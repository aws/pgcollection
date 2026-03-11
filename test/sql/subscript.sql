--
-- subscript.sql
--     Subscript fetch, assign, type coercion, NULL key handling,
--     and function/subscript parity verification.
--     Covers both collection (text-keyed) and icollection (int-keyed).
--

-- ============================================================
-- PART 1: collection subscript operations
-- ============================================================

DO $$
DECLARE
  u   collection('text');
BEGIN
  RAISE NOTICE 'Subscript test 1';
  u['aaa'] := 'Hello World';
  u['bbb'] := 'Hello All';
  u['ccc'] := 'Hi';
  RAISE NOTICE 'count: %', count(u);
END
$$;

DO $$
DECLARE
  u   collection('text');
BEGIN
  RAISE NOTICE 'Subscript test 2';
  u['aaa'] := 'Hello World';
  u['bbb'] := 'Hello All';
  u['ccc'] := 'Hi';

  RAISE NOTICE 'value: %', u['bbb'];
END
$$;

DO $$
DECLARE
  u   collection('text');
BEGIN
  RAISE NOTICE 'Subscript test 3';
  u['aaa'] := 'Hello World';
  u['aaa'] := 'Hello All';

  RAISE NOTICE 'count: %', count(u);
  RAISE NOTICE 'value: %', u['aaa'];
END
$$;

DO $$
DECLARE
  u   collection('text');
BEGIN
  RAISE NOTICE 'Subscript test 4';
  u['aaa'] := 'Hello World';
  u['bbb'] := 'Hello All';
  u['ccc'] := 'Hi';

  RAISE NOTICE 'value: %', u[null];
END
$$;

DO $$
DECLARE
  u   collection('date');
BEGIN
  RAISE NOTICE 'Subscript test 5';
  u['aaa'] := '1999-12-31'::date;

  RAISE NOTICE 'value: %', value(u, null::date);
END
$$;

DO $$
DECLARE
  u   collection('date');
BEGIN
  RAISE NOTICE 'Subscript test 6';
  u['aaa'] := '1999-12-31'::date;

  RAISE NOTICE 'value: %', u[null];
END
$$;

DO $$
DECLARE
  u   collection('text');
BEGIN
  RAISE NOTICE 'Subscript test 7';
  u['aaa'] := 'Hello World';
  u['bbb'] := 'Hello All';
  u['ccc'] := 'Hi';

  RAISE NOTICE 'value: %', u['ddd'];
END
$$;

DO
$$
DECLARE
  r       pg_class%ROWTYPE;
  c       collection('pg_class');
BEGIN
  RAISE NOTICE 'Subscript test 8';
  FOR r IN SELECT pg_class.* 
             FROM pg_class
            WHERE relname = 'pg_type'
            LIMIT 1
  LOOP
    c[r.relname] = r;
  END LOOP;

  RAISE NOTICE 'Collection size: %', count(c);
  RAISE NOTICE 'Key: %', key(c);
  RAISE NOTICE 'Schema: %', c['pg_type'].relnamespace::regnamespace;
END
$$;

DO $$
DECLARE
  u   collection('text');
BEGIN
  RAISE NOTICE 'Subscript test 9';
  u[repeat('a', 256)] := 'Hello World';
  RAISE NOTICE 'count: %', count(u);
END
$$;

DO $$
DECLARE
  u   collection('text');
BEGIN
  RAISE NOTICE 'Subscript test 10';
  u := add(u, 'x1', 'Hello World'::text);
  u := add(u, 'y3', '12-31-1999'::date);
  RAISE NOTICE 'count: %', count(u);
END
$$;

DO
$$
DECLARE
  parent    collection('collection');
  child1    collection('text');
  child2    collection('text');
BEGIN
  RAISE NOTICE 'Subscript test 11';

  child1['aaa'] := 'Hello World';
  child1['bbb'] := 'Hello All';

  child2['AAA'] := 'Hallo Welt';
  child2['BBB'] := 'Hola Mundo';

  parent['child1'] := child1;
  parent['child2'] := child2;

  RAISE NOTICE 'Parent: %', parent;
END
$$;

DO
$$
DECLARE
t collection;
BEGIN
  RAISE NOTICE 'Subscript test 12';

  RAISE NOTICE 'The current val is %', t['2'];
