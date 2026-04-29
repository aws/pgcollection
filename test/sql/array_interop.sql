--
-- array_interop.sql
--     Tests for to_icollection (array → icollection) and
--     to_array (icollection → array) conversions, implicit casts,
--     and round-trip behavior.
--

-- ============================================================
-- to_icollection: basic conversions
-- ============================================================

-- int array
DO $$
DECLARE
  v icollection;
BEGIN
  RAISE NOTICE 'Test 1: int array';
  v := to_icollection(ARRAY[10, 20, 30]);
  RAISE NOTICE 'count: %', count(v);
  RAISE NOTICE 'v[1]: %', v[1]::int;
  RAISE NOTICE 'v[2]: %', v[2]::int;
  RAISE NOTICE 'v[3]: %', v[3]::int;
END
$$;

-- text array
DO $$
DECLARE
  v icollection;
BEGIN
  RAISE NOTICE 'Test 2: text array';
  v := to_icollection(ARRAY['a', 'b', 'c']);
  RAISE NOTICE 'count: %', count(v);
  RAISE NOTICE 'v[1]: %', v[1]::text;
  RAISE NOTICE 'v[2]: %', v[2]::text;
  RAISE NOTICE 'v[3]: %', v[3]::text;
END
$$;

-- bigint array
DO $$
DECLARE
  v icollection;
BEGIN
  RAISE NOTICE 'Test 3: bigint array';
  v := to_icollection(ARRAY[100000000000, 200000000000]::bigint[]);
  RAISE NOTICE 'v[1]: %', v[1]::bigint;
  RAISE NOTICE 'v[2]: %', v[2]::bigint;
END
$$;

-- boolean array
DO $$
DECLARE
  v icollection;
BEGIN
  RAISE NOTICE 'Test 4: boolean array';
  v := to_icollection(ARRAY[true, false, true]);
  RAISE NOTICE 'v[1]: %', v[1]::boolean;
  RAISE NOTICE 'v[2]: %', v[2]::boolean;
  RAISE NOTICE 'v[3]: %', v[3]::boolean;
END
$$;

-- float8 array
DO $$
DECLARE
  v icollection;
BEGIN
  RAISE NOTICE 'Test 5: float8 array';
  v := to_icollection(ARRAY[1.1, 2.2, 3.3]::float8[]);
  RAISE NOTICE 'v[1]: %', v[1]::float8;
  RAISE NOTICE 'v[2]: %', v[2]::float8;
  RAISE NOTICE 'v[3]: %', v[3]::float8;
END
$$;

-- ============================================================
-- to_icollection: edge cases
-- ============================================================

-- empty array
DO $$
DECLARE
  v icollection;
BEGIN
  RAISE NOTICE 'Test 6: empty array';
  v := to_icollection(ARRAY[]::int[]);
  RAISE NOTICE 'count: %', count(v);
END
$$;

-- NULL input
DO $$
DECLARE
  v icollection;
BEGIN
  RAISE NOTICE 'Test 7: NULL input';
  v := to_icollection(NULL::int[]);
  RAISE NOTICE 'is null: %', v IS NULL;
END
$$;

-- array with NULL elements
DO $$
DECLARE
  v icollection;
BEGIN
  RAISE NOTICE 'Test 8: array with NULLs';
  v := to_icollection(ARRAY[1, NULL, 3]::int[]);
  RAISE NOTICE 'count: %', count(v);
  RAISE NOTICE 'v[1]: %', v[1]::int;
  RAISE NOTICE 'v[2] is null: %', NOT exist(v, 2) OR v[2]::text IS NULL;
  RAISE NOTICE 'v[3]: %', v[3]::int;
END
$$;

-- single element
DO $$
DECLARE
  v icollection;
BEGIN
  RAISE NOTICE 'Test 9: single element';
  v := to_icollection(ARRAY[42]);
  RAISE NOTICE 'count: %', count(v);
  RAISE NOTICE 'v[1]: %', v[1]::int;
END
$$;

-- multidimensional array rejected
DO $$
DECLARE
  v icollection;
BEGIN
  RAISE NOTICE 'Test 10: multidimensional rejected';
  v := to_icollection(ARRAY[[1,2],[3,4]]);
  RAISE NOTICE 'should not reach here';
EXCEPTION WHEN feature_not_supported THEN
  RAISE NOTICE 'caught: %', SQLERRM;
END
$$;

