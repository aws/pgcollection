--
-- basics.sql
--     Core CRUD operations, JSON I/O, type system, NULL handling,
--     empty collection operations, stats, and type coercion.
--     Covers both collection (text-keyed) and icollection (int-keyed).
--

-- ============================================================
-- PART 1: collection (text-keyed)
-- ============================================================

DO $$
DECLARE
  u   collection;
BEGIN
  RAISE NOTICE 'Test 1';
  u := add(u, 'aaa', 'Hello World'::text);
  RAISE NOTICE 'value: %', value(u);
END
$$;

DO $$
DECLARE
  u   collection;
BEGIN
  RAISE NOTICE 'Test 2';
  u := add(u, 'aaa', '1999-12-31'::date);
  RAISE NOTICE 'value: %', value(u);
END
$$;

DO $$
DECLARE
  u   collection;
BEGIN
  RAISE NOTICE 'Test 3';
  u := add(u, 'aaa', 'Hello World'::text);
  RAISE NOTICE 'value: %', value(u, null::varchar);
END
$$;

DO $$
DECLARE
  u   collection;
BEGIN
  RAISE NOTICE 'Test 4';
  u := add(u, 'aaa', '1999-12-31'::date);
  RAISE NOTICE 'value: %', value(u, null::date);
END
$$;

DO $$
DECLARE
  u   collection;
BEGIN
  RAISE NOTICE 'Test 5';
  u := add(u, 'aaa', 'Hello World'::text);
  u := add(u, 'bbb', 'Hello All'::text);
  RAISE NOTICE 'count: %', count(u);
END
$$;

DO $$
DECLARE
  u   collection;
BEGIN
  RAISE NOTICE 'Test 6';
  u := add(u, 'aaa', 'Hello World'::text);
  u := add(u, 'bbb', 'Hello All'::text);
  RAISE NOTICE 'find: %', find(u, 'aaa', null::text);
END
$$;

DO $$
DECLARE
  u   collection;
BEGIN
  RAISE NOTICE 'Test 7';
  u := add(u, 'aaa', '1999-12-31'::date);
  u := add(u, 'bbb', '2000-01-01'::date);
  RAISE NOTICE 'find: %', find(u, 'aaa', null::text);
END
$$;

DO $$
DECLARE
  u   collection;
  t   text;
BEGIN
  RAISE NOTICE 'Test 8';
  u := add(u, 'aaa', 'Hello World');
  u := add(u, 'bbb', 'Hello All');
  RAISE NOTICE 'count: %', count(u);

  u := add(u, 'ccc', 'Hello Everyone');
  u := add(u, 'ddd', 'First Hello');
  RAISE NOTICE 'count: %', count(u);

  t := key(u);
  RAISE NOTICE 'current key: %', t;
END
$$;

DO $$
DECLARE
  u   collection;
BEGIN
  RAISE NOTICE 'Test 9';
  u := add(u, 'aaa', 'Hello World');
  u := add(u, 'bbb', 'Hello All');
  RAISE NOTICE 'count: %', count(u);

  u := delete(u, 'aaa');
  RAISE NOTICE 'count: %', count(u);
END
$$;

DO $$
DECLARE
  u   collection;
BEGIN
  RAISE NOTICE 'Test 10';
  u := add(u, 'aaa', 'Hello World'::text);
  u := add(u, null, 'Hello All'::text);
  RAISE NOTICE 'count: %', count(u);
END
$$;

DO $$
DECLARE
  u   collection;
BEGIN
  RAISE NOTICE 'Test 11';
  u := add(u, 'aaa', 'Hello World'::text);
  u := add(u, 'bbb', null);
  RAISE NOTICE 'count: %', count(u);
END
$$;

DO $$
DECLARE
  u   collection;
BEGIN
  RAISE NOTICE 'Test 12';
  u := add(u, repeat('a', 4096), 'Hello World'::text);
  RAISE NOTICE 'count: %', count(u);
END
$$;

DO $$
DECLARE
  u   collection;
BEGIN
  RAISE NOTICE 'Test 13';
  u := add(u, 'aaa', 'Hello World'::text);
  u := add(u, 'bbb', 'Hello All'::text);
  RAISE NOTICE 'find: %', find(u, null);
END
$$;

DO $$
DECLARE
  u   collection;
BEGIN
  RAISE NOTICE 'Test 14';
  u := add(u, 'aaa', 'Hello World'::text);
  u := add(u, 'bbb', 'Hello All'::text);
  RAISE NOTICE 'find: %', find(u, repeat('a', 256));
END
$$;

DO $$
DECLARE
  u   collection;
BEGIN
  RAISE NOTICE 'Test 15';
  u := add(u, 'aaa', 'Hello World');
  u := add(u, 'bbb', 'Hello All');

  u := delete(u, null);
  RAISE NOTICE 'count: %', count(u);
END
$$;

DO $$
DECLARE
  u   collection;
BEGIN
  RAISE NOTICE 'Test 15';
  u := add(u, 'aaa', 'Hello World');
  u := add(u, 'bbb', 'Hello All');

  u := delete(u, repeat('a', 256));
  RAISE NOTICE 'count: %', count(u);
END
$$;

DO $$
DECLARE
  u   collection('text');
  v   collection('text');
BEGIN
  RAISE NOTICE 'Test 16';
  u := add(u, 'aaa', 'Hello World');
  u := add(u, 'bbb', 'Hello All');

  v := u;
  v := add(v, 'ccc', 'Hi');
  RAISE NOTICE 'count: u(%), v(%)', count(u), count(v);
END
$$;

DO $$
DECLARE
  u   collection('text');
  v   collection('text');
BEGIN
  RAISE NOTICE 'Test 17';
  u := add(u, 'aaa', 'Hello World');
  u := add(u, 'bbb', 'Hello All');

  v := copy(u);
  v := add(v, 'ccc', 'Hi');
  RAISE NOTICE 'count: u(%), v(%)', count(u), count(v);
END
$$;

DO $$
DECLARE
  u   collection('text');
BEGIN
  RAISE NOTICE 'Test 18';
  u := add(u, 'aaa', 'Hello World');
  u := add(u, 'bbb', 'Hello All');

  RAISE NOTICE 'json: %', to_json(u);
