-- Iteration tests for icollection (mirrors collection iteration.sql)

DO $$
DECLARE
  ic   icollection('text');
BEGIN
  RAISE NOTICE 'Iteration test 1';
  ic[1] := 'Hello World';
  ic[2] := 'Hello All';
  ic[3] := 'Hi';

  RAISE NOTICE 'value: %', value(ic);

  ic := next(ic);
  RAISE NOTICE 'value: %', value(ic);
END
$$;

DO $$
DECLARE
  ic   icollection('text');
BEGIN
  RAISE NOTICE 'Iteration test 3';
  ic[1] := 'Hello World';
  ic[2] := 'Hello All';
  ic[3] := 'Hi';

  ic := next(ic);
  ic := next(ic);
  ic := prev(ic);
  RAISE NOTICE 'value: %', value(ic);
END
$$;

DO $$
DECLARE
  ic   icollection('text');
BEGIN
  RAISE NOTICE 'Iteration test 4';
  ic[1] := 'Hello World';
  ic[2] := 'Hello All';
  ic[3] := 'Hi';

  ic := next(ic);
  ic := next(ic);
  ic := first(ic);
  RAISE NOTICE 'value: %', value(ic);
END
$$;

DO $$
DECLARE
  ic   icollection('text');
BEGIN
  RAISE NOTICE 'Iteration test 5';
  ic[1] := 'Hello World';

  RAISE NOTICE 'isnull: %', isnull(ic);
  ic := next(ic);
  RAISE NOTICE 'isnull: %', isnull(ic);
END
$$;

DO $$
DECLARE
  ic   icollection('text');
BEGIN
  RAISE NOTICE 'Iteration test 6';
  ic[1] := 'Hello World';
  ic[2] := 'Hello All';
  ic[3] := 'Hi';

  ic := first(ic);
  WHILE NOT isnull(ic) LOOP
    RAISE NOTICE 'value: %', value(ic);
    ic := next(ic);
  END LOOP;
END
$$;

-- Iterate then fetch by subscript
DO $$
DECLARE
  ic   icollection('text');
BEGIN
  RAISE NOTICE 'Iteration test 7';
  ic[1] := 'Hello World';
  ic[2] := 'Hello All';
  ic[3] := 'Hi';

  ic := first(ic);
  WHILE NOT isnull(ic) LOOP
    RAISE NOTICE 'value: %', value(ic);
    ic := next(ic);
  END LOOP;

  RAISE NOTICE 'value: %', ic[2];
END
$$;

-- Iterate after delete middle
DO $$
DECLARE
  ic   icollection('text');
BEGIN
  RAISE NOTICE 'Iteration test 8';
  ic[1] := 'Hello World';
  ic[2] := 'Hello All';
  ic[3] := 'Hi';

  ic := delete(ic, 2);

  ic := first(ic);
  WHILE NOT isnull(ic) LOOP
    RAISE NOTICE 'value: %', value(ic);
    ic := next(ic);
  END LOOP;
END
$$;

-- Iterate after delete first
DO $$
DECLARE
  ic   icollection('text');
BEGIN
  RAISE NOTICE 'Iteration test 9';
  ic[1] := 'Hello World';
  ic[2] := 'Hello All';
  ic[3] := 'Hi';

  ic := delete(ic, 1);

  ic := first(ic);
  WHILE NOT isnull(ic) LOOP
    RAISE NOTICE 'value: %', value(ic);
    ic := next(ic);
  END LOOP;
END
$$;

-- Sort then iterate
DO $$
DECLARE
  ic   icollection('text');
BEGIN
  RAISE NOTICE 'Iteration test 10';
  ic[3] := '3';
  ic[2] := '2';
  ic[5] := '5';
  ic[4] := '4';
  ic[1] := '1';

  ic := sort(ic);
  WHILE NOT isnull(ic) LOOP
    RAISE NOTICE 'value: %', value(ic);
    ic := next(ic);
  END LOOP;
END
$$;

-- next past end wraps to null
DO $$
DECLARE
  ic   icollection('text');
