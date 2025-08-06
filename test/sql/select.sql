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
