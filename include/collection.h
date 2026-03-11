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

#include "common/jsonapi.h"
#include "fmgr.h"
#include "nodes/pg_list.h"
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
#define uthash_nonfatal_oom(e) do{elog(ERROR, "unable to allocate memory");}while(0)

#define COLLECTION_MAGIC 8675309	/* ID for debugging crosschecks */

#define VALIDATE_KEY_LENGTH(key) \
	do { \
		if (strlen(key) > INT16_MAX) \
			ereport(ERROR, \
					(errcode(ERRCODE_PROGRAM_LIMIT_EXCEEDED), \
					 errmsg("key too long"), \
					 errdetail("Key length %zu exceeds maximum allowed length %d", \
							   strlen(key), INT16_MAX))); \
	} while (0)

/*
 * Common header layout shared by CollectionHeader and ICollectionHeader.
 * Both headers have identical field layout through current/head, differing
 * only in the pointer types.  This allows shared functions to operate on
 * either type via a cast.
 */
typedef struct CollectionHeaderCommon
{
	ExpandedObjectHeader hdr;
	int			collection_magic;
	Oid			value_type;
	int16		value_type_len;
	bool		value_byval;
	size_t		flat_size;
	void	   *current;
	void	   *head;
}			CollectionHeaderCommon;

/*
 * Minimal entry struct for hash navigation.  Both collection and icollection
 * entries have UT_hash_handle hh at the same offset (after key + value +
 * isnull, all padded to 24 bytes).  This struct lets shared code navigate
 * the hash chain without knowing the key type.
 */
typedef struct CollectionEntryCommon
{
	char		_pad[24];		/* key + value + isnull (same size both types) */
	UT_hash_handle hh;
}			CollectionEntryCommon;

typedef struct collection
{
	char	   *key;
	Datum		value;
	bool		isnull;
	UT_hash_handle hh;
}			collection;

typedef struct CollectionHeader
{
	/* Standard header for expanded objects */
	ExpandedObjectHeader hdr;

	/* Magic value identifying an expanded array (for debugging only) */
	int			collection_magic;

	Oid			value_type;		/* value type OID */
	int16		value_type_len;
	bool		value_byval;

	/*
	 * flat_size is the current space requirement for the flat equivalent of
	 * the expanded array, if known; otherwise it's 0.  We store this to make
	 * consecutive calls of get_flat_size cheap.
	 */
	size_t		flat_size;

	collection *current;
	collection *head;
}			CollectionHeader;

/*
 * Integer-keyed collection entry
 */
typedef struct icollection
{
	int64		key;
	Datum		value;
	bool		isnull;
	UT_hash_handle hh;
}			icollection;

/*
 * Header for expanded icollection objects
 */
typedef struct ICollectionHeader
{
	/* Standard header for expanded objects */
	ExpandedObjectHeader hdr;

	/* Magic value identifying an expanded icollection (for debugging only) */
	int			collection_magic;

	Oid			value_type;		/* value type OID */
	int16		value_type_len;
	bool		value_byval;

	/*
	 * flat_size is the current space requirement for the flat equivalent of
	 * the expanded icollection, if known; otherwise it's 0.  We store this to
	 * make consecutive calls of get_flat_size cheap.
	 */
	size_t		flat_size;

	icollection *current;
	icollection *head;
}			ICollectionHeader;

typedef struct FlatCollectionType
{
	int32		vl_len_;		/* varlena header (do not touch directly!) */
	int32		num_entries;
	Oid			value_type;
	char		values[];
}			FlatCollectionType;

typedef struct StatsCounters
{
	int64		add;
	int64		context_switch;
	int64		delete;
	int64		find;
	int64		exist;
	int64		sort;
}			StatsCounters;

extern StatsCounters stats;

extern CollectionHeader * parse_collection(char *json);
extern CollectionHeader * fetch_collection(FunctionCallInfo fcinfo, int argno);
extern CollectionHeader * construct_empty_collection(MemoryContext parentcontext);
CollectionHeader *DatumGetExpandedCollection(Datum d);