-- ============================================================
-- to_array: basic conversions
-- ============================================================

-- dense keys, default text[] return
DO $$
DECLARE
  v icollection;
BEGIN
  RAISE NOTICE 'Test 11: to_array dense';
  v := add(v, 1, 10);
  v := add(v, 2, 20);
  v := add(v, 3, 30);
  RAISE NOTICE 'result: %', to_array(v);
END
$$;

-- typed return via anyelement overload
DO $$
DECLARE
  v icollection;
  arr int[];
BEGIN
  RAISE NOTICE 'Test 12: to_array typed';
  v := add(v, 1, 10);
  v := add(v, 2, 20);
  v := add(v, 3, 30);
  arr := to_array(v, 0);
  RAISE NOTICE 'result: %', arr;
END
$$;

-- gaps become NULLs
DO $$
DECLARE
  v icollection;
BEGIN
  RAISE NOTICE 'Test 13: to_array with gaps';
  v := add(v, 1, 100);
  v := add(v, 3, 300);
  RAISE NOTICE 'result: %', to_array(v);
END
$$;

-- empty icollection
DO $$
DECLARE
  v icollection;
BEGIN
  RAISE NOTICE 'Test 14: to_array empty';
  RAISE NOTICE 'result: %', to_array(v);
END
$$;

-- NULL input
SELECT to_array(NULL::icollection);

-- NULL values preserved
DO $$
DECLARE
  v icollection;
BEGIN
  RAISE NOTICE 'Test 15: to_array with null values';
  v := add(v, 1, 10);
  v := add(v, 2, NULL::int);
  v := add(v, 3, 30);
  RAISE NOTICE 'result: %', to_array(v);
END
$$;

-- array lower bound matches min key
DO $$
DECLARE
  v icollection;
  arr text[];
BEGIN
  RAISE NOTICE 'Test 16: to_array preserves key as lower bound';
  v := add(v, 5, 'five');
  v := add(v, 7, 'seven');
  arr := to_array(v);
  RAISE NOTICE 'arr[5]: %', arr[5];
  RAISE NOTICE 'arr[6]: %', arr[6];
  RAISE NOTICE 'arr[7]: %', arr[7];
END
$$;

-- to_array does not mutate iteration order
DO $$
DECLARE
  v icollection;
  arr text[];
BEGIN
  RAISE NOTICE 'Test 17: to_array preserves iteration order';
  v := add(v, 3, 'three');
  v := add(v, 1, 'one');
  v := add(v, 2, 'two');
  v := first(v);
  RAISE NOTICE 'before: first key = %', key(v);
  arr := to_array(v);
  v := first(v);
  RAISE NOTICE 'after:  first key = %', key(v);
END
$$;

-- ============================================================
-- Round-trip tests
-- ============================================================

-- int round-trip
SELECT to_array(to_icollection(ARRAY[1, 2, 3]), 0);

-- text round-trip
SELECT to_array(to_icollection(ARRAY['x', 'y', 'z']), ''::text);

-- round-trip with NULLs
SELECT to_array(to_icollection(ARRAY[10, NULL, 30]::int[]), 0);

-- ============================================================
-- Implicit cast tests
-- ============================================================

-- int[] implicit cast
DO $$
DECLARE
  v icollection;
BEGIN
  RAISE NOTICE 'Test 18: implicit cast int[]';
  v := ARRAY[42, 99];
  RAISE NOTICE 'v[1]: %', v[1]::int;
  RAISE NOTICE 'v[2]: %', v[2]::int;
END
$$;

-- text[] implicit cast
DO $$
DECLARE
  v icollection;
BEGIN
  RAISE NOTICE 'Test 19: implicit cast text[]';
  v := ARRAY['hello', 'world'];
  RAISE NOTICE 'v[1]: %', v[1]::text;
  RAISE NOTICE 'v[2]: %', v[2]::text;
END
$$;

-- bigint[] implicit cast
DO $$
DECLARE
  v icollection;
BEGIN
  RAISE NOTICE 'Test 20: implicit cast bigint[]';
  v := ARRAY[1, 2, 3]::bigint[];
  RAISE NOTICE 'count: %', count(v);
END
$$;

-- ============================================================
-- BULK COLLECT pattern
-- ============================================================

CREATE TEMP TABLE bulk_test(id int, name text);
INSERT INTO bulk_test VALUES (101, 'Alice'), (202, 'Bob'), (303, 'Carol');

