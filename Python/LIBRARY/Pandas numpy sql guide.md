# 📊 Data Analysis with Pandas & NumPy
### A Beginner's Guide to Python's Most Powerful Data Libraries

---

> **Who is this for?**
> This guide is written for beginners stepping into data analysis and programming. No prior experience with pandas or numpy is required — just a basic understanding of Python will do!

---

## Table of Contents

1. [Introduction](#introduction)
2. [NumPy — The Foundation of Numerical Computing](#numpy)
3. [Pandas — The Data Manipulation Powerhouse](#pandas)
4. [SQL vs Pandas — A Head-to-Head Comparison](#sql-vs-pandas)
5. [What Pandas Can Do That SQL Cannot](#pandas-beyond-sql)
6. [Quick Reference Cheat Sheet](#cheat-sheet)

---

## 1. Introduction

Before diving in, here's a simple mental model to keep in mind:

- **NumPy** is like a super-powered calculator. It deals with numbers, matrices, and mathematical operations at blazing speed.
- **Pandas** is like a smart spreadsheet. It lets you load, clean, explore, and transform data stored in rows and columns.
- **SQL** is a database query language. It's excellent at fetching and filtering data stored in relational databases.

All three tools can work with tabular data — but they each have their strengths. By the end of this guide, you'll know exactly when and why to use each one.

---

## 2. NumPy — The Foundation of Numerical Computing

NumPy (Numerical Python) is the backbone of nearly every data science library in Python. Pandas itself is built on top of NumPy.

### 📦 Installation
```python
pip install numpy
import numpy as np
```

---

### 2.1 The `ndarray` — NumPy's Core Data Structure

The `ndarray` (n-dimensional array) is the heart of NumPy. Think of it as a list, but far more powerful — it can hold data in multiple dimensions (rows, columns, depth) and performs operations much faster than a regular Python list.

```python
# 1D Array (like a list)
arr = np.array([1, 2, 3, 4, 5])

# 2D Array (like a table with rows and columns)
matrix = np.array([[1, 2, 3],
                   [4, 5, 6]])

print(arr.shape)     # (5,)  — 5 elements, 1 dimension
print(matrix.shape)  # (2, 3) — 2 rows, 3 columns
```

> 💡 **Beginner Tip:** Think of a 1D array as a single row of numbers, and a 2D array as a table with rows and columns.

---

### 2.2 Creating Arrays

| Function | Description | Example |
|---|---|---|
| `np.array()` | Creates an array from a list | `np.array([1, 2, 3])` |
| `np.zeros()` | Creates an array filled with 0s | `np.zeros((3, 3))` |
| `np.ones()` | Creates an array filled with 1s | `np.ones((2, 4))` |
| `np.arange()` | Creates a range of numbers | `np.arange(0, 10, 2)` → `[0, 2, 4, 6, 8]` |
| `np.linspace()` | Creates evenly spaced numbers | `np.linspace(0, 1, 5)` → `[0, 0.25, 0.5, 0.75, 1.0]` |
| `np.random.rand()` | Creates an array of random numbers (0 to 1) | `np.random.rand(3, 3)` |
| `np.eye()` | Creates an identity matrix | `np.eye(3)` |
| `np.full()` | Creates an array filled with a specific value | `np.full((2,2), 7)` |

```python
# Example
zeros = np.zeros((3, 3))   # 3x3 grid of zeros
rng   = np.arange(1, 11)   # [1, 2, 3, ..., 10]
space = np.linspace(0, 1, 5) # 5 evenly spaced values between 0 and 1
```

---

### 2.3 Array Indexing and Slicing

Just like Python lists, you can access elements in a NumPy array using indices. The key difference is that NumPy supports multi-dimensional indexing.

```python
arr = np.array([10, 20, 30, 40, 50])

arr[0]    # 10  — first element
arr[-1]   # 50  — last element
arr[1:4]  # [20, 30, 40] — elements at index 1, 2, 3

# 2D Indexing: [row, column]
matrix = np.array([[1, 2, 3],
                   [4, 5, 6],
                   [7, 8, 9]])

matrix[0, 0]   # 1   — row 0, column 0
matrix[1, 2]   # 6   — row 1, column 2
matrix[:, 1]   # [2, 5, 8] — all rows, column 1
matrix[0:2, :]  # First two rows, all columns
```

---

### 2.4 Array Operations (Element-wise)

NumPy makes it incredibly easy to perform mathematical operations on entire arrays without writing loops.

```python
a = np.array([1, 2, 3])
b = np.array([4, 5, 6])

a + b    # [5, 7, 9]
a * b    # [4, 10, 18]
a ** 2   # [1, 4, 9]
a + 10   # [11, 12, 13] — broadcasting: adds 10 to each element
```

> 💡 **Broadcasting:** When you do `a + 10`, NumPy automatically "broadcasts" the scalar value `10` to match the array size. This saves you from writing loops!

---

### 2.5 Mathematical Functions

```python
arr = np.array([1, 4, 9, 16, 25])

np.sqrt(arr)    # [1.0, 2.0, 3.0, 4.0, 5.0] — square root
np.log(arr)     # natural logarithm of each element
np.exp(arr)     # e raised to the power of each element
np.abs(arr)     # absolute value of each element
np.sin(arr)     # sine of each element (in radians)
```

---

### 2.6 Statistical Functions

These are among the most commonly used NumPy tools in data analysis:

```python
arr = np.array([10, 20, 30, 40, 50])

np.mean(arr)    # 30.0  — average
np.median(arr)  # 30.0  — middle value
np.std(arr)     # 14.14 — standard deviation (spread of data)
np.var(arr)     # 200.0 — variance
np.min(arr)     # 10    — smallest value
np.max(arr)     # 50    — largest value
np.sum(arr)     # 150   — sum of all elements
np.cumsum(arr)  # [10, 30, 60, 100, 150] — running total
np.percentile(arr, 75)  # 40.0 — value at 75th percentile
```

---

### 2.7 Reshaping and Transposing

```python
arr = np.arange(1, 13)  # [1, 2, 3, ..., 12]

reshaped = arr.reshape(3, 4)   # Reshape to 3 rows, 4 columns
transposed = reshaped.T        # Flip rows and columns
flattened = reshaped.flatten() # Convert back to 1D

print(reshaped.shape)     # (3, 4)
print(transposed.shape)   # (4, 3)
```

---

### 2.8 Boolean Indexing (Filtering)

One of NumPy's most powerful features — filter data using conditions:

```python
arr = np.array([5, 15, 25, 35, 45])

arr[arr > 20]          # [25, 35, 45] — values greater than 20
arr[(arr > 10) & (arr < 40)]  # [15, 25, 35] — values between 10 and 40
```

---

### 2.9 Linear Algebra

NumPy has a dedicated module (`np.linalg`) for linear algebra operations:

```python
A = np.array([[1, 2], [3, 4]])
B = np.array([[5, 6], [7, 8]])

np.dot(A, B)          # Matrix multiplication
np.linalg.inv(A)      # Inverse of a matrix
np.linalg.det(A)      # Determinant of a matrix
np.linalg.eig(A)      # Eigenvalues and eigenvectors
```

---

### 2.10 Sorting and Searching

```python
arr = np.array([3, 1, 4, 1, 5, 9, 2, 6])

np.sort(arr)           # [1, 1, 2, 3, 4, 5, 6, 9] — sorted array
np.argsort(arr)        # Returns indices that would sort the array
np.argmax(arr)         # Index of the maximum value
np.argmin(arr)         # Index of the minimum value
np.where(arr > 4)      # Indices where condition is True
```

---

## 3. Pandas — The Data Manipulation Powerhouse

Pandas is built on top of NumPy and is designed to work with labeled, structured data — think spreadsheets or database tables.

### 📦 Installation
```python
pip install pandas
import pandas as pd
```

---

### 3.1 Core Data Structures

Pandas has two primary data structures:

#### Series — A labeled 1D array
```python
# Like a single column in a spreadsheet
scores = pd.Series([85, 92, 78, 95], index=["Alice", "Bob", "Carol", "Dave"])
print(scores["Alice"])  # 85
```

#### DataFrame — A labeled 2D table
```python
# Like a full spreadsheet with rows and columns
data = {
    "Name":   ["Alice", "Bob", "Carol", "Dave"],
    "Age":    [25, 30, 22, 35],
    "Score":  [85, 92, 78, 95],
    "City":   ["Delhi", "Mumbai", "Pune", "Chennai"]
}
df = pd.DataFrame(data)
```

> 💡 **Beginner Tip:** You'll use `DataFrame` 90% of the time. Think of it as a smart table where every row is a record and every column is a feature/attribute.

---

### 3.2 Loading and Saving Data

```python
# Reading data
df = pd.read_csv("data.csv")           # From a CSV file
df = pd.read_excel("data.xlsx")        # From an Excel file
df = pd.read_json("data.json")         # From a JSON file
df = pd.read_sql("SELECT * FROM tbl", conn)  # From a SQL database

# Saving data
df.to_csv("output.csv", index=False)   # To CSV
df.to_excel("output.xlsx", index=False) # To Excel
df.to_json("output.json")              # To JSON
```

---

### 3.3 Exploring a DataFrame

Before analyzing data, always start by understanding its structure:

```python
df.head()       # First 5 rows (great for a quick peek)
df.tail()       # Last 5 rows
df.shape        # (rows, columns) — e.g., (1000, 10)
df.info()       # Column names, data types, non-null counts
df.describe()   # Statistical summary (mean, std, min, max, etc.)
df.columns      # List all column names
df.dtypes       # Data type of each column
df.isnull().sum()  # Count of missing values per column
df.nunique()    # Number of unique values per column
df.value_counts()  # Frequency count of values in a Series
```

---

### 3.4 Selecting Data

```python
# Select a single column (returns a Series)
df["Name"]

# Select multiple columns (returns a DataFrame)
df[["Name", "Score"]]

# Select rows by position (like list indexing)
df.iloc[0]        # First row
df.iloc[0:3]      # First 3 rows
df.iloc[1, 2]     # Row 1, Column 2

# Select rows by label
df.loc[0]         # Row with index label 0
df.loc[0:2, "Name":"Score"]  # Rows 0-2, columns Name to Score
```

> 💡 **iloc vs loc:**
> - `iloc` uses **integer positions** (like Python list indexing)
> - `loc` uses **labels/names** (more intuitive for named data)

---

### 3.5 Filtering Data (Boolean Indexing)

```python
# Filter rows where Score > 80
df[df["Score"] > 80]

# Filter with multiple conditions
df[(df["Score"] > 80) & (df["Age"] < 30)]

# Filter using isin() — check if value is in a list
df[df["City"].isin(["Delhi", "Mumbai"])]

# Filter using string methods
df[df["Name"].str.startswith("A")]
```

---

### 3.6 Adding, Renaming, and Dropping Columns

```python
# Add a new column
df["Grade"] = df["Score"].apply(lambda x: "Pass" if x >= 80 else "Fail")

# Rename columns
df.rename(columns={"Score": "Marks", "City": "Location"}, inplace=True)

# Drop a column
df.drop(columns=["Grade"], inplace=True)

# Drop a row
df.drop(index=0, inplace=True)
```

---

### 3.7 Handling Missing Data

Real-world data is almost always messy. Pandas makes it easy to handle missing values:

```python
df.isnull()             # Boolean mask — True where value is missing
df.isnull().sum()       # Count missing values per column
df.dropna()             # Remove all rows with any missing value
df.dropna(subset=["Score"])  # Remove rows where 'Score' is missing
df.fillna(0)            # Replace all missing values with 0
df["Score"].fillna(df["Score"].mean(), inplace=True)  # Fill with mean
df.ffill()              # Forward fill — use previous row's value
df.bfill()              # Backward fill — use next row's value
```

---

### 3.8 Data Cleaning

```python
# Remove duplicate rows
df.drop_duplicates()
df.drop_duplicates(subset=["Name"])  # Based on specific column

# Strip whitespace from string columns
df["Name"] = df["Name"].str.strip()

# Convert data types
df["Age"] = df["Age"].astype(int)
df["Score"] = pd.to_numeric(df["Score"], errors="coerce")

# Rename messy column names
df.columns = df.columns.str.lower().str.replace(" ", "_")
```

---

### 3.9 Sorting Data

```python
# Sort by a single column
df.sort_values("Score", ascending=False)  # Highest score first

# Sort by multiple columns
df.sort_values(["City", "Score"], ascending=[True, False])

# Sort by index
df.sort_index()
```

---

### 3.10 GroupBy — Aggregation Made Easy

`groupby` is one of the most powerful tools in pandas. It groups data by one or more columns and lets you apply aggregate functions to each group.

```python
# Average score by City
df.groupby("City")["Score"].mean()

# Multiple aggregations at once
df.groupby("City").agg(
    Avg_Score=("Score", "mean"),
    Max_Score=("Score", "max"),
    Count=("Name", "count")
)
```

> 💡 **Think of GroupBy like this:** "Split the data into groups, apply a function to each group, then combine the results." This is the classic **Split-Apply-Combine** pattern.

---

### 3.11 Merging and Joining DataFrames

Just like SQL JOINs, pandas allows you to combine DataFrames:

```python
df1 = pd.DataFrame({"ID": [1, 2, 3], "Name": ["Alice", "Bob", "Carol"]})
df2 = pd.DataFrame({"ID": [1, 2, 4], "Score": [85, 92, 78]})

# Inner join — only matching rows
pd.merge(df1, df2, on="ID", how="inner")

# Left join — all rows from df1
pd.merge(df1, df2, on="ID", how="left")

# Right join — all rows from df2
pd.merge(df1, df2, on="ID", how="right")

# Outer join — all rows from both
pd.merge(df1, df2, on="ID", how="outer")
```

---

### 3.12 Pivot Tables

Pivot tables help you summarize data by reorganizing it in a meaningful way:

```python
# Create a pivot table — average score by City and Grade
pivot = df.pivot_table(values="Score", index="City", columns="Grade", aggfunc="mean")
```

> 💡 If you've ever used Excel's pivot tables, this is the exact same concept — just in Python!

---

### 3.13 Apply and Map — Custom Transformations

```python
# Apply a function to every element in a column
df["Score_Scaled"] = df["Score"].apply(lambda x: x / 100)

# Apply a function across rows
df["Combined"] = df.apply(lambda row: f"{row['Name']} ({row['City']})", axis=1)

# Map values to new values
grade_map = {"Pass": 1, "Fail": 0}
df["Grade_Num"] = df["Grade"].map(grade_map)
```

---

### 3.14 String Operations

Pandas has a `.str` accessor for working with text data:

```python
df["Name"].str.upper()           # Convert to uppercase
df["Name"].str.lower()           # Convert to lowercase
df["Name"].str.len()             # Length of each string
df["Name"].str.contains("Ali")   # True/False if contains substring
df["Name"].str.replace("Alice", "Alicia")
df["Name"].str.split(" ")        # Split on space
df["City"].str.startswith("D")   # True if starts with "D"
```

---

### 3.15 DateTime Operations

Working with dates and time series is effortless in pandas:

```python
# Convert a column to datetime type
df["Date"] = pd.to_datetime(df["Date"])

# Extract date components
df["Year"]  = df["Date"].dt.year
df["Month"] = df["Date"].dt.month
df["Day"]   = df["Date"].dt.day
df["Weekday"] = df["Date"].dt.day_name()

# Filter by date
df[df["Date"] > "2024-01-01"]

# Resample time series data (e.g., monthly average)
df.set_index("Date").resample("M")["Score"].mean()
```

---

### 3.16 Window Functions

Rolling and expanding windows are used for time-series and trend analysis:

```python
# 3-period rolling average
df["Rolling_Avg"] = df["Score"].rolling(window=3).mean()

# Cumulative sum
df["Cumulative"] = df["Score"].cumsum()

# Expanding mean (mean of all values seen so far)
df["Expanding_Mean"] = df["Score"].expanding().mean()
```

---

### 3.17 Concatenating DataFrames

```python
# Stack DataFrames vertically (add more rows)
combined = pd.concat([df1, df2], axis=0, ignore_index=True)

# Stack DataFrames horizontally (add more columns)
combined = pd.concat([df1, df2], axis=1)
```

---

## 4. SQL vs Pandas — A Head-to-Head Comparison

Both SQL and pandas can manipulate tabular data. Here's a direct comparison of common operations:

### 4.1 Operation Mapping Table

| Operation | SQL | Pandas |
|---|---|---|
| View all data | `SELECT * FROM table` | `df` or `df.head()` |
| Select columns | `SELECT col1, col2 FROM table` | `df[["col1", "col2"]]` |
| Filter rows | `WHERE col > 10` | `df[df["col"] > 10]` |
| Sort data | `ORDER BY col DESC` | `df.sort_values("col", ascending=False)` |
| Count rows | `SELECT COUNT(*) FROM table` | `len(df)` or `df.shape[0]` |
| Group & aggregate | `GROUP BY col` | `df.groupby("col").agg(...)` |
| Join tables | `JOIN table2 ON id` | `pd.merge(df1, df2, on="id")` |
| Add a column | `ALTER TABLE ADD col` | `df["col"] = value` |
| Remove duplicates | `SELECT DISTINCT` | `df.drop_duplicates()` |
| Limit results | `LIMIT 10` | `df.head(10)` |
| Null check | `WHERE col IS NULL` | `df[df["col"].isnull()]` |
| String search | `WHERE col LIKE '%text%'` | `df[df["col"].str.contains("text")]` |

---

### 4.2 Side-by-Side Code Comparison

#### Filtering
```sql
-- SQL
SELECT * FROM employees WHERE salary > 50000 AND department = 'Engineering';
```
```python
# Pandas
df[(df["salary"] > 50000) & (df["department"] == "Engineering")]
```

#### Aggregation
```sql
-- SQL
SELECT department, AVG(salary), COUNT(*) FROM employees GROUP BY department;
```
```python
# Pandas
df.groupby("department").agg(avg_salary=("salary", "mean"), count=("salary", "count"))
```

#### Joining
```sql
-- SQL
SELECT e.name, d.dept_name
FROM employees e
INNER JOIN departments d ON e.dept_id = d.id;
```
```python
# Pandas
pd.merge(employees_df, departments_df, left_on="dept_id", right_on="id", how="inner")
```

---

## 5. What Pandas Can Do That SQL Cannot

This is where pandas truly shines. SQL is great at querying data in databases — but pandas goes far beyond that.

### 5.1 Custom Row-Level Logic with `apply()`
SQL can only apply built-in functions to rows. Pandas lets you apply **any Python function** to each row.
```python
def risk_score(row):
    score = 0
    if row["age"] > 60:
        score += 2
    if row["bmi"] > 30:
        score += 3
    if row["smoker"] == "yes":
        score += 5
    return score

df["risk"] = df.apply(risk_score, axis=1)
```
> In SQL, this would require complex `CASE WHEN` chains or stored procedures. In pandas, it's just Python!

---

### 5.2 Rich DateTime Analysis
Pandas has first-class support for time series — resampling, rolling windows, frequency conversion, etc.
```python
# Resample daily data to monthly averages
df.set_index("date").resample("M")["revenue"].mean()

# Calculate 7-day rolling average
df["7day_avg"] = df["revenue"].rolling(7).mean()
```
> SQL can do basic date filtering, but complex time-series operations like rolling averages require verbose, error-prone window functions.

---

### 5.3 Reshape Data with `melt()` and `pivot()`
Pandas can easily switch between **wide format** and **long format** — a common need in data analysis.
```python
# Wide to Long (unpivot)
pd.melt(df, id_vars=["Name"], value_vars=["Q1", "Q2", "Q3", "Q4"],
        var_name="Quarter", value_name="Sales")

# Long to Wide (pivot)
df.pivot(index="Name", columns="Quarter", values="Sales")
```

---

### 5.4 Machine Learning Integration
Pandas DataFrames integrate seamlessly with Python's ML ecosystem (scikit-learn, TensorFlow, XGBoost). SQL cannot directly feed into ML pipelines.
```python
from sklearn.linear_model import LinearRegression

X = df[["age", "experience"]]
y = df["salary"]

model = LinearRegression()
model.fit(X, y)
```

---

### 5.5 Data Visualization
Pandas has built-in plotting through matplotlib:
```python
df["Score"].plot(kind="hist", bins=10, title="Score Distribution")
df.groupby("City")["Score"].mean().plot(kind="bar", color="steelblue")
```
> SQL has no native visualization capabilities.

---

### 5.6 Multi-Step Chained Operations (Method Chaining)
Pandas supports chaining multiple transformations in a clean, readable pipeline:
```python
result = (
    df
    .dropna(subset=["Score"])
    .query("Age > 20")
    .assign(Grade=lambda x: x["Score"].apply(lambda s: "A" if s > 90 else "B"))
    .groupby("Grade")["Score"]
    .mean()
    .reset_index()
    .sort_values("Score", ascending=False)
)
```

---

### 5.7 Reading Diverse File Formats
Pandas can read from CSV, Excel, JSON, Parquet, HTML tables, SQL databases, clipboard, and more. SQL is locked to its database.
```python
pd.read_csv("file.csv")
pd.read_excel("file.xlsx")
pd.read_json("file.json")
pd.read_parquet("file.parquet")
pd.read_html("https://example.com/table")  # Scrape HTML tables!
```

---

## 6. Quick Reference Cheat Sheet

### NumPy Essentials
```
np.array()       → Create array
np.zeros/ones()  → Arrays of 0s or 1s
np.arange()      → Range of numbers
np.reshape()     → Change array shape
np.mean/sum/std() → Statistics
np.dot()         → Matrix multiplication
np.where()       → Conditional selection
```

### Pandas Essentials
```
pd.read_csv()         → Load data
df.head/tail()        → Preview data
df.info/describe()    → Explore structure
df[condition]         → Filter rows
df.groupby().agg()    → Aggregate data
pd.merge()            → Join DataFrames
df.fillna/dropna()    → Handle missing values
df.apply()            → Custom transformations
df.sort_values()      → Sort data
df.pivot_table()      → Summarize data
```

### SQL → Pandas Quick Map
```
SELECT *         → df
WHERE            → df[condition]
GROUP BY         → df.groupby()
ORDER BY         → df.sort_values()
JOIN             → pd.merge()
DISTINCT         → df.drop_duplicates()
LIMIT n          → df.head(n)
IS NULL          → df.isnull()
```

---

## Closing Thoughts

| | NumPy | Pandas | SQL |
|---|---|---|---|
| **Best for** | Numerical computation | Data wrangling & analysis | Database queries |
| **Data structure** | Array (ndarray) | DataFrame / Series | Table |
| **Visualization** | No | Yes (basic) | No |
| **ML Integration** | Yes | Yes | No |
| **File Support** | Limited | Extensive | Database only |
| **Learning Curve** | Medium | Medium | Low–Medium |

In practice, **NumPy, Pandas, and SQL are complementary** — not competing. A typical data scientist uses SQL to extract data from a database, pandas to clean and transform it, and NumPy for mathematical computations underneath it all.

---

*Happy Learning! 🚀 Practice each concept with a small dataset, and these tools will become second nature.*