--
-- Edge case and crash-resistance tests for pgcollection 2.0.0
--
-- Focuses on: iterator stability, NULL handling, boundary conditions,
-- single-element collections, memory safety under rapid mutation,
-- and flatten/unflatten roundtrips.
--

----------------------------------------------------------------------
-- 1. Iterator stability after deleting the CURRENT element
----------------------------------------------------------------------
DO $$
DECLARE
  c collection;
  k text;
BEGIN
  c := add(add(add(NULL::collection, 'a', '1'), 'b', '2'), 'c', '3');
  c := first(c);
  c := next(c);  -- now on 'b'
  ASSERT key(c) = 'b', 'should be on b';
  c := delete(c, 'b');  -- delete current
  -- iterator should advance to next element, not crash
  ASSERT NOT isnull(c), 'iterator should not be null after deleting current';
  RAISE NOTICE 'col delete-current key: %', key(c);
END;
$$;

DO $$
DECLARE
  ic icollection;
  k bigint;
BEGIN
  ic := add(add(add(NULL::icollection, 1, 'a'), 2, 'b'), 3, 'c');
  ic := first(ic);
  ic := next(ic);  -- now on 2
  ASSERT key(ic) = 2, 'should be on 2';
  ic := delete(ic, 2);  -- delete current
  ASSERT NOT isnull(ic), 'ic iterator should not be null after deleting current';
  RAISE NOTICE 'icol delete-current key: %', key(ic);
END;
$$;

----------------------------------------------------------------------
-- 2. Single-element collection: delete only element
----------------------------------------------------------------------
DO $$
DECLARE
  c collection;
BEGIN
  c := add(NULL::collection, 'only', 'val');
  ASSERT count(c) = 1, 'single element count';
  c := delete(c, 'only');
  ASSERT count(c) = 0, 'count after deleting only element';
  ASSERT isnull(c), 'iterator null after deleting only element';
  ASSERT key(c) IS NULL, 'key null after deleting only element';
  ASSERT value(c) IS NULL, 'value null after deleting only element';
END;
$$;

DO $$
DECLARE
  ic icollection;
BEGIN
  ic := add(NULL::icollection, 42, 'val');
  ASSERT count(ic) = 1, 'ic single element count';
  ic := delete(ic, 42);
  ASSERT count(ic) = 0, 'ic count after deleting only element';
  ASSERT isnull(ic), 'ic iterator null after deleting only element';
END;
$$;

----------------------------------------------------------------------
-- 3. Single-element: copy, sort, iterate
----------------------------------------------------------------------
DO $$
DECLARE
  c collection;
  c2 collection;
BEGIN
  c := add(NULL::collection, 'solo', 'data');
  c2 := copy(c);
  ASSERT count(c2) = 1, 'copy of single-element';
  ASSERT find(c2, 'solo') = 'data', 'copy value matches';
  c := sort(c);
  ASSERT count(c) = 1, 'sort single-element';
  c := first(c);
  ASSERT key(c) = 'solo', 'first on single-element';
  c := last(c);
  ASSERT key(c) = 'solo', 'last on single-element';
  c := next(c);
  ASSERT isnull(c), 'next past single-element';
END;
$$;

----------------------------------------------------------------------
-- 4. Delete non-existent key (collection, text-keyed)
----------------------------------------------------------------------
DO $$
DECLARE
  c collection;
BEGIN
  c := add(NULL::collection, 'a', '1');
  c := delete(c, 'nonexistent');
  ASSERT count(c) = 1, 'delete non-existent should not change count';
  ASSERT find(c, 'a') = '1', 'original entry intact';
END;
$$;

----------------------------------------------------------------------
-- 5. next/prev boundary on collection (text-keyed)
----------------------------------------------------------------------
DO $$
DECLARE
  c collection;
BEGIN
  c := add(add(NULL::collection, 'a', '1'), 'b', '2');
  c := sort(c);
  -- prev from first
  c := first(c);
  c := prev(c);
  ASSERT isnull(c), 'prev from first should give null iterator';
  -- next from last
  c := add(NULL::collection, 'a', '1');
  c := add(c, 'b', '2');
  c := last(c);
  c := next(c);
  ASSERT isnull(c), 'next from last should give null iterator';
