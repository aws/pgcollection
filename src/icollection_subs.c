/*-------------------------------------------------------------------------
 *
 * icollection_subs.c
 *	  Subscripting support functions for icollection.
 *
 * See collection_subs.c for detailed comments on the subscripting approach.
 * This implementation is identical except for using int64 keys instead of
 * text keys.
 *
 * Portions Copyright (c) 1996-2023, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 * Modifications Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *-------------------------------------------------------------------------
 */
#include "postgres.h"

#include "catalog/pg_type_d.h"
#include "executor/execExpr.h"
#include "catalog/namespace.h"
#include "nodes/nodeFuncs.h"
#include "nodes/subscripting.h"
#include "parser/parse_coerce.h"
#include "parser/parse_expr.h"
#include "utils/builtins.h"
#include "utils/datum.h"
#include "utils/lsyscache.h"
#include "utils/wait_event.h"

#include "collection.h"

PG_FUNCTION_INFO_V1(icollection_subscript_handler);

static Oid	icollection_oid;

/*
 * Finish parse analysis of a SubscriptingRef expression for icollection.
 */
static void
icollection_subscript_transform(SubscriptingRef *sbsref,
								List *indirection,
								ParseState *pstate,
								bool isSlice,
								bool isAssignment)
{
	A_Indices  *ai;
	Node	   *subexpr;

	if (isSlice || list_length(indirection) != 1)
		ereport(ERROR,
				(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
				 errmsg("icollection allows only one subscript"),
				 parser_errposition(pstate,
									exprLocation((Node *) indirection))));

	ai = linitial_node(A_Indices, indirection);
	Assert(ai->uidx != NULL && ai->lidx == NULL && !ai->is_slice);

	subexpr = transformExpr(pstate, ai->uidx, pstate->p_expr_kind);

	subexpr = coerce_to_target_type(pstate,
									subexpr, exprType(subexpr),
									INT8OID, -1,
									COERCION_ASSIGNMENT,
									COERCE_IMPLICIT_CAST,
									-1);

	if (subexpr == NULL)
		ereport(ERROR,
				(errcode(ERRCODE_DATATYPE_MISMATCH),
				 errmsg("icollection subscript must have type bigint"),
				 parser_errposition(pstate, exprLocation(ai->uidx))));

	sbsref->refupperindexpr = list_make1(subexpr);
	sbsref->reflowerindexpr = NIL;

	if (sbsref->reftypmod == -1)
		sbsref->refrestype = TEXTOID;
	else
		sbsref->refrestype = sbsref->reftypmod;

	sbsref->reftypmod = -1;
}

/*
 * Evaluate SubscriptingRef fetch for icollection.
 */
static void
icollection_subscript_fetch(ExprState *state,
							ExprEvalStep *op,
							ExprContext *econtext)
{
	SubscriptingRefState *sbsrefstate = op->d.sbsref.state;
	CollectionSubWorkspace *workspace = (CollectionSubWorkspace *) sbsrefstate->workspace;
	ICollectionHeader *icolhdr;
	icollection *item;
	int64		key;
	Datum		value;

	if (*op->resnull)
		ereport(ERROR,
				(errcode(ERRCODE_NO_DATA_FOUND),
				 errmsg("key not found")));

	icolhdr = (ICollectionHeader *) DatumGetExpandedICollection(*op->resvalue);

	if (sbsrefstate->upperindexnull[0])
	{
		*op->resvalue = datumCopy(icolhdr->current->value, icolhdr->value_byval, icolhdr->value_type_len);
		*op->resnull = false;
		return;
	}

	key = DatumGetInt64(sbsrefstate->upperindex[0]);

	pgstat_report_wait_start(collection_we_fetch);

	ICOLLECTION_HASH_FIND(icolhdr->head, &key, item);

	if (item == NULL)
	{
		stats.find++;
		pgstat_report_wait_end();
		ereport(ERROR,
				(errcode(ERRCODE_NO_DATA_FOUND),
				 errmsg("key \"%ld\" not found", key)));
	}
	else if (item->isnull)
		value = (Datum) 0;
	else
		value = collection_coerce_value(item->value, icolhdr->value_type,
										icolhdr->value_byval,
										icolhdr->value_type_len,
										workspace->value_type);

	if (value == (Datum) 0)
		*op->resnull = true;
	else
		*op->resnull = false;

	*op->resvalue = value;

	stats.find++;
	pgstat_report_wait_end();
}

