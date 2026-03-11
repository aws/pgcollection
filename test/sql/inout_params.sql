--
-- inout_params.sql
--     INOUT parameter functionality for both collection and icollection.
--     Ensures collections work correctly as INOUT parameters without crashes.
--

-- ============================================================
-- PART 1: collection INOUT parameters
-- ============================================================

-- Test INOUT parameter functionality to prevent regression of double free bug
-- This test ensures collections work correctly as INOUT parameters without crashes

-- Test 1: Basic INOUT parameter with single call
CREATE OR REPLACE PROCEDURE test_inout_basic(INOUT c collection)
AS $$
BEGIN
  c := add(c, 'key1', 'value1'::text);
END;
$$ LANGUAGE plpgsql;

DO $$
DECLARE
  c collection('text');
BEGIN
  CALL test_inout_basic(c);
  RAISE NOTICE 'Basic INOUT test: % items', count(c);
  RAISE NOTICE 'Value: %', find(c, 'key1');
END;
$$;

-- Test 2: Multiple INOUT calls with data accumulation
CREATE OR REPLACE PROCEDURE test_inout_accumulate(INOUT c collection, key_name text, val int4)
AS $$
BEGIN
  c := add(c, key_name, val);
END;
$$ LANGUAGE plpgsql;

DO $$
DECLARE
  c collection('int4');
BEGIN
  FOR i IN 1..5 LOOP
    CALL test_inout_accumulate(c, 'key_' || i, i * 10);
    RAISE NOTICE 'Iteration %: % items', i, count(c);
  END LOOP;
  
  -- Verify all values are present
  FOR i IN 1..5 LOOP
    RAISE NOTICE 'key_%: %', i, find(c, 'key_' || i, 0::int4);
  END LOOP;
END;
$$;

-- Test 3: INOUT with different data types
CREATE OR REPLACE PROCEDURE test_inout_types(INOUT c collection, val date)
AS $$
BEGIN
  c := add(c, 'date_key', val);
END;
$$ LANGUAGE plpgsql;

DO $$
DECLARE
  c collection('date');
BEGIN
  CALL test_inout_types(c, '2024-01-01'::date);
  CALL test_inout_types(c, '2024-12-31'::date);
  RAISE NOTICE 'Date collection has % items', count(c);
END;
$$;

-- Test 4: INOUT with iteration after modification
CREATE OR REPLACE PROCEDURE test_inout_with_iteration(INOUT c collection)
AS $$
BEGIN
  c := add(c, 'iter1', 'first'::text);
  c := add(c, 'iter2', 'second'::text);
  c := add(c, 'iter3', 'third'::text);
END;
$$ LANGUAGE plpgsql;

DO $$
DECLARE
  c collection('text');
BEGIN
  CALL test_inout_with_iteration(c);
  
  -- Test iteration works correctly after INOUT modification
  c := first(c);
  WHILE NOT isnull(c) LOOP
    RAISE NOTICE 'Iteration: % = %', key(c), value(c);
    c := next(c);
  END LOOP;
END;
$$;

-- Test 5: Complex INOUT scenario with delete operations
CREATE OR REPLACE PROCEDURE test_inout_complex(INOUT c collection, operation text, k text, v text)
AS $$
BEGIN
  IF operation = 'add' THEN
    c := add(c, k, v);
  ELSIF operation = 'delete' THEN
    c := delete(c, k);
  END IF;
END;
$$ LANGUAGE plpgsql;

DO $$
DECLARE
  c collection('text');
BEGIN
  -- Add several items
  CALL test_inout_complex(c, 'add', 'a', 'alpha');
  CALL test_inout_complex(c, 'add', 'b', 'beta');
  CALL test_inout_complex(c, 'add', 'c', 'gamma');
  RAISE NOTICE 'After adds: % items', count(c);
  
  -- Delete one item
  CALL test_inout_complex(c, 'delete', 'b', '');
  RAISE NOTICE 'After delete: % items', count(c);
  
  -- Verify remaining items
  c := first(c);
  WHILE NOT isnull(c) LOOP
    RAISE NOTICE 'Remaining: % = %', key(c), value(c);
    c := next(c);
  END LOOP;
END;
$$;

-- Test 6: INOUT with null collections
CREATE OR REPLACE PROCEDURE test_inout_null(INOUT c collection)
AS $$
BEGIN
  IF c IS NULL THEN
    RAISE NOTICE 'Collection is null, creating new';
  END IF;
  c := add(c, 'null_test', 'created'::text);
END;
$$ LANGUAGE plpgsql;

DO $$
DECLARE
  c collection('text');
