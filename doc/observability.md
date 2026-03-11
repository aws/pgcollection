# Observability

## Wait Events

PostgreSQL 17+ supports custom wait events for extensions. `pgcollection` registers the following events, enabling detailed monitoring via `pg_stat_activity`. On PostgreSQL 14–16, all events appear as `Extension:extension`.

| Wait Event | Description |
|---|---|
| `CollectionCalculatingFlatSize` | Calculating the flat format size before a context switch |
| `CollectionFlatten` | Converting to flat format for a context switch |
| `CollectionExpand` | Expanding flat format to the optimized in-memory format |
| `CollectionCast` | Casting to or from a type-modified collection |
| `CollectionAdd` | Adding an item |
| `CollectionCount` | Counting items |
| `CollectionFind` | Finding an item by key |
| `CollectionDelete` | Deleting an item |
| `CollectionSort` | Sorting by keys |
| `CollectionCopy` | Copying a collection |
| `CollectionValue` | Returning the value at the current iterator position |
| `CollectionToTable` | Converting to a table result set |
| `CollectionFetch` | Fetching an item via subscript |
| `CollectionAssign` | Assigning an item via subscript |
| `CollectionInput` | Parsing JSON input into the expanded format |
| `CollectionOutput` | Serializing to JSON string output |

Both `collection` and `icollection` share the same wait events.

## Usage Statistics

The `collection_stats` view provides per-session operation counters for both `collection` and `icollection`:

| Column | Description |
|---|---|
| `add` | Number of add/assign operations |
| `context_switch` | Number of times a collection switched memory contexts |
| `delete` | Number of delete operations |
| `find` | Number of find/fetch operations |
| `sort` | Number of sort operations |
| `exist` | Number of exist checks |

```sql
SELECT * FROM collection_stats;
```

Use `collection_stats_reset()` to clear the counters:

```sql
SELECT collection_stats_reset();
```
