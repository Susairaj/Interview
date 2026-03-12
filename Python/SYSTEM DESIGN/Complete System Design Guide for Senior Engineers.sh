Complete System Design Guide for Senior Engineers & Tech Leads

---

## PART 1: HIGH LEVEL DESIGN

---

## Scalability

Scalability is the system's ability to handle growing amounts of work by adding resources.

### Vertical Scaling (Scale Up)
```
Before:                    After:
┌──────────┐              ┌──────────────┐
│  Server  │              │    Server     │
│  4 CPU   │  ────────►   │   32 CPU     │
│  8GB RAM │              │   128GB RAM  │
│  256GB   │              │   2TB SSD    │
└──────────┘              └──────────────┘
```

### Horizontal Scaling (Scale Out)
```
Before:                    After:
┌──────────┐              ┌──────────┐ ┌──────────┐ ┌──────────┐
│  Server  │              │ Server 1 │ │ Server 2 │ │ Server 3 │
│  4 CPU   │  ────────►   │  4 CPU   │ │  4 CPU   │ │  4 CPU   │
│  8GB RAM │              │  8GB RAM │ │  8GB RAM │ │  8GB RAM │
└──────────┘              └──────────┘ └──────────┘ └──────────┘
                                    ▲
                          ┌─────────┴─────────┐
                          │   Load Balancer    │
                          └────────────────────┘
```

### Real-World Example: E-Commerce During Black Friday

```python
# Problem: Traffic spikes from 1,000 to 100,000 requests/second

# WITHOUT Scalability
class MonolithicStore:
    """Single server handles everything - crashes under load"""
    def handle_request(self, request):
        # All on one machine
        product = self.query_database(request.product_id)    # DB bottleneck
        inventory = self.check_inventory(product)             # Memory bottleneck
        payment = self.process_payment(request.payment_info)  # CPU bottleneck
        return self.generate_response(product, inventory, payment)

# WITH Horizontal Scalability
class ScalableStore:
    """
    Each concern scales independently based on load.
    """
    def __init__(self):
        # Each service can have N instances behind a load balancer
        self.product_service = ServicePool("products", min_instances=3, max_instances=50)
        self.inventory_service = ServicePool("inventory", min_instances=3, max_instances=20)
        self.payment_service = ServicePool("payments", min_instances=5, max_instances=100)
    
    def handle_request(self, request):
        # Requests distributed across multiple instances
        product = self.product_service.call(request.product_id)
        inventory = self.inventory_service.call(product.id)
        payment = self.payment_service.call(request.payment_info)
        return Response(product, inventory, payment)


# Auto-scaling configuration example (AWS-style)
auto_scaling_config = {
    "service": "payment-service",
    "min_instances": 5,
    "max_instances": 100,
    "scale_up_rules": [
        {"metric": "cpu_utilization", "threshold": 70, "action": "add_2_instances"},
        {"metric": "request_latency_p99", "threshold": "500ms", "action": "add_5_instances"},
        {"metric": "queue_depth", "threshold": 1000, "action": "add_3_instances"}
    ],
    "scale_down_rules": [
        {"metric": "cpu_utilization", "threshold": 20, "cooldown": "10min", 
         "action": "remove_1_instance"}
    ]
}
```

### Key Scaling Strategies

```
┌─────────────────────────────────────────────────────────┐
│                   SCALING STRATEGIES                     │
├──────────────┬──────────────────────────────────────────┤
│ Database     │ Read Replicas, Sharding, Partitioning    │
│ Caching      │ Redis/Memcached layers                   │
│ CDN          │ Static content at edge locations          │
│ Async        │ Queue-based processing                   │
│ Stateless    │ No server-side sessions                  │
│ Partitioning │ Data/workload split across nodes         │
└──────────────┴──────────────────────────────────────────┘
```

---

## Availability

Availability measures the percentage of time a system remains operational.

```
Availability Table (The "Nines"):
┌───────────────┬──────────────────┬────────────────────┐
│ Availability  │ Downtime/Year    │ Downtime/Month     │
├───────────────┼──────────────────┼────────────────────┤
│ 99%           │ 3.65 days        │ 7.31 hours         │
│ 99.9%         │ 8.76 hours       │ 43.83 minutes      │
│ 99.99%        │ 52.56 minutes    │ 4.38 minutes       │
│ 99.999%       │ 5.26 minutes     │ 26.3 seconds       │
│ 99.9999%      │ 31.56 seconds    │ 2.63 seconds       │
└───────────────┴──────────────────┴────────────────────┘
```

### Achieving High Availability

```
                    ┌─────────────────┐
                    │   DNS (Route53)  │
                    │  Health Checks   │
                    └────────┬────────┘
                             │
              ┌──────────────┴──────────────┐
              ▼                              ▼
     ┌─────────────────┐           ┌─────────────────┐
     │  Region: US-East │           │ Region: EU-West  │
     └────────┬────────┘           └────────┬────────┘
              │                              │
     ┌────────┴────────┐           ┌────────┴────────┐
     ▼                  ▼           ▼                  ▼
┌─────────┐      ┌─────────┐ ┌─────────┐      ┌─────────┐
│   AZ-1  │      │   AZ-2  │ │   AZ-1  │      │   AZ-2  │
│         │      │         │ │         │      │         │
│ ┌─────┐ │      │ ┌─────┐ │ │ ┌─────┐ │      │ ┌─────┐ │
│ │App 1│ │      │ │App 2│ │ │ │App 3│ │      │ │App 4│ │
│ │App 5│ │      │ │App 6│ │ │ │App 7│ │      │ │App 8│ │
│ └─────┘ │      │ └─────┘ │ │ └─────┘ │      │ └─────┘ │
│         │      │         │ │         │      │         │
│ ┌─────┐ │      │ ┌─────┐ │ │ ┌─────┐ │      │ ┌─────┐ │
│ │DB   │◄├──────┤►│DB   │ │ │ │DB   │◄├──────┤►│DB   │ │
│ │Prime│ │ Sync │ │Repl.│ │ │ │Repl.│ │ Sync │ │Repl.│ │
│ └─────┘ │      │ └─────┘ │ │ └─────┘ │      │ └─────┘ │
└─────────┘      └─────────┘ └─────────┘      └─────────┘
```

```python
# Health Check Implementation
class HealthChecker:
    """
    Monitors service health and triggers failover.
    """
    def __init__(self):
        self.services = {}
        self.failure_counts = {}
        self.threshold = 3  # failures before marking unhealthy
    
    def register_service(self, name: str, endpoints: list):
        self.services[name] = {
            "endpoints": endpoints,
            "active": endpoints[0],  # Primary
            "status": "healthy"
        }
        self.failure_counts[name] = 0
    
    async def check_health(self, service_name: str):
        service = self.services[service_name]
        try:
            response = await http_get(
                f"{service['active']}/health",
                timeout=5
            )
            if response.status == 200:
                self.failure_counts[service_name] = 0
                return True
        except (TimeoutError, ConnectionError):
            self.failure_counts[service_name] += 1
        
        # Trigger failover after threshold breached
        if self.failure_counts[service_name] >= self.threshold:
            await self.failover(service_name)
        return False
    
    async def failover(self, service_name: str):
        """Switch to backup endpoint"""
        service = self.services[service_name]
        current = service["active"]
        
        # Find next healthy endpoint
        for endpoint in service["endpoints"]:
            if endpoint != current:
                if await self.ping(endpoint):
                    service["active"] = endpoint
                    service["status"] = "degraded"
                    alert(f"FAILOVER: {service_name} switched "
                          f"from {current} to {endpoint}")
                    return
        
        service["status"] = "critical"
        alert(f"CRITICAL: No healthy endpoints for {service_name}")


# Redundancy Pattern - Active/Passive
class DatabaseCluster:
    def __init__(self):
        self.primary = Database("primary-host")
        self.replicas = [
            Database("replica-1"),
            Database("replica-2"),
        ]
        self.replication_lag_threshold = 100  # ms
    
    def write(self, query, params):
        """All writes go to primary"""
        result = self.primary.execute(query, params)
        # Replicas receive changes via replication stream
        return result
    
    def read(self, query, params, consistency="eventual"):
        """Reads can go to replicas for better distribution"""
        if consistency == "strong":
            return self.primary.execute(query, params)
        
        # Pick replica with least replication lag
        best_replica = min(
            self.replicas,
            key=lambda r: r.replication_lag()
        )
        
        if best_replica.replication_lag() < self.replication_lag_threshold:
            return best_replica.execute(query, params)
        
        # Fall back to primary if replicas are too far behind
        return self.primary.execute(query, params)
```

---

## Fault Tolerance

Fault tolerance is the ability to continue operating correctly when components fail.

```
┌──────────────────────────────────────────────────────────────┐
│                    FAULT TOLERANCE STRATEGIES                 │
├──────────────────┬───────────────────────────────────────────┤
│ Redundancy       │ Multiple copies of components             │
│ Replication      │ Data copied across nodes                  │
│ Checkpointing    │ Save state periodically for recovery      │
│ Retry Logic      │ Automatic retry with backoff              │
│ Graceful Degrad. │ Reduced functionality > total failure     │
│ Bulkhead         │ Isolate failures to prevent cascade       │
│ Timeout          │ Don't wait forever for failing services   │
│ Fallback         │ Default behavior when service is down     │
└──────────────────┴───────────────────────────────────────────┘
```

```python
# Comprehensive Fault Tolerance Implementation
import time
import random
from enum import Enum
from functools import wraps
from typing import Callable, Any, Optional

class FaultToleranceFramework:
    """
    Production-grade fault tolerance patterns combined.
    """
    
    # === RETRY WITH EXPONENTIAL BACKOFF ===
    @staticmethod
    def retry(
        max_attempts: int = 3,
        base_delay: float = 1.0,
        max_delay: float = 60.0,
        exponential_base: float = 2,
        retryable_exceptions: tuple = (Exception,),
        on_retry: Callable = None
    ):
        """
        Decorator that retries failed operations with exponential backoff
        and jitter to prevent thundering herd.
        
        Example: An API call that occasionally times out
        """
        def decorator(func):
            @wraps(func)
            def wrapper(*args, **kwargs):
                last_exception = None
                
                for attempt in range(1, max_attempts + 1):
                    try:
                        return func(*args, **kwargs)
                    except retryable_exceptions as e:
                        last_exception = e
                        
                        if attempt == max_attempts:
                            break
                        
                        # Exponential backoff with jitter
                        delay = min(
                            base_delay * (exponential_base ** (attempt - 1)),
                            max_delay
                        )
                        # Add jitter (±25%) to prevent thundering herd
                        jitter = delay * 0.25 * (2 * random.random() - 1)
                        actual_delay = delay + jitter
                        
                        if on_retry:
                            on_retry(attempt, actual_delay, e)
                        
                        time.sleep(actual_delay)
                
                raise last_exception
            return wrapper
        return decorator
    
    # === BULKHEAD PATTERN ===
    class Bulkhead:
        """
        Isolates failures by limiting concurrent access to a resource.
        Like watertight compartments in a ship - one flooding 
        doesn't sink the whole ship.
        
        Example: Limit database connections so one slow query 
        doesn't exhaust the connection pool for all users.
        """
        def __init__(self, name: str, max_concurrent: int, max_wait: float = 10.0):
            self.name = name
            self.semaphore = threading.Semaphore(max_concurrent)
            self.max_wait = max_wait
            self.active_count = 0
            self.rejected_count = 0
        
        def execute(self, func: Callable, *args, **kwargs):
            acquired = self.semaphore.acquire(timeout=self.max_wait)
            
            if not acquired:
                self.rejected_count += 1
                raise BulkheadFullException(
                    f"Bulkhead '{self.name}' is full. "
                    f"Active: {self.active_count}, "
                    f"Rejected: {self.rejected_count}"
                )
            
            try:
                self.active_count += 1
                return func(*args, **kwargs)
            finally:
                self.active_count -= 1
                self.semaphore.release()

    # === TIMEOUT PATTERN ===
    @staticmethod
    def with_timeout(seconds: float, fallback: Any = None):
        """
        Prevents operations from hanging forever.
        
        Example: External API call should not block the 
        entire request for more than 5 seconds.
        """
        def decorator(func):
            @wraps(func)
            def wrapper(*args, **kwargs):
                import concurrent.futures
                
                with concurrent.futures.ThreadPoolExecutor(max_workers=1) as executor:
                    future = executor.submit(func, *args, **kwargs)
                    try:
                        return future.result(timeout=seconds)
                    except concurrent.futures.TimeoutError:
                        if fallback is not None:
                            return fallback() if callable(fallback) else fallback
                        raise TimeoutError(
                            f"{func.__name__} exceeded {seconds}s timeout"
                        )
            return wrapper
        return decorator

    # === GRACEFUL DEGRADATION ===
    class GracefulDegradation:
        """
        System continues with reduced functionality rather than failing completely.
        
        Example: Netflix - if the recommendation engine is down,
        show popular/trending instead of personalized recommendations.
        """
        def __init__(self):
            self.feature_flags = {}
            self.fallback_handlers = {}
        
        def register_feature(
            self, name: str, 
            primary: Callable, 
            fallback: Callable,
            health_check: Callable
        ):
            self.feature_flags[name] = {
                "primary": primary,
                "fallback": fallback,
                "health_check": health_check,
                "is_healthy": True
            }
        
        def execute(self, feature_name: str, *args, **kwargs):
            feature = self.feature_flags[feature_name]
            
            if feature["is_healthy"]:
                try:
                    return feature["primary"](*args, **kwargs)
                except Exception as e:
                    feature["is_healthy"] = False
                    log.warning(
                        f"Feature '{feature_name}' degraded: {e}. "
                        f"Using fallback."
                    )
            
            # Use fallback - reduced but functional
            return feature["fallback"](*args, **kwargs)


# === REAL WORLD EXAMPLE: E-Commerce Product Page ===
class ProductPageService:
    def __init__(self):
        self.degradation = FaultToleranceFramework.GracefulDegradation()
        self.product_bulkhead = FaultToleranceFramework.Bulkhead(
            "product-db", max_concurrent=50
        )
        self.review_bulkhead = FaultToleranceFramework.Bulkhead(
            "review-service", max_concurrent=20
        )
        
        # Register features with fallbacks
        self.degradation.register_feature(
            "recommendations",
            primary=self._get_personalized_recommendations,
            fallback=self._get_popular_products,  # Cached/static fallback
            health_check=self._check_recommendation_engine
        )
        self.degradation.register_feature(
            "reviews",
            primary=self._get_live_reviews,
            fallback=self._get_cached_reviews,
            health_check=self._check_review_service
        )
    
    @FaultToleranceFramework.retry(
        max_attempts=3,
        base_delay=0.5,
        retryable_exceptions=(ConnectionError, TimeoutError)
    )
    @FaultToleranceFramework.with_timeout(seconds=3.0)
    def get_product(self, product_id: str) -> dict:
        """Core product data - retries and timeouts applied."""
        return self.product_bulkhead.execute(
            self.product_db.find_by_id, product_id
        )
    
    def get_product_page(self, product_id: str, user_id: str) -> dict:
        """
        Assembles the full product page.
        Each component can fail independently without taking down the page.
        """
        # Core data - must succeed
        try:
            product = self.get_product(product_id)
        except Exception:
            # Even core data has a fallback - cached version
            product = self.cache.get(f"product:{product_id}")
            if not product:
                raise  # Truly can't serve this request
        
        # Non-critical: recommendations (graceful degradation)
        recommendations = self.degradation.execute(
            "recommendations", user_id=user_id, product_id=product_id
        )
        
        # Non-critical: reviews (graceful degradation)
        reviews = self.degradation.execute(
            "reviews", product_id=product_id
        )
        
        return {
            "product": product,
            "recommendations": recommendations,  # May be personalized or popular
            "reviews": reviews,                   # May be live or cached
            "degraded_features": self._get_degraded_features()
        }
```

