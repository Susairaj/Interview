Design Patterns & Code Quality for Python Leads

## A Complete Deep-Dive with Production-Grade Examples

---

# PART 1: DESIGN PATTERNS

---

## 1. CREATIONAL PATTERNS

> **Purpose:** Control *how* objects are created, hiding complexity and promoting flexibility.

---

### 1.1 Singleton

**Intent:** Guarantee a class has only **one instance** and provide a global access point.

**When to use:** Database connections, loggers, configuration managers, thread pools.

```python
# ─────────────────────────────────────────────
# APPROACH 1: Thread-Safe Singleton (Metaclass)
# ─────────────────────────────────────────────
import threading
from typing import Any


class SingletonMeta(type):
    """
    A thread-safe Singleton metaclass.

    When a class uses this as its metaclass, only ONE instance
    of that class will ever exist.

    How it works:
    ─────────────
    1. `_instances` dict stores the single instance of each class.
    2. `_lock` ensures only one thread can create the instance.
    3. `__call__` is invoked whenever you do `MyClass()`.
       - First call  → creates the instance, stores it.
       - Later calls → returns the stored instance.
    """

    _instances: dict[type, Any] = {}
    _lock: threading.Lock = threading.Lock()

    def __call__(cls, *args, **kwargs):
        # Double-checked locking pattern:
        # First check (without lock) — fast path for subsequent calls
        if cls not in cls._instances:
            # Second check (with lock) — only one thread creates
            with cls._lock:
                if cls not in cls._instances:
                    instance = super().__call__(*args, **kwargs)
                    cls._instances[cls] = instance
        return cls._instances[cls]


class DatabaseConnection(metaclass=SingletonMeta):
    """Only one DB connection exists application-wide."""

    def __init__(self, connection_string: str = "localhost:5432"):
        self.connection_string = connection_string
        self.connected = False
        print(f"[DatabaseConnection] Created with '{connection_string}'")

    def connect(self):
        self.connected = True
        print(f"[DatabaseConnection] Connected to '{self.connection_string}'")

    def execute(self, query: str) -> str:
        if not self.connected:
            raise RuntimeError("Not connected!")
        return f"Result of '{query}'"


# ─────────────────────────────────────────────
# APPROACH 2: Decorator-Based Singleton
# ─────────────────────────────────────────────
def singleton(cls):
    """A simpler decorator-based singleton (not thread-safe)."""
    instances = {}

    def get_instance(*args, **kwargs):
        if cls not in instances:
            instances[cls] = cls(*args, **kwargs)
        return instances[cls]

    return get_instance


@singleton
class AppConfig:
    def __init__(self):
        self.settings: dict[str, Any] = {}
        print("[AppConfig] Loaded configuration")

    def get(self, key: str, default: Any = None) -> Any:
        return self.settings.get(key, default)

    def set(self, key: str, value: Any) -> None:
        self.settings[key] = value


# ─────────────────────────────────────────────
# APPROACH 3: Module-Level Singleton (__new__)
# ─────────────────────────────────────────────
class Logger:
    """Singleton using __new__ — Pythonic approach."""

    _instance = None

    def __new__(cls, *args, **kwargs):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
            cls._instance._initialized = False
        return cls._instance

    def __init__(self, name: str = "app"):
        if self._initialized:
            return
        self.name = name
        self.logs: list[str] = []
        self._initialized = True
        print(f"[Logger] Initialized logger '{name}'")

    def log(self, message: str) -> None:
        entry = f"[{self.name}] {message}"
        self.logs.append(entry)
        print(entry)


# ─────────────────────────────────────────────
# USAGE
# ─────────────────────────────────────────────
if __name__ == "__main__":
    # Metaclass Singleton
    db1 = DatabaseConnection("postgres://prod:5432")
    db2 = DatabaseConnection("postgres://other:5432")   # ← ignored!
    print(f"Same instance? {db1 is db2}")                # True
    print(f"Connection: {db2.connection_string}")         # prod:5432

    # Decorator Singleton
    config1 = AppConfig()
    config1.set("debug", True)
    config2 = AppConfig()
    print(f"Same? {config1 is config2}")                  # True
    print(f"debug = {config2.get('debug')}")              # True

    # __new__ Singleton
    log1 = Logger("myapp")
    log2 = Logger("other")
    print(f"Same? {log1 is log2}")                        # True
    log2.log("Hello!")                                    # [myapp] Hello!
```

```
Output:
──────
[DatabaseConnection] Created with 'postgres://prod:5432'
Same instance? True
Connection: postgres://prod:5432
[AppConfig] Loaded configuration
Same? True
debug = True
[Logger] Initialized logger 'myapp'
Same? True
[myapp] Hello!
```

**Key Considerations for a Lead:**
- Singletons make unit testing harder (global state).
- Prefer **dependency injection** when possible.
- Use Singleton only for truly shared resources (config, logging, connection pools).

---

### 1.2 Factory

**Intent:** Delegate object creation to a factory instead of calling constructors directly.

**When to use:** When the exact class to instantiate depends on runtime data (config, user input, file type).

```python
# ─────────────────────────────────────────────
# SIMPLE FACTORY
# ─────────────────────────────────────────────
from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from enum import Enum, auto


# ── Product Interface ──
class Notification(ABC):
    """Abstract product — all notifications implement this."""

    @abstractmethod
    def send(self, recipient: str, message: str) -> str:
        ...

    @abstractmethod
    def validate(self, recipient: str) -> bool:
        ...


# ── Concrete Products ──
class EmailNotification(Notification):
    def send(self, recipient: str, message: str) -> str:
        if not self.validate(recipient):
            raise ValueError(f"Invalid email: {recipient}")
        return f"📧 Email sent to {recipient}: {message}"

    def validate(self, recipient: str) -> bool:
        return "@" in recipient and "." in recipient


class SMSNotification(Notification):
    def send(self, recipient: str, message: str) -> str:
        if not self.validate(recipient):
            raise ValueError(f"Invalid phone: {recipient}")
        return f"📱 SMS sent to {recipient}: {message}"

    def validate(self, recipient: str) -> bool:
        return recipient.startswith("+") and len(recipient) >= 10


class PushNotification(Notification):
    def send(self, recipient: str, message: str) -> str:
        return f"🔔 Push sent to device {recipient}: {message}"

    def validate(self, recipient: str) -> bool:
        return len(recipient) > 0


class SlackNotification(Notification):
    def send(self, recipient: str, message: str) -> str:
        return f"💬 Slack sent to #{recipient}: {message}"

    def validate(self, recipient: str) -> bool:
        return not recipient.startswith("#")  # We add # ourselves


# ── Simple Factory ──
class NotificationType(Enum):
    EMAIL = auto()
    SMS   = auto()
    PUSH  = auto()
    SLACK = auto()


class NotificationFactory:
    """
    Simple Factory — one method decides which class to instantiate.

    Why use a factory instead of if/else in client code?
    ─────────────────────────────────────────────────────
    1. Centralizes creation logic (one place to modify).
    2. Client code depends on the abstraction (Notification),
       not concrete classes.
    3. Easy to add new types without touching client code.
    """

    _registry: dict[NotificationType, type[Notification]] = {
        NotificationType.EMAIL: EmailNotification,
        NotificationType.SMS:   SMSNotification,
        NotificationType.PUSH:  PushNotification,
        NotificationType.SLACK: SlackNotification,
    }

    @classmethod
    def create(cls, notif_type: NotificationType) -> Notification:
        klass = cls._registry.get(notif_type)
        if klass is None:
            raise ValueError(f"Unknown notification type: {notif_type}")
        return klass()

    @classmethod
    def register(cls, notif_type: NotificationType,
                 klass: type[Notification]) -> None:
        """Open for extension — register new types at runtime."""
        cls._registry[notif_type] = klass


# ─────────────────────────────────────────────
# ABSTRACT FACTORY
# ─────────────────────────────────────────────
class UIComponent(ABC):
    @abstractmethod
    def render(self) -> str: ...


class Button(UIComponent):
    pass


class TextInput(UIComponent):
    pass


class Checkbox(UIComponent):
    pass


# ── Light Theme ──
class LightButton(Button):
    def render(self) -> str:
        return "[ Light Button ]"

class LightTextInput(TextInput):
    def render(self) -> str:
        return "| Light Input   |"

class LightCheckbox(Checkbox):
    def render(self) -> str:
        return "[✓] Light Check"


# ── Dark Theme ──
class DarkButton(Button):
    def render(self) -> str:
        return "[ Dark Button  ]"

class DarkTextInput(TextInput):
    def render(self) -> str:
        return "| Dark Input    |"

class DarkCheckbox(Checkbox):
    def render(self) -> str:
        return "[✓] Dark Check"


# ── Abstract Factory ──
class UIFactory(ABC):
    """
    Abstract Factory creates FAMILIES of related objects.

    Each concrete factory produces a consistent set (theme).
    Client code never knows which concrete classes it uses.
    """

    @abstractmethod
    def create_button(self) -> Button: ...

    @abstractmethod
    def create_text_input(self) -> TextInput: ...

    @abstractmethod
    def create_checkbox(self) -> Checkbox: ...


class LightThemeFactory(UIFactory):
    def create_button(self) -> Button:
        return LightButton()

    def create_text_input(self) -> TextInput:
        return LightTextInput()

    def create_checkbox(self) -> Checkbox:
        return LightCheckbox()


class DarkThemeFactory(UIFactory):
    def create_button(self) -> Button:
        return DarkButton()

    def create_text_input(self) -> TextInput:
        return DarkTextInput()

    def create_checkbox(self) -> Checkbox:
        return DarkCheckbox()


def build_form(factory: UIFactory) -> list[str]:
    """Client code — works with ANY theme factory."""
    button = factory.create_button()
    text   = factory.create_text_input()
    check  = factory.create_checkbox()
    return [button.render(), text.render(), check.render()]


# ─────────────────────────────────────────────
# USAGE
# ─────────────────────────────────────────────
if __name__ == "__main__":
    # Simple Factory
    print("=== Simple Factory ===")
    email = NotificationFactory.create(NotificationType.EMAIL)
    sms   = NotificationFactory.create(NotificationType.SMS)

    print(email.send("alice@example.com", "Welcome!"))
    print(sms.send("+1234567890", "Your OTP is 5678"))

    # Abstract Factory
    print("\n=== Abstract Factory ===")
    for name, factory in [("Light", LightThemeFactory()),
                          ("Dark",  DarkThemeFactory())]:
        print(f"\n{name} Theme:")
        for component in build_form(factory):
            print(f"  {component}")
```

```
Output:
──────
=== Simple Factory ===
📧 Email sent to alice@example.com: Welcome!
📱 SMS sent to +1234567890: Your OTP is 5678

=== Abstract Factory ===

Light Theme:
  [ Light Button ]
  | Light Input   |
  [✓] Light Check

Dark Theme:
  [ Dark Button  ]
  | Dark Input    |
  [✓] Dark Check
```

---

### 1.3 Builder

**Intent:** Construct complex objects **step by step**, separating construction from representation.

**When to use:** Objects with many optional parameters, complex configuration, building queries/documents/reports.

