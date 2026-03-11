# Migrating Oracle Associative Arrays to pgcollection

This guide covers translating Oracle PL/SQL Associative Arrays (`TABLE OF ... INDEX BY`) to pgcollection's `collection` and `icollection` types. While the core operations are similar, there are [behavioral differences](#differences-from-oracle) that may require code changes during migration.

## Type Mapping

| Oracle Declaration | pgcollection Equivalent |
|---|---|
| `TYPE t IS TABLE OF VARCHAR2(100) INDEX BY VARCHAR2(50);` | `collection` or `collection('text')` |
| `TYPE t IS TABLE OF VARCHAR2(100) INDEX BY PLS_INTEGER;` | `icollection` or `icollection('text')` |
| `TYPE t IS TABLE OF NUMBER INDEX BY VARCHAR2(50);` | `collection('numeric')` |
| `TYPE t IS TABLE OF NUMBER INDEX BY PLS_INTEGER;` | `icollection('numeric')` |
| `TYPE t IS TABLE OF DATE INDEX BY VARCHAR2(50);` | `collection('date')` |
| `TYPE t IS TABLE OF my_record INDEX BY PLS_INTEGER;` | `icollection('my_composite_type')` |

Key differences:
- Oracle requires a separate `TYPE` declaration. pgcollection types are declared inline.
- Oracle `PLS_INTEGER` keys are 32-bit. pgcollection `icollection` keys are 64-bit (`bigint`).
- Oracle `VARCHAR2` keys have a length limit you specify. pgcollection `collection` keys support up to 32,767 characters.

## Basic Operations

### Oracle
```sql
DECLARE
  TYPE capital_t IS TABLE OF VARCHAR2(100) INDEX BY VARCHAR2(50);
  capitals  capital_t;
BEGIN
  capitals('USA')            := 'Washington, D.C.';
  capitals('United Kingdom') := 'London';
  capitals('Japan')          := 'Tokyo';

  DBMS_OUTPUT.PUT_LINE('Capital of USA: ' || capitals('USA'));
  DBMS_OUTPUT.PUT_LINE('Count: ' || capitals.COUNT);

  capitals.DELETE('Japan');
  DBMS_OUTPUT.PUT_LINE('Count after delete: ' || capitals.COUNT);
END;
```

### pgcollection
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

  capitals := delete(capitals, 'Japan');
  RAISE NOTICE 'Count after delete: %', count(capitals);
END $$;
```

The main syntactic difference: Oracle uses parentheses `capitals('key')` while pgcollection uses brackets `capitals['key']`. Oracle methods like `.COUNT` and `.DELETE()` become functions `count()` and `delete()`.

## Iteration with FIRST/NEXT

Oracle's `FIRST`, `NEXT`, `LAST`, and `PRIOR` methods map directly to pgcollection functions.

### Oracle (string-indexed)
```sql
DECLARE
  TYPE capital_t IS TABLE OF VARCHAR2(100) INDEX BY VARCHAR2(50);
  capitals  capital_t;
  k         VARCHAR2(50);
BEGIN
  capitals('USA')            := 'Washington, D.C.';
  capitals('United Kingdom') := 'London';
  capitals('Japan')          := 'Tokyo';

  k := capitals.FIRST;
  WHILE k IS NOT NULL LOOP
    DBMS_OUTPUT.PUT_LINE(k || ' => ' || capitals(k));
    k := capitals.NEXT(k);
  END LOOP;
END;
```

### pgcollection (text-keyed)

There are two ways to iterate. The key-based approach mirrors Oracle most closely:

```sql
DO $$
DECLARE
  capitals  collection;
  k         text;
BEGIN
  capitals['USA']            := 'Washington, D.C.';
  capitals['United Kingdom'] := 'London';
  capitals['Japan']          := 'Tokyo';

  -- Key-based iteration (closest to Oracle)
  k := first_key(capitals);
  WHILE k IS NOT NULL LOOP
    RAISE NOTICE '% => %', k, find(capitals, k);
    k := next_key(capitals, k);
  END LOOP;
END $$;
```

The iterator-based approach is more idiomatic for pgcollection:

```sql
DO $$
DECLARE
  capitals  collection;