---

## CAP Theorem

You can only guarantee **two out of three** properties in a distributed system.

```
                        Consistency
                           /\
                          /  \
                         /    \
                        / CA   \
                       / Systems\
                      /  (RDBMS) \
                     /     ↑      \
                    /  Not possible \
                   /  with network   \
                  /   partitions      \
                 /──────────────────────\
                /           |            \
               /    CP      |     AP      \
              /   Systems   |   Systems    \
             / (MongoDB,    | (Cassandra,   \
            /   Redis,      |  DynamoDB,     \
           /    ZooKeeper)  |  CouchDB)       \
          /─────────────────|──────────────────\
     Partition                              Availability
     Tolerance

    CA = Consistency + Availability    (Sacrifices Partition Tolerance)
         → Traditional RDBMS on single node
         → NOT practical in distributed systems

    CP = Consistency + Partition Tol.  (Sacrifices Availability)
         → System may reject requests to maintain consistency
         → Bank transactions, inventory systems

    AP = Availability + Partition Tol. (Sacrifices Consistency)
         → System always responds but data may be stale
         → Social media feeds, DNS, shopping carts
```

```python
# CP System Example: Bank Transfer
class CPBankingSystem:
    """
    Prioritizes Consistency over Availability.
    If we can't guarantee the data is correct, we refuse to serve.
    """
    def transfer(self, from_account: str, to_account: str, amount: float):
        # Acquire distributed lock - blocks other operations
        lock = self.distributed_lock.acquire(
            resources=[from_account, to_account],
            timeout=30
        )
        
        if not lock:
            # UNAVAILABLE rather than risk inconsistency
            raise ServiceUnavailableError(
                "Cannot process transfer - unable to acquire locks. "
                "Please retry later."
            )
        
        try:
            # Check all replicas agree on current balance
            balances = self.read_from_all_replicas(from_account)
            if not all_equal(balances):
                raise ConsistencyError("Replicas out of sync - refusing operation")
            
            balance = balances[0]
            if balance < amount:
                raise InsufficientFundsError()
            
            # Write to majority of replicas (quorum write)
            success_count = 0
            for replica in self.replicas:
                try:
                    replica.debit(from_account, amount)
                    replica.credit(to_account, amount)
                    success_count += 1
                except ReplicaError:
                    continue
            
            # Need majority to confirm - otherwise rollback
            if success_count < (len(self.replicas) // 2 + 1):
                self.rollback_all(from_account, to_account, amount)
                raise ConsistencyError("Could not achieve quorum")
            
            return TransferResult(status="SUCCESS", amount=amount)
        finally:
            lock.release()


# AP System Example: Social Media Feed
class APSocialMediaFeed:
    """
    Prioritizes Availability over Consistency.
    Always returns something, even if slightly stale.
    """
    def get_feed(self, user_id: str):
        try:
            # Try to get the latest feed
            feed = self.closest_replica.get_feed(user_id)
            return FeedResponse(
                posts=feed,
                freshness="real-time",
                source="primary"
            )
        except ReplicaUnavailableError:
            # Fall back to any available replica
            for replica in self.replicas:
                try:
                    feed = replica.get_feed(user_id)
                    return FeedResponse(
                        posts=feed,
                        freshness="possibly-stale",
                        source=replica.id
                    )
                except ReplicaUnavailableError:
                    continue
        
        # Even if all DB replicas are down, serve from cache
        cached_feed = self.local_cache.get(f"feed:{user_id}")
        if cached_feed:
            return FeedResponse(
                posts=cached_feed,
                freshness="cached",
                source="local-cache"
            )
        
        # Last resort: return empty feed (available, but empty)
        return FeedResponse(posts=[], freshness="unavailable", source="none")
    
    def post_update(self, user_id: str, content: str):
        """
        Accept the write even if we can't propagate immediately.
        Eventual consistency - followers will see it eventually.
        """
        post = Post(user_id=user_id, content=content, timestamp=now())
        
        # Write to ANY available node
        written = False
        for replica in self.replicas:
            try:
                replica.save(post)
                written = True
                break
            except ReplicaUnavailableError:
                continue
        
        if not written:
            # Queue for later processing - still "accepted"
            self.write_ahead_log.append(post)
        
        # Background: propagate to other replicas eventually
        self.replication_queue.enqueue(post)
        
        return PostResponse(status="accepted", post_id=post.id)
```

---

## Consistency Models

```
STRONGEST ◄──────────────────────────────────────────────── WEAKEST

┌──────────────┬──────────────┬──────────────┬──────────────┬───────────┐
│   Strict/    │   Sequential │   Causal     │   Read-your- │  Eventual │
│ Linearizable │  Consistency │  Consistency │  own-writes  │Consistency│
├──────────────┼──────────────┼──────────────┼──────────────┼───────────┤
│ All ops      │ All processes│ Causally     │ User always  │ If no new │
│ appear       │ see same     │ related ops  │ sees their   │ updates,  │
│ instantan-   │ order of     │ seen in      │ own writes   │ all nodes │
│ eous and     │ operations   │ correct      │ immediately  │ converge  │
│ globally     │              │ order        │              │ eventually│
│ ordered      │              │              │              │           │
├──────────────┼──────────────┼──────────────┼──────────────┼───────────┤
│ Google       │ ZooKeeper    │ MongoDB      │ Session-     │ DynamoDB  │
│ Spanner      │              │ (default)    │ based DBs    │ Cassandra │
│              │              │              │              │ DNS       │
├──────────────┼──────────────┼──────────────┼──────────────┼───────────┤
│ Highest      │              │              │              │ Lowest    │
│ Latency      │              │              │              │ Latency   │
│ Lowest       │              │              │              │ Highest   │
│ Throughput   │              │              │              │ Throughput│
└──────────────┴──────────────┴──────────────┴──────────────┴───────────┘
```

```python
# Demonstration of different consistency models

class EventualConsistencyDemo:
    """
    Write goes to one node, propagates to others over time.
    Readers on different nodes may see different values temporarily.
    """
    def demonstrate(self):
        # T=0: User updates profile on Node A
        node_a.write("user:123", {"name": "Alice", "city": "NYC"})
        
        # T=0.001s: Node A has update, Node B doesn't yet
        node_a.read("user:123")  # → {"name": "Alice", "city": "NYC"} ✓
        node_b.read("user:123")  # → {"name": "Alice", "city": "SF"}  ✗ (stale)
        
        # T=2s: Replication completes
        node_a.read("user:123")  # → {"name": "Alice", "city": "NYC"} ✓
        node_b.read("user:123")  # → {"name": "Alice", "city": "NYC"} ✓ (converged)


class ReadYourOwnWritesDemo:
    """
    User always sees their own updates, even if others don't yet.
    """
    def demonstrate(self):
        session = Session(user_id="user:123")
        
        # User updates their profile
        session.write("profile", {"city": "NYC"})
        
        # Same user reads - guaranteed to see their update
        result = session.read("profile")
        assert result["city"] == "NYC"  # Always true
    
    # Implementation approach: sticky sessions or read-from-primary
    def read(self, key: str):
        if self.has_pending_writes(key):
            # Route to the node where we wrote
            return self.write_node.read(key)
        else:
            # Safe to read from any replica
            return self.any_replica.read(key)


class CausalConsistencyDemo:
    """
    If operation A causes operation B, everyone sees A before B.
    But unrelated operations can be seen in any order.
    """
    def demonstrate(self):
        # These are causally related (comment on a post):
        post_id = create_post("Hello World")           # Operation A
        comment_id = add_comment(post_id, "Great!")     # Operation B (caused by A)
        
        # ALL nodes guaranteed to see the post before the comment
        # No node will ever show the comment without the post
        
        # But unrelated operations have no ordering guarantee:
        # User X posts "Hello" and User Y posts "Goodbye"
        # Different nodes may show these in different orders
```

---

## PART 2: SYSTEM ARCHITECTURE

---

## Monolith vs Microservices

```
MONOLITH:
┌─────────────────────────────────────────────────┐
│                 SINGLE APPLICATION                │
│                                                   │
│  ┌───────────┐ ┌───────────┐ ┌───────────────┐  │
│  │   User     │ │  Product  │ │    Order      │  │
│  │  Module    │ │  Module   │ │   Module      │  │
│  └─────┬─────┘ └─────┬─────┘ └──────┬────────┘  │
│        │              │               │           │
│  ┌─────┴──────────────┴───────────────┴────────┐ │
│  │          SHARED DATABASE                      │ │
│  └───────────────────────────────────────────────┘│
│                                                   │
│  Single deployment unit, single process           │
│  Single codebase, shared memory                   │
└─────────────────────────────────────────────────┘

MICROSERVICES:
┌─────────┐    ┌──────────────┐    ┌────────────┐
│  User    │    │   Product    │    │   Order    │
│ Service  │    │   Service    │    │  Service   │
│          │    │              │    │            │
│ ┌──────┐ │    │ ┌──────────┐ │    │ ┌────────┐│
│ │UserDB│ │    │ │ProductDB │ │    │ │OrderDB ││
│ └──────┘ │    │ └──────────┘ │    │ └────────┘│
└────┬─────┘    └──────┬───────┘    └─────┬─────┘
     │                 │                   │
     └─────────────────┼───────────────────┘
                       │
              ┌────────┴────────┐
              │   API Gateway   │
              └─────────────────┘

Each service:
  ✓ Independently deployable
  ✓ Own database
  ✓ Own technology stack
  ✓ Own team
  ✓ Communicates via APIs/events
```

```python
# MONOLITH Example
class MonolithicECommerce:
    """
    Everything in one application.
    Simple to develop, test, and deploy initially.
    Becomes problematic as it grows.
    """
    def __init__(self):
        self.db = PostgresConnection()  # Single shared database
    
    def create_order(self, user_id: str, product_id: str, quantity: int):
        # All logic in one process, one transaction
        with self.db.transaction() as tx:
            # Check user
            user = tx.query("SELECT * FROM users WHERE id = %s", user_id)
            if not user:
                raise UserNotFoundError()
            
            # Check product and inventory
            product = tx.query("SELECT * FROM products WHERE id = %s", product_id)
            if product.stock < quantity:
                raise InsufficientStockError()
            
            # Update inventory
            tx.execute(
                "UPDATE products SET stock = stock - %s WHERE id = %s",
                quantity, product_id
            )
            
            # Create order
            order = tx.execute(
                "INSERT INTO orders (user_id, product_id, quantity, total) "
                "VALUES (%s, %s, %s, %s) RETURNING *",
                user_id, product_id, quantity, product.price * quantity
            )
            
            # Process payment
            payment_result = self._process_payment(
                user.payment_method, order.total
            )
            
            # Send notification
            self._send_email(user.email, f"Order {order.id} confirmed!")
            
            # Everything succeeds or everything rolls back
            tx.commit()
            return order
    
    # Problems at scale:
    # - One team's change can break everything
    # - Can't scale payment processing independently
    # - Stuck with one tech stack
    # - Deployment of any change requires redeploying everything
    # - Long build/test times
    # - A bug in notification can crash order processing


# MICROSERVICES Example
# === User Service ===
class UserService:
    """Owns user data and authentication."""
    def __init__(self):
        self.db = PostgresConnection("user-db")  # Own database
    
    def get_user(self, user_id: str) -> dict:
        return self.db.query("SELECT * FROM users WHERE id = %s", user_id)
    
    def validate_payment_method(self, user_id: str) -> bool:
        user = self.get_user(user_id)
        return user.payment_method is not None


# === Inventory Service ===
class InventoryService:
    """Owns product inventory. Can use different DB (e.g., Redis for speed)."""
    def __init__(self):
        self.db = Redis("inventory-db")
    
    def check_and_reserve(self, product_id: str, quantity: int) -> str:
        """Reserve inventory atomically, return reservation ID."""
        with self.db.lock(f"inv:{product_id}"):
            current = int(self.db.get(f"stock:{product_id}") or 0)
            if current < quantity:
                raise InsufficientStockError()
            
            self.db.decrby(f"stock:{product_id}", quantity)
            reservation_id = generate_id()
            self.db.setex(
                f"reservation:{reservation_id}",
                value=json.dumps({"product_id": product_id, "quantity": quantity}),
                time=600  # 10 min TTL - auto-release if not confirmed
            )
            return reservation_id
    
    def confirm_reservation(self, reservation_id: str):
        self.db.delete(f"reservation:{reservation_id}")
    
    def release_reservation(self, reservation_id: str):
        """Called if order fails - return stock."""
        data = json.loads(self.db.get(f"reservation:{reservation_id}"))
        self.db.incrby(f"stock:{data['product_id']}", data["quantity"])
        self.db.delete(f"reservation:{reservation_id}")


# === Order Service (Orchestrator) ===
class OrderService:
    """Coordinates the order flow by calling other services."""
    def __init__(self):
        self.db = PostgresConnection("order-db")
        self.user_client = HttpClient("http://user-service")
        self.inventory_client = HttpClient("http://inventory-service")
        self.payment_client = HttpClient("http://payment-service")
        self.notification_client = HttpClient("http://notification-service")
        self.event_bus = KafkaProducer()
    
    def create_order(self, user_id: str, product_id: str, quantity: int):
        # Step 1: Validate user
        user = self.user_client.get(f"/users/{user_id}")
        
        # Step 2: Reserve inventory
        reservation = self.inventory_client.post(
            "/inventory/reserve",
            {"product_id": product_id, "quantity": quantity}
        )
        
        try:
            # Step 3: Process payment
            payment = self.payment_client.post(
                "/payments",
                {"user_id": user_id, "amount": quantity * product.price}
            )
        except PaymentFailedError:
            # Compensating action: release reserved inventory
            self.inventory_client.delete(
                f"/inventory/reservations/{reservation.id}"
            )
            raise
        
        # Step 4: Create order record
        order = self.db.execute(
            "INSERT INTO orders (...) VALUES (...) RETURNING *", ...
        )
        
        # Step 5: Publish event (async - notification service listens)
        self.event_bus.publish("order.created", {
            "order_id": order.id,
            "user_id": user_id,
            "user_email": user.email
        })
        
        return order
```

### When to Use Which

```
┌─────────────────────┬──────────────────────┬──────────────────────────┐
│     FACTOR          │     MONOLITH         │     MICROSERVICES        │
├─────────────────────┼──────────────────────┼──────────────────────────┤
│ Team size           │ Small (< 10)         │ Large (multiple teams)   │
│ Project stage       │ MVP, Startup         │ Mature, Scaling          │
│ Deploy frequency    │ Weekly/monthly       │ Multiple times/day       │
│ Scaling needs       │ Uniform              │ Different per component  │
│ Domain complexity   │ Simple/Medium        │ Complex, clear boundaries│
│ Operational cost    │ Low                  │ High (K8s, monitoring)   │
│ Data consistency    │ Easy (single DB)     │ Hard (distributed txns)  │
│ Debugging           │ Easier (single proc) │ Harder (distributed)     │
│ Technology freedom  │ One stack            │ Polyglot                 │
└─────────────────────┴──────────────────────┴──────────────────────────┘

Recommended evolution:
  Monolith → Modular Monolith → Selective Extraction → Microservices
```

---

## Service Discovery

How services find each other in a dynamic environment where instances come and go.

