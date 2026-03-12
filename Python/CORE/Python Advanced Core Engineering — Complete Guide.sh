Python Advanced Core Engineering — Complete Guide

> I can't generate a downloadable PDF directly, but the content below is structured so you can copy it into any Markdown→PDF tool (e.g., `grip`, `pandoc`, or VS Code's "Markdown PDF" extension) and get a perfectly formatted document.

---

## Table of Contents

```
1.  Core Python
2.  Object-Oriented Programming
3.  Python Internals
4.  Concurrency
5.  Performance Optimization
6.  Advanced Python Features
7.  Python Testing
```

---

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 1. CORE PYTHON
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## 1.1 Python Execution Model

Python is a **compiled + interpreted** language. Source code goes through multiple stages before execution.

```
Source (.py)
    │
    ▼
┌──────────┐
│  Lexer   │  ← Tokenization
└──────────┘
    │
    ▼
┌──────────┐
│  Parser  │  ← AST (Abstract Syntax Tree)
└──────────┘
    │
    ▼
┌──────────┐
│ Compiler │  ← Bytecode (.pyc)
└──────────┘
    │
    ▼
┌──────────┐
│   PVM    │  ← Python Virtual Machine executes bytecode
└──────────┘
```

```python
# You can inspect each stage:

# 1. Tokenization
import tokenize, io
code = "x = 42 + 1"
tokens = tokenize.generate_tokens(io.StringIO(code).readline)
for tok in tokens:
    print(tok)

# 2. AST
import ast
tree = ast.parse(code)
print(ast.dump(tree, indent=2))

# 3. Bytecode
import dis
def example():
    x = 42 + 1
    return x

dis.dis(example)
# Output:
#   0 LOAD_CONST               1 (43)    ← compiler already folded 42+1
#   2 STORE_FAST               0 (x)
#   4 LOAD_FAST                0 (x)
#   6 RETURN_VALUE

# 4. .pyc files are cached in __pycache__/
import py_compile
py_compile.compile('my_module.py')
```

**Key points:**
- CPython compiles to bytecode **every time** unless a `.pyc` cache is valid
- The PVM is a **stack-based** virtual machine
- Constant folding, peephole optimizations happen at compile time

---

## 1.2 Python Memory Management

```
┌─────────────────────────────────────────────┐
│              OS Virtual Memory              │
├─────────────────────────────────────────────┤
│          Python's Memory Allocator          │
│  ┌───────────────────────────────────────┐  │
│  │  Object-specific allocators           │  │
│  │  (int, list, dict free-lists)         │  │
│  ├───────────────────────────────────────┤  │
│  │  pymalloc (arena-based)               │  │
│  │  - Arenas (256 KB each)               │  │
│  │    └─ Pools (4 KB each)               │  │
│  │       └─ Blocks (8–512 bytes)         │  │
│  ├───────────────────────────────────────┤  │
│  │  C malloc / OS allocator              │  │
│  │  (objects > 512 bytes)                │  │
│  └───────────────────────────────────────┘  │
└─────────────────────────────────────────────┘
```

```python
import sys

# Every object has overhead
print(sys.getsizeof(0))        # 28 bytes (on 64-bit CPython)
print(sys.getsizeof(1))        # 28 bytes
print(sys.getsizeof(10**100))  # 72 bytes (arbitrary precision)
print(sys.getsizeof(""))       # 49 bytes
print(sys.getsizeof([]))       # 56 bytes
print(sys.getsizeof({}))       # 64 bytes

# Integer interning: CPython caches small integers [-5, 256]
a = 256
b = 256
print(a is b)  # True — same object

a = 257
b = 257
print(a is b)  # False — different objects (outside REPL)

# String interning
s1 = "hello"
s2 = "hello"
print(s1 is s2)  # True — interned automatically

s3 = "hello world!"
s4 = "hello world!"
print(s3 is s4)  # May be False (not auto-interned, contains space/punct)

import sys
s5 = sys.intern("hello world!")
s6 = sys.intern("hello world!")
print(s5 is s6)  # True — manually interned


# Tracking memory usage
import tracemalloc
tracemalloc.start()

data = [i**2 for i in range(100_000)]

snapshot = tracemalloc.take_snapshot()
for stat in snapshot.statistics('lineno')[:3]:
    print(stat)
```

**Free Lists:**
```python
# CPython maintains free lists for frequently created/destroyed objects
# When a float/int/tuple/list/dict is deallocated, its memory block
# goes to a free list instead of being returned to the OS.

# This is why:
import timeit
# Creating floats is fast because free list provides pre-allocated blocks
print(timeit.timeit("x = 3.14", number=10_000_000))
```

---

## 1.3 Python Data Model (Dunder Methods)

The data model defines how objects interact with Python's syntax and built-in functions.

```python
class Vector:
    """A complete example demonstrating the Python data model."""

    __slots__ = ('_x', '_y')  # Memory optimization: no __dict__

    def __init__(self, x: float, y: float):
        """Constructor — called after __new__"""
        self._x = x
        self._y = y

    # ── Representation ──────────────────────────────────
    def __repr__(self) -> str:
        """Unambiguous representation for developers"""
        return f"Vector({self._x!r}, {self._y!r})"

    def __str__(self) -> str:
        """User-friendly string"""
        return f"({self._x}, {self._y})"

    def __format__(self, fmt_spec: str) -> str:
        """Support format() and f-strings with format spec"""
        if fmt_spec.endswith('p'):  # polar format
            import math
            r = abs(self)
            theta = math.atan2(self._y, self._x)
            fmt_spec = fmt_spec[:-1]
            return f"<{r:{fmt_spec}}, {theta:{fmt_spec}}>"
        components = (format(c, fmt_spec) for c in self)
        return '({}, {})'.format(*components)

    # ── Container Protocol ──────────────────────────────
    def __len__(self) -> int:
        return 2

    def __getitem__(self, index):
        return (self._x, self._y)[index]

    def __iter__(self):
        yield self._x
        yield self._y

    def __contains__(self, value):
        return value in (self._x, self._y)

    # ── Numeric Protocol ────────────────────────────────
    def __add__(self, other):
        if isinstance(other, Vector):
            return Vector(self._x + other._x, self._y + other._y)
        return NotImplemented

    def __radd__(self, other):
        """Reflected add — called when left operand doesn't support +"""
        return self.__add__(other)

    def __mul__(self, scalar):
        if isinstance(scalar, (int, float)):
            return Vector(self._x * scalar, self._y * scalar)
        return NotImplemented

    def __rmul__(self, scalar):
        return self.__mul__(scalar)

    def __neg__(self):
        return Vector(-self._x, -self._y)

    def __abs__(self):
        import math
        return math.hypot(self._x, self._y)

    # ── Comparison Protocol ─────────────────────────────
    def __eq__(self, other):
        if isinstance(other, Vector):
            return self._x == other._x and self._y == other._y
        return NotImplemented

    def __hash__(self):
        """Required for use in sets/dicts when __eq__ is defined"""
        return hash((self._x, self._y))

    def __bool__(self):
        """Truthiness: zero vector is falsy"""
        return bool(abs(self))

    # ── Attribute Access Protocol ───────────────────────
    # (handled by __slots__ here, but shown for education)

    # ── Context Manager Protocol ────────────────────────
    def __enter__(self):
        print(f"Entering context with {self}")
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        print(f"Exiting context")
        return False  # Don't suppress exceptions

    # ── Callable Protocol ───────────────────────────────
    def __call__(self, scalar=1):
        """Make instance callable"""
        return Vector(self._x * scalar, self._y * scalar)


# Usage demonstration
v1 = Vector(3, 4)
v2 = Vector(1, 2)

print(repr(v1))          # Vector(3, 4)
print(str(v1))           # (3, 4)
print(f"{v1:.2f}")       # (3.00, 4.00)
print(len(v1))           # 2
print(v1[0])             # 3
print(list(v1))          # [3, 4]
print(3 in v1)           # True
print(v1 + v2)           # (4, 6)
print(v1 * 3)            # (9, 12)
print(3 * v1)            # (9, 12) — __rmul__
print(abs(v1))           # 5.0
print(v1 == Vector(3,4)) # True
print(bool(Vector(0,0))) # False
print(v1(10))            # (30, 40) — __call__

# In a set (hashable)
vectors = {v1, v2, Vector(3, 4)}
print(len(vectors))      # 2 (v1 and Vector(3,4) are equal)
```

**Object Creation Pipeline:**
```python
class MyClass:
    def __new__(cls, *args, **kwargs):
        """Allocates memory — rarely overridden.
        Use case: singletons, immutable types, caching."""
        print("__new__ called")
        instance = super().__new__(cls)
        return instance

    def __init__(self, value):
        """Initializes the already-created instance."""
        print("__init__ called")
        self.value = value

    def __init_subclass__(cls, **kwargs):
        """Called when a class is subclassed."""
        print(f"__init_subclass__ called for {cls.__name__}")
        super().__init_subclass__(**kwargs)

    def __del__(self):
        """Destructor — called when ref count reaches 0.
        WARNING: Unreliable timing. Use context managers instead."""
        print("__del__ called")


# Singleton using __new__
class Singleton:
    _instance = None

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
        return cls._instance

s1 = Singleton()
s2 = Singleton()
print(s1 is s2)  # True
```

---

## 1.4 Mutable vs Immutable Objects

```
┌──────────────────────────────────────────────┐
│              IMMUTABLE OBJECTS                │
├──────────────────────────────────────────────┤
│  int, float, complex, bool                   │
│  str, bytes                                  │
│  tuple, frozenset                            │
│  None, Ellipsis                              │
│  (and user classes with __hash__ / __slots__) │
└──────────────────────────────────────────────┘

┌──────────────────────────────────────────────┐
│               MUTABLE OBJECTS                │
├──────────────────────────────────────────────┤
│  list, dict, set, bytearray                 │
│  Most user-defined classes                   │
└──────────────────────────────────────────────┘
```

```python
# === CRITICAL: Mutable default argument trap ===
def bad_append(value, lst=[]):
    """BUG: default list is shared across all calls!"""
    lst.append(value)
    return lst

print(bad_append(1))  # [1]
print(bad_append(2))  # [1, 2]  ← BUG!
print(bad_append(3))  # [1, 2, 3] ← BUG!

def good_append(value, lst=None):
    """FIX: use None sentinel."""
    if lst is None:
        lst = []
    lst.append(value)
    return lst


# === Immutability is shallow for tuples ===
t = ([1, 2], [3, 4])
# t[0] = [5, 6]   # TypeError: tuples don't support item assignment
t[0].append(99)    # But the LIST inside is mutable!
print(t)           # ([1, 2, 99], [3, 4])

# This means tuple's hash will fail if it contains mutable objects:
try:
    hash(t)
except TypeError as e:
    print(e)  # unhashable type: 'list'


# === String immutability and interning ===
s = "hello"
# s[0] = "H"  # TypeError
s = "H" + s[1:]  # Creates a NEW string object
print(id(s))

# Performance implication of string concatenation:
import timeit

# BAD: O(n²) — creates new string each iteration
def concat_bad(n):
    s = ""
    for i in range(n):
        s += str(i)
    return s

# GOOD: O(n) — joins at the end
def concat_good(n):
    parts = []
    for i in range(n):
        parts.append(str(i))
    return "".join(parts)

# BEST: O(n) — generator expression
def concat_best(n):
    return "".join(str(i) for i in range(n))

n = 50_000
print(timeit.timeit(lambda: concat_bad(n), number=5))
print(timeit.timeit(lambda: concat_good(n), number=5))
print(timeit.timeit(lambda: concat_best(n), number=5))
```

---

## 1.5 Namespaces & Scope (LEGB Rule)

```
┌─────────────────────────────────────────────┐
│  B — Built-in (builtins module)             │
│  ┌─────────────────────────────────────────┐│
│  │  G — Global (module-level)             ││
│  │  ┌─────────────────────────────────────┐││
│  │  │  E — Enclosing (outer function)    │││
│  │  │  ┌─────────────────────────────────┐│││
│  │  │  │  L — Local (current function)  ││││
│  │  │  └─────────────────────────────────┘│││
│  │  └─────────────────────────────────────┘││
│  └─────────────────────────────────────────┘│
└─────────────────────────────────────────────┘
```

```python
# === Full LEGB demonstration ===

x = "global"  # G

def outer():
    x = "enclosing"  # E

    def inner():
        x = "local"  # L
        print(x)     # "local" — L wins

    def inner_no_local():
        print(x)     # "enclosing" — E is next

    def inner_global():
        global x
        print(x)     # "global" — skips E, reads G
        x = "modified global"

    def inner_nonlocal():
        nonlocal x
        x = "modified enclosing"

    inner()            # local
    inner_no_local()   # enclosing
    inner_global()     # global
    print(x)           # still "enclosing" (inner_global used global, not nonlocal)

    inner_nonlocal()
    print(x)           # "modified enclosing" (nonlocal modified E)

outer()
print(x)  # "modified global" (inner_global modified G)


# === The UnboundLocalError trap ===
count = 0

def increment():
    # count += 1  # UnboundLocalError!
    # Python sees the assignment and marks 'count' as local at COMPILE time.
    # But += tries to READ it first → it doesn't exist locally yet.
    pass

def increment_fixed():
    global count
    count += 1


# === Namespace inspection ===
def show_namespaces():
    local_var = 42
    print("Locals:", locals())
    print("Globals keys:", list(globals().keys())[:10])

show_namespaces()

# === Closures capture variables by REFERENCE, not by value ===
def make_counters():
    counters = []
    for i in range(5):
        # BUG: all lambdas share the same 'i' variable
        counters.append(lambda: i)
    return counters

# All return 4!
print([c() for c in make_counters()])  # [4, 4, 4, 4, 4]

def make_counters_fixed():
    counters = []
    for i in range(5):
        # FIX: default argument captures current value
        counters.append(lambda i=i: i)
    return counters

print([c() for c in make_counters_fixed()])  # [0, 1, 2, 3, 4]
```

---

## 1.6 Pass by Reference vs Value

Python uses **"pass by object reference"** (also called "pass by assignment").

