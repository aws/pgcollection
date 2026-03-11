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

#include "access/htup_details.h"
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
PG_FUNCTION_INFO_V1(collection_delete_all);
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

PG_FUNCTION_INFO_V1(collection_next_key);
PG_FUNCTION_INFO_V1(collection_prev_key);
PG_FUNCTION_INFO_V1(collection_first_key);
PG_FUNCTION_INFO_V1(collection_last_key);

PG_FUNCTION_INFO_V1(collection_value_type);
PG_FUNCTION_INFO_V1(collection_stats);
PG_FUNCTION_INFO_V1(collection_stats_reset);

StatsCounters stats;

static Oid	collection_collation = DEFAULT_COLLATION_OID;

static int	by_key(const struct collection *a, const struct collection *b);
static collection * find_internal(CollectionHeader * colhdr, char *key);

Datum
collection_add(PG_FUNCTION_ARGS)
{
	CollectionHeader *colhdr;
	MemoryContext oldcxt;
	collection *item;
	collection *replaced_item;
	char	   *key;
	Datum		item_value;
	bool		item_isnull;
	Oid			argtype;

	if (PG_ARGISNULL(1))
		ereport(ERROR,
				(errcode(ERRCODE_DATATYPE_MISMATCH),
				 errmsg("Key must not be null")));

	colhdr = fetch_collection(fcinfo, 0);

	pgstat_report_wait_start(collection_we_add);

	argtype = get_fn_expr_argtype(fcinfo->flinfo, 2);

	oldcxt = collection_add_setup((CollectionHeaderCommon *) colhdr,
								  argtype, PG_GETARG_DATUM(2),
								  PG_ARGISNULL(2),
								  &item_value, &item_isnull);

	key = text_to_cstring(PG_GETARG_TEXT_PP(1));
	VALIDATE_KEY_LENGTH(key);

	item = (collection *) palloc(sizeof(collection));
	item->key = key;
	item->value = item_value;
	item->isnull = item_isnull;

	HASH_REPLACE(hh, colhdr->head, key[0], strlen(key), item, replaced_item);

	collection_replace_cleanup(replaced_item,
							   replaced_item ? replaced_item->key : NULL,
							   replaced_item ? replaced_item->isnull : true,
							   replaced_item ? replaced_item->value : (Datum) 0,
							   colhdr->value_byval);

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
	CollectionHeader *colhdr;

	if (PG_ARGISNULL(0))
		return 0;

	colhdr = fetch_collection(fcinfo, 0);

	PG_RETURN_INT32(collection_count_common((CollectionHeaderCommon *) colhdr));
}

Datum
collection_find(PG_FUNCTION_ARGS)
{
	char	   *key;
	collection *item;
	Datum		value;
	bool		resnull;
	Oid			rettype;
	CollectionHeader *colhdr;

	if (PG_ARGISNULL(1))
		PG_RETURN_NULL();

	key = text_to_cstring(PG_GETARG_TEXT_PP(1));
	VALIDATE_KEY_LENGTH(key);

	if (PG_ARGISNULL(0))
		ereport(ERROR,
				(errcode(ERRCODE_NO_DATA_FOUND),
				 errmsg("key \"%s\" not found", key)));

	colhdr = fetch_collection(fcinfo, 0);
	if (colhdr->head == NULL)
	{
		stats.find++;
		ereport(ERROR,
				(errcode(ERRCODE_NO_DATA_FOUND),
				 errmsg("key \"%s\" not found", key)));
	}

	item = find_internal(colhdr, key);

	get_call_result_type(fcinfo, &rettype, NULL);
	value = collection_fetch_value((CollectionHeaderCommon *) colhdr,
								   item->value, item->isnull,
								   rettype, &resnull);

	stats.find++;
	pgstat_report_wait_end();

	if (resnull)
		PG_RETURN_NULL();

	PG_RETURN_DATUM(value);
}

