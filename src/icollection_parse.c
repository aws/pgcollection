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

#include "catalog/pg_type_d.h"
#include "common/jsonapi.h"
#include "nodes/pg_list.h"
#include "mb/pg_wchar.h"
#include "utils/builtins.h"
#include "utils/datum.h"
#include "utils/lsyscache.h"

#include "collection.h"

static JsonParseErrorType json_icollection_object_field_start(void *state,
															  char *fname,
															  bool isnull);
static JsonParseErrorType json_icollection_scalar(void *state,
												  char *token,
												  JsonTokenType tokentype);

ICollectionHeader *
parse_icollection(char *json)
{
	ICollectionHeader *icolhdr;
	MemoryContext oldcxt;
	ListCell   *lc1;
	ListCell   *lc2;
	ListCell   *lc3;
	Oid			typInput;
	Oid			typIOParam;
	int			i = 0;

	JsonParseErrorType json_error;
	JsonSemAction sem;
	CollectionParseState parse;

	icolhdr = construct_empty_icollection(CurrentMemoryContext);

	oldcxt = MemoryContextSwitchTo(icolhdr->hdr.eoh_context);

	collection_parse_init(&parse, &sem, json,
						  json_icollection_object_field_start,
						  json_icollection_scalar);

	json_error = pg_parse_json(parse.lex, &sem);
	if (json_error != JSON_SUCCESS)
		elog(ERROR, "Invalid format");

	if (parse.typname)
	{
		Oid			typid;

		typid = DatumGetObjectId(DirectFunctionCall1(regtypein, CStringGetDatum(parse.typname)));
		icolhdr->value_type = typid;
		icolhdr->value_type_len = get_typlen(typid);
		icolhdr->value_byval = get_typbyval(typid);
	}
	else
	{
		icolhdr->value_type = TEXTOID;
		icolhdr->value_type_len = -1;
		icolhdr->value_byval = false;
	}

	getTypeInputInfo(icolhdr->value_type, &typInput, &typIOParam);

	forthree(lc1, parse.keys, lc2, parse.values, lc3, parse.nulls)
	{
		icollection *item;
		icollection *replaced_item;
		int64		key;
		char	   *vstr = lfirst(lc2);
		bool		isnull = (bool) lfirst_int(lc3);
		Datum		value;

		key = DatumGetInt64(DirectFunctionCall1(int8in, CStringGetDatum(lfirst(lc1))));

		item = (icollection *) palloc(sizeof(icollection));
		item->key = key;
		item->isnull = isnull;

		if (!isnull)
		{
			value = OidFunctionCall1(typInput, CStringGetDatum(vstr));
			item->value = datumCopy(value, icolhdr->value_byval, icolhdr->value_type_len);
		}

		ICOLLECTION_HASH_REPLACE(icolhdr->head, key, item, replaced_item);
		if (replaced_item)
		{
			if (!replaced_item->isnull && replaced_item->value)
				pfree(DatumGetPointer(replaced_item->value));
			pfree(replaced_item);
		}

		if (i == 0)
			icolhdr->current = icolhdr->head;

		i++;
	}

	icolhdr->current = icolhdr->head;

	MemoryContextSwitchTo(oldcxt);

	return icolhdr;
}

/*
 * ICollection-specific: stores keys via pstrdup, no pfree of fname.
 */
static JsonParseErrorType
json_icollection_object_field_start(void *state, char *fname, bool isnull)
{
	CollectionParseState *parse = state;

	switch (parse->state)
	{
		case COLL_PARSE_EXPECT_TOPLEVEL_FIELD:
			if (strcmp(fname, "value_type") == 0)
				parse->state = COLL_PARSE_EXPECT_VALUE_TYPE;
			else if (strcmp(fname, "entries") == 0)
				parse->state = COLL_PARSE_EXPECT_ENTRIES;
			else
				elog(ERROR, "unexpected field: %s", fname);
			break;

		case COLL_PARSE_EXPECT_ENTRIES_OBJECT:
			parse->keys = lappend(parse->keys, pstrdup(fname));
			break;

		default:
			elog(ERROR, "unexpected field start");
			break;
	}

	return JSON_SUCCESS;
}

/*
 * ICollection-specific: uses pstrdup for tokens, handles NULL token type.
 */
static JsonParseErrorType
json_icollection_scalar(void *state, char *token, JsonTokenType tokentype)
{
	CollectionParseState *parse = state;

	switch (parse->state)
	{
		case COLL_PARSE_EXPECT_VALUE_TYPE:
			parse->typname = pstrdup(token);
			parse->state = COLL_PARSE_EXPECT_TOPLEVEL_FIELD;
			break;

		case COLL_PARSE_EXPECT_ENTRIES_OBJECT:
			if (tokentype == JSON_TOKEN_NULL)
			{
				parse->values = lappend(parse->values, NULL);
				parse->nulls = lappend_int(parse->nulls, true);
			}
			else
			{
				parse->values = lappend(parse->values, pstrdup(token));
				parse->nulls = lappend_int(parse->nulls, false);
			}
			break;

		default:
			elog(ERROR, "unexpected scalar");
			break;
	}

	return JSON_SUCCESS;
}
