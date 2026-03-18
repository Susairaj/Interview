# Comprehensive Guide to Pandas, NumPy, and SQL Comparison

## A Beginner-Friendly Educational Resource for Data Analysis

---

# SECTION 1: NumPy - The Foundation of Numerical Computing

## What is NumPy?

NumPy (Numerical Python) is the fundamental library for scientific computing in Python. It provides support for large, multi-dimensional arrays and matrices, along with a collection of mathematical functions to operate on these arrays efficiently. Think of NumPy as the building block upon which most data science libraries in Python are constructed.

---

## Core Concepts in NumPy

### The NumPy Array (ndarray)

The most important object in NumPy is the **ndarray** (n-dimensional array). Unlike Python lists, NumPy arrays are homogeneous (all elements must be the same type), which makes them significantly faster for numerical operations.

```python
import numpy as np

# Creating a simple array
my_array = np.array([1, 2, 3, 4, 5])
print(my_array)  # Output: [1 2 3 4 5]
```

---

## Array Creation Methods

### np.array()
This is the most basic way to create a NumPy array. You pass a Python list (or list of lists for multi-dimensional arrays), and NumPy converts it into an array.

```python
# 1D array
one_dimensional = np.array([1, 2, 3])

# 2D array (like a table with rows and columns)
two_dimensional = np.array([[1, 2, 3], [4, 5, 6]])
```

**Beginner Tip:** Think of a 1D array as a single row of data, and a 2D array as a spreadsheet with rows and columns.

---

### np.zeros()
Creates an array filled entirely with zeros. This is useful when you need to initialize an array before filling it with actual data.

```python
# Create an array of 5 zeros
zeros_array = np.zeros(5)
print(zeros_array)  # Output: [0. 0. 0. 0. 0.]

# Create a 3x4 matrix of zeros
zeros_matrix = np.zeros((3, 4))
```

**Use Case:** When you're building a game board, image placeholder, or need to initialize counters.

---

### np.ones()
Similar to zeros(), but fills the array with ones instead.

```python
ones_array = np.ones((2, 3))
# Output:
# [[1. 1. 1.]
#  [1. 1. 1.]]
```

**Use Case:** Creating masks, initializing weights in machine learning, or creating baseline arrays.

---

### np.arange()
Creates an array with evenly spaced values within a specified range. It works similarly to Python's built-in range() function but returns a NumPy array.

```python
# Numbers from 0 to 9
range_array = np.arange(10)
print(range_array)  # Output: [0 1 2 3 4 5 6 7 8 9]

# Numbers from 2 to 10, stepping by 2
step_array = np.arange(2, 11, 2)
print(step_array)  # Output: [2 4 6 8 10]
```

**Beginner Tip:** The syntax is np.arange(start, stop, step). The stop value is not included in the result.

---

### np.linspace()
Creates an array with a specified number of evenly spaced values between a start and end point. Unlike arange(), you specify how many numbers you want, not the step size.

```python
# 5 evenly spaced numbers between 0 and 1
linear_space = np.linspace(0, 1, 5)
print(linear_space)  # Output: [0.   0.25 0.5  0.75 1.  ]
```

**Use Case:** Creating axis values for plotting graphs, generating test data points.

---

### np.eye() and np.identity()
Creates an identity matrix (a square matrix with ones on the diagonal and zeros elsewhere).

```python
identity_matrix = np.eye(3)
# Output:
# [[1. 0. 0.]
#  [0. 1. 0.]
#  [0. 0. 1.]]
```

**Use Case:** Linear algebra operations, matrix transformations.

---

### np.random Module

This module provides various functions for generating random numbers.

#### np.random.rand()
Generates random numbers uniformly distributed between 0 and 1.

```python
# Single random number
random_num = np.random.rand()

# Array of 5 random numbers
random_array = np.random.rand(5)

# 3x3 matrix of random numbers
random_matrix = np.random.rand(3, 3)
```

#### np.random.randn()
Generates random numbers from a standard normal distribution (mean=0, standard deviation=1).

```python
normal_random = np.random.randn(1000)  # 1000 normally distributed numbers
```

#### np.random.randint()
Generates random integers within a specified range.

```python
# Random integer between 1 and 10
random_int = np.random.randint(1, 11)

# Array of 5 random integers between 1 and 100
random_ints = np.random.randint(1, 101, size=5)
```

#### np.random.choice()
Randomly selects elements from a given array.

```python
colors = np.array(['red', 'blue', 'green', 'yellow'])
random_color = np.random.choice(colors)
random_colors = np.random.choice(colors, size=3, replace=True)
```

#### np.random.shuffle()
Randomly shuffles an array in place (modifies the original array).

```python
deck = np.arange(52)
np.random.shuffle(deck)
```

#### np.random.seed()
Sets the random seed for reproducibility. When you set a seed, you'll get the same "random" numbers each time you run the code.

```python
np.random.seed(42)  # Now random operations will be reproducible
```

**Beginner Tip:** Always set a seed when you want others to be able to reproduce your results exactly.

---

## Array Attributes

### shape
Returns a tuple indicating the dimensions of the array.

```python
arr = np.array([[1, 2, 3], [4, 5, 6]])
print(arr.shape)  # Output: (2, 3) - 2 rows, 3 columns
```

### ndim
Returns the number of dimensions of the array.

```python
print(arr.ndim)  # Output: 2
```

### size
Returns the total number of elements in the array.

```python
print(arr.size)  # Output: 6
```

### dtype
Returns the data type of the array elements.

```python
print(arr.dtype)  # Output: int64 (or similar, depending on system)
```

---

## Array Manipulation Methods

### reshape()
Changes the shape of an array without changing its data. The total number of elements must remain the same.

```python
original = np.arange(12)  # [0, 1, 2, ..., 11]
reshaped = original.reshape(3, 4)  # 3 rows, 4 columns
# Also: original.reshape(4, 3), original.reshape(2, 6), etc.
```

**Beginner Tip:** The product of the new dimensions must equal the total number of elements. For 12 elements: 3×4=12, 4×3=12, 2×6=12 all work.

---

### flatten() and ravel()
Convert a multi-dimensional array into a one-dimensional array.

```python
matrix = np.array([[1, 2], [3, 4]])
flat = matrix.flatten()  # Returns a copy
raveled = matrix.ravel()  # Returns a view (shares memory with original)
# Both output: [1 2 3 4]
```

**Key Difference:** flatten() creates a new copy of the data, while ravel() creates a view. Modifying the raveled array might affect the original.

---

### transpose() or .T
Swaps rows and columns of a 2D array.

```python
matrix = np.array([[1, 2, 3], [4, 5, 6]])
transposed = matrix.T
# Output:
# [[1 4]
#  [2 5]
#  [3 6]]
```

---

### concatenate()
Joins arrays along an existing axis.

```python
arr1 = np.array([1, 2, 3])
arr2 = np.array([4, 5, 6])
combined = np.concatenate([arr1, arr2])
# Output: [1 2 3 4 5 6]

# For 2D arrays
matrix1 = np.array([[1, 2], [3, 4]])
matrix2 = np.array([[5, 6], [7, 8]])
vertical = np.concatenate([matrix1, matrix2], axis=0)  # Stack vertically
horizontal = np.concatenate([matrix1, matrix2], axis=1)  # Stack horizontally
```

---

### vstack() and hstack()
Convenient shortcuts for vertical and horizontal stacking.

```python
# Vertical stack (stack rows)
vstacked = np.vstack([arr1, arr2])

# Horizontal stack (stack columns)
hstacked = np.hstack([arr1, arr2])
```

---

### split(), vsplit(), hsplit()
Split arrays into multiple sub-arrays.

