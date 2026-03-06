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
