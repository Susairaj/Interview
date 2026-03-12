Databases: Complete Tech Lead Reference Guide

---

## 1. SQL CONCEPTS

---

### JOINS

Joins combine rows from two or more tables based on related columns.

```sql
-- Sample tables for all join examples
CREATE TABLE departments (
    id    SERIAL PRIMARY KEY,
    name  VARCHAR(100) NOT NULL
);

CREATE TABLE employees (
    id             SERIAL PRIMARY KEY,
    name           VARCHAR(100) NOT NULL,
    department_id  INT REFERENCES departments(id),
    manager_id     INT REFERENCES employees(id),
    salary         DECIMAL(10,2),
    hired_at       DATE
);

CREATE TABLE projects (
    id       SERIAL PRIMARY KEY,
    name     VARCHAR(100),
    lead_id  INT REFERENCES employees(id)
);

CREATE TABLE employee_projects (
    employee_id  INT REFERENCES employees(id),
    project_id   INT REFERENCES projects(id),
    role         VARCHAR(50),
    PRIMARY KEY (employee_id, project_id)
);

INSERT INTO departments VALUES
    (1, 'Engineering'), (2, 'Marketing'), (3, 'Sales'), (4, 'HR');

INSERT INTO employees VALUES
    (1, 'Alice',   1, NULL, 150000, '2020-01-15'),
    (2, 'Bob',     1, 1,   120000, '2020-06-01'),
    (3, 'Charlie', 2, NULL, 110000, '2019-03-20'),
    (4, 'Diana',   NULL, 1, 95000, '2021-09-10'),  -- no department
    (5, 'Eve',     1, 1,   130000, '2021-01-05');

INSERT INTO projects VALUES
    (1, 'Project Alpha', 1), (2, 'Project Beta', 3), (3, 'Project Gamma', NULL);

INSERT INTO employee_projects VALUES
    (1, 1, 'Lead'), (2, 1, 'Developer'), (5, 1, 'Developer'),
    (3, 2, 'Lead'), (1, 2, 'Consultant');
```

```sql
-- ============================================================
-- INNER JOIN: Only matching rows from BOTH tables
-- ============================================================
-- Returns employees who HAVE a department assigned
SELECT e.name AS employee, d.name AS department
FROM employees e
INNER JOIN departments d ON e.department_id = d.id;

-- Result:
-- employee | department
-- Alice    | Engineering
-- Bob      | Engineering
-- Charlie  | Marketing
-- Eve      | Engineering
-- (Diana excluded — her department_id is NULL)


-- ============================================================
-- LEFT JOIN (LEFT OUTER JOIN): ALL rows from left + matches from right
-- ============================================================
-- Returns ALL employees, even those without a department
SELECT e.name AS employee, d.name AS department
FROM employees e
LEFT JOIN departments d ON e.department_id = d.id;

-- Result:
-- employee | department
-- Alice    | Engineering
-- Bob      | Engineering
-- Charlie  | Marketing
-- Diana    | NULL          ← included with NULL department
-- Eve      | Engineering


-- ============================================================
-- RIGHT JOIN: ALL rows from right + matches from left
-- ============================================================
-- Returns ALL departments, even those with no employees
SELECT e.name AS employee, d.name AS department
FROM employees e
RIGHT JOIN departments d ON e.department_id = d.id;

-- Result:
-- employee | department
-- Alice    | Engineering
-- Bob      | Engineering
-- Eve      | Engineering
-- Charlie  | Marketing
-- NULL     | Sales         ← no employees in Sales
-- NULL     | HR            ← no employees in HR


-- ============================================================
-- FULL OUTER JOIN: ALL rows from BOTH tables
-- ============================================================
SELECT e.name AS employee, d.name AS department
FROM employees e
FULL OUTER JOIN departments d ON e.department_id = d.id;

-- Result:
-- employee | department
-- Alice    | Engineering
-- Bob      | Engineering
-- Eve      | Engineering
-- Charlie  | Marketing
-- Diana    | NULL          ← employee without department
-- NULL     | Sales         ← department without employees
-- NULL     | HR            ← department without employees


-- ============================================================
-- CROSS JOIN: Cartesian product (every combination)
-- ============================================================
SELECT e.name, d.name
FROM employees e
CROSS JOIN departments d;
-- 5 employees × 4 departments = 20 rows

-- Practical use: generate a report skeleton for all combinations
SELECT d.name AS department, p.name AS project
FROM departments d
CROSS JOIN projects p;


-- ============================================================
-- SELF JOIN: A table joined to itself
-- ============================================================
-- Find each employee and their manager's name
SELECT
    e.name  AS employee,
    m.name  AS manager
FROM employees e
LEFT JOIN employees m ON e.manager_id = m.id;

-- Result:
-- employee | manager
-- Alice    | NULL       ← no manager
-- Bob      | Alice
-- Charlie  | NULL
-- Diana    | Alice
-- Eve      | Alice


-- ============================================================
-- MULTI-TABLE JOIN: Chaining joins
-- ============================================================
-- Find which employees work on which projects, including department
SELECT
    e.name       AS employee,
    d.name       AS department,
    p.name       AS project,
    ep.role      AS role_in_project
FROM employees e
JOIN employee_projects ep ON e.id = ep.employee_id
JOIN projects p           ON ep.project_id = p.id
LEFT JOIN departments d   ON e.department_id = d.id
ORDER BY p.name, e.name;


-- ============================================================
-- ANTI-JOIN patterns: finding non-matching rows
-- ============================================================
-- Employees NOT assigned to any project
-- Method 1: LEFT JOIN + IS NULL
SELECT e.name
FROM employees e
LEFT JOIN employee_projects ep ON e.id = ep.employee_id
WHERE ep.employee_id IS NULL;

-- Method 2: NOT EXISTS (often preferred by optimizer)
SELECT e.name
FROM employees e
WHERE NOT EXISTS (
    SELECT 1 FROM employee_projects ep WHERE ep.employee_id = e.id
);

-- Method 3: NOT IN (beware of NULLs!)
SELECT e.name
FROM employees e
WHERE e.id NOT IN (
    SELECT employee_id FROM employee_projects
);


-- ============================================================
-- SEMI-JOIN: EXISTS pattern (return left rows that have a match)
-- ============================================================
-- Departments that have at least one employee
SELECT d.name
FROM departments d
WHERE EXISTS (
    SELECT 1 FROM employees e WHERE e.department_id = d.id
);
```

---

### WINDOW FUNCTIONS

Window functions perform calculations across a set of rows related to the current row, without collapsing them into a single output row (unlike GROUP BY).

```sql
-- ============================================================
-- BASIC SYNTAX
-- ============================================================
-- function_name(...) OVER (
--     [PARTITION BY column_list]
--     [ORDER BY column_list]
--     [frame_clause]
-- )

-- ============================================================
-- ROW_NUMBER, RANK, DENSE_RANK
-- ============================================================
SELECT
    name,
    department_id,
    salary,
    ROW_NUMBER() OVER (ORDER BY salary DESC)                        AS row_num,
    RANK()       OVER (ORDER BY salary DESC)                        AS rank,
    DENSE_RANK() OVER (ORDER BY salary DESC)                        AS dense_rank,
    ROW_NUMBER() OVER (PARTITION BY department_id ORDER BY salary DESC)
        AS dept_rank
FROM employees;

-- Result:
-- name    | dept_id | salary  | row_num | rank | dense_rank | dept_rank
-- Alice   | 1       | 150000  | 1       | 1    | 1          | 1
-- Eve     | 1       | 130000  | 2       | 2    | 2          | 2
-- Bob     | 1       | 120000  | 3       | 3    | 3          | 3
-- Charlie | 2       | 110000  | 4       | 4    | 4          | 1
-- Diana   | NULL    | 95000   | 5       | 5    | 5          | 1

-- RANK vs DENSE_RANK: If two people tied at rank 2,
--   RANK  would skip to 4 next
--   DENSE_RANK would go to 3 next


-- ============================================================
-- Practical: Top-N per group (a VERY common interview/production pattern)
-- ============================================================
-- Top 2 highest-paid employees per department
WITH ranked AS (
    SELECT
        name, department_id, salary,
        ROW_NUMBER() OVER (
            PARTITION BY department_id ORDER BY salary DESC
        ) AS rn
    FROM employees
    WHERE department_id IS NOT NULL
)
SELECT name, department_id, salary
FROM ranked
WHERE rn <= 2;


-- ============================================================
-- AGGREGATE WINDOW FUNCTIONS
-- ============================================================
SELECT
    name,
    department_id,
    salary,
    SUM(salary)   OVER ()                          AS company_total,
    SUM(salary)   OVER (PARTITION BY department_id) AS dept_total,
    AVG(salary)   OVER (PARTITION BY department_id) AS dept_avg,
    COUNT(*)      OVER (PARTITION BY department_id) AS dept_count,
    -- Percentage of department salary
    ROUND(salary / SUM(salary) OVER (PARTITION BY department_id) * 100, 1)
        AS pct_of_dept
FROM employees;


-- ============================================================
-- LAG and LEAD: access previous/next rows
-- ============================================================
-- Compare each employee's salary with the previous hire's salary
SELECT
    name,
    hired_at,
    salary,
    LAG(salary, 1)  OVER (ORDER BY hired_at) AS prev_hire_salary,
    LEAD(salary, 1) OVER (ORDER BY hired_at) AS next_hire_salary,
    salary - LAG(salary, 1) OVER (ORDER BY hired_at) AS salary_diff
FROM employees
ORDER BY hired_at;


-- ============================================================
-- RUNNING TOTALS and MOVING AVERAGES (Frame clauses)
-- ============================================================
-- Running total of salaries by hire date
SELECT
    name,
    hired_at,
    salary,
    SUM(salary) OVER (
        ORDER BY hired_at
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_total,

    -- 3-row moving average
    AVG(salary) OVER (
        ORDER BY hired_at
        ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING
    ) AS moving_avg_3,

    -- Cumulative max
    MAX(salary) OVER (
        ORDER BY hired_at
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_max
FROM employees
ORDER BY hired_at;

-- Frame clause options:
--   ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW  (default for ORDER BY)
--   ROWS BETWEEN 2 PRECEDING AND 2 FOLLOWING
--   ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING
--   RANGE BETWEEN ...  (value-based rather than row-based)


-- ============================================================
-- FIRST_VALUE, LAST_VALUE, NTH_VALUE
-- ============================================================
SELECT
    name,
    department_id,
    salary,
    FIRST_VALUE(name) OVER (
        PARTITION BY department_id ORDER BY salary DESC
    ) AS highest_paid_in_dept,
    LAST_VALUE(name) OVER (
        PARTITION BY department_id ORDER BY salary DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS lowest_paid_in_dept
FROM employees
WHERE department_id IS NOT NULL;


-- ============================================================
-- NTILE: divide rows into N buckets
-- ============================================================
SELECT
    name,
    salary,
    NTILE(4) OVER (ORDER BY salary DESC) AS salary_quartile
FROM employees;

-- Result:
-- Alice   | 150000 | 1  (top 25%)
-- Eve     | 130000 | 1
-- Bob     | 120000 | 2
-- Charlie | 110000 | 3
-- Diana   | 95000  | 4  (bottom 25%)


-- ============================================================
-- NAMED WINDOWS (PostgreSQL): reuse window definitions
-- ============================================================
SELECT
    name, department_id, salary,
    ROW_NUMBER() OVER w AS rn,
    SUM(salary)  OVER w AS running_sum,
    AVG(salary)  OVER w AS running_avg
FROM employees
WINDOW w AS (PARTITION BY department_id ORDER BY salary DESC)
ORDER BY department_id, salary DESC;
```

