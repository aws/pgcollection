-- complain if script is sourced in psql, rather than via CREATE EXTENSION
\echo Use "ALTER EXTENSION collection UPDATE TO '1.1.0'" to load this file. \quit

CREATE FUNCTION last(collection) 
  RETURNS collection 
  AS 'MODULE_PATHNAME', 'collection_last'
  LANGUAGE c; 