END
$$;

DO $$
DECLARE
  u   collection('int');
BEGIN
  RAISE NOTICE 'Test 19';
  u := add(u, 'aaa', 42);
  u := add(u, 'bbb', 84);

  RAISE NOTICE 'json: %', to_json(u);
END
$$;

CREATE TABLE collection_regress(col1 varchar, col2 varchar, col3 int);

INSERT INTO collection_regress VALUES ('aaa', 'Hello World', 42), ('bbb', 'Hello All', 84);

DO
$$
DECLARE
  r       collection_regress%ROWTYPE;
  c       collection('collection_regress');
  cr      record;
BEGIN
  RAISE NOTICE 'Test 20';
  FOR r IN SELECT col1, col2, col3 
             FROM collection_regress 
            ORDER BY col1
  LOOP
    c[r.col1] = r;
  END LOOP;

  RAISE NOTICE 'output: %', c;
END
$$;

DO
$$
DECLARE
  r       collection_regress%ROWTYPE;
  c       collection('collection_regress');
  cr      record;
BEGIN
  RAISE NOTICE 'Test 21';
  FOR r IN SELECT col1, col2, col3 
             FROM collection_regress 
            ORDER BY col1
  LOOP
    c[r.col1] = r;
  END LOOP;

  RAISE NOTICE 'json: %', c::json;
END
$$;

DROP TABLE collection_regress;

SELECT add(null::collection, 'aaa', 'Hello World');

SELECT add(add(null::collection, 'aaa', 'Hello World'), 'bbb', 'Hello All');

SELECT '{"value_type": "text", "entries": {"aaa": "Hello World", "bbb": "Hello All"}}'::collection;

SELECT add(add(null::collection, 'aaa', '1999-12-31'::date),'bbb', '2000-01-01'::date);

SELECT add(add(null::collection, 'aaa', '1999-12-31'::date),'bbb', null::date);

SELECT '{"value_type": "text", "entries": {"aaa": "Hello World"}'::collection;

SELECT '{"value_type": "text", "entry": {"aaa": "Hello World"}}'::collection;

SELECT '{"entries": {"aaa": "Hello World"}}'::collection;

SELECT '{"entries": {"aaa": "Hello World"}, "value_type": "text"}'::collection;

SELECT '{"value_type": "text", "entries": {"aaa": "Hello World", "bbb": 1}}'::collection;

SELECT collection_stats_reset();

DO $$
DECLARE
  u   collection('text');
  v   collection('text');
BEGIN
  RAISE NOTICE 'Test 22';
  u := add(u, 'aaa', 'Hello World');
  u := add(u, 'bbb', 'Hello All');

  v := u;
  v := add(v, 'ccc', 'Hi');
  RAISE NOTICE 'count: u(%), v(%)', count(u), count(v);
END
$$;

SELECT * FROM collection_stats;

CREATE TABLE collections_test (c1 int, c2 collection);

INSERT INTO collections_test VALUES (1, add(null::collection, 'aaa', 'Hello World')); 
INSERT INTO collections_test VALUES (2, add(null::collection, 'bbb', 'Hello ALL')); 

SELECT * FROM collections_test ORDER BY c1;

DROP TABLE collections_test;

DO
$$
DECLARE
  t  collection;
BEGIN
  RAISE NOTICE 'Test 23';
  t := add(t, '1', 111::bigint);
  t := add(t, '2', 222::bigint);
  RAISE NOTICE 'The current val is %', value(t, null::bigint);
  RAISE NOTICE 'The current value type is %', pg_typeof(value(t, null::bigint));
END
$$;

DO
$$
DECLARE
  t  collection;
BEGIN
  RAISE NOTICE 'Test 24';
  t := add(t, '1', 111::bigint);
  t := add(t, '2', 'hello'::text);
END
$$;

DO
$$
DECLARE
  t  collection;
BEGIN
  RAISE NOTICE 'Test 25';
  t := add(t, '1', 111::bigint);
  RAISE NOTICE 'The type is %', value_type(t);
END
$$;

DO $$
DECLARE
  u   collection;
BEGIN
  RAISE NOTICE 'Test 26';
  u := add(u, 'aaa', 'Hello World'::text);
  u := add(u, 'bbb', 'Hello All'::text);
  u := delete(u, 'aaa');
  u := delete(u, 'bbb');
  u := add(u, 'aaa', 'Hello'::text);
  u := add(u, 'bbb', 'World'::text);
  RAISE NOTICE 'count: %', count(u);
END
$$;

DO $$
DECLARE
  n collection('numeric(8,2)');
BEGIN
  RAISE NOTICE 'Test 27';
  n['aaa'] := 3.14::numeric;
END $$;

DO $$
DECLARE
  u   collection;
BEGIN
  RAISE NOTICE 'Test 28';
  u := add(u, 'aaa', 'Hello World'::text);
  u := add(u, 'bbb', 'Hello All'::text);

  RAISE NOTICE 'bbb exist: %', exist(u, 'bbb');
  RAISE NOTICE 'ccc exist: %', exist(u, 'ccc');
  RAISE NOTICE '<null> exist: %', exist(u, null);
END
$$;

DO $$
DECLARE
  pgc_char collection('CHAR');
BEGIN
  RAISE NOTICE 'Test 29';
  NULL;
END $$;

DO $$
DECLARE
  c collection;
  long_key text;
BEGIN
  RAISE NOTICE 'Test 30';
  long_key := repeat('a', 32768);
  c := add(c, long_key, 'test_value');
END $$;

DO $$
DECLARE
  c collection;
  max_key text;
BEGIN
  RAISE NOTICE 'Test 31';
  max_key := repeat('c', 32767);
  c := add(c, max_key, 'test_value');
  RAISE NOTICE 'Success: Key with length 32767 accepted';
END $$;

DO $$
DECLARE
  c collection;
  long_key text;
BEGIN
  RAISE NOTICE 'Test 32';
  c := add(c, 'valid_key', 'test_value');
  
  long_key := repeat('d', 32768);
  RAISE NOTICE 'find: %', find(c, long_key);
END $$;

DO $$
DECLARE
  c collection;
  long_key text;