```python
# === The mental model ===
# Variables are NAMES that point to OBJECTS.
# Assignment binds a name to an object.
# Function arguments are new names bound to the same objects.

def demonstrate(param):
    """
    'param' is a new name pointing to the same object as the argument.
    - If you REBIND param (param = something_new), the caller is unaffected.
    - If you MUTATE the object (param.append(...)), the caller sees the change.
    """
    pass


# === Immutable: looks like pass-by-value ===
def try_change_int(n):
    print(f"  Before: id={id(n)}")
    n += 1  # Creates a NEW int object; rebinds local 'n'
    print(f"  After:  id={id(n)}")

x = 10
print(f"Caller before: x={x}, id={id(x)}")
try_change_int(x)
print(f"Caller after:  x={x}")  # Still 10


# === Mutable: looks like pass-by-reference ===
def try_change_list(lst):
    lst.append(99)  # Mutates the SAME object

my_list = [1, 2, 3]
try_change_list(my_list)
print(my_list)  # [1, 2, 3, 99] — caller sees the mutation


# === Mutable but REBINDING ===
def try_replace_list(lst):
    lst = [10, 20, 30]  # Rebinds local 'lst' to a NEW list

my_list = [1, 2, 3]
try_replace_list(my_list)
print(my_list)  # [1, 2, 3] — unchanged!


# === Practical pattern: avoid mutating arguments ===
def process(data: list[int]) -> list[int]:
    """Pure function: don't mutate input, return new data."""
    result = data.copy()  # or list(data) or data[:]
    result.sort()
    result.append(0)
    return result

original = [3, 1, 2]
processed = process(original)
print(original)   # [3, 1, 2] — untouched
print(processed)  # [0, 1, 2, 3]
```

---

## 1.7 Shallow Copy vs Deep Copy

```
ORIGINAL:         SHALLOW COPY:        DEEP COPY:
┌──────────┐      ┌──────────┐        ┌──────────┐
│ list obj │      │ list obj │        │ list obj │
│  [0]─────┼──┐   │  [0]─────┼──┐     │  [0]──┐  │
│  [1]─────┼──┤   │  [1]─────┼──┤     │  [1]──┤  │
└──────────┘  │   └──────────┘  │     └───────┤──┘
              │                 │             │
              ▼                 ▼             ▼
         ┌────────┐        ┌────────┐   ┌────────┐
         │ inner  │        │ SAME   │   │ NEW    │
         │ list   │◄───────│ inner  │   │ inner  │
         └────────┘        └────────┘   └────────┘
```

```python
import copy

# === Setup ===
original = [[1, 2, 3], [4, 5, 6], {"key": "value"}]

# === Shallow copy methods (all equivalent) ===
shallow1 = original.copy()
shallow2 = list(original)
shallow3 = original[:]
shallow4 = copy.copy(original)

# Outer list is new:
print(original is shallow1)      # False

# Inner objects are SHARED:
print(original[0] is shallow1[0])  # True ← SAME inner list!

# Mutating inner object affects both:
shallow1[0].append(999)
print(original[0])  # [1, 2, 3, 999] ← AFFECTED!


# === Deep copy ===
original = [[1, 2, 3], [4, 5, 6], {"key": "value"}]
deep = copy.deepcopy(original)

print(original[0] is deep[0])  # False ← different objects

deep[0].append(999)
print(original[0])  # [1, 2, 3] ← NOT affected


# === Deep copy handles cycles ===
a = [1, 2]
a.append(a)  # Self-referencing!
print(a)     # [1, 2, [...]]

b = copy.deepcopy(a)  # Handles circular references correctly
print(b)     # [1, 2, [...]]
print(b[2] is b)  # True — cycle preserved but with new objects


# === Custom copy behavior ===
class GameState:
    def __init__(self, board, metadata):
        self.board = board          # Must deep copy
        self.metadata = metadata    # Can shallow copy (immutable strings)

    def __copy__(self):
        """Custom shallow copy"""
        return GameState(self.board, self.metadata)

    def __deepcopy__(self, memo):
        """Custom deep copy — 'memo' tracks already-copied objects"""
        new_board = copy.deepcopy(self.board, memo)
        # Don't deep copy metadata (it's a shared config)
        return GameState(new_board, self.metadata)


# === Performance comparison ===
import timeit

data = [list(range(100)) for _ in range(100)]
print("Shallow:", timeit.timeit(lambda: copy.copy(data), number=10_000))
print("Deep:   ", timeit.timeit(lambda: copy.deepcopy(data), number=10_000))
# Deep copy is MUCH slower — only use when needed
```

---

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 2. OBJECT-ORIENTED PROGRAMMING
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## 2.1 SOLID Principles

```python
# ═══════════════════════════════════════
# S — Single Responsibility Principle
# ═══════════════════════════════════════
# A class should have ONE reason to change.

# BAD
class UserBad:
    def __init__(self, name, email):
        self.name = name
        self.email = email

    def save_to_db(self):  # Persistence logic
        pass

    def send_email(self):  # Email logic
        pass

    def generate_report(self):  # Reporting logic
        pass

# GOOD
class User:
    def __init__(self, name: str, email: str):
        self.name = name
        self.email = email

class UserRepository:
    def save(self, user: User): ...

class EmailService:
    def send(self, user: User, message: str): ...

class ReportGenerator:
    def generate(self, user: User) -> str: ...


# ═══════════════════════════════════════
# O — Open/Closed Principle
# ═══════════════════════════════════════
# Open for extension, closed for modification.

from abc import ABC, abstractmethod

# BAD — must modify existing code to add new shapes
class AreaCalculatorBad:
    def calculate(self, shape):
        if isinstance(shape, dict) and shape["type"] == "circle":
            return 3.14 * shape["radius"] ** 2
        elif isinstance(shape, dict) and shape["type"] == "rectangle":
            return shape["width"] * shape["height"]
        # Must add elif for every new shape...

# GOOD — extend by adding new classes
class Shape(ABC):
    @abstractmethod
    def area(self) -> float: ...

class Circle(Shape):
    def __init__(self, radius: float):
        self.radius = radius
    def area(self) -> float:
        return 3.14159 * self.radius ** 2

class Rectangle(Shape):
    def __init__(self, width: float, height: float):
        self.width = width
        self.height = height
    def area(self) -> float:
        return self.width * self.height

# Adding a triangle requires NO changes to existing code:
class Triangle(Shape):
    def __init__(self, base: float, height: float):
        self.base = base
        self.height = height
    def area(self) -> float:
        return 0.5 * self.base * self.height

def total_area(shapes: list[Shape]) -> float:
    return sum(s.area() for s in shapes)


# ═══════════════════════════════════════
# L — Liskov Substitution Principle
# ═══════════════════════════════════════
# Subtypes must be substitutable for their base types.

# BAD — violates LSP
class Bird:
    def fly(self):
        return "Flying"

class Penguin(Bird):
    def fly(self):
        raise NotImplementedError("Penguins can't fly!")  # Breaks substitution

# GOOD
class Bird(ABC):
    @abstractmethod
    def move(self) -> str: ...

class FlyingBird(Bird):
    def move(self) -> str:
        return "Flying"

class SwimmingBird(Bird):
    def move(self) -> str:
        return "Swimming"

class Eagle(FlyingBird): ...
class Penguin(SwimmingBird): ...

def make_bird_move(bird: Bird) -> str:
    return bird.move()  # Works for ALL birds


# ═══════════════════════════════════════
# I — Interface Segregation Principle
# ═══════════════════════════════════════
# Clients shouldn't depend on methods they don't use.

# BAD
class WorkerBad(ABC):
    @abstractmethod
    def work(self): ...
    @abstractmethod
    def eat(self): ...
    @abstractmethod
    def sleep(self): ...

class RobotBad(WorkerBad):
    def work(self): ...
    def eat(self): raise NotImplementedError  # Robots don't eat!
    def sleep(self): raise NotImplementedError

# GOOD
class Workable(ABC):
    @abstractmethod
    def work(self): ...

class Eatable(ABC):
    @abstractmethod
    def eat(self): ...

class Human(Workable, Eatable):
    def work(self): ...
    def eat(self): ...

class Robot(Workable):  # Only implements what it needs
    def work(self): ...


# ═══════════════════════════════════════
# D — Dependency Inversion Principle
# ═══════════════════════════════════════
# High-level modules shouldn't depend on low-level modules.
# Both should depend on abstractions.

# BAD — high-level depends on low-level
class MySQLDatabase:
    def query(self, sql): ...

class UserServiceBad:
    def __init__(self):
        self.db = MySQLDatabase()  # Tightly coupled!

# GOOD — depend on abstraction
class Database(ABC):
    @abstractmethod
    def query(self, sql: str) -> list: ...

class MySQL(Database):
    def query(self, sql: str) -> list:
        return []  # MySQL implementation

class PostgreSQL(Database):
    def query(self, sql: str) -> list:
        return []  # PostgreSQL implementation

class UserService:
    def __init__(self, db: Database):  # Depends on abstraction
        self.db = db

# Easy to swap implementations:
service_mysql = UserService(MySQL())
service_pg = UserService(PostgreSQL())
```

---

## 2.2 Abstract Classes vs Interfaces

```python
from abc import ABC, abstractmethod
from typing import Protocol, runtime_checkable


# === Abstract Base Class (ABC) ===
# - Uses inheritance (nominal typing)
# - Can have concrete methods and state
# - Cannot be instantiated directly

class Repository(ABC):
    def __init__(self, connection_string: str):
        self.connection_string = connection_string  # Shared state

    @abstractmethod
    def find(self, id: int):
        """Must be implemented by subclasses"""
        ...

    @abstractmethod
    def save(self, entity) -> None:
        ...

    def health_check(self) -> bool:
        """Concrete method — shared implementation"""
        return self.connection_string is not None

    @property
    @abstractmethod
    def table_name(self) -> str:
        """Abstract property"""
        ...


class UserRepository(Repository):
    @property
    def table_name(self) -> str:
        return "users"

    def find(self, id: int):
        return {"id": id}

    def save(self, entity) -> None:
        pass


# === Protocol (Structural/Duck Typing) ===
# - No inheritance required
# - Defines expected interface structurally
# - Python 3.8+

@runtime_checkable
class Renderable(Protocol):
    def render(self) -> str: ...

class HTMLPage:
    """Doesn't inherit from Renderable — but structurally matches!"""
    def render(self) -> str:
        return "<html>...</html>"

class JSONResponse:
    def render(self) -> str:
        return '{"status": "ok"}'

def display(item: Renderable) -> None:
    """Accepts anything with a render() method"""
    print(item.render())

display(HTMLPage())       # Works!
display(JSONResponse())   # Works!
print(isinstance(HTMLPage(), Renderable))  # True (runtime_checkable)


# === When to use which? ===
# ABC:      When you need shared implementation / state / enforcement
# Protocol: When you want structural typing / decoupling / duck typing
```

---

## 2.3 Method Resolution Order (MRO)

```python
# Python uses the C3 Linearization algorithm for MRO.

class A:
    def method(self):
        print("A.method")

class B(A):
    def method(self):
        print("B.method")
        super().method()

class C(A):
    def method(self):
        print("C.method")
        super().method()

class D(B, C):
    def method(self):
        print("D.method")
        super().method()

# MRO determines the order:
print(D.__mro__)
# (<class 'D'>, <class 'B'>, <class 'C'>, <class 'A'>, <class 'object'>)

d = D()
d.method()
# Output:
# D.method
# B.method
# C.method
# A.method

# The Diamond Problem is resolved by C3:
#
#       A
#      / \
#     B   C
#      \ /
#       D
#
# MRO: D → B → C → A → object
# A.method() is called ONCE, not twice!


# === super() with arguments ===
class Base:
    def __init__(self, value, **kwargs):
        super().__init__(**kwargs)  # Forward unknown kwargs
        self.value = value

class Mixin:
    def __init__(self, extra, **kwargs):
        super().__init__(**kwargs)
        self.extra = extra

class Combined(Mixin, Base):
    def __init__(self, value, extra, **kwargs):
        super().__init__(value=value, extra=extra, **kwargs)

obj = Combined(value=10, extra=20)
print(obj.value, obj.extra)  # 10 20


# === Invalid MRO (C3 Linearization failure) ===
class X: pass
class Y(X): pass

try:
    # This would fail:
    # class Z(X, Y): pass  # TypeError: Cannot create a consistent MRO
    pass
except TypeError as e:
    print(e)
```

---

## 2.4 Metaclasses

```python
# === What are metaclasses? ===
# A metaclass is the "class of a class."
# 
#   object  ← base of all instances
#   type    ← base of all classes (and its own metaclass!)
#
#   type(42)        → <class 'int'>
#   type(int)       → <class 'type'>
#   type(type)      → <class 'type'>

# === Creating classes dynamically with type() ===
# type(name, bases, namespace)
MyClass = type('MyClass', (object,), {
    'x': 42,
    'greet': lambda self: f"Hello, x={self.x}"
})

obj = MyClass()
print(obj.greet())  # Hello, x=42


# === Custom Metaclass ===
class ModelMeta(type):
    """Metaclass that auto-registers all model subclasses."""

    _registry: dict[str, type] = {}

    def __new__(mcs, name, bases, namespace):
        cls = super().__new__(mcs, name, bases, namespace)

        # Don't register the base Model itself
        if bases:
            mcs._registry[name] = cls
            print(f"Registered model: {name}")

        # Auto-generate __repr__ if not defined
        if '__repr__' not in namespace:
            fields = [k for k, v in namespace.items()
                     if not k.startswith('_') and not callable(v)]
            def auto_repr(self):
                attrs = ', '.join(f"{f}={getattr(self, f, '?')}" for f in fields)
                return f"{name}({attrs})"
            cls.__repr__ = auto_repr

        return cls

    def __init__(cls, name, bases, namespace):
        super().__init__(name, bases, namespace)

    def __call__(cls, *args, **kwargs):
        """Called when creating an instance of the class."""
        print(f"Creating instance of {cls.__name__}")
        instance = super().__call__(*args, **kwargs)
        # Could add validation, logging, etc.
        return instance


class Model(metaclass=ModelMeta):
    """Base class using our metaclass."""
    pass


class User(Model):
    table = "users"
    def __init__(self, name, email):
        self.name = name
        self.email = email

class Product(Model):
    table = "products"
    def __init__(self, title, price):
        self.title = title
        self.price = price


# Output during class creation:
# Registered model: User
# Registered model: Product

u = User("Alice", "alice@example.com")
# Output: Creating instance of User

print(ModelMeta._registry)
# {'User': <class 'User'>, 'Product': <class 'Product'>}


# === __init_subclass__ — Modern alternative to metaclasses ===
class Plugin:
    _plugins: dict[str, type] = {}

    def __init_subclass__(cls, plugin_name: str = None, **kwargs):
        super().__init_subclass__(**kwargs)
        name = plugin_name or cls.__name__
        Plugin._plugins[name] = cls
        print(f"Plugin registered: {name}")

class AuthPlugin(Plugin, plugin_name="auth"):
    pass

class CachePlugin(Plugin, plugin_name="cache"):
    pass

print(Plugin._plugins)
# {'auth': <class 'AuthPlugin'>, 'cache': <class 'CachePlugin'>}
```