```python
arr = np.arange(12)
split_arr = np.split(arr, 3)  # Split into 3 equal parts
# Output: [array([0, 1, 2, 3]), array([4, 5, 6, 7]), array([8, 9, 10, 11])]
```

---

## Mathematical Operations

### Basic Arithmetic
NumPy allows element-wise arithmetic operations on arrays.

```python
a = np.array([1, 2, 3, 4])
b = np.array([5, 6, 7, 8])

print(a + b)   # [6, 8, 10, 12]
print(a - b)   # [-4, -4, -4, -4]
print(a * b)   # [5, 12, 21, 32]
print(a / b)   # [0.2, 0.333..., 0.428..., 0.5]
print(a ** 2)  # [1, 4, 9, 16]
```

**Beginner Tip:** Unlike Python lists, NumPy arrays perform operations element by element automatically.

---

### Universal Functions (ufuncs)

Universal functions are functions that operate element-wise on arrays.

#### np.sqrt()
Calculates the square root of each element.

```python
np.sqrt(np.array([1, 4, 9, 16]))  # [1., 2., 3., 4.]
```

#### np.exp()
Calculates e raised to the power of each element.

```python
np.exp(np.array([0, 1, 2]))  # [1., 2.718..., 7.389...]
```

#### np.log(), np.log10(), np.log2()
Calculate logarithms (natural, base-10, and base-2).

```python
np.log(np.array([1, np.e, np.e**2]))  # [0., 1., 2.]
```

#### np.sin(), np.cos(), np.tan()
Trigonometric functions.

```python
angles = np.array([0, np.pi/2, np.pi])
np.sin(angles)  # [0., 1., 0.]
```

#### np.abs()
Returns the absolute value of each element.

```python
np.abs(np.array([-1, -2, 3]))  # [1, 2, 3]
```

#### np.round(), np.floor(), np.ceil()
Rounding functions.

```python
arr = np.array([1.4, 2.6, 3.5])
np.round(arr)  # [1., 3., 4.]
np.floor(arr)  # [1., 2., 3.]
np.ceil(arr)   # [2., 3., 4.]
```

---

## Statistical Functions

### np.sum()
Calculates the sum of array elements.

```python
arr = np.array([[1, 2, 3], [4, 5, 6]])
np.sum(arr)         # 21 (all elements)
np.sum(arr, axis=0) # [5, 7, 9] (sum of each column)
np.sum(arr, axis=1) # [6, 15] (sum of each row)
```

**Beginner Tip:** axis=0 means "along rows" (result has one value per column), axis=1 means "along columns" (result has one value per row).

---

### np.mean()
Calculates the average of array elements.

```python
np.mean(arr)         # 3.5
np.mean(arr, axis=0) # [2.5, 3.5, 4.5]
np.mean(arr, axis=1) # [2., 5.]
```

---

### np.median()
Finds the middle value when data is sorted.

```python
np.median(np.array([1, 3, 5, 7, 9]))  # 5.0
```

---

### np.std() and np.var()
Calculate standard deviation and variance, measures of how spread out the data is.

```python
data = np.array([2, 4, 6, 8, 10])
np.std(data)  # Standard deviation
np.var(data)  # Variance (std squared)
```

---

### np.min() and np.max()
Find the minimum and maximum values.

```python
arr = np.array([3, 1, 4, 1, 5, 9, 2, 6])
np.min(arr)  # 1
np.max(arr)  # 9
```

---

### np.argmin() and np.argmax()
Find the index (position) of the minimum and maximum values.

```python
np.argmin(arr)  # 1 (index of first occurrence of 1)
np.argmax(arr)  # 5 (index of 9)
```

---

### np.cumsum() and np.cumprod()
Calculate cumulative sum and cumulative product.

```python
arr = np.array([1, 2, 3, 4])
np.cumsum(arr)   # [1, 3, 6, 10]
np.cumprod(arr)  # [1, 2, 6, 24]
```

---

### np.percentile() and np.quantile()
Calculate percentiles and quantiles of the data.

```python
data = np.arange(1, 101)  # 1 to 100
np.percentile(data, 50)   # 50.5 (median)
np.percentile(data, 25)   # 25.75 (25th percentile)
np.quantile(data, 0.25)   # Same as 25th percentile
```

---

## Indexing and Slicing

### Basic Indexing
Access elements using square brackets. Remember, indexing starts at 0.

```python
arr = np.array([10, 20, 30, 40, 50])
arr[0]   # 10 (first element)
arr[-1]  # 50 (last element)
arr[2]   # 30 (third element)
```

---

### Slicing
Extract a portion of an array using start:stop:step notation.

```python
arr = np.array([0, 1, 2, 3, 4, 5, 6, 7, 8, 9])
arr[2:5]    # [2, 3, 4]
arr[:5]     # [0, 1, 2, 3, 4]
arr[5:]     # [5, 6, 7, 8, 9]
arr[::2]    # [0, 2, 4, 6, 8] (every other element)
arr[::-1]   # [9, 8, 7, 6, 5, 4, 3, 2, 1, 0] (reversed)
```

---

### 2D Array Indexing
Access elements in matrices using [row, column] notation.

```python
matrix = np.array([[1, 2, 3],
                   [4, 5, 6],
                   [7, 8, 9]])

matrix[0, 0]     # 1 (first row, first column)
matrix[1, 2]     # 6 (second row, third column)
matrix[0, :]     # [1, 2, 3] (entire first row)
matrix[:, 1]     # [2, 5, 8] (entire second column)
matrix[0:2, 1:]  # [[2, 3], [5, 6]] (submatrix)
```

---

### Boolean Indexing
Select elements based on conditions.

```python
arr = np.array([1, 2, 3, 4, 5, 6, 7, 8, 9, 10])

# Get all elements greater than 5
arr[arr > 5]  # [6, 7, 8, 9, 10]

# Get all even numbers
arr[arr % 2 == 0]  # [2, 4, 6, 8, 10]

# Multiple conditions (use & for AND, | for OR)
arr[(arr > 3) & (arr < 8)]  # [4, 5, 6, 7]
```

**Beginner Tip:** Boolean indexing is extremely powerful for filtering data. The condition creates a True/False array, and only True positions are selected.

---

### Fancy Indexing
Use arrays of indices to access multiple elements at once.

```python
arr = np.array([10, 20, 30, 40, 50])
indices = [0, 2, 4]
arr[indices]  # [10, 30, 50]
```

---

## Linear Algebra Functions

### np.dot()
Calculates the dot product of two arrays.

```python
a = np.array([1, 2, 3])
b = np.array([4, 5, 6])
np.dot(a, b)  # 32 (1*4 + 2*5 + 3*6)
```

---

### Matrix Multiplication with @
Python 3.5+ allows using @ for matrix multiplication.

```python
matrix1 = np.array([[1, 2], [3, 4]])
matrix2 = np.array([[5, 6], [7, 8]])
result = matrix1 @ matrix2
```

---

### np.linalg.inv()
Calculates the inverse of a matrix.

```python
matrix = np.array([[1, 2], [3, 4]])
inverse = np.linalg.inv(matrix)
```

---

### np.linalg.det()
Calculates the determinant of a matrix.

```python
determinant = np.linalg.det(matrix)
```

---

### np.linalg.eig()
Calculates eigenvalues and eigenvectors.

```python
eigenvalues, eigenvectors = np.linalg.eig(matrix)
```

---

## Comparison and Logical Operations

### np.where()
Returns indices where a condition is true, or can be used for conditional element selection.

