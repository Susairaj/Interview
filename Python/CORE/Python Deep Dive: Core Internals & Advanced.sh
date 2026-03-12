# Python Deep Dive: Core Internals & Advanced Engineering

I'll provide comprehensive explanations with practical code examples for each topic.

---

## 1. CORE PYTHON INTERNALS

### 1.1 Python Execution Model

Python code goes through multiple stages before execution:

```python
# Stage 1: Source Code (.py file)
def greet(name):
    return f"Hello, {name}!"

# Stage 2: Parse to AST (Abstract Syntax Tree)
import ast
code = """
def greet(name):
    return f"Hello, {name}!"
"""
tree = ast.parse(code)
print(ast.dump(tree, indent=2))

# Stage 3: Compile to Bytecode
import dis

def example_function(x, y):
    z = x + y
    if z > 10:
        return z * 2
    return z

# Disassemble to see bytecode
dis.dis(example_function)
```

**Output explanation:**
```
  1           0 LOAD_FAST                0 (x)
              2 LOAD_FAST                1 (y)
              4 BINARY_ADD
              6 STORE_FAST               2 (z)
              
  2           8 LOAD_FAST                2 (z)
             10 LOAD_CONST               1 (10)
             12 COMPARE_OP               4 (>)
             14 POP_JUMP_IF_FALSE       22
             
  3          16 LOAD_FAST                2 (z)
             18 LOAD_CONST               2 (2)
             20 BINARY_MULTIPLY
             22 RETURN_VALUE
```

### 1.2 Bytecode & Python Virtual Machine

The PVM is a stack-based virtual machine:

```python
import dis
import types

# Understanding stack operations
def stack_demo():
    a = 1
    b = 2
    c = a + b
    return c

print("=== Bytecode Analysis ===")
dis.dis(stack_demo)

# Creating code objects manually
def create_custom_bytecode():
    """Demonstrate code object structure"""
    
    def original():
        x = 42
        return x * 2
    
    code_obj = original.__code__
    
    print(f"Filename: {code_obj.co_filename}")
    print(f"Function name: {code_obj.co_name}")
    print(f"Argument count: {code_obj.co_argcount}")
    print(f"Local variables: {code_obj.co_varnames}")
    print(f"Constants: {code_obj.co_consts}")
    print(f"Bytecode: {code_obj.co_code}")
    
create_custom_bytecode()

# Manipulating bytecode (advanced)
def bytecode_modification_example():
    """Shows how Python compiles different operations"""
    
    # List comprehension
    comp = [x*2 for x in range(10)]
    
    # Generator expression  
    gen = (x*2 for x in range(10))
    
    print("\n=== List Comprehension Bytecode ===")
    dis.dis(lambda: [x*2 for x in range(10)])
    
    print("\n=== Generator Expression Bytecode ===")
    dis.dis(lambda: (x*2 for x in range(10)))

bytecode_modification_example()
```

### 1.3 CPython Architecture

```python
"""
CPython Architecture Layers:

1. Python Source Code (.py)
   ↓
2. Parser (Tokenizer → Parser → AST)
   ↓
3. Compiler (AST → Bytecode)
   ↓
4. Python Virtual Machine (PVM)
   ↓
5. C API / Built-in Functions
   ↓
6. Operating System
"""

# Examining Python object structure at C level
import sys
import ctypes

class PyObjectInspector:
    """Inspect Python object internals"""
    
    @staticmethod
    def get_refcount(obj):
        """Get reference count (before sys.getrefcount adds 1)"""
        return sys.getrefcount(obj) - 1
    
    @staticmethod
    def get_memory_address(obj):
        """Get memory address"""
        return id(obj)
    
    @staticmethod
    def get_size(obj):
        """Get size in bytes"""
        return sys.getsizeof(obj)
    
    @staticmethod
    def inspect(obj):
        print(f"Object: {obj}")
        print(f"Type: {type(obj)}")
        print(f"ID (memory address): {id(obj)}")
        print(f"Reference count: {sys.getrefcount(obj)}")
        print(f"Size: {sys.getsizeof(obj)} bytes")
        print()

# Example usage
inspector = PyObjectInspector()

x = [1, 2, 3]
inspector.inspect(x)

y = x  # Increases refcount
inspector.inspect(x)
```

### 1.4 Object Model and Memory Layout

```python
import sys

class MemoryLayoutDemo:
    """Understanding Python object memory layout"""
    
    def __init__(self):
        self.demonstrate_object_overhead()
        self.demonstrate_integer_caching()
        self.demonstrate_string_interning()
    
    def demonstrate_object_overhead(self):
        """Every Python object has overhead"""
        print("=== Object Overhead ===")
        
        # Empty objects still consume memory
        empty_list = []
        empty_dict = {}
        empty_set = set()
        
        print(f"Empty list: {sys.getsizeof(empty_list)} bytes")
        print(f"Empty dict: {sys.getsizeof(empty_dict)} bytes")
        print(f"Empty set: {sys.getsizeof(empty_set)} bytes")
        
        # Objects grow in chunks (over-allocation strategy)
        lists_sizes = []
        for i in range(20):
            lst = list(range(i))
            lists_sizes.append((i, sys.getsizeof(lst)))
        
        print("\nList growth pattern:")
        for length, size in lists_sizes:
            print(f"Length {length:2d}: {size:3d} bytes")
        print()
    
    def demonstrate_integer_caching(self):
        """CPython caches small integers [-5, 256]"""
        print("=== Integer Caching ===")
        
        # Small integers are cached
        a = 256
        b = 256
        print(f"a = 256, b = 256")
        print(f"a is b: {a is b}")  # True
        print(f"id(a) == id(b): {id(a) == id(b)}")
        
        # Large integers are not
        x = 257
        y = 257
        print(f"\nx = 257, y = 257")
        print(f"x is y: {x is y}")  # False (may be True in interactive mode)
        print(f"id(x) == id(y): {id(x) == id(y)}")
        print()
    
    def demonstrate_string_interning(self):
        """Python interns some strings for optimization"""
        print("=== String Interning ===")
        
        # Identifier-like strings are interned
        s1 = "hello"
        s2 = "hello"
        print(f"s1 = 'hello', s2 = 'hello'")
        print(f"s1 is s2: {s1 is s2}")  # True
        
        # Non-identifier strings may not be
        s3 = "hello world!"
        s4 = "hello world!"
        print(f"\ns3 = 'hello world!', s4 = 'hello world!'")
        print(f"s3 is s4: {s3 is s4}")  # May be False
        
        # Explicit interning
        import sys
        s5 = sys.intern("hello world!")
        s6 = sys.intern("hello world!")
        print(f"\nExplicitly interned strings:")
        print(f"s5 is s6: {s5 is s6}")  # True
        print()

demo = MemoryLayoutDemo()

# Understanding PyObject structure
class PyObjectStructure:
    """
    Every Python object in C has this structure:
    
    typedef struct _object {
        Py_ssize_t ob_refcnt;  // Reference count
        PyTypeObject *ob_type;  // Type pointer
    } PyObject;
    
    For variable-size objects:
    typedef struct {
        PyObject ob_base;
        Py_ssize_t ob_size;     // Number of items
    } PyVarObject;
    """
    
    @staticmethod
    def show_object_attributes():
        class CustomClass:
            def __init__(self, value):
                self.value = value
        
        obj = CustomClass(42)
        
        # Instance dictionary
        print("Instance __dict__:", obj.__dict__)
        
        # Class object
        print("Class:", obj.__class__)
        
        # Type
        print("Type:", type(obj))
        
        # Object attributes are stored in __dict__
        print("\nAttribute access:")
        print(f"obj.value = {obj.value}")
        print(f"obj.__dict__['value'] = {obj.__dict__['value']}")

PyObjectStructure.show_object_attributes()
```

