/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License").
 * You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
#include "postgres.h"

#include "access/htup_details.h"
#include "catalog/pg_type.h"
#include "common/jsonapi.h"
#include "executor/execExpr.h"
#include "funcapi.h"
#include "nodes/subscripting.h"
#include "mb/pg_wchar.h"
#include "parser/parse_coerce.h"
#include "parser/parse_type.h"
#include "utils/array.h"
#include "utils/builtins.h"
#include "utils/datum.h"
#include "utils/expandeddatum.h"
#include "utils/lsyscache.h"

#include "collection.h"

/*
 * collection_typmodin_common
 *		Shared typmod input logic for collection and icollection types.
 *		type_name is used only in error messages.
 */
int32
collection_typmodin_common(ArrayType *ta, const char *type_name)
{
	Datum	   *elem_values;
	int			n;
	Oid			typoid = 0;
	int32		typmod = 0;

	if (ARR_ELEMTYPE(ta) != CSTRINGOID)
		ereport(ERROR,
				(errcode(ERRCODE_ARRAY_ELEMENT_ERROR),
				 errmsg("typmod array must be type cstring[]")));

	if (ARR_NDIM(ta) != 1)
		ereport(ERROR,
				(errcode(ERRCODE_ARRAY_SUBSCRIPT_ERROR),
				 errmsg("typmod array must be one-dimensional")));

	if (array_contains_nulls(ta))
		ereport(ERROR,
				(errcode(ERRCODE_NULL_VALUE_NOT_ALLOWED),
				 errmsg("typmod array must not contain nulls")));

	deconstruct_array(ta, CSTRINGOID, -2, false, 'c', &elem_values, NULL, &n);

	if (n != 1)
		ereport(ERROR,
				(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
				 errmsg("invalid %s type modifier", type_name)));

	parseTypeString(DatumGetCString(elem_values[0]), &typoid, &typmod, NULL);

	if (typmod != -1)
	{
		/*
		 * There needs to be special handling for BPCHAR. For a CHAR passed in
		 * without a typemod defined, the typmod is still returned as 5
		 * intentionally based on the historical comment in varchar.c. There
		 * also needs to be a check to see if there are parentheses in the
		 * string to determine if the passed in string is CHAR or CHAR(1).
		 *
		 * In backend/utils/adt/varchar.c:
		 *
		 * For largely historical reasons, the typmod is VARHDRSZ plus the
		 * number of characters; there is enough client-side code that knows
		 * about that that we'd better not change it.
		 */
		if (typoid != BPCHAROID ||
			(typmod != VARHDRSZ + 1 ||
			 strpbrk(DatumGetCString(elem_values[0]), "()")))
			ereport(ERROR,
					(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
					 errmsg("invalid %s type modifier", type_name),
					 errdetail("the type cannot have a type modifier")));
	}

	return (int32) typoid;
}

/*
 * collection_typmodout_common
 *		Shared typmod output logic for collection and icollection types.
 */
char *
collection_typmodout_common(Oid typmod)
{
	return DatumGetCString(DirectFunctionCall1(regtypeout, typmod));
}

/*
 * Shared JSON parse callbacks for collection and icollection.
 *
 * object_start, object_end, and array_start are identical between the two
 * types. object_field_start and scalar differ (key handling, null tracking)
 * and remain type-specific.
 */

JsonParseErrorType
collection_parse_object_start(void *state)
{
	CollectionParseState *parse = state;

	switch (parse->state)
	{
		case COLL_PARSE_EXPECT_TOPLEVEL_START:
			parse->state = COLL_PARSE_EXPECT_TOPLEVEL_FIELD;
			break;

		case COLL_PARSE_EXPECT_ENTRIES:
			parse->state = COLL_PARSE_EXPECT_ENTRIES_OBJECT;
			break;

		default:
			elog(ERROR, "unexpected object start");
			break;
	}

	return JSON_SUCCESS;
}

JsonParseErrorType
collection_parse_object_end(void *state)
{
	CollectionParseState *parse = state;

	switch (parse->state)
	{
		case COLL_PARSE_EXPECT_TOPLEVEL_END:
			parse->state = COLL_PARSE_EXPECT_EOF;
			break;

		case COLL_PARSE_EXPECT_ENTRIES_OBJECT:
			parse->state = COLL_PARSE_EXPECT_TOPLEVEL_END;
			break;

		default:
			elog(ERROR, "unexpected object end");
			break;
	}

	return JSON_SUCCESS;
}

JsonParseErrorType
collection_parse_array_start(void *state)
{
	elog(ERROR, "Invalid collection format");
	return JSON_INVALID_TOKEN;
}