```python
arr = np.array([1, 2, 3, 4, 5])

# Find indices where condition is true
indices = np.where(arr > 3)  # (array([3, 4]),)

# Replace values based on condition
result = np.where(arr > 3, 'big', 'small')
# ['small', 'small', 'small', 'big', 'big']
```

---

### np.any() and np.all()
Check if any or all elements satisfy a condition.

```python
arr = np.array([1, 2, 3, 4, 5])
np.any(arr > 4)   # True (at least one element > 4)
np.all(arr > 0)   # True (all elements > 0)
np.all(arr > 3)   # False (not all elements > 3)
```

---

### np.unique()
Returns sorted unique elements.

```python
arr = np.array([1, 2, 2, 3, 3, 3, 4])
np.unique(arr)  # [1, 2, 3, 4]

# Also get counts
values, counts = np.unique(arr, return_counts=True)
# values: [1, 2, 3, 4], counts: [1, 2, 3, 1]
```

---

## Sorting

### np.sort()
Returns a sorted copy of the array.

```python
arr = np.array([3, 1, 4, 1, 5, 9, 2, 6])
sorted_arr = np.sort(arr)  # [1, 1, 2, 3, 4, 5, 6, 9]
```

---

### np.argsort()
Returns the indices that would sort the array.

```python
indices = np.argsort(arr)  # [1, 3, 6, 0, 2, 4, 7, 5]
arr[indices]  # Same as np.sort(arr)
```

---

## Broadcasting

Broadcasting is NumPy's way of handling operations between arrays of different shapes.

```python
# Scalar broadcasting
arr = np.array([1, 2, 3, 4])
arr + 10  # [11, 12, 13, 14]

# Array broadcasting
matrix = np.array([[1, 2, 3], [4, 5, 6]])
row = np.array([10, 20, 30])
matrix + row  # Each row gets [10, 20, 30] added
# [[11, 22, 33],
#  [14, 25, 36]]
```

**Beginner Tip:** Broadcasting allows you to perform operations without explicitly copying data, making your code both cleaner and faster.

---

# SECTION 2: Pandas - The Data Analysis Powerhouse

## What is Pandas?

Pandas is a powerful data manipulation and analysis library built on top of NumPy. It provides two main data structures: **Series** (one-dimensional) and **DataFrame** (two-dimensional). Pandas excels at handling tabular data, similar to spreadsheets or SQL tables, but with the full power of Python programming.

---

## Core Data Structures

### Series

A Series is a one-dimensional labeled array capable of holding any data type. Think of it as a single column of data with labels (called an index).

```python
import pandas as pd

# Creating a Series from a list
fruits_series = pd.Series([10, 20, 30, 40], index=['apples', 'bananas', 'oranges', 'grapes'])
print(fruits_series)
# apples     10
# bananas    20
# oranges    30
# grapes     40
# dtype: int64

# Accessing elements
fruits_series['apples']  # 10
fruits_series[0]         # 10 (by position)
```

---

### DataFrame

A DataFrame is a two-dimensional labeled data structure with columns of potentially different types. Think of it as a spreadsheet or SQL table.

```python
# Creating a DataFrame from a dictionary
data = {
    'Name': ['Alice', 'Bob', 'Charlie', 'Diana'],
    'Age': [25, 30, 35, 28],
    'City': ['New York', 'Los Angeles', 'Chicago', 'Houston'],
    'Salary': [50000, 60000, 75000, 55000]
}
df = pd.DataFrame(data)
print(df)
#       Name  Age         City  Salary
# 0    Alice   25     New York   50000
# 1      Bob   30  Los Angeles   60000
# 2  Charlie   35      Chicago   75000
# 3    Diana   28      Houston   55000
```

---

## Reading and Writing Data

### pd.read_csv()
Reads data from a CSV (Comma-Separated Values) file into a DataFrame.

```python
# Basic usage
df = pd.read_csv('data.csv')

# With options
df = pd.read_csv('data.csv',
                 sep=',',           # Delimiter
                 header=0,          # Row number for column names
                 index_col=0,       # Column to use as index
                 usecols=['A', 'B'], # Only read specific columns
                 nrows=100,         # Read only first 100 rows
                 skiprows=5,        # Skip first 5 rows
                 na_values=['NA', 'missing'],  # Values to treat as NaN
                 parse_dates=['date_column'],  # Parse as dates
                 encoding='utf-8')
```

---

### pd.read_excel()
Reads data from an Excel file.

```python
df = pd.read_excel('data.xlsx', sheet_name='Sheet1')
```

---

### pd.read_json()
Reads data from a JSON file.

```python
df = pd.read_json('data.json')
```

---

### pd.read_sql()
Reads data from a SQL database.

```python
import sqlite3
conn = sqlite3.connect('database.db')
df = pd.read_sql('SELECT * FROM table_name', conn)
```

---

### to_csv(), to_excel(), to_json()
Write DataFrame to various file formats.

```python
df.to_csv('output.csv', index=False)
df.to_excel('output.xlsx', index=False)
df.to_json('output.json')
```

---

## DataFrame Attributes and Basic Information

### shape
Returns a tuple of (rows, columns).

```python
df.shape  # (4, 4) for our example DataFrame
```

---

### columns
Returns the column names.

```python
df.columns  # Index(['Name', 'Age', 'City', 'Salary'], dtype='object')
```

---

### index
Returns the row labels.

```python
df.index  # RangeIndex(start=0, stop=4, step=1)
```

---

### dtypes
Returns the data type of each column.

```python
df.dtypes
# Name      object
# Age        int64
# City      object
# Salary     int64
# dtype: object
```

---

### info()
Provides a concise summary of the DataFrame including data types and memory usage.

```python
df.info()
# <class 'pandas.core.frame.DataFrame'>
# RangeIndex: 4 entries, 0 to 3
# Data columns (total 4 columns):
# ...
```

---

### describe()
Generates descriptive statistics for numerical columns.

```python
df.describe()
#              Age        Salary
# count   4.000000      4.000000
# mean   29.500000  60000.000000
# std     4.203173  10801.234497
# min    25.000000  50000.000000
# 25%    27.250000  53750.000000
# 50%    29.000000  57500.000000
# 75%    31.250000  63750.000000
# max    35.000000  75000.000000
```

---

### head() and tail()
View the first or last n rows (default is 5).

```python
df.head(3)   # First 3 rows
df.tail(2)   # Last 2 rows
```

---

### sample()
Returns a random sample of rows.

```python
df.sample(2)        # 2 random rows
df.sample(frac=0.5) # 50% of rows
```

---

## Selecting Data

### Selecting Columns

```python
# Single column (returns Series)
df['Name']

# Single column (alternative method)
df.Name

# Multiple columns (returns DataFrame)
df[['Name', 'Age']]
```

---

### loc[] - Label-based Selection
Select data by row and column labels.

```python
# Single value
df.loc[0, 'Name']  # 'Alice'

# Single row (returns Series)
df.loc[0]

# Multiple rows
df.loc[0:2]  # Rows with labels 0, 1, 2 (inclusive!)

# Specific rows and columns
df.loc[0:2, ['Name', 'Salary']]

# All rows, specific columns
df.loc[:, 'Age':'Salary']

# With boolean condition
df.loc[df['Age'] > 28]
```

**Beginner Tip:** With loc[], the end value in slicing is INCLUSIVE, unlike regular Python slicing.

---

### iloc[] - Position-based Selection
Select data by integer position (like array indexing).

```python
# Single value
df.iloc[0, 0]  # 'Alice'

# Single row
df.iloc[0]

# Multiple rows (exclusive end)
df.iloc[0:2]  # Rows at positions 0 and 1 only

# Specific rows and columns by position
df.iloc[0:2, [0, 3]]

# Last row
df.iloc[-1]
```

