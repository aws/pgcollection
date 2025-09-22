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
