

# 🏆 The Ultimate SQL Mastery Guide
## From Absolute Beginner to Advanced Professional

---

# 📖 TABLE OF CONTENTS

```
PART 1: FOUNDATIONS
  1.  Introduction to SQL & Databases
  2.  Data Types
  3.  DDL – Data Definition Language
  4.  DML – Data Manipulation Language
  5.  DQL – SELECT Statements & Filtering

PART 2: INTERMEDIATE
  6.  Aggregate Functions & GROUP BY
  7.  JOIN Operations
  8.  Subqueries & Nested Queries
  9.  Set Operations
  10. Views

PART 3: ADVANCED
  11. Indexes & Performance
  12. Transactions & ACID Properties
  13. Database Normalization
  14. Window Functions
  15. Common Table Expressions (CTEs)
  16. Stored Procedures & Functions
  17. Triggers
  18. Cursors
  19. Dynamic SQL
  20. Pivoting & Unpivoting
  21. Recursive Queries
  22. Query Optimization & Execution Plans
  23. Locking, Concurrency & Isolation Levels
  24. Partitioning
  25. Advanced Pattern Matching & Regular Expressions
```

---
---

# PART 1: FOUNDATIONS

---

# 1. 🌟 INTRODUCTION TO SQL & DATABASES

## What is a Database?
A **database** is an organized collection of structured data stored electronically. Think of it as a digital filing cabinet.

## What is SQL?
**SQL (Structured Query Language)** is the standard language used to communicate with relational databases. It allows you to create, read, update, and delete data.

## What is a Table?
A **table** is a collection of related data organized in **rows** (records) and **columns** (fields).

```
+----+----------+-----+------------+--------+
| id | name     | age | department | salary |
+----+----------+-----+------------+--------+
|  1 | Alice    |  30 | Engineering| 90000  |
|  2 | Bob      |  25 | Marketing  | 60000  |
|  3 | Charlie  |  35 | Engineering| 95000  |
+----+----------+-----+------------+--------+
        ↑ columns (fields)
  ← rows (records) →
```

## Categories of SQL Commands

```
┌─────────────────────────────────────────────────────────┐
│                    SQL COMMANDS                          │
├────────────┬────────────┬──────┬──────────┬─────────────┤
│    DDL     │    DML     │ DQL  │   DCL    │    TCL      │
├────────────┼────────────┼──────┼──────────┼─────────────┤
│ CREATE     │ INSERT     │SELECT│ GRANT    │ COMMIT      │
│ ALTER      │ UPDATE     │      │ REVOKE   │ ROLLBACK    │
│ DROP       │ DELETE     │      │          │ SAVEPOINT   │
│ TRUNCATE   │ MERGE      │      │          │             │
│ RENAME     │            │      │          │             │
└────────────┴────────────┴──────┴──────────┴─────────────┘
```

---

# 2. 🔢 DATA TYPES

## Common SQL Data Types

```
┌─────────────────┬───────────────────────────────────────────┐
│   Category      │   Data Types                              │
├─────────────────┼───────────────────────────────────────────┤
│ Numeric         │ INT, SMALLINT, BIGINT, DECIMAL(p,s),      │
│                 │ FLOAT, REAL, NUMERIC                      │
├─────────────────┼───────────────────────────────────────────┤
│ String/Text     │ CHAR(n), VARCHAR(n), TEXT, NVARCHAR(n)    │
├─────────────────┼───────────────────────────────────────────┤
│ Date/Time       │ DATE, TIME, DATETIME, TIMESTAMP, YEAR     │
├─────────────────┼───────────────────────────────────────────┤
│ Boolean         │ BOOLEAN (TRUE/FALSE)                      │
├─────────────────┼───────────────────────────────────────────┤
│ Binary          │ BLOB, BINARY, VARBINARY                   │
└─────────────────┴───────────────────────────────────────────┘
```

### Key Differences

```sql
-- CHAR(10) → Fixed length, always stores 10 characters (padded with spaces)
-- 'Hello     ' → 10 bytes

-- VARCHAR(10) → Variable length, stores only what's needed
-- 'Hello'      → 5 bytes

-- DECIMAL(8,2) → 8 total digits, 2 after decimal point
-- Example: 123456.78
```

---

# 3. 🏗️ DDL – DATA DEFINITION LANGUAGE

DDL commands define and modify the **structure** of database objects.

---

## 3.1 CREATE

### Creating a Database
```sql
CREATE DATABASE company_db;
USE company_db;
```

### Creating Tables
```sql
CREATE TABLE employees (
    employee_id   INT PRIMARY KEY AUTO_INCREMENT,
    first_name    VARCHAR(50) NOT NULL,
    last_name     VARCHAR(50) NOT NULL,
    email         VARCHAR(100) UNIQUE,
    hire_date     DATE DEFAULT (CURRENT_DATE),
    salary        DECIMAL(10,2) CHECK (salary > 0),
    department_id INT,
    manager_id    INT,
    is_active     BOOLEAN DEFAULT TRUE
);

CREATE TABLE departments (
    department_id   INT PRIMARY KEY AUTO_INCREMENT,
    department_name VARCHAR(100) NOT NULL UNIQUE,
    location        VARCHAR(100),
    budget          DECIMAL(15,2)
);

CREATE TABLE projects (
    project_id    INT PRIMARY KEY AUTO_INCREMENT,
    project_name  VARCHAR(100) NOT NULL,
    start_date    DATE,
    end_date      DATE,
    budget        DECIMAL(12,2),
    status        VARCHAR(20) DEFAULT 'Active',
    CHECK (end_date > start_date)
);

CREATE TABLE employee_projects (
    employee_id INT,
    project_id  INT,
    role        VARCHAR(50),
    hours_worked DECIMAL(6,2) DEFAULT 0,
    PRIMARY KEY (employee_id, project_id),
    FOREIGN KEY (employee_id) REFERENCES employees(employee_id),
    FOREIGN KEY (project_id) REFERENCES projects(project_id)
);
```

### Constraint Summary
```
┌──────────────┬──────────────────────────────────────────────┐
│ Constraint   │ Purpose                                      │
├──────────────┼──────────────────────────────────────────────┤
│ PRIMARY KEY  │ Uniquely identifies each row                 │
│ FOREIGN KEY  │ Links two tables together                    │
│ NOT NULL     │ Column cannot have NULL values               │
│ UNIQUE       │ All values in column must be different       │
│ CHECK        │ Values must satisfy a condition              │
│ DEFAULT      │ Sets a default value if none provided        │
│ AUTO_INCREMENT│ Automatically generates sequential numbers  │
└──────────────┴──────────────────────────────────────────────┘
```

---

## 3.2 ALTER

```sql
-- Add a new column
ALTER TABLE employees ADD COLUMN phone VARCHAR(15);

-- Modify a column's data type
ALTER TABLE employees MODIFY COLUMN phone VARCHAR(20);

-- Rename a column
ALTER TABLE employees RENAME COLUMN phone TO phone_number;

-- Drop a column
ALTER TABLE employees DROP COLUMN phone_number;

-- Add a constraint
ALTER TABLE employees
ADD CONSTRAINT fk_department
FOREIGN KEY (department_id) REFERENCES departments(department_id);

-- Drop a constraint
ALTER TABLE employees DROP CONSTRAINT fk_department;

-- Rename a table
ALTER TABLE employees RENAME TO staff;
```

---

## 3.3 DROP vs TRUNCATE

```sql
-- DROP: Removes the entire table (structure + data)
DROP TABLE IF EXISTS temp_table;

-- TRUNCATE: Removes all data but keeps the structure
TRUNCATE TABLE employees;

-- DROP a database
DROP DATABASE IF EXISTS test_db;
```

```
┌───────────┬────────────────────────┬─────────────────────────┐
│ Feature   │ DROP                   │ TRUNCATE                │
├───────────┼────────────────────────┼─────────────────────────┤
│ Structure │ Removes table entirely │ Keeps table structure   │
│ Data      │ All data deleted       │ All data deleted        │
│ Rollback  │ Cannot rollback        │ Cannot rollback (DDL)   │
│ WHERE     │ Not applicable         │ Not supported           │
│ Speed     │ N/A                    │ Faster than DELETE      │
│ Triggers  │ N/A                    │ Does NOT fire triggers  │
│ Identity  │ N/A                    │ Resets auto-increment   │
└───────────┴────────────────────────┴─────────────────────────┘
```

---

# 4. ✏️ DML – DATA MANIPULATION LANGUAGE

DML commands manipulate the **data** inside tables.

## Let's Populate Our Tables

### 4.1 INSERT

```sql
-- Insert into departments
INSERT INTO departments (department_name, location, budget)
VALUES
    ('Engineering',  'San Francisco', 500000),
    ('Marketing',    'New York',      300000),
    ('HR',           'Chicago',       200000),
    ('Finance',      'New York',      350000),
    ('Sales',        'Los Angeles',   400000);

-- Insert into employees
INSERT INTO employees
    (first_name, last_name, email, hire_date, salary, department_id, manager_id)
VALUES
    ('Alice',   'Johnson', 'alice@company.com',   '2020-01-15', 95000,  1, NULL),
    ('Bob',     'Smith',   'bob@company.com',     '2019-03-22', 62000,  2, 1),
    ('Charlie', 'Brown',   'charlie@company.com', '2021-07-10', 105000, 1, 1),
    ('Diana',   'Prince',  'diana@company.com',   '2018-11-05', 78000,  3, 1),
    ('Eve',     'Davis',   'eve@company.com',     '2022-02-28', 55000,  2, 2),
    ('Frank',   'Wilson',  'frank@company.com',   '2020-09-14', 88000,  4, 1),
    ('Grace',   'Lee',     'grace@company.com',   '2021-04-01', 72000,  5, 1),
    ('Henry',   'Taylor',  'henry@company.com',   '2023-01-10', 58000,  1, 3),
    ('Ivy',     'Chen',    'ivy@company.com',     '2022-06-15', 91000,  4, 6),
    ('Jack',    'Anderson','jack@company.com',    '2019-08-20', 67000,  5, 7);

-- Insert into projects
INSERT INTO projects (project_name, start_date, end_date, budget, status)
VALUES
    ('Website Redesign', '2023-01-01', '2023-06-30', 150000, 'Completed'),
    ('Mobile App',       '2023-03-15', '2023-12-31', 300000, 'Active'),
    ('Data Migration',   '2023-06-01', '2024-01-31', 200000, 'Active'),
    ('Marketing Campaign','2023-02-01','2023-08-31', 100000, 'Completed'),
    ('AI Integration',   '2024-01-01', '2024-12-31', 500000, 'Planning');

-- Insert into employee_projects
INSERT INTO employee_projects (employee_id, project_id, role, hours_worked)
VALUES
    (1, 1, 'Lead',      200),
    (1, 2, 'Architect', 150),
    (3, 2, 'Developer', 300),
    (3, 3, 'Lead',      250),
    (8, 2, 'Developer', 180),
    (2, 4, 'Lead',      220),
    (5, 4, 'Coordinator',160),
    (6, 3, 'Analyst',   190),
    (9, 3, 'Analyst',   175),
    (7, 1, 'Sales Rep', 120);
```

