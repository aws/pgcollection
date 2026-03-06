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
#include "collection.h"
#include "utils/datum.h"
#include "utils/expandeddatum.h"
#include "utils/lsyscache.h"
#include "utils/memutils.h"

/* Forward declarations */
static Size icollection_get_flat_size(ExpandedObjectHeader *eohptr);
static void icollection_flatten_into(ExpandedObjectHeader *eohptr,
									 void *result, Size allocated_size);
static Datum expand_icollection(Datum icollectiondatum, MemoryContext parentcontext);

static const ExpandedObjectMethods icollection_methods =
{
	icollection_get_flat_size,
	icollection_flatten_into
};

/*
 * expand_icollection
 *		Expand an icollection datum into a writable expanded object
 *		Preserves iterator position when copying from another expanded object
 *
 * NOTE: This function parallels expand_collection() in collection.c.
 * Any changes to the logic here should be mirrored there for consistency.
 * The two implementations differ only in key type (int64 vs char*) and
 * hash table operations.
 */
static Datum
expand_icollection(Datum icollectiondatum, MemoryContext parentcontext)
{
	/* If the source is an expanded icollection, copy it to make it writable */
	if (VARATT_IS_EXTERNAL_EXPANDED(DatumGetPointer(icollectiondatum)))
	{
		ICollectionHeader *src_hdr = (ICollectionHeader *) DatumGetEOHP(icollectiondatum);
		ICollectionHeader *copyhdr;
		MemoryContext oldcxt;
		icollection *iter;
		icollection *item;

		Assert(src_hdr->collection_magic == COLLECTION_MAGIC);

		/* Create a writable copy */
		copyhdr = construct_empty_icollection(parentcontext);

		if (src_hdr->head)
		{
			oldcxt = MemoryContextSwitchTo(copyhdr->hdr.eoh_context);

			copyhdr->value_type = src_hdr->value_type;
			copyhdr->value_type_len = src_hdr->value_type_len;
			copyhdr->value_byval = src_hdr->value_byval;

			/* Copy items in the same order to preserve iteration */
			for (iter = src_hdr->head; iter != NULL; iter = iter->hh.next)
			{
				icollection *replaced_item;

				item = palloc(sizeof(icollection));
				item->key = iter->key;
				item->isnull = iter->isnull;
				if (!iter->isnull)
					item->value = datumCopy(iter->value, src_hdr->value_byval, src_hdr->value_type_len);

				ICOLLECTION_HASH_REPLACE(copyhdr->head, key, item, replaced_item);
				if (replaced_item)
					pfree(replaced_item);

				/* Set current to match the source's current position exactly */
				if (iter == src_hdr->current)
					copyhdr->current = item;
			}

			/* If source current was NULL, keep it NULL */
			if (src_hdr->current == NULL)
				copyhdr->current = NULL;
			/* If we didn't find a matching current, default to NULL */
			else if (copyhdr->current == NULL && copyhdr->head)
				copyhdr->current = NULL;

			MemoryContextSwitchTo(oldcxt);
		}
		else
		{
			copyhdr->value_type = src_hdr->value_type;
			copyhdr->value_type_len = src_hdr->value_type_len;
			copyhdr->value_byval = src_hdr->value_byval;
		}

		return EOHPGetRWDatum(&copyhdr->hdr);
	}

	/* For flat icollections, expand them normally (iterator starts at NULL) */
	{
		ICollectionHeader *new_hdr;
		char	   *ptr;
		int32		num_entries;
		Oid			value_type;
		int			i;
		MemoryContext oldcxt;
		struct varlena *attr = NULL;

		/* Detoast if needed */
		if (VARATT_IS_EXTENDED(DatumGetPointer(icollectiondatum)))
		{
			attr = PG_DETOAST_DATUM_COPY(icollectiondatum);
			ptr = (char *) attr;
		}
		else
			ptr = (char *) DatumGetPointer(icollectiondatum);

		/* Skip varlena header */
		ptr += sizeof(int32);

		/* Read number of entries */
		memcpy(&num_entries, ptr, sizeof(int32));
		ptr += sizeof(int32);

		/* Read value type */
		memcpy(&value_type, ptr, sizeof(Oid));
		ptr += sizeof(Oid);

		/* Create empty collection */
		new_hdr = construct_empty_icollection(parentcontext);

		oldcxt = MemoryContextSwitchTo(new_hdr->hdr.eoh_context);

		new_hdr->value_type = value_type;
		if (value_type != InvalidOid)
			get_typlenbyval(value_type, &new_hdr->value_type_len, &new_hdr->value_byval);

		/* Read each entry */
		for (i = 0; i < num_entries; i++)
		{
			int64		key;
			size_t		value_len;
			icollection *item;
			icollection *replaced_item;

			/* Read key */
			memcpy(&key, ptr, sizeof(int64));
			ptr += sizeof(int64);

			/* Read value length */
			memcpy(&value_len, ptr, sizeof(size_t));
			ptr += sizeof(size_t);

			/* Allocate item */
			item = (icollection *) palloc(sizeof(icollection));
			item->key = key;

			if (value_len == 0)
				item->isnull = true;
			else
			{
				item->isnull = false;

				if (new_hdr->value_type_len != -1)
				{
					/* Fixed-length type */
					Datum		temp_value;

					memcpy(&temp_value, ptr, value_len);
					item->value = datumCopy(temp_value, new_hdr->value_byval, value_len);
				}
				else
				{
					/* Variable-length type */
					item->value = datumCopy((Datum) ptr, new_hdr->value_byval, value_len);
				}
			}
			ptr += value_len;

			/* Add to hash table */
			ICOLLECTION_HASH_REPLACE(new_hdr->head, key, item, replaced_item);
			if (replaced_item)
				pfree(replaced_item);

			/* Set current to first item like collection does */
			if (i == 0)
			{
				new_hdr->head = item;
				new_hdr->current = item;
			}
		}

		MemoryContextSwitchTo(oldcxt);

		if (attr)
			pfree(attr);

		return EOHPGetRWDatum(&new_hdr->hdr);
	}
}

