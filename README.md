# Teleport - Database Extraction Example

This Pad demonstrates how to use Teleport to extract tables from one database (the source), load it into another database (the sink), and then transform the loaded data in the sink database.

The dummy data for the source database comes from `garage.com` - a hypothetical SaaS business that allows users to manage the cars they own. It has two tables: 

* `users` - users that have registered for `garage.com`
* `cars` - contains all the cars that the users manage using `garage.com`; each car is associated with one user

# Instructions

## Table of Contents

1. [Prepare the test databases with dummy data](#prepare-the-test-databases-with-dummy-data)
2. [Run extract-load tasks using Teleport](#run-extract-load-tasks-using-teleport)
3. [Use a SQL Transform to modify or aggregate the data in the sink](#use-a-sql-transform-to-modify-or-aggregate-the-data-in-the-sink)

## Prepare the test databases with dummy data

Do the following from the command line on your computer

1. Use Docker to create and start the database

```
docker-compose up --no-start
docker-compose start
```

Expected output:
```
teleport-database-example $ docker-compose up --no-start --remove-orphans
Creating postgres_sink   ... done
Creating postgres_source ... done
teleport-database-example $ docker-compose start
Starting postgres_source ... done
Starting postgres_sink   ... done
teleport-database-example $
```


3. Verify the connection to `postgres_source` and `postgres_sink` (these are already configured in `config/database.yml`)

```
teleport about-db -source postgres_source
teleport about-db -source postgres_sink
```

Expected output:
```
teleport-database-example $ teleport about-db -source postgres_source
Name:  postgres_source
Type: PostgreSQL
teleport-database-example $ teleport about-db -source postgres_sink
Name:  postgres_sink
Type: PostgreSQL
```

3. Create the schema for the example tables in the `postgres_source` database

```
teleport db-terminal -source postgres_source
CREATE TABLE users (id INT8, first_name VARCHAR(128), last_name VARCHAR(128), email VARCHAR(255));
CREATE TABLE cars (id INT8, user_id INT8, make VARCHAR(128), model VARCHAR(128), purchase_date DATE);
```

Expected output:
```
teleport-database-example $ teleport db-terminal -source postgres_source
psql (12.3)
Type "help" for help.

postgres=# CREATE TABLE users (id INT8, first_name VARCHAR(128), last_name VARCHAR(128), email VARCHAR(255));
CREATE TABLE
postgres=# CREATE TABLE cars (id INT8, user_id INT8, make VARCHAR(128), model VARCHAR(128), purchase_date DATE);
CREATE TABLE
postgres=# \quit
```

4. Verify the tables exist in `postgres_source`

```
teleport list-tables -source postgres_source
```

Expected output:
```
teleport-database-example $ teleport list-tables -source postgres_source
users
cars
```


5. Load mock data into the tables in the `postgres_source` database

```
teleport import-csv -source postgres_source -table users -file .data/users.csv
teleport import-csv -source postgres_source -table cars -file .data/cars.csv
```

Expected output:
```
teleport-database-example $ teleport import-csv -source postgres_source -table users -file .data/users.csv
teleport-database-example $ teleport import-csv -source postgres_source -table cars -file .data/cars.csv
teleport-database-example $
```

6. Verify the mock data was imported into the test tables

```
teleport db-terminal -source postgres_source
SELECT COUNT(*) FROM users;
SELECT COUNT(*) FROM cars;
SELECT * FROM users LIMIT 10;
SELECT * FROM cars LIMIT 10;
```

```
teleport-database-example $ teleport db-terminal -source postgres_source
psql (12.3)
Type "help" for help.

postgres=# SELECT COUNT(*) FROM users;
 count
-------
   100
(1 row)

postgres=# SELECT COUNT(*) FROM cars;
 count
-------
   500

  postgres=# SELECT * FROM users LIMIT 10;
 id | first_name | last_name |           email
----+------------+-----------+----------------------------
  1 | Merla      | Housby    | mhousby0@printfriendly.com
  2 | Kellsie    | Clingan   | kclingan1@springer.com
  3 | Jany       | Cubitt    | jcubitt2@unc.edu
  4 | Doe        | Sorby     | dsorby3@gnu.org
  5 | Jessee     | Symmers   | jsymmers4@pen.io
  6 | Daveen     | Budgett   | dbudgett5@redcross.org
  7 | Hesther    | Staden    | hstaden6@accuweather.com
  8 | Estevan    | Tackell   | etackell7@lulu.com
  9 | Consuela   | Khosa     | ckhosa8@prweb.com
 10 | Glory      | Paulson   | gpaulson9@wikimedia.org
(10 rows)

postgres=# SELECT * FROM cars LIMIT 10;
 id | user_id |    make     |      model       | purchase_date
----+---------+-------------+------------------+---------------
  1 |      61 | Buick       | Regal            | 2018-02-09
  2 |      57 | Mitsubishi  | 3000GT           | 2019-06-30
  3 |     100 | Geo         | Tracker          | 2018-03-22
  4 |      62 | Pontiac     | Montana          | 2018-10-28
  5 |      71 | GMC         | Rally Wagon 1500 | 2014-10-22
  6 |      10 | Maserati    | Spyder           | 2017-03-15
  7 |      18 | Chrysler    | Crossfire        | 2015-09-22
  8 |      64 | Dodge       | Dakota           | 2015-01-03
  9 |      57 | Lamborghini | Murciélago       | 2018-04-17
 10 |      45 | Honda       | Element          | 2016-06-04
(10 rows)

```

## Run extract-load tasks using Teleport

Use `teleport extract-load-db` to execute a pipeline to extract data from `postgres_source` and load it into `postgres_sink`

1. Preview the task (`-preview` causes Teleport to print the steps of the task without executing them)

```
teleport extract-load-db -from postgres_source -table users -to postgres_sink -preview
teleport extract-load-db -from postgres_source -table cars -to postgres_sink -preview
```

Expected output:
```
teleport-database-example $ teleport extract-load-db -from postgres_source -table users -to postgres_sink -preview
INFO[0000] Starting extract-load                         from=postgres_source table=users to=postgres_sink
DEBU[0000] Establish connection to Database              database=postgres_source
DEBU[0000] Establish connection to Database              database=postgres_sink
DEBU[0000] Inspecting Table                              database=postgres_source table=users
INFO[0000] Destination Table does not exist, creating    database=postgres_sink table=postgres_source_users
DEBU[0000] (not executed) SQL Query:
	CREATE TABLE postgres_source_users (
	id INT8,
	first_name VARCHAR(128),
	last_name VARCHAR(128),
	email VARCHAR(255),
	full_name VARCHAR(255)
	);
DEBU[0000] Exporting CSV of table data                   database=postgres_source table=users type=Full
DEBU[0000] Results CSV Generated                         file=/tmp/extract-users-postgres_source-216493034.csv limit=3
DEBU[0000] CSV Contents:
Headers:
id,first_name,last_name,email,full_name

Body:
	1,Merla,Housby,mhousby0@printfriendly.com,Merla Housby
	2,Kellsie,Clingan,kclingan1@springer.com,Kellsie Clingan
	3,Jany,Cubitt,jcubitt2@unc.edu,Jany Cubitt


DEBU[0000] Creating staging table                        database=postgres_sink staging_table=staging_postgres_source_users_jmrpws
DEBU[0000] (not executed) SQL Query:
	CREATE TABLE staging_postgres_source_users_jmrpws AS TABLE postgres_source_users WITH NO DATA
DEBU[0000] (not executed) Importing CSV into staging table  database=postgres_sink staging_table=staging_postgres_source_users_jmrpws
DEBU[0000] Updating primary table                        database=postgres_sink staging_table=staging_postgres_source_users_jmrpws table=postgres_source_users
DEBU[0000] (not executed) SQL Query:

			ALTER TABLE postgres_source_users RENAME TO archive_postgres_source_users;
			ALTER TABLE staging_postgres_source_users_jmrpws RENAME TO postgres_source_users;
			DROP TABLE archive_postgres_source_users;

INFO[0000] Completed extract-load 🎉                      from=postgres_source rows=3 table=users to=postgres_sink
teleport-database-example $ teleport extract-load-db -from postgres_source -table cars -to postgres_sink -preview
INFO[0000] Starting extract-load                         from=postgres_source table=cars to=postgres_sink
DEBU[0000] Establish connection to Database              database=postgres_source
DEBU[0000] Establish connection to Database              database=postgres_sink
DEBU[0000] Inspecting Table                              database=postgres_source table=cars
INFO[0000] Destination Table does not exist, creating    database=postgres_sink table=postgres_source_cars
DEBU[0000] (not executed) SQL Query:
	CREATE TABLE postgres_source_cars (
	id INT8,
	user_id INT8,
	make VARCHAR(128),
	model VARCHAR(128),
	purchase_date DATE
	);
DEBU[0000] Exporting CSV of table data                   database=postgres_source table=cars type=Full
DEBU[0000] Results CSV Generated                         file=/tmp/extract-cars-postgres_source-128984152.csv limit=3
DEBU[0000] CSV Contents:
Headers:
id,user_id,make,model,purchase_date

Body:
	1,61,buick,Regal,2018-02-09
	2,57,mitsubishi,3000GT,2019-06-30
	3,100,geo,Tracker,2018-03-22


DEBU[0000] Creating staging table                        database=postgres_sink staging_table=staging_postgres_source_cars_3l6g9v
DEBU[0000] (not executed) SQL Query:
	CREATE TABLE staging_postgres_source_cars_3l6g9v AS TABLE postgres_source_cars WITH NO DATA
DEBU[0000] (not executed) Importing CSV into staging table  database=postgres_sink staging_table=staging_postgres_source_cars_3l6g9v
DEBU[0000] Updating primary table                        database=postgres_sink staging_table=staging_postgres_source_cars_3l6g9v table=postgres_source_cars
DEBU[0000] (not executed) SQL Query:

			ALTER TABLE postgres_source_cars RENAME TO archive_postgres_source_cars;
			ALTER TABLE staging_postgres_source_cars_3l6g9v RENAME TO postgres_source_cars;
			DROP TABLE archive_postgres_source_cars;

INFO[0000] Completed extract-load 🎉                      from=postgres_source rows=3 table=cars to=postgres_sink
```

2. Execute the task (if everything worked correctly in the previous step)

```
teleport extract-load-db -from postgres_source -table users -to postgres_sink
teleport extract-load-db -from postgres_source -table cars -to postgres_sink
```

Expected output:
```
teleport-database-example $ teleport extract-load-db -from postgres_source -table users -to postgres_sink
INFO[0000] Starting extract-load                         from=postgres_source table=users to=postgres_sink
INFO[0000] Destination Table does not exist, creating    database=postgres_sink table=postgres_source_users
INFO[0000] Completed extract-load 🎉                      from=postgres_source rows=100 table=users to=postgres_sink
teleport-database-example $ teleport extract-load-db -from postgres_source -table cars -to postgres_sink
INFO[0000] Starting extract-load                         from=postgres_source table=cars to=postgres_sink
INFO[0000] Destination Table does not exist, creating    database=postgres_sink table=postgres_source_cars
INFO[0000] Completed extract-load 🎉                      from=postgres_source rows=500 table=cars to=postgres_sink
```

3. Verify the data was loaded correctly into the sink

```
teleport db-terminal -source postgres_sink
SELECT COUNT(*) FROM postgres_source_users;
SELECT COUNT(*) FROM postgres_source_cars;
SELECT * FROM postgres_source_users LIMIT 10;
SELECT * FROM postgres_source_cars LIMIT 10;
```

Expected output:
```
teleport-database-example $ teleport db-terminal -source postgres_sink
psql (12.3)
Type "help" for help.

postgres=# SELECT COUNT(*) FROM postgres_source_users;
 count
-------
   100
(1 row)

postgres=# SELECT COUNT(*) FROM postgres_source_cars;
 count
-------
   500
(1 row)

postgres=# SELECT * FROM postgres_source_users LIMIT 10;
 id | first_name | last_name |           email            |    full_name
----+------------+-----------+----------------------------+-----------------
  1 | Merla      | Housby    | mhousby0@printfriendly.com | Merla Housby
  2 | Kellsie    | Clingan   | kclingan1@springer.com     | Kellsie Clingan
  3 | Jany       | Cubitt    | jcubitt2@unc.edu           | Jany Cubitt
  4 | Doe        | Sorby     | dsorby3@gnu.org            | Doe Sorby
  5 | Jessee     | Symmers   | jsymmers4@pen.io           | Jessee Symmers
  6 | Daveen     | Budgett   | dbudgett5@redcross.org     | Daveen Budgett
  7 | Hesther    | Staden    | hstaden6@accuweather.com   | Hesther Staden
  8 | Estevan    | Tackell   | etackell7@lulu.com         | Estevan Tackell
  9 | Consuela   | Khosa     | ckhosa8@prweb.com          | Consuela Khosa
 10 | Glory      | Paulson   | gpaulson9@wikimedia.org    | Glory Paulson
(10 rows)

postgres=# SELECT * FROM postgres_source_cars LIMIT 10;
 id | user_id |    make     |      model       | purchase_date
----+---------+-------------+------------------+---------------
  1 |      61 | buick       | Regal            | 2018-02-09
  2 |      57 | mitsubishi  | 3000GT           | 2019-06-30
  3 |     100 | geo         | Tracker          | 2018-03-22
  4 |      62 | pontiac     | Montana          | 2018-10-28
  5 |      71 | gmc         | Rally Wagon 1500 | 2014-10-22
  6 |      10 | maserati    | Spyder           | 2017-03-15
  7 |      18 | chrysler    | Crossfire        | 2015-09-22
  8 |      64 | dodge       | Dakota           | 2015-01-03
  9 |      57 | lamborghini | Murciélago       | 2018-04-17
 10 |      45 | honda       | Element          | 2016-06-04
(10 rows)

postgres=#
```

**A few things to notice here:**

* By convention, the tables in the sink are named using the format: `"{{source_name}}_{{source_table_name}}"`. e.g., when we extract the `cars` table from the `postgres_source` database, the destination table in `postgres_sink` is named `postgres_source_users`.
* The was modified (transformed) before loading. Notice how the `users` table has a new column `full_name` and the `make` column in the `cars` table has all lowercase values. These transformations are configured in `sources/databases/postgres_source.port`

## Use a SQL Transform to modify or aggregate the data in the sink

The transformations configured in the extract-load step are intended to be simple, row-level modifications to cleanup data before loading into a datawarehouse.

For more complex transformations and aggregations, SQL Transforms are preferred. These live in the pad's `transforms/` and should be run after loading the data.

SQL Transforms do not modify the loaded data. Instead, they generate new tables based on SQL statements.

In this example, we'll run a SQL Transform in the sink to create a new table that reports how many cars each user has.

To view the SQL statement, open `transforms/count_cars_by_user.sql` in your editor or:

```
cat transforms/count_cars_by_user.sql
```

1. Perform the SQL Transform

```
teleport transform -source postgres_sink -table count_cars_by_user
```

Expected output:
```
teleport-database-example $ teleport transform -source postgres_sink -table count_cars_by_user
teleport-database-example $
```

2. Verify the data in the new table `count_cars_by_user`

```
teleport db-terminal -source postgres_sink
SELECT COUNT(*) FROM count_cars_by_user;
SELECT * FROM count_cars_by_user LIMIT 10;
```

Expected output:
```
teleport-database-example $ teleport db-terminal -source postgres_sink
psql (12.3)
Type "help" for help.

postgres=# SELECT COUNT(*) FROM count_cars_by_user;
 count
-------
   100
(1 row)

postgres=# SELECT * FROM count_cars_by_user LIMIT 10;
 id |    full_name    | count
----+-----------------+-------
 21 | Amalia Borwick  |     4
 55 | Val Goulbourn   |     1
 13 | Cindee Elcox    |     4
 82 | Horton Eckh     |     3
  7 | Hesther Staden  |     2
 81 | Jerri Gilford   |    14
  6 | Daveen Budgett  |     6
 25 | Sam Sandyfirth  |     7
 83 | Josephina Ouver |     1
 94 | Daven De Laspee |     4
(10 rows)
```