BEGIN
  RAISE NOTICE 'Iteration test 11';
  ic[1] := 'Hello World';
  ic[2] := 'Hello All';

  ic := next(ic);
  RAISE NOTICE 'value: %', value(ic);
  ic := next(ic);
  RAISE NOTICE 'value: %', value(ic);
  ic := next(ic);
  RAISE NOTICE 'value: %', value(ic);
END
$$;

-- first/next on uninitialized
DO $$
DECLARE
  ic   icollection('text');
BEGIN
  RAISE NOTICE 'Iteration test 12';

  ic := first(ic);
  RAISE NOTICE 'value: %', value(ic);
  ic := next(ic);
  RAISE NOTICE 'value: %', value(ic);
END
$$;

-- prev on uninitialized
DO $$
DECLARE
  ic   icollection('text');
BEGIN
  RAISE NOTICE 'Iteration test 13';

  ic := prev(ic);
  RAISE NOTICE 'value: %', value(ic);
END
$$;

-- find doesn't change iterator position
DO $$
DECLARE
  ic   icollection('text');
BEGIN
  RAISE NOTICE 'Iteration test 14';
  ic[1] := 'Hello World';
  ic[2] := 'Hello All';
  ic[3] := 'Hi';

  ic := next(ic);
  ic := next(ic);
  RAISE NOTICE 'find after next: %', find(ic, 1);
END
$$;

-- prev from first gives null
DO $$
DECLARE
  ic   icollection('text');
BEGIN
  RAISE NOTICE 'Iteration test 16';
  ic[1] := 'Hello World';

  ic := first(ic);
  ic := prev(ic);
  RAISE NOTICE 'value: %', value(ic);
END
$$;

-- last() basic
DO $$
DECLARE
  ic   icollection('text');
BEGIN
  RAISE NOTICE 'Iteration test 18';
  ic := add(ic, 1, 'Hello World'::text);
  ic := add(ic, 2, 'Hello All'::text);
  ic := add(ic, 3, 'Hi'::text);

  RAISE NOTICE 'value: %', value(ic);

  ic := last(ic);
  RAISE NOTICE 'value: %', value(ic);
END
$$;

-- last() with subscript
DO $$
DECLARE
  ic   icollection('text');
BEGIN
  RAISE NOTICE 'Iteration test 19';
  ic[1] := 'Hello World';
  ic[2] := 'Hello All';
  ic[3] := 'Hi';

  RAISE NOTICE 'value: %', value(ic);

  ic := last(ic);
  RAISE NOTICE 'value: %', value(ic);
END
$$;

-- last then prev
DO $$
DECLARE
  ic   icollection('text');
BEGIN
  RAISE NOTICE 'Iteration test 20';
  ic[1] := 'Hello World';
  ic[2] := 'Hello All';
  ic[3] := 'Hi';

  ic := last(ic);
  RAISE NOTICE 'value: %', value(ic);
  ic := prev(ic);
  RAISE NOTICE 'value: %', value(ic);
END
$$;

-- reverse iterate with last/prev
DO $$
DECLARE
  ic   icollection('text');
BEGIN
  RAISE NOTICE 'Iteration test 21';
  ic[1] := 'Hello World';
  ic[2] := 'Hello All';
  ic[3] := 'Hi';

  ic := last(ic);
  WHILE NOT isnull(ic) LOOP
    RAISE NOTICE 'value: %', value(ic);
    ic := prev(ic);
  END LOOP;
END
$$;

-- last after delete last element
DO $$
DECLARE
  ic   icollection('text');
BEGIN
  RAISE NOTICE 'Iteration test 22';
  ic[1] := 'Hello World';
  ic[2] := 'Hello All';
  ic[3] := 'Hi';

  ic := delete(ic, 3);
  ic := last(ic);
  RAISE NOTICE 'value: %', value(ic);
END
$$;

-- last after delete only element
DO $$
DECLARE
  ic   icollection('text');
BEGIN
  RAISE NOTICE 'Iteration test 23';
  ic[1] := 'Hi';

  ic := delete(ic, 1);
  ic := last(ic);
  RAISE NOTICE 'value: %', value(ic);
END
$$;

-- last before and after sort
DO $$
DECLARE
  ic   icollection('text');