```
CLIENT-SIDE DISCOVERY:
┌────────┐         ┌──────────────────┐
│ Service│ ──1───► │ Service Registry  │
│   A    │ ◄──2─── │ (Consul/Eureka)  │
│        │         │                   │
│        │         │ OrderService:     │
│        │         │  - 10.0.1.5:8080 │
│        │         │  - 10.0.1.6:8080 │
│        │──3───►  │  - 10.0.1.7:8080 │
│        │         └──────────────────┘
└────┬───┘
     │ 3. Direct call to chosen instance
     ▼
┌────────┐
│10.0.1.6│  (Client picks which instance)
│  :8080 │
└────────┘

SERVER-SIDE DISCOVERY:
┌────────┐         ┌──────────────┐         ┌──────────────┐
│ Service│ ──1───► │ Load Balancer │ ──2───► │ Instance 1   │
│   A    │         │ (knows all    │         │ 10.0.1.5     │
│        │         │  instances)   │         └──────────────┘
│        │         │              │         ┌──────────────┐
│        │         │              │ ──2───► │ Instance 2   │
│        │         │              │         │ 10.0.1.6     │
└────────┘         └──────┬───────┘         └──────────────┘
                          │
                   ┌──────┴───────┐
                   │   Service    │
                   │  Registry    │
                   └──────────────┘
```

```python
# Service Registry Implementation
import time
import threading
from typing import Dict, List, Optional

class ServiceRegistry:
    """
    Central registry where services register themselves
    and discover other services.
    """
    def __init__(self):
        self.services: Dict[str, List[ServiceInstance]] = {}
        self.lock = threading.RLock()
        # Start health check background thread
        self._start_health_checker()
    
    def register(self, service_name: str, host: str, port: int, 
                 metadata: dict = None):
        """
        Called by each service instance on startup.
        """
        instance = ServiceInstance(
            service_name=service_name,
            host=host,
            port=port,
            metadata=metadata or {},
            registered_at=time.time(),
            last_heartbeat=time.time()
        )
        
        with self.lock:
            if service_name not in self.services:
                self.services[service_name] = []
            self.services[service_name].append(instance)
        
        return instance.instance_id
    
    def deregister(self, service_name: str, instance_id: str):
        """Called on graceful shutdown."""
        with self.lock:
            self.services[service_name] = [
                inst for inst in self.services.get(service_name, [])
                if inst.instance_id != instance_id
            ]
    
    def heartbeat(self, service_name: str, instance_id: str):
        """Services send periodic heartbeats to prove they're alive."""
        with self.lock:
            for instance in self.services.get(service_name, []):
                if instance.instance_id == instance_id:
                    instance.last_heartbeat = time.time()
                    return True
        return False
    
    def discover(self, service_name: str) -> List[ServiceInstance]:
        """Get all healthy instances of a service."""
        with self.lock:
            instances = self.services.get(service_name, [])
            return [i for i in instances if i.is_healthy()]
    
    def _start_health_checker(self):
        """Background thread to remove dead instances."""
        def check():
            while True:
                time.sleep(10)
                with self.lock:
                    for service_name, instances in self.services.items():
                        self.services[service_name] = [
                            inst for inst in instances
                            if time.time() - inst.last_heartbeat < 30
                        ]
        
        thread = threading.Thread(target=check, daemon=True)
        thread.start()


# Client-side discovery with load balancing
class ServiceClient:
    """
    Client that discovers and load-balances across service instances.
    """
    def __init__(self, registry: ServiceRegistry):
        self.registry = registry
        self.round_robin_counters = {}
    
    def call(self, service_name: str, path: str, method: str = "GET", 
             **kwargs) -> Response:
        # 1. Discover healthy instances
        instances = self.registry.discover(service_name)
        if not instances:
            raise NoHealthyInstancesError(f"No instances for {service_name}")
        
        # 2. Load balance (round-robin)
        instance = self._select_instance(service_name, instances)
        
        # 3. Make the call with retry on failure
        try:
            url = f"http://{instance.host}:{instance.port}{path}"
            return http_request(method, url, **kwargs)
        except ConnectionError:
            # Instance might have died, try another
            instances.remove(instance)
            if instances:
                instance = instances[0]
                url = f"http://{instance.host}:{instance.port}{path}"
                return http_request(method, url, **kwargs)
            raise
    
    def _select_instance(self, service_name: str, 
                          instances: List) -> ServiceInstance:
        counter = self.round_robin_counters.get(service_name, 0)
        instance = instances[counter % len(instances)]
        self.round_robin_counters[service_name] = counter + 1
        return instance
```

---

## API Gateway

Single entry point for all client requests, handling cross-cutting concerns.

```
Without API Gateway:                 With API Gateway:

Mobile ──► User Service              Mobile ─┐
Mobile ──► Product Service                     │
Mobile ──► Order Service              Web ────┤
Web ───► User Service                          ├──► ┌─────────────┐
Web ───► Product Service              IoT ────┤    │ API Gateway  │
Web ───► Order Service                         │    │             │
IoT ───► Product Service              3rd     ─┘    │ - Auth      │
                                      Party         │ - Rate Limit│
                                                    │ - Routing   │
Client must know every service!                     │ - Logging   │
Auth duplicated everywhere!                         │ - Transform │
                                                    └──────┬──────┘
                                                           │
                                            ┌──────────────┼──────────────┐
                                            ▼              ▼              ▼
                                      ┌──────────┐  ┌──────────┐  ┌──────────┐
                                      │   User   │  │ Product  │  │  Order   │
                                      │ Service  │  │ Service  │  │ Service  │
                                      └──────────┘  └──────────┘  └──────────┘
```

```python
from fastapi import FastAPI, Request, HTTPException
from datetime import datetime, timedelta
import jwt
import asyncio
import hashlib

class APIGateway:
    def __init__(self):
        self.app = FastAPI()
        self.rate_limiter = RateLimiter()
        self.auth = AuthMiddleware()
        self.router = ServiceRouter()
        self.cache = ResponseCache()
        self.circuit_breakers = {}
        
        # Register routes
        self.app.middleware("http")(self.handle_request)
    
    async def handle_request(self, request: Request, call_next):
        """
        All requests flow through this pipeline:
        
        Client Request
            │
            ▼
        1. Rate Limiting      ← Protect backend from overload
            │
            ▼
        2. Authentication     ← Verify identity
            │
            ▼
        3. Authorization      ← Check permissions
            │
            ▼
        4. Request Transform  ← Adapt request for backend
            │
            ▼
        5. Cache Check        ← Return cached if available
            │
            ▼
        6. Route to Service   ← Forward to correct backend
            │
            ▼
        7. Response Transform ← Adapt response for client
            │
            ▼
        8. Logging/Metrics    ← Record for observability
            │
            ▼
        Client Response
        """
        start_time = datetime.now()
        
        # 1. Rate Limiting
        client_ip = request.client.host
        if not self.rate_limiter.allow(client_ip):
            raise HTTPException(429, "Rate limit exceeded")
        
        # 2. Authentication
        if not request.url.path.startswith("/public"):
            user = await self.auth.authenticate(request)
            if not user:
                raise HTTPException(401, "Unauthorized")
            request.state.user = user
        
        # 3. Authorization
        if not self.auth.authorize(request.state.user, request.url.path, 
                                    request.method):
            raise HTTPException(403, "Forbidden")
        
        # 4. Cache Check (for GET requests)
        if request.method == "GET":
            cached = self.cache.get(request.url.path, request.query_params)
            if cached:
                return cached
        
        # 5. Route to backend service
        try:
            response = await self.router.route(request)
        except ServiceUnavailableError as e:
            raise HTTPException(503, f"Service unavailable: {e}")
        
        # 6. Cache the response
        if request.method == "GET" and response.status_code == 200:
            self.cache.set(request.url.path, request.query_params, 
                          response, ttl=60)
        
        # 7. Logging
        duration = (datetime.now() - start_time).total_seconds()
        self.log_request(request, response, duration)
        
        return response


class RateLimiter:
    """
    Token Bucket algorithm for rate limiting.
    Each client gets N tokens per window. Each request costs 1 token.
    """
    def __init__(self, max_requests: int = 100, window_seconds: int = 60):
        self.max_requests = max_requests
        self.window_seconds = window_seconds
        self.buckets = {}  # In production, use Redis
    
    def allow(self, client_id: str) -> bool:
        now = datetime.now()
        
        if client_id not in self.buckets:
            self.buckets[client_id] = {
                "tokens": self.max_requests - 1,
                "last_refill": now
            }
            return True
        
        bucket = self.buckets[client_id]
        
        # Refill tokens based on elapsed time
        elapsed = (now - bucket["last_refill"]).total_seconds()
        refill = int(elapsed * (self.max_requests / self.window_seconds))
        
        if refill > 0:
            bucket["tokens"] = min(self.max_requests, bucket["tokens"] + refill)
            bucket["last_refill"] = now
        
        if bucket["tokens"] > 0:
            bucket["tokens"] -= 1
            return True
        
        return False


class ServiceRouter:
    """
    Routes requests to the appropriate backend service.
    Includes path rewriting and request aggregation.
    """
    def __init__(self):
        self.routes = {
            "/api/users": {"service": "user-service", "path": "/users"},
            "/api/products": {"service": "product-service", "path": "/products"},
            "/api/orders": {"service": "order-service", "path": "/orders"},
        }
    
    async def route(self, request: Request):
        # Find matching route
        for pattern, config in self.routes.items():
            if request.url.path.startswith(pattern):
                service = config["service"]
                # Rewrite path: /api/users/123 → /users/123
                new_path = request.url.path.replace(pattern, config["path"])
                
                return await self.forward(service, new_path, request)
        
        raise HTTPException(404, "Route not found")
    
    async def forward(self, service: str, path: str, request: Request):
        """Forward request to backend service."""
        instance = service_registry.discover(service)
        url = f"http://{instance.host}:{instance.port}{path}"
        
        return await http_client.request(
            method=request.method,
            url=url,
            headers=self._forward_headers(request),
            body=await request.body()
        )


# === BFF (Backend for Frontend) Pattern ===
class MobileGateway(APIGateway):
    """
    Specialized gateway for mobile clients.
    Aggregates multiple service calls into one response.
    """
    async def get_home_screen(self, user_id: str):
        """
        Mobile needs one call for the home screen.
        This aggregates 4 service calls into 1 response.
        """
        # Parallel calls to multiple services
        user_task = asyncio.create_task(
            self.user_service.get_profile(user_id)
        )
        recommendations_task = asyncio.create_task(
            self.recommendation_service.get_for_user(user_id)
        )
        orders_task = asyncio.create_task(
            self.order_service.get_recent(user_id, limit=3)
        )
        notifications_task = asyncio.create_task(
            self.notification_service.get_unread(user_id)
        )
        
        # Wait for all (with timeouts)
        user, recommendations, orders, notifications = await asyncio.gather(
            user_task, recommendations_task, orders_task, notifications_task,
            return_exceptions=True
        )
        
        # Compose mobile-optimized response
        return {
            "user": user if not isinstance(user, Exception) else None,
            "recommendations": recommendations if not isinstance(
                recommendations, Exception) else [],
            "recent_orders": orders if not isinstance(orders, Exception) else [],
            "notification_count": notifications if not isinstance(
                notifications, Exception) else 0
        }
```

---

## Event-Driven Architecture

```
REQUEST-DRIVEN (Synchronous):

  Client ──► Service A ──► Service B ──► Service C
  Client ◄── Service A ◄── Service B ◄── Service C
  
  ⚠️ Tight coupling, cascading failures, high latency


EVENT-DRIVEN (Asynchronous):

  Service A ──publish──► ┌────────────────┐ ──consume──► Service B
                         │  Event Bus /   │ ──consume──► Service C  
  Service D ──publish──► │  Message Broker│ ──consume──► Service E
                         └────────────────┘
  
  ✓ Loose coupling, resilience, independent scaling
```

```python
# Event-Driven E-Commerce Example

from dataclasses import dataclass, field
from datetime import datetime
from typing import Callable, Dict, List
import json
import uuid

@dataclass
class Event:
    event_type: str
    data: dict
    event_id: str = field(default_factory=lambda: str(uuid.uuid4()))
    timestamp: str = field(default_factory=lambda: datetime.utcnow().isoformat())
    source: str = ""


class EventBus:
    """
    In-process event bus for demonstration.
    In production: Kafka, RabbitMQ, AWS SNS/SQS
    """
    def __init__(self):
        self.subscribers: Dict[str, List[Callable]] = {}
    
    def subscribe(self, event_type: str, handler: Callable):
        if event_type not in self.subscribers:
            self.subscribers[event_type] = []
        self.subscribers[event_type].append(handler)
    
    def publish(self, event: Event):
        handlers = self.subscribers.get(event.event_type, [])
        for handler in handlers:
            try:
                handler(event)
            except Exception as e:
                # In production: dead letter queue, retry logic
                print(f"Handler failed for {event.event_type}: {e}")


# === Services react to events independently ===

class OrderService:
    def __init__(self, event_bus: EventBus):
        self.event_bus = event_bus
    
    def place_order(self, user_id: str, items: list, total: float):
        """
        Creates order and publishes event.
        Doesn't know/care about inventory, payments, or notifications.
        """
        order = {
            "order_id": str(uuid.uuid4()),
            "user_id": user_id,
            "items": items,
            "total": total,
            "status": "CREATED"
        }
        
        self.save_to_db(order)
        
        # Publish event - other services react independently
        self.event_bus.publish(Event(
            event_type="order.created",
            data=order,
            source="order-service"
        ))
        
        return order


class InventoryService:
    def __init__(self, event_bus: EventBus):
        self.event_bus = event_bus
        # Subscribe to events we care about
        event_bus.subscribe("order.created", self.handle_order_created)
        event_bus.subscribe("order.cancelled", self.handle_order_cancelled)
    
    def handle_order_created(self, event: Event):
        """React to new order by reserving inventory."""
        order = event.data
        
        try:
            for item in order["items"]:
                self.reserve_stock(item["product_id"], item["quantity"])
            
            self.event_bus.publish(Event(
                event_type="inventory.reserved",
                data={"order_id": order["order_id"]},
                source="inventory-service"
            ))
        except InsufficientStockError:
            self.event_bus.publish(Event(
                event_type="inventory.reservation_failed",
                data={"order_id": order["order_id"], "reason": "out_of_stock"},
                source="inventory-service"
            ))
    
    def handle_order_cancelled(self, event: Event):
        """Release reserved inventory."""
        self.release_stock(event.data["order_id"])


class PaymentService:
    def __init__(self, event_bus: EventBus):
        self.event_bus = event_bus
        event_bus.subscribe("inventory.reserved", self.handle_inventory_reserved)
    
    def handle_inventory_reserved(self, event: Event):
        """Process payment after inventory is confirmed."""
        order_id = event.data["order_id"]
        order = self.get_order(order_id)
        
        try:
            payment = self.charge_customer(order["user_id"], order["total"])
            
            self.event_bus.publish(Event(
                event_type="payment.completed",
                data={"order_id": order_id, "payment_id": payment["id"]},
                source="payment-service"
            ))
        except PaymentFailedError as e:
            self.event_bus.publish(Event(
                event_type="payment.failed",
                data={"order_id": order_id, "reason": str(e)},
                source="payment-service"
            ))


class NotificationService:
    def __init__(self, event_bus: EventBus):
        event_bus.subscribe("payment.completed", self.send_confirmation)
        event_bus.subscribe("payment.failed", self.send_failure_notice)
        event_bus.subscribe("order.shipped", self.send_shipping_update)
    
    def send_confirmation(self, event: Event):
        order_id = event.data["order_id"]
        self.send_email(f"Order {order_id} confirmed and paid!")
    
    def send_failure_notice(self, event: Event):
        self.send_email(f"Payment failed for order {event.data['order_id']}")


class AnalyticsService:
    """Listens to everything for analytics - no other service knows about it."""
    def __init__(self, event_bus: EventBus):
        event_bus.subscribe("order.created", self.track_order)
        event_bus.subscribe("payment.completed", self.track_revenue)
        event_bus.subscribe("inventory.reservation_failed", self.track_stockout)
    
    def track_order(self, event: Event):
        self.metrics.increment("orders_created")
    
    def track_revenue(self, event: Event):
        self.metrics.add("revenue", event.data.get("amount", 0))


# === EVENT FLOW ===
"""
1. User places order
   OrderService publishes: order.created

2. InventoryService hears order.created
   → Reserves stock
   → Publishes: inventory.reserved

3. PaymentService hears inventory.reserved
   → Charges customer
   → Publishes: payment.completed

4. NotificationService hears payment.completed
   → Sends confirmation email

5. AnalyticsService hears ALL events
   → Tracks metrics

If anything fails, compensating events are published:
   inventory.reservation_failed → order gets cancelled
   payment.failed → inventory gets released
"""
```