Datum
collection_exist(PG_FUNCTION_ARGS)
{
	char	   *key;
	collection *item;
	CollectionHeader *colhdr;

	if (PG_ARGISNULL(0) || PG_ARGISNULL(1))
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
	VALIDATE_KEY_LENGTH(key);

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
		VALIDATE_KEY_LENGTH(key);

		HASH_FIND(hh, colhdr->head, key, strlen(key), item);

		if (item == NULL)
		{
			stats.delete++;
			pgstat_report_wait_end();
			PG_RETURN_DATUM(EOHPGetRWDatum(&colhdr->hdr));
		}

		if (item == colhdr->current)
			colhdr->current = item->hh.next;
		HASH_DEL(colhdr->head, item);
		if (item->key)
			pfree(item->key);
		if (!item->isnull && item->value && !colhdr->value_byval)
			pfree(DatumGetPointer(item->value));
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
collection_delete_all(PG_FUNCTION_ARGS)
{
	CollectionHeader *colhdr;
	collection *item;
	collection *tmp;

	colhdr = fetch_collection(fcinfo, 0);

	pgstat_report_wait_start(collection_we_delete);

	HASH_ITER(hh, colhdr->head, item, tmp)
	{
		HASH_DEL(colhdr->head, item);
		if (item->key)
			pfree(item->key);
		if (!item->isnull && item->value && !colhdr->value_byval)
			pfree(DatumGetPointer(item->value));
		pfree(item);
	}

	colhdr->head = NULL;
	colhdr->current = NULL;
	colhdr->flat_size = 0;

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
		collection *replaced_item;
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

			HASH_REPLACE(hh, copyhdr->head, key[0], strlen(key), item, replaced_item);
			if (replaced_item)
			{
				pfree(replaced_item->key);
				pfree(replaced_item);
			}

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

	get_call_result_type(fcinfo, &rettype, NULL);
	value = collection_coerce_value(colhdr->current->value,
									colhdr->value_type,
									colhdr->value_byval,
									colhdr->value_type_len,
									rettype);

	pgstat_report_wait_end();

	PG_RETURN_DATUM(value);
}

Datum
collection_isnull(PG_FUNCTION_ARGS)
{
	CollectionHeader *colhdr;

	if (PG_ARGISNULL(0))
		PG_RETURN_BOOL(true);

	colhdr = fetch_collection(fcinfo, 0);

	PG_RETURN_BOOL(collection_isnull_common((CollectionHeaderCommon *) colhdr));
}

Datum
collection_next(PG_FUNCTION_ARGS)
{
	CollectionHeader *colhdr;

	colhdr = fetch_collection(fcinfo, 0);
	collection_next_common((CollectionHeaderCommon *) colhdr);

	PG_RETURN_DATUM(EOHPGetRWDatum(&colhdr->hdr));
}

Datum
collection_prev(PG_FUNCTION_ARGS)
{
	CollectionHeader *colhdr;

	colhdr = fetch_collection(fcinfo, 0);
	collection_prev_common((CollectionHeaderCommon *) colhdr);

	PG_RETURN_DATUM(EOHPGetRWDatum(&colhdr->hdr));
}

Datum
collection_first(PG_FUNCTION_ARGS)
{
	CollectionHeader *colhdr;

	colhdr = fetch_collection(fcinfo, 0);
	collection_first_common((CollectionHeaderCommon *) colhdr);

	PG_RETURN_DATUM(EOHPGetRWDatum(&colhdr->hdr));
}

Datum
collection_last(PG_FUNCTION_ARGS)
{
	CollectionHeader *colhdr;

	colhdr = fetch_collection(fcinfo, 0);
	collection_last_common((CollectionHeaderCommon *) colhdr);

	PG_RETURN_DATUM(EOHPGetRWDatum(&colhdr->hdr));
}

Datum
collection_next_key(PG_FUNCTION_ARGS)
{
	char	   *key;
	collection *item;
	collection *next;
	CollectionHeader *colhdr;

	colhdr = fetch_collection(fcinfo, 0);
	if (colhdr->head == NULL)
	{
		stats.find++;
		PG_RETURN_NULL();
	}

	key = text_to_cstring(PG_GETARG_TEXT_PP(1));
	VALIDATE_KEY_LENGTH(key);

	item = find_internal(colhdr, key);

	next = (collection *) item->hh.next;

	if (next == NULL)
		PG_RETURN_NULL();

	PG_RETURN_TEXT_P(cstring_to_text(next->key));
}

Datum
collection_prev_key(PG_FUNCTION_ARGS)
{
	char	   *key;
	collection *item;
	collection *prev;
	CollectionHeader *colhdr;

	colhdr = fetch_collection(fcinfo, 0);
	if (colhdr->head == NULL)
	{
		stats.find++;
		PG_RETURN_NULL();
	}

	key = text_to_cstring(PG_GETARG_TEXT_PP(1));
	VALIDATE_KEY_LENGTH(key);

	item = find_internal(colhdr, key);

	prev = (collection *) item->hh.prev;

	if (prev == NULL)
		PG_RETURN_NULL();

	PG_RETURN_TEXT_P(cstring_to_text(prev->key));
}

Datum
collection_first_key(PG_FUNCTION_ARGS)
{
	CollectionHeader *colhdr;

	colhdr = fetch_collection(fcinfo, 0);
	if (colhdr->head == NULL)
	{
		stats.find++;
		PG_RETURN_NULL();
	}

	PG_RETURN_TEXT_P(cstring_to_text(colhdr->head->key));
}

Datum
collection_last_key(PG_FUNCTION_ARGS)
{
	collection *item;
	CollectionHeader *colhdr;

	colhdr = fetch_collection(fcinfo, 0);
	if (colhdr->head == NULL)
	{
		stats.find++;
		PG_RETURN_NULL();
	}

	item = (collection *) ELMT_FROM_HH(colhdr->head->hh.tbl, colhdr->head->hh.tbl->tail);

	PG_RETURN_TEXT_P(cstring_to_text(item->key));
}

/* SRF callbacks for collection */
static Datum
col_srf_get_key(void *cur)
{
	return CStringGetTextDatum(((collection *) cur)->key);
}

static Datum
col_srf_get_value(void *cur)
{
	return ((collection *) cur)->value;
}

static bool
col_srf_get_isnull(void *cur)
{
	return ((collection *) cur)->isnull;
}

static void *
col_srf_get_next(void *cur)
{
	return ((collection *) cur)->hh.next;
}

static CollectionSRFContext col_srf_tmpl =
{
	.get_key = col_srf_get_key,
		.get_value = col_srf_get_value,
		.get_isnull = col_srf_get_isnull,
		.get_next = col_srf_get_next,
};

Datum
collection_keys_to_table(PG_FUNCTION_ARGS)
{
	CollectionHeader *colhdr;
	CollectionSRFContext tmpl;

	if (SRF_IS_FIRSTCALL())
	{
		pgstat_report_wait_start(collection_we_to_table);
		colhdr = fetch_collection(fcinfo, 0);
		tmpl = col_srf_tmpl;
		tmpl.eoh = &colhdr->hdr;
		return collection_srf_keys_to_table(fcinfo, colhdr->head, &tmpl);
	}

	return collection_srf_keys_to_table(fcinfo, NULL, NULL);
}

Datum
collection_values_to_table(PG_FUNCTION_ARGS)
{
	CollectionHeader *colhdr;
	CollectionSRFContext tmpl;

	if (SRF_IS_FIRSTCALL())
	{
		pgstat_report_wait_start(collection_we_to_table);
		colhdr = fetch_collection(fcinfo, 0);
		tmpl = col_srf_tmpl;
		tmpl.eoh = &colhdr->hdr;
		tmpl.typelen = colhdr->value_type_len;
		tmpl.typebyval = colhdr->value_byval;
		return collection_srf_values_to_table(fcinfo, colhdr->head,
											  colhdr->value_type, &tmpl);
	}

	return collection_srf_values_to_table(fcinfo, NULL, InvalidOid, NULL);
}

Datum
collection_to_table(PG_FUNCTION_ARGS)
{
	CollectionHeader *colhdr;
	CollectionSRFContext tmpl;

	if (SRF_IS_FIRSTCALL())
	{
		pgstat_report_wait_start(collection_we_to_table);
		colhdr = fetch_collection(fcinfo, 0);
		tmpl = col_srf_tmpl;
		tmpl.eoh = &colhdr->hdr;
		tmpl.typelen = colhdr->value_type_len;
		tmpl.typebyval = colhdr->value_byval;
		return collection_srf_to_table(fcinfo, colhdr->head,
									   colhdr->value_type, &tmpl);
	}

	return collection_srf_to_table(fcinfo, NULL, InvalidOid, NULL);
}

Datum
collection_value_type(PG_FUNCTION_ARGS)
{
	CollectionHeader *colhdr;
	Datum		result;

	colhdr = fetch_collection(fcinfo, 0);
	result = collection_value_type_common((CollectionHeaderCommon *) colhdr);

	if (result == (Datum) 0)
		PG_RETURN_NULL();

	PG_RETURN_DATUM(result);
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

static collection *
find_internal(CollectionHeader * colhdr, char *key)
{
	collection *item;

	pgstat_report_wait_start(collection_we_find);

	HASH_FIND(hh, colhdr->head, key, strlen(key), item);

	stats.find++;
	pgstat_report_wait_end();

	if (item == NULL)
	{
		ereport(ERROR,
				(errcode(ERRCODE_NO_DATA_FOUND),
				 errmsg("key \"%s\" not found", key)));
	}

	return item;
}
