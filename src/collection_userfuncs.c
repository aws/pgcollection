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

#include <ctype.h>
#include <limits.h>

#include "catalog/pg_collation_d.h"
#include "catalog/pg_type.h"
#include "funcapi.h"
#include "parser/parse_coerce.h"
#include "pgstat.h"
#include "utils/array.h"
#include "utils/builtins.h"
#include "utils/datum.h"
#include "utils/json.h"
#include "utils/lsyscache.h"
#include "utils/memutils.h"
#include "utils/varlena.h"
#include "utils/wait_event.h"

#include "collection.h"

PG_FUNCTION_INFO_V1(collection_add);
PG_FUNCTION_INFO_V1(collection_count);
PG_FUNCTION_INFO_V1(collection_find);
PG_FUNCTION_INFO_V1(collection_exist);
PG_FUNCTION_INFO_V1(collection_delete);
PG_FUNCTION_INFO_V1(collection_sort);
PG_FUNCTION_INFO_V1(collection_copy);
PG_FUNCTION_INFO_V1(collection_key);
PG_FUNCTION_INFO_V1(collection_value);
PG_FUNCTION_INFO_V1(collection_isnull);

PG_FUNCTION_INFO_V1(collection_next);
PG_FUNCTION_INFO_V1(collection_prev);
PG_FUNCTION_INFO_V1(collection_first);
PG_FUNCTION_INFO_V1(collection_last);
PG_FUNCTION_INFO_V1(collection_keys_to_table);
PG_FUNCTION_INFO_V1(collection_values_to_table);
PG_FUNCTION_INFO_V1(collection_to_table);

PG_FUNCTION_INFO_V1(collection_value_type);
PG_FUNCTION_INFO_V1(collection_stats);
PG_FUNCTION_INFO_V1(collection_stats_reset);

StatsCounters stats;

static int	by_key(const struct collection *a, const struct collection *b);
static Oid	collection_collation = DEFAULT_COLLATION_OID;

Datum
collection_add(PG_FUNCTION_ARGS)
{
	CollectionHeader *colhdr;
	MemoryContext oldcxt;
	collection *item;
	collection *replaced_item;
	char	   *key;
	Datum		value;
	Oid			argtype;
	int16		argtypelen;
	bool		argtypebyval;

	if (PG_ARGISNULL(1))
		ereport(ERROR,
				(errcode(ERRCODE_DATATYPE_MISMATCH),
				 errmsg("Key must not be null")));

	colhdr = fetch_collection(fcinfo, 0);

	pgstat_report_wait_start(collection_we_add);

	oldcxt = MemoryContextSwitchTo(colhdr->hdr.eoh_context);

	key = text_to_cstring(PG_GETARG_TEXT_PP(1));
	item = (collection *) palloc(sizeof(collection));
	item->key = key;

	argtype = get_fn_expr_argtype(fcinfo->flinfo, 2);
	get_typlenbyval(argtype, &argtypelen, &argtypebyval);

	/*
	 * Set the value type of the collection to the first element added
	 */
	if (colhdr->value_type == InvalidOid)
	{
		colhdr->value_type = argtype;
		colhdr->value_type_len = argtypelen;
		colhdr->value_byval = argtypebyval;
	}
	else
	{
		if (!can_coerce_type(1, &argtype, &colhdr->value_type, COERCION_IMPLICIT))
		{
			pgstat_report_wait_end();
			ereport(ERROR,
					(errcode(ERRCODE_DATATYPE_MISMATCH),
					 errmsg("incompatible value data type"),
					 errdetail("expecting %s, but received %s",
							   format_type_extended(colhdr->value_type, -1, 0),
							   format_type_extended(argtype, -1, 0))));
		}
	}

	if (PG_ARGISNULL(2))
		item->isnull = true;
	else
	{
		value = PG_GETARG_DATUM(2);

		item->value = datumCopy(value, argtypebyval, argtypelen);
		item->isnull = false;
	}

	HASH_REPLACE(hh, colhdr->head, key[0], strlen(key), item, replaced_item);

	if (replaced_item)
		pfree(replaced_item);

	if (colhdr->current == NULL)
		colhdr->current = colhdr->head;

	MemoryContextSwitchTo(oldcxt);

	stats.add++;
	pgstat_report_wait_end();

	PG_RETURN_DATUM(EOHPGetRWDatum(&colhdr->hdr));
}