extern ICollectionHeader * parse_icollection(char *json);
extern ICollectionHeader * construct_empty_icollection(MemoryContext parentcontext);
extern ICollectionHeader * fetch_icollection(FunctionCallInfo fcinfo, int argno);
ICollectionHeader *DatumGetExpandedICollection(Datum d);

/* "Methods" required for an expanded object */
Size		collection_get_flat_size(ExpandedObjectHeader *eohptr);
void		collection_flatten_into(ExpandedObjectHeader *eohptr,
									void *result, Size allocated_size);

/*
 * Hash operation macros for integer-keyed collections.
 *
 * uthash's HASH_FIND_INT / HASH_ADD_INT / HASH_REPLACE_INT use sizeof(int),
 * which is 4 bytes.  icollection keys are int64 (8 bytes), so we must use
 * the generic HASH_FIND / HASH_ADD / HASH_REPLACE with sizeof(int64) to
 * hash and compare the full key.
 */
#define ICOLLECTION_HASH_FIND(head, key_int_ptr, item) \
	HASH_FIND(hh, head, key_int_ptr, sizeof(int64), item)

#define ICOLLECTION_HASH_ADD(head, key_field, item) \
	HASH_ADD(hh, head, key_field, sizeof(int64), item)

#define ICOLLECTION_HASH_REPLACE(head, key_field, item, replaced) \
	HASH_REPLACE(hh, head, key_field, sizeof(int64), item, replaced)

#define ICOLLECTION_HASH_DELETE(head, item) \
	HASH_DELETE(hh, head, item)

/* Shared typmod helpers (collection_common.c) */
struct ArrayType;
extern int32 collection_typmodin_common(struct ArrayType *ta, const char *type_name);
extern char *collection_typmodout_common(Oid typmod);

/*
 * Shared JSON parse state machine for collection/icollection parsing.
 * Used by collection_parse.c and icollection_parse.c.
 */
typedef enum
{
	COLL_PARSE_EXPECT_TOPLEVEL_START,
	COLL_PARSE_EXPECT_TOPLEVEL_END,
	COLL_PARSE_EXPECT_TOPLEVEL_FIELD,
	COLL_PARSE_EXPECT_VALUE_TYPE,
	COLL_PARSE_EXPECT_ENTRIES,
	COLL_PARSE_EXPECT_ENTRIES_OBJECT,
	COLL_PARSE_EXPECT_EOF,
}			CollectionParseSemanticState;

typedef struct CollectionParseState
{
	JsonLexContext *lex;
	CollectionParseSemanticState state;

	char	   *typname;
	List	   *keys;
	List	   *values;
	List	   *nulls;
}			CollectionParseState;

/* Shared JSON parse callbacks (collection_common.c) */
extern JsonParseErrorType collection_parse_object_start(void *state);
extern JsonParseErrorType collection_parse_object_end(void *state);
extern JsonParseErrorType collection_parse_array_start(void *state);
extern void collection_parse_init(CollectionParseState * parse,
								  JsonSemAction *sem,
								  char *json,
								  void *object_field_start,
								  void *scalar);

/*
 * Shared SRF iteration context for keys_to_table, values_to_table, to_table.
 * Both collection and icollection use this with type-specific callbacks.
 */
typedef struct CollectionSRFContext
{
	void	   *cur;			/* opaque pointer to current hash entry */
	void	   *eoh;			/* ExpandedObjectHeader, prevents GC */
	int16		typelen;
	bool		typebyval;
	void	   *tupdesc;		/* TupleDesc, for to_table only */

	/* Callbacks */
	Datum		(*get_key) (void *cur);
	Datum		(*get_value) (void *cur);
	bool		(*get_isnull) (void *cur);
	void	   *(*get_next) (void *cur);
}			CollectionSRFContext;