**Beginner Tip:** iloc[] uses standard Python indexing where the end is EXCLUSIVE.

---

### Boolean Indexing (Filtering)

```python
# Single condition
df[df['Age'] > 28]

# Multiple conditions (AND)
df[(df['Age'] > 25) & (df['Salary'] > 55000)]

# Multiple conditions (OR)
df[(df['City'] == 'New York') | (df['City'] == 'Chicago')]

# Using isin() for multiple values
df[df['City'].isin(['New York', 'Chicago'])]

# Negation with ~
df[~df['City'].isin(['New York', 'Chicago'])]
```

---

### query() Method
An alternative way to filter using a string expression.

```python
df.query('Age > 28')
df.query('Age > 25 and Salary > 55000')
df.query('City in ["New York", "Chicago"]')

# Using variables
min_age = 28
df.query('Age > @min_age')
```

---

## Modifying Data

### Adding New Columns

```python
# Direct assignment
df['Bonus'] = df['Salary'] * 0.1

# Using assign() (creates a copy)
df_new = df.assign(
    Bonus=df['Salary'] * 0.1,
    Total=df['Salary'] + df['Salary'] * 0.1
)

# Based on conditions
df['Senior'] = df['Age'] >= 30
```

---

### Modifying Existing Values

```python
# Change specific values
df.loc[0, 'Salary'] = 52000

# Change values based on condition
df.loc[df['Age'] > 30, 'Category'] = 'Senior'

# Replace values
df['City'] = df['City'].replace('New York', 'NYC')
df['City'] = df['City'].replace({'New York': 'NYC', 'Los Angeles': 'LA'})
```

---

### Renaming Columns

```python
# Rename specific columns
df = df.rename(columns={'Name': 'Employee_Name', 'City': 'Location'})

# Rename all columns
df.columns = ['emp_name', 'emp_age', 'emp_city', 'emp_salary']

# Apply function to column names
df.columns = df.columns.str.lower()
df.columns = df.columns.str.replace(' ', '_')
```

---

### Dropping Columns and Rows

```python
# Drop columns
df_dropped = df.drop(columns=['Bonus'])
df_dropped = df.drop(['Bonus', 'Senior'], axis=1)

# Drop rows by index
df_dropped = df.drop([0, 2])
df_dropped = df.drop(index=[0, 2])

# Drop in place (modifies original)
df.drop(columns=['Bonus'], inplace=True)
```

---

### insert()
Insert a column at a specific position.

```python
df.insert(1, 'ID', [101, 102, 103, 104])  # Insert 'ID' as second column
```

---

## Handling Missing Data

### Detecting Missing Values

```python
# Check for missing values
df.isna()      # Returns DataFrame of True/False
df.isnull()    # Same as isna()

# Check for non-missing values
df.notna()

# Count missing values per column
df.isna().sum()

# Total missing values
df.isna().sum().sum()

# Percentage of missing values
df.isna().mean() * 100
```

---

### fillna()
Fill missing values with a specified value or method.

```python
# Fill with a specific value
df['Age'] = df['Age'].fillna(0)
df = df.fillna(0)

# Fill with mean, median, or mode
df['Age'] = df['Age'].fillna(df['Age'].mean())
df['City'] = df['City'].fillna(df['City'].mode()[0])

# Forward fill (use previous valid value)
df = df.fillna(method='ffill')

# Backward fill (use next valid value)
df = df.fillna(method='bfill')

# Fill different columns with different values
df = df.fillna({'Age': 0, 'City': 'Unknown', 'Salary': df['Salary'].median()})
```

---

### dropna()
Remove rows or columns with missing values.

```python
# Drop rows with any missing values
df_clean = df.dropna()

# Drop rows only if all values are missing
df_clean = df.dropna(how='all')

# Drop rows with missing values in specific columns
df_clean = df.dropna(subset=['Age', 'Salary'])

# Drop columns with missing values
df_clean = df.dropna(axis=1)

# Keep rows with at least n non-null values
df_clean = df.dropna(thresh=3)
```

---

### interpolate()
Fill missing values using interpolation.

```python
# Linear interpolation
df['Value'] = df['Value'].interpolate()

# Time-based interpolation
df['Value'] = df['Value'].interpolate(method='time')
```

---

## Data Type Conversion

### astype()
Convert column to a different data type.

```python
# Convert to integer
df['Age'] = df['Age'].astype(int)

# Convert to string
df['ID'] = df['ID'].astype(str)

# Convert to category (memory efficient for repeated values)
df['City'] = df['City'].astype('category')

# Multiple conversions
df = df.astype({'Age': int, 'Salary': float})
```

---

### pd.to_numeric()
Convert to numeric type with error handling.

```python
df['Value'] = pd.to_numeric(df['Value'], errors='coerce')  # Invalid values become NaN
df['Value'] = pd.to_numeric(df['Value'], errors='ignore')  # Keep original if invalid
```

---

### pd.to_datetime()
Convert to datetime type.

```python
df['Date'] = pd.to_datetime(df['Date'])
df['Date'] = pd.to_datetime(df['Date'], format='%Y-%m-%d')
df['Date'] = pd.to_datetime(df['Date'], errors='coerce')
```

---

## Sorting

### sort_values()
Sort by column values.

```python
# Sort by one column
df_sorted = df.sort_values('Age')
df_sorted = df.sort_values('Age', ascending=False)

# Sort by multiple columns
df_sorted = df.sort_values(['City', 'Age'], ascending=[True, False])

# Sort in place
df.sort_values('Age', inplace=True)
```

---

### sort_index()
Sort by index labels.

```python
df_sorted = df.sort_index()
df_sorted = df.sort_index(ascending=False)
```

---

### nlargest() and nsmallest()
Get the n largest or smallest values.

```python
df.nlargest(3, 'Salary')   # Top 3 salaries
df.nsmallest(2, 'Age')     # 2 youngest employees
```

---

## Grouping and Aggregation

### groupby()
The groupby method is one of pandas' most powerful features. It splits data into groups based on criteria, applies a function to each group, and combines results.

```python
# Basic groupby
grouped = df.groupby('City')

# Apply aggregation function
df.groupby('City')['Salary'].mean()
df.groupby('City')['Salary'].sum()
df.groupby('City')['Age'].max()

# Multiple aggregations
df.groupby('City')['Salary'].agg(['mean', 'min', 'max', 'count'])

# Different aggregations for different columns
df.groupby('City').agg({
    'Salary': ['mean', 'sum'],
    'Age': ['min', 'max']
})

# Group by multiple columns
df.groupby(['City', 'Department'])['Salary'].mean()

# Reset index after groupby
result = df.groupby('City')['Salary'].mean().reset_index()
```

**Beginner Tip:** Think of groupby as "for each unique value in this column, do something with the other columns."

---

### Named Aggregation
A cleaner way to specify aggregations with custom column names.

```python
df.groupby('City').agg(
    avg_salary=('Salary', 'mean'),
    total_salary=('Salary', 'sum'),
    employee_count=('Name', 'count'),
    oldest_employee=('Age', 'max')
)
```

---

### transform()
Apply a function to each group and return results with the same shape as the input.

```python
# Add column with group mean
df['City_Avg_Salary'] = df.groupby('City')['Salary'].transform('mean')

# Normalize within groups
df['Salary_Normalized'] = df.groupby('City')['Salary'].transform(
    lambda x: (x - x.mean()) / x.std()
)
```

---

### filter()
Filter groups based on a condition.

```python
# Keep only cities with more than 2 employees
df.groupby('City').filter(lambda x: len(x) > 2)

# Keep only cities where average salary > 60000
df.groupby('City').filter(lambda x: x['Salary'].mean() > 60000)
```

