HLD Large Scale System Design (HLD) — Complete Deep Dive

---

## 1. URL Shortener (like Bitly)

### 1.1 Requirements

```
Functional:
  ✦ Given a long URL → return a short URL
  ✦ Given a short URL → redirect to original (301/302)
  ✦ Optional: custom aliases, expiry, analytics

Non-Functional:
  ✦ Very low latency redirection (< 10 ms)
  ✦ High availability (99.99%)
  ✦ Short URLs should not be predictable (guessable)
```

### 1.2 Capacity Estimation

```
Assumptions:
  • 100M new URLs/month (write)
  • Read:Write = 100:1 → 10B redirections/month
  
Throughput:
  • Writes: 100M / (30×24×3600) ≈ ~40 URLs/sec
  • Reads:  10B / (30×24×3600)  ≈ ~4000 reads/sec

Storage (5-year horizon):
  • 100M × 12 months × 5 years = 6 Billion records
  • Each record ≈ 500 bytes → 6B × 500B ≈ 3 TB

Bandwidth:
  • Writes: 40 × 500B = 20 KB/s
  • Reads:  4000 × 500B = 2 MB/s

Cache:
  • 80/20 rule: 20% hot URLs → cache 20% of daily reads
  • 4000 req/s × 86400 × 0.2 × 500B ≈ ~35 GB cache
```

### 1.3 High-Level Architecture

```
                          ┌──────────────┐
                          │   Clients    │
                          │ (Browser/App)│
                          └──────┬───────┘
                                 │
                          ┌──────▼───────┐
                          │  Load        │
                          │  Balancer    │
                          └──────┬───────┘
                                 │
               ┌─────────────────┼─────────────────┐
               │                 │                 │
        ┌──────▼──────┐  ┌──────▼──────┐  ┌──────▼──────┐
        │  App Server │  │  App Server │  │  App Server │
        │  (Stateless)│  │  (Stateless)│  │  (Stateless)│
        └──────┬──────┘  └──────┬──────┘  └──────┬──────┘
               │                 │                 │
               └─────────────────┼─────────────────┘
                                 │
                    ┌────────────┼────────────┐
                    │            │            │
             ┌──────▼─────┐ ┌───▼────┐ ┌────▼──────────┐
             │   Cache    │ │  Key   │ │   Database    │
             │  (Redis)   │ │ Gen.   │ │  (Cassandra/  │
             │            │ │Service │ │   DynamoDB)   │
             └────────────┘ └────────┘ └───────────────┘
                                             │
                                       ┌─────▼─────┐
                                       │ Analytics │
                                       │ (Kafka +  │
                                       │  Hadoop)  │
                                       └───────────┘
```

### 1.4 Core Algorithm — Short Key Generation

**Approach A: Base62 Encoding of Auto-Increment ID**
```
Characters: [a-z, A-Z, 0-9] = 62 chars
Key length 7 → 62^7 ≈ 3.5 trillion unique URLs (enough!)
```

**Approach B: MD5/SHA256 Hash + First 7 chars (collision prone)**

**Approach C: Pre-generated Key Database (KGS) — BEST**

```
┌────────────────────────────────────────────────────────┐
│              Key Generation Service (KGS)              │
│                                                        │
│  ┌──────────────────┐    ┌──────────────────┐          │
│  │   Unused Keys    │───▶│    Used Keys     │          │
│  │   (key_pool)     │    │   (used_pool)    │          │
│  │                  │    │                  │          │
│  │  aB3xK9p         │    │  tR4yM2q         │          │
│  │  zL7wN1m         │    │  pQ8vJ5s         │          │
│  │  ...             │    │  ...             │          │
│  └──────────────────┘    └──────────────────┘          │
│                                                        │
│  • Pre-generates millions of 7-char Base62 keys        │
│  • App server requests batch of keys (e.g., 1000)      │
│  • Keys moved from unused → used atomically            │
│  • Eliminates collision & hash computation              │
└────────────────────────────────────────────────────────┘
```

### 1.5 Database Schema

```
┌─────────────────────────────┐     ┌──────────────────────────┐
│        url_mappings         │     │         users            │
├─────────────────────────────┤     ├──────────────────────────┤
│ short_key   VARCHAR(7) PK  │     │ user_id    BIGINT PK     │
│ original_url TEXT           │     │ name       VARCHAR(100)  │
│ user_id      BIGINT FK     │     │ email      VARCHAR(255)  │
│ created_at   TIMESTAMP     │     │ api_key    VARCHAR(64)   │
│ expires_at   TIMESTAMP     │     │ created_at TIMESTAMP     │
│ click_count  BIGINT        │     └──────────────────────────┘
└─────────────────────────────┘

Why NoSQL (Cassandra/DynamoDB)?
  • No relationships needed (simple key-value lookup)
  • Billions of rows → horizontal scaling (sharding)
  • High write throughput
  • Partition key = short_key → even distribution
```

### 1.6 Detailed Read/Write Flow

```
WRITE FLOW (Create Short URL):
═══════════════════════════════════════════════════
Client ──POST /api/shorten──▶ Load Balancer
                                    │
                              App Server
                                    │
                      ┌─────────────▼──────────────┐
                      │ 1. Validate long_url        │
                      │ 2. Check if URL exists       │
                      │    (bloom filter or DB)      │
                      │ 3. Get key from KGS          │
                      │ 4. Store {key → long_url}    │
                      │ 5. Return short URL          │
                      └──────────────────────────────┘

READ FLOW (Redirect):
═══════════════════════════════════════════════════
Client ──GET /aB3xK9p──▶ Load Balancer
                                │
                          App Server
                                │
                    ┌───────────▼────────────┐
                    │ 1. Check Redis Cache    │──HIT──▶ 301 Redirect
                    │ 2. If MISS → query DB   │
                    │ 3. Populate cache        │
                    │ 4. 301 Redirect          │
                    │ 5. Async: log analytics  │
                    └────────────────────────┘
```

### 1.7 Full Python Implementation

```python
"""
URL Shortener — Production-Grade Implementation
"""
import hashlib
import time
import string
import random
import threading
from collections import OrderedDict
from dataclasses import dataclass, field
from typing import Optional, Dict
from datetime import datetime, timedelta


# ─────────────────────────────────────────────
# Component 1: Base62 Encoder
# ─────────────────────────────────────────────
class Base62Encoder:
    """Encode/decode integers to/from Base62 strings."""
    
    CHARSET = string.digits + string.ascii_lowercase + string.ascii_uppercase
    BASE = 62
    
    @classmethod
    def encode(cls, num: int, min_length: int = 7) -> str:
        if num == 0:
            return cls.CHARSET[0] * min_length
        
        chars = []
        while num > 0:
            chars.append(cls.CHARSET[num % cls.BASE])
            num //= cls.BASE
        
        result = ''.join(reversed(chars))
        return result.zfill(min_length) if len(result) < min_length else result
    
    @classmethod
    def decode(cls, s: str) -> int:
        num = 0
        for char in s:
            num = num * cls.BASE + cls.CHARSET.index(char)
        return num


# ─────────────────────────────────────────────
# Component 2: Key Generation Service (KGS)
# ─────────────────────────────────────────────
class KeyGenerationService:
    """
    Pre-generates unique keys and hands them out in batches.
    In production: separate service with its own DB.
    """
    
    def __init__(self, key_length: int = 7, pool_size: int = 10000):
        self.key_length = key_length
        self.pool_size = pool_size
        self.unused_keys: list = []
        self.used_keys: set = set()
        self.lock = threading.Lock()
        self._generate_pool()
    
    def _generate_pool(self):
        """Pre-generate a pool of unique keys."""
        charset = string.ascii_letters + string.digits
        while len(self.unused_keys) < self.pool_size:
            key = ''.join(random.choices(charset, k=self.key_length))
            if key not in self.used_keys:
                self.unused_keys.append(key)
    
    def get_key(self) -> str:
        """Get a single unique key (thread-safe)."""
        with self.lock:
            if not self.unused_keys:
                self._generate_pool()
            key = self.unused_keys.pop()
            self.used_keys.add(key)
            return key
    
    def get_batch(self, count: int = 100) -> list:
        """Get a batch of keys for an app server."""
        with self.lock:
            if len(self.unused_keys) < count:
                self._generate_pool()
            batch = self.unused_keys[:count]
            self.unused_keys = self.unused_keys[count:]
            self.used_keys.update(batch)
            return batch


# ─────────────────────────────────────────────
# Component 3: LRU Cache (simulates Redis)
# ─────────────────────────────────────────────
class LRUCache:
    """
    Least Recently Used Cache — simulates Redis for hot URLs.
    In production: use Redis Cluster with TTL.
    """
    
    def __init__(self, capacity: int = 10000):
        self.capacity = capacity
        self.cache: OrderedDict = OrderedDict()
        self.hits = 0
        self.misses = 0
    
    def get(self, key: str) -> Optional[str]:
        if key in self.cache:
            self.cache.move_to_end(key)
            self.hits += 1
            return self.cache[key]
        self.misses += 1
        return None
    
    def put(self, key: str, value: str):
        if key in self.cache:
            self.cache.move_to_end(key)
        self.cache[key] = value
        if len(self.cache) > self.capacity:
            self.cache.popitem(last=False)  # evict LRU
    
    @property
    def hit_rate(self) -> float:
        total = self.hits + self.misses
        return self.hits / total if total > 0 else 0.0


# ─────────────────────────────────────────────
# Component 4: Database Layer (simulates Cassandra/DynamoDB)
# ─────────────────────────────────────────────
@dataclass
class URLRecord:
    short_key: str
    original_url: str
    user_id: Optional[str] = None
    created_at: datetime = field(default_factory=datetime.utcnow)
    expires_at: Optional[datetime] = None
    click_count: int = 0


class Database:
    """
    Simulates a distributed NoSQL database.
    In production: Cassandra with partition key = short_key
    """
    
    def __init__(self, num_shards: int = 4):
        self.num_shards = num_shards
        # Each shard is a dict simulating a DB partition
        self.shards: list[Dict[str, URLRecord]] = [
            {} for _ in range(num_shards)
        ]
        # Reverse index: long_url → short_key (for dedup)
        self.reverse_index: Dict[str, str] = {}
    
    def _get_shard(self, key: str) -> int:
        """Consistent hashing to determine shard."""
        return hash(key) % self.num_shards
    
    def save(self, record: URLRecord) -> bool:
        shard_id = self._get_shard(record.short_key)
        self.shards[shard_id][record.short_key] = record
        self.reverse_index[record.original_url] = record.short_key
        return True
    
    def find_by_key(self, short_key: str) -> Optional[URLRecord]:
        shard_id = self._get_shard(short_key)
        record = self.shards[shard_id].get(short_key)
        if record and record.expires_at and record.expires_at < datetime.utcnow():
            del self.shards[shard_id][short_key]
            return None
        return record
    
    def find_by_url(self, original_url: str) -> Optional[str]:
        return self.reverse_index.get(original_url)
    
    def increment_clicks(self, short_key: str):
        shard_id = self._get_shard(short_key)
        if short_key in self.shards[shard_id]:
            self.shards[shard_id][short_key].click_count += 1
    
    def total_records(self) -> int:
        return sum(len(shard) for shard in self.shards)


# ─────────────────────────────────────────────
# Component 5: Analytics Service
# ─────────────────────────────────────────────
class AnalyticsService:
    """Async click tracking — in production uses Kafka + Spark."""
    
    def __init__(self):
        self.click_log: list = []
    
    def log_click(self, short_key: str, user_agent: str = "", 
                  ip: str = "", referrer: str = ""):
        self.click_log.append({
            "short_key": short_key,
            "timestamp": datetime.utcnow().isoformat(),
            "user_agent": user_agent,
            "ip": ip,
            "referrer": referrer,
        })
    
    def get_stats(self, short_key: str) -> dict:
        clicks = [c for c in self.click_log if c["short_key"] == short_key]
        return {
            "total_clicks": len(clicks),
            "recent_clicks": clicks[-5:],
        }


# ─────────────────────────────────────────────
# Component 6: URL Shortener Service (Main Orchestrator)
# ─────────────────────────────────────────────
class URLShortener:
    """
    Main service orchestrating all components.
    
    Architecture:
      Client → LB → AppServer → Cache → DB
                                   ↓
                               Analytics
    """
    
    BASE_URL = "https://short.ly/"
    
    def __init__(self):
        self.kgs = KeyGenerationService(key_length=7, pool_size=5000)
        self.cache = LRUCache(capacity=10000)
        self.db = Database(num_shards=4)
        self.analytics = AnalyticsService()
        print("✅ URL Shortener initialized")
        print(f"   KGS Pool: {len(self.kgs.unused_keys)} keys ready")
        print(f"   DB Shards: {self.db.num_shards}")
        print(f"   Cache Capacity: {self.cache.capacity}")
    
    def shorten(self, long_url: str, user_id: str = None,
                custom_alias: str = None, 
                ttl_hours: int = None) -> dict:
        """
        Create a short URL.
        
        Flow:
        1. Validate URL
        2. Check for duplicates
        3. Generate/use custom key
        4. Store in DB + Cache
        5. Return short URL
        """
        # Step 1: Validate
        if not long_url or not long_url.startswith(("http://", "https://")):
            return {"error": "Invalid URL", "status": 400}
        
        # Step 2: Check for duplicate (idempotency)
        existing_key = self.db.find_by_url(long_url)
        if existing_key and not custom_alias:
            return {
                "short_url": f"{self.BASE_URL}{existing_key}",
                "short_key": existing_key,
                "long_url": long_url,
                "status": 200,
                "message": "URL already shortened",
            }
        
        # Step 3: Get or validate key
        if custom_alias:
            if self.db.find_by_key(custom_alias):
                return {"error": "Custom alias already taken", "status": 409}
            short_key = custom_alias
        else:
            short_key = self.kgs.get_key()
        
        # Step 4: Create record
        expires_at = None
        if ttl_hours:
            expires_at = datetime.utcnow() + timedelta(hours=ttl_hours)
        
        record = URLRecord(
            short_key=short_key,
            original_url=long_url,
            user_id=user_id,
            expires_at=expires_at,
        )
        self.db.save(record)
        self.cache.put(short_key, long_url)
        
        return {
            "short_url": f"{self.BASE_URL}{short_key}",
            "short_key": short_key,
            "long_url": long_url,
            "expires_at": expires_at.isoformat() if expires_at else None,
            "status": 201,
        }
    
    def redirect(self, short_key: str, 
                 user_agent: str = "", ip: str = "") -> dict:
        """
        Resolve short URL → original URL.
        
        Flow:
        1. Check cache (Redis) → O(1)
        2. If miss → check DB
        3. Populate cache on miss
        4. Log analytics asynchronously
        5. Return redirect response
        """
        # Step 1: Cache lookup
        cached_url = self.cache.get(short_key)
        if cached_url:
            self.analytics.log_click(short_key, user_agent, ip)
            self.db.increment_clicks(short_key)
            return {
                "long_url": cached_url,
                "status": 301,
                "source": "cache",
            }
        
        # Step 2: DB lookup
        record = self.db.find_by_key(short_key)
        if not record:
            return {"error": "Short URL not found", "status": 404}
        
        # Step 3: Populate cache
        self.cache.put(short_key, record.original_url)
        
        # Step 4: Analytics
        self.analytics.log_click(short_key, user_agent, ip)
        self.db.increment_clicks(short_key)
        
        return {
            "long_url": record.original_url,
            "status": 301,
            "source": "database",
        }
    
    def get_analytics(self, short_key: str) -> dict:
        record = self.db.find_by_key(short_key)
        if not record:
            return {"error": "Not found", "status": 404}
        
        stats = self.analytics.get_stats(short_key)
        return {
            "short_key": short_key,
            "original_url": record.original_url,
            "created_at": record.created_at.isoformat(),
            "total_clicks": record.click_count,
            "recent_activity": stats["recent_clicks"],
        }
    
    def system_stats(self) -> dict:
        return {
            "total_urls": self.db.total_records(),
            "cache_size": len(self.cache.cache),
            "cache_hit_rate": f"{self.cache.hit_rate:.2%}",
            "kgs_remaining_keys": len(self.kgs.unused_keys),
            "total_clicks_logged": len(self.analytics.click_log),
        }


# ─────────────────────────────────────────────
# DEMO
# ─────────────────────────────────────────────
if __name__ == "__main__":
    shortener = URLShortener()
    
    print("\n" + "="*60)
    print("DEMO: URL SHORTENER")
    print("="*60)
    
    # Create short URLs
    urls = [
        "https://www.example.com/very/long/path/to/resource?id=12345",
        "https://docs.python.org/3/library/collections.html",
        "https://github.com/torvalds/linux/blob/master/README",
    ]
    
    print("\n📝 Creating short URLs:")
    for url in urls:
        result = shortener.shorten(url, user_id="user_001")
        print(f"   {result['short_url']} → {url[:50]}...")
    
    # Custom alias
    result = shortener.shorten(
        "https://myportfolio.com", 
        custom_alias="mysite",
        ttl_hours=24
    )
    print(f"   {result['short_url']} → Custom alias (24h TTL)")
    
    # Duplicate detection
    dup = shortener.shorten(urls[0])
    print(f"\n🔄 Duplicate: {dup['message']}")
    
    # Redirect simulation
    print("\n🔀 Redirecting:")
    for _ in range(5):
        r = shortener.redirect(result['short_key'], "Mozilla/5.0", "192.168.1.1")
        print(f"   /{result['short_key']} → {r['long_url']} (from {r['source']})")
    
    # Analytics
    print(f"\n📊 Analytics for /{result['short_key']}:")
    stats = shortener.get_analytics(result['short_key'])
    print(f"   Total clicks: {stats['total_clicks']}")
    
    # System stats
    print(f"\n⚙️  System Stats:")
    for k, v in shortener.system_stats().items():
        print(f"   {k}: {v}")
    
    # Base62 demo
    print(f"\n🔢 Base62 Examples:")
    for num in [1, 1000, 1000000, 3500000000]:
        encoded = Base62Encoder.encode(num)
        decoded = Base62Encoder.decode(encoded)
        print(f"   {num:>15,} → {encoded} → {decoded:>15,}")
```

### 1.8 Scaling Deep Dive

```
┌────────────────────────────────────────────────────────────┐
│                    SCALING STRATEGIES                       │
├────────────────────────────────────────────────────────────┤
│                                                            │
│  DATABASE PARTITIONING (Sharding):                         │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐     │
│  │ Shard-1  │ │ Shard-2  │ │ Shard-3  │ │ Shard-4  │     │
│  │ a-f keys │ │ g-m keys │ │ n-s keys │ │ t-z keys │     │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘     │
│  Strategy: Hash-based (consistent hashing)                │
│  Or: Range-based on first char of short_key               │
│                                                            │
│  CACHING LAYER:                                            │
│  • Redis Cluster (6+ nodes, 3 masters + 3 replicas)       │
│  • Cache-aside pattern (check cache → DB → populate)      │
│  • TTL = 24 hours for cache entries                        │
│  • ~35 GB needed for 20% of daily traffic                  │
│                                                            │
│  LOAD BALANCING:                                           │
│  • L7 (Application) load balancer                          │
│  • Round-robin or least-connections                        │
│  • Health checks every 5 seconds                           │
│                                                            │
│  CDN:                                                      │
│  • Geographic distribution for redirect latency            │
│  • Edge caching of popular short URLs                      │
│                                                            │
│  KGS AVAILABILITY:                                         │
│  • Standby replica of KGS                                  │
│  • Each app server pre-fetches 1000 keys                   │
│  • If KGS is down, app servers use local pool              │
└────────────────────────────────────────────────────────────┘
```

---

## 2. Rate Limiter

### 2.1 Requirements

```
Functional:
  ✦ Limit # of requests a client can make in a time window
  ✦ Support multiple rules (per user, per IP, per API)
  ✦ Return 429 Too Many Requests when limit exceeded
  ✦ Support different algorithms (Fixed Window, Sliding Window, Token Bucket)

Non-Functional:
  ✦ Ultra-low latency (< 1 ms overhead)
  ✦ Distributed (works across multiple servers)
  ✦ Accurate counting (minimal race conditions)
  ✦ Fault-tolerant (if limiter fails → allow traffic)
```

### 2.2 High-Level Architecture

```
                     ┌──────────────┐
                     │   Clients    │
                     └──────┬───────┘
                            │
                     ┌──────▼───────┐
                     │ Load Balancer│
                     └──────┬───────┘
                            │
              ┌─────────────▼──────────────┐
              │     Rate Limiter Layer      │
              │  (Middleware / API Gateway) │
              │                            │
              │  ┌──────────────────────┐  │
              │  │  Rate Limit Rules    │  │
              │  │  Engine              │  │
              │  │  ┌────────────────┐  │  │
              │  │  │ Token Bucket   │  │  │
              │  │  │ Sliding Window │  │  │
              │  │  │ Fixed Window   │  │  │
              │  │  │ Leaky Bucket   │  │  │
              │  │  └────────────────┘  │  │
              │  └──────────┬───────────┘  │
              └─────────────┼──────────────┘
                            │
                     ┌──────▼───────┐
                     │ Redis Cluster │
                     │ (Distributed  │
                     │  Counters)    │
                     └──────┬───────┘
                            │
                   ┌────────▼────────┐
                   │  App Servers    │
                   │  (if allowed)   │
                   └─────────────────┘
```

### 2.3 Algorithms Comparison

```
┌───────────────────┬──────────────┬──────────┬───────────────────────┐
│    Algorithm      │   Memory     │ Accuracy │   Best For            │
├───────────────────┼──────────────┼──────────┼───────────────────────┤
│ Fixed Window      │ Very Low     │ Low      │ Simple use cases      │
│ Sliding Window Log│ High         │ High     │ Strict accuracy       │
│ Sliding Window    │ Low          │ Medium   │ Best balance          │
│   Counter         │              │          │                       │
│ Token Bucket      │ Low          │ High     │ Bursty traffic OK     │
│ Leaky Bucket      │ Low          │ High     │ Smooth output rate    │
└───────────────────┴──────────────┴──────────┴───────────────────────┘
```

### 2.4 Algorithm Visual Explanations

```
TOKEN BUCKET:
═══════════════════════════════════════════════════
  Tokens added at fixed rate (e.g., 10/sec)
  Bucket has max capacity (e.g., 20 tokens)
  Each request consumes 1 token
  No token = rejected

    ┌─────────┐
    │ ● ● ● ● │ ← Bucket (capacity=10)
    │ ● ● ● ● │   Currently 8 tokens
    │         │
    └────┬────┘
         │ ↑ Refill: 2 tokens/sec
    ─────▼────
    Request arrives → take 1 token → ALLOW
    No tokens left → REJECT (429)


SLIDING WINDOW LOG:
═══════════════════════════════════════════════════
  Keep timestamp of every request
  Window slides with current time
  Count requests in window

  Time ──────────────────────────────────────▶
       |←───── 1 minute window ─────→|
  ─────[──×──×───×──×──×───×──×──]──────────
        7 requests in window
        Limit = 10 → ALLOW

SLIDING WINDOW COUNTER:
═══════════════════════════════════════════════════
  Weighted count across current + previous window

  Previous Window    Current Window
  ┌───────────┐     ┌───────────┐
  │  12 reqs  │     │  4 reqs   │
  └───────────┘     └───────────┘
       25%               75%      ← position in current window

  Weighted count = 12 × 0.25 + 4 × 0.75 = 3 + 3 = 6
  Limit = 10 → ALLOW (6 < 10)

LEAKY BUCKET:
═══════════════════════════════════════════════════
  Queue with fixed processing rate
  
    Requests ──▶ ┌─────────┐ ──▶ Processed at
                 │ ● ● ● ● │     fixed rate
                 │ ● ● ● ● │     (e.g., 5/sec)
                 │ ● ●     │
                 └─────────┘
                 Queue full?
                 → Drop request (429)
```

### 2.5 Full Python Implementation

```python
"""
Distributed Rate Limiter — All 4 Algorithms + Middleware
"""
import time
import threading
from abc import ABC, abstractmethod
from collections import defaultdict, deque
from dataclasses import dataclass, field
from typing import Optional, Dict, Tuple
from enum import Enum


# ─────────────────────────────────────────────
# Rate Limiter Configuration
# ─────────────────────────────────────────────
@dataclass
class RateLimitRule:
    """Defines a rate limiting rule."""
    requests: int           # Max requests allowed
    window_seconds: int     # Time window in seconds
    name: str = ""          # Rule name for logging
    
    def __str__(self):
        return f"{self.name}: {self.requests} req / {self.window_seconds}s"


@dataclass
class RateLimitResult:
    """Result of a rate limit check."""
    allowed: bool
    remaining: int        # Remaining requests in window
    limit: int            # Total limit
    retry_after: float    # Seconds to wait (if rejected)
    algorithm: str        # Algorithm used
    
    def headers(self) -> dict:
        """HTTP headers to include in response."""
        h = {
            "X-RateLimit-Limit": str(self.limit),
            "X-RateLimit-Remaining": str(max(0, self.remaining)),
            "X-RateLimit-Algorithm": self.algorithm,
        }
        if not self.allowed:
            h["Retry-After"] = str(int(self.retry_after))
        return h


# ─────────────────────────────────────────────
# Abstract Base Rate Limiter
# ─────────────────────────────────────────────
class RateLimiter(ABC):
    """Base class for all rate limiting algorithms."""
    
    def __init__(self, rule: RateLimitRule):
        self.rule = rule
        self.lock = threading.Lock()
    
    @abstractmethod
    def is_allowed(self, client_id: str) -> RateLimitResult:
        pass
    
    @abstractmethod
    def algorithm_name(self) -> str:
        pass


# ─────────────────────────────────────────────
# Algorithm 1: FIXED WINDOW COUNTER
# ─────────────────────────────────────────────
class FixedWindowLimiter(RateLimiter):
    """
    Divides time into fixed windows and counts requests.
    
    Pros: Simple, low memory
    Cons: Burst at window boundaries (2x allowed traffic)
    
    Example: Limit 10 req/min
      Window [00:00-01:00]: 8 requests → OK
      Window [01:00-02:00]: 0 requests → OK
      
    Edge case problem:
      [00:00─────01:00][01:00─────02:00]
               9 reqs ↗ ↖ 9 reqs
      18 requests in 1 minute window spanning boundary!
    """
    
    def __init__(self, rule: RateLimitRule):
        super().__init__(rule)
        # {client_id: (window_start, count)}
        self.counters: Dict[str, Tuple[float, int]] = {}
    
    def algorithm_name(self) -> str:
        return "Fixed Window"
    
    def _get_window_start(self, now: float) -> float:
        return now - (now % self.rule.window_seconds)
    
    def is_allowed(self, client_id: str) -> RateLimitResult:
        with self.lock:
            now = time.time()
            window_start = self._get_window_start(now)
            
            if client_id not in self.counters:
                self.counters[client_id] = (window_start, 0)
            
            stored_window, count = self.counters[client_id]
            
            # New window → reset counter
            if stored_window != window_start:
                count = 0
                stored_window = window_start
            
            if count < self.rule.requests:
                count += 1
                self.counters[client_id] = (stored_window, count)
                return RateLimitResult(
                    allowed=True,
                    remaining=self.rule.requests - count,
                    limit=self.rule.requests,
                    retry_after=0,
                    algorithm=self.algorithm_name(),
                )
            else:
                retry_after = (stored_window + self.rule.window_seconds) - now
                return RateLimitResult(
                    allowed=False,
                    remaining=0,
                    limit=self.rule.requests,
                    retry_after=max(0, retry_after),
                    algorithm=self.algorithm_name(),
                )


# ─────────────────────────────────────────────
# Algorithm 2: SLIDING WINDOW LOG
# ─────────────────────────────────────────────
class SlidingWindowLogLimiter(RateLimiter):
    """
    Keeps a log of all request timestamps.
    Counts requests in the sliding window.
    
    Pros: Most accurate, no boundary issues
    Cons: High memory (stores every timestamp)
    
    Example: Limit 5 req/min, current time = 01:30
      Log: [01:05, 01:15, 01:20, 01:25, 01:28]
      Window: [00:30, 01:30]
      All 5 in window → at limit, next request REJECTED
    """
    
    def __init__(self, rule: RateLimitRule):
        super().__init__(rule)
        # {client_id: deque of timestamps}
        self.logs: Dict[str, deque] = defaultdict(deque)
    
    def algorithm_name(self) -> str:
        return "Sliding Window Log"
    
    def is_allowed(self, client_id: str) -> RateLimitResult:
        with self.lock:
            now = time.time()
            window_start = now - self.rule.window_seconds
            
            log = self.logs[client_id]
            
            # Remove expired entries
            while log and log[0] <= window_start:
                log.popleft()
            
            if len(log) < self.rule.requests:
                log.append(now)
                return RateLimitResult(
                    allowed=True,
                    remaining=self.rule.requests - len(log),
                    limit=self.rule.requests,
                    retry_after=0,
                    algorithm=self.algorithm_name(),
                )
            else:
                # Earliest request in window determines retry time
                retry_after = log[0] + self.rule.window_seconds - now
                return RateLimitResult(
                    allowed=False,
                    remaining=0,
                    limit=self.rule.requests,
                    retry_after=max(0, retry_after),
                    algorithm=self.algorithm_name(),
                )


# ─────────────────────────────────────────────
# Algorithm 3: SLIDING WINDOW COUNTER
# ─────────────────────────────────────────────
class SlidingWindowCounterLimiter(RateLimiter):
    """
    Hybrid: weighted count from previous + current window.
    
    Pros: Low memory, smooth, good accuracy
    Cons: Approximate (not exact)
    
    Formula:
      weight = requests_prev × (1 - elapsed/window) + requests_curr
    
    Example: Limit 100 req/min
      Previous window (00:00-01:00): 84 requests
      Current window  (01:00-02:00): 36 requests
      Position in current window: 15 seconds (25%)
      
      Weighted = 84 × (1 - 0.25) + 36 = 63 + 36 = 99
      99 < 100 → ALLOW
    """
    
    def __init__(self, rule: RateLimitRule):
        super().__init__(rule)
        # {client_id: {window_key: count}}
        self.windows: Dict[str, Dict[int, int]] = defaultdict(
            lambda: defaultdict(int)
        )
    
    def algorithm_name(self) -> str:
        return "Sliding Window Counter"
    
    def _get_window_key(self, timestamp: float) -> int:
        return int(timestamp // self.rule.window_seconds)
    
    def is_allowed(self, client_id: str) -> RateLimitResult:
        with self.lock:
            now = time.time()
            current_window = self._get_window_key(now)
            previous_window = current_window - 1
            
            # How far into current window (0.0 to 1.0)
            elapsed = (now % self.rule.window_seconds) / self.rule.window_seconds
            
            prev_count = self.windows[client_id].get(previous_window, 0)
            curr_count = self.windows[client_id].get(current_window, 0)
            
            # Weighted count
            weighted = prev_count * (1 - elapsed) + curr_count
            
            if weighted < self.rule.requests:
                self.windows[client_id][current_window] = curr_count + 1
                
                # Cleanup old windows
                keys_to_remove = [
                    k for k in self.windows[client_id] 
                    if k < previous_window
                ]
                for k in keys_to_remove:
                    del self.windows[client_id][k]
                
                new_weighted = prev_count * (1 - elapsed) + curr_count + 1
                remaining = max(0, int(self.rule.requests - new_weighted))
                
                return RateLimitResult(
                    allowed=True,
                    remaining=remaining,
                    limit=self.rule.requests,
                    retry_after=0,
                    algorithm=self.algorithm_name(),
                )
            else:
                retry_after = self.rule.window_seconds * (1 - elapsed)
                return RateLimitResult(
                    allowed=False,
                    remaining=0,
                    limit=self.rule.requests,
                    retry_after=retry_after,
                    algorithm=self.algorithm_name(),
                )


# ─────────────────────────────────────────────
# Algorithm 4: TOKEN BUCKET
# ─────────────────────────────────────────────
class TokenBucketLimiter(RateLimiter):
    """
    Bucket fills with tokens at a steady rate.
    Each request takes 1 token. Empty bucket = rejected.
    
    Pros: Allows bursts, smooth long-term rate, simple
    Cons: Requires storing last_refill time + token count
    
    Parameters:
      - capacity: max tokens (allows burst up to this amount)
      - refill_rate: tokens added per second
    
    Example: capacity=10, refill_rate=2/sec
      t=0:   10 tokens → 5 requests → 5 tokens left
      t=1:   5 + 2 = 7 tokens
      t=5:   7 + 8 = 15 → capped at 10 tokens (capacity)
    """
    
    def __init__(self, rule: RateLimitRule):
        super().__init__(rule)
        self.capacity = rule.requests
        self.refill_rate = rule.requests / rule.window_seconds
        # {client_id: (tokens, last_refill_time)}
        self.buckets: Dict[str, Tuple[float, float]] = {}
    
    def algorithm_name(self) -> str:
        return "Token Bucket"
    
    def _refill(self, client_id: str) -> float:
        """Refill tokens based on elapsed time."""
        now = time.time()
        
        if client_id not in self.buckets:
            self.buckets[client_id] = (self.capacity, now)
            return self.capacity
        
        tokens, last_refill = self.buckets[client_id]
        elapsed = now - last_refill
        new_tokens = min(
            self.capacity,
            tokens + elapsed * self.refill_rate
        )
        self.buckets[client_id] = (new_tokens, now)
        return new_tokens
    
    def is_allowed(self, client_id: str) -> RateLimitResult:
        with self.lock:
            tokens = self._refill(client_id)
            
            if tokens >= 1:
                new_tokens = tokens - 1
                now = time.time()
                self.buckets[client_id] = (new_tokens, now)
                return RateLimitResult(
                    allowed=True,
                    remaining=int(new_tokens),
                    limit=self.capacity,
                    retry_after=0,
                    algorithm=self.algorithm_name(),
                )
            else:
                # Time to wait for 1 token
                retry_after = (1 - tokens) / self.refill_rate
                return RateLimitResult(
                    allowed=False,
                    remaining=0,
                    limit=self.capacity,
                    retry_after=retry_after,
                    algorithm=self.algorithm_name(),
                )


# ─────────────────────────────────────────────
# Algorithm 5: LEAKY BUCKET
# ─────────────────────────────────────────────
class LeakyBucketLimiter(RateLimiter):
    """
    Requests enter a queue (bucket), processed at fixed rate.
    If bucket is full → reject.
    
    Pros: Smooth output rate, prevents bursts
    Cons: Recent requests may wait, burst traffic gets queued
    
    Difference from Token Bucket:
      Token Bucket → controls INPUT rate (allows bursts)
      Leaky Bucket → controls OUTPUT rate (smooths traffic)
    """
    
    def __init__(self, rule: RateLimitRule, queue_size: int = None):
        super().__init__(rule)
        self.queue_size = queue_size or rule.requests
        self.leak_rate = rule.requests / rule.window_seconds
        # {client_id: (queue_count, last_leak_time)}
        self.buckets: Dict[str, Tuple[float, float]] = {}
    
    def algorithm_name(self) -> str:
        return "Leaky Bucket"
    
    def is_allowed(self, client_id: str) -> RateLimitResult:
        with self.lock:
            now = time.time()
            
            if client_id not in self.buckets:
                self.buckets[client_id] = (0, now)
            
            water, last_leak = self.buckets[client_id]
            
            # Leak water based on elapsed time
            elapsed = now - last_leak
            leaked = elapsed * self.leak_rate
            water = max(0, water - leaked)
            
            if water < self.queue_size:
                water += 1
                self.buckets[client_id] = (water, now)
                remaining = int(self.queue_size - water)
                return RateLimitResult(
                    allowed=True,
                    remaining=remaining,
                    limit=self.queue_size,
                    retry_after=0,
                    algorithm=self.algorithm_name(),
                )
            else:
                retry_after = 1.0 / self.leak_rate
                self.buckets[client_id] = (water, now)
                return RateLimitResult(
                    allowed=False,
                    remaining=0,
                    limit=self.queue_size,
                    retry_after=retry_after,
                    algorithm=self.algorithm_name(),
                )


# ─────────────────────────────────────────────
# Distributed Rate Limiter (Multi-Algorithm)
# ─────────────────────────────────────────────
class DistributedRateLimiter:
    """
    Production-grade rate limiter supporting:
    - Multiple algorithms
    - Multiple rules per client
    - Rule hierarchies (global → per-user → per-endpoint)
    
    In production: Uses Redis with Lua scripts for atomicity.
    
    Architecture:
      ┌─────────────────────────────────────────┐
      │        Rate Limiter Middleware           │
      │                                         │
      │  Rules Engine:                          │
      │  ┌─────────────────────────────────┐    │
      │  │ Global:  1000 req/s             │    │
      │  │ Per-IP:  100 req/min            │    │
      │  │ Per-User: 50 req/min            │    │
      │  │ Per-API: /api/shorten: 10/min   │    │
      │  └─────────────────────────────────┘    │
      │                                         │
      │  Client request → check ALL rules       │
      │  ALL pass → allow                       │
      │  ANY fails → reject with 429            │
      └─────────────────────────────────────────┘
    """
    
    def __init__(self):
        self.limiters: Dict[str, RateLimiter] = {}
        self.stats = defaultdict(lambda: {"allowed": 0, "rejected": 0})
    
    def add_rule(self, rule_name: str, rule: RateLimitRule, 
                 algorithm: str = "token_bucket"):
        """Add a rate limiting rule with chosen algorithm."""
        algorithms = {
            "fixed_window": FixedWindowLimiter,
            "sliding_log": SlidingWindowLogLimiter,
            "sliding_counter": SlidingWindowCounterLimiter,
            "token_bucket": TokenBucketLimiter,
            "leaky_bucket": LeakyBucketLimiter,
        }
        
        rule.name = rule_name
        limiter_class = algorithms.get(algorithm, TokenBucketLimiter)
        self.limiters[rule_name] = limiter_class(rule)
        print(f"   📏 Rule added: {rule} [{algorithm}]")
    
    def check(self, client_id: str, 
              rules: list = None) -> RateLimitResult:
        """
        Check all applicable rules.
        Request is allowed only if ALL rules pass.
        """
        rules_to_check = rules or list(self.limiters.keys())
        
        for rule_name in rules_to_check:
            if rule_name not in self.limiters:
                continue
            
            result = self.limiters[rule_name].is_allowed(client_id)
            
            if not result.allowed:
                self.stats[client_id]["rejected"] += 1
                return result
        
        self.stats[client_id]["allowed"] += 1
        
        # Return most restrictive remaining count
        return RateLimitResult(
            allowed=True,
            remaining=result.remaining if rules_to_check else 0,
            limit=result.limit if rules_to_check else 0,
            retry_after=0,
            algorithm=result.algorithm if rules_to_check else "",
        )
    
    def get_client_stats(self, client_id: str) -> dict:
        s = self.stats[client_id]
        total = s["allowed"] + s["rejected"]
        return {
            "client_id": client_id,
            "total_requests": total,
            "allowed": s["allowed"],
            "rejected": s["rejected"],
            "rejection_rate": f"{s['rejected']/total:.1%}" if total > 0 else "0%",
        }


# ─────────────────────────────────────────────
# HTTP Middleware Simulation
# ─────────────────────────────────────────────
class APIServer:
    """Simulates an HTTP API server with rate limiting middleware."""
    
    def __init__(self):
        self.rate_limiter = DistributedRateLimiter()
        self._setup_rules()
    
    def _setup_rules(self):
        print("\n🔧 Setting up rate limit rules:")
        # Global rate limit
        self.rate_limiter.add_rule(
            "global", 
            RateLimitRule(requests=1000, window_seconds=1),
            algorithm="token_bucket"
        )
        # Per-user limit
        self.rate_limiter.add_rule(
            "per_user",
            RateLimitRule(requests=10, window_seconds=60),
            algorithm="sliding_counter"
        )
        # Strict API limit
        self.rate_limiter.add_rule(
            "api_write",
            RateLimitRule(requests=5, window_seconds=60),
            algorithm="sliding_log"
        )
    
    def handle_request(self, client_id: str, 
                       endpoint: str = "/api/data") -> dict:
        """Process an incoming API request."""
        # Determine which rules apply
        rules = ["global", "per_user"]
        if endpoint.startswith("/api/write"):
            rules.append("api_write")
        
        # Rate limit check
        result = self.rate_limiter.check(client_id, rules)
        
        if not result.allowed:
            return {
                "status": 429,
                "error": "Too Many Requests",
                "retry_after": round(result.retry_after, 1),
                "headers": result.headers(),
            }
        
        return {
            "status": 200,
            "data": f"Response for {endpoint}",
            "headers": result.headers(),
        }


# ─────────────────────────────────────────────
# DEMO
# ─────────────────────────────────────────────
if __name__ == "__main__":
    print("="*60)
    print("DEMO: RATE LIMITER — ALL ALGORITHMS")
    print("="*60)
    
    # ── Demo 1: Compare all algorithms ──
    print("\n" + "─"*60)
    print("TEST 1: 15 rapid requests with limit of 10/minute")
    print("─"*60)
    
    algorithms = {
        "Fixed Window":          FixedWindowLimiter,
        "Sliding Window Log":    SlidingWindowLogLimiter,
        "Sliding Window Counter":SlidingWindowCounterLimiter,
        "Token Bucket":          TokenBucketLimiter,
        "Leaky Bucket":          LeakyBucketLimiter,
    }
    
    rule = RateLimitRule(requests=10, window_seconds=60)
    
    for name, cls in algorithms.items():
        limiter = cls(rule)
        allowed = sum(
            1 for _ in range(15)
            if limiter.is_allowed("user_1").allowed
        )
        print(f"   {name:30s} → {allowed}/15 allowed")
    
    # ── Demo 2: Full API Server ──
    print("\n" + "─"*60)
    print("TEST 2: API Server with multi-rule rate limiting")
    print("─"*60)
    
    server = APIServer()
    
    print("\n📨 Sending 15 requests from user 'alice':")
    for i in range(15):
        response = server.handle_request("alice", "/api/data")
        status = "✅" if response["status"] == 200 else "❌"
        extra = ""
        if response["status"] == 429:
            extra = f" (retry in {response['retry_after']}s)"
        print(f"   Request {i+1:2d}: {status} {response['status']}{extra}")
    
    print(f"\n📊 Stats: {server.rate_limiter.get_client_stats('alice')}")
    
    # ── Demo 3: Token Bucket burst behavior ──
    print("\n" + "─"*60)
    print("TEST 3: Token Bucket — Burst then refill")
    print("─"*60)
    
    tb = TokenBucketLimiter(RateLimitRule(requests=5, window_seconds=5))
    
    print("   Burst: 7 rapid requests")
    for i in range(7):
        r = tb.is_allowed("user_x")
        print(f"   #{i+1}: {'✅ ALLOW' if r.allowed else '❌ REJECT'}"
              f" remaining={r.remaining}")
    
    print(f"\n   ⏳ Waiting 2 seconds for token refill...")
    time.sleep(2)
    
    print("   After wait:")
    for i in range(3):
        r = tb.is_allowed("user_x")
        print(f"   #{i+1}: {'✅ ALLOW' if r.allowed else '❌ REJECT'}"
              f" remaining={r.remaining}")
```

### 2.6 Redis Lua Script (Production Atomic Operation)

```python
"""
In production, use Redis + Lua for atomic rate limiting.
This prevents race conditions across distributed servers.
"""

SLIDING_WINDOW_LUA = """
-- Redis Lua script for sliding window rate limiter
-- KEYS[1] = rate limit key
-- ARGV[1] = window size (seconds)
-- ARGV[2] = max requests
-- ARGV[3] = current timestamp (microseconds)

local key = KEYS[1]
local window = tonumber(ARGV[1])
local limit = tonumber(ARGV[2])
local now = tonumber(ARGV[3])
local window_start = now - (window * 1000000)

-- Remove expired entries
redis.call('ZREMRANGEBYSCORE', key, '-inf', window_start)

-- Count current entries
local count = redis.call('ZCARD', key)

if count < limit then
    -- Allow: add current timestamp
    redis.call('ZADD', key, now, now .. '-' .. math.random(1000000))
    redis.call('EXPIRE', key, window)
    return {1, limit - count - 1}  -- {allowed, remaining}
else
    return {0, 0}  -- {rejected, remaining=0}
end
"""

# Usage with redis-py:
# result = redis_client.eval(SLIDING_WINDOW_LUA, 1, key, window, limit, now)
```

---

## 3. Distributed Cache (like Redis)

### 3.1 Requirements

```
Functional:
  ✦ GET(key) → value | null               (O(1))
  ✦ SET(key, value, TTL)                   (O(1))
  ✦ DELETE(key)                            (O(1))
  ✦ Support expiration (TTL)
  ✦ Support eviction policies (LRU, LFU, FIFO)
  ✦ Support multiple data types (strings, hashes, lists)

Non-Functional:
  ✦ Sub-millisecond latency (in-memory)
  ✦ High throughput (100K+ ops/sec per node)
  ✦ Horizontal scaling (distribute across nodes)
  ✦ High availability (replication)
  ✦ Partition tolerance (consistent hashing)
```

### 3.2 High-Level Architecture

```
                    ┌──────────────────────────────────────────┐
                    │              Client Library               │
                    │  (Handles routing, serialization,         │
                    │   connection pooling)                     │
                    └─────────────────┬────────────────────────┘
                                      │
                    ┌─────────────────▼────────────────────────┐
                    │        Consistent Hash Ring               │
                    │                                          │
                    │        Node-A          Node-D            │
                    │          ●              ●                │
                    │       ╱                    ╲              │
                    │     ╱        Hash Ring       ╲            │
                    │    ●                          ●          │
                    │  Node-B                    Node-C        │
                    │    ●────── Virtual ──────── ●            │
                    │           Nodes                          │
                    └──────────────────────────────────────────┘
                                      │
            ┌─────────────────────────┼─────────────────────────┐
            │                         │                         │
     ┌──────▼──────┐          ┌──────▼──────┐          ┌──────▼──────┐
     │   Node A    │          │   Node B    │          │   Node C    │
     │ ┌─────────┐ │          │ ┌─────────┐ │          │ ┌─────────┐ │
     │ │ Memory  │ │          │ │ Memory  │ │          │ │ Memory  │ │
     │ │ Store   │ │          │ │ Store   │ │          │ │ Store   │ │
     │ ├─────────┤ │          │ ├─────────┤ │          │ ├─────────┤ │
     │ │ Eviction│ │          │ │ Eviction│ │          │ │ Eviction│ │
     │ │ Policy  │ │          │ │ Policy  │ │          │ │ Policy  │ │
     │ ├─────────┤ │          │ ├─────────┤ │          │ ├─────────┤ │
     │ │ TTL     │ │          │ │ TTL     │ │          │ │ TTL     │ │
     │ │ Manager │ │          │ │ Manager │ │          │ │ Manager │ │
     │ └─────────┘ │          │ └─────────┘ │          │ └─────────┘ │
     │             │          │             │          │             │
     │ Replica ──▶ │          │ Replica ──▶ │          │ Replica ──▶ │
     │  Node A'    │          │  Node B'    │          │  Node C'    │
     └─────────────┘          └─────────────┘          └─────────────┘
```

### 3.3 Core Concepts

```
CONSISTENT HASHING:
═══════════════════════════════════════════════════

Problem with simple hash (hash(key) % N):
  Adding/removing a node remaps almost ALL keys!

Consistent Hashing Solution:
  • Map both nodes AND keys onto a ring (0 to 2^32)
  • Key is stored on the NEXT node clockwise
  • Adding/removing a node only affects K/N keys

                    0
                    │
              ┌─────●─────┐
         N4 ●─┤           ├─● N1
              │   Ring     │
         K3 ×─┤  (2^32)   ├─× K1
              │           │
         N3 ●─┤           ├─● N2
              └─────●─────┘
                  K2 ×
                    
  K1 → N1 (next clockwise node)
  K2 → N3
  K3 → N4

Virtual Nodes:
  Each physical node gets ~150 virtual positions
  → More uniform distribution of keys


EVICTION POLICIES:
═══════════════════════════════════════════════════
  • LRU  (Least Recently Used)  — most popular
  • LFU  (Least Frequently Used)
  • FIFO (First In, First Out)
  • Random
  • TTL-based (evict expired first)

  Redis uses approximated LRU:
    - Sample 5 random keys
    - Evict the one with oldest access time
    - More efficient than true LRU (O(1) vs O(n))
```

### 3.4 Full Python Implementation

```python
"""
Distributed Cache System — Full Implementation
Features: Consistent Hashing, LRU/LFU Eviction, TTL, Replication
"""
import hashlib
import time
import bisect
import threading
from collections import OrderedDict, defaultdict
from dataclasses import dataclass, field
from typing import Any, Optional, Dict, List, Tuple
from enum import Enum


# ─────────────────────────────────────────────
# Component 1: Consistent Hash Ring
# ─────────────────────────────────────────────
class ConsistentHashRing:
    """
    Maps keys to nodes using consistent hashing.
    
    How it works:
    1. Each node gets multiple positions (virtual nodes) on a ring
    2. To find which node owns a key:
       - Hash the key to a position on the ring
       - Walk clockwise to find the nearest node
    
    When a node is added/removed, only keys between it and the
    previous node are affected (~K/N keys instead of all keys).
    """
    
    def __init__(self, virtual_nodes: int = 150):
        self.virtual_nodes = virtual_nodes
        self.ring: Dict[int, str] = {}      # hash → node_id
        self.sorted_hashes: List[int] = []   # sorted ring positions
        self.nodes: set = set()              # physical nodes
    
    def _hash(self, key: str) -> int:
        """MD5 hash → integer position on ring (0 to 2^32)."""
        digest = hashlib.md5(key.encode()).hexdigest()
        return int(digest[:8], 16)
    
    def add_node(self, node_id: str):
        """Add a node with virtual_nodes positions on the ring."""
        self.nodes.add(node_id)
        for i in range(self.virtual_nodes):
            virtual_key = f"{node_id}:vn{i}"
            hash_val = self._hash(virtual_key)
            self.ring[hash_val] = node_id
            bisect.insort(self.sorted_hashes, hash_val)
    
    def remove_node(self, node_id: str):
        """Remove all virtual nodes for a physical node."""
        self.nodes.discard(node_id)
        for i in range(self.virtual_nodes):
            virtual_key = f"{node_id}:vn{i}"
            hash_val = self._hash(virtual_key)
            if hash_val in self.ring:
                del self.ring[hash_val]
                self.sorted_hashes.remove(hash_val)
    
    def get_node(self, key: str) -> Optional[str]:
        """Find the node responsible for a given key."""
        if not self.ring:
            return None
        
        hash_val = self._hash(key)
        # Find the first node clockwise on the ring
        idx = bisect.bisect_right(self.sorted_hashes, hash_val)
        if idx == len(self.sorted_hashes):
            idx = 0  # Wrap around
        
        return self.ring[self.sorted_hashes[idx]]
    
    def get_nodes_for_replication(self, key: str, 
                                  replicas: int = 2) -> List[str]:
        """Get multiple distinct nodes for replication."""
        if not self.ring:
            return []
        
        nodes = []
        hash_val = self._hash(key)
        idx = bisect.bisect_right(self.sorted_hashes, hash_val)
        
        seen = set()
        for _ in range(len(self.sorted_hashes)):
            if idx >= len(self.sorted_hashes):
                idx = 0
            node = self.ring[self.sorted_hashes[idx]]
            if node not in seen:
                nodes.append(node)
                seen.add(node)
                if len(nodes) >= replicas + 1:
                    break
            idx += 1
        
        return nodes


# ─────────────────────────────────────────────
# Component 2: Cache Entry
# ─────────────────────────────────────────────
@dataclass
class CacheEntry:
    key: str
    value: Any
    created_at: float = field(default_factory=time.time)
    last_accessed: float = field(default_factory=time.time)
    ttl: Optional[float] = None  # seconds
    access_count: int = 0
    size_bytes: int = 0
    
    @property
    def is_expired(self) -> bool:
        if self.ttl is None:
            return False
        return time.time() > self.created_at + self.ttl
    
    @property
    def expires_in(self) -> Optional[float]:
        if self.ttl is None:
            return None
        remaining = (self.created_at + self.ttl) - time.time()
        return max(0, remaining)
    
    def touch(self):
        self.last_accessed = time.time()
        self.access_count += 1


# ─────────────────────────────────────────────
# Component 3: Eviction Policies
# ─────────────────────────────────────────────
class EvictionPolicy(Enum):
    LRU = "lru"         # Least Recently Used
    LFU = "lfu"         # Least Frequently Used
    FIFO = "fifo"       # First In, First Out
    RANDOM = "random"   # Random eviction


class LRUStore:
    """
    LRU Eviction — evicts least recently accessed item.
    
    Implementation: OrderedDict
      - Access (get/set) moves item to end
      - Eviction removes from front
      - All operations O(1)
    
    How Redis does it (Approximated LRU):
      - Doesn't track access order of ALL keys
      - Samples 5 random keys, evicts the oldest one
      - Memory efficient but approximate
    """
    
    def __init__(self, max_size: int = 1000):
        self.max_size = max_size
        self.store: OrderedDict[str, CacheEntry] = OrderedDict()
        self.lock = threading.RLock()
        
        # Stats
        self.hits = 0
        self.misses = 0
        self.evictions = 0
    
    def get(self, key: str) -> Optional[CacheEntry]:
        with self.lock:
            if key not in self.store:
                self.misses += 1
                return None
            
            entry = self.store[key]
            
            # Check expiration
            if entry.is_expired:
                del self.store[key]
                self.misses += 1
                return None
            
            # Move to end (most recently used)
            self.store.move_to_end(key)
            entry.touch()
            self.hits += 1
            return entry
    
    def set(self, key: str, value: Any, ttl: float = None) -> bool:
        with self.lock:
            if key in self.store:
                self.store.move_to_end(key)
                entry = self.store[key]
                entry.value = value
                entry.ttl = ttl
                entry.created_at = time.time()
                entry.touch()
                return True
            
            # Evict if at capacity
            while len(self.store) >= self.max_size:
                evicted_key, _ = self.store.popitem(last=False)
                self.evictions += 1
            
            entry = CacheEntry(
                key=key, value=value, ttl=ttl,
                size_bytes=len(str(value).encode())
            )
            self.store[key] = entry
            return True
    
    def delete(self, key: str) -> bool:
        with self.lock:
            if key in self.store:
                del self.store[key]
                return True
            return False
    
    def clear(self):
        with self.lock:
            self.store.clear()
    
    def cleanup_expired(self) -> int:
        """Remove expired entries (background task)."""
        with self.lock:
            expired = [
                k for k, v in self.store.items() if v.is_expired
            ]
            for k in expired:
                del self.store[k]
            return len(expired)
    
    @property
    def size(self) -> int:
        return len(self.store)
    
    @property
    def hit_rate(self) -> float:
        total = self.hits + self.misses
        return self.hits / total if total > 0 else 0.0


class LFUStore:
    """
    LFU Eviction — evicts least frequently accessed item.
    Tie-breaker: LRU among items with same frequency.
    """
    
    def __init__(self, max_size: int = 1000):
        self.max_size = max_size
        self.store: Dict[str, CacheEntry] = {}
        self.freq_map: Dict[int, OrderedDict] = defaultdict(OrderedDict)
        self.min_freq = 0
        self.lock = threading.RLock()
        self.hits = 0
        self.misses = 0
        self.evictions = 0
    
    def _update_freq(self, key: str, entry: CacheEntry):
        old_freq = entry.access_count
        entry.touch()  # increments access_count
        new_freq = entry.access_count
        
        # Remove from old frequency bucket
        if old_freq in self.freq_map and key in self.freq_map[old_freq]:
            del self.freq_map[old_freq][key]
            if not self.freq_map[old_freq]:
                del self.freq_map[old_freq]
                if self.min_freq == old_freq:
                    self.min_freq = new_freq
        
        # Add to new frequency bucket
        self.freq_map[new_freq][key] = entry
    
    def get(self, key: str) -> Optional[CacheEntry]:
        with self.lock:
            if key not in self.store:
                self.misses += 1
                return None
            
            entry = self.store[key]
            if entry.is_expired:
                self.delete(key)
                self.misses += 1
                return None
            
            self._update_freq(key, entry)
            self.hits += 1
            return entry
    
    def set(self, key: str, value: Any, ttl: float = None) -> bool:
        with self.lock:
            if self.max_size <= 0:
                return False
            
            if key in self.store:
                entry = self.store[key]
                entry.value = value
                entry.ttl = ttl
                entry.created_at = time.time()
                self._update_freq(key, entry)
                return True
            
            if len(self.store) >= self.max_size:
                # Evict LFU item
                if self.min_freq in self.freq_map:
                    evict_key, _ = self.freq_map[self.min_freq].popitem(
                        last=False
                    )
                    if not self.freq_map[self.min_freq]:
                        del self.freq_map[self.min_freq]
                    del self.store[evict_key]
                    self.evictions += 1
            
            entry = CacheEntry(key=key, value=value, ttl=ttl)
            entry.access_count = 1
            self.store[key] = entry
            self.min_freq = 1
            self.freq_map[1][key] = entry
            return True
    
    def delete(self, key: str) -> bool:
        with self.lock:
            if key not in self.store:
                return False
            entry = self.store[key]
            freq = entry.access_count
            if freq in self.freq_map and key in self.freq_map[freq]:
                del self.freq_map[freq][key]
                if not self.freq_map[freq]:
                    del self.freq_map[freq]
            del self.store[key]
            return True
    
    @property
    def size(self) -> int:
        return len(self.store)
    
    @property
    def hit_rate(self) -> float:
        total = self.hits + self.misses
        return self.hits / total if total > 0 else 0.0


# ─────────────────────────────────────────────
# Component 4: Cache Node (Single Server)
# ─────────────────────────────────────────────
class CacheNode:
    """
    A single cache node (like one Redis instance).
    Holds an in-memory store with eviction and TTL support.
    """
    
    def __init__(self, node_id: str, max_size: int = 10000,
                 eviction: EvictionPolicy = EvictionPolicy.LRU):
        self.node_id = node_id
        self.max_size = max_size
        
        if eviction == EvictionPolicy.LRU:
            self.store = LRUStore(max_size)
        elif eviction == EvictionPolicy.LFU:
            self.store = LFUStore(max_size)
        else:
            self.store = LRUStore(max_size)  # default
        
        self.is_alive = True
    
    def get(self, key: str) -> Optional[Any]:
        if not self.is_alive:
            return None
        entry = self.store.get(key)
        return entry.value if entry else None
    
    def set(self, key: str, value: Any, ttl: float = None) -> bool:
        if not self.is_alive:
            return False
        return self.store.set(key, value, ttl)
    
    def delete(self, key: str) -> bool:
        if not self.is_alive:
            return False
        return self.store.delete(key)
    
    def stats(self) -> dict:
        return {
            "node_id": self.node_id,
            "entries": self.store.size,
            "max_size": self.max_size,
            "hit_rate": f"{self.store.hit_rate:.2%}",
            "hits": self.store.hits,
            "misses": self.store.misses,
            "evictions": self.store.evictions,
            "alive": self.is_alive,
        }


# ─────────────────────────────────────────────
# Component 5: Distributed Cache Cluster
# ─────────────────────────────────────────────
class DistributedCache:
    """
    Distributed cache cluster with consistent hashing.
    
    Features:
    ┌─────────────────────────────────────────────────┐
    │  • Consistent hash ring for key distribution    │
    │  • Replication to N replicas                    │
    │  • Read-from-replica for high throughput        │
    │  • Automatic failover                          │
    │  • Cache-aside, Write-through patterns         │
    │  • TTL + background expiry cleanup             │
    └─────────────────────────────────────────────────┘
    
    Cache Patterns Supported:
    
    Cache-Aside (Lazy Loading):
      App → check cache → miss → query DB → write to cache
    
    Write-Through:
      App → write to cache AND DB simultaneously
    
    Write-Behind (Write-Back):
      App → write to cache → async write to DB (batched)
    """
    
    def __init__(self, num_replicas: int = 1):
        self.ring = ConsistentHashRing(virtual_nodes=150)
        self.nodes: Dict[str, CacheNode] = {}
        self.num_replicas = num_replicas
        self.total_ops = 0
    
    def add_node(self, node_id: str, max_size: int = 10000,
                 eviction: EvictionPolicy = EvictionPolicy.LRU):
        """Add a cache node to the cluster."""
        node = CacheNode(node_id, max_size, eviction)
        self.nodes[node_id] = node
        self.ring.add_node(node_id)
        print(f"   ✅ Node '{node_id}' added (max_size={max_size})")
        return node
    
    def remove_node(self, node_id: str):
        """Remove a node (simulates failure/decommission)."""
        if node_id in self.nodes:
            self.ring.remove_node(node_id)
            del self.nodes[node_id]
            print(f"   ❌ Node '{node_id}' removed")
    
    def get(self, key: str) -> Optional[Any]:
        """
        GET operation:
        1. Hash key → find primary node
        2. Try primary node
        3. If primary fails → try replicas
        """
        self.total_ops += 1
        
        target_nodes = self.ring.get_nodes_for_replication(
            key, self.num_replicas
        )
        
        for node_id in target_nodes:
            if node_id in self.nodes and self.nodes[node_id].is_alive:
                value = self.nodes[node_id].get(key)
                if value is not None:
                    return value
        
        return None
    
    def set(self, key: str, value: Any, ttl: float = None) -> bool:
        """
        SET operation:
        1. Hash key → find primary + replica nodes
        2. Write to primary
        3. Replicate to replica nodes
        """
        self.total_ops += 1
        
        target_nodes = self.ring.get_nodes_for_replication(
            key, self.num_replicas
        )
        
        success = False
        for node_id in target_nodes:
            if node_id in self.nodes and self.nodes[node_id].is_alive:
                self.nodes[node_id].set(key, value, ttl)
                success = True
        
        return success
    
    def delete(self, key: str) -> bool:
        """Delete from primary + all replicas."""
        self.total_ops += 1
        
        target_nodes = self.ring.get_nodes_for_replication(
            key, self.num_replicas
        )
        
        deleted = False
        for node_id in target_nodes:
            if node_id in self.nodes:
                if self.nodes[node_id].delete(key):
                    deleted = True
        
        return deleted
    
    def cluster_stats(self) -> dict:
        total_entries = sum(n.store.size for n in self.nodes.values())
        total_hits = sum(n.store.hits for n in self.nodes.values())
        total_misses = sum(n.store.misses for n in self.nodes.values())
        total_evictions = sum(n.store.evictions for n in self.nodes.values())
        
        return {
            "total_nodes": len(self.nodes),
            "alive_nodes": sum(1 for n in self.nodes.values() if n.is_alive),
            "total_entries": total_entries,
            "total_operations": self.total_ops,
            "total_hits": total_hits,
            "total_misses": total_misses,
            "cluster_hit_rate": (
                f"{total_hits/(total_hits+total_misses):.2%}"
                if (total_hits + total_misses) > 0 else "N/A"
            ),
            "total_evictions": total_evictions,
        }
    
    def key_distribution(self) -> dict:
        """Show how keys are distributed across nodes."""
        return {
            node_id: node.store.size 
            for node_id, node in self.nodes.items()
        }


# ─────────────────────────────────────────────
# Component 6: Cache-Aside Pattern
# ─────────────────────────────────────────────
class CacheAsideService:
    """
    Cache-Aside (Lazy-Loading) Pattern Implementation.
    
    Read Flow:
      1. Check cache
      2. If HIT → return
      3. If MISS → query database
      4. Store result in cache
      5. Return result
    
    Write Flow:
      1. Update database
      2. Invalidate cache (delete, NOT update)
      Why delete? Because update can cause race conditions:
        Thread A reads stale from DB
        Thread B updates DB + cache with new value
        Thread A writes stale value to cache → INCONSISTENCY
    """
    
    def __init__(self, cache: DistributedCache):
        self.cache = cache
        # Simulated database
        self.database: Dict[str, Any] = {}
        self.db_reads = 0
        self.db_writes = 0
    
    def read(self, key: str) -> Optional[Any]:
        """Cache-aside read."""
        # Step 1: Check cache
        cached = self.cache.get(key)
        if cached is not None:
            return cached  # Cache HIT
        
        # Step 2: Cache MISS → query database
        value = self.database.get(key)
        self.db_reads += 1
        
        if value is not None:
            # Step 3: Populate cache
            self.cache.set(key, value, ttl=300)  # 5 min TTL
        
        return value
    
    def write(self, key: str, value: Any):
        """Write-through with cache invalidation."""
        # Step 1: Update database
        self.database[key] = value
        self.db_writes += 1
        
        # Step 2: Invalidate cache (NOT update)
        self.cache.delete(key)
    
    def populate_db(self, data: dict):
        """Seed the database."""
        self.database.update(data)


# ─────────────────────────────────────────────
# DEMO
# ─────────────────────────────────────────────
if __name__ == "__main__":
    print("="*60)
    print("DEMO: DISTRIBUTED CACHE")
    print("="*60)
    
    # ── Create cluster ──
    print("\n🏗️  Creating cluster with 4 nodes:")
    cache = DistributedCache(num_replicas=1)
    for i in range(4):
        cache.add_node(f"node-{i}", max_size=1000)
    
    # ── Basic operations ──
    print("\n📝 Basic Operations:")
    cache.set("user:1001", {"name": "Alice", "age": 30}, ttl=60)
    cache.set("user:1002", {"name": "Bob", "age": 25}, ttl=60)
    cache.set("session:abc", "active", ttl=30)
    
    print(f"   GET user:1001 = {cache.get('user:1001')}")
    print(f"   GET user:1002 = {cache.get('user:1002')}")
    print(f"   GET missing    = {cache.get('nonexistent')}")
    
    # ── Bulk insert ──
    print("\n📦 Inserting 500 keys:")
    for i in range(500):
        cache.set(f"product:{i}", f"Product #{i}", ttl=120)
    
    # ── Distribution ──
    print("\n📊 Key Distribution Across Nodes:")
    dist = cache.key_distribution()
    total = sum(dist.values())
    for node_id, count in sorted(dist.items()):
        bar = "█" * (count // 5)
        pct = count / total * 100 if total > 0 else 0
        print(f"   {node_id}: {count:4d} keys ({pct:.1f}%) {bar}")
    
    # ── Node stats ──
    print("\n📈 Per-Node Stats:")
    for node_id, node in cache.nodes.items():
        s = node.stats()
        print(f"   {node_id}: entries={s['entries']}, "
              f"hits={s['hits']}, misses={s['misses']}, "
              f"hit_rate={s['hit_rate']}")
    
    # ── Simulate node failure ──
    print("\n💥 Simulating node-2 failure:")
    cache.nodes["node-2"].is_alive = False
    val = cache.get("product:42")
    print(f"   GET product:42 (with node-2 down) = {val}")
    
    # ── Cache-Aside Pattern ──
    print("\n" + "─"*60)
    print("CACHE-ASIDE PATTERN:")
    print("─"*60)
    
    service = CacheAsideService(cache)
    service.populate_db({
        "user:alice": {"name": "Alice", "role": "admin"},
        "user:bob": {"name": "Bob", "role": "user"},
        "config:theme": "dark",
    })
    
    # First read → cache MISS → hits DB
    print("\n   First read (cold cache):")
    val = service.read("user:alice")
    print(f"   user:alice = {val} (DB reads: {service.db_reads})")
    
    # Second read → cache HIT
    print("   Second read (warm cache):")
    val = service.read("user:alice")
    print(f"   user:alice = {val} (DB reads: {service.db_reads})")
    
    # Write → invalidates cache
    print("\n   Update user:alice → invalidate cache:")
    service.write("user:alice", {"name": "Alice", "role": "superadmin"})
    
    # Next read → cache MISS again → fresh from DB
    val = service.read("user:alice")
    print(f"   user:alice = {val} (DB reads: {service.db_reads})")
    
    # ── Cluster stats ──
    print(f"\n⚙️  Cluster Stats:")
    for k, v in cache.cluster_stats().items():
        print(f"   {k}: {v}")
    
    # ── Consistent Hashing Demo ──
    print("\n" + "─"*60)
    print("CONSISTENT HASHING — Node Add/Remove Impact:")
    print("─"*60)
    
    ring = ConsistentHashRing(virtual_nodes=150)
    ring.add_node("A")
    ring.add_node("B")
    ring.add_node("C")
    
    # Map 100 keys
    before = {}
    for i in range(100):
        key = f"key:{i}"
        before[key] = ring.get_node(key)
    
    # Add a new node
    ring.add_node("D")
    
    # Check how many keys moved
    moved = 0
    for key, old_node in before.items():
        new_node = ring.get_node(key)
        if old_node != new_node:
            moved += 1
    
    print(f"   Adding node 'D' to 3-node cluster:")
    print(f"   Keys remapped: {moved}/100 ({moved}%)")
    print(f"   Expected (K/N): ~{100//4}%")
    print(f"   → Only affected fraction of keys! ✅")
    
    # ── LRU vs LFU comparison ──
    print("\n" + "─"*60)
    print("LRU vs LFU EVICTION COMPARISON:")
    print("─"*60)
    
    lru = LRUStore(max_size=5)
    lfu = LFUStore(max_size=5)
    
    # Fill both caches
    for i in range(5):
        lru.set(f"k{i}", f"v{i}")
        lfu.set(f"k{i}", f"v{i}")
    
    # Access k0 many times (making it "hot")
    for _ in range(10):
        lru.get("k0")
        lfu.get("k0")
    
    # Access k1 once (recent but not frequent)
    lru.get("k1")
    lfu.get("k1")
    
    # Insert new key → triggers eviction
    lru.set("k_new", "new_value")
    lfu.set("k_new", "new_value")
    
    lru_keys = set(lru.store.keys())
    lfu_keys = set(lfu.store.keys())
    
    print(f"   After inserting 'k_new' into full cache (size=5):")
    print(f"   LRU kept: {sorted(lru_keys)} (evicted least recently used)")
    print(f"   LFU kept: {sorted(lfu_keys)} (evicted least frequently used)")
```

---

## 4. Message Queue System (like Apache Kafka)

### 4.1 Requirements

```
Functional:
  ✦ Producers publish messages to named topics
  ✦ Topics are divided into partitions (parallelism)
  ✦ Consumers subscribe to topics via consumer groups
  ✦ Message ordering guaranteed WITHIN a partition
  ✦ Messages persisted (replay capability)
  ✦ At-least-once / at-most-once / exactly-once delivery

Non-Functional:
  ✦ High throughput (millions of messages/sec)
  ✦ Low latency (< 10ms)
  ✦ Fault-tolerant (replication, no data loss)
  ✦ Horizontally scalable
  ✦ Durable (messages survive broker failure)
```

### 4.2 Core Concepts

```
TOPIC:
  A logical channel/category for messages
  Example: "user-events", "order-updates", "logs"

PARTITION:
  A topic is split into N partitions for parallelism
  Messages within a partition are ORDERED
  Each partition lives on ONE broker (leader)
  
  Topic: "orders" (3 partitions)
  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐
  │ Partition-0   │ │ Partition-1   │ │ Partition-2   │
  │ [0][1][2][3]  │ │ [0][1][2]    │ │ [0][1][2][3] │
  │  ← oldest      │ │              │ │    newest →   │
  └──────────────┘ └──────────────┘ └──────────────┘

OFFSET:
  Sequential ID for each message in a partition
  Consumers track their position via offset

CONSUMER GROUP:
  A group of consumers that share the work:
  • Each partition assigned to exactly ONE consumer in the group
  • Different groups get ALL messages independently
  
  Consumer Group A:              Consumer Group B:
  ┌────────┐ ┌────────┐        ┌────────┐
  │ C1: P0 │ │ C2: P1 │        │ C1: P0 │
  │     P2 │ │        │        │    P1   │
  └────────┘ └────────┘        │    P2   │
  (2 consumers share 3          └────────┘
   partitions)                  (1 consumer reads all)

BROKER:
  A single server in the Kafka cluster
  Hosts partition leaders and replicas
  
  Cluster of 3 brokers:
  ┌──────────┐  ┌──────────┐  ┌──────────┐
  │ Broker 0 │  │ Broker 1 │  │ Broker 2 │
  │ P0(L)    │  │ P1(L)    │  │ P2(L)    │
  │ P1(R)    │  │ P2(R)    │  │ P0(R)    │
  └──────────┘  └──────────┘  └──────────┘
  L = Leader, R = Replica
```

### 4.3 High-Level Architecture

```
 Producers                    Kafka Cluster                 Consumers
 ─────────                    ─────────────                 ─────────
                        ┌──────────────────────┐
 ┌──────┐              │   ┌──────────────┐   │           ┌──────────┐
 │Prod-1│──────┐       │   │  Broker 0    │   │    ┌─────▶│Consumer-1│
 └──────┘      │       │   │ ┌──────────┐ │   │    │      │ Group A  │
               │       │   │ │ Topic:    │ │   │    │      └──────────┘
 ┌──────┐      ▼       │   │ │ orders   │ │   │    │
 │Prod-2│──▶ ┌────┐    │   │ │ P0 ████ │ │   │    │      ┌──────────┐
 └──────┘    │ LB │────│──▶│ │ P1 ██   │ │   │────│─────▶│Consumer-2│
             └────┘    │   │ └──────────┘ │   │    │      │ Group A  │
 ┌──────┐      ▲       │   └──────────────┘   │    │      └──────────┘
 │Prod-3│──────┘       │                      │    │
 └──────┘              │   ┌──────────────┐   │    │      ┌──────────┐
                       │   │  Broker 1    │   │    └─────▶│Consumer-3│
                       │   │ ┌──────────┐ │   │           │ Group B  │
                       │   │ │ P2 ███   │ │   │           └──────────┘
                       │   │ │ (replica) │ │   │
                       │   │ └──────────┘ │   │
                       │   └──────────────┘   │
                       │                      │
                       │   ┌──────────────┐   │
                       │   │ ZooKeeper /  │   │
                       │   │ KRaft        │   │
                       │   │ (Metadata)   │   │
                       │   └──────────────┘   │
                       └──────────────────────┘
```

### 4.4 Full Python Implementation

```python
"""
Distributed Message Queue System (Kafka-like)
Features: Topics, Partitions, Consumer Groups, Offsets, 
          Replication, Ordering Guarantees
"""
import time
import hashlib
import threading
from collections import defaultdict, deque
from dataclasses import dataclass, field
from typing import Any, Optional, Dict, List, Callable, Set, Tuple
from enum import Enum
import json
from queue import Queue
import uuid


# ─────────────────────────────────────────────
# Component 1: Message
# ─────────────────────────────────────────────
@dataclass
class Message:
    """
    A single message in the queue.
    
    Fields mirror Kafka's ProducerRecord:
    - key: Used for partition routing (same key → same partition)
    - value: The actual payload
    - topic: Which topic this belongs to
    - partition: Assigned partition number
    - offset: Sequential ID within the partition
    - timestamp: When the message was produced
    - headers: Optional metadata
    """
    key: Optional[str]
    value: Any
    topic: str = ""
    partition: int = -1
    offset: int = -1
    timestamp: float = field(default_factory=time.time)
    headers: Dict[str, str] = field(default_factory=dict)
    message_id: str = field(default_factory=lambda: str(uuid.uuid4())[:8])
    
    def serialize(self) -> str:
        return json.dumps({
            "key": self.key,
            "value": self.value,
            "topic": self.topic,
            "partition": self.partition,
            "offset": self.offset,
            "timestamp": self.timestamp,
            "message_id": self.message_id,
        })
    
    def __repr__(self):
        return (f"Message(key={self.key}, value={self.value}, "
                f"P{self.partition}@{self.offset})")


# ─────────────────────────────────────────────
# Component 2: Partition
# ─────────────────────────────────────────────
class Partition:
    """
    An ordered, append-only log of messages.
    
    Like a commit log:
    ┌───┬───┬───┬───┬───┬───┬───┬───┐
    │ 0 │ 1 │ 2 │ 3 │ 4 │ 5 │ 6 │ 7 │ ← offsets
    └───┴───┴───┴───┴───┴───┴───┴───┘
      │                           │
      oldest                    newest (write position)
    
    Key properties:
    - Append-only (immutable once written)
    - Messages ordered by offset
    - Consumers track their own offset
    - Messages retained for configurable duration
    """
    
    def __init__(self, topic: str, partition_id: int, 
                 retention_seconds: float = 86400):
        self.topic = topic
        self.partition_id = partition_id
        self.retention_seconds = retention_seconds
        self.messages: List[Message] = []
        self.current_offset = 0
        self.lock = threading.Lock()
        
        # Replication
        self.is_leader = True
        self.replicas: List['Partition'] = []
        
        # Stats
        self.total_writes = 0
        self.total_reads = 0
    
    def append(self, message: Message) -> int:
        """
        Append a message to this partition.
        Returns the assigned offset.
        Thread-safe.
        """
        with self.lock:
            message.partition = self.partition_id
            message.offset = self.current_offset
            message.topic = self.topic
            
            self.messages.append(message)
            offset = self.current_offset
            self.current_offset += 1
            self.total_writes += 1
            
            # Replicate to followers
            for replica in self.replicas:
                replica._replicate(message)
            
            return offset
    
    def _replicate(self, message: Message):
        """Receive a replicated message (follower)."""
        with self.lock:
            msg_copy = Message(
                key=message.key,
                value=message.value,
                topic=message.topic,
                partition=message.partition,
                offset=message.offset,
                timestamp=message.timestamp,
                headers=message.headers.copy(),
            )
            self.messages.append(msg_copy)
            self.current_offset = message.offset + 1
    
    def read(self, offset: int, max_messages: int = 10) -> List[Message]:
        """
        Read messages starting from a given offset.
        Like Kafka's poll().
        """
        with self.lock:
            if offset >= len(self.messages):
                return []
            
            end = min(offset + max_messages, len(self.messages))
            self.total_reads += end - offset
            return self.messages[offset:end]
    
    def latest_offset(self) -> int:
        return self.current_offset
    
    def earliest_offset(self) -> int:
        return 0 if self.messages else -1
    
    def cleanup_expired(self) -> int:
        """Remove messages older than retention period."""
        with self.lock:
            cutoff = time.time() - self.retention_seconds
            before = len(self.messages)
            self.messages = [
                m for m in self.messages if m.timestamp >= cutoff
            ]
            return before - len(self.messages)


# ─────────────────────────────────────────────
# Component 3: Topic
# ─────────────────────────────────────────────
class PartitionStrategy(Enum):
    ROUND_ROBIN = "round_robin"
    KEY_HASH = "key_hash"
    CUSTOM = "custom"


class Topic:
    """
    A logical grouping of messages divided into partitions.
    
    Example: Topic "user-events" with 3 partitions
    
    ┌─────────────────────────────────────────┐
    │  Topic: user-events                      │
    │                                          │
    │  Partition 0: [msg0, msg3, msg6, ...]   │
    │  Partition 1: [msg1, msg4, msg7, ...]   │
    │  Partition 2: [msg2, msg5, msg8, ...]   │
    │                                          │
    │  Partitioning Strategy:                  │
    │  - No key → round-robin                 │
    │  - With key → hash(key) % num_partitions │
    │    (ensures same key → same partition)    │
    └─────────────────────────────────────────┘
    """
    
    def __init__(self, name: str, num_partitions: int = 3,
                 replication_factor: int = 1,
                 retention_seconds: float = 86400):
        self.name = name
        self.num_partitions = num_partitions
        self.replication_factor = replication_factor
        self.partitions: List[Partition] = []
        self.round_robin_counter = 0
        
        # Create partitions
        for i in range(num_partitions):
            self.partitions.append(
                Partition(name, i, retention_seconds)
            )
    
    def get_partition(self, key: Optional[str] = None) -> Partition:
        """
        Determine which partition a message should go to.
        
        - key=None: Round-robin distribution
        - key="user_123": hash(key) % N → deterministic partition
          (ensures all messages for user_123 go to same partition
           → preserves per-user ordering)
        """
        if key is not None:
            # Murmur-like hash for consistent partitioning
            hash_val = int(hashlib.md5(key.encode()).hexdigest(), 16)
            partition_id = hash_val % self.num_partitions
        else:
            partition_id = self.round_robin_counter % self.num_partitions
            self.round_robin_counter += 1
        
        return self.partitions[partition_id]
    
    def total_messages(self) -> int:
        return sum(p.current_offset for p in self.partitions)
    
    def stats(self) -> dict:
        return {
            "topic": self.name,
            "partitions": self.num_partitions,
            "total_messages": self.total_messages(),
            "partition_sizes": [
                p.current_offset for p in self.partitions
            ],
        }


# ─────────────────────────────────────────────
# Component 4: Consumer Group
# ─────────────────────────────────────────────
class Consumer:
    """A single consumer instance."""
    
    def __init__(self, consumer_id: str, group_id: str):
        self.consumer_id = consumer_id
        self.group_id = group_id
        self.assigned_partitions: List[int] = []
        self.is_active = True
        self.messages_consumed = 0


class ConsumerGroup:
    """
    A group of consumers that collaboratively consume from a topic.
    
    Key Rules:
    1. Each partition is assigned to exactly ONE consumer in the group
    2. One consumer can handle multiple partitions
    3. If consumers > partitions, some consumers are idle
    4. Rebalance occurs when consumers join/leave
    
    Example: 3 partitions, 2 consumers
    ┌──────────────┐          ┌──────────────┐
    │ Consumer-1   │          │ Consumer-2   │
    │ → P0, P2     │          │ → P1         │
    └──────────────┘          └──────────────┘
    
    Offset Tracking:
    ┌──────────────────────────────────────┐
    │ Consumer Group: "order-processors"    │
    │                                      │
    │ Offsets:                              │
    │   P0: committed=42, latest=50        │
    │   P1: committed=38, latest=38        │
    │   P2: committed=55, latest=67        │
    │                                      │
    │ Lag = latest - committed             │
    │   P0 lag: 8                          │
    │   P1 lag: 0 (caught up!)             │
    │   P2 lag: 12                         │
    └──────────────────────────────────────┘
    """
    
    def __init__(self, group_id: str, topic: Topic):
        self.group_id = group_id
        self.topic = topic
        self.consumers: Dict[str, Consumer] = {}
        self.committed_offsets: Dict[int, int] = {
            i: 0 for i in range(topic.num_partitions)
        }
        self.lock = threading.Lock()
    
    def add_consumer(self, consumer_id: str) -> Consumer:
        """Add a consumer and trigger rebalance."""
        with self.lock:
            consumer = Consumer(consumer_id, self.group_id)
            self.consumers[consumer_id] = consumer
            self._rebalance()
            return consumer
    
    def remove_consumer(self, consumer_id: str):
        """Remove a consumer and trigger rebalance."""
        with self.lock:
            if consumer_id in self.consumers:
                del self.consumers[consumer_id]
                self._rebalance()
    
    def _rebalance(self):
        """
        Redistribute partitions among active consumers.
        
        Strategy: Range Assignor (like Kafka's default)
        
        Before rebalance (2 consumers, 4 partitions):
          C1: [P0, P1]  C2: [P2, P3]
          
        After C2 leaves (1 consumer):
          C1: [P0, P1, P2, P3]  ← takes over all
        
        After C3 joins (2 consumers again):
          C1: [P0, P1]  C3: [P2, P3]  ← rebalanced
        """
        active = [c for c in self.consumers.values() if c.is_active]
        
        if not active:
            return
        
        # Clear all assignments
        for consumer in active:
            consumer.assigned_partitions = []
        
        # Range assignment
        partitions = list(range(self.topic.num_partitions))
        consumers_count = len(active)
        partitions_per_consumer = len(partitions) // consumers_count
        remainder = len(partitions) % consumers_count
        
        idx = 0
        for i, consumer in enumerate(active):
            count = partitions_per_consumer + (1 if i < remainder else 0)
            consumer.assigned_partitions = partitions[idx:idx + count]
            idx += count
    
    def poll(self, consumer_id: str, 
             max_messages: int = 10) -> List[Message]:
        """
        Poll for new messages (like Kafka's consumer.poll()).
        Returns messages from assigned partitions starting
        from committed offset.
        """
        with self.lock:
            if consumer_id not in self.consumers:
                return []
            
            consumer = self.consumers[consumer_id]
            all_messages = []
            
            for partition_id in consumer.assigned_partitions:
                partition = self.topic.partitions[partition_id]
                offset = self.committed_offsets.get(partition_id, 0)
                
                messages = partition.read(offset, max_messages)
                all_messages.extend(messages)
            
            consumer.messages_consumed += len(all_messages)
            return all_messages
    
    def commit(self, consumer_id: str, 
               partition_id: int, offset: int):
        """Commit offset (acknowledge message processing)."""
        with self.lock:
            self.committed_offsets[partition_id] = offset
    
    def commit_batch(self, consumer_id: str, messages: List[Message]):
        """Commit offsets for a batch of consumed messages."""
        with self.lock:
            for msg in messages:
                current = self.committed_offsets.get(msg.partition, 0)
                self.committed_offsets[msg.partition] = max(
                    current, msg.offset + 1
                )
    
    def lag(self) -> Dict[int, int]:
        """Consumer lag per partition."""
        result = {}
        for pid in range(self.topic.num_partitions):
            latest = self.topic.partitions[pid].latest_offset()
            committed = self.committed_offsets.get(pid, 0)
            result[pid] = max(0, latest - committed)
        return result
    
    def total_lag(self) -> int:
        return sum(self.lag().values())
    
    def assignments_display(self) -> str:
        lines = []
        for cid, consumer in self.consumers.items():
            parts = ", ".join(f"P{p}" for p in consumer.assigned_partitions)
            lines.append(f"     {cid}: [{parts}]")
        return "\n".join(lines)


# ─────────────────────────────────────────────
# Component 5: Producer
# ─────────────────────────────────────────────
class DeliverySemantics(Enum):
    AT_MOST_ONCE = "at_most_once"    # Fire and forget
    AT_LEAST_ONCE = "at_least_once"  # Retry on failure
    EXACTLY_ONCE = "exactly_once"    # Idempotent + transactions


class Producer:
    """
    Message producer (like KafkaProducer).
    
    Sends messages to topics with:
    - Automatic partitioning (by key or round-robin)
    - Batching for throughput
    - Acknowledgment modes
    - Optional callback on delivery
    
    Partitioning ensures ordering:
      produce(key="user_123", value="login")   → P2
      produce(key="user_123", value="purchase") → P2 (same partition!)
      → Consumer sees: login before purchase ✅
    """
    
    def __init__(self, producer_id: str, broker: 'MessageBroker',
                 semantics: DeliverySemantics = DeliverySemantics.AT_LEAST_ONCE):
        self.producer_id = producer_id
        self.broker = broker
        self.semantics = semantics
        self.messages_sent = 0
        self.errors = 0
    
    def send(self, topic_name: str, value: Any, 
             key: str = None, headers: dict = None) -> Optional[Message]:
        """Send a single message to a topic."""
        message = Message(
            key=key,
            value=value,
            headers=headers or {},
        )
        
        try:
            result = self.broker.publish(topic_name, message)
            self.messages_sent += 1
            return result
        except Exception as e:
            self.errors += 1
            if self.semantics == DeliverySemantics.AT_LEAST_ONCE:
                # Retry logic would go here
                pass
            return None
    
    def send_batch(self, topic_name: str, 
                   messages: List[Tuple[str, Any]]) -> List[Message]:
        """Send a batch of (key, value) pairs."""
        results = []
        for key, value in messages:
            result = self.send(topic_name, value, key)
            if result:
                results.append(result)
        return results


# ─────────────────────────────────────────────
# Component 6: Message Broker (Central Coordinator)
# ─────────────────────────────────────────────
class MessageBroker:
    """
    The central message broker (like a Kafka cluster).
    
    Responsibilities:
    ┌────────────────────────────────────────────────┐
    │ • Topic/partition management                    │
    │ • Message routing (producer → partition)        │
    │ • Consumer group coordination                   │
    │ • Offset management                             │
    │ • Replication management                        │
    │ • Retention enforcement                         │
    └────────────────────────────────────────────────┘
    """
    
    def __init__(self, broker_id: str = "broker-0"):
        self.broker_id = broker_id
        self.topics: Dict[str, Topic] = {}
        self.consumer_groups: Dict[str, ConsumerGroup] = {}
        self.lock = threading.Lock()
        self.total_messages = 0
    
    def create_topic(self, name: str, num_partitions: int = 3,
                     replication_factor: int = 1,
                     retention_hours: int = 24) -> Topic:
        """Create a new topic."""
        with self.lock:
            if name in self.topics:
                return self.topics[name]
            
            topic = Topic(
                name=name,
                num_partitions=num_partitions,
                replication_factor=replication_factor,
                retention_seconds=retention_hours * 3600,
            )
            self.topics[name] = topic
            return topic
    
    def publish(self, topic_name: str, message: Message) -> Message:
        """Route a message to the correct partition and append it."""
        if topic_name not in self.topics:
            raise ValueError(f"Topic '{topic_name}' does not exist")
        
        topic = self.topics[topic_name]
        partition = topic.get_partition(message.key)
        partition.append(message)
        self.total_messages += 1
        return message
    
    def create_consumer_group(self, group_id: str, 
                               topic_name: str) -> ConsumerGroup:
        """Create a consumer group for a topic."""
        key = f"{group_id}:{topic_name}"
        if key not in self.consumer_groups:
            if topic_name not in self.topics:
                raise ValueError(f"Topic '{topic_name}' does not exist")
            
            group = ConsumerGroup(group_id, self.topics[topic_name])
            self.consumer_groups[key] = group
        return self.consumer_groups[key]
    
    def list_topics(self) -> List[str]:
        return list(self.topics.keys())
    
    def broker_stats(self) -> dict:
        return {
            "broker_id": self.broker_id,
            "total_topics": len(self.topics),
            "total_partitions": sum(
                t.num_partitions for t in self.topics.values()
            ),
            "total_messages": self.total_messages,
            "total_consumer_groups": len(self.consumer_groups),
            "topic_stats": {
                name: topic.stats() 
                for name, topic in self.topics.items()
            },
        }


# ─────────────────────────────────────────────
# Component 7: Stream Processor (Bonus)
# ─────────────────────────────────────────────
class StreamProcessor:
    """
    Real-time stream processing on top of the message queue.
    
    Patterns:
    ─────────────────────────────────────────────
    Filter:   topic → filter(condition) → output_topic
    Map:      topic → transform(fn) → output_topic
    Aggregate: topic → group_by(key) → count/sum → output_topic
    Join:     topicA + topicB → join(key) → output_topic
    """
    
    def __init__(self, broker: MessageBroker, processor_id: str):
        self.broker = broker
        self.processor_id = processor_id
    
    def filter_and_forward(self, source_topic: str, 
                           dest_topic: str,
                           predicate: Callable[[Message], bool],
                           group_id: str = "stream_processor"):
        """Filter messages and forward matching ones."""
        if dest_topic not in self.broker.topics:
            self.broker.create_topic(dest_topic)
        
        group = self.broker.create_consumer_group(group_id, source_topic)
        consumer = group.add_consumer(f"{self.processor_id}_filter")
        
        messages = group.poll(consumer.consumer_id, max_messages=100)
        forwarded = 0
        
        for msg in messages:
            if predicate(msg):
                self.broker.publish(dest_topic, Message(
                    key=msg.key, 
                    value=msg.value,
                    headers={**msg.headers, "source": source_topic},
                ))
                forwarded += 1
        
        group.commit_batch(consumer.consumer_id, messages)
        return forwarded
    
    def map_transform(self, source_topic: str,
                      dest_topic: str,
                      transform_fn: Callable[[Any], Any],
                      group_id: str = "stream_processor"):
        """Transform messages and forward to destination."""
        if dest_topic not in self.broker.topics:
            self.broker.create_topic(dest_topic)
        
        group = self.broker.create_consumer_group(group_id, source_topic)
        consumer = group.add_consumer(f"{self.processor_id}_map")
        
        messages = group.poll(consumer.consumer_id, max_messages=100)
        
        for msg in messages:
            transformed = transform_fn(msg.value)
            self.broker.publish(dest_topic, Message(
                key=msg.key, value=transformed
            ))
        
        group.commit_batch(consumer.consumer_id, messages)
        return len(messages)


# ─────────────────────────────────────────────
# DEMO
# ─────────────────────────────────────────────
if __name__ == "__main__":
    print("="*60)
    print("DEMO: MESSAGE QUEUE SYSTEM (KAFKA-LIKE)")
    print("="*60)
    
    # ── Create Broker ──
    broker = MessageBroker("broker-0")
    
    # ── Create Topics ──
    print("\n📋 Creating Topics:")
    broker.create_topic("user-events", num_partitions=3)
    broker.create_topic("order-events", num_partitions=4)
    broker.create_topic("notifications", num_partitions=2)
    for topic_name in broker.list_topics():
        t = broker.topics[topic_name]
        print(f"   ✅ {topic_name} ({t.num_partitions} partitions)")
    
    # ── Create Producer ──
    print("\n📤 Producing Messages:")
    producer = Producer("producer-1", broker)
    
    # Send user events (keyed by user_id for ordering)
    events = [
        ("user_100", {"action": "login", "ip": "10.0.0.1"}),
        ("user_200", {"action": "login", "ip": "10.0.0.2"}),
        ("user_100", {"action": "view_page", "page": "/home"}),
        ("user_300", {"action": "login", "ip": "10.0.0.3"}),
        ("user_100", {"action": "purchase", "item": "laptop"}),
        ("user_200", {"action": "view_page", "page": "/products"}),
        ("user_100", {"action": "logout"}),
        ("user_200", {"action": "purchase", "item": "phone"}),
    ]
    
    for key, value in events:
        msg = producer.send("user-events", value, key=key)
        print(f"   → {key}: {value['action']:15s} → "
              f"P{msg.partition}@{msg.offset}")
    
    # Show partition assignment by key
    print("\n🔑 Key → Partition Mapping (ensures ordering per user):")
    partition_keys = defaultdict(list)
    for p in broker.topics["user-events"].partitions:
        for msg in p.messages:
            partition_keys[p.partition_id].append(msg.key)
    
    for pid, keys in sorted(partition_keys.items()):
        print(f"   P{pid}: {keys}")
    
    # ── Consumer Groups ──
    print("\n" + "─"*60)
    print("CONSUMER GROUPS:")
    print("─"*60)
    
    # Group A: 2 consumers
    print("\n👥 Group A (2 consumers for 3 partitions):")
    group_a = broker.create_consumer_group("analytics-team", "user-events")
    c1 = group_a.add_consumer("consumer-1")
    c2 = group_a.add_consumer("consumer-2")
    print(f"   Partition assignments:")
    print(group_a.assignments_display())
    
    # Group B: 1 consumer (independent)
    print("\n👤 Group B (1 consumer — gets ALL messages):")
    group_b = broker.create_consumer_group("audit-logger", "user-events")
    c3 = group_b.add_consumer("audit-consumer-1")
    print(f"   Partition assignments:")
    print(group_b.assignments_display())
    
    # ── Poll and Consume ──
    print("\n📥 Consumer-1 (Group A) polling:")
    messages = group_a.poll("consumer-1", max_messages=10)
    for msg in messages:
        print(f"   ← P{msg.partition}@{msg.offset}: "
              f"key={msg.key}, action={msg.value.get('action', '?')}")
    
    # Commit offsets
    group_a.commit_batch("consumer-1", messages)
    
    print(f"\n📥 Consumer-2 (Group A) polling:")
    messages = group_a.poll("consumer-2", max_messages=10)
    for msg in messages:
        print(f"   ← P{msg.partition}@{msg.offset}: "
              f"key={msg.key}, action={msg.value.get('action', '?')}")
    group_a.commit_batch("consumer-2", messages)
    
    # ── Consumer Group B gets SAME messages ──
    print(f"\n📥 Audit Consumer (Group B) — independent copy:")
    messages = group_b.poll("audit-consumer-1", max_messages=20)
    print(f"   Received {len(messages)} messages (same data, "
          f"independent offset)")
    group_b.commit_batch("audit-consumer-1", messages)
    
    # ── Consumer Lag ──
    print("\n📊 Consumer Lag:")
    print(f"   Group A lag: {group_a.lag()} "
          f"(total: {group_a.total_lag()})")
    print(f"   Group B lag: {group_b.lag()} "
          f"(total: {group_b.total_lag()})")
    
    # ── Rebalance Demo ──
    print("\n" + "─"*60)
    print("REBALANCE DEMO:")
    print("─"*60)
    
    print("\n   Before: 2 consumers")
    print(group_a.assignments_display())
    
    print("\n   Adding consumer-3...")
    group_a.add_consumer("consumer-3")
    print(group_a.assignments_display())
    
    print("\n   Removing consumer-1 (simulating crash)...")
    group_a.remove_consumer("consumer-1")
    print(group_a.assignments_display())
    
    # ── Stream Processing ──
    print("\n" + "─"*60)
    print("STREAM PROCESSING:")
    print("─"*60)
    
    # Produce more events
    for i in range(20):
        producer.send("order-events", {
            "order_id": f"ORD-{i}",
            "amount": (i + 1) * 15.99,
            "status": "completed" if i % 3 != 0 else "failed",
        }, key=f"customer_{i % 5}")
    
    processor = StreamProcessor(broker, "stream-proc-1")
    
    # Filter: only completed orders
    forwarded = processor.filter_and_forward(
        source_topic="order-events",
        dest_topic="completed-orders",
        predicate=lambda msg: msg.value.get("status") == "completed",
        group_id="filter_processor",
    )
    print(f"\n   Filter (completed orders): {forwarded} messages forwarded")
    
    # Map: extract amounts
    transformed = processor.map_transform(
        source_topic="order-events",
        dest_topic="order-amounts",
        transform_fn=lambda v: {"amount": v.get("amount", 0),
                                 "is_large": v.get("amount", 0) > 50},
        group_id="map_processor",
    )
    print(f"   Map (extract amounts): {transformed} messages transformed")
    
    # ── Broker Stats ──
    print("\n" + "─"*60)
    print("BROKER STATISTICS:")
    print("─"*60)
    stats = broker.broker_stats()
    print(f"   Broker ID:        {stats['broker_id']}")
    print(f"   Total Topics:     {stats['total_topics']}")
    print(f"   Total Partitions: {stats['total_partitions']}")
    print(f"   Total Messages:   {stats['total_messages']}")
    print(f"   Consumer Groups:  {stats['total_consumer_groups']}")
    
    print(f"\n   Per-Topic Breakdown:")
    for name, ts in stats['topic_stats'].items():
        print(f"   ┌─ {name}")
        print(f"   │  Messages: {ts['total_messages']}")
        print(f"   │  Partitions: {ts['partition_sizes']}")
        print(f"   └──────────────────")
    
    # ── Ordering Guarantee Demo ──
    print("\n" + "─"*60)
    print("ORDERING GUARANTEE DEMO:")
    print("─"*60)
    print("   Same key always goes to same partition:")
    
    broker.create_topic("ordering-test", num_partitions=3)
    for i in range(10):
        msg = producer.send("ordering-test", f"event-{i}", key="same_key")
        print(f"   Event {i} → Partition {msg.partition}")
    
    partition_seen = set()
    for p in broker.topics["ordering-test"].partitions:
        if p.messages:
            partition_seen.add(p.partition_id)
    
    print(f"   All messages landed in partition(s): {partition_seen}")
    print(f"   → Ordering preserved within partition ✅")
```

### 4.5 Kafka Architecture Summary

```
┌──────────────────────────────────────────────────────────┐
│              COMPLETE KAFKA ARCHITECTURE                   │
│                                                           │
│  ┌──────────────────────────────────────────────────┐    │
│  │                 ZooKeeper / KRaft                  │    │
│  │  • Broker registration                            │    │
│  │  • Topic/partition metadata                       │    │
│  │  • Consumer group coordination                    │    │
│  │  • Leader election                                │    │
│  └──────────────────────────────────────────────────┘    │
│                           │                               │
│  ┌─────────┐  ┌──────────▼────────┐  ┌─────────┐        │
│  │Producer │  │  Broker Cluster    │  │Consumer │        │
│  │         │  │                    │  │ Group   │        │
│  │ • batch │──│  Broker-0:         │──│         │        │
│  │ • retry │  │   P0(L), P3(R)    │  │ C1 → P0 │        │
│  │ • acks  │  │                    │  │ C2 → P1 │        │
│  │ • key   │  │  Broker-1:         │  │ C3 → P2 │        │
│  │  routing│  │   P1(L), P0(R)    │  │         │        │
│  │         │  │                    │  │ offset  │        │
│  │ acks:   │  │  Broker-2:         │  │ commit  │        │
│  │  0: fire│  │   P2(L), P1(R)    │  │         │        │
│  │  1: lead│  │                    │  │ poll()  │        │
│  │  all:   │  │  ISR (In-Sync     │  │         │        │
│  │   full  │  │   Replicas)       │  │         │        │
│  └─────────┘  └───────────────────┘  └─────────┘        │
│                                                           │
│  DELIVERY GUARANTEES:                                     │
│  ┌───────────────────────────────────────────────────┐   │
│  │ At-most-once:  Read → commit → process            │   │
│  │                (may lose messages if crash)        │   │
│  │                                                    │   │
│  │ At-least-once: Read → process → commit            │   │
│  │                (may duplicate if crash before      │   │
│  │                 commit; consumer must be idempotent)│   │
│  │                                                    │   │
│  │ Exactly-once:  Idempotent producer +              │   │
│  │                Transactional read-process-write    │   │
│  │                (Kafka Streams supports this)       │   │
│  └───────────────────────────────────────────────────┘   │
│                                                           │
│  WHEN TO USE KAFKA vs RABBITMQ:                           │
│  ┌───────────────────┬───────────────────┐               │
│  │     Kafka         │    RabbitMQ       │               │
│  ├───────────────────┼───────────────────┤               │
│  │ Event streaming   │ Task queues       │               │
│  │ Log aggregation   │ RPC patterns      │               │
│  │ Event sourcing    │ Complex routing   │               │
│  │ High throughput   │ Message priority  │               │
│  │ Replay capability │ Exactly-once easy │               │
│  │ Order guarantee   │ Push-based        │               │
│  └───────────────────┴───────────────────┘               │
└──────────────────────────────────────────────────────────┘
```

---

## Quick Reference: All Four Systems Compared

```
┌─────────────────┬──────────────┬──────────────┬──────────────┬──────────────┐
│   Aspect        │ URL Shortener│ Rate Limiter │ Dist. Cache  │ Message Queue│
├─────────────────┼──────────────┼──────────────┼──────────────┼──────────────┤
│ Primary DB      │ Cassandra/   │ Redis        │ In-Memory    │ Disk (WAL)   │
│                 │ DynamoDB     │              │ (RAM)        │              │
├─────────────────┼──────────────┼──────────────┼──────────────┼──────────────┤
│ Key Algorithm   │ Base62 + KGS │ Token Bucket │ Consistent   │ Partition +  │
│                 │              │ Sliding Win  │ Hashing, LRU │ Offset       │
├─────────────────┼──────────────┼──────────────┼──────────────┼──────────────┤
│ Scaling         │ Sharding by  │ Redis Cluster│ Hash Ring    │ Add          │
│                 │ short_key    │              │ + vnodes     │ partitions   │
├─────────────────┼──────────────┼──────────────┼──────────────┼──────────────┤
│ Consistency     │ Eventual     │ Eventual     │ Eventual     │ Strong (per  │
│                 │              │              │              │ partition)   │
├─────────────────┼──────────────┼──────────────┼──────────────┼──────────────┤
│ Latency Target  │ < 10ms       │ < 1ms        │ < 1ms        │ < 10ms       │
├─────────────────┼──────────────┼──────────────┼──────────────┼──────────────┤
│ Availability    │ 99.99%       │ 99.99%       │ 99.99%       │ 99.95%       │
│                 │              │ (fail-open)  │              │              │
└─────────────────┴──────────────┴──────────────┴──────────────┴──────────────┘
```



# Large Scale System Design (HLD) — Systems 5–8

---

## 5. Design a Distributed Job Scheduler

---

### 5.1 Requirements

```
Functional:
├─ Submit jobs (one-time or recurring/cron)
├─ Cancel / pause / resume jobs
├─ Job priorities & dependencies (DAG)
├─ Retry on failure with back-off
├─ Query job status & history
└─ Distribute work across a pool of workers

Non-Functional:
├─ At-least-once execution guarantee
├─ Horizontal scalability (millions of jobs)
├─ Low scheduling latency (< 1 s for due jobs)
├─ Fault tolerance (no single point of failure)
└─ Consistency (no duplicate firing under normal ops)
```

### 5.2 High-Level Architecture

```
┌────────────────────────────────────────────────────────────────────┐
│                         CLIENTS / API                             │
│          (Submit, Cancel, Query via REST / gRPC)                  │
└──────────────────────────┬─────────────────────────────────────────┘
                           │
                           ▼
              ┌────────────────────────┐
              │      API Gateway       │
              │  (Auth, Rate Limit)    │
              └───────────┬────────────┘
                          │
          ┌───────────────┼───────────────┐
          ▼               ▼               ▼
   ┌─────────────┐ ┌───────────┐  ┌──────────────┐
   │  Job CRUD   │ │  Scheduler│  │   Worker      │
   │  Service    │ │  Service  │  │   Fleet       │
   │             │ │ (Leaders) │  │               │
   └──────┬──────┘ └─────┬─────┘  └──────┬───────┘
          │               │               │
          ▼               ▼               ▼
   ┌─────────────────────────────────────────────┐
   │                  Data Layer                  │
   │  ┌──────────┐  ┌────────┐  ┌─────────────┐  │
   │  │  Job DB  │  │ Queue  │  │  Lock/Coord  │  │
   │  │(Postgres)│  │(Redis/ │  │  (ZooKeeper/ │  │
   │  │          │  │ Kafka) │  │   etcd)      │  │
   │  └──────────┘  └────────┘  └─────────────┘  │
   └─────────────────────────────────────────────┘
```

### 5.3 Core Components Deep-Dive

```
┌──────────────────────────────────────────────────────┐
│                   JOB LIFECYCLE                       │
│                                                      │
│  SUBMITTED ──► SCHEDULED ──► QUEUED ──► RUNNING      │
│                    │                      │    │      │
│                    │                      ▼    │      │
│                    │                   SUCCESS │      │
│                    │                           ▼      │
│                    │                        FAILED    │
│                    │                          │       │
│                    │              (retries?)  │       │
│                    │              ┌───YES─────┘       │
│                    │              ▼                   │
│                    └──────── RETRY_WAIT ──► QUEUED    │
│                                                      │
│  Any state ──► CANCELLED                             │
└──────────────────────────────────────────────────────┘
```

#### Scheduler Service (Leader-based)

```
┌─────────────────────────────────────────────────────────────┐
│               SCHEDULER SERVICE DETAIL                      │
│                                                             │
│  ┌─────────────┐    Leader Election (ZooKeeper / etcd)      │
│  │ Scheduler-1 │◄──────────────────────────────────────┐    │
│  │  (LEADER)   │    ┌─────────────┐  ┌─────────────┐   │   │
│  └──────┬──────┘    │ Scheduler-2 │  │ Scheduler-3 │   │   │
│         │           │ (FOLLOWER)  │  │ (FOLLOWER)  │   │   │
│         │           └─────────────┘  └─────────────┘   │   │
│         │                                               │   │
│         ▼                                               │   │
│  ┌──────────────────────────────────────┐               │   │
│  │  Tick Loop (every 1 second):        │               │   │
│  │                                      │               │   │
│  │  1. Query DB: jobs WHERE             │               │   │
│  │     next_run_at <= NOW()             │               │   │
│  │     AND status = 'SCHEDULED'         │               │   │
│  │     LIMIT 1000                       │               │   │
│  │     FOR UPDATE SKIP LOCKED           │               │   │
│  │                                      │               │   │
│  │  2. For each due job:                │               │   │
│  │     - Push to task queue             │               │   │
│  │     - Update status → QUEUED         │               │   │
│  │     - If recurring: compute          │               │   │
│  │       next_run_at from cron expr     │               │   │
│  │       & insert new SCHEDULED row     │               │   │
│  │                                      │               │   │
│  │  3. Heartbeat to ZooKeeper           │               │   │
│  └──────────────────────────────────────┘               │   │
│                                                         │   │
│  On leader failure → ZK triggers re-election ───────────┘   │
└─────────────────────────────────────────────────────────────┘
```

#### Partitioned Scheduler (Scale-Out)

```
┌──────────────────────────────────────────────────────────┐
│          PARTITIONED SCHEDULING (Large Scale)            │
│                                                          │
│   Jobs are hash-partitioned by job_id into N shards      │
│                                                          │
│   Shard 0        Shard 1        Shard 2       Shard 3   │
│  ┌────────┐    ┌────────┐    ┌────────┐    ┌────────┐   │
│  │Sched-A │    │Sched-B │    │Sched-C │    │Sched-D │   │
│  │(Leader)│    │(Leader)│    │(Leader)│    │(Leader)│   │
│  └───┬────┘    └───┬────┘    └───┬────┘    └───┬────┘   │
│      │             │             │             │         │
│      ▼             ▼             ▼             ▼         │
│  Jobs 0-24k   Jobs 25-49k   Jobs 50-74k  Jobs 75-99k   │
│                                                          │
│  Each shard has its own leader election                  │
│  Rebalancing on node add/remove (consistent hashing)    │
└──────────────────────────────────────────────────────────┘
```

### 5.4 Data Model

```
┌─────────────────────────────────────────────────────┐
│                    JOBS TABLE                        │
├─────────────────────────────────────────────────────┤
│  job_id          UUID  (PK)                         │
│  name            VARCHAR                             │
│  owner_id        UUID  (FK → users)                 │
│  job_type        ENUM(ONE_TIME, RECURRING)           │
│  cron_expr       VARCHAR  (NULL for one-time)        │
│  payload         JSONB    (task params)              │
│  callback_url    VARCHAR  (webhook on completion)    │
│  priority        INT      (0=low, 10=critical)       │
│  max_retries     INT      (default 3)                │
│  timeout_sec     INT      (default 3600)             │
│  status          ENUM(SUBMITTED,SCHEDULED,           │
│                       QUEUED,RUNNING,                │
│                       SUCCESS,FAILED,CANCELLED)      │
│  next_run_at     TIMESTAMP (indexed, B-tree)         │
│  created_at      TIMESTAMP                           │
│  updated_at      TIMESTAMP                           │
│  partition_key   INT  (hash(job_id) % N)             │
├─────────────────────────────────────────────────────┤
│  INDEX idx_due ON (partition_key, status, next_run_at)│
└─────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────┐
│              JOB_EXECUTIONS TABLE                    │
├─────────────────────────────────────────────────────┤
│  execution_id    UUID  (PK)                         │
│  job_id          UUID  (FK → jobs)                  │
│  attempt         INT                                 │
│  worker_id       VARCHAR                             │
│  status          ENUM(RUNNING,SUCCESS,FAILED)        │
│  started_at      TIMESTAMP                           │
│  finished_at     TIMESTAMP                           │
│  result          JSONB                               │
│  error_message   TEXT                                │
└─────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────┐
│              JOB_DEPENDENCIES TABLE                  │
├─────────────────────────────────────────────────────┤
│  job_id          UUID  (FK → jobs)                  │
│  depends_on      UUID  (FK → jobs)                  │
│  (PK = job_id + depends_on)                         │
└─────────────────────────────────────────────────────┘
```

### 5.5 API Design

```python
# REST API Endpoints

# POST /api/v1/jobs
{
    "name": "daily-report",
    "job_type": "RECURRING",
    "cron_expr": "0 2 * * *",       # 2 AM daily
    "payload": {
        "task": "generate_report",
        "params": {"format": "pdf", "recipients": ["a@b.com"]}
    },
    "callback_url": "https://myapp.com/webhook/job-done",
    "priority": 5,
    "max_retries": 3,
    "timeout_sec": 1800
}

# Response: 201 Created
{
    "job_id": "550e8400-e29b-41d4-a716-446655440000",
    "status": "SCHEDULED",
    "next_run_at": "2025-01-02T02:00:00Z"
}

# GET    /api/v1/jobs/{job_id}
# DELETE /api/v1/jobs/{job_id}            (cancel)
# PUT    /api/v1/jobs/{job_id}/pause
# PUT    /api/v1/jobs/{job_id}/resume
# GET    /api/v1/jobs/{job_id}/executions  (history)
```

### 5.6 Full Python Implementation

```python
"""
Distributed Job Scheduler — Core Components
"""
import uuid
import json
import time
import hashlib
import threading
from datetime import datetime, timedelta
from enum import Enum
from dataclasses import dataclass, field
from typing import Optional, Dict, List, Callable
from queue import PriorityQueue
import heapq
from abc import ABC, abstractmethod


# ─────────────────────────────────────────────
#  Data Models
# ─────────────────────────────────────────────

class JobStatus(Enum):
    SUBMITTED = "SUBMITTED"
    SCHEDULED = "SCHEDULED"
    QUEUED = "QUEUED"
    RUNNING = "RUNNING"
    SUCCESS = "SUCCESS"
    FAILED = "FAILED"
    CANCELLED = "CANCELLED"


class JobType(Enum):
    ONE_TIME = "ONE_TIME"
    RECURRING = "RECURRING"


@dataclass
class Job:
    job_id: str
    name: str
    job_type: JobType
    payload: Dict
    priority: int = 5               # 0(low) to 10(critical)
    cron_expr: Optional[str] = None
    callback_url: Optional[str] = None
    max_retries: int = 3
    timeout_sec: int = 3600
    status: JobStatus = JobStatus.SUBMITTED
    next_run_at: Optional[datetime] = None
    attempt: int = 0
    created_at: datetime = field(default_factory=datetime.utcnow)
    depends_on: List[str] = field(default_factory=list)

    def __lt__(self, other):
        """Priority comparison for heap (higher priority = lower number)."""
        if self.priority != other.priority:
            return self.priority > other.priority  # higher number = higher prio
        return self.next_run_at < other.next_run_at


@dataclass
class JobExecution:
    execution_id: str
    job_id: str
    attempt: int
    worker_id: str
    status: JobStatus
    started_at: datetime
    finished_at: Optional[datetime] = None
    result: Optional[Dict] = None
    error_message: Optional[str] = None


# ─────────────────────────────────────────────
#  Cron Expression Parser (simplified)
# ─────────────────────────────────────────────

class CronParser:
    """
    Simplified cron parser supporting: minute hour day month weekday
    Example: "0 2 * * *" = every day at 2:00 AM
             "*/5 * * * *" = every 5 minutes
    """
    @staticmethod
    def next_run(cron_expr: str, from_time: datetime = None) -> datetime:
        if from_time is None:
            from_time = datetime.utcnow()

        parts = cron_expr.strip().split()
        if len(parts) != 5:
            raise ValueError(f"Invalid cron expression: {cron_expr}")

        minute, hour, day, month, weekday = parts

        # Simplified: handle basic cases
        if cron_expr == "* * * * *":
            return from_time + timedelta(minutes=1)

        if minute.startswith("*/"):
            interval = int(minute[2:])
            next_min = from_time.minute + interval
            if next_min >= 60:
                return from_time.replace(
                    minute=next_min % 60,
                    second=0, microsecond=0
                ) + timedelta(hours=1)
            return from_time.replace(minute=next_min, second=0, microsecond=0)

        # Fixed time daily: e.g., "0 2 * * *"
        target_minute = int(minute)
        target_hour = int(hour)
        candidate = from_time.replace(
            hour=target_hour, minute=target_minute,
            second=0, microsecond=0
        )
        if candidate <= from_time:
            candidate += timedelta(days=1)
        return candidate


# ─────────────────────────────────────────────
#  Job Store (Database Abstraction)
# ─────────────────────────────────────────────

class JobStore:
    """
    In-memory job store simulating a sharded database.
    Production: PostgreSQL with partitioned tables.
    """
    def __init__(self, num_partitions: int = 4):
        self.num_partitions = num_partitions
        # Partition → {job_id → Job}
        self.partitions: Dict[int, Dict[str, Job]] = {
            i: {} for i in range(num_partitions)
        }
        self.executions: Dict[str, List[JobExecution]] = {}
        self.lock = threading.Lock()

    def _partition_for(self, job_id: str) -> int:
        h = int(hashlib.md5(job_id.encode()).hexdigest(), 16)
        return h % self.num_partitions

    def save(self, job: Job):
        partition = self._partition_for(job.job_id)
        with self.lock:
            self.partitions[partition][job.job_id] = job

    def get(self, job_id: str) -> Optional[Job]:
        partition = self._partition_for(job_id)
        return self.partitions[partition].get(job_id)

    def get_due_jobs(self, partition: int, now: datetime,
                     limit: int = 100) -> List[Job]:
        """Simulate: SELECT * FROM jobs WHERE partition_key=?
           AND status='SCHEDULED' AND next_run_at <= ?
           ORDER BY priority DESC, next_run_at
           LIMIT ? FOR UPDATE SKIP LOCKED"""
        with self.lock:
            due = []
            for job in self.partitions[partition].values():
                if (job.status == JobStatus.SCHEDULED
                        and job.next_run_at
                        and job.next_run_at <= now):
                    due.append(job)

            due.sort(key=lambda j: (-j.priority, j.next_run_at))
            return due[:limit]

    def save_execution(self, execution: JobExecution):
        with self.lock:
            if execution.job_id not in self.executions:
                self.executions[execution.job_id] = []
            self.executions[execution.job_id].append(execution)

    def get_executions(self, job_id: str) -> List[JobExecution]:
        return self.executions.get(job_id, [])


# ─────────────────────────────────────────────
#  Task Queue (simulates Redis/Kafka)
# ─────────────────────────────────────────────

class TaskQueue:
    """Priority-based task queue. Production: Redis Sorted Sets or Kafka."""
    def __init__(self):
        self._queue: List = []
        self._lock = threading.Lock()
        self._not_empty = threading.Condition(self._lock)

    def enqueue(self, job: Job):
        with self._not_empty:
            heapq.heappush(self._queue, (-job.priority, job.next_run_at, job))
            self._not_empty.notify()

    def dequeue(self, timeout: float = 5.0) -> Optional[Job]:
        with self._not_empty:
            while not self._queue:
                if not self._not_empty.wait(timeout):
                    return None
            _, _, job = heapq.heappop(self._queue)
            return job

    def size(self) -> int:
        with self._lock:
            return len(self._queue)


# ─────────────────────────────────────────────
#  Distributed Lock (simulates ZooKeeper/etcd)
# ─────────────────────────────────────────────

class DistributedLock:
    """Simulates distributed lock for leader election."""
    def __init__(self):
        self._locks: Dict[str, str] = {}   # resource → owner
        self._lock = threading.Lock()

    def try_acquire(self, resource: str, owner: str) -> bool:
        with self._lock:
            if resource not in self._locks:
                self._locks[resource] = owner
                return True
            return self._locks[resource] == owner

    def release(self, resource: str, owner: str):
        with self._lock:
            if self._locks.get(resource) == owner:
                del self._locks[resource]

    def current_owner(self, resource: str) -> Optional[str]:
        return self._locks.get(resource)


# ─────────────────────────────────────────────
#  Worker
# ─────────────────────────────────────────────

class TaskHandler(ABC):
    """Interface for user-defined task handlers."""
    @abstractmethod
    def execute(self, payload: Dict) -> Dict:
        pass


class Worker(threading.Thread):
    """
    Worker process that pulls tasks from the queue and executes them.
    Production: separate process / container.
    """
    def __init__(self, worker_id: str, task_queue: TaskQueue,
                 job_store: JobStore,
                 task_registry: Dict[str, TaskHandler]):
        super().__init__(daemon=True)
        self.worker_id = worker_id
        self.task_queue = task_queue
        self.job_store = job_store
        self.task_registry = task_registry
        self.running = True

    def run(self):
        print(f"[Worker-{self.worker_id}] Started")
        while self.running:
            job = self.task_queue.dequeue(timeout=2.0)
            if job is None:
                continue
            self._execute_job(job)

    def _execute_job(self, job: Job):
        job.status = JobStatus.RUNNING
        job.attempt += 1
        self.job_store.save(job)

        execution = JobExecution(
            execution_id=str(uuid.uuid4()),
            job_id=job.job_id,
            attempt=job.attempt,
            worker_id=self.worker_id,
            status=JobStatus.RUNNING,
            started_at=datetime.utcnow()
        )

        task_name = job.payload.get("task", "default")
        handler = self.task_registry.get(task_name)

        try:
            if handler is None:
                raise ValueError(f"No handler registered for task: {task_name}")

            result = handler.execute(job.payload.get("params", {}))

            job.status = JobStatus.SUCCESS
            execution.status = JobStatus.SUCCESS
            execution.result = result
            execution.finished_at = datetime.utcnow()
            print(f"[Worker-{self.worker_id}] Job {job.name} "
                  f"SUCCEEDED (attempt {job.attempt})")

        except Exception as e:
            execution.status = JobStatus.FAILED
            execution.error_message = str(e)
            execution.finished_at = datetime.utcnow()

            if job.attempt < job.max_retries:
                # Exponential backoff retry
                backoff = min(2 ** job.attempt, 60)
                job.status = JobStatus.SCHEDULED
                job.next_run_at = datetime.utcnow() + timedelta(seconds=backoff)
                print(f"[Worker-{self.worker_id}] Job {job.name} "
                      f"FAILED, retrying in {backoff}s "
                      f"(attempt {job.attempt}/{job.max_retries})")
            else:
                job.status = JobStatus.FAILED
                print(f"[Worker-{self.worker_id}] Job {job.name} "
                      f"PERMANENTLY FAILED after {job.attempt} attempts")

        self.job_store.save(job)
        self.job_store.save_execution(execution)

    def stop(self):
        self.running = False


# ─────────────────────────────────────────────
#  Scheduler Service
# ─────────────────────────────────────────────

class SchedulerService(threading.Thread):
    """
    Scans assigned partitions for due jobs and enqueues them.
    Uses leader election per partition.
    """
    def __init__(self, scheduler_id: str,
                 assigned_partitions: List[int],
                 job_store: JobStore,
                 task_queue: TaskQueue,
                 dist_lock: DistributedLock,
                 poll_interval: float = 1.0):
        super().__init__(daemon=True)
        self.scheduler_id = scheduler_id
        self.assigned_partitions = assigned_partitions
        self.job_store = job_store
        self.task_queue = task_queue
        self.dist_lock = dist_lock
        self.poll_interval = poll_interval
        self.running = True

    def run(self):
        print(f"[Scheduler-{self.scheduler_id}] Started, "
              f"partitions={self.assigned_partitions}")
        while self.running:
            for partition in self.assigned_partitions:
                lock_key = f"scheduler_partition_{partition}"
                if self.dist_lock.try_acquire(lock_key, self.scheduler_id):
                    self._process_partition(partition)
            time.sleep(self.poll_interval)

    def _process_partition(self, partition: int):
        now = datetime.utcnow()
        due_jobs = self.job_store.get_due_jobs(partition, now)

        for job in due_jobs:
            # Check dependencies
            if not self._dependencies_met(job):
                continue

            job.status = JobStatus.QUEUED
            self.job_store.save(job)
            self.task_queue.enqueue(job)

            # Schedule next run for recurring jobs
            if job.job_type == JobType.RECURRING and job.cron_expr:
                next_job = Job(
                    job_id=str(uuid.uuid4()),
                    name=job.name,
                    job_type=JobType.RECURRING,
                    payload=job.payload,
                    priority=job.priority,
                    cron_expr=job.cron_expr,
                    callback_url=job.callback_url,
                    max_retries=job.max_retries,
                    timeout_sec=job.timeout_sec,
                    status=JobStatus.SCHEDULED,
                    next_run_at=CronParser.next_run(job.cron_expr, now)
                )
                self.job_store.save(next_job)
                print(f"[Scheduler] Next run for '{job.name}': "
                      f"{next_job.next_run_at}")

    def _dependencies_met(self, job: Job) -> bool:
        for dep_id in job.depends_on:
            dep_job = self.job_store.get(dep_id)
            if dep_job is None or dep_job.status != JobStatus.SUCCESS:
                return False
        return True

    def stop(self):
        self.running = False
        for partition in self.assigned_partitions:
            self.dist_lock.release(
                f"scheduler_partition_{partition}", self.scheduler_id
            )


# ─────────────────────────────────────────────
#  Job Scheduler Facade (API Layer)
# ─────────────────────────────────────────────

class JobScheduler:
    """
    Main entry point — orchestrates all components.
    """
    def __init__(self, num_workers: int = 3, num_partitions: int = 4):
        self.job_store = JobStore(num_partitions)
        self.task_queue = TaskQueue()
        self.dist_lock = DistributedLock()
        self.task_registry: Dict[str, TaskHandler] = {}

        # Start schedulers (each owns some partitions)
        partitions_per_scheduler = num_partitions
        self.scheduler = SchedulerService(
            scheduler_id="sched-1",
            assigned_partitions=list(range(partitions_per_scheduler)),
            job_store=self.job_store,
            task_queue=self.task_queue,
            dist_lock=self.dist_lock,
            poll_interval=0.5
        )

        # Start workers
        self.workers = []
        for i in range(num_workers):
            w = Worker(
                worker_id=f"w-{i}",
                task_queue=self.task_queue,
                job_store=self.job_store,
                task_registry=self.task_registry
            )
            self.workers.append(w)

    def register_handler(self, task_name: str, handler: TaskHandler):
        self.task_registry[task_name] = handler

    def start(self):
        self.scheduler.start()
        for w in self.workers:
            w.start()
        print("[JobScheduler] System started")

    def submit_job(self, name: str, payload: Dict,
                   job_type: JobType = JobType.ONE_TIME,
                   cron_expr: str = None,
                   priority: int = 5,
                   delay_seconds: int = 0,
                   depends_on: List[str] = None,
                   max_retries: int = 3) -> Job:
        now = datetime.utcnow()

        if job_type == JobType.RECURRING and cron_expr:
            next_run = CronParser.next_run(cron_expr, now)
        else:
            next_run = now + timedelta(seconds=delay_seconds)

        job = Job(
            job_id=str(uuid.uuid4()),
            name=name,
            job_type=job_type,
            payload=payload,
            priority=priority,
            cron_expr=cron_expr,
            max_retries=max_retries,
            status=JobStatus.SCHEDULED,
            next_run_at=next_run,
            depends_on=depends_on or []
        )
        self.job_store.save(job)
        print(f"[JobScheduler] Submitted job '{name}' "
              f"(id={job.job_id[:8]}..., next_run={next_run})")
        return job

    def cancel_job(self, job_id: str) -> bool:
        job = self.job_store.get(job_id)
        if job and job.status in (JobStatus.SUBMITTED, JobStatus.SCHEDULED):
            job.status = JobStatus.CANCELLED
            self.job_store.save(job)
            return True
        return False

    def get_status(self, job_id: str) -> Optional[Dict]:
        job = self.job_store.get(job_id)
        if not job:
            return None
        executions = self.job_store.get_executions(job_id)
        return {
            "job_id": job.job_id,
            "name": job.name,
            "status": job.status.value,
            "attempt": job.attempt,
            "executions": len(executions)
        }

    def stop(self):
        self.scheduler.stop()
        for w in self.workers:
            w.stop()


# ─────────────────────────────────────────────
#  Example Task Handlers
# ─────────────────────────────────────────────

class ReportGenerator(TaskHandler):
    def execute(self, params: Dict) -> Dict:
        fmt = params.get("format", "pdf")
        time.sleep(0.5)  # Simulate work
        return {"file": f"/reports/report_2025.{fmt}", "size": "2.4MB"}


class EmailSender(TaskHandler):
    def execute(self, params: Dict) -> Dict:
        to = params.get("to", "unknown")
        time.sleep(0.3)
        return {"sent_to": to, "message_id": str(uuid.uuid4())[:8]}


class FailingTask(TaskHandler):
    """Task that fails first 2 attempts, succeeds on 3rd."""
    call_count = 0

    def execute(self, params: Dict) -> Dict:
        FailingTask.call_count += 1
        if FailingTask.call_count < 3:
            raise RuntimeError(f"Transient error (call #{FailingTask.call_count})")
        return {"recovered": True}


# ─────────────────────────────────────────────
#  Demo
# ─────────────────────────────────────────────

def main():
    scheduler = JobScheduler(num_workers=3, num_partitions=4)

    # Register task handlers
    scheduler.register_handler("generate_report", ReportGenerator())
    scheduler.register_handler("send_email", EmailSender())
    scheduler.register_handler("flaky_task", FailingTask())

    scheduler.start()
    time.sleep(1)

    # 1) One-time immediate job
    job1 = scheduler.submit_job(
        name="quarterly-report",
        payload={"task": "generate_report", "params": {"format": "pdf"}},
        priority=8
    )

    # 2) Delayed job
    job2 = scheduler.submit_job(
        name="welcome-email",
        payload={"task": "send_email", "params": {"to": "user@example.com"}},
        delay_seconds=2,
        priority=5
    )

    # 3) Job with retries
    job3 = scheduler.submit_job(
        name="flaky-operation",
        payload={"task": "flaky_task", "params": {}},
        max_retries=3,
        priority=6
    )

    # Let jobs process
    time.sleep(10)

    # Check statuses
    for job in [job1, job2, job3]:
        status = scheduler.get_status(job.job_id)
        print(f"\nStatus: {status}")

    scheduler.stop()
    print("\n[JobScheduler] System stopped")


if __name__ == "__main__":
    main()
```

### 5.7 Scaling Strategy

```
┌──────────────────────────────────────────────────────────────┐
│                   SCALING DIMENSIONS                         │
│                                                              │
│  1. MORE JOBS → Partition job DB by hash(job_id)             │
│     ┌─────────────┐  ┌─────────────┐  ┌─────────────┐       │
│     │ Shard 0     │  │ Shard 1     │  │ Shard 2     │       │
│     │ PostgreSQL  │  │ PostgreSQL  │  │ PostgreSQL  │       │
│     └─────────────┘  └─────────────┘  └─────────────┘       │
│                                                              │
│  2. MORE THROUGHPUT → Scale workers horizontally             │
│     ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐           │
│     │ W-1  │ │ W-2  │ │ W-3  │ │ W-4  │ │ W-N  │           │
│     └──────┘ └──────┘ └──────┘ └──────┘ └──────┘           │
│     All pull from same Kafka topic (consumer group)          │
│                                                              │
│  3. MORE SCHEDULERS → One leader per partition               │
│     Scheduler instances compete for partition leadership     │
│                                                              │
│  4. HOT PARTITIONS → Split into sub-partitions               │
│     Partition 0 → 0a, 0b (double slots)                     │
└──────────────────────────────────────────────────────────────┘
```

---

## 6. Design a Notification System

---

### 6.1 Requirements

```
Functional:
├─ Multi-channel: Push (iOS/Android), SMS, Email, In-App, Webhook
├─ Template management with variable substitution
├─ Bulk notifications (broadcast to millions)
├─ User preferences (opt-in/opt-out per channel)
├─ Scheduling (send at specific time / timezone-aware)
├─ Delivery tracking & analytics
└─ Rate limiting per user and per channel

Non-Functional:
├─ High throughput (millions of notifications/day)
├─ Low latency for real-time notifications (< 2 seconds)
├─ At-least-once delivery guarantee
├─ Extensible (add new channels easily)
└─ Graceful degradation (if SMS provider is down, queue)
```

### 6.2 High-Level Architecture

```
┌──────────────────────────────────────────────────────────────────────┐
│                        NOTIFICATION SYSTEM                           │
│                                                                      │
│  ┌───────────┐     ┌──────────────┐    ┌──────────────────────────┐  │
│  │ Service A │────►│              │    │   Template Service       │  │
│  │ Service B │────►│  Notification│    │   ┌──────────────────┐   │  │
│  │ Service C │────►│  API Gateway │───►│   │ Welcome Email    │   │  │
│  │ Cron Jobs │────►│              │    │   │ OTP SMS          │   │  │
│  └───────────┘     └──────┬───────┘    │   │ Order Confirm    │   │  │
│                           │            │   └──────────────────┘   │  │
│                           ▼            └──────────────────────────┘  │
│                  ┌─────────────────┐                                 │
│                  │  Validation &   │   ┌──────────────────────────┐  │
│                  │  Enrichment     │──►│  User Preference Store   │  │
│                  │  Service        │   │  (opt-in/out per channel)│  │
│                  └────────┬────────┘   └──────────────────────────┘  │
│                           │                                          │
│                           ▼                                          │
│               ┌───────────────────────┐                              │
│               │     Priority Router   │                              │
│               │  (Kafka Topic Router) │                              │
│               └───┬─────┬─────┬───┬───┘                              │
│                   │     │     │   │                                   │
│          ┌────────┘  ┌──┘  ┌──┘   └────────┐                         │
│          ▼           ▼     ▼               ▼                         │
│    ┌──────────┐ ┌────────┐ ┌──────────┐ ┌──────────┐                │
│    │  Email   │ │  SMS   │ │  Push    │ │ In-App   │                │
│    │  Queue   │ │  Queue │ │  Queue   │ │  Queue   │                │
│    │ (Kafka)  │ │(Kafka) │ │ (Kafka)  │ │ (Kafka)  │                │
│    └────┬─────┘ └───┬────┘ └────┬─────┘ └────┬─────┘                │
│         ▼           ▼          ▼             ▼                       │
│    ┌──────────┐ ┌────────┐ ┌──────────┐ ┌──────────┐                │
│    │  Email   │ │  SMS   │ │  Push    │ │  In-App  │                │
│    │  Workers │ │ Workers│ │  Workers │ │  Workers │                │
│    └────┬─────┘ └───┬────┘ └────┬─────┘ └────┬─────┘                │
│         │           │          │             │                       │
│         ▼           ▼          ▼             ▼                       │
│    ┌──────────┐ ┌────────┐ ┌──────────┐ ┌──────────┐                │
│    │ SendGrid │ │ Twilio │ │ FCM/APNs │ │ WebSocket│                │
│    │ Mailgun  │ │ AWS SNS│ │          │ │ SSE      │                │
│    └──────────┘ └────────┘ └──────────┘ └──────────┘                │
│                                                                      │
│    ┌─────────────────────────────────────────────────┐               │
│    │            Delivery Tracking (Kafka → DB)       │               │
│    │  Status: PENDING → SENT → DELIVERED → READ      │               │
│    │  Analytics: open rate, click rate, bounce rate   │               │
│    └─────────────────────────────────────────────────┘               │
└──────────────────────────────────────────────────────────────────────┘
```

### 6.3 Message Flow Detail

```
┌──────────────────────────────────────────────────────────────┐
│                    NOTIFICATION FLOW                         │
│                                                              │
│  1. API receives request:                                    │
│     POST /notify {user_id, template_id, channel, data}       │
│                                                              │
│  2. Validation & Enrichment:                                 │
│     ├─ Check user preferences (opted out? → skip)            │
│     ├─ Rate limit check (> 5 SMS/hour? → throttle)           │
│     ├─ Render template with data variables                   │
│     ├─ Look up device tokens / email / phone                 │
│     └─ Check DND hours (timezone-aware)                      │
│                                                              │
│  3. Priority Classification:                                 │
│     ├─ P0 (Critical): OTP, security alerts  → instant        │
│     ├─ P1 (High): order updates, payments   → < 30s          │
│     ├─ P2 (Medium): social notifications    → < 5 min        │
│     └─ P3 (Low): marketing, digest          → batched         │
│                                                              │
│  4. Channel-specific Queue:                                  │
│     Kafka topic: notifications.{channel}.{priority}          │
│     Example: notifications.sms.p0                            │
│                                                              │
│  5. Worker processes and calls external provider             │
│                                                              │
│  6. Delivery callback:                                       │
│     Provider webhook → update delivery status                │
│                                                              │
│  7. Analytics pipeline:                                      │
│     Kafka → Flink/Spark → ClickHouse → Dashboard            │
└──────────────────────────────────────────────────────────────┘
```

### 6.4 Data Model

```
┌──────────────────────────────────────────────────┐
│                NOTIFICATIONS TABLE                │
├──────────────────────────────────────────────────┤
│  notification_id   UUID (PK)                     │
│  request_id        UUID (idempotency key)        │
│  user_id           UUID (FK → users)             │
│  channel           ENUM(EMAIL,SMS,PUSH,IN_APP)   │
│  template_id       VARCHAR                        │
│  rendered_content  JSONB                          │
│  priority          ENUM(P0,P1,P2,P3)             │
│  status            ENUM(PENDING,QUEUED,SENT,      │
│                         DELIVERED,READ,FAILED)    │
│  provider          VARCHAR (sendgrid, twilio)     │
│  provider_msg_id   VARCHAR                        │
│  scheduled_at      TIMESTAMP                      │
│  sent_at           TIMESTAMP                      │
│  delivered_at      TIMESTAMP                      │
│  read_at           TIMESTAMP                      │
│  error_message     TEXT                           │
│  retry_count       INT                            │
│  created_at        TIMESTAMP                      │
├──────────────────────────────────────────────────┤
│  INDEX (user_id, created_at DESC)                │
│  INDEX (status, channel, created_at)             │
│  Partition by created_at (monthly)               │
└──────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────┐
│            TEMPLATES TABLE                        │
├──────────────────────────────────────────────────┤
│  template_id      VARCHAR (PK)                   │
│  channel          ENUM                            │
│  subject_template VARCHAR                         │
│  body_template    TEXT                            │
│  variables        JSONB (schema for validation)   │
│  version          INT                             │
│  active           BOOLEAN                         │
└──────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────┐
│          USER_PREFERENCES TABLE                   │
├──────────────────────────────────────────────────┤
│  user_id          UUID                            │
│  channel          ENUM                            │
│  enabled          BOOLEAN                         │
│  quiet_hours      JSONB  (e.g. {"start":"22:00",  │
│                           "end":"08:00","tz":"EST"})│
│  frequency_cap    INT    (max per hour)           │
│  updated_at       TIMESTAMP                       │
└──────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────┐
│          USER_DEVICES TABLE                       │
├──────────────────────────────────────────────────┤
│  device_id        UUID (PK)                      │
│  user_id          UUID                            │
│  platform         ENUM(IOS,ANDROID,WEB)          │
│  push_token       VARCHAR                         │
│  active           BOOLEAN                         │
│  last_active_at   TIMESTAMP                       │
└──────────────────────────────────────────────────┘
```

### 6.5 Full Python Implementation

```python
"""
Notification System — Complete Implementation
"""
import uuid
import time
import json
import re
import threading
from datetime import datetime, timedelta
from enum import Enum
from dataclasses import dataclass, field
from typing import Optional, Dict, List, Set
from collections import defaultdict
from abc import ABC, abstractmethod
from queue import Queue


# ─────────────────────────────────────────────
#  Enums and Data Models
# ─────────────────────────────────────────────

class Channel(Enum):
    EMAIL = "EMAIL"
    SMS = "SMS"
    PUSH = "PUSH"
    IN_APP = "IN_APP"
    WEBHOOK = "WEBHOOK"


class Priority(Enum):
    CRITICAL = 0    # OTP, security
    HIGH = 1        # Transactional
    MEDIUM = 2      # Social
    LOW = 3         # Marketing


class DeliveryStatus(Enum):
    PENDING = "PENDING"
    QUEUED = "QUEUED"
    SENT = "SENT"
    DELIVERED = "DELIVERED"
    READ = "READ"
    FAILED = "FAILED"
    THROTTLED = "THROTTLED"


@dataclass
class NotificationRequest:
    user_id: str
    template_id: str
    channel: Channel
    data: Dict                                # Template variables
    priority: Priority = Priority.MEDIUM
    request_id: str = field(default_factory=lambda: str(uuid.uuid4()))
    scheduled_at: Optional[datetime] = None   # None = send immediately


@dataclass
class Notification:
    notification_id: str
    request_id: str
    user_id: str
    channel: Channel
    priority: Priority
    template_id: str
    subject: str
    body: str
    status: DeliveryStatus = DeliveryStatus.PENDING
    provider: Optional[str] = None
    provider_msg_id: Optional[str] = None
    retry_count: int = 0
    error_message: Optional[str] = None
    created_at: datetime = field(default_factory=datetime.utcnow)
    sent_at: Optional[datetime] = None
    delivered_at: Optional[datetime] = None

    def __lt__(self, other):
        return self.priority.value < other.priority.value


@dataclass
class Template:
    template_id: str
    channel: Channel
    subject_template: str
    body_template: str
    variables: List[str]


@dataclass
class UserPreference:
    user_id: str
    channel_settings: Dict[Channel, bool]     # Channel → enabled
    quiet_start: Optional[int] = 22           # Hour (24h format)
    quiet_end: Optional[int] = 8
    frequency_cap: Dict[Channel, int] = field(
        default_factory=lambda: {c: 100 for c in Channel}
    )


@dataclass
class UserDevice:
    device_id: str
    user_id: str
    platform: str   # IOS, ANDROID, WEB
    push_token: str
    active: bool = True


# ─────────────────────────────────────────────
#  Template Engine
# ─────────────────────────────────────────────

class TemplateEngine:
    """Renders templates with variable substitution."""

    def __init__(self):
        self.templates: Dict[str, Template] = {}

    def register(self, template: Template):
        self.templates[template.template_id] = template

    def render(self, template_id: str, data: Dict) -> tuple:
        """Returns (subject, body) with variables substituted."""
        template = self.templates.get(template_id)
        if not template:
            raise ValueError(f"Template not found: {template_id}")

        subject = self._substitute(template.subject_template, data)
        body = self._substitute(template.body_template, data)
        return subject, body

    @staticmethod
    def _substitute(text: str, data: Dict) -> str:
        """Replace {{variable}} with values from data."""
        def replacer(match):
            key = match.group(1).strip()
            return str(data.get(key, f"{{{{key}}}}"))
        return re.sub(r'\{\{(\w+)\}\}', replacer, text)


# ─────────────────────────────────────────────
#  Rate Limiter (Token Bucket)
# ─────────────────────────────────────────────

class RateLimiter:
    """Per-user, per-channel rate limiter using sliding window."""

    def __init__(self):
        self._windows: Dict[str, List[datetime]] = defaultdict(list)
        self._lock = threading.Lock()

    def allow(self, user_id: str, channel: Channel,
              limit: int, window_seconds: int = 3600) -> bool:
        key = f"{user_id}:{channel.value}"
        now = datetime.utcnow()
        cutoff = now - timedelta(seconds=window_seconds)

        with self._lock:
            # Clean old entries
            self._windows[key] = [
                t for t in self._windows[key] if t > cutoff
            ]
            if len(self._windows[key]) >= limit:
                return False
            self._windows[key].append(now)
            return True

    def get_count(self, user_id: str, channel: Channel) -> int:
        key = f"{user_id}:{channel.value}"
        cutoff = datetime.utcnow() - timedelta(hours=1)
        with self._lock:
            return len([t for t in self._windows.get(key, []) if t > cutoff])


# ─────────────────────────────────────────────
#  User Preference Store
# ─────────────────────────────────────────────

class PreferenceStore:
    def __init__(self):
        self.preferences: Dict[str, UserPreference] = {}
        self.devices: Dict[str, List[UserDevice]] = defaultdict(list)

    def set_preference(self, pref: UserPreference):
        self.preferences[pref.user_id] = pref

    def get_preference(self, user_id: str) -> UserPreference:
        return self.preferences.get(user_id, UserPreference(
            user_id=user_id,
            channel_settings={c: True for c in Channel}
        ))

    def add_device(self, device: UserDevice):
        self.devices[device.user_id].append(device)

    def get_devices(self, user_id: str) -> List[UserDevice]:
        return [d for d in self.devices.get(user_id, []) if d.active]

    def is_in_quiet_hours(self, user_id: str) -> bool:
        pref = self.get_preference(user_id)
        current_hour = datetime.utcnow().hour
        if pref.quiet_start and pref.quiet_end:
            if pref.quiet_start > pref.quiet_end:  # e.g., 22-8
                return current_hour >= pref.quiet_start or current_hour < pref.quiet_end
            else:
                return pref.quiet_start <= current_hour < pref.quiet_end
        return False


# ─────────────────────────────────────────────
#  Channel Providers (External Service Adapters)
# ─────────────────────────────────────────────

class NotificationProvider(ABC):
    """Abstract interface for notification delivery."""

    @abstractmethod
    def send(self, notification: Notification,
             recipient_info: Dict) -> tuple:
        """Returns (success: bool, provider_msg_id: str, error: str)"""
        pass

    @abstractmethod
    def channel(self) -> Channel:
        pass


class EmailProvider(NotificationProvider):
    """Simulates SendGrid / SES / Mailgun."""

    def channel(self) -> Channel:
        return Channel.EMAIL

    def send(self, notification: Notification,
             recipient_info: Dict) -> tuple:
        email = recipient_info.get("email", "unknown@example.com")
        time.sleep(0.1)  # Simulate API call
        msg_id = f"email_{uuid.uuid4().hex[:8]}"
        print(f"    [EmailProvider] Sent to {email}: "
              f"'{notification.subject}' (id={msg_id})")
        return True, msg_id, None


class SMSProvider(NotificationProvider):
    """Simulates Twilio / AWS SNS."""

    def channel(self) -> Channel:
        return Channel.SMS

    def send(self, notification: Notification,
             recipient_info: Dict) -> tuple:
        phone = recipient_info.get("phone", "+1234567890")
        time.sleep(0.1)
        msg_id = f"sms_{uuid.uuid4().hex[:8]}"
        print(f"    [SMSProvider] Sent to {phone}: "
              f"'{notification.body[:50]}' (id={msg_id})")
        return True, msg_id, None


class PushProvider(NotificationProvider):
    """Simulates FCM / APNs."""

    def channel(self) -> Channel:
        return Channel.PUSH

    def send(self, notification: Notification,
             recipient_info: Dict) -> tuple:
        tokens = recipient_info.get("push_tokens", [])
        time.sleep(0.05)
        msg_id = f"push_{uuid.uuid4().hex[:8]}"
        print(f"    [PushProvider] Sent to {len(tokens)} device(s): "
              f"'{notification.subject}' (id={msg_id})")
        return True, msg_id, None


class InAppProvider(NotificationProvider):
    """Stores in-app notification for client to fetch."""

    def __init__(self):
        self.inbox: Dict[str, List[Dict]] = defaultdict(list)

    def channel(self) -> Channel:
        return Channel.IN_APP

    def send(self, notification: Notification,
             recipient_info: Dict) -> tuple:
        user_id = recipient_info.get("user_id")
        self.inbox[user_id].append({
            "notification_id": notification.notification_id,
            "subject": notification.subject,
            "body": notification.body,
            "created_at": str(datetime.utcnow()),
            "read": False
        })
        msg_id = f"inapp_{uuid.uuid4().hex[:8]}"
        print(f"    [InAppProvider] Stored for user {user_id[:8]}... "
              f"(inbox size={len(self.inbox[user_id])})")
        return True, msg_id, None

    def get_inbox(self, user_id: str, limit: int = 20) -> List[Dict]:
        return self.inbox.get(user_id, [])[-limit:]


# ─────────────────────────────────────────────
#  Channel-Specific Message Queues
# ─────────────────────────────────────────────

class ChannelQueue:
    """
    Simulates Kafka topics per channel with priority ordering.
    Production: Kafka topics like `notifications.email.p0`, etc.
    """
    def __init__(self):
        self._queues: Dict[Channel, Queue] = {c: Queue() for c in Channel}

    def enqueue(self, channel: Channel, notification: Notification):
        self._queues[channel].put(notification)

    def dequeue(self, channel: Channel,
                timeout: float = 2.0) -> Optional[Notification]:
        try:
            return self._queues[channel].get(timeout=timeout)
        except Exception:
            return None

    def size(self, channel: Channel) -> int:
        return self._queues[channel].qsize()


# ─────────────────────────────────────────────
#  Delivery Tracker & Analytics
# ─────────────────────────────────────────────

class DeliveryTracker:
    """Tracks notification delivery status and computes analytics."""

    def __init__(self):
        self.notifications: Dict[str, Notification] = {}
        self._lock = threading.Lock()

    def track(self, notification: Notification):
        with self._lock:
            self.notifications[notification.notification_id] = notification

    def update_status(self, notification_id: str,
                      status: DeliveryStatus, **kwargs):
        with self._lock:
            notif = self.notifications.get(notification_id)
            if notif:
                notif.status = status
                if status == DeliveryStatus.SENT:
                    notif.sent_at = datetime.utcnow()
                elif status == DeliveryStatus.DELIVERED:
                    notif.delivered_at = datetime.utcnow()

    def get_analytics(self) -> Dict:
        with self._lock:
            total = len(self.notifications)
            by_status = defaultdict(int)
            by_channel = defaultdict(int)
            for n in self.notifications.values():
                by_status[n.status.value] += 1
                by_channel[n.channel.value] += 1
            return {
                "total": total,
                "by_status": dict(by_status),
                "by_channel": dict(by_channel)
            }


# ─────────────────────────────────────────────
#  Channel Worker (Consumer)
# ─────────────────────────────────────────────

class ChannelWorker(threading.Thread):
    """
    Consumes from a channel queue and delivers via the provider.
    Production: Kafka consumer group.
    """
    def __init__(self, worker_id: str, channel: Channel,
                 queue: ChannelQueue, provider: NotificationProvider,
                 tracker: DeliveryTracker,
                 pref_store: PreferenceStore,
                 max_retries: int = 3):
        super().__init__(daemon=True)
        self.worker_id = worker_id
        self.channel = channel
        self.queue = queue
        self.provider = provider
        self.tracker = tracker
        self.pref_store = pref_store
        self.max_retries = max_retries
        self.running = True

    def run(self):
        print(f"[ChannelWorker-{self.channel.value}-{self.worker_id}] Started")
        while self.running:
            notification = self.queue.dequeue(self.channel, timeout=1.0)
            if notification is None:
                continue
            self._deliver(notification)

    def _deliver(self, notification: Notification):
        # Build recipient info
        recipient_info = self._get_recipient_info(notification)

        try:
            success, msg_id, error = self.provider.send(
                notification, recipient_info
            )
            if success:
                notification.status = DeliveryStatus.SENT
                notification.provider_msg_id = msg_id
                notification.sent_at = datetime.utcnow()
                self.tracker.update_status(
                    notification.notification_id, DeliveryStatus.SENT
                )
            else:
                self._handle_failure(notification, error)
        except Exception as e:
            self._handle_failure(notification, str(e))

    def _handle_failure(self, notification: Notification, error: str):
        notification.retry_count += 1
        if notification.retry_count < self.max_retries:
            notification.status = DeliveryStatus.QUEUED
            self.queue.enqueue(self.channel, notification)
            print(f"    [Retry {notification.retry_count}] "
                  f"{notification.notification_id[:8]}...")
        else:
            notification.status = DeliveryStatus.FAILED
            notification.error_message = error
            self.tracker.update_status(
                notification.notification_id, DeliveryStatus.FAILED
            )

    def _get_recipient_info(self, notification: Notification) -> Dict:
        user_id = notification.user_id
        info = {"user_id": user_id}

        if self.channel == Channel.EMAIL:
            info["email"] = f"user_{user_id[:4]}@example.com"
        elif self.channel == Channel.SMS:
            info["phone"] = f"+1-555-{user_id[:4]}"
        elif self.channel == Channel.PUSH:
            devices = self.pref_store.get_devices(user_id)
            info["push_tokens"] = [d.push_token for d in devices]
        return info

    def stop(self):
        self.running = False


# ─────────────────────────────────────────────
#  Notification Service (Orchestrator)
# ─────────────────────────────────────────────

class NotificationService:
    """
    Central orchestrator — validates, enriches, routes notifications.
    """
    def __init__(self):
        self.template_engine = TemplateEngine()
        self.rate_limiter = RateLimiter()
        self.pref_store = PreferenceStore()
        self.channel_queue = ChannelQueue()
        self.tracker = DeliveryTracker()
        self.idempotency_cache: Set[str] = set()

        # Providers
        self.in_app_provider = InAppProvider()
        self.providers: Dict[Channel, NotificationProvider] = {
            Channel.EMAIL: EmailProvider(),
            Channel.SMS: SMSProvider(),
            Channel.PUSH: PushProvider(),
            Channel.IN_APP: self.in_app_provider,
        }

        # Workers (per channel)
        self.workers: List[ChannelWorker] = []

    def setup_templates(self):
        """Register default templates."""
        self.template_engine.register(Template(
            template_id="welcome_email",
            channel=Channel.EMAIL,
            subject_template="Welcome to {{app_name}}, {{name}}!",
            body_template="Hi {{name}},\n\nWelcome to {{app_name}}! "
                          "Your account has been created.\n\nBest regards",
            variables=["name", "app_name"]
        ))
        self.template_engine.register(Template(
            template_id="otp_sms",
            channel=Channel.SMS,
            subject_template="OTP",
            body_template="Your OTP is {{code}}. Valid for {{minutes}} min. "
                          "Do not share with anyone.",
            variables=["code", "minutes"]
        ))
        self.template_engine.register(Template(
            template_id="order_update",
            channel=Channel.PUSH,
            subject_template="Order {{order_id}} {{status}}",
            body_template="Your order #{{order_id}} is now {{status}}. "
                          "{{details}}",
            variables=["order_id", "status", "details"]
        ))
        self.template_engine.register(Template(
            template_id="promo_inapp",
            channel=Channel.IN_APP,
            subject_template="{{discount}}% Off!",
            body_template="Use code {{code}} for {{discount}}% off "
                          "your next purchase. Expires {{expiry}}.",
            variables=["discount", "code", "expiry"]
        ))

    def start(self, workers_per_channel: int = 2):
        """Start channel workers."""
        for channel, provider in self.providers.items():
            for i in range(workers_per_channel):
                worker = ChannelWorker(
                    worker_id=str(i),
                    channel=channel,
                    queue=self.channel_queue,
                    provider=provider,
                    tracker=self.tracker,
                    pref_store=self.pref_store
                )
                worker.start()
                self.workers.append(worker)
        print("[NotificationService] Started with "
              f"{len(self.workers)} workers")

    def send(self, request: NotificationRequest) -> Dict:
        """
        Main entry point — process a notification request.
        """
        # 1. Idempotency check
        if request.request_id in self.idempotency_cache:
            return {"status": "duplicate", "request_id": request.request_id}
        self.idempotency_cache.add(request.request_id)

        # 2. Check user preference
        pref = self.pref_store.get_preference(request.user_id)
        channel_enabled = pref.channel_settings.get(request.channel, True)
        if not channel_enabled:
            return {"status": "opted_out", "channel": request.channel.value}

        # 3. Check quiet hours (skip for CRITICAL)
        if (request.priority != Priority.CRITICAL
                and self.pref_store.is_in_quiet_hours(request.user_id)):
            # Reschedule for after quiet hours
            return {"status": "quiet_hours", "rescheduled": True}

        # 4. Rate limiting (skip for CRITICAL)
        if request.priority != Priority.CRITICAL:
            cap = pref.frequency_cap.get(request.channel, 100)
            if not self.rate_limiter.allow(
                    request.user_id, request.channel, cap):
                return {"status": "throttled", "channel": request.channel.value}

        # 5. Render template
        try:
            subject, body = self.template_engine.render(
                request.template_id, request.data
            )
        except ValueError as e:
            return {"status": "error", "message": str(e)}

        # 6. Create notification object
        notification = Notification(
            notification_id=str(uuid.uuid4()),
            request_id=request.request_id,
            user_id=request.user_id,
            channel=request.channel,
            priority=request.priority,
            template_id=request.template_id,
            subject=subject,
            body=body,
            status=DeliveryStatus.QUEUED
        )

        # 7. Track and enqueue
        self.tracker.track(notification)
        self.channel_queue.enqueue(request.channel, notification)

        return {
            "status": "queued",
            "notification_id": notification.notification_id,
            "channel": request.channel.value,
            "priority": request.priority.name
        }

    def send_bulk(self, user_ids: List[str],
                  template_id: str, channel: Channel,
                  data: Dict, priority: Priority = Priority.LOW) -> Dict:
        """Send notification to multiple users."""
        results = {"queued": 0, "skipped": 0, "errors": 0}

        for user_id in user_ids:
            request = NotificationRequest(
                user_id=user_id,
                template_id=template_id,
                channel=channel,
                data=data,
                priority=priority
            )
            result = self.send(request)
            if result["status"] == "queued":
                results["queued"] += 1
            elif result["status"] in ("opted_out", "throttled", "quiet_hours"):
                results["skipped"] += 1
            else:
                results["errors"] += 1

        return results

    def get_inbox(self, user_id: str) -> List[Dict]:
        """Get in-app notifications for a user."""
        return self.in_app_provider.get_inbox(user_id)

    def get_analytics(self) -> Dict:
        return self.tracker.get_analytics()

    def stop(self):
        for w in self.workers:
            w.stop()


# ─────────────────────────────────────────────
#  Demo
# ─────────────────────────────────────────────

def main():
    service = NotificationService()
    service.setup_templates()

    # Setup user preferences
    user_id = "user-001-abc-def"
    service.pref_store.set_preference(UserPreference(
        user_id=user_id,
        channel_settings={
            Channel.EMAIL: True,
            Channel.SMS: True,
            Channel.PUSH: True,
            Channel.IN_APP: True,
        }
    ))
    service.pref_store.add_device(UserDevice(
        device_id="dev-1", user_id=user_id,
        platform="IOS", push_token="apns_token_abc123"
    ))

    service.start(workers_per_channel=1)
    time.sleep(0.5)

    print("\n" + "=" * 60)
    print("  SENDING NOTIFICATIONS")
    print("=" * 60)

    # 1. Welcome email
    result = service.send(NotificationRequest(
        user_id=user_id,
        template_id="welcome_email",
        channel=Channel.EMAIL,
        data={"name": "Alice", "app_name": "SuperApp"},
        priority=Priority.HIGH
    ))
    print(f"\n  Email result: {result}")

    # 2. OTP SMS (Critical)
    result = service.send(NotificationRequest(
        user_id=user_id,
        template_id="otp_sms",
        channel=Channel.SMS,
        data={"code": "847291", "minutes": "5"},
        priority=Priority.CRITICAL
    ))
    print(f"  SMS result: {result}")

    # 3. Push notification
    result = service.send(NotificationRequest(
        user_id=user_id,
        template_id="order_update",
        channel=Channel.PUSH,
        data={"order_id": "ORD-9921", "status": "Shipped",
              "details": "Expected delivery: Jan 5"},
        priority=Priority.HIGH
    ))
    print(f"  Push result: {result}")

    # 4. In-app promo
    result = service.send(NotificationRequest(
        user_id=user_id,
        template_id="promo_inapp",
        channel=Channel.IN_APP,
        data={"discount": "20", "code": "SAVE20", "expiry": "Jan 31"},
        priority=Priority.LOW
    ))
    print(f"  In-App result: {result}")

    # 5. Bulk notification
    print("\n  Sending bulk notifications...")
    bulk_users = [f"user-{i:03d}" for i in range(10)]
    bulk_result = service.send_bulk(
        user_ids=bulk_users,
        template_id="promo_inapp",
        channel=Channel.IN_APP,
        data={"discount": "15", "code": "BULK15", "expiry": "Feb 1"},
        priority=Priority.LOW
    )
    print(f"  Bulk result: {bulk_result}")

    # Wait for delivery
    time.sleep(3)

    # Check analytics
    print("\n" + "=" * 60)
    print("  ANALYTICS")
    print("=" * 60)
    analytics = service.get_analytics()
    print(f"  {json.dumps(analytics, indent=4)}")

    # Check inbox
    print(f"\n  In-App inbox for {user_id[:12]}...:")
    inbox = service.get_inbox(user_id)
    for msg in inbox:
        print(f"    - {msg['subject']}: {msg['body'][:50]}...")

    service.stop()
    print("\n[NotificationService] Stopped")


if __name__ == "__main__":
    main()
```

### 6.6 Scaling Strategies

```
┌────────────────────────────────────────────────────────────────────┐
│                  NOTIFICATION SYSTEM SCALING                       │
│                                                                    │
│  LAYER          STRATEGY                                           │
│  ─────          ────────                                           │
│  API            Auto-scaling API pods behind ALB                    │
│                 Idempotency via Redis (request_id dedup)            │
│                                                                    │
│  Queues         Kafka with partitions per channel × priority       │
│                 notifications.email.p0 → 16 partitions             │
│                 notifications.email.p3 → 4 partitions              │
│                                                                    │
│  Workers        Consumer groups per channel                        │
│                 Scale based on queue depth (Kafka lag)              │
│                 EMAIL: 20 workers, SMS: 10, PUSH: 30               │
│                                                                    │
│  Providers      Multi-provider failover:                           │
│                 Email: SendGrid → SES → Mailgun                    │
│                 SMS: Twilio → Nexmo → AWS SNS                      │
│                 Circuit breaker per provider                       │
│                                                                    │
│  Database       Notifications table partitioned by month           │
│                 Hot data (7 days) in PostgreSQL                     │
│                 Cold data archived to S3 + Athena                   │
│                                                                    │
│  Rate Limits    Redis sliding window counters                      │
│                 Key: rate:{user_id}:{channel}:{window}             │
│                                                                    │
│  Bulk Sends     Fan-out via Kafka:                                 │
│                 1 "campaign" message → N user messages              │
│                 Batch worker resolves user list from segment        │
└────────────────────────────────────────────────────────────────────┘
```

---

## 7. Design a Search Engine

---

### 7.1 Requirements

```
Functional:
├─ Web crawling (discover & fetch pages)
├─ Content indexing (inverted index)
├─ Full-text search with relevance ranking
├─ Auto-complete / search suggestions
├─ Spell correction ("did you mean?")
├─ Filters & facets
└─ Pagination of results

Non-Functional:
├─ Latency: search < 200ms (p99)
├─ Crawl billions of pages
├─ Handle 10K+ QPS (queries per second)
├─ Freshness: updated pages re-indexed within hours
└─ Fault tolerant with data replication
```

### 7.2 High-Level Architecture

```
┌──────────────────────────────────────────────────────────────────────┐
│                        SEARCH ENGINE                                 │
│                                                                      │
│  ┌──────────────────────────── CRAWLING ─────────────────────────┐   │
│  │                                                                │   │
│  │   Seed URLs ──►┌──────────┐    ┌───────────┐   ┌───────────┐  │   │
│  │                │   URL    │    │  Crawler   │   │   Content │  │   │
│  │                │ Frontier │───►│  Workers   │──►│   Store   │  │   │
│  │                │ (Queue)  │    │ (fetchers) │   │   (S3)    │  │   │
│  │                └─────▲────┘    └──────┬─────┘   └───────────┘  │   │
│  │                      │               │                         │   │
│  │                      │        ┌──────▼─────┐                   │   │
│  │                      └────────│  URL       │                   │   │
│  │                               │  Extractor │                   │   │
│  │                               │ (new links)│                   │   │
│  │                               └────────────┘                   │   │
│  └────────────────────────────────────────────────────────────────┘   │
│                           │                                           │
│                           ▼                                           │
│  ┌──────────────────────── INDEXING ─────────────────────────────┐   │
│  │                                                                │   │
│  │   ┌───────────┐   ┌────────────┐   ┌──────────────────────┐   │   │
│  │   │  Parser   │   │  Tokenizer │   │   Index Builder      │   │   │
│  │   │(HTML→text)│──►│  Stemmer   │──►│   (inverted index)   │   │   │
│  │   │          │   │  StopWords │   │                      │   │   │
│  │   └───────────┘   └────────────┘   └──────────┬───────────┘   │   │
│  │                                               │               │   │
│  │                                    ┌──────────▼───────────┐   │   │
│  │                                    │  Index Shards        │   │   │
│  │                                    │  ┌───┐┌───┐┌───┐     │   │   │
│  │                                    │  │ 0 ││ 1 ││ 2 │...  │   │   │
│  │                                    │  └───┘└───┘└───┘     │   │   │
│  │                                    └──────────────────────┘   │   │
│  └────────────────────────────────────────────────────────────────┘   │
│                           │                                           │
│                           ▼                                           │
│  ┌──────────────────────── SERVING ──────────────────────────────┐   │
│  │                                                                │   │
│  │   User Query ──► ┌────────────┐   ┌────────────────┐          │   │
│  │                   │  Query     │   │  Scatter-Gather│          │   │
│  │                   │  Parser    │──►│  to all shards │          │   │
│  │                   └────────────┘   └───────┬────────┘          │   │
│  │                                           │                    │   │
│  │                               ┌───────────▼───────────┐       │   │
│  │                               │    Ranker / Scorer    │       │   │
│  │                               │  (TF-IDF + PageRank) │       │   │
│  │                               └───────────┬───────────┘       │   │
│  │                                           │                    │   │
│  │                               ┌───────────▼───────────┐       │   │
│  │                               │    Results + Snippets │       │   │
│  │                               └───────────────────────┘       │   │
│  └────────────────────────────────────────────────────────────────┘   │
│                                                                      │
│  ┌──── AUXILIARY ──────────────────────────────────────────────┐     │
│  │  ┌──────────────┐  ┌───────────┐  ┌──────────────────────┐ │     │
│  │  │ Auto-Complete│  │  Spell    │  │  PageRank            │ │     │
│  │  │ (Trie/Redis) │  │  Checker  │  │  (offline graph comp)│ │     │
│  │  └──────────────┘  └───────────┘  └──────────────────────┘ │     │
│  └────────────────────────────────────────────────────────────┘     │
└──────────────────────────────────────────────────────────────────────┘
```

### 7.3 Inverted Index Structure

```
┌──────────────────────────────────────────────────────────────┐
│                    INVERTED INDEX                             │
│                                                              │
│  Forward Index:                                              │
│    doc_1 → "the quick brown fox"                             │
│    doc_2 → "the quick rabbit"                                │
│    doc_3 → "brown fox jumps"                                 │
│                                                              │
│  Inverted Index:                                             │
│    "brown"  → [(doc_1, pos=2, tf=1), (doc_3, pos=0, tf=1)]  │
│    "fox"    → [(doc_1, pos=3, tf=1), (doc_3, pos=1, tf=1)]  │
│    "jump"   → [(doc_3, pos=2, tf=1)]                        │
│    "quick"  → [(doc_1, pos=1, tf=1), (doc_2, pos=1, tf=1)]  │
│    "rabbit" → [(doc_2, pos=2, tf=1)]                        │
│                                                              │
│  Per-term data:                                              │
│    ┌────────────────────────────────────────────┐            │
│    │  Term: "quick"                             │            │
│    │  Document Frequency (df): 2                │            │
│    │  Posting List:                             │            │
│    │    doc_1: {tf: 1, positions: [1]}          │            │
│    │    doc_2: {tf: 1, positions: [1]}          │            │
│    └────────────────────────────────────────────┘            │
│                                                              │
│  Sharding: hash(term) % num_shards                           │
│    Shard 0: terms a-g                                        │
│    Shard 1: terms h-n                                        │
│    Shard 2: terms o-z                                        │
└──────────────────────────────────────────────────────────────┘
```

### 7.4 Ranking: TF-IDF + PageRank

```
┌──────────────────────────────────────────────────────────────┐
│                     RANKING FORMULA                          │
│                                                              │
│  Score(query, doc) = Σ  TF-IDF(term, doc) × PageRank(doc)   │
│                     t∈q                                      │
│                                                              │
│  TF-IDF:                                                     │
│    TF(t, d)  = freq(t in d) / total_terms(d)                │
│    IDF(t)    = log(N / df(t))                                │
│    TF-IDF    = TF × IDF                                      │
│                                                              │
│  Where:                                                      │
│    N    = total number of documents                          │
│    df(t) = number of documents containing term t             │
│                                                              │
│  PageRank (simplified):                                      │
│    PR(A) = (1-d) + d × Σ PR(T) / C(T)                       │
│                       T∈B(A)                                 │
│    d = damping factor (0.85)                                 │
│    B(A) = set of pages linking to A                          │
│    C(T) = number of outbound links from T                    │
│                                                              │
│  Final score blends relevance (TF-IDF) with authority (PR)   │
└──────────────────────────────────────────────────────────────┘
```

### 7.5 Full Python Implementation

```python
"""
Search Engine — Complete Implementation
Includes: Crawler, Indexer, Ranker, Auto-complete, Spell-checker
"""
import re
import math
import hashlib
import heapq
from collections import defaultdict, Counter
from dataclasses import dataclass, field
from typing import Dict, List, Set, Tuple, Optional
from urllib.parse import urlparse, urljoin


# ─────────────────────────────────────────────
#  Text Processing Pipeline
# ─────────────────────────────────────────────

class TextProcessor:
    """Tokenization, stop-word removal, stemming."""

    STOP_WORDS = {
        'the', 'a', 'an', 'and', 'or', 'but', 'in', 'on', 'at',
        'to', 'for', 'of', 'with', 'by', 'is', 'was', 'are', 'were',
        'be', 'been', 'being', 'have', 'has', 'had', 'do', 'does',
        'did', 'will', 'would', 'could', 'should', 'it', 'its',
        'this', 'that', 'these', 'those', 'i', 'you', 'he', 'she',
        'we', 'they', 'me', 'him', 'her', 'us', 'them', 'not', 'no',
        'from', 'as', 'if', 'then', 'than', 'so', 'can',
    }

    # Simple suffix-stripping rules (Porter stemmer approximation)
    SUFFIX_RULES = [
        ('ational', 'ate'), ('tional', 'tion'), ('enci', 'ence'),
        ('anci', 'ance'), ('izer', 'ize'), ('ising', 'ise'),
        ('izing', 'ize'), ('ating', 'ate'), ('ling', 'le'),
        ('ement', 'e'), ('ment', ''), ('ness', ''),
        ('tion', 'te'), ('sion', 'se'),
        ('ing', ''), ('ies', 'y'), ('ed', ''), ('ly', ''),
        ('es', ''), ('s', ''),
    ]

    @classmethod
    def tokenize(cls, text: str) -> List[str]:
        """Convert text to lowercase tokens."""
        text = re.sub(r'<[^>]+>', ' ', text)      # Strip HTML
        text = re.sub(r'[^\w\s]', ' ', text.lower())
        return text.split()

    @classmethod
    def remove_stop_words(cls, tokens: List[str]) -> List[str]:
        return [t for t in tokens if t not in cls.STOP_WORDS and len(t) > 1]

    @classmethod
    def stem(cls, word: str) -> str:
        """Simple suffix-stripping stemmer."""
        for suffix, replacement in cls.SUFFIX_RULES:
            if word.endswith(suffix) and len(word) - len(suffix) >= 3:
                return word[:-len(suffix)] + replacement
        return word

    @classmethod
    def process(cls, text: str) -> List[str]:
        """Full pipeline: tokenize → stop words → stem."""
        tokens = cls.tokenize(text)
        tokens = cls.remove_stop_words(tokens)
        return [cls.stem(t) for t in tokens]

    @classmethod
    def process_with_positions(cls, text: str) -> List[Tuple[str, int]]:
        """Returns (stemmed_token, original_position) pairs."""
        tokens = cls.tokenize(text)
        result = []
        for pos, token in enumerate(tokens):
            if token not in cls.STOP_WORDS and len(token) > 1:
                result.append((cls.stem(token), pos))
        return result


# ─────────────────────────────────────────────
#  Document Model
# ─────────────────────────────────────────────

@dataclass
class Document:
    doc_id: str
    url: str
    title: str
    content: str
    outbound_links: List[str] = field(default_factory=list)
    page_rank: float = 1.0
    content_length: int = 0

    def __post_init__(self):
        self.content_length = len(self.content.split())


@dataclass
class SearchResult:
    doc_id: str
    url: str
    title: str
    snippet: str
    score: float
    components: Dict[str, float] = field(default_factory=dict)


# ─────────────────────────────────────────────
#  Posting List Entry
# ─────────────────────────────────────────────

@dataclass
class Posting:
    doc_id: str
    term_frequency: int      # How many times term appears in doc
    positions: List[int]     # Positions of term in document
    field_boost: float = 1.0 # Title match = higher boost


# ─────────────────────────────────────────────
#  Inverted Index
# ─────────────────────────────────────────────

class InvertedIndex:
    """
    Core inverted index data structure.
    Production: distributed across shards, stored in SSTable format.
    """
    def __init__(self, num_shards: int = 4):
        self.num_shards = num_shards
        # shard_id → { term → [Posting] }
        self.shards: Dict[int, Dict[str, List[Posting]]] = {
            i: defaultdict(list) for i in range(num_shards)
        }
        # Forward index: doc_id → Document
        self.documents: Dict[str, Document] = {}
        # Document frequency: term → count of docs containing term
        self.doc_freq: Dict[str, int] = defaultdict(int)
        self.total_docs: int = 0
        # Average document length (for BM25)
        self.avg_doc_length: float = 0

    def _shard_for_term(self, term: str) -> int:
        return int(hashlib.md5(term.encode()).hexdigest(), 16) % self.num_shards

    def index_document(self, doc: Document):
        """Add a document to the index."""
        self.documents[doc.doc_id] = doc
        self.total_docs += 1

        # Update average document length
        self.avg_doc_length = (
            (self.avg_doc_length * (self.total_docs - 1) + doc.content_length)
            / self.total_docs
        )

        # Process content
        seen_terms: Set[str] = set()
        content_tokens = TextProcessor.process_with_positions(doc.content)
        title_tokens = TextProcessor.process_with_positions(doc.title)

        # Aggregate term frequencies & positions
        term_data: Dict[str, Dict] = defaultdict(
            lambda: {"tf": 0, "positions": [], "title_match": False}
        )

        for term, pos in content_tokens:
            term_data[term]["tf"] += 1
            term_data[term]["positions"].append(pos)

        for term, pos in title_tokens:
            term_data[term]["tf"] += 1
            term_data[term]["title_match"] = True

        # Add to inverted index
        for term, data in term_data.items():
            shard = self._shard_for_term(term)
            posting = Posting(
                doc_id=doc.doc_id,
                term_frequency=data["tf"],
                positions=data["positions"],
                field_boost=2.0 if data["title_match"] else 1.0
            )
            self.shards[shard][term].append(posting)

            if term not in seen_terms:
                self.doc_freq[term] += 1
                seen_terms.add(term)

    def search_term(self, term: str) -> List[Posting]:
        """Retrieve posting list for a term."""
        shard = self._shard_for_term(term)
        return self.shards[shard].get(term, [])

    def get_doc_freq(self, term: str) -> int:
        return self.doc_freq.get(term, 0)

    def get_stats(self) -> Dict:
        total_terms = sum(
            len(shard) for shard in self.shards.values()
        )
        total_postings = sum(
            sum(len(plist) for plist in shard.values())
            for shard in self.shards.values()
        )
        return {
            "total_documents": self.total_docs,
            "unique_terms": total_terms,
            "total_postings": total_postings,
            "avg_doc_length": round(self.avg_doc_length, 1),
            "shards": self.num_shards
        }


# ─────────────────────────────────────────────
#  PageRank Calculator
# ─────────────────────────────────────────────

class PageRankCalculator:
    """
    Offline PageRank computation.
    Production: runs on Spark/MapReduce over link graph.
    """
    @staticmethod
    def compute(documents: Dict[str, Document],
                damping: float = 0.85,
                iterations: int = 20) -> Dict[str, float]:
        """
        Iterative PageRank computation.
        """
        # Build adjacency: url → [outbound urls]
        url_to_doc: Dict[str, str] = {}
        for doc in documents.values():
            url_to_doc[doc.url] = doc.doc_id

        n = len(documents)
        if n == 0:
            return {}

        # Initialize PR
        pr: Dict[str, float] = {
            doc_id: 1.0 / n for doc_id in documents
        }

        # Build inbound links
        inbound: Dict[str, Set[str]] = defaultdict(set)
        outbound_count: Dict[str, int] = {}

        for doc in documents.values():
            valid_outbound = [
                url_to_doc[link]
                for link in doc.outbound_links
                if link in url_to_doc
            ]
            outbound_count[doc.doc_id] = max(len(valid_outbound), 1)
            for target_id in valid_outbound:
                inbound[target_id].add(doc.doc_id)

        # Iterate
        for iteration in range(iterations):
            new_pr: Dict[str, float] = {}
            for doc_id in documents:
                rank_sum = sum(
                    pr[src] / outbound_count[src]
                    for src in inbound[doc_id]
                )
                new_pr[doc_id] = (1 - damping) / n + damping * rank_sum
            pr = new_pr

        # Normalize to [0, 1]
        max_pr = max(pr.values()) if pr else 1
        return {doc_id: score / max_pr for doc_id, score in pr.items()}


# ─────────────────────────────────────────────
#  Scorer / Ranker
# ─────────────────────────────────────────────

class Scorer:
    """
    Combines TF-IDF with PageRank for final scoring.
    Also supports BM25 as alternative.
    """
    def __init__(self, index: InvertedIndex):
        self.index = index

    def tf_idf(self, term: str, posting: Posting) -> float:
        """Compute TF-IDF score for a term-document pair."""
        doc = self.index.documents[posting.doc_id]

        # TF: log-normalized
        tf = 1 + math.log(posting.term_frequency) if posting.term_frequency > 0 else 0

        # IDF: inverse document frequency
        df = self.index.get_doc_freq(term)
        idf = math.log(self.index.total_docs / (1 + df)) if df > 0 else 0

        return tf * idf * posting.field_boost

    def bm25(self, term: str, posting: Posting,
             k1: float = 1.5, b: float = 0.75) -> float:
        """BM25 scoring (better than basic TF-IDF)."""
        doc = self.index.documents[posting.doc_id]
        df = self.index.get_doc_freq(term)
        n = self.index.total_docs

        idf = math.log((n - df + 0.5) / (df + 0.5) + 1)

        tf = posting.term_frequency
        doc_len = doc.content_length
        avg_len = self.index.avg_doc_length

        numerator = tf * (k1 + 1)
        denominator = tf + k1 * (1 - b + b * doc_len / max(avg_len, 1))

        return idf * (numerator / denominator) * posting.field_boost

    def score_document(self, query_terms: List[str],
                       doc_id: str,
                       postings_map: Dict[str, Posting],
                       page_rank: float) -> float:
        """
        Combined score: BM25 relevance + PageRank authority.
        """
        relevance_score = 0
        for term in query_terms:
            if term in postings_map:
                relevance_score += self.bm25(term, postings_map[term])

        # Combine: 70% relevance + 30% authority
        final_score = 0.7 * relevance_score + 0.3 * (page_rank * 10)
        return final_score


# ─────────────────────────────────────────────
#  Auto-Complete (Trie-based)
# ─────────────────────────────────────────────

class TrieNode:
    def __init__(self):
        self.children: Dict[str, 'TrieNode'] = {}
        self.is_end: bool = False
        self.frequency: int = 0
        self.suggestions: List[Tuple[int, str]] = []  # (freq, word)


class AutoComplete:
    """
    Trie-based autocomplete with frequency ranking.
    Production: Redis sorted sets or dedicated service.
    """
    def __init__(self, max_suggestions: int = 5):
        self.root = TrieNode()
        self.max_suggestions = max_suggestions

    def insert(self, word: str, frequency: int = 1):
        node = self.root
        for char in word.lower():
            if char not in node.children:
                node.children[char] = TrieNode()
            node = node.children[char]
        node.is_end = True
        node.frequency += frequency

        # Update suggestions along the path
        self._update_suggestions(word.lower(), node.frequency)

    def _update_suggestions(self, word: str, freq: int):
        node = self.root
        for char in word:
            if char in node.children:
                node = node.children[char]
                # Maintain top-k suggestions at each node
                exists = False
                for i, (f, w) in enumerate(node.suggestions):
                    if w == word:
                        node.suggestions[i] = (freq, word)
                        exists = True
                        break
                if not exists:
                    node.suggestions.append((freq, word))
                node.suggestions.sort(key=lambda x: -x[0])
                node.suggestions = node.suggestions[:self.max_suggestions]

    def suggest(self, prefix: str) -> List[Tuple[str, int]]:
        """Return top suggestions for a prefix."""
        node = self.root
        for char in prefix.lower():
            if char not in node.children:
                return []
            node = node.children[char]

        # Collect all words below this prefix
        results = []
        self._dfs(node, prefix.lower(), results)
        results.sort(key=lambda x: -x[1])
        return results[:self.max_suggestions]

    def _dfs(self, node: TrieNode, current: str,
             results: List[Tuple[str, int]]):
        if node.is_end:
            results.append((current, node.frequency))
        for char, child in node.children.items():
            self._dfs(child, current + char, results)


# ─────────────────────────────────────────────
#  Spell Checker
# ─────────────────────────────────────────────

class SpellChecker:
    """
    Edit-distance based spell checker.
    Production: uses n-gram index + BK-tree for efficiency.
    """
    def __init__(self):
        self.vocabulary: Dict[str, int] = {}  # word → frequency

    def build(self, documents: Dict[str, Document]):
        """Build vocabulary from indexed documents."""
        for doc in documents.values():
            tokens = TextProcessor.tokenize(doc.title + " " + doc.content)
            for token in tokens:
                if len(token) > 2:
                    self.vocabulary[token] = self.vocabulary.get(token, 0) + 1

    @staticmethod
    def edit_distance(s1: str, s2: str) -> int:
        """Levenshtein distance."""
        m, n = len(s1), len(s2)
        dp = [[0] * (n + 1) for _ in range(m + 1)]
        for i in range(m + 1):
            dp[i][0] = i
        for j in range(n + 1):
            dp[0][j] = j
        for i in range(1, m + 1):
            for j in range(1, n + 1):
                if s1[i - 1] == s2[j - 1]:
                    dp[i][j] = dp[i - 1][j - 1]
                else:
                    dp[i][j] = 1 + min(
                        dp[i - 1][j], dp[i][j - 1], dp[i - 1][j - 1]
                    )
        return dp[m][n]

    def correct(self, word: str, max_distance: int = 2) -> Optional[str]:
        """Find closest word in vocabulary."""
        word = word.lower()
        if word in self.vocabulary:
            return None  # Word is correct

        candidates = []
        for vocab_word, freq in self.vocabulary.items():
            dist = self.edit_distance(word, vocab_word)
            if dist <= max_distance:
                candidates.append((dist, -freq, vocab_word))

        if candidates:
            candidates.sort()
            return candidates[0][2]
        return None

    def suggest_query(self, query: str) -> Optional[str]:
        """Correct an entire query."""
        words = query.lower().split()
        corrections = []
        any_corrected = False
        for word in words:
            correction = self.correct(word)
            if correction:
                corrections.append(correction)
                any_corrected = True
            else:
                corrections.append(word)
        return " ".join(corrections) if any_corrected else None


# ─────────────────────────────────────────────
#  Web Crawler (Simplified)
# ─────────────────────────────────────────────

class WebCrawler:
    """
    Simplified web crawler with URL frontier.
    Production: distributed with politeness policies,
    robots.txt compliance, duplicate detection.
    """
    def __init__(self):
        self.visited: Set[str] = set()
        self.frontier: List[str] = []
        self.crawled_pages: Dict[str, Document] = {}

    def add_seed(self, url: str):
        if url not in self.visited:
            self.frontier.append(url)

    def crawl(self, simulated_web: Dict[str, Dict],
              max_pages: int = 100) -> Dict[str, Document]:
        """
        Crawl simulated web pages.
        simulated_web: url → {"title": ..., "content": ..., "links": [...]}
        """
        while self.frontier and len(self.crawled_pages) < max_pages:
            url = self.frontier.pop(0)
            if url in self.visited:
                continue

            self.visited.add(url)
            page_data = simulated_web.get(url)

            if not page_data:
                continue

            doc = Document(
                doc_id=hashlib.md5(url.encode()).hexdigest()[:12],
                url=url,
                title=page_data["title"],
                content=page_data["content"],
                outbound_links=page_data.get("links", [])
            )
            self.crawled_pages[url] = doc

            # Add discovered links to frontier
            for link in page_data.get("links", []):
                if link not in self.visited:
                    self.frontier.append(link)

            print(f"  [Crawler] Crawled: {url} → '{doc.title[:40]}'")

        return self.crawled_pages


# ─────────────────────────────────────────────
#  Search Engine (Orchestrator)
# ─────────────────────────────────────────────

class SearchEngine:
    """
    Complete search engine: crawl → index → search.
    """
    def __init__(self, num_index_shards: int = 4):
        self.index = InvertedIndex(num_shards=num_index_shards)
        self.scorer = Scorer(self.index)
        self.autocomplete = AutoComplete()
        self.spell_checker = SpellChecker()
        self.crawler = WebCrawler()

    def crawl_and_index(self, simulated_web: Dict[str, Dict],
                        seed_urls: List[str]):
        """Full pipeline: crawl → index → compute PageRank."""
        print("=" * 60)
        print("  PHASE 1: CRAWLING")
        print("=" * 60)

        for url in seed_urls:
            self.crawler.add_seed(url)
        documents = self.crawler.crawl(simulated_web)

        print(f"\n  Crawled {len(documents)} pages")

        # Compute PageRank
        print("\n" + "=" * 60)
        print("  PHASE 2: COMPUTING PAGERANK")
        print("=" * 60)

        page_ranks = PageRankCalculator.compute(
            {doc.doc_id: doc for doc in documents.values()}
        )
        for doc in documents.values():
            doc.page_rank = page_ranks.get(doc.doc_id, 0.1)
            print(f"  PR({doc.url}) = {doc.page_rank:.4f}")

        # Build index
        print("\n" + "=" * 60)
        print("  PHASE 3: INDEXING")
        print("=" * 60)

        for doc in documents.values():
            self.index.index_document(doc)

        stats = self.index.get_stats()
        print(f"  Index stats: {stats}")

        # Build autocomplete from popular terms
        print("\n  Building autocomplete...")
        all_terms = Counter()
        for doc in documents.values():
            tokens = TextProcessor.tokenize(doc.title + " " + doc.content)
            all_terms.update(tokens)

        for term, freq in all_terms.most_common(1000):
            if len(term) > 2 and term not in TextProcessor.STOP_WORDS:
                self.autocomplete.insert(term, freq)

        # Build spell checker vocabulary
        self.spell_checker.build(
            {doc.doc_id: doc for doc in documents.values()}
        )

        print("  Indexing complete!")

    def search(self, query: str, top_k: int = 10) -> List[SearchResult]:
        """
        Execute a search query.
        Flow: parse → spell check → scatter to shards → rank → return
        """
        # 1. Process query
        query_terms = TextProcessor.process(query)
        if not query_terms:
            return []

        # 2. Spell check
        suggestion = self.spell_checker.suggest_query(query)

        # 3. Scatter: retrieve posting lists for each term
        #    (In production, this goes to all index shards in parallel)
        doc_postings: Dict[str, Dict[str, Posting]] = defaultdict(dict)

        for term in query_terms:
            postings = self.index.search_term(term)
            for posting in postings:
                doc_postings[posting.doc_id][term] = posting

        # 4. Score all candidate documents
        scored_docs = []
        for doc_id, postings_map in doc_postings.items():
            doc = self.index.documents[doc_id]
            score = self.scorer.score_document(
                query_terms, doc_id, postings_map, doc.page_rank
            )
            scored_docs.append((score, doc_id))

        # 5. Sort by score (descending)
        scored_docs.sort(key=lambda x: -x[0])

        # 6. Build results with snippets
        results = []
        for score, doc_id in scored_docs[:top_k]:
            doc = self.index.documents[doc_id]
            snippet = self._generate_snippet(doc.content, query_terms)

            results.append(SearchResult(
                doc_id=doc_id,
                url=doc.url,
                title=doc.title,
                snippet=snippet,
                score=round(score, 4),
                components={
                    "page_rank": round(doc.page_rank, 4)
                }
            ))

        return results, suggestion

    def _generate_snippet(self, content: str, query_terms: List[str],
                          context_words: int = 10) -> str:
        """Extract relevant snippet around query term occurrences."""
        words = content.split()
        stemmed_words = [TextProcessor.stem(w.lower()) for w in words]

        best_pos = 0
        best_score = 0

        for i, sw in enumerate(stemmed_words):
            if sw in query_terms:
                # Score based on number of query terms nearby
                window = set(stemmed_words[max(0, i - 5):i + 5])
                score = len(window.intersection(query_terms))
                if score > best_score:
                    best_score = score
                    best_pos = i

        start = max(0, best_pos - context_words)
        end = min(len(words), best_pos + context_words)
        snippet = " ".join(words[start:end])

        if start > 0:
            snippet = "..." + snippet
        if end < len(words):
            snippet += "..."

        return snippet

    def autocomplete_query(self, prefix: str) -> List[Tuple[str, int]]:
        return self.autocomplete.suggest(prefix)


# ─────────────────────────────────────────────
#  Demo: Complete Search Engine
# ─────────────────────────────────────────────

def main():
    # Simulated web (in production, these would be real HTTP fetches)
    simulated_web = {
        "https://example.com": {
            "title": "Example - Home Page",
            "content": "Welcome to Example, the world's leading platform "
                       "for distributed systems and cloud computing. "
                       "Learn about microservices, databases, and more.",
            "links": [
                "https://example.com/distributed-systems",
                "https://example.com/databases",
                "https://example.com/cloud-computing"
            ]
        },
        "https://example.com/distributed-systems": {
            "title": "Distributed Systems Guide",
            "content": "Distributed systems are collections of independent "
                       "computers that appear as a single coherent system. "
                       "Key concepts include consistency, availability, "
                       "partition tolerance (CAP theorem), consensus "
                       "algorithms like Raft and Paxos, and distributed "
                       "hash tables. Scaling distributed systems requires "
                       "careful design of data partitioning and replication.",
            "links": [
                "https://example.com",
                "https://example.com/databases",
                "https://example.com/consensus"
            ]
        },
        "https://example.com/databases": {
            "title": "Database Systems - SQL and NoSQL",
            "content": "Modern databases include relational systems like "
                       "PostgreSQL and MySQL, and NoSQL systems like "
                       "MongoDB, Cassandra, and Redis. Database indexing "
                       "uses B-trees and hash indexes for fast lookups. "
                       "Distributed databases use sharding and replication "
                       "for scalability and fault tolerance.",
            "links": [
                "https://example.com",
                "https://example.com/distributed-systems",
                "https://example.com/indexing"
            ]
        },
        "https://example.com/cloud-computing": {
            "title": "Cloud Computing Fundamentals",
            "content": "Cloud computing provides on-demand computing "
                       "resources over the internet. Major providers "
                       "include AWS, Google Cloud, and Azure. Key services "
                       "include compute (EC2), storage (S3), databases "
                       "(RDS), and container orchestration (Kubernetes). "
                       "Cloud architecture emphasizes scalability, "
                       "elasticity, and pay-per-use pricing.",
            "links": [
                "https://example.com",
                "https://example.com/distributed-systems"
            ]
        },
        "https://example.com/consensus": {
            "title": "Consensus Algorithms - Raft and Paxos",
            "content": "Consensus algorithms ensure that distributed "
                       "systems agree on a single value. Raft is designed "
                       "for understandability with leader election and log "
                       "replication. Paxos is theoretically elegant but "
                       "more complex. Both algorithms handle node failures "
                       "and network partitions gracefully. ZooKeeper and "
                       "etcd implement consensus for coordination.",
            "links": [
                "https://example.com/distributed-systems",
                "https://example.com"
            ]
        },
        "https://example.com/indexing": {
            "title": "Search Indexing and Inverted Indexes",
            "content": "Search engines use inverted indexes to map terms "
                       "to documents. Building an index involves tokenizing "
                       "text, removing stop words, and stemming. TF-IDF "
                       "and BM25 are scoring algorithms that rank documents "
                       "by relevance. PageRank measures page authority "
                       "based on link structure. Distributed search systems "
                       "shard indexes across multiple nodes.",
            "links": [
                "https://example.com/databases",
                "https://example.com/distributed-systems"
            ]
        },
    }

    # Create search engine
    engine = SearchEngine(num_index_shards=4)

    # Crawl and index
    engine.crawl_and_index(
        simulated_web,
        seed_urls=["https://example.com"]
    )

    # ─── SEARCH QUERIES ───
    print("\n" + "=" * 60)
    print("  SEARCH QUERIES")
    print("=" * 60)

    queries = [
        "distributed systems consensus",
        "database indexing scalability",
        "cloud computing storage",
        "raft paxos algorithm",
    ]

    for query in queries:
        print(f"\n  🔍 Query: '{query}'")
        print("  " + "-" * 50)

        results, spell_suggestion = engine.search(query, top_k=3)

        if spell_suggestion:
            print(f"  💡 Did you mean: '{spell_suggestion}'?")

        for i, result in enumerate(results, 1):
            print(f"  {i}. [{result.score:.3f}] {result.title}")
            print(f"     URL: {result.url}")
            print(f"     PR: {result.components['page_rank']:.3f}")
            print(f"     {result.snippet[:80]}...")

    # ─── AUTOCOMPLETE ───
    print("\n" + "=" * 60)
    print("  AUTOCOMPLETE")
    print("=" * 60)

    prefixes = ["dis", "dat", "con", "ind"]
    for prefix in prefixes:
        suggestions = engine.autocomplete_query(prefix)
        print(f"  '{prefix}' → {suggestions}")

    # ─── SPELL CHECK ───
    print("\n" + "=" * 60)
    print("  SPELL CHECK")
    print("=" * 60)

    misspelled = ["distribted systms", "dataase indxing", "consesus algorihm"]
    for query in misspelled:
        correction = engine.spell_checker.suggest_query(query)
        print(f"  '{query}' → '{correction}'")


if __name__ == "__main__":
    main()
```

### 7.6 Query Processing Flow

```
┌──────────────────────────────────────────────────────────────┐
│                QUERY PROCESSING PIPELINE                     │
│                                                              │
│  User Input: "distributed database systems"                  │
│                       │                                      │
│                       ▼                                      │
│              ┌────────────────┐                               │
│              │ Spell Check    │──► "distributed database      │
│              │                │     systems" (OK)             │
│              └────────┬───────┘                               │
│                       ▼                                      │
│              ┌────────────────┐                               │
│              │ Tokenize &     │──► ["distribut", "databas",   │
│              │ Stem           │     "system"]                 │
│              └────────┬───────┘                               │
│                       ▼                                      │
│        ┌──────────────┼──────────────┐    SCATTER             │
│        ▼              ▼              ▼                        │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐                   │
│  │ Shard 0  │  │ Shard 1  │  │ Shard 2  │                   │
│  │"distribut"│ │"databas" │  │"system"  │                   │
│  │→ postings│  │→ postings│  │→ postings│                   │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘                   │
│       └──────────────┼──────────────┘     GATHER             │
│                      ▼                                       │
│             ┌─────────────────┐                              │
│             │  Merge & Score  │                              │
│             │  (BM25 + PR)    │                              │
│             └────────┬────────┘                              │
│                      ▼                                       │
│             ┌─────────────────┐                              │
│             │  Top-K Results  │                              │
│             │  + Snippets     │                              │
│             └─────────────────┘                              │
└──────────────────────────────────────────────────────────────┘
```

---

## 8. Design a File Storage System (like Amazon S3)

---

### 8.1 Requirements

```
Functional:
├─ Create / delete buckets (namespaces)
├─ Upload objects (PUT with key)
├─ Download objects (GET by key)
├─ Delete objects
├─ List objects with prefix filtering
├─ Multipart upload for large files (> 100MB)
├─ Object versioning
├─ Pre-signed URLs for temporary access
└─ Metadata (content-type, custom headers)

Non-Functional:
├─ Durability: 99.999999999% (11 nines)
├─ Availability: 99.99%
├─ Support objects from 1 byte to 5 TB
├─ Horizontal scalability (exabytes of data)
├─ Low latency reads (< 100ms for metadata)
└─ Consistency: read-after-write for PUTs
```

### 8.2 High-Level Architecture

```
┌──────────────────────────────────────────────────────────────────────┐
│                  FILE STORAGE SYSTEM (S3-like)                       │
│                                                                      │
│  ┌──────────┐     ┌────────────────────┐                             │
│  │  Client   │────►│   API Gateway      │                             │
│  │ (SDK/CLI) │     │ (Auth, Routing,    │                             │
│  └──────────┘     │  Rate Limiting)    │                             │
│                    └─────────┬──────────┘                             │
│                              │                                       │
│          ┌───────────────────┼───────────────────┐                   │
│          ▼                   ▼                   ▼                   │
│  ┌───────────────┐  ┌───────────────┐  ┌───────────────┐            │
│  │  Metadata     │  │   Data        │  │  Bucket       │            │
│  │  Service      │  │   Service     │  │  Service      │            │
│  └───────┬───────┘  └───────┬───────┘  └───────┬───────┘            │
│          │                  │                   │                     │
│          ▼                  ▼                   ▼                     │
│  ┌───────────────┐  ┌───────────────┐  ┌───────────────┐            │
│  │  Metadata DB  │  │  Data Nodes   │  │  Bucket DB    │            │
│  │  (sharded)    │  │  (distributed │  │               │            │
│  │               │  │   storage)    │  │               │            │
│  └───────────────┘  └───────────────┘  └───────────────┘            │
│                                                                      │
│  ┌──────────────────────────────────────────────────────────────┐    │
│  │                    DATA PLANE (detail)                        │    │
│  │                                                              │    │
│  │   Object "photos/cat.jpg" (50 MB)                            │    │
│  │                                                              │    │
│  │   ┌──────────────────────────────────────┐                   │    │
│  │   │  Metadata DB entry:                  │                   │    │
│  │   │  bucket: "my-bucket"                 │                   │    │
│  │   │  key: "photos/cat.jpg"               │                   │    │
│  │   │  size: 52428800                      │                   │    │
│  │   │  content_type: "image/jpeg"          │                   │    │
│  │   │  chunks: [chunk_0, chunk_1, chunk_2] │                   │    │
│  │   │  version: 3                          │                   │    │
│  │   └──────────────────────────────────────┘                   │    │
│  │                                                              │    │
│  │   ┌────────────────────────────────────────────────┐         │    │
│  │   │  Data Nodes:                                   │         │    │
│  │   │                                                │         │    │
│  │   │  chunk_0 (16MB)  → Node-1, Node-4, Node-7     │         │    │
│  │   │  chunk_1 (16MB)  → Node-2, Node-5, Node-8     │         │    │
│  │   │  chunk_2 (18MB)  → Node-3, Node-6, Node-9     │         │    │
│  │   │                                                │         │    │
│  │   │  3-way replication for durability               │         │    │
│  │   └────────────────────────────────────────────────┘         │    │
│  └──────────────────────────────────────────────────────────────┘    │
└──────────────────────────────────────────────────────────────────────┘
```

### 8.3 Component Deep-Dive

```
┌──────────────────────────────────────────────────────────────┐
│                METADATA SERVICE                              │
│                                                              │
│  Responsibilities:                                           │
│  ├─ Object metadata CRUD                                     │
│  ├─ Key → chunk mapping                                      │
│  ├─ Version management                                       │
│  └─ Listing with prefix scans                                │
│                                                              │
│  Storage: Sharded PostgreSQL or DynamoDB                      │
│  Sharding key: hash(bucket_name + object_key)                │
│                                                              │
│  ┌─────────────────────────────────────────────┐             │
│  │  Shard 0              Shard 1               │             │
│  │  ┌──────────────┐    ┌──────────────┐       │             │
│  │  │ bucket: "a"  │    │ bucket: "b"  │       │             │
│  │  │ key: "x/y.z" │    │ key: "p/q.r" │       │             │
│  │  │ chunks: [..] │    │ chunks: [..] │       │             │
│  │  └──────────────┘    └──────────────┘       │             │
│  └─────────────────────────────────────────────┘             │
└──────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────┐
│                 DATA NODES                                   │
│                                                              │
│  Each data node manages local disk storage                   │
│                                                              │
│  ┌──────────────────────────────────────────────┐            │
│  │  Data Node Layout:                           │            │
│  │                                              │            │
│  │  /data/                                      │            │
│  │    ├── volume_001/                            │            │
│  │    │   ├── chunk_abc123.dat  (raw bytes)      │            │
│  │    │   ├── chunk_def456.dat                   │            │
│  │    │   └── ...                                │            │
│  │    ├── volume_002/                            │            │
│  │    │   └── ...                                │            │
│  │    └── metadata.db  (local chunk index)       │            │
│  │                                              │            │
│  │  Heartbeat → Placement Service (every 10s)   │            │
│  │  Reports: available space, chunk list, health │            │
│  └──────────────────────────────────────────────┘            │
└──────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────┐
│              PLACEMENT SERVICE                               │
│                                                              │
│  Decides which data nodes store each chunk                   │
│                                                              │
│  Strategy:                                                   │
│  ├─ Consistent hashing ring of data nodes                    │
│  ├─ Replication factor = 3 (configurable)                    │
│  ├─ Rack/AZ awareness (replicas in different AZs)            │
│  └─ Rebalancing on node add/remove                           │
│                                                              │
│  ┌────────────────────────────────────────────┐              │
│  │        Consistent Hashing Ring              │              │
│  │                                            │              │
│  │           Node-A (AZ-1)                    │              │
│  │          ╱                                 │              │
│  │    Node-F          Node-B (AZ-2)           │              │
│  │    (AZ-3)             │                    │              │
│  │         ╲          ╱                       │              │
│  │    Node-E     Node-C (AZ-1)               │              │
│  │          ╲  ╱                              │              │
│  │           Node-D (AZ-3)                    │              │
│  │                                            │              │
│  │  chunk_xyz → primary: Node-B               │              │
│  │              replica1: Node-C (diff AZ)    │              │
│  │              replica2: Node-D (diff AZ)    │              │
│  └────────────────────────────────────────────┘              │
└──────────────────────────────────────────────────────────────┘
```

### 8.4 Data Model

```
┌───────────────────────────────────────────────────┐
│                BUCKETS TABLE                       │
├───────────────────────────────────────────────────┤
│  bucket_name      VARCHAR (PK)                    │
│  owner_id         UUID (FK → users)               │
│  region           VARCHAR                          │
│  versioning       BOOLEAN (default false)          │
│  created_at       TIMESTAMP                        │
│  acl              JSONB (access control)           │
│  storage_class    ENUM(STANDARD, IA, GLACIER)      │
└───────────────────────────────────────────────────┘

┌───────────────────────────────────────────────────┐
│                OBJECTS TABLE (sharded)             │
├───────────────────────────────────────────────────┤
│  bucket_name      VARCHAR                          │
│  object_key       VARCHAR                          │
│  version_id       UUID                             │
│  (PK = bucket + key + version)                    │
│                                                   │
│  size             BIGINT                           │
│  content_type     VARCHAR                          │
│  checksum_sha256  VARCHAR                          │
│  custom_metadata  JSONB                            │
│  storage_class    ENUM                             │
│  chunk_count      INT                              │
│  is_latest        BOOLEAN                          │
│  is_delete_marker BOOLEAN                          │
│  created_at       TIMESTAMP                        │
│  expires_at       TIMESTAMP (optional)             │
├───────────────────────────────────────────────────┤
│  SHARD KEY: hash(bucket_name, object_key)         │
│  INDEX: (bucket_name, object_key, version_id)     │
│  INDEX: (bucket_name, prefix) for listing         │
└───────────────────────────────────────────────────┘

┌───────────────────────────────────────────────────┐
│               CHUNKS TABLE                         │
├───────────────────────────────────────────────────┤
│  chunk_id         UUID (PK)                       │
│  object_key       VARCHAR (FK → objects)           │
│  version_id       UUID                             │
│  sequence_num     INT (0, 1, 2, ...)              │
│  size             INT                              │
│  checksum_md5     VARCHAR                          │
│  data_nodes       JSONB  (["node-1","node-4",...]) │
│  status           ENUM(WRITING, COMMITTED, DELETED)│
└───────────────────────────────────────────────────┘

┌───────────────────────────────────────────────────┐
│           DATA_NODES TABLE                         │
├───────────────────────────────────────────────────┤
│  node_id          VARCHAR (PK)                    │
│  host             VARCHAR                          │
│  port             INT                              │
│  availability_zone VARCHAR                         │
│  total_space_gb   INT                              │
│  used_space_gb    INT                              │
│  status           ENUM(ACTIVE, DRAINING, DEAD)     │
│  last_heartbeat   TIMESTAMP                        │
└───────────────────────────────────────────────────┘

┌───────────────────────────────────────────────────┐
│         MULTIPART_UPLOADS TABLE                    │
├───────────────────────────────────────────────────┤
│  upload_id        UUID (PK)                       │
│  bucket_name      VARCHAR                          │
│  object_key       VARCHAR                          │
│  parts            JSONB  ([{part_num, chunk_id,    │
│                            size, etag}])           │
│  status           ENUM(IN_PROGRESS, COMPLETED,     │
│                        ABORTED)                    │
│  created_at       TIMESTAMP                        │
│  expires_at       TIMESTAMP                        │
└───────────────────────────────────────────────────┘
```

### 8.5 Upload & Download Flows

```
┌──────────────────────────────────────────────────────────────┐
│                    UPLOAD FLOW (PUT Object)                   │
│                                                              │
│  Client                  API          Metadata   Data Nodes  │
│    │                      │              │          │         │
│    │─── PUT /bucket/key ─►│              │          │         │
│    │    + body (50 MB)    │              │          │         │
│    │                      │              │          │         │
│    │                      │── Allocate ─►│          │         │
│    │                      │   chunks     │          │         │
│    │                      │◄── chunk_ids─│          │         │
│    │                      │   + nodes    │          │         │
│    │                      │              │          │         │
│    │                      │─── Write chunk 0 ────►│ Node-1  │
│    │                      │─── Write chunk 0 ────►│ Node-4  │
│    │                      │─── Write chunk 0 ────►│ Node-7  │
│    │                      │              │          │         │
│    │                      │─── Write chunk 1 ────►│ Node-2  │
│    │                      │    ...       │          │         │
│    │                      │              │          │         │
│    │                      │── Commit ───►│          │         │
│    │                      │   metadata   │          │         │
│    │                      │              │          │         │
│    │◄── 200 OK ───────────│              │          │         │
│    │    ETag: "abc123"    │              │          │         │
└──────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────┐
│                  DOWNLOAD FLOW (GET Object)                  │
│                                                              │
│  Client                  API          Metadata   Data Nodes  │
│    │                      │              │          │         │
│    │─── GET /bucket/key ─►│              │          │         │
│    │                      │              │          │         │
│    │                      │── Lookup ───►│          │         │
│    │                      │◄── metadata──│          │         │
│    │                      │   + chunks   │          │         │
│    │                      │   + nodes    │          │         │
│    │                      │              │          │         │
│    │                      │── Read chunk 0 ──────►│ Node-1  │
│    │◄── Stream chunk 0 ──│◄──────────────────────│ (or 4,7)│
│    │                      │              │          │         │
│    │                      │── Read chunk 1 ──────►│ Node-2  │
│    │◄── Stream chunk 1 ──│◄──────────────────────│ (or 5,8)│
│    │                      │              │          │         │
│    │◄── 200 OK (streamed)│              │          │         │
└──────────────────────────────────────────────────────────────┘
```

### 8.6 Full Python Implementation

```python
"""
File Storage System (S3-like) — Complete Implementation
"""
import os
import uuid
import hashlib
import hmac
import time
import json
import threading
from datetime import datetime, timedelta
from enum import Enum
from dataclasses import dataclass, field
from typing import Optional, Dict, List, Tuple, BinaryIO
from collections import defaultdict
from io import BytesIO
import bisect


# ─────────────────────────────────────────────
#  Enums & Configuration
# ─────────────────────────────────────────────

class StorageClass(Enum):
    STANDARD = "STANDARD"
    INFREQUENT_ACCESS = "INFREQUENT_ACCESS"
    GLACIER = "GLACIER"


class ObjectStatus(Enum):
    ACTIVE = "ACTIVE"
    DELETE_MARKER = "DELETE_MARKER"


CHUNK_SIZE = 16 * 1024 * 1024   # 16 MB
REPLICATION_FACTOR = 3


# ─────────────────────────────────────────────
#  Data Models
# ─────────────────────────────────────────────

@dataclass
class Bucket:
    name: str
    owner_id: str
    region: str = "us-east-1"
    versioning_enabled: bool = False
    created_at: datetime = field(default_factory=datetime.utcnow)
    storage_class: StorageClass = StorageClass.STANDARD
    acl: Dict = field(default_factory=lambda: {"public": False})


@dataclass
class ObjectVersion:
    bucket_name: str
    key: str
    version_id: str
    size: int
    content_type: str
    checksum_sha256: str
    custom_metadata: Dict
    chunk_ids: List[str]
    is_latest: bool = True
    is_delete_marker: bool = False
    storage_class: StorageClass = StorageClass.STANDARD
    created_at: datetime = field(default_factory=datetime.utcnow)
    expires_at: Optional[datetime] = None


@dataclass
class Chunk:
    chunk_id: str
    size: int
    checksum_md5: str
    data_nodes: List[str]       # Node IDs holding replicas
    sequence_num: int = 0


@dataclass
class DataNode:
    node_id: str
    host: str
    port: int
    availability_zone: str
    total_space_bytes: int
    used_space_bytes: int = 0
    status: str = "ACTIVE"
    last_heartbeat: datetime = field(default_factory=datetime.utcnow)

    @property
    def available_space(self) -> int:
        return self.total_space_bytes - self.used_space_bytes


@dataclass
class MultipartUpload:
    upload_id: str
    bucket_name: str
    object_key: str
    parts: Dict[int, Dict] = field(default_factory=dict)  # part_num → info
    status: str = "IN_PROGRESS"
    created_at: datetime = field(default_factory=datetime.utcnow)


# ─────────────────────────────────────────────
#  Consistent Hashing Ring (Placement Service)
# ─────────────────────────────────────────────

class ConsistentHashRing:
    """
    Consistent hashing for data placement across nodes.
    Uses virtual nodes for better distribution.
    """
    def __init__(self, virtual_nodes: int = 150):
        self.virtual_nodes = virtual_nodes
        self.ring: List[Tuple[int, str]] = []  # (hash, node_id)
        self.nodes: Dict[str, DataNode] = {}

    def _hash(self, key: str) -> int:
        return int(hashlib.sha256(key.encode()).hexdigest(), 16)

    def add_node(self, node: DataNode):
        self.nodes[node.node_id] = node
        for i in range(self.virtual_nodes):
            vnode_key = f"{node.node_id}:vn{i}"
            h = self._hash(vnode_key)
            bisect.insort(self.ring, (h, node.node_id))

    def remove_node(self, node_id: str):
        self.ring = [(h, nid) for h, nid in self.ring if nid != node_id]
        if node_id in self.nodes:
            del self.nodes[node_id]

    def get_nodes_for_chunk(self, chunk_id: str,
                            count: int = REPLICATION_FACTOR) -> List[str]:
        """
        Find N distinct nodes for a chunk, preferring different AZs.
        """
        if not self.ring:
            return []

        h = self._hash(chunk_id)
        idx = bisect.bisect_left(self.ring, (h,))

        selected = []
        selected_azs = set()
        seen_nodes = set()

        # Walk the ring to find distinct nodes in different AZs
        ring_len = len(self.ring)
        for i in range(ring_len):
            pos = (idx + i) % ring_len
            _, node_id = self.ring[pos]

            if node_id in seen_nodes:
                continue

            node = self.nodes.get(node_id)
            if not node or node.status != "ACTIVE":
                continue

            seen_nodes.add(node_id)

            # Prefer different AZs
            if node.availability_zone not in selected_azs or len(selected) >= count - 1:
                selected.append(node_id)
                selected_azs.add(node.availability_zone)

            if len(selected) >= count:
                break

        return selected


# ─────────────────────────────────────────────
#  Data Node Storage (Simulated)
# ─────────────────────────────────────────────

class DataNodeStorage:
    """
    Simulates data node local storage.
    Production: manages actual disk volumes.
    """
    def __init__(self):
        # node_id → { chunk_id → bytes }
        self.storage: Dict[str, Dict[str, bytes]] = defaultdict(dict)
        self._lock = threading.Lock()

    def write_chunk(self, node_id: str, chunk_id: str, data: bytes) -> bool:
        with self._lock:
            self.storage[node_id][chunk_id] = data
            return True

    def read_chunk(self, node_id: str, chunk_id: str) -> Optional[bytes]:
        with self._lock:
            return self.storage[node_id].get(chunk_id)

    def delete_chunk(self, node_id: str, chunk_id: str) -> bool:
        with self._lock:
            if chunk_id in self.storage.get(node_id, {}):
                del self.storage[node_id][chunk_id]
                return True
            return False

    def get_node_usage(self, node_id: str) -> int:
        with self._lock:
            return sum(len(d) for d in self.storage.get(node_id, {}).values())


# ─────────────────────────────────────────────
#  Metadata Store
# ─────────────────────────────────────────────

class MetadataStore:
    """
    Stores object metadata. Production: sharded PostgreSQL or DynamoDB.
    """
    def __init__(self):
        self.buckets: Dict[str, Bucket] = {}
        # (bucket, key) → [ObjectVersion] (sorted by created_at desc)
        self.objects: Dict[Tuple[str, str], List[ObjectVersion]] = defaultdict(list)
        self.chunks: Dict[str, Chunk] = {}
        self.multipart_uploads: Dict[str, MultipartUpload] = {}
        self._lock = threading.Lock()

    def create_bucket(self, bucket: Bucket) -> bool:
        with self._lock:
            if bucket.name in self.buckets:
                return False
            self.buckets[bucket.name] = bucket
            return True

    def get_bucket(self, name: str) -> Optional[Bucket]:
        return self.buckets.get(name)

    def delete_bucket(self, name: str) -> bool:
        with self._lock:
            # Check if empty
            for (bname, _) in self.objects:
                if bname == name:
                    return False  # Not empty
            if name in self.buckets:
                del self.buckets[name]
                return True
            return False

    def put_object_version(self, obj: ObjectVersion):
        with self._lock:
            key = (obj.bucket_name, obj.key)
            # Mark previous versions as not latest
            for prev in self.objects[key]:
                prev.is_latest = False
            self.objects[key].append(obj)

    def get_object(self, bucket: str, key: str,
                   version_id: str = None) -> Optional[ObjectVersion]:
        versions = self.objects.get((bucket, key), [])
        if not versions:
            return None
        if version_id:
            for v in versions:
                if v.version_id == version_id:
                    return v
            return None
        # Return latest non-delete-marker
        for v in reversed(versions):
            if v.is_latest and not v.is_delete_marker:
                return v
        return None

    def delete_object(self, bucket: str, key: str) -> bool:
        with self._lock:
            k = (bucket, key)
            bucket_obj = self.buckets.get(bucket)
            if not bucket_obj:
                return False

            if bucket_obj.versioning_enabled:
                # Add delete marker
                marker = ObjectVersion(
                    bucket_name=bucket,
                    key=key,
                    version_id=str(uuid.uuid4()),
                    size=0,
                    content_type="",
                    checksum_sha256="",
                    custom_metadata={},
                    chunk_ids=[],
                    is_latest=True,
                    is_delete_marker=True
                )
                for v in self.objects[k]:
                    v.is_latest = False
                self.objects[k].append(marker)
            else:
                if k in self.objects:
                    del self.objects[k]
            return True

    def list_objects(self, bucket: str, prefix: str = "",
                     max_keys: int = 1000) -> List[ObjectVersion]:
        results = []
        for (bname, key), versions in self.objects.items():
            if bname == bucket and key.startswith(prefix):
                for v in versions:
                    if v.is_latest and not v.is_delete_marker:
                        results.append(v)
        results.sort(key=lambda v: v.key)
        return results[:max_keys]

    def list_versions(self, bucket: str,
                      key: str) -> List[ObjectVersion]:
        return list(reversed(self.objects.get((bucket, key), [])))

    def save_chunk(self, chunk: Chunk):
        with self._lock:
            self.chunks[chunk.chunk_id] = chunk

    def get_chunk(self, chunk_id: str) -> Optional[Chunk]:
        return self.chunks.get(chunk_id)

    def save_multipart(self, upload: MultipartUpload):
        with self._lock:
            self.multipart_uploads[upload.upload_id] = upload

    def get_multipart(self, upload_id: str) -> Optional[MultipartUpload]:
        return self.multipart_uploads.get(upload_id)


# ─────────────────────────────────────────────
#  Pre-signed URL Generator
# ─────────────────────────────────────────────

class PreSignedURLGenerator:
    """Generate time-limited signed URLs for object access."""

    SECRET_KEY = "super-secret-signing-key-12345"

    @classmethod
    def generate(cls, bucket: str, key: str,
                 method: str = "GET",
                 expires_in: int = 3600) -> str:
        expiry = int(time.time()) + expires_in
        string_to_sign = f"{method}\n{bucket}\n{key}\n{expiry}"
        signature = hmac.new(
            cls.SECRET_KEY.encode(),
            string_to_sign.encode(),
            hashlib.sha256
        ).hexdigest()

        return (f"https://storage.example.com/{bucket}/{key}"
                f"?expires={expiry}&signature={signature}")

    @classmethod
    def verify(cls, bucket: str, key: str, method: str,
               expires: int, signature: str) -> bool:
        if int(time.time()) > expires:
            return False
        string_to_sign = f"{method}\n{bucket}\n{key}\n{expires}"
        expected = hmac.new(
            cls.SECRET_KEY.encode(),
            string_to_sign.encode(),
            hashlib.sha256
        ).hexdigest()
        return hmac.compare_digest(signature, expected)


# ─────────────────────────────────────────────
#  File Storage Service (Main API)
# ─────────────────────────────────────────────

class FileStorageService:
    """
    S3-like object storage service.
    Orchestrates metadata, data placement, and replication.
    """
    def __init__(self, chunk_size: int = CHUNK_SIZE):
        self.chunk_size = chunk_size
        self.metadata = MetadataStore()
        self.placement = ConsistentHashRing()
        self.data_storage = DataNodeStorage()
        self.url_generator = PreSignedURLGenerator()

        # Setup default data nodes
        self._setup_data_nodes()

    def _setup_data_nodes(self):
        """Initialize data nodes across availability zones."""
        nodes = [
            DataNode("node-1", "10.0.1.1", 9001, "az-1", 1_000_000_000_000),
            DataNode("node-2", "10.0.1.2", 9001, "az-1", 1_000_000_000_000),
            DataNode("node-3", "10.0.2.1", 9001, "az-2", 1_000_000_000_000),
            DataNode("node-4", "10.0.2.2", 9001, "az-2", 1_000_000_000_000),
            DataNode("node-5", "10.0.3.1", 9001, "az-3", 1_000_000_000_000),
            DataNode("node-6", "10.0.3.2", 9001, "az-3", 1_000_000_000_000),
        ]
        for node in nodes:
            self.placement.add_node(node)
        print(f"[Storage] Initialized {len(nodes)} data nodes "
              f"across 3 availability zones")

    # ─── Bucket Operations ───

    def create_bucket(self, name: str, owner_id: str,
                      versioning: bool = False) -> Dict:
        bucket = Bucket(
            name=name, owner_id=owner_id,
            versioning_enabled=versioning
        )
        if self.metadata.create_bucket(bucket):
            return {"status": "created", "bucket": name}
        return {"status": "error", "message": "Bucket already exists"}

    def delete_bucket(self, name: str) -> Dict:
        if self.metadata.delete_bucket(name):
            return {"status": "deleted", "bucket": name}
        return {"status": "error", "message": "Bucket not empty or not found"}

    def list_buckets(self, owner_id: str) -> List[str]:
        return [
            b.name for b in self.metadata.buckets.values()
            if b.owner_id == owner_id
        ]

    # ─── Object Upload ───

    def put_object(self, bucket_name: str, key: str,
                   data: bytes,
                   content_type: str = "application/octet-stream",
                   metadata: Dict = None) -> Dict:
        """
        Upload an object. Chunks it, replicates, and stores metadata.
        """
        # 1. Validate bucket
        bucket = self.metadata.get_bucket(bucket_name)
        if not bucket:
            return {"status": "error", "message": "Bucket not found"}

        # 2. Compute checksum
        checksum = hashlib.sha256(data).hexdigest()

        # 3. Split into chunks
        chunks = self._split_into_chunks(data)

        # 4. Store each chunk on data nodes
        chunk_records = []
        for seq, chunk_data in enumerate(chunks):
            chunk_id = str(uuid.uuid4())
            chunk_checksum = hashlib.md5(chunk_data).hexdigest()

            # Get placement (which nodes to write to)
            target_nodes = self.placement.get_nodes_for_chunk(
                chunk_id, REPLICATION_FACTOR
            )

            if len(target_nodes) < 2:
                return {"status": "error",
                        "message": "Insufficient data nodes"}

            # Write to all replicas
            for node_id in target_nodes:
                self.data_storage.write_chunk(node_id, chunk_id, chunk_data)

            chunk = Chunk(
                chunk_id=chunk_id,
                size=len(chunk_data),
                checksum_md5=chunk_checksum,
                data_nodes=target_nodes,
                sequence_num=seq
            )
            self.metadata.save_chunk(chunk)
            chunk_records.append(chunk_id)

        # 5. Create object metadata
        version_id = str(uuid.uuid4())
        obj_version = ObjectVersion(
            bucket_name=bucket_name,
            key=key,
            version_id=version_id,
            size=len(data),
            content_type=content_type,
            checksum_sha256=checksum,
            custom_metadata=metadata or {},
            chunk_ids=chunk_records,
            storage_class=bucket.storage_class
        )
        self.metadata.put_object_version(obj_version)

        etag = checksum[:32]
        print(f"[Storage] PUT {bucket_name}/{key} "
              f"({len(data)} bytes, {len(chunks)} chunks, "
              f"version={version_id[:8]})")

        return {
            "status": "ok",
            "bucket": bucket_name,
            "key": key,
            "version_id": version_id,
            "etag": etag,
            "size": len(data),
            "chunks": len(chunks)
        }

    def _split_into_chunks(self, data: bytes) -> List[bytes]:
        """Split data into fixed-size chunks."""
        chunks = []
        for i in range(0, len(data), self.chunk_size):
            chunks.append(data[i:i + self.chunk_size])
        return chunks

    # ─── Object Download ───

    def get_object(self, bucket_name: str, key: str,
                   version_id: str = None) -> Dict:
        """Download an object by reassembling chunks."""
        obj = self.metadata.get_object(bucket_name, key, version_id)
        if not obj:
            return {"status": "error", "message": "Object not found"}

        # Read and reassemble chunks in order
        data_parts = []
        for chunk_id in obj.chunk_ids:
            chunk = self.metadata.get_chunk(chunk_id)
            if not chunk:
                return {"status": "error",
                        "message": f"Chunk {chunk_id} missing"}

            # Try reading from any available replica
            chunk_data = None
            for node_id in chunk.data_nodes:
                chunk_data = self.data_storage.read_chunk(node_id, chunk_id)
                if chunk_data:
                    break

            if not chunk_data:
                return {"status": "error",
                        "message": f"All replicas failed for chunk {chunk_id}"}

            # Verify checksum
            actual_checksum = hashlib.md5(chunk_data).hexdigest()
            if actual_checksum != chunk.checksum_md5:
                return {"status": "error",
                        "message": "Data corruption detected"}

            data_parts.append(chunk_data)

        data = b"".join(data_parts)

        # Verify overall checksum
        if hashlib.sha256(data).hexdigest() != obj.checksum_sha256:
            return {"status": "error",
                    "message": "Object checksum mismatch"}

        print(f"[Storage] GET {bucket_name}/{key} → {len(data)} bytes")

        return {
            "status": "ok",
            "data": data,
            "content_type": obj.content_type,
            "size": obj.size,
            "version_id": obj.version_id,
            "etag": obj.checksum_sha256[:32],
            "metadata": obj.custom_metadata
        }

    # ─── Object Delete ───

    def delete_object(self, bucket_name: str, key: str) -> Dict:
        """Delete an object (or add delete marker if versioned)."""
        if self.metadata.delete_object(bucket_name, key):
            print(f"[Storage] DELETE {bucket_name}/{key}")
            return {"status": "deleted", "bucket": bucket_name, "key": key}
        return {"status": "error", "message": "Object not found"}

    # ─── List Objects ───

    def list_objects(self, bucket_name: str,
                     prefix: str = "",
                     max_keys: int = 1000) -> Dict:
        objects = self.metadata.list_objects(bucket_name, prefix, max_keys)
        return {
            "bucket": bucket_name,
            "prefix": prefix,
            "count": len(objects),
            "objects": [
                {
                    "key": obj.key,
                    "size": obj.size,
                    "content_type": obj.content_type,
                    "last_modified": str(obj.created_at),
                    "etag": obj.checksum_sha256[:32],
                    "storage_class": obj.storage_class.value
                }
                for obj in objects
            ]
        }

    # ─── Multipart Upload ───

    def initiate_multipart_upload(self, bucket_name: str,
                                  key: str) -> Dict:
        """Start a multipart upload session."""
        bucket = self.metadata.get_bucket(bucket_name)
        if not bucket:
            return {"status": "error", "message": "Bucket not found"}

        upload = MultipartUpload(
            upload_id=str(uuid.uuid4()),
            bucket_name=bucket_name,
            object_key=key
        )
        self.metadata.save_multipart(upload)

        print(f"[Storage] Initiated multipart upload: "
              f"{bucket_name}/{key} (upload_id={upload.upload_id[:8]})")

        return {
            "status": "initiated",
            "upload_id": upload.upload_id,
            "bucket": bucket_name,
            "key": key
        }

    def upload_part(self, upload_id: str, part_number: int,
                    data: bytes) -> Dict:
        """Upload a single part of a multipart upload."""
        upload = self.metadata.get_multipart(upload_id)
        if not upload or upload.status != "IN_PROGRESS":
            return {"status": "error", "message": "Invalid upload"}

        # Store the part as a chunk
        chunk_id = str(uuid.uuid4())
        chunk_checksum = hashlib.md5(data).hexdigest()

        target_nodes = self.placement.get_nodes_for_chunk(
            chunk_id, REPLICATION_FACTOR
        )

        for node_id in target_nodes:
            self.data_storage.write_chunk(node_id, chunk_id, data)

        chunk = Chunk(
            chunk_id=chunk_id,
            size=len(data),
            checksum_md5=chunk_checksum,
            data_nodes=target_nodes,
            sequence_num=part_number
        )
        self.metadata.save_chunk(chunk)

        upload.parts[part_number] = {
            "chunk_id": chunk_id,
            "size": len(data),
            "etag": chunk_checksum
        }
        self.metadata.save_multipart(upload)

        print(f"  [Multipart] Part {part_number}: "
              f"{len(data)} bytes (chunk={chunk_id[:8]})")

        return {
            "status": "ok",
            "part_number": part_number,
            "etag": chunk_checksum
        }

    def complete_multipart_upload(self, upload_id: str) -> Dict:
        """Complete a multipart upload, assembling all parts."""
        upload = self.metadata.get_multipart(upload_id)
        if not upload or upload.status != "IN_PROGRESS":
            return {"status": "error", "message": "Invalid upload"}

        # Sort parts by part number
        sorted_parts = sorted(upload.parts.items())
        chunk_ids = [info["chunk_id"] for _, info in sorted_parts]
        total_size = sum(info["size"] for _, info in sorted_parts)

        # Compute overall checksum
        hasher = hashlib.sha256()
        for _, info in sorted_parts:
            chunk = self.metadata.get_chunk(info["chunk_id"])
            for node_id in chunk.data_nodes:
                data = self.data_storage.read_chunk(node_id, chunk.chunk_id)
                if data:
                    hasher.update(data)
                    break

        # Create object version
        version_id = str(uuid.uuid4())
        obj_version = ObjectVersion(
            bucket_name=upload.bucket_name,
            key=upload.object_key,
            version_id=version_id,
            size=total_size,
            content_type="application/octet-stream",
            checksum_sha256=hasher.hexdigest(),
            custom_metadata={},
            chunk_ids=chunk_ids
        )
        self.metadata.put_object_version(obj_version)
        upload.status = "COMPLETED"

        print(f"[Storage] Completed multipart: "
              f"{upload.bucket_name}/{upload.object_key} "
              f"({len(sorted_parts)} parts, {total_size} bytes)")

        return {
            "status": "completed",
            "bucket": upload.bucket_name,
            "key": upload.object_key,
            "version_id": version_id,
            "size": total_size,
            "parts": len(sorted_parts)
        }

    # ─── Versioning ───

    def list_versions(self, bucket_name: str, key: str) -> Dict:
        versions = self.metadata.list_versions(bucket_name, key)
        return {
            "bucket": bucket_name,
            "key": key,
            "versions": [
                {
                    "version_id": v.version_id,
                    "size": v.size,
                    "is_latest": v.is_latest,
                    "is_delete_marker": v.is_delete_marker,
                    "created_at": str(v.created_at)
                }
                for v in versions
            ]
        }

    # ─── Pre-signed URLs ───

    def generate_presigned_url(self, bucket: str, key: str,
                               method: str = "GET",
                               expires_in: int = 3600) -> str:
        return self.url_generator.generate(bucket, key, method, expires_in)

    # ─── Storage Stats ───

    def get_storage_stats(self) -> Dict:
        total_objects = sum(
            len([v for v in versions if v.is_latest and not v.is_delete_marker])
            for versions in self.metadata.objects.values()
        )
        total_size = sum(
            v.size
            for versions in self.metadata.objects.values()
            for v in versions
            if v.is_latest and not v.is_delete_marker
        )
        total_chunks = len(self.metadata.chunks)
        nodes = len(self.placement.nodes)

        return {
            "buckets": len(self.metadata.buckets),
            "total_objects": total_objects,
            "total_size_bytes": total_size,
            "total_size_human": self._human_size(total_size),
            "total_chunks": total_chunks,
            "data_nodes": nodes,
            "replication_factor": REPLICATION_FACTOR
        }

    @staticmethod
    def _human_size(size: int) -> str:
        for unit in ['B', 'KB', 'MB', 'GB', 'TB']:
            if size < 1024:
                return f"{size:.1f} {unit}"
            size /= 1024
        return f"{size:.1f} PB"


# ─────────────────────────────────────────────
#  Demo
# ─────────────────────────────────────────────

def main():
    # Use smaller chunk size for demo
    storage = FileStorageService(chunk_size=1024)  # 1 KB chunks

    print("=" * 60)
    print("  FILE STORAGE SYSTEM DEMO")
    print("=" * 60)

    # 1. Create buckets
    print("\n--- Creating Buckets ---")
    print(storage.create_bucket("my-photos", "user-001"))
    print(storage.create_bucket("backups", "user-001", versioning=True))
    print(storage.create_bucket("logs", "user-002"))
    print(f"User-001 buckets: {storage.list_buckets('user-001')}")

    # 2. Upload objects
    print("\n--- Uploading Objects ---")

    # Small file
    small_data = b"Hello, World! This is a small text file."
    result = storage.put_object(
        "my-photos", "readme.txt", small_data,
        content_type="text/plain",
        metadata={"author": "alice", "project": "demo"}
    )
    print(f"  Small file: {result}")

    # Medium file (generates multiple chunks)
    medium_data = b"X" * 3000  # 3 KB → 3 chunks with 1KB chunk size
    result = storage.put_object(
        "my-photos", "photos/landscape.jpg", medium_data,
        content_type="image/jpeg"
    )
    print(f"  Medium file: {result}")

    # Nested keys
    for i in range(5):
        data = f"Log entry {i}: timestamp={datetime.utcnow()}".encode()
        storage.put_object("logs", f"2025/01/0{i+1}/app.log", data,
                           content_type="text/plain")

    # 3. Download objects
    print("\n--- Downloading Objects ---")
    result = storage.get_object("my-photos", "readme.txt")
    print(f"  Downloaded: {result['data'][:50]}... "
          f"({result['size']} bytes, type={result['content_type']})")

    result = storage.get_object("my-photos", "photos/landscape.jpg")
    print(f"  Downloaded: {result['size']} bytes, "
          f"matches original: {result['data'] == medium_data}")

    # 4. List objects
    print("\n--- Listing Objects ---")
    listing = storage.list_objects("my-photos")
    print(f"  All objects in 'my-photos': {listing['count']}")
    for obj in listing['objects']:
        print(f"    {obj['key']}: {obj['size']} bytes")

    listing = storage.list_objects("logs", prefix="2025/01/")
    print(f"\n  Logs with prefix '2025/01/': {listing['count']}")
    for obj in listing['objects']:
        print(f"    {obj['key']}")

    # 5. Versioning
    print("\n--- Versioning ---")
    storage.put_object("backups", "config.json",
                       b'{"version": 1, "debug": true}',
                       content_type="application/json")
    storage.put_object("backups", "config.json",
                       b'{"version": 2, "debug": false}',
                       content_type="application/json")
    storage.put_object("backups", "config.json",
                       b'{"version": 3, "debug": false, "cache": true}',
                       content_type="application/json")

    versions = storage.list_versions("backups", "config.json")
    print(f"  Versions of 'config.json': {len(versions['versions'])}")
    for v in versions['versions']:
        print(f"    v={v['version_id'][:8]}... "
              f"size={v['size']} latest={v['is_latest']}")

    # Get specific version
    result = storage.get_object(
        "backups", "config.json",
        version_id=versions['versions'][-1]['version_id']
    )
    print(f"  Oldest version content: {result['data']}")

    # 6. Multipart upload
    print("\n--- Multipart Upload ---")
    init = storage.initiate_multipart_upload("my-photos", "video/big_video.mp4")
    upload_id = init["upload_id"]

    # Upload parts
    for part_num in range(1, 4):
        part_data = bytes([part_num] * 1500)  # 1.5 KB each
        storage.upload_part(upload_id, part_num, part_data)

    # Complete
    complete = storage.complete_multipart_upload(upload_id)
    print(f"  Completed: {complete}")

    # 7. Pre-signed URL
    print("\n--- Pre-signed URLs ---")
    url = storage.generate_presigned_url(
        "my-photos", "readme.txt", "GET", expires_in=3600
    )
    print(f"  Pre-signed URL: {url}")

    # 8. Delete
    print("\n--- Deleting ---")
    result = storage.delete_object("my-photos", "readme.txt")
    print(f"  Delete result: {result}")

    # Verify delete
    result = storage.get_object("my-photos", "readme.txt")
    print(f"  After delete: {result}")

    # Versioned delete (adds marker)
    storage.delete_object("backups", "config.json")
    versions = storage.list_versions("backups", "config.json")
    print(f"  Versioned delete — versions now: {len(versions['versions'])}")
    for v in versions['versions']:
        marker = " [DELETE MARKER]" if v.get('is_delete_marker') else ""
        print(f"    {v['version_id'][:8]}... latest={v['is_latest']}{marker}")

    # 9. Storage stats
    print("\n--- Storage Stats ---")
    stats = storage.get_storage_stats()
    print(json.dumps(stats, indent=4))


if __name__ == "__main__":
    main()
```

### 8.7 Durability & Replication Strategy

```
┌────────────────────────────────────────────────────────────────────┐
│                  DURABILITY STRATEGY                               │
│                                                                    │
│  Goal: 11 nines (99.999999999%) durability                         │
│                                                                    │
│  1. REPLICATION (default)                                          │
│     ┌──────────────────────────────────────────────┐               │
│     │  3 replicas across 3 Availability Zones      │               │
│     │                                              │               │
│     │  AZ-1        AZ-2        AZ-3                │               │
│     │  ┌──────┐   ┌──────┐   ┌──────┐              │               │
│     │  │Copy 1│   │Copy 2│   │Copy 3│              │               │
│     │  └──────┘   └──────┘   └──────┘              │               │
│     │                                              │               │
│     │  Probability of losing all 3:                │               │
│     │  P(fail)³ = (0.01)³ = 10⁻⁶                   │               │
│     └──────────────────────────────────────────────┘               │
│                                                                    │
│  2. ERASURE CODING (for cold storage, saves space)                 │
│     ┌──────────────────────────────────────────────┐               │
│     │  Reed-Solomon (10, 4): 10 data + 4 parity    │               │
│     │  Can tolerate any 4 node failures             │               │
│     │  Storage overhead: 1.4x (vs 3x for replicas) │               │
│     │                                              │               │
│     │  File → split into 10 shards                 │               │
│     │       → compute 4 parity shards              │               │
│     │       → distribute 14 shards to 14 nodes     │               │
│     └──────────────────────────────────────────────┘               │
│                                                                    │
│  3. INTEGRITY CHECKING                                             │
│     ├─ MD5 checksum per chunk (verified on read)                   │
│     ├─ SHA-256 checksum per object (end-to-end)                    │
│     ├─ Background scrubbing (weekly full scan)                     │
│     └─ Bit-rot detection → auto-repair from replicas               │
│                                                                    │
│  4. GARBAGE COLLECTION                                             │
│     ├─ Orphaned chunks (no object reference) → delete after 7 days│
│     ├─ Expired multipart uploads → clean up after 24 hours         │
│     └─ Old versions beyond retention policy → archive/delete       │
└────────────────────────────────────────────────────────────────────┘
```

### 8.8 Overall Scaling Summary

```
┌────────────────────────────────────────────────────────────────────┐
│                SCALING ALL FOUR SYSTEMS                             │
│                                                                    │
│  ┌─────────────────────┬──────────────────────────────────────┐   │
│  │ System              │ Key Scaling Lever                     │   │
│  ├─────────────────────┼──────────────────────────────────────┤   │
│  │ Job Scheduler       │ Partition jobs by ID,                │   │
│  │                     │ scale workers independently,         │   │
│  │                     │ leader per partition                 │   │
│  ├─────────────────────┼──────────────────────────────────────┤   │
│  │ Notification System │ Kafka topics per channel+priority,   │   │
│  │                     │ consumer groups, multi-provider      │   │
│  │                     │ failover                             │   │
│  ├─────────────────────┼──────────────────────────────────────┤   │
│  │ Search Engine       │ Shard inverted index by term hash,   │   │
│  │                     │ scatter-gather queries, replicate    │   │
│  │                     │ shards for read throughput           │   │
│  ├─────────────────────┼──────────────────────────────────────┤   │
│  │ File Storage (S3)   │ Consistent hashing for data          │   │
│  │                     │ placement, shard metadata DB,        │   │
│  │                     │ 3-way replication across AZs         │   │
│  └─────────────────────┴──────────────────────────────────────┘   │
│                                                                    │
│  Common Patterns:                                                  │
│  ✓ Horizontal partitioning / sharding                             │
│  ✓ Leader election for coordination                               │
│  ✓ Async processing via message queues                            │
│  ✓ Replication for fault tolerance                                │
│  ✓ Consistent hashing for data distribution                      │
│  ✓ Idempotency for exactly-once semantics                        │
│  ✓ Circuit breakers for external dependencies                    │
└────────────────────────────────────────────────────────────────────┘
```

Each of these designs follows the same structural pattern: **identify the components, separate control plane from data plane, shard for scale, replicate for durability, and use async processing for throughput**. The Python implementations demonstrate the core algorithms and data structures that power these systems at scale.



# Large Scale System Design (HLD) — Systems 9–12

---

# 9. Design YouTube

## 9.1 Requirements

```
Functional:
  • Upload videos
  • Stream/watch videos (adaptive bitrate)
  • Search videos
  • Like, comment, subscribe
  • Recommendations

Non-Functional:
  • High availability (99.99%)
  • Low latency streaming (<200ms start)
  • Support 1B+ DAU, 500 hrs video uploaded/min
  • Global reach via CDN
  • Eventual consistency is acceptable
```

## 9.2 Capacity Estimation

```
DAU:               1 Billion
Videos watched/day: 5 per user → 5B views/day
Avg video size:     300 MB (original)
Uploads/day:        500K videos
Storage/day:        500K × 300MB = 150 TB (raw)
                    With multiple resolutions: ~500 TB/day
Bandwidth:
  Streaming: 5B × 50MB avg = 250 PB/day ≈ 23 Gbps average
```

## 9.3 High-Level Architecture

```
┌─────────────┐
│   Client     │  (Web / Mobile / Smart TV)
└──────┬───────┘
       │
       ▼
┌──────────────────────────────────────────────────────────────┐
│                        CDN (Edge)                            │
│   ┌──────────┐  ┌──────────┐  ┌──────────┐                  │
│   │PoP Node 1│  │PoP Node 2│  │PoP Node N│   (Serve videos) │
│   └──────────┘  └──────────┘  └──────────┘                  │
└──────────────────────────┬───────────────────────────────────┘
                           │ Cache miss
                           ▼
┌──────────────────────────────────────────────────────────────┐
│                     API Gateway / LB                         │
│              (Rate Limiting, Auth, Routing)                   │
└────┬─────────┬──────────┬──────────┬────────────┬────────────┘
     │         │          │          │            │
     ▼         ▼          ▼          ▼            ▼
┌────────┐┌────────┐┌──────────┐┌──────────┐┌────────────────┐
│Upload  ││Stream  ││Search    ││User      ││Recommendation  │
│Service ││Service ││Service   ││Service   ││Service         │
└───┬────┘└───┬────┘└────┬─────┘└────┬─────┘└───────┬────────┘
    │         │          │           │              │
    ▼         │          ▼           ▼              ▼
┌────────┐   │    ┌───────────┐┌──────────┐  ┌──────────┐
│Message │   │    │Elastic    ││User DB   │  │ML/Spark  │
│Queue   │   │    │Search     ││(MySQL)   │  │Pipeline  │
│(Kafka) │   │    └───────────┘└──────────┘  └──────────┘
└───┬────┘   │
    ▼        │
┌────────────┴─────────────────────────────────────────────┐
│              Video Processing Pipeline                    │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌─────────────┐ │
│  │Transcoder│ │Thumbnail │ │Watermark │ │DRM/Encrypt  │ │
│  │(FFmpeg)  │ │Generator │ │Inserter  │ │             │ │
│  └──────────┘ └──────────┘ └──────────┘ └─────────────┘ │
└───────────────────────┬──────────────────────────────────┘
                        │
                        ▼
┌──────────────────────────────────────────────────────────┐
│                  Object Storage (S3/GCS)                  │
│  ┌──────────────┐  ┌──────────────┐  ┌────────────────┐  │
│  │Raw Videos    │  │Processed     │  │Thumbnails      │  │
│  │              │  │Videos(multi) │  │                │  │
│  └──────────────┘  └──────────────┘  └────────────────┘  │
└──────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────┐
│                    Video Metadata DB                      │
│           (Cassandra / MySQL Vitess sharded)              │
└──────────────────────────────────────────────────────────┘
```

## 9.4 Data Models

```python
# ──────────────────────────────────────────────────────
#  Video Metadata (stored in MySQL/Vitess or Cassandra)
# ──────────────────────────────────────────────────────

"""
Table: videos
─────────────────────────────────────────────────
video_id        VARCHAR(11) PK    -- "dQw4w9WgXcQ"
user_id         BIGINT FK
title           VARCHAR(500)
description     TEXT
category        VARCHAR(50)
tags            JSON              -- ["music","pop"]
duration_sec    INT
status          ENUM('uploading','processing','live','failed','deleted')
visibility      ENUM('public','unlisted','private')
view_count      BIGINT DEFAULT 0
like_count      BIGINT DEFAULT 0
dislike_count   BIGINT DEFAULT 0
upload_time     DATETIME
thumbnail_url   VARCHAR(500)
─────────────────────────────────────────────────

Table: video_files
─────────────────────────────────────────────────
video_id        VARCHAR(11) FK
resolution      VARCHAR(10)       -- "1080p", "720p", "480p", "360p"
codec           VARCHAR(20)       -- "h264", "vp9", "av1"
bitrate_kbps    INT
file_url        VARCHAR(500)      -- S3 path
file_size_bytes BIGINT
PK(video_id, resolution, codec)
─────────────────────────────────────────────────

Table: users
─────────────────────────────────────────────────
user_id         BIGINT PK
username        VARCHAR(100) UNIQUE
email           VARCHAR(200) UNIQUE
channel_name    VARCHAR(200)
subscriber_count BIGINT DEFAULT 0
created_at      DATETIME
─────────────────────────────────────────────────

Table: comments
─────────────────────────────────────────────────
comment_id      BIGINT PK
video_id        VARCHAR(11) FK
user_id         BIGINT FK
parent_id       BIGINT NULL       -- for replies
content         TEXT
like_count      INT DEFAULT 0
created_at      DATETIME
─────────────────────────────────────────────────

Table: subscriptions
─────────────────────────────────────────────────
subscriber_id   BIGINT
channel_id      BIGINT
subscribed_at   DATETIME
PK(subscriber_id, channel_id)
─────────────────────────────────────────────────
"""
```

## 9.5 Core Flows — Python Examples

### Video Upload Flow

```python
import uuid
import hashlib
import boto3
from fastapi import FastAPI, UploadFile, File, Depends
from confluent_kafka import Producer
import json

app = FastAPI()
s3 = boto3.client('s3', region_name='us-east-1')
kafka_producer = Producer({'bootstrap.servers': 'kafka:9092'})

BUCKET_RAW = "youtube-raw-videos"
BUCKET_PROCESSED = "youtube-processed-videos"
CHUNK_SIZE = 5 * 1024 * 1024  # 5MB for multipart

# ─── Generate unique video ID (YouTube style: 11 chars) ───
def generate_video_id() -> str:
    """YouTube uses 11-character base64 IDs → 64^11 ≈ 7.3 × 10^19 possibilities."""
    raw = uuid.uuid4().bytes
    encoded = hashlib.md5(raw).hexdigest()[:11]
    return encoded

# ─── Resumable Upload (Chunked) ───
class UploadSession:
    """Manages resumable upload sessions."""
    
    def __init__(self, video_id: str, total_size: int):
        self.video_id = video_id
        self.total_size = total_size
        self.uploaded_bytes = 0
        self.parts = []
        
        # Initiate S3 multipart upload
        response = s3.create_multipart_upload(
            Bucket=BUCKET_RAW,
            Key=f"raw/{video_id}/original"
        )
        self.upload_id = response['UploadId']
    
    def upload_chunk(self, chunk: bytes, part_number: int) -> dict:
        """Upload a single chunk."""
        response = s3.upload_part(
            Bucket=BUCKET_RAW,
            Key=f"raw/{self.video_id}/original",
            UploadId=self.upload_id,
            PartNumber=part_number,
            Body=chunk
        )
        self.parts.append({
            'PartNumber': part_number,
            'ETag': response['ETag']
        })
        self.uploaded_bytes += len(chunk)
        return {
            'part_number': part_number,
            'uploaded': self.uploaded_bytes,
            'total': self.total_size,
            'progress': round(self.uploaded_bytes / self.total_size * 100, 1)
        }
    
    def complete(self):
        """Complete multipart upload."""
        s3.complete_multipart_upload(
            Bucket=BUCKET_RAW,
            Key=f"raw/{self.video_id}/original",
            UploadId=self.upload_id,
            MultipartUpload={'Parts': sorted(self.parts, key=lambda x: x['PartNumber'])}
        )

# Store active sessions
upload_sessions: dict[str, UploadSession] = {}

@app.post("/api/v1/videos/upload/init")
async def init_upload(title: str, description: str, file_size: int, user_id: int):
    """
    Step 1: Client requests an upload URL.
    Returns a session with video_id for chunked upload.
    """
    video_id = generate_video_id()
    
    # Save metadata to DB with status='uploading'
    await save_video_metadata(video_id, user_id, title, description, status='uploading')
    
    session = UploadSession(video_id, file_size)
    upload_sessions[video_id] = session
    
    return {
        "video_id": video_id,
        "upload_url": f"/api/v1/videos/upload/{video_id}/chunk",
        "chunk_size": CHUNK_SIZE,
        "total_parts": (file_size + CHUNK_SIZE - 1) // CHUNK_SIZE
    }

@app.put("/api/v1/videos/upload/{video_id}/chunk")
async def upload_chunk(video_id: str, part_number: int, chunk: UploadFile = File(...)):
    """Step 2: Upload individual chunks (supports resume on failure)."""
    session = upload_sessions[video_id]
    data = await chunk.read()
    result = session.upload_chunk(data, part_number)
    return result

@app.post("/api/v1/videos/upload/{video_id}/complete")
async def complete_upload(video_id: str):
    """Step 3: Finalize upload → trigger processing pipeline."""
    session = upload_sessions.pop(video_id)
    session.complete()
    
    # Update status
    await update_video_status(video_id, 'processing')
    
    # Publish to Kafka for async processing
    event = {
        "event": "video.uploaded",
        "video_id": video_id,
        "s3_path": f"s3://{BUCKET_RAW}/raw/{video_id}/original",
        "timestamp": "2024-01-15T10:30:00Z"
    }
    kafka_producer.produce(
        topic='video-processing',
        key=video_id.encode(),
        value=json.dumps(event).encode()
    )
    kafka_producer.flush()
    
    return {"video_id": video_id, "status": "processing"}
```

### Video Processing Pipeline (Transcoding)

```python
"""
Video Processing Pipeline
─────────────────────────
Triggered by Kafka consumer, uses FFmpeg for transcoding.

Pipeline stages:
  1. Download raw video from S3
  2. Validate & extract metadata
  3. Transcode to multiple resolutions
  4. Generate thumbnails
  5. Upload processed files to S3
  6. Update metadata DB
  7. Propagate to CDN
"""

import subprocess
import os
import json
from dataclasses import dataclass
from concurrent.futures import ThreadPoolExecutor
from confluent_kafka import Consumer

@dataclass
class TranscodeProfile:
    name: str
    resolution: str
    width: int
    height: int
    video_bitrate: str
    audio_bitrate: str
    
PROFILES = [
    TranscodeProfile("2160p", "3840x2160", 3840, 2160, "15000k", "192k"),
    TranscodeProfile("1080p", "1920x1080", 1920, 1080, "5000k",  "128k"),
    TranscodeProfile("720p",  "1280x720",  1280, 720,  "2500k",  "128k"),
    TranscodeProfile("480p",  "854x480",   854,  480,  "1000k",  "96k"),
    TranscodeProfile("360p",  "640x360",   640,  360,  "600k",   "96k"),
    TranscodeProfile("240p",  "426x240",   426,  240,  "400k",   "64k"),
]

class VideoProcessor:
    def __init__(self, video_id: str, input_path: str):
        self.video_id = video_id
        self.input_path = input_path
        self.output_dir = f"/tmp/processed/{video_id}"
        os.makedirs(self.output_dir, exist_ok=True)
    
    def extract_metadata(self) -> dict:
        """Use ffprobe to get video info."""
        cmd = [
            'ffprobe', '-v', 'quiet',
            '-print_format', 'json',
            '-show_format', '-show_streams',
            self.input_path
        ]
        result = subprocess.run(cmd, capture_output=True, text=True)
        return json.loads(result.stdout)
    
    def transcode(self, profile: TranscodeProfile) -> str:
        """
        Transcode video to a specific resolution using FFmpeg.
        Generates HLS segments for adaptive bitrate streaming.
        """
        output_path = f"{self.output_dir}/{profile.name}"
        os.makedirs(output_path, exist_ok=True)
        
        cmd = [
            'ffmpeg', '-i', self.input_path,
            '-vf', f'scale={profile.resolution}',
            '-c:v', 'libx264',
            '-b:v', profile.video_bitrate,
            '-c:a', 'aac',
            '-b:a', profile.audio_bitrate,
            '-hls_time', '6',                    # 6-second segments
            '-hls_playlist_type', 'vod',
            '-hls_segment_filename', f'{output_path}/segment_%04d.ts',
            f'{output_path}/playlist.m3u8',
            '-y'
        ]
        
        subprocess.run(cmd, check=True, capture_output=True)
        return output_path
    
    def generate_thumbnails(self) -> list[str]:
        """Generate thumbnails at different timestamps."""
        thumbnails = []
        for i, time_offset in enumerate([1, 5, 10, 30]):
            output = f"{self.output_dir}/thumb_{i}.jpg"
            cmd = [
                'ffmpeg', '-i', self.input_path,
                '-ss', str(time_offset),
                '-vframes', '1',
                '-vf', 'scale=1280:720',
                output, '-y'
            ]
            try:
                subprocess.run(cmd, check=True, capture_output=True)
                thumbnails.append(output)
            except subprocess.CalledProcessError:
                pass
        return thumbnails
    
    def generate_master_playlist(self, profiles_processed: list[TranscodeProfile]) -> str:
        """
        Generate HLS master playlist for adaptive bitrate streaming.
        Client uses this to switch quality based on bandwidth.
        """
        master = "#EXTM3U\n#EXT-X-VERSION:3\n\n"
        
        for profile in profiles_processed:
            bandwidth = int(profile.video_bitrate.replace('k', '')) * 1000
            master += (
                f"#EXT-X-STREAM-INF:BANDWIDTH={bandwidth},"
                f"RESOLUTION={profile.resolution}\n"
                f"{profile.name}/playlist.m3u8\n\n"
            )
        
        master_path = f"{self.output_dir}/master.m3u8"
        with open(master_path, 'w') as f:
            f.write(master)
        return master_path
    
    def process(self):
        """Full processing pipeline."""
        print(f"[{self.video_id}] Starting processing...")
        
        # 1. Extract metadata
        metadata = self.extract_metadata()
        source_height = int(metadata['streams'][0].get('height', 1080))
        
        # 2. Filter profiles (don't upscale)
        applicable = [p for p in PROFILES if p.height <= source_height]
        
        # 3. Transcode in parallel
        with ThreadPoolExecutor(max_workers=3) as executor:
            futures = {
                executor.submit(self.transcode, profile): profile
                for profile in applicable
            }
            processed = []
            for future in futures:
                future.result()  # wait
                processed.append(futures[future])
        
        # 4. Generate thumbnails
        thumbnails = self.generate_thumbnails()
        
        # 5. Generate master playlist
        self.generate_master_playlist(processed)
        
        # 6. Upload all to S3
        self._upload_to_s3()
        
        # 7. Update DB status → 'live'
        print(f"[{self.video_id}] Processing complete!")
        return {
            "video_id": self.video_id,
            "resolutions": [p.name for p in processed],
            "thumbnails": len(thumbnails),
            "status": "live"
        }
    
    def _upload_to_s3(self):
        """Upload all processed files to S3."""
        for root, dirs, files in os.walk(self.output_dir):
            for file in files:
                local_path = os.path.join(root, file)
                s3_key = f"processed/{self.video_id}/{os.path.relpath(local_path, self.output_dir)}"
                s3.upload_file(local_path, BUCKET_PROCESSED, s3_key)


# ─── Kafka Consumer (Processing Worker) ───
def processing_worker():
    consumer = Consumer({
        'bootstrap.servers': 'kafka:9092',
        'group.id': 'video-processors',
        'auto.offset.reset': 'earliest'
    })
    consumer.subscribe(['video-processing'])
    
    while True:
        msg = consumer.poll(1.0)
        if msg is None:
            continue
        
        event = json.loads(msg.value())
        video_id = event['video_id']
        
        # Download from S3
        local_path = f"/tmp/raw/{video_id}"
        s3.download_file(BUCKET_RAW, f"raw/{video_id}/original", local_path)
        
        # Process
        processor = VideoProcessor(video_id, local_path)
        result = processor.process()
        
        # Notify completion
        kafka_producer.produce(
            'video-ready',
            key=video_id.encode(),
            value=json.dumps(result).encode()
        )
```

### Video Streaming (Adaptive Bitrate)

```python
"""
Streaming Flow:
  1. Client requests video → gets master.m3u8 from CDN
  2. Client's player picks appropriate quality playlist
  3. Player fetches .ts segments sequentially
  4. Player monitors bandwidth → switches quality dynamically
"""

from fastapi import FastAPI, Request
from fastapi.responses import RedirectResponse, StreamingResponse
import redis

app = FastAPI()
redis_client = redis.Redis(host='redis', port=6379)

@app.get("/api/v1/videos/{video_id}/stream")
async def get_stream_url(video_id: str, request: Request):
    """
    Returns the CDN URL for the master playlist.
    CDN selection is based on client's geographic location.
    """
    # Determine closest CDN PoP based on client IP
    client_ip = request.client.host
    cdn_node = select_closest_cdn(client_ip)
    
    # Generate signed URL (time-limited for security)
    signed_url = generate_signed_cdn_url(
        cdn_node=cdn_node,
        path=f"/processed/{video_id}/master.m3u8",
        expiry_seconds=3600
    )
    
    # Increment view count asynchronously
    redis_client.incr(f"views:{video_id}")
    
    return {"stream_url": signed_url, "cdn_node": cdn_node}


# ─── View Count Aggregation (Batch) ───
async def flush_view_counts():
    """
    Periodically flush view counts from Redis to DB.
    Avoids write-heavy load on DB for every view.
    
    Runs every 30 seconds via a cron/scheduler.
    """
    cursor = 0
    while True:
        cursor, keys = redis_client.scan(cursor, match="views:*", count=100)
        for key in keys:
            video_id = key.decode().split(":")[1]
            count = int(redis_client.getdel(key) or 0)
            if count > 0:
                # Batch update DB
                await execute_sql(
                    "UPDATE videos SET view_count = view_count + %s WHERE video_id = %s",
                    (count, video_id)
                )
        if cursor == 0:
            break


def select_closest_cdn(client_ip: str) -> str:
    """
    Use GeoIP to find closest CDN Point of Presence.
    In production: DNS-based (like Route53 latency routing) or Anycast.
    """
    # Simplified: map IP ranges to regions
    cdn_nodes = {
        "us-east": "cdn-us-east.youtube.example.com",
        "us-west": "cdn-us-west.youtube.example.com",
        "eu-west": "cdn-eu-west.youtube.example.com",
        "ap-south": "cdn-ap-south.youtube.example.com",
    }
    region = geoip_lookup(client_ip)  # returns region key
    return cdn_nodes.get(region, cdn_nodes["us-east"])
```

### Search & Recommendation

```python
"""
Search: Elasticsearch for full-text search on title, description, tags.
Recommendations: Collaborative filtering + content-based.
"""

from elasticsearch import Elasticsearch

es = Elasticsearch(["http://elasticsearch:9200"])

# ─── Index a video ───
def index_video(video_id: str, title: str, description: str, 
                tags: list, category: str, channel: str):
    es.index(index="videos", id=video_id, document={
        "title": title,
        "description": description,
        "tags": tags,
        "category": category,
        "channel": channel,
        "upload_date": "2024-01-15",
        "view_count": 0,
        "like_count": 0,
    })

# ─── Search videos ───
def search_videos(query: str, page: int = 0, size: int = 20) -> list:
    result = es.search(index="videos", body={
        "query": {
            "multi_match": {
                "query": query,
                "fields": ["title^3", "tags^2", "description", "channel"],
                "type": "best_fields",
                "fuzziness": "AUTO"
            }
        },
        "sort": [
            {"_score": "desc"},
            {"view_count": "desc"}
        ],
        "from": page * size,
        "size": size
    })
    return [hit["_source"] | {"video_id": hit["_id"]} for hit in result["hits"]["hits"]]


# ─── Simple Recommendation Engine ───
class RecommendationEngine:
    """
    Hybrid approach:
      1. Content-based: similar videos by tags/category
      2. Collaborative: users who watched X also watched Y
      3. Trending: popular videos in user's region
    """
    
    def get_recommendations(self, user_id: int, current_video_id: str,
                            limit: int = 20) -> list:
        # Weighted merge of different strategies
        content_based = self._content_based(current_video_id, limit=10)
        collaborative = self._collaborative(user_id, limit=10)
        trending = self._trending(limit=5)
        
        # Merge, deduplicate, rank
        seen = set()
        results = []
        for video in content_based + collaborative + trending:
            if video["video_id"] not in seen:
                seen.add(video["video_id"])
                results.append(video)
        
        return results[:limit]
    
    def _content_based(self, video_id: str, limit: int) -> list:
        """Find similar videos using Elasticsearch more-like-this."""
        result = es.search(index="videos", body={
            "query": {
                "more_like_this": {
                    "fields": ["title", "tags", "category"],
                    "like": [{"_index": "videos", "_id": video_id}],
                    "min_term_freq": 1,
                    "min_doc_freq": 1
                }
            },
            "size": limit
        })
        return [hit["_source"] for hit in result["hits"]["hits"]]
    
    def _collaborative(self, user_id: int, limit: int) -> list:
        """Users who watched similar videos also watched..."""
        # In production: precomputed via Spark/ML pipeline
        # Uses user-item interaction matrix → ALS/SVD
        watched = get_user_watch_history(user_id, limit=50)
        # Query precomputed similar-users table
        similar_users = get_similar_users(user_id, limit=20)
        candidates = get_unwatched_popular_among(similar_users, watched, limit)
        return candidates
    
    def _trending(self, limit: int) -> list:
        """Videos trending in the last 24 hours."""
        # Precomputed hourly via batch job
        return redis_client.zrevrange("trending:global", 0, limit - 1)
```

## 9.6 Architecture Summary

```
Key Design Decisions:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
│ Component         │ Technology            │ Why                    │
├───────────────────┼───────────────────────┼────────────────────────┤
│ Video Storage     │ S3 / GCS              │ Unlimited, cheap       │
│ Metadata DB       │ MySQL Vitess          │ Strong consistency     │
│ Video Delivery    │ CDN (CloudFront)      │ Low latency globally   │
│ Streaming         │ HLS / DASH            │ Adaptive bitrate       │
│ Processing Queue  │ Kafka                 │ Durable, ordered       │
│ Transcoding       │ FFmpeg workers        │ Industry standard      │
│ Search            │ Elasticsearch         │ Full-text search       │
│ View Counts       │ Redis → batch to DB   │ High write throughput  │
│ Recommendations   │ Spark ML pipeline     │ Offline precomputation │
│ Thumbnails        │ S3 + CDN              │ Static asset delivery  │
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

---

# 10. Design WhatsApp

## 10.1 Requirements

```
Functional:
  • 1:1 messaging (text, media)
  • Group messaging (up to 1024 members)
  • Online/offline status & last seen
  • Message delivery receipts (sent ✓, delivered ✓✓, read 🔵✓✓)
  • End-to-end encryption
  • Media sharing (images, videos, documents)
  • Push notifications for offline users

Non-Functional:
  • Ultra-low latency (<100ms for message delivery)
  • Exactly-once delivery semantics
  • 2B+ users, 100B+ messages/day
  • Messages stored only until delivered (or 30 days)
  • End-to-end encrypted
```

## 10.2 Capacity Estimation

```
Total users:           2 Billion
DAU:                   500 Million
Messages/day:          100 Billion → ~1.15M messages/sec
Avg message size:      100 bytes (text)
Storage/day (text):    100B × 100B = 10 TB/day
Media messages:        ~5% = 5B/day, avg 200KB → 1 PB/day
Connections:           500M concurrent WebSocket connections
```

## 10.3 High-Level Architecture

```
┌────────────┐        ┌────────────┐
│  Client A  │        │  Client B  │
│  (Mobile)  │        │  (Mobile)  │
└──────┬─────┘        └──────┬─────┘
       │ WebSocket           │ WebSocket
       │                     │
       ▼                     ▼
┌──────────────────────────────────────────────────────────┐
│                    Load Balancer                          │
│         (L4 - TCP level for WebSocket stickiness)        │
└─────────┬──────────────────────────────────┬─────────────┘
          │                                  │
          ▼                                  ▼
┌──────────────────┐              ┌──────────────────┐
│  Chat Server 1   │              │  Chat Server N   │
│  (WebSocket      │   ◄────────► │  (WebSocket      │
│   Gateway)       │   Msg Relay  │   Gateway)       │
│                  │   via Redis  │                  │
│  Manages ~100K   │   Pub/Sub    │  Manages ~100K   │
│  connections     │              │  connections     │
└────────┬─────────┘              └────────┬─────────┘
         │                                 │
         └──────────┬──────────────────────┘
                    │
         ┌──────────┼──────────────────────────────┐
         │          │                              │
         ▼          ▼                              ▼
┌──────────┐ ┌─────────────┐              ┌──────────────┐
│  Redis   │ │  Message    │              │  Push         │
│  Cluster │ │  Queue      │              │  Notification │
│          │ │  (Kafka)    │              │  Service      │
│• Sessions│ │             │              │  (APNs/FCM)  │
│• Presence│ │• Offline    │              └──────────────┘
│• Pub/Sub │ │  message    │
└──────────┘ │  storage    │
             └──────┬──────┘
                    │
                    ▼
         ┌─────────────────────┐
         │   Message Store     │
         │   (Cassandra)       │
         │                     │
         │ • Partitioned by    │
         │   conversation_id   │
         │ • TTL: 30 days      │
         └─────────────────────┘
         
         ┌─────────────────────┐
         │   User/Group DB     │
         │   (MySQL sharded)   │
         │                     │
         │ • User profiles     │
         │ • Group metadata    │
         │ • Contacts          │
         └─────────────────────┘
         
         ┌─────────────────────┐
         │   Media Store       │
         │   (S3 / Blob)       │
         │                     │
         │ • Encrypted media   │
         │ • Signed URLs       │
         └─────────────────────┘
```

## 10.4 Data Models

```python
"""
─── Cassandra: Messages ───
Partitioned by conversation for efficient range queries.

CREATE TABLE messages (
    conversation_id  TEXT,        -- sorted(user_a, user_b) hash for 1:1
    message_id       TIMEUUID,   -- TimeUUID for ordering
    sender_id        BIGINT,
    message_type     TEXT,        -- 'text', 'image', 'video', 'audio', 'document'
    content          BLOB,        -- encrypted message content
    media_url        TEXT,        -- S3 URL for media (encrypted)
    status           TEXT,        -- 'sent', 'delivered', 'read'
    created_at       TIMESTAMP,
    PRIMARY KEY (conversation_id, message_id)
) WITH CLUSTERING ORDER BY (message_id DESC)
  AND default_time_to_live = 2592000;  -- 30 day TTL

─── MySQL: Users ───
CREATE TABLE users (
    user_id          BIGINT PRIMARY KEY AUTO_INCREMENT,
    phone_number     VARCHAR(20) UNIQUE,
    display_name     VARCHAR(100),
    profile_pic_url  VARCHAR(500),
    public_key       BLOB,           -- for E2E encryption
    last_seen        DATETIME,
    status_text      VARCHAR(200),
    created_at       DATETIME
);

─── MySQL: Groups ───
CREATE TABLE groups (
    group_id         BIGINT PRIMARY KEY,
    group_name       VARCHAR(200),
    created_by       BIGINT,
    created_at       DATETIME,
    max_members      INT DEFAULT 1024
);

CREATE TABLE group_members (
    group_id         BIGINT,
    user_id          BIGINT,
    role             ENUM('admin', 'member'),
    joined_at        DATETIME,
    PRIMARY KEY (group_id, user_id)
);
"""
```

## 10.5 Core Components — Python Implementation

### WebSocket Chat Server

```python
import asyncio
import json
import uuid
import time
from datetime import datetime
from dataclasses import dataclass, field
from typing import Optional
from fastapi import FastAPI, WebSocket, WebSocketDisconnect
import aioredis
from cassandra.cluster import Cluster
from cassandra.query import SimpleStatement

app = FastAPI()

# ─── Connection Manager ───
class ConnectionManager:
    """
    Manages WebSocket connections on THIS server instance.
    Each server handles ~100K concurrent connections.
    """
    
    def __init__(self):
        self.active_connections: dict[int, WebSocket] = {}  # user_id → ws
        self.redis: Optional[aioredis.Redis] = None
    
    async def init_redis(self):
        self.redis = await aioredis.from_url("redis://redis-cluster:6379")
    
    async def connect(self, user_id: int, websocket: WebSocket):
        await websocket.accept()
        self.active_connections[user_id] = websocket
        
        # Register in Redis: which server handles this user
        server_id = os.environ.get("SERVER_ID", "chat-server-1")
        await self.redis.hset("user:sessions", str(user_id), server_id)
        await self.redis.set(f"user:online:{user_id}", "1")
        
        # Subscribe to this user's Redis channel (for cross-server messages)
        pubsub = self.redis.pubsub()
        await pubsub.subscribe(f"user:{user_id}:messages")
        asyncio.create_task(self._listen_redis(user_id, pubsub))
        
        # Deliver any pending offline messages
        await self._deliver_offline_messages(user_id)
        
        print(f"User {user_id} connected on {server_id}")
    
    async def disconnect(self, user_id: int):
        self.active_connections.pop(user_id, None)
        await self.redis.hdel("user:sessions", str(user_id))
        await self.redis.delete(f"user:online:{user_id}")
        
        # Update last_seen
        await self.redis.set(f"user:lastseen:{user_id}", str(int(time.time())))
    
    async def send_to_user(self, user_id: int, message: dict):
        """
        Send message to a user.
        If user is on THIS server → direct WebSocket send.
        If user is on ANOTHER server → publish via Redis Pub/Sub.
        If user is OFFLINE → store in Kafka for offline delivery + push notification.
        """
        # Check if user is on this server
        if user_id in self.active_connections:
            ws = self.active_connections[user_id]
            await ws.send_json(message)
            return "delivered"
        
        # Check if user is online on another server
        target_server = await self.redis.hget("user:sessions", str(user_id))
        if target_server:
            # Publish to Redis Pub/Sub → other server picks it up
            await self.redis.publish(
                f"user:{user_id}:messages",
                json.dumps(message)
            )
            return "delivered"
        
        # User is offline → queue message
        await self._store_offline_message(user_id, message)
        await self._send_push_notification(user_id, message)
        return "stored"
    
    async def _listen_redis(self, user_id: int, pubsub):
        """Listen for messages from other servers via Redis Pub/Sub."""
        async for msg in pubsub.listen():
            if msg["type"] == "message":
                data = json.loads(msg["data"])
                if user_id in self.active_connections:
                    await self.active_connections[user_id].send_json(data)
    
    async def _store_offline_message(self, user_id: int, message: dict):
        """Store message in sorted set for offline delivery."""
        await self.redis.zadd(
            f"offline:{user_id}",
            {json.dumps(message): message["timestamp"]}
        )
    
    async def _deliver_offline_messages(self, user_id: int):
        """Deliver all pending offline messages when user connects."""
        messages = await self.redis.zrangebyscore(
            f"offline:{user_id}", "-inf", "+inf"
        )
        for msg_data in messages:
            message = json.loads(msg_data)
            await self.active_connections[user_id].send_json(message)
        
        # Clear delivered messages
        if messages:
            await self.redis.delete(f"offline:{user_id}")
    
    async def _send_push_notification(self, user_id: int, message: dict):
        """Send push notification via APNs/FCM."""
        # Publish to notification service queue
        await self.redis.lpush("push:queue", json.dumps({
            "user_id": user_id,
            "title": message.get("sender_name", "New Message"),
            "body": message.get("preview", "You have a new message"),
            "data": {"conversation_id": message.get("conversation_id")}
        }))


manager = ConnectionManager()

@app.on_event("startup")
async def startup():
    await manager.init_redis()


# ─── WebSocket Endpoint ───
@app.websocket("/ws/{user_id}")
async def websocket_endpoint(websocket: WebSocket, user_id: int):
    await manager.connect(user_id, websocket)
    
    try:
        while True:
            data = await websocket.receive_json()
            await handle_message(user_id, data)
    except WebSocketDisconnect:
        await manager.disconnect(user_id)


async def handle_message(sender_id: int, data: dict):
    """
    Route incoming messages based on type.
    """
    msg_type = data.get("type")
    
    if msg_type == "text_message":
        await handle_text_message(sender_id, data)
    elif msg_type == "group_message":
        await handle_group_message(sender_id, data)
    elif msg_type == "ack":
        await handle_ack(sender_id, data)
    elif msg_type == "typing":
        await handle_typing_indicator(sender_id, data)
    elif msg_type == "read_receipt":
        await handle_read_receipt(sender_id, data)
```

### Message Handling with Delivery Guarantees

```python
"""
Message Delivery Flow:
━━━━━━━━━━━━━━━━━━━━━━
 Client A                Server              Client B
    │                       │                    │
    │──── Send Message ────►│                    │
    │                       │── Store in DB ──►  │
    │◄──── ACK (sent ✓) ───│                    │
    │                       │                    │
    │                       │── Deliver ────────►│
    │                       │◄── ACK (received) ─│
    │◄── Delivered (✓✓) ───│                    │
    │                       │                    │
    │                       │    [User opens]    │
    │                       │◄── Read receipt ───│
    │◄──── Read (🔵✓✓) ───│                    │
"""

from cassandra.cluster import Cluster
from cassandra.util import uuid_from_time

# Cassandra connection
cassandra = Cluster(['cassandra-node1', 'cassandra-node2'])
session = cassandra.connect('whatsapp')

# Prepared statements for performance
INSERT_MSG = session.prepare("""
    INSERT INTO messages (conversation_id, message_id, sender_id, 
                          message_type, content, status, created_at)
    VALUES (?, ?, ?, ?, ?, ?, ?)
""")

UPDATE_STATUS = session.prepare("""
    UPDATE messages SET status = ? 
    WHERE conversation_id = ? AND message_id = ?
""")


def get_conversation_id(user_a: int, user_b: int) -> str:
    """Deterministic conversation ID for 1:1 chats."""
    return f"conv:{min(user_a, user_b)}:{max(user_a, user_b)}"


async def handle_text_message(sender_id: int, data: dict):
    """
    Process a 1:1 text message with exactly-once delivery.
    """
    recipient_id = data["recipient_id"]
    content = data["content"]
    client_msg_id = data["client_message_id"]  # Client-generated for idempotency
    
    conversation_id = get_conversation_id(sender_id, recipient_id)
    message_id = uuid_from_time(time.time())  # TimeUUID
    
    # ─── 1. Persist to Cassandra ───
    session.execute(INSERT_MSG, (
        conversation_id, message_id, sender_id,
        'text', content.encode(), 'sent', datetime.utcnow()
    ))
    
    # ─── 2. ACK to sender (message stored → single tick ✓) ───
    await manager.send_to_user(sender_id, {
        "type": "ack",
        "client_message_id": client_msg_id,
        "message_id": str(message_id),
        "status": "sent",  # ✓
        "timestamp": int(time.time())
    })
    
    # ─── 3. Deliver to recipient ───
    message_payload = {
        "type": "text_message",
        "message_id": str(message_id),
        "conversation_id": conversation_id,
        "sender_id": sender_id,
        "content": content,
        "timestamp": int(time.time())
    }
    
    delivery_status = await manager.send_to_user(recipient_id, message_payload)
    
    # ─── 4. If delivered, notify sender (double tick ✓✓) ───
    if delivery_status == "delivered":
        session.execute(UPDATE_STATUS, ('delivered', conversation_id, message_id))
        await manager.send_to_user(sender_id, {
            "type": "status_update",
            "message_id": str(message_id),
            "status": "delivered"  # ✓✓
        })


async def handle_read_receipt(reader_id: int, data: dict):
    """User has read messages → notify sender."""
    conversation_id = data["conversation_id"]
    last_read_message_id = data["last_read_message_id"]
    
    # Update all messages up to this point as 'read'
    # (In practice, batch update)
    session.execute(UPDATE_STATUS, ('read', conversation_id, 
                                     uuid.UUID(last_read_message_id)))
    
    # Notify the other party
    other_user_id = data["sender_id"]
    await manager.send_to_user(other_user_id, {
        "type": "read_receipt",
        "conversation_id": conversation_id,
        "last_read_message_id": last_read_message_id,
        "reader_id": reader_id
    })


async def handle_group_message(sender_id: int, data: dict):
    """
    Group message: fan-out to all group members.
    For large groups, use async fan-out via message queue.
    """
    group_id = data["group_id"]
    content = data["content"]
    
    conversation_id = f"group:{group_id}"
    message_id = uuid_from_time(time.time())
    
    # Persist message once
    session.execute(INSERT_MSG, (
        conversation_id, message_id, sender_id,
        'text', content.encode(), 'sent', datetime.utcnow()
    ))
    
    # Get group members
    members = await get_group_members(group_id)
    
    message_payload = {
        "type": "group_message",
        "message_id": str(message_id),
        "group_id": group_id,
        "sender_id": sender_id,
        "content": content,
        "timestamp": int(time.time())
    }
    
    # Fan-out to all members (except sender)
    tasks = []
    for member_id in members:
        if member_id != sender_id:
            tasks.append(manager.send_to_user(member_id, message_payload))
    
    await asyncio.gather(*tasks)
```

### End-to-End Encryption (Signal Protocol Simplified)

```python
"""
WhatsApp uses the Signal Protocol for E2E encryption.
Simplified implementation of the key concepts.
"""

from cryptography.hazmat.primitives.asymmetric.x25519 import (
    X25519PrivateKey, X25519PublicKey
)
from cryptography.hazmat.primitives.ciphers.aead import AESGCM
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.kdf.hkdf import HKDF
import os

class E2EEncryption:
    """
    Simplified Signal Protocol:
    1. Each user generates an identity key pair
    2. Key exchange happens on first message (X3DH)
    3. Messages encrypted with derived symmetric key
    4. Server NEVER sees plaintext
    """
    
    def __init__(self):
        # Long-term identity key
        self.identity_key = X25519PrivateKey.generate()
        self.identity_public = self.identity_key.public_key()
        
        # Ephemeral keys for each session
        self.sessions: dict[int, bytes] = {}  # peer_id → shared_secret
    
    def get_public_key_bytes(self) -> bytes:
        """Public key to share with server for key distribution."""
        from cryptography.hazmat.primitives.serialization import (
            Encoding, PublicFormat
        )
        return self.identity_public.public_bytes(
            Encoding.Raw, PublicFormat.Raw
        )
    
    def establish_session(self, peer_id: int, peer_public_key_bytes: bytes):
        """
        Perform key exchange (simplified X3DH → Diffie-Hellman).
        In production: includes prekeys, signed prekeys, etc.
        """
        peer_public_key = X25519PublicKey.from_public_bytes(peer_public_key_bytes)
        
        # Diffie-Hellman key exchange
        shared_secret = self.identity_key.exchange(peer_public_key)
        
        # Derive symmetric key using HKDF
        derived_key = HKDF(
            algorithm=hashes.SHA256(),
            length=32,
            salt=None,
            info=b"whatsapp-e2e"
        ).derive(shared_secret)
        
        self.sessions[peer_id] = derived_key
        return derived_key
    
    def encrypt_message(self, peer_id: int, plaintext: str) -> tuple[bytes, bytes]:
        """Encrypt a message for a peer."""
        key = self.sessions[peer_id]
        nonce = os.urandom(12)  # 96-bit nonce
        
        aesgcm = AESGCM(key)
        ciphertext = aesgcm.encrypt(nonce, plaintext.encode(), None)
        
        return nonce, ciphertext
    
    def decrypt_message(self, peer_id: int, nonce: bytes, 
                        ciphertext: bytes) -> str:
        """Decrypt a message from a peer."""
        key = self.sessions[peer_id]
        
        aesgcm = AESGCM(key)
        plaintext = aesgcm.decrypt(nonce, ciphertext, None)
        
        return plaintext.decode()


# ─── Usage Example ───
def demo_e2e():
    alice = E2EEncryption()
    bob = E2EEncryption()
    
    # Exchange public keys (via server)
    alice.establish_session(peer_id=2, peer_public_key_bytes=bob.get_public_key_bytes())
    bob.establish_session(peer_id=1, peer_public_key_bytes=alice.get_public_key_bytes())
    
    # Alice encrypts
    nonce, ciphertext = alice.encrypt_message(peer_id=2, plaintext="Hello Bob!")
    
    # Bob decrypts
    plaintext = bob.decrypt_message(peer_id=1, nonce=nonce, ciphertext=ciphertext)
    print(f"Decrypted: {plaintext}")  # "Hello Bob!"
    
    # Server only sees ciphertext — cannot read the message!
```

### Presence (Online/Offline/Last Seen)

```python
"""
Presence Service:
  • Track online/offline status
  • Last seen timestamp
  • Typing indicators
  
  Uses Redis with heartbeat mechanism.
"""

class PresenceService:
    def __init__(self, redis_client):
        self.redis = redis_client
        self.HEARTBEAT_INTERVAL = 30    # seconds
        self.ONLINE_TIMEOUT = 45        # seconds
    
    async def heartbeat(self, user_id: int):
        """
        Client sends heartbeat every 30s.
        If no heartbeat for 45s → user is offline.
        """
        await self.redis.setex(
            f"presence:{user_id}",
            self.ONLINE_TIMEOUT,
            "online"
        )
        await self.redis.set(
            f"lastseen:{user_id}",
            str(int(time.time()))
        )
    
    async def is_online(self, user_id: int) -> bool:
        status = await self.redis.get(f"presence:{user_id}")
        return status == b"online"
    
    async def get_last_seen(self, user_id: int) -> Optional[int]:
        ts = await self.redis.get(f"lastseen:{user_id}")
        return int(ts) if ts else None
    
    async def get_bulk_presence(self, user_ids: list[int]) -> dict:
        """
        Get online status for multiple users (e.g., contact list).
        Uses Redis pipeline for efficiency.
        """
        pipe = self.redis.pipeline()
        for uid in user_ids:
            pipe.get(f"presence:{uid}")
        
        results = await pipe.execute()
        return {
            uid: (result == b"online")
            for uid, result in zip(user_ids, results)
        }
    
    async def send_typing_indicator(self, sender_id: int, 
                                     recipient_id: int, is_typing: bool):
        """Ephemeral typing indicator — not persisted."""
        await manager.send_to_user(recipient_id, {
            "type": "typing",
            "user_id": sender_id,
            "is_typing": is_typing
        })
```

## 10.6 Architecture Summary

```
Key Design Decisions:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
│ Component           │ Choice              │ Why                      │
├─────────────────────┼─────────────────────┼──────────────────────────┤
│ Protocol            │ WebSocket           │ Full-duplex, low latency │
│ Message Store       │ Cassandra           │ Write-heavy, partitioned │
│ Session/Presence    │ Redis Cluster       │ Fast K-V, TTL, Pub/Sub   │
│ Cross-server relay  │ Redis Pub/Sub       │ Simple, fast routing     │
│ Offline queue       │ Redis Sorted Sets   │ Ordered delivery         │
│ User metadata       │ MySQL sharded       │ Relational, consistent   │
│ Media storage       │ S3 + signed URLs    │ Scalable blob storage    │
│ Encryption          │ Signal Protocol     │ Proven E2E security      │
│ Push notifications  │ APNs + FCM          │ iOS + Android            │
│ Group fan-out       │ Async workers       │ Don't block sender       │
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

---

# 11. Design Instagram Feed

## 11.1 Requirements

```
Functional:
  • Post photos/videos with captions
  • Follow/unfollow users
  • News feed: see posts from people you follow
  • Like, comment on posts
  • Stories (24-hour ephemeral content)
  • Explore/discover page

Non-Functional:
  • Feed generation < 500ms
  • 500M DAU
  • 100M photos uploaded/day
  • Feed should be ranked (not purely chronological)
  • High availability, eventual consistency OK for feed
```

## 11.2 Capacity Estimation

```
DAU:                   500 Million
Posts/day:             100 Million
Avg photo size:        2 MB
Storage/day (photos):  100M × 2MB = 200 TB
Avg follows per user:  200
Feed requests/day:     500M × 10 opens = 5B
Feed generation:       5B / 86400 ≈ 58K requests/sec
```

## 11.3 High-Level Architecture

```
┌─────────────────────┐
│      Clients        │
│  (iOS/Android/Web)  │
└──────────┬──────────┘
           │
           ▼
┌──────────────────────────────────────────────────────────────┐
│                      API Gateway                              │
│            (Auth, Rate Limiting, Routing)                      │
└──┬─────────┬──────────┬──────────┬──────────┬────────────────┘
   │         │          │          │          │
   ▼         ▼          ▼          ▼          ▼
┌──────┐ ┌───────┐ ┌───────┐ ┌────────┐ ┌──────────┐
│Post  │ │Feed   │ │User   │ │Media   │ │Notifica- │
│Svc   │ │Svc    │ │Svc    │ │Svc     │ │tion Svc  │
└──┬───┘ └───┬───┘ └───┬───┘ └───┬────┘ └──────────┘
   │         │         │         │
   │         │         │         ▼
   │         │         │    ┌────────────┐
   │         │         │    │ CDN        │
   │         │         │    │ (Images)   │
   │         │         │    └────────────┘
   │         │         │
   ▼         ▼         ▼
┌──────────────────────────────────────────────────────────────┐
│                         Data Layer                            │
│                                                              │
│  ┌────────────┐  ┌────────────┐  ┌────────────────────────┐  │
│  │ Post DB    │  │ Social     │  │ Feed Cache             │  │
│  │ (MySQL     │  │ Graph DB   │  │ (Redis)                │  │
│  │  Vitess)   │  │ (MySQL/    │  │                        │  │
│  │            │  │  Redis)    │  │ user:123:feed → [...]  │  │
│  └────────────┘  └────────────┘  └────────────────────────┘  │
│                                                              │
│  ┌────────────────────────────┐  ┌────────────────────────┐  │
│  │ Feed Generation Workers   │  │ Ranking Service        │  │
│  │ (Fan-out on Write)        │  │ (ML Model)             │  │
│  └────────────────────────────┘  └────────────────────────┘  │
└──────────────────────────────────────────────────────────────┘

═══════════════════════════════════════════════════
                Feed Generation Strategy
═══════════════════════════════════════════════════

    HYBRID APPROACH:
    
    Regular users (< 10K followers):
    ┌──────────────────────────────────────────┐
    │  FAN-OUT ON WRITE (Push Model)           │
    │                                          │
    │  User posts → push to all followers'     │
    │  feed caches immediately                 │
    │                                          │
    │  ✓ Fast feed reads (pre-computed)        │
    │  ✗ Slow writes for popular users         │
    └──────────────────────────────────────────┘
    
    Celebrities (> 10K followers):
    ┌──────────────────────────────────────────┐
    │  FAN-OUT ON READ (Pull Model)            │
    │                                          │
    │  When feed is requested → fetch posts    │
    │  from followed celebrities on-the-fly    │
    │                                          │
    │  ✓ No write amplification               │
    │  ✗ Slower reads (need to merge)          │
    └──────────────────────────────────────────┘
```

## 11.4 Data Models

```python
"""
─── MySQL (Vitess sharded): Posts ───
CREATE TABLE posts (
    post_id         BIGINT PRIMARY KEY,         -- Snowflake ID
    user_id         BIGINT NOT NULL,
    caption         TEXT,
    location        VARCHAR(200),
    created_at      DATETIME NOT NULL,
    like_count      INT DEFAULT 0,
    comment_count   INT DEFAULT 0,
    is_deleted      BOOLEAN DEFAULT FALSE,
    INDEX idx_user_created (user_id, created_at DESC)
);

CREATE TABLE post_media (
    media_id        BIGINT PRIMARY KEY,
    post_id         BIGINT,
    media_type      ENUM('photo', 'video', 'carousel'),
    media_url       VARCHAR(500),       -- CDN URL
    width           INT,
    height          INT,
    display_order   TINYINT,
    INDEX idx_post (post_id)
);

─── Social Graph ───
CREATE TABLE follows (
    follower_id     BIGINT,
    followee_id     BIGINT,
    created_at      DATETIME,
    PRIMARY KEY (follower_id, followee_id),
    INDEX idx_followee (followee_id, follower_id)
);
-- Shard by follower_id for "who do I follow" queries
-- Secondary index on followee_id for "who follows me"

─── Redis: Pre-computed Feed ───
# Key: feed:{user_id}
# Type: Sorted Set (score = timestamp)
# Value: post_id
# Max size: 1000 posts
# TTL: 7 days

─── Likes ───
CREATE TABLE likes (
    user_id         BIGINT,
    post_id         BIGINT,
    created_at      DATETIME,
    PRIMARY KEY (user_id, post_id)
);
"""
```

## 11.5 Core Implementation

### Post Creation & Fan-Out

```python
import asyncio
import time
from dataclasses import dataclass
from typing import Optional
import redis.asyncio as aioredis
from confluent_kafka import Producer
import json

# ─── Snowflake ID Generator ───
class SnowflakeIDGenerator:
    """
    Twitter Snowflake-like ID generator.
    64 bits: [1 bit unused][41 bits timestamp][10 bits machine][12 bits sequence]
    """
    
    EPOCH = 1640995200000  # 2022-01-01 00:00:00 UTC in ms
    
    def __init__(self, machine_id: int):
        self.machine_id = machine_id & 0x3FF  # 10 bits
        self.sequence = 0
        self.last_timestamp = -1
    
    def generate(self) -> int:
        timestamp = int(time.time() * 1000) - self.EPOCH
        
        if timestamp == self.last_timestamp:
            self.sequence = (self.sequence + 1) & 0xFFF  # 12 bits
            if self.sequence == 0:
                # Wait for next millisecond
                while timestamp <= self.last_timestamp:
                    timestamp = int(time.time() * 1000) - self.EPOCH
        else:
            self.sequence = 0
        
        self.last_timestamp = timestamp
        
        return (
            (timestamp << 22) |
            (self.machine_id << 12) |
            self.sequence
        )

id_gen = SnowflakeIDGenerator(machine_id=1)
redis_client = aioredis.from_url("redis://redis-cluster:6379")
kafka_producer = Producer({'bootstrap.servers': 'kafka:9092'})

CELEBRITY_THRESHOLD = 10_000  # followers


# ─── Post Creation ───
async def create_post(user_id: int, caption: str, 
                      media_urls: list[str]) -> dict:
    """
    Create a new post and trigger fan-out.
    """
    post_id = id_gen.generate()
    created_at = time.time()
    
    # 1. Store post in DB
    await execute_sql(
        "INSERT INTO posts (post_id, user_id, caption, created_at) VALUES (%s,%s,%s,%s)",
        (post_id, user_id, caption, created_at)
    )
    
    # 2. Store media
    for i, url in enumerate(media_urls):
        media_id = id_gen.generate()
        await execute_sql(
            "INSERT INTO post_media (media_id, post_id, media_url, display_order) "
            "VALUES (%s,%s,%s,%s)",
            (media_id, post_id, url, i)
        )
    
    # 3. Trigger fan-out
    follower_count = await get_follower_count(user_id)
    
    if follower_count < CELEBRITY_THRESHOLD:
        # Fan-out on write: push to all followers' feeds
        kafka_producer.produce(
            'feed-fanout',
            key=str(user_id).encode(),
            value=json.dumps({
                "type": "fanout_write",
                "post_id": post_id,
                "user_id": user_id,
                "created_at": created_at
            }).encode()
        )
    else:
        # Celebrity: store in celebrity posts cache only
        await redis_client.zadd(
            f"celebrity:posts:{user_id}",
            {str(post_id): created_at}
        )
        # Trim to last 100 posts
        await redis_client.zremrangebyrank(
            f"celebrity:posts:{user_id}", 0, -101
        )
    
    kafka_producer.flush()
    
    return {"post_id": post_id, "status": "created"}


# ─── Fan-Out Worker (Kafka Consumer) ───
class FanOutWorker:
    """
    Consumes from 'feed-fanout' topic.
    Pushes post_id to each follower's feed cache in Redis.
    
    For a user with 500 followers → 500 Redis ZADD operations.
    """
    
    FEED_MAX_SIZE = 1000  # Keep last 1000 posts in feed cache
    BATCH_SIZE = 500      # Process followers in batches
    
    async def process_fanout(self, event: dict):
        post_id = event["post_id"]
        user_id = event["user_id"]
        created_at = event["created_at"]
        
        # Get all followers (paginated)
        cursor = 0
        while True:
            followers = await get_followers_batch(
                user_id, cursor, self.BATCH_SIZE
            )
            if not followers:
                break
            
            # Batch Redis operations using pipeline
            pipe = redis_client.pipeline()
            for follower_id in followers:
                pipe.zadd(
                    f"feed:{follower_id}",
                    {str(post_id): created_at}
                )
                # Trim feed to max size
                pipe.zremrangebyrank(
                    f"feed:{follower_id}", 0, -(self.FEED_MAX_SIZE + 1)
                )
            
            await pipe.execute()
            cursor += self.BATCH_SIZE
        
        print(f"Fan-out complete for post {post_id} by user {user_id}")
```

### Feed Generation (Hybrid Pull + Push)

```python
"""
Feed Generation: Hybrid Approach
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
1. Fetch pre-computed feed from Redis (pushed by non-celebrities)
2. Fetch latest posts from followed celebrities (pulled on-read)
3. Merge and rank
4. Return paginated results
"""

@dataclass
class FeedItem:
    post_id: int
    user_id: int
    caption: str
    media_urls: list[str]
    created_at: float
    like_count: int
    comment_count: int
    user_name: str
    user_avatar: str
    ranking_score: float = 0.0


class FeedService:
    def __init__(self):
        self.redis = redis_client
        self.ranking_model = FeedRankingModel()
    
    async def get_feed(self, user_id: int, page: int = 0, 
                       page_size: int = 20) -> list[FeedItem]:
        """
        Generate user's feed with hybrid fan-out approach.
        
        Steps:
        1. Get pre-computed feed post IDs from Redis
        2. Get celebrity posts (fan-out on read)
        3. Merge all post IDs
        4. Fetch full post data
        5. Rank posts
        6. Return paginated
        """
        
        # ─── Step 1: Pre-computed feed (fan-out on write results) ───
        cached_post_ids = await self.redis.zrevrange(
            f"feed:{user_id}",
            0, 500,                          # Top 500 recent
            withscores=True
        )
        
        post_scores = {
            int(pid): score 
            for pid, score in cached_post_ids
        }
        
        # ─── Step 2: Celebrity posts (fan-out on read) ───
        followed_celebrities = await self._get_followed_celebrities(user_id)
        
        if followed_celebrities:
            # Fetch recent posts from each celebrity
            pipe = self.redis.pipeline()
            for celeb_id in followed_celebrities:
                pipe.zrevrange(
                    f"celebrity:posts:{celeb_id}",
                    0, 20,
                    withscores=True
                )
            
            celeb_results = await pipe.execute()
            
            for posts_with_scores in celeb_results:
                for pid, score in posts_with_scores:
                    post_scores[int(pid)] = score
        
        # ─── Step 3: Get full post data ───
        all_post_ids = sorted(post_scores.keys(), 
                              key=lambda x: post_scores[x], 
                              reverse=True)[:200]
        
        posts = await self._batch_get_posts(all_post_ids)
        
        # ─── Step 4: Rank posts ───
        feed_items = await self._enrich_posts(posts, user_id)
        ranked_feed = self.ranking_model.rank(user_id, feed_items)
        
        # ─── Step 5: Paginate ───
        start = page * page_size
        end = start + page_size
        
        return ranked_feed[start:end]
    
    async def _get_followed_celebrities(self, user_id: int) -> list[int]:
        """Get list of celebrities that this user follows."""
        # Cached in Redis
        cached = await self.redis.smembers(f"user:{user_id}:celeb_follows")
        if cached:
            return [int(uid) for uid in cached]
        
        # Fallback to DB
        result = await execute_sql("""
            SELECT f.followee_id FROM follows f
            JOIN users u ON f.followee_id = u.user_id
            WHERE f.follower_id = %s AND u.follower_count >= %s
        """, (user_id, CELEBRITY_THRESHOLD))
        
        celeb_ids = [row['followee_id'] for row in result]
        
        # Cache for 1 hour
        if celeb_ids:
            await self.redis.sadd(f"user:{user_id}:celeb_follows", *celeb_ids)
            await self.redis.expire(f"user:{user_id}:celeb_follows", 3600)
        
        return celeb_ids
    
    async def _batch_get_posts(self, post_ids: list[int]) -> list[dict]:
        """
        Fetch post data. Check cache first, then DB for misses.
        """
        # Try cache first
        pipe = self.redis.pipeline()
        for pid in post_ids:
            pipe.get(f"post:{pid}")
        
        cached = await pipe.execute()
        
        result = {}
        cache_misses = []
        
        for pid, data in zip(post_ids, cached):
            if data:
                result[pid] = json.loads(data)
            else:
                cache_misses.append(pid)
        
        # Fetch misses from DB
        if cache_misses:
            db_posts = await execute_sql(
                "SELECT * FROM posts WHERE post_id IN %s",
                (tuple(cache_misses),)
            )
            
            pipe = self.redis.pipeline()
            for post in db_posts:
                result[post['post_id']] = post
                # Cache for 1 hour
                pipe.setex(
                    f"post:{post['post_id']}", 
                    3600, 
                    json.dumps(post, default=str)
                )
            await pipe.execute()
        
        return [result[pid] for pid in post_ids if pid in result]
    
    async def _enrich_posts(self, posts: list[dict], 
                            user_id: int) -> list[FeedItem]:
        """Add user info, check if current user liked each post."""
        items = []
        for post in posts:
            user_info = await get_user_info(post['user_id'])
            items.append(FeedItem(
                post_id=post['post_id'],
                user_id=post['user_id'],
                caption=post.get('caption', ''),
                media_urls=await get_post_media(post['post_id']),
                created_at=post['created_at'],
                like_count=post.get('like_count', 0),
                comment_count=post.get('comment_count', 0),
                user_name=user_info['username'],
                user_avatar=user_info['profile_pic_url'],
            ))
        return items


# ─── Feed Ranking Model ───
class FeedRankingModel:
    """
    ML-based ranking considering:
    - Recency (time decay)
    - User affinity (how often you interact with poster)
    - Engagement (likes/comments ratio)
    - Content type preference
    - Post quality signals
    """
    
    def rank(self, user_id: int, items: list[FeedItem]) -> list[FeedItem]:
        """Score and sort feed items."""
        for item in items:
            item.ranking_score = self._compute_score(user_id, item)
        
        return sorted(items, key=lambda x: x.ranking_score, reverse=True)
    
    def _compute_score(self, user_id: int, item: FeedItem) -> float:
        """
        Score = w1 * affinity + w2 * recency + w3 * engagement + w4 * quality
        """
        # Time decay: exponential decay over hours
        age_hours = (time.time() - item.created_at) / 3600
        recency_score = 1.0 / (1.0 + age_hours * 0.1)
        
        # Engagement score
        total_interactions = item.like_count + item.comment_count * 2
        engagement_score = min(total_interactions / 100.0, 1.0)
        
        # User affinity (precomputed: how often user_id interacts with poster)
        affinity = self._get_affinity(user_id, item.user_id)
        
        # Weighted combination
        score = (
            0.35 * affinity +
            0.30 * recency_score +
            0.25 * engagement_score +
            0.10 * 0.5  # content quality placeholder
        )
        
        return score
    
    def _get_affinity(self, user_id: int, poster_id: int) -> float:
        """
        User affinity: precomputed score based on interaction history.
        Cached in Redis, updated by batch job.
        """
        # In production: precomputed via Spark job
        # Based on: likes, comments, profile visits, story views, DMs
        cached = redis_client.get(f"affinity:{user_id}:{poster_id}")
        return float(cached) if cached else 0.3  # default
```

### Stories (Ephemeral Content)

```python
"""
Instagram Stories: 24-hour ephemeral content.
Design considerations:
  - TTL-based expiry
  - Separate from main feed
  - Ordered by recency & affinity
"""

class StoriesService:
    """
    Stories Architecture:
    - Stored in Redis with 24-hour TTL
    - Each user's stories: Redis Sorted Set
    - Story tray (top bar): precomputed list of users with active stories
    """
    
    STORY_TTL = 86400  # 24 hours in seconds
    
    async def create_story(self, user_id: int, media_url: str, 
                           story_type: str = "photo") -> dict:
        story_id = id_gen.generate()
        created_at = time.time()
        
        story_data = {
            "story_id": story_id,
            "user_id": user_id,
            "media_url": media_url,
            "type": story_type,
            "created_at": created_at,
            "expires_at": created_at + self.STORY_TTL
        }
        
        # Store story with TTL
        await self.redis.setex(
            f"story:{story_id}",
            self.STORY_TTL,
            json.dumps(story_data)
        )
        
        # Add to user's story list
        await self.redis.zadd(
            f"user:{user_id}:stories",
            {str(story_id): created_at}
        )
        await self.redis.expire(f"user:{user_id}:stories", self.STORY_TTL)
        
        # Update story tray for followers
        followers = await get_all_followers(user_id)
        pipe = self.redis.pipeline()
        for fid in followers:
            pipe.zadd(f"storytray:{fid}", {str(user_id): created_at})
            pipe.expire(f"storytray:{fid}", self.STORY_TTL)
        await pipe.execute()
        
        return story_data
    
    async def get_story_tray(self, user_id: int) -> list[dict]:
        """
        Get the story tray (horizontal scroll bar at top).
        Returns users who have active stories, ordered by affinity.
        """
        # Get users with active stories
        active_users = await self.redis.zrevrange(
            f"storytray:{user_id}", 0, 100, withscores=True
        )
        
        tray = []
        for uid_bytes, timestamp in active_users:
            poster_id = int(uid_bytes)
            user_info = await get_user_info(poster_id)
            story_count = await self.redis.zcard(f"user:{poster_id}:stories")
            
            # Check if current user has viewed all stories
            viewed_count = await self.redis.scard(
                f"viewed:{user_id}:{poster_id}"
            )
            
            tray.append({
                "user_id": poster_id,
                "username": user_info["username"],
                "avatar": user_info["profile_pic_url"],
                "story_count": story_count,
                "has_unseen": viewed_count < story_count,
                "latest_timestamp": timestamp
            })
        
        return tray
    
    async def get_user_stories(self, viewer_id: int, 
                                poster_id: int) -> list[dict]:
        """Get all active stories for a user."""
        story_ids = await self.redis.zrange(
            f"user:{poster_id}:stories", 0, -1
        )
        
        stories = []
        pipe = self.redis.pipeline()
        for sid in story_ids:
            pipe.get(f"story:{sid.decode()}")
        
        results = await pipe.execute()
        for data in results:
            if data:
                story = json.loads(data)
                story["is_viewed"] = await self.redis.sismember(
                    f"viewed:{viewer_id}:{poster_id}",
                    str(story["story_id"])
                )
                stories.append(story)
        
        return stories
    
    async def mark_viewed(self, viewer_id: int, poster_id: int,
                          story_id: int):
        """Mark a story as viewed."""
        await self.redis.sadd(
            f"viewed:{viewer_id}:{poster_id}",
            str(story_id)
        )
        await self.redis.expire(
            f"viewed:{viewer_id}:{poster_id}", 
            self.STORY_TTL
        )
```

---

---

# 12. Design Twitter Timeline

## 12.1 Requirements

```
Functional:
  • Post tweets (280 chars, media)
  • Home timeline (tweets from followed users)
  • User timeline (all tweets by a specific user)
  • Retweet, quote tweet
  • Like, reply
  • Search tweets
  • Trending topics
  • Follow/unfollow

Non-Functional:
  • Timeline generation < 300ms
  • 400M DAU, 500M tweets/day
  • Timeline should feel real-time
  • High read:write ratio (~1000:1)
  • Availability > consistency
```

## 12.2 High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         CLIENTS                                 │
│              Web  │  iOS  │  Android  │  API                    │
└─────────────────────────────┬───────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                       API GATEWAY                               │
│          (Authentication, Rate Limiting, Routing)                │
└──┬──────────┬───────────┬───────────┬───────────┬───────────────┘
   │          │           │           │           │
   ▼          ▼           ▼           ▼           ▼
┌──────┐  ┌───────┐  ┌────────┐  ┌────────┐  ┌────────────┐
│Tweet │  │Home   │  │Search  │  │User    │  │Trending    │
│Write │  │Time-  │  │Service │  │Service │  │Service     │
│Svc   │  │line   │  │        │  │        │  │            │
│      │  │Svc    │  │(Elastic│  │(Follow │  │(Count-Min  │
│      │  │       │  │Search) │  │Graph)  │  │ Sketch)    │
└──┬───┘  └───┬───┘  └────────┘  └────────┘  └────────────┘
   │          │
   │          │      HOME TIMELINE FLOW
   │          │      ═══════════════════
   │          │
   │          │  ┌──── Is user's feed cached? ────┐
   │          │  │                                 │
   │          │  │  YES                      NO    │
   │          │  ▼                            ▼    │
   │          │ ┌───────────┐    ┌─────────────┐   │
   │          │ │Redis Feed │    │Fan-out on   │   │
   │          │ │Cache      │    │Read (merge  │   │
   │          │ │           │    │followed     │   │
   │          │ │Pre-built  │    │users' posts)│   │
   │          │ └───────────┘    └─────────────┘   │
   │          │                                    │
   │          └────────────────────────────────────┘
   │
   │  TWEET WRITE FLOW
   │  ═════════════════
   │
   ▼
┌──────────────────────────────────────────────────────────────┐
│                    MESSAGE QUEUE (Kafka)                      │
│                                                              │
│  Topic: tweet-created                                        │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │ { tweet_id, user_id, content, timestamp, ... }         │ │
│  └─────────────────────────────────────────────────────────┘ │
└──────────┬────────────────────────┬──────────────────────────┘
           │                        │
           ▼                        ▼
┌────────────────────┐   ┌────────────────────┐
│  Fan-Out Service   │   │  Search Indexer    │
│                    │   │                    │
│  For each follower │   │  Index tweet in    │
│  of the author:    │   │  Elasticsearch     │
│                    │   │                    │
│  IF author has     │   └────────────────────┘
│  < 10K followers:  │
│    Push tweet_id   │   ┌────────────────────┐
│    to follower's   │   │  Trending Service  │
│    Redis feed      │   │                    │
│                    │   │  Extract hashtags  │
│  ELSE (celebrity): │   │  Update counters   │
│    Skip fan-out    │   │  (Count-Min Sketch)│
│    (pull on read)  │   └────────────────────┘
└────────────────────┘

═══════════════════════════════════════════════════════════════
                    DATA STORES
═══════════════════════════════════════════════════════════════

┌─────────────────┐  ┌──────────────┐  ┌────────────────────┐
│ Tweet Store     │  │ Timeline     │  │ Social Graph       │
│ (MySQL Vitess)  │  │ Cache        │  │ (Redis + MySQL)    │
│                 │  │ (Redis)      │  │                    │
│ • Tweet data    │  │              │  │ • follow(A,B)      │
│ • Sharded by    │  │ feed:uid →   │  │ • followers(A)     │
│   tweet_id      │  │ [tweet_ids]  │  │ • following(A)     │
│                 │  │              │  │                    │
│ • Secondary     │  │ SortedSet    │  │ Sharded by         │
│   index on      │  │ by timestamp │  │ user_id            │
│   user_id       │  │              │  │                    │
└─────────────────┘  └──────────────┘  └────────────────────┘

┌─────────────────┐  ┌──────────────┐
│ Media Store     │  │ Analytics    │
│ (S3 + CDN)      │  │ (Kafka →     │
│                 │  │  Spark →     │
│ • Images        │  │  HDFS)       │
│ • Videos        │  │              │
│ • Thumbnails    │  │ • Impressions│
│                 │  │ • Engagement │
└─────────────────┘  └──────────────┘
```

## 12.3 Core Implementation

### Tweet Creation

```python
import time
import json
import re
from dataclasses import dataclass, field
from typing import Optional
from fastapi import FastAPI, Depends, HTTPException
import redis.asyncio as aioredis
from confluent_kafka import Producer

app = FastAPI()
redis_client = aioredis.from_url("redis://redis-cluster:6379")
kafka_producer = Producer({'bootstrap.servers': 'kafka:9092'})

TWEET_MAX_LENGTH = 280
CELEBRITY_THRESHOLD = 10_000

@dataclass
class Tweet:
    tweet_id: int
    user_id: int
    content: str
    created_at: float
    reply_to: Optional[int] = None
    retweet_of: Optional[int] = None
    quote_of: Optional[int] = None
    media_urls: list[str] = field(default_factory=list)
    hashtags: list[str] = field(default_factory=list)
    mentions: list[str] = field(default_factory=list)
    like_count: int = 0
    retweet_count: int = 0
    reply_count: int = 0


class TweetService:
    
    def __init__(self):
        self.id_gen = SnowflakeIDGenerator(machine_id=1)
    
    async def create_tweet(self, user_id: int, content: str,
                           media_urls: list[str] = None,
                           reply_to: int = None,
                           quote_of: int = None) -> Tweet:
        """
        Create a tweet and trigger downstream processing.
        """
        # ─── Validation ───
        if len(content) > TWEET_MAX_LENGTH:
            raise HTTPException(400, "Tweet exceeds 280 characters")
        
        # ─── Parse entities ───
        hashtags = re.findall(r'#(\w+)', content)
        mentions = re.findall(r'@(\w+)', content)
        
        tweet_id = self.id_gen.generate()
        created_at = time.time()
        
        tweet = Tweet(
            tweet_id=tweet_id,
            user_id=user_id,
            content=content,
            created_at=created_at,
            reply_to=reply_to,
            quote_of=quote_of,
            media_urls=media_urls or [],
            hashtags=hashtags,
            mentions=mentions
        )
        
        # ─── 1. Persist to DB ───
        await self._store_tweet(tweet)
        
        # ─── 2. Cache tweet data ───
        await redis_client.setex(
            f"tweet:{tweet_id}",
            86400,  # 24 hour cache
            json.dumps(tweet.__dict__, default=str)
        )
        
        # ─── 3. Add to user's own timeline ───
        await redis_client.zadd(
            f"user_timeline:{user_id}",
            {str(tweet_id): created_at}
        )
        await redis_client.zremrangebyrank(
            f"user_timeline:{user_id}", 0, -3201  # Keep last 3200
        )
        
        # ─── 4. Publish event for async processing ───
        event = {
            "event_type": "tweet_created",
            "tweet_id": tweet_id,
            "user_id": user_id,
            "content": content,
            "hashtags": hashtags,
            "mentions": mentions,
            "created_at": created_at,
            "follower_count": await self._get_follower_count(user_id)
        }
        
        kafka_producer.produce(
            'tweet-events',
            key=str(user_id).encode(),
            value=json.dumps(event).encode(),
            partition=user_id % 16  # partition by user
        )
        kafka_producer.flush()
        
        return tweet
    
    async def _store_tweet(self, tweet: Tweet):
        await execute_sql("""
            INSERT INTO tweets 
            (tweet_id, user_id, content, reply_to_id, quote_of_id, 
             created_at, hashtags, mentions)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
        """, (
            tweet.tweet_id, tweet.user_id, tweet.content,
            tweet.reply_to, tweet.quote_of, tweet.created_at,
            json.dumps(tweet.hashtags), json.dumps(tweet.mentions)
        ))
    
    async def _get_follower_count(self, user_id: int) -> int:
        cached = await redis_client.get(f"follower_count:{user_id}")
        if cached:
            return int(cached)
        count = await execute_sql(
            "SELECT COUNT(*) as cnt FROM follows WHERE followee_id = %s",
            (user_id,)
        )
        await redis_client.setex(f"follower_count:{user_id}", 300, str(count))
        return count
```

### Fan-Out Service (The Heart of Twitter)

```python
"""
Fan-Out Service: The Celebrity Problem
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

The key challenge: A celebrity tweets, and has 50M followers.
If we push to all followers → 50M Redis writes for ONE tweet!

Solution: Hybrid approach
─────────────────────────
Regular users (< 10K followers): Fan-out on WRITE
  → Push tweet to all followers' caches on tweet creation
  → Pros: Fast reads (cache hit)
  → Cons: Write amplification

Celebrities (≥ 10K followers): Fan-out on READ
  → Don't push. When follower requests feed, pull celebrity tweets live
  → Pros: No write amplification
  → Cons: Slightly slower reads (merge step)
"""

from confluent_kafka import Consumer
import asyncio

class FanOutService:
    """
    Kafka consumer that handles fan-out for new tweets.
    """
    
    FEED_CACHE_SIZE = 800       # tweets per user's home feed cache
    BATCH_SIZE = 1000           # followers per batch
    
    async def start(self):
        consumer = Consumer({
            'bootstrap.servers': 'kafka:9092',
            'group.id': 'fanout-workers',
            'auto.offset.reset': 'earliest',
            'max.poll.interval.ms': 300000
        })
        consumer.subscribe(['tweet-events'])
        
        while True:
            msg = consumer.poll(1.0)
            if msg is None:
                continue
            
            event = json.loads(msg.value())
            
            if event['event_type'] == 'tweet_created':
                await self._handle_tweet_fanout(event)
    
    async def _handle_tweet_fanout(self, event: dict):
        tweet_id = event['tweet_id']
        user_id = event['user_id']
        created_at = event['created_at']
        follower_count = event['follower_count']
        
        # ─── Decision: Fan-out on write or skip? ───
        if follower_count >= CELEBRITY_THRESHOLD:
            # Celebrity: mark as celebrity tweet, skip fan-out
            await redis_client.zadd(
                f"celebrity_tweets:{user_id}",
                {str(tweet_id): created_at}
            )
            await redis_client.zremrangebyrank(
                f"celebrity_tweets:{user_id}", 0, -201
            )
            print(f"Celebrity tweet {tweet_id}: skipped fan-out "
                  f"({follower_count} followers)")
            return
        
        # ─── Regular user: push to all followers ───
        total_pushed = 0
        cursor = 0
        
        while True:
            # Get batch of follower IDs
            followers = await self._get_followers_batch(
                user_id, cursor, self.BATCH_SIZE
            )
            
            if not followers:
                break
            
            # Pipeline Redis operations for efficiency
            pipe = redis_client.pipeline()
            for follower_id in followers:
                # Add tweet to follower's home timeline cache
                pipe.zadd(
                    f"home_timeline:{follower_id}",
                    {str(tweet_id): created_at}
                )
                # Trim to keep cache bounded
                pipe.zremrangebyrank(
                    f"home_timeline:{follower_id}",
                    0, -(self.FEED_CACHE_SIZE + 1)
                )
            
            await pipe.execute()
            
            total_pushed += len(followers)
            cursor += self.BATCH_SIZE
        
        print(f"Tweet {tweet_id}: fan-out to {total_pushed} followers")
    
    async def _get_followers_batch(self, user_id: int, 
                                    offset: int, limit: int) -> list[int]:
        """Get paginated follower list."""
        # Use Redis sorted set for follower list
        follower_ids = await redis_client.zrange(
            f"followers:{user_id}", offset, offset + limit - 1
        )
        return [int(fid) for fid in follower_ids]


# ─── Handle follow/unfollow ───
class SocialGraphService:
    
    async def follow(self, follower_id: int, followee_id: int):
        """
        User A follows User B.
        Need to backfill A's timeline with B's recent tweets.
        """
        # 1. Store in DB
        await execute_sql(
            "INSERT IGNORE INTO follows (follower_id, followee_id, created_at) "
            "VALUES (%s, %s, NOW())",
            (follower_id, followee_id)
        )
        
        # 2. Update Redis graph
        await redis_client.zadd(
            f"following:{follower_id}",
            {str(followee_id): time.time()}
        )
        await redis_client.zadd(
            f"followers:{followee_id}",
            {str(follower_id): time.time()}
        )
        
        # 3. Update follower count
        await redis_client.incr(f"follower_count:{followee_id}")
        
        # 4. Backfill: Add B's recent tweets to A's timeline
        follower_count = await redis_client.get(f"follower_count:{followee_id}")
        
        if int(follower_count or 0) < CELEBRITY_THRESHOLD:
            # Get B's recent tweets
            recent_tweets = await redis_client.zrevrange(
                f"user_timeline:{followee_id}", 0, 50, withscores=True
            )
            
            if recent_tweets:
                pipe = redis_client.pipeline()
                for tweet_id, score in recent_tweets:
                    pipe.zadd(
                        f"home_timeline:{follower_id}",
                        {tweet_id: score}
                    )
                await pipe.execute()
        else:
            # Celebrity: add to follower's celebrity list
            await redis_client.sadd(
                f"user:{follower_id}:celeb_follows",
                str(followee_id)
            )
    
    async def unfollow(self, follower_id: int, followee_id: int):
        """
        User A unfollows User B.
        Remove B's tweets from A's timeline (lazy removal).
        """
        await execute_sql(
            "DELETE FROM follows WHERE follower_id=%s AND followee_id=%s",
            (follower_id, followee_id)
        )
        
        await redis_client.zrem(f"following:{follower_id}", str(followee_id))
        await redis_client.zrem(f"followers:{followee_id}", str(follower_id))
        await redis_client.decr(f"follower_count:{followee_id}")
        
        # Lazy removal: tweets will naturally fall off the timeline
        # Or: async job to remove followee's tweets from cache
```

### Home Timeline Service

```python
"""
Home Timeline: Merge pre-computed feed with celebrity posts.

Timeline Read Path:
  1. Get pre-computed feed from Redis (pushed by fan-out workers)
  2. Get list of celebrities the user follows
  3. Fetch recent tweets from each celebrity
  4. Merge, deduplicate, sort by time
  5. Apply ranking (optional)
  6. Return paginated results
"""

class HomeTimelineService:
    
    CACHE_SIZE = 800
    
    async def get_timeline(self, user_id: int, 
                           cursor: Optional[str] = None,
                           count: int = 20) -> dict:
        """
        Get home timeline with cursor-based pagination.
        
        Cursor is the tweet_id of the last seen tweet.
        """
        
        # ─── Step 1: Pre-computed feed (fan-out on write) ───
        if cursor:
            # Get tweets older than cursor
            cursor_score = float(cursor)  # timestamp
            cached_tweets = await redis_client.zrevrangebyscore(
                f"home_timeline:{user_id}",
                f"({cursor_score}",     # exclusive
                "-inf",
                start=0,
                num=count + 50,         # fetch extra for merge
                withscores=True
            )
        else:
            cached_tweets = await redis_client.zrevrange(
                f"home_timeline:{user_id}",
                0, count + 50,
                withscores=True
            )
        
        # Convert to list of (tweet_id, timestamp)
        timeline = [(int(tid), score) for tid, score in cached_tweets]
        
        # ─── Step 2: Celebrity tweets (fan-out on read) ───
        celeb_ids = await redis_client.smembers(
            f"user:{user_id}:celeb_follows"
        )
        
        if celeb_ids:
            pipe = redis_client.pipeline()
            for cid in celeb_ids:
                if cursor:
                    pipe.zrevrangebyscore(
                        f"celebrity_tweets:{int(cid)}",
                        f"({cursor_score}", "-inf",
                        start=0, num=10,
                        withscores=True
                    )
                else:
                    pipe.zrevrange(
                        f"celebrity_tweets:{int(cid)}",
                        0, 10,
                        withscores=True
                    )
            
            results = await pipe.execute()
            for celeb_tweets in results:
                for tid, score in celeb_tweets:
                    timeline.append((int(tid), score))
        
        # ─── Step 3: Merge, deduplicate, sort ───
        seen = set()
        unique_timeline = []
        for tweet_id, score in timeline:
            if tweet_id not in seen:
                seen.add(tweet_id)
                unique_timeline.append((tweet_id, score))
        
        # Sort by timestamp descending
        unique_timeline.sort(key=lambda x: x[1], reverse=True)
        
        # Take requested count
        page = unique_timeline[:count]
        
        # ─── Step 4: Hydrate tweets with full data ───
        tweet_ids = [tid for tid, _ in page]
        tweets = await self._hydrate_tweets(tweet_ids, user_id)
        
        # ─── Step 5: Build response with cursor ───
        next_cursor = None
        if page:
            next_cursor = str(page[-1][1])  # timestamp of last tweet
        
        return {
            "tweets": tweets,
            "next_cursor": next_cursor,
            "has_more": len(unique_timeline) > count
        }
    
    async def _hydrate_tweets(self, tweet_ids: list[int], 
                               viewer_id: int) -> list[dict]:
        """
        Fetch full tweet data from cache/DB.
        Enrich with author info, like status, etc.
        """
        # Batch fetch from Redis cache
        pipe = redis_client.pipeline()
        for tid in tweet_ids:
            pipe.get(f"tweet:{tid}")
        
        cached = await pipe.execute()
        
        tweets = []
        cache_misses = []
        
        for tid, data in zip(tweet_ids, cached):
            if data:
                tweets.append(json.loads(data))
            else:
                cache_misses.append(tid)
        
        # Fetch cache misses from DB
        if cache_misses:
            db_tweets = await execute_sql(
                "SELECT * FROM tweets WHERE tweet_id IN %s",
                (tuple(cache_misses),)
            )
            
            pipe = redis_client.pipeline()
            for t in db_tweets:
                tweet_dict = dict(t)
                tweets.append(tweet_dict)
                pipe.setex(f"tweet:{t['tweet_id']}", 86400, 
                          json.dumps(tweet_dict, default=str))
            await pipe.execute()
        
        # Sort to maintain order
        tweet_map = {t['tweet_id']: t for t in tweets}
        ordered = [tweet_map[tid] for tid in tweet_ids if tid in tweet_map]
        
        # Enrich with author info and viewer context
        enriched = []
        for tweet in ordered:
            author = await get_user_info(tweet['user_id'])
            
            # Check if viewer liked this tweet
            liked = await redis_client.sismember(
                f"tweet_likes:{tweet['tweet_id']}",
                str(viewer_id)
            )
            
            enriched.append({
                **tweet,
                "author": {
                    "user_id": author["user_id"],
                    "username": author["username"],
                    "display_name": author["display_name"],
                    "avatar_url": author["profile_pic_url"],
                    "is_verified": author.get("is_verified", False)
                },
                "viewer_liked": bool(liked),
                "viewer_retweeted": False  # similar check
            })
        
        return enriched


# ─── API Endpoints ───
timeline_service = HomeTimelineService()
tweet_service = TweetService()

@app.post("/api/v1/tweets")
async def post_tweet(content: str, user_id: int = Depends(get_current_user)):
    tweet = await tweet_service.create_tweet(user_id, content)
    return {"tweet": tweet.__dict__}

@app.get("/api/v1/timeline/home")
async def home_timeline(cursor: Optional[str] = None, count: int = 20,
                        user_id: int = Depends(get_current_user)):
    result = await timeline_service.get_timeline(user_id, cursor, count)
    return result

@app.get("/api/v1/timeline/user/{target_user_id}")
async def user_timeline(target_user_id: int, cursor: Optional[str] = None, 
                        count: int = 20):
    """User's own tweets — simple range query."""
    tweets = await redis_client.zrevrange(
        f"user_timeline:{target_user_id}",
        0, count - 1,
        withscores=True
    )
    tweet_ids = [int(tid) for tid, _ in tweets]
    hydrated = await timeline_service._hydrate_tweets(tweet_ids, target_user_id)
    return {"tweets": hydrated}
```

### Trending Topics (Count-Min Sketch)

```python
"""
Trending Topics: Find trending hashtags in real-time.

Challenge: Counting millions of hashtags per minute accurately
           without storing every single one.

Solution: Count-Min Sketch (probabilistic data structure)
          + Time-windowed buckets
"""

import hashlib
import math
from collections import defaultdict

class CountMinSketch:
    """
    Probabilistic data structure for frequency estimation.
    
    Space: O(w × d) where w = width, d = depth
    Error: ε = e/w (additive)
    Probability of exceeding error: δ = e^(-d)
    
    For ε=0.001, δ=0.01: w=2718, d=5 → ~54KB total!
    """
    
    def __init__(self, width: int = 2718, depth: int = 5):
        self.width = width
        self.depth = depth
        self.table = [[0] * width for _ in range(depth)]
    
    def _hash(self, item: str, i: int) -> int:
        """Generate hash for row i."""
        h = hashlib.md5(f"{i}:{item}".encode()).hexdigest()
        return int(h, 16) % self.width
    
    def add(self, item: str, count: int = 1):
        """Increment count for an item."""
        for i in range(self.depth):
            j = self._hash(item, i)
            self.table[i][j] += count
    
    def estimate(self, item: str) -> int:
        """
        Estimate count (never underestimates, may overestimate).
        Returns minimum across all hash rows.
        """
        return min(
            self.table[i][self._hash(item, i)]
            for i in range(self.depth)
        )


class TrendingService:
    """
    Tracks trending topics using time-windowed Count-Min Sketches.
    
    Architecture:
    - 1-minute buckets (Count-Min Sketch per minute)
    - Aggregate last 60 minutes for "trending now"
    - Keep a min-heap of top-K hashtags
    """
    
    def __init__(self, window_minutes: int = 60, top_k: int = 50):
        self.window_minutes = window_minutes
        self.top_k = top_k
        self.sketches: dict[int, CountMinSketch] = {}  # minute → CMS
        self.candidates: set = set()  # Track seen hashtags
    
    def _current_minute(self) -> int:
        return int(time.time() // 60)
    
    def record_hashtags(self, hashtags: list[str]):
        """
        Called for every tweet containing hashtags.
        """
        minute = self._current_minute()
        
        if minute not in self.sketches:
            self.sketches[minute] = CountMinSketch()
            # Clean old buckets
            self._cleanup_old_buckets(minute)
        
        for tag in hashtags:
            tag_lower = tag.lower()
            self.sketches[minute].add(tag_lower)
            self.candidates.add(tag_lower)
    
    def get_trending(self, region: str = "global") -> list[dict]:
        """
        Get top trending hashtags.
        Aggregate counts across the time window.
        """
        current = self._current_minute()
        start = current - self.window_minutes
        
        # Aggregate counts for all candidates
        tag_counts = []
        for tag in self.candidates:
            total_count = 0
            for minute in range(start, current + 1):
                if minute in self.sketches:
                    total_count += self.sketches[minute].estimate(tag)
            
            if total_count > 10:  # minimum threshold
                tag_counts.append((tag, total_count))
        
        # Sort by count, take top K
        tag_counts.sort(key=lambda x: x[1], reverse=True)
        top = tag_counts[:self.top_k]
        
        return [
            {
                "rank": i + 1,
                "hashtag": f"#{tag}",
                "tweet_count": count,
                "category": self._categorize(tag)
            }
            for i, (tag, count) in enumerate(top)
        ]
    
    def _cleanup_old_buckets(self, current_minute: int):
        """Remove sketches older than the window."""
        cutoff = current_minute - self.window_minutes - 5
        old_keys = [k for k in self.sketches if k < cutoff]
        for k in old_keys:
            del self.sketches[k]
    
    def _categorize(self, tag: str) -> str:
        """Simple categorization (in production: ML classifier)."""
        return "trending"


# ─── Integration with Tweet Pipeline ───
trending_service = TrendingService()

async def process_tweet_for_trending(event: dict):
    """Called by Kafka consumer for every new tweet."""
    hashtags = event.get('hashtags', [])
    if hashtags:
        trending_service.record_hashtags(hashtags)


# ─── Demo ───
def demo_trending():
    ts = TrendingService(window_minutes=5)
    
    # Simulate tweets
    import random
    topics = ["AI", "Python", "WorldCup", "Bitcoin", "Election",
              "Taylor", "Netflix", "Climate", "SpaceX", "OpenAI"]
    
    for _ in range(10000):
        # Some topics are more popular
        weights = [20, 15, 50, 10, 40, 30, 5, 8, 12, 25]
        chosen = random.choices(topics, weights=weights, k=random.randint(1, 3))
        ts.record_hashtags(chosen)
    
    trending = ts.get_trending()
    for t in trending[:10]:
        print(f"  {t['rank']:2}. {t['hashtag']:15} ({t['tweet_count']:,} tweets)")

demo_trending()
```

### Search Service

```python
"""
Twitter Search: Real-time search across billions of tweets.
Uses Elasticsearch with custom analyzers.
"""

from elasticsearch import Elasticsearch

es = Elasticsearch(["http://es-cluster:9200"])

# ─── Create Index with Custom Settings ───
INDEX_SETTINGS = {
    "settings": {
        "number_of_shards": 10,
        "number_of_replicas": 2,
        "analysis": {
            "analyzer": {
                "tweet_analyzer": {
                    "type": "custom",
                    "tokenizer": "standard",
                    "filter": ["lowercase", "stop", "snowball"]
                }
            }
        }
    },
    "mappings": {
        "properties": {
            "content": {
                "type": "text",
                "analyzer": "tweet_analyzer"
            },
            "user_id": {"type": "long"},
            "username": {"type": "keyword"},
            "hashtags": {"type": "keyword"},
            "mentions": {"type": "keyword"},
            "created_at": {"type": "date"},
            "like_count": {"type": "integer"},
            "retweet_count": {"type": "integer"},
            "language": {"type": "keyword"},
            "location": {"type": "geo_point"}
        }
    }
}


class TweetSearchService:
    
    async def index_tweet(self, tweet: dict):
        """Index a new tweet (called asynchronously via Kafka)."""
        es.index(
            index="tweets",
            id=str(tweet["tweet_id"]),
            document={
                "content": tweet["content"],
                "user_id": tweet["user_id"],
                "username": tweet.get("username"),
                "hashtags": tweet.get("hashtags", []),
                "mentions": tweet.get("mentions", []),
                "created_at": tweet["created_at"],
                "like_count": tweet.get("like_count", 0),
                "retweet_count": tweet.get("retweet_count", 0),
            }
        )
    
    async def search(self, query: str, filters: dict = None,
                     page: int = 0, size: int = 20) -> dict:
        """
        Search tweets with optional filters.
        
        Supports:
        - Full text search on content
        - Filter by hashtag, user, date range
        - Sort by relevance, recency, or popularity
        """
        must_clauses = [
            {
                "multi_match": {
                    "query": query,
                    "fields": ["content^2", "hashtags^3", "username"],
                    "type": "best_fields",
                    "fuzziness": "AUTO"
                }
            }
        ]
        
        filter_clauses = []
        
        if filters:
            if "from_user" in filters:
                filter_clauses.append(
                    {"term": {"username": filters["from_user"]}}
                )
            if "since" in filters:
                filter_clauses.append(
                    {"range": {"created_at": {"gte": filters["since"]}}}
                )
            if "until" in filters:
                filter_clauses.append(
                    {"range": {"created_at": {"lte": filters["until"]}}}
                )
            if "min_likes" in filters:
                filter_clauses.append(
                    {"range": {"like_count": {"gte": filters["min_likes"]}}}
                )
        
        sort_by = filters.get("sort", "relevance") if filters else "relevance"
        
        sort_config = {
            "relevance": [{"_score": "desc"}, {"created_at": "desc"}],
            "recent": [{"created_at": "desc"}],
            "popular": [{"retweet_count": "desc"}, {"like_count": "desc"}]
        }.get(sort_by, [{"_score": "desc"}])
        
        body = {
            "query": {
                "bool": {
                    "must": must_clauses,
                    "filter": filter_clauses
                }
            },
            "sort": sort_config,
            "from": page * size,
            "size": size,
            "highlight": {
                "fields": {"content": {}}
            }
        }
        
        result = es.search(index="tweets", body=body)
        
        return {
            "total": result["hits"]["total"]["value"],
            "tweets": [
                {
                    "tweet_id": hit["_id"],
                    **hit["_source"],
                    "highlight": hit.get("highlight", {})
                }
                for hit in result["hits"]["hits"]
            ]
        }
```

## 12.4 Architecture Summary

```
Complete Twitter System — Key Metrics & Choices:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
│ Component          │ Technology            │ Why                    │
├────────────────────┼───────────────────────┼────────────────────────┤
│ Tweet Storage      │ MySQL Vitess          │ Sharded, consistent    │
│ Timeline Cache     │ Redis Cluster         │ Fast sorted sets       │
│ Fan-out Queue      │ Kafka                 │ Durable, partitioned   │
│ Fan-out Strategy   │ Hybrid Push/Pull      │ Celebrity problem      │
│ ID Generation      │ Snowflake             │ Time-sortable, unique  │
│ Search             │ Elasticsearch         │ Full-text, real-time   │
│ Trending           │ Count-Min Sketch      │ Space-efficient counts │
│ Social Graph       │ Redis + MySQL         │ Fast lookups + durable │
│ Media              │ S3 + CDN              │ Scalable blob storage  │
│ Pagination         │ Cursor-based          │ Consistent with writes │
│ Notifications      │ Kafka → Push          │ Async delivery         │
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Critical Design Trade-offs:
━━━━━━━━━━━━━━━━━━━━━━━━━━━
1. Fan-out on Write vs Read:
   • Write: O(followers) writes per tweet, O(1) read
   • Read: O(1) write per tweet, O(following) reads per timeline
   • Hybrid: Best of both worlds

2. Consistency vs Availability:
   • Choose AP (availability + partition tolerance)
   • Timeline can be eventually consistent
   • Tweet itself should be durable (acknowledged write)

3. Cache vs Storage:
   • Only cache recent timeline (800 tweets)
   • Older tweets: fan-out on read from DB
   • Cache invalidation: TTL + explicit on unfollow
```

---

## Comparison Summary

```
┌────────────┬─────────────┬────────────────┬────────────────┬────────────────┐
│ Aspect     │ YouTube     │ WhatsApp       │ Instagram      │ Twitter        │
│            │             │                │ Feed           │ Timeline       │
├────────────┼─────────────┼────────────────┼────────────────┼────────────────┤
│ Core       │ Video       │ Real-time      │ Photo feed     │ Tweet feed     │
│ Problem    │ streaming   │ messaging      │ generation     │ generation     │
├────────────┼─────────────┼────────────────┼────────────────┼────────────────┤
│ Protocol   │ HTTP/HLS    │ WebSocket      │ HTTP           │ HTTP (+ SSE)   │
├────────────┼─────────────┼────────────────┼────────────────┼────────────────┤
│ Read:Write │ 100:1       │ 1:1            │ 100:1          │ 1000:1         │
├────────────┼─────────────┼────────────────┼────────────────┼────────────────┤
│ Key Store  │ S3+CDN      │ Cassandra      │ MySQL+Redis    │ MySQL+Redis    │
├────────────┼─────────────┼────────────────┼────────────────┼────────────────┤
│ Feed       │ Recommend   │ N/A            │ Hybrid         │ Hybrid         │
│ Strategy   │ engine      │                │ fan-out        │ fan-out        │
├────────────┼─────────────┼────────────────┼────────────────┼────────────────┤
│ Special    │ Transcoding │ E2E Encryption │ Stories (TTL)  │ Trending       │
│ Feature    │ pipeline    │ Signal Protocol│ Ranking ML     │ Count-Min      │
├────────────┼─────────────┼────────────────┼────────────────┼────────────────┤
│ Hardest    │ Storage     │ Connection     │ Celebrity      │ Celebrity      │
│ Challenge  │ & bandwidth │ management     │ fan-out        │ fan-out        │
└────────────┴─────────────┴────────────────┴────────────────┴────────────────┘
```

Large Scale System Design (HLD) — Systems 13–16
13. Design Uber / Ride Matching
System Overview
text

┌─────────────────────────────────────────────────────────────────────────┐
│                        UBER SYSTEM ARCHITECTURE                        │
│                                                                         │
│  ┌──────────┐  ┌──────────┐                                            │
│  │  Rider   │  │  Driver  │                                            │
│  │  App     │  │  App     │                                            │
│  └────┬─────┘  └────┬─────┘                                            │
│       │              │                                                  │
│       ▼              ▼                                                  │
│  ┌─────────────────────────┐                                           │
│  │     API Gateway /       │                                           │
│  │     Load Balancer       │                                           │
│  └──────────┬──────────────┘                                           │
│             │                                                           │
│  ┌──────────┼──────────────────────────────────────────┐               │
│  │          ▼                                          │               │
│  │  ┌──────────────┐  ┌──────────────┐  ┌───────────┐ │               │
│  │  │  Location    │  │   Ride       │  │  Trip     │ │               │
│  │  │  Service     │  │   Matching   │  │  Service  │ │               │
│  │  │              │  │   Service    │  │           │ │               │
│  │  └──────┬───────┘  └──────┬───────┘  └─────┬─────┘ │               │
│  │         │                 │                │       │               │
│  │  ┌──────┴───────┐  ┌─────┴────────┐ ┌─────┴─────┐ │               │
│  │  │  Pricing     │  │ Notification │ │  Payment  │ │               │
│  │  │  Service     │  │ Service      │ │  Service  │ │               │
│  │  └──────────────┘  └──────────────┘ └───────────┘ │               │
│  └─────────────────────────────────────────────────────┘               │
│             │              │               │                            │
│  ┌──────────▼──────────────▼───────────────▼────────────┐              │
│  │                   DATA LAYER                          │              │
│  │  ┌─────────┐  ┌──────────┐  ┌────────┐  ┌─────────┐ │              │
│  │  │ Redis   │  │ PostgreSQL│  │ Kafka  │  │  S3     │ │              │
│  │  │ (Geo)   │  │          │  │        │  │         │ │              │
│  │  └─────────┘  └──────────┘  └────────┘  └─────────┘ │              │
│  └───────────────────────────────────────────────────────┘              │
└─────────────────────────────────────────────────────────────────────────┘
Requirements
text

FUNCTIONAL                              NON-FUNCTIONAL
─────────────────────                   ─────────────────────
• Rider requests a ride                 • Low latency matching (<2s)
• Match rider with nearest driver       • 99.99% availability
• Real-time GPS tracking                • Support 1M+ concurrent users
• ETA computation                       • Strong consistency (payments)
• Dynamic/surge pricing                 • Eventual consistency (location)
• Payment processing                    • Global scale
• Rating system                         • Handle 1M location updates/sec
• Trip history
Deep-Dive: Core Components
1. Location Service & Geospatial Indexing
text

                    GEOSPATIAL INDEX (QuadTree / GeoHash)
                    
    ┌───────────────────────────────────┐
    │           World Map               │
    │  ┌────────┬────────┐              │
    │  │ NW     │ NE     │              │
    │  │        │  🚗    │              │
    │  │   🚗   │     🚗 │              │
    │  ├────────┼────────┤              │
    │  │ SW     │ SE     │              │
    │  │  📍    │        │    📍 = Rider │
    │  │ Rider  │  🚗    │    🚗 = Driver│
    │  └────────┴────────┘              │
    │                                   │
    │  QuadTree subdivides until each   │
    │  cell has ≤ K drivers             │
    └───────────────────────────────────┘
    
    GeoHash: "9q8yyk" → lat/lng bucket
    
    Driver Location Update Flow:
    ┌────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐
    │ Driver │───▶│ WebSocket│───▶│ Location │───▶│  Redis   │
    │  App   │    │ Gateway  │    │ Service  │    │ GeoIndex │
    └────────┘    └──────────┘    └──────────┘    └──────────┘
       every 3-5s                    (updates        (GEOADD)
                                   QuadTree)
2. Ride Matching Algorithm
text

    MATCHING FLOW
    ═════════════
    
    Step 1: Rider requests ride at location (lat, lng)
                           │
                           ▼
    Step 2: Query nearby drivers within radius R
            ┌─────────────────────────┐
            │  GEORADIUS rider_loc    │
            │  radius=5km             │
            │  → [D1(0.5km), D2(1km),│
            │     D3(2km), D4(4.5km)]│
            └─────────────────────────┘
                           │
                           ▼
    Step 3: Filter available drivers (not on trip)
            → [D1(0.5km), D3(2km)]
                           │
                           ▼
    Step 4: Rank by score = w1*distance + w2*ETA + w3*rating
            → D1 (best match)
                           │
                           ▼
    Step 5: Send request to D1, wait 15s for response
            ┌─────────────────────────┐
            │  D1 accepts? ──YES──▶ MATCH!
            │       │                 │
            │      NO/TIMEOUT         │
            │       │                 │
            │       ▼                 │
            │  Try D3 next            │
            └─────────────────────────┘
3. Surge Pricing
text

    SUPPLY-DEMAND GRID
    
    ┌──────┬──────┬──────┐     Surge Multiplier Formula:
    │ 1.0x │ 1.5x │ 1.0x │     
    │      │ HIGH │      │     multiplier = demand / supply
    ├──────┼──────┼──────┤     
    │ 1.0x │ 2.5x │ 1.2x │     If area has:
    │      │ VERY │      │       - 100 ride requests
    ├──────┼──────┼──────┤       - 20 available drivers
    │ 1.0x │ 1.0x │ 1.0x │       → multiplier = 100/20 = 5.0
    └──────┴──────┴──────┘       → capped at 3.0x
    
    City divided into hexagonal cells (H3 index)
4. Trip Lifecycle State Machine
text

    ┌───────────┐
    │ REQUESTED │
    └─────┬─────┘
          │ driver matched
          ▼
    ┌───────────┐     driver cancels     ┌───────────┐
    │  MATCHED  │ ─────────────────────▶ │ CANCELLED │
    └─────┬─────┘                        └───────────┘
          │ driver arrives                     ▲
          ▼                                    │
    ┌───────────┐     rider cancels            │
    │  ARRIVED  │ ─────────────────────────────┘
    └─────┬─────┘
          │ trip starts
          ▼
    ┌───────────┐
    │IN_PROGRESS│
    └─────┬─────┘
          │ trip ends
          ▼
    ┌───────────┐
    │ COMPLETED │
    └─────┬─────┘
          │ payment processed
          ▼
    ┌───────────┐
    │   PAID    │
    └───────────┘
Data Models
Python

# ============================================================
# DATA MODELS
# ============================================================
from dataclasses import dataclass, field
from enum import Enum
from typing import List, Optional
import time
import uuid


class TripStatus(Enum):
    REQUESTED = "REQUESTED"
    MATCHED = "MATCHED"
    DRIVER_ARRIVED = "DRIVER_ARRIVED"
    IN_PROGRESS = "IN_PROGRESS"
    COMPLETED = "COMPLETED"
    CANCELLED = "CANCELLED"


class DriverStatus(Enum):
    AVAILABLE = "AVAILABLE"
    BUSY = "BUSY"
    OFFLINE = "OFFLINE"


@dataclass
class Location:
    latitude: float
    longitude: float
    timestamp: float = field(default_factory=time.time)


@dataclass
class User:
    user_id: str
    name: str
    email: str
    phone: str
    rating: float = 5.0


@dataclass
class Driver:
    driver_id: str
    name: str
    phone: str
    vehicle_type: str         # "SEDAN", "SUV", "PREMIUM"
    license_plate: str
    rating: float = 5.0
    status: DriverStatus = DriverStatus.OFFLINE
    current_location: Optional[Location] = None


@dataclass
class Trip:
    trip_id: str
    rider_id: str
    driver_id: Optional[str]
    pickup: Location
    dropoff: Location
    status: TripStatus
    vehicle_type: str
    estimated_fare: float
    actual_fare: Optional[float] = None
    surge_multiplier: float = 1.0
    created_at: float = field(default_factory=time.time)
    started_at: Optional[float] = None
    completed_at: Optional[float] = None
    route: List[Location] = field(default_factory=list)


@dataclass
class FareEstimate:
    base_fare: float
    distance_fare: float
    time_fare: float
    surge_multiplier: float
    total: float
Complete Python Implementation
Python

import math
import heapq
import random
import threading
import json
from collections import defaultdict
from typing import Dict, List, Optional, Tuple, Set
from dataclasses import dataclass, field
from enum import Enum
import time
import uuid
import hashlib


# ============================================================
# 1. GEOSPATIAL INDEX — QuadTree
# ============================================================
class QuadTreeNode:
    """
    QuadTree for efficient spatial queries.
    Each node represents a rectangular region.
    
    Visualization of subdivision:
    
    ┌─────────────────────┐     ┌──────────┬──────────┐
    │                     │     │    NW    │    NE    │
    │    Too many points  │ ──▶ │  ┌──┬──┐ │          │
    │    → SUBDIVIDE      │     ├──┼──┼──┤─┼──────────┤
    │                     │     │  └──┴──┘ │    SE    │
    │                     │     │    SW    │          │
    └─────────────────────┘     └──────────┴──────────┘
    """
    
    MAX_POINTS = 4  # Max points before subdivision
    MAX_DEPTH = 20
    
    def __init__(self, x_min, y_min, x_max, y_max, depth=0):
        self.boundary = (x_min, y_min, x_max, y_max)
        self.depth = depth
        self.points = []      # list of (lat, lng, driver_id)
        self.children = None   # [NW, NE, SW, SE] when subdivided
    
    def _subdivide(self):
        x_min, y_min, x_max, y_max = self.boundary
        x_mid = (x_min + x_max) / 2
        y_mid = (y_min + y_max) / 2
        d = self.depth + 1
        
        self.children = [
            QuadTreeNode(x_min, y_mid, x_mid, y_max, d),   # NW
            QuadTreeNode(x_mid, y_mid, x_max, y_max, d),   # NE
            QuadTreeNode(x_min, y_min, x_mid, y_mid, d),   # SW
            QuadTreeNode(x_mid, y_min, x_max, y_mid, d),   # SE
        ]
        
        # Re-insert existing points
        old_points = self.points
        self.points = []
        for p in old_points:
            self._insert_into_children(p)
    
    def _insert_into_children(self, point):
        for child in self.children:
            if child._contains(point[0], point[1]):
                child.insert(point)
                return
    
    def _contains(self, lat, lng):
        x_min, y_min, x_max, y_max = self.boundary
        return x_min <= lat <= x_max and y_min <= lng <= y_max
    
    def insert(self, point):
        """Insert (lat, lng, driver_id) into QuadTree"""
        if not self._contains(point[0], point[1]):
            return False
        
        if self.children is None:
            if len(self.points) < self.MAX_POINTS or self.depth >= self.MAX_DEPTH:
                self.points.append(point)
                return True
            self._subdivide()
        
        self._insert_into_children(point)
        return True
    
    def remove(self, driver_id):
        """Remove a driver from the tree"""
        if self.children is None:
            self.points = [p for p in self.points if p[2] != driver_id]
            return
        for child in self.children:
            child.remove(driver_id)
    
    def query_range(self, lat, lng, radius_km) -> List:
        """
        Find all points within radius_km of (lat, lng)
        
        ┌──────────────────────┐
        │    QuadTree Cell     │
        │         ╱╲           │
        │        ╱  ╲ radius   │
        │   ────●────          │ ● = query center
        │        ╲  ╱          │
        │         ╲╱           │
        └──────────────────────┘
        """
        results = []
        
        # Check if this node's boundary intersects the search circle
        if not self._intersects_circle(lat, lng, radius_km):
            return results
        
        # Check points in this node
        for point in self.points:
            dist = haversine_distance(lat, lng, point[0], point[1])
            if dist <= radius_km:
                results.append((point, dist))
        
        # Recurse into children
        if self.children:
            for child in self.children:
                results.extend(child.query_range(lat, lng, radius_km))
        
        return results
    
    def _intersects_circle(self, lat, lng, radius_km):
        x_min, y_min, x_max, y_max = self.boundary
        # Find closest point in rectangle to circle center
        closest_lat = max(x_min, min(lat, x_max))
        closest_lng = max(y_min, min(lng, y_max))
        dist = haversine_distance(lat, lng, closest_lat, closest_lng)
        return dist <= radius_km


def haversine_distance(lat1, lon1, lat2, lon2) -> float:
    """Calculate distance between two GPS coordinates in km"""
    R = 6371  # Earth radius in km
    dlat = math.radians(lat2 - lat1)
    dlon = math.radians(lon2 - lon1)
    a = (math.sin(dlat/2)**2 + 
         math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) * 
         math.sin(dlon/2)**2)
    c = 2 * math.asin(math.sqrt(a))
    return R * c


# ============================================================
# 2. GEOHASH IMPLEMENTATION (Alternative to QuadTree)
# ============================================================
class GeoHash:
    """
    GeoHash encodes lat/lng into a string for range queries.
    
    Precision vs Area:
    ┌──────────┬────────────────┐
    │ Chars    │ Cell Size      │
    ├──────────┼────────────────┤
    │ 1        │ 5000km × 5000km│
    │ 3        │ 156km × 156km  │
    │ 5        │ 4.9km × 4.9km  │
    │ 6        │ 1.2km × 0.6km  │
    │ 7        │ 153m × 153m    │
    │ 8        │ 38m × 19m      │
    └──────────┴────────────────┘
    """
    
    BASE32 = "0123456789bcdefghjkmnpqrstuvwxyz"
    
    @staticmethod
    def encode(lat: float, lng: float, precision: int = 7) -> str:
        lat_range = [-90.0, 90.0]
        lng_range = [-180.0, 180.0]
        geohash = []
        bit = 0
        ch = 0
        even = True
        
        while len(geohash) < precision:
            if even:  # longitude
                mid = (lng_range[0] + lng_range[1]) / 2
                if lng >= mid:
                    ch |= (1 << (4 - bit))
                    lng_range[0] = mid
                else:
                    lng_range[1] = mid
            else:  # latitude
                mid = (lat_range[0] + lat_range[1]) / 2
                if lat >= mid:
                    ch |= (1 << (4 - bit))
                    lat_range[0] = mid
                else:
                    lat_range[1] = mid
            
            even = not even
            bit += 1
            
            if bit == 5:
                geohash.append(GeoHash.BASE32[ch])
                bit = 0
                ch = 0
        
        return "".join(geohash)
    
    @staticmethod
    def neighbors(geohash: str) -> List[str]:
        """Get the 8 neighboring geohash cells"""
        # Simplified — return prefix-based neighbors
        # Real implementation uses bit manipulation
        lat, lng = GeoHash.decode(geohash)
        precision = len(geohash)
        # Approximate cell size
        delta_lat = 180.0 / (2 ** (precision * 5 // 2))
        delta_lng = 360.0 / (2 ** ((precision * 5 + 1) // 2))
        
        result = []
        for dlat in [-delta_lat, 0, delta_lat]:
            for dlng in [-delta_lng, 0, delta_lng]:
                if dlat == 0 and dlng == 0:
                    continue
                result.append(GeoHash.encode(lat + dlat, lng + dlng, precision))
        return result
    
    @staticmethod
    def decode(geohash: str) -> Tuple[float, float]:
        lat_range = [-90.0, 90.0]
        lng_range = [-180.0, 180.0]
        even = True
        
        for ch in geohash:
            idx = GeoHash.BASE32.index(ch)
            for bit in range(4, -1, -1):
                if even:
                    mid = (lng_range[0] + lng_range[1]) / 2
                    if idx & (1 << bit):
                        lng_range[0] = mid
                    else:
                        lng_range[1] = mid
                else:
                    mid = (lat_range[0] + lat_range[1]) / 2
                    if idx & (1 << bit):
                        lat_range[0] = mid
                    else:
                        lat_range[1] = mid
                even = not even
        
        lat = (lat_range[0] + lat_range[1]) / 2
        lng = (lng_range[0] + lng_range[1]) / 2
        return lat, lng


# ============================================================
# 3. LOCATION SERVICE
# ============================================================
class LocationService:
    """
    Tracks real-time driver locations using GeoHash index.
    
    Architecture:
    ┌─────────┐   WebSocket    ┌───────────┐    ┌──────────┐
    │ Driver  │───────────────▶│ Location  │───▶│  Redis   │
    │  App    │  (every 3-5s)  │  Service  │    │ GEOADD   │
    └─────────┘                └───────────┘    └──────────┘
                                     │
                                     ▼
                               ┌───────────┐
                               │ QuadTree  │
                               │  (in-mem) │
                               └───────────┘
    """
    
    def __init__(self):
        # GeoHash index: geohash_prefix -> set of driver_ids
        self.geohash_index: Dict[str, Set[str]] = defaultdict(set)
        # Driver locations: driver_id -> (lat, lng, timestamp)
        self.driver_locations: Dict[str, Tuple[float, float, float]] = {}
        # QuadTree for range queries
        self.quad_tree = QuadTreeNode(-90, -180, 90, 180)
        # Driver's current geohash (for efficient updates)
        self.driver_geohash: Dict[str, str] = {}
        self.lock = threading.Lock()
        self.GEOHASH_PRECISION = 6  # ~1.2km cells
    
    def update_driver_location(self, driver_id: str, lat: float, lng: float):
        """
        Called every 3-5 seconds per driver.
        Must handle ~1M updates/second at scale.
        """
        with self.lock:
            new_geohash = GeoHash.encode(lat, lng, self.GEOHASH_PRECISION)
            
            # Remove from old geohash cell
            if driver_id in self.driver_geohash:
                old_geohash = self.driver_geohash[driver_id]
                if old_geohash != new_geohash:
                    self.geohash_index[old_geohash].discard(driver_id)
            
            # Remove old position from QuadTree
            self.quad_tree.remove(driver_id)
            
            # Add to new geohash cell
            self.geohash_index[new_geohash].add(driver_id)
            self.driver_geohash[driver_id] = new_geohash
            self.driver_locations[driver_id] = (lat, lng, time.time())
            
            # Add to QuadTree
            self.quad_tree.insert((lat, lng, driver_id))
    
    def find_nearby_drivers(self, lat: float, lng: float, 
                            radius_km: float = 5.0) -> List[Tuple[str, float]]:
        """
        Find all drivers within radius_km of a location.
        Returns list of (driver_id, distance_km) sorted by distance.
        
        Strategy: Query QuadTree for range, then verify with Haversine.
        """
        with self.lock:
            results = self.quad_tree.query_range(lat, lng, radius_km)
            
            # Sort by distance
            nearby = [(point[2], dist) for point, dist in results]
            nearby.sort(key=lambda x: x[1])
            return nearby
    
    def find_nearby_drivers_geohash(self, lat: float, lng: float,
                                     radius_km: float = 5.0) -> List[Tuple[str, float]]:
        """
        Alternative: Find nearby drivers using GeoHash.
        Query the center cell + 8 neighbors.
        
        ┌───┬───┬───┐
        │ N │ N │ N │   N = Neighbor cells
        ├───┼───┼───┤   C = Center cell (rider's location)
        │ N │ C │ N │
        ├───┼───┼───┤   Query all 9 cells for drivers,
        │ N │ N │ N │   then filter by exact distance.
        └───┴───┴───┘
        """
        center_hash = GeoHash.encode(lat, lng, self.GEOHASH_PRECISION)
        neighbor_hashes = GeoHash.neighbors(center_hash)
        cells_to_check = [center_hash] + neighbor_hashes
        
        candidates = set()
        for cell_hash in cells_to_check:
            candidates.update(self.geohash_index.get(cell_hash, set()))
        
        results = []
        for driver_id in candidates:
            if driver_id in self.driver_locations:
                d_lat, d_lng, _ = self.driver_locations[driver_id]
                dist = haversine_distance(lat, lng, d_lat, d_lng)
                if dist <= radius_km:
                    results.append((driver_id, dist))
        
        results.sort(key=lambda x: x[1])
        return results
    
    def get_driver_location(self, driver_id: str) -> Optional[Location]:
        if driver_id in self.driver_locations:
            lat, lng, ts = self.driver_locations[driver_id]
            return Location(lat, lng, ts)
        return None
    
    def remove_driver(self, driver_id: str):
        with self.lock:
            if driver_id in self.driver_geohash:
                old_hash = self.driver_geohash.pop(driver_id)
                self.geohash_index[old_hash].discard(driver_id)
            self.driver_locations.pop(driver_id, None)
            self.quad_tree.remove(driver_id)


# ============================================================
# 4. RIDE MATCHING SERVICE
# ============================================================
class RideMatchingService:
    """
    Matches riders with optimal drivers.
    
    Matching Strategy:
    ┌────────────────────────────────────────────────────────┐
    │                                                        │
    │   Score = w1 × (1/distance) +                         │
    │           w2 × driver_rating +                        │
    │           w3 × (1/ETA) +                              │
    │           w4 × acceptance_rate                         │
    │                                                        │
    │   Higher score = better match                         │
    │                                                        │
    └────────────────────────────────────────────────────────┘
    """
    
    # Matching weights
    W_DISTANCE = 0.4
    W_RATING = 0.2
    W_ETA = 0.3
    W_ACCEPTANCE = 0.1
    
    MAX_RADIUS_KM = 10.0
    INITIAL_RADIUS_KM = 3.0
    DRIVER_RESPONSE_TIMEOUT = 15  # seconds
    
    def __init__(self, location_service: LocationService):
        self.location_service = location_service
        self.driver_registry: Dict[str, Driver] = {}
        self.pending_matches: Dict[str, dict] = {}  # trip_id -> match state
        self.driver_acceptance_rates: Dict[str, float] = defaultdict(lambda: 0.8)
    
    def register_driver(self, driver: Driver):
        self.driver_registry[driver.driver_id] = driver
    
    def find_best_match(self, trip: Trip) -> Optional[str]:
        """
        Find the best driver for a trip using expanding radius search.
        
        ┌─────────────────────────────────────────┐
        │  Expanding Radius Search:               │
        │                                         │
        │     ┌─ ─ ─ ─ ─ ─ ─ ─ ┐                │
        │     │  ┌─ ─ ─ ─ ─ ┐  │                 │
        │     │  │  ┌─────┐  │  │   R1=3km       │
        │     │  │  │  📍  │  │  │   R2=5km       │
        │     │  │  └─────┘  │  │   R3=10km      │
        │     │  └─ ─ ─ ─ ─ ┘  │                 │
        │     └─ ─ ─ ─ ─ ─ ─ ─ ┘                │
        │                                         │
        │  Start with R1, expand if no drivers.   │
        └─────────────────────────────────────────┘
        """
        radius = self.INITIAL_RADIUS_KM
        
        while radius <= self.MAX_RADIUS_KM:
            nearby = self.location_service.find_nearby_drivers(
                trip.pickup.latitude, trip.pickup.longitude, radius
            )
            
            # Filter: only available drivers matching vehicle type
            available = []
            for driver_id, distance in nearby:
                driver = self.driver_registry.get(driver_id)
                if (driver and 
                    driver.status == DriverStatus.AVAILABLE and
                    driver.vehicle_type == trip.vehicle_type):
                    available.append((driver_id, distance))
            
            if available:
                # Rank and return best
                ranked = self._rank_drivers(available, trip)
                return ranked[0][0]  # Return best driver_id
            
            radius *= 1.5  # Expand search radius
        
        return None  # No drivers found
    
    def _rank_drivers(self, candidates: List[Tuple[str, float]], 
                       trip: Trip) -> List[Tuple[str, float]]:
        """
        Rank candidate drivers by composite score.
        """
        scored = []
        max_dist = max(c[1] for c in candidates) or 1.0
        
        for driver_id, distance in candidates:
            driver = self.driver_registry[driver_id]
            
            # Normalize distance (closer = higher score)
            distance_score = 1.0 - (distance / max_dist)
            
            # Rating (0–5 → 0–1)
            rating_score = driver.rating / 5.0
            
            # ETA estimate (assumes ~30 km/h in city)
            eta_minutes = (distance / 30.0) * 60
            eta_score = 1.0 / (1.0 + eta_minutes)
            
            # Acceptance rate
            acceptance_score = self.driver_acceptance_rates[driver_id]
            
            # Composite score
            total_score = (
                self.W_DISTANCE * distance_score +
                self.W_RATING * rating_score +
                self.W_ETA * eta_score +
                self.W_ACCEPTANCE * acceptance_score
            )
            
            scored.append((driver_id, total_score))
        
        scored.sort(key=lambda x: x[1], reverse=True)
        return scored
    
    def handle_driver_response(self, trip_id: str, driver_id: str, 
                                accepted: bool) -> Optional[str]:
        """Handle driver accept/reject and try next driver if rejected"""
        if accepted:
            self.driver_registry[driver_id].status = DriverStatus.BUSY
            return driver_id
        else:
            # Update acceptance rate
            rate = self.driver_acceptance_rates[driver_id]
            self.driver_acceptance_rates[driver_id] = rate * 0.95
            return None


# ============================================================
# 5. PRICING / FARE SERVICE
# ============================================================
class PricingService:
    """
    Dynamic pricing with surge multiplier.
    
    Fare = (Base + Distance×Rate + Time×Rate) × Surge
    
    ┌─────────────────────────────────────────────┐
    │ Vehicle Type │ Base │ $/km │ $/min │ Min    │
    ├──────────────┼──────┼──────┼───────┼────────┤
    │ ECONOMY      │ 2.00 │ 1.00 │ 0.20  │ 5.00   │
    │ SEDAN        │ 3.00 │ 1.50 │ 0.30  │ 8.00   │
    │ SUV          │ 5.00 │ 2.00 │ 0.40  │ 12.00  │
    │ PREMIUM      │ 8.00 │ 3.00 │ 0.50  │ 15.00  │
    └──────────────┴──────┴──────┴───────┴────────┘
    """
    
    PRICING = {
        "ECONOMY": {"base": 2.0, "per_km": 1.0, "per_min": 0.20, "minimum": 5.0},
        "SEDAN":   {"base": 3.0, "per_km": 1.5, "per_min": 0.30, "minimum": 8.0},
        "SUV":     {"base": 5.0, "per_km": 2.0, "per_min": 0.40, "minimum": 12.0},
        "PREMIUM": {"base": 8.0, "per_km": 3.0, "per_min": 0.50, "minimum": 15.0},
    }
    
    # Surge pricing state per geohash cell
    def __init__(self):
        self.demand_count: Dict[str, int] = defaultdict(int)    # cell → request count
        self.supply_count: Dict[str, int] = defaultdict(int)    # cell → available drivers
        self.surge_multipliers: Dict[str, float] = defaultdict(lambda: 1.0)
        self.SURGE_CAP = 3.0
    
    def estimate_fare(self, pickup: Location, dropoff: Location,
                       vehicle_type: str) -> FareEstimate:
        distance_km = haversine_distance(
            pickup.latitude, pickup.longitude,
            dropoff.latitude, dropoff.longitude
        )
        # Estimate time: ~30 km/h average city speed
        estimated_minutes = (distance_km / 30.0) * 60
        
        pricing = self.PRICING.get(vehicle_type, self.PRICING["SEDAN"])
        
        base = pricing["base"]
        distance_fare = distance_km * pricing["per_km"]
        time_fare = estimated_minutes * pricing["per_min"]
        
        # Get surge multiplier for pickup location
        cell = GeoHash.encode(pickup.latitude, pickup.longitude, 5)
        surge = self.surge_multipliers.get(cell, 1.0)
        
        subtotal = base + distance_fare + time_fare
        total = max(subtotal * surge, pricing["minimum"])
        
        return FareEstimate(
            base_fare=base,
            distance_fare=distance_fare,
            time_fare=time_fare,
            surge_multiplier=surge,
            total=round(total, 2)
        )
    
    def update_surge(self, cell: str, demand: int, supply: int):
        """
        Update surge pricing for a geographic cell.
        
        Surge Logic:
        ┌──────────────────────────────────┐
        │ Ratio (D/S) │ Multiplier         │
        ├─────────────┼────────────────────┤
        │ < 1.0       │ 1.0x (no surge)    │
        │ 1.0 - 1.5   │ 1.2x              │
        │ 1.5 - 2.0   │ 1.5x              │
        │ 2.0 - 3.0   │ 2.0x              │
        │ > 3.0       │ 2.5x (capped 3.0) │
        └─────────────┴────────────────────┘
        """
        if supply == 0:
            self.surge_multipliers[cell] = self.SURGE_CAP
            return
        
        ratio = demand / supply
        
        if ratio < 1.0:
            multiplier = 1.0
        elif ratio < 1.5:
            multiplier = 1.2
        elif ratio < 2.0:
            multiplier = 1.5
        elif ratio < 3.0:
            multiplier = 2.0
        else:
            multiplier = min(ratio * 0.8, self.SURGE_CAP)
        
        # Smooth transition (exponential moving average)
        old = self.surge_multipliers.get(cell, 1.0)
        self.surge_multipliers[cell] = 0.7 * old + 0.3 * multiplier
    
    def calculate_final_fare(self, trip: Trip) -> float:
        """Calculate actual fare based on real distance/time"""
        if not trip.route or not trip.started_at or not trip.completed_at:
            return trip.estimated_fare
        
        # Calculate actual distance from GPS route
        total_distance = 0.0
        for i in range(1, len(trip.route)):
            total_distance += haversine_distance(
                trip.route[i-1].latitude, trip.route[i-1].longitude,
                trip.route[i].latitude, trip.route[i].longitude
            )
        
        actual_minutes = (trip.completed_at - trip.started_at) / 60.0
        pricing = self.PRICING.get(trip.vehicle_type, self.PRICING["SEDAN"])
        
        fare = (pricing["base"] + 
                total_distance * pricing["per_km"] + 
                actual_minutes * pricing["per_min"])
        fare *= trip.surge_multiplier
        fare = max(fare, pricing["minimum"])
        
        return round(fare, 2)


# ============================================================
# 6. TRIP SERVICE — Orchestrator
# ============================================================
class TripService:
    """
    Orchestrates the entire trip lifecycle.
    
    Request Flow:
    ┌────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐
    │ Rider  │───▶│  Trip    │───▶│ Matching │───▶│  Notify  │
    │Request │    │ Service  │    │ Service  │    │  Driver  │
    └────────┘    └────┬─────┘    └──────────┘    └────┬─────┘
                       │                                │
                       │         ┌──────────┐           │
                       │◀────────│  Driver  │◀──────────┘
                       │         │ Accepts  │
                       │         └──────────┘
                       │
                  ┌────▼─────┐
                  │  Start   │
                  │   Trip   │
                  └──────────┘
    """
    
    def __init__(self):
        self.location_service = LocationService()
        self.matching_service = RideMatchingService(self.location_service)
        self.pricing_service = PricingService()
        self.notification_service = NotificationService()
        
        self.trips: Dict[str, Trip] = {}
        self.rider_active_trip: Dict[str, str] = {}
        self.driver_active_trip: Dict[str, str] = {}
    
    def request_ride(self, rider_id: str, pickup: Location, 
                      dropoff: Location, vehicle_type: str = "SEDAN") -> Trip:
        """Step 1: Rider requests a ride"""
        
        # Check if rider already has active trip
        if rider_id in self.rider_active_trip:
            raise Exception("Rider already has an active trip")
        
        # Estimate fare
        fare = self.pricing_service.estimate_fare(pickup, dropoff, vehicle_type)
        
        # Create trip
        trip = Trip(
            trip_id=str(uuid.uuid4()),
            rider_id=rider_id,
            driver_id=None,
            pickup=pickup,
            dropoff=dropoff,
            status=TripStatus.REQUESTED,
            vehicle_type=vehicle_type,
            estimated_fare=fare.total,
            surge_multiplier=fare.surge_multiplier,
        )
        
        self.trips[trip.trip_id] = trip
        self.rider_active_trip[rider_id] = trip.trip_id
        
        print(f"[TRIP] Created trip {trip.trip_id[:8]}... "
              f"Estimated fare: ${fare.total} (surge: {fare.surge_multiplier}x)")
        
        # Find and match driver
        self._match_driver(trip)
        
        return trip
    
    def _match_driver(self, trip: Trip):
        """Step 2: Find and assign best driver"""
        driver_id = self.matching_service.find_best_match(trip)
        
        if driver_id is None:
            print(f"[TRIP] No drivers available for trip {trip.trip_id[:8]}")
            trip.status = TripStatus.CANCELLED
            self.rider_active_trip.pop(trip.rider_id, None)
            return
        
        # In real system, this sends push notification and waits
        # Here we simulate driver acceptance
        print(f"[MATCH] Sending request to driver {driver_id[:8]}...")
        
        # Simulate driver accepting
        trip.driver_id = driver_id
        trip.status = TripStatus.MATCHED
        self.driver_active_trip[driver_id] = trip.trip_id
        
        driver = self.matching_service.driver_registry[driver_id]
        driver.status = DriverStatus.BUSY
        
        driver_loc = self.location_service.get_driver_location(driver_id)
        if driver_loc:
            eta = haversine_distance(
                driver_loc.latitude, driver_loc.longitude,
                trip.pickup.latitude, trip.pickup.longitude
            ) / 30.0 * 60  # minutes
            print(f"[MATCH] Driver {driver_id[:8]} matched! ETA: {eta:.1f} min")
        
        self.notification_service.notify_rider(
            trip.rider_id, f"Driver matched! Trip {trip.trip_id[:8]}"
        )
    
    def start_trip(self, trip_id: str):
        """Step 3: Driver picks up rider, trip starts"""
        trip = self.trips[trip_id]
        trip.status = TripStatus.IN_PROGRESS
        trip.started_at = time.time()
        print(f"[TRIP] Trip {trip_id[:8]} started")
    
    def update_trip_location(self, trip_id: str, lat: float, lng: float):
        """Track route during trip"""
        trip = self.trips[trip_id]
        trip.route.append(Location(lat, lng))
    
    def complete_trip(self, trip_id: str):
        """Step 4: Trip completed, calculate fare"""
        trip = self.trips[trip_id]
        trip.status = TripStatus.COMPLETED
        trip.completed_at = time.time()
        
        # Calculate actual fare
        trip.actual_fare = self.pricing_service.calculate_final_fare(trip)
        
        # Free up driver
        if trip.driver_id:
            driver = self.matching_service.driver_registry.get(trip.driver_id)
            if driver:
                driver.status = DriverStatus.AVAILABLE
            self.driver_active_trip.pop(trip.driver_id, None)
        
        self.rider_active_trip.pop(trip.rider_id, None)
        
        print(f"[TRIP] Trip {trip_id[:8]} completed. "
              f"Fare: ${trip.actual_fare}")
        return trip
    
    def get_eta(self, driver_id: str, destination: Location) -> float:
        """Estimate time of arrival in minutes"""
        driver_loc = self.location_service.get_driver_location(driver_id)
        if not driver_loc:
            return float('inf')
        
        distance = haversine_distance(
            driver_loc.latitude, driver_loc.longitude,
            destination.latitude, destination.longitude
        )
        # Simple: assume 30 km/h in city
        return (distance / 30.0) * 60


# ============================================================
# 7. NOTIFICATION SERVICE
# ============================================================
class NotificationService:
    """
    Sends real-time notifications via WebSocket / Push.
    
    ┌──────────┐    ┌───────────┐    ┌──────────────┐
    │  Trip    │───▶│   Kafka   │───▶│ Notification │
    │ Service  │    │  (events) │    │   Workers    │
    └──────────┘    └───────────┘    └──────┬───────┘
                                           │
                                    ┌──────┴───────┐
                                    │              │
                               ┌────▼────┐   ┌────▼────┐
                               │WebSocket│   │  Push   │
                               │ (online)│   │(offline)│
                               └─────────┘   └─────────┘
    """
    
    def __init__(self):
        self.websocket_connections: Dict[str, object] = {}
    
    def notify_rider(self, rider_id: str, message: str):
        print(f"  📱 [NOTIFY→RIDER {rider_id[:8]}] {message}")
    
    def notify_driver(self, driver_id: str, message: str):
        print(f"  📱 [NOTIFY→DRIVER {driver_id[:8]}] {message}")
    
    def broadcast_location(self, trip_id: str, lat: float, lng: float):
        """Send real-time location updates to trip participants"""
        pass


# ============================================================
# 8. END-TO-END SIMULATION
# ============================================================
def simulate_uber():
    print("=" * 70)
    print("  UBER RIDE-MATCHING SIMULATION")
    print("=" * 70)
    
    service = TripService()
    
    # Register drivers in San Francisco area
    drivers = [
        Driver("d1", "Alice Driver", "555-0001", "SEDAN", "ABC-123", 4.9),
        Driver("d2", "Bob Driver", "555-0002", "SEDAN", "DEF-456", 4.7),
        Driver("d3", "Carol Driver", "555-0003", "SUV", "GHI-789", 4.8),
        Driver("d4", "Dave Driver", "555-0004", "SEDAN", "JKL-012", 4.5),
        Driver("d5", "Eve Driver", "555-0005", "PREMIUM", "MNO-345", 4.95),
    ]
    
    for driver in drivers:
        driver.status = DriverStatus.AVAILABLE
        service.matching_service.register_driver(driver)
    
    # Simulate driver locations (San Francisco area)
    # Rider is at Market St, drivers scattered nearby
    driver_locations = {
        "d1": (37.7850, -122.4094),  # 0.5 km away
        "d2": (37.7900, -122.4000),  # 1.2 km away
        "d3": (37.7700, -122.4200),  # 2.1 km away
        "d4": (37.8000, -122.3900),  # 3.0 km away
        "d5": (37.7600, -122.4300),  # 3.5 km away
    }
    
    for driver_id, (lat, lng) in driver_locations.items():
        service.location_service.update_driver_location(driver_id, lat, lng)
    
    print("\n📍 Driver Locations Registered")
    print("-" * 40)
    
    # Rider at Market Street, SF
    pickup = Location(37.7849, -122.4094)
    dropoff = Location(37.7749, -122.4194)
    
    # Find nearby drivers
    print("\n🔍 Searching for nearby SEDAN drivers...")
    nearby = service.location_service.find_nearby_drivers(
        pickup.latitude, pickup.longitude, 5.0
    )
    for driver_id, dist in nearby:
        driver = service.matching_service.driver_registry.get(driver_id)
        if driver:
            print(f"  🚗 {driver.name} ({driver.vehicle_type}) - "
                  f"{dist:.2f} km away - Rating: {driver.rating}")
    
    # Request ride
    print("\n" + "=" * 40)
    print("🚕 REQUESTING RIDE")
    print("=" * 40)
    trip = service.request_ride("rider_001", pickup, dropoff, "SEDAN")
    
    # Simulate trip
    if trip.status == TripStatus.MATCHED:
        print(f"\n▶ Starting trip...")
        service.start_trip(trip.trip_id)
        
        # Simulate route updates
        route_points = [
            (37.7840, -122.4100),
            (37.7820, -122.4130),
            (37.7800, -122.4150),
            (37.7780, -122.4170),
            (37.7749, -122.4194),
        ]
        for lat, lng in route_points:
            service.update_trip_location(trip.trip_id, lat, lng)
        
        # Complete trip
        trip.started_at = time.time() - 600  # 10 min ago
        completed = service.complete_trip(trip.trip_id)
        
        print(f"\n📊 Trip Summary:")
        print(f"  Status: {completed.status.value}")
        print(f"  Estimated Fare: ${completed.estimated_fare}")
        print(f"  Actual Fare: ${completed.actual_fare}")
        print(f"  Surge: {completed.surge_multiplier}x")
        print(f"  Route Points: {len(completed.route)}")
    
    # Test surge pricing
    print("\n" + "=" * 40)
    print("📈 SURGE PRICING TEST")
    print("=" * 40)
    
    cell = GeoHash.encode(pickup.latitude, pickup.longitude, 5)
    for demand, supply in [(10, 10), (20, 10), (50, 10), (100, 10)]:
        service.pricing_service.update_surge(cell, demand, supply)
        surge = service.pricing_service.surge_multipliers[cell]
        fare = service.pricing_service.estimate_fare(pickup, dropoff, "SEDAN")
        print(f"  Demand={demand:3d}, Supply={supply:2d} → "
              f"Surge={surge:.2f}x, Fare=${fare.total:.2f}")


simulate_uber()
14. Design Netflix Streaming Platform
System Overview
text

┌──────────────────────────────────────────────────────────────────────────────┐
│                      NETFLIX SYSTEM ARCHITECTURE                            │
│                                                                              │
│  ┌───────────┐   ┌───────────┐   ┌───────────┐                             │
│  │ Smart TV  │   │  Mobile   │   │  Browser  │                             │
│  └─────┬─────┘   └─────┬─────┘   └─────┬─────┘                             │
│        └───────────────┼───────────────┘                                    │
│                        ▼                                                     │
│               ┌────────────────┐                                            │
│               │   CDN (OCA)    │ ← Open Connect Appliances                  │
│               │  Edge Servers  │   (Netflix's own CDN)                      │
│               └────────┬───────┘                                            │
│                        │ cache miss                                          │
│                        ▼                                                     │
│  ┌──────────────────────────────────────────────────────┐                   │
│  │              BACKEND SERVICES (AWS)                   │                   │
│  │                                                       │                   │
│  │  ┌──────────┐ ┌──────────┐ ┌─────────┐ ┌──────────┐ │                   │
│  │  │  API     │ │ Streaming│ │ Content │ │  User    │ │                   │
│  │  │ Gateway  │ │ Service  │ │ Service │ │ Service  │ │                   │
│  │  └────┬─────┘ └────┬─────┘ └────┬────┘ └────┬─────┘ │                   │
│  │       │            │            │           │        │                   │
│  │  ┌────▼─────┐ ┌────▼─────┐ ┌────▼────┐ ┌───▼──────┐│                   │
│  │  │ Search   │ │ Recommend│ │Transcode│ │ Profile  ││                   │
│  │  │ Service  │ │ Engine   │ │Pipeline │ │ Service  ││                   │
│  │  └──────────┘ └──────────┘ └─────────┘ └──────────┘│                   │
│  └──────────────────────┬────────────────────────────────┘                   │
│                         ▼                                                    │
│  ┌──────────────────────────────────────────────────────┐                   │
│  │              DATA LAYER                               │                   │
│  │  ┌─────────┐ ┌───────┐ ┌────────┐ ┌───────────────┐ │                   │
│  │  │Cassandra│ │ MySQL │ │ Redis  │ │ S3 (Videos)   │ │                   │
│  │  │(viewing │ │(billing│ │(session│ │               │ │                   │
│  │  │ history)│ │ users) │ │ cache) │ │               │ │                   │
│  │  └─────────┘ └───────┘ └────────┘ └───────────────┘ │                   │
│  └──────────────────────────────────────────────────────┘                   │
└──────────────────────────────────────────────────────────────────────────────┘
Key Architecture Decisions
text

┌─────────────────────────────────────────────────────────────────────┐
│                    VIDEO PROCESSING PIPELINE                        │
│                                                                     │
│  ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐     │
│  │  Upload  │───▶│  Encode  │───▶│ Package  │───▶│  Deploy  │     │
│  │ Original │    │  Multiple│    │  HLS/    │    │  to CDN  │     │
│  │  Master  │    │  Profiles│    │  DASH    │    │  nodes   │     │
│  └──────────┘    └──────────┘    └──────────┘    └──────────┘     │
│                       │                                             │
│                       ▼                                             │
│          ┌─────────────────────────┐                               │
│          │  ENCODING PROFILES      │                               │
│          ├─────────────────────────┤                               │
│          │ 4K   : 2160p @ 16 Mbps │                               │
│          │ 1080p: 1080p @ 5 Mbps  │                               │
│          │ 720p : 720p  @ 3 Mbps  │                               │
│          │ 480p : 480p  @ 1.5 Mbps│                               │
│          │ 360p : 360p  @ 0.8 Mbps│                               │
│          │ 240p : 240p  @ 0.3 Mbps│                               │
│          └─────────────────────────┘                               │
│                                                                     │
│  Per-title encoding: Each title gets custom bitrate ladder         │
│  based on complexity (animation needs fewer bits than action)      │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│            ADAPTIVE BITRATE STREAMING (ABR)                         │
│                                                                     │
│  Bandwidth                                                          │
│    ▲                                                                │
│  8 │     ╱──────╲         ╱────╲                                   │
│  6 │    ╱        ╲       ╱      ╲                                  │
│  4 │───╱          ╲─────╱        ╲───────                          │
│  2 │                                                                │
│  0 │──────────────────────────────────────▶ Time                   │
│    │                                                                │
│    │   1080p    720p     1080p    720p                              │
│    │                                                                │
│  Client continuously measures bandwidth and switches               │
│  between quality levels seamlessly.                                 │
│                                                                     │
│  Manifest File (HLS .m3u8):                                        │
│  ┌─────────────────────────────────┐                               │
│  │ #EXT-X-STREAM-INF:BANDWIDTH=..│                               │
│  │ video_1080p/segment_001.ts     │                               │
│  │ video_1080p/segment_002.ts     │                               │
│  │ ...                             │                               │
│  └─────────────────────────────────┘                               │
└─────────────────────────────────────────────────────────────────────┘
CDN Architecture (Open Connect)
text

    GLOBAL CDN DISTRIBUTION
    ═══════════════════════
    
    ┌─── ISP Network (Comcast) ──────────┐
    │  ┌──────────┐                      │
    │  │   OCA    │ ← Netflix server     │
    │  │ Appliance│   inside ISP         │
    │  └──────┬───┘                      │
    │         │ serves 95% of traffic    │
    │    ┌────▼─────┐                    │
    │    │ Viewers  │                    │
    │    └──────────┘                    │
    └────────────────────────────────────┘
    
    Content Placement:
    ┌────────────────────────────────────────────────────┐
    │                                                    │
    │  Popular content → ALL edge locations              │
    │  Regional content → Regional edge locations        │
    │  Long-tail content → Central storage (S3)          │
    │                                                    │
    │  Cache tier:                                       │
    │  Client → Edge OCA → Regional OCA → Origin (S3)   │
    │                                                    │
    └────────────────────────────────────────────────────┘
Python Implementation
Python

import uuid
import time
import math
import hashlib
from enum import Enum
from dataclasses import dataclass, field
from typing import Dict, List, Optional, Set, Tuple
from collections import defaultdict
import heapq


# ============================================================
# DATA MODELS
# ============================================================
class VideoQuality(Enum):
    P240 = ("240p", 320, 240, 300_000)      # 300 Kbps
    P360 = ("360p", 640, 360, 800_000)       # 800 Kbps
    P480 = ("480p", 854, 480, 1_500_000)     # 1.5 Mbps
    P720 = ("720p", 1280, 720, 3_000_000)    # 3 Mbps
    P1080 = ("1080p", 1920, 1080, 5_000_000) # 5 Mbps
    P4K = ("4K", 3840, 2160, 16_000_000)     # 16 Mbps
    
    def __init__(self, label, width, height, bitrate):
        self.label = label
        self.width = width
        self.height = height
        self.bitrate = bitrate


class ContentType(Enum):
    MOVIE = "movie"
    SERIES = "series"
    DOCUMENTARY = "documentary"


@dataclass
class VideoSegment:
    """A single chunk of video (2-10 seconds)"""
    segment_id: str
    video_id: str
    quality: VideoQuality
    segment_number: int
    duration_seconds: float       # typically 4-6 seconds
    size_bytes: int
    url: str                      # CDN URL


@dataclass
class VideoContent:
    video_id: str
    title: str
    description: str
    content_type: ContentType
    duration_seconds: int
    genres: List[str]
    cast: List[str]
    release_year: int
    rating: float
    # Encoded versions
    segments: Dict[str, List[VideoSegment]] = field(default_factory=dict)
    # key = quality label, value = list of segments
    thumbnail_url: str = ""
    manifest_url: str = ""


@dataclass
class UserProfile:
    profile_id: str
    user_id: str
    name: str
    avatar: str
    viewing_history: List[dict] = field(default_factory=list)
    watchlist: List[str] = field(default_factory=list)
    preferences: Dict[str, float] = field(default_factory=dict)
    # genre -> affinity score


@dataclass
class StreamingSession:
    session_id: str
    profile_id: str
    video_id: str
    current_position_seconds: float
    current_quality: VideoQuality
    started_at: float
    bandwidth_history: List[float] = field(default_factory=list)
    # bits per second measurements


# ============================================================
# 1. VIDEO PROCESSING PIPELINE (Transcoding)
# ============================================================
class VideoProcessingPipeline:
    """
    Processes uploaded video into multiple quality levels.
    
    Pipeline:
    ┌────────┐   ┌──────────┐   ┌─────────┐   ┌──────────┐   ┌─────┐
    │ Upload │──▶│ Validate │──▶│ Encode  │──▶│ Package  │──▶│ CDN │
    │ Master │   │ & Analyze│   │ Multiple│   │ HLS/DASH │   │ Push│
    │ File   │   │          │   │ Quality │   │          │   │     │
    └────────┘   └──────────┘   └─────────┘   └──────────┘   └─────┘
    """
    
    SEGMENT_DURATION = 4  # seconds per segment
    
    QUALITY_PROFILES = [
        VideoQuality.P240,
        VideoQuality.P360,
        VideoQuality.P480,
        VideoQuality.P720,
        VideoQuality.P1080,
        VideoQuality.P4K,
    ]
    
    def __init__(self):
        self.processing_queue: List[dict] = []
        self.processed_videos: Dict[str, VideoContent] = {}
    
    def submit_for_processing(self, video: VideoContent, 
                                master_file_path: str) -> str:
        """Submit a video for transcoding"""
        job_id = str(uuid.uuid4())
        
        job = {
            "job_id": job_id,
            "video_id": video.video_id,
            "master_file": master_file_path,
            "status": "QUEUED",
            "submitted_at": time.time(),
        }
        self.processing_queue.append(job)
        
        print(f"[TRANSCODE] Job {job_id[:8]} queued for '{video.title}'")
        
        # Simulate processing
        self._process_video(video, job)
        
        return job_id
    
    def _process_video(self, video: VideoContent, job: dict):
        """
        Simulate transcoding into multiple quality profiles.
        
        Real Netflix uses per-title encoding:
        - Analyzes scene complexity
        - Creates custom bitrate ladder per title
        - Animation might need: 240p@100kbps, 1080p@2Mbps
        - Action might need:    240p@300kbps, 1080p@8Mbps
        """
        job["status"] = "PROCESSING"
        total_segments = math.ceil(video.duration_seconds / self.SEGMENT_DURATION)
        
        print(f"[TRANSCODE] Processing '{video.title}': "
              f"{total_segments} segments × {len(self.QUALITY_PROFILES)} qualities")
        
        for quality in self.QUALITY_PROFILES:
            segments = []
            for seg_num in range(total_segments):
                # Calculate segment size based on bitrate and duration
                actual_duration = min(
                    self.SEGMENT_DURATION, 
                    video.duration_seconds - seg_num * self.SEGMENT_DURATION
                )
                size_bytes = int(quality.bitrate * actual_duration / 8)
                
                segment = VideoSegment(
                    segment_id=f"{video.video_id}_{quality.label}_{seg_num:05d}",
                    video_id=video.video_id,
                    quality=quality,
                    segment_number=seg_num,
                    duration_seconds=actual_duration,
                    size_bytes=size_bytes,
                    url=f"https://cdn.netflix.com/v/{video.video_id}"
                        f"/{quality.label}/seg_{seg_num:05d}.ts"
                )
                segments.append(segment)
            
            video.segments[quality.label] = segments
        
        # Generate manifest
        video.manifest_url = self._generate_manifest(video)
        
        self.processed_videos[video.video_id] = video
        job["status"] = "COMPLETED"
        
        total_size = sum(
            sum(s.size_bytes for s in segs) 
            for segs in video.segments.values()
        )
        print(f"[TRANSCODE] Complete! Total storage: "
              f"{total_size / (1024*1024*1024):.2f} GB")
    
    def _generate_manifest(self, video: VideoContent) -> str:
        """
        Generate HLS manifest (.m3u8) file.
        
        Master playlist points to quality-specific playlists.
        """
        manifest = "#EXTM3U\n"
        manifest += "#EXT-X-VERSION:3\n\n"
        
        for quality in self.QUALITY_PROFILES:
            if quality.label in video.segments:
                manifest += (
                    f"#EXT-X-STREAM-INF:BANDWIDTH={quality.bitrate},"
                    f"RESOLUTION={quality.width}x{quality.height}\n"
                    f"{quality.label}/playlist.m3u8\n\n"
                )
        
        return manifest


# ============================================================
# 2. CDN SERVICE — Content Distribution
# ============================================================
class CDNNode:
    """Represents a CDN edge server (OCA)"""
    
    def __init__(self, node_id: str, region: str, capacity_gb: float):
        self.node_id = node_id
        self.region = region
        self.capacity_gb = capacity_gb
        self.used_gb = 0.0
        self.cache: Dict[str, bytes] = {}  # segment_id → data (simulated)
        self.access_count: Dict[str, int] = defaultdict(int)
        self.hit_count = 0
        self.miss_count = 0
    
    def get_segment(self, segment_id: str) -> Optional[str]:
        """Try to serve segment from cache"""
        if segment_id in self.cache:
            self.hit_count += 1
            self.access_count[segment_id] += 1
            return f"CDN:{self.node_id}:{segment_id}"
        self.miss_count += 1
        return None
    
    def cache_segment(self, segment_id: str, size_bytes: int) -> bool:
        """Cache a segment on this node"""
        size_gb = size_bytes / (1024 ** 3)
        if self.used_gb + size_gb > self.capacity_gb:
            self._evict_lru()
        
        self.cache[segment_id] = True  # Simulated
        self.used_gb += size_gb
        return True
    
    def _evict_lru(self):
        """Evict least recently used segment"""
        if not self.access_count:
            return
        lru_segment = min(self.access_count, key=self.access_count.get)
        del self.cache[lru_segment]
        del self.access_count[lru_segment]
    
    @property
    def hit_rate(self):
        total = self.hit_count + self.miss_count
        return self.hit_count / total if total > 0 else 0


class CDNService:
    """
    Netflix's Open Connect CDN architecture.
    
    ┌────────────────────────────────────────────────────────────┐
    │  Content Popularity Tiers:                                 │
    │                                                            │
    │  ┌─────────┐  HOT    → All edge nodes (top 20% content)  │
    │  │█████████│                                               │
    │  │█████████│  WARM   → Regional nodes (next 30%)          │
    │  │█████████│                                               │
    │  │░░░░░░░░░│  COLD   → Origin only (bottom 50%)          │
    │  └─────────┘                                               │
    │                                                            │
    │  Off-peak fill: Pre-populate caches during low traffic    │
    └────────────────────────────────────────────────────────────┘
    """
    
    def __init__(self):
        self.nodes: Dict[str, CDNNode] = {}
        self.region_nodes: Dict[str, List[str]] = defaultdict(list)
        self.content_popularity: Dict[str, int] = defaultdict(int)
        self.origin_storage: Dict[str, bool] = {}  # S3 simulation
    
    def add_node(self, node: CDNNode):
        self.nodes[node.node_id] = node
        self.region_nodes[node.region].append(node.node_id)
    
    def resolve_cdn_url(self, segment_id: str, 
                         user_region: str) -> Tuple[str, str]:
        """
        Resolve which CDN node should serve a segment.
        
        Resolution order:
        1. Local edge node (same ISP)
        2. Regional node
        3. Origin (S3)
        """
        # Try local/regional nodes first
        regional_nodes = self.region_nodes.get(user_region, [])
        
        for node_id in regional_nodes:
            node = self.nodes[node_id]
            result = node.get_segment(segment_id)
            if result:
                return result, "EDGE_HIT"
        
        # Cache miss — fetch from origin and cache locally
        if segment_id in self.origin_storage:
            # Cache on the closest edge node
            if regional_nodes:
                node = self.nodes[regional_nodes[0]]
                node.cache_segment(segment_id, 2_000_000)  # ~2MB segment
            return f"ORIGIN:{segment_id}", "ORIGIN_FETCH"
        
        return "", "NOT_FOUND"
    
    def distribute_content(self, video: VideoContent, 
                            popularity_tier: str = "WARM"):
        """
        Pre-populate CDN nodes based on content popularity.
        
        Done during off-peak hours (2-6 AM local time).
        """
        for quality_label, segments in video.segments.items():
            for segment in segments:
                self.origin_storage[segment.segment_id] = True
                
                if popularity_tier == "HOT":
                    # Push to ALL edge nodes
                    for node in self.nodes.values():
                        node.cache_segment(segment.segment_id, 
                                          segment.size_bytes)
                elif popularity_tier == "WARM":
                    # Push to regional nodes only
                    pass  # Cached on demand
    
    def print_cdn_stats(self):
        print("\n📊 CDN Statistics:")
        for node_id, node in self.nodes.items():
            print(f"  Node {node_id} ({node.region}): "
                  f"Hit Rate={node.hit_rate:.1%}, "
                  f"Cached={len(node.cache)} segments, "
                  f"Used={node.used_gb:.2f}/{node.capacity_gb} GB")


# ============================================================
# 3. STREAMING SERVICE — Adaptive Bitrate
# ============================================================
class StreamingService:
    """
    Manages video streaming sessions with adaptive bitrate.
    
    ABR Algorithm (similar to Netflix's buffer-based approach):
    
    ┌─────────────────────────────────────────────────┐
    │  Buffer Level vs Quality Selection               │
    │                                                   │
    │  Quality ▲                                       │
    │   4K     │                          ╱────────    │
    │  1080p   │                   ╱─────╱             │
    │   720p   │            ╱─────╱                    │
    │   480p   │     ╱─────╱                           │
    │   240p   │────╱                                  │
    │          └──────────────────────────────▶ Buffer │
    │          0    5s   10s   20s   40s   60s  level  │
    └─────────────────────────────────────────────────┘
    """
    
    # Buffer thresholds for quality switching
    BUFFER_LOW = 5.0        # seconds — switch DOWN
    BUFFER_TARGET = 30.0    # seconds — maintain
    BUFFER_HIGH = 60.0      # seconds — switch UP
    
    QUALITY_ORDER = [
        VideoQuality.P240, VideoQuality.P360, VideoQuality.P480,
        VideoQuality.P720, VideoQuality.P1080, VideoQuality.P4K,
    ]
    
    def __init__(self, cdn_service: CDNService):
        self.cdn_service = cdn_service
        self.active_sessions: Dict[str, StreamingSession] = {}
        self.viewing_history: Dict[str, List[dict]] = defaultdict(list)
    
    def start_stream(self, profile_id: str, video_id: str,
                      resume_position: float = 0.0) -> StreamingSession:
        """Initialize a streaming session"""
        session = StreamingSession(
            session_id=str(uuid.uuid4()),
            profile_id=profile_id,
            video_id=video_id,
            current_position_seconds=resume_position,
            current_quality=VideoQuality.P480,  # Start conservative
            started_at=time.time(),
        )
        self.active_sessions[session.session_id] = session
        
        print(f"[STREAM] Session {session.session_id[:8]} started "
              f"for video {video_id[:8]} at {resume_position}s")
        return session
    
    def get_next_segment(self, session_id: str, 
                          measured_bandwidth_bps: float,
                          buffer_level_seconds: float) -> Optional[dict]:
        """
        Called by client to get the next video segment.
        Implements adaptive bitrate selection.
        """
        session = self.active_sessions.get(session_id)
        if not session:
            return None
        
        session.bandwidth_history.append(measured_bandwidth_bps)
        
        # Select quality based on bandwidth and buffer
        new_quality = self._select_quality(
            measured_bandwidth_bps, buffer_level_seconds, session
        )
        
        old_label = session.current_quality.label
        session.current_quality = new_quality
        
        if old_label != new_quality.label:
            print(f"  [ABR] Quality switch: {old_label} → {new_quality.label} "
                  f"(BW: {measured_bandwidth_bps/1_000_000:.1f} Mbps, "
                  f"Buffer: {buffer_level_seconds:.1f}s)")
        
        # Calculate segment number
        seg_num = int(session.current_position_seconds / 4)  # 4s segments
        segment_id = f"{session.video_id}_{new_quality.label}_{seg_num:05d}"
        
        # Resolve CDN URL
        url, source = self.cdn_service.resolve_cdn_url(
            segment_id, "us-west-2"
        )
        
        session.current_position_seconds += 4
        
        return {
            "segment_id": segment_id,
            "quality": new_quality.label,
            "url": url,
            "source": source,
            "segment_number": seg_num,
        }
    
    def _select_quality(self, bandwidth_bps: float,
                         buffer_seconds: float,
                         session: StreamingSession) -> VideoQuality:
        """
        Adaptive Bitrate Selection Algorithm.
        
        Netflix's actual algorithm considers:
        1. Throughput (measured bandwidth)
        2. Buffer occupancy
        3. Network stability
        4. Device capability
        """
        # Use conservative estimate: 70th percentile of recent bandwidth
        if len(session.bandwidth_history) >= 3:
            recent = sorted(session.bandwidth_history[-10:])
            safe_bandwidth = recent[int(len(recent) * 0.3)]
        else:
            safe_bandwidth = bandwidth_bps
        
        # Buffer-based adjustments
        if buffer_seconds < self.BUFFER_LOW:
            # Emergency: drop quality immediately
            current_idx = self.QUALITY_ORDER.index(session.current_quality)
            return self.QUALITY_ORDER[max(0, current_idx - 2)]
        
        if buffer_seconds < self.BUFFER_TARGET * 0.5:
            # Low buffer: don't increase, maybe decrease
            safe_bandwidth *= 0.7
        elif buffer_seconds > self.BUFFER_HIGH:
            # High buffer: can be more aggressive
            safe_bandwidth *= 1.3
        
        # Select highest quality that fits bandwidth
        # Use 80% of bandwidth to leave headroom
        target_bitrate = safe_bandwidth * 0.8
        
        best_quality = self.QUALITY_ORDER[0]
        for quality in self.QUALITY_ORDER:
            if quality.bitrate <= target_bitrate:
                best_quality = quality
            else:
                break
        
        # Prevent rapid oscillation (hysteresis)
        current_idx = self.QUALITY_ORDER.index(session.current_quality)
        best_idx = self.QUALITY_ORDER.index(best_quality)
        
        if abs(best_idx - current_idx) == 1 and len(session.bandwidth_history) < 5:
            return session.current_quality  # Avoid small switches
        
        return best_quality
    
    def stop_stream(self, session_id: str):
        """Stop streaming and save progress"""
        session = self.active_sessions.pop(session_id, None)
        if session:
            self.viewing_history[session.profile_id].append({
                "video_id": session.video_id,
                "watched_until": session.current_position_seconds,
                "timestamp": time.time(),
            })
            print(f"[STREAM] Session {session_id[:8]} stopped at "
                  f"{session.current_position_seconds}s")
            return session.current_position_seconds
        return 0


# ============================================================
# 4. RECOMMENDATION ENGINE
# ============================================================
class RecommendationEngine:
    """
    Netflix recommendation system.
    
    Uses multiple signals:
    ┌───────────────────────────────────────────────────────┐
    │                                                       │
    │  ┌─────────────┐  ┌──────────────┐  ┌─────────────┐ │
    │  │ Collaborative│  │Content-Based │  │ Trending /  │ │
    │  │  Filtering   │  │  Filtering   │  │ Popularity  │ │
    │  │              │  │              │  │             │ │
    │  │ "Users like  │  │ "Movies with │  │ "Popular   │ │
    │  │  you watched"│  │  similar     │  │  right now"│ │
    │  │              │  │  features"   │  │             │ │
    │  └──────┬───────┘  └──────┬───────┘  └──────┬──────┘ │
    │         └────────────┬────┘──────────────────┘        │
    │                      ▼                                │
    │              ┌──────────────┐                         │
    │              │   Ranking    │                         │
    │              │   Model      │                         │
    │              └──────┬───────┘                         │
    │                     ▼                                 │
    │            Personalized Rows                          │
    │  ┌─────────────────────────────────────────┐         │
    │  │ "Because you watched Breaking Bad"       │         │
    │  │ [Ozark] [Better Call Saul] [Narcos]     │         │
    │  │                                          │         │
    │  │ "Trending Now"                           │         │
    │  │ [Squid Game] [Wednesday] [...]          │         │
    │  └─────────────────────────────────────────┘         │
    └───────────────────────────────────────────────────────┘
    """
    
    def __init__(self):
        self.content_features: Dict[str, Dict[str, float]] = {}
        # video_id → {genre: weight, ...}
        self.user_profiles: Dict[str, Dict[str, float]] = defaultdict(
            lambda: defaultdict(float)
        )
        # profile_id → {genre: affinity_score, ...}
        self.viewing_matrix: Dict[str, Dict[str, float]] = defaultdict(dict)
        # profile_id → {video_id: rating, ...}
        self.popularity_scores: Dict[str, float] = defaultdict(float)
    
    def index_content(self, video: VideoContent):
        """Index a video's features for content-based filtering"""
        features = {}
        for genre in video.genres:
            features[f"genre:{genre}"] = 1.0
        for actor in video.cast:
            features[f"cast:{actor}"] = 0.5
        features[f"year:{video.release_year // 5 * 5}s"] = 0.3
        features[f"type:{video.content_type.value}"] = 0.4
        
        self.content_features[video.video_id] = features
    
    def record_view(self, profile_id: str, video_id: str, 
                     completion_ratio: float):
        """
        Record that a user watched a video.
        completion_ratio: 0.0 to 1.0 (how much they watched)
        """
        # Implicit rating based on completion
        if completion_ratio > 0.8:
            implicit_rating = 5.0
        elif completion_ratio > 0.5:
            implicit_rating = 4.0
        elif completion_ratio > 0.2:
            implicit_rating = 3.0
        else:
            implicit_rating = 2.0
        
        self.viewing_matrix[profile_id][video_id] = implicit_rating
        self.popularity_scores[video_id] += 1
        
        # Update user profile based on content features
        if video_id in self.content_features:
            for feature, weight in self.content_features[video_id].items():
                self.user_profiles[profile_id][feature] += (
                    weight * implicit_rating * 0.1
                )
    
    def get_recommendations(self, profile_id: str, 
                              num_results: int = 20) -> List[Tuple[str, float, str]]:
        """
        Get personalized recommendations.
        Returns list of (video_id, score, reason).
        """
        candidates = {}
        
        # 1. Content-based filtering
        content_recs = self._content_based_recommendations(profile_id)
        for vid, score in content_recs:
            candidates[vid] = candidates.get(vid, 0) + score * 0.4
        
        # 2. Collaborative filtering
        collab_recs = self._collaborative_filtering(profile_id)
        for vid, score in collab_recs:
            candidates[vid] = candidates.get(vid, 0) + score * 0.4
        
        # 3. Popularity
        for vid, pop_score in self.popularity_scores.items():
            if vid not in self.viewing_matrix.get(profile_id, {}):
                normalized_pop = min(pop_score / 100, 1.0)
                candidates[vid] = candidates.get(vid, 0) + normalized_pop * 0.2
        
        # Remove already watched
        watched = set(self.viewing_matrix.get(profile_id, {}).keys())
        candidates = {k: v for k, v in candidates.items() if k not in watched}
        
        # Sort by score
        ranked = sorted(candidates.items(), key=lambda x: x[1], reverse=True)
        
        results = []
        for vid, score in ranked[:num_results]:
            reason = self._generate_reason(profile_id, vid)
            results.append((vid, score, reason))
        
        return results
    
    def _content_based_recommendations(self, profile_id: str) -> List[Tuple[str, float]]:
        """Find videos similar to what user has watched"""
        user_profile = self.user_profiles.get(profile_id, {})
        if not user_profile:
            return []
        
        scores = []
        for video_id, features in self.content_features.items():
            # Cosine-like similarity between user profile and content features
            similarity = sum(
                user_profile.get(feature, 0) * weight
                for feature, weight in features.items()
            )
            if similarity > 0:
                scores.append((video_id, similarity))
        
        scores.sort(key=lambda x: x[1], reverse=True)
        return scores[:50]
    
    def _collaborative_filtering(self, profile_id: str) -> List[Tuple[str, float]]:
        """Find videos watched by similar users"""
        user_ratings = self.viewing_matrix.get(profile_id, {})
        if not user_ratings:
            return []
        
        # Find similar users (simplified)
        similar_users = []
        for other_id, other_ratings in self.viewing_matrix.items():
            if other_id == profile_id:
                continue
            
            # Calculate similarity (shared ratings)
            common = set(user_ratings.keys()) & set(other_ratings.keys())
            if len(common) < 2:
                continue
            
            # Pearson-like similarity
            similarity = sum(
                user_ratings[vid] * other_ratings[vid] 
                for vid in common
            ) / (len(common) * 25)  # Normalize
            
            similar_users.append((other_id, similarity))
        
        similar_users.sort(key=lambda x: x[1], reverse=True)
        
        # Get recommendations from top similar users
        recommendations = defaultdict(float)
        for other_id, sim_score in similar_users[:10]:
            for vid, rating in self.viewing_matrix[other_id].items():
                if vid not in user_ratings:
                    recommendations[vid] += sim_score * rating
        
        return sorted(recommendations.items(), key=lambda x: x[1], reverse=True)
    
    def _generate_reason(self, profile_id: str, video_id: str) -> str:
        """Generate human-readable recommendation reason"""
        features = self.content_features.get(video_id, {})
        user_profile = self.user_profiles.get(profile_id, {})
        
        best_match_feature = ""
        best_match_score = 0
        
        for feature, weight in features.items():
            user_score = user_profile.get(feature, 0)
            if user_score * weight > best_match_score:
                best_match_score = user_score * weight
                best_match_feature = feature
        
        if best_match_feature.startswith("genre:"):
            genre = best_match_feature.split(":")[1]
            return f"Because you like {genre}"
        elif best_match_feature.startswith("cast:"):
            actor = best_match_feature.split(":")[1]
            return f"Starring {actor}"
        return "Trending Now"


# ============================================================
# 5. SEARCH SERVICE
# ============================================================
class SearchService:
    """
    Full-text search with autocomplete.
    Uses inverted index (like Elasticsearch).
    """
    
    def __init__(self):
        self.inverted_index: Dict[str, Set[str]] = defaultdict(set)
        self.video_data: Dict[str, VideoContent] = {}
        self.trie = {}  # For autocomplete
    
    def index_video(self, video: VideoContent):
        self.video_data[video.video_id] = video
        
        # Index title, description, genres, cast
        tokens = self._tokenize(video.title)
        tokens.extend(self._tokenize(video.description))
        tokens.extend(video.genres)
        tokens.extend(video.cast)
        
        for token in tokens:
            self.inverted_index[token.lower()].add(video.video_id)
            self._add_to_trie(token.lower(), video.video_id)
    
    def search(self, query: str, limit: int = 10) -> List[VideoContent]:
        """Search videos by query"""
        tokens = self._tokenize(query)
        
        if not tokens:
            return []
        
        # Intersection of results for all tokens
        result_sets = [
            self.inverted_index.get(t.lower(), set()) for t in tokens
        ]
        
        if not result_sets:
            return []
        
        common_ids = result_sets[0]
        for s in result_sets[1:]:
            common_ids = common_ids & s
        
        # Rank by relevance (simple: title match > description match)
        results = []
        for vid in common_ids:
            video = self.video_data[vid]
            score = 0
            for token in tokens:
                if token.lower() in video.title.lower():
                    score += 10
                if token.lower() in " ".join(video.genres).lower():
                    score += 5
            results.append((video, score))
        
        results.sort(key=lambda x: x[1], reverse=True)
        return [v for v, _ in results[:limit]]
    
    def autocomplete(self, prefix: str, limit: int = 5) -> List[str]:
        """Get autocomplete suggestions"""
        node = self.trie
        for char in prefix.lower():
            if char not in node:
                return []
            node = node[char]
        
        suggestions = []
        self._collect_words(node, prefix.lower(), suggestions, limit)
        return suggestions
    
    def _tokenize(self, text: str) -> List[str]:
        return [w.strip(".,!?;:") for w in text.split() if len(w) > 2]
    
    def _add_to_trie(self, word: str, video_id: str):
        node = self.trie
        for char in word:
            if char not in node:
                node[char] = {}
            node = node[char]
        node["#"] = node.get("#", set())
        node["#"].add(video_id)
    
    def _collect_words(self, node, prefix, results, limit):
        if len(results) >= limit:
            return
        if "#" in node:
            results.append(prefix)
        for char, child in sorted(node.items()):
            if char != "#":
                self._collect_words(child, prefix + char, results, limit)


# ============================================================
# 6. FULL NETFLIX PLATFORM — ORCHESTRATION
# ============================================================
class NetflixPlatform:
    def __init__(self):
        self.video_pipeline = VideoProcessingPipeline()
        self.cdn = CDNService()
        self.recommendation_engine = RecommendationEngine()
        self.search_service = SearchService()
        self.streaming_service = StreamingService(self.cdn)
        
        # Setup CDN nodes
        for region in ["us-west", "us-east", "eu-west", "ap-south"]:
            for i in range(2):
                node = CDNNode(f"{region}-{i}", region, capacity_gb=100.0)
                self.cdn.add_node(node)
    
    def add_content(self, video: VideoContent):
        """Ingest new content into the platform"""
        # 1. Transcode
        self.video_pipeline.submit_for_processing(video, f"/raw/{video.video_id}")
        
        # 2. Distribute to CDN
        self.cdn.distribute_content(video, "WARM")
        
        # 3. Index for search
        self.search_service.index_video(video)
        
        # 4. Index for recommendations
        self.recommendation_engine.index_content(video)
    
    def play(self, profile_id: str, video_id: str):
        """Simulate playing a video"""
        session = self.streaming_service.start_stream(profile_id, video_id)
        return session


# ============================================================
# SIMULATION
# ============================================================
def simulate_netflix():
    print("=" * 70)
    print("  NETFLIX STREAMING PLATFORM SIMULATION")
    print("=" * 70)
    
    platform = NetflixPlatform()
    
    # Add content catalog
    videos = [
        VideoContent("v1", "Stranger Things S1", "Sci-fi horror series",
                     ContentType.SERIES, 3600, ["Sci-Fi", "Horror", "Drama"],
                     ["Winona Ryder", "Millie Bobby Brown"], 2016, 8.7),
        VideoContent("v2", "Breaking Bad S1", "Chemistry teacher turns criminal",
                     ContentType.SERIES, 3600, ["Crime", "Drama", "Thriller"],
                     ["Bryan Cranston", "Aaron Paul"], 2008, 9.5),
        VideoContent("v3", "The Crown S1", "British royal family drama",
                     ContentType.SERIES, 3600, ["Drama", "History"],
                     ["Claire Foy", "Matt Smith"], 2016, 8.6),
        VideoContent("v4", "Narcos S1", "Drug cartel drama",
                     ContentType.SERIES, 3600, ["Crime", "Drama", "Thriller"],
                     ["Wagner Moura", "Pedro Pascal"], 2015, 8.8),
        VideoContent("v5", "Black Mirror S1", "Dark tech anthology",
                     ContentType.SERIES, 2400, ["Sci-Fi", "Drama", "Thriller"],
                     ["Daniel Kaluuya"], 2011, 8.8),
    ]
    
    print("\n📺 Adding Content Catalog")
    print("-" * 40)
    for video in videos:
        platform.add_content(video)
    
    # Simulate user viewing
    print("\n" + "=" * 40)
    print("👤 USER VIEWING SIMULATION")
    print("=" * 40)
    
    # User watches crime/drama content
    platform.recommendation_engine.record_view("user1", "v2", 0.95)  # Breaking Bad
    platform.recommendation_engine.record_view("user1", "v4", 0.80)  # Narcos
    
    # Another user watches sci-fi
    platform.recommendation_engine.record_view("user2", "v1", 0.90)  # Stranger Things
    platform.recommendation_engine.record_view("user2", "v5", 0.85)  # Black Mirror
    platform.recommendation_engine.record_view("user2", "v2", 0.70)  # Breaking Bad
    
    # Get recommendations for user1
    print("\n🎯 Recommendations for User1 (Crime/Drama fan):")
    recs = platform.recommendation_engine.get_recommendations("user1", 5)
    for vid, score, reason in recs:
        video = platform.search_service.video_data.get(vid)
        if video:
            print(f"  📺 {video.title} (score: {score:.2f}) — {reason}")
    
    # Search test
    print("\n🔍 Search: 'crime drama'")
    results = platform.search_service.search("crime drama")
    for video in results:
        print(f"  → {video.title} ({', '.join(video.genres)})")
    
    # Simulate streaming with bandwidth changes
    print("\n" + "=" * 40)
    print("▶ STREAMING SESSION (Adaptive Bitrate)")
    print("=" * 40)
    
    session = platform.streaming_service.start_stream("user1", "v2", 0)
    
    # Simulate changing bandwidth conditions
    bandwidth_scenarios = [
        (5_000_000, 30.0, "Good bandwidth, normal buffer"),
        (5_000_000, 35.0, "Good bandwidth, building buffer"),
        (8_000_000, 45.0, "Great bandwidth, high buffer"),
        (8_000_000, 50.0, "Great bandwidth, high buffer"),
        (1_000_000, 15.0, "Bandwidth drop!"),
        (800_000, 8.0, "Very low bandwidth!"),
        (500_000, 3.0, "Emergency! Buffer depleting!"),
        (3_000_000, 10.0, "Bandwidth recovering"),
        (5_000_000, 25.0, "Back to normal"),
        (6_000_000, 40.0, "Good conditions"),
    ]
    
    for bw, buffer, description in bandwidth_scenarios:
        print(f"\n  📡 {description}")
        segment = platform.streaming_service.get_next_segment(
            session.session_id, bw, buffer
        )
        if segment:
            print(f"     Serving: {segment['quality']} segment #{segment['segment_number']}"
                  f" from {segment['source']}")
    
    platform.streaming_service.stop_stream(session.session_id)
    platform.cdn.print_cdn_stats()


simulate_netflix()
15. Design Google Drive
System Overview
text

┌──────────────────────────────────────────────────────────────────────────────┐
│                     GOOGLE DRIVE ARCHITECTURE                                │
│                                                                              │
│  ┌────────┐  ┌────────┐  ┌────────┐                                        │
│  │ Web    │  │ Desktop │  │ Mobile │                                        │
│  │ Client │  │  Sync   │  │  App   │                                        │
│  └───┬────┘  └───┬─────┘  └───┬────┘                                        │
│      └───────────┼────────────┘                                             │
│                  ▼                                                           │
│         ┌────────────────┐                                                  │
│         │  API Gateway   │                                                  │
│         │  (Load Bal.)   │                                                  │
│         └───────┬────────┘                                                  │
│                 │                                                            │
│  ┌──────────────┼─────────────────────────────────────────┐                 │
│  │              ▼            SERVICES                      │                 │
│  │ ┌──────────────────┐  ┌──────────────┐  ┌────────────┐ │                 │
│  │ │  Upload/Download │  │   Metadata   │  │  Sharing   │ │                 │
│  │ │    Service       │  │   Service    │  │  Service   │ │                 │
│  │ └────────┬─────────┘  └──────┬───────┘  └──────┬─────┘ │                 │
│  │          │                   │                  │       │                 │
│  │ ┌────────▼─────────┐  ┌─────▼────────┐  ┌─────▼─────┐ │                 │
│  │ │   Block/Chunk    │  │  Versioning  │  │   Sync    │ │                 │
│  │ │    Service       │  │   Service    │  │  Service  │ │                 │
│  │ └────────┬─────────┘  └─────┬────────┘  └─────┬─────┘ │                 │
│  │          │                  │                  │       │                 │
│  │ ┌────────▼─────────┐  ┌────▼────────┐  ┌─────▼─────┐ │                 │
│  │ │  Notification    │  │  Search     │  │  Collab   │ │                 │
│  │ │  Service         │  │  Service    │  │  Service  │ │                 │
│  │ └─────────────────┘  └─────────────┘  └───────────┘ │                 │
│  └──────────────────────────────────────────────────────┘                  │
│                         │                                                    │
│  ┌──────────────────────▼──────────────────────────────────┐                │
│  │                    DATA LAYER                            │                │
│  │  ┌──────────┐  ┌──────────┐  ┌────────┐  ┌───────────┐ │                │
│  │  │ Cloud    │  │ Metadata │  │ Message│  │  Search   │ │                │
│  │  │ Storage  │  │   DB     │  │ Queue  │  │  Index    │ │                │
│  │  │ (GCS/S3) │  │(Spanner/ │  │(Kafka) │  │(Elastic) │ │                │
│  │  │          │  │ MySQL)   │  │        │  │          │ │                │
│  │  └──────────┘  └──────────┘  └────────┘  └───────────┘ │                │
│  └──────────────────────────────────────────────────────────┘                │
└──────────────────────────────────────────────────────────────────────────────┘
File Chunking & Deduplication
text

    FILE CHUNKING STRATEGY
    ══════════════════════
    
    Original File (100 MB):
    ┌──────────────────────────────────────────────────────────┐
    │                    document.pdf (100MB)                   │
    └──────────────────────────────────────────────────────────┘
                              │
                    Split into 4MB chunks
                              │
                              ▼
    ┌──────────┐ ┌──────────┐ ┌──────────┐       ┌──────────┐
    │ Chunk 0  │ │ Chunk 1  │ │ Chunk 2  │  ...  │ Chunk 24 │
    │  4 MB    │ │  4 MB    │ │  4 MB    │       │  4 MB    │
    │ hash:a1b2│ │ hash:c3d4│ │ hash:e5f6│       │ hash:y9z0│
    └──────────┘ └──────────┘ └──────────┘       └──────────┘
    
    DEDUPLICATION:
    ┌─────────────────────────────────────────────────────────┐
    │ User A uploads file with chunks: [a1b2, c3d4, e5f6]   │
    │ User B uploads file with chunks: [a1b2, g7h8, e5f6]   │
    │                                                         │
    │ Storage only stores unique chunks:                      │
    │ [a1b2, c3d4, e5f6, g7h8]  ← 4 chunks, not 6          │
    │                                                         │
    │ Savings: 33% deduplication!                             │
    └─────────────────────────────────────────────────────────┘
    
    DELTA SYNC (File Modified):
    ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐
    │ Chunk 0  │ │ Chunk 1  │ │ Chunk 2  │ │ Chunk 3  │  Version 1
    │  (same)  │ │(MODIFIED)│ │  (same)  │ │  (same)  │
    └──────────┘ └──────────┘ └──────────┘ └──────────┘
         │            │            │            │
         │            ▼            │            │
         │     ┌──────────┐       │            │
         │     │ Chunk 1' │       │            │  Only upload
         │     │ (new)    │       │            │  changed chunk!
         │     └──────────┘       │            │
         │            │            │            │
    ┌────▼───┐ ┌──────▼───┐ ┌────▼───┐ ┌─────▼──┐
    │Chunk 0 │ │ Chunk 1' │ │Chunk 2 │ │Chunk 3 │  Version 2
    └────────┘ └──────────┘ └────────┘ └────────┘
Python Implementation
Python

import os
import hashlib
import time
import uuid
import threading
from enum import Enum
from dataclasses import dataclass, field
from typing import Dict, List, Optional, Set, Tuple
from collections import defaultdict


# ============================================================
# DATA MODELS
# ============================================================
class FileType(Enum):
    FILE = "file"
    FOLDER = "folder"


class Permission(Enum):
    OWNER = "owner"
    EDITOR = "editor"
    VIEWER = "viewer"


@dataclass
class FileChunk:
    chunk_hash: str         # SHA-256 hash of chunk data
    chunk_index: int        # Position in file
    size_bytes: int
    storage_path: str       # Path in cloud storage
    ref_count: int = 1      # Number of files referencing this chunk


@dataclass
class FileVersion:
    version_id: str
    version_number: int
    chunk_hashes: List[str]     # Ordered list of chunk hashes
    file_size: int
    created_at: float
    created_by: str
    change_description: str = ""


@dataclass
class FileMetadata:
    file_id: str
    name: str
    file_type: FileType
    parent_id: Optional[str]    # Parent folder ID
    owner_id: str
    current_version: int
    versions: List[FileVersion] = field(default_factory=list)
    permissions: Dict[str, Permission] = field(default_factory=dict)
    created_at: float = field(default_factory=time.time)
    modified_at: float = field(default_factory=time.time)
    is_deleted: bool = False
    mime_type: str = "application/octet-stream"


@dataclass 
class UserStorage:
    user_id: str
    total_quota_bytes: int = 15 * 1024 * 1024 * 1024  # 15 GB
    used_bytes: int = 0
    root_folder_id: str = ""


# ============================================================
# 1. BLOCK/CHUNK SERVICE
# ============================================================
class BlockService:
    """
    Handles file chunking, deduplication, and storage.
    
    ┌────────────┐     ┌──────────────┐     ┌──────────────┐
    │   Client   │────▶│   Block      │────▶│   Cloud      │
    │   Upload   │     │   Service    │     │   Storage    │
    │            │◀────│   (chunk,    │◀────│   (S3/GCS)   │
    │            │     │    dedup)    │     │              │
    └────────────┘     └──────────────┘     └──────────────┘
    """
    
    CHUNK_SIZE = 4 * 1024 * 1024  # 4 MB chunks
    
    def __init__(self):
        # Global chunk store (simulates cloud storage)
        self.chunk_store: Dict[str, bytes] = {}
        # Chunk metadata
        self.chunk_metadata: Dict[str, FileChunk] = {}
        # Dedup index: hash → bool (exists in store)
        self.dedup_index: Set[str] = set()
        self.lock = threading.Lock()
        self._stats = {"uploads": 0, "deduped": 0, "bytes_saved": 0}
    
    def chunk_file(self, file_data: bytes) -> List[Tuple[str, bytes]]:
        """
        Split file into chunks and compute hashes.
        Returns list of (chunk_hash, chunk_data).
        
        Uses content-defined chunking for better dedup
        (simplified to fixed-size here).
        """
        chunks = []
        offset = 0
        
        while offset < len(file_data):
            chunk_data = file_data[offset:offset + self.CHUNK_SIZE]
            chunk_hash = hashlib.sha256(chunk_data).hexdigest()
            chunks.append((chunk_hash, chunk_data))
            offset += self.CHUNK_SIZE
        
        return chunks
    
    def upload_chunks(self, chunks: List[Tuple[str, bytes]], 
                       file_id: str) -> List[str]:
        """
        Upload chunks with deduplication.
        Only stores chunks not already in the store.
        """
        chunk_hashes = []
        
        with self.lock:
            for idx, (chunk_hash, chunk_data) in enumerate(chunks):
                self._stats["uploads"] += 1
                
                if chunk_hash in self.dedup_index:
                    # Chunk already exists — just increment ref count
                    self.chunk_metadata[chunk_hash].ref_count += 1
                    self._stats["deduped"] += 1
                    self._stats["bytes_saved"] += len(chunk_data)
                    print(f"    ♻️  Chunk {idx}: DEDUPED (hash={chunk_hash[:12]}...)")
                else:
                    # New chunk — store it
                    storage_path = f"/storage/chunks/{chunk_hash[:2]}/{chunk_hash}"
                    self.chunk_store[chunk_hash] = chunk_data
                    self.chunk_metadata[chunk_hash] = FileChunk(
                        chunk_hash=chunk_hash,
                        chunk_index=idx,
                        size_bytes=len(chunk_data),
                        storage_path=storage_path,
                    )
                    self.dedup_index.add(chunk_hash)
                    print(f"    📦 Chunk {idx}: STORED ({len(chunk_data)} bytes, "
                          f"hash={chunk_hash[:12]}...)")
                
                chunk_hashes.append(chunk_hash)
        
        return chunk_hashes
    
    def download_chunks(self, chunk_hashes: List[str]) -> bytes:
        """Reassemble file from chunks"""
        file_data = b""
        for chunk_hash in chunk_hashes:
            if chunk_hash in self.chunk_store:
                file_data += self.chunk_store[chunk_hash]
            else:
                raise FileNotFoundError(f"Chunk {chunk_hash} not found")
        return file_data
    
    def compute_delta(self, old_hashes: List[str], 
                       new_chunks: List[Tuple[str, bytes]]) -> List[int]:
        """
        Find which chunks changed between versions.
        Returns indices of changed chunks.
        
        ┌────────┬────────┬────────┬────────┐
        │ C0     │ C1     │ C2     │ C3     │ Old version
        │ hash:aa│ hash:bb│ hash:cc│ hash:dd│
        └────────┴────────┴────────┴────────┘
                      │ changed
                      ▼
        ┌────────┬────────┬────────┬────────┐
        │ C0     │ C1'    │ C2     │ C3     │ New version
        │ hash:aa│ hash:ee│ hash:cc│ hash:dd│
        └────────┴────────┴────────┴────────┘
        
        Delta = [1]  (only chunk 1 changed)
        """
        new_hashes = [h for h, _ in new_chunks]
        changed = []
        
        for i in range(max(len(old_hashes), len(new_hashes))):
            old_h = old_hashes[i] if i < len(old_hashes) else None
            new_h = new_hashes[i] if i < len(new_hashes) else None
            
            if old_h != new_h:
                changed.append(i)
        
        return changed
    
    def delete_chunks(self, chunk_hashes: List[str]):
        """Decrement ref count, delete if zero"""
        with self.lock:
            for chunk_hash in chunk_hashes:
                if chunk_hash in self.chunk_metadata:
                    meta = self.chunk_metadata[chunk_hash]
                    meta.ref_count -= 1
                    if meta.ref_count <= 0:
                        del self.chunk_store[chunk_hash]
                        del self.chunk_metadata[chunk_hash]
                        self.dedup_index.discard(chunk_hash)
    
    def print_stats(self):
        total = self._stats["uploads"]
        deduped = self._stats["deduped"]
        saved = self._stats["bytes_saved"]
        print(f"\n📊 Block Service Stats:")
        print(f"  Total chunks processed: {total}")
        print(f"  Deduplicated: {deduped} ({deduped/total*100:.1f}%)" if total else "")
        print(f"  Storage saved: {saved / (1024*1024):.2f} MB")
        print(f"  Unique chunks stored: {len(self.chunk_store)}")


# ============================================================
# 2. METADATA SERVICE
# ============================================================
class MetadataService:
    """
    Manages file/folder hierarchy, permissions, and versions.
    
    Directory Tree:
    ┌── root (user123)
    │   ├── Documents/
    │   │   ├── resume.pdf  (v3)
    │   │   └── notes.txt   (v1)
    │   ├── Photos/
    │   │   ├── vacation/
    │   │   │   └── beach.jpg
    │   │   └── profile.png
    │   └── shared_with_me/
    """
    
    def __init__(self):
        self.files: Dict[str, FileMetadata] = {}
        self.user_storage: Dict[str, UserStorage] = {}
        # Index: parent_id → list of child file_ids
        self.children_index: Dict[str, List[str]] = defaultdict(list)
        # Index: user_id → list of shared file_ids
        self.shared_with_user: Dict[str, List[str]] = defaultdict(list)
    
    def create_user_storage(self, user_id: str) -> UserStorage:
        """Initialize storage for a new user"""
        root_folder = self.create_file(
            name="My Drive",
            file_type=FileType.FOLDER,
            parent_id=None,
            owner_id=user_id,
        )
        
        storage = UserStorage(
            user_id=user_id,
            root_folder_id=root_folder.file_id,
        )
        self.user_storage[user_id] = storage
        return storage
    
    def create_file(self, name: str, file_type: FileType,
                     parent_id: Optional[str], owner_id: str,
                     chunk_hashes: List[str] = None,
                     file_size: int = 0) -> FileMetadata:
        """Create a new file or folder"""
        file_id = str(uuid.uuid4())
        
        metadata = FileMetadata(
            file_id=file_id,
            name=name,
            file_type=file_type,
            parent_id=parent_id,
            owner_id=owner_id,
            current_version=1 if file_type == FileType.FILE else 0,
            permissions={owner_id: Permission.OWNER},
        )
        
        if file_type == FileType.FILE and chunk_hashes:
            version = FileVersion(
                version_id=str(uuid.uuid4()),
                version_number=1,
                chunk_hashes=chunk_hashes,
                file_size=file_size,
                created_at=time.time(),
                created_by=owner_id,
                change_description="Initial upload",
            )
            metadata.versions.append(version)
        
        self.files[file_id] = metadata
        
        if parent_id:
            self.children_index[parent_id].append(file_id)
        
        # Update storage usage
        if owner_id in self.user_storage:
            self.user_storage[owner_id].used_bytes += file_size
        
        return metadata
    
    def update_file(self, file_id: str, new_chunk_hashes: List[str],
                     new_size: int, user_id: str, 
                     description: str = "") -> FileVersion:
        """Create a new version of a file"""
        metadata = self.files.get(file_id)
        if not metadata:
            raise FileNotFoundError(f"File {file_id} not found")
        
        # Check permission
        if not self._has_permission(file_id, user_id, Permission.EDITOR):
            raise PermissionError("No edit permission")
        
        new_version_num = metadata.current_version + 1
        
        version = FileVersion(
            version_id=str(uuid.uuid4()),
            version_number=new_version_num,
            chunk_hashes=new_chunk_hashes,
            file_size=new_size,
            created_at=time.time(),
            created_by=user_id,
            change_description=description,
        )
        
        # Keep last 100 versions
        metadata.versions.append(version)
        if len(metadata.versions) > 100:
            metadata.versions = metadata.versions[-100:]
        
        metadata.current_version = new_version_num
        metadata.modified_at = time.time()
        
        # Update storage usage
        old_size = metadata.versions[-2].file_size if len(metadata.versions) > 1 else 0
        if metadata.owner_id in self.user_storage:
            self.user_storage[metadata.owner_id].used_bytes += (new_size - old_size)
        
        return version
    
    def get_file(self, file_id: str, user_id: str) -> Optional[FileMetadata]:
        """Get file metadata (with permission check)"""
        metadata = self.files.get(file_id)
        if not metadata or metadata.is_deleted:
            return None
        if not self._has_permission(file_id, user_id, Permission.VIEWER):
            raise PermissionError("No access")
        return metadata
    
    def list_folder(self, folder_id: str, 
                     user_id: str) -> List[FileMetadata]:
        """List contents of a folder"""
        children_ids = self.children_index.get(folder_id, [])
        result = []
        for fid in children_ids:
            f = self.files.get(fid)
            if f and not f.is_deleted:
                if self._has_permission(fid, user_id, Permission.VIEWER):
                    result.append(f)
        return result
    
    def share_file(self, file_id: str, owner_id: str,
                    target_user_id: str, permission: Permission):
        """Share a file/folder with another user"""
        metadata = self.files.get(file_id)
        if not metadata:
            raise FileNotFoundError()
        
        if metadata.permissions.get(owner_id) != Permission.OWNER:
            raise PermissionError("Only owner can share")
        
        metadata.permissions[target_user_id] = permission
        self.shared_with_user[target_user_id].append(file_id)
        
        print(f"  🔗 Shared '{metadata.name}' with {target_user_id} "
              f"as {permission.value}")
    
    def move_file(self, file_id: str, new_parent_id: str, user_id: str):
        """Move file to a different folder"""
        metadata = self.files.get(file_id)
        if not metadata:
            raise FileNotFoundError()
        
        if not self._has_permission(file_id, user_id, Permission.EDITOR):
            raise PermissionError()
        
        # Remove from old parent
        if metadata.parent_id:
            self.children_index[metadata.parent_id].remove(file_id)
        
        # Add to new parent
        metadata.parent_id = new_parent_id
        self.children_index[new_parent_id].append(file_id)
    
    def delete_file(self, file_id: str, user_id: str):
        """Soft delete (move to trash)"""
        metadata = self.files.get(file_id)
        if metadata and self._has_permission(file_id, user_id, Permission.OWNER):
            metadata.is_deleted = True
            metadata.modified_at = time.time()
    
    def get_version_history(self, file_id: str) -> List[FileVersion]:
        metadata = self.files.get(file_id)
        if metadata:
            return metadata.versions
        return []
    
    def _has_permission(self, file_id: str, user_id: str, 
                         required: Permission) -> bool:
        metadata = self.files.get(file_id)
        if not metadata:
            return False
        
        user_perm = metadata.permissions.get(user_id)
        if not user_perm:
            return False
        
        hierarchy = {Permission.OWNER: 3, Permission.EDITOR: 2, Permission.VIEWER: 1}
        return hierarchy.get(user_perm, 0) >= hierarchy.get(required, 0)
    
    def get_path(self, file_id: str) -> str:
        """Get full path of a file"""
        parts = []
        current = self.files.get(file_id)
        while current:
            parts.append(current.name)
            current = self.files.get(current.parent_id) if current.parent_id else None
        parts.reverse()
        return "/" + "/".join(parts)


# ============================================================
# 3. SYNC SERVICE
# ============================================================
class SyncService:
    """
    Keeps files synchronized across multiple devices.
    
    Sync Strategy:
    ┌────────────────────────────────────────────────────────────┐
    │                                                            │
    │  Device A         Server          Device B                │
    │  ────────        ────────        ────────                 │
    │  Edit file ─────▶ Store    ─────▶ Notify                 │
    │                   new ver         & pull                  │
    │                                                            │
    │  CONFLICT RESOLUTION:                                     │
    │  If both devices edit simultaneously:                     │
    │    Option 1: Last-write-wins (simple)                     │
    │    Option 2: Create conflict copy                         │
    │    Option 3: Operational Transform (Google Docs)          │
    │                                                            │
    └────────────────────────────────────────────────────────────┘
    """
    
    def __init__(self, metadata_service: MetadataService):
        self.metadata_service = metadata_service
        # Track sync state per device
        # device_id → {file_id: last_synced_version}
        self.device_sync_state: Dict[str, Dict[str, int]] = defaultdict(dict)
        # Change log for efficient sync
        self.change_log: List[dict] = []
        self.change_log_lock = threading.Lock()
    
    def register_device(self, device_id: str, user_id: str):
        """Register a new device for sync"""
        self.device_sync_state[device_id] = {}
        print(f"  📱 Device {device_id[:8]} registered for user {user_id}")
    
    def record_change(self, file_id: str, version: int, 
                       change_type: str, user_id: str):
        """Record a change for sync propagation"""
        with self.change_log_lock:
            self.change_log.append({
                "file_id": file_id,
                "version": version,
                "change_type": change_type,  # "CREATE", "UPDATE", "DELETE"
                "user_id": user_id,
                "timestamp": time.time(),
                "sequence_id": len(self.change_log),
            })
    
    def get_changes_for_device(self, device_id: str, 
                                 user_id: str) -> List[dict]:
        """
        Get list of changes a device needs to sync.
        
        ┌─────────────────────────────────────────────┐
        │ Change Log:                                  │
        │ seq=1: file_A created    ← already synced   │
        │ seq=2: file_B updated    ← already synced   │
        │ seq=3: file_A updated    ← NEED TO SYNC     │
        │ seq=4: file_C created    ← NEED TO SYNC     │
        │                                              │
        │ Device last synced at seq=2                  │
        │ → Return changes [seq=3, seq=4]              │
        └─────────────────────────────────────────────┘
        """
        device_state = self.device_sync_state.get(device_id, {})
        pending_changes = []
        
        for change in self.change_log:
            file_id = change["file_id"]
            version = change["version"]
            
            synced_version = device_state.get(file_id, 0)
            if version > synced_version:
                pending_changes.append(change)
        
        return pending_changes
    
    def acknowledge_sync(self, device_id: str, file_id: str, version: int):
        """Mark a file version as synced on a device"""
        self.device_sync_state[device_id][file_id] = version
    
    def detect_conflict(self, file_id: str, base_version: int,
                         device_id: str) -> bool:
        """
        Detect if there's a conflict.
        Conflict = server version > base version the client edited from.
        """
        metadata = self.metadata_service.files.get(file_id)
        if not metadata:
            return False
        
        return metadata.current_version > base_version
    
    def resolve_conflict(self, file_id: str, 
                          local_chunks: List[str],
                          device_id: str,
                          user_id: str,
                          strategy: str = "create_copy") -> str:
        """
        Resolve sync conflict.
        
        Strategies:
        1. "last_write_wins" - Server version wins
        2. "create_copy" - Create "file (conflict copy)" 
        3. "merge" - For text files, attempt 3-way merge
        """
        metadata = self.metadata_service.files.get(file_id)
        
        if strategy == "create_copy":
            conflict_name = f"{metadata.name} (conflict copy - {device_id[:8]})"
            conflict_file = self.metadata_service.create_file(
                name=conflict_name,
                file_type=FileType.FILE,
                parent_id=metadata.parent_id,
                owner_id=user_id,
                chunk_hashes=local_chunks,
                file_size=0,
            )
            print(f"  ⚠️  Conflict resolved: Created '{conflict_name}'")
            return conflict_file.file_id
        
        elif strategy == "last_write_wins":
            print(f"  ⚠️  Conflict resolved: Server version kept")
            return file_id
        
        return file_id


# ============================================================
# 4. NOTIFICATION SERVICE
# ============================================================
class DriveNotificationService:
    """
    Real-time notifications for file changes.
    
    ┌──────────┐     ┌─────────┐     ┌────────────────┐
    │  Change  │────▶│  Kafka  │────▶│  Notification  │
    │  Event   │     │  Topic  │     │  Workers       │
    └──────────┘     └─────────┘     └───────┬────────┘
                                             │
                                    ┌────────┴────────┐
                                    │                 │
                              ┌─────▼─────┐    ┌─────▼──────┐
                              │ WebSocket │    │   Push     │
                              │ (desktop  │    │ (mobile    │
                              │  client)  │    │  client)   │
                              └───────────┘    └────────────┘
    """
    
    def __init__(self):
        self.subscribers: Dict[str, List[str]] = defaultdict(list)
        # file_id → list of user_ids watching
        self.notification_queue: List[dict] = []
    
    def subscribe(self, user_id: str, file_id: str):
        self.subscribers[file_id].append(user_id)
    
    def notify_change(self, file_id: str, change_type: str, 
                       changed_by: str, file_name: str):
        """Notify all subscribers of a file change"""
        for user_id in self.subscribers.get(file_id, []):
            if user_id != changed_by:
                notification = {
                    "user_id": user_id,
                    "message": f"{changed_by} {change_type}d '{file_name}'",
                    "file_id": file_id,
                    "timestamp": time.time(),
                }
                self.notification_queue.append(notification)
                print(f"  🔔 Notified {user_id}: {notification['message']}")


# ============================================================
# 5. GOOGLE DRIVE PLATFORM — Full Integration
# ============================================================
class GoogleDrivePlatform:
    """
    Complete Google Drive system integrating all services.
    """
    
    def __init__(self):
        self.block_service = BlockService()
        self.metadata_service = MetadataService()
        self.sync_service = SyncService(self.metadata_service)
        self.notification_service = DriveNotificationService()
    
    def create_user(self, user_id: str) -> UserStorage:
        """Initialize a new user's drive"""
        storage = self.metadata_service.create_user_storage(user_id)
        print(f"\n👤 Created Google Drive for user {user_id}")
        print(f"   Quota: {storage.total_quota_bytes / (1024**3):.0f} GB")
        return storage
    
    def create_folder(self, name: str, parent_id: str, 
                       user_id: str) -> FileMetadata:
        """Create a new folder"""
        folder = self.metadata_service.create_file(
            name=name,
            file_type=FileType.FOLDER,
            parent_id=parent_id,
            owner_id=user_id,
        )
        print(f"  📁 Created folder: {self.metadata_service.get_path(folder.file_id)}")
        return folder
    
    def upload_file(self, name: str, file_data: bytes,
                     parent_id: str, user_id: str) -> FileMetadata:
        """
        Upload a file:
        1. Chunk the file
        2. Deduplicate chunks
        3. Store unique chunks
        4. Create metadata
        """
        print(f"\n  📤 Uploading '{name}' ({len(file_data)} bytes)")
        
        # Check quota
        storage = self.metadata_service.user_storage.get(user_id)
        if storage and storage.used_bytes + len(file_data) > storage.total_quota_bytes:
            raise Exception("Storage quota exceeded!")
        
        # 1. Chunk the file
        chunks = self.block_service.chunk_file(file_data)
        print(f"    Split into {len(chunks)} chunks")
        
        # 2. Upload chunks (with deduplication)
        chunk_hashes = self.block_service.upload_chunks(chunks, "")
        
        # 3. Create metadata
        file_meta = self.metadata_service.create_file(
            name=name,
            file_type=FileType.FILE,
            parent_id=parent_id,
            owner_id=user_id,
            chunk_hashes=chunk_hashes,
            file_size=len(file_data),
        )
        
        # 4. Record change for sync
        self.sync_service.record_change(
            file_meta.file_id, 1, "CREATE", user_id
        )
        
        path = self.metadata_service.get_path(file_meta.file_id)
        print(f"    ✅ Upload complete: {path} (v1)")
        
        return file_meta
    
    def update_file(self, file_id: str, new_data: bytes,
                     user_id: str, description: str = "") -> FileVersion:
        """
        Update a file (delta sync):
        1. Chunk new data
        2. Compare with old chunks
        3. Upload only changed chunks
        4. Create new version
        """
        metadata = self.metadata_service.files.get(file_id)
        if not metadata:
            raise FileNotFoundError()
        
        print(f"\n  ✏️  Updating '{metadata.name}'")
        
        # Get old chunk hashes
        old_version = metadata.versions[-1] if metadata.versions else None
        old_hashes = old_version.chunk_hashes if old_version else []
        
        # Chunk new data
        new_chunks = self.block_service.chunk_file(new_data)
        
        # Find changed chunks
        changed_indices = self.block_service.compute_delta(old_hashes, new_chunks)
        print(f"    Delta: {len(changed_indices)}/{len(new_chunks)} chunks changed")
        
        # Upload all chunks (dedup handles the rest)
        chunk_hashes = self.block_service.upload_chunks(new_chunks, file_id)
        
        # Create new version
        version = self.metadata_service.update_file(
            file_id, chunk_hashes, len(new_data), user_id, description
        )
        
        # Record change for sync
        self.sync_service.record_change(
            file_id, version.version_number, "UPDATE", user_id
        )
        
        # Notify collaborators
        self.notification_service.notify_change(
            file_id, "update", user_id, metadata.name
        )
        
        print(f"    ✅ Updated to v{version.version_number}")
        return version
    
    def download_file(self, file_id: str, user_id: str,
                       version: int = None) -> bytes:
        """Download a file (optionally a specific version)"""
        metadata = self.metadata_service.get_file(file_id, user_id)
        if not metadata:
            raise FileNotFoundError()
        
        if version:
            file_version = next(
                (v for v in metadata.versions if v.version_number == version),
                None
            )
        else:
            file_version = metadata.versions[-1] if metadata.versions else None
        
        if not file_version:
            raise FileNotFoundError("Version not found")
        
        data = self.block_service.download_chunks(file_version.chunk_hashes)
        print(f"  📥 Downloaded '{metadata.name}' v{file_version.version_number} "
              f"({len(data)} bytes)")
        return data
    
    def share(self, file_id: str, owner_id: str, 
              target_user: str, permission: Permission):
        """Share a file with another user"""
        self.metadata_service.share_file(file_id, owner_id, target_user, permission)
    
    def list_folder(self, folder_id: str, user_id: str):
        """List folder contents with formatting"""
        contents = self.metadata_service.list_folder(folder_id, user_id)
        
        folder = self.metadata_service.files.get(folder_id)
        folder_name = folder.name if folder else "Unknown"
        
        print(f"\n  📂 Contents of '{folder_name}':")
        for item in contents:
            if item.file_type == FileType.FOLDER:
                print(f"    📁 {item.name}/")
            else:
                size = item.versions[-1].file_size if item.versions else 0
                ver = item.current_version
                print(f"    📄 {item.name} ({size} bytes, v{ver})")
        
        if not contents:
            print(f"    (empty)")
        
        return contents
    
    def get_version_history(self, file_id: str):
        """Show version history"""
        versions = self.metadata_service.get_version_history(file_id)
        metadata = self.metadata_service.files.get(file_id)
        
        print(f"\n  📋 Version History for '{metadata.name}':")
        for v in versions:
            print(f"    v{v.version_number}: {v.file_size} bytes | "
                  f"by {v.created_by} | {v.change_description or 'No description'}")


# ============================================================
# SIMULATION
# ============================================================
def simulate_google_drive():
    print("=" * 70)
    print("  GOOGLE DRIVE SIMULATION")
    print("=" * 70)
    
    drive = GoogleDrivePlatform()
    
    # Create users
    alice_storage = drive.create_user("alice")
    bob_storage = drive.create_user("bob")
    
    alice_root = alice_storage.root_folder_id
    
    # Create folder structure
    docs_folder = drive.create_folder("Documents", alice_root, "alice")
    photos_folder = drive.create_folder("Photos", alice_root, "alice")
    work_folder = drive.create_folder("Work", docs_folder.file_id, "alice")
    
    # Upload files
    print("\n" + "=" * 40)
    print("📤 FILE UPLOADS")
    print("=" * 40)
    
    # Create sample file data
    report_data = b"Annual Report 2024\n" + b"X" * (4 * 1024 * 1024 + 100)  # ~4MB
    report = drive.upload_file("report.pdf", report_data, 
                                work_folder.file_id, "alice")
    
    # Upload a similar file (to test deduplication)
    print("\n--- Testing Deduplication ---")
    similar_data = b"Annual Report 2024\n" + b"X" * (4 * 1024 * 1024 + 100)  # Same!
    similar = drive.upload_file("report_copy.pdf", similar_data,
                                 work_folder.file_id, "alice")
    
    # Update file (test delta sync)
    print("\n" + "=" * 40)
    print("✏️  FILE UPDATE (Delta Sync)")
    print("=" * 40)
    
    # Modify only part of the file
    updated_data = b"Annual Report 2024 - UPDATED\n" + b"X" * (4 * 1024 * 1024 + 100)
    drive.update_file(report.file_id, updated_data, "alice", "Updated header")
    
    # Second update
    updated_data2 = b"Annual Report 2024 - FINAL\n" + b"X" * (4 * 1024 * 1024 + 100)
    drive.update_file(report.file_id, updated_data2, "alice", "Final version")
    
    # Version history
    drive.get_version_history(report.file_id)
    
    # Share file
    print("\n" + "=" * 40)
    print("🔗 FILE SHARING")
    print("=" * 40)
    drive.share(report.file_id, "alice", "bob", Permission.EDITOR)
    
    # Bob downloads the file
    downloaded = drive.download_file(report.file_id, "bob")
    
    # Download specific version
    downloaded_v1 = drive.download_file(report.file_id, "alice", version=1)
    
    # List folder contents
    print("\n" + "=" * 40)
    print("📂 FOLDER LISTING")
    print("=" * 40)
    drive.list_folder(alice_root, "alice")
    drive.list_folder(work_folder.file_id, "alice")
    
    # Storage stats
    drive.block_service.print_stats()
    
    alice_used = drive.metadata_service.user_storage["alice"].used_bytes
    alice_quota = drive.metadata_service.user_storage["alice"].total_quota_bytes
    print(f"\n  💾 Alice's Storage: {alice_used/(1024*1024):.2f} MB / "
          f"{alice_quota/(1024**3):.0f} GB used")


simulate_google_drive()




# Designing Dropbox — A Complete High-Level System Design

---

## Table of Contents
1. [Requirements](#1-requirements)
2. [Capacity Estimation](#2-capacity)
3. [High-Level Architecture](#3-hla)
4. [Core Components Deep Dive](#4-components)
5. [Chunking & Deduplication](#5-chunking)
6. [Metadata Service](#6-metadata)
7. [Sync Protocol](#7-sync)
8. [Notification Service](#8-notification)
9. [Conflict Resolution](#9-conflict)
10. [API Design](#10-api)
11. [Data Models](#11-data-models)
12. [Security](#12-security)
13. [Python Examples (End-to-End)](#13-python)
14. [Failure Handling & Reliability](#14-failures)
15. [Final Architecture Diagram](#15-final)

---

## 1. Requirements <a name="1-requirements"></a>

### Functional Requirements
```
✅ Upload files (small & large, up to several GB)
✅ Download files
✅ Automatic sync across multiple devices
✅ File versioning (keep history)
✅ Share files/folders with other users
✅ Offline editing with later sync
✅ Notifications on file changes (real-time)
✅ Support for all file types
```

### Non-Functional Requirements
```
✅ High reliability — never lose user data
✅ High availability — accessible 99.9%+ uptime
✅ Low latency sync — near real-time
✅ Bandwidth efficiency — transfer only changes
✅ Scalability — support 500M+ users
✅ Consistency — eventual consistency is acceptable, 
   but metadata must be strongly consistent
```

### Out of Scope
```
❌ In-browser document editing (Google Docs style)
❌ Full-text search inside documents
❌ Media streaming
```

---

## 2. Capacity Estimation <a name="2-capacity"></a>

```
Total users:          500 Million
Daily active users:   100 Million
Avg files per user:   200
Avg file size:        500 KB (mixed: docs, images, videos)
Total files:          100 Billion files
Total storage:        100B × 500KB = 50 PB (petabytes)

Upload requests/day:  ~2 Billion (100M × ~20 file ops/day)
Upload QPS:           ~23,000 req/sec
Peak QPS:             ~50,000 req/sec

Read:Write ratio:     ~2:1
Bandwidth (upload):   ~23,000 × 500KB = ~11.5 GB/s
```

---

## 3. High-Level Architecture <a name="3-hla"></a>

```
┌──────────────────────────────────────────────────────────────────────┐
│                          CLIENTS                                      │
│   ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐            │
│   │ Desktop  │  │  Mobile  │  │   Web    │  │   API    │            │
│   │  Client  │  │  Client  │  │  Client  │  │ Client   │            │
│   └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘            │
│        │              │              │              │                  │
│   ┌────┴──────────────┴──────────────┴──────────────┴─────┐          │
│   │              LOCAL SYNC ENGINE                         │          │
│   │  ┌──────────┐ ┌───────────┐ ┌──────────┐ ┌─────────┐ │          │
│   │  │ Watcher  │ │ Chunker   │ │ Indexer  │ │Internal │ │          │
│   │  │ (inotify)│ │(4MB blocks│ │ (local   │ │  DB     │ │          │
│   │  │          │ │ + hashing)│ │  state)  │ │(SQLite) │ │          │
│   │  └──────────┘ └───────────┘ └──────────┘ └─────────┘ │          │
│   └───────────────────────┬───────────────────────────────┘          │
└───────────────────────────┼──────────────────────────────────────────┘
                            │ HTTPS / WebSocket
                            ▼
┌───────────────────────────────────────────────────────────────────────┐
│                       LOAD BALANCER (L7)                              │
│                    (Nginx / AWS ALB / HAProxy)                        │
└───────────────────────────┬───────────────────────────────────────────┘
                            │
          ┌─────────────────┼─────────────────┐
          ▼                 ▼                 ▼
┌──────────────┐  ┌──────────────┐  ┌──────────────────┐
│   API        │  │  Block       │  │  Notification    │
│   Gateway    │  │  Server      │  │  Service         │
│  (Auth,Rate  │  │  (Upload/    │  │  (WebSocket/     │
│   Limit,     │  │  Download    │  │   Long Poll/     │
│   Routing)   │  │  Chunks)     │  │   SSE)           │
└──────┬───────┘  └──────┬───────┘  └────────┬─────────┘
       │                 │                    │
       ▼                 ▼                    │
┌──────────────┐  ┌──────────────┐            │
│  Metadata    │  │  Cloud       │            │
│  Service     │  │  Storage     │            │
│              │  │  (S3/GCS/    │            │
│  ┌────────┐  │  │   HDFS)      │            │
│  │MetadataDB│ │  └──────────────┘            │
│  │(MySQL/  │ │                               │
│  │ Postgres│ │  ┌──────────────┐            │
│  └────────┘  │  │  Message     │◄───────────┘
│  ┌────────┐  │  │  Queue       │
│  │ Cache   │ │  │  (Kafka/     │
│  │(Redis)  │ │  │   RabbitMQ)  │
│  └────────┘  │  └──────────────┘
└──────────────┘
```

---

## 4. Core Components Deep Dive <a name="4-components"></a>

### 4.1 Client Application

The desktop client is the **heart** of Dropbox. It has four internal components:

```
┌─────────────────────────────────────────────────┐
│                 CLIENT APPLICATION               │
│                                                  │
│  ┌───────────┐    Detects file changes           │
│  │  WATCHER  │    (inotify on Linux,             │
│  │           │     FSEvents on macOS,            │
│  │           │     ReadDirectoryChanges on Win)  │
│  └─────┬─────┘                                   │
│        │ file changed event                      │
│        ▼                                         │
│  ┌───────────┐    Breaks file into 4MB chunks    │
│  │  CHUNKER  │    Computes SHA-256 hash per chunk│
│  │           │    Enables deduplication           │
│  └─────┬─────┘                                   │
│        │ chunk list + hashes                     │
│        ▼                                         │
│  ┌───────────┐    Compares local state with      │
│  │  INDEXER  │    server state. Decides which    │
│  │           │    chunks need upload/download     │
│  └─────┬─────┘                                   │
│        │ sync operations                         │
│        ▼                                         │
│  ┌───────────┐    Stores local metadata          │
│  │ LOCAL DB  │    (file paths, chunk hashes,     │
│  │ (SQLite)  │    versions, sync state)          │
│  └───────────┘                                   │
└─────────────────────────────────────────────────┘
```

### 4.2 Block Server (Chunk Server)

```
Responsibilities:
├── Accept chunk uploads from clients
├── Validate chunk integrity (SHA-256)
├── Store chunks in cloud storage (S3)
├── Serve chunk downloads
├── Support resumable uploads
└── Compress chunks before storage (LZ4/zstd)
```

### 4.3 Metadata Service

```
Responsibilities:
├── Manage file/folder hierarchy
├── Track file versions
├── Track chunk-to-file mappings
├── User workspace management
├── Sharing permissions
└── Sync state management
```

### 4.4 Notification Service

```
Responsibilities:
├── Notify clients of remote changes
├── WebSocket for online clients
├── Long polling fallback
└── Works with message queue (Kafka)
```

---

## 5. Chunking & Deduplication <a name="5-chunking"></a>

### Why Chunking?

```
Without Chunking:
  1GB file → 1 byte changed → re-upload entire 1GB ❌

With Chunking (4MB blocks):
  1GB file → 256 chunks → 1 byte changed → re-upload 1 chunk (4MB) ✅
  Savings: 99.6% bandwidth reduction!
```

### Fixed vs Content-Defined Chunking

```
┌─────────────────────────────────────────────────────────┐
│ FIXED-SIZE CHUNKING                                      │
│ ┌──────┬──────┬──────┬──────┬──────┬──────┐             │
│ │ 4MB  │ 4MB  │ 4MB  │ 4MB  │ 4MB  │ 2MB │             │
│ └──────┴──────┴──────┴──────┴──────┴──────┘             │
│ Simple but: inserting 1 byte at start shifts ALL chunks  │
│ → ALL chunks appear changed → all re-uploaded            │
│                                                          │
│ CONTENT-DEFINED CHUNKING (Rabin Fingerprinting)          │
│ ┌─────┬───────┬────┬────────┬─────┬──────┐              │
│ │3.5MB│ 4.2MB │2MB │ 5.1MB  │4MB  │ 1.2MB│              │
│ └─────┴───────┴────┴────────┴─────┴──────┘              │
│ Chunk boundaries determined by content                   │
│ → Insertion shifts only the affected chunk               │
│ → Only 1-2 chunks re-uploaded ✅                         │
└─────────────────────────────────────────────────────────┘
```

### Deduplication

```
User A uploads:  report.pdf → chunks [C1, C2, C3]
User B uploads:  report.pdf → chunks [C1, C2, C3]  (same hashes!)

Server already has C1, C2, C3 → No actual data transfer needed!
Only metadata is updated.

Dedup Levels:
1. Cross-user dedup  (same file uploaded by different users)
2. Cross-file dedup  (same chunk in different files)
3. Cross-version dedup (unchanged chunks between versions)
```

---

## 6. Metadata Service <a name="6-metadata"></a>

### Schema Design

```
┌────────────────────────────────────────────────────────────────┐
│                     METADATA DATABASE                          │
│                                                                │
│  ┌──────────────┐     ┌──────────────────┐                    │
│  │    users     │     │   workspaces     │                    │
│  ├──────────────┤     ├──────────────────┤                    │
│  │ user_id (PK) │────▶│ workspace_id(PK) │                    │
│  │ email        │     │ owner_id (FK)    │                    │
│  │ name         │     │ quota_bytes      │                    │
│  │ created_at   │     │ used_bytes       │                    │
│  └──────────────┘     └────────┬─────────┘                    │
│                                │                               │
│                       ┌────────┴─────────┐                    │
│                       │   file_metadata  │                    │
│                       ├──────────────────┤                    │
│                       │ file_id (PK)     │                    │
│                       │ workspace_id(FK) │                    │
│                       │ file_name        │                    │
│                       │ file_path        │                    │
│                       │ is_directory     │                    │
│                       │ parent_id (FK)   │──┐ (self-ref)     │
│                       │ latest_version   │  │                 │
│                       │ size_bytes       │  │                 │
│                       │ created_at       │◄─┘                 │
│                       │ updated_at       │                    │
│                       │ is_deleted       │                    │
│                       └────────┬─────────┘                    │
│                                │                               │
│                       ┌────────┴─────────┐                    │
│                       │  file_versions   │                    │
│                       ├──────────────────┤                    │
│                       │ version_id (PK)  │                    │
│                       │ file_id (FK)     │                    │
│                       │ version_number   │                    │
│                       │ size_bytes       │                    │
│                       │ checksum         │                    │
│                       │ modified_by      │                    │
│                       │ created_at       │                    │
│                       │ device_id        │                    │
│                       └────────┬─────────┘                    │
│                                │                               │
│                       ┌────────┴─────────┐                    │
│                       │  file_chunks     │                    │
│                       ├──────────────────┤                    │
│                       │ id (PK)          │                    │
│                       │ version_id (FK)  │                    │
│                       │ chunk_hash       │──┐                 │
│                       │ chunk_order      │  │                 │
│                       │ chunk_size       │  │                 │
│                       └──────────────────┘  │                 │
│                                              │                 │
│                       ┌──────────────────┐  │                 │
│                       │     chunks       │  │                 │
│                       ├──────────────────┤  │                 │
│                       │ chunk_hash (PK)  │◄─┘                 │
│                       │ storage_path     │                    │
│                       │ size_bytes       │                    │
│                       │ ref_count        │                    │
│                       │ created_at       │                    │
│                       └──────────────────┘                    │
│                                                                │
│  ┌──────────────────┐  ┌──────────────────┐                   │
│  │   sharing_acl    │  │    devices       │                   │
│  ├──────────────────┤  ├──────────────────┤                   │
│  │ id (PK)          │  │ device_id (PK)   │                   │
│  │ file_id (FK)     │  │ user_id (FK)     │                   │
│  │ shared_with (FK) │  │ device_name      │                   │
│  │ permission       │  │ platform         │                   │
│  │ created_at       │  │ last_sync_at     │                   │
│  └──────────────────┘  │ cursor_position  │                   │
│                        └──────────────────┘                   │
└────────────────────────────────────────────────────────────────┘
```

### Metadata Partitioning Strategy

```
Partitioning by workspace_id:
┌──────────────────────────────────────────────┐
│ Shard 1:  workspace_id % N == 0              │
│ Shard 2:  workspace_id % N == 1              │
│ Shard 3:  workspace_id % N == 2              │
│ ...                                          │
│ Shard N:  workspace_id % N == N-1            │
└──────────────────────────────────────────────┘

Why workspace_id?
- All files in a workspace are on the same shard
- Listing folders = single shard query
- Sharing = cross-shard but rare
```

---

## 7. Sync Protocol <a name="7-sync"></a>

### Upload Flow (File Changed Locally)

```
┌────────┐       ┌──────────┐      ┌──────────┐      ┌─────────┐      ┌─────┐
│ Client │       │API Server│      │ Metadata │      │  Block  │      │ S3  │
│        │       │          │      │ Service  │      │ Server  │      │     │
└───┬────┘       └────┬─────┘      └────┬─────┘      └────┬────┘      └──┬──┘
    │                  │                 │                  │              │
    │ 1. File changed  │                 │                  │              │
    │ (watcher detects)│                 │                  │              │
    │                  │                 │                  │              │
    │ 2. Chunk file    │                 │                  │              │
    │ (local chunker)  │                 │                  │              │
    │                  │                 │                  │              │
    │ 3. POST /sync    │                 │                  │              │
    │ {file_path,      │                 │                  │              │
    │  chunk_hashes[]} │                 │                  │              │
    │─────────────────▶│                 │                  │              │
    │                  │ 4. Check which  │                  │              │
    │                  │ chunks exist    │                  │              │
    │                  │────────────────▶│                  │              │
    │                  │                 │                  │              │
    │                  │ 5. Return       │                  │              │
    │                  │ missing_chunks[]│                  │              │
    │                  │◀────────────────│                  │              │
    │                  │                 │                  │              │
    │ 6. Upload only   │                 │                  │              │
    │ missing chunks   │                 │                  │              │
    │ PUT /chunks/{hash}                 │                  │              │
    │──────────────────────────────────────────────────────▶│              │
    │                  │                 │                  │ 7. Store     │
    │                  │                 │                  │────────────▶ │
    │                  │                 │                  │              │
    │                  │                 │                  │ 8. ACK       │
    │                  │                 │                  │◀──────────── │
    │                  │                 │                  │              │
    │ 9. POST /commit  │                 │                  │              │
    │ {file_path,      │                 │                  │              │
    │  version,        │                 │                  │              │
    │  chunk_list[]}   │                 │                  │              │
    │─────────────────▶│ 10. Create new  │                  │              │
    │                  │ version entry   │                  │              │
    │                  │────────────────▶│                  │              │
    │                  │                 │                  │              │
    │                  │ 11. Publish     │                  │              │
    │                  │ change event    │                  │              │
    │                  │─────────────────┼──▶ Message Queue │              │
    │                  │                 │                  │              │
    │ 12. Success      │                 │                  │              │
    │◀─────────────────│                 │                  │              │
```

### Download Flow (Remote Change Detected)

```
┌────────┐      ┌──────────────┐    ┌──────────┐    ┌──────────┐    ┌─────┐
│Client A│      │ Notification │    │ Metadata │    │  Block   │    │ S3  │
│        │      │   Service    │    │ Service  │    │  Server  │    │     │
└───┬────┘      └──────┬───────┘    └────┬─────┘    └────┬─────┘    └──┬──┘
    │                   │                 │               │             │
    │  1. WebSocket     │                 │               │             │
    │  "file changed"   │                 │               │             │
    │◀──────────────────│                 │               │             │
    │                   │                 │               │             │
    │  2. GET /delta    │                 │               │             │
    │  {cursor}         │                 │               │             │
    │──────────────────────────────────▶  │               │             │
    │                   │                 │               │             │
    │  3. Changes list  │                 │               │             │
    │  [{file, version, │                 │               │             │
    │    chunks[]}]     │                 │               │             │
    │◀──────────────────────────────────  │               │             │
    │                   │                 │               │             │
    │  4. Compare local │                 │               │             │
    │  chunks with new  │                 │               │             │
    │  chunk list       │                 │               │             │
    │                   │                 │               │             │
    │  5. Download only │                 │               │             │
    │  missing chunks   │                 │               │             │
    │  GET /chunks/{hash}                 │               │             │
    │─────────────────────────────────────────────────▶   │             │
    │                   │                 │               │ 6. Fetch    │
    │                   │                 │               │────────────▶│
    │                   │                 │               │             │
    │  7. Chunk data    │                 │               │◀────────────│
    │◀─────────────────────────────────────────────────   │             │
    │                   │                 │               │             │
    │  8. Reconstruct   │                 │               │             │
    │  file locally     │                 │               │             │
```

### Delta Sync (Cursor-Based)

```
How the cursor works:
┌────────────────────────────────────────────────────────┐
│ Each client maintains a "cursor" (a server-side        │
│ sequence number or timestamp of the last sync point)   │
│                                                        │
│ GET /delta?cursor=12345                                │
│                                                        │
│ Response:                                              │
│ {                                                      │
│   "entries": [                                         │
│     {"path": "/docs/report.pdf", "action": "update"},  │
│     {"path": "/photos/cat.jpg", "action": "add"},      │
│     {"path": "/old/draft.txt",  "action": "delete"}    │
│   ],                                                   │
│   "cursor": 12350,                                     │
│   "has_more": false                                    │
│ }                                                      │
│                                                        │
│ Client saves cursor=12350 for next delta call          │
└────────────────────────────────────────────────────────┘
```

---

## 8. Notification Service <a name="8-notification"></a>

```
┌─────────────────────────────────────────────────────────────┐
│                  NOTIFICATION ARCHITECTURE                    │
│                                                              │
│  ┌─────────┐  commit  ┌───────────┐  publish  ┌──────────┐ │
│  │Metadata │────────▶ │  Message  │────────▶  │Notif.    │ │
│  │Service  │          │  Queue    │           │Service   │ │
│  └─────────┘          │  (Kafka)  │           └────┬─────┘ │
│                       └───────────┘                │       │
│                                                     │       │
│              ┌──────────────────────────────────────┤       │
│              │              │              │         │       │
│              ▼              ▼              ▼         │       │
│         ┌────────┐    ┌────────┐    ┌────────┐      │       │
│         │Client A│    │Client B│    │Client C│      │       │
│         │(online)│    │(online)│    │(offline│      │       │
│         │WebSocket    │Long Poll    │ — gets │      │       │
│         └────────┘    └────────┘    │delta on│      │       │
│                                     │reconnect     │       │
│                                     └────────┘      │       │
└─────────────────────────────────────────────────────────────┘

Notification Types:
├── WebSocket    → Best for desktop clients (persistent connection)
├── Long Polling → Fallback for restrictive networks
├── SSE          → Web clients
└── Push (APNs/FCM) → Mobile clients
```

---

## 9. Conflict Resolution <a name="9-conflict"></a>

```
Scenario: User edits same file on two offline devices

Device A (offline): edits file.txt → version 3a
Device B (offline): edits file.txt → version 3b
Server: has version 2

Device A comes online first → uploads version 3a ✅ (server now at v3)
Device B comes online → tries to upload version 3b 
  → CONFLICT! (base version was 2, but server is now at 3)

Resolution Strategy:
┌──────────────────────────────────────────────────────────┐
│                                                          │
│  1. Server keeps BOTH versions                           │
│                                                          │
│  2. The later upload is saved as a "conflicted copy":    │
│     file.txt                    ← Device A's version     │
│     file (Device B's conflicted copy).txt                │
│                                                          │
│  3. User manually resolves                               │
│                                                          │
│  Alternative: Operational Transform / CRDT for           │
│  text files (but complex, out of typical scope)          │
│                                                          │
└──────────────────────────────────────────────────────────┘
```

---

## 10. API Design <a name="10-api"></a>

### RESTful APIs

```
Authentication: OAuth 2.0 Bearer Token
Base URL: https://api.dropbox.com/v2

────────────────────────────────────────────────────────────
File Operations:
────────────────────────────────────────────────────────────

POST   /files/upload
  Headers: Authorization, Content-Type, Dropbox-API-Arg
  Body: binary file data (for small files < 150MB)
  
POST   /files/upload_session/start
POST   /files/upload_session/append
POST   /files/upload_session/finish
  → For large files (chunked/resumable upload)

POST   /files/download
  Headers: Dropbox-API-Arg: {"path": "/docs/report.pdf"}
  Response: binary data

POST   /files/delete
POST   /files/move
POST   /files/copy
POST   /files/create_folder

POST   /files/list_folder
  Body: {"path": "/documents", "recursive": false}

POST   /files/list_folder/continue
  Body: {"cursor": "..."}

────────────────────────────────────────────────────────────
Sync Operations:
────────────────────────────────────────────────────────────

POST   /sync/check_chunks
  Body: {"chunk_hashes": ["abc123", "def456", ...]}
  Response: {"missing": ["def456"]}

PUT    /sync/upload_chunk/{chunk_hash}
  Body: binary chunk data

POST   /sync/commit
  Body: {
    "file_path": "/docs/report.pdf",
    "chunk_hashes": ["abc123", "def456"],
    "parent_version": 5
  }

POST   /sync/delta
  Body: {"cursor": "12345"}
  Response: {"entries": [...], "cursor": "12350", "has_more": false}

────────────────────────────────────────────────────────────
Sharing:
────────────────────────────────────────────────────────────

POST   /sharing/create_shared_link
POST   /sharing/add_folder_member
POST   /sharing/list_shared_links
POST   /sharing/revoke_shared_link
```

---

## 11. Data Models <a name="11-data-models"></a>

### SQL Schema

```sql
-- Users table
CREATE TABLE users (
    user_id         BIGINT PRIMARY KEY AUTO_INCREMENT,
    email           VARCHAR(255) UNIQUE NOT NULL,
    password_hash   VARCHAR(255) NOT NULL,
    name            VARCHAR(255),
    quota_bytes     BIGINT DEFAULT 2147483648, -- 2GB free
    used_bytes      BIGINT DEFAULT 0,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Devices table
CREATE TABLE devices (
    device_id       VARCHAR(64) PRIMARY KEY,
    user_id         BIGINT NOT NULL,
    device_name     VARCHAR(255),
    platform        ENUM('windows','macos','linux','ios','android','web'),
    last_sync_at    TIMESTAMP,
    sync_cursor     BIGINT DEFAULT 0,
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

-- File Metadata (tree structure with parent_id)
CREATE TABLE file_metadata (
    file_id         BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id         BIGINT NOT NULL,
    file_name       VARCHAR(255) NOT NULL,
    file_path       VARCHAR(4096) NOT NULL,
    is_directory    BOOLEAN DEFAULT FALSE,
    parent_id       BIGINT,
    latest_version  INT DEFAULT 1,
    size_bytes      BIGINT DEFAULT 0,
    content_hash    VARCHAR(64),
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_deleted      BOOLEAN DEFAULT FALSE,
    
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (parent_id) REFERENCES file_metadata(file_id),
    INDEX idx_user_path (user_id, file_path),
    INDEX idx_parent (parent_id)
);

-- File Versions
CREATE TABLE file_versions (
    version_id      BIGINT PRIMARY KEY AUTO_INCREMENT,
    file_id         BIGINT NOT NULL,
    version_number  INT NOT NULL,
    size_bytes      BIGINT NOT NULL,
    checksum        VARCHAR(64) NOT NULL,
    modified_by     BIGINT NOT NULL,
    device_id       VARCHAR(64),
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (file_id) REFERENCES file_metadata(file_id),
    UNIQUE KEY uk_file_version (file_id, version_number)
);

-- Chunks (global dedup pool)
CREATE TABLE chunks (
    chunk_hash      VARCHAR(64) PRIMARY KEY,  -- SHA-256
    storage_path    VARCHAR(512) NOT NULL,     -- S3 path
    size_bytes      INT NOT NULL,
    ref_count       INT DEFAULT 1,
    compressed_size INT,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Version-to-Chunk mapping
CREATE TABLE version_chunks (
    id              BIGINT PRIMARY KEY AUTO_INCREMENT,
    version_id      BIGINT NOT NULL,
    chunk_hash      VARCHAR(64) NOT NULL,
    chunk_order     INT NOT NULL,
    offset_bytes    BIGINT NOT NULL,
    
    FOREIGN KEY (version_id) REFERENCES file_versions(version_id),
    FOREIGN KEY (chunk_hash) REFERENCES chunks(chunk_hash),
    INDEX idx_version (version_id)
);

-- Change log for delta sync
CREATE TABLE change_log (
    sequence_id     BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id         BIGINT NOT NULL,
    file_id         BIGINT NOT NULL,
    action          ENUM('create','update','delete','move','rename'),
    file_path       VARCHAR(4096),
    version_number  INT,
    timestamp       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_user_seq (user_id, sequence_id)
);

-- Sharing
CREATE TABLE sharing_acl (
    id              BIGINT PRIMARY KEY AUTO_INCREMENT,
    file_id         BIGINT NOT NULL,
    owner_id        BIGINT NOT NULL,
    shared_with_id  BIGINT NOT NULL,
    permission      ENUM('view','edit','owner') DEFAULT 'view',
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (file_id) REFERENCES file_metadata(file_id)
);
```

---

## 12. Security <a name="12-security"></a>

```
┌──────────────────────────────────────────────────────┐
│                   SECURITY LAYERS                     │
│                                                       │
│  Transport:   TLS 1.3 for all communications         │
│                                                       │
│  Storage:     AES-256 encryption at rest             │
│               Each user gets unique encryption key    │
│               Keys stored in separate KMS             │
│                                                       │
│  Auth:        OAuth 2.0 + JWT tokens                 │
│               Multi-factor authentication             │
│               Device-level authentication             │
│                                                       │
│  Integrity:   SHA-256 checksums on all chunks        │
│               End-to-end verification                 │
│                                                       │
│  Access:      Role-based access control (RBAC)       │
│               Per-file/folder ACLs                    │
│               Expiring shared links                   │
│                                                       │
│  Rate Limit:  Per-user API rate limiting             │
│               Bandwidth throttling                    │
└──────────────────────────────────────────────────────┘
```

---

## 13. Python Examples (End-to-End) <a name="13-python"></a>

### 13.1 File Chunker with Content-Defined Chunking

```python
import hashlib
import os
from typing import List, Tuple

class Chunk:
    """Represents a single chunk of a file."""
    def __init__(self, data: bytes, offset: int):
        self.data = data
        self.offset = offset
        self.size = len(data)
        self.hash = hashlib.sha256(data).hexdigest()
    
    def __repr__(self):
        return f"Chunk(hash={self.hash[:12]}..., size={self.size}, offset={self.offset})"


class FileChunker:
    """
    Content-Defined Chunking using Rabin fingerprinting.
    
    Instead of fixed-size chunks, boundaries are determined by content.
    This means inserting bytes in the middle only affects 1-2 chunks.
    """
    
    # Chunking parameters
    MIN_CHUNK_SIZE = 2 * 1024 * 1024    # 2 MB minimum
    MAX_CHUNK_SIZE = 8 * 1024 * 1024    # 8 MB maximum
    TARGET_CHUNK_SIZE = 4 * 1024 * 1024 # 4 MB target
    
    # Rabin fingerprint parameters
    WINDOW_SIZE = 48
    PRIME = 31
    MODULUS = (1 << 13) - 1  # Mask for boundary detection
    
    def __init__(self):
        self._precompute_powers()
    
    def _precompute_powers(self):
        """Precompute prime powers for rolling hash."""
        self._prime_power = pow(self.PRIME, self.WINDOW_SIZE, 2**64)
    
    def _rolling_hash(self, data: bytes, start: int, window_size: int) -> int:
        """Compute a simple rolling hash over a window."""
        h = 0
        for i in range(window_size):
            if start + i < len(data):
                h = (h * self.PRIME + data[start + i]) & 0xFFFFFFFFFFFFFFFF
        return h
    
    def chunk_file(self, file_path: str) -> List[Chunk]:
        """
        Split a file into content-defined chunks.
        
        Returns a list of Chunk objects with hash, data, offset, and size.
        """
        with open(file_path, 'rb') as f:
            data = f.read()
        
        return self.chunk_data(data)
    
    def chunk_data(self, data: bytes) -> List[Chunk]:
        """Split raw bytes into content-defined chunks."""
        chunks = []
        offset = 0
        data_len = len(data)
        
        while offset < data_len:
            # Determine chunk boundary
            chunk_end = self._find_boundary(data, offset)
            
            chunk_data = data[offset:chunk_end]
            chunk = Chunk(chunk_data, offset)
            chunks.append(chunk)
            
            offset = chunk_end
        
        return chunks
    
    def _find_boundary(self, data: bytes, start: int) -> int:
        """
        Find the next chunk boundary using rolling hash.
        
        The boundary is where: rolling_hash & MODULUS == 0
        This creates variable-size chunks averaging TARGET_CHUNK_SIZE.
        """
        data_len = len(data)
        
        # Minimum chunk size — don't check for boundary before this
        min_end = min(start + self.MIN_CHUNK_SIZE, data_len)
        # Maximum chunk size — force boundary here
        max_end = min(start + self.MAX_CHUNK_SIZE, data_len)
        
        if min_end >= data_len:
            return data_len
        
        # Rolling hash to find boundary
        h = 0
        for pos in range(min_end, max_end):
            h = (h * self.PRIME + data[pos]) & 0xFFFFFFFFFFFFFFFF
            
            # Check if this is a boundary
            if (h & self.MODULUS) == 0:
                return pos + 1
        
        # If no boundary found, cut at max size
        return max_end
    
    @staticmethod
    def compute_file_hash(chunks: List[Chunk]) -> str:
        """Compute overall file hash from chunk hashes."""
        combined = ''.join(c.hash for c in chunks)
        return hashlib.sha256(combined.encode()).hexdigest()


class FixedSizeChunker:
    """Simple fixed-size chunker for comparison."""
    
    CHUNK_SIZE = 4 * 1024 * 1024  # 4 MB
    
    def chunk_file(self, file_path: str) -> List[Chunk]:
        chunks = []
        offset = 0
        
        with open(file_path, 'rb') as f:
            while True:
                data = f.read(self.CHUNK_SIZE)
                if not data:
                    break
                chunks.append(Chunk(data, offset))
                offset += len(data)
        
        return chunks


# --- Demo ---
if __name__ == "__main__":
    # Create a sample file
    sample_data = os.urandom(15 * 1024 * 1024)  # 15 MB random data
    
    with open("/tmp/sample_file.bin", "wb") as f:
        f.write(sample_data)
    
    chunker = FileChunker()
    chunks = chunker.chunk_file("/tmp/sample_file.bin")
    
    print(f"File size: {len(sample_data) / (1024*1024):.1f} MB")
    print(f"Number of chunks: {len(chunks)}")
    print(f"File hash: {FileChunker.compute_file_hash(chunks)}")
    print()
    for i, chunk in enumerate(chunks):
        print(f"  Chunk {i}: {chunk}")
```

### 13.2 Local Database (Client-Side Metadata)

```python
import sqlite3
import json
import time
from typing import Optional, List, Dict
from dataclasses import dataclass, asdict


@dataclass
class LocalFileEntry:
    file_path: str
    is_directory: bool
    file_hash: str  # overall file hash
    chunk_hashes: List[str]  # ordered list of chunk hashes
    size_bytes: int
    local_modified_at: float
    server_version: int
    sync_status: str  # 'synced', 'pending_upload', 'pending_download', 'conflict'


class LocalMetadataDB:
    """
    SQLite database on the client to track local file state.
    This is what the Indexer component uses.
    """
    
    def __init__(self, db_path: str = "~/.dropbox/metadata.db"):
        self.db_path = os.path.expanduser(db_path)
        os.makedirs(os.path.dirname(self.db_path), exist_ok=True)
        self.conn = sqlite3.connect(self.db_path)
        self._create_tables()
    
    def _create_tables(self):
        self.conn.executescript("""
            CREATE TABLE IF NOT EXISTS local_files (
                file_path       TEXT PRIMARY KEY,
                is_directory    INTEGER DEFAULT 0,
                file_hash       TEXT,
                chunk_hashes    TEXT,  -- JSON array
                size_bytes      INTEGER DEFAULT 0,
                local_modified  REAL,
                server_version  INTEGER DEFAULT 0,
                sync_status     TEXT DEFAULT 'pending_upload'
            );
            
            CREATE TABLE IF NOT EXISTS sync_cursor (
                id      INTEGER PRIMARY KEY CHECK (id = 1),
                cursor  TEXT DEFAULT '0'
            );
            
            INSERT OR IGNORE INTO sync_cursor (id, cursor) VALUES (1, '0');
            
            CREATE TABLE IF NOT EXISTS local_chunks (
                chunk_hash  TEXT PRIMARY KEY,
                file_path   TEXT,
                chunk_order INTEGER,
                uploaded    INTEGER DEFAULT 0
            );
        """)
        self.conn.commit()
    
    def upsert_file(self, entry: LocalFileEntry):
        """Insert or update a file entry."""
        self.conn.execute("""
            INSERT OR REPLACE INTO local_files 
            (file_path, is_directory, file_hash, chunk_hashes, 
             size_bytes, local_modified, server_version, sync_status)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        """, (
            entry.file_path,
            int(entry.is_directory),
            entry.file_hash,
            json.dumps(entry.chunk_hashes),
            entry.size_bytes,
            entry.local_modified_at,
            entry.server_version,
            entry.sync_status
        ))
        self.conn.commit()
    
    def get_file(self, file_path: str) -> Optional[LocalFileEntry]:
        """Get a file entry by path."""
        row = self.conn.execute(
            "SELECT * FROM local_files WHERE file_path = ?",
            (file_path,)
        ).fetchone()
        
        if not row:
            return None
        
        return LocalFileEntry(
            file_path=row[0],
            is_directory=bool(row[1]),
            file_hash=row[2],
            chunk_hashes=json.loads(row[3]) if row[3] else [],
            size_bytes=row[4],
            local_modified_at=row[5],
            server_version=row[6],
            sync_status=row[7]
        )
    
    def get_pending_uploads(self) -> List[LocalFileEntry]:
        """Get all files that need uploading."""
        rows = self.conn.execute(
            "SELECT * FROM local_files WHERE sync_status = 'pending_upload'"
        ).fetchall()
        return [self._row_to_entry(r) for r in rows]
    
    def get_cursor(self) -> str:
        row = self.conn.execute("SELECT cursor FROM sync_cursor WHERE id = 1").fetchone()
        return row[0] if row else '0'
    
    def set_cursor(self, cursor: str):
        self.conn.execute("UPDATE sync_cursor SET cursor = ? WHERE id = 1", (cursor,))
        self.conn.commit()
    
    def delete_file(self, file_path: str):
        self.conn.execute("DELETE FROM local_files WHERE file_path = ?", (file_path,))
        self.conn.commit()
    
    def _row_to_entry(self, row) -> LocalFileEntry:
        return LocalFileEntry(
            file_path=row[0],
            is_directory=bool(row[1]),
            file_hash=row[2],
            chunk_hashes=json.loads(row[3]) if row[3] else [],
            size_bytes=row[4],
            local_modified_at=row[5],
            server_version=row[6],
            sync_status=row[7]
        )
    
    def close(self):
        self.conn.close()
```

### 13.3 File Watcher

```python
import os
import time
import hashlib
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler, FileSystemEvent
from queue import Queue
from threading import Thread


class DropboxFileWatcher(FileSystemEventHandler):
    """
    Watches a local directory for file changes.
    Uses the 'watchdog' library (cross-platform: inotify/FSEvents/ReadDirectoryChanges).
    """
    
    def __init__(self, sync_folder: str, change_queue: Queue):
        self.sync_folder = os.path.abspath(sync_folder)
        self.change_queue = change_queue
        self._ignored_patterns = {'.dropbox', '.dropbox.cache', '__pycache__'}
    
    def _should_ignore(self, path: str) -> bool:
        """Ignore system/hidden files."""
        parts = path.split(os.sep)
        return any(p.startswith('.') or p in self._ignored_patterns for p in parts)
    
    def _get_relative_path(self, absolute_path: str) -> str:
        """Convert absolute path to relative path within sync folder."""
        return os.path.relpath(absolute_path, self.sync_folder)
    
    def on_created(self, event: FileSystemEvent):
        if self._should_ignore(event.src_path):
            return
        
        rel_path = self._get_relative_path(event.src_path)
        print(f"[WATCHER] Created: {rel_path}")
        self.change_queue.put({
            'action': 'create',
            'path': rel_path,
            'is_directory': event.is_directory,
            'timestamp': time.time()
        })
    
    def on_modified(self, event: FileSystemEvent):
        if event.is_directory or self._should_ignore(event.src_path):
            return
        
        rel_path = self._get_relative_path(event.src_path)
        print(f"[WATCHER] Modified: {rel_path}")
        self.change_queue.put({
            'action': 'modify',
            'path': rel_path,
            'is_directory': False,
            'timestamp': time.time()
        })
    
    def on_deleted(self, event: FileSystemEvent):
        if self._should_ignore(event.src_path):
            return
        
        rel_path = self._get_relative_path(event.src_path)
        print(f"[WATCHER] Deleted: {rel_path}")
        self.change_queue.put({
            'action': 'delete',
            'path': rel_path,
            'is_directory': event.is_directory,
            'timestamp': time.time()
        })
    
    def on_moved(self, event: FileSystemEvent):
        if self._should_ignore(event.src_path):
            return
        
        src_rel = self._get_relative_path(event.src_path)
        dst_rel = self._get_relative_path(event.dest_path)
        print(f"[WATCHER] Moved: {src_rel} → {dst_rel}")
        self.change_queue.put({
            'action': 'move',
            'path': src_rel,
            'new_path': dst_rel,
            'is_directory': event.is_directory,
            'timestamp': time.time()
        })


def start_watcher(sync_folder: str, change_queue: Queue) -> Observer:
    """Start watching a folder for changes."""
    event_handler = DropboxFileWatcher(sync_folder, change_queue)
    observer = Observer()
    observer.schedule(event_handler, sync_folder, recursive=True)
    observer.start()
    print(f"[WATCHER] Watching folder: {sync_folder}")
    return observer


# --- Demo ---
if __name__ == "__main__":
    import tempfile
    
    sync_folder = tempfile.mkdtemp(prefix="dropbox_sync_")
    change_queue = Queue()
    
    observer = start_watcher(sync_folder, change_queue)
    
    try:
        # Simulate file operations
        time.sleep(1)
        
        # Create a file
        test_file = os.path.join(sync_folder, "hello.txt")
        with open(test_file, 'w') as f:
            f.write("Hello, Dropbox!")
        
        time.sleep(1)
        
        # Modify the file
        with open(test_file, 'a') as f:
            f.write("\nNew line added.")
        
        time.sleep(1)
        
        # Process events
        while not change_queue.empty():
            event = change_queue.get()
            print(f"  Event: {event}")
        
    finally:
        observer.stop()
        observer.join()
```

### 13.4 Server — Metadata Service (FastAPI)

```python
from fastapi import FastAPI, HTTPException, Depends, Header
from pydantic import BaseModel
from typing import List, Optional, Dict
from datetime import datetime
import uuid
import asyncio

app = FastAPI(title="Dropbox Metadata Service")


# ──────────────────────────────────────────
# In-memory stores (replace with real DB)
# ──────────────────────────────────────────
users_db: Dict[str, dict] = {}
files_db: Dict[str, dict] = {}  # file_id -> file_metadata
chunks_db: Dict[str, dict] = {}  # chunk_hash -> chunk_info
versions_db: Dict[str, dict] = {}  # version_id -> version_info
change_log: List[dict] = []  # ordered list of changes
sequence_counter = 0


# ──────────────────────────────────────────
# Request/Response Models
# ──────────────────────────────────────────
class CheckChunksRequest(BaseModel):
    chunk_hashes: List[str]

class CheckChunksResponse(BaseModel):
    existing: List[str]
    missing: List[str]

class CommitRequest(BaseModel):
    file_path: str
    file_name: str
    chunk_hashes: List[str]
    total_size: int
    parent_version: int = 0  # 0 = new file

class CommitResponse(BaseModel):
    file_id: str
    version_number: int
    file_hash: str

class DeltaRequest(BaseModel):
    cursor: str = "0"

class DeltaEntry(BaseModel):
    file_path: str
    file_id: str
    action: str  # create, update, delete
    version: int
    chunk_hashes: List[str]
    size: int

class DeltaResponse(BaseModel):
    entries: List[DeltaEntry]
    cursor: str
    has_more: bool

class FileMetadataResponse(BaseModel):
    file_id: str
    file_name: str
    file_path: str
    size_bytes: int
    version: int
    content_hash: str
    modified_at: str
    is_directory: bool

class ListFolderRequest(BaseModel):
    path: str
    recursive: bool = False

class ListFolderResponse(BaseModel):
    entries: List[FileMetadataResponse]
    cursor: str


# ──────────────────────────────────────────
# Auth dependency (simplified)
# ──────────────────────────────────────────
async def get_current_user(authorization: str = Header(...)):
    """Simplified auth — in production, validate JWT."""
    token = authorization.replace("Bearer ", "")
    # In production: decode JWT, validate signature, extract user_id
    return {"user_id": token, "email": f"{token}@example.com"}


# ──────────────────────────────────────────
# Endpoints
# ──────────────────────────────────────────

@app.post("/sync/check_chunks", response_model=CheckChunksResponse)
async def check_chunks(request: CheckChunksRequest, user=Depends(get_current_user)):
    """
    Client sends a list of chunk hashes.
    Server returns which chunks already exist (deduplication).
    Client only needs to upload the missing ones.
    """
    existing = []
    missing = []
    
    for chunk_hash in request.chunk_hashes:
        if chunk_hash in chunks_db:
            existing.append(chunk_hash)
        else:
            missing.append(chunk_hash)
    
    return CheckChunksResponse(existing=existing, missing=missing)


@app.put("/sync/upload_chunk/{chunk_hash}")
async def upload_chunk(chunk_hash: str, user=Depends(get_current_user)):
    """
    Upload a single chunk. In production, this would:
    1. Receive binary data
    2. Verify hash matches
    3. Compress with LZ4/zstd
    4. Store in S3/GCS
    """
    # Simulate storing chunk
    storage_path = f"s3://dropbox-chunks/{chunk_hash[:2]}/{chunk_hash[2:4]}/{chunk_hash}"
    
    chunks_db[chunk_hash] = {
        "chunk_hash": chunk_hash,
        "storage_path": storage_path,
        "ref_count": 1,
        "created_at": datetime.utcnow().isoformat()
    }
    
    return {"status": "uploaded", "chunk_hash": chunk_hash}


@app.post("/sync/commit", response_model=CommitResponse)
async def commit_file(request: CommitRequest, user=Depends(get_current_user)):
    """
    After all chunks are uploaded, client commits the file.
    This creates/updates the file metadata and version.
    """
    global sequence_counter
    
    user_id = user["user_id"]
    
    # Verify all chunks exist
    for ch in request.chunk_hashes:
        if ch not in chunks_db:
            raise HTTPException(400, f"Chunk {ch} not found. Upload it first.")
    
    # Compute file hash from chunk hashes
    import hashlib
    file_hash = hashlib.sha256(
        ''.join(request.chunk_hashes).encode()
    ).hexdigest()
    
    # Check if file already exists
    existing_file = None
    for fid, fmeta in files_db.items():
        if fmeta["file_path"] == request.file_path and fmeta["user_id"] == user_id:
            existing_file = fmeta
            break
    
    if existing_file:
        # ─── UPDATE existing file ───
        # Check for conflicts (optimistic locking)
        if request.parent_version != existing_file["latest_version"]:
            raise HTTPException(
                409,
                detail={
                    "error": "conflict",
                    "server_version": existing_file["latest_version"],
                    "message": "File was modified by another device. "
                              "Save as conflicted copy."
                }
            )
        
        new_version = existing_file["latest_version"] + 1
        file_id = existing_file["file_id"]
        existing_file["latest_version"] = new_version
        existing_file["size_bytes"] = request.total_size
        existing_file["content_hash"] = file_hash
        existing_file["updated_at"] = datetime.utcnow().isoformat()
        action = "update"
    else:
        # ─── CREATE new file ───
        file_id = str(uuid.uuid4())
        new_version = 1
        files_db[file_id] = {
            "file_id": file_id,
            "user_id": user_id,
            "file_name": request.file_name,
            "file_path": request.file_path,
            "is_directory": False,
            "latest_version": new_version,
            "size_bytes": request.total_size,
            "content_hash": file_hash,
            "created_at": datetime.utcnow().isoformat(),
            "updated_at": datetime.utcnow().isoformat(),
        }
        action = "create"
    
    # Create version entry
    version_id = str(uuid.uuid4())
    versions_db[version_id] = {
        "version_id": version_id,
        "file_id": file_id,
        "version_number": new_version,
        "chunk_hashes": request.chunk_hashes,
        "size_bytes": request.total_size,
        "checksum": file_hash,
        "modified_by": user_id,
        "created_at": datetime.utcnow().isoformat()
    }
    
    # Increment ref_count on chunks
    for ch in request.chunk_hashes:
        chunks_db[ch]["ref_count"] += 1
    
    # Add to change log (for delta sync)
    sequence_counter += 1
    change_log.append({
        "sequence_id": sequence_counter,
        "user_id": user_id,
        "file_id": file_id,
        "action": action,
        "file_path": request.file_path,
        "version_number": new_version,
        "chunk_hashes": request.chunk_hashes,
        "size_bytes": request.total_size,
        "timestamp": datetime.utcnow().isoformat()
    })
    
    # TODO: Publish to message queue for notification service
    # await kafka_producer.send("file_changes", change_event)
    
    return CommitResponse(
        file_id=file_id,
        version_number=new_version,
        file_hash=file_hash
    )


@app.post("/sync/delta", response_model=DeltaResponse)
async def get_delta(request: DeltaRequest, user=Depends(get_current_user)):
    """
    Return all changes since the client's cursor position.
    This is how other devices learn about remote changes.
    """
    user_id = user["user_id"]
    cursor_pos = int(request.cursor)
    
    # Get all changes after cursor for this user
    entries = []
    for change in change_log:
        if change["sequence_id"] > cursor_pos and change["user_id"] == user_id:
            entries.append(DeltaEntry(
                file_path=change["file_path"],
                file_id=change["file_id"],
                action=change["action"],
                version=change["version_number"],
                chunk_hashes=change["chunk_hashes"],
                size=change["size_bytes"]
            ))
    
    # Limit response size
    PAGE_SIZE = 100
    has_more = len(entries) > PAGE_SIZE
    entries = entries[:PAGE_SIZE]
    
    # New cursor
    if entries:
        new_cursor_pos = cursor_pos + len(entries)
    else:
        new_cursor_pos = cursor_pos
    
    return DeltaResponse(
        entries=entries,
        cursor=str(new_cursor_pos),
        has_more=has_more
    )


@app.post("/files/list_folder", response_model=ListFolderResponse)
async def list_folder(request: ListFolderRequest, user=Depends(get_current_user)):
    """List all files in a folder."""
    user_id = user["user_id"]
    entries = []
    
    for fid, fmeta in files_db.items():
        if fmeta["user_id"] != user_id:
            continue
        
        file_dir = os.path.dirname(fmeta["file_path"])
        if request.recursive:
            if not fmeta["file_path"].startswith(request.path):
                continue
        else:
            if file_dir != request.path.rstrip('/'):
                continue
        
        entries.append(FileMetadataResponse(
            file_id=fmeta["file_id"],
            file_name=fmeta["file_name"],
            file_path=fmeta["file_path"],
            size_bytes=fmeta["size_bytes"],
            version=fmeta["latest_version"],
            content_hash=fmeta["content_hash"],
            modified_at=fmeta["updated_at"],
            is_directory=fmeta["is_directory"]
        ))
    
    return ListFolderResponse(
        entries=entries,
        cursor=str(sequence_counter)
    )


@app.get("/files/versions/{file_id}")
async def get_file_versions(file_id: str, user=Depends(get_current_user)):
    """Get all versions of a file (version history)."""
    file_versions = [
        v for v in versions_db.values() 
        if v["file_id"] == file_id
    ]
    file_versions.sort(key=lambda v: v["version_number"], reverse=True)
    return {"versions": file_versions}


@app.post("/sharing/share")
async def share_file(
    file_id: str, 
    shared_with_email: str,
    permission: str = "view",
    user=Depends(get_current_user)
):
    """Share a file with another user."""
    if file_id not in files_db:
        raise HTTPException(404, "File not found")
    
    file = files_db[file_id]
    if file["user_id"] != user["user_id"]:
        raise HTTPException(403, "Not authorized")
    
    # In production: look up user by email, create ACL entry
    return {
        "status": "shared",
        "file_id": file_id,
        "shared_with": shared_with_email,
        "permission": permission
    }


# Health check
@app.get("/health")
async def health():
    return {"status": "healthy", "service": "metadata"}
```

### 13.5 Sync Engine (Client-Side Orchestrator)

```python
import os
import time
import hashlib
import requests
from queue import Queue, Empty
from threading import Thread, Event
from typing import List, Dict, Optional


class SyncEngine:
    """
    The core sync engine that coordinates:
    1. Watching for local changes
    2. Chunking changed files
    3. Uploading new/changed chunks
    4. Committing file versions
    5. Polling for remote changes
    6. Downloading and reconstructing files
    """
    
    def __init__(
        self,
        sync_folder: str,
        server_url: str,
        auth_token: str,
        local_db: 'LocalMetadataDB'
    ):
        self.sync_folder = os.path.abspath(sync_folder)
        self.server_url = server_url
        self.auth_token = auth_token
        self.local_db = local_db
        self.chunker = FileChunker()
        self.change_queue = Queue()
        self.stop_event = Event()
        
        self.headers = {
            "Authorization": f"Bearer {auth_token}",
            "Content-Type": "application/json"
        }
    
    # ─────────────────────────────────
    # UPLOAD FLOW
    # ─────────────────────────────────
    
    def handle_local_change(self, change_event: dict):
        """Process a local file change event from the watcher."""
        action = change_event['action']
        rel_path = change_event['path']
        abs_path = os.path.join(self.sync_folder, rel_path)
        
        print(f"[SYNC] Processing local change: {action} {rel_path}")
        
        if action in ('create', 'modify'):
            if os.path.isfile(abs_path):
                self._upload_file(rel_path, abs_path)
        
        elif action == 'delete':
            self._delete_file(rel_path)
        
        elif action == 'move':
            new_path = change_event.get('new_path')
            self._move_file(rel_path, new_path)
    
    def _upload_file(self, rel_path: str, abs_path: str):
        """Upload a file to the server."""
        print(f"[SYNC] Uploading: {rel_path}")
        
        # Step 1: Chunk the file
        chunks = self.chunker.chunk_file(abs_path)
        chunk_hashes = [c.hash for c in chunks]
        total_size = sum(c.size for c in chunks)
        
        print(f"[SYNC]   Chunked into {len(chunks)} chunks, total {total_size} bytes")
        
        # Step 2: Check which chunks server already has
        response = requests.post(
            f"{self.server_url}/sync/check_chunks",
            json={"chunk_hashes": chunk_hashes},
            headers=self.headers
        )
        result = response.json()
        missing_hashes = set(result["missing"])
        
        print(f"[SYNC]   Server needs {len(missing_hashes)} new chunks "
              f"(already has {len(result['existing'])})")
        
        # Step 3: Upload only missing chunks
        for chunk in chunks:
            if chunk.hash in missing_hashes:
                print(f"[SYNC]   Uploading chunk: {chunk.hash[:12]}... ({chunk.size} bytes)")
                
                upload_response = requests.put(
                    f"{self.server_url}/sync/upload_chunk/{chunk.hash}",
                    headers=self.headers
                    # In production: send chunk.data as binary body
                )
                
                if upload_response.status_code != 200:
                    print(f"[SYNC]   ERROR uploading chunk: {upload_response.text}")
                    return
        
        # Step 4: Commit the file
        existing = self.local_db.get_file(rel_path)
        parent_version = existing.server_version if existing else 0
        
        commit_response = requests.post(
            f"{self.server_url}/sync/commit",
            json={
                "file_path": rel_path,
                "file_name": os.path.basename(rel_path),
                "chunk_hashes": chunk_hashes,
                "total_size": total_size,
                "parent_version": parent_version
            },
            headers=self.headers
        )
        
        if commit_response.status_code == 200:
            result = commit_response.json()
            print(f"[SYNC]   Committed! Version: {result['version_number']}")
            
            # Update local DB
            self.local_db.upsert_file(LocalFileEntry(
                file_path=rel_path,
                is_directory=False,
                file_hash=result['file_hash'],
                chunk_hashes=chunk_hashes,
                size_bytes=total_size,
                local_modified_at=os.path.getmtime(abs_path),
                server_version=result['version_number'],
                sync_status='synced'
            ))
        
        elif commit_response.status_code == 409:
            # CONFLICT!
            print(f"[SYNC]   CONFLICT detected! Creating conflicted copy.")
            self._handle_conflict(rel_path, abs_path, commit_response.json())
    
    def _handle_conflict(self, rel_path: str, abs_path: str, error_detail: dict):
        """Handle sync conflict by creating a conflicted copy."""
        import socket
        hostname = socket.gethostname()
        
        base, ext = os.path.splitext(rel_path)
        conflict_path = f"{base} ({hostname}'s conflicted copy){ext}"
        conflict_abs = os.path.join(self.sync_folder, conflict_path)
        
        # Rename local file to conflicted copy
        os.rename(abs_path, conflict_abs)
        
        # Download the server version
        self._download_file_from_server(rel_path)
        
        # Upload the conflicted copy
        self._upload_file(conflict_path, conflict_abs)
        
        print(f"[SYNC]   Conflict resolved: {conflict_path}")
    
    def _delete_file(self, rel_path: str):
        """Handle local file deletion."""
        print(f"[SYNC] Deleting on server: {rel_path}")
        # POST to server to mark file as deleted
        # Update local DB
        self.local_db.delete_file(rel_path)
    
    def _move_file(self, old_path: str, new_path: str):
        """Handle local file move/rename."""
        print(f"[SYNC] Moving on server: {old_path} → {new_path}")
        # POST to server with move request
    
    # ─────────────────────────────────
    # DOWNLOAD FLOW (Delta Sync)
    # ─────────────────────────────────
    
    def poll_remote_changes(self):
        """Poll server for changes made by other devices."""
        cursor = self.local_db.get_cursor()
        
        response = requests.post(
            f"{self.server_url}/sync/delta",
            json={"cursor": cursor},
            headers=self.headers
        )
        
        if response.status_code != 200:
            print(f"[SYNC] Error polling delta: {response.text}")
            return
        
        result = response.json()
        entries = result["entries"]
        
        if not entries:
            return
        
        print(f"[SYNC] Received {len(entries)} remote changes")
        
        for entry in entries:
            self._apply_remote_change(entry)
        
        # Update cursor
        self.local_db.set_cursor(result["cursor"])
        
        # If there are more changes, continue polling
        if result["has_more"]:
            self.poll_remote_changes()
    
    def _apply_remote_change(self, entry: dict):
        """Apply a single remote change to the local filesystem."""
        action = entry["action"]
        file_path = entry["file_path"]
        abs_path = os.path.join(self.sync_folder, file_path)
        
        print(f"[SYNC] Applying remote {action}: {file_path}")
        
        if action in ("create", "update"):
            self._download_file(file_path, entry["chunk_hashes"], entry["version"])
        
        elif action == "delete":
            if os.path.exists(abs_path):
                os.remove(abs_path)
            self.local_db.delete_file(file_path)
    
    def _download_file(self, rel_path: str, chunk_hashes: List[str], version: int):
        """Download a file by fetching its chunks."""
        abs_path = os.path.join(self.sync_folder, rel_path)
        
        # Ensure directory exists
        os.makedirs(os.path.dirname(abs_path), exist_ok=True)
        
        # Check which chunks we already have locally
        existing = self.local_db.get_file(rel_path)
        local_chunks = set(existing.chunk_hashes) if existing else set()
        
        # Download only new chunks
        file_data = b""
        for chunk_hash in chunk_hashes:
            if chunk_hash in local_chunks:
                # Read from local cache
                print(f"[SYNC]   Chunk {chunk_hash[:12]}... (cached)")
                # In production: read from local chunk cache
                pass
            else:
                # Download from server
                print(f"[SYNC]   Downloading chunk: {chunk_hash[:12]}...")
                resp = requests.get(
                    f"{self.server_url}/sync/download_chunk/{chunk_hash}",
                    headers=self.headers
                )
                # file_data += resp.content
        
        # Write reconstructed file
        # with open(abs_path, 'wb') as f:
        #     f.write(file_data)
        
        # Update local DB
        self.local_db.upsert_file(LocalFileEntry(
            file_path=rel_path,
            is_directory=False,
            file_hash=hashlib.sha256(''.join(chunk_hashes).encode()).hexdigest(),
            chunk_hashes=chunk_hashes,
            size_bytes=0,  # would be calculated
            local_modified_at=time.time(),
            server_version=version,
            sync_status='synced'
        ))
    
    # ─────────────────────────────────
    # MAIN LOOP
    # ─────────────────────────────────
    
    def start(self):
        """Start the sync engine with upload and download threads."""
        print(f"[SYNC] Starting sync engine for: {self.sync_folder}")
        
        # Start file watcher
        self.observer = start_watcher(self.sync_folder, self.change_queue)
        
        # Start upload processor thread
        upload_thread = Thread(target=self._upload_loop, daemon=True)
        upload_thread.start()
        
        # Start download poller thread
        download_thread = Thread(target=self._download_loop, daemon=True)
        download_thread.start()
        
        return upload_thread, download_thread
    
    def _upload_loop(self):
        """Process local changes in a loop."""
        # Debounce: wait a bit to batch rapid changes
        DEBOUNCE_SECONDS = 2
        
        while not self.stop_event.is_set():
            try:
                event = self.change_queue.get(timeout=1)
                
                # Simple debounce: wait for more events
                time.sleep(DEBOUNCE_SECONDS)
                
                # Collect all pending events
                events = [event]
                while not self.change_queue.empty():
                    try:
                        events.append(self.change_queue.get_nowait())
                    except Empty:
                        break
                
                # Deduplicate: if same file has multiple events, keep last
                latest_events = {}
                for e in events:
                    latest_events[e['path']] = e
                
                # Process each unique file change
                for path, evt in latest_events.items():
                    try:
                        self.handle_local_change(evt)
                    except Exception as ex:
                        print(f"[SYNC] Error processing {path}: {ex}")
                
            except Empty:
                continue
    
    def _download_loop(self):
        """Poll for remote changes periodically."""
        POLL_INTERVAL = 10  # seconds (in production: use WebSocket)
        
        while not self.stop_event.is_set():
            try:
                self.poll_remote_changes()
            except Exception as ex:
                print(f"[SYNC] Error polling remote changes: {ex}")
            
            time.sleep(POLL_INTERVAL)
    
    def stop(self):
        """Stop the sync engine."""
        self.stop_event.set()
        self.observer.stop()
        self.observer.join()
        print("[SYNC] Sync engine stopped.")
```

### 13.6 Notification Service (WebSocket)

```python
import asyncio
import json
from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from typing import Dict, Set
from collections import defaultdict

app = FastAPI(title="Dropbox Notification Service")


class ConnectionManager:
    """
    Manages WebSocket connections for real-time notifications.
    
    When a file changes, the metadata service publishes to Kafka.
    This service consumes from Kafka and pushes to connected clients.
    """
    
    def __init__(self):
        # user_id -> set of active WebSocket connections
        self.active_connections: Dict[str, Set[WebSocket]] = defaultdict(set)
    
    async def connect(self, websocket: WebSocket, user_id: str):
        await websocket.accept()
        self.active_connections[user_id].add(websocket)
        print(f"[WS] User {user_id} connected. "
              f"Total connections: {len(self.active_connections[user_id])}")
    
    def disconnect(self, websocket: WebSocket, user_id: str):
        self.active_connections[user_id].discard(websocket)
        if not self.active_connections[user_id]:
            del self.active_connections[user_id]
        print(f"[WS] User {user_id} disconnected.")
    
    async def notify_user(self, user_id: str, message: dict):
        """Send notification to all devices of a user."""
        if user_id not in self.active_connections:
            return
        
        dead_connections = set()
        
        for ws in self.active_connections[user_id]:
            try:
                await ws.send_json(message)
            except Exception:
                dead_connections.add(ws)
        
        # Clean up dead connections
        for ws in dead_connections:
            self.active_connections[user_id].discard(ws)
    
    async def broadcast_to_user(
        self, 
        user_id: str, 
        message: dict, 
        exclude: WebSocket = None
    ):
        """Notify all devices EXCEPT the one that made the change."""
        if user_id not in self.active_connections:
            return
        
        for ws in self.active_connections[user_id]:
            if ws != exclude:
                try:
                    await ws.send_json(message)
                except Exception:
                    pass


manager = ConnectionManager()


@app.websocket("/ws/sync/{user_id}")
async def websocket_endpoint(websocket: WebSocket, user_id: str):
    """
    WebSocket endpoint for real-time sync notifications.
    
    Client connects and receives notifications when files change
    on other devices.
    """
    await manager.connect(websocket, user_id)
    
    try:
        while True:
            # Keep connection alive, listen for client messages
            data = await websocket.receive_text()
            message = json.loads(data)
            
            if message.get("type") == "ping":
                await websocket.send_json({"type": "pong"})
            
            elif message.get("type") == "subscribe":
                # Client can subscribe to specific folders
                folders = message.get("folders", [])
                print(f"[WS] User {user_id} subscribed to: {folders}")
    
    except WebSocketDisconnect:
        manager.disconnect(websocket, user_id)


# ─── Kafka Consumer (simulated) ───
# In production, this would consume from a Kafka topic

async def simulate_kafka_consumer():
    """
    Simulates consuming file change events from Kafka
    and pushing them to connected WebSocket clients.
    """
    while True:
        await asyncio.sleep(5)
        
        # Simulate receiving a change event
        change_event = {
            "type": "file_changed",
            "user_id": "user123",
            "file_path": "/documents/report.pdf",
            "action": "update",
            "version": 5,
            "timestamp": "2024-01-15T10:30:00Z"
        }
        
        # Push to user's connected devices
        await manager.notify_user(
            change_event["user_id"],
            {
                "type": "sync_update",
                "file_path": change_event["file_path"],
                "action": change_event["action"],
                "version": change_event["version"]
            }
        )


@app.on_event("startup")
async def startup():
    asyncio.create_task(simulate_kafka_consumer())


# ─── Long Polling Fallback ───

@app.get("/longpoll/{user_id}")
async def long_poll(user_id: str, cursor: str = "0", timeout: int = 30):
    """
    Long polling fallback for clients that can't use WebSocket.
    
    Server holds the connection open until either:
    1. A change occurs → return immediately
    2. Timeout (30s) → return empty response
    """
    start_time = time.time()
    
    while time.time() - start_time < timeout:
        # Check if there are new changes
        # In production: check Kafka or change_log
        has_changes = False  # placeholder
        
        if has_changes:
            return {"changes": True, "cursor": "new_cursor"}
        
        await asyncio.sleep(1)
    
    return {"changes": False, "cursor": cursor}
```

### 13.7 Block Server (Chunk Storage Service)

```python
import os
import hashlib
import zlib
import boto3
from fastapi import FastAPI, UploadFile, HTTPException
from fastapi.responses import StreamingResponse
import io

app = FastAPI(title="Dropbox Block Server")


class ChunkStorage:
    """
    Handles the actual storage of file chunks.
    
    Storage hierarchy:
    s3://dropbox-chunks/
    └── ab/                    (first 2 chars of hash)
        └── cd/                (next 2 chars of hash)
            └── abcdef1234...  (full hash as filename)
    
    This distribution prevents too many files in one directory.
    """
    
    def __init__(self, storage_backend: str = "local"):
        self.storage_backend = storage_backend
        
        if storage_backend == "s3":
            self.s3_client = boto3.client('s3')
            self.bucket = 'dropbox-chunks'
        else:
            self.local_path = "/tmp/dropbox_chunks"
            os.makedirs(self.local_path, exist_ok=True)
    
    def _get_storage_path(self, chunk_hash: str) -> str:
        """Generate hierarchical storage path from hash."""
        return f"{chunk_hash[:2]}/{chunk_hash[2:4]}/{chunk_hash}"
    
    def store_chunk(self, chunk_hash: str, data: bytes) -> dict:
        """
        Store a chunk with:
        1. Hash verification
        2. Compression
        3. Encryption (in production)
        """
        # Verify integrity
        computed_hash = hashlib.sha256(data).hexdigest()
        if computed_hash != chunk_hash:
            raise ValueError(
                f"Hash mismatch! Expected {chunk_hash}, got {computed_hash}"
            )
        
        # Compress
        compressed_data = zlib.compress(data, level=6)
        compression_ratio = len(compressed_data) / len(data)
        
        # Store
        storage_path = self._get_storage_path(chunk_hash)
        
        if self.storage_backend == "s3":
            self.s3_client.put_object(
                Bucket=self.bucket,
                Key=storage_path,
                Body=compressed_data,
                Metadata={
                    'original-size': str(len(data)),
                    'compressed-size': str(len(compressed_data)),
                    'sha256': chunk_hash
                }
            )
        else:
            full_path = os.path.join(self.local_path, storage_path)
            os.makedirs(os.path.dirname(full_path), exist_ok=True)
            with open(full_path, 'wb') as f:
                f.write(compressed_data)
        
        return {
            "chunk_hash": chunk_hash,
            "original_size": len(data),
            "compressed_size": len(compressed_data),
            "compression_ratio": f"{compression_ratio:.2%}",
            "storage_path": storage_path
        }
    
    def retrieve_chunk(self, chunk_hash: str) -> bytes:
        """Retrieve and decompress a chunk."""
        storage_path = self._get_storage_path(chunk_hash)
        
        if self.storage_backend == "s3":
            response = self.s3_client.get_object(
                Bucket=self.bucket, Key=storage_path
            )
            compressed_data = response['Body'].read()
        else:
            full_path = os.path.join(self.local_path, storage_path)
            if not os.path.exists(full_path):
                raise FileNotFoundError(f"Chunk {chunk_hash} not found")
            with open(full_path, 'rb') as f:
                compressed_data = f.read()
        
        # Decompress
        data = zlib.decompress(compressed_data)
        
        # Verify integrity
        computed_hash = hashlib.sha256(data).hexdigest()
        if computed_hash != chunk_hash:
            raise ValueError(f"Data corruption detected for chunk {chunk_hash}")
        
        return data
    
    def chunk_exists(self, chunk_hash: str) -> bool:
        """Check if a chunk exists in storage."""
        storage_path = self._get_storage_path(chunk_hash)
        
        if self.storage_backend == "s3":
            try:
                self.s3_client.head_object(Bucket=self.bucket, Key=storage_path)
                return True
            except self.s3_client.exceptions.NoSuchKey:
                return False
        else:
            full_path = os.path.join(self.local_path, storage_path)
            return os.path.exists(full_path)
    
    def delete_chunk(self, chunk_hash: str):
        """Delete a chunk (used when ref_count reaches 0)."""
        storage_path = self._get_storage_path(chunk_hash)
        
        if self.storage_backend == "s3":
            self.s3_client.delete_object(Bucket=self.bucket, Key=storage_path)
        else:
            full_path = os.path.join(self.local_path, storage_path)
            if os.path.exists(full_path):
                os.remove(full_path)


# Initialize storage
chunk_storage = ChunkStorage(storage_backend="local")


@app.put("/chunks/{chunk_hash}")
async def upload_chunk(chunk_hash: str, file: UploadFile):
    """Upload a single chunk."""
    data = await file.read()
    
    try:
        result = chunk_storage.store_chunk(chunk_hash, data)
        return result
    except ValueError as e:
        raise HTTPException(400, str(e))


@app.get("/chunks/{chunk_hash}")
async def download_chunk(chunk_hash: str):
    """Download a single chunk."""
    try:
        data = chunk_storage.retrieve_chunk(chunk_hash)
        return StreamingResponse(
            io.BytesIO(data),
            media_type="application/octet-stream",
            headers={"X-Chunk-Hash": chunk_hash}
        )
    except FileNotFoundError:
        raise HTTPException(404, f"Chunk {chunk_hash} not found")
    except ValueError as e:
        raise HTTPException(500, f"Data corruption: {str(e)}")


@app.head("/chunks/{chunk_hash}")
async def check_chunk(chunk_hash: str):
    """Check if a chunk exists."""
    if chunk_storage.chunk_exists(chunk_hash):
        return {"exists": True}
    raise HTTPException(404)
```

### 13.8 Resumable Upload Manager

```python
import os
import json
import hashlib
from typing import Optional, Dict, List
from dataclasses import dataclass
import time


@dataclass
class UploadSession:
    session_id: str
    file_path: str
    total_size: int
    chunk_hashes: List[str]
    uploaded_chunks: List[str]  # chunks successfully uploaded
    created_at: float
    expires_at: float


class ResumableUploadManager:
    """
    Manages resumable uploads for large files.
    
    If upload is interrupted (network failure, app crash):
    1. Client checks which chunks were already uploaded
    2. Resumes from where it left off
    3. No data re-transmission
    
    This is critical for large files (GB+) on unreliable networks.
    """
    
    def __init__(self, server_url: str, auth_token: str):
        self.server_url = server_url
        self.auth_token = auth_token
        self.sessions: Dict[str, UploadSession] = {}
        self.session_file = os.path.expanduser("~/.dropbox/upload_sessions.json")
        self._load_sessions()
    
    def _load_sessions(self):
        """Load incomplete upload sessions from disk."""
        if os.path.exists(self.session_file):
            with open(self.session_file) as f:
                data = json.load(f)
                for sid, sdata in data.items():
                    self.sessions[sid] = UploadSession(**sdata)
    
    def _save_sessions(self):
        """Persist upload sessions to disk."""
        os.makedirs(os.path.dirname(self.session_file), exist_ok=True)
        data = {}
        for sid, session in self.sessions.items():
            data[sid] = {
                "session_id": session.session_id,
                "file_path": session.file_path,
                "total_size": session.total_size,
                "chunk_hashes": session.chunk_hashes,
                "uploaded_chunks": session.uploaded_chunks,
                "created_at": session.created_at,
                "expires_at": session.expires_at
            }
        with open(self.session_file, 'w') as f:
            json.dump(data, f)
    
    def start_upload(self, file_path: str, chunks: list) -> UploadSession:
        """Start a new upload session."""
        session_id = hashlib.md5(
            f"{file_path}:{time.time()}".encode()
        ).hexdigest()
        
        session = UploadSession(
            session_id=session_id,
            file_path=file_path,
            total_size=sum(c.size for c in chunks),
            chunk_hashes=[c.hash for c in chunks],
            uploaded_chunks=[],
            created_at=time.time(),
            expires_at=time.time() + 7 * 86400  # 7 days
        )
        
        self.sessions[session_id] = session
        self._save_sessions()
        
        print(f"[UPLOAD] Started session {session_id} for {file_path}")
        print(f"[UPLOAD] {len(chunks)} chunks to upload")
        
        return session
    
    def resume_upload(self, session_id: str) -> Optional[UploadSession]:
        """Resume an interrupted upload."""
        session = self.sessions.get(session_id)
        
        if not session:
            print(f"[UPLOAD] Session {session_id} not found")
            return None
        
        if time.time() > session.expires_at:
            print(f"[UPLOAD] Session {session_id} expired")
            del self.sessions[session_id]
            self._save_sessions()
            return None
        
        remaining = set(session.chunk_hashes) - set(session.uploaded_chunks)
        print(f"[UPLOAD] Resuming session {session_id}")
        print(f"[UPLOAD] {len(session.uploaded_chunks)}/{len(session.chunk_hashes)} "
              f"chunks already uploaded, {len(remaining)} remaining")
        
        return session
    
    def mark_chunk_uploaded(self, session_id: str, chunk_hash: str):
        """Mark a chunk as successfully uploaded."""
        session = self.sessions.get(session_id)
        if session and chunk_hash not in session.uploaded_chunks:
            session.uploaded_chunks.append(chunk_hash)
            self._save_sessions()
            
            progress = len(session.uploaded_chunks) / len(session.chunk_hashes) * 100
            print(f"[UPLOAD] Progress: {progress:.1f}%")
    
    def is_complete(self, session_id: str) -> bool:
        """Check if all chunks have been uploaded."""
        session = self.sessions.get(session_id)
        if not session:
            return False
        return set(session.chunk_hashes) == set(session.uploaded_chunks)
    
    def complete_upload(self, session_id: str):
        """Finalize the upload and clean up."""
        if session_id in self.sessions:
            del self.sessions[session_id]
            self._save_sessions()
            print(f"[UPLOAD] Session {session_id} completed and cleaned up")
    
    def get_pending_sessions(self) -> List[UploadSession]:
        """Get all incomplete upload sessions."""
        now = time.time()
        return [
            s for s in self.sessions.values()
            if now < s.expires_at and not self.is_complete(s.session_id)
        ]


# --- Demo ---
if __name__ == "__main__":
    manager = ResumableUploadManager("http://localhost:8000", "token123")
    
    # Simulate starting an upload
    chunker = FileChunker()
    
    # Create test file
    test_data = os.urandom(20 * 1024 * 1024)  # 20 MB
    with open("/tmp/large_file.bin", "wb") as f:
        f.write(test_data)
    
    chunks = chunker.chunk_file("/tmp/large_file.bin")
    session = manager.start_upload("/tmp/large_file.bin", chunks)
    
    # Simulate uploading first 2 chunks, then "crash"
    for chunk in chunks[:2]:
        manager.mark_chunk_uploaded(session.session_id, chunk.hash)
    
    print("\n--- Simulating crash and resume ---\n")
    
    # Resume
    resumed = manager.resume_upload(session.session_id)
    if resumed:
        remaining = set(resumed.chunk_hashes) - set(resumed.uploaded_chunks)
        for chunk in chunks:
            if chunk.hash in remaining:
                manager.mark_chunk_uploaded(session.session_id, chunk.hash)
        
        if manager.is_complete(session.session_id):
            manager.complete_upload(session.session_id)
```

### 13.9 Complete Client Integration

```python
"""
Putting it all together: The complete Dropbox client.
"""

class DropboxClient:
    """
    Main Dropbox client that integrates all components:
    - File Watcher
    - Chunker
    - Sync Engine
    - Local DB
    - Resumable Upload Manager
    """
    
    def __init__(
        self,
        sync_folder: str,
        server_url: str = "http://localhost:8000",
        auth_token: str = "user123"
    ):
        self.sync_folder = os.path.abspath(sync_folder)
        os.makedirs(self.sync_folder, exist_ok=True)
        
        # Initialize components
        self.local_db = LocalMetadataDB(
            os.path.join(self.sync_folder, ".dropbox", "metadata.db")
        )
        self.chunker = FileChunker()
        self.upload_manager = ResumableUploadManager(server_url, auth_token)
        self.sync_engine = SyncEngine(
            sync_folder=self.sync_folder,
            server_url=server_url,
            auth_token=auth_token,
            local_db=self.local_db
        )
    
    def start(self):
        """Start the Dropbox client."""
        print("=" * 60)
        print(f"  Dropbox Client Starting")
        print(f"  Sync Folder: {self.sync_folder}")
        print("=" * 60)
        
        # 1. Initial sync — download any remote changes
        print("\n[INIT] Performing initial sync...")
        self.sync_engine.poll_remote_changes()
        
        # 2. Check for interrupted uploads
        pending = self.upload_manager.get_pending_sessions()
        if pending:
            print(f"\n[INIT] Resuming {len(pending)} interrupted uploads...")
            for session in pending:
                self.upload_manager.resume_upload(session.session_id)
        
        # 3. Start continuous sync
        print("\n[INIT] Starting continuous sync...")
        self.sync_engine.start()
        
        print("\n[READY] Dropbox is running! Watching for changes...")
    
    def stop(self):
        """Stop the client gracefully."""
        self.sync_engine.stop()
        self.local_db.close()
        print("\n[STOP] Dropbox client stopped.")
    
    def get_status(self) -> dict:
        """Get current sync status."""
        pending = self.local_db.get_pending_uploads()
        cursor = self.local_db.get_cursor()
        
        return {
            "sync_folder": self.sync_folder,
            "pending_uploads": len(pending),
            "last_cursor": cursor,
            "active_upload_sessions": len(
                self.upload_manager.get_pending_sessions()
            )
        }


# --- Run the client ---
if __name__ == "__main__":
    import tempfile
    
    sync_folder = tempfile.mkdtemp(prefix="my_dropbox_")
    
    client = DropboxClient(
        sync_folder=sync_folder,
        server_url="http://localhost:8000",
        auth_token="user123"
    )
    
    try:
        client.start()
        
        # Keep running
        while True:
            time.sleep(10)
            status = client.get_status()
            print(f"\n[STATUS] {status}")
    
    except KeyboardInterrupt:
        client.stop()
```

---

## 14. Failure Handling & Reliability <a name="14-failures"></a>

```
┌──────────────────────────────────────────────────────────────────┐
│                    FAILURE SCENARIOS                              │
│                                                                   │
│  ┌─────────────────────┬────────────────────────────────────┐    │
│  │ Failure             │ Handling Strategy                   │    │
│  ├─────────────────────┼────────────────────────────────────┤    │
│  │ Network drops       │ Resumable uploads; retry with      │    │
│  │ during upload       │ exponential backoff; local queue   │    │
│  ├─────────────────────┼────────────────────────────────────┤    │
│  │ Client crashes      │ Upload sessions persisted to disk; │    │
│  │                     │ resume on restart                  │    │
│  ├─────────────────────┼────────────────────────────────────┤    │
│  │ Metadata DB down    │ Read replicas; failover to         │    │
│  │                     │ standby; client retries            │    │
│  ├─────────────────────┼────────────────────────────────────┤    │
│  │ S3/Cloud storage    │ Multi-region replication; S3       │    │
│  │ failure             │ provides 11 nines durability       │    │
│  ├─────────────────────┼────────────────────────────────────┤    │
│  │ Chunk corruption    │ SHA-256 verification on every      │    │
│  │                     │ read; re-download if mismatch      │    │
│  ├─────────────────────┼────────────────────────────────────┤    │
│  │ Concurrent edits    │ Optimistic locking (version check) │    │
│  │ (conflict)          │ + conflicted copies                │    │
│  ├─────────────────────┼────────────────────────────────────┤    │
│  │ Message queue       │ Persistent topics; consumer        │    │
│  │ failure             │ offsets; at-least-once delivery    │    │
│  ├─────────────────────┼────────────────────────────────────┤    │
│  │ Notification        │ Clients fall back to polling;      │    │
│  │ service down        │ delta sync catches up              │    │
│  └─────────────────────┴────────────────────────────────────┘    │
│                                                                   │
│  Replication Strategy:                                            │
│  ┌────────────────────────────────────────────────────────────┐   │
│  │ • Metadata DB: Primary-Replica (sync replication)          │   │
│  │ • Chunks in S3: Cross-region replication (automatic)       │   │
│  │ • Kafka: 3x replication factor, min.insync.replicas=2     │   │
│  │ • Cache (Redis): Redis Sentinel or Redis Cluster           │   │
│  └────────────────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────────────┘
```

---

## 15. Final Architecture Diagram <a name="15-final"></a>

```
                        ┌─────────────────────────────────────┐
                        │           CLIENTS                    │
                        │  ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐  │
                        │  │ PC  │ │ Mac │ │ iOS │ │ Web │  │
                        │  └──┬──┘ └──┬──┘ └──┬──┘ └──┬──┘  │
                        │     │  Sync │Engine │       │      │
                        │  ┌──┴──────┴──────┴───────┴──┐    │
                        │  │Watcher│Chunker│Indexer│DB  │    │
                        │  └───────────────┬────────────┘    │
                        └──────────────────┼─────────────────┘
                                           │
                                    ┌──────┴──────┐
                                    │     CDN     │
                                    │(CloudFront) │
                                    └──────┬──────┘
                                           │
                               ┌───────────┴───────────┐
                               │   LOAD BALANCER (L7)   │
                               │   (AWS ALB / Nginx)    │
                               └───┬───────┬───────┬───┘
                                   │       │       │
                    ┌──────────────┘       │       └──────────────┐
                    ▼                      ▼                      ▼
           ┌────────────────┐    ┌────────────────┐    ┌──────────────────┐
           │  API Gateway   │    │  Block Server   │    │  Notification    │
           │  ┌──────────┐  │    │  (Chunk Upload/ │    │  Service         │
           │  │Auth/Rate │  │    │   Download)     │    │  (WebSocket/     │
           │  │Limit/    │  │    │                 │    │   Long Poll)     │
           │  │Route     │  │    │  ┌───────────┐  │    │                  │
           │  └──────────┘  │    │  │Compression│  │    │  Consumes from   │
           └───────┬────────┘    │  │Encryption │  │    │  Kafka           │
                   │             │  │Validation │  │    └────────┬─────────┘
                   │             │  └───────────┘  │             │
                   ▼             └────────┬────────┘             │
          ┌────────────────┐              │                      │
          │ Metadata       │              ▼                      │
          │ Service        │    ┌──────────────────┐             │
          │                │    │   Cloud Storage   │             │
          │ ┌────────────┐ │    │   (Amazon S3)     │             │
          │ │ MySQL/     │ │    │                   │             │
          │ │ PostgreSQL │ │    │  ┌─────────────┐  │             │
          │ │ (Primary + │ │    │  │ ab/cd/hash1 │  │             │
          │ │  Replicas) │ │    │  │ ef/gh/hash2 │  │             │
          │ └──────┬─────┘ │    │  │ ...         │  │             │
          │        │       │    │  └─────────────┘  │             │
          │ ┌──────┴─────┐ │    │                   │             │
          │ │   Redis    │ │    │  99.999999999%    │             │
          │ │   Cache    │ │    │  durability       │             │
          │ └────────────┘ │    └──────────────────┘             │
          │                │                                      │
          │ Publishes to ──┼──────────┐                          │
          └────────────────┘          │                          │
                                      ▼                          │
                            ┌──────────────────┐                │
                            │   Message Queue   │────────────────┘
                            │   (Apache Kafka)  │
                            │                   │
                            │  Topics:          │
                            │  - file_changes   │
                            │  - sync_events    │
                            │  - notifications  │
                            └──────────────────┘

    ┌───────────────────────────────────────────────────────────────┐
    │                    SUPPORTING SERVICES                        │
    │                                                               │
    │  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────────┐ │
    │  │ User     │  │ Sharing  │  │ Garbage  │  │ Analytics    │ │
    │  │ Service  │  │ Service  │  │ Collector│  │ Service      │ │
    │  │          │  │          │  │(orphaned │  │              │ │
    │  │ Auth,    │  │ ACLs,    │  │ chunks   │  │ Usage stats, │ │
    │  │ Quota,   │  │ Links,   │  │ cleanup) │  │ metrics      │ │
    │  │ Profile  │  │ Perms    │  │          │  │              │ │
    │  └──────────┘  └──────────┘  └──────────┘  └──────────────┘ │
    └───────────────────────────────────────────────────────────────┘
```

### Key Design Decisions Summary

```
┌────────────────────────────────────────────────────────────────────┐
│ Decision                │ Choice              │ Why                │
├─────────────────────────┼─────────────────────┼────────────────────┤
│ Chunking strategy       │ Content-defined     │ Minimal re-upload  │
│                         │ (4MB target)        │ on small changes   │
├─────────────────────────┼─────────────────────┼────────────────────┤
│ Chunk storage           │ S3 / GCS            │ 11 nines durability│
│                         │                     │ infinite scale     │
├─────────────────────────┼─────────────────────┼────────────────────┤
│ Metadata store          │ MySQL/Postgres      │ ACID, strong       │
│                         │ (sharded)           │ consistency        │
├─────────────────────────┼─────────────────────┼────────────────────┤
│ Cache                   │ Redis               │ Hot metadata       │
├─────────────────────────┼─────────────────────┼────────────────────┤
│ Message queue           │ Kafka               │ Durable, ordered,  │
│                         │                     │ high throughput     │
├─────────────────────────┼─────────────────────┼────────────────────┤
│ Notifications           │ WebSocket + fallback│ Real-time + compat │
├─────────────────────────┼─────────────────────┼────────────────────┤
│ Sync protocol           │ Delta sync (cursor) │ Bandwidth efficient│
├─────────────────────────┼─────────────────────┼────────────────────┤
│ Conflict resolution     │ Conflicted copies   │ No data loss,      │
│                         │                     │ user decides       │
├─────────────────────────┼─────────────────────┼────────────────────┤
│ Deduplication           │ Content-addressable  │ Massive storage    │
│                         │ (hash-based)        │ savings            │
├─────────────────────────┼─────────────────────┼────────────────────┤
│ Upload strategy         │ Resumable + chunked │ Handles failures   │
│                         │                     │ gracefully         │
├─────────────────────────┼─────────────────────┼────────────────────┤
│ Partitioning            │ By workspace_id     │ Co-locate related  │
│                         │                     │ data               │
└─────────────────────────┴─────────────────────┴────────────────────┘
```

This design handles **500M+ users**, provides **near real-time sync**, minimizes **bandwidth** through chunking and deduplication, and ensures **zero data loss** through S3's durability and metadata replication.



# Backend Infrastructure Design (HLD) — Complete Guide

---

## 17. API Gateway

---

### What & Why

An API Gateway is the **single entry point** for all client requests. It handles routing, rate limiting, authentication, load balancing, request transformation, and circuit breaking.

```
┌─────────────────────────────────────────────────────────────────┐
│                        CLIENTS                                  │
│         Web App    Mobile App    Partner APIs    IoT             │
└──────────────────────────┬──────────────────────────────────────┘
                           │
                           ▼
┌──────────────────────────────────────────────────────────────────┐
│                       API GATEWAY                                │
│                                                                  │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌───────────────────┐   │
│  │  Rate    │ │  Auth    │ │ Request  │ │  Circuit          │   │
│  │ Limiter  │ │ Checker  │ │ Router   │ │  Breaker          │   │
│  └──────────┘ └──────────┘ └──────────┘ └───────────────────┘   │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌───────────────────┐   │
│  │ Request  │ │ Response │ │  Load    │ │  Logging &        │   │
│  │Transform │ │ Cache    │ │ Balancer │ │  Metrics          │   │
│  └──────────┘ └──────────┘ └──────────┘ └───────────────────┘   │
└──────────────────────────┬──────────────────────────────────────┘
                           │
            ┌──────────────┼──────────────┐
            ▼              ▼              ▼
     ┌────────────┐ ┌────────────┐ ┌────────────┐
     │  User      │ │  Order     │ │  Payment   │
     │  Service   │ │  Service   │ │  Service   │
     └────────────┘ └────────────┘ └────────────┘
```

### Detailed Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                       API GATEWAY INTERNALS                         │
│                                                                     │
│   REQUEST PIPELINE                                                  │
│   ═══════════════                                                   │
│                                                                     │
│   Client Request                                                    │
│        │                                                            │
│        ▼                                                            │
│   ┌─────────────────┐                                               │
│   │  TLS Termination│  ← SSL/TLS offloading                        │
│   └────────┬────────┘                                               │
│            ▼                                                        │
│   ┌─────────────────┐     ┌──────────────┐                          │
│   │  Rate Limiter   │────▶│ Redis Cluster│  (token bucket/sliding)  │
│   └────────┬────────┘     └──────────────┘                          │
│            ▼                                                        │
│   ┌─────────────────┐     ┌──────────────┐                          │
│   │  Authentication │────▶│ Auth Service │  (JWT/OAuth validation)  │
│   └────────┬────────┘     └──────────────┘                          │
│            ▼                                                        │
│   ┌─────────────────┐     ┌──────────────┐                          │
│   │  Authorization  │────▶│ Policy Engine│  (RBAC/ABAC check)      │
│   └────────┬────────┘     └──────────────┘                          │
│            ▼                                                        │
│   ┌─────────────────┐                                               │
│   │ Request         │  ← Header injection, body transform          │
│   │ Transformation  │                                               │
│   └────────┬────────┘                                               │
│            ▼                                                        │
│   ┌─────────────────┐     ┌──────────────┐                          │
│   │  Response Cache │────▶│ Redis/Local  │  (cache GET responses)   │
│   └────────┬────────┘     └──────────────┘                          │
│            ▼                                                        │
│   ┌─────────────────┐     ┌──────────────┐                          │
│   │  Circuit Breaker│────▶│ State Store  │  (OPEN/HALF/CLOSED)     │
│   └────────┬────────┘     └──────────────┘                          │
│            ▼                                                        │
│   ┌─────────────────┐     ┌──────────────────────┐                  │
│   │  Load Balancer  │────▶│ Service Registry     │                  │
│   │  + Router       │     │ (Consul/etcd/ZK)     │                  │
│   └────────┬────────┘     └──────────────────────┘                  │
│            ▼                                                        │
│   ┌─────────────────┐                                               │
│   │ Upstream Proxy  │ ──────▶  Backend Microservices                │
│   └─────────────────┘                                               │
│                                                                     │
│   ┌─────────────────┐     ┌──────────────────────┐                  │
│   │ Observability   │────▶│ Prometheus/Grafana   │                  │
│   │ (Metrics, Logs) │     │ ELK/Jaeger           │                  │
│   └─────────────────┘     └──────────────────────┘                  │
└─────────────────────────────────────────────────────────────────────┘
```

### Python Implementation

```python
"""
Full API Gateway Implementation
"""
import time
import asyncio
import hashlib
import json
import logging
from enum import Enum
from dataclasses import dataclass, field
from typing import Dict, List, Optional, Callable, Any
from collections import defaultdict
import aiohttp
from fastapi import FastAPI, Request, Response, HTTPException
from fastapi.middleware.cors import CORSMiddleware
import redis.asyncio as redis
import jwt

logger = logging.getLogger("api_gateway")

# ─────────────────────────────────────────────────
# 1. RATE LIMITER  (Sliding Window + Token Bucket)
# ─────────────────────────────────────────────────
class RateLimitAlgorithm(Enum):
    TOKEN_BUCKET = "token_bucket"
    SLIDING_WINDOW = "sliding_window"

class RateLimiter:
    """Distributed rate limiter using Redis."""

    def __init__(self, redis_client: redis.Redis):
        self.redis = redis_client
        # Lua script for atomic sliding window
        self.sliding_window_script = """
        local key = KEYS[1]
        local window = tonumber(ARGV[1])
        local max_requests = tonumber(ARGV[2])
        local now = tonumber(ARGV[3])
        
        -- Remove old entries outside the window
        redis.call('ZREMRANGEBYSCORE', key, 0, now - window)
        
        -- Count current requests
        local current = redis.call('ZCARD', key)
        
        if current < max_requests then
            redis.call('ZADD', key, now, now .. '-' .. math.random(1000000))
            redis.call('EXPIRE', key, window)
            return 1  -- allowed
        else
            return 0  -- denied
        end
        """
        self._script_sha = None

    async def _ensure_script(self):
        if self._script_sha is None:
            self._script_sha = await self.redis.script_load(
                self.sliding_window_script
            )

    async def is_allowed(
        self,
        identifier: str,
        max_requests: int = 100,
        window_seconds: int = 60
    ) -> dict:
        await self._ensure_script()
        key = f"ratelimit:{identifier}"
        now = time.time()

        allowed = await self.redis.evalsha(
            self._script_sha,
            1, key,
            window_seconds, max_requests, now
        )

        current_count = await self.redis.zcard(key)
        return {
            "allowed": bool(allowed),
            "remaining": max(0, max_requests - current_count),
            "reset_at": int(now + window_seconds),
            "limit": max_requests
        }


# ─────────────────────────────────────────────────
# 2. CIRCUIT BREAKER
# ─────────────────────────────────────────────────
class CircuitState(Enum):
    CLOSED = "closed"         # Normal operation
    OPEN = "open"             # Failing — reject all
    HALF_OPEN = "half_open"   # Testing recovery

@dataclass
class CircuitBreaker:
    """Per-service circuit breaker."""
    service_name: str
    failure_threshold: int = 5
    recovery_timeout: float = 30.0
    half_open_max_calls: int = 3

    state: CircuitState = CircuitState.CLOSED
    failure_count: int = 0
    success_count: int = 0
    last_failure_time: float = 0.0
    half_open_calls: int = 0

    def can_execute(self) -> bool:
        if self.state == CircuitState.CLOSED:
            return True

        if self.state == CircuitState.OPEN:
            # Check if recovery timeout has elapsed
            if time.time() - self.last_failure_time >= self.recovery_timeout:
                self.state = CircuitState.HALF_OPEN
                self.half_open_calls = 0
                logger.info(f"Circuit {self.service_name}: OPEN → HALF_OPEN")
                return True
            return False

        if self.state == CircuitState.HALF_OPEN:
            return self.half_open_calls < self.half_open_max_calls

        return False

    def record_success(self):
        if self.state == CircuitState.HALF_OPEN:
            self.success_count += 1
            if self.success_count >= self.half_open_max_calls:
                self.state = CircuitState.CLOSED
                self.failure_count = 0
                self.success_count = 0
                logger.info(f"Circuit {self.service_name}: HALF_OPEN → CLOSED")
        else:
            self.failure_count = 0

    def record_failure(self):
        self.failure_count += 1
        self.last_failure_time = time.time()

        if self.state == CircuitState.HALF_OPEN:
            self.state = CircuitState.OPEN
            logger.warning(f"Circuit {self.service_name}: HALF_OPEN → OPEN")
        elif self.failure_count >= self.failure_threshold:
            self.state = CircuitState.OPEN
            logger.warning(f"Circuit {self.service_name}: CLOSED → OPEN")


# ─────────────────────────────────────────────────
# 3. SERVICE REGISTRY & LOAD BALANCER
# ─────────────────────────────────────────────────
@dataclass
class ServiceInstance:
    host: str
    port: int
    weight: int = 1
    healthy: bool = True
    active_connections: int = 0

    @property
    def url(self) -> str:
        return f"http://{self.host}:{self.port}"

class LoadBalancingStrategy(Enum):
    ROUND_ROBIN = "round_robin"
    LEAST_CONNECTIONS = "least_connections"
    WEIGHTED_ROUND_ROBIN = "weighted_round_robin"

class ServiceRegistry:
    """In-memory service registry with health checks."""

    def __init__(self):
        self.services: Dict[str, List[ServiceInstance]] = {}
        self._rr_counters: Dict[str, int] = defaultdict(int)

    def register(self, service_name: str, instance: ServiceInstance):
        if service_name not in self.services:
            self.services[service_name] = []
        self.services[service_name].append(instance)
        logger.info(f"Registered {service_name} → {instance.url}")

    def deregister(self, service_name: str, host: str, port: int):
        if service_name in self.services:
            self.services[service_name] = [
                inst for inst in self.services[service_name]
                if not (inst.host == host and inst.port == port)
            ]

    def get_instance(
        self,
        service_name: str,
        strategy: LoadBalancingStrategy = LoadBalancingStrategy.ROUND_ROBIN
    ) -> Optional[ServiceInstance]:
        instances = [
            i for i in self.services.get(service_name, []) if i.healthy
        ]
        if not instances:
            return None

        if strategy == LoadBalancingStrategy.ROUND_ROBIN:
            idx = self._rr_counters[service_name] % len(instances)
            self._rr_counters[service_name] += 1
            return instances[idx]

        elif strategy == LoadBalancingStrategy.LEAST_CONNECTIONS:
            return min(instances, key=lambda i: i.active_connections)

        elif strategy == LoadBalancingStrategy.WEIGHTED_ROUND_ROBIN:
            # Simple weighted selection
            total = sum(i.weight for i in instances)
            counter = self._rr_counters[service_name] % total
            self._rr_counters[service_name] += 1
            cumulative = 0
            for inst in instances:
                cumulative += inst.weight
                if counter < cumulative:
                    return inst
        return instances[0]

    async def health_check_loop(self, interval: int = 10):
        """Periodically check health of all service instances."""
        while True:
            async with aiohttp.ClientSession(
                timeout=aiohttp.ClientTimeout(total=3)
            ) as session:
                for svc_name, instances in self.services.items():
                    for inst in instances:
                        try:
                            async with session.get(
                                f"{inst.url}/health"
                            ) as resp:
                                inst.healthy = resp.status == 200
                        except Exception:
                            inst.healthy = False
            await asyncio.sleep(interval)


# ─────────────────────────────────────────────────
# 4. RESPONSE CACHE
# ─────────────────────────────────────────────────
class ResponseCache:
    """Cache GET responses in Redis."""

    def __init__(self, redis_client: redis.Redis, default_ttl: int = 60):
        self.redis = redis_client
        self.default_ttl = default_ttl

    def _cache_key(self, method: str, path: str, query: str) -> str:
        raw = f"{method}:{path}:{query}"
        return f"cache:{hashlib.sha256(raw.encode()).hexdigest()}"

    async def get(self, method: str, path: str, query: str) -> Optional[dict]:
        if method != "GET":
            return None
        key = self._cache_key(method, path, query)
        cached = await self.redis.get(key)
        if cached:
            return json.loads(cached)
        return None

    async def set(
        self, method: str, path: str, query: str,
        status_code: int, body: bytes, headers: dict,
        ttl: Optional[int] = None
    ):
        if method != "GET" or status_code != 200:
            return
        key = self._cache_key(method, path, query)
        data = {
            "status_code": status_code,
            "body": body.decode("utf-8", errors="replace"),
            "headers": dict(headers),
        }
        await self.redis.setex(key, ttl or self.default_ttl, json.dumps(data))


# ─────────────────────────────────────────────────
# 5. REQUEST TRANSFORMER
# ─────────────────────────────────────────────────
class RequestTransformer:
    """Transform requests before forwarding."""

    def __init__(self):
        self.transformations: List[Callable] = []

    def add_transformation(self, fn: Callable):
        self.transformations.append(fn)

    async def transform(
        self, headers: dict, body: bytes, path: str
    ) -> tuple:
        for fn in self.transformations:
            headers, body, path = await fn(headers, body, path)
        return headers, body, path


# ─────────────────────────────────────────────────
# 6. ROUTE CONFIG
# ─────────────────────────────────────────────────
@dataclass
class RouteConfig:
    path_prefix: str
    service_name: str
    strip_prefix: bool = True
    rate_limit: int = 100            # requests per window
    rate_limit_window: int = 60      # seconds
    cache_ttl: int = 0               # 0 = no cache
    require_auth: bool = True
    allowed_methods: List[str] = field(
        default_factory=lambda: ["GET", "POST", "PUT", "DELETE"]
    )
    timeout: float = 30.0


# ─────────────────────────────────────────────────
# 7. MAIN API GATEWAY
# ─────────────────────────────────────────────────
class APIGateway:
    def __init__(self, redis_url: str = "redis://localhost:6379"):
        self.app = FastAPI(title="API Gateway")
        self.redis_url = redis_url
        self.redis_client: Optional[redis.Redis] = None

        self.rate_limiter: Optional[RateLimiter] = None
        self.cache: Optional[ResponseCache] = None
        self.registry = ServiceRegistry()
        self.circuit_breakers: Dict[str, CircuitBreaker] = {}
        self.transformer = RequestTransformer()
        self.routes: List[RouteConfig] = []

        self._setup_middleware()
        self._setup_events()
        self._setup_catch_all()

    def _setup_middleware(self):
        self.app.add_middleware(
            CORSMiddleware,
            allow_origins=["*"],
            allow_methods=["*"],
            allow_headers=["*"],
        )

    def _setup_events(self):
        @self.app.on_event("startup")
        async def startup():
            self.redis_client = redis.from_url(self.redis_url)
            self.rate_limiter = RateLimiter(self.redis_client)
            self.cache = ResponseCache(self.redis_client)
            # Start health checks
            asyncio.create_task(self.registry.health_check_loop())

        @self.app.on_event("shutdown")
        async def shutdown():
            if self.redis_client:
                await self.redis_client.close()

    def add_route(self, config: RouteConfig):
        self.routes.append(config)
        if config.service_name not in self.circuit_breakers:
            self.circuit_breakers[config.service_name] = CircuitBreaker(
                service_name=config.service_name
            )

    def _match_route(self, path: str) -> Optional[RouteConfig]:
        for route in sorted(self.routes, key=lambda r: -len(r.path_prefix)):
            if path.startswith(route.path_prefix):
                return route
        return None

    def _setup_catch_all(self):
        @self.app.api_route(
            "/{path:path}", methods=["GET","POST","PUT","DELETE","PATCH"]
        )
        async def gateway_handler(request: Request, path: str):
            full_path = f"/{path}"

            # ── 1. Route Matching ──
            route = self._match_route(full_path)
            if not route:
                raise HTTPException(404, "No route matched")

            if request.method not in route.allowed_methods:
                raise HTTPException(405, "Method not allowed")

            # ── 2. Rate Limiting ──
            client_ip = request.client.host
            rl_key = f"{client_ip}:{route.path_prefix}"
            rl_result = await self.rate_limiter.is_allowed(
                rl_key, route.rate_limit, route.rate_limit_window
            )
            if not rl_result["allowed"]:
                return Response(
                    content=json.dumps({"error": "Rate limit exceeded"}),
                    status_code=429,
                    headers={
                        "X-RateLimit-Limit": str(rl_result["limit"]),
                        "X-RateLimit-Remaining": str(rl_result["remaining"]),
                        "X-RateLimit-Reset": str(rl_result["reset_at"]),
                        "Retry-After": str(route.rate_limit_window),
                    }
                )

            # ── 3. Authentication ──
            if route.require_auth:
                auth_header = request.headers.get("Authorization", "")
                if not auth_header.startswith("Bearer "):
                    raise HTTPException(401, "Missing auth token")
                token = auth_header.split(" ", 1)[1]
                try:
                    payload = jwt.decode(
                        token, "SECRET_KEY", algorithms=["HS256"]
                    )
                except jwt.InvalidTokenError:
                    raise HTTPException(401, "Invalid token")

            # ── 4. Cache Check ──
            query_str = str(request.query_params)
            if route.cache_ttl > 0:
                cached = await self.cache.get(
                    request.method, full_path, query_str
                )
                if cached:
                    return Response(
                        content=cached["body"],
                        status_code=cached["status_code"],
                        headers={**cached["headers"], "X-Cache": "HIT"}
                    )

            # ── 5. Circuit Breaker Check ──
            cb = self.circuit_breakers[route.service_name]
            if not cb.can_execute():
                raise HTTPException(
                    503,
                    f"Service {route.service_name} unavailable (circuit open)"
                )

            # ── 6. Service Discovery + Load Balance ──
            instance = self.registry.get_instance(route.service_name)
            if not instance:
                raise HTTPException(
                    503, f"No healthy instances for {route.service_name}"
                )

            # ── 7. Build Upstream URL ──
            upstream_path = full_path
            if route.strip_prefix:
                upstream_path = full_path[len(route.path_prefix):]
                if not upstream_path.startswith("/"):
                    upstream_path = "/" + upstream_path

            upstream_url = f"{instance.url}{upstream_path}"
            if query_str:
                upstream_url += f"?{query_str}"

            # ── 8. Forward Request ──
            body = await request.body()
            headers = dict(request.headers)
            headers.pop("host", None)

            # Transform
            headers, body, upstream_path = await self.transformer.transform(
                headers, body, upstream_path
            )

            instance.active_connections += 1
            start = time.time()

            try:
                async with aiohttp.ClientSession(
                    timeout=aiohttp.ClientTimeout(total=route.timeout)
                ) as session:
                    async with session.request(
                        method=request.method,
                        url=upstream_url,
                        headers=headers,
                        data=body,
                    ) as upstream_resp:
                        resp_body = await upstream_resp.read()
                        resp_headers = dict(upstream_resp.headers)

                        cb.record_success()

                        # Cache response if configured
                        if route.cache_ttl > 0:
                            await self.cache.set(
                                request.method, full_path, query_str,
                                upstream_resp.status, resp_body,
                                resp_headers, route.cache_ttl
                            )

                        latency = time.time() - start
                        logger.info(
                            f"{request.method} {full_path} → "
                            f"{route.service_name} {upstream_resp.status} "
                            f"{latency:.3f}s"
                        )

                        return Response(
                            content=resp_body,
                            status_code=upstream_resp.status,
                            headers={
                                **resp_headers,
                                "X-Gateway-Latency": f"{latency:.3f}",
                                "X-Cache": "MISS",
                            }
                        )

            except asyncio.TimeoutError:
                cb.record_failure()
                raise HTTPException(504, "Upstream timeout")
            except Exception as e:
                cb.record_failure()
                raise HTTPException(502, f"Upstream error: {str(e)}")
            finally:
                instance.active_connections -= 1


# ─────────────────────────────────────────────────
# Usage
# ─────────────────────────────────────────────────
gateway = APIGateway()

# Register backend services
gateway.registry.register("user-service", ServiceInstance("10.0.1.1", 8001))
gateway.registry.register("user-service", ServiceInstance("10.0.1.2", 8001))
gateway.registry.register("order-service", ServiceInstance("10.0.2.1", 8002))

# Define routes
gateway.add_route(RouteConfig(
    path_prefix="/api/users",
    service_name="user-service",
    rate_limit=200,
    cache_ttl=30,
))
gateway.add_route(RouteConfig(
    path_prefix="/api/orders",
    service_name="order-service",
    rate_limit=100,
    cache_ttl=0,
))

app = gateway.app
# Run: uvicorn main:app --host 0.0.0.0 --port 8080
```

### Key Design Decisions

| Concern | Decision | Rationale |
|---|---|---|
| Rate Limiting | Redis + Lua sliding window | Atomic, distributed, precise |
| Circuit Breaker | Per-service in-memory | Fast check, no network hop |
| Service Discovery | Registry + health checks | Decouple from DNS TTL issues |
| Caching | Redis with content hash key | Shared across gateway replicas |
| Load Balancing | Round-robin / Least-conn | Pluggable strategies |

---

## 18. Authentication & Authorization System

---

### Architecture

```
┌────────────────────────────────────────────────────────────────────────┐
│                    AUTH SYSTEM ARCHITECTURE                             │
│                                                                        │
│  ┌──────────┐    ┌──────────────────────────────────────────┐          │
│  │  Client  │───▶│             API Gateway                  │          │
│  └──────────┘    └──────────┬───────────────────────────────┘          │
│                             │                                          │
│              ┌──────────────┼──────────────────┐                       │
│              ▼              ▼                  ▼                        │
│  ┌────────────────┐ ┌──────────────┐ ┌──────────────────┐              │
│  │  Auth Service  │ │ User Service │ │ Resource Services│              │
│  │                │ │              │ │                  │              │
│  │ • Login        │ │ • Profile    │ │ • Enforce AuthZ  │              │
│  │ • Register     │ │ • Password   │ │ • Check perms    │              │
│  │ • Token issue  │ │ • MFA        │ │                  │              │
│  │ • Token refresh│ │              │ │                  │              │
│  │ • OAuth flows  │ │              │ │                  │              │
│  └───────┬────────┘ └──────┬───────┘ └──────────────────┘              │
│          │                 │                                            │
│          ▼                 ▼                                            │
│  ┌───────────────────────────────────────────────────────┐              │
│  │                    DATA STORES                        │              │
│  │                                                       │              │
│  │  ┌──────────────┐  ┌───────────────┐  ┌────────────┐ │              │
│  │  │  PostgreSQL  │  │  Redis        │  │  Vault     │ │              │
│  │  │  • Users     │  │  • Sessions   │  │  • Secrets │ │              │
│  │  │  • Roles     │  │  • Revoked    │  │  • Keys    │ │              │
│  │  │  • Perms     │  │    tokens     │  │  • Certs   │ │              │
│  │  │  • Audit log │  │  • Rate limit │  │            │ │              │
│  │  └──────────────┘  └───────────────┘  └────────────┘ │              │
│  └───────────────────────────────────────────────────────┘              │
└────────────────────────────────────────────────────────────────────────┘
```

### Token Flow

```
  ┌─────────────────── AUTHENTICATION FLOW ───────────────────┐
  │                                                            │
  │  1. Login                                                  │
  │  Client ──POST /auth/login──▶ Auth Service                 │
  │         { email, password }                                │
  │                                                            │
  │  2. Validate credentials                                   │
  │  Auth Service ──query──▶ User DB (bcrypt verify)           │
  │                                                            │
  │  3. Check MFA (if enabled)                                 │
  │  Auth Service ──▶ TOTP verify / SMS verify                 │
  │                                                            │
  │  4. Issue tokens                                           │
  │  Auth Service ──▶ Client                                   │
  │  {                                                         │
  │    access_token:  JWT (15 min TTL),                        │
  │    refresh_token: opaque (30 day TTL, stored in DB),       │
  │    token_type:    "Bearer"                                 │
  │  }                                                         │
  │                                                            │
  │  5. Subsequent API calls                                   │
  │  Client ──GET /api/resource──▶ API Gateway                 │
  │  Header: Authorization: Bearer <access_token>              │
  │                                                            │
  │  6. Token refresh (when access_token expires)              │
  │  Client ──POST /auth/refresh──▶ Auth Service               │
  │  { refresh_token }                                         │
  │  ──▶ new access_token + rotated refresh_token              │
  └────────────────────────────────────────────────────────────┘
```

### RBAC/ABAC Model

```
┌─────────────────── AUTHORIZATION MODEL ─────────────────────┐
│                                                              │
│  RBAC (Role-Based Access Control)                            │
│  ═══════════════════════════════                             │
│                                                              │
│  User ──has──▶ Role ──has──▶ Permission                      │
│                                                              │
│  Example:                                                    │
│  User("alice") ─▶ Role("editor") ─▶ Perm("articles:write")  │
│                                  ─▶ Perm("articles:read")   │
│                                  ─▶ Perm("articles:delete") │
│                                                              │
│  ABAC (Attribute-Based Access Control)                       │
│  ════════════════════════════════════                        │
│                                                              │
│  Policy: {                                                   │
│    effect: "allow",                                          │
│    action: "edit",                                           │
│    resource: "article",                                      │
│    conditions: {                                             │
│      "resource.owner_id == subject.id",                      │
│      "resource.status != 'published'",                       │
│      "subject.department == 'content'"                       │
│    }                                                         │
│  }                                                           │
└──────────────────────────────────────────────────────────────┘
```

### Python Implementation

```python
"""
Complete Authentication & Authorization System
"""
import os
import uuid
import time
import hashlib
import secrets
from datetime import datetime, timedelta
from enum import Enum
from dataclasses import dataclass, field
from typing import Optional, List, Set, Dict, Any
from functools import wraps

import bcrypt
import jwt
import pyotp
from fastapi import FastAPI, Depends, HTTPException, Security
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from pydantic import BaseModel, EmailStr
from sqlalchemy import (
    Column, String, Boolean, DateTime, ForeignKey, Table,
    create_engine, Text
)
from sqlalchemy.orm import (
    declarative_base, relationship, Session, sessionmaker
)
import redis

# ─────────────────────────────────────────────────
# Database Models
# ─────────────────────────────────────────────────
Base = declarative_base()

# Many-to-Many: User <-> Role
user_roles = Table(
    "user_roles", Base.metadata,
    Column("user_id", String, ForeignKey("users.id")),
    Column("role_id", String, ForeignKey("roles.id")),
)

# Many-to-Many: Role <-> Permission
role_permissions = Table(
    "role_permissions", Base.metadata,
    Column("role_id", String, ForeignKey("roles.id")),
    Column("permission_id", String, ForeignKey("permissions.id")),
)


class UserModel(Base):
    __tablename__ = "users"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    email = Column(String, unique=True, nullable=False, index=True)
    password_hash = Column(String, nullable=False)
    is_active = Column(Boolean, default=True)
    is_email_verified = Column(Boolean, default=False)
    mfa_enabled = Column(Boolean, default=False)
    mfa_secret = Column(String, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow)

    roles = relationship("RoleModel", secondary=user_roles, back_populates="users")
    refresh_tokens = relationship("RefreshTokenModel", back_populates="user")


class RoleModel(Base):
    __tablename__ = "roles"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    name = Column(String, unique=True, nullable=False)
    description = Column(Text, nullable=True)

    users = relationship("UserModel", secondary=user_roles, back_populates="roles")
    permissions = relationship(
        "PermissionModel", secondary=role_permissions, back_populates="roles"
    )


class PermissionModel(Base):
    __tablename__ = "permissions"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    name = Column(String, unique=True, nullable=False)   # e.g. "articles:write"
    resource = Column(String, nullable=False)              # e.g. "articles"
    action = Column(String, nullable=False)                # e.g. "write"

    roles = relationship(
        "RoleModel", secondary=role_permissions, back_populates="permissions"
    )


class RefreshTokenModel(Base):
    __tablename__ = "refresh_tokens"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    token_hash = Column(String, nullable=False, index=True)
    user_id = Column(String, ForeignKey("users.id"), nullable=False)
    device_info = Column(String, nullable=True)
    expires_at = Column(DateTime, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    revoked = Column(Boolean, default=False)

    user = relationship("UserModel", back_populates="refresh_tokens")


class AuditLogModel(Base):
    __tablename__ = "audit_logs"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String, nullable=True)
    action = Column(String, nullable=False)
    resource = Column(String, nullable=True)
    ip_address = Column(String, nullable=True)
    user_agent = Column(String, nullable=True)
    details = Column(Text, nullable=True)
    timestamp = Column(DateTime, default=datetime.utcnow)


# ─────────────────────────────────────────────────
# Pydantic Schemas
# ─────────────────────────────────────────────────
class RegisterRequest(BaseModel):
    email: EmailStr
    password: str  # Min 8 chars, must contain upper, lower, digit, special

class LoginRequest(BaseModel):
    email: EmailStr
    password: str
    mfa_code: Optional[str] = None

class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "Bearer"
    expires_in: int

class RefreshRequest(BaseModel):
    refresh_token: str


# ─────────────────────────────────────────────────
# Password Service
# ─────────────────────────────────────────────────
class PasswordService:
    @staticmethod
    def hash_password(password: str) -> str:
        return bcrypt.hashpw(
            password.encode("utf-8"),
            bcrypt.gensalt(rounds=12)
        ).decode("utf-8")

    @staticmethod
    def verify_password(password: str, hashed: str) -> bool:
        return bcrypt.checkpw(
            password.encode("utf-8"),
            hashed.encode("utf-8")
        )

    @staticmethod
    def validate_strength(password: str) -> bool:
        if len(password) < 8:
            return False
        has_upper = any(c.isupper() for c in password)
        has_lower = any(c.islower() for c in password)
        has_digit = any(c.isdigit() for c in password)
        has_special = any(c in "!@#$%^&*()_+-=[]{}|;:,.<>?" for c in password)
        return all([has_upper, has_lower, has_digit, has_special])


# ─────────────────────────────────────────────────
# Token Service (JWT + Refresh Token)
# ─────────────────────────────────────────────────
class TokenService:
    def __init__(
        self,
        secret_key: str,
        algorithm: str = "HS256",
        access_token_ttl: int = 900,      # 15 minutes
        refresh_token_ttl: int = 2592000,  # 30 days
        redis_client: redis.Redis = None,
    ):
        self.secret_key = secret_key
        self.algorithm = algorithm
        self.access_token_ttl = access_token_ttl
        self.refresh_token_ttl = refresh_token_ttl
        self.redis = redis_client

    def create_access_token(
        self, user_id: str, roles: List[str], permissions: List[str]
    ) -> str:
        now = datetime.utcnow()
        payload = {
            "sub": user_id,
            "roles": roles,
            "permissions": permissions,
            "iat": now,
            "exp": now + timedelta(seconds=self.access_token_ttl),
            "jti": str(uuid.uuid4()),
            "type": "access",
        }
        return jwt.encode(payload, self.secret_key, algorithm=self.algorithm)

    def create_refresh_token(self) -> str:
        return secrets.token_urlsafe(64)

    def decode_access_token(self, token: str) -> dict:
        try:
            payload = jwt.decode(
                token, self.secret_key, algorithms=[self.algorithm]
            )
            # Check if token is revoked (blacklisted)
            jti = payload.get("jti")
            if self.redis and self.redis.exists(f"revoked_token:{jti}"):
                raise jwt.InvalidTokenError("Token has been revoked")
            return payload
        except jwt.ExpiredSignatureError:
            raise HTTPException(401, "Token has expired")
        except jwt.InvalidTokenError as e:
            raise HTTPException(401, f"Invalid token: {str(e)}")

    def revoke_token(self, jti: str, ttl: int = None):
        """Add token JTI to blacklist in Redis."""
        if self.redis:
            self.redis.setex(
                f"revoked_token:{jti}",
                ttl or self.access_token_ttl,
                "1"
            )

    @staticmethod
    def hash_refresh_token(token: str) -> str:
        return hashlib.sha256(token.encode()).hexdigest()


# ─────────────────────────────────────────────────
# MFA Service (TOTP)
# ─────────────────────────────────────────────────
class MFAService:
    @staticmethod
    def generate_secret() -> str:
        return pyotp.random_base32()

    @staticmethod
    def get_provisioning_uri(secret: str, email: str, issuer: str = "MyApp"):
        totp = pyotp.TOTP(secret)
        return totp.provisioning_uri(name=email, issuer_name=issuer)

    @staticmethod
    def verify_code(secret: str, code: str) -> bool:
        totp = pyotp.TOTP(secret)
        return totp.verify(code, valid_window=1)  # ±30 seconds


# ─────────────────────────────────────────────────
# Authorization (RBAC + ABAC Policy Engine)
# ─────────────────────────────────────────────────
@dataclass
class PolicyCondition:
    field: str       # e.g. "resource.owner_id"
    operator: str    # e.g. "eq", "ne", "in", "contains"
    value: Any       # e.g. "{subject.id}" for dynamic reference

class PolicyEffect(Enum):
    ALLOW = "allow"
    DENY = "deny"

@dataclass
class Policy:
    effect: PolicyEffect
    actions: List[str]
    resources: List[str]
    conditions: List[PolicyCondition] = field(default_factory=list)

class AuthorizationEngine:
    """Evaluates RBAC permissions and ABAC policies."""

    def __init__(self):
        self.policies: List[Policy] = []

    def add_policy(self, policy: Policy):
        self.policies.append(policy)

    def check_permission(self, user_permissions: List[str], required: str) -> bool:
        """Simple RBAC check."""
        return required in user_permissions

    def evaluate_policy(
        self,
        subject: dict,    # user attributes
        action: str,
        resource: dict,   # resource attributes
    ) -> bool:
        """ABAC policy evaluation."""
        applicable = [
            p for p in self.policies
            if action in p.actions
            and resource.get("type") in p.resources
        ]

        if not applicable:
            return False  # Default deny

        for policy in applicable:
            conditions_met = all(
                self._evaluate_condition(cond, subject, resource)
                for cond in policy.conditions
            )
            if conditions_met:
                if policy.effect == PolicyEffect.DENY:
                    return False
                if policy.effect == PolicyEffect.ALLOW:
                    return True

        return False  # Default deny

    def _evaluate_condition(
        self, cond: PolicyCondition,
        subject: dict, resource: dict
    ) -> bool:
        actual = self._resolve_value(cond.field, subject, resource)
        expected = self._resolve_value(str(cond.value), subject, resource)

        ops = {
            "eq": lambda a, e: a == e,
            "ne": lambda a, e: a != e,
            "in": lambda a, e: a in e,
            "gt": lambda a, e: a > e,
            "lt": lambda a, e: a < e,
        }
        return ops.get(cond.operator, lambda a, e: False)(actual, expected)

    def _resolve_value(self, ref: str, subject: dict, resource: dict) -> Any:
        if ref.startswith("subject."):
            return subject.get(ref.split(".", 1)[1])
        if ref.startswith("resource."):
            return resource.get(ref.split(".", 1)[1])
        return ref


# ─────────────────────────────────────────────────
# Main Auth Service (FastAPI)
# ─────────────────────────────────────────────────
app = FastAPI(title="Auth Service")
security_scheme = HTTPBearer()

# Init services (simplified — use DI in production)
engine = create_engine("sqlite:///auth.db")
Base.metadata.create_all(engine)
SessionLocal = sessionmaker(bind=engine)

token_service = TokenService(
    secret_key=os.getenv("JWT_SECRET", "change-me-in-production"),
    redis_client=redis.Redis(),
)
password_service = PasswordService()
mfa_service = MFAService()
authz_engine = AuthorizationEngine()


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


@app.post("/auth/register", response_model=dict)
def register(req: RegisterRequest, db: Session = Depends(get_db)):
    if not password_service.validate_strength(req.password):
        raise HTTPException(400, "Password too weak")

    existing = db.query(UserModel).filter_by(email=req.email).first()
    if existing:
        raise HTTPException(409, "Email already registered")

    user = UserModel(
        email=req.email,
        password_hash=password_service.hash_password(req.password),
    )
    db.add(user)
    db.commit()
    return {"user_id": user.id, "message": "Registration successful"}


@app.post("/auth/login", response_model=TokenResponse)
def login(req: LoginRequest, db: Session = Depends(get_db)):
    user = db.query(UserModel).filter_by(email=req.email).first()
    if not user or not password_service.verify_password(
        req.password, user.password_hash
    ):
        raise HTTPException(401, "Invalid credentials")

    if not user.is_active:
        raise HTTPException(403, "Account disabled")

    # MFA check
    if user.mfa_enabled:
        if not req.mfa_code:
            raise HTTPException(403, "MFA code required")
        if not mfa_service.verify_code(user.mfa_secret, req.mfa_code):
            raise HTTPException(401, "Invalid MFA code")

    # Gather roles & permissions
    roles = [r.name for r in user.roles]
    permissions = list({
        p.name for r in user.roles for p in r.permissions
    })

    # Issue tokens
    access_token = token_service.create_access_token(
        user.id, roles, permissions
    )
    refresh_token_raw = token_service.create_refresh_token()

    # Store refresh token (hashed)
    rt = RefreshTokenModel(
        token_hash=TokenService.hash_refresh_token(refresh_token_raw),
        user_id=user.id,
        expires_at=datetime.utcnow() + timedelta(
            seconds=token_service.refresh_token_ttl
        ),
    )
    db.add(rt)
    db.commit()

    # Audit log
    db.add(AuditLogModel(user_id=user.id, action="login"))
    db.commit()

    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token_raw,
        expires_in=token_service.access_token_ttl,
    )


@app.post("/auth/refresh", response_model=TokenResponse)
def refresh_token(req: RefreshRequest, db: Session = Depends(get_db)):
    token_hash = TokenService.hash_refresh_token(req.refresh_token)
    rt = db.query(RefreshTokenModel).filter_by(
        token_hash=token_hash, revoked=False
    ).first()

    if not rt or rt.expires_at < datetime.utcnow():
        raise HTTPException(401, "Invalid or expired refresh token")

    user = rt.user

    # Rotate refresh token
    rt.revoked = True
    new_refresh = token_service.create_refresh_token()
    new_rt = RefreshTokenModel(
        token_hash=TokenService.hash_refresh_token(new_refresh),
        user_id=user.id,
        expires_at=datetime.utcnow() + timedelta(
            seconds=token_service.refresh_token_ttl
        ),
    )
    db.add(new_rt)

    roles = [r.name for r in user.roles]
    permissions = list({
        p.name for r in user.roles for p in r.permissions
    })
    access_token = token_service.create_access_token(
        user.id, roles, permissions
    )
    db.commit()

    return TokenResponse(
        access_token=access_token,
        refresh_token=new_refresh,
        expires_in=token_service.access_token_ttl,
    )


@app.post("/auth/logout")
def logout(
    creds: HTTPAuthorizationCredentials = Security(security_scheme),
    db: Session = Depends(get_db),
):
    payload = token_service.decode_access_token(creds.credentials)
    token_service.revoke_token(payload["jti"])

    # Revoke all refresh tokens for this user
    db.query(RefreshTokenModel).filter_by(
        user_id=payload["sub"], revoked=False
    ).update({"revoked": True})
    db.commit()

    return {"message": "Logged out"}


# ─────────────────────────────────────────────────
# Dependency: Require specific permission
# ─────────────────────────────────────────────────
def require_permission(permission: str):
    def dependency(
        creds: HTTPAuthorizationCredentials = Security(security_scheme)
    ):
        payload = token_service.decode_access_token(creds.credentials)
        if permission not in payload.get("permissions", []):
            raise HTTPException(
                403, f"Missing permission: {permission}"
            )
        return payload
    return Depends(dependency)


# Usage in a resource service:
@app.get("/api/articles")
def list_articles(user=require_permission("articles:read")):
    return {"articles": [], "user_id": user["sub"]}
```

---

## 19. Feature Flag System

---

### Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│                   FEATURE FLAG SYSTEM                            │
│                                                                  │
│  ┌───────────────────────────────────────────────────────┐       │
│  │              MANAGEMENT DASHBOARD (UI)                │       │
│  │  • Create/edit flags    • Set targeting rules          │       │
│  │  • Schedule rollouts    • View analytics               │       │
│  └────────────────────────┬──────────────────────────────┘       │
│                           │                                      │
│                           ▼                                      │
│  ┌───────────────────────────────────────────────────────┐       │
│  │              FLAG MANAGEMENT API                      │       │
│  │  POST /flags          GET /flags/{key}                │       │
│  │  PUT /flags/{key}     DELETE /flags/{key}             │       │
│  │  POST /flags/{key}/rules                              │       │
│  └────────────────────────┬──────────────────────────────┘       │
│                           │                                      │
│             ┌─────────────┼─────────────┐                        │
│             ▼             ▼             ▼                         │
│     ┌──────────────┐ ┌──────────┐ ┌──────────────┐               │
│     │  PostgreSQL  │ │  Redis   │ │  Event Bus   │               │
│     │  (Source of  │ │  (Cache) │ │  (Pub/Sub)   │               │
│     │   Truth)     │ │          │ │              │               │
│     └──────────────┘ └──────────┘ └──────┬───────┘               │
│                                          │                       │
│                     ┌────────────────────┼────────────┐          │
│                     ▼                    ▼            ▼          │
│              ┌─────────────┐  ┌─────────────┐ ┌────────────┐    │
│              │ Service A   │  │ Service B   │ │ Service C  │    │
│              │ ┌─────────┐ │  │ ┌─────────┐ │ │┌─────────┐│    │
│              │ │SDK/Local│ │  │ │SDK/Local│ │ ││SDK/Local││    │
│              │ │Cache    │ │  │ │Cache    │ │ ││Cache    ││    │
│              │ └─────────┘ │  │ └─────────┘ │ │└─────────┘│    │
│              └─────────────┘  └─────────────┘ └────────────┘    │
│                                                                  │
│  ┌───────────────────────────────────────────────────────┐       │
│  │              FLAG EVALUATION ENGINE                    │       │
│  │                                                       │       │
│  │  1. Check kill switch (global on/off)                 │       │
│  │  2. Check user-specific overrides                     │       │
│  │  3. Evaluate targeting rules                          │       │
│  │     a. User attributes (email, plan, country)         │       │
│  │     b. Percentage rollout (consistent hashing)        │       │
│  │     c. Segment membership                             │       │
│  │  4. Return default value                              │       │
│  └───────────────────────────────────────────────────────┘       │
└──────────────────────────────────────────────────────────────────┘
```

### Evaluation Flow

```
evaluate("new_checkout", user_context)
            │
            ▼
    ┌───────────────┐
    │ Flag exists?  │──No──▶ Return default_value
    └───────┬───────┘
            │ Yes
            ▼
    ┌───────────────┐
    │ Flag enabled? │──No──▶ Return off_variation
    └───────┬───────┘
            │ Yes
            ▼
    ┌───────────────────┐
    │ User in override  │──Yes──▶ Return override_variation
    │ list?             │
    └───────┬───────────┘
            │ No
            ▼
    ┌───────────────────┐
    │ Evaluate targeting│
    │ rules in order    │──Match──▶ Return rule variation
    └───────┬───────────┘
            │ No match
            ▼
    ┌───────────────────┐
    │ Percentage rollout│
    │ hash(flag+user)%  │──In %──▶ Return on_variation
    │ 100 < percentage  │
    └───────┬───────────┘
            │ Outside %
            ▼
    Return off_variation
```

### Python Implementation

```python
"""
Complete Feature Flag System
"""
import hashlib
import json
import time
import threading
from datetime import datetime
from dataclasses import dataclass, field
from enum import Enum
from typing import Any, Dict, List, Optional, Union
from uuid import uuid4

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import redis

# ─────────────────────────────────────────────────
# Core Models
# ─────────────────────────────────────────────────
class FlagType(str, Enum):
    BOOLEAN = "boolean"
    STRING = "string"
    INTEGER = "integer"
    JSON = "json"

class RuleOperator(str, Enum):
    EQUALS = "eq"
    NOT_EQUALS = "ne"
    CONTAINS = "contains"
    IN = "in"
    NOT_IN = "not_in"
    GREATER_THAN = "gt"
    LESS_THAN = "lt"
    REGEX = "regex"
    SEMVER_GT = "semver_gt"
    SEMVER_LT = "semver_lt"

@dataclass
class TargetingCondition:
    attribute: str          # e.g. "email", "country", "plan"
    operator: RuleOperator
    values: List[Any]       # e.g. ["US", "CA"] for "in" operator

@dataclass
class TargetingRule:
    id: str
    conditions: List[TargetingCondition]   # AND logic within rule
    variation_index: int                    # which variation to serve
    description: str = ""

@dataclass
class FeatureFlag:
    key: str
    name: str
    description: str
    flag_type: FlagType
    enabled: bool
    variations: List[Any]          # e.g. [True, False] or ["v1", "v2", "v3"]
    default_variation: int         # index into variations (when enabled)
    off_variation: int             # index into variations (when disabled)
    targeting_rules: List[TargetingRule] = field(default_factory=list)
    user_overrides: Dict[str, int] = field(default_factory=dict)
    percentage_rollout: float = 100.0    # 0-100
    salt: str = field(default_factory=lambda: str(uuid4()))
    created_at: datetime = field(default_factory=datetime.utcnow)
    updated_at: datetime = field(default_factory=datetime.utcnow)
    tags: List[str] = field(default_factory=list)

    def to_dict(self) -> dict:
        return {
            "key": self.key,
            "name": self.name,
            "description": self.description,
            "flag_type": self.flag_type.value,
            "enabled": self.enabled,
            "variations": self.variations,
            "default_variation": self.default_variation,
            "off_variation": self.off_variation,
            "targeting_rules": [
                {
                    "id": r.id,
                    "conditions": [
                        {
                            "attribute": c.attribute,
                            "operator": c.operator.value,
                            "values": c.values
                        }
                        for c in r.conditions
                    ],
                    "variation_index": r.variation_index,
                }
                for r in self.targeting_rules
            ],
            "user_overrides": self.user_overrides,
            "percentage_rollout": self.percentage_rollout,
            "salt": self.salt,
            "tags": self.tags,
        }


# ─────────────────────────────────────────────────
# Evaluation Context
# ─────────────────────────────────────────────────
@dataclass
class EvaluationContext:
    user_id: str
    attributes: Dict[str, Any] = field(default_factory=dict)
    # Common attributes:
    #   email, country, plan, app_version, device_type, etc.

@dataclass
class EvaluationResult:
    flag_key: str
    value: Any
    variation_index: int
    reason: str     # "OFF", "OVERRIDE", "RULE_MATCH", "PERCENTAGE", "DEFAULT"
    rule_id: Optional[str] = None


# ─────────────────────────────────────────────────
# Evaluation Engine
# ─────────────────────────────────────────────────
class FlagEvaluator:
    """Core evaluation logic — deterministic, no side effects."""

    def evaluate(self, flag: FeatureFlag, context: EvaluationContext) -> EvaluationResult:

        # 1. Flag disabled → return off variation
        if not flag.enabled:
            return EvaluationResult(
                flag_key=flag.key,
                value=flag.variations[flag.off_variation],
                variation_index=flag.off_variation,
                reason="OFF"
            )

        # 2. User-specific override
        if context.user_id in flag.user_overrides:
            idx = flag.user_overrides[context.user_id]
            return EvaluationResult(
                flag_key=flag.key,
                value=flag.variations[idx],
                variation_index=idx,
                reason="OVERRIDE"
            )

        # 3. Targeting rules (evaluated in order, first match wins)
        for rule in flag.targeting_rules:
            if self._evaluate_rule(rule, context):
                idx = rule.variation_index
                return EvaluationResult(
                    flag_key=flag.key,
                    value=flag.variations[idx],
                    variation_index=idx,
                    reason="RULE_MATCH",
                    rule_id=rule.id,
                )

        # 4. Percentage rollout (consistent hashing)
        if flag.percentage_rollout < 100.0:
            bucket = self._get_bucket(flag.salt, flag.key, context.user_id)
            if bucket >= flag.percentage_rollout:
                return EvaluationResult(
                    flag_key=flag.key,
                    value=flag.variations[flag.off_variation],
                    variation_index=flag.off_variation,
                    reason="PERCENTAGE_EXCLUDED"
                )

        # 5. Return default (on) variation
        return EvaluationResult(
            flag_key=flag.key,
            value=flag.variations[flag.default_variation],
            variation_index=flag.default_variation,
            reason="DEFAULT"
        )

    def _evaluate_rule(
        self, rule: TargetingRule, context: EvaluationContext
    ) -> bool:
        """All conditions within a rule must match (AND logic)."""
        return all(
            self._evaluate_condition(cond, context)
            for cond in rule.conditions
        )

    def _evaluate_condition(
        self, cond: TargetingCondition, ctx: EvaluationContext
    ) -> bool:
        user_val = ctx.attributes.get(cond.attribute)
        if user_val is None:
            return False

        op = cond.operator
        target_vals = cond.values

        if op == RuleOperator.EQUALS:
            return user_val == target_vals[0]
        elif op == RuleOperator.NOT_EQUALS:
            return user_val != target_vals[0]
        elif op == RuleOperator.IN:
            return user_val in target_vals
        elif op == RuleOperator.NOT_IN:
            return user_val not in target_vals
        elif op == RuleOperator.CONTAINS:
            return target_vals[0] in str(user_val)
        elif op == RuleOperator.GREATER_THAN:
            return user_val > target_vals[0]
        elif op == RuleOperator.LESS_THAN:
            return user_val < target_vals[0]
        return False

    @staticmethod
    def _get_bucket(salt: str, flag_key: str, user_id: str) -> float:
        """Consistent hash → 0-100 bucket. Same user always gets same bucket."""
        raw = f"{salt}:{flag_key}:{user_id}"
        hash_val = int(hashlib.sha256(raw.encode()).hexdigest(), 16)
        return (hash_val % 10000) / 100.0   # 0.00 - 99.99


# ─────────────────────────────────────────────────
# Flag Store (with Redis cache + local cache)
# ─────────────────────────────────────────────────
class FlagStore:
    """Manages persistence and caching of feature flags."""

    def __init__(self, redis_client: redis.Redis):
        self.redis = redis_client
        self._local_cache: Dict[str, FeatureFlag] = {}
        self._cache_ttl = 30   # seconds
        self._last_refresh = 0.0
        self._lock = threading.Lock()

    def save_flag(self, flag: FeatureFlag):
        data = json.dumps(flag.to_dict())
        self.redis.hset("feature_flags", flag.key, data)
        # Publish update event for other instances
        self.redis.publish("flag_updates", json.dumps({
            "action": "update",
            "key": flag.key
        }))
        with self._lock:
            self._local_cache[flag.key] = flag

    def get_flag(self, key: str) -> Optional[FeatureFlag]:
        # Try local cache first
        with self._lock:
            if key in self._local_cache:
                return self._local_cache[key]

        # Try Redis
        data = self.redis.hget("feature_flags", key)
        if data:
            flag = self._deserialize(json.loads(data))
            with self._lock:
                self._local_cache[key] = flag
            return flag
        return None

    def get_all_flags(self) -> Dict[str, FeatureFlag]:
        all_data = self.redis.hgetall("feature_flags")
        flags = {}
        for key, data in all_data.items():
            key_str = key.decode() if isinstance(key, bytes) else key
            data_str = data.decode() if isinstance(data, bytes) else data
            flags[key_str] = self._deserialize(json.loads(data_str))
        with self._lock:
            self._local_cache = flags.copy()
        return flags

    def delete_flag(self, key: str):
        self.redis.hdel("feature_flags", key)
        with self._lock:
            self._local_cache.pop(key, None)

    def refresh_local_cache(self):
        now = time.time()
        if now - self._last_refresh > self._cache_ttl:
            self.get_all_flags()
            self._last_refresh = now

    @staticmethod
    def _deserialize(data: dict) -> FeatureFlag:
        rules = []
        for r in data.get("targeting_rules", []):
            conditions = [
                TargetingCondition(
                    attribute=c["attribute"],
                    operator=RuleOperator(c["operator"]),
                    values=c["values"]
                )
                for c in r["conditions"]
            ]
            rules.append(TargetingRule(
                id=r["id"],
                conditions=conditions,
                variation_index=r["variation_index"],
            ))

        return FeatureFlag(
            key=data["key"],
            name=data["name"],
            description=data.get("description", ""),
            flag_type=FlagType(data["flag_type"]),
            enabled=data["enabled"],
            variations=data["variations"],
            default_variation=data["default_variation"],
            off_variation=data["off_variation"],
            targeting_rules=rules,
            user_overrides=data.get("user_overrides", {}),
            percentage_rollout=data.get("percentage_rollout", 100.0),
            salt=data.get("salt", ""),
            tags=data.get("tags", []),
        )


# ─────────────────────────────────────────────────
# SDK Client (used in application code)
# ─────────────────────────────────────────────────
class FeatureFlagClient:
    """
    Application-facing SDK.
    
    Usage:
        client = FeatureFlagClient(redis.Redis())
        
        if client.is_enabled("new_checkout", user_id="u123",
                              attributes={"plan": "premium"}):
            show_new_checkout()
        else:
            show_old_checkout()
    """

    def __init__(self, redis_client: redis.Redis):
        self.store = FlagStore(redis_client)
        self.evaluator = FlagEvaluator()
        # Preload flags
        self.store.get_all_flags()

    def is_enabled(
        self,
        flag_key: str,
        user_id: str = "anonymous",
        attributes: Dict[str, Any] = None,
        default: bool = False,
    ) -> bool:
        self.store.refresh_local_cache()
        flag = self.store.get_flag(flag_key)
        if not flag:
            return default

        ctx = EvaluationContext(
            user_id=user_id,
            attributes=attributes or {}
        )
        result = self.evaluator.evaluate(flag, ctx)
        return bool(result.value)

    def get_variation(
        self,
        flag_key: str,
        user_id: str = "anonymous",
        attributes: Dict[str, Any] = None,
        default: Any = None,
    ) -> Any:
        self.store.refresh_local_cache()
        flag = self.store.get_flag(flag_key)
        if not flag:
            return default

        ctx = EvaluationContext(
            user_id=user_id,
            attributes=attributes or {}
        )
        result = self.evaluator.evaluate(flag, ctx)
        return result.value


# ─────────────────────────────────────────────────
# Management API
# ─────────────────────────────────────────────────
app = FastAPI(title="Feature Flag Service")
redis_client = redis.Redis()
store = FlagStore(redis_client)

class CreateFlagRequest(BaseModel):
    key: str
    name: str
    description: str = ""
    flag_type: str = "boolean"
    variations: List[Any] = [True, False]
    default_variation: int = 0
    off_variation: int = 1
    enabled: bool = False
    percentage_rollout: float = 100.0

@app.post("/flags")
def create_flag(req: CreateFlagRequest):
    if store.get_flag(req.key):
        raise HTTPException(409, "Flag already exists")
    flag = FeatureFlag(
        key=req.key,
        name=req.name,
        description=req.description,
        flag_type=FlagType(req.flag_type),
        enabled=req.enabled,
        variations=req.variations,
        default_variation=req.default_variation,
        off_variation=req.off_variation,
        percentage_rollout=req.percentage_rollout,
    )
    store.save_flag(flag)
    return flag.to_dict()

@app.put("/flags/{key}/toggle")
def toggle_flag(key: str, enabled: bool):
    flag = store.get_flag(key)
    if not flag:
        raise HTTPException(404)
    flag.enabled = enabled
    flag.updated_at = datetime.utcnow()
    store.save_flag(flag)
    return {"key": key, "enabled": enabled}

@app.put("/flags/{key}/rollout")
def set_rollout(key: str, percentage: float):
    flag = store.get_flag(key)
    if not flag:
        raise HTTPException(404)
    flag.percentage_rollout = max(0, min(100, percentage))
    store.save_flag(flag)
    return {"key": key, "percentage_rollout": flag.percentage_rollout}

@app.post("/evaluate")
def evaluate_flag(flag_key: str, user_id: str, attributes: dict = {}):
    flag = store.get_flag(flag_key)
    if not flag:
        raise HTTPException(404)
    evaluator = FlagEvaluator()
    ctx = EvaluationContext(user_id=user_id, attributes=attributes)
    result = evaluator.evaluate(flag, ctx)
    return {
        "flag_key": result.flag_key,
        "value": result.value,
        "variation_index": result.variation_index,
        "reason": result.reason,
    }


# ─────────────────────────────────────────────────
# Application Usage Example
# ─────────────────────────────────────────────────
"""
# In your microservice:
ff_client = FeatureFlagClient(redis.Redis())

@app.get("/checkout")
def checkout(user_id: str):
    if ff_client.is_enabled("new_checkout_flow", 
                            user_id=user_id,
                            attributes={"plan": "premium", "country": "US"}):
        return new_checkout_flow(user_id)
    else:
        return legacy_checkout_flow(user_id)

# Multivariate flag:
@app.get("/homepage")
def homepage(user_id: str):
    variant = ff_client.get_variation(
        "homepage_experiment",
        user_id=user_id,
        attributes={"device": "mobile"},
        default="control"
    )
    # variant could be "control", "variant_a", "variant_b"
    return render_homepage(variant)
"""
```

---

## 20. Payment Processing System

---

### Architecture

```
┌──────────────────────────────────────────────────────────────────────────┐
│                    PAYMENT PROCESSING SYSTEM                             │
│                                                                          │
│  ┌─────────┐     ┌───────────────────────────────────────────────────┐   │
│  │ Client  │────▶│                 API Gateway                       │   │
│  └─────────┘     └────────────────────┬──────────────────────────────┘   │
│                                       │                                  │
│                                       ▼                                  │
│  ┌────────────────────────────────────────────────────────────────────┐   │
│  │                      PAYMENT SERVICE                               │   │
│  │                                                                    │   │
│  │   ┌──────────────┐  ┌──────────────┐  ┌────────────────────────┐  │   │
│  │   │ Payment      │  │ Idempotency  │  │ Fraud Detection       │  │   │
│  │   │ Orchestrator │  │ Manager      │  │ Engine                │  │   │
│  │   └──────┬───────┘  └──────────────┘  └────────────────────────┘  │   │
│  │          │                                                        │   │
│  │   ┌──────┴──────────────────────────────────────┐                 │   │
│  │   │         PAYMENT STATE MACHINE               │                 │   │
│  │   │                                              │                 │   │
│  │   │  CREATED ──▶ PROCESSING ──▶ AUTHORIZED ──▶  │                 │   │
│  │   │      │           │              │            │                 │   │
│  │   │      ▼           ▼              ▼            │                 │   │
│  │   │   FAILED      FAILED       CAPTURED ──▶     │                 │   │
│  │   │                              │    │          │                 │   │
│  │   │                              ▼    ▼          │                 │   │
│  │   │                         SETTLED  REFUNDED    │                 │   │
│  │   └──────────────────────────────────────────────┘                 │   │
│  └────────────┬───────────────────────┬──────────────────────────────┘   │
│               │                       │                                  │
│    ┌──────────┴────────┐    ┌─────────┴──────────┐                       │
│    ▼                   ▼    ▼                    ▼                        │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐ ┌──────────────┐    │
│  │ PSP Adapter  │ │ PSP Adapter  │ │ Ledger       │ │ Notification │    │
│  │ (Stripe)     │ │ (PayPal)     │ │ Service      │ │ Service      │    │
│  └──────┬───────┘ └──────┬───────┘ └──────────────┘ └──────────────┘    │
│         │                │                                               │
│         ▼                ▼                                               │
│  ┌──────────────┐ ┌──────────────┐                                       │
│  │ Stripe API   │ │ PayPal API   │                                       │
│  └──────────────┘ └──────────────┘                                       │
│                                                                          │
│  ┌────────────────────────────────────────────────────────────────────┐   │
│  │                     DATA STORES                                    │   │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌───────────────────┐  │   │
│  │  │PostgreSQL│  │  Redis   │  │  Kafka   │  │  S3 (Receipts)   │  │   │
│  │  │• Payments│  │• Idempot.│  │• Events  │  │                  │  │   │
│  │  │• Ledger  │  │• Locks   │  │• Webhooks│  │                  │  │   │
│  │  │• Audit   │  │• Cache   │  │          │  │                  │  │   │
│  │  └──────────┘  └──────────┘  └──────────┘  └───────────────────┘  │   │
│  └────────────────────────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────────────────────┘
```

### Double-Entry Ledger

```
┌─────────────── DOUBLE-ENTRY LEDGER ───────────────────┐
│                                                        │
│  Every transaction has at least 2 entries that          │
│  MUST sum to zero (debit + credit = 0)                 │
│                                                        │
│  Payment of $100 from Customer → Merchant:             │
│  ┌──────────────────────────────────────────────────┐  │
│  │ Entry 1: DEBIT  customer_balance   -$100         │  │
│  │ Entry 2: CREDIT merchant_balance   +$100         │  │
│  │                                    ─────         │  │
│  │                             SUM:      $0  ✓      │  │
│  └──────────────────────────────────────────────────┘  │
│                                                        │
│  Refund of $30:                                        │
│  ┌──────────────────────────────────────────────────┐  │
│  │ Entry 1: DEBIT  merchant_balance   -$30          │  │
│  │ Entry 2: CREDIT customer_balance   +$30          │  │
│  │                                    ────          │  │
│  │                             SUM:     $0  ✓       │  │
│  └──────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────┘
```

### Python Implementation

```python
"""
Complete Payment Processing System
"""
import uuid
import time
import hashlib
import json
import logging
from datetime import datetime
from decimal import Decimal, ROUND_HALF_UP
from enum import Enum
from dataclasses import dataclass, field
from typing import Optional, Dict, List, Any
from abc import ABC, abstractmethod

from fastapi import FastAPI, HTTPException, Header
from pydantic import BaseModel, validator
from sqlalchemy import (
    Column, String, Numeric, DateTime, Enum as SAEnum,
    ForeignKey, Index, create_engine, Boolean, Text
)
from sqlalchemy.orm import declarative_base, relationship, Session, sessionmaker
import redis
import stripe

logger = logging.getLogger("payment")

Base = declarative_base()

# ─────────────────────────────────────────────────
# 1. PAYMENT STATES
# ─────────────────────────────────────────────────
class PaymentStatus(str, Enum):
    CREATED = "created"
    PROCESSING = "processing"
    AUTHORIZED = "authorized"
    CAPTURED = "captured"
    SETTLED = "settled"
    FAILED = "failed"
    CANCELLED = "cancelled"
    REFUND_PENDING = "refund_pending"
    REFUNDED = "refunded"
    PARTIALLY_REFUNDED = "partially_refunded"

# Valid state transitions
VALID_TRANSITIONS = {
    PaymentStatus.CREATED: {PaymentStatus.PROCESSING, PaymentStatus.CANCELLED},
    PaymentStatus.PROCESSING: {PaymentStatus.AUTHORIZED, PaymentStatus.FAILED},
    PaymentStatus.AUTHORIZED: {
        PaymentStatus.CAPTURED, PaymentStatus.CANCELLED, PaymentStatus.FAILED
    },
    PaymentStatus.CAPTURED: {
        PaymentStatus.SETTLED, PaymentStatus.REFUND_PENDING,
        PaymentStatus.PARTIALLY_REFUNDED
    },
    PaymentStatus.SETTLED: {
        PaymentStatus.REFUND_PENDING, PaymentStatus.PARTIALLY_REFUNDED
    },
    PaymentStatus.REFUND_PENDING: {
        PaymentStatus.REFUNDED, PaymentStatus.PARTIALLY_REFUNDED
    },
}

class Currency(str, Enum):
    USD = "USD"
    EUR = "EUR"
    GBP = "GBP"
    JPY = "JPY"


# ─────────────────────────────────────────────────
# 2. DATABASE MODELS
# ─────────────────────────────────────────────────
class PaymentModel(Base):
    __tablename__ = "payments"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    idempotency_key = Column(String, unique=True, index=True, nullable=False)
    merchant_id = Column(String, nullable=False, index=True)
    customer_id = Column(String, nullable=False, index=True)
    amount = Column(Numeric(12, 2), nullable=False)
    currency = Column(String(3), nullable=False)
    status = Column(String, nullable=False, default=PaymentStatus.CREATED.value)
    description = Column(Text, nullable=True)
    payment_method = Column(String, nullable=True)  # card, bank_transfer, etc.
    psp_provider = Column(String, nullable=True)      # stripe, paypal
    psp_transaction_id = Column(String, nullable=True)
    psp_response = Column(Text, nullable=True)
    error_code = Column(String, nullable=True)
    error_message = Column(Text, nullable=True)
    metadata_ = Column("metadata", Text, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    ledger_entries = relationship("LedgerEntryModel", back_populates="payment")
    refunds = relationship("RefundModel", back_populates="payment")


class LedgerEntryModel(Base):
    __tablename__ = "ledger_entries"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    payment_id = Column(String, ForeignKey("payments.id"), nullable=False)
    account_id = Column(String, nullable=False, index=True)
    entry_type = Column(String, nullable=False)  # "debit" or "credit"
    amount = Column(Numeric(12, 2), nullable=False)
    currency = Column(String(3), nullable=False)
    description = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    payment = relationship("PaymentModel", back_populates="ledger_entries")

    __table_args__ = (
        Index("idx_ledger_account_created", "account_id", "created_at"),
    )


class RefundModel(Base):
    __tablename__ = "refunds"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    payment_id = Column(String, ForeignKey("payments.id"), nullable=False)
    amount = Column(Numeric(12, 2), nullable=False)
    reason = Column(Text, nullable=True)
    status = Column(String, nullable=False, default="pending")
    psp_refund_id = Column(String, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    payment = relationship("PaymentModel", back_populates="refunds")


# ─────────────────────────────────────────────────
# 3. PSP ADAPTER (Strategy Pattern)
# ─────────────────────────────────────────────────
@dataclass
class PSPResponse:
    success: bool
    transaction_id: Optional[str] = None
    error_code: Optional[str] = None
    error_message: Optional[str] = None
    raw_response: Optional[dict] = None

class PaymentServiceProvider(ABC):
    @abstractmethod
    def authorize(
        self, amount: Decimal, currency: str,
        payment_method: str, metadata: dict
    ) -> PSPResponse:
        pass

    @abstractmethod
    def capture(self, transaction_id: str, amount: Decimal) -> PSPResponse:
        pass

    @abstractmethod
    def refund(
        self, transaction_id: str, amount: Decimal
    ) -> PSPResponse:
        pass

class StripeAdapter(PaymentServiceProvider):
    def __init__(self, api_key: str):
        stripe.api_key = api_key

    def authorize(
        self, amount: Decimal, currency: str,
        payment_method: str, metadata: dict
    ) -> PSPResponse:
        try:
            intent = stripe.PaymentIntent.create(
                amount=int(amount * 100),  # Stripe uses cents
                currency=currency.lower(),
                payment_method=payment_method,
                capture_method="manual",   # Authorize only
                confirm=True,
                metadata=metadata,
            )
            return PSPResponse(
                success=intent.status in ("requires_capture", "succeeded"),
                transaction_id=intent.id,
                raw_response=dict(intent),
            )
        except stripe.error.CardError as e:
            return PSPResponse(
                success=False,
                error_code=e.code,
                error_message=str(e),
            )

    def capture(self, transaction_id: str, amount: Decimal) -> PSPResponse:
        try:
            intent = stripe.PaymentIntent.capture(
                transaction_id,
                amount_to_capture=int(amount * 100),
            )
            return PSPResponse(
                success=intent.status == "succeeded",
                transaction_id=intent.id,
                raw_response=dict(intent),
            )
        except Exception as e:
            return PSPResponse(success=False, error_message=str(e))

    def refund(self, transaction_id: str, amount: Decimal) -> PSPResponse:
        try:
            refund = stripe.Refund.create(
                payment_intent=transaction_id,
                amount=int(amount * 100),
            )
            return PSPResponse(
                success=refund.status == "succeeded",
                transaction_id=refund.id,
                raw_response=dict(refund),
            )
        except Exception as e:
            return PSPResponse(success=False, error_message=str(e))


class MockPSPAdapter(PaymentServiceProvider):
    """For testing."""
    def authorize(self, amount, currency, payment_method, metadata):
        return PSPResponse(
            success=True,
            transaction_id=f"mock_txn_{uuid.uuid4().hex[:12]}"
        )

    def capture(self, transaction_id, amount):
        return PSPResponse(success=True, transaction_id=transaction_id)

    def refund(self, transaction_id, amount):
        return PSPResponse(
            success=True,
            transaction_id=f"mock_ref_{uuid.uuid4().hex[:12]}"
        )


# ─────────────────────────────────────────────────
# 4. IDEMPOTENCY MANAGER
# ─────────────────────────────────────────────────
class IdempotencyManager:
    """Prevents duplicate payment processing using Redis."""

    def __init__(self, redis_client: redis.Redis, ttl: int = 86400):
        self.redis = redis_client
        self.ttl = ttl  # 24 hours

    def check_and_lock(self, idempotency_key: str) -> Optional[dict]:
        """
        Returns cached response if exists.
        Acquires lock if new request.
        """
        cache_key = f"idempotency:{idempotency_key}"

        # Try to get existing result
        cached = self.redis.get(cache_key)
        if cached:
            return json.loads(cached)

        # Try to acquire lock (SETNX)
        lock_key = f"idempotency_lock:{idempotency_key}"
        acquired = self.redis.set(lock_key, "1", nx=True, ex=30)  # 30s lock
        if not acquired:
            # Another request is currently processing this
            raise HTTPException(409, "Request is being processed")

        return None  # New request, proceed

    def save_result(self, idempotency_key: str, result: dict):
        cache_key = f"idempotency:{idempotency_key}"
        self.redis.setex(cache_key, self.ttl, json.dumps(result))
        # Release lock
        self.redis.delete(f"idempotency_lock:{idempotency_key}")


# ─────────────────────────────────────────────────
# 5. FRAUD DETECTION (Simple Rule Engine)
# ─────────────────────────────────────────────────
@dataclass
class FraudCheckResult:
    approved: bool
    risk_score: float    # 0-100
    reasons: List[str] = field(default_factory=list)

class FraudDetectionEngine:
    def __init__(self, redis_client: redis.Redis):
        self.redis = redis_client

    def check(
        self,
        customer_id: str,
        amount: Decimal,
        currency: str,
        ip_address: str = None,
    ) -> FraudCheckResult:
        reasons = []
        risk_score = 0.0

        # Rule 1: Velocity check (>5 transactions in 1 hour)
        velocity_key = f"fraud:velocity:{customer_id}"
        tx_count = self.redis.incr(velocity_key)
        if tx_count == 1:
            self.redis.expire(velocity_key, 3600)
        if tx_count > 5:
            risk_score += 30
            reasons.append(f"High velocity: {tx_count} txns in 1 hour")

        # Rule 2: Large amount
        if amount > Decimal("10000"):
            risk_score += 25
            reasons.append(f"Large amount: {amount} {currency}")

        # Rule 3: Multiple currencies in short time
        currency_key = f"fraud:currencies:{customer_id}"
        self.redis.sadd(currency_key, currency)
        self.redis.expire(currency_key, 3600)
        num_currencies = self.redis.scard(currency_key)
        if num_currencies > 2:
            risk_score += 20
            reasons.append(f"Multiple currencies: {num_currencies}")

        approved = risk_score < 70
        return FraudCheckResult(
            approved=approved,
            risk_score=risk_score,
            reasons=reasons
        )


# ─────────────────────────────────────────────────
# 6. LEDGER SERVICE
# ─────────────────────────────────────────────────
class LedgerService:
    def __init__(self, db_session: Session):
        self.db = db_session

    def record_payment(
        self,
        payment_id: str,
        customer_account: str,
        merchant_account: str,
        amount: Decimal,
        currency: str,
    ):
        """Double-entry: debit customer, credit merchant."""
        debit = LedgerEntryModel(
            payment_id=payment_id,
            account_id=customer_account,
            entry_type="debit",
            amount=-amount,   # Negative = money going out
            currency=currency,
            description=f"Payment {payment_id}",
        )
        credit = LedgerEntryModel(
            payment_id=payment_id,
            account_id=merchant_account,
            entry_type="credit",
            amount=amount,    # Positive = money coming in
            currency=currency,
            description=f"Payment {payment_id}",
        )
        self.db.add(debit)
        self.db.add(credit)

    def record_refund(
        self,
        payment_id: str,
        customer_account: str,
        merchant_account: str,
        amount: Decimal,
        currency: str,
    ):
        """Double-entry: debit merchant, credit customer."""
        debit = LedgerEntryModel(
            payment_id=payment_id,
            account_id=merchant_account,
            entry_type="debit",
            amount=-amount,
            currency=currency,
            description=f"Refund for {payment_id}",
        )
        credit = LedgerEntryModel(
            payment_id=payment_id,
            account_id=customer_account,
            entry_type="credit",
            amount=amount,
            currency=currency,
            description=f"Refund for {payment_id}",
        )
        self.db.add(debit)
        self.db.add(credit)

    def get_balance(self, account_id: str) -> Dict[str, Decimal]:
        entries = self.db.query(LedgerEntryModel).filter_by(
            account_id=account_id
        ).all()
        balances: Dict[str, Decimal] = {}
        for entry in entries:
            cur = entry.currency
            balances[cur] = balances.get(cur, Decimal("0")) + entry.amount
        return balances


# ─────────────────────────────────────────────────
# 7. PAYMENT ORCHESTRATOR
# ─────────────────────────────────────────────────
class PaymentOrchestrator:
    def __init__(
        self,
        db_session: Session,
        psp: PaymentServiceProvider,
        idempotency: IdempotencyManager,
        fraud_engine: FraudDetectionEngine,
        ledger: LedgerService,
    ):
        self.db = db_session
        self.psp = psp
        self.idempotency = idempotency
        self.fraud = fraud_engine
        self.ledger = ledger

    def _transition(self, payment: PaymentModel, new_status: PaymentStatus):
        current = PaymentStatus(payment.status)
        valid = VALID_TRANSITIONS.get(current, set())
        if new_status not in valid:
            raise ValueError(
                f"Invalid transition: {current.value} → {new_status.value}"
            )
        payment.status = new_status.value
        payment.updated_at = datetime.utcnow()

    def create_payment(
        self,
        idempotency_key: str,
        merchant_id: str,
        customer_id: str,
        amount: Decimal,
        currency: str,
        payment_method: str,
        description: str = "",
        ip_address: str = None,
    ) -> dict:
        # 1. Idempotency check
        cached = self.idempotency.check_and_lock(idempotency_key)
        if cached:
            return cached

        try:
            # 2. Create payment record
            payment = PaymentModel(
                idempotency_key=idempotency_key,
                merchant_id=merchant_id,
                customer_id=customer_id,
                amount=amount,
                currency=currency,
                payment_method=payment_method,
                description=description,
                psp_provider="stripe",
            )
            self.db.add(payment)
            self.db.flush()

            # 3. Fraud check
            fraud_result = self.fraud.check(
                customer_id, amount, currency, ip_address
            )
            if not fraud_result.approved:
                self._transition(payment, PaymentStatus.FAILED)
                payment.error_code = "FRAUD_DETECTED"
                payment.error_message = "; ".join(fraud_result.reasons)
                self.db.commit()
                result = self._payment_response(payment)
                self.idempotency.save_result(idempotency_key, result)
                return result

            # 4. Process with PSP
            self._transition(payment, PaymentStatus.PROCESSING)
            self.db.flush()

            psp_response = self.psp.authorize(
                amount, currency, payment_method,
                metadata={"payment_id": payment.id}
            )

            if psp_response.success:
                self._transition(payment, PaymentStatus.AUTHORIZED)
                payment.psp_transaction_id = psp_response.transaction_id

                # 5. Auto-capture
                capture_resp = self.psp.capture(
                    psp_response.transaction_id, amount
                )
                if capture_resp.success:
                    self._transition(payment, PaymentStatus.CAPTURED)
                    # 6. Record in ledger
                    self.ledger.record_payment(
                        payment.id,
                        f"customer:{customer_id}",
                        f"merchant:{merchant_id}",
                        amount, currency
                    )
            else:
                self._transition(payment, PaymentStatus.FAILED)
                payment.error_code = psp_response.error_code
                payment.error_message = psp_response.error_message

            self.db.commit()
            result = self._payment_response(payment)
            self.idempotency.save_result(idempotency_key, result)
            return result

        except Exception as e:
            self.db.rollback()
            logger.exception(f"Payment processing error: {e}")
            raise

    def process_refund(
        self, payment_id: str, amount: Decimal, reason: str = ""
    ) -> dict:
        payment = self.db.query(PaymentModel).get(payment_id)
        if not payment:
            raise HTTPException(404, "Payment not found")

        if payment.status not in (
            PaymentStatus.CAPTURED.value, PaymentStatus.SETTLED.value
        ):
            raise HTTPException(400, "Payment cannot be refunded")

        # Check total refunded amount
        existing_refunds = sum(
            r.amount for r in payment.refunds if r.status == "completed"
        )
        if existing_refunds + amount > payment.amount:
            raise HTTPException(400, "Refund exceeds payment amount")

        refund = RefundModel(
            payment_id=payment_id,
            amount=amount,
            reason=reason,
        )
        self.db.add(refund)

        psp_resp = self.psp.refund(payment.psp_transaction_id, amount)

        if psp_resp.success:
            refund.status = "completed"
            refund.psp_refund_id = psp_resp.transaction_id

            if existing_refunds + amount == payment.amount:
                self._transition(payment, PaymentStatus.REFUNDED)
            else:
                self._transition(payment, PaymentStatus.PARTIALLY_REFUNDED)

            self.ledger.record_refund(
                payment.id,
                f"customer:{payment.customer_id}",
                f"merchant:{payment.merchant_id}",
                amount, payment.currency,
            )
        else:
            refund.status = "failed"

        self.db.commit()
        return {"refund_id": refund.id, "status": refund.status}

    def _payment_response(self, payment: PaymentModel) -> dict:
        return {
            "payment_id": payment.id,
            "status": payment.status,
            "amount": str(payment.amount),
            "currency": payment.currency,
            "created_at": payment.created_at.isoformat(),
        }


# ─────────────────────────────────────────────────
# 8. API ENDPOINTS
# ─────────────────────────────────────────────────
app = FastAPI(title="Payment Service")

engine = create_engine("postgresql://localhost/payments")
Base.metadata.create_all(engine)
SessionLocal = sessionmaker(bind=engine)
redis_client = redis.Redis()

class CreatePaymentRequest(BaseModel):
    merchant_id: str
    customer_id: str
    amount: str   # String to avoid float precision issues
    currency: str
    payment_method: str
    description: str = ""

    @validator("amount")
    def validate_amount(cls, v):
        d = Decimal(v)
        if d <= 0:
            raise ValueError("Amount must be positive")
        return v

@app.post("/payments")
def create_payment(
    req: CreatePaymentRequest,
    idempotency_key: str = Header(..., alias="Idempotency-Key"),
):
    db = SessionLocal()
    try:
        orchestrator = PaymentOrchestrator(
            db_session=db,
            psp=MockPSPAdapter(),
            idempotency=IdempotencyManager(redis_client),
            fraud_engine=FraudDetectionEngine(redis_client),
            ledger=LedgerService(db),
        )
        return orchestrator.create_payment(
            idempotency_key=idempotency_key,
            merchant_id=req.merchant_id,
            customer_id=req.customer_id,
            amount=Decimal(req.amount),
            currency=req.currency,
            payment_method=req.payment_method,
            description=req.description,
        )
    finally:
        db.close()

class RefundRequest(BaseModel):
    amount: str
    reason: str = ""

@app.post("/payments/{payment_id}/refund")
def refund_payment(payment_id: str, req: RefundRequest):
    db = SessionLocal()
    try:
        orchestrator = PaymentOrchestrator(
            db_session=db,
            psp=MockPSPAdapter(),
            idempotency=IdempotencyManager(redis_client),
            fraud_engine=FraudDetectionEngine(redis_client),
            ledger=LedgerService(db),
        )
        return orchestrator.process_refund(
            payment_id, Decimal(req.amount), req.reason
        )
    finally:
        db.close()
```

---

## 21. Global CDN System

---

### Architecture

```
┌──────────────────────────────────────────────────────────────────────────┐
│                        GLOBAL CDN SYSTEM                                 │
│                                                                          │
│   User (Tokyo)                                                           │
│       │                                                                  │
│       ▼                                                                  │
│   ┌────────────────────────────────────────────────────────────────┐     │
│   │                    DNS (GeoDNS / Anycast)                      │     │
│   │  Resolves to nearest PoP based on user's location              │     │
│   │  cdn.example.com → 103.21.244.x (Tokyo PoP)                   │     │
│   └────────────────────────┬───────────────────────────────────────┘     │
│                            │                                             │
│   ┌────────────────────────▼───────────────────────────────────────┐     │
│   │              EDGE PoP (Point of Presence) — Tokyo              │     │
│   │                                                                │     │
│   │  ┌──────────────┐   ┌──────────────┐   ┌────────────────┐     │     │
│   │  │  TLS Termin. │──▶│  Edge Cache  │──▶│ Request Router │     │     │
│   │  │  (L4/L7 LB)  │   │  (Varnish/   │   │                │     │     │
│   │  │              │   │   Nginx)     │   │                │     │     │
│   │  └──────────────┘   └──────┬───────┘   └───────┬────────┘     │     │
│   │                     HIT? ──┤                    │              │     │
│   │                    Yes     No                   │              │     │
│   │                     │      │                    │              │     │
│   │                     ▼      ▼                    ▼              │     │
│   │              Serve   ┌──────────────┐  ┌────────────────┐     │     │
│   │              cached  │  Shield      │  │ Edge Compute   │     │     │
│   │              content │  (Regional   │  │ (Wasm/V8       │     │     │
│   │                      │   Mid-tier)  │  │  Workers)      │     │     │
│   │                      └──────┬───────┘  └────────────────┘     │     │
│   └─────────────────────────────┼──────────────────────────────────┘     │
│                                 │                                        │
│                            MISS │ (Cache miss at shield)                 │
│                                 │                                        │
│   ┌─────────────────────────────▼──────────────────────────────────┐     │
│   │                     ORIGIN INFRASTRUCTURE                      │     │
│   │                                                                │     │
│   │  ┌──────────────┐   ┌──────────────┐   ┌────────────────┐     │     │
│   │  │  Origin LB   │──▶│  Origin      │──▶│  Object Store  │     │     │
│   │  │              │   │  Servers     │   │  (S3/GCS)      │     │     │
│   │  └──────────────┘   └──────────────┘   └────────────────┘     │     │
│   └────────────────────────────────────────────────────────────────┘     │
│                                                                          │
│   ┌────────────────────────────────────────────────────────────────┐     │
│   │                    CONTROL PLANE                               │     │
│   │                                                                │     │
│   │  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────────┐  │     │
│   │  │Config    │  │ Purge    │  │Analytics │  │ Certificate  │  │     │
│   │  │Manager   │  │ Service  │  │ Pipeline │  │ Manager      │  │     │
│   │  └──────────┘  └──────────┘  └──────────┘  └──────────────┘  │     │
│   └────────────────────────────────────────────────────────────────┘     │
└──────────────────────────────────────────────────────────────────────────┘
```

### Caching Strategy

```
┌────────────── CACHE HIERARCHY ──────────────────┐
│                                                  │
│  L1: Browser Cache                               │
│      Cache-Control: public, max-age=31536000     │
│      (immutable assets with hash in filename)    │
│                                                  │
│  L2: Edge PoP Cache (200+ locations worldwide)   │
│      Per-PoP, hot content, short TTL for dynamic │
│      Vary: Accept-Encoding, Accept-Language      │
│                                                  │
│  L3: Shield/Regional Cache (5-10 locations)      │
│      Collapsed forwarding (coalesce misses)      │
│      Protects origin from thundering herd        │
│                                                  │
│  L4: Origin                                      │
│      Source of truth                              │
└──────────────────────────────────────────────────┘

┌────────── CACHE KEY COMPOSITION ────────────────┐
│                                                  │
│  key = hash(                                     │
│    url,                                          │
│    Vary_headers (Accept-Encoding, etc.),         │
│    query_params,                                 │
│    device_type (if mobile-specific),             │
│    country (if geo-targeted)                     │
│  )                                               │
└──────────────────────────────────────────────────┘
```

### Python Implementation

```python
"""
CDN Edge Server + Control Plane Simulation
"""
import hashlib
import time
import json
import logging
import asyncio
from dataclasses import dataclass, field
from typing import Optional, Dict, List, Set, Tuple
from enum import Enum
from collections import OrderedDict
import aiohttp
from fastapi import FastAPI, Request, Response, HTTPException

logger = logging.getLogger("cdn")

# ─────────────────────────────────────────────────
# 1. LRU CACHE with TTL
# ─────────────────────────────────────────────────
@dataclass
class CacheEntry:
    content: bytes
    content_type: str
    headers: Dict[str, str]
    status_code: int
    created_at: float
    ttl: int
    size: int
    hit_count: int = 0

    @property
    def is_expired(self) -> bool:
        return time.time() - self.created_at > self.ttl

    @property
    def age(self) -> int:
        return int(time.time() - self.created_at)


class LRUCache:
    """LRU cache with TTL support and max size in bytes."""

    def __init__(self, max_size_bytes: int = 1_073_741_824):  # 1GB default
        self._cache: OrderedDict[str, CacheEntry] = OrderedDict()
        self._max_size = max_size_bytes
        self._current_size = 0
        self._hits = 0
        self._misses = 0

    def get(self, key: str) -> Optional[CacheEntry]:
        if key not in self._cache:
            self._misses += 1
            return None

        entry = self._cache[key]
        if entry.is_expired:
            self._remove(key)
            self._misses += 1
            return None

        # Move to end (most recently used)
        self._cache.move_to_end(key)
        entry.hit_count += 1
        self._hits += 1
        return entry

    def put(self, key: str, entry: CacheEntry):
        # Remove existing entry if present
        if key in self._cache:
            self._remove(key)

        # Evict LRU entries until enough space
        while self._current_size + entry.size > self._max_size and self._cache:
            oldest_key = next(iter(self._cache))
            self._remove(oldest_key)

        self._cache[key] = entry
        self._current_size += entry.size

    def _remove(self, key: str):
        if key in self._cache:
            self._current_size -= self._cache[key].size
            del self._cache[key]

    def purge(self, key: str) -> bool:
        if key in self._cache:
            self._remove(key)
            return True
        return False

    def purge_by_prefix(self, prefix: str) -> int:
        keys_to_remove = [k for k in self._cache if k.startswith(prefix)]
        for k in keys_to_remove:
            self._remove(k)
        return len(keys_to_remove)

    def purge_all(self):
        self._cache.clear()
        self._current_size = 0

    @property
    def stats(self) -> dict:
        total = self._hits + self._misses
        return {
            "entries": len(self._cache),
            "size_bytes": self._current_size,
            "max_size_bytes": self._max_size,
            "utilization": self._current_size / self._max_size,
            "hits": self._hits,
            "misses": self._misses,
            "hit_rate": self._hits / total if total > 0 else 0.0,
        }


# ─────────────────────────────────────────────────
# 2. CACHE KEY BUILDER
# ─────────────────────────────────────────────────
class CacheKeyBuilder:
    """Build deterministic cache keys from request properties."""

    VARY_HEADERS = {"accept-encoding", "accept-language", "accept"}

    @classmethod
    def build(cls, request: Request) -> str:
        parts = [
            request.method,
            str(request.url.path),
            str(sorted(request.query_params.items())),
        ]

        # Add Vary-header values
        for header_name in cls.VARY_HEADERS:
            val = request.headers.get(header_name, "")
            parts.append(f"{header_name}={val}")

        raw = "|".join(parts)
        return hashlib.sha256(raw.encode()).hexdigest()


# ─────────────────────────────────────────────────
# 3. GEO DNS RESOLVER (Simplified)
# ─────────────────────────────────────────────────
@dataclass
class PoP:
    id: str
    location: str
    region: str
    latitude: float
    longitude: float
    capacity: int
    current_load: int = 0
    healthy: bool = True

class GeoDNSResolver:
    """Simulates GeoDNS resolution to nearest PoP."""

    def __init__(self):
        self.pops: List[PoP] = []

    def add_pop(self, pop: PoP):
        self.pops.append(pop)

    def resolve(self, client_lat: float, client_lon: float) -> Optional[PoP]:
        healthy_pops = [p for p in self.pops if p.healthy]
        if not healthy_pops:
            return None

        def distance(pop: PoP) -> float:
            # Simplified Euclidean distance (Haversine in production)
            return (
                (pop.latitude - client_lat) ** 2 +
                (pop.longitude - client_lon) ** 2
            ) ** 0.5

        return min(healthy_pops, key=distance)


# ─────────────────────────────────────────────────
# 4. ORIGIN SHIELD (Collapsed Forwarding)
# ─────────────────────────────────────────────────
class OriginShield:
    """
    Prevents thundering herd — when many PoPs have a cache miss
    for the same content simultaneously, only ONE request goes to origin.
    """

    def __init__(self):
        self._inflight: Dict[str, asyncio.Event] = {}
        self._inflight_results: Dict[str, Tuple[int, bytes, dict]] = {}
        self._lock = asyncio.Lock()

    async def fetch_with_coalescing(
        self,
        cache_key: str,
        origin_url: str,
        headers: dict,
    ) -> Tuple[int, bytes, dict]:
        async with self._lock:
            if cache_key in self._inflight:
                # Another request is already fetching this — wait for it
                event = self._inflight[cache_key]
            else:
                # First request for this key — I'll fetch it
                event = asyncio.Event()
                self._inflight[cache_key] = event
                event = None  # Signal that we are the fetcher

        if event is not None:
            # Wait for the fetcher to complete
            await self._inflight[cache_key].wait()
            result = self._inflight_results.get(cache_key)
            if result:
                return result
            raise Exception("Coalesced request failed")

        # I am the fetcher
        try:
            async with aiohttp.ClientSession(
                timeout=aiohttp.ClientTimeout(total=30)
            ) as session:
                async with session.get(origin_url, headers=headers) as resp:
                    body = await resp.read()
                    resp_headers = dict(resp.headers)
                    result = (resp.status, body, resp_headers)
                    self._inflight_results[cache_key] = result
                    return result
        finally:
            # Signal waiting requests
            async with self._lock:
                if cache_key in self._inflight:
                    self._inflight[cache_key].set()
                    # Clean up after a delay
                    await asyncio.sleep(0.1)
                    self._inflight.pop(cache_key, None)
                    self._inflight_results.pop(cache_key, None)


# ─────────────────────────────────────────────────
# 5. PURGE SERVICE
# ─────────────────────────────────────────────────
class PurgeType(str, Enum):
    SINGLE = "single"        # Purge one URL
    PREFIX = "prefix"        # Purge by path prefix
    TAG = "tag"              # Purge by surrogate tag
    ALL = "all"              # Purge everything

class PurgeService:
    """Manages cache purge propagation across all PoPs."""

    def __init__(self):
        self.pop_caches: Dict[str, LRUCache] = {}  # pop_id → cache

    def register_pop_cache(self, pop_id: str, cache: LRUCache):
        self.pop_caches[pop_id] = cache

    async def purge(
        self, purge_type: PurgeType, value: str = ""
    ) -> dict:
        results = {}
        for pop_id, cache in self.pop_caches.items():
            if purge_type == PurgeType.SINGLE:
                key = hashlib.sha256(value.encode()).hexdigest()
                success = cache.purge(key)
                results[pop_id] = {"purged": 1 if success else 0}
            elif purge_type == PurgeType.PREFIX:
                count = cache.purge_by_prefix(value)
                results[pop_id] = {"purged": count}
            elif purge_type == PurgeType.ALL:
                cache.purge_all()
                results[pop_id] = {"purged": "all"}
        return results


# ─────────────────────────────────────────────────
# 6. CDN EDGE SERVER
# ─────────────────────────────────────────────────
class CDNEdgeServer:
    def __init__(
        self,
        pop_id: str,
        origin_base_url: str,
        cache_size_mb: int = 1024,
    ):
        self.pop_id = pop_id
        self.origin_base_url = origin_base_url
        self.cache = LRUCache(max_size_bytes=cache_size_mb * 1024 * 1024)
        self.shield = OriginShield()
        self.app = FastAPI(title=f"CDN Edge - {pop_id}")
        self._setup_routes()

    def _parse_cache_control(self, headers: dict) -> int:
        """Parse Cache-Control header for max-age."""
        cc = headers.get("cache-control", headers.get("Cache-Control", ""))
        for directive in cc.split(","):
            directive = directive.strip()
            if directive.startswith("max-age="):
                try:
                    return int(directive.split("=")[1])
                except ValueError:
                    pass
            if directive in ("no-store", "no-cache", "private"):
                return 0
        return 3600  # Default 1 hour

    def _setup_routes(self):
        @self.app.get("/{path:path}")
        async def serve_content(request: Request, path: str):
            cache_key = CacheKeyBuilder.build(request)

            # 1. Check edge cache
            cached = self.cache.get(cache_key)
            if cached:
                resp_headers = {
                    **cached.headers,
                    "X-Cache": "HIT",
                    "X-Cache-Age": str(cached.age),
                    "X-PoP": self.pop_id,
                    "Age": str(cached.age),
                }
                return Response(
                    content=cached.content,
                    status_code=cached.status_code,
                    headers=resp_headers,
                    media_type=cached.content_type,
                )

            # 2. Cache MISS — fetch from origin (with coalescing)
            origin_url = f"{self.origin_base_url}/{path}"
            if request.query_params:
                origin_url += f"?{request.query_params}"

            fwd_headers = {
                k: v for k, v in request.headers.items()
                if k.lower() not in ("host",)
            }

            status, body, resp_headers = await self.shield.fetch_with_coalescing(
                cache_key, origin_url, fwd_headers
            )

            # 3. Cache the response if cacheable
            ttl = self._parse_cache_control(resp_headers)
            if ttl > 0 and status == 200:
                entry = CacheEntry(
                    content=body,
                    content_type=resp_headers.get(
                        "content-type", "application/octet-stream"
                    ),
                    headers=resp_headers,
                    status_code=status,
                    created_at=time.time(),
                    ttl=ttl,
                    size=len(body),
                )
                self.cache.put(cache_key, entry)

            resp_headers.update({
                "X-Cache": "MISS",
                "X-PoP": self.pop_id,
            })
            return Response(
                content=body,
                status_code=status,
                headers=resp_headers,
            )

        @self.app.get("/_cdn/stats")
        async def cache_stats():
            return self.cache.stats

        @self.app.post("/_cdn/purge")
        async def purge_cache(
            purge_type: str = "single",
            url: str = "",
        ):
            if purge_type == "all":
                self.cache.purge_all()
                return {"purged": "all"}
            key = hashlib.sha256(url.encode()).hexdigest()
            success = self.cache.purge(key)
            return {"purged": success}


# ─────────────────────────────────────────────────
# Usage
# ─────────────────────────────────────────────────
# Create edge server for Tokyo PoP
tokyo_edge = CDNEdgeServer(
    pop_id="nrt-1",
    origin_base_url="https://origin.example.com",
    cache_size_mb=2048,
)

app = tokyo_edge.app
# Run: uvicorn cdn_edge:app --host 0.0.0.0 --port 8080
```

---

## 22. Distributed Logging System

---

### Architecture

```
┌──────────────────────────────────────────────────────────────────────────┐
│                     DISTRIBUTED LOGGING SYSTEM                           │
│                                                                          │
│   ┌───────────┐  ┌───────────┐  ┌───────────┐  ┌───────────┐           │
│   │ Service A │  │ Service B │  │ Service C │  │ Service D │           │
│   │┌─────────┐│  │┌─────────┐│  │┌─────────┐│  │┌─────────┐│           │
│   ││Log Agent││  ││Log Agent││  ││Log Agent││  ││Log Agent││           │
│   │└────┬────┘│  │└────┬────┘│  │└────┬────┘│  │└────┬────┘│           │
│   └─────┼─────┘  └─────┼─────┘  └─────┼─────┘  └─────┼─────┘           │
│         │              │              │              │                    │
│         └──────────────┼──────────────┼──────────────┘                    │
│                        │              │                                   │
│                        ▼              ▼                                   │
│   ┌─────────────────────────────────────────────────────────────┐        │
│   │               MESSAGE QUEUE (Kafka)                         │        │
│   │                                                             │        │
│   │  Topic: logs.raw     Topic: logs.errors    Topic: logs.audit│        │
│   │  ┌──┬──┬──┬──┐      ┌──┬──┬──┐           ┌──┬──┬──┐       │        │
│   │  │P0│P1│P2│P3│      │P0│P1│P2│           │P0│P1│P2│       │        │
│   │  └──┴──┴──┴──┘      └──┴──┴──┘           └──┴──┴──┘       │        │
│   └────────────────┬────────────────┬───────────────────────────┘        │
│                    │                │                                     │
│            ┌───────┴──────┐  ┌──────┴────────┐                           │
│            ▼              ▼  ▼               ▼                           │
│   ┌────────────────┐  ┌────────────────┐  ┌────────────────┐            │
│   │ Log Processor  │  │ Log Processor  │  │ Alert Engine   │            │
│   │ (Transform,    │  │ (Aggregate,    │  │ (Pattern match │            │
│   │  Enrich,       │  │  Sample)       │  │  threshold)    │            │
│   │  Filter)       │  │                │  │                │            │
│   └───────┬────────┘  └───────┬────────┘  └───────┬────────┘            │
│           │                   │                    │                      │
│           ▼                   ▼                    ▼                      │
│   ┌────────────────────────────────────┐  ┌──────────────────┐           │
│   │     Elasticsearch Cluster          │  │ PagerDuty/Slack  │           │
│   │                                    │  └──────────────────┘           │
│   │  ┌────────┐ ┌────────┐ ┌────────┐ │                                 │
│   │  │ Data   │ │ Data   │ │ Data   │ │                                 │
│   │  │ Node 1 │ │ Node 2 │ │ Node 3 │ │                                 │
│   │  └────────┘ └────────┘ └────────┘ │                                 │
│   │  Hot ─────▶ Warm ─────▶ Cold      │  (ILM: Index Lifecycle Mgmt)    │
│   └───────────────┬────────────────────┘                                 │
│                   │                                                      │
│                   ▼                                                      │
│   ┌────────────────────────────────────┐                                 │
│   │          Kibana / Grafana          │                                 │
│   │  • Search & explore logs           │                                 │
│   │  • Dashboards                      │                                 │
│   │  • Saved queries                   │                                 │
│   │  • Distributed tracing view        │                                 │
│   └────────────────────────────────────┘                                 │
│                                                                          │
│   ┌────────────────────────────────────┐                                 │
│   │          Cold Storage              │                                 │
│   │  S3/GCS (compressed, > 30 days)    │                                 │
│   └────────────────────────────────────┘                                 │
└──────────────────────────────────────────────────────────────────────────┘
```

### Log Entry Structure

```
┌─────────────── STRUCTURED LOG FORMAT ──────────────────┐
│                                                         │
│  {                                                      │
│    "timestamp": "2024-01-15T10:23:45.123Z",            │
│    "level": "ERROR",                                    │
│    "service": "order-service",                          │
│    "instance": "order-svc-pod-abc123",                  │
│    "trace_id": "abc123def456",          ◄── distributed │
│    "span_id": "span789",                    tracing     │
│    "parent_span_id": "span456",                         │
│    "message": "Failed to process order",                │
│    "error": {                                           │
│      "type": "PaymentDeclinedException",                │
│      "message": "Card declined",                        │
│      "stack_trace": "..."                               │
│    },                                                   │
│    "context": {                                         │
│      "user_id": "u_12345",                              │
│      "order_id": "ord_67890",                           │
│      "amount": 99.99,                                   │
│      "payment_method": "visa_****4242"                  │
│    },                                                   │
│    "metadata": {                                        │
│      "host": "10.0.1.15",                               │
│      "environment": "production",                       │
│      "version": "2.3.1",                                │
│      "region": "us-east-1"                              │
│    }                                                    │
│  }                                                      │
└─────────────────────────────────────────────────────────┘
```

### Python Implementation

```python
"""
Distributed Logging System — Agent, Processor, Query API
"""
import json
import time
import uuid
import gzip
import logging
import threading
import traceback
from datetime import datetime, timedelta
from dataclasses import dataclass, field
from typing import Optional, Dict, List, Any, Callable
from enum import Enum
from collections import deque
from queue import Queue, Full
import asyncio

from fastapi import FastAPI, Query, HTTPException
from pydantic import BaseModel

# ─────────────────────────────────────────────────
# 1. LOG LEVELS & STRUCTURED LOG ENTRY
# ─────────────────────────────────────────────────
class LogLevel(str, Enum):
    TRACE = "TRACE"
    DEBUG = "DEBUG"
    INFO = "INFO"
    WARN = "WARN"
    ERROR = "ERROR"
    FATAL = "FATAL"

LOG_LEVEL_PRIORITY = {
    LogLevel.TRACE: 0,
    LogLevel.DEBUG: 1,
    LogLevel.INFO: 2,
    LogLevel.WARN: 3,
    LogLevel.ERROR: 4,
    LogLevel.FATAL: 5,
}

@dataclass
class LogEntry:
    timestamp: str
    level: LogLevel
    service: str
    message: str
    instance: str = ""
    trace_id: str = ""
    span_id: str = ""
    parent_span_id: str = ""
    error: Optional[Dict[str, str]] = None
    context: Dict[str, Any] = field(default_factory=dict)
    metadata: Dict[str, Any] = field(default_factory=dict)
    tags: List[str] = field(default_factory=list)

    def to_dict(self) -> dict:
        d = {
            "timestamp": self.timestamp,
            "level": self.level.value,
            "service": self.service,
            "instance": self.instance,
            "message": self.message,
            "trace_id": self.trace_id,
            "span_id": self.span_id,
            "context": self.context,
            "metadata": self.metadata,
            "tags": self.tags,
        }
        if self.error:
            d["error"] = self.error
        if self.parent_span_id:
            d["parent_span_id"] = self.parent_span_id
        return d

    def to_json(self) -> str:
        return json.dumps(self.to_dict())


# ─────────────────────────────────────────────────
# 2. CONTEXT PROPAGATION (for Distributed Tracing)
# ─────────────────────────────────────────────────
import contextvars

_trace_id_var: contextvars.ContextVar[str] = contextvars.ContextVar(
    "trace_id", default=""
)
_span_id_var: contextvars.ContextVar[str] = contextvars.ContextVar(
    "span_id", default=""
)

class TraceContext:
    @staticmethod
    def new_trace() -> str:
        trace_id = uuid.uuid4().hex
        _trace_id_var.set(trace_id)
        _span_id_var.set(uuid.uuid4().hex[:16])
        return trace_id

    @staticmethod
    def new_span() -> str:
        span_id = uuid.uuid4().hex[:16]
        _span_id_var.set(span_id)
        return span_id

    @staticmethod
    def get_trace_id() -> str:
        return _trace_id_var.get()

    @staticmethod
    def get_span_id() -> str:
        return _span_id_var.get()

    @staticmethod
    def set_from_headers(headers: dict):
        if "X-Trace-Id" in headers:
            _trace_id_var.set(headers["X-Trace-Id"])
        if "X-Span-Id" in headers:
            _span_id_var.set(headers["X-Span-Id"])


# ─────────────────────────────────────────────────
# 3. LOG AGENT (runs in each service)
# ─────────────────────────────────────────────────
class LogTransport:
    """Abstract transport for sending logs."""
    def send(self, entries: List[LogEntry]):
        raise NotImplementedError


class StdoutTransport(LogTransport):
    """Print to stdout (for development)."""
    def send(self, entries: List[LogEntry]):
        for entry in entries:
            print(entry.to_json())


class KafkaTransport(LogTransport):
    """Send logs to Kafka (production)."""
    def __init__(self, bootstrap_servers: str, topic: str = "logs.raw"):
        self.topic = topic
        self.bootstrap_servers = bootstrap_servers
        # In production: from confluent_kafka import Producer
        # self.producer = Producer({"bootstrap.servers": bootstrap_servers})

    def send(self, entries: List[LogEntry]):
        for entry in entries:
            key = entry.service.encode()
            value = entry.to_json().encode()
            # self.producer.produce(self.topic, key=key, value=value)
            # self.producer.flush()
            pass  # Placeholder


class HTTPTransport(LogTransport):
    """Send logs via HTTP to collector."""
    def __init__(self, endpoint: str):
        self.endpoint = endpoint

    def send(self, entries: List[LogEntry]):
        import requests
        payload = [e.to_dict() for e in entries]
        try:
            requests.post(
                self.endpoint,
                json=payload,
                timeout=5,
                headers={"Content-Type": "application/json"}
            )
        except Exception:
            pass  # Don't crash the app because of logging


class LogAgent:
    """
    Buffers log entries and sends them in batches.
    Used within each microservice.
    
    Usage:
        logger = LogAgent(
            service="order-service",
            transports=[KafkaTransport("kafka:9092")],
        )
        logger.info("Order created", context={"order_id": "123"})
        logger.error("Payment failed", error=exc)
    """

    def __init__(
        self,
        service: str,
        instance: str = "",
        transports: List[LogTransport] = None,
        min_level: LogLevel = LogLevel.INFO,
        buffer_size: int = 100,
        flush_interval: float = 5.0,
        environment: str = "production",
        version: str = "unknown",
    ):
        self.service = service
        self.instance = instance or f"{service}-{uuid.uuid4().hex[:8]}"
        self.transports = transports or [StdoutTransport()]
        self.min_level = min_level
        self.environment = environment
        self.version = version

        self._buffer: deque = deque(maxlen=buffer_size * 2)
        self._buffer_size = buffer_size
        self._flush_interval = flush_interval

        # Start background flush thread
        self._running = True
        self._flush_thread = threading.Thread(
            target=self._flush_loop, daemon=True
        )
        self._flush_thread.start()

    def _should_log(self, level: LogLevel) -> bool:
        return LOG_LEVEL_PRIORITY[level] >= LOG_LEVEL_PRIORITY[self.min_level]

    def _create_entry(
        self,
        level: LogLevel,
        message: str,
        error: Exception = None,
        context: Dict = None,
        tags: List[str] = None,
    ) -> LogEntry:
        entry = LogEntry(
            timestamp=datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%S.%f")[:-3] + "Z",
            level=level,
            service=self.service,
            instance=self.instance,
            message=message,
            trace_id=TraceContext.get_trace_id(),
            span_id=TraceContext.get_span_id(),
            context=context or {},
            metadata={
                "environment": self.environment,
                "version": self.version,
            },
            tags=tags or [],
        )
        if error:
            entry.error = {
                "type": type(error).__name__,
                "message": str(error),
                "stack_trace": traceback.format_exc(),
            }
        return entry

    def log(
        self,
        level: LogLevel,
        message: str,
        error: Exception = None,
        context: Dict = None,
        tags: List[str] = None,
    ):
        if not self._should_log(level):
            return
        entry = self._create_entry(level, message, error, context, tags)
        self._buffer.append(entry)
        if len(self._buffer) >= self._buffer_size:
            self._flush()

    def trace(self, msg, **kwargs):
        self.log(LogLevel.TRACE, msg, **kwargs)

    def debug(self, msg, **kwargs):
        self.log(LogLevel.DEBUG, msg, **kwargs)

    def info(self, msg, **kwargs):
        self.log(LogLevel.INFO, msg, **kwargs)

    def warn(self, msg, **kwargs):
        self.log(LogLevel.WARN, msg, **kwargs)

    def error(self, msg, **kwargs):
        self.log(LogLevel.ERROR, msg, **kwargs)

    def fatal(self, msg, **kwargs):
        self.log(LogLevel.FATAL, msg, **kwargs)

    def _flush(self):
        entries = []
        while self._buffer:
            try:
                entries.append(self._buffer.popleft())
            except IndexError:
                break

        if entries:
            for transport in self.transports:
                try:
                    transport.send(entries)
                except Exception as e:
                    print(f"Failed to send logs via {transport}: {e}")

    def _flush_loop(self):
        while self._running:
            time.sleep(self._flush_interval)
            self._flush()

    def shutdown(self):
        self._running = False
        self._flush()


# ─────────────────────────────────────────────────
# 4. LOG PROCESSOR (consumes from Kafka, enriches, writes to ES)
# ─────────────────────────────────────────────────
class LogProcessor:
    """
    Consumes raw logs, applies transformations:
    - PII masking
    - GeoIP enrichment
    - Sampling for high-volume services
    - Routing (errors → separate index)
    """

    def __init__(self):
        self.transformers: List[Callable[[dict], dict]] = []
        self.filters: List[Callable[[dict], bool]] = []
        self.sample_rates: Dict[str, float] = {}  # service → rate (0-1)

    def add_transformer(self, fn: Callable[[dict], dict]):
        self.transformers.append(fn)

    def add_filter(self, fn: Callable[[dict], bool]):
        self.filters.append(fn)

    def set_sample_rate(self, service: str, rate: float):
        self.sample_rates[service] = max(0.0, min(1.0, rate))

    def process(self, raw_log: dict) -> Optional[dict]:
        # 1. Sampling
        service = raw_log.get("service", "")
        if service in self.sample_rates:
            import random
            if random.random() > self.sample_rates[service]:
                return None  # Sampled out

        # 2. Filters (drop if any filter returns False)
        for f in self.filters:
            if not f(raw_log):
                return None

        # 3. Transformations
        processed = raw_log.copy()
        for t in self.transformers:
            processed = t(processed)

        return processed


# Built-in transformers
def mask_pii(log: dict) -> dict:
    """Mask sensitive fields."""
    PII_FIELDS = {"email", "phone", "ssn", "credit_card", "password"}
    context = log.get("context", {})
    for key in PII_FIELDS:
        if key in context:
            val = str(context[key])
            if len(val) > 4:
                context[key] = val[:2] + "*" * (len(val) - 4) + val[-2:]
            else:
                context[key] = "****"
    log["context"] = context
    return log


def enrich_with_geo(log: dict) -> dict:
    """Add geo information based on IP (simplified)."""
    ip = log.get("metadata", {}).get("client_ip")
    if ip:
        # In production: use MaxMind GeoIP database
        log.setdefault("geo", {})
        log["geo"]["country"] = "US"  # placeholder
    return log


def normalize_timestamp(log: dict) -> dict:
    """Ensure timestamp is in ISO 8601 format."""
    ts = log.get("timestamp", "")
    if ts and not ts.endswith("Z"):
        log["timestamp"] = ts + "Z"
    return log


# ─────────────────────────────────────────────────
# 5. LOG STORAGE (Elasticsearch-like index management)
# ─────────────────────────────────────────────────
class LogStorageBackend:
    """
    Manages log storage with Index Lifecycle Management (ILM):
    - Hot tier:  recent logs, SSD, full replicas (0-7 days)
    - Warm tier: older logs, HDD, fewer replicas (7-30 days)  
    - Cold tier: S3/GCS, compressed (30-365 days)
    - Delete:    > 365 days
    """

    def __init__(self):
        self._indices: Dict[str, List[dict]] = {}  # index_name → logs
        self._hot_days = 7
        self._warm_days = 30
        self._cold_days = 365

    def get_index_name(self, log: dict) -> str:
        """Index per service per day: logs-order-service-2024.01.15"""
        ts = log.get("timestamp", "")[:10]  # YYYY-MM-DD
        service = log.get("service", "unknown").replace("-", "_")
        level = log.get("level", "INFO")
        
        # Separate index for errors
        if level in ("ERROR", "FATAL"):
            return f"logs-errors-{service}-{ts}"
        return f"logs-{service}-{ts}"

    def store(self, log: dict):
        index = self.get_index_name(log)
        if index not in self._indices:
            self._indices[index] = []
        log["_id"] = uuid.uuid4().hex
        log["_indexed_at"] = datetime.utcnow().isoformat()
        self._indices[index].append(log)

    def search(
        self,
        query: str = "",
        service: str = None,
        level: str = None,
        trace_id: str = None,
        start_time: str = None,
        end_time: str = None,
        limit: int = 100,
    ) -> List[dict]:
        results = []
        for index_name, logs in self._indices.items():
            for log in logs:
                if self._matches(
                    log, query, service, level, trace_id,
                    start_time, end_time
                ):
                    results.append(log)

        # Sort by timestamp descending
        results.sort(key=lambda x: x.get("timestamp", ""), reverse=True)
        return results[:limit]

    def _matches(
        self, log, query, service, level, trace_id,
        start_time, end_time
    ) -> bool:
        if service and log.get("service") != service:
            return False
        if level and log.get("level") != level:
            return False
        if trace_id and log.get("trace_id") != trace_id:
            return False
        if start_time and log.get("timestamp", "") < start_time:
            return False
        if end_time and log.get("timestamp", "") > end_time:
            return False
        if query and query.lower() not in json.dumps(log).lower():
            return False
        return True

    def get_stats(self) -> dict:
        total = sum(len(logs) for logs in self._indices.values())
        return {
            "total_logs": total,
            "indices": len(self._indices),
            "index_names": list(self._indices.keys()),
        }


# ─────────────────────────────────────────────────
# 6. ALERT ENGINE
# ─────────────────────────────────────────────────
@dataclass
class AlertRule:
    id: str
    name: str
    condition: str         # "level == ERROR"
    service: str = "*"     # which service to monitor
    threshold: int = 10    # trigger if count > threshold
    window_seconds: int = 300  # in last 5 minutes
    cooldown_seconds: int = 600
    channels: List[str] = field(default_factory=lambda: ["slack"])
    enabled: bool = True

class AlertEngine:
    def __init__(self):
        self.rules: List[AlertRule] = []
        self._counters: Dict[str, deque] = {}  # rule_id → timestamps
        self._last_fired: Dict[str, float] = {}

    def add_rule(self, rule: AlertRule):
        self.rules.append(rule)
        self._counters[rule.id] = deque()

    def evaluate(self, log: dict):
        for rule in self.rules:
            if not rule.enabled:
                continue

            if rule.service != "*" and log.get("service") != rule.service:
                continue

            if self._matches_condition(rule.condition, log):
                now = time.time()
                counter = self._counters[rule.id]
                counter.append(now)

                # Remove entries outside the window
                cutoff = now - rule.window_seconds
                while counter and counter[0] < cutoff:
                    counter.popleft()

                # Check threshold
                if len(counter) >= rule.threshold:
                    # Check cooldown
                    last = self._last_fired.get(rule.id, 0)
                    if now - last > rule.cooldown_seconds:
                        self._fire_alert(rule, len(counter), log)
                        self._last_fired[rule.id] = now

    def _matches_condition(self, condition: str, log: dict) -> bool:
        """Simple condition evaluator."""
        if "level == ERROR" in condition:
            return log.get("level") in ("ERROR", "FATAL")
        if "level == FATAL" in condition:
            return log.get("level") == "FATAL"
        return False

    def _fire_alert(self, rule: AlertRule, count: int, sample_log: dict):
        alert = {
            "rule": rule.name,
            "count": count,
            "window": f"{rule.window_seconds}s",
            "service": sample_log.get("service"),
            "sample_message": sample_log.get("message"),
            "trace_id": sample_log.get("trace_id"),
        }
        print(f"🚨 ALERT: {json.dumps(alert, indent=2)}")
        # In production: send to Slack, PagerDuty, etc.


# ─────────────────────────────────────────────────
# 7. LOG QUERY API
# ─────────────────────────────────────────────────
app = FastAPI(title="Log Query Service")
storage = LogStorageBackend()
processor = LogProcessor()
processor.add_transformer(mask_pii)
processor.add_transformer(normalize_timestamp)
alert_engine = AlertEngine()

# Add default alert rule
alert_engine.add_rule(AlertRule(
    id="high-error-rate",
    name="High Error Rate",
    condition="level == ERROR",
    threshold=50,
    window_seconds=300,
))


class IngestRequest(BaseModel):
    logs: List[dict]

@app.post("/ingest")
def ingest_logs(req: IngestRequest):
    """Receive logs from agents/Kafka consumers."""
    processed_count = 0
    for raw_log in req.logs:
        processed = processor.process(raw_log)
        if processed:
            storage.store(processed)
            alert_engine.evaluate(processed)
            processed_count += 1
    return {"ingested": processed_count, "dropped": len(req.logs) - processed_count}


@app.get("/search")
def search_logs(
    q: str = Query("", description="Full-text search"),
    service: Optional[str] = None,
    level: Optional[str] = None,
    trace_id: Optional[str] = None,
    start: Optional[str] = None,
    end: Optional[str] = None,
    limit: int = Query(100, le=1000),
):
    results = storage.search(
        query=q, service=service, level=level,
        trace_id=trace_id, start_time=start, end_time=end,
        limit=limit,
    )
    return {"total": len(results), "logs": results}


@app.get("/trace/{trace_id}")
def get_trace(trace_id: str):
    """Get all logs for a distributed trace — reconstruct call chain."""
    logs = storage.search(trace_id=trace_id, limit=1000)
    # Sort by timestamp to show call flow
    logs.sort(key=lambda x: x.get("timestamp", ""))
    return {
        "trace_id": trace_id,
        "span_count": len(logs),
        "services": list(set(l.get("service", "") for l in logs)),
        "spans": logs,
    }


@app.get("/stats")
def get_stats():
    return storage.get_stats()


# ─────────────────────────────────────────────────
# 8. USAGE EXAMPLE IN A MICROSERVICE
# ─────────────────────────────────────────────────
"""
# In your order-service:

from log_system import LogAgent, KafkaTransport, TraceContext

logger = LogAgent(
    service="order-service",
    transports=[
        KafkaTransport("kafka:9092"),
    ],
    min_level=LogLevel.INFO,
    environment="production",
    version="2.3.1",
)

@app.middleware("http")
async def logging_middleware(request, call_next):
    # Extract or create trace context
    TraceContext.set_from_headers(dict(request.headers))
    if not TraceContext.get_trace_id():
        TraceContext.new_trace()
    TraceContext.new_span()
    
    start = time.time()
    response = await call_next(request)
    duration = time.time() - start
    
    logger.info(
        f"{request.method} {request.url.path} → {response.status_code}",
        context={
            "method": request.method,
            "path": str(request.url.path),
            "status_code": response.status_code,
            "duration_ms": round(duration * 1000, 2),
            "client_ip": request.client.host,
        }
    )
    
    # Propagate trace headers downstream
    response.headers["X-Trace-Id"] = TraceContext.get_trace_id()
    response.headers["X-Span-Id"] = TraceContext.get_span_id()
    return response

@app.post("/orders")
def create_order(order_data: dict):
    try:
        logger.info("Creating order", context={"items": len(order_data["items"])})
        order = order_service.create(order_data)
        logger.info("Order created", context={"order_id": order.id})
        return order
    except PaymentError as e:
        logger.error(
            "Payment failed during order creation",
            error=e,
            context={"order_data": order_data},
            tags=["payment", "critical"],
        )
        raise
"""
```

---

## Summary Comparison

| System | Core Challenge | Key Pattern | Storage |
|--------|---------------|-------------|---------|
| **API Gateway** | Single entry point, cross-cutting | Chain of Responsibility, Proxy | Redis (rate limit, cache) |
| **Auth System** | Security, token lifecycle | JWT + Refresh rotation, RBAC/ABAC | PostgreSQL + Redis (blacklist) |
| **Feature Flags** | Safe rollout, targeting | Consistent hashing, Rule engine | Redis + local cache |
| **Payments** | Correctness, idempotency | State machine, Double-entry ledger, Strategy (PSP) | PostgreSQL + Redis (idempotency) |
| **CDN** | Latency, cache efficiency | LRU + TTL, Collapsed forwarding, GeoDNS | Edge memory + Origin |
| **Logging** | Volume, searchability | Buffered agent, Pipeline, ILM | Kafka → Elasticsearch → S3 |



# Data-Intensive System Design (HLD)

---

## 23. Real-Time Analytics System

### Problem Statement

Design a system that ingests millions of events per second, processes them in real-time, and serves analytical queries with sub-second latency (think Google Analytics, Mixpanel, or an internal dashboard).

---

### Functional Requirements

```
1. Ingest high-volume event streams (clicks, page views, transactions)
2. Compute real-time aggregations (counts, sums, percentiles)
3. Support time-windowed queries (last 5 min, 1 hour, 1 day)
4. Provide dashboard APIs with sub-second response
5. Support dimensional drill-downs (by country, device, page)
```

### Non-Functional Requirements

```
- Throughput: 1M+ events/sec ingestion
- Query latency: < 500ms for dashboards
- Data freshness: < 5 seconds end-to-end
- Availability: 99.99%
- Retention: raw data 30 days, aggregates forever
```

---

### High-Level Architecture (Lambda + Kappa Hybrid)

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        REAL-TIME ANALYTICS SYSTEM                       │
│                                                                         │
│  ┌──────────┐    ┌──────────────┐    ┌─────────────────────────────┐   │
│  │  Web/App  │    │  Mobile SDK  │    │      Server-side Events     │   │
│  └────┬─────┘    └──────┬───────┘    └──────────────┬──────────────┘   │
│       │                 │                            │                   │
│       ▼                 ▼                            ▼                   │
│  ┌──────────────────────────────────────────────────────────────────┐   │
│  │                    API Gateway / Load Balancer                    │   │
│  │              (Rate limiting, Auth, Schema validation)            │   │
│  └──────────────────────────┬───────────────────────────────────────┘   │
│                             │                                           │
│                             ▼                                           │
│  ┌──────────────────────────────────────────────────────────────────┐   │
│  │                  Event Collection Service                        │   │
│  │            (Stateless, horizontally scalable)                    │   │
│  │         - Schema validation & enrichment                        │   │
│  │         - Geo-IP lookup, User-Agent parsing                     │   │
│  │         - Batching & compression                                │   │
│  └──────────────────────────┬───────────────────────────────────────┘   │
│                             │                                           │
│                             ▼                                           │
│  ┌──────────────────────────────────────────────────────────────────┐   │
│  │                    Apache Kafka (Event Bus)                      │   │
│  │              Partitioned by (event_type, user_id)               │   │
│  │                                                                  │   │
│  │  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐              │   │
│  │  │ Part 0  │ │ Part 1  │ │ Part 2  │ │ Part N  │              │   │
│  │  └─────────┘ └─────────┘ └─────────┘ └─────────┘              │   │
│  └──────┬──────────────┬────────────────────┬──────────────────────┘   │
│         │              │                    │                           │
│    ┌────▼────┐   ┌─────▼──────┐    ┌───────▼────────┐                 │
│    │ SPEED   │   │  BATCH     │    │   RAW STORAGE  │                 │
│    │ LAYER   │   │  LAYER     │    │                │                 │
│    │         │   │            │    │                │                 │
│    │ Apache  │   │ Apache     │    │  S3 / HDFS     │                 │
│    │ Flink   │   │ Spark      │    │  (Parquet)     │                 │
│    │         │   │            │    │                │                 │
│    │ Real-   │   │ Hourly/    │    │  Data Lake     │                 │
│    │ time    │   │ Daily      │    │  (30-day       │                 │
│    │ aggs    │   │ aggs       │    │   retention)   │                 │
│    └────┬────┘   └─────┬──────┘    └────────────────┘                 │
│         │              │                                               │
│         ▼              ▼                                               │
│  ┌──────────────────────────────────────────────────────────────────┐   │
│  │                    SERVING LAYER                                  │   │
│  │                                                                  │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌────────────────────┐     │   │
│  │  │    Redis      │  │   Apache     │  │   ClickHouse /     │     │   │
│  │  │  (Hot aggs,   │  │   Druid      │  │   Apache Pinot     │     │   │
│  │  │   last 5min)  │  │  (OLAP cube) │  │  (Ad-hoc queries)  │     │   │
│  │  └──────┬───────┘  └──────┬───────┘  └────────┬───────────┘     │   │
│  │         │                 │                    │                  │   │
│  └─────────┴─────────────────┴────────────────────┴─────────────────┘   │
│                             │                                           │
│                             ▼                                           │
│  ┌──────────────────────────────────────────────────────────────────┐   │
│  │                    Query / API Service                           │   │
│  │              (REST + WebSocket for live dashboards)              │   │
│  └──────────────────────────┬───────────────────────────────────────┘   │
│                             │                                           │
│                             ▼                                           │
│  ┌──────────────────────────────────────────────────────────────────┐   │
│  │                    Dashboard UI (Grafana / Custom)               │   │
│  └──────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────┘
```

---

### Deep Dive: Stream Processing Engine

```
┌─────────────────────────────────────────────────────────────────┐
│                 FLINK STREAM PROCESSING TOPOLOGY                │
│                                                                 │
│   Kafka Source                                                  │
│       │                                                         │
│       ▼                                                         │
│   ┌─────────────────┐                                          │
│   │  Deserialize &  │                                          │
│   │  Validate       │                                          │
│   └────────┬────────┘                                          │
│            │                                                    │
│            ▼                                                    │
│   ┌─────────────────┐                                          │
│   │   Enrich Event  │◄──── Lookup: GeoIP DB, User Profile     │
│   │   (Side Input)  │      Cache (Redis/RocksDB)              │
│   └────────┬────────┘                                          │
│            │                                                    │
│       ┌────┴────────────────────────┐                          │
│       │                             │                          │
│       ▼                             ▼                          │
│   ┌───────────────┐      ┌──────────────────┐                 │
│   │  Tumbling     │      │   Sliding        │                 │
│   │  Window       │      │   Window         │                 │
│   │  (1 min)      │      │   (5 min,        │                 │
│   │               │      │    slide 30s)    │                 │
│   │  COUNT BY:    │      │                  │                 │
│   │  - page       │      │  PERCENTILES:    │                 │
│   │  - country    │      │  - p50, p95, p99 │                 │
│   │  - device     │      │  - latency       │                 │
│   └───────┬───────┘      └────────┬─────────┘                 │
│           │                       │                            │
│           ▼                       ▼                            │
│   ┌─────────────────────────────────────┐                     │
│   │      Aggregate Sink (Multi-fan-out) │                     │
│   │                                     │                     │
│   │  → Redis (hot counters)            │                     │
│   │  → Druid (OLAP segments)           │                     │
│   │  → Kafka (downstream consumers)    │                     │
│   │  → Alerting (threshold breaches)   │                     │
│   └─────────────────────────────────────┘                     │
└─────────────────────────────────────────────────────────────────┘
```

---

### Windowing Strategies

```
TIME ──────────────────────────────────────────►

TUMBLING WINDOW (non-overlapping, 1 min):
┌──────────┐┌──────────┐┌──────────┐┌──────────┐
│ Window 1 ││ Window 2 ││ Window 3 ││ Window 4 │
│ 00-01min ││ 01-02min ││ 02-03min ││ 03-04min │
└──────────┘└──────────┘└──────────┘└──────────┘

SLIDING WINDOW (overlapping, 5 min window, 1 min slide):
┌──────────────────────────────────────────────────┐
│ Window 1:  00:00 - 05:00                         │
└──────────────────────────────────────────────────┘
   ┌──────────────────────────────────────────────────┐
   │ Window 2:  01:00 - 06:00                         │
   └──────────────────────────────────────────────────┘
      ┌──────────────────────────────────────────────────┐
      │ Window 3:  02:00 - 07:00                         │
      └──────────────────────────────────────────────────┘

SESSION WINDOW (gap-based, per user):
User A: ┌─────────────┐         ┌──────────┐
         │  Session 1  │  >30min │ Session 2│
         └─────────────┘  gap    └──────────┘

HOPPING WINDOW (for unique counts):
Uses HyperLogLog for memory-efficient cardinality estimation
```

---

### Pre-Aggregation Strategy

```
┌──────────────────────────────────────────────────────────────┐
│                   AGGREGATION HIERARCHY                       │
│                                                              │
│   Raw Events (1M/sec)                                        │
│       │                                                      │
│       ▼                                                      │
│   Per-Second Counters (aggregated in Flink)                  │
│       │                                                      │
│       ▼                                                      │
│   Per-Minute Rollups → Redis (TTL: 24 hours)                │
│       │                                                      │
│       ▼                                                      │
│   Per-Hour Rollups → Druid/ClickHouse (TTL: 90 days)        │
│       │                                                      │
│       ▼                                                      │
│   Per-Day Rollups → Druid/ClickHouse (TTL: forever)         │
│                                                              │
│   SPACE SAVINGS:                                             │
│   Raw: 86.4B events/day → ~8.6 TB                           │
│   1-min rollup: 1440 × dimensions → ~14 GB                  │
│   1-hour rollup: 24 × dimensions → ~240 MB                  │
│   1-day rollup: 1 × dimensions → ~10 MB                     │
└──────────────────────────────────────────────────────────────┘
```

---

### Python Implementation

#### Event Collection Service

```python
"""
Event Collection Service - FastAPI-based ingestion endpoint
Handles schema validation, enrichment, and Kafka publishing.
"""

import asyncio
import json
import time
import hashlib
from datetime import datetime, timezone
from typing import Optional, List, Dict, Any
from dataclasses import dataclass, field, asdict
from enum import Enum
from collections import defaultdict

import uvicorn
from fastapi import FastAPI, HTTPException, Request, BackgroundTasks
from pydantic import BaseModel, Field, validator
from confluent_kafka import Producer
import geoip2.database  # MaxMind GeoIP


# ──────────────────────────────────────────────
# Data Models
# ──────────────────────────────────────────────

class EventType(str, Enum):
    PAGE_VIEW = "page_view"
    CLICK = "click"
    PURCHASE = "purchase"
    SIGNUP = "signup"
    CUSTOM = "custom"


class EventPayload(BaseModel):
    """Incoming event schema with validation."""
    event_type: EventType
    timestamp: Optional[float] = None  # Unix timestamp; server fills if absent
    user_id: Optional[str] = None
    session_id: Optional[str] = None
    page_url: Optional[str] = None
    referrer: Optional[str] = None
    properties: Dict[str, Any] = Field(default_factory=dict)

    @validator('timestamp', pre=True, always=True)
    def set_timestamp(cls, v):
        if v is None:
            return time.time()
        # Reject timestamps more than 1 hour in the future or 7 days in the past
        now = time.time()
        if v > now + 3600 or v < now - 7 * 86400:
            raise ValueError("Timestamp out of acceptable range")
        return v


class EventBatch(BaseModel):
    """Batch of events for bulk ingestion."""
    events: List[EventPayload] = Field(..., max_items=500)


class EnrichedEvent(BaseModel):
    """Event after enrichment, ready for Kafka."""
    event_id: str
    event_type: str
    timestamp: float
    received_at: float
    user_id: Optional[str]
    session_id: Optional[str]
    page_url: Optional[str]
    referrer: Optional[str]
    properties: Dict[str, Any]
    # Enriched fields
    country: Optional[str] = None
    city: Optional[str] = None
    device_type: Optional[str] = None
    browser: Optional[str] = None
    os: Optional[str] = None
    # Derived
    date_partition: str = ""  # e.g., "2024-01-15"
    hour_bucket: int = 0


# ──────────────────────────────────────────────
# GeoIP Enricher
# ──────────────────────────────────────────────

class GeoIPEnricher:
    """Enriches events with geographic information using MaxMind DB."""

    def __init__(self, db_path: str = "GeoLite2-City.mmdb"):
        try:
            self.reader = geoip2.database.Reader(db_path)
        except Exception:
            self.reader = None
            print("⚠️  GeoIP database not found; geo-enrichment disabled")

    def enrich(self, ip: str) -> Dict[str, str]:
        if not self.reader:
            return {"country": "unknown", "city": "unknown"}
        try:
            response = self.reader.city(ip)
            return {
                "country": response.country.iso_code or "unknown",
                "city": response.city.name or "unknown",
            }
        except Exception:
            return {"country": "unknown", "city": "unknown"}


# ──────────────────────────────────────────────
# User-Agent Parser (simplified)
# ──────────────────────────────────────────────

class UAParser:
    """Parses User-Agent strings into device/browser/os."""

    @staticmethod
    def parse(ua_string: str) -> Dict[str, str]:
        ua = ua_string.lower()
        # Device type
        if "mobile" in ua or "android" in ua or "iphone" in ua:
            device = "mobile"
        elif "tablet" in ua or "ipad" in ua:
            device = "tablet"
        else:
            device = "desktop"

        # Browser detection
        if "chrome" in ua and "edg" not in ua:
            browser = "chrome"
        elif "firefox" in ua:
            browser = "firefox"
        elif "safari" in ua and "chrome" not in ua:
            browser = "safari"
        elif "edg" in ua:
            browser = "edge"
        else:
            browser = "other"

        # OS detection
        if "windows" in ua:
            os_name = "windows"
        elif "mac" in ua:
            os_name = "macos"
        elif "linux" in ua:
            os_name = "linux"
        elif "android" in ua:
            os_name = "android"
        elif "iphone" in ua or "ipad" in ua:
            os_name = "ios"
        else:
            os_name = "other"

        return {"device_type": device, "browser": browser, "os": os_name}


# ──────────────────────────────────────────────
# Kafka Producer Wrapper
# ──────────────────────────────────────────────

class KafkaEventProducer:
    """Async-friendly Kafka producer with batching."""

    def __init__(self, bootstrap_servers: str = "localhost:9092",
                 topic: str = "analytics-events"):
        self.topic = topic
        self.producer = Producer({
            'bootstrap.servers': bootstrap_servers,
            'linger.ms': 50,           # Batch for 50ms for throughput
            'batch.num.messages': 10000,
            'compression.type': 'lz4',  # Fast compression
            'acks': '1',               # Leader ack for balance of durability/speed
            'queue.buffering.max.messages': 1000000,
        })
        self._poll_task = None

    def _delivery_callback(self, err, msg):
        if err:
            print(f"❌ Kafka delivery failed: {err}")

    def produce(self, event: EnrichedEvent):
        """Produce a single event to Kafka."""
        key = event.event_type  # Partition by event type
        value = event.json()
        self.producer.produce(
            topic=self.topic,
            key=key.encode('utf-8'),
            value=value.encode('utf-8'),
            callback=self._delivery_callback,
        )
        self.producer.poll(0)  # Non-blocking poll for callbacks

    def flush(self):
        self.producer.flush(timeout=10)


# ──────────────────────────────────────────────
# Rate Limiter (Token Bucket)
# ──────────────────────────────────────────────

class TokenBucketRateLimiter:
    """Per-client token bucket rate limiter."""

    def __init__(self, rate: int = 1000, capacity: int = 5000):
        self.rate = rate        # tokens per second
        self.capacity = capacity
        self.buckets: Dict[str, Dict] = {}

    def allow(self, client_id: str) -> bool:
        now = time.time()
        if client_id not in self.buckets:
            self.buckets[client_id] = {
                'tokens': self.capacity,
                'last_refill': now,
            }
        bucket = self.buckets[client_id]
        elapsed = now - bucket['last_refill']
        bucket['tokens'] = min(
            self.capacity,
            bucket['tokens'] + elapsed * self.rate
        )
        bucket['last_refill'] = now
        if bucket['tokens'] >= 1:
            bucket['tokens'] -= 1
            return True
        return False


# ──────────────────────────────────────────────
# Metrics Collector (in-memory, for the service itself)
# ──────────────────────────────────────────────

class IngestMetrics:
    """Tracks ingestion metrics for monitoring."""

    def __init__(self):
        self.events_received = 0
        self.events_enriched = 0
        self.events_produced = 0
        self.events_dropped = 0
        self.errors = 0
        self.latency_sum = 0.0  # Total enrichment latency
        self.start_time = time.time()

    def record_event(self, latency: float):
        self.events_received += 1
        self.events_enriched += 1
        self.events_produced += 1
        self.latency_sum += latency

    def snapshot(self) -> Dict:
        elapsed = max(time.time() - self.start_time, 1)
        return {
            "events_received": self.events_received,
            "events_per_second": round(self.events_received / elapsed, 2),
            "avg_latency_ms": round(
                (self.latency_sum / max(self.events_received, 1)) * 1000, 2
            ),
            "errors": self.errors,
            "uptime_seconds": round(elapsed, 0),
        }


# ──────────────────────────────────────────────
# FastAPI Application
# ──────────────────────────────────────────────

app = FastAPI(title="Real-Time Analytics - Event Collector")

geo_enricher = GeoIPEnricher()
ua_parser = UAParser()
kafka_producer = KafkaEventProducer()
rate_limiter = TokenBucketRateLimiter(rate=10000, capacity=50000)
metrics = IngestMetrics()


def generate_event_id(event: EventPayload, ip: str) -> str:
    """Generate deterministic event ID for deduplication."""
    raw = f"{event.timestamp}:{event.user_id}:{event.event_type}:{ip}"
    return hashlib.md5(raw.encode()).hexdigest()


def enrich_event(event: EventPayload, request: Request) -> EnrichedEvent:
    """Enrich raw event with geo, device, and temporal data."""
    ip = request.client.host
    ua = request.headers.get("user-agent", "")

    geo_info = geo_enricher.enrich(ip)
    ua_info = ua_parser.parse(ua)

    dt = datetime.fromtimestamp(event.timestamp, tz=timezone.utc)

    return EnrichedEvent(
        event_id=generate_event_id(event, ip),
        event_type=event.event_type.value,
        timestamp=event.timestamp,
        received_at=time.time(),
        user_id=event.user_id,
        session_id=event.session_id,
        page_url=event.page_url,
        referrer=event.referrer,
        properties=event.properties,
        country=geo_info["country"],
        city=geo_info["city"],
        device_type=ua_info["device_type"],
        browser=ua_info["browser"],
        os=ua_info["os"],
        date_partition=dt.strftime("%Y-%m-%d"),
        hour_bucket=dt.hour,
    )


@app.post("/v1/event")
async def ingest_single_event(event: EventPayload, request: Request):
    """Ingest a single analytics event."""
    client_id = request.headers.get("x-api-key", request.client.host)

    if not rate_limiter.allow(client_id):
        raise HTTPException(status_code=429, detail="Rate limit exceeded")

    start = time.time()
    enriched = enrich_event(event, request)
    kafka_producer.produce(enriched)
    metrics.record_event(time.time() - start)

    return {"status": "ok", "event_id": enriched.event_id}


@app.post("/v1/events/batch")
async def ingest_batch(batch: EventBatch, request: Request):
    """Ingest a batch of analytics events."""
    client_id = request.headers.get("x-api-key", request.client.host)

    if not rate_limiter.allow(client_id):
        raise HTTPException(status_code=429, detail="Rate limit exceeded")

    event_ids = []
    start = time.time()
    for event in batch.events:
        enriched = enrich_event(event, request)
        kafka_producer.produce(enriched)
        event_ids.append(enriched.event_id)

    metrics.record_event(time.time() - start)

    return {
        "status": "ok",
        "count": len(event_ids),
        "event_ids": event_ids[:5],  # Return first 5 for brevity
    }


@app.get("/v1/health")
async def health_check():
    return {"status": "healthy", "metrics": metrics.snapshot()}


@app.on_event("shutdown")
def shutdown():
    kafka_producer.flush()
```

#### Stream Processing (Flink-style in Python)

```python
"""
Real-Time Stream Processor
Simulates Apache Flink-style windowed aggregations in Python.
In production, use actual Flink/Spark Structured Streaming.
"""

import time
import json
import threading
from collections import defaultdict
from dataclasses import dataclass, field
from typing import Dict, List, Optional, Callable, Any
from datetime import datetime, timezone
import heapq
import math
import redis


# ──────────────────────────────────────────────
# HyperLogLog for Cardinality Estimation
# ──────────────────────────────────────────────

class HyperLogLog:
    """
    Memory-efficient unique count estimator.
    Uses only ~1.5KB for millions of unique items with ~2% error.
    """

    def __init__(self, precision: int = 10):
        self.p = precision
        self.m = 1 << precision  # Number of registers
        self.registers = [0] * self.m
        self.alpha = self._compute_alpha()

    def _compute_alpha(self) -> float:
        if self.m == 16:
            return 0.673
        elif self.m == 32:
            return 0.697
        elif self.m == 64:
            return 0.709
        else:
            return 0.7213 / (1 + 1.079 / self.m)

    def _hash(self, value: str) -> int:
        """Simple hash function (use MurmurHash3 in production)."""
        import hashlib
        h = int(hashlib.sha256(value.encode()).hexdigest(), 16)
        return h & ((1 << 64) - 1)  # 64-bit hash

    def add(self, value: str):
        h = self._hash(value)
        # First p bits → register index
        j = h & (self.m - 1)
        # Remaining bits → count leading zeros
        w = h >> self.p
        # Position of leftmost 1-bit (add 1 because we count from 1)
        rho = (64 - self.p) - int(math.log2(w)) if w > 0 else (64 - self.p)
        self.registers[j] = max(self.registers[j], rho)

    def count(self) -> int:
        """Estimate cardinality."""
        indicator = sum(2 ** (-r) for r in self.registers)
        estimate = self.alpha * self.m * self.m / indicator

        # Small range correction
        if estimate <= 2.5 * self.m:
            zeros = self.registers.count(0)
            if zeros > 0:
                estimate = self.m * math.log(self.m / zeros)

        return int(estimate)

    def merge(self, other: 'HyperLogLog'):
        """Merge two HLLs (for combining windows/partitions)."""
        assert self.m == other.m
        self.registers = [
            max(a, b) for a, b in zip(self.registers, other.registers)
        ]


# ──────────────────────────────────────────────
# Window Types
# ──────────────────────────────────────────────

@dataclass
class WindowState:
    """State for a single window bucket."""
    window_start: float
    window_end: float
    count: int = 0
    sum_value: float = 0.0
    min_value: float = float('inf')
    max_value: float = float('-inf')
    hll: HyperLogLog = field(default_factory=HyperLogLog)
    # For percentile computation (t-digest would be used in production)
    samples: List[float] = field(default_factory=list)
    dimension_counts: Dict[str, Dict[str, int]] = field(
        default_factory=lambda: defaultdict(lambda: defaultdict(int))
    )

    def add_event(self, event: dict):
        self.count += 1
        value = event.get('value', 1.0)
        self.sum_value += value
        self.min_value = min(self.min_value, value)
        self.max_value = max(self.max_value, value)

        # Track unique users
        if event.get('user_id'):
            self.hll.add(event['user_id'])

        # Reservoir sampling for percentiles (keep max 1000 samples)
        if len(self.samples) < 1000:
            self.samples.append(value)
        else:
            import random
            idx = random.randint(0, self.count - 1)
            if idx < 1000:
                self.samples[idx] = value

        # Dimensional breakdowns
        for dim in ['country', 'device_type', 'browser', 'event_type']:
            if dim in event:
                self.dimension_counts[dim][event[dim]] += 1

    def compute_percentiles(self) -> Dict[str, float]:
        if not self.samples:
            return {}
        sorted_samples = sorted(self.samples)
        n = len(sorted_samples)
        return {
            'p50': sorted_samples[int(n * 0.5)],
            'p90': sorted_samples[int(n * 0.9)],
            'p95': sorted_samples[int(n * 0.95)],
            'p99': sorted_samples[min(int(n * 0.99), n - 1)],
        }

    def to_dict(self) -> dict:
        return {
            'window_start': self.window_start,
            'window_end': self.window_end,
            'count': self.count,
            'sum': self.sum_value,
            'avg': self.sum_value / self.count if self.count > 0 else 0,
            'min': self.min_value if self.count > 0 else 0,
            'max': self.max_value if self.count > 0 else 0,
            'unique_users': self.hll.count(),
            'percentiles': self.compute_percentiles(),
            'dimensions': {
                dim: dict(counts) 
                for dim, counts in self.dimension_counts.items()
            },
        }


class TumblingWindowProcessor:
    """
    Tumbling (fixed, non-overlapping) window processor.
    
    Example: 1-minute windows
    |──── W1 ────|──── W2 ────|──── W3 ────|
    00:00  01:00  01:00  02:00  02:00  03:00
    """

    def __init__(self, window_size_sec: int, 
                 on_window_close: Callable[[Dict], None]):
        self.window_size = window_size_sec
        self.on_window_close = on_window_close
        self.windows: Dict[int, WindowState] = {}  # bucket_id → state
        self.watermark = 0.0
        self.allowed_lateness_sec = 5  # Late event tolerance

    def _get_bucket_id(self, timestamp: float) -> int:
        return int(timestamp // self.window_size)

    def process_event(self, event: dict):
        ts = event.get('timestamp', time.time())
        bucket_id = self._get_bucket_id(ts)
        window_start = bucket_id * self.window_size
        window_end = window_start + self.window_size

        # Check if event is too late
        if window_end < self.watermark - self.allowed_lateness_sec:
            # Drop late event (or send to late-data side output)
            return

        if bucket_id not in self.windows:
            self.windows[bucket_id] = WindowState(
                window_start=window_start,
                window_end=window_end
            )

        self.windows[bucket_id].add_event(event)
        self._advance_watermark(ts)

    def _advance_watermark(self, event_time: float):
        """Advance watermark and trigger window closures."""
        new_watermark = event_time - self.allowed_lateness_sec
        if new_watermark <= self.watermark:
            return

        self.watermark = new_watermark

        # Close all windows that end before the watermark
        closed_buckets = []
        for bucket_id, window in self.windows.items():
            if window.window_end <= self.watermark:
                self.on_window_close(window.to_dict())
                closed_buckets.append(bucket_id)

        for bid in closed_buckets:
            del self.windows[bid]

    def flush_all(self):
        """Force-close all open windows (on shutdown)."""
        for window in self.windows.values():
            self.on_window_close(window.to_dict())
        self.windows.clear()


class SlidingWindowProcessor:
    """
    Sliding window that advances by a slide interval.
    Maintains multiple overlapping windows.

    Example: 5-min window, 1-min slide
    |──────────── W1 (00:00 - 05:00) ────────────|
       |──────────── W2 (01:00 - 06:00) ────────────|
          |──────────── W3 (02:00 - 07:00) ────────────|
    """

    def __init__(self, window_size_sec: int, slide_sec: int,
                 on_window_close: Callable[[Dict], None]):
        self.window_size = window_size_sec
        self.slide = slide_sec
        self.on_window_close = on_window_close
        self.windows: Dict[int, WindowState] = {}
        self.watermark = 0.0

    def _get_affected_buckets(self, timestamp: float) -> List[int]:
        """An event belongs to multiple sliding windows."""
        latest_start = int(timestamp // self.slide) * self.slide
        buckets = []
        start = latest_start
        while start + self.window_size > timestamp and \
              start >= latest_start - self.window_size + self.slide:
            buckets.append(int(start // self.slide))
            start -= self.slide
        return buckets

    def process_event(self, event: dict):
        ts = event.get('timestamp', time.time())
        for bucket_id in self._get_affected_buckets(ts):
            window_start = bucket_id * self.slide
            window_end = window_start + self.window_size
            if bucket_id not in self.windows:
                self.windows[bucket_id] = WindowState(
                    window_start=window_start,
                    window_end=window_end,
                )
            self.windows[bucket_id].add_event(event)

        self._advance_watermark(ts)

    def _advance_watermark(self, event_time: float):
        new_watermark = event_time - 5  # 5s lateness
        if new_watermark <= self.watermark:
            return
        self.watermark = new_watermark

        closed = []
        for bucket_id, window in self.windows.items():
            if window.window_end <= self.watermark:
                self.on_window_close(window.to_dict())
                closed.append(bucket_id)
        for bid in closed:
            del self.windows[bid]


# ──────────────────────────────────────────────
# Aggregation Sink (writes to Redis + OLAP store)
# ──────────────────────────────────────────────

class AggregationSink:
    """Writes window results to Redis and OLAP store."""

    def __init__(self, redis_host: str = "localhost", redis_port: int = 6379):
        try:
            self.redis = redis.Redis(
                host=redis_host, port=redis_port, decode_responses=True
            )
            self.redis.ping()
            print("✅ Connected to Redis")
        except Exception:
            self.redis = None
            print("⚠️  Redis not available; printing results to console")

    def write_window_result(self, result: dict):
        """Write aggregated window result to serving layer."""
        window_key = (
            f"analytics:window:"
            f"{int(result['window_start'])}:"
            f"{int(result['window_end'])}"
        )

        if self.redis:
            # Store the full aggregate
            self.redis.setex(
                window_key,
                86400,  # 24-hour TTL
                json.dumps(result, default=str)
            )

            # Update real-time counters
            self.redis.incrby("analytics:total_events", result['count'])
            self.redis.set(
                "analytics:latest_unique_users",
                result['unique_users']
            )

            # Per-dimension counters
            for dim_name, dim_counts in result.get('dimensions', {}).items():
                for dim_value, count in dim_counts.items():
                    self.redis.hincrby(
                        f"analytics:dim:{dim_name}",
                        dim_value,
                        count
                    )

        # Always log (for debugging / console output)
        ts_start = datetime.fromtimestamp(
            result['window_start'], tz=timezone.utc
        ).strftime("%H:%M:%S")
        ts_end = datetime.fromtimestamp(
            result['window_end'], tz=timezone.utc
        ).strftime("%H:%M:%S")

        print(
            f"📊 Window [{ts_start} → {ts_end}] "
            f"events={result['count']:,} "
            f"unique_users={result['unique_users']:,} "
            f"avg={result['avg']:.2f} "
            f"p95={result['percentiles'].get('p95', 'N/A')}"
        )


# ──────────────────────────────────────────────
# Stream Processing Pipeline
# ──────────────────────────────────────────────

class AnalyticsPipeline:
    """
    Main stream processing pipeline.
    In production, this would be a Flink/Spark Streaming job.
    """

    def __init__(self):
        self.sink = AggregationSink()

        # 1-minute tumbling windows for real-time counters
        self.minute_processor = TumblingWindowProcessor(
            window_size_sec=60,
            on_window_close=self._on_minute_window_close,
        )

        # 5-minute sliding windows for trend analysis
        self.trend_processor = SlidingWindowProcessor(
            window_size_sec=300,
            slide_sec=60,
            on_window_close=self._on_trend_window_close,
        )

        self.processed_count = 0

    def _on_minute_window_close(self, result: dict):
        result['window_type'] = 'tumbling_1min'
        self.sink.write_window_result(result)

    def _on_trend_window_close(self, result: dict):
        result['window_type'] = 'sliding_5min'
        self.sink.write_window_result(result)

    def process(self, event: dict):
        """Process a single event through all window operators."""
        self.minute_processor.process_event(event)
        self.trend_processor.process_event(event)
        self.processed_count += 1

    def shutdown(self):
        self.minute_processor.flush_all()
        self.trend_processor.flush_all()


# ──────────────────────────────────────────────
# Simulation / Demo
# ──────────────────────────────────────────────

def simulate_analytics_stream():
    """Simulates incoming analytics events and processes them."""
    import random

    pipeline = AnalyticsPipeline()

    countries = ["US", "UK", "DE", "JP", "BR", "IN", "FR", "CA"]
    devices = ["mobile", "desktop", "tablet"]
    browsers = ["chrome", "safari", "firefox", "edge"]
    event_types = ["page_view", "click", "purchase", "signup"]
    pages = ["/home", "/products", "/cart", "/checkout", "/about"]

    print("🚀 Starting real-time analytics simulation...")
    print("=" * 60)

    base_time = time.time()
    events_per_second = 500

    try:
        for second in range(180):  # Simulate 3 minutes
            for _ in range(events_per_second):
                event = {
                    'timestamp': base_time + second + random.random(),
                    'event_type': random.choice(event_types),
                    'user_id': f"user_{random.randint(1, 10000)}",
                    'session_id': f"sess_{random.randint(1, 5000)}",
                    'page_url': random.choice(pages),
                    'country': random.choice(countries),
                    'device_type': random.choice(devices),
                    'browser': random.choice(browsers),
                    'value': random.expovariate(1 / 50),  # Avg value ~50
                }
                pipeline.process(event)

            if (second + 1) % 10 == 0:
                print(
                    f"  ⏱  {second + 1}s elapsed | "
                    f"Total events: {pipeline.processed_count:,}"
                )

    except KeyboardInterrupt:
        pass
    finally:
        pipeline.shutdown()
        print(f"\n✅ Processed {pipeline.processed_count:,} total events")


if __name__ == "__main__":
    simulate_analytics_stream()
```

#### Query / Dashboard API

```python
"""
Analytics Query API
Serves pre-aggregated data for dashboards with sub-second latency.
"""

import json
import time
from typing import Optional, List
from datetime import datetime, timedelta

from fastapi import FastAPI, Query
from pydantic import BaseModel
import redis


app = FastAPI(title="Analytics Query API")


class TimeseriesPoint(BaseModel):
    timestamp: float
    value: float


class AnalyticsResponse(BaseModel):
    query: str
    time_range: str
    data: dict
    query_time_ms: float


class RedisQueryEngine:
    """Queries pre-aggregated data from Redis."""

    def __init__(self):
        try:
            self.redis = redis.Redis(
                host="localhost", port=6379, decode_responses=True
            )
            self.redis.ping()
        except Exception:
            self.redis = None

    def get_realtime_summary(self) -> dict:
        """Get real-time summary metrics."""
        if not self.redis:
            return self._mock_summary()

        return {
            "total_events": int(
                self.redis.get("analytics:total_events") or 0
            ),
            "unique_users": int(
                self.redis.get("analytics:latest_unique_users") or 0
            ),
            "by_country": self.redis.hgetall("analytics:dim:country"),
            "by_device": self.redis.hgetall("analytics:dim:device_type"),
            "by_browser": self.redis.hgetall("analytics:dim:browser"),
            "by_event_type": self.redis.hgetall("analytics:dim:event_type"),
        }

    def get_timeseries(self, metric: str, minutes: int) -> List[dict]:
        """Get time-series data for the last N minutes."""
        now = time.time()
        results = []

        for i in range(minutes):
            window_end = int((now - i * 60) // 60) * 60 + 60
            window_start = window_end - 60
            key = f"analytics:window:{window_start}:{window_end}"

            if self.redis:
                data = self.redis.get(key)
                if data:
                    parsed = json.loads(data)
                    results.append({
                        'timestamp': window_start,
                        'count': parsed.get('count', 0),
                        'unique_users': parsed.get('unique_users', 0),
                        'avg_value': parsed.get('avg', 0),
                    })

        return sorted(results, key=lambda x: x['timestamp'])

    def _mock_summary(self) -> dict:
        """Mock data when Redis is not available."""
        return {
            "total_events": 1_250_000,
            "unique_users": 45_200,
            "by_country": {
                "US": "450000", "UK": "180000", "DE": "120000",
                "JP": "95000", "BR": "85000", "IN": "320000",
            },
            "by_device": {
                "mobile": "625000", "desktop": "500000", "tablet": "125000",
            },
            "by_browser": {
                "chrome": "750000", "safari": "312500",
                "firefox": "125000", "edge": "62500",
            },
            "by_event_type": {
                "page_view": "875000", "click": "250000",
                "purchase": "62500", "signup": "62500",
            },
        }


query_engine = RedisQueryEngine()


@app.get("/api/v1/analytics/realtime")
async def realtime_dashboard():
    """Real-time dashboard summary."""
    start = time.time()
    data = query_engine.get_realtime_summary()
    return AnalyticsResponse(
        query="realtime_summary",
        time_range="live",
        data=data,
        query_time_ms=round((time.time() - start) * 1000, 2),
    )


@app.get("/api/v1/analytics/timeseries")
async def timeseries(
    metric: str = Query("count", enum=["count", "unique_users", "avg_value"]),
    minutes: int = Query(60, ge=1, le=1440),
):
    """Time-series data for charts."""
    start = time.time()
    data = query_engine.get_timeseries(metric, minutes)
    return AnalyticsResponse(
        query=f"timeseries:{metric}",
        time_range=f"last_{minutes}_minutes",
        data={"series": data, "metric": metric},
        query_time_ms=round((time.time() - start) * 1000, 2),
    )


@app.get("/api/v1/analytics/topN")
async def top_n(
    dimension: str = Query(..., enum=[
        "country", "device_type", "browser", "event_type", "page_url"
    ]),
    n: int = Query(10, ge=1, le=100),
):
    """Top N values for a dimension."""
    start = time.time()
    summary = query_engine.get_realtime_summary()

    dim_key = f"by_{dimension}"
    dim_data = summary.get(dim_key, {})

    sorted_items = sorted(
        dim_data.items(), key=lambda x: int(x[1]), reverse=True
    )[:n]

    return AnalyticsResponse(
        query=f"topN:{dimension}",
        time_range="cumulative",
        data={
            "dimension": dimension,
            "items": [
                {"value": k, "count": int(v)} for k, v in sorted_items
            ],
        },
        query_time_ms=round((time.time() - start) * 1000, 2),
    )
```

---

### Data Storage Strategy

```
┌────────────────────────────────────────────────────────────────┐
│                    STORAGE LAYER DESIGN                        │
│                                                                │
│  HOT DATA (0-24 hours):                                       │
│  ┌──────────┐                                                 │
│  │  Redis    │  Pre-computed 1-minute rollups                 │
│  │  Cluster  │  Real-time counters (INCRBY)                   │
│  │           │  HyperLogLog for unique users (PFADD/PFCOUNT)  │
│  │           │  Sorted sets for Top-N (ZINCRBY)               │
│  │  TTL: 24h │  Pub/Sub for live dashboard push              │
│  └──────────┘                                                 │
│                                                                │
│  WARM DATA (1-90 days):                                       │
│  ┌──────────────┐                                             │
│  │  Apache Druid │  Pre-aggregated OLAP segments             │
│  │  / ClickHouse │  Columnar storage                         │
│  │               │  Sub-second queries on dimensions          │
│  │               │  Automatic rollup & compaction             │
│  └──────────────┘                                             │
│                                                                │
│  COLD DATA (90+ days):                                        │
│  ┌──────────┐                                                 │
│  │ S3/HDFS  │  Parquet files, partitioned by date            │
│  │          │  Queryable via Presto/Trino/Athena             │
│  │          │  Cost: ~$0.023/GB/month                        │
│  └──────────┘                                                 │
└────────────────────────────────────────────────────────────────┘
```

---
---

## 24. Log Aggregation System

### Problem Statement

Design a system like the **ELK Stack (Elasticsearch-Logstash-Kibana)** or **Splunk** that collects, processes, indexes, and enables searching across logs from thousands of servers.

---

### Requirements

```
Functional:
1. Collect logs from 10,000+ servers
2. Structured and unstructured log parsing
3. Full-text search with sub-second latency
4. Time-range filtering, field-based filtering
5. Log pattern alerting (error spikes)
6. Dashboard & visualization
7. Log retention policies (hot/warm/cold)

Non-Functional:
- Ingestion: 500 GB/day (50 TB/day for large orgs)
- Search latency: < 1 second for recent logs
- Availability: 99.9% (logs are critical for debugging)
- Retention: 7 days hot, 30 days warm, 1 year cold
```

---

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        LOG AGGREGATION SYSTEM                               │
│                                                                             │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐        │
│  │ Server 1 │ │ Server 2 │ │ Server 3 │ │ Server N │ │ Container│        │
│  │          │ │          │ │          │ │          │ │ (K8s)    │        │
│  │ ┌──────┐ │ │ ┌──────┐ │ │ ┌──────┐ │ │ ┌──────┐ │ │ ┌──────┐ │        │
│  │ │Agent │ │ │ │Agent │ │ │ │Agent │ │ │ │Agent │ │ │ │Agent │ │        │
│  │ │(Fluentd│ │ │(Fluentd│ │ │(Fluentd│ │ │(Fluentd│ │ │(Fluentd│        │
│  │ │/Filebeat│ │ │/Filebeat│ │ │/Filebeat│ │ │/Filebeat│ │ │/Filebeat│      │
│  │ └───┬──┘ │ │ └───┬──┘ │ │ └───┬──┘ │ │ └───┬──┘ │ │ └───┬──┘ │        │
│  └─────┼────┘ └─────┼────┘ └─────┼────┘ └─────┼────┘ └─────┼────┘        │
│        │            │            │            │            │               │
│        └────────────┴─────┬──────┴────────────┴────────────┘               │
│                           │                                                │
│                           ▼                                                │
│  ┌──────────────────────────────────────────────────────────────────┐      │
│  │                   Kafka Cluster (Buffer)                         │      │
│  │                                                                  │      │
│  │  Topic: raw-logs (partitioned by service_name)                  │      │
│  │  Retention: 72 hours (replay buffer)                            │      │
│  │  Replication factor: 3                                          │      │
│  │                                                                  │      │
│  │  ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐       │      │
│  │  │ Part 0 │ │ Part 1 │ │ Part 2 │ │ Part 3 │ │ Part N │       │      │
│  │  │api-svc │ │auth-svc│ │pay-svc │ │web-svc │ │  ...   │       │      │
│  │  └────────┘ └────────┘ └────────┘ └────────┘ └────────┘       │      │
│  └──────────────────────────┬───────────────────────────────────────┘      │
│                             │                                              │
│                    ┌────────┴────────┐                                     │
│                    │                 │                                     │
│                    ▼                 ▼                                     │
│  ┌─────────────────────┐  ┌──────────────────────┐                       │
│  │  LOG PROCESSOR      │  │  ARCHIVAL PIPELINE   │                       │
│  │  (Stream Processing)│  │                      │                       │
│  │                     │  │  Kafka → S3/GCS      │                       │
│  │  • Parse & structure│  │  (Parquet format)    │                       │
│  │  • Grok patterns    │  │  Partitioned by:     │                       │
│  │  • Timestamp extract│  │    date/service/     │                       │
│  │  • Field extraction │  │    log_level         │                       │
│  │  • PII masking      │  │                      │                       │
│  │  • Sampling         │  │  Queryable via:      │                       │
│  │  • Alert evaluation │  │  Athena/Presto       │                       │
│  └──────────┬──────────┘  └──────────────────────┘                       │
│             │                                                             │
│             ▼                                                             │
│  ┌──────────────────────────────────────────────────────────────────┐     │
│  │                ELASTICSEARCH CLUSTER                              │     │
│  │                                                                  │     │
│  │  ┌──────────────────────────────────────────────────────────┐   │     │
│  │  │  Index Lifecycle Management (ILM)                        │   │     │
│  │  │                                                          │   │     │
│  │  │  HOT (0-24h)     WARM (1-7d)      COLD (7-30d)         │   │     │
│  │  │  ┌──────────┐   ┌──────────┐     ┌──────────┐          │   │     │
│  │  │  │ SSD nodes│   │ HDD nodes│     │ Frozen   │          │   │     │
│  │  │  │ 1 replica│   │ 1 replica│     │ tier/S3  │          │   │     │
│  │  │  │ 1 shard  │   │ Force    │     │ Searchable│         │   │     │
│  │  │  │ per 50GB │   │ merge    │     │ snapshot │          │   │     │
│  │  │  └──────────┘   └──────────┘     └──────────┘          │   │     │
│  │  └──────────────────────────────────────────────────────────┘   │     │
│  │                                                                  │     │
│  │  Master Nodes (3)  │  Data Nodes (N)  │  Coordinator Nodes (M) │     │
│  └──────────────────────────────────────────────────────────────────┘     │
│             │                                                             │
│             ▼                                                             │
│  ┌──────────────────────────────────────────────────────────────────┐     │
│  │                    QUERY & VISUALIZATION                          │     │
│  │                                                                  │     │
│  │  ┌────────────┐  ┌────────────┐  ┌────────────┐                │     │
│  │  │  Search    │  │  Kibana /  │  │  Alert     │                │     │
│  │  │  API       │  │  Grafana   │  │  Manager   │                │     │
│  │  └────────────┘  └────────────┘  └────────────┘                │     │
│  └──────────────────────────────────────────────────────────────────┘     │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

### Deep Dive: Log Agent Architecture

```
┌────────────────────────────────────────────────────────────┐
│                    LOG AGENT (per server)                    │
│                                                            │
│  ┌────────────────────────────────────┐                    │
│  │  FILE TAILER                       │                    │
│  │                                    │                    │
│  │  /var/log/app/service.log ─────────┼──┐                │
│  │  /var/log/nginx/access.log ────────┼──┤                │
│  │  /var/log/syslog ─────────────────┼──┤                │
│  │  stdout (container) ──────────────┼──┤                │
│  │                                    │  │                │
│  │  Features:                         │  │                │
│  │  • inotify for file changes       │  │                │
│  │  • File rotation handling          │  │                │
│  │  • Offset tracking (registry)     │  │                │
│  │  • Multi-line log joining         │  │                │
│  └────────────────────────────────────┘  │                │
│                                          ▼                │
│  ┌────────────────────────────────────┐                    │
│  │  IN-MEMORY BUFFER                  │                    │
│  │                                    │                    │
│  │  Ring buffer: 128 MB              │                    │
│  │  Backpressure: block when full    │                    │
│  │  Disk spillover for durability    │                    │
│  └──────────────┬─────────────────────┘                    │
│                 │                                          │
│                 ▼                                          │
│  ┌────────────────────────────────────┐                    │
│  │  BATCH SENDER                      │                    │
│  │                                    │                    │
│  │  Batch size: 1000 logs or 5s      │                    │
│  │  Compression: gzip/lz4            │                    │
│  │  Retry with exponential backoff   │                    │
│  │  Target: Kafka / HTTP endpoint    │                    │
│  └────────────────────────────────────┘                    │
└────────────────────────────────────────────────────────────┘
```

---

### Deep Dive: Index Design

```
┌────────────────────────────────────────────────────────────────┐
│              ELASTICSEARCH INDEX STRATEGY                       │
│                                                                │
│  Index pattern: logs-{service}-{YYYY.MM.dd}                   │
│  Example: logs-api-gateway-2024.01.15                         │
│                                                                │
│  MAPPING:                                                      │
│  ┌──────────────────────────────────────────────────┐         │
│  │  @timestamp    : date       (sort key)           │         │
│  │  level         : keyword    (ERROR, WARN, INFO)  │         │
│  │  service       : keyword    (indexed, not analyzed)│        │
│  │  host          : keyword                          │         │
│  │  trace_id      : keyword    (for distributed tracing)│     │
│  │  message       : text       (full-text indexed)   │         │
│  │  message.raw   : keyword    (exact match)         │         │
│  │  source_file   : keyword                          │         │
│  │  line_number   : integer                          │         │
│  │  request_id    : keyword                          │         │
│  │  user_id       : keyword                          │         │
│  │  duration_ms   : float                            │         │
│  │  status_code   : integer                          │         │
│  │  error_type    : keyword                          │         │
│  │  stack_trace   : text       (full-text indexed)   │         │
│  │  tags          : keyword[]  (multi-value)         │         │
│  └──────────────────────────────────────────────────┘         │
│                                                                │
│  SHARD STRATEGY:                                              │
│  - Target shard size: 30-50 GB                                │
│  - 1 shard per 50GB of expected daily data per service        │
│  - Example: api-gateway produces 200 GB/day → 4 shards       │
│                                                                │
│  ILM POLICY:                                                  │
│  - Hot → Warm: after 24 hours (force merge to 1 segment)     │
│  - Warm → Cold: after 7 days (freeze index)                  │
│  - Cold → Delete: after 30 days                              │
└────────────────────────────────────────────────────────────────┘
```

---

### Python Implementation

#### Log Agent (Filebeat-like)

```python
"""
Log Collection Agent
Lightweight agent that tails log files, parses them,
and ships to a central collector (Kafka or HTTP).
"""

import os
import time
import json
import gzip
import re
import hashlib
import threading
import queue
from dataclasses import dataclass, field, asdict
from typing import Dict, List, Optional, Callable
from pathlib import Path
from collections import deque
from datetime import datetime


# ──────────────────────────────────────────────
# Log Line Models
# ──────────────────────────────────────────────

@dataclass
class LogEntry:
    """Structured log entry."""
    timestamp: str
    level: str
    service: str
    host: str
    message: str
    source_file: str
    line_number: int
    # Optional fields extracted from parsing
    request_id: Optional[str] = None
    trace_id: Optional[str] = None
    duration_ms: Optional[float] = None
    status_code: Optional[int] = None
    error_type: Optional[str] = None
    stack_trace: Optional[str] = None
    tags: List[str] = field(default_factory=list)

    def to_json(self) -> str:
        d = asdict(self)
        d = {k: v for k, v in d.items() if v is not None}
        return json.dumps(d)


# ──────────────────────────────────────────────
# Log Parsers (Grok-like patterns)
# ──────────────────────────────────────────────

class LogParser:
    """
    Parses various log formats into structured LogEntry objects.
    Supports Grok-like pattern matching.
    """

    # Common patterns
    PATTERNS = {
        # 2024-01-15 10:23:45.123 ERROR [api-gateway] Request failed - 500
        'standard': re.compile(
            r'(?P<timestamp>\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2}:\d{2}[\.,]\d{3})\s+'
            r'(?P<level>DEBUG|INFO|WARN|ERROR|FATAL)\s+'
            r'\[(?P<service>[^\]]+)\]\s+'
            r'(?P<message>.*)'
        ),
        # NGINX access log
        'nginx': re.compile(
            r'(?P<ip>\S+)\s+-\s+-\s+'
            r'\[(?P<timestamp>[^\]]+)\]\s+'
            r'"(?P<method>\S+)\s+(?P<url>\S+)\s+\S+"\s+'
            r'(?P<status>\d+)\s+'
            r'(?P<bytes>\d+)\s+'
            r'"(?P<referrer>[^"]*?)"\s+'
            r'"(?P<user_agent>[^"]*?)"'
        ),
        # JSON log format (structured logging)
        'json': re.compile(r'^\s*\{.*\}\s*$'),
        # Syslog
        'syslog': re.compile(
            r'(?P<timestamp>\w{3}\s+\d+\s+\d{2}:\d{2}:\d{2})\s+'
            r'(?P<host>\S+)\s+'
            r'(?P<service>\S+?)(\[\d+\])?:\s+'
            r'(?P<message>.*)'
        ),
    }

    # Extract request ID, trace ID patterns
    REQUEST_ID_PATTERN = re.compile(r'req[_-]?id[=:\s]+([a-zA-Z0-9\-]+)')
    TRACE_ID_PATTERN = re.compile(r'trace[_-]?id[=:\s]+([a-zA-Z0-9\-]+)')
    DURATION_PATTERN = re.compile(r'(?:duration|took|elapsed)[=:\s]+(\d+(?:\.\d+)?)\s*(?:ms)?')

    def __init__(self, default_service: str = "unknown"):
        self.default_service = default_service

    def parse(self, raw_line: str, source_file: str, 
              line_number: int, host: str) -> Optional[LogEntry]:
        """Parse a raw log line into a structured LogEntry."""
        raw_line = raw_line.strip()
        if not raw_line:
            return None

        # Try JSON format first
        if self.PATTERNS['json'].match(raw_line):
            return self._parse_json(raw_line, source_file, line_number, host)

        # Try standard application log
        match = self.PATTERNS['standard'].match(raw_line)
        if match:
            return self._parse_standard(
                match, raw_line, source_file, line_number, host
            )

        # Try NGINX format
        match = self.PATTERNS['nginx'].match(raw_line)
        if match:
            return self._parse_nginx(
                match, raw_line, source_file, line_number, host
            )

        # Try syslog
        match = self.PATTERNS['syslog'].match(raw_line)
        if match:
            return self._parse_syslog(
                match, raw_line, source_file, line_number, host
            )

        # Fallback: treat entire line as message
        return LogEntry(
            timestamp=datetime.utcnow().isoformat(),
            level="INFO",
            service=self.default_service,
            host=host,
            message=raw_line,
            source_file=source_file,
            line_number=line_number,
        )

    def _parse_json(self, line: str, source_file: str,
                    line_number: int, host: str) -> LogEntry:
        """Parse JSON-formatted log line."""
        try:
            data = json.loads(line)
            return LogEntry(
                timestamp=data.get('timestamp', data.get('@timestamp',
                    datetime.utcnow().isoformat())),
                level=data.get('level', data.get('severity', 'INFO')).upper(),
                service=data.get('service', data.get('logger',
                    self.default_service)),
                host=data.get('host', host),
                message=data.get('message', data.get('msg', '')),
                source_file=source_file,
                line_number=line_number,
                request_id=data.get('request_id'),
                trace_id=data.get('trace_id'),
                duration_ms=data.get('duration_ms'),
                status_code=data.get('status_code'),
                error_type=data.get('error_type'),
                stack_trace=data.get('stack_trace'),
                tags=data.get('tags', []),
            )
        except json.JSONDecodeError:
            return LogEntry(
                timestamp=datetime.utcnow().isoformat(),
                level="INFO",
                service=self.default_service,
                host=host,
                message=line,
                source_file=source_file,
                line_number=line_number,
            )

    def _parse_standard(self, match, raw_line: str, source_file: str,
                        line_number: int, host: str) -> LogEntry:
        """Parse standard application log format."""
        message = match.group('message')

        # Extract embedded fields
        req_id_match = self.REQUEST_ID_PATTERN.search(message)
        trace_match = self.TRACE_ID_PATTERN.search(message)
        duration_match = self.DURATION_PATTERN.search(message)

        return LogEntry(
            timestamp=match.group('timestamp'),
            level=match.group('level'),
            service=match.group('service'),
            host=host,
            message=message,
            source_file=source_file,
            line_number=line_number,
            request_id=req_id_match.group(1) if req_id_match else None,
            trace_id=trace_match.group(1) if trace_match else None,
            duration_ms=float(duration_match.group(1)) if duration_match else None,
        )

    def _parse_nginx(self, match, raw_line: str, source_file: str,
                     line_number: int, host: str) -> LogEntry:
        """Parse NGINX access log format."""
        status = int(match.group('status'))
        level = "ERROR" if status >= 500 else (
            "WARN" if status >= 400 else "INFO"
        )

        return LogEntry(
            timestamp=match.group('timestamp'),
            level=level,
            service="nginx",
            host=host,
            message=f"{match.group('method')} {match.group('url')}",
            source_file=source_file,
            line_number=line_number,
            status_code=status,
            tags=["access_log"],
        )

    def _parse_syslog(self, match, raw_line: str, source_file: str,
                      line_number: int, host: str) -> LogEntry:
        """Parse syslog format."""
        return LogEntry(
            timestamp=match.group('timestamp'),
            level="INFO",
            service=match.group('service'),
            host=match.group('host'),
            message=match.group('message'),
            source_file=source_file,
            line_number=line_number,
        )


# ──────────────────────────────────────────────
# Multi-line Log Joiner
# ──────────────────────────────────────────────

class MultiLineJoiner:
    """
    Joins multi-line log entries (e.g., Java stack traces).
    A new log entry starts when the pattern matches.
    Lines not matching are appended to the previous entry.
    """

    def __init__(self, start_pattern: str = 
                 r'^\d{4}-\d{2}-\d{2}|^\w{3}\s+\d+|^\{'):
        self.start_pattern = re.compile(start_pattern)
        self.buffer: List[str] = []

    def process_line(self, line: str) -> Optional[str]:
        """
        Feed a line. Returns a complete log entry when a new one starts.
        """
        if self.start_pattern.match(line):
            # This line starts a new entry
            if self.buffer:
                # Return the previous buffered entry
                complete = '\n'.join(self.buffer)
                self.buffer = [line]
                return complete
            else:
                self.buffer = [line]
                return None
        else:
            # Continuation line (e.g., stack trace)
            if self.buffer:
                self.buffer.append(line)
            return None

    def flush(self) -> Optional[str]:
        """Flush remaining buffered content."""
        if self.buffer:
            complete = '\n'.join(self.buffer)
            self.buffer = []
            return complete
        return None


# ──────────────────────────────────────────────
# File Tailer with Offset Tracking
# ──────────────────────────────────────────────

class FileTailer:
    """
    Tails a log file, tracking read offsets for crash recovery.
    Handles log rotation (new file with same name).
    """

    def __init__(self, filepath: str, registry_dir: str = "/tmp/log_agent"):
        self.filepath = filepath
        self.registry_dir = registry_dir
        self.offset = 0
        self.inode = None
        self._file = None
        self.multiline = MultiLineJoiner()

        os.makedirs(registry_dir, exist_ok=True)
        self._load_offset()

    @property
    def _registry_path(self) -> str:
        file_hash = hashlib.md5(self.filepath.encode()).hexdigest()
        return os.path.join(self.registry_dir, f"offset_{file_hash}.json")

    def _load_offset(self):
        """Load previously saved offset from registry."""
        try:
            with open(self._registry_path, 'r') as f:
                data = json.load(f)
                self.offset = data.get('offset', 0)
                self.inode = data.get('inode')
        except (FileNotFoundError, json.JSONDecodeError):
            self.offset = 0

    def _save_offset(self):
        """Persist current offset to registry."""
        with open(self._registry_path, 'w') as f:
            json.dump({
                'offset': self.offset,
                'inode': self.inode,
                'filepath': self.filepath,
                'updated_at': time.time(),
            }, f)

    def _check_rotation(self) -> bool:
        """Detect if the file has been rotated (new inode)."""
        try:
            stat = os.stat(self.filepath)
            current_inode = stat.st_ino
            if self.inode is not None and current_inode != self.inode:
                # File was rotated
                self.offset = 0
                self.inode = current_inode
                return True
            self.inode = current_inode
            return False
        except FileNotFoundError:
            return False

    def read_new_lines(self) -> List[str]:
        """Read new lines from the file since last offset."""
        try:
            self._check_rotation()

            with open(self.filepath, 'r') as f:
                f.seek(self.offset)
                lines = f.readlines()
                self.offset = f.tell()

            if lines:
                self._save_offset()

            # Process through multi-line joiner
            complete_entries = []
            for line in lines:
                result = self.multiline.process_line(line.rstrip('\n'))
                if result:
                    complete_entries.append(result)

            return complete_entries

        except FileNotFoundError:
            return []


# ──────────────────────────────────────────────
# Log Shipper (sends to Kafka/HTTP)
# ──────────────────────────────────────────────

class LogShipper:
    """
    Batches and ships logs to the central collector.
    Supports compression and retry logic.
    """

    def __init__(self, destination: str = "kafka",
                 batch_size: int = 100, flush_interval_sec: float = 5.0):
        self.destination = destination
        self.batch_size = batch_size
        self.flush_interval = flush_interval_sec
        self.buffer: deque = deque(maxlen=100000)  # Backpressure
        self.lock = threading.Lock()
        self.last_flush = time.time()

        # Metrics
        self.shipped_count = 0
        self.error_count = 0
        self.bytes_shipped = 0

    def enqueue(self, log_entry: LogEntry):
        """Add a log entry to the shipping buffer."""
        with self.lock:
            self.buffer.append(log_entry)

        if len(self.buffer) >= self.batch_size:
            self.flush()

    def flush(self):
        """Send buffered logs to destination."""
        with self.lock:
            if not self.buffer:
                return

            batch = []
            while self.buffer and len(batch) < self.batch_size:
                batch.append(self.buffer.popleft())

        if not batch:
            return

        # Serialize and compress
        payload = '\n'.join(entry.to_json() for entry in batch)
        compressed = gzip.compress(payload.encode('utf-8'))

        # Ship (simplified - in production, use actual Kafka producer or HTTP)
        success = self._send(compressed, len(batch))

        if success:
            self.shipped_count += len(batch)
            self.bytes_shipped += len(compressed)
        else:
            # Re-enqueue on failure (with retry limit)
            self.error_count += 1
            with self.lock:
                for entry in reversed(batch):
                    self.buffer.appendleft(entry)

        self.last_flush = time.time()

    def _send(self, compressed_data: bytes, count: int) -> bool:
        """
        Send compressed log batch to destination.
        Returns True on success.
        """
        try:
            if self.destination == "kafka":
                # In production: kafka_producer.produce(topic, compressed_data)
                pass
            elif self.destination == "http":
                # In production: requests.post(url, data=compressed_data)
                pass

            # Simulate successful send
            compression_ratio = len(compressed_data) / max(
                1, count * 200  # ~200 bytes avg per log
            )
            print(
                f"  📤 Shipped {count} logs "
                f"({len(compressed_data):,} bytes, "
                f"compression: {compression_ratio:.1%})"
            )
            return True

        except Exception as e:
            print(f"  ❌ Ship failed: {e}")
            return False

    def stats(self) -> dict:
        return {
            "shipped": self.shipped_count,
            "errors": self.error_count,
            "bytes_shipped": self.bytes_shipped,
            "buffer_size": len(self.buffer),
        }


# ──────────────────────────────────────────────
# Log Agent (Main Orchestrator)
# ──────────────────────────────────────────────

class LogAgent:
    """
    Main log collection agent that runs on each server.
    Coordinates file tailing, parsing, and shipping.
    """

    def __init__(self, config: dict):
        self.hostname = config.get('hostname', os.uname().nodename)
        self.poll_interval = config.get('poll_interval_sec', 1.0)
        self.running = False

        # Initialize components
        self.parser = LogParser(
            default_service=config.get('default_service', 'unknown')
        )
        self.shipper = LogShipper(
            destination=config.get('destination', 'kafka'),
            batch_size=config.get('batch_size', 100),
        )

        # Setup file tailers
        self.tailers: Dict[str, FileTailer] = {}
        for log_path in config.get('log_files', []):
            self.tailers[log_path] = FileTailer(log_path)

        self.line_counter = 0

    def start(self):
        """Start the agent main loop."""
        self.running = True
        print(f"🚀 Log Agent started on {self.hostname}")
        print(f"   Monitoring {len(self.tailers)} files")

        try:
            while self.running:
                for filepath, tailer in self.tailers.items():
                    new_lines = tailer.read_new_lines()

                    for line_num, raw_line in enumerate(new_lines):
                        self.line_counter += 1
                        entry = self.parser.parse(
                            raw_line, filepath,
                            self.line_counter, self.hostname
                        )
                        if entry:
                            # Apply filters (e.g., drop DEBUG in production)
                            if self._should_ship(entry):
                                self.shipper.enqueue(entry)

                # Periodic flush
                if time.time() - self.shipper.last_flush > 5.0:
                    self.shipper.flush()

                time.sleep(self.poll_interval)

        except KeyboardInterrupt:
            pass
        finally:
            self.stop()

    def stop(self):
        """Graceful shutdown."""
        self.running = False
        self.shipper.flush()
        print(f"\n✅ Agent stopped. Stats: {self.shipper.stats()}")

    def _should_ship(self, entry: LogEntry) -> bool:
        """Filter/sampling logic."""
        # Always ship errors
        if entry.level in ("ERROR", "FATAL"):
            return True
        # Sample DEBUG logs at 10%
        if entry.level == "DEBUG":
            return hash(entry.message) % 10 == 0
        # Ship everything else
        return True


# ──────────────────────────────────────────────
# PII Masking Pipeline Stage
# ──────────────────────────────────────────────

class PIIMasker:
    """Masks sensitive data in log messages before shipping."""

    PATTERNS = [
        # Credit card numbers
        (re.compile(r'\b\d{4}[-\s]?\d{4}[-\s]?\d{4}[-\s]?\d{4}\b'),
         '****-****-****-****'),
        # Email addresses
        (re.compile(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b'),
         '***@***.***'),
        # SSN
        (re.compile(r'\b\d{3}-\d{2}-\d{4}\b'),
         '***-**-****'),
        # IP addresses (optional - may want to keep these)
        # (re.compile(r'\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b'),
        #  '***.***.***.***'),
        # Bearer tokens
        (re.compile(r'Bearer\s+[A-Za-z0-9\-._~+/]+=*'),
         'Bearer ***MASKED***'),
        # API keys (generic pattern)
        (re.compile(r'(?:api[_-]?key|apikey|token)[=:\s]+["\']?([A-Za-z0-9]{20,})["\']?',
                     re.IGNORECASE),
         'api_key=***MASKED***'),
    ]

    @classmethod
    def mask(cls, message: str) -> str:
        for pattern, replacement in cls.PATTERNS:
            message = pattern.sub(replacement, message)
        return message


# ──────────────────────────────────────────────
# Log Search Engine (Simplified)
# ──────────────────────────────────────────────

class LogSearchEngine:
    """
    Simplified log search engine using inverted index.
    In production, this would be Elasticsearch.
    """

    def __init__(self):
        # Inverted index: word → set of doc_ids
        self.inverted_index: Dict[str, set] = defaultdict(set)
        # Field index: field_name:value → set of doc_ids
        self.field_index: Dict[str, set] = defaultdict(set)
        # Document store
        self.docs: Dict[int, dict] = {}
        self.doc_counter = 0

    def index(self, log_entry: LogEntry):
        """Index a log entry."""
        doc_id = self.doc_counter
        self.doc_counter += 1

        # Store document
        doc = asdict(log_entry)
        self.docs[doc_id] = doc

        # Full-text index on message
        words = re.findall(r'\w+', log_entry.message.lower())
        for word in words:
            self.inverted_index[word].add(doc_id)

        # Field indices
        self.field_index[f"level:{log_entry.level}"].add(doc_id)
        self.field_index[f"service:{log_entry.service}"].add(doc_id)
        self.field_index[f"host:{log_entry.host}"].add(doc_id)

        if log_entry.status_code:
            self.field_index[
                f"status_code:{log_entry.status_code}"
            ].add(doc_id)

    def search(self, query: str, filters: Dict[str, str] = None,
               limit: int = 20) -> List[dict]:
        """
        Search logs with full-text query and field filters.

        Example:
            search("timeout error", filters={"level": "ERROR", "service": "api"})
        """
        # Start with full-text search results
        if query:
            words = re.findall(r'\w+', query.lower())
            if words:
                # AND semantics: intersect results for all words
                result_sets = [
                    self.inverted_index.get(w, set()) for w in words
                ]
                matching_docs = set.intersection(*result_sets) if result_sets else set()
            else:
                matching_docs = set(self.docs.keys())
        else:
            matching_docs = set(self.docs.keys())

        # Apply field filters
        if filters:
            for field_name, field_value in filters.items():
                field_key = f"{field_name}:{field_value}"
                field_docs = self.field_index.get(field_key, set())
                matching_docs = matching_docs.intersection(field_docs)

        # Sort by doc_id descending (most recent first) and limit
        sorted_ids = sorted(matching_docs, reverse=True)[:limit]
        return [self.docs[doc_id] for doc_id in sorted_ids]

    def count_by_level(self) -> Dict[str, int]:
        """Get count of logs by level."""
        result = {}
        for key, doc_ids in self.field_index.items():
            if key.startswith("level:"):
                level = key.split(":")[1]
                result[level] = len(doc_ids)
        return result


# ──────────────────────────────────────────────
# Alerting Engine
# ──────────────────────────────────────────────

class LogAlertEngine:
    """
    Detects anomalous log patterns and triggers alerts.
    """

    def __init__(self):
        self.rules: List[dict] = []
        self.window_counts: Dict[str, deque] = defaultdict(
            lambda: deque(maxlen=60)  # 60-second window
        )
        self.alerts_fired: List[dict] = []

    def add_rule(self, name: str, condition: Callable[[LogEntry], bool],
                 threshold: int, window_sec: int = 60,
                 cooldown_sec: int = 300):
        """Add an alerting rule."""
        self.rules.append({
            'name': name,
            'condition': condition,
            'threshold': threshold,
            'window_sec': window_sec,
            'cooldown_sec': cooldown_sec,
            'last_alert': 0,
        })

    def evaluate(self, log_entry: LogEntry):
        """Evaluate all rules against a log entry."""
        now = time.time()

        for rule in self.rules:
            if rule['condition'](log_entry):
                key = rule['name']
                self.window_counts[key].append(now)

                # Count events in window
                cutoff = now - rule['window_sec']
                recent = sum(
                    1 for t in self.window_counts[key] if t > cutoff
                )

                if (recent >= rule['threshold'] and
                        now - rule['last_alert'] > rule['cooldown_sec']):
                    self._fire_alert(rule, recent, log_entry)
                    rule['last_alert'] = now

    def _fire_alert(self, rule: dict, count: int, sample: LogEntry):
        """Fire an alert (send to PagerDuty, Slack, etc.)."""
        alert = {
            'rule': rule['name'],
            'count': count,
            'threshold': rule['threshold'],
            'sample_message': sample.message[:200],
            'service': sample.service,
            'timestamp': time.time(),
        }
        self.alerts_fired.append(alert)
        print(f"  🚨 ALERT: [{rule['name']}] "
              f"{count} events in window (threshold: {rule['threshold']})")


# ──────────────────────────────────────────────
# Demo
# ──────────────────────────────────────────────

def demo_log_system():
    """Demonstrate the log aggregation components."""
    import random

    # Initialize components
    parser = LogParser(default_service="demo-app")
    masker = PIIMasker()
    search_engine = LogSearchEngine()
    alert_engine = LogAlertEngine()

    # Add alert rules
    alert_engine.add_rule(
        name="high_error_rate",
        condition=lambda e: e.level == "ERROR",
        threshold=5,
        window_sec=10,
    )
    alert_engine.add_rule(
        name="5xx_spike",
        condition=lambda e: e.status_code is not None and e.status_code >= 500,
        threshold=3,
        window_sec=10,
    )

    # Sample log lines (various formats)
    sample_logs = [
        # Standard app logs
        '2024-01-15 10:23:45.123 INFO [api-gateway] Request processed successfully req_id=abc-123 duration=45ms',
        '2024-01-15 10:23:45.456 ERROR [auth-service] Authentication failed for user@example.com - Invalid token Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9',
        '2024-01-15 10:23:46.789 WARN [payment-service] Payment processing slow trace_id=xyz-789 duration=2500ms',
        '2024-01-15 10:23:47.001 ERROR [api-gateway] Database connection timeout after 30000ms',
        '2024-01-15 10:23:47.100 ERROR [api-gateway] Connection pool exhausted',
        '2024-01-15 10:23:47.200 ERROR [api-gateway] Request failed with status 500',
        '2024-01-15 10:23:47.300 ERROR [api-gateway] Upstream service unavailable',
        '2024-01-15 10:23:47.400 ERROR [api-gateway] Circuit breaker OPEN',
        # JSON structured log
        '{"timestamp": "2024-01-15T10:23:48Z", "level": "ERROR", "service": "order-service", "message": "Order processing failed", "request_id": "ord-456", "duration_ms": 1200, "status_code": 500}',
        # NGINX log
        '192.168.1.100 - - [15/Jan/2024:10:23:49 +0000] "GET /api/users HTTP/1.1" 200 1234 "-" "Mozilla/5.0"',
        '192.168.1.101 - - [15/Jan/2024:10:23:50 +0000] "POST /api/orders HTTP/1.1" 503 89 "-" "curl/7.68.0"',
        # With PII
        '2024-01-15 10:23:51.000 INFO [user-service] Processing payment for card 4532-1234-5678-9012 email john@example.com',
    ]

    print("=" * 70)
    print("    LOG AGGREGATION SYSTEM DEMO")
    print("=" * 70)

    # Process each log
    for i, raw_log in enumerate(sample_logs):
        print(f"\n{'─' * 60}")
        print(f"RAW: {raw_log[:80]}...")

        # 1. Parse
        entry = parser.parse(raw_log, "/var/log/app.log", i + 1, "server-01")
        if not entry:
            continue

        print(f"  📋 Parsed → level={entry.level}, service={entry.service}")

        # 2. Mask PII
        original_msg = entry.message
        entry.message = masker.mask(entry.message)
        if entry.message != original_msg:
            print(f"  🔒 PII masked: {entry.message[:60]}...")

        # 3. Index for search
        search_engine.index(entry)

        # 4. Check alerts
        alert_engine.evaluate(entry)

    # Search demo
    print(f"\n{'=' * 60}")
    print("SEARCH RESULTS:")
    print(f"{'=' * 60}")

    # Search for errors
    results = search_engine.search("timeout", filters={"level": "ERROR"})
    print(f"\n🔍 Query: 'timeout' + level=ERROR → {len(results)} results")
    for r in results:
        print(f"   [{r['level']}] [{r['service']}] {r['message'][:60]}")

    # Search by service
    results = search_engine.search("", filters={"service": "api-gateway"})
    print(f"\n🔍 Query: service=api-gateway → {len(results)} results")
    for r in results:
        print(f"   [{r['level']}] {r['message'][:60]}")

    # Level distribution
    print(f"\n📊 Log Level Distribution: {search_engine.count_by_level()}")
    print(f"🚨 Alerts fired: {len(alert_engine.alerts_fired)}")
    for alert in alert_engine.alerts_fired:
        print(f"   - {alert['rule']}: {alert['count']} events")


if __name__ == "__main__":
    demo_log_system()
```

---
---

## 25. Recommendation System

### Problem Statement

Design a system like **Netflix recommendations**, **Amazon "Customers who bought..."**, or **Spotify Discover Weekly**. The system should provide personalized recommendations in real-time.

---

### Requirements

```
Functional:
1. Personalized recommendations per user
2. "Similar items" recommendations
3. "Frequently bought together" 
4. Trending/popular items (cold start)
5. Real-time updates based on recent activity
6. A/B testing framework for model comparison

Non-Functional:
- Latency: < 100ms for serving recommendations
- Scale: 100M+ users, 10M+ items
- Freshness: incorporates user activity within minutes
- Availability: 99.99% (revenue critical)
```

---

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                       RECOMMENDATION SYSTEM                                 │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │                    DATA COLLECTION LAYER                            │    │
│  │                                                                     │    │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────────────┐  │    │
│  │  │  Clicks  │  │ Purchases│  │  Ratings │  │ Session/Browse   │  │    │
│  │  │  Stream  │  │  Stream  │  │  Stream  │  │ History Stream   │  │    │
│  │  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────────┬────────┘  │    │
│  │       └──────────────┴─────────────┴─────────────────┘            │    │
│  └──────────────────────────────┬──────────────────────────────────────┘    │
│                                 │                                           │
│                                 ▼                                           │
│  ┌──────────────────────────────────────────────────────────────────┐      │
│  │                    Kafka Event Bus                                │      │
│  │                                                                  │      │
│  │   Topics: user-events, item-updates, interaction-events         │      │
│  └─────────────┬──────────────────────┬─────────────────────────────┘      │
│                │                      │                                     │
│         ┌──────┴──────┐        ┌──────┴──────┐                             │
│         │  OFFLINE    │        │  ONLINE     │                             │
│         │  PIPELINE   │        │  PIPELINE   │                             │
│         │  (BATCH)    │        │  (REAL-TIME) │                            │
│         └──────┬──────┘        └──────┬──────┘                             │
│                │                      │                                     │
│                ▼                      ▼                                     │
│  ┌─────────────────────┐  ┌──────────────────────┐                        │
│  │  OFFLINE TRAINING   │  │  ONLINE FEATURE      │                        │
│  │                     │  │  COMPUTATION          │                        │
│  │  ┌───────────────┐  │  │                      │                        │
│  │  │Collaborative  │  │  │  • Recent clicks     │                        │
│  │  │Filtering (ALS)│  │  │  • Session context   │                        │
│  │  └───────────────┘  │  │  • Real-time trends  │                        │
│  │  ┌───────────────┐  │  │  • User embedding    │                        │
│  │  │Content-Based  │  │  │    update            │                        │
│  │  │(Item features)│  │  │                      │                        │
│  │  └───────────────┘  │  └──────────┬───────────┘                        │
│  │  ┌───────────────┐  │             │                                     │
│  │  │Deep Learning  │  │             │                                     │
│  │  │(Neural CF,    │  │             │                                     │
│  │  │ Two-tower)    │  │             │                                     │
│  │  └───────────────┘  │             │                                     │
│  │  ┌───────────────┐  │             │                                     │
│  │  │Item-Item      │  │             │                                     │
│  │  │Similarity     │  │             │                                     │
│  │  └───────┬───────┘  │             │                                     │
│  └──────────┼──────────┘             │                                     │
│             │                        │                                     │
│             ▼                        ▼                                     │
│  ┌──────────────────────────────────────────────────────────────────┐      │
│  │                    MODEL & FEATURE STORE                         │      │
│  │                                                                  │      │
│  │  ┌────────────────┐  ┌────────────────┐  ┌──────────────────┐  │      │
│  │  │  User Embeddings│  │Item Embeddings │  │ Similarity       │  │      │
│  │  │  (Redis/Milvus) │  │(Redis/Milvus)  │  │ Matrix (ANN)    │  │      │
│  │  └────────────────┘  └────────────────┘  └──────────────────┘  │      │
│  │  ┌────────────────┐  ┌────────────────┐  ┌──────────────────┐  │      │
│  │  │  Feature Store │  │  Model Registry│  │ Pre-computed     │  │      │
│  │  │  (Feast)       │  │  (MLflow)      │  │ Recommendations  │  │      │
│  │  └────────────────┘  └────────────────┘  └──────────────────┘  │      │
│  └──────────────────────────────┬───────────────────────────────────┘      │
│                                 │                                           │
│                                 ▼                                           │
│  ┌──────────────────────────────────────────────────────────────────┐      │
│  │                 RECOMMENDATION SERVING LAYER                     │      │
│  │                                                                  │      │
│  │  ┌──────────────┐                                               │      │
│  │  │  CANDIDATE   │  Retrieve top-1000 candidates from            │      │
│  │  │  GENERATION  │  multiple sources (ANN, popular, recent)      │      │
│  │  └──────┬───────┘                                               │      │
│  │         │                                                        │      │
│  │         ▼                                                        │      │
│  │  ┌──────────────┐                                               │      │
│  │  │   FILTERING  │  Remove already-seen, out-of-stock,           │      │
│  │  │              │  age-restricted, etc.                          │      │
│  │  └──────┬───────┘                                               │      │
│  │         │                                                        │      │
│  │         ▼                                                        │      │
│  │  ┌──────────────┐                                               │      │
│  │  │   SCORING /  │  Re-rank candidates with ML model             │      │
│  │  │   RANKING    │  considering context, diversity               │      │
│  │  └──────┬───────┘                                               │      │
│  │         │                                                        │      │
│  │         ▼                                                        │      │
│  │  ┌──────────────┐                                               │      │
│  │  │  POST-       │  Diversity injection, business rules,         │      │
│  │  │  PROCESSING  │  A/B test assignment                          │      │
│  │  └──────┬───────┘                                               │      │
│  │         │                                                        │      │
│  │         ▼                                                        │      │
│  │    Return top-20 recommendations                                │      │
│  └──────────────────────────────────────────────────────────────────┘      │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

### Deep Dive: Recommendation Algorithms

```
┌────────────────────────────────────────────────────────────────────┐
│             RECOMMENDATION ALGORITHM LANDSCAPE                     │
│                                                                    │
│  ┌────────────────────────────────────────────┐                   │
│  │  1. COLLABORATIVE FILTERING                │                   │
│  │     "Users who liked X also liked Y"       │                   │
│  │                                            │                   │
│  │     User-User CF:                          │                   │
│  │     Find similar users → recommend their   │                   │
│  │     highly rated items                     │                   │
│  │                                            │                   │
│  │     Item-Item CF:                          │                   │
│  │     Find items similar to user's history   │                   │
│  │     (Amazon's approach)                    │                   │
│  │                                            │                   │
│  │     Matrix Factorization (ALS/SVD):        │                   │
│  │     Decompose User×Item matrix into        │                   │
│  │     low-rank factors (embeddings)          │                   │
│  │                                            │                   │
│  │     User × Item = User_Embed × Item_Embed  │                   │
│  │     [100M×10M] ≈ [100M×128] × [128×10M]   │                   │
│  └────────────────────────────────────────────┘                   │
│                                                                    │
│  ┌────────────────────────────────────────────┐                   │
│  │  2. CONTENT-BASED FILTERING                │                   │
│  │     "Items with similar features to X"     │                   │
│  │                                            │                   │
│  │     • Item features: genre, director, tags │                   │
│  │     • TF-IDF on descriptions              │                   │
│  │     • Deep learning embeddings (BERT)     │                   │
│  │     • Good for cold-start items           │                   │
│  └────────────────────────────────────────────┘                   │
│                                                                    │
│  ┌────────────────────────────────────────────┐                   │
│  │  3. HYBRID APPROACHES                      │                   │
│  │                                            │                   │
│  │     Two-Tower Model (Google):             │                   │
│  │     ┌──────────┐     ┌──────────┐         │                   │
│  │     │User Tower│     │Item Tower│         │                   │
│  │     │(user feat│     │(item feat│         │                   │
│  │     │→ embed)  │     │→ embed)  │         │                   │
│  │     └────┬─────┘     └────┬─────┘         │                   │
│  │          │                │                │                   │
│  │          └───── dot ──────┘                │                   │
│  │               product                      │                   │
│  │            = relevance                     │                   │
│  │              score                         │                   │
│  │                                            │                   │
│  │     Wide & Deep (Google):                 │                   │
│  │     Wide (memorization) + Deep (general)  │                   │
│  └────────────────────────────────────────────┘                   │
│                                                                    │
│  ┌────────────────────────────────────────────┐                   │
│  │  4. KNOWLEDGE GRAPH / GRAPH NEURAL NET    │                   │
│  │                                            │                   │
│  │     User ──watched──► Movie ──genre──► Sci-Fi │                │
│  │       │                 │                  │                   │
│  │       │              directed_by           │                   │
│  │       │                 │                  │                   │
│  │       └──liked──►   Director ──directed──► Movie2│            │
│  │                                            │                   │
│  │     Graph embeddings capture complex       │                   │
│  │     relationships beyond simple similarity │                   │
│  └────────────────────────────────────────────┘                   │
└────────────────────────────────────────────────────────────────────┘
```

---

### Serving Architecture (Multi-Stage Funnel)

```
┌──────────────────────────────────────────────────────────────┐
│            RECOMMENDATION SERVING FUNNEL                      │
│                                                              │
│   User Request (user_id, context)                            │
│           │                                                  │
│           ▼                                                  │
│   ┌───────────────────────────────────────┐                 │
│   │  STAGE 1: CANDIDATE GENERATION       │                 │
│   │  ~100ms budget                       │                 │
│   │                                       │                 │
│   │  Source 1: ANN Search (user embed     │                 │
│   │    → nearest item embeds) → 500 items │                 │
│   │                                       │                 │
│   │  Source 2: Item-Item CF               │                 │
│   │    (similar to recently viewed) → 200 │                 │
│   │                                       │                 │
│   │  Source 3: Popular/Trending → 100     │                 │
│   │                                       │                 │
│   │  Source 4: Editorial/Curated → 50     │                 │
│   │                                       │                 │
│   │  Union + Dedup → ~800 candidates     │                 │
│   └───────────────┬───────────────────────┘                 │
│                   │                                          │
│                   ▼                                          │
│   ┌───────────────────────────────────────┐                 │
│   │  STAGE 2: FILTERING                  │                 │
│   │  ~10ms budget                        │                 │
│   │                                       │                 │
│   │  Remove:                              │                 │
│   │  • Already watched/purchased         │                 │
│   │  • Out of stock / unavailable        │                 │
│   │  • Age-restricted / geo-blocked      │                 │
│   │  • Low quality (< threshold)         │                 │
│   │                                       │                 │
│   │  → ~500 candidates remain            │                 │
│   └───────────────┬───────────────────────┘                 │
│                   │                                          │
│                   ▼                                          │
│   ┌───────────────────────────────────────┐                 │
│   │  STAGE 3: SCORING / RANKING          │                 │
│   │  ~30ms budget                        │                 │
│   │                                       │                 │
│   │  ML Ranking Model:                   │                 │
│   │  score = model(user_features,        │                 │
│   │               item_features,         │                 │
│   │               context_features)      │                 │
│   │                                       │                 │
│   │  Features:                            │                 │
│   │  • User: age, country, watch history │                 │
│   │  • Item: genre, popularity, recency  │                 │
│   │  • Context: time of day, device      │                 │
│   │  • Cross: user×item interaction score│                 │
│   │                                       │                 │
│   │  Sort by score → top 50             │                 │
│   └───────────────┬───────────────────────┘                 │
│                   │                                          │
│                   ▼                                          │
│   ┌───────────────────────────────────────┐                 │
│   │  STAGE 4: POST-PROCESSING            │                 │
│   │  ~5ms budget                         │                 │
│   │                                       │                 │
│   │  • Diversity: ensure variety          │                 │
│   │    (not all same genre/category)     │                 │
│   │  • Business rules: boost promotions  │                 │
│   │  • Freshness: mix in new items       │                 │
│   │  • A/B test bucketing                │                 │
│   │                                       │                 │
│   │  → Final 20 recommendations         │                 │
│   └───────────────────────────────────────┘                 │
│                                                              │
│   Total latency: < 100ms (P99)                              │
└──────────────────────────────────────────────────────────────┘
```

---

### Python Implementation

#### Core Recommendation Algorithms

```python
"""
Recommendation System - Complete Implementation
Includes: Collaborative Filtering, Content-Based, ANN Search, and Serving Layer.
"""

import numpy as np
import json
import time
import hashlib
import heapq
from collections import defaultdict, Counter
from dataclasses import dataclass, field
from typing import Dict, List, Optional, Tuple, Set
from abc import ABC, abstractmethod
import math
import random


# ══════════════════════════════════════════════
# DATA MODELS
# ══════════════════════════════════════════════

@dataclass
class User:
    user_id: str
    features: Dict[str, any] = field(default_factory=dict)
    # e.g., {"age_group": "25-34", "country": "US", "gender": "M"}


@dataclass
class Item:
    item_id: str
    title: str
    category: str
    tags: List[str] = field(default_factory=list)
    features: Dict[str, float] = field(default_factory=dict)
    popularity_score: float = 0.0
    created_at: float = 0.0


@dataclass
class Interaction:
    user_id: str
    item_id: str
    interaction_type: str  # "view", "click", "purchase", "rating"
    value: float = 1.0     # Rating value or implicit weight
    timestamp: float = 0.0


@dataclass
class RecommendationRequest:
    user_id: str
    num_items: int = 20
    context: Dict[str, any] = field(default_factory=dict)
    # e.g., {"device": "mobile", "time_of_day": "evening"}
    exclude_items: Set[str] = field(default_factory=set)


@dataclass
class ScoredItem:
    item_id: str
    score: float
    source: str  # Which algorithm generated this candidate
    explanation: str = ""


# ══════════════════════════════════════════════
# COLLABORATIVE FILTERING (Matrix Factorization)
# ══════════════════════════════════════════════

class ALSMatrixFactorization:
    """
    Alternating Least Squares for implicit feedback.
    
    Factorizes the User-Item interaction matrix R into:
        R ≈ U × V^T
    where U = user factors, V = item factors

    For 100M users × 10M items with 128 dimensions:
    - U: 100M × 128 = ~50 GB
    - V: 10M × 128 = ~5 GB
    
    In production: Use Spark MLlib ALS or implicit library.
    """

    def __init__(self, num_factors: int = 64, regularization: float = 0.01,
                 iterations: int = 15, alpha: float = 40.0):
        self.num_factors = num_factors
        self.reg = regularization
        self.iterations = iterations
        self.alpha = alpha  # Confidence weight for implicit feedback

        self.user_factors: Dict[str, np.ndarray] = {}
        self.item_factors: Dict[str, np.ndarray] = {}
        self.user_idx: Dict[str, int] = {}
        self.item_idx: Dict[str, int] = {}
        self.idx_user: Dict[int, str] = {}
        self.idx_item: Dict[int, str] = {}

    def fit(self, interactions: List[Interaction]):
        """Train ALS model on interaction data."""
        print(f"  Training ALS with {len(interactions)} interactions...")

        # Build index mappings
        users = sorted(set(i.user_id for i in interactions))
        items = sorted(set(i.item_id for i in interactions))

        self.user_idx = {u: i for i, u in enumerate(users)}
        self.item_idx = {it: i for i, it in enumerate(items)}
        self.idx_user = {i: u for u, i in self.user_idx.items()}
        self.idx_item = {i: it for it, i in self.item_idx.items()}

        n_users = len(users)
        n_items = len(items)

        # Build interaction matrix (sparse in production)
        R = np.zeros((n_users, n_items))
        for inter in interactions:
            ui = self.user_idx.get(inter.user_id)
            ii = self.item_idx.get(inter.item_id)
            if ui is not None and ii is not None:
                R[ui, ii] = inter.value

        # Confidence matrix: C = 1 + alpha * R
        C = 1.0 + self.alpha * R
        # Preference matrix: P = (R > 0)
        P = (R > 0).astype(float)

        # Initialize factors randomly
        U = np.random.normal(0, 0.01, (n_users, self.num_factors))
        V = np.random.normal(0, 0.01, (n_items, self.num_factors))

        reg_I = self.reg * np.eye(self.num_factors)

        # ALS iterations
        for iteration in range(self.iterations):
            # Fix V, solve for U
            VtV = V.T @ V
            for u in range(n_users):
                Cu = np.diag(C[u, :])
                U[u] = np.linalg.solve(
                    VtV + V.T @ (Cu - np.eye(n_items)) @ V + reg_I,
                    V.T @ Cu @ P[u, :]
                )

            # Fix U, solve for V
            UtU = U.T @ U
            for i in range(n_items):
                Ci = np.diag(C[:, i])
                V[i] = np.linalg.solve(
                    UtU + U.T @ (Ci - np.eye(n_users)) @ U + reg_I,
                    U.T @ Ci @ P[:, i]
                )

            # Compute loss (for monitoring convergence)
            if (iteration + 1) % 5 == 0:
                pred = U @ V.T
                loss = np.sum(C * (P - pred) ** 2) + \
                       self.reg * (np.sum(U ** 2) + np.sum(V ** 2))
                print(f"    Iteration {iteration + 1}/{self.iterations}, "
                      f"loss: {loss:.4f}")

        # Store factors
        for uid, idx in self.user_idx.items():
            self.user_factors[uid] = U[idx]
        for iid, idx in self.item_idx.items():
            self.item_factors[iid] = V[idx]

        print(f"  ✅ ALS training complete. "
              f"{n_users} users, {n_items} items, "
              f"{self.num_factors} factors")

    def recommend(self, user_id: str, n: int = 20,
                  exclude: Set[str] = None) -> List[ScoredItem]:
        """Get top-N recommendations for a user."""
        if user_id not in self.user_factors:
            return []

        user_vec = self.user_factors[user_id]
        exclude = exclude or set()

        scores = []
        for item_id, item_vec in self.item_factors.items():
            if item_id in exclude:
                continue
            score = float(np.dot(user_vec, item_vec))
            scores.append(ScoredItem(
                item_id=item_id,
                score=score,
                source="als_cf",
                explanation="Based on your interaction patterns"
            ))

        scores.sort(key=lambda x: x.score, reverse=True)
        return scores[:n]

    def similar_items(self, item_id: str, n: int = 10) -> List[ScoredItem]:
        """Find items similar to the given item."""
        if item_id not in self.item_factors:
            return []

        target_vec = self.item_factors[item_id]
        target_norm = np.linalg.norm(target_vec)
        if target_norm == 0:
            return []

        scores = []
        for other_id, other_vec in self.item_factors.items():
            if other_id == item_id:
                continue
            other_norm = np.linalg.norm(other_vec)
            if other_norm == 0:
                continue
            cosine_sim = float(
                np.dot(target_vec, other_vec) / (target_norm * other_norm)
            )
            scores.append(ScoredItem(
                item_id=other_id,
                score=cosine_sim,
                source="item_similarity",
                explanation=f"Similar to {item_id}"
            ))

        scores.sort(key=lambda x: x.score, reverse=True)
        return scores[:n]


# ══════════════════════════════════════════════
# CONTENT-BASED FILTERING
# ══════════════════════════════════════════════

class ContentBasedRecommender:
    """
    Content-based filtering using item features (TF-IDF style).
    Recommends items similar in content to what the user has liked.
    """

    def __init__(self):
        self.item_features: Dict[str, Dict[str, float]] = {}
        self.idf: Dict[str, float] = {}  # Inverse document frequency
        self.user_profiles: Dict[str, Dict[str, float]] = {}

    def build_item_profiles(self, items: List[Item]):
        """Build TF-IDF feature vectors for all items."""
        # Count document frequency for each tag/feature
        doc_freq: Dict[str, int] = defaultdict(int)
        n_docs = len(items)

        for item in items:
            features = set()
            features.add(f"category:{item.category}")
            for tag in item.tags:
                features.add(f"tag:{tag}")
            for feat_name, feat_val in item.features.items():
                features.add(f"feat:{feat_name}:{feat_val:.1f}")

            for feat in features:
                doc_freq[feat] += 1

        # Compute IDF
        self.idf = {
            feat: math.log(n_docs / (1 + freq))
            for feat, freq in doc_freq.items()
        }

        # Build TF-IDF vectors for each item
        for item in items:
            features = defaultdict(float)
            features[f"category:{item.category}"] = 1.0
            for tag in item.tags:
                features[f"tag:{tag}"] = 1.0
            for feat_name, feat_val in item.features.items():
                features[f"feat:{feat_name}:{feat_val:.1f}"] = feat_val

            # Apply IDF weighting
            tfidf = {}
            for feat, tf in features.items():
                tfidf[feat] = tf * self.idf.get(feat, 1.0)

            # L2 normalize
            norm = math.sqrt(sum(v ** 2 for v in tfidf.values()))
            if norm > 0:
                tfidf = {k: v / norm for k, v in tfidf.items()}

            self.item_features[item.item_id] = tfidf

    def build_user_profile(self, user_id: str,
                           interactions: List[Interaction]):
        """Build user profile from their interaction history."""
        profile: Dict[str, float] = defaultdict(float)
        total_weight = 0

        for inter in interactions:
            if inter.user_id != user_id:
                continue
            item_feats = self.item_features.get(inter.item_id, {})
            weight = inter.value
            total_weight += weight

            for feat, val in item_feats.items():
                profile[feat] += val * weight

        # Normalize
        if total_weight > 0:
            profile = {k: v / total_weight for k, v in profile.items()}

        self.user_profiles[user_id] = dict(profile)

    def recommend(self, user_id: str, n: int = 20,
                  exclude: Set[str] = None) -> List[ScoredItem]:
        """Recommend items based on content similarity to user profile."""
        if user_id not in self.user_profiles:
            return []

        user_profile = self.user_profiles[user_id]
        exclude = exclude or set()

        scores = []
        for item_id, item_feats in self.item_features.items():
            if item_id in exclude:
                continue

            # Cosine similarity between user profile and item features
            dot_product = sum(
                user_profile.get(feat, 0) * val
                for feat, val in item_feats.items()
            )
            scores.append(ScoredItem(
                item_id=item_id,
                score=dot_product,
                source="content_based",
                explanation="Matches your taste profile"
            ))

        scores.sort(key=lambda x: x.score, reverse=True)
        return scores[:n]


# ══════════════════════════════════════════════
# APPROXIMATE NEAREST NEIGHBOR (ANN) INDEX
# ══════════════════════════════════════════════

class LSHIndex:
    """
    Locality-Sensitive Hashing for fast approximate nearest neighbor search.
    
    In production: Use FAISS, ScaNN, Annoy, or Milvus.
    
    This implementation uses random hyperplane LSH for cosine similarity.
    """

    def __init__(self, dim: int, num_tables: int = 10,
                 num_hashes: int = 8):
        self.dim = dim
        self.num_tables = num_tables
        self.num_hashes = num_hashes

        # Random hyperplanes for each hash table
        self.hyperplanes = [
            np.random.randn(num_hashes, dim) for _ in range(num_tables)
        ]
        # Hash tables: table_idx → hash_key → list of (item_id, vector)
        self.tables: List[Dict[str, List[Tuple[str, np.ndarray]]]] = [
            defaultdict(list) for _ in range(num_tables)
        ]
        self.vectors: Dict[str, np.ndarray] = {}

    def _hash(self, vector: np.ndarray, table_idx: int) -> str:
        """Compute LSH hash for a vector using the given table's hyperplanes."""
        projections = self.hyperplanes[table_idx] @ vector
        bits = (projections > 0).astype(int)
        return ''.join(str(b) for b in bits)

    def add(self, item_id: str, vector: np.ndarray):
        """Add a vector to the index."""
        self.vectors[item_id] = vector
        for t in range(self.num_tables):
            hash_key = self._hash(vector, t)
            self.tables[t][hash_key].append((item_id, vector))

    def search(self, query_vector: np.ndarray, k: int = 20,
               num_probes: int = 1) -> List[Tuple[str, float]]:
        """
        Find k approximate nearest neighbors.
        
        Multi-probe: Also check neighboring hash buckets 
        (flip 1 bit at a time).
        """
        candidates = set()

        for t in range(self.num_tables):
            hash_key = self._hash(query_vector, t)

            # Exact bucket
            for item_id, _ in self.tables[t].get(hash_key, []):
                candidates.add(item_id)

            # Multi-probe: flip each bit
            if num_probes > 1:
                for bit_idx in range(self.num_hashes):
                    flipped = list(hash_key)
                    flipped[bit_idx] = '1' if flipped[bit_idx] == '0' else '0'
                    flipped_key = ''.join(flipped)
                    for item_id, _ in self.tables[t].get(flipped_key, []):
                        candidates.add(item_id)

        # Re-rank candidates by exact cosine similarity
        query_norm = np.linalg.norm(query_vector)
        if query_norm == 0:
            return []

        results = []
        for item_id in candidates:
            vec = self.vectors[item_id]
            vec_norm = np.linalg.norm(vec)
            if vec_norm == 0:
                continue
            sim = float(np.dot(query_vector, vec) / (query_norm * vec_norm))
            results.append((item_id, sim))

        results.sort(key=lambda x: x[1], reverse=True)
        return results[:k]

    def stats(self) -> dict:
        total_entries = sum(
            sum(len(bucket) for bucket in table.values())
            for table in self.tables
        )
        return {
            "num_vectors": len(self.vectors),
            "num_tables": self.num_tables,
            "total_index_entries": total_entries,
            "avg_bucket_size": total_entries / max(
                sum(len(table) for table in self.tables), 1
            ),
        }


# ══════════════════════════════════════════════
# CO-OCCURRENCE / "FREQUENTLY BOUGHT TOGETHER"
# ══════════════════════════════════════════════

class CoOccurrenceRecommender:
    """
    "Customers who bought X also bought Y"
    Based on item co-occurrence in user sessions/orders.
    """

    def __init__(self, min_support: int = 5):
        self.min_support = min_support
        # item_pair → count
        self.pair_counts: Dict[Tuple[str, str], int] = defaultdict(int)
        # item → total count
        self.item_counts: Dict[str, int] = defaultdict(int)
        # Pre-computed recommendations
        self.recommendations: Dict[str, List[ScoredItem]] = {}

    def build(self, sessions: List[List[str]]):
        """
        Build co-occurrence matrix from sessions (purchase/view sessions).
        Each session is a list of item_ids.
        """
        for session in sessions:
            unique_items = list(set(session))
            for item in unique_items:
                self.item_counts[item] += 1

            for i in range(len(unique_items)):
                for j in range(i + 1, len(unique_items)):
                    pair = tuple(sorted([unique_items[i], unique_items[j]]))
                    self.pair_counts[pair] += 1

        # Pre-compute recommendations using lift
        for (item_a, item_b), count in self.pair_counts.items():
            if count < self.min_support:
                continue

            n_sessions = len(sessions)
            # Lift = P(A,B) / (P(A) * P(B))
            p_ab = count / n_sessions
            p_a = self.item_counts[item_a] / n_sessions
            p_b = self.item_counts[item_b] / n_sessions

            lift = p_ab / (p_a * p_b) if p_a * p_b > 0 else 0

            # Store bidirectional recommendations
            if item_a not in self.recommendations:
                self.recommendations[item_a] = []
            self.recommendations[item_a].append(ScoredItem(
                item_id=item_b, score=lift,
                source="co_occurrence",
                explanation="Frequently bought together"
            ))

            if item_b not in self.recommendations:
                self.recommendations[item_b] = []
            self.recommendations[item_b].append(ScoredItem(
                item_id=item_a, score=lift,
                source="co_occurrence",
                explanation="Frequently bought together"
            ))

        # Sort recommendations by score
        for item_id in self.recommendations:
            self.recommendations[item_id].sort(
                key=lambda x: x.score, reverse=True
            )

    def recommend(self, item_id: str, n: int = 10) -> List[ScoredItem]:
        """Get items frequently co-occurring with the given item."""
        return self.recommendations.get(item_id, [])[:n]


# ══════════════════════════════════════════════
# POPULARITY / TRENDING (Cold Start)
# ══════════════════════════════════════════════

class PopularityRecommender:
    """
    Trending and popular items recommender.
    Used for cold-start users or as a fallback.
    Uses exponential decay for time-weighted popularity.
    """

    def __init__(self, decay_rate: float = 0.1):
        self.decay_rate = decay_rate  # Per hour decay
        self.interaction_log: List[Interaction] = []

    def add_interaction(self, interaction: Interaction):
        self.interaction_log.append(interaction)

    def get_trending(self, n: int = 20, 
                     time_window_hours: int = 24) -> List[ScoredItem]:
        """Get trending items with time-weighted scoring."""
        now = time.time()
        cutoff = now - time_window_hours * 3600
        scores: Dict[str, float] = defaultdict(float)

        for inter in self.interaction_log:
            if inter.timestamp < cutoff:
                continue
            hours_ago = (now - inter.timestamp) / 3600
            weight = math.exp(-self.decay_rate * hours_ago)

            # Weight by interaction type
            type_weight = {
                "purchase": 5.0,
                "rating": 3.0,
                "click": 1.0,
                "view": 0.5,
            }.get(inter.interaction_type, 1.0)

            scores[inter.item_id] += weight * type_weight * inter.value

        ranked = sorted(scores.items(), key=lambda x: x[1], reverse=True)

        return [
            ScoredItem(
                item_id=item_id,
                score=score,
                source="trending",
                explanation="Trending right now"
            )
            for item_id, score in ranked[:n]
        ]

    def get_popular_by_category(self, category: str, items: Dict[str, Item],
                                n: int = 10) -> List[ScoredItem]:
        """Get popular items within a category."""
        category_items = {
            iid for iid, item in items.items() if item.category == category
        }
        trending = self.get_trending(n=n * 3)
        return [
            item for item in trending if item.item_id in category_items
        ][:n]


# ══════════════════════════════════════════════
# RECOMMENDATION SERVING (Multi-Stage Pipeline)
# ══════════════════════════════════════════════

class DiversityReranker:
    """
    Re-ranks recommendations to ensure diversity.
    Uses Maximal Marginal Relevance (MMR).
    """

    @staticmethod
    def rerank(candidates: List[ScoredItem],
               item_categories: Dict[str, str],
               diversity_weight: float = 0.3,
               n: int = 20) -> List[ScoredItem]:
        """
        MMR-style re-ranking for diversity.
        
        Score = (1-λ) * relevance - λ * max_sim_to_selected
        
        We approximate similarity by category overlap.
        """
        if len(candidates) <= n:
            return candidates

        selected: List[ScoredItem] = []
        remaining = list(candidates)

        # Always pick the best item first
        remaining.sort(key=lambda x: x.score, reverse=True)
        selected.append(remaining.pop(0))

        while len(selected) < n and remaining:
            best_score = float('-inf')
            best_idx = 0

            for i, candidate in enumerate(remaining):
                relevance = candidate.score

                # Compute diversity penalty (based on category overlap)
                candidate_cat = item_categories.get(candidate.item_id, "")
                max_similarity = 0.0
                for sel in selected:
                    sel_cat = item_categories.get(sel.item_id, "")
                    if candidate_cat == sel_cat and candidate_cat:
                        max_similarity = max(max_similarity, 1.0)

                mmr_score = ((1 - diversity_weight) * relevance -
                            diversity_weight * max_similarity)

                if mmr_score > best_score:
                    best_score = mmr_score
                    best_idx = i

            selected.append(remaining.pop(best_idx))

        return selected


class ABTestManager:
    """Simple A/B test bucketing for recommendation experiments."""

    def __init__(self):
        self.experiments: Dict[str, dict] = {}

    def create_experiment(self, name: str, variants: List[str],
                          traffic_split: List[float]):
        """Create an A/B test experiment."""
        assert len(variants) == len(traffic_split)
        assert abs(sum(traffic_split) - 1.0) < 0.01

        cumulative = []
        total = 0
        for split in traffic_split:
            total += split
            cumulative.append(total)

        self.experiments[name] = {
            'variants': variants,
            'cumulative_splits': cumulative,
        }

    def get_variant(self, experiment_name: str, user_id: str) -> str:
        """Deterministically assign user to experiment variant."""
        if experiment_name not in self.experiments:
            return "control"

        exp = self.experiments[experiment_name]
        # Deterministic hash-based bucketing
        hash_val = int(hashlib.md5(
            f"{experiment_name}:{user_id}".encode()
        ).hexdigest(), 16) % 10000 / 10000

        for i, threshold in enumerate(exp['cumulative_splits']):
            if hash_val < threshold:
                return exp['variants'][i]

        return exp['variants'][-1]


class RecommendationEngine:
    """
    Main recommendation serving engine.
    Orchestrates multiple recommenders in a multi-stage pipeline.
    """

    def __init__(self):
        self.cf_model = ALSMatrixFactorization(num_factors=32, iterations=10)
        self.content_model = ContentBasedRecommender()
        self.cooccurrence = CoOccurrenceRecommender(min_support=2)
        self.popularity = PopularityRecommender()
        self.ann_index = LSHIndex(dim=32, num_tables=5, num_hashes=6)
        self.diversity = DiversityReranker()
        self.ab_test = ABTestManager()

        self.items: Dict[str, Item] = {}
        self.user_history: Dict[str, Set[str]] = defaultdict(set)
        self.item_categories: Dict[str, str] = {}

    def train(self, items: List[Item], interactions: List[Interaction]):
        """Train all recommendation models."""
        print("🔧 Training recommendation models...")
        start = time.time()

        # Store items
        for item in items:
            self.items[item.item_id] = item
            self.item_categories[item.item_id] = item.category

        # Build user history
        for inter in interactions:
            self.user_history[inter.user_id].add(inter.item_id)

        # 1. Train collaborative filtering
        self.cf_model.fit(interactions)

        # 2. Build content profiles
        self.content_model.build_item_profiles(items)
        for user_id in self.user_history:
            self.content_model.build_user_profile(user_id, interactions)

        # 3. Build co-occurrence
        sessions = defaultdict(list)
        for inter in interactions:
            sessions[inter.user_id].append(inter.item_id)
        self.cooccurrence.build(list(sessions.values()))

        # 4. Build popularity model
        for inter in interactions:
            self.popularity.add_interaction(inter)

        # 5. Build ANN index from item factors
        for item_id, vector in self.cf_model.item_factors.items():
            self.ann_index.add(item_id, vector)

        # 6. Setup A/B test
        self.ab_test.create_experiment(
            "ranking_model_v2",
            variants=["control", "new_ranker"],
            traffic_split=[0.8, 0.2],
        )

        elapsed = time.time() - start
        print(f"✅ Training complete in {elapsed:.1f}s")
        print(f"   Users: {len(self.user_history)}")
        print(f"   Items: {len(self.items)}")
        print(f"   ANN Index: {self.ann_index.stats()}")

    def recommend(self, request: RecommendationRequest) -> List[ScoredItem]:
        """
        Main recommendation pipeline.
        Multi-stage: Candidate Generation → Filtering → Scoring → Re-ranking
        """
        start_time = time.time()
        user_id = request.user_id
        exclude = request.exclude_items | self.user_history.get(user_id, set())

        # ─── Stage 1: Candidate Generation ───
        candidates: Dict[str, ScoredItem] = {}  # item_id → best score

        # Source 1: Collaborative Filtering
        cf_recs = self.cf_model.recommend(user_id, n=50, exclude=exclude)
        for rec in cf_recs:
            candidates[rec.item_id] = rec

        # Source 2: ANN search (fast approximate lookup)
        if user_id in self.cf_model.user_factors:
            user_vec = self.cf_model.user_factors[user_id]
            ann_results = self.ann_index.search(user_vec, k=50)
            for item_id, sim in ann_results:
                if item_id not in exclude and item_id not in candidates:
                    candidates[item_id] = ScoredItem(
                        item_id=item_id, score=sim,
                        source="ann_search",
                        explanation="Personalized for you"
                    )

        # Source 3: Content-based
        content_recs = self.content_model.recommend(
            user_id, n=30, exclude=exclude
        )
        for rec in content_recs:
            if rec.item_id not in candidates:
                candidates[rec.item_id] = rec

        # Source 4: "Bought together" (based on recent items)
        recent_items = list(self.user_history.get(user_id, set()))[:5]
        for recent_item in recent_items:
            cooc_recs = self.cooccurrence.recommend(recent_item, n=10)
            for rec in cooc_recs:
                if rec.item_id not in exclude and rec.item_id not in candidates:
                    candidates[rec.item_id] = rec

        # Source 5: Trending (fill-in for diversity / cold start)
        trending = self.popularity.get_trending(n=20)
        for rec in trending:
            if rec.item_id not in exclude and rec.item_id not in candidates:
                candidates[rec.item_id] = rec

        # ─── Stage 2: Filtering ───
        filtered = []
        for item_id, scored in candidates.items():
            item = self.items.get(item_id)
            if item is None:
                continue
            # Business rules filtering
            # (In production: check inventory, geo-restrictions, etc.)
            filtered.append(scored)

        # ─── Stage 3: Scoring / Ranking ───
        variant = self.ab_test.get_variant("ranking_model_v2", user_id)

        if variant == "new_ranker":
            # Experimental ranker: boost by recency and diversity
            for item in filtered:
                item_obj = self.items.get(item.item_id)
                if item_obj:
                    recency_boost = 1.0 + (item_obj.popularity_score * 0.1)
                    item.score *= recency_boost
        else:
            # Control: use raw scores
            pass

        filtered.sort(key=lambda x: x.score, reverse=True)

        # ─── Stage 4: Post-Processing (Diversity) ───
        final = self.diversity.rerank(
            filtered,
            self.item_categories,
            diversity_weight=0.3,
            n=request.num_items,
        )

        elapsed_ms = (time.time() - start_time) * 1000

        print(f"\n  📋 Recommendation for user={user_id} "
              f"(variant={variant})")
        print(f"     Candidates: {len(candidates)} → "
              f"Filtered: {len(filtered)} → "
              f"Final: {len(final)}")
        print(f"     Latency: {elapsed_ms:.1f}ms")

        return final


# ══════════════════════════════════════════════
# DEMO
# ══════════════════════════════════════════════

def demo_recommendation_system():
    """End-to-end demonstration of the recommendation system."""

    print("=" * 70)
    print("    RECOMMENDATION SYSTEM DEMO")
    print("=" * 70)

    # ─── Generate Sample Data ───
    random.seed(42)
    np.random.seed(42)

    categories = ["Action", "Comedy", "Drama", "Sci-Fi", "Horror",
                   "Romance", "Thriller", "Documentary"]
    tags_pool = [
        "suspenseful", "funny", "dark", "uplifting", "classic",
        "indie", "blockbuster", "award-winning", "family",
        "violent", "romantic", "thought-provoking", "visually-stunning"
    ]

    # Create items (movies)
    items = []
    for i in range(200):
        category = random.choice(categories)
        item = Item(
            item_id=f"movie_{i}",
            title=f"{category} Movie {i}",
            category=category,
            tags=random.sample(tags_pool, k=random.randint(2, 5)),
            features={
                "avg_rating": round(random.uniform(2.0, 5.0), 1),
                "year": random.randint(2010, 2024),
            },
            popularity_score=random.expovariate(0.3),
            created_at=time.time() - random.randint(0, 365 * 86400),
        )
        items.append(item)

    # Create users with preference profiles
    n_users = 50
    users = [User(user_id=f"user_{i}") for i in range(n_users)]

    # Generate interactions (with realistic patterns)
    interactions = []
    for user in users:
        # Each user has 1-2 preferred genres
        preferred = random.sample(categories, k=random.randint(1, 2))
        n_interactions = random.randint(5, 30)

        for _ in range(n_interactions):
            # 70% chance of interacting with preferred genre
            if random.random() < 0.7:
                genre_items = [it for it in items if it.category in preferred]
            else:
                genre_items = items

            if not genre_items:
                continue

            item = random.choice(genre_items)
            inter_type = random.choices(
                ["view", "click", "rating", "purchase"],
                weights=[0.4, 0.3, 0.2, 0.1]
            )[0]

            value = 1.0
            if inter_type == "rating":
                # Higher ratings for preferred genres
                if item.category in preferred:
                    value = random.uniform(3.5, 5.0)
                else:
                    value = random.uniform(1.0, 4.0)

            interactions.append(Interaction(
                user_id=user.user_id,
                item_id=item.item_id,
                interaction_type=inter_type,
                value=value,
                timestamp=time.time() - random.randint(0, 30 * 86400),
            ))

    print(f"\n📊 Generated {len(items)} items, {len(users)} users, "
          f"{len(interactions)} interactions\n")

    # ─── Train & Serve ───
    engine = RecommendationEngine()
    engine.train(items, interactions)

    # ─── Get Recommendations ───
    print("\n" + "=" * 60)
    print("RECOMMENDATIONS:")
    print("=" * 60)

    for test_user in ["user_0", "user_10", "user_25"]:
        request = RecommendationRequest(
            user_id=test_user,
            num_items=10,
            context={"device": "mobile", "time_of_day": "evening"},
        )

        recs = engine.recommend(request)

        print(f"\n  🎬 Top recommendations for {test_user}:")
        print(f"     User's history: "
              f"{list(engine.user_history.get(test_user, set()))[:5]}")
        for i, rec in enumerate(recs[:8], 1):
            item = engine.items.get(rec.item_id)
            print(f"     {i}. {item.title} [{item.category}] "
                  f"score={rec.score:.3f} "
                  f"via={rec.source}")

    # ─── Similar Items Demo ───
    print(f"\n{'=' * 60}")
    print("SIMILAR ITEMS:")
    print("=" * 60)

    test_item = "movie_0"
    similar = engine.cf_model.similar_items(test_item, n=5)
    item_obj = engine.items[test_item]
    print(f"\n  Items similar to '{item_obj.title}' [{item_obj.category}]:")
    for s in similar:
        sim_item = engine.items.get(s.item_id)
        print(f"    - {sim_item.title} [{sim_item.category}] "
              f"similarity={s.score:.3f}")

    # ─── Co-occurrence Demo ───
    print(f"\n{'=' * 60}")
    print("FREQUENTLY WATCHED TOGETHER:")
    print("=" * 60)

    for test_item in ["movie_1", "movie_5"]:
        cooc = engine.cooccurrence.recommend(test_item, n=3)
        if cooc:
            item_obj = engine.items[test_item]
            print(f"\n  Users who watched '{item_obj.title}' also watched:")
            for c in cooc:
                c_item = engine.items.get(c.item_id)
                if c_item:
                    print(f"    - {c_item.title} (lift={c.score:.2f})")

    # ─── Trending Demo ───
    print(f"\n{'=' * 60}")
    print("TRENDING NOW:")
    print("=" * 60)

    trending = engine.popularity.get_trending(n=5)
    for i, t in enumerate(trending, 1):
        item = engine.items.get(t.item_id)
        if item:
            print(f"  {i}. {item.title} [{item.category}] "
                  f"trend_score={t.score:.2f}")

    # ─── A/B Test Assignment ───
    print(f"\n{'=' * 60}")
    print("A/B TEST ASSIGNMENTS:")
    print("=" * 60)
    variant_counts = defaultdict(int)
    for i in range(100):
        variant = engine.ab_test.get_variant("ranking_model_v2", f"user_{i}")
        variant_counts[variant] += 1
    print(f"  Distribution across 100 users: {dict(variant_counts)}")


if __name__ == "__main__":
    demo_recommendation_system()
```

---

### Feature Store Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     FEATURE STORE                                │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  OFFLINE FEATURES (Batch - computed daily/hourly)        │  │
│  │                                                          │  │
│  │  User Features:                                          │  │
│  │  ├─ user_avg_rating: float (avg of all ratings)         │  │
│  │  ├─ user_genre_distribution: map<str, float>            │  │
│  │  ├─ user_activity_level: enum (low/med/high)            │  │
│  │  ├─ user_lifetime_value: float                          │  │
│  │  └─ user_embedding: float[128] (from ALS/DL)           │  │
│  │                                                          │  │
│  │  Item Features:                                          │  │
│  │  ├─ item_avg_rating: float                              │  │
│  │  ├─ item_num_ratings: int                               │  │
│  │  ├─ item_popularity_rank: int                           │  │
│  │  ├─ item_category_popularity: float                     │  │
│  │  └─ item_embedding: float[128]                          │  │
│  │                                                          │  │
│  │  Storage: Hive/S3 → synced to Redis                     │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  ONLINE FEATURES (Real-time - computed per request)      │  │
│  │                                                          │  │
│  │  ├─ user_last_5_clicks: list<item_id>                   │  │
│  │  ├─ user_session_duration: float (minutes)              │  │
│  │  ├─ user_clicks_last_hour: int                          │  │
│  │  ├─ item_clicks_last_hour: int (trending signal)        │  │
│  │  └─ user_current_context: map (device, time, location)  │  │
│  │                                                          │  │
│  │  Storage: Redis with TTL                                │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  CROSS FEATURES (Computed at serving time)               │  │
│  │                                                          │  │
│  │  ├─ user_item_genre_match: float                        │  │
│  │  ├─ user_item_price_preference: float                   │  │
│  │  ├─ user_item_brand_affinity: float                     │  │
│  │  └─ dot(user_embedding, item_embedding): float          │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

---

### Summary Comparison

```
┌────────────────────┬────────────────────┬──────────────────┬───────────────────┐
│                    │ Real-Time          │ Log              │ Recommendation    │
│                    │ Analytics          │ Aggregation      │ System            │
├────────────────────┼────────────────────┼──────────────────┼───────────────────┤
│ Data Volume        │ 1M events/sec      │ 500 GB/day       │ 100M users ×      │
│                    │                    │                  │ 10M items         │
├────────────────────┼────────────────────┼──────────────────┼───────────────────┤
│ Latency Target     │ < 5s freshness     │ < 1s search      │ < 100ms serving   │
│                    │ < 500ms query      │                  │                   │
├────────────────────┼────────────────────┼──────────────────┼───────────────────┤
│ Key Stores         │ Kafka + Flink +    │ Kafka + ES +     │ Feature Store +   │
│                    │ Redis + Druid      │ S3               │ ANN Index + Redis │
├────────────────────┼────────────────────┼──────────────────┼───────────────────┤
│ Processing Model   │ Stream (Flink)     │ Stream + Batch   │ Batch train +     │
│                    │                    │ (ETL)            │ Online serve      │
├────────────────────┼────────────────────┼──────────────────┼───────────────────┤
│ Key Algorithm      │ Window aggregation │ Inverted index   │ Matrix Factor.,   │
│                    │ HyperLogLog        │ Full-text search │ ANN, Co-occur.    │
├────────────────────┼────────────────────┼──────────────────┼───────────────────┤
│ Cold → Hot Data    │ S3 → Druid → Redis │ S3 → Warm ES →   │ S3 → Feature     │
│ Tiering            │                    │ Hot ES           │ Store → Cache     │
├────────────────────┼────────────────────┼──────────────────┼───────────────────┤
│ Key Challenges     │ Exactly-once,      │ Schema variety,  │ Cold start,       │
│                    │ Late data,         │ PII masking,     │ Scalable ANN,     │
│                    │ Backpressure       │ Retention mgmt   │ A/B testing       │
└────────────────────┴────────────────────┴──────────────────┴───────────────────┘
```



# Data-Intensive System Design (HLD): Systems 26–28

---

## 26. Design a Stock Trading Platform

---

### 1. Requirements

```
Functional:
 • Place orders (market, limit, stop-loss)
 • Real-time order matching (matching engine)
 • Stream live market data (price, volume, depth)
 • Portfolio & position management
 • Trade settlement & clearing
 • Historical data & charting

Non-Functional:
 • Ultra-low latency matching (< 1 ms per match)
 • High throughput (millions of orders/day)
 • Strong consistency for order/trade data
 • 99.999% availability during market hours
 • Regulatory audit trail (every event logged)
```

### 2. Scale Estimation

```
• 10M registered users, 500K DAU
• Peak: 50,000 orders/second
• ~5,000 tradable symbols
• Market data: ~1M price updates/second across all symbols
• Trade log: ~100M trades/day → ~50 GB/day raw
```

### 3. High-Level Architecture

```
┌─────────────┐     ┌──────────────┐     ┌──────────────────┐
│  Web/Mobile  │────▶│  API Gateway  │────▶│  Auth + Rate     │
│   Clients    │◀────│  (WebSocket)  │◀────│  Limiter         │
└─────────────┘     └──────┬───────┘     └──────────────────┘
                           │
              ┌────────────┼────────────────┐
              ▼            ▼                ▼
     ┌──────────────┐ ┌──────────┐  ┌───────────────┐
     │ Order Service │ │ Market   │  │ Portfolio     │
     │              │ │ Data Svc │  │ Service       │
     └──────┬───────┘ └────┬─────┘  └───────┬───────┘
            │              │                │
            ▼              │                │
     ┌──────────────┐      │                │
     │  Order Queue  │      │                │
     │  (Sequencer)  │      │                │
     └──────┬───────┘      │                │
            ▼              │                │
     ┌──────────────┐      │                │
     │  MATCHING    │──────┘                │
     │  ENGINE      │──────────────────────▶│
     │ (per symbol) │                       │
     └──────┬───────┘                       │
            │                               │
            ▼                               ▼
     ┌──────────────┐              ┌──────────────┐
     │ Trade Log /  │              │  Positions   │
     │ Event Store  │              │  Database    │
     │ (Kafka)      │              │  (PostgreSQL)│
     └──────┬───────┘              └──────────────┘
            │
     ┌──────┼──────────────┐
     ▼      ▼              ▼
┌────────┐ ┌───────────┐ ┌──────────────┐
│Clearing│ │ Risk      │ │ Analytics /  │
│& Settle│ │ Engine    │ │ Reporting    │
└────────┘ └───────────┘ └──────────────┘
```

### 4. Core Components Deep Dive

#### A. Order Sequencer + Matching Engine

```
The HEART of any exchange. One matching engine per symbol
guarantees total ordering within that symbol.

Order Book Structure (per symbol):
┌─────────────────────────────────────────────┐
│                ORDER BOOK: AAPL             │
│                                             │
│  BIDS (Buy)          │  ASKS (Sell)         │
│  Price   | Qty | Time│  Price  | Qty | Time │
│  ────────┼─────┼─────│  ───────┼─────┼───── │
│  150.10  | 500 | T1  │  150.15 | 300 | T2   │
│  150.05  | 200 | T3  │  150.20 | 100 | T4   │
│  150.00  | 800 | T5  │  150.25 | 400 | T6   │
│                      │                      │
│  Sorted DESC         │  Sorted ASC          │
└─────────────────────────────────────────────┘

Matching Rules:
 • Price-Time Priority (FIFO at each price level)
 • Market orders match at best available price
 • Limit orders rest in book if no match
```

#### B. Python: Matching Engine

```python
import heapq
import time
import uuid
from dataclasses import dataclass, field
from enum import Enum
from typing import Optional
from collections import defaultdict
import threading


class Side(Enum):
    BUY = "BUY"
    SELL = "SELL"


class OrderType(Enum):
    MARKET = "MARKET"
    LIMIT = "LIMIT"
    STOP_LOSS = "STOP_LOSS"


class OrderStatus(Enum):
    NEW = "NEW"
    PARTIALLY_FILLED = "PARTIALLY_FILLED"
    FILLED = "FILLED"
    CANCELLED = "CANCELLED"


@dataclass
class Order:
    order_id: str
    user_id: str
    symbol: str
    side: Side
    order_type: OrderType
    quantity: int
    price: Optional[float]  # None for market orders
    timestamp: float = field(default_factory=time.time)
    filled_quantity: int = 0
    status: OrderStatus = OrderStatus.NEW

    @property
    def remaining(self) -> int:
        return self.quantity - self.filled_quantity


@dataclass
class Trade:
    trade_id: str
    symbol: str
    buyer_order_id: str
    seller_order_id: str
    buyer_id: str
    seller_id: str
    price: float
    quantity: int
    timestamp: float = field(default_factory=time.time)


class OrderBookSide:
    """
    Min-heap for asks (lowest price first)
    Max-heap for bids (highest price first, negate price)
    Tie-break on timestamp (earliest first)
    """

    def __init__(self, side: Side):
        self.side = side
        self.heap: list = []
        self.order_map: dict[str, Order] = {}

    def add(self, order: Order):
        if self.side == Side.BUY:
            # Max-heap via negation
            priority = (-order.price, order.timestamp, order.order_id)
        else:
            priority = (order.price, order.timestamp, order.order_id)

        heapq.heappush(self.heap, priority)
        self.order_map[order.order_id] = order

    def peek(self) -> Optional[Order]:
        while self.heap:
            _, _, order_id = self.heap[0]
            if order_id in self.order_map:
                order = self.order_map[order_id]
                if order.remaining > 0 and order.status != OrderStatus.CANCELLED:
                    return order
            heapq.heappop(self.heap)  # lazy deletion
        return None

    def pop(self) -> Optional[Order]:
        order = self.peek()
        if order:
            heapq.heappop(self.heap)
        return order

    def remove(self, order_id: str) -> Optional[Order]:
        if order_id in self.order_map:
            order = self.order_map.pop(order_id)
            order.status = OrderStatus.CANCELLED
            return order
        return None

    @property
    def best_price(self) -> Optional[float]:
        top = self.peek()
        return top.price if top else None

    def depth(self, levels: int = 5) -> list[tuple[float, int]]:
        """Return price levels with aggregated quantities."""
        price_qty: dict[float, int] = defaultdict(int)
        for oid, order in self.order_map.items():
            if order.remaining > 0 and order.status != OrderStatus.CANCELLED:
                price_qty[order.price] += order.remaining

        sorted_prices = sorted(
            price_qty.items(),
            reverse=(self.side == Side.BUY)
        )
        return sorted_prices[:levels]


class MatchingEngine:
    """Single-symbol matching engine."""

    def __init__(self, symbol: str):
        self.symbol = symbol
        self.bids = OrderBookSide(Side.BUY)
        self.asks = OrderBookSide(Side.SELL)
        self.trades: list[Trade] = []
        self.lock = threading.Lock()
        self.trade_callbacks: list = []
        self.last_trade_price: Optional[float] = None

    def on_trade(self, callback):
        self.trade_callbacks.append(callback)

    def _emit_trade(self, trade: Trade):
        for cb in self.trade_callbacks:
            cb(trade)

    def submit_order(self, order: Order) -> list[Trade]:
        with self.lock:
            if order.order_type == OrderType.MARKET:
                return self._match_market_order(order)
            elif order.order_type == OrderType.LIMIT:
                return self._match_limit_order(order)
            return []

    def _match_market_order(self, order: Order) -> list[Trade]:
        trades = []
        opposite = self.asks if order.side == Side.BUY else self.bids

        while order.remaining > 0:
            best = opposite.peek()
            if best is None:
                break  # No liquidity
            trade = self._execute(order, best)
            trades.append(trade)

            if best.remaining == 0:
                best.status = OrderStatus.FILLED
                opposite.order_map.pop(best.order_id, None)

        if order.remaining == 0:
            order.status = OrderStatus.FILLED
        else:
            # Unfilled market order remainder is cancelled
            order.status = OrderStatus.CANCELLED

        return trades

    def _match_limit_order(self, order: Order) -> list[Trade]:
        trades = []
        opposite = self.asks if order.side == Side.BUY else self.bids
        same_side = self.bids if order.side == Side.BUY else self.asks

        while order.remaining > 0:
            best = opposite.peek()
            if best is None:
                break

            # Check price cross
            if order.side == Side.BUY and order.price < best.price:
                break
            if order.side == Side.SELL and order.price > best.price:
                break

            trade = self._execute(order, best)
            trades.append(trade)

            if best.remaining == 0:
                best.status = OrderStatus.FILLED
                opposite.order_map.pop(best.order_id, None)

        # Rest in book if not fully filled
        if order.remaining > 0:
            order.status = (
                OrderStatus.PARTIALLY_FILLED
                if order.filled_quantity > 0
                else OrderStatus.NEW
            )
            same_side.add(order)
        else:
            order.status = OrderStatus.FILLED

        return trades

    def _execute(self, aggressor: Order, resting: Order) -> Trade:
        fill_qty = min(aggressor.remaining, resting.remaining)
        fill_price = resting.price  # Price-time priority

        aggressor.filled_quantity += fill_qty
        resting.filled_quantity += fill_qty

        buyer = aggressor if aggressor.side == Side.BUY else resting
        seller = resting if aggressor.side == Side.BUY else aggressor

        trade = Trade(
            trade_id=str(uuid.uuid4()),
            symbol=self.symbol,
            buyer_order_id=buyer.order_id,
            seller_order_id=seller.order_id,
            buyer_id=buyer.user_id,
            seller_id=seller.user_id,
            price=fill_price,
            quantity=fill_qty,
        )

        self.trades.append(trade)
        self.last_trade_price = fill_price
        self._emit_trade(trade)
        return trade

    def cancel_order(self, order_id: str) -> bool:
        with self.lock:
            removed = self.bids.remove(order_id)
            if removed:
                return True
            removed = self.asks.remove(order_id)
            return removed is not None

    def get_order_book_snapshot(self, levels: int = 5) -> dict:
        with self.lock:
            return {
                "symbol": self.symbol,
                "bids": self.bids.depth(levels),
                "asks": self.asks.depth(levels),
                "last_price": self.last_trade_price,
                "timestamp": time.time(),
            }


# ─────────────────── Exchange (manages all symbols) ───────────────────

class Exchange:
    def __init__(self):
        self.engines: dict[str, MatchingEngine] = {}
        self.lock = threading.Lock()

    def get_engine(self, symbol: str) -> MatchingEngine:
        if symbol not in self.engines:
            with self.lock:
                if symbol not in self.engines:
                    self.engines[symbol] = MatchingEngine(symbol)
        return self.engines[symbol]

    def place_order(self, order: Order) -> list[Trade]:
        engine = self.get_engine(order.symbol)
        return engine.submit_order(order)


# ─────────────────── Demo ───────────────────

if __name__ == "__main__":
    exchange = Exchange()

    def trade_logger(trade: Trade):
        print(f"  ★ TRADE: {trade.symbol} {trade.quantity}@{trade.price} "
              f"buyer={trade.buyer_id} seller={trade.seller_id}")

    engine = exchange.get_engine("AAPL")
    engine.on_trade(trade_logger)

    # Sellers place limit asks
    orders = [
        Order(str(uuid.uuid4()), "seller1", "AAPL", Side.SELL, OrderType.LIMIT, 100, 150.10),
        Order(str(uuid.uuid4()), "seller2", "AAPL", Side.SELL, OrderType.LIMIT, 200, 150.20),
        Order(str(uuid.uuid4()), "seller3", "AAPL", Side.SELL, OrderType.LIMIT, 50,  150.05),
    ]
    for o in orders:
        exchange.place_order(o)
        print(f"Placed SELL limit: {o.quantity}@{o.price}")

    print("\n--- Buyer places market order for 120 shares ---")
    buy_order = Order(str(uuid.uuid4()), "buyer1", "AAPL", Side.BUY, OrderType.MARKET, 120, None)
    trades = exchange.place_order(buy_order)
    print(f"Trades executed: {len(trades)}")

    print("\n--- Order Book Snapshot ---")
    snap = engine.get_order_book_snapshot()
    print(f"  Bids: {snap['bids']}")
    print(f"  Asks: {snap['asks']}")
    print(f"  Last: {snap['last_price']}")

    print("\n--- Buyer places limit bid ---")
    bid = Order(str(uuid.uuid4()), "buyer2", "AAPL", Side.BUY, OrderType.LIMIT, 300, 150.15)
    trades = exchange.place_order(bid)
    print(f"Trades executed: {len(trades)}")

    snap = engine.get_order_book_snapshot()
    print(f"  Bids: {snap['bids']}")
    print(f"  Asks: {snap['asks']}")
```

#### C. Market Data Streaming

```
┌─────────────┐    ┌──────────────┐    ┌──────────────────┐
│  Matching    │───▶│  Kafka Topic │───▶│  Market Data     │
│  Engine      │    │  (trades)    │    │  Aggregator      │
└─────────────┘    └──────────────┘    └──────┬───────────┘
                                              │
                                              ▼
                                       ┌──────────────┐
                                       │  OHLCV       │
                                       │  Candles     │
                                       │  (1s,1m,5m)  │
                                       └──────┬───────┘
                                              │
                                    ┌─────────┼──────────┐
                                    ▼         ▼          ▼
                              ┌──────────┐ ┌──────┐ ┌──────────┐
                              │WebSocket │ │Redis │ │TimescaleDB│
                              │Broadcast │ │Cache │ │Historical │
                              └──────────┘ └──────┘ └──────────┘
```

```python
import asyncio
import json
import time
from collections import defaultdict
from dataclasses import dataclass, field


@dataclass
class OHLCV:
    """Open-High-Low-Close-Volume candle."""
    symbol: str
    interval: str  # "1s", "1m", "5m"
    timestamp: float  # bucket start
    open: float = 0.0
    high: float = float('-inf')
    low: float = float('inf')
    close: float = 0.0
    volume: int = 0
    trade_count: int = 0

    def update(self, price: float, quantity: int):
        if self.trade_count == 0:
            self.open = price
        self.high = max(self.high, price)
        self.low = min(self.low, price)
        self.close = price
        self.volume += quantity
        self.trade_count += 1

    def to_dict(self) -> dict:
        return {
            "symbol": self.symbol,
            "interval": self.interval,
            "timestamp": self.timestamp,
            "open": self.open,
            "high": self.high,
            "low": self.low,
            "close": self.close,
            "volume": self.volume,
            "trades": self.trade_count,
        }


class MarketDataAggregator:
    """Aggregates trades into OHLCV candles at multiple intervals."""

    INTERVALS = {
        "1s": 1,
        "1m": 60,
        "5m": 300,
        "1h": 3600,
    }

    def __init__(self):
        # {(symbol, interval): OHLCV}
        self.candles: dict[tuple[str, str], OHLCV] = {}
        self.completed_candles: list[OHLCV] = []
        self.subscribers: dict[str, list] = defaultdict(list)

    def _bucket_start(self, ts: float, interval_secs: int) -> float:
        return (int(ts) // interval_secs) * interval_secs

    def on_trade(self, symbol: str, price: float, quantity: int,
                 timestamp: float = None):
        ts = timestamp or time.time()

        for interval_name, interval_secs in self.INTERVALS.items():
            bucket = self._bucket_start(ts, interval_secs)
            key = (symbol, interval_name)

            if key in self.candles and self.candles[key].timestamp != bucket:
                # Candle completed
                completed = self.candles.pop(key)
                self.completed_candles.append(completed)
                self._notify(completed)

            if key not in self.candles:
                self.candles[key] = OHLCV(
                    symbol=symbol,
                    interval=interval_name,
                    timestamp=bucket
                )

            self.candles[key].update(price, quantity)

    def subscribe(self, symbol: str, callback):
        self.subscribers[symbol].append(callback)

    def _notify(self, candle: OHLCV):
        for cb in self.subscribers.get(candle.symbol, []):
            cb(candle)

    def get_current(self, symbol: str, interval: str) -> dict:
        key = (symbol, interval)
        if key in self.candles:
            return self.candles[key].to_dict()
        return {}


# Demo
if __name__ == "__main__":
    agg = MarketDataAggregator()

    def on_candle(candle: OHLCV):
        print(f"  📊 Candle complete: {candle.to_dict()}")

    agg.subscribe("AAPL", on_candle)

    # Simulate trades
    base_time = 1700000000.0
    trades = [
        (base_time + 0.1, 150.10, 100),
        (base_time + 0.5, 150.15, 200),
        (base_time + 0.9, 150.05, 50),
        (base_time + 1.2, 150.20, 300),  # new 1s candle
        (base_time + 1.8, 150.25, 100),
    ]

    for ts, price, qty in trades:
        agg.on_trade("AAPL", price, qty, ts)

    print("Current 1s candle:", agg.get_current("AAPL", "1s"))
```

#### D. Risk Engine

```python
from dataclasses import dataclass
from enum import Enum


class RiskAction(Enum):
    ALLOW = "ALLOW"
    REJECT = "REJECT"
    MARGIN_CALL = "MARGIN_CALL"


@dataclass
class Position:
    symbol: str
    quantity: int  # positive=long, negative=short
    avg_cost: float
    current_price: float

    @property
    def market_value(self) -> float:
        return self.quantity * self.current_price

    @property
    def unrealized_pnl(self) -> float:
        return self.quantity * (self.current_price - self.avg_cost)


@dataclass
class Account:
    user_id: str
    cash_balance: float
    positions: dict[str, Position]
    margin_ratio: float = 2.0  # 2:1 leverage

    @property
    def portfolio_value(self) -> float:
        pos_value = sum(p.market_value for p in self.positions.values())
        return self.cash_balance + pos_value

    @property
    def buying_power(self) -> float:
        return self.cash_balance * self.margin_ratio

    @property
    def margin_used(self) -> float:
        return sum(
            abs(p.market_value) for p in self.positions.values()
        )

    @property
    def margin_available(self) -> float:
        return self.buying_power - self.margin_used


class RiskEngine:
    """Pre-trade and post-trade risk checks."""

    # Per-order limits
    MAX_ORDER_VALUE = 1_000_000
    MAX_ORDER_QUANTITY = 100_000
    MAX_POSITION_CONCENTRATION = 0.25  # 25% of portfolio in one symbol
    MARGIN_CALL_THRESHOLD = 0.3  # 30% equity ratio

    def __init__(self):
        self.accounts: dict[str, Account] = {}
        self.daily_loss_limits: dict[str, float] = {}
        self.daily_losses: dict[str, float] = {}

    def register_account(self, account: Account):
        self.accounts[account.user_id] = account
        self.daily_loss_limits[account.user_id] = account.cash_balance * 0.1
        self.daily_losses[account.user_id] = 0.0

    def pre_trade_check(self, user_id: str, symbol: str,
                        side: str, quantity: int,
                        price: float) -> tuple[RiskAction, str]:
        account = self.accounts.get(user_id)
        if not account:
            return RiskAction.REJECT, "Account not found"

        order_value = quantity * price

        # Check 1: Order size limits
        if order_value > self.MAX_ORDER_VALUE:
            return RiskAction.REJECT, f"Order value {order_value} exceeds max {self.MAX_ORDER_VALUE}"

        if quantity > self.MAX_ORDER_QUANTITY:
            return RiskAction.REJECT, f"Quantity {quantity} exceeds max {self.MAX_ORDER_QUANTITY}"

        # Check 2: Buying power (for buys)
        if side == "BUY":
            if order_value > account.margin_available:
                return RiskAction.REJECT, (
                    f"Insufficient margin. Need {order_value}, "
                    f"available {account.margin_available}"
                )

        # Check 3: Position concentration
        if account.portfolio_value > 0:
            current_pos_value = 0
            if symbol in account.positions:
                current_pos_value = abs(account.positions[symbol].market_value)
            new_pos_value = current_pos_value + order_value
            concentration = new_pos_value / account.portfolio_value

            if concentration > self.MAX_POSITION_CONCENTRATION:
                return RiskAction.REJECT, (
                    f"Concentration {concentration:.1%} exceeds "
                    f"max {self.MAX_POSITION_CONCENTRATION:.0%}"
                )

        # Check 4: Daily loss limit
        daily_loss = self.daily_losses.get(user_id, 0)
        limit = self.daily_loss_limits.get(user_id, 0)
        if daily_loss >= limit:
            return RiskAction.REJECT, "Daily loss limit reached"

        return RiskAction.ALLOW, "All checks passed"

    def post_trade_check(self, user_id: str) -> RiskAction:
        """Check margin after trade execution."""
        account = self.accounts.get(user_id)
        if not account:
            return RiskAction.ALLOW

        if account.portfolio_value <= 0:
            return RiskAction.MARGIN_CALL

        equity_ratio = account.cash_balance / account.margin_used \
            if account.margin_used > 0 else float('inf')

        if equity_ratio < self.MARGIN_CALL_THRESHOLD:
            return RiskAction.MARGIN_CALL

        return RiskAction.ALLOW


# Demo
if __name__ == "__main__":
    risk = RiskEngine()

    account = Account(
        user_id="user1",
        cash_balance=100_000,
        positions={
            "AAPL": Position("AAPL", 100, 145.0, 150.0),
        }
    )
    risk.register_account(account)

    print(f"Portfolio value: ${account.portfolio_value:,.2f}")
    print(f"Buying power: ${account.buying_power:,.2f}")

    action, reason = risk.pre_trade_check("user1", "GOOG", "BUY", 50, 140.0)
    print(f"\nBuy 50 GOOG@140: {action.value} - {reason}")

    action, reason = risk.pre_trade_check("user1", "AAPL", "BUY", 5000, 150.0)
    print(f"Buy 5000 AAPL@150: {action.value} - {reason}")
```

#### E. Data Storage Design

```
┌─────────────────────────────────────────────────────────┐
│                  DATA STORAGE LAYER                     │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  HOT PATH (Real-time):                                 │
│  ┌──────────┐  ┌──────────┐  ┌──────────────┐        │
│  │  Redis    │  │  Kafka   │  │  In-Memory   │        │
│  │  Cluster  │  │  Streams │  │  Order Books │        │
│  │          │  │          │  │              │        │
│  │• L1 quote│  │• Trade   │  │• Active      │        │
│  │• Sessions│  │  events  │  │  orders only │        │
│  │• Tickers │  │• Order   │  │              │        │
│  └──────────┘  │  events  │  └──────────────┘        │
│                └──────────┘                            │
│                                                         │
│  WARM PATH (Operational):                              │
│  ┌──────────────┐  ┌─────────────────┐                │
│  │  PostgreSQL   │  │  TimescaleDB    │                │
│  │  (Partitioned)│  │                 │                │
│  │              │  │• OHLCV candles  │                │
│  │• Orders      │  │• Tick data      │                │
│  │• Trades      │  │• Market depth   │                │
│  │• Accounts    │  │  history        │                │
│  │• Positions   │  │                 │                │
│  └──────────────┘  └─────────────────┘                │
│                                                         │
│  COLD PATH (Analytics/Compliance):                     │
│  ┌──────────────┐  ┌─────────────────┐                │
│  │  S3 / HDFS   │  │  ClickHouse     │                │
│  │  (Parquet)   │  │  (Analytics)    │                │
│  │              │  │                 │                │
│  │• Raw events  │  │• Trade reports  │                │
│  │• Audit trail │  │• P&L analysis   │                │
│  └──────────────┘  └─────────────────┘                │
└─────────────────────────────────────────────────────────┘
```

```sql
-- Core Tables
CREATE TABLE orders (
    order_id        UUID PRIMARY KEY,
    user_id         UUID NOT NULL,
    symbol          VARCHAR(10) NOT NULL,
    side            VARCHAR(4) NOT NULL,
    order_type      VARCHAR(10) NOT NULL,
    quantity        INT NOT NULL,
    price           DECIMAL(12,4),
    filled_quantity INT DEFAULT 0,
    status          VARCHAR(20) NOT NULL,
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
) PARTITION BY RANGE (created_at);

CREATE TABLE trades (
    trade_id         UUID PRIMARY KEY,
    symbol           VARCHAR(10) NOT NULL,
    buyer_order_id   UUID REFERENCES orders(order_id),
    seller_order_id  UUID REFERENCES orders(order_id),
    price            DECIMAL(12,4) NOT NULL,
    quantity         INT NOT NULL,
    executed_at      TIMESTAMPTZ DEFAULT NOW()
) PARTITION BY RANGE (executed_at);

-- TimescaleDB hypertable for market data
CREATE TABLE market_data (
    time       TIMESTAMPTZ NOT NULL,
    symbol     VARCHAR(10) NOT NULL,
    price      DECIMAL(12,4),
    volume     BIGINT,
    bid        DECIMAL(12,4),
    ask        DECIMAL(12,4)
);
SELECT create_hypertable('market_data', 'time');
```

### 5. Full Architecture Diagram

```
                        ┌─────────────────────────┐
                        │      CLIENTS            │
                        │  Web │ Mobile │ FIX API  │
                        └──────────┬──────────────┘
                                   │
                        ┌──────────▼──────────────┐
                        │     LOAD BALANCER        │
                        │     (L4/L7, sticky)      │
                        └──────────┬──────────────┘
                                   │
                  ┌────────────────┼────────────────┐
                  ▼                ▼                ▼
          ┌──────────────┐ ┌──────────────┐ ┌──────────────┐
          │  REST API    │ │  WebSocket   │ │  FIX Gateway │
          │  Gateway     │ │  Gateway     │ │              │
          └──────┬───────┘ └──────┬───────┘ └──────┬───────┘
                 │                │                │
                 └────────────────┼────────────────┘
                                  │
              ┌───────────────────┼───────────────────┐
              ▼                   ▼                   ▼
     ┌──────────────┐   ┌──────────────┐    ┌──────────────┐
     │ Order Service │   │ Market Data  │    │  Account     │
     │              │   │ Service      │    │  Service     │
     └──────┬───────┘   └──────────────┘    └──────────────┘
            │                   ▲
     ┌──────▼───────┐          │
     │ Risk Engine  │          │
     └──────┬───────┘          │
            │                  │
     ┌──────▼───────┐         │
     │ Sequencer /  │         │
     │ Order Queue  │─────────┘
     │ (Kafka)      │
     └──────┬───────┘
            │
     ┌──────▼───────────────────────────────┐
     │         MATCHING ENGINE CLUSTER       │
     │                                       │
     │  ┌────────┐ ┌────────┐ ┌────────┐   │
     │  │  AAPL  │ │  GOOG  │ │  MSFT  │   │
     │  │ Engine │ │ Engine │ │ Engine │   │
     │  └───┬────┘ └───┬────┘ └───┬────┘   │
     │      └──────────┼──────────┘         │
     └─────────────────┼───────────────────┘
                       │
                ┌──────▼──────┐
                │  Event Bus  │
                │  (Kafka)    │
                └──────┬──────┘
                       │
          ┌────────────┼────────────┐
          ▼            ▼            ▼
   ┌───────────┐ ┌──────────┐ ┌──────────┐
   │ Clearing  │ │ Position │ │ Market   │
   │ & Settle  │ │ Updater  │ │ Data Pub │
   └───────────┘ └──────────┘ └──────────┘
```

---

## 27. Design an Ad Click Tracking System

---

### 1. Requirements

```
Functional:
 • Track ad impressions and clicks
 • Attribute clicks to campaigns/advertisers
 • Real-time click-through rate (CTR) dashboards
 • Click fraud detection
 • Billing based on CPC/CPM
 • Conversion tracking (click → purchase)

Non-Functional:
 • Handle 100K+ clicks/second at peak
 • < 200ms redirect latency for click tracking
 • Near real-time aggregation (< 1 minute)
 • Exactly-once counting for billing
 • 99.99% availability
 • 7-year retention for compliance
```

### 2. Scale Estimation

```
• 10B ad impressions/day
• 200M clicks/day (~2,300 clicks/sec avg, 10K peak)
• Each click event: ~500 bytes
• Raw click data: 200M × 500B = 100 GB/day
• Impressions: 10B × 300B = 3 TB/day
• Aggregated data: ~1 GB/day
```

### 3. High-Level Architecture

```
┌──────────┐    ┌───────────────────┐    ┌──────────────────┐
│  User    │    │   Ad Serving      │    │  Click Tracker   │
│ Browser  │───▶│   (returns ad +   │    │  (redirect svc)  │
│          │    │    tracking pixel) │    │                  │
└──────────┘    └───────────────────┘    └────────┬─────────┘
     │                                            │
     │  ①  Page loads, impression pixel fires      │
     │  ②  User clicks ad link                     │
     │──────────────────────────────────────────▶  │
     │  ③  302 redirect to advertiser              │
     │◀──────────────────────────────────────────  │
     │                                            │
     │                                     ┌──────▼──────────┐
     │                                     │  Kafka          │
     │                                     │  (click events) │
     │                                     └──────┬──────────┘
     │                                            │
     │                          ┌─────────────────┼──────────────┐
     │                          ▼                 ▼              ▼
     │                   ┌────────────┐   ┌────────────┐  ┌──────────┐
     │                   │  Flink     │   │  Fraud     │  │  Raw     │
     │                   │  Streaming │   │  Detector  │  │  Storage │
     │                   │  Aggregator│   │            │  │  (S3)    │
     │                   └─────┬──────┘   └─────┬──────┘  └──────────┘
     │                         │                │
     │                         ▼                ▼
     │                   ┌────────────┐   ┌────────────┐
     │                   │ ClickHouse │   │ Fraud DB   │
     │                   │ (OLAP)     │   │ (blocked   │
     │                   │            │   │  IPs, etc) │
     │                   └─────┬──────┘   └────────────┘
     │                         │
     │                         ▼
     │                   ┌────────────┐
     │                   │ Dashboard  │
     │                   │ & Billing  │
     │                   │ Service    │
     │                   └────────────┘
```

### 4. Core Components

#### A. Click Tracking Service

```python
import time
import uuid
import hashlib
import json
from dataclasses import dataclass, field, asdict
from typing import Optional
from urllib.parse import urlencode, parse_qs


@dataclass
class ClickEvent:
    event_id: str
    event_type: str  # "impression" | "click" | "conversion"
    ad_id: str
    campaign_id: str
    advertiser_id: str
    publisher_id: str
    user_id: Optional[str]  # hashed/anonymous
    ip_address: str
    user_agent: str
    referrer: str
    country: str
    device_type: str  # "mobile" | "desktop" | "tablet"
    timestamp: float
    landing_url: str = ""
    click_cost: float = 0.0

    def to_dict(self) -> dict:
        return asdict(self)

    def to_json(self) -> str:
        return json.dumps(self.to_dict())


class ClickTracker:
    """
    Handles the click redirect and event generation.
    Designed for ultra-low latency:
      1. Log to Kafka asynchronously
      2. Return 302 redirect immediately
    """

    def __init__(self, kafka_producer=None):
        self.kafka_producer = kafka_producer
        self.ad_registry: dict[str, dict] = {}  # ad_id -> metadata
        self._dedup_cache: set = set()  # Redis in production

    def register_ad(self, ad_id: str, metadata: dict):
        self.ad_registry[ad_id] = metadata

    def generate_click_url(self, ad_id: str, publisher_id: str,
                           user_id: str = None) -> str:
        """Generate a trackable click URL."""
        params = {
            "ad_id": ad_id,
            "pub_id": publisher_id,
            "uid": user_id or "",
            "ts": str(int(time.time())),
        }
        # Add HMAC signature to prevent URL tampering
        sig_data = f"{ad_id}:{publisher_id}:{params['ts']}:SECRET_KEY"
        params["sig"] = hashlib.sha256(sig_data.encode()).hexdigest()[:16]

        return f"https://click.adplatform.com/track?{urlencode(params)}"

    def generate_impression_pixel(self, ad_id: str,
                                   publisher_id: str) -> str:
        """Generate a 1x1 tracking pixel URL."""
        params = {
            "ad_id": ad_id,
            "pub_id": publisher_id,
            "type": "impression",
            "ts": str(int(time.time())),
        }
        return f'<img src="https://track.adplatform.com/pixel?{urlencode(params)}" width="1" height="1" />'

    def handle_click(self, ad_id: str, publisher_id: str,
                     ip: str, user_agent: str,
                     referrer: str, user_id: str = None) -> tuple[str, ClickEvent]:
        """
        Process a click:
          1. Create click event
          2. Async send to Kafka
          3. Return redirect URL

        Returns (redirect_url, click_event)
        """
        ad_meta = self.ad_registry.get(ad_id, {})

        event = ClickEvent(
            event_id=str(uuid.uuid4()),
            event_type="click",
            ad_id=ad_id,
            campaign_id=ad_meta.get("campaign_id", ""),
            advertiser_id=ad_meta.get("advertiser_id", ""),
            publisher_id=publisher_id,
            user_id=self._hash_user(user_id, ip, user_agent),
            ip_address=ip,
            user_agent=user_agent,
            referrer=referrer,
            country=self._geo_lookup(ip),
            device_type=self._detect_device(user_agent),
            timestamp=time.time(),
            landing_url=ad_meta.get("landing_url", ""),
            click_cost=ad_meta.get("cpc", 0.0),
        )

        # Deduplication check (e.g., double-click within 10s)
        dedup_key = f"{event.user_id}:{ad_id}:{int(event.timestamp) // 10}"
        if dedup_key in self._dedup_cache:
            event.click_cost = 0.0  # Don't charge for dupes

        self._dedup_cache.add(dedup_key)

        # Async publish to Kafka
        self._publish_event(event)

        return event.landing_url, event

    def handle_impression(self, ad_id: str, publisher_id: str,
                          ip: str, user_agent: str) -> ClickEvent:
        ad_meta = self.ad_registry.get(ad_id, {})

        event = ClickEvent(
            event_id=str(uuid.uuid4()),
            event_type="impression",
            ad_id=ad_id,
            campaign_id=ad_meta.get("campaign_id", ""),
            advertiser_id=ad_meta.get("advertiser_id", ""),
            publisher_id=publisher_id,
            user_id=self._hash_user(None, ip, user_agent),
            ip_address=ip,
            user_agent=user_agent,
            referrer="",
            country=self._geo_lookup(ip),
            device_type=self._detect_device(user_agent),
            timestamp=time.time(),
        )
        self._publish_event(event)
        return event

    def _publish_event(self, event: ClickEvent):
        """In production: Kafka producer.send()"""
        topic = f"ad-events-{event.event_type}"
        print(f"  → Kafka [{topic}]: {event.event_id} "
              f"{event.event_type} ad={event.ad_id}")

    def _hash_user(self, user_id, ip, ua) -> str:
        raw = f"{user_id or ''}:{ip}:{ua}"
        return hashlib.sha256(raw.encode()).hexdigest()[:16]

    def _geo_lookup(self, ip: str) -> str:
        # MaxMind GeoIP in production
        return "US"

    def _detect_device(self, user_agent: str) -> str:
        ua_lower = user_agent.lower()
        if "mobile" in ua_lower or "android" in ua_lower:
            return "mobile"
        elif "tablet" in ua_lower or "ipad" in ua_lower:
            return "tablet"
        return "desktop"


# Demo
if __name__ == "__main__":
    tracker = ClickTracker()

    tracker.register_ad("ad_001", {
        "campaign_id": "camp_100",
        "advertiser_id": "adv_50",
        "landing_url": "https://shop.example.com/product/123",
        "cpc": 0.50,
    })

    # Generate tracking URL
    click_url = tracker.generate_click_url("ad_001", "pub_200", "user_abc")
    print(f"Click URL: {click_url}\n")

    # Simulate click
    redirect_url, event = tracker.handle_click(
        ad_id="ad_001",
        publisher_id="pub_200",
        ip="203.0.113.45",
        user_agent="Mozilla/5.0 (iPhone; CPU iPhone OS)",
        referrer="https://news-site.com/article",
        user_id="user_abc",
    )
    print(f"\nRedirect → {redirect_url}")
    print(f"Click cost: ${event.click_cost}")
    print(f"Device: {event.device_type}")
```

#### B. Real-Time Aggregation (Flink-style in Python)

```python
import time
from collections import defaultdict
from dataclasses import dataclass, field
from typing import Optional
import threading


@dataclass
class ClickAggregation:
    """Aggregated metrics for a time window."""
    window_start: float
    window_end: float
    ad_id: str
    campaign_id: str
    impressions: int = 0
    clicks: int = 0
    unique_users: set = field(default_factory=set)
    total_cost: float = 0.0
    countries: dict = field(default_factory=lambda: defaultdict(int))
    devices: dict = field(default_factory=lambda: defaultdict(int))
    fraud_clicks: int = 0

    @property
    def ctr(self) -> float:
        return self.clicks / self.impressions if self.impressions > 0 else 0.0

    @property
    def unique_clicks(self) -> int:
        return len(self.unique_users)

    def to_dict(self) -> dict:
        return {
            "window_start": self.window_start,
            "window_end": self.window_end,
            "ad_id": self.ad_id,
            "campaign_id": self.campaign_id,
            "impressions": self.impressions,
            "clicks": self.clicks,
            "unique_clicks": self.unique_clicks,
            "ctr": round(self.ctr, 4),
            "total_cost": round(self.total_cost, 2),
            "countries": dict(self.countries),
            "devices": dict(self.devices),
            "fraud_clicks": self.fraud_clicks,
        }


class StreamingAggregator:
    """
    Tumbling window aggregation for click events.
    Mimics Apache Flink windowed aggregation.
    """

    def __init__(self, window_size_secs: int = 60):
        self.window_size = window_size_secs
        # Key: (window_start, ad_id) → ClickAggregation
        self.windows: dict[tuple, ClickAggregation] = {}
        self.completed: list[ClickAggregation] = []
        self.lock = threading.Lock()

    def _window_start(self, ts: float) -> float:
        return (int(ts) // self.window_size) * self.window_size

    def process_event(self, event: dict):
        ts = event.get("timestamp", time.time())
        ws = self._window_start(ts)
        ad_id = event["ad_id"]
        key = (ws, ad_id)

        with self.lock:
            # Flush old windows
            self._flush_old_windows(ts)

            if key not in self.windows:
                self.windows[key] = ClickAggregation(
                    window_start=ws,
                    window_end=ws + self.window_size,
                    ad_id=ad_id,
                    campaign_id=event.get("campaign_id", ""),
                )

            agg = self.windows[key]

            if event["event_type"] == "impression":
                agg.impressions += 1
            elif event["event_type"] == "click":
                agg.clicks += 1
                agg.total_cost += event.get("click_cost", 0)
                if event.get("user_id"):
                    agg.unique_users.add(event["user_id"])
                agg.countries[event.get("country", "unknown")] += 1
                agg.devices[event.get("device_type", "unknown")] += 1

    def _flush_old_windows(self, current_ts: float):
        current_ws = self._window_start(current_ts)
        expired = [
            k for k in self.windows
            if k[0] + self.window_size <= current_ws
        ]
        for k in expired:
            self.completed.append(self.windows.pop(k))

    def get_current_stats(self, ad_id: str) -> Optional[dict]:
        ws = self._window_start(time.time())
        key = (ws, ad_id)
        if key in self.windows:
            return self.windows[key].to_dict()
        return None


class ClickAggregationPipeline:
    """
    Multi-level aggregation pipeline:
      Raw events → 1-min windows → 1-hour rollups → daily rollups
    """

    def __init__(self):
        self.minute_agg = StreamingAggregator(window_size_secs=60)
        self.hour_agg = StreamingAggregator(window_size_secs=3600)
        # Campaign-level aggregation
        self.campaign_stats: dict[str, dict] = defaultdict(
            lambda: {"impressions": 0, "clicks": 0, "cost": 0.0, "budget": 0}
        )

    def process(self, event: dict):
        # Minute-level
        self.minute_agg.process_event(event)
        # Hour-level
        self.hour_agg.process_event(event)
        # Campaign running total
        cid = event.get("campaign_id")
        if cid:
            stats = self.campaign_stats[cid]
            if event["event_type"] == "impression":
                stats["impressions"] += 1
            elif event["event_type"] == "click":
                stats["clicks"] += 1
                stats["cost"] += event.get("click_cost", 0)

    def get_campaign_summary(self, campaign_id: str) -> dict:
        stats = self.campaign_stats.get(campaign_id, {})
        impressions = stats.get("impressions", 0)
        clicks = stats.get("clicks", 0)
        return {
            "campaign_id": campaign_id,
            "impressions": impressions,
            "clicks": clicks,
            "ctr": round(clicks / impressions, 4) if impressions > 0 else 0,
            "total_cost": round(stats.get("cost", 0), 2),
        }


# Demo
if __name__ == "__main__":
    pipeline = ClickAggregationPipeline()

    base_ts = time.time()
    events = [
        {"event_type": "impression", "ad_id": "ad1", "campaign_id": "c1",
         "timestamp": base_ts, "country": "US", "device_type": "mobile"},
        {"event_type": "impression", "ad_id": "ad1", "campaign_id": "c1",
         "timestamp": base_ts + 1, "country": "UK", "device_type": "desktop"},
        {"event_type": "click", "ad_id": "ad1", "campaign_id": "c1",
         "timestamp": base_ts + 2, "click_cost": 0.50, "user_id": "u1",
         "country": "US", "device_type": "mobile"},
        {"event_type": "impression", "ad_id": "ad1", "campaign_id": "c1",
         "timestamp": base_ts + 5, "country": "DE", "device_type": "mobile"},
        {"event_type": "click", "ad_id": "ad1", "campaign_id": "c1",
         "timestamp": base_ts + 6, "click_cost": 0.50, "user_id": "u2",
         "country": "DE", "device_type": "mobile"},
    ]

    for e in events:
        pipeline.process(e)

    stats = pipeline.minute_agg.get_current_stats("ad1")
    print("Minute-level stats:", json.dumps(stats, indent=2, default=str))

    summary = pipeline.get_campaign_summary("c1")
    print("\nCampaign summary:", json.dumps(summary, indent=2))
```

#### C. Click Fraud Detection

```python
import time
from collections import defaultdict, deque
from dataclasses import dataclass
from enum import Enum


class FraudReason(Enum):
    RATE_LIMIT = "Excessive click rate from single IP"
    BOT_SIGNATURE = "Known bot user-agent"
    GEO_MISMATCH = "Geographic impossibility"
    CLICK_FARM = "Coordinated click pattern"
    DUPLICATE = "Duplicate click within threshold"
    INVALID_REFERRER = "Missing or suspicious referrer"


@dataclass
class FraudResult:
    is_fraud: bool
    score: float  # 0.0 (clean) to 1.0 (definitely fraud)
    reasons: list[FraudReason]


class ClickFraudDetector:
    """
    Multi-signal fraud detection engine.

    Checks:
    1. IP rate limiting (too many clicks from one IP)
    2. Bot detection (user-agent analysis)
    3. Click timing patterns
    4. Geographic impossibility
    5. Duplicate detection
    """

    # Thresholds
    IP_CLICK_LIMIT = 10          # max clicks per IP per minute
    USER_CLICK_LIMIT = 5         # max clicks per user per minute
    MIN_TIME_BETWEEN_CLICKS = 0.5  # seconds
    FRAUD_SCORE_THRESHOLD = 0.6

    # Known bot patterns
    BOT_SIGNATURES = [
        "bot", "crawler", "spider", "scrapy",
        "headless", "phantom", "selenium",
    ]

    def __init__(self):
        # Sliding window counters: IP → deque of timestamps
        self.ip_clicks: dict[str, deque] = defaultdict(lambda: deque(maxlen=1000))
        self.user_clicks: dict[str, deque] = defaultdict(lambda: deque(maxlen=1000))
        # For geographic checks
        self.user_last_location: dict[str, tuple[str, float]] = {}
        # Blocked IPs
        self.blocked_ips: set = set()
        # Stats
        self.total_checked = 0
        self.total_fraud = 0

    def check(self, event: dict) -> FraudResult:
        self.total_checked += 1
        reasons = []
        score = 0.0
        ts = event.get("timestamp", time.time())

        # ── Check 1: Blocked IP ──
        ip = event.get("ip_address", "")
        if ip in self.blocked_ips:
            return FraudResult(True, 1.0, [FraudReason.RATE_LIMIT])

        # ── Check 2: IP rate limit ──
        self.ip_clicks[ip].append(ts)
        recent_ip_clicks = sum(
            1 for t in self.ip_clicks[ip] if ts - t < 60
        )
        if recent_ip_clicks > self.IP_CLICK_LIMIT:
            reasons.append(FraudReason.RATE_LIMIT)
            score += 0.4
            if recent_ip_clicks > self.IP_CLICK_LIMIT * 3:
                self.blocked_ips.add(ip)

        # ── Check 3: User rate limit ──
        user_id = event.get("user_id", "")
        if user_id:
            self.user_clicks[user_id].append(ts)
            recent_user_clicks = sum(
                1 for t in self.user_clicks[user_id] if ts - t < 60
            )
            if recent_user_clicks > self.USER_CLICK_LIMIT:
                reasons.append(FraudReason.CLICK_FARM)
                score += 0.3

        # ── Check 4: Bot detection ──
        ua = event.get("user_agent", "").lower()
        if any(bot in ua for bot in self.BOT_SIGNATURES):
            reasons.append(FraudReason.BOT_SIGNATURE)
            score += 0.5

        if not ua or len(ua) < 10:
            reasons.append(FraudReason.BOT_SIGNATURE)
            score += 0.3

        # ── Check 5: Click timing (too fast) ──
        if user_id and len(self.user_clicks[user_id]) >= 2:
            clicks = list(self.user_clicks[user_id])
            time_gaps = [clicks[i] - clicks[i-1] for i in range(1, len(clicks))]
            recent_gaps = [g for g in time_gaps[-5:]]
            if recent_gaps and min(recent_gaps) < self.MIN_TIME_BETWEEN_CLICKS:
                reasons.append(FraudReason.DUPLICATE)
                score += 0.2

        # ── Check 6: Missing referrer ──
        referrer = event.get("referrer", "")
        if not referrer or referrer == "":
            reasons.append(FraudReason.INVALID_REFERRER)
            score += 0.15

        # ── Check 7: Geographic impossibility ──
        country = event.get("country", "")
        if user_id and user_id in self.user_last_location:
            last_country, last_ts = self.user_last_location[user_id]
            time_diff = ts - last_ts
            if last_country != country and time_diff < 3600:
                reasons.append(FraudReason.GEO_MISMATCH)
                score += 0.3

        if user_id:
            self.user_last_location[user_id] = (country, ts)

        score = min(score, 1.0)
        is_fraud = score >= self.FRAUD_SCORE_THRESHOLD

        if is_fraud:
            self.total_fraud += 1

        return FraudResult(is_fraud, round(score, 2), reasons)

    @property
    def fraud_rate(self) -> float:
        if self.total_checked == 0:
            return 0
        return self.total_fraud / self.total_checked


# Demo
if __name__ == "__main__":
    detector = ClickFraudDetector()

    # Normal click
    result = detector.check({
        "ip_address": "1.2.3.4",
        "user_id": "user1",
        "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)",
        "referrer": "https://example.com/page",
        "country": "US",
        "timestamp": time.time(),
    })
    print(f"Normal click: fraud={result.is_fraud}, score={result.score}")

    # Bot click
    result = detector.check({
        "ip_address": "5.6.7.8",
        "user_id": "user2",
        "user_agent": "Googlebot/2.1",
        "referrer": "",
        "country": "CN",
        "timestamp": time.time(),
    })
    print(f"Bot click: fraud={result.is_fraud}, score={result.score}, "
          f"reasons={[r.value for r in result.reasons]}")

    # Rate-limited IP (simulate rapid clicks)
    ts = time.time()
    for i in range(15):
        result = detector.check({
            "ip_address": "10.0.0.1",
            "user_id": f"user_{i}",
            "user_agent": "Mozilla/5.0",
            "referrer": "https://site.com",
            "country": "US",
            "timestamp": ts + i * 0.1,
        })
    print(f"Rate-limited IP: fraud={result.is_fraud}, score={result.score}")

    print(f"\nOverall fraud rate: {detector.fraud_rate:.1%}")
```

#### D. Data Storage Schema (ClickHouse)

```sql
-- Raw click events (columnar, very fast for aggregations)
CREATE TABLE ad_clicks (
    event_id       String,
    event_type     Enum8('impression'=1, 'click'=2, 'conversion'=3),
    ad_id          String,
    campaign_id    String,
    advertiser_id  String,
    publisher_id   String,
    user_id        String,
    ip_address     IPv4,
    country        LowCardinality(String),
    device_type    LowCardinality(String),
    is_fraud       UInt8,
    click_cost     Float64,
    event_time     DateTime
) ENGINE = MergeTree()
PARTITION BY toYYYYMM(event_time)
ORDER BY (campaign_id, ad_id, event_time)
TTL event_time + INTERVAL 2 YEAR;

-- Pre-aggregated materialized view (1-minute windows)
CREATE MATERIALIZED VIEW ad_clicks_1min
ENGINE = SummingMergeTree()
PARTITION BY toYYYYMMDD(window_start)
ORDER BY (campaign_id, ad_id, window_start)
AS SELECT
    campaign_id,
    ad_id,
    toStartOfMinute(event_time) AS window_start,
    countIf(event_type = 'impression') AS impressions,
    countIf(event_type = 'click') AS clicks,
    countIf(event_type = 'conversion') AS conversions,
    sumIf(click_cost, event_type = 'click') AS total_cost,
    uniqIf(user_id, event_type = 'click') AS unique_clickers,
    countIf(is_fraud = 1) AS fraud_clicks
FROM ad_clicks
GROUP BY campaign_id, ad_id, window_start;

-- Hourly rollup
CREATE MATERIALIZED VIEW ad_clicks_1hr
ENGINE = SummingMergeTree()
PARTITION BY toYYYYMM(window_start)
ORDER BY (campaign_id, ad_id, window_start)
AS SELECT
    campaign_id,
    ad_id,
    toStartOfHour(event_time) AS window_start,
    countIf(event_type = 'impression') AS impressions,
    countIf(event_type = 'click') AS clicks,
    sumIf(click_cost, event_type = 'click') AS total_cost
FROM ad_clicks
GROUP BY campaign_id, ad_id, window_start;
```

### 5. Full Architecture Diagram

```
┌────────────────────────────────────────────────────────────────────┐
│                    AD CLICK TRACKING SYSTEM                        │
├────────────────────────────────────────────────────────────────────┤
│                                                                    │
│  ┌──────────┐   ┌──────────────┐   ┌─────────────────────┐       │
│  │ User     │──▶│ Publisher    │──▶│ Ad Serving (CDN)    │       │
│  │ Browser  │   │ Website     │   │ • Select ad         │       │
│  │          │◀──│             │◀──│ • Return creative   │       │
│  └────┬─────┘   └──────────────┘   │ • Embed track URLs │       │
│       │                             └─────────────────────┘       │
│       │                                                            │
│       │  ① Impression pixel → track.example.com/pixel             │
│       │  ② Click → click.example.com/track?ad_id=X               │
│       │                                                            │
│  ┌────▼──────────────────────────────────────────────┐            │
│  │              EDGE / CDN LAYER                      │            │
│  │   ┌──────────┐ ┌──────────┐ ┌──────────┐         │            │
│  │   │  Edge    │ │  Edge    │ │  Edge    │         │            │
│  │   │  PoP 1  │ │  PoP 2  │ │  PoP 3  │         │            │
│  │   └────┬─────┘ └────┬─────┘ └────┬─────┘         │            │
│  └────────┼─────────────┼───────────┼────────────────┘            │
│           └─────────────┼───────────┘                              │
│                         ▼                                          │
│              ┌──────────────────┐                                  │
│              │  Click Tracking  │ ← 302 Redirect + Log            │
│              │  Service (K8s)   │                                  │
│              │  • Dedup cache   │                                  │
│              │  • Fraud quick   │                                  │
│              │    check         │                                  │
│              └────────┬─────────┘                                  │
│                       │                                            │
│              ┌────────▼─────────┐                                  │
│              │      KAFKA       │                                  │
│              │  ┌─────────────┐ │                                  │
│              │  │ impressions │ │                                  │
│              │  │ clicks      │ │                                  │
│              │  │ conversions │ │                                  │
│              │  └─────────────┘ │                                  │
│              └───┬─────┬────┬───┘                                  │
│                  │     │    │                                       │
│        ┌─────────┘     │    └──────────┐                           │
│        ▼               ▼               ▼                           │
│  ┌───────────┐  ┌────────────┐  ┌────────────┐                   │
│  │  Flink    │  │  Fraud     │  │  S3 Sink   │                   │
│  │  Streaming│  │  Detection │  │  (Raw      │                   │
│  │  Agg      │  │  Engine    │  │   Archive) │                   │
│  │  (1m,1h)  │  │  (ML +     │  │            │                   │
│  │           │  │   Rules)   │  │            │                   │
│  └─────┬─────┘  └─────┬──────┘  └────────────┘                   │
│        │               │                                           │
│        ▼               ▼                                           │
│  ┌───────────┐  ┌────────────┐                                    │
│  │ClickHouse │  │ Redis      │                                    │
│  │ (OLAP)    │  │ (Blocked   │                                    │
│  │           │  │  IPs, Live │                                    │
│  │• Rollups  │  │  Counters) │                                    │
│  │• Reports  │  │            │                                    │
│  └─────┬─────┘  └────────────┘                                    │
│        │                                                           │
│        ▼                                                           │
│  ┌───────────────────────────────┐                                │
│  │    Dashboard & Billing API    │                                │
│  │  • Real-time CTR dashboards   │                                │
│  │  • Budget pacing              │                                │
│  │  • Advertiser invoicing       │                                │
│  │  • Publisher payments         │                                │
│  └───────────────────────────────┘                                │
└────────────────────────────────────────────────────────────────────┘
```

---

## 28. Design a Metrics Monitoring System

---

### 1. Requirements

```
Functional:
 • Ingest millions of time-series metrics/sec
 • Support multiple metric types (counter, gauge, histogram)
 • Flexible querying with labels/tags
 • Dashboards with real-time visualization
 • Alerting with configurable rules
 • Downsampling for long-term storage

Non-Functional:
 • Handle 10M+ active time series
 • Ingest 1M data points/second
 • Query latency < 500ms for recent data
 • Alert evaluation < 30 seconds
 • 99.9% availability
 • 1-year raw, 5-year downsampled retention
```

### 2. Scale Estimation

```
• 500 services × 200 instances × 100 metrics = 10M time series
• Collection interval: 10 seconds
• Ingestion: 10M / 10 = 1M data points/second
• Data point size: ~16 bytes (timestamp + float64)
• Raw data: 1M × 16B × 86400 = 1.38 TB/day
• With labels/metadata: ~5 TB/day
• After compression: ~500 GB/day (10:1 compression ratio typical)
```

### 3. High-Level Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│                   METRICS MONITORING SYSTEM                      │
├──────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────────┐   │
│  │ App      │  │ System   │  │ Custom   │  │ StatsD/OTel  │   │
│  │ Metrics  │  │ Metrics  │  │ Metrics  │  │ Collectors   │   │
│  │ (SDK)    │  │ (Agent)  │  │ (Push)   │  │              │   │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └──────┬───────┘   │
│       └──────────────┼───────────┘              │           │
│                      ▼                          ▼           │
│            ┌─────────────────────────────────────┐          │
│            │        INGESTION LAYER              │          │
│            │  ┌───────────┐  ┌───────────┐      │          │
│            │  │ Ingest    │  │ Ingest    │      │          │
│            │  │ Gateway 1 │  │ Gateway N │      │          │
│            │  └─────┬─────┘  └─────┬─────┘      │          │
│            │        └──────┬───────┘             │          │
│            └───────────────┼─────────────────────┘          │
│                            ▼                                 │
│            ┌───────────────────────────────┐                │
│            │          KAFKA               │                │
│            │   (metrics-raw topic)        │                │
│            │   Partitioned by metric_id   │                │
│            └───────────┬──────────────────┘                │
│                        │                                    │
│           ┌────────────┼────────────────┐                  │
│           ▼            ▼                ▼                  │
│    ┌────────────┐ ┌──────────┐   ┌──────────────┐        │
│    │  Storage   │ │  Alert   │   │  Downsample  │        │
│    │  Writer    │ │  Evaluator│   │  Worker      │        │
│    └─────┬──────┘ └────┬─────┘   └──────┬───────┘        │
│          │              │                │                 │
│          ▼              ▼                ▼                 │
│    ┌────────────┐ ┌──────────┐   ┌────────────┐          │
│    │  TSDB      │ │  Alert   │   │  Cold TSDB │          │
│    │  (Hot)     │ │  Manager │   │  (S3/Blob) │          │
│    └─────┬──────┘ └────┬─────┘   └────────────┘          │
│          │              │                                  │
│          ▼              ▼                                  │
│    ┌────────────┐ ┌──────────────┐                       │
│    │  Query     │ │  Notification│                       │
│    │  Engine    │ │  Service     │                       │
│    └─────┬──────┘ │(PagerDuty,  │                       │
│          │        │ Slack, Email)│                       │
│          ▼        └──────────────┘                       │
│    ┌────────────┐                                        │
│    │  Dashboard │                                        │
│    │  (Grafana) │                                        │
│    └────────────┘                                        │
└──────────────────────────────────────────────────────────┘
```

### 4. Core Components

#### A. Metric Data Model & Collection SDK

```python
import time
import threading
import hashlib
import json
from dataclasses import dataclass, field
from enum import Enum
from typing import Optional
from collections import defaultdict
import math
import random


class MetricType(Enum):
    COUNTER = "counter"      # Monotonically increasing (e.g., requests_total)
    GAUGE = "gauge"          # Point-in-time value (e.g., cpu_usage)
    HISTOGRAM = "histogram"  # Distribution (e.g., request_latency)
    SUMMARY = "summary"      # Quantiles (e.g., p50, p95, p99)


@dataclass
class MetricPoint:
    """A single time-series data point."""
    metric_name: str
    labels: dict[str, str]
    value: float
    timestamp: float
    metric_type: MetricType

    @property
    def series_id(self) -> str:
        """Unique identifier for this time series."""
        label_str = ",".join(f"{k}={v}" for k, v in sorted(self.labels.items()))
        raw = f"{self.metric_name}{{{label_str}}}"
        return hashlib.md5(raw.encode()).hexdigest()

    @property
    def series_key(self) -> str:
        label_str = ",".join(f"{k}={v}" for k, v in sorted(self.labels.items()))
        return f"{self.metric_name}{{{label_str}}}"

    def to_dict(self) -> dict:
        return {
            "name": self.metric_name,
            "labels": self.labels,
            "value": self.value,
            "timestamp": self.timestamp,
            "type": self.metric_type.value,
        }


class Counter:
    """Monotonically increasing counter."""

    def __init__(self, name: str, labels: dict[str, str] = None,
                 description: str = ""):
        self.name = name
        self.labels = labels or {}
        self.description = description
        self._value = 0.0
        self._lock = threading.Lock()

    def inc(self, amount: float = 1.0):
        assert amount >= 0, "Counter can only be incremented"
        with self._lock:
            self._value += amount

    def get(self) -> float:
        return self._value

    def collect(self) -> MetricPoint:
        return MetricPoint(
            metric_name=self.name,
            labels=self.labels,
            value=self._value,
            timestamp=time.time(),
            metric_type=MetricType.COUNTER,
        )


class Gauge:
    """Point-in-time value that can go up or down."""

    def __init__(self, name: str, labels: dict[str, str] = None,
                 description: str = ""):
        self.name = name
        self.labels = labels or {}
        self.description = description
        self._value = 0.0
        self._lock = threading.Lock()

    def set(self, value: float):
        with self._lock:
            self._value = value

    def inc(self, amount: float = 1.0):
        with self._lock:
            self._value += amount

    def dec(self, amount: float = 1.0):
        with self._lock:
            self._value -= amount

    def collect(self) -> MetricPoint:
        return MetricPoint(
            metric_name=self.name,
            labels=self.labels,
            value=self._value,
            timestamp=time.time(),
            metric_type=MetricType.GAUGE,
        )


class Histogram:
    """
    Distribution of values across configurable buckets.
    Inspired by Prometheus histogram.
    """

    DEFAULT_BUCKETS = (0.005, 0.01, 0.025, 0.05, 0.1, 0.25,
                       0.5, 1.0, 2.5, 5.0, 10.0, float('inf'))

    def __init__(self, name: str, labels: dict[str, str] = None,
                 buckets: tuple = None, description: str = ""):
        self.name = name
        self.labels = labels or {}
        self.description = description
        self.buckets = buckets or self.DEFAULT_BUCKETS
        self._counts = {b: 0 for b in self.buckets}
        self._sum = 0.0
        self._count = 0
        self._lock = threading.Lock()

    def observe(self, value: float):
        with self._lock:
            self._sum += value
            self._count += 1
            for b in self.buckets:
                if value <= b:
                    self._counts[b] += 1

    def collect(self) -> list[MetricPoint]:
        """Histogram emits multiple series: _bucket, _sum, _count."""
        points = []
        ts = time.time()

        for bucket, count in self._counts.items():
            le = str(bucket) if bucket != float('inf') else "+Inf"
            points.append(MetricPoint(
                metric_name=f"{self.name}_bucket",
                labels={**self.labels, "le": le},
                value=count,
                timestamp=ts,
                metric_type=MetricType.HISTOGRAM,
            ))

        points.append(MetricPoint(
            metric_name=f"{self.name}_sum",
            labels=self.labels,
            value=self._sum,
            timestamp=ts,
            metric_type=MetricType.HISTOGRAM,
        ))

        points.append(MetricPoint(
            metric_name=f"{self.name}_count",
            labels=self.labels,
            value=self._count,
            timestamp=ts,
            metric_type=MetricType.HISTOGRAM,
        ))

        return points

    def quantile(self, q: float) -> float:
        """Approximate quantile from histogram buckets."""
        target = q * self._count
        prev_count = 0
        prev_bound = 0

        for bucket in sorted(self._counts.keys()):
            count = self._counts[bucket]
            if count >= target:
                # Linear interpolation
                fraction = (target - prev_count) / max(count - prev_count, 1)
                return prev_bound + fraction * (bucket - prev_bound)
            prev_count = count
            prev_bound = bucket

        return float('inf')


class MetricsRegistry:
    """Central registry for all metrics in an application."""

    def __init__(self, service_name: str, instance_id: str):
        self.service_name = service_name
        self.instance_id = instance_id
        self._metrics: dict[str, object] = {}
        self._lock = threading.Lock()

    def counter(self, name: str, labels: dict = None, **kwargs) -> Counter:
        key = self._key(name, labels)
        if key not in self._metrics:
            with self._lock:
                if key not in self._metrics:
                    base_labels = {
                        "service": self.service_name,
                        "instance": self.instance_id,
                        **(labels or {}),
                    }
                    self._metrics[key] = Counter(name, base_labels, **kwargs)
        return self._metrics[key]

    def gauge(self, name: str, labels: dict = None, **kwargs) -> Gauge:
        key = self._key(name, labels)
        if key not in self._metrics:
            with self._lock:
                if key not in self._metrics:
                    base_labels = {
                        "service": self.service_name,
                        "instance": self.instance_id,
                        **(labels or {}),
                    }
                    self._metrics[key] = Gauge(name, base_labels, **kwargs)
        return self._metrics[key]

    def histogram(self, name: str, labels: dict = None, **kwargs) -> Histogram:
        key = self._key(name, labels)
        if key not in self._metrics:
            with self._lock:
                if key not in self._metrics:
                    base_labels = {
                        "service": self.service_name,
                        "instance": self.instance_id,
                        **(labels or {}),
                    }
                    self._metrics[key] = Histogram(name, base_labels, **kwargs)
        return self._metrics[key]

    def collect_all(self) -> list[MetricPoint]:
        points = []
        for metric in self._metrics.values():
            result = metric.collect()
            if isinstance(result, list):
                points.extend(result)
            else:
                points.append(result)
        return points

    def _key(self, name, labels) -> str:
        label_str = json.dumps(labels or {}, sort_keys=True)
        return f"{name}|{label_str}"


# Demo
if __name__ == "__main__":
    registry = MetricsRegistry("order-service", "instance-1")

    req_counter = registry.counter("http_requests_total",
                                    {"method": "POST", "path": "/api/orders"})
    error_counter = registry.counter("http_errors_total",
                                      {"method": "POST", "path": "/api/orders"})
    latency_hist = registry.histogram("http_request_duration_seconds",
                                       {"method": "POST", "path": "/api/orders"})
    cpu_gauge = registry.gauge("cpu_usage_percent")

    # Simulate traffic
    for _ in range(1000):
        req_counter.inc()
        latency = random.expovariate(1.0 / 0.15)  # avg 150ms
        latency_hist.observe(latency)
        if random.random() < 0.02:  # 2% error rate
            error_counter.inc()

    cpu_gauge.set(67.5)

    # Collect all metrics
    points = registry.collect_all()
    print(f"Collected {len(points)} metric points:")
    for p in points[:5]:
        print(f"  {p.series_key} = {p.value}")

    print(f"\n  P50 latency: {latency_hist.quantile(0.5):.3f}s")
    print(f"  P95 latency: {latency_hist.quantile(0.95):.3f}s")
    print(f"  P99 latency: {latency_hist.quantile(0.99):.3f}s")
```

#### B. Time-Series Storage Engine

```python
import time
import struct
import zlib
from dataclasses import dataclass, field
from collections import defaultdict
from typing import Optional
import bisect


@dataclass
class TimeSeriesChunk:
    """
    Compressed chunk of time-series data.
    Inspired by Gorilla/Facebook's in-memory TSDB compression.

    Strategy:
    - Delta-of-delta encoding for timestamps
    - XOR encoding for values (IEEE 754 float)
    - Chunk = 2 hours of data
    """
    series_id: str
    start_time: float
    end_time: float = 0
    timestamps: list[float] = field(default_factory=list)
    values: list[float] = field(default_factory=list)
    _compressed: Optional[bytes] = None
    _frozen: bool = False

    def append(self, timestamp: float, value: float):
        if self._frozen:
            raise ValueError("Chunk is frozen/compressed")
        self.timestamps.append(timestamp)
        self.values.append(value)
        self.end_time = timestamp

    @property
    def count(self) -> int:
        return len(self.timestamps)

    def compress(self) -> bytes:
        """Compress using delta encoding + zlib."""
        if self._compressed:
            return self._compressed

        # Pack timestamps as deltas
        ts_deltas = []
        for i, ts in enumerate(self.timestamps):
            if i == 0:
                ts_deltas.append(ts)
            else:
                ts_deltas.append(ts - self.timestamps[i - 1])

        data = {
            "series_id": self.series_id,
            "start": self.start_time,
            "ts_deltas": ts_deltas,
            "values": self.values,
        }
        raw = json.dumps(data).encode()
        self._compressed = zlib.compress(raw, level=6)
        self._frozen = True
        return self._compressed

    @classmethod
    def decompress(cls, data: bytes) -> 'TimeSeriesChunk':
        raw = zlib.decompress(data)
        parsed = json.loads(raw)

        # Reconstruct timestamps from deltas
        timestamps = []
        for i, delta in enumerate(parsed["ts_deltas"]):
            if i == 0:
                timestamps.append(delta)
            else:
                timestamps.append(timestamps[-1] + delta)

        chunk = cls(
            series_id=parsed["series_id"],
            start_time=parsed["start"],
        )
        chunk.timestamps = timestamps
        chunk.values = parsed["values"]
        chunk.end_time = timestamps[-1] if timestamps else parsed["start"]
        return chunk

    @property
    def compression_ratio(self) -> float:
        raw_size = len(self.timestamps) * 16  # 8 bytes ts + 8 bytes val
        compressed_size = len(self.compress())
        return raw_size / compressed_size if compressed_size > 0 else 0


class TimeSeriesDB:
    """
    In-memory TSDB with chunk-based storage.

    Architecture mirrors Prometheus TSDB:
    ┌───────────────────────────────────────┐
    │  HEAD (Active, in-memory)             │
    │  ┌─────────┐ ┌─────────┐            │
    │  │ Chunk 1 │ │ Chunk 2 │ ...        │
    │  │ (2hr)   │ │ (2hr)   │            │
    │  └─────────┘ └─────────┘            │
    ├───────────────────────────────────────┤
    │  BLOCKS (Immutable, compressed)       │
    │  ┌──────────────┐ ┌──────────────┐  │
    │  │ Block        │ │ Block        │  │
    │  │ (6hr/24hr)   │ │ (6hr/24hr)   │  │
    │  │ • Index      │ │ • Index      │  │
    │  │ • Chunks     │ │ • Chunks     │  │
    │  │ • Tombstones │ │ • Tombstones │  │
    │  └──────────────┘ └──────────────┘  │
    └───────────────────────────────────────┘
    """

    CHUNK_DURATION = 7200  # 2 hours in seconds

    def __init__(self):
        # Active chunks: series_id → list of chunks
        self.active_chunks: dict[str, list[TimeSeriesChunk]] = defaultdict(list)
        # Compressed/archived blocks
        self.archived_blocks: dict[str, list[bytes]] = defaultdict(list)
        # Inverted index: label_key=label_value → set of series_ids
        self.inverted_index: dict[str, set[str]] = defaultdict(set)
        # Series metadata
        self.series_metadata: dict[str, dict] = {}
        # Stats
        self.total_points = 0
        self.total_series = 0

    def _get_or_create_chunk(self, series_id: str,
                              timestamp: float) -> TimeSeriesChunk:
        chunks = self.active_chunks[series_id]

        if chunks:
            latest = chunks[-1]
            if not latest._frozen and (timestamp - latest.start_time) < self.CHUNK_DURATION:
                return latest

            # Freeze and compress old chunk
            if not latest._frozen:
                compressed = latest.compress()
                self.archived_blocks[series_id].append(compressed)

        # Create new chunk
        chunk = TimeSeriesChunk(series_id=series_id, start_time=timestamp)
        self.active_chunks[series_id].append(chunk)
        return chunk

    def ingest(self, point: MetricPoint):
        """Ingest a single data point."""
        series_id = point.series_id

        # Update inverted index
        if series_id not in self.series_metadata:
            self.series_metadata[series_id] = {
                "name": point.metric_name,
                "labels": point.labels,
                "type": point.metric_type.value,
            }
            self.total_series += 1

            # Index all labels
            self.inverted_index[f"__name__={point.metric_name}"].add(series_id)
            for k, v in point.labels.items():
                self.inverted_index[f"{k}={v}"].add(series_id)

        # Write to chunk
        chunk = self._get_or_create_chunk(series_id, point.timestamp)
        chunk.append(point.timestamp, point.value)
        self.total_points += 1

    def ingest_batch(self, points: list[MetricPoint]):
        for point in points:
            self.ingest(point)

    def query(self, metric_name: str, label_matchers: dict[str, str] = None,
              start_time: float = None, end_time: float = None) -> dict[str, list[tuple[float, float]]]:
        """
        Query time series matching the given selectors.
        Returns: {series_key: [(timestamp, value), ...]}
        """
        # Find matching series using inverted index
        matching_series = self.inverted_index.get(f"__name__={metric_name}", set()).copy()

        if label_matchers:
            for k, v in label_matchers.items():
                label_matches = self.inverted_index.get(f"{k}={v}", set())
                matching_series &= label_matches

        results = {}
        start_time = start_time or 0
        end_time = end_time or float('inf')

        for series_id in matching_series:
            meta = self.series_metadata[series_id]
            label_str = ",".join(f'{k}="{v}"' for k, v in sorted(meta["labels"].items()))
            series_key = f'{meta["name"]}{{{label_str}}}'

            data_points = []

            # Search archived blocks
            for compressed in self.archived_blocks.get(series_id, []):
                chunk = TimeSeriesChunk.decompress(compressed)
                for ts, val in zip(chunk.timestamps, chunk.values):
                    if start_time <= ts <= end_time:
                        data_points.append((ts, val))

            # Search active chunks
            for chunk in self.active_chunks.get(series_id, []):
                if not chunk._frozen:
                    for ts, val in zip(chunk.timestamps, chunk.values):
                        if start_time <= ts <= end_time:
                            data_points.append((ts, val))

            if data_points:
                results[series_key] = sorted(data_points)

        return results

    def query_instant(self, metric_name: str,
                      label_matchers: dict = None) -> dict[str, float]:
        """Get the latest value for matching series."""
        results = self.query(metric_name, label_matchers)
        return {
            key: points[-1][1] if points else 0
            for key, points in results.items()
        }

    def get_stats(self) -> dict:
        total_active_points = sum(
            sum(c.count for c in chunks)
            for chunks in self.active_chunks.values()
        )
        total_archived_chunks = sum(
            len(blocks) for blocks in self.archived_blocks.values()
        )
        return {
            "total_series": self.total_series,
            "total_points_ingested": self.total_points,
            "active_chunks": sum(
                len(c) for c in self.active_chunks.values()
            ),
            "active_points": total_active_points,
            "archived_chunks": total_archived_chunks,
        }


# Demo
if __name__ == "__main__":
    import json as json_module

    tsdb = TimeSeriesDB()
    registry = MetricsRegistry("web-api", "pod-1")

    # Simulate 10 minutes of metrics
    req_counter = registry.counter("http_requests_total",
                                    {"method": "GET", "status": "200"})
    err_counter = registry.counter("http_requests_total",
                                    {"method": "GET", "status": "500"})
    cpu = registry.gauge("cpu_usage_percent", {"core": "0"})

    base_time = time.time() - 600  # 10 minutes ago

    for i in range(60):  # 60 data points, 10s apart
        t = base_time + i * 10
        req_counter.inc(random.randint(80, 120))
        err_counter.inc(random.randint(0, 3))
        cpu.set(50 + 30 * math.sin(i / 10) + random.uniform(-5, 5))

        for point in registry.collect_all():
            point.timestamp = t
            tsdb.ingest(point)

    print("TSDB Stats:", json_module.dumps(tsdb.get_stats(), indent=2))

    # Query
    print("\n--- Query: http_requests_total{status='200'} ---")
    results = tsdb.query("http_requests_total", {"status": "200"})
    for key, points in results.items():
        print(f"  {key}: {len(points)} points, "
              f"latest={points[-1][1]:.0f}")

    print("\n--- Instant Query: cpu_usage_percent ---")
    instant = tsdb.query_instant("cpu_usage_percent")
    for key, val in instant.items():
        print(f"  {key} = {val:.1f}%")
```

#### C. Alerting Engine

```python
import time
import re
from dataclasses import dataclass, field
from enum import Enum
from typing import Callable, Optional
from collections import deque


class AlertState(Enum):
    OK = "ok"
    PENDING = "pending"   # Condition met but within 'for' duration
    FIRING = "firing"
    RESOLVED = "resolved"


class AlertSeverity(Enum):
    INFO = "info"
    WARNING = "warning"
    CRITICAL = "critical"


class Comparator(Enum):
    GT = ">"
    GTE = ">="
    LT = "<"
    LTE = "<="
    EQ = "=="
    NEQ = "!="


@dataclass
class AlertRule:
    """
    Defines an alerting rule.

    Example (Prometheus-like):
      alert: HighErrorRate
      expr: rate(http_errors_total[5m]) / rate(http_requests_total[5m]) > 0.05
      for: 5m
      labels:
        severity: critical
      annotations:
        summary: "Error rate > 5%"
    """
    rule_id: str
    name: str
    metric_name: str
    label_matchers: dict[str, str]
    comparator: Comparator
    threshold: float
    for_duration: float  # seconds, how long condition must hold
    severity: AlertSeverity
    summary: str
    runbook_url: str = ""
    # Evaluation function: takes query results, returns computed value
    eval_func: Optional[Callable] = None


@dataclass
class Alert:
    rule: AlertRule
    state: AlertState = AlertState.OK
    value: float = 0.0
    started_at: float = 0.0  # When condition first became true
    fired_at: float = 0.0    # When alert transitioned to FIRING
    resolved_at: float = 0.0
    labels: dict = field(default_factory=dict)
    annotations: dict = field(default_factory=dict)

    @property
    def duration(self) -> float:
        if self.state == AlertState.FIRING:
            return time.time() - self.fired_at
        return 0


class AlertManager:
    """
    Evaluates alert rules against TSDB and manages alert lifecycle.

    Pipeline:
    ┌──────────┐    ┌──────────────┐    ┌─────────────┐    ┌──────────────┐
    │  TSDB    │───▶│ Rule         │───▶│ Dedup /     │───▶│ Notification │
    │  Query   │    │ Evaluation   │    │ Grouping /  │    │ Dispatch     │
    │          │    │              │    │ Inhibition  │    │ (Slack, PD)  │
    └──────────┘    └──────────────┘    └─────────────┘    └──────────────┘
    """

    def __init__(self, tsdb: TimeSeriesDB):
        self.tsdb = tsdb
        self.rules: list[AlertRule] = []
        self.alerts: dict[str, Alert] = {}  # rule_id → Alert
        self.notification_history: list[dict] = []
        self.notification_handlers: list[Callable] = []
        # Silence rules
        self.silences: list[dict] = []

    def add_rule(self, rule: AlertRule):
        self.rules.append(rule)
        self.alerts[rule.rule_id] = Alert(rule=rule)

    def add_notification_handler(self, handler: Callable):
        self.notification_handlers.append(handler)

    def silence(self, label_matchers: dict, duration: float):
        self.silences.append({
            "matchers": label_matchers,
            "until": time.time() + duration,
        })

    def evaluate_all(self):
        """Evaluate all alert rules. Called periodically (e.g., every 15s)."""
        now = time.time()

        for rule in self.rules:
            alert = self.alerts[rule.rule_id]
            value = self._evaluate_rule(rule)

            condition_met = self._check_condition(
                value, rule.comparator, rule.threshold
            )

            if condition_met:
                if alert.state == AlertState.OK or alert.state == AlertState.RESOLVED:
                    alert.state = AlertState.PENDING
                    alert.started_at = now
                    alert.value = value
                    print(f"  ⏳ PENDING: {rule.name} = {value:.4f} "
                          f"{rule.comparator.value} {rule.threshold}")

                elif alert.state == AlertState.PENDING:
                    elapsed = now - alert.started_at
                    if elapsed >= rule.for_duration:
                        alert.state = AlertState.FIRING
                        alert.fired_at = now
                        alert.value = value
                        print(f"  🔥 FIRING: {rule.name} = {value:.4f} "
                              f"(after {elapsed:.0f}s)")
                        self._send_notification(alert, "firing")

                elif alert.state == AlertState.FIRING:
                    alert.value = value  # Update current value

            else:
                if alert.state in (AlertState.PENDING, AlertState.FIRING):
                    if alert.state == AlertState.FIRING:
                        alert.resolved_at = now
                        print(f"  ✅ RESOLVED: {rule.name}")
                        self._send_notification(alert, "resolved")
                    alert.state = AlertState.RESOLVED

    def _evaluate_rule(self, rule: AlertRule) -> float:
        """Query TSDB and compute the metric value."""
        if rule.eval_func:
            results = self.tsdb.query(rule.metric_name, rule.label_matchers)
            return rule.eval_func(results)

        # Default: latest value
        instant = self.tsdb.query_instant(rule.metric_name, rule.label_matchers)
        if instant:
            return list(instant.values())[0]
        return 0.0

    def _check_condition(self, value: float, comp: Comparator,
                         threshold: float) -> bool:
        ops = {
            Comparator.GT: lambda a, b: a > b,
            Comparator.GTE: lambda a, b: a >= b,
            Comparator.LT: lambda a, b: a < b,
            Comparator.LTE: lambda a, b: a <= b,
            Comparator.EQ: lambda a, b: a == b,
            Comparator.NEQ: lambda a, b: a != b,
        }
        return ops[comp](value, threshold)

    def _send_notification(self, alert: Alert, action: str):
        """Send alert notification through configured channels."""
        # Check silences
        for silence in self.silences:
            if time.time() < silence["until"]:
                # Check if silence matches
                matches = all(
                    alert.rule.label_matchers.get(k) == v
                    for k, v in silence["matchers"].items()
                )
                if matches:
                    print(f"    (silenced)")
                    return

        notification = {
            "alert_name": alert.rule.name,
            "state": action,
            "severity": alert.rule.severity.value,
            "value": alert.value,
            "threshold": alert.rule.threshold,
            "summary": alert.rule.summary,
            "fired_at": alert.fired_at,
            "labels": alert.rule.label_matchers,
            "timestamp": time.time(),
        }

        self.notification_history.append(notification)

        for handler in self.notification_handlers:
            handler(notification)

    def get_active_alerts(self) -> list[dict]:
        return [
            {
                "name": alert.rule.name,
                "state": alert.state.value,
                "severity": alert.rule.severity.value,
                "value": alert.value,
                "duration": alert.duration,
            }
            for alert in self.alerts.values()
            if alert.state in (AlertState.PENDING, AlertState.FIRING)
        ]


# ─── Notification Handlers ───

def slack_handler(notification: dict):
    emoji = "🔥" if notification["state"] == "firing" else "✅"
    print(f"    📱 Slack: {emoji} [{notification['severity'].upper()}] "
          f"{notification['alert_name']}: {notification['summary']} "
          f"(value={notification['value']:.4f})")


def pagerduty_handler(notification: dict):
    if notification["severity"] == "critical":
        print(f"    📟 PagerDuty: Incident created for "
              f"{notification['alert_name']}")


# Demo
if __name__ == "__main__":
    import json as json_mod

    tsdb = TimeSeriesDB()
    alert_mgr = AlertManager(tsdb)

    alert_mgr.add_notification_handler(slack_handler)
    alert_mgr.add_notification_handler(pagerduty_handler)

    # Define alert rules
    alert_mgr.add_rule(AlertRule(
        rule_id="high_cpu",
        name="HighCPUUsage",
        metric_name="cpu_usage_percent",
        label_matchers={},
        comparator=Comparator.GT,
        threshold=80.0,
        for_duration=2.0,  # Alert after 2 seconds (demo)
        severity=AlertSeverity.CRITICAL,
        summary="CPU usage above 80%",
    ))

    alert_mgr.add_rule(AlertRule(
        rule_id="high_error_rate",
        name="HighErrorRate",
        metric_name="http_requests_total",
        label_matchers={"status": "500"},
        comparator=Comparator.GT,
        threshold=50.0,
        for_duration=1.0,
        severity=AlertSeverity.WARNING,
        summary="Error count exceeding threshold",
    ))

    # Simulate metrics
    registry = MetricsRegistry("web-api", "pod-1")
    cpu = registry.gauge("cpu_usage_percent", {"core": "0"})
    errors = registry.counter("http_requests_total",
                               {"method": "GET", "status": "500"})

    print("=== Simulating metrics + alert evaluation ===\n")

    for i in range(8):
        # CPU spikes at step 2
        if i < 2:
            cpu.set(60 + random.uniform(-5, 5))
        else:
            cpu.set(90 + random.uniform(-3, 3))

        errors.inc(random.randint(5, 15))

        # Ingest
        for point in registry.collect_all():
            tsdb.ingest(point)

        # Evaluate alerts
        print(f"\n--- Step {i} (t+{i}s) ---")
        alert_mgr.evaluate_all()

        time.sleep(0.5)  # Simulate time passing

    print("\n=== Active Alerts ===")
    for alert in alert_mgr.get_active_alerts():
        print(f"  {json_mod.dumps(alert, indent=4)}")
```

#### D. Downsampling & Long-Term Storage

```python
import time
from collections import defaultdict
from dataclasses import dataclass


@dataclass
class DownsampledPoint:
    timestamp: float  # bucket start
    min_val: float
    max_val: float
    avg_val: float
    sum_val: float
    count: int


class Downsampler:
    """
    Reduces resolution of time-series data for long-term storage.

    Retention Policy:
    ┌──────────────────────────────────────────────────┐
    │ Resolution │ Retention │ Storage                  │
    ├──────────────────────────────────────────────────┤
    │ 10s (raw)  │ 15 days   │ Hot TSDB                │
    │ 1 minute   │ 90 days   │ Warm TSDB               │
    │ 5 minutes  │ 1 year    │ Cold Storage             │
    │ 1 hour     │ 5 years   │ S3/Glacier               │
    └──────────────────────────────────────────────────┘
    """

    POLICIES = [
        {"name": "1min", "interval": 60, "retention_days": 90},
        {"name": "5min", "interval": 300, "retention_days": 365},
        {"name": "1hour", "interval": 3600, "retention_days": 1825},
    ]

    def __init__(self):
        # {resolution: {series_id: [DownsampledPoint]}}
        self.downsampled_data: dict[str, dict[str, list]] = {
            p["name"]: defaultdict(list) for p in self.POLICIES
        }

    def downsample(self, series_id: str,
                   raw_points: list[tuple[float, float]]) -> dict:
        """
        Downsample raw points into configured resolutions.
        Returns: {resolution_name: [DownsampledPoint]}
        """
        results = {}

        for policy in self.POLICIES:
            interval = policy["interval"]
            name = policy["name"]

            # Group points into buckets
            buckets: dict[float, list[float]] = defaultdict(list)
            for ts, val in raw_points:
                bucket_start = (int(ts) // interval) * interval
                buckets[bucket_start].append(val)

            # Aggregate each bucket
            downsampled = []
            for bucket_ts in sorted(buckets.keys()):
                values = buckets[bucket_ts]
                point = DownsampledPoint(
                    timestamp=bucket_ts,
                    min_val=min(values),
                    max_val=max(values),
                    avg_val=sum(values) / len(values),
                    sum_val=sum(values),
                    count=len(values),
                )
                downsampled.append(point)

            self.downsampled_data[name][series_id].extend(downsampled)
            results[name] = downsampled

        return results

    def query_downsampled(self, resolution: str, series_id: str,
                          start: float, end: float) -> list[DownsampledPoint]:
        points = self.downsampled_data.get(resolution, {}).get(series_id, [])
        return [p for p in points if start <= p.timestamp <= end]


# Demo
if __name__ == "__main__":
    downsampler = Downsampler()

    # Generate 1 hour of raw data (10s intervals = 360 points)
    base = time.time() - 3600
    raw = [
        (base + i * 10, 50 + 30 * math.sin(i / 36) + random.uniform(-5, 5))
        for i in range(360)
    ]

    print(f"Raw points: {len(raw)}")

    results = downsampler.downsample("cpu_series_001", raw)

    for res_name, points in results.items():
        print(f"\n{res_name}: {len(points)} points")
        for p in points[:3]:
            print(f"  t={p.timestamp:.0f} min={p.min_val:.1f} "
                  f"max={p.max_val:.1f} avg={p.avg_val:.1f} "
                  f"count={p.count}")

    # Compression ratio
    raw_size = len(raw) * 16  # 8 bytes ts + 8 bytes value
    for res_name, points in results.items():
        ds_size = len(points) * 48  # 6 fields × 8 bytes
        ratio = raw_size / ds_size if ds_size > 0 else 0
        print(f"\n{res_name} compression: {ratio:.1f}x "
              f"({raw_size} bytes → {ds_size} bytes)")
```

#### E. Query Language (PromQL-inspired)

```python
import re
import time
from dataclasses import dataclass
from typing import Optional
from enum import Enum


class AggOp(Enum):
    SUM = "sum"
    AVG = "avg"
    MIN = "min"
    MAX = "max"
    COUNT = "count"
    RATE = "rate"
    IRATE = "irate"


@dataclass
class QueryAST:
    """Simple AST for metric queries."""
    metric_name: str
    label_matchers: dict[str, str]
    range_seconds: Optional[float] = None  # For range vectors
    aggregation: Optional[AggOp] = None
    group_by: Optional[list[str]] = None
    offset: float = 0  # Time offset


class MetricQueryEngine:
    """
    Simple query engine supporting PromQL-like expressions.

    Supported queries:
      http_requests_total{method="GET"}                    - instant
      rate(http_requests_total{method="GET"}[5m])          - rate
      sum by (method) (http_requests_total)                - aggregation
      avg(cpu_usage_percent{instance=~"web-.*"})           - average
    """

    def __init__(self, tsdb: TimeSeriesDB):
        self.tsdb = tsdb

    def parse(self, query: str) -> QueryAST:
        """Parse a simplified PromQL expression."""
        # Check for aggregation: sum by (label) (metric{...})
        agg_match = re.match(
            r'(sum|avg|min|max|count)\s*(?:by\s*\(([^)]+)\))?\s*\((.+)\)',
            query.strip()
        )
        if agg_match:
            agg_op = AggOp(agg_match.group(1))
            group_by = [l.strip() for l in agg_match.group(2).split(",")] \
                if agg_match.group(2) else None
            inner = agg_match.group(3).strip()
            ast = self._parse_selector(inner)
            ast.aggregation = agg_op
            ast.group_by = group_by
            return ast

        # Check for rate: rate(metric{...}[5m])
        rate_match = re.match(
            r'(rate|irate)\((.+)\[(\d+)([smhd])\]\)',
            query.strip()
        )
        if rate_match:
            func = AggOp(rate_match.group(1))
            inner = rate_match.group(2).strip()
            duration = int(rate_match.group(3))
            unit = rate_match.group(4)
            multipliers = {"s": 1, "m": 60, "h": 3600, "d": 86400}
            range_secs = duration * multipliers.get(unit, 1)

            ast = self._parse_selector(inner)
            ast.range_seconds = range_secs
            ast.aggregation = func
            return ast

        # Simple selector
        return self._parse_selector(query)

    def _parse_selector(self, selector: str) -> QueryAST:
        """Parse metric_name{label1='value1', label2='value2'}"""
        match = re.match(r'(\w+)(?:\{([^}]*)\})?', selector.strip())
        if not match:
            raise ValueError(f"Invalid selector: {selector}")

        name = match.group(1)
        labels = {}

        if match.group(2):
            for pair in match.group(2).split(","):
                pair = pair.strip()
                if "=" in pair:
                    k, v = pair.split("=", 1)
                    labels[k.strip()] = v.strip().strip('"\'')

        return QueryAST(metric_name=name, label_matchers=labels)

    def execute(self, query: str) -> dict:
        """Execute a query and return results."""
        ast = self.parse(query)
        now = time.time()

        if ast.aggregation == AggOp.RATE and ast.range_seconds:
            return self._compute_rate(ast, now)

        if ast.aggregation and ast.aggregation != AggOp.RATE:
            return self._compute_aggregation(ast, now)

        # Instant query
        return self.tsdb.query_instant(ast.metric_name, ast.label_matchers)

    def _compute_rate(self, ast: QueryAST, now: float) -> dict:
        """Compute per-second rate over a range."""
        start = now - ast.range_seconds
        results = self.tsdb.query(ast.metric_name, ast.label_matchers,
                                   start_time=start, end_time=now)
        rates = {}
        for key, points in results.items():
            if len(points) >= 2:
                first_ts, first_val = points[0]
                last_ts, last_val = points[-1]
                time_diff = last_ts - first_ts
                if time_diff > 0:
                    rates[key] = (last_val - first_val) / time_diff
        return rates

    def _compute_aggregation(self, ast: QueryAST, now: float) -> dict:
        """Compute aggregation (sum, avg, etc.)."""
        instant = self.tsdb.query_instant(ast.metric_name, ast.label_matchers)

        if not ast.group_by:
            # Aggregate all series into one value
            values = list(instant.values())
            if not values:
                return {"result": 0}

            ops = {
                AggOp.SUM: sum(values),
                AggOp.AVG: sum(values) / len(values),
                AggOp.MIN: min(values),
                AggOp.MAX: max(values),
                AggOp.COUNT: len(values),
            }
            return {"result": ops.get(ast.aggregation, 0)}

        # Group by specific labels
        groups: dict[str, list[float]] = {}
        for key, value in instant.items():
            # Extract group label values from series key
            group_key = self._extract_group_key(key, ast.group_by)
            if group_key not in groups:
                groups[group_key] = []
            groups[group_key].append(value)

        result = {}
        for group_key, values in groups.items():
            ops = {
                AggOp.SUM: sum(values),
                AggOp.AVG: sum(values) / len(values),
                AggOp.MIN: min(values),
                AggOp.MAX: max(values),
                AggOp.COUNT: len(values),
            }
            result[group_key] = ops.get(ast.aggregation, 0)

        return result

    def _extract_group_key(self, series_key: str,
                            group_by: list[str]) -> str:
        labels = {}
        match = re.search(r'\{([^}]+)\}', series_key)
        if match:
            for pair in match.group(1).split(","):
                k, v = pair.strip().split("=", 1)
                labels[k.strip()] = v.strip('"')

        return ",".join(f'{k}={labels.get(k, "")}' for k in group_by)


# Demo
if __name__ == "__main__":
    tsdb = TimeSeriesDB()

    # Ingest sample data
    base = time.time() - 300
    for i in range(30):
        for method in ["GET", "POST"]:
            for status in ["200", "500"]:
                point = MetricPoint(
                    metric_name="http_requests_total",
                    labels={
                        "service": "api",
                        "method": method,
                        "status": status,
                    },
                    value=100 + i * 10 + (5 if status == "500" else 50),
                    timestamp=base + i * 10,
                    metric_type=MetricType.COUNTER,
                )
                tsdb.ingest(point)

    qe = MetricQueryEngine(tsdb)

    queries = [
        'http_requests_total{method="GET", status="200"}',
        'sum(http_requests_total)',
        'sum by (method) (http_requests_total)',
        'rate(http_requests_total{method="GET", status="200"}[5m])',
    ]

    for q in queries:
        print(f"\nQuery: {q}")
        result = qe.execute(q)
        print(f"  Result: {result}")
```

### 5. Full System Architecture

```
┌────────────────────────────────────────────────────────────────────┐
│                 METRICS MONITORING SYSTEM                          │
├────────────────────────────────────────────────────────────────────┤
│                                                                    │
│  DATA SOURCES                                                      │
│  ┌─────────┐ ┌──────────┐ ┌──────────┐ ┌──────────────┐         │
│  │App SDK  │ │Node      │ │Container │ │Custom        │         │
│  │(Counter,│ │Exporter  │ │cAdvisor  │ │Exporters     │         │
│  │Gauge,   │ │(CPU,Mem, │ │(K8s pods)│ │(DB,Queue,    │         │
│  │Histogram│ │Disk,Net) │ │          │ │Cache stats)  │         │
│  └────┬────┘ └────┬─────┘ └────┬─────┘ └──────┬───────┘         │
│       └───────────┼────────────┼───────────────┘                  │
│                   ▼            ▼                                   │
│  COLLECTION LAYER                                                  │
│  ┌────────────────────────────────────────┐                       │
│  │         Collection Agents              │                       │
│  │  (Pull: scrape /metrics endpoints)     │                       │
│  │  (Push: receive StatsD/OTLP/Graphite)  │                       │
│  │                                        │                       │
│  │  ┌──────────┐ ┌──────────┐            │                       │
│  │  │ Agent 1  │ │ Agent N  │            │                       │
│  │  │ (scrapes │ │          │            │                       │
│  │  │  targets)│ │          │            │                       │
│  │  └──────────┘ └──────────┘            │                       │
│  └──────────────────┬─────────────────────┘                       │
│                     │                                              │
│  INGESTION LAYER    ▼                                              │
│  ┌────────────────────────────────────────┐                       │
│  │              KAFKA                     │                       │
│  │  Topic: metrics-raw (1000 partitions)  │                       │
│  │  Partition key: hash(metric_name)      │                       │
│  └───────────┬───────────┬────────────────┘                       │
│              │           │                                         │
│  PROCESSING  │           │                                         │
│  ┌───────────▼───┐  ┌───▼──────────────┐                         │
│  │  TSDB Writer  │  │  Stream Processor│                         │
│  │  (Batch write │  │  (Flink/Spark)   │                         │
│  │   to storage) │  │  • Pre-aggregate │                         │
│  └───────┬───────┘  │  • Anomaly detect│                         │
│          │          │  • Top-K compute  │                         │
│          │          └──────┬────────────┘                         │
│          │                 │                                       │
│  STORAGE ▼                 ▼                                       │
│  ┌─────────────────────────────────────────┐                      │
│  │           TIERED STORAGE                │                      │
│  │                                         │                      │
│  │  HOT (0-2h): In-Memory WAL + Chunks    │                      │
│  │  ┌───────────────────────────────────┐  │                      │
│  │  │  Prometheus-style TSDB            │  │                      │
│  │  │  (Memory-mapped, compressed)      │  │                      │
│  │  └───────────────────────────────────┘  │                      │
│  │                                         │                      │
│  │  WARM (2h-15d): Local SSD Blocks       │                      │
│  │  ┌───────────────────────────────────┐  │                      │
│  │  │  Compacted blocks with index      │  │                      │
│  │  └───────────────────────────────────┘  │                      │
│  │                                         │                      │
│  │  COLD (15d+): Object Storage           │                      │
│  │  ┌───────────────────────────────────┐  │                      │
│  │  │  S3/GCS with downsampled data     │  │                      │
│  │  │  (Thanos / Cortex style)          │  │                      │
│  │  └───────────────────────────────────┘  │                      │
│  └─────────────────────────────────────────┘                      │
│                                                                    │
│  QUERY & ALERT LAYER                                               │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐        │
│  │ Query Engine │  │ Alert Engine │  │ Recording Rules  │        │
│  │ (PromQL)     │  │ (evaluate    │  │ (pre-compute     │        │
│  │              │  │  every 15s)  │  │  expensive        │        │
│  │• Instant     │  │              │  │  queries)         │        │
│  │• Range       │  │• Thresholds  │  │                   │        │
│  │• Aggregation │  │• Anomaly     │  │                   │        │
│  └──────┬───────┘  │• Composite   │  └──────────────────┘        │
│         │          └──────┬───────┘                                │
│         │                 │                                        │
│  PRESENTATION             ▼                                        │
│  ┌──────▼───────┐  ┌──────────────────────────┐                  │
│  │ Grafana      │  │  Notification Router     │                  │
│  │ Dashboard    │  │  ┌──────┐ ┌──────┐      │                  │
│  │              │  │  │Slack │ │PD    │      │                  │
│  │• Charts      │  │  └──────┘ └──────┘      │                  │
│  │• Heatmaps    │  │  ┌──────┐ ┌──────┐      │                  │
│  │• Alerts panel│  │  │Email │ │Webhook│      │                  │
│  └──────────────┘  │  └──────┘ └──────┘      │                  │
│                    └──────────────────────────┘                  │
└────────────────────────────────────────────────────────────────────┘
```

### Summary Comparison

```
┌────────────────────┬────────────────────┬──────────────────┬─────────────────────┐
│                    │ Stock Trading      │ Ad Click Tracker │ Metrics Monitoring  │
├────────────────────┼────────────────────┼──────────────────┼─────────────────────┤
│ Write Pattern      │ Burst (market hrs) │ Constant high    │ Constant high       │
│ Read Pattern       │ Real-time + hist   │ Aggregated       │ Range queries       │
│ Latency Req        │ < 1ms matching     │ < 200ms redirect │ < 500ms query       │
│ Throughput         │ 50K orders/sec     │ 100K clicks/sec  │ 1M points/sec       │
│ Consistency        │ Strong (orders)    │ Eventual (counts)│ Eventual            │
│ Core Algorithm     │ Order matching     │ Stream agg       │ Time-series storage │
│ Primary Storage    │ PostgreSQL + Redis │ ClickHouse + S3  │ TSDB + S3           │
│ Streaming          │ Kafka → WebSocket  │ Kafka → Flink    │ Kafka → TSDB Writer │
│ Special Concern    │ Risk management    │ Fraud detection  │ Alerting engine     │
│ Compression        │ N/A                │ Columnar (10:1)  │ Gorilla (10:1)      │
│ Key Data Structure │ Order Book (Heap)  │ Sliding windows  │ Inverted index +    │
│                    │                    │                  │ chunked time series │
└────────────────────┴────────────────────┴──────────────────┴─────────────────────┘
```