BEGIN
  RAISE NOTICE 'Test 33';
  c := add(c, 'valid_key', 'test_value');
  
  long_key := repeat('e', 32768);
  RAISE NOTICE 'exist: %', exist(c, long_key);
END $$;

DO $$
DECLARE
  c collection;
  long_key text;
BEGIN
  RAISE NOTICE 'Test 34';
  c := add(c, 'valid_key', 'test_value');
  
  long_key := repeat('f', 32768);
  c := delete(c, long_key);
END $$;

SELECT delete('{"value_type": "pg_catalog.text", "entries": {"A": "A", "B": "B", "C": "C"}}'::collection, 'A');

-- Test delete with pass-by-value types (int4) - regression test for bug fixed in commit 16eecda
DO $$
DECLARE
    c collection('int4');
BEGIN
    c := add(c, 'a', 1);
    c := add(c, 'b', 2);
    c := add(c, 'c', 3);
    
    c := delete(c, 'a');
    RAISE NOTICE 'After delete a, count: %', count(c);
    
    c := delete(c, 'b');
    RAISE NOTICE 'After delete b, count: %', count(c);
    
    c := delete(c, 'c');
    RAISE NOTICE 'After delete c, count: %', count(c);
END $$;

DO $$
DECLARE
  arr_instance collection('collection');
BEGIN
  RAISE NOTICE 'Test 35';

  -- Initialize: A -> AA := 1
  arr_instance := add(arr_instance, 'A', add(NULL::collection, 'AA', 1::int));

  FOR i IN 1..10 LOOP
    -- Update: A -> AB := 1
    RAISE NOTICE 'Attempt: %', i;
    arr_instance := add(arr_instance, 'A', add(find(arr_instance, 'A', NULL::collection), 'AB', 1::int));
  END LOOP;
END $$;

DO $$
DECLARE
  c1 collection('text');
BEGIN
  RAISE NOTICE 'Test 36';

  -- Uninitialized collection
    RAISE NOTICE 'find(c1): %', find(c1, 'B', NULL::TEXT);
END $$;

DO $$
DECLARE
  c2 collection('text') DEFAULT '{"value_type": "text", "entries": {}}'::collection;
BEGIN
  RAISE NOTICE 'Test 37';

  -- Empty collection
  RAISE NOTICE 'find(c2): %', find(c2, 'B', NULL::TEXT);
END $$;

DO $$
DECLARE
  c3 collection('text');
BEGIN
  RAISE NOTICE 'Test 38';

  -- Non-empty collection
  c3 := add(c3, 'A', 'Hello World');
  RAISE NOTICE 'find(c3): %', find(c3, 'B', NULL::TEXT);
END $$;

DO $$
DECLARE
  c1 collection('text');
  c2 collection('text') DEFAULT '{"value_type": "text", "entries": {}}'::collection;
  c3 collection('text');
BEGIN
  RAISE NOTICE 'Test 39';

  -- Uninitialized collection
  RAISE NOTICE 'count(c1): %', count(c1);

  -- Empty collection
  RAISE NOTICE 'count(c2): %', count(c2);

  -- Non-empty collection
  c3 := add(c3, 'A', 'Hello World');
  RAISE NOTICE 'count(c3): %', count(c3);
END
$$;

DO $$
DECLARE
  val1 collection('int4');
BEGIN
  RAISE NOTICE 'Test 40';

  val1 := add(val1, 'A', 1::int4);
  val1 := add(val1, 'A', 2::int4);
END;
$$;

-- ============================================================
-- Flatten/unflatten roundtrip with typed collections
-- ============================================================
CREATE TABLE collection_persist_test(id serial, c collection);

-- bigint values
INSERT INTO collection_persist_test(c)
  SELECT add(add(null::collection, 'a', 100::bigint), 'b', 200::bigint);

-- date values
INSERT INTO collection_persist_test(c)
  SELECT add(add(null::collection, 'x', '2026-01-01'::date), 'y', '2026-12-31'::date);

-- collection with NULL values
INSERT INTO collection_persist_test(c)
  SELECT add(add(null::collection, 'present', 'hello'), 'missing', null::text);

SELECT id, c FROM collection_persist_test ORDER BY id;
SELECT id, count(c), value_type(c) FROM collection_persist_test ORDER BY id;

-- verify values survive roundtrip
DO $$
DECLARE
  r record;
BEGIN
  SELECT c INTO r FROM collection_persist_test WHERE id = 1;
  ASSERT find(r.c, 'a', 0::bigint) = 100, 'bigint roundtrip failed';
  ASSERT find(r.c, 'b', 0::bigint) = 200, 'bigint roundtrip b failed';

  SELECT c INTO r FROM collection_persist_test WHERE id = 2;
  ASSERT find(r.c, 'x', '2000-01-01'::date) = '2026-01-01'::date, 'date roundtrip failed';

  SELECT c INTO r FROM collection_persist_test WHERE id = 3;
  ASSERT find(r.c, 'present') = 'hello', 'text roundtrip failed';
  ASSERT find(r.c, 'missing') IS NULL, 'null roundtrip failed';
END $$;

-- composite type values
CREATE TABLE collection_comp_type(col1 text, col2 int);
INSERT INTO collection_comp_type VALUES ('hello', 42), ('world', 99);

INSERT INTO collection_persist_test(c)
  SELECT add(add(null::collection, 'r1', r), 'r2', r)
    FROM (SELECT row('hello', 42)::collection_comp_type AS r) sub;

SELECT id, c FROM collection_persist_test WHERE id = 4;

DO $$
DECLARE
  r record;
  v collection_comp_type;
BEGIN
  SELECT c INTO r FROM collection_persist_test WHERE id = 4;
  v := find(r.c, 'r1', null::collection_comp_type);
  ASSERT v.col1 = 'hello' AND v.col2 = 42,
    format('composite roundtrip failed: %s', v);
END $$;

DROP TABLE collection_comp_type;
DROP TABLE collection_persist_test;

-- ============================================================
-- Delete all then reuse
-- ============================================================
DO $$
DECLARE
  c collection;
BEGIN
  c := add(c, 'a', 'one');
  c := add(c, 'b', 'two');
  c := delete(c, 'a');
  c := delete(c, 'b');
  ASSERT count(c) = 0, 'count after delete-all should be 0';
  ASSERT isnull(c), 'iterator should be null after delete-all';

  -- reuse
  c := add(c, 'x', 'new');
  ASSERT count(c) = 1, 'count after re-add should be 1';
  ASSERT find(c, 'x') = 'new', 'find after re-add failed';
