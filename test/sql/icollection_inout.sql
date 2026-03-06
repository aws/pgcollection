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
