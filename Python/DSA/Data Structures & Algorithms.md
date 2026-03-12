Data Structures & Algorithms — The Complete Guide

## Why DSA Matters

```
Real Problem → Choose Right Data Structure → Apply Right Algorithm → Efficient Solution
```

> Every interview, every system you build, every optimization you make
> comes back to **how you store data** and **how you process it**.

---

## PART 1: DATA STRUCTURES

---

## 1. Arrays

The most basic and widely used data structure.

### Core Concept
```
Contiguous block of memory, fixed size, index-based access.

Index:    0     1     2     3     4
        ┌─────┬─────┬─────┬─────┬─────┐
Values: │  10 │  20 │  30 │  40 │  50 │
        └─────┴─────┴─────┴─────┴─────┘

Memory:  100   104   108   112   116  (addresses, 4 bytes each)
```

### Key Operations & Complexities
```
╔══════════════════════╦═══════════╗
║ Operation            ║ Time      ║
╠══════════════════════╬═══════════╣
║ Access by index      ║ O(1)      ║
║ Search (unsorted)    ║ O(n)      ║
║ Search (sorted)      ║ O(log n)  ║
║ Insert at end        ║ O(1)*     ║
║ Insert at beginning  ║ O(n)      ║
║ Delete at index      ║ O(n)      ║
╚══════════════════════╩═══════════╝
* Amortized for dynamic arrays
```

### Types of Arrays
```
1. Static Array    → Fixed size, declared at compile time
2. Dynamic Array   → Resizable (ArrayList, Vector, Python list)
3. 2D Array        → Matrix / Grid
4. Circular Array  → End wraps to beginning
```

### Implementation — Dynamic Array
```python
class DynamicArray:
    def __init__(self):
        self.size = 0              # Number of actual elements
        self.capacity = 1          # Total space available
        self.arr = [None] * self.capacity

    def append(self, value):
        # If full, double the capacity
        if self.size == self.capacity:
            self._resize(2 * self.capacity)
        self.arr[self.size] = value
        self.size += 1

    def get(self, index):
        if 0 <= index < self.size:
            return self.arr[index]
        raise IndexError("Index out of bounds")

    def insert(self, index, value):
        if self.size == self.capacity:
            self._resize(2 * self.capacity)
        # Shift elements right
        for i in range(self.size, index, -1):
            self.arr[i] = self.arr[i - 1]
        self.arr[index] = value
        self.size += 1

    def delete(self, index):
        # Shift elements left
        for i in range(index, self.size - 1):
            self.arr[i] = self.arr[i + 1]
        self.size -= 1

    def _resize(self, new_capacity):
        new_arr = [None] * new_capacity
        for i in range(self.size):
            new_arr[i] = self.arr[i]
        self.arr = new_arr
        self.capacity = new_capacity
```

### Classic Interview Patterns
```python
# Pattern 1: Two Pointers (Sorted Array)
def two_sum_sorted(arr, target):
    """Find two numbers that add up to target"""
    left, right = 0, len(arr) - 1
    while left < right:
        current_sum = arr[left] + arr[right]
        if current_sum == target:
            return [left, right]
        elif current_sum < target:
            left += 1
        else:
            right -= 1
    return [-1, -1]

# Pattern 2: Sliding Window
def max_sum_subarray(arr, k):
    """Find maximum sum subarray of size k"""
    window_sum = sum(arr[:k])
    max_sum = window_sum
    for i in range(k, len(arr)):
        window_sum += arr[i] - arr[i - k]   # Slide the window
        max_sum = max(max_sum, window_sum)
    return max_sum

# Pattern 3: Kadane's Algorithm (Maximum Subarray)
def max_subarray(arr):
    """Find contiguous subarray with largest sum"""
    current_max = global_max = arr[0]
    for i in range(1, len(arr)):
        current_max = max(arr[i], current_max + arr[i])
        global_max = max(global_max, current_max)
    return global_max

# Pattern 4: Dutch National Flag (3-way partition)
def sort_colors(nums):
    """Sort array of 0s, 1s, 2s in-place"""
    low, mid, high = 0, 0, len(nums) - 1
    while mid <= high:
        if nums[mid] == 0:
            nums[low], nums[mid] = nums[mid], nums[low]
            low += 1
            mid += 1
        elif nums[mid] == 1:
            mid += 1
        else:
            nums[mid], nums[high] = nums[high], nums[mid]
            high -= 1

# Pattern 5: Prefix Sum
def range_sum(arr, queries):
    """Answer multiple range sum queries efficiently"""
    # Build prefix sum: O(n)
    prefix = [0] * (len(arr) + 1)
    for i in range(len(arr)):
        prefix[i + 1] = prefix[i] + arr[i]
    
    # Answer each query: O(1)
    results = []
    for left, right in queries:
        results.append(prefix[right + 1] - prefix[left])
    return results
```

---

## 2. Linked Lists

### Core Concept
```
Elements (nodes) connected by pointers, not contiguous memory.

Singly Linked List:
┌───┬───┐    ┌───┬───┐    ┌───┬───┐    ┌───┬──────┐
│ 1 │ ──┼───>│ 2 │ ──┼───>│ 3 │ ──┼───>│ 4 │ None │
└───┴───┘    └───┴───┘    └───┴───┘    └───┴──────┘
 data next    data next    data next    data  next

Doubly Linked List:
       ┌──────┬───┬───┐    ┌───┬───┬───┐    ┌───┬───┬──────┐
None ◄─┤ prev │ 1 │ ──┼───>│◄──│ 2 │ ──┼───>│◄──│ 3 │ None │
       └──────┴───┴───┘    └───┴───┴───┘    └───┴───┴──────┘

Circular Linked List:
┌───┬───┐    ┌───┬───┐    ┌───┬───┐
│ 1 │ ──┼───>│ 2 │ ──┼───>│ 3 │ ──┼──┐
└───┴───┘    └───┴───┘    └───┴───┘  │
  ▲                                   │
  └───────────────────────────────────┘
```

### Key Operations & Complexities
```
╔══════════════════════════╦══════════════════════════════╗
║ Operation                ║ Singly    Doubly             ║
╠══════════════════════════╬══════════════════════════════╣
║ Access by index          ║ O(n)      O(n)               ║
║ Insert at head           ║ O(1)      O(1)               ║
║ Insert at tail           ║ O(n)*     O(1)               ║
║ Delete head              ║ O(1)      O(1)               ║
║ Delete specific node     ║ O(n)      O(1) if ref given  ║
║ Search                   ║ O(n)      O(n)               ║
╚══════════════════════════╩══════════════════════════════╝
* O(1) if we maintain a tail pointer
```

### Implementation
```python
# --- Singly Linked List ---
class ListNode:
    def __init__(self, val=0, next=None):
        self.val = val
        self.next = next

class SinglyLinkedList:
    def __init__(self):
        self.head = None

    def insert_at_head(self, val):
        new_node = ListNode(val)
        new_node.next = self.head
        self.head = new_node                   # O(1)

    def insert_at_tail(self, val):
        new_node = ListNode(val)
        if not self.head:
            self.head = new_node
            return
        curr = self.head
        while curr.next:                       # O(n)
            curr = curr.next
        curr.next = new_node

    def delete(self, val):
        if not self.head:
            return
        if self.head.val == val:               # Delete head
            self.head = self.head.next
            return
        curr = self.head
        while curr.next:
            if curr.next.val == val:
                curr.next = curr.next.next     # Bypass the node
                return
            curr = curr.next

    def search(self, val):
        curr = self.head
        while curr:
            if curr.val == val:
                return True
            curr = curr.next
        return False

    def display(self):
        curr = self.head
        while curr:
            print(curr.val, end=" -> ")
            curr = curr.next
        print("None")


# --- Doubly Linked List ---
class DoublyNode:
    def __init__(self, val=0):
        self.val = val
        self.prev = None
        self.next = None

class DoublyLinkedList:
    def __init__(self):
        # Sentinel nodes to simplify edge cases
        self.head = DoublyNode(0)    # dummy head
        self.tail = DoublyNode(0)    # dummy tail
        self.head.next = self.tail
        self.tail.prev = self.head

    def insert_after(self, node, val):
        new = DoublyNode(val)
        new.prev = node
        new.next = node.next
        node.next.prev = new
        node.next = new
        return new

    def delete(self, node):
        node.prev.next = node.next
        node.next.prev = node.prev  # O(1) with reference
```

### Classic Interview Patterns
```python
# Pattern 1: Reverse a Linked List (MOST COMMON)
def reverse_list(head):
    prev = None
    curr = head
    while curr:
        next_node = curr.next    # Save next
        curr.next = prev         # Reverse pointer
        prev = curr              # Move prev forward
        curr = next_node         # Move curr forward
    return prev                  # New head

    # Visualization:
    # 1 -> 2 -> 3 -> None
    # Step 1: None <- 1    2 -> 3 -> None
    # Step 2: None <- 1 <- 2    3 -> None
    # Step 3: None <- 1 <- 2 <- 3

# Pattern 2: Detect Cycle (Floyd's Tortoise & Hare)
def has_cycle(head):
    slow = fast = head
    while fast and fast.next:
        slow = slow.next           # 1 step
        fast = fast.next.next      # 2 steps
        if slow == fast:
            return True            # They met = cycle exists
    return False

# Pattern 3: Find Middle Node
def find_middle(head):
    slow = fast = head
    while fast and fast.next:
        slow = slow.next
        fast = fast.next.next
    return slow                    # slow is at the middle

# Pattern 4: Merge Two Sorted Lists
def merge_sorted(l1, l2):
    dummy = ListNode(0)
    curr = dummy
    while l1 and l2:
        if l1.val <= l2.val:
            curr.next = l1
            l1 = l1.next
        else:
            curr.next = l2
            l2 = l2.next
        curr = curr.next
    curr.next = l1 or l2
    return dummy.next

# Pattern 5: Remove Nth Node From End
def remove_nth_from_end(head, n):
    dummy = ListNode(0, head)
    fast = slow = dummy
    for _ in range(n + 1):        # Move fast n+1 steps ahead
        fast = fast.next
    while fast:                    # Move both until fast hits end
        fast = fast.next
        slow = slow.next
    slow.next = slow.next.next    # Remove the nth node
    return dummy.next

# Pattern 6: Check if Palindrome
def is_palindrome(head):
    # Find middle
    slow = fast = head
    while fast and fast.next:
        slow = slow.next
        fast = fast.next.next
    # Reverse second half
    second = reverse_list(slow)
    # Compare
    first = head
    while second:
        if first.val != second.val:
            return False
        first = first.next
        second = second.next
    return True
```

