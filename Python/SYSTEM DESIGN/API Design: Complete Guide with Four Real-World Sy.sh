API Design: Complete Guide with Four Real-World Systems

## Core Concepts (Applicable to All Designs)

Before diving into domain-specific APIs, let's establish foundational patterns.

---

## REST vs gRPC

```
┌─────────────────────────────────────────────────────────────────┐
│                     REST vs gRPC                                │
├──────────────────┬──────────────────────────────────────────────┤
│                  │                                              │
│   CLIENT         │              SERVER                          │
│                  │                                              │
│  ┌──────────┐    │    ┌──────────────┐                          │
│  │  REST     │───JSON/HTTP──▶  REST   │   • Human-readable      │
│  │  Client   │    │    │  Handler    │   • Cacheable            │
│  └──────────┘    │    └──────────────┘   • Browser-friendly     │
│                  │                                              │
│  ┌──────────┐    │    ┌──────────────┐                          │
│  │  gRPC    │──Protobuf/HTTP2──▶ gRPC │   • Binary (faster)     │
│  │  Client   │    │    │  Service    │   • Streaming support    │
│  └──────────┘    │    └──────────────┘   • Strongly typed       │
│                  │                                              │
└──────────────────┴──────────────────────────────────────────────┘
```

```python
# ============================================================
# REST Example (using FastAPI)
# ============================================================
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import Optional
import uvicorn

app = FastAPI()

class Product(BaseModel):
    id: Optional[int] = None
    name: str
    price: float
    stock: int

# REST follows resource-oriented URLs + HTTP verbs
@app.get("/api/v1/products/{product_id}")
async def get_product(product_id: int):
    """
    REST Characteristics:
    - Resource identified by URL: /products/{id}
    - HTTP verb defines action: GET = Read
    - JSON response body
    - Stateless: each request carries all needed info
    - Cacheable via HTTP headers (ETag, Cache-Control)
    """
    return {"id": product_id, "name": "Laptop", "price": 999.99, "stock": 50}

@app.post("/api/v1/products", status_code=201)
async def create_product(product: Product):
    return {"id": 1, **product.dict()}


# ============================================================
# gRPC Example
# ============================================================

# Step 1: Define the service in a .proto file
PROTO_DEFINITION = """
// product.proto
syntax = "proto3";

package ecommerce;

// Service definition - like an interface/contract
service ProductService {
    // Unary RPC - single request, single response
    rpc GetProduct(GetProductRequest) returns (ProductResponse);
    
    // Server streaming - client sends one request, server streams responses
    rpc ListProducts(ListProductsRequest) returns (stream ProductResponse);
    
    // Client streaming - client streams requests, server sends one response
    rpc BulkCreateProducts(stream CreateProductRequest) returns (BulkCreateResponse);
    
    // Bidirectional streaming - both sides stream
    rpc SyncInventory(stream InventoryUpdate) returns (stream InventoryStatus);
}

message GetProductRequest {
    int32 product_id = 1;
}

message ProductResponse {
    int32 id = 1;
    string name = 2;
    double price = 3;
    int32 stock = 4;
}

message ListProductsRequest {
    int32 page_size = 1;
    string page_token = 2;
    string category = 3;
}

message CreateProductRequest {
    string name = 1;
    double price = 2;
    int32 stock = 3;
}

message BulkCreateResponse {
    int32 created_count = 1;
    repeated int32 product_ids = 2;
}

message InventoryUpdate {
    int32 product_id = 1;
    int32 quantity_change = 2;
}

message InventoryStatus {
    int32 product_id = 1;
    int32 current_stock = 2;
    bool low_stock_alert = 3;
}
"""

# Step 2: Generate Python code from .proto
# Run: python -m grpc_tools.protoc -I. --python_out=. --grpc_python_out=. product.proto

# Step 3: Implement the server
import grpc
from concurrent import futures

# These would be auto-generated from the .proto file
# import product_pb2
# import product_pb2_grpc

class ProductServicer:
    """gRPC service implementation."""
    
    def GetProduct(self, request, context):
        """
        gRPC Characteristics:
        - Uses Protocol Buffers (binary serialization)
        - HTTP/2 transport (multiplexing, header compression)
        - Strongly typed via .proto contract
        - Supports streaming (server, client, bidirectional)
        - ~10x faster serialization than JSON
        """
        product_id = request.product_id
        
        if product_id <= 0:
            # gRPC has its own status codes (different from HTTP)
            context.set_code(grpc.StatusCode.INVALID_ARGUMENT)
            context.set_details(f"Invalid product ID: {product_id}")
            return product_pb2.ProductResponse()
        
        # Return protobuf message (binary, not JSON)
        return product_pb2.ProductResponse(
            id=product_id,
            name="Laptop",
            price=999.99,
            stock=50
        )
    
    def ListProducts(self, request, context):
        """Server streaming: yields multiple responses."""
        products = get_products_from_db(
            category=request.category,
            page_size=request.page_size
        )
        for product in products:
            yield product_pb2.ProductResponse(
                id=product.id,
                name=product.name,
                price=product.price,
                stock=product.stock
            )
    
    def SyncInventory(self, request_iterator, context):
        """Bidirectional streaming: real-time inventory sync."""
        for update in request_iterator:
            new_stock = process_inventory_update(
                update.product_id, 
                update.quantity_change
            )
            yield product_pb2.InventoryStatus(
                product_id=update.product_id,
                current_stock=new_stock,
                low_stock_alert=new_stock < 10
            )

def serve_grpc():
    server = grpc.server(futures.ThreadPoolExecutor(max_workers=10))
    # product_pb2_grpc.add_ProductServiceServicer_to_server(
    #     ProductServicer(), server
    # )
    server.add_insecure_port('[::]:50051')
    server.start()
    server.wait_for_termination()


# ============================================================
# When to use which?
# ============================================================
"""
┌─────────────────────────────────────────────────────────────┐
│                   Decision Matrix                           │
├─────────────────────┬──────────────┬────────────────────────┤
│ Factor              │ REST         │ gRPC                   │
├─────────────────────┼──────────────┼────────────────────────┤
│ Client type         │ Browser/Web  │ Microservice-to-       │
│                     │ Mobile apps  │ microservice            │
│ Payload format      │ JSON (text)  │ Protobuf (binary)      │
│ Performance         │ Good         │ Excellent (~10x)       │
│ Streaming           │ SSE/WebSocket│ Native bidirectional   │
│ Browser support     │ Native       │ Needs grpc-web proxy   │
│ Debugging           │ Easy (curl)  │ Needs special tools    │
│ Schema evolution    │ Manual docs  │ .proto versioning      │
│ Code generation     │ OpenAPI/     │ Built-in protoc        │
│                     │ Swagger      │                        │
│ Caching             │ HTTP caching │ Custom implementation  │
│ Load balancing      │ L7 (nginx)   │ L7 (envoy) or client  │
└─────────────────────┴──────────────┴────────────────────────┘

Typical Architecture:
  
  Browser ──REST──▶ API Gateway ──gRPC──▶ Product Service
                                 ──gRPC──▶ Order Service  
                                 ──gRPC──▶ Payment Service
                                 ──gRPC──▶ Inventory Service
"""
```

---

## Idempotency

```
┌──────────────────────────────────────────────────────────────────┐
│                    IDEMPOTENCY                                    │
│                                                                   │
│  "Doing something once or multiple times produces                │
│   the same result"                                                │
│                                                                   │
│  Client ──POST /payment──▶ Server    (network timeout)           │
│  Client ──POST /payment──▶ Server    (retry - same key)          │
│  Client ──POST /payment──▶ Server    (retry - same key)          │
│                                                                   │
│  Result: Only ONE payment is processed!                           │
│                                                                   │
│  ┌──────────────────────────────────────────┐                    │
│  │  HTTP Method Idempotency                 │                    │
│  ├──────────┬───────────┬───────────────────┤                    │
│  │ Method   │ Idempotent│ Safe              │                    │
│  ├──────────┼───────────┼───────────────────┤                    │
│  │ GET      │ ✅ Yes    │ ✅ Yes            │                    │
│  │ PUT      │ ✅ Yes    │ ❌ No             │                    │
│  │ DELETE   │ ✅ Yes    │ ❌ No             │                    │
│  │ HEAD     │ ✅ Yes    │ ✅ Yes            │                    │
│  │ POST     │ ❌ No *   │ ❌ No             │                    │
│  │ PATCH    │ ❌ No *   │ ❌ No             │                    │
│  └──────────┴───────────┴───────────────────┘                    │
│  * Can be made idempotent with idempotency keys                  │
└──────────────────────────────────────────────────────────────────┘
```

```python
import hashlib
import json
import time
import redis
from fastapi import FastAPI, Header, HTTPException, Request
from pydantic import BaseModel
from typing import Optional
import uuid

app = FastAPI()
redis_client = redis.Redis(host='localhost', port=6379, db=0)


# ============================================================
# Idempotency Key Implementation
# ============================================================

class IdempotencyStore:
    """
    Stores and retrieves idempotent operation results.
    
    Flow:
    1. Client generates unique Idempotency-Key
    2. Server checks if key exists in store
    3. If exists → return cached response (no re-processing)
    4. If not → process request, store result, return response
    
    ┌────────┐         ┌─────────┐        ┌───────┐
    │ Client │──req───▶│ Server  │──check─▶│ Redis │
    │        │         │         │◀─miss───│       │
    │        │         │         │──process─▶ DB   │
    │        │         │         │──store──▶│ Redis │
    │        │◀─resp───│         │         │       │
    └────────┘         └─────────┘        └───────┘
    
    On retry:
    ┌────────┐         ┌─────────┐        ┌───────┐
    │ Client │──req───▶│ Server  │──check─▶│ Redis │
    │        │         │         │◀──hit───│       │
    │        │◀─cached─│         │         │       │
    └────────┘         └─────────┘        └───────┘
    """
    
    def __init__(self, redis_client, ttl_seconds: int = 86400):
        self.redis = redis_client
        self.ttl = ttl_seconds  # Keep results for 24 hours
    
    def get(self, key: str) -> Optional[dict]:
        """Check if this idempotency key was already processed."""
        result = self.redis.get(f"idempotency:{key}")
        if result:
            return json.loads(result)
        return None
    
    def set(self, key: str, response: dict, status_code: int):
        """Store the result of a processed request."""
        data = {
            "response": response,
            "status_code": status_code,
            "processed_at": time.time()
        }
        self.redis.setex(
            f"idempotency:{key}",
            self.ttl,
            json.dumps(data)
        )
    
    def lock(self, key: str, timeout: int = 30) -> bool:
        """
        Prevent concurrent requests with the same key.
        Uses Redis SET NX (set if not exists) for atomic locking.
        """
        return self.redis.set(
            f"idempotency_lock:{key}",
            "locked",
            nx=True,    # Only set if key doesn't exist
            ex=timeout  # Auto-expire lock after timeout
        )
    
    def unlock(self, key: str):
        """Release the lock after processing."""
        self.redis.delete(f"idempotency_lock:{key}")


idempotency_store = IdempotencyStore(redis_client)


# ============================================================
# Idempotency Middleware / Decorator
# ============================================================

from functools import wraps

def idempotent(func):
    """
    Decorator that makes any endpoint idempotent.
    Requires 'Idempotency-Key' header.
    """
    @wraps(func)
    async def wrapper(*args, idempotency_key: str = Header(None), **kwargs):
        if not idempotency_key:
            raise HTTPException(
                status_code=400,
                detail="Idempotency-Key header is required for this operation"
            )
        
        # Step 1: Check if already processed
        cached = idempotency_store.get(idempotency_key)
        if cached:
            # Return the exact same response as the first request
            return cached["response"]
        
        # Step 2: Acquire lock to prevent concurrent duplicates
        if not idempotency_store.lock(idempotency_key):
            raise HTTPException(
                status_code=409,
                detail="A request with this idempotency key is currently being processed"
            )
        
        try:
            # Step 3: Process the request
            result = await func(*args, **kwargs)
            
            # Step 4: Store the result
            idempotency_store.set(idempotency_key, result, status_code=200)
            
            return result
        except Exception as e:
            # Don't cache errors (allow retry)
            raise
        finally:
            idempotency_store.unlock(idempotency_key)
    
    return wrapper


# ============================================================
# Usage Example: Payment API
# ============================================================

class PaymentRequest(BaseModel):
    order_id: str
    amount: float
    currency: str = "USD"
    payment_method_id: str

@app.post("/api/v1/payments")
@idempotent
async def create_payment(payment: PaymentRequest):
    """
    POST /api/v1/payments
    Headers:
        Idempotency-Key: "pay_abc123_attempt1"
    Body:
        {"order_id": "ord_123", "amount": 99.99, ...}
    
    First call  → processes payment, returns result
    Retry calls → returns cached result (no double charge)
    """
    # This only executes ONCE per idempotency key
    result = await process_payment_with_stripe(payment)
    return {
        "payment_id": f"pay_{uuid.uuid4().hex[:12]}",
        "order_id": payment.order_id,
        "amount": payment.amount,
        "status": "completed",
        "transaction_id": result.transaction_id
    }


# ============================================================
# Client-side idempotency key generation
# ============================================================

class IdempotencyKeyGenerator:
    """
    Strategies for generating idempotency keys on the client side.
    """
    
    @staticmethod
    def uuid_based() -> str:
        """Simple UUID - unique per request attempt."""
        return str(uuid.uuid4())
    
    @staticmethod
    def content_based(user_id: str, action: str, params: dict) -> str:
        """
        Deterministic key based on request content.
        Same params always produce the same key.
        Useful when client might not track UUIDs across retries.
        """
        content = f"{user_id}:{action}:{json.dumps(params, sort_keys=True)}"
        return hashlib.sha256(content.encode()).hexdigest()
    
    @staticmethod
    def composite(user_id: str, order_id: str, attempt: int = 0) -> str:
        """
        Business-logic key.
        Ties idempotency to a specific business operation.
        """
        return f"{user_id}_{order_id}_{attempt}"


# Client usage example
import requests

def make_payment_with_retry(order_id: str, amount: float, max_retries: int = 3):
    """Client-side retry with idempotency."""
    
    # Generate key ONCE, reuse for all retries
    idempotency_key = IdempotencyKeyGenerator.composite(
        user_id="user_123",
        order_id=order_id
    )
    
    for attempt in range(max_retries):
        try:
            response = requests.post(
                "https://api.example.com/api/v1/payments",
                json={"order_id": order_id, "amount": amount},
                headers={
                    "Idempotency-Key": idempotency_key,
                    "Authorization": "Bearer token_xxx"
                },
                timeout=10
            )
            
            if response.status_code in (200, 201):
                return response.json()
            elif response.status_code == 409:
                # Concurrent request in progress, wait and retry
                time.sleep(2 ** attempt)
                continue
            else:
                response.raise_for_status()
                
        except requests.exceptions.Timeout:
            # Network timeout - safe to retry with same idempotency key
            print(f"Timeout on attempt {attempt + 1}, retrying...")
            time.sleep(2 ** attempt)
            continue
        except requests.exceptions.ConnectionError:
            time.sleep(2 ** attempt)
            continue
    
    raise Exception("Payment failed after all retries")
```

---

## Pagination

```
┌────────────────────────────────────────────────────────────────┐
│                 PAGINATION STRATEGIES                          │
│                                                                │
│  1. OFFSET-BASED (Traditional)                                 │
│     GET /products?page=3&page_size=20                         │
│     ┌──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┐          │
│     │1 │2 │3 │..│20│21│..│40│41│..│60│61│..│80│..│          │
│     └──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┘          │
│     Page 1────────▶  Page 2───▶  Page 3───▶                    │
│     SKIP 0, TAKE 20  SKIP 20    SKIP 40                       │
│                                                                │
│  2. CURSOR-BASED (Efficient)                                   │
│     GET /products?cursor=eyJpZCI6NDV9&limit=20                │
│     ┌──┬──┬──────────┬──┬──┬──────────┬──┬──┐                │
│     │1 │..│    20    │21│..│    40    │41│..│                │
│     └──┴──┴────┬─────┴──┴──┴────┬─────┴──┴──┘                │
│           cursor="id:20"   cursor="id:40"                      │
│                                                                │
│  3. KEYSET-BASED (Best for large datasets)                     │
│     WHERE id > last_seen_id ORDER BY id LIMIT 20              │
└────────────────────────────────────────────────────────────────┘
```

