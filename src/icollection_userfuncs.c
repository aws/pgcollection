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
#include "collection.h"
#include "fmgr.h"
#include "funcapi.h"
#include "parser/parse_coerce.h"
#include "pgstat.h"
#include "utils/builtins.h"
#include "utils/wait_event.h"
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
static int	icollection_by_key(const struct icollection *a, const struct icollection *b);

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
	Datum		item_value;
	bool		item_isnull;
	Oid			argtype;

	if (PG_ARGISNULL(1))
		ereport(ERROR,
				(errcode(ERRCODE_DATATYPE_MISMATCH),
				 errmsg("key must not be null")));

	hdr = fetch_icollection(fcinfo, 0);

	pgstat_report_wait_start(collection_we_add);

	argtype = get_fn_expr_argtype(fcinfo->flinfo, 2);

	oldcxt = collection_add_setup((CollectionHeaderCommon *) hdr,
								  argtype, PG_GETARG_DATUM(2),
								  PG_ARGISNULL(2),
								  &item_value, &item_isnull);

	key = PG_GETARG_INT64(1);

	item = (icollection *) palloc(sizeof(icollection));
	item->key = key;
	item->value = item_value;
	item->isnull = item_isnull;

	ICOLLECTION_HASH_REPLACE(hdr->head, key, item, replaced_item);

	collection_replace_cleanup(replaced_item, NULL,
							   replaced_item ? replaced_item->isnull : true,
							   replaced_item ? replaced_item->value : (Datum) 0,
							   hdr->value_byval);

	if (hdr->current == NULL)
		hdr->current = hdr->head;

	MemoryContextSwitchTo(oldcxt);

	stats.add++;
	pgstat_report_wait_end();

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
	Datum		value;
	bool		resnull;
	Oid			rettype;

	if (PG_ARGISNULL(1))
		PG_RETURN_NULL();

	if (PG_ARGISNULL(0))
		ereport(ERROR,
				(errcode(ERRCODE_NO_DATA_FOUND),
				 errmsg("key not found")));

	hdr = fetch_icollection(fcinfo, 0);
	key = PG_GETARG_INT64(1);

	if (hdr->head == NULL)
	{
		stats.find++;
		ereport(ERROR,
				(errcode(ERRCODE_NO_DATA_FOUND),
				 errmsg("key \"%lld\" not found", (long long) key)));
	}

	pgstat_report_wait_start(collection_we_find);

	ICOLLECTION_HASH_FIND(hdr->head, &key, item);

	if (item == NULL)
	{
		stats.find++;
		pgstat_report_wait_end();
		ereport(ERROR,
				(errcode(ERRCODE_NO_DATA_FOUND),
				 errmsg("key \"%lld\" not found", (long long) key)));
	}

	get_call_result_type(fcinfo, &rettype, NULL);
	value = collection_fetch_value((CollectionHeaderCommon *) hdr,
								   item->value, item->isnull,
								   rettype, &resnull);

	stats.find++;
	pgstat_report_wait_end();

	if (resnull)
		PG_RETURN_NULL();

	PG_RETURN_DATUM(value);
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

	if (PG_ARGISNULL(0) || PG_ARGISNULL(1))
	{
		stats.exist++;
		PG_RETURN_BOOL(false);
	}

	hdr = fetch_icollection(fcinfo, 0);
	if (hdr->head == NULL)
	{
		stats.exist++;
		PG_RETURN_BOOL(false);
	}

	pgstat_report_wait_start(collection_we_exist);

	key = PG_GETARG_INT64(1);

	ICOLLECTION_HASH_FIND(hdr->head, &key, item);

	stats.exist++;
	pgstat_report_wait_end();

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

	if (PG_ARGISNULL(0))
		return 0;

	hdr = fetch_icollection(fcinfo, 0);

	PG_RETURN_INT32(collection_count_common((CollectionHeaderCommon *) hdr));
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

	if (PG_ARGISNULL(1))
		ereport(ERROR,
				(errcode(ERRCODE_DATATYPE_MISMATCH),
				 errmsg("key must not be null")));

	hdr = fetch_icollection(fcinfo, 0);

	pgstat_report_wait_start(collection_we_delete);

	if (hdr->head)
	{
		key = PG_GETARG_INT64(1);

		ICOLLECTION_HASH_FIND(hdr->head, &key, item);

		if (item == NULL)
		{
			stats.delete++;
			pgstat_report_wait_end();
			PG_RETURN_DATUM(EOHPGetRWDatum(&hdr->hdr));
		}

		if (item == hdr->current)
			hdr->current = item->hh.next;

		ICOLLECTION_HASH_DELETE(hdr->head, item);

		if (!item->isnull && item->value && !hdr->value_byval)
			pfree(DatumGetPointer(item->value));
		pfree(item);

		if (HASH_COUNT(hdr->head) == 0)
		{
			HASH_CLEAR(hh, hdr->head);
			hdr->head = NULL;
			hdr->current = NULL;
		}
	}

	stats.delete++;
	pgstat_report_wait_end();

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
	collection_first_common((CollectionHeaderCommon *) hdr);

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

	hdr = fetch_icollection(fcinfo, 0);
	collection_last_common((CollectionHeaderCommon *) hdr);

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
	collection_next_common((CollectionHeaderCommon *) hdr);

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
	collection_prev_common((CollectionHeaderCommon *) hdr);

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
	Datum		value;
	Oid			rettype;

	hdr = fetch_icollection(fcinfo, 0);

	if (hdr->current == NULL || hdr->current->isnull)
		PG_RETURN_NULL();

	pgstat_report_wait_start(collection_we_value);

	get_call_result_type(fcinfo, &rettype, NULL);
	value = collection_coerce_value(hdr->current->value,
									hdr->value_type,
									hdr->value_byval,
									hdr->value_type_len,
									rettype);

	pgstat_report_wait_end();

	PG_RETURN_DATUM(value);
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

	PG_RETURN_BOOL(collection_isnull_common((CollectionHeaderCommon *) hdr));
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

	pgstat_report_wait_start(collection_we_sort);

	if (hdr->head)
	{
		HASH_SRT(hh, hdr->head, icollection_by_key);
		hdr->current = hdr->head;
	}

	stats.sort++;
	pgstat_report_wait_end();

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

	pgstat_report_wait_start(collection_we_copy);

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

			if (!copyhdr->current)
				copyhdr->current = copyhdr->head;
		}

		MemoryContextSwitchTo(oldcxt);

		pgstat_report_wait_end();

		PG_RETURN_DATUM(EOHPGetRWDatum(&copyhdr->hdr));
	}

	pgstat_report_wait_end();

	PG_RETURN_NULL();
}

