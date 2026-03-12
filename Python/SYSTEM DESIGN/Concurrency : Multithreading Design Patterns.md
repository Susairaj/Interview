Concurrency / Multithreading Design Patterns

---

## 23. Thread-Safe Cache

### Core Problem
Multiple threads reading/writing a cache simultaneously can cause **race conditions**, **stale reads**, and **corrupted data**.

### Architecture

```
┌─────────────────────────────────────────────────────────┐
│                   Thread-Safe Cache                      │
│                                                          │
│  ┌──────────┐   ┌──────────────────────────────────┐    │
│  │ Thread 1 │──▶│                                  │    │
│  └──────────┘   │   ┌─────────┐   ┌───────────┐   │    │
│  ┌──────────┐   │   │  R/W    │   │  Hash Map │   │    │
│  │ Thread 2 │──▶│   │  Lock   │──▶│  + DLL    │   │    │
│  └──────────┘   │   │(or fine  │   │  (LRU)    │   │    │
│  ┌──────────┐   │   │ grained) │   │           │   │    │
│  │ Thread 3 │──▶│   └─────────┘   └───────────┘   │    │
│  └──────────┘   │        Cache Engine              │    │
│                 └──────────────────────────────────┘    │
│                                                          │
│  Eviction: LRU / TTL / LFU                              │
│  Locking:  RWLock / Striped / Lock-Free                 │
└─────────────────────────────────────────────────────────┘
```

### Locking Strategies Compared

```
Strategy          Read Perf    Write Perf   Complexity
─────────────────────────────────────────────────────
Global Mutex      Low          Low          Simple
ReadWrite Lock    High         Medium       Medium
Striped Locks     High         High         Complex
Lock-Free (CAS)   Highest      Highest      Very Complex
```

### Full Implementation

```python
import threading
import time
from collections import OrderedDict
from typing import Any, Optional, Hashable
from dataclasses import dataclass, field


# ─────────────────────────────────────────────
# 1. Basic LRU Cache with RWLock
# ─────────────────────────────────────────────

class ReadWriteLock:
    """
    Multiple readers can hold the lock simultaneously,
    but writers get exclusive access.
    
    Prevents writer starvation with a writer-preference flag.
    """

    def __init__(self):
        self._read_ready = threading.Condition(threading.Lock())
        self._readers = 0
        self._writers_waiting = 0
        self._writer_active = False

    def acquire_read(self):
        with self._read_ready:
            # Wait if a writer is active or writers are waiting (prevent starvation)
            while self._writer_active or self._writers_waiting > 0:
                self._read_ready.wait()
            self._readers += 1

    def release_read(self):
        with self._read_ready:
            self._readers -= 1
            if self._readers == 0:
                self._read_ready.notify_all()

    def acquire_write(self):
        with self._read_ready:
            self._writers_waiting += 1
            while self._readers > 0 or self._writer_active:
                self._read_ready.wait()
            self._writers_waiting -= 1
            self._writer_active = True

    def release_write(self):
        with self._read_ready:
            self._writer_active = False
            self._read_ready.notify_all()


@dataclass
class CacheEntry:
    value: Any
    created_at: float = field(default_factory=time.time)
    ttl: Optional[float] = None  # seconds

    @property
    def is_expired(self) -> bool:
        if self.ttl is None:
            return False
        return (time.time() - self.created_at) > self.ttl


class ThreadSafeLRUCache:
    """
    Thread-safe LRU cache with:
    - Read/Write lock for high read concurrency
    - TTL-based expiration
    - Max capacity with LRU eviction
    - Hit/miss statistics
    """

    def __init__(self, capacity: int = 1000, default_ttl: Optional[float] = None):
        self._capacity = capacity
        self._default_ttl = default_ttl
        self._cache: OrderedDict[Hashable, CacheEntry] = OrderedDict()
        self._lock = ReadWriteLock()

        # Stats
        self._hits = 0
        self._misses = 0
        self._evictions = 0
        self._stats_lock = threading.Lock()

    def get(self, key: Hashable) -> Optional[Any]:
        """Retrieve value; returns None on miss or expiry."""
        self._lock.acquire_read()
        try:
            if key not in self._cache:
                self._record_miss()
                return None

            entry = self._cache[key]

            if entry.is_expired:
                # Need write access to delete — release read, acquire write
                self._lock.release_read()
                self._delete_expired(key)
                self._record_miss()
                return None

            self._record_hit()
            # Move to end requires mutation — but OrderedDict.move_to_end
            # is a write operation. We promote lazily under write lock.
            return entry.value
        finally:
            try:
                self._lock.release_read()
            except RuntimeError:
                pass  # Already released above in expiry path

    def put(self, key: Hashable, value: Any, ttl: Optional[float] = None) -> None:
        """Insert or update a key-value pair."""
        effective_ttl = ttl if ttl is not None else self._default_ttl

        self._lock.acquire_write()
        try:
            if key in self._cache:
                # Update existing: move to end (most recently used)
                self._cache.move_to_end(key)
                self._cache[key] = CacheEntry(value=value, ttl=effective_ttl)
            else:
                # Evict if at capacity
                while len(self._cache) >= self._capacity:
                    evicted_key, _ = self._cache.popitem(last=False)
                    self._evictions += 1

                self._cache[key] = CacheEntry(value=value, ttl=effective_ttl)
        finally:
            self._lock.release_write()

    def delete(self, key: Hashable) -> bool:
        self._lock.acquire_write()
        try:
            if key in self._cache:
                del self._cache[key]
                return True
            return False
        finally:
            self._lock.release_write()

    def _delete_expired(self, key: Hashable):
        self._lock.acquire_write()
        try:
            if key in self._cache and self._cache[key].is_expired:
                del self._cache[key]
        finally:
            self._lock.release_write()

    def clear(self):
        self._lock.acquire_write()
        try:
            self._cache.clear()
        finally:
            self._lock.release_write()

    def _record_hit(self):
        with self._stats_lock:
            self._hits += 1

    def _record_miss(self):
        with self._stats_lock:
            self._misses += 1

    @property
    def stats(self) -> dict:
        with self._stats_lock:
            total = self._hits + self._misses
            return {
                "size": len(self._cache),
                "capacity": self._capacity,
                "hits": self._hits,
                "misses": self._misses,
                "hit_rate": self._hits / total if total > 0 else 0,
                "evictions": self._evictions,
            }

    def __len__(self):
        self._lock.acquire_read()
        try:
            return len(self._cache)
        finally:
            self._lock.release_read()


# ─────────────────────────────────────────────
# 2. Striped Lock Cache (higher write throughput)
# ─────────────────────────────────────────────

class StripedLockCache:
    """
    Divides keyspace into N shards, each with its own lock.
    Reduces contention for write-heavy workloads.
    
    ┌────────┬────────┬────────┬────────┐
    │ Shard0 │ Shard1 │ Shard2 │ Shard3 │
    │ Lock0  │ Lock1  │ Lock2  │ Lock3  │
    │ Dict0  │ Dict1  │ Dict2  │ Dict3  │
    └────────┴────────┴────────┴────────┘
    """

    def __init__(self, num_stripes: int = 16, capacity_per_stripe: int = 64):
        self._num_stripes = num_stripes
        self._capacity = capacity_per_stripe
        self._stripes = [OrderedDict() for _ in range(num_stripes)]
        self._locks = [threading.Lock() for _ in range(num_stripes)]

    def _get_stripe(self, key: Hashable) -> int:
        return hash(key) % self._num_stripes

    def get(self, key: Hashable) -> Optional[Any]:
        idx = self._get_stripe(key)
        with self._locks[idx]:
            if key in self._stripes[idx]:
                self._stripes[idx].move_to_end(key)
                entry = self._stripes[idx][key]
                if isinstance(entry, CacheEntry) and entry.is_expired:
                    del self._stripes[idx][key]
                    return None
                return entry.value if isinstance(entry, CacheEntry) else entry
            return None

    def put(self, key: Hashable, value: Any, ttl: Optional[float] = None):
        idx = self._get_stripe(key)
        with self._locks[idx]:
            stripe = self._stripes[idx]
            if key in stripe:
                stripe.move_to_end(key)
            else:
                while len(stripe) >= self._capacity:
                    stripe.popitem(last=False)
            stripe[key] = CacheEntry(value=value, ttl=ttl)


# ─────────────────────────────────────────────
# 3. Background TTL Cleanup Daemon
# ─────────────────────────────────────────────

class TTLCleanupDaemon(threading.Thread):
    """Periodically scans and removes expired entries."""

    def __init__(self, cache: ThreadSafeLRUCache, interval: float = 5.0):
        super().__init__(daemon=True)
        self._cache = cache
        self._interval = interval
        self._stop_event = threading.Event()

    def run(self):
        while not self._stop_event.is_set():
            self._cleanup()
            self._stop_event.wait(timeout=self._interval)

    def _cleanup(self):
        self._cache._lock.acquire_write()
        try:
            expired_keys = [
                k for k, v in self._cache._cache.items() if v.is_expired
            ]
            for k in expired_keys:
                del self._cache._cache[k]
        finally:
            self._cache._lock.release_write()

    def stop(self):
        self._stop_event.set()


# ─────────────────────────────────────────────
# Demo
# ─────────────────────────────────────────────

def demo_thread_safe_cache():
    cache = ThreadSafeLRUCache(capacity=5, default_ttl=2.0)
    cleaner = TTLCleanupDaemon(cache, interval=1.0)
    cleaner.start()

    errors = []

    def writer(thread_id):
        for i in range(20):
            cache.put(f"key-{thread_id}-{i}", f"value-{i}")
            time.sleep(0.01)

    def reader(thread_id):
        for i in range(20):
            _ = cache.get(f"key-{thread_id}-{i}")
            time.sleep(0.005)

    threads = []
    for t in range(4):
        threads.append(threading.Thread(target=writer, args=(t,)))
        threads.append(threading.Thread(target=reader, args=(t,)))

    for t in threads:
        t.start()
    for t in threads:
        t.join()

    print("Cache stats:", cache.stats)
    cleaner.stop()


if __name__ == "__main__":
    demo_thread_safe_cache()
```

