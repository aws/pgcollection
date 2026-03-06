-- complain if script is sourced in psql, rather than via CREATE EXTENSION
\echo Use "CREATE EXTENSION collection" to load this file. \quit

-- icollection type
CREATE TYPE icollection;

CREATE FUNCTION icollection_in(cstring, oid, integer)
    RETURNS icollection
    AS 'MODULE_PATHNAME'
    LANGUAGE C IMMUTABLE STRICT;

CREATE FUNCTION icollection_out(icollection)
    RETURNS cstring
    AS 'MODULE_PATHNAME'
    LANGUAGE C IMMUTABLE STRICT;

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
    LANGUAGE C STRICT IMMUTABLE;

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
    LANGUAGE C IMMUTABLE;

CREATE FUNCTION find(icollection, bigint)
    RETURNS text
    AS 'MODULE_PATHNAME', 'icollection_find'
    LANGUAGE C IMMUTABLE STRICT;

CREATE FUNCTION exist(icollection, bigint)
    RETURNS boolean
    AS 'MODULE_PATHNAME', 'icollection_exist'
    LANGUAGE C IMMUTABLE;

CREATE FUNCTION count(icollection)
    RETURNS integer
    AS 'MODULE_PATHNAME', 'icollection_count'
    LANGUAGE C IMMUTABLE STRICT;

CREATE FUNCTION delete(icollection, bigint)
    RETURNS icollection
    AS 'MODULE_PATHNAME', 'icollection_delete'
    LANGUAGE C IMMUTABLE STRICT;

CREATE FUNCTION first(icollection)
    RETURNS icollection
    AS 'MODULE_PATHNAME', 'icollection_first'
    LANGUAGE C IMMUTABLE STRICT;

CREATE FUNCTION last(icollection)
    RETURNS icollection
    AS 'MODULE_PATHNAME', 'icollection_last'
    LANGUAGE C IMMUTABLE STRICT;

CREATE FUNCTION next(icollection)
    RETURNS icollection
    AS 'MODULE_PATHNAME', 'icollection_next'
    LANGUAGE C IMMUTABLE STRICT;

CREATE FUNCTION prev(icollection)
    RETURNS icollection
    AS 'MODULE_PATHNAME', 'icollection_prev'
    LANGUAGE C IMMUTABLE STRICT;

CREATE FUNCTION key(icollection)
    RETURNS bigint
    AS 'MODULE_PATHNAME', 'icollection_key'
    LANGUAGE C IMMUTABLE STRICT;

CREATE FUNCTION value(icollection)
    RETURNS text
    AS 'MODULE_PATHNAME', 'icollection_value'
    LANGUAGE C IMMUTABLE STRICT;

CREATE FUNCTION isnull(icollection)
    RETURNS boolean
    AS 'MODULE_PATHNAME', 'icollection_isnull'
    LANGUAGE C IMMUTABLE STRICT;

CREATE FUNCTION sort(icollection)
    RETURNS icollection
    AS 'MODULE_PATHNAME', 'icollection_sort'
    LANGUAGE C IMMUTABLE STRICT;

CREATE FUNCTION copy(icollection)
    RETURNS icollection
    AS 'MODULE_PATHNAME', 'icollection_copy'
    LANGUAGE C IMMUTABLE STRICT;

CREATE FUNCTION value_type(icollection)
    RETURNS oid
    AS 'MODULE_PATHNAME', 'icollection_value_type'
    LANGUAGE C IMMUTABLE STRICT;

CREATE FUNCTION keys_to_table(icollection)
    RETURNS SETOF bigint
    AS 'MODULE_PATHNAME', 'icollection_keys_to_table'
    LANGUAGE C IMMUTABLE STRICT;

CREATE FUNCTION values_to_table(icollection)
    RETURNS SETOF text
    AS 'MODULE_PATHNAME', 'icollection_values_to_table'
    LANGUAGE C IMMUTABLE STRICT;

CREATE FUNCTION to_table(icollection, OUT key bigint, OUT value text)
    RETURNS SETOF record
    AS 'MODULE_PATHNAME', 'icollection_to_table'
    LANGUAGE C IMMUTABLE STRICT;

CREATE FUNCTION next_key(icollection, bigint)
    RETURNS bigint
    AS 'MODULE_PATHNAME', 'icollection_next_key'
    LANGUAGE C STRICT;

CREATE FUNCTION prev_key(icollection, bigint)
    RETURNS bigint
    AS 'MODULE_PATHNAME', 'icollection_prev_key'
    LANGUAGE C STRICT;

CREATE FUNCTION first_key(icollection)
    RETURNS bigint
    AS 'MODULE_PATHNAME', 'icollection_first_key'
    LANGUAGE C STRICT;

CREATE FUNCTION last_key(icollection)
    RETURNS bigint
    AS 'MODULE_PATHNAME', 'icollection_last_key'
    LANGUAGE C STRICT;