BEGIN
  capitals['USA']            := 'Washington, D.C.';
  capitals['United Kingdom'] := 'London';
  capitals['Japan']          := 'Tokyo';

  -- Iterator-based (pgcollection-native)
  capitals := first(capitals);
  WHILE NOT isnull(capitals) LOOP
    RAISE NOTICE '% => %', key(capitals), value(capitals);
    capitals := next(capitals);
  END LOOP;
END $$;
```

### Oracle (integer-indexed)
```sql
DECLARE
  TYPE num_arr IS TABLE OF VARCHAR2(100) INDEX BY PLS_INTEGER;
  arr  num_arr;
  i    PLS_INTEGER;
BEGIN
  arr(1)    := 'first';
  arr(1000) := 'thousandth';
  arr(5000) := 'five-thousandth';

  i := arr.FIRST;
  WHILE i IS NOT NULL LOOP
    DBMS_OUTPUT.PUT_LINE(i || ' => ' || arr(i));
    i := arr.NEXT(i);
  END LOOP;
END;
```

### pgcollection (integer-keyed)
```sql
DO $$
DECLARE
  arr  icollection('text');
  k    bigint;
BEGIN
  arr[1]    := 'first';
  arr[1000] := 'thousandth';
  arr[5000] := 'five-thousandth';

  k := first_key(arr);
  WHILE k IS NOT NULL LOOP
    RAISE NOTICE '% => %', k, find(arr, k);
    k := next_key(arr, k);
  END LOOP;
END $$;
```

## EXISTS Method

Oracle's `.EXISTS()` maps to `exist()`:

### Oracle
```sql
IF capitals.EXISTS('Japan') THEN
  DBMS_OUTPUT.PUT_LINE('Found Japan');
END IF;
```

### pgcollection
```sql
IF exist(capitals, 'Japan') THEN
  RAISE NOTICE 'Found Japan';
END IF;
```

## Sorted Iteration

This is one of the most important [differences from Oracle](#differences-from-oracle). Oracle Associative Arrays with `VARCHAR2` keys are automatically sorted in key order. pgcollection stores entries in insertion order by default. Use `sort()` to get key-ordered iteration:

### Oracle
```sql
-- Oracle: VARCHAR2-indexed arrays are always sorted by key
k := capitals.FIRST;  -- returns 'Japan' (alphabetical first)
```

### pgcollection
```sql
-- pgcollection: explicit sort needed
capitals := sort(capitals);
-- sort() positions the iterator at the first sorted element
-- key(capitals) now returns 'Japan'
```

To iterate in reverse sorted order, call `last()` after `sort()`:

```sql
capitals := sort(capitals);
capitals := last(capitals);
-- key(capitals) now returns 'United Kingdom' (alphabetical last)
WHILE NOT isnull(capitals) LOOP
  RAISE NOTICE '% => %', key(capitals), value(capitals);
  capitals := prev(capitals);
END LOOP;
```

For `icollection`, `sort()` orders keys numerically (ascending), matching Oracle's `PLS_INTEGER`-indexed behavior.

## Bulk Loading from a Query

A common Oracle pattern is loading query results into an Associative Array for repeated lookups.

### Oracle
```sql
DECLARE
  TYPE emp_t IS TABLE OF employees%ROWTYPE INDEX BY PLS_INTEGER;
  emps  emp_t;
  CURSOR c IS SELECT * FROM employees WHERE department_id = 10;
BEGIN
  FOR r IN c LOOP
    emps(r.employee_id) := r;
  END LOOP;

  DBMS_OUTPUT.PUT_LINE('Employee name: ' || emps(100).last_name);
END;
```

### pgcollection
```sql
DO $$
DECLARE
  r     pg_class%ROWTYPE;
  rels  collection('pg_class');
BEGIN
  FOR r IN SELECT * FROM pg_class WHERE relkind = 'r' LOOP
    rels[r.relname] := r;
  END LOOP;

  RAISE NOTICE 'Owner of pg_type: %', rels['pg_type'].relowner::regrole;
