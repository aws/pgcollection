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

-- ============================================================================
-- Object comments
--
-- Terse catalog descriptions so the extension self-documents under \dT+, \df+,
-- \dv+ and pg_description, matching the convention followed by PostgreSQL's
-- built-in objects.  The type comments carry the non-obvious usage model
-- (subscripts + the sort/first/next iteration cursor); every other comment is
-- a short label, not a substitute for doc/functions.md.
-- ============================================================================

-- Types
COMMENT ON TYPE collection IS
  'text-keyed associative array for PL/pgSQL; subscript with v[''k''], iterate with sort/first/next + key/value/isnull';
COMMENT ON TYPE icollection IS
  'bigint-keyed associative array for PL/pgSQL; subscript with v[i], iterate with sort/first/next + key/value/isnull';

-- collection: I/O and type-support plumbing
COMMENT ON FUNCTION collection_in(cstring) IS 'I/O';
COMMENT ON FUNCTION collection_out(collection) IS 'I/O';
COMMENT ON FUNCTION collection_typmodin(cstring[]) IS 'I/O typmod';
COMMENT ON FUNCTION collection_typmodout(integer) IS 'I/O typmod';
COMMENT ON FUNCTION collection_subscript_handler(internal) IS 'subscript handler';
COMMENT ON FUNCTION collection(collection, integer) IS 'typmod coercion';

-- collection: element access
COMMENT ON FUNCTION add(collection, text, anyelement) IS 'add or update element';
COMMENT ON FUNCTION add(collection, text, text) IS 'add or update element';
COMMENT ON FUNCTION find(collection, text, anyelement) IS 'get element value (typed)';
COMMENT ON FUNCTION find(collection, text) IS 'get element value';
COMMENT ON FUNCTION exist(collection, text) IS 'true if key exists';
COMMENT ON FUNCTION count(collection) IS 'element count';
COMMENT ON FUNCTION delete(collection, text) IS 'delete element by key';
COMMENT ON FUNCTION delete(collection, text, text) IS 'delete key range';
COMMENT ON FUNCTION delete(collection) IS 'delete all elements';
COMMENT ON FUNCTION sort(collection) IS 'return key-sorted copy';
COMMENT ON FUNCTION copy(collection) IS 'return deep copy';
COMMENT ON FUNCTION value_type(collection) IS 'element value type';

-- collection: iteration cursor
COMMENT ON FUNCTION first(collection) IS 'position cursor at first element';
COMMENT ON FUNCTION last(collection) IS 'position cursor at last element';
COMMENT ON FUNCTION next(collection) IS 'advance iteration cursor';
COMMENT ON FUNCTION prev(collection) IS 'move cursor to previous element';
COMMENT ON FUNCTION key(collection) IS 'key at iteration cursor';
COMMENT ON FUNCTION value(collection, anyelement) IS 'value at cursor (typed)';
COMMENT ON FUNCTION value(collection) IS 'value at cursor';
COMMENT ON FUNCTION isnull(collection) IS 'true when cursor past last element';
COMMENT ON FUNCTION first_key(collection) IS 'first (lowest) key';
COMMENT ON FUNCTION last_key(collection) IS 'last (highest) key';
COMMENT ON FUNCTION next_key(collection, text) IS 'next key after given key';
COMMENT ON FUNCTION prev_key(collection, text) IS 'previous key before given key';

-- collection: set-returning
COMMENT ON FUNCTION keys_to_table(collection) IS 'expand keys to rows';
COMMENT ON FUNCTION values_to_table(collection) IS 'expand values to rows';
COMMENT ON FUNCTION values_to_table(collection, anyelement) IS 'expand values to rows (typed)';
COMMENT ON FUNCTION to_table(collection) IS 'expand to (key, value) rows';
COMMENT ON FUNCTION to_table(collection, anyelement) IS 'expand to (key, value) rows (typed)';

-- icollection: I/O and type-support plumbing
COMMENT ON FUNCTION icollection_in(cstring, oid, integer) IS 'I/O';
COMMENT ON FUNCTION icollection_out(icollection) IS 'I/O';
COMMENT ON FUNCTION icollection_typmodin(cstring[]) IS 'I/O typmod';
COMMENT ON FUNCTION icollection_typmodout(integer) IS 'I/O typmod';
COMMENT ON FUNCTION icollection_subscript_handler(internal) IS 'subscript handler';
COMMENT ON FUNCTION icollection(icollection, integer) IS 'typmod coercion';