---

## 2.5 Class vs Static Methods

```python
from datetime import datetime


class DateParser:
    """Demonstrates class methods, static methods, and instance methods."""

    date_format = "%Y-%m-%d"  # Class-level attribute

    def __init__(self, date_string: str):
        self.date = datetime.strptime(date_string, self.date_format)

    # Instance method: has access to instance (self) AND class
    def days_until_today(self) -> int:
        return (datetime.now() - self.date).days

    # Class method: has access to CLASS (cls), not instance
    @classmethod
    def from_timestamp(cls, timestamp: float) -> "DateParser":
        """Alternative constructor."""
        date_string = datetime.fromtimestamp(timestamp).strftime(cls.date_format)
        return cls(date_string)  # Uses cls, not DateParser — works with subclasses!

    @classmethod
    def set_format(cls, fmt: str):
        """Modifies class-level state."""
        cls.date_format = fmt

    # Static method: no access to instance or class — pure utility
    @staticmethod
    def is_valid_date(date_string: str, fmt: str = "%Y-%m-%d") -> bool:
        """Doesn't need instance or class state."""
        try:
            datetime.strptime(date_string, fmt)
            return True
        except ValueError:
            return False


# Usage
parser = DateParser("2024-01-15")
print(parser.days_until_today())

# Alternative constructor
parser2 = DateParser.from_timestamp(1700000000)
print(parser2.date)

# Static utility
print(DateParser.is_valid_date("2024-13-01"))  # False


# === Why classmethod matters for inheritance ===
class USDateParser(DateParser):
    date_format = "%m/%d/%Y"

# from_timestamp uses cls, so it returns USDateParser, not DateParser
us_parser = USDateParser.from_timestamp(1700000000)
print(type(us_parser))  # <class 'USDateParser'>
```

---

## 2.6 Design Patterns in Python

```python
# ═══════════════════════════════════════
# CREATIONAL PATTERNS
# ═══════════════════════════════════════

# --- Factory Method ---
class Serializer:
    @staticmethod
    def create(format: str) -> "Serializer":
        serializers = {
            "json": JsonSerializer,
            "xml": XmlSerializer,
            "yaml": YamlSerializer,
        }
        cls = serializers.get(format)
        if not cls:
            raise ValueError(f"Unknown format: {format}")
        return cls()

class JsonSerializer(Serializer):
    def serialize(self, data): return f"JSON: {data}"

class XmlSerializer(Serializer):
    def serialize(self, data): return f"XML: {data}"

class YamlSerializer(Serializer):
    def serialize(self, data): return f"YAML: {data}"

s = Serializer.create("json")


# --- Singleton (multiple approaches) ---

# Approach 1: Module-level (Pythonic)
# config.py → just use module-level variables. Import is cached.

# Approach 2: __new__
class SingletonNew:
    _instance = None
    def __new__(cls):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
        return cls._instance

# Approach 3: Metaclass
class SingletonMeta(type):
    _instances = {}
    def __call__(cls, *args, **kwargs):
        if cls not in cls._instances:
            cls._instances[cls] = super().__call__(*args, **kwargs)
        return cls._instances[cls]

class Database(metaclass=SingletonMeta):
    def __init__(self):
        self.connection = "connected"

print(Database() is Database())  # True

# Approach 4: Decorator
def singleton(cls):
    instances = {}
    def get_instance(*args, **kwargs):
        if cls not in instances:
            instances[cls] = cls(*args, **kwargs)
        return instances[cls]
    return get_instance

@singleton
class Config:
    pass


# ═══════════════════════════════════════
# STRUCTURAL PATTERNS
# ═══════════════════════════════════════

# --- Decorator Pattern (not to confuse with Python decorators) ---
class DataSource:
    def read(self) -> str:
        return "raw data"

class EncryptionDecorator:
    def __init__(self, source: DataSource):
        self._source = source
    def read(self) -> str:
        return f"encrypted({self._source.read()})"

class CompressionDecorator:
    def __init__(self, source: DataSource):
        self._source = source
    def read(self) -> str:
        return f"compressed({self._source.read()})"

source = CompressionDecorator(EncryptionDecorator(DataSource()))
print(source.read())  # compressed(encrypted(raw data))


# --- Strategy Pattern ---
from typing import Callable

# Python-idiomatic: use callables instead of class hierarchy
def bubble_sort(data: list) -> list:
    return sorted(data)  # simplified

def quick_sort(data: list) -> list:
    return sorted(data)  # simplified

class Sorter:
    def __init__(self, strategy: Callable[[list], list] = sorted):
        self.strategy = strategy

    def sort(self, data: list) -> list:
        return self.strategy(data)

sorter = Sorter(strategy=bubble_sort)
print(sorter.sort([3, 1, 2]))


# ═══════════════════════════════════════
# BEHAVIORAL PATTERNS
# ═══════════════════════════════════════

# --- Observer Pattern ---
from typing import Any

class EventEmitter:
    def __init__(self):
        self._listeners: dict[str, list[Callable]] = {}

    def on(self, event: str, callback: Callable):
        self._listeners.setdefault(event, []).append(callback)
        return self  # Allow chaining

    def emit(self, event: str, data: Any = None):
        for callback in self._listeners.get(event, []):
            callback(data)

emitter = EventEmitter()
emitter.on("user_created", lambda user: print(f"Welcome, {user}!"))
emitter.on("user_created", lambda user: print(f"Sending email to {user}"))
emitter.emit("user_created", "Alice")


# --- Chain of Responsibility ---
class Handler(ABC):
    def __init__(self):
        self._next: Handler | None = None

    def set_next(self, handler: "Handler") -> "Handler":
        self._next = handler
        return handler

    def handle(self, request: dict) -> str | None:
        if self._next:
            return self._next.handle(request)
        return None

class AuthHandler(Handler):
    def handle(self, request):
        if not request.get("authenticated"):
            return "401 Unauthorized"
        return super().handle(request)

class RateLimitHandler(Handler):
    def handle(self, request):
        if request.get("rate_exceeded"):
            return "429 Too Many Requests"
        return super().handle(request)

class BusinessHandler(Handler):
    def handle(self, request):
        return "200 OK"

# Build chain
auth = AuthHandler()
rate = RateLimitHandler()
business = BusinessHandler()
auth.set_next(rate).set_next(business)

print(auth.handle({"authenticated": True}))   # 200 OK
print(auth.handle({"authenticated": False}))   # 401 Unauthorized
```

---

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 3. PYTHON INTERNALS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## 3.1 CPython Architecture

```
┌──────────────────────────────────────────────────┐
│                   CPython Layers                 │
├──────────────────────────────────────────────────┤
│                                                  │
│  Python Code (.py)                               │
│       │                                          │
│       ▼                                          │
│  ┌────────────┐                                  │
│  │ Tokenizer  │  Lib/tokenize.py                 │
│  │ (Lexer)    │  Parser/tokenize.c               │
│  └────────────┘                                  │
│       │ tokens                                   │
│       ▼                                          │
│  ┌────────────┐                                  │
│  │   Parser   │  Parser/parser.c (PEG parser)    │
│  └────────────┘  (switched from LL(1) in 3.9)   │
│       │ AST                                      │
│       ▼                                          │
│  ┌────────────┐                                  │
│  │ Compiler   │  Python/compile.c                │
│  └────────────┘                                  │
│       │ bytecode (code objects)                   │
│       ▼                                          │
│  ┌────────────┐                                  │
│  │   ceval.c  │  ← The evaluation loop           │
│  │  (PVM)     │  Python/ceval.c                  │
│  └────────────┘                                  │
│       │                                          │
│       ▼                                          │
│  ┌────────────┐                                  │
│  │  C stdlib  │  OS calls, memory, I/O           │
│  └────────────┘                                  │
│                                                  │
└──────────────────────────────────────────────────┘
```

```python
# === Key CPython internal structures ===

# PyObject — every Python object is this at the C level:
# struct PyObject {
#     Py_ssize_t ob_refcnt;     // Reference count
#     PyTypeObject *ob_type;    // Pointer to type object
# }

# You can inspect these from Python:
import sys
import ctypes

x = 42
print(sys.getrefcount(x))  # Reference count (includes the getrefcount arg itself)
print(type(x))             # <class 'int'>
print(id(x))               # Memory address (CPython)

# Code objects
def example(x, y):
    z = x + y
    return z

code = example.__code__
print(f"Name: {code.co_name}")
print(f"Arguments: {code.co_varnames}")
print(f"Constants: {code.co_consts}")
print(f"Bytecode: {code.co_code.hex()}")
print(f"Stack size: {code.co_stacksize}")
print(f"Flags: {code.co_flags}")

import dis
dis.dis(example)
```

---

## 3.2 Global Interpreter Lock (GIL)

```
┌──────────────────────────────────────────────────────────┐
│                    GIL Behavior                          │
│                                                          │
│  Thread 1: ████░░░░████░░░░████     (CPU-bound)         │
│  Thread 2: ░░░░████░░░░████░░░░     (CPU-bound)         │
│  Thread 3: ░░░░░░░░░░░░░░░░░░░░     (starved)           │
│                                                          │
│  ████ = Holding GIL (executing Python bytecode)          │
│  ░░░░ = Waiting for GIL                                  │
│                                                          │
│  GIL is RELEASED during:                                 │
│    - I/O operations (file, network, sleep)               │
│    - C extensions (numpy, etc.)                          │
│    - time.sleep()                                        │
│                                                          │
│  GIL is REQUIRED for:                                    │
│    - Python bytecode execution                           │
│    - Reference count modifications                       │
│                                                          │
│  Switch interval: sys.getswitchinterval() → 5ms default  │
└──────────────────────────────────────────────────────────┘
```

```python
import threading
import time
import sys

print(f"GIL switch interval: {sys.getswitchinterval()}s")

# === CPU-bound: GIL makes threads SLOWER than single-threaded ===
def cpu_bound(n):
    total = 0
    for i in range(n):
        total += i * i
    return total

N = 20_000_000

# Single-threaded
start = time.perf_counter()
cpu_bound(N)
cpu_bound(N)
print(f"Sequential: {time.perf_counter() - start:.2f}s")

# Multi-threaded (SLOWER due to GIL contention)
start = time.perf_counter()
t1 = threading.Thread(target=cpu_bound, args=(N,))
t2 = threading.Thread(target=cpu_bound, args=(N,))
t1.start(); t2.start()
t1.join(); t2.join()
print(f"Threaded:   {time.perf_counter() - start:.2f}s")


# === I/O-bound: GIL is released, threads help ===
import urllib.request

def io_bound(url):
    urllib.request.urlopen(url).read()

urls = ["https://httpbin.org/delay/1"] * 4

# Sequential I/O
start = time.perf_counter()
for url in urls:
    io_bound(url)
print(f"Sequential I/O: {time.perf_counter() - start:.2f}s")

# Threaded I/O (much faster)
start = time.perf_counter()
threads = [threading.Thread(target=io_bound, args=(url,)) for url in urls]
for t in threads: t.start()
for t in threads: t.join()
print(f"Threaded I/O:   {time.perf_counter() - start:.2f}s")


# === Python 3.13+ free-threaded mode (PEP 703) ===
# Build with: ./configure --disable-gil
# Check: python -X gil=0
# or: sys.flags.nogil (if available)
```

---

## 3.3 Reference Counting & Garbage Collection

```python
import sys
import gc

# === Reference Counting ===
a = []                # refcount = 1
print(sys.getrefcount(a) - 1)  # -1 because getrefcount adds a temp ref

b = a                 # refcount = 2
c = [a, a]            # refcount = 4 (list holds 2 refs)
del b                 # refcount = 3
c.pop()               # refcount = 2

# When refcount reaches 0 → immediately deallocated (deterministic)


# === Circular References ===
class Node:
    def __init__(self, name):
        self.name = name
        self.ref = None
    def __del__(self):
        print(f"  Deleting {self.name}")

# Create circular reference
a = Node("A")
b = Node("B")
a.ref = b
b.ref = a  # Circular!

# Delete external references
del a
del b
# __del__ NOT called yet! Refcount is 1 for each (circular ref).
# The garbage collector must handle this.


# === Garbage Collector (gc module) ===
print(f"GC enabled: {gc.isenabled()}")
print(f"Thresholds: {gc.get_threshold()}")  # (700, 10, 10)
# Generation 0: collected every 700 allocations - deallocations
# Generation 1: collected every 10 gen-0 collections
# Generation 2: collected every 10 gen-1 collections

# Force collection
collected = gc.collect()
print(f"Objects collected: {collected}")
# Now the Node __del__ methods will be called

# Track objects
gc.set_debug(gc.DEBUG_STATS)

# Get all objects tracked by GC
all_objects = gc.get_objects()
print(f"Total tracked objects: {len(all_objects)}")


# === weakref — avoid preventing garbage collection ===
import weakref

class Cache:
    def __init__(self, name):
        self.name = name

obj = Cache("important")
weak = weakref.ref(obj)

print(weak())        # <Cache object>
print(weak().name)   # "important"

del obj
print(weak())        # None — object was garbage collected

# WeakValueDictionary for caches
cache = weakref.WeakValueDictionary()
obj = Cache("temp")
cache["key"] = obj
print(cache["key"])  # <Cache object>
del obj
# cache["key"]  # KeyError — it's been garbage collected
```

---

## 3.4 Bytecode Deep Dive