```python
from __future__ import annotations
from dataclasses import dataclass, field
from enum import Enum, auto
from typing import Optional


# ─────────────────────────────────────────────
# THE PRODUCT — a complex object to build
# ─────────────────────────────────────────────
class Environment(Enum):
    DEV     = "development"
    STAGING = "staging"
    PROD    = "production"


@dataclass
class DatabaseConfig:
    host: str = "localhost"
    port: int = 5432
    name: str = "mydb"
    user: str = "admin"
    password: str = ""
    pool_size: int = 5
    ssl_enabled: bool = False


@dataclass
class CacheConfig:
    backend: str = "redis"
    host: str = "localhost"
    port: int = 6379
    ttl: int = 300


@dataclass
class ServerConfig:
    """
    Complex product with many interdependent settings.
    Creating this directly is error-prone — use a Builder.
    """
    app_name: str = "MyApp"
    environment: Environment = Environment.DEV
    host: str = "0.0.0.0"
    port: int = 8000
    debug: bool = True
    workers: int = 1
    database: Optional[DatabaseConfig] = None
    cache: Optional[CacheConfig] = None
    allowed_hosts: list[str] = field(default_factory=list)
    middleware: list[str] = field(default_factory=list)
    cors_origins: list[str] = field(default_factory=list)
    log_level: str = "DEBUG"
    secret_key: str = "change-me"

    def summary(self) -> str:
        lines = [
            f"╔══════════════════════════════════════╗",
            f"║  {self.app_name:^34}  ║",
            f"╠══════════════════════════════════════╣",
            f"║  Env:      {self.environment.value:<25}║",
            f"║  Server:   {self.host}:{self.port:<19}║",
            f"║  Workers:  {self.workers:<25}║",
            f"║  Debug:    {str(self.debug):<25}║",
            f"║  Log:      {self.log_level:<25}║",
        ]
        if self.database:
            lines.append(
                f"║  DB:       {self.database.host}:{self.database.port}"
                f"/{self.database.name:<8}  ║"
            )
        if self.cache:
            lines.append(
                f"║  Cache:    {self.cache.backend} @ "
                f"{self.cache.host}:{self.cache.port:<7}  ║"
            )
        if self.middleware:
            lines.append(f"║  MW:       {len(self.middleware)} loaded{' '*17}║")
        lines.append(f"╚══════════════════════════════════════╝")
        return "\n".join(lines)


# ─────────────────────────────────────────────
# THE BUILDER — step-by-step construction
# ─────────────────────────────────────────────
class ServerConfigBuilder:
    """
    Fluent Builder for ServerConfig.

    Why Builder instead of a big __init__?
    ───────────────────────────────────────
    1. Readable: `builder.with_database(...).with_cache(...)` reads like English.
    2. Validated: Each step can validate before setting.
    3. Preset configs: The Director provides common presets.
    4. Immutable result: Build once, use safely.
    """

    def __init__(self, app_name: str):
        self._config = ServerConfig(app_name=app_name)

    # ── Fluent Setters (each returns `self`) ──

    def set_environment(self, env: Environment) -> ServerConfigBuilder:
        self._config.environment = env
        return self

    def set_server(self, host: str = "0.0.0.0",
                   port: int = 8000) -> ServerConfigBuilder:
        self._config.host = host
        self._config.port = port
        return self

    def set_workers(self, count: int) -> ServerConfigBuilder:
        if count < 1:
            raise ValueError("Workers must be >= 1")
        self._config.workers = count
        return self

    def set_debug(self, enabled: bool) -> ServerConfigBuilder:
        self._config.debug = enabled
        return self

    def set_log_level(self, level: str) -> ServerConfigBuilder:
        valid = {"DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL"}
        if level.upper() not in valid:
            raise ValueError(f"Invalid log level: {level}")
        self._config.log_level = level.upper()
        return self

    def with_database(self, host: str = "localhost", port: int = 5432,
                      name: str = "mydb", user: str = "admin",
                      password: str = "",
                      pool_size: int = 5,
                      ssl: bool = False) -> ServerConfigBuilder:
        self._config.database = DatabaseConfig(
            host=host, port=port, name=name,
            user=user, password=password,
            pool_size=pool_size, ssl_enabled=ssl,
        )
        return self

    def with_cache(self, backend: str = "redis",
                   host: str = "localhost", port: int = 6379,
                   ttl: int = 300) -> ServerConfigBuilder:
        self._config.cache = CacheConfig(
            backend=backend, host=host, port=port, ttl=ttl,
        )
        return self

    def add_middleware(self, *names: str) -> ServerConfigBuilder:
        self._config.middleware.extend(names)
        return self

    def set_allowed_hosts(self, *hosts: str) -> ServerConfigBuilder:
        self._config.allowed_hosts = list(hosts)
        return self

    def set_cors_origins(self, *origins: str) -> ServerConfigBuilder:
        self._config.cors_origins = list(origins)
        return self

    def set_secret_key(self, key: str) -> ServerConfigBuilder:
        if len(key) < 16:
            raise ValueError("Secret key must be >= 16 chars")
        self._config.secret_key = key
        return self

    def build(self) -> ServerConfig:
        """Validate and return the final product."""
        if self._config.environment == Environment.PROD:
            if self._config.debug:
                raise ValueError("Debug must be OFF in production!")
            if self._config.secret_key == "change-me":
                raise ValueError("Set a real secret key for production!")
            if not self._config.allowed_hosts:
                raise ValueError("Set allowed_hosts for production!")
        return self._config


# ─────────────────────────────────────────────
# THE DIRECTOR — provides preset configurations
# ─────────────────────────────────────────────
class ServerConfigDirector:
    """
    Director knows HOW to build common configurations.
    It uses the Builder's steps in a specific order.
    """

    @staticmethod
    def create_development(app_name: str) -> ServerConfig:
        return (
            ServerConfigBuilder(app_name)
            .set_environment(Environment.DEV)
            .set_debug(True)
            .set_log_level("DEBUG")
            .set_workers(1)
            .with_database(name=f"{app_name}_dev")
            .with_cache(ttl=60)
            .add_middleware("debug_toolbar", "cors")
            .build()
        )

    @staticmethod
    def create_production(app_name: str,
                          secret_key: str,
                          db_host: str,
                          domain: str) -> ServerConfig:
        return (
            ServerConfigBuilder(app_name)
            .set_environment(Environment.PROD)
            .set_debug(False)
            .set_log_level("WARNING")
            .set_workers(8)
            .set_server("0.0.0.0", 443)
            .set_secret_key(secret_key)
            .set_allowed_hosts(domain, f"www.{domain}")
            .set_cors_origins(f"https://{domain}")
            .with_database(
                host=db_host, name=app_name,
                pool_size=20, ssl=True,
            )
            .with_cache(ttl=3600)
            .add_middleware(
                "security_headers", "gzip",
                "rate_limit", "cors",
            )
            .build()
        )


# ─────────────────────────────────────────────
# USAGE
# ─────────────────────────────────────────────
if __name__ == "__main__":
    director = ServerConfigDirector()

    dev = director.create_development("myapp")
    print(dev.summary())

    print()

    prod = director.create_production(
        app_name="myapp",
        secret_key="super-secret-production-key-2024",
        db_host="db.prod.internal",
        domain="myapp.com",
    )
    print(prod.summary())
```

```
Output:
──────
╔══════════════════════════════════════╗
║               myapp                  ║
╠══════════════════════════════════════╣
║  Env:      development              ║
║  Server:   0.0.0.0:8000             ║
║  Workers:  1                        ║
║  Debug:    True                     ║
║  Log:      DEBUG                    ║
║  DB:       localhost:5432/myapp_dev  ║
║  Cache:    redis @ localhost:6379    ║
║  MW:       2 loaded                 ║
╚══════════════════════════════════════╝

╔══════════════════════════════════════╗
║               myapp                  ║
╠══════════════════════════════════════╣
║  Env:      production               ║
║  Server:   0.0.0.0:443              ║
║  Workers:  8                        ║
║  Debug:    False                    ║
║  Log:      WARNING                  ║
║  DB:       db.prod.internal:5432/myapp║
║  Cache:    redis @ localhost:6379    ║
║  MW:       4 loaded                 ║
╚══════════════════════════════════════╝
```

---

## 2. STRUCTURAL PATTERNS

> **Purpose:** Define how classes and objects are **composed** to form larger structures.

---

### 2.1 Adapter

**Intent:** Convert the interface of a class into another interface clients expect. Makes incompatible interfaces work together.

**When to use:** Integrating third-party libraries, migrating legacy code, unifying disparate APIs.

```python
from abc import ABC, abstractmethod
from dataclasses import dataclass
import json
import xml.etree.ElementTree as ET


# ─────────────────────────────────────────────
# TARGET — the interface YOUR code expects
# ─────────────────────────────────────────────
@dataclass
class WeatherData:
    city: str
    temperature_celsius: float
    humidity_percent: float
    description: str


class WeatherService(ABC):
    """Interface that our application expects."""

    @abstractmethod
    def get_weather(self, city: str) -> WeatherData:
        ...


# ─────────────────────────────────────────────
# ADAPTEES — third-party services with DIFFERENT interfaces
# ─────────────────────────────────────────────
class OpenWeatherAPI:
    """
    Third-party API #1.
    Returns JSON with temperature in Fahrenheit.
    We CANNOT modify this class.
    """

    def fetch_weather_data(self, city_name: str) -> dict:
        # Simulating API response
        return {
            "city": city_name,
            "main": {
                "temp_f": 72.5,
                "humidity": 65,
            },
            "weather": [{"description": "partly cloudy"}],
        }


class AccuWeatherAPI:
    """
    Third-party API #2.
    Returns XML with temperature in Kelvin.
    Completely different interface.
    """

    def get_conditions(self, location: str) -> str:
        # Simulating XML response
        return f"""
        <weather>
            <location>{location}</location>
            <temperature unit="kelvin">295.37</temperature>
            <relative_humidity>65</relative_humidity>
            <text_summary>Partly Cloudy</text_summary>
        </weather>
        """


class InternalLegacySystem:
    """
    Legacy internal system.
    Returns a tuple (city, temp_celsius, humidity, desc).
    """

    def query(self, loc_id: str) -> tuple:
        return (loc_id, 22.5, 65.0, "Partly Cloudy")


# ─────────────────────────────────────────────
# ADAPTERS — bridge between adaptees and target
# ─────────────────────────────────────────────
class OpenWeatherAdapter(WeatherService):
    """
    Adapts OpenWeatherAPI → WeatherService.

    The adapter:
    1. Holds a reference to the adaptee.
    2. Implements the target interface.
    3. Translates calls & converts data.
    """

    def __init__(self, api: OpenWeatherAPI):
        self._api = api

    @staticmethod
    def _fahrenheit_to_celsius(f: float) -> float:
        return round((f - 32) * 5 / 9, 2)

    def get_weather(self, city: str) -> WeatherData:
        # Call the adaptee's method
        raw = self._api.fetch_weather_data(city)

        # Convert to our expected format
        return WeatherData(
            city=raw["city"],
            temperature_celsius=self._fahrenheit_to_celsius(
                raw["main"]["temp_f"]
            ),
            humidity_percent=raw["main"]["humidity"],
            description=raw["weather"][0]["description"],
        )


class AccuWeatherAdapter(WeatherService):
    """Adapts AccuWeatherAPI (XML/Kelvin) → WeatherService."""

    def __init__(self, api: AccuWeatherAPI):
        self._api = api

    @staticmethod
    def _kelvin_to_celsius(k: float) -> float:
        return round(k - 273.15, 2)

    def get_weather(self, city: str) -> WeatherData:
        xml_str = self._api.get_conditions(city)
        root = ET.fromstring(xml_str.strip())

        temp_k = float(root.find("temperature").text)

        return WeatherData(
            city=root.find("location").text,
            temperature_celsius=self._kelvin_to_celsius(temp_k),
            humidity_percent=float(root.find("relative_humidity").text),
            description=root.find("text_summary").text,
        )


class LegacySystemAdapter(WeatherService):
    """Adapts the legacy tuple-based system → WeatherService."""

    def __init__(self, system: InternalLegacySystem):
        self._system = system

    def get_weather(self, city: str) -> WeatherData:
        city_name, temp, humidity, desc = self._system.query(city)
        return WeatherData(
            city=city_name,
            temperature_celsius=temp,
            humidity_percent=humidity,
            description=desc,
        )


# ─────────────────────────────────────────────
# CLIENT CODE — works with ANY adapter
# ─────────────────────────────────────────────
def display_weather(service: WeatherService, city: str) -> None:
    """
    Client code depends ONLY on WeatherService interface.
    It doesn't know or care which API is behind the adapter.
    """
    data = service.get_weather(city)
    print(f"  🌍 {data.city}")
    print(f"  🌡️  {data.temperature_celsius}°C")
    print(f"  💧 {data.humidity_percent}%")
    print(f"  📝 {data.description}")
    print()


if __name__ == "__main__":
    print("=== OpenWeather (Fahrenheit → Celsius) ===")
    display_weather(OpenWeatherAdapter(OpenWeatherAPI()), "London")

    print("=== AccuWeather (Kelvin XML → Celsius) ===")
    display_weather(AccuWeatherAdapter(AccuWeatherAPI()), "Paris")

    print("=== Legacy System (Tuple → Object) ===")
    display_weather(LegacySystemAdapter(InternalLegacySystem()), "NYC")
```

```
Output:
──────
=== OpenWeather (Fahrenheit → Celsius) ===
  🌍 London
  🌡️  22.5°C
  💧 65%
  📝 partly cloudy

=== AccuWeather (Kelvin XML → Celsius) ===
  🌍 Paris
  🌡️  22.22°C
  💧 65.0%
  📝 Partly Cloudy

=== Legacy System (Tuple → Object) ===
  🌍 NYC
  🌡️  22.5°C
  💧 65.0%
  📝 Partly Cloudy
```

---

### 2.2 Decorator

**Intent:** Attach additional responsibilities to an object **dynamically** without modifying its code. Wrapping, not subclassing.

**When to use:** Adding logging/caching/auth/retry/rate-limiting to existing services. Python's `@decorator` syntax is a language-level implementation of this pattern.