END;
$$;

----------------------------------------------------------------------
-- 6. next_key/prev_key on collection (text-keyed) boundaries
----------------------------------------------------------------------
DO $$
DECLARE
  c collection;
  ok boolean;
BEGIN
  c := add(add(add(NULL::collection, 'a', '1'), 'b', '2'), 'c', '3');
  c := sort(c);
  ASSERT next_key(c, 'a') = 'b', 'next_key from a';
  ASSERT prev_key(c, 'c') = 'b', 'prev_key from c';
  ASSERT next_key(c, 'c') IS NULL, 'next_key from last is null';
  ASSERT prev_key(c, 'a') IS NULL, 'prev_key from first is null';

  -- next_key on missing key should error
  ok := false;
  BEGIN
    PERFORM next_key(c, 'zzz');
  EXCEPTION WHEN no_data_found THEN
    ok := true;
  END;
  ASSERT ok, 'next_key on missing key should error';

  -- prev_key on missing key should error
  ok := false;
  BEGIN
    PERFORM prev_key(c, 'zzz');
  EXCEPTION WHEN no_data_found THEN
    ok := true;
  END;
  ASSERT ok, 'prev_key on missing key should error';
END;
$$;

----------------------------------------------------------------------
-- 7. SRF on empty collection (text-keyed) — use add/delete to get empty
----------------------------------------------------------------------
DO $$
DECLARE
  c collection;
  n int;
BEGIN
  c := add(NULL::collection, 'tmp', 'val');
  c := delete(c, 'tmp');
  ASSERT count(c) = 0, 'empty via delete';
  SELECT count(*) INTO n FROM keys_to_table(c);
  ASSERT n = 0, 'keys_to_table on empty';
  SELECT count(*) INTO n FROM values_to_table(c);
  ASSERT n = 0, 'values_to_table on empty';
  SELECT count(*) INTO n FROM to_table(c);
  ASSERT n = 0, 'to_table on empty';
END;
$$;

DO $$
DECLARE
  ic icollection;
  n int;
BEGIN
  ic := add(NULL::icollection, 1, 'val');
  ic := delete(ic, 1);
  ASSERT count(ic) = 0, 'ic empty via delete';
  SELECT count(*) INTO n FROM keys_to_table(ic);
  ASSERT n = 0, 'ic keys_to_table on empty';
  SELECT count(*) INTO n FROM values_to_table(ic);
  ASSERT n = 0, 'ic values_to_table on empty';
  SELECT count(*) INTO n FROM to_table(ic);
  ASSERT n = 0, 'ic to_table on empty';
END;
$$;

----------------------------------------------------------------------
-- 8. Subscript assign to create collection from NULL variable
----------------------------------------------------------------------
DO $$
DECLARE
  c collection;
  ic icollection;
BEGIN
  -- c is NULL, subscript assign should create a new collection
  c['hello'] := 'world';
  ASSERT count(c) = 1, 'subscript assign from null collection';
  ASSERT c['hello'] = 'world', 'subscript fetch after null assign';

  -- ic is NULL, subscript assign should create a new icollection
  ic[1] := 'world';
  ASSERT count(ic) = 1, 'subscript assign from null icollection';
  ASSERT ic[1] = 'world', 'subscript fetch after null icollection assign';
END;
$$;

----------------------------------------------------------------------
-- 9. Subscript with NULL key
----------------------------------------------------------------------
DO $$
DECLARE
  c collection;
  ok boolean;
BEGIN
  c := add(NULL::collection, 'a', '1');
  -- NULL subscript in assignment should error
  ok := false;
  BEGIN
    c[NULL] := 'val';
  EXCEPTION WHEN null_value_not_allowed THEN
    ok := true;
  END;
  ASSERT ok, 'null subscript assign should error';
END;
$$;

DO $$
DECLARE
  ic icollection;
  ok boolean;
BEGIN
  ic := add(NULL::icollection, 1, 'a');
  ok := false;
  BEGIN
    ic[NULL] := 'val';
  EXCEPTION WHEN null_value_not_allowed THEN
    ok := true;
  END;
  ASSERT ok, 'ic null subscript assign should error';
END;
$$;

