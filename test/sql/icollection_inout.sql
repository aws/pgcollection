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