---

## 24. Producer-Consumer System

### Core Problem
Decouple **data production** from **data consumption** using a bounded buffer, handling back-pressure and graceful shutdown.

### Architecture

```
                        BOUNDED BUFFER
  Producers             (thread-safe)            Consumers
 ┌──────────┐        ┌───────────────┐        ┌──────────┐
 │Producer 1│──put──▶│ ■ ■ ■ □ □ □   │──get──▶│Consumer 1│
 └──────────┘        │               │        └──────────┘
 ┌──────────┐        │  Semaphores:  │        ┌──────────┐
 │Producer 2│──put──▶│  empty_slots  │──get──▶│Consumer 2│
 └──────────┘        │  filled_slots │        └──────────┘
 ┌──────────┐        │  mutex        │        ┌──────────┐
 │Producer 3│──put──▶│               │──get──▶│Consumer 3│
 └──────────┘        └───────────────┘        └──────────┘

 BACK-PRESSURE: producers block when buffer full
 STARVATION:    consumers block when buffer empty
 SHUTDOWN:      poison pill / event signal
```

### Implementation

```python
import threading
import queue
import time
import random
import logging
from dataclasses import dataclass, field
from typing import Any, Callable, Optional, List
from enum import Enum, auto

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(threadName)s] %(message)s")
logger = logging.getLogger(__name__)


# ─────────────────────────────────────────────
# 1. Core: Bounded Buffer with Semaphores
#    (Manual implementation to show internals)
# ─────────────────────────────────────────────

class BoundedBuffer:
    """
    Classic bounded buffer using counting semaphores.
    
    Two semaphores ensure:
      - Producers block when buffer is FULL  (empty_slots = 0)
      - Consumers block when buffer is EMPTY (filled_slots = 0)
    A mutex protects the actual buffer from concurrent access.
    """

    def __init__(self, capacity: int):
        self._buffer = []
        self._capacity = capacity
        self._mutex = threading.Lock()
        self._empty_slots = threading.Semaphore(capacity)   # starts at capacity
        self._filled_slots = threading.Semaphore(0)         # starts at 0

    def put(self, item: Any, timeout: Optional[float] = None) -> bool:
        # Block if no empty slots (buffer full → back-pressure)
        acquired = self._empty_slots.acquire(timeout=timeout)
        if not acquired:
            return False  # Timed out

        with self._mutex:
            self._buffer.append(item)

        self._filled_slots.release()  # Signal one more filled slot
        return True

    def get(self, timeout: Optional[float] = None) -> Optional[Any]:
        # Block if no filled slots (buffer empty → wait)
        acquired = self._filled_slots.acquire(timeout=timeout)
        if not acquired:
            return None  # Timed out

        with self._mutex:
            item = self._buffer.pop(0)

        self._empty_slots.release()  # Signal one more empty slot
        return item

    @property
    def size(self):
        with self._mutex:
            return len(self._buffer)


# ─────────────────────────────────────────────
# 2. Task / Message Types
# ─────────────────────────────────────────────

class Priority(Enum):
    LOW = 0
    MEDIUM = 1
    HIGH = 2
    CRITICAL = 3

@dataclass(order=True)
class Task:
    priority: int = field(compare=True)       # Higher = more urgent
    task_id: str = field(compare=False)
    payload: Any = field(compare=False)
    created_at: float = field(default_factory=time.time, compare=False)

_POISON_PILL = Task(priority=-1, task_id="__POISON__", payload=None)


# ─────────────────────────────────────────────
# 3. Full Producer-Consumer System
# ─────────────────────────────────────────────

class ProducerConsumerSystem:
    """
    Complete system with:
    - Multiple producers & consumers
    - Priority queue option
    - Back-pressure monitoring
    - Graceful shutdown (poison pills)
    - Error handling with DLQ
    - Metrics
    """

    def __init__(
        self,
        buffer_size: int = 100,
        num_producers: int = 3,
        num_consumers: int = 2,
        use_priority: bool = False,
    ):
        if use_priority:
            # PriorityQueue: highest-priority (numerically smallest) first
            # We negate priority so CRITICAL (3) → -3, comes out first
            self._queue = queue.PriorityQueue(maxsize=buffer_size)
        else:
            self._queue = queue.Queue(maxsize=buffer_size)

        self._dlq: queue.Queue = queue.Queue()     # Dead-letter queue
        self._num_producers = num_producers
        self._num_consumers = num_consumers
        self._use_priority = use_priority
        self._shutdown_event = threading.Event()

        # Metrics
        self._produced = 0
        self._consumed = 0
        self._errors = 0
        self._metrics_lock = threading.Lock()

        self._producers: List[threading.Thread] = []
        self._consumers: List[threading.Thread] = []

    # ── Producer ──────────────────────────────

    def _producer_loop(
        self,
        producer_id: int,
        produce_fn: Callable[[], Optional[Task]],
        rate_limit: float = 0.1,
    ):
        """Each producer calls produce_fn to generate tasks."""
        while not self._shutdown_event.is_set():
            try:
                task = produce_fn()
                if task is None:
                    continue

                if self._use_priority:
                    # Negate priority for min-heap behavior
                    item = (-task.priority, task)
                else:
                    item = task

                # put() blocks if queue is full → BACK-PRESSURE
                self._queue.put(item, timeout=1.0)

                with self._metrics_lock:
                    self._produced += 1

                logger.info(f"Producer-{producer_id} produced: {task.task_id}")

            except queue.Full:
                logger.warning(f"Producer-{producer_id}: buffer full, backing off")
                time.sleep(0.5)
            except Exception as e:
                logger.error(f"Producer-{producer_id} error: {e}")

            time.sleep(rate_limit)

        logger.info(f"Producer-{producer_id} shutting down")

    # ── Consumer ──────────────────────────────

    def _consumer_loop(
        self,
        consumer_id: int,
        consume_fn: Callable[[Task], None],
        max_retries: int = 3,
    ):
        """Each consumer processes tasks via consume_fn."""
        while True:
            try:
                item = self._queue.get(timeout=1.0)
            except queue.Empty:
                if self._shutdown_event.is_set() and self._queue.empty():
                    break
                continue

            # Unwrap priority wrapper
            task = item[1] if self._use_priority else item

            # Check for poison pill
            if task.task_id == "__POISON__":
                logger.info(f"Consumer-{consumer_id} received poison pill")
                self._queue.task_done()
                break

            # Process with retry
            success = False
            for attempt in range(1, max_retries + 1):
                try:
                    consume_fn(task)
                    success = True
                    break
                except Exception as e:
                    logger.warning(
                        f"Consumer-{consumer_id} attempt {attempt}/{max_retries} "
                        f"failed for {task.task_id}: {e}"
                    )
                    time.sleep(0.1 * attempt)  # Exponential-ish backoff

            if success:
                with self._metrics_lock:
                    self._consumed += 1
                logger.info(f"Consumer-{consumer_id} processed: {task.task_id}")
            else:
                # Send to Dead-Letter Queue
                self._dlq.put(task)
                with self._metrics_lock:
                    self._errors += 1
                logger.error(f"Consumer-{consumer_id}: {task.task_id} → DLQ")

            self._queue.task_done()

        logger.info(f"Consumer-{consumer_id} shutting down")

    # ── Lifecycle ─────────────────────────────

    def start(
        self,
        produce_fn: Callable[[], Optional[Task]],
        consume_fn: Callable[[Task], None],
    ):
        # Start consumers first (they'll block waiting for items)
        for i in range(self._num_consumers):
            t = threading.Thread(
                target=self._consumer_loop,
                args=(i, consume_fn),
                name=f"Consumer-{i}",
            )
            t.start()
            self._consumers.append(t)

        # Start producers
        for i in range(self._num_producers):
            t = threading.Thread(
                target=self._producer_loop,
                args=(i, produce_fn),
                name=f"Producer-{i}",
            )
            t.start()
            self._producers.append(t)

    def shutdown(self, wait: bool = True):
        """Graceful shutdown: stop producers, drain queue, stop consumers."""
        logger.info("Initiating shutdown...")

        # 1. Signal producers to stop
        self._shutdown_event.set()
        for t in self._producers:
            t.join()
        logger.info("All producers stopped")

        # 2. Send poison pills (one per consumer)
        for _ in self._consumers:
            pill = (-_POISON_PILL.priority, _POISON_PILL) if self._use_priority else _POISON_PILL
            self._queue.put(pill)

        # 3. Wait for consumers
        if wait:
            for t in self._consumers:
                t.join()
        logger.info("All consumers stopped")

    @property
    def metrics(self):
        with self._metrics_lock:
            return {
                "produced": self._produced,
                "consumed": self._consumed,
                "errors": self._errors,
                "dlq_size": self._dlq.qsize(),
                "buffer_size": self._queue.qsize(),
            }


# ─────────────────────────────────────────────
# Demo
# ─────────────────────────────────────────────

def demo_producer_consumer():
    counter = {"n": 0}
    counter_lock = threading.Lock()

    def produce() -> Optional[Task]:
        with counter_lock:
            counter["n"] += 1
            n = counter["n"]
        if n > 30:
            return None
        return Task(
            priority=random.choice([p.value for p in Priority]),
            task_id=f"task-{n}",
            payload={"data": random.randint(1, 100)},
        )

    def consume(task: Task):
        # Simulate work; occasionally fail
        if random.random() < 0.1:
            raise ValueError("Random processing error")
        time.sleep(random.uniform(0.05, 0.2))

    system = ProducerConsumerSystem(
        buffer_size=10,
        num_producers=3,
        num_consumers=2,
        use_priority=True,
    )
    system.start(produce_fn=produce, consume_fn=consume)
    time.sleep(5)
    system.shutdown()
    print("Final metrics:", system.metrics)


if __name__ == "__main__":
    demo_producer_consumer()
```