END
$$;

DO
$$
DECLARE
  t  collection;
BEGIN
  RAISE NOTICE 'Subscript test 13';

  t['1'] := 111::bigint;
  t['2'] := 222::bigint;
  RAISE NOTICE 'The type is %', value_type(t);
END
$$;


DO
$$
DECLARE
  t  collection;
BEGIN
  RAISE NOTICE 'Subscript test 14';

  t := add(t, '1', 111::bigint);
  t['2'] := 'abc';
END
$$;

DO
$$
DECLARE
  t collection('bigint');
  x collection('bigint');
BEGIN
  RAISE NOTICE 'Subscript test 15';
  t['1'] := 1;
  t['2'] := 2;
  t['111'] := 11;

  RAISE NOTICE 'The current val of t is %', t;

  x := (t::text)::collection('bigint');
  RAISE NOTICE 'The current val of x is %', x;
  RAISE NOTICE 'The current val of t[2] is %', t['2'];

  RAISE NOTICE 'The current val of x[2] is %', x['2'];
END
$$;

DO $$
DECLARE
  u   collection;
BEGIN
  RAISE NOTICE 'Subscript test 16';
  u['aaa'] := 'Hello World'::text;
  u['bbb'] := 'Hello All'::text;
  u := delete(u, 'aaa');
  u := delete(u, 'bbb');
  u['aaa'] := 'Hello'::text;
  u['bbb'] := 'World'::text;
  RAISE NOTICE 'count: %', count(u);
END
$$;

DO $$
DECLARE
  u   collection('bytea');
BEGIN
  RAISE NOTICE 'Subscript test 17';
  u['aaa'] := NULL::bytea;
  RAISE NOTICE 'count: %', count(u);
END
$$;

DO $$
DECLARE
  n collection('numeric');
BEGIN
  RAISE NOTICE 'Subscript test 18';
  n['aaa'] := 3.14::numeric(8,2);
  n['bbb'] := 42::numeric(8,2);
  RAISE NOTICE 'aaa: %', n['aaa'];
  RAISE NOTICE 'bbb: %', n['bbb'];
END $$;

DO $$
DECLARE
  n collection('INTERVAL');
BEGIN
  RAISE NOTICE 'Subscript test 19';
  n['aaa'] := INTERVAL '5 days 4 hours 3 minutes 2 seconds';
  RAISE NOTICE 'aaa: %', n['aaa'];
END $$;

CREATE FUNCTION test_timestamps()
  RETURNS void AS
$$
DECLARE
  m collection('TIMESTAMP WITHOUT TIME ZONE');
  n collection('TIMESTAMP WITH TIME ZONE');
BEGIN
  RAISE NOTICE 'Subscript test 20';
  m['M'] := '2024-01-15 10:30:45'::TIMESTAMP(0);

  n['O'] := '2024-01-15 10:30:45.123456+02:00'::TIMESTAMP(6) WITH TIME ZONE;

  RAISE NOTICE 'm[M]: %', m['M'];
  RAISE NOTICE 'n[O]: %', n['O'];
END
$$ LANGUAGE plpgsql
SET TIME ZONE 'UTC';

SELECT test_timestamps();

DROP FUNCTION test_timestamps();

DO $$
DECLARE
  c collection;
  long_key text;
BEGIN
  RAISE NOTICE 'Subscript test 21';
  long_key := repeat('b', 32768);
  c[long_key] := 'test_value';
END $$;

DO $$
DECLARE
  c collection;
  long_key text;
  result text;
BEGIN
  RAISE NOTICE 'Subscript test 22';
  c['valid_key'] := 'test_value';
  
  long_key := repeat('g', 32768);
  result := c[long_key];
END $$;

DO $$
DECLARE
  arr_instance1 collection('int4');
  arr_instance2 collection('int4');
BEGIN
  RAISE NOTICE 'Subscript test 23';
  arr_instance2 := copy(arr_instance1);
  arr_instance2['A'] := 1;
  RAISE NOTICE 'Count: %', count(arr_instance2);
END $$;

DO $$
DECLARE
  c1 collection('text');
BEGIN
  RAISE NOTICE 'Subscript test 24';

  -- Uninitialized collection
    RAISE NOTICE 'fetch(c1): %', c1['B'];