---

## PART 3: MESSAGING SYSTEMS

---

## Kafka

```
KAFKA ARCHITECTURE:

┌─────────────────────────────────────────────────────────────────┐
│                        KAFKA CLUSTER                             │
│                                                                  │
│  ┌──────────┐    ┌──────────┐    ┌──────────┐                  │
│  │ Broker 1 │    │ Broker 2 │    │ Broker 3 │                  │
│  │          │    │          │    │          │                  │
│  │ ┌──────┐ │    │ ┌──────┐ │    │ ┌──────┐ │                  │
│  │ │P0-L  │ │    │ │P0-F  │ │    │ │P1-F  │ │   Topic: orders │
│  │ │P1-F  │ │    │ │P1-L  │ │    │ │P2-L  │ │                  │
│  │ │P2-F  │ │    │ │P2-F  │ │    │ │P0-F  │ │   L = Leader    │
│  │ └──────┘ │    │ └──────┘ │    │ └──────┘ │   F = Follower  │
│  └──────────┘    └──────────┘    └──────────┘                  │
│                                                                  │
│  Topic "orders" has 3 partitions, replication factor = 3        │
└─────────────────────────────────────────────────────────────────┘

PARTITION DETAIL:
┌─────────────────────────────────────────────────┐
│ Partition 0                                      │
│                                                  │
│  Offset: 0   1   2   3   4   5   6   7   8     │
│         ┌───┬───┬───┬───┬───┬───┬───┬───┬───┐  │
│         │msg│msg│msg│msg│msg│msg│msg│msg│msg│  │
│         └───┴───┴───┴───┴───┴───┴───┴───┴───┘  │
│                           ▲               ▲     │
│                     Consumer A's     New writes  │
│                     current offset   append here │
│                                                  │
│  • Ordered within partition                      │
│  • Immutable append-only log                     │
│  • Retained for configured period (e.g., 7 days)│
└─────────────────────────────────────────────────┘

CONSUMER GROUPS:
┌──────────────────────────────────────────────────────────┐
│  Consumer Group "order-processors"                        │
│                                                          │
│  Consumer 1 ◄─── Partition 0                             │
│  Consumer 2 ◄─── Partition 1        Each partition is    │
│  Consumer 3 ◄─── Partition 2        assigned to exactly  │
│                                     ONE consumer in group│
│                                                          │
│  Consumer Group "analytics"                              │
│                                                          │
│  Consumer A ◄─── Partition 0, 1     Different groups     │
│  Consumer B ◄─── Partition 2        read independently   │
└──────────────────────────────────────────────────────────┘
```

```python
# Kafka Producer - Python with confluent-kafka
from confluent_kafka import Producer, Consumer, KafkaError
import json

class OrderEventProducer:
    def __init__(self):
        self.producer = Producer({
            'bootstrap.servers': 'kafka1:9092,kafka2:9092,kafka3:9092',
            'acks': 'all',                    # Wait for all replicas
            'retries': 3,                      # Retry on failure
            'enable.idempotence': True,        # Exactly-once semantics
            'max.in.flight.requests.per.connection': 5,
            'compression.type': 'snappy',      # Compress for throughput
        })
    
    def publish_order_event(self, order: dict, event_type: str):
        topic = "orders"
        
        # Key determines partition - same order_id always goes to same partition
        # This guarantees ordering for the same order
        key = order["order_id"].encode('utf-8')
        
        value = json.dumps({
            "event_type": event_type,
            "data": order,
            "timestamp": datetime.utcnow().isoformat()
        }).encode('utf-8')
        
        # Headers for metadata (filtering without deserializing)
        headers = [
            ("event_type", event_type.encode()),
            ("source", b"order-service"),
            ("version", b"1.0")
        ]
        
        self.producer.produce(
            topic=topic,
            key=key,
            value=value,
            headers=headers,
            callback=self._delivery_callback
        )
        
        # Trigger actual send (producer batches messages)
        self.producer.flush()
    
    def _delivery_callback(self, err, msg):
        if err:
            print(f"Delivery failed: {err}")
            # In production: retry, alert, dead letter queue
        else:
            print(f"Delivered to {msg.topic()} "
                  f"partition [{msg.partition()}] "
                  f"offset {msg.offset()}")


class OrderEventConsumer:
    def __init__(self, group_id: str):
        self.consumer = Consumer({
            'bootstrap.servers': 'kafka1:9092,kafka2:9092,kafka3:9092',
            'group.id': group_id,
            'auto.offset.reset': 'earliest',     # Start from beginning if new
            'enable.auto.commit': False,           # Manual commit for safety
            'max.poll.interval.ms': 300000,        # 5 min max processing time
            'session.timeout.ms': 30000,
        })
        
        self.consumer.subscribe(['orders'])
        self.handlers = {}
    
    def register_handler(self, event_type: str, handler):
        self.handlers[event_type] = handler
    
    def start_consuming(self):
        """Main consumer loop."""
        try:
            while True:
                # Poll for messages (1 second timeout)
                msg = self.consumer.poll(1.0)
                
                if msg is None:
                    continue
                
                if msg.error():
                    if msg.error().code() == KafkaError._PARTITION_EOF:
                        continue  # End of partition, not an error
                    raise KafkaException(msg.error())
                
                try:
                    # Deserialize
                    event = json.loads(msg.value().decode('utf-8'))
                    event_type = event.get("event_type")
                    
                    # Route to handler
                    handler = self.handlers.get(event_type)
                    if handler:
                        handler(event["data"])
                    
                    # Commit offset AFTER successful processing
                    self.consumer.commit(msg)
                    
                except Exception as e:
                    # Processing failed - don't commit offset
                    # Message will be redelivered
                    print(f"Error processing message: {e}")
                    self._send_to_dead_letter_queue(msg, e)
                    self.consumer.commit(msg)  # Skip poisoned message
        finally:
            self.consumer.close()


# Kafka Streams-style processing
class OrderStreamProcessor:
    """
    Real-time stream processing with Kafka.
    Example: Compute running total of orders per user in real-time.
    """
    def __init__(self):
        self.user_totals = {}  # In production: use a state store (RocksDB)
    
    def process(self, event: dict):
        """
        For each order event, update the running total.
        
        Input stream (orders topic):
        [user:A, $50] [user:B, $30] [user:A, $20] [user:A, $100]
        
        Output stream (user-totals topic):
        [user:A, $50] [user:B, $30] [user:A, $70] [user:A, $170]
        """
        user_id = event["user_id"]
        amount = event["total"]
        
        current_total = self.user_totals.get(user_id, 0)
        new_total = current_total + amount
        self.user_totals[user_id] = new_total
        
        # Publish updated total to output topic
        self.producer.produce(
            topic="user-totals",
            key=user_id.encode(),
            value=json.dumps({
                "user_id": user_id,
                "total_spent": new_total,
                "order_count": self.user_counts.get(user_id, 0) + 1
            }).encode()
        )
```

### Key Kafka Concepts

```
┌─────────────────────────────────────────────────────────────┐
│                    KAFKA KEY CONCEPTS                        │
├────────────────────┬────────────────────────────────────────┤
│ Topic              │ Named feed/category of messages         │
│ Partition          │ Ordered, immutable sequence of records  │
│ Offset             │ Position of a message in a partition    │
│ Producer           │ Publishes messages to topics            │
│ Consumer           │ Reads messages from topics              │
│ Consumer Group     │ Set of consumers sharing the workload   │
│ Broker             │ Kafka server that stores data           │
│ Replication Factor │ Number of copies of each partition      │
│ ISR                │ In-Sync Replicas - caught up followers  │
│ Retention          │ How long messages are kept              │
│ Compaction         │ Keep only latest value per key          │
└────────────────────┴────────────────────────────────────────┘

When to use Kafka:
  ✓ High throughput (millions of events/sec)
  ✓ Event sourcing
  ✓ Log aggregation
  ✓ Stream processing
  ✓ Data pipeline
  ✓ Message replay needed
  ✓ Ordering within partition needed
```

---

## RabbitMQ

```
RABBITMQ ARCHITECTURE:

Producer ──► Exchange ──► Queue ──► Consumer

EXCHANGE TYPES:

1. DIRECT EXCHANGE (routing key match):
   ┌──────────┐        ┌──────────┐       ┌────────┐
   │ Producer │──key:──►│  Direct  │──key:──►│ Queue  │──►Consumer
   │          │ "error" │ Exchange │ "error" │"errors"│
   └──────────┘        │          │       └────────┘
                       │          │       ┌────────┐
                       │          │──key:──►│ Queue  │──►Consumer
                       │          │ "info"  │"infos" │
                       └──────────┘       └────────┘

2. FANOUT EXCHANGE (broadcast to all queues):
   ┌──────────┐        ┌──────────┐       ┌────────┐
   │ Producer │────────►│  Fanout  │───────►│Queue 1 │──►Consumer A
   │          │        │ Exchange │───────►│Queue 2 │──►Consumer B
   └──────────┘        │          │───────►│Queue 3 │──►Consumer C
                       └──────────┘       └────────┘

3. TOPIC EXCHANGE (pattern matching):
   ┌──────────┐        ┌──────────┐
   │ Producer │──key:──►│  Topic   │
   │          │"order.  │ Exchange │
   └──────────┘ created"│          │
                       │          │──"order.*"──►│Queue 1│ (all order events)
                       │          │──"*.created"─►│Queue 2│ (all created events)
                       │          │──"#"─────────►│Queue 3│ (everything)
                       └──────────┘

4. HEADERS EXCHANGE (header attribute matching):
   Routes based on message headers instead of routing key
```

```python
import pika
import json

class RabbitMQPublisher:
    def __init__(self):
        self.connection = pika.BlockingConnection(
            pika.ConnectionParameters(
                host='rabbitmq-host',
                credentials=pika.PlainCredentials('user', 'pass'),
                heartbeat=600,
                blocked_connection_timeout=300
            )
        )
        self.channel = self.connection.channel()
        
        # Declare exchange
        self.channel.exchange_declare(
            exchange='orders',
            exchange_type='topic',
            durable=True  # Survives broker restart
        )
    
    def publish_order_event(self, order: dict, event_type: str):
        message = json.dumps({
            "event_type": event_type,
            "data": order,
            "timestamp": datetime.utcnow().isoformat()
        })
        
        self.channel.basic_publish(
            exchange='orders',
            routing_key=f'order.{event_type}',  # e.g., "order.created"
            body=message,
            properties=pika.BasicProperties(
                delivery_mode=2,        # Persistent (survives restart)
                content_type='application/json',
                message_id=str(uuid.uuid4()),
                timestamp=int(time.time()),
                headers={
                    'version': '1.0',
                    'source': 'order-service'
                }
            )
        )


class RabbitMQConsumer:
    def __init__(self, queue_name: str, routing_keys: list):
        self.connection = pika.BlockingConnection(
            pika.ConnectionParameters('rabbitmq-host')
        )
        self.channel = self.connection.channel()
        
        # Declare queue
        self.channel.queue_declare(
            queue=queue_name,
            durable=True,
            arguments={
                'x-dead-letter-exchange': 'orders.dlx',  # Failed messages go here
                'x-message-ttl': 86400000,  # 24h TTL
                'x-max-length': 100000       # Max queue size
            }
        )
        
        # Bind queue to exchange with routing keys
        for key in routing_keys:
            self.channel.queue_bind(
                exchange='orders',
                queue=queue_name,
                routing_key=key
            )
        
        # Prefetch: get only 10 messages at a time
        self.channel.basic_qos(prefetch_count=10)
    
    def start_consuming(self, callback):
        def on_message(ch, method, properties, body):
            try:
                message = json.loads(body)
                callback(message)
                
                # Acknowledge: message successfully processed
                ch.basic_ack(delivery_tag=method.delivery_tag)
                
            except Exception as e:
                # Negative acknowledge: requeue or send to DLQ
                ch.basic_nack(
                    delivery_tag=method.delivery_tag,
                    requeue=False  # Send to Dead Letter Queue
                )
        
        self.channel.basic_consume(
            queue=self.queue_name,
            on_message_callback=on_message
        )
        
        self.channel.start_consuming()


# Usage Example
def setup_order_processing():
    # Publisher
    publisher = RabbitMQPublisher()
    
    # Consumer for payment processing (listens to order.created)
    payment_consumer = RabbitMQConsumer(
        queue_name='payment-processing',
        routing_keys=['order.created']
    )
    
    # Consumer for analytics (listens to ALL order events)
    analytics_consumer = RabbitMQConsumer(
        queue_name='order-analytics',
        routing_keys=['order.*']  # Wildcard: order.created, order.shipped, etc.
    )
    
    # Consumer for notifications (listens to specific events)
    notification_consumer = RabbitMQConsumer(
        queue_name='order-notifications',
        routing_keys=['order.created', 'order.shipped', 'order.delivered']
    )
```

---

## SQS (Amazon Simple Queue Service)

```
SQS Architecture:

┌──────────┐     ┌──────────────────────────┐     ┌──────────┐
│ Producer │────►│        SQS Queue          │────►│ Consumer │
│          │     │                            │     │          │
│  Send    │     │  ┌───┬───┬───┬───┬───┐   │     │  Receive │
│ Message  │     │  │msg│msg│msg│msg│msg│   │     │  Delete  │
│          │     │  └───┴───┴───┴───┴───┘   │     │          │
└──────────┘     │                            │     └──────────┘
                 │  • Fully managed            │
                 │  • Auto-scales              │
                 │  • At-least-once delivery   │
                 │  • Visibility timeout       │
                 └──────────────────────────────┘

STANDARD vs FIFO:
┌─────────────────────┬────────────────────┬─────────────────────┐
│                     │    Standard        │       FIFO          │
├─────────────────────┼────────────────────┼─────────────────────┤
│ Throughput          │ Unlimited          │ 300 msg/s (3000     │
│                     │                    │ with batching)      │
│ Ordering            │ Best-effort        │ Guaranteed          │
│ Delivery            │ At-least-once      │ Exactly-once        │
│ Deduplication       │ Not guaranteed     │ 5-min dedup window  │
│ Use case            │ High throughput    │ Order-sensitive     │
└─────────────────────┴────────────────────┴─────────────────────┘
```

