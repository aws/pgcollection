/*-------------------------------------------------------------------------
 *
 * collection_subs.c
 *	  Subscripting support functions for collection.
 *
 * This is a great deal simpler than array_subs.c, because the result of
 * subscripting an collection is just a datum (the value for the key).
 * We do not need to support array slicing notation, nor multiple subscripts.
 * Less obviously, because the subscript result is never a SQL container
 * type, there will never be any nested-assignment scenarios, so we do not
 * need a fetch_old function.  In turn, that means we can drop the
 * check_subscripts function and just let the fetch and assign functions
 * do everything.
 *
 * Copied from contrib/hstore/hstore_subs.c and modified to suit

 * Portions Copyright (c) 1996-2023, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 * Modifications Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *-------------------------------------------------------------------------
 */
#include "postgres.h"

#include "catalog/pg_type_d.h"
#include "executor/execExpr.h"
#include "nodes/nodeFuncs.h"
#include "nodes/subscripting.h"
#include "parser/parse_coerce.h"
#include "parser/parse_expr.h"
#include "utils/builtins.h"
#include "utils/datum.h"
#include "utils/lsyscache.h"
#include "utils/wait_event.h"

#include "collection.h"

typedef struct CollectionSubWorkspace
{
	/* Values determined during expression compilation */
	Oid			value_type;
	int16		value_type_len;
	bool		value_byval;
}			CollectionSubWorkspace;

PG_FUNCTION_INFO_V1(collection_subscript_handler);

/*
 * Finish parse analysis of a SubscriptingRef expression for collection.
 *
 * Verify there's just one subscript, coerce it to text,
 * and set the result type of the SubscriptingRef node.
 */
static void
collection_subscript_transform(SubscriptingRef *sbsref,
							   List *indirection,
							   ParseState *pstate,
							   bool isSlice,
							   bool isAssignment)
{
	A_Indices  *ai;
	Node	   *subexpr;

	/* We support only single-subscript, non-slice cases */
	if (isSlice || list_length(indirection) != 1)
		ereport(ERROR,
				(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
				 errmsg("collection allows only one subscript"),
				 parser_errposition(pstate,
									exprLocation((Node *) indirection))));

	/* Transform the subscript expression to type text */
	ai = linitial_node(A_Indices, indirection);
	Assert(ai->uidx != NULL && ai->lidx == NULL && !ai->is_slice);

	subexpr = transformExpr(pstate, ai->uidx, pstate->p_expr_kind);

	subexpr = coerce_to_target_type(pstate,
									subexpr, exprType(subexpr),
									TEXTOID, -1,
									COERCION_ASSIGNMENT,
									COERCE_IMPLICIT_CAST,
									-1);

	if (subexpr == NULL)
		ereport(ERROR,
				(errcode(ERRCODE_DATATYPE_MISMATCH),
				 errmsg("collection subscript must have type text"),
				 parser_errposition(pstate, exprLocation(ai->uidx))));

	/* ... and store the transformed subscript into the SubscriptRef node */
	sbsref->refupperindexpr = list_make1(subexpr);
	sbsref->reflowerindexpr = NIL;

	/* Default to returning text unless the typmod is set */
	if (sbsref->reftypmod == -1)
		sbsref->refrestype = TEXTOID;
	else
		sbsref->refrestype = sbsref->reftypmod;
}

/*
 * Evaluate SubscriptingRef fetch for collection.
 *
 * Source container is in step's result variable (it's known not NULL, since
 * we set fetch_strict to true), and the subscript expression is in the
 * upperindex[] array.
 */
static void
collection_subscript_fetch(ExprState *state,
						   ExprEvalStep *op,
						   ExprContext *econtext)
{
	SubscriptingRefState *sbsrefstate = op->d.sbsref.state;
	CollectionSubWorkspace *workspace = (CollectionSubWorkspace *) sbsrefstate->workspace;
	CollectionHeader *colhdr;
	collection *item;
	char	   *key;
	Datum		value;

	/* Should not get here if source collection is null */
	Assert(!(*op->resnull));

	colhdr = (CollectionHeader *) DatumGetExpandedCollection(*op->resvalue);

	/* Check for null subscript */
	if (sbsrefstate->upperindexnull[0])
	{
		*op->resvalue = datumCopy(colhdr->current->value, colhdr->value_byval, colhdr->value_type_len);
		*op->resnull = false;
		return;
	}

	pgstat_report_wait_start(collection_we_fetch);

	key = text_to_cstring(DatumGetTextPP(sbsrefstate->upperindex[0]));

	HASH_FIND(hh, colhdr->head, key, strlen(key), item);

	if (item == NULL)
		value = (Datum) 0;
	else
	{
		if (can_coerce_type(1, &workspace->value_type, &colhdr->value_type, COERCION_IMPLICIT))
			value = datumCopy(item->value, colhdr->value_byval, colhdr->value_type_len);
		else
		{
			if (workspace->value_type == TEXTOID)
			{
				bool		typisvarlena;
				Oid			outfuncoid;

				getTypeOutputInfo(colhdr->value_type, &outfuncoid, &typisvarlena);
				value = CStringGetTextDatum(DatumGetCString(OidFunctionCall1(outfuncoid, item->value)));
			}
			else
			{
				ereport(ERROR,
						(errcode(ERRCODE_DATATYPE_MISMATCH),
						 errmsg("Incompatible value data type"),
						 errdetail("Expecting %s, but received %s",
								   format_type_extended(workspace->value_type, -1, 0),
								   format_type_extended(colhdr->value_type, -1, 0))));
			}
		}
	}

	if (value == (Datum) 0)
		*op->resnull = true;
	else
		*op->resnull = false;

	*op->resvalue = value;

	stats.find++;
	pgstat_report_wait_end();

}