Datum
collection_count(PG_FUNCTION_ARGS)
{
	Size		count;
	CollectionHeader *colhdr;

	colhdr = fetch_collection(fcinfo, 0);

	if (colhdr->head == NULL)
		PG_RETURN_NULL();

	pgstat_report_wait_start(collection_we_count);

	count = HASH_COUNT(colhdr->head);

	pgstat_report_wait_end();

	PG_RETURN_INT32(count);
}

Datum
collection_find(PG_FUNCTION_ARGS)
{
	char	   *key;
	Datum		value;
	collection *item;
	Oid			rettype;
	CollectionHeader *colhdr;

	if (PG_ARGISNULL(1))
		PG_RETURN_NULL();

	colhdr = fetch_collection(fcinfo, 0);
	if (colhdr->head == NULL)
	{
		stats.find++;
		PG_RETURN_NULL();
	}

	pgstat_report_wait_start(collection_we_find);

	key = text_to_cstring(PG_GETARG_TEXT_PP(1));

	HASH_FIND(hh, colhdr->head, key, strlen(key), item);

	if (item == NULL)
	{
		stats.find++;
		pgstat_report_wait_end();
		ereport(ERROR,
				(errcode(ERRCODE_NO_DATA_FOUND),
				 errmsg("key \"%s\" not found", key)));
	}

	if (item->isnull)
	{
		stats.find++;
		pgstat_report_wait_end();
		PG_RETURN_NULL();
	}

	value = datumCopy(item->value, colhdr->value_byval, colhdr->value_type_len);

	get_call_result_type(fcinfo, &rettype, NULL);

	if (!can_coerce_type(1, &rettype, &colhdr->value_type, COERCION_IMPLICIT))
	{
		pgstat_report_wait_end();
		ereport(ERROR,
				(errcode(ERRCODE_DATATYPE_MISMATCH),
				 errmsg("Value type does not match the return type")));
	}

	stats.find++;
	pgstat_report_wait_end();

	PG_RETURN_DATUM(value);
}

Datum
collection_exist(PG_FUNCTION_ARGS)
{
	char	   *key;
	collection *item;
	CollectionHeader *colhdr;

	if (PG_ARGISNULL(1))
	{
		stats.exist++;
		PG_RETURN_BOOL(false);
	}

	colhdr = fetch_collection(fcinfo, 0);
	if (colhdr->head == NULL)
	{
		stats.exist++;
		PG_RETURN_BOOL(false);
	}

	pgstat_report_wait_start(collection_we_exist);

	key = text_to_cstring(PG_GETARG_TEXT_PP(1));

	HASH_FIND(hh, colhdr->head, key, strlen(key), item);

	if (item == NULL)
	{
		stats.exist++;
		pgstat_report_wait_end();
		PG_RETURN_BOOL(false);
	}

	stats.exist++;
	pgstat_report_wait_end();

	PG_RETURN_BOOL(true);
}

Datum
collection_delete(PG_FUNCTION_ARGS)
{
	char	   *key;
	collection *item;
	CollectionHeader *colhdr;

	if (PG_ARGISNULL(1))
		ereport(ERROR,
				(errcode(ERRCODE_DATATYPE_MISMATCH),
				 errmsg("Key must not be null")));

	colhdr = fetch_collection(fcinfo, 0);

	pgstat_report_wait_start(collection_we_delete);

	if (colhdr->head)
	{
		key = text_to_cstring(PG_GETARG_TEXT_PP(1));

		HASH_FIND(hh, colhdr->head, key, strlen(key), item);

		if (item == NULL)
		{
			stats.delete++;
			pgstat_report_wait_end();
			PG_RETURN_DATUM(EOHPGetRWDatum(&colhdr->hdr));
		}

		HASH_DEL(colhdr->head, item);
		pfree(item);

		/* Clean up the hash table if the last item was deleted */
		if (HASH_COUNT(colhdr->head) == 0)
		{
			HASH_CLEAR(hh, colhdr->head);
			colhdr->head = NULL;
			colhdr->current = NULL;
		}
	}

	stats.delete++;
	pgstat_report_wait_end();

	PG_RETURN_DATUM(EOHPGetRWDatum(&colhdr->hdr));
}

Datum
collection_sort(PG_FUNCTION_ARGS)
{
	CollectionHeader *colhdr;

	colhdr = fetch_collection(fcinfo, 0);

	collection_collation = PG_GET_COLLATION();

	pgstat_report_wait_start(collection_we_sort);

	if (colhdr->head)
	{
		HASH_SORT(colhdr->head, by_key);

		colhdr->current = colhdr->head;
	}

	stats.sort++;
	pgstat_report_wait_end();

	PG_RETURN_DATUM(EOHPGetRWDatum(&colhdr->hdr));
}

