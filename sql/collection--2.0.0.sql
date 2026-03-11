-- complain if script is sourced in psql, rather than via CREATE EXTENSION
\echo Use "CREATE EXTENSION collection" to load this file. \quit

-- ============================================================================
-- collection type (text-keyed)
-- ============================================================================

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

CREATE FUNCTION delete(collection)
  RETURNS collection
  AS 'MODULE_PATHNAME', 'collection_delete_all'
  LANGUAGE C;

CREATE FUNCTION delete(collection, text, text)
  RETURNS collection
  AS 'MODULE_PATHNAME', 'collection_delete_range'
  LANGUAGE C;

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
  LANGUAGE c;

CREATE FUNCTION prev(collection)
  RETURNS collection
  AS 'MODULE_PATHNAME', 'collection_prev'
  LANGUAGE c;

CREATE FUNCTION first(collection)
  RETURNS collection
  AS 'MODULE_PATHNAME', 'collection_first'
  LANGUAGE c;

CREATE FUNCTION last(collection)
  RETURNS collection
  AS 'MODULE_PATHNAME', 'collection_last'
  STRICT
  LANGUAGE c;

CREATE FUNCTION exist(collection, text)
  RETURNS bool
  AS 'MODULE_PATHNAME', 'collection_exist'
  LANGUAGE c;

CREATE FUNCTION next_key(collection, text)
  RETURNS text
  AS 'MODULE_PATHNAME', 'collection_next_key'
  STRICT
  LANGUAGE c;

CREATE FUNCTION prev_key(collection, text)
  RETURNS text
  AS 'MODULE_PATHNAME', 'collection_prev_key'
  STRICT
  LANGUAGE c;

CREATE FUNCTION first_key(collection)
  RETURNS text
  AS 'MODULE_PATHNAME', 'collection_first_key'
  STRICT
  LANGUAGE c;

CREATE FUNCTION last_key(collection)
  RETURNS text
  AS 'MODULE_PATHNAME', 'collection_last_key'
  STRICT
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
                                 OUT delete int8, OUT find int8, OUT sort int8,
                                 OUT exist int8)
  AS 'MODULE_PATHNAME', 'collection_stats'
  LANGUAGE c;

CREATE FUNCTION collection_stats_reset()
  RETURNS void
  AS 'MODULE_PATHNAME', 'collection_stats_reset'
  LANGUAGE c;

CREATE VIEW collection_stats
  AS SELECT add, context_switch, delete, find, sort, exist
       FROM collection_stats();

CREATE CAST (collection AS json)
  WITH INOUT
  AS IMPLICIT;

-- ============================================================================
-- icollection type (int64-keyed)
-- ============================================================================

CREATE TYPE icollection;

CREATE FUNCTION icollection_in(cstring, oid, integer)
    RETURNS icollection
    AS 'MODULE_PATHNAME'
    LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION icollection_out(icollection)
    RETURNS cstring
    AS 'MODULE_PATHNAME'
    LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION icollection_typmodin(cstring[])
    RETURNS integer
    AS 'MODULE_PATHNAME'
    LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;

CREATE FUNCTION icollection_typmodout(integer)
    RETURNS cstring
    AS 'MODULE_PATHNAME'
    LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;

CREATE FUNCTION icollection_subscript_handler(internal)
    RETURNS internal
    AS 'MODULE_PATHNAME', 'icollection_subscript_handler'
    LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;

CREATE TYPE icollection (
    INPUT = icollection_in,
    OUTPUT = icollection_out,
    TYPMOD_IN = icollection_typmodin,
    TYPMOD_OUT = icollection_typmodout,
    STORAGE = extended,
    SUBSCRIPT = icollection_subscript_handler
);

CREATE FUNCTION icollection(icollection, integer)
    RETURNS icollection
    AS 'MODULE_PATHNAME', 'icollection_cast'
    LANGUAGE C IMMUTABLE;

CREATE CAST (icollection AS icollection)
    WITH FUNCTION icollection(icollection, integer)
    AS IMPLICIT;

CREATE FUNCTION add(icollection, bigint, anyelement)
    RETURNS icollection
    AS 'MODULE_PATHNAME', 'icollection_add'
    LANGUAGE C;

CREATE FUNCTION add(icollection, bigint, text)
    RETURNS icollection
    AS 'MODULE_PATHNAME', 'icollection_add'
    LANGUAGE C;

CREATE FUNCTION find(icollection, bigint, anyelement)
    RETURNS anyelement
    AS 'MODULE_PATHNAME', 'icollection_find'
    LANGUAGE C;

CREATE FUNCTION find(icollection, bigint)
    RETURNS text
    AS 'MODULE_PATHNAME', 'icollection_find'
    LANGUAGE C;