-- BULK COLLECT INTO with int column
DO $$
DECLARE
  v icollection;
BEGIN
  RAISE NOTICE 'Test 21: BULK COLLECT int';
  v := to_icollection(ARRAY(SELECT id FROM bulk_test ORDER BY id));
  RAISE NOTICE 'count: %', count(v);
  RAISE NOTICE 'v[1]: %', v[1]::int;
  RAISE NOTICE 'v[2]: %', v[2]::int;
  RAISE NOTICE 'v[3]: %', v[3]::int;
END
$$;

-- BULK COLLECT INTO with text column
DO $$
DECLARE
  v icollection;
BEGIN
  RAISE NOTICE 'Test 22: BULK COLLECT text';
  v := to_icollection(ARRAY(SELECT name FROM bulk_test ORDER BY id));
  RAISE NOTICE 'count: %', count(v);
  RAISE NOTICE 'v[1]: %', v[1]::text;
  RAISE NOTICE 'v[2]: %', v[2]::text;
  RAISE NOTICE 'v[3]: %', v[3]::text;
END
$$;

-- BULK COLLECT round-trip back to array
DO $$
DECLARE
  v icollection;
  arr int[];
BEGIN
  RAISE NOTICE 'Test 23: BULK COLLECT round-trip';
  v := to_icollection(ARRAY(SELECT id FROM bulk_test ORDER BY id));
  arr := to_array(v, 0);
  RAISE NOTICE 'result: %', arr;
END
$$;

DROP TABLE bulk_test;

-- ============================================================
-- Cross-type conversion tests
-- ============================================================

-- date array -> icollection preserves date type
DO $$
DECLARE
  v icollection;
BEGIN
  RAISE NOTICE 'Test 24: date array conversion';
  v := to_icollection(ARRAY['2024-01-01','2024-06-15']::date[]);
  RAISE NOTICE 'value_type: %', value_type(v);
  RAISE NOTICE 'v[1]: %', v[1]::text;
  RAISE NOTICE 'v[2]: %', v[2]::text;
END
$$;

-- date icollection -> access as incompatible type errors
DO $$
DECLARE
  v icollection;
BEGIN
  RAISE NOTICE 'Test 25: date accessed as int errors';
  v := to_icollection(ARRAY['2024-01-01']::date[]);
  RAISE NOTICE 'v[1] as int: %', v[1]::int;
EXCEPTION WHEN others THEN
  RAISE NOTICE 'caught: %', SQLERRM;
END
$$;

-- numeric array -> icollection, access as int errors (lossy)
DO $$
DECLARE
  v icollection;
BEGIN
  RAISE NOTICE 'Test 26: numeric accessed as int errors';
  v := to_icollection(ARRAY[1.5, 2.7]::numeric[]);
  RAISE NOTICE 'value_type: %', value_type(v);
  RAISE NOTICE 'v[1] as int: %', v[1]::int;
EXCEPTION WHEN others THEN
  RAISE NOTICE 'caught: %', SQLERRM;
END
$$;

-- int icollection -> to_array as text[] (widening coercion works)
DO $$
DECLARE
  v icollection;
  arr text[];
BEGIN
  RAISE NOTICE 'Test 27: int icollection to text array';
  v := add(v, 1, 42);
  v := add(v, 2, 99);
  arr := to_array(v, ''::text);
  RAISE NOTICE 'result: %', arr;
END
$$;

-- date round-trip: date[] -> icollection -> date[]
DO $$
DECLARE
  v icollection;
  arr date[];
BEGIN
  RAISE NOTICE 'Test 28: date round-trip';
  v := to_icollection(ARRAY['2024-01-01','2024-06-15']::date[]);
  arr := to_array(v, '2000-01-01'::date);
  RAISE NOTICE 'result: %', arr;
END
$$;

-- int[] assigned to typed icollection('text') errors
DO $$
DECLARE
  v icollection('text');
BEGIN
  RAISE NOTICE 'Test 29: int[] to icollection(text) errors';
  v := ARRAY[1, 2, 3];
  RAISE NOTICE 'should not reach here';
EXCEPTION WHEN datatype_mismatch THEN
  RAISE NOTICE 'caught: %', SQLERRM;
END
$$;

-- timestamp array conversion
DO $$
DECLARE
  v icollection;
