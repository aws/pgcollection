--
-- stress.sql
--     Large collection tests and stats counter verification.
--

-- Large collection: 1000 entries
DO $$
DECLARE
  c collection;
  i int;
BEGIN
  FOR i IN 1..1000 LOOP
    c := add(c, 'key_' || i, 'val_' || i);
  END LOOP;

  ASSERT count(c) = 1000, format('expected 1000, got %s', count(c));
  ASSERT find(c, 'key_1') = 'val_1', 'find first failed';
  ASSERT find(c, 'key_500') = 'val_500', 'find middle failed';
  ASSERT find(c, 'key_1000') = 'val_1000', 'find last failed';

  c := delete(c, 'key_500');
  ASSERT count(c) = 999, 'delete middle count failed';
  ASSERT exist(c, 'key_500') = false, 'deleted key should not exist';
  ASSERT exist(c, 'key_499') = true, 'neighbor should still exist';
END $$;

-- Large icollection: 1000 entries
DO $$
DECLARE
  ic icollection;
  i int;
BEGIN
  FOR i IN 1..1000 LOOP
    ic := add(ic, i, 'val_' || i);
  END LOOP;

  ASSERT count(ic) = 1000, format('ic expected 1000, got %s', count(ic));
  ASSERT find(ic, 1) = 'val_1', 'ic find first failed';
  ASSERT find(ic, 500) = 'val_500', 'ic find middle failed';
  ASSERT find(ic, 1000) = 'val_1000', 'ic find last failed';

  ic := delete(ic, 500);
  ASSERT count(ic) = 999, 'ic delete middle count failed';
  ASSERT exist(ic, 500) = false, 'ic deleted key should not exist';
  ASSERT exist(ic, 499) = true, 'ic neighbor should still exist';
END $$;

-- Stats counter verification
SELECT collection_stats_reset();

DO $$
DECLARE
  c collection;
BEGIN
  c := add(c, 'a', '1');
  c := add(c, 'b', '2');
  c := add(c, 'c', '3');
  PERFORM find(c, 'a');
  PERFORM find(c, 'b');
  PERFORM exist(c, 'a');
  c := delete(c, 'c');
  c := sort(c);
END $$;

SELECT * FROM collection_stats;