```python
from fastapi import FastAPI, Query
from pydantic import BaseModel
from typing import List, Optional, Generic, TypeVar
import base64
import json
from datetime import datetime

app = FastAPI()
T = TypeVar('T')


# ============================================================
# 1. OFFSET-BASED PAGINATION
# ============================================================

class PaginatedResponse(BaseModel):
    """Standard offset-based pagination response."""
    data: list
    pagination: dict

@app.get("/api/v1/products")
async def list_products_offset(
    page: int = Query(1, ge=1, description="Page number"),
    page_size: int = Query(20, ge=1, le=100, description="Items per page"),
    sort_by: str = Query("created_at", description="Sort field"),
    sort_order: str = Query("desc", regex="^(asc|desc)$")
):
    """
    Offset-Based Pagination
    
    Pros:
    - Simple to implement
    - Can jump to any page directly
    - Easy to understand total count
    
    Cons:
    - Performance degrades with large offsets (OFFSET 1000000)
    - Inconsistent results if data changes between requests
      (items can be skipped or duplicated)
    - COUNT(*) can be expensive on large tables
    
    SQL: SELECT * FROM products ORDER BY created_at DESC
         LIMIT 20 OFFSET 40  -- page 3, 20 items per page
    """
    offset = (page - 1) * page_size
    
    # Database query
    # products = db.query(Product)
    #     .order_by(sort_by, sort_order)
    #     .offset(offset)
    #     .limit(page_size)
    #     .all()
    # total = db.query(Product).count()
    
    total = 1000  # Example
    products = [{"id": i, "name": f"Product {i}"} for i in range(offset+1, offset+page_size+1)]
    
    total_pages = (total + page_size - 1) // page_size
    
    return {
        "data": products,
        "pagination": {
            "current_page": page,
            "page_size": page_size,
            "total_items": total,
            "total_pages": total_pages,
            "has_next": page < total_pages,
            "has_previous": page > 1,
            # HATEOAS links
            "links": {
                "self": f"/api/v1/products?page={page}&page_size={page_size}",
                "first": f"/api/v1/products?page=1&page_size={page_size}",
                "last": f"/api/v1/products?page={total_pages}&page_size={page_size}",
                "next": f"/api/v1/products?page={page+1}&page_size={page_size}" if page < total_pages else None,
                "prev": f"/api/v1/products?page={page-1}&page_size={page_size}" if page > 1 else None,
            }
        }
    }


# ============================================================
# 2. CURSOR-BASED PAGINATION
# ============================================================

class CursorEncoder:
    """Encode/decode pagination cursors."""
    
    @staticmethod
    def encode(data: dict) -> str:
        """Convert cursor data to opaque string."""
        json_str = json.dumps(data, sort_keys=True, default=str)
        return base64.urlsafe_b64encode(json_str.encode()).decode()
    
    @staticmethod
    def decode(cursor: str) -> dict:
        """Convert opaque string back to cursor data."""
        try:
            json_str = base64.urlsafe_b64decode(cursor.encode()).decode()
            return json.loads(json_str)
        except Exception:
            raise HTTPException(status_code=400, detail="Invalid cursor")


@app.get("/api/v1/orders")
async def list_orders_cursor(
    cursor: Optional[str] = Query(None, description="Pagination cursor"),
    limit: int = Query(20, ge=1, le=100),
    direction: str = Query("next", regex="^(next|prev)$")
):
    """
    Cursor-Based Pagination (Preferred for feeds, timelines)
    
    Pros:
    - Consistent results even when data changes
    - Efficient for large datasets (no OFFSET)
    - Works well with real-time data (new items don't shift pages)
    
    Cons:
    - Cannot jump to arbitrary page
    - More complex to implement
    - Total count not readily available
    
    SQL: SELECT * FROM orders 
         WHERE (created_at, id) < ('2024-01-15 10:30:00', 456)
         ORDER BY created_at DESC, id DESC
         LIMIT 21  -- fetch one extra to check if more exist
    """
    
    # Decode cursor to get the "pointer" position
    if cursor:
        cursor_data = CursorEncoder.decode(cursor)
        last_created_at = cursor_data["created_at"]
        last_id = cursor_data["id"]
    else:
        last_created_at = None
        last_id = None
    
    # Build query based on cursor
    # query = db.query(Order).order_by(Order.created_at.desc(), Order.id.desc())
    # if last_created_at:
    #     query = query.filter(
    #         db.or_(
    #             Order.created_at < last_created_at,
    #             db.and_(
    #                 Order.created_at == last_created_at,
    #                 Order.id < last_id
    #             )
    #         )
    #     )
    # orders = query.limit(limit + 1).all()  # Fetch one extra
    
    # Simulated results
    orders = [
        {"id": 100 - i, "total": 50.0 + i, "created_at": f"2024-01-{15-i:02d}T10:30:00Z"}
        for i in range(min(limit + 1, 25))
    ]
    
    # Check if there are more results
    has_more = len(orders) > limit
    if has_more:
        orders = orders[:limit]  # Remove the extra item
    
    # Build next cursor from the last item
    next_cursor = None
    if has_more and orders:
        last_item = orders[-1]
        next_cursor = CursorEncoder.encode({
            "id": last_item["id"],
            "created_at": last_item["created_at"]
        })
    
    # Build previous cursor from the first item
    prev_cursor = None
    if cursor and orders:
        first_item = orders[0]
        prev_cursor = CursorEncoder.encode({
            "id": first_item["id"],
            "created_at": first_item["created_at"]
        })
    
    return {
        "data": orders,
        "pagination": {
            "next_cursor": next_cursor,
            "prev_cursor": prev_cursor,
            "has_more": has_more,
            "limit": limit
        }
    }


# ============================================================
# 3. KEYSET PAGINATION (for sorted data)
# ============================================================

@app.get("/api/v1/products/search")
async def search_products_keyset(
    after_id: Optional[int] = Query(None, description="Return items after this ID"),
    after_score: Optional[float] = Query(None, description="Return items after this relevance score"),
    limit: int = Query(20, ge=1, le=100),
    q: str = Query(..., description="Search query")
):
    """
    Keyset Pagination (for pre-sorted data like search results)
    
    SQL: SELECT * FROM products 
         WHERE (relevance_score, id) < (0.95, 234)
         AND search_vector @@ to_tsquery('laptop')
         ORDER BY relevance_score DESC, id DESC
         LIMIT 20
    
    Best for: Search results ranked by score, feeds sorted by time
    """
    
    # Build query
    # query = db.query(Product).filter(Product.search_vector.match(q))
    # if after_score is not None:
    #     query = query.filter(
    #         db.or_(
    #             Product.relevance_score < after_score,
    #             db.and_(
    #                 Product.relevance_score == after_score,
    #                 Product.id < after_id
    #             )
    #         )
    #     )
    # results = query.order_by(
    #     Product.relevance_score.desc(), Product.id.desc()
    # ).limit(limit + 1).all()
    
    results = [{"id": i, "name": f"Result {i}", "score": 0.99 - i*0.01} for i in range(limit+1)]
    
    has_more = len(results) > limit
    results = results[:limit]
    
    return {
        "data": results,
        "pagination": {
            "has_more": has_more,
            "next_params": {
                "after_id": results[-1]["id"],
                "after_score": results[-1]["score"]
            } if has_more else None
        }
    }
```

---

## Rate Limiting

```
┌────────────────────────────────────────────────────────────────┐
│                    RATE LIMITING                                │
│                                                                │
│  Algorithms:                                                    │
│                                                                │
│  1. Fixed Window          2. Sliding Window                     │
│  ┌─────┬─────┬─────┐    ┌──────────────────┐                  │
│  │ 0-1m│ 1-2m│ 2-3m│    │   ◀──1 minute──▶ │                  │
│  │ 95  │ 100 │  5  │    │  ═══════════════  │                  │
│  │ req │ req │ req │    │  counts overlap   │                  │
│  └─────┴─────┴─────┘    └──────────────────┘                  │
│                                                                │
│  3. Token Bucket          4. Leaky Bucket                       │
│  ┌─────────┐             ┌─────────┐                           │
│  │ ● ● ● ● │ tokens     │ ● ● ● ● │ queue                    │
│  │ ● ●     │ refill     │ ● ●     │                           │
│  │         │ at rate R   │    ▼    │ drain at                  │
│  └─────────┘             └────┼────┘ constant rate             │
│                               ▼                                 │
│                          processed                              │
└────────────────────────────────────────────────────────────────┘
```

```python
import time
import redis
from fastapi import FastAPI, Request, HTTPException
from fastapi.responses import JSONResponse
from starlette.middleware.base import BaseHTTPMiddleware
from typing import Optional
import math

app = FastAPI()
redis_client = redis.Redis(host='localhost', port=6379, db=0)


# ============================================================
# Token Bucket Algorithm (Most commonly used)
# ============================================================

class TokenBucketRateLimiter:
    """
    Token Bucket: Allows bursts while maintaining average rate.
    
    ┌──────────────────────────────────────────────┐
    │  Bucket (capacity=10)                        │
    │  ┌──┬──┬──┬──┬──┬──┬──┬──┬──┬──┐           │
    │  │● │● │● │● │● │● │  │  │  │  │           │
    │  └──┴──┴──┴──┴──┴──┴──┴──┴──┴──┘           │
    │   6 tokens available                         │
    │   Refill rate: 2 tokens/second               │
    │                                              │
    │  Request arrives:                             │
    │  - If tokens > 0: consume 1 token → ALLOW    │
    │  - If tokens = 0: REJECT (429)               │
    └──────────────────────────────────────────────┘
    """
    
    def __init__(self, redis_client, capacity: int, refill_rate: float):
        """
        Args:
            capacity: Maximum tokens (burst size)
            refill_rate: Tokens added per second
        """
        self.redis = redis_client
        self.capacity = capacity
        self.refill_rate = refill_rate
    
    def is_allowed(self, key: str, tokens_needed: int = 1) -> dict:
        """
        Check if request is allowed, atomically using Lua script.
        
        Using Lua script ensures atomicity in Redis
        (no race conditions between read and write).
        """
        lua_script = """
        local key = KEYS[1]
        local capacity = tonumber(ARGV[1])
        local refill_rate = tonumber(ARGV[2])
        local now = tonumber(ARGV[3])
        local tokens_needed = tonumber(ARGV[4])
        
        -- Get current state
        local bucket = redis.call('hmget', key, 'tokens', 'last_refill')
        local tokens = tonumber(bucket[1]) or capacity
        local last_refill = tonumber(bucket[2]) or now
        
        -- Calculate tokens to add since last request
        local elapsed = now - last_refill
        local new_tokens = elapsed * refill_rate
        tokens = math.min(capacity, tokens + new_tokens)
        
        -- Try to consume tokens
        local allowed = 0
        if tokens >= tokens_needed then
            tokens = tokens - tokens_needed
            allowed = 1
        end
        
        -- Update state
        redis.call('hmset', key, 'tokens', tokens, 'last_refill', now)
        redis.call('expire', key, math.ceil(capacity / refill_rate) * 2)
        
        return {allowed, math.floor(tokens), math.ceil((tokens_needed - tokens) / refill_rate)}
        """
        
        now = time.time()
        result = self.redis.eval(
            lua_script, 1, key,
            self.capacity, self.refill_rate, now, tokens_needed
        )
        
        allowed, remaining, retry_after = result
        
        return {
            "allowed": bool(allowed),
            "remaining": int(remaining),
            "limit": self.capacity,
            "retry_after": max(0, int(retry_after)) if not allowed else 0,
            "reset": int(now + (self.capacity - remaining) / self.refill_rate)
        }


# ============================================================
# Sliding Window Counter
# ============================================================

class SlidingWindowRateLimiter:
    """
    Sliding Window: More accurate than fixed window.
    
    Time: ──────|──────────────|──────────────|──────
                t-2min         t-1min          now
    
    Current window (t-1min to now): 30 requests
    Previous window (t-2min to t-1min): 50 requests
    
    Weighted count = prev * overlap% + current
                   = 50 * 0.25 + 30 = 42.5
    
    If limit = 100 → ALLOW (42.5 < 100)
    """
    
    def __init__(self, redis_client, limit: int, window_seconds: int):
        self.redis = redis_client
        self.limit = limit
        self.window = window_seconds
    
    def is_allowed(self, key: str) -> dict:
        now = time.time()
        current_window = int(now // self.window)
        previous_window = current_window - 1
        
        # Position within current window (0.0 to 1.0)
        window_position = (now % self.window) / self.window
        
        pipe = self.redis.pipeline()
        current_key = f"ratelimit:{key}:{current_window}"
        previous_key = f"ratelimit:{key}:{previous_window}"
        
        pipe.get(current_key)
        pipe.get(previous_key)
        results = pipe.execute()
        
        current_count = int(results[0] or 0)
        previous_count = int(results[1] or 0)
        
        # Weighted count: more weight on current window as time progresses
        weighted_count = previous_count * (1 - window_position) + current_count
        
        if weighted_count < self.limit:
            # Increment current window counter
            pipe = self.redis.pipeline()
            pipe.incr(current_key)
            pipe.expire(current_key, self.window * 2)
            pipe.execute()
            
            return {
                "allowed": True,
                "remaining": max(0, int(self.limit - weighted_count - 1)),
                "limit": self.limit,
                "reset": int((current_window + 1) * self.window)
            }
        
        return {
            "allowed": False,
            "remaining": 0,
            "limit": self.limit,
            "retry_after": int((current_window + 1) * self.window - now),
            "reset": int((current_window + 1) * self.window)
        }


# ============================================================
# Rate Limiting Middleware
# ============================================================

class RateLimitConfig:
    """Per-endpoint rate limit configuration."""
    
    # Different limits for different endpoints and user tiers
    LIMITS = {
        "default": {"capacity": 100, "refill_rate": 10},      # 100 burst, 10/sec sustained
        "/api/v1/search": {"capacity": 30, "refill_rate": 5},  # Search is expensive
        "/api/v1/payments": {"capacity": 10, "refill_rate": 2}, # Payments are sensitive
    }
    
    TIER_MULTIPLIERS = {
        "free": 1.0,
        "basic": 2.0,
        "premium": 5.0,
        "enterprise": 20.0,
    }


class RateLimitMiddleware(BaseHTTPMiddleware):
    """
    Middleware that applies rate limiting to all requests.
    
    Response Headers:
    - X-RateLimit-Limit: Maximum requests allowed
    - X-RateLimit-Remaining: Requests remaining in window
    - X-RateLimit-Reset: Unix timestamp when limit resets
    - Retry-After: Seconds to wait (only on 429)
    """
    
    def __init__(self, app):
        super().__init__(app)
        self.default_limiter = TokenBucketRateLimiter(
            redis_client, capacity=100, refill_rate=10
        )
        # Create per-endpoint limiters
        self.endpoint_limiters = {}
        for path, config in RateLimitConfig.LIMITS.items():
            if path != "default":
                self.endpoint_limiters[path] = TokenBucketRateLimiter(
                    redis_client, **config
                )
    
    async def dispatch(self, request: Request, call_next):
        # Identify the client
        client_key = self._get_client_key(request)
        
        # Get appropriate limiter for this endpoint
        limiter = self.endpoint_limiters.get(
            request.url.path, self.default_limiter
        )
        
        # Check rate limit
        result = limiter.is_allowed(client_key)
        
        if not result["allowed"]:
            return JSONResponse(
                status_code=429,
                content={
                    "error": "rate_limit_exceeded",
                    "message": "Too many requests. Please slow down.",
                    "retry_after": result["retry_after"]
                },
                headers={
                    "X-RateLimit-Limit": str(result["limit"]),
                    "X-RateLimit-Remaining": "0",
                    "X-RateLimit-Reset": str(result["reset"]),
                    "Retry-After": str(result["retry_after"])
                }
            )
        
        # Process request
        response = await call_next(request)
        
        # Add rate limit headers to response
        response.headers["X-RateLimit-Limit"] = str(result["limit"])
        response.headers["X-RateLimit-Remaining"] = str(result["remaining"])
        response.headers["X-RateLimit-Reset"] = str(result["reset"])
        
        return response
    
    def _get_client_key(self, request: Request) -> str:
        """
        Identify client for rate limiting.
        Priority: API Key > User ID > IP Address
        """
        # Check for API key
        api_key = request.headers.get("X-API-Key")
        if api_key:
            return f"api_key:{api_key}"
        
        # Check for authenticated user
        auth = request.headers.get("Authorization")
        if auth:
            user_id = decode_token(auth)  # Extract user ID from JWT
            return f"user:{user_id}"
        
        # Fall back to IP
        client_ip = request.client.host
        forwarded = request.headers.get("X-Forwarded-For")
        if forwarded:
            client_ip = forwarded.split(",")[0].strip()
        
        return f"ip:{client_ip}"


# Register middleware
app.add_middleware(RateLimitMiddleware)
```