### Array vs Linked List — When to Use What
```
╔═══════════════════╦═══════════════════╦═══════════════════╗
║ Criteria          ║ Array             ║ Linked List       ║
╠═══════════════════╬═══════════════════╬═══════════════════╣
║ Random access     ║ ✅ O(1)           ║ ❌ O(n)           ║
║ Insert/Delete     ║ ❌ O(n) shifting  ║ ✅ O(1) if ref    ║
║ Memory            ║ Contiguous        ║ Scattered         ║
║ Cache friendly    ║ ✅ Yes            ║ ❌ No             ║
║ Size flexibility  ║ Fixed/Resize      ║ Fully dynamic     ║
║ Extra memory      ║ None              ║ Pointer overhead  ║
╚═══════════════════╩═══════════════════╩═══════════════════╝
```

---

## 3. Stacks & Queues

### Stack — LIFO (Last In, First Out)
```
Think: Stack of plates

    push(40)
       ↓
   ┌──────┐
   │  40  │  ← top (peek/pop from here)
   ├──────┤
   │  30  │
   ├──────┤
   │  20  │
   ├──────┤
   │  10  │
   └──────┘

All operations: O(1)
- push(item): Add to top
- pop():      Remove from top
- peek():     View top without removing
- isEmpty():  Check if empty
```

```python
# Stack Implementation (using array)
class Stack:
    def __init__(self):
        self.items = []

    def push(self, item):
        self.items.append(item)

    def pop(self):
        if self.is_empty():
            raise Exception("Stack is empty")
        return self.items.pop()

    def peek(self):
        if self.is_empty():
            raise Exception("Stack is empty")
        return self.items[-1]

    def is_empty(self):
        return len(self.items) == 0

    def size(self):
        return len(self.items)
```

### Stack Interview Classics
```python
# 1. Valid Parentheses
def is_valid_parentheses(s):
    stack = []
    mapping = {')': '(', '}': '{', ']': '['}
    for char in s:
        if char in mapping:
            if not stack or stack[-1] != mapping[char]:
                return False
            stack.pop()
        else:
            stack.append(char)
    return len(stack) == 0

# 2. Next Greater Element
def next_greater_element(arr):
    """For each element, find the next element that is greater"""
    result = [-1] * len(arr)
    stack = []  # stores indices
    for i in range(len(arr)):
        while stack and arr[i] > arr[stack[-1]]:
            result[stack.pop()] = arr[i]
        stack.append(i)
    return result
    # arr =    [4, 5, 2, 25]
    # result = [5, 25, 25, -1]

# 3. Min Stack — Get minimum in O(1)
class MinStack:
    def __init__(self):
        self.stack = []
        self.min_stack = []   # Track minimums

    def push(self, val):
        self.stack.append(val)
        min_val = min(val, self.min_stack[-1] if self.min_stack else val)
        self.min_stack.append(min_val)

    def pop(self):
        self.stack.pop()
        self.min_stack.pop()

    def getMin(self):
        return self.min_stack[-1]

# 4. Evaluate Reverse Polish Notation
def eval_rpn(tokens):
    stack = []
    ops = {'+': lambda a, b: a + b,
           '-': lambda a, b: a - b,
           '*': lambda a, b: a * b,
           '/': lambda a, b: int(a / b)}
    for token in tokens:
        if token in ops:
            b, a = stack.pop(), stack.pop()
            stack.append(ops[token](a, b))
        else:
            stack.append(int(token))
    return stack[0]
```

### Queue — FIFO (First In, First Out)
```
Think: Line at a ticket counter

enqueue(10)  enqueue(20)  enqueue(30)

  FRONT                         REAR
    ↓                             ↓
┌──────┬──────┬──────┬──────┐
│  10  │  20  │  30  │      │
└──────┴──────┴──────┴──────┘
  ↑ dequeue from here    ↑ enqueue here

All operations: O(1)
```

```python
# Queue using Linked List (efficient)
class QueueNode:
    def __init__(self, val):
        self.val = val
        self.next = None

class Queue:
    def __init__(self):
        self.front = None
        self.rear = None
        self.size = 0

    def enqueue(self, val):
        new_node = QueueNode(val)
        if self.rear:
            self.rear.next = new_node
        self.rear = new_node
        if not self.front:
            self.front = new_node
        self.size += 1

    def dequeue(self):
        if not self.front:
            raise Exception("Queue is empty")
        val = self.front.val
        self.front = self.front.next
        if not self.front:
            self.rear = None
        self.size -= 1
        return val

# Circular Queue (fixed size, wraps around)
class CircularQueue:
    def __init__(self, capacity):
        self.queue = [None] * capacity
        self.capacity = capacity
        self.front = 0
        self.rear = -1
        self.size = 0

    def enqueue(self, val):
        if self.size == self.capacity:
            raise Exception("Queue is full")
        self.rear = (self.rear + 1) % self.capacity
        self.queue[self.rear] = val
        self.size += 1

    def dequeue(self):
        if self.size == 0:
            raise Exception("Queue is empty")
        val = self.queue[self.front]
        self.front = (self.front + 1) % self.capacity
        self.size -= 1
        return val
```

### Deque (Double-Ended Queue)
```python
from collections import deque

# Sliding Window Maximum using Deque
def max_sliding_window(nums, k):
    """Find max in every window of size k"""
    dq = deque()   # stores indices of useful elements
    result = []
    
    for i in range(len(nums)):
        # Remove indices out of window
        while dq and dq[0] < i - k + 1:
            dq.popleft()
        # Remove smaller elements (they'll never be max)
        while dq and nums[dq[-1]] < nums[i]:
            dq.pop()
        dq.append(i)
        # Window is complete
        if i >= k - 1:
            result.append(nums[dq[0]])
    return result
```

---

## 4. Hash Tables (Hash Maps)

### Core Concept
```
Key → Hash Function → Index → Value

     Hash Function
"john" ──────────→  hash("john") % 8 = 3

Index:  0     1     2     3        4     5     6     7
      ┌─────┬─────┬─────┬────────┬─────┬─────┬─────┬─────┐
      │     │     │     │"john"  │     │     │     │     │
      │     │     │     │  → 25  │     │     │     │     │
      └─────┴─────┴─────┴────────┴─────┴─────┴─────┴─────┘
```

### Collision Handling
```
What if hash("john") and hash("jane") both = 3?

Method 1: Chaining (Linked Lists)
Index 3: ["john"→25] → ["jane"→30] → None

Method 2: Open Addressing (Linear Probing)
Index 3: "john"→25
Index 4: "jane"→30  (next available slot)
```

### Complexities
```
╔═══════════════╦═══════════╦════════════╗
║ Operation     ║ Average   ║ Worst Case ║
╠═══════════════╬═══════════╬════════════╣
║ Insert        ║ O(1)      ║ O(n)       ║
║ Search        ║ O(1)      ║ O(n)       ║
║ Delete        ║ O(1)      ║ O(n)       ║
╚═══════════════╩═══════════╩════════════╝
Worst case: all keys collide → everything in one bucket
```

### Implementation from Scratch
```python
class HashTable:
    def __init__(self, size=16):
        self.size = size
        self.buckets = [[] for _ in range(size)]  # Chaining
        self.count = 0

    def _hash(self, key):
        return hash(key) % self.size

    def put(self, key, value):
        index = self._hash(key)
        bucket = self.buckets[index]
        
        # Update if key exists
        for i, (k, v) in enumerate(bucket):
            if k == key:
                bucket[i] = (key, value)
                return
        
        # Insert new
        bucket.append((key, value))
        self.count += 1
        
        # Resize if load factor > 0.75
        if self.count / self.size > 0.75:
            self._resize()

    def get(self, key):
        index = self._hash(key)
        for k, v in self.buckets[index]:
            if k == key:
                return v
        raise KeyError(key)

    def delete(self, key):
        index = self._hash(key)
        bucket = self.buckets[index]
        for i, (k, v) in enumerate(bucket):
            if k == key:
                del bucket[i]
                self.count -= 1
                return
        raise KeyError(key)

    def _resize(self):
        old_buckets = self.buckets
        self.size *= 2
        self.buckets = [[] for _ in range(self.size)]
        self.count = 0
        for bucket in old_buckets:
            for key, value in bucket:
                self.put(key, value)
```

