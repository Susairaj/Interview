Python Backend Frameworks & API Engineering — Lead Engineer's Deep Dive

> I cannot generate downloadable PDFs, but this response is structured for easy
> copy-paste into any Markdown→PDF converter (Pandoc, md-to-pdf, or Typora).

---

## PART 1 — DJANGO INTERNALS

---

### 1.1 ORM Internals

```python
# ============================================================
# HOW DJANGO ORM TRANSLATES PYTHON TO SQL
# ============================================================

# Django ORM uses a "lazy QuerySet" pattern.
# No SQL is executed until the QuerySet is EVALUATED.

from django.db import models

# --- Model Definition ---
class Author(models.Model):
    name = models.CharField(max_length=200)
    email = models.EmailField(unique=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "authors"
        indexes = [
            models.Index(fields=["email"], name="idx_author_email"),
        ]

class Book(models.Model):
    title = models.CharField(max_length=300)
    author = models.ForeignKey(
        Author, 
        on_delete=models.CASCADE, 
        related_name="books"
    )
    price = models.DecimalField(max_digits=10, decimal_places=2)
    published = models.DateField()
    tags = models.ManyToManyField("Tag", related_name="books")
    
    class Meta:
        db_table = "books"
        ordering = ["-published"]

class Tag(models.Model):
    name = models.CharField(max_length=50, unique=True)


# --- QuerySet Lifecycle (Internal Flow) ---
# 1. You write: Book.objects.filter(price__gt=20)
# 2. Django creates a QuerySet object (no DB hit yet)
# 3. QuerySet holds an internal `query` attribute (sql.Query object)
# 4. sql.Query builds an AST (Abstract Syntax Tree) of the query
# 5. SQLCompiler converts the AST into a SQL string
# 6. DatabaseWrapper executes the SQL string via the DB backend

# --- Proof of laziness ---
qs = Book.objects.filter(price__gt=20)   # No SQL executed
qs = qs.filter(author__name="Tolkien")   # Still no SQL
qs = qs.order_by("title")               # Still no SQL

# SQL is executed ONLY when you evaluate:
# - Iteration: for book in qs
# - Slicing:   qs[0]
# - list():    list(qs)
# - bool():    if qs
# - .count(), .exists(), .first(), .aggregate(), etc.

# --- Inspecting the generated SQL ---
print(qs.query)
# SELECT "books"."id", "books"."title", ...
# FROM "books"
# INNER JOIN "authors" ON ("books"."author_id" = "authors"."id")
# WHERE "books"."price" > 20 AND "authors"."name" = 'Tolkien'
# ORDER BY "books"."title" ASC


# ============================================================
# DEEP DIVE: Query Expression Internals
# ============================================================
from django.db.models import F, Q, Value, Case, When
from django.db.models.functions import Concat, Upper

# F() expressions reference a column at the DATABASE level
# They avoid loading data into Python
Book.objects.filter(price__gt=F("author__id") * 10)

# Q() objects allow complex boolean logic
Book.objects.filter(
    Q(price__gt=50) | Q(title__icontains="ring"),
    ~Q(author__name="Unknown")   # NOT
)

# Internally, Q() objects form a tree:
#        AND
#       /   \
#     OR    NOT
#    / \      \
# price title  author__name="Unknown"


# ============================================================
# MODEL FIELD INTERNALS
# ============================================================
# Every Field has these key internal methods:
#
# 1. db_type(connection)     -> Returns DB column type ("VARCHAR(200)")
# 2. from_db_value(value...) -> Converts DB value -> Python value
# 3. to_python(value)        -> Converts any value -> Python type
# 4. get_prep_value(value)   -> Python value -> DB-ready value  
# 5. get_db_prep_value(...)  -> Final DB preparation (quoting, etc.)

class CompressedJSONField(models.TextField):
    """Custom field example showing internals."""
    
    import json, zlib, base64
    
    def from_db_value(self, value, expression, connection):
        if value is None:
            return value
        # DB stores base64-encoded zlib-compressed JSON
        compressed = base64.b64decode(value)
        json_str = zlib.decompress(compressed).decode("utf-8")
        return json.loads(json_str)
    
    def get_prep_value(self, value):
        if value is None:
            return value
        json_str = json.dumps(value)
        compressed = zlib.compress(json_str.encode("utf-8"))
        return base64.b64encode(compressed).decode("ascii")
```

### 1.2 Query Optimization

```python
# ============================================================
# THE N+1 PROBLEM AND SOLUTIONS
# ============================================================

# --- BAD: N+1 queries ---
# This generates 1 query for books + N queries for each author
books = Book.objects.all()          # Query 1: SELECT * FROM books
for book in books:
    print(book.author.name)         # Query 2..N+1: SELECT * FROM authors WHERE id=?

# --- GOOD: select_related (uses SQL JOIN) ---
# For ForeignKey / OneToOneField relationships
books = Book.objects.select_related("author").all()
# Single query: SELECT books.*, authors.* FROM books
#               INNER JOIN authors ON books.author_id = authors.id
for book in books:
    print(book.author.name)         # No additional queries!

# --- GOOD: prefetch_related (uses separate query + Python join) ---
# For ManyToManyField / reverse ForeignKey relationships
authors = Author.objects.prefetch_related("books").all()
# Query 1: SELECT * FROM authors
# Query 2: SELECT * FROM books WHERE author_id IN (1, 2, 3, ...)
for author in authors:
    for book in author.books.all():  # No additional queries!
        print(book.title)


# --- ADVANCED: Prefetch object with custom queryset ---
from django.db.models import Prefetch

authors = Author.objects.prefetch_related(
    Prefetch(
        "books",
        queryset=Book.objects.filter(price__gt=20).select_related("author"),
        to_attr="expensive_books"   # Store as a list attribute
    )
)
for author in authors:
    for book in author.expensive_books:  # Python list, not QuerySet
        print(book.title, book.price)


# ============================================================
# QUERY OPTIMIZATION TECHNIQUES
# ============================================================
from django.db.models import Count, Sum, Avg, Subquery, OuterRef, Exists

# 1. only() and defer() — Control which columns are loaded
books = Book.objects.only("title", "price")       # Load ONLY these
books = Book.objects.defer("large_text_field")     # Load all EXCEPT these

# 2. values() and values_list() — Return dicts/tuples instead of objects
titles = Book.objects.values_list("title", flat=True)
# ['The Hobbit', 'LOTR', ...] — much less memory

# 3. Aggregation at the database level
from django.db.models import Count, Avg

stats = Book.objects.aggregate(
    total_books=Count("id"),
    avg_price=Avg("price"),
    total_revenue=Sum("price"),
)
# {'total_books': 150, 'avg_price': Decimal('29.99'), ...}

# 4. Annotation — Add computed columns
authors_with_counts = Author.objects.annotate(
    book_count=Count("books"),
    avg_book_price=Avg("books__price"),
).filter(book_count__gt=5).order_by("-book_count")

# 5. Subqueries
from django.db.models import Subquery, OuterRef

newest_book = Book.objects.filter(
    author=OuterRef("pk")
).order_by("-published")

authors = Author.objects.annotate(
    latest_book_title=Subquery(newest_book.values("title")[:1]),
    latest_book_date=Subquery(newest_book.values("published")[:1]),
)

# 6. Exists subquery (more efficient than count > 0)
has_expensive = Book.objects.filter(
    author=OuterRef("pk"),
    price__gt=100,
)
authors = Author.objects.annotate(
    has_expensive_books=Exists(has_expensive)
).filter(has_expensive_books=True)

# 7. Database-level pagination (avoid large OFFSETs)
# BAD for large offsets:
books = Book.objects.all()[10000:10020]  
# Better: keyset pagination
last_seen_id = 9999
books = Book.objects.filter(id__gt=last_seen_id).order_by("id")[:20]

# 8. Raw SQL when ORM is insufficient
from django.db import connection

def get_complex_report():
    with connection.cursor() as cursor:
        cursor.execute("""
            SELECT a.name, 
                   COUNT(b.id) as book_count,
                   AVG(b.price) as avg_price
            FROM authors a
            LEFT JOIN books b ON b.author_id = a.id
            GROUP BY a.id, a.name
            HAVING COUNT(b.id) > %s
            ORDER BY avg_price DESC
        """, [5])
        columns = [col[0] for col in cursor.description]
        return [dict(zip(columns, row)) for row in cursor.fetchall()]


# ============================================================
# QUERY DEBUGGING
# ============================================================
import logging

# Method 1: Django debug logging
# settings.py
LOGGING = {
    'version': 1,
    'handlers': {
        'console': {'class': 'logging.StreamHandler'},
    },
    'loggers': {
        'django.db.backends': {
            'handlers': ['console'],
            'level': 'DEBUG',
        },
    },
}

# Method 2: connection.queries
from django.db import connection, reset_queries

reset_queries()
list(Book.objects.filter(price__gt=20))
print(f"Queries executed: {len(connection.queries)}")
for q in connection.queries:
    print(f"  [{q['time']}s] {q['sql']}")

# Method 3: django-debug-toolbar (in development)
# Method 4: explain()
print(Book.objects.filter(price__gt=20).explain(analyze=True))
# Seq Scan on books  (cost=0.00..25.00 rows=500 width=100)
#   Filter: (price > 20)
#   Rows Removed by Filter: 50
#   Planning Time: 0.1 ms
#   Execution Time: 0.5 ms
```

### 1.3 Signals

```python
# ============================================================
# DJANGO SIGNALS — OBSERVER PATTERN IMPLEMENTATION
# ============================================================
# Signals allow decoupled applications to get notified when 
# certain actions occur elsewhere in the framework.

# --- Built-in Signals ---
# pre_save    / post_save      -> Before/after Model.save()
# pre_delete  / post_delete    -> Before/after Model.delete()
# m2m_changed                  -> ManyToMany field changes
# request_started / request_finished -> HTTP request lifecycle
# pre_migrate / post_migrate   -> Migration lifecycle

from django.db.models.signals import post_save, pre_save, post_delete
from django.dispatch import receiver, Signal
from django.core.mail import send_mail


# --- Method 1: @receiver decorator ---
@receiver(post_save, sender=Author)
def author_post_save(sender, instance, created, **kwargs):
    """
    Called after Author.save() completes.
    
    Args:
        sender: The model class (Author)
        instance: The actual Author instance being saved
        created: Boolean — True if new record, False if update
        **kwargs: raw, using, update_fields
    """
    if created:
        send_mail(
            subject="New Author Registered",
            message=f"Author {instance.name} has been created.",
            from_email="system@example.com",
            recipient_list=["admin@example.com"],
        )
        # Create related profile
        AuthorProfile.objects.create(
            author=instance,
            bio="",
            avatar_url="default.png",
        )


@receiver(pre_save, sender=Book)
def book_pre_save(sender, instance, **kwargs):
    """Normalize data before saving."""
    instance.title = instance.title.strip().title()
    
    # Detect price changes
    if instance.pk:
        try:
            old = Book.objects.get(pk=instance.pk)
            if old.price != instance.price:
                PriceHistory.objects.create(
                    book=instance,
                    old_price=old.price,
                    new_price=instance.price,
                )
        except Book.DoesNotExist:
            pass


# --- Method 2: Manual connection (in AppConfig.ready()) ---
# myapp/apps.py
from django.apps import AppConfig

class MyAppConfig(AppConfig):
    default_auto_field = "django.db.models.BigAutoField"
    name = "myapp"
    
    def ready(self):
        # Import signals module to register handlers
        import myapp.signals  # noqa: F401
        
        # Or connect manually:
        from django.db.models.signals import post_save
        from myapp.models import Author
        from myapp.handlers import handle_author_save
        
        post_save.connect(handle_author_save, sender=Author)


# --- Custom Signals ---
# Define your own signals for domain events

order_completed = Signal()  # Django 3.1+: no args needed
payment_failed = Signal()
inventory_low = Signal()

# Sending the signal
class OrderService:
    def complete_order(self, order):
        order.status = "completed"
        order.save()
        
        # Fire signal — all connected receivers will be called
        order_completed.send(
            sender=self.__class__,
            order=order,
            total=order.total_amount,
        )

# Receiving the signal
@receiver(order_completed)
def send_confirmation_email(sender, order, total, **kwargs):
    send_mail(
        subject=f"Order #{order.id} Confirmed",
        message=f"Your order of ${total} is confirmed.",
        from_email="orders@example.com",
        recipient_list=[order.customer.email],
    )

@receiver(order_completed)
def update_inventory(sender, order, **kwargs):
    for item in order.items.all():
        item.product.stock -= item.quantity
        item.product.save()
        
        if item.product.stock < 10:
            inventory_low.send(
                sender=OrderService,
                product=item.product,
            )

@receiver(order_completed)
def record_analytics(sender, order, **kwargs):
    AnalyticsEvent.objects.create(
        event_type="order_completed",
        payload={"order_id": order.id, "total": str(order.total_amount)},
    )


# --- Signal Pitfalls ---
# 1. Signals make control flow HIDDEN — hard to debug
# 2. Signals run SYNCHRONOUSLY in the same transaction
# 3. Exception in any receiver breaks the chain
# 4. No guaranteed ordering of receivers
# 5. Prefer explicit method calls for critical business logic:

# INSTEAD OF signals for critical logic:
class AuthorService:
    def create_author(self, name, email):
        author = Author.objects.create(name=name, email=email)
        AuthorProfile.objects.create(author=author)
        self._send_welcome_email(author)
        self._notify_admin(author)
        return author
```

### 1.4 Middleware