---

## API Versioning

```
┌─────────────────────────────────────────────────────────────────┐
│                    API VERSIONING STRATEGIES                     │
│                                                                  │
│  1. URL Path Versioning (Most Common)                           │
│     GET /api/v1/products                                         │
│     GET /api/v2/products                                         │
│                                                                  │
│  2. Header Versioning                                            │
│     GET /api/products                                            │
│     Accept: application/vnd.myapp.v2+json                       │
│                                                                  │
│  3. Query Parameter Versioning                                   │
│     GET /api/products?version=2                                  │
│                                                                  │
│  4. Content Negotiation                                          │
│     Accept: application/json; version=2                          │
│                                                                  │
│  ┌──────────────────┬──────────────────────────────────┐        │
│  │ Strategy         │ Trade-offs                       │        │
│  ├──────────────────┼──────────────────────────────────┤        │
│  │ URL Path         │ ✅ Clear, cacheable, easy to use │        │
│  │                  │ ❌ URL pollution                  │        │
│  │ Header           │ ✅ Clean URLs                    │        │
│  │                  │ ❌ Hidden, harder to test         │        │
│  │ Query Param      │ ✅ Easy to use                   │        │
│  │                  │ ❌ Optional = defaults needed     │        │
│  └──────────────────┴──────────────────────────────────┘        │
└─────────────────────────────────────────────────────────────────┘
```

```python
from fastapi import FastAPI, APIRouter, Header, Request
from fastapi.responses import JSONResponse
from enum import Enum
from typing import Optional
from pydantic import BaseModel

# ============================================================
# Strategy 1: URL Path Versioning (Recommended)
# ============================================================

app = FastAPI(title="E-Commerce API")

# Version 1 Router
v1_router = APIRouter(prefix="/api/v1", tags=["v1"])

class ProductV1(BaseModel):
    id: int
    name: str
    price: float
    # V1: simple flat structure

@v1_router.get("/products/{product_id}")
async def get_product_v1(product_id: int):
    """V1: Returns flat product structure."""
    return ProductV1(id=product_id, name="Laptop", price=999.99)


# Version 2 Router (with breaking changes)
v2_router = APIRouter(prefix="/api/v2", tags=["v2"])

class MoneyV2(BaseModel):
    amount: float
    currency: str

class ProductV2(BaseModel):
    id: int
    name: str
    price: MoneyV2            # Breaking change: price is now an object
    slug: str                 # New field
    images: list[str]         # New field
    metadata: dict            # New field

@v2_router.get("/products/{product_id}")
async def get_product_v2(product_id: int):
    """V2: Returns structured product with money object."""
    return ProductV2(
        id=product_id,
        name="Laptop",
        price=MoneyV2(amount=999.99, currency="USD"),
        slug="laptop-pro-2024",
        images=["https://cdn.example.com/laptop1.jpg"],
        metadata={"brand": "TechCo", "weight_kg": 1.5}
    )

app.include_router(v1_router)
app.include_router(v2_router)


# ============================================================
# Strategy 2: Header-Based Versioning
# ============================================================

class HeaderVersionMiddleware(BaseHTTPMiddleware):
    """Route requests based on Accept header version."""
    
    SUPPORTED_VERSIONS = {"v1", "v2", "v3"}
    DEFAULT_VERSION = "v2"
    
    async def dispatch(self, request: Request, call_next):
        # Extract version from Accept header
        accept = request.headers.get("Accept", "")
        
        version = self.DEFAULT_VERSION
        
        # Parse: application/vnd.myapp.v2+json
        if "vnd.myapp." in accept:
            try:
                version_part = accept.split("vnd.myapp.")[1].split("+")[0]
                if version_part in self.SUPPORTED_VERSIONS:
                    version = version_part
            except (IndexError, ValueError):
                pass
        
        # Inject version into request state
        request.state.api_version = version
        
        response = await call_next(request)
        response.headers["X-API-Version"] = version
        
        # Deprecation warnings
        if version == "v1":
            response.headers["Deprecation"] = "true"
            response.headers["Sunset"] = "2025-06-01T00:00:00Z"
            response.headers["Link"] = '</api/v2/docs>; rel="successor-version"'
        
        return response


@app.get("/api/products/{product_id}")
async def get_product_header_versioned(product_id: int, request: Request):
    """
    Single endpoint, behavior varies by header.
    
    curl -H "Accept: application/vnd.myapp.v1+json" /api/products/1
    curl -H "Accept: application/vnd.myapp.v2+json" /api/products/1
    """
    version = getattr(request.state, 'api_version', 'v2')
    
    if version == "v1":
        return {"id": product_id, "name": "Laptop", "price": 999.99}
    elif version == "v2":
        return {
            "id": product_id,
            "name": "Laptop",
            "price": {"amount": 999.99, "currency": "USD"},
            "slug": "laptop-pro-2024"
        }


# ============================================================
# Version Deprecation & Sunset Management
# ============================================================

class APIVersion:
    """Manage API version lifecycle."""
    
    def __init__(self, version: str, status: str, sunset_date: Optional[str] = None):
        self.version = version
        self.status = status  # "active", "deprecated", "sunset"
        self.sunset_date = sunset_date

VERSIONS = {
    "v1": APIVersion("v1", "deprecated", "2025-06-01"),
    "v2": APIVersion("v2", "active"),
    "v3": APIVersion("v3", "active"),
}

class VersionDeprecationMiddleware(BaseHTTPMiddleware):
    """Warn clients about deprecated versions."""
    
    async def dispatch(self, request: Request, call_next):
        # Extract version from URL
        path = request.url.path
        version = None
        for v in VERSIONS:
            if f"/api/{v}/" in path:
                version = v
                break
        
        if version and VERSIONS[version].status == "sunset":
            return JSONResponse(
                status_code=410,  # Gone
                content={
                    "error": "api_version_sunset",
                    "message": f"API {version} has been sunset. Please upgrade to v3.",
                    "migration_guide": "https://docs.example.com/migration/v2-to-v3"
                }
            )
        
        response = await call_next(request)
        
        if version and VERSIONS[version].status == "deprecated":
            response.headers["Deprecation"] = "true"
            response.headers["Sunset"] = VERSIONS[version].sunset_date
            response.headers["X-Deprecation-Notice"] = (
                f"API {version} is deprecated and will be removed on "
                f"{VERSIONS[version].sunset_date}. "
                f"Please migrate to v3."
            )
        
        return response
```

---

# 19. E-Commerce API Design

```
┌─────────────────────────────────────────────────────────────────────┐
│                     E-COMMERCE API ARCHITECTURE                     │
│                                                                     │
│  ┌──────────┐     ┌──────────────┐     ┌─────────────────────┐     │
│  │  Client   │────▶│  API Gateway │────▶│  Service Mesh       │     │
│  │  (Web/    │     │  (Auth,      │     │                     │     │
│  │   Mobile) │     │   Rate Limit,│     │  ┌──────────────┐  │     │
│  └──────────┘     │   Routing)   │     │  │ Product Svc  │  │     │
│                    └──────────────┘     │  │ /products    │  │     │
│                                         │  └──────────────┘  │     │
│  Resources:                             │  ┌──────────────┐  │     │
│  • Products                             │  │ Cart Svc     │  │     │
│  • Categories                           │  │ /carts       │  │     │
│  • Cart                                 │  └──────────────┘  │     │
│  • Orders                               │  ┌──────────────┐  │     │
│  • Payments                             │  │ Order Svc    │  │     │
│  • Users                                │  │ /orders      │  │     │
│  • Reviews                              │  └──────────────┘  │     │
│  • Inventory                            │  ┌──────────────┐  │     │
│  • Addresses                            │  │ Payment Svc  │  │     │
│  • Wishlists                            │  │ /payments    │  │     │
│                                         │  └──────────────┘  │     │
│                                         └─────────────────────┘     │
└─────────────────────────────────────────────────────────────────────┘
```