END $$;

DO $$
DECLARE
  c2 collection('text') DEFAULT '{"value_type": "text", "entries": {}}'::collection;
BEGIN
  RAISE NOTICE 'Subscript test 25';

  -- Empty collection
    RAISE NOTICE 'fetch(c2): %', c2['B'];
END $$;

DO $$
DECLARE
  c3 collection('text');
BEGIN
  RAISE NOTICE 'Subscript test 26';

  -- Non-empty collection
  c3 := add(c3, 'A', 'Hello World');
    RAISE NOTICE 'fetch(c3): %', c3['B'];
END $$;

DO $$
DECLARE
  c1 collection('text');
BEGIN
  RAISE NOTICE 'Subscript test 27';

  -- Uninitialized collection
    RAISE NOTICE 'fetch(c1): %', c1[NULL];
END $$;

DO $$
DECLARE
  val1 collection('int4');
BEGIN
  RAISE NOTICE 'Subscript test 28';

  val1['A'] := 1::int4;
  val1['A'] := 2::int4;
END;
$$;


DO $$
DECLARE
  val1 collection('varchar');
BEGIN
  RAISE NOTICE 'Subscript test 28';

  val1['A'] := 'hello'::varchar;
  val1['A'] := 'world'::varchar;
END;
$$;

-- Test for data corruption regression
DO $$
DECLARE
  t collection('bigint');
BEGIN
  RAISE NOTICE 'Subscript test 29 - Data corruption regression';
  
  t['key1'] := 1::bigint;
  t['key2'] := 2::bigint;
  t['key3'] := 9223372036854775807::bigint; -- Max bigint
  
  RAISE NOTICE 'Values: %, %, %', t['key1'], t['key2'], t['key3'];
END;
$$;

DO $$
DECLARE
  n collection('numeric');
BEGIN
  RAISE NOTICE 'Subscript test 30 - Numeric precision regression';
  
  n['pi'] := 3.14159265359::numeric;
  n['small'] := 0.000001::numeric;
  n['large'] := 999999999.999999::numeric;
  
  RAISE NOTICE 'Values: %, %, %', n['pi'], n['small'], n['large'];
END;
$$;

DO $$
DECLARE
  i collection('int4');
BEGIN
  RAISE NOTICE 'Subscript test 31 - Type property consistency';
  
  i['a'] := 42::int4;
  i['b'] := -2147483647::int4; -- Near min int4
  i['c'] := 2147483647::int4;  -- Max int4
  
  RAISE NOTICE 'Values: %, %, %', i['a'], i['b'], i['c'];
END;
$$;

-- Subscript test: invalid typmod
DO $$
DECLARE
  c collection('nonexistent_type');
BEGIN
  c['a'] := 'val';
END $$;

-- Subscript test: multiple subscripts not allowed
DO $$
DECLARE
  c collection;
  v text;
BEGIN
  c['a'] := 'val';
  v := c['a']['b'];
END $$;

-- ============================================================
-- PART 2: icollection subscript operations
-- ============================================================

DO $$
DECLARE
  ic   icollection('text');
BEGIN
  RAISE NOTICE 'Subscript test 1';
  ic[1] := 'Hello World';
  ic[2] := 'Hello All';
  ic[3] := 'Hi';
  RAISE NOTICE 'count: %', count(ic);
END
$$;

DO $$
DECLARE
  ic   icollection('text');
BEGIN
  RAISE NOTICE 'Subscript test 2';
  ic[1] := 'Hello World';
  ic[2] := 'Hello All';
  ic[3] := 'Hi';

  RAISE NOTICE 'value: %', ic[2];
END
$$;

DO $$
DECLARE
  ic   icollection('text');
BEGIN
  RAISE NOTICE 'Subscript test 3';
  ic[1] := 'Hello World';
  ic[1] := 'Hello All';

  RAISE NOTICE 'count: %', count(ic);
  RAISE NOTICE 'value: %', ic[1];
END
$$;

DO $$
DECLARE
  ic   icollection('text');
BEGIN
  RAISE NOTICE 'Subscript test 4';
  ic[1] := 'Hello World';
  ic[2] := 'Hello All';
  ic[3] := 'Hi';

  RAISE NOTICE 'value: %', ic[null];
END
$$;