---

## 25. Async Task Queue

### Core Problem
Execute tasks **asynchronously** with support for scheduling, retries, result tracking, and worker pools — like a simplified **Celery**.

### Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│                      Async Task Queue                            │
│                                                                  │
│  Client                                                          │
│    │  submit(fn, args) → Future                                  │
│    ▼                                                             │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────────┐   │
│  │  Task        │    │  Scheduler   │    │  Worker Pool     │   │
│  │  Registry    │───▶│  (priority   │───▶│  ┌────────────┐  │   │
│  │              │    │   + delay    │    │  │  Worker 1   │  │   │
│  │  task_id →   │    │   queue)     │    │  │  Worker 2   │  │   │
│  │  TaskInfo    │    │              │    │  │  Worker 3   │  │   │
│  └──────────────┘    └──────────────┘    │  │  Worker 4   │  │   │
│         │                                │  └────────────┘  │   │
│         ▼                                └──────────────────┘   │
│  ┌──────────────┐                               │               │
│  │  Result      │◀──────────────────────────────┘               │
│  │  Store       │   callback / Future.result()                  │
│  └──────────────┘                                               │
│                                                                  │
│  Features: retries, delay, priority, cancel, callbacks, deps    │
└──────────────────────────────────────────────────────────────────┘
```

### Task State Machine

```
   PENDING ──▶ SCHEDULED ──▶ RUNNING ──▶ COMPLETED
                  │              │
                  │              ├──▶ FAILED ──▶ RETRY ──▶ SCHEDULED
                  │              │                            (back)
                  ▼              ▼
               CANCELLED      DEAD (max retries exceeded)
```

### Implementation

```python
import threading
import time
import uuid
import heapq
import traceback
import logging
from concurrent.futures import Future
from dataclasses import dataclass, field
from typing import Any, Callable, Optional, Dict, List
from enum import Enum, auto

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(threadName)s] %(message)s")
logger = logging.getLogger(__name__)


class TaskState(Enum):
    PENDING = auto()
    SCHEDULED = auto()
    RUNNING = auto()
    COMPLETED = auto()
    FAILED = auto()
    CANCELLED = auto()
    RETRYING = auto()


@dataclass
class TaskInfo:
    task_id: str
    func: Callable
    args: tuple
    kwargs: dict
    state: TaskState = TaskState.PENDING
    priority: int = 0             # Lower = higher priority
    delay: float = 0.0            # Seconds to delay execution
    max_retries: int = 3
    retry_count: int = 0
    retry_backoff: float = 1.0    # Exponential backoff base
    result: Any = None
    error: Optional[Exception] = None
    future: Future = field(default_factory=Future)
    created_at: float = field(default_factory=time.time)
    started_at: Optional[float] = None
    completed_at: Optional[float] = None
    callback: Optional[Callable] = None
    dependencies: List[str] = field(default_factory=list)


@dataclass(order=True)
class ScheduledTask:
    """Wrapper for priority queue ordering."""
    execute_at: float                                    # Primary sort key
    priority: int = field(compare=True)                  # Secondary
    task_id: str = field(compare=False)