### Interview Patterns with Hash Maps
```python
# 1. Two Sum (THE classic)
def two_sum(nums, target):
    seen = {}  # value → index
    for i, num in enumerate(nums):
        complement = target - num
        if complement in seen:
            return [seen[complement], i]
        seen[num] = i
    return []

# 2. Frequency Counter
def top_k_frequent(nums, k):
    from collections import Counter
    count = Counter(nums)
    return [x for x, _ in count.most_common(k)]

# 3. Group Anagrams
def group_anagrams(strs):
    groups = {}
    for s in strs:
        key = tuple(sorted(s))  # "eat" → ('a','e','t')
        groups.setdefault(key, []).append(s)
    return list(groups.values())

# 4. Longest Consecutive Sequence — O(n)
def longest_consecutive(nums):
    num_set = set(nums)
    longest = 0
    for num in num_set:
        if num - 1 not in num_set:  # Start of sequence
            length = 1
            while num + length in num_set:
                length += 1
            longest = max(longest, length)
    return longest

# 5. Subarray Sum Equals K (Prefix Sum + Hash Map)
def subarray_sum(nums, k):
    count = 0
    prefix_sum = 0
    seen = {0: 1}  # prefix_sum → frequency
    for num in nums:
        prefix_sum += num
        if prefix_sum - k in seen:
            count += seen[prefix_sum - k]
        seen[prefix_sum] = seen.get(prefix_sum, 0) + 1
    return count
```

### Hash Set
```python
# When you only care about presence, not key-value pairs
# Contains Duplicate
def contains_duplicate(nums):
    return len(nums) != len(set(nums))

# Intersection of Two Arrays
def intersection(nums1, nums2):
    return list(set(nums1) & set(nums2))
```

---

## 5. Trees

### Binary Tree — Core Concept
```
         1           ← Root
        / \
       2   3         ← Internal nodes
      / \   \
     4   5   6       ← Leaves (no children)

Terminology:
- Root: Top node (1)
- Parent of 4,5 is 2
- Children of 2 are 4,5
- Leaf: Node with no children (4,5,6)
- Height: Longest path from root to leaf = 2
- Depth of node 5: distance from root = 2
- Level: root is level 0
```

### Types of Trees
```
Binary Tree:         Each node has at most 2 children
BST:                 Left < Parent < Right
AVL Tree:            Self-balancing BST (height diff ≤ 1)
Red-Black Tree:      Self-balancing BST (used in TreeMap, std::map)
B-Tree:              Used in databases and file systems
Segment Tree:        Range queries
Fenwick Tree (BIT):  Prefix operations
N-ary Tree:          Each node has up to N children
```

### Binary Tree Implementation & Traversals
```python
class TreeNode:
    def __init__(self, val=0, left=None, right=None):
        self.val = val
        self.left = left
        self.right = right

# ===== DEPTH-FIRST TRAVERSALS =====

# Inorder: Left → Root → Right  (gives sorted order for BST)
def inorder(root):
    if not root:
        return []
    return inorder(root.left) + [root.val] + inorder(root.right)

# Preorder: Root → Left → Right  (useful for copying tree)
def preorder(root):
    if not root:
        return []
    return [root.val] + preorder(root.left) + preorder(root.right)

# Postorder: Left → Right → Root  (useful for deleting tree)
def postorder(root):
    if not root:
        return []
    return postorder(root.left) + postorder(root.right) + [root.val]

#         1
#        / \
#       2   3
#      / \
#     4   5
#
# Inorder:   [4, 2, 5, 1, 3]
# Preorder:  [1, 2, 4, 5, 3]
# Postorder: [4, 5, 2, 3, 1]

# Iterative Inorder (using stack)
def inorder_iterative(root):
    result, stack = [], []
    curr = root
    while curr or stack:
        while curr:
            stack.append(curr)
            curr = curr.left
        curr = stack.pop()
        result.append(curr.val)
        curr = curr.right
    return result

# ===== BREADTH-FIRST TRAVERSAL (Level Order) =====
from collections import deque

def level_order(root):
    if not root:
        return []
    result = []
    queue = deque([root])
    while queue:
        level = []
        for _ in range(len(queue)):
            node = queue.popleft()
            level.append(node.val)
            if node.left:
                queue.append(node.left)
            if node.right:
                queue.append(node.right)
        result.append(level)
    return result
    # Returns: [[1], [2, 3], [4, 5]]
```

### Binary Search Tree (BST)
```
Property: For every node:
  - All values in LEFT subtree < node
  - All values in RIGHT subtree > node

         8
        / \
       3   10
      / \    \
     1   6    14
        / \   /
       4   7 13

Search for 7:
  8 → go left → 3 → go right → 6 → go right → 7 ✓

Operations: O(h) where h = height
  Balanced BST: h = O(log n)
  Skewed BST:   h = O(n)
```

```python
class BST:
    def __init__(self):
        self.root = None

    def insert(self, val):
        self.root = self._insert(self.root, val)

    def _insert(self, node, val):
        if not node:
            return TreeNode(val)
        if val < node.val:
            node.left = self._insert(node.left, val)
        elif val > node.val:
            node.right = self._insert(node.right, val)
        return node

    def search(self, val):
        return self._search(self.root, val)

    def _search(self, node, val):
        if not node:
            return False
        if val == node.val:
            return True
        elif val < node.val:
            return self._search(node.left, val)
        else:
            return self._search(node.right, val)

    def delete(self, val):
        self.root = self._delete(self.root, val)

    def _delete(self, node, val):
        if not node:
            return None
        if val < node.val:
            node.left = self._delete(node.left, val)
        elif val > node.val:
            node.right = self._delete(node.right, val)
        else:
            # Case 1: Leaf node
            if not node.left and not node.right:
                return None
            # Case 2: One child
            if not node.left:
                return node.right
            if not node.right:
                return node.left
            # Case 3: Two children
            # Find inorder successor (smallest in right subtree)
            successor = self._find_min(node.right)
            node.val = successor.val
            node.right = self._delete(node.right, successor.val)
        return node

    def _find_min(self, node):
        while node.left:
            node = node.left
        return node
```

### Classic Tree Interview Problems
```python
# 1. Maximum Depth (Height)
def max_depth(root):
    if not root:
        return 0
    return 1 + max(max_depth(root.left), max_depth(root.right))

# 2. Check if Balanced
def is_balanced(root):
    def check(node):
        if not node:
            return 0
        left = check(node.left)
        right = check(node.right)
        if left == -1 or right == -1 or abs(left - right) > 1:
            return -1
        return 1 + max(left, right)
    return check(root) != -1

# 3. Lowest Common Ancestor (LCA)
def lca(root, p, q):
    if not root or root == p or root == q:
        return root
    left = lca(root.left, p, q)
    right = lca(root.right, p, q)
    if left and right:
        return root        # p and q are on different sides
    return left or right   # both on same side

# 4. Validate BST
def is_valid_bst(root, min_val=float('-inf'), max_val=float('inf')):
    if not root:
        return True
    if root.val <= min_val or root.val >= max_val:
        return False
    return (is_valid_bst(root.left, min_val, root.val) and
            is_valid_bst(root.right, root.val, max_val))

# 5. Diameter of Binary Tree
def diameter(root):
    max_d = [0]
    def depth(node):
        if not node:
            return 0
        left = depth(node.left)
        right = depth(node.right)
        max_d[0] = max(max_d[0], left + right)
        return 1 + max(left, right)
    depth(root)
    return max_d[0]

# 6. Serialize and Deserialize
def serialize(root):
    if not root:
        return "null"
    return f"{root.val},{serialize(root.left)},{serialize(root.right)}"

def deserialize(data):
    values = iter(data.split(","))
    def build():
        val = next(values)
        if val == "null":
            return None
        node = TreeNode(int(val))
        node.left = build()
        node.right = build()
        return node
    return build()

# 7. Path Sum
def has_path_sum(root, target):
    if not root:
        return False
    if not root.left and not root.right:
        return root.val == target
    return (has_path_sum(root.left, target - root.val) or
            has_path_sum(root.right, target - root.val))
```

---

## 6. Heaps (Priority Queues)

### Core Concept
```
A complete binary tree where parent has priority over children.

Min-Heap: Parent ≤ Children       Max-Heap: Parent ≥ Children

       1                                 9
      / \                              / \
     3   2                            7   8
    / \                              / \
   7   5                            3   5

Array representation (0-indexed):
[1, 3, 2, 7, 5]

For node at index i:
  Parent:      (i - 1) // 2
  Left child:  2 * i + 1
  Right child: 2 * i + 2
```

### Complexities
```
╔════════════════════╦═══════════╗
║ Operation          ║ Time      ║
╠════════════════════╬═══════════╣
║ Insert             ║ O(log n)  ║
║ Extract min/max    ║ O(log n)  ║
║ Peek min/max       ║ O(1)      ║
║ Build heap         ║ O(n)      ║
║ Heapify            ║ O(log n)  ║
╚════════════════════╩═══════════╝
```

### Implementation
```python
class MinHeap:
    def __init__(self):
        self.heap = []

    def insert(self, val):
        self.heap.append(val)
        self._bubble_up(len(self.heap) - 1)

    def extract_min(self):
        if not self.heap:
            raise Exception("Heap is empty")
        min_val = self.heap[0]
        self.heap[0] = self.heap[-1]
        self.heap.pop()
        if self.heap:
            self._bubble_down(0)
        return min_val

    def peek(self):
        return self.heap[0] if self.heap else None

    def _bubble_up(self, index):
        parent = (index - 1) // 2
        while index > 0 and self.heap[index] < self.heap[parent]:
            self.heap[index], self.heap[parent] = self.heap[parent], self.heap[index]
            index = parent
            parent = (index - 1) // 2

    def _bubble_down(self, index):
        n = len(self.heap)
        while True:
            smallest = index
            left = 2 * index + 1
            right = 2 * index + 2
            if left < n and self.heap[left] < self.heap[smallest]:
                smallest = left
            if right < n and self.heap[right] < self.heap[smallest]:
                smallest = right
            if smallest == index:
                break
            self.heap[index], self.heap[smallest] = self.heap[smallest], self.heap[index]
            index = smallest
```