DO $$
DECLARE
  ic   icollection('int4');
BEGIN
  RAISE NOTICE 'Subscript test 5';
  ic[10] := 100;
  ic[20] := 200;
  ic[30] := 300;

  RAISE NOTICE 'value: %', ic[20];
END
$$;

DO $$
DECLARE
  ic   icollection('text');
BEGIN
  RAISE NOTICE 'Subscript test 6';
  ic[-1] := 'negative';
  ic[0] := 'zero';
  ic[1] := 'positive';

  RAISE NOTICE 'value: %', ic[-1];
  RAISE NOTICE 'value: %', ic[0];
  RAISE NOTICE 'value: %', ic[1];
END
$$;

DO $$
DECLARE
  ic   icollection('text');
BEGIN
  RAISE NOTICE 'Subscript test 7';
  ic[1] := NULL;
  ic[2] := 'value';

  RAISE NOTICE 'count: %', count(ic);
END
$$;

-- Subscript test 8: date type via subscript
DO $$
DECLARE
  ic   icollection('date');
BEGIN
  RAISE NOTICE 'Subscript test 8';
  ic[1] := '1999-12-31'::date;

  RAISE NOTICE 'value: %', value(ic, null::date);
END
$$;

-- Subscript test 9: fetch non-existent key
DO $$
DECLARE
  ic   icollection('text');
BEGIN
  RAISE NOTICE 'Subscript test 9';
  ic[1] := 'Hello World';
  ic[2] := 'Hello All';
  ic[3] := 'Hi';

  RAISE NOTICE 'value: %', ic[999];
END
$$;

-- Subscript test 10: type mismatch via subscript
DO $$
DECLARE
  ic   icollection('text');
BEGIN
  RAISE NOTICE 'Subscript test 10';
  ic := add(ic, 1, 'Hello World'::text);
  ic[2] := '12-31-1999'::date;
  RAISE NOTICE 'count: %', count(ic);
END
$$;

-- Subscript test 11: delete then re-add via subscript
DO $$
DECLARE
  ic   icollection;
BEGIN
  RAISE NOTICE 'Subscript test 11';
  ic[1] := 'Hello World'::text;
  ic[2] := 'Hello All'::text;
  ic := delete(ic, 1);
  ic := delete(ic, 2);
  ic[1] := 'Hello'::text;
  ic[2] := 'World'::text;
  RAISE NOTICE 'count: %', count(ic);
END
$$;

-- Subscript test 12: bytea NULL via subscript
DO $$
DECLARE
  ic   icollection('bytea');
BEGIN
  RAISE NOTICE 'Subscript test 12';
  ic[1] := NULL::bytea;
  RAISE NOTICE 'count: %', count(ic);
END
$$;

-- Subscript test 13: numeric via subscript
DO $$
DECLARE
  ic icollection('numeric');
BEGIN
  RAISE NOTICE 'Subscript test 13';
  ic[1] := 3.14::numeric(8,2);
  ic[2] := 42::numeric(8,2);
  RAISE NOTICE '1: %', ic[1];
  RAISE NOTICE '2: %', ic[2];
END $$;

-- Subscript test 14: interval via subscript
DO $$
DECLARE
  ic icollection('INTERVAL');
BEGIN
  RAISE NOTICE 'Subscript test 14';
  ic[1] := INTERVAL '5 days 4 hours 3 minutes 2 seconds';
  RAISE NOTICE '1: %', ic[1];
END $$;

-- Subscript test 15: uninitialized fetch
DO $$
DECLARE
  ic icollection;
BEGIN
  RAISE NOTICE 'Subscript test 15';
  RAISE NOTICE 'The current val is %', ic[2];
END
$$;

-- Subscript test 16: infer type from first subscript assign
DO $$
DECLARE
  ic  icollection;
BEGIN
  RAISE NOTICE 'Subscript test 16';
  ic[1] := 111::bigint;
  ic[2] := 222::bigint;
  RAISE NOTICE 'The type is %', value_type(ic);
END
$$;

-- Subscript test 17: type mismatch on second assign
DO $$
DECLARE
  ic  icollection;
BEGIN
  RAISE NOTICE 'Subscript test 17';
  ic := add(ic, 1, 111::bigint);
  ic[2] := 'abc';