### 4.2 UPDATE

```sql
-- Update a single record
UPDATE employees
SET salary = 98000
WHERE employee_id = 1;

-- Update multiple records
UPDATE employees
SET salary = salary * 1.10     -- 10% raise
WHERE department_id = 1;

-- Update with a subquery
UPDATE employees
SET salary = salary * 1.05
WHERE department_id = (
    SELECT department_id
    FROM departments
    WHERE department_name = 'Marketing'
);
```

### 4.3 DELETE

```sql
-- Delete specific records
DELETE FROM employees
WHERE employee_id = 10;

-- Delete with condition
DELETE FROM employees
WHERE is_active = FALSE AND hire_date < '2020-01-01';

-- Delete all rows (but keep table) — compare with TRUNCATE
DELETE FROM temp_table;
```

```
┌───────────┬──────────────────────┬──────────────────────────┐
│ Feature   │ DELETE               │ TRUNCATE                 │
├───────────┼──────────────────────┼──────────────────────────┤
│ WHERE     │ ✅ Supported         │ ❌ Not supported          │
│ Speed     │ Slower (row-by-row)  │ Faster (deallocates)     │
│ Triggers  │ ✅ Fires triggers    │ ❌ Does NOT fire triggers │
│ Rollback  │ ✅ Can rollback      │ ❌ Cannot rollback (DDL)  │
│ Log       │ Logs each row        │ Logs page deallocation   │
└───────────┴──────────────────────┴──────────────────────────┘
```

---

# 5. 🔍 DQL – SELECT STATEMENTS & FILTERING

The **SELECT** statement is the most used SQL command. It retrieves data from tables.

## 5.1 Basic SELECT

```sql
-- Select all columns
SELECT * FROM employees;

-- Select specific columns
SELECT first_name, last_name, salary FROM employees;

-- Select with alias
SELECT
    first_name AS "First Name",
    last_name  AS "Last Name",
    salary     AS "Annual Salary"
FROM employees;
```

**Output:**
```
+------------+-----------+---------------+
| First Name | Last Name | Annual Salary |
+------------+-----------+---------------+
| Alice      | Johnson   |      95000.00 |
| Bob        | Smith     |      62000.00 |
| Charlie    | Brown     |     105000.00 |
| Diana      | Prince    |      78000.00 |
| Eve        | Davis     |      55000.00 |
| Frank      | Wilson    |      88000.00 |
| Grace      | Lee       |      72000.00 |
| Henry      | Taylor    |      58000.00 |
| Ivy        | Chen      |      91000.00 |
| Jack       | Anderson  |      67000.00 |
+------------+-----------+---------------+
```

## 5.2 DISTINCT

```sql
-- Remove duplicate values
SELECT DISTINCT department_id FROM employees;

-- Multiple columns
SELECT DISTINCT department_id, is_active FROM employees;
```

## 5.3 WHERE Clause (Filtering)

```sql
-- Comparison operators
SELECT * FROM employees WHERE salary > 80000;
SELECT * FROM employees WHERE department_id = 1;
SELECT * FROM employees WHERE hire_date >= '2021-01-01';

-- AND, OR, NOT
SELECT * FROM employees
WHERE department_id = 1 AND salary > 90000;

SELECT * FROM employees
WHERE department_id = 1 OR department_id = 2;

SELECT * FROM employees
WHERE NOT department_id = 3;
```

## 5.4 Special Operators

### IN
```sql
-- Instead of multiple OR conditions
SELECT * FROM employees
WHERE department_id IN (1, 2, 4);
```

**Output:**
```
+----+---------+---------+-------------------+------------+--------+-----+
| id | first   | last    | email             | hire_date  | salary | dep |
+----+---------+---------+-------------------+------------+--------+-----+
|  1 | Alice   | Johnson | alice@company.com | 2020-01-15 | 95000  |  1  |
|  2 | Bob     | Smith   | bob@company.com   | 2019-03-22 | 62000  |  2  |
|  3 | Charlie | Brown   | charlie@company.com| 2021-07-10| 105000 |  1  |
|  5 | Eve     | Davis   | eve@company.com   | 2022-02-28 | 55000  |  2  |
|  6 | Frank   | Wilson  | frank@company.com | 2020-09-14 | 88000  |  4  |
|  8 | Henry   | Taylor  | henry@company.com | 2023-01-10 | 58000  |  1  |
|  9 | Ivy     | Chen    | ivy@company.com   | 2022-06-15 | 91000  |  4  |
+----+---------+---------+-------------------+------------+--------+-----+
```

### BETWEEN
```sql
SELECT * FROM employees
WHERE salary BETWEEN 60000 AND 90000;
-- Equivalent to: salary >= 60000 AND salary <= 90000

SELECT * FROM employees
WHERE hire_date BETWEEN '2020-01-01' AND '2022-12-31';
```

### LIKE (Pattern Matching)
```sql
-- % matches any sequence of characters
-- _ matches exactly one character

SELECT * FROM employees WHERE first_name LIKE 'A%';    -- Starts with A
SELECT * FROM employees WHERE last_name LIKE '%son';    -- Ends with 'son'
SELECT * FROM employees WHERE email LIKE '%@company%';  -- Contains '@company'
SELECT * FROM employees WHERE first_name LIKE '_v_';    -- 3 chars, 'v' in middle
SELECT * FROM employees WHERE first_name LIKE '____';   -- Exactly 4 characters
```

### IS NULL / IS NOT NULL
```sql
SELECT * FROM employees WHERE manager_id IS NULL;      -- Alice (top manager)
SELECT * FROM employees WHERE manager_id IS NOT NULL;  -- Everyone else
```

## 5.5 ORDER BY

```sql
-- Ascending (default)
SELECT first_name, salary
FROM employees
ORDER BY salary ASC;

-- Descending
SELECT first_name, salary
FROM employees
ORDER BY salary DESC;

-- Multiple columns
SELECT first_name, department_id, salary
FROM employees
ORDER BY department_id ASC, salary DESC;
```

**Output (multiple sort):**
```
+----------+---------------+--------+
| first_name| department_id | salary |
+----------+---------------+--------+
| Charlie  |             1 | 105000 |  ← Dept 1, highest salary first
| Alice    |             1 |  95000 |
| Henry    |             1 |  58000 |
| Bob      |             2 |  62000 |  ← Dept 2
| Eve      |             2 |  55000 |
| Diana    |             3 |  78000 |  ← Dept 3
| Ivy      |             4 |  91000 |  ← Dept 4
| Frank    |             4 |  88000 |
| Grace    |             5 |  72000 |  ← Dept 5
| Jack     |             5 |  67000 |
+----------+---------------+--------+
```

## 5.6 LIMIT / OFFSET (Pagination)

```sql
-- Get top 5 highest paid employees
SELECT first_name, salary
FROM employees
ORDER BY salary DESC
LIMIT 5;

-- Skip first 3, get next 5 (pagination)
SELECT first_name, salary
FROM employees
ORDER BY salary DESC
LIMIT 5 OFFSET 3;

-- SQL Server uses TOP instead:
-- SELECT TOP 5 first_name, salary FROM employees ORDER BY salary DESC;
```

## 5.7 CASE Expression (Conditional Logic)

```sql
SELECT
    first_name,
    salary,
    CASE
        WHEN salary >= 100000 THEN 'Senior'
        WHEN salary >= 75000  THEN 'Mid-Level'
        WHEN salary >= 60000  THEN 'Junior'
        ELSE 'Entry-Level'
    END AS level
FROM employees
ORDER BY salary DESC;
```

**Output:**
```
+----------+--------+-------------+
| first_name| salary | level       |
+----------+--------+-------------+
| Charlie  | 105000 | Senior      |
| Alice    |  95000 | Mid-Level   |
| Ivy      |  91000 | Mid-Level   |
| Frank    |  88000 | Mid-Level   |
| Diana    |  78000 | Mid-Level   |
| Grace    |  72000 | Junior      |
| Jack     |  67000 | Junior      |
| Bob      |  62000 | Junior      |
| Henry    |  58000 | Entry-Level |
| Eve      |  55000 | Entry-Level |
+----------+--------+-------------+
```

## 5.8 SQL Logical Order of Execution

```
Written Order:          Execution Order:
─────────────           ────────────────
SELECT          ←─ 5    FROM            ←─ 1
FROM            ←─ 1    WHERE           ←─ 2
WHERE           ←─ 2    GROUP BY        ←─ 3
GROUP BY        ←─ 3    HAVING          ←─ 4
HAVING          ←─ 4    SELECT          ←─ 5
ORDER BY        ←─ 6    ORDER BY        ←─ 6
LIMIT           ←─ 7    LIMIT           ←─ 7
```

> ⚠️ This is why you can't use a column alias defined in SELECT inside the WHERE clause!

---
---

# PART 2: INTERMEDIATE

---

# 6. 📊 AGGREGATE FUNCTIONS & GROUP BY

## 6.1 Aggregate Functions

Aggregate functions perform calculations on a set of values and return a **single value**.

```sql
SELECT
    COUNT(*)            AS total_employees,
    COUNT(manager_id)   AS employees_with_manager,
    SUM(salary)         AS total_salary,
    AVG(salary)         AS average_salary,
    MIN(salary)         AS lowest_salary,
    MAX(salary)         AS highest_salary
FROM employees;
```

**Output:**
```
+---------+----------+----------+----------+--------+--------+
| total   | w/manager| total_sal| avg_sal  | lowest | highest|
+---------+----------+----------+----------+--------+--------+
|      10 |        9 | 771000.00| 77100.00 | 55000  | 105000 |
+---------+----------+----------+----------+--------+--------+
```

> 📝 `COUNT(*)` counts all rows; `COUNT(column)` counts non-NULL values only.

## 6.2 GROUP BY

Groups rows sharing a property so aggregate functions can be applied to each group.

```sql
SELECT
    department_id,
    COUNT(*)       AS num_employees,
    AVG(salary)    AS avg_salary,
    SUM(salary)    AS total_salary
FROM employees
GROUP BY department_id
ORDER BY avg_salary DESC;
```

**Output:**
```
+---------------+----------------+------------+--------------+
| department_id | num_employees  | avg_salary | total_salary |
+---------------+----------------+------------+--------------+
|             1 |              3 |   86000.00 |    258000.00 |
|             4 |              2 |   89500.00 |    179000.00 |
|             3 |              1 |   78000.00 |     78000.00 |
|             5 |              2 |   69500.00 |    139000.00 |
|             2 |              2 |   58500.00 |    117000.00 |
+---------------+----------------+------------+--------------+
```

## 6.3 HAVING (Filter Groups)

`WHERE` filters **rows** before grouping. `HAVING` filters **groups** after grouping.