/*
 * Evaluate SubscriptingRef assignment for collection.
 *
 * Input container (possibly null) is in result area, replacement value is in
 * SubscriptingRefState's replacevalue/replacenull.
 */
static void
collection_subscript_assign(ExprState *state,
							ExprEvalStep *op,
							ExprContext *econtext)
{
	SubscriptingRefState *sbsrefstate = op->d.sbsref.state;
	CollectionSubWorkspace *workspace = (CollectionSubWorkspace *) sbsrefstate->workspace;
	MemoryContext oldcxt;
	CollectionHeader *colhdr;
	collection *item;
	collection *replaced_item;
	char	   *key;

	/* Check for null subscript */
	if (sbsrefstate->upperindexnull[0])
		ereport(ERROR,
				(errcode(ERRCODE_NULL_VALUE_NOT_ALLOWED),
				 errmsg("collection subscript in assignment must not be null")));

	if (*op->resnull)
	{
		colhdr = construct_empty_collection(CurrentMemoryContext);
		*op->resnull = false;

		colhdr->value_type = workspace->value_type;
		colhdr->value_type_len = workspace->value_type_len;
		colhdr->value_byval = workspace->value_byval;
	}
	else
	{
		colhdr = (CollectionHeader *) DatumGetExpandedCollection(*op->resvalue);
	}

	pgstat_report_wait_start(collection_we_assign);

	if (!can_coerce_type(1, &workspace->value_type, &colhdr->value_type, COERCION_IMPLICIT))
	{
		pgstat_report_wait_end();
		ereport(ERROR,
				(errcode(ERRCODE_DATATYPE_MISMATCH),
				 errmsg("incompatible value data type"),
				 errdetail("expecting %s, but received %s",
						   format_type_extended(colhdr->value_type, -1, 0),
						   format_type_extended(workspace->value_type, -1, 0))));
	}

	oldcxt = MemoryContextSwitchTo(colhdr->hdr.eoh_context);

	key = text_to_cstring(DatumGetTextPP(sbsrefstate->upperindex[0]));

	item = (collection *) palloc(sizeof(collection));
	item->key = key;
	item->value = datumCopy(sbsrefstate->replacevalue, workspace->value_byval, workspace->value_type_len);

	HASH_REPLACE(hh, colhdr->current, key[0], strlen(key), item, replaced_item);

	if (colhdr->head == NULL)
		colhdr->head = colhdr->current;

	MemoryContextSwitchTo(oldcxt);

	*op->resvalue = EOHPGetRWDatum(&colhdr->hdr);
	*op->resnull = false;

	stats.add++;
	pgstat_report_wait_end();
}

/*
 * Set up execution state for an collection subscript operation.
 */
static void
collection_exec_setup(const SubscriptingRef *sbsref,
					  SubscriptingRefState *sbsrefstate,
					  SubscriptExecSteps *methods)
{
	CollectionSubWorkspace *workspace;

	/* Assert we are dealing with one subscript */
	Assert(sbsrefstate->numlower == 0);
	Assert(sbsrefstate->numupper == 1);
	/* We can't check upperprovided[0] here, but it must be true */

	/*
	 * Allocate type-specific workspace.
	 */
	workspace = (CollectionSubWorkspace *) palloc(sizeof(CollectionSubWorkspace));
	sbsrefstate->workspace = workspace;

	/* Default to fetching as text unless the typmod is set */
	if (sbsref->reftypmod == -1)
	{
		workspace->value_type = TEXTOID;
		workspace->value_type_len = -1;
		workspace->value_byval = false;
	}
	else
	{
		workspace->value_type = sbsref->reftypmod;
		get_typlenbyval(sbsref->reftypmod, &workspace->value_type_len, &workspace->value_byval);
	}

	/* Pass back pointers to appropriate step execution functions */
	methods->sbs_check_subscripts = NULL;
	methods->sbs_fetch = collection_subscript_fetch;
	methods->sbs_assign = collection_subscript_assign;
	methods->sbs_fetch_old = NULL;
}

/*
 * collection_subscript_handler
 *		Subscripting handler for collection.
 */
Datum
collection_subscript_handler(PG_FUNCTION_ARGS)
{
	static const SubscriptRoutines sbsroutines = {
		.transform = collection_subscript_transform,
		.exec_setup = collection_exec_setup,
		.fetch_strict = true,	/* fetch returns NULL for NULL inputs */
		.fetch_leakproof = true,	/* fetch returns NULL for bad subscript */
		.store_leakproof = false	/* ... but assignment throws error */
	};

	PG_RETURN_POINTER(&sbsroutines);
}