class AsyncTaskQueue:
    """
    Full-featured async task queue with:
    - Thread pool workers
    - Priority scheduling
    - Delayed execution
    - Retry with exponential backoff
    - Task cancellation
    - Callbacks on completion
    - Dependency resolution
    - Result tracking via Futures
    """

    def __init__(self, num_workers: int = 4):
        self._num_workers = num_workers
        self._task_registry: Dict[str, TaskInfo] = {}
        self._schedule_queue: List[ScheduledTask] = []  # Min-heap
        self._queue_lock = threading.Lock()
        self._queue_not_empty = threading.Condition(self._queue_lock)
        self._registry_lock = threading.Lock()
        self._shutdown_event = threading.Event()
        self._workers: List[threading.Thread] = []

    # ── Public API ────────────────────────────

    def submit(
        self,
        func: Callable,
        *args,
        priority: int = 0,
        delay: float = 0.0,
        max_retries: int = 3,
        callback: Optional[Callable] = None,
        dependencies: Optional[List[str]] = None,
        **kwargs,
    ) -> str:
        """Submit a task. Returns task_id."""

        task_id = str(uuid.uuid4())[:8]
        task_info = TaskInfo(
            task_id=task_id,
            func=func,
            args=args,
            kwargs=kwargs,
            priority=priority,
            delay=delay,
            max_retries=max_retries,
            callback=callback,
            dependencies=dependencies or [],
        )

        with self._registry_lock:
            self._task_registry[task_id] = task_info

        # Schedule it
        execute_at = time.time() + delay
        self._enqueue(ScheduledTask(execute_at=execute_at, priority=priority, task_id=task_id))

        logger.info(f"Submitted task {task_id} (delay={delay}s, priority={priority})")
        return task_id

    def get_result(self, task_id: str, timeout: Optional[float] = None) -> Any:
        """Block until result is available."""
        with self._registry_lock:
            task = self._task_registry.get(task_id)
        if not task:
            raise KeyError(f"Unknown task: {task_id}")
        return task.future.result(timeout=timeout)

    def get_future(self, task_id: str) -> Future:
        with self._registry_lock:
            return self._task_registry[task_id].future

    def cancel(self, task_id: str) -> bool:
        with self._registry_lock:
            task = self._task_registry.get(task_id)
            if not task:
                return False
            if task.state in (TaskState.PENDING, TaskState.SCHEDULED):
                task.state = TaskState.CANCELLED
                task.future.cancel()
                logger.info(f"Cancelled task {task_id}")
                return True
        return False

    def get_status(self, task_id: str) -> dict:
        with self._registry_lock:
            task = self._task_registry.get(task_id)
            if not task:
                return {"error": "not found"}
            return {
                "task_id": task.task_id,
                "state": task.state.name,
                "retry_count": task.retry_count,
                "created_at": task.created_at,
                "started_at": task.started_at,
                "completed_at": task.completed_at,
                "error": str(task.error) if task.error else None,
            }

    # ── Internal scheduling ───────────────────

    def _enqueue(self, scheduled_task: ScheduledTask):
        with self._queue_lock:
            heapq.heappush(self._schedule_queue, scheduled_task)
            self._queue_not_empty.notify()

    def _dequeue(self) -> Optional[str]:
        """Get next ready task_id, respecting execute_at time."""
        with self._queue_lock:
            while True:
                if self._shutdown_event.is_set() and not self._schedule_queue:
                    return None

                if not self._schedule_queue:
                    self._queue_not_empty.wait(timeout=0.5)
                    if self._shutdown_event.is_set() and not self._schedule_queue:
                        return None
                    continue

                # Peek at earliest task
                earliest = self._schedule_queue[0]
                now = time.time()

                if earliest.execute_at <= now:
                    heapq.heappop(self._schedule_queue)
                    return earliest.task_id
                else:
                    # Wait until execute_at or until notified
                    wait_time = earliest.execute_at - now
                    self._queue_not_empty.wait(timeout=wait_time)

    # ── Dependency checking ───────────────────

    def _dependencies_met(self, task: TaskInfo) -> bool:
        with self._registry_lock:
            for dep_id in task.dependencies:
                dep = self._task_registry.get(dep_id)
                if not dep or dep.state != TaskState.COMPLETED:
                    return False
        return True

    # ── Worker loop ───────────────────────────

    def _worker_loop(self, worker_id: int):
        logger.info(f"Worker-{worker_id} started")

        while not self._shutdown_event.is_set() or not self._is_queue_empty():
            task_id = self._dequeue()
            if task_id is None:
                continue

            with self._registry_lock:
                task = self._task_registry.get(task_id)
                if not task or task.state == TaskState.CANCELLED:
                    continue

                # Check dependencies
                if not self._dependencies_met(task):
                    # Re-enqueue with slight delay
                    self._enqueue(ScheduledTask(
                        execute_at=time.time() + 0.5,
                        priority=task.priority,
                        task_id=task_id,
                    ))
                    continue

                task.state = TaskState.RUNNING
                task.started_at = time.time()

            # Execute outside the lock
            try:
                result = task.func(*task.args, **task.kwargs)

                with self._registry_lock:
                    task.state = TaskState.COMPLETED
                    task.result = result
                    task.completed_at = time.time()

                task.future.set_result(result)
                logger.info(f"Worker-{worker_id} completed {task_id}")

                # Invoke callback
                if task.callback:
                    try:
                        task.callback(task_id, result)
                    except Exception:
                        pass

            except Exception as e:
                with self._registry_lock:
                    task.retry_count += 1
                    task.error = e

                    if task.retry_count <= task.max_retries:
                        task.state = TaskState.RETRYING
                        backoff = task.retry_backoff * (2 ** (task.retry_count - 1))
                        logger.warning(
                            f"Worker-{worker_id}: {task_id} failed "
                            f"(attempt {task.retry_count}/{task.max_retries}), "
                            f"retrying in {backoff:.1f}s"
                        )
                        self._enqueue(ScheduledTask(
                            execute_at=time.time() + backoff,
                            priority=task.priority,
                            task_id=task_id,
                        ))
                    else:
                        task.state = TaskState.FAILED
                        task.completed_at = time.time()
                        task.future.set_exception(e)
                        logger.error(f"Worker-{worker_id}: {task_id} permanently failed")

        logger.info(f"Worker-{worker_id} exiting")

    def _is_queue_empty(self) -> bool:
        with self._queue_lock:
            return len(self._schedule_queue) == 0

    # ── Lifecycle ─────────────────────────────

    def start(self):
        for i in range(self._num_workers):
            t = threading.Thread(target=self._worker_loop, args=(i,), name=f"Worker-{i}", daemon=True)
            t.start()
            self._workers.append(t)

    def shutdown(self, wait: bool = True):
        self._shutdown_event.set()
        with self._queue_lock:
            self._queue_not_empty.notify_all()
        if wait:
            for w in self._workers:
                w.join(timeout=10)
        logger.info("Task queue shut down")


# ─────────────────────────────────────────────
# Demo
# ─────────────────────────────────────────────

def demo_async_task_queue():
    tq = AsyncTaskQueue(num_workers=3)
    tq.start()

    def add(a, b):
        time.sleep(random.uniform(0.1, 0.5))
        return a + b

    def flaky_task():
        if random.random() < 0.7:
            raise RuntimeError("Transient failure")
        return "success!"

    import random

    # Normal tasks
    t1 = tq.submit(add, 2, 3, callback=lambda tid, r: print(f"  ✓ {tid} result={r}"))
    t2 = tq.submit(add, 10, 20, priority=1)

    # Delayed task
    t3 = tq.submit(add, 100, 200, delay=2.0, priority=0)

    # Flaky task with retries
    t4 = tq.submit(flaky_task, max_retries=5, priority=2)

    # Task with dependency
    t5 = tq.submit(add, 1, 1, dependencies=[t1, t2])

    time.sleep(5)

    for tid in [t1, t2, t3, t4, t5]:
        print(f"  Status {tid}:", tq.get_status(tid))

    tq.shutdown()