/*
 * icollection_value_type
 *		Return the OID of the value type
 */
Datum
icollection_value_type(PG_FUNCTION_ARGS)
{
	ICollectionHeader *hdr;
	Datum		result;

	hdr = fetch_icollection(fcinfo, 0);
	result = collection_value_type_common((CollectionHeaderCommon *) hdr);

	if (result == (Datum) 0)
		PG_RETURN_NULL();

	PG_RETURN_DATUM(result);
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

/* SRF callbacks for icollection */
static Datum
icol_srf_get_key(void *cur)
{
	return Int64GetDatum(((icollection *) cur)->key);
}

static Datum
icol_srf_get_value(void *cur)
{
	return ((icollection *) cur)->value;
}

static bool
icol_srf_get_isnull(void *cur)
{
	return ((icollection *) cur)->isnull;
}

static void *
icol_srf_get_next(void *cur)
{
	return ((icollection *) cur)->hh.next;
}

static CollectionSRFContext icol_srf_tmpl =
{
	.get_key = icol_srf_get_key,
		.get_value = icol_srf_get_value,
		.get_isnull = icol_srf_get_isnull,
		.get_next = icol_srf_get_next,
};

/*
 * icollection_keys_to_table
 *		Return all keys as a table
 */
Datum
icollection_keys_to_table(PG_FUNCTION_ARGS)
{
	ICollectionHeader *hdr;
	CollectionSRFContext tmpl;

	if (SRF_IS_FIRSTCALL())
	{
		hdr = fetch_icollection(fcinfo, 0);
		tmpl = icol_srf_tmpl;
		tmpl.eoh = &hdr->hdr;
		return collection_srf_keys_to_table(fcinfo, hdr->head, &tmpl);
	}

	return collection_srf_keys_to_table(fcinfo, NULL, NULL);
}

/*
 * icollection_values_to_table
 *		Return all values as a table
 */
Datum
icollection_values_to_table(PG_FUNCTION_ARGS)
{
	ICollectionHeader *hdr;
	CollectionSRFContext tmpl;

	if (SRF_IS_FIRSTCALL())
	{
		hdr = fetch_icollection(fcinfo, 0);
		tmpl = icol_srf_tmpl;
		tmpl.eoh = &hdr->hdr;
		tmpl.typelen = hdr->value_type_len;
		tmpl.typebyval = hdr->value_byval;
		return collection_srf_values_to_table(fcinfo, hdr->head,
											  hdr->value_type, &tmpl);
	}

	return collection_srf_values_to_table(fcinfo, NULL, InvalidOid, NULL);
}

/*
 * icollection_to_table
 *		Return all key-value pairs as a table
 */
Datum
icollection_to_table(PG_FUNCTION_ARGS)
{
	ICollectionHeader *hdr;
	CollectionSRFContext tmpl;

	if (SRF_IS_FIRSTCALL())
	{
		hdr = fetch_icollection(fcinfo, 0);
		tmpl = icol_srf_tmpl;
		tmpl.eoh = &hdr->hdr;
		tmpl.typelen = hdr->value_type_len;
		tmpl.typebyval = hdr->value_byval;
		return collection_srf_to_table(fcinfo, hdr->head,
									   hdr->value_type, &tmpl);
	}

	return collection_srf_to_table(fcinfo, NULL, InvalidOid, NULL);
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
