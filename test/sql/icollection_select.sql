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