```python
# ============================================================
# DJANGO MIDDLEWARE — REQUEST/RESPONSE PROCESSING PIPELINE
# ============================================================
#
# Middleware processes EVERY request/response. The execution order:
#
#  Request comes in
#       │
#       ▼
#  ┌─────────────────────┐
#  │  SecurityMiddleware  │  ← Process request (top-down)
#  │  SessionMiddleware   │
#  │  CommonMiddleware    │
#  │  CsrfViewMiddleware  │
#  │  AuthenticationMW    │
#  │  MessageMiddleware   │
#  │  YourCustomMiddleware│
#  └─────────────────────┘
#       │
#       ▼
#     VIEW (generates response)
#       │
#       ▼
#  ┌─────────────────────┐
#  │  YourCustomMiddleware│  ← Process response (bottom-up)
#  │  MessageMiddleware   │
#  │  AuthenticationMW    │
#  │  CsrfViewMiddleware  │
#  │  CommonMiddleware    │
#  │  SessionMiddleware   │
#  │  SecurityMiddleware  │
#  └─────────────────────┘
#       │
#       ▼
#  Response sent to client

import time
import uuid
import logging
from django.http import JsonResponse, HttpResponseForbidden
from django.utils.deprecation import MiddlewareMixin
from django.conf import settings

logger = logging.getLogger(__name__)


# --- Modern Middleware (Django 2.0+) ---
class RequestTimingMiddleware:
    """Measures request processing time."""
    
    def __init__(self, get_response):
        # Called once at server startup
        self.get_response = get_response
    
    def __call__(self, request):
        # Code before the view (and later middleware) is called
        request.start_time = time.perf_counter()
        request.request_id = str(uuid.uuid4())
        
        # Call the next middleware or view
        response = self.get_response(request)
        
        # Code after the view has returned a response
        duration = time.perf_counter() - request.start_time
        response["X-Request-Duration"] = f"{duration:.4f}s"
        response["X-Request-ID"] = request.request_id
        
        logger.info(
            "Request completed",
            extra={
                "request_id": request.request_id,
                "method": request.method,
                "path": request.path,
                "status": response.status_code,
                "duration_ms": round(duration * 1000, 2),
                "user": getattr(request, "user", None),
            }
        )
        
        # Alert on slow requests
        if duration > 2.0:
            logger.warning(f"SLOW REQUEST: {request.path} took {duration:.2f}s")
        
        return response
    
    def process_exception(self, request, exception):
        """Called if the view raises an exception."""
        logger.error(
            f"Unhandled exception in {request.path}",
            exc_info=True,
            extra={"request_id": getattr(request, "request_id", "unknown")},
        )
        if settings.DEBUG:
            return None  # Let Django's default exception handling take over
        return JsonResponse(
            {"error": "Internal server error", "request_id": request.request_id},
            status=500,
        )

    def process_view(self, request, view_func, view_args, view_kwargs):
        """Called just before Django calls the view."""
        # Can return None (continue) or HttpResponse (short-circuit)
        logger.debug(f"Calling view: {view_func.__module__}.{view_func.__name__}")
        return None


class RateLimitMiddleware:
    """IP-based rate limiting using Django cache."""
    
    def __init__(self, get_response):
        self.get_response = get_response
        self.rate_limit = getattr(settings, "RATE_LIMIT_PER_MINUTE", 60)
    
    def __call__(self, request):
        from django.core.cache import cache
        
        ip = self._get_client_ip(request)
        cache_key = f"rate_limit:{ip}"
        
        # Atomic increment
        request_count = cache.get(cache_key, 0)
        if request_count >= self.rate_limit:
            return JsonResponse(
                {
                    "error": "Rate limit exceeded",
                    "retry_after": 60,
                },
                status=429,
                headers={"Retry-After": "60"},
            )
        
        cache.set(cache_key, request_count + 1, timeout=60)
        
        response = self.get_response(request)
        response["X-RateLimit-Limit"] = str(self.rate_limit)
        response["X-RateLimit-Remaining"] = str(
            self.rate_limit - request_count - 1
        )
        return response
    
    def _get_client_ip(self, request):
        x_forwarded_for = request.META.get("HTTP_X_FORWARDED_FOR")
        if x_forwarded_for:
            return x_forwarded_for.split(",")[0].strip()
        return request.META.get("REMOTE_ADDR")


class CORSMiddleware:
    """Cross-Origin Resource Sharing headers."""
    
    ALLOWED_ORIGINS = [
        "https://frontend.example.com",
        "https://admin.example.com",
    ]
    
    def __init__(self, get_response):
        self.get_response = get_response
    
    def __call__(self, request):
        # Handle preflight OPTIONS requests
        if request.method == "OPTIONS":
            response = JsonResponse({}, status=200)
        else:
            response = self.get_response(request)
        
        origin = request.META.get("HTTP_ORIGIN")
        if origin in self.ALLOWED_ORIGINS:
            response["Access-Control-Allow-Origin"] = origin
            response["Access-Control-Allow-Methods"] = (
                "GET, POST, PUT, PATCH, DELETE, OPTIONS"
            )
            response["Access-Control-Allow-Headers"] = (
                "Content-Type, Authorization, X-Request-ID"
            )
            response["Access-Control-Max-Age"] = "86400"
            response["Access-Control-Allow-Credentials"] = "true"
        
        return response


# --- Register in settings.py ---
MIDDLEWARE = [
    "django.middleware.security.SecurityMiddleware",
    "myapp.middleware.RequestTimingMiddleware",     # Custom
    "myapp.middleware.RateLimitMiddleware",         # Custom
    "myapp.middleware.CORSMiddleware",              # Custom
    "django.contrib.sessions.middleware.SessionMiddleware",
    "django.middleware.common.CommonMiddleware",
    "django.middleware.csrf.CsrfViewMiddleware",
    "django.contrib.auth.middleware.AuthenticationMiddleware",
    "django.contrib.messages.middleware.MessageMiddleware",
    "django.middleware.clickjacking.XFrameOptionsMiddleware",
]
```

### 1.5 Custom Managers

```python
# ============================================================
# CUSTOM MANAGERS & QUERYSETS
# ============================================================
# Manager  = Interface between Model and Database (Model.objects)
# QuerySet = Collection of database queries that can be chained

from django.db import models
from django.utils import timezone
from datetime import timedelta


class BookQuerySet(models.QuerySet):
    """Custom QuerySet methods that are CHAINABLE."""
    
    def published(self):
        return self.filter(status="published", published__lte=timezone.now())
    
    def draft(self):
        return self.filter(status="draft")
    
    def by_author(self, author):
        return self.filter(author=author)
    
    def expensive(self, threshold=50):
        return self.filter(price__gt=threshold)
    
    def cheap(self, threshold=15):
        return self.filter(price__lt=threshold)
    
    def recent(self, days=30):
        cutoff = timezone.now() - timedelta(days=days)
        return self.filter(published__gte=cutoff)
    
    def with_stats(self):
        """Annotate with computed fields."""
        from django.db.models import Count, Avg
        return self.annotate(
            review_count=Count("reviews"),
            avg_rating=Avg("reviews__rating"),
        )
    
    def bestsellers(self, min_sales=1000):
        return self.filter(total_sales__gte=min_sales).order_by("-total_sales")
    
    def search(self, query):
        """Full-text search across multiple fields."""
        from django.db.models import Q
        return self.filter(
            Q(title__icontains=query) |
            Q(author__name__icontains=query) |
            Q(description__icontains=query)
        )


class BookManager(models.Manager):
    """Custom manager that uses the custom QuerySet."""
    
    def get_queryset(self):
        return BookQuerySet(self.model, using=self._db)
    
    # Proxy methods for easy access
    def published(self):
        return self.get_queryset().published()
    
    def search(self, query):
        return self.get_queryset().search(query)


class PublishedBookManager(models.Manager):
    """Manager that ALWAYS filters to published books only."""
    
    def get_queryset(self):
        return (
            super()
            .get_queryset()
            .filter(status="published", published__lte=timezone.now())
        )


class Book(models.Model):
    STATUS_CHOICES = [
        ("draft", "Draft"),
        ("published", "Published"),
        ("archived", "Archived"),
    ]
    
    title = models.CharField(max_length=300)
    author = models.ForeignKey("Author", on_delete=models.CASCADE, related_name="books")
    price = models.DecimalField(max_digits=10, decimal_places=2)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default="draft")
    published = models.DateTimeField(null=True, blank=True)
    total_sales = models.PositiveIntegerField(default=0)
    description = models.TextField(blank=True)
    
    # Multiple managers
    objects = BookManager()                     # Default: Book.objects.all()
    published_objects = PublishedBookManager()  # Book.published_objects.all()
    
    class Meta:
        default_manager_name = "objects"


# --- Usage Examples ---

# Chainable queries
books = (
    Book.objects
    .published()
    .expensive(threshold=30)
    .recent(days=90)
    .with_stats()
    .order_by("-avg_rating")
)

# Using the filtered manager
published = Book.published_objects.all()        # Always published only
published = Book.published_objects.filter(price__gt=20)  # Published AND expensive

# Search
results = Book.objects.search("django").published().with_stats()
```

### 1.6 Model Lifecycle

```python
# ============================================================
# COMPLETE MODEL LIFECYCLE
# ============================================================
#
# Model.save() internal flow:
#
# 1. Model.__init__()             → Object created in memory
# 2. pre_save signal fired        → Listeners notified
# 3. Model.clean_fields()         → Field-level validation
# 4. Model.clean()                → Model-level validation
# 5. Model.validate_unique()      → Uniqueness constraints
# 6. Model.save_base()            → Actual DB operation
#    6a. pre_save signal
#    6b. INSERT or UPDATE SQL
#    6c. post_save signal
# 7. post_save signal fired       → Listeners notified

from django.db import models
from django.core.exceptions import ValidationError
from django.utils import timezone
import uuid


class Order(models.Model):
    STATUS_FLOW = {
        "pending": ["confirmed", "cancelled"],
        "confirmed": ["processing", "cancelled"],
        "processing": ["shipped", "cancelled"],
        "shipped": ["delivered"],
        "delivered": [],       # Terminal state
        "cancelled": [],       # Terminal state
    }
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    customer = models.ForeignKey("auth.User", on_delete=models.PROTECT)
    status = models.CharField(max_length=20, default="pending")
    total = models.DecimalField(max_digits=12, decimal_places=2)
    notes = models.TextField(blank=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    confirmed_at = models.DateTimeField(null=True, blank=True)
    shipped_at = models.DateTimeField(null=True, blank=True)
    
    # Track original state for change detection
    _original_status = None
    
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        # Store original status when loaded from DB
        self._original_status = self.status
    
    def clean_fields(self, exclude=None):
        """Field-level validation."""
        super().clean_fields(exclude=exclude)
        if self.total is not None and self.total < 0:
            raise ValidationError({"total": "Order total cannot be negative."})
    
    def clean(self):
        """Cross-field / business rule validation."""
        super().clean()
        
        # Validate status transitions
        if self._original_status and self._original_status != self.status:
            allowed = self.STATUS_FLOW.get(self._original_status, [])
            if self.status not in allowed:
                raise ValidationError(
                    f"Cannot transition from '{self._original_status}' "
                    f"to '{self.status}'. Allowed: {allowed}"
                )
    
    def save(self, *args, **kwargs):
        """Override save to add custom logic."""
        # Run full validation
        self.full_clean()
        
        # Auto-set timestamps based on status changes
        now = timezone.now()
        if self.status == "confirmed" and not self.confirmed_at:
            self.confirmed_at = now
        elif self.status == "shipped" and not self.shipped_at:
            self.shipped_at = now
        
        is_new = self._state.adding  # True if INSERT, False if UPDATE
        old_status = self._original_status
        
        super().save(*args, **kwargs)
        
        # Post-save actions
        self._original_status = self.status
        
        if is_new:
            self._on_created()
        elif old_status != self.status:
            self._on_status_changed(old_status, self.status)
    
    def delete(self, *args, **kwargs):
        """Soft delete instead of hard delete."""
        if self.status not in ("pending", "cancelled"):
            raise ValidationError("Cannot delete orders that are in progress.")
        self.status = "cancelled"
        self.save(update_fields=["status", "updated_at"])
    
    def hard_delete(self, *args, **kwargs):
        """Actually remove from database."""
        super().delete(*args, **kwargs)
    
    def _on_created(self):
        """Hook called when a new order is created."""
        AuditLog.objects.create(
            entity_type="Order",
            entity_id=str(self.id),
            action="created",
            details=f"Order created with total ${self.total}",
        )
    
    def _on_status_changed(self, old_status, new_status):
        """Hook called when status changes."""
        AuditLog.objects.create(
            entity_type="Order",
            entity_id=str(self.id),
            action="status_changed",
            details=f"Status: {old_status} → {new_status}",
        )
        
        if new_status == "shipped":
            # Trigger notification
            from myapp.tasks import send_shipping_notification
            send_shipping_notification.delay(str(self.id))
    
    # --- Business methods ---
    def confirm(self):
        self.status = "confirmed"
        self.save()
    
    def ship(self, tracking_number):
        self.status = "shipped"
        self.tracking_number = tracking_number
        self.save()
    
    def cancel(self, reason=""):
        self.status = "cancelled"
        self.notes = f"Cancelled: {reason}"
        self.save()
```

### 1.7 Django Caching