if __name__ == "__main__":
    demo_async_task_queue()
```

---

## 26. Connection Pool

### Core Problem
Creating network connections (DB, HTTP, TCP) is **expensive**. A pool maintains **reusable connections**, bounding the total count and handling health checks.

### Architecture

```
┌───────────────────────────────────────────────────────────────┐
│                     Connection Pool                           │
│                                                               │
│  Application Threads                                          │
│  ┌──┐ ┌──┐ ┌──┐ ┌──┐ ┌──┐                                   │
│  │T1│ │T2│ │T3│ │T4│ │T5│     acquire() / release()          │
│  └──┘ └──┘ └──┘ └──┘ └──┘                                   │
│    │    │    │    │    │                                       │
│    ▼    ▼    ▼    ▼    ▼                                      │
│  ┌─────────────────────────────────────────┐                 │
│  │         Pool Manager                     │                 │
│  │  ┌─────────────┐  ┌──────────────────┐  │                 │
│  │  │ Available    │  │ In-Use Tracking  │  │                 │
│  │  │ (Semaphore   │  │ {conn → thread}  │  │                 │
│  │  │  + Deque)    │  │                  │  │                 │
│  │  └─────────────┘  └──────────────────┘  │                 │
│  │                                          │                 │
│  │  ┌──────────┐  ┌──────────────────────┐ │                 │
│  │  │ Health   │  │  Connection Factory   │ │                 │
│  │  │ Checker  │  │  create() / destroy() │ │                 │
│  │  │ (daemon) │  │  validate()           │ │                 │
│  │  └──────────┘  └──────────────────────┘ │                 │
│  └─────────────────────────────────────────┘                 │
│                         │                                     │
│                         ▼                                     │
│               ┌──────────────────┐                           │
│               │  External System │                           │
│               │  (DB / Service)  │                           │
│               └──────────────────┘                           │
└───────────────────────────────────────────────────────────────┘

  min_size=2    max_size=10    idle_timeout=300s
```

### Connection Lifecycle

```
 create ──▶ IDLE (in pool) ◀──▶ ACTIVE (checked out)
               │                       │
               ├── health_check fail ──▶ STALE ──▶ destroy
               └── idle_timeout ───────▶ EXPIRED ─▶ destroy
```

### Implementation

```python
import threading
import time
import logging
import socket
from collections import deque
from dataclasses import dataclass, field
from typing import Optional, Callable, Any, Deque, Set
from contextlib import contextmanager

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(threadName)s] %(message)s")
logger = logging.getLogger(__name__)


# ─────────────────────────────────────────────
# 1. Connection Abstraction
# ─────────────────────────────────────────────

@dataclass
class PooledConnection:
    """Wrapper around an actual connection with metadata."""
    conn_id: int
    raw_connection: Any          # The actual DB/socket connection
    created_at: float = field(default_factory=time.time)
    last_used_at: float = field(default_factory=time.time)
    last_validated_at: float = field(default_factory=time.time)
    use_count: int = 0
    is_valid: bool = True

    def touch(self):
        self.last_used_at = time.time()
        self.use_count += 1


class ConnectionFactory:
    """
    Abstract factory – replace with actual DB driver.
    This simulates a database connection.
    """

    def __init__(self, host: str = "localhost", port: int = 5432, db: str = "mydb"):
        self._host = host
        self._port = port
        self._db = db
        self._counter = 0
        self._lock = threading.Lock()

    def create(self) -> PooledConnection:
        with self._lock:
            self._counter += 1
            conn_id = self._counter

        # Simulate connection creation time
        time.sleep(0.05)
        logger.info(f"Created connection #{conn_id}")

        # In reality: psycopg2.connect(host=...) / mysql.connector.connect(...)
        raw = {"id": conn_id, "host": self._host, "db": self._db, "open": True}
        return PooledConnection(conn_id=conn_id, raw_connection=raw)

    def destroy(self, conn: PooledConnection):
        logger.info(f"Destroying connection #{conn.conn_id}")
        conn.raw_connection["open"] = False
        conn.is_valid = False

    def validate(self, conn: PooledConnection) -> bool:
        """Lightweight health check (e.g., SELECT 1)."""
        valid = conn.raw_connection.get("open", False)
        conn.last_validated_at = time.time()
        return valid


# ─────────────────────────────────────────────
# 2. Connection Pool
# ─────────────────────────────────────────────