BEGIN
  RAISE NOTICE 'Test 30: timestamp array';
  v := to_icollection(ARRAY['2024-01-01 12:00:00','2024-06-15 18:30:00']::timestamp[]);
  RAISE NOTICE 'value_type: %', value_type(v);
  RAISE NOTICE 'v[1]: %', v[1]::text;
  RAISE NOTICE 'v[2]: %', v[2]::text;
END
$$;

-- date[] has no implicit cast (no overload), requires explicit call
DO $$
DECLARE
  v icollection;
BEGIN
  RAISE NOTICE 'Test 31: date[] explicit conversion';
  v := to_icollection(ARRAY['2024-03-15']::date[]);
  RAISE NOTICE 'count: %', count(v);
  RAISE NOTICE 'value_type: %', value_type(v);
END
$$;

-- ============================================================
-- Overflow and boundary tests for to_array
-- ============================================================

-- key exceeding int32 range
DO $$
DECLARE v icollection;
BEGIN
  RAISE NOTICE 'Test 32: key > INT_MAX rejected';
  v := add(v, 3000000000::bigint, 'big');
  RAISE NOTICE 'to_array: %', to_array(v);
EXCEPTION WHEN program_limit_exceeded THEN
  RAISE NOTICE 'caught: %', SQLERRM;
END
$$;

-- negative key below int32 range
DO $$
DECLARE v icollection;
BEGIN
  RAISE NOTICE 'Test 33: key < INT_MIN rejected';
  v := add(v, -3000000000::bigint, 'neg');
  RAISE NOTICE 'to_array: %', to_array(v);
EXCEPTION WHEN program_limit_exceeded THEN
  RAISE NOTICE 'caught: %', SQLERRM;
END
$$;

-- huge sparse range exceeds allocation limit
DO $$
DECLARE v icollection;
BEGIN
  RAISE NOTICE 'Test 34: sparse range rejected';
  v := add(v, 1, 'lo');
  v := add(v, 2000000000, 'hi');
  RAISE NOTICE 'to_array: %', to_array(v);
EXCEPTION WHEN program_limit_exceeded THEN
  RAISE NOTICE 'caught: %', SQLERRM;
END
$$;

-- negative keys within int32 range work
DO $$
DECLARE v icollection;
BEGIN
  RAISE NOTICE 'Test 35: negative keys work';
  v := add(v, -2, 'neg2');
  v := add(v, 0, 'zero');
  v := add(v, 2, 'pos2');
  RAISE NOTICE 'result: %', to_array(v);
END
$$;

-- single element with large valid key
DO $$
DECLARE v icollection;
BEGIN
  RAISE NOTICE 'Test 36: single large key';
  v := add(v, 2000000000, 'big');
  RAISE NOTICE 'result: %', to_array(v);
END
$$;

-- ============================================================
-- Post-conversion mutation tests
-- Verify the icollection built from an array has correct
-- internal metadata by exercising all operations on it.
-- ============================================================

-- add to a converted icollection (tests value_type compatibility)
DO $$
DECLARE
  v icollection;
BEGIN
  RAISE NOTICE 'Test 37: add after from_array';
  v := to_icollection(ARRAY[10, 20, 30]);
  v := add(v, 4, 40);
  RAISE NOTICE 'count: %', count(v);
  RAISE NOTICE 'v[4]: %', v[4]::int;
END
$$;

-- add incompatible type to converted icollection (tests value_type enforcement)
DO $$
DECLARE
  v icollection;
BEGIN
  RAISE NOTICE 'Test 38: add incompatible type errors';
  v := to_icollection(ARRAY[10, 20, 30]);
  v := add(v, 4, 'text_value'::text);
EXCEPTION WHEN datatype_mismatch THEN
  RAISE NOTICE 'caught: %', SQLERRM;
END
$$;

-- delete from converted icollection
DO $$
DECLARE
  v icollection;
BEGIN
  RAISE NOTICE 'Test 39: delete after from_array';
  v := to_icollection(ARRAY[10, 20, 30]);
  v := delete(v, 2);
  RAISE NOTICE 'count: %', count(v);
  RAISE NOTICE 'exist(2): %', exist(v, 2);
  RAISE NOTICE 'v[1]: %', v[1]::int;
  RAISE NOTICE 'v[3]: %', v[3]::int;
END
$$;

-- delete_all from converted icollection
DO $$
DECLARE
  v icollection;
BEGIN
  RAISE NOTICE 'Test 40: delete_all after from_array';
  v := to_icollection(ARRAY[10, 20, 30]);
  v := delete(v);
  RAISE NOTICE 'count: %', count(v);