### Using Python's heapq
```python
import heapq

# Min heap (default)
heap = []
heapq.heappush(heap, 5)
heapq.heappush(heap, 1)
heapq.heappush(heap, 3)
print(heapq.heappop(heap))  # 1 (smallest)

# Max heap trick: negate values
max_heap = []
heapq.heappush(max_heap, -5)
heapq.heappush(max_heap, -1)
print(-heapq.heappop(max_heap))  # 5 (largest)

# Build heap from list in O(n)
arr = [5, 3, 8, 1, 2]
heapq.heapify(arr)  # arr is now a valid min-heap

# K largest elements
k_largest = heapq.nlargest(3, arr)
k_smallest = heapq.nsmallest(3, arr)
```

### Classic Heap Interview Problems
```python
# 1. Kth Largest Element
def find_kth_largest(nums, k):
    # Min-heap of size k
    heap = nums[:k]
    heapq.heapify(heap)
    for num in nums[k:]:
        if num > heap[0]:
            heapq.heapreplace(heap, num)
    return heap[0]    # O(n log k)

# 2. Merge K Sorted Lists
def merge_k_lists(lists):
    heap = []
    for i, lst in enumerate(lists):
        if lst:
            heapq.heappush(heap, (lst.val, i, lst))
    
    dummy = ListNode(0)
    curr = dummy
    while heap:
        val, i, node = heapq.heappop(heap)
        curr.next = node
        curr = curr.next
        if node.next:
            heapq.heappush(heap, (node.next.val, i, node.next))
    return dummy.next

# 3. Find Median from Data Stream
class MedianFinder:
    def __init__(self):
        self.small = []   # Max-heap (negate values)
        self.large = []   # Min-heap

    def addNum(self, num):
        heapq.heappush(self.small, -num)
        # Ensure max of small ≤ min of large
        heapq.heappush(self.large, -heapq.heappop(self.small))
        # Balance sizes
        if len(self.large) > len(self.small):
            heapq.heappush(self.small, -heapq.heappop(self.large))

    def findMedian(self):
        if len(self.small) > len(self.large):
            return -self.small[0]
        return (-self.small[0] + self.large[0]) / 2.0

# 4. Top K Frequent Elements
def top_k_frequent(nums, k):
    count = {}
    for num in nums:
        count[num] = count.get(num, 0) + 1
    return heapq.nlargest(k, count.keys(), key=count.get)
```

---

## 7. Graphs

### Core Concept
```
A collection of nodes (vertices) connected by edges.

Undirected Graph:        Directed Graph (Digraph):
    A --- B              A ──→ B
    |   / |              ↑   ↗ |
    |  /  |              |  /  ↓
    C --- D              C ←── D

Weighted Graph:
    A ─(4)─ B
    |       |
   (2)    (3)
    |       |
    C ─(1)─ D
```

### Graph Representations
```python
# 1. Adjacency List (Most Common — space efficient for sparse graphs)
graph = {
    'A': ['B', 'C'],
    'B': ['A', 'C', 'D'],
    'C': ['A', 'B', 'D'],
    'D': ['B', 'C']
}

# Weighted Adjacency List
weighted_graph = {
    'A': [('B', 4), ('C', 2)],
    'B': [('A', 4), ('D', 3)],
    'C': [('A', 2), ('D', 1)],
    'D': [('B', 3), ('C', 1)]
}

# 2. Adjacency Matrix (Good for dense graphs)
#     A  B  C  D
# A [ 0, 1, 1, 0 ]
# B [ 1, 0, 1, 1 ]
# C [ 1, 1, 0, 1 ]
# D [ 0, 1, 1, 0 ]

# 3. Edge List
edges = [('A','B'), ('A','C'), ('B','C'), ('B','D'), ('C','D')]
```

### Graph Traversals
```python
# BFS — Breadth-First Search (Level by level, uses Queue)
# Use for: Shortest path (unweighted), level-order
from collections import deque

def bfs(graph, start):
    visited = set([start])
    queue = deque([start])
    order = []
    
    while queue:
        node = queue.popleft()
        order.append(node)
        for neighbor in graph[node]:
            if neighbor not in visited:
                visited.add(neighbor)
                queue.append(neighbor)
    return order

# DFS — Depth-First Search (Go deep first, uses Stack/Recursion)
# Use for: Detecting cycles, topological sort, connected components

def dfs_recursive(graph, node, visited=None):
    if visited is None:
        visited = set()
    visited.add(node)
    print(node, end=' ')
    for neighbor in graph[node]:
        if neighbor not in visited:
            dfs_recursive(graph, neighbor, visited)

def dfs_iterative(graph, start):
    visited = set()
    stack = [start]
    order = []
    
    while stack:
        node = stack.pop()
        if node not in visited:
            visited.add(node)
            order.append(node)
            for neighbor in graph[node]:
                if neighbor not in visited:
                    stack.append(neighbor)
    return order
```

### BFS vs DFS Comparison
```
╔═══════════════════╦═══════════════════╦════════════════════╗
║                   ║ BFS               ║ DFS                ║
╠═══════════════════╬═══════════════════╬════════════════════╣
║ Data Structure    ║ Queue             ║ Stack / Recursion  ║
║ Shortest Path     ║ ✅ (unweighted)   ║ ❌                 ║
║ Memory            ║ O(width)          ║ O(depth)           ║
║ Complete?         ║ Yes               ║ Not in infinite    ║
║ Use Cases         ║ Level order,      ║ Cycle detection,   ║
║                   ║ shortest path,    ║ topological sort,  ║
║                   ║ nearest neighbor  ║ path finding       ║
╚═══════════════════╩═══════════════════╩════════════════════╝
```

### Classic Graph Problems
```python
# 1. Shortest Path (Unweighted) — BFS
def shortest_path(graph, start, end):
    queue = deque([(start, [start])])
    visited = set([start])
    while queue:
        node, path = queue.popleft()
        if node == end:
            return path
        for neighbor in graph[node]:
            if neighbor not in visited:
                visited.add(neighbor)
                queue.append((neighbor, path + [neighbor]))
    return None

# 2. Detect Cycle in Undirected Graph — DFS
def has_cycle_undirected(graph):
    visited = set()
    def dfs(node, parent):
        visited.add(node)
        for neighbor in graph[node]:
            if neighbor not in visited:
                if dfs(neighbor, node):
                    return True
            elif neighbor != parent:
                return True    # Back edge = cycle
        return False
    
    for node in graph:
        if node not in visited:
            if dfs(node, None):
                return True
    return False

# 3. Detect Cycle in Directed Graph — DFS with coloring
def has_cycle_directed(graph):
    WHITE, GRAY, BLACK = 0, 1, 2
    color = {node: WHITE for node in graph}
    
    def dfs(node):
        color[node] = GRAY           # Currently exploring
        for neighbor in graph[node]:
            if color[neighbor] == GRAY:
                return True           # Back edge = cycle
            if color[neighbor] == WHITE:
                if dfs(neighbor):
                    return True
        color[node] = BLACK           # Done exploring
        return False
    
    return any(dfs(node) for node in graph if color[node] == WHITE)

# 4. Topological Sort (DAG only) — Kahn's Algorithm (BFS)
def topological_sort(graph, num_nodes):
    in_degree = {node: 0 for node in graph}
    for node in graph:
        for neighbor in graph[node]:
            in_degree[neighbor] += 1
    
    queue = deque([node for node in in_degree if in_degree[node] == 0])
    order = []
    
    while queue:
        node = queue.popleft()
        order.append(node)
        for neighbor in graph[node]:
            in_degree[neighbor] -= 1
            if in_degree[neighbor] == 0:
                queue.append(neighbor)
    
    return order if len(order) == num_nodes else []  # Empty = cycle

# 5. Number of Connected Components
def count_components(n, edges):
    graph = {i: [] for i in range(n)}
    for u, v in edges:
        graph[u].append(v)
        graph[v].append(u)
    
    visited = set()
    count = 0
    
    for node in range(n):
        if node not in visited:
            # BFS/DFS to mark all nodes in this component
            queue = deque([node])
            visited.add(node)
            while queue:
                curr = queue.popleft()
                for neighbor in graph[curr]:
                    if neighbor not in visited:
                        visited.add(neighbor)
                        queue.append(neighbor)
            count += 1
    return count

# 6. Number of Islands (Grid as Graph)
def num_islands(grid):
    if not grid:
        return 0
    rows, cols = len(grid), len(grid[0])
    count = 0
    
    def dfs(r, c):
        if r < 0 or r >= rows or c < 0 or c >= cols or grid[r][c] == '0':
            return
        grid[r][c] = '0'    # Mark visited
        dfs(r+1, c)
        dfs(r-1, c)
        dfs(r, c+1)
        dfs(r, c-1)
    
    for r in range(rows):
        for c in range(cols):
            if grid[r][c] == '1':
                dfs(r, c)
                count += 1
    return count

# 7. Dijkstra's Algorithm (Shortest Path — Weighted Graph)
def dijkstra(graph, start):
    import heapq
    distances = {node: float('inf') for node in graph}
    distances[start] = 0
    pq = [(0, start)]  # (distance, node)
    
    while pq:
        dist, node = heapq.heappop(pq)
        if dist > distances[node]:
            continue
        for neighbor, weight in graph[node]:
            new_dist = dist + weight
            if new_dist < distances[neighbor]:
                distances[neighbor] = new_dist
                heapq.heappush(pq, (new_dist, neighbor))
    return distances

# 8. Union-Find (Disjoint Set Union)
class UnionFind:
    def __init__(self, n):
        self.parent = list(range(n))
        self.rank = [0] * n
        self.components = n

    def find(self, x):
        if self.parent[x] != x:
            self.parent[x] = self.find(self.parent[x])  # Path compression
        return self.parent[x]

    def union(self, x, y):
        px, py = self.find(x), self.find(y)
        if px == py:
            return False
        # Union by rank
        if self.rank[px] < self.rank[py]:
            px, py = py, px
        self.parent[py] = px
        if self.rank[px] == self.rank[py]:
            self.rank[px] += 1
        self.components -= 1
        return True
```

