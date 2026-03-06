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

#include "catalog/pg_type.h"
#include "collection.h"
#include "fmgr.h"
#include "funcapi.h"
#include "parser/parse_coerce.h"
#include "utils/builtins.h"
#include "utils/datum.h"
#include "utils/expandeddatum.h"
#include "utils/lsyscache.h"
#include "utils/memutils.h"

PG_FUNCTION_INFO_V1(icollection_add);
PG_FUNCTION_INFO_V1(icollection_find);
PG_FUNCTION_INFO_V1(icollection_exist);
PG_FUNCTION_INFO_V1(icollection_count);
PG_FUNCTION_INFO_V1(icollection_delete);
PG_FUNCTION_INFO_V1(icollection_first);
PG_FUNCTION_INFO_V1(icollection_last);
PG_FUNCTION_INFO_V1(icollection_next);
PG_FUNCTION_INFO_V1(icollection_prev);
PG_FUNCTION_INFO_V1(icollection_key);
PG_FUNCTION_INFO_V1(icollection_value);
PG_FUNCTION_INFO_V1(icollection_isnull);
PG_FUNCTION_INFO_V1(icollection_sort);
PG_FUNCTION_INFO_V1(icollection_copy);
PG_FUNCTION_INFO_V1(icollection_value_type);
PG_FUNCTION_INFO_V1(icollection_keys_to_table);
PG_FUNCTION_INFO_V1(icollection_values_to_table);
PG_FUNCTION_INFO_V1(icollection_to_table);
PG_FUNCTION_INFO_V1(icollection_next_key);
PG_FUNCTION_INFO_V1(icollection_prev_key);
PG_FUNCTION_INFO_V1(icollection_first_key);
PG_FUNCTION_INFO_V1(icollection_last_key);

/* Forward declaration */
static int icollection_by_key(const struct icollection *a, const struct icollection *b);

/*
 * icollection_add
 *		Add a key-value pair to an icollection
 */
