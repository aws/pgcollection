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
	EXPECT_EOF,
} JsonCollectionSemanticState;

struct JsonCollectionParseContext;
typedef struct JsonCollectionParseContext JsonCollectionParseContext;

struct JsonCollectionParseContext
{
	void	   *private_data;
};

typedef struct
{
	JsonLexContext *lex;
	JsonCollectionParseContext *context;
	JsonCollectionSemanticState state;

	char	   *typname;
	List	   *keys;
	List	   *values;
} JsonCollectionParseState;

static JsonParseErrorType json_collection_object_start(void *state);
static JsonParseErrorType json_collection_object_end(void *state);
static JsonParseErrorType json_collection_array_start(void *state);
static JsonParseErrorType json_collection_object_field_start(void *state, 
															 char *fname, 
															 bool isnull);
static JsonParseErrorType json_collection_scalar(void *state, 
												 char *token, 
												 JsonTokenType tokentype);

CollectionHeader *
parse_collection(char *json)
{
	CollectionHeader   *colhdr;
	ListCell   *lc1;
	ListCell   *lc2;
	Oid			typInput;
	Oid			typIOParam;
	int			i = 0;

	JsonParseErrorType json_error;
	JsonSemAction sem;
	JsonCollectionParseState parse;
	JsonCollectionParseContext context;

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
	parse.typname = NULL;

	/* Set up semantic actions. */
	sem.semstate = &parse;
	
#if (PG_VERSION_NUM >= 160000)
	sem.object_start = json_collection_object_start;
	sem.object_end = json_collection_object_end;
	sem.array_start = json_collection_array_start;
	sem.object_field_start = json_collection_object_field_start;
	sem.scalar = json_collection_scalar;
#else
	/* Quiet the compiler */
	sem.object_start = (void *) json_collection_object_start;
	sem.object_end = (void *) json_collection_object_end;
	sem.array_start = (void *) json_collection_array_start;
	sem.object_field_start = (void *) json_collection_object_field_start;
	sem.scalar = (void *) json_collection_scalar;
#endif
	sem.array_end = NULL; 
	sem.object_field_end = NULL;
	sem.array_element_start = NULL;
	sem.array_element_end = NULL;

	json_error = pg_parse_json(parse.lex, &sem);
	if (json_error != JSON_SUCCESS)
		elog(ERROR, "Invalid format");

	colhdr = construct_empty_collection(CurrentMemoryContext);


	if (parse.typname)
	{
		Oid		typid;
		typid = DatumGetObjectId(DirectFunctionCall1(regtypein, CStringGetDatum(parse.typname)));
		colhdr->value_type = typid;
		colhdr->value_type_len = get_typlen(typid);
	} else {
		colhdr->value_type = TEXTOID;
		colhdr->value_type_len = -1;
	}

	getTypeInputInfo(colhdr->value_type, &typInput, &typIOParam);

	forboth(lc1, parse.keys, lc2, parse.values)
	{
		collection *item;
		char	   *key = lfirst(lc1);
		char	   *vstr = lfirst(lc2);
		Datum		value;

		item = (collection *)palloc(sizeof(collection));

		item->key = key;

		value = OidFunctionCall1(typInput, CStringGetDatum(vstr));
		item->value = datumCopy(value, true, colhdr->value_type_len);

		HASH_ADD_PTR(colhdr->current, key, item);

		if (i == 0)
			colhdr->head = colhdr->current;

		i++;
	}

	return colhdr;
}

static JsonParseErrorType
json_collection_object_start(void *state)
{
	JsonCollectionParseState *parse = state;

	switch (parse->state)
	{
		case EXPECT_TOPLEVEL_START:
			parse->state = EXPECT_TOPLEVEL_FIELD;
			break;

		case EXPECT_ENTRIES:
			break;
			
		default:
			elog(ERROR, "unexpected object start");
			break;
	}

	return JSON_SUCCESS;
}

static JsonParseErrorType
json_collection_object_end(void *state)
{
	JsonCollectionParseState *parse = state;

	switch (parse->state)
	{
		case EXPECT_TOPLEVEL_END:
			parse->state = EXPECT_EOF;
			break;

		case EXPECT_ENTRIES:
			parse->state = EXPECT_TOPLEVEL_END;
			break;

		default:
			elog(ERROR, "unexpected object end");
			break;
	}

	return JSON_SUCCESS;
}

static JsonParseErrorType
json_collection_array_start(void *state)
{
	/* Arrays should not exist in a collection json doc */
	elog(ERROR, "Invalid collection format");
	
	return JSON_INVALID_TOKEN;
}

static JsonParseErrorType
json_collection_object_field_start(void *state, char *fname, bool isnull)
{
	JsonCollectionParseState *parse = state;
	char	*key;

	switch (parse->state)
	{
		case EXPECT_TOPLEVEL_FIELD:
			if (strcmp(fname, "value_type") == 0)
			{
				parse->state = EXPECT_VALUE_TYPE;
				break;
			}

			if (strcmp(fname, "entries") == 0)
			{
				parse->state = EXPECT_ENTRIES;
				break;
			}

			/* It's not a field we recognize. */
			elog(ERROR, "unrecognized top-level field");
			break;

		case EXPECT_ENTRIES:
			key = palloc0(strlen(fname) + 1);
			strcpy(key, fname);
			parse->keys = lappend(parse->keys, key);
			break;

		default:
			elog(ERROR, "unexpected object field");
			break;
	}

	pfree(fname);

	return JSON_SUCCESS;
}

static JsonParseErrorType
json_collection_scalar(void *state, char *token, JsonTokenType tokentype)
{
	JsonCollectionParseState *parse = state;

	switch (parse->state)
	{
		case EXPECT_VALUE_TYPE:
			parse->typname = token;
			parse->state = EXPECT_TOPLEVEL_FIELD;
			break;

		case EXPECT_ENTRIES:
			parse->values = lappend(parse->values, token);
			break;

		default:
			elog(ERROR, "unexpected scalar");
			break;
	}

	return JSON_SUCCESS;
}
