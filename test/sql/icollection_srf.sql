-- SRF tests for icollection (mirrors collection srf.sql)

DO $$
DECLARE
  ic   icollection('text');
  r    record;
BEGIN
  RAISE NOTICE 'SRF test 1';
  ic[1] := 'Hello World';
  ic[2] := 'Hello All';

  RAISE NOTICE '----------------';
  FOR r IN SELECT k FROM keys_to_table(ic) k
  LOOP
    RAISE NOTICE 'key: [%]', r.k;
  END LOOP;
END
$$;

DO $$
DECLARE
  ic   icollection('text');
  r    record;
BEGIN
  RAISE NOTICE 'SRF test 2';
  ic[1] := 'Hello World';
  ic[2] := 'Hello All';

  RAISE NOTICE '----------------';
  FOR r IN SELECT v FROM values_to_table(ic) v
  LOOP
    RAISE NOTICE 'value: [%]', r.v;
  END LOOP;
END
$$;

-- values_to_table with typed output (date)
DO $$
DECLARE
  ic   icollection('date');
  r    record;
BEGIN
  RAISE NOTICE 'SRF test 3';
  ic[1] := '1999-12-31'::date;
  ic[2] := '2000-01-01'::date;

  RAISE NOTICE '----------------';
  FOR r IN SELECT v FROM values_to_table(ic, null::date) v
  LOOP
    RAISE NOTICE 'value: [%]', r.v;
  END LOOP;
END
$$;

-- values_to_table with typed output (int)
DO $$
DECLARE
  ic   icollection('int');
  r    record;
BEGIN
  RAISE NOTICE 'SRF test 3b';
  ic[1] := 100;
  ic[2] := 222;

  RAISE NOTICE '----------------';
  FOR r IN SELECT v FROM values_to_table(ic, null::int) v
  LOOP
    RAISE NOTICE 'value: [%]', r.v;
  END LOOP;
END
$$;

-- to_table text output
DO $$
DECLARE
  ic   icollection('text');
  r    record;
BEGIN
  RAISE NOTICE 'SRF test 4';
  ic[1] := 'Hello World';
  ic[2] := 'Hello All';

  RAISE NOTICE '----------------';
  FOR r IN SELECT * FROM to_table(ic) v
  LOOP
    RAISE NOTICE 'key: [%] value: [%]', r.key, r.value;
  END LOOP;
END
$$;

-- to_table typed output (date)
DO $$
DECLARE
  ic   icollection('date');
  r    record;
BEGIN
  RAISE NOTICE 'SRF test 5';
  ic[1] := '1999-12-31'::date;
  ic[2] := '2000-01-01'::date;

  RAISE NOTICE '----------------';
  FOR r IN SELECT * FROM to_table(ic, null::date) v
  LOOP
    RAISE NOTICE 'key: [%] value: [%]', r.key, r.value;
  END LOOP;
END
$$;

-- to_table with NULL values
DO $$
DECLARE
  ic   icollection('date');
  r    record;
BEGIN
  RAISE NOTICE 'SRF test 8';
  ic[1] := '1999-12-31'::date;
  ic[2] := null;
  ic[3] := '2000-01-01'::date;

  RAISE NOTICE '----------------';
  FOR r IN SELECT * FROM to_table(ic, null::date) v
  LOOP
    RAISE NOTICE 'key: [%] value: [%]', r.key, r.value;
  END LOOP;
END
$$;

-- SRF on empty icollection
DO $$
DECLARE
  ic icollection;
  cnt int := 0;
  r record;
BEGIN
  RAISE NOTICE 'ic SRF test - empty icollection';
  ic := add(ic, 1, 'val');
  ic := delete(ic, 1);

  FOR r IN SELECT k FROM keys_to_table(ic) k LOOP cnt := cnt + 1; END LOOP;
  ASSERT cnt = 0, 'ic keys_to_table on empty should return 0 rows';

  FOR r IN SELECT v FROM values_to_table(ic) v LOOP cnt := cnt + 1; END LOOP;
  ASSERT cnt = 0, 'ic values_to_table on empty should return 0 rows';

  FOR r IN SELECT * FROM to_table(ic) LOOP cnt := cnt + 1; END LOOP;
  ASSERT cnt = 0, 'ic to_table on empty should return 0 rows';
END $$;

-- SRF with NULL values
DO $$
DECLARE
  ic icollection;
  r record;
BEGIN
  RAISE NOTICE 'ic SRF test - NULL values';
  ic := add(ic, 1, 'real');
  ic := add(ic, 2, null::text);
  ic := add(ic, 3, 'also real');

  RAISE NOTICE '----------------';
  FOR r IN SELECT v FROM values_to_table(ic) v
  LOOP
    RAISE NOTICE 'value: [%]', r.v;
  END LOOP;
END $$;
