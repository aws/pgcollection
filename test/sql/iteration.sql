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