BEGIN
  -- c starts as null
  CALL test_inout_null(c);
  RAISE NOTICE 'Null test result: % items', count(c);
END;
$$;

-- Cleanup
DROP PROCEDURE test_inout_basic(INOUT collection);
DROP PROCEDURE test_inout_accumulate(INOUT collection, text, int4);
DROP PROCEDURE test_inout_types(INOUT collection, date);
DROP PROCEDURE test_inout_with_iteration(INOUT collection);
DROP PROCEDURE test_inout_complex(INOUT collection, text, text, text);
DROP PROCEDURE test_inout_null(INOUT collection);

-- Additional edge case tests for INOUT parameters

-- Test 7: Nested INOUT calls (procedure calling procedure)
CREATE OR REPLACE PROCEDURE test_inout_nested_inner(INOUT c collection, val text)
AS $$
BEGIN
  c := add(c, 'inner', val);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE test_inout_nested_outer(INOUT c collection)
AS $$
BEGIN
  c := add(c, 'outer', 'start');
  CALL test_inout_nested_inner(c, 'nested_value');
  c := add(c, 'final', 'end');
END;
$$ LANGUAGE plpgsql;

DO $$
DECLARE
  c collection('text');
BEGIN
  CALL test_inout_nested_outer(c);
  RAISE NOTICE 'Nested test: % items', count(c);
  
  c := first(c);
  WHILE NOT isnull(c) LOOP
    RAISE NOTICE 'Nested result: % = %', key(c), value(c);
    c := next(c);
  END LOOP;
END;
$$;

-- Test 8: INOUT with collection operations (sort, copy, etc.)
CREATE OR REPLACE PROCEDURE test_inout_operations(INOUT c collection)
AS $$
BEGIN
  c := add(c, 'z_last', 'should_be_last');
  c := add(c, 'a_first', 'should_be_first');
  c := add(c, 'm_middle', 'should_be_middle');
  c := sort(c);
END;
$$ LANGUAGE plpgsql;

DO $$
DECLARE
  c collection('text');
BEGIN
  CALL test_inout_operations(c);
  RAISE NOTICE 'Operations test: % items', count(c);
  
  c := first(c);
  WHILE NOT isnull(c) LOOP
    RAISE NOTICE 'Sorted: % = %', key(c), value(c);
    c := next(c);
  END LOOP;
END;
$$;

-- Test 9: INOUT with large collections (stress test)
CREATE OR REPLACE PROCEDURE test_inout_large(INOUT c collection, num_items int)
AS $$
BEGIN
  FOR i IN 1..num_items LOOP
    c := add(c, 'item_' || i, 'value_' || i);
  END LOOP;
END;
$$ LANGUAGE plpgsql;

DO $$
DECLARE
  c collection('text');
BEGIN
  CALL test_inout_large(c, 100);
  RAISE NOTICE 'Large collection test: % items', count(c);
  
  -- Test iteration over large collection
  c := first(c);
  DECLARE
    counter int := 0;
  BEGIN
    WHILE NOT isnull(c) AND counter < 5 LOOP
      counter := counter + 1;
      RAISE NOTICE 'Large item %: % = %', counter, key(c), value(c);
      c := next(c);
    END LOOP;
  END;
END;
$$;

-- Test 10: INOUT with exception handling
CREATE OR REPLACE PROCEDURE test_inout_exception(INOUT c collection, should_fail boolean)
AS $$
BEGIN
  c := add(c, 'before_exception', 'added');
  
  IF should_fail THEN
    RAISE EXCEPTION 'Intentional test exception';
  END IF;
  
  c := add(c, 'after_exception', 'also_added');
END;
$$ LANGUAGE plpgsql;

DO $$
DECLARE
  c collection('text');
BEGIN
  -- First call that succeeds
  CALL test_inout_exception(c, false);
  RAISE NOTICE 'Exception test (success): % items', count(c);
  
  -- Second call that fails - collection should remain unchanged
  BEGIN
    CALL test_inout_exception(c, true);
  EXCEPTION
    WHEN OTHERS THEN
      RAISE NOTICE 'Exception caught as expected';
  END;
  
  RAISE NOTICE 'Exception test (after failure): % items', count(c);
  
  c := first(c);
  WHILE NOT isnull(c) LOOP
    RAISE NOTICE 'Exception result: % = %', key(c), value(c);
    c := next(c);
  END LOOP;
END;
$$;

-- Test 11: INOUT with multiple parameters
CREATE OR REPLACE PROCEDURE test_inout_multiple(INOUT c1 collection, INOUT c2 collection, swap_data boolean)
AS $$
DECLARE
  temp_val text;