Datum
icollection_add(PG_FUNCTION_ARGS)
{
	ICollectionHeader *hdr;
	MemoryContext oldcxt;
	icollection *item;
	icollection *replaced_item;
	int64		key;
	Datum		value;
	Oid			argtype;
	int16		argtypelen;
	bool		argtypebyval;

	if (PG_ARGISNULL(1))
		ereport(ERROR,
				(errcode(ERRCODE_DATATYPE_MISMATCH),
				 errmsg("key must not be null")));

	hdr = fetch_icollection(fcinfo, 0);

	oldcxt = MemoryContextSwitchTo(hdr->hdr.eoh_context);

	key = PG_GETARG_INT64(1);

	item = (icollection *) palloc(sizeof(icollection));
	item->key = key;

	argtype = get_fn_expr_argtype(fcinfo->flinfo, 2);
	get_typlenbyval(argtype, &argtypelen, &argtypebyval);

	/* Set the value type of the collection to the first element added */
	if (hdr->value_type == InvalidOid)
	{
		hdr->value_type = argtype;
		hdr->value_type_len = argtypelen;
		hdr->value_byval = argtypebyval;
	}
	else
	{
		if (!can_coerce_type(1, &argtype, &hdr->value_type, COERCION_IMPLICIT))
		{
			ereport(ERROR,
					(errcode(ERRCODE_DATATYPE_MISMATCH),
					 errmsg("incompatible value data type"),
					 errdetail("expecting %s, but received %s",
							   format_type_extended(hdr->value_type, -1, 0),
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

	ICOLLECTION_HASH_REPLACE(hdr->head, key, item, replaced_item);

	if (replaced_item)
	{
		if (!replaced_item->isnull && replaced_item->value && !argtypebyval)
			pfree(DatumGetPointer(replaced_item->value));
		pfree(replaced_item);
	}

	if (hdr->current == NULL)
		hdr->current = hdr->head;

	MemoryContextSwitchTo(oldcxt);

	PG_RETURN_DATUM(EOHPGetRWDatum(&hdr->hdr));
}

/*
 * icollection_find
 *		Find a value by key
 */
Datum
icollection_find(PG_FUNCTION_ARGS)
{
	ICollectionHeader *hdr;
	int64		key;
	icollection *item;
	Oid			outfuncoid;
	bool		typisvarlena;
	char	   *value_str;

	if (PG_ARGISNULL(1))
		ereport(ERROR,
				(errcode(ERRCODE_DATATYPE_MISMATCH),
				 errmsg("key must not be null")));

	hdr = fetch_icollection(fcinfo, 0);
	key = PG_GETARG_INT64(1);

	ICOLLECTION_HASH_FIND(hdr->head, &key, item);

	if (item == NULL)
		ereport(ERROR,
				(errcode(ERRCODE_DATATYPE_MISMATCH),
				 errmsg("key \"%lld\" not found", (long long) key)));

	if (item->isnull)
		PG_RETURN_NULL();

	getTypeOutputInfo(hdr->value_type, &outfuncoid, &typisvarlena);
	value_str = DatumGetCString(OidFunctionCall1(outfuncoid, item->value));

	PG_RETURN_TEXT_P(cstring_to_text(value_str));
}

/*
 * icollection_exist
 *		Check if a key exists
 */
Datum
icollection_exist(PG_FUNCTION_ARGS)
{
	ICollectionHeader *hdr;
	int64		key;
	icollection *item;

	if (PG_ARGISNULL(1))
		PG_RETURN_BOOL(false);

	hdr = fetch_icollection(fcinfo, 0);
	key = PG_GETARG_INT64(1);

	ICOLLECTION_HASH_FIND(hdr->head, &key, item);

	PG_RETURN_BOOL(item != NULL);
}

/*
 * icollection_count
 *		Return the number of entries
 */
Datum
icollection_count(PG_FUNCTION_ARGS)
{
	ICollectionHeader *hdr;

	hdr = fetch_icollection(fcinfo, 0);

	PG_RETURN_INT32(HASH_COUNT(hdr->head));
}

/*
 * icollection_delete
 *		Delete entry by key
 */
Datum
icollection_delete(PG_FUNCTION_ARGS)
{
	ICollectionHeader *hdr;
	int64		key;
	icollection *item;

	hdr = fetch_icollection(fcinfo, 0);
	key = PG_GETARG_INT64(1);

	if (hdr->head)
	{
		ICOLLECTION_HASH_FIND(hdr->head, &key, item);

		if (item == NULL)
			PG_RETURN_DATUM(EOHPGetRWDatum(&hdr->hdr));

		if (item == hdr->current)
			hdr->current = item->hh.next;

		ICOLLECTION_HASH_DELETE(hdr->head, item);

		if (!item->isnull && item->value && !hdr->value_byval)
			pfree(DatumGetPointer(item->value));
		pfree(item);

		if (HASH_COUNT(hdr->head) == 0)
		{
			hdr->head = NULL;
			hdr->current = NULL;
		}
	}

	PG_RETURN_DATUM(EOHPGetRWDatum(&hdr->hdr));
}

/*
 * icollection_first
 *		Move iterator to first entry
 */
Datum
icollection_first(PG_FUNCTION_ARGS)
{
	ICollectionHeader *hdr;

	hdr = fetch_icollection(fcinfo, 0);
	hdr->current = hdr->head;

	PG_RETURN_DATUM(EOHPGetRWDatum(&hdr->hdr));
}

/*
 * icollection_last
 *		Move iterator to last entry
 */
Datum
icollection_last(PG_FUNCTION_ARGS)
{
	ICollectionHeader *hdr;
	icollection *item;

	hdr = fetch_icollection(fcinfo, 0);

	if (hdr->head != NULL)
	{
		for (item = hdr->head; item->hh.next != NULL; item = item->hh.next)
			;
		hdr->current = item;
	}
	else
		hdr->current = NULL;

	PG_RETURN_DATUM(EOHPGetRWDatum(&hdr->hdr));
}

/*
 * icollection_next
 *		Move iterator to next entry
 */
Datum
icollection_next(PG_FUNCTION_ARGS)
{
	ICollectionHeader *hdr;

	hdr = fetch_icollection(fcinfo, 0);

	if (hdr->current != NULL)
		hdr->current = hdr->current->hh.next;

	PG_RETURN_DATUM(EOHPGetRWDatum(&hdr->hdr));
}

/*
 * icollection_prev
 *		Move iterator to previous entry
 */
Datum
icollection_prev(PG_FUNCTION_ARGS)
{
	ICollectionHeader *hdr;

	hdr = fetch_icollection(fcinfo, 0);

	if (hdr->current != NULL)
		hdr->current = hdr->current->hh.prev;

	PG_RETURN_DATUM(EOHPGetRWDatum(&hdr->hdr));
}

/*
 * icollection_key
 *		Get current iterator key
 */
Datum
icollection_key(PG_FUNCTION_ARGS)
{
	ICollectionHeader *hdr;

	hdr = fetch_icollection(fcinfo, 0);

	if (hdr->current == NULL)
		PG_RETURN_NULL();

	PG_RETURN_INT64(hdr->current->key);
}

/*
 * icollection_value
 *		Get current iterator value
 */
Datum
icollection_value(PG_FUNCTION_ARGS)
{
	ICollectionHeader *hdr;
	Oid			outfuncoid;
	bool		typisvarlena;
	char	   *value_str;

	hdr = fetch_icollection(fcinfo, 0);

	if (hdr->current == NULL || hdr->current->isnull)
		PG_RETURN_NULL();

	getTypeOutputInfo(hdr->value_type, &outfuncoid, &typisvarlena);
	value_str = DatumGetCString(OidFunctionCall1(outfuncoid, hdr->current->value));

	PG_RETURN_TEXT_P(cstring_to_text(value_str));
}

/*
 * icollection_isnull
 *		Check if iterator is at valid position
 */
Datum
icollection_isnull(PG_FUNCTION_ARGS)
{
	ICollectionHeader *hdr;

	hdr = fetch_icollection(fcinfo, 0);

	PG_RETURN_BOOL(hdr->current == NULL);
}

/*
 * icollection_sort
 *		Sort icollection by key (numeric order)
 */
Datum
icollection_sort(PG_FUNCTION_ARGS)
{
	ICollectionHeader *hdr;

	hdr = fetch_icollection(fcinfo, 0);

	if (hdr->head)
	{
		HASH_SRT(hh, hdr->head, icollection_by_key);
		hdr->current = hdr->head;
	}

	PG_RETURN_DATUM(EOHPGetRWDatum(&hdr->hdr));
}

/*
 * icollection_copy
 *		Create a deep copy of an icollection
 */
Datum
icollection_copy(PG_FUNCTION_ARGS)
{
	ICollectionHeader *hdr;
	ICollectionHeader *copyhdr;

	hdr = fetch_icollection(fcinfo, 0);

	if (hdr->head)
	{
		MemoryContext oldcxt;
		icollection *iter;
		icollection *item;
		icollection *replaced_item;

		copyhdr = construct_empty_icollection(CurrentMemoryContext);

		oldcxt = MemoryContextSwitchTo(copyhdr->hdr.eoh_context);

		copyhdr->value_type = hdr->value_type;
		copyhdr->value_type_len = hdr->value_type_len;
		copyhdr->value_byval = hdr->value_byval;

		for (iter = hdr->head; iter != NULL; iter = iter->hh.next)
		{
			item = (icollection *) palloc(sizeof(icollection));
			item->key = iter->key;
			item->isnull = iter->isnull;
			if (!iter->isnull)
				item->value = datumCopy(iter->value, hdr->value_byval, hdr->value_type_len);

			ICOLLECTION_HASH_REPLACE(copyhdr->head, key, item, replaced_item);
			if (replaced_item)
				pfree(replaced_item);
		}

		copyhdr->current = copyhdr->head;

		MemoryContextSwitchTo(oldcxt);
	}
	else
		copyhdr = construct_empty_icollection(CurrentMemoryContext);

	PG_RETURN_DATUM(EOHPGetRWDatum(&copyhdr->hdr));
}

/*
 * icollection_value_type
 *		Return the OID of the value type
 */
Datum
icollection_value_type(PG_FUNCTION_ARGS)
{
	ICollectionHeader *hdr;

	hdr = fetch_icollection(fcinfo, 0);

	PG_RETURN_OID(hdr->value_type);
}

/*
 * icollection_by_key
 *		Comparison function for sorting by key
 */
static int
icollection_by_key(const struct icollection *a, const struct icollection *b)
{
	if (a->key < b->key)
		return -1;
	if (a->key > b->key)
		return 1;
	return 0;
}

/*
 * icollection_keys_to_table
 *		Return all keys as a table
 */
Datum
icollection_keys_to_table(PG_FUNCTION_ARGS)
{
	typedef struct
	{
		icollection *cur;
	} keys_fctx;

	FuncCallContext *funcctx;
	keys_fctx *fctx;
	ICollectionHeader *hdr;
	MemoryContext oldcontext;

	if (SRF_IS_FIRSTCALL())
	{
		funcctx = SRF_FIRSTCALL_INIT();
		oldcontext = MemoryContextSwitchTo(funcctx->multi_call_memory_ctx);

		fctx = (keys_fctx *) palloc(sizeof(keys_fctx));
		hdr = fetch_icollection(fcinfo, 0);
		fctx->cur = hdr->head;
		funcctx->user_fctx = fctx;

		MemoryContextSwitchTo(oldcontext);
	}

	funcctx = SRF_PERCALL_SETUP();
	fctx = funcctx->user_fctx;

	if (fctx->cur != NULL)
	{
		Datum value = Int64GetDatum(fctx->cur->key);
		fctx->cur = fctx->cur->hh.next;
		SRF_RETURN_NEXT(funcctx, value);
	}
	else
	{
		SRF_RETURN_DONE(funcctx);
	}
}

/*
 * icollection_values_to_table
 *		Return all values as a table
 */
Datum
icollection_values_to_table(PG_FUNCTION_ARGS)
{
	typedef struct
	{
		icollection *cur;
		ICollectionHeader *hdr;
	} values_fctx;

	FuncCallContext *funcctx;
	values_fctx *fctx;
	ICollectionHeader *hdr;
	MemoryContext oldcontext;

	if (SRF_IS_FIRSTCALL())
	{
		funcctx = SRF_FIRSTCALL_INIT();
		oldcontext = MemoryContextSwitchTo(funcctx->multi_call_memory_ctx);

		fctx = (values_fctx *) palloc(sizeof(values_fctx));
		hdr = fetch_icollection(fcinfo, 0);
		fctx->hdr = hdr;
		fctx->cur = hdr->head;
		funcctx->user_fctx = fctx;

		MemoryContextSwitchTo(oldcontext);
	}

	funcctx = SRF_PERCALL_SETUP();
	fctx = funcctx->user_fctx;

	if (fctx->cur != NULL)
	{
		Datum value;
		Oid outfuncoid;
		bool typisvarlena;
		char *value_str;

		if (fctx->cur->isnull)
		{
			fctx->cur = fctx->cur->hh.next;
			SRF_RETURN_NEXT_NULL(funcctx);
		}

		getTypeOutputInfo(fctx->hdr->value_type, &outfuncoid, &typisvarlena);
		value_str = DatumGetCString(OidFunctionCall1(outfuncoid, fctx->cur->value));
		value = CStringGetTextDatum(value_str);

		fctx->cur = fctx->cur->hh.next;
		SRF_RETURN_NEXT(funcctx, value);
	}
	else
	{
		SRF_RETURN_DONE(funcctx);
	}
}

/*
 * icollection_to_table
 *		Return all key-value pairs as a table
 */
Datum
icollection_to_table(PG_FUNCTION_ARGS)
{
	typedef struct
	{
		icollection *cur;
		ICollectionHeader *hdr;
	} to_table_fctx;

	FuncCallContext *funcctx;
	to_table_fctx *fctx;
	ICollectionHeader *hdr;
	MemoryContext oldcontext;

	if (SRF_IS_FIRSTCALL())
	{
		TupleDesc tupdesc;

		funcctx = SRF_FIRSTCALL_INIT();
		oldcontext = MemoryContextSwitchTo(funcctx->multi_call_memory_ctx);

		fctx = (to_table_fctx *) palloc(sizeof(to_table_fctx));
		hdr = fetch_icollection(fcinfo, 0);
		fctx->hdr = hdr;
		fctx->cur = hdr->head;
		funcctx->user_fctx = fctx;

		/* Build tuple descriptor */
		if (get_call_result_type(fcinfo, NULL, &tupdesc) != TYPEFUNC_COMPOSITE)
			ereport(ERROR,
					(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
					 errmsg("function returning record called in context that cannot accept type record")));

		funcctx->tuple_desc = BlessTupleDesc(tupdesc);

		MemoryContextSwitchTo(oldcontext);
	}

	funcctx = SRF_PERCALL_SETUP();
	fctx = funcctx->user_fctx;

	if (fctx->cur != NULL)
	{
		Datum values[2];
		bool nulls[2];
		HeapTuple tuple;
		Datum result;
		Oid outfuncoid;
		bool typisvarlena;
		char *value_str;

		/* Key */
		values[0] = Int64GetDatum(fctx->cur->key);
		nulls[0] = false;

		/* Value */
		if (fctx->cur->isnull)
		{
			values[1] = (Datum) 0;
			nulls[1] = true;
		}
		else
		{
			getTypeOutputInfo(fctx->hdr->value_type, &outfuncoid, &typisvarlena);
			value_str = DatumGetCString(OidFunctionCall1(outfuncoid, fctx->cur->value));
			values[1] = CStringGetTextDatum(value_str);
			nulls[1] = false;
		}

		tuple = heap_form_tuple(funcctx->tuple_desc, values, nulls);
		result = HeapTupleGetDatum(tuple);

		fctx->cur = fctx->cur->hh.next;
		SRF_RETURN_NEXT(funcctx, result);
	}
	else
	{
		SRF_RETURN_DONE(funcctx);
	}
}

Datum
icollection_next_key(PG_FUNCTION_ARGS)
{
	int64		key;
	icollection *item;
	icollection *next;
	ICollectionHeader *icolhdr;

	icolhdr = fetch_icollection(fcinfo, 0);
	if (icolhdr->head == NULL)
		PG_RETURN_NULL();

	key = PG_GETARG_INT64(1);

	ICOLLECTION_HASH_FIND(icolhdr->head, &key, item);
	if (item == NULL)
		ereport(ERROR,
				(errcode(ERRCODE_NO_DATA_FOUND),
				 errmsg("key \"%ld\" not found", key)));

	next = (icollection *) item->hh.next;

	if (next == NULL)
		PG_RETURN_NULL();

	PG_RETURN_INT64(next->key);
}

Datum
icollection_prev_key(PG_FUNCTION_ARGS)
{
	int64		key;
	icollection *item;
	icollection *prev;
	ICollectionHeader *icolhdr;

	icolhdr = fetch_icollection(fcinfo, 0);
	if (icolhdr->head == NULL)
		PG_RETURN_NULL();

	key = PG_GETARG_INT64(1);

	ICOLLECTION_HASH_FIND(icolhdr->head, &key, item);
	if (item == NULL)
		ereport(ERROR,
				(errcode(ERRCODE_NO_DATA_FOUND),
				 errmsg("key \"%ld\" not found", key)));

	prev = (icollection *) item->hh.prev;

	if (prev == NULL)
		PG_RETURN_NULL();

	PG_RETURN_INT64(prev->key);
}

Datum
icollection_first_key(PG_FUNCTION_ARGS)
{
	ICollectionHeader *icolhdr;

	icolhdr = fetch_icollection(fcinfo, 0);
	if (icolhdr->head == NULL)
		PG_RETURN_NULL();

	PG_RETURN_INT64(icolhdr->head->key);
}

Datum
icollection_last_key(PG_FUNCTION_ARGS)
{
	icollection *item;
	ICollectionHeader *icolhdr;

	icolhdr = fetch_icollection(fcinfo, 0);
	if (icolhdr->head == NULL)
		PG_RETURN_NULL();

	item = (icollection *) ELMT_FROM_HH(icolhdr->head->hh.tbl, icolhdr->head->hh.tbl->tail);

	PG_RETURN_INT64(item->key);
}
