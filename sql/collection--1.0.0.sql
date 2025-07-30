-- complain if script is sourced in psql, rather than via CREATE EXTENSION
\echo Use "CREATE EXTENSION collection" to load this file. \quit

CREATE TYPE collection;

CREATE FUNCTION collection_in(cstring) 
  RETURNS collection 
  AS 'MODULE_PATHNAME'
  LANGUAGE c 
  STRICT IMMUTABLE PARALLEL SAFE;

CREATE FUNCTION collection_out(collection) 
  RETURNS cstring 
  AS 'MODULE_PATHNAME'
  LANGUAGE c 
  STRICT IMMUTABLE PARALLEL SAFE;

CREATE FUNCTION collection_typmodin(cstring[]) 
  RETURNS integer 
  AS 'MODULE_PATHNAME'
  LANGUAGE c 
  STRICT IMMUTABLE PARALLEL SAFE;

CREATE FUNCTION collection_typmodout(integer) 
  RETURNS cstring 
  AS 'MODULE_PATHNAME'
  LANGUAGE c 
  STRICT IMMUTABLE PARALLEL SAFE;

CREATE FUNCTION collection_subscript_handler(internal) 
  RETURNS internal
  AS 'MODULE_PATHNAME', 'collection_subscript_handler'
  LANGUAGE C 
  STRICT IMMUTABLE PARALLEL SAFE;

CREATE TYPE collection (
	INPUT = collection_in,
	OUTPUT = collection_out,
	TYPMOD_IN = collection_typmodin,
	TYPMOD_OUT  = collection_typmodout,
	SUBSCRIPT = collection_subscript_handler,
	INTERNALLENGTH = -1,
	STORAGE = extended,
	COLLATABLE = true
);

CREATE FUNCTION collection (collection, integer) 
  RETURNS collection
  AS 'MODULE_PATHNAME', 'collection_cast'
  LANGUAGE c
  IMMUTABLE;

CREATE CAST (collection AS collection) 
  WITH FUNCTION collection(collection, integer)
  AS IMPLICIT;

CREATE FUNCTION add(collection, text, anyelement) 
  RETURNS collection 
  AS 'MODULE_PATHNAME', 'collection_add'
  LANGUAGE c;

CREATE FUNCTION add(collection, text, text) 
  RETURNS collection 
  AS 'MODULE_PATHNAME', 'collection_add'
  LANGUAGE c;

CREATE FUNCTION count(collection) 
  RETURNS int 
  AS 'MODULE_PATHNAME', 'collection_count'
  STRICT
  LANGUAGE c;

CREATE FUNCTION find(collection, text, anyelement) 
  RETURNS anyelement 
  AS 'MODULE_PATHNAME', 'collection_find'
  LANGUAGE c;

CREATE FUNCTION find(collection, text) 
  RETURNS text 
  AS 'MODULE_PATHNAME', 'collection_find'
  LANGUAGE c;

CREATE FUNCTION delete(collection, text) 
  RETURNS collection 
  AS 'MODULE_PATHNAME', 'collection_delete'
  LANGUAGE c;

CREATE FUNCTION sort(collection) 
  RETURNS collection 
  AS 'MODULE_PATHNAME', 'collection_sort'
  STRICT
  LANGUAGE c;

CREATE FUNCTION copy(collection) 
  RETURNS collection 
  AS 'MODULE_PATHNAME', 'collection_copy'
  STRICT
  LANGUAGE c;

CREATE FUNCTION key(collection) 
  RETURNS text 
  AS 'MODULE_PATHNAME', 'collection_key'
  STRICT
  LANGUAGE c;

CREATE FUNCTION value(collection, anyelement) 
  RETURNS anyelement 
  AS 'MODULE_PATHNAME', 'collection_value'
  LANGUAGE c;  

CREATE FUNCTION value(collection) 
  RETURNS text 
  AS 'MODULE_PATHNAME', 'collection_value'
  STRICT
  LANGUAGE c;  

CREATE FUNCTION next(collection) 
  RETURNS collection 
  AS 'MODULE_PATHNAME', 'collection_next'
  LANGUAGE c; 

CREATE FUNCTION isnull(collection) 
  RETURNS bool 
  AS 'MODULE_PATHNAME', 'collection_isnull'
  STRICT
  LANGUAGE c;

CREATE FUNCTION prev(collection) 
  RETURNS collection 
  AS 'MODULE_PATHNAME', 'collection_prev'
  LANGUAGE c;

CREATE FUNCTION first(collection) 
  RETURNS collection 
  AS 'MODULE_PATHNAME', 'collection_first'
  LANGUAGE c;

CREATE FUNCTION keys_to_table(collection) 
  RETURNS SETOF text 
  AS 'MODULE_PATHNAME', 'collection_keys_to_table'
  LANGUAGE c;

CREATE FUNCTION values_to_table(collection) 
  RETURNS SETOF text 
  AS 'MODULE_PATHNAME', 'collection_values_to_table'
  LANGUAGE c;

CREATE FUNCTION values_to_table(collection, anyelement) 
  RETURNS SETOF anyelement 
  AS 'MODULE_PATHNAME', 'collection_values_to_table'
  LANGUAGE c;

CREATE FUNCTION to_table(collection, OUT key text, OUT value text) 
  RETURNS SETOF record 
  AS 'MODULE_PATHNAME', 'collection_to_table'
  LANGUAGE c;

CREATE FUNCTION to_table(collection, anyelement, OUT key text, OUT value anyelement) 
  RETURNS SETOF record 
  AS 'MODULE_PATHNAME', 'collection_to_table'
  LANGUAGE c;

CREATE FUNCTION value_type(collection)
  RETURNS regtype
  AS 'MODULE_PATHNAME', 'collection_value_type'
  LANGUAGE c;

CREATE FUNCTION collection_stats(OUT add int8, OUT context_switch int8, 
                                 OUT delete int8, OUT find int8, OUT sort int8)
  AS 'MODULE_PATHNAME', 'collection_stats'
  LANGUAGE c;

CREATE FUNCTION collection_stats_reset() 
  RETURNS void
  AS 'MODULE_PATHNAME', 'collection_stats_reset'
  LANGUAGE c;

CREATE VIEW collection_stats
  AS SELECT add, context_switch, delete, find, sort
       FROM collection_stats();

CREATE CAST (collection AS json)
  WITH INOUT
  AS IMPLICIT;