END
$$;

-- sort converted icollection
DO $$
DECLARE
  v icollection;
BEGIN
  RAISE NOTICE 'Test 41: sort after from_array';
  v := to_icollection(ARRAY[30, 10, 20]);
  v := sort(v);
  RAISE NOTICE 'first key: %', key(v);
  v := last(v);
  RAISE NOTICE 'last key: %', key(v);
END
$$;

-- copy converted icollection
DO $$
DECLARE
  v icollection;
  c icollection;
BEGIN
  RAISE NOTICE 'Test 42: copy after from_array';
  v := to_icollection(ARRAY[10, 20, 30]);
  c := copy(v);
  RAISE NOTICE 'copy count: %', count(c);
  RAISE NOTICE 'c[1]: %', c[1]::int;
  RAISE NOTICE 'c[3]: %', c[3]::int;
  -- mutate original, copy should be independent
  v := delete(v, 1);
  RAISE NOTICE 'orig count: %', count(v);
  RAISE NOTICE 'copy count: %', count(c);
END
$$;

-- full iteration over converted icollection
DO $$
DECLARE
  v icollection;
  k bigint;
BEGIN
  RAISE NOTICE 'Test 43: full iteration after from_array';
  v := to_icollection(ARRAY[100, 200, 300]);
  k := first_key(v);
  WHILE k IS NOT NULL LOOP
    RAISE NOTICE 'k=% v=%', k, find(v, k)::int;
    k := next_key(v, k);
  END LOOP;
END
$$;

-- iterator-based iteration
DO $$
DECLARE
  v icollection;
BEGIN
  RAISE NOTICE 'Test 44: iterator after from_array';
  v := to_icollection(ARRAY['alpha', 'bravo', 'charlie']);
  v := first(v);
  WHILE NOT isnull(v) LOOP
    RAISE NOTICE 'k=% v=%', key(v), value(v);
    v := next(v);
  END LOOP;
END
$$;

-- value_type preserved correctly
DO $$
DECLARE
  v icollection;
BEGIN
  RAISE NOTICE 'Test 45: value_type after from_array';
  v := to_icollection(ARRAY[1.5, 2.5]::numeric[]);
  RAISE NOTICE 'type: %', value_type(v);
  v := to_icollection(ARRAY[true, false]);
  RAISE NOTICE 'type: %', value_type(v);
  v := to_icollection(ARRAY['2024-01-01']::date[]);
  RAISE NOTICE 'type: %', value_type(v);
END
$$;

-- to_table on converted icollection (tests flatten path)
DO $$
DECLARE
  v icollection;
  r record;
BEGIN
  RAISE NOTICE 'Test 46: to_table after from_array';
  v := to_icollection(ARRAY[10, 20, 30]);
  FOR r IN SELECT * FROM to_table(v, 0) LOOP
    RAISE NOTICE 'k=% v=%', r.key, r.value;
  END LOOP;
END
$$;

-- persist to table and read back (tests flatten/expand round-trip)
DO $$
DECLARE
  v icollection;
  v2 icollection;
BEGIN
  RAISE NOTICE 'Test 47: persist after from_array';
  v := to_icollection(ARRAY[10, 20, 30]);
  CREATE TEMP TABLE _test_persist(data icollection) ON COMMIT DROP;
  INSERT INTO _test_persist VALUES (v);
  SELECT data INTO v2 FROM _test_persist;
  RAISE NOTICE 'count: %', count(v2);
  RAISE NOTICE 'v2[1]: %', v2[1]::int;
  RAISE NOTICE 'v2[2]: %', v2[2]::int;
  RAISE NOTICE 'v2[3]: %', v2[3]::int;
  RAISE NOTICE 'type: %', value_type(v2);
  DROP TABLE _test_persist;
END
$$;

-- text array: persist and read back (variable-length type)
DO $$
DECLARE
  v icollection;
  v2 icollection;
BEGIN
  RAISE NOTICE 'Test 48: persist text after from_array';
  v := to_icollection(ARRAY['hello', 'world']);
  CREATE TEMP TABLE _test_persist2(data icollection) ON COMMIT DROP;
  INSERT INTO _test_persist2 VALUES (v);
  SELECT data INTO v2 FROM _test_persist2;
  RAISE NOTICE 'count: %', count(v2);
  RAISE NOTICE 'v2[1]: %', v2[1]::text;
  RAISE NOTICE 'v2[2]: %', v2[2]::text;
  DROP TABLE _test_persist2;