---

### apply()
Apply a custom function to each group.

```python
def summarize(group):
    return pd.Series({
        'count': len(group),
        'salary_range': group['Salary'].max() - group['Salary'].min()
    })

df.groupby('City').apply(summarize)
```

---

## Merging and Joining

### merge()
Combine DataFrames based on common columns (like SQL JOIN).

```python
# Sample DataFrames
df1 = pd.DataFrame({
    'ID': [1, 2, 3, 4],
    'Name': ['Alice', 'Bob', 'Charlie', 'Diana']
})

df2 = pd.DataFrame({
    'ID': [1, 2, 3, 5],
    'Salary': [50000, 60000, 75000, 45000]
})

# Inner join (default) - only matching rows
merged = pd.merge(df1, df2, on='ID')

# Left join - all rows from left, matching from right
merged = pd.merge(df1, df2, on='ID', how='left')

# Right join - all rows from right, matching from left
merged = pd.merge(df1, df2, on='ID', how='right')

# Outer join - all rows from both
merged = pd.merge(df1, df2, on='ID', how='outer')

# Different column names
merged = pd.merge(df1, df2, left_on='ID', right_on='EmployeeID')

# Multiple keys
merged = pd.merge(df1, df2, on=['ID', 'Year'])
```

**Beginner Tip:** 
- **Inner join**: Only rows that exist in BOTH tables
- **Left join**: All rows from left table, matching rows from right (NaN if no match)
- **Right join**: All rows from right table, matching rows from left
- **Outer join**: All rows from both tables

---

### join()
Join DataFrames on their indices.

```python
df1 = df1.set_index('ID')
df2 = df2.set_index('ID')
joined = df1.join(df2, how='left')
```

---

### concat()
Concatenate DataFrames along an axis.

```python
# Stack vertically (add more rows)
combined = pd.concat([df1, df2], axis=0, ignore_index=True)

# Stack horizontally (add more columns)
combined = pd.concat([df1, df2], axis=1)

# With keys to identify source
combined = pd.concat([df1, df2], keys=['first', 'second'])
```

---

## Pivot Tables and Reshaping

### pivot_table()
Create a spreadsheet-style pivot table.

```python
# Sample data
sales = pd.DataFrame({
    'Date': ['2023-01-01', '2023-01-01', '2023-01-02', '2023-01-02'],
    'Product': ['A', 'B', 'A', 'B'],
    'Region': ['East', 'East', 'West', 'West'],
    'Sales': [100, 150, 200, 120]
})

# Basic pivot table
pivot = pd.pivot_table(sales, values='Sales', index='Product', columns='Region')

# With aggregation function
pivot = pd.pivot_table(sales, values='Sales', index='Product', columns='Region', aggfunc='sum')

# Multiple values and aggregations
pivot = pd.pivot_table(sales, 
                       values='Sales', 
                       index='Product', 
                       columns='Region',
                       aggfunc=['sum', 'mean', 'count'],
                       margins=True)  # Add row/column totals
```

---

### melt()
Unpivot a DataFrame from wide to long format.

```python
# Wide format
wide_df = pd.DataFrame({
    'Name': ['Alice', 'Bob'],
    'Math': [90, 85],
    'Science': [88, 92],
    'English': [95, 80]
})

# Convert to long format
long_df = pd.melt(wide_df, id_vars=['Name'], var_name='Subject', value_name='Score')
#     Name  Subject  Score
# 0  Alice     Math     90
# 1    Bob     Math     85
# 2  Alice  Science     88
# ...
```

---

### stack() and unstack()
Reshape by moving columns to/from row index.

```python
# stack() - columns become index levels
stacked = df.stack()

# unstack() - index levels become columns
unstacked = df.unstack()
```

---

### crosstab()
Compute a cross-tabulation of two or more factors.

```python
pd.crosstab(df['City'], df['Department'])
pd.crosstab(df['City'], df['Department'], values=df['Salary'], aggfunc='mean')
```

---

## String Methods

Pandas provides string methods accessible through the `.str` accessor.

### Common String Methods

```python
# Sample data
df['Name'] = pd.Series(['ALICE', 'bob', 'Charlie', 'diana smith'])

# Case conversion
df['Name'].str.lower()      # all lowercase
df['Name'].str.upper()      # ALL UPPERCASE
df['Name'].str.title()      # Title Case
df['Name'].str.capitalize() # Capitalize first letter

# String testing
df['Name'].str.contains('a', case=False)  # Contains 'a'?
df['Name'].str.startswith('A')
df['Name'].str.endswith('e')
df['Name'].str.isdigit()
df['Name'].str.isalpha()

# String manipulation
df['Name'].str.strip()       # Remove leading/trailing whitespace
df['Name'].str.replace('a', 'X')
df['Name'].str.split(' ')    # Split into list

# String extraction
df['Name'].str.len()         # Length of each string
df['Name'].str[:3]           # First 3 characters
df['Name'].str.extract(r'(\w+)')  # Extract with regex

# Get specific parts
df['Full_Name'].str.split(' ', expand=True)  # Split into columns
df['Full_Name'].str.get(0)   # First element after split
```

---

## DateTime Methods

### Creating DateTime

```python
# Convert to datetime
df['Date'] = pd.to_datetime(df['Date'])

# Create datetime index
date_range = pd.date_range(start='2023-01-01', end='2023-12-31', freq='D')
date_range = pd.date_range(start='2023-01-01', periods=12, freq='M')
```

---

### DateTime Accessors

```python
# Extract components
df['Date'].dt.year
df['Date'].dt.month
df['Date'].dt.day
df['Date'].dt.hour
df['Date'].dt.minute
df['Date'].dt.second
df['Date'].dt.dayofweek    # Monday=0, Sunday=6
df['Date'].dt.dayofyear
df['Date'].dt.week         # Week number
df['Date'].dt.quarter
df['Date'].dt.is_month_end
df['Date'].dt.is_month_start

# String formatting
df['Date'].dt.strftime('%Y-%m-%d')
df['Date'].dt.strftime('%B %d, %Y')

# Date calculations
df['Date'] + pd.Timedelta(days=7)
df['Date'] - df['Start_Date']  # Returns timedelta
```

---

### Resampling Time Series

```python
# Set datetime as index
df = df.set_index('Date')

# Resample to different frequencies
df.resample('W').sum()     # Weekly sum
df.resample('M').mean()    # Monthly mean
df.resample('Q').count()   # Quarterly count
df.resample('Y').max()     # Yearly max
```

---

## Apply and Map Functions

### apply()
Apply a function along an axis of the DataFrame.

```python
# Apply to each column
df.apply(np.sum)
df.apply(lambda x: x.max() - x.min())

# Apply to each row
df.apply(lambda row: row['Salary'] / row['Age'], axis=1)

# Apply to a single column (Series)
df['Salary'].apply(lambda x: x * 1.1)
df['Name'].apply(str.upper)
```

---

### map()
Map values of a Series using a dictionary or function.

```python
# Map using dictionary
mapping = {'New York': 'NY', 'Los Angeles': 'LA', 'Chicago': 'CHI'}
df['City_Abbr'] = df['City'].map(mapping)

# Map using function
df['Salary_Category'] = df['Salary'].map(lambda x: 'High' if x > 60000 else 'Low')
```

---

### applymap()
Apply a function element-wise to the entire DataFrame.

```python
df_numeric = df[['Age', 'Salary']]
df_rounded = df_numeric.applymap(lambda x: round(x, 2))
```

---

### replace()
Replace values in a DataFrame.