```python
from abc import ABC, abstractmethod
from functools import wraps
from typing import Any
import time
import hashlib


# ─────────────────────────────────────────────
# PATTERN APPROACH: Class-Based Decorators
# ─────────────────────────────────────────────

class DataSource(ABC):
    """Component interface."""

    @abstractmethod
    def read(self) -> str: ...

    @abstractmethod
    def write(self, data: str) -> None: ...


class FileDataSource(DataSource):
    """Concrete component — reads/writes data."""

    def __init__(self, filename: str):
        self._filename = filename
        self._data = ""

    def read(self) -> str:
        print(f"    [File] Reading from '{self._filename}'")
        return self._data

    def write(self, data: str) -> None:
        print(f"    [File] Writing to '{self._filename}'")
        self._data = data


class DataSourceDecorator(DataSource, ABC):
    """
    Base decorator — wraps a DataSource.

    Key insight: The decorator IS-A DataSource AND HAS-A DataSource.
    This lets decorators be stacked: Encrypt(Compress(File(...)))
    """

    def __init__(self, source: DataSource):
        self._wrapped = source

    def read(self) -> str:
        return self._wrapped.read()

    def write(self, data: str) -> None:
        self._wrapped.write(data)


class EncryptionDecorator(DataSourceDecorator):
    """Adds encryption/decryption on top of any DataSource."""

    def __init__(self, source: DataSource, key: str = "secret"):
        super().__init__(source)
        self._key = key

    def _encrypt(self, data: str) -> str:
        # Simple XOR cipher for demonstration
        key_bytes = (self._key * (len(data) // len(self._key) + 1)).encode()
        encrypted = bytes(
            a ^ b for a, b in zip(data.encode(), key_bytes)
        )
        result = encrypted.hex()
        print(f"    [Encrypt] {data[:20]}... → {result[:20]}...")
        return result

    def _decrypt(self, data: str) -> str:
        encrypted = bytes.fromhex(data)
        key_bytes = (self._key * (len(encrypted) // len(self._key) + 1)).encode()
        decrypted = bytes(
            a ^ b for a, b in zip(encrypted, key_bytes)
        ).decode()
        print(f"    [Decrypt] {data[:20]}... → {decrypted[:20]}...")
        return decrypted

    def write(self, data: str) -> None:
        super().write(self._encrypt(data))

    def read(self) -> str:
        return self._decrypt(super().read())


class CompressionDecorator(DataSourceDecorator):
    """Adds compression on top of any DataSource."""

    def _compress(self, data: str) -> str:
        # Simulated compression (run-length encoding sketch)
        compressed = f"COMPRESSED[{len(data)}]:{data}"
        print(f"    [Compress] {len(data)} chars → {len(compressed)} chars")
        return compressed

    def _decompress(self, data: str) -> str:
        if data.startswith("COMPRESSED["):
            idx = data.index("]:") + 2
            decompressed = data[idx:]
            print(f"    [Decompress] → {len(decompressed)} chars")
            return decompressed
        return data

    def write(self, data: str) -> None:
        super().write(self._compress(data))

    def read(self) -> str:
        return self._decompress(super().read())


class LoggingDecorator(DataSourceDecorator):
    """Adds logging to any DataSource operation."""

    def write(self, data: str) -> None:
        print(f"    [Log] WRITE operation, data length: {len(data)}")
        super().write(data)

    def read(self) -> str:
        print(f"    [Log] READ operation")
        result = super().read()
        print(f"    [Log] READ returned {len(result)} chars")
        return result


# ─────────────────────────────────────────────
# PYTHON-STYLE: Function Decorators
# ─────────────────────────────────────────────

def retry(max_attempts: int = 3, delay: float = 0.1):
    """Decorator factory: retries a function on exception."""
    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            last_exception = None
            for attempt in range(1, max_attempts + 1):
                try:
                    return func(*args, **kwargs)
                except Exception as e:
                    last_exception = e
                    print(f"  ⚠️  Attempt {attempt}/{max_attempts} "
                          f"failed: {e}")
                    if attempt < max_attempts:
                        time.sleep(delay)
            raise last_exception
        return wrapper
    return decorator


def cache(ttl_seconds: int = 60):
    """Decorator factory: caches function results."""
    _cache: dict[str, tuple[float, Any]] = {}

    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            # Build a cache key from function name + arguments
            key = f"{func.__name__}:{args}:{kwargs}"
            now = time.time()

            if key in _cache:
                cached_time, cached_value = _cache[key]
                if now - cached_time < ttl_seconds:
                    print(f"  ⚡ Cache HIT for {func.__name__}")
                    return cached_value

            print(f"  🔄 Cache MISS for {func.__name__}")
            result = func(*args, **kwargs)
            _cache[key] = (now, result)
            return result
        return wrapper
    return decorator


def timing(func):
    """Decorator: measures execution time."""
    @wraps(func)
    def wrapper(*args, **kwargs):
        start = time.perf_counter()
        result = func(*args, **kwargs)
        elapsed = time.perf_counter() - start
        print(f"  ⏱️  {func.__name__} took {elapsed:.4f}s")
        return result
    return wrapper


# ── Using function decorators ──

call_count = 0

@timing
@retry(max_attempts=3, delay=0.05)
@cache(ttl_seconds=10)
def fetch_user_data(user_id: int) -> dict:
    """Simulates a flaky API call."""
    global call_count
    call_count += 1
    # Fail on first call to demonstrate retry
    if call_count == 1:
        raise ConnectionError("API timeout")
    return {"id": user_id, "name": "Alice", "role": "admin"}


# ─────────────────────────────────────────────
# USAGE
# ─────────────────────────────────────────────
if __name__ == "__main__":
    # Class-based decorator pattern — stacking decorators
    print("=" * 50)
    print("CLASS-BASED DECORATOR PATTERN")
    print("=" * 50)

    # Stack: Logging → Encryption → Compression → File
    # Write path: Log → Encrypt → Compress → File
    # Read path:  File → Decompress → Decrypt → Log
    source = LoggingDecorator(
        EncryptionDecorator(
            CompressionDecorator(
                FileDataSource("data.txt")
            ),
            key="mykey"
        )
    )

    print("\n--- Writing ---")
    source.write("Hello, Decorator Pattern!")

    print("\n--- Reading ---")
    result = source.read()
    print(f"\n    Final result: '{result}'")

    # Function decorators
    print("\n" + "=" * 50)
    print("FUNCTION DECORATORS")
    print("=" * 50)

    print("\n--- First call (will retry, then cache) ---")
    data = fetch_user_data(42)
    print(f"  Result: {data}")

    print("\n--- Second call (cache hit) ---")
    data = fetch_user_data(42)
    print(f"  Result: {data}")
```

```
Output:
──────
==================================================
CLASS-BASED DECORATOR PATTERN
==================================================

--- Writing ---
    [Log] WRITE operation, data length: 25
    [Encrypt] Hello, Decorator Patter... → 200e07001a57170a1700...
    [Compress] 50 chars → 65 chars
    [File] Writing to 'data.txt'

--- Reading ---
    [Log] READ operation
    [File] Reading from 'data.txt'
    [Decompress] → 50 chars
    [Decrypt] 200e07001a57170a1700... → Hello, Decorator Patter...
    [Log] READ returned 25 chars

    Final result: 'Hello, Decorator Pattern!'

==================================================
FUNCTION DECORATORS
==================================================

--- First call (will retry, then cache) ---
  ⚠️  Attempt 1/3 failed: API timeout
  🔄 Cache MISS for fetch_user_data
  Result: {'id': 42, 'name': 'Alice', 'role': 'admin'}
  ⏱️  fetch_user_data took 0.0523s

--- Second call (cache hit) ---
  ⚡ Cache HIT for fetch_user_data
  Result: {'id': 42, 'name': 'Alice', 'role': 'admin'}
  ⏱️  fetch_user_data took 0.0001s
```

---

### 2.3 Facade

**Intent:** Provide a **simplified interface** to a complex subsystem. Hide the wiring, expose the essentials.

**When to use:** Simplifying complex library interactions, API gateways, service orchestration.

```python
from dataclasses import dataclass, field
from enum import Enum, auto
from typing import Optional
import json
import hashlib
import time


# ─────────────────────────────────────────────
# COMPLEX SUBSYSTEM — many classes the client
# shouldn't have to know about
# ─────────────────────────────────────────────

class InventorySystem:
    """Subsystem 1: Manages product stock."""

    def __init__(self):
        self._stock: dict[str, int] = {
            "LAPTOP-001": 50,
            "PHONE-002": 200,
            "TABLET-003": 0,
        }

    def check_stock(self, product_id: str) -> int:
        stock = self._stock.get(product_id, 0)
        print(f"  [Inventory] {product_id}: {stock} in stock")
        return stock

    def reserve(self, product_id: str, quantity: int) -> bool:
        if self._stock.get(product_id, 0) >= quantity:
            self._stock[product_id] -= quantity
            print(f"  [Inventory] Reserved {quantity}x {product_id}")
            return True
        print(f"  [Inventory] ❌ Cannot reserve {quantity}x {product_id}")
        return False

    def release(self, product_id: str, quantity: int) -> None:
        self._stock[product_id] = self._stock.get(product_id, 0) + quantity
        print(f"  [Inventory] Released {quantity}x {product_id}")


class PricingEngine:
    """Subsystem 2: Calculates prices, discounts, taxes."""

    _prices: dict[str, float] = {
        "LAPTOP-001": 999.99,
        "PHONE-002": 699.99,
        "TABLET-003": 449.99,
    }

    _tax_rates: dict[str, float] = {
        "US-CA": 0.0725,
        "US-NY": 0.08,
        "US-TX": 0.0625,
        "UK":    0.20,
    }

    def get_price(self, product_id: str) -> float:
        price = self._prices.get(product_id, 0)
        print(f"  [Pricing] {product_id} base price: ${price}")
        return price

    def apply_discount(self, price: float, code: str) -> float:
        discounts = {"SAVE10": 0.10, "SAVE20": 0.20, "VIP": 0.15}
        discount = discounts.get(code, 0)
        final = round(price * (1 - discount), 2)
        print(f"  [Pricing] Discount '{code}': "
              f"${price} → ${final} ({discount*100}% off)")
        return final

    def calculate_tax(self, price: float, region: str) -> float:
        rate = self._tax_rates.get(region, 0)
        tax = round(price * rate, 2)
        print(f"  [Pricing] Tax for {region}: ${tax} ({rate*100}%)")
        return tax


class PaymentGateway:
    """Subsystem 3: Processes payments."""

    def authorize(self, card_token: str, amount: float) -> Optional[str]:
        # Simulate payment authorization
        if amount > 5000:
            print(f"  [Payment] ❌ Amount ${amount} exceeds limit")
            return None
        txn_id = hashlib.md5(
            f"{card_token}{amount}{time.time()}".encode()
        ).hexdigest()[:12]
        print(f"  [Payment] ✅ Authorized ${amount}, txn: {txn_id}")
        return txn_id

    def capture(self, txn_id: str) -> bool:
        print(f"  [Payment] 💰 Captured txn {txn_id}")
        return True

    def refund(self, txn_id: str, amount: float) -> bool:
        print(f"  [Payment] ↩️  Refunded ${amount} for txn {txn_id}")
        return True


class ShippingService:
    """Subsystem 4: Handles shipping."""

    _rates: dict[str, float] = {
        "standard": 5.99,
        "express": 15.99,
        "overnight": 29.99,
    }

    def get_rate(self, method: str, weight_kg: float) -> float:
        base = self._rates.get(method, 5.99)
        rate = round(base + (weight_kg * 0.5), 2)
        print(f"  [Shipping] {method}: ${rate} ({weight_kg}kg)")
        return rate

    def create_shipment(self, address: str,
                        method: str) -> str:
        tracking = f"TRK-{hashlib.md5(address.encode()).hexdigest()[:8]}"
        print(f"  [Shipping] 📦 Created shipment {tracking}")
        return tracking


class NotificationService:
    """Subsystem 5: Sends notifications."""

    def send_email(self, to: str, subject: str, body: str) -> None:
        print(f"  [Notify] 📧 Email to {to}: {subject}")

    def send_sms(self, phone: str, message: str) -> None:
        print(f"  [Notify] 📱 SMS to {phone}: {message[:40]}...")


# ─────────────────────────────────────────────
# THE FACADE — simple interface to all subsystems
# ─────────────────────────────────────────────

@dataclass
class OrderResult:
    success: bool
    order_id: str = ""
    total: float = 0.0
    tracking: str = ""
    error: str = ""


class OrderFacade:
    """
    Facade: ONE simple method to place an order.

    Without this facade, the client would need to:
    1. Know about 5 different subsystem classes
    2. Call them in the correct order
    3. Handle rollbacks if any step fails
    4. Manage the data flow between subsystems

    The Facade encapsulates all of that complexity.
    """

    def __init__(self):
        self._inventory = InventorySystem()
        self._pricing = PricingEngine()
        self._payment = PaymentGateway()
        self._shipping = ShippingService()
        self._notifier = NotificationService()

    def place_order(
        self,
        product_id: str,
        quantity: int,
        card_token: str,
        shipping_address: str,
        email: str,
        region: str = "US-CA",
        discount_code: str = "",
        shipping_method: str = "standard",
    ) -> OrderResult:
        """
        Single method that orchestrates the entire order flow.

        Steps:
        1. Check & reserve inventory
        2. Calculate price (discount + tax + shipping)
        3. Authorize & capture payment
        4. Create shipment
        5. Send confirmation
        """

        order_id = f"ORD-{int(time.time())}"
        print(f"\n{'='*50}")
        print(f"Processing Order {order_id}")
        print(f"{'='*50}")

        # Step 1: Inventory
        print("\n📦 Step 1: Inventory Check")
        stock = self._inventory.check_stock(product_id)
        if stock < quantity:
            return OrderResult(
                success=False,
                error=f"Insufficient stock: {stock} < {quantity}",
            )
        if not self._inventory.reserve(product_id, quantity):
            return OrderResult(success=False, error="Reservation failed")

        # Step 2: Pricing
        print("\n💵 Step 2: Price Calculation")
        unit_price = self._pricing.get_price(product_id)
        subtotal = unit_price * quantity

        if discount_code:
            subtotal = self._pricing.apply_discount(subtotal, discount_code)

        tax = self._pricing.calculate_tax(subtotal, region)
        shipping = self._shipping.get_rate(shipping_method, quantity * 0.5)
        total = round(subtotal + tax + shipping, 2)
        print(f"  [Total] ${subtotal} + ${tax} tax + ${shipping} ship "
              f"= ${total}")

        # Step 3: Payment
        print("\n💳 Step 3: Payment")
        txn_id = self._payment.authorize(card_token, total)
        if not txn_id:
            # Rollback inventory
            self._inventory.release(product_id, quantity)
            return OrderResult(success=False, error="Payment declined")
        self._payment.capture(txn_id)

        # Step 4: Shipping
        print("\n🚚 Step 4: Shipping")
        tracking = self._shipping.create_shipment(
            shipping_address, shipping_method
        )

        # Step 5: Notification
        print("\n📧 Step 5: Notification")
        self._notifier.send_email(
            email,
            f"Order {order_id} Confirmed!",
            f"Total: ${total}. Tracking: {tracking}",
        )

        return OrderResult(
            success=True,
            order_id=order_id,
            total=total,
            tracking=tracking,
        )


# ─────────────────────────────────────────────
# USAGE — Client code is beautifully simple
# ─────────────────────────────────────────────
if __name__ == "__main__":
    shop = OrderFacade()

    # Successful order
    result = shop.place_order(
        product_id="LAPTOP-001",
        quantity=2,
        card_token="tok_visa_4242",
        shipping_address="123 Main St, San Francisco, CA",
        email="alice@example.com",
        discount_code="SAVE10",
        shipping_method="express",
    )
    print(f"\n✅ Order: {result.order_id}, "
          f"Total: ${result.total}, Tracking: {result.tracking}")

    # Failed order (out of stock)
    result = shop.place_order(
        product_id="TABLET-003",
        quantity=1,
        card_token="tok_visa_4242",
        shipping_address="456 Oak Ave",
        email="bob@example.com",
    )
    print(f"\n❌ Error: {result.error}")
```