END
$$;

-- Subscript test 18: roundtrip via text cast
DO $$
DECLARE
  ic  icollection('bigint');
  x   icollection('bigint');
BEGIN
  RAISE NOTICE 'Subscript test 18';
  ic[1] := 1;
  ic[2] := 2;
  ic[111] := 11;

  RAISE NOTICE 'The current val of ic is %', ic;

  x := (ic::text)::icollection('bigint');
  RAISE NOTICE 'The current val of x is %', x;
  RAISE NOTICE 'The current val of ic[2] is %', ic[2];
  RAISE NOTICE 'The current val of x[2] is %', x[2];
END
$$;

-- Subscript test 19: copy then assign
DO $$
DECLARE
  ic1 icollection('int4');
  ic2 icollection('int4');
BEGIN
  RAISE NOTICE 'Subscript test 19';
  ic2 := copy(ic1);
  ic2[1] := 1;
  RAISE NOTICE 'Count: %', count(ic2);
END $$;

-- Subscript test 20: fetch from uninitialized
DO $$
DECLARE
  c1 icollection('text');
BEGIN
  RAISE NOTICE 'Subscript test 20';
  RAISE NOTICE 'fetch(c1): %', c1[2];
END $$;

-- Subscript test 21: fetch from empty
DO $$
DECLARE
  c2 icollection('text') DEFAULT '{"value_type": "text", "entries": {}}'::icollection;
BEGIN
  RAISE NOTICE 'Subscript test 21';
  RAISE NOTICE 'fetch(c2): %', c2[2];
END $$;

-- Subscript test 22: fetch non-existent from non-empty
DO $$
DECLARE
  c3 icollection('text');
BEGIN
  RAISE NOTICE 'Subscript test 22';
  c3 := add(c3, 1, 'Hello World');
  RAISE NOTICE 'fetch(c3): %', c3[2];
END $$;

-- Subscript test 23: fetch with NULL key
DO $$
DECLARE
  c1 icollection('text');
BEGIN
  RAISE NOTICE 'Subscript test 23';
  RAISE NOTICE 'fetch(c1): %', c1[NULL];
END $$;

-- Subscript test 24: overwrite int4 value
DO $$
DECLARE
  val1 icollection('int4');
BEGIN
  RAISE NOTICE 'Subscript test 24';
  val1[1] := 1::int4;
  val1[1] := 2::int4;
END;
$$;

-- Subscript test 25: overwrite varchar value
DO $$
DECLARE
  val1 icollection('varchar');
BEGIN
  RAISE NOTICE 'Subscript test 25';
  val1[1] := 'hello'::varchar;
  val1[1] := 'world'::varchar;
END;
$$;

-- Subscript test 26: bigint data corruption regression
DO $$
DECLARE
  ic icollection('bigint');
BEGIN
  RAISE NOTICE 'Subscript test 26 - Data corruption regression';

  ic[1] := 1::bigint;
  ic[2] := 2::bigint;
  ic[3] := 9223372036854775807::bigint;

  RAISE NOTICE 'Values: %, %, %', ic[1], ic[2], ic[3];
END;
$$;

-- Subscript test 27: numeric precision regression
DO $$
DECLARE
  ic icollection('numeric');
BEGIN
  RAISE NOTICE 'Subscript test 27 - Numeric precision regression';

  ic[1] := 3.14159265359::numeric;
  ic[2] := 0.000001::numeric;
  ic[3] := 999999999.999999::numeric;

  RAISE NOTICE 'Values: %, %, %', ic[1], ic[2], ic[3];
END;
$$;

-- Subscript test 28: int4 boundary values
DO $$
DECLARE
  ic icollection('int4');
BEGIN
  RAISE NOTICE 'Subscript test 28 - Type property consistency';

  ic[1] := 42::int4;
  ic[2] := -2147483647::int4;
  ic[3] := 2147483647::int4;

  RAISE NOTICE 'Values: %, %, %', ic[1], ic[2], ic[3];
END;
$$;

-- Subscript test: invalid typmod
DO $$
DECLARE
  ic icollection('nonexistent_type');
BEGIN
  ic[1] := 'val';
END $$;

-- Subscript test: multiple subscripts not allowed
DO $$
DECLARE
  ic icollection;
  v text;