```python
import dis
import opcode

# === Inspecting bytecode ===
def calculate(a, b):
    result = a * b + 2
    if result > 100:
        return result
    return 0

dis.dis(calculate)
# Output (CPython 3.12+):
#   0 RESUME                   0
#
#   1 LOAD_FAST                0 (a)
#     LOAD_FAST                1 (b)
#     BINARY_OP                5 (*)
#     LOAD_CONST               1 (2)
#     BINARY_OP                0 (+)
#     STORE_FAST               2 (result)
#
#   2 LOAD_FAST                2 (result)
#     LOAD_CONST               2 (100)
#     COMPARE_OP               4 (>)
#     POP_JUMP_IF_FALSE        ...
#
#   3 LOAD_FAST                2 (result)
#     RETURN_VALUE
#
#   4 LOAD_CONST               3 (0)
#     RETURN_VALUE


# === Bytecode object analysis ===
code = calculate.__code__

print("Bytecode bytes:", code.co_code.hex())
print("Constants:", code.co_consts)     # (None, 2, 100, 0)
print("Varnames:", code.co_varnames)     # ('a', 'b', 'result')
print("Stack size:", code.co_stacksize)

# Iterate over instructions
for instruction in dis.get_instructions(calculate):
    print(f"{instruction.offset:4d}  {instruction.opname:<25s} "
          f"{instruction.argrepr}")


# === Compiler optimizations ===
def optimized():
    x = 2 + 3       # Constant folding → LOAD_CONST 5
    y = "hello" * 3  # String multiplication → LOAD_CONST "hellohellohello"
    z = (1, 2, 3)    # Tuple is a constant
    return x + y

dis.dis(optimized)
# You'll see LOAD_CONST with pre-computed values


# === Modifying bytecode (educational only!) ===
import types

def original():
    return 42

# Create modified code object
old_code = original.__code__
new_code = old_code.replace(co_consts=(None, 100))  # Change 42 to 100

original.__code__ = new_code
print(original())  # 100!
```

---

## 3.5 Python Interpreter Lifecycle

```python
# The complete lifecycle when you run: python script.py

"""
1. INITIALIZATION (Py_Initialize)
   ├── Initialize memory allocator
   ├── Create interpreter state
   ├── Create main thread state
   ├── Initialize built-in modules (sys, builtins, _io)
   ├── Initialize sys.path
   ├── Initialize signal handling
   └── Initialize import system

2. COMPILATION
   ├── Read source file
   ├── Tokenize (lexical analysis)
   ├── Parse into AST
   ├── Compile AST to bytecode
   └── Create code object

3. EXECUTION
   ├── Create __main__ module
   ├── Set __name__ = "__main__"
   ├── Execute bytecode in PVM (ceval.c main loop)
   │   ├── Fetch opcode
   │   ├── Decode arguments
   │   ├── Execute (giant switch statement)
   │   ├── Check for GIL switch / signals every N instructions
   │   └── Repeat
   └── Handle exceptions

4. FINALIZATION (Py_Finalize)
   ├── Call atexit registered functions
   ├── Wait for non-daemon threads
   ├── Run garbage collection
   ├── Destroy all modules
   ├── Free memory
   └── Return exit code to OS
"""

import atexit
import sys

def cleanup():
    print("Cleaning up...")

atexit.register(cleanup)

# sys hooks
print(f"Python version: {sys.version}")
print(f"Platform: {sys.platform}")
print(f"Path: {sys.path[:3]}")
print(f"Modules loaded: {len(sys.modules)}")
print(f"Recursion limit: {sys.getrecursionlimit()}")
```

---

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 4. CONCURRENCY
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## Concurrency Overview

```
┌───────────────────────────────────────────────────┐
│               CONCURRENCY MODELS                  │
├───────────────────────────────────────────────────┤
│                                                   │
│  Threading        Multiprocessing      AsyncIO    │
│  ─────────        ───────────────      ───────    │
│  Multiple         Multiple             Single     │
│  threads,         processes,           thread,    │
│  shared           separate             event      │
│  memory           memory               loop       │
│                                                   │
│  Best for:        Best for:            Best for:  │
│  I/O-bound        CPU-bound            I/O-bound  │
│  tasks            tasks                (high       │
│                                        concurrency│
│                                        10k+       │
│                                        connections)│
│                                                   │
│  GIL: Yes         GIL: Bypassed        GIL: N/A  │
│  (limits CPU)     (each has own)       (single    │
│                                        thread)    │
└───────────────────────────────────────────────────┘
```

## 4.1 Multithreading

```python
import threading
import time
import queue
from concurrent.futures import ThreadPoolExecutor, as_completed

# === Basic Threading ===
def worker(name: str, delay: float):
    print(f"[{name}] Starting")
    time.sleep(delay)
    print(f"[{name}] Done")

threads = []
for i in range(3):
    t = threading.Thread(target=worker, args=(f"Thread-{i}", 1),
                        daemon=False)
    threads.append(t)
    t.start()

for t in threads:
    t.join(timeout=5)  # Wait for completion


# === Thread Synchronization ===

# Lock — mutual exclusion
class ThreadSafeCounter:
    def __init__(self):
        self._count = 0
        self._lock = threading.Lock()

    def increment(self):
        with self._lock:  # Context manager — auto release
            self._count += 1

    @property
    def count(self):
        with self._lock:
            return self._count

counter = ThreadSafeCounter()
threads = [threading.Thread(target=lambda: [counter.increment() for _ in range(100_000)])
           for _ in range(10)]
for t in threads: t.start()
for t in threads: t.join()
print(f"Counter: {counter.count}")  # Exactly 1,000,000


# RLock — reentrant lock (same thread can acquire multiple times)
class ReentrantExample:
    def __init__(self):
        self._lock = threading.RLock()

    def method_a(self):
        with self._lock:
            return self.method_b()  # Same thread re-acquires

    def method_b(self):
        with self._lock:
            return "OK"


# Semaphore — limit concurrent access
class ConnectionPool:
    def __init__(self, max_connections: int):
        self._semaphore = threading.Semaphore(max_connections)

    def get_connection(self):
        self._semaphore.acquire()
        print(f"Connection acquired by {threading.current_thread().name}")
        return self

    def release_connection(self):
        self._semaphore.release()
        print(f"Connection released by {threading.current_thread().name}")


# Event — thread signaling
class DataPipeline:
    def __init__(self):
        self.data_ready = threading.Event()
        self.data = None

    def producer(self):
        time.sleep(1)
        self.data = {"result": 42}
        self.data_ready.set()  # Signal consumers

    def consumer(self):
        self.data_ready.wait()  # Block until set
        print(f"Received: {self.data}")


# Condition — complex synchronization
class BoundedBuffer:
    def __init__(self, capacity: int):
        self.buffer = []
        self.capacity = capacity
        self.condition = threading.Condition()

    def produce(self, item):
        with self.condition:
            while len(self.buffer) >= self.capacity:
                self.condition.wait()
            self.buffer.append(item)
            self.condition.notify_all()

    def consume(self):
        with self.condition:
            while not self.buffer:
                self.condition.wait()
            item = self.buffer.pop(0)
            self.condition.notify_all()
            return item


# Barrier — synchronize N threads at a point
barrier = threading.Barrier(3)

def barrier_worker(name):
    print(f"{name}: preparing...")
    time.sleep(0.5)
    barrier.wait()  # All 3 must reach here before any proceed
    print(f"{name}: proceeding!")


# === Thread-safe Queue ===
def producer(q: queue.Queue):
    for i in range(10):
        q.put(i)
    q.put(None)  # Sentinel

def consumer(q: queue.Queue):
    while True:
        item = q.get()
        if item is None:
            break
        print(f"Processing: {item}")
        q.task_done()

q = queue.Queue(maxsize=5)
p = threading.Thread(target=producer, args=(q,))
c = threading.Thread(target=consumer, args=(q,))
p.start(); c.start()
p.join(); c.join()


# === ThreadPoolExecutor (preferred for production) ===
def fetch_url(url: str) -> dict:
    time.sleep(0.5)  # Simulate I/O
    return {"url": url, "status": 200}

urls = [f"https://api.example.com/item/{i}" for i in range(20)]

with ThreadPoolExecutor(max_workers=5) as executor:
    # Submit returns futures
    futures = {executor.submit(fetch_url, url): url for url in urls}

    for future in as_completed(futures):
        url = futures[future]
        try:
            result = future.result(timeout=10)
            print(f"{url} → {result['status']}")
        except Exception as e:
            print(f"{url} → Error: {e}")

    # Or use map for simpler cases
    results = list(executor.map(fetch_url, urls))


# === Thread-local storage ===
local_data = threading.local()

def thread_func(value):
    local_data.value = value  # Each thread gets its own copy
    time.sleep(0.1)
    print(f"{threading.current_thread().name}: {local_data.value}")
```

---

## 4.2 Multiprocessing

```python
import multiprocessing as mp
from multiprocessing import Process, Pool, Queue, Pipe, Manager, Value, Array
import os
import time

# === Basic Process ===
def cpu_intensive(n: int) -> int:
    """Each process has its own GIL and memory space."""
    print(f"PID: {os.getpid()}, Parent: {os.getppid()}")
    return sum(i * i for i in range(n))

if __name__ == "__main__":
    # Always guard with __name__ check (required on Windows/macOS)

    # Method 1: Process
    p = Process(target=cpu_intensive, args=(10_000_000,))
    p.start()
    p.join()
    print(f"Exit code: {p.exitcode}")


    # Method 2: Pool (map/starmap)
    with Pool(processes=mp.cpu_count()) as pool:
        # map — parallel map
        args = [5_000_000] * mp.cpu_count()
        results = pool.map(cpu_intensive, args)
        print(f"Results: {results}")

        # imap — lazy, ordered
        for result in pool.imap(cpu_intensive, args):
            print(result)

        # imap_unordered — lazy, fastest-first
        for result in pool.imap_unordered(cpu_intensive, args):
            print(result)

        # apply_async — single task, non-blocking
        future = pool.apply_async(cpu_intensive, (10_000_000,))
        result = future.get(timeout=30)


    # === Inter-Process Communication ===

    # Queue (thread/process safe)
    def producer(q: Queue):
        for i in range(5):
            q.put(i)
        q.put(None)  # Sentinel

    def consumer(q: Queue):
        while True:
            item = q.get()
            if item is None:
                break
            print(f"Got: {item}")

    q = Queue()
    p1 = Process(target=producer, args=(q,))
    p2 = Process(target=consumer, args=(q,))
    p1.start(); p2.start()
    p1.join(); p2.join()


    # Pipe (two-way communication between 2 processes)
    def sender(conn):
        conn.send({"data": [1, 2, 3]})
        conn.close()

    parent_conn, child_conn = Pipe()
    p = Process(target=sender, args=(child_conn,))
    p.start()
    print(parent_conn.recv())  # {"data": [1, 2, 3]}
    p.join()


    # Shared Memory (Value, Array)
    shared_counter = Value('i', 0)  # 'i' = integer
    shared_array = Array('d', [0.0] * 10)  # 'd' = double

    def increment_shared(counter, lock):
        for _ in range(100_000):
            with lock:
                counter.value += 1

    lock = mp.Lock()
    processes = [Process(target=increment_shared, args=(shared_counter, lock))
                 for _ in range(4)]
    for p in processes: p.start()
    for p in processes: p.join()
    print(f"Shared counter: {shared_counter.value}")  # 400,000


    # Manager (shared objects — dicts, lists, etc.)
    with Manager() as manager:
        shared_dict = manager.dict()
        shared_list = manager.list()

        def worker(d, l, idx):
            d[idx] = idx ** 2
            l.append(idx)

        processes = [Process(target=worker, args=(shared_dict, shared_list, i))
                     for i in range(5)]
        for p in processes: p.start()
        for p in processes: p.join()

        print(dict(shared_dict))  # {0: 0, 1: 1, 2: 4, 3: 9, 4: 16}
        print(list(shared_list))  # [0, 1, 2, 3, 4] (order may vary)


    # === ProcessPoolExecutor (modern API) ===
    from concurrent.futures import ProcessPoolExecutor, as_completed

    with ProcessPoolExecutor(max_workers=4) as executor:
        futures = [executor.submit(cpu_intensive, 5_000_000) for _ in range(8)]
        for f in as_completed(futures):
            print(f.result())
```

---

## 4.3 AsyncIO

```python
import asyncio
import aiohttp  # pip install aiohttp
import time

# === Coroutines & await ===
async def fetch_data(url: str, delay: float) -> dict:
    """An async function (coroutine function).
    Calling it returns a coroutine object, not the result."""
    print(f"Fetching {url}...")
    await asyncio.sleep(delay)  # Non-blocking sleep
    return {"url": url, "data": "response"}


async def main():
    # Sequential (slow)
    start = time.perf_counter()
    result1 = await fetch_data("url1", 1)
    result2 = await fetch_data("url2", 1)
    print(f"Sequential: {time.perf_counter() - start:.2f}s")  # ~2s

    # Concurrent (fast)
    start = time.perf_counter()
    result1, result2 = await asyncio.gather(
        fetch_data("url1", 1),
        fetch_data("url2", 1),
    )
    print(f"Concurrent: {time.perf_counter() - start:.2f}s")  # ~1s

asyncio.run(main())


# === Task management ===
async def task_examples():
    # Create tasks (schedule coroutines concurrently)
    task1 = asyncio.create_task(fetch_data("url1", 2), name="task-1")
    task2 = asyncio.create_task(fetch_data("url2", 1), name="task-2")

    # Wait for specific task
    result = await task1
    print(result)

    # Wait with timeout
    try:
        result = await asyncio.wait_for(
            fetch_data("slow_url", 10),
            timeout=2.0
        )
    except asyncio.TimeoutError:
        print("Timed out!")

    # Wait for first completed
    tasks = [
        asyncio.create_task(fetch_data(f"url{i}", i))
        for i in range(1, 4)
    ]
    done, pending = await asyncio.wait(
        tasks,
        return_when=asyncio.FIRST_COMPLETED
    )
    print(f"First done: {done.pop().result()}")
    for task in pending:
        task.cancel()

    # TaskGroup (Python 3.11+) — structured concurrency
    async with asyncio.TaskGroup() as tg:
        t1 = tg.create_task(fetch_data("url1", 1))
        t2 = tg.create_task(fetch_data("url2", 1))
    # Both are guaranteed done here
    print(t1.result(), t2.result())


# === Async generators ===
async def async_range(start: int, stop: int, delay: float):
    for i in range(start, stop):
        await asyncio.sleep(delay)
        yield i

async def consume_async_gen():
    async for value in async_range(0, 5, 0.1):
        print(value)


# === Async context managers ===
class AsyncDatabase:
    async def __aenter__(self):
        print("Opening connection...")
        await asyncio.sleep(0.1)
        return self

    async def __aexit__(self, exc_type, exc_val, exc_tb):
        print("Closing connection...")
        await asyncio.sleep(0.1)

    async def query(self, sql: str):
        await asyncio.sleep(0.1)
        return [{"id": 1}]

async def use_db():
    async with AsyncDatabase() as db:
        results = await db.query("SELECT * FROM users")
        print(results)


# === Semaphore (rate limiting) ===
async def rate_limited_fetch(sem: asyncio.Semaphore, url: str):
    async with sem:  # Only N concurrent requests
        return await fetch_data(url, 0.5)

async def crawl():
    sem = asyncio.Semaphore(10)  # Max 10 concurrent requests
    urls = [f"url_{i}" for i in range(100)]
    tasks = [rate_limited_fetch(sem, url) for url in urls]
    results = await asyncio.gather(*tasks)
    return results


# === Async Queue ===
async def async_producer(queue: asyncio.Queue):
    for i in range(10):
        await queue.put(i)
        await asyncio.sleep(0.1)
    await queue.put(None)

async def async_consumer(queue: asyncio.Queue, name: str):
    while True:
        item = await queue.get()
        if item is None:
            await queue.put(None)  # Propagate sentinel
            break
        print(f"{name} processing: {item}")
        queue.task_done()

async def pipeline():
    queue = asyncio.Queue(maxsize=5)
    await asyncio.gather(
        async_producer(queue),
        async_consumer(queue, "Consumer-1"),
        async_consumer(queue, "Consumer-2"),
    )


# === Real-world: HTTP client with aiohttp ===
async def fetch_many_urls():
    urls = [f"https://httpbin.org/delay/{i%3}" for i in range(10)]

    async with aiohttp.ClientSession() as session:
        async def fetch_one(url):
            async with session.get(url) as response:
                return await response.json()

        tasks = [fetch_one(url) for url in urls]
        results = await asyncio.gather(*tasks, return_exceptions=True)
        return results


# === Event Loop internals ===
async def event_loop_demo():
    loop = asyncio.get_running_loop()

    # Run blocking code in executor
    import functools
    result = await loop.run_in_executor(
        None,  # Default executor (ThreadPoolExecutor)
        functools.partial(time.sleep, 1)  # Blocking call
    )

    # Schedule callback
    def callback(future):
        print(f"Callback: {future.result()}")

    future = loop.run_in_executor(None, lambda: 42)
    future.add_done_callback(callback)
    await future
```