```python
# ============================================================
# DJANGO CACHING — MULTI-LAYER STRATEGY
# ============================================================

# --- settings.py Cache Configuration ---
CACHES = {
    # Primary cache: Redis
    "default": {
        "BACKEND": "django_redis.cache.RedisCache",
        "LOCATION": "redis://redis:6379/1",
        "OPTIONS": {
            "CLIENT_CLASS": "django_redis.client.DefaultClient",
            "SERIALIZER": "django_redis.serializers.json.JSONSerializer",
            "CONNECTION_POOL_KWARGS": {"max_connections": 50},
            "SOCKET_CONNECT_TIMEOUT": 5,
            "SOCKET_TIMEOUT": 5,
        },
        "KEY_PREFIX": "myapp",
        "TIMEOUT": 300,  # 5 minutes default
    },
    # Secondary cache: Local memory (for very hot data)
    "local": {
        "BACKEND": "django.core.cache.backends.locmem.LocMemCache",
        "LOCATION": "local-cache",
        "TIMEOUT": 60,
    },
    # Session cache
    "sessions": {
        "BACKEND": "django_redis.cache.RedisCache",
        "LOCATION": "redis://redis:6379/2",
        "OPTIONS": {
            "CLIENT_CLASS": "django_redis.client.DefaultClient",
        },
    },
}

# Use Redis for sessions
SESSION_ENGINE = "django.contrib.sessions.backends.cache"
SESSION_CACHE_ALIAS = "sessions"


# --- Low-Level Cache API ---
from django.core.cache import cache, caches
import hashlib
import json

# Basic operations
cache.set("key", "value", timeout=300)
value = cache.get("key", default=None)
cache.delete("key")

# Atomic operations
cache.incr("page_views")
cache.decr("stock_count")

# Set if not exists
cache.add("lock:process_orders", "1", timeout=60)  # Returns False if exists

# Set multiple
cache.set_many({"key1": "val1", "key2": "val2"}, timeout=300)
values = cache.get_many(["key1", "key2"])

# Get or set pattern
def get_expensive_data():
    return Book.objects.with_stats().published()[:100]

books = cache.get_or_set("homepage_books", get_expensive_data, timeout=600)


# --- Cache Patterns ---
class CacheService:
    """Reusable cache patterns for the application."""
    
    @staticmethod
    def cache_key(*args):
        """Generate consistent cache keys."""
        raw = ":".join(str(a) for a in args)
        return f"app:{hashlib.md5(raw.encode()).hexdigest()}"
    
    @staticmethod
    def cached(timeout=300, key_prefix="", cache_alias="default"):
        """Decorator for caching function results."""
        def decorator(func):
            import functools
            @functools.wraps(func)
            def wrapper(*args, **kwargs):
                # Build cache key from function name + arguments
                key_parts = [key_prefix or func.__name__]
                key_parts.extend(str(a) for a in args)
                key_parts.extend(f"{k}={v}" for k, v in sorted(kwargs.items()))
                cache_key = CacheService.cache_key(*key_parts)
                
                selected_cache = caches[cache_alias]
                result = selected_cache.get(cache_key)
                if result is not None:
                    return result
                
                result = func(*args, **kwargs)
                selected_cache.set(cache_key, result, timeout=timeout)
                return result
            
            wrapper.cache_clear = lambda: None  # Add invalidation hook
            return wrapper
        return decorator
    
    @staticmethod
    def invalidate_pattern(pattern):
        """Delete all keys matching a pattern (Redis only)."""
        from django_redis import get_redis_connection
        conn = get_redis_connection("default")
        keys = conn.keys(f"myapp:{pattern}")
        if keys:
            conn.delete(*keys)


# Usage
class BookService:
    
    @CacheService.cached(timeout=600, key_prefix="book_detail")
    def get_book_detail(self, book_id):
        return (
            Book.objects
            .select_related("author")
            .prefetch_related("tags", "reviews")
            .get(id=book_id)
        )
    
    @CacheService.cached(timeout=300, key_prefix="book_list")
    def get_book_list(self, page=1, per_page=20, **filters):
        qs = Book.objects.published().with_stats()
        if filters.get("author_id"):
            qs = qs.filter(author_id=filters["author_id"])
        if filters.get("min_price"):
            qs = qs.filter(price__gte=filters["min_price"])
        
        start = (page - 1) * per_page
        return list(qs[start:start + per_page])
    
    def update_book(self, book_id, **data):
        book = Book.objects.get(id=book_id)
        for key, value in data.items():
            setattr(book, key, value)
        book.save()
        
        # Invalidate related caches
        cache.delete(CacheService.cache_key("book_detail", book_id))
        CacheService.invalidate_pattern("book_list:*")
        return book


# --- View-Level Caching ---
from django.views.decorators.cache import cache_page, cache_control
from django.views.decorators.vary import vary_on_headers, vary_on_cookie

# Cache entire view response for 15 minutes
@cache_page(60 * 15)
@vary_on_headers("Authorization")
def book_list_view(request):
    books = Book.objects.published()[:50]
    return JsonResponse({"books": list(books.values())})

# Cache control headers
@cache_control(max_age=3600, public=True)
def static_content_view(request):
    pass


# --- Template Fragment Caching ---
# In templates:
# {% load cache %}
# {% cache 600 sidebar request.user.id %}
#     ... expensive template fragment ...
# {% endcache %}


# --- Per-View Cache with Class-Based Views ---
from django.utils.decorators import method_decorator

@method_decorator(cache_page(300), name="dispatch")
class BookListView(ListView):
    model = Book
    queryset = Book.objects.published()
```

### 1.8 Celery Integration

```python
# ============================================================
# CELERY WITH DJANGO — ASYNC TASK PROCESSING
# ============================================================

# --- Project Structure ---
# myproject/
# ├── myproject/
# │   ├── __init__.py       ← Import celery app here
# │   ├── celery.py         ← Celery application config
# │   ├── settings.py
# │   └── urls.py
# ├── myapp/
# │   ├── tasks.py          ← Define tasks here
# │   └── ...
# └── manage.py

# --- myproject/celery.py ---
import os
from celery import Celery
from celery.schedules import crontab

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "myproject.settings")

app = Celery("myproject")
app.config_from_object("django.conf:settings", namespace="CELERY")
app.autodiscover_tasks()  # Auto-discover tasks.py in all installed apps


# --- myproject/__init__.py ---
from .celery import app as celery_app
__all__ = ("celery_app",)


# --- settings.py Celery configuration ---
CELERY_BROKER_URL = "redis://redis:6379/0"
CELERY_RESULT_BACKEND = "redis://redis:6379/0"
CELERY_ACCEPT_CONTENT = ["json"]
CELERY_TASK_SERIALIZER = "json"
CELERY_RESULT_SERIALIZER = "json"
CELERY_TIMEZONE = "UTC"
CELERY_TASK_TRACK_STARTED = True
CELERY_TASK_TIME_LIMIT = 300            # Hard kill after 5 min
CELERY_TASK_SOFT_TIME_LIMIT = 240       # Raise exception after 4 min
CELERY_WORKER_PREFETCH_MULTIPLIER = 1   # Fair task distribution
CELERY_WORKER_MAX_TASKS_PER_CHILD = 1000  # Prevent memory leaks

# Retry policy
CELERY_TASK_ACKS_LATE = True            # Ack after completion (not receipt)
CELERY_TASK_REJECT_ON_WORKER_LOST = True

# Rate limiting
CELERY_TASK_DEFAULT_RATE_LIMIT = "100/m"

# Periodic tasks (Celery Beat)
CELERY_BEAT_SCHEDULE = {
    "cleanup-expired-sessions": {
        "task": "myapp.tasks.cleanup_expired_sessions",
        "schedule": crontab(hour=2, minute=0),     # Daily at 2 AM
    },
    "generate-daily-report": {
        "task": "myapp.tasks.generate_daily_report",
        "schedule": crontab(hour=6, minute=0),
    },
    "sync-inventory": {
        "task": "myapp.tasks.sync_inventory",
        "schedule": 300.0,  # Every 5 minutes
    },
    "send-weekly-digest": {
        "task": "myapp.tasks.send_weekly_digest",
        "schedule": crontab(hour=9, minute=0, day_of_week=1),  # Monday 9 AM
    },
}


# --- myapp/tasks.py ---
from celery import shared_task, chain, group, chord
from celery.utils.log import get_task_logger
from django.core.mail import send_mail
from django.utils import timezone

logger = get_task_logger(__name__)


@shared_task(
    bind=True,
    max_retries=3,
    default_retry_delay=60,
    autoretry_for=(ConnectionError, TimeoutError),
    retry_backoff=True,          # Exponential backoff
    retry_backoff_max=600,       # Max 10 min between retries
    retry_jitter=True,           # Add randomness to prevent thundering herd
    acks_late=True,
    track_started=True,
    name="myapp.send_order_confirmation",
)
def send_order_confirmation(self, order_id):
    """
    Send order confirmation email.
    
    self is bound to the task instance (bind=True).
    """
    from myapp.models import Order
    
    try:
        order = Order.objects.select_related("customer").get(id=order_id)
        
        send_mail(
            subject=f"Order #{order.id} Confirmed",
            message=f"Dear {order.customer.first_name},\n\n"
                    f"Your order of ${order.total} has been confirmed.",
            from_email="orders@example.com",
            recipient_list=[order.customer.email],
        )
        
        logger.info(f"Confirmation sent for order {order_id}")
        return {"status": "sent", "order_id": str(order_id)}
        
    except Order.DoesNotExist:
        logger.error(f"Order {order_id} not found")
        # Don't retry for data errors
        return {"status": "error", "reason": "Order not found"}
    
    except Exception as exc:
        logger.error(f"Failed to send confirmation for order {order_id}: {exc}")
        # Retry with exponential backoff
        raise self.retry(exc=exc)


@shared_task(bind=True)
def generate_daily_report(self):
    """Generate and email daily sales report."""
    from myapp.models import Order
    from datetime import timedelta
    
    today = timezone.now().date()
    yesterday = today - timedelta(days=1)
    
    orders = Order.objects.filter(
        created_at__date=yesterday,
        status__in=["confirmed", "shipped", "delivered"],
    )
    
    report = {
        "date": str(yesterday),
        "total_orders": orders.count(),
        "total_revenue": float(orders.aggregate(Sum("total"))["total__sum"] or 0),
        "avg_order_value": float(orders.aggregate(Avg("total"))["total__avg"] or 0),
    }
    
    logger.info(f"Daily report: {report}")
    return report


@shared_task
def process_image(image_path, sizes=None):
    """CPU-intensive image processing task."""
    from PIL import Image
    
    sizes = sizes or [(100, 100), (300, 300), (800, 800)]
    results = []
    
    img = Image.open(image_path)
    for width, height in sizes:
        resized = img.resize((width, height))
        output_path = f"{image_path}_{width}x{height}.jpg"
        resized.save(output_path, "JPEG", quality=85)
        results.append(output_path)
    
    return results


# --- Task Composition: Chain, Group, Chord ---

def process_order_pipeline(order_id):
    """Chain multiple tasks in sequence."""
    pipeline = chain(
        validate_order.s(order_id),
        process_payment.s(),
        update_inventory.s(),
        send_order_confirmation.s(),
        notify_warehouse.s(),
    )
    pipeline.apply_async()

def process_bulk_images(image_paths):
    """Process multiple images in parallel."""
    job = group(
        process_image.s(path) for path in image_paths
    )
    result = job.apply_async()
    return result

def generate_composite_report():
    """Chord: parallel tasks + callback when all complete."""
    report_tasks = group(
        generate_sales_report.s(),
        generate_inventory_report.s(),
        generate_customer_report.s(),
    )
    callback = compile_master_report.s()
    chord(report_tasks)(callback)


# --- Calling Tasks ---

# Async execution (returns AsyncResult)
result = send_order_confirmation.delay(order_id="abc-123")
result = send_order_confirmation.apply_async(
    args=["abc-123"],
    countdown=60,              # Delay execution by 60 seconds
    expires=3600,              # Task expires after 1 hour
    queue="high_priority",     # Send to specific queue
    priority=9,                # Higher priority (0-9)
)

# Check task status
print(result.id)          # Task UUID
print(result.status)      # PENDING, STARTED, SUCCESS, FAILURE, RETRY
print(result.ready())     # True if completed
print(result.result)      # Return value (if SUCCESS) or exception (if FAILURE)
print(result.get(timeout=10))  # Block and wait for result

# --- Run workers ---
# celery -A myproject worker -l info -Q default,high_priority -c 4
# celery -A myproject beat -l info  # Periodic task scheduler
# celery -A myproject flower        # Web monitoring UI
```

### 1.9 Django Performance Tuning

```python
# ============================================================
# DJANGO PERFORMANCE TUNING — COMPREHENSIVE CHECKLIST
# ============================================================

# --- 1. Database Optimization ---

# settings.py: Connection pooling
DATABASES = {
    "default": {
        "ENGINE": "django.db.backends.postgresql",
        "NAME": "mydb",
        "CONN_MAX_AGE": 600,       # Persistent connections (seconds)
        "CONN_HEALTH_CHECKS": True, # Django 4.1+
        "OPTIONS": {
            "connect_timeout": 5,
        },
    },
}

# Database indexes (in models)
class Book(models.Model):
    title = models.CharField(max_length=300, db_index=True)
    isbn = models.CharField(max_length=13, unique=True)  # Implicit index
    
    class Meta:
        indexes = [
            models.Index(fields=["status", "published"]),   # Composite index
            models.Index(
                fields=["price"],
                condition=models.Q(status="published"),
                name="idx_published_price",                  # Partial index
            ),
            models.Index(
                fields=["-created_at"],
                name="idx_recent_books",                     # Descending
            ),
        ]
        # GIN index for full-text search (PostgreSQL)
        # GiST index for geographic data


# --- 2. Query Optimization Checklist ---
"""
□ Use select_related() for ForeignKey/OneToOne
□ Use prefetch_related() for ManyToMany/reverse FK
□ Use only()/defer() to limit columns
□ Use values()/values_list() when you don't need model instances
□ Use iterator() for large querysets (reduced memory)
□ Use exists() instead of count() > 0
□ Use bulk_create() / bulk_update() for batch operations
□ Use update() instead of save() for simple field updates
□ Avoid queries in loops
□ Use database-level aggregation (annotate/aggregate)
□ Use Subquery instead of Python-level filtering
□ Add appropriate database indexes
□ Use EXPLAIN ANALYZE to verify query plans
"""

# Bulk operations
Book.objects.bulk_create([
    Book(title=f"Book {i}", price=9.99, author_id=1)
    for i in range(10000)
], batch_size=1000)

Book.objects.filter(status="draft").update(status="archived")

Book.objects.bulk_update(books, ["price", "status"], batch_size=1000)

# Iterator for memory efficiency
for book in Book.objects.all().iterator(chunk_size=2000):
    process_book(book)  # Only chunk_size objects in memory at a time


# --- 3. Template & Response Optimization ---
TEMPLATES = [{
    "BACKEND": "django.template.backends.django.DjangoTemplates",
    "OPTIONS": {
        "loaders": [
            # Cache compiled templates in production
            ("django.template.loaders.cached.Loader", [
                "django.template.loaders.filesystem.Loader",
                "django.template.loaders.app_directories.Loader",
            ]),
        ],
    },
}]

# GZip middleware
MIDDLEWARE = [
    "django.middleware.gzip.GZipMiddleware",  # Compress responses
    # ...
]


# --- 4. Static & Media Files ---
# Use WhiteNoise for serving static files efficiently
STATICFILES_STORAGE = "whitenoise.storage.CompressedManifestStaticFilesStorage"

MIDDLEWARE = [
    "django.middleware.security.SecurityMiddleware",
    "whitenoise.middleware.WhiteNoiseMiddleware",  # Before all others
    # ...
]


# --- 5. Async Views (Django 4.1+) ---
import asyncio
import httpx

async def async_dashboard_view(request):
    """Handle multiple external API calls concurrently."""
    async with httpx.AsyncClient() as client:
        weather_task = client.get("https://api.weather.com/current")
        news_task = client.get("https://api.news.com/latest")
        stocks_task = client.get("https://api.stocks.com/portfolio")
        
        weather, news, stocks = await asyncio.gather(
            weather_task, news_task, stocks_task
        )
    
    return JsonResponse({
        "weather": weather.json(),
        "news": news.json(),
        "stocks": stocks.json(),
    })


# --- 6. Database Read Replicas ---
DATABASE_ROUTERS = ["myproject.routers.PrimaryReplicaRouter"]

class PrimaryReplicaRouter:
    def db_for_read(self, model, **hints):
        return "replica"
    
    def db_for_write(self, model, **hints):
        return "default"
    
    def allow_relation(self, obj1, obj2, **hints):
        return True
    
    def allow_migrate(self, db, app_label, model_name=None, **hints):
        return db == "default"
```