END $$;

-- ============================================================
-- Key length validation
-- ============================================================
DO $$
DECLARE
  c collection;
  long_key text;
BEGIN
  long_key := repeat('x', 32768);
  c := add(c, long_key, 'val');
EXCEPTION WHEN program_limit_exceeded THEN
  RAISE NOTICE 'key length error caught';
END $$;

-- ============================================================
-- Empty collection operations
-- ============================================================
DO $$
DECLARE
  c collection;
  v text;
  ok boolean;
BEGIN
  c := add(c, 'a', 'val');
  c := delete(c, 'a');
  -- now c is empty but not null

  ASSERT count(c) = 0, 'empty count';
  ASSERT key(c) IS NULL, 'empty key';
  ASSERT value(c) IS NULL, 'empty value';
  ASSERT isnull(c), 'empty isnull';
  ASSERT first_key(c) IS NULL, 'empty first_key';
  ASSERT last_key(c) IS NULL, 'empty last_key';
  ASSERT value_type(c) IS NULL, 'empty value_type';

  -- sort on empty should not error
  c := sort(c);
  ASSERT count(c) = 0, 'empty sort count';

  -- copy of empty returns null
  ASSERT copy(c) IS NULL, 'empty copy';

  -- find on empty should error
  ok := false;
  BEGIN
    v := find(c, 'nope');
  EXCEPTION WHEN no_data_found THEN
    ok := true;
  END;
  ASSERT ok, 'find on empty should error';
END $$;

-- ============================================================
-- NULL arg edge cases
-- ============================================================
SELECT find(null::collection, 'k');
SELECT exist(null::collection, 'k');
SELECT count(null::collection);

-- ============================================================
-- Cast error path
-- ============================================================
DO $$
DECLARE
  c collection;
  t collection('bigint');
BEGIN
  c := add(c, 'a', 'hello');
  t := c;
EXCEPTION WHEN datatype_mismatch THEN
  RAISE NOTICE 'cast error caught';
END $$;

-- ============================================================
-- PART 2: icollection (int-keyed)
-- ============================================================

-- Test icollection type

-- Basic DO block tests matching collection test structure
DO $$
DECLARE
  ic   icollection;
BEGIN
  RAISE NOTICE 'Test 1';
  ic := add(ic, 1, 'Hello World'::text);
  RAISE NOTICE 'value: %', value(ic);
END
$$;

DO $$
DECLARE
  ic   icollection;
BEGIN
  RAISE NOTICE 'Test 2';
  ic := add(ic, 1, '1999-12-31'::date);
  RAISE NOTICE 'value: %', value(ic);
END
$$;

DO $$
DECLARE
  ic   icollection;
BEGIN
  RAISE NOTICE 'Test 3';
  ic := add(ic, 1, 'Hello World'::text);
  ic := add(ic, 2, 'Hello All'::text);
  RAISE NOTICE 'count: %', count(ic);
END
$$;

DO $$
DECLARE
  ic   icollection;
BEGIN
  RAISE NOTICE 'Test 4';
  ic := add(ic, 1, 'Hello World'::text);
  ic := add(ic, 2, 'Hello All'::text);
  RAISE NOTICE 'find: %', find(ic, 1);
END
$$;

DO $$
DECLARE
  ic   icollection;
BEGIN
  RAISE NOTICE 'Test 5';
  ic := add(ic, 1, '1999-12-31'::date);
  ic := add(ic, 2, '2000-01-01'::date);
  RAISE NOTICE 'find: %', find(ic, 1);
END
$$;

DO $$
DECLARE
  ic   icollection;
  k    bigint;
BEGIN
  RAISE NOTICE 'Test 6';
  ic := add(ic, 1, 'Hello World');
  ic := add(ic, 2, 'Hello All');
  RAISE NOTICE 'count: %', count(ic);

  ic := add(ic, 3, 'Hello Everyone');
  ic := add(ic, 4, 'First Hello');
  RAISE NOTICE 'count: %', count(ic);

  k := key(ic);
  RAISE NOTICE 'current key: %', k;
END
$$;

-- Test empty icollection creation
SELECT '{}'::icollection;

-- Test that icollection type exists and is distinct
SELECT typname FROM pg_type WHERE typname = 'icollection';

-- Test icollection_add function
SELECT add('{}'::icollection, 1, 'hello'::text);
SELECT add(add('{}'::icollection, 1, 'hello'::text), 2, 'world'::text);

-- Test with different value types
SELECT add(add('{}'::icollection, 10, 42), 20, 100);
SELECT add(add('{}'::icollection, 1, '2024-01-01'::date), 2, '2024-12-31'::date);
SELECT add(add('{}'::icollection, 1, 1.5::float8), 2, 2.5::float8);

-- Test with NULL values
SELECT add(add('{}'::icollection, 1, 'value'::text), 2, NULL::text);
SELECT add(add('{}'::icollection, 1, '1999-12-31'::date), 2, null::date);

-- Test key replacement
SELECT add(add(add('{}'::icollection, 1, 'first'::text), 1, 'second'::text), 2, 'third'::text);

-- Test find function
SELECT find(add(add('{}'::icollection, 1, 'hello'::text), 2, 'world'::text), 1);
SELECT find(add(add('{}'::icollection, 1, 'hello'::text), 2, 'world'::text), 2);

-- Test find with NULL value
SELECT find(add('{}'::icollection, 1, NULL::text), 1);

-- Test find with non-existent key (should error)
SELECT find('{}'::icollection, 999);

-- Test exist function
SELECT exist(add(add('{}'::icollection, 1, 'hello'::text), 2, 'world'::text), 1);
SELECT exist(add(add('{}'::icollection, 1, 'hello'::text), 2, 'world'::text), 999);
SELECT exist(add('{}'::icollection, 1, NULL::text), 1);
SELECT exist('{}'::icollection, 1);

-- Test count function
SELECT count('{}'::icollection);
SELECT count(add('{}'::icollection, 1, 'hello'::text));
SELECT count(add(add('{}'::icollection, 1, 'hello'::text), 2, 'world'::text));