---

## 3. BEHAVIORAL PATTERNS

> **Purpose:** Define how objects **communicate** and divide responsibilities.

---

### 3.1 Observer

**Intent:** Define a one-to-many dependency so that when one object changes state, all dependents are notified automatically.

**When to use:** Event systems, UI updates, pub/sub, reactive programming.

```python
from __future__ import annotations
from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum, auto
from typing import Any, Callable


# ─────────────────────────────────────────────
# APPROACH 1: Classic OOP Observer
# ─────────────────────────────────────────────

@dataclass
class Event:
    """Data carried with each notification."""
    name: str
    data: dict[str, Any]
    timestamp: datetime = field(default_factory=datetime.now)


class Observer(ABC):
    """Abstract observer — must implement `update`."""

    @abstractmethod
    def update(self, event: Event) -> None:
        ...


class Subject:
    """
    Observable subject — maintains a list of observers.

    Key concepts:
    ─────────────
    • Observers subscribe to specific event types.
    • When state changes, relevant observers are notified.
    • Subject doesn't know concrete observer types (loose coupling).
    """

    def __init__(self):
        self._observers: dict[str, list[Observer]] = {}

    def subscribe(self, event_name: str, observer: Observer) -> None:
        if event_name not in self._observers:
            self._observers[event_name] = []
        self._observers[event_name].append(observer)
        print(f"  [Subject] {observer.__class__.__name__} "
              f"subscribed to '{event_name}'")

    def unsubscribe(self, event_name: str, observer: Observer) -> None:
        if event_name in self._observers:
            self._observers[event_name].remove(observer)

    def notify(self, event: Event) -> None:
        observers = self._observers.get(event.name, [])
        print(f"\n  📢 Notifying {len(observers)} observers "
              f"of '{event.name}'")
        for observer in observers:
            observer.update(event)


# ── Concrete Subject ──
class ECommerceStore(Subject):
    """An online store that emits events."""

    def new_order(self, order_id: str, customer: str,
                  total: float) -> None:
        print(f"\n🛒 New order: {order_id} by {customer}, ${total}")
        self.notify(Event("order_placed", {
            "order_id": order_id,
            "customer": customer,
            "total": total,
        }))

    def cancel_order(self, order_id: str, reason: str) -> None:
        print(f"\n🚫 Order cancelled: {order_id}")
        self.notify(Event("order_cancelled", {
            "order_id": order_id,
            "reason": reason,
        }))

    def item_back_in_stock(self, product_id: str,
                           product_name: str) -> None:
        print(f"\n📦 Back in stock: {product_name}")
        self.notify(Event("back_in_stock", {
            "product_id": product_id,
            "product_name": product_name,
        }))


# ── Concrete Observers ──
class EmailNotifier(Observer):
    def update(self, event: Event) -> None:
        if event.name == "order_placed":
            print(f"    📧 [Email] Sending confirmation to "
                  f"{event.data['customer']}")
        elif event.name == "order_cancelled":
            print(f"    📧 [Email] Sending cancellation notice")
        elif event.name == "back_in_stock":
            print(f"    📧 [Email] '{event.data['product_name']}' "
                  f"is available!")


class InventoryManager(Observer):
    def update(self, event: Event) -> None:
        if event.name == "order_placed":
            print(f"    📋 [Inventory] Reserving items for "
                  f"order {event.data['order_id']}")
        elif event.name == "order_cancelled":
            print(f"    📋 [Inventory] Releasing items for "
                  f"order {event.data['order_id']}")


class AnalyticsTracker(Observer):
    def __init__(self):
        self.events_tracked: list[str] = []

    def update(self, event: Event) -> None:
        self.events_tracked.append(event.name)
        print(f"    📊 [Analytics] Tracked '{event.name}' "
              f"(total: {len(self.events_tracked)} events)")


class FraudDetector(Observer):
    def update(self, event: Event) -> None:
        if event.name == "order_placed":
            total = event.data.get("total", 0)
            if total > 1000:
                print(f"    🚨 [Fraud] HIGH VALUE order ${total} — "
                      f"flagged for review!")
            else:
                print(f"    ✅ [Fraud] Order ${total} — looks normal")


# ─────────────────────────────────────────────
# APPROACH 2: Pythonic Event System (functions)
# ─────────────────────────────────────────────

class EventBus:
    """
    A more Pythonic observer using callable handlers.
    Supports both functions and methods.
    """

    def __init__(self):
        self._handlers: dict[str, list[Callable]] = {}

    def on(self, event_name: str, handler: Callable) -> Callable:
        """Register a handler (can be used as decorator)."""
        if event_name not in self._handlers:
            self._handlers[event_name] = []
        self._handlers[event_name].append(handler)
        return handler

    def off(self, event_name: str, handler: Callable) -> None:
        if event_name in self._handlers:
            self._handlers[event_name].remove(handler)

    def emit(self, event_name: str, **kwargs) -> None:
        for handler in self._handlers.get(event_name, []):
            handler(**kwargs)


# ─────────────────────────────────────────────
# USAGE
# ─────────────────────────────────────────────
if __name__ == "__main__":
    # === Classic Observer ===
    print("=" * 55)
    print("CLASSIC OBSERVER PATTERN")
    print("=" * 55)

    store = ECommerceStore()

    email     = EmailNotifier()
    inventory = InventoryManager()
    analytics = AnalyticsTracker()
    fraud     = FraudDetector()

    # Subscribe to events
    store.subscribe("order_placed", email)
    store.subscribe("order_placed", inventory)
    store.subscribe("order_placed", analytics)
    store.subscribe("order_placed", fraud)
    store.subscribe("order_cancelled", email)
    store.subscribe("order_cancelled", inventory)
    store.subscribe("order_cancelled", analytics)
    store.subscribe("back_in_stock", email)

    # Trigger events
    store.new_order("ORD-001", "alice@example.com", 299.99)
    store.new_order("ORD-002", "bob@example.com", 2499.99)
    store.cancel_order("ORD-001", "Customer changed mind")
    store.item_back_in_stock("TAB-003", "iPad Pro")

    # === Pythonic EventBus ===
    print("\n" + "=" * 55)
    print("PYTHONIC EVENT BUS")
    print("=" * 55)

    bus = EventBus()

    # Register handlers (functions)
    @bus.on("user_signup")
    def send_welcome(username: str, email: str, **_):
        print(f"  📧 Welcome email to {email}")

    @bus.on("user_signup")
    def create_profile(username: str, **_):
        print(f"  👤 Created profile for {username}")

    @bus.on("user_signup")
    def track_signup(username: str, **_):
        print(f"  📊 Tracked signup: {username}")

    # Emit
    print("\n🆕 New user signup!")
    bus.emit("user_signup", username="charlie", email="charlie@test.com")
```

---

### 3.2 Strategy

**Intent:** Define a **family of algorithms**, encapsulate each one, and make them **interchangeable** at runtime.

**When to use:** Multiple ways to sort, validate, authenticate, price, compress, or export data.

```python
from abc import ABC, abstractmethod
from dataclasses import dataclass
from typing import Callable


# ─────────────────────────────────────────────
# APPROACH 1: Classic OOP Strategy
# ─────────────────────────────────────────────

@dataclass
class ShippingOrder:
    weight_kg: float
    distance_km: float
    is_fragile: bool = False
    is_express: bool = False


# ── Strategy Interface ──
class ShippingStrategy(ABC):
    """Each strategy encapsulates a different pricing algorithm."""

    @abstractmethod
    def calculate_cost(self, order: ShippingOrder) -> float:
        ...

    @abstractmethod
    def estimated_days(self, order: ShippingOrder) -> int:
        ...

    @property
    @abstractmethod
    def name(self) -> str:
        ...


# ── Concrete Strategies ──
class StandardShipping(ShippingStrategy):
    @property
    def name(self) -> str:
        return "Standard Ground"

    def calculate_cost(self, order: ShippingOrder) -> float:
        base = 5.99
        weight_charge = order.weight_kg * 0.50
        distance_charge = order.distance_km * 0.01
        fragile = 3.00 if order.is_fragile else 0
        return round(base + weight_charge + distance_charge + fragile, 2)

    def estimated_days(self, order: ShippingOrder) -> int:
        return max(3, int(order.distance_km / 500))


class ExpressShipping(ShippingStrategy):
    @property
    def name(self) -> str:
        return "Express Air"

    def calculate_cost(self, order: ShippingOrder) -> float:
        base = 15.99
        weight_charge = order.weight_kg * 1.50
        distance_charge = order.distance_km * 0.03
        fragile = 8.00 if order.is_fragile else 0
        return round(base + weight_charge + distance_charge + fragile, 2)

    def estimated_days(self, order: ShippingOrder) -> int:
        return 1 if order.distance_km < 1000 else 2


class FreeShipping(ShippingStrategy):
    @property
    def name(self) -> str:
        return "Free (Promo)"

    def calculate_cost(self, order: ShippingOrder) -> float:
        return 0.0

    def estimated_days(self, order: ShippingOrder) -> int:
        return max(5, int(order.distance_km / 300))


class PickupStrategy(ShippingStrategy):
    @property
    def name(self) -> str:
        return "Store Pickup"

    def calculate_cost(self, order: ShippingOrder) -> float:
        return 0.0

    def estimated_days(self, order: ShippingOrder) -> int:
        return 0


# ── Context ──
class ShippingCalculator:
    """
    Context that uses a strategy.

    The calculator doesn't know HOW shipping is calculated.
    It delegates to whatever strategy is set.
    Strategies can be swapped at runtime.
    """

    def __init__(self, strategy: ShippingStrategy):
        self._strategy = strategy

    @property
    def strategy(self) -> ShippingStrategy:
        return self._strategy

    @strategy.setter
    def strategy(self, strategy: ShippingStrategy) -> None:
        print(f"  🔄 Strategy changed to: {strategy.name}")
        self._strategy = strategy

    def calculate(self, order: ShippingOrder) -> dict:
        cost = self._strategy.calculate_cost(order)
        days = self._strategy.estimated_days(order)
        return {
            "method": self._strategy.name,
            "cost": cost,
            "days": days,
        }


# ─────────────────────────────────────────────
# APPROACH 2: Pythonic Strategy (functions)
# ─────────────────────────────────────────────
# In Python, you often don't need classes for Strategy.
# Functions are first-class objects!

@dataclass
class TextDocument:
    content: str
    title: str = "Untitled"


# Strategy functions (no class needed!)
def export_as_markdown(doc: TextDocument) -> str:
    return f"# {doc.title}\n\n{doc.content}"


def export_as_html(doc: TextDocument) -> str:
    return f"<html><body><h1>{doc.title}</h1><p>{doc.content}</p></body></html>"


def export_as_plain(doc: TextDocument) -> str:
    return f"{doc.title}\n{'=' * len(doc.title)}\n{doc.content}"


def export_as_json(doc: TextDocument) -> str:
    import json
    return json.dumps({"title": doc.title, "content": doc.content}, indent=2)


# Type alias for the strategy
ExportStrategy = Callable[[TextDocument], str]


class DocumentExporter:
    """Context using function-based strategies."""

    # Registry of available strategies
    _strategies: dict[str, ExportStrategy] = {
        "markdown": export_as_markdown,
        "html":     export_as_html,
        "plain":    export_as_plain,
        "json":     export_as_json,
    }

    def __init__(self, default_format: str = "plain"):
        self._format = default_format

    @classmethod
    def register_format(cls, name: str,
                        strategy: ExportStrategy) -> None:
        """Extend with new formats at runtime."""
        cls._strategies[name] = strategy

    def export(self, doc: TextDocument,
               fmt: str | None = None) -> str:
        format_name = fmt or self._format
        strategy = self._strategies.get(format_name)
        if not strategy:
            raise ValueError(f"Unknown format: {format_name}")
        return strategy(doc)


# ─────────────────────────────────────────────
# USAGE
# ─────────────────────────────────────────────
if __name__ == "__main__":
    # Class-based Strategy
    print("=" * 50)
    print("CLASS-BASED STRATEGY")
    print("=" * 50)

    order = ShippingOrder(
        weight_kg=2.5, distance_km=800, is_fragile=True
    )

    calc = ShippingCalculator(StandardShipping())

    for strategy in [StandardShipping(), ExpressShipping(),
                     FreeShipping(), PickupStrategy()]:
        calc.strategy = strategy
        result = calc.calculate(order)
        print(f"    {result['method']:>16}: ${result['cost']:>7.2f} "
              f"| {result['days']} days")

    # Function-based Strategy
    print("\n" + "=" * 50)
    print("FUNCTION-BASED STRATEGY (Pythonic)")
    print("=" * 50)

    doc = TextDocument("Strategy pattern is powerful!", "Design Patterns")
    exporter = DocumentExporter()

    for fmt in ["plain", "markdown", "html", "json"]:
        print(f"\n--- {fmt.upper()} ---")
        print(exporter.export(doc, fmt))
```

