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