END $$;
```

## Bulk DML with Set-Returning Functions

Oracle code that iterates over an Associative Array to perform DML can be replaced with a single statement using pgcollection's set-returning functions.

### Oracle
```sql
DECLARE
  TYPE capital_t IS TABLE OF VARCHAR2(100) INDEX BY VARCHAR2(50);
  capitals  capital_t;
  k         VARCHAR2(50);
BEGIN
  capitals('USA')    := 'Washington, D.C.';
  capitals('Japan')  := 'Tokyo';

  k := capitals.FIRST;
  WHILE k IS NOT NULL LOOP
    UPDATE countries SET capital = capitals(k) WHERE name = k;
    k := capitals.NEXT(k);
  END LOOP;
END;
```

### pgcollection
```sql
DO $$
DECLARE
  capitals  collection;
BEGIN
  capitals['USA']   := 'Washington, D.C.';
  capitals['Japan'] := 'Tokyo';

  -- Single statement, no loop needed
  UPDATE countries
     SET capital = col.value
    FROM to_table(capitals) AS col
   WHERE countries.name = col.key;
END $$;
```

This eliminates context switching between PL/pgSQL and the SQL engine for each row.

## Passing Collections as Parameters

Oracle procedures commonly accept Associative Arrays as IN, OUT, or IN OUT parameters. pgcollection supports all three patterns.

### Oracle
```sql
CREATE OR REPLACE PROCEDURE add_employee(
  p_emps  IN OUT  emp_array_t,
  p_id    IN      PLS_INTEGER,
  p_name  IN      VARCHAR2
) AS
BEGIN
  p_emps(p_id) := p_name;
END;
```

### pgcollection

Functions can accept and return collections. Use `INOUT` parameters with procedures for the IN OUT pattern:

```sql
CREATE OR REPLACE PROCEDURE add_employee(
  INOUT p_emps  icollection('text'),
  p_id           bigint,
  p_name         text
) AS $$
BEGIN
  p_emps[p_id] := p_name;
END;
$$ LANGUAGE plpgsql;

DO $$
DECLARE
  emps  icollection('text');
BEGIN
  CALL add_employee(emps, 101, 'Alice');
  CALL add_employee(emps, 102, 'Bob');
  RAISE NOTICE 'Count: %', count(emps);
  RAISE NOTICE 'Employee 101: %', find(emps, 101);
END $$;
```

Functions can also return collections directly:

```sql
CREATE OR REPLACE FUNCTION build_lookup()
RETURNS collection AS $$
DECLARE
  c  collection;
BEGIN
  c['a'] := 'alpha';
  c['b'] := 'bravo';
  RETURN c;
END;
$$ LANGUAGE plpgsql;

DO $$
DECLARE
  c  collection;
BEGIN
  c := build_lookup();
  RAISE NOTICE 'a = %', find(c, 'a');
END $$;
```

## Record Types as Values

Oracle code frequently stores record types in Associative Arrays. pgcollection supports this using PostgreSQL composite types.

### Oracle
```sql
DECLARE
  TYPE emp_rec IS RECORD (
    name    VARCHAR2(100),
    dept    VARCHAR2(50),
    salary  NUMBER
  );
  TYPE emp_arr IS TABLE OF emp_rec INDEX BY PLS_INTEGER;
  emps  emp_arr;
BEGIN
  emps(1).name   := 'Alice';
  emps(1).dept   := 'Engineering';
  emps(1).salary := 120000;

  DBMS_OUTPUT.PUT_LINE(emps(1).name || ': ' || emps(1).salary);
END;
```

### pgcollection

Define a composite type first, then use it as the type modifier:

```sql
CREATE TYPE emp_rec AS (name text, dept text, salary numeric);

DO $$
DECLARE
  emps  collection('emp_rec');
  e     emp_rec;
BEGIN
  emps['E001'] := ROW('Alice', 'Engineering', 120000)::emp_rec;
  emps['E002'] := ROW('Bob', 'Sales', 95000)::emp_rec;

  -- Retrieve the full record
  e := find(emps, 'E001', NULL::emp_rec);
  RAISE NOTICE 'Name: %, Salary: %', e.name, e.salary;

  -- Access fields directly through subscript
  RAISE NOTICE 'E002 name: %', emps['E002'].name;