-- Test delete function
SELECT delete(add(add('{}'::icollection, 1, 'hello'::text), 2, 'world'::text), 1);
SELECT count(delete(add(add('{}'::icollection, 1, 'hello'::text), 2, 'world'::text), 1));
SELECT delete('{}'::icollection, 999);  -- delete non-existent key

-- Test delete with pass-by-value types (int4) - regression test for bug fixed in commit 16eecda
DO $$
DECLARE
    ic icollection('int4');
BEGIN
    ic := add(ic, 1, 10);
    ic := add(ic, 2, 20);
    ic := add(ic, 3, 30);
    
    ic := delete(ic, 1);
    RAISE NOTICE 'After delete 1, count: %', count(ic);
    
    ic := delete(ic, 2);
    RAISE NOTICE 'After delete 2, count: %', count(ic);
    
    ic := delete(ic, 3);
    RAISE NOTICE 'After delete 3, count: %', count(ic);
END $$;

-- Test iterator functions
DO $$
DECLARE
    ic icollection;
BEGIN
    ic := add(add(add('{}'::icollection, 1, 'first'::text), 2, 'second'::text), 3, 'third'::text);
    ic := first(ic);
    
    WHILE NOT isnull(ic) LOOP
        RAISE NOTICE 'key: %, value: %', key(ic), value(ic);
        ic := next(ic);
    END LOOP;
END $$;

-- Test last and prev
DO $$
DECLARE
    ic icollection;
BEGIN
    ic := add(add(add('{}'::icollection, 1, 'first'::text), 2, 'second'::text), 3, 'third'::text);
    ic := last(ic);
    
    WHILE NOT isnull(ic) LOOP
        RAISE NOTICE 'key: %, value: %', key(ic), value(ic);
        ic := prev(ic);
    END LOOP;
END $$;

-- Test iterator on empty collection
DO $$
DECLARE
    ic icollection;
BEGIN
    ic := '{}'::icollection;
    ic := first(ic);
    
    IF isnull(ic) THEN
        RAISE NOTICE 'Empty collection iterator is null';
    END IF;
END $$;

-- Test sort function
SELECT sort(add(add(add('{}'::icollection, 3, 'third'::text), 1, 'first'::text), 2, 'second'::text));
SELECT sort(add(add(add('{}'::icollection, 100, 'z'::text), -50, 'a'::text), 0, 'm'::text));

-- Test copy function
DO $$
DECLARE
    ic1 icollection;
    ic2 icollection;
BEGIN
    ic1 := add(add('{}'::icollection, 1, 'original'::text), 2, 'data'::text);
    ic2 := copy(ic1);
    ic2 := add(ic2, 3, 'modified'::text);
    
    RAISE NOTICE 'ic1 count: %', count(ic1);
    RAISE NOTICE 'ic2 count: %', count(ic2);
END $$;

-- Test copy of empty collection
SELECT copy('{}'::icollection);

-- Test value_type function
SELECT value_type(add('{}'::icollection, 1, 'text'::text));
SELECT value_type(add('{}'::icollection, 1, 42::int4));
SELECT value_type(add('{}'::icollection, 1, '2024-01-01'::date));

-- Test keys_to_table function
SELECT * FROM keys_to_table(add(add(add('{}'::icollection, 3, 'c'::text), 1, 'a'::text), 2, 'b'::text)) ORDER BY 1;
SELECT * FROM keys_to_table('{}'::icollection);  -- empty collection

-- Test values_to_table function
SELECT * FROM values_to_table(sort(add(add(add('{}'::icollection, 3, 'third'::text), 1, 'first'::text), 2, 'second'::text)));
SELECT * FROM values_to_table(add(add('{}'::icollection, 1, 'value'::text), 2, NULL::text));  -- with NULL

-- Test to_table function
SELECT * FROM to_table(add(add(add('{}'::icollection, 10, 'ten'::text), 20, 'twenty'::text), 30, 'thirty'::text)) ORDER BY key;
SELECT * FROM to_table('{}'::icollection);  -- empty collection

-- Test negative keys
SELECT add(add(add('{}'::icollection, -1, 'negative'::text), 0, 'zero'::text), 1, 'positive'::text);
SELECT sort(add(add(add('{}'::icollection, -1, 'negative'::text), 0, 'zero'::text), 1, 'positive'::text));

-- Test large keys
SELECT add(add('{}'::icollection, 9223372036854775807, 'max'::text), -9223372036854775808, 'min'::text);

-- Test JSON parsing
SELECT '{"value_type":"text","entries":{"1":"hello","2":"world"}}'::icollection;
SELECT '{"value_type":"int4","entries":{"10":"100","20":"200"}}'::icollection;
SELECT '{"entries":{"1":"default text"}}'::icollection;
SELECT '{"value_type":"text","entries":{"1":"value","2":null}}'::icollection;
SELECT count('{"value_type":"text","entries":{"1":"a","2":"b","3":"c"}}'::icollection);

-- Test JSON parsing with find
SELECT find('{"value_type":"text","entries":{"1":"hello","2":"world"}}'::icollection, 1);
SELECT find('{"value_type":"text","entries":{"1":"hello","2":"world"}}'::icollection, 2);

-- Test key navigation functions
DO $$
DECLARE
    ic icollection;
BEGIN
    ic := add(add(add('{}'::icollection, 1, 'first'::text), 2, 'second'::text), 3, 'third'::text);
    
    RAISE NOTICE 'first_key: %', first_key(ic);
    RAISE NOTICE 'last_key: %', last_key(ic);
    RAISE NOTICE 'next_key(1): %', next_key(ic, 1);
    RAISE NOTICE 'prev_key(3): %', prev_key(ic, 3);
END $$;

-- Test key navigation with NULL returns
DO $$
DECLARE
    ic icollection;
BEGIN
    ic := add(add('{}'::icollection, 1, 'first'::text), 2, 'second'::text);
    
    RAISE NOTICE 'next_key(2) is null: %', next_key(ic, 2) IS NULL;
    RAISE NOTICE 'prev_key(1) is null: %', prev_key(ic, 1) IS NULL;
END $$;

-- Test typmod syntax
DO $$
DECLARE
    ic icollection('int4');
