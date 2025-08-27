## pgcollection

pgcollection is a memory optimized data type for PostgreSQL. The primary usage 
is a high performance data structure inside of plpglsql functions. Like other
PostgreSQL data types, a collection can be a column of a table, but there are
no operators. 

A collection is a set of key-value pairs. Each key is a unique string of type 
`text`. Entries are stored in creation order. A collection can hold an 
unlimited number of elements, constrained by the memory available to the 
database. A collection is stored as a PostgreSQL `varlena` limiting the 
maximum size to 1GB if the structure was persisted to a column in a table. 

The value of an element can be any PostgreSQL type including composite types 
with a default of type `text`. All elements in a collection must be of the 
same type. 

```sql
DO
$$
DECLARE
  t_capital  collection;
BEGIN
  t_capital['USA']            := 'Washington, D.C.';
  t_capital['United Kingdom'] := 'London';
  t_capital['Japan']          := 'Tokyo';

  t_capital := first(t_capital);
  WHILE NOT isnull(t_capital) LOOP
    RAISE NOTICE 'The capital of % is %', key(t_capital), value(t_capital);
    t_capital := next(t_capital);
  END LOOP;
END
$$;
```

## Installation

### Linux and Mac

Compile and install the extension (supports PostgreSQL 14+)

```sh
cd /tmp
git clone https://github.com/aws/pgcollection.git
cd pgcollection
make
make install
```

## Getting Started

Enable the extension (do this once in each database where you want to use it)

```tsql
CREATE EXTENSION collection;
```

## List of Functions

|      Function Name                      |    Return Type          |    Description                                                                             |
| --------------------------------------- | ----------------------- | ------------------------------------------------------------------------------------------ |
| add(collection, text, text)             | collection              | Adds an text item to a collection                                                          |
| add(collection, text, anyelement)       | collection              | Adds an anyelement item to a collection                                                    |
| count(collection)                       | int4                    | Returns the number of items in a collection                                                |
| delete(collection, text)                | collection              | Deletes an item from a collection                                                          |
| exist(collection, text)                 | text                    | Returns true if a given key exists in the collection                                       |
| find(collection, text)                  | text                    | Returns a text item from a collection if it exists                                         |
| find(collection, text, anyelement)      | anyelement              | Returns an anyelement item from a collection if it exists                                  |
| first(collection)                       | collection              | Sets the collection iterator to the first item                                             |
| last(collection)                        | collection              | Sets the collection iterator to the last item                                              |
| next(collection)                        | collection              | Sets the collection iterator to the next item                                              |
| prev(collection)                        | collection              | Sets the collection iterator to the previous item                                          |
| first_key(collection)                   | collection              | Returns the key of the first item in the collection                                        |
| last_key(collection)                    | collection              | Returns the key of the last item in the collection                                         |
| next_key(collection, text)              | collection              | Returns the key of the next item in the collection for the given key                       |
| prev_key(collection, text)              | collection              | Returns the key of the previous item in the collection for the given key                   |
| copy(collection)                        | collection              | Returns a copy of a collection without a context switch                                    |
| sort(collection)                        | collection              | Sorts a collection by the keys in collation order and points to the first item             |
| isnull(collection)                      | bool                    | Returns true if the current location of the iterator is null                               |
| key(collection)                         | text                    | Returns the key of the item the collection is pointed at                                   |
| value(collection)                       | text                    | Returns the value as text of the item the collection is pointed at                         |
| value(collection, anyelement)           | anyelement              | Returns the value as anyelement of the item the collection is pointed at                   |
| keys_to_table(collection)               | SETOF text              | Returns all of the keys in the collection                                                  |
| values_to_table(collection)             | SETOF text              | Returns all of the values as text in the collection                                        |
| values_to_table(collection, anyelement) | SETOF anyelement        | Returns all of the values as anyelement in the collection                                  |
| to_table(collection)                    | TABLE(text, text)       | Returns all of the keys and values as text in the collection                               |
| to_table(collection, anyelement)        | TABLE(text, anyelement) | Returns all of the keys and values as anyelement in the collection                         |
| value_type(collection)                  | regtype                 | Returns the data type of the elements within the collection                                |

## Finding an Item in a Collection

The `find` function comes in two different variants. The first takes two
parameters and returns the value as a `text` type. The second takes a third
parameter of the pseudo-type `anyelement` which is used to determine the return
type. If `find` is called with a key that has not been defined in the
collection, a `no_data_found` error is thrown.

```sql
DO
$$
DECLARE
  c1   collection('date');
BEGIN
  c1 := add(c1, 'k1', '1999-12-31'::date);

  RAISE NOTICE 'The value of c1 is %', find(c1, 'k1', null::date);
END
$$;
```

## Using Subscripts

In addition to these functions, collections can be subscripted, allowing them 
to act like associative arrays. Only a single subscript of type `text` can be 
specified. It is interpreted as a key and the corresponding value is fetched 
or assigned.