```python
from fastapi import FastAPI, HTTPException, Depends, Query, Header, Path
from pydantic import BaseModel, Field, validator
from typing import List, Optional, Dict
from enum import Enum
from datetime import datetime
import uuid

app = FastAPI(
    title="E-Commerce API",
    version="2.0.0",
    description="Complete E-Commerce Platform API"
)


# ============================================================
# DATA MODELS
# ============================================================

class Money(BaseModel):
    amount: float = Field(..., ge=0, description="Amount in smallest unit")
    currency: str = Field(default="USD", regex="^[A-Z]{3}$")

class Address(BaseModel):
    street: str
    city: str
    state: str
    zip_code: str
    country: str = "US"

class ProductStatus(str, Enum):
    ACTIVE = "active"
    DRAFT = "draft"
    ARCHIVED = "archived"
    OUT_OF_STOCK = "out_of_stock"

class OrderStatus(str, Enum):
    PENDING = "pending"
    CONFIRMED = "confirmed"
    PROCESSING = "processing"
    SHIPPED = "shipped"
    DELIVERED = "delivered"
    CANCELLED = "cancelled"
    REFUNDED = "refunded"

class PaymentStatus(str, Enum):
    PENDING = "pending"
    AUTHORIZED = "authorized"
    CAPTURED = "captured"
    FAILED = "failed"
    REFUNDED = "refunded"


# ============================================================
# PRODUCT APIs
# ============================================================

class CreateProductRequest(BaseModel):
    name: str = Field(..., min_length=1, max_length=255)
    description: str = Field(..., max_length=5000)
    price: Money
    compare_at_price: Optional[Money] = None
    sku: str = Field(..., regex="^[A-Z0-9-]+$")
    category_id: int
    tags: List[str] = []
    images: List[str] = []
    variants: List[dict] = []
    metadata: Dict[str, str] = {}

class ProductResponse(BaseModel):
    id: int
    name: str
    slug: str
    description: str
    price: Money
    compare_at_price: Optional[Money]
    sku: str
    status: ProductStatus
    category: dict
    tags: List[str]
    images: List[str]
    average_rating: float
    review_count: int
    stock_quantity: int
    created_at: datetime
    updated_at: datetime

class ProductSearchFilters(BaseModel):
    q: Optional[str] = None
    category_id: Optional[int] = None
    min_price: Optional[float] = None
    max_price: Optional[float] = None
    tags: Optional[List[str]] = None
    in_stock: Optional[bool] = None
    rating_min: Optional[float] = None
    sort_by: str = "relevance"  # relevance, price_asc, price_desc, rating, newest
    

# ---- Product Endpoints ----

@app.post("/api/v2/products", status_code=201, tags=["Products"])
async def create_product(product: CreateProductRequest):
    """
    Create a new product.
    
    Required: seller or admin authentication
    Idempotency: Use SKU as natural idempotency key
    """
    return {
        "id": 1,
        "slug": "premium-laptop-2024",
        **product.dict(),
        "status": "draft",
        "average_rating": 0.0,
        "review_count": 0,
        "stock_quantity": 0,
        "created_at": datetime.utcnow(),
        "updated_at": datetime.utcnow()
    }

@app.get("/api/v2/products", tags=["Products"])
async def list_products(
    q: Optional[str] = Query(None, description="Search query"),
    category_id: Optional[int] = Query(None),
    min_price: Optional[float] = Query(None, ge=0),
    max_price: Optional[float] = Query(None, ge=0),
    tags: Optional[str] = Query(None, description="Comma-separated tags"),
    in_stock: Optional[bool] = Query(None),
    sort_by: str = Query("relevance", regex="^(relevance|price_asc|price_desc|rating|newest)$"),
    cursor: Optional[str] = Query(None),
    limit: int = Query(20, ge=1, le=100)
):
    """
    Search and list products with filtering, sorting, and pagination.
    
    Examples:
        GET /api/v2/products?q=laptop&min_price=500&max_price=2000&sort_by=price_asc
        GET /api/v2/products?category_id=5&in_stock=true&limit=50
        GET /api/v2/products?tags=electronics,sale&cursor=eyJpZCI6MTAwfQ
    """
    products = [
        {
            "id": i,
            "name": f"Product {i}",
            "slug": f"product-{i}",
            "price": {"amount": 99.99 + i, "currency": "USD"},
            "average_rating": 4.5,
            "review_count": 128,
            "stock_quantity": 50,
            "images": [f"https://cdn.example.com/product-{i}.jpg"],
        }
        for i in range(1, limit + 1)
    ]
    
    return {
        "data": products,
        "pagination": {
            "next_cursor": "eyJpZCI6MjB9",
            "has_more": True,
            "limit": limit
        },
        "facets": {
            "categories": [
                {"id": 1, "name": "Electronics", "count": 150},
                {"id": 2, "name": "Clothing", "count": 89}
            ],
            "price_ranges": [
                {"min": 0, "max": 50, "count": 45},
                {"min": 50, "max": 100, "count": 78},
                {"min": 100, "max": 500, "count": 120}
            ],
            "ratings": [
                {"stars": 5, "count": 30},
                {"stars": 4, "count": 85}
            ]
        }
    }

@app.get("/api/v2/products/{product_id}", tags=["Products"])
async def get_product(product_id: int = Path(..., ge=1)):
    """Get detailed product information."""
    return {
        "id": product_id,
        "name": "Premium Laptop 2024",
        "slug": "premium-laptop-2024",
        "description": "High-performance laptop...",
        "price": {"amount": 999.99, "currency": "USD"},
        "compare_at_price": {"amount": 1299.99, "currency": "USD"},
        "sku": "LAP-PRO-2024",
        "status": "active",
        "category": {"id": 1, "name": "Electronics", "path": "Electronics > Laptops"},
        "tags": ["electronics", "laptop", "sale"],
        "images": [
            {"url": "https://cdn.example.com/laptop1.jpg", "alt": "Front view", "position": 1},
            {"url": "https://cdn.example.com/laptop2.jpg", "alt": "Side view", "position": 2}
        ],
        "variants": [
            {"id": 1, "name": "8GB RAM / 256GB SSD", "price": {"amount": 999.99, "currency": "USD"}, "stock": 25},
            {"id": 2, "name": "16GB RAM / 512GB SSD", "price": {"amount": 1299.99, "currency": "USD"}, "stock": 15}
        ],
        "average_rating": 4.7,
        "review_count": 342,
        "stock_quantity": 40,
        "created_at": "2024-01-15T10:30:00Z",
        "updated_at": "2024-01-20T14:00:00Z"
    }

@app.put("/api/v2/products/{product_id}", tags=["Products"])
async def update_product(product_id: int, product: CreateProductRequest):
    """Full update of a product (idempotent)."""
    pass

@app.patch("/api/v2/products/{product_id}", tags=["Products"])
async def partial_update_product(product_id: int, updates: dict):
    """
    Partial update.
    
    PATCH /api/v2/products/1
    {"price": {"amount": 899.99, "currency": "USD"}, "status": "active"}
    """
    pass

@app.delete("/api/v2/products/{product_id}", status_code=204, tags=["Products"])
async def delete_product(product_id: int):
    """Soft delete a product (idempotent)."""
    pass

@app.get("/api/v2/products/{product_id}/reviews", tags=["Reviews"])
async def get_product_reviews(
    product_id: int,
    rating: Optional[int] = Query(None, ge=1, le=5),
    sort_by: str = Query("newest", regex="^(newest|highest|lowest|helpful)$"),
    cursor: Optional[str] = None,
    limit: int = Query(10, ge=1, le=50)
):
    """Get reviews for a specific product with filtering."""
    return {
        "data": [
            {
                "id": 1,
                "user": {"id": 42, "name": "John D.", "verified_purchase": True},
                "rating": 5,
                "title": "Great laptop!",
                "body": "Exceeded my expectations...",
                "helpful_count": 15,
                "images": [],
                "created_at": "2024-01-18T09:00:00Z",
                "seller_response": {
                    "body": "Thank you for your review!",
                    "responded_at": "2024-01-19T10:00:00Z"
                }
            }
        ],
        "summary": {
            "average_rating": 4.7,
            "total_reviews": 342,
            "rating_distribution": {5: 200, 4: 80, 3: 35, 2: 17, 1: 10}
        },
        "pagination": {"next_cursor": "abc123", "has_more": True}
    }


# ============================================================
# CART APIs
# ============================================================

class AddToCartRequest(BaseModel):
    product_id: int
    variant_id: Optional[int] = None
    quantity: int = Field(..., ge=1, le=99)

class UpdateCartItemRequest(BaseModel):
    quantity: int = Field(..., ge=0, le=99)  # 0 = remove

@app.get("/api/v2/cart", tags=["Cart"])
async def get_cart():
    """
    Get current user's cart.
    Cart is identified by authenticated user or session token.
    """
    return {
        "id": "cart_abc123",
        "items": [
            {
                "id": "item_1",
                "product": {
                    "id": 1,
                    "name": "Premium Laptop",
                    "image": "https://cdn.example.com/laptop1.jpg",
                    "price": {"amount": 999.99, "currency": "USD"},
                    "stock_available": 25
                },
                "variant": {"id": 1, "name": "8GB RAM / 256GB SSD"},
                "quantity": 2,
                "line_total": {"amount": 1999.98, "currency": "USD"}
            }
        ],
        "summary": {
            "subtotal": {"amount": 1999.98, "currency": "USD"},
            "discount": {"amount": 100.00, "currency": "USD"},
            "tax_estimate": {"amount": 159.99, "currency": "USD"},
            "shipping_estimate": {"amount": 0.00, "currency": "USD"},
            "total": {"amount": 2059.97, "currency": "USD"},
            "item_count": 2,
            "applied_coupons": ["SAVE100"]
        },
        "warnings": [
            # Real-time stock warnings
            # {"type": "low_stock", "item_id": "item_1", "message": "Only 3 left in stock"}
        ]
    }

@app.post("/api/v2/cart/items", status_code=201, tags=["Cart"])
async def add_to_cart(item: AddToCartRequest):
    """
    Add item to cart. 
    
    Idempotency consideration: Adding same product again should
    increase quantity, not create duplicate line item.
    """
    pass

@app.patch("/api/v2/cart/items/{item_id}", tags=["Cart"])
async def update_cart_item(item_id: str, update: UpdateCartItemRequest):
    """Update quantity of a cart item. Set to 0 to remove."""
    pass

@app.delete("/api/v2/cart/items/{item_id}", status_code=204, tags=["Cart"])
async def remove_from_cart(item_id: str):
    """Remove item from cart."""
    pass

@app.post("/api/v2/cart/coupons", tags=["Cart"])
async def apply_coupon(coupon_code: str):
    """Apply a coupon/promo code to the cart."""
    pass


# ============================================================
# ORDER APIs (Complex State Machine)
# ============================================================

"""
Order State Machine:
                  ┌──────────┐
                  │ PENDING  │ (created, awaiting payment)
                  └────┬─────┘
                       │ payment_authorized
                  ┌────▼─────┐
        ┌────────│CONFIRMED │
        │         └────┬─────┘
        │              │ processing_started
        │         ┌────▼──────┐
        │         │PROCESSING │ (picking, packing)
        │         └────┬──────┘
        │              │ shipped
        │         ┌────▼──────┐
        │         │  SHIPPED  │
        │         └────┬──────┘
        │              │ delivered
        │         ┌────▼──────┐
        │         │ DELIVERED │
  cancel│         └───────────┘
        │
   ┌────▼──────┐
   │ CANCELLED │
   └───────────┘
"""

class CreateOrderRequest(BaseModel):
    """Checkout request - creates order from cart."""
    shipping_address_id: int
    billing_address_id: Optional[int] = None  # Defaults to shipping
    payment_method_id: str
    shipping_method: str = "standard"  # standard, express, overnight
    notes: Optional[str] = None
    coupon_codes: List[str] = []

@app.post("/api/v2/orders", status_code=201, tags=["Orders"])
async def create_order(
    order: CreateOrderRequest,
    idempotency_key: str = Header(..., alias="Idempotency-Key")
):
    """
    Create order (checkout).
    
    This is a complex operation that:
    1. Validates cart items are still in stock
    2. Reserves inventory
    3. Calculates final pricing (tax, shipping)
    4. Creates order record
    5. Initiates payment authorization
    
    MUST be idempotent (network retries shouldn't create duplicate orders).
    
    Headers:
        Idempotency-Key: checkout_user123_1705334400
    """
    return {
        "id": "ord_abc123",
        "order_number": "ORD-2024-00001",
        "status": "pending",
        "items": [
            {
                "product_id": 1,
                "product_name": "Premium Laptop",
                "variant": "8GB RAM / 256GB SSD",
                "quantity": 2,
                "unit_price": {"amount": 999.99, "currency": "USD"},
                "line_total": {"amount": 1999.98, "currency": "USD"}
            }
        ],
        "pricing": {
            "subtotal": {"amount": 1999.98, "currency": "USD"},
            "discount": {"amount": 100.00, "currency": "USD"},
            "tax": {"amount": 159.99, "currency": "USD"},
            "shipping": {"amount": 0.00, "currency": "USD"},
            "total": {"amount": 2059.97, "currency": "USD"}
        },
        "shipping": {
            "method": "standard",
            "estimated_delivery": "2024-01-25",
            "address": {
                "street": "123 Main St",
                "city": "San Francisco",
                "state": "CA",
                "zip_code": "94105"
            }
        },
        "payment": {
            "status": "authorized",
            "method": "visa_ending_4242"
        },
        "created_at": "2024-01-20T15:30:00Z"
    }

@app.get("/api/v2/orders", tags=["Orders"])
async def list_user_orders(
    status: Optional[OrderStatus] = None,
    cursor: Optional[str] = None,
    limit: int = Query(20, ge=1, le=50)
):
    """List authenticated user's orders."""
    pass

@app.get("/api/v2/orders/{order_id}", tags=["Orders"])
async def get_order(order_id: str):
    """Get detailed order information including timeline."""
    return {
        "id": order_id,
        "order_number": "ORD-2024-00001",
        "status": "shipped",
        "items": [...],
        "pricing": {...},
        "timeline": [
            {"status": "pending", "timestamp": "2024-01-20T15:30:00Z"},
            {"status": "confirmed", "timestamp": "2024-01-20T15:30:05Z", "note": "Payment authorized"},
            {"status": "processing", "timestamp": "2024-01-20T16:00:00Z"},
            {"status": "shipped", "timestamp": "2024-01-21T10:00:00Z",
             "tracking": {"carrier": "UPS", "tracking_number": "1Z999AA10123456784",
                         "tracking_url": "https://ups.com/track/1Z999AA10123456784"}}
        ],
        "tracking": {
            "carrier": "UPS",
            "tracking_number": "1Z999AA10123456784",
            "status": "in_transit",
            "estimated_delivery": "2024-01-25",
            "events": [
                {"timestamp": "2024-01-22T08:00:00Z", "location": "Memphis, TN", "description": "In transit"},
                {"timestamp": "2024-01-21T10:00:00Z", "location": "San Francisco, CA", "description": "Picked up"}
            ]
        }
    }

@app.post("/api/v2/orders/{order_id}/cancel", tags=["Orders"])
async def cancel_order(order_id: str, reason: Optional[str] = None):
    """
    Cancel an order.
    Only allowed if status is 'pending' or 'confirmed'.
    Triggers payment refund.
    """
    pass

@app.post("/api/v2/orders/{order_id}/return", tags=["Orders"])
async def request_return(order_id: str, items: List[dict], reason: str):
    """Request a return for delivered order items."""
    pass


# ============================================================
# PAYMENT APIs
# ============================================================

class CreatePaymentRequest(BaseModel):
    order_id: str
    payment_method_id: str
    amount: Money
    save_payment_method: bool = False

@app.post("/api/v2/payments", tags=["Payments"])
async def create_payment(
    payment: CreatePaymentRequest,
    idempotency_key: str = Header(...)
):
    """
    Process payment for an order.
    
    Flow: Authorize → Capture (two-step for e-commerce)
    
    MUST be idempotent to prevent double charges.
    """
    return {
        "id": "pay_xyz789",
        "order_id": payment.order_id,
        "amount": payment.amount.dict(),
        "status": "authorized",
        "payment_method": {
            "type": "card",
            "brand": "visa",
            "last_four": "4242",
            "exp_month": 12,
            "exp_year": 2025
        },
        "authorization_code": "AUTH_123456",
        "created_at": "2024-01-20T15:30:05Z"
    }

@app.post("/api/v2/payments/{payment_id}/capture", tags=["Payments"])
async def capture_payment(payment_id: str, amount: Optional[Money] = None):
    """
    Capture an authorized payment (when order ships).
    Amount can be less than authorized (partial capture).
    """
    pass

@app.post("/api/v2/payments/{payment_id}/refund", tags=["Payments"])
async def refund_payment(
    payment_id: str,
    amount: Optional[Money] = None,  # None = full refund
    reason: str = "customer_request",
    idempotency_key: str = Header(...)
):
    """Process full or partial refund."""
    pass

@app.get("/api/v2/users/me/payment-methods", tags=["Payments"])
async def list_payment_methods():
    """List saved payment methods for the user."""
    return {
        "data": [
            {
                "id": "pm_1",
                "type": "card",
                "brand": "visa",
                "last_four": "4242",
                "exp_month": 12,
                "exp_year": 2025,
                "is_default": True
            }
        ]
    }


# ============================================================
# INVENTORY APIs (Internal / Admin)
# ============================================================

@app.get("/api/v2/inventory/{product_id}", tags=["Inventory"])
async def get_inventory(product_id: int):
    """Get inventory levels across warehouses."""
    return {
        "product_id": product_id,
        "total_available": 150,
        "total_reserved": 25,
        "total_on_hand": 175,
        "warehouses": [
            {"id": "wh_east", "name": "East Coast", "available": 80, "reserved": 15},
            {"id": "wh_west", "name": "West Coast", "available": 70, "reserved": 10}
        ],
        "low_stock_threshold": 20,
        "reorder_point": 50
    }

@app.post("/api/v2/inventory/{product_id}/reserve", tags=["Inventory"])
async def reserve_inventory(
    product_id: int,
    quantity: int,
    order_id: str,
    idempotency_key: str = Header(...)
):
    """
    Reserve inventory for an order.
    
    Uses optimistic locking:
    UPDATE inventory SET reserved = reserved + :qty, available = available - :qty
    WHERE product_id = :pid AND available >= :qty AND version = :expected_version
    
    Idempotent: same order_id + product_id = same reservation
    """
    pass
```

---

# 20. Food Delivery API Design

```
┌──────────────────────────────────────────────────────────────────┐
│                  FOOD DELIVERY SYSTEM                             │
│                                                                   │
│  ┌──────────┐    ┌──────────┐    ┌──────────┐                    │
│  │ Customer │    │Restaurant│    │ Driver   │                    │
│  │  App     │    │  App     │    │  App     │                    │
│  └────┬─────┘    └────┬─────┘    └────┬─────┘                    │
│       │               │               │                          │
│       ▼               ▼               ▼                          │
│  ┌────────────────────────────────────────────┐                  │
│  │              API GATEWAY                    │                  │
│  └────────────────────┬───────────────────────┘                  │
│                       │                                          │
│  ┌────────┬───────────┼────────────┬──────────┐                 │
│  │        │           │            │          │                  │
│  ▼        ▼           ▼            ▼          ▼                  │
│ ┌────┐ ┌──────┐ ┌─────────┐ ┌────────┐ ┌────────┐             │
│ │User│ │Rest- │ │ Order   │ │Delivery│ │Payment │             │
│ │Svc │ │aurant│ │ Service │ │Service │ │Service │             │
│ │    │ │Svc   │ │         │ │        │ │        │             │
│ └────┘ └──────┘ └─────────┘ └────────┘ └────────┘             │
│                                                                   │
│  Order Flow:                                                      │
│  Browse → Add to Cart → Checkout → Restaurant Accepts →          │
│  Preparing → Driver Assigned → Picked Up → Delivered             │
└──────────────────────────────────────────────────────────────────┘
```