BEGIN
    ic[1] := 100;
    ic[2] := 200;
    RAISE NOTICE 'value_type: %', value_type(ic);
END $$;

-- Test polymorphic value
DO $$
DECLARE
  ic   icollection;
BEGIN
  RAISE NOTICE 'Test 7';
  ic := add(ic, 1, 'Hello World'::text);
  RAISE NOTICE 'value: %', value(ic, null::varchar);
END
$$;

DO $$
DECLARE
  ic   icollection;
BEGIN
  RAISE NOTICE 'Test 8';
  ic := add(ic, 1, '1999-12-31'::date);
  RAISE NOTICE 'value: %', value(ic, null::date);
END
$$;

-- Test polymorphic find
DO $$
DECLARE
  ic   icollection;
BEGIN
  RAISE NOTICE 'Test 9';
  ic := add(ic, 1, 'Hello World'::text);
  ic := add(ic, 2, 'Hello All'::text);
  RAISE NOTICE 'find: %', find(ic, 1, null::text);
END
$$;

DO $$
DECLARE
  ic   icollection;
BEGIN
  RAISE NOTICE 'Test 10';
  ic := add(ic, 1, '1999-12-31'::date);
  ic := add(ic, 2, '2000-01-01'::date);
  RAISE NOTICE 'find: %', find(ic, 1, null::text);
END
$$;

-- Test delete then re-add
DO $$
DECLARE
  ic   icollection;
BEGIN
  RAISE NOTICE 'Test 11';
  ic := add(ic, 1, 'Hello World'::text);
  ic := add(ic, 2, 'Hello All'::text);
  ic := delete(ic, 1);
  ic := delete(ic, 2);
  ic := add(ic, 1, 'Hello'::text);
  ic := add(ic, 2, 'World'::text);
  RAISE NOTICE 'count: %', count(ic);
END
$$;

-- Test add with NULL value
DO $$
DECLARE
  ic   icollection;
BEGIN
  RAISE NOTICE 'Test 12';
  ic := add(ic, 1, 'Hello World'::text);
  ic := add(ic, 2, null);
  RAISE NOTICE 'count: %', count(ic);
END
$$;

-- Test exist with NULL key
DO $$
DECLARE
  ic   icollection;
BEGIN
  RAISE NOTICE 'Test 13';
  ic := add(ic, 1, 'Hello World'::text);
  ic := add(ic, 2, 'Hello All'::text);

  RAISE NOTICE '2 exist: %', exist(ic, 2);
  RAISE NOTICE '999 exist: %', exist(ic, 999);
  RAISE NOTICE '<null> exist: %', exist(ic, null);
END
$$;

-- Test find on uninitialized, empty, non-empty with missing key
DO $$
DECLARE
  c1 icollection('text');
BEGIN
  RAISE NOTICE 'Test 14';
  RAISE NOTICE 'find(c1): %', find(c1, 2, NULL::TEXT);
END $$;

DO $$
DECLARE
  c3 icollection('text');
BEGIN
  RAISE NOTICE 'Test 15';
  c3 := add(c3, 1, 'Hello World');
  RAISE NOTICE 'find(c3): %', find(c3, 2, NULL::TEXT);
END $$;

-- Test count on uninitialized and empty
DO $$
DECLARE
  c1 icollection('text');
  c3 icollection('text');
BEGIN
  RAISE NOTICE 'Test 16';

  RAISE NOTICE 'count(c1): %', count(c1);

  c3 := add(c3, 1, 'Hello World');
  RAISE NOTICE 'count(c3): %', count(c3);
END
$$;

-- Test duplicate key replacement
DO $$
DECLARE
  val1 icollection('int4');
BEGIN
  RAISE NOTICE 'Test 17';
  val1 := add(val1, 1, 1::int4);
  val1 := add(val1, 1, 2::int4);
END;
$$;

-- Test value_type
DO $$
DECLARE
  ic  icollection;
BEGIN
  RAISE NOTICE 'Test 18';
  ic := add(ic, 1, 111::bigint);
  RAISE NOTICE 'The type is %', value_type(ic);
END
$$;

-- Test mixed type error
DO $$
DECLARE
  ic  icollection;
BEGIN
  RAISE NOTICE 'Test 19';
  ic := add(ic, 1, 111::bigint);
  ic := add(ic, 2, 'hello'::text);
END
$$;

-- Test polymorphic value with bigint
DO $$
DECLARE
  ic  icollection;
BEGIN
  RAISE NOTICE 'Test 20';
  ic := add(ic, 1, 111::bigint);
  ic := add(ic, 2, 222::bigint);
  RAISE NOTICE 'The current val is %', value(ic, null::bigint);
  RAISE NOTICE 'The current value type is %', pg_typeof(value(ic, null::bigint));
END
$$;

-- Test typmod with numeric
DO $$
DECLARE
  ic icollection('numeric(8,2)');
BEGIN
  RAISE NOTICE 'Test 21';
  ic[1] := 3.14::numeric;
END $$;

-- Test JSON output
DO $$
DECLARE
  ic   icollection('text');
BEGIN
  RAISE NOTICE 'Test 22';
  ic := add(ic, 1, 'Hello World');
  ic := add(ic, 2, 'Hello All');

  RAISE NOTICE 'json: %', to_json(ic);
END
$$;

DO $$
DECLARE
  ic   icollection('int');
BEGIN
  RAISE NOTICE 'Test 23';
  ic := add(ic, 1, 42);
  ic := add(ic, 2, 84);

  RAISE NOTICE 'json: %', to_json(ic);
END
$$;

-- Test table storage
CREATE TABLE icollections_test (c1 int, c2 icollection);

INSERT INTO icollections_test VALUES (1, add(null::icollection, 1, 'Hello World'));
INSERT INTO icollections_test VALUES (2, add(null::icollection, 2, 'Hello ALL'));

SELECT * FROM icollections_test ORDER BY c1;

DROP TABLE icollections_test;

-- Test stats (icollection shares collection_stats counters)
SELECT collection_stats_reset();

DO $$
DECLARE
  ic1 icollection('text');
  ic2 icollection('text');
