# Usage Guide

## Finding an Item

The `find` function returns the value for a given key. It comes in two variants: one returns `text`, the other uses `anyelement` to return a typed value. If the key doesn't exist, a `no_data_found` error is raised.

```sql
DO $$
DECLARE
  c1  collection('date');
BEGIN
  c1 := add(c1, 'k1', '1999-12-31'::date);

  RAISE NOTICE 'Value: %', find(c1, 'k1', null::date);
END $$;
```

Use `exist()` to check before accessing if you're unsure whether a key is present:

```sql
IF exist(c1, 'k1') THEN
  RAISE NOTICE 'Found: %', find(c1, 'k1');
END IF;
```

## Using Subscripts

Both types support subscript syntax, making them work like associative arrays.

### collection (text keys)

```sql
DO $$
DECLARE
  capitals  collection;
BEGIN
  capitals['USA'] := 'Washington, D.C.';
  RAISE NOTICE 'Capital of USA: %', capitals['USA'];
END $$;
```

### icollection (integer keys)

```sql
DO $$
DECLARE
  sparse  icollection('text');
BEGIN
  sparse[1] := 'first';
  sparse[100] := 'hundredth';
  RAISE NOTICE 'Value at 100: %', sparse[100];
END $$;
```

### NULL subscript

A `null` subscript fetches the value at the current iterator position:

```sql
DO $$
DECLARE
  c  collection;
BEGIN
  c['USA'] := 'Washington, D.C.';
  c := first(c);
  RAISE NOTICE 'Current value: %', c[null];
END $$;
```

## Setting the Element Type

The default element type is `text`. You can set it two ways:

1. **Type modifier** — declare it explicitly: `collection('date')`, `icollection('int4')`
2. **First element** — if no type modifier, the type of the first `add()` call sets the type

When using subscripts without a type modifier, values are always stored as `text`. To ensure consistent behavior, always declare a type modifier for non-text values:

```sql
-- With type modifier: subscripts and add() agree
DECLARE c collection('bigint');
c['k'] := 42::bigint;          -- stored as bigint
c := add(c, 'k', 42::bigint);  -- stored as bigint
```

## Iterating Over a Collection

### Iterator Functions

When a collection is created, the iterator points at the first element added. Use `first()`, `last()`, `next()`, `prev()` to move the iterator, and `isnull()` to detect the end.

```sql
DO $$
DECLARE
  capitals  collection;
BEGIN
  capitals['USA']            := 'Washington, D.C.';
  capitals['United Kingdom'] := 'London';
  capitals['Japan']          := 'Tokyo';

  capitals := first(capitals);
  WHILE NOT isnull(capitals) LOOP
    RAISE NOTICE '% => %', key(capitals), value(capitals);
    capitals := next(capitals);
  END LOOP;
END $$;
```

### Key Navigation Functions

For Oracle-style iteration without moving the iterator, use `first_key()`, `last_key()`, `next_key()`, `prev_key()`:

```sql
DO $$
DECLARE
  capitals  collection;
  k         text;
BEGIN
  capitals['USA']            := 'Washington, D.C.';
  capitals['United Kingdom'] := 'London';
  capitals['Japan']          := 'Tokyo';

  k := first_key(capitals);
  WHILE k IS NOT NULL LOOP
    RAISE NOTICE '% => %', k, find(capitals, k);
    k := next_key(capitals, k);
  END LOOP;
END $$;
```

### Sorting

Collections store entries in insertion order. `sort()` reorders by key and positions the iterator at the first sorted element:

```sql
DO $$
DECLARE
  capitals  collection;
BEGIN
  capitals['USA']            := 'Washington, D.C.';
  capitals['United Kingdom'] := 'London';
  capitals['Japan']          := 'Tokyo';

  capitals := sort(capitals);
  -- Iterator now at 'Japan' (alphabetical first)
  RAISE NOTICE 'First sorted key: %', key(capitals);
END $$;
```

For `icollection`, `sort()` orders keys numerically.

### Collations

`collection` is a collatable type. Sort order depends on the collation, which defaults to the database collation:

```sql
DECLARE
  capitals  collection COLLATE "en_US";
```

## Set-Returning Functions

Instead of iterating, you can return the entire collection as a result set:

```sql
DO $$
DECLARE
  capitals  collection;
  r         record;
BEGIN
  capitals['USA']            := 'Washington, D.C.';
  capitals['United Kingdom'] := 'London';
  capitals['Japan']          := 'Tokyo';

  -- Keys only
  FOR r IN SELECT * FROM keys_to_table(capitals) AS k LOOP
    RAISE NOTICE 'Key: %', r.k;
  END LOOP;

  -- Keys and values
  FOR r IN SELECT * FROM to_table(capitals) LOOP
    RAISE NOTICE '% => %', r.key, r.value;
  END LOOP;
END $$;
```

## Bulk Loading from a Query

Load query results into a collection for repeated lookups. Using a `FOR` loop with an inline query creates an implicit cursor with prefetching:

```sql
DO $$
DECLARE
  r    pg_tablespace%ROWTYPE;
  c    collection('pg_tablespace');
BEGIN
  FOR r IN SELECT * FROM pg_tablespace LOOP
    c[r.spcname] := r;
  END LOOP;

  RAISE NOTICE 'Owner of pg_default: %', c['pg_default'].spcowner::regrole;
END $$;
```

## Bulk DML with Set-Returning Functions

Use `to_table()` in DML statements to avoid per-row context switching:

```sql
DO $$
DECLARE
  capitals  collection;
BEGIN
  capitals['USA']   := 'Washington, D.C.';
  capitals['Japan'] := 'Tokyo';

  UPDATE countries
     SET capital = col.value
    FROM to_table(capitals) AS col
   WHERE countries.name = col.key;
END $$;
```

## icollection vs PostgreSQL Arrays

`icollection` addresses two issues with PostgreSQL arrays for associative-array use cases:

**Non-contiguous keys without gap-filling** — when a PostgreSQL array has elements at both a low and high index, it fills the gap with NULLs. For example, assigning `a[1]` and `a[1000000]` creates a 1,000,000-element array with NULLs in positions 2–999,999. `icollection` stores only the keys that are explicitly set:

```sql
DO $$
DECLARE
  sparse  icollection('text');
BEGIN
  sparse[1]       := 'first';
  sparse[1000000] := 'millionth';
  RAISE NOTICE 'Count: %', count(sparse);  -- 2, not 1000000
END $$;
```

**NULL vs uninitialized** — `exist()` distinguishes between a key set to NULL and a key that was never set:

```sql
DO $$
DECLARE
  ic  icollection('text');
BEGIN
  ic[1] := 'value';
  ic[2] := NULL;

  RAISE NOTICE 'Key 2 exists: %', exist(ic, 2);  -- true (explicitly NULL)
  RAISE NOTICE 'Key 3 exists: %', exist(ic, 3);  -- false (never set)
END $$;
```

PostgreSQL arrays return NULL for both uninitialized and explicitly-NULL elements, making them indistinguishable.