```python
from fastapi import FastAPI, HTTPException, Query, Header, WebSocket
from pydantic import BaseModel, Field
from typing import List, Optional, Tuple
from enum import Enum
from datetime import datetime, time
import asyncio

app = FastAPI(title="Food Delivery API", version="2.0.0")


# ============================================================
# DATA MODELS
# ============================================================

class GeoLocation(BaseModel):
    latitude: float = Field(..., ge=-90, le=90)
    longitude: float = Field(..., ge=-180, le=180)

class DeliveryOrderStatus(str, Enum):
    PLACED = "placed"
    ACCEPTED = "accepted"            # Restaurant accepted
    REJECTED = "rejected"            # Restaurant rejected
    PREPARING = "preparing"          # Kitchen is cooking
    READY_FOR_PICKUP = "ready"       # Food is ready
    DRIVER_ASSIGNED = "driver_assigned"
    DRIVER_AT_RESTAURANT = "driver_at_restaurant"
    PICKED_UP = "picked_up"          # Driver has the food
    EN_ROUTE = "en_route"            # Driver heading to customer
    ARRIVED = "arrived"              # Driver at delivery location
    DELIVERED = "delivered"          
    CANCELLED = "cancelled"

"""
Order State Machine:
┌────────┐     ┌──────────┐     ┌───────────┐     ┌───────┐
│ PLACED │────▶│ ACCEPTED │────▶│ PREPARING │────▶│ READY │
└────┬───┘     └──────────┘     └───────────┘     └───┬───┘
     │                                                 │
     │ rejected                          driver_assigned│
     ▼                                                 ▼
┌──────────┐                              ┌─────────────────┐
│ REJECTED │                              │ DRIVER_ASSIGNED  │
└──────────┘                              └────────┬────────┘
                                                   │
                               ┌───────────────────┼──────────────┐
                               ▼                   ▼              ▼
                        ┌────────────┐    ┌──────────┐    ┌──────────┐
                        │ AT_RESTRNRT│───▶│PICKED_UP │───▶│ EN_ROUTE │
                        └────────────┘    └──────────┘    └────┬─────┘
                                                               │
                                                    ┌──────────▼──┐
                                                    │  DELIVERED  │
                                                    └─────────────┘
"""


# ============================================================
# RESTAURANT DISCOVERY APIs
# ============================================================

@app.get("/api/v2/restaurants", tags=["Restaurants"])
async def search_restaurants(
    lat: float = Query(..., ge=-90, le=90, description="User latitude"),
    lng: float = Query(..., ge=-180, le=180, description="User longitude"),
    q: Optional[str] = Query(None, description="Search query (restaurant name, cuisine)"),
    cuisine: Optional[str] = Query(None, description="Cuisine type filter"),
    price_level: Optional[int] = Query(None, ge=1, le=4, description="1=$ to 4=$$$$"),
    rating_min: Optional[float] = Query(None, ge=0, le=5),
    delivery_fee_max: Optional[float] = Query(None, ge=0),
    max_delivery_time: Optional[int] = Query(None, description="Max delivery time in minutes"),
    dietary: Optional[str] = Query(None, description="vegan,vegetarian,halal,gluten_free"),
    is_open: bool = Query(True, description="Only show currently open restaurants"),
    sort_by: str = Query("recommended", regex="^(recommended|rating|delivery_time|distance|price)$"),
    radius_km: float = Query(10.0, ge=1, le=50),
    cursor: Optional[str] = None,
    limit: int = Query(20, ge=1, le=50)
):
    """
    Search nearby restaurants.
    
    Uses geospatial indexing for proximity search.
    
    Ranking algorithm considers:
    - Distance from user
    - Restaurant rating
    - Estimated delivery time
    - User's past orders (personalization)
    - Restaurant promotions
    - Sponsored listings
    """
    return {
        "data": [
            {
                "id": "rest_001",
                "name": "Burger Palace",
                "slug": "burger-palace-sf",
                "image": "https://cdn.example.com/restaurants/burger-palace.jpg",
                "cover_image": "https://cdn.example.com/restaurants/burger-palace-cover.jpg",
                "cuisine_types": ["American", "Burgers", "Fast Food"],
                "price_level": 2,
                "rating": {
                    "average": 4.5,
                    "count": 1250,
                    "display": "4.5 (1.2K+ ratings)"
                },
                "delivery": {
                    "estimated_time_minutes": {"min": 25, "max": 35},
                    "fee": {"amount": 2.99, "currency": "USD"},
                    "free_delivery_minimum": {"amount": 25.00, "currency": "USD"},
                    "distance_km": 2.3
                },
                "operating_hours": {
                    "is_open": True,
                    "closes_at": "22:00",
                    "next_opens": None
                },
                "promotions": [
                    {"type": "discount", "description": "20% off first order", "code": "WELCOME20"}
                ],
                "tags": ["Popular", "Free Delivery over $25"],
                "is_featured": True
            }
        ],
        "pagination": {
            "next_cursor": "eyJzY29yZSI6MC44NSwiaWQiOiJyZXN0XzAyMCJ9",
            "has_more": True
        }
    }

@app.get("/api/v2/restaurants/{restaurant_id}", tags=["Restaurants"])
async def get_restaurant(restaurant_id: str):
    """Get detailed restaurant information including full menu."""
    return {
        "id": restaurant_id,
        "name": "Burger Palace",
        "description": "Premium burgers made with locally sourced ingredients",
        "address": "123 Market St, San Francisco, CA 94105",
        "location": {"latitude": 37.7749, "longitude": -122.4194},
        "phone": "+1-415-555-0123",
        "rating": {"average": 4.5, "count": 1250},
        "price_level": 2,
        "cuisine_types": ["American", "Burgers"],
        "operating_hours": {
            "monday": {"open": "10:00", "close": "22:00"},
            "tuesday": {"open": "10:00", "close": "22:00"},
            # ...
        },
        "delivery_info": {
            "radius_km": 8,
            "minimum_order": {"amount": 10.00, "currency": "USD"},
            "estimated_time_minutes": {"min": 25, "max": 35}
        },
        "menu": {
            "categories": [
                {
                    "id": "cat_1",
                    "name": "Popular Items",
                    "description": "Our most ordered dishes",
                    "items": [
                        {
                            "id": "item_101",
                            "name": "Classic Burger",
                            "description": "Angus beef patty, lettuce, tomato, secret sauce",
                            "price": {"amount": 12.99, "currency": "USD"},
                            "image": "https://cdn.example.com/items/classic-burger.jpg",
                            "is_available": True,
                            "is_popular": True,
                            "dietary_info": ["contains_gluten", "contains_dairy"],
                            "calories": 650,
                            "customizations": [
                                {
                                    "id": "cust_1",
                                    "name": "Patty Type",
                                    "type": "single_select",
                                    "required": True,
                                    "options": [
                                        {"id": "opt_1", "name": "Beef", "price_adjustment": 0},
                                        {"id": "opt_2", "name": "Chicken", "price_adjustment": 0},
                                        {"id": "opt_3", "name": "Veggie", "price_adjustment": 1.00}
                                    ]
                                },
                                {
                                    "id": "cust_2",
                                    "name": "Toppings",
                                    "type": "multi_select",
                                    "required": False,
                                    "max_selections": 5,
                                    "options": [
                                        {"id": "top_1", "name": "Extra Cheese", "price_adjustment": 1.50},
                                        {"id": "top_2", "name": "Bacon", "price_adjustment": 2.00},
                                        {"id": "top_3", "name": "Avocado", "price_adjustment": 2.50}
                                    ]
                                }
                            ]
                        }
                    ]
                },
                {
                    "id": "cat_2",
                    "name": "Sides",
                    "items": [...]
                }
            ]
        }
    }


# ============================================================
# ORDER APIs (Customer Side)
# ============================================================

class OrderItemCustomization(BaseModel):
    customization_id: str
    selected_option_ids: List[str]

class OrderItem(BaseModel):
    menu_item_id: str
    quantity: int = Field(..., ge=1, le=20)
    special_instructions: Optional[str] = Field(None, max_length=500)
    customizations: List[OrderItemCustomization] = []

class CreateDeliveryOrderRequest(BaseModel):
    restaurant_id: str
    items: List[OrderItem] = Field(..., min_items=1)
    delivery_address_id: Optional[int] = None
    delivery_address: Optional[dict] = None  # For one-time address
    delivery_instructions: Optional[str] = Field(None, max_length=500)
    tip_amount: Optional[float] = Field(None, ge=0)
    payment_method_id: str
    coupon_code: Optional[str] = None
    scheduled_for: Optional[datetime] = None  # None = ASAP
    contactless_delivery: bool = False

@app.post("/api/v2/delivery/orders", status_code=201, tags=["Orders"])
async def create_delivery_order(
    order: CreateDeliveryOrderRequest,
    idempotency_key: str = Header(...)
):
    """
    Place a delivery order.
    
    Server-side processing:
    1. Validate restaurant is open and delivering to address
    2. Validate all menu items are available
    3. Calculate pricing (subtotal, fees, tax, tip)
    4. Authorize payment
    5. Send order to restaurant for acceptance
    6. Start order tracking
    
    Idempotency: Same idempotency key within 24h returns cached result
    """
    return {
        "id": "dord_abc123",
        "order_number": "FD-2024-00456",
        "status": "placed",
        "restaurant": {
            "id": "rest_001",
            "name": "Burger Palace",
            "phone": "+1-415-555-0123"
        },
        "items": [
            {
                "menu_item_id": "item_101",
                "name": "Classic Burger",
                "quantity": 2,
                "customizations": [
                    {"name": "Patty Type", "selected": "Beef"},
                    {"name": "Toppings", "selected": ["Extra Cheese", "Bacon"]}
                ],
                "special_instructions": "No pickles please",
                "unit_price": {"amount": 16.49, "currency": "USD"},
                "line_total": {"amount": 32.98, "currency": "USD"}
            }
        ],
        "pricing": {
            "subtotal": {"amount": 32.98, "currency": "USD"},
            "delivery_fee": {"amount": 2.99, "currency": "USD"},
            "service_fee": {"amount": 3.30, "currency": "USD"},
            "tax": {"amount": 3.15, "currency": "USD"},
            "tip": {"amount": 5.00, "currency": "USD"},
            "discount": {"amount": -6.60, "currency": "USD"},
            "total": {"amount": 40.82, "currency": "USD"}
        },
        "delivery": {
            "address": "456 Oak Ave, San Francisco, CA 94102",
            "instructions": "Ring doorbell, leave at door",
            "contactless": True,
            "estimated_delivery_time": {
                "min_minutes": 30,
                "max_minutes": 45,
                "estimated_at": "2024-01-20T16:15:00Z"
            }
        },
        "tracking_url": "https://track.example.com/dord_abc123",
        "created_at": "2024-01-20T15:30:00Z"
    }

@app.get("/api/v2/delivery/orders/{order_id}", tags=["Orders"])
async def get_delivery_order(order_id: str):
    """Get order details with current status and tracking."""
    pass

@app.get("/api/v2/delivery/orders/{order_id}/track", tags=["Tracking"])
async def get_order_tracking(order_id: str):
    """
    Get real-time tracking information.
    
    For real-time updates, use WebSocket or SSE instead.
    This endpoint is for initial state + polling fallback.
    """
    return {
        "order_id": order_id,
        "status": "en_route",
        "timeline": [
            {"status": "placed", "timestamp": "2024-01-20T15:30:00Z"},
            {"status": "accepted", "timestamp": "2024-01-20T15:31:00Z",
             "message": "Restaurant accepted your order"},
            {"status": "preparing", "timestamp": "2024-01-20T15:35:00Z",
             "message": "Your food is being prepared"},
            {"status": "ready", "timestamp": "2024-01-20T15:55:00Z",
             "message": "Your food is ready for pickup"},
            {"status": "driver_assigned", "timestamp": "2024-01-20T15:50:00Z",
             "message": "Driver John is heading to the restaurant"},
            {"status": "picked_up", "timestamp": "2024-01-20T15:58:00Z",
             "message": "Driver John picked up your order"},
            {"status": "en_route", "timestamp": "2024-01-20T16:00:00Z",
             "message": "Your order is on the way!"}
        ],
        "driver": {
            "id": "drv_789",
            "name": "John",
            "photo": "https://cdn.example.com/drivers/john.jpg",
            "phone": "+1-415-555-9876",  # masked number
            "vehicle": {"type": "car", "model": "Toyota Camry", "color": "Silver", "plate": "ABC123"},
            "rating": 4.9,
            "current_location": {
                "latitude": 37.7845,
                "longitude": -122.4095,
                "heading": 180,
                "updated_at": "2024-01-20T16:02:00Z"
            }
        },
        "estimated_arrival": {
            "minutes_remaining": 8,
            "eta": "2024-01-20T16:10:00Z"
        },
        "delivery_proof": None  # Populated after delivery (photo)
    }


# ============================================================
# REAL-TIME TRACKING (WebSocket)
# ============================================================

@app.websocket("/api/v2/delivery/orders/{order_id}/live")
async def order_live_tracking(websocket: WebSocket, order_id: str):
    """
    WebSocket for real-time order tracking.
    
    Client receives:
    - Status changes
    - Driver location updates (every 5 seconds when en_route)
    - ETA updates
    
    Much more efficient than polling GET /track every few seconds.
    """
    await websocket.accept()
    
    try:
        while True:
            # Simulate real-time updates
            tracking_update = {
                "type": "location_update",
                "data": {
                    "driver_location": {
                        "latitude": 37.7845,
                        "longitude": -122.4095,
                        "heading": 180,
                        "speed_kmh": 35
                    },
                    "eta_minutes": 8,
                    "distance_km": 2.1,
                    "timestamp": datetime.utcnow().isoformat()
                }
            }
            
            await websocket.send_json(tracking_update)
            await asyncio.sleep(5)  # Update every 5 seconds
            
    except Exception:
        await websocket.close()


# ============================================================
# RESTAURANT MANAGEMENT APIs (Restaurant App)
# ============================================================

@app.get("/api/v2/restaurant-portal/orders", tags=["Restaurant Portal"])
async def get_incoming_orders(
    status: Optional[str] = Query(None, regex="^(placed|accepted|preparing|ready)$"),
    limit: int = Query(50, ge=1, le=100)
):
    """Get orders for the restaurant dashboard."""
    pass

@app.post("/api/v2/restaurant-portal/orders/{order_id}/accept", tags=["Restaurant Portal"])
async def accept_order(
    order_id: str,
    estimated_prep_time_minutes: int = Field(..., ge=5, le=120)
):
    """
    Restaurant accepts an incoming order.
    Must respond within 5 minutes or order auto-cancels.
    
    Sets the preparation time estimate shown to customer.
    """
    return {
        "order_id": order_id,
        "status": "accepted",
        "estimated_prep_time_minutes": estimated_prep_time_minutes,
        "accepted_at": datetime.utcnow().isoformat()
    }

@app.post("/api/v2/restaurant-portal/orders/{order_id}/reject", tags=["Restaurant Portal"])
async def reject_order(order_id: str, reason: str):
    """
    Restaurant rejects an order.
    
    Reasons: too_busy, item_unavailable, closing_soon, other
    Triggers: customer notification + full refund
    """
    pass

@app.post("/api/v2/restaurant-portal/orders/{order_id}/ready", tags=["Restaurant Portal"])
async def mark_order_ready(order_id: str):
    """Mark order as ready for driver pickup."""
    pass

@app.patch("/api/v2/restaurant-portal/menu/items/{item_id}", tags=["Restaurant Portal"])
async def update_menu_item_availability(item_id: str, is_available: bool):
    """Toggle menu item availability (86'd an item)."""
    pass


# ============================================================
# DRIVER APIs (Driver App)
# ============================================================

@app.post("/api/v2/driver/location", tags=["Driver"])
async def update_driver_location(location: GeoLocation):
    """
    Driver app sends location updates.
    
    Called every 5-10 seconds when driver is active.
    Uses gRPC in production for efficiency (high frequency, small payload).
    
    Server uses this for:
    - Customer ETA calculation
    - Order matching algorithm
    - Route optimization
    """
    pass

@app.post("/api/v2/driver/status", tags=["Driver"])
async def update_driver_status(status: str):
    """
    Driver goes online/offline.
    
    status: 'online' | 'offline' | 'busy'
    """
    pass

@app.get("/api/v2/driver/offers", tags=["Driver"])
async def get_delivery_offers():
    """
    Get available delivery offers for the driver.
    
    System pushes offers based on:
    - Driver's current location
    - Driver's rating
    - Order priority
    - Estimated earnings
    """
    return {
        "offers": [
            {
                "id": "offer_001",
                "order_id": "dord_abc123",
                "restaurant": {
                    "name": "Burger Palace",
                    "address": "123 Market St",
                    "location": {"latitude": 37.7749, "longitude": -122.4194}
                },
                "delivery_address": "456 Oak Ave",
                "delivery_location": {"latitude": 37.7650, "longitude": -122.4200},
                "estimated_distance_km": 3.5,
                "estimated_time_minutes": 20,
                "estimated_earnings": {"amount": 8.50, "currency": "USD"},
                "tip_included": True,
                "expires_at": "2024-01-20T15:52:00Z"  # 30 second window to accept
            }
        ]
    }

@app.post("/api/v2/driver/offers/{offer_id}/accept", tags=["Driver"])
async def accept_delivery_offer(offer_id: str):
    """Driver accepts a delivery offer."""
    pass

@app.post("/api/v2/driver/deliveries/{delivery_id}/pickup", tags=["Driver"])
async def confirm_pickup(delivery_id: str, confirmation_code: Optional[str] = None):
    """Driver confirms food pickup from restaurant."""
    pass

@app.post("/api/v2/driver/deliveries/{delivery_id}/complete", tags=["Driver"])
async def complete_delivery(
    delivery_id: str,
    proof_photo_url: Optional[str] = None,
    notes: Optional[str] = None
):
    """Driver marks delivery as complete."""
    pass
```

---

# 21. Ride Sharing API Design

```
┌──────────────────────────────────────────────────────────────────┐
│                    RIDE SHARING SYSTEM                            │
│                                                                   │
│  ┌──────────┐         ┌──────────┐                               │
│  │  Rider   │         │  Driver  │                               │
│  │  App     │         │  App     │                               │
│  └────┬─────┘         └────┬─────┘                               │
│       │                    │                                      │
│       ▼                    ▼                                      │
│  ┌─────────────────────────────────┐                             │
│  │         API GATEWAY              │                             │
│  └──────────────┬──────────────────┘                             │
│                 │                                                 │
│  ┌──────┬───────┼──────┬───────┬────────┐                       │
│  ▼      ▼       ▼      ▼       ▼        ▼                       │
│ ┌────┐┌──────┐┌─────┐┌──────┐┌──────┐┌───────┐                │
│ │User││Match ││Ride ││Price ││Pay-  ││Notif- │                │
│ │Svc ││Svc   ││Svc  ││Svc   ││ment  ││ication│                │
│ │    ││      ││     ││      ││Svc   ││Svc    │                │
│ └────┘└──────┘└─────┘└──────┘└──────┘└───────┘                │
│                                                                   │
│  Ride Flow:                                                       │
│  Request → Price Estimate → Confirm → Match Driver →             │
│  Driver En Route → Arrived → Trip Started → Trip Ended →         │
│  Payment → Rating                                                 │
└──────────────────────────────────────────────────────────────────┘
```