---

### COMMON TABLE EXPRESSIONS (CTEs)

```sql
-- ============================================================
-- BASIC CTE
-- ============================================================
WITH dept_stats AS (
    SELECT
        department_id,
        COUNT(*)       AS emp_count,
        AVG(salary)    AS avg_salary,
        MAX(salary)    AS max_salary
    FROM employees
    WHERE department_id IS NOT NULL
    GROUP BY department_id
)
SELECT
    d.name         AS department,
    ds.emp_count,
    ds.avg_salary,
    ds.max_salary
FROM dept_stats ds
JOIN departments d ON d.id = ds.department_id
WHERE ds.avg_salary > 100000;


-- ============================================================
-- MULTIPLE CTEs (chained)
-- ============================================================
WITH
high_earners AS (
    SELECT id, name, department_id, salary
    FROM employees
    WHERE salary > 115000
),
high_earner_depts AS (
    SELECT
        d.name   AS department,
        COUNT(*) AS high_earner_count,
        AVG(he.salary) AS avg_high_salary
    FROM high_earners he
    JOIN departments d ON he.department_id = d.id
    GROUP BY d.name
)
SELECT * FROM high_earner_depts;


-- ============================================================
-- RECURSIVE CTE: organizational hierarchy
-- ============================================================
-- Build the full management chain
WITH RECURSIVE org_tree AS (
    -- Base case: top-level managers (no manager)
    SELECT
        id,
        name,
        manager_id,
        1 AS level,
        ARRAY[name] AS path        -- PostgreSQL array for the path
    FROM employees
    WHERE manager_id IS NULL

    UNION ALL

    -- Recursive case: employees with managers
    SELECT
        e.id,
        e.name,
        e.manager_id,
        ot.level + 1,
        ot.path || e.name
    FROM employees e
    INNER JOIN org_tree ot ON e.manager_id = ot.id
)
SELECT
    REPEAT('  ', level - 1) || name AS org_chart,
    level,
    path
FROM org_tree
ORDER BY path;

-- Result:
-- org_chart       | level | path
-- Alice           | 1     | {Alice}
--   Bob           | 2     | {Alice,Bob}
--   Diana         | 2     | {Alice,Diana}
--   Eve           | 2     | {Alice,Eve}
-- Charlie         | 1     | {Charlie}


-- ============================================================
-- RECURSIVE CTE: generate a series (useful for gap-filling)
-- ============================================================
WITH RECURSIVE dates AS (
    SELECT DATE '2024-01-01' AS dt
    UNION ALL
    SELECT dt + INTERVAL '1 day'
    FROM dates
    WHERE dt < DATE '2024-01-31'
)
SELECT dt FROM dates;


-- ============================================================
-- CTE with INSERT (PostgreSQL: writable CTEs)
-- ============================================================
WITH new_dept AS (
    INSERT INTO departments (name) VALUES ('Data Science')
    RETURNING id, name
)
INSERT INTO employees (name, department_id, salary, hired_at)
SELECT 'Frank', nd.id, 140000, CURRENT_DATE
FROM new_dept nd;
```

---

### SUBQUERIES

```sql
-- ============================================================
-- SCALAR SUBQUERY: returns a single value
-- ============================================================
SELECT
    name,
    salary,
    salary - (SELECT AVG(salary) FROM employees) AS diff_from_avg
FROM employees;


-- ============================================================
-- SUBQUERY IN WHERE: filtering
-- ============================================================
-- Employees earning above their department's average
SELECT name, salary, department_id
FROM employees e
WHERE salary > (
    SELECT AVG(salary)
    FROM employees e2
    WHERE e2.department_id = e.department_id   -- correlated subquery
);


-- ============================================================
-- SUBQUERY IN FROM: derived table
-- ============================================================
SELECT dept_name, avg_salary
FROM (
    SELECT
        d.name    AS dept_name,
        AVG(e.salary) AS avg_salary
    FROM employees e
    JOIN departments d ON e.department_id = d.id
    GROUP BY d.name
) AS dept_averages
WHERE avg_salary > 100000;


-- ============================================================
-- EXISTS vs IN: semantic and performance differences
-- ============================================================
-- EXISTS: short-circuits as soon as a match is found
-- Better when the subquery result set is large
SELECT d.name
FROM departments d
WHERE EXISTS (
    SELECT 1 FROM employees e
    WHERE e.department_id = d.id AND e.salary > 100000
);

-- IN: materializes the full subquery result
-- Better when the subquery result set is small
SELECT name FROM employees
WHERE department_id IN (
    SELECT id FROM departments WHERE name LIKE '%Engineering%'
);

-- DANGER: NOT IN with NULLs
-- If the subquery returns ANY NULL, NOT IN returns no rows!
SELECT name FROM employees
WHERE department_id NOT IN (
    SELECT department_id FROM employees  -- if any NULL exists, returns EMPTY
    WHERE department_id IS NOT NULL      -- ← fix: filter NULLs
);


-- ============================================================
-- LATERAL JOIN (PostgreSQL): correlated subquery in FROM
-- ============================================================
-- Top 2 highest-paid employees per department
SELECT d.name AS department, top_emp.*
FROM departments d
CROSS JOIN LATERAL (
    SELECT e.name, e.salary
    FROM employees e
    WHERE e.department_id = d.id
    ORDER BY e.salary DESC
    LIMIT 2
) AS top_emp;
```

---

### INDEXING STRATEGIES

```sql
-- ============================================================
-- B-TREE INDEX (default): equality and range queries
-- ============================================================
CREATE INDEX idx_employees_salary ON employees(salary);

-- Useful for: =, <, >, <=, >=, BETWEEN, IN, ORDER BY, MIN/MAX
-- Example queries that benefit:
SELECT * FROM employees WHERE salary > 100000;
SELECT * FROM employees WHERE salary BETWEEN 80000 AND 120000;
SELECT * FROM employees ORDER BY salary DESC LIMIT 10;


-- ============================================================
-- COMPOSITE (MULTI-COLUMN) INDEX
-- ============================================================
-- Column order matters! Left-to-right prefix rule.
CREATE INDEX idx_emp_dept_salary ON employees(department_id, salary);

-- ✅ Uses the index (leading column present):
SELECT * FROM employees WHERE department_id = 1;
SELECT * FROM employees WHERE department_id = 1 AND salary > 100000;
SELECT * FROM employees WHERE department_id = 1 ORDER BY salary;

-- ❌ Cannot use this index efficiently:
SELECT * FROM employees WHERE salary > 100000;  -- skips leading column


-- ============================================================
-- COVERING INDEX (INCLUDE in PostgreSQL)
-- ============================================================
-- Index contains ALL columns needed → index-only scan, no table lookup
CREATE INDEX idx_emp_covering
ON employees(department_id)
INCLUDE (name, salary);

-- This query is satisfied entirely from the index:
SELECT name, salary FROM employees WHERE department_id = 1;


-- ============================================================
-- PARTIAL INDEX: index a subset of rows
-- ============================================================
CREATE INDEX idx_active_high_earners
ON employees(salary)
WHERE salary > 100000;

-- Small index, fast lookups for: WHERE salary > 100000


-- ============================================================
-- EXPRESSION / FUNCTIONAL INDEX
-- ============================================================
CREATE INDEX idx_emp_name_lower ON employees(LOWER(name));

-- Now this uses the index:
SELECT * FROM employees WHERE LOWER(name) = 'alice';


-- ============================================================
-- HASH INDEX (PostgreSQL): only equality, no range
-- ============================================================
CREATE INDEX idx_emp_name_hash ON employees USING hash(name);
-- Faster than B-tree for pure equality lookups, but:
-- ❌ No range queries, no sorting, no partial matching


-- ============================================================
-- GIN INDEX: for arrays, JSONB, full-text search
-- ============================================================
-- For JSONB columns
ALTER TABLE employees ADD COLUMN metadata JSONB;
CREATE INDEX idx_emp_metadata ON employees USING gin(metadata);

-- For full-text search
CREATE INDEX idx_emp_search ON employees USING gin(to_tsvector('english', name));


-- ============================================================
-- GiST INDEX: geometric data, range types, full-text
-- ============================================================
-- For range queries on range types
-- CREATE INDEX idx_schedule ON events USING gist(time_range);


-- ============================================================
-- UNIQUE INDEX
-- ============================================================
CREATE UNIQUE INDEX idx_emp_email ON employees(email);
-- Enforces uniqueness AND provides fast lookups


-- ============================================================
-- WHEN TO INDEX / WHEN NOT TO INDEX
-- ============================================================
/*
✅ INDEX WHEN:
  - Column appears frequently in WHERE, JOIN ON, ORDER BY
  - High cardinality (many distinct values)
  - Table is large and queries return small portion of rows
  - Foreign key columns (critical for join performance)

❌ DON'T INDEX WHEN:
  - Table is small (full scan is faster)
  - Column has low cardinality (boolean, status with 2-3 values)
    Exception: partial index on the rare value
  - Column is frequently updated (index maintenance cost)
  - You already have too many indexes (slows writes)
*/
```

---

### QUERY EXECUTION PLAN

```sql
-- ============================================================
-- EXPLAIN: shows the planned execution
-- ============================================================
EXPLAIN
SELECT e.name, d.name
FROM employees e
JOIN departments d ON e.department_id = d.id
WHERE e.salary > 100000;

-- ============================================================
-- EXPLAIN ANALYZE: actually executes and shows real timings
-- ============================================================
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT e.name, d.name
FROM employees e
JOIN departments d ON e.department_id = d.id
WHERE e.salary > 100000;

-- Sample output:
/*
Hash Join  (cost=1.09..2.25 rows=3 width=236)
           (actual time=0.035..0.041 rows=3 loops=1)
  Hash Cond: (e.department_id = d.id)
  Buffers: shared hit=3
  ->  Seq Scan on employees e  (cost=0.00..1.06 rows=3 width=122)
                               (actual time=0.009..0.012 rows=3 loops=1)
        Filter: (salary > 100000)
        Rows Removed by Filter: 2
        Buffers: shared hit=1
  ->  Hash  (cost=1.04..1.04 rows=4 width=118)
            (actual time=0.008..0.009 rows=4 loops=1)
        Buckets: 1024  Batches: 1
        ->  Seq Scan on departments d  (cost=0.00..1.04 rows=4 width=118)
                                       (actual time=0.003..0.004 rows=4 loops=1)
              Buffers: shared hit=1
Planning Time: 0.150 ms
Execution Time: 0.065 ms
*/
```

```
Key scan types to understand:

┌─────────────────────┬────────────────────────────────────────────┐
│ Scan Type           │ Meaning                                    │
├─────────────────────┼────────────────────────────────────────────┤
│ Seq Scan            │ Full table scan, row by row                │
│ Index Scan          │ Traverse index → fetch rows from table     │
│ Index Only Scan     │ All data from index, no table access       │
│ Bitmap Index Scan   │ Build bitmap from index → fetch in bulk    │
│ Bitmap Heap Scan    │ Fetch rows using bitmap                    │
├─────────────────────┼────────────────────────────────────────────┤
│ Nested Loop         │ For each outer row, scan inner             │
│ Hash Join           │ Build hash of smaller table, probe with    │
│                     │ larger table                               │
│ Merge Join          │ Both inputs sorted, merge them             │
├─────────────────────┼────────────────────────────────────────────┤
│ Sort                │ Sort operation (may spill to disk)         │
│ HashAggregate       │ GROUP BY using hash table                  │
│ GroupAggregate      │ GROUP BY using sorted input                │
└─────────────────────┴────────────────────────────────────────────┘
```