Datum
collection_copy(PG_FUNCTION_ARGS)
{
	CollectionHeader *colhdr;
	CollectionHeader *copyhdr;

	colhdr = fetch_collection(fcinfo, 0);

	pgstat_report_wait_start(collection_we_copy);

	if (colhdr->head)
	{
		MemoryContext oldcxt;
		collection *iter;
		collection *item;
		collection *head;

		copyhdr = construct_empty_collection(CurrentMemoryContext);

		oldcxt = MemoryContextSwitchTo(copyhdr->hdr.eoh_context);

		copyhdr->value_type = colhdr->value_type;
		copyhdr->value_type_len = colhdr->value_type_len;
		copyhdr->value_byval = colhdr->value_byval;

		head = colhdr->head;
		for (iter = colhdr->head; iter != NULL; iter = iter->hh.next)
		{
			char	   *key;
			int			key_len;

			key_len = strlen(iter->key);
			key = palloc(key_len + 1);
			memset(key, 0, key_len + 1);
			strcpy(key, iter->key);

			item = (collection *) palloc(sizeof(collection));
			item->key = key;
			item->isnull = iter->isnull;
			if (!iter->isnull)
				item->value = datumCopy(iter->value, colhdr->value_byval, colhdr->value_type_len);

			HASH_ADD(hh, copyhdr->head, key[0], strlen(key), item);

			if (!copyhdr->current)
				copyhdr->current = copyhdr->head;
		}
		colhdr->head = head;

		MemoryContextSwitchTo(oldcxt);

		pgstat_report_wait_end();

		PG_RETURN_DATUM(EOHPGetRWDatum(&copyhdr->hdr));
	}

	pgstat_report_wait_end();

	PG_RETURN_NULL();
}

Datum
collection_key(PG_FUNCTION_ARGS)
{
	CollectionHeader *colhdr;

	colhdr = fetch_collection(fcinfo, 0);

	if (colhdr->current == NULL)
		PG_RETURN_NULL();

	PG_RETURN_TEXT_P(cstring_to_text(colhdr->current->key));
}

Datum
collection_value(PG_FUNCTION_ARGS)
{
	Datum		value;
	Oid			rettype;
	CollectionHeader *colhdr;

	colhdr = fetch_collection(fcinfo, 0);

	if (colhdr->current == NULL)
		PG_RETURN_NULL();

	if (colhdr->current->isnull)
		PG_RETURN_NULL();

	pgstat_report_wait_start(collection_we_value);

	value = datumCopy(colhdr->current->value, colhdr->value_byval, colhdr->value_type_len);

	get_call_result_type(fcinfo, &rettype, NULL);

	if (!can_coerce_type(1, &rettype, &colhdr->value_type, COERCION_IMPLICIT))
	{
		pgstat_report_wait_end();
		ereport(ERROR,
				(errcode(ERRCODE_DATATYPE_MISMATCH),
				 errmsg("Value type does not match the return type")));
	}

	pgstat_report_wait_end();

	PG_RETURN_DATUM(value);
}

Datum
collection_isnull(PG_FUNCTION_ARGS)
{
	CollectionHeader *colhdr;

	colhdr = fetch_collection(fcinfo, 0);

	if (colhdr->current == NULL)
		PG_RETURN_BOOL(true);

	PG_RETURN_BOOL(false);
}

Datum
collection_next(PG_FUNCTION_ARGS)
{
	CollectionHeader *colhdr;

	colhdr = fetch_collection(fcinfo, 0);

	if (colhdr->current)
		colhdr->current = colhdr->current->hh.next;

	PG_RETURN_DATUM(EOHPGetRWDatum(&colhdr->hdr));
}

Datum
collection_prev(PG_FUNCTION_ARGS)
{
	CollectionHeader *colhdr;

	colhdr = fetch_collection(fcinfo, 0);

	if (colhdr->current)
		colhdr->current = colhdr->current->hh.prev;

	PG_RETURN_DATUM(EOHPGetRWDatum(&colhdr->hdr));
}

Datum
collection_first(PG_FUNCTION_ARGS)
{
	CollectionHeader *colhdr;

	colhdr = fetch_collection(fcinfo, 0);
	colhdr->current = colhdr->head;

	PG_RETURN_DATUM(EOHPGetRWDatum(&colhdr->hdr));
}