```python
from fastapi import FastAPI, HTTPException, Query, Header, WebSocket
from pydantic import BaseModel, Field
from typing import List, Optional
from enum import Enum
from datetime import datetime

app = FastAPI(title="Ride Sharing API", version="2.0.0")


# ============================================================
# DATA MODELS
# ============================================================

class GeoPoint(BaseModel):
    latitude: float = Field(..., ge=-90, le=90)
    longitude: float = Field(..., ge=-180, le=180)
    address: Optional[str] = None

class RideType(str, Enum):
    ECONOMY = "economy"         # UberX equivalent
    COMFORT = "comfort"         # UberComfort
    PREMIUM = "premium"         # UberBlack
    XL = "xl"                   # UberXL (larger vehicles)
    POOL = "pool"               # Shared rides
    SCHEDULED = "scheduled"     # Pre-scheduled rides

class RideStatus(str, Enum):
    REQUESTED = "requested"         # Rider requested, finding driver
    DRIVER_ASSIGNED = "driver_assigned"  # Driver matched
    DRIVER_EN_ROUTE = "driver_en_route"  # Driver heading to pickup
    DRIVER_ARRIVED = "driver_arrived"    # Driver at pickup location
    IN_PROGRESS = "in_progress"          # Trip active
    COMPLETED = "completed"              # Trip finished
    CANCELLED = "cancelled"              # Cancelled by rider or driver
    NO_DRIVERS = "no_drivers"            # No drivers available

"""
Ride State Machine:
┌───────────┐     ┌─────────────────┐     ┌─────────────────┐
│ REQUESTED │────▶│ DRIVER_ASSIGNED │────▶│ DRIVER_EN_ROUTE │
└─────┬─────┘     └─────────────────┘     └────────┬────────┘
      │                                             │
      │ no drivers         rider/driver cancel      │
      ▼                          │                  ▼
┌────────────┐          ┌───────▼─────┐    ┌──────────────┐
│ NO_DRIVERS │          │  CANCELLED  │    │DRIVER_ARRIVED│
└────────────┘          └─────────────┘    └───────┬──────┘
                                                    │ trip_start
                                            ┌───────▼──────┐
                                            │ IN_PROGRESS  │
                                            └───────┬──────┘
                                                    │ trip_end
                                            ┌───────▼──────┐
                                            │  COMPLETED   │
                                            └──────────────┘
"""


# ============================================================
# RIDE ESTIMATE & REQUEST APIs (Rider)
# ============================================================

class RideEstimateRequest(BaseModel):
    pickup: GeoPoint
    dropoff: GeoPoint
    ride_types: Optional[List[RideType]] = None  # None = all types
    passenger_count: int = Field(default=1, ge=1, le=8)
    scheduled_at: Optional[datetime] = None

@app.post("/api/v2/rides/estimate", tags=["Rides"])
async def get_ride_estimate(request: RideEstimateRequest):
    """
    Get price and time estimates for a ride.
    
    Pricing factors:
    - Base fare + per mile + per minute
    - Surge multiplier (demand/supply ratio)
    - Time of day
    - Route (traffic, tolls)
    - Ride type
    
    This is a read-like operation using POST because:
    - Complex request body (coordinates)
    - Not cacheable (prices change in real-time)
    - No side effects (safe operation)
    
    Rate limit: 30 requests/minute per user
    """
    return {
        "pickup": {
            "address": "123 Market St, San Francisco, CA",
            "latitude": 37.7749,
            "longitude": -122.4194
        },
        "dropoff": {
            "address": "SFO Airport, San Francisco, CA",
            "latitude": 37.6213,
            "longitude": -122.3790
        },
        "estimates": [
            {
                "ride_type": "economy",
                "display_name": "Economy",
                "description": "Affordable rides",
                "capacity": 4,
                "price_estimate": {
                    "min": {"amount": 25.00, "currency": "USD"},
                    "max": {"amount": 32.00, "currency": "USD"},
                    "surge_multiplier": 1.2,
                    "surge_active": True,
                    "fare_breakdown": {
                        "base_fare": 2.50,
                        "distance_fare": 15.60,  # $1.20/mile × 13 miles
                        "time_fare": 4.80,        # $0.20/min × 24 min
                        "surge_premium": 4.58,
                        "booking_fee": 2.50,
                        "tolls": 0.00,
                        "estimated_total": 29.98
                    }
                },
                "eta_minutes": {
                    "pickup": 5,      # Driver arrives in 5 min
                    "trip": 24,       # Trip takes ~24 min
                    "dropoff": 29     # Total time to destination
                },
                "available_drivers": 8,
                "vehicle_icon_url": "https://cdn.example.com/icons/economy.png"
            },
            {
                "ride_type": "comfort",
                "display_name": "Comfort",
                "description": "Newer cars, extra legroom",
                "capacity": 4,
                "price_estimate": {
                    "min": {"amount": 35.00, "currency": "USD"},
                    "max": {"amount": 45.00, "currency": "USD"},
                    "surge_multiplier": 1.0,
                    "surge_active": False
                },
                "eta_minutes": {"pickup": 8, "trip": 24, "dropoff": 32},
                "available_drivers": 3
            },
            {
                "ride_type": "xl",
                "display_name": "XL",
                "description": "SUVs and minivans for groups",
                "capacity": 6,
                "price_estimate": {
                    "min": {"amount": 45.00, "currency": "USD"},
                    "max": {"amount": 55.00, "currency": "USD"}
                },
                "eta_minutes": {"pickup": 12, "trip": 24, "dropoff": 36},
                "available_drivers": 2
            }
        ],
        "route": {
            "distance_km": 20.9,
            "duration_minutes": 24,
            "polyline": "encoded_polyline_string..."  # For displaying route on map
        },
        "estimated_at": "2024-01-20T15:30:00Z",
        "valid_until": "2024-01-20T15:35:00Z"  # Estimate expires in 5 min
    }


class RequestRideRequest(BaseModel):
    pickup: GeoPoint
    dropoff: GeoPoint
    ride_type: RideType
    passenger_count: int = Field(default=1, ge=1, le=8)
    payment_method_id: str
    promo_code: Optional[str] = None
    notes: Optional[str] = Field(None, max_length=200)
    scheduled_at: Optional[datetime] = None  # None = ride now

@app.post("/api/v2/rides", status_code=201, tags=["Rides"])
async def request_ride(
    ride: RequestRideRequest,
    idempotency_key: str = Header(...)
):
    """
    Request a ride.
    
    Flow:
    1. Validate payment method
    2. Check price hasn't changed significantly  
    3. Find optimal driver using matching algorithm
    4. Reserve estimated fare on payment method
    5. Notify driver of new ride request
    
    Driver matching considers:
    - Proximity to pickup location
    - Driver rating
    - Driver heading direction
    - Acceptance rate
    - Vehicle type compatibility
    
    Idempotency: Prevents duplicate ride requests on network retry.
    """
    return {
        "id": "ride_abc123",
        "status": "requested",
        "ride_type": "economy",
        "pickup": {
            "address": "123 Market St, San Francisco, CA",
            "latitude": 37.7749,
            "longitude": -122.4194
        },
        "dropoff": {
            "address": "SFO Airport, San Francisco, CA",
            "latitude": 37.6213,
            "longitude": -122.3790
        },
        "estimated_price": {"amount": 29.98, "currency": "USD"},
        "estimated_pickup_eta": 5,
        "created_at": "2024-01-20T15:30:00Z",
        "cancel_policy": {
            "free_cancel_seconds": 120,  # Free cancellation for 2 minutes
            "cancel_fee": {"amount": 5.00, "currency": "USD"}
        }
    }

@app.get("/api/v2/rides/{ride_id}", tags=["Rides"])
async def get_ride(ride_id: str):
    """Get current ride status and details."""
    return {
        "id": ride_id,
        "status": "driver_en_route",
        "ride_type": "economy",
        "pickup": {"address": "123 Market St", "latitude": 37.7749, "longitude": -122.4194},
        "dropoff": {"address": "SFO Airport", "latitude": 37.6213, "longitude": -122.3790},
        "driver": {
            "id": "drv_456",
            "name": "Sarah",
            "photo_url": "https://cdn.example.com/drivers/sarah.jpg",
            "rating": 4.92,
            "total_rides": 2540,
            "phone": "+1-415-555-XXXX",  # Masked
            "vehicle": {
                "make": "Toyota",
                "model": "Camry",
                "year": 2023,
                "color": "Silver",
                "license_plate": "ABC 1234"
            },
            "current_location": {
                "latitude": 37.7760,
                "longitude": -122.4180,
                "heading": 225,
                "updated_at": "2024-01-20T15:31:30Z"
            },
            "eta_minutes": 3
        },
        "fare_estimate": {
            "min": {"amount": 25.00, "currency": "USD"},
            "max": {"amount": 32.00, "currency": "USD"}
        },
        "route": {
            "distance_km": 20.9,
            "duration_minutes": 24,
            "polyline": "encoded_polyline..."
        },
        "share_url": "https://ride.example.com/share/ride_abc123",  # Share ETA with friends
        "safety": {
            "emergency_button_enabled": True,
            "trip_sharing_active": False,
            "safety_toolkit_url": "/api/v2/rides/ride_abc123/safety"
        },
        "created_at": "2024-01-20T15:30:00Z"
    }

@app.post("/api/v2/rides/{ride_id}/cancel", tags=["Rides"])
async def cancel_ride(ride_id: str, reason: Optional[str] = None):
    """
    Cancel a ride request.
    
    Cancellation fee applies if:
    - More than 2 minutes after driver assigned
    - Driver is already en route
    
    Free cancellation:
    - Within 2 minutes of requesting
    - Before driver is assigned
    - Driver hasn't moved toward pickup
    """
    return {
        "ride_id": ride_id,
        "status": "cancelled",
        "cancellation_fee": {"amount": 0.00, "currency": "USD"},
        "reason": "changed_plans"
    }

@app.post("/api/v2/rides/{ride_id}/rate", tags=["Rides"])
async def rate_ride(ride_id: str, rating: int = Field(..., ge=1, le=5), 
                    feedback: Optional[str] = None,
                    tip: Optional[float] = Field(None, ge=0)):
    """
    Rate a completed ride and optionally add a tip.
    
    Idempotent: Re-rating overwrites previous rating.
    """
    pass


# ============================================================
# REAL-TIME TRACKING (WebSocket)
# ============================================================

@app.websocket("/api/v2/rides/{ride_id}/live")
async def ride_live_tracking(websocket: WebSocket, ride_id: str):
    """
    Real-time ride tracking via WebSocket.
    
    Events sent to rider:
    - driver_location: Every 3 seconds during en_route
    - status_change: When ride status changes
    - eta_update: Updated ETA based on traffic
    - route_update: If driver takes different route
    
    Events sent to driver:
    - navigation_update: Turn-by-turn navigation
    - rider_location: Rider's pinned location
    """
    await websocket.accept()
    
    try:
        while True:
            # Server pushes updates
            update = {
                "event": "driver_location",
                "data": {
                    "latitude": 37.7760,
                    "longitude": -122.4180,
                    "heading": 225,
                    "speed_kmh": 30,
                    "eta_minutes": 3,
                    "distance_remaining_km": 1.2,
                    "timestamp": datetime.utcnow().isoformat()
                }
            }
            await websocket.send_json(update)
            await asyncio.sleep(3)
    except Exception:
        await websocket.close()


# ============================================================
# DRIVER APIs
# ============================================================

@app.post("/api/v2/driver/go-online", tags=["Driver"])
async def driver_go_online(location: GeoPoint, vehicle_id: str):
    """
    Driver starts accepting ride requests.
    Begins location tracking.
    """
    return {
        "status": "online",
        "surge_zones": [
            {
                "center": {"latitude": 37.78, "longitude": -122.41},
                "radius_km": 2,
                "surge_multiplier": 1.8,
                "demand_level": "high"
            }
        ],
        "incentives": [
            {"type": "quest", "description": "Complete 3 rides before 8PM for $15 bonus",
             "progress": {"completed": 1, "required": 3}}
        ]
    }

@app.post("/api/v2/driver/go-offline", tags=["Driver"])
async def driver_go_offline():
    """Driver stops accepting ride requests."""
    pass

@app.post("/api/v2/driver/location", tags=["Driver"])
async def update_driver_location(location: GeoPoint):
    """
    High-frequency location update (every 3-5 seconds).
    
    In production, this would use gRPC streaming for efficiency:
    - Binary protobuf instead of JSON
    - Persistent HTTP/2 connection (no connection overhead)
    - ~50 bytes per update instead of ~200 bytes
    """
    pass

@app.post("/api/v2/driver/rides/{ride_id}/accept", tags=["Driver"])
async def accept_ride_request(ride_id: str):
    """
    Driver accepts a ride request.
    Must respond within 15 seconds or request goes to next driver.
    """
    return {
        "ride_id": ride_id,
        "status": "driver_assigned",
        "rider": {
            "name": "Alex",
            "rating": 4.8,
            "pickup": {
                "address": "123 Market St",
                "latitude": 37.7749,
                "longitude": -122.4194,
                "notes": "I'll be at the corner near the coffee shop"
            }
        },
        "navigation": {
            "destination": {"latitude": 37.7749, "longitude": -122.4194},
            "distance_km": 1.5,
            "duration_minutes": 5,
            "polyline": "encoded..."
        }
    }

@app.post("/api/v2/driver/rides/{ride_id}/arrive", tags=["Driver"])
async def driver_arrived(ride_id: str):
    """Driver confirms arrival at pickup location."""
    pass

@app.post("/api/v2/driver/rides/{ride_id}/start", tags=["Driver"])
async def start_ride(ride_id: str, odometer_reading: Optional[float] = None):
    """Start the trip (rider is in the vehicle)."""
    pass

@app.post("/api/v2/driver/rides/{ride_id}/stop-points", tags=["Driver"])
async def add_stop(ride_id: str, location: GeoPoint):
    """Rider requests an additional stop during the trip."""
    pass

@app.post("/api/v2/driver/rides/{ride_id}/complete", tags=["Driver"])
async def complete_ride(ride_id: str, odometer_reading: Optional[float] = None):
    """
    End the trip.
    
    Triggers:
    1. Calculate final fare (actual distance × rate + time × rate + fees)
    2. Charge rider's payment method
    3. Credit driver's earnings
    4. Request rating from both parties
    """
    return {
        "ride_id": ride_id,
        "status": "completed",
        "fare": {
            "base_fare": 2.50,
            "distance_fare": 15.60,
            "time_fare": 5.20,
            "surge_premium": 4.66,
            "booking_fee": 2.50,
            "tolls": 6.50,
            "subtotal": 36.96,
            "rider_discount": -5.00,
            "total_charged_to_rider": 31.96,
            "driver_earnings": 25.57,
            "platform_fee": 6.39
        },
        "trip_summary": {
            "distance_km": 21.2,
            "duration_minutes": 26,
            "route_polyline": "encoded...",
            "start_time": "2024-01-20T15:35:00Z",
            "end_time": "2024-01-20T16:01:00Z"
        }
    }


# ============================================================
# SURGE PRICING API (Internal)
# ============================================================

@app.get("/api/v2/surge", tags=["Pricing"])
async def get_surge_pricing(
    lat: float = Query(...),
    lng: float = Query(...)
):
    """
    Get current surge multiplier for a location.
    
    Surge is calculated based on:
    - Supply: Number of available drivers in the area
    - Demand: Number of ride requests in the area
    - Time of day, events, weather
    
    Updated every 1-2 minutes.
    """
    return {
        "location": {"latitude": lat, "longitude": lng},
        "surge_multiplier": 1.5,
        "demand_level": "high",
        "supply_level": "low",
        "estimated_wait_minutes": 8,
        "heat_map_url": "https://api.example.com/surge/heatmap?lat=37.77&lng=-122.41"
    }
```

