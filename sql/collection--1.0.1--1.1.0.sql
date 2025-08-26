-- complain if script is sourced in psql, rather than via CREATE EXTENSION
\echo Use "ALTER EXTENSION collection UPDATE TO '1.1.0'" to load this file. \quit

CREATE FUNCTION last(collection)
  RETURNS collection
  AS 'MODULE_PATHNAME', 'collection_last'
  LANGUAGE c;

DROP VIEW collection_stats;

DROP FUNCTION collection_stats();

CREATE FUNCTION collection_stats(OUT add int8, OUT context_switch int8,
                                 OUT delete int8, OUT find int8, OUT sort int8,
                                 OUT exist int8)
  AS 'MODULE_PATHNAME', 'collection_stats'
  LANGUAGE c;

CREATE VIEW collection_stats
  AS SELECT add, context_switch, delete, find, sort, exist
       FROM collection_stats();

CREATE FUNCTION exist(collection, text)
  RETURNS bool
  AS 'MODULE_PATHNAME', 'collection_exist'
  LANGUAGE c;
