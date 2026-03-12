Deep Dive into Python OOP Concepts
Table of Contents
Classes and Objects
Attributes and Methods
Constructors and Destructors
Encapsulation
Inheritance
Polymorphism
Abstraction
Special/Magic Methods
Class vs Instance Methods vs Static Methods
Property Decorators
Method Resolution Order (MRO)
Composition vs Inheritance
1. Classes and Objects
Class = Blueprint/Template
Object = Instance of a class

Python

# Basic class definition
class Dog:
    pass

# Creating objects
dog1 = Dog()
dog2 = Dog()

print(type(dog1))  # <class '__main__.Dog'>
print(dog1 == dog2)  # False (different objects)
Real-World Example: Car Class
Python

class Car:
    # Class attribute (shared by all instances)
    wheels = 4
    
    def __init__(self, brand, model, year):
        # Instance attributes (unique to each instance)
        self.brand = brand
        self.model = model
        self.year = year
        self.odometer = 0
    
    def display_info(self):
        return f"{self.year} {self.brand} {self.model}"
    
    def drive(self, miles):
        self.odometer += miles
        return f"Driven {miles} miles. Total: {self.odometer}"

# Creating instances
car1 = Car("Toyota", "Camry", 2022)
car2 = Car("Honda", "Civic", 2021)

print(car1.display_info())  # 2022 Toyota Camry
print(car1.drive(100))      # Driven 100 miles. Total: 100
print(car2.wheels)          # 4 (class attribute)
2. Attributes and Methods
Types of Attributes
Python

class Employee:
    # 1. Class Attribute
    company = "TechCorp"
    employee_count = 0
    
    def __init__(self, name, salary):
        # 2. Instance Attributes
        self.name = name
        self.salary = salary
        self.__private_id = id(self)  # Private attribute
        Employee.employee_count += 1
    
    # Instance Method
    def get_details(self):
        return f"{self.name} works at {self.company}"
    
    # Accessing private attribute
    def get_id(self):
        return self.__private_id

emp1 = Employee("Alice", 50000)
emp2 = Employee("Bob", 60000)

print(Employee.employee_count)  # 2
print(emp1.get_details())       # Alice works at TechCorp
print(emp1.get_id())            # Unique ID
Dynamic Attributes
Python

class Person:
    def __init__(self, name):
        self.name = name

person = Person("John")
person.age = 30  # Adding attribute dynamically
print(person.age)  # 30

# Using __dict__ to see all attributes
print(person.__dict__)  # {'name': 'John', 'age': 30}
3. Constructors and Destructors
Python

class Resource:
    def __init__(self, name):
        """Constructor - called when object is created"""
        self.name = name
        print(f"Resource {self.name} initialized")
    
    def __del__(self):
        """Destructor - called when object is destroyed"""
        print(f"Resource {self.name} destroyed")

# Usage
resource = Resource("Database")
# Output: Resource Database initialized

resource = None  # Trigger destructor
# Output: Resource Database destroyed
Parameterized Constructor
Python

class Rectangle:
    def __init__(self, width=0, height=0):
        """Constructor with default parameters"""
        self.width = width
        self.height = height
    
    def area(self):
        return self.width * self.height

rect1 = Rectangle(5, 10)
rect2 = Rectangle()  # Uses defaults

print(rect1.area())  # 50
print(rect2.area())  # 0
4. Encapsulation
Encapsulation = Bundling data and methods + restricting access

Access Modifiers in Python
Python

class BankAccount:
    def __init__(self, account_number, balance):
        self.account_number = account_number    # Public
        self._balance = balance                 # Protected (convention)
        self.__pin = "1234"                     # Private (name mangling)
    
    # Public method
    def deposit(self, amount):
        if amount > 0:
            self._balance += amount
            return True
        return False
    
    # Public method to access private data
    def withdraw(self, amount, pin):
        if pin == self.__pin and amount <= self._balance:
            self._balance -= amount
            return True
        return False
    
    def get_balance(self):
        return self._balance
    
    # Private method
    def __validate_transaction(self, amount):
        return amount > 0 and amount <= self._balance

# Usage
account = BankAccount("123456", 1000)
print(account.account_number)      # 123456 (public)
print(account._balance)            # 1000 (accessible but shouldn't be used)
# print(account.__pin)             # AttributeError
print(account._BankAccount__pin)   # 1234 (name mangling - not recommended)

account.deposit(500)
print(account.get_balance())       # 1500
Real-World Example: Student Grade System
Python

class Student:
    def __init__(self, name, roll_number):
        self.name = name
        self.roll_number = roll_number
        self.__grades = []  # Private
    
    def add_grade(self, subject, marks):
        if 0 <= marks <= 100:
            self.__grades.append({'subject': subject, 'marks': marks})
        else:
            raise ValueError("Marks must be between 0 and 100")
    
    def get_average(self):
        if not self.__grades:
            return 0
        total = sum(grade['marks'] for grade in self.__grades)
        return total / len(self.__grades)
    
    def get_grades(self):
        # Return copy, not original
        return self.__grades.copy()

student = Student("Emma", "A001")
student.add_grade("Math", 85)
student.add_grade("Science", 92)

print(f"Average: {student.get_average():.2f}")  # Average: 88.50
print(student.get_grades())  # [{'subject': 'Math', 'marks': 85}, ...]
5. Inheritance
Inheritance allows a class to inherit attributes and methods from another class.

Single Inheritance
Python

class Animal:
    def __init__(self, name):
        self.name = name
    
    def speak(self):
        return "Some sound"
    
    def info(self):
        return f"I am {self.name}"

class Dog(Animal):  # Dog inherits from Animal
    def speak(self):  # Method overriding
        return "Woof!"
    
    def fetch(self):  # New method
        return f"{self.name} is fetching the ball"

# Usage
dog = Dog("Buddy")
print(dog.info())    # I am Buddy (inherited)
print(dog.speak())   # Woof! (overridden)
print(dog.fetch())   # Buddy is fetching the ball
Multi-Level Inheritance
Python

class Vehicle:
    def __init__(self, brand):
        self.brand = brand
    
    def start(self):
        return f"{self.brand} vehicle starting"

class Car(Vehicle):
    def __init__(self, brand, model):
        super().__init__(brand)  # Call parent constructor
        self.model = model
    
    def drive(self):
        return "Driving on road"

class ElectricCar(Car):
    def __init__(self, brand, model, battery_capacity):
        super().__init__(brand, model)
        self.battery_capacity = battery_capacity
    
    def charge(self):
        return f"Charging {self.battery_capacity}kWh battery"

# Usage
tesla = ElectricCar("Tesla", "Model 3", 75)
print(tesla.start())    # Tesla vehicle starting
print(tesla.drive())    # Driving on road
print(tesla.charge())   # Charging 75kWh battery
Multiple Inheritance
Python

class Flyer:
    def fly(self):
        return "Flying in the air"

class Swimmer:
    def swim(self):
        return "Swimming in water"

class Duck(Flyer, Swimmer):  # Multiple inheritance
    def quack(self):
        return "Quack quack!"

# Usage
duck = Duck()
print(duck.fly())    # Flying in the air
print(duck.swim())   # Swimming in water
print(duck.quack())  # Quack quack!
Complex Inheritance Example
Python

class Person:
    def __init__(self, name, age):
        self.name = name
        self.age = age
    
    def introduce(self):
        return f"Hi, I'm {self.name}, {self.age} years old"

class Employee(Person):
    def __init__(self, name, age, employee_id, salary):
        super().__init__(name, age)
        self.employee_id = employee_id
        self.salary = salary
    
    def work(self):
        return f"{self.name} is working"

class Manager(Employee):
    def __init__(self, name, age, employee_id, salary, department):
        super().__init__(name, age, employee_id, salary)
        self.department = department
        self.team = []
    
    def add_team_member(self, employee):
        self.team.append(employee)
    
    def show_team(self):
        return [member.name for member in self.team]

# Usage
emp1 = Employee("John", 28, "E001", 50000)
emp2 = Employee("Sarah", 25, "E002", 48000)
manager = Manager("Mike", 35, "M001", 80000, "IT")

manager.add_team_member(emp1)
manager.add_team_member(emp2)

print(manager.introduce())    # Hi, I'm Mike, 35 years old
print(manager.show_team())    # ['John', 'Sarah']
6. Polymorphism
Polymorphism = "Many forms" - same interface, different implementations

Method Overriding
Python

class Shape:
    def area(self):
        return 0
    
    def perimeter(self):
        return 0

class Circle(Shape):
    def __init__(self, radius):
        self.radius = radius
    
    def area(self):
        return 3.14 * self.radius ** 2
    
    def perimeter(self):
        return 2 * 3.14 * self.radius

class Rectangle(Shape):
    def __init__(self, width, height):
        self.width = width
        self.height = height
    
    def area(self):
        return self.width * self.height
    
    def perimeter(self):
        return 2 * (self.width + self.height)

# Polymorphic behavior
def print_shape_info(shape):
    print(f"Area: {shape.area()}")
    print(f"Perimeter: {shape.perimeter()}")

circle = Circle(5)
rectangle = Rectangle(4, 6)

print_shape_info(circle)      # Uses Circle's methods
print_shape_info(rectangle)   # Uses Rectangle's methods
Operator Overloading
Python

class Vector:
    def __init__(self, x, y):
        self.x = x
        self.y = y
    
    def __add__(self, other):
        """Overload + operator"""
        return Vector(self.x + other.x, self.y + other.y)
    
    def __sub__(self, other):
        """Overload - operator"""
        return Vector(self.x - other.x, self.y - other.y)
    
    def __mul__(self, scalar):
        """Overload * operator"""
        return Vector(self.x * scalar, self.y * scalar)
    
    def __str__(self):
        """String representation"""
        return f"Vector({self.x}, {self.y})"
    
    def __eq__(self, other):
        """Overload == operator"""
        return self.x == other.x and self.y == other.y

# Usage
v1 = Vector(2, 3)
v2 = Vector(4, 5)

v3 = v1 + v2
print(v3)  # Vector(6, 8)

v4 = v2 - v1
print(v4)  # Vector(2, 2)

v5 = v1 * 3
print(v5)  # Vector(6, 9)

print(v1 == v2)  # False
Duck Typing (Python's Polymorphism)
Python

class Dog:
    def speak(self):
        return "Woof!"

class Cat:
    def speak(self):
        return "Meow!"

class Robot:
    def speak(self):
        return "Beep boop!"

def make_it_speak(thing):
    # Doesn't care about type, only if it has speak()
    print(thing.speak())

# All work because they have speak() method
make_it_speak(Dog())    # Woof!
make_it_speak(Cat())    # Meow!
make_it_speak(Robot())  # Beep boop!
7. Abstraction
Abstraction = Hiding complex implementation details, showing only essential features

Using ABC (Abstract Base Class)
Python

from abc import ABC, abstractmethod

class PaymentProcessor(ABC):
    """Abstract base class"""
    
    @abstractmethod
    def process_payment(self, amount):
        """Must be implemented by subclasses"""
        pass
    
    @abstractmethod
    def refund(self, transaction_id):
        """Must be implemented by subclasses"""
        pass
    
    def log_transaction(self, message):
        """Concrete method (shared by all)"""
        print(f"LOG: {message}")

class CreditCardProcessor(PaymentProcessor):
    def process_payment(self, amount):
        self.log_transaction(f"Processing credit card payment: ${amount}")
        return f"Charged ${amount} to credit card"
    
    def refund(self, transaction_id):
        self.log_transaction(f"Refunding transaction: {transaction_id}")
        return f"Refunded transaction {transaction_id}"

class PayPalProcessor(PaymentProcessor):
    def process_payment(self, amount):
        self.log_transaction(f"Processing PayPal payment: ${amount}")
        return f"Paid ${amount} via PayPal"
    
    def refund(self, transaction_id):
        self.log_transaction(f"Refunding PayPal transaction: {transaction_id}")
        return f"Refunded PayPal transaction {transaction_id}"

# Cannot instantiate abstract class
# processor = PaymentProcessor()  # TypeError

# Can instantiate concrete classes
cc_processor = CreditCardProcessor()
print(cc_processor.process_payment(100))
# LOG: Processing credit card payment: $100
# Charged $100 to credit card

paypal_processor = PayPalProcessor()
print(paypal_processor.refund("TXN123"))
# LOG: Refunding PayPal transaction: TXN123
# Refunded PayPal transaction TXN123
Real-World Example: Database Connection
Python

from abc import ABC, abstractmethod

class Database(ABC):
    @abstractmethod
    def connect(self):
        pass
    
    @abstractmethod
    def disconnect(self):
        pass
    
    @abstractmethod
    def execute_query(self, query):
        pass

class MySQLDatabase(Database):
    def connect(self):
        return "Connected to MySQL"
    
    def disconnect(self):
        return "Disconnected from MySQL"
    
    def execute_query(self, query):
        return f"Executing MySQL query: {query}"

class PostgreSQLDatabase(Database):
    def connect(self):
        return "Connected to PostgreSQL"
    
    def disconnect(self):
        return "Disconnected from PostgreSQL"
    
    def execute_query(self, query):
        return f"Executing PostgreSQL query: {query}"

# Database manager that works with any database
class DatabaseManager:
    def __init__(self, database: Database):
        self.database = database
    
    def run_query(self, query):
        self.database.connect()
        result = self.database.execute_query(query)
        self.database.disconnect()
        return result

# Usage
mysql = MySQLDatabase()
postgres = PostgreSQLDatabase()

manager1 = DatabaseManager(mysql)
print(manager1.run_query("SELECT * FROM users"))

manager2 = DatabaseManager(postgres)
print(manager2.run_query("SELECT * FROM users"))
8. Special/Magic Methods
Also called "dunder" methods (double underscore)

Python

class Book:
    def __init__(self, title, author, pages):
        self.title = title
        self.author = author
        self.pages = pages
    
    def __str__(self):
        """Called by str() and print()"""
        return f"'{self.title}' by {self.author}"
    
    def __repr__(self):
        """Called by repr() - for developers"""
        return f"Book('{self.title}', '{self.author}', {self.pages})"
    
    def __len__(self):
        """Called by len()"""
        return self.pages
    
    def __eq__(self, other):
        """Called by =="""
        return self.title == other.title and self.author == other.author
    
    def __lt__(self, other):
        """Called by <"""
        return self.pages < other.pages
    
    def __add__(self, other):
        """Called by +"""
        return self.pages + other.pages
    
    def __getitem__(self, index):
        """Makes object subscriptable"""
        return f"Page {index} of {self.title}"
    
    def __call__(self):
        """Makes object callable"""
        return f"Reading {self.title}"

# Usage
book1 = Book("Python Crash Course", "Eric Matthes", 544)
book2 = Book("Fluent Python", "Luciano Ramalho", 792)

print(str(book1))       # 'Python Crash Course' by Eric Matthes
print(repr(book1))      # Book('Python Crash Course', 'Eric Matthes', 544)
print(len(book1))       # 544
print(book1 == book2)   # False
print(book1 < book2)    # True (fewer pages)
print(book1 + book2)    # 1336
print(book1[10])        # Page 10 of Python Crash Course
print(book1())          # Reading Python Crash Course
Context Manager Protocol
Python

class FileManager:
    def __init__(self, filename, mode):
        self.filename = filename
        self.mode = mode
        self.file = None
    
    def __enter__(self):
        """Called when entering 'with' block"""
        print(f"Opening {self.filename}")
        self.file = open(self.filename, self.mode)
        return self.file
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        """Called when exiting 'with' block"""
        if self.file:
            print(f"Closing {self.filename}")
            self.file.close()
        # Return False to propagate exceptions
        return False

# Usage
with FileManager('test.txt', 'w') as f:
    f.write("Hello, World!")
# File automatically closed
9. Class vs Instance vs Static Methods
Python

class Pizza:
    def __init__(self, ingredients):
        self.ingredients = ingredients
    
    # Instance method (needs self)
    def describe(self):
        return f"Pizza with {', '.join(self.ingredients)}"
    
    # Class method (needs cls)
    @classmethod
    def margherita(cls):
        """Factory method"""
        return cls(['mozzarella', 'tomatoes', 'basil'])
    
    @classmethod
    def prosciutto(cls):
        """Factory method"""
        return cls(['mozzarella', 'tomatoes', 'ham'])
    
    # Static method (no self or cls)
    @staticmethod
    def is_vegetarian(ingredients):
        meat = ['ham', 'chicken', 'beef', 'pepperoni']
        return not any(item in meat for item in ingredients)

# Usage
# Instance method
custom_pizza = Pizza(['cheese', 'pepperoni', 'mushrooms'])
print(custom_pizza.describe())  
# Pizza with cheese, pepperoni, mushrooms

# Class method (factory)
marg = Pizza.margherita()
print(marg.describe())  
# Pizza with mozzarella, tomatoes, basil

# Static method
print(Pizza.is_vegetarian(['cheese', 'tomatoes']))  # True
print(Pizza.is_vegetarian(['cheese', 'ham']))       # False
Real-World Example: Date Formatter
Python

from datetime import datetime

class DateFormatter:
    def __init__(self, date):
        self.date = date
    
    # Instance method
    def format_us(self):
        return self.date.strftime("%m/%d/%Y")
    
    # Class method - alternative constructor
    @classmethod
    def from_string(cls, date_string, format="%Y-%m-%d"):
        date = datetime.strptime(date_string, format)
        return cls(date)
    
    @classmethod
    def today(cls):
        return cls(datetime.now())
    
    # Static method - utility function
    @staticmethod
    def is_valid_date(date_string, format="%Y-%m-%d"):
        try:
            datetime.strptime(date_string, format)
            return True
        except ValueError:
            return False

# Usage
# Using regular constructor
df1 = DateFormatter(datetime(2024, 1, 15))
print(df1.format_us())  # 01/15/2024

# Using class method (alternative constructor)
df2 = DateFormatter.from_string("2024-01-15")
print(df2.format_us())  # 01/15/2024

df3 = DateFormatter.today()
print(df3.format_us())

# Using static method
print(DateFormatter.is_valid_date("2024-01-15"))  # True
print(DateFormatter.is_valid_date("invalid"))     # False
10. Property Decorators
Properties provide getter, setter, and deleter functionality

Python

class Temperature:
    def __init__(self, celsius=0):
        self._celsius = celsius
    
    @property
    def celsius(self):
        """Getter for celsius"""
        print("Getting celsius value")
        return self._celsius
    
    @celsius.setter
    def celsius(self, value):
        """Setter for celsius"""
        print(f"Setting celsius to {value}")
        if value < -273.15:
            raise ValueError("Temperature below absolute zero!")
        self._celsius = value
    
    @celsius.deleter
    def celsius(self):
        """Deleter for celsius"""
        print("Deleting celsius value")
        del self._celsius
    
    @property
    def fahrenheit(self):
        """Computed property"""
        return (self._celsius * 9/5) + 32
    
    @fahrenheit.setter
    def fahrenheit(self, value):
        self._celsius = (value - 32) * 5/9

# Usage
temp = Temperature(25)
print(temp.celsius)      # Getting celsius value -> 25
temp.celsius = 30        # Setting celsius to 30
print(temp.fahrenheit)   # 86.0

temp.fahrenheit = 98.6
print(temp.celsius)      # Getting celsius value -> 37.0

# temp.celsius = -300    # ValueError: Temperature below absolute zero!
Real-World Example: User Account
Python

import re

class UserAccount:
    def __init__(self, username, email):
        self._username = username
        self._email = email
        self._password = None
    
    @property
    def username(self):
        return self._username
    
    @username.setter
    def username(self, value):
        if len(value) < 3:
            raise ValueError("Username must be at least 3 characters")
        self._username = value
    
    @property
    def email(self):
        return self._email
    
    @email.setter
    def email(self, value):
        pattern = r'^[\w\.-]+@[\w\.-]+\.\w+$'
        if not re.match(pattern, value):
            raise ValueError("Invalid email format")
        self._email = value
    
    @property
    def password(self):
        raise AttributeError("Password is write-only")
    
    @password.setter
    def password(self, value):
        if len(value) < 8:
            raise ValueError("Password must be at least 8 characters")
        # In real app, hash the password
        self._password = f"hashed_{value}"
    
    def verify_password(self, password):
        return self._password == f"hashed_{password}"

# Usage
user = UserAccount("john_doe", "john@example.com")
print(user.username)  # john_doe
print(user.email)     # john@example.com

user.password = "securepass123"
print(user.verify_password("securepass123"))  # True

# print(user.password)  # AttributeError: Password is write-only
11. Method Resolution Order (MRO)
MRO determines the order in which base classes are searched when executing a method

Python

class A:
    def process(self):
        return "A"

class B(A):
    def process(self):
        return "B"

class C(A):
    def process(self):
        return "C"

class D(B, C):
    pass

# MRO: D -> B -> C -> A -> object
d = D()
print(d.process())  # B

# View MRO
print(D.__mro__)
# (<class '__main__.D'>, <class '__main__.B'>, <class '__main__.C'>, 
#  <class '__main__.A'>, <class 'object'>)

print(D.mro())
# Same as above, but as a list
Diamond Problem Example
Python

class Base:
    def __init__(self):
        print("Base.__init__")
        super().__init__()

class Left(Base):
    def __init__(self):
        print("Left.__init__")
        super().__init__()

class Right(Base):
    def __init__(self):
        print("Right.__init__")
        super().__init__()

class Child(Left, Right):
    def __init__(self):
        print("Child.__init__")
        super().__init__()

# Creating instance
c = Child()
# Output:
# Child.__init__
# Left.__init__
# Right.__init__
# Base.__init__

print(Child.mro())
# [<class '__main__.Child'>, <class '__main__.Left'>, 
#  <class '__main__.Right'>, <class '__main__.Base'>, <class 'object'>]
12. Composition vs Inheritance
Inheritance ("is-a" relationship)
Python

class Engine:
    def start(self):
        return "Engine started"
    
    def stop(self):
        return "Engine stopped"

class Car(Engine):  # Inheritance: Car IS-A Engine (not ideal)
    pass

car = Car()
print(car.start())  # Works, but conceptually wrong
Composition ("has-a" relationship)
Python

class Engine:
    def __init__(self, horsepower):
        self.horsepower = horsepower
    
    def start(self):
        return f"{self.horsepower}HP engine started"
    
    def stop(self):
        return "Engine stopped"

class Transmission:
    def __init__(self, type_):
        self.type = type_
    
    def shift(self, gear):
        return f"Shifting {self.type} transmission to gear {gear}"

class Car:  # Composition: Car HAS-A Engine and Transmission
    def __init__(self, brand, engine, transmission):
        self.brand = brand
        self.engine = engine            # Composition
        self.transmission = transmission # Composition
    
    def start(self):
        return f"{self.brand}: {self.engine.start()}"
    
    def drive(self):
        return self.transmission.shift(1)

# Usage
engine = Engine(250)
transmission = Transmission("automatic")
car = Car("Toyota", engine, transmission)

print(car.start())  # Toyota: 250HP engine started
print(car.drive())  # Shifting automatic transmission to gear 1
Real-World Example: Computer System
Python

class CPU:
    def __init__(self, brand, cores):
        self.brand = brand
        self.cores = cores
    
    def process(self):
        return f"{self.brand} CPU with {self.cores} cores processing"

class RAM:
    def __init__(self, size):
        self.size = size
    
    def load(self):
        return f"Loading into {self.size}GB RAM"

class Storage:
    def __init__(self, capacity, type_):
        self.capacity = capacity
        self.type = type_
    
    def read(self):
        return f"Reading from {self.capacity}GB {self.type}"

class Computer:
    def __init__(self, cpu, ram, storage):
        self.cpu = cpu
        self.ram = ram
        self.storage = storage
        self.running = False
    
    def boot(self):
        if not self.running:
            print(self.storage.read())
            print(self.ram.load())
            print(self.cpu.process())
            self.running = True
            return "Computer booted successfully"
        return "Computer already running"
    
    def shutdown(self):
        self.running = False
        return "Computer shut down"

# Building a computer
cpu = CPU("Intel i7", 8)
ram = RAM(16)
storage = Storage(512, "SSD")

my_computer = Computer(cpu, ram, storage)
print(my_computer.boot())
# Reading from 512GB SSD
# Loading into 16GB RAM
# Intel i7 CPU with 8 cores processing
# Computer booted successfully
Advanced OOP Patterns
Singleton Pattern
Python

class Singleton:
    _instance = None
    
    def __new__(cls):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
        return cls._instance

# Usage
s1 = Singleton()
s2 = Singleton()
print(s1 is s2)  # True - same instance
Factory Pattern
Python

class Dog:
    def speak(self):
        return "Woof!"

class Cat:
    def speak(self):
        return "Meow!"

class AnimalFactory:
    @staticmethod
    def create_animal(animal_type):
        if animal_type == "dog":
            return Dog()
        elif animal_type == "cat":
            return Cat()
        else:
            raise ValueError(f"Unknown animal type: {animal_type}")

# Usage
factory = AnimalFactory()
dog = factory.create_animal("dog")
cat = factory.create_animal("cat")

print(dog.speak())  # Woof!
print(cat.speak())  # Meow!
Observer Pattern
Python

class Subject:
    def __init__(self):
        self._observers = []
        self._state = None
    
    def attach(self, observer):
        self._observers.append(observer)
    
    def detach(self, observer):
        self._observers.remove(observer)
    
    def notify(self):
        for observer in self._observers:
            observer.update(self._state)
    
    def set_state(self, state):
        self._state = state
        self.notify()

class Observer:
    def __init__(self, name):
        self.name = name
    
    def update(self, state):
        print(f"{self.name} received update: {state}")

# Usage
subject = Subject()

observer1 = Observer("Observer 1")
observer2 = Observer("Observer 2")

subject.attach(observer1)
subject.attach(observer2)

subject.set_state("State changed!")
# Observer 1 received update: State changed!
# Observer 2 received update: State changed!

Deep Dive: OOP Best Practices in Python
1. Composition Over Inheritance
❌ Bad: Inheritance Abuse
Python

# Wrong approach - using inheritance for code reuse
class Logger:
    def log(self, message):
        print(f"LOG: {message}")

class DataProcessor(Logger):  # IS-A relationship doesn't make sense
    def process(self, data):
        self.log("Processing started")
        # process data
        self.log("Processing completed")
✅ Good: Composition
Python

# Correct approach - using composition
class Logger:
    def log(self, message):
        print(f"LOG: {message}")

class DataProcessor:
    def __init__(self, logger):
        self.logger = logger  # HAS-A relationship
    
    def process(self, data):
        self.logger.log("Processing started")
        # process data
        self.logger.log("Processing completed")

# Usage
logger = Logger()
processor = DataProcessor(logger)
processor.process([1, 2, 3])
Real-World Example: E-commerce System
Python

from datetime import datetime
from typing import List

# Components that can be composed
class PaymentGateway:
    def process_payment(self, amount, card_number):
        return f"Processed ${amount} payment"

class ShippingService:
    def calculate_shipping(self, weight, destination):
        return weight * 2.5
    
    def ship(self, address):
        return f"Shipping to {address}"

class InventoryManager:
    def __init__(self):
        self.stock = {}
    
    def check_availability(self, product_id, quantity):
        return self.stock.get(product_id, 0) >= quantity
    
    def reduce_stock(self, product_id, quantity):
        if product_id in self.stock:
            self.stock[product_id] -= quantity

class NotificationService:
    def send_email(self, email, message):
        return f"Email sent to {email}: {message}"
    
    def send_sms(self, phone, message):
        return f"SMS sent to {phone}: {message}"

# Main class using composition
class Order:
    """
    Order management system using composition.
    Delegates responsibilities to specialized components.
    """
    
    def __init__(
        self,
        payment_gateway: PaymentGateway,
        shipping_service: ShippingService,
        inventory_manager: InventoryManager,
        notification_service: NotificationService
    ):
        # Composition: Order HAS-A payment gateway, shipping service, etc.
        self.payment = payment_gateway
        self.shipping = shipping_service
        self.inventory = inventory_manager
        self.notifications = notification_service
        
        self.items = []
        self.status = "pending"
    
    def add_item(self, product_id, quantity, price):
        """Add item to order"""
        if self.inventory.check_availability(product_id, quantity):
            self.items.append({
                'product_id': product_id,
                'quantity': quantity,
                'price': price
            })
            return True
        return False
    
    def calculate_total(self):
        """Calculate order total"""
        return sum(item['price'] * item['quantity'] for item in self.items)
    
    def place_order(self, card_number, shipping_address, email):
        """Complete order process"""
        # Calculate total
        total = self.calculate_total()
        
        # Process payment
        payment_result = self.payment.process_payment(total, card_number)
        
        # Update inventory
        for item in self.items:
            self.inventory.reduce_stock(item['product_id'], item['quantity'])
        
        # Arrange shipping
        shipping_result = self.shipping.ship(shipping_address)
        
        # Send confirmation
        self.notifications.send_email(
            email, 
            f"Order confirmed. {payment_result}. {shipping_result}"
        )
        
        self.status = "completed"
        return f"Order placed successfully. Total: ${total}"

# Usage
payment_gateway = PaymentGateway()
shipping_service = ShippingService()
inventory = InventoryManager()
inventory.stock = {'PROD001': 100, 'PROD002': 50}
notifications = NotificationService()

order = Order(payment_gateway, shipping_service, inventory, notifications)
order.add_item('PROD001', 2, 29.99)
order.add_item('PROD002', 1, 49.99)

result = order.place_order(
    card_number="1234-5678-9012-3456",
    shipping_address="123 Main St",
    email="customer@example.com"
)
print(result)
2. SOLID Principles
2.1 Single Responsibility Principle (SRP)
A class should have only one reason to change

❌ Bad: Multiple Responsibilities
Python

class User:
    def __init__(self, name, email):
        self.name = name
        self.email = email
    
    def save_to_database(self):
        # Database logic - first responsibility
        print(f"Saving {self.name} to database")
    
    def send_welcome_email(self):
        # Email logic - second responsibility
        print(f"Sending email to {self.email}")
    
    def generate_report(self):
        # Report generation - third responsibility
        return f"Report for {self.name}"
✅ Good: Single Responsibility
Python

class User:
    """Responsible only for user data"""
    def __init__(self, name, email):
        self.name = name
        self.email = email
    
    def get_info(self):
        return f"{self.name} ({self.email})"

class UserRepository:
    """Responsible only for database operations"""
    def save(self, user: User):
        print(f"Saving {user.name} to database")
    
    def find_by_email(self, email):
        print(f"Finding user with email: {email}")
    
    def delete(self, user: User):
        print(f"Deleting {user.name} from database")

class EmailService:
    """Responsible only for email operations"""
    def send_welcome_email(self, user: User):
        print(f"Sending welcome email to {user.email}")
    
    def send_notification(self, user: User, message):
        print(f"Sending to {user.email}: {message}")

class ReportGenerator:
    """Responsible only for report generation"""
    def generate_user_report(self, user: User):
        return f"Report for {user.name}"
    
    def generate_analytics_report(self, users):
        return f"Analytics for {len(users)} users"

# Usage
user = User("John Doe", "john@example.com")
repository = UserRepository()
email_service = EmailService()
report_generator = ReportGenerator()

repository.save(user)
email_service.send_welcome_email(user)
report = report_generator.generate_user_report(user)
2.2 Open/Closed Principle (OCP)
Open for extension, closed for modification

❌ Bad: Modifying existing code
Python

class DiscountCalculator:
    def calculate_discount(self, customer_type, amount):
        if customer_type == "regular":
            return amount * 0.05
        elif customer_type == "premium":
            return amount * 0.10
        elif customer_type == "vip":
            return amount * 0.20
        # Adding new customer type requires modifying this method
✅ Good: Extensible design
Python

from abc import ABC, abstractmethod

class DiscountStrategy(ABC):
    """Abstract base class for discount strategies"""
    
    @abstractmethod
    def calculate_discount(self, amount):
        pass

class RegularDiscount(DiscountStrategy):
    def calculate_discount(self, amount):
        return amount * 0.05

class PremiumDiscount(DiscountStrategy):
    def calculate_discount(self, amount):
        return amount * 0.10

class VIPDiscount(DiscountStrategy):
    def calculate_discount(self, amount):
        return amount * 0.20

class SeasonalDiscount(DiscountStrategy):
    """New discount type - no need to modify existing code"""
    def calculate_discount(self, amount):
        return amount * 0.15

class DiscountCalculator:
    """
    Open for extension (new strategies), 
    closed for modification (no need to change this class)
    """
    def __init__(self, strategy: DiscountStrategy):
        self.strategy = strategy
    
    def calculate(self, amount):
        return self.strategy.calculate_discount(amount)

# Usage
regular_calc = DiscountCalculator(RegularDiscount())
print(regular_calc.calculate(100))  # 5.0

vip_calc = DiscountCalculator(VIPDiscount())
print(vip_calc.calculate(100))  # 20.0

seasonal_calc = DiscountCalculator(SeasonalDiscount())
print(seasonal_calc.calculate(100))  # 15.0
2.3 Liskov Substitution Principle (LSP)
Subtypes must be substitutable for their base types

❌ Bad: Violates LSP
Python

class Bird:
    def fly(self):
        return "Flying"

class Penguin(Bird):
    def fly(self):
        raise Exception("Penguins can't fly!")  # Violates LSP

def make_bird_fly(bird: Bird):
    return bird.fly()

# This breaks!
# penguin = Penguin()
# make_bird_fly(penguin)  # Exception!
✅ Good: Follows LSP
Python

from abc import ABC, abstractmethod

class Bird(ABC):
    """Base class for all birds"""
    
    @abstractmethod
    def move(self):
        pass

class FlyingBird(Bird):
    """Base class for birds that can fly"""
    def move(self):
        return self.fly()
    
    def fly(self):
        return "Flying through the air"

class FlightlessBird(Bird):
    """Base class for birds that cannot fly"""
    def move(self):
        return self.walk()
    
    def walk(self):
        return "Walking on the ground"

class Sparrow(FlyingBird):
    pass

class Penguin(FlightlessBird):
    def swim(self):
        return "Swimming in water"

# Now this works for all birds
def move_bird(bird: Bird):
    return bird.move()

sparrow = Sparrow()
penguin = Penguin()

print(move_bird(sparrow))   # Flying through the air
print(move_bird(penguin))   # Walking on the ground
2.4 Interface Segregation Principle (ISP)
Clients shouldn't depend on interfaces they don't use

❌ Bad: Fat Interface
Python

from abc import ABC, abstractmethod

class Worker(ABC):
    @abstractmethod
    def work(self):
        pass
    
    @abstractmethod
    def eat(self):
        pass
    
    @abstractmethod
    def sleep(self):
        pass

class Human(Worker):
    def work(self):
        return "Working"
    
    def eat(self):
        return "Eating"
    
    def sleep(self):
        return "Sleeping"

class Robot(Worker):
    def work(self):
        return "Working"
    
    def eat(self):
        raise NotImplementedError("Robots don't eat")  # Forced to implement
    
    def sleep(self):
        raise NotImplementedError("Robots don't sleep")  # Forced to implement
✅ Good: Segregated Interfaces
Python

from abc import ABC, abstractmethod

class Workable(ABC):
    """Interface for entities that can work"""
    @abstractmethod
    def work(self):
        pass

class Eatable(ABC):
    """Interface for entities that can eat"""
    @abstractmethod
    def eat(self):
        pass

class Sleepable(ABC):
    """Interface for entities that can sleep"""
    @abstractmethod
    def sleep(self):
        pass

class Human(Workable, Eatable, Sleepable):
    """Humans implement all three interfaces"""
    def work(self):
        return "Human working"
    
    def eat(self):
        return "Human eating"
    
    def sleep(self):
        return "Human sleeping"

class Robot(Workable):
    """Robots only implement what they need"""
    def work(self):
        return "Robot working"
    
    def recharge(self):
        return "Robot recharging"

class Manager:
    """Can work with any workable entity"""
    def manage(self, worker: Workable):
        return worker.work()

# Usage
human = Human()
robot = Robot()

manager = Manager()
print(manager.manage(human))  # Human working
print(manager.manage(robot))  # Robot working
2.5 Dependency Inversion Principle (DIP)
Depend on abstractions, not concretions

❌ Bad: High-level depends on low-level
Python

class MySQLDatabase:
    def save(self, data):
        print(f"Saving to MySQL: {data}")

class UserService:
    def __init__(self):
        self.database = MySQLDatabase()  # Tight coupling
    
    def save_user(self, user):
        self.database.save(user)
# Hard to test, hard to switch databases
✅ Good: Both depend on abstraction
Python

from abc import ABC, abstractmethod
from typing import Any

class Database(ABC):
    """
    Abstract interface for database operations.
    Both high-level and low-level modules depend on this.
    """
    
    @abstractmethod
    def save(self, data: Any) -> bool:
        pass
    
    @abstractmethod
    def find(self, id: str) -> Any:
        pass
    
    @abstractmethod
    def delete(self, id: str) -> bool:
        pass

class MySQLDatabase(Database):
    """Low-level module - implements abstraction"""
    def save(self, data: Any) -> bool:
        print(f"Saving to MySQL: {data}")
        return True
    
    def find(self, id: str) -> Any:
        print(f"Finding in MySQL: {id}")
        return {"id": id, "data": "..."}
    
    def delete(self, id: str) -> bool:
        print(f"Deleting from MySQL: {id}")
        return True

class PostgreSQLDatabase(Database):
    """Another low-level module"""
    def save(self, data: Any) -> bool:
        print(f"Saving to PostgreSQL: {data}")
        return True
    
    def find(self, id: str) -> Any:
        print(f"Finding in PostgreSQL: {id}")
        return {"id": id, "data": "..."}
    
    def delete(self, id: str) -> bool:
        print(f"Deleting from PostgreSQL: {id}")
        return True

class MongoDatabase(Database):
    """Yet another low-level module"""
    def save(self, data: Any) -> bool:
        print(f"Saving to MongoDB: {data}")
        return True
    
    def find(self, id: str) -> Any:
        print(f"Finding in MongoDB: {id}")
        return {"id": id, "data": "..."}
    
    def delete(self, id: str) -> bool:
        print(f"Deleting from MongoDB: {id}")
        return True

class UserService:
    """
    High-level module - depends on abstraction (Database).
    Doesn't know or care about specific database implementation.
    """
    
    def __init__(self, database: Database):
        self.database = database  # Dependency injection
    
    def save_user(self, user_data):
        """Save user to database"""
        return self.database.save(user_data)
    
    def get_user(self, user_id):
        """Retrieve user from database"""
        return self.database.find(user_id)
    
    def delete_user(self, user_id):
        """Delete user from database"""
        return self.database.delete(user_id)

# Usage - Easy to swap implementations
mysql_db = MySQLDatabase()
postgres_db = PostgreSQLDatabase()
mongo_db = MongoDatabase()

# Use MySQL
user_service = UserService(mysql_db)
user_service.save_user({"name": "John"})

# Switch to PostgreSQL without changing UserService
user_service = UserService(postgres_db)
user_service.save_user({"name": "Jane"})

# Switch to MongoDB
user_service = UserService(mongo_db)
user_service.save_user({"name": "Bob"})
3. Properties for Controlled Access
Basic Property Usage
Python

class Temperature:
    """
    Temperature class with validation using properties.
    Provides controlled access to internal state.
    """
    
    def __init__(self, celsius=0):
        self._celsius = celsius  # Private attribute
    
    @property
    def celsius(self):
        """
        Getter for celsius temperature.
        Allows controlled read access.
        """
        return self._celsius
    
    @celsius.setter
    def celsius(self, value):
        """
        Setter for celsius temperature.
        Validates input before setting.
        """
        if value < -273.15:
            raise ValueError(
                "Temperature cannot be below absolute zero (-273.15°C)"
            )
        self._celsius = value
    
    @property
    def fahrenheit(self):
        """Computed property - derived from celsius"""
        return (self._celsius * 9/5) + 32
    
    @fahrenheit.setter
    def fahrenheit(self, value):
        """Setting fahrenheit also updates celsius"""
        self.celsius = (value - 32) * 5/9
    
    @property
    def kelvin(self):
        """Another computed property"""
        return self._celsius + 273.15
    
    @kelvin.setter
    def kelvin(self, value):
        """Setting kelvin also updates celsius"""
        self.celsius = value - 273.15

# Usage
temp = Temperature(25)
print(f"Celsius: {temp.celsius}°C")       # 25
print(f"Fahrenheit: {temp.fahrenheit}°F") # 77.0
print(f"Kelvin: {temp.kelvin}K")          # 298.15

# Set via fahrenheit
temp.fahrenheit = 100
print(f"Celsius: {temp.celsius}°C")       # 37.77...

# Validation works
try:
    temp.celsius = -300
except ValueError as e:
    print(f"Error: {e}")
Real-World Example: Bank Account
Python

from datetime import datetime
from typing import List, Dict

class BankAccount:
    """
    Bank account with controlled access to balance and transactions.
    Demonstrates property usage for validation and encapsulation.
    """
    
    _account_counter = 1000
    
    def __init__(self, owner: str, initial_balance: float = 0):
        self._account_number = BankAccount._account_counter
        BankAccount._account_counter += 1
        
        self._owner = owner
        self._balance = 0
        self._transactions: List[Dict] = []
        self._is_active = True
        
        if initial_balance > 0:
            self.deposit(initial_balance)
    
    @property
    def account_number(self):
        """Read-only property - account number cannot be changed"""
        return f"ACC{self._account_number:06d}"
    
    @property
    def owner(self):
        """Getter for owner name"""
        return self._owner
    
    @owner.setter
    def owner(self, value: str):
        """Setter with validation"""
        if not value or not value.strip():
            raise ValueError("Owner name cannot be empty")
        if len(value) < 2:
            raise ValueError("Owner name must be at least 2 characters")
        self._owner = value.strip()
    
    @property
    def balance(self):
        """
        Read-only balance property.
        Balance can only be changed through deposit/withdraw.
        """
        return self._balance
    
    @property
    def is_active(self):
        """Check if account is active"""
        return self._is_active
    
    @property
    def transactions(self):
        """Return copy of transactions (not the original list)"""
        return self._transactions.copy()
    
    def deposit(self, amount: float) -> bool:
        """
        Deposit money into account.
        This is the only way to increase balance.
        """
        if not self._is_active:
            raise ValueError("Account is inactive")
        
        if amount <= 0:
            raise ValueError("Deposit amount must be positive")
        
        self._balance += amount
        self._record_transaction("deposit", amount)
        return True
    
    def withdraw(self, amount: float) -> bool:
        """
        Withdraw money from account.
        This is the only way to decrease balance.
        """
        if not self._is_active:
            raise ValueError("Account is inactive")
        
        if amount <= 0:
            raise ValueError("Withdrawal amount must be positive")
        
        if amount > self._balance:
            raise ValueError(
                f"Insufficient funds. Balance: ${self._balance:.2f}"
            )
        
        self._balance -= amount
        self._record_transaction("withdrawal", amount)
        return True
    
    def close_account(self):
        """Close the account"""
        if self._balance > 0:
            raise ValueError(
                "Cannot close account with positive balance. "
                "Please withdraw all funds first."
            )
        self._is_active = False
    
    def _record_transaction(self, type_: str, amount: float):
        """Private method to record transactions"""
        self._transactions.append({
            'type': type_,
            'amount': amount,
            'timestamp': datetime.now(),
            'balance_after': self._balance
        })
    
    def __str__(self):
        status = "Active" if self._is_active else "Closed"
        return (
            f"Account {self.account_number}\n"
            f"Owner: {self.owner}\n"
            f"Balance: ${self.balance:.2f}\n"
            f"Status: {status}"
        )

# Usage
account = BankAccount("John Doe", 1000)
print(account)
print()

# Properties provide controlled access
print(f"Account Number: {account.account_number}")  # Read-only
print(f"Balance: ${account.balance:.2f}")           # Read-only

# Can only change balance through methods
account.deposit(500)
account.withdraw(200)

print(f"New Balance: ${account.balance:.2f}")

# Cannot directly modify balance
try:
    account.balance = 99999  # AttributeError
except AttributeError:
    print("Cannot directly modify balance!")

# Can change owner with validation
try:
    account.owner = "J"  # Too short
except ValueError as e:
    print(f"Error: {e}")

account.owner = "Jane Doe"  # Valid
print(f"New Owner: {account.owner}")

# View transactions
print("\nTransactions:")
for tx in account.transactions:
    print(f"  {tx['type']}: ${tx['amount']:.2f} at {tx['timestamp']}")
4. Abstract Base Classes (ABC)
Payment Processing System
Python

from abc import ABC, abstractmethod
from typing import Dict, Optional
from enum import Enum

class PaymentStatus(Enum):
    """Enum for payment status"""
    PENDING = "pending"
    COMPLETED = "completed"
    FAILED = "failed"
    REFUNDED = "refunded"

class PaymentMethod(ABC):
    """
    Abstract base class defining the interface for payment methods.
    All payment methods must implement these methods.
    """
    
    @abstractmethod
    def validate(self) -> bool:
        """
        Validate payment method details.
        Must be implemented by all subclasses.
        """
        pass
    
    @abstractmethod
    def process_payment(self, amount: float) -> Dict:
        """
        Process a payment.
        Returns a dictionary with transaction details.
        """
        pass
    
    @abstractmethod
    def refund(self, transaction_id: str, amount: float) -> Dict:
        """
        Process a refund.
        Returns a dictionary with refund details.
        """
        pass
    
    def log_transaction(self, message: str):
        """
        Concrete method - shared by all payment methods.
        Subclasses can use this without overriding.
        """
        print(f"[TRANSACTION LOG] {message}")

class CreditCard(PaymentMethod):
    """
    Credit card payment implementation.
    Implements all abstract methods from PaymentMethod.
    """
    
    def __init__(self, card_number: str, cvv: str, expiry: str):
        self.card_number = card_number
        self.cvv = cvv
        self.expiry = expiry
    
    def validate(self) -> bool:
        """Validate credit card details"""
        # Simple validation (in production, use proper validation)
        if len(self.card_number) != 16:
            return False
        if len(self.cvv) != 3:
            return False
        # Check expiry format, etc.
        return True
    
    def process_payment(self, amount: float) -> Dict:
        """Process credit card payment"""
        if not self.validate():
            self.log_transaction(f"Invalid card details")
            return {
                'status': PaymentStatus.FAILED,
                'message': 'Invalid card details'
            }
        
        # Simulate payment processing
        masked_card = f"****-****-****-{self.card_number[-4:]}"
        self.log_transaction(
            f"Processing ${amount:.2f} on card {masked_card}"
        )
        
        return {
            'status': PaymentStatus.COMPLETED,
            'amount': amount,
            'card': masked_card,
            'transaction_id': f"CC-{hash(self.card_number) % 100000}"
        }
    
    def refund(self, transaction_id: str, amount: float) -> Dict:
        """Process credit card refund"""
        self.log_transaction(
            f"Refunding ${amount:.2f} to transaction {transaction_id}"
        )
        return {
            'status': PaymentStatus.REFUNDED,
            'amount': amount,
            'transaction_id': transaction_id
        }

class PayPal(PaymentMethod):
    """PayPal payment implementation"""
    
    def __init__(self, email: str, password: str):
        self.email = email
        self.password = password
    
    def validate(self) -> bool:
        """Validate PayPal credentials"""
        return '@' in self.email and len(self.password) >= 8
    
    def process_payment(self, amount: float) -> Dict:
        """Process PayPal payment"""
        if not self.validate():
            self.log_transaction(f"Invalid PayPal credentials")
            return {
                'status': PaymentStatus.FAILED,
                'message': 'Invalid credentials'
            }
        
        self.log_transaction(
            f"Processing ${amount:.2f} via PayPal ({self.email})"
        )
        
        return {
            'status': PaymentStatus.COMPLETED,
            'amount': amount,
            'email': self.email,
            'transaction_id': f"PP-{hash(self.email) % 100000}"
        }
    
    def refund(self, transaction_id: str, amount: float) -> Dict:
        """Process PayPal refund"""
        self.log_transaction(
            f"Refunding ${amount:.2f} to PayPal transaction {transaction_id}"
        )
        return {
            'status': PaymentStatus.REFUNDED,
            'amount': amount,
            'transaction_id': transaction_id
        }

class BankTransfer(PaymentMethod):
    """Bank transfer payment implementation"""
    
    def __init__(self, account_number: str, routing_number: str):
        self.account_number = account_number
        self.routing_number = routing_number
    
    def validate(self) -> bool:
        """Validate bank account details"""
        return (len(self.account_number) >= 8 and 
                len(self.routing_number) == 9)
    
    def process_payment(self, amount: float) -> Dict:
        """Process bank transfer"""
        if not self.validate():
            self.log_transaction(f"Invalid bank account details")
            return {
                'status': PaymentStatus.FAILED,
                'message': 'Invalid account details'
            }
        
        masked_account = f"****{self.account_number[-4:]}"
        self.log_transaction(
            f"Processing ${amount:.2f} via bank transfer to {masked_account}"
        )
        
        return {
            'status': PaymentStatus.COMPLETED,
            'amount': amount,
            'account': masked_account,
            'transaction_id': f"BT-{hash(self.account_number) % 100000}"
        }
    
    def refund(self, transaction_id: str, amount: float) -> Dict:
        """Process bank transfer refund"""
        self.log_transaction(
            f"Refunding ${amount:.2f} to bank account"
        )
        return {
            'status': PaymentStatus.REFUNDED,
            'amount': amount,
            'transaction_id': transaction_id
        }

class PaymentProcessor:
    """
    High-level payment processor.
    Works with any PaymentMethod implementation.
    """
    
    def __init__(self, payment_method: PaymentMethod):
        self.payment_method = payment_method
    
    def charge(self, amount: float) -> Dict:
        """Charge using the configured payment method"""
        print(f"\nProcessing payment of ${amount:.2f}...")
        result = self.payment_method.process_payment(amount)
        
        if result['status'] == PaymentStatus.COMPLETED:
            print(f"✓ Payment successful!")
        else:
            print(f"✗ Payment failed: {result.get('message')}")
        
        return result
    
    def refund_payment(self, transaction_id: str, amount: float) -> Dict:
        """Refund a payment"""
        print(f"\nProcessing refund of ${amount:.2f}...")
        result = self.payment_method.refund(transaction_id, amount)
        
        if result['status'] == PaymentStatus.REFUNDED:
            print(f"✓ Refund successful!")
        
        return result

# Usage
print("=== Credit Card Payment ===")
cc = CreditCard("1234567890123456", "123", "12/25")
processor = PaymentProcessor(cc)
result = processor.charge(99.99)
if result['status'] == PaymentStatus.COMPLETED:
    processor.refund_payment(result['transaction_id'], 99.99)

print("\n=== PayPal Payment ===")
paypal = PayPal("user@example.com", "securepassword")
processor = PaymentProcessor(paypal)
processor.charge(149.99)

print("\n=== Bank Transfer ===")
bank = BankTransfer("12345678", "123456789")
processor = PaymentProcessor(bank)
processor.charge(299.99)

# Cannot instantiate abstract class
try:
    payment = PaymentMethod()  # TypeError
except TypeError as e:
    print(f"\n✗ Error: {e}")
5. Special Methods (Magic Methods)
Complete Example: Custom Collection
Python

from typing import Any, Iterator

class CustomList:
    """
    Custom list implementation demonstrating special methods.
    Makes the class behave like a built-in Python type.
    """
    
    def __init__(self, items=None):
        """
        Constructor - called when object is created.
        Usage: my_list = CustomList([1, 2, 3])
        """
        self._items = list(items) if items else []
    
    def __str__(self):
        """
        String representation for users.
        Called by: str(obj), print(obj)
        """
        return f"CustomList({self._items})"
    
    def __repr__(self):
        """
        String representation for developers.
        Called by: repr(obj), interactive console
        """
        return f"CustomList({self._items!r})"
    
    def __len__(self):
        """
        Length of the collection.
        Called by: len(obj)
        """
        return len(self._items)
    
    def __getitem__(self, index):
        """
        Get item by index.
        Called by: obj[index]
        Supports slicing: obj[1:3]
        """
        return self._items[index]
    
    def __setitem__(self, index, value):
        """
        Set item by index.
        Called by: obj[index] = value
        """
        self._items[index] = value
    
    def __delitem__(self, index):
        """
        Delete item by index.
        Called by: del obj[index]
        """
        del self._items[index]
    
    def __iter__(self):
        """
        Make object iterable.
        Called by: for item in obj
        """
        return iter(self._items)
    
    def __contains__(self, item):
        """
        Membership test.
        Called by: item in obj
        """
        return item in self._items
    
    def __add__(self, other):
        """
        Addition operator.
        Called by: obj1 + obj2
        """
        if isinstance(other, CustomList):
            return CustomList(self._items + other._items)
        return CustomList(self._items + list(other))
    
    def __mul__(self, times):
        """
        Multiplication operator.
        Called by: obj * n
        """
        return CustomList(self._items * times)
    
    def __eq__(self, other):
        """
        Equality comparison.
        Called by: obj1 == obj2
        """
        if isinstance(other, CustomList):
            return self._items == other._items
        return self._items == other
    
    def __lt__(self, other):
        """
        Less than comparison.
        Called by: obj1 < obj2
        Also enables >, <=, >= through reflection
        """
        if isinstance(other, CustomList):
            return len(self._items) < len(other._items)
        return len(self._items) < len(other)
    
    def __bool__(self):
        """
        Boolean conversion.
        Called by: bool(obj), if obj:
        """
        return len(self._items) > 0
    
    def __call__(self, *args):
        """
        Make object callable like a function.
        Called by: obj(args)
        """
        self._items.extend(args)
        return self
    
    def __enter__(self):
        """
        Context manager entry.
        Called by: with obj as x:
        """
        print("Entering context")
        return self
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        """
        Context manager exit.
        Called when leaving: with block
        """
        print("Exiting context")
        self._items.clear()
        return False
    
    def append(self, item):
        """Regular method to add item"""
        self._items.append(item)

# Demonstration
print("=== Creating CustomList ===")
my_list = CustomList([1, 2, 3, 4, 5])

print("\n=== String Representation ===")
print(str(my_list))   # CustomList([1, 2, 3, 4, 5])
print(repr(my_list))  # CustomList([1, 2, 3, 4, 5])

print("\n=== Length ===")
print(len(my_list))   # 5

print("\n=== Indexing ===")
print(my_list[0])     # 1
print(my_list[-1])    # 5
print(my_list[1:3])   # [2, 3]

print("\n=== Setting Items ===")
my_list[0] = 10
print(my_list)        # CustomList([10, 2, 3, 4, 5])

print("\n=== Iteration ===")
for item in my_list:
    print(item, end=' ')  # 10 2 3 4 5
print()

print("\n=== Membership ===")
print(3 in my_list)   # True
print(99 in my_list)  # False

print("\n=== Addition ===")
list2 = CustomList([6, 7])
list3 = my_list + list2
print(list3)          # CustomList([10, 2, 3, 4, 5, 6, 7])

print("\n=== Multiplication ===")
list4 = CustomList([1, 2]) * 3
print(list4)          # CustomList([1, 2, 1, 2, 1, 2])

print("\n=== Comparison ===")
print(my_list == [10, 2, 3, 4, 5])  # True
print(CustomList([1, 2]) < CustomList([1, 2, 3]))  # True

print("\n=== Boolean ===")
print(bool(my_list))          # True
print(bool(CustomList()))     # False

print("\n=== Callable ===")
my_list(6, 7, 8)
print(my_list)                # CustomList([10, 2, 3, 4, 5, 6, 7, 8])

print("\n=== Context Manager ===")
with CustomList([1, 2, 3]) as lst:
    print(f"Inside context: {lst}")
    lst.append(4)
    print(f"After append: {lst}")
print(f"After context: {lst}")  # Empty
6. Using super() Properly
Single Inheritance
Python

class Person:
    """Base class for all persons"""
    
    def __init__(self, name, age):
        print(f"Person.__init__ called for {name}")
        self.name = name
        self.age = age
    
    def introduce(self):
        return f"I'm {self.name}, {self.age} years old"

class Student(Person):
    """Student extends Person"""
    
    def __init__(self, name, age, student_id, major):
        print(f"Student.__init__ called for {name}")
        # Call parent constructor
        super().__init__(name, age)
        self.student_id = student_id
        self.major = major
    
    def introduce(self):
        # Call parent method and extend it
        base_intro = super().introduce()
        return f"{base_intro}, studying {self.major}"

class GraduateStudent(Student):
    """Graduate student extends Student"""
    
    def __init__(self, name, age, student_id, major, thesis_topic):
        print(f"GraduateStudent.__init__ called for {name}")
        super().__init__(name, age, student_id, major)
        self.thesis_topic = thesis_topic
    
    def introduce(self):
        base_intro = super().introduce()
        return f"{base_intro}, thesis: {self.thesis_topic}"

# Usage
grad = GraduateStudent(
    "Alice", 25, "G001", "Computer Science", 
    "Machine Learning in Healthcare"
)
# Output:
# GraduateStudent.__init__ called for Alice
# Student.__init__ called for Alice
# Person.__init__ called for Alice

print(grad.introduce())
# I'm Alice, 25 years old, studying Computer Science, 
# thesis: Machine Learning in Healthcare
Multiple Inheritance with super()
Python

class Base:
    def __init__(self):
        print("Base.__init__")
        super().__init__()

class A(Base):
    def __init__(self):
        print("A.__init__")
        super().__init__()

class B(Base):
    def __init__(self):
        print("B.__init__")
        super().__init__()

class C(A, B):
    def __init__(self):
        print("C.__init__")
        super().__init__()

# MRO: C -> A -> B -> Base -> object
print("Creating C instance:")
c = C()
# Output:
# C.__init__
# A.__init__
# B.__init__
# Base.__init__

print("\nMethod Resolution Order:")
print([cls.__name__ for cls in C.mro()])
# ['C', 'A', 'B', 'Base', 'object']
Complex Example: Plugin System
Python

class Plugin:
    """Base plugin class"""
    
    def __init__(self, name):
        print(f"Plugin.__init__({name})")
        self.name = name
        super().__init__()
    
    def execute(self):
        print(f"Plugin {self.name} executing")

class LoggingMixin:
    """Mixin for logging functionality"""
    
    def __init__(self):
        print("LoggingMixin.__init__")
        self.logs = []
        super().__init__()
    
    def log(self, message):
        self.logs.append(f"[{self.name}] {message}")

class CachingMixin:
    """Mixin for caching functionality"""
    
    def __init__(self):
        print("CachingMixin.__init__")
        self.cache = {}
        super().__init__()
    
    def get_cached(self, key):
        return self.cache.get(key)
    
    def set_cache(self, key, value):
        self.cache[key] = value

class DataPlugin(Plugin, LoggingMixin, CachingMixin):
    """
    Plugin with logging and caching.
    Demonstrates proper use of super() in multiple inheritance.
    """
    
    def __init__(self, name, data_source):
        print(f"DataPlugin.__init__({name})")
        self.data_source = data_source
        # super() follows MRO to initialize all parent classes
        super().__init__(name)
    
    def execute(self):
        # Check cache first
        cached = self.get_cached(self.data_source)
        if cached:
            self.log(f"Using cached data from {self.data_source}")
            return cached
        
        # Simulate data fetch
        data = f"Data from {self.data_source}"
        self.set_cache(self.data_source, data)
        self.log(f"Fetched data from {self.data_source}")
        
        # Call parent execute
        super().execute()
        return data

# Usage
plugin = DataPlugin("MyDataPlugin", "database")
print("\nMRO:")
print([cls.__name__ for cls in DataPlugin.mro()])

print("\nFirst execution:")
result1 = plugin.execute()

print("\nSecond execution (cached):")
result2 = plugin.execute()

print("\nLogs:")
for log in plugin.logs:
    print(log)
7. Cohesive Classes & Documentation
Well-Documented, Focused Class
Python

from typing import List, Optional, Dict
from datetime import datetime
from enum import Enum

class TaskStatus(Enum):
    """Enumeration of possible task statuses"""
    TODO = "todo"
    IN_PROGRESS = "in_progress"
    COMPLETED = "completed"
    CANCELLED = "cancelled"

class Task:
    """
    Represents a single task in a task management system.
    
    A task has a title, description, status, and optional due date.
    This class is responsible ONLY for task data and basic operations.
    It does NOT handle:
    - Database operations (handled by TaskRepository)
    - Notifications (handled by NotificationService)
    - UI rendering (handled by TaskView)
    
    Attributes:
        title (str): The task title
        description (str): Detailed task description
        status (TaskStatus): Current status of the task
        due_date (Optional[datetime]): When the task is due
        created_at (datetime): When the task was created
        completed_at (Optional[datetime]): When the task was completed
    
    Example:
        >>> task = Task("Write documentation", "Document all classes")
        >>> task.start()
        >>> task.complete()
        >>> print(task.is_completed)
        True
    """
    
    def __init__(
        self, 
        title: str, 
        description: str = "",
        due_date: Optional[datetime] = None
    ):
        """
        Initialize a new task.
        
        Args:
            title: The task title (required)
            description: Detailed description (optional)
            due_date: When the task is due (optional)
        
        Raises:
            ValueError: If title is empty or only whitespace
        """
        if not title or not title.strip():
            raise ValueError("Task title cannot be empty")
        
        self.title = title.strip()
        self.description = description.strip()
        self.status = TaskStatus.TODO
        self.due_date = due_date
        self.created_at = datetime.now()
        self.completed_at: Optional[datetime] = None
    
    def start(self) -> None:
        """
        Mark the task as in progress.
        
        Raises:
            ValueError: If task is already completed or cancelled
        """
        if self.status == TaskStatus.COMPLETED:
            raise ValueError("Cannot start a completed task")
        if self.status == TaskStatus.CANCELLED:
            raise ValueError("Cannot start a cancelled task")
        
        self.status = TaskStatus.IN_PROGRESS
    
    def complete(self) -> None:
        """
        Mark the task as completed.
        
        Sets the completed_at timestamp to current time.
        
        Raises:
            ValueError: If task is cancelled
        """
        if self.status == TaskStatus.CANCELLED:
            raise ValueError("Cannot complete a cancelled task")
        
        self.status = TaskStatus.COMPLETED
        self.completed_at = datetime.now()
    
    def cancel(self) -> None:
        """
        Cancel the task.
        
        Raises:
            ValueError: If task is already completed
        """
        if self.status == TaskStatus.COMPLETED:
            raise ValueError("Cannot cancel a completed task")
        
        self.status = TaskStatus.CANCELLED
    
    @property
    def is_completed(self) -> bool:
        """Check if task is completed."""
        return self.status == TaskStatus.COMPLETED
    
    @property
    def is_overdue(self) -> bool:
        """
        Check if task is overdue.
        
        Returns:
            True if task has a due date in the past and is not completed
        """
        if self.due_date is None or self.is_completed:
            return False
        return datetime.now() > self.due_date
    
    def to_dict(self) -> Dict:
        """
        Convert task to dictionary representation.
        
        Returns:
            Dictionary containing all task data
        """
        return {
            'title': self.title,
            'description': self.description,
            'status': self.status.value,
            'due_date': self.due_date.isoformat() if self.due_date else None,
            'created_at': self.created_at.isoformat(),
            'completed_at': self.completed_at.isoformat() 
                           if self.completed_at else None
        }
    
    def __str__(self) -> str:
        """Return user-friendly string representation."""
        status_symbol = {
            TaskStatus.TODO: "☐",
            TaskStatus.IN_PROGRESS: "⧗",
            TaskStatus.COMPLETED: "☑",
            TaskStatus.CANCELLED: "☒"
        }
        symbol = status_symbol.get(self.status, "?")
        return f"{symbol} {self.title}"
    
    def __repr__(self) -> str:
        """Return developer-friendly string representation."""
        return (
            f"Task(title='{self.title}', "
            f"status={self.status.value}, "
            f"due_date={self.due_date})"
        )

# Usage with documentation
task = Task(
    title="Implement user authentication",
    description="Add JWT-based authentication to the API",
    due_date=datetime(2024, 12, 31)
)

# Access docstrings
print(Task.__doc__)
print(Task.complete.__doc__)

# IDE will show documentation when you hover or use help()
help(Task.start)
Complete Real-World Example: E-Commerce System
Putting it all together:

Python

"""
E-Commerce Order Management System
Demonstrates all OOP best practices in a cohesive example.
"""

from abc import ABC, abstractmethod
from typing import List, Dict, Optional
from datetime import datetime
from enum import Enum

# ============================================================================
# SOLID PRINCIPLES DEMONSTRATED
# ============================================================================

# --- Single Responsibility Principle ---
# Each class has one clear responsibility

class OrderStatus(Enum):
    """Order status enumeration"""
    PENDING = "pending"
    CONFIRMED = "confirmed"
    SHIPPED = "shipped"
    DELIVERED = "delivered"
    CANCELLED = "cancelled"

class Product:
    """
    Represents a product in the catalog.
    Responsibility: Store product information only.
    """
    
    def __init__(self, product_id: str, name: str, price: float, stock: int):
        if price < 0:
            raise ValueError("Price cannot be negative")
        if stock < 0:
            raise ValueError("Stock cannot be negative")
        
        self.product_id = product_id
        self.name = name
        self._price = price
        self._stock = stock
    
    @property
    def price(self) -> float:
        """Get product price"""
        return self._price
    
    @property
    def stock(self) -> int:
        """Get available stock"""
        return self._stock
    
    def reduce_stock(self, quantity: int) -> bool:
        """
        Reduce stock by quantity.
        Returns True if successful, False if insufficient stock.
        """
        if quantity > self._stock:
            return False
        self._stock -= quantity
        return True
    
    def add_stock(self, quantity: int) -> None:
        """Add stock"""
        self._stock += quantity
    
    def __str__(self) -> str:
        return f"{self.name} - ${self.price:.2f}"

class OrderItem:
    """
    Represents a single item in an order.
    Responsibility: Link product to quantity in an order.
    """
    
    def __init__(self, product: Product, quantity: int):
        if quantity <= 0:
            raise ValueError("Quantity must be positive")
        
        self.product = product
        self.quantity = quantity
    
    @property
    def subtotal(self) -> float:
        """Calculate subtotal for this item"""
        return self.product.price * self.quantity
    
    def __str__(self) -> str:
        return f"{self.product.name} x{self.quantity} = ${self.subtotal:.2f}"

# --- Open/Closed Principle ---
# Open for extension, closed for modification

class DiscountStrategy(ABC):
    """
    Abstract discount strategy.
    New discount types can be added without modifying existing code.
    """
    
    @abstractmethod
    def calculate_discount(self, amount: float) -> float:
        """Calculate discount amount"""
        pass
    
    @abstractmethod
    def get_description(self) -> str:
        """Get discount description"""
        pass

class NoDiscount(DiscountStrategy):
    """No discount applied"""
    
    def calculate_discount(self, amount: float) -> float:
        return 0
    
    def get_description(self) -> str:
        return "No discount"

class PercentageDiscount(DiscountStrategy):
    """Percentage-based discount"""
    
    def __init__(self, percentage: float):
        if not 0 <= percentage <= 100:
            raise ValueError("Percentage must be between 0 and 100")
        self.percentage = percentage
    
    def calculate_discount(self, amount: float) -> float:
        return amount * (self.percentage / 100)
    
    def get_description(self) -> str:
        return f"{self.percentage}% discount"

class FixedAmountDiscount(DiscountStrategy):
    """Fixed amount discount"""
    
    def __init__(self, amount: float):
        if amount < 0:
            raise ValueError("Discount amount cannot be negative")
        self.amount = amount
    
    def calculate_discount(self, amount: float) -> float:
        return min(self.amount, amount)  # Don't exceed total
    
    def get_description(self) -> str:
        return f"${self.amount:.2f} off"

# --- Liskov Substitution Principle ---
# Subclasses can be substituted for base class

class PaymentMethod(ABC):
    """
    Abstract payment method.
    All payment methods can be used interchangeably.
    """
    
    @abstractmethod
    def process_payment(self, amount: float) -> Dict:
        """Process payment and return result"""
        pass
    
    @abstractmethod
    def get_type(self) -> str:
        """Get payment method type"""
        pass

class CreditCardPayment(PaymentMethod):
    """Credit card payment"""
    
    def __init__(self, card_number: str, cvv: str):
        self.card_number = card_number
        self.cvv = cvv
    
    def process_payment(self, amount: float) -> Dict:
        # Simulate payment processing
        return {
            'success': True,
            'amount': amount,
            'transaction_id': f"CC-{hash(self.card_number) % 100000}",
            'method': self.get_type()
        }
    
    def get_type(self) -> str:
        return "Credit Card"

class PayPalPayment(PaymentMethod):
    """PayPal payment"""
    
    def __init__(self, email: str):
        self.email = email
    
    def process_payment(self, amount: float) -> Dict:
        return {
            'success': True,
            'amount': amount,
            'transaction_id': f"PP-{hash(self.email) % 100000}",
            'method': self.get_type()
        }
    
    def get_type(self) -> str:
        return "PayPal"

# --- Interface Segregation Principle ---
# Classes don't depend on interfaces they don't use

class Notifiable(ABC):
    """Interface for entities that can receive notifications"""
    
    @abstractmethod
    def get_notification_address(self) -> str:
        pass

class Trackable(ABC):
    """Interface for entities that can be tracked"""
    
    @abstractmethod
    def get_tracking_number(self) -> str:
        pass

# --- Dependency Inversion Principle ---
# Depend on abstractions, not concretions

class NotificationService(ABC):
    """Abstract notification service"""
    
    @abstractmethod
    def send(self, recipient: str, message: str) -> bool:
        pass

class EmailNotification(NotificationService):
    """Email notification implementation"""
    
    def send(self, recipient: str, message: str) -> bool:
        print(f"📧 Sending email to {recipient}: {message}")
        return True

class SMSNotification(NotificationService):
    """SMS notification implementation"""
    
    def send(self, recipient: str, message: str) -> bool:
        print(f"📱 Sending SMS to {recipient}: {message}")
        return True

# --- Main Order Class (Composition) ---

class Order:
    """
    Main order class demonstrating composition and best practices.
    
    This class:
    - Uses composition (HAS-A relationships)
    - Depends on abstractions (DIP)
    - Has single responsibility (order management)
    - Uses properties for controlled access
    - Is well-documented
    """
    
    _order_counter = 1000
    
    def __init__(
        self,
        customer_email: str,
        discount_strategy: Optional[DiscountStrategy] = None,
        notification_service: Optional[NotificationService] = None
    ):
        """
        Initialize a new order.
        
        Args:
            customer_email: Customer's email address
            discount_strategy: Strategy for calculating discounts
            notification_service: Service for sending notifications
        """
        self.order_id = f"ORD-{Order._order_counter:06d}"
        Order._order_counter += 1
        
        self.customer_email = customer_email
        self.items: List[OrderItem] = []
        self.status = OrderStatus.PENDING
        self.created_at = datetime.now()
        
        # Composition: Order HAS-A discount strategy
        self.discount_strategy = discount_strategy or NoDiscount()
        
        # Composition: Order HAS-A notification service
        self.notification_service = notification_service
        
        self._payment_result: Optional[Dict] = None
    
    def add_item(self, product: Product, quantity: int) -> bool:
        """
        Add item to order.
        
        Args:
            product: Product to add
            quantity: Quantity to add
        
        Returns:
            True if successful, False if insufficient stock
        """
        if not product.reduce_stock(quantity):
            return False
        
        # Check if product already in order
        for item in self.items:
            if item.product.product_id == product.product_id:
                item.quantity += quantity
                return True
        
        # Add new item
        self.items.append(OrderItem(product, quantity))
        return True
    
    def remove_item(self, product_id: str) -> bool:
        """Remove item from order"""
        for item in self.items:
            if item.product.product_id == product_id:
                # Return stock
                item.product.add_stock(item.quantity)
                self.items.remove(item)
                return True
        return False
    
    @property
    def subtotal(self) -> float:
        """Calculate subtotal (before discount)"""
        return sum(item.subtotal for item in self.items)
    
    @property
    def discount_amount(self) -> float:
        """Calculate discount amount"""
        return self.discount_strategy.calculate_discount(self.subtotal)
    
    @property
    def total(self) -> float:
        """Calculate total (after discount)"""
        return self.subtotal - self.discount_amount
    
    def checkout(self, payment_method: PaymentMethod) -> bool:
        """
        Complete the order checkout process.
        
        Args:
            payment_method: Payment method to use
        
        Returns:
            True if successful
        """
        if not self.items:
            raise ValueError("Cannot checkout empty order")
        
        if self.status != OrderStatus.PENDING:
            raise ValueError(f"Order already {self.status.value}")
        
        # Process payment
        self._payment_result = payment_method.process_payment(self.total)
        
        if not self._payment_result['success']:
            return False
        
        # Update status
        self.status = OrderStatus.CONFIRMED
        
        # Send confirmation
        if self.notification_service:
            self._send_confirmation()
        
        return True
    
    def _send_confirmation(self) -> None:
        """Send order confirmation (private method)"""
        message = (
            f"Order {self.order_id} confirmed!\n"
            f"Total: ${self.total:.2f}\n"
            f"Payment: {self._payment_result['method']}"
        )
        self.notification_service.send(self.customer_email, message)
    
    def ship(self, tracking_number: str) -> None:
        """Mark order as shipped"""
        if self.status != OrderStatus.CONFIRMED:
            raise ValueError("Can only ship confirmed orders")
        
        self.status = OrderStatus.SHIPPED
        
        if self.notification_service:
            message = (
                f"Order {self.order_id} shipped!\n"
                f"Tracking: {tracking_number}"
            )
            self.notification_service.send(self.customer_email, message)
    
    def __str__(self) -> str:
        """User-friendly string representation"""
        items_str = "\n".join(f"  - {item}" for item in self.items)
        return (
            f"Order {self.order_id} ({self.status.value})\n"
            f"{items_str}\n"
            f"Subtotal: ${self.subtotal:.2f}\n"
            f"Discount: -${self.discount_amount:.2f} "
            f"({self.discount_strategy.get_description()})\n"
            f"Total: ${self.total:.2f}"
        )
    
    def __repr__(self) -> str:
        """Developer-friendly string representation"""
        return (
            f"Order(order_id='{self.order_id}', "
            f"items={len(self.items)}, "
            f"total=${self.total:.2f}, "
            f"status={self.status.value})"
        )

# ============================================================================
# USAGE EXAMPLE
# ============================================================================

def main():
    """Demonstrate the e-commerce system"""
    
    print("=" * 60)
    print("E-COMMERCE ORDER MANAGEMENT SYSTEM")
    print("=" * 60)
    
    # Create products
    laptop = Product("P001", "Laptop", 999.99, 10)
    mouse = Product("P002", "Wireless Mouse", 29.99, 50)
    keyboard = Product("P003", "Mechanical Keyboard", 79.99, 30)
    
    # Create notification service
    email_service = EmailNotification()
    
    # Create order with 10% discount
    discount = PercentageDiscount(10)
    order = Order(
        customer_email="customer@example.com",
        discount_strategy=discount,
        notification_service=email_service
    )
    
    print(f"\n📦 Created {order.order_id}")
    
    # Add items
    print("\n➕ Adding items...")
    order.add_item(laptop, 1)
    order.add_item(mouse, 2)
    order.add_item(keyboard, 1)
    
    # Display order
    print(f"\n{order}")
    
    # Checkout with credit card
    print("\n💳 Processing checkout...")
    payment = CreditCardPayment("1234567890123456", "123")
    success = order.checkout(payment)
    
    if success:
        print(f"\n✅ Order confirmed!")
        print(f"Order status: {order.status.value}")
        
        # Ship order
        print("\n📫 Shipping order...")
        order.ship("TRACK123456")
        print(f"Order status: {order.status.value}")
    
    print("\n" + "=" * 60)

if __name__ == "__main__":
    main()


Complete OOP Mastery Guide: Advanced Patterns & Examples
Let me provide even more advanced examples demonstrating these principles in real-world scenarios.

1. Advanced Composition Patterns
Strategy Pattern with Composition
Python

"""
Advanced composition example: Content Management System
Demonstrates how composition provides flexibility over inheritance
"""

from abc import ABC, abstractmethod
from typing import List, Dict, Optional
from datetime import datetime
from enum import Enum

# ============================================================================
# COMPOSITION: Content Rendering Strategies
# ============================================================================

class ContentFormat(Enum):
    """Content format types"""
    MARKDOWN = "markdown"
    HTML = "html"
    PLAIN_TEXT = "plain_text"
    JSON = "json"

class RenderStrategy(ABC):
    """
    Abstract rendering strategy.
    Different rendering strategies can be composed with content.
    """
    
    @abstractmethod
    def render(self, content: str, metadata: Dict) -> str:
        """Render content in specific format"""
        pass
    
    @abstractmethod
    def get_format(self) -> ContentFormat:
        """Get format type"""
        pass

class MarkdownRenderer(RenderStrategy):
    """Render content as Markdown"""
    
    def render(self, content: str, metadata: Dict) -> str:
        title = metadata.get('title', 'Untitled')
        author = metadata.get('author', 'Unknown')
        
        output = f"# {title}\n\n"
        output += f"*By {author}*\n\n"
        output += f"{content}\n"
        return output
    
    def get_format(self) -> ContentFormat:
        return ContentFormat.MARKDOWN

class HTMLRenderer(RenderStrategy):
    """Render content as HTML"""
    
    def render(self, content: str, metadata: Dict) -> str:
        title = metadata.get('title', 'Untitled')
        author = metadata.get('author', 'Unknown')
        
        output = f"<article>\n"
        output += f"  <h1>{title}</h1>\n"
        output += f"  <p class='author'>By {author}</p>\n"
        output += f"  <div class='content'>{content}</div>\n"
        output += f"</article>"
        return output
    
    def get_format(self) -> ContentFormat:
        return ContentFormat.HTML

class JSONRenderer(RenderStrategy):
    """Render content as JSON"""
    
    def render(self, content: str, metadata: Dict) -> str:
        import json
        data = {
            'title': metadata.get('title', 'Untitled'),
            'author': metadata.get('author', 'Unknown'),
            'content': content,
            'metadata': metadata
        }
        return json.dumps(data, indent=2)
    
    def get_format(self) -> ContentFormat:
        return ContentFormat.JSON

# ============================================================================
# COMPOSITION: Storage Strategies
# ============================================================================

class StorageStrategy(ABC):
    """Abstract storage strategy"""
    
    @abstractmethod
    def save(self, key: str, data: str) -> bool:
        """Save data"""
        pass
    
    @abstractmethod
    def load(self, key: str) -> Optional[str]:
        """Load data"""
        pass
    
    @abstractmethod
    def delete(self, key: str) -> bool:
        """Delete data"""
        pass

class InMemoryStorage(StorageStrategy):
    """In-memory storage implementation"""
    
    def __init__(self):
        self._storage: Dict[str, str] = {}
    
    def save(self, key: str, data: str) -> bool:
        self._storage[key] = data
        print(f"💾 Saved to memory: {key}")
        return True
    
    def load(self, key: str) -> Optional[str]:
        return self._storage.get(key)
    
    def delete(self, key: str) -> bool:
        if key in self._storage:
            del self._storage[key]
            return True
        return False

class FileStorage(StorageStrategy):
    """File-based storage implementation"""
    
    def __init__(self, base_path: str = "./storage"):
        self.base_path = base_path
    
    def save(self, key: str, data: str) -> bool:
        filepath = f"{self.base_path}/{key}.txt"
        print(f"💾 Saved to file: {filepath}")
        # In real implementation, write to file
        return True
    
    def load(self, key: str) -> Optional[str]:
        # In real implementation, read from file
        return None
    
    def delete(self, key: str) -> bool:
        # In real implementation, delete file
        return True

class DatabaseStorage(StorageStrategy):
    """Database storage implementation"""
    
    def __init__(self, connection_string: str):
        self.connection_string = connection_string
    
    def save(self, key: str, data: str) -> bool:
        print(f"💾 Saved to database: {key}")
        # In real implementation, save to database
        return True
    
    def load(self, key: str) -> Optional[str]:
        # In real implementation, query database
        return None
    
    def delete(self, key: str) -> bool:
        # In real implementation, delete from database
        return True

# ============================================================================
# COMPOSITION: Validation Strategies
# ============================================================================

class ValidationStrategy(ABC):
    """Abstract validation strategy"""
    
    @abstractmethod
    def validate(self, content: str, metadata: Dict) -> tuple[bool, List[str]]:
        """
        Validate content.
        Returns (is_valid, list_of_errors)
        """
        pass

class LengthValidator(ValidationStrategy):
    """Validate content length"""
    
    def __init__(self, min_length: int = 10, max_length: int = 10000):
        self.min_length = min_length
        self.max_length = max_length
    
    def validate(self, content: str, metadata: Dict) -> tuple[bool, List[str]]:
        errors = []
        
        if len(content) < self.min_length:
            errors.append(f"Content too short (min: {self.min_length})")
        
        if len(content) > self.max_length:
            errors.append(f"Content too long (max: {self.max_length})")
        
        return (len(errors) == 0, errors)

class MetadataValidator(ValidationStrategy):
    """Validate required metadata"""
    
    def __init__(self, required_fields: List[str]):
        self.required_fields = required_fields
    
    def validate(self, content: str, metadata: Dict) -> tuple[bool, List[str]]:
        errors = []
        
        for field in self.required_fields:
            if field not in metadata or not metadata[field]:
                errors.append(f"Missing required field: {field}")
        
        return (len(errors) == 0, errors)

class CompositeValidator(ValidationStrategy):
    """Compose multiple validators"""
    
    def __init__(self, validators: List[ValidationStrategy]):
        self.validators = validators
    
    def validate(self, content: str, metadata: Dict) -> tuple[bool, List[str]]:
        all_errors = []
        
        for validator in self.validators:
            is_valid, errors = validator.validate(content, metadata)
            all_errors.extend(errors)
        
        return (len(all_errors) == 0, all_errors)

# ============================================================================
# MAIN CLASS: Content using Composition
# ============================================================================

class Content:
    """
    Content class using composition.
    
    This class demonstrates:
    - Composition over inheritance (HAS-A relationships)
    - Strategy pattern for flexible behavior
    - Dependency injection
    - Single Responsibility Principle
    
    The Content class delegates:
    - Rendering to RenderStrategy
    - Storage to StorageStrategy
    - Validation to ValidationStrategy
    
    This makes it easy to:
    - Swap rendering formats at runtime
    - Change storage backend without modifying Content
    - Add new validators without changing Content
    """
    
    def __init__(
        self,
        content_id: str,
        text: str,
        metadata: Dict,
        renderer: RenderStrategy,
        storage: StorageStrategy,
        validator: Optional[ValidationStrategy] = None
    ):
        """
        Initialize content with composed strategies.
        
        Args:
            content_id: Unique identifier
            text: Content text
            metadata: Content metadata (title, author, etc.)
            renderer: Strategy for rendering content
            storage: Strategy for storing content
            validator: Optional validation strategy
        """
        self.content_id = content_id
        self._text = text
        self._metadata = metadata
        
        # Composition: Content HAS-A renderer, storage, validator
        self._renderer = renderer
        self._storage = storage
        self._validator = validator
        
        self.created_at = datetime.now()
        self.modified_at = datetime.now()
    
    @property
    def text(self) -> str:
        """Get content text"""
        return self._text
    
    @text.setter
    def text(self, value: str):
        """Set content text with validation"""
        if self._validator:
            is_valid, errors = self._validator.validate(value, self._metadata)
            if not is_valid:
                raise ValueError(f"Validation failed: {', '.join(errors)}")
        
        self._text = value
        self.modified_at = datetime.now()
    
    @property
    def metadata(self) -> Dict:
        """Get metadata (returns copy)"""
        return self._metadata.copy()
    
    def update_metadata(self, **kwargs):
        """Update metadata"""
        self._metadata.update(kwargs)
        self.modified_at = datetime.now()
    
    def render(self) -> str:
        """
        Render content using composed renderer.
        Behavior depends on which renderer was injected.
        """
        return self._renderer.render(self._text, self._metadata)
    
    def change_renderer(self, new_renderer: RenderStrategy):
        """
        Change rendering strategy at runtime.
        This demonstrates the flexibility of composition.
        """
        self._renderer = new_renderer
    
    def save(self) -> bool:
        """
        Save content using composed storage.
        Storage mechanism depends on which storage was injected.
        """
        rendered = self.render()
        return self._storage.save(self.content_id, rendered)
    
    def load(self) -> Optional[str]:
        """Load content from storage"""
        return self._storage.load(self.content_id)
    
    def validate(self) -> tuple[bool, List[str]]:
        """Validate content if validator is set"""
        if not self._validator:
            return (True, [])
        return self._validator.validate(self._text, self._metadata)
    
    def __str__(self) -> str:
        title = self._metadata.get('title', 'Untitled')
        format_type = self._renderer.get_format().value
        return f"Content: {title} (Format: {format_type})"

# ============================================================================
# USAGE EXAMPLE
# ============================================================================

def demonstrate_composition():
    """Demonstrate composition advantages"""
    
    print("=" * 70)
    print("COMPOSITION PATTERN DEMONSTRATION")
    print("=" * 70)
    
    # Create content text
    text = """
    This is a comprehensive guide to Object-Oriented Programming.
    We'll cover all the important concepts with practical examples.
    """
    
    metadata = {
        'title': 'OOP Guide',
        'author': 'John Doe',
        'category': 'Programming',
        'tags': ['python', 'oop', 'tutorial']
    }
    
    # Create validators
    length_validator = LengthValidator(min_length=10, max_length=1000)
    metadata_validator = MetadataValidator(['title', 'author'])
    validator = CompositeValidator([length_validator, metadata_validator])
    
    # Create content with Markdown renderer and in-memory storage
    print("\n1️⃣  Creating content with Markdown renderer...")
    markdown_renderer = MarkdownRenderer()
    memory_storage = InMemoryStorage()
    
    content = Content(
        content_id="content_001",
        text=text,
        metadata=metadata,
        renderer=markdown_renderer,
        storage=memory_storage,
        validator=validator
    )
    
    print(f"\n{content}")
    print("\nRendered as Markdown:")
    print(content.render())
    
    # Save with current renderer
    content.save()
    
    # Change renderer at runtime (composition flexibility!)
    print("\n2️⃣  Changing renderer to HTML...")
    html_renderer = HTMLRenderer()
    content.change_renderer(html_renderer)
    
    print(f"\n{content}")
    print("\nRendered as HTML:")
    print(content.render())
    
    # Change renderer again
    print("\n3️⃣  Changing renderer to JSON...")
    json_renderer = JSONRenderer()
    content.change_renderer(json_renderer)
    
    print(f"\n{content}")
    print("\nRendered as JSON:")
    print(content.render())
    
    # Demonstrate validation
    print("\n4️⃣  Testing validation...")
    is_valid, errors = content.validate()
    print(f"Valid: {is_valid}")
    
    try:
        content.text = "Too short"  # Will fail validation
    except ValueError as e:
        print(f"❌ Validation error: {e}")
    
    print("\n" + "=" * 70)
    print("KEY ADVANTAGES OF COMPOSITION:")
    print("=" * 70)
    print("✅ Changed rendering format 3 times without modifying Content class")
    print("✅ Can swap storage backend without changing Content")
    print("✅ Can combine multiple validators")
    print("✅ Easy to test (inject mock strategies)")
    print("✅ No inheritance complexity")
    print("=" * 70)

if __name__ == "__main__":
    demonstrate_composition()
2. Advanced SOLID Examples
Real-World Application: Task Management System
Python

"""
Complete Task Management System demonstrating all SOLID principles
"""

from abc import ABC, abstractmethod
from typing import List, Dict, Optional, Set
from datetime import datetime, timedelta
from enum import Enum
import json

# ============================================================================
# SINGLE RESPONSIBILITY PRINCIPLE
# Each class has ONE reason to change
# ============================================================================

class Priority(Enum):
    """Task priority levels"""
    LOW = 1
    MEDIUM = 2
    HIGH = 3
    CRITICAL = 4

class TaskStatus(Enum):
    """Task status"""
    TODO = "todo"
    IN_PROGRESS = "in_progress"
    DONE = "done"
    ARCHIVED = "archived"

class Task:
    """
    Represents a task.
    RESPONSIBILITY: Store and manage task data only.
    NOT responsible for: persistence, notifications, validation
    """
    
    def __init__(
        self,
        task_id: str,
        title: str,
        description: str = "",
        priority: Priority = Priority.MEDIUM,
        due_date: Optional[datetime] = None
    ):
        self.task_id = task_id
        self.title = title
        self.description = description
        self.priority = priority
        self.status = TaskStatus.TODO
        self.due_date = due_date
        self.created_at = datetime.now()
        self.completed_at: Optional[datetime] = None
        self.tags: Set[str] = set()
        self.assigned_to: Optional[str] = None
    
    def mark_in_progress(self):
        """Change status to in progress"""
        self.status = TaskStatus.IN_PROGRESS
    
    def mark_done(self):
        """Mark task as complete"""
        self.status = TaskStatus.DONE
        self.completed_at = datetime.now()
    
    def add_tag(self, tag: str):
        """Add a tag"""
        self.tags.add(tag.lower())
    
    def assign_to(self, user_id: str):
        """Assign task to user"""
        self.assigned_to = user_id
    
    def to_dict(self) -> Dict:
        """Convert to dictionary"""
        return {
            'task_id': self.task_id,
            'title': self.title,
            'description': self.description,
            'priority': self.priority.value,
            'status': self.status.value,
            'due_date': self.due_date.isoformat() if self.due_date else None,
            'created_at': self.created_at.isoformat(),
            'completed_at': self.completed_at.isoformat() if self.completed_at else None,
            'tags': list(self.tags),
            'assigned_to': self.assigned_to
        }
    
    def __str__(self) -> str:
        status_emoji = {
            TaskStatus.TODO: "⭕",
            TaskStatus.IN_PROGRESS: "🔄",
            TaskStatus.DONE: "✅",
            TaskStatus.ARCHIVED: "📦"
        }
        priority_emoji = {
            Priority.LOW: "🟢",
            Priority.MEDIUM: "🟡",
            Priority.HIGH: "🟠",
            Priority.CRITICAL: "🔴"
        }
        
        emoji = status_emoji.get(self.status, "❓")
        priority = priority_emoji.get(self.priority, "⚪")
        
        return f"{emoji} {priority} {self.title}"

class TaskRepository:
    """
    Handles task persistence.
    RESPONSIBILITY: CRUD operations for tasks only.
    NOT responsible for: business logic, validation, notifications
    """
    
    def __init__(self):
        self._tasks: Dict[str, Task] = {}
    
    def add(self, task: Task) -> bool:
        """Add task to repository"""
        if task.task_id in self._tasks:
            return False
        self._tasks[task.task_id] = task
        return True
    
    def get(self, task_id: str) -> Optional[Task]:
        """Get task by ID"""
        return self._tasks.get(task_id)
    
    def get_all(self) -> List[Task]:
        """Get all tasks"""
        return list(self._tasks.values())
    
    def update(self, task: Task) -> bool:
        """Update existing task"""
        if task.task_id not in self._tasks:
            return False
        self._tasks[task.task_id] = task
        return True
    
    def delete(self, task_id: str) -> bool:
        """Delete task"""
        if task_id in self._tasks:
            del self._tasks[task_id]
            return True
        return False
    
    def find_by_status(self, status: TaskStatus) -> List[Task]:
        """Find tasks by status"""
        return [t for t in self._tasks.values() if t.status == status]
    
    def find_by_priority(self, priority: Priority) -> List[Task]:
        """Find tasks by priority"""
        return [t for t in self._tasks.values() if t.priority == priority]

class TaskValidator:
    """
    Validates task data.
    RESPONSIBILITY: Task validation only.
    """
    
    @staticmethod
    def validate_create(title: str, due_date: Optional[datetime]) -> tuple[bool, List[str]]:
        """Validate task creation data"""
        errors = []
        
        if not title or not title.strip():
            errors.append("Title cannot be empty")
        
        if len(title) > 200:
            errors.append("Title too long (max 200 characters)")
        
        if due_date and due_date < datetime.now():
            errors.append("Due date cannot be in the past")
        
        return (len(errors) == 0, errors)
    
    @staticmethod
    def validate_update(task: Task) -> tuple[bool, List[str]]:
        """Validate task update"""
        errors = []
        
        if task.status == TaskStatus.DONE and not task.completed_at:
            errors.append("Done tasks must have completion date")
        
        return (len(errors) == 0, errors)

# ============================================================================
# OPEN/CLOSED PRINCIPLE
# Open for extension, closed for modification
# ============================================================================

class TaskFilter(ABC):
    """
    Abstract task filter.
    New filters can be added without modifying existing code.
    """
    
    @abstractmethod
    def matches(self, task: Task) -> bool:
        """Check if task matches filter criteria"""
        pass

class StatusFilter(TaskFilter):
    """Filter by status"""
    
    def __init__(self, status: TaskStatus):
        self.status = status
    
    def matches(self, task: Task) -> bool:
        return task.status == self.status

class PriorityFilter(TaskFilter):
    """Filter by priority"""
    
    def __init__(self, priority: Priority):
        self.priority = priority
    
    def matches(self, task: Task) -> bool:
        return task.priority == self.priority

class OverdueFilter(TaskFilter):
    """Filter overdue tasks"""
    
    def matches(self, task: Task) -> bool:
        if not task.due_date or task.status == TaskStatus.DONE:
            return False
        return datetime.now() > task.due_date

class TagFilter(TaskFilter):
    """Filter by tag"""
    
    def __init__(self, tag: str):
        self.tag = tag.lower()
    
    def matches(self, task: Task) -> bool:
        return self.tag in task.tags

class AssigneeFilter(TaskFilter):
    """Filter by assignee"""
    
    def __init__(self, user_id: str):
        self.user_id = user_id
    
    def matches(self, task: Task) -> bool:
        return task.assigned_to == user_id

class CompositeFilter(TaskFilter):
    """
    Combine multiple filters with AND logic.
    NEW filter type without modifying existing code!
    """
    
    def __init__(self, *filters: TaskFilter):
        self.filters = filters
    
    def matches(self, task: Task) -> bool:
        return all(f.matches(task) for f in self.filters)

class OrFilter(TaskFilter):
    """
    Combine multiple filters with OR logic.
    Another NEW filter type!
    """
    
    def __init__(self, *filters: TaskFilter):
        self.filters = filters
    
    def matches(self, task: Task) -> bool:
        return any(f.matches(task) for f in self.filters)

# ============================================================================
# LISKOV SUBSTITUTION PRINCIPLE
# Subtypes must be substitutable for base types
# ============================================================================

class Notifier(ABC):
    """
    Abstract notifier.
    All notifiers can be used interchangeably.
    """
    
    @abstractmethod
    def send(self, recipient: str, subject: str, message: str) -> bool:
        """Send notification"""
        pass
    
    @abstractmethod
    def get_type(self) -> str:
        """Get notifier type"""
        pass

class EmailNotifier(Notifier):
    """Email notification - fully substitutable"""
    
    def send(self, recipient: str, subject: str, message: str) -> bool:
        print(f"📧 Email to {recipient}")
        print(f"   Subject: {subject}")
        print(f"   {message}")
        return True
    
    def get_type(self) -> str:
        return "Email"

class SMSNotifier(Notifier):
    """SMS notification - fully substitutable"""
    
    def send(self, recipient: str, subject: str, message: str) -> bool:
        # SMS doesn't use subject, but accepts it (LSP compliant)
        print(f"📱 SMS to {recipient}: {message}")
        return True
    
    def get_type(self) -> str:
        return "SMS"

class SlackNotifier(Notifier):
    """Slack notification - fully substitutable"""
    
    def send(self, recipient: str, subject: str, message: str) -> bool:
        print(f"💬 Slack to #{recipient}")
        print(f"   **{subject}**")
        print(f"   {message}")
        return True
    
    def get_type(self) -> str:
        return "Slack"

# ============================================================================
# INTERFACE SEGREGATION PRINCIPLE
# Don't force classes to implement interfaces they don't use
# ============================================================================

class Exportable(ABC):
    """Interface for exportable objects"""
    
    @abstractmethod
    def export_to_json(self) -> str:
        pass

class Importable(ABC):
    """Interface for importable objects"""
    
    @abstractmethod
    def import_from_json(self, data: str) -> bool:
        pass

class Reportable(ABC):
    """Interface for objects that can generate reports"""
    
    @abstractmethod
    def generate_report(self) -> str:
        pass

class TaskExporter(Exportable):
    """
    Handles task export.
    Only implements Exportable, not forced to implement other interfaces.
    """
    
    def __init__(self, repository: TaskRepository):
        self.repository = repository
    
    def export_to_json(self) -> str:
        """Export all tasks to JSON"""
        tasks = self.repository.get_all()
        data = [task.to_dict() for task in tasks]
        return json.dumps(data, indent=2)

class TaskReporter(Reportable):
    """
    Generates task reports.
    Only implements Reportable interface.
    """
    
    def __init__(self, repository: TaskRepository):
        self.repository = repository
    
    def generate_report(self) -> str:
        """Generate task summary report"""
        tasks = self.repository.get_all()
        
        status_counts = {}
        for task in tasks:
            status = task.status.value
            status_counts[status] = status_counts.get(status, 0) + 1
        
        report = "TASK SUMMARY REPORT\n"
        report += "=" * 50 + "\n"
        for status, count in status_counts.items():
            report += f"{status}: {count}\n"
        report += f"\nTotal: {len(tasks)} tasks\n"
        
        return report

# ============================================================================
# DEPENDENCY INVERSION PRINCIPLE
# Depend on abstractions, not concretions
# ============================================================================

class NotificationService:
    """
    High-level service depending on abstraction (Notifier).
    Doesn't depend on concrete Email/SMS/Slack implementations.
    """
    
    def __init__(self, notifiers: List[Notifier]):
        self.notifiers = notifiers  # Depends on abstraction
    
    def notify_all(self, recipient: str, subject: str, message: str):
        """Send notification through all channels"""
        for notifier in self.notifiers:
            notifier.send(recipient, subject, message)
    
    def add_notifier(self, notifier: Notifier):
        """Add new notification channel"""
        self.notifiers.append(notifier)

class TaskService:
    """
    High-level task service.
    Depends on abstractions (TaskRepository, TaskValidator, NotificationService)
    """
    
    def __init__(
        self,
        repository: TaskRepository,
        validator: TaskValidator,
        notification_service: Optional[NotificationService] = None
    ):
        self.repository = repository
        self.validator = validator
        self.notification_service = notification_service
    
    def create_task(
        self,
        task_id: str,
        title: str,
        description: str = "",
        priority: Priority = Priority.MEDIUM,
        due_date: Optional[datetime] = None
    ) -> tuple[bool, Optional[Task], List[str]]:
        """Create new task"""
        
        # Validate
        is_valid, errors = self.validator.validate_create(title, due_date)
        if not is_valid:
            return (False, None, errors)
        
        # Create task
        task = Task(task_id, title, description, priority, due_date)
        
        # Save
        success = self.repository.add(task)
        if not success:
            return (False, None, ["Task ID already exists"])
        
        return (True, task, [])
    
    def complete_task(self, task_id: str) -> tuple[bool, List[str]]:
        """Mark task as complete"""
        task = self.repository.get(task_id)
        if not task:
            return (False, ["Task not found"])
        
        task.mark_done()
        
        # Validate
        is_valid, errors = self.validator.validate_update(task)
        if not is_valid:
            return (False, errors)
        
        # Save
        self.repository.update(task)
        
        # Notify
        if self.notification_service and task.assigned_to:
            self.notification_service.notify_all(
                task.assigned_to,
                "Task Completed",
                f"Task '{task.title}' has been completed!"
            )
        
        return (True, [])
    
    def filter_tasks(self, filter_: TaskFilter) -> List[Task]:
        """Filter tasks using any filter strategy"""
        all_tasks = self.repository.get_all()
        return [task for task in all_tasks if filter_.matches(task)]

# ============================================================================
# DEMONSTRATION
# ============================================================================

def main():
    """Demonstrate all SOLID principles"""
    
    print("=" * 70)
    print("SOLID PRINCIPLES IN ACTION")
    print("=" * 70)
    
    # Setup
    repository = TaskRepository()
    validator = TaskValidator()
    
    # Setup notifications (DIP - depend on abstraction)
    email_notifier = EmailNotifier()
    sms_notifier = SMSNotifier()
    slack_notifier = SlackNotifier()
    notification_service = NotificationService([email_notifier, sms_notifier])
    
    # Create service (DIP - inject dependencies)
    task_service = TaskService(repository, validator, notification_service)
    
    # Create tasks
    print("\n1️⃣  Creating tasks (SRP - TaskService handles creation)...")
    
    success, task1, errors = task_service.create_task(
        "T001",
        "Implement user authentication",
        "Add JWT-based auth",
        Priority.HIGH,
        datetime.now() + timedelta(days=7)
    )
    if success:
        task1.assign_to("developer@example.com")
        task1.add_tag("backend")
        task1.add_tag("security")
        print(f"   ✅ Created: {task1}")
    
    success, task2, errors = task_service.create_task(
        "T002",
        "Design landing page",
        "Create mockups",
        Priority.MEDIUM,
        datetime.now() + timedelta(days=3)
    )
    if success:
        task2.assign_to("designer@example.com")
        task2.add_tag("frontend")
        task2.add_tag("design")
        print(f"   ✅ Created: {task2}")
    
    success, task3, errors = task_service.create_task(
        "T003",
        "Write documentation",
        "User guide",
        Priority.LOW,
        datetime.now() - timedelta(days=1)  # Overdue!
    )
    if success:
        task3.add_tag("docs")
        print(f"   ✅ Created: {task3}")
    
    # Filter tasks (OCP - new filters without modifying code)
    print("\n2️⃣  Filtering tasks (OCP - extensible filters)...")
    
    high_priority = task_service.filter_tasks(PriorityFilter(Priority.HIGH))
    print(f"\n   High priority tasks: {len(high_priority)}")
    for task in high_priority:
        print(f"      {task}")
    
    overdue = task_service.filter_tasks(OverdueFilter())
    print(f"\n   Overdue tasks: {len(overdue)}")
    for task in overdue:
        print(f"      {task}")
    
    # Composite filter (OCP - combine filters)
    backend_high = task_service.filter_tasks(
        CompositeFilter(
            TagFilter("backend"),
            PriorityFilter(Priority.HIGH)
        )
    )
    print(f"\n   High priority backend tasks: {len(backend_high)}")
    for task in backend_high:
        print(f"      {task}")
    
    # Complete task (LSP - all notifiers work the same)
    print("\n3️⃣  Completing task (LSP - interchangeable notifiers)...")
    task1.mark_in_progress()
    success, errors = task_service.complete_task("T001")
    
    # Add Slack notification (DIP - easy to add new notifier)
    print("\n4️⃣  Adding Slack notifier (DIP - depends on abstraction)...")
    notification_service.add_notifier(slack_notifier)
    
    # Export (ISP - only implements needed interface)
    print("\n5️⃣  Exporting tasks (ISP - focused interfaces)...")
    exporter = TaskExporter(repository)
    json_export = exporter.export_to_json()
    print("   Tasks exported to JSON")
    
    # Report (ISP - separate interface)
    print("\n6️⃣  Generating report (ISP - separate interface)...")
    reporter = TaskReporter(repository)
    report = reporter.generate_report()
    print(f"\n{report}")
    
    print("=" * 70)
    print("SOLID PRINCIPLES DEMONSTRATED:")
    print("=" * 70)
    print("✅ SRP: Each class has single responsibility")
    print("✅ OCP: Filters extensible without modification")
    print("✅ LSP: All notifiers interchangeable")
    print("✅ ISP: Focused interfaces (Export, Report separate)")
    print("✅ DIP: Services depend on abstractions")
    print("=" * 70)

if __name__ == "__main__":
    main()
3. Complete Real-World System
Blog Platform with All Best Practices
Python

"""
Complete Blog Platform demonstrating all OOP best practices
"""

from abc import ABC, abstractmethod
from typing import List, Dict, Optional, Set
from datetime import datetime
from enum import Enum
import re

# ============================================================================
# DOMAIN MODELS
# ============================================================================

class UserRole(Enum):
    """User roles"""
    READER = "reader"
    AUTHOR = "author"
    EDITOR = "editor"
    ADMIN = "admin"

class PostStatus(Enum):
    """Post status"""
    DRAFT = "draft"
    PUBLISHED = "published"
    ARCHIVED = "archived"

class User:
    """
    Represents a user.
    Uses properties for controlled access.
    Well-documented with type hints.
    """
    
    def __init__(self, user_id: str, email: str, username: str, role: UserRole):
        """
        Initialize a user.
        
        Args:
            user_id: Unique identifier
            email: User's email address
            username: User's display name
            role: User's role in the system
            
        Raises:
            ValueError: If email or username is invalid
        """
        self.user_id = user_id
        self._email = ""
        self._username = ""
        self.role = role
        self.created_at = datetime.now()
        
        # Use setters for validation
        self.email = email
        self.username = username
    
    @property
    def email(self) -> str:
        """Get user email"""
        return self._email
    
    @email.setter
    def email(self, value: str):
        """
        Set user email with validation.
        
        Args:
            value: Email address
            
        Raises:
            ValueError: If email format is invalid
        """
        pattern = r'^[\w\.-]+@[\w\.-]+\.\w+$'
        if not re.match(pattern, value):
            raise ValueError(f"Invalid email format: {value}")
        self._email = value
    
    @property
    def username(self) -> str:
        """Get username"""
        return self._username
    
    @username.setter
    def username(self, value: str):
        """
        Set username with validation.
        
        Args:
            value: Username
            
        Raises:
            ValueError: If username is invalid
        """
        if not value or len(value) < 3:
            raise ValueError("Username must be at least 3 characters")
        if len(value) > 30:
            raise ValueError("Username too long (max 30 characters)")
        self._username = value
    
    def can_publish(self) -> bool:
        """Check if user can publish posts"""
        return self.role in [UserRole.AUTHOR, UserRole.EDITOR, UserRole.ADMIN]
    
    def can_edit(self) -> bool:
        """Check if user can edit posts"""
        return self.role in [UserRole.EDITOR, UserRole.ADMIN]
    
    def can_delete(self) -> bool:
        """Check if user can delete posts"""
        return self.role == UserRole.ADMIN
    
    def __str__(self) -> str:
        return f"{self.username} ({self.role.value})"
    
    def __repr__(self) -> str:
        return f"User(id='{self.user_id}', username='{self.username}', role={self.role.value})"

class Post:
    """
    Represents a blog post.
    Demonstrates encapsulation and properties.
    """
    
    def __init__(
        self,
        post_id: str,
        author: User,
        title: str,
        content: str
    ):
        """
        Initialize a blog post.
        
        Args:
            post_id: Unique identifier
            author: Post author (must be able to publish)
            title: Post title
            content: Post content
            
        Raises:
            ValueError: If author cannot publish or data is invalid
        """
        if not author.can_publish():
            raise ValueError(f"User {author.username} cannot publish posts")
        
        self.post_id = post_id
        self.author = author
        self._title = ""
        self._content = ""
        self.status = PostStatus.DRAFT
        self.created_at = datetime.now()
        self.published_at: Optional[datetime] = None
        self.updated_at = datetime.now()
        self.tags: Set[str] = set()
        self.views = 0
        
        # Use setters for validation
        self.title = title
        self.content = content
    
    @property
    def title(self) -> str:
        """Get post title"""
        return self._title
    
    @title.setter
    def title(self, value: str):
        """Set post title with validation"""
        if not value or not value.strip():
            raise ValueError("Title cannot be empty")
        if len(value) > 200:
            raise ValueError("Title too long (max 200 characters)")
        self._title = value.strip()
        self.updated_at = datetime.now()
    
    @property
    def content(self) -> str:
        """Get post content"""
        return self._content
    
    @content.setter
    def content(self, value: str):
        """Set post content with validation"""
        if not value or not value.strip():
            raise ValueError("Content cannot be empty")
        if len(value) < 100:
            raise ValueError("Content too short (min 100 characters)")
        self._content = value.strip()
        self.updated_at = datetime.now()
    
    @property
    def is_published(self) -> bool:
        """Check if post is published"""
        return self.status == PostStatus.PUBLISHED
    
    def add_tag(self, tag: str):
        """Add a tag to the post"""
        self.tags.add(tag.lower().strip())
    
    def publish(self):
        """Publish the post"""
        if self.status == PostStatus.PUBLISHED:
            raise ValueError("Post already published")
        
        self.status = PostStatus.PUBLISHED
        self.published_at = datetime.now()
    
    def archive(self):
        """Archive the post"""
        self.status = PostStatus.ARCHIVED
    
    def increment_views(self):
        """Increment view count"""
        self.views += 1
    
    def __str__(self) -> str:
        status_emoji = {
            PostStatus.DRAFT: "📝",
            PostStatus.PUBLISHED: "📰",
            PostStatus.ARCHIVED: "📦"
        }
        emoji = status_emoji.get(self.status, "❓")
        return f"{emoji} {self.title} by {self.author.username}"
    
    def __repr__(self) -> str:
        return f"Post(id='{self.post_id}', title='{self.title}', status={self.status.value})"

# ============================================================================
# ABSTRACT BASE CLASSES (Interface Definition)
# ============================================================================

class Repository(ABC):
    """
    Abstract repository interface.
    All repositories must implement these methods.
    """
    
    @abstractmethod
    def add(self, entity) -> bool:
        """Add entity"""
        pass
    
    @abstractmethod
    def get(self, entity_id: str):
        """Get entity by ID"""
        pass
    
    @abstractmethod
    def update(self, entity) -> bool:
        """Update entity"""
        pass
    
    @abstractmethod
    def delete(self, entity_id: str) -> bool:
        """Delete entity"""
        pass
    
    @abstractmethod
    def get_all(self) -> List:
        """Get all entities"""
        pass

class SearchEngine(ABC):
    """Abstract search engine interface"""
    
    @abstractmethod
    def index(self, post: Post):
        """Index a post"""
        pass
    
    @abstractmethod
    def search(self, query: str) -> List[Post]:
        """Search posts"""
        pass

class CacheService(ABC):
    """Abstract cache service interface"""
    
    @abstractmethod
    def get(self, key: str) -> Optional[any]:
        """Get from cache"""
        pass
    
    @abstractmethod
    def set(self, key: str, value: any, ttl: int = 3600):
        """Set cache value"""
        pass
    
    @abstractmethod
    def delete(self, key: str):
        """Delete from cache"""
        pass

# ============================================================================
# CONCRETE IMPLEMENTATIONS
# ============================================================================

class InMemoryPostRepository(Repository):
    """In-memory post repository implementation"""
    
    def __init__(self):
        self._posts: Dict[str, Post] = {}
    
    def add(self, post: Post) -> bool:
        if post.post_id in self._posts:
            return False
        self._posts[post.post_id] = post
        return True
    
    def get(self, post_id: str) -> Optional[Post]:
        return self._posts.get(post_id)
    
    def update(self, post: Post) -> bool:
        if post.post_id not in self._posts:
            return False
        self._posts[post.post_id] = post
        return True
    
    def delete(self, post_id: str) -> bool:
        if post_id in self._posts:
            del self._posts[post_id]
            return True
        return False
    
    def get_all(self) -> List[Post]:
        return list(self._posts.values())
    
    def find_by_author(self, author_id: str) -> List[Post]:
        """Additional method specific to posts"""
        return [p for p in self._posts.values() if p.author.user_id == author_id]
    
    def find_by_status(self, status: PostStatus) -> List[Post]:
        """Find posts by status"""
        return [p for p in self._posts.values() if p.status == status]

class SimpleSearchEngine(SearchEngine):
    """Simple keyword-based search implementation"""
    
    def __init__(self):
        self._index: Dict[str, Set[str]] = {}  # word -> set of post_ids
    
    def index(self, post: Post):
        """Index post by words in title and content"""
        words = set()
        
        # Index title words
        words.update(post.title.lower().split())
        
        # Index content words (first 500 words for simplicity)
        content_words = post.content.lower().split()[:500]
        words.update(content_words)
        
        # Index tags
        words.update(post.tags)
        
        # Add to index
        for word in words:
            if word not in self._index:
                self._index[word] = set()
            self._index[word].add(post.post_id)
    
    def search(self, query: str) -> List[str]:
        """
        Search and return matching post IDs.
        Returns list of post IDs sorted by relevance.
        """
        query_words = query.lower().split()
        matching_posts: Dict[str, int] = {}  # post_id -> relevance score
        
        for word in query_words:
            if word in self._index:
                for post_id in self._index[word]:
                    matching_posts[post_id] = matching_posts.get(post_id, 0) + 1
        
        # Sort by relevance (number of matching words)
        sorted_posts = sorted(
            matching_posts.items(),
            key=lambda x: x[1],
            reverse=True
        )
        
        return [post_id for post_id, _ in sorted_posts]

class InMemoryCache(CacheService):
    """Simple in-memory cache implementation"""
    
    def __init__(self):
        self._cache: Dict[str, tuple[any, datetime]] = {}  # key -> (value, expiry)
    
    def get(self, key: str) -> Optional[any]:
        if key in self._cache:
            value, expiry = self._cache[key]
            if datetime.now() < expiry:
                return value
            else:
                del self._cache[key]
        return None
    
    def set(self, key: str, value: any, ttl: int = 3600):
        expiry = datetime.now() + timedelta(seconds=ttl)
        self._cache[key] = (value, expiry)
    
    def delete(self, key: str):
        if key in self._cache:
            del self._cache[key]

# ============================================================================
# SERVICES (Business Logic)
# ============================================================================

class BlogService:
    """
    High-level blog service.
    Demonstrates:
    - Dependency Inversion (depends on abstractions)
    - Composition (has repository, search, cache)
    - Single Responsibility (coordinates blog operations)
    """
    
    def __init__(
        self,
        post_repository: Repository,
        search_engine: SearchEngine,
        cache: CacheService
    ):
        """
        Initialize blog service with dependencies.
        
        Args:
            post_repository: Repository for post persistence
            search_engine: Search engine for finding posts
            cache: Cache service for performance
        """
        self.repository = post_repository
        self.search = search_engine
        self.cache = cache
    
    def create_post(
        self,
        post_id: str,
        author: User,
        title: str,
        content: str,
        tags: Optional[List[str]] = None
    ) -> tuple[bool, Optional[Post], List[str]]:
        """
        Create a new post.
        
        Returns:
            (success, post, errors)
        """
        try:
            post = Post(post_id, author, title, content)
            
            if tags:
                for tag in tags:
                    post.add_tag(tag)
            
            success = self.repository.add(post)
            if not success:
                return (False, None, ["Post ID already exists"])
            
            return (True, post, [])
            
        except ValueError as e:
            return (False, None, [str(e)])
    
    def publish_post(self, post_id: str) -> tuple[bool, List[str]]:
        """Publish a post"""
        post = self.repository.get(post_id)
        if not post:
            return (False, ["Post not found"])
        
        try:
            post.publish()
            self.repository.update(post)
            
            # Index for search
            self.search.index(post)
            
            # Invalidate cache
            self.cache.delete(f"post:{post_id}")
            
            return (True, [])
            
        except ValueError as e:
            return (False, [str(e)])
    
    def get_post(self, post_id: str) -> Optional[Post]:
        """
        Get post with caching.
        Demonstrates use of cache service.
        """
        # Try cache first
        cache_key = f"post:{post_id}"
        cached = self.cache.get(cache_key)
        if cached:
            return cached
        
        # Get from repository
        post = self.repository.get(post_id)
        if post:
            # Cache it
            self.cache.set(cache_key, post, ttl=300)  # 5 minutes
            
            # Increment views
            post.increment_views()
            self.repository.update(post)
        
        return post
    
    def search_posts(self, query: str) -> List[Post]:
        """Search posts using search engine"""
        post_ids = self.search.search(query)
        posts = []
        
        for post_id in post_ids:
            post = self.repository.get(post_id)
            if post and post.is_published:
                posts.append(post)
        
        return posts
    
    def get_user_posts(self, author_id: str) -> List[Post]:
        """Get all posts by an author"""
        # Type check to use specific repository method
        if isinstance(self.repository, InMemoryPostRepository):
            return self.repository.find_by_author(author_id)
        
        # Fallback
        return [p for p in self.repository.get_all() if p.author.user_id == author_id]
    
    def get_published_posts(self) -> List[Post]:
        """Get all published posts"""
        if isinstance(self.repository, InMemoryPostRepository):
            return self.repository.find_by_status(PostStatus.PUBLISHED)
        
        return [p for p in self.repository.get_all() if p.is_published]

# ============================================================================
# DEMONSTRATION
# ============================================================================

def main():
    """Demonstrate complete blog platform"""
    
    print("=" * 70)
    print("BLOG PLATFORM - ALL BEST PRACTICES")
    print("=" * 70)
    
    # Setup (Dependency Injection)
    repository = InMemoryPostRepository()
    search_engine = SimpleSearchEngine()
    cache = InMemoryCache()
    
    blog_service = BlogService(repository, search_engine, cache)
    
    # Create users
    print("\n1️⃣  Creating users...")
    admin = User("U001", "admin@blog.com", "admin", UserRole.ADMIN)
    author = User("U002", "author@blog.com", "john_doe", UserRole.AUTHOR)
    reader = User("U003", "reader@blog.com", "jane_reader", UserRole.READER)
    
    print(f"   {admin}")
    print(f"   {author}")
    print(f"   {reader}")
    
    # Create posts
    print("\n2️⃣  Creating posts...")
    
    success, post1, errors = blog_service.create_post(
        "P001",
        author,
        "Getting Started with Python OOP",
        "Learn object-oriented programming in Python. " * 10,
        ["python", "oop", "tutorial"]
    )
    if success:
        print(f"   ✅ {post1}")
    
    success, post2, errors = blog_service.create_post(
        "P002",
        author,
        "Advanced Design Patterns",
        "Deep dive into software design patterns. " * 10,
        ["design patterns", "software engineering"]
    )
    if success:
        print(f"   ✅ {post2}")
    
    # Try to create post as reader (should fail)
    try:
        Post("P003", reader, "Test", "Content" * 20)
    except ValueError as e:
        print(f"   ❌ Reader cannot publish: {e}")
    
    # Publish posts
    print("\n3️⃣  Publishing posts...")
    blog_service.publish_post("P001")
    blog_service.publish_post("P002")
    print(f"   Published 2 posts")
    
    # Get post (with caching)
    print("\n4️⃣  Getting posts (with caching)...")
    post = blog_service.get_post("P001")
    print(f"   First fetch: {post} (Views: {post.views})")
    
    post = blog_service.get_post("P001")
    print(f"   Cached fetch: {post} (Views: {post.views})")
    
    # Search posts
    print("\n5️⃣  Searching posts...")
    results = blog_service.search_posts("python oop")
    print(f"   Found {len(results)} posts for 'python oop':")
    for post in results:
        print(f"      {post}")
    
    # Get user's posts
    print("\n6️⃣  Getting author's posts...")
    user_posts = blog_service.get_user_posts(author.user_id)
    print(f"   {author.username} has {len(user_posts)} posts:")
    for post in user_posts:
        print(f"      {post}")
    
    # Properties demonstration
    print("\n7️⃣  Testing properties and validation...")
    try:
        post1.title = "Updated Title"
        print(f"   ✅ Title updated: {post1.title}")
    except ValueError as e:
        print(f"   ❌ {e}")
    
    try:
        post1.title = ""  # Should fail
    except ValueError as e:
        print(f"   ❌ Validation works: {e}")
    
    print("\n" + "=" * 70)
    print("DEMONSTRATED BEST PRACTICES:")
    print("=" * 70)
    print("✅ Composition: BlogService HAS-A repository, search, cache")
    print("✅ SOLID: All principles applied")
    print("✅ Properties: Validated access to title, content, email")
    print("✅ ABC: Repository, SearchEngine, CacheService are abstract")
    print("✅ Special methods: __str__, __repr__ for debugging")
    print("✅ Type hints: All methods have type annotations")
    print("✅ Documentation: Comprehensive docstrings")
    print("✅ Encapsulation: Private attributes with validation")
    print("=" * 70)

if __name__ == "__main__":
    main()


Ultimate Python OOP Mastery: Production-Ready Examples
Let me provide you with production-grade examples that show all these principles working together in real-world applications.

1. E-Commerce Platform - Complete Implementation
Python

"""
Production-Ready E-Commerce Platform
Demonstrates ALL OOP best practices in a cohesive system
"""

from abc import ABC, abstractmethod
from typing import List, Dict, Optional, Set, Callable
from datetime import datetime, timedelta
from enum import Enum
from dataclasses import dataclass
from decimal import Decimal
import uuid
import re

# ============================================================================
# DOMAIN MODELS - Well-documented, focused classes
# ============================================================================

class Currency(Enum):
    """Supported currencies"""
    USD = "USD"
    EUR = "EUR"
    GBP = "GBP"

class OrderStatus(Enum):
    """Order lifecycle states"""
    PENDING = "pending"
    CONFIRMED = "confirmed"
    PROCESSING = "processing"
    SHIPPED = "shipped"
    DELIVERED = "delivered"
    CANCELLED = "cancelled"
    REFUNDED = "refunded"

class PaymentStatus(Enum):
    """Payment states"""
    PENDING = "pending"
    AUTHORIZED = "authorized"
    CAPTURED = "captured"
    FAILED = "failed"
    REFUNDED = "refunded"

@dataclass
class Money:
    """
    Value object for monetary amounts.
    Immutable and provides type-safe money operations.
    
    Examples:
        >>> price = Money(Decimal('99.99'), Currency.USD)
        >>> tax = price * Decimal('0.1')
        >>> total = price + tax
    """
    amount: Decimal
    currency: Currency
    
    def __post_init__(self):
        """Validate after initialization"""
        if not isinstance(self.amount, Decimal):
            self.amount = Decimal(str(self.amount))
        if self.amount < 0:
            raise ValueError("Amount cannot be negative")
    
    def __add__(self, other: 'Money') -> 'Money':
        """Add two Money objects"""
        if self.currency != other.currency:
            raise ValueError(f"Cannot add {self.currency} and {other.currency}")
        return Money(self.amount + other.amount, self.currency)
    
    def __sub__(self, other: 'Money') -> 'Money':
        """Subtract two Money objects"""
        if self.currency != other.currency:
            raise ValueError(f"Cannot subtract different currencies")
        return Money(self.amount - other.amount, self.currency)
    
    def __mul__(self, multiplier: Decimal) -> 'Money':
        """Multiply money by a number"""
        return Money(self.amount * multiplier, self.currency)
    
    def __truediv__(self, divisor: Decimal) -> 'Money':
        """Divide money by a number"""
        return Money(self.amount / divisor, self.currency)
    
    def __eq__(self, other) -> bool:
        """Check equality"""
        if not isinstance(other, Money):
            return False
        return self.amount == other.amount and self.currency == other.currency
    
    def __lt__(self, other: 'Money') -> bool:
        """Less than comparison"""
        if self.currency != other.currency:
            raise ValueError("Cannot compare different currencies")
        return self.amount < other.amount
    
    def __str__(self) -> str:
        """User-friendly representation"""
        return f"{self.currency.value} {self.amount:.2f}"
    
    def __repr__(self) -> str:
        """Developer representation"""
        return f"Money({self.amount}, {self.currency})"

class Product:
    """
    Represents a product in the catalog.
    
    Demonstrates:
    - Properties for controlled access
    - Input validation
    - Encapsulation
    - Clear single responsibility
    
    Attributes:
        product_id: Unique identifier
        name: Product name
        price: Product price (Money object)
        stock: Available quantity
        sku: Stock Keeping Unit
        description: Product description
    """
    
    def __init__(
        self,
        product_id: str,
        name: str,
        price: Money,
        sku: str,
        initial_stock: int = 0,
        description: str = ""
    ):
        """
        Initialize a product.
        
        Args:
            product_id: Unique product identifier
            name: Product name
            price: Product price
            sku: Stock Keeping Unit
            initial_stock: Initial stock quantity
            description: Product description
            
        Raises:
            ValueError: If validation fails
        """
        self.product_id = product_id
        self.sku = sku
        self._name = ""
        self._price = price
        self._stock = 0
        self._description = description
        
        # Use setters for validation
        self.name = name
        self.stock = initial_stock
        
        self.created_at = datetime.now()
    
    @property
    def name(self) -> str:
        """Get product name"""
        return self._name
    
    @name.setter
    def name(self, value: str):
        """
        Set product name with validation.
        
        Args:
            value: Product name
            
        Raises:
            ValueError: If name is invalid
        """
        if not value or not value.strip():
            raise ValueError("Product name cannot be empty")
        if len(value) > 200:
            raise ValueError("Product name too long (max 200 chars)")
        self._name = value.strip()
    
    @property
    def price(self) -> Money:
        """Get product price"""
        return self._price
    
    @price.setter
    def price(self, value: Money):
        """
        Set product price.
        
        Args:
            value: New price
            
        Raises:
            ValueError: If price is invalid
        """
        if value.amount <= 0:
            raise ValueError("Price must be positive")
        self._price = value
    
    @property
    def stock(self) -> int:
        """Get available stock"""
        return self._stock
    
    @stock.setter
    def stock(self, value: int):
        """
        Set stock quantity.
        
        Args:
            value: Stock quantity
            
        Raises:
            ValueError: If stock is negative
        """
        if value < 0:
            raise ValueError("Stock cannot be negative")
        self._stock = value
    
    @property
    def is_available(self) -> bool:
        """Check if product is in stock"""
        return self._stock > 0
    
    def reserve_stock(self, quantity: int) -> bool:
        """
        Reserve stock for an order.
        
        Args:
            quantity: Quantity to reserve
            
        Returns:
            True if successful, False if insufficient stock
        """
        if quantity <= 0:
            raise ValueError("Quantity must be positive")
        
        if self._stock >= quantity:
            self._stock -= quantity
            return True
        return False
    
    def release_stock(self, quantity: int):
        """
        Release reserved stock (e.g., cancelled order).
        
        Args:
            quantity: Quantity to release
        """
        if quantity <= 0:
            raise ValueError("Quantity must be positive")
        self._stock += quantity
    
    def __str__(self) -> str:
        """User-friendly representation"""
        availability = "✅ In Stock" if self.is_available else "❌ Out of Stock"
        return f"{self.name} - {self.price} ({availability})"
    
    def __repr__(self) -> str:
        """Developer representation"""
        return (
            f"Product(id='{self.product_id}', name='{self.name}', "
            f"price={self.price}, stock={self.stock})"
        )

class Customer:
    """
    Represents a customer.
    
    Demonstrates:
    - Email validation with regex
    - Property decorators
    - Encapsulation of customer data
    """
    
    def __init__(
        self,
        customer_id: str,
        email: str,
        first_name: str,
        last_name: str,
        phone: Optional[str] = None
    ):
        """
        Initialize a customer.
        
        Args:
            customer_id: Unique identifier
            email: Customer email
            first_name: First name
            last_name: Last name
            phone: Optional phone number
            
        Raises:
            ValueError: If validation fails
        """
        self.customer_id = customer_id
        self._email = ""
        self._first_name = ""
        self._last_name = ""
        self._phone = phone
        
        # Use setters for validation
        self.email = email
        self.first_name = first_name
        self.last_name = last_name
        
        self.created_at = datetime.now()
        self.addresses: List['Address'] = []
        self.loyalty_points = 0
    
    @property
    def email(self) -> str:
        """Get customer email"""
        return self._email
    
    @email.setter
    def email(self, value: str):
        """
        Set customer email with validation.
        
        Args:
            value: Email address
            
        Raises:
            ValueError: If email format is invalid
        """
        pattern = r'^[\w\.-]+@[\w\.-]+\.\w+$'
        if not re.match(pattern, value):
            raise ValueError(f"Invalid email format: {value}")
        self._email = value.lower().strip()
    
    @property
    def first_name(self) -> str:
        """Get first name"""
        return self._first_name
    
    @first_name.setter
    def first_name(self, value: str):
        """Set first name with validation"""
        if not value or len(value.strip()) < 2:
            raise ValueError("First name must be at least 2 characters")
        self._first_name = value.strip()
    
    @property
    def last_name(self) -> str:
        """Get last name"""
        return self._last_name
    
    @last_name.setter
    def last_name(self, value: str):
        """Set last name with validation"""
        if not value or len(value.strip()) < 2:
            raise ValueError("Last name must be at least 2 characters")
        self._last_name = value.strip()
    
    @property
    def full_name(self) -> str:
        """Get full name (computed property)"""
        return f"{self._first_name} {self._last_name}"
    
    def add_address(self, address: 'Address'):
        """Add delivery address"""
        self.addresses.append(address)
    
    def add_loyalty_points(self, points: int):
        """Add loyalty points"""
        if points < 0:
            raise ValueError("Points must be positive")
        self.loyalty_points += points
    
    def redeem_loyalty_points(self, points: int) -> bool:
        """
        Redeem loyalty points.
        
        Returns:
            True if successful, False if insufficient points
        """
        if points < 0:
            raise ValueError("Points must be positive")
        if self.loyalty_points >= points:
            self.loyalty_points -= points
            return True
        return False
    
    def __str__(self) -> str:
        """User-friendly representation"""
        return f"{self.full_name} ({self.email})"
    
    def __repr__(self) -> str:
        """Developer representation"""
        return (
            f"Customer(id='{self.customer_id}', "
            f"name='{self.full_name}', email='{self.email}')"
        )

@dataclass
class Address:
    """
    Value object for addresses.
    Immutable after creation.
    """
    street: str
    city: str
    state: str
    postal_code: str
    country: str
    
    def __str__(self) -> str:
        return (
            f"{self.street}, {self.city}, "
            f"{self.state} {self.postal_code}, {self.country}"
        )

class OrderItem:
    """
    Represents an item in an order.
    
    Demonstrates:
    - Composition (HAS-A Product)
    - Computed properties
    - Immutability (quantity can't be changed after creation)
    """
    
    def __init__(self, product: Product, quantity: int, unit_price: Money):
        """
        Initialize order item.
        
        Args:
            product: Product being ordered
            quantity: Quantity ordered
            unit_price: Price at time of order (for price history)
            
        Raises:
            ValueError: If quantity is invalid
        """
        if quantity <= 0:
            raise ValueError("Quantity must be positive")
        
        self._product = product
        self._quantity = quantity
        self._unit_price = unit_price
    
    @property
    def product(self) -> Product:
        """Get product (read-only)"""
        return self._product
    
    @property
    def quantity(self) -> int:
        """Get quantity (read-only)"""
        return self._quantity
    
    @property
    def unit_price(self) -> Money:
        """Get unit price (read-only)"""
        return self._unit_price
    
    @property
    def subtotal(self) -> Money:
        """Calculate subtotal (computed property)"""
        return self._unit_price * Decimal(self._quantity)
    
    def __str__(self) -> str:
        """User-friendly representation"""
        return f"{self.product.name} x{self.quantity} = {self.subtotal}"
    
    def __repr__(self) -> str:
        """Developer representation"""
        return (
            f"OrderItem(product='{self.product.name}', "
            f"quantity={self.quantity}, subtotal={self.subtotal})"
        )

# ============================================================================
# ABSTRACT BASE CLASSES - Clear interface definitions
# ============================================================================

class PricingStrategy(ABC):
    """
    Abstract pricing strategy (OPEN/CLOSED PRINCIPLE).
    New pricing strategies can be added without modifying existing code.
    """
    
    @abstractmethod
    def calculate_price(self, items: List[OrderItem]) -> Money:
        """
        Calculate total price for items.
        
        Args:
            items: List of order items
            
        Returns:
            Total price
        """
        pass
    
    @abstractmethod
    def get_description(self) -> str:
        """Get strategy description"""
        pass

class PaymentGateway(ABC):
    """
    Abstract payment gateway (LISKOV SUBSTITUTION).
    All payment gateways are interchangeable.
    """
    
    @abstractmethod
    def authorize(self, amount: Money, payment_details: Dict) -> Dict:
        """
        Authorize payment.
        
        Args:
            amount: Amount to authorize
            payment_details: Payment method details
            
        Returns:
            Authorization result
        """
        pass
    
    @abstractmethod
    def capture(self, authorization_id: str) -> Dict:
        """
        Capture authorized payment.
        
        Args:
            authorization_id: Authorization ID
            
        Returns:
            Capture result
        """
        pass
    
    @abstractmethod
    def refund(self, transaction_id: str, amount: Money) -> Dict:
        """
        Refund payment.
        
        Args:
            transaction_id: Transaction ID
            amount: Amount to refund
            
        Returns:
            Refund result
        """
        pass

class NotificationChannel(ABC):
    """
    Abstract notification channel (INTERFACE SEGREGATION).
    Different notification types with focused interfaces.
    """
    
    @abstractmethod
    def send(self, recipient: str, subject: str, message: str) -> bool:
        """Send notification"""
        pass
    
    @abstractmethod
    def get_channel_type(self) -> str:
        """Get channel type"""
        pass

class InventoryService(ABC):
    """Abstract inventory service"""
    
    @abstractmethod
    def reserve_stock(self, product_id: str, quantity: int) -> bool:
        """Reserve stock for order"""
        pass
    
    @abstractmethod
    def release_stock(self, product_id: str, quantity: int):
        """Release reserved stock"""
        pass
    
    @abstractmethod
    def check_availability(self, product_id: str, quantity: int) -> bool:
        """Check stock availability"""
        pass

class Repository(ABC):
    """Generic repository interface"""
    
    @abstractmethod
    def save(self, entity) -> bool:
        """Save entity"""
        pass
    
    @abstractmethod
    def find_by_id(self, entity_id: str):
        """Find entity by ID"""
        pass
    
    @abstractmethod
    def find_all(self) -> List:
        """Find all entities"""
        pass
    
    @abstractmethod
    def delete(self, entity_id: str) -> bool:
        """Delete entity"""
        pass

# ============================================================================
# CONCRETE IMPLEMENTATIONS
# ============================================================================

class StandardPricing(PricingStrategy):
    """Standard pricing - sum of all items"""
    
    def calculate_price(self, items: List[OrderItem]) -> Money:
        if not items:
            raise ValueError("Cannot calculate price for empty order")
        
        currency = items[0].unit_price.currency
        total = Money(Decimal('0'), currency)
        
        for item in items:
            total = total + item.subtotal
        
        return total
    
    def get_description(self) -> str:
        return "Standard Pricing"

class BulkDiscountPricing(PricingStrategy):
    """
    Bulk discount pricing.
    Example of OPEN/CLOSED - new strategy without modifying existing code.
    """
    
    def __init__(self, threshold: int, discount_percent: Decimal):
        """
        Initialize bulk discount.
        
        Args:
            threshold: Minimum items for discount
            discount_percent: Discount percentage (e.g., 10 for 10%)
        """
        self.threshold = threshold
        self.discount_percent = discount_percent
    
    def calculate_price(self, items: List[OrderItem]) -> Money:
        standard = StandardPricing()
        subtotal = standard.calculate_price(items)
        
        total_items = sum(item.quantity for item in items)
        
        if total_items >= self.threshold:
            discount = subtotal * (self.discount_percent / Decimal('100'))
            return subtotal - discount
        
        return subtotal
    
    def get_description(self) -> str:
        return f"{self.discount_percent}% off for {self.threshold}+ items"

class LoyaltyDiscountPricing(PricingStrategy):
    """Loyalty-based pricing"""
    
    def __init__(self, customer: Customer, points_value: Decimal):
        """
        Initialize loyalty discount.
        
        Args:
            customer: Customer with loyalty points
            points_value: Value of each point in currency
        """
        self.customer = customer
        self.points_value = points_value
    
    def calculate_price(self, items: List[OrderItem]) -> Money:
        standard = StandardPricing()
        subtotal = standard.calculate_price(items)
        
        # Calculate discount from loyalty points
        points_discount = Money(
            self.customer.loyalty_points * self.points_value,
            subtotal.currency
        )
        
        # Don't discount more than subtotal
        if points_discount > subtotal:
            points_discount = subtotal
        
        return subtotal - points_discount
    
    def get_description(self) -> str:
        return f"Loyalty discount ({self.customer.loyalty_points} points)"

class StripePaymentGateway(PaymentGateway):
    """Stripe payment implementation (LISKOV SUBSTITUTION)"""
    
    def authorize(self, amount: Money, payment_details: Dict) -> Dict:
        """Simulate Stripe authorization"""
        print(f"💳 Stripe: Authorizing {amount}")
        return {
            'success': True,
            'authorization_id': f"auth_{uuid.uuid4().hex[:12]}",
            'amount': amount,
            'status': PaymentStatus.AUTHORIZED
        }
    
    def capture(self, authorization_id: str) -> Dict:
        """Simulate Stripe capture"""
        print(f"💰 Stripe: Capturing {authorization_id}")
        return {
            'success': True,
            'transaction_id': f"txn_{uuid.uuid4().hex[:12]}",
            'status': PaymentStatus.CAPTURED
        }
    
    def refund(self, transaction_id: str, amount: Money) -> Dict:
        """Simulate Stripe refund"""
        print(f"↩️  Stripe: Refunding {amount}")
        return {
            'success': True,
            'refund_id': f"ref_{uuid.uuid4().hex[:12]}",
            'status': PaymentStatus.REFUNDED
        }

class PayPalGateway(PaymentGateway):
    """PayPal payment implementation (LISKOV SUBSTITUTION)"""
    
    def authorize(self, amount: Money, payment_details: Dict) -> Dict:
        """Simulate PayPal authorization"""
        print(f"💳 PayPal: Authorizing {amount}")
        return {
            'success': True,
            'authorization_id': f"pp_auth_{uuid.uuid4().hex[:12]}",
            'amount': amount,
            'status': PaymentStatus.AUTHORIZED
        }
    
    def capture(self, authorization_id: str) -> Dict:
        """Simulate PayPal capture"""
        print(f"💰 PayPal: Capturing {authorization_id}")
        return {
            'success': True,
            'transaction_id': f"pp_txn_{uuid.uuid4().hex[:12]}",
            'status': PaymentStatus.CAPTURED
        }
    
    def refund(self, transaction_id: str, amount: Money) -> Dict:
        """Simulate PayPal refund"""
        print(f"↩️  PayPal: Refunding")
        return {
            'success': True,
            'refund_id': f"pp_ref_{uuid.uuid4().hex[:12]}",
            'status': PaymentStatus.REFUNDED
        }

class EmailNotification(NotificationChannel):
    """Email notification implementation"""
    
    def send(self, recipient: str, subject: str, message: str) -> bool:
        print(f"📧 Email to {recipient}")
        print(f"   Subject: {subject}")
        print(f"   {message[:50]}...")
        return True
    
    def get_channel_type(self) -> str:
        return "Email"

class SMSNotification(NotificationChannel):
    """SMS notification implementation"""
    
    def send(self, recipient: str, subject: str, message: str) -> bool:
        print(f"📱 SMS to {recipient}: {message[:50]}...")
        return True
    
    def get_channel_type(self) -> str:
        return "SMS"

class SimpleInventoryService(InventoryService):
    """Simple in-memory inventory service"""
    
    def __init__(self, products: Dict[str, Product]):
        self.products = products
    
    def reserve_stock(self, product_id: str, quantity: int) -> bool:
        product = self.products.get(product_id)
        if not product:
            return False
        return product.reserve_stock(quantity)
    
    def release_stock(self, product_id: str, quantity: int):
        product = self.products.get(product_id)
        if product:
            product.release_stock(quantity)
    
    def check_availability(self, product_id: str, quantity: int) -> bool:
        product = self.products.get(product_id)
        if not product:
            return False
        return product.stock >= quantity

class InMemoryOrderRepository(Repository):
    """In-memory order repository"""
    
    def __init__(self):
        self._orders: Dict[str, 'Order'] = {}
    
    def save(self, order: 'Order') -> bool:
        self._orders[order.order_id] = order
        return True
    
    def find_by_id(self, order_id: str) -> Optional['Order']:
        return self._orders.get(order_id)
    
    def find_all(self) -> List['Order']:
        return list(self._orders.values())
    
    def delete(self, order_id: str) -> bool:
        if order_id in self._orders:
            del self._orders[order_id]
            return True
        return False
    
    def find_by_customer(self, customer_id: str) -> List['Order']:
        return [
            order for order in self._orders.values()
            if order.customer.customer_id == customer_id
        ]

# ============================================================================
# MAIN AGGREGATE - Order (COMPOSITION)
# ============================================================================

class Order:
    """
    Main order aggregate demonstrating COMPOSITION.
    
    This class:
    - Uses composition (HAS-A pricing, payment, inventory)
    - Depends on abstractions (DEPENDENCY INVERSION)
    - Has single responsibility (order management)
    - Uses properties for controlled access
    - Is well-documented
    
    The Order delegates to:
    - PricingStrategy for price calculation
    - PaymentGateway for payment processing
    - InventoryService for stock management
    - NotificationChannel for customer updates
    """
    
    def __init__(
        self,
        order_id: str,
        customer: Customer,
        pricing_strategy: PricingStrategy,
        payment_gateway: PaymentGateway,
        inventory_service: InventoryService,
        notification_channels: Optional[List[NotificationChannel]] = None
    ):
        """
        Initialize order with dependencies (DEPENDENCY INJECTION).
        
        Args:
            order_id: Unique order identifier
            customer: Customer placing order
            pricing_strategy: Strategy for price calculation
            payment_gateway: Gateway for payment processing
            inventory_service: Service for inventory management
            notification_channels: Optional notification channels
        """
        self.order_id = order_id
        self.customer = customer
        
        # Composition: Order HAS-A pricing strategy
        self._pricing_strategy = pricing_strategy
        
        # Composition: Order HAS-A payment gateway
        self._payment_gateway = payment_gateway
        
        # Composition: Order HAS-A inventory service
        self._inventory_service = inventory_service
        
        # Composition: Order HAS-A notification channels
        self._notification_channels = notification_channels or []
        
        self._items: List[OrderItem] = []
        self._status = OrderStatus.PENDING
        self._payment_status = PaymentStatus.PENDING
        self._shipping_address: Optional[Address] = None
        
        self.created_at = datetime.now()
        self._authorization_id: Optional[str] = None
        self._transaction_id: Optional[str] = None
    
    @property
    def items(self) -> List[OrderItem]:
        """Get order items (returns copy for immutability)"""
        return self._items.copy()
    
    @property
    def status(self) -> OrderStatus:
        """Get order status"""
        return self._status
    
    @property
    def payment_status(self) -> PaymentStatus:
        """Get payment status"""
        return self._payment_status
    
    @property
    def total(self) -> Money:
        """
        Calculate order total using pricing strategy.
        Demonstrates STRATEGY PATTERN and COMPOSITION.
        """
        return self._pricing_strategy.calculate_price(self._items)
    
    @property
    def item_count(self) -> int:
        """Get total number of items"""
        return sum(item.quantity for item in self._items)
    
    def set_shipping_address(self, address: Address):
        """Set shipping address"""
        if self._status != OrderStatus.PENDING:
            raise ValueError("Cannot change address after order confirmation")
        self._shipping_address = address
    
    def add_item(self, product: Product, quantity: int) -> bool:
        """
        Add item to order.
        
        Args:
            product: Product to add
            quantity: Quantity to add
            
        Returns:
            True if successful
            
        Raises:
            ValueError: If order is not pending or quantity invalid
        """
        if self._status != OrderStatus.PENDING:
            raise ValueError("Cannot modify confirmed order")
        
        if quantity <= 0:
            raise ValueError("Quantity must be positive")
        
        # Check availability through inventory service
        if not self._inventory_service.check_availability(product.product_id, quantity):
            return False
        
        # Create order item with current price
        item = OrderItem(product, quantity, product.price)
        self._items.append(item)
        
        return True
    
    def remove_item(self, product_id: str) -> bool:
        """Remove item from order"""
        if self._status != OrderStatus.PENDING:
            raise ValueError("Cannot modify confirmed order")
        
        for item in self._items:
            if item.product.product_id == product_id:
                self._items.remove(item)
                return True
        
        return False
    
    def confirm(self) -> tuple[bool, List[str]]:
        """
        Confirm order and reserve inventory.
        
        Returns:
            (success, errors)
        """
        errors = []
        
        if self._status != OrderStatus.PENDING:
            errors.append("Order already confirmed")
            return (False, errors)
        
        if not self._items:
            errors.append("Cannot confirm empty order")
            return (False, errors)
        
        if not self._shipping_address:
            errors.append("Shipping address required")
            return (False, errors)
        
        # Reserve inventory for all items
        for item in self._items:
            success = self._inventory_service.reserve_stock(
                item.product.product_id,
                item.quantity
            )
            if not success:
                errors.append(f"Insufficient stock for {item.product.name}")
        
        if errors:
            return (False, errors)
        
        self._status = OrderStatus.CONFIRMED
        self._notify_customer("Order Confirmed", f"Your order #{self.order_id} has been confirmed!")
        
        return (True, [])
    
    def process_payment(self, payment_details: Dict) -> tuple[bool, List[str]]:
        """
        Process payment for order.
        
        Args:
            payment_details: Payment method details
            
        Returns:
            (success, errors)
        """
        errors = []
        
        if self._status != OrderStatus.CONFIRMED:
            errors.append("Order must be confirmed before payment")
            return (False, errors)
        
        if self._payment_status != PaymentStatus.PENDING:
            errors.append(f"Payment already {self._payment_status.value}")
            return (False, errors)
        
        # Authorize payment through gateway
        result = self._payment_gateway.authorize(self.total, payment_details)
        
        if not result['success']:
            self._payment_status = PaymentStatus.FAILED
            errors.append("Payment authorization failed")
            return (False, errors)
        
        self._authorization_id = result['authorization_id']
        self._payment_status = PaymentStatus.AUTHORIZED
        
        # Capture payment
        capture_result = self._payment_gateway.capture(self._authorization_id)
        
        if capture_result['success']:
            self._transaction_id = capture_result['transaction_id']
            self._payment_status = PaymentStatus.CAPTURED
            self._status = OrderStatus.PROCESSING
            
            # Award loyalty points (1 point per currency unit)
            points = int(self.total.amount)
            self.customer.add_loyalty_points(points)
            
            self._notify_customer(
                "Payment Successful",
                f"Payment of {self.total} processed successfully!"
            )
            
            return (True, [])
        else:
            errors.append("Payment capture failed")
            return (False, errors)
    
    def ship(self, tracking_number: str):
        """Mark order as shipped"""
        if self._status != OrderStatus.PROCESSING:
            raise ValueError("Can only ship processing orders")
        
        self._status = OrderStatus.SHIPPED
        self._notify_customer(
            "Order Shipped",
            f"Your order has been shipped! Tracking: {tracking_number}"
        )
    
    def deliver(self):
        """Mark order as delivered"""
        if self._status != OrderStatus.SHIPPED:
            raise ValueError("Can only deliver shipped orders")
        
        self._status = OrderStatus.DELIVERED
        self._notify_customer(
            "Order Delivered",
            "Your order has been delivered! Thank you for your purchase."
        )
    
    def cancel(self) -> tuple[bool, List[str]]:
        """
        Cancel order and release inventory.
        
        Returns:
            (success, errors)
        """
        errors = []
        
        if self._status in [OrderStatus.DELIVERED, OrderStatus.CANCELLED]:
            errors.append(f"Cannot cancel {self._status.value} order")
            return (False, errors)
        
        # Release inventory
        for item in self._items:
            self._inventory_service.release_stock(
                item.product.product_id,
                item.quantity
            )
        
        # Refund if payment was captured
        if self._payment_status == PaymentStatus.CAPTURED and self._transaction_id:
            refund_result = self._payment_gateway.refund(
                self._transaction_id,
                self.total
            )
            if refund_result['success']:
                self._payment_status = PaymentStatus.REFUNDED
        
        self._status = OrderStatus.CANCELLED
        self._notify_customer("Order Cancelled", "Your order has been cancelled.")
        
        return (True, [])
    
    def _notify_customer(self, subject: str, message: str):
        """Send notification through all channels"""
        for channel in self._notification_channels:
            channel.send(self.customer.email, subject, message)
    
    def __str__(self) -> str:
        """User-friendly representation"""
        status_emoji = {
            OrderStatus.PENDING: "⏳",
            OrderStatus.CONFIRMED: "✅",
            OrderStatus.PROCESSING: "⚙️",
            OrderStatus.SHIPPED: "📦",
            OrderStatus.DELIVERED: "🎉",
            OrderStatus.CANCELLED: "❌",
            OrderStatus.REFUNDED: "↩️"
        }
        emoji = status_emoji.get(self._status, "❓")
        
        return (
            f"{emoji} Order #{self.order_id}\n"
            f"Customer: {self.customer.full_name}\n"
            f"Items: {self.item_count}\n"
            f"Total: {self.total}\n"
            f"Status: {self._status.value}\n"
            f"Payment: {self._payment_status.value}"
        )
    
    def __repr__(self) -> str:
        """Developer representation"""
        return (
            f"Order(id='{self.order_id}', "
            f"customer='{self.customer.full_name}', "
            f"total={self.total}, status={self._status.value})"
        )

# ============================================================================
# HIGH-LEVEL SERVICE (Orchestration)
# ============================================================================

class OrderService:
    """
    High-level order service (FACADE PATTERN).
    
    Demonstrates:
    - DEPENDENCY INVERSION (depends on abstractions)
    - SINGLE RESPONSIBILITY (order orchestration)
    - COMPOSITION (uses multiple services)
    """
    
    def __init__(
        self,
        order_repository: Repository,
        inventory_service: InventoryService,
        default_payment_gateway: PaymentGateway,
        notification_channels: List[NotificationChannel]
    ):
        """
        Initialize order service.
        
        All dependencies are abstractions (interfaces), not concrete classes.
        This makes the service easy to test and extend.
        """
        self.repository = order_repository
        self.inventory_service = inventory_service
        self.default_payment_gateway = default_payment_gateway
        self.notification_channels = notification_channels
    
    def create_order(
        self,
        customer: Customer,
        pricing_strategy: Optional[PricingStrategy] = None,
        payment_gateway: Optional[PaymentGateway] = None
    ) -> Order:
        """
        Create new order.
        
        Args:
            customer: Customer placing order
            pricing_strategy: Optional custom pricing
            payment_gateway: Optional custom payment gateway
            
        Returns:
            New order instance
        """
        order_id = f"ORD-{uuid.uuid4().hex[:8].upper()}"
        
        # Use defaults if not provided
        pricing = pricing_strategy or StandardPricing()
        gateway = payment_gateway or self.default_payment_gateway
        
        order = Order(
            order_id=order_id,
            customer=customer,
            pricing_strategy=pricing,
            payment_gateway=gateway,
            inventory_service=self.inventory_service,
            notification_channels=self.notification_channels
        )
        
        self.repository.save(order)
        return order
    
    def get_order(self, order_id: str) -> Optional[Order]:
        """Get order by ID"""
        return self.repository.find_by_id(order_id)
    
    def get_customer_orders(self, customer_id: str) -> List[Order]:
        """Get all orders for customer"""
        if isinstance(self.repository, InMemoryOrderRepository):
            return self.repository.find_by_customer(customer_id)
        
        # Fallback
        all_orders = self.repository.find_all()
        return [
            order for order in all_orders
            if order.customer.customer_id == customer_id
        ]
    
    def place_order(
        self,
        order: Order,
        shipping_address: Address,
        payment_details: Dict
    ) -> tuple[bool, List[str]]:
        """
        Complete order placement workflow.
        
        Args:
            order: Order to place
            shipping_address: Shipping address
            payment_details: Payment details
            
        Returns:
            (success, errors)
        """
        errors = []
        
        # Set shipping address
        try:
            order.set_shipping_address(shipping_address)
        except ValueError as e:
            errors.append(str(e))
            return (False, errors)
        
        # Confirm order
        success, confirm_errors = order.confirm()
        if not success:
            errors.extend(confirm_errors)
            return (False, errors)
        
        # Process payment
        success, payment_errors = order.process_payment(payment_details)
        if not success:
            errors.extend(payment_errors)
            # Try to cancel order if payment fails
            order.cancel()
            return (False, errors)
        
        # Save updated order
        self.repository.save(order)
        
        return (True, [])

# ============================================================================
# DEMONSTRATION
# ============================================================================

def main():
    """Comprehensive demonstration of all OOP principles"""
    
    print("=" * 80)
    print("🛒 E-COMMERCE PLATFORM - PRODUCTION-READY IMPLEMENTATION")
    print("=" * 80)
    
    # Setup products
    print("\n📦 Setting up product catalog...")
    products = {
        'P001': Product(
            'P001',
            'Python Programming Book',
            Money(Decimal('49.99'), Currency.USD),
            'BOOK-PY-001',
            100,
            'Comprehensive Python guide'
        ),
        'P002': Product(
            'P002',
            'Wireless Keyboard',
            Money(Decimal('79.99'), Currency.USD),
            'KB-WL-002',
            50,
            'Mechanical wireless keyboard'
        ),
        'P003': Product(
            'P003',
            'USB-C Cable',
            Money(Decimal('12.99'), Currency.USD),
            'CABLE-USBC-003',
            200,
            '2m USB-C cable'
        ),
    }
    
    for product in products.values():
        print(f"   {product}")
    
    # Setup services
    print("\n⚙️  Initializing services...")
    inventory_service = SimpleInventoryService(products)
    order_repository = InMemoryOrderRepository()
    payment_gateway = StripePaymentGateway()
    notification_channels = [
        EmailNotification(),
        SMSNotification()
    ]
    
    order_service = OrderService(
        order_repository,
        inventory_service,
        payment_gateway,
        notification_channels
    )
    
    # Create customer
    print("\n👤 Creating customer...")
    customer = Customer(
        'C001',
        'john.doe@example.com',
        'John',
        'Doe',
        '+1-555-0123'
    )
    customer.add_loyalty_points(50)  # Some existing points
    print(f"   {customer}")
    print(f"   Loyalty Points: {customer.loyalty_points}")
    
    # Create shipping address
    shipping_address = Address(
        '123 Main Street',
        'San Francisco',
        'CA',
        '94102',
        'USA'
    )
    
    # Create order with bulk discount
    print("\n🛍️  Creating order with bulk discount...")
    bulk_pricing = BulkDiscountPricing(threshold=3, discount_percent=Decimal('10'))
    order = order_service.create_order(customer, pricing_strategy=bulk_pricing)
    
    # Add items
    print("\n➕ Adding items to order...")
    order.add_item(products['P001'], 2)
    order.add_item(products['P002'], 1)
    order.add_item(products['P003'], 3)
    
    for item in order.items:
        print(f"   {item}")
    
    print(f"\n💰 Pricing Strategy: {bulk_pricing.get_description()}")
    print(f"   Subtotal would be: USD {StandardPricing().calculate_price(order.items).amount}")
    print(f"   Order Total: {order.total}")
    print(f"   Savings: USD {(StandardPricing().calculate_price(order.items) - order.total).amount:.2f}")
    
    # Place order
    print("\n✅ Placing order...")
    payment_details = {
        'card_number': '4242424242424242',
        'cvv': '123',
        'expiry': '12/25'
    }
    
    success, errors = order_service.place_order(
        order,
        shipping_address,
        payment_details
    )
    
    if success:
        print("   ✅ Order placed successfully!")
        print(f"\n{order}")
    else:
        print(f"   ❌ Order failed: {errors}")
    
    # Ship order
    print("\n📦 Shipping order...")
    order.ship("TRACK123456789")
    
    # Deliver order
    print("\n🎉 Delivering order...")
    order.deliver()
    
    print(f"\n{order}")
    
    # Create another order with loyalty discount
    print("\n" + "=" * 80)
    print("🎁 DEMONSTRATING LOYALTY PRICING")
    print("=" * 80)
    
    print(f"\nCustomer loyalty points before: {customer.loyalty_points}")
    
    loyalty_pricing = LoyaltyDiscountPricing(customer, Decimal('0.10'))
    order2 = order_service.create_order(customer, pricing_strategy=loyalty_pricing)
    order2.add_item(products['P001'], 1)
    
    print(f"\n💰 Order total with loyalty discount: {order2.total}")
    print(f"   Regular price: {products['P001'].price}")
    print(f"   Discount: {loyalty_pricing.get_description()}")
    
    # Demonstrate property validation
    print("\n" + "=" * 80)
    print("🔒 DEMONSTRATING PROPERTY VALIDATION")
    print("=" * 80)
    
    try:
        print("\n✅ Valid email update...")
        customer.email = "newemail@example.com"
        print(f"   Email updated: {customer.email}")
    except ValueError as e:
        print(f"   ❌ {e}")
    
    try:
        print("\n❌ Invalid email update...")
        customer.email = "invalid-email"
    except ValueError as e:
        print(f"   ✅ Validation caught: {e}")
    
    try:
        print("\n❌ Negative price...")
        products['P001'].price = Money(Decimal('-10'), Currency.USD)
    except ValueError as e:
        print(f"   ✅ Validation caught: {e}")
    
    # Demonstrate Money value object
    print("\n" + "=" * 80)
    print("💵 DEMONSTRATING MONEY VALUE OBJECT")
    print("=" * 80)
    
    price1 = Money(Decimal('100.00'), Currency.USD)
    price2 = Money(Decimal('50.00'), Currency.USD)
    
    print(f"\nPrice 1: {price1}")
    print(f"Price 2: {price2}")
    print(f"Addition: {price1 + price2}")
    print(f"Subtraction: {price1 - price2}")
    print(f"Multiplication: {price1 * Decimal('1.5')}")
    print(f"Division: {price1 / Decimal('2')}")
    print(f"Comparison: {price1} > {price2} = {price1 > price2}")
    
    # Demonstrate LSP (Liskov Substitution)
    print("\n" + "=" * 80)
    print("🔄 DEMONSTRATING LISKOV SUBSTITUTION PRINCIPLE")
    print("=" * 80)
    
    # All payment gateways are interchangeable
    gateways = [
        StripePaymentGateway(),
        PayPalGateway()
    ]
    
    test_amount = Money(Decimal('99.99'), Currency.USD)
    
    for gateway in gateways:
        print(f"\nTesting {gateway.__class__.__name__}:")
        result = gateway.authorize(test_amount, payment_details)
        print(f"   Authorization: {result['success']}")
        capture = gateway.capture(result['authorization_id'])
        print(f"   Capture: {capture['success']}")
    
    # Final summary
    print("\n" + "=" * 80)
    print("✅ DEMONSTRATED OOP BEST PRACTICES:")
    print("=" * 80)
    print("✅ Composition: Order HAS-A pricing, payment, inventory, notifications")
    print("✅ SOLID Principles:")
    print("   S - Each class has single responsibility")
    print("   O - New pricing/payment strategies without modifying existing code")
    print("   L - All payment gateways/notifiers are interchangeable")
    print("   I - Focused interfaces (Repository, PaymentGateway, etc.)")
    print("   D - Services depend on abstractions, not concrete classes")
    print("✅ Properties: Validated access to price, stock, email, etc.")
    print("✅ ABC: Clear interfaces for all strategies and services")
    print("✅ Special Methods: __str__, __repr__, __add__, __eq__, etc.")
    print("✅ Type Hints: Complete type annotations throughout")
    print("✅ Documentation: Comprehensive docstrings for all classes/methods")
    print("✅ Encapsulation: Private attributes with controlled access")
    print("✅ Immutability: Money, Address value objects")
    print("=" * 80)

if __name__ == "__main__":
    main()
Key Takeaways
This production-ready example demonstrates:

1. Composition Over Inheritance
Python

# Order HAS-A pricing strategy, payment gateway, inventory service
class Order:
    def __init__(self, pricing_strategy, payment_gateway, inventory_service):
        self._pricing_strategy = pricing_strategy  # Composition
        self._payment_gateway = payment_gateway    # Composition
        self._inventory_service = inventory_service # Composition
2. SOLID Principles
S: Product, Customer, Order each have ONE responsibility
O: Add new PricingStrategy without changing Order
L: All PaymentGateway implementations are interchangeable
I: Separate interfaces (Repository, NotificationChannel)
D: OrderService depends on abstractions, not concrete classes
3. Properties
Python

@property
def total(self) -> Money:
    """Computed property using strategy"""
    return self._pricing_strategy.calculate_price(self._items)

@email.setter
def email(self, value: str):
    """Validated setter"""
    if not re.match(pattern, value):
        raise ValueError("Invalid email")
    self._email = value
4. Abstract Base Classes
Python

class PaymentGateway(ABC):
    @abstractmethod
    def authorize(self, amount: Money, details: Dict) -> Dict:
        pass
5. Special Methods
Python

class Money:
    def __add__(self, other: 'Money') -> 'Money':
        return Money(self.amount + other.amount, self.currency)
    
    def __str__(self) -> str:
        return f"{self.currency.value} {self.amount:.2f}"


Complete Guide: Python Documentation Best Practices
1. Docstring Styles & Conventions
Google Style (Recommended)
Python

def calculate_discount(
    price: float,
    discount_percent: float,
    customer_tier: str = "regular"
) -> float:
    """
    Calculate discounted price based on customer tier.
    
    This function applies a percentage discount to the base price and may
    apply additional tier-based bonuses for premium customers.
    
    Args:
        price: Original price before discount. Must be positive.
        discount_percent: Discount percentage (0-100). For example, 20 means 20% off.
        customer_tier: Customer membership tier. Options are:
            - 'regular': Standard discount only
            - 'premium': Additional 5% off
            - 'vip': Additional 10% off
            
    Returns:
        Final price after applying all discounts. Rounded to 2 decimal places.
        
    Raises:
        ValueError: If price is negative or discount_percent is not in range 0-100.
        TypeError: If customer_tier is not a string.
        
    Examples:
        >>> calculate_discount(100, 20)
        80.0
        
        >>> calculate_discount(100, 20, "premium")
        75.0
        
        >>> calculate_discount(100, 20, "vip")
        70.0
        
    Note:
        Tier-based discounts are applied after the percentage discount,
        not on the original price.
        
    See Also:
        apply_coupon_code(): For additional coupon-based discounts
        calculate_tax(): To add tax to the final price
    """
    if price < 0:
        raise ValueError(f"Price cannot be negative: {price}")
    
    if not 0 <= discount_percent <= 100:
        raise ValueError(f"Discount must be 0-100: {discount_percent}")
    
    if not isinstance(customer_tier, str):
        raise TypeError(f"customer_tier must be string, got {type(customer_tier)}")
    
    # Apply percentage discount
    discounted = price * (1 - discount_percent / 100)
    
    # Apply tier bonus
    tier_bonuses = {
        "regular": 0,
        "premium": 0.05,
        "vip": 0.10
    }
    
    tier_discount = tier_bonuses.get(customer_tier.lower(), 0)
    final_price = discounted * (1 - tier_discount)
    
    return round(final_price, 2)
NumPy Style (For Scientific Computing)
Python

def calculate_moving_average(
    data: List[float],
    window_size: int,
    center: bool = False
) -> List[float]:
    """
    Calculate moving average of a time series.
    
    Uses a sliding window approach to smooth data by averaging
    values within each window. Useful for noise reduction and
    trend identification.
    
    Parameters
    ----------
    data : List[float]
        Input time series data. Must contain at least `window_size` elements.
    window_size : int
        Number of data points in each averaging window. Must be odd if center=True.
    center : bool, optional
        If True, labels are centered in the window (default is False).
        When False, labels are at the right edge of the window.
        
    Returns
    -------
    List[float]
        Smoothed data with same length as input.
        Edge values are handled by reducing window size.
        
    Raises
    ------
    ValueError
        If window_size is larger than data length.
        If window_size is even when center=True.
    TypeError
        If data contains non-numeric values.
        
    Examples
    --------
    >>> data = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
    >>> calculate_moving_average(data, 3)
    [1.0, 1.5, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0]
    
    >>> calculate_moving_average(data, 3, center=True)
    [1.5, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 9.5]
    
    Notes
    -----
    The moving average is calculated using the formula:
    
    .. math:: MA_t = \\frac{1}{n} \\sum_{i=0}^{n-1} x_{t-i}
    
    where n is the window size and x is the data point.
    
    See Also
    --------
    calculate_exponential_moving_average : Weighted moving average
    smooth_data : General purpose smoothing function
    
    References
    ----------
    .. [1] Box, G. E. P., Jenkins, G. M., & Reinsel, G. C. (2015).
           Time Series Analysis: Forecasting and Control.
    """
    if len(data) < window_size:
        raise ValueError(
            f"Data length ({len(data)}) must be >= window_size ({window_size})"
        )
    
    if center and window_size % 2 == 0:
        raise ValueError("window_size must be odd when center=True")
    
    result = []
    # Implementation here...
    return result
2. Class Documentation
Complete Class Documentation
Python

from abc import ABC, abstractmethod
from typing import List, Dict, Optional, Union
from datetime import datetime
from decimal import Decimal

class BankAccount:
    """
    Represents a bank account with transaction management.
    
    This class provides a complete interface for managing a bank account,
    including deposits, withdrawals, transfers, and transaction history.
    It enforces business rules like minimum balance and transaction limits.
    
    The account uses Decimal for precise monetary calculations to avoid
    floating-point arithmetic issues.
    
    Attributes:
        account_number (str): Unique account identifier (read-only).
        account_holder (str): Name of account holder.
        balance (Decimal): Current account balance (read-only).
        account_type (str): Type of account ('checking' or 'savings').
        is_active (bool): Whether account is active (read-only).
        created_at (datetime): Account creation timestamp (read-only).
        transactions (List[Dict]): Transaction history (read-only copy).
        
    Class Attributes:
        MIN_BALANCE (Decimal): Minimum required balance.
        DAILY_WITHDRAWAL_LIMIT (Decimal): Maximum daily withdrawal amount.
        TRANSACTION_FEE (Decimal): Fee per transaction.
        
    Examples:
        Create a new account:
        
        >>> account = BankAccount("ACC001", "John Doe", initial_balance=1000)
        >>> print(account.balance)
        Decimal('1000.00')
        
        Make deposits and withdrawals:
        
        >>> account.deposit(500, "Salary")
        True
        >>> account.withdraw(200, "Groceries")
        True
        >>> print(account.balance)
        Decimal('1300.00')
        
        Transfer between accounts:
        
        >>> account2 = BankAccount("ACC002", "Jane Doe", initial_balance=500)
        >>> account.transfer(account2, 100)
        True
        >>> print(account2.balance)
        Decimal('600.00')
        
    Note:
        All monetary amounts are handled using Decimal to ensure precision.
        Transaction fees are automatically deducted for certain operations.
        
    See Also:
        SavingsAccount: Subclass with interest calculations
        CheckingAccount: Subclass with overdraft protection
        
    Warning:
        Accounts with balance below MIN_BALANCE may be subject to fees.
        Exceeding DAILY_WITHDRAWAL_LIMIT will raise an exception.
    """
    
    # Class attributes with documentation
    MIN_BALANCE: Decimal = Decimal('100.00')
    """Minimum balance required to avoid fees."""
    
    DAILY_WITHDRAWAL_LIMIT: Decimal = Decimal('5000.00')
    """Maximum amount that can be withdrawn in a single day."""
    
    TRANSACTION_FEE: Decimal = Decimal('1.50')
    """Fee charged per transaction."""
    
    def __init__(
        self,
        account_number: str,
        account_holder: str,
        initial_balance: Union[Decimal, float] = 0,
        account_type: str = "checking"
    ):
        """
        Initialize a new bank account.
        
        Creates a new account with the specified parameters and initializes
        the transaction history. Validates all input parameters.
        
        Args:
            account_number: Unique identifier for the account. Must be
                alphanumeric and 6-12 characters long.
            account_holder: Full name of the account holder. Must be at
                least 2 characters.
            initial_balance: Starting balance for the account. Must be
                non-negative. Defaults to 0.
            account_type: Type of account. Must be either 'checking' or
                'savings'. Defaults to 'checking'.
                
        Raises:
            ValueError: If account_number format is invalid, account_holder
                is too short, initial_balance is negative, or account_type
                is not recognized.
            TypeError: If parameters are of incorrect type.
            
        Examples:
            >>> account = BankAccount("ACC001", "John Doe")
            >>> account = BankAccount("ACC002", "Jane Doe", 1000, "savings")
            
        Note:
            Initial balance is recorded as the first transaction with
            description "Initial deposit".
        """
        # Validation
        if not isinstance(account_number, str) or not (6 <= len(account_number) <= 12):
            raise ValueError(
                f"Account number must be 6-12 characters: {account_number}"
            )
        
        if not isinstance(account_holder, str) or len(account_holder.strip()) < 2:
            raise ValueError(
                f"Account holder name too short: {account_holder}"
            )
        
        if not isinstance(initial_balance, (Decimal, int, float)):
            raise TypeError(
                f"initial_balance must be numeric, got {type(initial_balance)}"
            )
        
        balance_decimal = Decimal(str(initial_balance))
        if balance_decimal < 0:
            raise ValueError(
                f"Initial balance cannot be negative: {initial_balance}"
            )
        
        if account_type not in ["checking", "savings"]:
            raise ValueError(
                f"account_type must be 'checking' or 'savings': {account_type}"
            )
        
        # Initialize attributes
        self._account_number = account_number
        self._account_holder = account_holder.strip()
        self._balance = balance_decimal
        self._account_type = account_type
        self._is_active = True
        self._created_at = datetime.now()
        self._transactions: List[Dict] = []
        self._daily_withdrawals = Decimal('0')
        self._last_withdrawal_date = datetime.now().date()
        
        # Record initial deposit if non-zero
        if balance_decimal > 0:
            self._record_transaction(
                "deposit",
                balance_decimal,
                "Initial deposit"
            )
    
    @property
    def account_number(self) -> str:
        """
        Get the account number.
        
        Returns:
            Unique account identifier (read-only).
            
        Examples:
            >>> account = BankAccount("ACC001", "John Doe")
            >>> print(account.account_number)
            'ACC001'
        """
        return self._account_number
    
    @property
    def balance(self) -> Decimal:
        """
        Get the current account balance.
        
        Returns:
            Current balance as Decimal (read-only).
            
        Examples:
            >>> account = BankAccount("ACC001", "John Doe", 1000)
            >>> print(account.balance)
            Decimal('1000.00')
            
        Note:
            Balance can only be modified through deposit(), withdraw(),
            and transfer() methods.
        """
        return self._balance
    
    @property
    def account_holder(self) -> str:
        """
        Get or set the account holder name.
        
        Returns:
            Account holder's full name.
            
        Raises:
            ValueError: When setting, if name is too short.
            
        Examples:
            >>> account = BankAccount("ACC001", "John Doe")
            >>> print(account.account_holder)
            'John Doe'
            >>> account.account_holder = "John Smith"
        """
        return self._account_holder
    
    @account_holder.setter
    def account_holder(self, value: str):
        """Set account holder with validation."""
        if not isinstance(value, str) or len(value.strip()) < 2:
            raise ValueError(f"Account holder name too short: {value}")
        self._account_holder = value.strip()
    
    @property
    def transactions(self) -> List[Dict]:
        """
        Get transaction history.
        
        Returns:
            Copy of transaction history list. Each transaction is a dict with:
                - type (str): 'deposit', 'withdrawal', or 'transfer'
                - amount (Decimal): Transaction amount
                - description (str): Transaction description
                - timestamp (datetime): When transaction occurred
                - balance_after (Decimal): Balance after transaction
                
        Examples:
            >>> account = BankAccount("ACC001", "John Doe", 1000)
            >>> account.deposit(500, "Salary")
            True
            >>> for txn in account.transactions:
            ...     print(f"{txn['type']}: {txn['amount']}")
            deposit: 1000.00
            deposit: 500.00
            
        Note:
            Returns a copy to prevent external modification of history.
        """
        return self._transactions.copy()
    
    def deposit(
        self,
        amount: Union[Decimal, float],
        description: str = ""
    ) -> bool:
        """
        Deposit money into the account.
        
        Adds the specified amount to the account balance and records
        the transaction in history. A transaction fee may be applied.
        
        Args:
            amount: Amount to deposit. Must be positive.
            description: Optional description of the deposit.
                Defaults to "Deposit".
                
        Returns:
            True if deposit was successful.
            
        Raises:
            ValueError: If amount is not positive or account is inactive.
            TypeError: If amount is not numeric.
            
        Examples:
            >>> account = BankAccount("ACC001", "John Doe", 1000)
            >>> account.deposit(500)
            True
            >>> account.deposit(250, "Birthday gift")
            True
            >>> print(account.balance)
            Decimal('1750.00')
            
        Note:
            Transaction fee is NOT applied to deposits.
            
        See Also:
            withdraw(): For withdrawing money
            transfer(): For transferring to another account
        """
        if not self._is_active:
            raise ValueError("Cannot deposit to inactive account")
        
        if not isinstance(amount, (Decimal, int, float)):
            raise TypeError(f"Amount must be numeric, got {type(amount)}")
        
        amount_decimal = Decimal(str(amount))
        
        if amount_decimal <= 0:
            raise ValueError(f"Deposit amount must be positive: {amount}")
        
        self._balance += amount_decimal
        self._record_transaction(
            "deposit",
            amount_decimal,
            description or "Deposit"
        )
        
        return True
    
    def withdraw(
        self,
        amount: Union[Decimal, float],
        description: str = ""
    ) -> bool:
        """
        Withdraw money from the account.
        
        Subtracts the specified amount from the account balance, applies
        transaction fee, and enforces daily withdrawal limits.
        
        Args:
            amount: Amount to withdraw. Must be positive and not exceed
                available balance or daily limit.
            description: Optional description of the withdrawal.
                Defaults to "Withdrawal".
                
        Returns:
            True if withdrawal was successful.
            
        Raises:
            ValueError: If amount is invalid, insufficient funds,
                daily limit exceeded, or account is inactive.
            TypeError: If amount is not numeric.
            
        Examples:
            >>> account = BankAccount("ACC001", "John Doe", 1000)
            >>> account.withdraw(200)
            True
            >>> account.withdraw(100, "ATM withdrawal")
            True
            >>> print(account.balance)
            Decimal('697.00')  # After transaction fees
            
        Note:
            - Transaction fee is automatically deducted
            - Daily withdrawal limit is enforced
            - Minimum balance requirement is checked
            
        Warning:
            Withdrawing below MIN_BALANCE may trigger additional fees.
            
        See Also:
            deposit(): For depositing money
            get_daily_withdrawal_remaining(): Check remaining daily limit
        """
        if not self._is_active:
            raise ValueError("Cannot withdraw from inactive account")
        
        if not isinstance(amount, (Decimal, int, float)):
            raise TypeError(f"Amount must be numeric, got {type(amount)}")
        
        amount_decimal = Decimal(str(amount))
        
        if amount_decimal <= 0:
            raise ValueError(f"Withdrawal amount must be positive: {amount}")
        
        # Check daily limit
        self._reset_daily_limit_if_needed()
        
        if self._daily_withdrawals + amount_decimal > self.DAILY_WITHDRAWAL_LIMIT:
            remaining = self.DAILY_WITHDRAWAL_LIMIT - self._daily_withdrawals
            raise ValueError(
                f"Daily withdrawal limit exceeded. "
                f"Remaining today: {remaining}"
            )
        
        # Calculate total deduction (amount + fee)
        total_deduction = amount_decimal + self.TRANSACTION_FEE
        
        if self._balance < total_deduction:
            raise ValueError(
                f"Insufficient funds. "
                f"Need {total_deduction} (includes {self.TRANSACTION_FEE} fee), "
                f"have {self._balance}"
            )
        
        # Process withdrawal
        self._balance -= total_deduction
        self._daily_withdrawals += amount_decimal
        
        self._record_transaction(
            "withdrawal",
            amount_decimal,
            description or "Withdrawal"
        )
        
        return True
    
    def transfer(
        self,
        to_account: 'BankAccount',
        amount: Union[Decimal, float],
        description: str = ""
    ) -> bool:
        """
        Transfer money to another account.
        
        Withdraws from this account and deposits to the target account
        in a single atomic operation. If any step fails, the entire
        transfer is rolled back.
        
        Args:
            to_account: Destination BankAccount instance.
            amount: Amount to transfer. Must be positive.
            description: Optional description. Defaults to "Transfer to [account]".
                
        Returns:
            True if transfer was successful.
            
        Raises:
            ValueError: If amount is invalid, insufficient funds,
                or either account is inactive.
            TypeError: If to_account is not a BankAccount instance.
            
        Examples:
            >>> account1 = BankAccount("ACC001", "John Doe", 1000)
            >>> account2 = BankAccount("ACC002", "Jane Doe", 500)
            >>> account1.transfer(account2, 200)
            True
            >>> print(account1.balance)
            Decimal('798.50')  # After fee
            >>> print(account2.balance)
            Decimal('700.00')
            
        Note:
            - Transaction fee is charged to the sender
            - Transfer counts toward daily withdrawal limit
            - Both accounts must be active
            
        See Also:
            withdraw(): Underlying withdrawal mechanism
            deposit(): Underlying deposit mechanism
        """
        if not isinstance(to_account, BankAccount):
            raise TypeError(
                f"to_account must be BankAccount, got {type(to_account)}"
            )
        
        if not to_account._is_active:
            raise ValueError("Cannot transfer to inactive account")
        
        desc = description or f"Transfer to {to_account.account_number}"
        
        # Withdraw from this account (includes validation)
        self.withdraw(amount, desc)
        
        try:
            # Deposit to target account
            to_account.deposit(
                amount,
                f"Transfer from {self.account_number}"
            )
        except Exception as e:
            # Rollback if deposit fails
            self.deposit(amount, f"Rollback: {desc}")
            raise ValueError(f"Transfer failed: {e}")
        
        return True
    
    def get_transaction_summary(
        self,
        start_date: Optional[datetime] = None,
        end_date: Optional[datetime] = None
    ) -> Dict[str, Decimal]:
        """
        Get summary of transactions in date range.
        
        Calculates total deposits, withdrawals, and net change for
        the specified date range.
        
        Args:
            start_date: Start of date range (inclusive).
                If None, includes all transactions from account creation.
            end_date: End of date range (inclusive).
                If None, includes all transactions up to now.
                
        Returns:
            Dictionary containing:
                - total_deposits (Decimal): Sum of all deposits
                - total_withdrawals (Decimal): Sum of all withdrawals
                - net_change (Decimal): Difference (deposits - withdrawals)
                - transaction_count (int): Number of transactions
                
        Examples:
            >>> account = BankAccount("ACC001", "John Doe", 1000)
            >>> account.deposit(500)
            True
            >>> account.withdraw(200)
            True
            >>> summary = account.get_transaction_summary()
            >>> print(summary['total_deposits'])
            Decimal('1500.00')
            >>> print(summary['total_withdrawals'])
            Decimal('200.00')
            >>> print(summary['net_change'])
            Decimal('1300.00')
            
        Note:
            Withdrawals include transaction fees in the balance calculation
            but the summary shows only the actual withdrawal amounts.
        """
        filtered_txns = self._transactions
        
        if start_date:
            filtered_txns = [
                t for t in filtered_txns
                if t['timestamp'] >= start_date
            ]
        
        if end_date:
            filtered_txns = [
                t for t in filtered_txns
                if t['timestamp'] <= end_date
            ]
        
        deposits = sum(
            t['amount'] for t in filtered_txns
            if t['type'] == 'deposit'
        )
        
        withdrawals = sum(
            t['amount'] for t in filtered_txns
            if t['type'] == 'withdrawal'
        )
        
        return {
            'total_deposits': deposits,
            'total_withdrawals': withdrawals,
            'net_change': deposits - withdrawals,
            'transaction_count': len(filtered_txns)
        }
    
    def close_account(self) -> Decimal:
        """
        Close the account and return remaining balance.
        
        Deactivates the account and returns the final balance.
        No further transactions can be performed after closing.
        
        Returns:
            Final account balance before closing.
            
        Raises:
            ValueError: If account is already closed.
            
        Examples:
            >>> account = BankAccount("ACC001", "John Doe", 1000)
            >>> final_balance = account.close_account()
            >>> print(final_balance)
            Decimal('1000.00')
            >>> account.deposit(100)  # Raises ValueError
            
        Warning:
            This operation cannot be undone. All transaction history
            is preserved but the account cannot be reactivated.
            
        Note:
            Any balance below MIN_BALANCE is waived during closure.
        """
        if not self._is_active:
            raise ValueError("Account is already closed")
        
        final_balance = self._balance
        self._is_active = False
        self._balance = Decimal('0')
        
        self._record_transaction(
            "closure",
            final_balance,
            "Account closed"
        )
        
        return final_balance
    
    def _record_transaction(
        self,
        txn_type: str,
        amount: Decimal,
        description: str
    ):
        """
        Record a transaction in history (private method).
        
        This is an internal method not meant to be called directly.
        It's used by deposit(), withdraw(), and transfer() to maintain
        transaction history.
        
        Args:
            txn_type: Type of transaction ('deposit', 'withdrawal', etc.)
            amount: Transaction amount
            description: Human-readable description
            
        Note:
            This method doesn't validate inputs as it's only called
            by methods that have already performed validation.
        """
        self._transactions.append({
            'type': txn_type,
            'amount': amount,
            'description': description,
            'timestamp': datetime.now(),
            'balance_after': self._balance
        })
    
    def _reset_daily_limit_if_needed(self):
        """
        Reset daily withdrawal counter if new day (private method).
        
        Checks if the current date is different from the last withdrawal
        date and resets the daily withdrawal counter if needed.
        """
        today = datetime.now().date()
        if today != self._last_withdrawal_date:
            self._daily_withdrawals = Decimal('0')
            self._last_withdrawal_date = today
    
    def __str__(self) -> str:
        """
        Return user-friendly string representation.
        
        Returns:
            String showing account number, holder, and balance.
            
        Examples:
            >>> account = BankAccount("ACC001", "John Doe", 1000)
            >>> print(account)
            Account ACC001 - John Doe: $1000.00
        """
        status = "Active" if self._is_active else "Closed"
        return (
            f"Account {self._account_number} - {self._account_holder}: "
            f"${self._balance} ({status})"
        )
    
    def __repr__(self) -> str:
        """
        Return developer-friendly string representation.
        
        Returns:
            String that could recreate the object (approximately).
            
        Examples:
            >>> account = BankAccount("ACC001", "John Doe", 1000)
            >>> repr(account)
            "BankAccount('ACC001', 'John Doe', balance=Decimal('1000.00'))"
        """
        return (
            f"BankAccount('{self._account_number}', '{self._account_holder}', "
            f"balance={self._balance!r})"
        )
    
    def __eq__(self, other) -> bool:
        """
        Check equality based on account number.
        
        Two accounts are considered equal if they have the same account number.
        
        Args:
            other: Another object to compare with.
            
        Returns:
            True if account numbers match, False otherwise.
            
        Examples:
            >>> account1 = BankAccount("ACC001", "John Doe", 1000)
            >>> account2 = BankAccount("ACC001", "Jane Doe", 500)
            >>> account1 == account2
            True
        """
        if not isinstance(other, BankAccount):
            return False
        return self._account_number == other._account_number
3. Module-Level Documentation
Python

"""
Bank account management system.

This module provides classes and utilities for managing bank accounts,
including deposits, withdrawals, transfers, and transaction tracking.

The module uses Decimal arithmetic for precise monetary calculations
and implements proper validation and error handling throughout.

Classes:
    BankAccount: Main account class with transaction management
    SavingsAccount: Account subclass with interest calculations
    CheckingAccount: Account subclass with overdraft protection
    Transaction: Represents a single transaction
    AccountManager: Manages multiple accounts
    
Functions:
    calculate_interest: Calculate compound interest
    format_currency: Format amount as currency string
    validate_account_number: Validate account number format
    
Constants:
    MIN_BALANCE: Minimum required balance
    TRANSACTION_FEE: Fee per transaction
    INTEREST_RATE: Default interest rate for savings
    
Examples:
    Basic account usage:
    
    >>> from banking import BankAccount
    >>> account = BankAccount("ACC001", "John Doe", 1000)
    >>> account.deposit(500)
    True
    >>> account.withdraw(200)
    True
    >>> print(account.balance)
    Decimal('1298.50')
    
    Using account manager:
    
    >>> from banking import AccountManager
    >>> manager = AccountManager()
    >>> account = manager.create_account("John Doe", initial_balance=1000)
    >>> manager.transfer("ACC001", "ACC002", 500)
    
Notes:
    - All monetary values use Decimal for precision
    - Thread-safety is NOT guaranteed (use locks if needed)
    - Accounts are automatically saved to database
    
See Also:
    transactions: Module for transaction history analysis
    reporting: Module for account reports and statements
    
Author:
    John Developer <john@example.com>
    
Version:
    1.2.0
    
License:
    MIT License
"""

__version__ = "1.2.0"
__author__ = "John Developer"
__all__ = [
    "BankAccount",
    "SavingsAccount", 
    "CheckingAccount",
    "AccountManager",
    "calculate_interest",
    "format_currency"
]

from decimal import Decimal
from typing import List, Dict, Optional
from datetime import datetime

# Module constants
MIN_BALANCE: Decimal = Decimal('100.00')
"""Minimum balance required to avoid fees."""

TRANSACTION_FEE: Decimal = Decimal('1.50')
"""Fee charged per transaction."""

INTEREST_RATE: Decimal = Decimal('0.02')
"""Default annual interest rate (2%)."""

# Rest of module code...
4. Type Hints & Advanced Annotations
Python

from typing import (
    List, Dict, Set, Tuple, Optional, Union, Any,
    Callable, TypeVar, Generic, Protocol, Literal,
    overload, Final
)
from collections.abc import Iterable, Sequence
from decimal import Decimal
from datetime import datetime

# Type variables
T = TypeVar('T')
K = TypeVar('K')
V = TypeVar('V')

# Literal types for specific values
AccountType = Literal["checking", "savings", "investment"]
TransactionType = Literal["deposit", "withdrawal", "transfer"]

class Repository(Protocol[T]):
    """
    Protocol defining repository interface.
    
    This is a structural type (duck typing) that any class
    with matching methods can satisfy.
    
    Type Parameters:
        T: Type of entity stored in repository
        
    Examples:
        >>> class UserRepository:
        ...     def save(self, entity: User) -> bool: ...
        ...     def find(self, id: str) -> Optional[User]: ...
        >>> 
        >>> # UserRepository satisfies Repository[User] protocol
        >>> def process_repo(repo: Repository[User]): ...
    """
    
    def save(self, entity: T) -> bool:
        """Save entity to repository."""
        ...
    
    def find(self, id: str) -> Optional[T]:
        """Find entity by ID."""
        ...
    
    def find_all(self) -> List[T]:
        """Find all entities."""
        ...

def process_transactions(
    transactions: Sequence[Dict[str, Union[str, Decimal, datetime]]],
    *,
    filter_type: Optional[TransactionType] = None,
    min_amount: Decimal = Decimal('0'),
    callback: Optional[Callable[[Dict], None]] = None
) -> Tuple[Decimal, int]:
    """
    Process a sequence of transactions.
    
    Args:
        transactions: Sequence of transaction dictionaries. Each dict must contain:
            - 'type': TransactionType
            - 'amount': Decimal
            - 'timestamp': datetime
            - 'description': str
        filter_type: Optional filter by transaction type. If None, processes all.
        min_amount: Only process transactions >= this amount. Defaults to 0.
        callback: Optional function called for each processed transaction.
            
    Returns:
        Tuple of:
            - Total amount processed (Decimal)
            - Number of transactions processed (int)
            
    Examples:
        >>> txns = [
        ...     {'type': 'deposit', 'amount': Decimal('100'), ...},
        ...     {'type': 'withdrawal', 'amount': Decimal('50'), ...}
        ... ]
        >>> total, count = process_transactions(txns, filter_type='deposit')
        >>> print(f"Processed {count} deposits totaling {total}")
        Processed 1 deposits totaling 100
        
    Type Hints Explained:
        - Sequence[Dict[...]]: Accepts any sequence (list, tuple) of dicts
        - Union[str, Decimal, datetime]: Dict values can be any of these types
        - Optional[TransactionType]: Can be TransactionType or None
        - Callable[[Dict], None]: Function taking Dict, returning None
        - Tuple[Decimal, int]: Return exactly 2 elements of these types
    """
    total = Decimal('0')
    count = 0
    
    for txn in transactions:
        if filter_type and txn['type'] != filter_type:
            continue
            
        amount = txn['amount']
        if not isinstance(amount, Decimal):
            continue
            
        if amount < min_amount:
            continue
        
        total += amount
        count += 1
        
        if callback:
            callback(txn)
    
    return total, count

# Generic class with type parameter
class Cache(Generic[K, V]):
    """
    Generic cache implementation.
    
    Type Parameters:
        K: Type of cache keys
        V: Type of cache values
        
    Examples:
        >>> # Cache with string keys, int values
        >>> int_cache: Cache[str, int] = Cache()
        >>> int_cache.set("count", 42)
        >>> 
        >>> # Cache with int keys, BankAccount values
        >>> account_cache: Cache[int, BankAccount] = Cache()
        >>> account_cache.set(1, account)
    """
    
    def __init__(self):
        self._data: Dict[K, V] = {}
    
    def set(self, key: K, value: V) -> None:
        """
        Store value in cache.
        
        Args:
            key: Cache key of type K
            value: Cache value of type V
        """
        self._data[key] = value
    
    def get(self, key: K) -> Optional[V]:
        """
        Retrieve value from cache.
        
        Args:
            key: Cache key of type K
            
        Returns:
            Cached value of type V, or None if not found
        """
        return self._data.get(key)

# Function overloading with @overload
@overload
def calculate_fee(
    amount: Decimal,
    fee_type: Literal["percentage"]
) -> Decimal: ...

@overload
def calculate_fee(
    amount: Decimal,
    fee_type: Literal["fixed"]
) -> Decimal: ...

def calculate_fee(
    amount: Decimal,
    fee_type: Literal["percentage", "fixed"],
    rate: Decimal = Decimal('0.01')
) -> Decimal:
    """
    Calculate transaction fee.
    
    This function has different behavior based on fee_type, indicated
    by overload signatures for better type checking.
    
    Args:
        amount: Transaction amount
        fee_type: Type of fee calculation:
            - "percentage": Fee is percentage of amount
            - "fixed": Fee is fixed rate regardless of amount
        rate: Fee rate (percentage or fixed amount). Defaults to 1%.
        
    Returns:
        Calculated fee amount
        
    Examples:
        >>> calculate_fee(Decimal('100'), "percentage", Decimal('0.05'))
        Decimal('5.00')
        >>> calculate_fee(Decimal('100'), "fixed", Decimal('2.50'))
        Decimal('2.50')
        
    Note:
        The @overload decorators help type checkers understand the
        relationship between fee_type and the expected behavior.
    """
    if fee_type == "percentage":
        return amount * rate
    else:
        return rate

# Final class (cannot be subclassed)
class Currency(Final):
    """
    Immutable currency value object.
    
    This class is marked Final and cannot be subclassed.
    
    Attributes:
        code: ISO currency code (Final, cannot be changed)
        symbol: Currency symbol (Final, cannot be changed)
    """
    
    code: Final[str]
    symbol: Final[str]
    
    def __init__(self, code: str, symbol: str):
        """
        Initialize currency.
        
        Args:
            code: ISO 4217 currency code (e.g., 'USD')
            symbol: Currency symbol (e.g., '$')
        """
        object.__setattr__(self, 'code', code)
        object.__setattr__(self, 'symbol', symbol)
    
    def __setattr__(self, name: str, value: Any) -> None:
        """Prevent attribute modification."""
        raise AttributeError("Currency is immutable")
5. Real-World Complete Example
Python

"""
E-commerce order processing system.

This module demonstrates comprehensive documentation practices for a
production-ready order processing system.
"""

from abc import ABC, abstractmethod
from typing import List, Dict, Optional, Union, Literal, Protocol
from decimal import Decimal
from datetime import datetime, timedelta
from enum import Enum
import logging

# Configure logging
logger = logging.getLogger(__name__)

class OrderStatus(Enum):
    """
    Enumeration of possible order statuses.
    
    Attributes:
        PENDING: Order created but not confirmed
        CONFIRMED: Order confirmed and payment pending
        PAID: Payment received
        PROCESSING: Order being prepared
        SHIPPED: Order dispatched
        DELIVERED: Order delivered to customer
        CANCELLED: Order cancelled
        REFUNDED: Payment refunded
    """
    PENDING = "pending"
    CONFIRMED = "confirmed"
    PAID = "paid"
    PROCESSING = "processing"
    SHIPPED = "shipped"
    DELIVERED = "delivered"
    CANCELLED = "cancelled"
    REFUNDED = "refunded"

class PaymentMethod(Protocol):
    """
    Protocol defining payment method interface.
    
    Any class implementing these methods can be used as a payment method.
    
    Examples:
        >>> class CreditCard:
        ...     def process_payment(self, amount: Decimal) -> bool:
        ...         # Process credit card payment
        ...         return True
        ...     
        ...     def get_type(self) -> str:
        ...         return "credit_card"
        >>> 
        >>> # CreditCard satisfies PaymentMethod protocol
        >>> def charge(method: PaymentMethod, amount: Decimal):
        ...     return method.process_payment(amount)
    """
    
    def process_payment(self, amount: Decimal) -> bool:
        """
        Process payment for given amount.
        
        Args:
            amount: Amount to charge
            
        Returns:
            True if payment successful, False otherwise
        """
        ...
    
    def get_type(self) -> str:
        """Get payment method type identifier."""
        ...

class OrderService:
    """
    Service for managing customer orders.
    
    This service coordinates the order lifecycle from creation through
    delivery, handling payment processing, inventory management, and
    customer notifications.
    
    The service follows the SOLID principles and uses dependency injection
    for all external services (payment, inventory, notifications).
    
    Attributes:
        payment_processor: Service for processing payments
        inventory_manager: Service for managing inventory
        notification_service: Service for sending notifications
        
    Examples:
        Basic order workflow:
        
        >>> from decimal import Decimal
        >>> # Setup services
        >>> payment = CreditCardProcessor()
        >>> inventory = InventoryManager()
        >>> notifications = EmailNotificationService()
        >>> 
        >>> # Create service
        >>> service = OrderService(payment, inventory, notifications)
        >>> 
        >>> # Create and process order
        >>> order = service.create_order(
        ...     customer_id="C001",
        ...     items=[{"product_id": "P001", "quantity": 2}]
        ... )
        >>> service.confirm_order(order.id)
        >>> service.process_payment(order.id, payment_method)
        >>> service.ship_order(order.id, tracking_number="TRACK123")
        
        Handling errors:
        
        >>> try:
        ...     service.process_payment(order.id, payment_method)
        ... except InsufficientInventoryError as e:
        ...     logger.error(f"Cannot fulfill order: {e}")
        ... except PaymentFailedError as e:
        ...     logger.error(f"Payment failed: {e}")
        ...     service.cancel_order(order.id)
        
    Thread Safety:
        This class is NOT thread-safe. If using in multi-threaded
        environment, wrap calls in locks or use one instance per thread.
        
    See Also:
        Order: Order entity class
        PaymentProcessor: Payment processing interface
        InventoryManager: Inventory management service
        
    Note:
        All monetary amounts are handled using Decimal to avoid
        floating-point precision issues.
        
    Warning:
        Do not modify order status directly. Always use the service
        methods to ensure proper state transitions and side effects.
    """
    
    def __init__(
        self,
        payment_processor: 'PaymentProcessor',
        inventory_manager: 'InventoryManager',
        notification_service: 'NotificationService'
    ):
        """
        Initialize order service with dependencies.
        
        Args:
            payment_processor: Service for processing payments.
                Must implement PaymentProcessor interface.
            inventory_manager: Service for managing inventory.
                Must implement InventoryManager interface.
            notification_service: Service for sending notifications.
                Must implement NotificationService interface.
                
        Examples:
            >>> payment = StripePaymentProcessor(api_key="sk_test_...")
            >>> inventory = DatabaseInventoryManager(db_connection)
            >>> notifications = SendGridNotificationService(api_key="...")
            >>> service = OrderService(payment, inventory, notifications)
        """
        self._payment_processor = payment_processor
        self._inventory_manager = inventory_manager
        self._notification_service = notification_service
        self._orders: Dict[str, 'Order'] = {}
        
        logger.info("OrderService initialized")
    
    def create_order(
        self,
        customer_id: str,
        items: List[Dict[str, Union[str, int]]],
        *,
        shipping_address: Optional[Dict[str, str]] = None,
        notes: str = ""
    ) -> 'Order':
        """
        Create a new order.
        
        Creates an order in PENDING status with the specified items.
        Does not reserve inventory or process payment yet.
        
        Args:
            customer_id: Unique customer identifier. Must be valid customer ID.
            items: List of items to order. Each item dict must contain:
                - product_id (str): Product identifier
                - quantity (int): Quantity to order (must be positive)
            shipping_address: Optional shipping address dict with keys:
                - street, city, state, postal_code, country
                If None, uses customer's default address.
            notes: Optional order notes or special instructions.
                
        Returns:
            Newly created Order instance in PENDING status.
            
        Raises:
            ValueError: If customer_id is invalid, items list is empty,
                or any item has invalid format.
            InvalidProductError: If any product_id doesn't exist.
            
        Examples:
            Create simple order:
            
            >>> order = service.create_order(
            ...     customer_id="C001",
            ...     items=[
            ...         {"product_id": "P001", "quantity": 2},
            ...         {"product_id": "P002", "quantity": 1}
            ...     ]
            ... )
            >>> print(order.status)
            OrderStatus.PENDING
            
            Create order with shipping address:
            
            >>> address = {
            ...     "street": "123 Main St",
            ...     "city": "San Francisco",
            ...     "state": "CA",
            ...     "postal_code": "94102",
            ...     "country": "USA"
            ... }
            >>> order = service.create_order(
            ...     customer_id="C001",
            ...     items=[{"product_id": "P001", "quantity": 1}],
            ...     shipping_address=address,
            ...     notes="Please ring doorbell"
            ... )
            
        Note:
            - Order ID is auto-generated using UUID
            - Order total is calculated based on current product prices
            - No inventory is reserved until order is confirmed
            - Customer is notified of order creation
            
        See Also:
            confirm_order(): To confirm and reserve inventory
            cancel_order(): To cancel pending order
        """
        # Validation
        if not customer_id:
            raise ValueError("customer_id is required")
        
        if not items:
            raise ValueError("items list cannot be empty")
        
        # Validate items format
        for item in items:
            if "product_id" not in item or "quantity" not in item:
                raise ValueError(
                    "Each item must have 'product_id' and 'quantity'"
                )
            if not isinstance(item["quantity"], int) or item["quantity"] <= 0:
                raise ValueError(
                    f"Quantity must be positive integer: {item['quantity']}"
                )
        
        # Create order (implementation details...)
        order = Order(
            customer_id=customer_id,
            items=items,
            shipping_address=shipping_address,
            notes=notes
        )
        
        self._orders[order.id] = order
        
        # Send notification
        self._notification_service.send_order_created(order)
        
        logger.info(f"Created order {order.id} for customer {customer_id}")
        
        return order
    
    def confirm_order(self, order_id: str) -> bool:
        """
        Confirm order and reserve inventory.
        
        Transitions order from PENDING to CONFIRMED status and reserves
        the required inventory. If inventory is insufficient, order
        remains PENDING and exception is raised.
        
        Args:
            order_id: Unique order identifier.
            
        Returns:
            True if order was successfully confirmed.
            
        Raises:
            OrderNotFoundError: If order_id doesn't exist.
            InvalidOrderStatusError: If order is not in PENDING status.
            InsufficientInventoryError: If not enough inventory available.
                Contains details of which items are out of stock.
                
        Examples:
            >>> order = service.create_order("C001", items)
            >>> service.confirm_order(order.id)
            True
            >>> print(order.status)
            OrderStatus.CONFIRMED
            
            Handle insufficient inventory:
            
            >>> try:
            ...     service.confirm_order(order.id)
            ... except InsufficientInventoryError as e:
            ...     print(f"Out of stock: {e.unavailable_items}")
            ...     # Notify customer about availability issues
            
        Note:
            - Inventory is reserved but not committed
            - Reserved inventory expires after 30 minutes if not paid
            - Customer is notified of confirmation
            - This operation is NOT atomic (consider using transactions)
            
        Warning:
            If this method is called concurrently for orders with
            overlapping items, race conditions may occur. Consider
            using database-level locking for production systems.
            
        See Also:
            process_payment(): Next step after confirmation
            cancel_order(): To release reserved inventory
        """
        order = self._get_order(order_id)
        
        if order.status != OrderStatus.PENDING:
            raise InvalidOrderStatusError(
                f"Order must be PENDING to confirm, currently {order.status}"
            )
        
        # Reserve inventory
        try:
            self._inventory_manager.reserve(order.items)
        except InsufficientInventoryError as e:
            logger.warning(
                f"Cannot confirm order {order_id}: insufficient inventory"
            )
            raise
        
        # Update status
        order.status = OrderStatus.CONFIRMED
        order.confirmed_at = datetime.now()
        
        # Notify customer
        self._notification_service.send_order_confirmed(order)
        
        logger.info(f"Confirmed order {order_id}")
        
        return True
    
    def process_payment(
        self,
        order_id: str,
        payment_method: PaymentMethod,
        *,
        timeout: timedelta = timedelta(seconds=30)
    ) -> Dict[str, Union[str, bool, Decimal]]:
        """
        Process payment for confirmed order.
        
        Charges the payment method for the order total and transitions
        order to PAID status if successful. If payment fails, order
        remains CONFIRMED and inventory stays reserved.
        
        Args:
            order_id: Unique order identifier.
            payment_method: Payment method to charge. Must satisfy
                PaymentMethod protocol.
            timeout: Maximum time to wait for payment processing.
                Defaults to 30 seconds.
                
        Returns:
            Payment result dictionary containing:
                - success (bool): Whether payment succeeded
                - transaction_id (str): Unique transaction identifier
                - amount (Decimal): Amount charged
                - timestamp (datetime): When payment was processed
                - method_type (str): Type of payment method used
                
        Raises:
            OrderNotFoundError: If order_id doesn't exist.
            InvalidOrderStatusError: If order is not CONFIRMED.
            PaymentFailedError: If payment processing fails.
                Contains failure reason and details.
            PaymentTimeoutError: If payment processing exceeds timeout.
                
        Examples:
            Process credit card payment:
            
            >>> payment_method = CreditCard(
            ...     number="4111111111111111",
            ...     cvv="123",
            ...     expiry="12/25"
            ... )
            >>> result = service.process_payment(order.id, payment_method)
            >>> print(result['transaction_id'])
            'txn_abc123xyz'
            
            Handle payment failure:
            
            >>> try:
            ...     result = service.process_payment(order.id, payment_method)
            ... except PaymentFailedError as e:
            ...     logger.error(f"Payment failed: {e.reason}")
            ...     # Notify customer to try different payment method
            ...     service.send_payment_failed_notification(order.id)
            
            With custom timeout:
            
            >>> result = service.process_payment(
            ...     order.id,
            ...     payment_method,
            ...     timeout=timedelta(seconds=60)
            ... )
            
        Note:
            - Payment is processed immediately (not deferred)
            - If payment succeeds, inventory reservation is confirmed
            - Customer is notified of successful payment
            - Transaction ID can be used for refunds later
            
        Warning:
            Failed payment attempts count toward fraud detection limits.
            After 3 failed attempts, order may be automatically cancelled.
            
        See Also:
            refund_order(): To refund a paid order
            ship_order(): Next step after payment
        """
        order = self._get_order(order_id)
        
        if order.status != OrderStatus.CONFIRMED:
            raise InvalidOrderStatusError(
                f"Order must be CONFIRMED to process payment, "
                f"currently {order.status}"
            )
        
        # Process payment
        try:
            result = self._payment_processor.charge(
                amount=order.total,
                payment_method=payment_method,
                timeout=timeout
            )
        except Exception as e:
            logger.error(f"Payment failed for order {order_id}: {e}")
            raise PaymentFailedError(str(e))
        
        if not result['success']:
            raise PaymentFailedError(result.get('error', 'Unknown error'))
        
        # Update order
        order.status = OrderStatus.PAID
        order.paid_at = datetime.now()
        order.transaction_id = result['transaction_id']
        
        # Confirm inventory
        self._inventory_manager.confirm(order.items)
        
        # Notify customer
        self._notification_service.send_payment_successful(order)
        
        logger.info(
            f"Processed payment for order {order_id}: "
            f"{result['transaction_id']}"
        )
        
        return result
    
    def _get_order(self, order_id: str) -> 'Order':
        """
        Get order by ID (private helper method).
        
        This is an internal helper method. External code should use
        public methods that provide proper access control.
        
        Args:
            order_id: Order identifier
            
        Returns:
            Order instance
            
        Raises:
            OrderNotFoundError: If order doesn't exist
        """
        order = self._orders.get(order_id)
        if not order:
            raise OrderNotFoundError(f"Order not found: {order_id}")
        return order



Master Guide: Professional Python Documentation Standards
Table of Contents
Type Hints Mastery
Exception Documentation
Realistic Examples
WHY vs WHAT Documentation
Documentation Maintenance
Consistent Style Guide
Edge Cases & Limitations
Warnings for Dangerous Operations
Complete Real-World Example
1. Type Hints Mastery
Basic Type Hints
Python

from typing import (
    List, Dict, Set, Tuple, Optional, Union, Any,
    Callable, Iterator, Generator, TypeVar, Generic,
    Literal, Final, Protocol, TypedDict, cast
)
from collections.abc import Sequence, Mapping, Iterable
from decimal import Decimal
from datetime import datetime, timedelta
from pathlib import Path
import asyncio

# ============================================================================
# BASIC TYPES
# ============================================================================

def greet(name: str, age: int) -> str:
    """
    Generate greeting message.
    
    Args:
        name: Person's name (must be non-empty string)
        age: Person's age in years (must be non-negative)
        
    Returns:
        Formatted greeting message
        
    Examples:
        >>> greet("Alice", 30)
        'Hello Alice, you are 30 years old'
    """
    return f"Hello {name}, you are {age} years old"

# ============================================================================
# COLLECTION TYPES
# ============================================================================

def process_items(
    items: List[str],
    metadata: Dict[str, Any],
    tags: Set[str],
    coordinates: Tuple[float, float]
) -> List[Dict[str, Union[str, int, float]]]:
    """
    Process items with metadata.
    
    Type hints explained:
        - List[str]: Mutable list containing strings only
        - Dict[str, Any]: Dictionary with string keys, any value type
        - Set[str]: Unordered collection of unique strings
        - Tuple[float, float]: Exactly 2 floats (immutable)
        - Return: List of dicts with specific value types
        
    Args:
        items: List of item names to process
        metadata: Additional metadata (flexible value types)
        tags: Unique tags to apply
        coordinates: GPS coordinates as (latitude, longitude)
        
    Returns:
        List of processed item dictionaries
    """
    return []

# ============================================================================
# OPTIONAL AND UNION TYPES
# ============================================================================

def find_user(
    user_id: int,
    include_deleted: bool = False
) -> Optional[Dict[str, Union[str, int, datetime]]]:
    """
    Find user by ID.
    
    Type hints explained:
        - Optional[X] is equivalent to Union[X, None]
        - Union[str, int, datetime]: Value can be any of these types
        - Return None if user not found
        
    Args:
        user_id: Unique user identifier
        include_deleted: Whether to include deleted users
        
    Returns:
        User dictionary if found, None otherwise.
        Dictionary contains:
            - 'name': str
            - 'age': int
            - 'created_at': datetime
    """
    return None

# ============================================================================
# CALLABLE TYPES
# ============================================================================

def retry_operation(
    operation: Callable[[], bool],
    max_attempts: int,
    on_error: Optional[Callable[[Exception], None]] = None
) -> bool:
    """
    Retry an operation until success or max attempts.
    
    Type hints explained:
        - Callable[[], bool]: Function with no args, returns bool
        - Callable[[Exception], None]: Function taking Exception, returns None
        
    Args:
        operation: Function to execute (no parameters, returns bool)
        max_attempts: Maximum number of retry attempts
        on_error: Optional callback for each error.
            Called with the exception that occurred.
            
    Returns:
        True if operation succeeded, False if all attempts failed
        
    Examples:
        >>> def task() -> bool:
        ...     return True
        >>> retry_operation(task, max_attempts=3)
        True
        
        >>> def log_error(e: Exception) -> None:
        ...     print(f"Error: {e}")
        >>> retry_operation(task, 3, on_error=log_error)
        True
    """
    for attempt in range(max_attempts):
        try:
            return operation()
        except Exception as e:
            if on_error:
                on_error(e)
    return False

# ============================================================================
# GENERIC TYPES
# ============================================================================

T = TypeVar('T')
K = TypeVar('K')
V = TypeVar('V')

def get_first_item(items: Sequence[T]) -> Optional[T]:
    """
    Get first item from sequence.
    
    Type hints explained:
        - T is a type variable (generic type)
        - Sequence[T]: Any sequence type (list, tuple, etc.) of type T
        - Return Optional[T]: Either type T or None
        
    This function works with any type:
        - get_first_item([1, 2, 3]) -> Optional[int]
        - get_first_item(['a', 'b']) -> Optional[str]
        
    Args:
        items: Sequence of items of any type
        
    Returns:
        First item if sequence non-empty, None otherwise
        
    Examples:
        >>> get_first_item([1, 2, 3])
        1
        >>> get_first_item([])
        None
        >>> get_first_item(('a', 'b', 'c'))
        'a'
    """
    return items[0] if items else None

class Repository(Generic[T]):
    """
    Generic repository for any entity type.
    
    Type parameter T represents the entity type stored.
    
    Examples:
        >>> user_repo: Repository[User] = Repository()
        >>> product_repo: Repository[Product] = Repository()
    """
    
    def __init__(self):
        self._items: Dict[str, T] = {}
    
    def save(self, id: str, item: T) -> None:
        """
        Save item to repository.
        
        Args:
            id: Unique identifier
            item: Item of type T to save
        """
        self._items[id] = item
    
    def find(self, id: str) -> Optional[T]:
        """
        Find item by ID.
        
        Args:
            id: Item identifier
            
        Returns:
            Item of type T if found, None otherwise
        """
        return self._items.get(id)
    
    def find_all(self) -> List[T]:
        """
        Get all items.
        
        Returns:
            List of all items of type T
        """
        return list(self._items.values())

# ============================================================================
# PROTOCOL (STRUCTURAL TYPING)
# ============================================================================

class Drawable(Protocol):
    """
    Protocol for drawable objects.
    
    Any class with a 'draw' method satisfies this protocol.
    This is duck typing with type safety.
    """
    
    def draw(self) -> str:
        """Draw the object."""
        ...

class Circle:
    """Circle class (doesn't explicitly inherit Drawable)."""
    
    def draw(self) -> str:
        return "Drawing circle"

class Square:
    """Square class (doesn't explicitly inherit Drawable)."""
    
    def draw(self) -> str:
        return "Drawing square"

def render(shape: Drawable) -> str:
    """
    Render any drawable shape.
    
    Type hint explained:
        - Drawable is a Protocol (structural type)
        - Any object with a draw() method satisfies this
        - No inheritance required
        
    Args:
        shape: Any object with a draw() method
        
    Returns:
        Result of drawing the shape
        
    Examples:
        >>> render(Circle())  # Circle satisfies Drawable protocol
        'Drawing circle'
        >>> render(Square())  # Square satisfies Drawable protocol
        'Drawing square'
    """
    return shape.draw()

# ============================================================================
# LITERAL TYPES
# ============================================================================

def set_log_level(level: Literal["DEBUG", "INFO", "WARNING", "ERROR"]) -> None:
    """
    Set logging level.
    
    Type hint explained:
        - Literal restricts values to specific strings
        - Type checker will error on invalid values
        - Better than plain str for API clarity
        
    Args:
        level: Log level. Must be exactly one of:
            - "DEBUG": Most verbose
            - "INFO": Informational messages
            - "WARNING": Warning messages
            - "ERROR": Error messages only
            
    Examples:
        >>> set_log_level("DEBUG")  # OK
        >>> set_log_level("TRACE")  # Type error!
    """
    pass

# ============================================================================
# TYPED DICT
# ============================================================================

from typing import TypedDict

class UserDict(TypedDict):
    """
    Typed dictionary for user data.
    
    This provides type checking for dictionary structure.
    Better than Dict[str, Any] when structure is known.
    """
    id: str
    name: str
    email: str
    age: int
    is_active: bool

def create_user(data: UserDict) -> UserDict:
    """
    Create user from typed dictionary.
    
    Type hint explained:
        - UserDict ensures dictionary has exact structure
        - Type checker verifies all required fields present
        - Type checker verifies field types correct
        
    Args:
        data: User data with required fields:
            - id: Unique identifier (str)
            - name: Full name (str)
            - email: Email address (str)
            - age: Age in years (int)
            - is_active: Account status (bool)
            
    Returns:
        Created user with same structure
        
    Examples:
        >>> user_data: UserDict = {
        ...     'id': 'U001',
        ...     'name': 'John Doe',
        ...     'email': 'john@example.com',
        ...     'age': 30,
        ...     'is_active': True
        ... }
        >>> create_user(user_data)
        {...}
    """
    return data

# ============================================================================
# ASYNC TYPE HINTS
# ============================================================================

async def fetch_data(url: str) -> Dict[str, Any]:
    """
    Fetch data asynchronously.
    
    Type hint explained:
        - async def means function returns a coroutine
        - Actual return type is Coroutine[Any, Any, Dict[str, Any]]
        - But we just annotate the eventual value: Dict[str, Any]
        
    Args:
        url: URL to fetch from
        
    Returns:
        Parsed JSON data as dictionary
        
    Examples:
        >>> async def main():
        ...     data = await fetch_data("https://api.example.com/users")
        ...     print(data)
        >>> asyncio.run(main())
    """
    await asyncio.sleep(0.1)  # Simulate network delay
    return {"status": "ok"}

async def process_batch(
    items: List[str],
    processor: Callable[[str], Awaitable[bool]]
) -> List[bool]:
    """
    Process items asynchronously.
    
    Type hint explained:
        - Callable[[str], Awaitable[bool]]: Async function
        - Takes str parameter, returns awaitable that yields bool
        
    Args:
        items: Items to process
        processor: Async function to process each item
        
    Returns:
        List of processing results
        
    Examples:
        >>> async def process_item(item: str) -> bool:
        ...     await asyncio.sleep(0.1)
        ...     return True
        >>> asyncio.run(process_batch(['a', 'b'], process_item))
        [True, True]
    """
    tasks = [processor(item) for item in items]
    return await asyncio.gather(*tasks)

# ============================================================================
# GENERATOR TYPE HINTS
# ============================================================================

def fibonacci(n: int) -> Generator[int, None, None]:
    """
    Generate Fibonacci sequence.
    
    Type hint explained:
        - Generator[YieldType, SendType, ReturnType]
        - YieldType: int (values yielded)
        - SendType: None (we don't accept sent values)
        - ReturnType: None (generator doesn't return a value)
        
    Args:
        n: Number of Fibonacci numbers to generate
        
    Yields:
        Next Fibonacci number
        
    Examples:
        >>> list(fibonacci(5))
        [0, 1, 1, 2, 3]
        
        >>> for num in fibonacci(10):
        ...     print(num)
    """
    a, b = 0, 1
    for _ in range(n):
        yield a
        a, b = b, a + b

def read_file_lines(path: Path) -> Iterator[str]:
    """
    Read file lines lazily.
    
    Type hint explained:
        - Iterator[str]: Simpler than Generator when not using send/return
        - Indicates this yields strings
        
    Args:
        path: Path to file
        
    Yields:
        Each line from the file
        
    Examples:
        >>> for line in read_file_lines(Path("data.txt")):
        ...     process(line)
    """
    with open(path) as f:
        for line in f:
            yield line.strip()

# ============================================================================
# FINAL (NON-OVERRIDABLE)
# ============================================================================

class Config:
    """Configuration class with final attributes."""
    
    API_KEY: Final[str] = "secret_key_123"
    """API key that should never be changed."""
    
    MAX_RETRIES: Final[int] = 3
    """Maximum retry attempts (constant)."""

# ============================================================================
# TYPE NARROWING WITH TYPE GUARDS
# ============================================================================

def is_string_list(val: List[Any]) -> TypeGuard[List[str]]:
    """
    Type guard to check if list contains only strings.
    
    Type hint explained:
        - TypeGuard[List[str]] tells type checker that if this
          returns True, val can be treated as List[str]
        
    Args:
        val: List to check
        
    Returns:
        True if all elements are strings
        
    Examples:
        >>> data: List[Any] = ["a", "b", "c"]
        >>> if is_string_list(data):
        ...     # Type checker knows data is List[str] here
        ...     result = [s.upper() for s in data]
    """
    return all(isinstance(item, str) for item in val)

# ============================================================================
# OVERLOAD (MULTIPLE SIGNATURES)
# ============================================================================

from typing import overload

@overload
def process(data: str) -> str: ...

@overload
def process(data: int) -> int: ...

@overload
def process(data: List[str]) -> List[str]: ...

def process(data: Union[str, int, List[str]]) -> Union[str, int, List[str]]:
    """
    Process different data types.
    
    Type hints explained:
        - @overload decorators define type-specific signatures
        - Helps type checker understand return type based on input type
        - Actual implementation has Union type
        
    Args:
        data: Data to process (str, int, or List[str])
        
    Returns:
        Processed data of same type as input
        
    Examples:
        >>> process("hello")  # Type checker knows returns str
        'HELLO'
        >>> process(42)  # Type checker knows returns int
        42
        >>> process(["a", "b"])  # Type checker knows returns List[str]
        ['A', 'B']
    """
    if isinstance(data, str):
        return data.upper()
    elif isinstance(data, int):
        return data
    else:
        return [s.upper() for s in data]
2. Exception Documentation
Complete Exception Documentation
Python

class InsufficientFundsError(Exception):
    """
    Raised when account has insufficient funds for operation.
    
    This exception is raised by withdrawal and transfer operations
    when the requested amount exceeds available balance.
    
    Attributes:
        requested_amount: Amount that was requested
        available_balance: Current available balance
        account_number: Account identifier
        
    Examples:
        >>> try:
        ...     account.withdraw(1000)
        ... except InsufficientFundsError as e:
        ...     print(f"Need {e.requested_amount}, have {e.available_balance}")
    """
    
    def __init__(
        self,
        requested_amount: Decimal,
        available_balance: Decimal,
        account_number: str
    ):
        self.requested_amount = requested_amount
        self.available_balance = available_balance
        self.account_number = account_number
        
        shortage = requested_amount - available_balance
        message = (
            f"Insufficient funds in account {account_number}. "
            f"Requested: {requested_amount}, "
            f"Available: {available_balance}, "
            f"Short by: {shortage}"
        )
        super().__init__(message)

class BankAccount:
    """
    Bank account with comprehensive exception handling.
    """
    
    def __init__(self, account_number: str, initial_balance: Decimal):
        """
        Initialize bank account.
        
        Args:
            account_number: Unique account identifier
            initial_balance: Starting balance
            
        Raises:
            ValueError: If account_number is empty or initial_balance is negative.
                Examples:
                    - Empty account number: ""
                    - Negative balance: Decimal('-100')
                    
        Examples:
            Valid initialization:
            >>> account = BankAccount("ACC001", Decimal('1000'))
            
            Invalid - raises ValueError:
            >>> account = BankAccount("", Decimal('1000'))
            Traceback (most recent call last):
                ...
            ValueError: Account number cannot be empty
        """
        if not account_number:
            raise ValueError("Account number cannot be empty")
        if initial_balance < 0:
            raise ValueError(
                f"Initial balance cannot be negative: {initial_balance}"
            )
        
        self.account_number = account_number
        self.balance = initial_balance
    
    def withdraw(self, amount: Decimal) -> bool:
        """
        Withdraw money from account.
        
        Args:
            amount: Amount to withdraw (must be positive)
            
        Returns:
            True if withdrawal successful
            
        Raises:
            ValueError: If amount is zero, negative, or not a valid Decimal.
                WHY: Zero/negative withdrawals don't make business sense.
                Examples:
                    - Zero amount: Decimal('0')
                    - Negative amount: Decimal('-50')
                    
            TypeError: If amount is not Decimal type.
                WHY: We require Decimal for precision in financial calculations.
                Example:
                    - Float: 50.5 (should be Decimal('50.5'))
                    
            InsufficientFundsError: If withdrawal amount exceeds balance.
                WHY: Cannot withdraw more than available.
                Contains:
                    - requested_amount: What was requested
                    - available_balance: What's available
                    - account_number: Which account
                Example:
                    - Request Decimal('1000') with balance Decimal('500')
                    
            AccountClosedError: If account is closed.
                WHY: Closed accounts cannot perform transactions.
                Example:
                    - Attempting withdrawal after calling close_account()
                    
        Examples:
            Successful withdrawal:
            >>> account = BankAccount("ACC001", Decimal('1000'))
            >>> account.withdraw(Decimal('100'))
            True
            >>> print(account.balance)
            900
            
            Insufficient funds (raises exception):
            >>> account = BankAccount("ACC001", Decimal('100'))
            >>> try:
            ...     account.withdraw(Decimal('1000'))
            ... except InsufficientFundsError as e:
            ...     print(f"Error: {e}")
            ...     print(f"Shortage: {e.requested_amount - e.available_balance}")
            Error: Insufficient funds...
            Shortage: 900
            
            Invalid amount (raises ValueError):
            >>> account.withdraw(Decimal('-50'))
            Traceback (most recent call last):
                ...
            ValueError: Withdrawal amount must be positive
            
        Note:
            Even obvious exceptions are documented because:
            1. Developers need to know what to catch
            2. Different exceptions have different recovery strategies
            3. Documentation helps with error handling design
        """
        # Validate amount type
        if not isinstance(amount, Decimal):
            raise TypeError(
                f"Amount must be Decimal, got {type(amount).__name__}. "
                f"Use Decimal('{amount}') for precision."
            )
        
        # Validate amount value
        if amount <= 0:
            raise ValueError(
                f"Withdrawal amount must be positive, got {amount}"
            )
        
        # Check sufficient funds
        if amount > self.balance:
            raise InsufficientFundsError(
                requested_amount=amount,
                available_balance=self.balance,
                account_number=self.account_number
            )
        
        # Perform withdrawal
        self.balance -= amount
        return True

# ============================================================================
# EXCEPTION HIERARCHY DOCUMENTATION
# ============================================================================

class PaymentError(Exception):
    """
    Base exception for all payment-related errors.
    
    All payment exceptions inherit from this, allowing catch-all:
        try:
            process_payment()
        except PaymentError:
            # Catches all payment-related errors
            pass
    """
    pass

class PaymentValidationError(PaymentError):
    """
    Raised when payment details fail validation.
    
    This is raised BEFORE attempting to charge payment method.
    
    Common causes:
        - Invalid card number format
        - Expired payment method
        - Invalid CVV
        - Missing required fields
        
    Examples:
        >>> try:
        ...     validate_payment(card_number="invalid")
        ... except PaymentValidationError as e:
        ...     print(f"Validation failed: {e}")
    """
    pass

class PaymentProcessingError(PaymentError):
    """
    Raised when payment processing fails at gateway.
    
    This is raised AFTER attempting to charge payment method.
    
    Common causes:
        - Insufficient funds
        - Card declined by issuer
        - Network timeout
        - Gateway unavailable
        
    Attributes:
        gateway_response: Raw response from payment gateway
        retry_allowed: Whether operation can be retried
        
    Examples:
        >>> try:
        ...     gateway.charge(amount)
        ... except PaymentProcessingError as e:
        ...     if e.retry_allowed:
        ...         # Can retry with same payment method
        ...         retry_payment()
        ...     else:
        ...         # Must use different payment method
        ...         request_new_payment()
    """
    
    def __init__(
        self,
        message: str,
        gateway_response: Dict[str, Any],
        retry_allowed: bool = False
    ):
        super().__init__(message)
        self.gateway_response = gateway_response
        self.retry_allowed = retry_allowed

class PaymentTimeoutError(PaymentProcessingError):
    """
    Raised when payment processing times out.
    
    WHY separate exception: Timeouts require special handling.
    Unlike other processing errors, timeout doesn't mean payment
    failed - it means we don't know the status.
    
    Recovery strategy:
        1. Check payment status before retrying
        2. Use idempotency key to prevent double-charging
        3. May need to contact gateway support
        
    Examples:
        >>> try:
        ...     gateway.charge(amount, timeout=30)
        ... except PaymentTimeoutError:
        ...     # Check status before retry!
        ...     status = gateway.check_status(transaction_id)
        ...     if status == 'pending':
        ...         wait_for_completion()
        ...     elif status == 'failed':
        ...         retry_payment()
    """
    pass
3. Realistic Examples
Real-World Usage Examples
Python

from decimal import Decimal
from datetime import datetime, date
from typing import List, Dict, Optional
from pathlib import Path
import json

class OrderManagementSystem:
    """
    Complete order management with realistic examples.
    """
    
    def create_order(
        self,
        customer_id: str,
        items: List[Dict[str, Union[str, int, Decimal]]],
        shipping_address: Dict[str, str],
        payment_method: Dict[str, str]
    ) -> Dict[str, Any]:
        """
        Create a new order.
        
        Args:
            customer_id: Customer identifier (e.g., "CUST-12345")
            items: List of items with structure:
                [
                    {
                        'product_id': 'PROD-001',
                        'quantity': 2,
                        'unit_price': Decimal('29.99')
                    },
                    ...
                ]
            shipping_address: Address dictionary:
                {
                    'street': '123 Main St',
                    'city': 'San Francisco',
                    'state': 'CA',
                    'postal_code': '94102',
                    'country': 'USA'
                }
            payment_method: Payment details:
                {
                    'type': 'credit_card',
                    'card_number': '4111111111111111',
                    'expiry': '12/25',
                    'cvv': '123'
                }
                
        Returns:
            Order details dictionary:
            {
                'order_id': 'ORD-2024-001',
                'status': 'pending',
                'created_at': '2024-01-15T10:30:00',
                'total': Decimal('59.98'),
                'items': [...],
                'shipping_address': {...},
                'estimated_delivery': '2024-01-20'
            }
            
        Examples:
            EXAMPLE 1: Simple single-item order
            ------------------------------------
            >>> oms = OrderManagementSystem()
            >>> order = oms.create_order(
            ...     customer_id="CUST-001",
            ...     items=[{
            ...         'product_id': 'LAPTOP-15',
            ...         'quantity': 1,
            ...         'unit_price': Decimal('999.99')
            ...     }],
            ...     shipping_address={
            ...         'street': '742 Evergreen Terrace',
            ...         'city': 'Springfield',
            ...         'state': 'OR',
            ...         'postal_code': '97403',
            ...         'country': 'USA'
            ...     },
            ...     payment_method={
            ...         'type': 'credit_card',
            ...         'card_number': '4111111111111111',
            ...         'expiry': '12/25',
            ...         'cvv': '123'
            ...     }
            ... )
            >>> print(order['order_id'])
            'ORD-2024-001'
            >>> print(order['total'])
            Decimal('999.99')
            
            EXAMPLE 2: Multi-item order with bulk discount
            -----------------------------------------------
            >>> order = oms.create_order(
            ...     customer_id="CUST-002",
            ...     items=[
            ...         {
            ...             'product_id': 'MOUSE-WIRELESS',
            ...             'quantity': 5,  # Bulk order
            ...             'unit_price': Decimal('29.99')
            ...         },
            ...         {
            ...             'product_id': 'KEYBOARD-MECH',
            ...             'quantity': 5,
            ...             'unit_price': Decimal('79.99')
            ...         }
            ...     ],
            ...     shipping_address={
            ...         'street': '1600 Pennsylvania Avenue',
            ...         'city': 'Washington',
            ...         'state': 'DC',
            ...         'postal_code': '20500',
            ...         'country': 'USA'
            ...     },
            ...     payment_method={
            ...         'type': 'paypal',
            ...         'email': 'customer@example.com'
            ...     }
            ... )
            >>> # 10+ items qualifies for 10% discount
            >>> print(order['discount'])
            Decimal('54.99')
            >>> print(order['total'])
            Decimal('494.91')
            
            EXAMPLE 3: International order with customs
            --------------------------------------------
            >>> order = oms.create_order(
            ...     customer_id="CUST-INTL-003",
            ...     items=[{
            ...         'product_id': 'TABLET-PRO',
            ...         'quantity': 1,
            ...         'unit_price': Decimal('799.00')
            ...     }],
            ...     shipping_address={
            ...         'street': '1 Chome-1-2 Oshiage',
            ...         'city': 'Tokyo',
            ...         'state': 'Tokyo',
            ...         'postal_code': '131-0045',
            ...         'country': 'Japan'  # International!
            ...     },
            ...     payment_method={
            ...         'type': 'credit_card',
            ...         'card_number': '4111111111111111',
            ...         'expiry': '12/25',
            ...         'cvv': '123'
            ...     }
            ... )
            >>> # International orders include customs info
            >>> print(order['customs_required'])
            True
            >>> print(order['estimated_duty'])
            Decimal('79.90')  # ~10% of value
            
            EXAMPLE 4: Error handling - invalid payment
            --------------------------------------------
            >>> try:
            ...     order = oms.create_order(
            ...         customer_id="CUST-004",
            ...         items=[{
            ...             'product_id': 'HEADPHONES',
            ...             'quantity': 1,
            ...             'unit_price': Decimal('199.99')
            ...         }],
            ...         shipping_address={...},
            ...         payment_method={
            ...             'type': 'credit_card',
            ...             'card_number': 'invalid',  # Bad format
            ...             'expiry': '12/25',
            ...             'cvv': '123'
            ...         }
            ...     )
            ... except PaymentValidationError as e:
            ...     print(f"Payment validation failed: {e}")
            ...     # Re-prompt user for valid payment method
            Payment validation failed: Invalid card number format
            
            EXAMPLE 5: Complete workflow with all steps
            --------------------------------------------
            >>> # 1. Create order
            >>> order = oms.create_order(...)
            >>> 
            >>> # 2. Process payment
            >>> payment = oms.process_payment(order['order_id'])
            >>> print(payment['status'])
            'captured'
            >>> 
            >>> # 3. Allocate inventory
            >>> inventory = oms.allocate_inventory(order['order_id'])
            >>> print(inventory['allocated'])
            True
            >>> 
            >>> # 4. Ship order
            >>> shipment = oms.create_shipment(
            ...     order['order_id'],
            ...     carrier='UPS',
            ...     service_level='ground'
            ... )
            >>> print(shipment['tracking_number'])
            '1Z999AA10123456784'
            >>> 
            >>> # 5. Track until delivery
            >>> while shipment['status'] != 'delivered':
            ...     status = oms.get_tracking_status(
            ...         shipment['tracking_number']
            ...     )
            ...     print(f"Status: {status['status']}")
            ...     time.sleep(3600)  # Check hourly
            
        Note:
            These examples show REAL usage patterns, not toy examples:
            - Realistic data structures
            - Common edge cases (international orders)
            - Error handling workflows
            - Multi-step processes
            - Integration with other system components
        """
        pass
    
    def generate_invoice(
        self,
        order_id: str,
        format: Literal['pdf', 'html', 'json'] = 'pdf'
    ) -> Union[bytes, str, Dict]:
        """
        Generate invoice for order.
        
        Args:
            order_id: Order identifier
            format: Output format
            
        Returns:
            Invoice in requested format:
                - 'pdf': bytes (binary PDF data)
                - 'html': str (HTML string)
                - 'json': Dict (structured data)
                
        Examples:
            EXAMPLE 1: Generate PDF invoice for email
            ------------------------------------------
            >>> oms = OrderManagementSystem()
            >>> order_id = "ORD-2024-001"
            >>> 
            >>> # Generate PDF
            >>> pdf_bytes = oms.generate_invoice(order_id, format='pdf')
            >>> 
            >>> # Save to file
            >>> with open(f'invoice_{order_id}.pdf', 'wb') as f:
            ...     f.write(pdf_bytes)
            >>> 
            >>> # Email to customer
            >>> email_service.send_email(
            ...     to=customer.email,
            ...     subject=f'Invoice for Order {order_id}',
            ...     body='Please find your invoice attached.',
            ...     attachments=[{
            ...         'filename': f'invoice_{order_id}.pdf',
            ...         'content': pdf_bytes,
            ...         'mime_type': 'application/pdf'
            ...     }]
            ... )
            
            EXAMPLE 2: Display invoice in web browser
            ------------------------------------------
            >>> # Generate HTML
            >>> html = oms.generate_invoice(order_id, format='html')
            >>> 
            >>> # In Flask/Django view:
            >>> return render_template(
            ...     'invoice_template.html',
            ...     invoice_html=html
            ... )
            >>> 
            >>> # Or directly:
            >>> return Response(html, mimetype='text/html')
            
            EXAMPLE 3: Process invoice data programmatically
            ------------------------------------------------
            >>> # Generate JSON for API
            >>> invoice_data = oms.generate_invoice(order_id, format='json')
            >>> 
            >>> # Extract specific fields
            >>> total = invoice_data['total']
            >>> tax = invoice_data['tax']
            >>> items = invoice_data['line_items']
            >>> 
            >>> # Send to accounting system
            >>> accounting_api.create_invoice({
            ...     'external_id': order_id,
            ...     'amount': total,
            ...     'tax': tax,
            ...     'line_items': items,
            ...     'customer': invoice_data['customer']
            ... })
            >>> 
            >>> # Store for records
            >>> with open(f'invoices/{order_id}.json', 'w') as f:
            ...     json.dump(invoice_data, f, indent=2)
            
            EXAMPLE 4: Batch invoice generation
            ------------------------------------
            >>> # Generate invoices for all orders in date range
            >>> orders = oms.get_orders_by_date(
            ...     start_date=date(2024, 1, 1),
            ...     end_date=date(2024, 1, 31)
            ... )
            >>> 
            >>> invoices_dir = Path('invoices/2024-01')
            >>> invoices_dir.mkdir(parents=True, exist_ok=True)
            >>> 
            >>> for order in orders:
            ...     # Generate PDF for each
            ...     pdf = oms.generate_invoice(order['order_id'], format='pdf')
            ...     
            ...     # Save to monthly directory
            ...     filename = f"{order['order_id']}_{order['customer_id']}.pdf"
            ...     filepath = invoices_dir / filename
            ...     filepath.write_bytes(pdf)
            ...     
            ...     print(f"Generated: {filename}")
            
            EXAMPLE 5: Invoice with custom template
            ----------------------------------------
            >>> # Use custom template for VIP customers
            >>> if customer.tier == 'VIP':
            ...     invoice_html = oms.generate_invoice(
            ...         order_id,
            ...         format='html',
            ...         template='vip_invoice_template.html',
            ...         branding={
            ...             'logo_url': 'https://cdn.example.com/vip_logo.png',
            ...             'primary_color': '#gold',
            ...             'thank_you_message': 'Thank you for being a VIP!'
            ...         }
            ...     )
            
        Note:
            Examples demonstrate:
            - Different output formats for different use cases
            - Integration with other systems (email, accounting)
            - Batch processing patterns
            - File system operations
            - Conditional logic based on customer data
        """
        pass
4. WHY vs WHAT Documentation
Explaining the Reasoning
Python

from typing import List, Dict, Set
from datetime import datetime, timedelta
from decimal import Decimal

class CacheManager:
    """
    Manages caching with TTL and automatic cleanup.
    
    WHY this class exists:
        Many parts of the application need temporary data storage
        to avoid repeated expensive operations (database queries,
        API calls, calculations). A centralized cache manager ensures:
        1. Consistent caching behavior across application
        2. Automatic memory management (prevents unbounded growth)
        3. Thread-safe operations (important for web servers)
        4. Monitoring and debugging capabilities
    """
    
    def __init__(self, max_size: int = 1000, default_ttl: int = 3600):
        """
        Initialize cache manager.
        
        WHAT: Creates empty cache with size limit and default TTL.
        
        WHY max_size is needed:
            Without a size limit, the cache would grow unbounded,
            eventually consuming all available memory and crashing
            the application. The limit forces eviction of old entries.
            
        WHY default_ttl:
            Different data has different freshness requirements.
            Having a default prevents forgetting to set TTL, which
            could lead to stale data being served indefinitely.
            
        WHY these specific defaults (1000, 3600):
            - 1000 items: Enough for typical app, ~1MB for small objects
            - 3600 seconds (1 hour): Good balance between freshness
              and cache hit rate for most data
              
        Args:
            max_size: Maximum number of items to cache.
                WHY configurable: Different deployments have different
                memory constraints. Development might use 100, production
                might use 10000.
            default_ttl: Default time-to-live in seconds.
                WHY configurable: Different applications have different
                staleness tolerances. Real-time dashboard might use 60,
                analytics dashboard might use 86400 (24 hours).
        """
        self._cache: Dict[str, tuple[Any, datetime]] = {}
        self._access_times: Dict[str, datetime] = {}
        self._max_size = max_size
        self._default_ttl = default_ttl
    
    def get(self, key: str) -> Optional[Any]:
        """
        Get value from cache.
        
        WHAT: Retrieves cached value if exists and not expired.
        
        WHY check expiry on get (instead of background cleanup):
            Lazy expiry checking has several advantages:
            1. Simpler implementation (no background threads)
            2. More accurate (removes expired items immediately when accessed)
            3. Lower overhead (only checks when actually needed)
            
        WHY update access time:
            We use LRU (Least Recently Used) eviction. Tracking access
            times allows evicting items that haven't been used recently,
            keeping "hot" data in cache even if it was added long ago.
            
        Args:
            key: Cache key
            
        Returns:
            Cached value if found and not expired, None otherwise.
            
            WHY return None instead of raising exception:
                Cache miss is a normal occurrence, not an error condition.
                Requiring exception handling would clutter calling code:
                
                # Bad (if we raised exception):
                try:
                    value = cache.get(key)
                except CacheMissError:
                    value = expensive_operation()
                
                # Good (with None):
                value = cache.get(key)
                if value is None:
                    value = expensive_operation()
        """
        # WHY check existence first:
        # Prevents KeyError when accessing _cache dict
        if key not in self._cache:
            return None
        
        value, expiry = self._cache[key]
        
        # WHY check expiry:
        # Expired data is stale and should not be served
        if datetime.now() > expiry:
            # WHY delete expired item immediately:
            # Frees memory and prevents expired item from being
            # counted toward max_size
            self._delete_item(key)
            return None
        
        # WHY update access time:
        # Marks this item as recently used for LRU eviction
        self._access_times[key] = datetime.now()
        
        return value
    
    def set(
        self,
        key: str,
        value: Any,
        ttl: Optional[int] = None
    ) -> None:
        """
        Store value in cache.
        
        WHAT: Saves value with expiry time, evicting old items if needed.
        
        WHY evict before adding (instead of after):
            If we added first then evicted, we might briefly exceed max_size,
            potentially causing memory issues. Evicting first ensures we
            never go over the limit.
            
        WHY allow TTL override:
            Different data has different staleness requirements:
            - User session: 1 hour (3600s)
            - Product catalog: 1 day (86400s)
            - Flash sale countdown: 1 minute (60s)
            Allowing per-item TTL provides flexibility.
            
        Args:
            key: Cache key
            value: Value to cache
                WHY accept Any type:
                    Cache should work with any serializable data.
                    Restricting to specific types would limit reusability.
            ttl: Time-to-live in seconds (uses default if None)
        """
        # WHY check size before adding:
        # See explanation in method docstring above
        if len(self._cache) >= self._max_size:
            self._evict_lru()
        
        # WHY use default if ttl is None (instead of requiring ttl):
        # Convenience - most cache operations use standard TTL.
        # Requiring TTL every time would be tedious:
        # cache.set('key', value, 3600)  # repetitive
        # vs
        # cache.set('key', value)  # clean
        ttl_seconds = ttl if ttl is not None else self._default_ttl
        expiry = datetime.now() + timedelta(seconds=ttl_seconds)
        
        self._cache[key] = (value, expiry)
        self._access_times[key] = datetime.now()
    
    def _evict_lru(self) -> None:
        """
        Evict least recently used item (private method).
        
        WHAT: Removes item that hasn't been accessed in longest time.
        
        WHY LRU instead of FIFO:
            FIFO (First In First Out) would evict old items even if
            frequently accessed. LRU keeps "hot" data regardless of age.
            
            Example scenario:
            - Item A: Added 1 hour ago, accessed 1000 times
            - Item B: Added 5 minutes ago, accessed once
            
            FIFO would evict A (older), losing valuable cached data.
            LRU would evict B (less used), which is better.
            
        WHY this is a private method:
            Eviction is an internal implementation detail. External
            code shouldn't trigger eviction directly - it happens
            automatically when needed. This prevents misuse:
            
            # Bad (if public):
            cache._evict_lru()  # Manual eviction is wrong
            
        WHY use min() instead of sorting entire access_times:
            Sorting is O(n log n), finding minimum is O(n).
            For large caches, this is significantly faster:
            - 10,000 items: sort ~130k ops, min ~10k ops
        """
        # Find least recently used item
        lru_key = min(
            self._access_times.items(),
            key=lambda x: x[1]  # WHY [1]: Sorts by datetime, not key
        )[0]
        
        self._delete_item(lru_key)
    
    def _delete_item(self, key: str) -> None:
        """
        Delete item from cache (private method).
        
        WHAT: Removes item from both cache and access_times dicts.
        
        WHY separate method for deletion:
            Multiple places need to delete items (eviction, expiry).
            Centralizing in one method ensures:
            1. Consistent cleanup (both dicts updated)
            2. Single place to add logging/metrics
            3. Prevents bugs from forgetting to update both dicts
            
        WHY check 'if key in dict' before del:
            Prevents KeyError if key was already deleted.
            This can happen in concurrent scenarios:
            - Thread 1: Checks expiry, finds expired
            - Thread 2: Evicts same key due to LRU
            - Thread 1: Tries to delete already-gone key
            
        Args:
            key: Key to delete
        """
        if key in self._cache:
            del self._cache[key]
        
        if key in self._access_times:
            del self._access_times[key]

class RateLimiter:
    """
    Rate limiting to prevent abuse.
    
    WHY rate limiting is necessary:
        Without limits, a single user/IP could:
        1. Exhaust server resources (DOS attack)
        2. Scrape all data rapidly
        3. Cause unfair usage (one user gets all API calls)
        4. Generate excessive costs (if using paid services)
        
    WHY token bucket algorithm:
        Alternatives considered:
        
        1. Fixed window (count requests per minute):
           PROBLEM: Burst at window boundary
           User sends 1000 at :59, 1000 at 1:00 = 2000 in 2 seconds!
           
        2. Sliding window:
           PROBLEM: Memory intensive (stores every request timestamp)
           
        3. Token bucket (chosen):
           PROS:
           - Smooth rate limiting (no boundary issues)
           - Allows controlled bursts (token accumulation)
           - Low memory (just token count, not timestamps)
           - Industry standard (AWS, Stripe use this)
    """
    
    def __init__(
        self,
        rate: int,
        per: int,
        burst: Optional[int] = None
    ):
        """
        Initialize rate limiter.
        
        WHY three parameters needed:
            'rate' alone isn't enough. We need to specify timeframe:
            - "10 per second" is very different from "10 per hour"
            
        WHY allow burst:
            Strict rate limiting can hurt user experience:
            - User idle for 5 minutes (tokens accumulate)
            - User returns, clicks 10 things rapidly
            - Without burst: Denied! (poor UX)
            - With burst: Allowed! (tokens were saved up)
            
        Args:
            rate: Number of requests allowed
            per: Time period in seconds
            burst: Maximum tokens to accumulate (None = rate * 2)
                WHY default to rate * 2:
                    Allows brief burst while preventing unlimited accumulation.
                    If rate is 100/min, burst of 200 allows 2x speed briefly.
        """
        self._rate = rate
        self._per = per
        # WHY rate * 2 for default burst:
        # Explained in docstring above
        self._burst = burst if burst is not None else rate * 2
        
        # WHY Dict instead of single counter:
        # Different clients need different token buckets
        # (each user/IP has own limit)
        self._buckets: Dict[str, tuple[float, datetime]] = {}
    
    def allow(self, client_id: str) -> bool:
        """
        Check if request is allowed.
        
        WHAT: Returns True if client has tokens, False if rate limited.
        
        WHY return bool instead of raise exception:
            Rate limiting is expected behavior, not an error.
            Caller should handle gracefully:
            
            if rate_limiter.allow(user_id):
                process_request()
            else:
                return "Rate limit exceeded, try again later"
                
        WHY calculate tokens on-demand (vs background refill):
            Background refill would require:
            1. Separate thread/task
            2. Locks for thread safety
            3. More complex code
            
            On-demand calculation:
            1. No threads needed
            2. Naturally thread-safe (each calc independent)
            3. Simpler code
            4. More accurate (calculates exact time elapsed)
            
        Args:
            client_id: Identifier for client (user ID, IP address, API key)
                WHY accept any string:
                    Different systems identify clients differently:
                    - Web app: user ID
                    - API: API key
                    - Public endpoint: IP address
                    Accepting string allows flexibility.
                    
        Returns:
            True if request allowed, False if rate limited.
        """
        now = datetime.now()
        
        # WHY check if client exists:
        # First request from client needs initialization
        if client_id not in self._buckets:
            # WHY start with full bucket:
            # New clients shouldn't be immediately limited
            self._buckets[client_id] = (float(self._rate), now)
            return True
        
        tokens, last_update = self._buckets[client_id]
        
        # Calculate tokens to add based on time elapsed
        # WHY use total_seconds():
        # timedelta doesn't support direct division, need seconds
        elapsed = (now - last_update).total_seconds()
        
        # WHY divide rate by per:
        # Convert "100 per 60 seconds" to "1.67 per second"
        # This gives us tokens-per-second rate
        tokens_to_add = elapsed * (self._rate / self._per)
        
        # WHY min with burst:
        # Cap tokens at burst limit to prevent unlimited accumulation
        # User idle for 1 hour shouldn't get 6000 tokens!
        tokens = min(tokens + tokens_to_add, float(self._burst))
        
        # WHY check >= 1 (not > 0):
        # Request costs 1 token. Having 0.5 tokens isn't enough.
        if tokens >= 1:
            # WHY subtract 1:
            # Consume one token for this request
            tokens -= 1
            self._buckets[client_id] = (tokens, now)
            return True
        else:
            # WHY update timestamp even when denied:
            # Keeps refill rate accurate. Without this:
            # - Request at 0:00 with 0 tokens → denied
            # - Request at 0:01 with 0 tokens → denied
            # - Would keep denying forever! Need to track time.
            self._buckets[client_id] = (tokens, now)
            return False
This demonstrates the critical difference:

WHAT: Describes the operation
WHY: Explains the reasoning, alternatives considered, and consequences
Good documentation includes both! 🎯

5. Documentation Maintenance
Keeping Documentation Current
Python

# ============================================================================
# VERSION HISTORY AND CHANGELOG
# ============================================================================

"""
Module: payment_processor.py
Last Updated: 2024-01-15
Version: 2.3.0

CHANGELOG:
----------
v2.3.0 (2024-01-15):
    - Added support for Apple Pay and Google Pay
    - BREAKING: Changed refund() return type from bool to Dict
    - Deprecated: process_card() - use process_payment() instead
    - Fixed: Race condition in concurrent payment processing
    
v2.2.0 (2023-12-01):
    - Added async payment processing support
    - Improved error messages for declined cards
    
v2.1.0 (2023-10-15):
    - Added support for 3D Secure authentication
    - Updated Stripe API to v2023-10-01
    
DEPRECATION NOTICES:
-------------------
- process_card() will be removed in v3.0.0 (March 2024)
  Use process_payment() instead
  
MIGRATION GUIDE:
----------------
From v2.2.x to v2.3.0:

Old code:
>>> success = processor.refund(transaction_id, amount)
>>> if success:
...     print("Refunded")

New code:
>>> result = processor.refund(transaction_id, amount)
>>> if result['success']:
...     print(f"Refunded: {result['refund_id']}")
"""

from typing import Dict, Union, Optional, Literal
from decimal import Decimal
from datetime import datetime
import warnings

class PaymentProcessor:
    """
    Process payments through multiple gateways.
    
    Version: 2.3.0
    Last Updated: 2024-01-15
    
    Supported Payment Methods:
        - Credit Cards (Visa, Mastercard, Amex)
        - Debit Cards
        - PayPal
        - Apple Pay (New in v2.3.0)
        - Google Pay (New in v2.3.0)
        
    Thread Safety:
        This class IS thread-safe as of v2.3.0 (fixed in #PR-234)
        
    Performance:
        - Average latency: 200ms
        - Throughput: 1000 req/sec
        - Rate limit: 100 req/sec per API key
    """
    
    def process_payment(
        self,
        amount: Decimal,
        currency: str,
        payment_method: Dict[str, str],
        *,
        idempotency_key: Optional[str] = None,
        metadata: Optional[Dict[str, str]] = None
    ) -> Dict[str, Union[str, bool, Decimal]]:
        """
        Process a payment.
        
        Version History:
            - v2.0.0: Initial implementation
            - v2.1.0: Added 3D Secure support
            - v2.3.0: Added Apple Pay and Google Pay support
            
        Args:
            amount: Payment amount (must be positive)
            currency: ISO 4217 currency code (e.g., 'USD', 'EUR')
            payment_method: Payment details. Structure depends on type:
                
                Credit Card:
                {
                    'type': 'card',
                    'number': '4111111111111111',
                    'exp_month': '12',
                    'exp_year': '2025',
                    'cvv': '123'
                }
                
                PayPal:
                {
                    'type': 'paypal',
                    'email': 'customer@example.com'
                }
                
                Apple Pay (New in v2.3.0):
                {
                    'type': 'apple_pay',
                    'token': 'pk_apple_...'
                }
                
                Google Pay (New in v2.3.0):
                {
                    'type': 'google_pay',
                    'token': 'pk_google_...'
                }
                
            idempotency_key: Unique key to prevent duplicate charges.
                IMPORTANT: Always provide this for payment retries!
                
                Added in v2.2.0 to prevent double-charging.
                See: https://docs.example.com/idempotency
                
            metadata: Optional metadata to attach to payment.
                Added in v2.1.0.
                Useful for order IDs, customer references, etc.
                
        Returns:
            Payment result dictionary:
            {
                'success': True,
                'transaction_id': 'txn_abc123',
                'amount': Decimal('100.00'),
                'currency': 'USD',
                'status': 'succeeded',
                'created_at': '2024-01-15T10:30:00Z'
            }
            
            BREAKING CHANGE in v2.3.0:
                Now includes 'created_at' field.
                Update code that relies on dict keys!
                
        Raises:
            ValueError: If amount <= 0 or currency invalid
            PaymentMethodError: If payment method invalid/unsupported
            PaymentDeclinedError: If payment declined by issuer
            PaymentTimeoutError: If payment processing times out
                
                NOTE: TimeoutError doesn't mean payment failed!
                Always check payment status before retrying.
                See: https://docs.example.com/timeouts
                
        Examples:
            Example 1: Basic credit card payment
            
            >>> processor = PaymentProcessor(api_key='sk_test_...')
            >>> result = processor.process_payment(
            ...     amount=Decimal('99.99'),
            ...     currency='USD',
            ...     payment_method={
            ...         'type': 'card',
            ...         'number': '4111111111111111',
            ...         'exp_month': '12',
            ...         'exp_year': '2025',
            ...         'cvv': '123'
            ...     },
            ...     idempotency_key='order_12345'
            ... )
            >>> print(result['transaction_id'])
            'txn_abc123'
            
            Example 2: Apple Pay (New in v2.3.0)
            
            >>> result = processor.process_payment(
            ...     amount=Decimal('149.99'),
            ...     currency='USD',
            ...     payment_method={
            ...         'type': 'apple_pay',
            ...         'token': apple_pay_token
            ...     }
            ... )
            
            Example 3: Handling errors with retry
            
            >>> import time
            >>> 
            >>> def safe_payment(processor, amount, method, order_id):
            ...     \"\"\"Payment with retry logic.\"\"\"
            ...     max_attempts = 3
            ...     
            ...     for attempt in range(max_attempts):
            ...         try:
            ...             return processor.process_payment(
            ...                 amount=amount,
            ...                 currency='USD',
            ...                 payment_method=method,
            ...                 idempotency_key=f"order_{order_id}"
            ...             )
            ...         except PaymentTimeoutError:
            ...             # Check status before retry!
            ...             status = processor.get_payment_status(
            ...                 idempotency_key=f"order_{order_id}"
            ...             )
            ...             if status['status'] == 'succeeded':
            ...                 return status
            ...             
            ...             if attempt < max_attempts - 1:
            ...                 time.sleep(2 ** attempt)  # Exponential backoff
            ...                 continue
            ...             raise
            ...         except PaymentDeclinedError as e:
            ...             # Don't retry declined payments
            ...             raise
            
        See Also:
            refund_payment(): For refunding payments
            get_payment_status(): For checking payment status
            cancel_payment(): For canceling pending payments (v2.2.0+)
            
        Note:
            Payment processing is asynchronous. The payment may still
            be processing even after this method returns success.
            For mission-critical applications, use webhooks to get
            final payment status.
            
        Warning:
            NEVER log or store full credit card numbers!
            This violates PCI-DSS compliance.
            Always use tokenization for card storage.
        """
        pass
    
    def process_card(
        self,
        card_number: str,
        exp_month: str,
        exp_year: str,
        cvv: str,
        amount: Decimal
    ) -> bool:
        """
        Process credit card payment.
        
        .. deprecated:: 2.3.0
            This method is deprecated and will be removed in v3.0.0.
            Use :meth:`process_payment` instead.
            
        WHY DEPRECATED:
            This method has several issues:
            1. Doesn't support idempotency (can double-charge)
            2. No metadata support
            3. Only supports credit cards
            4. Returns bool instead of detailed result
            
        MIGRATION:
            Old code:
            >>> success = processor.process_card(
            ...     '4111111111111111', '12', '2025', '123',
            ...     Decimal('100.00')
            ... )
            
            New code:
            >>> result = processor.process_payment(
            ...     amount=Decimal('100.00'),
            ...     currency='USD',
            ...     payment_method={
            ...         'type': 'card',
            ...         'number': '4111111111111111',
            ...         'exp_month': '12',
            ...         'exp_year': '2025',
            ...         'cvv': '123'
            ...     },
            ...     idempotency_key='unique_key_here'
            ... )
            >>> success = result['success']
            
        Will be removed in:
            Version 3.0.0 (estimated March 2024)
        """
        warnings.warn(
            "process_card() is deprecated and will be removed in v3.0.0. "
            "Use process_payment() instead.",
            DeprecationWarning,
            stacklevel=2
        )
        # Implementation calls new method internally
        result = self.process_payment(
            amount=amount,
            currency='USD',
            payment_method={
                'type': 'card',
                'number': card_number,
                'exp_month': exp_month,
                'exp_year': exp_year,
                'cvv': cvv
            }
        )
        return result['success']
    
    def refund_payment(
        self,
        transaction_id: str,
        amount: Optional[Decimal] = None,
        reason: Optional[str] = None
    ) -> Dict[str, Union[str, bool, Decimal]]:
        """
        Refund a payment.
        
        BREAKING CHANGE in v2.3.0:
            Return type changed from bool to Dict.
            
            Before v2.3.0:
            >>> success = processor.refund(txn_id, amount)
            
            From v2.3.0:
            >>> result = processor.refund(txn_id, amount)
            >>> success = result['success']
            >>> refund_id = result['refund_id']
            
        WHY THIS CHANGED:
            Returning bool provided no information about the refund.
            Clients needed refund ID for tracking, reconciliation.
            Dict provides all necessary information.
            
        Args:
            transaction_id: Original payment transaction ID
            amount: Amount to refund (None = full refund)
                Changed in v2.1.0: Now supports partial refunds
            reason: Reason for refund (optional)
                Added in v2.2.0 for better record-keeping
                
        Returns:
            Refund result (CHANGED in v2.3.0):
            {
                'success': True,
                'refund_id': 'ref_xyz789',  # NEW in v2.3.0
                'transaction_id': 'txn_abc123',
                'amount': Decimal('100.00'),
                'status': 'succeeded',
                'created_at': '2024-01-15T11:00:00Z'  # NEW in v2.3.0
            }
            
        Examples:
            Full refund:
            >>> result = processor.refund_payment('txn_abc123')
            >>> print(result['refund_id'])
            'ref_xyz789'
            
            Partial refund (v2.1.0+):
            >>> result = processor.refund_payment(
            ...     'txn_abc123',
            ...     amount=Decimal('50.00'),
            ...     reason='Customer returned one item'
            ... )
        """
        pass

# ============================================================================
# DOCUMENTING API CHANGES
# ============================================================================

def get_user_orders(
    user_id: str,
    *,
    status: Optional[List[str]] = None,
    limit: int = 100,
    offset: int = 0,
    include_cancelled: bool = False  # NEW in v2.1.0
) -> List[Dict]:
    """
    Get orders for user.
    
    API Changes:
        v2.1.0 (2023-10-01):
            - Added 'include_cancelled' parameter
            - Default behavior CHANGED: Now excludes cancelled orders
              (previously included them)
              
        v2.0.0 (2023-06-01):
            - BREAKING: Changed return type from List[Order] to List[Dict]
            - Added pagination support (limit, offset)
            
        v1.0.0 (2023-01-01):
            - Initial release
            
    Args:
        user_id: User identifier
        status: Filter by order status (None = all statuses)
        limit: Maximum orders to return (default 100, max 1000)
            Added in v2.0.0
        offset: Number of orders to skip (for pagination)
            Added in v2.0.0
        include_cancelled: Whether to include cancelled orders
            Added in v2.1.0
            Default: False (CHANGED from v1.x where default was True)
            
    Returns:
        List of order dictionaries.
        
        BREAKING CHANGE in v2.0.0:
            Now returns List[Dict] instead of List[Order] objects.
            
        Migration guide:
            v1.x code:
            >>> orders = get_user_orders(user_id)
            >>> for order in orders:
            ...     print(order.id)  # Object attribute
            
            v2.x code:
            >>> orders = get_user_orders(user_id)
            >>> for order in orders:
            ...     print(order['id'])  # Dictionary key
            
    Examples:
        Get recent orders (excluding cancelled):
        >>> orders = get_user_orders('U001', limit=10)
        
        Include cancelled orders (new in v2.1.0):
        >>> all_orders = get_user_orders(
        ...     'U001',
        ...     include_cancelled=True
        ... )
        
        Filter by status:
        >>> shipped_orders = get_user_orders(
        ...     'U001',
        ...     status=['shipped', 'delivered']
        ... )
        
        Pagination:
        >>> page1 = get_user_orders('U001', limit=20, offset=0)
        >>> page2 = get_user_orders('U001', limit=20, offset=20)
    """
    pass
Documentation Review Checklist
Python

"""
DOCUMENTATION REVIEW CHECKLIST
==============================

Before committing code changes, verify documentation:

□ Updated Version Number
  - Incremented version in docstring
  - Updated CHANGELOG
  - Tagged in version control

□ Updated Examples
  - Examples use current API
  - Examples include new features
  - Deprecated examples removed or marked

□ Updated Type Hints
  - All new parameters have type hints
  - Return types updated
  - Generic types specified

□ Updated Exceptions
  - New exceptions documented
  - Changed exceptions noted
  - Removed exceptions deleted

□ Marked Breaking Changes
  - Used BREAKING CHANGE tag
  - Provided migration guide
  - Updated version (major bump)

□ Marked Deprecations
  - Used @deprecated decorator
  - Set removal version/date
  - Provided alternative

□ Updated Cross-References
  - "See Also" section updated
  - Links to related functions checked
  - External documentation links verified

□ Tested Documentation
  - Doctest examples run successfully
  - Code examples compile
  - Links are not broken

□ Grammar and Spelling
  - Spell-checked
  - Grammar-checked
  - Consistent terminology
"""

Professional Python Documentation: Sections 6-9
6. Consistent Style Guide
Google Style (Recommended for Most Projects)
Python

"""
Google Style Documentation Standard

Advantages:
    - Clean, readable format
    - Good for both humans and doc generators
    - Widely adopted in industry
    - Works well with Sphinx
"""

from typing import List, Dict, Optional, Union, Tuple
from decimal import Decimal
from datetime import datetime, timedelta
from pathlib import Path

class UserManager:
    """
    Manages user accounts and authentication.
    
    This class provides comprehensive user management including creation,
    authentication, password management, and account lifecycle operations.
    
    Attributes:
        database: Database connection instance
        password_hasher: Password hashing service
        email_service: Email notification service
        max_login_attempts: Maximum failed login attempts before lockout
        session_timeout: Session timeout duration in seconds
        
    Example:
        Basic usage::
        
            >>> from database import Database
            >>> from security import PasswordHasher
            >>> 
            >>> db = Database("postgresql://localhost/myapp")
            >>> hasher = PasswordHasher()
            >>> manager = UserManager(db, hasher)
            >>> 
            >>> # Create user
            >>> user = manager.create_user(
            ...     email="john@example.com",
            ...     password="SecurePass123!",
            ...     name="John Doe"
            ... )
            >>> 
            >>> # Authenticate
            >>> session = manager.authenticate(
            ...     email="john@example.com",
            ...     password="SecurePass123!"
            ... )
            >>> print(session.user_id)
            
    Note:
        All passwords are hashed using bcrypt with cost factor 12.
        Sessions are stored in Redis with automatic expiration.
        
    Warning:
        This class is NOT thread-safe. Use separate instances per thread
        or wrap calls in locks for multi-threaded environments.
    """
    
    def __init__(
        self,
        database: 'Database',
        password_hasher: 'PasswordHasher',
        email_service: Optional['EmailService'] = None,
        max_login_attempts: int = 5,
        session_timeout: int = 3600
    ):
        """
        Initialize UserManager.
        
        Args:
            database: Database instance for user storage. Must support
                transactions and have users table with schema:
                    - id: UUID primary key
                    - email: VARCHAR(255) unique
                    - password_hash: VARCHAR(255)
                    - name: VARCHAR(255)
                    - created_at: TIMESTAMP
                    - is_active: BOOLEAN
            password_hasher: Service for hashing and verifying passwords.
                Must implement PasswordHasher interface with:
                    - hash(password: str) -> str
                    - verify(password: str, hash: str) -> bool
            email_service: Optional email service for notifications.
                If None, email notifications are disabled.
            max_login_attempts: Maximum failed login attempts before
                account lockout. Must be between 3 and 10.
                Default: 5
            session_timeout: Session duration in seconds before automatic
                logout. Must be between 300 (5 min) and 86400 (24 hours).
                Default: 3600 (1 hour)
                
        Raises:
            ValueError: If max_login_attempts or session_timeout out of range
            TypeError: If database or password_hasher don't implement
                required interfaces
                
        Example:
            With all services::
            
                >>> manager = UserManager(
                ...     database=Database("postgresql://..."),
                ...     password_hasher=BcryptHasher(cost=12),
                ...     email_service=SendGridService(api_key="..."),
                ...     max_login_attempts=3,
                ...     session_timeout=7200  # 2 hours
                ... )
            
            Minimal configuration::
            
                >>> manager = UserManager(
                ...     database=db,
                ...     password_hasher=hasher
                ... )  # Uses defaults, no email
        """
        # Validation
        if not 3 <= max_login_attempts <= 10:
            raise ValueError(
                f"max_login_attempts must be 3-10, got {max_login_attempts}"
            )
        
        if not 300 <= session_timeout <= 86400:
            raise ValueError(
                f"session_timeout must be 300-86400, got {session_timeout}"
            )
        
        self.database = database
        self.password_hasher = password_hasher
        self.email_service = email_service
        self.max_login_attempts = max_login_attempts
        self.session_timeout = session_timeout
    
    def create_user(
        self,
        email: str,
        password: str,
        name: str,
        *,
        send_welcome_email: bool = True,
        metadata: Optional[Dict[str, str]] = None
    ) -> Dict[str, Union[str, datetime, bool]]:
        """
        Create a new user account.
        
        Creates user with hashed password, sends optional welcome email,
        and returns user data. Email must be unique in system.
        
        Args:
            email: User's email address. Must be valid email format and
                not already registered. Case-insensitive (stored lowercase).
            password: Plain text password. Must meet requirements:
                - Minimum 8 characters
                - At least 1 uppercase letter
                - At least 1 lowercase letter
                - At least 1 number
                - At least 1 special character (!@#$%^&*)
            name: User's full name. Must be 2-100 characters.
            send_welcome_email: Whether to send welcome email.
                Requires email_service to be configured.
                Default: True
            metadata: Optional user metadata (e.g., registration source,
                referral code, preferences). Keys must be strings,
                values converted to strings.
                
        Returns:
            Created user dictionary containing:
                - id (str): Unique user identifier (UUID)
                - email (str): User's email (lowercase)
                - name (str): User's full name
                - created_at (datetime): Account creation timestamp
                - is_active (bool): Account status (always True for new users)
                - metadata (Dict[str, str]): User metadata if provided
                
        Raises:
            ValueError: If email, password, or name fail validation.
                Specific errors:
                    - "Invalid email format: {email}"
                    - "Email already registered: {email}"
                    - "Password too weak: {reason}"
                    - "Name must be 2-100 characters"
            EmailServiceError: If send_welcome_email=True but email fails
                to send. User is still created, error is logged.
            DatabaseError: If database operation fails. User is NOT created.
                
        Example:
            Basic user creation::
            
                >>> user = manager.create_user(
                ...     email="alice@example.com",
                ...     password="SecurePass123!",
                ...     name="Alice Smith"
                ... )
                >>> print(user['id'])
                '550e8400-e29b-41d4-a716-446655440000'
                >>> print(user['email'])
                'alice@example.com'
            
            With metadata::
            
                >>> user = manager.create_user(
                ...     email="bob@example.com",
                ...     password="SecurePass123!",
                ...     name="Bob Jones",
                ...     metadata={
                ...         'source': 'google_oauth',
                ...         'referral_code': 'FRIEND20',
                ...         'language': 'en'
                ...     }
                ... )
                >>> print(user['metadata']['referral_code'])
                'FRIEND20'
            
            Error handling::
            
                >>> try:
                ...     user = manager.create_user(
                ...         email="invalid-email",
                ...         password="weak",
                ...         name="A"
                ...     )
                ... except ValueError as e:
                ...     print(f"Validation error: {e}")
                ...     # Show user-friendly error message
                Validation error: Invalid email format: invalid-email
            
        Note:
            - Passwords are never stored in plain text
            - Email is case-insensitive (stored lowercase)
            - User ID is UUID v4
            - Welcome emails are sent asynchronously (non-blocking)
            
        See Also:
            authenticate(): For user login
            update_user(): For modifying user data
            delete_user(): For account deletion
        """
        pass
    
    def authenticate(
        self,
        email: str,
        password: str,
        *,
        remember_me: bool = False,
        ip_address: Optional[str] = None
    ) -> Dict[str, Union[str, datetime]]:
        """
        Authenticate user and create session.
        
        Verifies credentials, checks account status, enforces rate limits,
        and creates authenticated session.
        
        Args:
            email: User's email address (case-insensitive)
            password: Plain text password to verify
            remember_me: If True, extends session timeout to 30 days.
                If False, uses configured session_timeout.
                Default: False
            ip_address: Client's IP address for security logging and
                rate limiting. Highly recommended for production.
                
        Returns:
            Session dictionary containing:
                - session_id (str): Unique session identifier
                - user_id (str): User's ID
                - expires_at (datetime): Session expiration time
                - created_at (datetime): Session creation time
                
        Raises:
            AuthenticationError: If credentials invalid or account locked.
                Specific subtypes:
                    - InvalidCredentialsError: Wrong email or password
                    - AccountLockedError: Too many failed attempts
                    - AccountDisabledError: Account deactivated
            RateLimitError: If too many authentication attempts from IP.
                Contains retry_after (int): Seconds until retry allowed
                
        Example:
            Standard login::
            
                >>> try:
                ...     session = manager.authenticate(
                ...         email="alice@example.com",
                ...         password="SecurePass123!",
                ...         ip_address="192.168.1.100"
                ...     )
                ...     print(f"Session: {session['session_id']}")
                ...     print(f"Expires: {session['expires_at']}")
                ... except InvalidCredentialsError:
                ...     print("Wrong email or password")
                ... except AccountLockedError as e:
                ...     print(f"Account locked. Retry in {e.retry_after}s")
                Session: sess_abc123xyz...
                Expires: 2024-01-15 11:30:00
            
            Remember me functionality::
            
                >>> session = manager.authenticate(
                ...     email="bob@example.com",
                ...     password="SecurePass123!",
                ...     remember_me=True  # 30-day session
                ... )
                >>> duration = session['expires_at'] - session['created_at']
                >>> print(f"Session lasts {duration.days} days")
                Session lasts 30 days
            
            Handling rate limits::
            
                >>> from time import sleep
                >>> 
                >>> try:
                ...     session = manager.authenticate(email, password)
                ... except RateLimitError as e:
                ...     print(f"Too many attempts. Wait {e.retry_after}s")
                ...     sleep(e.retry_after)
                ...     session = manager.authenticate(email, password)
                
        Note:
            - Failed attempts increment lockout counter
            - Account locks after max_login_attempts failures
            - Locked accounts auto-unlock after 30 minutes
            - Sessions are stored server-side (not in cookies)
            - IP-based rate limit: 10 attempts per 15 minutes
            
        Security:
            - Timing-safe password comparison prevents timing attacks
            - Failed login details logged for security monitoring
            - IP addresses used for anomaly detection
            - Sessions use cryptographically random IDs
            
        See Also:
            logout(): For ending session
            refresh_session(): For extending session
            reset_password(): For password recovery
        """
        pass

# ============================================================================
# NUMPY STYLE (For Scientific/Data Science Projects)
# ============================================================================

class DataProcessor:
    """
    Process and analyze large datasets.
    
    This class provides methods for cleaning, transforming, and analyzing
    data using vectorized operations for performance.
    
    Parameters
    ----------
    data : pandas.DataFrame or numpy.ndarray
        Input data to process. Must be 2-dimensional.
    missing_strategy : {'drop', 'mean', 'median', 'forward_fill'}, default 'mean'
        Strategy for handling missing values:
        
        - 'drop': Remove rows with missing values
        - 'mean': Replace with column mean
        - 'median': Replace with column median
        - 'forward_fill': Use previous valid value
        
    normalize : bool, default True
        Whether to normalize data to [0, 1] range
    n_jobs : int, default -1
        Number of parallel jobs. -1 uses all CPU cores.
        
    Attributes
    ----------
    data_ : pandas.DataFrame
        Processed data after transformations
    missing_count_ : int
        Number of missing values found
    is_fitted_ : bool
        Whether processor has been fitted to data
        
    Examples
    --------
    Basic usage with pandas DataFrame:
    
    >>> import pandas as pd
    >>> import numpy as np
    >>> 
    >>> # Create sample data
    >>> df = pd.DataFrame({
    ...     'age': [25, 30, np.nan, 45, 50],
    ...     'income': [50000, 60000, 55000, np.nan, 80000],
    ...     'score': [7.5, 8.0, 6.5, 9.0, 8.5]
    ... })
    >>> 
    >>> # Process data
    >>> processor = DataProcessor(
    ...     data=df,
    ...     missing_strategy='mean',
    ...     normalize=True
    ... )
    >>> processed = processor.fit_transform()
    >>> print(processed.head())
           age    income     score
    0  0.000000  0.000000  0.500000
    1  0.200000  0.333333  0.750000
    2  0.366667  0.166667  0.000000
    3  0.800000  1.000000  1.000000
    4  1.000000  1.000000  0.750000
    
    Using different missing value strategies:
    
    >>> # Drop missing values
    >>> proc1 = DataProcessor(df, missing_strategy='drop')
    >>> result1 = proc1.fit_transform()
    >>> print(len(result1))  # Fewer rows
    3
    >>> 
    >>> # Use median
    >>> proc2 = DataProcessor(df, missing_strategy='median')
    >>> result2 = proc2.fit_transform()
    >>> print(result2.isnull().sum())  # No missing values
    age       0
    income    0
    score     0
    dtype: int64
    
    Notes
    -----
    The processor uses the following normalization formula:
    
    .. math::
        x_{norm} = \\frac{x - x_{min}}{x_{max} - x_{min}}
    
    For missing value imputation with mean:
    
    .. math::
        x_{missing} = \\frac{1}{n} \\sum_{i=1}^{n} x_i
    
    where n is the number of non-missing values.
    
    Performance scales linearly with data size for most operations.
    Memory usage is approximately 3x the input data size during processing.
    
    See Also
    --------
    sklearn.preprocessing.StandardScaler : Alternative normalization
    pandas.DataFrame.fillna : Direct missing value filling
    
    References
    ----------
    .. [1] McKinney, W. (2010). "Data Structures for Statistical Computing 
           in Python", Proceedings of the 9th Python in Science Conference.
    .. [2] Harris, C.R., Millman, K.J., van der Walt, S.J. et al. (2020).
           "Array programming with NumPy", Nature 585, 357–362.
    """
    
    def fit_transform(
        self,
        X: Optional[np.ndarray] = None
    ) -> pd.DataFrame:
        """
        Fit processor to data and transform it.
        
        Combines fit() and transform() in single call for convenience.
        Learns parameters from data and applies transformation.
        
        Parameters
        ----------
        X : numpy.ndarray, shape (n_samples, n_features), optional
            Alternative data to process. If None, uses data from __init__.
            Must have same number of features as initialization data.
            
        Returns
        -------
        transformed : pandas.DataFrame, shape (n_samples, n_features)
            Processed data with:
            - Missing values handled per missing_strategy
            - Values normalized to [0, 1] if normalize=True
            - Same column names as input
            
        Raises
        ------
        ValueError
            If X has different number of features than initialization data.
            If all values in a column are missing (cannot impute).
        RuntimeError
            If processor already fitted and fit_transform called again.
            Use transform() for already-fitted processor.
            
        Examples
        --------
        Single call processing:
        
        >>> data = np.array([[1, 2], [3, 4], [5, 6]])
        >>> processor = DataProcessor(data)
        >>> result = processor.fit_transform()
        >>> print(result)
             0    1
        0  0.0  0.0
        1  0.5  0.5
        2  1.0  1.0
        
        Processing new data with same parameters:
        
        >>> new_data = np.array([[2, 3], [4, 5]])
        >>> result = processor.transform(new_data)
        
        Chaining operations:
        
        >>> result = (
        ...     DataProcessor(data, missing_strategy='drop')
        ...     .fit_transform()
        ...     .pipe(lambda df: df[df['age'] > 30])
        ... )
        
        Notes
        -----
        This method is NOT idempotent. Calling it multiple times will
        raise RuntimeError. Use transform() for additional data.
        
        The method internally calls:
        1. _validate_data() - Check data format
        2. _handle_missing() - Impute missing values
        3. _normalize() - Scale to [0, 1] if requested
        
        See Also
        --------
        fit : Learn parameters without transforming
        transform : Transform using learned parameters
        """
        pass

# ============================================================================
# SPHINX STYLE (For Documentation-Heavy Projects)
# ============================================================================

class CacheManager:
    """
    Manages application caching with TTL and eviction policies.
    
    The cache manager provides a unified interface for caching data
    with automatic expiration, size limits, and multiple eviction
    strategies (LRU, LFU, FIFO).
    
    :param backend: Cache backend ('memory', 'redis', 'memcached')
    :type backend: str
    :param max_size: Maximum number of items in cache
    :type max_size: int
    :param default_ttl: Default time-to-live in seconds
    :type default_ttl: int
    :param eviction_policy: Policy for removing items ('lru', 'lfu', 'fifo')
    :type eviction_policy: str
    :param serializer: Optional custom serializer for values
    :type serializer: Optional[Callable]
    
    :raises ValueError: If backend not recognized or parameters invalid
    :raises ConnectionError: If unable to connect to remote cache backend
    
    .. note::
        Redis and Memcached backends require additional dependencies:
        
        * Redis: ``pip install redis``
        * Memcached: ``pip install pymemcache``
    
    .. warning::
        In-memory backend does NOT persist across process restarts.
        Use Redis or Memcached for distributed caching.
    
    :Example:
    
    Initialize with memory backend::
    
        >>> cache = CacheManager(
        ...     backend='memory',
        ...     max_size=1000,
        ...     default_ttl=3600,
        ...     eviction_policy='lru'
        ... )
        >>> cache.set('key', 'value')
        >>> print(cache.get('key'))
        'value'
    
    Using Redis backend::
    
        >>> cache = CacheManager(
        ...     backend='redis',
        ...     max_size=10000,
        ...     default_ttl=7200,
        ...     connection_url='redis://localhost:6379/0'
        ... )
    
    .. seealso::
       :class:`RedisBackend`
          Redis-specific cache implementation
       :class:`MemcachedBackend`
          Memcached-specific cache implementation
    """
    
    def get(
        self,
        key: str,
        default: Optional[Any] = None
    ) -> Optional[Any]:
        """
        Retrieve value from cache.
        
        Returns cached value if exists and not expired. Otherwise returns
        default value. Updates access time for LRU eviction.
        
        :param key: Cache key to retrieve
        :type key: str
        :param default: Value to return if key not found
        :type default: Any, optional
        
        :returns: Cached value or default if not found
        :rtype: Any
        
        :raises TypeError: If key is not a string
        :raises CacheError: If cache backend unavailable
        
        :Example:
        
        Basic retrieval::
        
            >>> cache.set('user:1', {'name': 'Alice', 'age': 30})
            >>> user = cache.get('user:1')
            >>> print(user['name'])
            'Alice'
        
        With default value::
        
            >>> value = cache.get('nonexistent', default='not found')
            >>> print(value)
            'not found'
        
        Safe retrieval with type checking::
        
            >>> user = cache.get('user:1')
            >>> if user and isinstance(user, dict):
            ...     print(f"User: {user['name']}")
            ... else:
            ...     print("User not in cache")
        
        .. note::
            Getting a key updates its access time for LRU eviction,
            making it less likely to be evicted.
        
        .. seealso::
           :meth:`set`
              Store value in cache
           :meth:`get_many`
              Retrieve multiple keys at once
        """
        pass

# ============================================================================
# CONSISTENT FORMATTING RULES
# ============================================================================

def format_money(
    amount: Decimal,
    currency: str = "USD",
    locale: str = "en_US"
) -> str:
    """
    Format monetary amount for display.
    
    FORMATTING CONVENTIONS:
    ----------------------
    1. All parameters documented in consistent order:
       - Required parameters first
       - Optional parameters with defaults after
       - Use same order in docstring and signature
       
    2. Type hints always included:
       - Parameters: amount: Decimal
       - Returns: -> str
       - Use typing module for complex types
       
    3. Descriptions always end with period.
    
    4. Examples always use >>> prompt.
    
    5. Raises section lists exceptions alphabetically.
    
    6. Cross-references use :meth:, :class:, :func:.
    
    Args:
        amount: Monetary amount to format. Must be non-negative.
            Use Decimal for precision in financial calculations.
        currency: ISO 4217 currency code (e.g., 'USD', 'EUR', 'GBP').
            Default: 'USD'
        locale: Locale for formatting (e.g., 'en_US', 'de_DE', 'ja_JP').
            Determines decimal separator, thousands separator, symbol placement.
            Default: 'en_US'
            
    Returns:
        Formatted currency string with appropriate symbol and separators.
        Examples:
            - US: '$1,234.56'
            - EU: '1.234,56 €'
            - JP: '¥1,235'
            
    Raises:
        ValueError: If amount is negative or currency code invalid.
        LocaleError: If locale not supported or not installed.
        
    Examples:
        US Dollar formatting::
        
            >>> format_money(Decimal('1234.56'))
            '$1,234.56'
            >>> format_money(Decimal('0.99'))
            '$0.99'
        
        European formatting::
        
            >>> format_money(Decimal('1234.56'), 'EUR', 'de_DE')
            '1.234,56 €'
        
        Japanese Yen (no decimals)::
        
            >>> format_money(Decimal('1234.56'), 'JPY', 'ja_JP')
            '¥1,235'
        
    Note:
        - Rounds to currency's decimal places (2 for USD, 0 for JPY)
        - Uses locale-specific formatting rules
        - Thread-safe for read operations
        
    See Also:
        parse_money(): Parse formatted money string back to Decimal
        Money: Value object for monetary amounts
    """
    pass
7. Edge Cases & Limitations
Comprehensive Edge Case Documentation
Python

from typing import List, Optional, Union
from decimal import Decimal, InvalidOperation
from datetime import datetime, date
import math

class Calculator:
    """
    Scientific calculator with comprehensive edge case handling.
    """
    
    def divide(
        self,
        numerator: Union[int, float, Decimal],
        denominator: Union[int, float, Decimal]
    ) -> Decimal:
        """
        Divide two numbers with edge case handling.
        
        Args:
            numerator: Number to divide
            denominator: Number to divide by
            
        Returns:
            Result of division as Decimal
            
        Raises:
            ZeroDivisionError: If denominator is zero
            ValueError: If either operand is infinity or NaN
            OverflowError: If result would overflow Decimal range
            
        Edge Cases:
            **Zero Division:**
                >>> calc.divide(10, 0)
                Traceback (most recent call last):
                    ...
                ZeroDivisionError: Cannot divide by zero
                
                >>> calc.divide(0, 0)
                Traceback (most recent call last):
                    ...
                ZeroDivisionError: Cannot divide by zero (0/0 is undefined)
            
            **Very Small Numbers:**
                >>> calc.divide(1, 10**50)
                Decimal('1E-50')  # Maintains precision
                
                >>> calc.divide(1, 10**100)
                Decimal('0')  # Underflow to zero
            
            **Very Large Numbers:**
                >>> calc.divide(10**100, 0.0001)
                Decimal('1E+104')
                
                >>> calc.divide(10**500, 0.0001)
                Traceback (most recent call last):
                    ...
                OverflowError: Result too large for Decimal
            
            **Negative Numbers:**
                >>> calc.divide(-10, 3)
                Decimal('-3.333333333333333333333333333')
                
                >>> calc.divide(10, -3)
                Decimal('-3.333333333333333333333333333')
                
                >>> calc.divide(-10, -3)
                Decimal('3.333333333333333333333333333')
            
            **Special Float Values:**
                >>> calc.divide(float('inf'), 2)
                Traceback (most recent call last):
                    ...
                ValueError: Cannot divide infinity
                
                >>> calc.divide(float('nan'), 2)
                Traceback (most recent call last):
                    ...
                ValueError: Cannot divide NaN (not a number)
            
            **Type Mixing:**
                >>> calc.divide(10, 3)  # int / int
                Decimal('3.333333333333333333333333333')
                
                >>> calc.divide(10.0, 3)  # float / int
                Decimal('3.333333333333333333333333333')
                
                >>> calc.divide(Decimal('10'), 3)  # Decimal / int
                Decimal('3.333333333333333333333333333')
            
        Limitations:
            - Maximum precision: 28 decimal places
            - Maximum exponent: 999,999,999
            - Minimum exponent: -999,999,999
            - Cannot represent true infinity
            - Cannot represent NaN (raises error instead)
            
        Performance:
            - Simple division: O(1)
            - Large number division: O(n) where n is digit count
            - Typical performance: < 1μs for normal numbers
        """
        pass
    
    def sqrt(self, n: Union[int, float, Decimal]) -> Decimal:
        """
        Calculate square root.
        
        Args:
            n: Number to calculate square root of
            
        Returns:
            Square root as Decimal
            
        Raises:
            ValueError: If n is negative
            
        Edge Cases:
            **Zero:**
                >>> calc.sqrt(0)
                Decimal('0')  # sqrt(0) = 0
            
            **Perfect Squares:**
                >>> calc.sqrt(4)
                Decimal('2')
                
                >>> calc.sqrt(100)
                Decimal('10')
            
            **Non-Perfect Squares:**
                >>> calc.sqrt(2)
                Decimal('1.414213562373095048801688724')  # Precise
                
                >>> calc.sqrt(3)
                Decimal('1.732050807568877293527446342')
            
            **Very Small Numbers:**
                >>> calc.sqrt(1e-100)
                Decimal('1E-50')  # Maintains precision
                
                >>> calc.sqrt(0.0001)
                Decimal('0.01')
            
            **Very Large Numbers:**
                >>> calc.sqrt(10**100)
                Decimal('1E+50')
                
                >>> calc.sqrt(10**500)
                Decimal('1E+250')
            
            **Negative Numbers:**
                >>> calc.sqrt(-1)
                Traceback (most recent call last):
                    ...
                ValueError: Cannot calculate square root of negative number
                
                Complex numbers not supported. Use:
                    - cmath.sqrt() for complex results
                    - abs(n) for magnitude only
            
            **Precision Near Integer:**
                >>> result = calc.sqrt(4.0000000001)
                >>> print(result)
                Decimal('2.000000000124999999609375')
                
                >>> result = calc.sqrt(3.9999999999)
                >>> print(result)
                Decimal('1.999999999975000000003125')
            
        Limitations:
            - Does not support complex numbers (no imaginary results)
            - Precision decreases for very large numbers (> 10^100)
            - Newton's method used (iterative, not exact for irrational)
            - Maximum iterations: 100 (prevents infinite loops)
            
        Algorithm:
            Uses Newton's method:
                x_{n+1} = (x_n + n/x_n) / 2
                
            Converges quadratically for positive numbers.
            Typically converges in 5-10 iterations.
            
        Performance:
            - Perfect squares: O(1)
            - Other numbers: O(log n) iterations
            - Large numbers: O(n) per iteration where n is digits
        """
        pass

class DateRange:
    """
    Represents a range of dates with edge case handling.
    """
    
    def __init__(self, start: date, end: date):
        """
        Create date range.
        
        Args:
            start: Range start date (inclusive)
            end: Range end date (inclusive)
            
        Raises:
            ValueError: If end is before start
            TypeError: If start or end not date objects
            
        Edge Cases:
            **Single Day Range:**
                >>> range1 = DateRange(date(2024, 1, 1), date(2024, 1, 1))
                >>> list(range1)
                [datetime.date(2024, 1, 1)]  # One day
            
            **Leap Year Handling:**
                >>> range2 = DateRange(date(2024, 2, 28), date(2024, 3, 1))
                >>> list(range2)
                [datetime.date(2024, 2, 28),
                 datetime.date(2024, 2, 29),  # Leap day included!
                 datetime.date(2024, 3, 1)]
                
                >>> range3 = DateRange(date(2023, 2, 28), date(2023, 3, 1))
                >>> list(range3)
                [datetime.date(2023, 2, 28),
                 datetime.date(2023, 3, 1)]  # No Feb 29 in 2023
            
            **Year Boundaries:**
                >>> range4 = DateRange(date(2023, 12, 30), date(2024, 1, 2))
                >>> list(range4)
                [datetime.date(2023, 12, 30),
                 datetime.date(2023, 12, 31),  # Year boundary
                 datetime.date(2024, 1, 1),
                 datetime.date(2024, 1, 2)]
            
            **Month Boundaries:**
                >>> range5 = DateRange(date(2024, 1, 30), date(2024, 2, 2))
                >>> list(range5)
                [datetime.date(2024, 1, 30),
                 datetime.date(2024, 1, 31),  # Month boundary
                 datetime.date(2024, 2, 1),
                 datetime.date(2024, 2, 2)]
            
            **Very Long Ranges:**
                >>> range6 = DateRange(date(2000, 1, 1), date(2024, 12, 31))
                >>> len(list(range6))
                9131  # 25 years (including leap days)
                
                WARNING: Iterating very long ranges consumes memory!
                Use contains() check instead of generating full list.
            
            **Historical Dates:**
                >>> range7 = DateRange(date(1900, 1, 1), date(1900, 12, 31))
                >>> len(list(range7))
                365  # 1900 was NOT a leap year
                
                NOTE: 1900 not divisible by 400, so not leap year
                despite being divisible by 4.
            
            **Invalid Ranges:**
                >>> DateRange(date(2024, 1, 10), date(2024, 1, 5))
                Traceback (most recent call last):
                    ...
                ValueError: End date must be >= start date
        
        Limitations:
            - Only supports date objects (not datetime)
            - Cannot represent infinite ranges
            - Memory usage: O(n) where n is number of days
            - Performance degrades for ranges > 100,000 days
            - Does not account for time zones (date only)
            - Does not handle business days (includes weekends)
            
        Known Issues:
            1. **DST Transitions:** Not applicable (date-only)
            2. **Leap Seconds:** Not handled (Python datetime limitation)
            3. **Julian Calendar:** Only Gregorian calendar supported
        """
        pass

class StringProcessor:
    """
    String processing with unicode and encoding edge cases.
    """
    
    def truncate(
        self,
        text: str,
        max_length: int,
        suffix: str = "..."
    ) -> str:
        """
        Truncate string to maximum length.
        
        Args:
            text: String to truncate
            max_length: Maximum length (including suffix)
            suffix: String to append when truncated
            
        Returns:
            Truncated string
            
        Edge Cases:
            **ASCII Text:**
                >>> processor.truncate("Hello World", 8)
                'Hello...'
                
                >>> processor.truncate("Hello", 10)
                'Hello'  # No truncation needed
            
            **Empty/Small Strings:**
                >>> processor.truncate("", 10)
                ''  # Empty string unchanged
                
                >>> processor.truncate("Hi", 10)
                'Hi'  # Shorter than max
                
                >>> processor.truncate("Hello", 3)
                '...'  # Only room for suffix
                
                >>> processor.truncate("Hello", 2)
                Traceback (most recent call last):
                    ...
                ValueError: max_length must be >= len(suffix)
            
            **Unicode Characters:**
                >>> processor.truncate("Hello 世界", 8)
                'Hello...'  # Correctly counts unicode chars
                
                >>> processor.truncate("🎉🎊🎈🎁", 3)
                '🎉...'  # Emojis are single characters
                
                >>> processor.truncate("Café", 4)
                'Café'  # é is one character
            
            **Combining Characters:**
                >>> text = "e\u0301"  # é as e + combining acute
                >>> processor.truncate(text, 1)
                '...'  # Counts as 2 characters!
                
                NOTE: This is Python limitation. Consider using
                unicodedata.normalize() first:
                    >>> import unicodedata
                    >>> normalized = unicodedata.normalize('NFC', text)
                    >>> processor.truncate(normalized, 1)
                    'é'
            
            **Zero-Width Characters:**
                >>> text = "Hello\u200B\u200BWorld"  # Zero-width spaces
                >>> processor.truncate(text, 8)
                'Hello\u200B\u200B...'
                
                NOTE: Zero-width chars count toward length!
                May want to strip them first:
                    >>> import re
                    >>> clean = re.sub(r'[\u200B-\u200D\uFEFF]', '', text)
            
            **Surrogate Pairs:**
                >>> text = "𝕳𝖊𝖑𝖑𝖔"  # Mathematical bold text
                >>> processor.truncate(text, 3)
                '𝕳...'  # Each char is surrogate pair
                
                >>> len(text)
                5  # Length is correct
                
                >>> len(text.encode('utf-16'))
                12  # But encoding size differs!
            
            **Whitespace:**
                >>> processor.truncate("Hello   World", 8)
                'Hello...'  # Preserves spaces
                
                >>> processor.truncate("   Hello", 8)
                '   H...'  # Preserves leading spaces
            
            **Custom Suffix:**
                >>> processor.truncate("Hello World", 10, " [more]")
                'Hel [more]'
                
                >>> processor.truncate("Hello World", 10, "")
                'Hello Worl'  # No suffix
            
        Limitations:
            - Counts by characters, not display width
            - Doesn't account for combining characters properly
            - Doesn't handle right-to-left text specially
            - Doesn't prevent truncation mid-word (see truncate_words())
            - Maximum string length: 2^31 - 1 characters (Python limit)
            
        Gotchas:
            1. **Display Width:** Some characters (CJK) take 2 columns:
                >>> processor.truncate("你好世界", 3)
                '你...'  # Only 1 CJK char fits visually
                
            2. **Grapheme Clusters:** Emojis with modifiers:
                >>> processor.truncate("👨‍👩‍👧‍👦", 2)  # Family emoji
                '👨...'  # Splits multi-char emoji!
                
            3. **Normalization:** Same visual, different encoding:
                >>> "é" == "é"  # Might be False!
                False
                >>> len("é"), len("é")
                (1, 2)  # Different lengths!
        
        See Also:
            truncate_words(): Truncate at word boundaries
            truncate_bytes(): Truncate by byte count
        """
        pass

class FileHandler:
    """
    File operations with comprehensive edge case handling.
    """
    
    def read_file(
        self,
        filepath: Union[str, Path],
        encoding: str = 'utf-8'
    ) -> str:
        """
        Read entire file into string.
        
        Args:
            filepath: Path to file
            encoding: Character encoding
            
        Returns:
            File contents as string
            
        Edge Cases:
            **Empty Files:**
                >>> handler.read_file('empty.txt')
                ''  # Empty string, not None
            
            **Missing Files:**
                >>> handler.read_file('nonexistent.txt')
                Traceback (most recent call last):
                    ...
                FileNotFoundError: [Errno 2] No such file: 'nonexistent.txt'
            
            **Permission Denied:**
                >>> handler.read_file('/root/secret.txt')
                Traceback (most recent call last):
                    ...
                PermissionError: [Errno 13] Permission denied: '/root/secret.txt'
            
            **Directories:**
                >>> handler.read_file('/tmp')
                Traceback (most recent call last):
                    ...
                IsADirectoryError: [Errno 21] Is a directory: '/tmp'
            
            **Symbolic Links:**
                >>> # symlink.txt -> target.txt
                >>> handler.read_file('symlink.txt')
                'Target file contents'  # Follows symlink
                
                >>> # broken_link.txt -> missing.txt
                >>> handler.read_file('broken_link.txt')
                Traceback (most recent call last):
                    ...
                FileNotFoundError: [Errno 2] No such file: 'missing.txt'
            
            **Encoding Issues:**
                >>> # File contains bytes: b'\xff\xfe'
                >>> handler.read_file('utf16.txt', encoding='utf-8')
                Traceback (most recent call last):
                    ...
                UnicodeDecodeError: 'utf-8' codec can't decode...
                
                >>> # Use correct encoding
                >>> handler.read_file('utf16.txt', encoding='utf-16')
                'Contents in UTF-16'
                
                >>> # Unknown encoding - use binary
                >>> handler.read_file('unknown.txt', encoding='latin-1')
                # Always succeeds (all bytes valid in latin-1)
            
            **Large Files:**
                >>> # 10 GB file
                >>> handler.read_file('huge.log')
                Traceback (most recent call last):
                    ...
                MemoryError: Cannot allocate 10GB for file
                
                SOLUTION: Use read_file_chunked() for large files
            
            **Special Files:**
                >>> handler.read_file('/dev/random')
                # Blocks forever! /dev/random is infinite
                
                >>> handler.read_file('/proc/cpuinfo')
                'processor\t: 0\n...'  # Works on Linux
                
                >>> handler.read_file('COM1')
                # Blocks on Windows! Serial port read
            
            **Race Conditions:**
                >>> # Thread 1 checks file exists
                >>> if os.path.exists('data.txt'):
                ...     # Thread 2 deletes file here!
                ...     content = handler.read_file('data.txt')
                Traceback (most recent call last):
                    ...
                FileNotFoundError: ...
                
                SOLUTION: Use try/except, not pre-check
            
            **Line Endings:**
                >>> # File has Windows line endings (\r\n)
                >>> content = handler.read_file('windows.txt')
                >>> '\r\n' in content
                False  # Python converts to \n on text mode read!
                
                >>> # To preserve original:
                >>> content = handler.read_file('windows.txt', newline='')
                >>> '\r\n' in content
                True
            
        Limitations:
            - Reads entire file into memory (not suitable for large files)
            - No progress reporting for large files
            - No timeout for slow filesystems
            - Follows symbolic links (can't read link itself)
            - Cannot read from stdin/stdout (use sys.stdin.read())
            - Maximum file size: Available memory
            
        Performance:
            - Small files (< 1MB): < 1ms
            - Medium files (1-100MB): 10-100ms
            - Large files (> 100MB): May cause MemoryError
            - Network filesystems: Unpredictable latency
            
        Security:
            - Path traversal possible: '../../../etc/passwd'
            - Symlink attacks possible in shared directories
            - No sandboxing - can read any accessible file
            - Encoding attacks possible with invalid sequences
            
        See Also:
            read_file_chunked(): For large files
            read_binary(): For binary files
            safe_read(): With path validation
        """
        pass
8. Warnings for Dangerous Operations
Comprehensive Warning Documentation
Python

from typing import Any, Dict, List, Optional
from decimal import Decimal
import warnings
import threading
import pickle

class Database:
    """
    Database operations with comprehensive safety warnings.
    """
    
    def execute_raw_sql(
        self,
        query: str,
        params: Optional[Dict[str, Any]] = None
    ) -> List[Dict[str, Any]]:
        """
        Execute raw SQL query.
        
        .. danger::
            **SQL INJECTION RISK!**
            
            This method executes raw SQL directly. Using user input in the
            query string creates SQL injection vulnerability:
            
            **NEVER DO THIS:**
            >>> user_input = request.GET['username']
            >>> query = f"SELECT * FROM users WHERE username = '{user_input}'"
            >>> db.execute_raw_sql(query)  # VULNERABLE!
            
            An attacker could input: ``admin' OR '1'='1``
            Resulting query: ``SELECT * FROM users WHERE username = 'admin' OR '1'='1'``
            Returns all users!
            
            **ALWAYS USE PARAMETERIZED QUERIES:**
            >>> query = "SELECT * FROM users WHERE username = :username"
            >>> db.execute_raw_sql(query, {'username': user_input})  # SAFE
        
        Args:
            query: SQL query string. Use :param_name for parameters.
            params: Dictionary of query parameters.
            
        Returns:
            List of result rows as dictionaries.
            
        Warnings:
            **SQL Injection:**
                Never concatenate user input into queries.
                Always use parameterized queries with params argument.
                
            **Performance:**
                Raw queries bypass ORM caching and optimizations.
                May create N+1 query problems.
                Consider using ORM methods when possible.
                
            **Maintainability:**
                String queries are harder to maintain and refactor.
                Database schema changes can silently break queries.
                No compile-time query validation.
                
            **Portability:**
                Raw SQL may not be portable across databases.
                PostgreSQL, MySQL, SQLite have different syntax.
                
        Examples:
            Safe parameterized query::
            
                >>> query = '''
                ...     SELECT id, email, name
                ...     FROM users
                ...     WHERE created_at > :start_date
                ...     AND is_active = :active
                ... '''
                >>> results = db.execute_raw_sql(
                ...     query,
                ...     {
                ...         'start_date': '2024-01-01',
                ...         'active': True
                ...     }
                ... )
            
            Multiple parameters::
            
                >>> query = '''
                ...     INSERT INTO orders (user_id, total, status)
                ...     VALUES (:user_id, :total, :status)
                ... '''
                >>> db.execute_raw_sql(
                ...     query,
                ...     {
                ...         'user_id': 123,
                ...         'total': Decimal('99.99'),
                ...         'status': 'pending'
                ...     }
                ... )
            
        Security Checklist:
            ☐ Using parameterized queries (not string formatting)
            ☐ Validated all user input before params
            ☐ Not exposing raw query in error messages to users
            ☐ Logged all queries for audit trail
            ☐ Using least-privilege database user
            ☐ Set query timeout to prevent DOS
            
        See Also:
            User.objects.filter(): ORM alternative (safer)
            execute_stored_procedure(): For complex operations
            
        Note:
            This method should only be used when ORM cannot express
            the query efficiently (e.g., complex analytics, bulk operations).
        """
        pass
    
    def drop_table(self, table_name: str) -> None:
        """
        Drop database table.
        
        .. danger::
            **IRREVERSIBLE DATA LOSS!**
            
            This operation permanently deletes all data in the table.
            There is NO undo. Backups may be the only recovery option.
            
        .. warning::
            **CASCADE DELETION:**
            
            Dropping a table may cascade delete related data:
            - Foreign key references will fail or cascade
            - Views depending on table will become invalid
            - Stored procedures using table will break
            - Triggers on table will be deleted
            
        Args:
            table_name: Name of table to drop.
            
        Raises:
            ValueError: If table_name contains suspicious characters
                (potential SQL injection attempt).
            DatabaseError: If table has dependencies or doesn't exist.
            
        Warnings:
            **Before Calling This Method:**
                1. ⚠️  Backup the database
                2. ⚠️  Verify table name is correct
                3. ⚠️  Check for dependent tables/views
                4. ⚠️  Ensure you have recent backup
                5. ⚠️  Consider using soft delete instead
                6. ⚠️  Test on development database first
                7. ⚠️  Get approval from DBA/team lead
                8. ⚠️  Schedule during maintenance window
                
            **Production Safeguards:**
                - Require two-factor authentication
                - Require manual confirmation of table name
                - Log operation to audit trail
                - Send alert to admin team
                - Create automatic backup before drop
                
        Examples:
            Safe approach with checks::
            
                >>> # 1. Verify table exists and is safe to drop
                >>> tables = db.list_tables()
                >>> assert 'old_temp_data' in tables
                >>> 
                >>> # 2. Create backup
                >>> db.backup_table('old_temp_data', 'old_temp_data_backup')
                >>> 
                >>> # 3. Check dependencies
                >>> deps = db.get_table_dependencies('old_temp_data')
                >>> assert len(deps) == 0, f"Table has dependencies: {deps}"
                >>> 
                >>> # 4. Manual confirmation
                >>> confirmation = input(f"Type table name to confirm: ")
                >>> assert confirmation == 'old_temp_data'
                >>> 
                >>> # 5. Actually drop
                >>> db.drop_table('old_temp_data')
                >>> 
                >>> # 6. Verify drop succeeded
                >>> assert 'old_temp_data' not in db.list_tables()
            
            Better alternative - soft delete::
            
                >>> # Instead of dropping, mark as inactive
                >>> db.execute_raw_sql(
                ...     "ALTER TABLE old_data RENAME TO _archived_old_data"
                ... )
                >>> # Can still access if needed, but hidden from normal queries
            
        Dangerous Patterns to Avoid:
            **NEVER accept user input for table name:**
            >>> user_table = request.GET['table']  # DANGEROUS!
            >>> db.drop_table(user_table)  # Could drop any table!
            
            **NEVER drop tables in production without backup:**
            >>> if environment == 'production':
            ...     db.drop_table('users')  # NEVER DO THIS!
            
            **NEVER drop tables in automated scripts without safeguards:**
            >>> for table in tables_to_cleanup:
            ...     db.drop_table(table)  # What if list is wrong?!
            
        Recovery Options:
            If you accidentally dropped a table:
                1. STOP all writes to database immediately
                2. Restore from most recent backup
                3. Use transaction log replay (if available)
                4. Contact DBA for point-in-time recovery
                5. Check if cloud provider has automatic snapshots
                
        Alternative Approaches:
            Instead of dropping tables, consider:
            
            1. **Truncate:** Keep table structure, delete data
               >>> db.execute_raw_sql("TRUNCATE TABLE old_data")
               
            2. **Rename:** Hide table but keep data
               >>> db.rename_table('old_data', '_archived_old_data')
               
            3. **Soft Delete:** Add deleted_at column
               >>> db.add_column('users', 'deleted_at', 'TIMESTAMP')
               >>> db.execute_raw_sql(
               ...     "UPDATE users SET deleted_at = NOW() WHERE ..."
               ... )
               
            4. **Archive:** Move to separate database
               >>> db.export_table('old_data', 'archive_db.old_data')
               >>> db.drop_table('old_data')
        
        See Also:
            truncate_table(): Delete data but keep structure
            rename_table(): Rename instead of drop
            backup_table(): Create backup
        """
        pass

class CacheManager:
    """
    Caching with thread safety warnings.
    """
    
    def __init__(self):
        """
        Initialize cache manager.
        
        .. warning::
            **NOT THREAD-SAFE BY DEFAULT!**
            
            This cache implementation uses a simple dictionary and is
            NOT thread-safe. Concurrent access can cause:
            
            1. **Data Corruption:**
                >>> # Thread 1
                >>> cache['key'] = {'count': 0}
                >>> # Thread 2 (concurrent)
                >>> cache['key'] = {'count': 1}
                >>> # Result: Unpredictable! Lost update.
            
            2. **Race Conditions:**
                >>> # Both threads check simultaneously
                >>> if 'key' not in cache:  # Both see False
                ...     cache['key'] = expensive_operation()  # Both execute!
            
            3. **Dictionary Iteration Errors:**
                >>> # Thread 1 iterates
                >>> for key in cache:
                ...     # Thread 2 modifies during iteration
                ...     cache['new_key'] = 'value'
                RuntimeError: dictionary changed size during iteration
            
            **SOLUTIONS:**
            
            Option 1: Use locks (manual synchronization)::
            
                >>> import threading
                >>> cache_lock = threading.Lock()
                >>> 
                >>> with cache_lock:
                ...     cache['key'] = 'value'
            
            Option 2: Use thread-safe cache::
            
                >>> from threading import Lock
                >>> class ThreadSafeCache(CacheManager):
                ...     def __init__(self):
                ...         super().__init__()
                ...         self._lock = Lock()
                ...     
                ...     def set(self, key, value):
                ...         with self._lock:
                ...             return super().set(key, value)
            
            Option 3: Use multiprocessing.Manager for multi-process::
            
                >>> from multiprocessing import Manager
                >>> manager = Manager()
                >>> cache = manager.dict()  # Process-safe
            
            Option 4: Use Redis for distributed caching::
            
                >>> import redis
                >>> cache = redis.Redis(host='localhost', port=6379)
                >>> cache.set('key', 'value')  # Thread & process safe
        """
        self._cache: Dict[str, Any] = {}
    
    def get_or_compute(
        self,
        key: str,
        compute_func: Callable[[], Any]
    ) -> Any:
        """
        Get cached value or compute if missing.
        
        .. warning::
            **RACE CONDITION RISK!**
            
            This method has a race condition in multi-threaded environments:
            
            **Problem:**
            >>> def expensive_operation():
            ...     time.sleep(10)  # Expensive
            ...     return "result"
            >>> 
            >>> # Thread 1 checks cache
            >>> if key not in cache:  # Miss
            ...     # Thread 2 checks cache here (also miss!)
            ...     result = expensive_operation()  # Thread 1 computes
            ...     # Thread 2 also computes! Wasted work!
            ...     cache[key] = result
            
            **Solution - Use lock:**
            >>> from threading import Lock
            >>> compute_locks = {}
            >>> locks_lock = Lock()
            >>> 
            >>> def safe_get_or_compute(key, compute_func):
            ...     # Get or create lock for this key
            ...     with locks_lock:
            ...         if key not in compute_locks:
            ...             compute_locks[key] = Lock()
            ...         lock = compute_locks[key]
            ...     
            ...     # Check cache under lock
            ...     with lock:
            ...         if key in cache:
            ...             return cache[key]
            ...         
            ...         # Only one thread computes
            ...         result = compute_func()
            ...         cache[key] = result
            ...         return result
            
        Args:
            key: Cache key
            compute_func: Function to compute value if cache miss
            
        Returns:
            Cached or computed value
            
        Warnings:
            - May compute same value multiple times concurrently
            - No timeout on compute_func (could hang forever)
            - No exception handling (failed compute = no cache)
            - Unbounded cache size (memory leak risk)
            
        See Also:
            ThreadSafeCache.get_or_compute(): Thread-safe version
        """
        pass

class Serializer:
    """
    Object serialization with security warnings.
    """
    
    def deserialize_pickle(self, data: bytes) -> Any:
        """
        Deserialize object from pickle format.
        
        .. danger::
            **ARBITRARY CODE EXECUTION VULNERABILITY!**
            
            pickle.loads() can execute arbitrary Python code during
            deserialization. NEVER deserialize untrusted data!
            
            **Attack Example:**
            >>> import pickle
            >>> import os
            >>> 
            >>> # Attacker creates malicious payload
            >>> class Malicious:
            ...     def __reduce__(self):
            ...         return (os.system, ('rm -rf /',))
            >>> 
            >>> payload = pickle.dumps(Malicious())
            >>> 
            >>> # Victim deserializes
            >>> pickle.loads(payload)  # Executes 'rm -rf /' !!!
            
            This is not a theoretical risk - it's easily exploitable:
            - Web APIs accepting pickled data
            - Message queues with pickled messages
            - Cached objects from untrusted sources
            
        .. warning::
            **SAFE ALTERNATIVES:**
            
            1. **JSON (recommended for untrusted data):**
               >>> import json
               >>> data = json.dumps({'key': 'value'})
               >>> obj = json.loads(data)  # Safe!
               
            2. **MessagePack (faster than JSON):**
               >>> import msgpack
               >>> data = msgpack.packb({'key': 'value'})
               >>> obj = msgpack.unpackb(data)  # Safe!
               
            3. **Protocol Buffers (strongly typed):**
               >>> from google.protobuf import message
               >>> # Define schema, then serialize/deserialize
               
            4. **If you MUST use pickle:**
               - Only deserialize your own data
               - Sign pickled data with HMAC
               - Validate signature before deserializing
               - Run in sandboxed environment
               - Use pickle protocol version 0 (slower but safer)
               
        Args:
            data: Pickled bytes to deserialize
            
        Returns:
            Deserialized Python object
            
        Raises:
            pickle.UnpicklingError: If data is corrupted
            
        Examples:
            **UNSAFE - Never do this:**
            >>> user_data = request.body  # From HTTP request
            >>> obj = serializer.deserialize_pickle(user_data)  # VULNERABLE!
            
            **SAFER - With signature verification:**
            >>> import hmac
            >>> import hashlib
            >>> 
            >>> def safe_deserialize(data, secret_key):
            ...     # Split signature and payload
            ...     signature = data[:32]
            ...     payload = data[32:]
            ...     
            ...     # Verify signature
            ...     expected = hmac.new(
            ...         secret_key,
            ...         payload,
            ...         hashlib.sha256
            ...     ).digest()
            ...     
            ...     if not hmac.compare_digest(signature, expected):
            ...         raise ValueError("Invalid signature")
            ...     
            ...     # Only deserialize verified data
            ...     return pickle.loads(payload)
            
            **BEST - Use JSON instead:**
            >>> import json
            >>> data = json.dumps(obj)  # Serialize
            >>> obj = json.loads(data)  # Deserialize - SAFE!
            
        Vulnerability Database:
            - CVE-2019-16785: Python pickle RCE
            - CVE-2021-3570: MLflow pickle RCE
            - CVE-2022-21668: pipenv pickle RCE
            
            Many projects have been compromised via pickle deserialization.
            
        Red Flags:
            ⚠️  Deserializing data from web requests
            ⚠️  Deserializing data from message queues
            ⚠️  Deserializing cached data from Redis
            ⚠️  Deserializing data from files (if user-writable)
            ⚠️  Deserializing data from APIs
            ⚠️  Any pickle.loads() on non-local data
            
        See Also:
            serialize_json(): Safe alternative
            serialize_msgpack(): Fast safe alternative
        """
        warnings.warn(
            "deserialize_pickle() can execute arbitrary code! "
            "Only use with trusted data. Consider JSON instead.",
            SecurityWarning,
            stacklevel=2
        )
        return pickle.loads(data)

class AsyncManager:
    """
    Async operations with deadlock warnings.
    """
    
    async def acquire_multiple_locks(
        self,
        locks: List[threading.Lock]
    ) -> None:
        """
        Acquire multiple locks.
        
        .. danger::
            **DEADLOCK RISK!**
            
            Acquiring multiple locks can cause deadlock if not done carefully.
            
            **Deadlock Example:**
            >>> lock_a = threading.Lock()
            >>> lock_b = threading.Lock()
            >>> 
            >>> # Thread 1
            >>> with lock_a:
            ...     time.sleep(0.1)
            ...     with lock_b:  # Waits for lock_b
            ...         pass
            >>> 
            >>> # Thread 2 (concurrent)
            >>> with lock_b:
            ...     time.sleep(0.1)
            ...     with lock_a:  # Waits for lock_a
            ...         pass
            >>> # DEADLOCK! Both threads wait forever.
            
        .. warning::
            **PREVENTION STRATEGIES:**
            
            1. **Always acquire locks in same order:**
               >>> locks = sorted(locks, key=id)  # Sort by memory address
               >>> for lock in locks:
               ...     lock.acquire()
               
            2. **Use timeout:**
               >>> if not lock.acquire(timeout=1.0):
               ...     raise TimeoutError("Could not acquire lock")
               
            3. **Use context manager with timeout:**
               >>> from contextlib import contextmanager
               >>> @contextmanager
               >>> def acquire_with_timeout(lock, timeout=1.0):
               ...     if not lock.acquire(timeout=timeout):
               ...         raise TimeoutError()
               ...     try:
               ...         yield
               ...     finally:
               ...         lock.release()
               
            4. **Use RLock for recursive locking:**
               >>> lock = threading.RLock()  # Reentrant lock
               >>> with lock:
               ...     with lock:  # Same thread can reacquire
               ...         pass
               
            5. **Use semaphore instead of multiple locks:**
               >>> sem = threading.Semaphore(5)  # Allow 5 concurrent
               >>> with sem:
               ...     # Do work
               
        Args:
            locks: List of locks to acquire
            
        Raises:
            TimeoutError: If locks cannot be acquired within timeout
            
        Warnings:
            - Locks acquired in order provided (may cause deadlock)
            - No timeout by default (can wait forever)
            - Not exception-safe (locks may not be released)
            - No deadlock detection
            
        See Also:
            acquire_locks_ordered(): Deadlock-safe version
        """
        pass
9. Complete Real-World Example
Production-Ready E-Commerce System
Python

"""
E-Commerce Order Processing System
==================================

A production-ready order processing system demonstrating all documentation
best practices:

- Comprehensive type hints
- Complete exception documentation
- Realistic examples
- WHY explanations
- Version history
- Edge case handling
- Security warnings
- Performance notes

Version: 3.2.1
Last Updated: 2024-01-15
Author: Development Team <dev@example.com>
License: MIT

Dependencies:
    - Python 3.10+
    - decimal
    - datetime
    - typing
    - dataclasses

Installation:
    $ pip install ecommerce-system
    
Quick Start:
    >>> from ecommerce import OrderProcessor, Product, Customer
    >>> processor = OrderProcessor(database_url="postgresql://...")
    >>> order = processor.create_order(customer_id="C001", items=[...])

For full documentation: https://docs.example.com/ecommerce
"""

from typing import List, Dict, Optional, Union, Literal, TypedDict, Protocol
from decimal import Decimal, InvalidOperation
from datetime import datetime, timedelta
from dataclasses import dataclass, field
from enum import Enum
from pathlib import Path
import logging
import warnings
from contextlib import contextmanager

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# ============================================================================
# TYPE DEFINITIONS
# ============================================================================

class OrderStatus(Enum):
    """
    Order lifecycle states.
    
    The order progresses through these states:
        DRAFT -> PENDING -> CONFIRMED -> PAID -> FULFILLED -> COMPLETED
        
    Can also transition to CANCELLED or REFUNDED from most states.
    
    Version History:
        - v3.0.0: Added DRAFT status
        - v2.5.0: Split PROCESSING into PAID and FULFILLED
        - v1.0.0: Initial statuses
    """
    DRAFT = "draft"           # Being created, not submitted
    PENDING = "pending"       # Submitted, awaiting confirmation
    CONFIRMED = "confirmed"   # Confirmed, awaiting payment
    PAID = "paid"            # Paid, awaiting fulfillment
    FULFILLED = "fulfilled"   # Shipped/delivered
    COMPLETED = "completed"   # Finalized, no changes allowed
    CANCELLED = "cancelled"   # Cancelled by user or system
    REFUNDED = "refunded"    # Payment refunded

class PaymentStatus(Enum):
    """Payment states matching payment gateway statuses."""
    PENDING = "pending"
    AUTHORIZED = "authorized"
    CAPTURED = "captured"
    FAILED = "failed"
    REFUNDED = "refunded"

class Currency(Enum):
    """Supported currencies (ISO 4217 codes)."""
    USD = "USD"
    EUR = "EUR"
    GBP = "GBP"
    JPY = "JPY"

@dataclass(frozen=True)
class Money:
    """
    Immutable monetary value.
    
    Uses Decimal for precision to avoid floating-point errors in
    financial calculations.
    
    Examples:
        >>> price = Money(Decimal('19.99'), Currency.USD)
        >>> tax = price * Decimal('0.1')
        >>> total = price + tax
        >>> print(total)
        Money(amount=Decimal('21.99'), currency=<Currency.USD>)
    
    Note:
        Immutable by design (frozen=True) to prevent accidental modification
        of monetary values, which could cause accounting errors.
    """
    amount: Decimal
    currency: Currency
    
    def __post_init__(self):
        """
        Validate after initialization.
        
        WHY: dataclass __init__ doesn't support validation,
        so we use __post_init__ hook.
        """
        if not isinstance(self.amount, Decimal):
            # Convert to Decimal if needed
            object.__setattr__(
                self,
                'amount',
                Decimal(str(self.amount))
            )
        
        if self.amount < 0:
            raise ValueError(f"Amount cannot be negative: {self.amount}")
    
    def __add__(self, other: 'Money') -> 'Money':
        """
        Add two Money objects.
        
        Raises:
            ValueError: If currencies don't match
            
        WHY check currency:
            Adding $10 + €10 is undefined. Must convert first.
        """
        if self.currency != other.currency:
            raise ValueError(
                f"Cannot add {self.currency} and {other.currency}. "
                f"Convert currencies first."
            )
        return Money(self.amount + other.amount, self.currency)
    
    def __mul__(self, multiplier: Union[int, Decimal]) -> 'Money':
        """
        Multiply money by number.
        
        Examples:
            >>> price = Money(Decimal('10.00'), Currency.USD)
            >>> total = price * 5
            >>> print(total)
            Money(amount=Decimal('50.00'), currency=<Currency.USD>)
            
            >>> # Calculate 6.5% tax
            >>> tax = price * Decimal('0.065')
            >>> print(tax)
            Money(amount=Decimal('0.65'), currency=<Currency.USD>)
        """
        return Money(self.amount * Decimal(str(multiplier)), self.currency)
    
    def __str__(self) -> str:
        """User-friendly representation."""
        symbols = {
            Currency.USD: '$',
            Currency.EUR: '€',
            Currency.GBP: '£',
            Currency.JPY: '¥'
        }
        symbol = symbols.get(self.currency, self.currency.value)
        
        # JPY has no decimal places
        if self.currency == Currency.JPY:
            return f"{symbol}{int(self.amount)}"
        
        return f"{symbol}{self.amount:.2f}"

class Address(TypedDict):
    """
    Typed dictionary for addresses.
    
    WHY TypedDict instead of dataclass:
        - Serializes directly to JSON (no .to_dict() needed)
        - Compatible with existing dict-based code
        - Lighter weight than full class
    """
    street: str
    city: str
    state: str
    postal_code: str
    country: str

# ============================================================================
# DOMAIN MODELS
# ============================================================================

@dataclass
class Product:
    """
    Represents a product in catalog.
    
    Attributes:
        product_id: Unique identifier (SKU or internal ID)
        name: Product name (2-200 characters)
        price: Product price (must be positive)
        stock: Available inventory (non-negative integer)
        description: Optional product description
        is_active: Whether product is available for sale
        
    Examples:
        >>> product = Product(
        ...     product_id="SKU-001",
        ...     name="Wireless Mouse",
        ...     price=Money(Decimal('29.99'), Currency.USD),
        ...     stock=100
        ... )
        >>> print(product.is_available(5))
        True
        >>> print(product.is_available(150))
        False
    
    Edge Cases:
        >>> # Zero stock
        >>> product.stock = 0
        >>> print(product.is_available(1))
        False
        
        >>> # Exact stock match
        >>> product.stock = 5
        >>> print(product.is_available(5))
        True
    """
    product_id: str
    name: str
    price: Money
    stock: int = 0
    description: str = ""
    is_active: bool = True
    created_at: datetime = field(default_factory=datetime.now)
    
    def __post_init__(self):
        """
        Validate product data.
        
        WHY validate in __post_init__:
            dataclass __init__ is auto-generated, so we use this hook
            for custom validation logic.
        """
        if not self.product_id or len(self.product_id) > 50:
            raise ValueError(
                f"product_id must be 1-50 characters: '{self.product_id}'"
            )
        
        if not self.name or not (2 <= len(self.name) <= 200):
            raise ValueError(
                f"name must be 2-200 characters: '{self.name}'"
            )
        
        if self.stock < 0:
            raise ValueError(f"stock cannot be negative: {self.stock}")
    
    def is_available(self, quantity: int = 1) -> bool:
        """
        Check if product available in requested quantity.
        
        Args:
            quantity: Quantity to check (default 1)
            
        Returns:
            True if product is active and has sufficient stock
            
        Examples:
            >>> product = Product("P001", "Item", Money(Decimal('10'), Currency.USD), stock=5)
            >>> product.is_available()
            True
            >>> product.is_available(5)
            True
            >>> product.is_available(6)
            False
            >>> product.is_active = False
            >>> product.is_available(1)
            False
        
        Note:
            Also checks is_active flag. Inactive products always return False
            even if stock available.
        """
        return self.is_active and self.stock >= quantity
    
    def reserve_stock(self, quantity: int) -> bool:
        """
        Reserve stock for order.
        
        Args:
            quantity: Quantity to reserve
            
        Returns:
            True if reservation successful, False if insufficient stock
            
        Raises:
            ValueError: If quantity <= 0
            
        Warning:
            This method is NOT thread-safe! In production, use:
            - Database-level row locking
            - Optimistic locking with version numbers
            - Distributed locks (Redis)
            
            **Race condition example:**
            >>> # Current stock: 5
            >>> # Thread 1 checks: 5 >= 5 → True
            >>> # Thread 2 checks: 5 >= 5 → True (same time!)
            >>> # Thread 1 reserves: stock = 0
            >>> # Thread 2 reserves: stock = -5 (OVERSOLD!)
            
        Examples:
            >>> product = Product("P001", "Item", Money(Decimal('10'), Currency.USD), stock=10)
            >>> product.reserve_stock(5)
            True
            >>> print(product.stock)
            5
            >>> product.reserve_stock(10)
            False
            >>> print(product.stock)
            5
        """
        if quantity <= 0:
            raise ValueError(f"Quantity must be positive: {quantity}")
        
        if not self.is_available(quantity):
            return False
        
        self.stock -= quantity
        logger.info(
            f"Reserved {quantity} of {self.product_id}. "
            f"Remaining stock: {self.stock}"
        )
        return True

@dataclass
class Customer:
    """
    Represents a customer.
    
    Attributes:
        customer_id: Unique identifier
        email: Customer email (validated format)
        name: Full name
        addresses: List of saved addresses
        created_at: Account creation timestamp
        
    Security:
        - Email is stored lowercase for case-insensitive lookups
        - Customer IDs should be UUIDs, not sequential integers
          (prevents enumeration attacks)
        
    Examples:
        >>> customer = Customer(
        ...     customer_id="C001",
        ...     email="john@example.com",
        ...     name="John Doe"
        ... )
        >>> customer.add_address({
        ...     'street': '123 Main St',
        ...     'city': 'New York',
        ...     'state': 'NY',
        ...     'postal_code': '10001',
        ...     'country': 'USA'
        ... })
        >>> print(len(customer.addresses))
        1
    """
    customer_id: str
    email: str
    name: str
    addresses: List[Address] = field(default_factory=list)
    created_at: datetime = field(default_factory=datetime.now)
    
    def __post_init__(self):
        """Validate and normalize customer data."""
        # Normalize email to lowercase
        # WHY: Emails are case-insensitive (RFC 5321)
        self.email = self.email.lower().strip()
        
        # Basic email validation
        # WHY not regex: Email regex is complex and error-prone
        # Better to use email library or send verification email
        if '@' not in self.email or '.' not in self.email.split('@')[1]:
            raise ValueError(f"Invalid email format: {self.email}")
        
        # Validate name
        self.name = self.name.strip()
        if not self.name or len(self.name) < 2:
            raise ValueError(f"Name too short: '{self.name}'")
    
    def add_address(self, address: Address) -> None:
        """
        Add address to customer's saved addresses.
        
        Args:
            address: Address dictionary with required fields
            
        Raises:
            ValueError: If address missing required fields or invalid format
            
        Examples:
            >>> customer = Customer("C001", "test@example.com", "Test User")
            >>> address: Address = {
            ...     'street': '123 Main St',
            ...     'city': 'New York',
            ...     'state': 'NY',
            ...     'postal_code': '10001',
            ...     'country': 'USA'
            ... }
            >>> customer.add_address(address)
            >>> print(len(customer.addresses))
            1
        
        Note:
            Duplicate addresses are allowed. Consider deduplication
            if this is a concern.
        """
        # Validate required fields
        required_fields = ['street', 'city', 'state', 'postal_code', 'country']
        missing = [f for f in required_fields if f not in address or not address[f]]
        
        if missing:
            raise ValueError(f"Address missing required fields: {missing}")
        
        self.addresses.append(address)
        logger.debug(f"Added address for customer {self.customer_id}")

# ============================================================================
# ORDER MANAGEMENT
# ============================================================================

@dataclass
class OrderItem:
    """
    Single item in an order.
    
    WHY separate class:
        - Captures price at time of order (historical record)
        - Product price may change, but order price shouldn't
        - Enables quantity discounts, bundles, etc.
    """
    product_id: str
    product_name: str
    quantity: int
    unit_price: Money
    
    @property
    def subtotal(self) -> Money:
        """
        Calculate item subtotal.
        
        WHY property instead of storing:
            - Always calculated from current quantity and price
            - Prevents inconsistency if quantity/price changes
            - No need to update when quantity changes
        """
        return self.unit_price * self.quantity

@dataclass
class Order:
    """
    Customer order with complete lifecycle management.
    
    This is the main aggregate root for order processing. It coordinates
    all order-related operations and maintains data consistency.
    
    Attributes:
        order_id: Unique order identifier
        customer: Customer who placed order
        items: List of order items
        status: Current order status
        payment_status: Current payment status
        shipping_address: Delivery address
        created_at: Order creation timestamp
        updated_at: Last update timestamp
        
    State Transitions:
        Valid transitions (enforced by transition methods):
        - DRAFT → PENDING (submit)
        - PENDING → CONFIRMED (confirm)
        - CONFIRMED → PAID (process_payment)
        - PAID → FULFILLED (ship)
        - FULFILLED → COMPLETED (complete)
        - Any → CANCELLED (cancel, with conditions)
        - PAID → REFUNDED (refund)
        
    Examples:
        Create and process order::
        
            >>> from decimal import Decimal
            >>> 
            >>> # Setup
            >>> customer = Customer("C001", "test@example.com", "Test")
            >>> product = Product(
            ...     "P001", "Widget",
            ...     Money(Decimal('19.99'), Currency.USD),
            ...     stock=100
            ... )
            >>> 
            >>> # Create order
            >>> order = Order(
            ...     order_id="ORD-001",
            ...     customer=customer
            ... )
            >>> 
            >>> # Add items
            >>> order.add_item(product, quantity=2)
            >>> 
            >>> # Set shipping
            >>> order.shipping_address = {
            ...     'street': '123 Main St',
            ...     'city': 'New York',
            ...     'state': 'NY',
            ...     'postal_code': '10001',
            ...     'country': 'USA'
            ... }
            >>> 
            >>> # Submit order
            >>> order.submit()
            >>> print(order.status)
            OrderStatus.PENDING
            >>> 
            >>> # Confirm
            >>> order.confirm()
            >>> print(order.status)
            OrderStatus.CONFIRMED
            >>> 
            >>> # Process payment
            >>> order.process_payment()
            >>> print(order.payment_status)
            PaymentStatus.CAPTURED
            >>> 
            >>> # Ship
            >>> order.ship()
            >>> print(order.status)
            OrderStatus.FULFILLED
    
    Warning:
        Order state is NOT persisted automatically. You must:
        1. Save order after each state change
        2. Use database transactions for consistency
        3. Handle concurrent modifications (optimistic locking)
        
    Thread Safety:
        This class is NOT thread-safe. Use database-level locking
        or optimistic concurrency control (version numbers).
    """
    order_id: str
    customer: Customer
    items: List[OrderItem] = field(default_factory=list)
    status: OrderStatus = OrderStatus.DRAFT
    payment_status: PaymentStatus = PaymentStatus.PENDING
    shipping_address: Optional[Address] = None
    created_at: datetime = field(default_factory=datetime.now)
    updated_at: datetime = field(default_factory=datetime.now)
    
    def add_item(
        self,
        product: Product,
        quantity: int = 1
    ) -> None:
        """
        Add item to order.
        
        Args:
            product: Product to add
            quantity: Quantity to order (default 1)
            
        Raises:
            ValueError: If order not in DRAFT status, quantity invalid,
                or product not available
                
        Examples:
            >>> order = Order("ORD-001", customer)
            >>> product = Product("P001", "Widget", Money(Decimal('10'), Currency.USD), 100)
            >>> order.add_item(product, 5)
            >>> print(len(order.items))
            1
            >>> print(order.items[0].quantity)
            5
            
        Edge Cases:
            >>> # Adding same product twice combines quantities
            >>> order.add_item(product, 2)
            >>> order.add_item(product, 3)
            >>> print(order.items[0].quantity)
            5
            
            >>> # Zero quantity
            >>> order.add_item(product, 0)
            Traceback (most recent call last):
                ...
            ValueError: Quantity must be positive
            
            >>> # Product out of stock
            >>> product.stock = 0
            >>> order.add_item(product, 1)
            Traceback (most recent call last):
                ...
            ValueError: Product not available
        """
        if self.status != OrderStatus.DRAFT:
            raise ValueError(
                f"Cannot add items to {self.status.value} order. "
                f"Order must be in DRAFT status."
            )
        
        if quantity <= 0:
            raise ValueError(f"Quantity must be positive: {quantity}")
        
        if not product.is_available(quantity):
            raise ValueError(
                f"Product {product.product_id} not available. "
                f"Requested: {quantity}, Available: {product.stock}"
            )
        
        # Check if product already in order
        for item in self.items:
            if item.product_id == product.product_id:
                # Update existing item
                item.quantity += quantity
                logger.info(
                    f"Updated {product.product_id} quantity to {item.quantity} "
                    f"in order {self.order_id}"
                )
                return
        
        # Add new item
        item = OrderItem(
            product_id=product.product_id,
            product_name=product.name,
            quantity=quantity,
            unit_price=product.price
        )
        self.items.append(item)
        logger.info(
            f"Added {quantity}x {product.product_id} "
            f"to order {self.order_id}"
        )
    
    @property
    def total(self) -> Money:
        """
        Calculate order total.
        
        Returns:
            Sum of all item subtotals
            
        Raises:
            ValueError: If order has items in different currencies
            
        Examples:
            >>> order = Order("ORD-001", customer)
            >>> product1 = Product("P001", "A", Money(Decimal('10'), Currency.USD), 100)
            >>> product2 = Product("P002", "B", Money(Decimal('20'), Currency.USD), 100)
            >>> order.add_item(product1, 2)
            >>> order.add_item(product2, 1)
            >>> print(order.total)
            $40.00
            
        Edge Cases:
            >>> # Empty order
            >>> empty_order = Order("ORD-002", customer)
            >>> print(empty_order.total)
            $0.00
            
            >>> # Mixed currencies (error)
            >>> product_eur = Product("P003", "C", Money(Decimal('10'), Currency.EUR), 100)
            >>> order.add_item(product_eur, 1)
            Traceback (most recent call last):
                ...
            ValueError: Cannot add USD and EUR
        """
        if not self.items:
            # Return zero in USD by default
            # WHY USD: Most common currency, arbitrary choice
            return Money(Decimal('0'), Currency.USD)
        
        # Start with first item's subtotal
        total = self.items[0].subtotal
        
        # Add remaining items
        for item in self.items[1:]:
            total = total + item.subtotal
        
        return total
    
    def submit(self) -> None:
        """
        Submit order for processing.
        
        Transitions order from DRAFT to PENDING status.
        
        Raises:
            ValueError: If order invalid (no items, no address, wrong status)
            
        Examples:
            >>> order = Order("ORD-001", customer)
            >>> order.add_item(product, 1)
            >>> order.shipping_address = address
            >>> order.submit()
            >>> print(order.status)
            OrderStatus.PENDING
            
        Warnings:
            This does NOT reserve inventory! Call confirm() to reserve.
            
        See Also:
            confirm(): Next step to reserve inventory
        """
        # Validate current status
        if self.status != OrderStatus.DRAFT:
            raise ValueError(
                f"Cannot submit {self.status.value} order. "
                f"Only DRAFT orders can be submitted."
            )
        
        # Validate order has items
        if not self.items:
            raise ValueError("Cannot submit empty order")
        
        # Validate shipping address
        if not self.shipping_address:
            raise ValueError("Shipping address required")
        
        # Update status
        self.status = OrderStatus.PENDING
        self.updated_at = datetime.now()
        
        logger.info(f"Order {self.order_id} submitted")
    
    def confirm(self) -> None:
        """
        Confirm order and reserve inventory.
        
        .. warning::
            This method reserves actual inventory. Make sure order
            is valid before calling!
            
        Transitions:
            PENDING → CONFIRMED
            
        Raises:
            ValueError: If status invalid or inventory unavailable
            
        Examples:
            >>> order.submit()  # First submit
            >>> order.confirm()  # Then confirm
            >>> print(order.status)
            OrderStatus.CONFIRMED
        """
        if self.status != OrderStatus.PENDING:
            raise ValueError(
                f"Cannot confirm {self.status.value} order. "
                f"Only PENDING orders can be confirmed."
            )
        
        # Note: In real implementation, would reserve inventory here
        # For demonstration, we'll just update status
        
        self.status = OrderStatus.CONFIRMED
        self.updated_at = datetime.now()
        
        logger.info(f"Order {self.order_id} confirmed")
    
    def process_payment(self) -> None:
        """
        Process payment for order.
        
        .. danger::
            This would charge real money in production!
            Ensure proper validation and error handling.
            
        Transitions:
            CONFIRMED → PAID
            
        Examples:
            >>> order.confirm()
            >>> order.process_payment()
            >>> print(order.status)
            OrderStatus.PAID
            >>> print(order.payment_status)
            PaymentStatus.CAPTURED
        """
        if self.status != OrderStatus.CONFIRMED:
            raise ValueError(
                f"Cannot process payment for {self.status.value} order. "
                f"Order must be CONFIRMED."
            )
        
        # In real implementation: call payment gateway
        # For demonstration: just update status
        
        self.status = OrderStatus.PAID
        self.payment_status = PaymentStatus.CAPTURED
        self.updated_at = datetime.now()
        
        logger.info(f"Payment processed for order {self.order_id}")
    
    def ship(self, tracking_number: Optional[str] = None) -> None:
        """
        Mark order as shipped.
        
        Args:
            tracking_number: Optional shipment tracking number
            
        Examples:
            >>> order.process_payment()
            >>> order.ship("TRACK123456")
            >>> print(order.status)
            OrderStatus.FULFILLED
        """
        if self.status != OrderStatus.PAID:
            raise ValueError(
                f"Cannot ship {self.status.value} order. "
                f"Order must be PAID."
            )
        
        self.status = OrderStatus.FULFILLED
        self.updated_at = datetime.now()
        
        logger.info(
            f"Order {self.order_id} shipped"
            + (f" (tracking: {tracking_number})" if tracking_number else "")
        )
    
    def __str__(self) -> str:
        """User-friendly string representation."""
        items_summary = f"{len(self.items)} item(s)"
        return (
            f"Order {self.order_id} - {self.status.value} - "
            f"{items_summary} - Total: {self.total}"
        )

# ============================================================================
# DEMONSTRATION
# ============================================================================

def main():
    """
    Demonstrate complete order processing workflow.
    
    This example shows:
    - Creating products
    - Creating customer
    - Building an order
    - Processing through lifecycle
    - Error handling
    """
    print("=" * 70)
    print("E-COMMERCE ORDER PROCESSING DEMONSTRATION")
    print("=" * 70)
    
    # Create products
    print("\n1. Creating Products")
    print("-" * 70)
    
    products = [
        Product(
            product_id="WIDGET-001",
            name="Super Widget",
            price=Money(Decimal('29.99'), Currency.USD),
            stock=100,
            description="Amazing widget that does everything"
        ),
        Product(
            product_id="GADGET-001",
            name="Awesome Gadget",
            price=Money(Decimal('49.99'), Currency.USD),
            stock=50,
            description="Incredible gadget for power users"
        )
    ]
    
    for product in products:
        print(f"  ✓ {product.name} - {product.price} (Stock: {product.stock})")
    
    # Create customer
    print("\n2. Creating Customer")
    print("-" * 70)
    
    customer = Customer(
        customer_id="CUST-12345",
        email="john.doe@example.com",
        name="John Doe"
    )
    
    address: Address = {
        'street': '123 Main Street',
        'city': 'San Francisco',
        'state': 'CA',
        'postal_code': '94102',
        'country': 'USA'
    }
    customer.add_address(address)
    
    print(f"  ✓ {customer.name} ({customer.email})")
    print(f"  ✓ Address: {address['street']}, {address['city']}")
    
    # Create order
    print("\n3. Creating Order")
    print("-" * 70)
    
    order = Order(
        order_id="ORD-2024-001",
        customer=customer
    )
    
    # Add items
    order.add_item(products[0], quantity=2)
    order.add_item(products[1], quantity=1)
    
    print(f"  ✓ Order {order.order_id} created")
    for item in order.items:
        print(f"    - {item.quantity}x {item.product_name} @ {item.unit_price}")
    print(f"  ✓ Total: {order.total}")
    
    # Set shipping address
    order.shipping_address = address
    
    # Process order
    print("\n4. Processing Order")
    print("-" * 70)
    
    print(f"  Status: {order.status.value}")
    
    order.submit()
    print(f"  → Submitted: {order.status.value}")
    
    order.confirm()
    print(f"  → Confirmed: {order.status.value}")
    
    order.process_payment()
    print(f"  → Payment Processed: {order.status.value}")
    print(f"  → Payment Status: {order.payment_status.value}")
    
    order.ship(tracking_number="TRACK123456789")
    print(f"  → Shipped: {order.status.value}")
    
    # Final summary
    print("\n5. Order Summary")
    print("-" * 70)
    print(f"  {order}")
    print(f"  Customer: {customer.name}")
    print(f"  Items: {len(order.items)}")
    print(f"  Total: {order.total}")
    print(f"  Status: {order.status.value}")
    print(f"  Payment: {order.payment_status.value}")
    
    print("\n" + "=" * 70)
    print("✓ Order processing completed successfully!")
    print("=" * 70)

if __name__ == "__main__":
    main()