/*
 * collection_parse_init
 *		Initialize shared parse state and wire up JSON semantic actions.
 *		object_field_start and scalar are type-specific callbacks passed in
 *		by the caller.
 */
void
collection_parse_init(CollectionParseState * parse,
					  JsonSemAction *sem,
					  char *json,
					  void *object_field_start,
					  void *scalar)
{
	parse->state = COLL_PARSE_EXPECT_TOPLEVEL_START;
#if (PG_VERSION_NUM >= 170000)
	parse->lex = makeJsonLexContextCstringLen(NULL, json, strlen(json), PG_UTF8, true);
#else
	parse->lex = makeJsonLexContextCstringLen(json, strlen(json), PG_UTF8, true);
#endif
	parse->keys = NIL;
	parse->values = NIL;
	parse->nulls = NIL;
	parse->typname = NULL;

	sem->semstate = parse;

#if (PG_VERSION_NUM >= 160000)
	sem->object_start = collection_parse_object_start;
	sem->object_end = collection_parse_object_end;
	sem->array_start = collection_parse_array_start;
	sem->object_field_start = object_field_start;
	sem->scalar = scalar;
#else
	sem->object_start = (void *) collection_parse_object_start;
	sem->object_end = (void *) collection_parse_object_end;
	sem->array_start = (void *) collection_parse_array_start;
	sem->object_field_start = (void *) object_field_start;
	sem->scalar = (void *) scalar;
#endif
	sem->array_end = NULL;
	sem->object_field_end = NULL;
	sem->array_element_start = NULL;
	sem->array_element_end = NULL;
}

/*
 * Shared SRF helpers for keys_to_table, values_to_table, to_table.
 *
 * Both collection and icollection use these with type-specific callbacks
 * for key/value extraction and iteration.
 */

Datum
collection_srf_keys_to_table(FunctionCallInfo fcinfo,
							 void *head,
							 CollectionSRFContext * tmpl)
{
	FuncCallContext *funcctx;
	CollectionSRFContext *ctx;

	if (SRF_IS_FIRSTCALL())
	{
		MemoryContext oldcxt;

		funcctx = SRF_FIRSTCALL_INIT();
		oldcxt = MemoryContextSwitchTo(funcctx->multi_call_memory_ctx);

		ctx = (CollectionSRFContext *) palloc(sizeof(CollectionSRFContext));
		memcpy(ctx, tmpl, sizeof(CollectionSRFContext));
		ctx->cur = head;

		/* Keep expanded object alive across SRF calls */
		if (ctx->eoh)
			TransferExpandedObject(EOHPGetRWDatum((ExpandedObjectHeader *) ctx->eoh),
								   funcctx->multi_call_memory_ctx);

		funcctx->user_fctx = ctx;

		MemoryContextSwitchTo(oldcxt);
	}

	funcctx = SRF_PERCALL_SETUP();
	ctx = funcctx->user_fctx;

	if (ctx->cur != NULL)
	{
		Datum		value = ctx->get_key(ctx->cur);

		ctx->cur = ctx->get_next(ctx->cur);
		SRF_RETURN_NEXT(funcctx, value);
	}

	SRF_RETURN_DONE(funcctx);
}

Datum
collection_srf_values_to_table(FunctionCallInfo fcinfo,
							   void *head,
							   Oid value_type,
							   CollectionSRFContext * tmpl)
{
	FuncCallContext *funcctx;
	CollectionSRFContext *ctx;

	if (SRF_IS_FIRSTCALL())
	{
		MemoryContext oldcxt;
		Oid			rettype;

		funcctx = SRF_FIRSTCALL_INIT();
		oldcxt = MemoryContextSwitchTo(funcctx->multi_call_memory_ctx);

		ctx = (CollectionSRFContext *) palloc(sizeof(CollectionSRFContext));
		memcpy(ctx, tmpl, sizeof(CollectionSRFContext));
		ctx->cur = head;

		/* Keep expanded object alive across SRF calls */
		if (ctx->eoh)
			TransferExpandedObject(EOHPGetRWDatum((ExpandedObjectHeader *) ctx->eoh),
								   funcctx->multi_call_memory_ctx);

		funcctx->user_fctx = ctx;

		get_call_result_type(fcinfo, &rettype, NULL);

		if (!can_coerce_type(1, &rettype, &value_type, COERCION_IMPLICIT))
			ereport(ERROR,
					(errcode(ERRCODE_DATATYPE_MISMATCH),
					 errmsg("Value type does not match the return type")));

		MemoryContextSwitchTo(oldcxt);
	}

	funcctx = SRF_PERCALL_SETUP();
	ctx = funcctx->user_fctx;

	if (ctx->cur != NULL)
	{
		if (ctx->get_isnull(ctx->cur))
		{
			ctx->cur = ctx->get_next(ctx->cur);
			SRF_RETURN_NEXT_NULL(funcctx);
		}
		else
		{
			Datum		value = datumCopy(ctx->get_value(ctx->cur),
										  ctx->typebyval, ctx->typelen);

			ctx->cur = ctx->get_next(ctx->cur);
			SRF_RETURN_NEXT(funcctx, value);
		}
	}

	SRF_RETURN_DONE(funcctx);
}

