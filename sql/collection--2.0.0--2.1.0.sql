-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION collection UPDATE TO '2.1.0'" to load this file. \quit

-- Generic function (works with any array type via explicit call)
CREATE FUNCTION to_icollection(anyarray)
    RETURNS icollection
    AS 'MODULE_PATHNAME', 'icollection_from_array'
    LANGUAGE C STABLE STRICT PARALLEL SAFE;

-- Type-specific overloads for assignment casts
CREATE FUNCTION to_icollection_int4(int[])
    RETURNS icollection
    AS 'MODULE_PATHNAME', 'icollection_from_array'
    LANGUAGE C STABLE STRICT PARALLEL SAFE;

CREATE FUNCTION to_icollection_int8(bigint[])
    RETURNS icollection
    AS 'MODULE_PATHNAME', 'icollection_from_array'
    LANGUAGE C STABLE STRICT PARALLEL SAFE;

CREATE FUNCTION to_icollection_numeric(numeric[])
    RETURNS icollection
    AS 'MODULE_PATHNAME', 'icollection_from_array'
    LANGUAGE C STABLE STRICT PARALLEL SAFE;

CREATE FUNCTION to_icollection_text(text[])
    RETURNS icollection
    AS 'MODULE_PATHNAME', 'icollection_from_array'
    LANGUAGE C STABLE STRICT PARALLEL SAFE;

CREATE FUNCTION to_icollection_bool(boolean[])
    RETURNS icollection
    AS 'MODULE_PATHNAME', 'icollection_from_array'
    LANGUAGE C STABLE STRICT PARALLEL SAFE;

CREATE FUNCTION to_icollection_float8(float8[])
    RETURNS icollection
    AS 'MODULE_PATHNAME', 'icollection_from_array'
    LANGUAGE C STABLE STRICT PARALLEL SAFE;

CREATE FUNCTION to_icollection_timestamp(timestamp[])
    RETURNS icollection
    AS 'MODULE_PATHNAME', 'icollection_from_array'
    LANGUAGE C STABLE STRICT PARALLEL SAFE;

CREATE FUNCTION to_icollection_timestamptz(timestamptz[])
    RETURNS icollection
    AS 'MODULE_PATHNAME', 'icollection_from_array'
    LANGUAGE C STABLE STRICT PARALLEL SAFE;

-- Assignment casts: array -> icollection
-- Uses AS ASSIGNMENT so casts fire for PL/pgSQL assignment (v := ARRAY[...])
-- but not in arbitrary expression contexts.
CREATE CAST (int[] AS icollection)
    WITH FUNCTION to_icollection_int4(int[]) AS ASSIGNMENT;

CREATE CAST (bigint[] AS icollection)
    WITH FUNCTION to_icollection_int8(bigint[]) AS ASSIGNMENT;

CREATE CAST (numeric[] AS icollection)
    WITH FUNCTION to_icollection_numeric(numeric[]) AS ASSIGNMENT;

CREATE CAST (text[] AS icollection)
    WITH FUNCTION to_icollection_text(text[]) AS ASSIGNMENT;

CREATE CAST (boolean[] AS icollection)
    WITH FUNCTION to_icollection_bool(boolean[]) AS ASSIGNMENT;

CREATE CAST (float8[] AS icollection)
    WITH FUNCTION to_icollection_float8(float8[]) AS ASSIGNMENT;

CREATE CAST (timestamp[] AS icollection)
    WITH FUNCTION to_icollection_timestamp(timestamp[]) AS ASSIGNMENT;

CREATE CAST (timestamptz[] AS icollection)
    WITH FUNCTION to_icollection_timestamptz(timestamptz[]) AS ASSIGNMENT;

-- to_array: icollection -> array conversion
CREATE FUNCTION to_array(icollection)
    RETURNS text[]
    AS 'MODULE_PATHNAME', 'icollection_to_array'
    LANGUAGE C STABLE STRICT PARALLEL SAFE;

CREATE FUNCTION to_array(icollection, anyelement)
    RETURNS anyarray
    AS 'MODULE_PATHNAME', 'icollection_to_array'
    LANGUAGE C STABLE STRICT PARALLEL SAFE;