END $$;
```

Note: Oracle allows field assignment on the AA element directly (`emps(1).name := 'Alice'`). In pgcollection, assign the entire composite value at once using `ROW()`.

## Lookup Cache Pattern

One of the most common uses of Oracle Associative Arrays is building an in-memory lookup cache at the start of a procedure to avoid repeated table access.

### Oracle
```sql
DECLARE
  TYPE dept_cache_t IS TABLE OF VARCHAR2(100) INDEX BY PLS_INTEGER;
  dept_names  dept_cache_t;
BEGIN
  FOR r IN (SELECT department_id, department_name FROM departments) LOOP
    dept_names(r.department_id) := r.department_name;
  END LOOP;

  -- Now use dept_names(id) throughout the procedure
  -- instead of querying departments each time
  DBMS_OUTPUT.PUT_LINE('Dept 10: ' || dept_names(10));
END;
```

### pgcollection
```sql
DO $$
DECLARE
  r           record;
  nsp_cache   icollection('text');
BEGIN
  FOR r IN SELECT oid, nspname FROM pg_namespace LOOP
    nsp_cache[r.oid] := r.nspname;
  END LOOP;

  RAISE NOTICE 'Cache size: %', count(nsp_cache);
  RAISE NOTICE 'Namespace 11: %', find(nsp_cache, 11);
END $$;
```

## FORALL Bulk DML

Oracle's `FORALL` statement performs bulk DML using Associative Array indices. pgcollection achieves the same result using `to_table()` in a single SQL statement.

### Oracle
```sql
DECLARE
  TYPE id_arr   IS TABLE OF PLS_INTEGER INDEX BY PLS_INTEGER;
  TYPE name_arr IS TABLE OF VARCHAR2(100) INDEX BY PLS_INTEGER;
  ids    id_arr;
  names  name_arr;
BEGIN
  ids(1) := 101;  names(1) := 'Alice';
  ids(2) := 102;  names(2) := 'Bob';
  ids(3) := 103;  names(3) := 'Charlie';

  FORALL i IN 1..ids.COUNT
    INSERT INTO employees (id, name) VALUES (ids(i), names(i));
END;
```

### pgcollection

Use `to_table()` to turn the collection into a result set for the DML:

```sql
DO $$
DECLARE
  emps  icollection('text');
BEGIN
  emps[101] := 'Alice';
  emps[102] := 'Bob';
  emps[103] := 'Charlie';

  INSERT INTO employees (id, name)
    SELECT key, value FROM to_table(emps);
END $$;
```

This is a single statement — no loop, no per-row context switch.

## Exception Handling

Oracle raises `NO_DATA_FOUND` when accessing a non-existent key. pgcollection does the same, so existing exception handling patterns translate directly.

### Oracle
```sql
DECLARE
  TYPE arr_t IS TABLE OF VARCHAR2(100) INDEX BY VARCHAR2(50);
  arr  arr_t;
  val  VARCHAR2(100);
BEGIN
  arr('a') := 'alpha';
  BEGIN
    val := arr('missing');
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      DBMS_OUTPUT.PUT_LINE('Key not found');
  END;
END;
```

### pgcollection
```sql
DO $$
DECLARE
  c    collection;
  val  text;
BEGIN
  c['a'] := 'alpha';
  BEGIN
    val := c['missing'];
  EXCEPTION
    WHEN no_data_found THEN
      RAISE NOTICE 'Key not found';
  END;
END $$;
```

Use `exist()` to avoid the exception when the key may not be present:

```sql
IF exist(c, 'missing') THEN
  val := c['missing'];
ELSE
  val := 'default';
