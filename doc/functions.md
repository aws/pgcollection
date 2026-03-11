# Function Reference

Both `collection` (text-keyed) and `icollection` (integer-keyed) support the same set of functions. The only difference is the key type: `text` for collection, `bigint` for icollection.

## collection Functions

| Function | Return Type | Description |
|---|---|---|
| `add(collection, text, text)` | `collection` | Adds a text item to a collection |
| `add(collection, text, anyelement)` | `collection` | Adds an anyelement item to a collection |
| `count(collection)` | `int4` | Returns the number of items in a collection |
| `delete(collection, text)` | `collection` | Deletes an item from a collection |
| `exist(collection, text)` | `bool` | Returns true if a given key exists in the collection |
| `find(collection, text)` | `text` | Returns a text item from a collection if it exists |
| `find(collection, text, anyelement)` | `anyelement` | Returns an anyelement item from a collection if it exists |
| `first(collection)` | `collection` | Sets the collection iterator to the first item |
| `last(collection)` | `collection` | Sets the collection iterator to the last item |
| `next(collection)` | `collection` | Sets the collection iterator to the next item |
| `prev(collection)` | `collection` | Sets the collection iterator to the previous item |
| `first_key(collection)` | `text` | Returns the key of the first item |
| `last_key(collection)` | `text` | Returns the key of the last item |
| `next_key(collection, text)` | `text` | Returns the key of the next item for the given key |
| `prev_key(collection, text)` | `text` | Returns the key of the previous item for the given key |
| `copy(collection)` | `collection` | Returns a copy of a collection without a context switch |
| `sort(collection)` | `collection` | Sorts by keys in collation order and points to the first item |
| `isnull(collection)` | `bool` | Returns true if the iterator has passed the end of the collection |
| `key(collection)` | `text` | Returns the key at the current iterator position |
| `value(collection)` | `text` | Returns the value as text at the current iterator position |
| `value(collection, anyelement)` | `anyelement` | Returns the value as anyelement at the current iterator position |
| `keys_to_table(collection)` | `SETOF text` | Returns all keys as a result set |
| `values_to_table(collection)` | `SETOF text` | Returns all values as text in a result set |
| `values_to_table(collection, anyelement)` | `SETOF anyelement` | Returns all values as anyelement in a result set |
| `to_table(collection)` | `TABLE(text, text)` | Returns all keys and values as text in a result set |
| `to_table(collection, anyelement)` | `TABLE(text, anyelement)` | Returns all keys and values as anyelement in a result set |
| `value_type(collection)` | `regtype` | Returns the data type of the elements within the collection |

## icollection Functions

| Function | Return Type | Description |
|---|---|---|
| `add(icollection, bigint, text)` | `icollection` | Adds a text item to an icollection |
| `add(icollection, bigint, anyelement)` | `icollection` | Adds an anyelement item to an icollection |
| `count(icollection)` | `int4` | Returns the number of items in an icollection |
| `delete(icollection, bigint)` | `icollection` | Deletes an item from an icollection |
| `exist(icollection, bigint)` | `bool` | Returns true if a given key exists in the icollection |
| `find(icollection, bigint)` | `text` | Returns a text item from an icollection if it exists |
| `find(icollection, bigint, anyelement)` | `anyelement` | Returns an anyelement item from an icollection if it exists |
| `first(icollection)` | `icollection` | Sets the icollection iterator to the first item |
| `last(icollection)` | `icollection` | Sets the icollection iterator to the last item |
| `next(icollection)` | `icollection` | Sets the icollection iterator to the next item |
| `prev(icollection)` | `icollection` | Sets the icollection iterator to the previous item |
| `first_key(icollection)` | `bigint` | Returns the key of the first item |
| `last_key(icollection)` | `bigint` | Returns the key of the last item |
| `next_key(icollection, bigint)` | `bigint` | Returns the key of the next item for the given key |
| `prev_key(icollection, bigint)` | `bigint` | Returns the key of the previous item for the given key |
| `copy(icollection)` | `icollection` | Returns a copy of an icollection without a context switch |
| `sort(icollection)` | `icollection` | Sorts by keys numerically and points to the first item |
| `isnull(icollection)` | `bool` | Returns true if the iterator has passed the end of the icollection |
| `key(icollection)` | `bigint` | Returns the key at the current iterator position |
| `value(icollection)` | `text` | Returns the value as text at the current iterator position |
| `value(icollection, anyelement)` | `anyelement` | Returns the value as anyelement at the current iterator position |
| `keys_to_table(icollection)` | `SETOF bigint` | Returns all keys as a result set |
| `values_to_table(icollection)` | `SETOF text` | Returns all values as text in a result set |
| `values_to_table(icollection, anyelement)` | `SETOF anyelement` | Returns all values as anyelement in a result set |
| `to_table(icollection)` | `TABLE(bigint, text)` | Returns all keys and values as text in a result set |
| `to_table(icollection, anyelement)` | `TABLE(bigint, anyelement)` | Returns all keys and values as anyelement in a result set |
| `value_type(icollection)` | `regtype` | Returns the data type of the elements within the icollection |

## Statistics Functions

| Function / View | Description |
|---|---|
| `collection_stats` (view) | Session-level operation counters for both collection and icollection |
| `collection_stats_reset()` | Resets all statistics counters for the current session |

The `collection_stats` view columns:

| Column | Description |
|---|---|
| `add` | Number of add/assign operations |
| `context_switch` | Number of times a collection switched memory contexts |
| `delete` | Number of delete operations |
| `find` | Number of find/fetch operations |
| `sort` | Number of sort operations |
| `exist` | Number of exist checks |