END
$$;

-- convert from array with NULLs, then add/delete/iterate
DO $$
DECLARE
  v icollection;
BEGIN
  RAISE NOTICE 'Test 49: mutate after from_array with NULLs';
  v := to_icollection(ARRAY[1, NULL, 3]::int[]);
  v := add(v, 2, 22);
  RAISE NOTICE 'v[2] after overwrite: %', v[2]::int;
  v := delete(v, 1);
  RAISE NOTICE 'count: %', count(v);
  v := first(v);
  WHILE NOT isnull(v) LOOP
    RAISE NOTICE 'k=% v=%', key(v), value(v);
    v := next(v);
  END LOOP;
END
$$;

-- delete_range on converted icollection
DO $$
DECLARE
  v icollection;
BEGIN
  RAISE NOTICE 'Test 50: delete_range after from_array';
  v := to_icollection(ARRAY[10, 20, 30, 40, 50]);
  v := delete(v, 2::bigint, 4::bigint);
  RAISE NOTICE 'count: %', count(v);
  RAISE NOTICE 'v[1]: %', v[1]::int;
  RAISE NOTICE 'v[5]: %', v[5]::int;
END
$$;

-- persist with NULL values (flatten crash fix 6627a69)
DO $$
DECLARE
  v icollection;
  v2 icollection;
BEGIN
  RAISE NOTICE 'Test 51: persist with NULLs after from_array';
  v := to_icollection(ARRAY[10, NULL, 30]::int[]);
  CREATE TEMP TABLE _test_persist3(data icollection) ON COMMIT DROP;
  INSERT INTO _test_persist3 VALUES (v);
  SELECT data INTO v2 FROM _test_persist3;
  RAISE NOTICE 'count: %', count(v2);
  RAISE NOTICE 'v2[1]: %', v2[1]::int;
  RAISE NOTICE 'v2[2] null: %', v2[2]::text IS NULL;
  RAISE NOTICE 'v2[3]: %', v2[3]::int;
  DROP TABLE _test_persist3;
END
$$;

-- subscript assign on converted icollection (fix fa3d563)
DO $$
DECLARE
  v icollection('int');
BEGIN
  RAISE NOTICE 'Test 52: subscript assign after from_array';
  v := to_icollection(ARRAY[10, 20, 30]);
  v[2] := 99;
  RAISE NOTICE 'v[2]: %', v[2]::int;
  v[4] := 40;
  RAISE NOTICE 'v[4]: %', v[4]::int;
  RAISE NOTICE 'count: %', count(v);
END
$$;

-- subscript assign wrong type on converted icollection
DO $$
DECLARE
  v icollection('int');
BEGIN
  RAISE NOTICE 'Test 53: subscript assign wrong type errors';
  v := to_icollection(ARRAY[10, 20, 30]);
  v[1] := 'not_an_int'::text;
EXCEPTION WHEN others THEN
  RAISE NOTICE 'caught: %', SQLERRM;
END
$$;

-- INOUT parameter with converted icollection (fix 6a046e9)
CREATE OR REPLACE FUNCTION _test_inout(INOUT v icollection, key bigint, val int)
AS $$
BEGIN
  v := add(v, key, val);
END;
$$ LANGUAGE plpgsql;

DO $$
DECLARE
  v icollection;
BEGIN
  RAISE NOTICE 'Test 54: INOUT with from_array';
  v := to_icollection(ARRAY[10, 20, 30]);
  v := _test_inout(v, 4, 40);
  v := _test_inout(v, 5, 50);
  RAISE NOTICE 'count: %', count(v);
  RAISE NOTICE 'v[4]: %', v[4]::int;
  RAISE NOTICE 'v[5]: %', v[5]::int;
END
$$;

-- INOUT stress: multiple calls to exercise expanded object copy (fix 6a046e9)
DO $$
DECLARE
  v icollection;
  i int;
BEGIN
  RAISE NOTICE 'Test 55: INOUT stress with from_array';
  v := to_icollection(ARRAY[1, 2, 3]);
  FOR i IN 4..50 LOOP
    v := _test_inout(v, i, i * 10);
  END LOOP;
  RAISE NOTICE 'count: %', count(v);
  RAISE NOTICE 'v[50]: %', v[50]::int;
END
$$;

DROP FUNCTION _test_inout;