---

## 8. Tries (Prefix Trees)

### Core Concept
```
Tree structure for storing strings, shared prefixes save space.

Insert: "cat", "car", "card", "dog"

            (root)
           /      \
          c        d
          |        |
          a        o
         / \       |
        t   r      g
            |
            d

Search "car":  root → c → a → r → ✓ (is_end = True)
Search "ca":   root → c → a → ✗ (is_end = False, it's a prefix)
Prefix "ca":   root → c → a → ✓ (exists as path)
```

### Implementation
```python
class TrieNode:
    def __init__(self):
        self.children = {}       # char → TrieNode
        self.is_end = False      # marks end of a word

class Trie:
    def __init__(self):
        self.root = TrieNode()

    def insert(self, word):               # O(m) where m = len(word)
        node = self.root
        for char in word:
            if char not in node.children:
                node.children[char] = TrieNode()
            node = node.children[char]
        node.is_end = True

    def search(self, word):               # O(m)
        node = self._find_node(word)
        return node is not None and node.is_end

    def starts_with(self, prefix):        # O(m)
        return self._find_node(prefix) is not None

    def _find_node(self, prefix):
        node = self.root
        for char in prefix:
            if char not in node.children:
                return None
            node = node.children[char]
        return node

    # Autocomplete: return all words with given prefix
    def autocomplete(self, prefix):
        node = self._find_node(prefix)
        if not node:
            return []
        results = []
        self._dfs(node, prefix, results)
        return results

    def _dfs(self, node, path, results):
        if node.is_end:
            results.append(path)
        for char, child in node.children.items():
            self._dfs(child, path + char, results)
```

### Use Cases
```
✓ Autocomplete / Search suggestions
✓ Spell checkers
✓ IP routing (longest prefix match)
✓ Word games (Boggle, Scrabble)
✓ Storing dictionaries efficiently
```

---

## PART 2: ALGORITHMS

---

## 9. Sorting Algorithms

### Visual Comparison
```
╔══════════════════╦══════════╦══════════╦══════════╦════════╦══════════╗
║ Algorithm        ║ Best     ║ Average  ║ Worst    ║ Space  ║ Stable?  ║
╠══════════════════╬══════════╬══════════╬══════════╬════════╬══════════╣
║ Bubble Sort      ║ O(n)     ║ O(n²)    ║ O(n²)    ║ O(1)   ║ Yes      ║
║ Selection Sort   ║ O(n²)    ║ O(n²)    ║ O(n²)    ║ O(1)   ║ No       ║
║ Insertion Sort   ║ O(n)     ║ O(n²)    ║ O(n²)    ║ O(1)   ║ Yes      ║
║ Merge Sort       ║ O(nlogn) ║ O(nlogn) ║ O(nlogn) ║ O(n)   ║ Yes      ║
║ Quick Sort       ║ O(nlogn) ║ O(nlogn) ║ O(n²)    ║ O(logn)║ No       ║
║ Heap Sort        ║ O(nlogn) ║ O(nlogn) ║ O(nlogn) ║ O(1)   ║ No       ║
║ Counting Sort    ║ O(n+k)   ║ O(n+k)   ║ O(n+k)   ║ O(k)   ║ Yes      ║
║ Radix Sort       ║ O(nk)    ║ O(nk)    ║ O(nk)    ║ O(n+k) ║ Yes      ║
╚══════════════════╩══════════╩══════════╩══════════╩════════╩══════════╝
Stable = Equal elements maintain their original order
```

### Implementations
```python
# ===== BUBBLE SORT =====
# Repeatedly swap adjacent elements if out of order
def bubble_sort(arr):
    n = len(arr)
    for i in range(n):
        swapped = False
        for j in range(n - 1 - i):
            if arr[j] > arr[j + 1]:
                arr[j], arr[j + 1] = arr[j + 1], arr[j]
                swapped = True
        if not swapped:        # Optimization: already sorted
            break
    return arr

# ===== SELECTION SORT =====
# Find minimum, place it at the beginning
def selection_sort(arr):
    n = len(arr)
    for i in range(n):
        min_idx = i
        for j in range(i + 1, n):
            if arr[j] < arr[min_idx]:
                min_idx = j
        arr[i], arr[min_idx] = arr[min_idx], arr[i]
    return arr

# ===== INSERTION SORT =====
# Build sorted array one element at a time
def insertion_sort(arr):
    for i in range(1, len(arr)):
        key = arr[i]
        j = i - 1
        while j >= 0 and arr[j] > key:
            arr[j + 1] = arr[j]       # Shift right
            j -= 1
        arr[j + 1] = key
    return arr

# ===== MERGE SORT ===== (Divide and Conquer)
# Split array in half, sort each half, merge
def merge_sort(arr):
    if len(arr) <= 1:
        return arr
    
    mid = len(arr) // 2
    left = merge_sort(arr[:mid])
    right = merge_sort(arr[mid:])
    return merge(left, right)

def merge(left, right):
    result = []
    i = j = 0
    while i < len(left) and j < len(right):
        if left[i] <= right[j]:
            result.append(left[i])
            i += 1
        else:
            result.append(right[j])
            j += 1
    result.extend(left[i:])
    result.extend(right[j:])
    return result

# Visualization:
# [38, 27, 43, 3, 9, 82, 10]
#        /                \
# [38, 27, 43]      [3, 9, 82, 10]
#    /      \          /        \
# [38]  [27, 43]    [3, 9]   [82, 10]
#         / \        / \       / \
#      [27] [43]   [3] [9]  [82] [10]
#         \ /        \ /       \ /
#      [27, 43]    [3, 9]   [10, 82]
#          \         /          |
#      [27, 38, 43]  [3, 9, 10, 82]
#              \         /
#     [3, 9, 10, 27, 38, 43, 82]


# ===== QUICK SORT ===== (Divide and Conquer)
# Pick pivot, partition around it
def quick_sort(arr, low=0, high=None):
    if high is None:
        high = len(arr) - 1
    if low < high:
        pivot_idx = partition(arr, low, high)
        quick_sort(arr, low, pivot_idx - 1)
        quick_sort(arr, pivot_idx + 1, high)
    return arr

def partition(arr, low, high):
    pivot = arr[high]              # Choose last element as pivot
    i = low - 1                    # Pointer for smaller elements
    for j in range(low, high):
        if arr[j] <= pivot:
            i += 1
            arr[i], arr[j] = arr[j], arr[i]
    arr[i + 1], arr[high] = arr[high], arr[i + 1]
    return i + 1

# Visualization:
# [10, 7, 8, 9, 1, 5]  pivot=5
# After partition: [1, 5, 8, 9, 10, 7]  pivot at index 1
# Recurse on [1] and [8, 9, 10, 7]


# ===== HEAP SORT =====
def heap_sort(arr):
    n = len(arr)
    
    # Build max heap
    for i in range(n // 2 - 1, -1, -1):
        heapify(arr, n, i)
    
    # Extract elements one by one
    for i in range(n - 1, 0, -1):
        arr[0], arr[i] = arr[i], arr[0]   # Move max to end
        heapify(arr, i, 0)                  # Restore heap
    return arr

def heapify(arr, n, i):
    largest = i
    left = 2 * i + 1
    right = 2 * i + 2
    if left < n and arr[left] > arr[largest]:
        largest = left
    if right < n and arr[right] > arr[largest]:
        largest = right
    if largest != i:
        arr[i], arr[largest] = arr[largest], arr[i]
        heapify(arr, n, largest)


# ===== COUNTING SORT ===== (Non-comparison based)
def counting_sort(arr):
    if not arr:
        return arr
    max_val = max(arr)
    count = [0] * (max_val + 1)
    
    for num in arr:
        count[num] += 1
    
    result = []
    for val, cnt in enumerate(count):
        result.extend([val] * cnt)
    return result
```

### When to Use What
```
Small array (n < 50):        Insertion Sort (low overhead)
Nearly sorted:               Insertion Sort (O(n) best case)
General purpose:             Merge Sort (guaranteed O(n log n))
In-place needed:             Quick Sort (O(log n) space)
External sorting (on disk):  Merge Sort (sequential access)
Integer keys, small range:   Counting Sort / Radix Sort
Priority queue operations:   Heap Sort
```

---

## 10. Searching Algorithms

### Linear Search — O(n)
```python
def linear_search(arr, target):
    for i, val in enumerate(arr):
        if val == target:
            return i
    return -1
```

### Binary Search — O(log n)
```
Requirement: Array MUST be sorted

Search for 23 in [2, 5, 8, 12, 16, 23, 38, 56, 72, 91]

Step 1: mid = 16 → 23 > 16 → search right half
Step 2: mid = 56 → 23 < 56 → search left half
Step 3: mid = 23 → Found!

Each step eliminates HALF the elements
```

```python
# Classic Binary Search
def binary_search(arr, target):
    left, right = 0, len(arr) - 1
    while left <= right:
        mid = left + (right - left) // 2    # Avoid overflow
        if arr[mid] == target:
            return mid
        elif arr[mid] < target:
            left = mid + 1
        else:
            right = mid - 1
    return -1

# Recursive version
def binary_search_recursive(arr, target, left, right):
    if left > right:
        return -1
    mid = left + (right - left) // 2
    if arr[mid] == target:
        return mid
    elif arr[mid] < target:
        return binary_search_recursive(arr, target, mid + 1, right)
    else:
        return binary_search_recursive(arr, target, left, mid - 1)
```