### 1.5 Garbage Collection & Reference Counting

```python
import gc
import sys
import weakref

class GarbageCollectionDemo:
    """Understanding Python's memory management"""
    
    def __init__(self):
        print("=== Reference Counting ===\n")
        self.reference_counting_demo()
        
        print("\n=== Cyclic References ===\n")
        self.cyclic_reference_demo()
        
        print("\n=== Garbage Collector ===\n")
        self.garbage_collector_demo()
        
        print("\n=== Weak References ===\n")
        self.weak_reference_demo()
    
    def reference_counting_demo(self):
        """Reference counting is the primary mechanism"""
        
        class TrackedObject:
            def __init__(self, name):
                self.name = name
                print(f"  Created {name}")
            
            def __del__(self):
                print(f"  Deleted {name}")
        
        print("Creating object 'obj1':")
        obj1 = TrackedObject("obj1")
        print(f"Refcount: {sys.getrefcount(obj1) - 1}")  # -1 for getrefcount's reference
        
        print("\nCreating reference 'obj2 = obj1':")
        obj2 = obj1
        print(f"Refcount: {sys.getrefcount(obj1) - 1}")
        
        print("\nDeleting 'obj2':")
        del obj2
        print(f"Refcount: {sys.getrefcount(obj1) - 1}")
        
        print("\nDeleting 'obj1':")
        del obj1
        print("Object should be deleted now")
    
    def cyclic_reference_demo(self):
        """Reference counting can't handle cycles"""
        
        class Node:
            def __init__(self, name):
                self.name = name
                self.ref = None
                print(f"  Created {name}")
            
            def __del__(self):
                print(f"  Deleted {name}")
        
        print("Creating cyclic reference:")
        node1 = Node("node1")
        node2 = Node("node2")
        
        # Create cycle
        node1.ref = node2
        node2.ref = node1
        
        print(f"node1 refcount: {sys.getrefcount(node1) - 1}")
        print(f"node2 refcount: {sys.getrefcount(node2) - 1}")
        
        print("\nDeleting local references:")
        del node1
        del node2
        
        print("Objects still in memory (cycle prevents deletion)")
        
        print("\nRunning garbage collector:")
        collected = gc.collect()
        print(f"Collected {collected} objects")
    
    def garbage_collector_demo(self):
        """Understanding generational garbage collection"""
        
        # Get GC stats
        print("GC thresholds:", gc.get_threshold())
        print("GC counts (gen0, gen1, gen2):", gc.get_count())
        
        # Monitor GC
        gc.set_debug(gc.DEBUG_STATS)
        
        # Create garbage
        class Container:
            pass
        
        print("\nCreating 1000 containers with cycles:")
        for i in range(1000):
            c = Container()
            c.self_ref = c
        
        print("\nGC counts after creation:", gc.get_count())
        
        print("\nForcing collection:")
        collected = gc.collect()
        print(f"Collected {collected} objects")
        
        print("GC counts after collection:", gc.get_count())
        
        # Reset debug flags
        gc.set_debug(0)
    
    def weak_reference_demo(self):
        """Weak references don't increase refcount"""
        
        class LargeObject:
            def __init__(self, data):
                self.data = data
                print(f"  Created object with {len(data)} bytes")
            
            def __del__(self):
                print(f"  Deleted object")
        
        # Strong reference
        print("Creating strong reference:")
        obj = LargeObject(b"x" * 1000)
        print(f"Refcount: {sys.getrefcount(obj) - 1}")
        
        # Weak reference
        print("\nCreating weak reference:")
        weak_obj = weakref.ref(obj)
        print(f"Refcount: {sys.getrefcount(obj) - 1}")
        print(f"Weak ref alive: {weak_obj() is not None}")
        
        print("\nDeleting strong reference:")
        del obj
        print(f"Weak ref alive: {weak_obj() is not None}")

# Run demo
gc_demo = GarbageCollectionDemo()

# Advanced GC patterns
class GCOptimization:
    """Optimization techniques"""
    
    @staticmethod
    def use_slots():
        """__slots__ reduces memory usage"""
        
        class WithoutSlots:
            def __init__(self, x, y):
                self.x = x
                self.y = y
        
        class WithSlots:
            __slots__ = ['x', 'y']
            def __init__(self, x, y):
                self.x = x
                self.y = y
        
        obj1 = WithoutSlots(1, 2)
        obj2 = WithSlots(1, 2)
        
        print(f"\nWithout __slots__: {sys.getsizeof(obj1) + sys.getsizeof(obj1.__dict__)} bytes")
        print(f"With __slots__: {sys.getsizeof(obj2)} bytes")
    
    @staticmethod
    def manual_gc_control():
        """Disable GC for performance-critical code"""
        
        import time
        
        def create_objects():
            return [object() for _ in range(100000)]
        
        # With GC
        gc.enable()
        start = time.perf_counter()
        objs = create_objects()
        with_gc = time.perf_counter() - start
        
        # Without GC
        gc.disable()
        start = time.perf_counter()
        objs = create_objects()
        without_gc = time.perf_counter() - start
        gc.enable()
        
        print(f"\nObject creation time:")
        print(f"With GC: {with_gc:.4f}s")
        print(f"Without GC: {without_gc:.4f}s")
        print(f"Speedup: {with_gc/without_gc:.2f}x")

opt = GCOptimization()
opt.use_slots()
opt.manual_gc_control()
```

---

## 2. ADVANCED PYTHON ENGINEERING

### 2.1 Iterators & Generators