END IF;
```

## Differences from Oracle

pgcollection is modeled after Oracle Associative Arrays but is not identical. The following differences may require code changes during migration.

### Iteration order

Oracle Associative Arrays are always sorted by key — alphabetically for `VARCHAR2` keys, numerically for `PLS_INTEGER` keys. `FIRST` returns the lowest key, `NEXT` returns the next key in sorted order.

pgcollection stores entries in insertion order by default. `first_key()` returns the first key *inserted*, not the lowest. To get Oracle's sorted behavior, call `sort()` before iterating. `sort()` also positions the iterator at the first sorted element, so there is no need to call `first()` afterward:

```sql
-- Oracle: capitals.FIRST always returns 'Japan' (alphabetical first)
-- pgcollection: first_key(capitals) returns whatever was inserted first
capitals := sort(capitals);
-- Iterator is now at 'Japan' (alphabetical first)
```

This applies to both `collection` and `icollection`. If your Oracle code relies on sorted iteration order (which is most code using `FIRST`/`NEXT` loops), add a `sort()` call before iterating.

### Methods vs functions

Oracle Associative Array operations are methods on the variable (`v.COUNT`, `v.DELETE('key')`, `v.EXISTS('key')`). pgcollection uses standalone functions (`count(v)`, `delete(v, 'key')`, `exist(v, 'key')`).

`delete()` returns the modified collection and must be reassigned:

```sql
-- Oracle
capitals.DELETE('Japan');

-- pgcollection
capitals := delete(capitals, 'Japan');
```

### No bulk DELETE

Oracle's `.DELETE` with no arguments removes all elements. pgcollection has no equivalent — delete keys individually in a loop, or reassign the variable to `NULL`:

```sql
-- Remove all elements
capitals := NULL;
```

### Subscript syntax

Oracle uses parentheses; pgcollection uses square brackets:

```sql
-- Oracle
capitals('USA') := 'Washington, D.C.';
val := capitals('USA');

-- pgcollection
capitals['USA'] := 'Washington, D.C.';
val := capitals['USA'];
```

### Homogeneous values

Oracle Associative Arrays enforce a single value type through the `TYPE` declaration. pgcollection also enforces homogeneous values, but the type is set either by a type modifier (`collection('date')`) or inferred from the first `add()` call. Attempting to add a value of a different type raises an error.

### SQL-level usage

Oracle Associative Arrays are PL/SQL-only — they cannot be used in SQL statements, stored in table columns, or passed as SQL function arguments. pgcollection types are full PostgreSQL data types: they can be table columns, function parameters, cast to JSON, and used with set-returning functions like `to_table()` in SQL statements.

### Key type differences

- Oracle `PLS_INTEGER` keys are 32-bit signed integers (-2,147,483,648 to 2,147,483,647). pgcollection `icollection` keys are 64-bit `bigint`.
- Oracle `VARCHAR2` keys have a declared maximum length. pgcollection `collection` keys support up to 32,767 characters.
- Oracle does not allow NULL keys. pgcollection does not allow NULL keys.

### Error behavior

Both Oracle and pgcollection raise `NO_DATA_FOUND` when accessing a non-existent key. Deleting a non-existent key is a silent no-op in both.

## Quick Reference

| Oracle Method | collection (text keys) | icollection (integer keys) |
|---|---|---|
| `v('key')` (read) | `v['key']` or `find(v, 'key')` | `v[42]` or `find(v, 42)` |
| `v('key') := val` (write) | `v['key'] := val` or `add(v, 'key', val)` | `v[42] := val` or `add(v, 42, val)` |
| `v.COUNT` | `count(v)` | `count(v)` |
| `v.EXISTS('key')` | `exist(v, 'key')` | `exist(v, 42)` |
| `v.DELETE('key')` | `v := delete(v, 'key')` | `v := delete(v, 42)` |
| `v.DELETE` (all) | — (delete keys in a loop) | — (delete keys in a loop) |
| `v.FIRST` | `first_key(v)` | `first_key(v)` |
| `v.LAST` | `last_key(v)` | `last_key(v)` |
| `v.NEXT(k)` | `next_key(v, k)` | `next_key(v, k)` |
| `v.PRIOR(k)` | `prev_key(v, k)` | `prev_key(v, k)` |

## Further Reading

- [Oracle PL/SQL Associative Arrays documentation](https://docs.oracle.com/en/database/oracle/oracle-database/23/lnpls/plsql-collections-and-records.html#GUID-E1C1B23D-E498-4220-A178-C5B1B8B0F66E)