### Binary Search Variations (VERY Important for Interviews)
```python
# 1. Find First Occurrence (Lower Bound)
def find_first(arr, target):
    left, right = 0, len(arr) - 1
    result = -1
    while left <= right:
        mid = left + (right - left) // 2
        if arr[mid] == target:
            result = mid
            right = mid - 1       # Keep searching left
        elif arr[mid] < target:
            left = mid + 1
        else:
            right = mid - 1
    return result

# 2. Find Last Occurrence (Upper Bound)
def find_last(arr, target):
    left, right = 0, len(arr) - 1
    result = -1
    while left <= right:
        mid = left + (right - left) // 2
        if arr[mid] == target:
            result = mid
            left = mid + 1        # Keep searching right
        elif arr[mid] < target:
            left = mid + 1
        else:
            right = mid - 1
    return result

# 3. Search in Rotated Sorted Array
def search_rotated(nums, target):
    left, right = 0, len(nums) - 1
    while left <= right:
        mid = left + (right - left) // 2
        if nums[mid] == target:
            return mid
        # Left half is sorted
        if nums[left] <= nums[mid]:
            if nums[left] <= target < nums[mid]:
                right = mid - 1
            else:
                left = mid + 1
        # Right half is sorted
        else:
            if nums[mid] < target <= nums[right]:
                left = mid + 1
            else:
                right = mid - 1
    return -1

# 4. Find Peak Element
def find_peak(nums):
    left, right = 0, len(nums) - 1
    while left < right:
        mid = left + (right - left) // 2
        if nums[mid] < nums[mid + 1]:
            left = mid + 1        # Peak is to the right
        else:
            right = mid           # Peak is at mid or left
    return left

# 5. Search on Answer (Binary Search on Result Space)
# Example: Minimum days to make bouquets
def min_days_bouquets(bloomDay, m, k):
    """m bouquets, k adjacent flowers each"""
    if m * k > len(bloomDay):
        return -1
    
    def can_make(days):
        bouquets = flowers = 0
        for bloom in bloomDay:
            if bloom <= days:
                flowers += 1
                if flowers == k:
                    bouquets += 1
                    flowers = 0
            else:
                flowers = 0
        return bouquets >= m
    
    left, right = min(bloomDay), max(bloomDay)
    while left < right:
        mid = left + (right - left) // 2
        if can_make(mid):
            right = mid
        else:
            left = mid + 1
    return left

# 6. Find Square Root (Integer)
def sqrt(x):
    left, right = 0, x
    while left <= right:
        mid = left + (right - left) // 2
        if mid * mid == x:
            return mid
        elif mid * mid < x:
            left = mid + 1
        else:
            right = mid - 1
    return right    # Floor of sqrt
```

---

## 11. Recursion & Backtracking

### Recursion — Core Concept
```
A function that calls itself with a smaller subproblem.

Three parts:
1. Base case    → When to stop
2. Recursive case → Break problem into smaller subproblem
3. Progress     → Each call moves toward base case

Factorial example:
factorial(4)
  = 4 * factorial(3)
  = 4 * 3 * factorial(2)
  = 4 * 3 * 2 * factorial(1)
  = 4 * 3 * 2 * 1     ← base case
  = 24

Call Stack:
┌─────────────────┐
│ factorial(1) = 1│  ← returns first
├─────────────────┤
│ factorial(2)    │
├─────────────────┤
│ factorial(3)    │
├─────────────────┤
│ factorial(4)    │  ← called first
└─────────────────┘
```

```python
# Classic recursive problems
def factorial(n):
    if n <= 1:          # Base case
        return 1
    return n * factorial(n - 1)   # Recursive case

def fibonacci(n):
    if n <= 1:
        return n
    return fibonacci(n-1) + fibonacci(n-2)  # O(2^n) - exponential!

def power(base, exp):
    if exp == 0:
        return 1
    if exp % 2 == 0:
        half = power(base, exp // 2)
        return half * half           # O(log n) - fast exponentiation
    return base * power(base, exp - 1)
```

### Backtracking
```
Systematic way to try all possibilities.
Build a solution step by step, abandon ("backtrack") when constraints fail.

Template:
1. Choose    → Pick a candidate
2. Explore   → Recurse with candidate added
3. Unchoose  → Remove candidate (backtrack)
```

```python
# 1. Generate All Subsets
def subsets(nums):
    result = []
    def backtrack(start, current):
        result.append(current[:])         # Add copy of current subset
        for i in range(start, len(nums)):
            current.append(nums[i])       # Choose
            backtrack(i + 1, current)     # Explore
            current.pop()                 # Unchoose (backtrack)
    backtrack(0, [])
    return result
    # subsets([1,2,3]) → [[], [1], [1,2], [1,2,3], [1,3], [2], [2,3], [3]]

# 2. Generate All Permutations
def permutations(nums):
    result = []
    def backtrack(current, remaining):
        if not remaining:
            result.append(current[:])
            return
        for i in range(len(remaining)):
            current.append(remaining[i])
            backtrack(current, remaining[:i] + remaining[i+1:])
            current.pop()
    backtrack([], nums)
    return result

# 3. Combination Sum
def combination_sum(candidates, target):
    result = []
    def backtrack(start, current, remaining):
        if remaining == 0:
            result.append(current[:])
            return
        if remaining < 0:
            return
        for i in range(start, len(candidates)):
            current.append(candidates[i])
            backtrack(i, current, remaining - candidates[i])  # same i: reuse allowed
            current.pop()
    backtrack(0, [], target)
    return result

# 4. N-Queens
def solve_n_queens(n):
    result = []
    board = [['.' ] * n for _ in range(n)]
    
    def is_safe(row, col):
        # Check column
        for i in range(row):
            if board[i][col] == 'Q':
                return False
        # Check upper-left diagonal
        i, j = row - 1, col - 1
        while i >= 0 and j >= 0:
            if board[i][j] == 'Q':
                return False
            i -= 1; j -= 1
        # Check upper-right diagonal
        i, j = row - 1, col + 1
        while i >= 0 and j < n:
            if board[i][j] == 'Q':
                return False
            i -= 1; j += 1
        return True
    
    def backtrack(row):
        if row == n:
            result.append([''.join(r) for r in board])
            return
        for col in range(n):
            if is_safe(row, col):
                board[row][col] = 'Q'
                backtrack(row + 1)
                board[row][col] = '.'
    
    backtrack(0)
    return result

# 5. Word Search in Grid
def word_search(board, word):
    rows, cols = len(board), len(board[0])
    
    def backtrack(r, c, idx):
        if idx == len(word):
            return True
        if (r < 0 or r >= rows or c < 0 or c >= cols or
            board[r][c] != word[idx]):
            return False
        
        temp = board[r][c]
        board[r][c] = '#'           # Mark visited
        
        found = (backtrack(r+1, c, idx+1) or
                 backtrack(r-1, c, idx+1) or
                 backtrack(r, c+1, idx+1) or
                 backtrack(r, c-1, idx+1))
        
        board[r][c] = temp          # Restore (backtrack)
        return found
    
    for r in range(rows):
        for c in range(cols):
            if backtrack(r, c, 0):
                return True
    return False
```

---

## 12. Dynamic Programming (DP)

### Core Concept
```
Optimization technique for problems with:
1. Overlapping subproblems  → Same subproblem solved multiple times
2. Optimal substructure     → Optimal solution built from optimal sub-solutions

Two approaches:
┌─────────────────────────────────────────────────┐
│ Top-Down (Memoization)                          │
│ Start from main problem, cache results          │
│ Recursive + HashMap/Array                       │
├─────────────────────────────────────────────────┤
│ Bottom-Up (Tabulation)                          │
│ Start from smallest subproblem, build up        │
│ Iterative + Table                               │
└─────────────────────────────────────────────────┘
```

### Fibonacci — The Gateway to DP
```python
# Brute Force: O(2^n) — TERRIBLE
def fib_brute(n):
    if n <= 1:
        return n
    return fib_brute(n-1) + fib_brute(n-2)

# Call tree for fib(5) — massive redundancy:
#                fib(5)
#              /        \
#          fib(4)      fib(3)
#         /    \       /    \
#      fib(3) fib(2) fib(2) fib(1)
#      /  \   ...     ...
#  fib(2) fib(1)
#  fib(2) is computed 3 times!

# Top-Down (Memoization): O(n)
def fib_memo(n, memo={}):
    if n <= 1:
        return n
    if n in memo:
        return memo[n]
    memo[n] = fib_memo(n-1, memo) + fib_memo(n-2, memo)
    return memo[n]

# Bottom-Up (Tabulation): O(n)
def fib_tab(n):
    if n <= 1:
        return n
    dp = [0] * (n + 1)
    dp[1] = 1
    for i in range(2, n + 1):
        dp[i] = dp[i-1] + dp[i-2]
    return dp[n]

# Space-Optimized: O(1) space
def fib_optimal(n):
    if n <= 1:
        return n
    a, b = 0, 1
    for _ in range(2, n + 1):
        a, b = b, a + b
    return b
```

### DP Framework — How to Approach Any DP Problem
```
Step 1: IDENTIFY → Does this problem have overlapping subproblems?
Step 2: DEFINE   → What does dp[i] represent?
Step 3: RELATE   → Write the recurrence relation
Step 4: BASE     → What are the base cases?
Step 5: ORDER    → What order to fill the table?
Step 6: OPTIMIZE → Can we reduce space?
```

