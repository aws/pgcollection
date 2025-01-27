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