Datum
collection_last(PG_FUNCTION_ARGS)
{
	CollectionHeader *colhdr;

	colhdr = fetch_collection(fcinfo, 0);

	if (colhdr->current)
		colhdr->current = ELMT_FROM_HH(colhdr->current->hh.tbl, colhdr->current->hh.tbl->tail);


	PG_RETURN_DATUM(EOHPGetRWDatum(&colhdr->hdr));
}

Datum
collection_keys_to_table(PG_FUNCTION_ARGS)
{
	typedef struct
	{
		collection *cur;
	}			to_table_fctx;

	FuncCallContext *funcctx;
	to_table_fctx *fctx;
	CollectionHeader *colhdr;
	MemoryContext oldcontext;

	/* stuff done only on the first call of the function */
	if (SRF_IS_FIRSTCALL())
	{
		pgstat_report_wait_start(collection_we_to_table);
		funcctx = SRF_FIRSTCALL_INIT();

		oldcontext = MemoryContextSwitchTo(funcctx->multi_call_memory_ctx);

		fctx = (to_table_fctx *) palloc(sizeof(to_table_fctx));
		colhdr = fetch_collection(fcinfo, 0);
		fctx->cur = colhdr->head;
		funcctx->user_fctx = fctx;

		MemoryContextSwitchTo(oldcontext);
	}

	funcctx = SRF_PERCALL_SETUP();
	fctx = funcctx->user_fctx;

	if (fctx->cur != NULL)
	{
		Datum		value = CStringGetTextDatum(fctx->cur->key);

		fctx->cur = fctx->cur->hh.next;

		SRF_RETURN_NEXT(funcctx, value);
	}
	else
	{
		pgstat_report_wait_end();
		/* do when there is no more left */
		SRF_RETURN_DONE(funcctx);
	}
}

Datum
collection_values_to_table(PG_FUNCTION_ARGS)
{
	typedef struct
	{
		collection *cur;
		int16		typelen;
		bool		typebyval;
	}			to_table_fctx;

	FuncCallContext *funcctx;
	to_table_fctx *fctx;
	CollectionHeader *colhdr;
	MemoryContext oldcontext;
	Oid			rettype;

	/* stuff done only on the first call of the function */
	if (SRF_IS_FIRSTCALL())
	{
		pgstat_report_wait_start(collection_we_to_table);
		funcctx = SRF_FIRSTCALL_INIT();

		oldcontext = MemoryContextSwitchTo(funcctx->multi_call_memory_ctx);

		fctx = (to_table_fctx *) palloc(sizeof(to_table_fctx));
		colhdr = fetch_collection(fcinfo, 0);
		fctx->cur = colhdr->head;
		fctx->typelen = colhdr->value_type_len;
		fctx->typebyval = colhdr->value_byval;
		funcctx->user_fctx = fctx;

		get_call_result_type(fcinfo, &rettype, NULL);

		if (!can_coerce_type(1, &rettype, &colhdr->value_type, COERCION_IMPLICIT))
		{
			ereport(ERROR,
					(errcode(ERRCODE_DATATYPE_MISMATCH),
					 errmsg("Value type does not match the return type")));
		}

		MemoryContextSwitchTo(oldcontext);
	}

	funcctx = SRF_PERCALL_SETUP();
	fctx = funcctx->user_fctx;

	if (fctx->cur != NULL)
	{
		if (fctx->cur->isnull)
		{
			fctx->cur = fctx->cur->hh.next;
			SRF_RETURN_NEXT_NULL(funcctx);
		}
		else
		{
			Datum		value = datumCopy(fctx->cur->value, fctx->typebyval, fctx->typelen);

			fctx->cur = fctx->cur->hh.next;
			SRF_RETURN_NEXT(funcctx, value);
		}
	}
	else
	{
		pgstat_report_wait_end();
		/* do when there is no more left */
		SRF_RETURN_DONE(funcctx);
	}
}