```sql
DO
$$
DECLARE
  t_capital  collection;
BEGIN
  t_capital['USA'] := 'Washington, D.C.';

  RAISE NOTICE 'The capital of USA is %', t_capital['USA'];
END
$$;
```

If the subscript is `null`, the current element will be fetched.

```sql
DO
$$
DECLARE
  t_capital  collection;
BEGIN
  t_capital['USA'] := 'Washington, D.C.';

  RAISE NOTICE 'The current capital is %', t_capital[null];
END
$$;
```

## Setting The Element Type

The default type of a collection's element is `text`, however it can contain
any valid PostgreSQL type. The type can be set in two ways. The first is by
explicitly setting it as the type modifier when declaring the collection. If
no type modifier is defined, the type of the first element added to the 
collection using the `add` function will define the type of the collection.
If no type modifier is set, any subscript assignments or fetches will be cast
to type `text`.

```sql
DO 
$$
DECLARE
  c1   collection('date');
BEGIN
  c1['k1'] := '1999-12-31';

  RAISE NOTICE 'The next value of c1 is %', c1['k1'] + 1;
END
$$;
```

## Iterating Over a Collection

In addition to finding specific elements in a collection, a collection can be a 
traversed by iterating over it. When a collection is initially defined, the 
position of the implicit iterator is pointing at the first element added to the 
collection. 

### Key and Value Functions

The `key` and `value` functions act on the current position of the iterator and 
will return the current key and value respectively. Using a `null` subscript will
have the same results of calling the `value` function. 

```sql
DO
$$
DECLARE
  t_capital  collection;
  r          record;
BEGIN
  t_capital['USA']            := 'Washington, D.C.';
  t_capital['United Kingdom'] := 'London';
  t_capital['Japan']          := 'Tokyo';

  RAISE NOTICE 'The current element is %', key(t_capital);
END
$$;
```

### First, Last and Sort Functions

Before starting to iterate over a collection, it is good practice the ensure 
that the iterator is positioned at the start or end of the collection depending
on the direction the collection will be traversed. The `first` function will 
return a reference to the collection at the first element and conversely the
`last` function will return a reference to the last element. If there is a 
need to iterate over a collection sorted by the value of the keys instead of 
the order the elements were added, the `sort` function will sort the collection
and return a reference to the first sorted element. 

```sql
DO
$$
DECLARE
  t_capital  collection;
  r          record;
BEGIN
  t_capital['USA']            := 'Washington, D.C.';
  t_capital['United Kingdom'] := 'London';
  t_capital['Japan']          := 'Tokyo';

  t_capital := sort(t_capital);
  RAISE NOTICE 'The current element is %', key(t_capital);
END
$$;
```

### Collations

A collection is a collatable type meaning that the sort order of the keys in a
collection is dependent on the collation defined for the collection. A
collection will use the collation of the database by default, but alternative
collations can be used when defining the collection variable.

```sql
DO
$$
DECLARE
  t_capital  collection COLLATE "en_US";
  r          record;
BEGIN
  t_capital['USA']            := 'Washington, D.C.';
  t_capital['United Kingdom'] := 'London';
  t_capital['Japan']          := 'Tokyo';

  t_capital := sort(t_capital);
  FOR r IN SELECT * FROM keys_to_table(t_capital) AS k 
  LOOP
    RAISE NOTICE 'The current element is %', r.k;
  END LOOP;
END
$$;
```

### Next and Prev Functions

When iterating over a collection, control may be needed on how to move over
the collection. The `next` function will move the reference to the collection 
to the next element in either added order or sorted order depending on if
the `sort` function was called. The `prev` function will move the reference
to the previous element in the collection.

```sql
DO
$$
DECLARE
  t_capital  collection;
  r          record;
BEGIN
  t_capital['USA']            := 'Washington, D.C.';
  t_capital['United Kingdom'] := 'London';
  t_capital['Japan']          := 'Tokyo';

  t_capital := next(t_capital);
  RAISE NOTICE 'The current element is %', key(t_capital);
END
$$;
```

### Isnull Function

While iterating over a collection, an indicator is needed for when the end of 
the collection is reached. The `isnull` function will return a true value once
the iterator reaches the end of the collection. 

```sql
DO
$$
DECLARE
  t_capital  collection;
BEGIN
  t_capital['USA']            := 'Washington, D.C.';
  t_capital['United Kingdom'] := 'London';
  t_capital['Japan']          := 'Tokyo';

  t_capital := sort(t_capital);
  WHILE NOT isnull(t_capital) LOOP
    RAISE NOTICE 'The current element is %', key(t_capital);
    t_capital := next(t_capital);
  END LOOP;
END
$$;
```

### Set Returning Functions

