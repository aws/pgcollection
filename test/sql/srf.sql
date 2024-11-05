DO $$
DECLARE
  u   collection('text');
  r   record;
BEGIN
  RAISE NOTICE 'SRF test 1';
  u['aaa'] := 'Hello World';
  u['bbb'] := 'Hello All';

  RAISE NOTICE '----------------';
  FOR r IN SELECT k FROM keys_to_table(u) k
  LOOP
    RAISE NOTICE 'key: [%]', r.k;
  END LOOP;
END
$$;

DO $$
DECLARE
  u   collection('text');
  r   record;
BEGIN
  RAISE NOTICE 'SRF test 2';
  u['aaa'] := 'Hello World';
  u['bbb'] := 'Hello All';

  RAISE NOTICE '----------------';
  FOR r IN SELECT v FROM values_to_table(u) v
  LOOP
    RAISE NOTICE 'value: [%]', r.v;
  END LOOP;
END
$$;

DO $$
DECLARE
  u   collection('date');
  r   record;
BEGIN
  RAISE NOTICE 'SRF test 3';
  u['aaa'] := '1999-12-31'::date;
  u['bbb'] := '2000-01-01'::date;

  RAISE NOTICE '----------------';
  FOR r IN SELECT v FROM values_to_table(u, null::date) v
  LOOP
    RAISE NOTICE 'value: [%]', r.v;
  END LOOP;
END
$$;

DO $$
DECLARE
  u   collection('int');
  r   record;
BEGIN
  RAISE NOTICE 'SRF test 3';
  u['aa'] := 100;
  u['bb'] := 222;

  RAISE NOTICE '----------------';
  FOR r IN SELECT v FROM values_to_table(u, null::int) v
  LOOP
    RAISE NOTICE 'value: [%]', r.v;
  END LOOP;
END
$$;

DO $$
DECLARE
  u   collection('text');
  r   record;
BEGIN
  RAISE NOTICE 'SRF test 4';
  u['aaa'] := 'Hello World';
  u['bbb'] := 'Hello All';

  RAISE NOTICE '----------------';
  FOR r IN SELECT * FROM to_table(u) v
  LOOP
	RAISE NOTICE 'key: [%] value: [%]', r.key, r.value;
  END LOOP;
END
$$;

DO $$
DECLARE
  u   collection('date');
  r   record;
BEGIN
  RAISE NOTICE 'SRF test 5';
  u['aaa'] := '1999-12-31'::date;
  u['bbb'] := '2000-01-01'::date;

  RAISE NOTICE '----------------';
  FOR r IN SELECT * FROM to_table(u, null::date) v
  LOOP
	RAISE NOTICE 'key: [%] value: [%]', r.key, r.value;
  END LOOP;
END
$$;

CREATE TABLE collection_regress(col1 varchar, col2 varchar, col3 int);

INSERT INTO collection_regress VALUES ('aaa', 'Hello World', 42), ('bbb', 'Hello All', 84);

DO
$$
DECLARE
  r       collection_regress%ROWTYPE;
  c       collection('collection_regress');
  cr      record;
BEGIN
  RAISE NOTICE 'SRF test 6';
  FOR r IN SELECT * 
             FROM collection_regress 
            ORDER BY col1
  LOOP
    c[r.col1] = r;
  END LOOP;

  FOR cr IN SELECT * FROM to_table(c, null::collection_regress)
  LOOP
    RAISE NOTICE 'col1: [%] col3: [%]', cr.key, (cr.value).col3;
  END LOOP;
END
$$;

DO
$$
DECLARE
  c       collection('int');
BEGIN
  RAISE NOTICE 'SRF test 7';

  c['aaa'] := 142;
  c['bbb'] := 184;

  UPDATE collection_regress
     SET col3 = t.value
    FROM to_table(c, null::int) t
   WHERE col1 = t.key;
END
$$;

SELECT * FROM collection_regress ORDER BY col1;

DROP TABLE collection_regress;
