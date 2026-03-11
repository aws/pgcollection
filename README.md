# pgcollection

pgcollection is a PostgreSQL extension that provides associative array data types for use in PL/pgSQL. It is modeled after Oracle PL/SQL Associative Arrays (`TABLE OF ... INDEX BY`), supporting the same core operations, though there are [behavioral differences](doc/oracle-migration.md#differences-from-oracle) to be aware of when migrating.

Two types are provided:

- **`collection`** — text-keyed (`INDEX BY VARCHAR2` equivalent)
- **`icollection`** — 64-bit integer-keyed (`INDEX BY PLS_INTEGER` equivalent)

Both types support subscript access, forward/reverse iteration, sorted traversal, existence checks, and set-returning functions. Values can be any PostgreSQL type (default is `text`). Collections are stored in memory using PostgreSQL's expanded object API and can also be persisted to table columns.

## Examples

### collection (text keys)

```sql
DO $$
DECLARE
  capitals  collection;
BEGIN
  capitals['USA']            := 'Washington, D.C.';
  capitals['United Kingdom'] := 'London';
  capitals['Japan']          := 'Tokyo';

  RAISE NOTICE 'Capital of USA: %', capitals['USA'];
  RAISE NOTICE 'Count: %', count(capitals);

  capitals := sort(capitals);
  WHILE NOT isnull(capitals) LOOP
    RAISE NOTICE '% => %', key(capitals), value(capitals);
    capitals := next(capitals);
  END LOOP;
END $$;
```

### icollection (integer keys)

```sql
DO $$
DECLARE
  sparse  icollection('text');
BEGIN
  sparse[1]       := 'first';
  sparse[1000]    := 'thousandth';
  sparse[1000000] := 'millionth';

  RAISE NOTICE 'Count: %', count(sparse);       -- 3
  RAISE NOTICE 'Value at 1000: %', sparse[1000];
  RAISE NOTICE 'Key 500 exists: %', exist(sparse, 500);  -- false
END $$;
```

### Bulk DML using set-returning functions

```sql
DO $$
DECLARE
  capitals  collection;
BEGIN
  capitals['USA']   := 'Washington, D.C.';
  capitals['Japan'] := 'Tokyo';

  UPDATE countries
     SET capital = col.value
    FROM to_table(capitals) AS col
   WHERE countries.name = col.key;
END $$;
```

## Installation

Requires PostgreSQL 14 or later.

```sh
git clone https://github.com/aws/pgcollection.git
cd pgcollection
make
make install
```

Then in each database:

```sql
CREATE EXTENSION collection;
```

## Oracle Associative Array Mapping

| Oracle | pgcollection |
|---|---|
| `TYPE t IS TABLE OF VARCHAR2(100) INDEX BY VARCHAR2(50)` | `collection` or `collection('text')` |
| `TYPE t IS TABLE OF NUMBER INDEX BY PLS_INTEGER` | `icollection('numeric')` |
| `v('key')` | `v['key']` or `find(v, 'key')` |
| `v('key') := val` | `v['key'] := val` or `add(v, 'key', val)` |
| `v.COUNT` | `count(v)` |
| `v.EXISTS('key')` | `exist(v, 'key')` |
| `v.DELETE('key')` | `v := delete(v, 'key')` |
| `v.FIRST` / `v.LAST` | `first_key(v)` / `last_key(v)` |
| `v.NEXT(k)` / `v.PRIOR(k)` | `next_key(v, k)` / `prev_key(v, k)` |

See the [Oracle Migration Guide](doc/oracle-migration.md) for detailed side-by-side examples.

## Documentation

- [Oracle Migration Guide](doc/oracle-migration.md) — translating Oracle PL/SQL associative array patterns to pgcollection
- [Usage Guide](doc/usage.md) — subscripts, type modifiers, iteration, set-returning functions, bulk operations
- [Function Reference](doc/functions.md) — complete function list for both types
- [Observability](doc/observability.md) — wait events and session statistics

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for how to report issues, set up a development environment, and submit code.

We adhere to the [Amazon Open Source Code of Conduct](https://aws.github.io/code-of-conduct).

## Security

See [CONTRIBUTING.md](CONTRIBUTING.md#security-issue-notifications) for more information.

## License

This project is licensed under the Apache-2.0 License.

## Acknowledgements

pgcollection uses [uthash](https://github.com/troydhanson/uthash) for its hash table implementation.