---

## 4.4 Futures & Executors

```python
from concurrent.futures import (
    ThreadPoolExecutor, ProcessPoolExecutor,
    Future, as_completed, wait, FIRST_COMPLETED
)
import time

# === Future object ===
def long_computation(x: int) -> int:
    time.sleep(1)
    if x == 3:
        raise ValueError("Bad value!")
    return x ** 2

with ThreadPoolExecutor(max_workers=4) as executor:
    # Submit returns a Future
    future: Future = executor.submit(long_computation, 5)

    # Future methods
    print(future.done())        # False (still running)
    print(future.running())     # True
    print(future.cancelled())   # False

    result = future.result(timeout=5)  # Blocks until done
    print(f"Result: {result}")         # 25

    # Callbacks
    def on_complete(f: Future):
        if f.exception():
            print(f"Error: {f.exception()}")
        else:
            print(f"Done: {f.result()}")

    future2 = executor.submit(long_computation, 3)
    future2.add_done_callback(on_complete)

    # as_completed — iterate in completion order
    futures = [executor.submit(long_computation, i) for i in range(5)]
    for f in as_completed(futures):
        try:
            print(f"Completed: {f.result()}")
        except ValueError as e:
            print(f"Failed: {e}")

    # wait — wait for specific conditions
    futures = [executor.submit(long_computation, i) for i in [1, 2, 4]]
    done, not_done = wait(futures, return_when=FIRST_COMPLETED)
    print(f"First result: {done.pop().result()}")


# === Custom Executor pattern ===
class RetryExecutor:
    """Executor wrapper with automatic retry."""
    def __init__(self, max_workers: int, max_retries: int = 3):
        self._executor = ThreadPoolExecutor(max_workers=max_workers)
        self._max_retries = max_retries

    def submit(self, fn, *args, **kwargs) -> Future:
        return self._executor.submit(self._retry_wrapper, fn, *args, **kwargs)

    def _retry_wrapper(self, fn, *args, **kwargs):
        last_exception = None
        for attempt in range(self._max_retries):
            try:
                return fn(*args, **kwargs)
            except Exception as e:
                last_exception = e
                time.sleep(2 ** attempt)  # Exponential backoff
        raise last_exception

    def __enter__(self):
        return self

    def __exit__(self, *args):
        self._executor.shutdown(wait=True)
```

---

## 4.5 Parallel Processing Strategies

```python
"""
Decision matrix for choosing concurrency strategy:

┌──────────────┬─────────────┬──────────────┬────────────┐
│  Workload    │  Threading  │  Multiproc.  │  AsyncIO   │
├──────────────┼─────────────┼──────────────┼────────────┤
│  CPU-bound   │     ✗       │     ✓✓✓      │     ✗      │
│  I/O-bound   │     ✓✓      │     ✓        │     ✓✓✓    │
│  (few tasks) │             │              │            │
│  I/O-bound   │     ✓       │     ✗        │     ✓✓✓    │
│  (10k+ tasks)│             │              │            │
│  Mixed       │     ✓       │     ✓✓       │     ✓✓     │
│              │             │              │ (+ executor)│
└──────────────┴─────────────┴──────────────┴────────────┘
"""

# === Hybrid: AsyncIO + ProcessPoolExecutor for mixed workloads ===
import asyncio
from concurrent.futures import ProcessPoolExecutor

def cpu_work(data: list) -> float:
    """CPU-intensive — runs in separate process."""
    return sum(x ** 2 for x in data)

async def io_work(url: str) -> str:
    """I/O-intensive — runs in event loop."""
    await asyncio.sleep(0.5)
    return f"fetched {url}"

async def hybrid_pipeline():
    loop = asyncio.get_running_loop()

    # CPU work in process pool
    with ProcessPoolExecutor() as pool:
        cpu_future = loop.run_in_executor(
            pool,
            cpu_work,
            list(range(10_000_000))
        )

        # I/O work concurrently
        io_tasks = [io_work(f"url_{i}") for i in range(10)]

        # Run both concurrently
        cpu_result, *io_results = await asyncio.gather(
            cpu_future,
            *io_tasks
        )

    print(f"CPU result: {cpu_result}")
    print(f"IO results: {len(io_results)} completed")

# asyncio.run(hybrid_pipeline())


# === MapReduce pattern ===
from multiprocessing import Pool
from functools import reduce
from itertools import chain

def chunk_list(lst, n_chunks):
    """Split list into n chunks."""
    size = len(lst) // n_chunks + 1
    return [lst[i:i+size] for i in range(0, len(lst), size)]

def map_func(chunk):
    """Process one chunk."""
    return {word: chunk.count(word) for word in set(chunk)}

def reduce_func(result1, result2):
    """Merge two results."""
    for key, value in result2.items():
        result1[key] = result1.get(key, 0) + value
    return result1

def parallel_word_count(words: list[str], n_workers: int = 4) -> dict:
    chunks = chunk_list(words, n_workers)
    with Pool(n_workers) as pool:
        mapped = pool.map(map_func, chunks)
    return reduce(reduce_func, mapped)

words = "the quick brown fox jumps over the lazy dog the".split()
print(parallel_word_count(words * 10000))
```

---

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 5. PERFORMANCE OPTIMIZATION
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## 5.1 Profiling Tools

```python
import cProfile
import pstats
import time
import timeit

# === timeit — micro-benchmarks ===
# Command line: python -m timeit "'-'.join(str(i) for i in range(100))"

print(timeit.timeit(
    "'-'.join(str(i) for i in range(100))",
    number=10_000
))

# Compare approaches
setup = "data = list(range(1000))"
approaches = {
    "list comp": "[x**2 for x in data]",
    "map":       "list(map(lambda x: x**2, data))",
    "for loop":  """
result = []
for x in data:
    result.append(x**2)
""",
}

for name, code in approaches.items():
    t = timeit.timeit(code, setup=setup, number=10_000)
    print(f"{name:15s}: {t:.4f}s")


# === cProfile — function-level profiling ===
def slow_function():
    total = 0
    for i in range(1_000_000):
        total += i ** 2
    return total

def main_program():
    slow_function()
    sorted(range(100_000), reverse=True)
    time.sleep(0.1)

# Profile and print stats
cProfile.run('main_program()', sort='cumulative')

# Or save to file and analyze
cProfile.run('main_program()', 'profile_output.prof')
stats = pstats.Stats('profile_output.prof')
stats.strip_dirs().sort_stats('cumulative').print_stats(10)


# === line_profiler — line-by-line profiling ===
# pip install line_profiler
# Decorate function with @profile, then run:
# kernprof -l -v script.py

# @profile  # uncomment when using kernprof
def function_to_profile():
    a = [i ** 2 for i in range(10000)]
    b = sorted(a, reverse=True)
    c = sum(b)
    return c


# === memory_profiler ===
# pip install memory-profiler
# @profile  # uncomment when using: python -m memory_profiler script.py
def memory_intensive():
    a = [0] * 1_000_000    # ~8 MB
    b = a[:]                # ~8 MB copy
    del a                   # Free ~8 MB
    return sum(b)


# === tracemalloc — built-in memory profiling ===
import tracemalloc

tracemalloc.start()

# Your code here
data = {i: str(i) * 100 for i in range(10_000)}

snapshot = tracemalloc.take_snapshot()
top_stats = snapshot.statistics('lineno')

print("\n[ Top 5 Memory Consumers ]")
for stat in top_stats[:5]:
    print(stat)

current, peak = tracemalloc.get_traced_memory()
print(f"\nCurrent: {current / 1024:.1f} KB")
print(f"Peak:    {peak / 1024:.1f} KB")
tracemalloc.stop()


# === py-spy — sampling profiler (no code changes) ===
# pip install py-spy
# py-spy record -o profile.svg -- python script.py
# py-spy top -- python script.py
```

---

## 5.2 Memory Optimization

```python
import sys

# === __slots__ — eliminate per-instance __dict__ ===
class PointWithDict:
    def __init__(self, x, y, z):
        self.x = x
        self.y = y
        self.z = z

class PointWithSlots:
    __slots__ = ('x', 'y', 'z')
    def __init__(self, x, y, z):
        self.x = x
        self.y = y
        self.z = z

p1 = PointWithDict(1, 2, 3)
p2 = PointWithSlots(1, 2, 3)

print(f"With __dict__: {sys.getsizeof(p1) + sys.getsizeof(p1.__dict__)} bytes")
print(f"With __slots__: {sys.getsizeof(p2)} bytes")

# For 1 million points: saves ~40-60% memory


# === Named tuples vs classes vs dataclasses ===
from collections import namedtuple
from dataclasses import dataclass

PointNT = namedtuple('PointNT', ['x', 'y', 'z'])

@dataclass(slots=True, frozen=True)  # Python 3.10+
class PointDC:
    x: float
    y: float
    z: float

p_nt = PointNT(1, 2, 3)
p_dc = PointDC(1, 2, 3)
print(f"Namedtuple: {sys.getsizeof(p_nt)} bytes")
print(f"Dataclass (slots): {sys.getsizeof(p_dc)} bytes")


# === array module — typed arrays (less memory than list) ===
from array import array

list_of_ints = list(range(1_000_000))
array_of_ints = array('i', range(1_000_000))

print(f"List:  {sys.getsizeof(list_of_ints):>12,} bytes")  # ~8 MB
print(f"Array: {sys.getsizeof(array_of_ints):>12,} bytes")  # ~4 MB


# === Interning strings ===
import sys

strings = [sys.intern(f"key_{i % 100}") for i in range(1_000_000)]
# Instead of 1M string objects, only 100 unique objects exist


# === Generator expressions vs list comprehensions ===
# List: stores all in memory
total_list = sum([x ** 2 for x in range(10_000_000)])  # ~80 MB

# Generator: streams one at a time
total_gen = sum(x ** 2 for x in range(10_000_000))     # ~0 MB extra


# === compact dict (Python 3.6+) ===
# Python 3.6+ dicts are 20-25% more memory-efficient
# and maintain insertion order


# === __del__ and preventing leaks ===
import weakref

class HeavyObject:
    def __init__(self, data):
        self.data = data

# Cache with weak references — allows GC
cache = weakref.WeakValueDictionary()

def get_or_create(key):
    obj = cache.get(key)
    if obj is None:
        obj = HeavyObject(key)
        cache[key] = obj
    return obj
```

---

## 5.3 Lazy Evaluation, Generators & Iterators

```python
# === Iterator Protocol ===
class FibonacciIterator:
    """Infinite Fibonacci sequence — lazy, constant memory."""

    def __init__(self):
        self.a, self.b = 0, 1

    def __iter__(self):
        return self

    def __next__(self) -> int:
        value = self.a
        self.a, self.b = self.b, self.a + self.b
        return value

# Usage
from itertools import islice
fib = FibonacciIterator()
first_10 = list(islice(fib, 10))
print(first_10)  # [0, 1, 1, 2, 3, 5, 8, 13, 21, 34]


# === Generator Functions ===
def fibonacci():
    """Same as above, but much cleaner."""
    a, b = 0, 1
    while True:
        yield a
        a, b = b, a + b

# Generator is lazy — produces values on demand
gen = fibonacci()
print(next(gen))  # 0
print(next(gen))  # 1
print(next(gen))  # 1


# === Generator Pipelines (Unix pipes) ===
def read_lines(filename):
    """Stage 1: Read lines lazily."""
    with open(filename) as f:
        for line in f:
            yield line.strip()

def parse_json_lines(lines):
    """Stage 2: Parse each line."""
    import json
    for line in lines:
        if line:
            yield json.loads(line)

def filter_active(records):
    """Stage 3: Filter."""
    for record in records:
        if record.get("active"):
            yield record

def extract_emails(records):
    """Stage 4: Transform."""
    for record in records:
        yield record["email"]

# Pipeline — processes ONE record at a time through ALL stages
# Memory: O(1) regardless of file size!
# pipeline = extract_emails(filter_active(parse_json_lines(read_lines("data.jsonl"))))
# for email in pipeline:
#     print(email)


# === Generator .send(), .throw(), .close() ===
def accumulator():
    """Coroutine-style generator with .send()"""
    total = 0
    while True:
        value = yield total
        if value is None:
            break
        total += value

acc = accumulator()
next(acc)           # Prime the generator (advance to first yield)
print(acc.send(10)) # 10
print(acc.send(20)) # 30
print(acc.send(30)) # 60
acc.close()


# === yield from — delegate to sub-generator ===
def flatten(nested):
    """Recursively flatten nested iterables."""
    for item in nested:
        if isinstance(item, (list, tuple)):
            yield from flatten(item)  # Delegates to sub-generator
        else:
            yield item

data = [1, [2, [3, 4]], [5, [6, [7]]]]
print(list(flatten(data)))  # [1, 2, 3, 4, 5, 6, 7]


# === Lazy properties ===
class LazyProperty:
    """Descriptor that computes value once and caches it."""
    def __init__(self, func):
        self.func = func
        self.attr_name = f"_lazy_{func.__name__}"

    def __get__(self, obj, objtype=None):
        if obj is None:
            return self
        if not hasattr(obj, self.attr_name):
            setattr(obj, self.attr_name, self.func(obj))
        return getattr(obj, self.attr_name)

class DataAnalysis:
    def __init__(self, data):
        self.data = data

    @LazyProperty
    def statistics(self):
        """Expensive computation — only done once, when accessed."""
        print("Computing statistics...")
        return {
            "mean": sum(self.data) / len(self.data),
            "max": max(self.data),
            "min": min(self.data),
        }

analysis = DataAnalysis(range(1_000_000))
# statistics not computed yet
print(analysis.statistics)  # Computed now
print(analysis.statistics)  # Cached — not recomputed


# Python 3.8+ functools.cached_property
from functools import cached_property

class DataAnalysis2:
    def __init__(self, data):
        self.data = data

    @cached_property
    def statistics(self):
        return {"mean": sum(self.data) / len(self.data)}
```

