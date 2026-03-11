--
-- iteration.sql
--     Iterator movement (first/last/next/prev), key/value access,
--     key navigation (first_key/last_key/next_key/prev_key),
--     boundary conditions, sort-then-iterate, and loop termination.
--     Covers both collection (text-keyed) and icollection (int-keyed).
--

-- ============================================================
-- PART 1: collection iteration
-- ============================================================

DO $$
DECLARE
  u   collection('text');
BEGIN
  RAISE NOTICE 'Iteration test 1';
  u['aaa'] := 'Hello World';
  u['bbb'] := 'Hello All';
  u['ccc'] := 'Hi';

  RAISE NOTICE 'value: %', value(u);

  u := next(u);
  RAISE NOTICE 'value: %', value(u);
END
$$;

DO $$
DECLARE
  u   collection('text');
BEGIN
  RAISE NOTICE 'Iteration test 3';
  u['aaa'] := 'Hello World';
  u['bbb'] := 'Hello All';
  u['ccc'] := 'Hi';

  u := next(u);
  u := next(u);
  u := prev(u);
  RAISE NOTICE 'value: %', value(u);
END
$$;

DO $$
DECLARE
  u   collection('text');
BEGIN
  RAISE NOTICE 'Iteration test 4';
  u['aaa'] := 'Hello World';
  u['bbb'] := 'Hello All';
  u['ccc'] := 'Hi';

  u := next(u);
  u := next(u);
  u := first(u);
  RAISE NOTICE 'value: %', value(u);
END
$$;

DO $$
DECLARE
  u   collection('text');
BEGIN
  RAISE NOTICE 'Iteration test 5';
  u['aaa'] := 'Hello World';

  RAISE NOTICE 'isnull: %', isnull(u);
  u := next(u);
  RAISE NOTICE 'isnull: %', isnull(u);
END
$$;

DO $$
DECLARE
  u   collection('text');
BEGIN
  RAISE NOTICE 'Iteration test 6';
  u['aaa'] := 'Hello World';
  u['bbb'] := 'Hello All';
  u['ccc'] := 'Hi';

  u := first(u);
  WHILE NOT isnull(u) LOOP
    RAISE NOTICE 'value: %', value(u);
    u := next(u);
  END LOOP;
END
$$;

DO $$
DECLARE
  u   collection('text');
BEGIN
  RAISE NOTICE 'Iteration test 7';
  u['aaa'] := 'Hello World';
  u['bbb'] := 'Hello All';
  u['ccc'] := 'Hi';

  u := first(u);
  WHILE NOT isnull(u) LOOP
    RAISE NOTICE 'value: %', value(u);
    u := next(u);
  END LOOP;

  RAISE NOTICE 'value: %', u['bbb'];
END
$$;

DO $$
DECLARE
  u   collection('text');
BEGIN
  RAISE NOTICE 'Iteration test 8';
  u['aaa'] := 'Hello World';
  u['bbb'] := 'Hello All';
  u['ccc'] := 'Hi';

  u := delete(u, 'bbb');

  u := first(u);
  WHILE NOT isnull(u) LOOP
    RAISE NOTICE 'value: %', value(u);
    u := next(u);
  END LOOP;
END
$$;

DO $$
DECLARE
  u   collection('text');
BEGIN
  RAISE NOTICE 'Iteration test 9';
  u['aaa'] := 'Hello World';
  u['bbb'] := 'Hello All';
  u['ccc'] := 'Hi';

  u := delete(u, 'aaa');

  u := first(u);
  WHILE NOT isnull(u) LOOP
    RAISE NOTICE 'value: %', value(u);
    u := next(u);
  END LOOP;
END
$$;

DO $$
DECLARE
  u   collection('text');
  t   text;
BEGIN
  RAISE NOTICE 'Iteration test 10';
  u['ccc'] := '3';
  u['bbb'] := '2';
  u['eee'] := '5';
  u['ddd'] := '4';
  u['aaa'] := '1';

  u := sort(u);
  WHILE NOT isnull(u) LOOP
    RAISE NOTICE 'value: %', value(u);
    u := next(u);
  END LOOP;