```sql
-- ============================================================
-- READING THE PLAN: key metrics
-- ============================================================
/*
cost=STARTUP..TOTAL
  - Startup: cost before first row can be returned
  - Total: cost to return all rows
  - Units are arbitrary but comparable within a query

rows=N
  - Estimated number of rows (EXPLAIN)
  - Actual rows (EXPLAIN ANALYZE)

width=N
  - Estimated average row size in bytes

Buffers:
  - shared hit: pages found in cache
  - shared read: pages read from disk
  - If read >> hit, you may need more memory or better indexes

IMPORTANT: actual rows vs estimated rows discrepancy
  - If the planner estimates 10 rows but actual is 100,000,
    statistics are stale → run ANALYZE
*/

-- Force stats refresh
ANALYZE employees;
```

---

## 2. DATABASE INTERNALS

---

### B-TREE INDEXES

```
B-Tree Structure (conceptual):

                    ┌──────────────────┐
                    │   [30] [60] [90] │            ← Root node
                    └──┬────┬────┬────┬┘
                       │    │    │    │
          ┌────────────┘    │    │    └────────────┐
          ▼                 ▼    ▼                 ▼
    ┌──────────┐    ┌──────────┐ ┌──────────┐  ┌──────────┐
    │ [10][20] │    │ [40][50] │ │ [70][80] │  │[100][110]│  ← Internal
    └──┬──┬──┬─┘    └──┬──┬──┬─┘ └──┬──┬──┬─┘  └──┬──┬──┬─┘
       │  │  │         │  │  │      │  │  │       │  │  │
       ▼  ▼  ▼         ▼  ▼  ▼     ▼  ▼  ▼      ▼  ▼  ▼
    Leaf nodes with actual data pointers + linked list
    [5,8,10] ↔ [15,18,20] ↔ [25,28,30] ↔ [35,38,40] ↔ ...

Properties:
  • Balanced: all leaves at same depth → O(log N) lookups
  • Ordered: leaf nodes form a doubly-linked list → efficient range scans
  • Each node = one disk page (typically 8KB in PostgreSQL)
  • Fan-out: hundreds of keys per node → very shallow trees
    Example: 100 keys/node → 100^3 = 1 million rows in 3 levels

Operations:
  • Point lookup:  O(log N) — traverse root to leaf
  • Range scan:    O(log N + K) — find start, follow leaf links
  • Insert:        O(log N) — may cause page splits
  • Delete:        O(log N) — may cause page merges
```

```sql
-- Observing index usage in PostgreSQL
-- Check index size
SELECT
    indexrelname          AS index_name,
    pg_size_pretty(pg_relation_size(indexrelid)) AS index_size,
    idx_scan              AS times_used,
    idx_tup_read          AS tuples_read,
    idx_tup_fetch         AS tuples_fetched
FROM pg_stat_user_indexes
WHERE schemaname = 'public'
ORDER BY pg_relation_size(indexrelid) DESC;

-- Check table bloat and dead tuples
SELECT
    relname,
    n_live_tup,
    n_dead_tup,
    last_vacuum,
    last_autovacuum,
    last_analyze
FROM pg_stat_user_tables;
```

---

### QUERY OPTIMIZER

```
How the PostgreSQL Query Optimizer Works:

SQL Query
    │
    ▼
┌──────────┐
│  Parser  │ → Syntax validation → Parse tree
└────┬─────┘
     ▼
┌───────────┐
│ Rewriter  │ → View expansion, rule application
└────┬──────┘
     ▼
┌───────────────┐
│   Planner /   │ → Generates execution plan
│   Optimizer   │
└────┬──────────┘
     │
     │  Considers:
     │  1. Which indexes to use (or seq scan)
     │  2. Join order (N! permutations for N tables)
     │  3. Join algorithm (nested loop, hash, merge)
     │  4. Aggregation strategy
     │  5. Sort method
     │
     │  Uses:
     │  - Table statistics (pg_stats)
     │  - Row count estimates
     │  - Column value distribution (histograms)
     │  - Correlation (physical vs logical order)
     │  - Cost model (seq_page_cost, random_page_cost, cpu_tuple_cost...)
     │
     ▼
┌──────────┐
│ Executor │ → Runs the chosen plan
└──────────┘
```

```sql
-- ============================================================
-- VIEWING STATISTICS THE OPTIMIZER USES
-- ============================================================
SELECT
    attname,
    n_distinct,
    most_common_vals,
    most_common_freqs,
    correlation       -- 1.0 = perfectly correlated with physical order
FROM pg_stats
WHERE tablename = 'employees';


-- ============================================================
-- INFLUENCING THE OPTIMIZER
-- ============================================================
-- Update statistics (critical after bulk loads)
ANALYZE employees;

-- Adjust statistics target for a column (more histogram buckets)
ALTER TABLE employees ALTER COLUMN salary SET STATISTICS 1000;
ANALYZE employees;

-- Cost parameters (session level)
SET random_page_cost = 1.1;  -- Lower for SSDs (default 4.0)
SET seq_page_cost = 1.0;     -- Sequential I/O cost
SET effective_cache_size = '4GB';  -- How much memory available for caching

-- Force/prevent specific plan choices (debugging only!)
SET enable_seqscan = off;     -- Force index usage
SET enable_hashjoin = off;    -- Prevent hash joins
SET enable_nestloop = off;    -- Prevent nested loops


-- ============================================================
-- COMMON OPTIMIZER PITFALLS
-- ============================================================
-- 1. Stale statistics → run ANALYZE
-- 2. Function calls in WHERE prevent index use
--    BAD:  WHERE YEAR(created_at) = 2024
--    GOOD: WHERE created_at >= '2024-01-01' AND created_at < '2025-01-01'

-- 3. Implicit type casting
--    BAD:  WHERE varchar_col = 123  (casts every row)
--    GOOD: WHERE varchar_col = '123'

-- 4. OR conditions can prevent index use
--    BAD:  WHERE dept_id = 1 OR salary > 100000
--    GOOD: Use UNION ALL of two indexed queries
```

---

### LOCKING

```sql
-- ============================================================
-- LOCK TYPES IN POSTGRESQL (from least to most restrictive)
-- ============================================================
/*
┌──────────────────────────┬────────────────────────────────────┐
│ Lock Mode                │ Acquired By                        │
├──────────────────────────┼────────────────────────────────────┤
│ ACCESS SHARE             │ SELECT                             │
│ ROW SHARE                │ SELECT FOR UPDATE/SHARE            │
│ ROW EXCLUSIVE            │ INSERT, UPDATE, DELETE             │
│ SHARE UPDATE EXCLUSIVE   │ VACUUM, ANALYZE, CREATE INDEX      │
│                          │ CONCURRENTLY                       │
│ SHARE                    │ CREATE INDEX (not concurrently)    │
│ SHARE ROW EXCLUSIVE      │ Certain ALTER TABLE variants       │
│ EXCLUSIVE                │ Rare internal use                  │
│ ACCESS EXCLUSIVE         │ ALTER TABLE, DROP TABLE, VACUUM    │
│                          │ FULL, LOCK TABLE                   │
└──────────────────────────┴────────────────────────────────────┘

Conflict Matrix (simplified):
                        ACCESS  ROW    ROW     SHARE    SHARE   ACCESS
                        SHARE   SHARE  EXCL    ...      ...     EXCL
ACCESS SHARE              ✓       ✓      ✓       ✓       ✓       ✗
ROW EXCLUSIVE             ✓       ✓      ✓       ✗       ✗       ✗
ACCESS EXCLUSIVE          ✗       ✗      ✗       ✗       ✗       ✗

Key insight: Readers don't block readers. Readers don't block writers.
             Writers don't block readers. Only writers block writers
             (at the row level with MVCC).
*/

-- ============================================================
-- ROW-LEVEL LOCKING
-- ============================================================
BEGIN;
-- Lock specific rows for update (prevents concurrent modification)
SELECT * FROM employees WHERE id = 1 FOR UPDATE;
-- Other transactions trying to UPDATE/DELETE row id=1 will WAIT

-- FOR UPDATE SKIP LOCKED: skip already-locked rows (job queue pattern)
SELECT * FROM task_queue
WHERE status = 'pending'
ORDER BY created_at
LIMIT 1
FOR UPDATE SKIP LOCKED;

-- FOR UPDATE NOWAIT: error immediately if locked
SELECT * FROM employees WHERE id = 1 FOR UPDATE NOWAIT;
COMMIT;


-- ============================================================
-- EXPLICIT TABLE LOCKING
-- ============================================================
BEGIN;
LOCK TABLE employees IN SHARE MODE;
-- Allows concurrent reads but blocks writes
-- Useful for consistent reports across multiple queries
COMMIT;


-- ============================================================
-- ADVISORY LOCKS (application-level locking)
-- ============================================================
-- Useful for distributed coordination without touching actual rows

-- Session-level lock
SELECT pg_advisory_lock(12345);      -- Acquire
-- ... do work ...
SELECT pg_advisory_unlock(12345);    -- Release

-- Transaction-level lock (auto-released on commit/rollback)
SELECT pg_advisory_xact_lock(12345);

-- Non-blocking attempt
SELECT pg_try_advisory_lock(12345);  -- Returns true/false


-- ============================================================
-- MONITORING LOCKS
-- ============================================================
SELECT
    l.locktype,
    l.relation::regclass,
    l.mode,
    l.granted,
    l.pid,
    a.usename,
    a.query,
    a.state,
    age(now(), a.query_start) AS duration
FROM pg_locks l
JOIN pg_stat_activity a ON l.pid = a.pid
WHERE l.relation IS NOT NULL
ORDER BY a.query_start;
```

---

### ISOLATION LEVELS

```sql
-- ============================================================
-- THE FOUR ISOLATION LEVELS
-- ============================================================
/*
┌───────────────────┬──────────┬────────────────┬────────────────┬─────────────┐
│ Isolation Level   │ Dirty    │ Non-Repeatable │ Phantom        │ Serializ.   │
│                   │ Read     │ Read           │ Read           │ Anomaly     │
├───────────────────┼──────────┼────────────────┼────────────────┼─────────────┤
│ READ UNCOMMITTED  │ Possible │ Possible       │ Possible       │ Possible    │
│ READ COMMITTED    │ ✗        │ Possible       │ Possible       │ Possible    │
│ REPEATABLE READ   │ ✗        │ ✗              │ Possible*      │ Possible    │
│ SERIALIZABLE      │ ✗        │ ✗              │ ✗              │ ✗           │
└───────────────────┴──────────┴────────────────┴────────────────┴─────────────┘
* PostgreSQL's REPEATABLE READ actually prevents phantoms too (uses snapshot)
  In MySQL InnoDB, REPEATABLE READ uses gap locks to prevent some phantoms.

PostgreSQL default: READ COMMITTED
MySQL InnoDB default: REPEATABLE READ
*/

-- ============================================================
-- READ COMMITTED (PostgreSQL default)
-- ============================================================
/*
Each statement sees the latest committed data at the moment the
statement begins. Different statements within the same transaction
may see different data.

Transaction A:                    Transaction B:
BEGIN;
SELECT salary FROM employees
WHERE id = 1;  → 100000
                                  BEGIN;
                                  UPDATE employees SET salary = 120000
                                  WHERE id = 1;
                                  COMMIT;
SELECT salary FROM employees
WHERE id = 1;  → 120000          ← Non-repeatable read!
COMMIT;
*/

SET TRANSACTION ISOLATION LEVEL READ COMMITTED;


-- ============================================================
-- REPEATABLE READ
-- ============================================================
/*
The transaction sees a snapshot of the database as of the transaction
start. All reads within the transaction see the same data.

Transaction A:                    Transaction B:
BEGIN;
SET TRANSACTION ISOLATION
LEVEL REPEATABLE READ;
SELECT salary FROM employees
WHERE id = 1;  → 100000
                                  BEGIN;
                                  UPDATE employees SET salary = 120000
                                  WHERE id = 1;
                                  COMMIT;
SELECT salary FROM employees
WHERE id = 1;  → 100000          ← Same as before! Snapshot.

-- But if A tries to UPDATE the same row:
UPDATE employees SET salary = salary + 5000
WHERE id = 1;
-- PostgreSQL: ERROR "could not serialize access"
-- (detects write conflict)
COMMIT;
*/

BEGIN;
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
-- All queries here see the same snapshot
COMMIT;


-- ============================================================
-- SERIALIZABLE
-- ============================================================
/*
Strictest level. Transactions behave AS IF they were executed
one at a time (serially). PostgreSQL uses SSI (Serializable
Snapshot Isolation) to detect serialization anomalies.

Classic example — write skew:

Table: doctors(name, on_call)
Constraint: at least 1 doctor must be on call

Transaction A:                    Transaction B:
BEGIN SERIALIZABLE;               BEGIN SERIALIZABLE;
SELECT COUNT(*) FROM doctors
WHERE on_call = true; → 2
                                  SELECT COUNT(*) FROM doctors
                                  WHERE on_call = true; → 2
UPDATE doctors SET on_call = false
WHERE name = 'Alice';
                                  UPDATE doctors SET on_call = false
                                  WHERE name = 'Bob';
COMMIT; ← succeeds
                                  COMMIT; ← ERROR: serialization failure
                                  -- Prevents: 0 doctors on call
*/

BEGIN;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
-- May throw serialization errors → application must retry
COMMIT;
```