In addition to the iterator functions, the entirety of the collection can be 
leveraged through the use of set returning functions. There are three 
variations that will return a list of keys, values or both in a result set. 

```sql
DO
$$
DECLARE
  t_capital  collection;
  r          record;
BEGIN
  t_capital['USA']            := 'Washington, D.C.';
  t_capital['United Kingdom'] := 'London';
  t_capital['Japan']          := 'Tokyo';

  FOR r IN SELECT * FROM keys_to_table(t_capital) AS k 
  LOOP
    RAISE NOTICE 'The current element is %', r.k;
  END LOOP;
END
$$;
```


## Bulk Loading Collections

A common practice is to load data into a collection at the start of a function
so it can be repeatedly used without needing to access the source tables 
again. For the best performance, use the plpgsql `FOR` [construct with the
query](https://www.postgresql.org/docs/current/plpgsql-control-structures.html#PLPGSQL-RECORDS-ITERATING)
defined in the loop. This will create an implicit cursor and utilize prefetching
on the query results. 

```sql
DO
$$
DECLARE
  r       pg_tablespace%ROWTYPE;
  c       collection('pg_tablespace');
BEGIN
  FOR r IN SELECT pg_tablespace.* 
             FROM pg_tablespace 
  LOOP
    c[r.spcname] = r;
  END LOOP;

  RAISE NOTICE 'The owner of pg_default is %', c['pg_default'].spcowner::regrole;
END
$$;
```

## Bulk DML Operations

Data contained in a collection can be used to perform DML operations for each 
element in the collection. While the collection can be iterated and the DML 
performed inside of a loop, that pattern can be a performance bottleneck for 
large collections. A more efficient method is to use the set returning 
functions as part of the DML. The eliminates the context switching between the 
function context and the SQL engine beyond the initial statement call. 

```sql
DO
$$
DECLARE
  t_capital  collection;
  r          record;
BEGIN
  t_capital['USA']            := 'Washington, D.C.';
  t_capital['United Kingdom'] := 'London';
  t_capital['Japan']          := 'Tokyo';

  UPDATE countries
     SET capital = col.value
    FROM to_table(t_capital) AS col
   WHERE countries.name = col.key;
END
$$;
```
## Observability

`pgcollection` is a performance feature so having observaility into how things
are operating can assist in finding bottlenecks or wider performance problems.

### Wait Events

PostgreSQL 17 introduced custom wait events enabling extensions to define
events specific to the extension. `pgcollection` introduces a number of 
custom wait events allowing detailed monitoring. Prior to PostgreSQL 17,
all of the wait events are rolled up into the common `Extension:extension`
wait event. 

|      Wait Event               |    Description                                                               |
| ----------------------------- | ---------------------------------------------------------------------------- |
| CollectionCalculatingFlatSize | Calculating the size of the flat collection format before a context switch   |
| CollectionFlatten             | Converting a collection to the flat format to move to a new context          |
| CollectionExpand              | Expanding a flat collection to an optimized expanded format                  |
| CollectionCast                | Casting a collection to or from a typemod specified collection               |
| CollectionAdd                 | Adding an item to a collection                                               |
| CollectionCount               | Returning the number of items in a collection                                |
| CollectionFind                | Finding an item in a collection                                              |
| CollectionDelete              | Deleting an item from a collection                                           |
| CollectionSort                | Sorting a collection                                                         |
| CollectionCopy                | Copying a collection                                                         |
| CollectionValue               | Returning the value at the current location of a collection                  |
| CollectionToTable             | Converting a collection to a table format                                    |
| CollectionFetch               | Fetching an item in a collection using a subscript                           |
| CollectionAssign              | Assigning a new item to a collection using a subscript                       |
| CollectionInput               | Converting a collection from a string format to an optimized expanded format |
| CollectionOutput              | Converting a collection to a string format for output                        |

### Usage Statistics

The `collection_stats` view provides the following fields for a session:

| fieldname       | description                                                               |
|-----------------|---------------------------------------------------------------------------|
| add             | The number of adds or assigns to a collection for a session               |
| context_switch  | The number of times a collection switches to a different memory context   |
| delete          | The number of deletes from a collection for a session                     |
| find            | The number of finds or fetches from a collection for a session            |
| sort            | The number of collection sorts for a session                              |

The `collection_stats_reset()` function removes all stored statistics for the session


## Contributing

We welcome and encourage contributions to `pgcollection`!

See our [contribution guide](CONTRIBUTING.md) for more information on how to report issues, set up a development environment, and submit code.

We adhere to the [Amazon Open Source Code of Conduct](https://aws.github.io/code-of-conduct).

## Security

See [CONTRIBUTING](CONTRIBUTING.md#security-issue-notifications) for more information.

## License

This project is licensed under the Apache-2.0 License.

## Acknowledgements

pgcollection makes use of the following open source project:

 - [uthash](https://github.com/troydhanson/uthash)