class ConnectionPool:
    """
    Thread-safe connection pool with:
    - Pre-warmed minimum connections
    - Dynamic scaling up to max_size
    - Idle timeout eviction
    - Health checking
    - Context manager support
    - Metrics
    """

    def __init__(
        self,
        factory: ConnectionFactory,
        min_size: int = 2,
        max_size: int = 10,
        acquire_timeout: float = 30.0,
        idle_timeout: float = 300.0,
        max_lifetime: float = 3600.0,
        validation_interval: float = 60.0,
    ):
        self._factory = factory
        self._min_size = min_size
        self._max_size = max_size
        self._acquire_timeout = acquire_timeout
        self._idle_timeout = idle_timeout
        self._max_lifetime = max_lifetime
        self._validation_interval = validation_interval

        # Pool state
        self._idle_conns: Deque[PooledConnection] = deque()
        self._active_conns: Set[int] = set()  # conn_ids currently checked out
        self._total_created = 0
        self._lock = threading.Lock()
        self._available = threading.Semaphore(max_size)  # limits total connections
        self._conn_available = threading.Condition(self._lock)

        # Metrics
        self._waits = 0
        self._timeouts = 0
        self._total_acquired = 0
        self._total_released = 0

        self._closed = False
        self._health_checker: Optional[threading.Thread] = None

    # ── Initialization ────────────────────────

    def initialize(self):
        """Pre-warm the pool with min_size connections."""
        logger.info(f"Initializing pool (min={self._min_size}, max={self._max_size})")
        for _ in range(self._min_size):
            conn = self._factory.create()
            self._idle_conns.append(conn)
            self._total_created += 1
            self._available.acquire()  # Reserve a slot

        # Start health checker daemon
        self._health_checker = threading.Thread(
            target=self._health_check_loop, daemon=True, name="HealthChecker"
        )
        self._health_checker.start()

    # ── Acquire / Release ─────────────────────

    def acquire(self, timeout: Optional[float] = None) -> PooledConnection:
        """
        Get a connection from the pool.
        Blocks if all connections are in use until one is returned or timeout.
        """
        if self._closed:
            raise RuntimeError("Pool is closed")

        effective_timeout = timeout or self._acquire_timeout

        # Try to get a semaphore slot (limits total connections)
        if not self._available.acquire(timeout=effective_timeout):
            self._timeouts += 1
            raise TimeoutError(
                f"Could not acquire connection within {effective_timeout}s "
                f"(active={len(self._active_conns)})"
            )

        with self._lock:
            # Try to get an idle connection
            conn = self._get_idle_connection()

            if conn is None:
                # Create a new one (we already have the semaphore slot)
                conn = self._factory.create()
                self._total_created += 1

            conn.touch()
            self._active_conns.add(conn.conn_id)
            self._total_acquired += 1

        logger.debug(f"Acquired connection #{conn.conn_id}")
        return conn

    def release(self, conn: PooledConnection):
        """Return a connection to the pool."""
        with self._lock:
            self._active_conns.discard(conn.conn_id)
            self._total_released += 1

            # Check if connection is still valid and not too old
            now = time.time()
            if (
                conn.is_valid
                and self._factory.validate(conn)
                and (now - conn.created_at) < self._max_lifetime
            ):
                self._idle_conns.append(conn)
                logger.debug(f"Released connection #{conn.conn_id} back to pool")
            else:
                self._factory.destroy(conn)
                logger.info(f"Destroyed stale connection #{conn.conn_id}")

        self._available.release()  # Free the semaphore slot

    def _get_idle_connection(self) -> Optional[PooledConnection]:
        """Get a valid idle connection, discarding stale ones."""
        while self._idle_conns:
            conn = self._idle_conns.popleft()
            now = time.time()

            # Check max lifetime
            if (now - conn.created_at) > self._max_lifetime:
                self._factory.destroy(conn)
                self._available.release()
                continue

            # Validate if needed
            if (now - conn.last_validated_at) > self._validation_interval:
                if not self._factory.validate(conn):
                    self._factory.destroy(conn)
                    self._available.release()
                    continue

            return conn

        return None  # No idle connections available

    # ── Context Manager ───────────────────────

    @contextmanager
    def connection(self, timeout: Optional[float] = None):
        """
        Usage:
            with pool.connection() as conn:
                conn.raw_connection.execute("SELECT ...")
        """
        conn = self.acquire(timeout=timeout)
        try:
            yield conn
        except Exception:
            # On error, mark connection as potentially invalid
            conn.is_valid = False
            raise
        finally:
            self.release(conn)

    # ── Health Check Daemon ───────────────────

    def _health_check_loop(self):
        while not self._closed:
            time.sleep(self._validation_interval / 2)
            self._evict_idle()
            self._ensure_minimum()

    def _evict_idle(self):
        """Remove connections that have been idle too long."""
        with self._lock:
            now = time.time()
            to_keep = deque()
            evicted = 0

            while self._idle_conns:
                conn = self._idle_conns.popleft()
                idle_time = now - conn.last_used_at

                if idle_time > self._idle_timeout and (
                    len(to_keep) + len(self._active_conns) >= self._min_size
                ):
                    self._factory.destroy(conn)
                    self._available.release()
                    evicted += 1
                else:
                    to_keep.append(conn)

            self._idle_conns = to_keep

            if evicted:
                logger.info(f"Evicted {evicted} idle connections")

    def _ensure_minimum(self):
        """Ensure at least min_size connections exist."""
        with self._lock:
            total = len(self._idle_conns) + len(self._active_conns)
            deficit = self._min_size - total

        for _ in range(max(0, deficit)):
            if self._available.acquire(timeout=0):
                conn = self._factory.create()
                with self._lock:
                    self._idle_conns.append(conn)
                    self._total_created += 1

    # ── Shutdown ──────────────────────────────

    def close(self):
        """Close all connections and shut down the pool."""
        self._closed = True
        with self._lock:
            while self._idle_conns:
                conn = self._idle_conns.popleft()
                self._factory.destroy(conn)
            logger.info(
                f"Pool closed. Total created: {self._total_created}, "
                f"Active at close: {len(self._active_conns)}"
            )

    # ── Metrics ───────────────────────────────

    @property
    def stats(self) -> dict:
        with self._lock:
            return {
                "idle": len(self._idle_conns),
                "active": len(self._active_conns),
                "total_created": self._total_created,
                "total_acquired": self._total_acquired,
                "total_released": self._total_released,
                "timeouts": self._timeouts,
            }


# ─────────────────────────────────────────────
# Demo
# ─────────────────────────────────────────────

def demo_connection_pool():
    factory = ConnectionFactory(host="localhost", port=5432, db="test")
    pool = ConnectionPool(factory, min_size=2, max_size=5, idle_timeout=10)
    pool.initialize()

    def worker(worker_id):
        for _ in range(5):
            with pool.connection() as conn:
                # Simulate query
                logger.info(f"Worker-{worker_id} using conn #{conn.conn_id}")
                time.sleep(0.1)

    threads = [threading.Thread(target=worker, args=(i,)) for i in range(8)]
    for t in threads:
        t.start()
    for t in threads:
        t.join()

    print("Pool stats:", pool.stats)
    pool.close()


if __name__ == "__main__":
    demo_connection_pool()
```

---

## 27. Web Crawler

### Core Problem
Crawl millions of web pages **concurrently** while respecting politeness rules, deduplicating URLs, handling errors, and staying within resource limits.

### Architecture

```
┌──────────────────────────────────────────────────────────────────────┐
│                         Web Crawler                                   │
│                                                                       │
│  ┌────────────┐     ┌──────────────┐     ┌────────────────────┐      │
│  │  Seed URLs │────▶│   URL        │────▶│   Scheduler        │      │
│  └────────────┘     │   Frontier   │     │   (Priority Queue  │      │
│                     │   (BFS/DFS)  │     │    + Domain Delay) │      │
│                     └──────────────┘     └────────┬───────────┘      │
│                            ▲                      │                   │
│                            │                      ▼                   │
│  ┌──────────────┐          │        ┌──────────────────────┐         │
│  │  URL Filter  │          │        │   Worker Pool        │         │
│  │  - Seen set  │──────────┤        │   ┌──────────────┐   │         │
│  │  - Robots    │          │        │   │  Fetcher 1   │   │         │
│  │  - Domain    │          │        │   │  Fetcher 2   │   │         │
│  │    whitelist │          │        │   │  Fetcher 3   │   │         │
│  └──────────────┘          │        │   │  ...         │   │         │
│                            │        │   └──────┬───────┘   │         │
│                            │        └──────────┼───────────┘         │
│                            │                   │                      │
│                            │                   ▼                      │
│                     ┌──────┴───────┐    ┌──────────────┐             │
│                     │  Link        │◀───│   Parser     │             │
│                     │  Extractor   │    │  (HTML→Data) │             │
│                     └──────────────┘    └──────┬───────┘             │
│                                                │                      │
│                                                ▼                      │
│                                         ┌──────────────┐             │
│                                         │   Storage    │             │
│                                         │  (DB/Files)  │             │
│                                         └──────────────┘             │
└──────────────────────────────────────────────────────────────────────┘
```

### Politeness & Rate Limiting

```
Domain: example.com
    
  Request 1  ──▶  [1s delay]  ──▶  Request 2  ──▶  [1s delay]  ──▶  ...

  ┌─────────────────────────────────────┐
  │  Per-Domain Rate Limiter            │
  │                                     │
  │  example.com  │ last_access: 14:30  │
  │  google.com   │ last_access: 14:29  │
  │  github.com   │ last_access: 14:31  │
  │                                     │
  │  Minimum delay between requests     │
  │  to same domain: 1-2 seconds        │
  └─────────────────────────────────────┘
```

### Implementation

```python
import threading
import time
import hashlib
import logging
import re
from collections import deque, defaultdict
from dataclasses import dataclass, field
from typing import Set, Dict, List, Optional, Callable
from urllib.parse import urljoin, urlparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import queue

# In production, use: import requests, from bs4 import BeautifulSoup
# Here we simulate HTTP for self-contained example

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(threadName)s] %(message)s")
logger = logging.getLogger(__name__)


# ─────────────────────────────────────────────
# 1. Data Models
# ─────────────────────────────────────────────

@dataclass
class CrawlRequest:
    url: str
    depth: int = 0
    priority: int = 0        # Lower = higher priority
    parent_url: str = ""
    retry_count: int = 0

@dataclass(order=True)
class PrioritizedRequest:
    priority: int
    request: CrawlRequest = field(compare=False)

@dataclass
class CrawlResult:
    url: str
    status_code: int
    content_type: str = ""
    content: str = ""
    links: List[str] = field(default_factory=list)
    title: str = ""
    fetch_time: float = 0.0
    error: Optional[str] = None