---

### MVCC (Multi-Version Concurrency Control)

```
How MVCC Works in PostgreSQL:

┌─────────────────────────────────────────────────────────────────┐
│ Core Principle: Writers don't block readers.                    │
│                 Readers don't block writers.                    │
│                                                                 │
│ Instead of locks, each row has multiple versions.               │
│ Each transaction sees a consistent snapshot.                    │
└─────────────────────────────────────────────────────────────────┘

Row Structure in PostgreSQL:
┌──────┬──────┬────────┬────────┬──────────────────────┐
│ xmin │ xmax │ ctid   │ ...    │ actual data columns  │
├──────┼──────┼────────┼────────┼──────────────────────┤
│ 100  │ 0    │ (0,1)  │        │ 'Alice', 150000      │  ← Current version
│ 100  │ 105  │ (0,1)  │        │ 'Alice', 150000      │  ← Old (deleted by tx 105)
│ 105  │ 0    │ (0,3)  │        │ 'Alice', 160000      │  ← New version by tx 105
└──────┴──────┴────────┴────────┴──────────────────────┘

xmin: transaction ID that created this row version
xmax: transaction ID that deleted/updated it (0 = still alive)
ctid: physical location (page, offset)

Visibility Rules:
A row version is visible to transaction T if:
  1. xmin is committed AND xmin < T's snapshot
  2. xmax is not set (0) OR xmax is not committed OR xmax > T's snapshot
```

```sql
-- ============================================================
-- OBSERVING MVCC IN ACTION
-- ============================================================

-- See hidden system columns
SELECT xmin, xmax, ctid, * FROM employees WHERE id = 1;
-- xmin=100, xmax=0, ctid=(0,1), id=1, name='Alice', salary=150000

-- After an UPDATE:
BEGIN;
UPDATE employees SET salary = 160000 WHERE id = 1;
SELECT xmin, xmax, ctid, * FROM employees WHERE id = 1;
-- xmin=200 (new tx), xmax=0, ctid=(0,6) ← NEW physical location
-- The old version at (0,1) now has xmax=200
COMMIT;


-- ============================================================
-- VACUUM: cleaning up dead row versions
-- ============================================================
/*
Problem: Updates and deletes create dead tuples (old versions).
         These waste space and slow down scans.

VACUUM:
  - Marks dead tuple space as reusable
  - Does NOT return space to OS
  - Does NOT lock the table (can run concurrently)
  - Updates visibility map and free space map

VACUUM FULL:
  - Rewrites entire table compacted
  - DOES return space to OS
  - Requires ACCESS EXCLUSIVE lock (blocks everything)
  - Use sparingly!

AUTOVACUUM:
  - Background process that runs VACUUM automatically
  - Triggered when dead_tuples > threshold
  - Threshold = autovacuum_vacuum_threshold +
                autovacuum_vacuum_scale_factor × n_live_tup
  - Default: 50 + 0.2 × n_live_tup
*/

-- Manual vacuum
VACUUM employees;
VACUUM (VERBOSE) employees;       -- With stats output
VACUUM FULL employees;             -- Compact (locking!)
VACUUM (ANALYZE) employees;        -- Vacuum + update statistics

-- Check autovacuum status
SELECT
    relname,
    n_live_tup,
    n_dead_tup,
    ROUND(n_dead_tup::numeric / GREATEST(n_live_tup, 1) * 100, 2) AS dead_pct,
    last_autovacuum,
    autovacuum_count
FROM pg_stat_user_tables
ORDER BY n_dead_tup DESC;


-- ============================================================
-- MVCC IN MYSQL INNODB
-- ============================================================
/*
InnoDB uses a different approach:
- Stores current version in the main table
- Old versions stored in the UNDO LOG (rollback segment)
- Each row has a hidden 6-byte transaction ID and 7-byte roll pointer
- Roll pointer chains to previous versions in undo log
- Purge thread cleans up old undo log entries

Key difference: PostgreSQL keeps old versions in-place (needs VACUUM)
                InnoDB keeps them in undo log (needs purge)
*/
```

---

## 3. PERFORMANCE

---

### SLOW QUERY OPTIMIZATION

```sql
-- ============================================================
-- STEP 1: IDENTIFY SLOW QUERIES
-- ============================================================

-- PostgreSQL: enable pg_stat_statements extension
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- Find top queries by total time
SELECT
    query,
    calls,
    ROUND(total_exec_time::numeric, 2)         AS total_ms,
    ROUND(mean_exec_time::numeric, 2)           AS avg_ms,
    ROUND(stddev_exec_time::numeric, 2)         AS stddev_ms,
    rows,
    ROUND((shared_blks_hit::numeric /
           NULLIF(shared_blks_hit + shared_blks_read, 0)) * 100, 2)
        AS cache_hit_pct
FROM pg_stat_statements
ORDER BY total_exec_time DESC
LIMIT 20;

-- Enable slow query log
-- postgresql.conf:
--   log_min_duration_statement = 1000  -- log queries > 1 second

-- MySQL:
-- SET GLOBAL slow_query_log = 'ON';
-- SET GLOBAL long_query_time = 1;


-- ============================================================
-- STEP 2: ANALYZE THE QUERY PLAN
-- ============================================================
EXPLAIN (ANALYZE, BUFFERS, TIMING)
SELECT e.name, d.name, COUNT(ep.project_id)
FROM employees e
JOIN departments d ON e.department_id = d.id
LEFT JOIN employee_projects ep ON e.id = ep.employee_id
WHERE e.salary > 50000
GROUP BY e.name, d.name
ORDER BY COUNT(ep.project_id) DESC;

-- Look for:
-- 1. Seq Scans on large tables (should be index scans)
-- 2. Large gap between estimated and actual rows
-- 3. Sort operations with "Sort Method: external merge" (spilling to disk)
-- 4. Nested Loops with high loop counts
-- 5. High shared_blks_read (cache misses)


-- ============================================================
-- STEP 3: COMMON OPTIMIZATIONS
-- ============================================================

-- OPTIMIZATION 1: Add missing indexes
-- Before: Seq Scan on employees (filter salary > 50000)
CREATE INDEX idx_emp_salary ON employees(salary);
-- After: Index Scan using idx_emp_salary

-- OPTIMIZATION 2: Rewrite correlated subqueries as JOINs
-- SLOW:
SELECT name, (
    SELECT COUNT(*) FROM employee_projects ep
    WHERE ep.employee_id = e.id
) AS project_count
FROM employees e;

-- FAST:
SELECT e.name, COUNT(ep.project_id) AS project_count
FROM employees e
LEFT JOIN employee_projects ep ON e.id = ep.employee_id
GROUP BY e.name;

-- OPTIMIZATION 3: Avoid SELECT *
-- BAD:  SELECT * FROM employees WHERE ...
-- GOOD: SELECT name, salary FROM employees WHERE ...
-- Enables index-only scans, reduces I/O

-- OPTIMIZATION 4: Pagination with keyset instead of OFFSET
-- SLOW (large offsets scan and discard rows):
SELECT * FROM employees ORDER BY id LIMIT 20 OFFSET 100000;

-- FAST (keyset pagination):
SELECT * FROM employees WHERE id > 100000 ORDER BY id LIMIT 20;

-- OPTIMIZATION 5: Batch operations
-- SLOW: 10,000 individual INSERTs
-- FAST:
INSERT INTO employees (name, salary)
VALUES ('A', 100), ('B', 200), ('C', 300), ...;  -- batch

-- OPTIMIZATION 6: Materialized views for expensive aggregations
CREATE MATERIALIZED VIEW dept_salary_stats AS
SELECT
    department_id,
    COUNT(*) AS emp_count,
    AVG(salary) AS avg_salary,
    MAX(salary) AS max_salary
FROM employees
GROUP BY department_id;

CREATE UNIQUE INDEX ON dept_salary_stats(department_id);

-- Refresh periodically
REFRESH MATERIALIZED VIEW CONCURRENTLY dept_salary_stats;
```

---

### INDEX DESIGN

```
Index Design Decision Framework:

┌─────────────────────────────────────────────────────────────┐
│                    QUERY ANALYSIS                           │
│                                                             │
│  For each important query, identify:                        │
│  1. WHERE clause columns (equality first, then range)       │
│  2. JOIN columns                                            │
│  3. ORDER BY / GROUP BY columns                             │
│  4. SELECT columns (for covering index)                     │
└─────────────────────────┬───────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│              COMPOSITE INDEX ORDERING RULE                  │
│                                                             │
│  1. Equality columns first (in any order)                   │
│  2. Sort/group columns next (matching query order)          │
│  3. Range columns last                                      │
│                                                             │
│  Example query:                                             │
│  WHERE status = 'active'        ← equality                  │
│    AND department_id = 5        ← equality                  │
│    AND salary > 100000          ← range                     │
│  ORDER BY hired_at              ← sort                      │
│                                                             │
│  Optimal index:                                             │
│  (status, department_id, hired_at, salary)                  │
│   eq        eq            sort      range                   │
│                                                             │
│  ❌ (status, salary, department_id, hired_at)               │
│     Range column (salary) stops further index navigation    │
└─────────────────────────────────────────────────────────────┘
```