BEGIN
  ic[1] := 'val';
  v := ic[1][2];
END $$;

-- ============================================================
-- PART 3: function/subscript parity (both types)
-- ============================================================

--
-- func_sub_parity.sql
--     Verify that subscript operations produce identical results to their
--     function equivalents (fetch=find, assign=add) for both collection
--     and icollection.  Any divergence here is a bug.
--

-- ============================================================
-- COLLECTION: add() vs subscript assign
-- ============================================================

-- Parity 1: text values (untyped collection)
DO $$
DECLARE
  cf  collection;
  cs  collection;
BEGIN
  cf := add(cf, 'a', 'hello');
  cf := add(cf, 'b', 'world');
  cs['a'] := 'hello';
  cs['b'] := 'world';
  ASSERT cf::text = cs::text,
    format('text add parity failed: func=%s sub=%s', cf, cs);
END $$;

-- Parity 2: integer values (typed collection)
DO $$
DECLARE
  cf  collection('integer');
  cs  collection('integer');
BEGIN
  cf := add(cf, 'x', 42);
  cf := add(cf, 'y', 99);
  cs['x'] := 42;
  cs['y'] := 99;
  ASSERT cf::text = cs::text,
    format('int add parity failed: func=%s sub=%s', cf, cs);
END $$;

-- Parity 3: bigint values (typed collection)
DO $$
DECLARE
  cf  collection('bigint');
  cs  collection('bigint');
BEGIN
  cf := add(cf, 'k', 9999999999::bigint);
  cs['k'] := 9999999999::bigint;
  ASSERT cf::text = cs::text,
    format('bigint add parity failed: func=%s sub=%s', cf, cs);
END $$;

-- Parity 4: date values (typed collection)
DO $$
DECLARE
  cf  collection('date');
  cs  collection('date');
BEGIN
  cf := add(cf, 'd', '2026-01-01'::date);
  cs['d'] := '2026-01-01'::date;
  ASSERT cf::text = cs::text,
    format('date add parity failed: func=%s sub=%s', cf, cs);
END $$;

-- Parity 5: NULL value storage
DO $$
DECLARE
  cf  collection;
  cs  collection;
BEGIN
  cf := add(cf, 'a', 'real');
  cf := add(cf, 'b', null::text);
  cs['a'] := 'real';
  cs['b'] := null::text;
  ASSERT cf::text = cs::text,
    format('null add parity failed: func=%s sub=%s', cf, cs);
END $$;

-- Parity 6: overwrite existing key
DO $$
DECLARE
  cf  collection;
  cs  collection;
BEGIN
  cf := add(cf, 'k', 'old');
  cf := add(cf, 'k', 'new');
  cs['k'] := 'old';
  cs['k'] := 'new';
  ASSERT cf::text = cs::text,
    format('overwrite parity failed: func=%s sub=%s', cf, cs);
END $$;

-- Parity 7: find() vs subscript fetch — text
DO $$
DECLARE
  c   collection;
  vf  text;
  vs  text;
BEGIN
  c := add(c, 'k', 'hello');
  vf := find(c, 'k');
  vs := c['k'];
  ASSERT vf = vs,
    format('text find parity failed: func=%s sub=%s', vf, vs);
END $$;

-- Parity 8: find() vs subscript fetch — bigint
DO $$
DECLARE
  c   collection('bigint');
  vf  bigint;
  vs  bigint;
BEGIN
  c := add(c, 'k', 42::bigint);
  vf := find(c, 'k', 0::bigint);
  vs := c['k'];
  ASSERT vf = vs,
    format('bigint find parity failed: func=%s sub=%s', vf, vs);
END $$;

-- Parity 9: find() vs subscript fetch — date
DO $$
DECLARE
  c   collection('date');
  vf  date;
  vs  date;
BEGIN
  c := add(c, 'k', '2026-06-15'::date);
  vf := find(c, 'k', '2000-01-01'::date);
  vs := c['k'];
  ASSERT vf = vs,
    format('date find parity failed: func=%s sub=%s', vf, vs);
END $$;

-- Parity 10: NULL fetch parity
DO $$
DECLARE
  c   collection;
  vf  text;
  vs  text;
