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

typedef enum
{
	EXPECT_TOPLEVEL_START,
	EXPECT_TOPLEVEL_END,
	EXPECT_TOPLEVEL_FIELD,
	EXPECT_VALUE_TYPE,
	EXPECT_ENTRIES,
	EXPECT_ENTRIES_OBJECT,
	EXPECT_EOF,
}			JsonICollectionSemanticState;

struct JsonICollectionParseContext;
typedef struct JsonICollectionParseContext JsonICollectionParseContext;

struct JsonICollectionParseContext
{
	void	   *private_data;
};

typedef struct
{
	JsonLexContext *lex;
	JsonICollectionParseContext *context;
	JsonICollectionSemanticState state;

	char	   *typname;
	List	   *keys;
	List	   *values;
	List	   *nulls;
}			JsonICollectionParseState;

static JsonParseErrorType json_icollection_object_start(void *state);
static JsonParseErrorType json_icollection_object_end(void *state);
static JsonParseErrorType json_icollection_array_start(void *state);
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
	JsonICollectionParseState parse;
	JsonICollectionParseContext context;

	icolhdr = construct_empty_icollection(CurrentMemoryContext);

	oldcxt = MemoryContextSwitchTo(icolhdr->hdr.eoh_context);

	context.private_data = json;

	parse.context = &context;
	parse.state = EXPECT_TOPLEVEL_START;
#if (PG_VERSION_NUM >= 170000)
	parse.lex = makeJsonLexContextCstringLen(NULL, json, strlen(json), PG_UTF8, true);
#else
	parse.lex = makeJsonLexContextCstringLen(json, strlen(json), PG_UTF8, true);
#endif
	parse.keys = NIL;
	parse.values = NIL;
	parse.nulls = NIL;
	parse.typname = NULL;

	sem.semstate = &parse;

#if (PG_VERSION_NUM >= 160000)
	sem.object_start = json_icollection_object_start;
	sem.object_end = json_icollection_object_end;
	sem.array_start = json_icollection_array_start;
	sem.object_field_start = json_icollection_object_field_start;
	sem.scalar = json_icollection_scalar;
#else
	sem.object_start = (void *) json_icollection_object_start;
	sem.object_end = (void *) json_icollection_object_end;
	sem.array_start = (void *) json_icollection_array_start;
	sem.object_field_start = (void *) json_icollection_object_field_start;
	sem.scalar = (void *) json_icollection_scalar;
#endif
	sem.array_end = NULL;
	sem.object_field_end = NULL;
	sem.array_element_start = NULL;
	sem.array_element_end = NULL;

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

static JsonParseErrorType
json_icollection_object_start(void *state)
{
	JsonICollectionParseState *parse = state;

	switch (parse->state)
	{
		case EXPECT_TOPLEVEL_START:
			parse->state = EXPECT_TOPLEVEL_FIELD;
			break;

		case EXPECT_ENTRIES:
			parse->state = EXPECT_ENTRIES_OBJECT;
			break;

		default:
			elog(ERROR, "unexpected object start");
			break;
	}

	return JSON_SUCCESS;
}

static JsonParseErrorType
json_icollection_object_end(void *state)
{
	JsonICollectionParseState *parse = state;

	switch (parse->state)
	{
		case EXPECT_TOPLEVEL_END:
			parse->state = EXPECT_EOF;
			break;

		case EXPECT_ENTRIES_OBJECT:
			parse->state = EXPECT_TOPLEVEL_END;
			break;

		default:
			elog(ERROR, "unexpected object end");
			break;
	}

	return JSON_SUCCESS;
}

static JsonParseErrorType
json_icollection_array_start(void *state)
{
	elog(ERROR, "Invalid icollection format");
	return JSON_INVALID_TOKEN;
}

static JsonParseErrorType
json_icollection_object_field_start(void *state, char *fname, bool isnull)
{
	JsonICollectionParseState *parse = state;

	switch (parse->state)
	{
		case EXPECT_TOPLEVEL_FIELD:
			if (strcmp(fname, "value_type") == 0)
				parse->state = EXPECT_VALUE_TYPE;
			else if (strcmp(fname, "entries") == 0)
				parse->state = EXPECT_ENTRIES;
			else
				elog(ERROR, "unexpected field: %s", fname);
			break;

		case EXPECT_ENTRIES_OBJECT:
			parse->keys = lappend(parse->keys, pstrdup(fname));
			break;

		default:
			elog(ERROR, "unexpected field start");
			break;
	}

	return JSON_SUCCESS;
}

static JsonParseErrorType
json_icollection_scalar(void *state, char *token, JsonTokenType tokentype)
{
	JsonICollectionParseState *parse = state;

	switch (parse->state)
	{
		case EXPECT_VALUE_TYPE:
			parse->typname = pstrdup(token);
			parse->state = EXPECT_TOPLEVEL_FIELD;
			break;

		case EXPECT_ENTRIES_OBJECT:
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