```sql
-- ============================================================
-- INDEX DESIGN EXAMPLES
-- ============================================================

-- Query 1: Filter by status, sort by date, range on salary
-- WHERE status = 'active' AND salary > 80000 ORDER BY hired_at DESC
CREATE INDEX idx_q1 ON employees(status, hired_at DESC, salary);
-- Note: salary as range goes AFTER sort column

-- Query 2: Join + filter
-- FROM orders o JOIN users u ON u.id = o.user_id WHERE u.country = 'US'
CREATE INDEX idx_users_country ON users(country);     -- filter
-- orders.user_id should already have FK index

-- Query 3: Covering index for a dashboard query
-- SELECT name, salary FROM employees WHERE department_id = 3
CREATE INDEX idx_dept_covering ON employees(department_id) INCLUDE (name, salary);

-- Query 4: Partial index for a status flag
-- 99% of orders are 'completed', we only query 'pending'
CREATE INDEX idx_pending_orders ON orders(created_at)
WHERE status = 'pending';
-- Tiny index, extremely fast for the queries that matter


-- ============================================================
-- INDEX MAINTENANCE
-- ============================================================

-- Identify unused indexes (waste of write performance)
SELECT
    schemaname || '.' || relname AS table,
    indexrelname AS index,
    pg_size_pretty(pg_relation_size(i.indexrelid)) AS index_size,
    idx_scan AS times_used
FROM pg_stat_user_indexes i
JOIN pg_index USING (indexrelid)
WHERE idx_scan = 0
  AND NOT indisunique        -- don't drop unique constraints
  AND NOT indisprimary       -- don't drop PKs
ORDER BY pg_relation_size(i.indexrelid) DESC;

-- Identify duplicate indexes
SELECT
    array_agg(indexrelid::regclass) AS indexes,
    indrelid::regclass AS table,
    indkey AS column_positions
FROM pg_index
GROUP BY indrelid, indkey
HAVING COUNT(*) > 1;

-- Rebuild bloated indexes
REINDEX INDEX CONCURRENTLY idx_employees_salary;
```

---

### PARTITIONING

```sql
-- ============================================================
-- WHY PARTITION?
-- ============================================================
/*
Benefits:
  - Query performance: scan only relevant partitions (partition pruning)
  - Maintenance: VACUUM, REINDEX individual partitions
  - Data lifecycle: DROP old partitions instead of DELETE (instant, no bloat)
  - Parallelism: parallel scans across partitions

When to partition:
  - Table > 10-100 GB
  - Clear partition key in most queries (date, tenant_id)
  - Need to efficiently purge old data
*/


-- ============================================================
-- RANGE PARTITIONING (most common — by date)
-- ============================================================
CREATE TABLE events (
    id          BIGSERIAL,
    event_type  VARCHAR(50),
    payload     JSONB,
    created_at  TIMESTAMPTZ NOT NULL,
    PRIMARY KEY (id, created_at)    -- partition key must be in PK
) PARTITION BY RANGE (created_at);

-- Create partitions
CREATE TABLE events_2024_q1 PARTITION OF events
    FOR VALUES FROM ('2024-01-01') TO ('2024-04-01');
CREATE TABLE events_2024_q2 PARTITION OF events
    FOR VALUES FROM ('2024-04-01') TO ('2024-07-01');
CREATE TABLE events_2024_q3 PARTITION OF events
    FOR VALUES FROM ('2024-07-01') TO ('2024-10-01');
CREATE TABLE events_2024_q4 PARTITION OF events
    FOR VALUES FROM ('2024-10-01') TO ('2025-01-01');

-- Default partition (catches rows that don't match any partition)
CREATE TABLE events_default PARTITION OF events DEFAULT;

-- Indexes are created per partition
CREATE INDEX ON events(event_type, created_at);
-- This creates an index on EACH partition automatically

-- Query with partition pruning:
EXPLAIN SELECT * FROM events
WHERE created_at >= '2024-04-01' AND created_at < '2024-07-01';
-- Only scans events_2024_q2!

-- Drop old data instantly:
DROP TABLE events_2024_q1;
-- vs DELETE: would scan millions of rows, create dead tuples, need VACUUM


-- ============================================================
-- LIST PARTITIONING (by category/tenant)
-- ============================================================
CREATE TABLE orders (
    id       BIGSERIAL,
    region   VARCHAR(20) NOT NULL,
    amount   DECIMAL(10,2),
    PRIMARY KEY (id, region)
) PARTITION BY LIST (region);

CREATE TABLE orders_us PARTITION OF orders FOR VALUES IN ('US');
CREATE TABLE orders_eu PARTITION OF orders FOR VALUES IN ('EU', 'UK');
CREATE TABLE orders_asia PARTITION OF orders FOR VALUES IN ('JP', 'KR', 'IN');


-- ============================================================
-- HASH PARTITIONING (even distribution)
-- ============================================================
CREATE TABLE sessions (
    id       UUID PRIMARY KEY,
    user_id  BIGINT NOT NULL,
    data     JSONB
) PARTITION BY HASH (id);

CREATE TABLE sessions_p0 PARTITION OF sessions FOR VALUES WITH (MODULUS 4, REMAINDER 0);
CREATE TABLE sessions_p1 PARTITION OF sessions FOR VALUES WITH (MODULUS 4, REMAINDER 1);
CREATE TABLE sessions_p2 PARTITION OF sessions FOR VALUES WITH (MODULUS 4, REMAINDER 2);
CREATE TABLE sessions_p3 PARTITION OF sessions FOR VALUES WITH (MODULUS 4, REMAINDER 3);


-- ============================================================
-- SUB-PARTITIONING (multi-level)
-- ============================================================
CREATE TABLE logs (
    id          BIGSERIAL,
    tenant_id   INT NOT NULL,
    created_at  DATE NOT NULL,
    message     TEXT,
    PRIMARY KEY (id, tenant_id, created_at)
) PARTITION BY LIST (tenant_id);

CREATE TABLE logs_tenant_1 PARTITION OF logs
    FOR VALUES IN (1)
    PARTITION BY RANGE (created_at);

CREATE TABLE logs_tenant_1_2024_q1 PARTITION OF logs_tenant_1
    FOR VALUES FROM ('2024-01-01') TO ('2024-04-01');
```

---

### SHARDING

```
Sharding = Horizontal partitioning ACROSS multiple database servers

┌─────────┐      ┌──────────────────────────────────────────┐
│  App     │      │            Shard Router                  │
│  Server  │─────▶│  (Application logic / proxy like        │
│          │      │   Vitess, Citus, ProxySQL)               │
└─────────┘      └────────┬──────────┬──────────┬───────────┘
                          │          │          │
                    ┌─────▼──┐ ┌─────▼──┐ ┌────▼───┐
                    │Shard 0 │ │Shard 1 │ │Shard 2 │
                    │users   │ │users   │ │users   │
                    │id 1-   │ │id      │ │id      │
                    │ 999999 │ │1M-1.9M │ │2M-2.9M │
                    └────────┘ └────────┘ └────────┘

Sharding Strategies:

1. RANGE-BASED:
   shard = user_id / 1_000_000
   Pro: Simple, range queries on shard key
   Con: Hotspots (newest shard gets all writes)

2. HASH-BASED:
   shard = hash(user_id) % num_shards
   Pro: Even distribution
   Con: Range queries need all shards, resharding is painful

3. DIRECTORY-BASED:
   Lookup table: user_id → shard_id
   Pro: Flexible, can move individual users
   Con: Lookup table is a single point of failure

4. GEO-BASED:
   shard = region(user)
   Pro: Data locality, compliance (GDPR)
   Con: Uneven distribution
```

```python
# ============================================================
# APPLICATION-LEVEL SHARDING EXAMPLE
# ============================================================

import hashlib

class ShardManager:
    """Simple consistent-hashing shard manager."""

    def __init__(self, shard_configs: dict):
        """
        shard_configs = {
            0: {"host": "db-shard-0.internal", "port": 5432, "dbname": "myapp"},
            1: {"host": "db-shard-1.internal", "port": 5432, "dbname": "myapp"},
            2: {"host": "db-shard-2.internal", "port": 5432, "dbname": "myapp"},
        }
        """
        self.shard_configs = shard_configs
        self.num_shards = len(shard_configs)

    def get_shard_id(self, user_id: int) -> int:
        """Hash-based sharding."""
        return user_id % self.num_shards

    def get_connection(self, user_id: int):
        """Get database connection for the shard owning this user."""
        shard_id = self.get_shard_id(user_id)
        config = self.shard_configs[shard_id]
        # Return a connection from the pool for this shard
        return connection_pools[shard_id].getconn()

    def scatter_gather(self, query: str) -> list:
        """Execute query on ALL shards and combine results."""
        results = []
        for shard_id in self.shard_configs:
            conn = connection_pools[shard_id].getconn()
            cursor = conn.cursor()
            cursor.execute(query)
            results.extend(cursor.fetchall())
            connection_pools[shard_id].putconn(conn)
        return results


# ============================================================
# CHALLENGES OF SHARDING
# ============================================================
"""
1. CROSS-SHARD QUERIES
   - JOINs across shards are expensive (scatter-gather)
   - Solution: Denormalize data, keep related data on same shard

2. CROSS-SHARD TRANSACTIONS
   - 2PC (Two-Phase Commit) is slow and complex
   - Solution: Design for eventual consistency, use sagas

3. RESHARDING
   - Adding/removing shards requires data migration
   - Solution: Consistent hashing, virtual shards (many virtual → few physical)

4. AUTO-INCREMENT IDS
   - Can't use DB auto-increment across shards (collisions)
   - Solutions: UUID, Snowflake IDs, sequence per shard with offset

5. REFERENTIAL INTEGRITY
   - Foreign keys can't span shards
   - Solution: Application-level enforcement
"""
```

---

### READ REPLICAS

```
Architecture:

                    ┌──────────────┐
          Writes    │   Primary    │   Streaming
         ────────▶  │   (Master)   │   Replication
                    │              │──────────────┐──────────────┐
                    └──────────────┘              │              │
                                           ┌─────▼──────┐ ┌─────▼──────┐
                     Reads                 │  Replica 1  │ │  Replica 2  │
                    ────────────────────▶  │  (Read-only)│ │  (Read-only)│
                                           └─────────────┘ └─────────────┘

Replication Types:

1. SYNCHRONOUS: Primary waits for replica to confirm write
   + Strong consistency
   - Higher write latency
   - Primary blocked if replica is down

2. ASYNCHRONOUS: Primary doesn't wait
   + Lower write latency
   + Primary unaffected by replica issues
   - Replication lag: replicas may serve stale data

3. SEMI-SYNCHRONOUS (MySQL): Wait for at least 1 replica to acknowledge
   Compromise between the two
```

```sql
-- ============================================================
-- PostgreSQL STREAMING REPLICATION SETUP
-- ============================================================

-- On PRIMARY (postgresql.conf):
-- wal_level = replica
-- max_wal_senders = 5
-- synchronous_standby_names = ''   -- async (or 'replica1' for sync)

-- On REPLICA:
-- primary_conninfo = 'host=primary-host port=5432 user=replicator'
-- hot_standby = on   -- allows read queries on replica

-- Check replication status on PRIMARY:
SELECT
    client_addr,
    state,
    sent_lsn,
    write_lsn,
    flush_lsn,
    replay_lsn,
    pg_wal_lsn_diff(sent_lsn, replay_lsn) AS replication_lag_bytes,
    sync_state
FROM pg_stat_replication;

-- Check lag on REPLICA:
SELECT
    now() - pg_last_xact_replay_timestamp() AS replication_lag;
```

