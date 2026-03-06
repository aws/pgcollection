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

static JsonParseErrorType json_collection_object_field_start(void *state,
															 char *fname,
															 bool isnull);
static JsonParseErrorType json_collection_scalar(void *state,
												 char *token,
												 JsonTokenType tokentype);

CollectionHeader *
parse_collection(char *json)
{
	CollectionHeader *colhdr;
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

	colhdr = construct_empty_collection(CurrentMemoryContext);

	oldcxt = MemoryContextSwitchTo(colhdr->hdr.eoh_context);

	collection_parse_init(&parse, &sem, json,
						  json_collection_object_field_start,
						  json_collection_scalar);

	json_error = pg_parse_json(parse.lex, &sem);
	if (json_error != JSON_SUCCESS)
		elog(ERROR, "Invalid format");

	if (parse.typname)
	{
		Oid			typid;

		typid = DatumGetObjectId(DirectFunctionCall1(regtypein, CStringGetDatum(parse.typname)));
		colhdr->value_type = typid;
		colhdr->value_type_len = get_typlen(typid);
		colhdr->value_byval = get_typbyval(typid);
	}
	else
	{
		colhdr->value_type = TEXTOID;
		colhdr->value_type_len = -1;
		colhdr->value_byval = false;
	}

	getTypeInputInfo(colhdr->value_type, &typInput, &typIOParam);

	forthree(lc1, parse.keys, lc2, parse.values, lc3, parse.nulls)
	{
		collection *item;
		collection *replaced_item;
		char	   *key = lfirst(lc1);
		char	   *vstr = lfirst(lc2);
		bool		isnull = (bool) lfirst_int(lc3);
		Datum		value;

		item = (collection *) palloc(sizeof(collection));

		item->key = key;

		item->isnull = isnull;

		if (!isnull)
		{
			value = OidFunctionCall1(typInput, CStringGetDatum(vstr));
			item->value = datumCopy(value, colhdr->value_byval, colhdr->value_type_len);
		}

		HASH_REPLACE(hh, colhdr->head, key[0], strlen(key), item, replaced_item);
		if (replaced_item)
		{
			if (replaced_item->key)
				pfree(replaced_item->key);
			if (replaced_item->isnull == false && replaced_item->value)
				pfree(DatumGetPointer(replaced_item->value));
			pfree(replaced_item);
		}

		if (i == 0)
			colhdr->current = colhdr->head;

		i++;
	}

	colhdr->current = colhdr->head;

	MemoryContextSwitchTo(oldcxt);

	return colhdr;
}

/*
 * Collection-specific: stores string keys with palloc0+strcpy, frees fname.
 */
static JsonParseErrorType
json_collection_object_field_start(void *state, char *fname, bool isnull)
{
	CollectionParseState *parse = state;
	char	   *key;

	switch (parse->state)
	{
		case COLL_PARSE_EXPECT_TOPLEVEL_FIELD:
			if (strcmp(fname, "value_type") == 0)
			{
				parse->state = COLL_PARSE_EXPECT_VALUE_TYPE;
				break;
			}

			if (strcmp(fname, "entries") == 0)
			{
				parse->state = COLL_PARSE_EXPECT_ENTRIES;
				break;
			}

			/* It's not a field we recognize. */
			elog(ERROR, "unrecognized top-level field");
			break;

		case COLL_PARSE_EXPECT_ENTRIES_OBJECT:
			key = palloc0(strlen(fname) + 1);
			strcpy(key, fname);
			parse->keys = lappend(parse->keys, key);
			parse->nulls = lappend_int(parse->nulls, (int) isnull);
			break;

		default:
			elog(ERROR, "unexpected object field");
			break;
	}

	pfree(fname);

	return JSON_SUCCESS;
}

/*
 * Collection-specific: appends token directly (no pstrdup), handles
 * "entries" scalar error.
 */
static JsonParseErrorType
json_collection_scalar(void *state, char *token, JsonTokenType tokentype)
{
	CollectionParseState *parse = state;

	switch (parse->state)
	{
		case COLL_PARSE_EXPECT_VALUE_TYPE:
			parse->typname = token;
			parse->state = COLL_PARSE_EXPECT_TOPLEVEL_FIELD;
			break;

		case COLL_PARSE_EXPECT_ENTRIES:
			elog(ERROR, "\"entries\" field must be a JSON object, not a scalar value");
			break;

		case COLL_PARSE_EXPECT_ENTRIES_OBJECT:
			parse->values = lappend(parse->values, token);
			break;

		default:
			elog(ERROR, "unexpected scalar");
			break;
	}

	return JSON_SUCCESS;
}