---

## PART 2 — FASTAPI

---

### 2.1 Dependency Injection

```python
# ============================================================
# FASTAPI DEPENDENCY INJECTION — FULL SYSTEM
# ============================================================
# FastAPI's DI is one of its most powerful features.
# Dependencies are declared as function parameters and resolved automatically.

from fastapi import FastAPI, Depends, HTTPException, Header, Query, Request
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine, async_sessionmaker
from sqlalchemy.orm import DeclarativeBase
from typing import Annotated, AsyncGenerator
from functools import lru_cache
import jwt

app = FastAPI(title="Bookstore API", version="2.0.0")


# ---- Configuration Dependency ----
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    database_url: str = "postgresql+asyncpg://user:pass@localhost/db"
    redis_url: str = "redis://localhost:6379"
    secret_key: str = "super-secret-key"
    algorithm: str = "HS256"
    access_token_expire_minutes: int = 30
    debug: bool = False
    
    class Config:
        env_file = ".env"

@lru_cache   # Singleton — created once, reused forever
def get_settings() -> Settings:
    return Settings()


# ---- Database Session Dependency ----
class Base(DeclarativeBase):
    pass

engine = create_async_engine(
    "postgresql+asyncpg://user:pass@localhost/db",
    echo=False,
    pool_size=20,
    max_overflow=10,
    pool_pre_ping=True,
)

AsyncSessionLocal = async_sessionmaker(
    engine, class_=AsyncSession, expire_on_commit=False
)

async def get_db() -> AsyncGenerator[AsyncSession, None]:
    """
    Yields a database session.
    The `finally` block ensures the session is closed even if an error occurs.
    This is a GENERATOR dependency — FastAPI handles the lifecycle.
    """
    session = AsyncSessionLocal()
    try:
        yield session
        await session.commit()
    except Exception:
        await session.rollback()
        raise
    finally:
        await session.close()


# ---- Authentication Dependencies (Layered) ----
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/token")

async def get_current_user(
    token: Annotated[str, Depends(oauth2_scheme)],
    db: Annotated[AsyncSession, Depends(get_db)],
    settings: Annotated[Settings, Depends(get_settings)],
):
    """Decode JWT token and return the user."""
    credentials_exception = HTTPException(
        status_code=401,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(
            token, settings.secret_key, algorithms=[settings.algorithm]
        )
        user_id: str = payload.get("sub")
        if user_id is None:
            raise credentials_exception
    except jwt.PyJWTError:
        raise credentials_exception
    
    from myapp.models import User
    from sqlalchemy import select
    
    result = await db.execute(select(User).where(User.id == int(user_id)))
    user = result.scalar_one_or_none()
    if user is None:
        raise credentials_exception
    return user


async def get_current_active_user(
    current_user: Annotated[dict, Depends(get_current_user)],
):
    """Ensure the user is active."""
    if not current_user.is_active:
        raise HTTPException(status_code=403, detail="Inactive user")
    return current_user


def require_role(*roles):
    """Factory function that returns a dependency for role-based access."""
    async def role_checker(
        user: Annotated[dict, Depends(get_current_active_user)],
    ):
        if user.role not in roles:
            raise HTTPException(
                status_code=403,
                detail=f"Role '{user.role}' not authorized. Required: {roles}",
            )
        return user
    return role_checker


# ---- Pagination Dependency ----
class PaginationParams:
    def __init__(
        self,
        page: Annotated[int, Query(ge=1, description="Page number")] = 1,
        per_page: Annotated[int, Query(ge=1, le=100, description="Items per page")] = 20,
    ):
        self.page = page
        self.per_page = per_page
        self.offset = (page - 1) * per_page
        self.limit = per_page


# ---- Service Layer Dependencies ----
class BookService:
    def __init__(
        self,
        db: AsyncSession,
        settings: Settings,
    ):
        self.db = db
        self.settings = settings
    
    async def get_books(self, offset: int = 0, limit: int = 20):
        from sqlalchemy import select
        from myapp.models import Book
        
        result = await self.db.execute(
            select(Book).offset(offset).limit(limit)
        )
        return result.scalars().all()
    
    async def create_book(self, data: dict):
        from myapp.models import Book
        book = Book(**data)
        self.db.add(book)
        await self.db.flush()
        return book

async def get_book_service(
    db: Annotated[AsyncSession, Depends(get_db)],
    settings: Annotated[Settings, Depends(get_settings)],
) -> BookService:
    return BookService(db=db, settings=settings)


# ---- Using Dependencies in Endpoints ----
@app.get("/books/")
async def list_books(
    service: Annotated[BookService, Depends(get_book_service)],
    pagination: Annotated[PaginationParams, Depends()],
    user: Annotated[dict, Depends(get_current_active_user)],
):
    """
    Dependency resolution order:
    1. get_settings()
    2. get_db()
    3. oauth2_scheme() → extracts token
    4. get_current_user(token, db, settings)
    5. get_current_active_user(user)
    6. get_book_service(db, settings)
    7. PaginationParams(page, per_page)
    """
    books = await service.get_books(
        offset=pagination.offset,
        limit=pagination.limit,
    )
    return {"books": books, "page": pagination.page}


@app.post("/books/")
async def create_book(
    book_data: BookCreateSchema,
    service: Annotated[BookService, Depends(get_book_service)],
    user: Annotated[dict, Depends(require_role("admin", "editor"))],
):
    book = await service.create_book(book_data.model_dump())
    return {"book": book}


# ---- Class-Based Dependencies ----
class RateLimiter:
    def __init__(self, max_requests: int = 10, window_seconds: int = 60):
        self.max_requests = max_requests
        self.window_seconds = window_seconds
    
    async def __call__(self, request: Request):
        # Implement rate limiting logic
        client_ip = request.client.host
        # Check against Redis, etc.
        # Raise HTTPException(429) if exceeded
        return True

# Use as dependency
rate_limiter = RateLimiter(max_requests=100, window_seconds=60)

@app.get("/public/", dependencies=[Depends(rate_limiter)])
async def public_endpoint():
    return {"message": "Hello"}
```

### 2.2 Async Endpoints

```python
# ============================================================
# FASTAPI ASYNC ENDPOINTS — COMPLETE PATTERNS
# ============================================================
import asyncio
import httpx
from fastapi import FastAPI, BackgroundTasks
from contextlib import asynccontextmanager
from typing import AsyncGenerator

# --- Application Lifespan (startup/shutdown) ---
@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncGenerator:
    """Manage application lifecycle resources."""
    # STARTUP
    print("Starting up...")
    app.state.http_client = httpx.AsyncClient(timeout=30)
    app.state.redis = await aioredis.from_url("redis://localhost")
    
    yield  # Application runs here
    
    # SHUTDOWN
    print("Shutting down...")
    await app.state.http_client.aclose()
    await app.state.redis.close()

app = FastAPI(lifespan=lifespan)


# --- Async vs Sync Endpoints ---

# ASYNC endpoint — runs on the event loop directly
# Use for: I/O-bound operations (DB queries, HTTP calls, file I/O)
@app.get("/async-endpoint")
async def async_endpoint():
    # These operations don't block the event loop
    async with httpx.AsyncClient() as client:
        response = await client.get("https://api.example.com/data")
    return response.json()

# SYNC endpoint — FastAPI runs it in a threadpool automatically
# Use for: CPU-bound operations, or when using sync libraries
@app.get("/sync-endpoint")
def sync_endpoint():
    # This runs in a separate thread, won't block the event loop
    import time
    time.sleep(1)  # Simulating CPU-bound work
    return {"result": "computed"}


# --- Concurrent External API Calls ---
@app.get("/dashboard")
async def dashboard(request: Request):
    """Fetch data from multiple APIs concurrently."""
    client = request.app.state.http_client
    
    # All three requests execute simultaneously
    results = await asyncio.gather(
        client.get("https://api.weather.com/current"),
        client.get("https://api.news.com/headlines"),
        client.get("https://api.stocks.com/prices"),
        return_exceptions=True,  # Don't fail if one request fails
    )
    
    weather, news, stocks = results
    
    return {
        "weather": weather.json() if not isinstance(weather, Exception) else None,
        "news": news.json() if not isinstance(news, Exception) else None,
        "stocks": stocks.json() if not isinstance(stocks, Exception) else None,
    }


# --- Async Database Operations ---
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func

@app.get("/books/{book_id}")
async def get_book(
    book_id: int,
    db: Annotated[AsyncSession, Depends(get_db)],
):
    result = await db.execute(
        select(Book)
        .options(selectinload(Book.author), selectinload(Book.reviews))
        .where(Book.id == book_id)
    )
    book = result.scalar_one_or_none()
    if not book:
        raise HTTPException(status_code=404, detail="Book not found")
    return book


# --- Streaming Responses ---
from fastapi.responses import StreamingResponse
import csv
import io

@app.get("/export/books")
async def export_books(db: Annotated[AsyncSession, Depends(get_db)]):
    """Stream large CSV export without loading everything into memory."""
    
    async def generate_csv():
        output = io.StringIO()
        writer = csv.writer(output)
        writer.writerow(["ID", "Title", "Author", "Price"])
        yield output.getvalue()
        output.seek(0)
        output.truncate(0)
        
        # Stream results in chunks
        result = await db.execute(select(Book).order_by(Book.id))
        for book in result.scalars():
            writer.writerow([book.id, book.title, book.author_id, book.price])
            yield output.getvalue()
            output.seek(0)
            output.truncate(0)
    
    return StreamingResponse(
        generate_csv(),
        media_type="text/csv",
        headers={"Content-Disposition": "attachment; filename=books.csv"},
    )


# --- WebSocket Endpoint ---
from fastapi import WebSocket, WebSocketDisconnect

class ConnectionManager:
    def __init__(self):
        self.active_connections: dict[str, list[WebSocket]] = {}
    
    async def connect(self, websocket: WebSocket, room: str):
        await websocket.accept()
        if room not in self.active_connections:
            self.active_connections[room] = []
        self.active_connections[room].append(websocket)
    
    def disconnect(self, websocket: WebSocket, room: str):
        self.active_connections[room].remove(websocket)
    
    async def broadcast(self, message: dict, room: str):
        for connection in self.active_connections.get(room, []):
            await connection.send_json(message)

manager = ConnectionManager()

@app.websocket("/ws/{room}")
async def websocket_endpoint(websocket: WebSocket, room: str):
    await manager.connect(websocket, room)
    try:
        while True:
            data = await websocket.receive_json()
            await manager.broadcast(
                {"user": data.get("user"), "message": data.get("message")},
                room,
            )
    except WebSocketDisconnect:
        manager.disconnect(websocket, room)
        await manager.broadcast({"message": "User left"}, room)
```

### 2.3 Pydantic Validation

```python
# ============================================================
# PYDANTIC V2 VALIDATION — COMPREHENSIVE
# ============================================================
from pydantic import (
    BaseModel, Field, field_validator, model_validator,
    ConfigDict, EmailStr, HttpUrl, constr, conint,
    computed_field,
)
from typing import Optional, Annotated
from datetime import datetime, date
from decimal import Decimal
from enum import Enum
import re
import uuid


class BookStatus(str, Enum):
    DRAFT = "draft"
    PUBLISHED = "published"
    ARCHIVED = "archived"


# --- Schema Inheritance Pattern ---
class BookBase(BaseModel):
    """Shared fields between create/update/response schemas."""
    
    model_config = ConfigDict(
        str_strip_whitespace=True,     # Strip whitespace from strings
        str_min_length=1,              # No empty strings (unless Optional)
        from_attributes=True,          # Allow ORM model → Pydantic conversion
        json_schema_extra={
            "examples": [{
                "title": "The Hobbit",
                "isbn": "978-0-261-10295-1",
                "price": 12.99,
                "author_id": 1,
            }]
        },
    )
    
    title: Annotated[str, Field(
        min_length=1,
        max_length=300,
        description="Book title",
        examples=["The Hobbit"],
    )]
    
    isbn: Annotated[str, Field(
        pattern=r"^\d{3}-\d-\d{3}-\d{5}-\d$",
        description="ISBN-13 format",
    )]
    
    price: Annotated[Decimal, Field(
        ge=0,
        le=99999.99,
        decimal_places=2,
        description="Book price in USD",
    )]
    
    tags: list[str] = Field(
        default_factory=list,
        max_length=10,
        description="List of tags (max 10)",
    )
    
    # Field-level validators
    @field_validator("title")
    @classmethod
    def title_must_be_titlecase(cls, v: str) -> str:
        return v.title()
    
    @field_validator("isbn")
    @classmethod
    def validate_isbn_checksum(cls, v: str) -> str:
        """Validate ISBN-13 checksum."""
        digits = v.replace("-", "")
        if len(digits) != 13:
            raise ValueError("ISBN must have 13 digits")
        
        total = sum(
            int(d) * (1 if i % 2 == 0 else 3)
            for i, d in enumerate(digits)
        )
        if total % 10 != 0:
            raise ValueError("Invalid ISBN checksum")
        return v
    
    @field_validator("tags", mode="before")
    @classmethod
    def normalize_tags(cls, v):
        if isinstance(v, str):
            v = [t.strip() for t in v.split(",")]
        return [t.lower().strip() for t in v if t.strip()]


class BookCreate(BookBase):
    """Schema for creating a new book."""
    author_id: int = Field(gt=0)
    status: BookStatus = BookStatus.DRAFT
    published_date: Optional[date] = None
    
    @model_validator(mode="after")
    def validate_published_date(self):
        """Cross-field validation."""
        if self.status == BookStatus.PUBLISHED and not self.published_date:
            raise ValueError(
                "Published date is required when status is 'published'"
            )
        if self.published_date and self.published_date > date.today():
            raise ValueError("Published date cannot be in the future")
        return self


class BookUpdate(BaseModel):
    """Schema for updating — all fields optional."""
    model_config = ConfigDict(from_attributes=True)
    
    title: Optional[str] = Field(None, min_length=1, max_length=300)
    price: Optional[Decimal] = Field(None, ge=0, le=99999.99)
    status: Optional[BookStatus] = None
    tags: Optional[list[str]] = None


class AuthorResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    
    id: int
    name: str
    email: EmailStr


class BookResponse(BookBase):
    """Schema for API responses — includes DB-generated fields."""
    model_config = ConfigDict(from_attributes=True)
    
    id: int
    status: BookStatus
    author: AuthorResponse
    created_at: datetime
    updated_at: datetime
    
    @computed_field
    @property
    def price_with_tax(self) -> Decimal:
        return round(self.price * Decimal("1.1"), 2)
    
    @computed_field
    @property
    def is_available(self) -> bool:
        return self.status == BookStatus.PUBLISHED


class PaginatedResponse(BaseModel):
    """Generic paginated response wrapper."""
    items: list[BookResponse]
    total: int
    page: int
    per_page: int
    pages: int
    
    @computed_field
    @property
    def has_next(self) -> bool:
        return self.page < self.pages
    
    @computed_field
    @property
    def has_prev(self) -> bool:
        return self.page > 1


# --- Complex Nested Validation ---
class Address(BaseModel):
    street: str = Field(min_length=5)
    city: str
    state: str = Field(min_length=2, max_length=2)
    zip_code: str = Field(pattern=r"^\d{5}(-\d{4})?$")
    country: str = "US"

class OrderItem(BaseModel):
    book_id: int = Field(gt=0)
    quantity: int = Field(gt=0, le=100)
    unit_price: Decimal = Field(ge=0)
    
    @computed_field
    @property
    def subtotal(self) -> Decimal:
        return self.unit_price * self.quantity

class OrderCreate(BaseModel):
    customer_email: EmailStr
    shipping_address: Address
    items: list[OrderItem] = Field(min_length=1, max_length=50)
    coupon_code: Optional[str] = None
    notes: Optional[str] = Field(None, max_length=500)
    
    @model_validator(mode="after")
    def validate_order(self):
        # Check for duplicate books
        book_ids = [item.book_id for item in self.items]
        if len(book_ids) != len(set(book_ids)):
            raise ValueError("Duplicate books in order")
        
        # Validate total
        total = sum(item.subtotal for item in self.items)
        if total <= 0:
            raise ValueError("Order total must be positive")
        
        return self


# --- Using Schemas in Endpoints ---
@app.post("/books/", response_model=BookResponse, status_code=201)
async def create_book(
    book_data: BookCreate,   # ← Request body validated automatically
    service: Annotated[BookService, Depends(get_book_service)],
    user: Annotated[dict, Depends(require_role("admin"))],
):
    """
    FastAPI automatically:
    1. Parses the JSON request body
    2. Validates against BookCreate schema
    3. Returns 422 with details if validation fails
    4. Converts the response to BookResponse schema
    """
    book = await service.create_book(book_data.model_dump())
    return book


@app.patch("/books/{book_id}", response_model=BookResponse)
async def update_book(
    book_id: int,
    book_data: BookUpdate,
    service: Annotated[BookService, Depends(get_book_service)],
):
    # Only include fields that were explicitly set (not None defaults)
    update_data = book_data.model_dump(exclude_unset=True)
    book = await service.update_book(book_id, update_data)
    return book
```