BEGIN
  RAISE NOTICE 'Test 24';
  ic1 := add(ic1, 1, 'Hello World');
  ic1 := add(ic1, 2, 'Hello All');

  ic2 := ic1;
  ic2 := add(ic2, 3, 'Hi');
  RAISE NOTICE 'count: ic1(%), ic2(%)', count(ic1), count(ic2);
END
$$;

SELECT * FROM collection_stats;

-- Test copy semantics
DO $$
DECLARE
  ic1 icollection('text');
  ic2 icollection('text');
BEGIN
  RAISE NOTICE 'Test 25';
  ic1 := add(ic1, 1, 'Hello World');
  ic1 := add(ic1, 2, 'Hello All');

  ic2 := copy(ic1);
  ic2 := add(ic2, 3, 'Hi');
  RAISE NOTICE 'count: ic1(%), ic2(%)', count(ic1), count(ic2);
END
$$;

-- Test JSON parse errors
SELECT '{"value_type": "text", "entries": {"1": "Hello World"}'::icollection;

SELECT '{"value_type": "text", "entry": {"1": "Hello World"}}'::icollection;

SELECT '{"entries": {"1": "Hello World"}}'::icollection;

SELECT '{"entries": {"1": "Hello World"}, "value_type": "text"}'::icollection;

SELECT '{"value_type": "text", "entries": {"1": "Hello World", "2": 1}}'::icollection;

-- Test delete via SQL
SELECT delete('{"value_type": "pg_catalog.text", "entries": {"1": "A", "2": "B", "3": "C"}}'::icollection, 1);

-- Test nested icollection
DO $$
DECLARE
  arr_instance icollection('icollection');
BEGIN
  RAISE NOTICE 'Test 26';

  arr_instance := add(arr_instance, 1, add(NULL::icollection, 10, 1::int));

  FOR i IN 1..10 LOOP
    RAISE NOTICE 'Attempt: %', i;
    arr_instance := add(arr_instance, 1, add(find(arr_instance, 1, NULL::icollection), 20, 1::int));
  END LOOP;
END $$;

-- ============================================================
-- Flatten/unflatten roundtrip with typed icollections
-- ============================================================
CREATE TABLE icollection_persist_test(id serial, ic icollection);

-- bigint values
INSERT INTO icollection_persist_test(ic)
  SELECT add(add(null::icollection, 1, 100::bigint), 2, 200::bigint);

-- date values
INSERT INTO icollection_persist_test(ic)
  SELECT add(add(null::icollection, 10, '2026-01-01'::date), 20, '2026-12-31'::date);

-- icollection with NULL values
INSERT INTO icollection_persist_test(ic)
  SELECT add(add(null::icollection, 1, 'hello'), 2, null::text);

SELECT id, ic FROM icollection_persist_test ORDER BY id;
SELECT id, count(ic), value_type(ic) FROM icollection_persist_test ORDER BY id;

-- verify values survive roundtrip
DO $$
DECLARE
  r record;
BEGIN
  SELECT ic INTO r FROM icollection_persist_test WHERE id = 1;
  ASSERT find(r.ic, 1, 0::bigint) = 100, 'ic bigint roundtrip failed';
  ASSERT find(r.ic, 2, 0::bigint) = 200, 'ic bigint roundtrip 2 failed';

  SELECT ic INTO r FROM icollection_persist_test WHERE id = 2;
  ASSERT find(r.ic, 10, '2000-01-01'::date) = '2026-01-01'::date, 'ic date roundtrip failed';

  SELECT ic INTO r FROM icollection_persist_test WHERE id = 3;
  ASSERT find(r.ic, 1) = 'hello', 'ic text roundtrip failed';
  ASSERT find(r.ic, 2) IS NULL, 'ic null roundtrip failed';
END $$;

DROP TABLE icollection_persist_test;

-- ============================================================
-- Delete all then reuse
-- ============================================================
DO $$
DECLARE
  ic icollection;
BEGIN
  ic := add(ic, 1, 'one');
  ic := add(ic, 2, 'two');
  ic := delete(ic, 1);
  ic := delete(ic, 2);
  ASSERT count(ic) = 0, 'ic count after delete-all should be 0';
  ASSERT isnull(ic), 'ic iterator should be null after delete-all';

  ic := add(ic, 99, 'new');
  ASSERT count(ic) = 1, 'ic count after re-add should be 1';
  ASSERT find(ic, 99) = 'new', 'ic find after re-add failed';
END $$;

-- ============================================================
-- Empty icollection operations
-- ============================================================
DO $$
DECLARE
  ic icollection;
  v text;
  ok boolean;
BEGIN
  ic := add(ic, 1, 'val');
  ic := delete(ic, 1);

  ASSERT count(ic) = 0, 'ic empty count';
  ASSERT key(ic) IS NULL, 'ic empty key';
  ASSERT value(ic) IS NULL, 'ic empty value';
  ASSERT isnull(ic), 'ic empty isnull';
  ASSERT first_key(ic) IS NULL, 'ic empty first_key';
  ASSERT last_key(ic) IS NULL, 'ic empty last_key';
  ASSERT value_type(ic) IS NULL, 'ic empty value_type';

  ic := sort(ic);
  ASSERT count(ic) = 0, 'ic empty sort count';

  ASSERT copy(ic) IS NULL, 'ic empty copy';

  ok := false;
  BEGIN
    v := find(ic, 1);
  EXCEPTION WHEN no_data_found THEN
    ok := true;
  END;
  ASSERT ok, 'ic find on empty should error';
END $$;

-- ============================================================
-- Cast error path
-- ============================================================
DO $$
DECLARE
  ic icollection;
  t  icollection('bigint');
BEGIN
  ic := add(ic, 1, 'hello');
  t := ic;
EXCEPTION WHEN datatype_mismatch THEN
  RAISE NOTICE 'ic cast error caught';
END $$;


-- ============================================================
-- delete() with no args — collection
-- ============================================================
DO
$$
DECLARE
  c collection;
BEGIN
  c['a'] := 'alpha';
  c['b'] := 'bravo';
  c['c'] := 'charlie';
  ASSERT count(c) = 3, 'pre-delete count';
  c := delete(c);
  ASSERT count(c) = 0, 'post-delete count';
  ASSERT isnull(c), 'iterator null after delete all';
  c['d'] := 'delta';
  ASSERT count(c) = 1, 'add after delete all';
  ASSERT find(c, 'd') = 'delta', 'find after delete all';