----------------------------------------------------------------------
-- 10. Flatten roundtrip: NULL values survive persist
----------------------------------------------------------------------
CREATE TABLE edge_persist_test(id serial, c collection, ic icollection);

INSERT INTO edge_persist_test(c, ic)
  VALUES (
    add(add(NULL::collection, 'k1', 'v1'), 'k2', NULL::text),
    add(add(NULL::icollection, 1, 'v1'), 2, NULL::text)
  );

DO $$
DECLARE
  r record;
BEGIN
  SELECT c, ic INTO r FROM edge_persist_test WHERE id = 1;
  ASSERT find(r.c, 'k1') = 'v1', 'collection null-value roundtrip k1';
  ASSERT find(r.c, 'k2') IS NULL, 'collection null-value roundtrip k2';
  ASSERT find(r.ic, 1) = 'v1', 'icollection null-value roundtrip 1';
  ASSERT find(r.ic, 2) IS NULL, 'icollection null-value roundtrip 2';
END;
$$;

DROP TABLE edge_persist_test;

----------------------------------------------------------------------
-- 11. Copy independence: mutating copy doesn't affect original
----------------------------------------------------------------------
DO $$
DECLARE
  c collection;
  c2 collection;
BEGIN
  c := add(add(NULL::collection, 'a', '1'), 'b', '2');
  c2 := copy(c);
  c2 := add(c2, 'c', '3');
  c2 := delete(c2, 'a');
  ASSERT count(c) = 2, 'original unchanged after copy mutation';
  ASSERT count(c2) = 2, 'copy has correct count';
  ASSERT exist(c, 'a'), 'original still has a';
  ASSERT NOT exist(c2, 'a'), 'copy does not have a';
  ASSERT exist(c2, 'c'), 'copy has c';
END;
$$;

DO $$
DECLARE
  ic icollection;
  ic2 icollection;
BEGIN
  ic := add(add(NULL::icollection, 1, 'a'), 2, 'b');
  ic2 := copy(ic);
  ic2 := add(ic2, 3, 'c');
  ic2 := delete(ic2, 1);
  ASSERT count(ic) = 2, 'ic original unchanged after copy mutation';
  ASSERT count(ic2) = 2, 'ic copy has correct count';
  ASSERT exist(ic, 1), 'ic original still has 1';
  ASSERT NOT exist(ic2, 1), 'ic copy does not have 1';
END;
$$;

----------------------------------------------------------------------
-- 12. Rapid add/delete cycles (memory safety)
----------------------------------------------------------------------
DO $$
DECLARE
  c collection;
  i int;
BEGIN
  c := NULL::collection;
  FOR i IN 1..500 LOOP
    c := add(c, 'key' || i, 'val' || i);
  END LOOP;
  ASSERT count(c) = 500, 'rapid add count';
  FOR i IN 1..500 LOOP
    c := delete(c, 'key' || i);
  END LOOP;
  ASSERT count(c) = 0, 'rapid delete count';
  -- re-add after full delete
  c := add(c, 'new', 'value');
  ASSERT count(c) = 1, 'add after full rapid delete';
  ASSERT find(c, 'new') = 'value', 'find after full rapid delete';
END;
$$;

DO $$
DECLARE
  ic icollection;
  i int;
BEGIN
  ic := NULL::icollection;
  FOR i IN 1..500 LOOP
    ic := add(ic, i, 'val' || i);
  END LOOP;
  ASSERT count(ic) = 500, 'ic rapid add count';
  FOR i IN 1..500 LOOP
    ic := delete(ic, i);
  END LOOP;
  ASSERT count(ic) = 0, 'ic rapid delete count';
  ic := add(ic, 999, 'comeback');
  ASSERT count(ic) = 1, 'ic add after full rapid delete';
END;
$$;

----------------------------------------------------------------------
-- 13. Overwrite same key repeatedly
----------------------------------------------------------------------
DO $$
DECLARE
  c collection;
  i int;
BEGIN
  c := NULL::collection;
  FOR i IN 1..100 LOOP
    c := add(c, 'same', 'val' || i);
  END LOOP;
  ASSERT count(c) = 1, 'overwrite same key count';
  ASSERT find(c, 'same') = 'val100', 'overwrite same key value';