---

## 5.4 Vectorization & C Extensions

```python
# === NumPy vectorization ===
import numpy as np
import timeit

size = 1_000_000

# Pure Python loop
def python_sum_squares(data):
    return sum(x**2 for x in data)

# NumPy vectorized
def numpy_sum_squares(data):
    return np.sum(data**2)

py_data = list(range(size))
np_data = np.arange(size)

py_time = timeit.timeit(lambda: python_sum_squares(py_data), number=10)
np_time = timeit.timeit(lambda: numpy_sum_squares(np_data), number=10)

print(f"Python: {py_time:.3f}s")
print(f"NumPy:  {np_time:.3f}s")
print(f"Speedup: {py_time/np_time:.1f}x")  # Often 50-100x


# === Built-in optimizations ===
# Use built-in functions (implemented in C)
data = list(range(1_000_000))

# Slow: Python loop
total = 0
for x in data:
    total += x

# Fast: C implementation
total = sum(data)

# Fast: min/max
minimum = min(data)

# Fast: sorted (TimSort in C)
sorted_data = sorted(data)

# Fast: map + built-in function
strings = list(map(str, data))  # Faster than [str(x) for x in data]


# === collections module — C-optimized data structures ===
from collections import deque, Counter, defaultdict

# deque: O(1) append/pop from both ends
d = deque(maxlen=1000)  # Bounded deque — auto-discards old items
d.append(1)
d.appendleft(0)
d.rotate(1)

# Counter: optimized counting
words = "the quick brown fox jumps over the lazy dog".split()
counts = Counter(words)
print(counts.most_common(3))

# defaultdict: no KeyError
graph = defaultdict(list)
edges = [(1, 2), (1, 3), (2, 4)]
for src, dst in edges:
    graph[src].append(dst)


# === Cython example ===
"""
# fibonacci.pyx
def fib_cython(int n):
    cdef int a = 0, b = 1, i
    for i in range(n):
        a, b = b, a + b
    return a

# setup.py
from setuptools import setup
from Cython.Build import cythonize
setup(ext_modules=cythonize("fibonacci.pyx"))

# Build: python setup.py build_ext --inplace
# Usage: from fibonacci import fib_cython
"""


# === ctypes — call C libraries directly ===
import ctypes

# Load C standard library
libc = ctypes.CDLL("libc.so.6")  # Linux
# libc = ctypes.CDLL("libc.dylib")  # macOS

# Call C functions
libc.printf(b"Hello from C! %d\n", 42)


# === struct module — efficient binary data ===
import struct

# Pack Python values into bytes (like C struct)
packed = struct.pack('!2I3s', 1, 2, b'abc')
print(packed)  # bytes
unpacked = struct.unpack('!2I3s', packed)
print(unpacked)  # (1, 2, b'abc')
```

---

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 6. ADVANCED PYTHON FEATURES
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## 6.1 Decorators

```python
import functools
import time
import logging
from typing import Callable, TypeVar, ParamSpec

P = ParamSpec('P')
R = TypeVar('R')

# === Basic decorator ===
def timer(func: Callable[P, R]) -> Callable[P, R]:
    @functools.wraps(func)  # Preserves __name__, __doc__, etc.
    def wrapper(*args: P.args, **kwargs: P.kwargs) -> R:
        start = time.perf_counter()
        result = func(*args, **kwargs)
        elapsed = time.perf_counter() - start
        print(f"{func.__name__} took {elapsed:.4f}s")
        return result
    return wrapper

@timer
def slow_function():
    """Docstring preserved by functools.wraps."""
    time.sleep(0.5)

slow_function()
print(slow_function.__name__)  # "slow_function" (not "wrapper")


# === Decorator with arguments ===
def retry(max_attempts: int = 3, delay: float = 1.0,
          exceptions: tuple = (Exception,)):
    """Retry decorator with exponential backoff."""
    def decorator(func: Callable[P, R]) -> Callable[P, R]:
        @functools.wraps(func)
        def wrapper(*args: P.args, **kwargs: P.kwargs) -> R:
            last_exception = None
            for attempt in range(1, max_attempts + 1):
                try:
                    return func(*args, **kwargs)
                except exceptions as e:
                    last_exception = e
                    wait = delay * (2 ** (attempt - 1))
                    print(f"Attempt {attempt} failed: {e}. "
                          f"Retrying in {wait}s...")
                    time.sleep(wait)
            raise last_exception
        return wrapper
    return decorator

@retry(max_attempts=3, delay=0.1, exceptions=(ConnectionError,))
def fetch_data():
    import random
    if random.random() < 0.7:
        raise ConnectionError("Network error")
    return {"data": "success"}


# === Class-based decorator ===
class CacheDecorator:
    """LRU cache with TTL (time-to-live)."""
    def __init__(self, ttl: float = 60.0):
        self.ttl = ttl
        self.cache = {}

    def __call__(self, func):
        @functools.wraps(func)
        def wrapper(*args):
            now = time.time()
            if args in self.cache:
                result, timestamp = self.cache[args]
                if now - timestamp < self.ttl:
                    return result
            result = func(*args)
            self.cache[args] = (result, now)
            return result
        wrapper.clear_cache = lambda: self.cache.clear()
        return wrapper

@CacheDecorator(ttl=30)
def expensive_query(user_id: int):
    time.sleep(1)  # Simulate DB query
    return {"user_id": user_id, "name": "Alice"}


# === Stacking decorators ===
def debug(func):
    @functools.wraps(func)
    def wrapper(*args, **kwargs):
        args_str = ", ".join(map(repr, args))
        kwargs_str = ", ".join(f"{k}={v!r}" for k, v in kwargs.items())
        print(f"Calling {func.__name__}({args_str}, {kwargs_str})")
        result = func(*args, **kwargs)
        print(f"{func.__name__} returned {result!r}")
        return result
    return wrapper

def validate_types(**type_hints):
    """Runtime type checking decorator."""
    def decorator(func):
        @functools.wraps(func)
        def wrapper(*args, **kwargs):
            import inspect
            sig = inspect.signature(func)
            bound = sig.bind(*args, **kwargs)
            for param_name, expected_type in type_hints.items():
                if param_name in bound.arguments:
                    value = bound.arguments[param_name]
                    if not isinstance(value, expected_type):
                        raise TypeError(
                            f"{param_name} must be {expected_type.__name__}, "
                            f"got {type(value).__name__}"
                        )
            return func(*args, **kwargs)
        return wrapper
    return decorator

@debug
@timer
@validate_types(x=int, y=int)
def add(x, y):
    return x + y

add(3, 4)
# Execution order: debug → timer → validate_types → add


# === Decorator for methods (handling self) ===
def require_auth(func):
    @functools.wraps(func)
    def wrapper(self, *args, **kwargs):
        if not self.is_authenticated:
            raise PermissionError("Authentication required")
        return func(self, *args, **kwargs)
    return wrapper

class API:
    def __init__(self, authenticated: bool):
        self.is_authenticated = authenticated

    @require_auth
    def get_data(self):
        return "secret data"
```

---

## 6.2 Context Managers

```python
from contextlib import contextmanager, asynccontextmanager, suppress
import time

# === Class-based context manager ===
class DatabaseTransaction:
    def __init__(self, connection):
        self.connection = connection
        self.cursor = None

    def __enter__(self):
        self.cursor = self.connection.cursor()
        self.connection.begin()
        return self.cursor

    def __exit__(self, exc_type, exc_val, exc_tb):
        if exc_type is not None:
            self.connection.rollback()
            print(f"Rolled back due to: {exc_val}")
            return False  # Re-raise exception
        self.connection.commit()
        return False


# === Generator-based context manager ===
@contextmanager
def timer_context(label: str):
    """Time a block of code."""
    start = time.perf_counter()
    try:
        yield  # The 'with' block executes here
    except Exception as e:
        print(f"[{label}] Error: {e}")
        raise
    finally:
        elapsed = time.perf_counter() - start
        print(f"[{label}] Took {elapsed:.4f}s")

with timer_context("processing"):
    time.sleep(0.5)


@contextmanager
def temporary_directory():
    """Create and auto-cleanup a temp directory."""
    import tempfile, shutil
    path = tempfile.mkdtemp()
    try:
        yield path
    finally:
        shutil.rmtree(path)

with temporary_directory() as tmpdir:
    print(f"Working in: {tmpdir}")
# Directory automatically cleaned up


# === Nested context managers ===
from contextlib import ExitStack

def process_files(filenames):
    with ExitStack() as stack:
        files = [stack.enter_context(open(f)) for f in filenames]
        # All files will be closed when block exits
        for f in files:
            print(f.readline())


# === suppress — ignore specific exceptions ===
with suppress(FileNotFoundError):
    import os
    os.remove("nonexistent_file.txt")
# No error raised


# === Reentrant context managers ===
@contextmanager
def indent_logger(level=0):
    prefix = "  " * level
    original_print = print

    def indented_print(*args, **kwargs):
        original_print(prefix, *args, **kwargs)

    import builtins
    builtins.print = indented_print
    try:
        yield
    finally:
        builtins.print = original_print


# === Async context manager ===
@asynccontextmanager
async def async_timer(label):
    start = time.perf_counter()
    try:
        yield
    finally:
        print(f"[{label}] {time.perf_counter() - start:.4f}s")

# async with async_timer("fetch"):
#     await asyncio.sleep(1)
```

---

## 6.3 Descriptors

```python
# Descriptors are objects that define __get__, __set__, or __delete__.
# They customize attribute access on classes.

# === Non-data descriptor (only __get__) ===
class LazyAttribute:
    """Compute once, then cache as instance attribute."""
    def __init__(self, func):
        self.func = func
        self.attr_name = func.__name__

    def __get__(self, obj, objtype=None):
        if obj is None:
            return self
        value = self.func(obj)
        # Store directly on instance — next access bypasses descriptor
        setattr(obj, self.attr_name, value)
        return value


# === Data descriptor (has __set__) ===
class Validated:
    """Type-checked and validated attribute."""
    def __init__(self, validator=None, type_=None):
        self.validator = validator
        self.type_ = type_

    def __set_name__(self, owner, name):
        """Called automatically when descriptor is assigned to class."""
        self.public_name = name
        self.private_name = f"_{name}"

    def __get__(self, obj, objtype=None):
        if obj is None:
            return self
        return getattr(obj, self.private_name, None)

    def __set__(self, obj, value):
        if self.type_ and not isinstance(value, self.type_):
            raise TypeError(
                f"{self.public_name} must be {self.type_.__name__}, "
                f"got {type(value).__name__}"
            )
        if self.validator and not self.validator(value):
            raise ValueError(
                f"Validation failed for {self.public_name}: {value}"
            )
        setattr(obj, self.private_name, value)

    def __delete__(self, obj):
        delattr(obj, self.private_name)


class User:
    name = Validated(type_=str, validator=lambda s: len(s) > 0)
    age = Validated(type_=int, validator=lambda n: 0 <= n <= 150)
    email = Validated(type_=str, validator=lambda s: '@' in s)

    def __init__(self, name, age, email):
        self.name = name
        self.age = age
        self.email = email

user = User("Alice", 30, "alice@example.com")
print(user.name)  # Alice

try:
    user.age = -1  # ValueError
except ValueError as e:
    print(e)

try:
    user.email = "invalid"  # ValueError
except ValueError as e:
    print(e)


# === How Python methods work (descriptor protocol) ===
class MyClass:
    def method(self):
        pass

# method is a function (non-data descriptor with __get__)
print(type(MyClass.__dict__['method']))  # <class 'function'>

# Accessing through instance triggers __get__, which returns a bound method
obj = MyClass()
print(type(obj.method))  # <class 'method'>

# That's why self is passed automatically:
# obj.method() → MyClass.method.__get__(obj, MyClass)() → method(obj)


# === property is a data descriptor ===
class Temperature:
    def __init__(self, celsius: float):
        self._celsius = celsius

    @property
    def celsius(self) -> float:
        return self._celsius

    @celsius.setter
    def celsius(self, value: float):
        if value < -273.15:
            raise ValueError("Temperature below absolute zero!")
        self._celsius = value

    @property
    def fahrenheit(self) -> float:
        return self._celsius * 9/5 + 32

    @fahrenheit.setter
    def fahrenheit(self, value: float):
        self.celsius = (value - 32) * 5/9

t = Temperature(100)
print(t.fahrenheit)   # 212.0
t.fahrenheit = 32
print(t.celsius)      # 0.0
```

---

## 6.4 Dataclasses