```python
"""
Iterator Protocol:
- __iter__(): Returns the iterator object
- __next__(): Returns the next item or raises StopIteration
"""

class CustomIterator:
    """Deep dive into iterator implementation"""
    
    def __init__(self, max_value):
        self.max_value = max_value
        self.current = 0
    
    def __iter__(self):
        """Returns self because this object is an iterator"""
        return self
    
    def __next__(self):
        """Returns next value or raises StopIteration"""
        if self.current >= self.max_value:
            raise StopIteration
        
        self.current += 1
        return self.current ** 2

# Usage
print("=== Custom Iterator ===")
for num in CustomIterator(5):
    print(num, end=" ")
print("\n")

# Understanding iterator consumption
iterator = CustomIterator(3)
print("Manual iteration:")
print(next(iterator))  # 1
print(next(iterator))  # 4
print(next(iterator))  # 9
try:
    print(next(iterator))  # Raises StopIteration
except StopIteration:
    print("Iterator exhausted\n")


class Iterable:
    """Iterable vs Iterator distinction"""
    
    def __init__(self, data):
        self.data = data
    
    def __iter__(self):
        """Returns a NEW iterator each time"""
        return iter(self.data)

# Iterable can be iterated multiple times
iterable = Iterable([1, 2, 3])
print("First iteration:", list(iterable))
print("Second iteration:", list(iterable))
print()


# Generator Functions
def fibonacci_generator(n):
    """
    Generators are functions that yield values.
    They automatically implement the iterator protocol.
    State is preserved between yields.
    """
    a, b = 0, 1
    count = 0
    
    while count < n:
        yield a
        a, b = b, a + b
        count += 1

print("=== Generator Function ===")
fib = fibonacci_generator(10)
print(f"Type: {type(fib)}")
print(f"Fibonacci sequence: {list(fib)}\n")


# Generator Expressions
print("=== Generator Expressions ===")

# List comprehension - creates entire list in memory
list_comp = [x**2 for x in range(1000000)]
print(f"List comprehension size: {sys.getsizeof(list_comp)} bytes")

# Generator expression - lazy evaluation
gen_exp = (x**2 for x in range(1000000))
print(f"Generator expression size: {sys.getsizeof(gen_exp)} bytes\n")


# Advanced Generator Patterns
class GeneratorPipeline:
    """Composing generators for data processing pipelines"""
    
    @staticmethod
    def read_data(n):
        """Simulate data source"""
        for i in range(n):
            yield f"data_{i}"
    
    @staticmethod
    def process_data(data_iter):
        """Transform data"""
        for item in data_iter:
            yield item.upper()
    
    @staticmethod
    def filter_data(data_iter, pattern):
        """Filter data"""
        for item in data_iter:
            if pattern in item:
                yield item
    
    @staticmethod
    def demonstrate():
        print("=== Generator Pipeline ===")
        
        # Compose pipeline
        pipeline = GeneratorPipeline.filter_data(
            GeneratorPipeline.process_data(
                GeneratorPipeline.read_data(1000)
            ),
            "DATA_5"
        )
        
        # Process only needed items (lazy evaluation)
        results = list(pipeline)
        print(f"Filtered results: {results[:5]}...\n")

GeneratorPipeline.demonstrate()


# Generator Methods: send(), throw(), close()
def coroutine_example():
    """Generators can receive values via send()"""
    total = 0
    count = 0
    average = None
    
    while True:
        # yield returns sent value
        value = yield average
        
        if value is None:
            break
        
        total += value
        count += 1
        average = total / count

print("=== Coroutine (Generator.send()) ===")
calc = coroutine_example()
next(calc)  # Prime the generator

print(f"Send 10: {calc.send(10)}")
print(f"Send 20: {calc.send(20)}")
print(f"Send 30: {calc.send(30)}")
calc.close()
print()


# Yield from (delegation)
def generator_delegation():
    """yield from delegates to sub-generator"""
    
    def inner_gen():
        yield 1
        yield 2
        yield 3
        return "Inner done"
    
    def outer_gen():
        result = yield from inner_gen()  # Delegate
        yield f"Result: {result}"
        yield 4
    
    return outer_gen()

print("=== Yield From ===")
for value in generator_delegation():
    print(value)
print()


# Performance comparison
import time

def performance_comparison():
    """Compare memory and speed"""
    
    def list_approach(n):
        return [x**2 for x in range(n)]
    
    def generator_approach(n):
        return (x**2 for x in range(n))
    
    n = 1_000_000
    
    # Memory usage
    lst = list_approach(n)
    gen = generator_approach(n)
    
    print("=== Performance Comparison ===")
    print(f"List memory: {sys.getsizeof(lst):,} bytes")
    print(f"Generator memory: {sys.getsizeof(gen):,} bytes")
    
    # Speed for full iteration
    start = time.perf_counter()
    sum(list_approach(n))
    list_time = time.perf_counter() - start
    
    start = time.perf_counter()
    sum(generator_approach(n))
    gen_time = time.perf_counter() - start
    
    print(f"\nFull iteration:")
    print(f"List time: {list_time:.4f}s")
    print(f"Generator time: {gen_time:.4f}s")
    
    # Speed for early termination
    start = time.perf_counter()
    for i, _ in enumerate(list_approach(n)):
        if i == 10:
            break
    list_time = time.perf_counter() - start
    
    start = time.perf_counter()
    for i, _ in enumerate(generator_approach(n)):
        if i == 10:
            break
    gen_time = time.perf_counter() - start
    
    print(f"\nEarly termination (10 items):")
    print(f"List time: {list_time:.6f}s")
    print(f"Generator time: {gen_time:.6f}s")

performance_comparison()
```

### 2.2 Closures & Decorators

```python
"""
Closure: A function that captures variables from its enclosing scope
"""

def closure_example():
    """Understanding closures"""
    
    def make_multiplier(factor):
        """Outer function"""
        
        def multiplier(x):
            """Inner function - captures 'factor'"""
            return x * factor
        
        return multiplier
    
    # Create closures with different factors
    times_2 = make_multiplier(2)
    times_3 = make_multiplier(3)
    
    print("=== Closures ===")
    print(f"times_2(5) = {times_2(5)}")
    print(f"times_3(5) = {times_3(5)}")
    
    # Inspect closure
    print(f"\nClosure variables: {times_2.__code__.co_freevars}")
    print(f"Closure cell: {times_2.__closure__[0].cell_contents}")
    print()

closure_example()


# Mutable closure state
def make_counter():
    """Closure with mutable state"""
    count = 0
    
    def counter():
        nonlocal count  # Required to modify enclosing scope variable
        count += 1
        return count
    
    def reset():
        nonlocal count
        count = 0
    
    def get_count():
        return count
    
    return counter, reset, get_count

print("=== Mutable Closure State ===")
count, reset, get = make_counter()
print(f"Count: {count()}")  # 1
print(f"Count: {count()}")  # 2
reset()
print(f"After reset: {count()}")  # 1
print()


# Decorator basics
def simple_decorator(func):
    """Basic decorator structure"""
    
    def wrapper(*args, **kwargs):
        print(f"Before calling {func.__name__}")
        result = func(*args, **kwargs)
        print(f"After calling {func.__name__}")
        return result
    
    return wrapper

@simple_decorator
def greet(name):
    print(f"Hello, {name}!")
    return f"Greeted {name}"

print("=== Simple Decorator ===")
result = greet("Alice")
print(f"Result: {result}\n")


# Decorator with arguments
def repeat(times):
    """Decorator factory - returns a decorator"""
    
    def decorator(func):
        """Actual decorator"""
        
        def wrapper(*args, **kwargs):
            """Wrapper function"""
            results = []
            for _ in range(times):
                results.append(func(*args, **kwargs))
            return results
        
        return wrapper
    return decorator

@repeat(times=3)
def say_hello():
    return "Hello!"

print("=== Decorator with Arguments ===")
print(say_hello())
print()


# Preserving metadata with functools.wraps
from functools import wraps

def better_decorator(func):
    """Decorator that preserves function metadata"""
    
    @wraps(func)  # Copies __name__, __doc__, etc.
    def wrapper(*args, **kwargs):
        """Wrapper documentation"""
        return func(*args, **kwargs)
    
    return wrapper

@better_decorator
def documented_function():
    """Original documentation"""
    pass

print("=== Preserving Metadata ===")
print(f"Function name: {documented_function.__name__}")
print(f"Function doc: {documented_function.__doc__}")
print()


# Class-based decorators
class CountCalls:
    """Decorator implemented as a class"""
    
    def __init__(self, func):
        self.func = func
        self.count = 0
        # Preserve metadata
        wraps(func)(self)
    
    def __call__(self, *args, **kwargs):
        """Make instance callable"""
        self.count += 1
        print(f"Call {self.count} of {self.func.__name__}")
        return self.func(*args, **kwargs)
    
    def reset(self):
        """Additional method"""
        self.count = 0

@CountCalls
def process_data(data):
    return data.upper()

print("=== Class-based Decorator ===")
process_data("hello")
process_data("world")
print(f"Total calls: {process_data.count}")
process_data.reset()
print()


# Advanced decorator patterns
class DecoratorPatterns:
    """Collection of useful decorator patterns"""
    
    @staticmethod
    def memoize(func):
        """Cache function results"""
        cache = {}
        
        @wraps(func)
        def wrapper(*args):
            if args not in cache:
                cache[args] = func(*args)
            return cache[args]
        
        wrapper.cache = cache
        return wrapper
    
    @staticmethod
    def validate_types(**type_checks):
        """Validate argument types"""
        
        def decorator(func):
            @wraps(func)
            def wrapper(*args, **kwargs):
                # Get function signature
                import inspect
                sig = inspect.signature(func)
                bound = sig.bind(*args, **kwargs)
                
                # Check types
                for param_name, expected_type in type_checks.items():
                    if param_name in bound.arguments:
                        value = bound.arguments[param_name]
                        if not isinstance(value, expected_type):
                            raise TypeError(
                                f"{param_name} must be {expected_type}, "
                                f"got {type(value)}"
                            )
                
                return func(*args, **kwargs)
            
            return wrapper
        return decorator
    
    @staticmethod
    def retry(max_attempts=3, delay=1):
        """Retry function on exception"""
        
        def decorator(func):
            @wraps(func)
            def wrapper(*args, **kwargs):
                import time
                
                for attempt in range(max_attempts):
                    try:
                        return func(*args, **kwargs)
                    except Exception as e:
                        if attempt == max_attempts - 1:
                            raise
                        print(f"Attempt {attempt + 1} failed: {e}")
                        time.sleep(delay)
            
            return wrapper
        return decorator
    
    @staticmethod
    def benchmark(func):
        """Measure execution time"""
        
        @wraps(func)
        def wrapper(*args, **kwargs):
            import time
            start = time.perf_counter()
            result = func(*args, **kwargs)
            elapsed = time.perf_counter() - start
            print(f"{func.__name__} took {elapsed:.4f}s")
            return result
        
        return wrapper

# Examples
@DecoratorPatterns.memoize
def fibonacci(n):
    if n < 2:
        return n
    return fibonacci(n-1) + fibonacci(n-2)

print("=== Memoization ===")
print(f"fibonacci(10) = {fibonacci(10)}")
print(f"Cache: {fibonacci.cache}\n")


@DecoratorPatterns.validate_types(x=int, y=int)
def add(x, y):
    return x + y

print("=== Type Validation ===")
print(f"add(5, 3) = {add(5, 3)}")
try:
    add("5", 3)
except TypeError as e:
    print(f"Error: {e}\n")


# Stacking decorators
@DecoratorPatterns.benchmark
@DecoratorPatterns.memoize
def expensive_function(n):
    """Decorators are applied bottom-up"""
    import time
    time.sleep(0.1)
    return n ** 2

print("=== Stacked Decorators ===")
expensive_function(5)  # Slow
expensive_function(5)  # Fast (cached)
print()


# Property decorator (built-in)
class Temperature:
    """Using property as a decorator"""
    
    def __init__(self, celsius=0):
        self._celsius = celsius
    
    @property
    def celsius(self):
        """Getter"""
        return self._celsius
    
    @celsius.setter
    def celsius(self, value):
        """Setter"""
        if value < -273.15:
            raise ValueError("Temperature below absolute zero!")
        self._celsius = value
    
    @property
    def fahrenheit(self):
        """Computed property"""
        return self._celsius * 9/5 + 32

print("=== Property Decorator ===")
temp = Temperature(25)
print(f"Celsius: {temp.celsius}")
print(f"Fahrenheit: {temp.fahrenheit}")
temp.celsius = 30
print(f"Updated Fahrenheit: {temp.fahrenheit}")
```