```sql
SELECT
    department_id,
    COUNT(*)    AS num_employees,
    AVG(salary) AS avg_salary
FROM employees
WHERE is_active = TRUE              -- ← filters ROWS first
GROUP BY department_id
HAVING AVG(salary) > 70000          -- ← filters GROUPS after
ORDER BY avg_salary DESC;
```

**Output:**
```
+---------------+----------------+------------+
| department_id | num_employees  | avg_salary |
+---------------+----------------+------------+
|             4 |              2 |   89500.00 |
|             1 |              3 |   86000.00 |
|             3 |              1 |   78000.00 |
+---------------+----------------+------------+
```

```
┌────────────┬─────────────────────────────────────────┐
│            │ Purpose                                 │
├────────────┼─────────────────────────────────────────┤
│ WHERE      │ Filters individual ROWS before grouping │
│ HAVING     │ Filters GROUPS after aggregation        │
└────────────┴─────────────────────────────────────────┘
```

## 6.4 GROUP BY with Multiple Columns

```sql
SELECT
    department_id,
    YEAR(hire_date)   AS hire_year,
    COUNT(*)          AS num_hired,
    AVG(salary)       AS avg_salary
FROM employees
GROUP BY department_id, YEAR(hire_date)
ORDER BY department_id, hire_year;
```

---

# 7. 🔗 JOIN OPERATIONS

JOINs combine rows from two or more tables based on a related column.

## Visual Overview

```
Table A         Table B

┌───┐           ┌───┐
│ 1 │           │ 1 │
│ 2 │           │ 2 │
│ 3 │           │ 4 │
│ 4 │           │ 5 │
└───┘           └───┘

INNER JOIN:      Only matching → {1, 2, 4}
LEFT JOIN:       All of A + matching B → {1, 2, 3, 4}
RIGHT JOIN:      All of B + matching A → {1, 2, 4, 5}
FULL OUTER JOIN: Everything → {1, 2, 3, 4, 5}
CROSS JOIN:      Every combination → 4 × 4 = 16 rows
```

## 7.1 INNER JOIN

Returns only rows that have matching values in **both** tables.

```sql
SELECT
    e.first_name,
    e.last_name,
    d.department_name,
    e.salary
FROM employees e
INNER JOIN departments d
    ON e.department_id = d.department_id;
```

**Output:**
```
+----------+----------+--------------+--------+
| first    | last     | department   | salary |
+----------+----------+--------------+--------+
| Alice    | Johnson  | Engineering  | 95000  |
| Bob      | Smith    | Marketing    | 62000  |
| Charlie  | Brown    | Engineering  | 105000 |
| Diana    | Prince   | HR           | 78000  |
| Eve      | Davis    | Marketing    | 55000  |
| Frank    | Wilson   | Finance      | 88000  |
| Grace    | Lee      | Sales        | 72000  |
| Henry    | Taylor   | Engineering  | 58000  |
| Ivy      | Chen     | Finance      | 91000  |
| Jack     | Anderson | Sales        | 67000  |
+----------+----------+--------------+--------+
```

## 7.2 LEFT JOIN (LEFT OUTER JOIN)

Returns **all** rows from the left table, and matched rows from the right table. Unmatched rows get NULL.

```sql
-- Imagine we have an employee with department_id = NULL
SELECT
    e.first_name,
    d.department_name
FROM employees e
LEFT JOIN departments d
    ON e.department_id = d.department_id;
```
```
If an employee has no matching department:
+----------+----------------+
| first    | department     |
+----------+----------------+
| Alice    | Engineering    |
| NewGuy   | NULL           |  ← No matching department
+----------+----------------+
```

## 7.3 RIGHT JOIN (RIGHT OUTER JOIN)

Returns **all** rows from the right table, and matched rows from the left table.

```sql
SELECT
    e.first_name,
    d.department_name
FROM employees e
RIGHT JOIN departments d
    ON e.department_id = d.department_id;
```
```
If a department has no employees:
+----------+----------------+
| first    | department     |
+----------+----------------+
| Alice    | Engineering    |
| NULL     | Legal          |  ← Department exists but no employees
+----------+----------------+
```

## 7.4 FULL OUTER JOIN

Returns all rows from **both** tables, with NULLs where there's no match.

```sql
SELECT
    e.first_name,
    d.department_name
FROM employees e
FULL OUTER JOIN departments d
    ON e.department_id = d.department_id;
```

> ⚠️ MySQL doesn't support FULL OUTER JOIN directly. Workaround:
```sql
SELECT e.first_name, d.department_name
FROM employees e LEFT JOIN departments d ON e.department_id = d.department_id
UNION
SELECT e.first_name, d.department_name
FROM employees e RIGHT JOIN departments d ON e.department_id = d.department_id;
```

## 7.5 CROSS JOIN (Cartesian Product)

Every row from table A is paired with every row from table B.

```sql
SELECT
    e.first_name,
    p.project_name
FROM employees e
CROSS JOIN projects p;
-- If 10 employees × 5 projects = 50 rows
```

## 7.6 SELF JOIN

A table joined with **itself**. Useful for hierarchical data.

```sql
-- Find each employee's manager name
SELECT
    e.first_name  AS employee,
    m.first_name  AS manager
FROM employees e
LEFT JOIN employees m
    ON e.manager_id = m.employee_id;
```

**Output:**
```
+----------+----------+
| employee | manager  |
+----------+----------+
| Alice    | NULL     |  ← Alice has no manager (top)
| Bob      | Alice    |
| Charlie  | Alice    |
| Diana    | Alice    |
| Eve      | Bob      |
| Frank    | Alice    |
| Grace    | Alice    |
| Henry    | Charlie  |
| Ivy      | Frank    |
| Jack     | Grace    |
+----------+----------+
```

## 7.7 Multi-Table JOIN

```sql
-- Employees with their departments and project assignments
SELECT
    e.first_name,
    d.department_name,
    p.project_name,
    ep.role,
    ep.hours_worked
FROM employees e
JOIN departments d       ON e.department_id = d.department_id
JOIN employee_projects ep ON e.employee_id   = ep.employee_id
JOIN projects p          ON ep.project_id    = p.project_id
ORDER BY e.first_name;
```

**Output:**
```
+----------+--------------+-------------------+-----------+-------+
| first    | department   | project           | role      | hours |
+----------+--------------+-------------------+-----------+-------+
| Alice    | Engineering  | Website Redesign  | Lead      |   200 |
| Alice    | Engineering  | Mobile App        | Architect |   150 |
| Bob      | Marketing    | Marketing Campaign| Lead      |   220 |
| Charlie  | Engineering  | Mobile App        | Developer |   300 |
| Charlie  | Engineering  | Data Migration    | Lead      |   250 |
| Eve      | Marketing    | Marketing Campaign| Coordinator| 160  |
| Frank    | Finance      | Data Migration    | Analyst   |   190 |
| Grace    | Sales        | Website Redesign  | Sales Rep |   120 |
| Henry    | Engineering  | Mobile App        | Developer |   180 |
| Ivy      | Finance      | Data Migration    | Analyst   |   175 |
+----------+--------------+-------------------+-----------+-------+
```

## 7.8 NATURAL JOIN

Automatically joins on columns with the same name (use with caution).

```sql
SELECT e.first_name, d.department_name
FROM employees e
NATURAL JOIN departments d;
-- Automatically joins on 'department_id' (common column)
```

---

# 8. 🎯 SUBQUERIES & NESTED QUERIES

A subquery is a query **inside** another query.

## 8.1 Subquery in WHERE

```sql
-- Find employees who earn more than the average salary
SELECT first_name, salary
FROM employees
WHERE salary > (SELECT AVG(salary) FROM employees);
```

**Output:**
```
+----------+--------+
| first    | salary |
+----------+--------+
| Alice    | 95000  |
| Charlie  | 105000 |
| Diana    | 78000  |
| Frank    | 88000  |
| Ivy      | 91000  |
+----------+--------+
```

## 8.2 Subquery with IN

```sql
-- Employees who work on 'Active' projects
SELECT first_name
FROM employees
WHERE employee_id IN (
    SELECT DISTINCT employee_id
    FROM employee_projects
    WHERE project_id IN (
        SELECT project_id
        FROM projects
        WHERE status = 'Active'
    )
);
```

## 8.3 Subquery in FROM (Derived Table)

```sql
-- Average salary by department, then find departments above overall average
SELECT
    dept_stats.department_id,
    dept_stats.avg_salary
FROM (
    SELECT department_id, AVG(salary) AS avg_salary
    FROM employees
    GROUP BY department_id
) AS dept_stats
WHERE dept_stats.avg_salary > (SELECT AVG(salary) FROM employees);
```

## 8.4 Subquery in SELECT (Scalar Subquery)

```sql
SELECT
    first_name,
    salary,
    (SELECT AVG(salary) FROM employees) AS company_avg,
    salary - (SELECT AVG(salary) FROM employees) AS diff_from_avg
FROM employees;
```

## 8.5 Correlated Subquery

A subquery that references the outer query. Runs once **for each row** of the outer query.

```sql
-- Employees who earn more than the average salary in THEIR department
SELECT first_name, salary, department_id
FROM employees e1
WHERE salary > (
    SELECT AVG(salary)
    FROM employees e2
    WHERE e2.department_id = e1.department_id   -- ← references outer query!
);
```

**Output:**
```
+----------+--------+---------------+
| first    | salary | department_id |
+----------+--------+---------------+
| Alice    | 95000  |             1 |  ← Dept 1 avg ≈ 86000
| Charlie  | 105000 |             1 |
| Bob      | 62000  |             2 |  ← Dept 2 avg = 58500
| Ivy      | 91000  |             4 |  ← Dept 4 avg = 89500
| Grace    | 72000  |             5 |  ← Dept 5 avg = 69500
+----------+--------+---------------+
```

## 8.6 EXISTS & NOT EXISTS

```sql
-- Departments that have at least one employee
SELECT department_name
FROM departments d
WHERE EXISTS (
    SELECT 1 FROM employees e
    WHERE e.department_id = d.department_id
);

-- Employees NOT assigned to any project
SELECT first_name
FROM employees e
WHERE NOT EXISTS (
    SELECT 1 FROM employee_projects ep
    WHERE ep.employee_id = e.employee_id
);
```

---

# 9. 🔀 SET OPERATIONS

Combine results from multiple SELECT statements.

```
┌───────────────┬──────────────────────────────────────────────┐
│ Operation     │ Description                                  │
├───────────────┼──────────────────────────────────────────────┤
│ UNION         │ Combines results, removes duplicates         │
│ UNION ALL     │ Combines results, keeps duplicates           │
│ INTERSECT     │ Only rows common to both queries             │
│ EXCEPT/MINUS  │ Rows in first query but NOT in second        │
└───────────────┴──────────────────────────────────────────────┘
```