BEGIN
  c1 := add(c1, 'c1_key', 'from_c1');
  c2 := add(c2, 'c2_key', 'from_c2');
  
  IF swap_data THEN
    -- Cross-populate to test multiple INOUT handling
    temp_val := find(c1, 'c1_key');
    c2 := add(c2, 'swapped_from_c1', temp_val);
    
    temp_val := find(c2, 'c2_key');
    c1 := add(c1, 'swapped_from_c2', temp_val);
  END IF;
END;
$$ LANGUAGE plpgsql;

DO $$
DECLARE
  c1 collection('text');
  c2 collection('text');
BEGIN
  CALL test_inout_multiple(c1, c2, true);
  RAISE NOTICE 'Multiple INOUT test: c1 has % items, c2 has % items', count(c1), count(c2);
  
  RAISE NOTICE 'c1 contents:';
  c1 := first(c1);
  WHILE NOT isnull(c1) LOOP
    RAISE NOTICE '  % = %', key(c1), value(c1);
    c1 := next(c1);
  END LOOP;
  
  RAISE NOTICE 'c2 contents:';
  c2 := first(c2);
  WHILE NOT isnull(c2) LOOP
    RAISE NOTICE '  % = %', key(c2), value(c2);
    c2 := next(c2);
  END LOOP;
END;
$$;

-- Test 12: INOUT with recursive calls
CREATE OR REPLACE PROCEDURE test_inout_recursive(INOUT c collection, depth int)
AS $$
BEGIN
  c := add(c, 'depth_' || depth, 'level_' || depth);
  
  IF depth > 1 THEN
    CALL test_inout_recursive(c, depth - 1);
  END IF;
  
  c := add(c, 'return_' || depth, 'back_' || depth);
END;
$$ LANGUAGE plpgsql;

DO $$
DECLARE
  c collection('text');
BEGIN
  CALL test_inout_recursive(c, 3);
  RAISE NOTICE 'Recursive test: % items', count(c);
  
  c := first(c);
  WHILE NOT isnull(c) LOOP
    RAISE NOTICE 'Recursive result: % = %', key(c), value(c);
    c := next(c);
  END LOOP;
END;
$$;

-- Cleanup additional procedures
DROP PROCEDURE test_inout_nested_inner(INOUT collection, text);
DROP PROCEDURE test_inout_nested_outer(INOUT collection);
DROP PROCEDURE test_inout_operations(INOUT collection);
DROP PROCEDURE test_inout_large(INOUT collection, int);
DROP PROCEDURE test_inout_exception(INOUT collection, boolean);
DROP PROCEDURE test_inout_multiple(INOUT collection, INOUT collection, boolean);
DROP PROCEDURE test_inout_recursive(INOUT collection, int);
-- Test 13: INOUT stress test (regression test for double-free error)
CREATE OR REPLACE PROCEDURE test_inout_stress_regression(INOUT c collection) AS $$
BEGIN
  c := add(c, 'stress_key', 'stress_value');
END;
$$ LANGUAGE plpgsql;

DO $$
DECLARE
  c collection;
BEGIN
  c := add(c, 'initial', 'value');
  
  FOR i IN 1..50 LOOP
    CALL test_inout_stress_regression(c);
  END LOOP;
  RAISE NOTICE 'INOUT stress test completed: % items', count(c);
END
$$;

DROP PROCEDURE test_inout_stress_regression(collection);

-- Test uninitialized collections with INOUT parameters
CREATE OR REPLACE PROCEDURE test_uninitialized_inout(INOUT param_1 collection('int4'))
AS $$
BEGIN
END;
$$ LANGUAGE plpgsql;

DO $$
DECLARE
  var1 collection('int4');
BEGIN
  CALL test_uninitialized_inout(var1);
  CALL test_uninitialized_inout(var1);
  RAISE NOTICE 'Uninitialized INOUT test passed';
END $$;

DROP PROCEDURE test_uninitialized_inout(collection);

-- ============================================================
-- PART 2: icollection INOUT parameters
-- ============================================================

-- Test INOUT parameter functionality for icollection
-- Ensures icollection works correctly as INOUT parameters without crashes

-- Test 1: Basic INOUT parameter with single call
CREATE OR REPLACE PROCEDURE test_icollection_inout_basic(INOUT ic icollection)
AS $$
BEGIN
  ic := add(ic, 1, 'value1'::text);
END;
$$ LANGUAGE plpgsql;

DO $$
DECLARE
  ic icollection;