### Classic DP Problems
```python
# ===== 1D DP =====

# 1. Climbing Stairs
# How many ways to reach step n (1 or 2 steps at a time)?
def climb_stairs(n):
    # dp[i] = number of ways to reach step i
    # dp[i] = dp[i-1] + dp[i-2]
    if n <= 2:
        return n
    a, b = 1, 2
    for _ in range(3, n + 1):
        a, b = b, a + b
    return b

# 2. House Robber
# Max money from non-adjacent houses
def rob(nums):
    # dp[i] = max money robbing houses 0..i
    # dp[i] = max(dp[i-1], dp[i-2] + nums[i])
    if not nums:
        return 0
    if len(nums) == 1:
        return nums[0]
    prev2, prev1 = 0, 0
    for num in nums:
        prev2, prev1 = prev1, max(prev1, prev2 + num)
    return prev1

# 3. Longest Increasing Subsequence (LIS)
def lis(nums):
    # dp[i] = length of LIS ending at index i
    n = len(nums)
    dp = [1] * n
    for i in range(1, n):
        for j in range(i):
            if nums[j] < nums[i]:
                dp[i] = max(dp[i], dp[j] + 1)
    return max(dp)    # O(n²)

# Optimized LIS with Binary Search: O(n log n)
import bisect
def lis_optimized(nums):
    tails = []
    for num in nums:
        pos = bisect.bisect_left(tails, num)
        if pos == len(tails):
            tails.append(num)
        else:
            tails[pos] = num
    return len(tails)

# 4. Coin Change
# Minimum coins to make amount
def coin_change(coins, amount):
    # dp[i] = min coins needed for amount i
    dp = [float('inf')] * (amount + 1)
    dp[0] = 0
    for i in range(1, amount + 1):
        for coin in coins:
            if coin <= i:
                dp[i] = min(dp[i], dp[i - coin] + 1)
    return dp[amount] if dp[amount] != float('inf') else -1

# 5. Word Break
def word_break(s, wordDict):
    # dp[i] = can s[0:i] be segmented?
    word_set = set(wordDict)
    dp = [False] * (len(s) + 1)
    dp[0] = True
    for i in range(1, len(s) + 1):
        for j in range(i):
            if dp[j] and s[j:i] in word_set:
                dp[i] = True
                break
    return dp[len(s)]


# ===== 2D DP =====

# 6. Longest Common Subsequence (LCS)
def lcs(text1, text2):
    m, n = len(text1), len(text2)
    dp = [[0] * (n + 1) for _ in range(m + 1)]
    
    for i in range(1, m + 1):
        for j in range(1, n + 1):
            if text1[i-1] == text2[j-1]:
                dp[i][j] = dp[i-1][j-1] + 1
            else:
                dp[i][j] = max(dp[i-1][j], dp[i][j-1])
    return dp[m][n]

    #     ""  a  c  e
    # ""   0  0  0  0
    # a    0  1  1  1
    # b    0  1  1  1
    # c    0  1  2  2
    # d    0  1  2  2
    # e    0  1  2  3    → LCS("abcde", "ace") = 3

# 7. Edit Distance (Levenshtein Distance)
def edit_distance(word1, word2):
    m, n = len(word1), len(word2)
    dp = [[0] * (n + 1) for _ in range(m + 1)]
    
    for i in range(m + 1):
        dp[i][0] = i           # Delete all chars
    for j in range(n + 1):
        dp[0][j] = j           # Insert all chars
    
    for i in range(1, m + 1):
        for j in range(1, n + 1):
            if word1[i-1] == word2[j-1]:
                dp[i][j] = dp[i-1][j-1]                    # No operation
            else:
                dp[i][j] = 1 + min(
                    dp[i-1][j],      # Delete
                    dp[i][j-1],      # Insert
                    dp[i-1][j-1]     # Replace
                )
    return dp[m][n]

# 8. 0/1 Knapsack
def knapsack(weights, values, capacity):
    n = len(weights)
    dp = [[0] * (capacity + 1) for _ in range(n + 1)]
    
    for i in range(1, n + 1):
        for w in range(capacity + 1):
            dp[i][w] = dp[i-1][w]                  # Don't take item i
            if weights[i-1] <= w:
                dp[i][w] = max(dp[i][w],
                    dp[i-1][w - weights[i-1]] + values[i-1])  # Take item i
    return dp[n][capacity]

# 9. Unique Paths in Grid
def unique_paths(m, n):
    dp = [[1] * n for _ in range(m)]
    for i in range(1, m):
        for j in range(1, n):
            dp[i][j] = dp[i-1][j] + dp[i][j-1]
    return dp[m-1][n-1]

# 10. Maximum Product Subarray
def max_product(nums):
    max_so_far = min_so_far = result = nums[0]
    for i in range(1, len(nums)):
        candidates = (nums[i], max_so_far * nums[i], min_so_far * nums[i])
        max_so_far = max(candidates)
        min_so_far = min(candidates)
        result = max(result, max_so_far)
    return result
```

### DP Patterns Summary
```
╔═══════════════════════╦═══════════════════════════════════════╗
║ Pattern               ║ Examples                              ║
╠═══════════════════════╬═══════════════════════════════════════╣
║ Linear DP             ║ Fibonacci, Climbing Stairs, Rob       ║
║ Grid DP               ║ Unique Paths, Min Path Sum            ║
║ String DP             ║ LCS, Edit Distance, Palindrome        ║
║ Knapsack              ║ 0/1 Knapsack, Coin Change, Subset Sum║
║ Interval DP           ║ Burst Balloons, Matrix Chain          ║
║ State Machine DP      ║ Stock Buy/Sell with cooldown          ║
║ Bitmask DP            ║ TSP, Assignment Problem               ║
║ Tree DP               ║ Diameter, House Robber III            ║
╚═══════════════════════╩═══════════════════════════════════════╝
```

---

## 13. Greedy Algorithms

### Core Concept
```
Make the locally optimal choice at each step,
hoping it leads to the globally optimal solution.

Greedy works when:
1. Greedy choice property → local optimal leads to global optimal
2. Optimal substructure   → optimal solution contains optimal sub-solutions

NOT always correct — must prove correctness!
```

```python
# 1. Activity Selection / Interval Scheduling
# Maximum non-overlapping intervals
def activity_selection(intervals):
    intervals.sort(key=lambda x: x[1])   # Sort by end time
    result = [intervals[0]]
    for i in range(1, len(intervals)):
        if intervals[i][0] >= result[-1][1]:   # No overlap
            result.append(intervals[i])
    return result

# 2. Fractional Knapsack
def fractional_knapsack(items, capacity):
    # items = [(weight, value), ...]
    # Sort by value/weight ratio (descending)
    items.sort(key=lambda x: x[1]/x[0], reverse=True)
    total_value = 0
    for weight, value in items:
        if capacity >= weight:
            total_value += value
            capacity -= weight
        else:
            total_value += (capacity / weight) * value   # Take fraction
            break
    return total_value

# 3. Jump Game — Can you reach the last index?
def can_jump(nums):
    max_reach = 0
    for i in range(len(nums)):
        if i > max_reach:
            return False
        max_reach = max(max_reach, i + nums[i])
    return True

# 4. Minimum Number of Platforms (Merge Intervals variant)
def min_platforms(arrivals, departures):
    arrivals.sort()
    departures.sort()
    platforms = max_platforms = 0
    i = j = 0
    while i < len(arrivals):
        if arrivals[i] <= departures[j]:
            platforms += 1
            max_platforms = max(max_platforms, platforms)
            i += 1
        else:
            platforms -= 1
            j += 1
    return max_platforms

# 5. Huffman Coding (Optimal prefix codes)
import heapq
def huffman_coding(freq):
    heap = [(f, char) for char, f in freq.items()]
    heapq.heapify(heap)
    while len(heap) > 1:
        f1, c1 = heapq.heappop(heap)
        f2, c2 = heapq.heappop(heap)
        heapq.heappush(heap, (f1 + f2, c1 + c2))
    return heap[0]

# 6. Task Scheduler
def least_interval(tasks, n):
    from collections import Counter
    freq = Counter(tasks)
    max_freq = max(freq.values())
    max_count = sum(1 for v in freq.values() if v == max_freq)
    return max(len(tasks), (max_freq - 1) * (n + 1) + max_count)
```

### Greedy vs DP
```
╔═══════════════╦══════════════════════╦═══════════════════════╗
║               ║ Greedy               ║ Dynamic Programming   ║
╠═══════════════╬══════════════════════╬═══════════════════════╣
║ Approach      ║ Local best choice    ║ Try all subproblems   ║
║ Guarantee     ║ Not always optimal   ║ Always optimal        ║
║ Speed         ║ Usually faster       ║ Usually slower        ║
║ Complexity    ║ O(n log n) typical   ║ O(n²) or more typical║
║ Proves needed ║ Yes (correctness)    ║ Just needs structure  ║
║ Example       ║ Fractional Knapsack  ║ 0/1 Knapsack         ║
╚═══════════════╩══════════════════════╩═══════════════════════╝
```

---

## 14. Bit Manipulation

### Core Concepts
```
AND  (&):  1 & 1 = 1, rest = 0     (both bits set)
OR   (|):  0 | 0 = 0, rest = 1     (either bit set)
XOR  (^):  same = 0, different = 1  (bits differ)
NOT  (~):  flip all bits
LEFT SHIFT  (<<): multiply by 2
RIGHT SHIFT (>>): divide by 2

Key properties of XOR:
  a ^ 0 = a
  a ^ a = 0
  a ^ b ^ a = b  (cancels out)
```