```python
# Single replacement
df['City'] = df['City'].replace('New York', 'NYC')

# Multiple replacements
df['City'] = df['City'].replace({'New York': 'NYC', 'Los Angeles': 'LA'})

# Using regex
df['Name'] = df['Name'].replace(r'\d+', '', regex=True)
```

---

## Window Functions

### Rolling Windows

```python
# Rolling mean (moving average)
df['Rolling_Mean'] = df['Sales'].rolling(window=7).mean()

# Rolling sum
df['Rolling_Sum'] = df['Sales'].rolling(window=7).sum()

# Rolling standard deviation
df['Rolling_Std'] = df['Sales'].rolling(window=7).std()

# Min periods (allow partial windows)
df['Rolling_Mean'] = df['Sales'].rolling(window=7, min_periods=1).mean()
```

---

### Expanding Windows

```python
# Expanding mean (cumulative mean)
df['Expanding_Mean'] = df['Sales'].expanding().mean()

# Expanding sum (same as cumsum)
df['Expanding_Sum'] = df['Sales'].expanding().sum()
```

---

### Shift and Diff

```python
# Shift values
df['Previous_Sales'] = df['Sales'].shift(1)   # Previous row
df['Next_Sales'] = df['Sales'].shift(-1)      # Next row

# Difference from previous value
df['Sales_Change'] = df['Sales'].diff()

# Percentage change
df['Sales_Pct_Change'] = df['Sales'].pct_change()
```

---

### Rank

```python
# Rank values
df['Salary_Rank'] = df['Salary'].rank()
df['Salary_Rank'] = df['Salary'].rank(ascending=False)
df['Salary_Rank'] = df['Salary'].rank(method='dense')
```

---

## Working with Duplicates

### Finding Duplicates

```python
# Find duplicate rows
df.duplicated()                    # Returns boolean Series
df.duplicated(keep='first')        # Mark all except first as True
df.duplicated(keep='last')         # Mark all except last as True
df.duplicated(keep=False)          # Mark all duplicates as True

# Check specific columns
df.duplicated(subset=['Name', 'City'])

# Get duplicate rows
df[df.duplicated()]
```

---

### Removing Duplicates

```python
# Remove duplicates
df_unique = df.drop_duplicates()
df_unique = df.drop_duplicates(keep='first')  # Keep first occurrence
df_unique = df.drop_duplicates(keep='last')   # Keep last occurrence
df_unique = df.drop_duplicates(keep=False)    # Remove all duplicates

# Based on specific columns
df_unique = df.drop_duplicates(subset=['Name'])

# In place
df.drop_duplicates(inplace=True)
```

---

## Statistical Methods

### Basic Statistics

```python
df['Salary'].mean()      # Average
df['Salary'].median()    # Middle value
df['Salary'].mode()      # Most common value(s)
df['Salary'].std()       # Standard deviation
df['Salary'].var()       # Variance
df['Salary'].min()       # Minimum
df['Salary'].max()       # Maximum
df['Salary'].sum()       # Sum
df['Salary'].count()     # Count non-null values

# Multiple statistics
df['Salary'].describe()
```

---

### Correlation and Covariance

```python
# Correlation between two columns
df['Age'].corr(df['Salary'])

# Correlation matrix
df.corr()

# Covariance
df['Age'].cov(df['Salary'])
df.cov()
```

---

### Value Counts

```python
# Count unique values
df['City'].value_counts()
df['City'].value_counts(normalize=True)  # Percentages
df['City'].value_counts(ascending=True)
df['City'].value_counts(dropna=False)    # Include NaN
```

---

### Unique Values

```python
df['City'].unique()      # Array of unique values
df['City'].nunique()     # Count of unique values
```

---

## Binning and Discretization

### cut()
Bin values into discrete intervals.

```python
# Create age groups
df['Age_Group'] = pd.cut(df['Age'], bins=[0, 25, 35, 50, 100], 
                          labels=['Young', 'Adult', 'Middle', 'Senior'])

# Equal-width bins
df['Salary_Bin'] = pd.cut(df['Salary'], bins=5)
```

---

### qcut()
Bin values into quantile-based intervals (equal-size bins).

```python
# Create quartiles
df['Salary_Quartile'] = pd.qcut(df['Salary'], q=4, labels=['Q1', 'Q2', 'Q3', 'Q4'])

# Percentiles
df['Salary_Percentile'] = pd.qcut(df['Salary'], q=10)
```

---

## MultiIndex (Hierarchical Indexing)

### Creating MultiIndex

```python
# From tuples
arrays = [['A', 'A', 'B', 'B'], [1, 2, 1, 2]]
tuples = list(zip(*arrays))
index = pd.MultiIndex.from_tuples(tuples, names=['Letter', 'Number'])
df = pd.DataFrame({'Value': [10, 20, 30, 40]}, index=index)

# From set_index
df = df.set_index(['City', 'Department'])

# From groupby
grouped = df.groupby(['City', 'Department'])['Salary'].mean()
```

---

### Accessing MultiIndex Data

```python
# Access first level
df.loc['New York']

# Access multiple levels
df.loc[('New York', 'Sales')]

# Cross-section
df.xs('Sales', level='Department')

# Reset to regular index
df.reset_index()
```

---

## Memory Optimization

### Checking Memory Usage

```python
df.info(memory_usage='deep')
df.memory_usage(deep=True)
```

---

### Optimizing Data Types

```python
# Convert to category
df['City'] = df['City'].astype('category')

# Use smaller integer types
df['Age'] = df['Age'].astype('int8')  # If values fit in int8

# Use sparse data for many zeros
df['Sparse_Col'] = pd.arrays.SparseArray(df['Col'])
```

---

# SECTION 3: SQL vs Pandas Comparison

## Understanding the Relationship

SQL (Structured Query Language) and pandas serve similar purposes—both are tools for querying, transforming, and analyzing data. However, they operate in different contexts and have different strengths. SQL is a language designed for relational databases, while pandas is a Python library that operates on in-memory data structures.

---

## Side-by-Side Comparison of Common Operations

### Selecting Data

**SQL:**
```sql
-- Select all columns
SELECT * FROM employees;

-- Select specific columns
SELECT name, age, salary FROM employees;
```

**Pandas:**
```python
# Select all columns
df

# Select specific columns
df[['name', 'age', 'salary']]
```

---

### Filtering Rows (WHERE clause)

**SQL:**
```sql
SELECT * FROM employees WHERE age > 30;

SELECT * FROM employees 
WHERE age > 30 AND salary > 50000;

SELECT * FROM employees 
WHERE city IN ('New York', 'Chicago');
```

**Pandas:**
```python
df[df['age'] > 30]

df[(df['age'] > 30) & (df['salary'] > 50000)]

df[df['city'].isin(['New York', 'Chicago'])]
```

---

### Sorting (ORDER BY)

**SQL:**
```sql
SELECT * FROM employees ORDER BY salary DESC;

SELECT * FROM employees ORDER BY city ASC, salary DESC;
```

**Pandas:**
```python
df.sort_values('salary', ascending=False)

df.sort_values(['city', 'salary'], ascending=[True, False])
```

---

### Aggregation (GROUP BY)

**SQL:**
```sql
SELECT city, AVG(salary) as avg_salary
FROM employees
GROUP BY city;

SELECT city, COUNT(*) as count, AVG(salary), MAX(age)
FROM employees
GROUP BY city;
```

**Pandas:**
```python
df.groupby('city')['salary'].mean()

df.groupby('city').agg({
    'salary': ['count', 'mean'],
    'age': 'max'
})
```

---

### Joins

