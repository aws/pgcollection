-- complain if script is sourced in psql, rather than via CREATE EXTENSION
\echo Use "CREATE EXTENSION collection" to load this file. \quit

-- icollection type
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

-- icollection functions

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

CREATE FUNCTION delete(collection)
    RETURNS collection
    AS 'MODULE_PATHNAME', 'collection_delete_all'
    LANGUAGE C;

CREATE FUNCTION delete(icollection)
    RETURNS icollection
    AS 'MODULE_PATHNAME', 'icollection_delete_all'
    LANGUAGE C;