BEGIN
  c := add(c, 'k', null::text);
  vf := find(c, 'k');
  vs := c['k'];
  ASSERT vf IS NULL AND vs IS NULL,
    format('null find parity failed: func=%s sub=%s', vf, vs);
END $$;

-- Parity 11: type mismatch — add() rejects, subscript must also reject
DO $$
DECLARE
  c     collection;
  ok_f  boolean := false;
  ok_s  boolean := false;
BEGIN
  c := add(c, 'a', 42::bigint);

  BEGIN
    c := add(c, 'b', 'text_val');
  EXCEPTION WHEN datatype_mismatch THEN
    ok_f := true;
  END;

  BEGIN
    c['b'] := 'text_val';
  EXCEPTION WHEN datatype_mismatch THEN
    ok_s := true;
  END;

  ASSERT ok_f AND ok_s,
    format('type mismatch parity failed: func_err=%s sub_err=%s', ok_f, ok_s);
END $$;

-- Parity 12: missing key — find() errors, subscript must also error
DO $$
DECLARE
  c     collection;
  ok_f  boolean := false;
  ok_s  boolean := false;
  v     text;
BEGIN
  c := add(c, 'a', 'val');

  BEGIN
    v := find(c, 'missing');
  EXCEPTION WHEN no_data_found THEN
    ok_f := true;
  END;

  BEGIN
    v := c['missing'];
  EXCEPTION WHEN no_data_found THEN
    ok_s := true;
  END;

  ASSERT ok_f AND ok_s,
    format('missing key parity failed: func_err=%s sub_err=%s', ok_f, ok_s);
END $$;

-- Parity 13: count after add vs subscript
DO $$
DECLARE
  cf  collection;
  cs  collection;
BEGIN
  cf := add(add(add(cf, 'a', 1), 'b', 2), 'c', 3);
  cs['a'] := 1;
  cs['b'] := 2;
  cs['c'] := 3;
  ASSERT count(cf) = count(cs) AND count(cf) = 3,
    format('count parity failed: func=%s sub=%s', count(cf), count(cs));
END $$;

-- Parity 14: value_type matches after add vs subscript (typed)
DO $$
DECLARE
  cf  collection('bigint');
  cs  collection('bigint');
BEGIN
  cf := add(cf, 'a', 42::bigint);
  cs['a'] := 42::bigint;
  ASSERT value_type(cf) = value_type(cs),
    format('value_type parity failed: func=%s sub=%s',
           value_type(cf), value_type(cs));
END $$;

-- ============================================================
-- ICOLLECTION: add() vs subscript assign
-- ============================================================

-- Parity 15: text values
DO $$
DECLARE
  cf  icollection;
  cs  icollection;
BEGIN
  cf := add(cf, 1, 'hello');
  cf := add(cf, 2, 'world');
  cs[1] := 'hello';
  cs[2] := 'world';
  ASSERT cf::text = cs::text,
    format('ic text add parity failed: func=%s sub=%s', cf, cs);
END $$;

-- Parity 16: bigint values (typed)
DO $$
DECLARE
  cf  icollection('bigint');
  cs  icollection('bigint');
BEGIN
  cf := add(cf, 1, 9999999999::bigint);
  cs[1] := 9999999999::bigint;
  ASSERT cf::text = cs::text,
    format('ic bigint add parity failed: func=%s sub=%s', cf, cs);
END $$;

-- Parity 17: NULL value storage
DO $$
DECLARE
  cf  icollection;
  cs  icollection;
BEGIN
  cf := add(cf, 1, 'real');
  cf := add(cf, 2, null::text);
  cs[1] := 'real';
  cs[2] := null::text;
  ASSERT cf::text = cs::text,
    format('ic null add parity failed: func=%s sub=%s', cf, cs);
END $$;

-- Parity 18: overwrite existing key
DO $$
DECLARE
  cf  icollection;
  cs  icollection;
BEGIN
  cf := add(cf, 1, 'old');
  cf := add(cf, 1, 'new');
  cs[1] := 'old';
  cs[1] := 'new';
  ASSERT cf::text = cs::text,
    format('ic overwrite parity failed: func=%s sub=%s', cf, cs);
END $$;

-- Parity 19: find() vs subscript fetch — text
DO $$
DECLARE
  c   icollection;
  vf  text;
  vs  text;