### 2.4 Background Tasks

```python
# ============================================================
# FASTAPI BACKGROUND TASKS
# ============================================================
from fastapi import BackgroundTasks
import logging

logger = logging.getLogger(__name__)

# --- Simple Background Tasks (built-in) ---
def write_audit_log(user_id: int, action: str, details: str):
    """Runs AFTER the response is sent to the client."""
    logger.info(f"AUDIT: User {user_id} performed {action}: {details}")
    # Write to database, file, external service, etc.

def send_notification_email(email: str, subject: str, body: str):
    """Send email in background."""
    import smtplib
    from email.mime.text import MIMEText
    
    msg = MIMEText(body)
    msg["Subject"] = subject
    msg["To"] = email
    
    with smtplib.SMTP("smtp.example.com") as server:
        server.send_message(msg)

@app.post("/books/", status_code=201)
async def create_book(
    book_data: BookCreate,
    background_tasks: BackgroundTasks,
    user: Annotated[dict, Depends(get_current_active_user)],
):
    book = await book_service.create_book(book_data)
    
    # These run AFTER the response is sent
    background_tasks.add_task(
        write_audit_log, user.id, "create_book", f"Book: {book.title}"
    )
    background_tasks.add_task(
        send_notification_email,
        "admin@example.com",
        f"New Book: {book.title}",
        f"A new book '{book.title}' was added by {user.name}.",
    )
    
    # Response is sent immediately — tasks run in background
    return {"book": book, "message": "Book created successfully"}


# --- Background Tasks in Dependencies ---
async def log_request(
    request: Request,
    background_tasks: BackgroundTasks,
):
    """Dependency that adds logging as a background task."""
    def _log(method, path, client):
        logger.info(f"Request: {method} {path} from {client}")
    
    background_tasks.add_task(_log, request.method, request.url.path, request.client.host)

@app.get("/items/", dependencies=[Depends(log_request)])
async def list_items():
    return {"items": []}


# --- For Heavy Tasks: Use Celery/ARQ instead ---
# BackgroundTasks runs in the SAME process. For heavy work, use a task queue.

# Using ARQ (async-compatible task queue)
from arq import create_pool
from arq.connections import RedisSettings

async def startup():
    app.state.arq_pool = await create_pool(RedisSettings())

# In your endpoint:
@app.post("/reports/generate")
async def generate_report(request: Request):
    job = await request.app.state.arq_pool.enqueue_job(
        "generate_report_task",
        report_type="monthly",
        month="2024-01",
    )
    return {"job_id": job.job_id, "status": "queued"}
```

---

## PART 3 — FLASK

---

### 3.1 Application Factory

```python
# ============================================================
# FLASK APPLICATION FACTORY PATTERN
# ============================================================
#
# Project Structure:
# myapp/
# ├── __init__.py          ← Application factory
# ├── config.py            ← Configuration classes
# ├── extensions.py        ← Extension instances
# ├── models/
# │   ├── __init__.py
# │   ├── user.py
# │   └── book.py
# ├── api/
# │   ├── __init__.py      ← Blueprint registration
# │   ├── auth.py
# │   ├── books.py
# │   └── users.py
# ├── services/
# │   ├── __init__.py
# │   ├── book_service.py
# │   └── auth_service.py
# ├── middleware.py
# └── utils.py

# --- config.py ---
import os

class Config:
    """Base configuration."""
    SECRET_KEY = os.environ.get("SECRET_KEY", "dev-secret-key")
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    JSON_SORT_KEYS = False
    
    # Celery
    CELERY_BROKER_URL = os.environ.get("CELERY_BROKER_URL", "redis://localhost:6379/0")
    
    # Cache
    CACHE_TYPE = "RedisCache"
    CACHE_REDIS_URL = os.environ.get("REDIS_URL", "redis://localhost:6379/1")
    CACHE_DEFAULT_TIMEOUT = 300
    
    # Rate limiting
    RATELIMIT_STORAGE_URI = os.environ.get("REDIS_URL", "redis://localhost:6379/2")

class DevelopmentConfig(Config):
    DEBUG = True
    SQLALCHEMY_DATABASE_URI = "postgresql://user:pass@localhost/dev_db"
    SQLALCHEMY_ECHO = True  # Log SQL queries

class TestingConfig(Config):
    TESTING = True
    SQLALCHEMY_DATABASE_URI = "sqlite:///:memory:"
    WTF_CSRF_ENABLED = False

class ProductionConfig(Config):
    DEBUG = False
    SQLALCHEMY_DATABASE_URI = os.environ["DATABASE_URL"]
    SQLALCHEMY_ENGINE_OPTIONS = {
        "pool_size": 20,
        "max_overflow": 10,
        "pool_pre_ping": True,
        "pool_recycle": 300,
    }

config_map = {
    "development": DevelopmentConfig,
    "testing": TestingConfig,
    "production": ProductionConfig,
}


# --- extensions.py ---
from flask_sqlalchemy import SQLAlchemy
from flask_migrate import Migrate
from flask_marshmallow import Marshmallow
from flask_caching import Cache
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address
from flask_cors import CORS
from flask_jwt_extended import JWTManager

# Create extension instances WITHOUT initializing them
db = SQLAlchemy()
migrate = Migrate()
ma = Marshmallow()
cache = Cache()
limiter = Limiter(key_func=get_remote_address)
cors = CORS()
jwt = JWTManager()


# --- __init__.py (Application Factory) ---
from flask import Flask
from myapp.config import config_map

def create_app(config_name=None):
    """
    Application factory function.
    
    Why use a factory?
    1. Testing — Create separate app instances with test config
    2. Multiple instances — Run different configs simultaneously
    3. Delayed initialization — Extensions don't need a global app
    4. Clean separation — No circular imports
    """
    if config_name is None:
        config_name = os.environ.get("FLASK_ENV", "development")
    
    app = Flask(__name__)
    app.config.from_object(config_map[config_name])
    
    # Initialize extensions with this app instance
    _init_extensions(app)
    
    # Register blueprints
    _register_blueprints(app)
    
    # Register error handlers
    _register_error_handlers(app)
    
    # Register CLI commands
    _register_cli_commands(app)
    
    # Register middleware
    _register_middleware(app)
    
    # Shell context for `flask shell`
    @app.shell_context_processor
    def make_shell_context():
        from myapp.models import User, Book
        return {"db": db, "User": User, "Book": Book}
    
    return app


def _init_extensions(app):
    from myapp.extensions import db, migrate, ma, cache, limiter, cors, jwt
    
    db.init_app(app)
    migrate.init_app(app, db)
    ma.init_app(app)
    cache.init_app(app)
    limiter.init_app(app)
    cors.init_app(app, resources={
        r"/api/*": {
            "origins": app.config.get("ALLOWED_ORIGINS", "*"),
            "methods": ["GET", "POST", "PUT", "PATCH", "DELETE"],
            "allow_headers": ["Authorization", "Content-Type"],
        }
    })
    jwt.init_app(app)
    
    # JWT error handlers
    @jwt.expired_token_loader
    def expired_token_callback(jwt_header, jwt_payload):
        return {"error": "Token has expired"}, 401
    
    @jwt.invalid_token_loader
    def invalid_token_callback(error):
        return {"error": "Invalid token"}, 401


def _register_blueprints(app):
    from myapp.api.auth import auth_bp
    from myapp.api.books import books_bp
    from myapp.api.users import users_bp
    
    app.register_blueprint(auth_bp, url_prefix="/api/auth")
    app.register_blueprint(books_bp, url_prefix="/api/books")
    app.register_blueprint(users_bp, url_prefix="/api/users")


def _register_error_handlers(app):
    from werkzeug.exceptions import HTTPException
    
    @app.errorhandler(HTTPException)
    def handle_http_error(error):
        return {
            "error": error.name,
            "message": error.description,
            "status_code": error.code,
        }, error.code
    
    @app.errorhandler(Exception)
    def handle_generic_error(error):
        app.logger.error(f"Unhandled exception: {error}", exc_info=True)
        if app.debug:
            raise error
        return {"error": "Internal server error"}, 500


def _register_cli_commands(app):
    @app.cli.command("seed")
    def seed_database():
        """Seed the database with test data."""
        from myapp.seeds import run_seeds
        run_seeds()
        print("Database seeded successfully!")


def _register_middleware(app):
    import time
    import uuid
    
    @app.before_request
    def before_request():
        from flask import g, request
        g.request_id = str(uuid.uuid4())
        g.start_time = time.perf_counter()
    
    @app.after_request
    def after_request(response):
        from flask import g
        duration = time.perf_counter() - g.start_time
        response.headers["X-Request-ID"] = g.request_id
        response.headers["X-Response-Time"] = f"{duration:.4f}s"
        return response


# --- Run the application ---
# wsgi.py
app = create_app()

if __name__ == "__main__":
    app.run()

# Or with gunicorn:
# gunicorn "myapp:create_app()" --workers 4 --bind 0.0.0.0:8000
```

### 3.2 Blueprint Architecture

```python
# ============================================================
# FLASK BLUEPRINTS — MODULAR APPLICATION DESIGN
# ============================================================

# --- api/books.py ---
from flask import Blueprint, request, jsonify, g
from flask_jwt_extended import jwt_required, get_jwt_identity
from myapp.extensions import db, cache, limiter
from myapp.models.book import Book
from myapp.schemas.book import BookSchema, BookCreateSchema
from myapp.services.book_service import BookService
from functools import wraps

books_bp = Blueprint("books", __name__)
book_schema = BookSchema()
books_schema = BookSchema(many=True)
book_create_schema = BookCreateSchema()


# --- Blueprint-level error handler ---
@books_bp.errorhandler(404)
def book_not_found(error):
    return {"error": "Book not found"}, 404


# --- Blueprint-level before_request ---
@books_bp.before_request
def log_book_access():
    g.service = BookService()


# --- Decorator for role-based access ---
def require_role(*roles):
    def decorator(f):
        @wraps(f)
        @jwt_required()
        def decorated(*args, **kwargs):
            user_id = get_jwt_identity()
            from myapp.models.user import User
            user = db.session.get(User, user_id)
            if not user or user.role not in roles:
                return {"error": "Insufficient permissions"}, 403
            g.current_user = user
            return f(*args, **kwargs)
        return decorated
    return decorator


# --- CRUD Endpoints ---

@books_bp.route("/", methods=["GET"])
@cache.cached(timeout=60, query_string=True)  # Cache with query params
@limiter.limit("100/minute")
def list_books():
    """
    GET /api/books/?page=1&per_page=20&author=tolkien&min_price=10
    """
    page = request.args.get("page", 1, type=int)
    per_page = request.args.get("per_page", 20, type=int)
    author = request.args.get("author")
    min_price = request.args.get("min_price", type=float)
    sort = request.args.get("sort", "created_at")
    order = request.args.get("order", "desc")
    
    query = Book.query.filter_by(status="published")
    
    if author:
        query = query.join(Book.author).filter(
            Author.name.ilike(f"%{author}%")
        )
    if min_price is not None:
        query = query.filter(Book.price >= min_price)
    
    # Dynamic sorting
    sort_column = getattr(Book, sort, Book.created_at)
    if order == "desc":
        sort_column = sort_column.desc()
    query = query.order_by(sort_column)
    
    pagination = query.paginate(page=page, per_page=per_page, error_out=False)
    
    return {
        "books": books_schema.dump(pagination.items),
        "pagination": {
            "page": pagination.page,
            "per_page": pagination.per_page,
            "total": pagination.total,
            "pages": pagination.pages,
            "has_next": pagination.has_next,
            "has_prev": pagination.has_prev,
        },
    }


@books_bp.route("/<int:book_id>", methods=["GET"])
@cache.cached(timeout=300)
def get_book(book_id):
    """GET /api/books/123"""
    book = db.session.get(Book, book_id)
    if not book:
        return {"error": "Book not found"}, 404
    return book_schema.dump(book)


@books_bp.route("/", methods=["POST"])
@require_role("admin", "editor")
def create_book():
    """POST /api/books/"""
    errors = book_create_schema.validate(request.json)
    if errors:
        return {"errors": errors}, 422
    
    data = book_create_schema.load(request.json)
    book = g.service.create_book(data, g.current_user)
    
    cache.delete_memoized(list_books)  # Invalidate list cache
    
    return book_schema.dump(book), 201


@books_bp.route("/<int:book_id>", methods=["PATCH"])
@require_role("admin", "editor")
def update_book(book_id):
    """PATCH /api/books/123"""
    book = db.session.get(Book, book_id)
    if not book:
        return {"error": "Book not found"}, 404
    
    data = request.json
    for key, value in data.items():
        if hasattr(book, key):
            setattr(book, key, value)
    
    db.session.commit()
    cache.delete(f"books:get_book:{book_id}")
    
    return book_schema.dump(book)


@books_bp.route("/<int:book_id>", methods=["DELETE"])
@require_role("admin")
def delete_book(book_id):
    """DELETE /api/books/123"""
    book = db.session.get(Book, book_id)
    if not book:
        return {"error": "Book not found"}, 404
    
    db.session.delete(book)
    db.session.commit()
    
    return "", 204


# --- Nested Blueprint ---
# api/books/reviews.py
reviews_bp = Blueprint("reviews", __name__)

@reviews_bp.route("/", methods=["GET"])
def list_reviews(book_id):
    reviews = Review.query.filter_by(book_id=book_id).all()
    return {"reviews": ReviewSchema(many=True).dump(reviews)}

@reviews_bp.route("/", methods=["POST"])
@jwt_required()
def create_review(book_id):
    pass

# Register nested blueprint
books_bp.register_blueprint(reviews_bp, url_prefix="/<int:book_id>/reviews")
# Result: GET /api/books/123/reviews/
```