### 2.3 Descriptor Protocol

```python
"""
Descriptor Protocol:
- __get__(self, obj, type=None) -> value
- __set__(self, obj, value) -> None
- __delete__(self, obj) -> None

Data descriptor: defines __get__ and __set__
Non-data descriptor: defines only __get__
"""

class Descriptor:
    """Basic descriptor implementation"""
    
    def __init__(self, name=None):
        self.name = name
    
    def __set_name__(self, owner, name):
        """Called when descriptor is assigned to class attribute"""
        self.name = name
    
    def __get__(self, obj, objtype=None):
        """Called when attribute is accessed"""
        if obj is None:
            # Accessed from class
            return self
        
        # Accessed from instance
        value = obj.__dict__.get(self.name)
        print(f"__get__: accessing {self.name} = {value}")
        return value
    
    def __set__(self, obj, value):
        """Called when attribute is assigned"""
        print(f"__set__: setting {self.name} = {value}")
        obj.__dict__[self.name] = value
    
    def __delete__(self, obj):
        """Called when attribute is deleted"""
        print(f"__delete__: deleting {self.name}")
        del obj.__dict__[self.name]

class MyClass:
    attr = Descriptor()

print("=== Basic Descriptor ===")
obj = MyClass()
obj.attr = 42  # Calls __set__
print(obj.attr)  # Calls __get__
del obj.attr  # Calls __delete__
print()


# Validated descriptor
class Validated:
    """Descriptor with validation"""
    
    def __init__(self, validator=None, default=None):
        self.validator = validator
        self.default = default
        self.data = {}  # Store data keyed by object id
    
    def __set_name__(self, owner, name):
        self.name = name
    
    def __get__(self, obj, objtype=None):
        if obj is None:
            return self
        return self.data.get(id(obj), self.default)
    
    def __set__(self, obj, value):
        if self.validator and not self.validator(value):
            raise ValueError(
                f"Invalid value for {self.name}: {value}"
            )
        self.data[id(obj)] = value
    
    def __delete__(self, obj):
        if id(obj) in self.data:
            del self.data[id(obj)]


class Person:
    """Using validated descriptors"""
    
    name = Validated(
        validator=lambda x: isinstance(x, str) and len(x) > 0,
        default=""
    )
    
    age = Validated(
        validator=lambda x: isinstance(x, int) and 0 <= x <= 150,
        default=0
    )

print("=== Validated Descriptor ===")
person = Person()
person.name = "Alice"
person.age = 30
print(f"Name: {person.name}, Age: {person.age}")

try:
    person.age = 200  # Invalid
except ValueError as e:
    print(f"Error: {e}\n")


# Type descriptor
class TypedProperty:
    """Enforce type checking"""
    
    def __init__(self, expected_type, default=None):
        self.expected_type = expected_type
        self.default = default
    
    def __set_name__(self, owner, name):
        self.name = f"_{name}"
    
    def __get__(self, obj, objtype=None):
        if obj is None:
            return self
        return getattr(obj, self.name, self.default)
    
    def __set__(self, obj, value):
        if not isinstance(value, self.expected_type):
            raise TypeError(
                f"{self.name[1:]} must be {self.expected_type.__name__}, "
                f"got {type(value).__name__}"
            )
        setattr(obj, self.name, value)


class Product:
    name = TypedProperty(str, "")
    price = TypedProperty(float, 0.0)
    quantity = TypedProperty(int, 0)

print("=== Type Descriptor ===")
product = Product()
product.name = "Widget"
product.price = 9.99
product.quantity = 100

try:
    product.price = "expensive"  # Wrong type
except TypeError as e:
    print(f"Error: {e}\n")


# Lazy property
class LazyProperty:
    """Compute value on first access, then cache"""
    
    def __init__(self, func):
        self.func = func
        self.name = func.__name__
    
    def __get__(self, obj, objtype=None):
        if obj is None:
            return self
        
        # Compute value
        value = self.func(obj)
        
        # Replace descriptor with computed value
        setattr(obj, self.name, value)
        
        return value


class DataProcessor:
    def __init__(self, data):
        self.data = data
    
    @LazyProperty
    def processed_data(self):
        """Expensive computation"""
        print("Computing processed_data...")
        import time
        time.sleep(0.5)
        return [x * 2 for x in self.data]

print("=== Lazy Property ===")
processor = DataProcessor([1, 2, 3])
print("First access:")
print(processor.processed_data)  # Computes
print("Second access:")
print(processor.processed_data)  # Returns cached value
print()


# Method descriptor (how methods work)
class Function:
    """Simplified function descriptor"""
    
    def __init__(self, func):
        self.func = func
    
    def __get__(self, obj, objtype=None):
        """Return bound or unbound method"""
        if obj is None:
            # Unbound - accessed from class
            return self.func
        
        # Bound - accessed from instance
        # Return a bound method
        from functools import partial
        return partial(self.func, obj)


class Example:
    def method(self, x):
        return f"Instance method: {x}"
    
    # Replace with custom descriptor
    method = Function(method)

print("=== Method Descriptor ===")
obj = Example()
print(obj.method(42))
print()


# Property implementation using descriptors
class Property:
    """Reimplementing built-in property"""
    
    def __init__(self, fget=None, fset=None, fdel=None, doc=None):
        self.fget = fget
        self.fset = fset
        self.fdel = fdel
        if doc is None and fget is not None:
            doc = fget.__doc__
        self.__doc__ = doc
    
    def __get__(self, obj, objtype=None):
        if obj is None:
            return self
        if self.fget is None:
            raise AttributeError("unreadable attribute")
        return self.fget(obj)
    
    def __set__(self, obj, value):
        if self.fset is None:
            raise AttributeError("can't set attribute")
        self.fset(obj, value)
    
    def __delete__(self, obj):
        if self.fdel is None:
            raise AttributeError("can't delete attribute")
        self.fdel(obj)
    
    def getter(self, fget):
        return type(self)(fget, self.fset, self.fdel, self.__doc__)
    
    def setter(self, fset):
        return type(self)(self.fget, fset, self.fdel, self.__doc__)
    
    def deleter(self, fdel):
        return type(self)(self.fget, self.fset, fdel, self.__doc__)


class Circle:
    def __init__(self, radius):
        self._radius = radius
    
    @Property
    def radius(self):
        return self._radius
    
    @radius.setter
    def radius(self, value):
        if value < 0:
            raise ValueError("Radius cannot be negative")
        self._radius = value

print("=== Custom Property ===")
circle = Circle(5)
print(f"Radius: {circle.radius}")
circle.radius = 10
print(f"Updated radius: {circle.radius}")
```

