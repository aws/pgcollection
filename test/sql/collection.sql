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