**SQL:**
```sql
-- Inner Join
SELECT * FROM employees e
INNER JOIN departments d ON e.dept_id = d.id;

-- Left Join
SELECT * FROM employees e
LEFT JOIN departments d ON e.dept_id = d.id;
```

**Pandas:**
```python
# Inner Join
pd.merge(employees, departments, left_on='dept_id', right_on='id')

# Left Join
pd.merge(employees, departments, left_on='dept_id', right_on='id', how='left')
```

---

### Limiting Results

**SQL:**
```sql
SELECT * FROM employees LIMIT 10;
SELECT * FROM employees LIMIT 10 OFFSET 20;
```

**Pandas:**
```python
df.head(10)
df.iloc[20:30]
```

---

### Distinct Values

**SQL:**
```sql
SELECT DISTINCT city FROM employees;
SELECT COUNT(DISTINCT city) FROM employees;
```

**Pandas:**
```python
df['city'].unique()
df['city'].nunique()
```

---

### Adding Calculated Columns

**SQL:**
```sql
SELECT *, salary * 12 as annual_salary FROM employees;

SELECT *, 
    CASE 
        WHEN age > 30 THEN 'Senior'
        ELSE 'Junior'
    END as category
FROM employees;
```

**Pandas:**
```python
df['annual_salary'] = df['salary'] * 12

df['category'] = df['age'].apply(lambda x: 'Senior' if x > 30 else 'Junior')
# or
df['category'] = np.where(df['age'] > 30, 'Senior', 'Junior')
```

---

### Handling NULL/NaN Values

**SQL:**
```sql
SELECT * FROM employees WHERE salary IS NULL;
SELECT * FROM employees WHERE salary IS NOT NULL;
SELECT COALESCE(salary, 0) FROM employees;
```

**Pandas:**
```python
df[df['salary'].isna()]
df[df['salary'].notna()]
df['salary'].fillna(0)
```

---

### String Operations

**SQL:**
```sql
SELECT * FROM employees WHERE name LIKE '%John%';
SELECT UPPER(name), LOWER(city) FROM employees;
SELECT CONCAT(first_name, ' ', last_name) as full_name FROM employees;
```

**Pandas:**
```python
df[df['name'].str.contains('John')]
df['name'].str.upper(), df['city'].str.lower()
df['first_name'] + ' ' + df['last_name']
```

---

### Date Operations

**SQL:**
```sql
SELECT *, EXTRACT(YEAR FROM hire_date) as hire_year FROM employees;
SELECT * FROM employees WHERE hire_date > '2020-01-01';
```

**Pandas:**
```python
df['hire_year'] = df['hire_date'].dt.year
df[df['hire_date'] > '2020-01-01']
```

---

### Union Operations

**SQL:**
```sql
SELECT * FROM table1
UNION ALL
SELECT * FROM table2;
```

**Pandas:**
```python
pd.concat([table1, table2], ignore_index=True)
```

---

### Window Functions

**SQL:**
```sql
SELECT *,
    ROW_NUMBER() OVER (PARTITION BY city ORDER BY salary DESC) as rank,
    AVG(salary) OVER (PARTITION BY city) as city_avg_salary
FROM employees;
```

**Pandas:**
```python
df['rank'] = df.groupby('city')['salary'].rank(ascending=False)
df['city_avg_salary'] = df.groupby('city')['salary'].transform('mean')
```

---

## What Pandas Can Do That SQL Cannot (or Does Less Elegantly)

### 1. In-Memory Processing with Full Programming Language Integration

**Pandas Advantage:**
Pandas operates within Python, giving you access to the entire Python ecosystem. You can use custom functions, machine learning libraries, visualization tools, and more.

```python
# Apply complex custom logic
def categorize_employee(row):
    if row['age'] > 40 and row['salary'] > 100000:
        return 'Senior High Earner'
    elif row['performance_score'] > 90:
        return 'Top Performer'
    else:
        return 'Standard'

df['category'] = df.apply(categorize_employee, axis=1)
```

**SQL Limitation:** While you can write stored procedures in SQL, integrating complex logic, external APIs, or machine learning models is much more cumbersome.

---

### 2. Advanced Data Visualization Integration

**Pandas Advantage:**
Pandas integrates seamlessly with visualization libraries like Matplotlib, Seaborn, and Plotly.

```python
import matplotlib.pyplot as plt

# Built-in plotting
df['salary'].hist(bins=20)
df.plot(x='age', y='salary', kind='scatter')
df.groupby('city')['salary'].mean().plot(kind='bar')

# Integration with Seaborn
import seaborn as sns
sns.heatmap(df.corr(), annot=True)
```

**SQL Limitation:** SQL itself cannot visualize data. You need external tools like Tableau, Power BI, or must export data to another system.

---

### 3. Reshaping Data (Pivot and Melt)

**Pandas Advantage:**
Pandas provides intuitive methods for transforming data between wide and long formats.

```python
# Wide to Long (Melt)
long_df = pd.melt(df, id_vars=['name'], 
                   value_vars=['q1_sales', 'q2_sales', 'q3_sales', 'q4_sales'],
                   var_name='quarter', value_name='sales')

# Long to Wide (Pivot)
wide_df = df.pivot(index='name', columns='quarter', values='sales')

# Complex pivot tables
pivot = pd.pivot_table(df, values='sales', index=['region', 'product'],
                       columns='year', aggfunc=['sum', 'mean'], margins=True)
```

**SQL Limitation:** While SQL has PIVOT and UNPIVOT operations, they are database-specific, less flexible, and require you to know column names in advance.

---

### 4. Rolling and Expanding Window Calculations

**Pandas Advantage:**
Pandas offers flexible window operations with intuitive syntax.

```python
# Various rolling calculations
df['rolling_mean'] = df['sales'].rolling(window=7).mean()
df['rolling_std'] = df['sales'].rolling(window=7).std()
df['rolling_min'] = df['sales'].rolling(window=7).min()
df['ewm_mean'] = df['sales'].ewm(span=7).mean()  # Exponential weighted

# Custom rolling functions
df['rolling_custom'] = df['sales'].rolling(window=7).apply(
    lambda x: np.percentile(x, 75) - np.percentile(x, 25)
)

# Expanding windows
df['cumulative_mean'] = df['sales'].expanding().mean()
```

**SQL Limitation:** While SQL window functions exist, they are more verbose and less flexible. Custom rolling calculations are particularly difficult.

---

### 5. Advanced String Manipulation

**Pandas Advantage:**
Pandas provides a comprehensive set of string methods through the `.str` accessor.

```python
# Complex string operations
df['clean_name'] = (df['name']
    .str.lower()
    .str.strip()
    .str.replace(r'[^\w\s]', '', regex=True)
    .str.replace(r'\s+', ' ', regex=True))

# Extract patterns
df['phone_numbers'] = df['text'].str.extractall(r'(\d{3}-\d{3}-\d{4})')

# Get dummies from string column
pd.get_dummies(df['category'], prefix='cat')

# Split into multiple columns
df[['first_name', 'last_name']] = df['full_name'].str.split(' ', expand=True)
```

**SQL Limitation:** SQL string functions are limited and regex support varies by database. Complex text processing often requires exporting to another tool.

---

### 6. Machine Learning Integration

**Pandas Advantage:**
Pandas DataFrames are the standard input for machine learning libraries in Python.

```python
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler
from sklearn.ensemble import RandomForestClassifier

# Prepare features
X = df[['age', 'salary', 'experience']]
y = df['will_churn']

# Train-test split
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2)

# Scale features
scaler = StandardScaler()
X_train_scaled = scaler.fit_transform(X_train)

# Train model
model = RandomForestClassifier()
model.fit(X_train_scaled, y_train)

# Add predictions back to DataFrame
df['prediction'] = model.predict(scaler.transform(X))
```