### 2.4 Metaclasses

```python
"""
Metaclasses: Classes that create classes
- type is the default metaclass
- class Foo: ... is equivalent to Foo = type('Foo', (), {})
- Metaclasses control class creation
"""

# Understanding type
print("=== Understanding type ===")

# type as a class inspector
print(f"type(5) = {type(5)}")
print(f"type(int) = {type(int)}")
print(f"type(type) = {type(type)}")

# type as a class factory
MyClass = type(
    'MyClass',           # Class name
    (),                  # Base classes
    {'x': 42,           # Class dictionary
     'method': lambda self: "Hello"}
)

obj = MyClass()
print(f"\nDynamically created class: {obj.x}")
print(f"Method: {obj.method()}\n")


# Basic metaclass
class Meta(type):
    """Simple metaclass"""
    
    def __new__(mcs, name, bases, namespace):
        """Called to create the class object"""
        print(f"Creating class {name}")
        print(f"  Bases: {bases}")
        print(f"  Namespace keys: {list(namespace.keys())}")
        
        # Modify class before creation
        namespace['created_by_metaclass'] = True
        
        # Create class
        cls = super().__new__(mcs, name, bases, namespace)
        return cls
    
    def __init__(cls, name, bases, namespace):
        """Called after class is created"""
        print(f"Initializing class {name}")
        super().__init__(name, bases, namespace)
    
    def __call__(cls, *args, **kwargs):
        """Called when creating instances"""
        print(f"Creating instance of {cls.__name__}")
        instance = super().__call__(*args, **kwargs)
        return instance


class MyClass(metaclass=Meta):
    """Class using custom metaclass"""
    
    def __init__(self):
        print("  __init__ called")

print("=== Basic Metaclass ===")
obj = MyClass()
print(f"created_by_metaclass: {MyClass.created_by_metaclass}\n")


# Singleton metaclass
class Singleton(type):
    """Ensures only one instance of a class"""
    
    _instances = {}
    
    def __call__(cls, *args, **kwargs):
        if cls not in cls._instances:
            cls._instances[cls] = super().__call__(*args, **kwargs)
        return cls._instances[cls]


class Database(metaclass=Singleton):
    def __init__(self):
        print("Initializing database connection")
        self.connection = "connected"

print("=== Singleton Metaclass ===")
db1 = Database()
db2 = Database()
print(f"db1 is db2: {db1 is db2}\n")


# Attribute validation metaclass
class ValidateAttributes(type):
    """Validates class attributes"""
    
    def __new__(mcs, name, bases, namespace):
        # Check for required attributes
        required = namespace.get('__required__', [])
        
        for attr in required:
            if attr not in namespace:
                raise TypeError(
                    f"Class {name} missing required attribute: {attr}"
                )
        
        return super().__new__(mcs, name, bases, namespace)


class Model(metaclass=ValidateAttributes):
    """Base model class"""
    __required__ = ['table_name']

class User(Model):
    table_name = 'users'
    
    def __init__(self, name):
        self.name = name

print("=== Validation Metaclass ===")
try:
    class InvalidModel(Model):
        # Missing table_name
        pass
except TypeError as e:
    print(f"Error: {e}\n")


# Auto-register metaclass
class AutoRegister(type):
    """Automatically register classes"""
    
    registry = {}
    
    def __new__(mcs, name, bases, namespace):
        cls = super().__new__(mcs, name, bases, namespace)
        
        # Don't register base class
        if name != 'Plugin':
            mcs.registry[name] = cls
        
        return cls


class Plugin(metaclass=AutoRegister):
    """Base plugin class"""
    pass

class PluginA(Plugin):
    pass

class PluginB(Plugin):
    pass

print("=== Auto-register Metaclass ===")
print(f"Registered plugins: {list(AutoRegister.registry.keys())}\n")


# Method decorator metaclass
class MethodDecorator(type):
    """Apply decorator to all methods"""
    
    def __new__(mcs, name, bases, namespace):
        # Decorator to apply
        def log_calls(func):
            from functools import wraps
            
            @wraps(func)
            def wrapper(*args, **kwargs):
                print(f"Calling {func.__name__}")
                return func(*args, **kwargs)
            return wrapper
        
        # Apply to all methods
        for key, value in namespace.items():
            if callable(value) and not key.startswith('__'):
                namespace[key] = log_calls(value)
        
        return super().__new__(mcs, name, bases, namespace)


class Calculator(metaclass=MethodDecorator):
    def add(self, x, y):
        return x + y
    
    def multiply(self, x, y):
        return x * y

print("=== Method Decorator Metaclass ===")
calc = Calculator()
calc.add(2, 3)
calc.multiply(4, 5)
print()


# ABCMeta reimplementation
class AbstractMeta(type):
    """Simplified abstract base class metaclass"""
    
    def __new__(mcs, name, bases, namespace):
        cls = super().__new__(mcs, name, bases, namespace)
        
        # Collect abstract methods
        abstracts = set()
        
        for key, value in namespace.items():
            if getattr(value, '__isabstractmethod__', False):
                abstracts.add(key)
        
        # Add abstract methods from base classes
        for base in bases:
            for key in getattr(base, '__abstractmethods__', set()):
                if key not in namespace:
                    abstracts.add(key)
        
        cls.__abstractmethods__ = frozenset(abstracts)
        return cls
    
    def __call__(cls, *args, **kwargs):
        if cls.__abstractmethods__:
            raise TypeError(
                f"Can't instantiate abstract class {cls.__name__} "
                f"with abstract methods {', '.join(cls.__abstractmethods__)}"
            )
        return super().__call__(*args, **kwargs)


def abstractmethod(func):
    """Mark method as abstract"""
    func.__isabstractmethod__ = True
    return func


class Shape(metaclass=AbstractMeta):
    @abstractmethod
    def area(self):
        pass

class Rectangle(Shape):
    def __init__(self, width, height):
        self.width = width
        self.height = height
    
    def area(self):
        return self.width * self.height

print("=== Abstract Metaclass ===")
try:
    shape = Shape()  # Error
except TypeError as e:
    print(f"Error: {e}")

rect = Rectangle(5, 3)
print(f"Rectangle area: {rect.area()}\n")


# __init_subclass__ (modern alternative)
class PluginBase:
    """Modern approach without metaclass"""
    
    plugins = {}
    
    def __init_subclass__(cls, **kwargs):
        """Called when class is subclassed"""
        super().__init_subclass__(**kwargs)
        cls.plugins[cls.__name__] = cls


class PluginX(PluginBase):
    pass

class PluginY(PluginBase):
    pass

print("=== __init_subclass__ (modern alternative) ===")
print(f"Registered plugins: {list(PluginBase.plugins.keys())}\n")


# Class decorator vs Metaclass
def add_methods(cls):
    """Class decorator alternative to metaclass"""
    cls.added_method = lambda self: "Added by decorator"
    return cls

@add_methods
class DecoratedClass:
    pass

print("=== Class Decorator vs Metaclass ===")
obj = DecoratedClass()
print(f"Decorator added method: {obj.added_method()}")
```