Datum
collection_srf_to_table(FunctionCallInfo fcinfo,
						void *head,
						Oid value_type,
						CollectionSRFContext * tmpl)
{
	FuncCallContext *funcctx;
	CollectionSRFContext *ctx;
	ReturnSetInfo *rsinfo = (ReturnSetInfo *) fcinfo->resultinfo;

	if (SRF_IS_FIRSTCALL())
	{
		MemoryContext oldcxt;
		Oid			rettype;

		if (rsinfo == NULL || !IsA(rsinfo, ReturnSetInfo))
			ereport(ERROR,
					(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
					 errmsg("set-valued function called in context that cannot accept a set")));
		if (!(rsinfo->allowedModes & SFRM_Materialize))
			ereport(ERROR,
					(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
					 errmsg("materialize mode required, but it is not allowed in this context")));

		funcctx = SRF_FIRSTCALL_INIT();
		oldcxt = MemoryContextSwitchTo(funcctx->multi_call_memory_ctx);

		ctx = (CollectionSRFContext *) palloc(sizeof(CollectionSRFContext));
		memcpy(ctx, tmpl, sizeof(CollectionSRFContext));
		ctx->cur = head;

		/* Keep expanded object alive across SRF calls */
		if (ctx->eoh)
			TransferExpandedObject(EOHPGetRWDatum((ExpandedObjectHeader *) ctx->eoh),
								   funcctx->multi_call_memory_ctx);

		if (rsinfo->expectedDesc->natts != 2)
			ereport(ERROR,
					(errcode(ERRCODE_DATATYPE_MISMATCH),
					 errmsg("Return record must have 2 attributes")));

		rettype = TupleDescAttr(rsinfo->expectedDesc, 1)->atttypid;

		if (!can_coerce_type(1, &rettype, &value_type, COERCION_IMPLICIT))
			ereport(ERROR,
					(errcode(ERRCODE_DATATYPE_MISMATCH),
					 errmsg("Value type does not match the return type")));

		ctx->tupdesc = (void *) CreateTupleDescCopy(rsinfo->expectedDesc);
		funcctx->user_fctx = ctx;

		MemoryContextSwitchTo(oldcxt);
	}

	funcctx = SRF_PERCALL_SETUP();
	ctx = funcctx->user_fctx;

	if (ctx->cur != NULL)
	{
		Datum		values[2];
		bool		nulls[2] = {0};
		HeapTuple	tuple;

		values[0] = ctx->get_key(ctx->cur);

		if (ctx->get_isnull(ctx->cur))
			nulls[1] = true;
		else
			values[1] = datumCopy(ctx->get_value(ctx->cur),
								  ctx->typebyval, ctx->typelen);

		tuple = heap_form_tuple((TupleDesc) ctx->tupdesc, values, nulls);

		ctx->cur = ctx->get_next(ctx->cur);

		SRF_RETURN_NEXT(funcctx, HeapTupleGetDatum(tuple));
	}

	SRF_RETURN_DONE(funcctx);
}

/*
 * collection_exec_setup_common
 *		Shared exec_setup logic for collection and icollection subscripting.
 *
 * Allocates workspace, resolves value type from refrestype/reftypmod,
 * and wires up the fetch/assign method pointers.
 */