/*
 * icollection_get_flat_size
 *		Return size needed for flattened icollection
 */
static Size
icollection_get_flat_size(ExpandedObjectHeader *eohptr)
{
	ICollectionHeader *hdr = (ICollectionHeader *) eohptr;
	icollection *cur;
	size_t		sz = 0;

	Assert(hdr->collection_magic == COLLECTION_MAGIC);

	/* Calculate size for each entry */
	for (cur = hdr->head; cur != NULL; cur = cur->hh.next)
	{
		sz += sizeof(int64);	/* key */
		sz += sizeof(size_t);	/* value length */

		if (!cur->isnull)
		{
			if (hdr->value_type_len != -1)
				sz += hdr->value_type_len;
			else
			{
				struct varlena *s = (struct varlena *) DatumGetPointer(cur->value);

				sz += (Size) VARSIZE_ANY(s);
			}
		}
	}

	/* Add header size */
	sz += sizeof(int32) + sizeof(int32) + sizeof(Oid);

	hdr->flat_size = sz;
	return sz;
}

/*
 * icollection_flatten_into
 *		Flatten expanded icollection into flat format
 */
static void
icollection_flatten_into(ExpandedObjectHeader *eohptr,
						 void *result, Size allocated_size)
{
	ICollectionHeader *hdr = (ICollectionHeader *) eohptr;
	char	   *ptr = (char *) result;
	int32		num_entries;
	icollection *cur;

	Assert(hdr->collection_magic == COLLECTION_MAGIC);
	Assert(allocated_size == hdr->flat_size);

	/* Write varlena header */
	SET_VARSIZE(result, allocated_size);
	ptr += sizeof(int32);

	/* Write number of entries */
	num_entries = HASH_COUNT(hdr->head);
	memcpy(ptr, &num_entries, sizeof(int32));
	ptr += sizeof(int32);

	/* Write value type */
	memcpy(ptr, &hdr->value_type, sizeof(Oid));
	ptr += sizeof(Oid);

	/* Write each entry */
	for (cur = hdr->head; cur != NULL; cur = cur->hh.next)
	{
		size_t		value_len;

		/* Write key */
		memcpy(ptr, &cur->key, sizeof(int64));
		ptr += sizeof(int64);

		/* Write value length and value */
		if (cur->isnull)
		{
			value_len = 0;
		}
		else
		{
			if (hdr->value_type_len != -1)
				value_len = hdr->value_type_len;
			else
			{
				struct varlena *s = (struct varlena *) DatumGetPointer(cur->value);

				value_len = (size_t) VARSIZE_ANY(s);
			}
		}

		memcpy(ptr, &value_len, sizeof(size_t));
		ptr += sizeof(size_t);

		if (value_len > 0)
		{
			if (hdr->value_type_len != -1)
				memcpy(ptr, &cur->value, value_len);
			else
				memcpy(ptr, DatumGetPointer(cur->value), value_len);
			ptr += value_len;
		}
	}
}

/*
 * construct_empty_icollection
 *		Create an empty expanded icollection
 */
ICollectionHeader *
construct_empty_icollection(MemoryContext parentcontext)
{
	ICollectionHeader *hdr;
	MemoryContext objcxt;

	objcxt = AllocSetContextCreate(parentcontext,
								   "expanded icollection",
								   ALLOCSET_START_SMALL_SIZES);

	hdr = (ICollectionHeader *)
		MemoryContextAlloc(objcxt, sizeof(ICollectionHeader));

	EOH_init_header(&hdr->hdr, &icollection_methods, objcxt);
	hdr->collection_magic = COLLECTION_MAGIC;
	hdr->value_type = InvalidOid;
	hdr->value_byval = false;
	hdr->flat_size = 0;

	hdr->current = NULL;
	hdr->head = NULL;

	return hdr;
}

/*
 * fetch_icollection
 *		Get expanded icollection from argument
 */
ICollectionHeader *
fetch_icollection(FunctionCallInfo fcinfo, int argno)
{
	ICollectionHeader *hdr;

	if (!PG_ARGISNULL(argno))
	{
		Datum		d = PG_GETARG_DATUM(argno);

		/* Expand to writable form, preserving iterator if already expanded */
		d = expand_icollection(d, CurrentMemoryContext);
		hdr = (ICollectionHeader *) DatumGetEOHP(d);
	}
	else
		hdr = construct_empty_icollection(CurrentMemoryContext);

	return hdr;
}

/*
 * DatumGetExpandedICollection
 *		Get expanded icollection from datum, expanding if needed
 */
ICollectionHeader *
DatumGetExpandedICollection(Datum d)
{
	/* If it's a writable expanded icollection already, just return it */
	if (VARATT_IS_EXTERNAL_EXPANDED(DatumGetPointer(d)))
	{
		Assert(((ICollectionHeader *) DatumGetEOHP(d))->collection_magic == COLLECTION_MAGIC);
		d = expand_icollection(d, CurrentMemoryContext);
		return (ICollectionHeader *) DatumGetEOHP(d);
	}

	/* Otherwise expand from flat form */
	d = expand_icollection(d, CurrentMemoryContext);
	return (ICollectionHeader *) DatumGetEOHP(d);
}
