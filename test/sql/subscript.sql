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
END
$$;
