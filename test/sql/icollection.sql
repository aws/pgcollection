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