```python
from dataclasses import dataclass, field, asdict, astuple, replace
from typing import ClassVar
import json

# === Basic dataclass ===
@dataclass
class Point:
    x: float
    y: float
    z: float = 0.0  # Default value

p = Point(1.0, 2.0)
print(p)         # Point(x=1.0, y=2.0, z=0.0) — auto __repr__
print(p == Point(1.0, 2.0))  # True — auto __eq__


# === Full-featured dataclass ===
@dataclass(
    order=True,      # Auto-generate __lt__, __le__, __gt__, __ge__
    frozen=True,      # Immutable (hashable)
    slots=True,       # Use __slots__ (Python 3.10+)
)
class Employee:
    # Sort key (order matters for comparison!)
    sort_index: int = field(init=False, repr=False)

    name: str
    department: str
    salary: float
    skills: tuple[str, ...] = ()  # Immutable default (frozen requires it)

    # Class variable (not included in __init__)
    company: ClassVar[str] = "TechCorp"

    def __post_init__(self):
        # Called after __init__ — for computed fields
        object.__setattr__(self, 'sort_index', -self.salary)  # Needed for frozen

emp = Employee("Alice", "Engineering", 150_000, ("Python", "Go"))
print(emp)
print(hash(emp))  # Hashable because frozen=True

# Sorting (by salary, descending due to negative sort_index)
emps = [
    Employee("Alice", "Eng", 150_000),
    Employee("Bob", "Eng", 120_000),
    Employee("Charlie", "Sales", 130_000),
]
print(sorted(emps))  # Sorted by salary descending


# === Factory functions for mutable defaults ===
@dataclass
class Config:
    name: str
    tags: list[str] = field(default_factory=list)  # New list per instance
    metadata: dict = field(default_factory=dict)
    id: str = field(default_factory=lambda: str(__import__('uuid').uuid4()))

    def __post_init__(self):
        if not self.name:
            raise ValueError("Name cannot be empty")


# === Serialization ===
@dataclass
class APIResponse:
    status: int
    data: dict
    errors: list[str] = field(default_factory=list)

    def to_json(self) -> str:
        return json.dumps(asdict(self))

    @classmethod
    def from_json(cls, json_str: str) -> "APIResponse":
        return cls(**json.loads(json_str))

response = APIResponse(200, {"user": "Alice"})
json_str = response.to_json()
print(json_str)
restored = APIResponse.from_json(json_str)
print(restored)

# replace() — create modified copy
error_response = replace(response, status=500, errors=["Server error"])
print(error_response)


# === Inheritance ===
@dataclass
class Animal:
    name: str
    sound: str

@dataclass
class Dog(Animal):
    breed: str
    sound: str = "Woof"  # Override default

dog = Dog("Rex", breed="Labrador")
print(dog)  # Dog(name='Rex', sound='Woof', breed='Labrador')
```

---

## 6.5 Type Hints & Protocols

```python
from typing import (
    TypeVar, Generic, Protocol, runtime_checkable,
    TypeAlias, TypeGuard, overload, Final, Literal,
    Annotated, Never, Self, Unpack, TypeVarTuple
)
from collections.abc import Callable, Iterator, Sequence
from dataclasses import dataclass

# === Basic type hints ===
def greet(name: str, times: int = 1) -> str:
    return (f"Hello, {name}! " * times).strip()

# Collections
def process(
    items: list[int],
    mapping: dict[str, float],
    unique: set[str],
    pair: tuple[int, str],
    variable_tuple: tuple[int, ...],
) -> None: ...

# Optional and Union
from typing import Optional  # Optional[X] == X | None (3.10+)

def find(name: str) -> int | None:  # Python 3.10+
    return None

# Callable
Handler = Callable[[str, int], bool]
def register(handler: Handler) -> None: ...


# === Generics ===
T = TypeVar('T')
K = TypeVar('K')
V = TypeVar('V')

class Stack(Generic[T]):
    def __init__(self) -> None:
        self._items: list[T] = []

    def push(self, item: T) -> None:
        self._items.append(item)

    def pop(self) -> T:
        return self._items.pop()

    def peek(self) -> T:
        return self._items[-1]

    def __len__(self) -> int:
        return len(self._items)

int_stack: Stack[int] = Stack()
int_stack.push(42)
# int_stack.push("hello")  # mypy error!

# Bounded TypeVar
from typing import SupportsFloat
N = TypeVar('N', bound=SupportsFloat)

def double(x: N) -> N:
    return x * 2  # type: ignore


# === Protocols (Structural Subtyping) ===
@runtime_checkable
class Drawable(Protocol):
    def draw(self) -> str: ...
    @property
    def color(self) -> str: ...

class Circle:  # No inheritance needed!
    @property
    def color(self) -> str:
        return "red"
    def draw(self) -> str:
        return "Drawing circle"

def render(item: Drawable) -> str:
    return item.draw()

print(render(Circle()))  # Works!
print(isinstance(Circle(), Drawable))  # True


# === TypeGuard (narrowing) ===
def is_string_list(val: list[object]) -> TypeGuard[list[str]]:
    return all(isinstance(x, str) for x in val)

def process_strings(data: list[object]):
    if is_string_list(data):
        # mypy knows data is list[str] here
        print(", ".join(data))


# === Literal types ===
def set_mode(mode: Literal["read", "write", "append"]) -> None:
    pass

set_mode("read")    # OK
# set_mode("delete")  # mypy error


# === Final (prevent reassignment/override) ===
MAX_SIZE: Final = 100

class Base:
    @final
    def critical_method(self) -> None:
        pass  # Cannot be overridden in subclasses


# === Annotated (attach metadata) ===
from typing import Annotated

Positive = Annotated[int, "must be positive"]
Email = Annotated[str, "valid email format"]

def create_user(name: str, age: Positive, email: Email) -> None:
    pass


# === Self type (Python 3.11+) ===
class Builder:
    def set_name(self, name: str) -> Self:
        self.name = name
        return self

    def set_value(self, value: int) -> Self:
        self.value = value
        return self

# Works with subclasses too
class AdvancedBuilder(Builder):
    def set_extra(self, extra: str) -> Self:
        self.extra = extra
        return self

# Chaining returns correct type
b = AdvancedBuilder().set_name("test").set_extra("data")


# === Overloads ===
@overload
def parse(data: str) -> dict: ...
@overload
def parse(data: bytes) -> list: ...

def parse(data: str | bytes) -> dict | list:
    if isinstance(data, str):
        return {"parsed": data}
    return [data]
```

---

## 6.6 Dependency Injection

```python
from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from typing import Callable, TypeVar, Generic

T = TypeVar('T')

# === Manual Dependency Injection ===
class EmailService(ABC):
    @abstractmethod
    def send(self, to: str, subject: str, body: str) -> bool: ...

class SMTPService(EmailService):
    def send(self, to, subject, body) -> bool:
        print(f"SMTP: Sending to {to}")
        return True

class MockEmailService(EmailService):
    def __init__(self):
        self.sent = []
    def send(self, to, subject, body) -> bool:
        self.sent.append((to, subject, body))
        return True

class UserService:
    def __init__(self, email_service: EmailService):
        self._email = email_service  # Injected dependency

    def register(self, email: str):
        # Business logic...
        self._email.send(email, "Welcome!", "Thanks for joining!")

# Production
user_svc = UserService(SMTPService())

# Testing
mock_email = MockEmailService()
user_svc_test = UserService(mock_email)
user_svc_test.register("test@example.com")
assert len(mock_email.sent) == 1


# === Simple DI Container ===
class Container:
    """Lightweight dependency injection container."""

    def __init__(self):
        self._factories: dict[type, Callable] = {}
        self._singletons: dict[type, object] = {}

    def register(self, interface: type, factory: Callable,
                 singleton: bool = False):
        if singleton:
            instance = None
            original_factory = factory
            def singleton_factory():
                nonlocal instance
                if instance is None:
                    instance = original_factory()
                return instance
            self._factories[interface] = singleton_factory
        else:
            self._factories[interface] = factory
        return self

    def resolve(self, interface: type[T]) -> T:
        factory = self._factories.get(interface)
        if factory is None:
            raise KeyError(f"No registration for {interface}")
        return factory()

# Usage
container = Container()
container.register(EmailService, lambda: SMTPService(), singleton=True)
container.register(
    UserService,
    lambda: UserService(container.resolve(EmailService))
)

user_svc = container.resolve(UserService)
user_svc.register("alice@example.com")


# === Decorator-based injection ===
import functools
import inspect

_registry: dict[type, Callable] = {}

def injectable(cls):
    """Register a class as injectable."""
    _registry[cls] = cls
    for base in cls.__mro__:
        if base not in (cls, object):
            _registry[base] = cls
    return cls

def inject(func):
    """Auto-inject dependencies based on type hints."""
    @functools.wraps(func)
    def wrapper(*args, **kwargs):
        sig = inspect.signature(func)
        for name, param in sig.parameters.items():
            if name not in kwargs and param.annotation in _registry:
                kwargs[name] = _registry[param.annotation]()
        return func(*args, **kwargs)
    return wrapper

@injectable
class Logger:
    def log(self, msg): print(f"LOG: {msg}")

@inject
def do_work(logger: Logger):
    logger.log("Working!")

do_work()  # Logger auto-injected
```

---

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 7. PYTHON TESTING
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## 7.1 Unit Testing with pytest

```python
# test_calculator.py
import pytest
from dataclasses import dataclass

# === Code under test ===
class Calculator:
    def add(self, a: float, b: float) -> float:
        return a + b

    def divide(self, a: float, b: float) -> float:
        if b == 0:
            raise ValueError("Cannot divide by zero")
        return a / b

    def factorial(self, n: int) -> int:
        if n < 0:
            raise ValueError("Negative numbers not supported")
        if n <= 1:
            return 1
        return n * self.factorial(n - 1)


# === Basic tests ===
class TestCalculator:
    def setup_method(self):
        """Runs before each test method."""
        self.calc = Calculator()

    def test_add(self):
        assert self.calc.add(2, 3) == 5

    def test_add_negative(self):
        assert self.calc.add(-1, 1) == 0

    def test_add_floats(self):
        result = self.calc.add(0.1, 0.2)
        assert result == pytest.approx(0.3)  # Floating point comparison

    def test_divide(self):
        assert self.calc.divide(10, 2) == 5.0

    def test_divide_by_zero(self):
        with pytest.raises(ValueError, match="Cannot divide by zero"):
            self.calc.divide(1, 0)


# === Parametrized tests ===
@pytest.mark.parametrize("a, b, expected", [
    (1, 1, 2),
    (0, 0, 0),
    (-1, 1, 0),
    (100, 200, 300),
    (0.1, 0.2, pytest.approx(0.3)),
])
def test_add_parametrized(a, b, expected):
    calc = Calculator()
    assert calc.add(a, b) == expected


@pytest.mark.parametrize("n, expected", [
    (0, 1),
    (1, 1),
    (5, 120),
    (10, 3628800),
])
def test_factorial(n, expected):
    calc = Calculator()
    assert calc.factorial(n) == expected


# === Markers ===
@pytest.mark.slow
def test_large_factorial():
    calc = Calculator()
    result = calc.factorial(100)
    assert result > 0

@pytest.mark.skipif(
    __import__('sys').platform == 'win32',
    reason="Unix-only test"
)
def test_unix_specific():
    pass

@pytest.mark.xfail(reason="Known bug #123")
def test_known_bug():
    assert 1 == 2
```

---

## 7.2 Fixtures

```python
# conftest.py — shared fixtures
import pytest
import tempfile
import os
from unittest.mock import AsyncMock

# === Basic fixtures ===
@pytest.fixture
def calculator():
    """Fresh calculator for each test."""
    return Calculator()

@pytest.fixture
def sample_data():
    return [1, 2, 3, 4, 5]


# === Fixture with setup and teardown ===
@pytest.fixture
def temp_file():
    """Create a temp file, yield it, then clean up."""
    fd, path = tempfile.mkstemp()
    os.write(fd, b"test data")
    os.close(fd)
    yield path  # Test runs here
    os.unlink(path)  # Cleanup after test

def test_read_file(temp_file):
    with open(temp_file) as f:
        assert f.read() == "test data"


# === Fixture scopes ===
@pytest.fixture(scope="session")
def database_connection():
    """Created once for entire test session."""
    conn = {"host": "localhost", "connected": True}
    yield conn
    # Teardown: close connection

@pytest.fixture(scope="module")
def module_data():
    """Created once per test module."""
    return {"key": "value"}

@pytest.fixture(scope="class")
def class_data():
    """Created once per test class."""
    return []

@pytest.fixture(scope="function")  # Default
def function_data():
    """Created for each test function."""
    return {}


# === Parametrized fixtures ===
@pytest.fixture(params=["sqlite", "postgres", "mysql"])
def db_engine(request):
    """Test runs once for each parameter."""
    engine_type = request.param
    engine = {"type": engine_type, "connected": True}
    yield engine
    # Cleanup

def test_db_connection(db_engine):
    """This test runs 3 times — once per engine type."""
    assert db_engine["connected"]


# === Fixture composition ===
@pytest.fixture
def user(database_connection):
    """Fixture that depends on another fixture."""
    return {"name": "Alice", "db": database_connection}


# === Factory fixture ===
@pytest.fixture
def make_user():
    """Returns a factory function for creating test users."""
    created_users = []

    def _make_user(name="Alice", email=None):
        email = email or f"{name.lower()}@test.com"
        user = {"name": name, "email": email}
        created_users.append(user)
        return user

    yield _make_user

    # Cleanup all created users
    for user in created_users:
        pass  # delete from DB, etc.

def test_multiple_users(make_user):
    alice = make_user("Alice")
    bob = make_user("Bob", "bob@custom.com")
    assert alice["name"] != bob["name"]
```

---

## 7.3 Mocking

