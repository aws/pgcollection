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
#ifndef __COLLECTION_H__
#define __COLLECTION_H__

#include "fmgr.h"
#include "storage/lwlock.h"
#include "utils/expandeddatum.h"
#include "utils/hsearch.h"

#ifdef HASH_FUNCTION
#undef HASH_FUNCTION
#define HASH_FUNCTION HASH_JEN
#endif

#define HASH_NONFATAL_OOM 1

#include "uthash/uthash.h"

#undef uthash_malloc
#undef uthash_free
#undef uthash_nonfatal_oom
#define uthash_malloc(sz) palloc(sz)
#define uthash_free(ptr,sz) pfree(ptr)
#define uthash_nonfatal_oom(e) do{elog(ERROR, "Unable to allocate memory");}while(0)

#define COLLECTION_MAGIC 8675309		/* ID for debugging crosschecks */

typedef struct collection {
	char		   *key;
	Datum			value;
	UT_hash_handle	hh;
} collection;

typedef struct CollectionHeader
{
	/* Standard header for expanded objects */
	ExpandedObjectHeader hdr;

	/* Magic value identifying an expanded array (for debugging only) */
	int				collection_magic;

	Oid				value_type;	/* value type OID */
	int16			value_type_len;
	bool			value_byval;

	/*
	 * flat_size is the current space requirement for the flat equivalent of
	 * the expanded array, if known; otherwise it's 0.  We store this to make
	 * consecutive calls of get_flat_size cheap.
	 */
	size_t			flat_size;

	collection	   *current;
	collection	   *head;
} CollectionHeader;

typedef struct FlatCollectionType
{
	int32		vl_len_;		/* varlena header (do not touch directly!) */
	int32		num_entries;
	Oid			value_type;
	char		values[];
} FlatCollectionType;

typedef struct StatsCounters
{
	int64		add;
	int64		context_switch;
	int64		delete;
	int64		find;
	int64		sort;
} StatsCounters;

extern StatsCounters stats;

extern CollectionHeader *parse_collection(char *json);
extern CollectionHeader *fetch_collection(FunctionCallInfo fcinfo, int argno);
extern CollectionHeader *construct_empty_collection(MemoryContext parentcontext);
CollectionHeader *DatumGetExpandedCollection(Datum d);

/* "Methods" required for an expanded object */
Size collection_get_flat_size(ExpandedObjectHeader *eohptr);
void collection_flatten_into(ExpandedObjectHeader *eohptr,
							void *result, Size allocated_size);

/* custom wait event values, retrieved from shared memory */
extern uint32 collection_we_flatsize;
extern uint32 collection_we_flatten;
extern uint32 collection_we_expand;
extern uint32 collection_we_cast;
extern uint32 collection_we_add;
extern uint32 collection_we_count;
extern uint32 collection_we_find;
extern uint32 collection_we_delete;
extern uint32 collection_we_sort;
extern uint32 collection_we_copy;
extern uint32 collection_we_value;
extern uint32 collection_we_to_table;
extern uint32 collection_we_fetch;
extern uint32 collection_we_assign;
extern uint32 collection_we_input;
extern uint32 collection_we_output;

#endif							/* __COLLECTION_H__ */