# ─────────────────────────────────────────────
# 2. URL Frontier (thread-safe priority queue)
# ─────────────────────────────────────────────

class URLFrontier:
    """
    Manages the queue of URLs to crawl.
    - Priority-based ordering
    - Thread-safe
    - Deduplication via seen set using content hashes
    """

    def __init__(self):
        self._queue: queue.PriorityQueue = queue.PriorityQueue()
        self._seen_urls: Set[str] = set()
        self._seen_lock = threading.Lock()
        self._enqueued = 0
        self._deduplicated = 0

    def add(self, request: CrawlRequest) -> bool:
        """Add URL to frontier if not seen before. Returns True if added."""
        normalized = self._normalize_url(request.url)

        with self._seen_lock:
            if normalized in self._seen_urls:
                self._deduplicated += 1
                return False
            self._seen_urls.add(normalized)

        self._queue.put(PrioritizedRequest(
            priority=request.priority + request.depth,  # Deeper = lower priority
            request=request,
        ))
        self._enqueued += 1
        return True

    def get(self, timeout: float = 1.0) -> Optional[CrawlRequest]:
        try:
            item = self._queue.get(timeout=timeout)
            return item.request
        except queue.Empty:
            return None

    def add_many(self, requests: List[CrawlRequest]) -> int:
        added = 0
        for req in requests:
            if self.add(req):
                added += 1
        return added

    @staticmethod
    def _normalize_url(url: str) -> str:
        """Normalize URL for deduplication."""
        parsed = urlparse(url)
        # Remove fragment, normalize path
        normalized = f"{parsed.scheme}://{parsed.netloc}{parsed.path}".rstrip("/").lower()
        if parsed.query:
            # Sort query params for canonical form
            params = sorted(parsed.query.split("&"))
            normalized += "?" + "&".join(params)
        return normalized

    @property
    def size(self) -> int:
        return self._queue.qsize()

    @property
    def seen_count(self) -> int:
        with self._seen_lock:
            return len(self._seen_urls)

    def has_seen(self, url: str) -> bool:
        with self._seen_lock:
            return self._normalize_url(url) in self._seen_urls


# ─────────────────────────────────────────────
# 3. Politeness: Per-Domain Rate Limiter
# ─────────────────────────────────────────────

class DomainRateLimiter:
    """
    Enforces minimum delay between requests to the same domain.
    Also tracks robots.txt rules (simplified).
    """

    def __init__(self, default_delay: float = 1.0):
        self._default_delay = default_delay
        self._domain_delays: Dict[str, float] = {}       # Custom per-domain delays
        self._last_access: Dict[str, float] = {}
        self._lock = threading.Lock()
        self._blocked_domains: Set[str] = set()

    def wait_if_needed(self, url: str):
        """Block the calling thread until it's polite to fetch this URL."""
        domain = urlparse(url).netloc

        if domain in self._blocked_domains:
            raise PermissionError(f"Domain {domain} is blocked")

        delay = self._domain_delays.get(domain, self._default_delay)

        with self._lock:
            last = self._last_access.get(domain, 0)
            now = time.time()
            wait_time = max(0, delay - (now - last))

            if wait_time > 0:
                # Release lock while sleeping
                pass

        if wait_time > 0:
            time.sleep(wait_time)

        with self._lock:
            self._last_access[domain] = time.time()

    def block_domain(self, domain: str):
        self._blocked_domains.add(domain)

    def set_delay(self, domain: str, delay: float):
        self._domain_delays[domain] = delay


# ─────────────────────────────────────────────
# 4. Fetcher (HTTP client simulation)
# ─────────────────────────────────────────────

class PageFetcher:
    """
    Fetches web pages. In production, use `requests` or `aiohttp`.
    This simulates responses for demonstration.
    """

    # Simulated web for demo
    SIMULATED_WEB = {
        "https://example.com": {
            "status": 200,
            "title": "Example Home",
            "links": [
                "https://example.com/about",
                "https://example.com/products",
                "https://example.com/blog",
            ],
            "content": "Welcome to Example.com",
        },
        "https://example.com/about": {
            "status": 200,
            "title": "About Us",
            "links": [
                "https://example.com",
                "https://example.com/team",
                "https://external.com/partner",
            ],
            "content": "We are a company.",
        },
        "https://example.com/products": {
            "status": 200,
            "title": "Products",
            "links": [
                "https://example.com/products/widget",
                "https://example.com/products/gadget",
            ],
            "content": "Our products page.",
        },
        "https://example.com/blog": {
            "status": 200,
            "title": "Blog",
            "links": [
                "https://example.com/blog/post-1",
                "https://example.com/blog/post-2",
            ],
            "content": "Blog posts here.",
        },
    }

    def __init__(self, timeout: float = 10.0, user_agent: str = "MyCrawler/1.0"):
        self._timeout = timeout
        self._user_agent = user_agent

    def fetch(self, url: str) -> CrawlResult:
        start = time.time()

        # ── Simulation ──
        time.sleep(0.05)  # Simulate network latency

        page = self.SIMULATED_WEB.get(url)
        if page:
            return CrawlResult(
                url=url,
                status_code=page["status"],
                content_type="text/html",
                content=page["content"],
                links=page["links"],
                title=page["title"],
                fetch_time=time.time() - start,
            )
        else:
            # Simulate 404 for unknown URLs
            return CrawlResult(
                url=url,
                status_code=404,
                fetch_time=time.time() - start,
                error="Not Found",
            )

        # ── Real implementation would be ──
        # import requests
        # try:
        #     resp = requests.get(url, timeout=self._timeout,
        #                         headers={"User-Agent": self._user_agent})
        #     from bs4 import BeautifulSoup
        #     soup = BeautifulSoup(resp.text, "html.parser")
        #     links = [urljoin(url, a["href"]) for a in soup.find_all("a", href=True)]
        #     title = soup.title.string if soup.title else ""
        #     return CrawlResult(url=url, status_code=resp.status_code,
        #                        content=resp.text, links=links, title=title,
        #                        fetch_time=time.time() - start)
        # except Exception as e:
        #     return CrawlResult(url=url, status_code=0, error=str(e),
        #                        fetch_time=time.time() - start)


# ─────────────────────────────────────────────
# 5. URL Filter
# ─────────────────────────────────────────────

class URLFilter:
    """Filters URLs based on various rules."""

    def __init__(
        self,
        allowed_domains: Optional[Set[str]] = None,
        max_depth: int = 5,
        exclude_patterns: Optional[List[str]] = None,
    ):
        self._allowed_domains = allowed_domains
        self._max_depth = max_depth
        self._exclude_patterns = [
            re.compile(p) for p in (exclude_patterns or [])
        ]

    def should_crawl(self, request: CrawlRequest) -> bool:
        # Depth check
        if request.depth > self._max_depth:
            return False

        parsed = urlparse(request.url)

        # Scheme check
        if parsed.scheme not in ("http", "https"):
            return False

        # Domain whitelist
        if self._allowed_domains and parsed.netloc not in self._allowed_domains:
            return False

        # Exclude patterns (e.g., images, PDFs)
        for pattern in self._exclude_patterns:
            if pattern.search(request.url):
                return False

        # Skip common non-page extensions
        path = parsed.path.lower()
        skip_ext = {".jpg", ".png", ".gif", ".pdf", ".zip", ".css", ".js"}
        if any(path.endswith(ext) for ext in skip_ext):
            return False

        return True


# ─────────────────────────────────────────────
# 6. Storage
# ─────────────────────────────────────────────

