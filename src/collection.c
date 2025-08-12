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
#include "pgstat.h"
#include "utils/builtins.h"
#include "utils/datum.h"
#include "utils/lsyscache.h"
#include "utils/memutils.h"
#include "storage/ipc.h"
#include "utils/typcache.h"
#include "utils/wait_event.h"

#include "collection.h"
#include "collection_config.h"

#ifdef PG_MODULE_MAGIC_EXT
PG_MODULE_MAGIC_EXT(.name = EXT_NAME,.version = EXT_VERSION);
#else
PG_MODULE_MAGIC;
#endif

static const ExpandedObjectMethods collection_expand_methods =
{
	collection_get_flat_size,
	collection_flatten_into
};

void		_PG_init(void);

void
_PG_init(void)
{
	/* first time, allocate or get the custom wait event */
#if (PG_VERSION_NUM >= 170000)
	collection_we_flatsize = WaitEventExtensionNew("CollectionCalculatingFlatSize");
	collection_we_flatten = WaitEventExtensionNew("CollectionFlatten");
	collection_we_expand = WaitEventExtensionNew("CollectionExpand");
	collection_we_cast = WaitEventExtensionNew("CollectionCast");
	collection_we_add = WaitEventExtensionNew("CollectionAdd");
	collection_we_count = WaitEventExtensionNew("CollectionCount");
	collection_we_find = WaitEventExtensionNew("CollectionFind");
	collection_we_delete = WaitEventExtensionNew("CollectionDelete");
	collection_we_sort = WaitEventExtensionNew("CollectionSort");
	collection_we_copy = WaitEventExtensionNew("CollectionCopy");
	collection_we_value = WaitEventExtensionNew("CollectionValue");
	collection_we_to_table = WaitEventExtensionNew("CollectionToTable");
	collection_we_fetch = WaitEventExtensionNew("CollectionFetch");
	collection_we_assign = WaitEventExtensionNew("CollectionAssign");
	collection_we_input = WaitEventExtensionNew("CollectionInput");
	collection_we_output = WaitEventExtensionNew("CollectionOutput");
#else
	collection_we_flatsize = PG_WAIT_EXTENSION;
	collection_we_flatten = PG_WAIT_EXTENSION;
	collection_we_expand = PG_WAIT_EXTENSION;
	collection_we_add = PG_WAIT_EXTENSION;
	collection_we_count = PG_WAIT_EXTENSION;
	collection_we_find = PG_WAIT_EXTENSION;
	collection_we_delete = PG_WAIT_EXTENSION;
	collection_we_copy = PG_WAIT_EXTENSION;
	collection_we_value = PG_WAIT_EXTENSION;
	collection_we_to_table = PG_WAIT_EXTENSION;
	collection_we_fetch = PG_WAIT_EXTENSION;
	collection_we_assign = PG_WAIT_EXTENSION;
	collection_we_input = PG_WAIT_EXTENSION;
	collection_we_output = PG_WAIT_EXTENSION;
#endif
}

Size
collection_get_flat_size(ExpandedObjectHeader *eohptr)
{
	CollectionHeader *colhdr = (CollectionHeader *) eohptr;
	collection *cur;
	size_t		sz = 0;

	Assert(colhdr->collection_magic == COLLECTION_MAGIC);

	pgstat_report_wait_start(collection_we_flatsize);

	for (cur = colhdr->head; cur != NULL; cur = cur->hh.next)
	{
		sz += strlen(cur->key);

		if (colhdr->value_type_len != -1)
			sz += colhdr->value_type_len;
		else
		{
			struct varlena *s = (struct varlena *) DatumGetPointer(cur->value);

			sz += (Size) VARSIZE_ANY(s);
		}
		sz += sizeof(int16);
		sz += sizeof(size_t);
	}

	sz += sizeof(FlatCollectionType);
	colhdr->flat_size = sz;

	pgstat_report_wait_end();

	return sz;
}