---

### 3.3 Command

**Intent:** Encapsulate a request as an **object**, allowing you to parameterize clients, queue operations, and support **undo/redo**.

**When to use:** Undo/redo, task queues, macro recording, transaction logs.

```python
from __future__ import annotations
from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from typing import Any


# ─────────────────────────────────────────────
# COMMAND INTERFACE
# ─────────────────────────────────────────────

class Command(ABC):
    """
    Each command encapsulates an action and its inverse.

    Key properties:
    ───────────────
    • execute()  — performs the action
    • undo()     — reverses the action
    • description — human-readable name
    """

    @abstractmethod
    def execute(self) -> None: ...

    @abstractmethod
    def undo(self) -> None: ...

    @property
    @abstractmethod
    def description(self) -> str: ...


# ─────────────────────────────────────────────
# RECEIVER — the object being acted upon
# ─────────────────────────────────────────────

class TextDocument:
    """Receiver: a simple text editor document."""

    def __init__(self):
        self._lines: list[str] = []
        self._clipboard: str = ""

    @property
    def text(self) -> str:
        return "\n".join(self._lines)

    @property
    def line_count(self) -> int:
        return len(self._lines)

    def insert_line(self, index: int, text: str) -> None:
        self._lines.insert(index, text)

    def remove_line(self, index: int) -> str:
        return self._lines.pop(index)

    def get_line(self, index: int) -> str:
        return self._lines[index]

    def replace_line(self, index: int, text: str) -> str:
        old = self._lines[index]
        self._lines[index] = text
        return old

    def display(self) -> None:
        print("    ┌─────────────────────────────────┐")
        if not self._lines:
            print("    │  (empty document)                │")
        for i, line in enumerate(self._lines):
            print(f"    │ {i+1:2}│ {line:<30}│")
        print("    └─────────────────────────────────┘")


# ─────────────────────────────────────────────
# CONCRETE COMMANDS
# ─────────────────────────────────────────────

class InsertLineCommand(Command):
    def __init__(self, document: TextDocument, index: int, text: str):
        self._doc = document
        self._index = index
        self._text = text

    @property
    def description(self) -> str:
        return f"Insert '{self._text}' at line {self._index + 1}"

    def execute(self) -> None:
        self._doc.insert_line(self._index, self._text)

    def undo(self) -> None:
        self._doc.remove_line(self._index)


class DeleteLineCommand(Command):
    def __init__(self, document: TextDocument, index: int):
        self._doc = document
        self._index = index
        self._deleted_text: str = ""

    @property
    def description(self) -> str:
        return f"Delete line {self._index + 1}"

    def execute(self) -> None:
        self._deleted_text = self._doc.remove_line(self._index)

    def undo(self) -> None:
        self._doc.insert_line(self._index, self._deleted_text)


class ReplaceLineCommand(Command):
    def __init__(self, document: TextDocument, index: int,
                 new_text: str):
        self._doc = document
        self._index = index
        self._new_text = new_text
        self._old_text: str = ""

    @property
    def description(self) -> str:
        return f"Replace line {self._index + 1} with '{self._new_text}'"

    def execute(self) -> None:
        self._old_text = self._doc.replace_line(
            self._index, self._new_text
        )

    def undo(self) -> None:
        self._doc.replace_line(self._index, self._old_text)


class MacroCommand(Command):
    """A composite command — executes multiple commands as one."""

    def __init__(self, name: str, commands: list[Command]):
        self._name = name
        self._commands = commands

    @property
    def description(self) -> str:
        return f"Macro '{self._name}' ({len(self._commands)} commands)"

    def execute(self) -> None:
        for cmd in self._commands:
            cmd.execute()

    def undo(self) -> None:
        for cmd in reversed(self._commands):
            cmd.undo()


# ─────────────────────────────────────────────
# INVOKER — manages command history + undo/redo
# ─────────────────────────────────────────────

class TextEditor:
    """
    Invoker: executes commands and manages undo/redo stacks.

    This is the core of the Command pattern's power:
    • Every action is recorded
    • Full undo/redo support
    • Action history / audit trail
    """

    def __init__(self):
        self.document = TextDocument()
        self._history: list[Command] = []  # undo stack
        self._redo_stack: list[Command] = []

    def execute(self, command: Command) -> None:
        command.execute()
        self._history.append(command)
        self._redo_stack.clear()  # New action invalidates redo
        print(f"  ✅ {command.description}")

    def undo(self) -> None:
        if not self._history:
            print("  ⚠️  Nothing to undo")
            return
        command = self._history.pop()
        command.undo()
        self._redo_stack.append(command)
        print(f"  ↩️  Undo: {command.description}")

    def redo(self) -> None:
        if not self._redo_stack:
            print("  ⚠️  Nothing to redo")
            return
        command = self._redo_stack.pop()
        command.execute()
        self._history.append(command)
        print(f"  ↪️  Redo: {command.description}")

    def show_history(self) -> None:
        print("\n  📜 Command History:")
        for i, cmd in enumerate(self._history, 1):
            print(f"     {i}. {cmd.description}")
        if not self._history:
            print("     (empty)")


# ─────────────────────────────────────────────
# USAGE
# ─────────────────────────────────────────────
if __name__ == "__main__":
    editor = TextEditor()

    print("=== Text Editor with Undo/Redo ===\n")

    # Build a document
    editor.execute(InsertLineCommand(editor.document, 0,
                                     "Hello, World!"))
    editor.execute(InsertLineCommand(editor.document, 1,
                                     "This is the Command pattern."))
    editor.execute(InsertLineCommand(editor.document, 2,
                                     "Each action is an object."))
    print()
    editor.document.display()

    # Replace a line
    editor.execute(ReplaceLineCommand(editor.document, 0,
                                      "Hi, Design Patterns!"))
    print()
    editor.document.display()

    # Undo twice
    print()
    editor.undo()
    editor.undo()
    print()
    editor.document.display()

    # Redo once
    editor.redo()
    print()
    editor.document.display()

    # Macro command
    print("\n--- Macro: Add Signature ---")
    macro = MacroCommand("add_signature", [
        InsertLineCommand(editor.document, editor.document.line_count,
                          "---"),
        InsertLineCommand(editor.document, editor.document.line_count + 1,
                          "Author: Python Lead"),
        InsertLineCommand(editor.document, editor.document.line_count + 2,
                          "Date: 2024"),
    ])
    editor.execute(macro)
    print()
    editor.document.display()

    # Undo the entire macro in one step!
    print("\n--- Undo Macro (all 3 lines removed at once) ---")
    editor.undo()
    print()
    editor.document.display()

    # Full history
    editor.show_history()
```

```
Output:
──────
=== Text Editor with Undo/Redo ===

  ✅ Insert 'Hello, World!' at line 1
  ✅ Insert 'This is the Command pattern.' at line 2
  ✅ Insert 'Each action is an object.' at line 3

    ┌─────────────────────────────────┐
    │  1│ Hello, World!               │
    │  2│ This is the Command pattern.│
    │  3│ Each action is an object.   │
    └─────────────────────────────────┘
  ✅ Replace line 1 with 'Hi, Design Patterns!'

    ┌─────────────────────────────────┐
    │  1│ Hi, Design Patterns!        │
    │  2│ This is the Command pattern.│
    │  3│ Each action is an object.   │
    └─────────────────────────────────┘

  ↩️  Undo: Replace line 1 with 'Hi, Design Patterns!'
  ↩️  Undo: Insert 'Each action is an object.' at line 3

    ┌─────────────────────────────────┐
    │  1│ Hello, World!               │
    │  2│ This is the Command pattern.│
    └─────────────────────────────────┘
  ↪️  Redo: Insert 'Each action is an object.' at line 3

    ┌─────────────────────────────────┐
    │  1│ Hello, World!               │
    │  2│ This is the Command pattern.│
    │  3│ Each action is an object.   │
    └─────────────────────────────────┘

--- Macro: Add Signature ---
  ✅ Macro 'add_signature' (3 commands)

    ┌─────────────────────────────────┐
    │  1│ Hello, World!               │
    │  2│ This is the Command pattern.│
    │  3│ Each action is an object.   │
    │  4│ ---                         │
    │  5│ Author: Python Lead         │
    │  6│ Date: 2024                  │
    └─────────────────────────────────┘

--- Undo Macro (all 3 lines removed at once) ---
  ↩️  Undo: Macro 'add_signature' (3 commands)

    ┌─────────────────────────────────┐
    │  1│ Hello, World!               │
    │  2│ This is the Command pattern.│
    │  3│ Each action is an object.   │
    └─────────────────────────────────┘
```

---
---

# PART 2: CODE QUALITY

---

## 4. Clean Architecture

> **Core Principle:** Dependency flows INWARD. Business logic never depends on frameworks, databases, or UI.

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│   ┌───────────────────────────────────────────────────┐     │
│   │                                                   │     │
│   │   ┌───────────────────────────────────────┐       │     │
│   │   │                                       │       │     │
│   │   │   ┌───────────────────────────┐       │       │     │
│   │   │   │                           │       │       │     │
│   │   │   │     ENTITIES              │       │       │     │
│   │   │   │  (Business Objects)       │       │       │     │
│   │   │   │                           │       │       │     │
│   │   │   └───────────────────────────┘       │       │     │
│   │   │                                       │       │     │
│   │   │     USE CASES                         │       │     │
│   │   │  (Application Business Rules)         │       │     │
│   │   │                                       │       │     │
│   │   └───────────────────────────────────────┘       │     │
│   │                                                   │     │
│   │     INTERFACE ADAPTERS                            │     │
│   │  (Controllers, Gateways, Presenters)              │     │
│   │                                                   │     │
│   └───────────────────────────────────────────────────┘     │
│                                                             │
│     FRAMEWORKS & DRIVERS                                    │
│  (Web, DB, External APIs, UI)                               │
│                                                             │
└─────────────────────────────────────────────────────────────┘

         ↑ Dependencies point INWARD ↑
```

```python
"""
Clean Architecture Example: User Registration System

Directory structure:
────────────────────
project/
├── domain/              ← INNERMOST (no dependencies)
│   ├── entities.py
│   └── repositories.py  (interfaces only)
├── use_cases/           ← depends only on domain
│   └── register_user.py
├── adapters/            ← depends on domain + use_cases
│   ├── controllers.py
│   ├── presenters.py
│   └── repositories.py  (implementations)
└── frameworks/          ← OUTERMOST
    ├── web.py
    └── database.py
"""

# ═══════════════════════════════════════════════
# LAYER 1: DOMAIN (innermost — zero dependencies)
# ═══════════════════════════════════════════════

# --- domain/entities.py ---
from __future__ import annotations
from dataclasses import dataclass, field
from datetime import datetime
from abc import ABC, abstractmethod
from typing import Optional
import re
import uuid


@dataclass
class User:
    """
    Domain Entity — pure business object.

    Rules:
    ──────
    • Contains ONLY business logic and validation.
    • No database code, no framework imports.
    • Must be valid at all times (invariants enforced).
    """
    id: str = field(default_factory=lambda: str(uuid.uuid4()))
    username: str = ""
    email: str = ""
    password_hash: str = ""
    is_active: bool = True
    created_at: datetime = field(default_factory=datetime.utcnow)

    def __post_init__(self):
        self._validate()

    def _validate(self) -> None:
        if self.username and len(self.username) < 3:
            raise ValueError("Username must be >= 3 characters")
        if self.email and not self._is_valid_email(self.email):
            raise ValueError(f"Invalid email: {self.email}")

    @staticmethod
    def _is_valid_email(email: str) -> bool:
        return bool(re.match(r"^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$", email))

    def deactivate(self) -> None:
        self.is_active = False


@dataclass
class RegistrationResult:
    """Value object representing the outcome."""
    success: bool
    user: Optional[User] = None
    error: str = ""


# --- domain/repositories.py ---
class UserRepository(ABC):
    """
    Repository INTERFACE — defined in domain layer.

    The domain says WHAT it needs (find, save),
    but NOT HOW (SQL, Mongo, file).
    Implementation is in the adapters layer.
    """

    @abstractmethod
    def find_by_email(self, email: str) -> Optional[User]: ...

    @abstractmethod
    def find_by_username(self, username: str) -> Optional[User]: ...

    @abstractmethod
    def save(self, user: User) -> None: ...


class PasswordHasher(ABC):
    """Interface for password hashing — domain doesn't know bcrypt."""

    @abstractmethod
    def hash(self, password: str) -> str: ...

    @abstractmethod
    def verify(self, password: str, hashed: str) -> bool: ...


class EventPublisher(ABC):
    """Interface for publishing domain events."""

    @abstractmethod
    def publish(self, event_name: str, data: dict) -> None: ...


# ═══════════════════════════════════════════════
# LAYER 2: USE CASES (depends only on domain)
# ═══════════════════════════════════════════════

# --- use_cases/register_user.py ---
@dataclass
class RegisterUserRequest:
    """Input DTO — what the use case needs."""
    username: str
    email: str
    password: str