```python
import boto3
import json

class SQSProcessor:
    def __init__(self, queue_url: str):
        self.sqs = boto3.client('sqs', region_name='us-east-1')
        self.queue_url = queue_url
    
    def send_message(self, message: dict, group_id: str = None):
        """Send a message to the queue."""
        params = {
            'QueueUrl': self.queue_url,
            'MessageBody': json.dumps(message),
            'MessageAttributes': {
                'EventType': {
                    'DataType': 'String',
                    'StringValue': message.get('event_type', 'unknown')
                },
                'Source': {
                    'DataType': 'String',
                    'StringValue': 'order-service'
                }
            }
        }
        
        # For FIFO queues
        if group_id:
            params['MessageGroupId'] = group_id
            params['MessageDeduplicationId'] = message.get('idempotency_key', 
                                                            str(uuid.uuid4()))
        
        response = self.sqs.send_message(**params)
        return response['MessageId']
    
    def process_messages(self, handler, batch_size: int = 10):
        """
        Long-polling consumer loop.
        
        SQS Visibility Timeout Flow:
        1. Consumer receives message → message becomes INVISIBLE to other consumers
        2. Consumer processes message
        3a. Success → Consumer DELETES message
        3b. Failure → Visibility timeout expires → message becomes VISIBLE again
        """
        while True:
            # Long polling (wait up to 20 seconds for messages)
            response = self.sqs.receive_message(
                QueueUrl=self.queue_url,
                MaxNumberOfMessages=batch_size,     # Up to 10
                WaitTimeSeconds=20,                  # Long polling
                VisibilityTimeout=300,               # 5 min to process
                MessageAttributeNames=['All']
            )
            
            messages = response.get('Messages', [])
            
            if not messages:
                continue
            
            for message in messages:
                try:
                    body = json.loads(message['Body'])
                    
                    # Process the message
                    handler(body)
                    
                    # Delete on success (acknowledge)
                    self.sqs.delete_message(
                        QueueUrl=self.queue_url,
                        ReceiptHandle=message['ReceiptHandle']
                    )
                    
                except Exception as e:
                    # Don't delete - message will reappear after visibility timeout
                    print(f"Failed to process message: {e}")
                    
                    # Optionally: change visibility timeout to retry sooner
                    self.sqs.change_message_visibility(
                        QueueUrl=self.queue_url,
                        ReceiptHandle=message['ReceiptHandle'],
                        VisibilityTimeout=60  # Retry in 1 minute
                    )
    
    def setup_dead_letter_queue(self, dlq_arn: str, max_receives: int = 3):
        """
        After max_receives failures, message goes to DLQ for investigation.
        """
        self.sqs.set_queue_attributes(
            QueueUrl=self.queue_url,
            Attributes={
                'RedrivePolicy': json.dumps({
                    'deadLetterTargetArn': dlq_arn,
                    'maxReceiveCount': str(max_receives)
                })
            }
        )
```

---

## Messaging Concepts

### Pub/Sub (Publish/Subscribe)

```
┌───────────┐                                    ┌──────────────┐
│ Publisher  │──── "price.update" ───►            │ Subscriber A │
│ (doesn't  │                        ┌────────►  │ (Dashboard)  │
│  know who  │                        │           └──────────────┘
│  listens)  │    ┌────────────┐      │           ┌──────────────┐
│            │───►│   Topic    │──────┼────────►  │ Subscriber B │
└───────────┘    │ (Channel)  │      │           │ (Alert Svc)  │
                 └────────────┘      │           └──────────────┘
                                     │           ┌──────────────┐
                                     └────────►  │ Subscriber C │
                                                 │ (Logger)     │
                                                 └──────────────┘

Key Properties:
  • Publishers are decoupled from subscribers
  • Multiple subscribers receive the SAME message
  • Adding new subscribers requires NO changes to publishers
  • Messages are ephemeral (not queued) in pure pub/sub
```

```python
# Pub/Sub with Redis
import redis

class RedisPubSub:
    def __init__(self):
        self.redis = redis.Redis(host='localhost', port=6379)
    
    def publish(self, channel: str, message: dict):
        """Publisher sends message to channel. Fire-and-forget."""
        self.redis.publish(channel, json.dumps(message))
    
    def subscribe(self, channels: list, handler):
        """Subscriber listens for messages on channels."""
        pubsub = self.redis.pubsub()
        pubsub.subscribe(*channels)
        
        for message in pubsub.listen():
            if message['type'] == 'message':
                data = json.loads(message['data'])
                handler(message['channel'], data)

# Example: Real-time price updates
class StockPricePublisher:
    def __init__(self, pubsub: RedisPubSub):
        self.pubsub = pubsub
    
    def update_price(self, symbol: str, price: float):
        self.pubsub.publish(f"price.{symbol}", {
            "symbol": symbol,
            "price": price,
            "timestamp": time.time()
        })

class TradingDashboard:
    """Subscribes to price updates for display."""
    def __init__(self, pubsub: RedisPubSub, symbols: list):
        channels = [f"price.{s}" for s in symbols]
        pubsub.subscribe(channels, self.on_price_update)
    
    def on_price_update(self, channel: str, data: dict):
        print(f"[DASHBOARD] {data['symbol']}: ${data['price']}")

class AlertService:
    """Subscribes to ALL price updates for alerting."""
    def __init__(self, pubsub: RedisPubSub):
        pubsub.subscribe(["price.*"], self.check_alert)
    
    def check_alert(self, channel: str, data: dict):
        if self.should_alert(data['symbol'], data['price']):
            self.send_alert(f"{data['symbol']} hit ${data['price']}!")
```

### Event Streaming

```
TRADITIONAL MESSAGING vs EVENT STREAMING:

Traditional (RabbitMQ/SQS):
  Message is CONSUMED and REMOVED from queue
  ┌───┬───┬───┬───┬───┐  Consumer reads msg1 → ┌───┬───┬───┬───┐
  │ 1 │ 2 │ 3 │ 4 │ 5 │                         │ 2 │ 3 │ 4 │ 5 │
  └───┴───┴───┴───┴───┘                         └───┴───┴───┴───┘
  (msg1 is gone forever)

Event Streaming (Kafka):
  Events are RETAINED in an immutable log
  ┌───┬───┬───┬───┬───┬───┬───┬───┐
  │ 0 │ 1 │ 2 │ 3 │ 4 │ 5 │ 6 │ 7 │  ← Events stay in the log
  └───┴───┴───┴───┴───┴───┴───┴───┘
                ▲           ▲
           Consumer A   Consumer B     ← Each tracks own position
           (offset 3)   (offset 5)

  Benefits:
  ✓ Replay: New consumer can start from the beginning
  ✓ Audit: Complete history of all events
  ✓ Multiple consumers: Each reads independently
  ✓ Time travel: Reprocess events from any point
```

```python
# Event Streaming: Event Sourcing Pattern
class BankAccount:
    """
    Instead of storing current state, store ALL events.
    Current state = replay of all events.
    """
    def __init__(self, account_id: str, event_store):
        self.account_id = account_id
        self.event_store = event_store
        self.balance = 0
        self.version = 0
        
        # Rebuild state from event history
        self._replay_events()
    
    def _replay_events(self):
        """Rebuild current state by replaying all past events."""
        events = self.event_store.get_events(self.account_id)
        for event in events:
            self._apply_event(event)
    
    def _apply_event(self, event: dict):
        """Apply a single event to update state."""
        if event["type"] == "money_deposited":
            self.balance += event["amount"]
        elif event["type"] == "money_withdrawn":
            self.balance -= event["amount"]
        elif event["type"] == "account_opened":
            self.balance = event.get("initial_balance", 0)
        self.version += 1
    
    def deposit(self, amount: float):
        if amount <= 0:
            raise ValueError("Amount must be positive")
        
        event = {
            "type": "money_deposited",
            "account_id": self.account_id,
            "amount": amount,
            "timestamp": datetime.utcnow().isoformat(),
            "version": self.version + 1
        }
        
        # Store the event (not the state)
        self.event_store.append(self.account_id, event)
        self._apply_event(event)
    
    def withdraw(self, amount: float):
        if amount > self.balance:
            raise InsufficientFundsError()
        
        event = {
            "type": "money_withdrawn",
            "account_id": self.account_id,
            "amount": amount,
            "timestamp": datetime.utcnow().isoformat(),
            "version": self.version + 1
        }
        
        self.event_store.append(self.account_id, event)
        self._apply_event(event)


class EventStore:
    """
    Stores events in Kafka - immutable, ordered, replayable.
    """
    def __init__(self):
        self.producer = KafkaProducer(bootstrap_servers='kafka:9092')
        self.consumer = KafkaConsumer(bootstrap_servers='kafka:9092')
    
    def append(self, aggregate_id: str, event: dict):
        """Append event to the stream."""
        self.producer.produce(
            topic="bank-account-events",
            key=aggregate_id.encode(),
            value=json.dumps(event).encode()
        )
    
    def get_events(self, aggregate_id: str) -> list:
        """Get all events for an aggregate (account)."""
        # Read all events with matching key from topic
        events = []
        for msg in self.consumer.read_topic("bank-account-events"):
            if msg.key == aggregate_id:
                events.append(json.loads(msg.value))
        return events


# Event history for account "ACC-001":
# [
#   {"type": "account_opened", "amount": 0, "timestamp": "2024-01-01"},
#   {"type": "money_deposited", "amount": 1000, "timestamp": "2024-01-02"},
#   {"type": "money_deposited", "amount": 500, "timestamp": "2024-01-15"},
#   {"type": "money_withdrawn", "amount": 200, "timestamp": "2024-02-01"},
#   {"type": "money_deposited", "amount": 300, "timestamp": "2024-02-15"},
# ]
# Current balance: 0 + 1000 + 500 - 200 + 300 = $1600
```

### Idempotency

```
The Problem:
  Client ──► Server: "Charge $100"      (Request 1)
  Client ◄── Server: (timeout/no response)
  Client ──► Server: "Charge $100"      (Request 2 - retry)
  
  WITHOUT idempotency: Customer charged $200! 💥
  WITH idempotency:    Customer charged $100  ✓
```

```python
import hashlib
import json
from datetime import datetime, timedelta

class IdempotentProcessor:
    """
    Ensures that processing a message multiple times 
    produces the same result as processing it once.
    """
    def __init__(self, redis_client):
        self.redis = redis_client
        self.idempotency_window = timedelta(hours=24)
    
    def process_payment(self, payment_request: dict) -> dict:
        """
        Idempotent payment processing.
        Same idempotency_key always returns same result.
        """
        idempotency_key = payment_request.get("idempotency_key")
        
        if not idempotency_key:
            raise ValueError("idempotency_key is required")
        
        # Check if we've already processed this request
        cache_key = f"idempotent:{idempotency_key}"
        existing_result = self.redis.get(cache_key)
        
        if existing_result:
            # Already processed - return the same result
            return json.loads(existing_result)
        
        # Try to acquire a lock (prevent concurrent duplicate processing)
        lock_key = f"lock:{idempotency_key}"
        lock_acquired = self.redis.set(
            lock_key, "locked", 
            nx=True,  # Only set if doesn't exist
            ex=30     # 30 second expiry
        )
        
        if not lock_acquired:
            # Another process is handling this request
            raise ConflictError("Request is being processed")
        
        try:
            # Process the payment
            result = self._charge_payment_provider(
                amount=payment_request["amount"],
                customer_id=payment_request["customer_id"]
            )
            
            # Cache the result for the idempotency window
            self.redis.setex(
                cache_key,
                time=int(self.idempotency_window.total_seconds()),
                value=json.dumps(result)
            )
            
            return result
        finally:
            self.redis.delete(lock_key)


class IdempotentEventHandler:
    """
    Handles events idempotently using event ID tracking.
    Critical for at-least-once delivery systems.
    """
    def __init__(self, db):
        self.db = db
    
    def handle_order_created(self, event: dict):
        """
        This handler might be called multiple times for the same event
        (Kafka consumer rebalancing, network issues, etc.)
        Must be safe to call multiple times.
        """
        event_id = event["event_id"]
        
        # Check if event was already processed
        if self.db.exists("processed_events", {"event_id": event_id}):
            return  # Already handled, skip
        
        # Use database transaction to atomically:
        # 1. Process the business logic
        # 2. Record that we processed this event
        with self.db.transaction() as tx:
            order = event["data"]
            
            # Business logic (with upsert to be safe)
            tx.execute("""
                INSERT INTO order_summaries (order_id, total, status)
                VALUES (%s, %s, 'PENDING')
                ON CONFLICT (order_id) DO NOTHING
            """, (order["order_id"], order["total"]))
            
            # Record event as processed
            tx.execute("""
                INSERT INTO processed_events (event_id, processed_at)
                VALUES (%s, NOW())
                ON CONFLICT (event_id) DO NOTHING
            """, (event_id,))
            
            tx.commit()


# Idempotent API Endpoint
class PaymentAPI:
    """
    REST API with idempotency key support.
    
    Client sends:
    POST /payments
    Idempotency-Key: abc-123-def-456
    {
        "amount": 100.00,
        "currency": "USD",
        "customer_id": "cust_789"
    }
    
    First call: processes payment, returns 200
    Retry calls: returns same 200 with same response body
    """
    def create_payment(self, request):
        idempotency_key = request.headers.get("Idempotency-Key")
        
        if not idempotency_key:
            return Response(400, "Idempotency-Key header required")
        
        # Check for existing result
        existing = self.cache.get(f"payment:{idempotency_key}")
        if existing:
            return Response(200, existing, headers={
                "X-Idempotent-Replay": "true"
            })
        
        # Process new payment
        result = self.payment_processor.charge(request.body)
        
        # Store result
        self.cache.setex(
            f"payment:{idempotency_key}",
            86400,  # 24 hours
            result
        )
        
        return Response(200, result)
```

---

## PART 4: DISTRIBUTED SYSTEMS

---

## Distributed Locks

```
The Problem Without Distributed Locks:

Time ──────────────────────────────────────────►

Server A:  READ balance=$100  │  WRITE balance=$50  (deduct $50)
                              │
Server B:      READ balance=$100  │  WRITE balance=$50  (deduct $50)

Expected: balance = $0 (two $50 deductions)
Actual:   balance = $50 (lost update!)

With Distributed Lock:

Server A:  ACQUIRE LOCK → READ $100 → WRITE $50 → RELEASE LOCK
                                                        │
Server B:  WAIT......... ACQUIRE LOCK → READ $50 → WRITE $0 → RELEASE LOCK

Result: balance = $0 ✓
```

