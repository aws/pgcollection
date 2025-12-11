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

#include "catalog/pg_type.h"
#include "common/jsonapi.h"
#include "parser/parse_coerce.h"
#include "parser/parse_type.h"
#include "pgstat.h"
#include "utils/builtins.h"
#include "utils/datum.h"
#include "utils/json.h"
#include "utils/jsonfuncs.h"
#include "utils/lsyscache.h"
#include "utils/memutils.h"
#include "utils/wait_event.h"

#include "collection.h"

PG_FUNCTION_INFO_V1(collection_in);
PG_FUNCTION_INFO_V1(collection_out);
PG_FUNCTION_INFO_V1(collection_typmodin);
PG_FUNCTION_INFO_V1(collection_typmodout);
PG_FUNCTION_INFO_V1(collection_cast);

/* custom wait event values, retrieved from shared memory */
uint32		collection_we_flatsize;
uint32		collection_we_flatten;
uint32		collection_we_expand;
uint32		collection_we_cast;
uint32		collection_we_add;
uint32		collection_we_count;
uint32		collection_we_find;
uint32		collection_we_exist;
uint32		collection_we_delete;
uint32		collection_we_sort;
uint32		collection_we_copy;
uint32		collection_we_value;
uint32		collection_we_to_table;
uint32		collection_we_fetch;
uint32		collection_we_assign;
uint32		collection_we_input;
uint32		collection_we_output;

Datum
collection_in(PG_FUNCTION_ARGS)
{
	char	   *json = PG_GETARG_CSTRING(0);
	CollectionHeader *colhdr;

	pgstat_report_wait_start(collection_we_input);

	colhdr = parse_collection(json);

	pgstat_report_wait_end();

	PG_RETURN_DATUM(EOHPGetRWDatum(&colhdr->hdr));
}

Datum
collection_out(PG_FUNCTION_ARGS)
{
	CollectionHeader *colhdr;
	collection *cur;
	Oid			outfuncoid;
	bool		typisvarlena;
	int			count;
	char	   *key;
	char	   *value;
	char	   *value_type;
	StringInfoData tmp,
				dst;

	pgstat_report_wait_start(collection_we_output);

	colhdr = fetch_collection(fcinfo, 0);

	count = HASH_COUNT(colhdr->head);
	if (count == 0)
		PG_RETURN_CSTRING("{}");

	getTypeOutputInfo(colhdr->value_type, &outfuncoid, &typisvarlena);
	value_type = format_type_extended(colhdr->value_type, -1, FORMAT_TYPE_FORCE_QUALIFY);

	initStringInfo(&tmp);
	initStringInfo(&dst);

	appendStringInfoString(&dst, "{\"value_type\": ");

	resetStringInfo(&tmp);
	appendBinaryStringInfo(&tmp, value_type, strlen(value_type));
	escape_json(&dst, tmp.data);

	appendStringInfoString(&dst, ", \"entries\": {");

	for (cur = colhdr->head; cur != NULL; cur = cur->hh.next)
	{
		key = cur->key;

		resetStringInfo(&tmp);
		appendBinaryStringInfo(&tmp, key, strlen(key));
		escape_json(&dst, tmp.data);
		appendStringInfoString(&dst, ": ");

		if (cur->isnull)
			appendStringInfoString(&dst, "null");
		else
		{
			value = DatumGetCString(OidFunctionCall1(outfuncoid, cur->value));

			resetStringInfo(&tmp);
			appendBinaryStringInfo(&tmp, value, strlen(value));
			escape_json(&dst, tmp.data);
		}

		if (cur->hh.next != NULL)
			appendStringInfoString(&dst, ", ");
	}

	appendStringInfoString(&dst, "}}");

	pgstat_report_wait_end();

	PG_RETURN_CSTRING(dst.data);
}

Datum
collection_typmodin(PG_FUNCTION_ARGS)
{
	ArrayType  *ta = PG_GETARG_ARRAYTYPE_P(0);
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
	{
		ereport(ERROR,
				(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
				 errmsg("invalid COLLECTION type modifier")));
		typoid = 0;				/* keep compiler quiet */
	}

	parseTypeString(DatumGetCString(elem_values[0]), &typoid, &typmod, NULL);

	if (typmod != -1)
	{
		/*
		 * There needs to be special handling for BPCHAR For a CHAR passed in
		 * without a typemod defined, the typmod is still returned as 5
		 * intentionally based the historical comment in varchar.c. There also
		 * needs a check to see if there are parenthesis in the string to
		 * determine if the passed in string is CHAR or CHAR(1).
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
					 errmsg("invalid COLLECTION type modifier"),
					 errdetail("the type cannot have a type modifier")));
	}

	PG_RETURN_INT32(typoid);
}

Datum
collection_typmodout(PG_FUNCTION_ARGS)
{
	Oid			typmod = PG_GETARG_OID(0);
	char	   *res = (char *) palloc(NAMEDATALEN);

	res = DatumGetCString(DirectFunctionCall1(regtypeout, typmod));

	PG_RETURN_CSTRING(res);
}

Datum
collection_cast(PG_FUNCTION_ARGS)
{
	CollectionHeader *colhdr;
	Oid			typmod = PG_GETARG_INT32(1);

	colhdr = fetch_collection(fcinfo, 0);

	pgstat_report_wait_start(collection_we_cast);

	if (typmod > 0 && colhdr->value_type != InvalidOid)
	{
		/*
		 * Check if the cast is into a collection or if it can be coerced to
		 * the appropriate type
		 */
		if (get_fn_expr_argtype(fcinfo->flinfo, 0) != typmod &&
			!can_coerce_type(1, &colhdr->value_type, &typmod, COERCION_IMPLICIT))
			ereport(ERROR,
					(errcode(ERRCODE_DATATYPE_MISMATCH),
					 errmsg("Incompatible value data type"),
					 errdetail("Expecting %s, but received %s",
							   format_type_extended(typmod, -1, 0),
							   format_type_extended(colhdr->value_type, -1, 0))));
	}
	else if (typmod > 0 && colhdr->value_type == InvalidOid)
	{
		/* For empty collections with InvalidOid, set the target type */
		colhdr->value_type = (Oid) typmod;
		get_typlenbyval(colhdr->value_type, &colhdr->value_type_len, &colhdr->value_byval);
	}

	pgstat_report_wait_end();

	PG_RETURN_DATUM(EOHPGetRWDatum(&colhdr->hdr));
}