class CrawlStorage:
    """Thread-safe storage for crawl results."""

    def __init__(self):
        self._results: Dict[str, CrawlResult] = {}
        self._lock = threading.Lock()

    def store(self, result: CrawlResult):
        with self._lock:
            self._results[result.url] = result

    def get(self, url: str) -> Optional[CrawlResult]:
        with self._lock:
            return self._results.get(url)

    @property
    def count(self) -> int:
        with self._lock:
            return len(self._results)

    def get_all(self) -> Dict[str, CrawlResult]:
        with self._lock:
            return dict(self._results)


# ─────────────────────────────────────────────
# 7. Web Crawler (Orchestrator)
# ─────────────────────────────────────────────

class WebCrawler:
    """
    Multithreaded web crawler with:
    - BFS/priority crawl ordering
    - Concurrent fetchers (thread pool)
    - Per-domain rate limiting
    - URL deduplication
    - Configurable depth/domain limits
    - Graceful shutdown
    - Crawl statistics
    """

    def __init__(
        self,
        num_workers: int = 5,
        max_depth: int = 3,
        max_pages: int = 100,
        allowed_domains: Optional[Set[str]] = None,
        politeness_delay: float = 1.0,
    ):
        self._num_workers = num_workers
        self._max_pages = max_pages

        # Components
        self._frontier = URLFrontier()
        self._fetcher = PageFetcher()
        self._rate_limiter = DomainRateLimiter(default_delay=politeness_delay)
        self._url_filter = URLFilter(
            allowed_domains=allowed_domains,
            max_depth=max_depth,
            exclude_patterns=[r"\.(jpg|png|gif|pdf|zip)$"],
        )
        self._storage = CrawlStorage()

        # State
        self._shutdown_event = threading.Event()
        self._active_fetches = 0
        self._active_lock = threading.Lock()

        # Stats
        self._stats = {
            "pages_crawled": 0,
            "pages_failed": 0,
            "links_discovered": 0,
            "links_filtered": 0,
            "start_time": 0,
        }
        self._stats_lock = threading.Lock()

    def crawl(self, seed_urls: List[str]):
        """Main entry point. Blocks until crawl completes or max_pages reached."""
        self._stats["start_time"] = time.time()
        logger.info(f"Starting crawl with {len(seed_urls)} seed URLs")

        # Add seeds to frontier
        for url in seed_urls:
            self._frontier.add(CrawlRequest(url=url, depth=0))

        # Launch worker threads
        with ThreadPoolExecutor(
            max_workers=self._num_workers, thread_name_prefix="Crawler"
        ) as executor:
            futures = []

            while not self._should_stop():
                # Get next URL from frontier
                request = self._frontier.get(timeout=2.0)
                if request is None:
                    # Check if all workers are idle
                    with self._active_lock:
                        if self._active_fetches == 0 and self._frontier.size == 0:
                            logger.info("Frontier empty and no active fetches. Done.")
                            break
                    continue

                # Submit to thread pool
                future = executor.submit(self._crawl_page, request)
                futures.append(future)

            # Wait for remaining futures
            for f in futures:
                try:
                    f.result(timeout=30)
                except Exception as e:
                    logger.error(f"Worker error: {e}")

        self._print_stats()

    def _crawl_page(self, request: CrawlRequest):
        """Fetch and process a single page."""
        with self._active_lock:
            self._active_fetches += 1

        try:
            # Rate limiting (blocks if too fast)
            self._rate_limiter.wait_if_needed(request.url)

            # Fetch
            result = self._fetcher.fetch(request.url)

            if result.status_code == 200:
                # Store the result
                self._storage.store(result)

                with self._stats_lock:
                    self._stats["pages_crawled"] += 1

                logger.info(
                    f"Crawled [{result.status_code}] {request.url} "
                    f"(depth={request.depth}, links={len(result.links)})"
                )

                # Extract and enqueue new URLs
                new_requests = []
                for link in result.links:
                    child = CrawlRequest(
                        url=link,
                        depth=request.depth + 1,
                        parent_url=request.url,
                    )
                    if self._url_filter.should_crawl(child):
                        new_requests.append(child)
                    else:
                        with self._stats_lock:
                            self._stats["links_filtered"] += 1

                added = self._frontier.add_many(new_requests)
                with self._stats_lock:
                    self._stats["links_discovered"] += len(result.links)

            else:
                with self._stats_lock:
                    self._stats["pages_failed"] += 1
                logger.warning(f"Failed [{result.status_code}] {request.url}: {result.error}")

        except PermissionError as e:
            logger.warning(f"Blocked: {e}")
        except Exception as e:
            logger.error(f"Error crawling {request.url}: {e}")
            with self._stats_lock:
                self._stats["pages_failed"] += 1
        finally:
            with self._active_lock:
                self._active_fetches -= 1

    def _should_stop(self) -> bool:
        if self._shutdown_event.is_set():
            return True
        with self._stats_lock:
            return self._stats["pages_crawled"] >= self._max_pages

    def stop(self):
        self._shutdown_event.set()

    def _print_stats(self):
        elapsed = time.time() - self._stats["start_time"]
        crawled = self._stats["pages_crawled"]
        print("\n" + "=" * 50)
        print("CRAWL STATISTICS")
        print("=" * 50)
        print(f"  Pages crawled:    {crawled}")
        print(f"  Pages failed:     {self._stats['pages_failed']}")
        print(f"  Links discovered: {self._stats['links_discovered']}")
        print(f"  Links filtered:   {self._stats['links_filtered']}")
        print(f"  URLs seen:        {self._frontier.seen_count}")
        print(f"  Time elapsed:     {elapsed:.2f}s")
        print(f"  Pages/second:     {crawled / elapsed:.2f}" if elapsed > 0 else "")
        print(f"  Results stored:   {self._storage.count}")
        print("=" * 50)

        # Print crawled pages
        for url, result in self._storage.get_all().items():
            print(f"  📄 {result.title or 'Untitled'}: {url}")


# ─────────────────────────────────────────────
# Demo
# ─────────────────────────────────────────────

def demo_web_crawler():
    crawler = WebCrawler(
        num_workers=3,
        max_depth=2,
        max_pages=20,
        allowed_domains={"example.com"},
        politeness_delay=0.2,  # Short for demo
    )

    crawler.crawl(seed_urls=["https://example.com"])


if __name__ == "__main__":
    demo_web_crawler()
```

---

## Summary Comparison

```
┌─────────────────────┬──────────────────┬───────────────────┬─────────────────┐
│ System              │ Core Primitive   │ Key Challenge     │ Pattern         │
├─────────────────────┼──────────────────┼───────────────────┼─────────────────┤
│ Thread-Safe Cache   │ RWLock / Striped │ Read concurrency  │ Readers-Writer  │
│                     │ Locks            │ vs write safety   │ Lock            │
├─────────────────────┼──────────────────┼───────────────────┼─────────────────┤
│ Producer-Consumer   │ Semaphores +     │ Back-pressure,    │ Bounded Buffer  │
│                     │ Bounded Queue    │ graceful shutdown  │ + Poison Pill   │
├─────────────────────┼──────────────────┼───────────────────┼─────────────────┤
│ Async Task Queue    │ Priority Heap +  │ Retries, delays,  │ Worker Pool +   │
│                     │ Condition Var    │ dependencies       │ State Machine   │
├─────────────────────┼──────────────────┼───────────────────┼─────────────────┤
│ Connection Pool     │ Semaphore +      │ Health checking,  │ Object Pool +   │
│                     │ Deque            │ idle eviction      │ Factory         │
├─────────────────────┼──────────────────┼───────────────────┼─────────────────┤
│ Web Crawler         │ ThreadPool +     │ Politeness,       │ BFS + Rate      │
│                     │ Priority Queue   │ deduplication      │ Limiter         │
└─────────────────────┴──────────────────┴───────────────────┴─────────────────┘
```