---

## 3. PERFORMANCE ENGINEERING

### 3.1 Python Profiling

```python
import time
import cProfile
import pstats
from io import StringIO
import line_profiler
import memory_profiler

# Sample functions for profiling
def fibonacci_recursive(n):
    """Inefficient recursive implementation"""
    if n < 2:
        return n
    return fibonacci_recursive(n-1) + fibonacci_recursive(n-2)

def fibonacci_iterative(n):
    """Efficient iterative implementation"""
    if n < 2:
        return n
    a, b = 0, 1
    for _ in range(n-1):
        a, b = b, a + b
    return b

def fibonacci_memoized(n, memo={}):
    """Memoized recursive implementation"""
    if n in memo:
        return memo[n]
    if n < 2:
        return n
    memo[n] = fibonacci_memoized(n-1, memo) + fibonacci_memoized(n-2, memo)
    return memo[n]


# 1. timeit - Micro-benchmarking
from timeit import timeit

print("=== timeit (Micro-benchmarking) ===")
print("Comparing list creation methods:")

# Number of runs
number = 100000

# List comprehension
time1 = timeit('[x**2 for x in range(100)]', number=number)
print(f"List comprehension: {time1:.4f}s")

# map()
time2 = timeit('list(map(lambda x: x**2, range(100)))', number=number)
print(f"map(): {time2:.4f}s")

# for loop
code = """
result = []
for x in range(100):
    result.append(x**2)
"""
time3 = timeit(code, number=number)
print(f"for loop: {time3:.4f}s\n")


# 2. cProfile - Deterministic profiling
print("=== cProfile (Function-level profiling) ===")

def main():
    """Function to profile"""
    result = []
    for i in range(10):
        result.append(fibonacci_recursive(20))
    return result

# Profile the function
profiler = cProfile.Profile()
profiler.enable()
main()
profiler.disable()

# Print statistics
stats = pstats.Stats(profiler)
stats.strip_dirs()
stats.sort_stats('cumulative')
stats.print_stats(10)  # Top 10 functions
print()


# 3. Manual timing with decorators
class Timer:
    """Context manager and decorator for timing"""
    
    def __init__(self, name=""):
        self.name = name
    
    def __enter__(self):
        self.start = time.perf_counter()
        return self
    
    def __exit__(self, *args):
        self.elapsed = time.perf_counter() - self.start
        print(f"{self.name}: {self.elapsed:.6f}s")
    
    def __call__(self, func):
        """Use as decorator"""
        from functools import wraps
        
        @wraps(func)
        def wrapper(*args, **kwargs):
            with self:
                return func(*args, **kwargs)
        return wrapper

print("=== Manual Timing ===")

# As context manager
with Timer("fibonacci_recursive(25)"):
    fibonacci_recursive(25)

with Timer("fibonacci_iterative(25)"):
    fibonacci_iterative(25)

with Timer("fibonacci_memoized(25)"):
    fibonacci_memoized(25)

# As decorator
@Timer("decorated_function")
def slow_function():
    time.sleep(0.1)
    return "done"

slow_function()
print()


# 4. Profiling with statistics
class DetailedProfiler:
    """Collect detailed profiling statistics"""
    
    def __init__(self):
        self.stats = {}
    
    def profile_function(self, func, *args, **kwargs):
        """Profile a single function call"""
        profiler = cProfile.Profile()
        
        profiler.enable()
        result = func(*args, **kwargs)
        profiler.disable()
        
        # Collect stats
        stream = StringIO()
        stats = pstats.Stats(profiler, stream=stream)
        stats.strip_dirs()
        stats.sort_stats('cumulative')
        
        self.stats[func.__name__] = {
            'result': result,
            'stats': stats,
            'text': stream.getvalue()
        }
        
        return result
    
    def compare(self):
        """Compare profiled functions"""
        for name, data in self.stats.items():
            print(f"\n=== {name} ===")
            data['stats'].print_stats(5)

print("=== Detailed Profiling ===")
profiler = DetailedProfiler()

profiler.profile_function(fibonacci_recursive, 20)
profiler.profile_function(fibonacci_iterative, 20)
profiler.profile_function(fibonacci_memoized, 20)

profiler.compare()


# 5. Line-by-line profiling simulation
def line_profile_demo():
    """
    For real line profiling, use:
    pip install line_profiler
    
    @profile
    def function():
        ...
    
    kernprof -l -v script.py
    """
    
    print("\n=== Line Profiling (Simulation) ===")
    print("Install line_profiler for detailed line-by-line analysis")
    print("Usage:")
    print("  1. Add @profile decorator to function")
    print("  2. Run: kernprof -l -v script.py")
    print("  3. View detailed line-by-line timing\n")

line_profile_demo()


# 6. Performance comparison framework
class PerformanceComparison:
    """Framework for comparing implementations"""
    
    def __init__(self):
        self.results = {}
    
    def benchmark(self, name, func, *args, runs=100, **kwargs):
        """Benchmark a function"""
        times = []
        
        for _ in range(runs):
            start = time.perf_counter()
            func(*args, **kwargs)
            elapsed = time.perf_counter() - start
            times.append(elapsed)
        
        self.results[name] = {
            'min': min(times),
            'max': max(times),
            'mean': sum(times) / len(times),
            'median': sorted(times)[len(times)//2]
        }
    
    def report(self):
        """Print comparison report"""
        print("\n=== Performance Comparison ===")
        print(f"{'Implementation':<25} {'Min (ms)':<12} {'Mean (ms)':<12} {'Max (ms)':<12}")
        print("-" * 65)
        
        for name, stats in self.results.items():
            print(f"{name:<25} {stats['min']*1000:<12.4f} "
                  f"{stats['mean']*1000:<12.4f} {stats['max']*1000:<12.4f}")
        
        # Find fastest
        fastest = min(self.results.items(), 
                     key=lambda x: x[1]['mean'])
        print(f"\nFastest: {fastest[0]}")

# Compare implementations
comparison = PerformanceComparison()
comparison.benchmark("fibonacci_recursive", fibonacci_recursive, 15)
comparison.benchmark("fibonacci_iterative", fibonacci_iterative, 15)
comparison.benchmark("fibonacci_memoized", fibonacci_memoized, 15)
comparison.report()


# 7. Memory profiling basics
print("\n=== Memory Usage ===")

def memory_intensive():
    """Function that uses significant memory"""
    data = [list(range(1000)) for _ in range(1000)]
    return data

import tracemalloc

tracemalloc.start()

memory_intensive()

current, peak = tracemalloc.get_traced_memory()
print(f"Current memory usage: {current / 10**6:.2f} MB")
print(f"Peak memory usage: {peak / 10**6:.2f} MB")

tracemalloc.stop()
```

