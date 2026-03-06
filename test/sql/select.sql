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