BEGIN
  CALL test_icollection_inout_basic(ic);
  RAISE NOTICE 'Basic INOUT test: % items', count(ic);
  RAISE NOTICE 'Value: %', find(ic, 1);
END;
$$;

-- Test 2: Multiple INOUT calls with data accumulation
CREATE OR REPLACE PROCEDURE test_icollection_inout_accumulate(INOUT ic icollection, key_val bigint, val int4)
AS $$
BEGIN
  ic := add(ic, key_val, val);
END;
$$ LANGUAGE plpgsql;

DO $$
DECLARE
  ic icollection;
BEGIN
  FOR i IN 1..5 LOOP
    CALL test_icollection_inout_accumulate(ic, i, i * 10);
    RAISE NOTICE 'Iteration %: % items', i, count(ic);
  END LOOP;
  
  -- Verify all values are present
  FOR i IN 1..5 LOOP
    RAISE NOTICE 'key %: %', i, find(ic, i);
  END LOOP;
END;
$$;

-- Test 3: INOUT with iteration after modification
CREATE OR REPLACE PROCEDURE test_icollection_inout_with_iteration(INOUT ic icollection)
AS $$
BEGIN
  ic := add(ic, 10, 'first'::text);
  ic := add(ic, 20, 'second'::text);
  ic := add(ic, 30, 'third'::text);
END;
$$ LANGUAGE plpgsql;

DO $$
DECLARE
  ic icollection;
BEGIN
  CALL test_icollection_inout_with_iteration(ic);
  
  -- Test iteration works correctly after INOUT modification
  ic := first(ic);
  WHILE NOT isnull(ic) LOOP
    RAISE NOTICE 'Iteration: % = %', key(ic), value(ic);
    ic := next(ic);
  END LOOP;
END;
$$;

-- Test 4: Complex INOUT scenario with delete operations
CREATE OR REPLACE PROCEDURE test_icollection_inout_complex(INOUT ic icollection, operation text, k bigint, v text)
AS $$
BEGIN
  IF operation = 'add' THEN
    ic := add(ic, k, v);
  ELSIF operation = 'delete' THEN
    ic := delete(ic, k);
  END IF;
END;
$$ LANGUAGE plpgsql;

DO $$
DECLARE
  ic icollection;
BEGIN
  -- Add several items
  CALL test_icollection_inout_complex(ic, 'add', 1, 'alpha');
  CALL test_icollection_inout_complex(ic, 'add', 2, 'beta');
  CALL test_icollection_inout_complex(ic, 'add', 3, 'gamma');
  RAISE NOTICE 'After adds: % items', count(ic);
  
  -- Delete one item
  CALL test_icollection_inout_complex(ic, 'delete', 2, '');
  RAISE NOTICE 'After delete: % items', count(ic);
  
  -- Verify remaining items
  ic := first(ic);
  WHILE NOT isnull(ic) LOOP
    RAISE NOTICE 'Remaining: % = %', key(ic), value(ic);
    ic := next(ic);
  END LOOP;
END;
$$;

-- Test 5: Stress test - many INOUT iterations
CREATE OR REPLACE PROCEDURE test_icollection_inout_stress(INOUT ic icollection, iter int)
AS $$
BEGIN
  ic := add(ic, iter, iter::text);
END;
$$ LANGUAGE plpgsql;

DO $$
DECLARE
  ic icollection;
BEGIN
  FOR i IN 1..100 LOOP
    CALL test_icollection_inout_stress(ic, i);
  END LOOP;
  RAISE NOTICE 'Stress test completed: % items', count(ic);
END;
$$;

-- Cleanup
DROP PROCEDURE test_icollection_inout_basic(INOUT icollection);
DROP PROCEDURE test_icollection_inout_accumulate(INOUT icollection, bigint, int4);
DROP PROCEDURE test_icollection_inout_with_iteration(INOUT icollection);
DROP PROCEDURE test_icollection_inout_complex(INOUT icollection, text, bigint, text);
DROP PROCEDURE test_icollection_inout_stress(INOUT icollection, int);

-- Test 6: INOUT with null collection
CREATE OR REPLACE PROCEDURE test_icollection_inout_null(INOUT ic icollection)
AS $$
BEGIN
  IF ic IS NULL THEN
    RAISE NOTICE 'Collection is null, creating new';
  END IF;
  ic := add(ic, 1, 'created'::text);
END;
$$ LANGUAGE plpgsql;

DO $$
DECLARE
  ic icollection('text');
BEGIN
  CALL test_icollection_inout_null(ic);
  RAISE NOTICE 'Null test result: % items', count(ic);
END;
$$;

DROP PROCEDURE test_icollection_inout_null(INOUT icollection);