### 3.2 Memory Optimization

```python
import sys
import array
import gc
from collections import namedtuple

print("=== Memory Optimization Techniques ===\n")

# 1. __slots__
class WithoutSlots:
    def __init__(self, x, y, z):
        self.x = x
        self.y = y
        self.z = z

class WithSlots:
    __slots__ = ['x', 'y', 'z']
    
    def __init__(self, x, y, z):
        self.x = x
        self.y = y
        self.z = z

print("1. __slots__ vs __dict__")

obj1 = WithoutSlots(1, 2, 3)
obj2 = WithSlots(1, 2, 3)

size1 = sys.getsizeof(obj1) + sys.getsizeof(obj1.__dict__)
size2 = sys.getsizeof(obj2)

print(f"Without __slots__: {size1} bytes")
print(f"With __slots__: {size2} bytes")
print(f"Savings: {size1 - size2} bytes ({(1 - size2/size1)*100:.1f}%)\n")

# Memory for 1 million objects
million_without = (size1 * 1_000_000) / (1024**2)
million_with = (size2 * 1_000_000) / (1024**2)

print(f"1M objects without __slots__: {million_without:.2f} MB")
print(f"1M objects with __slots__: {million_with:.2f} MB\n")


# 2. Named tuples vs classes
print("2. Named Tuples")

Point = namedtuple('Point', ['x', 'y', 'z'])

class PointClass:
    def __init__(self, x, y, z):
        self.x = x
        self.y = y
        self.z = z

point_tuple = Point(1, 2, 3)
point_class = PointClass(1, 2, 3)

print(f"NamedTuple: {sys.getsizeof(point_tuple)} bytes")
print(f"Class: {sys.getsizeof(point_class) + sys.getsizeof(point_class.__dict__)} bytes\n")


# 3. Arrays vs Lists
print("3. Arrays vs Lists (homogeneous data)")

list_int = list(range(1000))
array_int = array.array('i', range(1000))

print(f"List of ints: {sys.getsizeof(list_int)} bytes")
print(f"Array of ints: {sys.getsizeof(array_int)} bytes")
print(f"Savings: {sys.getsizeof(list_int) - sys.getsizeof(array_int)} bytes\n")


# 4. Generators vs Lists
print("4. Generators vs Lists (lazy evaluation)")

def list_approach(n):
    return [x**2 for x in range(n)]

def generator_approach(n):
    return (x**2 for x in range(n))

n = 1_000_000

list_obj = list_approach(n)
gen_obj = generator_approach(n)

print(f"List: {sys.getsizeof(list_obj) / 10**6:.2f} MB")
print(f"Generator: {sys.getsizeof(gen_obj)} bytes\n")


# 5. String concatenation
print("5. String Concatenation")

def bad_concat(strings):
    """Inefficient - creates new string each time"""
    result = ""
    for s in strings:
        result += s
    return result

def good_concat(strings):
    """Efficient - builds list then joins"""
    return "".join(strings)

# Benchmark would show good_concat is faster and uses less memory


# 6. Object pooling
class ObjectPool:
    """Reuse objects instead of creating new ones"""
    
    def __init__(self, cls, size):
        self.cls = cls
        self.pool = [cls() for _ in range(size)]
        self.available = list(self.pool)
    
    def acquire(self):
        if not self.available:
            raise RuntimeError("Pool exhausted")
        return self.available.pop()
    
    def release(self, obj):
        obj.reset()  # Clean up object state
        self.available.append(obj)

class PooledObject:
    def __init__(self):
        self.data = None
    
    def reset(self):
        self.data = None

print("6. Object Pooling (for frequently created/destroyed objects)")
pool = ObjectPool(PooledObject, 10)
obj = pool.acquire()
obj.data = "some data"
pool.release(obj)
print("Object pooling implemented\n")


# 7. Interning
print("7. String Interning")

import sys

# Manual interning
s1 = sys.intern("hello" * 100)
s2 = sys.intern("hello" * 100)

print(f"Interned strings are same object: {s1 is s2}")

# Without interning
s3 = "hello" * 100
s4 = "hello" * 100
print(f"Non-interned strings: {s3 is s4}\n")


# 8. Weak references
print("8. Weak References")

class LargeObject:
    def __init__(self, data):
        self.data = data

import weakref

# Strong reference prevents garbage collection
obj = LargeObject(b"x" * 1000000)
print(f"Object size: {sys.getsizeof(obj.data) / 10**6:.2f} MB")

# Weak reference doesn't prevent GC
weak_ref = weakref.ref(obj)
print(f"Weak reference exists: {weak_ref() is not None}")

del obj
gc.collect()
print(f"After deletion: {weak_ref() is not None}\n")


# 9. Memory profiling for data structures
class MemoryProfiler:
    """Profile memory usage of data structures"""
    
    @staticmethod
    def profile_structure(name, factory, size):
        """Profile a data structure"""
        gc.collect()  # Clean up first
        
        tracemalloc.start()
        obj = factory(size)
        current, peak = tracemalloc.get_traced_memory()
        tracemalloc.stop()
        
        print(f"{name}:")
        print(f"  Current: {current / 10**6:.2f} MB")
        print(f"  Peak: {peak / 10**6:.2f} MB")
        
        return obj

print("9. Data Structure Memory Profiling")

import tracemalloc

# List
MemoryProfiler.profile_structure(
    "List", 
    lambda n: list(range(n)), 
    100000
)

# Set
MemoryProfiler.profile_structure(
    "Set",
    lambda n: set(range(n)),
    100000
)

# Dict
MemoryProfiler.profile_structure(
    "Dict",
    lambda n: {i: i for i in range(n)},
    100000
)

print()


# 10. Memory-efficient iteration
print("10. Memory-efficient Iteration Patterns\n")

class MemoryEfficientIterator:
    """Examples of memory-efficient patterns"""
    
    @staticmethod
    def process_large_file(filename):
        """Read file line by line instead of loading all"""
        # Don't do this:
        # with open(filename) as f:
        #     lines = f.readlines()  # Loads entire file
        
        # Do this:
        with open(filename) as f:
            for line in f:  # Iterates lazily
                process_line(line)
    
    @staticmethod
    def batch_processing(items, batch_size=1000):
        """Process items in batches"""
        for i in range(0, len(items), batch_size):
            batch = items[i:i+batch_size]
            yield batch
    
    @staticmethod
    def lazy_loading():
        """Load data only when needed"""
        class LazyData:
            def __init__(self):
                self._data = None
            
            @property
            def data(self):
                if self._data is None:
                    self._data = load_expensive_data()
                return self._data
        
        return LazyData()

def process_line(line):
    pass

def load_expensive_data():
    return "expensive data"

print("Memory-efficient patterns demonstrated")
```

