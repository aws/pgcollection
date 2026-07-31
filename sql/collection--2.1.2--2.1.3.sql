-- complain if script is sourced in psql, rather than via CREATE EXTENSION
\echo Use "ALTER EXTENSION collection UPDATE TO '2.1.3'" to load this file. \quit

-- Allow a typed NULL to be passed as the second argument so callers can
-- select the array element type without constructing a dummy value.  The
-- underlying C function only uses the argument's type, never its value, and
-- already guards against a NULL first argument, so dropping STRICT is safe.
CREATE OR REPLACE FUNCTION to_array(icollection, anyelement)
    RETURNS anyarray
    AS 'MODULE_PATHNAME', 'icollection_to_array'
    LANGUAGE C STABLE CALLED ON NULL INPUT PARALLEL SAFE;