```python
# 1. Check if even/odd
def is_odd(n):
    return n & 1    # Last bit = 1 means odd

# 2. Check if power of 2
def is_power_of_2(n):
    return n > 0 and (n & (n - 1)) == 0
    # 8 = 1000, 7 = 0111 → 1000 & 0111 = 0000

# 3. Count set bits (Hamming Weight)
def count_bits(n):
    count = 0
    while n:
        count += 1
        n &= (n - 1)    # Remove lowest set bit
    return count

# 4. Single Number (all appear twice except one)
def single_number(nums):
    result = 0
    for num in nums:
        result ^= num    # Pairs cancel out
    return result

# 5. Swap without temp variable
def swap(a, b):
    a ^= b
    b ^= a
    a ^= b
    return a, b

# 6. Get/Set/Clear/Toggle bit
def get_bit(num, i):
    return (num >> i) & 1

def set_bit(num, i):
    return num | (1 << i)

def clear_bit(num, i):
    return num & ~(1 << i)

def toggle_bit(num, i):
    return num ^ (1 << i)

# 7. Missing Number (0 to n, one missing)
def missing_number(nums):
    n = len(nums)
    result = n
    for i in range(n):
        result ^= i ^ nums[i]
    return result
```

---

## 15. String Algorithms

```python
# 1. Palindrome Check
def is_palindrome(s):
    s = ''.join(c.lower() for c in s if c.isalnum())
    return s == s[::-1]

# 2. Longest Palindromic Substring (Expand from center)
def longest_palindrome(s):
    def expand(left, right):
        while left >= 0 and right < len(s) and s[left] == s[right]:
            left -= 1
            right += 1
        return s[left+1:right]
    
    result = ""
    for i in range(len(s)):
        # Odd length palindrome
        odd = expand(i, i)
        # Even length palindrome
        even = expand(i, i + 1)
        result = max(result, odd, even, key=len)
    return result

# 3. KMP Pattern Matching — O(n + m)
def kmp_search(text, pattern):
    # Build failure function
    def build_lps(pattern):
        lps = [0] * len(pattern)
        length = 0
        i = 1
        while i < len(pattern):
            if pattern[i] == pattern[length]:
                length += 1
                lps[i] = length
                i += 1
            elif length:
                length = lps[length - 1]
            else:
                lps[i] = 0
                i += 1
        return lps
    
    lps = build_lps(pattern)
    i = j = 0
    results = []
    while i < len(text):
        if text[i] == pattern[j]:
            i += 1
            j += 1
        if j == len(pattern):
            results.append(i - j)
            j = lps[j - 1]
        elif i < len(text) and text[i] != pattern[j]:
            if j:
                j = lps[j - 1]
            else:
                i += 1
    return results

# 4. Rabin-Karp (Rolling Hash)
def rabin_karp(text, pattern):
    n, m = len(text), len(pattern)
    base, mod = 256, 101
    pattern_hash = 0
    text_hash = 0
    h = pow(base, m - 1, mod)
    
    for i in range(m):
        pattern_hash = (base * pattern_hash + ord(pattern[i])) % mod
        text_hash = (base * text_hash + ord(text[i])) % mod
    
    results = []
    for i in range(n - m + 1):
        if pattern_hash == text_hash:
            if text[i:i+m] == pattern:
                results.append(i)
        if i < n - m:
            text_hash = (base * (text_hash - ord(text[i]) * h) + ord(text[i + m])) % mod
            text_hash = (text_hash + mod) % mod
    return results

# 5. Longest Substring Without Repeating Characters
def length_of_longest_substring(s):
    seen = {}
    left = max_len = 0
    for right, char in enumerate(s):
        if char in seen and seen[char] >= left:
            left = seen[char] + 1
        seen[char] = right
        max_len = max(max_len, right - left + 1)
    return max_len
```

---

## 16. Advanced Data Structures

### Segment Tree — Range Queries
```python
class SegmentTree:
    """Range sum queries with point updates"""
    def __init__(self, arr):
        self.n = len(arr)
        self.tree = [0] * (4 * self.n)
        self._build(arr, 0, 0, self.n - 1)

    def _build(self, arr, node, start, end):
        if start == end:
            self.tree[node] = arr[start]
        else:
            mid = (start + end) // 2
            self._build(arr, 2*node+1, start, mid)
            self._build(arr, 2*node+2, mid+1, end)
            self.tree[node] = self.tree[2*node+1] + self.tree[2*node+2]

    def update(self, idx, val, node=0, start=0, end=None):
        if end is None: end = self.n - 1
        if start == end:
            self.tree[node] = val
        else:
            mid = (start + end) // 2
            if idx <= mid:
                self.update(idx, val, 2*node+1, start, mid)
            else:
                self.update(idx, val, 2*node+2, mid+1, end)
            self.tree[node] = self.tree[2*node+1] + self.tree[2*node+2]

    def query(self, l, r, node=0, start=0, end=None):
        if end is None: end = self.n - 1
        if r < start or end < l:
            return 0
        if l <= start and end <= r:
            return self.tree[node]
        mid = (start + end) // 2
        return (self.query(l, r, 2*node+1, start, mid) +
                self.query(l, r, 2*node+2, mid+1, end))
```

### Fenwick Tree (Binary Indexed Tree) — Prefix Sums
```python
class FenwickTree:
    def __init__(self, n):
        self.n = n
        self.tree = [0] * (n + 1)

    def update(self, i, delta):
        i += 1  # 1-indexed
        while i <= self.n:
            self.tree[i] += delta
            i += i & (-i)       # Add lowest set bit

    def prefix_sum(self, i):
        i += 1
        total = 0
        while i > 0:
            total += self.tree[i]
            i -= i & (-i)       # Remove lowest set bit
        return total

    def range_sum(self, l, r):
        return self.prefix_sum(r) - (self.prefix_sum(l - 1) if l > 0 else 0)
```

### LRU Cache (Hash Map + Doubly Linked List)
```python
from collections import OrderedDict

class LRUCache:
    def __init__(self, capacity):
        self.cache = OrderedDict()
        self.capacity = capacity

    def get(self, key):
        if key not in self.cache:
            return -1
        self.cache.move_to_end(key)
        return self.cache[key]

    def put(self, key, value):
        if key in self.cache:
            self.cache.move_to_end(key)
        self.cache[key] = value
        if len(self.cache) > self.capacity:
            self.cache.popitem(last=False)    # Remove oldest
```

---

## 17. Complexity Analysis (Big O)

### Time Complexity Ranking
```
FAST ←────────────────────────────────────→ SLOW

O(1) < O(log n) < O(n) < O(n log n) < O(n²) < O(2ⁿ) < O(n!)

Name          │ Example              │ n=1000
──────────────┼──────────────────────┼──────────
O(1)          │ Array access         │ 1
O(log n)      │ Binary search        │ ~10
O(n)          │ Linear scan          │ 1,000
O(n log n)    │ Merge sort           │ ~10,000
O(n²)         │ Nested loops         │ 1,000,000
O(2ⁿ)         │ All subsets          │ ∞ (way too much)
O(n!)         │ All permutations     │ ∞ (way too much)
```

### How to Calculate
```python
# O(1) - Constant
x = arr[5]

# O(log n) - Logarithmic (halving each time)
while n > 0:
    n //= 2

# O(n) - Linear
for i in range(n):
    print(i)

# O(n log n) - Linearithmic
arr.sort()    # Most efficient comparison sorts

# O(n²) - Quadratic
for i in range(n):
    for j in range(n):
        print(i, j)

# O(2ⁿ) - Exponential
def fib(n):
    if n <= 1: return n
    return fib(n-1) + fib(n-2)

# Amortized O(1)
# Dynamic array append: mostly O(1), occasionally O(n) for resize
# Average across all operations = O(1)
```

### Space Complexity
```
Variables:        O(1)
Array of size n:  O(n)
2D matrix n×m:    O(n*m)
Recursive depth:  O(depth) on call stack
Hash map:         O(n) for n entries
```

---

## QUICK REFERENCE CHEAT SHEET

```
╔══════════════════════╦════════════╦═══════════╦═════════════════════╗
║ Data Structure       ║ Access     ║ Search    ║ Insert/Delete       ║
╠══════════════════════╬════════════╬═══════════╬═════════════════════╣
║ Array                ║ O(1)       ║ O(n)      ║ O(n)                ║
║ Linked List          ║ O(n)       ║ O(n)      ║ O(1) head           ║
║ Stack / Queue        ║ O(n)       ║ O(n)      ║ O(1)                ║
║ Hash Table           ║ N/A        ║ O(1) avg  ║ O(1) avg            ║
║ BST (balanced)       ║ O(log n)   ║ O(log n)  ║ O(log n)            ║
║ Heap                 ║ O(1) top   ║ O(n)      ║ O(log n)            ║
║ Trie                 ║ O(m)       ║ O(m)      ║ O(m)  m=key length  ║
╚══════════════════════╩════════════╩═══════════╩═════════════════════╝

╔══════════════════════╦═════════════════════════════════════════════╗
║ Problem Pattern      ║ Go-To Approach                             ║
╠══════════════════════╬═════════════════════════════════════════════╣
║ "Find pair/sum"      ║ Hash Map or Two Pointers                   ║
║ "Sorted array"       ║ Binary Search                              ║
║ "Top/Bottom K"       ║ Heap                                       ║
║ "BFS/Shortest path"  ║ Queue + BFS                                ║
║ "All combos/perms"   ║ Backtracking                               ║
║ "Optimal/Count ways" ║ Dynamic Programming                        ║
║ "Connected/Groups"   ║ Union Find or DFS                          ║
║ "Prefix lookup"      ║ Trie                                       ║
║ "Interval merging"   ║ Sort + Greedy                              ║
║ "Sliding window"     ║ Two Pointers / Deque                       ║
║ "Stream / Online"    ║ Heap / Balanced BST                        ║
║ "Parentheses/Nested" ║ Stack                                      ║
╚══════════════════════╩═════════════════════════════════════════════╝
```

---

> **Study order for interviews:**
> Arrays → Hash Maps → Two Pointers → Sliding Window →
> Stacks/Queues → Linked Lists → Trees → Binary Search →
> Graphs (BFS/DFS) → Heaps → Recursion/Backtracking →
> Dynamic Programming → Greedy → Tries → Bit Manipulation