```python
# ============================================================
# APPLICATION-LEVEL READ/WRITE SPLITTING
# ============================================================

import random

class DatabaseRouter:
    """Routes queries to primary or replica based on operation type."""

    def __init__(self, primary_pool, replica_pools: list):
        self.primary_pool = primary_pool
        self.replica_pools = replica_pools

    def get_read_connection(self):
        """Round-robin across replicas for read queries."""
        pool = random.choice(self.replica_pools)
        return pool.getconn()

    def get_write_connection(self):
        """Always use primary for writes."""
        return self.primary_pool.getconn()

    def read_after_write_connection(self, user_session):
        """
        After a write, read from primary for a short window
        to avoid reading stale data from replica.
        """
        if user_session.get('last_write_time'):
            elapsed = time.time() - user_session['last_write_time']
            if elapsed < 5:  # 5-second window
                return self.get_write_connection()  # read from primary
        return self.get_read_connection()


# ============================================================
# HANDLING REPLICATION LAG
# ============================================================
"""
Strategies:
1. Read-your-writes consistency
   - After a write, read from primary for N seconds
   - Track last_write_timestamp in session/cookie

2. Monotonic reads
   - Always route a user to the same replica
   - Or track the LSN of the last write, and only read from
     replicas that have replayed past that LSN

3. Causal consistency
   - Pass the primary's LSN to the application
   - Before reading from replica, wait until replay_lsn >= write_lsn
   
   PostgreSQL supports this:
   SELECT pg_current_wal_lsn();  -- on primary after write
   -- On replica:
   SELECT pg_last_wal_replay_lsn();  -- wait until >= saved LSN
"""
```

---

## 4. TRANSACTIONS

---

### ACID Properties

```
┌─────────────────────────────────────────────────────────────────┐
│                         A C I D                                 │
├────────────────┬────────────────────────────────────────────────┤
│ Atomicity      │ All or nothing. If any part of a transaction  │
│                │ fails, the entire transaction is rolled back. │
│                │ Implementation: Write-Ahead Log (WAL)         │
│                │                                                │
│ Consistency    │ Transaction brings the database from one      │
│                │ valid state to another. Constraints, triggers, │
│                │ and cascades are all enforced.                 │
│                │ Implementation: Constraints + application logic│
│                │                                                │
│ Isolation      │ Concurrent transactions don't interfere with  │
│                │ each other. Each appears to run in isolation.  │
│                │ Implementation: MVCC + Locks                  │
│                │                                                │
│ Durability     │ Once committed, data survives crashes.        │
│                │ Implementation: WAL flushed to disk before    │
│                │ commit acknowledged.                           │
└────────────────┴────────────────────────────────────────────────┘
```

```sql
-- ============================================================
-- TRANSACTION EXAMPLES
-- ============================================================

-- Basic transaction
BEGIN;
UPDATE accounts SET balance = balance - 500 WHERE id = 1;
UPDATE accounts SET balance = balance + 500 WHERE id = 2;
-- If any statement fails, rollback both
COMMIT;
-- If we detect an error:
-- ROLLBACK;


-- ============================================================
-- SAVEPOINTS: partial rollback within a transaction
-- ============================================================
BEGIN;
INSERT INTO orders (user_id, amount) VALUES (1, 100);
SAVEPOINT sp1;

INSERT INTO order_items (order_id, product_id, qty) VALUES (1, 99, 1);
-- Oops, product 99 doesn't exist → constraint error
ROLLBACK TO SAVEPOINT sp1;

-- Continue with valid data
INSERT INTO order_items (order_id, product_id, qty) VALUES (1, 1, 1);
COMMIT;


-- ============================================================
-- WAL (Write-Ahead Log): How durability works
-- ============================================================
/*
1. Application: BEGIN; UPDATE ...; COMMIT;

2. PostgreSQL:
   a. Write new row version to shared buffer (memory)
   b. Write WAL record describing the change to WAL buffer
   c. On COMMIT: flush WAL buffer to disk (fsync)
   d. Acknowledge COMMIT to client
   e. Later: background writer flushes data pages to disk (checkpoint)

3. Crash recovery:
   - Read WAL from last checkpoint
   - Replay any committed transactions not yet in data files
   - Rollback any uncommitted transactions

This is why COMMIT can be fast: only sequential WAL writes needed,
not random data file writes.
*/

-- WAL configuration
SHOW wal_level;              -- minimal, replica, logical
SHOW synchronous_commit;     -- on, off, local, remote_write, remote_apply
-- synchronous_commit = off → faster commits, risk of losing last few ms
```

---

### DEADLOCKS

```
Deadlock: Two or more transactions waiting for each other's locks

Transaction A:                    Transaction B:
BEGIN;                            BEGIN;
UPDATE accounts SET balance=100   UPDATE accounts SET balance=200
WHERE id = 1;                     WHERE id = 2;
-- Holds lock on row 1            -- Holds lock on row 2

UPDATE accounts SET balance=200   UPDATE accounts SET balance=100
WHERE id = 2;                     WHERE id = 1;
-- WAITS for lock on row 2        -- WAITS for lock on row 1
   (held by B)                       (held by A)

          ╔══════════════════╗
          ║    DEADLOCK!     ║
          ║                  ║
          ║  A waits for B   ║
          ║  B waits for A   ║
          ╚══════════════════╝

PostgreSQL detects this (deadlock detector runs periodically)
and kills one transaction with:
ERROR: deadlock detected
```

```sql
-- ============================================================
-- DEADLOCK PREVENTION STRATEGIES
-- ============================================================

-- Strategy 1: CONSISTENT LOCK ORDERING
-- Always lock resources in the same order (e.g., by ID ascending)

-- BAD (different order in different code paths):
-- Transaction A: UPDATE ... WHERE id = 1; UPDATE ... WHERE id = 2;
-- Transaction B: UPDATE ... WHERE id = 2; UPDATE ... WHERE id = 1;

-- GOOD (same order everywhere):
-- Both transactions: UPDATE ... WHERE id = 1; UPDATE ... WHERE id = 2;

-- In application code:
-- def transfer(from_id, to_id, amount):
--     first, second = sorted([from_id, to_id])
--     lock(first); lock(second);  -- consistent order


-- Strategy 2: LOCK TIMEOUT
SET lock_timeout = '5s';  -- Give up waiting after 5 seconds
-- Prevents indefinite waits (not just deadlocks)


-- Strategy 3: SELECT FOR UPDATE with NOWAIT
BEGIN;
SELECT * FROM accounts WHERE id = 1 FOR UPDATE NOWAIT;
-- If locked, immediately raises an error instead of waiting
COMMIT;


-- Strategy 4: ADVISORY LOCKS for application-level ordering
BEGIN;
SELECT pg_advisory_xact_lock(hashtext('transfer:' || least(1,2)::text || ':' || greatest(1,2)::text));
-- Now only one transfer between accounts 1 and 2 can proceed
UPDATE accounts SET balance = balance - 100 WHERE id = 1;
UPDATE accounts SET balance = balance + 100 WHERE id = 2;
COMMIT;


-- ============================================================
-- DETECTING AND MONITORING DEADLOCKS
-- ============================================================

-- PostgreSQL logs deadlocks automatically:
-- LOG: process 1234 detected deadlock while waiting for ShareLock on transaction 5678

-- Configure:
-- log_lock_waits = on
-- deadlock_timeout = 1s   -- how long to wait before checking for deadlock

-- Find currently blocked queries
SELECT
    blocked.pid     AS blocked_pid,
    blocked.query   AS blocked_query,
    blocking.pid    AS blocking_pid,
    blocking.query  AS blocking_query,
    age(now(), blocked.query_start) AS wait_duration
FROM pg_stat_activity blocked
JOIN pg_locks bl ON bl.pid = blocked.pid AND NOT bl.granted
JOIN pg_locks kl ON kl.locktype = bl.locktype
    AND kl.database IS NOT DISTINCT FROM bl.database
    AND kl.relation IS NOT DISTINCT FROM bl.relation
    AND kl.page IS NOT DISTINCT FROM bl.page
    AND kl.tuple IS NOT DISTINCT FROM bl.tuple
    AND kl.virtualxid IS NOT DISTINCT FROM bl.virtualxid
    AND kl.transactionid IS NOT DISTINCT FROM bl.transactionid
    AND kl.classid IS NOT DISTINCT FROM bl.classid
    AND kl.objid IS NOT DISTINCT FROM bl.objid
    AND kl.pid != bl.pid
    AND kl.granted
JOIN pg_stat_activity blocking ON kl.pid = blocking.pid;

-- Kill a blocking query
SELECT pg_terminate_backend(blocking_pid);
```

---

### CONSISTENCY MODELS

```
┌─────────────────────────────────────────────────────────────────┐
│              CONSISTENCY MODELS SPECTRUM                        │
│                                                                 │
│  Strongest ◄──────────────────────────────────► Weakest         │
│                                                                 │
│  Linearizable                                                   │
│    │  Every read returns the most recent write.                 │
│    │  Single global order of operations.                        │
│    │  Like a single-threaded program.                           │
│    │  Example: Single PostgreSQL with SERIALIZABLE              │
│    │                                                            │
│  Sequential Consistency                                         │
│    │  Operations appear in SOME total order consistent          │
│    │  with each process's program order.                        │
│    │                                                            │
│  Causal Consistency                                             │
│    │  Causally related operations are seen in order.            │
│    │  Concurrent (unrelated) operations may be seen             │
│    │  in different orders by different nodes.                   │
│    │  Example: MongoDB with causal sessions                     │
│    │                                                            │
│  Read-Your-Writes                                               │
│    │  A process always sees its own writes.                     │
│    │  May not see others' recent writes.                        │
│    │                                                            │
│  Monotonic Reads                                                │
│    │  Once you read a value, you never see an older one.        │
│    │                                                            │
│  Eventual Consistency                                           │
│       If no new writes, all replicas eventually converge.       │
│       No ordering guarantees during convergence.                │
│       Example: DNS, DynamoDB (default), Cassandra               │
└─────────────────────────────────────────────────────────────────┘
```

```
CAP Theorem:

    Consistency ─────────── Availability
         \                    /
          \                  /
           \   Pick Two    /
            \    (in the  /
             \  presence /
              \ of P)   /
               \       /
                \     /
                 \   /
            Partition
            Tolerance

In practice:
  - Network partitions WILL happen → you must choose P
  - Choice is really between CP and AP:

  CP (Consistency + Partition tolerance):
    - Refuse to serve requests during partition
    - Examples: PostgreSQL, etcd, ZooKeeper, HBase
    - Use for: Financial transactions, inventory, leader election

  AP (Availability + Partition tolerance):
    - Always respond, even with stale data
    - Examples: Cassandra, DynamoDB, CouchDB
    - Use for: Social media feeds, analytics, caching

  The choice is often PER-OPERATION, not per-system.
  Example: User profile reads = AP, Payment processing = CP
```

---

## 5. NoSQL DATABASES

---

### REDIS