```python
from unittest.mock import (
    Mock, MagicMock, patch, PropertyMock,
    call, ANY, AsyncMock, create_autospec
)
import pytest

# === Code to test ===
class PaymentGateway:
    def charge(self, amount: float, card_token: str) -> dict:
        # In reality, calls Stripe/PayPal API
        raise NotImplementedError("Connect to payment provider")

class OrderService:
    def __init__(self, payment: PaymentGateway, notifier):
        self.payment = payment
        self.notifier = notifier

    def place_order(self, user_id: int, amount: float, card: str) -> dict:
        result = self.payment.charge(amount, card)
        if result["success"]:
            self.notifier.send(user_id, f"Order placed: ${amount}")
            return {"order_id": 123, "status": "confirmed"}
        raise ValueError("Payment failed")


# === Mock objects ===
def test_place_order_success():
    # Create mocks
    mock_payment = Mock(spec=PaymentGateway)
    mock_notifier = Mock()

    # Configure mock return value
    mock_payment.charge.return_value = {"success": True, "tx_id": "abc123"}

    # Inject mocks
    service = OrderService(mock_payment, mock_notifier)
    result = service.place_order(1, 99.99, "tok_visa")

    # Assertions
    assert result["status"] == "confirmed"

    # Verify mock was called correctly
    mock_payment.charge.assert_called_once_with(99.99, "tok_visa")
    mock_notifier.send.assert_called_once_with(1, "Order placed: $99.99")


def test_place_order_failure():
    mock_payment = Mock(spec=PaymentGateway)
    mock_payment.charge.return_value = {"success": False}

    service = OrderService(mock_payment, Mock())

    with pytest.raises(ValueError, match="Payment failed"):
        service.place_order(1, 99.99, "tok_bad")


# === patch decorator ===
class EmailClient:
    def send(self, to, subject, body):
        import smtplib  # Real SMTP
        pass

class NotificationService:
    def __init__(self):
        self.client = EmailClient()

    def notify(self, email, message):
        self.client.send(email, "Notification", message)
        return True

# Patch the EmailClient at the location it's USED (not where it's defined)
@patch('__main__.EmailClient')
def test_notification(MockEmailClient):
    mock_instance = MockEmailClient.return_value
    mock_instance.send.return_value = None

    service = NotificationService()
    result = service.notify("test@test.com", "Hello!")

    assert result is True
    mock_instance.send.assert_called_once()


# === patch as context manager ===
def test_with_patch_context():
    with patch('__main__.EmailClient') as MockClient:
        mock = MockClient.return_value
        service = NotificationService()
        service.notify("a@b.com", "test")
        mock.send.assert_called_once()


# === Side effects ===
def test_side_effects():
    mock = Mock()

    # Return different values on successive calls
    mock.side_effect = [1, 2, 3]
    assert mock() == 1
    assert mock() == 2
    assert mock() == 3

    # Raise exception
    mock.side_effect = ConnectionError("Network down")
    with pytest.raises(ConnectionError):
        mock()

    # Custom function
    mock.side_effect = lambda x: x * 2
    assert mock(5) == 10


# === MagicMock (supports magic methods) ===
def test_magic_mock():
    mock = MagicMock()
    mock.__len__.return_value = 5
    mock.__getitem__.return_value = "item"

    assert len(mock) == 5
    assert mock[0] == "item"
    assert bool(mock) is True


# === create_autospec (safer mocking) ===
def test_autospec():
    mock = create_autospec(PaymentGateway)

    # This would raise TypeError because charge takes 2 args:
    # mock.charge()  # TypeError!

    mock.charge("100", "token")  # OK — matches real signature


# === Patching properties ===
class Config:
    @property
    def debug_mode(self):
        return False

def test_patch_property():
    with patch.object(Config, 'debug_mode',
                      new_callable=PropertyMock, return_value=True):
        config = Config()
        assert config.debug_mode is True


# === AsyncMock ===
@pytest.mark.asyncio
async def test_async_mock():
    mock = AsyncMock()
    mock.return_value = {"data": "async result"}

    result = await mock()
    assert result == {"data": "async result"}
    mock.assert_awaited_once()
```

---

## 7.4 Integration Tests

```python
import pytest
import sqlite3
from contextlib import contextmanager

# === Database integration test ===
class UserRepository:
    def __init__(self, db_path: str):
        self.db_path = db_path
        self._init_db()

    def _init_db(self):
        with self._connect() as conn:
            conn.execute("""
                CREATE TABLE IF NOT EXISTS users (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    name TEXT NOT NULL,
                    email TEXT UNIQUE NOT NULL
                )
            """)

    @contextmanager
    def _connect(self):
        conn = sqlite3.connect(self.db_path)
        conn.row_factory = sqlite3.Row
        try:
            yield conn
            conn.commit()
        except Exception:
            conn.rollback()
            raise
        finally:
            conn.close()

    def create(self, name: str, email: str) -> int:
        with self._connect() as conn:
            cursor = conn.execute(
                "INSERT INTO users (name, email) VALUES (?, ?)",
                (name, email)
            )
            return cursor.lastrowid

    def get(self, user_id: int) -> dict | None:
        with self._connect() as conn:
            row = conn.execute(
                "SELECT * FROM users WHERE id = ?", (user_id,)
            ).fetchone()
            return dict(row) if row else None

    def list_all(self) -> list[dict]:
        with self._connect() as conn:
            rows = conn.execute("SELECT * FROM users").fetchall()
            return [dict(r) for r in rows]


# === Integration test fixtures ===
@pytest.fixture
def db_repo(tmp_path):
    """Real database, temporary file."""
    db_path = str(tmp_path / "test.db")
    repo = UserRepository(db_path)
    return repo


class TestUserRepositoryIntegration:
    """Integration tests — use real database."""

    def test_create_and_get(self, db_repo):
        user_id = db_repo.create("Alice", "alice@test.com")
        user = db_repo.get(user_id)

        assert user is not None
        assert user["name"] == "Alice"
        assert user["email"] == "alice@test.com"

    def test_create_duplicate_email(self, db_repo):
        db_repo.create("Alice", "alice@test.com")

        with pytest.raises(sqlite3.IntegrityError):
            db_repo.create("Bob", "alice@test.com")

    def test_list_all(self, db_repo):
        db_repo.create("Alice", "alice@test.com")
        db_repo.create("Bob", "bob@test.com")

        users = db_repo.list_all()
        assert len(users) == 2
        names = {u["name"] for u in users}
        assert names == {"Alice", "Bob"}

    def test_get_nonexistent(self, db_repo):
        user = db_repo.get(999)
        assert user is None


# === API integration test (with httpx/requests) ===
"""
# test_api_integration.py
import httpx
import pytest

@pytest.fixture(scope="session")
def api_client():
    with httpx.Client(base_url="http://localhost:8000") as client:
        yield client

class TestAPIIntegration:
    def test_health_check(self, api_client):
        response = api_client.get("/health")
        assert response.status_code == 200

    def test_create_user(self, api_client):
        response = api_client.post("/users", json={
            "name": "Alice",
            "email": "alice@test.com"
        })
        assert response.status_code == 201
        data = response.json()
        assert data["name"] == "Alice"
"""
```

---

## 7.5 Property-Based Testing (Hypothesis)

```python
import pytest
from hypothesis import given, assume, settings, example
from hypothesis import strategies as st

# === Basic property-based test ===
@given(st.integers(), st.integers())
def test_addition_commutative(a, b):
    """Property: a + b == b + a for all integers."""
    assert a + b == b + a

@given(st.integers(), st.integers(), st.integers())
def test_addition_associative(a, b, c):
    """Property: (a + b) + c == a + (b + c)."""
    assert (a + b) + c == a + (b + c)

@given(st.lists(st.integers()))
def test_sort_is_idempotent(lst):
    """Property: sorting a sorted list gives the same result."""
    assert sorted(sorted(lst)) == sorted(lst)

@given(st.lists(st.integers()))
def test_sort_preserves_length(lst):
    """Property: sorting doesn't change length."""
    assert len(sorted(lst)) == len(lst)

@given(st.lists(st.integers(), min_size=1))
def test_sort_min_is_first(lst):
    """Property: first element of sorted list is the minimum."""
    assert sorted(lst)[0] == min(lst)


# === Complex strategies ===
@st.composite
def user_strategy(draw):
    """Custom strategy for generating User objects."""
    name = draw(st.text(min_size=1, max_size=50,
                       alphabet=st.characters(whitelist_categories=('L',))))
    age = draw(st.integers(min_value=0, max_value=150))
    email = draw(st.emails())
    return {"name": name, "age": age, "email": email}

@given(user_strategy())
def test_user_serialization(user):
    """Property: serialize then deserialize gives original."""
    import json
    serialized = json.dumps(user)
    deserialized = json.loads(serialized)
    assert deserialized == user


# === Testing with assume() ===
@given(st.floats(), st.floats())
def test_division_inverse(a, b):
    """Property: (a / b) * b ≈ a"""
    assume(b != 0)                    # Skip if b is 0
    assume(not (abs(a) > 1e300))       # Skip extreme values
    assume(not (abs(b) < 1e-300))

    result = (a / b) * b
    assert result == pytest.approx(a, rel=1e-9) or abs(a) < 1e-10


# === Explicit examples ===
@given(st.text())
@example("")           # Always test empty string
@example("a" * 10000)  # Always test large string
@example("🎉🎊")       # Always test unicode
def test_string_roundtrip(s):
    assert s.encode('utf-8').decode('utf-8') == s


# === Stateful testing ===
from hypothesis.stateful import RuleBasedStateMachine, rule, invariant

class ListMachine(RuleBasedStateMachine):
    """Test that our custom list behaves like Python's list."""

    def __init__(self):
        super().__init__()
        self.model = []       # Reference implementation
        self.actual = []      # Implementation under test

    @rule(value=st.integers())
    def append(self, value):
        self.model.append(value)
        self.actual.append(value)

    @rule()
    def pop(self):
        if self.model:
            expected = self.model.pop()
            actual = self.actual.pop()
            assert actual == expected

    @invariant()
    def lengths_match(self):
        assert len(self.model) == len(self.actual)

    @invariant()
    def contents_match(self):
        assert self.model == self.actual

TestListMachine = ListMachine.TestCase


# === Settings ===
@settings(
    max_examples=500,        # Run more examples
    deadline=1000,           # ms per example
    deriving=True,
)
@given(st.lists(st.integers()))
def test_with_settings(data):
    assert sorted(data) == sorted(data)
```

---

## 7.6 Test Coverage & Best Practices

```python
# === Running coverage ===
"""
# Install
pip install pytest-cov

# Run with coverage
pytest --cov=mypackage --cov-report=html --cov-report=term-missing

# Coverage configuration in pyproject.toml:
[tool.coverage.run]
source = ["mypackage"]
branch = true
omit = ["tests/*", "*/migrations/*"]

[tool.coverage.report]
fail_under = 80
show_missing = true
exclude_lines = [
    "pragma: no cover",
    "if TYPE_CHECKING:",
    "if __name__ == .__main__.",
    "raise NotImplementedError",
]
"""


# === pytest configuration (pyproject.toml) ===
"""
[tool.pytest.ini_options]
testpaths = ["tests"]
python_files = ["test_*.py"]
python_functions = ["test_*"]
addopts = [
    "-v",
    "--strict-markers",
    "--tb=short",
    "-x",  # Stop on first failure
]
markers = [
    "slow: marks tests as slow",
    "integration: integration tests",
    "unit: unit tests",
]
filterwarnings = [
    "error",
    "ignore::DeprecationWarning",
]
"""


# === Test organization ===
"""
project/
├── src/
│   └── mypackage/
│       ├── __init__.py
│       ├── models.py
│       ├── services.py
│       └── utils.py
├── tests/
│   ├── conftest.py          # Shared fixtures
│   ├── unit/
│   │   ├── conftest.py      # Unit test fixtures
│   │   ├── test_models.py
│   │   ├── test_services.py
│   │   └── test_utils.py
│   ├── integration/
│   │   ├── conftest.py      # Integration fixtures (DB, API)
│   │   └── test_api.py
│   └── e2e/
│       └── test_workflows.py
├── pyproject.toml
└── Makefile
"""


# === Makefile for test commands ===
"""
.PHONY: test test-unit test-integration test-coverage

test:
	pytest

test-unit:
	pytest tests/unit -v

test-integration:
	pytest tests/integration -v --slow

test-coverage:
	pytest --cov=mypackage --cov-report=html
	open htmlcov/index.html

test-watch:
	ptw -- -v --tb=short  # pip install pytest-watch

lint:
	ruff check .
	mypy src/
"""


# === Testing patterns / best practices ===

# 1. Arrange-Act-Assert (AAA)
def test_aaa_pattern():
    # Arrange
    calc = Calculator()
    a, b = 5, 3

    # Act
    result = calc.add(a, b)

    # Assert
    assert result == 8


# 2. One assertion per test (when practical)
def test_user_creation_returns_id(db_repo):
    user_id = db_repo.create("Alice", "alice@test.com")
    assert isinstance(user_id, int)

def test_user_creation_stores_name(db_repo):
    user_id = db_repo.create("Alice", "alice@test.com")
    user = db_repo.get(user_id)
    assert user["name"] == "Alice"


# 3. Test naming convention
def test_divide_by_zero_raises_value_error():
    """test_<method>_<scenario>_<expected>"""
    pass


# 4. Don't test implementation details
def test_result_not_implementation():
    # BAD: tests internal state
    # assert calc._cache == {...}

    # GOOD: tests behavior
    calc = Calculator()
    assert calc.add(2, 3) == 5
```

---

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# QUICK REFERENCE CARD
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

```
┌──────────────────────────────────────────────────────┐
│               PYTHON INTERNALS CHEATSHEET            │
├──────────────────────────────────────────────────────┤
│                                                      │
│  Memory:  pymalloc → pools (4KB) → blocks (8-512B)  │
│  Ints:    cached [-5, 256]                           │
│  Strings: auto-interned if identifier-like           │
│  GIL:     released on I/O, C extensions              │
│  GC:      ref counting + generational (3 gens)       │
│  MRO:     C3 linearization                           │
│                                                      │
│  CONCURRENCY DECISION:                               │
│  ┌──────────┬───────────┬──────────┬────────────┐    │
│  │ Workload │ Threading │ Multipr. │ AsyncIO    │    │
│  ├──────────┼───────────┼──────────┼────────────┤    │
│  │ CPU      │    ✗      │   ✓✓✓    │    ✗       │    │
│  │ I/O few  │   ✓✓      │    ✓     │   ✓✓       │    │
│  │ I/O many │    ✓      │    ✗     │   ✓✓✓      │    │
│  └──────────┴───────────┴──────────┴────────────┘    │
│                                                      │
│  TESTING:                                            │
│  pytest → fixtures + parametrize + markers           │
│  mock   → patch where USED, not where DEFINED        │
│  hypothesis → property-based (find edge cases)       │
│                                                      │
│  PERFORMANCE:                                        │
│  1. Profile first (cProfile, line_profiler)          │
│  2. Use built-ins (sum, sorted, map)                 │
│  3. Use generators for large data                    │
│  4. Use __slots__ for many instances                 │
│  5. Use numpy for numerical work                     │
│  6. Use multiprocessing for CPU-bound                │
│                                                      │
└──────────────────────────────────────────────────────┘
```

---