void
collection_exec_setup_common(const SubscriptingRef *sbsref,
							 SubscriptingRefState *sbsrefstate,
							 SubscriptExecSteps *methods,
							 Oid type_oid,
							 void *fetch_fn,
							 void *assign_fn)
{
	CollectionSubWorkspace *workspace;

	Assert(sbsrefstate->numlower == 0);
	Assert(sbsrefstate->numupper == 1);

	workspace = (CollectionSubWorkspace *) palloc(sizeof(CollectionSubWorkspace));
	sbsrefstate->workspace = workspace;

	if (sbsref->refrestype == type_oid && sbsref->reftypmod != -1)
	{
		workspace->value_type = sbsref->reftypmod;
		get_typlenbyval(sbsref->reftypmod, &workspace->value_type_len, &workspace->value_byval);
	}
	else if (sbsref->refrestype != InvalidOid && sbsref->refrestype != type_oid && sbsref->reftypmod == -1)
	{
		workspace->value_type = sbsref->refrestype;
		get_typlenbyval(sbsref->refrestype, &workspace->value_type_len, &workspace->value_byval);
	}
	else
	{
		workspace->value_type = TEXTOID;
		workspace->value_type_len = -1;
		workspace->value_byval = false;
	}

	methods->sbs_check_subscripts = NULL;
	methods->sbs_fetch = (ExecEvalSubroutine) fetch_fn;
	methods->sbs_assign = (ExecEvalSubroutine) assign_fn;
	methods->sbs_fetch_old = NULL;
}

/*
 * Shared simple userfuncs for collection and icollection.
 *
 * These operate on CollectionHeaderCommon, which has the same layout as
 * both CollectionHeader and ICollectionHeader.  The entry structs also
 * share the same UT_hash_handle offset, so HASH_COUNT and hh navigation
 * work through void pointers.
 */

int32
collection_count_common(CollectionHeaderCommon * hdr)
{
	if (hdr->head == NULL)
		return 0;

	return HASH_COUNT((CollectionEntryCommon *) hdr->head);
}

bool
collection_isnull_common(CollectionHeaderCommon * hdr)
{
	return (hdr->current == NULL);
}

void
collection_first_common(CollectionHeaderCommon * hdr)
{
	hdr->current = hdr->head;
}

void
collection_last_common(CollectionHeaderCommon * hdr)
{
	if (hdr->head != NULL)
	{
		CollectionEntryCommon *entry = (CollectionEntryCommon *) hdr->head;

		hdr->current = ELMT_FROM_HH(entry->hh.tbl, entry->hh.tbl->tail);
	}
	else
		hdr->current = NULL;
}

void
collection_next_common(CollectionHeaderCommon * hdr)
{
	if (hdr->current != NULL)
		hdr->current = ((CollectionEntryCommon *) hdr->current)->hh.next;
}

void
collection_prev_common(CollectionHeaderCommon * hdr)
{
	if (hdr->current != NULL)
		hdr->current = ((CollectionEntryCommon *) hdr->current)->hh.prev;
}

Datum
collection_value_type_common(CollectionHeaderCommon * hdr)
{
	if (hdr->head == NULL || hdr->value_type == InvalidOid)
		return (Datum) 0;		/* caller returns NULL */

	return ObjectIdGetDatum(hdr->value_type);
}

void
collection_cast_common(CollectionHeaderCommon * hdr, Oid typmod,
					   FunctionCallInfo fcinfo)
{
	if (typmod > 0 && hdr->value_type != InvalidOid)
	{
		if (get_fn_expr_argtype(fcinfo->flinfo, 0) != typmod &&
			!can_coerce_type(1, &hdr->value_type, &typmod, COERCION_IMPLICIT))
			ereport(ERROR,
					(errcode(ERRCODE_DATATYPE_MISMATCH),
					 errmsg("Incompatible value data type"),
					 errdetail("Expecting %s, but received %s",
							   format_type_extended(typmod, -1, 0),
							   format_type_extended(hdr->value_type, -1, 0))));
	}
	else if (typmod > 0 && hdr->value_type == InvalidOid)
	{
		hdr->value_type = (Oid) typmod;
		get_typlenbyval(hdr->value_type, &hdr->value_type_len, &hdr->value_byval);
	}
}

/*
 * collection_coerce_value
 *		Shared 3-tier value coercion used by find, value, and subscript fetch.
 *		1) If rettype can coerce to value_type, return native datumCopy.
 *		2) If rettype is TEXTOID, convert via output function.
 *		3) Otherwise error.
 */
Datum
collection_coerce_value(Datum value, Oid value_type,
						bool value_byval, int16 value_type_len,
						Oid rettype)
{
	if (can_coerce_type(1, &rettype, &value_type, COERCION_IMPLICIT))
		return datumCopy(value, value_byval, value_type_len);

	if (rettype == TEXTOID)
	{
		Oid			outfuncoid;
		bool		typisvarlena;

		getTypeOutputInfo(value_type, &outfuncoid, &typisvarlena);
		return CStringGetTextDatum(DatumGetCString(OidFunctionCall1(outfuncoid, value)));
	}

	ereport(ERROR,
			(errcode(ERRCODE_DATATYPE_MISMATCH),
			 errmsg("Value type does not match the return type")));
	return (Datum) 0;			/* unreachable */
}