END;
$$;

DO $$
DECLARE
  ic icollection;
  i int;
BEGIN
  ic := NULL::icollection;
  FOR i IN 1..100 LOOP
    ic := add(ic, 1, 'val' || i);
  END LOOP;
  ASSERT count(ic) = 1, 'ic overwrite same key count';
  ASSERT find(ic, 1) = 'val100', 'ic overwrite same key value';
END;
$$;

----------------------------------------------------------------------
-- 14. Type mismatch errors
----------------------------------------------------------------------
DO $$
DECLARE
  c collection;
  ok boolean;
BEGIN
  c := add(NULL::collection, 'a', 42::int);
  ok := false;
  BEGIN
    c := add(c, 'b', 'text_value'::text);
  EXCEPTION WHEN datatype_mismatch THEN
    ok := true;
  END;
  ASSERT ok, 'type mismatch on add should error';
END;
$$;

DO $$
DECLARE
  ic icollection;
  ok boolean;
BEGIN
  ic := add(NULL::icollection, 1, 42::int);
  ok := false;
  BEGIN
    ic := add(ic, 2, 'text_value'::text);
  EXCEPTION WHEN datatype_mismatch THEN
    ok := true;
  END;
  ASSERT ok, 'ic type mismatch on add should error';
END;
$$;

----------------------------------------------------------------------
-- 15. find/exist on NULL collection arg
----------------------------------------------------------------------
DO $$
DECLARE
  ok boolean;
BEGIN
  -- exist on NULL returns false
  ASSERT NOT exist(NULL::collection, 'a'), 'exist on null collection';

  -- find on NULL should error
  ok := false;
  BEGIN
    PERFORM find(NULL::collection, 'a');
  EXCEPTION WHEN no_data_found THEN
    ok := true;
  END;
  ASSERT ok, 'find on null collection should error';
END;
$$;

DO $$
DECLARE
  ok boolean;
BEGIN
  ASSERT NOT exist(NULL::icollection, 1), 'exist on null icollection';

  ok := false;
  BEGIN
    PERFORM find(NULL::icollection, 1);
  EXCEPTION WHEN no_data_found THEN
    ok := true;
  END;
  ASSERT ok, 'find on null icollection should error';
END;
$$;

----------------------------------------------------------------------
-- 16. Iterate full cycle: first -> next -> ... -> null -> prev/next
----------------------------------------------------------------------
DO $$
DECLARE
  c collection;
  n int := 0;
BEGIN
  c := add(add(add(NULL::collection, 'a', '1'), 'b', '2'), 'c', '3');
  c := first(c);
  WHILE NOT isnull(c) LOOP
    n := n + 1;
    c := next(c);
  END LOOP;
  ASSERT n = 3, 'full iteration count';
  -- now at null, prev should stay null (not crash)
  c := prev(c);
  ASSERT isnull(c), 'prev from null stays null';
  -- next from null should also stay null
  c := next(c);
  ASSERT isnull(c), 'next from null stays null';
END;
$$;

DO $$
DECLARE
  ic icollection;
  n int := 0;
BEGIN
  ic := add(add(add(NULL::icollection, 1, 'a'), 2, 'b'), 3, 'c');
  ic := first(ic);
  WHILE NOT isnull(ic) LOOP
    n := n + 1;
    ic := next(ic);
  END LOOP;
  ASSERT n = 3, 'ic full iteration count';
  ic := prev(ic);
  ASSERT isnull(ic), 'ic prev from null stays null';
END;
$$;

----------------------------------------------------------------------
-- 17. Invalid JSON input
----------------------------------------------------------------------

-- Completely invalid JSON
SELECT 'not json at all'::collection;

-- Array instead of object
SELECT '[1,2,3]'::collection;

-- Missing closing brace
SELECT '{"value_type": "text", "entries": {"a": "b"}'::collection;

-- Entries as array instead of object
SELECT '{"value_type": "text", "entries": [1,2,3]}'::collection;

-- icollection with non-integer key
SELECT '{"value_type": "text", "entries": {"notanumber": "val"}}'::icollection;

----------------------------------------------------------------------
-- 18. Subscript fetch on missing key errors properly
----------------------------------------------------------------------
DO $$
DECLARE
  c collection;
  v text;
  ok boolean;