### 3.3 Flask Middleware

```python
# ============================================================
# FLASK MIDDLEWARE — WSGI & FLASK PATTERNS
# ============================================================

# --- Method 1: before_request / after_request hooks ---
import time
import uuid
from flask import Flask, g, request, jsonify

app = create_app()

@app.before_request
def start_timer():
    g.start_time = time.perf_counter()
    g.request_id = request.headers.get("X-Request-ID", str(uuid.uuid4()))

@app.after_request
def add_headers(response):
    # Timing
    duration = time.perf_counter() - g.start_time
    response.headers["X-Response-Time"] = f"{duration:.4f}s"
    response.headers["X-Request-ID"] = g.request_id
    
    # Security headers
    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["X-Frame-Options"] = "DENY"
    response.headers["X-XSS-Protection"] = "1; mode=block"
    response.headers["Strict-Transport-Security"] = "max-age=31536000"
    
    # Log request
    app.logger.info(
        f"{request.method} {request.path} → {response.status_code} "
        f"({duration*1000:.1f}ms) [ID: {g.request_id}]"
    )
    
    return response

@app.teardown_request
def teardown_request(exception):
    """Called after the response has been sent, even if an error occurred."""
    if exception:
        app.logger.error(f"Request failed: {exception}")


# --- Method 2: True WSGI Middleware ---
class ProfilingMiddleware:
    """
    WSGI middleware that wraps the entire Flask application.
    Has access to the raw WSGI environ — runs OUTSIDE Flask.
    """
    
    def __init__(self, app, profile_dir="/tmp/profiles"):
        self.app = app
        self.profile_dir = profile_dir
    
    def __call__(self, environ, start_response):
        # Check if profiling is requested
        if environ.get("HTTP_X_PROFILE") == "true":
            import cProfile
            import pstats
            import io
            
            profiler = cProfile.Profile()
            profiler.enable()
            
            response = self.app(environ, start_response)
            
            profiler.disable()
            stream = io.StringIO()
            stats = pstats.Stats(profiler, stream=stream)
            stats.sort_stats("cumulative")
            stats.print_stats(20)
            
            # Log or save profile
            print(stream.getvalue())
            
            return response
        
        return self.app(environ, start_response)


class SecurityMiddleware:
    """Enforce security at the WSGI level."""
    
    def __init__(self, app):
        self.app = app
    
    def __call__(self, environ, start_response):
        # Block requests with oversized bodies
        content_length = environ.get("CONTENT_LENGTH", "0")
        if content_length and int(content_length) > 10 * 1024 * 1024:  # 10 MB
            start_response("413 Payload Too Large", [("Content-Type", "application/json")])
            return [b'{"error": "Payload too large"}']
        
        # Block suspicious user agents
        user_agent = environ.get("HTTP_USER_AGENT", "").lower()
        blocked_agents = ["sqlmap", "nikto", "nmap"]
        if any(agent in user_agent for agent in blocked_agents):
            start_response("403 Forbidden", [("Content-Type", "application/json")])
            return [b'{"error": "Blocked"}']
        
        return self.app(environ, start_response)


# Apply WSGI middleware
app = create_app()
app.wsgi_app = ProfilingMiddleware(app.wsgi_app)
app.wsgi_app = SecurityMiddleware(app.wsgi_app)
```

---

## PART 4 — API ENGINEERING

---

### 4.1 REST Principles & HATEOAS

```python
# ============================================================
# REST PRINCIPLES — RICHARDSON MATURITY MODEL
# ============================================================
#
# Level 0: Single endpoint, RPC-style (POST /api)
# Level 1: Multiple resources (/books, /authors)
# Level 2: HTTP verbs (GET, POST, PUT, DELETE) + status codes
# Level 3: HATEOAS (Hypermedia as the Engine of Application State)
#
# REST Constraints:
# 1. Client-Server separation
# 2. Stateless — each request contains all info needed
# 3. Cacheable — responses must define cacheability
# 4. Uniform Interface — consistent resource representation
# 5. Layered System — client doesn't know if it talks to server directly
# 6. Code on Demand (optional) — server can extend client functionality

from fastapi import FastAPI, Request
from pydantic import BaseModel, Field, HttpUrl
from typing import Optional

app = FastAPI()


# --- HATEOAS Implementation ---
class Link(BaseModel):
    """Hypermedia link following RFC 8288."""
    href: str
    rel: str                 # Relationship type
    method: str = "GET"      # HTTP method
    title: Optional[str] = None

class HATEOASResponse(BaseModel):
    """Base response with hypermedia links."""
    _links: dict[str, Link] = Field(default_factory=dict)

class BookResponse(BaseModel):
    id: int
    title: str
    author_id: int
    price: float
    status: str
    _links: dict[str, Link]
    _embedded: Optional[dict] = None

def build_book_links(request: Request, book) -> dict[str, Link]:
    base = str(request.base_url).rstrip("/")
    links = {
        "self": Link(
            href=f"{base}/api/v1/books/{book.id}",
            rel="self",
            method="GET",
            title="This book",
        ),
        "update": Link(
            href=f"{base}/api/v1/books/{book.id}",
            rel="update",
            method="PATCH",
            title="Update this book",
        ),
        "delete": Link(
            href=f"{base}/api/v1/books/{book.id}",
            rel="delete",
            method="DELETE",
            title="Delete this book",
        ),
        "author": Link(
            href=f"{base}/api/v1/authors/{book.author_id}",
            rel="author",
            method="GET",
            title="Book's author",
        ),
        "reviews": Link(
            href=f"{base}/api/v1/books/{book.id}/reviews",
            rel="reviews",
            method="GET",
            title="Book reviews",
        ),
        "collection": Link(
            href=f"{base}/api/v1/books",
            rel="collection",
            method="GET",
            title="All books",
        ),
    }
    
    # Conditional links based on state
    if book.status == "draft":
        links["publish"] = Link(
            href=f"{base}/api/v1/books/{book.id}/publish",
            rel="publish",
            method="POST",
            title="Publish this book",
        )
    elif book.status == "published":
        links["archive"] = Link(
            href=f"{base}/api/v1/books/{book.id}/archive",
            rel="archive",
            method="POST",
            title="Archive this book",
        )
    
    return links


def build_collection_links(request: Request, page, per_page, total) -> dict:
    base = str(request.base_url).rstrip("/")
    total_pages = (total + per_page - 1) // per_page
    
    links = {
        "self": Link(
            href=f"{base}/api/v1/books?page={page}&per_page={per_page}",
            rel="self",
        ),
        "first": Link(
            href=f"{base}/api/v1/books?page=1&per_page={per_page}",
            rel="first",
        ),
        "last": Link(
            href=f"{base}/api/v1/books?page={total_pages}&per_page={per_page}",
            rel="last",
        ),
    }
    
    if page > 1:
        links["prev"] = Link(
            href=f"{base}/api/v1/books?page={page-1}&per_page={per_page}",
            rel="prev",
        )
    if page < total_pages:
        links["next"] = Link(
            href=f"{base}/api/v1/books?page={page+1}&per_page={per_page}",
            rel="next",
        )
    
    return links


@app.get("/api/v1/books")
async def list_books(request: Request, page: int = 1, per_page: int = 20):
    books = await get_books(page, per_page)
    total = await get_book_count()
    
    return {
        "_links": build_collection_links(request, page, per_page, total),
        "_embedded": {
            "books": [
                {
                    "id": b.id,
                    "title": b.title,
                    "price": b.price,
                    "_links": build_book_links(request, b),
                }
                for b in books
            ],
        },
        "page": page,
        "per_page": per_page,
        "total": total,
    }


@app.get("/api/v1/books/{book_id}")
async def get_book(request: Request, book_id: int):
    book = await fetch_book(book_id)
    return {
        "id": book.id,
        "title": book.title,
        "author_id": book.author_id,
        "price": float(book.price),
        "status": book.status,
        "_links": build_book_links(request, book),
        "_embedded": {
            "author": {
                "id": book.author.id,
                "name": book.author.name,
                "_links": {
                    "self": {
                        "href": f"/api/v1/authors/{book.author.id}",
                        "rel": "self",
                    },
                },
            },
        },
    }

# Example Response:
# {
#   "id": 42,
#   "title": "The Hobbit",
#   "price": 12.99,
#   "status": "published",
#   "_links": {
#     "self":    {"href": "/api/v1/books/42", "rel": "self", "method": "GET"},
#     "update":  {"href": "/api/v1/books/42", "rel": "update", "method": "PATCH"},
#     "delete":  {"href": "/api/v1/books/42", "rel": "delete", "method": "DELETE"},
#     "author":  {"href": "/api/v1/authors/7", "rel": "author", "method": "GET"},
#     "reviews": {"href": "/api/v1/books/42/reviews", "rel": "reviews", "method": "GET"},
#     "archive": {"href": "/api/v1/books/42/archive", "rel": "archive", "method": "POST"}
#   },
#   "_embedded": {
#     "author": {"id": 7, "name": "J.R.R. Tolkien", "_links": {...}}
#   }
# }
```

### 4.2 Versioning, Pagination & Filtering