---

# 22. Social Media API Design

```
┌──────────────────────────────────────────────────────────────────┐
│                   SOCIAL MEDIA PLATFORM                          │
│                                                                   │
│  ┌──────────┐     ┌──────────────┐                               │
│  │  Web /   │────▶│  API Gateway │                               │
│  │  Mobile  │     │              │                               │
│  └──────────┘     └──────┬───────┘                               │
│                          │                                        │
│  ┌───────────────────────┼──────────────────────┐                │
│  │                       │                      │                │
│  ▼            ▼          ▼         ▼            ▼                │
│ ┌────────┐ ┌──────┐ ┌────────┐ ┌───────┐ ┌──────────┐          │
│ │  User  │ │ Post │ │  Feed  │ │Message│ │Notif-    │          │
│ │Service │ │  Svc │ │  Svc   │ │  Svc  │ │ication   │          │
│ │        │ │      │ │        │ │       │ │  Svc     │          │
│ └────────┘ └──────┘ └────────┘ └───────┘ └──────────┘          │
│                                                                   │
│  Core Features:                                                   │
│  • User profiles & follow graph                                  │
│  • Posts (text, images, videos)                                  │
│  • News feed generation                                          │
│  • Likes, comments, shares                                       │
│  • Direct messaging                                              │
│  • Notifications                                                  │
│  • Search & discovery                                             │
│  • Stories (ephemeral content)                                    │
└──────────────────────────────────────────────────────────────────┘
```

```python
from fastapi import FastAPI, HTTPException, Query, Header, UploadFile, File, WebSocket
from pydantic import BaseModel, Field
from typing import List, Optional, Set
from enum import Enum
from datetime import datetime

app = FastAPI(title="Social Media API", version="2.0.0")


# ============================================================
# USER / PROFILE APIs
# ============================================================

class CreateUserRequest(BaseModel):
    username: str = Field(..., regex="^[a-zA-Z0-9_]{3,30}$")
    email: str
    display_name: str = Field(..., min_length=1, max_length=50)
    bio: Optional[str] = Field(None, max_length=160)
    date_of_birth: Optional[str] = None  # For age verification

class UpdateProfileRequest(BaseModel):
    display_name: Optional[str] = Field(None, max_length=50)
    bio: Optional[str] = Field(None, max_length=160)
    website: Optional[str] = None
    location: Optional[str] = None
    profile_image_url: Optional[str] = None
    cover_image_url: Optional[str] = None
    is_private: Optional[bool] = None

@app.post("/api/v2/users", status_code=201, tags=["Users"])
async def create_user(user: CreateUserRequest):
    """Register a new user."""
    return {
        "id": "usr_abc123",
        "username": user.username,
        "display_name": user.display_name,
        "bio": user.bio,
        "profile_image_url": "https://cdn.example.com/defaults/avatar.png",
        "is_verified": False,
        "is_private": False,
        "stats": {
            "posts_count": 0,
            "followers_count": 0,
            "following_count": 0
        },
        "created_at": datetime.utcnow().isoformat()
    }

@app.get("/api/v2/users/{username}", tags=["Users"])
async def get_user_profile(username: str):
    """
    Get a user's public profile.
    
    Returns different data based on relationship:
    - Self: Full profile with settings
    - Following: Full profile
    - Not following (private): Limited profile
    - Not following (public): Full profile
    """
    return {
        "id": "usr_abc123",
        "username": username,
        "display_name": "John Doe",
        "bio": "Software engineer | Photography enthusiast | 🌍 Traveler",
        "website": "https://johndoe.com",
        "location": "San Francisco, CA",
        "profile_image_url": "https://cdn.example.com/users/johndoe/profile.jpg",
        "cover_image_url": "https://cdn.example.com/users/johndoe/cover.jpg",
        "is_verified": True,
        "is_private": False,
        "stats": {
            "posts_count": 342,
            "followers_count": 15200,
            "following_count": 890
        },
        "relationship": {
            "following": True,          # Am I following them?
            "followed_by": False,       # Are they following me?
            "blocked": False,
            "muted": False,
            "follow_request_sent": False
        },
        "joined_at": "2022-03-15T10:00:00Z"
    }

@app.patch("/api/v2/users/me", tags=["Users"])
async def update_profile(updates: UpdateProfileRequest):
    """Update authenticated user's profile."""
    pass


# ============================================================
# FOLLOW / SOCIAL GRAPH APIs
# ============================================================

@app.post("/api/v2/users/{username}/follow", tags=["Social Graph"])
async def follow_user(username: str):
    """
    Follow a user.
    
    If target is private: sends follow request (pending approval)
    If target is public: immediately follows
    
    Idempotent: Following someone you already follow is a no-op.
    """
    return {
        "status": "following",  # or "requested" for private accounts
        "user": {"username": username, "display_name": "John Doe"}
    }

@app.delete("/api/v2/users/{username}/follow", tags=["Social Graph"])
async def unfollow_user(username: str):
    """Unfollow a user. Idempotent."""
    pass

@app.get("/api/v2/users/{username}/followers", tags=["Social Graph"])
async def get_followers(
    username: str,
    cursor: Optional[str] = None,
    limit: int = Query(20, ge=1, le=100)
):
    """
    Get a user's followers list.
    
    Cursor-based pagination (follower lists can be very large).
    Returns mutual follow status for each follower.
    """
    return {
        "data": [
            {
                "id": "usr_xyz",
                "username": "janedoe",
                "display_name": "Jane Doe",
                "profile_image_url": "https://cdn.example.com/users/janedoe/profile.jpg",
                "is_verified": False,
                "is_following": True,  # Do I follow this person?
                "follows_me": True     # Does this person follow me?
            }
        ],
        "pagination": {
            "next_cursor": "eyJ1c2VyX2lkIjoiMTIzIn0",
            "has_more": True
        }
    }

@app.get("/api/v2/users/{username}/following", tags=["Social Graph"])
async def get_following(
    username: str,
    cursor: Optional[str] = None,
    limit: int = Query(20, ge=1, le=100)
):
    """Get list of users that this user follows."""
    pass

@app.get("/api/v2/users/me/follow-requests", tags=["Social Graph"])
async def get_follow_requests(cursor: Optional[str] = None, limit: int = 20):
    """Get pending follow requests (for private accounts)."""
    pass

@app.post("/api/v2/users/me/follow-requests/{request_id}/accept", tags=["Social Graph"])
async def accept_follow_request(request_id: str):
    """Accept a pending follow request."""
    pass

@app.post("/api/v2/users/me/follow-requests/{request_id}/reject", tags=["Social Graph"])
async def reject_follow_request(request_id: str):
    """Reject a pending follow request."""
    pass


# ============================================================
# POST / CONTENT APIs
# ============================================================

class PostType(str, Enum):
    TEXT = "text"
    IMAGE = "image"
    VIDEO = "video"
    POLL = "poll"
    LINK = "link"
    REPOST = "repost"

class CreatePostRequest(BaseModel):
    content: str = Field(..., max_length=5000)
    media_ids: List[str] = Field(default=[], max_items=10)
    post_type: PostType = PostType.TEXT
    reply_to_id: Optional[str] = None       # If this is a reply
    quote_post_id: Optional[str] = None     # If this is a quote repost
    poll: Optional[dict] = None             # Poll options
    mentioned_users: List[str] = []          # @mentions
    hashtags: List[str] = []                 # #hashtags
    location: Optional[dict] = None
    visibility: str = Field(default="public", regex="^(public|followers|mentioned)$")

@app.post("/api/v2/posts", status_code=201, tags=["Posts"])
async def create_post(
    post: CreatePostRequest,
    idempotency_key: str = Header(...)
):
    """
    Create a new post.
    
    Server-side processing:
    1. Content moderation (text + images)
    2. Extract hashtags, mentions, URLs
    3. Generate link previews
    4. Process media (resize, thumbnails)
    5. Fan-out to followers' feeds
    6. Send notifications to mentioned users
    7. Update trending topics
    
    Rate limit: 30 posts/hour, 300 posts/day
    """
    return {
        "id": "post_abc123",
        "author": {
            "id": "usr_abc123",
            "username": "johndoe",
            "display_name": "John Doe",
            "profile_image_url": "https://cdn.example.com/users/johndoe/profile.jpg",
            "is_verified": True
        },
        "content": post.content,
        "post_type": post.post_type,
        "media": [
            {
                "id": "med_1",
                "type": "image",
                "url": "https://cdn.example.com/media/photo1.jpg",
                "thumbnail_url": "https://cdn.example.com/media/photo1_thumb.jpg",
                "width": 1920,
                "height": 1080,
                "alt_text": "A beautiful sunset",
                "blurhash": "LEHV6nWB2yk8pyo0adR*.7kCMdnj"
            }
        ],
        "hashtags": ["#photography", "#sunset"],
        "mentions": [{"username": "janedoe", "user_id": "usr_xyz"}],
        "link_preview": None,
        "location": {"name": "Golden Gate Bridge", "latitude": 37.8199, "longitude": -122.4783},
        "visibility": "public",
        "stats": {
            "likes_count": 0,
            "comments_count": 0,
            "reposts_count": 0,
            "views_count": 0,
            "bookmarks_count": 0
        },
        "viewer_interaction": {
            "liked": False,
            "reposted": False,
            "bookmarked": False
        },
        "created_at": datetime.utcnow().isoformat()
    }

@app.get("/api/v2/posts/{post_id}", tags=["Posts"])
async def get_post(post_id: str):
    """Get a single post with full details."""
    pass

@app.delete("/api/v2/posts/{post_id}", status_code=204, tags=["Posts"])
async def delete_post(post_id: str):
    """
    Delete a post. Only the author can delete.
    Soft delete: keeps record but removes from feeds.
    """
    pass

@app.get("/api/v2/users/{username}/posts", tags=["Posts"])
async def get_user_posts(
    username: str,
    post_type: Optional[PostType] = None,
    include_replies: bool = Query(False),
    cursor: Optional[str] = None,
    limit: int = Query(20, ge=1, le=50)
):
    """
    Get posts by a specific user.
    Cursor-based pagination sorted by created_at DESC.
    """
    pass


# ============================================================
# ENGAGEMENT APIs (Likes, Comments, Reposts, Bookmarks)
# ============================================================

@app.post("/api/v2/posts/{post_id}/like", tags=["Engagement"])
async def like_post(post_id: str):
    """
    Like a post.
    
    Idempotent: Liking an already-liked post is a no-op.
    
    Triggers:
    - Notification to post author
    - Update like counter (async, eventually consistent)
    """
    return {"liked": True, "likes_count": 43}

@app.delete("/api/v2/posts/{post_id}/like", tags=["Engagement"])
async def unlike_post(post_id: str):
    """Unlike a post. Idempotent."""
    return {"liked": False, "likes_count": 42}

@app.get("/api/v2/posts/{post_id}/likes", tags=["Engagement"])
async def get_post_likes(
    post_id: str,
    cursor: Optional[str] = None,
    limit: int = Query(20, ge=1, le=100)
):
    """Get users who liked a post."""
    pass


class CreateCommentRequest(BaseModel):
    content: str = Field(..., min_length=1, max_length=2000)
    reply_to_comment_id: Optional[str] = None  # Threaded replies
    media_ids: List[str] = []

@app.post("/api/v2/posts/{post_id}/comments", status_code=201, tags=["Engagement"])
async def create_comment(
    post_id: str,
    comment: CreateCommentRequest,
    idempotency_key: str = Header(...)
):
    """
    Add a comment to a post.
    
    Supports threaded/nested replies via reply_to_comment_id.
    Rate limit: 30 comments/minute
    """
    return {
        "id": "cmt_abc123",
        "post_id": post_id,
        "author": {
            "id": "usr_abc123",
            "username": "johndoe",
            "display_name": "John Doe",
            "profile_image_url": "https://cdn.example.com/users/johndoe/profile.jpg"
        },
        "content": comment.content,
        "reply_to": comment.reply_to_comment_id,
        "likes_count": 0,
        "replies_count": 0,
        "created_at": datetime.utcnow().isoformat()
    }

@app.get("/api/v2/posts/{post_id}/comments", tags=["Engagement"])
async def get_comments(
    post_id: str,
    sort_by: str = Query("top", regex="^(top|newest|oldest)$"),
    cursor: Optional[str] = None,
    limit: int = Query(20, ge=1, le=50)
):
    """
    Get comments on a post.
    
    Returns top-level comments with a preview of replies.
    Use GET /comments/{comment_id}/replies for full reply thread.
    """
    return {
        "data": [
            {
                "id": "cmt_1",
                "author": {"username": "janedoe", "display_name": "Jane Doe"},
                "content": "Amazing photo! Where was this taken?",
                "likes_count": 15,
                "replies_count": 3,
                "reply_preview": [
                    {
                        "id": "cmt_1_reply_1",
                        "author": {"username": "johndoe"},
                        "content": "Thanks! This was at Golden Gate Bridge 🌉",
                        "likes_count": 8
                    }
                ],
                "viewer_liked": False,
                "created_at": "2024-01-20T16:00:00Z"
            }
        ],
        "pagination": {"next_cursor": "xyz", "has_more": True}
    }

@app.post("/api/v2/posts/{post_id}/repost", tags=["Engagement"])
async def repost(post_id: str):
    """Repost (share) a post to your followers."""
    pass

@app.post("/api/v2/posts/{post_id}/bookmark", tags=["Engagement"])
async def bookmark_post(post_id: str):
    """Save a post to bookmarks. Idempotent."""
    pass

@app.get("/api/v2/users/me/bookmarks", tags=["Engagement"])
async def get_bookmarks(cursor: Optional[str] = None, limit: int = 20):
    """Get saved/bookmarked posts."""
    pass


# ============================================================
# MEDIA UPLOAD API
# ============================================================

@app.post("/api/v2/media/upload", tags=["Media"])
async def upload_media(
    file: UploadFile = File(...),
    alt_text: Optional[str] = None
):
    """
    Upload media (images/videos) for use in posts.
    
    Flow:
    1. Client uploads file
    2. Server validates (type, size, content moderation)
    3. Server processes (resize, compress, generate thumbnails)
    4. Returns media_id to use in create_post
    
    Supported: JPEG, PNG, GIF, WebP, MP4, MOV
    Max size: Images 10MB, Videos 512MB
    
    Rate limit: 50 uploads/hour
    """
    return {
        "id": "med_abc123",
        "type": "image",
        "url": "https://cdn.example.com/media/full/abc123.jpg",
        "thumbnail_url": "https://cdn.example.com/media/thumb/abc123.jpg",
        "width": 1920,
        "height": 1080,
        "file_size_bytes": 2456789,
        "content_type": "image/jpeg",
        "alt_text": alt_text,
        "blurhash": "LEHV6nWB2yk8pyo0adR*.7kCMdnj",
        "processing_status": "completed",
        "created_at": datetime.utcnow().isoformat()
    }


# ============================================================
# NEWS FEED API
# ============================================================

@app.get("/api/v2/feed", tags=["Feed"])
async def get_feed(
    cursor: Optional[str] = None,
    limit: int = Query(20, ge=1, le=50),
    feed_type: str = Query("for_you", regex="^(for_you|following|trending)$")
):
    """
    Get personalized news feed.
    
    Feed generation strategies:
    
    1. PULL model (Fan-in / Read-heavy):
       - At read time, query all followed users' posts
       - Merge and rank
       - Good for users following many accounts
       
    2. PUSH model (Fan-out / Write-heavy):
       - When user posts, write to all followers' feed caches
       - At read time, just read from cache
       - Good for users with few followers
       
    3. HYBRID (what most platforms use):
       - Push for regular users (< 10K followers)
       - Pull for celebrities (millions of followers)
       - Combine at read time
    
    Ranking algorithm considers:
    - Recency
    - Engagement (likes, comments, shares)
    - User affinity (how often you interact with the author)
    - Content type preference
    - Diversity (don't show too many posts from same author)
    
    Cursor-based pagination is essential:
    - Feed items can be inserted/removed between requests
    - Offset-based would cause skips and duplicates
    """
    return {
        "data": [
            {
                "feed_item_type": "post",  # post, suggested_follow, ad, trending_topic
                "post": {
                    "id": "post_abc123",
                    "author": {
                        "id": "usr_xyz",
                        "username": "janedoe",
                        "display_name": "Jane Doe",
                        "profile_image_url": "https://cdn.example.com/users/janedoe/profile.jpg",
                        "is_verified": True
                    },
                    "content": "Just launched my new photography portfolio! Check it out 📸",
                    "media": [
                        {
                            "type": "image",
                            "url": "https://cdn.example.com/media/photo.jpg",
                            "thumbnail_url": "https://cdn.example.com/media/photo_thumb.jpg",
                            "blurhash": "LEHV6nWB2yk8pyo0adR*.7kCMdnj"
                        }
                    ],
                    "stats": {
                        "likes_count": 234,
                        "comments_count": 18,
                        "reposts_count": 12,
                        "views_count": 5420
                    },
                    "viewer_interaction": {
                        "liked": False,
                        "reposted": False,
                        "bookmarked": False
                    },
                    "created_at": "2024-01-20T14:30:00Z"
                },
                "reason": "followed_by_you",  # Why this appeared in feed
                "ranking_score": 0.95
            },
            {
                "feed_item_type": "suggested_follow",
                "suggestion": {
                    "users": [
                        {
                            "username": "photographer_bob",
                            "display_name": "Bob the Photographer",
                            "profile_image_url": "...",
                            "bio": "Award-winning photographer",
                            "mutual_followers_count": 5,
                            "mutual_followers_preview": ["alice", "charlie"]
                        }
                    ],
                    "reason": "Based on people you follow"
                }
            }
        ],
        "pagination": {
            "next_cursor": "eyJ0cyI6IjIwMjQtMDEtMjBUMTQ6MDA6MDBaIiwic2NvcmUiOjAuODV9",
            "has_more": True
        }
    }


# ============================================================
# SEARCH & DISCOVERY APIs
# ============================================================

@app.get("/api/v2/search", tags=["Search"])
async def search(
    q: str = Query(..., min_length=1, max_length=200),
    type: str = Query("top", regex="^(top|users|posts|hashtags)$"),
    cursor: Optional[str] = None,
    limit: int = Query(20, ge=1, le=50)
):
    """
    Universal search across users, posts, and hashtags.
    
    'top' returns a mix of all types, ranked by relevance.
    
    Search infrastructure: Elasticsearch/Meilisearch
    Rate limit: 30 searches/minute
    """
    return {
        "data": {
            "users": [
                {
                    "id": "usr_1",
                    "username": "johndoe",
                    "display_name": "John Doe",
                    "bio": "Software engineer",
                    "is_verified": True,
                    "followers_count": 15200,
                    "is_following": False
                }
            ],
            "posts": [
                {
                    "id": "post_1",
                    "author": {"username": "janedoe"},
                    "content": "Matching content...",
                    "highlight": "Matching <mark>content</mark>...",  # Search highlight
                    "created_at": "2024-01-20T14:30:00Z"
                }
            ],
            "hashtags": [
                {"name": "#photography", "posts_count": 125000},
                {"name": "#photographer", "posts_count": 89000}
            ]
        },
        "pagination": {"next_cursor": "abc", "has_more": True}
    }

@app.get("/api/v2/trending", tags=["Discovery"])
async def get_trending(
    category: Optional[str] = Query(None, description="Filter by category")
):
    """
    Get trending topics and hashtags.
    
    Updated every 5 minutes.
    Personalized based on user's interests and location.
    """
    return {
        "trends": [
            {
                "rank": 1,
                "hashtag": "#TechConf2024",
                "category": "Technology",
                "posts_count": 45000,
                "description": "Annual technology conference happening this week"
            },
            {
                "rank": 2,
                "hashtag": "#Photography",
                "category": "Art",
                "posts_count": 12000
            }
        ],
        "updated_at": "2024-01-20T15:30:00Z"
    }


# ============================================================
# DIRECT MESSAGING APIs
# ============================================================

@app.get("/api/v2/messages/conversations", tags=["Messages"])
async def list_conversations(
    cursor: Optional[str] = None,
    limit: int = Query(20, ge=1, le=50)
):
    """
    Get list of conversations (inbox).
    Sorted by last message timestamp.
    """
    return {
        "data": [
            {
                "id": "conv_abc123",
                "type": "direct",  # direct, group
                "participants": [
                    {"id": "usr_xyz", "username": "janedoe", "display_name": "Jane Doe",
                     "profile_image_url": "..."}
                ],
                "last_message": {
                    "id": "msg_999",
                    "content": "See you tomorrow!",
                    "sender_id": "usr_xyz",
                    "sent_at": "2024-01-20T15:45:00Z",
                    "is_read": False
                },
                "unread_count": 3,
                "is_muted": False,
                "updated_at": "2024-01-20T15:45:00Z"
            }
        ],
        "total_unread": 7,
        "pagination": {"next_cursor": "def", "has_more": True}
    }

@app.get("/api/v2/messages/conversations/{conversation_id}/messages", tags=["Messages"])
async def get_messages(
    conversation_id: str,
    cursor: Optional[str] = None,
    limit: int = Query(50, ge=1, le=100),
    direction: str = Query("older", regex="^(older|newer)$")
):
    """
    Get messages in a conversation.
    
    Cursor-based, loading older messages as user scrolls up.
    """
    return {
        "data": [
            {
                "id": "msg_001",
                "conversation_id": conversation_id,
                "sender": {"id": "usr_abc123", "username": "johndoe"},
                "content": "Hey! How are you?",
                "media": [],
                "type": "text",  # text, image, video, link, reaction
                "status": "read",  # sent, delivered, read
                "reactions": [
                    {"emoji": "❤️", "user_ids": ["usr_xyz"]}
                ],
                "reply_to": None,
                "sent_at": "2024-01-20T15:40:00Z",
                "read_at": "2024-01-20T15:41:00Z"
            }
        ],
        "pagination": {"next_cursor": "ghi", "has_more": True}
    }

class SendMessageRequest(BaseModel):
    content: Optional[str] = Field(None, max_length=5000)
    media_ids: List[str] = []
    reply_to_message_id: Optional[str] = None

@app.post("/api/v2/messages/conversations/{conversation_id}/messages", 
          status_code=201, tags=["Messages"])
async def send_message(
    conversation_id: str,
    message: SendMessageRequest,
    idempotency_key: str = Header(...)
):
    """
    Send a message in a conversation.
    
    Idempotent: prevents duplicate messages on network retry.
    Rate limit: 60 messages/minute
    """
    pass

@app.post("/api/v2/messages/conversations/{conversation_id}/read", tags=["Messages"])
async def mark_as_read(conversation_id: str, last_read_message_id: str):
    """Mark messages as read up to a specific message."""
    pass


# ============================================================
# REAL-TIME MESSAGING (WebSocket)
# ============================================================

@app.websocket("/api/v2/messages/stream")
async def message_stream(websocket: WebSocket):
    """
    WebSocket for real-time messaging.
    
    Events:
    - new_message: New message received
    - message_read: Message was read by recipient  
    - typing: User is typing
    - presence: User online/offline status
    - reaction: Message reaction added/removed
    
    Much more efficient than polling for new messages.
    """
    await websocket.accept()
    
    try:
        while True:
            # Receive client events (typing indicators, read receipts)
            data = await websocket.receive_json()
            
            if data["type"] == "typing":
                # Broadcast typing indicator to other participants
                await broadcast_to_conversation(
                    data["conversation_id"],
                    {"type": "typing", "user_id": "usr_abc123"}
                )
            elif data["type"] == "read_receipt":
                # Mark messages as read
                await mark_messages_read(
                    data["conversation_id"],
                    data["last_read_message_id"]
                )
            
            # Server pushes new messages
            # await websocket.send_json({
            #     "type": "new_message",
            #     "data": {...}
            # })
    except Exception:
        await websocket.close()


# ============================================================
# NOTIFICATION APIs
# ============================================================

@app.get("/api/v2/notifications", tags=["Notifications"])
async def get_notifications(
    cursor: Optional[str] = None,
    limit: int = Query(30, ge=1, le=50),
    filter: Optional[str] = Query(None, regex="^(all|mentions|likes|follows|comments)$")
):
    """
    Get user notifications.
    
    Notifications are grouped for efficiency:
    "Jane, Bob, and 3 others liked your post"
    """
    return {
        "data": [
            {
                "id": "notif_001",
                "type": "like",
                "is_read": False,
                "group": {
                    "actors": [
                        {"username": "janedoe", "display_name": "Jane Doe", "profile_image_url": "..."},
                        {"username": "bobsmith", "display_name": "Bob Smith", "profile_image_url": "..."}
                    ],
                    "total_actors": 5,
                    "display_text": "Jane Doe, Bob Smith, and 3 others liked your post"
                },
                "target": {
                    "type": "post",
                    "id": "post_abc123",
                    "preview": "Just launched my new photography..."
                },
                "created_at": "2024-01-20T15:30:00Z"
            },
            {
                "id": "notif_002",
                "type": "follow",
                "is_read": True,
                "group": {
                    "actors": [
                        {"username": "newuser", "display_name": "New User"}
                    ],
                    "total_actors": 1,
                    "display_text": "New User started following you"
                },
                "target": None,
                "created_at": "2024-01-20T14:00:00Z"
            }
        ],
        "unread_count": 12,
        "pagination": {"next_cursor": "jkl", "has_more": True}
    }

@app.post("/api/v2/notifications/read-all", tags=["Notifications"])
async def mark_all_notifications_read():
    """Mark all notifications as read."""
    pass

@app.get("/api/v2/notifications/unread-count", tags=["Notifications"])
async def get_unread_count():
    """
    Lightweight endpoint for badge count.
    Called frequently (polling) or pushed via WebSocket.
    """
    return {"unread_count": 12}


# ============================================================
# STORIES (Ephemeral Content) APIs
# ============================================================

@app.post("/api/v2/stories", status_code=201, tags=["Stories"])
async def create_story(
    media_id: str,
    caption: Optional[str] = Field(None, max_length=200),
    duration_seconds: int = Field(default=5, ge=3, le=15),
    stickers: List[dict] = [],
    mentions: List[str] = []
):
    """
    Create a story (auto-expires after 24 hours).
    
    Rate limit: 50 stories/day
    """
    return {
        "id": "story_abc123",
        "media_url": "https://cdn.example.com/stories/abc123.jpg",
        "caption": caption,
        "expires_at": "2024-01-21T15:30:00Z",
        "view_count": 0,
        "created_at": datetime.utcnow().isoformat()
    }

@app.get("/api/v2/stories/feed", tags=["Stories"])
async def get_stories_feed():
    """
    Get stories from followed users.
    
    Returns grouped by user, sorted by:
    1. Unseen stories first
    2. Close friends
    3. Most interacted-with users
    """
    return {
        "data": [
            {
                "user": {
                    "id": "usr_xyz",
                    "username": "janedoe",
                    "profile_image_url": "...",
                    "has_unseen": True
                },
                "stories": [
                    {
                        "id": "story_1",
                        "media_url": "https://cdn.example.com/stories/1.jpg",
                        "media_type": "image",
                        "caption": "Morning vibes ☀️",
                        "duration_seconds": 5,
                        "is_seen": False,
                        "view_count": 45,
                        "created_at": "2024-01-20T08:00:00Z",
                        "expires_at": "2024-01-21T08:00:00Z"
                    }
                ]
            }
        ]
    }

@app.post("/api/v2/stories/{story_id}/view", tags=["Stories"])
async def mark_story_viewed(story_id: str):
    """Mark a story as viewed. Idempotent."""
    pass

@app.get("/api/v2/stories/{story_id}/viewers", tags=["Stories"])
async def get_story_viewers(
    story_id: str,
    cursor: Optional[str] = None,
    limit: int = 20
):
    """Get list of users who viewed your story."""
    pass
```