BEGIN
  c := add(NULL::collection, 'a', '1');
  ok := false;
  BEGIN
    v := c['missing'];
  EXCEPTION WHEN no_data_found THEN
    ok := true;
  END;
  ASSERT ok, 'subscript fetch missing key should error';
END;
$$;

DO $$
DECLARE
  ic icollection;
  v text;
  ok boolean;
BEGIN
  ic := add(NULL::icollection, 1, 'a');
  ok := false;
  BEGIN
    v := ic[999];
  EXCEPTION WHEN no_data_found THEN
    ok := true;
  END;
  ASSERT ok, 'ic subscript fetch missing key should error';
END;
$$;

----------------------------------------------------------------------
-- 19. Sort then iterate preserves order
----------------------------------------------------------------------
DO $$
DECLARE
  c collection;
  keys text[] := '{}';
BEGIN
  c := add(add(add(NULL::collection, 'cherry', '3'), 'apple', '1'), 'banana', '2');
  c := sort(c);
  c := first(c);
  WHILE NOT isnull(c) LOOP
    keys := array_append(keys, key(c));
    c := next(c);
  END LOOP;
  ASSERT keys = ARRAY['apple','banana','cherry'],
    format('sort order wrong: %s', keys::text);
END;
$$;

DO $$
DECLARE
  ic icollection;
  keys bigint[] := '{}';
BEGIN
  ic := add(add(add(NULL::icollection, 30, 'c'), 10, 'a'), 20, 'b');
  ic := sort(ic);
  ic := first(ic);
  WHILE NOT isnull(ic) LOOP
    keys := array_append(keys, key(ic));
    ic := next(ic);
  END LOOP;
  ASSERT keys = ARRAY[10,20,30]::bigint[],
    format('ic sort order wrong: %s', keys::text);
END;
$$;

----------------------------------------------------------------------
-- 20. Add after sort maintains new entry
----------------------------------------------------------------------
DO $$
DECLARE
  c collection;
BEGIN
  c := add(add(NULL::collection, 'b', '2'), 'a', '1');
  c := sort(c);
  c := add(c, 'c', '3');
  ASSERT count(c) = 3, 'count after add-after-sort';
  ASSERT exist(c, 'c'), 'new key exists after add-after-sort';
END;
$$;

----------------------------------------------------------------------
-- 21. value_type consistency
----------------------------------------------------------------------
DO $$
DECLARE
  c collection;
BEGIN
  -- value_type is NULL until first add
  c := add(NULL::collection, 'tmp', 'x');
  c := delete(c, 'tmp');
  -- after delete-all, value_type returns NULL (head is NULL)
  ASSERT value_type(c) IS NULL, 'value_type null after delete-all';
  -- re-adding same type works
  c := add(c, 'a', 'hello');
  ASSERT value_type(c) = 'text'::regtype, 'value_type after re-add';
  -- fresh collection with int
  c := add(NULL::collection, 'a', 42::int);
  ASSERT value_type(c) = 'integer'::regtype, 'value_type after first int add';
END;
$$;

----------------------------------------------------------------------
-- 22. Large collection flatten/unflatten roundtrip
----------------------------------------------------------------------
DO $$
DECLARE
  c collection;
  r record;
  i int;
BEGIN
  c := NULL::collection;
  FOR i IN 1..200 LOOP
    c := add(c, 'key' || lpad(i::text, 4, '0'), 'value' || i);
  END LOOP;

  CREATE TEMP TABLE edge_large_test(c collection);
  INSERT INTO edge_large_test VALUES (c);

  SELECT edge_large_test.c INTO r FROM edge_large_test;
  ASSERT count(r.c) = 200, 'large collection roundtrip count';
  ASSERT find(r.c, 'key0001') = 'value1', 'large collection roundtrip first';
  ASSERT find(r.c, 'key0200') = 'value200', 'large collection roundtrip last';

  DROP TABLE edge_large_test;
END;
$$;

----------------------------------------------------------------------
-- 23. icollection with extreme int64 keys
----------------------------------------------------------------------
DO $$
DECLARE
  ic icollection;