```python
import redis
import json
import time
import uuid

r = redis.Redis(host='localhost', port=6379, db=0, decode_responses=True)

# ============================================================
# BASIC DATA STRUCTURES
# ============================================================

# Strings
r.set('user:1:name', 'Alice')
r.get('user:1:name')  # 'Alice'
r.incr('page_views:home')  # Atomic increment
r.incrby('page_views:home', 10)

# Hashes (like a row/object)
r.hset('user:1', mapping={
    'name': 'Alice',
    'email': 'alice@example.com',
    'salary': '150000',
    'department': 'Engineering'
})
r.hget('user:1', 'name')       # 'Alice'
r.hgetall('user:1')            # Full dict
r.hincrby('user:1', 'salary', 5000)  # Atomic field increment

# Lists (ordered, allows duplicates)
r.lpush('queue:emails', 'email1', 'email2')  # Push left
r.rpop('queue:emails')                        # Pop right (FIFO queue)
r.lrange('queue:emails', 0, -1)              # Get all

# Sets (unordered, unique)
r.sadd('tags:article:1', 'python', 'redis', 'database')
r.smembers('tags:article:1')
r.sinter('tags:article:1', 'tags:article:2')  # Intersection

# Sorted Sets (ordered by score, unique members)
r.zadd('leaderboard', {'Alice': 1500, 'Bob': 1200, 'Charlie': 1800})
r.zrevrange('leaderboard', 0, 2, withscores=True)  # Top 3
r.zincrby('leaderboard', 50, 'Alice')               # Update score
r.zrank('leaderboard', 'Alice')                      # Rank (0-based)


# ============================================================
# CACHING PATTERNS
# ============================================================

# --- Pattern 1: Cache-Aside (Lazy Loading) ---
def get_user(user_id: int) -> dict:
    """Most common pattern. App manages the cache."""
    cache_key = f'user:{user_id}'

    # 1. Check cache
    cached = r.get(cache_key)
    if cached:
        return json.loads(cached)  # Cache HIT

    # 2. Cache MISS → query database
    user = db.query("SELECT * FROM users WHERE id = %s", user_id)

    # 3. Populate cache
    r.setex(cache_key, 3600, json.dumps(user))  # TTL: 1 hour

    return user

def update_user(user_id: int, data: dict):
    """On write, invalidate cache."""
    db.execute("UPDATE users SET ... WHERE id = %s", user_id)
    r.delete(f'user:{user_id}')  # Invalidate → next read will repopulate


# --- Pattern 2: Write-Through ---
def update_user_write_through(user_id: int, data: dict):
    """Write to DB AND cache simultaneously."""
    db.execute("UPDATE users SET ... WHERE id = %s", user_id)
    r.setex(f'user:{user_id}', 3600, json.dumps(data))
    # Pro: cache is always fresh
    # Con: write latency increases, cache may hold never-read data


# --- Pattern 3: Write-Behind (Write-Back) ---
def update_user_write_behind(user_id: int, data: dict):
    """Write to cache immediately, async write to DB."""
    r.setex(f'user:{user_id}', 3600, json.dumps(data))
    # Queue the DB write
    r.lpush('db_write_queue', json.dumps({
        'table': 'users', 'id': user_id, 'data': data
    }))
    # Background worker processes the queue and writes to DB
    # Pro: very fast writes
    # Con: data loss risk if Redis crashes before DB write


# --- Pattern 4: Read-Through (Cache as primary interface) ---
# Similar to cache-aside but the cache layer handles DB fetching
# Typically implemented with a framework (e.g., Spring Cache)


# --- Cache Stampede Prevention ---
def get_user_with_stampede_prevention(user_id: int) -> dict:
    """Prevent thundering herd when cache expires."""
    cache_key = f'user:{user_id}'
    lock_key = f'lock:user:{user_id}'

    cached = r.get(cache_key)
    if cached:
        return json.loads(cached)

    # Try to acquire lock (only one request rebuilds cache)
    if r.set(lock_key, '1', nx=True, ex=10):  # NX=set if not exists
        try:
            user = db.query("SELECT * FROM users WHERE id = %s", user_id)
            r.setex(cache_key, 3600, json.dumps(user))
            return user
        finally:
            r.delete(lock_key)
    else:
        # Another request is rebuilding; wait and retry
        time.sleep(0.1)
        return get_user_with_stampede_prevention(user_id)


# ============================================================
# PUB/SUB
# ============================================================

# Publisher
def publish_event(channel: str, event: dict):
    r.publish(channel, json.dumps(event))

publish_event('user:events', {'type': 'signup', 'user_id': 42})

# Subscriber (blocking - run in a separate thread/process)
def subscribe_to_events():
    pubsub = r.pubsub()
    pubsub.subscribe('user:events')

    for message in pubsub.listen():
        if message['type'] == 'message':
            event = json.loads(message['data'])
            print(f"Received: {event}")

# Pattern subscribe (wildcard)
def subscribe_to_all_user_events():
    pubsub = r.pubsub()
    pubsub.psubscribe('user:*')  # Matches user:events, user:updates, etc.

    for message in pubsub.listen():
        if message['type'] == 'pmessage':
            channel = message['channel']
            event = json.loads(message['data'])
            print(f"[{channel}] {event}")

"""
Pub/Sub limitations:
  - Fire and forget: if subscriber is down, messages are lost
  - No persistence: unlike Kafka/RabbitMQ
  - Use Redis Streams for persistent messaging (XADD/XREAD/XREADGROUP)
"""

# ============================================================
# REDIS STREAMS (better than Pub/Sub for reliable messaging)
# ============================================================
# Add to stream
r.xadd('events:stream', {'type': 'order', 'user_id': '1', 'amount': '99.99'})

# Create consumer group
r.xgroup_create('events:stream', 'processors', id='0', mkstream=True)

# Read as consumer in group
messages = r.xreadgroup('processors', 'worker-1', {'events:stream': '>'}, count=10)
# Process message, then acknowledge
for stream, entries in messages:
    for msg_id, data in entries:
        process(data)
        r.xack('events:stream', 'processors', msg_id)


# ============================================================
# DISTRIBUTED LOCKS (Redlock pattern)
# ============================================================

def acquire_lock(lock_name: str, ttl_seconds: int = 10) -> str | None:
    """
    Simple distributed lock with Redis.
    Returns lock_id if acquired, None if not.
    """
    lock_id = str(uuid.uuid4())
    acquired = r.set(
        f'lock:{lock_name}',
        lock_id,
        nx=True,      # Only set if not exists
        ex=ttl_seconds # Auto-expire (prevents deadlocks)
    )
    return lock_id if acquired else None

def release_lock(lock_name: str, lock_id: str) -> bool:
    """
    Release lock ONLY if we own it (compare lock_id).
    Uses Lua script for atomicity.
    """
    lua_script = """
    if redis.call("get", KEYS[1]) == ARGV[1] then
        return redis.call("del", KEYS[1])
    else
        return 0
    end
    """
    result = r.eval(lua_script, 1, f'lock:{lock_name}', lock_id)
    return result == 1

# Usage:
lock_id = acquire_lock('process-payment:order-123', ttl_seconds=30)
if lock_id:
    try:
        process_payment(order_id=123)
    finally:
        release_lock('process-payment:order-123', lock_id)
else:
    print("Could not acquire lock — another worker is processing this order")


"""
Redlock Algorithm (for true distributed lock across multiple Redis instances):
  1. Get current time in milliseconds
  2. Try to acquire lock on N Redis instances (e.g., 5)
  3. Lock acquired if majority (N/2 + 1) succeed AND total time < TTL
  4. If failed, release all locks
  
  Use the 'python-redis-lock' or 'pottery' library for production.
"""


# ============================================================
# TTL STRATEGIES
# ============================================================

# Fixed TTL: simple, predictable
r.setex('session:abc123', 1800, 'user_data')  # 30 minutes

# Sliding TTL: extend on each access (sessions)
def get_session(session_id: str):
    data = r.get(f'session:{session_id}')
    if data:
        r.expire(f'session:{session_id}', 1800)  # Reset TTL on access
    return data

# Randomized TTL: prevent cache stampede
import random
base_ttl = 3600  # 1 hour
jitter = random.randint(-300, 300)  # ±5 minutes
r.setex(cache_key, base_ttl + jitter, cached_data)

# Eternal cache with background refresh
# - Set no TTL (or very long TTL)
# - Background job refreshes periodically
# - Stale data is acceptable briefly

# TTL for rate limiting
def rate_limit(user_id: int, max_requests: int = 100, window: int = 60) -> bool:
    """Sliding window rate limiter."""
    key = f'ratelimit:{user_id}'
    current = r.incr(key)
    if current == 1:
        r.expire(key, window)  # Set TTL only on first request in window
    return current <= max_requests

# Sorted set sliding window (more precise)
def rate_limit_precise(user_id: int, max_requests: int = 100, window: int = 60) -> bool:
    key = f'ratelimit:{user_id}'
    now = time.time()
    pipeline = r.pipeline()
    pipeline.zremrangebyscore(key, 0, now - window)  # Remove old entries
    pipeline.zadd(key, {str(uuid.uuid4()): now})     # Add current request
    pipeline.zcard(key)                                # Count requests in window
    pipeline.expire(key, window)                       # Cleanup
    results = pipeline.execute()
    request_count = results[2]
    return request_count <= max_requests
```

---

### MONGODB

```javascript
// ============================================================
// DOCUMENT MODEL
// ============================================================

// A MongoDB "document" = a JSON-like object (BSON internally)
// No fixed schema — each document in a collection can differ

// Insert documents
db.users.insertOne({
    _id: ObjectId("..."),          // Auto-generated unique ID
    name: "Alice",
    email: "alice@example.com",
    age: 30,
    address: {                      // Embedded document
        street: "123 Main St",
        city: "San Francisco",
        state: "CA",
        zip: "94105"
    },
    skills: ["Python", "MongoDB", "Redis"],  // Array
    projects: [                     // Array of embedded documents
        { name: "Alpha", role: "Lead", hours: 500 },
        { name: "Beta", role: "Developer", hours: 200 }
    ],
    created_at: ISODate("2024-01-15T10:30:00Z"),
    metadata: {                     // Flexible schema
        source: "signup_form",
        referral_code: "ABC123"
    }
});

// Schema design choices:
// EMBED when:
//   - 1:1 or 1:few relationships
//   - Data is always accessed together
//   - Child data doesn't make sense without parent
//   Example: user.address, order.items

// REFERENCE when:
//   - 1:many or many:many relationships
//   - Data is accessed independently
//   - Document would exceed 16MB limit
//   - Data changes frequently and independently
//   Example: user_id in orders collection

// Reference pattern:
db.orders.insertOne({
    user_id: ObjectId("..."),     // Reference to users collection
    items: [
        { product_id: ObjectId("..."), qty: 2, price: 29.99 }
    ],
    total: 59.98,
    status: "shipped"
});


// ============================================================
// CRUD OPERATIONS
// ============================================================

// --- Find ---
db.users.find({ age: { $gte: 25 } });
db.users.find({ "address.city": "San Francisco" });      // Dot notation
db.users.find({ skills: "Python" });                      // Array contains
db.users.find({ skills: { $all: ["Python", "MongoDB"] }});  // All of these
db.users.find({
    $or: [{ age: { $lt: 25 }}, { "address.state": "CA" }]
});

// Projection (select specific fields)
db.users.find(
    { age: { $gte: 25 } },
    { name: 1, email: 1, _id: 0 }   // Include name, email; exclude _id
);

// --- Update ---
db.users.updateOne(
    { _id: ObjectId("...") },
    {
        $set: { age: 31 },
        $push: { skills: "Elasticsearch" },
        $inc: { "metrics.login_count": 1 }
    }
);

// Update with array filters
db.users.updateOne(
    { _id: ObjectId("...") },
    { $set: { "projects.$[p].hours": 600 } },
    { arrayFilters: [{ "p.name": "Alpha" }] }
);

// --- Delete ---
db.users.deleteMany({ created_at: { $lt: ISODate("2020-01-01") } });


// ============================================================
// AGGREGATION PIPELINE
// ============================================================

// The aggregation pipeline is MongoDB's equivalent of SQL
// GROUP BY + window functions + subqueries

// Example: Department salary statistics
db.employees.aggregate([
    // Stage 1: Filter
    { $match: { status: "active" } },

    // Stage 2: Join with departments (like SQL LEFT JOIN)
    { $lookup: {
        from: "departments",
        localField: "department_id",
        foreignField: "_id",
        as: "department"
    }},

    // Stage 3: Unwind the joined array (1 doc per match)
    { $unwind: "$department" },

    // Stage 4: Group and aggregate
    { $group: {
        _id: "$department.name",
        avg_salary: { $avg: "$salary" },
        max_salary: { $max: "$salary" },
        min_salary: { $min: "$salary" },
        employee_count: { $sum: 1 },
        employees: { $push: "$name" }    // Collect names into array
    }},

    // Stage 5: Filter groups
    { $match: { avg_salary: { $gt: 100000 } } },

    // Stage 6: Sort
    { $sort: { avg_salary: -1 } },

    // Stage 7: Reshape output
    { $project: {
        department: "$_id",
        _id: 0,
        avg_salary: { $round: ["$avg_salary", 2] },
        employee_count: 1,
        salary_range: { $subtract: ["$max_salary", "$min_salary"] }
    }}
]);


// More pipeline stages:
// $addFields:  Add computed fields
// $bucket:     Group into ranges (histograms)
// $facet:      Run multiple pipelines in parallel
// $graphLookup: Recursive lookup (like recursive CTE)
// $merge:      Write results to another collection (materialized view)
// $unionWith:  UNION ALL equivalent

// Example: Faceted search (run multiple aggregations at once)
db.products.aggregate([
    { $match: { status: "available" } },
    { $facet: {
        by_category: [
            { $group: { _id: "$category", count: { $sum: 1 } } }
        ],
        by_price_range: [
            { $bucket: {
                groupBy: "$price",
                boundaries: [0, 25, 50, 100, 500],
                default: "500+",
                output: { count: { $sum: 1 } }
            }}
        ],
        total_count: [
            { $count: "count" }
        ]
    }}
]);


// ============================================================
// INDEXING IN MONGODB
// ============================================================

// Single field index
db.users.createIndex({ email: 1 });       // 1 = ascending
db.users.createIndex({ age: -1 });        // -1 = descending

// Compound index (order matters, just like PostgreSQL)
db.users.createIndex({ department_id: 1, salary: -1 });

// Unique index
db.users.createIndex({ email: 1 }, { unique: true });

// Partial index (like PostgreSQL partial index)
db.orders.createIndex(
    { created_at: 1 },
    { partialFilterExpression: { status: "pending" } }
);

// TTL index (auto-delete documents after expiry)
db.sessions.createIndex(
    { created_at: 1 },
    { expireAfterSeconds: 3600 }  // Delete after 1 hour
);

// Text index (full-text search)
db.articles.createIndex({ title: "text", body: "text" });
db.articles.find({ $text: { $search: "mongodb performance" } });

// Multikey index (on array fields — automatic)
db.users.createIndex({ skills: 1 });
// Automatically indexes each array element

// Wildcard index (for dynamic/unknown fields)
db.events.createIndex({ "metadata.$**": 1 });

// Check index usage
db.users.find({ email: "alice@example.com" }).explain("executionStats");

// List indexes
db.users.getIndexes();
```