---

## Complete Cross-Cutting Concerns Summary

```python
# ============================================================
# PUTTING IT ALL TOGETHER: Complete API Setup
# ============================================================

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.gzip import GZipMiddleware

def create_app() -> FastAPI:
    """Factory function with all middleware and configuration."""
    
    app = FastAPI(
        title="Platform API",
        version="2.0.0",
        docs_url="/api/docs",
        redoc_url="/api/redoc",
        openapi_url="/api/openapi.json"
    )
    
    # ---- CORS ----
    app.add_middleware(
        CORSMiddleware,
        allow_origins=["https://app.example.com"],
        allow_methods=["*"],
        allow_headers=["*"],
        expose_headers=[
            "X-RateLimit-Limit",
            "X-RateLimit-Remaining", 
            "X-RateLimit-Reset",
            "X-Request-Id"
        ]
    )
    
    # ---- Compression ----
    app.add_middleware(GZipMiddleware, minimum_size=1000)
    
    # ---- Rate Limiting ----
    app.add_middleware(RateLimitMiddleware)
    
    # ---- API Versioning ----
    app.add_middleware(VersionDeprecationMiddleware)
    
    # ---- Request ID Tracking ----
    @app.middleware("http")
    async def add_request_id(request, call_next):
        request_id = request.headers.get("X-Request-Id", str(uuid.uuid4()))
        response = await call_next(request)
        response.headers["X-Request-Id"] = request_id
        return response
    
    # ---- Global Error Handling ----
    @app.exception_handler(HTTPException)
    async def http_exception_handler(request, exc):
        return JSONResponse(
            status_code=exc.status_code,
            content={
                "error": {
                    "code": exc.status_code,
                    "type": STATUS_CODE_MAP.get(exc.status_code, "error"),
                    "message": exc.detail,
                    "request_id": request.headers.get("X-Request-Id"),
                    "documentation_url": f"https://docs.example.com/errors/{exc.status_code}"
                }
            }
        )
    
    # ---- Health Check ----
    @app.get("/health")
    async def health():
        return {"status": "healthy", "version": "2.0.0", "timestamp": datetime.utcnow()}
    
    # ---- Include Routers ----
    app.include_router(v2_router)
    
    return app


"""
┌─────────────────────────────────────────────────────────────────┐
│                SUMMARY: API DESIGN CHECKLIST                     │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ☑ REST for public APIs, gRPC for internal microservices        │
│                                                                  │
│  ☑ Idempotency keys for mutations (POST /orders, /payments)     │
│    → Client generates key, server caches result                  │
│    → Same key = same response (no double processing)             │
│                                                                  │
│  ☑ Cursor-based pagination for feeds and large lists             │
│    → Offset for admin dashboards with page jumping              │
│    → Keyset for pre-sorted data                                  │
│                                                                  │
│  ☑ Rate limiting per user/API key with appropriate headers       │
│    → Token bucket for burst tolerance                            │
│    → Different limits for different endpoints                    │
│    → 429 response with Retry-After header                       │
│                                                                  │
│  ☑ API versioning via URL path (/api/v2/...)                    │
│    → Deprecation headers for old versions                        │
│    → Sunset dates and migration guides                           │
│                                                                  │
│  ☑ Consistent error format across all endpoints                  │
│  ☑ Request ID tracking for debugging                             │
│  ☑ HATEOAS links where appropriate                               │
│  ☑ Proper HTTP status codes                                      │
│  ☑ Input validation with clear error messages                    │
│  ☑ WebSocket for real-time features (tracking, messaging)       │
│  ☑ CORS and security headers                                     │
│  ☑ Response compression (gzip)                                   │
│  ☑ API documentation (OpenAPI/Swagger)                           │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
"""
```

Each of these four API designs demonstrates how the five core concepts — **REST vs gRPC**, **Idempotency**, **Pagination**, **Rate Limiting**, and **API Versioning** — apply differently depending on the domain while following the same fundamental principles. The key takeaway: good API design is about **consistency**, **safety** (idempotency), **efficiency** (pagination, gRPC), **fairness** (rate limiting), and **evolution** (versioning).