BEGIN
  ic := add(NULL::icollection, 9223372036854775807, 'max');
  ic := add(ic, -9223372036854775808, 'min');
  ic := add(ic, 0, 'zero');
  ASSERT count(ic) = 3, 'extreme keys count';
  ASSERT find(ic, 9223372036854775807) = 'max', 'max key find';
  ASSERT find(ic, -9223372036854775808) = 'min', 'min key find';
  ASSERT find(ic, 0) = 'zero', 'zero key find';
  ASSERT exist(ic, 9223372036854775807), 'max key exist';
  ASSERT exist(ic, -9223372036854775808), 'min key exist';
END;
$$;

-- Keys that would collide with 4-byte hash but not 8-byte
DO $$
DECLARE
  ic icollection;
BEGIN
  ic := add(NULL::icollection, 1, 'one');
  ic := add(ic, 4294967297, 'big');  -- 0x100000001, same lower 32 bits as 1
  ASSERT count(ic) = 2, 'keys with same lower 32 bits are distinct';
  ASSERT find(ic, 1) = 'one', 'find key 1';
  ASSERT find(ic, 4294967297) = 'big', 'find key 4294967297';
END;
$$;

----------------------------------------------------------------------
-- 24. Delete then re-add then iterate
----------------------------------------------------------------------
DO $$
DECLARE
  c collection;
  n int := 0;
BEGIN
  c := add(add(add(NULL::collection, 'a', '1'), 'b', '2'), 'c', '3');
  c := delete(c, 'b');
  c := add(c, 'b', 'new');
  c := first(c);
  WHILE NOT isnull(c) LOOP
    n := n + 1;
    c := next(c);
  END LOOP;
  ASSERT n = 3, 'iterate after delete-readd count';
  ASSERT find(c, 'b') = 'new', 'readded value correct';
END;
$$;

----------------------------------------------------------------------
-- 25. first_key / last_key on collection (text-keyed)
----------------------------------------------------------------------
DO $$
DECLARE
  c collection;
BEGIN
  c := add(add(NULL::collection, 'x', '1'), 'y', '2');
  -- first_key/last_key reflect insertion order (not sorted)
  ASSERT first_key(c) IS NOT NULL, 'first_key not null';
  ASSERT last_key(c) IS NOT NULL, 'last_key not null';

  -- on empty (via delete)
  c := delete(c, 'x');
  c := delete(c, 'y');
  ASSERT first_key(c) IS NULL, 'first_key on empty';
  ASSERT last_key(c) IS NULL, 'last_key on empty';
END;
$$;

----------------------------------------------------------------------
-- 26. icollection large flatten/unflatten roundtrip
----------------------------------------------------------------------
DO $$
DECLARE
  ic icollection;
  r record;
  i int;
BEGIN
  ic := NULL::icollection;
  FOR i IN 1..200 LOOP
    ic := add(ic, i, 'value' || i);
  END LOOP;

  CREATE TEMP TABLE edge_large_ic_test(ic icollection);
  INSERT INTO edge_large_ic_test VALUES (ic);

  SELECT edge_large_ic_test.ic INTO r FROM edge_large_ic_test;
  ASSERT count(r.ic) = 200, 'large icollection roundtrip count';
  ASSERT find(r.ic, 1) = 'value1', 'large icollection roundtrip first';
  ASSERT find(r.ic, 200) = 'value200', 'large icollection roundtrip last';

  DROP TABLE edge_large_ic_test;
END;
$$;

----------------------------------------------------------------------
-- 27. Negative key operations on icollection
----------------------------------------------------------------------
DO $$
DECLARE
  ic icollection;
BEGIN
  ic := add(NULL::icollection, -1, 'neg1');
  ic := add(ic, -100, 'neg100');
  ic := add(ic, -999999999999, 'bigneg');
  ASSERT count(ic) = 3, 'negative keys count';
  ASSERT find(ic, -1) = 'neg1', 'find -1';
  ASSERT find(ic, -100) = 'neg100', 'find -100';
  ASSERT exist(ic, -999999999999), 'exist big negative';
  ic := delete(ic, -100);
  ASSERT count(ic) = 2, 'count after delete negative key';
  ASSERT NOT exist(ic, -100), 'deleted negative key gone';
END;
$$;