### 3.3 GIL Deep Dive

```python
"""
Global Interpreter Lock (GIL):
- Mutex that protects access to Python objects
- Only one thread executes Python bytecode at a time
- Released during I/O operations
- Impacts CPU-bound multi-threading but not I/O-bound
"""

import threading
import multiprocessing
import time
from concurrent.futures import ThreadPoolExecutor, ProcessPoolExecutor

print("=== GIL (Global Interpreter Lock) Deep Dive ===\n")


# 1. Demonstrating GIL impact on CPU-bound tasks
def cpu_bound_task(n):
    """CPU-intensive operation"""
    count = 0
    for i in range(n):
        count += i ** 2
    return count

def io_bound_task(n):
    """I/O-intensive operation"""
    time.sleep(n)
    return n


print("1. CPU-Bound Tasks (GIL impact)")

# Single-threaded baseline
start = time.perf_counter()
for _ in range(4):
    cpu_bound_task(5_000_000)
single_time = time.perf_counter() - start
print(f"Single-threaded: {single_time:.4f}s")

# Multi-threaded (GIL prevents parallelism)
start = time.perf_counter()
threads = []
for _ in range(4):
    t = threading.Thread(target=cpu_bound_task, args=(5_000_000,))
    t.start()
    threads.append(t)

for t in threads:
    t.join()
multi_thread_time = time.perf_counter() - start
print(f"Multi-threaded (4 threads): {multi_thread_time:.4f}s")
print(f"Speedup: {single_time/multi_thread_time:.2f}x (expected ~1x due to GIL)\n")


print("2. I/O-Bound Tasks (GIL released)")

# Single-threaded
start = time.perf_counter()
for _ in range(4):
    io_bound_task(0.5)
single_time = time.perf_counter() - start
print(f"Single-threaded: {single_time:.4f}s")

# Multi-threaded (GIL released during I/O)
start = time.perf_counter()
threads = []
for _ in range(4):
    t = threading.Thread(target=io_bound_task, args=(0.5,))
    t.start()
    threads.append(t)

for t in threads:
    t.join()
multi_thread_time = time.perf_counter() - start
print(f"Multi-threaded (4 threads): {multi_thread_time:.4f}s")
print(f"Speedup: {single_time/multi_thread_time:.2f}x (near 4x - GIL released)\n")


# 3. Multiprocessing bypasses GIL
print("3. Multiprocessing (bypasses GIL)")

if __name__ == '__main__':
    # CPU-bound with multiprocessing
    start = time.perf_counter()
    with ProcessPoolExecutor(max_workers=4) as executor:
        executor.map(cpu_bound_task, [5_000_000] * 4)
    multi_proc_time = time.perf_counter() - start
    print(f"Multi-processing (4 processes): {multi_proc_time:.4f}s")
    print(f"Speedup vs single-threaded: {single_time/multi_proc_time:.2f}x\n")


# 4. Understanding when GIL is released
class GILBehavior:
    """Demonstrate GIL release patterns"""
    
    @staticmethod
    def pure_python():
        """Pure Python - holds GIL"""
        result = 0
        for i in range(1000000):
            result += i
        return result
    
    @staticmethod
    def c_extension():
        """C extensions can release GIL"""
        import hashlib
        # hashlib releases GIL during computation
        return hashlib.sha256(b"x" * 1000000).hexdigest()
    
    @staticmethod
    def io_operation():
        """I/O operations release GIL"""
        import time
        time.sleep(0.1)  # Releases GIL
    
    @staticmethod
    def demonstrate():
        print("4. GIL Release Patterns")
        print("Pure Python: Holds GIL")
        print("C extensions: Can release GIL (e.g., hashlib, NumPy)")
        print("I/O operations: Release GIL (sleep, file I/O, network)")
        print()

GILBehavior.demonstrate()


# 5. Visualizing GIL contention
class GILContentionDemo:
    """Demonstrate thread switching overhead"""
    
    @staticmethod
    def increment_counter(counter, lock, iterations):
        """Thread-safe counter increment"""
        for _ in range(iterations):
            with lock:
                counter[0] += 1
    
    @staticmethod
    def demonstrate():
        print("5. GIL Contention")
        
        iterations = 100000
        
        # Without lock (race condition, but shows GIL switching)
        counter = [0]
        lock = threading.Lock()
        
        start = time.perf_counter()
        threads = []
        for _ in range(4):
            t = threading.Thread(
                target=GILContentionDemo.increment_counter,
                args=(counter, lock, iterations)
            )
            t.start()
            threads.append(t)
        
        for t in threads:
            t.join()
        
        elapsed = time.perf_counter() - start
        print(f"4 threads incrementing counter: {elapsed:.4f}s")
        print(f"Counter value: {counter[0]}")
        print(f"Expected: {iterations * 4}")
        print()

GILContentionDemo.demonstrate()


# 6. GIL switching interval
print("6. GIL Switching")
import sys

# Check GIL switch interval
print(f"GIL switch interval: {sys.getswitchinterval()} seconds")
print("(Threads switch approximately every 5ms by default)")
print()

# Adjust switch interval (not usually recommended)
# sys.setswitchinterval(0.001)  # More frequent switching


# 7. When to use what
class ConcurrencyDecisionTree:
    """Guide for choosing concurrency approach"""
    
    @staticmethod
    def guide():
        print("7. Choosing Concurrency Approach")
        print()
        print("CPU-Bound Tasks:")
        print("  → multiprocessing (bypasses GIL)")
        print("  → Consider: Numba, Cython for speed")
        print()
        print("I/O-Bound Tasks:")
        print("  → threading (GIL released during I/O)")
        print("  → asyncio (single-threaded async)")
        print()
        print("Mixed Workload:")
        print("  → ThreadPoolExecutor for I/O")
        print("  → ProcessPoolExecutor for CPU")
        print()

ConcurrencyDecisionTree.guide()


# 8. Practical example: Web scraping
def web_scraper_comparison():
    """Compare threading vs multiprocessing for I/O"""
    import urllib.request
    
    urls = [
        'http://example.com',
        'http://example.org',
        'http://example.net',
    ] * 10
    
    def fetch_url(url):
        """Simulated URL fetch"""
        time.sleep(0.1)  # Simulate network delay
        return url
    
    print("8. Practical Example: I/O-Bound Task")
    
    # Threading (good for I/O)
    start = time.perf_counter()
    with ThreadPoolExecutor(max_workers=10) as executor:
        results = list(executor.map(fetch_url, urls))
    thread_time = time.perf_counter() - start
    
    print(f"Threading: {thread_time:.4f}s")
    
    # Would be slower with multiprocessing due to overhead
    print("(Multiprocessing would be slower due to process overhead)")
    print()

web_scraper_comparison()


# 9. GIL-free Python alternatives
print("9. GIL-Free Alternatives")
print("- Jython: Python for JVM (no GIL)")
print("- IronPython: Python for .NET (no GIL)")
print("- PyPy-STM: Experimental Software Transactional Memory")
print("- nogil: Experimental CPython fork")
print("- PEP 703: Making GIL optional (Python 3.13+)")
```

