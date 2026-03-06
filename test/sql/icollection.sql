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