class RegisterUserUseCase:
    """
    Application Business Rule.

    Orchestrates the flow:
    1. Validate input
    2. Check uniqueness
    3. Create user entity
    4. Save to repository
    5. Publish event

    Notice: It depends on INTERFACES (abstractions),
    not concrete implementations. → Dependency Inversion.
    """

    def __init__(
        self,
        user_repo: UserRepository,
        password_hasher: PasswordHasher,
        event_publisher: EventPublisher,
    ):
        self._repo = user_repo
        self._hasher = password_hasher
        self._events = event_publisher

    def execute(self, request: RegisterUserRequest) -> RegistrationResult:
        # 1. Validate password strength (business rule)
        if len(request.password) < 8:
            return RegistrationResult(
                success=False,
                error="Password must be >= 8 characters",
            )

        # 2. Check uniqueness
        if self._repo.find_by_email(request.email):
            return RegistrationResult(
                success=False,
                error=f"Email '{request.email}' already registered",
            )

        if self._repo.find_by_username(request.username):
            return RegistrationResult(
                success=False,
                error=f"Username '{request.username}' already taken",
            )

        # 3. Create domain entity
        try:
            user = User(
                username=request.username,
                email=request.email,
                password_hash=self._hasher.hash(request.password),
            )
        except ValueError as e:
            return RegistrationResult(success=False, error=str(e))

        # 4. Persist
        self._repo.save(user)

        # 5. Publish domain event
        self._events.publish("user_registered", {
            "user_id": user.id,
            "username": user.username,
            "email": user.email,
        })

        return RegistrationResult(success=True, user=user)


# ═══════════════════════════════════════════════
# LAYER 3: ADAPTERS (implements domain interfaces)
# ═══════════════════════════════════════════════

# --- adapters/repositories.py ---
class InMemoryUserRepository(UserRepository):
    """Concrete repository — stores users in memory."""

    def __init__(self):
        self._users: dict[str, User] = {}

    def find_by_email(self, email: str) -> Optional[User]:
        for user in self._users.values():
            if user.email == email:
                return user
        return None

    def find_by_username(self, username: str) -> Optional[User]:
        for user in self._users.values():
            if user.username == username:
                return user
        return None

    def save(self, user: User) -> None:
        self._users[user.id] = user
        print(f"    [Repo] Saved user: {user.username} ({user.id[:8]}...)")


# --- adapters/password.py ---
class SimplePasswordHasher(PasswordHasher):
    """Concrete hasher (use bcrypt in production!)."""

    def hash(self, password: str) -> str:
        import hashlib
        return hashlib.sha256(password.encode()).hexdigest()

    def verify(self, password: str, hashed: str) -> bool:
        return self.hash(password) == hashed


# --- adapters/events.py ---
class ConsoleEventPublisher(EventPublisher):
    """Concrete publisher — logs to console."""

    def publish(self, event_name: str, data: dict) -> None:
        print(f"    [Event] {event_name}: {data}")


# --- adapters/controllers.py ---
class RegistrationController:
    """
    Interface Adapter — translates HTTP-like input
    to use case input and use case output to response.
    """

    def __init__(self, use_case: RegisterUserUseCase):
        self._use_case = use_case

    def handle(self, request_data: dict) -> dict:
        """Simulate handling an HTTP POST request."""
        # Translate raw dict → use case DTO
        uc_request = RegisterUserRequest(
            username=request_data.get("username", ""),
            email=request_data.get("email", ""),
            password=request_data.get("password", ""),
        )

        # Execute use case
        result = self._use_case.execute(uc_request)

        # Translate result → HTTP-like response
        if result.success:
            return {
                "status": 201,
                "body": {
                    "message": "User created successfully",
                    "user_id": result.user.id,
                    "username": result.user.username,
                },
            }
        else:
            return {
                "status": 400,
                "body": {"error": result.error},
            }


# ═══════════════════════════════════════════════
# LAYER 4: FRAMEWORKS (outermost — wiring)
# ═══════════════════════════════════════════════

def create_app():
    """
    Composition Root — wires everything together.

    This is the ONLY place that knows about ALL concrete classes.
    Swap implementations here without touching business logic.
    """
    # Create concrete implementations
    user_repo = InMemoryUserRepository()
    hasher = SimplePasswordHasher()
    events = ConsoleEventPublisher()

    # Inject into use case
    register_use_case = RegisterUserUseCase(user_repo, hasher, events)

    # Inject into controller
    controller = RegistrationController(register_use_case)

    return controller


# ─────────────────────────────────────────────
# USAGE
# ─────────────────────────────────────────────
if __name__ == "__main__":
    controller = create_app()

    print("=" * 50)
    print("CLEAN ARCHITECTURE — User Registration")
    print("=" * 50)

    # Test 1: Successful registration
    print("\n--- Test 1: Valid registration ---")
    response = controller.handle({
        "username": "alice",
        "email": "alice@example.com",
        "password": "securepass123",
    })
    print(f"  Response: {response}")

    # Test 2: Duplicate email
    print("\n--- Test 2: Duplicate email ---")
    response = controller.handle({
        "username": "bob",
        "email": "alice@example.com",
        "password": "anotherpass",
    })
    print(f"  Response: {response}")

    # Test 3: Weak password
    print("\n--- Test 3: Weak password ---")
    response = controller.handle({
        "username": "charlie",
        "email": "charlie@example.com",
        "password": "short",
    })
    print(f"  Response: {response}")

    # Test 4: Invalid email
    print("\n--- Test 4: Invalid email ---")
    response = controller.handle({
        "username": "diana",
        "email": "not-an-email",
        "password": "securepass123",
    })
    print(f"  Response: {response}")
```

**Benefits of Clean Architecture:**
```
✅ Business logic has ZERO framework dependencies
✅ Easy to test (mock the interfaces)
✅ Easy to swap (change DB from Postgres to Mongo — only adapters change)
✅ Easy to understand (each layer has one job)
✅ Framework-agnostic (Django → FastAPI? Only outer layer changes)
```

---

## 5. Domain-Driven Design (DDD)

> **Core Idea:** Model software around the **business domain**, using a **ubiquitous language** shared between developers and domain experts.

```python
"""
DDD Example: Order Management System

Key DDD Concepts Demonstrated:
──────────────────────────────
1. Entity       — has identity, lifecycle (Order, Customer)
2. Value Object — defined by attributes, immutable (Money, Address)
3. Aggregate    — cluster of entities with a root (Order → OrderLines)
4. Repository   — persistence abstraction
5. Domain Event — something that happened in the domain
6. Domain Service — logic that doesn't belong to a single entity
7. Specification — encapsulated business rule
"""

from __future__ import annotations
from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from datetime import datetime
from decimal import Decimal
from enum import Enum, auto
from typing import Optional
import uuid


# ═══════════════════════════════════════════════
# VALUE OBJECTS — immutable, compared by value
# ═══════════════════════════════════════════════

@dataclass(frozen=True)
class Money:
    """
    Value Object: Amount + Currency.

    Immutable. Two Money objects are equal if
    amount AND currency are equal.
    """
    amount: Decimal
    currency: str = "USD"

    def __post_init__(self):
        if self.amount < 0:
            raise ValueError("Money amount cannot be negative")

    def __add__(self, other: Money) -> Money:
        if self.currency != other.currency:
            raise ValueError(
                f"Cannot add {self.currency} and {other.currency}"
            )
        return Money(self.amount + other.amount, self.currency)

    def __mul__(self, quantity: int) -> Money:
        return Money(self.amount * quantity, self.currency)

    def __gt__(self, other: Money) -> bool:
        self._check_currency(other)
        return self.amount > other.amount

    def __ge__(self, other: Money) -> bool:
        self._check_currency(other)
        return self.amount >= other.amount

    def _check_currency(self, other: Money) -> None:
        if self.currency != other.currency:
            raise ValueError("Cannot compare different currencies")

    def __str__(self) -> str:
        return f"{self.currency} {self.amount:.2f}"


@dataclass(frozen=True)
class Address:
    """Value Object: Shipping address."""
    street: str
    city: str
    state: str
    zip_code: str
    country: str = "US"

    def __str__(self) -> str:
        return f"{self.street}, {self.city}, {self.state} {self.zip_code}"


@dataclass(frozen=True)
class ProductId:
    """Value Object: Strongly-typed ID."""
    value: str

    def __str__(self) -> str:
        return self.value


# ═══════════════════════════════════════════════
# DOMAIN EVENTS
# ═══════════════════════════════════════════════

@dataclass(frozen=True)
class DomainEvent:
    occurred_at: datetime = field(default_factory=datetime.utcnow)


@dataclass(frozen=True)
class OrderPlaced(DomainEvent):
    order_id: str = ""
    customer_id: str = ""
    total: Money = field(default_factory=lambda: Money(Decimal("0")))


@dataclass(frozen=True)
class OrderShipped(DomainEvent):
    order_id: str = ""
    tracking_number: str = ""


@dataclass(frozen=True)
class OrderCancelled(DomainEvent):
    order_id: str = ""
    reason: str = ""


# ═══════════════════════════════════════════════
# ENTITIES
# ═══════════════════════════════════════════════

class OrderStatus(Enum):
    DRAFT    = auto()
    PLACED   = auto()
    PAID     = auto()
    SHIPPED  = auto()
    DELIVERED = auto()
    CANCELLED = auto()


@dataclass
class OrderLine:
    """
    Entity within the Order aggregate.
    Has its own identity but is managed by Order.
    """
    id: str = field(default_factory=lambda: str(uuid.uuid4())[:8])
    product_id: ProductId = field(default_factory=lambda: ProductId(""))
    product_name: str = ""
    unit_price: Money = field(default_factory=lambda: Money(Decimal("0")))
    quantity: int = 1

    @property
    def line_total(self) -> Money:
        return self.unit_price * self.quantity

    def __str__(self) -> str:
        return (f"{self.quantity}x {self.product_name} "
                f"@ {self.unit_price} = {self.line_total}")


class Order:
    """
    AGGREGATE ROOT — the main entity.

    Rules:
    ──────
    • ALL modifications go through the aggregate root.
    • External code never directly modifies OrderLine.
    • The root enforces all invariants (business rules).
    • Domain events are collected here.
    """

    MAX_LINES = 20
    MIN_ORDER_TOTAL = Money(Decimal("10.00"))

    def __init__(self, customer_id: str,
                 shipping_address: Address):
        self.id: str = str(uuid.uuid4())[:12]
        self.customer_id = customer_id
        self.shipping_address = shipping_address
        self.status = OrderStatus.DRAFT
        self.created_at = datetime.utcnow()

        self._lines: list[OrderLine] = []
        self._events: list[DomainEvent] = []

    # ── Properties ──

    @property
    def lines(self) -> tuple[OrderLine, ...]:
        """Return immutable view of order lines."""
        return tuple(self._lines)

    @property
    def total(self) -> Money:
        if not self._lines:
            return Money(Decimal("0"))
        result = self._lines[0].line_total
        for line in self._lines[1:]:
            result = result + line.line_total
        return result

    @property
    def domain_events(self) -> list[DomainEvent]:
        return list(self._events)

    def clear_events(self) -> None:
        self._events.clear()

    # ── Commands (state-changing methods) ──

    def add_line(self, product_id: ProductId, product_name: str,
                 unit_price: Money, quantity: int = 1) -> OrderLine:
        """Add a product to the order."""
        self._ensure_status(OrderStatus.DRAFT)

        if len(self._lines) >= self.MAX_LINES:
            raise ValueError(
                f"Order cannot have more than {self.MAX_LINES} lines"
            )
        if quantity < 1:
            raise ValueError("Quantity must be >= 1")

        line = OrderLine(
            product_id=product_id,
            product_name=product_name,
            unit_price=unit_price,
            quantity=quantity,
        )
        self._lines.append(line)
        return line

    def remove_line(self, line_id: str) -> None:
        self._ensure_status(OrderStatus.DRAFT)
        self._lines = [l for l in self._lines if l.id != line_id]

    def place(self) -> None:
        """Transition: DRAFT → PLACED."""
        self._ensure_status(OrderStatus.DRAFT)

        if not self._lines:
            raise ValueError("Cannot place an empty order")
        if self.total < self.MIN_ORDER_TOTAL:  # Corrected comparison
            raise ValueError(
                f"Minimum order: {self.MIN_ORDER_TOTAL} "
                f"(current: {self.total})"
            )

        self.status = OrderStatus.PLACED
        self._events.append(OrderPlaced(
            order_id=self.id,
            customer_id=self.customer_id,
            total=self.total,
        ))

    def mark_paid(self) -> None:
        self._ensure_status(OrderStatus.PLACED)
        self.status = OrderStatus.PAID

    def ship(self, tracking_number: str) -> None:
        self._ensure_status(OrderStatus.PAID)
        self.status = OrderStatus.SHIPPED
        self._events.append(OrderShipped(
            order_id=self.id,
            tracking_number=tracking_number,
        ))

    def cancel(self, reason: str) -> None:
        if self.status in (OrderStatus.SHIPPED, OrderStatus.DELIVERED):
            raise ValueError("Cannot cancel a shipped/delivered order")
        self.status = OrderStatus.CANCELLED
        self._events.append(OrderCancelled(
            order_id=self.id,
            reason=reason,
        ))

    # ── Internal helpers ──

    def _ensure_status(self, expected: OrderStatus) -> None:
        if self.status != expected:
            raise ValueError(
                f"Order must be {expected.name}, "
                f"but is {self.status.name}"
            )

    def __str__(self) -> str:
        lines_str = "\n    ".join(str(l) for l in self._lines)
        return (
            f"Order {self.id} [{self.status.name}]\n"
            f"  Customer: {self.customer_id}\n"
            f"  Ship to:  {self.shipping_address}\n"
            f"  Lines:\n    {lines_str}\n"
            f"  Total:    {self.total}"
        )


# ═══════════════════════════════════════════════
# SPECIFICATION PATTERN — encapsulated business rule
# ═══════════════════════════════════════════════