```sql
-- UNION: Employees in Engineering OR earning > 90000 (no duplicates)
SELECT first_name, salary FROM employees WHERE department_id = 1
UNION
SELECT first_name, salary FROM employees WHERE salary > 90000;

-- UNION ALL: Keeps duplicates (faster, no dedup)
SELECT first_name FROM employees WHERE department_id = 1
UNION ALL
SELECT first_name FROM employees WHERE salary > 90000;

-- INTERSECT: Employees in Engineering AND earning > 90000
SELECT first_name FROM employees WHERE department_id = 1
INTERSECT
SELECT first_name FROM employees WHERE salary > 90000;
-- Result: Alice, Charlie

-- EXCEPT: In Engineering but NOT earning > 90000
SELECT first_name FROM employees WHERE department_id = 1
EXCEPT
SELECT first_name FROM employees WHERE salary > 90000;
-- Result: Henry
```

> ⚠️ Rules: Same number of columns, compatible data types, column names come from the first query.

---

# 10. 👁️ VIEWS

A **view** is a virtual table based on the result of a SELECT statement. It doesn't store data itself.

## 10.1 Creating Views

```sql
CREATE VIEW v_employee_details AS
SELECT
    e.employee_id,
    e.first_name,
    e.last_name,
    d.department_name,
    e.salary,
    m.first_name AS manager_name
FROM employees e
JOIN departments d ON e.department_id = d.department_id
LEFT JOIN employees m ON e.manager_id = m.employee_id;

-- Using the view (just like a table!)
SELECT * FROM v_employee_details WHERE salary > 80000;
```

## 10.2 Updatable Views

```sql
-- Simple views can sometimes be updated
CREATE VIEW v_engineering AS
SELECT employee_id, first_name, salary
FROM employees
WHERE department_id = 1;

-- This updates the underlying table
UPDATE v_engineering SET salary = 100000 WHERE employee_id = 1;
```

## 10.3 WITH CHECK OPTION

```sql
CREATE VIEW v_engineering_checked AS
SELECT employee_id, first_name, salary, department_id
FROM employees
WHERE department_id = 1
WITH CHECK OPTION;

-- This would FAIL because department_id = 2 violates the view's WHERE
UPDATE v_engineering_checked
SET department_id = 2
WHERE employee_id = 1;
-- ERROR: CHECK OPTION failed
```

## 10.4 Drop / Replace Views

```sql
DROP VIEW IF EXISTS v_employee_details;

CREATE OR REPLACE VIEW v_employee_details AS
SELECT ... ;  -- new definition
```

---
---

# PART 3: ADVANCED

---

# 11. ⚡ INDEXES & PERFORMANCE