-- Test 7: Nested INOUT calls
CREATE OR REPLACE PROCEDURE test_icollection_inout_nested_inner(INOUT ic icollection, val text)
AS $$
BEGIN
  ic := add(ic, 100, val);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE test_icollection_inout_nested_outer(INOUT ic icollection)
AS $$
BEGIN
  ic := add(ic, 1, 'start');
  CALL test_icollection_inout_nested_inner(ic, 'nested_value');
  ic := add(ic, 200, 'end');
END;
$$ LANGUAGE plpgsql;

DO $$
DECLARE
  ic icollection('text');
BEGIN
  CALL test_icollection_inout_nested_outer(ic);
  RAISE NOTICE 'Nested test: % items', count(ic);

  ic := first(ic);
  WHILE NOT isnull(ic) LOOP
    RAISE NOTICE 'Nested result: % = %', key(ic), value(ic);
    ic := next(ic);
  END LOOP;
END;
$$;

DROP PROCEDURE test_icollection_inout_nested_inner(INOUT icollection, text);
DROP PROCEDURE test_icollection_inout_nested_outer(INOUT icollection);

-- Test 8: INOUT with sort
CREATE OR REPLACE PROCEDURE test_icollection_inout_operations(INOUT ic icollection)
AS $$
BEGIN
  ic := add(ic, 30, 'should_be_last');
  ic := add(ic, 10, 'should_be_first');
  ic := add(ic, 20, 'should_be_middle');
  ic := sort(ic);
END;
$$ LANGUAGE plpgsql;

DO $$
DECLARE
  ic icollection('text');
BEGIN
  CALL test_icollection_inout_operations(ic);
  RAISE NOTICE 'Operations test: % items', count(ic);

  ic := first(ic);
  WHILE NOT isnull(ic) LOOP
    RAISE NOTICE 'Sorted: % = %', key(ic), value(ic);
    ic := next(ic);
  END LOOP;
END;
$$;

DROP PROCEDURE test_icollection_inout_operations(INOUT icollection);

-- Test 9: INOUT with exception handling
CREATE OR REPLACE PROCEDURE test_icollection_inout_exception(INOUT ic icollection, should_fail boolean)
AS $$
BEGIN
  ic := add(ic, 1, 'added');

  IF should_fail THEN
    RAISE EXCEPTION 'Intentional test exception';
  END IF;

  ic := add(ic, 2, 'also_added');
END;
$$ LANGUAGE plpgsql;

DO $$
DECLARE
  ic icollection('text');
BEGIN
  CALL test_icollection_inout_exception(ic, false);
  RAISE NOTICE 'Exception test (success): % items', count(ic);

  BEGIN
    CALL test_icollection_inout_exception(ic, true);
  EXCEPTION
    WHEN OTHERS THEN
      RAISE NOTICE 'Exception caught as expected';
  END;

  RAISE NOTICE 'Exception test (after failure): % items', count(ic);
END;
$$;

DROP PROCEDURE test_icollection_inout_exception(INOUT icollection, boolean);

-- Test 10: INOUT with recursive calls
CREATE OR REPLACE PROCEDURE test_icollection_inout_recursive(INOUT ic icollection, depth int)
AS $$
BEGIN
  ic := add(ic, depth, 'level_' || depth);

  IF depth > 1 THEN
    CALL test_icollection_inout_recursive(ic, depth - 1);
  END IF;

  ic := add(ic, depth + 100, 'back_' || depth);
END;
$$ LANGUAGE plpgsql;

DO $$
DECLARE
  ic icollection('text');
BEGIN
  CALL test_icollection_inout_recursive(ic, 3);
  RAISE NOTICE 'Recursive test: % items', count(ic);

  ic := first(ic);
  WHILE NOT isnull(ic) LOOP
    RAISE NOTICE 'Recursive result: % = %', key(ic), value(ic);
    ic := next(ic);
  END LOOP;
END;
$$;

DROP PROCEDURE test_icollection_inout_recursive(INOUT icollection, int);

-- Test 11: Uninitialized INOUT
CREATE OR REPLACE PROCEDURE test_icollection_uninit_inout(INOUT param_1 icollection('int4'))
AS $$
BEGIN
END;
$$ LANGUAGE plpgsql;

DO $$
DECLARE
  var1 icollection('int4');
BEGIN
  CALL test_icollection_uninit_inout(var1);
  CALL test_icollection_uninit_inout(var1);
  RAISE NOTICE 'Uninitialized INOUT test passed';
END $$;

DROP PROCEDURE test_icollection_uninit_inout(icollection);