```python
import redis
import uuid
import time

class RedisDistributedLock:
    """
    Implementation of distributed lock using Redis (Redlock algorithm simplified).
    
    Key properties:
    1. Mutual exclusion - only one holder at a time
    2. Deadlock free - lock auto-expires (TTL)
    3. Fault tolerant - lock released even if holder crashes
    """
    def __init__(self, redis_client):
        self.redis = redis_client
    
    def acquire(self, resource: str, ttl_seconds: int = 30, 
                retry_count: int = 3, retry_delay: float = 0.2) -> str:
        """
        Attempt to acquire a lock on a resource.
        Returns a token (needed for safe release) or None.
        """
        # Unique token prevents releasing someone else's lock
        token = str(uuid.uuid4())
        lock_key = f"lock:{resource}"
        
        for attempt in range(retry_count):
            # SET NX (only if not exists) with expiry
            acquired = self.redis.set(
                lock_key,
                token,
                nx=True,    # Only set if key doesn't exist
                ex=ttl_seconds  # Auto-expire to prevent deadlocks
            )
            
            if acquired:
                return token  # Lock acquired successfully
            
            # Wait before retrying
            time.sleep(retry_delay * (2 ** attempt))  # Exponential backoff
        
        return None  # Failed to acquire lock
    
    def release(self, resource: str, token: str) -> bool:
        """
        Release the lock, but ONLY if we still own it.
        Uses Lua script for atomicity (check + delete).
        """
        lock_key = f"lock:{resource}"
        
        # Lua script ensures atomic check-and-delete
        # Without this, there's a race condition:
        #   1. Check token matches → yes
        #   2. Another process acquires the lock
        #   3. We delete the NEW lock!
        lua_script = """
        if redis.call("GET", KEYS[1]) == ARGV[1] then
            return redis.call("DEL", KEYS[1])
        else
            return 0
        end
        """
        
        result = self.redis.eval(lua_script, 1, lock_key, token)
        return result == 1
    
    def extend(self, resource: str, token: str, 
               additional_seconds: int) -> bool:
        """Extend lock TTL if we still hold it (for long operations)."""
        lock_key = f"lock:{resource}"
        
        lua_script = """
        if redis.call("GET", KEYS[1]) == ARGV[1] then
            return redis.call("EXPIRE", KEYS[1], ARGV[2])
        else
            return 0
        end
        """
        
        result = self.redis.eval(
            lua_script, 1, lock_key, token, additional_seconds
        )
        return result == 1


# Context manager for clean usage
class DistributedLock:
    def __init__(self, lock_manager, resource, ttl=30):
        self.lock_manager = lock_manager
        self.resource = resource
        self.ttl = ttl
        self.token = None
    
    def __enter__(self):
        self.token = self.lock_manager.acquire(self.resource, self.ttl)
        if not self.token:
            raise LockAcquisitionError(
                f"Failed to acquire lock on '{self.resource}'"
            )
        return self
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        if self.token:
            self.lock_manager.release(self.resource, self.token)
        return False


# Usage Example: Preventing double-booking
class BookingService:
    def __init__(self):
        self.lock_manager = RedisDistributedLock(redis.Redis())
        self.db = Database()
    
    def book_seat(self, flight_id: str, seat_number: str, user_id: str):
        """
        Multiple servers might try to book the same seat simultaneously.
        Distributed lock prevents double-booking.
        """
        resource = f"flight:{flight_id}:seat:{seat_number}"
        
        with DistributedLock(self.lock_manager, resource, ttl=10):
            # Inside the lock - only one server executes this at a time
            
            # Check if seat is available
            seat = self.db.query(
                "SELECT * FROM seats WHERE flight_id=%s AND seat=%s",
                flight_id, seat_number
            )
            
            if seat.status != 'AVAILABLE':
                raise SeatUnavailableError(f"Seat {seat_number} is taken")
            
            # Book the seat
            self.db.execute(
                "UPDATE seats SET status='BOOKED', user_id=%s "
                "WHERE flight_id=%s AND seat=%s",
                user_id, flight_id, seat_number
            )
            
            return BookingConfirmation(flight_id, seat_number, user_id)


# Redlock: Multi-node Redis lock (production-grade)
class Redlock:
    """
    Uses N independent Redis instances.
    Lock is acquired only if majority (N/2 + 1) grant it.
    Protects against single Redis node failure.
    """
    def __init__(self, redis_instances: list):
        self.instances = redis_instances  # e.g., 5 independent Redis nodes
        self.quorum = len(redis_instances) // 2 + 1  # e.g., 3
    
    def acquire(self, resource: str, ttl: int = 30) -> dict:
        token = str(uuid.uuid4())
        start_time = time.monotonic()
        
        acquired_count = 0
        for instance in self.instances:
            try:
                if instance.set(f"lock:{resource}", token, nx=True, ex=ttl):
                    acquired_count += 1
            except redis.RedisError:
                continue  # Skip failed nodes
        
        # Check if we got majority AND didn't take too long
        elapsed = time.monotonic() - start_time
        remaining_ttl = ttl - elapsed
        
        if acquired_count >= self.quorum and remaining_ttl > 0:
            return {"token": token, "valid_until": time.time() + remaining_ttl}
        else:
            # Failed to get quorum - release all acquired locks
            self._release_all(resource, token)
            return None
```

---

## Leader Election

```
WHY LEADER ELECTION?

In distributed systems, sometimes ONE node must coordinate:
  • Database primary (handles writes)
  • Task scheduler (assigns work)
  • Cron job runner (don't run same job on all nodes)
  • Cache coordinator (manages invalidation)

Without leader election:
  Node A: "I'll process the daily report" ──► Report runs 3 times!
  Node B: "I'll process the daily report"
  Node C: "I'll process the daily report"

With leader election:
  Node A: "I'm the leader, I'll run it" ──► Report runs once ✓
  Node B: "Node A is leader, I'll standby"
  Node C: "Node A is leader, I'll standby"
  
  If Node A dies:
  Node B: "Node A is gone, I'm the new leader" ──► Takes over ✓
  Node C: "Node B is leader, I'll standby"
```

```python
# Leader Election with ZooKeeper (using Kazoo library)
from kazoo.client import KazooClient
from kazoo.recipe.election import Election
import threading
import time

class ZooKeeperLeaderElection:
    """
    Uses ZooKeeper's ephemeral sequential nodes for leader election.
    
    How it works:
    1. Each node creates an ephemeral sequential znode:
       /election/node-0000000001  (Node A)
       /election/node-0000000002  (Node B)
       /election/node-0000000003  (Node C)
    
    2. Node with LOWEST sequence number is the leader
    
    3. If leader dies, its ephemeral node is auto-deleted
       ZooKeeper notifies next node → new leader
    """
    def __init__(self, node_id: str, zk_hosts: str = 'localhost:2181'):
        self.node_id = node_id
        self.zk = KazooClient(hosts=zk_hosts)
        self.zk.start()
        self.is_leader = False
        self.leader_callback = None
        self.follower_callback = None
    
    def run_election(self, election_path: str = "/election"):
        """Participate in leader election."""
        election = Election(self.zk, election_path, self.node_id)
        
        # This blocks until we become leader
        # When leader dies, next candidate is promoted automatically
        election.run(self._on_elected)
    
    def _on_elected(self):
        """Called when this node becomes the leader."""
        self.is_leader = True
        print(f"[{self.node_id}] I am now the LEADER!")
        
        if self.leader_callback:
            self.leader_callback()
        
        # Keep running as leader until we're told to stop
        while self.is_leader:
            self._do_leader_work()
            time.sleep(1)
    
    def _do_leader_work(self):
        """Work that only the leader should do."""
        pass  # Override in subclass


# Leader Election with Redis (simpler but less robust)
class RedisLeaderElection:
    """
    Simpler leader election using Redis TTL.
    Less robust than ZooKeeper but easier to set up.
    """
    def __init__(self, node_id: str, redis_client):
        self.node_id = node_id
        self.redis = redis_client
        self.leader_key = "cluster:leader"
        self.term_seconds = 10  # Leadership term
        self.running = True
    
    def start(self, on_leader: callable, on_follower: callable):
        """Main election loop."""
        while self.running:
            try:
                if self._try_become_leader():
                    print(f"[{self.node_id}] Became LEADER")
                    on_leader()
                    
                    # Heartbeat: renew leadership
                    while self.running and self._renew_leadership():
                        on_leader()
                        time.sleep(self.term_seconds / 3)
                    
                    print(f"[{self.node_id}] Lost leadership")
                else:
                    current_leader = self.redis.get(self.leader_key)
                    print(f"[{self.node_id}] Following {current_leader}")
                    on_follower()
                    time.sleep(self.term_seconds / 2)
                    
            except redis.RedisError:
                time.sleep(1)
    
    def _try_become_leader(self) -> bool:
        """Try to claim leadership."""
        return self.redis.set(
            self.leader_key,
            self.node_id,
            nx=True,  # Only if no current leader
            ex=self.term_seconds
        )
    
    def _renew_leadership(self) -> bool:
        """Renew our leadership term."""
        lua_script = """
        if redis.call("GET", KEYS[1]) == ARGV[1] then
            return redis.call("EXPIRE", KEYS[1], ARGV[2])
        else
            return 0
        end
        """
        return self.redis.eval(
            lua_script, 1,
            self.leader_key, self.node_id, self.term_seconds
        ) == 1


# Example: Cron Job Scheduler with Leader Election
class DistributedScheduler:
    """
    Only the leader node runs scheduled jobs.
    If leader fails, another node takes over.
    """
    def __init__(self, node_id: str):
        self.node_id = node_id
        self.election = RedisLeaderElection(node_id, redis.Redis())
        self.jobs = {}
    
    def register_job(self, name: str, func: callable, interval_seconds: int):
        self.jobs[name] = {
            "func": func,
            "interval": interval_seconds,
            "last_run": 0
        }
    
    def start(self):
        self.election.start(
            on_leader=self._run_as_leader,
            on_follower=self._run_as_follower
        )
    
    def _run_as_leader(self):
        """Execute scheduled jobs."""
        now = time.time()
        for name, job in self.jobs.items():
            if now - job["last_run"] >= job["interval"]:
                try:
                    job["func"]()
                    job["last_run"] = now
                except Exception as e:
                    print(f"Job {name} failed: {e}")
    
    def _run_as_follower(self):
        """Standby - ready to take over if leader fails."""
        pass  # Just wait


# Usage
scheduler = DistributedScheduler("node-1")
scheduler.register_job("daily_report", generate_daily_report, 86400)
scheduler.register_job("cleanup", cleanup_old_data, 3600)
scheduler.start()
```

---

## Consensus Algorithms

```
THE CONSENSUS PROBLEM:

Multiple nodes must agree on a single value, even if some nodes fail.

Example: "What is the committed value of account balance?"
  Node A thinks: $100
  Node B thinks: $150 (received a deposit)
  Node C thinks: $100
  
  Consensus: All nodes must agree → $150 (majority saw the deposit)


TWO MAIN ALGORITHMS:

1. PAXOS (theoretical foundation)
2. RAFT (practical, understandable implementation)
```

### Raft Consensus Algorithm

```
RAFT: Three Roles

┌─────────────────────────────────────────────────────────────────────┐
│                                                                     │
│  ┌──────────┐    Heartbeats     ┌──────────┐    Heartbeats         │
│  │ FOLLOWER │ ◄──────────────── │  LEADER  │ ──────────────►       │
│  │          │                    │          │              ┌────────┤
│  │ Passive  │                    │ Handles  │              │FOLLOWER│
│  │ Receives │   Election         │ all      │              │        │
│  │ updates  │   Timeout          │ client   │              │Passive │
│  └────┬─────┘       │           │ requests │              └────────┘
│       │              ▼           └──────────┘                       │
│       │        ┌──────────┐                                        │
│       │        │CANDIDATE │                                        │
│       └───────►│          │ Requests votes from all nodes          │
│                │ Seeks    │ If majority votes YES → becomes LEADER │
│                │ election │ If loses → back to FOLLOWER            │
│                └──────────┘                                        │
└─────────────────────────────────────────────────────────────────────┘

RAFT LOG REPLICATION:

Client: "Set X=5"
    │
    ▼
┌──────────┐  1. Append to local log
│  LEADER  │  2. Send AppendEntries to followers
│  Log:    │  
│  [X=5]   │──────────────────────────┐
└──────────┘                          │
                                      ▼
              ┌──────────┐     ┌──────────┐
              │ FOLLOWER │     │ FOLLOWER │
              │  Log:    │     │  Log:    │
              │  [X=5]   │     │  [X=5]   │
              └──────────┘     └──────────┘
                    │                │
                    └────────────────┘
                           │
                      ACK to Leader
                           │
                    ▼ (majority ACKed)
              Leader COMMITS entry
              Applies X=5 to state machine
              Responds to client: "OK"
              Notifies followers to commit
```

```python
import random
import threading
import time
from enum import Enum
from typing import Dict, List, Optional

class NodeState(Enum):
    FOLLOWER = "follower"
    CANDIDATE = "candidate"
    LEADER = "leader"

class LogEntry:
    def __init__(self, term: int, command: str, value: any):
        self.term = term
        self.command = command
        self.value = value

class RaftNode:
    """
    Simplified Raft consensus implementation.
    Demonstrates the core concepts.
    """
    def __init__(self, node_id: str, peers: List[str]):
        self.node_id = node_id
        self.peers = peers
        
        # Persistent state
        self.current_term = 0
        self.voted_for = None
        self.log: List[LogEntry] = []
        
        # Volatile state
        self.state = NodeState.FOLLOWER
        self.commit_index = -1
        self.last_applied = -1
        
        # Leader state
        self.next_index: Dict[str, int] = {}    # Next log index to send to each follower
        self.match_index: Dict[str, int] = {}   # Highest replicated index per follower
        
        # Timing
        self.election_timeout = random.uniform(1.5, 3.0)  # Randomized!
        self.heartbeat_interval = 0.5
        self.last_heartbeat = time.time()
        
        # State machine
        self.state_machine: Dict[str, any] = {}
    
    def start(self):
        """Start the Raft node."""
        threading.Thread(target=self._election_timer, daemon=True).start()
        threading.Thread(target=self._apply_committed, daemon=True).start()
    
    # === ELECTION ===
    def _election_timer(self):
        """If no heartbeat from leader, start election."""
        while True:
            time.sleep(0.1)
            
            if self.state == NodeState.LEADER:
                self._send_heartbeats()
                continue
            
            elapsed = time.time() - self.last_heartbeat
            if elapsed > self.election_timeout:
                self._start_election()
    
    def _start_election(self):
        """Transition to candidate and request votes."""
        self.state = NodeState.CANDIDATE
        self.current_term += 1
        self.voted_for = self.node_id
        votes_received = 1  # Vote for self
        
        print(f"[{self.node_id}] Starting election for term {self.current_term}")
        
        # Request votes from all peers
        for peer in self.peers:
            vote_granted = self._request_vote(
                peer,
                term=self.current_term,
                candidate_id=self.node_id,
                last_log_index=len(self.log) - 1,
                last_log_term=self.log[-1].term if self.log else 0
            )
            if vote_granted:
                votes_received += 1
        
        # Check if we won majority
        total_nodes = len(self.peers) + 1
        if votes_received > total_nodes // 2:
            self._become_leader()
        else:
            self.state = NodeState.FOLLOWER
            # Randomize timeout to prevent split votes
            self.election_timeout = random.uniform(1.5, 3.0)
    
    def _become_leader(self):
        """Transition to leader state."""
        self.state = NodeState.LEADER
        print(f"[{self.node_id}] Became LEADER for term {self.current_term}")
        
        # Initialize leader state
        for peer in self.peers:
            self.next_index[peer] = len(self.log)
            self.match_index[peer] = -1
        
        # Send immediate heartbeat to establish authority
        self._send_heartbeats()
    
    def handle_request_vote(self, term: int, candidate_id: str, 
                            last_log_index: int, last_log_term: int) -> bool:
        """Decide whether to vote for a candidate."""
        # If candidate's term is old, reject
        if term < self.current_term:
            return False
        
        # If we haven't voted or already voted for this candidate
        if self.voted_for is None or self.voted_for == candidate_id:
            # Only vote if candidate's log is at least as up-to-date as ours
            our_last_term = self.log[-1].term if self.log else 0
            our_last_index = len(self.log) - 1
            
            log_is_current = (
                last_log_term > our_last_term or
                (last_log_term == our_last_term and 
                 last_log_index >= our_last_index)
            )
            
            if log_is_current:
                self.voted_for = candidate_id
                self.last_heartbeat = time.time()
                return True
        
        return False
    
    # === LOG REPLICATION ===
    def client_request(self, command: str, value: any) -> bool:
        """Handle a client request (only leader can handle)."""
        if self.state != NodeState.LEADER:
            raise NotLeaderError(f"Not leader. Current leader: {self.leader_id}")
        
        # 1. Append to local log
        entry = LogEntry(self.current_term, command, value)
        self.log.append(entry)
        
        # 2. Replicate to followers
        replicated_count = 1  # Count self
        
        for peer in self.peers:
            success = self._append_entries(
                peer,
                entries=[entry],
                prev_log_index=len(self.log) - 2,
                prev_log_term=self.log[-2].term if len(self.log) > 1 else 0,
                leader_commit=self.commit_index
            )
            if success:
                replicated_count += 1
        
        # 3. If majority replicated, commit
        total_nodes = len(self.peers) + 1
        if replicated_count > total_nodes // 2:
            self.commit_index = len(self.log) - 1
            return True
        
        return False
    
    def _apply_committed(self):
        """Apply committed log entries to state machine."""
        while True:
            while self.last_applied < self.commit_index:
                self.last_applied += 1
                entry = self.log[self.last_applied]
                
                # Apply to state machine
                if entry.command == "SET":
                    key, val = entry.value
                    self.state_machine[key] = val
                elif entry.command == "DELETE":
                    self.state_machine.pop(entry.value, None)
                
                print(f"[{self.node_id}] Applied: {entry.command} {entry.value}")
            
            time.sleep(0.01)
    
    def _send_heartbeats(self):
        """Leader sends periodic heartbeats to maintain authority."""
        for peer in self.peers:
            self._append_entries(
                peer,
                entries=[],  # Empty = heartbeat
                prev_log_index=len(self.log) - 1,
                prev_log_term=self.log[-1].term if self.log else 0,
                leader_commit=self.commit_index
            )
```