BEGIN
  RAISE NOTICE 'Iteration test 24';
  ic[3] := '3';
  ic[2] := '2';
  ic[5] := '5';
  ic[4] := '4';
  ic[1] := '1';

  ic := last(ic);
  RAISE NOTICE 'value: %', value(ic);

  ic := sort(ic);

  ic := last(ic);
  RAISE NOTICE 'value: %', value(ic);
END
$$;

-- next_key
DO $$
DECLARE
  ic   icollection('text');
BEGIN
  RAISE NOTICE 'Iteration test 25';
  ic := add(ic, 1, 'Hello World');
  ic := add(ic, 2, 'Hello All');
  ic := add(ic, 3, 'Hi');
  RAISE NOTICE 'next_key(2): %', next_key(ic, 2);
  RAISE NOTICE 'next_key(3): %', next_key(ic, 3);
END
$$;

-- prev_key
DO $$
DECLARE
  ic   icollection('text');
BEGIN
  RAISE NOTICE 'Iteration test 26';
  ic := add(ic, 1, 'Hello World');
  ic := add(ic, 2, 'Hello All');
  ic := add(ic, 3, 'Hi');
  RAISE NOTICE 'prev_key(2): %', prev_key(ic, 2);
  RAISE NOTICE 'prev_key(1): %', prev_key(ic, 1);
END
$$;

-- first_key
DO $$
DECLARE
  ic   icollection('text');
BEGIN
  RAISE NOTICE 'Iteration test 27';
  ic := add(ic, 1, 'Hello World');
  ic := add(ic, 2, 'Hello All');
  ic := add(ic, 3, 'Hi');
  RAISE NOTICE 'first_key: %', first_key(ic);
END
$$;

-- last_key
DO $$
DECLARE
  ic   icollection('text');
BEGIN
  RAISE NOTICE 'Iteration test 28';
  ic := add(ic, 1, 'Hello World');
  ic := add(ic, 2, 'Hello All');
  ic := add(ic, 3, 'Hi');
  RAISE NOTICE 'last_key: %', last_key(ic);
END
$$;

-- isnull on uninitialized, empty, non-empty
DO $$
DECLARE
  c1 icollection('text');
  c2 icollection('text') DEFAULT '{"value_type": "text", "entries": {}}'::icollection;
  c3 icollection('text');
BEGIN
  RAISE NOTICE 'Iteration test 29';

  RAISE NOTICE 'isnull(c1): %', isnull(c1);
  RAISE NOTICE 'isnull(c2): %', isnull(c2);

  c3 := add(c3, 1, 'Hello World');
  RAISE NOTICE 'isnull(c3): %', isnull(c3);
END
$$;

-- WHILE loop termination safety
DO $$
DECLARE
  ic   icollection('text');
  counter int := 0;
BEGIN
  RAISE NOTICE 'WHILE loop termination test';
  ic[1] := 'Hello World';
  ic[2] := 'Hello All';
  ic[3] := 'Hi';

  ic := first(ic);
  WHILE NOT isnull(ic) LOOP
    counter := counter + 1;
    RAISE NOTICE 'Loop iteration %: %', counter, value(ic);
    ic := next(ic);
    IF counter > 10 THEN
      RAISE EXCEPTION 'WHILE loop did not terminate - infinite loop detected';
    END IF;
  END LOOP;
  RAISE NOTICE 'WHILE loop completed after % iterations', counter;
END
$$;

-- Iteration advancement regression test
DO $$
DECLARE
  ic icollection;
BEGIN
  ic[1] := 'first';
  ic[2] := 'second';
  ic[3] := 'third';

  ic := first(ic);
  RAISE NOTICE 'Iteration advancement - first: %', key(ic);

  ic := next(ic);
  RAISE NOTICE 'Iteration advancement - next: %', key(ic);

  ic := next(ic);
  RAISE NOTICE 'Iteration advancement - next again: %', key(ic);

  ic := next(ic);
  RAISE NOTICE 'Iteration advancement - next (null): %', COALESCE(key(ic)::text, 'NULL');
END
$$;

-- Large collection iteration
DO
$$
DECLARE
  ic icollection;
BEGIN
  RAISE NOTICE 'Iteration test 17';
  FOR i IN 1..1000 LOOP
    ic[i] := 'abc';
  END LOOP;
  RAISE NOTICE 'Size of icollection is %', length(ic::text);
END;
$$;