An **index** is a data structure that speeds up data retrieval (like a book's index).

## 11.1 Types of Indexes

```
┌──────────────────────┬─────────────────────────────────────────┐
│ Index Type           │ Description                             │
├──────────────────────┼─────────────────────────────────────────┤
│ Single-Column Index  │ Index on one column                     │
│ Composite Index      │ Index on multiple columns               │
│ Unique Index         │ Ensures all values are unique           │
│ Clustered Index      │ Determines physical order of data       │
│                      │ (only ONE per table)                    │
│ Non-Clustered Index  │ Separate structure pointing to data     │
│                      │ (multiple per table)                    │
│ Full-Text Index      │ For text searching                      │
│ Partial/Filtered     │ Index on a subset of rows               │
│ Covering Index       │ Contains all columns needed by a query  │
└──────────────────────┴─────────────────────────────────────────┘
```

## 11.2 Creating Indexes

```sql
-- Basic index
CREATE INDEX idx_emp_salary ON employees(salary);

-- Composite index
CREATE INDEX idx_emp_dept_salary ON employees(department_id, salary);

-- Unique index
CREATE UNIQUE INDEX idx_emp_email ON employees(email);

-- Drop an index
DROP INDEX idx_emp_salary ON employees;
```

## 11.3 When to Use / Not Use Indexes

```
✅ USE indexes on:               ❌ AVOID indexes on:
─────────────────────            ──────────────────────
• Columns in WHERE clauses       • Small tables
• Columns in JOIN conditions     • Columns with low cardinality
• Columns in ORDER BY            • Frequently updated columns
• Columns in GROUP BY            • Wide columns (TEXT, BLOB)
• Foreign key columns            • Tables with heavy INSERT/UPDATE
```

## 11.4 How Indexes Work (B-Tree Visualization)

```
                    [50]
                   /    \
              [25]        [75]
             /    \      /    \
          [10,20] [30,40] [60,70] [80,90]
            ↓       ↓       ↓       ↓
          data    data    data    data

Without index: Full table scan → O(n)
With B-Tree index: Binary search → O(log n)

Table with 1,000,000 rows:
  Without index: scans up to 1,000,000 rows
  With index: finds data in ~20 steps
```

---

# 12. 🔒 TRANSACTIONS & ACID PROPERTIES

A **transaction** is a sequence of operations treated as a single unit.

## 12.1 ACID Properties

```
┌──────────────────┬─────────────────────────────────────────────────┐
│ Property         │ Meaning                                         │
├──────────────────┼─────────────────────────────────────────────────┤
│ Atomicity        │ All or nothing – either all operations succeed  │
│                  │ or none do                                      │
├──────────────────┼─────────────────────────────────────────────────┤
│ Consistency      │ Database moves from one valid state to another  │
├──────────────────┼─────────────────────────────────────────────────┤
│ Isolation        │ Concurrent transactions don't interfere with    │
│                  │ each other                                      │
├──────────────────┼─────────────────────────────────────────────────┤
│ Durability       │ Once committed, changes are permanent even if   │
│                  │ system crashes                                  │
└──────────────────┴─────────────────────────────────────────────────┘
```

## 12.2 Transaction Commands

```sql
-- Basic transaction
START TRANSACTION;  -- or BEGIN

UPDATE accounts SET balance = balance - 500 WHERE account_id = 1;
UPDATE accounts SET balance = balance + 500 WHERE account_id = 2;

-- If everything is OK:
COMMIT;

-- If something went wrong:
ROLLBACK;
```

## 12.3 SAVEPOINT

```sql
START TRANSACTION;

INSERT INTO orders VALUES (1, 'Product A', 100);
SAVEPOINT sp1;

INSERT INTO orders VALUES (2, 'Product B', 200);
SAVEPOINT sp2;

INSERT INTO orders VALUES (3, 'Product C', 300);

-- Oops, undo only the last insert
ROLLBACK TO sp2;

-- Commit orders 1 and 2 only
COMMIT;
```

## 12.4 Practical Example: Bank Transfer

```sql
DELIMITER //
CREATE PROCEDURE transfer_money(
    IN from_account INT,
    IN to_account INT,
    IN amount DECIMAL(10,2)
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SELECT 'Transfer failed! Rolled back.' AS message;
    END;

    START TRANSACTION;

    -- Check sufficient balance
    IF (SELECT balance FROM accounts WHERE account_id = from_account) < amount THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Insufficient funds';
    END IF;

    -- Debit
    UPDATE accounts SET balance = balance - amount WHERE account_id = from_account;

    -- Credit
    UPDATE accounts SET balance = balance + amount WHERE account_id = to_account;

    COMMIT;
    SELECT 'Transfer successful!' AS message;
END //
DELIMITER ;
```

---

# 13. 📐 DATABASE NORMALIZATION

Normalization is the process of organizing data to **reduce redundancy** and **improve data integrity**.

## Unnormalized Table (The Problem)

```
+----+--------+----------+-----------+---------------------------+
| id | name   | dept     | dept_head | courses                   |
+----+--------+----------+-----------+---------------------------+
|  1 | Alice  | CS       | Dr. Smith | Math, Physics, CS101      |
|  2 | Bob    | CS       | Dr. Smith | Math, CS101               |
|  3 | Charlie| EE       | Dr. Jones | Physics, Circuits         |
+----+--------+----------+-----------+---------------------------+

Problems:
❌ Multiple values in one cell (courses)
❌ Repeated data (dept_head appears multiple times)
❌ Update anomaly: Change Dr. Smith → must update all rows
❌ Deletion anomaly: Delete Bob → might lose course info
❌ Insertion anomaly: Can't add a department without a student
```

## 13.1 First Normal Form (1NF)

> **Rule:** Each cell must contain a single (atomic) value. No repeating groups.

```
students:
+----+--------+----------+-----------+
| id | name   | dept     | dept_head |
+----+--------+----------+-----------+
|  1 | Alice  | CS       | Dr. Smith |
|  2 | Bob    | CS       | Dr. Smith |
|  3 | Charlie| EE       | Dr. Jones |
+----+--------+----------+-----------+

student_courses:
+------------+-----------+
| student_id | course    |
+------------+-----------+
|          1 | Math      |
|          1 | Physics   |
|          1 | CS101     |
|          2 | Math      |
|          2 | CS101     |
|          3 | Physics   |
|          3 | Circuits  |
+------------+-----------+

✅ Each cell has one value
✅ No repeating groups
```

## 13.2 Second Normal Form (2NF)

> **Rule:** Must be in 1NF + no partial dependency (every non-key column depends on the **entire** primary key).

```
If student_courses had extra info:
+------------+---------+-------------+
| student_id | course  | course_hours|  ← course_hours depends only on
+------------+---------+-------------+     course, not on student_id
|          1 | Math    |           3 |
|          2 | Math    |           3 |  ← Redundant!

FIX: Separate into two tables:

student_courses:               courses:
+------------+---------+       +---------+-------------+
| student_id | course  |       | course  | course_hours|
+------------+---------+       +---------+-------------+
|          1 | Math    |       | Math    |           3 |
|          2 | Math    |       | Physics |           4 |
+------------+---------+       +---------+-------------+

✅ No partial dependencies
```

## 13.3 Third Normal Form (3NF)

> **Rule:** Must be in 2NF + no transitive dependency (non-key columns depend ONLY on the primary key, not on other non-key columns).

```
Problem in students table:
+----+--------+----------+-----------+
| id | name   | dept     | dept_head |  ← dept_head depends on dept,
+----+--------+----------+-----------+     NOT directly on student id

Transitive: id → dept → dept_head  (BAD!)

FIX: Split!

students:                    departments:
+----+--------+---------+   +---------+-----------+
| id | name   | dept_id |   | dept_id | dept_name | dept_head  |
+----+--------+---------+   +---------+-----------+------------+
|  1 | Alice  |       1 |   |       1 | CS        | Dr. Smith  |
|  2 | Bob    |       1 |   |       2 | EE        | Dr. Jones  |
|  3 | Charlie|       2 |   +---------+-----------+------------+
+----+--------+---------+

✅ No transitive dependencies
```

## 13.4 BCNF (Boyce-Codd Normal Form)

> **Rule:** Must be in 3NF + every determinant must be a candidate key.

```
Scenario: Students can have multiple advisors per subject
+-----------+---------+---------+
| student   | subject | advisor |
+-----------+---------+---------+
| Alice     | DB      | Prof X  |
| Alice     | OS      | Prof Y  |
| Bob       | DB      | Prof X  |

Functional dependency: advisor → subject
But advisor is NOT a candidate key!

FIX:
advisor_subjects:         student_advisors:
+---------+---------+    +-----------+---------+
| advisor | subject |    | student   | advisor |
+---------+---------+    +-----------+---------+
| Prof X  | DB      |    | Alice     | Prof X  |
| Prof Y  | OS      |    | Alice     | Prof Y  |
+---------+---------+    | Bob       | Prof X  |
                         +-----------+---------+
```

## Summary Table

```
┌──────┬──────────────────────────────────────────────────┐
│ Form │ Rule                                             │
├──────┼──────────────────────────────────────────────────┤
│ 1NF  │ Atomic values, no repeating groups               │
│ 2NF  │ 1NF + No partial dependencies                   │
│ 3NF  │ 2NF + No transitive dependencies                │
│ BCNF │ 3NF + Every determinant is a candidate key      │
│ 4NF  │ BCNF + No multi-valued dependencies             │
│ 5NF  │ 4NF + No join dependencies                      │
└──────┴──────────────────────────────────────────────────┘
```

---

# 14. 🪟 WINDOW FUNCTIONS

Window functions perform calculations across a set of rows **related to the current row** — without collapsing rows like GROUP BY.

## Syntax
```sql
function_name() OVER (
    [PARTITION BY column(s)]
    [ORDER BY column(s)]
    [ROWS/RANGE frame_specification]
)
```

## 14.1 ROW_NUMBER, RANK, DENSE_RANK

```sql
SELECT
    first_name,
    department_id,
    salary,
    ROW_NUMBER() OVER (ORDER BY salary DESC) AS row_num,
    RANK()       OVER (ORDER BY salary DESC) AS rank_val,
    DENSE_RANK() OVER (ORDER BY salary DESC) AS dense_rank_val
FROM employees;
```

**Output:**
```
+----------+------+--------+---------+------+------------+
| first    | dept | salary | row_num | rank | dense_rank |
+----------+------+--------+---------+------+------------+
| Charlie  |    1 | 105000 |       1 |    1 |          1 |
| Alice    |    1 |  95000 |       2 |    2 |          2 |
| Ivy      |    4 |  91000 |       3 |    3 |          3 |
| Frank    |    4 |  88000 |       4 |    4 |          4 |
| Diana    |    3 |  78000 |       5 |    5 |          5 |
| Grace    |    5 |  72000 |       6 |    6 |          6 |
| Jack     |    5 |  67000 |       7 |    7 |          7 |
| Bob      |    2 |  62000 |       8 |    8 |          8 |
| Henry    |    1 |  58000 |       9 |    9 |          9 |
| Eve      |    2 |  55000 |      10 |   10 |         10 |
+----------+------+--------+---------+------+------------+
```

### The Difference (with ties):
```
If two employees had salary = 91000:

ROW_NUMBER: 3, 4     ← Always unique, arbitrary order for ties
RANK:       3, 3     ← Same rank for ties, SKIPS next (→ 5)
DENSE_RANK: 3, 3     ← Same rank for ties, NO skip (→ 4)
```

## 14.2 PARTITION BY

```sql
-- Rank within each department
SELECT
    first_name,
    department_id,
    salary,
    RANK() OVER (
        PARTITION BY department_id
        ORDER BY salary DESC
    ) AS dept_rank
FROM employees;
```

**Output:**
```
+----------+------+--------+-----------+
| first    | dept | salary | dept_rank |
+----------+------+--------+-----------+
| Charlie  |    1 | 105000 |         1 |  ← Rank within dept 1
| Alice    |    1 |  95000 |         2 |
| Henry    |    1 |  58000 |         3 |
| Bob      |    2 |  62000 |         1 |  ← Rank within dept 2
| Eve      |    2 |  55000 |         2 |
| Diana    |    3 |  78000 |         1 |  ← Rank within dept 3
| Ivy      |    4 |  91000 |         1 |  ← Rank within dept 4
| Frank    |    4 |  88000 |         2 |
| Grace    |    5 |  72000 |         1 |  ← Rank within dept 5
| Jack     |    5 |  67000 |         2 |
+----------+------+--------+-----------+
```

## 14.3 Aggregate Window Functions

```sql
SELECT
    first_name,
    department_id,
    salary,
    SUM(salary) OVER (PARTITION BY department_id)  AS dept_total,
    AVG(salary) OVER (PARTITION BY department_id)  AS dept_avg,
    COUNT(*)    OVER (PARTITION BY department_id)  AS dept_count,
    salary - AVG(salary) OVER (PARTITION BY department_id) AS diff_from_dept_avg
FROM employees;
```

**Output:**
```
+----------+------+--------+----------+----------+-------+---------+
| first    | dept | salary | dept_tot | dept_avg | count | diff    |
+----------+------+--------+----------+----------+-------+---------+
| Alice    |    1 |  95000 |   258000 |  86000.0 |     3 |  9000.0 |
| Charlie  |    1 | 105000 |   258000 |  86000.0 |     3 | 19000.0 |
| Henry    |    1 |  58000 |   258000 |  86000.0 |     3 |-28000.0 |
| Bob      |    2 |  62000 |   117000 |  58500.0 |     2 |  3500.0 |
| Eve      |    2 |  55000 |   117000 |  58500.0 |     2 | -3500.0 |
+----------+------+--------+----------+----------+-------+---------+
```

## 14.4 LAG & LEAD

Access previous or next row's value.

```sql
SELECT
    first_name,
    hire_date,
    salary,
    LAG(salary, 1)  OVER (ORDER BY hire_date) AS prev_salary,
    LEAD(salary, 1) OVER (ORDER BY hire_date) AS next_salary,
    salary - LAG(salary, 1) OVER (ORDER BY hire_date) AS salary_diff
FROM employees
ORDER BY hire_date;
```

**Output:**
```
+----------+------------+--------+------+------+------+
| first    | hire_date  | salary | prev | next | diff |
+----------+------------+--------+------+------+------+
| Diana    | 2018-11-05 |  78000 | NULL | 62000| NULL |
| Bob      | 2019-03-22 |  62000 | 78000| 67000|-16000|
| Jack     | 2019-08-20 |  67000 | 62000| 95000|  5000|
| Alice    | 2020-01-15 |  95000 | 67000| 88000| 28000|
| Frank    | 2020-09-14 |  88000 | 95000|105000| -7000|
| Charlie  | 2021-07-10 | 105000 | 88000| 72000| 17000|
| ...      |            |        |      |      |      |
+----------+------------+--------+------+------+------+
```

## 14.5 FIRST_VALUE, LAST_VALUE, NTH_VALUE

```sql
SELECT
    first_name,
    department_id,
    salary,
    FIRST_VALUE(first_name) OVER (
        PARTITION BY department_id ORDER BY salary DESC
    ) AS highest_earner,
    LAST_VALUE(first_name) OVER (
        PARTITION BY department_id ORDER BY salary DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS lowest_earner
FROM employees;
```

## 14.6 Running Totals & Moving Averages

```sql
-- Running total of salary (ordered by hire date)
SELECT
    first_name,
    hire_date,
    salary,
    SUM(salary) OVER (
        ORDER BY hire_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_total,
    AVG(salary) OVER (
        ORDER BY hire_date
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS moving_avg_3
FROM employees
ORDER BY hire_date;
```

## 14.7 Window Frame Specifications

```
ROWS BETWEEN ... AND ...

Options:
  UNBOUNDED PRECEDING  → From the very first row
  n PRECEDING          → n rows before current
  CURRENT ROW          → The current row
  n FOLLOWING          → n rows after current
  UNBOUNDED FOLLOWING  → To the very last row

Examples:
┌─────────────────────────────────────────────────────────────┐
│ ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW           │
│ → Running total from start to current row                   │
│                                                             │
│ ROWS BETWEEN 2 PRECEDING AND 2 FOLLOWING                   │
│ → 5-row window centered on current row                      │
│                                                             │
│ ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING   │
│ → Entire partition                                          │
└─────────────────────────────────────────────────────────────┘
```

## 14.8 NTILE

Distributes rows into a specified number of roughly equal groups.

```sql
SELECT
    first_name,
    salary,
    NTILE(4) OVER (ORDER BY salary DESC) AS quartile
FROM employees;
```

**Output:**
```
+----------+--------+----------+
| first    | salary | quartile |
+----------+--------+----------+
| Charlie  | 105000 |        1 |  ← Top 25%
| Alice    |  95000 |        1 |
| Ivy      |  91000 |        1 |
| Frank    |  88000 |        2 |  ← 25-50%
| Diana    |  78000 |        2 |
| Grace    |  72000 |        2 |
| Jack     |  67000 |        3 |  ← 50-75%
| Bob      |  62000 |        3 |
| Henry    |  58000 |        4 |  ← Bottom 25%
| Eve      |  55000 |        4 |
+----------+--------+----------+
```

## 14.9 PERCENT_RANK & CUME_DIST

```sql
SELECT
    first_name,
    salary,
    PERCENT_RANK() OVER (ORDER BY salary) AS pct_rank,
    CUME_DIST()    OVER (ORDER BY salary) AS cume_dist
FROM employees;
```
```
PERCENT_RANK = (rank - 1) / (total rows - 1)
CUME_DIST    = (rows with value ≤ current) / total rows
```

---

# 15. 📦 COMMON TABLE EXPRESSIONS (CTEs)

A **CTE** is a temporary, named result set defined within a query. Think of it as a "temporary view" for a single query.

## 15.1 Basic CTE

```sql
WITH high_earners AS (
    SELECT
        first_name,
        salary,
        department_id
    FROM employees
    WHERE salary > 80000
)
SELECT
    h.first_name,
    h.salary,
    d.department_name
FROM high_earners h
JOIN departments d ON h.department_id = d.department_id;
```

## 15.2 Multiple CTEs

```sql
WITH
dept_stats AS (
    SELECT
        department_id,
        AVG(salary) AS avg_salary,
        COUNT(*)    AS emp_count
    FROM employees
    GROUP BY department_id
),
company_stats AS (
    SELECT AVG(salary) AS company_avg FROM employees
)
SELECT
    d.department_name,
    ds.avg_salary,
    ds.emp_count,
    cs.company_avg,
    ds.avg_salary - cs.company_avg AS diff
FROM dept_stats ds
JOIN departments d ON ds.department_id = d.department_id
CROSS JOIN company_stats cs
ORDER BY diff DESC;
```

**Output:**
```
+--------------+----------+---------+----------+---------+
| department   | avg_sal  | emp_cnt | comp_avg | diff    |
+--------------+----------+---------+----------+---------+
| Finance      | 89500.00 |       2 | 77100.00 | 12400.0 |
| Engineering  | 86000.00 |       3 | 77100.00 |  8900.0 |
| HR           | 78000.00 |       1 | 77100.00 |   900.0 |
| Sales        | 69500.00 |       2 | 77100.00 | -7600.0 |
| Marketing    | 58500.00 |       2 | 77100.00 |-18600.0 |
+--------------+----------+---------+----------+---------+
```

## CTE vs Subquery vs View

```
┌──────────────┬───────────────────────────────────────────────┐
│ Feature      │ CTE          │ Subquery       │ View         │
├──────────────┼──────────────┼────────────────┼──────────────┤
│ Scope        │ Single query │ Single query   │ Permanent    │
│ Readability  │ ✅ High      │ ❌ Can be messy │ ✅ High      │
│ Reusable     │ Within query │ No             │ Yes          │
│ Recursive    │ ✅ Yes       │ ❌ No           │ ❌ No        │
│ Performance  │ Same as sub  │ Same as CTE    │ Can be cached│
│ Stored in DB │ No           │ No             │ Yes          │
└──────────────┴──────────────┴────────────────┴──────────────┘
```

---

# 16. 🔧 STORED PROCEDURES & FUNCTIONS

## 16.1 Stored Procedures

A stored procedure is a **prepared SQL code** saved in the database that you can call repeatedly.

```sql
-- Creating a stored procedure
DELIMITER //
CREATE PROCEDURE GetEmployeesByDepartment(IN dept_name VARCHAR(100))
BEGIN
    SELECT
        e.first_name,
        e.last_name,
        e.salary,
        d.department_name
    FROM employees e
    JOIN departments d ON e.department_id = d.department_id
    WHERE d.department_name = dept_name
    ORDER BY e.salary DESC;
END //
DELIMITER ;

-- Calling the procedure
CALL GetEmployeesByDepartment('Engineering');
```

### Procedure with IN, OUT, INOUT Parameters

```sql
DELIMITER //
CREATE PROCEDURE GetDeptStats(
    IN  dept_id INT,
    OUT total_emp INT,
    OUT avg_sal DECIMAL(10,2),
    OUT max_sal DECIMAL(10,2)
)
BEGIN
    SELECT
        COUNT(*),
        AVG(salary),
        MAX(salary)
    INTO total_emp, avg_sal, max_sal
    FROM employees
    WHERE department_id = dept_id;
END //
DELIMITER ;

-- Calling
CALL GetDeptStats(1, @total, @avg, @max);
SELECT @total AS total_employees, @avg AS avg_salary, @max AS max_salary;
```

### Procedure with Control Flow

```sql
DELIMITER //
CREATE PROCEDURE GiveRaise(
    IN emp_id INT,
    IN raise_percent DECIMAL(5,2)
)
BEGIN
    DECLARE current_sal DECIMAL(10,2);
    DECLARE new_sal DECIMAL(10,2);

    -- Get current salary
    SELECT salary INTO current_sal FROM employees WHERE employee_id = emp_id;

    -- Validate
    IF current_sal IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Employee not found';
    ELSEIF raise_percent > 50 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Raise cannot exceed 50%';
    ELSE
        SET new_sal = current_sal * (1 + raise_percent / 100);

        UPDATE employees SET salary = new_sal WHERE employee_id = emp_id;

        SELECT CONCAT('Salary updated from ', current_sal, ' to ', new_sal) AS result;
    END IF;
END //
DELIMITER ;
```

## 16.2 User-Defined Functions (UDF)

Functions **return a value** and can be used inside SQL statements.

```sql
DELIMITER //
CREATE FUNCTION CalculateBonus(salary DECIMAL(10,2), performance_rating INT)
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
    DECLARE bonus DECIMAL(10,2);

    CASE performance_rating
        WHEN 5 THEN SET bonus = salary * 0.20;
        WHEN 4 THEN SET bonus = salary * 0.15;
        WHEN 3 THEN SET bonus = salary * 0.10;
        WHEN 2 THEN SET bonus = salary * 0.05;
        ELSE SET bonus = 0;
    END CASE;

    RETURN bonus;
END //
DELIMITER ;

-- Using the function in a query
SELECT
    first_name,
    salary,
    CalculateBonus(salary, 4) AS bonus,
    salary + CalculateBonus(salary, 4) AS total_compensation
FROM employees;
```

```
┌──────────────────┬────────────────────────────────────────────┐
│ Feature          │ Procedure          │ Function              │
├──────────────────┼────────────────────┼───────────────────────┤
│ Returns          │ 0 or more values   │ Exactly 1 value       │
│ Called with      │ CALL statement     │ Inside SQL queries    │
│ Can modify data  │ ✅ Yes (DML)       │ ❌ No (typically)     │
│ Used in SELECT   │ ❌ No              │ ✅ Yes                │
│ Transaction      │ ✅ Can use         │ ❌ Cannot use          │
│ Parameters       │ IN, OUT, INOUT     │ IN only               │
└──────────────────┴────────────────────┴───────────────────────┘
```

---

# 17. ⚡ TRIGGERS

A **trigger** is a stored procedure that automatically executes when a specified event occurs on a table.

## 17.1 Types of Triggers

```
┌────────────────┬───────────────────────┐
│ Timing         │ Event                 │
├────────────────┼───────────────────────┤
│ BEFORE INSERT  │ Before a new row      │
│ AFTER INSERT   │ After a new row       │
│ BEFORE UPDATE  │ Before row is changed │
│ AFTER UPDATE   │ After row is changed  │
│ BEFORE DELETE  │ Before row is removed │
│ AFTER DELETE   │ After row is removed  │
└────────────────┴───────────────────────┘
```

## 17.2 Audit Trail Trigger

```sql
-- Create audit table
CREATE TABLE salary_audit (
    audit_id     INT PRIMARY KEY AUTO_INCREMENT,
    employee_id  INT,
    old_salary   DECIMAL(10,2),
    new_salary   DECIMAL(10,2),
    changed_by   VARCHAR(100),
    changed_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    action_type  VARCHAR(10)
);

-- Create trigger
DELIMITER //
CREATE TRIGGER trg_salary_change
AFTER UPDATE ON employees
FOR EACH ROW
BEGIN
    IF OLD.salary <> NEW.salary THEN
        INSERT INTO salary_audit
            (employee_id, old_salary, new_salary, changed_by, action_type)
        VALUES
            (OLD.employee_id, OLD.salary, NEW.salary, CURRENT_USER(), 'UPDATE');
    END IF;
END //
DELIMITER ;

-- Now when we update salary, the trigger fires automatically
UPDATE employees SET salary = 100000 WHERE employee_id = 1;

-- Check audit log
SELECT * FROM salary_audit;
```

**Output:**
```
+----------+-----+--------+--------+--------+---------------------+--------+
| audit_id | emp | old_sal| new_sal| changed| changed_at          | action |
+----------+-----+--------+--------+--------+---------------------+--------+
|        1 |   1 |  95000 | 100000 | root@  | 2024-01-15 10:30:00 | UPDATE |
+----------+-----+--------+--------+--------+---------------------+--------+
```

## 17.3 Validation Trigger

```sql
DELIMITER //
CREATE TRIGGER trg_validate_salary
BEFORE INSERT ON employees
FOR EACH ROW
BEGIN
    IF NEW.salary < 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Salary cannot be negative';
    END IF;

    IF NEW.salary > 500000 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Salary exceeds maximum allowed';
    END IF;
END //
DELIMITER ;
```

## 17.4 Cascade Update Trigger

```sql
DELIMITER //
CREATE TRIGGER trg_update_dept_budget
AFTER INSERT ON employees
FOR EACH ROW
BEGIN
    -- Automatically recalculate department budget usage
    UPDATE departments
    SET budget = budget - NEW.salary
    WHERE department_id = NEW.department_id;
END //
DELIMITER ;
```

---

# 18. 🔄 CURSORS

A **cursor** allows you to process rows **one at a time** (row-by-row processing).

> ⚠️ Cursors are generally slow. Prefer set-based operations when possible.

```sql
DELIMITER //
CREATE PROCEDURE ProcessEmployeeRaises()
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE emp_id INT;
    DECLARE emp_salary DECIMAL(10,2);
    DECLARE emp_dept INT;
    DECLARE raise_pct DECIMAL(5,2);

    -- Declare cursor
    DECLARE emp_cursor CURSOR FOR
        SELECT employee_id, salary, department_id
        FROM employees
        WHERE is_active = TRUE;

    -- Handler for when cursor reaches end
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    -- Open cursor
    OPEN emp_cursor;

    -- Loop through rows
    read_loop: LOOP
        FETCH emp_cursor INTO emp_id, emp_salary, emp_dept;

        IF done THEN
            LEAVE read_loop;
        END IF;

        -- Business logic: different raise per department
        CASE emp_dept
            WHEN 1 THEN SET raise_pct = 10.0;  -- Engineering: 10%
            WHEN 2 THEN SET raise_pct = 8.0;   -- Marketing: 8%
            WHEN 3 THEN SET raise_pct = 7.0;   -- HR: 7%
            ELSE SET raise_pct = 5.0;           -- Others: 5%
        END CASE;

        -- Apply raise
        UPDATE employees
        SET salary = salary * (1 + raise_pct / 100)
        WHERE employee_id = emp_id;
    END LOOP;

    -- Close cursor
    CLOSE emp_cursor;

    SELECT 'All raises processed successfully' AS result;
END //
DELIMITER ;

CALL ProcessEmployeeRaises();
```

---

# 19. 🧬 DYNAMIC SQL

Dynamic SQL constructs and executes SQL statements **at runtime** as strings.

```sql
DELIMITER //
CREATE PROCEDURE DynamicSearch(
    IN search_column VARCHAR(50),
    IN search_value VARCHAR(100),
    IN sort_column VARCHAR(50),
    IN sort_direction VARCHAR(4)
)
BEGIN
    SET @sql = CONCAT(
        'SELECT employee_id, first_name, last_name, salary ',
        'FROM employees ',
        'WHERE ', search_column, ' LIKE ''%', search_value, '%'' ',
        'ORDER BY ', sort_column, ' ', sort_direction
    );

    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
END //
DELIMITER ;

-- Usage
CALL DynamicSearch('first_name', 'Ali', 'salary', 'DESC');
```

### Parameterized Dynamic SQL (Safer — prevents SQL injection)

```sql
DELIMITER //
CREATE PROCEDURE SafeSearch(
    IN search_value VARCHAR(100)
)
BEGIN
    SET @sql = 'SELECT * FROM employees WHERE first_name = ?';
    SET @val = search_value;

    PREPARE stmt FROM @sql;
    EXECUTE stmt USING @val;
    DEALLOCATE PREPARE stmt;
END //
DELIMITER ;
```

---

# 20. 🔄 PIVOTING & UNPIVOTING

## 20.1 PIVOT (Rows to Columns)

Transform row data into columnar format.

```sql
-- Original data: employee count by department
-- Goal: Departments as columns

-- Using CASE with GROUP BY (works in all databases)
SELECT
    YEAR(hire_date) AS hire_year,
    SUM(CASE WHEN department_id = 1 THEN 1 ELSE 0 END) AS Engineering,
    SUM(CASE WHEN department_id = 2 THEN 1 ELSE 0 END) AS Marketing,
    SUM(CASE WHEN department_id = 3 THEN 1 ELSE 0 END) AS HR,
    SUM(CASE WHEN department_id = 4 THEN 1 ELSE 0 END) AS Finance,
    SUM(CASE WHEN department_id = 5 THEN 1 ELSE 0 END) AS Sales
FROM employees
GROUP BY YEAR(hire_date)
ORDER BY hire_year;
```

**Output:**
```
+-----------+------+------+----+------+-------+
| hire_year | Engr | Mktg | HR | Fin  | Sales |
+-----------+------+------+----+------+-------+
|      2018 |    0 |    0 |  1 |    0 |     0 |
|      2019 |    0 |    1 |  0 |    0 |     1 |
|      2020 |    1 |    0 |  0 |    1 |     0 |
|      2021 |    1 |    0 |  0 |    0 |     1 |
|      2022 |    0 |    1 |  0 |    1 |     0 |
|      2023 |    1 |    0 |  0 |    0 |     0 |
+-----------+------+------+----+------+-------+
```

### SQL Server PIVOT Syntax
```sql
SELECT *
FROM (
    SELECT YEAR(hire_date) AS hire_year, department_id, employee_id
    FROM employees
) AS source_data
PIVOT (
    COUNT(employee_id)
    FOR department_id IN ([1], [2], [3], [4], [5])
) AS pivot_table;
```

## 20.2 UNPIVOT (Columns to Rows)

```sql
-- SQL Server syntax
SELECT hire_year, department, emp_count
FROM pivot_table
UNPIVOT (
    emp_count FOR department IN ([Engineering], [Marketing], [HR], [Finance], [Sales])
) AS unpivot_table;

-- Generic approach using UNION ALL
SELECT 'Engineering' AS department, COUNT(*) AS emp_count
FROM employees WHERE department_id = 1
UNION ALL
SELECT 'Marketing', COUNT(*) FROM employees WHERE department_id = 2
UNION ALL
SELECT 'HR', COUNT(*) FROM employees WHERE department_id = 3;
```

---

# 21. 🌲 RECURSIVE QUERIES

Recursive CTEs allow you to query **hierarchical** or **tree-structured** data.

## 21.1 Organizational Hierarchy

```sql
WITH RECURSIVE org_chart AS (
    -- Anchor: Start with the top-level manager (no manager)
    SELECT
        employee_id,
        first_name,
        manager_id,
        0 AS level,
        CAST(first_name AS CHAR(500)) AS path
    FROM employees
    WHERE manager_id IS NULL

    UNION ALL

    -- Recursive: Find employees managed by current level
    SELECT
        e.employee_id,
        e.first_name,
        e.manager_id,
        oc.level + 1,
        CONCAT(oc.path, ' → ', e.first_name)
    FROM employees e
    INNER JOIN org_chart oc ON e.manager_id = oc.employee_id
)
SELECT
    CONCAT(REPEAT('    ', level), first_name) AS org_tree,
    level,
    path
FROM org_chart
ORDER BY path;
```

**Output:**
```
+----------------------+-------+----------------------------+
| org_tree             | level | path                       |
+----------------------+-------+----------------------------+
| Alice                |     0 | Alice                      |
|     Bob              |     1 | Alice → Bob                |
|         Eve          |     2 | Alice → Bob → Eve          |
|     Charlie          |     1 | Alice → Charlie            |
|         Henry        |     2 | Alice → Charlie → Henry    |
|     Diana            |     1 | Alice → Diana              |
|     Frank            |     1 | Alice → Frank              |
|         Ivy          |     2 | Alice → Frank → Ivy        |
|     Grace            |     1 | Alice → Grace              |
|         Jack         |     2 | Alice → Grace → Jack       |
+----------------------+-------+----------------------------+
```

## 21.2 Number Series Generator

```sql
WITH RECURSIVE numbers AS (
    SELECT 1 AS n
    UNION ALL
    SELECT n + 1 FROM numbers WHERE n < 100
)
SELECT n FROM numbers;
-- Generates: 1, 2, 3, ..., 100
```

## 21.3 Date Series

```sql
WITH RECURSIVE date_series AS (
    SELECT '2024-01-01' AS dt
    UNION ALL
    SELECT DATE_ADD(dt, INTERVAL 1 DAY)
    FROM date_series
    WHERE dt < '2024-01-31'
)
SELECT dt AS date FROM date_series;
-- Generates every date in January 2024
```

## 21.4 Bill of Materials / Parts Explosion

```sql
-- Table: components(part_id, part_name, parent_part_id, quantity)
WITH RECURSIVE bom AS (
    SELECT part_id, part_name, parent_part_id, quantity, 1 AS depth
    FROM components
    WHERE parent_part_id IS NULL  -- Top-level product

    UNION ALL

    SELECT c.part_id, c.part_name, c.parent_part_id,
           c.quantity * bom.quantity, bom.depth + 1
    FROM components c
    JOIN bom ON c.parent_part_id = bom.part_id
)
SELECT * FROM bom ORDER BY depth, part_name;
```

---

# 22. 🏎️ QUERY OPTIMIZATION & EXECUTION PLANS

## 22.1 EXPLAIN / Execution Plans

```sql
-- See how MySQL will execute a query
EXPLAIN SELECT e.first_name, d.department_name
FROM employees e
JOIN departments d ON e.department_id = d.department_id
WHERE e.salary > 80000;

-- More detail
EXPLAIN ANALYZE SELECT ...;
```

**Output:**
```
+----+------+----------+------+--------+------+----------+-----------+
| id | type | table    | type | key    | rows | filtered | Extra     |
+----+------+----------+------+--------+------+----------+-----------+
|  1 | SIMPLE| e       | ALL  | NULL   |   10 |    50.00 | Using where|
|  1 | SIMPLE| d       | eq_ref| PRIMARY|    1 |   100.00 | NULL      |
+----+------+----------+------+--------+------+----------+-----------+
```

### Key Columns in EXPLAIN

```
┌──────────┬──────────────────────────────────────────────────────┐
│ Column   │ What it tells you                                    │
├──────────┼──────────────────────────────────────────────────────┤
│ type     │ Join type (best → worst):                            │
│          │ system > const > eq_ref > ref > range > index > ALL  │
├──────────┼──────────────────────────────────────────────────────┤
│ key      │ Which index is being used (NULL = no index)          │
├──────────┼──────────────────────────────────────────────────────┤
│ rows     │ Estimated number of rows to examine                  │
├──────────┼──────────────────────────────────────────────────────┤
│ Extra    │ "Using index" = good; "Using filesort" = consider    │
│          │ optimization; "Using temporary" = costly             │
└──────────┴──────────────────────────────────────────────────────┘
```

## 22.2 Optimization Tips

### ❌ Bad Practices → ✅ Good Practices

```sql
-- ❌ BAD: SELECT *
SELECT * FROM employees;

-- ✅ GOOD: Select only needed columns
SELECT first_name, salary FROM employees;

-- ❌ BAD: Function on indexed column (prevents index usage)
SELECT * FROM employees WHERE YEAR(hire_date) = 2023;

-- ✅ GOOD: Use range instead
SELECT * FROM employees
WHERE hire_date >= '2023-01-01' AND hire_date < '2024-01-01';

-- ❌ BAD: Leading wildcard (can't use index)
SELECT * FROM employees WHERE last_name LIKE '%son';

-- ✅ GOOD: Trailing wildcard (can use index)
SELECT * FROM employees WHERE last_name LIKE 'John%';

-- ❌ BAD: OR on different columns
SELECT * FROM employees WHERE first_name = 'Alice' OR salary > 90000;

-- ✅ GOOD: Use UNION
SELECT * FROM employees WHERE first_name = 'Alice'
UNION
SELECT * FROM employees WHERE salary > 90000;

-- ❌ BAD: NOT IN with subquery (can be slow)
SELECT * FROM employees
WHERE department_id NOT IN (SELECT department_id FROM departments WHERE budget < 250000);

-- ✅ GOOD: LEFT JOIN + IS NULL
SELECT e.* FROM employees e
LEFT JOIN departments d ON e.department_id = d.department_id AND d.budget < 250000
WHERE d.department_id IS NULL;

-- ❌ BAD: Correlated subquery in SELECT (runs for each row)
SELECT e.first_name,
       (SELECT COUNT(*) FROM employee_projects ep WHERE ep.employee_id = e.employee_id) AS project_count
FROM employees e;

-- ✅ GOOD: JOIN with aggregation
SELECT e.first_name, COALESCE(pc.project_count, 0) AS project_count
FROM employees e
LEFT JOIN (
    SELECT employee_id, COUNT(*) AS project_count
    FROM employee_projects
    GROUP BY employee_id
) pc ON e.employee_id = pc.employee_id;
```

## 22.3 Index Optimization Strategy

```sql
-- Analyze which queries are slowest
SHOW FULL PROCESSLIST;

-- Check existing indexes
SHOW INDEX FROM employees;

-- For a query like:
SELECT * FROM employees
WHERE department_id = 1 AND salary > 80000
ORDER BY hire_date;

-- Create a composite covering index:
CREATE INDEX idx_dept_salary_hire
ON employees(department_id, salary, hire_date);
-- Column order matters! Put equality columns first, then range, then sort.
```

---

# 23. 🔐 LOCKING, CONCURRENCY & ISOLATION LEVELS

## 23.1 Types of Locks

```
┌──────────────────┬──────────────────────────────────────────────┐
│ Lock Type        │ Description                                  │
├──────────────────┼──────────────────────────────────────────────┤
│ Shared (S)       │ For READ operations. Multiple transactions   │
│                  │ can hold simultaneously.                     │
├──────────────────┼──────────────────────────────────────────────┤
│ Exclusive (X)    │ For WRITE operations. Only one transaction   │
│                  │ can hold at a time.                          │
├──────────────────┼──────────────────────────────────────────────┤
│ Row-Level Lock   │ Locks individual rows (most granular)        │
├──────────────────┼──────────────────────────────────────────────┤
│ Table-Level Lock │ Locks the entire table (less concurrent)     │
├──────────────────┼──────────────────────────────────────────────┤
│ Deadlock         │ Two transactions each waiting for the        │
│                  │ other's lock (DB auto-resolves)              │
└──────────────────┴──────────────────────────────────────────────┘
```

## 23.2 Concurrency Problems

```
┌────────────────────┬─────────────────────────────────────────────┐
│ Problem            │ Description                                 │
├────────────────────┼─────────────────────────────────────────────┤
│ Dirty Read         │ Reading uncommitted data from another       │
│                    │ transaction                                 │
├────────────────────┼─────────────────────────────────────────────┤
│ Non-Repeatable Read│ Same query returns different results within │
│                    │ the same transaction                        │
├────────────────────┼─────────────────────────────────────────────┤
│ Phantom Read       │ New rows appear in repeated queries due to  │
│                    │ another transaction's INSERT                │
├────────────────────┼─────────────────────────────────────────────┤
│ Lost Update        │ Two transactions update the same row,       │
│                    │ one overwrites the other                    │
└────────────────────┴─────────────────────────────────────────────┘
```

## 23.3 Isolation Levels

```
┌──────────────────────┬────────┬───────────────┬─────────┐
│ Isolation Level      │ Dirty  │ Non-Repeatable│ Phantom │
│                      │ Read   │ Read          │ Read    │
├──────────────────────┼────────┼───────────────┼─────────┤
│ READ UNCOMMITTED     │ ✅ Yes │ ✅ Yes        │ ✅ Yes  │
│ READ COMMITTED       │ ❌ No  │ ✅ Yes        │ ✅ Yes  │
│ REPEATABLE READ      │ ❌ No  │ ❌ No         │ ✅ Yes  │
│ SERIALIZABLE         │ ❌ No  │ ❌ No         │ ❌ No   │
├──────────────────────┼────────┴───────────────┴─────────┤
│ ↑ More concurrent    │                                   │
│ ↓ More isolated      │ (safer but slower)                │
└──────────────────────┴───────────────────────────────────┘
```

```sql
-- Set isolation level
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;

-- Check current level
SELECT @@transaction_isolation;

-- Example: Pessimistic locking
START TRANSACTION;
SELECT * FROM employees WHERE employee_id = 1 FOR UPDATE;
-- Row is locked until COMMIT or ROLLBACK
UPDATE employees SET salary = 100000 WHERE employee_id = 1;
COMMIT;

-- Example: Shared lock
SELECT * FROM employees WHERE employee_id = 1 LOCK IN SHARE MODE;
```

---

# 24. 📂 PARTITIONING

Partitioning divides a large table into smaller, more manageable pieces.

## 24.1 Types of Partitioning

```
┌──────────────────┬──────────────────────────────────────────────┐
│ Type             │ Description                                  │
├──────────────────┼──────────────────────────────────────────────┤
│ RANGE            │ Based on value ranges (e.g., dates)          │
│ LIST             │ Based on specific value lists                │
│ HASH             │ Based on hash function result                │
│ KEY              │ Like HASH but uses MySQL's internal hash     │
│ Composite        │ Combination (e.g., RANGE + HASH)            │
└──────────────────┴──────────────────────────────────────────────┘
```

## 24.2 Range Partitioning

```sql
CREATE TABLE orders (
    order_id    INT NOT NULL,
    customer_id INT NOT NULL,
    order_date  DATE NOT NULL,
    amount      DECIMAL(10,2),
    PRIMARY KEY (order_id, order_date)
)
PARTITION BY RANGE (YEAR(order_date)) (
    PARTITION p2020 VALUES LESS THAN (2021),
    PARTITION p2021 VALUES LESS THAN (2022),
    PARTITION p2022 VALUES LESS THAN (2023),
    PARTITION p2023 VALUES LESS THAN (2024),
    PARTITION p2024 VALUES LESS THAN (2025),
    PARTITION pmax  VALUES LESS THAN MAXVALUE
);

-- Query only scans relevant partition(s)
SELECT * FROM orders WHERE order_date BETWEEN '2023-01-01' AND '2023-12-31';
-- Only scans partition p2023!
```

## 24.3 List Partitioning

```sql
CREATE TABLE sales (
    sale_id   INT NOT NULL,
    region    VARCHAR(20) NOT NULL,
    amount    DECIMAL(10,2),
    PRIMARY KEY (sale_id, region)
)
PARTITION BY LIST COLUMNS (region) (
    PARTITION p_east   VALUES IN ('New York', 'Boston', 'Philadelphia'),
    PARTITION p_west   VALUES IN ('Los Angeles', 'San Francisco', 'Seattle'),
    PARTITION p_central VALUES IN ('Chicago', 'Dallas', 'Denver')
);
```

## 24.4 Managing Partitions

```sql
-- Add a new partition
ALTER TABLE orders ADD PARTITION (
    PARTITION p2025 VALUES LESS THAN (2026)
);

-- Drop old partition (fast deletion of old data!)
ALTER TABLE orders DROP PARTITION p2020;

-- Check which partition a query uses
EXPLAIN SELECT * FROM orders WHERE order_date = '2023-06-15';
```

---

# 25. 🔍 ADVANCED PATTERN MATCHING & REGULAR EXPRESSIONS

## 25.1 REGEXP / RLIKE

```sql
-- Find names starting with A, B, or C
SELECT first_name FROM employees
WHERE first_name REGEXP '^[ABC]';

-- Find names ending with a vowel
SELECT first_name FROM employees
WHERE first_name REGEXP '[aeiou]$';

-- Find names containing exactly 5 characters
SELECT first_name FROM employees
WHERE first_name REGEXP '^.{5}$';

-- Find email addresses with specific patterns
SELECT email FROM employees
WHERE email REGEXP '^[a-zA-Z0-9.]+@company\\.com$';
```

## 25.2 Common REGEXP Patterns

```
┌──────────┬─────────────────────────────────────┐
│ Pattern  │ Meaning                             │
├──────────┼─────────────────────────────────────┤
│ ^        │ Start of string                     │
│ $        │ End of string                       │
│ .        │ Any single character                │
│ *        │ Zero or more of previous            │
│ +        │ One or more of previous             │
│ ?        │ Zero or one of previous             │
│ [abc]    │ Any character in set                │
│ [^abc]   │ Any character NOT in set            │
│ [a-z]    │ Any character in range              │
│ {n}      │ Exactly n occurrences               │
│ {n,m}    │ Between n and m occurrences         │
│ |        │ OR (alternation)                    │
│ \\       │ Escape special character            │
└──────────┴─────────────────────────────────────┘
```

## 25.3 String Functions

```sql
SELECT
    CONCAT(first_name, ' ', last_name) AS full_name,
    UPPER(first_name)                  AS upper_name,
    LOWER(last_name)                   AS lower_name,
    LENGTH(first_name)                 AS name_length,
    SUBSTRING(email, 1, 5)            AS email_start,
    REPLACE(email, '@company.com', '') AS username,
    TRIM('  hello  ')                  AS trimmed,
    LPAD(employee_id, 5, '0')         AS emp_code,
    REVERSE(first_name)               AS reversed,
    LOCATE('@', email)                AS at_position
FROM employees;
```

---

# 🎯 BONUS: COMPREHENSIVE CHEAT SHEET

## SQL Order of Operations

```
┌─────────────────────────────────────────────────────────────┐
│                  SQL QUERY EXECUTION ORDER                   │
│                                                             │
│   1. FROM       → Which tables to use                       │
│   2. JOIN       → Combine tables                            │
│   3. WHERE      → Filter rows                               │
│   4. GROUP BY   → Group rows                                │
│   5. HAVING     → Filter groups                             │
│   6. SELECT     → Choose columns                            │
│   7. DISTINCT   → Remove duplicates                         │
│   8. ORDER BY   → Sort results                              │
│   9. LIMIT      → Restrict output                           │
└─────────────────────────────────────────────────────────────┘
```

## Essential Date Functions

```sql
SELECT
    NOW()                                    AS current_datetime,
    CURDATE()                                AS current_date,
    YEAR(hire_date)                          AS year,
    MONTH(hire_date)                         AS month,
    DAY(hire_date)                           AS day,
    DAYNAME(hire_date)                       AS day_name,
    DATEDIFF(NOW(), hire_date)              AS days_employed,
    DATE_ADD(hire_date, INTERVAL 1 YEAR)    AS one_year_later,
    DATE_FORMAT(hire_date, '%M %d, %Y')     AS formatted
FROM employees;
```

## NULL Handling

```sql
SELECT
    COALESCE(manager_id, 0)        AS mgr_or_zero,      -- First non-NULL
    IFNULL(manager_id, 'No Mgr')   AS mgr_or_text,      -- MySQL
    NULLIF(salary, 0)              AS salary_or_null,    -- Returns NULL if equal
    CASE WHEN manager_id IS NULL
         THEN 'Top Level'
         ELSE 'Has Manager'
    END AS mgr_status
FROM employees;
```

## Common Interview Queries

```sql
-- 1. Second highest salary
SELECT DISTINCT salary FROM employees ORDER BY salary DESC LIMIT 1 OFFSET 1;

-- Alternative with subquery
SELECT MAX(salary) FROM employees
WHERE salary < (SELECT MAX(salary) FROM employees);

-- 2. Nth highest salary (using DENSE_RANK)
WITH ranked AS (
    SELECT salary, DENSE_RANK() OVER (ORDER BY salary DESC) AS rnk
    FROM employees
)
SELECT DISTINCT salary FROM ranked WHERE rnk = 3;  -- 3rd highest

-- 3. Employees earning more than their manager
SELECT e.first_name AS employee, e.salary AS emp_salary,
       m.first_name AS manager, m.salary AS mgr_salary
FROM employees e
JOIN employees m ON e.manager_id = m.employee_id
WHERE e.salary > m.salary;

-- 4. Departments with no employees
SELECT d.department_name
FROM departments d
LEFT JOIN employees e ON d.department_id = e.department_id
WHERE e.employee_id IS NULL;

-- 5. Duplicate detection
SELECT email, COUNT(*) AS count
FROM employees
GROUP BY email
HAVING COUNT(*) > 1;

-- 6. Delete duplicates (keep lowest ID)
DELETE e1 FROM employees e1
INNER JOIN employees e2
WHERE e1.email = e2.email AND e1.employee_id > e2.employee_id;

-- 7. Year-over-year growth
WITH yearly AS (
    SELECT YEAR(hire_date) AS yr, COUNT(*) AS hires
    FROM employees GROUP BY YEAR(hire_date)
)
SELECT yr, hires,
       LAG(hires) OVER (ORDER BY yr) AS prev_year,
       hires - LAG(hires) OVER (ORDER BY yr) AS growth
FROM yearly;

-- 8. Running percentage
SELECT first_name, salary,
       SUM(salary) OVER (ORDER BY salary DESC) / SUM(salary) OVER () * 100
       AS running_pct
FROM employees;
```

---

# 🗺️ LEARNING ROADMAP

```
                    SQL MASTERY ROADMAP

Level 1: BEGINNER (Weeks 1-2)
├── SELECT, WHERE, ORDER BY, LIMIT
├── INSERT, UPDATE, DELETE
├── Data Types & Constraints
└── Basic Aggregate Functions

Level 2: INTERMEDIATE (Weeks 3-5)
├── JOINs (INNER, LEFT, RIGHT, FULL)
├── GROUP BY & HAVING
├── Subqueries
├── Set Operations (UNION, INTERSECT, EXCEPT)
└── Views

Level 3: ADVANCED (Weeks 6-10)
├── Window Functions
├── CTEs & Recursive Queries
├── Stored Procedures & Functions
├── Triggers
├── Indexes & Query Optimization
├── Transactions & ACID
├── Database Normalization (1NF → BCNF)
└── Execution Plans & Performance Tuning

Level 4: EXPERT (Ongoing)
├── Partitioning
├── Locking & Concurrency Control
├── Dynamic SQL
├── Database Design Patterns
├── Pivoting & Advanced Analytics
└── Database Administration Basics
```

---

> 📌 **Final Tip:** The best way to learn SQL is by **practicing**. Use platforms like **LeetCode**, **HackerRank**, **SQLZoo**, or **Mode Analytics** to solve real-world problems. Build projects with sample datasets. Every expert was once a beginner who refused to give up! 🚀