BEGIN
  c := add(c, 1, 'hello');
  vf := find(c, 1);
  vs := c[1];
  ASSERT vf = vs,
    format('ic text find parity failed: func=%s sub=%s', vf, vs);
END $$;

-- Parity 20: find() vs subscript fetch — bigint
DO $$
DECLARE
  c   icollection('bigint');
  vf  bigint;
  vs  bigint;
BEGIN
  c := add(c, 1, 42::bigint);
  vf := find(c, 1, 0::bigint);
  vs := c[1];
  ASSERT vf = vs,
    format('ic bigint find parity failed: func=%s sub=%s', vf, vs);
END $$;

-- Parity 21: NULL fetch parity
DO $$
DECLARE
  c   icollection;
  vf  text;
  vs  text;
BEGIN
  c := add(c, 1, null::text);
  vf := find(c, 1);
  vs := c[1];
  ASSERT vf IS NULL AND vs IS NULL,
    format('ic null find parity failed: func=%s sub=%s', vf, vs);
END $$;

-- Parity 22: type mismatch — both reject
DO $$
DECLARE
  c     icollection;
  ok_f  boolean := false;
  ok_s  boolean := false;
BEGIN
  c := add(c, 1, 42::bigint);

  BEGIN
    c := add(c, 2, 'text_val');
  EXCEPTION WHEN datatype_mismatch THEN
    ok_f := true;
  END;

  BEGIN
    c[2] := 'text_val';
  EXCEPTION WHEN datatype_mismatch THEN
    ok_s := true;
  END;

  ASSERT ok_f AND ok_s,
    format('ic type mismatch parity failed: func_err=%s sub_err=%s', ok_f, ok_s);
END $$;

-- Parity 23: missing key — both error
DO $$
DECLARE
  c     icollection;
  ok_f  boolean := false;
  ok_s  boolean := false;
  v     text;
BEGIN
  c := add(c, 1, 'val');

  BEGIN
    v := find(c, 999);
  EXCEPTION WHEN no_data_found THEN
    ok_f := true;
  END;

  BEGIN
    v := c[999];
  EXCEPTION WHEN no_data_found THEN
    ok_s := true;
  END;

  ASSERT ok_f AND ok_s,
    format('ic missing key parity failed: func_err=%s sub_err=%s', ok_f, ok_s);
END $$;

-- Parity 24: count after add vs subscript
DO $$
DECLARE
  cf  icollection;
  cs  icollection;
BEGIN
  cf := add(add(add(cf, 1, 'a'), 2, 'b'), 3, 'c');
  cs[1] := 'a';
  cs[2] := 'b';
  cs[3] := 'c';
  ASSERT count(cf) = count(cs) AND count(cf) = 3,
    format('ic count parity failed: func=%s sub=%s', count(cf), count(cs));
END $$;

-- Parity 25: value_type matches for icollection (typed)
DO $$
DECLARE
  cf  icollection('date');
  cs  icollection('date');
BEGIN
  cf := add(cf, 1, '2026-01-01'::date);
  cs[1] := '2026-01-01'::date;
  ASSERT value_type(cf) = value_type(cs),
    format('ic value_type parity failed: func=%s sub=%s',
           value_type(cf), value_type(cs));
END $$;

-- Parity 26: multi-step add+find roundtrip
DO $$
DECLARE
  cf  collection;
  cs  collection;
BEGIN
  cf := add(cf, 'a', 'one');
  cf := add(cf, 'b', 'two');
  cf := add(cf, 'a', 'replaced');
  cs['a'] := 'one';
  cs['b'] := 'two';
  cs['a'] := 'replaced';
  ASSERT find(cf, 'a') = cs['a'] AND find(cf, 'b') = cs['b'],
    format('roundtrip parity failed');
END $$;

-- Parity 27: multi-step icollection roundtrip
DO $$
DECLARE
  cf  icollection;
  cs  icollection;
BEGIN
  cf := add(cf, 10, 'one');
  cf := add(cf, 20, 'two');
  cf := add(cf, 10, 'replaced');
  cs[10] := 'one';
  cs[20] := 'two';
  cs[10] := 'replaced';
  ASSERT find(cf, 10) = cs[10] AND find(cf, 20) = cs[20],
    format('ic roundtrip parity failed');
END $$;