**SQL Limitation:** SQL databases are not designed for machine learning. While some databases have ML extensions, they are limited compared to Python's ecosystem.

---

### 7. Interactive Data Exploration

**Pandas Advantage:**
In Jupyter notebooks, pandas provides an interactive environment perfect for exploration.

```python
# Quick exploration
df.head()
df.info()
df.describe()
df['salary'].hist()

# Profile entire dataset
import pandas_profiling
profile = pandas_profiling.ProfileReport(df)
```

**SQL Limitation:** SQL queries return results but don't provide an interactive exploration environment. Each query is independent.

---

### 8. Complex Data Type Handling

**Pandas Advantage:**
Pandas can handle complex data types including nested structures, mixed types, and custom objects.

```python
# JSON/nested data
df['metadata'] = [{'a': 1, 'b': 2}, {'a': 3, 'b': 4}]
df['metadata'].apply(lambda x: x.get('a'))

# Lists within cells
df['tags'] = [['python', 'pandas'], ['sql', 'database']]
df = df.explode('tags')

# Custom objects
class CustomType:
    def __init__(self, value):
        self.value = value
        
df['custom'] = [CustomType(1), CustomType(2)]
```

**SQL Limitation:** SQL is designed for structured, tabular data. While JSON support exists in modern databases, it's not as flexible.

---

### 9. Multi-Index and Hierarchical Data

**Pandas Advantage:**
Pandas supports complex hierarchical indexing for multi-dimensional data analysis.

```python
# Create hierarchical index
df = df.set_index(['region', 'city', 'product'])

# Cross-sectional analysis
df.xs('North', level='region')
df.xs(('North', 'Electronics'), level=['region', 'product'])

# Stack and unstack
df.stack()
df.unstack(level='product')
```

**SQL Limitation:** SQL doesn't have native support for hierarchical indexing. You'd need multiple queries or complex joins.

---

### 10. Method Chaining

**Pandas Advantage:**
Pandas allows elegant method chaining for readable data transformations.

```python
result = (df
    .query('age > 25')
    .assign(
        annual_salary=lambda x: x['monthly_salary'] * 12,
        age_group=lambda x: pd.cut(x['age'], bins=[0, 30, 50, 100])
    )
    .groupby('department')
    .agg({
        'annual_salary': ['mean', 'median'],
        'performance': 'mean'
    })
    .round(2)
    .sort_values(('annual_salary', 'mean'), ascending=False)
    .head(10)
)
```

**SQL Limitation:** SQL queries can be chained with CTEs (Common Table Expressions), but the syntax is more verbose.

---

### 11. Custom Aggregation Functions

**Pandas Advantage:**
Create any aggregation function you need.

```python
# Custom aggregations
def range_func(x):
    return x.max() - x.min()

def coefficient_of_variation(x):
    return x.std() / x.mean()

df.groupby('city')['salary'].agg([range_func, coefficient_of_variation])

# Lambda functions
df.groupby('city')['salary'].agg(
    iqr=lambda x: x.quantile(0.75) - x.quantile(0.25),
    skewness=lambda x: x.skew()
)
```

**SQL Limitation:** SQL has built-in aggregate functions, but creating custom ones requires writing stored procedures or using database-specific features.

---

### 12. Data Profiling and Quality Checks

**Pandas Advantage:**
Easy data quality assessment.

```python
# Check for missing values
df.isnull().sum()

# Check for duplicates
df.duplicated().sum()

# Data type analysis
df.dtypes
df.select_dtypes(include=['object']).columns

# Outlier detection
q1 = df['salary'].quantile(0.25)
q3 = df['salary'].quantile(0.75)
iqr = q3 - q1
outliers = df[(df['salary'] < q1 - 1.5*iqr) | (df['salary'] > q3 + 1.5*iqr)]

# Validate data
assert df['age'].between(0, 120).all(), "Invalid age values found"
```

---

## What SQL Does Better Than Pandas

While pandas has many advantages, SQL excels in certain areas:

### 1. Handling Very Large Datasets
SQL databases can handle datasets larger than RAM through indexing, query optimization, and disk-based storage. Pandas loads everything into memory.

### 2. Concurrent Access
SQL databases support multiple users querying and updating data simultaneously with ACID transactions. Pandas is single-user by nature.

### 3. Data Persistence
SQL databases store data permanently with backup and recovery features. Pandas DataFrames exist only while your Python session is running.

### 4. Optimized Query Execution
SQL databases have query optimizers that choose the most efficient execution plan. Pandas executes operations as written.

### 5. Complex Joins on Large Tables
When joining large tables, SQL databases use indexes efficiently. Pandas joins can be slow on large datasets.

### 6. Security and Access Control
SQL databases provide user authentication, role-based access, and fine-grained permissions. Pandas has no built-in security.

---

## When to Use Which

### Use SQL When:
- Data is stored in a relational database
- Dataset is larger than available RAM
- Multiple users need concurrent access
- You need persistent data storage
- Simple querying and basic aggregations are sufficient
- Data security and access control are required

### Use Pandas When:
- Performing exploratory data analysis
- Data fits in memory
- You need complex transformations or reshaping
- Integrating with machine learning or visualization
- Rapid prototyping and iteration
- Working with diverse data formats (CSV, Excel, JSON)
- You need custom functions or Python integration

### Use Both Together:
The best approach often combines both tools:
```python
# Query database with SQL
query = """
    SELECT * FROM sales
    WHERE date > '2023-01-01'
    AND region IN ('North', 'South')
"""
df = pd.read_sql(query, connection)

# Process in pandas
result = (df
    .groupby('product')
    .agg({'revenue': 'sum', 'quantity': 'mean'})
    .sort_values('revenue', ascending=False)
)

# Write results back to database
result.to_sql('sales_summary', connection, if_exists='replace')
```

---

## Summary Comparison Table

| Feature | SQL | Pandas |
|---------|-----|--------|
| Data Storage | Persistent, disk-based | In-memory, temporary |
| Data Size | Scales to massive datasets | Limited by RAM |
| Query Language | SQL syntax | Python methods |
| Learning Curve | Moderate | Moderate to High |
| Visualization | Requires external tools | Built-in + integrations |
| Machine Learning | Limited support | Full Python ecosystem |
| String Operations | Basic | Comprehensive |
| Custom Functions | Stored procedures | Any Python function |
| Window Functions | Supported | More flexible |
| Data Reshaping | Limited | Excellent |
| Concurrent Access | Excellent | Single user |
| Speed on Large Data | Generally faster | Limited by memory |
| Interactivity | Batch queries | Interactive exploration |
| Version Control | Limited | Works with Git |
| Reproducibility | Query-based | Notebook-based |

---

# Conclusion

This guide has covered the essential functions and methods in both NumPy and pandas, providing you with a solid foundation for data analysis in Python. We've also explored the relationship between pandas and SQL, highlighting when to use each tool.

**Key Takeaways:**

1. **NumPy** is the foundation for numerical computing in Python, providing efficient array operations and mathematical functions.

2. **Pandas** builds on NumPy to provide powerful data manipulation capabilities, especially for tabular data.

3. **SQL** and **pandas** serve similar purposes but excel in different scenarios—SQL for large-scale database operations, pandas for flexible in-memory analysis.

4. The best data practitioners are proficient in both SQL and pandas, using each tool where it excels.

As you continue your data analysis journey, remember that practice is key. Work with real datasets, experiment with different methods, and don't be afraid to look up documentation. The pandas and NumPy documentation are excellent resources for deeper learning.

Happy analyzing!