CREATE FUNCTION exist(icollection, bigint)
    RETURNS boolean
    AS 'MODULE_PATHNAME', 'icollection_exist'
    LANGUAGE C;

CREATE FUNCTION count(icollection)
    RETURNS integer
    AS 'MODULE_PATHNAME', 'icollection_count'
    LANGUAGE C;

CREATE FUNCTION delete(icollection, bigint)
    RETURNS icollection
    AS 'MODULE_PATHNAME', 'icollection_delete'
    LANGUAGE C;

CREATE FUNCTION delete(icollection)
    RETURNS icollection
    AS 'MODULE_PATHNAME', 'icollection_delete_all'
    LANGUAGE C;

CREATE FUNCTION delete(icollection, bigint, bigint)
    RETURNS icollection
    AS 'MODULE_PATHNAME', 'icollection_delete_range'
    LANGUAGE C;

CREATE FUNCTION first(icollection)
    RETURNS icollection
    AS 'MODULE_PATHNAME', 'icollection_first'
    LANGUAGE C;

CREATE FUNCTION last(icollection)
    RETURNS icollection
    AS 'MODULE_PATHNAME', 'icollection_last'
    STRICT
    LANGUAGE C;

CREATE FUNCTION next(icollection)
    RETURNS icollection
    AS 'MODULE_PATHNAME', 'icollection_next'
    LANGUAGE C;

CREATE FUNCTION prev(icollection)
    RETURNS icollection
    AS 'MODULE_PATHNAME', 'icollection_prev'
    LANGUAGE C;

CREATE FUNCTION key(icollection)
    RETURNS bigint
    AS 'MODULE_PATHNAME', 'icollection_key'
    STRICT
    LANGUAGE C;

CREATE FUNCTION value(icollection, anyelement)
    RETURNS anyelement
    AS 'MODULE_PATHNAME', 'icollection_value'
    LANGUAGE C;

CREATE FUNCTION value(icollection)
    RETURNS text
    AS 'MODULE_PATHNAME', 'icollection_value'
    STRICT
    LANGUAGE C;

CREATE FUNCTION isnull(icollection)
    RETURNS boolean
    AS 'MODULE_PATHNAME', 'icollection_isnull'
    LANGUAGE C;

CREATE FUNCTION sort(icollection)
    RETURNS icollection
    AS 'MODULE_PATHNAME', 'icollection_sort'
    STRICT
    LANGUAGE C;

CREATE FUNCTION copy(icollection)
    RETURNS icollection
    AS 'MODULE_PATHNAME', 'icollection_copy'
    STRICT
    LANGUAGE C;

CREATE FUNCTION value_type(icollection)
    RETURNS regtype
    AS 'MODULE_PATHNAME', 'icollection_value_type'
    LANGUAGE C;

CREATE FUNCTION keys_to_table(icollection)
    RETURNS SETOF bigint
    AS 'MODULE_PATHNAME', 'icollection_keys_to_table'
    LANGUAGE C;

CREATE FUNCTION values_to_table(icollection)
    RETURNS SETOF text
    AS 'MODULE_PATHNAME', 'icollection_values_to_table'
    LANGUAGE C;

CREATE FUNCTION values_to_table(icollection, anyelement)
    RETURNS SETOF anyelement
    AS 'MODULE_PATHNAME', 'icollection_values_to_table'
    LANGUAGE C;

CREATE FUNCTION to_table(icollection, OUT key bigint, OUT value text)
    RETURNS SETOF record
    AS 'MODULE_PATHNAME', 'icollection_to_table'
    LANGUAGE C;

CREATE FUNCTION to_table(icollection, anyelement, OUT key bigint, OUT value anyelement)
    RETURNS SETOF record
    AS 'MODULE_PATHNAME', 'icollection_to_table'
    LANGUAGE C;

CREATE FUNCTION next_key(icollection, bigint)
    RETURNS bigint
    AS 'MODULE_PATHNAME', 'icollection_next_key'
    STRICT
    LANGUAGE C;

CREATE FUNCTION prev_key(icollection, bigint)
    RETURNS bigint
    AS 'MODULE_PATHNAME', 'icollection_prev_key'
    STRICT
    LANGUAGE C;

CREATE FUNCTION first_key(icollection)
    RETURNS bigint
    AS 'MODULE_PATHNAME', 'icollection_first_key'
    STRICT
    LANGUAGE C;

CREATE FUNCTION last_key(icollection)
    RETURNS bigint
    AS 'MODULE_PATHNAME', 'icollection_last_key'
    STRICT
    LANGUAGE C;

CREATE CAST (icollection AS json)
    WITH INOUT
    AS IMPLICIT;
