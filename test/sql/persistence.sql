--
-- persistence.sql
--     Table storage, flatten/unflatten roundtrips, SELECT queries.
--     Covers both collection (text-keyed) and icollection (int-keyed).
--

-- ============================================================
-- PART 1: collection table storage
-- ============================================================

CREATE TABLE select_collection(col_collection collection);

INSERT INTO select_collection VALUES('{"value_type":"pg_catalog.text","entries":{"USA":"Washington", "UK":"London"}}');
INSERT INTO select_collection VALUES('{"value_type":"pg_catalog.text","entries":{"India":"New Delhi"}}');
INSERT INTO select_collection VALUES('{"entries":{"China":"Beijing"}}');
INSERT INTO select_collection VALUES('{"value_type":"pg_catalog.text","entries":{"NULL":"NULL"}}');
INSERT INTO select_collection VALUES('{"value_type":"pg_catalog.text","entries":{"Canada":"Ottawa"}}');
INSERT INTO select_collection VALUES('{"value_type":"pg_catalog.text","entries":{"India":"New Delhi"}}');
INSERT INTO select_collection VALUES('{"value_type":"pg_catalog.text","entries":{"Australia":"Canberra"}}');

-- should throw error
INSERT INTO select_collection VALUES('{"value_type":"pg_catalog.text","entries":{NULL:NULL}}');

SELECT * FROM select_collection;

SELECT sort(col_collection) FROM select_collection;

SELECT key(col_collection) FROM select_collection;

SELECT value(col_collection) FROM select_collection;

SELECT value_type(col_collection) FROM select_collection;

SELECT to_table(col_collection) FROM select_collection;

SELECT keys_to_table(col_collection) FROM select_collection;

SELECT values_to_table(col_collection) FROM select_collection;

SELECT COUNT(col_collection) FROM select_collection;

INSERT INTO select_collection VALUES('{"value_type":"pg_catalog.varchar","entries":{"Japan":"Tokyo"}}');
INSERT INTO select_collection VALUES('{"value_type":"pg_catalog.char","entries":{"Canada":"Ottawa"}}');

SELECT * FROM select_collection;

DROP TABLE select_collection;

-- Typed collection persistence
CREATE TABLE select_typed(id serial, c collection);

INSERT INTO select_typed(c)
  SELECT add(add(null::collection, 'a', 42::bigint), 'b', 99::bigint);
INSERT INTO select_typed(c)
  SELECT add(add(null::collection, 'x', '2026-01-01'::date), 'y', '2026-06-15'::date);
INSERT INTO select_typed(c)
  SELECT add(add(null::collection, 'p', 'hello'), 'q', null::text);

SELECT id, c FROM select_typed ORDER BY id;

DROP TABLE select_typed;

-- ============================================================
-- PART 2: icollection table storage
-- ============================================================

-- Table storage tests for icollection (mirrors collection select.sql)

CREATE TABLE select_icollection(col_icollection icollection);

INSERT INTO select_icollection VALUES('{"value_type":"pg_catalog.text","entries":{"1":"Washington", "2":"London"}}');
INSERT INTO select_icollection VALUES('{"value_type":"pg_catalog.text","entries":{"3":"New Delhi"}}');
INSERT INTO select_icollection VALUES('{"value_type":"pg_catalog.text","entries":{"4":"Beijing"}}');
INSERT INTO select_icollection VALUES('{"value_type":"pg_catalog.text","entries":{"5":"Ottawa"}}');

SELECT * FROM select_icollection;

SELECT sort(col_icollection) FROM select_icollection;

SELECT key(col_icollection) FROM select_icollection;

SELECT value(col_icollection) FROM select_icollection;

SELECT value_type(col_icollection) FROM select_icollection;

SELECT to_table(col_icollection) FROM select_icollection;

SELECT keys_to_table(col_icollection) FROM select_icollection;

SELECT values_to_table(col_icollection) FROM select_icollection;

SELECT COUNT(col_icollection) FROM select_icollection;

DROP TABLE select_icollection;

-- Typed icollection persistence
CREATE TABLE select_ic_typed(id serial, ic icollection);

INSERT INTO select_ic_typed(ic)
  SELECT add(add(null::icollection, 1, 42::bigint), 2, 99::bigint);
INSERT INTO select_ic_typed(ic)
  SELECT add(add(null::icollection, 10, '2026-01-01'::date), 20, '2026-06-15'::date);
INSERT INTO select_ic_typed(ic)
  SELECT add(add(null::icollection, 1, 'hello'), 2, null::text);

SELECT id, ic FROM select_ic_typed ORDER BY id;

DROP TABLE select_ic_typed;

-- Text output must preserve quoted values, negative keys, and a stored NULL.
DO $$
DECLARE
  c icollection('text');
  restored icollection;
  escaped text := E'quote " and backslash \\ and newline\n';
BEGIN
  c[-2] := escaped;
  c[0] := NULL::text;
  c[3] := 'null';
  restored := (c::text)::icollection;
  ASSERT value_type(restored) = 'text'::regtype;
  ASSERT count(restored) = 3;
  ASSERT restored[-2] IS NOT DISTINCT FROM escaped;
  ASSERT exist(restored, 0) AND restored[0] IS NULL;
  ASSERT restored[3] IS NOT DISTINCT FROM 'null';
END
$$;
