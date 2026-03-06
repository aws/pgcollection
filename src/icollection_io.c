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
#include "parser/parse_type.h"
#include "utils/array.h"
#include "utils/builtins.h"
#include "utils/expandeddatum.h"
#include "utils/lsyscache.h"

#include "collection.h"

PG_FUNCTION_INFO_V1(icollection_in);
PG_FUNCTION_INFO_V1(icollection_out);
PG_FUNCTION_INFO_V1(icollection_typmodin);
PG_FUNCTION_INFO_V1(icollection_typmodout);
PG_FUNCTION_INFO_V1(icollection_cast);

uint32		icollection_we_fetch;
uint32		icollection_we_assign;

/*
 * icollection_in
 *		Input function for icollection type
 */
Datum
icollection_in(PG_FUNCTION_ARGS)
{
	char	   *json = PG_GETARG_CSTRING(0);
	ICollectionHeader *icolhdr;

	icolhdr = parse_icollection(json);

	PG_RETURN_DATUM(EOHPGetRWDatum(&icolhdr->hdr));
}

/*
 * icollection_out
 *		Output function for icollection type
 */
Datum
icollection_out(PG_FUNCTION_ARGS)
{
	ICollectionHeader *hdr;
	icollection *cur;
	int			count;
	StringInfoData buf;

	hdr = fetch_icollection(fcinfo, 0);

	count = HASH_COUNT(hdr->head);
	if (count == 0)
		PG_RETURN_CSTRING("{}");

	initStringInfo(&buf);
	appendStringInfoString(&buf, "{");

	for (cur = hdr->head; cur != NULL; cur = cur->hh.next)
	{
		appendStringInfo(&buf, "%lld: ", (long long) cur->key);

		if (cur->isnull)
			appendStringInfoString(&buf, "null");
		else
		{
			Oid			outfuncoid;
			bool		typisvarlena;
			char	   *value_str;

			getTypeOutputInfo(hdr->value_type, &outfuncoid, &typisvarlena);
			value_str = DatumGetCString(OidFunctionCall1(outfuncoid, cur->value));
			appendStringInfoString(&buf, value_str);
		}

		if (cur->hh.next != NULL)
			appendStringInfoString(&buf, ", ");
	}

	appendStringInfoString(&buf, "}");

	PG_RETURN_CSTRING(buf.data);
}

Datum
icollection_typmodin(PG_FUNCTION_ARGS)
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
		ereport(ERROR,
				(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
				 errmsg("invalid ICOLLECTION type modifier")));

	parseTypeString(DatumGetCString(elem_values[0]), &typoid, &typmod, NULL);

	if (typmod != -1)
	{
		if (typoid != BPCHAROID ||
			(typmod != VARHDRSZ + 1 ||
			 strpbrk(DatumGetCString(elem_values[0]), "()")))
			ereport(ERROR,
					(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
					 errmsg("invalid ICOLLECTION type modifier"),
					 errdetail("the type cannot have a type modifier")));
	}

	PG_RETURN_INT32(typoid);
}

Datum
icollection_typmodout(PG_FUNCTION_ARGS)
{
	Oid			typmod = PG_GETARG_OID(0);
	char	   *res = (char *) palloc(NAMEDATALEN);

	res = DatumGetCString(DirectFunctionCall1(regtypeout, typmod));

	PG_RETURN_CSTRING(res);
}

Datum
icollection_cast(PG_FUNCTION_ARGS)
{
	ICollectionHeader *icolhdr;
	Oid			typmod;

	icolhdr = fetch_icollection(fcinfo, 0);
	typmod = PG_GETARG_OID(1);

	if (icolhdr->value_type == InvalidOid)
	{
		icolhdr->value_type = typmod;
		get_typlenbyval(typmod, &icolhdr->value_type_len, &icolhdr->value_byval);
	}

	PG_RETURN_DATUM(EOHPGetRWDatum(&icolhdr->hdr));
}