```python
# ============================================================
# MONGODB WITH PYTHON (PyMongo)
# ============================================================

from pymongo import MongoClient, ASCENDING, DESCENDING
from pymongo.errors import DuplicateKeyError

client = MongoClient('mongodb://localhost:27017/')
db = client['myapp']
users = db['users']

# Insert
user_id = users.insert_one({
    'name': 'Alice',
    'email': 'alice@example.com',
    'department': 'Engineering',
    'salary': 150000
}).inserted_id

# Find with projection
user = users.find_one(
    {'email': 'alice@example.com'},
    {'name': 1, 'salary': 1, '_id': 0}
)

# Aggregation
pipeline = [
    {'$match': {'salary': {'$gte': 100000}}},
    {'$group': {
        '_id': '$department',
        'avg_salary': {'$avg': '$salary'},
        'count': {'$sum': 1}
    }},
    {'$sort': {'avg_salary': -1}}
]
results = list(users.aggregate(pipeline))

# Transactions (replica set required)
with client.start_session() as session:
    with session.start_transaction():
        users.update_one(
            {'_id': sender_id},
            {'$inc': {'balance': -100}},
            session=session
        )
        users.update_one(
            {'_id': receiver_id},
            {'$inc': {'balance': 100}},
            session=session
        )
        # Auto-commits on exit, or auto-aborts on exception
```

---

### ELASTICSEARCH

```python
from elasticsearch import Elasticsearch

es = Elasticsearch(['http://localhost:9200'])

# ============================================================
# INDEX MANAGEMENT
# ============================================================

# Create index with mappings (schema)
es.indices.create(index='products', body={
    'settings': {
        'number_of_shards': 3,
        'number_of_replicas': 1,
        'analysis': {
            'analyzer': {
                'custom_analyzer': {
                    'type': 'custom',
                    'tokenizer': 'standard',
                    'filter': ['lowercase', 'stop', 'snowball']
                }
            }
        }
    },
    'mappings': {
        'properties': {
            'name':        {'type': 'text', 'analyzer': 'custom_analyzer',
                           'fields': {'keyword': {'type': 'keyword'}}},
            'description': {'type': 'text'},
            'price':       {'type': 'float'},
            'category':    {'type': 'keyword'},   # exact match, aggregations
            'tags':        {'type': 'keyword'},
            'in_stock':    {'type': 'boolean'},
            'created_at':  {'type': 'date'},
            'location':    {'type': 'geo_point'}
        }
    }
})


# ============================================================
# INDEXING DOCUMENTS
# ============================================================

# Index a single document
es.index(index='products', id='1', body={
    'name': 'Redis in Action',
    'description': 'A comprehensive guide to Redis data structures and patterns',
    'price': 39.99,
    'category': 'Books',
    'tags': ['redis', 'database', 'caching'],
    'in_stock': True,
    'created_at': '2024-01-15'
})

# Bulk indexing (much faster for large datasets)
from elasticsearch.helpers import bulk

actions = [
    {
        '_index': 'products',
        '_id': str(i),
        '_source': {
            'name': f'Product {i}',
            'price': i * 9.99,
            'category': 'Electronics',
            'in_stock': True
        }
    }
    for i in range(1000)
]
bulk(es, actions)


# ============================================================
# SEARCH QUERIES
# ============================================================

# --- Full-text search ---
result = es.search(index='products', body={
    'query': {
        'match': {                          # Analyzed text search
            'description': 'redis caching patterns'
        }
    }
})

# --- Multi-field search ---
result = es.search(index='products', body={
    'query': {
        'multi_match': {
            'query': 'redis guide',
            'fields': ['name^3', 'description'],  # name boosted 3x
            'type': 'best_fields'
        }
    }
})

# --- Boolean compound query ---
result = es.search(index='products', body={
    'query': {
        'bool': {
            'must': [                                     # AND (scored)
                {'match': {'description': 'redis'}}
            ],
            'filter': [                                   # AND (not scored, cached)
                {'term': {'category': 'Books'}},
                {'range': {'price': {'lte': 50}}},
                {'term': {'in_stock': True}}
            ],
            'should': [                                   # OR (boosts score)
                {'match': {'tags': 'bestseller'}}
            ],
            'must_not': [                                 # NOT
                {'term': {'category': 'Discontinued'}}
            ]
        }
    },
    'sort': [
        {'_score': 'desc'},
        {'price': 'asc'}
    ],
    'from': 0,
    'size': 20,
    'highlight': {
        'fields': {
            'description': {}
        }
    }
})

# Access results
for hit in result['hits']['hits']:
    print(f"Score: {hit['_score']}, Name: {hit['_source']['name']}")
    if 'highlight' in hit:
        print(f"  Highlight: {hit['highlight']['description']}")


# --- Aggregations (like SQL GROUP BY) ---
result = es.search(index='products', body={
    'size': 0,  # Don't return documents, just aggregations
    'aggs': {
        'by_category': {
            'terms': {'field': 'category', 'size': 20},
            'aggs': {
                'avg_price': {'avg': {'field': 'price'}},
                'price_ranges': {
                    'range': {
                        'field': 'price',
                        'ranges': [
                            {'to': 25},
                            {'from': 25, 'to': 100},
                            {'from': 100}
                        ]
                    }
                }
            }
        },
        'price_stats': {
            'stats': {'field': 'price'}  # min, max, avg, sum, count
        }
    }
})


# ============================================================
# ELASTICSEARCH ARCHITECTURE
# ============================================================
"""
┌─────────────────────────────────────────────────────────┐
│                    ES Cluster                           │
│                                                         │
│  Node 1                Node 2              Node 3       │
│  ┌────────────┐       ┌────────────┐     ┌────────────┐ │
│  │ Shard 0(P) │       │ Shard 1(P) │     │ Shard 2(P) │ │
│  │ Shard 1(R) │       │ Shard 2(R) │     │ Shard 0(R) │ │
│  └────────────┘       └────────────┘     └────────────┘ │
│                                                         │
│  P = Primary shard, R = Replica shard                   │
│                                                         │
│  Index "products" with 3 shards, 1 replica:             │
│  - 3 primary shards distributed across nodes            │
│  - 3 replica shards on different nodes (fault tolerance) │
│  - Each shard is a Lucene index                         │
│                                                         │
│  Inverted Index (inside each shard):                    │
│  ┌──────────────┬────────────────────┐                  │
│  │ Term         │ Document IDs       │                  │
│  ├──────────────┼────────────────────┤                  │
│  │ "redis"      │ [1, 5, 23, 156]   │                  │
│  │ "caching"    │ [1, 8, 42]         │                  │
│  │ "database"   │ [1, 3, 5, 8, 42]  │                  │
│  └──────────────┴────────────────────┘                  │
│                                                         │
│  text field → analyzed (tokenized, lowercased, stemmed) │
│  keyword field → exact value (not analyzed)             │
└─────────────────────────────────────────────────────────┘

When to use Elasticsearch:
  ✅ Full-text search with relevance scoring
  ✅ Log aggregation and analysis (ELK stack)
  ✅ Autocomplete / search suggestions
  ✅ Faceted navigation (e-commerce filters)
  ✅ Geo-spatial queries
  ✅ Real-time analytics dashboards

When NOT to use:
  ❌ Primary data store (no ACID transactions)
  ❌ Frequent updates to existing documents
  ❌ Strong consistency requirements
  ❌ Complex relational queries (joins)
"""
```

---

## DECISION FRAMEWORK: SQL vs NoSQL

```
┌────────────────────┬──────────────────┬──────────────────┬───────────────┐
│ Requirement        │ PostgreSQL/MySQL │ MongoDB          │ Redis         │
├────────────────────┼──────────────────┼──────────────────┼───────────────┤
│ ACID transactions  │ ✅ Native        │ ⚠️ Multi-doc     │ ❌ Single-key  │
│                    │                  │   since 4.0      │   atomic only │
│ Complex queries    │ ✅ SQL, JOINs    │ ⚠️ Aggregation   │ ❌             │
│                    │                  │   pipeline       │               │
│ Flexible schema    │ ⚠️ JSONB column  │ ✅ Native        │ ⚠️ Hashes     │
│ Read performance   │ ✅ With indexes  │ ✅ With indexes   │ ✅✅ In-memory │
│ Write throughput   │ ✅ Good          │ ✅ Good           │ ✅✅ Excellent │
│ Full-text search   │ ⚠️ Basic         │ ⚠️ Atlas Search  │ ❌ Use ES     │
│ Horizontal scale   │ ⚠️ Hard (shard)  │ ✅ Native        │ ✅ Cluster    │
│ Data relationships │ ✅ Foreign keys  │ ⚠️ $lookup       │ ❌             │
│ Caching            │ ❌               │ ❌               │ ✅ Primary use│
│ Time-series        │ ⚠️ TimescaleDB   │ ⚠️ Time-series   │ ⚠️ Sorted sets│
│ Geospatial         │ ✅ PostGIS       │ ✅ Built-in      │ ✅ GEO*       │
└────────────────────┴──────────────────┴──────────────────┴───────────────┘

Common Architecture:
  PostgreSQL  → Source of truth (orders, users, financial data)
  Redis       → Caching layer, sessions, rate limiting, real-time features
  MongoDB     → Content management, event logs, flexible-schema data
  Elasticsearch → Search functionality, log analysis
```