Datum
collection_to_table(PG_FUNCTION_ARGS)
{
	typedef struct
	{
		collection *cur;
		int16		typelen;
		bool		typebyval;
		TupleDesc	tupdesc;
	}			to_table_fctx;

	FuncCallContext *funcctx;
	to_table_fctx *fctx;
	CollectionHeader *colhdr;
	MemoryContext oldcontext;
	Oid			rettype;
	ReturnSetInfo *rsinfo = (ReturnSetInfo *) fcinfo->resultinfo;

	/* stuff done only on the first call of the function */
	if (SRF_IS_FIRSTCALL())
	{
		/* check to see if caller supports us returning a tuplestore */
		if (rsinfo == NULL || !IsA(rsinfo, ReturnSetInfo))
			ereport(ERROR,
					(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
					 errmsg("set-valued function called in context that cannot accept a set")));
		if (!(rsinfo->allowedModes & SFRM_Materialize))
			ereport(ERROR,
					(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
					 errmsg("materialize mode required, but it is not allowed in this context")));

		pgstat_report_wait_start(collection_we_to_table);
		funcctx = SRF_FIRSTCALL_INIT();

		oldcontext = MemoryContextSwitchTo(funcctx->multi_call_memory_ctx);

		fctx = (to_table_fctx *) palloc(sizeof(to_table_fctx));
		colhdr = fetch_collection(fcinfo, 0);
		fctx->cur = colhdr->head;
		fctx->typelen = colhdr->value_type_len;
		fctx->typebyval = colhdr->value_byval;

		if (rsinfo->expectedDesc->natts != 2)
			ereport(ERROR,
					(errcode(ERRCODE_DATATYPE_MISMATCH),
					 errmsg("Return record must have 2 attributes")));

		rettype = TupleDescAttr(rsinfo->expectedDesc, 1)->atttypid;

		if (!can_coerce_type(1, &rettype, &colhdr->value_type, COERCION_IMPLICIT))
			ereport(ERROR,
					(errcode(ERRCODE_DATATYPE_MISMATCH),
					 errmsg("Value type does not match the return type")));

		fctx->tupdesc = CreateTupleDescCopy(rsinfo->expectedDesc);

		funcctx->user_fctx = fctx;

		MemoryContextSwitchTo(oldcontext);
	}

	funcctx = SRF_PERCALL_SETUP();
	fctx = funcctx->user_fctx;

	if (fctx->cur != NULL)
	{
		Datum		values[2];
		bool		nulls[2] = {0};
		HeapTuple	tuple;

		values[0] = CStringGetTextDatum(fctx->cur->key);

		if (fctx->cur->isnull)
			nulls[1] = true;
		else
			values[1] = datumCopy(fctx->cur->value, fctx->typebyval, fctx->typelen);

		tuple = heap_form_tuple(fctx->tupdesc, values, nulls);

		fctx->cur = fctx->cur->hh.next;

		SRF_RETURN_NEXT(funcctx, HeapTupleGetDatum(tuple));
	}
	else
	{
		pgstat_report_wait_end();
		/* do when there is no more left */
		SRF_RETURN_DONE(funcctx);
	}
}

Datum
collection_value_type(PG_FUNCTION_ARGS)
{
	CollectionHeader *colhdr;

	colhdr = fetch_collection(fcinfo, 0);

	if (colhdr->head == NULL || colhdr->value_type == InvalidOid)
		PG_RETURN_NULL();

	PG_RETURN_OID(colhdr->value_type);
}

Datum
collection_stats(PG_FUNCTION_ARGS)
{
	Datum		result;
	TupleDesc	tupleDesc;
	char	   *values[6];
	int			j;
	HeapTuple	tuple;

	if (get_call_result_type(fcinfo, NULL, &tupleDesc) != TYPEFUNC_COMPOSITE)
		elog(ERROR, "return type must be a row type");

	j = 0;
	values[j++] = psprintf(INT64_FORMAT, (int64) stats.add);
	values[j++] = psprintf(INT64_FORMAT, (int64) stats.context_switch);
	values[j++] = psprintf(INT64_FORMAT, (int64) stats.delete);
	values[j++] = psprintf(INT64_FORMAT, (int64) stats.find);
	values[j++] = psprintf(INT64_FORMAT, (int64) stats.sort);
	values[j++] = psprintf(INT64_FORMAT, (int64) stats.exist);

	tuple = BuildTupleFromCStrings(TupleDescGetAttInMetadata(tupleDesc),
								   values);

	result = HeapTupleGetDatum(tuple);
	PG_RETURN_DATUM(result);
}

Datum
collection_stats_reset(PG_FUNCTION_ARGS)
{
	stats.add = 0;
	stats.context_switch = 0;
	stats.delete = 0;
	stats.find = 0;
	stats.exist = 0;
	stats.sort = 0;

	PG_RETURN_VOID();
}

static int
by_key(const struct collection *a, const struct collection *b)
{
	return varstr_cmp(a->key, strlen(a->key), b->key, strlen(b->key), collection_collation);
}