---

## Data Replication

```
REPLICATION STRATEGIES:

1. SINGLE-LEADER (Primary-Replica):
   ┌──────────┐       ┌──────────┐
   │  Leader  │──────►│ Follower │  All writes go through leader
   │ (Primary)│──────►│ Follower │  Reads from any node
   │  R/W     │       │  R only  │  
   └──────────┘       └──────────┘
   Used by: PostgreSQL, MySQL, MongoDB

2. MULTI-LEADER:
   ┌──────────┐◄─────►┌──────────┐  Multiple nodes accept writes
   │ Leader 1 │       │ Leader 2 │  Need conflict resolution
   │  R/W     │       │  R/W     │  Used in multi-datacenter setups
   └──────────┘       └──────────┘
   Used by: CouchDB, Cassandra

3. LEADERLESS:
   ┌──────────┐
   │  Node A  │  Client writes to multiple nodes
   │  R/W     │  Client reads from multiple nodes
   ├──────────┤  Use quorum: W + R > N
   │  Node B  │  
   │  R/W     │  W=2, R=2, N=3 → guaranteed overlap
   ├──────────┤
   │  Node C  │  
   │  R/W     │  
   └──────────┘  
   Used by: DynamoDB, Cassandra, Riak
```

```python
# Single-Leader Replication
class PrimaryReplicaCluster:
    """
    All writes go through primary.
    Reads can go to any replica for better performance.
    """
    def __init__(self):
        self.primary = DatabaseNode("primary", is_primary=True)
        self.replicas = [
            DatabaseNode("replica-1"),
            DatabaseNode("replica-2"),
            DatabaseNode("replica-3"),
        ]
        self.replication_mode = "async"  # or "sync" or "semi-sync"
    
    def write(self, key: str, value: any):
        """Write goes to primary, then replicates."""
        # Write to primary
        lsn = self.primary.write(key, value)  # Log Sequence Number
        
        if self.replication_mode == "sync":
            # Wait for ALL replicas to confirm (strongest, slowest)
            for replica in self.replicas:
                replica.apply_wal(self.primary.get_wal_from(lsn))
                
        elif self.replication_mode == "semi-sync":
            # Wait for at least ONE replica (balance of safety and speed)
            confirmed = 0
            for replica in self.replicas:
                try:
                    replica.apply_wal(self.primary.get_wal_from(lsn))
                    confirmed += 1
                    if confirmed >= 1:
                        break
                except ReplicationError:
                    continue
                    
        else:  # async
            # Return immediately, replicate in background (fastest, riskiest)
            for replica in self.replicas:
                threading.Thread(
                    target=replica.apply_wal,
                    args=(self.primary.get_wal_from(lsn),)
                ).start()
        
        return lsn
    
    def read(self, key: str, consistency: str = "eventual"):
        """Read with configurable consistency."""
        if consistency == "strong":
            # Always read from primary (guaranteed latest)
            return self.primary.read(key)
        
        elif consistency == "bounded_staleness":
            # Read from replica, but only if not too far behind
            best_replica = min(self.replicas, key=lambda r: r.replication_lag())
            if best_replica.replication_lag() < timedelta(seconds=5):
                return best_replica.read(key)
            return self.primary.read(key)
        
        else:  # eventual
            # Read from any replica (fastest, may be stale)
            replica = random.choice(self.replicas)
            return replica.read(key)


# Leaderless Replication with Quorum
class QuorumReplication:
    """
    No single leader. Client coordinates reads/writes across nodes.
    
    Quorum formula: W + R > N
    Where:
      N = total replicas
      W = write acknowledgments required
      R = read responses required
    
    This guarantees at least one node has the latest data in every read.
    
    Example with N=3:
      W=2, R=2 → balanced
      W=3, R=1 → fast reads, slow writes
      W=1, R=3 → fast writes, slow reads
    """
    def __init__(self, nodes: list, write_quorum: int, read_quorum: int):
        self.nodes = nodes
        self.n = len(nodes)
        self.w = write_quorum
        self.r = read_quorum
        
        assert self.w + self.r > self.n, "Quorum condition not met"
    
    def write(self, key: str, value: any) -> bool:
        """Write to W nodes."""
        timestamp = time.time()  # Version number for conflict resolution
        
        success_count = 0
        for node in self.nodes:
            try:
                node.write(key, value, timestamp)
                success_count += 1
            except NodeUnavailableError:
                continue
        
        if success_count >= self.w:
            return True  # Write quorum achieved
        
        raise WriteQuorumNotMetError(
            f"Only {success_count}/{self.w} nodes acknowledged"
        )
    
    def read(self, key: str) -> any:
        """Read from R nodes and return the latest value."""
        responses = []
        
        for node in self.nodes:
            try:
                value, timestamp = node.read(key)
                responses.append((value, timestamp, node))
            except NodeUnavailableError:
                continue
        
        if len(responses) < self.r:
            raise ReadQuorumNotMetError(
                f"Only {len(responses)}/{self.r} nodes responded"
            )
        
        # Return the value with the highest timestamp (latest write)
        latest = max(responses, key=lambda x: x[1])
        latest_value = latest[0]
        
        # Read repair: update stale nodes
        for value, timestamp, node in responses:
            if timestamp < latest[1]:
                # This node has stale data, update it
                threading.Thread(
                    target=node.write,
                    args=(key, latest_value, latest[1])
                ).start()
        
        return latest_value
```

---

## Eventual Consistency

```
EVENTUAL CONSISTENCY TIMELINE:

T=0ms    Write "X=5" to Node A
         Node A: X=5  ✓
         Node B: X=3  ✗ (stale)
         Node C: X=3  ✗ (stale)

T=50ms   Replication in progress...
         Node A: X=5  ✓
         Node B: X=5  ✓
         Node C: X=3  ✗ (still propagating)

T=100ms  All nodes converged
         Node A: X=5  ✓
         Node B: X=5  ✓
         Node C: X=5  ✓

"If no new updates are made, eventually all nodes
 will return the last updated value."

CONFLICT RESOLUTION STRATEGIES:

1. Last Write Wins (LWW):
   Node A receives: SET X=5 at T=100
   Node B receives: SET X=7 at T=101
   Conflict! → T=101 is later → X=7 wins

2. Version Vectors:
   Track causality to merge properly

3. CRDTs (Conflict-free Replicated Data Types):
   Data structures that can be merged without conflicts
```

```python
# Eventual Consistency with Conflict Resolution

class EventuallyConsistentStore:
    """
    Demonstrates eventual consistency with conflict resolution.
    """
    def __init__(self, node_id: str, peers: list):
        self.node_id = node_id
        self.peers = peers
        self.data = {}  # key → {value, vector_clock, timestamp}
        self.anti_entropy_interval = 5  # seconds
    
    def put(self, key: str, value: any):
        """Write locally, propagate eventually."""
        # Increment our vector clock
        vc = self.data.get(key, {}).get("vector_clock", {}).copy()
        vc[self.node_id] = vc.get(self.node_id, 0) + 1
        
        self.data[key] = {
            "value": value,
            "vector_clock": vc,
            "timestamp": time.time(),
            "node_id": self.node_id
        }
        
        # Async propagation to peers
        for peer in self.peers:
            threading.Thread(
                target=self._replicate_to_peer,
                args=(peer, key, self.data[key])
            ).start()
    
    def get(self, key: str) -> any:
        """Read local value (may be stale)."""
        entry = self.data.get(key)
        return entry["value"] if entry else None
    
    def receive_replication(self, key: str, remote_entry: dict):
        """Handle incoming replication from another node."""
        local_entry = self.data.get(key)
        
        if local_entry is None:
            # We don't have this key - accept remote value
            self.data[key] = remote_entry
            return
        
        # Compare vector clocks to detect conflicts
        relationship = self._compare_vector_clocks(
            local_entry["vector_clock"],
            remote_entry["vector_clock"]
        )
        
        if relationship == "remote_dominates":
            # Remote is strictly newer - accept it
            self.data[key] = remote_entry
            
        elif relationship == "local_dominates":
            # Local is strictly newer - keep ours
            pass
            
        elif relationship == "concurrent":
            # CONFLICT: concurrent writes detected
            resolved = self._resolve_conflict(key, local_entry, remote_entry)
            self.data[key] = resolved
    
    def _compare_vector_clocks(self, vc1: dict, vc2: dict) -> str:
        """
        Compare two vector clocks.
        
        Example:
          vc1 = {"A": 2, "B": 1}
          vc2 = {"A": 2, "B": 2}
          → "remote_dominates" (vc2 has everything vc1 has, plus more)
          
          vc1 = {"A": 2, "B": 1}
          vc2 = {"A": 1, "B": 2}
          → "concurrent" (neither dominates - conflict!)
        """
        all_nodes = set(list(vc1.keys()) + list(vc2.keys()))
        
        vc1_greater = False
        vc2_greater = False
        
        for node in all_nodes:
            v1 = vc1.get(node, 0)
            v2 = vc2.get(node, 0)
            
            if v1 > v2:
                vc1_greater = True
            elif v2 > v1:
                vc2_greater = True
        
        if vc1_greater and not vc2_greater:
            return "local_dominates"
        elif vc2_greater and not vc1_greater:
            return "remote_dominates"
        elif not vc1_greater and not vc2_greater:
            return "equal"
        else:
            return "concurrent"
    
    def _resolve_conflict(self, key: str, local: dict, remote: dict) -> dict:
        """
        Resolve concurrent write conflict.
        Strategy depends on business requirements.
        """
        # Strategy 1: Last Write Wins (simple, may lose data)
        if local["timestamp"] >= remote["timestamp"]:
            return local
        return remote
        
        # Strategy 2: Merge (application-specific)
        # For a shopping cart, merge items from both versions
        # merged_value = merge(local["value"], remote["value"])
        
        # Strategy 3: Keep both (let application decide)
        # return {"value": [local["value"], remote["value"]], "conflict": True}
    
    def _anti_entropy(self):
        """
        Periodic background process to sync nodes.
        Catches any updates missed by real-time replication.
        
        Techniques:
        1. Merkle Trees - efficiently find differences
        2. Gossip Protocol - randomly exchange state with peers
        """
        while True:
            time.sleep(self.anti_entropy_interval)
            
            # Pick a random peer (gossip)
            peer = random.choice(self.peers)
            
            # Exchange data summaries using Merkle tree
            my_hash = self._compute_merkle_root()
            peer_hash = peer.get_merkle_root()
            
            if my_hash != peer_hash:
                # Trees differ - find and sync different keys
                diff_keys = self._find_merkle_differences(peer)
                for key in diff_keys:
                    self._sync_key(peer, key)


# CRDT Example: Grow-Only Counter
class GCounter:
    """
    Conflict-free Replicated Data Type.
    Multiple nodes can increment independently.
    No conflicts possible - always converges.
    
    Each node maintains its own counter.
    Total = sum of all node counters.
    
    Node A: {A: 5, B: 0, C: 0} → total = 5
    Node B: {A: 0, B: 3, C: 0} → total = 3
    
    After merge:
    Both: {A: 5, B: 3, C: 0} → total = 8
    """
    def __init__(self, node_id: str):
        self.node_id = node_id
        self.counts: Dict[str, int] = {}
    
    def increment(self, amount: int = 1):
        """Increment this node's counter."""
        self.counts[self.node_id] = self.counts.get(self.node_id, 0) + amount
    
    def value(self) -> int:
        """Get total count across all nodes."""
        return sum(self.counts.values())
    
    def merge(self, other: 'GCounter'):
        """
        Merge with another counter.
        Take the MAX of each node's counter.
        This is always safe - no conflicts possible!
        """
        all_nodes = set(list(self.counts.keys()) + list(other.counts.keys()))
        for node in all_nodes:
            self.counts[node] = max(
                self.counts.get(node, 0),
                other.counts.get(node, 0)
            )
```

---

## Sharding Strategies

```
WHY SHARD?

Single database: 1 billion rows, all queries go to one machine
  → CPU bottleneck, memory bottleneck, disk I/O bottleneck

Sharded database: 1 billion rows split across 10 machines
  → Each machine handles ~100 million rows
  → Queries distributed across machines

SHARDING STRATEGIES:

1. HASH-BASED SHARDING:
   shard = hash(key) % num_shards
   
   Key: user_123 → hash = 7823 → shard = 7823 % 4 = 3
   Key: user_456 → hash = 2341 → shard = 2341 % 4 = 1
   
   ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐
   │ Shard 0 │ │ Shard 1 │ │ Shard 2 │ │ Shard 3 │
   │         │ │user_456 │ │         │ │user_123 │
   └─────────┘ └─────────┘ └─────────┘ └─────────┘
   
   ✓ Even distribution
   ✗ Range queries are hard (scattered across shards)
   ✗ Adding shards requires reshuffling data

2. RANGE-BASED SHARDING:
   A-F → Shard 0, G-L → Shard 1, M-R → Shard 2, S-Z → Shard 3
   
   ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐
   │ Shard 0 │ │ Shard 1 │ │ Shard 2 │ │ Shard 3 │
   │  A - F  │ │  G - L  │ │  M - R  │ │  S - Z  │
   │  Alice  │ │  Grace  │ │  Mike   │ │  Steve  │
   │  Bob    │ │  John   │ │  Nancy  │ │  Tom    │
   └─────────┘ └─────────┘ └─────────┘ └─────────┘
   
   ✓ Range queries are efficient
   ✗ Hotspots (e.g., more people with names starting with S)

3. CONSISTENT HASHING:
   Nodes arranged on a virtual ring
   
        Node A
       ╱      ╲
     ╱          ╲
   Node D      Node B       Keys are assigned to the next node
     ╲          ╱            clockwise on the ring
      ╲       ╱
       Node C

   ✓ Adding/removing nodes only affects neighboring data
   ✓ Minimal data movement when scaling
```