-- icollection: element access
COMMENT ON FUNCTION add(icollection, bigint, anyelement) IS 'add or update element';
COMMENT ON FUNCTION add(icollection, bigint, text) IS 'add or update element';
COMMENT ON FUNCTION find(icollection, bigint, anyelement) IS 'get element value (typed)';
COMMENT ON FUNCTION find(icollection, bigint) IS 'get element value';
COMMENT ON FUNCTION exist(icollection, bigint) IS 'true if key exists';
COMMENT ON FUNCTION count(icollection) IS 'element count';
COMMENT ON FUNCTION delete(icollection, bigint) IS 'delete element by key';
COMMENT ON FUNCTION delete(icollection, bigint, bigint) IS 'delete key range';
COMMENT ON FUNCTION delete(icollection) IS 'delete all elements';
COMMENT ON FUNCTION sort(icollection) IS 'return key-sorted copy';
COMMENT ON FUNCTION copy(icollection) IS 'return deep copy';
COMMENT ON FUNCTION value_type(icollection) IS 'element value type';

-- icollection: iteration cursor
COMMENT ON FUNCTION first(icollection) IS 'position cursor at first element';
COMMENT ON FUNCTION last(icollection) IS 'position cursor at last element';
COMMENT ON FUNCTION next(icollection) IS 'advance iteration cursor';
COMMENT ON FUNCTION prev(icollection) IS 'move cursor to previous element';
COMMENT ON FUNCTION key(icollection) IS 'key at iteration cursor';
COMMENT ON FUNCTION value(icollection, anyelement) IS 'value at cursor (typed)';
COMMENT ON FUNCTION value(icollection) IS 'value at cursor';
COMMENT ON FUNCTION isnull(icollection) IS 'true when cursor past last element';
COMMENT ON FUNCTION first_key(icollection) IS 'first (lowest) key';
COMMENT ON FUNCTION last_key(icollection) IS 'last (highest) key';
COMMENT ON FUNCTION next_key(icollection, bigint) IS 'next key after given key';
COMMENT ON FUNCTION prev_key(icollection, bigint) IS 'previous key before given key';

-- icollection: set-returning
COMMENT ON FUNCTION keys_to_table(icollection) IS 'expand keys to rows';
COMMENT ON FUNCTION values_to_table(icollection) IS 'expand values to rows';
COMMENT ON FUNCTION values_to_table(icollection, anyelement) IS 'expand values to rows (typed)';
COMMENT ON FUNCTION to_table(icollection) IS 'expand to (key, value) rows';
COMMENT ON FUNCTION to_table(icollection, anyelement) IS 'expand to (key, value) rows (typed)';

-- icollection: array interop
COMMENT ON FUNCTION to_icollection(anyarray) IS 'build icollection from array (1-based keys)';
COMMENT ON FUNCTION to_icollection_int4(int[]) IS 'array to icollection (assignment cast)';
COMMENT ON FUNCTION to_icollection_int8(bigint[]) IS 'array to icollection (assignment cast)';
COMMENT ON FUNCTION to_icollection_numeric(numeric[]) IS 'array to icollection (assignment cast)';
COMMENT ON FUNCTION to_icollection_text(text[]) IS 'array to icollection (assignment cast)';
COMMENT ON FUNCTION to_icollection_bool(boolean[]) IS 'array to icollection (assignment cast)';
COMMENT ON FUNCTION to_icollection_float8(float8[]) IS 'array to icollection (assignment cast)';
COMMENT ON FUNCTION to_icollection_timestamp(timestamp[]) IS 'array to icollection (assignment cast)';
COMMENT ON FUNCTION to_icollection_timestamptz(timestamptz[]) IS 'array to icollection (assignment cast)';
COMMENT ON FUNCTION to_array(icollection) IS 'return values as text array ordered by key';
COMMENT ON FUNCTION to_array(icollection, anyelement) IS 'return values as typed array ordered by key';

-- Session statistics
COMMENT ON VIEW collection_stats IS 'session operation counters';
COMMENT ON FUNCTION collection_stats() IS 'session operation counters';
COMMENT ON FUNCTION collection_stats_reset() IS 'reset session operation counters';