```python
# ============================================================
# API VERSIONING STRATEGIES
# ============================================================

# Strategy 1: URL Path Versioning (Most Common)
# /api/v1/books
# /api/v2/books

from fastapi import APIRouter, FastAPI

app = FastAPI()

v1_router = APIRouter(prefix="/api/v1", tags=["v1"])
v2_router = APIRouter(prefix="/api/v2", tags=["v2"])

@v1_router.get("/books")
async def list_books_v1():
    """Original implementation."""
    return {"books": [...], "version": 1}

@v2_router.get("/books")
async def list_books_v2():
    """New implementation with breaking changes."""
    return {"data": {"books": [...]}, "meta": {"version": 2}}

app.include_router(v1_router)
app.include_router(v2_router)


# Strategy 2: Header Versioning
# Accept: application/vnd.myapp.v2+json

@app.get("/api/books")
async def list_books(request: Request):
    accept = request.headers.get("Accept", "")
    if "v2" in accept:
        return await list_books_v2_impl()
    return await list_books_v1_impl()


# Strategy 3: Query Parameter Versioning
# /api/books?version=2

@app.get("/api/books")
async def list_books(version: int = 1):
    if version == 2:
        return await list_books_v2_impl()
    return await list_books_v1_impl()


# ============================================================
# PAGINATION STRATEGIES
# ============================================================

# --- Offset-based Pagination ---
class OffsetPagination(BaseModel):
    page: int = Field(ge=1, default=1)
    per_page: int = Field(ge=1, le=100, default=20)

@app.get("/api/v1/books")
async def list_books_offset(
    pagination: Annotated[OffsetPagination, Depends()],
    db: Annotated[AsyncSession, Depends(get_db)],
):
    offset = (pagination.page - 1) * pagination.per_page
    
    # Count total
    total = await db.scalar(select(func.count(Book.id)))
    
    # Fetch page
    result = await db.execute(
        select(Book)
        .offset(offset)
        .limit(pagination.per_page)
        .order_by(Book.id)
    )
    books = result.scalars().all()
    
    total_pages = (total + pagination.per_page - 1) // pagination.per_page
    
    return {
        "data": [BookSchema.model_validate(b) for b in books],
        "pagination": {
            "page": pagination.page,
            "per_page": pagination.per_page,
            "total_items": total,
            "total_pages": total_pages,
            "has_next": pagination.page < total_pages,
            "has_prev": pagination.page > 1,
        },
    }
# Pros: Simple, supports jumping to any page
# Cons: Slow for large offsets, inconsistent with concurrent inserts/deletes


# --- Cursor-based Pagination (Keyset) ---
from base64 import b64encode, b64decode
import json

def encode_cursor(data: dict) -> str:
    return b64encode(json.dumps(data).encode()).decode()

def decode_cursor(cursor: str) -> dict:
    return json.loads(b64decode(cursor.encode()).decode())

@app.get("/api/v1/books/stream")
async def list_books_cursor(
    cursor: Optional[str] = None,
    limit: int = Query(default=20, ge=1, le=100),
    db: Annotated[AsyncSession, Depends(get_db)],
):
    query = select(Book).order_by(Book.created_at.desc(), Book.id.desc())
    
    if cursor:
        cursor_data = decode_cursor(cursor)
        # Keyset condition: get rows AFTER the cursor position
        query = query.where(
            (Book.created_at < cursor_data["created_at"]) |
            (
                (Book.created_at == cursor_data["created_at"]) &
                (Book.id < cursor_data["id"])
            )
        )
    
    # Fetch one extra to determine if there's a next page
    result = await db.execute(query.limit(limit + 1))
    books = result.scalars().all()
    
    has_next = len(books) > limit
    if has_next:
        books = books[:limit]
    
    next_cursor = None
    if has_next and books:
        last = books[-1]
        next_cursor = encode_cursor({
            "created_at": last.created_at.isoformat(),
            "id": last.id,
        })
    
    return {
        "data": [BookSchema.model_validate(b) for b in books],
        "pagination": {
            "next_cursor": next_cursor,
            "has_next": has_next,
            "limit": limit,
        },
    }
# Pros: Consistent results, fast for any "page", works well at scale
# Cons: No page numbers, can only go forward/backward


# ============================================================
# ADVANCED FILTERING
# ============================================================

@app.get("/api/v1/books")
async def list_books_filtered(
    # Simple filters
    title: Optional[str] = Query(None, description="Filter by title (partial)"),
    author_id: Optional[int] = Query(None, description="Filter by author"),
    status: Optional[BookStatus] = Query(None, description="Filter by status"),
    
    # Range filters
    min_price: Optional[float] = Query(None, ge=0),
    max_price: Optional[float] = Query(None, ge=0),
    published_after: Optional[date] = Query(None),
    published_before: Optional[date] = Query(None),
    
    # Multi-value filters
    tags: Optional[list[str]] = Query(None, description="Filter by tags"),
    
    # Search
    search: Optional[str] = Query(None, min_length=2, description="Full-text search"),
    
    # Sorting
    sort_by: str = Query("created_at", regex="^(title|price|created_at|rating)$"),
    sort_order: str = Query("desc", regex="^(asc|desc)$"),
    
    # Pagination
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=100),
    
    db: Annotated[AsyncSession, Depends(get_db)],
):
    query = select(Book)
    
    # Apply filters dynamically
    if title:
        query = query.where(Book.title.ilike(f"%{title}%"))
    if author_id:
        query = query.where(Book.author_id == author_id)
    if status:
        query = query.where(Book.status == status.value)
    if min_price is not None:
        query = query.where(Book.price >= min_price)
    if max_price is not None:
        query = query.where(Book.price <= max_price)
    if published_after:
        query = query.where(Book.published >= published_after)
    if published_before:
        query = query.where(Book.published <= published_before)
    if tags:
        query = query.join(Book.tags).where(Tag.name.in_(tags))
    if search:
        # PostgreSQL full-text search
        query = query.where(
            Book.title.ilike(f"%{search}%") |
            Book.description.ilike(f"%{search}%")
        )
    
    # Sorting
    sort_column = getattr(Book, sort_by)
    if sort_order == "desc":
        sort_column = sort_column.desc()
    query = query.order_by(sort_column)
    
    # Count
    count_query = select(func.count()).select_from(query.subquery())
    total = await db.scalar(count_query)
    
    # Paginate
    offset = (page - 1) * per_page
    result = await db.execute(query.offset(offset).limit(per_page))
    books = result.scalars().all()
    
    return {
        "data": [BookSchema.model_validate(b) for b in books],
        "filters_applied": {
            k: v for k, v in {
                "title": title, "author_id": author_id,
                "status": status, "min_price": min_price,
                "max_price": max_price, "tags": tags, "search": search,
            }.items() if v is not None
        },
        "pagination": {
            "page": page,
            "per_page": per_page,
            "total": total,
            "pages": (total + per_page - 1) // per_page,
        },
    }
```

### 4.3 API Rate Limiting

```python
# ============================================================
# API RATE LIMITING — PRODUCTION IMPLEMENTATION
# ============================================================

import time
import hashlib
from fastapi import FastAPI, Request, HTTPException, Depends
from typing import Annotated
import aioredis


# --- Token Bucket Algorithm ---
class TokenBucketRateLimiter:
    """
    Token Bucket Algorithm:
    - Bucket holds N tokens
    - Each request consumes 1 token
    - Tokens are refilled at a fixed rate
    - If bucket is empty, request is rejected
    """
    
    def __init__(self, redis_url: str = "redis://localhost"):
        self.redis = None
        self.redis_url = redis_url
    
    async def init(self):
        self.redis = await aioredis.from_url(self.redis_url)
    
    async def is_allowed(
        self,
        key: str,
        max_tokens: int = 60,
        refill_rate: float = 1.0,  # tokens per second
    ) -> tuple[bool, dict]:
        """
        Check if request is allowed under rate limit.
        
        Returns: (allowed: bool, info: dict)
        """
        now = time.time()
        pipe = self.redis.pipeline()
        
        # Lua script for atomic token bucket operation
        lua_script = """
        local key = KEYS[1]
        local max_tokens = tonumber(ARGV[1])
        local refill_rate = tonumber(ARGV[2])
        local now = tonumber(ARGV[3])
        
        -- Get current state
        local bucket = redis.call('hmget', key, 'tokens', 'last_refill')
        local tokens = tonumber(bucket[1]) or max_tokens
        local last_refill = tonumber(bucket[2]) or now
        
        -- Calculate refill
        local elapsed = now - last_refill
        local new_tokens = math.min(max_tokens, tokens + elapsed * refill_rate)
        
        local allowed = 0
        if new_tokens >= 1 then
            new_tokens = new_tokens - 1
            allowed = 1
        end
        
        -- Update state
        redis.call('hmset', key, 'tokens', new_tokens, 'last_refill', now)
        redis.call('expire', key, math.ceil(max_tokens / refill_rate) + 1)
        
        return {allowed, tostring(new_tokens), tostring(max_tokens)}
        """
        
        result = await self.redis.eval(
            lua_script, 1, key,
            str(max_tokens), str(refill_rate), str(now)
        )
        
        allowed = bool(result[0])
        remaining = float(result[1])
        limit = int(result[2])
        
        retry_after = None
        if not allowed:
            retry_after = max(1, int((1 - remaining) / refill_rate))
        
        return allowed, {
            "limit": limit,
            "remaining": max(0, int(remaining)),
            "retry_after": retry_after,
            "reset": int(now + (limit - remaining) / refill_rate),
        }


# --- Sliding Window Rate Limiter ---
class SlidingWindowRateLimiter:
    """
    Sliding Window Algorithm:
    - More accurate than fixed window
    - Prevents burst at window boundaries
    """
    
    def __init__(self, redis):
        self.redis = redis
    
    async def is_allowed(
        self,
        key: str,
        max_requests: int = 100,
        window_seconds: int = 60,
    ) -> tuple[bool, dict]:
        now = time.time()
        window_start = now - window_seconds
        
        pipe = self.redis.pipeline()
        
        # Remove expired entries
        pipe.zremrangebyscore(key, 0, window_start)
        # Count requests in window
        pipe.zcard(key)
        # Add current request (score = timestamp)
        pipe.zadd(key, {str(now): now})
        # Set expiry
        pipe.expire(key, window_seconds)
        
        results = await pipe.execute()
        request_count = results[1]
        
        allowed = request_count < max_requests
        
        if not allowed:
            # Remove the request we just added
            await self.redis.zrem(key, str(now))
        
        return allowed, {
            "limit": max_requests,
            "remaining": max(0, max_requests - request_count - (1 if allowed else 0)),
            "window": window_seconds,
            "reset": int(now + window_seconds),
        }


# --- FastAPI Rate Limit Dependency ---
rate_limiter = TokenBucketRateLimiter()

@app.on_event("startup")
async def startup():
    await rate_limiter.init()

class RateLimit:
    """Configurable rate limit dependency."""
    
    def __init__(
        self,
        max_requests: int = 60,
        window_seconds: int = 60,
        key_func=None,
    ):
        self.max_requests = max_requests
        self.window_seconds = window_seconds
        self.key_func = key_func or self._default_key
    
    def _default_key(self, request: Request) -> str:
        """Rate limit by IP address."""
        client_ip = request.client.host
        return f"rate_limit:{client_ip}:{request.url.path}"
    
    async def __call__(self, request: Request):
        key = self.key_func(request)
        
        refill_rate = self.max_requests / self.window_seconds
        allowed, info = await rate_limiter.is_allowed(
            key,
            max_tokens=self.max_requests,
            refill_rate=refill_rate,
        )
        
        # Store info for response headers
        request.state.rate_limit_info = info
        
        if not allowed:
            raise HTTPException(
                status_code=429,
                detail={
                    "error": "Rate limit exceeded",
                    "retry_after": info["retry_after"],
                },
                headers={
                    "Retry-After": str(info["retry_after"]),
                    "X-RateLimit-Limit": str(info["limit"]),
                    "X-RateLimit-Remaining": "0",
                },
            )

# Rate limit by API key
def api_key_rate_limit_key(request: Request) -> str:
    api_key = request.headers.get("X-API-Key", request.client.host)
    return f"rate_limit:api:{api_key}"

# Usage
@app.get(
    "/api/v1/books",
    dependencies=[Depends(RateLimit(max_requests=100, window_seconds=60))],
)
async def list_books():
    return {"books": []}

@app.post(
    "/api/v1/books",
    dependencies=[Depends(RateLimit(
        max_requests=10,
        window_seconds=60,
        key_func=api_key_rate_limit_key,
    ))],
)
async def create_book():
    return {"book": {}}


# --- Add rate limit headers to all responses ---
@app.middleware("http")
async def add_rate_limit_headers(request: Request, call_next):
    response = await call_next(request)
    
    if hasattr(request.state, "rate_limit_info"):
        info = request.state.rate_limit_info
        response.headers["X-RateLimit-Limit"] = str(info["limit"])
        response.headers["X-RateLimit-Remaining"] = str(info["remaining"])
        response.headers["X-RateLimit-Reset"] = str(info["reset"])
    
    return response
```

### 4.4 API Security (OAuth2, JWT, Token Lifecycle)