```python
import hashlib
from bisect import bisect_right
from typing import Dict, List, Optional

# === Hash-Based Sharding ===
class HashShardRouter:
    """Simple hash-based sharding."""
    def __init__(self, shard_count: int):
        self.shard_count = shard_count
        self.shards = {i: Database(f"shard-{i}") for i in range(shard_count)}
    
    def get_shard(self, key: str) -> int:
        """Determine which shard a key belongs to."""
        hash_value = int(hashlib.md5(key.encode()).hexdigest(), 16)
        return hash_value % self.shard_count
    
    def write(self, key: str, value: any):
        shard_id = self.get_shard(key)
        self.shards[shard_id].write(key, value)
    
    def read(self, key: str) -> any:
        shard_id = self.get_shard(key)
        return self.shards[shard_id].read(key)
    
    def query_all_shards(self, query: str) -> list:
        """
        Scatter-gather: query all shards and combine results.
        Needed for queries that don't include the shard key.
        """
        results = []
        for shard in self.shards.values():
            results.extend(shard.query(query))
        return results


# === Consistent Hashing ===
class ConsistentHashRing:
    """
    Consistent hashing distributes keys across nodes on a virtual ring.
    When nodes are added/removed, only ~1/N of keys need to move.
    
    Virtual nodes (vnodes) ensure even distribution.
    """
    def __init__(self, nodes: List[str] = None, virtual_nodes: int = 150):
        self.virtual_nodes = virtual_nodes
        self.ring: Dict[int, str] = {}  # hash → node
        self.sorted_keys: List[int] = []
        
        if nodes:
            for node in nodes:
                self.add_node(node)
    
    def _hash(self, key: str) -> int:
        """Generate consistent hash for a key."""
        return int(hashlib.sha256(key.encode()).hexdigest(), 16)
    
    def add_node(self, node: str):
        """
        Add a node to the ring with virtual nodes for better distribution.
        
        Without virtual nodes: 3 nodes might get 10%, 60%, 30% of data
        With 150 virtual nodes each: distribution approaches 33%, 33%, 34%
        """
        for i in range(self.virtual_nodes):
            virtual_key = f"{node}:vnode{i}"
            hash_value = self._hash(virtual_key)
            self.ring[hash_value] = node
            self.sorted_keys.append(hash_value)
        
        self.sorted_keys.sort()
    
    def remove_node(self, node: str):
        """
        Remove a node. Only keys assigned to this node need to move
        to the next node on the ring.
        """
        for i in range(self.virtual_nodes):
            virtual_key = f"{node}:vnode{i}"
            hash_value = self._hash(virtual_key)
            if hash_value in self.ring:
                del self.ring[hash_value]
                self.sorted_keys.remove(hash_value)
    
    def get_node(self, key: str) -> str:
        """
        Find which node a key should be stored on.
        Walk clockwise on the ring from the key's hash position.
        """
        if not self.ring:
            raise Exception("No nodes in ring")
        
        hash_value = self._hash(key)
        
        # Find the first node clockwise from this hash
        idx = bisect_right(self.sorted_keys, hash_value)
        
        # Wrap around to the beginning of the ring
        if idx >= len(self.sorted_keys):
            idx = 0
        
        return self.ring[self.sorted_keys[idx]]
    
    def get_nodes(self, key: str, count: int = 3) -> List[str]:
        """
        Get N distinct nodes for a key (for replication).
        Walk clockwise and pick different physical nodes.
        """
        if not self.ring:
            raise Exception("No nodes in ring")
        
        hash_value = self._hash(key)
        idx = bisect_right(self.sorted_keys, hash_value)
        
        nodes = []
        seen = set()
        
        for i in range(len(self.sorted_keys)):
            actual_idx = (idx + i) % len(self.sorted_keys)
            node = self.ring[self.sorted_keys[actual_idx]]
            
            if node not in seen:
                nodes.append(node)
                seen.add(node)
            
            if len(nodes) == count:
                break
        
        return nodes


# === Practical Sharding Example: User Database ===
class ShardedUserDatabase:
    """
    Real-world sharding example for a user database.
    """
    def __init__(self):
        self.ring = ConsistentHashRing(
            nodes=["db-node-1", "db-node-2", "db-node-3", "db-node-4"],
            virtual_nodes=150
        )
        self.connections = {
            "db-node-1": DatabasePool("postgres://db1:5432/users"),
            "db-node-2": DatabasePool("postgres://db2:5432/users"),
            "db-node-3": DatabasePool("postgres://db3:5432/users"),
            "db-node-4": DatabasePool("postgres://db4:5432/users"),
        }
    
    def create_user(self, user_id: str, data: dict):
        """Write user to the appropriate shard."""
        node = self.ring.get_node(user_id)
        db = self.connections[node]
        db.execute(
            "INSERT INTO users (id, name, email) VALUES (%s, %s, %s)",
            user_id, data["name"], data["email"]
        )
    
    def get_user(self, user_id: str) -> dict:
        """Read user from the correct shard."""
        node = self.ring.get_node(user_id)
        db = self.connections[node]
        return db.query("SELECT * FROM users WHERE id = %s", user_id)
    
    def search_users(self, query: str) -> list:
        """
        Search requires scatter-gather across ALL shards.
        This is why sharding key choice is critical!
        """
        results = []
        for node, db in self.connections.items():
            shard_results = db.query(
                "SELECT * FROM users WHERE name ILIKE %s", f"%{query}%"
            )
            results.extend(shard_results)
        
        return results
    
    def add_shard(self, node_name: str, connection_string: str):
        """
        Add a new shard. With consistent hashing, only ~25% of data
        needs to move (with 4 existing nodes → adding 5th node).
        """
        # Add node to ring
        self.ring.add_node(node_name)
        self.connections[node_name] = DatabasePool(connection_string)
        
        # Migrate data that now belongs to the new node
        self._rebalance_data(node_name)
    
    def _rebalance_data(self, new_node: str):
        """Move data to new shard that now belongs there."""
        for old_node, db in self.connections.items():
            if old_node == new_node:
                continue
            
            # Check each key in old node
            for row in db.query("SELECT id FROM users"):
                current_owner = self.ring.get_node(row["id"])
                
                if current_owner == new_node:
                    # This key should now be on the new node
                    full_data = db.query(
                        "SELECT * FROM users WHERE id = %s", row["id"]
                    )
                    new_db = self.connections[new_node]
                    new_db.execute("INSERT INTO users ...", full_data)
                    db.execute("DELETE FROM users WHERE id = %s", row["id"])
```

---

## Circuit Breaker Pattern

```
THE PROBLEM:

Service A calls Service B which is DOWN:
  Service A → Service B (timeout 30s)  ← Waits 30s, fails
  Service A → Service B (timeout 30s)  ← Waits 30s, fails
  Service A → Service B (timeout 30s)  ← Waits 30s, fails
  
  Meanwhile: Service A's threads are exhausted waiting for B
  Result: Service A also goes down! (Cascading failure)

THE SOLUTION: Circuit Breaker

Like an electrical circuit breaker - cuts the circuit when there's a problem.

States:
┌────────┐   Failure threshold    ┌────────┐   Timeout expires   ┌───────────┐
│ CLOSED │ ─────exceeded────────► │  OPEN  │ ──────────────────► │ HALF-OPEN │
│        │                        │        │                      │           │
│ Normal │                        │ Fail   │                      │ Test with │
│ traffic│  ◄──success──────────  │ fast   │  ◄──failure────────  │ limited   │
│ flows  │                        │ (don't │                      │ requests  │
│        │                        │  call  │                      │           │
└────────┘                        │backend)│                      └───────────┘
                                  └────────┘

CLOSED:   Normal operation, calls pass through
OPEN:     All calls fail immediately (fast failure, no waiting)
HALF-OPEN: Allow a few test calls to see if service recovered
```

```python
import time
import threading
from enum import Enum
from typing import Callable, Any, Optional
from collections import deque

class CircuitState(Enum):
    CLOSED = "CLOSED"
    OPEN = "OPEN"
    HALF_OPEN = "HALF_OPEN"

class CircuitBreaker:
    """
    Production-grade circuit breaker implementation.
    Prevents cascading failures by failing fast when a service is down.
    """
    def __init__(
        self,
        name: str,
        failure_threshold: int = 5,      # Failures before opening
        success_threshold: int = 3,       # Successes to close from half-open
        timeout: float = 30.0,            # Seconds before trying again
        failure_rate_threshold: float = 0.5,  # 50% failure rate
        monitoring_window: int = 10,      # Window size for rate calculation
        excluded_exceptions: tuple = ()   # Exceptions that don't count as failures
    ):
        self.name = name
        self.failure_threshold = failure_threshold
        self.success_threshold = success_threshold
        self.timeout = timeout
        self.failure_rate_threshold = failure_rate_threshold
        self.monitoring_window = monitoring_window
        self.excluded_exceptions = excluded_exceptions
        
        # State
        self.state = CircuitState.CLOSED
        self.failure_count = 0
        self.success_count = 0
        self.last_failure_time = None
        self.last_state_change = time.time()
        
        # Monitoring window (sliding window of results)
        self.results = deque(maxlen=monitoring_window)
        
        # Thread safety
        self.lock = threading.RLock()
        
        # Metrics
        self.metrics = {
            "total_calls": 0,
            "total_successes": 0,
            "total_failures": 0,
            "total_rejected": 0,
            "state_changes": []
        }
    
    def call(self, func: Callable, *args, fallback: Callable = None, 
             **kwargs) -> Any:
        """
        Execute function through the circuit breaker.
        """
        self.metrics["total_calls"] += 1
        
        with self.lock:
            if self.state == CircuitState.OPEN:
                if self._should_attempt_reset():
                    self._transition_to(CircuitState.HALF_OPEN)
                else:
                    self.metrics["total_rejected"] += 1
                    if fallback:
                        return fallback(*args, **kwargs)
                    raise CircuitOpenError(
                        f"Circuit '{self.name}' is OPEN. "
                        f"Will retry in "
                        f"{self.timeout - (time.time() - self.last_failure_time):.1f}s"
                    )
            
            if self.state == CircuitState.HALF_OPEN:
                # Allow limited requests through
                pass
        
        # Execute the actual call
        try:
            result = func(*args, **kwargs)
            self._on_success()
            return result
            
        except self.excluded_exceptions:
            # These exceptions don't count as circuit failures
            # e.g., validation errors (4xx) vs server errors (5xx)
            raise
            
        except Exception as e:
            self._on_failure(e)
            
            if fallback:
                return fallback(*args, **kwargs)
            raise
    
    def _on_success(self):
        """Record a successful call."""
        with self.lock:
            self.metrics["total_successes"] += 1
            self.results.append(True)
            
            if self.state == CircuitState.HALF_OPEN:
                self.success_count += 1
                if self.success_count >= self.success_threshold:
                    self._transition_to(CircuitState.CLOSED)
            
            elif self.state == CircuitState.CLOSED:
                self.failure_count = 0
    
    def _on_failure(self, error: Exception):
        """Record a failed call."""
        with self.lock:
            self.metrics["total_failures"] += 1
            self.results.append(False)
            self.last_failure_time = time.time()
            
            if self.state == CircuitState.HALF_OPEN:
                # Any failure in half-open → back to open
                self._transition_to(CircuitState.OPEN)
            
            elif self.state == CircuitState.CLOSED:
                self.failure_count += 1
                
                # Check failure rate
                if len(self.results) >= self.monitoring_window:
                    failure_rate = self.results.count(False) / len(self.results)
                    if failure_rate >= self.failure_rate_threshold:
                        self._transition_to(CircuitState.OPEN)
                
                # Or absolute threshold
                elif self.failure_count >= self.failure_threshold:
                    self._transition_to(CircuitState.OPEN)
    
    def _should_attempt_reset(self) -> bool:
        """Check if enough time has passed to try again."""
        return (time.time() - self.last_failure_time) >= self.timeout
    
    def _transition_to(self, new_state: CircuitState):
        """Change circuit state."""
        old_state = self.state
        self.state = new_state
        self.last_state_change = time.time()
        
        if new_state == CircuitState.CLOSED:
            self.failure_count = 0
            self.success_count = 0
            self.results.clear()
        elif new_state == CircuitState.HALF_OPEN:
            self.success_count = 0
        
        self.metrics["state_changes"].append({
            "from": old_state.value,
            "to": new_state.value,
            "at": time.time()
        })
        
        print(f"[CircuitBreaker:{self.name}] "
              f"{old_state.value} → {new_state.value}")


# === Usage in a real service ===
class OrderService:
    def __init__(self):
        # Circuit breaker for each external dependency
        self.payment_circuit = CircuitBreaker(
            name="payment-service",
            failure_threshold=5,
            success_threshold=3,
            timeout=30,
            excluded_exceptions=(ValidationError,)  # 4xx don't trip breaker
        )
        
        self.inventory_circuit = CircuitBreaker(
            name="inventory-service",
            failure_threshold=3,       # More sensitive - inventory is critical
            timeout=15                 # Try again sooner
        )
    
    def process_order(self, order: dict):
        """
        Process order with circuit breakers protecting external calls.
        """
        # Check inventory with circuit breaker
        try:
            available = self.inventory_circuit.call(
                self._check_inventory,
                order["product_id"],
                order["quantity"],
                fallback=self._check_inventory_cache  # Use cache if service down
            )
        except CircuitOpenError:
            # Circuit is open - we know service is down
            # Fast fail instead of waiting for timeout
            available = self._check_inventory_cache(
                order["product_id"], order["quantity"]
            )
        
        if not available:
            raise OutOfStockError()
        
        # Process payment with circuit breaker
        try:
            payment = self.payment_circuit.call(
                self._charge_customer,
                order["user_id"],
                order["total"],
                fallback=self._queue_payment  # Queue for later if service down
            )
        except CircuitOpenError:
            # Payment service is down - queue for later processing
            payment = self._queue_payment(order["user_id"], order["total"])
        
        return {"status": "accepted", "payment": payment}
    
    def _check_inventory(self, product_id, quantity):
        """Call inventory service."""
        response = http_client.get(
            f"http://inventory-service/check/{product_id}",
            params={"quantity": quantity},
            timeout=5
        )
        return response.json()["available"]
    
    def _check_inventory_cache(self, product_id, quantity):
        """Fallback: check cached inventory."""
        cached = redis.get(f"inventory:{product_id}")
        if cached:
            return int(cached) >= quantity
        return True  # Optimistic: assume available, verify later
    
    def _charge_customer(self, user_id, amount):
        """Call payment service."""
        return http_client.post(
            "http://payment-service/charge",
            json={"user_id": user_id, "amount": amount},
            timeout=10
        ).json()
    
    def _queue_payment(self, user_id, amount):
        """Fallback: queue payment for later processing."""
        sqs.send_message(
            QueueUrl=PAYMENT_QUEUE_URL,
            MessageBody=json.dumps({
                "user_id": user_id,
                "amount": amount,
                "queued_at": datetime.utcnow().isoformat()
            })
        )
        return {"status": "queued", "message": "Payment will be processed shortly"}
```

---

## Quick Reference: When to Use What

```
┌────────────────────────────┬──────────────────────────────────────┐
│ SCENARIO                   │ SOLUTION                              │
├────────────────────────────┼──────────────────────────────────────┤
│ Prevent double processing  │ Idempotency keys                     │
│ Prevent double booking     │ Distributed locks                    │
│ One coordinator needed     │ Leader election                      │
│ All nodes must agree       │ Consensus (Raft/Paxos)               │
│ Service keeps failing      │ Circuit breaker                      │
│ Database too big           │ Sharding                             │
│ Read scalability           │ Read replicas                        │
│ Decouple services          │ Event-driven + message queue         │
│ High throughput events     │ Kafka                                │
│ Task queue (work dispatch) │ RabbitMQ / SQS                       │
│ Real-time notifications    │ Pub/Sub (Redis, SNS)                 │
│ Services finding each other│ Service discovery (Consul, K8s)      │
│ Single entry point         │ API Gateway                          │
│ Multi-region availability  │ Multi-leader replication + AP system │
│ Financial transactions     │ CP system + strong consistency       │
│ Social media feeds         │ AP system + eventual consistency     │
│ Need message replay        │ Event streaming (Kafka)              │
│ Cascading failure prevent  │ Bulkhead + Circuit breaker + Timeout │
└────────────────────────────┴──────────────────────────────────────┘
```