END;
$$;

-- delete() with no args — collection (date values, type preserved)
DO
$$
DECLARE
  c collection('date');
BEGIN
  c['start'] := '2024-01-01'::date;
  c['end']   := '2024-12-31'::date;
  c := delete(c);
  ASSERT count(c) = 0, 'date delete all';
  c['mid'] := '2024-06-15'::date;
  ASSERT find(c, 'mid', NULL::date) = '2024-06-15'::date, 'date add after delete';
END;
$$;

-- delete() with no args — collection (numeric values, type preserved)
DO
$$
DECLARE
  c collection('numeric');
BEGIN
  c['pi']  := 3.14159;
  c['e']   := 2.71828;
  c['phi'] := 1.61803;
  c := delete(c);
  ASSERT count(c) = 0, 'numeric delete all';
  c['tau'] := 6.28318;
  ASSERT find(c, 'tau', NULL::numeric) = 6.28318, 'numeric add after delete';
END;
$$;

-- delete() with no args — collection (composite type, type preserved)
CREATE TYPE test_delete_comp AS (x int, y int);

DO
$$
DECLARE
  c   collection('test_delete_comp');
  val test_delete_comp;
BEGIN
  c['p1'] := ROW(1, 2)::test_delete_comp;
  c['p2'] := ROW(3, 4)::test_delete_comp;
  c := delete(c);
  ASSERT count(c) = 0, 'composite delete all';
  c['p3'] := ROW(5, 6)::test_delete_comp;
  val := find(c, 'p3', NULL::test_delete_comp);
  ASSERT val.x = 5 AND val.y = 6, 'composite add after delete';
END;
$$;

DROP TYPE test_delete_comp;

-- ============================================================
-- delete() with no args — icollection
-- ============================================================
DO
$$
DECLARE
  ic icollection('text');
BEGIN
  ic[1]   := 'one';
  ic[100] := 'hundred';
  ic[999] := 'nine-nine-nine';
  ASSERT count(ic) = 3, 'ic pre-delete';
  ic := delete(ic);
  ASSERT count(ic) = 0, 'ic post-delete';
  ASSERT isnull(ic), 'ic iterator null';
  ic[42] := 'answer';
  ASSERT count(ic) = 1, 'ic add after delete';
  ASSERT find(ic, 42) = 'answer', 'ic find after delete';
END;
$$;

-- delete() with no args — icollection (int4 values, type preserved)
DO
$$
DECLARE
  ic icollection('int4');
BEGIN
  ic[1] := 10;
  ic[2] := 20;
  ic[3] := 30;
  ic := delete(ic);
  ASSERT count(ic) = 0, 'int4 ic delete all';
  ic[4] := 40;
  ASSERT find(ic, 4, NULL::int4) = 40, 'int4 ic add after delete';
END;
$$;

-- delete() with no args — icollection (bigint extreme keys)
DO
$$
DECLARE
  ic icollection('bigint');
BEGIN
  ic[9223372036854775807] := 9223372036854775807;
  ic[-9223372036854775808] := -9223372036854775808;
  ic[0] := 0;
  ASSERT count(ic) = 3, 'bigint extreme keys pre-delete';
  ic := delete(ic);
  ASSERT count(ic) = 0, 'bigint extreme keys post-delete';
  ic[1] := 1;
  ASSERT find(ic, 1, NULL::bigint) = 1, 'bigint add after delete';
END;
$$;

-- single-key delete still works after adding delete() overload
DO
$$
DECLARE
  c  collection;
  ic icollection('text');
BEGIN
  c['a'] := '1'; c['b'] := '2'; c['c'] := '3';
  c := delete(c, 'b');
  ASSERT count(c) = 2, 'single delete still works';
  ASSERT NOT exist(c, 'b'), 'single deleted key gone';
  ASSERT find(c, 'a') = '1', 'other keys intact';

  ic[1] := 'x'; ic[2] := 'y';
  ic := delete(ic, 1);
  ASSERT count(ic) = 1, 'ic single delete still works';
  ASSERT find(ic, 2) = 'y', 'ic other key intact';
END;
$$;


-- ============================================================
-- delete(collection, lo, hi) — range delete
-- ============================================================
DO
$$
DECLARE
  c collection;
BEGIN
  c['a'] := '1'; c['b'] := '2'; c['c'] := '3'; c['d'] := '4'; c['e'] := '5';
  c := delete(c, 'b', 'd');
  ASSERT count(c) = 2, 'range delete count';
  ASSERT exist(c, 'a') AND exist(c, 'e'), 'endpoints survive';
  ASSERT NOT exist(c, 'b') AND NOT exist(c, 'c') AND NOT exist(c, 'd'), 'range deleted';
END;
$$;

-- delete(collection, lo, hi) — lo/hi don't exist as keys
DO
$$
DECLARE
  c collection;
BEGIN
  c['a'] := '1'; c['c'] := '3'; c['e'] := '5'; c['g'] := '7';
  c := delete(c, 'b', 'f');
  ASSERT count(c) = 2, 'non-existent bounds';
  ASSERT exist(c, 'a') AND exist(c, 'g'), 'outside range survives';
END;
$$;

-- delete(icollection, lo, hi) — range delete
DO
$$
DECLARE
  ic icollection('text');
BEGIN
  ic[1] := 'one'; ic[5] := 'five'; ic[10] := 'ten'; ic[15] := 'fifteen'; ic[20] := 'twenty';
  ic := delete(ic, 5::bigint, 15::bigint);
  ASSERT count(ic) = 2, 'ic range delete count';
  ASSERT exist(ic, 1) AND exist(ic, 20), 'ic endpoints survive';
END;
$$;

-- delete(icollection, lo, hi) — negative keys
DO
$$
DECLARE
  ic icollection('text');
BEGIN
  ic[-10] := 'a'; ic[-5] := 'b'; ic[0] := 'c'; ic[5] := 'd'; ic[10] := 'e';
  ic := delete(ic, (-5)::bigint, 5::bigint);
  ASSERT count(ic) = 2, 'negative range count';
  ASSERT exist(ic, -10) AND exist(ic, 10), 'negative range endpoints';
END;
$$;