END
$$;

DO $$
DECLARE
  u   collection('text');
BEGIN
  RAISE NOTICE 'Iteration test 11';
  u['aaa'] := 'Hello World';
  u['bbb'] := 'Hello All';

  u := next(u);
  RAISE NOTICE 'value: %', value(u);
  u := next(u);
  RAISE NOTICE 'value: %', value(u);
  u := next(u);
  RAISE NOTICE 'value: %', value(u);
END
$$;

DO $$
DECLARE
  u   collection('text');
BEGIN
  RAISE NOTICE 'Iteration test 12';

  u := first(u);
  RAISE NOTICE 'value: %', value(u);
  u := next(u);
  RAISE NOTICE 'value: %', value(u);
END
$$;

DO $$
DECLARE
  u   collection('text');
BEGIN
  RAISE NOTICE 'Iteration test 13';

  u := prev(u);
  RAISE NOTICE 'value: %', value(u);
END
$$;

DO $$
DECLARE
  u   collection('text');
BEGIN
  RAISE NOTICE 'Iteration test 14';
  u['aaa'] := 'Hello World';
  u['bbb'] := 'Hello All';
  u['ccc'] := 'Hi';

  u := next(u);
  u := next(u);
  RAISE NOTICE 'find after next: %', find(u, 'aaa');
END
$$;

DO $$
DECLARE
  u   collection COLLATE "en_US";
  v   collection COLLATE "C";
BEGIN
  RAISE NOTICE 'Iteration test 15';
  u['a'] := '1'::text;
  u['B'] := '2'::text;
  u['c'] := '3'::text;
  v := copy(u);

  u := sort(u);
  WHILE NOT isnull(u) LOOP
    RAISE NOTICE 'u value: %', value(u);
    u := next(u);
  END LOOP;

  v := sort(v);
  WHILE NOT isnull(v) LOOP
    RAISE NOTICE 'v value: %', value(v);
    v := next(v);
  END LOOP;
END
$$;

DO $$
DECLARE
  u   collection('text');
BEGIN
  RAISE NOTICE 'Iteration test 16';
  u['aaa'] := 'Hello World';

  u := first(u);
  u := prev(u);
  RAISE NOTICE 'value: %', value(u);
END
$$;

DO
$$
DECLARE
  a collection;
BEGIN
  RAISE NOTICE 'Iteration test 17';
  FOR i IN 1..1000 LOOP
    a[i::text] := 'abc';
  END LOOP;
RAISE NOTICE 'Size of collection is %', length(a::text);
END;
$$;

DO $$
DECLARE
  u   collection('text');
BEGIN
  RAISE NOTICE 'Iteration test 18';
  u := add(u, 'aaa', 'Hello World'::text);
  u := add(u, 'bbb', 'Hello All'::text);
  u := add(u, 'ccc', 'Hi'::text);

  RAISE NOTICE 'value: %', value(u);

  u := last(u);
  RAISE NOTICE 'value: %', value(u);
END
$$;

DO $$
DECLARE
  u   collection('text');
BEGIN
  RAISE NOTICE 'Iteration test 19';
  u['aaa'] := 'Hello World';
  u['bbb'] := 'Hello All';
  u['ccc'] := 'Hi';

  RAISE NOTICE 'value: %', value(u);

  u := last(u);
  RAISE NOTICE 'value: %', value(u);
END
$$;

DO $$
DECLARE
  u   collection('text');
BEGIN
  RAISE NOTICE 'Iteration test 20';
  u['aaa'] := 'Hello World';
  u['bbb'] := 'Hello All';
  u['ccc'] := 'Hi';

  u := last(u);
  RAISE NOTICE 'value: %', value(u);
  u := prev(u);
  RAISE NOTICE 'value: %', value(u);
END
$$;

DO $$
DECLARE
  u   collection('text');