extern Datum collection_srf_keys_to_table(FunctionCallInfo fcinfo,
										  void *head,
										  CollectionSRFContext * tmpl);
extern Datum collection_srf_values_to_table(FunctionCallInfo fcinfo,
											void *head,
											Oid value_type,
											CollectionSRFContext * tmpl);
extern Datum collection_srf_to_table(FunctionCallInfo fcinfo,
									 void *head,
									 Oid value_type,
									 CollectionSRFContext * tmpl);

/* Shared simple userfuncs (collection_common.c) */
extern int32 collection_count_common(CollectionHeaderCommon * hdr);
extern bool collection_isnull_common(CollectionHeaderCommon * hdr);
extern void collection_first_common(CollectionHeaderCommon * hdr);
extern void collection_last_common(CollectionHeaderCommon * hdr);
extern void collection_next_common(CollectionHeaderCommon * hdr);
extern void collection_prev_common(CollectionHeaderCommon * hdr);
extern Datum collection_value_type_common(CollectionHeaderCommon * hdr);
extern void collection_cast_common(CollectionHeaderCommon * hdr,
								   Oid typmod, FunctionCallInfo fcinfo);

/*
 * Shared value coercion: try native coerce, fall back to text conversion,
 * else error.  Returns the coerced Datum.  Caller must have already checked
 * that the value is not null.
 */
extern Datum collection_coerce_value(Datum value, Oid value_type,
									 bool value_byval, int16 value_type_len,
									 Oid rettype);

/*
 * Shared fetch logic: coerce value from a found entry, handling isnull.
 * Sets *resnull and returns the coerced Datum.  entry_value/entry_isnull
 * come from the hash entry.  target_type is the desired output type.
 */
extern Datum collection_fetch_value(CollectionHeaderCommon * hdr,
									Datum entry_value, bool entry_isnull,
									Oid target_type,
									bool *resnull);

/*
 * Shared add/assign logic: validate type compatibility, switch to the
 * expanded object's memory context, copy the value, and return the new
 * item's value+isnull.  On return, caller must do the HASH_REPLACE and
 * free the old entry.  Returns the previous MemoryContext.
 *
 * If the collection has no value_type yet, it is set from argtype.
 * If argtype conflicts, an ERROR is raised.
 */
extern MemoryContext collection_add_setup(CollectionHeaderCommon * hdr,
										  Oid argtype, Datum value,
										  bool argisnull,
										  Datum *out_value, bool *out_isnull);

/*
 * Shared post-replace cleanup: free old entry's value (if pass-by-ref and
 * not null).  key_ptr is the old entry's key pointer (NULL for int-keyed
 * collections).  old_entry is the replaced entry to pfree.
 */
extern void collection_replace_cleanup(void *old_entry, void *key_ptr,
									   bool entry_isnull, Datum entry_value,
									   bool value_byval);

/*
 * Shared subscript workspace used by both collection and icollection.
 * The struct layout is identical for both types.
 */
typedef struct CollectionSubWorkspace
{
	Oid			value_type;
	int16		value_type_len;
	bool		value_byval;
}			CollectionSubWorkspace;

/* Forward declarations to avoid including heavy executor headers */
struct SubscriptingRef;
struct SubscriptingRefState;
struct SubscriptExecSteps;

extern void collection_exec_setup_common(const struct SubscriptingRef *sbsref,
										 struct SubscriptingRefState *sbsrefstate,
										 struct SubscriptExecSteps *methods,
										 Oid type_oid,
										 void *fetch_fn,
										 void *assign_fn);

/* custom wait event values, retrieved from shared memory */
extern uint32 collection_we_flatsize;
extern uint32 collection_we_flatten;
extern uint32 collection_we_expand;
extern uint32 collection_we_cast;
extern uint32 collection_we_add;
extern uint32 collection_we_count;
extern uint32 collection_we_find;
extern uint32 collection_we_exist;
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