/*
 * Evaluate SubscriptingRef assignment for icollection.
 */
static void
icollection_subscript_assign(ExprState *state,
							 ExprEvalStep *op,
							 ExprContext *econtext)
{
	SubscriptingRefState *sbsrefstate = op->d.sbsref.state;
	CollectionSubWorkspace *workspace = (CollectionSubWorkspace *) sbsrefstate->workspace;
	MemoryContext oldcxt;
	ICollectionHeader *icolhdr;
	icollection *item;
	icollection *replaced_item;
	int64		key;

	if (sbsrefstate->upperindexnull[0])
		ereport(ERROR,
				(errcode(ERRCODE_NULL_VALUE_NOT_ALLOWED),
				 errmsg("icollection subscript in assignment must not be null")));

	if (*op->resnull)
	{
		icolhdr = construct_empty_icollection(CurrentMemoryContext);
		*op->resnull = false;
	}
	else
	{
		icolhdr = (ICollectionHeader *) DatumGetExpandedICollection(*op->resvalue);
	}

	if (icolhdr->value_type == InvalidOid)
	{
		icolhdr->value_type = workspace->value_type;
		icolhdr->value_type_len = workspace->value_type_len;
		icolhdr->value_byval = workspace->value_byval;
	}
	else if (workspace->value_type != icolhdr->value_type)
	{
		workspace->value_type = icolhdr->value_type;
		get_typlenbyval(icolhdr->value_type, &workspace->value_type_len, &workspace->value_byval);
		icolhdr->value_type_len = workspace->value_type_len;
		icolhdr->value_byval = workspace->value_byval;
	}

	pgstat_report_wait_start(collection_we_assign);

	if (!can_coerce_type(1, &workspace->value_type, &icolhdr->value_type, COERCION_IMPLICIT))
	{
		pgstat_report_wait_end();
		ereport(ERROR,
				(errcode(ERRCODE_DATATYPE_MISMATCH),
				 errmsg("incompatible value data type"),
				 errdetail("expecting %s, but received %s",
						   format_type_extended(icolhdr->value_type, -1, 0),
						   format_type_extended(workspace->value_type, -1, 0))));
	}

	oldcxt = MemoryContextSwitchTo(icolhdr->hdr.eoh_context);

	key = DatumGetInt64(sbsrefstate->upperindex[0]);

	item = (icollection *) palloc(sizeof(icollection));
	item->key = key;

	if (sbsrefstate->replacenull)
		item->isnull = true;
	else
	{
		item->value = datumCopy(sbsrefstate->replacevalue, workspace->value_byval, workspace->value_type_len);
		item->isnull = false;
	}

	ICOLLECTION_HASH_REPLACE(icolhdr->head, key, item, replaced_item);

	if (replaced_item)
	{
		if (!replaced_item->isnull && replaced_item->value && !workspace->value_byval)
			pfree(DatumGetPointer(replaced_item->value));
		pfree(replaced_item);
	}

	if (icolhdr->current == NULL)
		icolhdr->current = icolhdr->head;

	MemoryContextSwitchTo(oldcxt);

	*op->resvalue = EOHPGetRWDatum(&icolhdr->hdr);
	*op->resnull = false;

	stats.add++;
	pgstat_report_wait_end();
}

/*
 * Set up execution state for an icollection subscript operation.
 */
static void
icollection_exec_setup(const SubscriptingRef *sbsref,
					   SubscriptingRefState *sbsrefstate,
					   SubscriptExecSteps *methods)
{
	collection_exec_setup_common(sbsref, sbsrefstate, methods,
								 icollection_oid,
								 icollection_subscript_fetch,
								 icollection_subscript_assign);
}

/*
 * icollection_subscript_handler
 *		Subscripting handler for icollection.
 */
Datum
icollection_subscript_handler(PG_FUNCTION_ARGS)
{
	static const SubscriptRoutines sbsroutines = {
		.transform = icollection_subscript_transform,
		.exec_setup = icollection_exec_setup,
		.fetch_strict = false,
		.fetch_leakproof = true,
		.store_leakproof = false
	};

	icollection_oid = TypenameGetTypidExtended("icollection", false);

	PG_RETURN_POINTER(&sbsroutines);
}