BEGIN
  RAISE NOTICE 'Iteration test 21';
  u['aaa'] := 'Hello World';
  u['bbb'] := 'Hello All';
  u['ccc'] := 'Hi';

  u := last(u);
  WHILE NOT isnull(u) LOOP
    RAISE NOTICE 'value: %', value(u);
    u := prev(u);
  END LOOP;
END
$$;

DO $$
DECLARE
  u   collection('text');
BEGIN
  RAISE NOTICE 'Iteration test 22';
  u['aaa'] := 'Hello World';
  u['bbb'] := 'Hello All';
  u['ccc'] := 'Hi';

  u := delete(u, 'ccc');
  u := last(u);
  RAISE NOTICE 'value: %', value(u);
END
$$;

DO $$
DECLARE
  u   collection('text');
BEGIN
  RAISE NOTICE 'Iteration test 23';
  u['ccc'] := 'Hi';

  u := delete(u, 'ccc');
  u := last(u);
  RAISE NOTICE 'value: %', value(u);
END
$$;

DO $$
DECLARE
  u   collection('text');
  t   text;
BEGIN
  RAISE NOTICE 'Iteration test 24';
  u['ccc'] := '3';
  u['bbb'] := '2';
  u['eee'] := '5';
  u['ddd'] := '4';
  u['aaa'] := '1';

  u := last(u);
  RAISE NOTICE 'value: %', value(u);

  u := sort(u);

  u := last(u);
  RAISE NOTICE 'value: %', value(u);
END
$$;

DO $$
DECLARE
  u   collection('text');
BEGIN
  RAISE NOTICE 'Iteration test 25';
  u := add(u, 'aaa', 'Hello World');
  u := add(u, 'bbb', 'Hello All');
  u := add(u, 'ccc', 'Hi');
  RAISE NOTICE 'next_key(bbb): %', next_key(u, 'bbb');
  RAISE NOTICE 'next_key(ccc): %', next_key(u, 'ccc');
END
$$;

DO $$
DECLARE
  u   collection('text');
BEGIN
  RAISE NOTICE 'Iteration test 26';
  u := add(u, 'aaa', 'Hello World');
  u := add(u, 'bbb', 'Hello All');
  u := add(u, 'ccc', 'Hi');
  RAISE NOTICE 'prev_key(bbb): %', prev_key(u, 'bbb');
  RAISE NOTICE 'prev_key(aaa): %', prev_key(u, 'aaa');
END
$$;

DO $$
DECLARE
  u   collection('text');
BEGIN
  RAISE NOTICE 'Iteration test 27';
  u := add(u, 'aaa', 'Hello World');
  u := add(u, 'bbb', 'Hello All');
  u := add(u, 'ccc', 'Hi');
  RAISE NOTICE 'first_key: %', first_key(u);
END
$$;

DO $$
DECLARE
  u   collection('text');
BEGIN
  RAISE NOTICE 'Iteration test 28';
  u := add(u, 'aaa', 'Hello World');
  u := add(u, 'bbb', 'Hello All');
  u := add(u, 'ccc', 'Hi');
  RAISE NOTICE 'last_key: %', last_key(u);
END
$$;

DO $$
DECLARE
  c1 collection('text');
  c2 collection('text') DEFAULT '{"value_type": "text", "entries": {}}'::collection;
  c3 collection('text');
BEGIN
  RAISE NOTICE 'Iteration test 29';

  -- Uninitialized collection
  RAISE NOTICE 'isnull(c1): %', isnull(c1);

  -- Empty collection
  RAISE NOTICE 'isnull(c2): %', isnull(c2);

  -- Non-empty collection
  c3 := add(c3, 'A', 'Hello World');
  RAISE NOTICE 'isnull(c3): %', isnull(c3);
END
$$;

-- Test WHILE loop termination to prevent infinite loop regression
DO $$
DECLARE
  u   collection('text');
  counter int := 0;
