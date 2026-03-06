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
#include "parser/parse_coerce.h"
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

	PG_RETURN_INT32(collection_typmodin_common(ta, "ICOLLECTION"));
}

Datum
icollection_typmodout(PG_FUNCTION_ARGS)
{
	Oid			typmod = PG_GETARG_OID(0);

	PG_RETURN_CSTRING(collection_typmodout_common(typmod));
}

Datum
icollection_cast(PG_FUNCTION_ARGS)
{
	ICollectionHeader *icolhdr;
	Oid			typmod = PG_GETARG_INT32(1);

	icolhdr = fetch_icollection(fcinfo, 0);

	collection_cast_common((CollectionHeaderCommon *) icolhdr, typmod, fcinfo);

	PG_RETURN_DATUM(EOHPGetRWDatum(&icolhdr->hdr));
}