```python
# ============================================================
# COMPLETE AUTH SYSTEM — OAuth2 + JWT
# ============================================================

from datetime import datetime, timedelta, timezone
from typing import Optional, Annotated
from fastapi import FastAPI, Depends, HTTPException, status, Request
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from pydantic import BaseModel, EmailStr
from passlib.context import CryptContext
import jwt
import uuid
import secrets


# --- Configuration ---
class AuthConfig:
    SECRET_KEY = "your-256-bit-secret-key-here"
    ALGORITHM = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES = 15        # Short-lived
    REFRESH_TOKEN_EXPIRE_DAYS = 30          # Long-lived
    PASSWORD_RESET_TOKEN_EXPIRE_HOURS = 1
    MAX_LOGIN_ATTEMPTS = 5
    LOCKOUT_DURATION_MINUTES = 30


# --- Password Hashing ---
pwd_context = CryptContext(
    schemes=["bcrypt"],
    deprecated="auto",
    bcrypt__rounds=12,
)

def hash_password(password: str) -> str:
    return pwd_context.hash(password)

def verify_password(plain: str, hashed: str) -> bool:
    return pwd_context.verify(plain, hashed)


# --- JWT Token Management ---
class TokenPayload(BaseModel):
    sub: str                    # Subject (user ID)
    exp: datetime               # Expiration
    iat: datetime               # Issued at
    jti: str                    # JWT ID (for revocation)
    type: str                   # "access" or "refresh"
    roles: list[str] = []
    scopes: list[str] = []

class TokenPair(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    expires_in: int             # Seconds until access token expires


class TokenService:
    """Manages JWT token creation, validation, and revocation."""
    
    def __init__(self, redis_client):
        self.redis = redis_client
        self.config = AuthConfig()
    
    def create_access_token(
        self,
        user_id: int,
        roles: list[str] = None,
        scopes: list[str] = None,
    ) -> str:
        now = datetime.now(timezone.utc)
        expires = now + timedelta(minutes=self.config.ACCESS_TOKEN_EXPIRE_MINUTES)
        
        payload = {
            "sub": str(user_id),
            "exp": expires,
            "iat": now,
            "jti": str(uuid.uuid4()),
            "type": "access",
            "roles": roles or [],
            "scopes": scopes or [],
        }
        
        return jwt.encode(payload, self.config.SECRET_KEY, algorithm=self.config.ALGORITHM)
    
    def create_refresh_token(self, user_id: int) -> str:
        now = datetime.now(timezone.utc)
        expires = now + timedelta(days=self.config.REFRESH_TOKEN_EXPIRE_DAYS)
        
        payload = {
            "sub": str(user_id),
            "exp": expires,
            "iat": now,
            "jti": str(uuid.uuid4()),
            "type": "refresh",
        }
        
        token = jwt.encode(payload, self.config.SECRET_KEY, algorithm=self.config.ALGORITHM)
        
        # Store refresh token in Redis for revocation tracking
        # Use jti as key, store until expiry
        self.redis.setex(
            f"refresh_token:{payload['jti']}",
            int(self.config.REFRESH_TOKEN_EXPIRE_DAYS * 86400),
            str(user_id),
        )
        
        return token
    
    def create_token_pair(
        self,
        user_id: int,
        roles: list[str] = None,
        scopes: list[str] = None,
    ) -> TokenPair:
        return TokenPair(
            access_token=self.create_access_token(user_id, roles, scopes),
            refresh_token=self.create_refresh_token(user_id),
            expires_in=self.config.ACCESS_TOKEN_EXPIRE_MINUTES * 60,
        )
    
    def decode_token(self, token: str) -> dict:
        try:
            payload = jwt.decode(
                token,
                self.config.SECRET_KEY,
                algorithms=[self.config.ALGORITHM],
            )
            return payload
        except jwt.ExpiredSignatureError:
            raise HTTPException(status_code=401, detail="Token has expired")
        except jwt.InvalidTokenError:
            raise HTTPException(status_code=401, detail="Invalid token")
    
    async def revoke_token(self, jti: str, expires_in: int):
        """Add token to blacklist."""
        await self.redis.setex(f"blacklisted:{jti}", expires_in, "1")
    
    async def is_revoked(self, jti: str) -> bool:
        """Check if token has been revoked."""
        return await self.redis.exists(f"blacklisted:{jti}")
    
    async def revoke_all_user_tokens(self, user_id: int):
        """Revoke all refresh tokens for a user."""
        # Find and delete all refresh tokens for this user
        pattern = f"refresh_token:*"
        async for key in self.redis.scan_iter(pattern):
            stored_user_id = await self.redis.get(key)
            if stored_user_id and int(stored_user_id) == user_id:
                await self.redis.delete(key)
                jti = key.split(":")[-1]
                await self.redis.setex(f"blacklisted:{jti}", 86400 * 30, "1")
    
    async def refresh_access_token(self, refresh_token: str) -> TokenPair:
        """Use refresh token to get new token pair."""
        payload = self.decode_token(refresh_token)
        
        if payload.get("type") != "refresh":
            raise HTTPException(status_code=401, detail="Invalid token type")
        
        jti = payload["jti"]
        
        # Check if refresh token is still valid in Redis
        stored = await self.redis.get(f"refresh_token:{jti}")
        if not stored:
            raise HTTPException(status_code=401, detail="Refresh token revoked")
        
        # Check blacklist
        if await self.is_revoked(jti):
            raise HTTPException(status_code=401, detail="Token has been revoked")
        
        # Rotate refresh token (invalidate old, create new)
        await self.redis.delete(f"refresh_token:{jti}")
        
        user_id = int(payload["sub"])
        # Fetch fresh user data for roles
        user = await get_user_by_id(user_id)
        
        return self.create_token_pair(
            user_id=user_id,
            roles=user.roles,
        )


# --- Auth Endpoints ---
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/token")

@app.post("/auth/register")
async def register(
    email: EmailStr,
    password: str,
    name: str,
    db: Annotated[AsyncSession, Depends(get_db)],
):
    # Check if user exists
    existing = await db.execute(select(User).where(User.email == email))
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=409, detail="Email already registered")
    
    user = User(
        email=email,
        password_hash=hash_password(password),
        name=name,
    )
    db.add(user)
    await db.commit()
    
    return {"message": "User registered successfully", "user_id": user.id}


@app.post("/auth/token", response_model=TokenPair)
async def login(
    form_data: Annotated[OAuth2PasswordRequestForm, Depends()],
    request: Request,
    db: Annotated[AsyncSession, Depends(get_db)],
    token_service: Annotated[TokenService, Depends(get_token_service)],
):
    """OAuth2 password flow — returns access + refresh tokens."""
    
    # Rate limiting on login attempts
    ip = request.client.host
    attempts_key = f"login_attempts:{ip}:{form_data.username}"
    attempts = await token_service.redis.get(attempts_key)
    
    if attempts and int(attempts) >= AuthConfig.MAX_LOGIN_ATTEMPTS:
        raise HTTPException(
            status_code=429,
            detail=f"Too many login attempts. Try again in "
                   f"{AuthConfig.LOCKOUT_DURATION_MINUTES} minutes.",
        )
    
    # Authenticate
    result = await db.execute(
        select(User).where(User.email == form_data.username)
    )
    user = result.scalar_one_or_none()
    
    if not user or not verify_password(form_data.password, user.password_hash):
        # Increment failed attempts
        pipe = token_service.redis.pipeline()
        pipe.incr(attempts_key)
        pipe.expire(attempts_key, AuthConfig.LOCKOUT_DURATION_MINUTES * 60)
        await pipe.execute()
        
        raise HTTPException(status_code=401, detail="Invalid credentials")
    
    if not user.is_active:
        raise HTTPException(status_code=403, detail="Account is deactivated")
    
    # Clear failed attempts on success
    await token_service.redis.delete(attempts_key)
    
    # Update last login
    user.last_login = datetime.now(timezone.utc)
    await db.commit()
    
    return token_service.create_token_pair(
        user_id=user.id,
        roles=[user.role],
        scopes=form_data.scopes,
    )


@app.post("/auth/refresh", response_model=TokenPair)
async def refresh_token(
    refresh_token: str,
    token_service: Annotated[TokenService, Depends(get_token_service)],
):
    """Exchange refresh token for new token pair."""
    return await token_service.refresh_access_token(refresh_token)


@app.post("/auth/logout")
async def logout(
    token: Annotated[str, Depends(oauth2_scheme)],
    token_service: Annotated[TokenService, Depends(get_token_service)],
):
    """Revoke the current access token."""
    payload = token_service.decode_token(token)
    jti = payload["jti"]
    exp = payload["exp"]
    
    # Calculate remaining TTL
    now = datetime.now(timezone.utc).timestamp()
    ttl = int(exp - now)
    
    if ttl > 0:
        await token_service.revoke_token(jti, ttl)
    
    return {"message": "Successfully logged out"}


@app.post("/auth/logout-all")
async def logout_all_devices(
    user: Annotated[dict, Depends(get_current_user)],
    token_service: Annotated[TokenService, Depends(get_token_service)],
):
    """Revoke all tokens for the current user."""
    await token_service.revoke_all_user_tokens(user.id)
    return {"message": "Logged out from all devices"}


# --- Protected Endpoint Dependency ---
async def get_current_user(
    token: Annotated[str, Depends(oauth2_scheme)],
    token_service: Annotated[TokenService, Depends(get_token_service)],
    db: Annotated[AsyncSession, Depends(get_db)],
):
    payload = token_service.decode_token(token)
    
    # Verify token type
    if payload.get("type") != "access":
        raise HTTPException(status_code=401, detail="Invalid token type")
    
    # Check blacklist
    if await token_service.is_revoked(payload["jti"]):
        raise HTTPException(status_code=401, detail="Token has been revoked")
    
    # Get user
    user = await db.get(User, int(payload["sub"]))
    if not user:
        raise HTTPException(status_code=401, detail="User not found")
    
    # Attach token info to user for use in endpoints
    user.token_scopes = payload.get("scopes", [])
    user.token_roles = payload.get("roles", [])
    
    return user
```

### 4.5 API Gateway Pattern

```python
# ============================================================
# API GATEWAY — REQUEST ROUTING & AGGREGATION
# ============================================================
# In production, use Kong, AWS API Gateway, or Traefik.
# Below shows the concepts for understanding.

from fastapi import FastAPI, Request, HTTPException
import httpx
from typing import Optional
import asyncio

app = FastAPI(title="API Gateway")

# Service registry
SERVICES = {
    "books": "http://books-service:8001",
    "authors": "http://authors-service:8002",
    "orders": "http://orders-service:8003",
    "users": "http://users-service:8004",
}


# --- Service Proxy ---
@app.api_route(
    "/api/{service}/{path:path}",
    methods=["GET", "POST", "PUT", "PATCH", "DELETE"],
)
async def proxy(service: str, path: str, request: Request):
    """Route requests to appropriate microservice."""
    
    if service not in SERVICES:
        raise HTTPException(status_code=404, detail=f"Service '{service}' not found")
    
    target_url = f"{SERVICES[service]}/{path}"
    
    # Forward headers (excluding hop-by-hop headers)
    headers = dict(request.headers)
    headers.pop("host", None)
    
    async with httpx.AsyncClient(timeout=30) as client:
        response = await client.request(
            method=request.method,
            url=target_url,
            headers=headers,
            params=dict(request.query_params),
            content=await request.body(),
        )
    
    return Response(
        content=response.content,
        status_code=response.status_code,
        headers=dict(response.headers),
    )


# --- Aggregation Endpoint ---
@app.get("/api/dashboard")
async def dashboard(request: Request):
    """Aggregate data from multiple services."""
    async with httpx.AsyncClient(timeout=15) as client:
        token = request.headers.get("Authorization", "")
        headers = {"Authorization": token}
        
        results = await asyncio.gather(
            client.get(f"{SERVICES['books']}/stats", headers=headers),
            client.get(f"{SERVICES['orders']}/stats", headers=headers),
            client.get(f"{SERVICES['users']}/stats", headers=headers),
            return_exceptions=True,
        )
    
    return {
        "books": results[0].json() if not isinstance(results[0], Exception) else None,
        "orders": results[1].json() if not isinstance(results[1], Exception) else None,
        "users": results[2].json() if not isinstance(results[2], Exception) else None,
    }
```

### 4.6 OpenAPI / Swagger Documentation

```python
# ============================================================
# OPENAPI DOCUMENTATION — FASTAPI
# ============================================================

from fastapi import FastAPI, Query, Path, Body, Header
from fastapi.openapi.utils import get_openapi
from pydantic import BaseModel, Field
from typing import Annotated

app = FastAPI(
    title="Bookstore API",
    description="""
    ## Bookstore API
    
    A comprehensive API for managing books, authors, and orders.
    
    ### Features
    * **Books** — CRUD operations for books
    * **Authors** — Manage book authors
    * **Orders** — Place and track orders
    * **Authentication** — JWT-based auth with OAuth2
    
    ### Rate Limiting
    - Public endpoints: 100 requests/minute
    - Authenticated endpoints: 1000 requests/minute
    - Write endpoints: 50 requests/minute
    """,
    version="2.1.0",
    terms_of_service="https://example.com/terms",
    contact={
        "name": "API Support",
        "url": "https://example.com/support",
        "email": "api@example.com",
    },
    license_info={
        "name": "MIT",
        "url": "https://opensource.org/licenses/MIT",
    },
    servers=[
        {"url": "https://api.example.com", "description": "Production"},
        {"url": "https://staging-api.example.com", "description": "Staging"},
        {"url": "http://localhost:8000", "description": "Development"},
    ],
)


# --- Well-Documented Endpoint ---
class BookCreate(BaseModel):
    """Schema for creating a new book."""
    
    title: str = Field(
        min_length=1,
        max_length=300,
        description="The title of the book",
        examples=["The Hobbit"],
    )
    isbn: str = Field(
        pattern=r"^\d{3}-\d-\d{3}-\d{5}-\d$",
        description="ISBN-13 format with dashes",
        examples=["978-0-261-10295-1"],
    )
    price: float = Field(
        ge=0,
        le=99999.99,
        description="Price in USD",
        examples=[12.99],
    )
    author_id: int = Field(
        gt=0,
        description="ID of the book's author",
        examples=[42],
    )

    model_config = {
        "json_schema_extra": {
            "examples": [
                {
                    "title": "The Hobbit",
                    "isbn": "978-0-261-10295-1",
                    "price": 12.99,
                    "author_id": 42,
                },
                {
                    "title": "Dune",
                    "isbn": "978-0-441-17271-9",
                    "price": 9.99,
                    "author_id": 15,
                },
            ]
        }
    }


class ErrorResponse(BaseModel):
    error: str = Field(description="Error type")
    message: str = Field(description="Human-readable error message")
    details: dict = Field(default_factory=dict, description="Additional error details")


@app.post(
    "/api/v1/books",
    response_model=BookResponse,
    status_code=201,
    summary="Create a new book",
    description="Creates a new book in the catalog. Requires admin or editor role.",
    response_description="The newly created book",
    tags=["Books"],
    responses={
        201: {
            "description": "Book created successfully",
            "content": {
                "application/json": {
                    "example": {
                        "id": 1,
                        "title": "The Hobbit",
                        "price": 12.99,
                        "status": "draft",
                    }
                }
            },
        },
        401: {
            "model": ErrorResponse,
            "description": "Authentication required",
        },
        403: {
            "model": ErrorResponse,
            "description": "Insufficient permissions",
        },
        409: {
            "model": ErrorResponse,
            "description": "Book with this ISBN already exists",
        },
        422: {
            "model": ErrorResponse,
            "description": "Validation error",
        },
        429: {
            "model": ErrorResponse,
            "description": "Rate limit exceeded",
        },
    },
)
async def create_book(
    book: Annotated[BookCreate, Body(
        openapi_examples={
            "fiction": {
                "summary": "A fiction book",
                "description": "Example of creating a fiction book",
                "value": {
                    "title": "The Hobbit",
                    "isbn": "978-0-261-10295-1",
                    "price": 12.99,
                    "author_id": 42,
                },
            },
            "technical": {
                "summary": "A technical book",
                "value": {
                    "title": "Designing Data-Intensive Applications",
                    "isbn": "978-1-449-37332-0",
                    "price": 44.99,
                    "author_id": 88,
                },
            },
        },
    )],
    authorization: Annotated[str, Header(description="Bearer JWT token")],
):
    """
    Create a new book in the catalog.
    
    **Required roles:** `admin`, `editor`
    
    **Business rules:**
    - ISBN must be unique
    - Author must exist
    - Price cannot be negative
    - Title is automatically title-cased
    
    **Rate limit:** 50 requests per minute
    """
    pass


# --- Custom OpenAPI Schema ---
def custom_openapi():
    if app.openapi_schema:
        return app.openapi_schema
    
    openapi_schema = get_openapi(
        title=app.title,
        version=app.version,
        description=app.description,
        routes=app.routes,
    )
    
    # Add security scheme
    openapi_schema["components"]["securitySchemes"] = {
        "bearerAuth": {
            "type": "http",
            "scheme": "bearer",
            "bearerFormat": "JWT",
            "description": "Enter your JWT token",
        },
        "apiKeyAuth": {
            "type": "apiKey",
            "in": "header",
            "name": "X-API-Key",
            "description": "API key for service-to-service auth",
        },
    }
    
    # Apply security globally
    openapi_schema["security"] = [{"bearerAuth": []}]
    
    app.openapi_schema = openapi_schema
    return app.openapi_schema

app.openapi = custom_openapi

# --- Access documentation at ---
# Swagger UI:   http://localhost:8000/docs
# ReDoc:        http://localhost:8000/redoc
# OpenAPI JSON: http://localhost:8000/openapi.json
```

---

## QUICK REFERENCE MATRIX

```
┌────────────────────┬─────────────┬─────────────┬─────────────┐
│     Feature        │   Django    │   FastAPI   │    Flask    │
├────────────────────┼─────────────┼─────────────┼─────────────┤
│ ORM               │ Built-in    │ SQLAlchemy  │ SQLAlchemy  │
│ Validation         │ Forms/DRF   │ Pydantic    │ Marshmallow │
│ Async Support      │ Partial 4.1+│ Native      │ Limited     │
│ Auto Docs          │ DRF/drf-spec│ Built-in    │ Flask-RESTX │
│ DI System          │ None        │ Built-in    │ None        │
│ Auth               │ Built-in    │ Manual/Deps │ Extensions  │
│ Admin Panel        │ Built-in    │ None        │ Flask-Admin │
│ Middleware         │ Class-based │ ASGI/Starlette│ WSGI/hooks│
│ Performance        │ Moderate    │ High        │ Moderate    │
│ Learning Curve     │ Steep       │ Moderate    │ Low         │
│ Best For           │ Full apps   │ APIs/Micro  │ Small-Med   │
└────────────────────┴─────────────┴─────────────┴─────────────┘
```