BEGIN
  RAISE NOTICE 'WHILE loop termination test';
  u['aaa'] := 'Hello World';
  u['bbb'] := 'Hello All';
  u['ccc'] := 'Hi';

  u := first(u);
  WHILE NOT isnull(u) LOOP
    counter := counter + 1;
    RAISE NOTICE 'Loop iteration %: %', counter, value(u);
    u := next(u);
    -- Safety check to prevent infinite loop in case of regression
    IF counter > 10 THEN
      RAISE EXCEPTION 'WHILE loop did not terminate - infinite loop detected';
    END IF;
  END LOOP;
  RAISE NOTICE 'WHILE loop completed after % iterations', counter;
END
$$;
-- Test iteration advancement (regression test for PostgreSQL 18 bug)
DO $$
DECLARE
  c collection;
BEGIN
  c['aaa'] := 'first';
  c['bbb'] := 'second';
  c['ccc'] := 'third';
  
  c := first(c);
  RAISE NOTICE 'Iteration advancement - first: %', key(c);
  
  c := next(c);
  RAISE NOTICE 'Iteration advancement - next: %', key(c);
  
  c := next(c);
  RAISE NOTICE 'Iteration advancement - next again: %', key(c);
  
  c := next(c);
  RAISE NOTICE 'Iteration advancement - next (null): %', COALESCE(key(c), 'NULL');
END
$$;

-- next_key/prev_key boundary tests
DO $$
DECLARE
  c collection;
  v text;
  ok boolean;
BEGIN
  c := add(c, 'a', '1');
  c := add(c, 'b', '2');
  c := add(c, 'c', '3');

  -- next_key on last key returns NULL
  ASSERT next_key(c, 'c') IS NULL, 'next_key on last should be null';

  -- prev_key on first key returns NULL
  ASSERT prev_key(c, 'a') IS NULL, 'prev_key on first should be null';

  -- next_key/prev_key on nonexistent key errors
  ok := false;
  BEGIN
    v := next_key(c, 'zzz');
  EXCEPTION WHEN no_data_found THEN
    ok := true;
  END;
  ASSERT ok, 'next_key on missing key should error';

  ok := false;
  BEGIN
    v := prev_key(c, 'zzz');
  EXCEPTION WHEN no_data_found THEN
    ok := true;
  END;
  ASSERT ok, 'prev_key on missing key should error';
END $$;

-- ============================================================
-- PART 2: icollection iteration
-- ============================================================

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

-- next_key/prev_key boundary tests
DO $$
DECLARE
  ic icollection;
  v bigint;
  ok boolean;
BEGIN
  ic := add(ic, 1, 'a');
  ic := add(ic, 2, 'b');
  ic := add(ic, 3, 'c');

  ASSERT next_key(ic, 3) IS NULL, 'ic next_key on last should be null';
  ASSERT prev_key(ic, 1) IS NULL, 'ic prev_key on first should be null';

  ok := false;
  BEGIN
    v := next_key(ic, 999);
  EXCEPTION WHEN no_data_found THEN
    ok := true;
  END;
  ASSERT ok, 'ic next_key on missing key should error';

  ok := false;
  BEGIN
    v := prev_key(ic, 999);
  EXCEPTION WHEN no_data_found THEN
    ok := true;
  END;
  ASSERT ok, 'ic prev_key on missing key should error';
END $$;


-- ============================================================
-- Iteration after delete() with no args and re-add
-- ============================================================
DO
$$
DECLARE
  c collection;
BEGIN
  c['a'] := '1'; c['b'] := '2';
  c := delete(c);
  c['x'] := '10'; c['y'] := '20'; c['z'] := '30';
  c := first(c);
  ASSERT NOT isnull(c), 'iterator valid after re-add';
  ASSERT key(c) = 'x', 'first key after re-add';
  c := sort(c);
  ASSERT key(c) = 'x', 'sorted first key';
  c := next(c);
  ASSERT key(c) = 'y', 'sorted second key';
  c := next(c);
  ASSERT key(c) = 'z', 'sorted third key';
END;
$$;
