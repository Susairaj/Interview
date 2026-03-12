# Python Core Mastery Guide for Senior Tech Lead Interviews
## A Comprehensive 50-Page Reference for 12+ Years Experience Level

---

# Table of Contents

1. [Python Internals & Memory Management](#chapter-1-python-internals--memory-management)
2. [Advanced Object-Oriented Programming](#chapter-2-advanced-object-oriented-programming)
3. [Metaprogramming & Descriptors](#chapter-3-metaprogramming--descriptors)
4. [Concurrency & Parallelism](#chapter-4-concurrency--parallelism)
5. [Performance Optimization](#chapter-5-performance-optimization)
6. [Design Patterns & Architecture](#chapter-6-design-patterns--architecture)
7. [Testing & Quality Assurance](#chapter-7-testing--quality-assurance)
8. [Security Best Practices](#chapter-8-security-best-practices)
9. [System Design with Python](#chapter-9-system-design-with-python)
10. [Leadership & Code Review](#chapter-10-leadership--code-review)

---

# Chapter 1: Python Internals & Memory Management

## 1.1 CPython Architecture

### The Python Execution Model

```python
"""
Understanding Python's execution pipeline:
Source Code → Lexer → Parser → AST → Compiler → Bytecode → PVM
"""

import dis
import ast
import sys

# Examining bytecode
def example_function(x, y):
    result = x + y
    return result * 2

# Disassemble to see bytecode
print("Bytecode Analysis:")
dis.dis(example_function)

# Output:
#   2           0 LOAD_FAST                0 (x)
#               2 LOAD_FAST                1 (y)
#               4 BINARY_ADD
#               6 STORE_FAST               2 (result)
#   3           8 LOAD_FAST                2 (result)
#              10 LOAD_CONST               1 (2)
#              12 BINARY_MULTIPLY
#              14 RETURN_VALUE

# AST Inspection
source_code = """
def greet(name):
    return f"Hello, {name}!"
"""

tree = ast.parse(source_code)
print("\nAST Dump:")
print(ast.dump(tree, indent=2))

# Code object inspection
def inspect_code_object(func):
    """Deep inspection of Python code objects."""
    code = func.__code__
    
    print(f"\n{'='*50}")
    print(f"Function: {func.__name__}")
    print(f"{'='*50}")
    print(f"Argument count: {code.co_argcount}")
    print(f"Local variables: {code.co_varnames}")
    print(f"Constants: {code.co_consts}")
    print(f"Names (global refs): {code.co_names}")
    print(f"Bytecode: {code.co_code.hex()}")
    print(f"Stack size: {code.co_stacksize}")
    print(f"Flags: {bin(code.co_flags)}")
    
inspect_code_object(example_function)
```

### Frame Objects and Call Stack

```python
import sys
import traceback

def get_frame_info():
    """Demonstrates frame introspection."""
    frame = sys._getframe()
    
    print("Current Frame Analysis:")
    print(f"  Function: {frame.f_code.co_name}")
    print(f"  Line number: {frame.f_lineno}")
    print(f"  Local variables: {frame.f_locals}")
    print(f"  Global variables count: {len(frame.f_globals)}")
    
    # Walk the call stack
    print("\nCall Stack:")
    current = frame
    depth = 0
    while current:
        print(f"  [{depth}] {current.f_code.co_name} "
              f"at {current.f_code.co_filename}:{current.f_lineno}")
        current = current.f_back
        depth += 1

def outer_function():
    x = 10
    inner_function()

def inner_function():
    y = 20
    get_frame_info()

outer_function()

# Custom trace function for debugging
def trace_calls(frame, event, arg):
    """Custom trace function to monitor execution."""
    if event == 'call':
        print(f"CALL: {frame.f_code.co_name}")
    elif event == 'return':
        print(f"RETURN: {frame.f_code.co_name} -> {arg}")
    elif event == 'line':
        print(f"LINE: {frame.f_lineno} in {frame.f_code.co_name}")
    return trace_calls

# Usage: sys.settrace(trace_calls)
```

## 1.2 Memory Management Deep Dive

### Reference Counting and Garbage Collection

```python
import sys
import gc
import weakref
import ctypes

class MemoryAnalyzer:
    """Tools for analyzing Python memory management."""
    
    @staticmethod
    def get_ref_count(obj):
        """Get reference count (subtract 1 for the argument reference)."""
        return sys.getrefcount(obj) - 1
    
    @staticmethod
    def get_object_size(obj, seen=None):
        """Recursively calculate object size."""
        size = sys.getsizeof(obj)
        if seen is None:
            seen = set()
        
        obj_id = id(obj)
        if obj_id in seen:
            return 0
        seen.add(obj_id)
        
        if isinstance(obj, dict):
            size += sum(MemoryAnalyzer.get_object_size(v, seen) 
                       for v in obj.values())
            size += sum(MemoryAnalyzer.get_object_size(k, seen) 
                       for k in obj.keys())
        elif hasattr(obj, '__dict__'):
            size += MemoryAnalyzer.get_object_size(obj.__dict__, seen)
        elif hasattr(obj, '__iter__') and not isinstance(obj, (str, bytes, bytearray)):
            size += sum(MemoryAnalyzer.get_object_size(i, seen) for i in obj)
        
        return size
    
    @staticmethod
    def get_gc_stats():
        """Get garbage collector statistics."""
        return {
            'collections': gc.get_count(),
            'thresholds': gc.get_threshold(),
            'tracked_objects': len(gc.get_objects()),
            'garbage': len(gc.garbage)
        }

# Demonstrating reference counting
print("Reference Counting Demo:")
a = [1, 2, 3]
print(f"Initial ref count: {MemoryAnalyzer.get_ref_count(a)}")

b = a  # New reference
print(f"After b = a: {MemoryAnalyzer.get_ref_count(a)}")

c = [a, a, a]  # Three more references
print(f"After c = [a, a, a]: {MemoryAnalyzer.get_ref_count(a)}")

del b
print(f"After del b: {MemoryAnalyzer.get_ref_count(a)}")


# Circular reference demonstration
class CircularRef:
    def __init__(self, name):
        self.name = name
        self.ref = None
    
    def __del__(self):
        print(f"Deleting {self.name}")

def create_cycle():
    """Create a circular reference."""
    obj1 = CircularRef("Object 1")
    obj2 = CircularRef("Object 2")
    
    obj1.ref = obj2
    obj2.ref = obj1
    
    print(f"Before deletion - GC stats: {MemoryAnalyzer.get_gc_stats()}")
    
    # Objects won't be immediately collected due to cycle
    return weakref.ref(obj1), weakref.ref(obj2)

print("\n" + "="*50)
print("Circular Reference Demo:")
weak1, weak2 = create_cycle()

print(f"Weak refs alive: {weak1() is not None}, {weak2() is not None}")

# Force garbage collection
gc.collect()
print(f"After gc.collect() - Weak refs alive: {weak1() is not None}, {weak2() is not None}")
```

### Memory Pools and Object Allocators

```python
import sys

def analyze_small_integer_caching():
    """
    Python caches small integers (-5 to 256) for performance.
    This is called 'integer interning'.
    """
    print("Small Integer Caching Analysis:")
    
    # Small integers are cached
    a = 256
    b = 256
    print(f"256 is 256: {a is b}")  # True
    
    a = 257
    b = 257
    print(f"257 is 257: {a is b}")  # False (typically)
    
    # Negative numbers
    a = -5
    b = -5
    print(f"-5 is -5: {a is b}")  # True
    
    a = -6
    b = -6
    print(f"-6 is -6: {a is b}")  # False (typically)

def analyze_string_interning():
    """
    Python interns certain strings automatically.
    """
    print("\nString Interning Analysis:")
    
    # Simple strings are interned
    a = "hello"
    b = "hello"
    print(f"'hello' is 'hello': {a is b}")  # True
    
    # Strings with spaces aren't automatically interned
    a = "hello world"
    b = "hello world"
    print(f"'hello world' is 'hello world': {a is b}")  # May vary
    
    # Manual interning
    a = sys.intern("hello world!")
    b = sys.intern("hello world!")
    print(f"After intern: {a is b}")  # True

def analyze_pymalloc():
    """
    Understanding Python's memory allocator layers:
    
    Layer 3: Object-specific allocators (list, dict, etc.)
    Layer 2: Python object allocator (pymalloc)
    Layer 1: Python raw memory allocator
    Layer 0: System allocator (malloc/free)
    
    pymalloc manages memory in:
    - Arenas (256 KB)
    - Pools (4 KB)
    - Blocks (8-512 bytes)
    """
    print("\nPyMalloc Analysis:")
    
    # Small objects (< 512 bytes) use pymalloc
    small_list = [1, 2, 3]
    print(f"Small list size: {sys.getsizeof(small_list)} bytes")
    
    # Large objects bypass pymalloc
    large_list = list(range(10000))
    print(f"Large list size: {sys.getsizeof(large_list)} bytes")
    
    # Dictionary memory
    d = {}
    print(f"Empty dict: {sys.getsizeof(d)} bytes")
    d = {i: i for i in range(100)}
    print(f"Dict with 100 items: {sys.getsizeof(d)} bytes")

analyze_small_integer_caching()
analyze_string_interning()
analyze_pymalloc()
```

### Weak References and Caching

```python
import weakref
from weakref import WeakValueDictionary, WeakKeyDictionary, finalize
import functools

class ExpensiveObject:
    """Simulates an expensive-to-create object."""
    _instances = WeakValueDictionary()
    
    def __new__(cls, key):
        # Return existing instance if available
        if key in cls._instances:
            print(f"Returning cached instance for {key}")
            return cls._instances[key]
        
        print(f"Creating new instance for {key}")
        instance = super().__new__(cls)
        cls._instances[key] = instance
        return instance
    
    def __init__(self, key):
        if hasattr(self, '_initialized'):
            return
        self.key = key
        self._initialized = True
        self.data = f"Expensive data for {key}"
    
    def __del__(self):
        print(f"Deleting ExpensiveObject({self.key})")

# Demonstration
print("WeakValueDictionary Demo:")
obj1 = ExpensiveObject("config_a")
obj2 = ExpensiveObject("config_a")  # Returns cached
obj3 = ExpensiveObject("config_b")

print(f"obj1 is obj2: {obj1 is obj2}")

del obj1, obj2
print(f"After deletion, cache contains: {list(ExpensiveObject._instances.keys())}")


# Weak reference callbacks
class ResourceManager:
    """Demonstrates weak reference with cleanup callbacks."""
    
    def __init__(self, name):
        self.name = name
        self._finalizer = finalize(self, self._cleanup, name)
    
    @staticmethod
    def _cleanup(name):
        print(f"Cleaning up resources for {name}")
    
    def remove(self):
        """Explicitly clean up."""
        self._finalizer()

print("\n" + "="*50)
print("Finalizer Demo:")
rm = ResourceManager("Database Connection")
del rm  # Cleanup happens automatically


# LRU Cache with weak references
class WeakLRUCache:
    """LRU Cache that doesn't prevent garbage collection."""
    
    def __init__(self, maxsize=128):
        self.maxsize = maxsize
        self.cache = WeakValueDictionary()
        self.order = []
    
    def get(self, key):
        if key in self.cache:
            # Move to end (most recently used)
            self.order.remove(key)
            self.order.append(key)
            return self.cache[key]
        return None
    
    def put(self, key, value):
        if key in self.cache:
            self.order.remove(key)
        elif len(self.order) >= self.maxsize:
            # Remove least recently used
            old_key = self.order.pop(0)
            if old_key in self.cache:
                del self.cache[old_key]
        
        self.cache[key] = value
        self.order.append(key)
```

## 1.3 The Global Interpreter Lock (GIL)

### Understanding and Working with the GIL

```python
import threading
import time
import sys
from concurrent.futures import ThreadPoolExecutor, ProcessPoolExecutor
import multiprocessing

def cpu_bound_task(n):
    """CPU-intensive task."""
    count = 0
    for i in range(n):
        count += i * i
    return count

def io_bound_task(duration):
    """I/O-intensive task (simulated)."""
    time.sleep(duration)
    return f"Slept for {duration}s"

def benchmark_gil():
    """
    Demonstrates GIL impact on CPU vs I/O bound tasks.
    """
    n = 10_000_000
    
    # Single-threaded CPU-bound
    start = time.perf_counter()
    results = [cpu_bound_task(n) for _ in range(4)]
    single_thread_time = time.perf_counter() - start
    print(f"Single-threaded CPU-bound: {single_thread_time:.2f}s")
    
    # Multi-threaded CPU-bound (GIL limits parallelism)
    start = time.perf_counter()
    with ThreadPoolExecutor(max_workers=4) as executor:
        results = list(executor.map(cpu_bound_task, [n] * 4))
    multi_thread_time = time.perf_counter() - start
    print(f"Multi-threaded CPU-bound: {multi_thread_time:.2f}s")
    
    # Multi-process CPU-bound (bypasses GIL)
    start = time.perf_counter()
    with ProcessPoolExecutor(max_workers=4) as executor:
        results = list(executor.map(cpu_bound_task, [n] * 4))
    multi_process_time = time.perf_counter() - start
    print(f"Multi-process CPU-bound: {multi_process_time:.2f}s")
    
    print(f"\nThread vs Process speedup: {multi_thread_time/multi_process_time:.2f}x")

def demonstrate_gil_release():
    """
    Shows when GIL is released:
    - I/O operations
    - C extensions (numpy, etc.)
    - Explicit release in C code
    """
    import threading
    
    shared_counter = 0
    lock = threading.Lock()
    
    def unsafe_increment(n):
        global shared_counter
        for _ in range(n):
            shared_counter += 1  # Not thread-safe!
    
    def safe_increment(n):
        global shared_counter
        for _ in range(n):
            with lock:
                shared_counter += 1
    
    # Demonstrate race condition
    shared_counter = 0
    threads = [
        threading.Thread(target=unsafe_increment, args=(100000,))
        for _ in range(4)
    ]
    for t in threads:
        t.start()
    for t in threads:
        t.join()
    print(f"Unsafe counter (expected 400000): {shared_counter}")
    
    # Safe version
    shared_counter = 0
    threads = [
        threading.Thread(target=safe_increment, args=(100000,))
        for _ in range(4)
    ]
    for t in threads:
        t.start()
    for t in threads:
        t.join()
    print(f"Safe counter: {shared_counter}")

# GIL-aware design patterns
class GILAwareProcessor:
    """
    Design pattern for GIL-aware processing.
    Uses threads for I/O, processes for CPU.
    """
    
    def __init__(self, io_workers=10, cpu_workers=None):
        self.io_workers = io_workers
        self.cpu_workers = cpu_workers or multiprocessing.cpu_count()
        self._io_executor = None
        self._cpu_executor = None
    
    def __enter__(self):
        self._io_executor = ThreadPoolExecutor(max_workers=self.io_workers)
        self._cpu_executor = ProcessPoolExecutor(max_workers=self.cpu_workers)
        return self
    
    def __exit__(self, *args):
        self._io_executor.shutdown(wait=True)
        self._cpu_executor.shutdown(wait=True)
    
    def process_io(self, func, items):
        """Process I/O-bound tasks with threads."""
        return list(self._io_executor.map(func, items))
    
    def process_cpu(self, func, items):
        """Process CPU-bound tasks with processes."""
        return list(self._cpu_executor.map(func, items))

# Usage example
def fetch_url(url):
    """Simulated I/O operation."""
    time.sleep(0.1)
    return f"Fetched {url}"

def process_data(data):
    """Simulated CPU operation."""
    return sum(i * i for i in range(data))

# with GILAwareProcessor() as processor:
#     # I/O-bound: Use threads
#     urls = ["http://example.com"] * 10
#     results = processor.process_io(fetch_url, urls)
#     
#     # CPU-bound: Use processes
#     data = [1000000] * 4
#     results = processor.process_cpu(process_data, data)

if __name__ == "__main__":
    print("GIL Benchmark:")
    print("=" * 50)
    # benchmark_gil()  # Uncomment to run benchmark
    
    print("\n" + "=" * 50)
    print("GIL Release Demo:")
    demonstrate_gil_release()
```

---

# Chapter 2: Advanced Object-Oriented Programming

## 2.1 The Python Data Model

### Magic Methods Mastery

```python
from functools import total_ordering
from typing import Any, Iterator
import operator

@total_ordering
class Money:
    """
    Demonstrates comprehensive magic method implementation.
    A production-ready Money class with full operator support.
    """
    
    __slots__ = ('_amount', '_currency')
    
    EXCHANGE_RATES = {
        ('USD', 'EUR'): 0.85,
        ('EUR', 'USD'): 1.18,
        ('USD', 'GBP'): 0.73,
        ('GBP', 'USD'): 1.37,
    }
    
    def __init__(self, amount: float, currency: str = 'USD'):
        self._amount = round(amount, 2)
        self._currency = currency.upper()
    
    # String representations
    def __repr__(self) -> str:
        return f"Money({self._amount!r}, {self._currency!r})"
    
    def __str__(self) -> str:
        symbols = {'USD': '$', 'EUR': '€', 'GBP': '£'}
        symbol = symbols.get(self._currency, self._currency + ' ')
        return f"{symbol}{self._amount:,.2f}"
    
    def __format__(self, spec: str) -> str:
        if spec == 'short':
            return f"{self._currency} {self._amount:.0f}"
        elif spec == 'full':
            return f"{self._amount:,.2f} {self._currency}"
        return str(self)
    
    # Comparison (total_ordering provides the rest)
    def __eq__(self, other: Any) -> bool:
        if not isinstance(other, Money):
            return NotImplemented
        return (self._amount, self._currency) == (other._amount, other._currency)
    
    def __lt__(self, other: 'Money') -> bool:
        if not isinstance(other, Money):
            return NotImplemented
        if self._currency != other._currency:
            other = other.convert_to(self._currency)
        return self._amount < other._amount
    
    def __hash__(self) -> int:
        return hash((self._amount, self._currency))
    
    # Arithmetic operations
    def __add__(self, other: 'Money') -> 'Money':
        if not isinstance(other, Money):
            return NotImplemented
        if self._currency != other._currency:
            other = other.convert_to(self._currency)
        return Money(self._amount + other._amount, self._currency)
    
    def __radd__(self, other: Any) -> 'Money':
        if other == 0:  # Allows sum() to work
            return self
        return NotImplemented
    
    def __sub__(self, other: 'Money') -> 'Money':
        if not isinstance(other, Money):
            return NotImplemented
        if self._currency != other._currency:
            other = other.convert_to(self._currency)
        return Money(self._amount - other._amount, self._currency)
    
    def __mul__(self, factor: float) -> 'Money':
        if not isinstance(factor, (int, float)):
            return NotImplemented
        return Money(self._amount * factor, self._currency)
    
    def __rmul__(self, factor: float) -> 'Money':
        return self.__mul__(factor)
    
    def __truediv__(self, divisor: float) -> 'Money':
        if not isinstance(divisor, (int, float)):
            return NotImplemented
        return Money(self._amount / divisor, self._currency)
    
    def __floordiv__(self, divisor: float) -> 'Money':
        if not isinstance(divisor, (int, float)):
            return NotImplemented
        return Money(self._amount // divisor, self._currency)
    
    def __neg__(self) -> 'Money':
        return Money(-self._amount, self._currency)
    
    def __pos__(self) -> 'Money':
        return Money(self._amount, self._currency)
    
    def __abs__(self) -> 'Money':
        return Money(abs(self._amount), self._currency)
    
    # Type conversions
    def __float__(self) -> float:
        return float(self._amount)
    
    def __int__(self) -> int:
        return int(self._amount)
    
    def __bool__(self) -> bool:
        return self._amount != 0
    
    # Container protocol (for cents)
    def __iter__(self) -> Iterator[int]:
        dollars = int(self._amount)
        cents = int((self._amount - dollars) * 100)
        yield dollars
        yield cents
    
    # Attribute access
    @property
    def amount(self) -> float:
        return self._amount
    
    @property
    def currency(self) -> str:
        return self._currency
    
    # Business logic
    def convert_to(self, target_currency: str) -> 'Money':
        target_currency = target_currency.upper()
        if self._currency == target_currency:
            return Money(self._amount, self._currency)
        
        rate_key = (self._currency, target_currency)
        if rate_key not in self.EXCHANGE_RATES:
            raise ValueError(f"No exchange rate for {rate_key}")
        
        rate = self.EXCHANGE_RATES[rate_key]
        return Money(self._amount * rate, target_currency)
    
    def split(self, parts: int) -> list['Money']:
        """Split money into equal parts, handling rounding."""
        base_amount = self._amount / parts
        amounts = [round(base_amount, 2) for _ in range(parts)]
        
        # Adjust for rounding errors
        total = sum(amounts)
        diff = round(self._amount - total, 2)
        amounts[0] += diff
        
        return [Money(amt, self._currency) for amt in amounts]


# Demonstration
print("Money Class Demo:")
print("=" * 50)

m1 = Money(100, 'USD')
m2 = Money(50, 'USD')
m3 = Money(85, 'EUR')

print(f"m1 = {m1}")
print(f"m2 = {m2}")
print(f"m1 + m2 = {m1 + m2}")
print(f"m1 * 2 = {m1 * 2}")
print(f"m1 / 3 = {m1 / 3}")
print(f"sum([m1, m2]) = {sum([m1, m2])}")
print(f"m3.convert_to('USD') = {m3.convert_to('USD')}")
print(f"Format short: {m1:short}")
print(f"Format full: {m1:full}")

dollars, cents = m1
print(f"Unpacked: {dollars} dollars, {cents} cents")

print(f"\nSplit $100 into 3: {[str(m) for m in m1.split(3)]}")
```

### Context Managers Deep Dive

```python
from contextlib import contextmanager, asynccontextmanager, ExitStack
from typing import Optional, Any
import time
import threading
import logging

# Class-based context manager
class DatabaseTransaction:
    """
    Production-grade transaction context manager.
    Demonstrates proper resource management patterns.
    """
    
    def __init__(self, connection, isolation_level='READ_COMMITTED'):
        self.connection = connection
        self.isolation_level = isolation_level
        self._savepoint = None
        self._committed = False
    
    def __enter__(self):
        self.connection.begin_transaction(self.isolation_level)
        self._savepoint = self.connection.create_savepoint()
        return self
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        if exc_type is not None:
            # Exception occurred - rollback
            self.connection.rollback_to_savepoint(self._savepoint)
            self.connection.rollback()
            return False  # Re-raise the exception
        
        if not self._committed:
            # No explicit commit - auto-commit
            self.connection.commit()
        
        return False
    
    def commit(self):
        self.connection.release_savepoint(self._savepoint)
        self.connection.commit()
        self._committed = True
    
    def rollback(self):
        self.connection.rollback_to_savepoint(self._savepoint)


# Reentrant context manager
class ReentrantLock:
    """
    Demonstrates reentrant (nestable) context manager pattern.
    """
    
    def __init__(self):
        self._lock = threading.RLock()
        self._count = 0
    
    def __enter__(self):
        self._lock.acquire()
        self._count += 1
        return self
    
    def __exit__(self, *args):
        self._count -= 1
        self._lock.release()
        return False
    
    @property
    def depth(self):
        return self._count


# Generator-based context managers
@contextmanager
def timing(label: str = "Operation"):
    """Context manager for timing code blocks."""
    start = time.perf_counter()
    try:
        yield
    finally:
        elapsed = time.perf_counter() - start
        print(f"{label} took {elapsed:.4f} seconds")

@contextmanager
def temporary_attribute(obj: Any, attr: str, value: Any):
    """Temporarily set an attribute on an object."""
    had_attr = hasattr(obj, attr)
    old_value = getattr(obj, attr, None) if had_attr else None
    
    setattr(obj, attr, value)
    try:
        yield
    finally:
        if had_attr:
            setattr(obj, attr, old_value)
        else:
            delattr(obj, attr)

@contextmanager
def suppress_logging(logger: logging.Logger, level: int = logging.CRITICAL):
    """Temporarily suppress logging below a certain level."""
    old_level = logger.level
    logger.setLevel(level)
    try:
        yield
    finally:
        logger.setLevel(old_level)


# ExitStack for dynamic context management
class ResourcePool:
    """
    Demonstrates ExitStack for managing multiple dynamic resources.
    """
    
    def __init__(self):
        self._stack = ExitStack()
        self._resources = []
    
    def __enter__(self):
        self._stack.__enter__()
        return self
    
    def __exit__(self, *args):
        return self._stack.__exit__(*args)
    
    def acquire(self, resource_factory, *args, **kwargs):
        """Acquire a resource and register cleanup."""
        resource = resource_factory(*args, **kwargs)
        self._stack.enter_context(resource)
        self._resources.append(resource)
        return resource
    
    def register_cleanup(self, callback, *args, **kwargs):
        """Register arbitrary cleanup function."""
        self._stack.callback(callback, *args, **kwargs)


# Async context manager
class AsyncDatabasePool:
    """
    Async context manager for connection pooling.
    """
    
    def __init__(self, dsn: str, min_size: int = 5, max_size: int = 20):
        self.dsn = dsn
        self.min_size = min_size
        self.max_size = max_size
        self._pool = None
    
    async def __aenter__(self):
        # Simulated async pool creation
        # self._pool = await asyncpg.create_pool(self.dsn, ...)
        print(f"Creating pool with {self.min_size}-{self.max_size} connections")
        return self
    
    async def __aexit__(self, exc_type, exc_val, exc_tb):
        # await self._pool.close()
        print("Closing pool")
        return False
    
    @asynccontextmanager
    async def acquire(self):
        """Acquire a connection from the pool."""
        # connection = await self._pool.acquire()
        connection = "MockConnection"
        try:
            yield connection
        finally:
            # await self._pool.release(connection)
            print(f"Released {connection}")


# Demonstration
print("Context Manager Demos:")
print("=" * 50)

# Timing context manager
with timing("Sleep operation"):
    time.sleep(0.1)

# Nested reentrant lock
lock = ReentrantLock()
with lock:
    print(f"Lock depth: {lock.depth}")
    with lock:
        print(f"Lock depth (nested): {lock.depth}")
    print(f"Lock depth (after exit): {lock.depth}")

# Temporary attribute
class Config:
    debug = False

print(f"\nOriginal debug: {Config.debug}")
with temporary_attribute(Config, 'debug', True):
    print(f"Temporary debug: {Config.debug}")
print(f"Restored debug: {Config.debug}")
```

## 2.2 Advanced Inheritance and MRO

### Method Resolution Order

```python
class MROExplorer:
    """
    Utilities for understanding Method Resolution Order.
    Python uses C3 linearization algorithm.
    """
    
    @staticmethod
    def print_mro(cls):
        """Print the MRO with details."""
        print(f"\nMRO for {cls.__name__}:")
        for i, klass in enumerate(cls.__mro__):
            print(f"  {i}: {klass.__name__}")
    
    @staticmethod
    def find_method_origin(cls, method_name):
        """Find which class in MRO defines a method."""
        for klass in cls.__mro__:
            if method_name in klass.__dict__:
                return klass
        return None


# Diamond inheritance example
class A:
    def method(self):
        print("A.method")
        
    def foo(self):
        print("A.foo")

class B(A):
    def method(self):
        print("B.method")
        super().method()

class C(A):
    def method(self):
        print("C.method")
        super().method()
    
    def foo(self):
        print("C.foo")

class D(B, C):
    def method(self):
        print("D.method")
        super().method()

# Analyze MRO
MROExplorer.print_mro(D)
# Output:
# MRO for D:
#   0: D
#   1: B
#   2: C
#   3: A
#   4: object

print("\nMethod call chain:")
d = D()
d.method()
# Output:
# D.method
# B.method
# C.method
# A.method

print(f"\nfoo() is from: {MROExplorer.find_method_origin(D, 'foo').__name__}")


# Cooperative multiple inheritance
class LoggingMixin:
    """Mixin that adds logging capability."""
    
    def __init__(self, *args, **kwargs):
        print(f"LoggingMixin.__init__ called")
        super().__init__(*args, **kwargs)
    
    def log(self, message):
        print(f"[LOG] {self.__class__.__name__}: {message}")

class SerializationMixin:
    """Mixin that adds serialization capability."""
    
    def __init__(self, *args, **kwargs):
        print(f"SerializationMixin.__init__ called")
        super().__init__(*args, **kwargs)
    
    def to_dict(self):
        return {k: v for k, v in self.__dict__.items() 
                if not k.startswith('_')}

class BaseModel:
    """Base model class."""
    
    def __init__(self, id: int, name: str, **kwargs):
        print(f"BaseModel.__init__ called")
        self.id = id
        self.name = name
        super().__init__(**kwargs)  # Forward remaining kwargs

class User(LoggingMixin, SerializationMixin, BaseModel):
    """User model with logging and serialization."""
    
    def __init__(self, id: int, name: str, email: str, **kwargs):
        print(f"User.__init__ called")
        self.email = email
        super().__init__(id=id, name=name, **kwargs)


print("\n" + "=" * 50)
print("Cooperative Inheritance Demo:")
MROExplorer.print_mro(User)

user = User(1, "John", "john@example.com")
print(f"\nUser dict: {user.to_dict()}")
user.log("Created successfully")


# Super() internals
class SuperExplorer:
    """Understanding super() behavior."""
    
    @staticmethod
    def explain_super():
        """
        super() returns a proxy object that delegates method calls.
        
        super() with no arguments:
        - Equivalent to super(__class__, self) in instance methods
        - Only works inside class definition
        
        super(type, obj):
        - type: Starting point in MRO
        - obj: Object to bind method to
        - Returns proxy for obj's MRO starting after 'type'
        """
        pass


class Parent:
    def greet(self):
        return "Hello from Parent"

class Child(Parent):
    def greet(self):
        # These are equivalent:
        # super().greet()
        # super(Child, self).greet()
        # super(__class__, self).greet()
        return f"Child says: {super().greet()}"
    
    def greet_grandparent(self):
        # Skip Parent, go directly to object (won't work as expected here)
        # This demonstrates MRO navigation
        return super(Parent, self).greet()  # Would raise AttributeError


print("\n" + "=" * 50)
print("Super() Demo:")
child = Child()
print(child.greet())
```

## 2.3 Abstract Base Classes and Protocols

```python
from abc import ABC, abstractmethod
from typing import Protocol, runtime_checkable, Iterator, Iterable
import collections.abc

# Abstract Base Class pattern
class Repository(ABC):
    """
    Abstract base class for repository pattern.
    Demonstrates proper ABC usage with abstract methods and properties.
    """
    
    @abstractmethod
    def get(self, id: int):
        """Retrieve an entity by ID."""
        pass
    
    @abstractmethod
    def save(self, entity) -> int:
        """Save an entity and return its ID."""
        pass
    
    @abstractmethod
    def delete(self, id: int) -> bool:
        """Delete an entity by ID."""
        pass
    
    @property
    @abstractmethod
    def count(self) -> int:
        """Return total number of entities."""
        pass
    
    # Concrete method using abstract methods
    def exists(self, id: int) -> bool:
        """Check if entity exists."""
        return self.get(id) is not None
    
    def save_all(self, entities) -> list[int]:
        """Save multiple entities."""
        return [self.save(e) for e in entities]


class InMemoryRepository(Repository):
    """Concrete implementation of Repository."""
    
    def __init__(self):
        self._storage = {}
        self._next_id = 1
    
    def get(self, id: int):
        return self._storage.get(id)
    
    def save(self, entity) -> int:
        entity_id = self._next_id
        self._storage[entity_id] = entity
        self._next_id += 1
        return entity_id
    
    def delete(self, id: int) -> bool:
        if id in self._storage:
            del self._storage[id]
            return True
        return False
    
    @property
    def count(self) -> int:
        return len(self._storage)


# Protocol (Structural Subtyping)
@runtime_checkable
class Drawable(Protocol):
    """
    Protocol for drawable objects.
    Any class with a draw() method satisfies this protocol.
    """
    
    def draw(self) -> str:
        ...

@runtime_checkable
class Sized(Protocol):
    """Protocol for objects with a size."""
    
    def __len__(self) -> int:
        ...

class Circle:
    """Circle class - implicitly implements Drawable."""
    
    def __init__(self, radius: float):
        self.radius = radius
    
    def draw(self) -> str:
        return f"Drawing circle with radius {self.radius}"

class Rectangle:
    """Rectangle class - implicitly implements Drawable."""
    
    def __init__(self, width: float, height: float):
        self.width = width
        self.height = height
    
    def draw(self) -> str:
        return f"Drawing rectangle {self.width}x{self.height}"

def render(shape: Drawable) -> None:
    """Function that works with any Drawable."""
    print(shape.draw())


# Custom collection using ABC
class SortedSet(collections.abc.MutableSet):
    """
    A sorted set implementation using ABC.
    Demonstrates implementing collection ABCs.
    """
    
    def __init__(self, iterable=None):
        self._data = []
        if iterable:
            for item in iterable:
                self.add(item)
    
    def __contains__(self, item):
        return self._binary_search(item) >= 0
    
    def __iter__(self):
        return iter(self._data)
    
    def __len__(self):
        return len(self._data)
    
    def add(self, item):
        if item not in self:
            # Insert in sorted position
            index = self._find_insert_position(item)
            self._data.insert(index, item)
    
    def discard(self, item):
        index = self._binary_search(item)
        if index >= 0:
            self._data.pop(index)
    
    def _binary_search(self, item):
        """Return index if found, -1 otherwise."""
        import bisect
        index = bisect.bisect_left(self._data, item)
        if index < len(self._data) and self._data[index] == item:
            return index
        return -1
    
    def _find_insert_position(self, item):
        import bisect
        return bisect.bisect_left(self._data, item)
    
    def __repr__(self):
        return f"SortedSet({self._data})"


# Demonstration
print("Abstract Base Classes Demo:")
print("=" * 50)

# Repository pattern
repo = InMemoryRepository()
id1 = repo.save({"name": "Item 1"})
id2 = repo.save({"name": "Item 2"})
print(f"Saved items with IDs: {id1}, {id2}")
print(f"Count: {repo.count}")
print(f"Exists ID 1: {repo.exists(id1)}")

# Protocol demo
print("\n" + "=" * 50)
print("Protocol Demo:")

circle = Circle(5)
rectangle = Rectangle(10, 20)

# Both satisfy Drawable protocol
print(f"Circle is Drawable: {isinstance(circle, Drawable)}")
print(f"Rectangle is Drawable: {isinstance(rectangle, Drawable)}")

render(circle)
render(rectangle)

# SortedSet demo
print("\n" + "=" * 50)
print("SortedSet Demo:")

ss = SortedSet([5, 2, 8, 1, 9, 3])
print(f"SortedSet: {ss}")
ss.add(4)
print(f"After adding 4: {ss}")
ss.discard(2)
print(f"After removing 2: {ss}")
print(f"5 in ss: {5 in ss}")
```

---

# Chapter 3: Metaprogramming & Descriptors

## 3.1 Descriptors

```python
from typing import Any, Optional, Callable, TypeVar, Generic
from weakref import WeakKeyDictionary
import logging

T = TypeVar('T')

class Descriptor:
    """
    Base descriptor class demonstrating the descriptor protocol.
    
    Descriptors are objects that define __get__, __set__, or __delete__.
    They customize attribute access when accessed through a class.
    """
    
    def __set_name__(self, owner: type, name: str) -> None:
        """Called when descriptor is assigned to a class attribute."""
        self.public_name = name
        self.private_name = f'_{name}'
    
    def __get__(self, obj: Optional[object], objtype: Optional[type] = None) -> Any:
        """
        Called when attribute is accessed.
        
        obj: Instance through which accessed (None if accessed through class)
        objtype: Owner class
        """
        if obj is None:
            return self
        return getattr(obj, self.private_name, None)
    
    def __set__(self, obj: object, value: Any) -> None:
        """Called when attribute is set."""
        setattr(obj, self.private_name, value)
    
    def __delete__(self, obj: object) -> None:
        """Called when attribute is deleted."""
        delattr(obj, self.private_name)


# Validated descriptor
class Validated(Descriptor):
    """Descriptor with validation."""
    
    def __init__(self, validator: Callable[[Any], bool], 
                 error_message: str = "Validation failed"):
        self.validator = validator
        self.error_message = error_message
    
    def __set__(self, obj: object, value: Any) -> None:
        if not self.validator(value):
            raise ValueError(f"{self.public_name}: {self.error_message}")
        super().__set__(obj, value)


class TypeChecked(Descriptor):
    """Descriptor that enforces type."""
    
    def __init__(self, expected_type: type):
        self.expected_type = expected_type
    
    def __set__(self, obj: object, value: Any) -> None:
        if not isinstance(value, self.expected_type):
            raise TypeError(
                f"{self.public_name} must be {self.expected_type.__name__}, "
                f"got {type(value).__name__}"
            )
        super().__set__(obj, value)


class Bounded(Descriptor):
    """Numeric descriptor with bounds."""
    
    def __init__(self, min_value: float = None, max_value: float = None):
        self.min_value = min_value
        self.max_value = max_value
    
    def __set__(self, obj: object, value: float) -> None:
        if self.min_value is not None and value < self.min_value:
            raise ValueError(f"{self.public_name} must be >= {self.min_value}")
        if self.max_value is not None and value > self.max_value:
            raise ValueError(f"{self.public_name} must be <= {self.max_value}")
        super().__set__(obj, value)


# Non-data descriptor (for methods)
class LazyProperty:
    """
    Non-data descriptor for lazy evaluation.
    Computes value once and caches it on the instance.
    """
    
    def __init__(self, func: Callable):
        self.func = func
        self.__doc__ = func.__doc__
    
    def __set_name__(self, owner: type, name: str) -> None:
        self.name = name
    
    def __get__(self, obj: Optional[object], objtype: Optional[type] = None) -> Any:
        if obj is None:
            return self
        
        # Compute and cache on instance
        value = self.func(obj)
        setattr(obj, self.name, value)  # Shadows descriptor
        return value


# Class-level descriptor (stores per-instance in WeakKeyDictionary)
class InstanceAttribute(Generic[T]):
    """
    Descriptor that stores values per-instance without polluting instance __dict__.
    Useful when you need descriptor behavior but want clean instance namespace.
    """
    
    def __init__(self, default: T = None):
        self.default = default
        self.data = WeakKeyDictionary()
    
    def __set_name__(self, owner: type, name: str) -> None:
        self.name = name
    
    def __get__(self, obj: Optional[object], objtype: Optional[type] = None) -> T:
        if obj is None:
            return self
        return self.data.get(obj, self.default)
    
    def __set__(self, obj: object, value: T) -> None:
        self.data[obj] = value


# Usage demonstration
class Person:
    name = TypeChecked(str)
    age = Bounded(min_value=0, max_value=150)
    email = Validated(
        lambda x: '@' in x and '.' in x.split('@')[1],
        "Invalid email format"
    )
    
    def __init__(self, name: str, age: int, email: str):
        self.name = name
        self.age = age
        self.email = email


class DataProcessor:
    """Class demonstrating lazy property."""
    
    def __init__(self, data: list):
        self._data = data
    
    @LazyProperty
    def processed_data(self):
        """Expensive computation done only once."""
        print("Computing processed_data...")
        return [x * 2 for x in self._data]
    
    @LazyProperty
    def statistics(self):
        """Another expensive computation."""
        print("Computing statistics...")
        data = self.processed_data
        return {
            'sum': sum(data),
            'avg': sum(data) / len(data),
            'min': min(data),
            'max': max(data)
        }


# Demonstration
print("Descriptor Demo:")
print("=" * 50)

person = Person("John", 30, "john@example.com")
print(f"Person: {person.name}, {person.age}, {person.email}")

try:
    person.age = -5
except ValueError as e:
    print(f"Validation error: {e}")

try:
    person.email = "invalid"
except ValueError as e:
    print(f"Validation error: {e}")

print("\n" + "=" * 50)
print("Lazy Property Demo:")

processor = DataProcessor([1, 2, 3, 4, 5])
print("Accessing processed_data first time:")
print(processor.processed_data)
print("Accessing processed_data second time:")
print(processor.processed_data)  # No "Computing..." printed

print("\nAccessing statistics:")
print(processor.statistics)
```

## 3.2 Metaclasses

```python
from typing import Any, Dict, Tuple, Callable
import inspect

class MetaclassExplainer:
    """
    Understanding metaclasses:
    
    - A metaclass is the class of a class
    - type is the default metaclass
    - Metaclasses control class creation and behavior
    
    Class creation process:
    1. __prepare__ - Create namespace dict
    2. Class body executed in namespace
    3. __new__ - Create class object
    4. __init__ - Initialize class object
    5. __call__ - When class is called (instantiation)
    """
    pass


# Basic metaclass
class LoggingMeta(type):
    """Metaclass that logs class creation and method calls."""
    
    def __new__(mcs, name: str, bases: Tuple[type, ...], 
                namespace: Dict[str, Any], **kwargs) -> type:
        print(f"Creating class: {name}")
        print(f"  Bases: {[b.__name__ for b in bases]}")
        print(f"  Namespace keys: {list(namespace.keys())}")
        
        # Wrap all methods with logging
        for key, value in namespace.items():
            if callable(value) and not key.startswith('_'):
                namespace[key] = mcs._wrap_method(value)
        
        return super().__new__(mcs, name, bases, namespace)
    
    @staticmethod
    def _wrap_method(method: Callable) -> Callable:
        def wrapper(*args, **kwargs):
            print(f"  Calling: {method.__name__}")
            return method(*args, **kwargs)
        wrapper.__name__ = method.__name__
        wrapper.__doc__ = method.__doc__
        return wrapper


# Singleton metaclass
class SingletonMeta(type):
    """Metaclass that makes classes singletons."""
    
    _instances: Dict[type, object] = {}
    
    def __call__(cls, *args, **kwargs):
        if cls not in cls._instances:
            cls._instances[cls] = super().__call__(*args, **kwargs)
        return cls._instances[cls]


# Registry metaclass
class RegistryMeta(type):
    """Metaclass that maintains a registry of all subclasses."""
    
    def __init__(cls, name: str, bases: Tuple[type, ...], 
                 namespace: Dict[str, Any], **kwargs):
        super().__init__(name, bases, namespace)
        
        if not hasattr(cls, '_registry'):
            cls._registry = {}
        else:
            # Register subclass
            cls._registry[name] = cls
    
    def get_subclass(cls, name: str) -> type:
        return cls._registry.get(name)
    
    def list_subclasses(cls) -> list:
        return list(cls._registry.keys())


# Auto-property metaclass
class AutoPropertyMeta(type):
    """
    Metaclass that automatically creates properties from type hints.
    """
    
    def __new__(mcs, name: str, bases: Tuple[type, ...], 
                namespace: Dict[str, Any], **kwargs) -> type:
        
        annotations = namespace.get('__annotations__', {})
        
        for attr_name, attr_type in annotations.items():
            if attr_name.startswith('_'):
                continue
                
            private_name = f'_{attr_name}'
            
            # Create getter
            def make_getter(private):
                def getter(self):
                    return getattr(self, private, None)
                return getter
            
            # Create setter with type checking
            def make_setter(private, expected_type):
                def setter(self, value):
                    if not isinstance(value, expected_type):
                        raise TypeError(
                            f"Expected {expected_type.__name__}, "
                            f"got {type(value).__name__}"
                        )
                    setattr(self, private, value)
                return setter
            
            namespace[attr_name] = property(
                make_getter(private_name),
                make_setter(private_name, attr_type)
            )
        
        return super().__new__(mcs, name, bases, namespace)


# Abstract interface metaclass
class InterfaceMeta(type):
    """Metaclass for interface-like abstract classes."""
    
    def __new__(mcs, name: str, bases: Tuple[type, ...], 
                namespace: Dict[str, Any], **kwargs) -> type:
        
        cls = super().__new__(mcs, name, bases, namespace)
        
        # Check if this is a concrete class (not the interface itself)
        if bases and any(isinstance(b, InterfaceMeta) for b in bases):
            # Get all abstract methods from base interfaces
            abstract_methods = set()
            for base in bases:
                if hasattr(base, '_abstract_methods'):
                    abstract_methods.update(base._abstract_methods)
            
            # Check implementation
            for method_name in abstract_methods:
                if method_name not in namespace:
                    raise TypeError(
                        f"Class {name} must implement {method_name}"
                    )
        else:
            # This is an interface - collect abstract methods
            cls._abstract_methods = {
                name for name, value in namespace.items()
                if callable(value) and not name.startswith('_')
            }
        
        return cls


# Demonstration
print("Metaclass Demo:")
print("=" * 50)

# Logging metaclass
class MyClass(metaclass=LoggingMeta):
    def method_a(self):
        return "A"
    
    def method_b(self):
        return "B"

obj = MyClass()
obj.method_a()
obj.method_b()

# Singleton metaclass
print("\n" + "=" * 50)
print("Singleton Demo:")

class Database(metaclass=SingletonMeta):
    def __init__(self):
        print("Database initialized")

db1 = Database()
db2 = Database()
print(f"db1 is db2: {db1 is db2}")

# Registry metaclass
print("\n" + "=" * 50)
print("Registry Demo:")

class Handler(metaclass=RegistryMeta):
    pass

class JSONHandler(Handler):
    pass

class XMLHandler(Handler):
    pass

print(f"Registered handlers: {Handler.list_subclasses()}")
print(f"Get JSONHandler: {Handler.get_subclass('JSONHandler')}")

# Auto-property metaclass
print("\n" + "=" * 50)
print("Auto-property Demo:")

class Person(metaclass=AutoPropertyMeta):
    name: str
    age: int
    
    def __init__(self, name: str, age: int):
        self.name = name
        self.age = age

person = Person("Alice", 30)
print(f"Name: {person.name}, Age: {person.age}")

try:
    person.age = "thirty"
except TypeError as e:
    print(f"Type error: {e}")
```

## 3.3 Class Decorators and Dynamic Class Creation

```python
from typing import Callable, TypeVar, Any, Dict
from functools import wraps
import dataclasses
from datetime import datetime

C = TypeVar('C', bound=type)

# Class decorator for adding functionality
def auto_repr(cls: C) -> C:
    """Automatically generate __repr__ from __init__ parameters."""
    
    original_init = cls.__init__
    init_signature = inspect.signature(original_init)
    param_names = [
        p.name for p in init_signature.parameters.values()
        if p.name != 'self'
    ]
    
    def __repr__(self):
        params = ', '.join(
            f"{name}={getattr(self, name)!r}"
            for name in param_names
            if hasattr(self, name)
        )
        return f"{cls.__name__}({params})"
    
    cls.__repr__ = __repr__
    return cls


def singleton(cls: C) -> C:
    """Class decorator for singleton pattern."""
    
    instance = None
    
    @wraps(cls)
    def wrapper(*args, **kwargs):
        nonlocal instance
        if instance is None:
            instance = cls(*args, **kwargs)
        return instance
    
    wrapper._instance = lambda: instance
    return wrapper


def frozen(cls: C) -> C:
    """Make class instances immutable after initialization."""
    
    original_init = cls.__init__
    
    def new_init(self, *args, **kwargs):
        object.__setattr__(self, '_frozen', False)
        original_init(self, *args, **kwargs)
        object.__setattr__(self, '_frozen', True)
    
    def frozen_setattr(self, name, value):
        if getattr(self, '_frozen', False):
            raise AttributeError(
                f"Cannot modify frozen instance of {cls.__name__}"
            )
        object.__setattr__(self, name, value)
    
    def frozen_delattr(self, name):
        if getattr(self, '_frozen', False):
            raise AttributeError(
                f"Cannot modify frozen instance of {cls.__name__}"
            )
        object.__delattr__(self, name)
    
    cls.__init__ = new_init
    cls.__setattr__ = frozen_setattr
    cls.__delattr__ = frozen_delattr
    
    return cls


def add_logging(cls: C) -> C:
    """Add logging to all public methods."""
    
    import logging
    logger = logging.getLogger(cls.__name__)
    
    for name, method in inspect.getmembers(cls, predicate=inspect.isfunction):
        if not name.startswith('_'):
            setattr(cls, name, _logged_method(method, logger))
    
    return cls

def _logged_method(method: Callable, logger: logging.Logger) -> Callable:
    @wraps(method)
    def wrapper(*args, **kwargs):
        logger.debug(f"Entering {method.__name__}")
        try:
            result = method(*args, **kwargs)
            logger.debug(f"Exiting {method.__name__} with {result}")
            return result
        except Exception as e:
            logger.exception(f"Error in {method.__name__}: {e}")
            raise
    return wrapper


# Parameterized class decorator
def retry_methods(max_retries: int = 3, exceptions: tuple = (Exception,)):
    """Class decorator that adds retry logic to all methods."""
    
    def decorator(cls: C) -> C:
        for name, method in inspect.getmembers(cls, predicate=inspect.isfunction):
            if not name.startswith('_'):
                setattr(cls, name, _retry_wrapper(method, max_retries, exceptions))
        return cls
    
    return decorator

def _retry_wrapper(method: Callable, max_retries: int, exceptions: tuple) -> Callable:
    @wraps(method)
    def wrapper(*args, **kwargs):
        last_exception = None
        for attempt in range(max_retries):
            try:
                return method(*args, **kwargs)
            except exceptions as e:
                last_exception = e
                print(f"Retry {attempt + 1}/{max_retries} for {method.__name__}")
        raise last_exception
    return wrapper


# Dynamic class creation
def create_model_class(name: str, fields: Dict[str, type]) -> type:
    """Dynamically create a model class with validation."""
    
    def __init__(self, **kwargs):
        for field_name, field_type in fields.items():
            if field_name not in kwargs:
                raise TypeError(f"Missing required field: {field_name}")
            value = kwargs[field_name]
            if not isinstance(value, field_type):
                raise TypeError(
                    f"{field_name} must be {field_type.__name__}"
                )
            setattr(self, field_name, value)
    
    def __repr__(self):
        items = ', '.join(
            f"{k}={getattr(self, k)!r}"
            for k in fields
        )
        return f"{name}({items})"
    
    def to_dict(self):
        return {k: getattr(self, k) for k in fields}
    
    namespace = {
        '__init__': __init__,
        '__repr__': __repr__,
        'to_dict': to_dict,
        '__annotations__': fields.copy(),
    }
    
    return type(name, (), namespace)


# Demonstration
print("Class Decorator Demo:")
print("=" * 50)

@auto_repr
class Point:
    def __init__(self, x: float, y: float):
        self.x = x
        self.y = y

point = Point(3, 4)
print(f"Auto repr: {point}")

@frozen
class Config:
    def __init__(self, host: str, port: int):
        self.host = host
        self.port = port

print("\n" + "=" * 50)
print("Frozen Class Demo:")

config = Config("localhost", 8080)
print(f"Config: {config.host}:{config.port}")

try:
    config.host = "newhost"
except AttributeError as e:
    print(f"Modification blocked: {e}")

# Dynamic class creation
print("\n" + "=" * 50)
print("Dynamic Class Creation:")

User = create_model_class('User', {
    'name': str,
    'age': int,
    'email': str
})

user = User(name="Bob", age=25, email="bob@example.com")
print(f"User: {user}")
print(f"User dict: {user.to_dict()}")
```

---

# Chapter 4: Concurrency & Parallelism

## 4.1 Threading Deep Dive

```python
import threading
import queue
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from contextlib import contextmanager
from typing import Callable, Any, List
import random

class ThreadingPatterns:
    """Collection of advanced threading patterns."""
    
    @staticmethod
    def producer_consumer_demo():
        """Classic producer-consumer pattern with Queue."""
        
        task_queue = queue.Queue(maxsize=10)
        results_queue = queue.Queue()
        stop_event = threading.Event()
        
        def producer(producer_id: int, num_items: int):
            for i in range(num_items):
                item = f"Producer-{producer_id}-Item-{i}"
                task_queue.put(item)
                print(f"Produced: {item}")
                time.sleep(random.uniform(0.01, 0.05))
            print(f"Producer {producer_id} finished")
        
        def consumer(consumer_id: int):
            while not stop_event.is_set() or not task_queue.empty():
                try:
                    item = task_queue.get(timeout=0.1)
                    result = f"Processed by Consumer-{consumer_id}: {item}"
                    results_queue.put(result)
                    task_queue.task_done()
                    time.sleep(random.uniform(0.02, 0.08))
                except queue.Empty:
                    continue
            print(f"Consumer {consumer_id} finished")
        
        # Start consumers
        consumers = [
            threading.Thread(target=consumer, args=(i,))
            for i in range(3)
        ]
        for c in consumers:
            c.start()
        
        # Start producers
        producers = [
            threading.Thread(target=producer, args=(i, 5))
            for i in range(2)
        ]
        for p in producers:
            p.start()
        
        # Wait for producers to finish
        for p in producers:
            p.join()
        
        # Wait for queue to be processed
        task_queue.join()
        
        # Signal consumers to stop
        stop_event.set()
        for c in consumers:
            c.join()
        
        # Collect results
        results = []
        while not results_queue.empty():
            results.append(results_queue.get())
        
        return results


class ThreadPool:
    """Custom thread pool implementation."""
    
    def __init__(self, num_workers: int = 4):
        self.num_workers = num_workers
        self._task_queue = queue.Queue()
        self._workers: List[threading.Thread] = []
        self._shutdown = False
        self._shutdown_lock = threading.Lock()
        
        for i in range(num_workers):
            worker = threading.Thread(target=self._worker_loop, daemon=True)
            worker.start()
            self._workers.append(worker)
    
    def _worker_loop(self):
        while True:
            try:
                task, args, kwargs, result_holder = self._task_queue.get(timeout=0.1)
                if task is None:  # Shutdown signal
                    break
                try:
                    result = task(*args, **kwargs)
                    result_holder['result'] = result
                except Exception as e:
                    result_holder['exception'] = e
                finally:
                    result_holder['done'].set()
                    self._task_queue.task_done()
            except queue.Empty:
                with self._shutdown_lock:
                    if self._shutdown:
                        break
    
    def submit(self, func: Callable, *args, **kwargs) -> 'Future':
        result_holder = {'result': None, 'exception': None, 'done': threading.Event()}
        self._task_queue.put((func, args, kwargs, result_holder))
        return Future(result_holder)
    
    def shutdown(self, wait: bool = True):
        with self._shutdown_lock:
            self._shutdown = True
        
        for _ in self._workers:
            self._task_queue.put((None, None, None, None))
        
        if wait:
            for worker in self._workers:
                worker.join()
    
    def __enter__(self):
        return self
    
    def __exit__(self, *args):
        self.shutdown(wait=True)


class Future:
    """Simple Future implementation."""
    
    def __init__(self, result_holder: dict):
        self._result_holder = result_holder
    
    def result(self, timeout: float = None) -> Any:
        if not self._result_holder['done'].wait(timeout):
            raise TimeoutError("Future timed out")
        
        if self._result_holder['exception']:
            raise self._result_holder['exception']
        
        return self._result_holder['result']
    
    def done(self) -> bool:
        return self._result_holder['done'].is_set()


# Read-Write Lock
class ReadWriteLock:
    """
    Lock that allows multiple readers OR single writer.
    Writers have priority to prevent starvation.
    """
    
    def __init__(self):
        self._read_ready = threading.Condition(threading.Lock())
        self._readers = 0
        self._writers_waiting = 0
        self._writer_active = False
    
    @contextmanager
    def read_lock(self):
        """Acquire read lock."""
        with self._read_ready:
            while self._writer_active or self._writers_waiting > 0:
                self._read_ready.wait()
            self._readers += 1
        
        try:
            yield
        finally:
            with self._read_ready:
                self._readers -= 1
                if self._readers == 0:
                    self._read_ready.notify_all()
    
    @contextmanager
    def write_lock(self):
        """Acquire write lock."""
        with self._read_ready:
            self._writers_waiting += 1
            while self._readers > 0 or self._writer_active:
                self._read_ready.wait()
            self._writers_waiting -= 1
            self._writer_active = True
        
        try:
            yield
        finally:
            with self._read_ready:
                self._writer_active = False
                self._read_ready.notify_all()


# Thread-safe data structures
class ThreadSafeDict:
    """Thread-safe dictionary using read-write lock."""
    
    def __init__(self):
        self._data = {}
        self._lock = ReadWriteLock()
    
    def get(self, key, default=None):
        with self._lock.read_lock():
            return self._data.get(key, default)
    
    def set(self, key, value):
        with self._lock.write_lock():
            self._data[key] = value
    
    def delete(self, key):
        with self._lock.write_lock():
            if key in self._data:
                del self._data[key]
    
    def keys(self):
        with self._lock.read_lock():
            return list(self._data.keys())
    
    def __len__(self):
        with self._lock.read_lock():
            return len(self._data)


# Demonstration
print("Threading Patterns Demo:")
print("=" * 50)

# Custom thread pool
def square(x):
    time.sleep(0.1)
    return x * x

print("\nCustom Thread Pool:")
with ThreadPool(4) as pool:
    futures = [pool.submit(square, i) for i in range(10)]
    results = [f.result() for f in futures]
    print(f"Results: {results}")

# Read-Write Lock demo
print("\n" + "=" * 50)
print("Read-Write Lock Demo:")

ts_dict = ThreadSafeDict()
ts_dict.set('key1', 'value1')
ts_dict.set('key2', 'value2')
print(f"Keys: {ts_dict.keys()}")
print(f"Get key1: {ts_dict.get('key1')}")
```

## 4.2 Asyncio Deep Dive

```python
import asyncio
from asyncio import Queue as AsyncQueue
from typing import List, Callable, Awaitable, Any, TypeVar
from contextlib import asynccontextmanager
import aiohttp  # type: ignore
from dataclasses import dataclass
from datetime import datetime
import random

T = TypeVar('T')

class AsyncPatterns:
    """Collection of advanced asyncio patterns."""
    
    @staticmethod
    async def gather_with_concurrency(
        n: int, 
        *coros: Awaitable[T]
    ) -> List[T]:
        """
        Like asyncio.gather but with concurrency limit.
        """
        semaphore = asyncio.Semaphore(n)
        
        async def sem_coro(coro):
            async with semaphore:
                return await coro
        
        return await asyncio.gather(*(sem_coro(c) for c in coros))
    
    @staticmethod
    async def timeout_with_fallback(
        coro: Awaitable[T],
        timeout: float,
        fallback: T
    ) -> T:
        """Execute coroutine with timeout and fallback value."""
        try:
            return await asyncio.wait_for(coro, timeout)
        except asyncio.TimeoutError:
            return fallback
    
    @staticmethod
    async def retry_async(
        coro_factory: Callable[[], Awaitable[T]],
        max_retries: int = 3,
        delay: float = 1.0,
        backoff: float = 2.0,
        exceptions: tuple = (Exception,)
    ) -> T:
        """Retry coroutine with exponential backoff."""
        last_exception = None
        current_delay = delay
        
        for attempt in range(max_retries):
            try:
                return await coro_factory()
            except exceptions as e:
                last_exception = e
                if attempt < max_retries - 1:
                    await asyncio.sleep(current_delay)
                    current_delay *= backoff
        
        raise last_exception


# Async producer-consumer
class AsyncProducerConsumer:
    """Async producer-consumer pattern."""
    
    def __init__(self, queue_size: int = 100):
        self._queue: AsyncQueue = AsyncQueue(maxsize=queue_size)
        self._running = False
    
    async def produce(self, item: Any) -> None:
        await self._queue.put(item)
    
    async def consume(self) -> Any:
        return await self._queue.get()
    
    async def run_producers(
        self, 
        producer_coros: List[Awaitable[None]]
    ) -> None:
        await asyncio.gather(*producer_coros)
    
    async def run_consumers(
        self,
        consumer_func: Callable[[Any], Awaitable[None]],
        num_consumers: int
    ) -> None:
        async def consumer():
            while True:
                try:
                    item = await asyncio.wait_for(
                        self._queue.get(), 
                        timeout=1.0
                    )
                    await consumer_func(item)
                    self._queue.task_done()
                except asyncio.TimeoutError:
                    if self._queue.empty():
                        break
        
        await asyncio.gather(*[consumer() for _ in range(num_consumers)])


# Async context manager for resource pooling
class AsyncConnectionPool:
    """Async connection pool implementation."""
    
    def __init__(self, factory: Callable, max_size: int = 10):
        self._factory = factory
        self._max_size = max_size
        self._pool: asyncio.Queue = asyncio.Queue(maxsize=max_size)
        self._size = 0
        self._lock = asyncio.Lock()
    
    async def initialize(self) -> None:
        """Pre-create connections."""
        for _ in range(self._max_size):
            conn = await self._factory()
            await self._pool.put(conn)
            self._size += 1
    
    @asynccontextmanager
    async def acquire(self):
        """Acquire a connection from the pool."""
        conn = await self._pool.get()
        try:
            yield conn
        finally:
            await self._pool.put(conn)
    
    async def close(self) -> None:
        """Close all connections."""
        while not self._pool.empty():
            conn = await self._pool.get()
            if hasattr(conn, 'close'):
                await conn.close()


# Rate limiter
class AsyncRateLimiter:
    """Token bucket rate limiter for async operations."""
    
    def __init__(self, rate: float, capacity: int):
        """
        Args:
            rate: Tokens per second
            capacity: Maximum tokens (burst capacity)
        """
        self._rate = rate
        self._capacity = capacity
        self._tokens = capacity
        self._last_update = datetime.now()
        self._lock = asyncio.Lock()
    
    async def acquire(self, tokens: int = 1) -> None:
        """Acquire tokens, waiting if necessary."""
        async with self._lock:
            await self._refill()
            
            while self._tokens < tokens:
                wait_time = (tokens - self._tokens) / self._rate
                await asyncio.sleep(wait_time)
                await self._refill()
            
            self._tokens -= tokens
    
    async def _refill(self) -> None:
        """Refill tokens based on elapsed time."""
        now = datetime.now()
        elapsed = (now - self._last_update).total_seconds()
        self._tokens = min(
            self._capacity,
            self._tokens + elapsed * self._rate
        )
        self._last_update = now


# Async batch processor
class AsyncBatchProcessor:
    """Process items in batches asynchronously."""
    
    def __init__(
        self,
        batch_size: int,
        process_func: Callable[[List[Any]], Awaitable[List[Any]]],
        max_wait: float = 1.0
    ):
        self._batch_size = batch_size
        self._process_func = process_func
        self._max_wait = max_wait
        self._buffer: List[Any] = []
        self