class Specification(ABC):
    """Encapsulates a business rule as an object."""

    @abstractmethod
    def is_satisfied_by(self, candidate) -> bool: ...

    def __and__(self, other: Specification) -> AndSpecification:
        return AndSpecification(self, other)

    def __or__(self, other: Specification) -> OrSpecification:
        return OrSpecification(self, other)

    def __invert__(self) -> NotSpecification:
        return NotSpecification(self)


class AndSpecification(Specification):
    def __init__(self, left: Specification, right: Specification):
        self._left = left
        self._right = right

    def is_satisfied_by(self, candidate) -> bool:
        return (self._left.is_satisfied_by(candidate) and
                self._right.is_satisfied_by(candidate))


class OrSpecification(Specification):
    def __init__(self, left: Specification, right: Specification):
        self._left = left
        self._right = right

    def is_satisfied_by(self, candidate) -> bool:
        return (self._left.is_satisfied_by(candidate) or
                self._right.is_satisfied_by(candidate))


class NotSpecification(Specification):
    def __init__(self, spec: Specification):
        self._spec = spec

    def is_satisfied_by(self, candidate) -> bool:
        return not self._spec.is_satisfied_by(candidate)


# ── Concrete Specifications ──

class HighValueOrder(Specification):
    def __init__(self, threshold: Money = Money(Decimal("500"))):
        self._threshold = threshold

    def is_satisfied_by(self, order: Order) -> bool:
        return order.total >= self._threshold


class PlacedOrder(Specification):
    def is_satisfied_by(self, order: Order) -> bool:
        return order.status == OrderStatus.PLACED


class MultiItemOrder(Specification):
    def __init__(self, min_lines: int = 3):
        self._min = min_lines

    def is_satisfied_by(self, order: Order) -> bool:
        return len(order.lines) >= self._min


# ═══════════════════════════════════════════════
# DOMAIN SERVICE — logic that spans multiple aggregates
# ═══════════════════════════════════════════════

class PricingService:
    """
    Domain Service: calculates discounts.

    This logic doesn't belong to Order or Customer alone,
    so it's a standalone service in the domain layer.
    """

    @staticmethod
    def calculate_discount(order: Order) -> Money:
        total = order.total

        # Bulk discount: 3+ line items → 5% off
        if len(order.lines) >= 3:
            discount_rate = Decimal("0.05")
        # High value: $500+ → 10% off
        elif total >= Money(Decimal("500")):
            discount_rate = Decimal("0.10")
        else:
            discount_rate = Decimal("0")

        discount_amount = total.amount * discount_rate
        return Money(discount_amount.quantize(Decimal("0.01")))


# ═══════════════════════════════════════════════
# USAGE
# ═══════════════════════════════════════════════

if __name__ == "__main__":
    print("=" * 55)
    print("DOMAIN-DRIVEN DESIGN — Order System")
    print("=" * 55)

    # Create an order (Aggregate Root)
    address = Address("123 Main St", "San Francisco", "CA", "94102")
    order = Order(customer_id="CUST-001", shipping_address=address)

    # Add lines through the aggregate root
    order.add_line(
        ProductId("LAPTOP-001"), "MacBook Pro",
        Money(Decimal("999.99")), quantity=1,
    )
    order.add_line(
        ProductId("MOUSE-002"), "Magic Mouse",
        Money(Decimal("79.99")), quantity=2,
    )
    order.add_line(
        ProductId("CASE-003"), "Laptop Case",
        Money(Decimal("49.99")), quantity=1,
    )

    print("\n📋 Order created:")
    print(order)

    # Domain Service — calculate discount
    discount = PricingService.calculate_discount(order)
    print(f"\n💰 Discount: {discount}")

    # Specifications — composable business rules
    print("\n📏 Specifications:")
    high_value = HighValueOrder()
    multi_item = MultiItemOrder()
    priority = high_value & multi_item

    print(f"  High value (>$500)?  {high_value.is_satisfied_by(order)}")
    print(f"  Multi-item (3+)?    {multi_item.is_satisfied_by(order)}")
    print(f"  Priority (both)?    {priority.is_satisfied_by(order)}")

    # State transitions with domain events
    print("\n🔄 State transitions:")
    order.place()
    print(f"  Status: {order.status.name}")

    order.mark_paid()
    print(f"  Status: {order.status.name}")

    order.ship("TRK-123456")
    print(f"  Status: {order.status.name}")

    # Domain events collected
    print("\n📢 Domain Events:")
    for event in order.domain_events:
        print(f"  • {event.__class__.__name__}: {event}")

    # Demonstrate invariant protection
    print("\n🛡️ Invariant protection:")
    try:
        order.cancel("Changed my mind")
    except ValueError as e:
        print(f"  ✅ Blocked: {e}")

    try:
        order.add_line(
            ProductId("X"), "Extra",
            Money(Decimal("10")),
        )
    except ValueError as e:
        print(f"  ✅ Blocked: {e}")
```

---

## 6. Code Review Strategies

```python
"""
Code Review: A Lead's Framework

This isn't code to run — it's a comprehensive guide
with before/after examples.
"""

# ═══════════════════════════════════════════════
# WHAT TO LOOK FOR IN CODE REVIEWS
# ═══════════════════════════════════════════════

# ────────────────────────────────────────────
# 1. CORRECTNESS — Does it actually work?
# ────────────────────────────────────────────

# ❌ BAD: Off-by-one, race condition, missing edge cases
def find_max_bad(numbers):
    max_val = 0  # Bug: fails for negative numbers
    for n in numbers:
        if n > max_val:
            max_val = n
    return max_val

# ✅ GOOD: Handles edge cases
def find_max_good(numbers: list[float]) -> float:
    if not numbers:
        raise ValueError("Cannot find max of empty list")
    return max(numbers)  # Use stdlib!


# ────────────────────────────────────────────
# 2. SECURITY — Is it safe?
# ────────────────────────────────────────────

# ❌ BAD: SQL injection vulnerability
def get_user_bad(username: str):
    query = f"SELECT * FROM users WHERE name = '{username}'"
    # If username = "'; DROP TABLE users; --" ... 💀
    return query

# ✅ GOOD: Parameterized queries
def get_user_good(cursor, username: str):
    cursor.execute(
        "SELECT * FROM users WHERE name = %s",
        (username,)
    )
    return cursor.fetchone()


# ────────────────────────────────────────────
# 3. READABILITY — Can someone else understand it?
# ────────────────────────────────────────────

# ❌ BAD: Clever but unreadable
def f(d, k):
    return {x: y for x, y in d.items() if x not in k}

# ✅ GOOD: Clear intent
def exclude_keys(
    data: dict[str, any],
    keys_to_exclude: set[str],
) -> dict[str, any]:
    """Return a new dict without the specified keys."""
    return {
        key: value
        for key, value in data.items()
        if key not in keys_to_exclude
    }


# ────────────────────────────────────────────
# 4. SOLID PRINCIPLES
# ────────────────────────────────────────────

# ❌ BAD: God class violating Single Responsibility
class UserManagerBad:
    def create_user(self, data): ...
    def send_email(self, user, msg): ...
    def generate_pdf_report(self, users): ...
    def authenticate(self, token): ...
    def update_database(self, query): ...
    def validate_credit_card(self, card): ...

# ✅ GOOD: Each class has ONE reason to change
class UserService:
    def create_user(self, data): ...
    def get_user(self, user_id): ...

class EmailService:
    def send(self, to, subject, body): ...

class ReportGenerator:
    def generate(self, data, format): ...


# ────────────────────────────────────────────
# 5. ERROR HANDLING
# ────────────────────────────────────────────

# ❌ BAD: Swallowing exceptions
def process_bad(data):
    try:
        result = complex_operation(data)
    except Exception:
        pass  # Silently fails — bugs disappear
    return None

# ❌ BAD: Catching too broadly
def process_also_bad(data):
    try:
        return int(data["value"]) / data["divisor"]
    except Exception as e:
        # Catches KeyError, TypeError, ZeroDivisionError...
        # Which one? We don't know!
        print(f"Error: {e}")

# ✅ GOOD: Specific exceptions, proper handling
def process_good(data: dict) -> float:
    try:
        value = int(data["value"])
    except KeyError:
        raise ValueError("Missing 'value' key in data")
    except (TypeError, ValueError) as e:
        raise ValueError(f"'value' must be an integer: {e}")

    try:
        return value / data["divisor"]
    except ZeroDivisionError:
        raise ValueError("Divisor cannot be zero")
    except KeyError:
        raise ValueError("Missing 'divisor' key in data")


# ────────────────────────────────────────────
# 6. PERFORMANCE — Obvious inefficiencies
# ────────────────────────────────────────────

# ❌ BAD: O(n²) when O(n) exists
def find_duplicates_bad(items: list) -> list:
    duplicates = []
    for i, item in enumerate(items):
        if item in items[i+1:]:  # O(n) search each time
            duplicates.append(item)
    return duplicates

# ✅ GOOD: O(n) with a set
def find_duplicates_good(items: list) -> set:
    seen = set()
    duplicates = set()
    for item in items:
        if item in seen:
            duplicates.add(item)
        seen.add(item)
    return duplicates


# ────────────────────────────────────────────
# 7. TESTABILITY — Is it easy to test?
# ────────────────────────────────────────────

# ❌ BAD: Hard-coded dependency, impossible to mock
import datetime as dt

class ReportBad:
    def generate(self):
        now = dt.datetime.now()  # Can't control in tests!
        data = open("report.csv").read()  # Hard-coded file!
        # ...

# ✅ GOOD: Dependencies injected
class ReportGood:
    def __init__(self, data_source, clock=None):
        self._source = data_source
        self._clock = clock or dt.datetime

    def generate(self):
        now = self._clock.now()
        data = self._source.read()
        # Easy to test with mocks!


# ═══════════════════════════════════════════════
# CODE REVIEW CHECKLIST FOR PYTHON LEADS
# ═══════════════════════════════════════════════
"""
□ Correctness
  □ Logic is correct, edge cases handled
  □ Boundary conditions tested
  □ Concurrent access considered

□ Security
  □ No SQL/command injection
  □ Secrets not hardcoded
  □ Input validated and sanitized
  □ Proper authentication/authorization checks

□ Design
  □ SOLID principles followed
  □ Appropriate design patterns used
  □ No unnecessary complexity (YAGNI)
  □ DRY — no copy-paste code

□ Readability
  □ Clear naming (variables, functions, classes)
  □ Functions are small and focused
  □ Comments explain WHY, not WHAT
  □ Type hints on public interfaces

□ Error Handling
  □ Specific exceptions caught
  □ Errors not silently swallowed
  □ Custom exceptions for domain errors
  □ Proper cleanup (context managers, finally)

□ Testing
  □ Tests exist for new/changed code
  □ Tests cover happy path + error cases
  □ Tests are independent and deterministic
  □ Mocks used appropriately (not excessively)

□ Performance
  □ No obvious O(n²) when O(n) exists
  □ Database queries are efficient (N+1?)
  □ No unnecessary memory allocation
  □ Async used where appropriate

□ Python-Specific
  □ Type hints consistent
  □ f-strings over .format() or %
  □ Context managers for resources
  □ Dataclasses/NamedTuples for data containers
  □ Pathlib over os.path
  □ Logging over print statements
"""
```

---

## 7. Refactoring Techniques

```python
"""
Refactoring Techniques — Improving code without changing behavior.
Each section shows BEFORE → AFTER with explanation.
"""


# ═══════════════════════════════════════════════
# TECHNIQUE 1: Extract Method
# Purpose: Break long functions into readable pieces
# ═══════════════════════════════════════════════

# ❌ BEFORE: One giant function doing everything
def process_order_before(order_data: dict) -> dict:
    # Validate
    if not order_data.get("customer_id"):
        return {"error": "Missing customer ID"}
    if not order_data.get("items"):
        return {"error": "No items"}
    for item in order_data["items"]:
        if item.get("quantity", 0) <= 0:
            return {"error": f"Invalid quantity for {item['name']}"}
        if item.get("price", 0) <= 0:
            return {"error": f"Invalid price for {item['name']}"}

    # Calculate total
    subtotal = 0
    for item in order_data["items"]:
        subtotal += item["price"] * item["quantity"]

    # Apply discount
    if subtotal > 100:
        discount = subtotal * 0.1
    elif subtotal > 50:
        discount = subtotal * 0.05
    else:
        discount = 0

    total = subtotal - discount

    # Tax
    tax = total * 0.08
    final = total + tax

    return {"subtotal": subtotal, "discount": discount,
            "tax": tax, "total": final}


# ✅ AFTER: Each step is its own focused function
from dataclasses import dataclass
from typing import Optional


@dataclass
class OrderItem:
    name: str
    price: float
    quantity: int


@dataclass
class OrderSummary:
    subtotal: float
    discount: float
    tax: float
    total: float


def validate_order(order_data: dict) -> Optional[str]:
    """Return error message or None if valid."""
    if not order_data.get("customer_id"):
        return "Missing customer ID"
    if not order_data.get("items"):
        return "No items"
    for item in order_data["items"]:
        if item.get("quantity", 0) <= 0:
            return f"Invalid quantity for {item['name']}"
        if item.get("price", 0) <= 0:
            return f"Invalid price for {item['name']}"
    return None


def calculate_subtotal(items: list[OrderItem]) -> float:
    return sum(item.price * item.quantity for item in items)


def calculate_discount(subtotal: float) -> float:
    if subtotal > 100:
        return subtotal * 0.10
    elif subtotal > 50:
        return subtotal * 0.05
    return 0.0


def calculate_tax(amount: float, rate: float = 0.08) -> float:
    return round(amount * rate, 2)


