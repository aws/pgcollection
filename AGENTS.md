# AGENTS.md

Guidance for AI agents (and new contributors) working on the pgcollection
source. For what the extension does and how to use it, read `README.md` and
`doc/`. This file covers how to change it safely.

## What this is

A PostgreSQL extension written in C (PGXS build) that provides two in-memory
associative array types for PL/pgSQL: `collection` (text keys) and
`icollection` (bigint keys). Requires PostgreSQL 14 or later.

## Layout

- `src/` C implementation. Files are split by type and concern, e.g.
  `collection.c`, `collection_io.c`, `collection_userfuncs.c`,
  `collection_subs.c`, `collection_parse.c`, and the `icollection_*.c`
  counterparts.
- `include/` headers, including the shared `collection.h`.
- `sql/` extension install and upgrade scripts (`collection--X--Y.sql`).
- `test/sql/` regression inputs, `test/expected/` their expected output.
- `doc/` user-facing documentation.

## Build and test

```sh
make
make install
make installcheck
```

If `pg_config` is not on `PATH`, point at a specific server:

```sh
make PG_CONFIG=/path/to/pg/bin/pg_config install
```

The regression suite is the `REGRESS` list in the `Makefile`. When behavior
changes, update the matching file in `test/expected/` (or regenerate it) so
`installcheck` passes.

## Code style

C code must pass `pgindent` with the upstream `typedefs.list`; CI fails on any
diff (see `.github/workflows/test.yml`). `include/uthash/uthash.h` is excluded
via `tools/pgindent_excludes`. Match the surrounding style, prefer `psprintf`
over manual `palloc` + `sprintf`.

## The two types mirror each other

Almost every feature exists twice: once for `collection` (text keys, `src/collection*.c`)
and once for `icollection` (bigint keys, `src/icollection*.c`), with parallel
SQL declarations. A change to one type almost always needs the same change to
its twin. Check both before considering a change complete.

## Versioning and migrations

This is the easiest thing to get wrong.

- The version lives in three places that must stay in sync: `EXTVERSION` in the
  `Makefile`, `collection.control.in`, and `META.json.in`.
- Released migration scripts are frozen. Never edit a `sql/collection--X--Y.sql`
  that has shipped; a database that already applied it will not re-run it.
  Instead add a new `sql/collection--Y--Z.sql` and bump the version.
- The current in-development version can still be edited freely until it is
  tagged. Check `git tag` to see what has actually been released; the highest
  tag is the last shipped version, and `default_version` in the control file
  may already point past it at the unreleased work in progress.

## Adding or changing a SQL-visible function

A change is not complete until all of these agree:

1. The C implementation in `src/` (and its twin, if the other type applies).
2. The SQL declaration in the appropriate migration script.
3. A `COMMENT ON` entry in the same migration. Every extension object carries a
   terse catalog comment so an installed database is self-describing; do not
   leave a new function blank.
4. An entry in `doc/functions.md`.
5. A regression test in `test/sql/` with expected output in `test/expected/`.