void
collection_flatten_into(ExpandedObjectHeader *eohptr,
						void *result, Size allocated_size)
{
	CollectionHeader *colhdr = (CollectionHeader *) eohptr;
	FlatCollectionType *cresult = (FlatCollectionType *) result;
	collection *cur;
	int			location = 0;

	Assert(allocated_size == colhdr->flat_size);

	pgstat_report_wait_start(collection_we_flatten);

	memset(cresult, 0, allocated_size);

	SET_VARSIZE(cresult, allocated_size);
	cresult->num_entries = HASH_COUNT(colhdr->head);
	cresult->value_type = colhdr->value_type;

	for (cur = colhdr->head; cur != NULL; cur = cur->hh.next)
	{
		int16		key_len;
		size_t		value_len;
		bool		is_varlena;

		key_len = strlen(cur->key);

		if (colhdr->value_type_len != -1)
		{
			value_len = colhdr->value_type_len;
			is_varlena = false;
		}
		else
		{
			struct varlena *s = (struct varlena *) DatumGetPointer(cur->value);

			value_len = (size_t) VARSIZE_ANY(s);
			is_varlena = true;
		}

		memcpy(cresult->values + location, (char *) &key_len, sizeof(key_len));
		location += sizeof(key_len);

		memcpy(cresult->values + location, (char *) &value_len, sizeof(value_len));
		location += sizeof(value_len);

		memcpy(cresult->values + location, cur->key, key_len);
		location += key_len;

		if (is_varlena)
			memcpy((char *) cresult->values + location, (char *) cur->value, value_len);
		else
			memcpy((char *) cresult->values + location, (char *) &cur->value, value_len);

		location += value_len;
	}
	stats.context_switch++;
	pgstat_report_wait_end();
}

CollectionHeader *
fetch_collection(FunctionCallInfo fcinfo, int argno)
{
	CollectionHeader *colhdr;

	if (!PG_ARGISNULL(argno))
		colhdr = DatumGetExpandedCollection(PG_GETARG_DATUM(argno));
	else
		colhdr = construct_empty_collection(CurrentMemoryContext);

	return colhdr;
}

CollectionHeader *
construct_empty_collection(MemoryContext parentcontext)
{
	CollectionHeader *colhdr;
	MemoryContext objcxt;

	objcxt = AllocSetContextCreate(parentcontext,
								   "expanded collection",
								   ALLOCSET_START_SMALL_SIZES);

	/* Set up expanded collection */
	colhdr = (CollectionHeader *)
		MemoryContextAlloc(objcxt, sizeof(CollectionHeader));

	EOH_init_header(&colhdr->hdr, &collection_expand_methods, objcxt);
	colhdr->collection_magic = COLLECTION_MAGIC;
	colhdr->value_type = InvalidOid;
	colhdr->value_byval = false;
	colhdr->flat_size = 0;

	colhdr->current = NULL;
	colhdr->head = NULL;

	return colhdr;
}

CollectionHeader *
DatumGetExpandedCollection(Datum d)
{
	CollectionHeader *colhdr;
	FlatCollectionType *fc;
	MemoryContext oldcxt;
	int			location = 0;
	int			i = 0;
	struct varlena *attr;

	if (VARATT_IS_EXTERNAL_EXPANDED(DatumGetPointer(d)))
	{
		colhdr = (CollectionHeader *) DatumGetEOHP(d);

		Assert(colhdr->collection_magic == COLLECTION_MAGIC);

		return colhdr;
	}

	pgstat_report_wait_start(collection_we_expand);

	/* Check whether toasted or not */
	if (VARATT_IS_EXTENDED(DatumGetPointer(d)))
	{
		attr = PG_DETOAST_DATUM_COPY(d);
		fc = (FlatCollectionType *) attr;
	}
	else
		fc = (FlatCollectionType *) (DatumGetPointer(d));

	/* Validate that the type exists */
	lookup_type_cache(fc->value_type, 0);

	colhdr = construct_empty_collection(CurrentMemoryContext);

	oldcxt = MemoryContextSwitchTo(colhdr->hdr.eoh_context);

	colhdr->value_type = fc->value_type;
	get_typlenbyval(fc->value_type, &colhdr->value_type_len, &colhdr->value_byval);


	while (i < fc->num_entries)
	{
		int16		key_len;
		size_t		value_len;
		char	   *key;
		Datum	   *value;
		collection *item;

		memcpy((unsigned char *) &key_len, fc->values + location, sizeof(int16));
		location += sizeof(int16);

		memcpy((unsigned char *) &value_len, fc->values + location, sizeof(size_t));
		location += sizeof(size_t);

		item = (collection *) palloc(sizeof(collection));


		key = (char *) palloc(key_len + 1);
		memcpy(key, fc->values + location, key_len);
		key[key_len] = '\0';
		location += key_len;

		value = (Datum *) palloc(value_len);
		memcpy((unsigned char *) value, fc->values + location, value_len);
		location += value_len;

		item->key = key;

		if (colhdr->value_type_len != -1)
			item->value = datumCopy((Datum) *value, colhdr->value_byval, value_len);
		else
			item->value = datumCopy((Datum) value, colhdr->value_byval, value_len);


		HASH_ADD(hh, colhdr->current, key[0], strlen(key), item);

		if (i == 0)
			colhdr->head = colhdr->current;

		i++;
	}

	MemoryContextSwitchTo(oldcxt);

	pgstat_report_wait_end();

	return colhdr;
}