def process_order_after(order_data: dict) -> OrderSummary | dict:
    # Each step is clear and testable independently
    error = validate_order(order_data)
    if error:
        return {"error": error}

    items = [OrderItem(**item) for item in order_data["items"]]
    subtotal = calculate_subtotal(items)
    discount = calculate_discount(subtotal)
    taxable  = subtotal - discount
    tax      = calculate_tax(taxable)

    return OrderSummary(
        subtotal=subtotal,
        discount=discount,
        tax=tax,
        total=round(taxable + tax, 2),
    )


# ═══════════════════════════════════════════════
# TECHNIQUE 2: Replace Conditionals with Polymorphism
# Purpose: Eliminate complex if/elif chains
# ═══════════════════════════════════════════════

# ❌ BEFORE: Type-checking conditionals
class ShapeBefore:
    def __init__(self, shape_type: str, **kwargs):
        self.type = shape_type
        self.kwargs = kwargs

    def area(self) -> float:
        if self.type == "circle":
            return 3.14159 * self.kwargs["radius"] ** 2
        elif self.type == "rectangle":
            return self.kwargs["width"] * self.kwargs["height"]
        elif self.type == "triangle":
            return 0.5 * self.kwargs["base"] * self.kwargs["height"]
        else:
            raise ValueError(f"Unknown shape: {self.type}")

    def perimeter(self) -> float:
        if self.type == "circle":
            return 2 * 3.14159 * self.kwargs["radius"]
        elif self.type == "rectangle":
            return 2 * (self.kwargs["width"] + self.kwargs["height"])
        elif self.type == "triangle":
            return (self.kwargs["a"] + self.kwargs["b"]
                    + self.kwargs["c"])
        else:
            raise ValueError(f"Unknown shape: {self.type}")


# ✅ AFTER: Polymorphism — each shape knows its own math
from abc import ABC, abstractmethod
import math


class Shape(ABC):
    @abstractmethod
    def area(self) -> float: ...

    @abstractmethod
    def perimeter(self) -> float: ...

    def describe(self) -> str:
        return (f"{self.__class__.__name__}: "
                f"area={self.area():.2f}, "
                f"perimeter={self.perimeter():.2f}")


@dataclass
class Circle(Shape):
    radius: float

    def area(self) -> float:
        return math.pi * self.radius ** 2

    def perimeter(self) -> float:
        return 2 * math.pi * self.radius


@dataclass
class Rectangle(Shape):
    width: float
    height: float

    def area(self) -> float:
        return self.width * self.height

    def perimeter(self) -> float:
        return 2 * (self.width + self.height)


@dataclass
class Triangle(Shape):
    base: float
    height: float
    a: float
    b: float
    c: float

    def area(self) -> float:
        return 0.5 * self.base * self.height

    def perimeter(self) -> float:
        return self.a + self.b + self.c


# ═══════════════════════════════════════════════
# TECHNIQUE 3: Replace Magic Numbers/Strings
# ═══════════════════════════════════════════════

# ❌ BEFORE: Magic values scattered everywhere
def calculate_shipping_before(weight, method):
    if method == 1:          # What is 1?
        return weight * 0.5 + 5.99    # What's 0.5? 5.99?
    elif method == 2:
        return weight * 1.2 + 12.99
    elif method == 3:
        return weight * 2.0 + 24.99
    return 0

# ✅ AFTER: Named constants and enums
from enum import Enum


class ShippingMethod(Enum):
    STANDARD  = "standard"
    EXPRESS   = "express"
    OVERNIGHT = "overnight"


@dataclass(frozen=True)
class ShippingRate:
    per_kg: float
    base_fee: float

    def calculate(self, weight_kg: float) -> float:
        return round(weight_kg * self.per_kg + self.base_fee, 2)


SHIPPING_RATES: dict[ShippingMethod, ShippingRate] = {
    ShippingMethod.STANDARD:  ShippingRate(per_kg=0.50, base_fee=5.99),
    ShippingMethod.EXPRESS:   ShippingRate(per_kg=1.20, base_fee=12.99),
    ShippingMethod.OVERNIGHT: ShippingRate(per_kg=2.00, base_fee=24.99),
}


def calculate_shipping(weight_kg: float,
                       method: ShippingMethod) -> float:
    rate = SHIPPING_RATES.get(method)
    if not rate:
        raise ValueError(f"Unknown shipping method: {method}")
    return rate.calculate(weight_kg)


# ═══════════════════════════════════════════════
# TECHNIQUE 4: Introduce Parameter Object
# Purpose: Group related parameters into a data class
# ═══════════════════════════════════════════════

# ❌ BEFORE: Too many parameters
def create_user_before(
    first_name, last_name, email, phone,
    street, city, state, zip_code, country,
    role, department, manager_id,
    is_active, start_date
):
    pass  # 14 parameters!

# ✅ AFTER: Grouped into meaningful objects
@dataclass
class PersonalInfo:
    first_name: str
    last_name: str
    email: str
    phone: str = ""


@dataclass
class EmploymentInfo:
    role: str
    department: str
    manager_id: str = ""
    start_date: str = ""
    is_active: bool = True


def create_user_after(
    personal: PersonalInfo,
    address: Address,        # Reusing our earlier Value Object
    employment: EmploymentInfo,
) -> None:
    pass  # 3 clear, meaningful parameters


# ═══════════════════════════════════════════════
# TECHNIQUE 5: Replace Nested Conditionals with Guard Clauses
# ═══════════════════════════════════════════════

# ❌ BEFORE: Deep nesting (arrow anti-pattern)
def process_payment_before(payment):
    if payment is not None:
        if payment.amount > 0:
            if payment.currency in ("USD", "EUR", "GBP"):
                if payment.card_valid:
                    if payment.fraud_check_passed:
                        # Finally, the actual logic (5 levels deep!)
                        return charge(payment)
                    else:
                        return "Fraud detected"
                else:
                    return "Invalid card"
            else:
                return "Unsupported currency"
        else:
            return "Invalid amount"
    else:
        return "No payment"

# ✅ AFTER: Guard clauses — fail fast, flat code
def process_payment_after(payment) -> str:
    """Each guard clause handles one validation and returns early."""
    if payment is None:
        return "No payment"

    if payment.amount <= 0:
        return "Invalid amount"

    if payment.currency not in ("USD", "EUR", "GBP"):
        return "Unsupported currency"

    if not payment.card_valid:
        return "Invalid card"

    if not payment.fraud_check_passed:
        return "Fraud detected"

    # Happy path — no nesting!
    return charge(payment)


# ═══════════════════════════════════════════════
# TECHNIQUE 6: Use Context Managers for Resource Management
# ═══════════════════════════════════════════════

# ❌ BEFORE: Manual resource management
def write_report_before(data, filename):
    f = open(filename, 'w')
    try:
        f.write("Report\n")
        f.write("======\n")
        for item in data:
            f.write(f"{item}\n")
    finally:
        f.close()

# ✅ AFTER: Context manager
from contextlib import contextmanager
from pathlib import Path


@contextmanager
def report_writer(filename: str | Path):
    """Custom context manager for structured report writing."""
    path = Path(filename)
    path.parent.mkdir(parents=True, exist_ok=True)
    f = open(path, 'w')
    try:
        f.write("Report\n")
        f.write("=" * 40 + "\n")
        yield f
        f.write("\n" + "=" * 40 + "\n")
        f.write("End of Report\n")
    except Exception:
        f.write("\n[ERROR: Report generation failed]\n")
        raise
    finally:
        f.close()


# Usage:
# with report_writer("output/sales.txt") as report:
#     for item in data:
#         report.write(f"  {item}\n")


# ═══════════════════════════════════════════════
# TECHNIQUE 7: Replace Inheritance with Composition
# ═══════════════════════════════════════════════

# ❌ BEFORE: Deep inheritance hierarchy
class Animal:
    def eat(self): ...

class FlyingAnimal(Animal):
    def fly(self): ...

class SwimmingAnimal(Animal):
    def swim(self): ...

class FlyingSwimmingAnimal(FlyingAnimal, SwimmingAnimal):
    # Diamond problem! What if a Duck?
    pass


# ✅ AFTER: Composition with protocols
from typing import Protocol


class CanFly(Protocol):
    def fly(self) -> str: ...

class CanSwim(Protocol):
    def swim(self) -> str: ...


@dataclass
class Wings:
    span_meters: float

    def fly(self) -> str:
        return f"Flying with {self.span_meters}m wingspan"


@dataclass
class Fins:
    count: int

    def swim(self) -> str:
        return f"Swimming with {self.count} fins"


@dataclass
class Duck:
    """Composed of capabilities, not inherited."""
    name: str
    wings: Wings = field(default_factory=lambda: Wings(0.3))
    fins: Fins = field(default_factory=lambda: Fins(2))

    def fly(self) -> str:
        return self.wings.fly()

    def swim(self) -> str:
        return self.fins.swim()


# ═══════════════════════════════════════════════
# SUMMARY: Quick Reference
# ═══════════════════════════════════════════════
"""
REFACTORING TECHNIQUES CHEAT SHEET
═══════════════════════════════════

1. Extract Method
   Long function → small focused functions

2. Replace Conditionals with Polymorphism
   if/elif type-checking → abstract classes + subclasses

3. Replace Magic Numbers with Constants
   Bare literals → named constants/enums

4. Introduce Parameter Object
   5+ related params → dataclass

5. Guard Clauses
   Deep nesting → early returns

6. Context Managers
   try/finally → with statement

7. Composition over Inheritance
   Deep class hierarchy → Protocol + composed objects

8. Introduce Explaining Variable
   Complex expression → named variable

9. Replace Temp with Query
   Temporary variable → property/method

10. Move Method
    Method in wrong class → move to class it uses most

KEY PRINCIPLES:
───────────────
• Always have tests BEFORE refactoring
• Make ONE change at a time
• Run tests after EACH change
• Commit frequently
• If unsure, ask "is this simpler to understand?"
"""

# ─────────────────────────────────────────────
# DEMONSTRATE THE REFACTORED CODE
# ─────────────────────────────────────────────
if __name__ == "__main__":
    print("=" * 50)
    print("REFACTORING TECHNIQUES DEMO")
    print("=" * 50)

    # Extract Method demo
    print("\n--- Extract Method ---")
    result = process_order_after({
        "customer_id": "C001",
        "items": [
            {"name": "Widget", "price": 29.99, "quantity": 3},
            {"name": "Gadget", "price": 49.99, "quantity": 1},
        ],
    })
    print(f"  Order: {result}")

    # Polymorphism demo
    print("\n--- Polymorphism ---")
    shapes: list[Shape] = [
        Circle(radius=5),
        Rectangle(width=4, height=6),
        Triangle(base=3, height=4, a=3, b=4, c=5),
    ]
    for shape in shapes:
        print(f"  {shape.describe()}")

    # Named Constants demo
    print("\n--- Named Constants ---")
    for method in ShippingMethod:
        cost = calculate_shipping(2.5, method)
        print(f"  {method.value:>10}: ${cost}")

    # Composition demo
    print("\n--- Composition over Inheritance ---")
    duck = Duck("Donald")
    print(f"  {duck.name}: {duck.fly()}")
    print(f"  {duck.name}: {duck.swim()}")
```

```
Output:
──────
==================================================
REFACTORING TECHNIQUES DEMO
==================================================

--- Extract Method ---
  Order: OrderSummary(subtotal=139.96, discount=13.996,
         tax=10.08, total=136.04)

--- Polymorphism ---
  Circle: area=78.54, perimeter=31.42
  Rectangle: area=24.00, perimeter=20.00
  Triangle: area=6.00, perimeter=12.00

--- Named Constants ---
    standard: $7.24
     express: $15.99
   overnight: $29.99

--- Composition over Inheritance ---
  Donald: Flying with 0.3m wingspan
  Donald: Swimming with 2 fins
```

---

## Summary Cheat Sheet

```
╔════════════════════════════════════════════════════════════╗
║                DESIGN PATTERNS & CODE QUALITY             ║
║                   Quick Reference Card                    ║
╠════════════════════════════════════════════════════════════╣
║                                                           ║
║  CREATIONAL                                               ║
║  ─────────                                                ║
║  Singleton  → One instance only (DB, Config, Logger)      ║
║  Factory    → Delegate creation (if/else → polymorphism)  ║
║  Builder    → Complex objects step-by-step (fluent API)   ║
║                                                           ║
║  STRUCTURAL                                               ║
║  ──────────                                               ║
║  Adapter    → Convert interface A → interface B           ║
║  Decorator  → Wrap objects to add behavior dynamically    ║
║  Facade     → Simple API for complex subsystems           ║
║                                                           ║
║  BEHAVIORAL                                               ║
║  ──────────                                               ║
║  Observer   → Event system: subject notifies observers    ║
║  Strategy   → Swap algorithms at runtime                  ║
║  Command    → Encapsulate actions (undo/redo, queues)     ║
║                                                           ║
║  CODE QUALITY                                             ║
║  ────────────                                             ║
║  Clean Arch → Dependencies flow inward (domain is pure)   ║
║  DDD        → Model around business domain concepts       ║
║  Reviews    → Correctness → Security → Design → Tests     ║
║  Refactor   → Extract, Guard, Compose, Polymorphism       ║
║                                                           ║
║  PYTHON-SPECIFIC TIPS                                     ║
║  ────────────────────                                     ║
║  • Use Protocol over ABC when possible                    ║
║  • Prefer function strategies over class strategies       ║
║  • dataclass + frozen=True for value objects               ║
║  • @contextmanager for resource lifecycle                  ║
║  • Type hints on all public interfaces                    ║
║  • Dependency injection > global singletons               ║
║                                                           ║
╚════════════════════════════════════════════════════════════╝
```