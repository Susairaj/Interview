# Complete DSA Questions Guide (Python)

I'll provide comprehensive solutions for all questions across the four categories. Due to the length, I'll organize them clearly with explanations.

## 1. ARRAYS (30 Questions)

### 1. Two Sum
**Problem:** Find two numbers that add up to a target.

```python
def two_sum(nums, target):
    """
    Time: O(n), Space: O(n)
    Use hashmap to store complement
    """
    seen = {}
    for i, num in enumerate(nums):
        complement = target - num
        if complement in seen:
            return [seen[complement], i]
        seen[num] = i
    return []

# Example
print(two_sum([2, 7, 11, 15], 9))  # [0, 1]
```

**Explanation:**
1. Create a hashmap to store numbers we've seen
2. For each number, calculate its complement (target - num)
3. If complement exists in hashmap, return indices
4. Otherwise, store current number with its index

---

### 2. Best Time to Buy and Sell Stock
**Problem:** Maximize profit from one buy and one sell.

```python
def max_profit(prices):
    """
    Time: O(n), Space: O(1)
    Track minimum price and maximum profit
    """
    min_price = float('inf')
    max_profit = 0
    
    for price in prices:
        min_price = min(min_price, price)
        profit = price - min_price
        max_profit = max(max_profit, profit)
    
    return max_profit

# Example
print(max_profit([7, 1, 5, 3, 6, 4]))  # 5
```

**Explanation:**
1. Track the minimum price seen so far
2. Calculate profit if we sell at current price
3. Update maximum profit if current is better

---

### 3. Contains Duplicate
**Problem:** Check if array has duplicates.

```python
def contains_duplicate(nums):
    """
    Time: O(n), Space: O(n)
    Use set to track seen numbers
    """
    return len(nums) != len(set(nums))

# Alternative approach
def contains_duplicate_v2(nums):
    seen = set()
    for num in nums:
        if num in seen:
            return True
        seen.add(num)
    return False

# Example
print(contains_duplicate([1, 2, 3, 1]))  # True
```

**Explanation:**
1. Convert list to set (removes duplicates)
2. If lengths differ, duplicates exist
3. Alternative: iterate and check each element

---

### 4. Product of Array Except Self
**Problem:** Return array where each element is product of all others.

```python
def product_except_self(nums):
    """
    Time: O(n), Space: O(1) - output array doesn't count
    Use left and right products
    """
    n = len(nums)
    result = [1] * n
    
    # Left products
    left = 1
    for i in range(n):
        result[i] = left
        left *= nums[i]
    
    # Right products
    right = 1
    for i in range(n - 1, -1, -1):
        result[i] *= right
        right *= nums[i]
    
    return result

# Example
print(product_except_self([1, 2, 3, 4]))  # [24, 12, 8, 6]
```

**Explanation:**
1. First pass: accumulate products from left
2. Second pass: accumulate products from right
3. Multiply left and right products for each position

---

### 5. Maximum Subarray (Kadane's Algorithm)
**Problem:** Find contiguous subarray with largest sum.

```python
def max_subarray(nums):
    """
    Time: O(n), Space: O(1)
    Kadane's algorithm
    """
    max_sum = nums[0]
    current_sum = nums[0]
    
    for i in range(1, len(nums)):
        current_sum = max(nums[i], current_sum + nums[i])
        max_sum = max(max_sum, current_sum)
    
    return max_sum

# Example
print(max_subarray([-2, 1, -3, 4, -1, 2, 1, -5, 4]))  # 6
```

**Explanation:**
1. Track current sum ending at position i
2. Either extend previous subarray or start new one
3. Update global maximum

---

### 6. Maximum Product Subarray
**Problem:** Find contiguous subarray with largest product.

```python
def max_product(nums):
    """
    Time: O(n), Space: O(1)
    Track both max and min (for negative numbers)
    """
    if not nums:
        return 0
    
    max_prod = min_prod = result = nums[0]
    
    for i in range(1, len(nums)):
        num = nums[i]
        # Swap if current number is negative
        if num < 0:
            max_prod, min_prod = min_prod, max_prod
        
        max_prod = max(num, max_prod * num)
        min_prod = min(num, min_prod * num)
        result = max(result, max_prod)
    
    return result

# Example
print(max_product([2, 3, -2, 4]))  # 6
```

**Explanation:**
1. Track both maximum and minimum products
2. Negative numbers can make min become max
3. Swap max/min when encountering negative

---

### 7. Find Minimum in Rotated Sorted Array
**Problem:** Find minimum in rotated sorted array.

```python
def find_min(nums):
    """
    Time: O(log n), Space: O(1)
    Binary search approach
    """
    left, right = 0, len(nums) - 1
    
    while left < right:
        mid = (left + right) // 2
        
        if nums[mid] > nums[right]:
            left = mid + 1
        else:
            right = mid
    
    return nums[left]

# Example
print(find_min([3, 4, 5, 1, 2]))  # 1
```

**Explanation:**
1. Use binary search
2. If mid > right, minimum is in right half
3. Otherwise, minimum is in left half (including mid)

---

### 8. Search in Rotated Sorted Array
**Problem:** Search target in rotated sorted array.

```python
def search(nums, target):
    """
    Time: O(log n), Space: O(1)
    Modified binary search
    """
    left, right = 0, len(nums) - 1
    
    while left <= right:
        mid = (left + right) // 2
        
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

# Example
print(search([4, 5, 6, 7, 0, 1, 2], 0))  # 4
```

**Explanation:**
1. Find which half is sorted
2. Check if target is in sorted half
3. Adjust search boundaries accordingly

---

### 9. 3Sum
**Problem:** Find all triplets that sum to zero.

```python
def three_sum(nums):
    """
    Time: O(n²), Space: O(1) - excluding output
    Sort then two-pointer approach
    """
    nums.sort()
    result = []
    
    for i in range(len(nums) - 2):
        # Skip duplicates
        if i > 0 and nums[i] == nums[i - 1]:
            continue
        
        left, right = i + 1, len(nums) - 1
        
        while left < right:
            total = nums[i] + nums[left] + nums[right]
            
            if total < 0:
                left += 1
            elif total > 0:
                right -= 1
            else:
                result.append([nums[i], nums[left], nums[right]])
                
                # Skip duplicates
                while left < right and nums[left] == nums[left + 1]:
                    left += 1
                while left < right and nums[right] == nums[right - 1]:
                    right -= 1
                
                left += 1
                right -= 1
    
    return result

# Example
print(three_sum([-1, 0, 1, 2, -1, -4]))  # [[-1, -1, 2], [-1, 0, 1]]
```

**Explanation:**
1. Sort the array
2. Fix first element, use two pointers for others
3. Skip duplicates to avoid repeated triplets

---

### 10. Container With Most Water
**Problem:** Find two lines that form container with most water.

```python
def max_area(height):
    """
    Time: O(n), Space: O(1)
    Two-pointer approach
    """
    left, right = 0, len(height) - 1
    max_water = 0
    
    while left < right:
        width = right - left
        current_height = min(height[left], height[right])
        max_water = max(max_water, width * current_height)
        
        # Move pointer with smaller height
        if height[left] < height[right]:
            left += 1
        else:
            right -= 1
    
    return max_water

# Example
print(max_area([1, 8, 6, 2, 5, 4, 8, 3, 7]))  # 49
```

**Explanation:**
1. Start with widest container
2. Move pointer with smaller height inward
3. Track maximum area

---

### 11. Merge Intervals
**Problem:** Merge overlapping intervals.

```python
def merge(intervals):
    """
    Time: O(n log n), Space: O(n)
    Sort then merge
    """
    if not intervals:
        return []
    
    intervals.sort(key=lambda x: x[0])
    merged = [intervals[0]]
    
    for current in intervals[1:]:
        last = merged[-1]
        
        if current[0] <= last[1]:
            # Overlapping, merge
            merged[-1] = [last[0], max(last[1], current[1])]
        else:
            # Non-overlapping, add
            merged.append(current)
    
    return merged

# Example
print(merge([[1, 3], [2, 6], [8, 10], [15, 18]]))  # [[1, 6], [8, 10], [15, 18]]
```

**Explanation:**
1. Sort intervals by start time
2. Compare each interval with last merged
3. Merge if overlapping, otherwise add new

---

### 12. Insert Interval
**Problem:** Insert interval and merge if necessary.

```python
def insert(intervals, newInterval):
    """
    Time: O(n), Space: O(n)
    Three-part approach
    """
    result = []
    i = 0
    n = len(intervals)
    
    # Add intervals before newInterval
    while i < n and intervals[i][1] < newInterval[0]:
        result.append(intervals[i])
        i += 1
    
    # Merge overlapping intervals
    while i < n and intervals[i][0] <= newInterval[1]:
        newInterval[0] = min(newInterval[0], intervals[i][0])
        newInterval[1] = max(newInterval[1], intervals[i][1])
        i += 1
    result.append(newInterval)
    
    # Add remaining intervals
    while i < n:
        result.append(intervals[i])
        i += 1
    
    return result

# Example
print(insert([[1, 3], [6, 9]], [2, 5]))  # [[1, 5], [6, 9]]
```

**Explanation:**
1. Add all intervals that end before new interval
2. Merge all overlapping intervals
3. Add remaining intervals

---

### 13. Non-Overlapping Intervals
**Problem:** Minimum removals to make intervals non-overlapping.

```python
def erase_overlap_intervals(intervals):
    """
    Time: O(n log n), Space: O(1)
    Greedy approach - sort by end time
    """
    if not intervals:
        return 0
    
    intervals.sort(key=lambda x: x[1])
    count = 0
    end = intervals[0][1]
    
    for i in range(1, len(intervals)):
        if intervals[i][0] < end:
            # Overlapping, remove this interval
            count += 1
        else:
            # Non-overlapping, update end
            end = intervals[i][1]
    
    return count

# Example
print(erase_overlap_intervals([[1, 2], [2, 3], [3, 4], [1, 3]]))  # 1
```

**Explanation:**
1. Sort by end time
2. Keep track of last non-overlapping end
3. Count overlaps (intervals to remove)

---

### 14. Meeting Rooms
**Problem:** Check if person can attend all meetings.

```python
def can_attend_meetings(intervals):
    """
    Time: O(n log n), Space: O(1)
    Sort and check for overlaps
    """
    intervals.sort(key=lambda x: x[0])
    
    for i in range(1, len(intervals)):
        if intervals[i][0] < intervals[i - 1][1]:
            return False
    
    return True

# Example
print(can_attend_meetings([[0, 30], [5, 10], [15, 20]]))  # False
```

**Explanation:**
1. Sort meetings by start time
2. Check if any meeting starts before previous ends

---

### 15. Meeting Rooms II
**Problem:** Minimum number of conference rooms needed.

```python
def min_meeting_rooms(intervals):
    """
    Time: O(n log n), Space: O(n)
    Separate start and end times
    """
    if not intervals:
        return 0
    
    starts = sorted([i[0] for i in intervals])
    ends = sorted([i[1] for i in intervals])
    
    rooms = 0
    max_rooms = 0
    start_ptr = end_ptr = 0
    
    while start_ptr < len(intervals):
        if starts[start_ptr] < ends[end_ptr]:
            rooms += 1
            max_rooms = max(max_rooms, rooms)
            start_ptr += 1
        else:
            rooms -= 1
            end_ptr += 1
    
    return max_rooms

# Example
print(min_meeting_rooms([[0, 30], [5, 10], [15, 20]]))  # 2
```

**Explanation:**
1. Sort start and end times separately
2. When meeting starts, increment rooms
3. When meeting ends, decrement rooms
4. Track maximum concurrent rooms

---

### 16. Rotate Array
**Problem:** Rotate array k steps to the right.

```python
def rotate(nums, k):
    """
    Time: O(n), Space: O(1)
    Reverse approach
    """
    k = k % len(nums)
    
    # Reverse entire array
    reverse(nums, 0, len(nums) - 1)
    # Reverse first k elements
    reverse(nums, 0, k - 1)
    # Reverse remaining elements
    reverse(nums, k, len(nums) - 1)

def reverse(nums, left, right):
    while left < right:
        nums[left], nums[right] = nums[right], nums[left]
        left += 1
        right -= 1

# Example
nums = [1, 2, 3, 4, 5, 6, 7]
rotate(nums, 3)
print(nums)  # [5, 6, 7, 1, 2, 3, 4]
```

**Explanation:**
1. Reverse entire array
2. Reverse first k elements
3. Reverse remaining elements

---

### 17. Move Zeroes
**Problem:** Move all zeros to end while maintaining order.

```python
def move_zeroes(nums):
    """
    Time: O(n), Space: O(1)
    Two-pointer approach
    """
    left = 0  # Position for next non-zero
    
    for right in range(len(nums)):
        if nums[right] != 0:
            nums[left], nums[right] = nums[right], nums[left]
            left += 1

# Example
nums = [0, 1, 0, 3, 12]
move_zeroes(nums)
print(nums)  # [1, 3, 12, 0, 0]
```

**Explanation:**
1. Left pointer tracks position for next non-zero
2. Right pointer scans array
3. Swap non-zero elements to left

---

### 18. Find All Duplicates in Array
**Problem:** Find duplicates in array where 1 ≤ a[i] ≤ n.

```python
def find_duplicates(nums):
    """
    Time: O(n), Space: O(1)
    Use array indices as markers
    """
    result = []
    
    for num in nums:
        index = abs(num) - 1
        if nums[index] < 0:
            result.append(abs(num))
        else:
            nums[index] = -nums[index]
    
    return result

# Example
print(find_duplicates([4, 3, 2, 7, 8, 2, 3, 1]))  # [2, 3]
```

**Explanation:**
1. Use sign of element at index as marker
2. If already negative, it's a duplicate
3. Mark visited indices by negating

---

### 19. Missing Number
**Problem:** Find missing number from 0 to n.

```python
def missing_number(nums):
    """
    Time: O(n), Space: O(1)
    XOR or sum approach
    """
    # Method 1: XOR
    missing = len(nums)
    for i, num in enumerate(nums):
        missing ^= i ^ num
    return missing

# Method 2: Sum
def missing_number_v2(nums):
    n = len(nums)
    expected_sum = n * (n + 1) // 2
    actual_sum = sum(nums)
    return expected_sum - actual_sum

# Example
print(missing_number([3, 0, 1]))  # 2
```

**Explanation:**
1. XOR approach: XOR cancels out matching numbers
2. Sum approach: difference between expected and actual

---

### 20. Find Peak Element
**Problem:** Find peak element (greater than neighbors).

```python
def find_peak_element(nums):
    """
    Time: O(log n), Space: O(1)
    Binary search
    """
    left, right = 0, len(nums) - 1
    
    while left < right:
        mid = (left + right) // 2
        
        if nums[mid] > nums[mid + 1]:
            # Peak is on left side (including mid)
            right = mid
        else:
            # Peak is on right side
            left = mid + 1
    
    return left

# Example
print(find_peak_element([1, 2, 3, 1]))  # 2
```

**Explanation:**
1. Binary search for peak
2. If mid > mid+1, peak is on left
3. Otherwise, peak is on right

---

### 21. Subarray Sum Equals K
**Problem:** Count subarrays with sum equal to k.

```python
def subarray_sum(nums, k):
    """
    Time: O(n), Space: O(n)
    Prefix sum with hashmap
    """
    count = 0
    current_sum = 0
    prefix_sums = {0: 1}  # sum: frequency
    
    for num in nums:
        current_sum += num
        
        # Check if (current_sum - k) exists
        if current_sum - k in prefix_sums:
            count += prefix_sums[current_sum - k]
        
        # Update prefix sum count
        prefix_sums[current_sum] = prefix_sums.get(current_sum, 0) + 1
    
    return count

# Example
print(subarray_sum([1, 1, 1], 2))  # 2
```

**Explanation:**
1. Track prefix sums and their frequencies
2. If (current_sum - k) exists, we found subarrays
3. Update prefix sum counts

---

### 22. Longest Consecutive Sequence
**Problem:** Find length of longest consecutive sequence.

```python
def longest_consecutive(nums):
    """
    Time: O(n), Space: O(n)
    Use set for O(1) lookups
    """
    if not nums:
        return 0
    
    num_set = set(nums)
    longest = 0
    
    for num in num_set:
        # Only start counting from sequence start
        if num - 1 not in num_set:
            current = num
            streak = 1
            
            while current + 1 in num_set:
                current += 1
                streak += 1
            
            longest = max(longest, streak)
    
    return longest

# Example
print(longest_consecutive([100, 4, 200, 1, 3, 2]))  # 4
```

**Explanation:**
1. Convert to set for O(1) lookup
2. Only start counting from beginning of sequence
3. Count consecutive numbers

---

### 23. Majority Element
**Problem:** Find element appearing more than n/2 times.

```python
def majority_element(nums):
    """
    Time: O(n), Space: O(1)
    Boyer-Moore Voting Algorithm
    """
    candidate = None
    count = 0
    
    for num in nums:
        if count == 0:
            candidate = num
        count += 1 if num == candidate else -1
    
    return candidate

# Example
print(majority_element([3, 2, 3]))  # 3
```

**Explanation:**
1. Maintain candidate and count
2. Increment count for candidate, decrement for others
3. Candidate at end is majority (guaranteed to exist)

---

### 24. Majority Element II
**Problem:** Find all elements appearing more than n/3 times.

```python
def majority_element_ii(nums):
    """
    Time: O(n), Space: O(1)
    Extended Boyer-Moore
    """
    if not nums:
        return []
    
    # At most 2 elements can appear > n/3 times
    candidate1 = candidate2 = None
    count1 = count2 = 0
    
    # Find candidates
    for num in nums:
        if num == candidate1:
            count1 += 1
        elif num == candidate2:
            count2 += 1
        elif count1 == 0:
            candidate1 = num
            count1 = 1
        elif count2 == 0:
            candidate2 = num
            count2 = 1
        else:
            count1 -= 1
            count2 -= 1
    
    # Verify candidates
    result = []
    for candidate in [candidate1, candidate2]:
        if nums.count(candidate) > len(nums) // 3:
            result.append(candidate)
    
    return result

# Example
print(majority_element_ii([3, 2, 3]))  # [3]
```

**Explanation:**
1. At most 2 elements can appear > n/3 times
2. Find two candidates using modified Boyer-Moore
3. Verify candidates actually appear > n/3 times

---

### 25. Find Duplicate Number
**Problem:** Find duplicate in array of n+1 integers (1 to n).

```python
def find_duplicate(nums):
    """
    Time: O(n), Space: O(1)
    Floyd's Cycle Detection
    """
    # Find intersection point
    slow = fast = nums[0]
    
    while True:
        slow = nums[slow]
        fast = nums[nums[fast]]
        if slow == fast:
            break
    
    # Find entrance to cycle
    slow = nums[0]
    while slow != fast:
        slow = nums[slow]
        fast = nums[fast]
    
    return slow

# Example
print(find_duplicate([1, 3, 4, 2, 2]))  # 2
```

**Explanation:**
1. Treat array as linked list (value as next pointer)
2. Use Floyd's algorithm to find cycle
3. Cycle entrance is the duplicate

---

### 26. Maximum Sum Circular Subarray
**Problem:** Find maximum sum of circular subarray.

```python
def max_subarray_sum_circular(nums):
    """
    Time: O(n), Space: O(1)
    Two cases: max in middle or wraps around
    """
    def kadane_max(arr):
        max_sum = curr_sum = arr[0]
        for num in arr[1:]:
            curr_sum = max(num, curr_sum + num)
            max_sum = max(max_sum, curr_sum)
        return max_sum
    
    def kadane_min(arr):
        min_sum = curr_sum = arr[0]
        for num in arr[1:]:
            curr_sum = min(num, curr_sum + num)
            min_sum = min(min_sum, curr_sum)
        return min_sum
    
    max_normal = kadane_max(nums)
    total_sum = sum(nums)
    min_sum = kadane_min(nums)
    
    # If all negative, return max_normal
    if total_sum == min_sum:
        return max_normal
    
    max_circular = total_sum - min_sum
    return max(max_normal, max_circular)

# Example
print(max_subarray_sum_circular([5, -3, 5]))  # 10
```

**Explanation:**
1. Case 1: Maximum subarray doesn't wrap (standard Kadane)
2. Case 2: Maximum wraps = total - minimum subarray
3. Handle all-negative case

---

### 27. Maximum Sliding Window
**Problem:** Find maximum in each sliding window of size k.

```python
from collections import deque

def max_sliding_window(nums, k):
    """
    Time: O(n), Space: O(k)
    Monotonic decreasing deque
    """
    if not nums:
        return []
    
    dq = deque()  # Store indices
    result = []
    
    for i, num in enumerate(nums):
        # Remove indices outside window
        while dq and dq[0] < i - k + 1:
            dq.popleft()
        
        # Remove smaller elements
        while dq and nums[dq[-1]] < num:
            dq.pop()
        
        dq.append(i)
        
        # Add to result when window is complete
        if i >= k - 1:
            result.append(nums[dq[0]])
    
    return result

# Example
print(max_sliding_window([1, 3, -1, -3, 5, 3, 6, 7], 3))  # [3, 3, 5, 5, 6, 7]
```

**Explanation:**
1. Use deque to maintain indices in decreasing order
2. Remove indices outside window
3. Remove smaller elements (not useful)
4. Front of deque is maximum

---

### 28. Minimum Size Subarray Sum
**Problem:** Find minimum length subarray with sum ≥ target.

```python
def min_subarray_len(target, nums):
    """
    Time: O(n), Space: O(1)
    Sliding window
    """
    left = 0
    current_sum = 0
    min_length = float('inf')
    
    for right in range(len(nums)):
        current_sum += nums[right]
        
        while current_sum >= target:
            min_length = min(min_length, right - left + 1)
            current_sum -= nums[left]
            left += 1
    
    return min_length if min_length != float('inf') else 0

# Example
print(min_subarray_len(7, [2, 3, 1, 2, 4, 3]))  # 2
```

**Explanation:**
1. Expand window by moving right pointer
2. Contract window while sum ≥ target
3. Track minimum length

---

### 29. Kth Largest Element in Array
**Problem:** Find kth largest element.

```python
import heapq
import random

def find_kth_largest(nums, k):
    """
    Method 1: Min heap
    Time: O(n log k), Space: O(k)
    """
    heap = []
    for num in nums:
        heapq.heappush(heap, num)
        if len(heap) > k:
            heapq.heappop(heap)
    return heap[0]

def find_kth_largest_quickselect(nums, k):
    """
    Method 2: Quickselect
    Time: O(n) average, Space: O(1)
    """
    k = len(nums) - k  # Convert to kth smallest
    
    def quickselect(left, right):
        pivot = nums[right]
        p = left
        
        for i in range(left, right):
            if nums[i] <= pivot:
                nums[p], nums[i] = nums[i], nums[p]
                p += 1
        
        nums[p], nums[right] = nums[right], nums[p]
        
        if p < k:
            return quickselect(p + 1, right)
        elif p > k:
            return quickselect(left, p - 1)
        else:
            return nums[p]
    
    return quickselect(0, len(nums) - 1)

# Example
print(find_kth_largest([3, 2, 1, 5, 6, 4], 2))  # 5
```

**Explanation:**
1. Heap method: maintain k largest elements
2. Quickselect: partition around pivot like quicksort

---

### 30. Find Pivot Index
**Problem:** Find index where left sum equals right sum.

```python
def pivot_index(nums):
    """
    Time: O(n), Space: O(1)
    Prefix sum approach
    """
    total_sum = sum(nums)
    left_sum = 0
    
    for i, num in enumerate(nums):
        right_sum = total_sum - left_sum - num
        
        if left_sum == right_sum:
            return i
        
        left_sum += num
    
    return -1

# Example
print(pivot_index([1, 7, 3, 6, 5, 6]))  # 3
```

**Explanation:**
1. Calculate total sum
2. Track left sum as we iterate
3. Check if left sum equals right sum

---

## 2. STRINGS (30 Questions)

### 31. Valid Anagram
**Problem:** Check if two strings are anagrams.

```python
def is_anagram(s, t):
    """
    Time: O(n), Space: O(1) - limited character set
    Use character count
    """
    if len(s) != len(t):
        return False
    
    # Method 1: Using Counter
    from collections import Counter
    return Counter(s) == Counter(t)

# Method 2: Sorting
def is_anagram_v2(s, t):
    return sorted(s) == sorted(t)

# Method 3: Character array
def is_anagram_v3(s, t):
    if len(s) != len(t):
        return False
    
    counts = [0] * 26
    for i in range(len(s)):
        counts[ord(s[i]) - ord('a')] += 1
        counts[ord(t[i]) - ord('a')] -= 1
    
    return all(c == 0 for c in counts)

# Example
print(is_anagram("anagram", "nagaram"))  # True
```

**Explanation:**
1. Check if lengths match
2. Count character frequencies
3. Compare counts

---

### 32. Valid Palindrome
**Problem:** Check if string is palindrome (alphanumeric only).

```python
def is_palindrome(s):
    """
    Time: O(n), Space: O(1)
    Two-pointer approach
    """
    left, right = 0, len(s) - 1
    
    while left < right:
        # Skip non-alphanumeric
        while left < right and not s[left].isalnum():
            left += 1
        while left < right and not s[right].isalnum():
            right -= 1
        
        if s[left].lower() != s[right].lower():
            return False
        
        left += 1
        right -= 1
    
    return True

# Example
print(is_palindrome("A man, a plan, a canal: Panama"))  # True
```

**Explanation:**
1. Use two pointers from both ends
2. Skip non-alphanumeric characters
3. Compare characters case-insensitively

---

### 33. Longest Substring Without Repeating Characters
**Problem:** Find length of longest substring without repeats.

```python
def length_of_longest_substring(s):
    """
    Time: O(n), Space: O(min(n, m)) where m is charset size
    Sliding window with hashmap
    """
    char_index = {}
    left = 0
    max_length = 0
    
    for right, char in enumerate(s):
        if char in char_index and char_index[char] >= left:
            left = char_index[char] + 1
        
        char_index[char] = right
        max_length = max(max_length, right - left + 1)
    
    return max_length

# Example
print(length_of_longest_substring("abcabcbb"))  # 3
```

**Explanation:**
1. Use sliding window with hashmap
2. Track last index of each character
3. Move left pointer when duplicate found

---

### 34. Longest Palindromic Substring
**Problem:** Find longest palindromic substring.

```python
def longest_palindrome(s):
    """
    Time: O(n²), Space: O(1)
    Expand around center
    """
    if not s:
        return ""
    
    def expand_around_center(left, right):
        while left >= 0 and right < len(s) and s[left] == s[right]:
            left -= 1
            right += 1
        return right - left - 1
    
    start = end = 0
    
    for i in range(len(s)):
        # Odd length palindrome
        len1 = expand_around_center(i, i)
        # Even length palindrome
        len2 = expand_around_center(i, i + 1)
        
        max_len = max(len1, len2)
        
        if max_len > end - start:
            start = i - (max_len - 1) // 2
            end = i + max_len // 2
    
    return s[start:end + 1]

# Example
print(longest_palindrome("babad"))  # "bab" or "aba"
```

**Explanation:**
1. For each position, expand around center
2. Check both odd and even length palindromes
3. Track longest palindrome found

---

### 35. Group Anagrams
**Problem:** Group strings that are anagrams.

```python
def group_anagrams(strs):
    """
    Time: O(n * k log k) where k is max string length
    Space: O(n * k)
    Sort and group
    """
    from collections import defaultdict
    
    groups = defaultdict(list)
    
    for s in strs:
        key = ''.join(sorted(s))
        groups[key].append(s)
    
    return list(groups.values())

# Alternative: Character count as key
def group_anagrams_v2(strs):
    from collections import defaultdict
    
    groups = defaultdict(list)
    
    for s in strs:
        count = [0] * 26
        for c in s:
            count[ord(c) - ord('a')] += 1
        groups[tuple(count)].append(s)
    
    return list(groups.values())

# Example
print(group_anagrams(["eat", "tea", "tan", "ate", "nat", "bat"]))
# [["eat", "tea", "ate"], ["tan", "nat"], ["bat"]]
```

**Explanation:**
1. Use sorted string or character count as key
2. Group strings with same key
3. Return grouped values

---

### 36. Minimum Window Substring
**Problem:** Find minimum window containing all characters of t.

```python
def min_window(s, t):
    """
    Time: O(|s| + |t|), Space: O(|t|)
    Sliding window with character counts
    """
    from collections import Counter
    
    if not s or not t:
        return ""
    
    target_counts = Counter(t)
    required = len(target_counts)
    formed = 0
    
    window_counts = {}
    left = 0
    min_len = float('inf')
    min_left = 0
    
    for right, char in enumerate(s):
        window_counts[char] = window_counts.get(char, 0) + 1
        
        if char in target_counts and window_counts[char] == target_counts[char]:
            formed += 1
        
        while left <= right and formed == required:
            # Update result
            if right - left + 1 < min_len:
                min_len = right - left + 1
                min_left = left
            
            # Contract window
            char = s[left]
            window_counts[char] -= 1
            if char in target_counts and window_counts[char] < target_counts[char]:
                formed -= 1
            left += 1
    
    return "" if min_len == float('inf') else s[min_left:min_left + min_len]

# Example
print(min_window("ADOBECODEBANC", "ABC"))  # "BANC"
```

**Explanation:**
1. Count characters needed from t
2. Expand window until all characters found
3. Contract window while maintaining validity
4. Track minimum window

---

### 37. Longest Common Prefix
**Problem:** Find longest common prefix among strings.

```python
def longest_common_prefix(strs):
    """
    Time: O(S) where S is sum of all characters
    Space: O(1)
    Vertical scanning
    """
    if not strs:
        return ""
    
    for i in range(len(strs[0])):
        char = strs[0][i]
        for s in strs[1:]:
            if i >= len(s) or s[i] != char:
                return strs[0][:i]
    
    return strs[0]

# Alternative: Horizontal scanning
def longest_common_prefix_v2(strs):
    if not strs:
        return ""
    
    prefix = strs[0]
    for s in strs[1:]:
        while not s.startswith(prefix):
            prefix = prefix[:-1]
            if not prefix:
                return ""
    
    return prefix

# Example
print(longest_common_prefix(["flower", "flow", "flight"]))  # "fl"
```

**Explanation:**
1. Compare characters at each position
2. Stop when mismatch or end of string
3. Return common prefix

---

### 38. Implement strStr()
**Problem:** Find first occurrence of needle in haystack.

```python
def str_str(haystack, needle):
    """
    Time: O(n * m), Space: O(1)
    Sliding window comparison
    """
    if not needle:
        return 0
    
    n, m = len(haystack), len(needle)
    
    for i in range(n - m + 1):
        if haystack[i:i + m] == needle:
            return i
    
    return -1

# KMP Algorithm for O(n + m)
def str_str_kmp(haystack, needle):
    if not needle:
        return 0
    
    # Build LPS array
    def build_lps(pattern):
        lps = [0] * len(pattern)
        length = 0
        i = 1
        
        while i < len(pattern):
            if pattern[i] == pattern[length]:
                length += 1
                lps[i] = length
                i += 1
            else:
                if length != 0:
                    length = lps[length - 1]
                else:
                    lps[i] = 0
                    i += 1
        return lps
    
    lps = build_lps(needle)
    i = j = 0
    
    while i < len(haystack):
        if haystack[i] == needle[j]:
            i += 1
            j += 1
        
        if j == len(needle):
            return i - j
        elif i < len(haystack) and haystack[i] != needle[j]:
            if j != 0:
                j = lps[j - 1]
            else:
                i += 1
    
    return -1

# Example
print(str_str("hello", "ll"))  # 2
```

**Explanation:**
1. Simple: check each possible position
2. KMP: use pattern preprocessing for efficiency

---

### 39. String Compression
**Problem:** Compress string using counts of repeated chars.

```python
def compress(chars):
    """
    Time: O(n), Space: O(1)
    In-place two-pointer
    """
    write = 0
    i = 0
    
    while i < len(chars):
        char = chars[i]
        count = 0
        
        # Count consecutive characters
        while i < len(chars) and chars[i] == char:
            count += 1
            i += 1
        
        # Write character
        chars[write] = char
        write += 1
        
        # Write count if > 1
        if count > 1:
            for digit in str(count):
                chars[write] = digit
                write += 1
    
    return write

# Example
chars = ["a", "a", "b", "b", "c", "c", "c"]
length = compress(chars)
print(chars[:length])  # ['a', '2', 'b', '2', 'c', '3']
```

**Explanation:**
1. Count consecutive characters
2. Write character and count
3. Use two pointers for in-place modification

---

### 40. Reverse Words in String
**Problem:** Reverse order of words in string.

```python
def reverse_words(s):
    """
    Time: O(n), Space: O(n)
    Split, reverse, join
    """
    return ' '.join(reversed(s.split()))

# Manual approach
def reverse_words_manual(s):
    # Trim and split
    words = s.strip().split()
    
    # Reverse words
    left, right = 0, len(words) - 1
    while left < right:
        words[left], words[right] = words[right], words[left]
        left += 1
        right -= 1
    
    return ' '.join(words)

# Example
print(reverse_words("  the sky is blue  "))  # "blue is sky the"
```

**Explanation:**
1. Split string into words
2. Reverse word order
3. Join with space

---

### 41. Palindromic Substrings
**Problem:** Count all palindromic substrings.

```python
def count_substrings(s):
    """
    Time: O(n²), Space: O(1)
    Expand around center
    """
    def expand_around_center(left, right):
        count = 0
        while left >= 0 and right < len(s) and s[left] == s[right]:
            count += 1
            left -= 1
            right += 1
        return count
    
    total = 0
    for i in range(len(s)):
        # Odd length
        total += expand_around_center(i, i)
        # Even length
        total += expand_around_center(i, i + 1)
    
    return total

# Example
print(count_substrings("abc"))  # 3
print(count_substrings("aaa"))  # 6
```

**Explanation:**
1. For each center, expand outward
2. Count palindromes with odd and even lengths
3. Sum all counts

---

### 42. Longest Repeating Character Replacement
**Problem:** Longest substring with same letter after k replacements.

```python
def character_replacement(s, k):
    """
    Time: O(n), Space: O(1) - only 26 letters
    Sliding window
    """
    from collections import defaultdict
    
    counts = defaultdict(int)
    left = 0
    max_count = 0
    max_length = 0
    
    for right in range(len(s)):
        counts[s[right]] += 1
        max_count = max(max_count, counts[s[right]])
        
        # If window invalid, shrink from left
        while (right - left + 1) - max_count > k:
            counts[s[left]] -= 1
            left += 1
        
        max_length = max(max_length, right - left + 1)
    
    return max_length

# Example
print(character_replacement("ABAB", 2))  # 4
```

**Explanation:**
1. Maintain window with most frequent character
2. If replacements needed > k, shrink window
3. Track maximum valid window

---

### 43. Decode String
**Problem:** Decode string with pattern k[encoded_string].

```python
def decode_string(s):
    """
    Time: O(maxK * n), Space: O(n)
    Stack-based approach
    """
    stack = []
    current_num = 0
    current_str = ""
    
    for char in s:
        if char.isdigit():
            current_num = current_num * 10 + int(char)
        elif char == '[':
            # Push current state to stack
            stack.append((current_str, current_num))
            current_str = ""
            current_num = 0
        elif char == ']':
            # Pop and decode
            prev_str, num = stack.pop()
            current_str = prev_str + current_str * num
        else:
            current_str += char
    
    return current_str

# Example
print(decode_string("3[a]2[bc]"))  # "aaabcbc"
print(decode_string("3[a2[c]]"))  # "accaccacc"
```

**Explanation:**
1. Use stack to handle nested brackets
2. Build number and string separately
3. On ']', pop and multiply string

---

### 44. Count and Say
**Problem:** Generate nth term of count-and-say sequence.

```python
def count_and_say(n):
    """
    Time: O(2^n), Space: O(2^n)
    Iterative building
    """
    result = "1"
    
    for _ in range(n - 1):
        next_result = ""
        i = 0
        
        while i < len(result):
            char = result[i]
            count = 1
            
            while i + 1 < len(result) and result[i + 1] == char:
                count += 1
                i += 1
            
            next_result += str(count) + char
            i += 1
        
        result = next_result
    
    return result

# Example
print(count_and_say(4))  # "1211"
```

**Explanation:**
1. Start with "1"
2. For each iteration, count consecutive digits
3. Build next string with counts

---

### 45. Multiply Strings
**Problem:** Multiply two numbers represented as strings.

```python
def multiply(num1, num2):
    """
    Time: O(m * n), Space: O(m + n)
    Grade school multiplication
    """
    if num1 == "0" or num2 == "0":
        return "0"
    
    m, n = len(num1), len(num2)
    result = [0] * (m + n)
    
    # Multiply each digit
    for i in range(m - 1, -1, -1):
        for j in range(n - 1, -1, -1):
            mul = int(num1[i]) * int(num2[j])
            p1, p2 = i + j, i + j + 1
            total = mul + result[p2]
            
            result[p2] = total % 10
            result[p1] += total // 10
    
    # Convert to string, skip leading zeros
    result_str = ''.join(map(str, result))
    return result_str.lstrip('0') or "0"

# Example
print(multiply("123", "456"))  # "56088"
```

**Explanation:**
1. Create array to store products
2. Multiply each digit pair
3. Handle carries and convert to string

---

### 46. Add Binary
**Problem:** Add two binary strings.

```python
def add_binary(a, b):
    """
    Time: O(max(m, n)), Space: O(max(m, n))
    Process from right to left with carry
    """
    result = []
    carry = 0
    i, j = len(a) - 1, len(b) - 1
    
    while i >= 0 or j >= 0 or carry:
        total = carry
        
        if i >= 0:
            total += int(a[i])
            i -= 1
        
        if j >= 0:
            total += int(b[j])
            j -= 1
        
        result.append(str(total % 2))
        carry = total // 2
    
    return ''.join(reversed(result))

# Example
print(add_binary("1010", "1011"))  # "10101"
```

**Explanation:**
1. Process digits from right to left
2. Track carry for next position
3. Reverse result at end

---

### 47. Simplify Path
**Problem:** Simplify Unix file path.

```python
def simplify_path(path):
    """
    Time: O(n), Space: O(n)
    Stack-based path building
    """
    stack = []
    
    for component in path.split('/'):
        if component == '..' and stack:
            stack.pop()
        elif component and component not in ['.', '..']:
            stack.append(component)
    
    return '/' + '/'.join(stack)

# Example
print(simplify_path("/home//foo/"))  # "/home/foo"
print(simplify_path("/a/./b/../../c/"))  # "/c"
```

**Explanation:**
1. Split path by '/'
2. Use stack: push valid dirs, pop for '..'
3. Join stack with '/'

---

### 48. Valid Parentheses
**Problem:** Check if parentheses are valid.

```python
def is_valid(s):
    """
    Time: O(n), Space: O(n)
    Stack matching
    """
    stack = []
    mapping = {')': '(', '}': '{', ']': '['}
    
    for char in s:
        if char in mapping:
            top = stack.pop() if stack else '#'
            if mapping[char] != top:
                return False
        else:
            stack.append(char)
    
    return not stack

# Example
print(is_valid("()[]{}"))  # True
print(is_valid("([)]"))  # False
```

**Explanation:**
1. Push opening brackets to stack
2. For closing brackets, check if matches top
3. Stack should be empty at end

---

### 49. Generate Parentheses
**Problem:** Generate all valid n pairs of parentheses.

```python
def generate_parenthesis(n):
    """
    Time: O(4^n / sqrt(n)), Space: O(n)
    Backtracking
    """
    result = []
    
    def backtrack(current, open_count, close_count):
        if len(current) == 2 * n:
            result.append(current)
            return
        
        if open_count < n:
            backtrack(current + '(', open_count + 1, close_count)
        
        if close_count < open_count:
            backtrack(current + ')', open_count, close_count + 1)
    
    backtrack('', 0, 0)
    return result

# Example
print(generate_parenthesis(3))
# ["((()))", "(()())", "(())()", "()(())", "()()()"]
```

**Explanation:**
1. Use backtracking to build combinations
2. Add '(' if we haven't used all n
3. Add ')' if it won't make string invalid

---

### 50. Remove Invalid Parentheses
**Problem:** Remove minimum parentheses to make valid.

```python
def remove_invalid_parentheses(s):
    """
    Time: O(2^n), Space: O(n)
    BFS to find minimum removals
    """
    from collections import deque
    
    def is_valid(s):
        count = 0
        for char in s:
            if char == '(':
                count += 1
            elif char == ')':
                count -= 1
                if count < 0:
                    return False
        return count == 0
    
    if is_valid(s):
        return [s]
    
    result = []
    visited = {s}
    queue = deque([s])
    found = False
    
    while queue and not found:
        for _ in range(len(queue)):
            current = queue.popleft()
            
            if is_valid(current):
                result.append(current)
                found = True
            
            if found:
                continue
            
            for i in range(len(current)):
                if current[i] not in '()':
                    continue
                
                next_str = current[:i] + current[i+1:]
                if next_str not in visited:
                    visited.add(next_str)
                    queue.append(next_str)
    
    return result

# Example
print(remove_invalid_parentheses("()())()"))  # ["(())()", "()()()"]
```

**Explanation:**
1. Use BFS to try removing each parenthesis
2. Check validity at each level
3. Return first valid level found

---

### 51. Word Break
**Problem:** Check if string can be segmented into dictionary words.

```python
def word_break(s, word_dict):
    """
    Time: O(n²), Space: O(n)
    Dynamic programming
    """
    word_set = set(word_dict)
    dp = [False] * (len(s) + 1)
    dp[0] = True
    
    for i in range(1, len(s) + 1):
        for j in range(i):
            if dp[j] and s[j:i] in word_set:
                dp[i] = True
                break
    
    return dp[len(s)]

# Example
print(word_break("leetcode", ["leet", "code"]))  # True
```

**Explanation:**
1. dp[i] = can segment s[0:i]
2. Check all possible last words
3. If any partition works, mark True

---

### 52. Word Break II
**Problem:** Return all possible segmentations.

```python
def word_break_ii(s, word_dict):
    """
    Time: O(2^n), Space: O(2^n)
    Backtracking with memoization
    """
    word_set = set(word_dict)
    memo = {}
    
    def backtrack(start):
        if start in memo:
            return memo[start]
        
        if start == len(s):
            return [[]]
        
        result = []
        for end in range(start + 1, len(s) + 1):
            word = s[start:end]
            if word in word_set:
                for rest in backtrack(end):
                    result.append([word] + rest)
        
        memo[start] = result
        return result
    
    return [' '.join(words) for words in backtrack(0)]

# Example
print(word_break_ii("catsanddog", ["cat", "cats", "and", "sand", "dog"]))
# ["cats and dog", "cat sand dog"]
```

**Explanation:**
1. Try all possible first words
2. Recursively segment remainder
3. Memoize to avoid recomputation

---

### 53. Longest Valid Parentheses
**Problem:** Length of longest valid parentheses substring.

```python
def longest_valid_parentheses(s):
    """
    Time: O(n), Space: O(n)
    Stack-based approach
    """
    stack = [-1]
    max_length = 0
    
    for i, char in enumerate(s):
        if char == '(':
            stack.append(i)
        else:
            stack.pop()
            if not stack:
                stack.append(i)
            else:
                max_length = max(max_length, i - stack[-1])
    
    return max_length

# DP approach
def longest_valid_parentheses_dp(s):
    if not s:
        return 0
    
    dp = [0] * len(s)
    max_length = 0
    
    for i in range(1, len(s)):
        if s[i] == ')':
            if s[i - 1] == '(':
                dp[i] = (dp[i - 2] if i >= 2 else 0) + 2
            elif i - dp[i - 1] > 0 and s[i - dp[i - 1] - 1] == '(':
                dp[i] = dp[i - 1] + 2 + (dp[i - dp[i - 1] - 2] if i - dp[i - 1] >= 2 else 0)
            
            max_length = max(max_length, dp[i])
    
    return max_length

# Example
print(longest_valid_parentheses("(()"))  # 2
```

**Explanation:**
1. Stack method: track indices of unmatched parentheses
2. DP method: dp[i] = length ending at i

---

### 54. Edit Distance
**Problem:** Minimum operations to convert word1 to word2.

```python
def min_distance(word1, word2):
    """
    Time: O(m * n), Space: O(m * n)
    Dynamic programming
    """
    m, n = len(word1), len(word2)
    dp = [[0] * (n + 1) for _ in range(m + 1)]
    
    # Base cases
    for i in range(m + 1):
        dp[i][0] = i
    for j in range(n + 1):
        dp[0][j] = j
    
    # Fill DP table
    for i in range(1, m + 1):
        for j in range(1, n + 1):
            if word1[i - 1] == word2[j - 1]:
                dp[i][j] = dp[i - 1][j - 1]
            else:
                dp[i][j] = 1 + min(
                    dp[i - 1][j],      # Delete
                    dp[i][j - 1],      # Insert
                    dp[i - 1][j - 1]   # Replace
                )
    
    return dp[m][n]

# Example
print(min_distance("horse", "ros"))  # 3
```

**Explanation:**
1. dp[i][j] = min operations for word1[0:i] to word2[0:j]
2. If characters match, no operation needed
3. Otherwise, try insert/delete/replace

---

### 55. Interleaving String
**Problem:** Check if s3 is interleaving of s1 and s2.

```python
def is_interleave(s1, s2, s3):
    """
    Time: O(m * n), Space: O(m * n)
    Dynamic programming
    """
    m, n = len(s1), len(s2)
    
    if m + n != len(s3):
        return False
    
    dp = [[False] * (n + 1) for _ in range(m + 1)]
    dp[0][0] = True
    
    # First row
    for j in range(1, n + 1):
        dp[0][j] = dp[0][j - 1] and s2[j - 1] == s3[j - 1]
    
    # First column
    for i in range(1, m + 1):
        dp[i][0] = dp[i - 1][0] and s1[i - 1] == s3[i - 1]
    
    # Fill table
    for i in range(1, m + 1):
        for j in range(1, n + 1):
            dp[i][j] = (
                (dp[i - 1][j] and s1[i - 1] == s3[i + j - 1]) or
                (dp[i][j - 1] and s2[j - 1] == s3[i + j - 1])
            )
    
    return dp[m][n]

# Example
print(is_interleave("aabcc", "dbbca", "aadbbcbcac"))  # True
```

**Explanation:**
1. dp[i][j] = can form s3[0:i+j] from s1[0:i] and s2[0:j]
2. Check if current char from s1 or s2 matches s3
3. Combine with previous states

---

### 56. Minimum Remove to Make Valid Parentheses
**Problem:** Remove minimum parentheses to make valid.

```python
def min_remove_to_make_valid(s):
    """
    Time: O(n), Space: O(n)
    Two-pass with set
    """
    to_remove = set()
    stack = []
    
    # Find invalid closing brackets
    for i, char in enumerate(s):
        if char == '(':
            stack.append(i)
        elif char == ')':
            if stack:
                stack.pop()
            else:
                to_remove.add(i)
    
    # Add unmatched opening brackets
    to_remove.update(stack)
    
    # Build result
    return ''.join(char for i, char in enumerate(s) if i not in to_remove)

# Example
print(min_remove_to_make_valid("lee(t(c)o)de)"))  # "lee(t(c)o)de"
```

**Explanation:**
1. Track indices of unmatched parentheses
2. Remove those indices from string
3. Return cleaned string

---

### 57. Check Inclusion (Permutation in String)
**Problem:** Check if s2 contains permutation of s1.

```python
def check_inclusion(s1, s2):
    """
    Time: O(n), Space: O(1)
    Sliding window with character count
    """
    from collections import Counter
    
    if len(s1) > len(s2):
        return False
    
    s1_count = Counter(s1)
    window_count = Counter(s2[:len(s1)])
    
    if s1_count == window_count:
        return True
    
    for i in range(len(s1), len(s2)):
        # Add new character
        window_count[s2[i]] += 1
        
        # Remove old character
        left_char = s2[i - len(s1)]
        window_count[left_char] -= 1
        if window_count[left_char] == 0:
            del window_count[left_char]
        
        if s1_count == window_count:
            return True
    
    return False

# Example
print(check_inclusion("ab", "eidbaooo"))  # True
```

**Explanation:**
1. Use sliding window of s1's length
2. Compare character counts
3. Slide window and update counts

---

### 58. Z Algorithm Pattern Matching
**Problem:** Find all occurrences of pattern in text.

```python
def z_algorithm(text, pattern):
    """
    Time: O(n + m), Space: O(n + m)
    Z-algorithm for pattern matching
    """
    s = pattern + '$' + text
    n = len(s)
    z = [0] * n
    l, r = 0, 0
    
    for i in range(1, n):
        if i > r:
            l, r = i, i
            while r < n and s[r - l] == s[r]:
                r += 1
            z[i] = r - l
            r -= 1
        else:
            k = i - l
            if z[k] < r - i + 1:
                z[i] = z[k]
            else:
                l = i
                while r < n and s[r - l] == s[r]:
                    r += 1
                z[i] = r - l
                r -= 1
    
    # Find matches
    pattern_len = len(pattern)
    result = []
    for i in range(len(pattern) + 1, n):
        if z[i] == pattern_len:
            result.append(i - pattern_len - 1)
    
    return result

# Example
print(z_algorithm("ababcababa", "aba"))  # [0, 5, 7]
```

**Explanation:**
1. Concatenate pattern + separator + text
2. Compute Z-array (longest prefix match)
3. Positions with z[i] = pattern length are matches

---

### 59. Rabin-Karp String Matching
**Problem:** Find pattern in text using hashing.

```python
def rabin_karp(text, pattern):
    """
    Time: O(n + m) average, Space: O(1)
    Rolling hash for pattern matching
    """
    n, m = len(text), len(pattern)
    if m > n:
        return []
    
    # Constants for hashing
    d = 256  # Number of characters
    q = 101  # Prime modulus
    
    # Calculate hash values
    pattern_hash = 0
    text_hash = 0
    h = pow(d, m - 1, q)
    
    # Hash pattern and first window
    for i in range(m):
        pattern_hash = (d * pattern_hash + ord(pattern[i])) % q
        text_hash = (d * text_hash + ord(text[i])) % q
    
    result = []
    
    # Slide pattern over text
    for i in range(n - m + 1):
        if pattern_hash == text_hash:
            # Hash match, verify actual match
            if text[i:i + m] == pattern:
                result.append(i)
        
        # Calculate hash for next window
        if i < n - m:
            text_hash = (d * (text_hash - ord(text[i]) * h) + ord(text[i + m])) % q
            if text_hash < 0:
                text_hash += q
    
    return result

# Example
print(rabin_karp("ababcababa", "aba"))  # [0, 5, 7]
```

**Explanation:**
1. Compute hash of pattern
2. Compute rolling hash of text windows
3. When hashes match, verify actual match

---

### 60. KMP Algorithm
**Problem:** Pattern matching with KMP algorithm.

```python
def kmp_search(text, pattern):
    """
    Time: O(n + m), Space: O(m)
    Knuth-Morris-Pratt algorithm
    """
    def compute_lps(pattern):
        """Compute Longest Proper Prefix which is also Suffix"""
        m = len(pattern)
        lps = [0] * m
        length = 0
        i = 1
        
        while i < m:
            if pattern[i] == pattern[length]:
                length += 1
                lps[i] = length
                i += 1
            else:
                if length != 0:
                    length = lps[length - 1]
                else:
                    lps[i] = 0
                    i += 1
        
        return lps
    
    n, m = len(text), len(pattern)
    lps = compute_lps(pattern)
    result = []
    
    i = j = 0
    while i < n:
        if text[i] == pattern[j]:
            i += 1
            j += 1
        
        if j == m:
            result.append(i - j)
            j = lps[j - 1]
        elif i < n and text[i] != pattern[j]:
            if j != 0:
                j = lps[j - 1]
            else:
                i += 1
    
    return result

# Example
print(kmp_search("ababcababa", "aba"))  # [0, 5, 7]
```

**Explanation:**
1. Build LPS (failure function) for pattern
2. Use LPS to skip comparisons
3. Never backtrack in text

---

## 3. LINKED LISTS (25 Questions)

### 61. Reverse Linked List
**Problem:** Reverse a singly linked list.

```python
class ListNode:
    def __init__(self, val=0, next=None):
        self.val = val
        self.next = next

def reverse_list(head):
    """
    Time: O(n), Space: O(1)
    Iterative three-pointer approach
    """
    prev = None
    current = head
    
    while current:
        next_temp = current.next
        current.next = prev
        prev = current
        current = next_temp
    
    return prev

# Recursive approach
def reverse_list_recursive(head):
    """
    Time: O(n), Space: O(n) - recursion stack
    """
    if not head or not head.next:
        return head
    
    new_head = reverse_list_recursive(head.next)
    head.next.next = head
    head.next = None
    
    return new_head
```

**Explanation:**
1. Iterative: reverse pointers one by one
2. Recursive: reverse rest, then attach current

---

### 62. Detect Cycle in Linked List
**Problem:** Check if linked list has cycle.

```python
def has_cycle(head):
    """
    Time: O(n), Space: O(1)
    Floyd's cycle detection (two pointers)
    """
    if not head:
        return False
    
    slow = fast = head
    
    while fast and fast.next:
        slow = slow.next
        fast = fast.next.next
        
        if slow == fast:
            return True
    
    return False
```

**Explanation:**
1. Slow pointer moves 1 step, fast moves 2
2. If cycle exists, they will meet
3. Otherwise, fast reaches end

---

### 63. Merge Two Sorted Lists
**Problem:** Merge two sorted linked lists.

```python
def merge_two_lists(l1, l2):
    """
    Time: O(n + m), Space: O(1)
    Two-pointer merge
    """
    dummy = ListNode(0)
    current = dummy
    
    while l1 and l2:
        if l1.val <= l2.val:
            current.next = l1
            l1 = l1.next
        else:
            current.next = l2
            l2 = l2.next
        current = current.next
    
    # Attach remaining
    current.next = l1 if l1 else l2
    
    return dummy.next

# Recursive approach
def merge_two_lists_recursive(l1, l2):
    if not l1:
        return l2
    if not l2:
        return l1
    
    if l1.val <= l2.val:
        l1.next = merge_two_lists_recursive(l1.next, l2)
        return l1
    else:
        l2.next = merge_two_lists_recursive(l1, l2.next)
        return l2
```

**Explanation:**
1. Compare heads of both lists
2. Attach smaller node to result
3. Continue until one list exhausted

---

### 64. Remove Nth Node From End
**Problem:** Remove nth node from end of list.

```python
def remove_nth_from_end(head, n):
    """
    Time: O(n), Space: O(1)
    Two-pointer approach
    """
    dummy = ListNode(0)
    dummy.next = head
    
    fast = slow = dummy
    
    # Move fast n+1 steps ahead
    for _ in range(n + 1):
        fast = fast.next
    
    # Move both until fast reaches end
    while fast:
        fast = fast.next
        slow = slow.next
    
    # Remove node
    slow.next = slow.next.next
    
    return dummy.next
```

**Explanation:**
1. Use two pointers n+1 apart
2. When fast reaches end, slow is before target
3. Remove target node

---

### 65. Reorder List
**Problem:** Reorder list: L0 → Ln → L1 → Ln-1 → L2 → Ln-2...

```python
def reorder_list(head):
    """
    Time: O(n), Space: O(1)
    Find middle, reverse second half, merge
    """
    if not head or not head.next:
        return
    
    # Find middle
    slow = fast = head
    while fast.next and fast.next.next:
        slow = slow.next
        fast = fast.next.next
    
    # Reverse second half
    second = slow.next
    slow.next = None
    
    prev = None
    while second:
        next_temp = second.next
        second.next = prev
        prev = second
        second = next_temp
    
    # Merge two halves
    first, second = head, prev
    while second:
        next_first = first.next
        next_second = second.next
        
        first.next = second
        second.next = next_first
        
        first = next_first
        second = next_second
```

**Explanation:**
1. Find middle of list
2. Reverse second half
3. Merge alternately from both halves

---

### 66. Reverse Linked List II
**Problem:** Reverse nodes from position m to n.

```python
def reverse_between(head, m, n):
    """
    Time: O(n), Space: O(1)
    Reverse portion of list
    """
    if not head or m == n:
        return head
    
    dummy = ListNode(0)
    dummy.next = head
    
    # Move to node before m
    prev = dummy
    for _ in range(m - 1):
        prev = prev.next
    
    # Reverse m to n
    current = prev.next
    for _ in range(n - m):
        next_temp = current.next
        current.next = next_temp.next
        next_temp.next = prev.next
        prev.next = next_temp
    
    return dummy.next
```

**Explanation:**
1. Find node before position m
2. Reverse nodes from m to n
3. Reconnect with rest of list

---

### 67. Intersection of Two Linked Lists
**Problem:** Find node where two lists intersect.

```python
def get_intersection_node(headA, headB):
    """
    Time: O(m + n), Space: O(1)
    Two-pointer approach
    """
    if not headA or not headB:
        return None
    
    pA, pB = headA, headB
    
    while pA != pB:
        pA = pA.next if pA else headB
        pB = pB.next if pB else headA
    
    return pA
```

**Explanation:**
1. Two pointers traverse both lists
2. When reaching end, jump to other list's head
3. They meet at intersection or None

---

### 68. Palindrome Linked List
**Problem:** Check if linked list is palindrome.

```python
def is_palindrome(head):
    """
    Time: O(n), Space: O(1)
    Reverse second half and compare
    """
    if not head or not head.next:
        return True
    
    # Find middle
    slow = fast = head
    while fast.next and fast.next.next:
        slow = slow.next
        fast = fast.next.next
    
    # Reverse second half
    second = slow.next
    slow.next = None
    
    prev = None
    while second:
        next_temp = second.next
        second.next = prev
        prev = second
        second = next_temp
    
    # Compare
    first, second = head, prev
    result = True
    while second:
        if first.val != second.val:
            result = False
            break
        first = first.next
        second = second.next
    
    return result
```

**Explanation:**
1. Find middle using slow/fast pointers
2. Reverse second half
3. Compare both halves

---

### 69. Copy List with Random Pointer
**Problem:** Deep copy list with random pointers.

```python
class Node:
    def __init__(self, val=0, next=None, random=None):
        self.val = val
        self.next = next
        self.random = random

def copy_random_list(head):
    """
    Time: O(n), Space: O(n)
    Hashmap approach
    """
    if not head:
        return None
    
    # First pass: create nodes
    old_to_new = {}
    current = head
    while current:
        old_to_new[current] = Node(current.val)
        current = current.next
    
    # Second pass: connect pointers
    current = head
    while current:
        if current.next:
            old_to_new[current].next = old_to_new[current.next]
        if current.random:
            old_to_new[current].random = old_to_new[current.random]
        current = current.next
    
    return old_to_new[head]

# O(1) space approach
def copy_random_list_v2(head):
    if not head:
        return None
    
    # Interweave nodes
    current = head
    while current:
        new_node = Node(current.val)
        new_node.next = current.next
        current.next = new_node
        current = new_node.next
    
    # Set random pointers
    current = head
    while current:
        if current.random:
            current.next.random = current.random.next
        current = current.next.next
    
    # Separate lists
    old_head = head
    new_head = head.next
    old_curr = old_head
    new_curr = new_head
    
    while old_curr:
        old_curr.next = old_curr.next.next
        new_curr.next = new_curr.next.next if new_curr.next else None
        old_curr = old_curr.next
        new_curr = new_curr.next
    
    return new_head
```

**Explanation:**
1. Hashmap: map old nodes to new nodes
2. O(1) space: interweave nodes, then separate

---

### 70. Add Two Numbers
**Problem:** Add two numbers represented as linked lists.

```python
def add_two_numbers(l1, l2):
    """
    Time: O(max(m, n)), Space: O(max(m, n))
    Add with carry
    """
    dummy = ListNode(0)
    current = dummy
    carry = 0
    
    while l1 or l2 or carry:
        val1 = l1.val if l1 else 0
        val2 = l2.val if l2 else 0
        
        total = val1 + val2 + carry
        carry = total // 10
        
        current.next = ListNode(total % 10)
        current = current.next
        
        l1 = l1.next if l1 else None
        l2 = l2.next if l2 else None
    
    return dummy.next
```

**Explanation:**
1. Add corresponding digits with carry
2. Create new node for each sum
3. Continue until all digits processed

---

### 71. Swap Nodes in Pairs
**Problem:** Swap every two adjacent nodes.

```python
def swap_pairs(head):
    """
    Time: O(n), Space: O(1)
    Iterative swap
    """
    dummy = ListNode(0)
    dummy.next = head
    prev = dummy
    
    while prev.next and prev.next.next:
        first = prev.next
        second = prev.next.next
        
        # Swap
        first.next = second.next
        second.next = first
        prev.next = second
        
        prev = first
    
    return dummy.next
```

**Explanation:**
1. Track three nodes: prev, first, second
2. Swap first and second
3. Move to next pair

---

### 72. Rotate List
**Problem:** Rotate list to the right by k places.

```python
def rotate_right(head, k):
    """
    Time: O(n), Space: O(1)
    Find new tail and break cycle
    """
    if not head or not head.next or k == 0:
        return head
    
    # Find length and make cycle
    length = 1
    tail = head
    while tail.next:
        tail = tail.next
        length += 1
    
    tail.next = head
    
    # Find new tail
    k = k % length
    steps_to_new_tail = length - k
    
    new_tail = head
    for _ in range(steps_to_new_tail - 1):
        new_tail = new_tail.next
    
    new_head = new_tail.next
    new_tail.next = None
    
    return new_head
```

**Explanation:**
1. Connect tail to head (make cycle)
2. Find new tail position
3. Break cycle at new tail

---

### 73. Partition List
**Problem:** Partition list around value x.

```python
def partition(head, x):
    """
    Time: O(n), Space: O(1)
    Two separate lists
    """
    before_head = ListNode(0)
    after_head = ListNode(0)
    
    before = before_head
    after = after_head
    
    while head:
        if head.val < x:
            before.next = head
            before = before.next
        else:
            after.next = head
            after = after.next
        head = head.next
    
    after.next = None
    before.next = after_head.next
    
    return before_head.next
```

**Explanation:**
1. Create two lists: before and after
2. Distribute nodes based on value
3. Connect lists

---

### 74. Remove Linked List Elements
**Problem:** Remove all nodes with given value.

```python
def remove_elements(head, val):
    """
    Time: O(n), Space: O(1)
    Skip nodes with target value
    """
    dummy = ListNode(0)
    dummy.next = head
    
    current = dummy
    while current.next:
        if current.next.val == val:
            current.next = current.next.next
        else:
            current = current.next
    
    return dummy.next
```

**Explanation:**
1. Use dummy head to handle edge cases
2. Skip nodes with target value
3. Continue until end

---

### 75. Odd Even Linked List
**Problem:** Group odd and even positioned nodes.

```python
def odd_even_list(head):
    """
    Time: O(n), Space: O(1)
    Separate odd and even, then connect
    """
    if not head or not head.next:
        return head
    
    odd = head
    even = head.next
    even_head = even
    
    while even and even.next:
        odd.next = even.next
        odd = odd.next
        even.next = odd.next
        even = even.next
    
    odd.next = even_head
    
    return head
```

**Explanation:**
1. Track odd and even lists separately
2. Connect nodes to respective lists
3. Attach even list after odd

---

### 76. Flatten Multilevel Doubly Linked List
**Problem:** Flatten a multilevel doubly linked list.

```python
class Node:
    def __init__(self, val=0, prev=None, next=None, child=None):
        self.val = val
        self.prev = prev
        self.next = next
        self.child = child

def flatten(head):
    """
    Time: O(n), Space: O(n) - recursion
    DFS approach
    """
    if not head:
        return None
    
    def flatten_helper(node):
        current = node
        tail = None
        
        while current:
            next_node = current.next
            
            if current.child:
                child_tail = flatten_helper(current.child)
                
                # Connect current to child
                current.next = current.child
                current.child.prev = current
                current.child = None
                
                # Connect child tail to next
                if next_node:
                    child_tail.next = next_node
                    next_node.prev = child_tail
                
                tail = child_tail
            else:
                tail = current
            
            current = next_node
        
        return tail
    
    flatten_helper(head)
    return head
```

**Explanation:**
1. Use DFS to process each level
2. Connect child lists inline
3. Update prev/next pointers

---

### 77. Sort List
**Problem:** Sort linked list in O(n log n) time.

```python
def sort_list(head):
    """
    Time: O(n log n), Space: O(log n)
    Merge sort
    """
    if not head or not head.next:
        return head
    
    # Find middle
    slow = fast = head
    prev = None
    while fast and fast.next:
        prev = slow
        slow = slow.next
        fast = fast.next.next
    
    prev.next = None
    
    # Sort halves
    left = sort_list(head)
    right = sort_list(slow)
    
    # Merge
    return merge_two_lists(left, right)

def merge_two_lists(l1, l2):
    dummy = ListNode(0)
    current = dummy
    
    while l1 and l2:
        if l1.val <= l2.val:
            current.next = l1
            l1 = l1.next
        else:
            current.next = l2
            l2 = l2.next
        current = current.next
    
    current.next = l1 if l1 else l2
    return dummy.next
```

**Explanation:**
1. Find middle using slow/fast pointers
2. Recursively sort both halves
3. Merge sorted halves

---

### 78. Insertion Sort List
**Problem:** Sort list using insertion sort.

```python
def insertion_sort_list(head):
    """
    Time: O(n²), Space: O(1)
    Insertion sort
    """
    dummy = ListNode(0)
    current = head
    
    while current:
        prev = dummy
        next_temp = current.next
        
        # Find position to insert
        while prev.next and prev.next.val < current.val:
            prev = prev.next
        
        # Insert current
        current.next = prev.next
        prev.next = current
        
        current = next_temp
    
    return dummy.next
```

**Explanation:**
1. Build sorted list from scratch
2. For each node, find correct position
3. Insert node in sorted position

---

### 79. Reverse Nodes in K Group
**Problem:** Reverse nodes in groups of k.

```python
def reverse_k_group(head, k):
    """
    Time: O(n), Space: O(1)
    Reverse in chunks
    """
    def get_length(node):
        length = 0
        while node:
            length += 1
            node = node.next
        return length
    
    def reverse_group(start, k):
        prev = None
        current = start
        
        for _ in range(k):
            next_temp = current.next
            current.next = prev
            prev = current
            current = next_temp
        
        return prev, start, current
    
    dummy = ListNode(0)
    dummy.next = head
    
    length = get_length(head)
    prev_group = dummy
    
    while length >= k:
        start = prev_group.next
        new_head, new_tail, next_start = reverse_group(start, k)
        
        prev_group.next = new_head
        new_tail.next = next_start
        prev_group = new_tail
        
        length -= k
    
    return dummy.next
```

**Explanation:**
1. Check if k nodes available
2. Reverse k nodes
3. Connect with previous and next groups

---

### 80. Merge K Sorted Lists
**Problem:** Merge k sorted linked lists.

```python
import heapq

def merge_k_lists(lists):
    """
    Time: O(n log k), Space: O(k)
    Min heap approach
    """
    heap = []
    
    # Add first node of each list
    for i, lst in enumerate(lists):
        if lst:
            heapq.heappush(heap, (lst.val, i, lst))
    
    dummy = ListNode(0)
    current = dummy
    
    while heap:
        val, i, node = heapq.heappop(heap)
        current.next = node
        current = current.next
        
        if node.next:
            heapq.heappush(heap, (node.next.val, i, node.next))
    
    return dummy.next

# Divide and conquer approach
def merge_k_lists_v2(lists):
    """
    Time: O(n log k), Space: O(log k)
    """
    if not lists:
        return None
    
    def merge_lists(l1, l2):
        dummy = ListNode(0)
        current = dummy
        
        while l1 and l2:
            if l1.val <= l2.val:
                current.next = l1
                l1 = l1.next
            else:
                current.next = l2
                l2 = l2.next
            current = current.next
        
        current.next = l1 if l1 else l2
        return dummy.next
    
    while len(lists) > 1:
        merged = []
        for i in range(0, len(lists), 2):
            l1 = lists[i]
            l2 = lists[i + 1] if i + 1 < len(lists) else None
            merged.append(merge_lists(l1, l2))
        lists = merged
    
    return lists[0]
```

**Explanation:**
1. Heap: always merge smallest available node
2. Divide & conquer: merge pairs repeatedly

---

### 81. Delete Node in Linked List
**Problem:** Delete node given only access to that node.

```python
def delete_node(node):
    """
    Time: O(1), Space: O(1)
    Copy next node's value
    """
    node.val = node.next.val
    node.next = node.next.next
```

**Explanation:**
1. Copy next node's value to current
2. Remove next node
3. Works except for tail node

---

### 82. Remove Duplicates from Sorted List
**Problem:** Remove duplicates from sorted list.

```python
def delete_duplicates(head):
    """
    Time: O(n), Space: O(1)
    Skip duplicates
    """
    current = head
    
    while current and current.next:
        if current.val == current.next.val:
            current.next = current.next.next
        else:
            current = current.next
    
    return head
```

**Explanation:**
1. Compare current with next
2. Skip next if duplicate
3. Otherwise move to next

---

### 83. Remove Duplicates from Sorted List II
**Problem:** Remove all nodes that have duplicates.

```python
def delete_duplicates_ii(head):
    """
    Time: O(n), Space: O(1)
    Remove all occurrences of duplicates
    """
    dummy = ListNode(0)
    dummy.next = head
    prev = dummy
    
    while head:
        # If duplicate sequence
        if head.next and head.val == head.next.val:
            # Skip all duplicates
            while head.next and head.val == head.next.val:
                head = head.next
            prev.next = head.next
        else:
            prev = prev.next
        
        head = head.next
    
    return dummy.next
```

**Explanation:**
1. Use dummy to handle edge cases
2. If duplicate found, skip entire sequence
3. Otherwise, move forward

---

### 84. Middle of Linked List
**Problem:** Find middle node of linked list.

```python
def middle_node(head):
    """
    Time: O(n), Space: O(1)
    Slow and fast pointers
    """
    slow = fast = head
    
    while fast and fast.next:
        slow = slow.next
        fast = fast.next.next
    
    return slow
```

**Explanation:**
1. Slow moves 1 step, fast moves 2
2. When fast reaches end, slow is at middle

---

### 85. Linked List Cycle II
**Problem:** Find node where cycle begins.

```python
def detect_cycle(head):
    """
    Time: O(n), Space: O(1)
    Floyd's algorithm
    """
    if not head:
        return None
    
    # Find meeting point
    slow = fast = head
    has_cycle = False
    
    while fast and fast.next:
        slow = slow.next
        fast = fast.next.next
        
        if slow == fast:
            has_cycle = True
            break
    
    if not has_cycle:
        return None
    
    # Find cycle start
    slow = head
    while slow != fast:
        slow = slow.next
        fast = fast.next
    
    return slow
```

**Explanation:**
1. Find meeting point using slow/fast
2. Reset slow to head
3. Move both 1 step until they meet (cycle start)

---

## 4. STACK & QUEUE (25 Questions)

### 86. Implement Stack using Queue
**Problem:** Implement stack using queue operations.

```python
from collections import deque

class MyStack:
    """
    Push: O(n), Pop/Top: O(1)
    Make push expensive
    """
    def __init__(self):
        self.q = deque()
    
    def push(self, x):
        self.q.append(x)
        # Rotate to make new element front
        for _ in range(len(self.q) - 1):
            self.q.append(self.q.popleft())
    
    def pop(self):
        return self.q.popleft()
    
    def top(self):
        return self.q[0]
    
    def empty(self):
        return len(self.q) == 0
```

**Explanation:**
1. After pushing, rotate queue
2. New element becomes front
3. Pop/top become O(1)

---

### 87. Implement Queue using Stack
**Problem:** Implement queue using stack operations.

```python
class MyQueue:
    """
    Push: O(1), Pop: O(1) amortized
    Use two stacks
    """
    def __init__(self):
        self.input_stack = []
        self.output_stack = []
    
    def push(self, x):
        self.input_stack.append(x)
    
    def pop(self):
        self._transfer()
        return self.output_stack.pop()
    
    def peek(self):
        self._transfer()
        return self.output_stack[-1]
    
    def empty(self):
        return not self.input_stack and not self.output_stack
    
    def _transfer(self):
        if not self.output_stack:
            while self.input_stack:
                self.output_stack.append(self.input_stack.pop())
```

**Explanation:**
1. Input stack for push operations
2. Output stack for pop operations
3. Transfer when output empty

---

### 88. Min Stack
**Problem:** Stack with O(1) getMin operation.

```python
class MinStack:
    """
    All operations O(1)
    Track minimum with each element
    """
    def __init__(self):
        self.stack = []  # (value, min_so_far)
    
    def push(self, val):
        if not self.stack:
            self.stack.append((val, val))
        else:
            self.stack.append((val, min(val, self.stack[-1][1])))
    
    def pop(self):
        self.stack.pop()
    
    def top(self):
        return self.stack[-1][0]
    
    def getMin(self):
        return self.stack[-1][1]
```

**Explanation:**
1. Store value and minimum together
2. Update minimum on each push
3. All operations O(1)

---

### 89. Evaluate Reverse Polish Notation
**Problem:** Evaluate RPN expression.

```python
def eval_rpn(tokens):
    """
    Time: O(n), Space: O(n)
    Stack for operands
    """
    stack = []
    operators = {'+', '-', '*', '/'}
    
    for token in tokens:
        if token in operators:
            b = stack.pop()
            a = stack.pop()
            
            if token == '+':
                stack.append(a + b)
            elif token == '-':
                stack.append(a - b)
            elif token == '*':
                stack.append(a * b)
            else:  # '/'
                stack.append(int(a / b))  # Truncate towards zero
        else:
            stack.append(int(token))
    
    return stack[0]

# Example
print(eval_rpn(["2", "1", "+", "3", "*"]))  # 9
```

**Explanation:**
1. Push numbers to stack
2. On operator, pop two operands
3. Push result back

---

### 90. Daily Temperatures
**Problem:** Days until warmer temperature.

```python
def daily_temperatures(temperatures):
    """
    Time: O(n), Space: O(n)
    Monotonic decreasing stack
    """
    n = len(temperatures)
    result = [0] * n
    stack = []  # Indices
    
    for i, temp in enumerate(temperatures):
        while stack and temperatures[stack[-1]] < temp:
            prev_idx = stack.pop()
            result[prev_idx] = i - prev_idx
        stack.append(i)
    
    return result

# Example
print(daily_temperatures([73, 74, 75, 71, 69, 72, 76, 73]))
# [1, 1, 4, 2, 1, 1, 0, 0]
```

**Explanation:**
1. Maintain stack of indices
2. Pop when warmer day found
3. Record distance between days

---

### 91. Next Greater Element I
**Problem:** Find next greater element for subset.

```python
def next_greater_element(nums1, nums2):
    """
    Time: O(m + n), Space: O(n)
    Stack + hashmap
    """
    next_greater = {}
    stack = []
    
    # Build next greater map for nums2
    for num in nums2:
        while stack and stack[-1] < num:
            next_greater[stack.pop()] = num
        stack.append(num)
    
    # Build result for nums1
    return [next_greater.get(num, -1) for num in nums1]

# Example
print(next_greater_element([4, 1, 2], [1, 3, 4, 2]))  # [-1, 3, -1]
```

**Explanation:**
1. Build map of next greater for nums2
2. Use stack to find next greater
3. Look up for nums1 elements

---

### 92. Next Greater Element II
**Problem:** Find next greater in circular array.

```python
def next_greater_elements(nums):
    """
    Time: O(n), Space: O(n)
    Circular array with stack
    """
    n = len(nums)
    result = [-1] * n
    stack = []
    
    # Process array twice for circular
    for i in range(2 * n):
        while stack and nums[stack[-1]] < nums[i % n]:
            result[stack.pop()] = nums[i % n]
        
        if i < n:
            stack.append(i)
    
    return result

# Example
print(next_greater_elements([1, 2, 1]))  # [2, -1, 2]
```

**Explanation:**
1. Process array twice for circular
2. Use modulo for wraparound
3. Only track first n indices

---

### 93. Largest Rectangle in Histogram
**Problem:** Find largest rectangle in histogram.

```python
def largest_rectangle_area(heights):
    """
    Time: O(n), Space: O(n)
    Stack for increasing heights
    """
    stack = []
    max_area = 0
    heights.append(0)  # Sentinel
    
    for i, h in enumerate(heights):
        while stack and heights[stack[-1]] > h:
            height_idx = stack.pop()
            height = heights[height_idx]
            width = i if not stack else i - stack[-1] - 1
            max_area = max(max_area, height * width)
        
        stack.append(i)
    
    heights.pop()  # Remove sentinel
    return max_area

# Example
print(largest_rectangle_area([2, 1, 5, 6, 2, 3]))  # 10
```

**Explanation:**
1. Maintain stack of increasing heights
2. On decrease, calculate areas
3. Width determined by stack positions

---

### 94. Trapping Rain Water
**Problem:** Calculate trapped rain water.

```python
def trap(height):
    """
    Time: O(n), Space: O(1)
    Two-pointer approach
    """
    if not height:
        return 0
    
    left, right = 0, len(height) - 1
    left_max = right_max = 0
    water = 0
    
    while left < right:
        if height[left] < height[right]:
            if height[left] >= left_max:
                left_max = height[left]
            else:
                water += left_max - height[left]
            left += 1
        else:
            if height[right] >= right_max:
                right_max = height[right]
            else:
                water += right_max - height[right]
            right -= 1
    
    return water

# Stack approach
def trap_stack(height):
    """
    Time: O(n), Space: O(n)
    """
    stack = []
    water = 0
    
    for i, h in enumerate(height):
        while stack and height[stack[-1]] < h:
            bottom = stack.pop()
            
            if not stack:
                break
            
            distance = i - stack[-1] - 1
            bounded_height = min(height[i], height[stack[-1]]) - height[bottom]
            water += distance * bounded_height
        
        stack.append(i)
    
    return water

# Example
print(trap([0, 1, 0, 2, 1, 0, 1, 3, 2, 1, 2, 1]))  # 6
```

**Explanation:**
1. Two-pointer: track max heights from both sides
2. Stack: calculate water by layers

---

### 95. Basic Calculator
**Problem:** Evaluate expression with +, -, (, ).

```python
def calculate(s):
    """
    Time: O(n), Space: O(n)
    Stack for handling parentheses
    """
    stack = []
    num = 0
    sign = 1
    result = 0
    
    for char in s:
        if char.isdigit():
            num = num * 10 + int(char)
        elif char == '+':
            result += sign * num
            num = 0
            sign = 1
        elif char == '-':
            result += sign * num
            num = 0
            sign = -1
        elif char == '(':
            stack.append(result)
            stack.append(sign)
            result = 0
            sign = 1
        elif char == ')':
            result += sign * num
            num = 0
            result *= stack.pop()  # sign before (
            result += stack.pop()  # result before (
    
    result += sign * num
    return result

# Example
print(calculate("(1+(4+5+2)-3)+(6+8)"))  # 23
```

**Explanation:**
1. Track current number, sign, result
2. Stack for parentheses context
3. Process operators and parentheses

---

### 96. Basic Calculator II
**Problem:** Evaluate expression with +, -, *, /.

```python
def calculate_ii(s):
    """
    Time: O(n), Space: O(n)
    Stack for handling precedence
    """
    stack = []
    num = 0
    operation = '+'
    
    for i, char in enumerate(s):
        if char.isdigit():
            num = num * 10 + int(char)
        
        if char in '+-*/' or i == len(s) - 1:
            if char != ' ' or i == len(s) - 1:
                if operation == '+':
                    stack.append(num)
                elif operation == '-':
                    stack.append(-num)
                elif operation == '*':
                    stack.append(stack.pop() * num)
                elif operation == '/':
                    stack.append(int(stack.pop() / num))
                
                if i < len(s) - 1:
                    operation = char
                    num = 0
    
    return sum(stack)

# Example
print(calculate_ii("3+2*2"))  # 7
```

**Explanation:**
1. Process operators left to right
2. Apply */  immediately
3. Stack +/- for final sum

---

### 97. Sliding Window Maximum
**Problem:** Maximum in each sliding window.
**(Already covered in Arrays section)**

---

### 98. Design Circular Queue
**Problem:** Implement circular queue.

```python
class MyCircularQueue:
    """
    Fixed-size circular queue
    """
    def __init__(self, k):
        self.queue = [0] * k
        self.size = k
        self.front = 0
        self.rear = -1
        self.count = 0
    
    def enQueue(self, value):
        if self.isFull():
            return False
        
        self.rear = (self.rear + 1) % self.size
        self.queue[self.rear] = value
        self.count += 1
        return True
    
    def deQueue(self):
        if self.isEmpty():
            return False
        
        self.front = (self.front + 1) % self.size
        self.count -= 1
        return True
    
    def Front(self):
        return -1 if self.isEmpty() else self.queue[self.front]
    
    def Rear(self):
        return -1 if self.isEmpty() else self.queue[self.rear]
    
    def isEmpty(self):
        return self.count == 0
    
    def isFull(self):
        return self.count == self.size
```

**Explanation:**
1. Use array with front/rear pointers
2. Use modulo for circular behavior
3. Track count for empty/full checks

---

### 99. Design Circular Deque
**Problem:** Implement circular double-ended queue.

```python
class MyCircularDeque:
    """
    Circular deque with front/rear operations
    """
    def __init__(self, k):
        self.queue = [0] * k
        self.size = k
        self.front = 0
        self.rear = 0
        self.count = 0
    
    def insertFront(self, value):
        if self.isFull():
            return False
        
        if self.count != 0:
            self.front = (self.front - 1) % self.size
        self.queue[self.front] = value
        self.count += 1
        return True
    
    def insertLast(self, value):
        if self.isFull():
            return False
        
        if self.count != 0:
            self.rear = (self.rear + 1) % self.size
        self.queue[self.rear] = value
        self.count += 1
        return True
    
    def deleteFront(self):
        if self.isEmpty():
            return False
        
        self.front = (self.front + 1) % self.size
        self.count -= 1
        return True
    
    def deleteLast(self):
        if self.isEmpty():
            return False
        
        self.rear = (self.rear - 1) % self.size
        self.count -= 1
        return True
    
    def getFront(self):
        return -1 if self.isEmpty() else self.queue[self.front]
    
    def getRear(self):
        return -1 if self.isEmpty() else self.queue[self.rear]
    
    def isEmpty(self):
        return self.count == 0
    
    def isFull(self):
        return self.count == self.size
```

**Explanation:**
1. Support operations at both ends
2. Use modulo for wraparound
3. Adjust front/rear based on operation

---

### 100. Implement Stack
**Problem:** Basic stack implementation.

```python
class Stack:
    """
    Simple stack using list
    """
    def __init__(self):
        self.items = []
    
    def push(self, item):
        self.items.append(item)
    
    def pop(self):
        if not self.is_empty():
            return self.items.pop()
        raise IndexError("Pop from empty stack")
    
    def peek(self):
        if not self.is_empty():
            return self.items[-1]
        raise IndexError("Peek from empty stack")
    
    def is_empty(self):
        return len(self.items) == 0
    
    def size(self):
        return len(self.items)
```

---

### 101. Valid Parentheses
**(Already covered in Strings section)**

---

### 102. Simplify Path
**(Already covered in Strings section)**

---

### 103. Remove K Digits
**Problem:** Remove k digits to get smallest number.

```python
def remove_kdigits(num, k):
    """
    Time: O(n), Space: O(n)
    Monotonic increasing stack
    """
    stack = []
    
    for digit in num:
        while k > 0 and stack and stack[-1] > digit:
            stack.pop()
            k -= 1
        stack.append(digit)
    
    # Remove remaining k digits from end
    stack = stack[:-k] if k > 0 else stack
    
    # Remove leading zeros
    result = ''.join(stack).lstrip('0')
    
    return result if result else '0'

# Example
print(remove_kdigits("1432219", 3))  # "1219"
```

**Explanation:**
1. Maintain increasing stack
2. Remove larger digits before smaller
3. Handle remaining removals and leading zeros

---

### 104. Decode String
**(Already covered in Strings section)**

---

### 105. Asteroid Collision
**Problem:** Simulate asteroid collisions.

```python
def asteroid_collision(asteroids):
    """
    Time: O(n), Space: O(n)
    Stack simulation
    """
    stack = []
    
    for asteroid in asteroids:
        while stack and asteroid < 0 < stack[-1]:
            if stack[-1] < -asteroid:
                stack.pop()
                continue
            elif stack[-1] == -asteroid:
                stack.pop()
            break
        else:
            stack.append(asteroid)
    
    return stack

# Example
print(asteroid_collision([5, 10, -5]))  # [5, 10]
print(asteroid_collision([8, -8]))  # []
```

**Explanation:**
1. Positive asteroids go right, negative left
2. Collision when positive meets negative
3. Larger survives, equal both destroyed

---

### 106. Online Stock Span
**Problem:** Calculate stock price spans.

```python
class StockSpanner:
    """
    Monotonic decreasing stack
    """
    def __init__(self):
        self.stack = []  # (price, span)
    
    def next(self, price):
        span = 1
        
        while self.stack and self.stack[-1][0] <= price:
            span += self.stack.pop()[1]
        
        self.stack.append((price, span))
        return span

# Example
spanner = StockSpanner()
print(spanner.next(100))  # 1
print(spanner.next(80))   # 1
print(spanner.next(60))   # 1
print(spanner.next(70))   # 2
print(spanner.next(60))   # 1
print(spanner.next(75))   # 4
print(spanner.next(85))   # 6
```

**Explanation:**
1. Stack stores (price, span)
2. Pop prices ≤ current price
3. Sum their spans for current span

---

### 107. Implement Queue
**Problem:** Basic queue implementation.

```python
class Queue:
    """
    Simple queue using list
    """
    def __init__(self):
        self.items = []
    
    def enqueue(self, item):
        self.items.append(item)
    
    def dequeue(self):
        if not self.is_empty():
            return self.items.pop(0)
        raise IndexError("Dequeue from empty queue")
    
    def front(self):
        if not self.is_empty():
            return self.items[0]
        raise IndexError("Front from empty queue")
    
    def is_empty(self):
        return len(self.items) == 0
    
    def size(self):
        return len(self.items)

# Better implementation using deque
from collections import deque

class QueueOptimized:
    def __init__(self):
        self.items = deque()
    
    def enqueue(self, item):
        self.items.append(item)
    
    def dequeue(self):
        if not self.is_empty():
            return self.items.popleft()
        raise IndexError("Dequeue from empty queue")
    
    def front(self):
        if not self.is_empty():
            return self.items[0]
        raise IndexError("Front from empty queue")
    
    def is_empty(self):
        return len(self.items) == 0
    
    def size(self):
        return len(self.items)
```

---

### 108. Moving Average from Data Stream
**Problem:** Calculate moving average of stream.

```python
from collections import deque

class MovingAverage:
    """
    Time: O(1) per operation
    Space: O(size)
    """
    def __init__(self, size):
        self.size = size
        self.queue = deque()
        self.sum = 0
    
    def next(self, val):
        self.queue.append(val)
        self.sum += val
        
        if len(self.queue) > self.size:
            self.sum -= self.queue.popleft()
        
        return self.sum / len(self.queue)

# Example
ma = MovingAverage(3)
print(ma.next(1))   # 1.0
print(ma.next(10))  # 5.5
print(ma.next(3))   # 4.666...
print(ma.next(5))   # 6.0
```

**Explanation:**
1. Maintain queue of size elements
2. Track sum for quick average
3. Remove oldest when size exceeded

---

### 109. Baseball Game
**Problem:** Calculate score based on operations.

```python
def cal_points(ops):
    """
    Time: O(n), Space: O(n)
    Stack for score tracking
    """
    stack = []
    
    for op in ops:
        if op == '+':
            stack.append(stack[-1] + stack[-2])
        elif op == 'D':
            stack.append(2 * stack[-1])
        elif op == 'C':
            stack.pop()
        else:
            stack.append(int(op))
    
    return sum(stack)

# Example
print(cal_points(["5", "2", "C", "D", "+"]))  # 30
```

**Explanation:**
1. Maintain stack of scores
2. Apply operations: +, D, C, or number
3. Sum final stack

---

### 110. Remove Adjacent Duplicates
**Problem:** Remove adjacent duplicate characters.

```python
def remove_duplicates(s):
    """
    Time: O(n), Space: O(n)
    Stack for tracking
    """
    stack = []
    
    for char in s:
        if stack and stack[-1] == char:
            stack.pop()
        else:
            stack.append(char)
    
    return ''.join(stack)

# With k duplicates
def remove_duplicates_k(s, k):
    """
    Remove k adjacent duplicates
    """
    stack = []  # (char, count)
    
    for char in s:
        if stack and stack[-1][0] == char:
            stack[-1] = (char, stack[-1][1] + 1)
            if stack[-1][1] == k:
                stack.pop()
        else:
            stack.append((char, 1))
    
    return ''.join(char * count for char, count in stack)

# Example
print(remove_duplicates("abbaca"))  # "ca"
print(remove_duplicates_k("deeedbbcccbdaa", 3))  # "aa"
```

**Explanation:**
1. Stack tracks characters
2. Remove when duplicate found
3. For k duplicates, count occurrences

---

## Summary

This comprehensive guide covers:
- **110 DSA problems** across 4 major categories
- **Multiple approaches** for many problems
- **Time and space complexity** analysis
- **Clear explanations** of each solution
- **Working Python code** with examples

### Key Patterns:
1. **Arrays**: Two pointers, sliding window, prefix sums
2. **Strings**: Sliding window, two pointers, DP
3. **Linked Lists**: Two pointers, fast/slow, dummy nodes
4. **Stack/Queue**: Monotonic stack, parentheses matching

### Practice Tips:
- Start with easy problems in each category
- Understand the pattern before memorizing code
- Practice drawing diagrams for complex problems
- Time yourself to improve speed
- Review and revise regularly

---
# DSA Questions - Binary Trees & Heaps (Python Solutions)

I'll provide detailed solutions for all questions with explanations.

---

## 5. Binary Trees (35 Questions)

### 1. Maximum Depth of Binary Tree

```python
class TreeNode:
    def __init__(self, val=0, left=None, right=None):
        self.val = val
        self.left = left
        self.right = right

def maxDepth(root):
    """
    Find maximum depth of binary tree
    Time: O(n), Space: O(h) where h is height
    """
    # Base case: empty tree has depth 0
    if not root:
        return 0
    
    # Recursive case: 1 + max of left and right subtree depths
    left_depth = maxDepth(root.left)
    right_depth = maxDepth(root.right)
    
    return 1 + max(left_depth, right_depth)

# Iterative approach using BFS
def maxDepth_iterative(root):
    if not root:
        return 0
    
    from collections import deque
    queue = deque([root])
    depth = 0
    
    while queue:
        depth += 1
        # Process all nodes at current level
        for _ in range(len(queue)):
            node = queue.popleft()
            if node.left:
                queue.append(node.left)
            if node.right:
                queue.append(node.right)
    
    return depth
```

---

### 2. Same Tree

```python
def isSameTree(p, q):
    """
    Check if two trees are identical
    Time: O(n), Space: O(h)
    """
    # Both empty - same
    if not p and not q:
        return True
    
    # One empty, one not - different
    if not p or not q:
        return False
    
    # Values different - different
    if p.val != q.val:
        return False
    
    # Check both subtrees recursively
    return isSameTree(p.left, q.left) and isSameTree(p.right, q.right)
```

---

### 3. Invert Binary Tree

```python
def invertTree(root):
    """
    Mirror a binary tree
    Time: O(n), Space: O(h)
    """
    # Base case
    if not root:
        return None
    
    # Swap left and right children
    root.left, root.right = root.right, root.left
    
    # Recursively invert subtrees
    invertTree(root.left)
    invertTree(root.right)
    
    return root

# Iterative approach
def invertTree_iterative(root):
    if not root:
        return None
    
    from collections import deque
    queue = deque([root])
    
    while queue:
        node = queue.popleft()
        # Swap children
        node.left, node.right = node.right, node.left
        
        if node.left:
            queue.append(node.left)
        if node.right:
            queue.append(node.right)
    
    return root
```

---

### 4. Binary Tree Level Order Traversal

```python
def levelOrder(root):
    """
    Return level-by-level traversal
    Time: O(n), Space: O(n)
    """
    if not root:
        return []
    
    from collections import deque
    result = []
    queue = deque([root])
    
    while queue:
        level = []
        level_size = len(queue)
        
        # Process all nodes at current level
        for _ in range(level_size):
            node = queue.popleft()
            level.append(node.val)
            
            if node.left:
                queue.append(node.left)
            if node.right:
                queue.append(node.right)
        
        result.append(level)
    
    return result
```

---

### 5. Binary Tree Zigzag Traversal

```python
def zigzagLevelOrder(root):
    """
    Zigzag level order traversal
    Time: O(n), Space: O(n)
    """
    if not root:
        return []
    
    from collections import deque
    result = []
    queue = deque([root])
    left_to_right = True
    
    while queue:
        level = []
        level_size = len(queue)
        
        for _ in range(level_size):
            node = queue.popleft()
            level.append(node.val)
            
            if node.left:
                queue.append(node.left)
            if node.right:
                queue.append(node.right)
        
        # Reverse every other level
        if not left_to_right:
            level.reverse()
        
        result.append(level)
        left_to_right = not left_to_right
    
    return result
```

---

### 6. Construct Binary Tree from Preorder and Inorder

```python
def buildTree(preorder, inorder):
    """
    Construct tree from preorder and inorder traversals
    Time: O(n), Space: O(n)
    """
    if not preorder or not inorder:
        return None
    
    # First element in preorder is root
    root_val = preorder[0]
    root = TreeNode(root_val)
    
    # Find root position in inorder
    mid = inorder.index(root_val)
    
    # Elements left of mid are in left subtree
    # Elements right of mid are in right subtree
    root.left = buildTree(preorder[1:mid+1], inorder[:mid])
    root.right = buildTree(preorder[mid+1:], inorder[mid+1:])
    
    return root

# Optimized version with index mapping
def buildTree_optimized(preorder, inorder):
    inorder_map = {val: idx for idx, val in enumerate(inorder)}
    pre_idx = [0]  # Use list to maintain reference
    
    def helper(left, right):
        if left > right:
            return None
        
        root_val = preorder[pre_idx[0]]
        root = TreeNode(root_val)
        pre_idx[0] += 1
        
        mid = inorder_map[root_val]
        root.left = helper(left, mid - 1)
        root.right = helper(mid + 1, right)
        
        return root
    
    return helper(0, len(inorder) - 1)
```

---

### 7. Serialize and Deserialize Binary Tree

```python
class Codec:
    """
    Serialize and deserialize binary tree
    """
    def serialize(self, root):
        """
        Encodes a tree to a single string
        Time: O(n), Space: O(n)
        """
        if not root:
            return "null"
        
        # Use preorder traversal
        left = self.serialize(root.left)
        right = self.serialize(root.right)
        
        return f"{root.val},{left},{right}"
    
    def deserialize(self, data):
        """
        Decodes string to tree
        Time: O(n), Space: O(n)
        """
        def helper(values):
            val = next(values)
            
            if val == "null":
                return None
            
            node = TreeNode(int(val))
            node.left = helper(values)
            node.right = helper(values)
            
            return node
        
        values = iter(data.split(','))
        return helper(values)

# Alternative BFS approach
class Codec_BFS:
    def serialize(self, root):
        if not root:
            return ""
        
        from collections import deque
        queue = deque([root])
        result = []
        
        while queue:
            node = queue.popleft()
            if node:
                result.append(str(node.val))
                queue.append(node.left)
                queue.append(node.right)
            else:
                result.append("null")
        
        return ",".join(result)
    
    def deserialize(self, data):
        if not data:
            return None
        
        from collections import deque
        values = data.split(',')
        root = TreeNode(int(values[0]))
        queue = deque([root])
        i = 1
        
        while queue:
            node = queue.popleft()
            
            if values[i] != "null":
                node.left = TreeNode(int(values[i]))
                queue.append(node.left)
            i += 1
            
            if values[i] != "null":
                node.right = TreeNode(int(values[i]))
                queue.append(node.right)
            i += 1
        
        return root
```

---

### 8. Lowest Common Ancestor

```python
def lowestCommonAncestor(root, p, q):
    """
    Find LCA of two nodes
    Time: O(n), Space: O(h)
    """
    # Base case: reached null or found one of the nodes
    if not root or root == p or root == q:
        return root
    
    # Search in left and right subtrees
    left = lowestCommonAncestor(root.left, p, q)
    right = lowestCommonAncestor(root.right, p, q)
    
    # If both return non-null, current node is LCA
    if left and right:
        return root
    
    # Otherwise, return whichever is non-null
    return left if left else right

# For BST (optimized)
def lowestCommonAncestor_BST(root, p, q):
    """
    LCA for Binary Search Tree
    Time: O(h), Space: O(1)
    """
    while root:
        # Both nodes in left subtree
        if p.val < root.val and q.val < root.val:
            root = root.left
        # Both nodes in right subtree
        elif p.val > root.val and q.val > root.val:
            root = root.right
        # Split point found
        else:
            return root
    
    return None
```

---

### 9. Diameter of Binary Tree

```python
def diameterOfBinaryTree(root):
    """
    Find diameter (longest path between any two nodes)
    Time: O(n), Space: O(h)
    """
    diameter = [0]  # Use list to maintain reference
    
    def height(node):
        if not node:
            return 0
        
        left_height = height(node.left)
        right_height = height(node.right)
        
        # Update diameter (path through current node)
        diameter[0] = max(diameter[0], left_height + right_height)
        
        # Return height of current node
        return 1 + max(left_height, right_height)
    
    height(root)
    return diameter[0]
```

---

### 10. Balanced Binary Tree

```python
def isBalanced(root):
    """
    Check if tree is height-balanced
    Time: O(n), Space: O(h)
    """
    def check_height(node):
        # Returns height if balanced, -1 if unbalanced
        if not node:
            return 0
        
        left_height = check_height(node.left)
        if left_height == -1:
            return -1
        
        right_height = check_height(node.right)
        if right_height == -1:
            return -1
        
        # Check if current node is balanced
        if abs(left_height - right_height) > 1:
            return -1
        
        return 1 + max(left_height, right_height)
    
    return check_height(root) != -1
```

---

### 11. Path Sum

```python
def hasPathSum(root, targetSum):
    """
    Check if root-to-leaf path sum equals target
    Time: O(n), Space: O(h)
    """
    if not root:
        return False
    
    # Leaf node check
    if not root.left and not root.right:
        return root.val == targetSum
    
    # Check subtrees with reduced sum
    remaining = targetSum - root.val
    return hasPathSum(root.left, remaining) or hasPathSum(root.right, remaining)

# Iterative approach
def hasPathSum_iterative(root, targetSum):
    if not root:
        return False
    
    from collections import deque
    queue = deque([(root, root.val)])
    
    while queue:
        node, current_sum = queue.popleft()
        
        # Leaf node
        if not node.left and not node.right:
            if current_sum == targetSum:
                return True
        
        if node.left:
            queue.append((node.left, current_sum + node.left.val))
        if node.right:
            queue.append((node.right, current_sum + node.right.val))
    
    return False
```

---

### 12. Path Sum II

```python
def pathSum(root, targetSum):
    """
    Find all root-to-leaf paths with given sum
    Time: O(n²), Space: O(h)
    """
    result = []
    
    def dfs(node, remaining, path):
        if not node:
            return
        
        # Add current node to path
        path.append(node.val)
        
        # Leaf node with matching sum
        if not node.left and not node.right and remaining == node.val:
            result.append(path[:])  # Make a copy
        
        # Explore subtrees
        dfs(node.left, remaining - node.val, path)
        dfs(node.right, remaining - node.val, path)
        
        # Backtrack
        path.pop()
    
    dfs(root, targetSum, [])
    return result
```

---

### 13. Maximum Path Sum

```python
def maxPathSum(root):
    """
    Find maximum path sum (any node to any node)
    Time: O(n), Space: O(h)
    """
    max_sum = [float('-inf')]
    
    def max_gain(node):
        if not node:
            return 0
        
        # Get max sum from left and right (ignore negative)
        left_gain = max(max_gain(node.left), 0)
        right_gain = max(max_gain(node.right), 0)
        
        # Path sum through current node
        path_sum = node.val + left_gain + right_gain
        max_sum[0] = max(max_sum[0], path_sum)
        
        # Return max gain continuing from this node
        return node.val + max(left_gain, right_gain)
    
    max_gain(root)
    return max_sum[0]
```

---

### 14. Sum Root to Leaf Numbers

```python
def sumNumbers(root):
    """
    Sum all numbers formed by root-to-leaf paths
    Time: O(n), Space: O(h)
    """
    def dfs(node, current_num):
        if not node:
            return 0
        
        current_num = current_num * 10 + node.val
        
        # Leaf node
        if not node.left and not node.right:
            return current_num
        
        # Sum from both subtrees
        return dfs(node.left, current_num) + dfs(node.right, current_num)
    
    return dfs(root, 0)

# Iterative approach
def sumNumbers_iterative(root):
    if not root:
        return 0
    
    from collections import deque
    total = 0
    queue = deque([(root, root.val)])
    
    while queue:
        node, current_num = queue.popleft()
        
        if not node.left and not node.right:
            total += current_num
        
        if node.left:
            queue.append((node.left, current_num * 10 + node.left.val))
        if node.right:
            queue.append((node.right, current_num * 10 + node.right.val))
    
    return total
```

---

### 15. Flatten Binary Tree to Linked List

```python
def flatten(root):
    """
    Flatten tree to linked list in-place (preorder)
    Time: O(n), Space: O(h)
    """
    if not root:
        return
    
    # Flatten subtrees
    flatten(root.left)
    flatten(root.right)
    
    # Store right subtree
    right_subtree = root.right
    
    # Move left subtree to right
    root.right = root.left
    root.left = None
    
    # Find end of new right subtree
    current = root
    while current.right:
        current = current.right
    
    # Attach original right subtree
    current.right = right_subtree

# Iterative approach (Morris-like)
def flatten_iterative(root):
    current = root
    
    while current:
        if current.left:
            # Find rightmost node in left subtree
            predecessor = current.left
            while predecessor.right:
                predecessor = predecessor.right
            
            # Rewire connections
            predecessor.right = current.right
            current.right = current.left
            current.left = None
        
        current = current.right
```

---

### 16. Populate Next Right Pointer

```python
class Node:
    def __init__(self, val=0, left=None, right=None, next=None):
        self.val = val
        self.left = left
        self.right = right
        self.next = next

def connect(root):
    """
    Populate next right pointers in perfect binary tree
    Time: O(n), Space: O(1)
    """
    if not root:
        return root
    
    # Start with leftmost node
    leftmost = root
    
    while leftmost.left:
        # Iterate through current level
        head = leftmost
        
        while head:
            # Connect left child to right child
            head.left.next = head.right
            
            # Connect right child to next left child
            if head.next:
                head.right.next = head.next.left
            
            head = head.next
        
        # Move to next level
        leftmost = leftmost.left
    
    return root

# For any binary tree (not just perfect)
def connect_any_tree(root):
    """
    Populate next pointers for any binary tree
    Time: O(n), Space: O(1)
    """
    if not root:
        return root
    
    leftmost = root
    
    while leftmost:
        current = leftmost
        # Reset for next level
        leftmost = None
        prev = None
        
        while current:
            # Process left child
            if current.left:
                if prev:
                    prev.next = current.left
                else:
                    leftmost = current.left
                prev = current.left
            
            # Process right child
            if current.right:
                if prev:
                    prev.next = current.right
                else:
                    leftmost = current.right
                prev = current.right
            
            current = current.next
    
    return root
```

---

### 17. Binary Tree Right Side View

```python
def rightSideView(root):
    """
    Return values visible from right side
    Time: O(n), Space: O(h)
    """
    if not root:
        return []
    
    result = []
    
    def dfs(node, level):
        if not node:
            return
        
        # First node we see at this level from right
        if level == len(result):
            result.append(node.val)
        
        # Visit right first, then left
        dfs(node.right, level + 1)
        dfs(node.left, level + 1)
    
    dfs(root, 0)
    return result

# BFS approach
def rightSideView_bfs(root):
    if not root:
        return []
    
    from collections import deque
    result = []
    queue = deque([root])
    
    while queue:
        level_size = len(queue)
        
        for i in range(level_size):
            node = queue.popleft()
            
            # Last node in level
            if i == level_size - 1:
                result.append(node.val)
            
            if node.left:
                queue.append(node.left)
            if node.right:
                queue.append(node.right)
    
    return result
```

---

### 18. Symmetric Tree

```python
def isSymmetric(root):
    """
    Check if tree is mirror of itself
    Time: O(n), Space: O(h)
    """
    def is_mirror(left, right):
        # Both null
        if not left and not right:
            return True
        
        # One null
        if not left or not right:
            return False
        
        # Check values and recursive mirror
        return (left.val == right.val and 
                is_mirror(left.left, right.right) and 
                is_mirror(left.right, right.left))
    
    if not root:
        return True
    
    return is_mirror(root.left, root.right)

# Iterative approach
def isSymmetric_iterative(root):
    if not root:
        return True
    
    from collections import deque
    queue = deque([(root.left, root.right)])
    
    while queue:
        left, right = queue.popleft()
        
        if not left and not right:
            continue
        if not left or not right:
            return False
        if left.val != right.val:
            return False
        
        queue.append((left.left, right.right))
        queue.append((left.right, right.left))
    
    return True
```

---

### 19. Subtree of Another Tree

```python
def isSubtree(root, subRoot):
    """
    Check if subRoot is subtree of root
    Time: O(m*n), Space: O(h)
    """
    if not root:
        return False
    
    # Check if trees match at current node
    if isSameTree(root, subRoot):
        return True
    
    # Check in left or right subtree
    return isSubtree(root.left, subRoot) or isSubtree(root.right, subRoot)

def isSameTree(p, q):
    if not p and not q:
        return True
    if not p or not q:
        return False
    return (p.val == q.val and 
            isSameTree(p.left, q.left) and 
            isSameTree(p.right, q.right))
```

---

### 20. Kth Smallest Element in BST

```python
def kthSmallest(root, k):
    """
    Find kth smallest element in BST
    Time: O(h+k), Space: O(h)
    """
    # Inorder traversal gives sorted order
    stack = []
    current = root
    
    while True:
        # Go to leftmost
        while current:
            stack.append(current)
            current = current.left
        
        # Process node
        current = stack.pop()
        k -= 1
        
        if k == 0:
            return current.val
        
        # Move to right
        current = current.right

# Recursive approach
def kthSmallest_recursive(root, k):
    result = []
    
    def inorder(node):
        if not node or len(result) >= k:
            return
        
        inorder(node.left)
        result.append(node.val)
        inorder(node.right)
    
    inorder(root)
    return result[k-1]
```

---

### 21. Validate Binary Search Tree

```python
def isValidBST(root):
    """
    Check if tree is valid BST
    Time: O(n), Space: O(h)
    """
    def validate(node, min_val, max_val):
        if not node:
            return True
        
        # Check current node's value
        if node.val <= min_val or node.val >= max_val:
            return False
        
        # Check subtrees with updated bounds
        return (validate(node.left, min_val, node.val) and 
                validate(node.right, node.val, max_val))
    
    return validate(root, float('-inf'), float('inf'))

# Inorder traversal approach
def isValidBST_inorder(root):
    prev = [float('-inf')]
    
    def inorder(node):
        if not node:
            return True
        
        # Check left subtree
        if not inorder(node.left):
            return False
        
        # Check current value
        if node.val <= prev[0]:
            return False
        prev[0] = node.val
        
        # Check right subtree
        return inorder(node.right)
    
    return inorder(root)
```

---

### 22. Convert Sorted Array to BST

```python
def sortedArrayToBST(nums):
    """
    Convert sorted array to height-balanced BST
    Time: O(n), Space: O(log n)
    """
    def convert(left, right):
        if left > right:
            return None
        
        # Choose middle as root for balance
        mid = (left + right) // 2
        node = TreeNode(nums[mid])
        
        # Recursively build subtrees
        node.left = convert(left, mid - 1)
        node.right = convert(mid + 1, right)
        
        return node
    
    return convert(0, len(nums) - 1)
```

---

### 23. Convert BST to Doubly Linked List

```python
def treeToDoublyList(root):
    """
    Convert BST to circular doubly linked list (in-place)
    Time: O(n), Space: O(h)
    """
    if not root:
        return None
    
    # Track first and last nodes
    first = None
    last = None
    
    def inorder(node):
        nonlocal first, last
        
        if not node:
            return
        
        # Process left subtree
        inorder(node.left)
        
        # Process current node
        if last:
            # Link previous node with current
            last.right = node
            node.left = last
        else:
            # First node
            first = node
        
        last = node
        
        # Process right subtree
        inorder(node.right)
    
    inorder(root)
    
    # Make circular
    last.right = first
    first.left = last
    
    return first
```

---

### 24. Recover Binary Search Tree

```python
def recoverTree(root):
    """
    Fix BST where two nodes are swapped
    Time: O(n), Space: O(h)
    """
    first = second = prev = None
    
    def inorder(node):
        nonlocal first, second, prev
        
        if not node:
            return
        
        inorder(node.left)
        
        # Find violations
        if prev and node.val < prev.val:
            if not first:
                first = prev
            second = node
        
        prev = node
        inorder(node.right)
    
    inorder(root)
    
    # Swap values
    first.val, second.val = second.val, first.val

# Morris traversal (O(1) space)
def recoverTree_morris(root):
    first = second = prev = None
    current = root
    
    while current:
        if current.left:
            # Find predecessor
            predecessor = current.left
            while predecessor.right and predecessor.right != current:
                predecessor = predecessor.right
            
            if not predecessor.right:
                # Create thread
                predecessor.right = current
                current = current.left
            else:
                # Remove thread and process
                predecessor.right = None
                
                if prev and current.val < prev.val:
                    if not first:
                        first = prev
                    second = current
                
                prev = current
                current = current.right
        else:
            # Process current
            if prev and current.val < prev.val:
                if not first:
                    first = prev
                second = current
            
            prev = current
            current = current.right
    
    first.val, second.val = second.val, first.val
```

---

### 25. Binary Tree Vertical Order

```python
def verticalOrder(root):
    """
    Return vertical order traversal
    Time: O(n log n), Space: O(n)
    """
    if not root:
        return []
    
    from collections import defaultdict, deque
    column_table = defaultdict(list)
    queue = deque([(root, 0)])  # (node, column)
    
    while queue:
        node, column = queue.popleft()
        column_table[column].append(node.val)
        
        if node.left:
            queue.append((node.left, column - 1))
        if node.right:
            queue.append((node.right, column + 1))
    
    # Sort by column and return values
    return [column_table[col] for col in sorted(column_table.keys())]
```

---

### 26. Boundary Traversal

```python
def boundaryOfBinaryTree(root):
    """
    Return boundary of binary tree (anti-clockwise)
    Time: O(n), Space: O(h)
    """
    if not root:
        return []
    
    if not root.left and not root.right:
        return [root.val]
    
    boundary = [root.val]
    
    # Left boundary (excluding leaves)
    def left_boundary(node):
        if not node or (not node.left and not node.right):
            return
        
        boundary.append(node.val)
        
        if node.left:
            left_boundary(node.left)
        else:
            left_boundary(node.right)
    
    # Leaves
    def leaves(node):
        if not node:
            return
        
        if not node.left and not node.right:
            boundary.append(node.val)
            return
        
        leaves(node.left)
        leaves(node.right)
    
    # Right boundary (excluding leaves, bottom-up)
    def right_boundary(node):
        if not node or (not node.left and not node.right):
            return
        
        if node.right:
            right_boundary(node.right)
        else:
            right_boundary(node.left)
        
        boundary.append(node.val)
    
    left_boundary(root.left)
    leaves(root)
    right_boundary(root.right)
    
    return boundary
```

---

### 27. Binary Tree Maximum Width

```python
def widthOfBinaryTree(root):
    """
    Find maximum width of binary tree
    Time: O(n), Space: O(n)
    """
    if not root:
        return 0
    
    from collections import deque
    max_width = 0
    # Store (node, position)
    queue = deque([(root, 0)])
    
    while queue:
        level_length = len(queue)
        _, level_start = queue[0]
        
        for _ in range(level_length):
            node, pos = queue.popleft()
            
            if node.left:
                queue.append((node.left, 2 * pos))
            if node.right:
                queue.append((node.right, 2 * pos + 1))
        
        # Width = rightmost - leftmost + 1
        max_width = max(max_width, pos - level_start + 1)
    
    return max_width
```

---

### 28. Binary Tree Cameras

```python
def minCameraCover(root):
    """
    Minimum cameras to monitor all nodes
    Time: O(n), Space: O(h)
    """
    cameras = [0]
    
    # States: 0 = needs cover, 1 = has camera, 2 = covered
    def dfs(node):
        if not node:
            return 2  # Null is covered
        
        left = dfs(node.left)
        right = dfs(node.right)
        
        # If either child needs cover, place camera here
        if left == 0 or right == 0:
            cameras[0] += 1
            return 1
        
        # If either child has camera, this is covered
        if left == 1 or right == 1:
            return 2
        
        # Both children covered but no camera, needs cover
        return 0
    
    # If root needs cover, add camera
    if dfs(root) == 0:
        cameras[0] += 1
    
    return cameras[0]
```

---

### 29. House Robber III

```python
def rob(root):
    """
    Maximum money from robbing houses (tree structure)
    Time: O(n), Space: O(h)
    """
    def dfs(node):
        # Returns (rob_current, not_rob_current)
        if not node:
            return (0, 0)
        
        left = dfs(node.left)
        right = dfs(node.right)
        
        # Rob current: can't rob children
        rob_current = node.val + left[1] + right[1]
        
        # Don't rob current: max of robbing or not robbing children
        not_rob_current = max(left) + max(right)
        
        return (rob_current, not_rob_current)
    
    return max(dfs(root))
```

---

### 30. Count Complete Tree Nodes

```python
def countNodes(root):
    """
    Count nodes in complete binary tree
    Time: O(log²n), Space: O(log n)
    """
    if not root:
        return 0
    
    def get_height(node):
        height = 0
        while node:
            height += 1
            node = node.left
        return height
    
    left_height = get_height(root.left)
    right_height = get_height(root.right)
    
    # Left subtree is perfect
    if left_height == right_height:
        return (1 << left_height) + countNodes(root.right)
    # Right subtree is perfect
    else:
        return (1 << right_height) + countNodes(root.left)

# Simple O(n) approach
def countNodes_simple(root):
    if not root:
        return 0
    return 1 + countNodes_simple(root.left) + countNodes_simple(root.right)
```

---

### 31. Path Sum III

```python
def pathSum3(root, targetSum):
    """
    Count paths that sum to target (can start anywhere)
    Time: O(n), Space: O(h)
    """
    from collections import defaultdict
    prefix_sum = defaultdict(int)
    prefix_sum[0] = 1  # Empty path
    
    def dfs(node, current_sum):
        if not node:
            return 0
        
        current_sum += node.val
        
        # Count paths ending at current node
        count = prefix_sum[current_sum - targetSum]
        
        # Add current sum to map
        prefix_sum[current_sum] += 1
        
        # Recurse
        count += dfs(node.left, current_sum)
        count += dfs(node.right, current_sum)
        
        # Backtrack
        prefix_sum[current_sum] -= 1
        
        return count
    
    return dfs(root, 0)
```

---

### 32. Sum of Left Leaves

```python
def sumOfLeftLeaves(root):
    """
    Sum all left leaves
    Time: O(n), Space: O(h)
    """
    if not root:
        return 0
    
    total = 0
    
    # Check if left child is a leaf
    if root.left and not root.left.left and not root.left.right:
        total += root.left.val
    else:
        total += sumOfLeftLeaves(root.left)
    
    total += sumOfLeftLeaves(root.right)
    
    return total

# Iterative approach
def sumOfLeftLeaves_iterative(root):
    if not root:
        return 0
    
    from collections import deque
    queue = deque([root])
    total = 0
    
    while queue:
        node = queue.popleft()
        
        # Check if left child is leaf
        if node.left:
            if not node.left.left and not node.left.right:
                total += node.left.val
            else:
                queue.append(node.left)
        
        if node.right:
            queue.append(node.right)
    
    return total
```

---

### 33. Find Bottom Left Tree Value

```python
def findBottomLeftValue(root):
    """
    Find leftmost value in last row
    Time: O(n), Space: O(w) where w is max width
    """
    from collections import deque
    queue = deque([root])
    leftmost = root.val
    
    while queue:
        level_size = len(queue)
        
        for i in range(level_size):
            node = queue.popleft()
            
            # First node in level
            if i == 0:
                leftmost = node.val
            
            if node.left:
                queue.append(node.left)
            if node.right:
                queue.append(node.right)
    
    return leftmost

# DFS approach (right to left)
def findBottomLeftValue_dfs(root):
    max_depth = [-1]
    leftmost = [root.val]
    
    def dfs(node, depth):
        if not node:
            return
        
        # Update if we found deeper level
        if depth > max_depth[0]:
            max_depth[0] = depth
            leftmost[0] = node.val
        
        # Visit left first
        dfs(node.left, depth + 1)
        dfs(node.right, depth + 1)
    
    dfs(root, 0)
    return leftmost[0]
```

---

### 34. Binary Tree Tilt

```python
def findTilt(root):
    """
    Find sum of all node tilts
    Tilt = |sum(left subtree) - sum(right subtree)|
    Time: O(n), Space: O(h)
    """
    total_tilt = [0]
    
    def get_sum(node):
        if not node:
            return 0
        
        left_sum = get_sum(node.left)
        right_sum = get_sum(node.right)
        
        # Calculate tilt for current node
        tilt = abs(left_sum - right_sum)
        total_tilt[0] += tilt
        
        # Return sum including current node
        return node.val + left_sum + right_sum
    
    get_sum(root)
    return total_tilt[0]
```

---

### 35. Leaf Similar Trees

```python
def leafSimilar(root1, root2):
    """
    Check if two trees have same leaf sequence
    Time: O(n+m), Space: O(h1+h2)
    """
    def get_leaves(node):
        if not node:
            return []
        
        # Leaf node
        if not node.left and not node.right:
            return [node.val]
        
        return get_leaves(node.left) + get_leaves(node.right)
    
    return get_leaves(root1) == get_leaves(root2)

# Generator approach (space efficient)
def leafSimilar_generator(root1, root2):
    def leaf_sequence(node):
        if node:
            if not node.left and not node.right:
                yield node.val
            yield from leaf_sequence(node.left)
            yield from leaf_sequence(node.right)
    
    return list(leaf_sequence(root1)) == list(leaf_sequence(root2))
```

---

## 6. Heaps / Priority Queue (20 Questions)

### 1. Kth Largest Element in Stream

```python
import heapq

class KthLargest:
    """
    Find kth largest element in stream
    Time: O(log k) per add, Space: O(k)
    """
    def __init__(self, k, nums):
        self.k = k
        self.heap = nums
        heapq.heapify(self.heap)
        
        # Keep only k largest elements
        while len(self.heap) > k:
            heapq.heappop(self.heap)
    
    def add(self, val):
        heapq.heappush(self.heap, val)
        
        if len(self.heap) > self.k:
            heapq.heappop(self.heap)
        
        return self.heap[0]  # Smallest in heap = kth largest overall

# Usage
# kthLargest = KthLargest(3, [4, 5, 8, 2])
# kthLargest.add(3)  # returns 4
# kthLargest.add(5)  # returns 5
```

---

### 2. Top K Frequent Elements

```python
def topKFrequent(nums, k):
    """
    Find k most frequent elements
    Time: O(n log k), Space: O(n)
    """
    from collections import Counter
    import heapq
    
    # Count frequencies
    count = Counter(nums)
    
    # Use min heap of size k
    # Store (-frequency, num) for max heap behavior
    return heapq.nlargest(k, count.keys(), key=count.get)

# Alternative: Bucket sort approach O(n)
def topKFrequent_bucket(nums, k):
    from collections import Counter
    
    count = Counter(nums)
    # Bucket[i] contains elements with frequency i
    bucket = [[] for _ in range(len(nums) + 1)]
    
    for num, freq in count.items():
        bucket[freq].append(num)
    
    result = []
    # Iterate from highest frequency
    for i in range(len(bucket) - 1, 0, -1):
        result.extend(bucket[i])
        if len(result) >= k:
            return result[:k]
    
    return result
```

---

### 3. Merge K Sorted Lists

```python
class ListNode:
    def __init__(self, val=0, next=None):
        self.val = val
        self.next = next

def mergeKLists(lists):
    """
    Merge k sorted linked lists
    Time: O(n log k), Space: O(k)
    """
    import heapq
    
    # Min heap: (value, index, node)
    heap = []
    
    # Add first node from each list
    for i, node in enumerate(lists):
        if node:
            heapq.heappush(heap, (node.val, i, node))
    
    dummy = ListNode()
    current = dummy
    
    while heap:
        val, i, node = heapq.heappop(heap)
        
        current.next = node
        current = current.next
        
        # Add next node from same list
        if node.next:
            heapq.heappush(heap, (node.next.val, i, node.next))
    
    return dummy.next

# Divide and conquer approach
def mergeKLists_divide(lists):
    if not lists:
        return None
    
    def merge_two(l1, l2):
        dummy = ListNode()
        current = dummy
        
        while l1 and l2:
            if l1.val < l2.val:
                current.next = l1
                l1 = l1.next
            else:
                current.next = l2
                l2 = l2.next
            current = current.next
        
        current.next = l1 or l2
        return dummy.next
    
    # Merge lists pairwise
    while len(lists) > 1:
        merged = []
        for i in range(0, len(lists), 2):
            l1 = lists[i]
            l2 = lists[i + 1] if i + 1 < len(lists) else None
            merged.append(merge_two(l1, l2))
        lists = merged
    
    return lists[0]
```

---

### 4. Find Median from Data Stream

```python
import heapq

class MedianFinder:
    """
    Find median from data stream
    Time: O(log n) per add, O(1) for median
    Space: O(n)
    """
    def __init__(self):
        # Max heap for smaller half (invert with negative)
        self.small = []
        # Min heap for larger half
        self.large = []
    
    def addNum(self, num):
        # Add to max heap (smaller half)
        heapq.heappush(self.small, -num)
        
        # Balance: move largest from small to large
        if self.small and self.large and -self.small[0] > self.large[0]:
            val = -heapq.heappop(self.small)
            heapq.heappush(self.large, val)
        
        # Maintain size property (small.size == large.size or small.size = large.size + 1)
        if len(self.small) > len(self.large) + 1:
            val = -heapq.heappop(self.small)
            heapq.heappush(self.large, val)
        
        if len(self.large) > len(self.small):
            val = heapq.heappop(self.large)
            heapq.heappush(self.small, -val)
    
    def findMedian(self):
        if len(self.small) > len(self.large):
            return -self.small[0]
        return (-self.small[0] + self.large[0]) / 2.0
```

---

### 5. K Closest Points to Origin

```python
def kClosest(points, k):
    """
    Find k closest points to origin
    Time: O(n log k), Space: O(k)
    """
    import heapq
    
    # Max heap of size k (use negative distance)
    heap = []
    
    for x, y in points:
        dist = x*x + y*y
        
        if len(heap) < k:
            heapq.heappush(heap, (-dist, [x, y]))
        elif dist < -heap[0][0]:
            heapq.heapreplace(heap, (-dist, [x, y]))
    
    return [point for _, point in heap]

# QuickSelect approach O(n) average
def kClosest_quickselect(points, k):
    def distance(point):
        return point[0]**2 + point[1]**2
    
    def partition(left, right):
        pivot = distance(points[right])
        i = left
        
        for j in range(left, right):
            if distance(points[j]) < pivot:
                points[i], points[j] = points[j], points[i]
                i += 1
        
        points[i], points[right] = points[right], points[i]
        return i
    
    left, right = 0, len(points) - 1
    
    while left < right:
        mid = partition(left, right)
        
        if mid == k:
            break
        elif mid < k:
            left = mid + 1
        else:
            right = mid - 1
    
    return points[:k]
```

---

### 6. Task Scheduler

```python
def leastInterval(tasks, n):
    """
    Minimum intervals to complete tasks with cooldown
    Time: O(n), Space: O(1) - only 26 letters
    """
    from collections import Counter
    import heapq
    
    # Count frequencies
    count = Counter(tasks)
    
    # Max heap of frequencies
    heap = [-freq for freq in count.values()]
    heapq.heapify(heap)
    
    time = 0
    
    while heap:
        cycle = []
        
        # Try to execute n+1 tasks
        for _ in range(n + 1):
            if heap:
                freq = heapq.heappop(heap)
                if freq < -1:
                    cycle.append(freq + 1)
        
        # Add back remaining tasks
        for freq in cycle:
            heapq.heappush(heap, freq)
        
        # Add time (full cycle or remaining tasks)
        time += (n + 1) if heap else len(cycle)
    
    return time

# Mathematical approach
def leastInterval_math(tasks, n):
    from collections import Counter
    
    count = Counter(tasks)
    max_freq = max(count.values())
    max_count = sum(1 for freq in count.values() if freq == max_freq)
    
    # Formula: (max_freq - 1) * (n + 1) + max_count
    # Or total tasks if no idle needed
    return max(len(tasks), (max_freq - 1) * (n + 1) + max_count)
```

---

### 7. Reorganize String

```python
def reorganizeString(s):
    """
    Rearrange string so no adjacent characters are same
    Time: O(n log 26), Space: O(1)
    """
    from collections import Counter
    import heapq
    
    count = Counter(s)
    
    # Max heap
    heap = [(-freq, char) for char, freq in count.items()]
    heapq.heapify(heap)
    
    result = []
    prev_freq, prev_char = 0, ''
    
    while heap:
        freq, char = heapq.heappop(heap)
        
        result.append(char)
        
        # Add back previous character if remaining
        if prev_freq < 0:
            heapq.heappush(heap, (prev_freq, prev_char))
        
        # Update previous
        prev_freq = freq + 1
        prev_char = char
    
    result_str = ''.join(result)
    
    # Check if valid
    if len(result_str) != len(s):
        return ""
    
    return result_str
```

---

### 8. Connect Ropes with Minimum Cost

```python
def connectRopes(ropes):
    """
    Connect ropes with minimum cost
    Cost = sum of lengths being connected
    Time: O(n log n), Space: O(n)
    """
    import heapq
    
    heapq.heapify(ropes)
    total_cost = 0
    
    while len(ropes) > 1:
        # Take two smallest
        first = heapq.heappop(ropes)
        second = heapq.heappop(ropes)
        
        cost = first + second
        total_cost += cost
        
        # Add combined rope
        heapq.heappush(ropes, cost)
    
    return total_cost

# Example
# ropes = [4, 3, 2, 6]
# Result: 29
# Explanation: (2+3)=5, (4+5)=9, (6+9)=15, total = 5+9+15=29
```

---

### 9. Kth Smallest Element in Sorted Matrix

```python
def kthSmallest(matrix, k):
    """
    Find kth smallest in row and column sorted matrix
    Time: O(k log n), Space: O(n)
    """
    import heapq
    
    n = len(matrix)
    # Min heap: (value, row, col)
    heap = []
    
    # Add first element from each row
    for r in range(min(n, k)):
        heapq.heappush(heap, (matrix[r][0], r, 0))
    
    result = 0
    for _ in range(k):
        result, r, c = heapq.heappop(heap)
        
        # Add next element from same row
        if c + 1 < n:
            heapq.heappush(heap, (matrix[r][c + 1], r, c + 1))
    
    return result

# Binary search approach O(n log(max-min))
def kthSmallest_binary(matrix, k):
    n = len(matrix)
    left, right = matrix[0][0], matrix[n-1][n-1]
    
    def count_less_equal(mid):
        count = 0
        col = n - 1
        
        for row in range(n):
            while col >= 0 and matrix[row][col] > mid:
                col -= 1
            count += col + 1
        
        return count
    
    while left < right:
        mid = (left + right) // 2
        
        if count_less_equal(mid) < k:
            left = mid + 1
        else:
            right = mid
    
    return left
```

---

### 10. Sliding Window Median

```python
def medianSlidingWindow(nums, k):
    """
    Find median of each window of size k
    Time: O(n*k), Space: O(k)
    """
    import heapq
    from collections import defaultdict
    
    small = []  # Max heap
    large = []  # Min heap
    result = []
    
    # Track elements to remove
    to_remove = defaultdict(int)
    
    def balance():
        # Move from small to large
        while len(small) > len(large) + 1:
            val = -heapq.heappop(small)
            heapq.heappush(large, val)
        
        # Move from large to small
        while len(large) > len(small):
            val = heapq.heappop(large)
            heapq.heappush(small, -val)
    
    def clean_heap(heap):
        # Remove invalid elements from top
        while heap and to_remove[abs(heap[0])] > 0:
            val = abs(heapq.heappop(heap))
            to_remove[val] -= 1
    
    # Initialize first window
    for i in range(k):
        heapq.heappush(small, -nums[i])
    
    for _ in range(k // 2):
        val = -heapq.heappop(small)
        heapq.heappush(large, val)
    
    i = k
    while True:
        # Get median
        if k % 2 == 1:
            result.append(float(-small[0]))
        else:
            result.append((-small[0] + large[0]) / 2.0)
        
        if i >= len(nums):
            break
        
        # Remove outgoing element
        out_num = nums[i - k]
        to_remove[out_num] += 1
        
        # Add incoming element
        in_num = nums[i]
        
        if in_num <= -small[0]:
            heapq.heappush(small, -in_num)
        else:
            heapq.heappush(large, in_num)
        
        # Rebalance if needed
        if out_num <= -small[0]:
            if in_num > -small[0]:
                val = -heapq.heappop(small)
                heapq.heappush(large, val)
        else:
            if in_num <= -small[0]:
                val = heapq.heappop(large)
                heapq.heappush(small, -val)
        
        clean_heap(small)
        clean_heap(large)
        
        i += 1
    
    return result
```

---

### 11. Top K Frequent Words

```python
def topKFrequent_words(words, k):
    """
    Find k most frequent words (alphabetical if tie)
    Time: O(n log k), Space: O(n)
    """
    from collections import Counter
    import heapq
    
    count = Counter(words)
    
    # Min heap with custom comparison
    # (frequency, word) - but we want max freq, min alphabetical
    heap = []
    
    for word, freq in count.items():
        heapq.heappush(heap, (freq, word))
        if len(heap) > k:
            heapq.heappop(heap)
    
    # Sort result
    result = []
    while heap:
        freq, word = heapq.heappop(heap)
        result.append(word)
    
    # Sort by frequency desc, then alphabetical
    result.sort(key=lambda x: (-count[x], x))
    return result

# Using nsmallest with custom key
def topKFrequent_words_v2(words, k):
    from collections import Counter
    import heapq
    
    count = Counter(words)
    
    # Use heapq.nsmallest with inverted frequency
    return heapq.nsmallest(k, count.keys(), 
                          key=lambda x: (-count[x], x))
```

---

### 12. Smallest Range Covering K Lists

```python
def smallestRange(nums):
    """
    Find smallest range that includes at least one from each list
    Time: O(n log k), Space: O(k)
    """
    import heapq
    
    # Min heap: (value, list_idx, element_idx)
    heap = []
    current_max = float('-inf')
    
    # Add first element from each list
    for i in range(len(nums)):
        heapq.heappush(heap, (nums[i][0], i, 0))
        current_max = max(current_max, nums[i][0])
    
    result = [float('-inf'), float('inf')]
    
    while heap:
        current_min, list_idx, elem_idx = heapq.heappop(heap)
        
        # Update result if smaller range
        if current_max - current_min < result[1] - result[0]:
            result = [current_min, current_max]
        
        # Move to next element in same list
        if elem_idx + 1 < len(nums[list_idx]):
            next_val = nums[list_idx][elem_idx + 1]
            heapq.heappush(heap, (next_val, list_idx, elem_idx + 1))
            current_max = max(current_max, next_val)
        else:
            # Can't include this list anymore
            break
    
    return result
```

---

### 13. Maximum Performance of Team

```python
def maxPerformance(n, speed, efficiency, k):
    """
    Choose at most k engineers to maximize performance
    Performance = sum(speed) * min(efficiency)
    Time: O(n log n), Space: O(k)
    """
    import heapq
    
    MOD = 10**9 + 7
    
    # Sort by efficiency descending
    engineers = sorted(zip(efficiency, speed), reverse=True)
    
    max_perf = 0
    speed_sum = 0
    heap = []  # Min heap of speeds
    
    for eff, spd in engineers:
        # Add current engineer's speed
        heapq.heappush(heap, spd)
        speed_sum += spd
        
        # Remove slowest if team too large
        if len(heap) > k:
            speed_sum -= heapq.heappop(heap)
        
        # Calculate performance with current min efficiency
        max_perf = max(max_perf, speed_sum * eff)
    
    return max_perf % MOD
```

---

### 14. Minimum Cost to Hire Workers

```python
def mincostToHireWorkers(quality, wage, k):
    """
    Hire k workers minimizing total cost while maintaining wage/quality ratio
    Time: O(n log n), Space: O(n)
    """
    import heapq
    
    # Calculate wage/quality ratio for each worker
    workers = sorted([(w/q, q, w) for q, w in zip(quality, wage)])
    
    min_cost = float('inf')
    quality_sum = 0
    heap = []  # Max heap of qualities
    
    for ratio, q, w in workers:
        # Add current worker
        heapq.heappush(heap, -q)
        quality_sum += q
        
        # Keep only k workers
        if len(heap) > k:
            quality_sum += heapq.heappop(heap)  # Remove largest quality
        
        # Calculate cost with current ratio as maximum
        if len(heap) == k:
            min_cost = min(min_cost, quality_sum * ratio)
    
    return min_cost
```

---

### 15. Furthest Building You Can Reach

```python
def furthestBuilding(heights, bricks, ladders):
    """
    Use bricks/ladders optimally to reach furthest building
    Time: O(n log ladders), Space: O(ladders)
    """
    import heapq
    
    # Min heap to track largest climbs where we used bricks
    heap = []
    
    for i in range(len(heights) - 1):
        climb = heights[i + 1] - heights[i]
        
        if climb <= 0:
            continue
        
        # Use bricks initially
        heapq.heappush(heap, climb)
        
        # If we've used more bricks than available
        if len(heap) > ladders:
            # Replace smallest climb with ladder
            bricks -= heapq.heappop(heap)
            
            if bricks < 0:
                return i
    
    return len(heights) - 1
```

---

### 16. IPO Problem

```python
def findMaximizedCapital(k, w, profits, capital):
    """
    Maximize capital by choosing k projects
    Time: O(n log n), Space: O(n)
    """
    import heapq
    
    # Sort projects by capital required
    projects = sorted(zip(capital, profits))
    
    # Max heap of profits
    available = []
    i = 0
    
    for _ in range(k):
        # Add all affordable projects
        while i < len(projects) and projects[i][0] <= w:
            heapq.heappush(available, -projects[i][1])
            i += 1
        
        # Choose most profitable
        if available:
            w += -heapq.heappop(available)
        else:
            break
    
    return w
```

---

### 17. Last Stone Weight

```python
def lastStoneWeight(stones):
    """
    Smash heaviest stones until one or none remain
    Time: O(n log n), Space: O(n)
    """
    import heapq
    
    # Max heap (negate values)
    heap = [-stone for stone in stones]
    heapq.heapify(heap)
    
    while len(heap) > 1:
        first = -heapq.heappop(heap)
        second = -heapq.heappop(heap)
        
        if first != second:
            heapq.heappush(heap, -(first - second))
    
    return -heap[0] if heap else 0
```

---

### 18. K Closest Elements

```python
def findClosestElements(arr, k, x):
    """
    Find k closest elements to x
    Time: O(log n + k), Space: O(1)
    """
    # Binary search for left boundary
    left, right = 0, len(arr) - k
    
    while left < right:
        mid = (left + right) // 2
        
        # Compare distances from x to elements at window boundaries
        if x - arr[mid] > arr[mid + k] - x:
            left = mid + 1
        else:
            right = mid
    
    return arr[left:left + k]

# Heap approach
def findClosestElements_heap(arr, k, x):
    import heapq
    
    # Max heap: (distance, value)
    heap = []
    
    for num in arr:
        dist = abs(num - x)
        
        if len(heap) < k:
            heapq.heappush(heap, (-dist, -num))
        elif dist < -heap[0][0]:
            heapq.heapreplace(heap, (-dist, -num))
    
    return sorted([-num for _, num in heap])
```

---

### 19. Maximum Frequency Stack

```python
class FreqStack:
    """
    Stack that pops most frequent element
    Time: O(1) for both push and pop
    Space: O(n)
    """
    def __init__(self):
        self.freq = {}  # Element -> frequency
        self.group = {}  # Frequency -> stack of elements
        self.max_freq = 0
    
    def push(self, val):
        # Update frequency
        f = self.freq.get(val, 0) + 1
        self.freq[val] = f
        
        # Update max frequency
        self.max_freq = max(self.max_freq, f)
        
        # Add to group
        if f not in self.group:
            self.group[f] = []
        self.group[f].append(val)
    
    def pop(self):
        # Pop from highest frequency group
        val = self.group[self.max_freq].pop()
        
        # Update frequency
        self.freq[val] -= 1
        
        # Update max frequency if group empty
        if not self.group[self.max_freq]:
            self.max_freq -= 1
        
        return val
```

---

### 20. Find K Pairs with Smallest Sums

```python
def kSmallestPairs(nums1, nums2, k):
    """
    Find k pairs with smallest sums from two arrays
    Time: O(k log k), Space: O(k)
    """
    import heapq
    
    if not nums1 or not nums2:
        return []
    
    # Min heap: (sum, i, j)
    heap = [(nums1[0] + nums2[0], 0, 0)]
    visited = {(0, 0)}
    result = []
    
    while heap and len(result) < k:
        total, i, j = heapq.heappop(heap)
        result.append([nums1[i], nums2[j]])
        
        # Add next pairs
        if i + 1 < len(nums1) and (i + 1, j) not in visited:
            heapq.heappush(heap, (nums1[i + 1] + nums2[j], i + 1, j))
            visited.add((i + 1, j))
        
        if j + 1 < len(nums2) and (i, j + 1) not in visited:
            heapq.heappush(heap, (nums1[i] + nums2[j + 1], i, j + 1))
            visited.add((i, j + 1))
    
    return result

# Optimized version (only track j indices)
def kSmallestPairs_v2(nums1, nums2, k):
    import heapq
    
    if not nums1 or not nums2:
        return []
    
    # Start with pairs (nums1[i], nums2[0])
    heap = [(nums1[i] + nums2[0], i, 0) for i in range(min(k, len(nums1)))]
    heapq.heapify(heap)
    
    result = []
    
    while heap and len(result) < k:
        total, i, j = heapq.heappop(heap)
        result.append([nums1[i], nums2[j]])
        
        # Only move j forward for this i
        if j + 1 < len(nums2):
            heapq.heappush(heap, (nums1[i] + nums2[j + 1], i, j + 1))
    
    return result
```

---

## Summary of Key Concepts

### Binary Trees:
1. **Traversals**: Preorder, Inorder, Postorder, Level-order
2. **Recursion**: Most tree problems use recursive approach
3. **Height/Depth**: Track levels for various problems
4. **BST Properties**: Left < Root < Right
5. **Path Problems**: Use DFS with backtracking

### Heaps:
1. **Min/Max Heap**: Use negative values to convert between them
2. **K Elements**: Maintain heap of size k
3. **Top K**: Use heap for efficient selection
4. **Sliding Window**: Use two heaps for median problems
5. **Greedy**: Heaps often used in greedy algorithms

**Time Complexities:**
- Tree traversal: O(n)
- Heap push/pop: O(log n)
- Building heap: O(n)
- Finding kth element: O(n log k)

# DSA Questions - Hashing & Graphs (Python Solutions)

I'll provide detailed solutions for all questions with explanations.

## 7. HASHING (20 Questions)

### 1. Two Sum
```python
def twoSum(nums, target):
    """
    Find indices of two numbers that add up to target.
    
    Approach: Hash map to store complements
    Time: O(n), Space: O(n)
    """
    seen = {}  # num -> index
    
    for i, num in enumerate(nums):
        complement = target - num
        if complement in seen:
            return [seen[complement], i]
        seen[num] = i
    
    return []

# Example
print(twoSum([2, 7, 11, 15], 9))  # [0, 1]
```

### 2. Subarray Sum Equals K
```python
def subarraySum(nums, k):
    """
    Count subarrays with sum equal to k.
    
    Approach: Prefix sum + hash map
    Time: O(n), Space: O(n)
    """
    count = 0
    prefix_sum = 0
    sum_freq = {0: 1}  # prefix_sum -> frequency
    
    for num in nums:
        prefix_sum += num
        # If (prefix_sum - k) exists, we found subarray(s)
        if prefix_sum - k in sum_freq:
            count += sum_freq[prefix_sum - k]
        sum_freq[prefix_sum] = sum_freq.get(prefix_sum, 0) + 1
    
    return count

# Example
print(subarraySum([1, 1, 1], 2))  # 2
```

### 3. Longest Consecutive Sequence
```python
def longestConsecutive(nums):
    """
    Find longest consecutive sequence length.
    
    Approach: Hash set for O(1) lookups
    Time: O(n), Space: O(n)
    """
    if not nums:
        return 0
    
    num_set = set(nums)
    max_length = 0
    
    for num in num_set:
        # Only start counting from sequence beginning
        if num - 1 not in num_set:
            current = num
            length = 1
            
            while current + 1 in num_set:
                current += 1
                length += 1
            
            max_length = max(max_length, length)
    
    return max_length

# Example
print(longestConsecutive([100, 4, 200, 1, 3, 2]))  # 4 ([1,2,3,4])
```

### 4. Happy Number
```python
def isHappy(n):
    """
    Determine if number is happy (sum of squares eventually = 1).
    
    Approach: Hash set to detect cycles
    Time: O(log n), Space: O(log n)
    """
    seen = set()
    
    while n != 1 and n not in seen:
        seen.add(n)
        n = sum(int(digit) ** 2 for digit in str(n))
    
    return n == 1

# Example
print(isHappy(19))  # True
```

### 5. Isomorphic Strings
```python
def isIsomorphic(s, t):
    """
    Check if two strings are isomorphic.
    
    Approach: Two hash maps for bidirectional mapping
    Time: O(n), Space: O(1) - limited by alphabet size
    """
    if len(s) != len(t):
        return False
    
    s_to_t = {}
    t_to_s = {}
    
    for char_s, char_t in zip(s, t):
        if char_s in s_to_t:
            if s_to_t[char_s] != char_t:
                return False
        else:
            s_to_t[char_s] = char_t
        
        if char_t in t_to_s:
            if t_to_s[char_t] != char_s:
                return False
        else:
            t_to_s[char_t] = char_s
    
    return True

# Example
print(isIsomorphic("egg", "add"))  # True
print(isIsomorphic("foo", "bar"))  # False
```

### 6. Group Anagrams
```python
def groupAnagrams(strs):
    """
    Group strings that are anagrams.
    
    Approach: Hash map with sorted string as key
    Time: O(n * k log k), Space: O(n * k)
    """
    from collections import defaultdict
    
    anagram_groups = defaultdict(list)
    
    for s in strs:
        # Sort string to use as key
        key = ''.join(sorted(s))
        anagram_groups[key].append(s)
    
    return list(anagram_groups.values())

# Alternative: Character count as key (faster)
def groupAnagrams2(strs):
    from collections import defaultdict
    
    anagram_groups = defaultdict(list)
    
    for s in strs:
        count = [0] * 26
        for char in s:
            count[ord(char) - ord('a')] += 1
        anagram_groups[tuple(count)].append(s)
    
    return list(anagram_groups.values())

# Example
print(groupAnagrams(["eat", "tea", "tan", "ate", "nat", "bat"]))
# [['eat', 'tea', 'ate'], ['tan', 'nat'], ['bat']]
```

### 7. Top K Frequent Elements
```python
def topKFrequent(nums, k):
    """
    Find k most frequent elements.
    
    Approach 1: Hash map + heap
    Time: O(n log k), Space: O(n)
    """
    from collections import Counter
    import heapq
    
    count = Counter(nums)
    return heapq.nlargest(k, count.keys(), key=count.get)

# Approach 2: Bucket sort (O(n) time)
def topKFrequent2(nums, k):
    from collections import Counter
    
    count = Counter(nums)
    # Bucket sort: index = frequency
    buckets = [[] for _ in range(len(nums) + 1)]
    
    for num, freq in count.items():
        buckets[freq].append(num)
    
    result = []
    for i in range(len(buckets) - 1, -1, -1):
        result.extend(buckets[i])
        if len(result) >= k:
            return result[:k]
    
    return result

# Example
print(topKFrequent([1, 1, 1, 2, 2, 3], 2))  # [1, 2]
```

### 8. Find Duplicate File in System
```python
def findDuplicate(paths):
    """
    Find duplicate files based on content.
    
    Approach: Hash map with content as key
    Time: O(n * m), Space: O(n * m)
    """
    from collections import defaultdict
    
    content_map = defaultdict(list)
    
    for path in paths:
        parts = path.split()
        directory = parts[0]
        
        for file_info in parts[1:]:
            name, content = file_info.split('(')
            content = content[:-1]  # Remove ')'
            full_path = directory + '/' + name
            content_map[content].append(full_path)
    
    return [paths for paths in content_map.values() if len(paths) > 1]

# Example
paths = ["root/a 1.txt(abcd) 2.txt(efgh)", "root/c 3.txt(abcd)"]
print(findDuplicate(paths))  # [['root/a/1.txt', 'root/c/3.txt']]
```

### 9. Design HashMap
```python
class MyHashMap:
    """
    Design a HashMap without built-in hash table.
    
    Approach: Array of buckets with chaining
    """
    def __init__(self):
        self.size = 1000
        self.buckets = [[] for _ in range(self.size)]
    
    def _hash(self, key):
        return key % self.size
    
    def put(self, key, value):
        """Time: O(n/k) average, O(n) worst"""
        bucket_idx = self._hash(key)
        bucket = self.buckets[bucket_idx]
        
        # Update if key exists
        for i, (k, v) in enumerate(bucket):
            if k == key:
                bucket[i] = (key, value)
                return
        
        # Add new key-value pair
        bucket.append((key, value))
    
    def get(self, key):
        """Time: O(n/k) average"""
        bucket_idx = self._hash(key)
        bucket = self.buckets[bucket_idx]
        
        for k, v in bucket:
            if k == key:
                return v
        return -1
    
    def remove(self, key):
        """Time: O(n/k) average"""
        bucket_idx = self._hash(key)
        bucket = self.buckets[bucket_idx]
        
        for i, (k, v) in enumerate(bucket):
            if k == key:
                del bucket[i]
                return

# Example
hashMap = MyHashMap()
hashMap.put(1, 1)
hashMap.put(2, 2)
print(hashMap.get(1))  # 1
hashMap.remove(2)
print(hashMap.get(2))  # -1
```

### 10. Design HashSet
```python
class MyHashSet:
    """
    Design a HashSet without built-in hash table.
    
    Approach: Array of buckets with chaining
    """
    def __init__(self):
        self.size = 1000
        self.buckets = [[] for _ in range(self.size)]
    
    def _hash(self, key):
        return key % self.size
    
    def add(self, key):
        """Time: O(n/k) average"""
        bucket_idx = self._hash(key)
        bucket = self.buckets[bucket_idx]
        
        if key not in bucket:
            bucket.append(key)
    
    def remove(self, key):
        """Time: O(n/k) average"""
        bucket_idx = self._hash(key)
        bucket = self.buckets[bucket_idx]
        
        if key in bucket:
            bucket.remove(key)
    
    def contains(self, key):
        """Time: O(n/k) average"""
        bucket_idx = self._hash(key)
        return key in self.buckets[bucket_idx]

# Example
hashSet = MyHashSet()
hashSet.add(1)
hashSet.add(2)
print(hashSet.contains(1))  # True
hashSet.remove(2)
print(hashSet.contains(2))  # False
```

### 11. Longest Substring Without Repeating Characters
```python
def lengthOfLongestSubstring(s):
    """
    Find longest substring without repeating characters.
    
    Approach: Sliding window + hash set
    Time: O(n), Space: O(min(n, m)) where m is alphabet size
    """
    char_set = set()
    left = 0
    max_length = 0
    
    for right in range(len(s)):
        # Shrink window until no duplicates
        while s[right] in char_set:
            char_set.remove(s[left])
            left += 1
        
        char_set.add(s[right])
        max_length = max(max_length, right - left + 1)
    
    return max_length

# Alternative: Hash map with last seen index
def lengthOfLongestSubstring2(s):
    last_seen = {}
    left = 0
    max_length = 0
    
    for right, char in enumerate(s):
        if char in last_seen and last_seen[char] >= left:
            left = last_seen[char] + 1
        
        last_seen[char] = right
        max_length = max(max_length, right - left + 1)
    
    return max_length

# Example
print(lengthOfLongestSubstring("abcabcbb"))  # 3 ("abc")
```

### 12. Count Primes
```python
def countPrimes(n):
    """
    Count primes less than n.
    
    Approach: Sieve of Eratosthenes
    Time: O(n log log n), Space: O(n)
    """
    if n <= 2:
        return 0
    
    is_prime = [True] * n
    is_prime[0] = is_prime[1] = False
    
    # Mark multiples of each prime as composite
    for i in range(2, int(n ** 0.5) + 1):
        if is_prime[i]:
            # Start from i*i (smaller multiples already marked)
            for j in range(i * i, n, i):
                is_prime[j] = False
    
    return sum(is_prime)

# Example
print(countPrimes(10))  # 4 (2, 3, 5, 7)
```

### 13. Continuous Subarray Sum
```python
def checkSubarraySum(nums, k):
    """
    Check if there's a subarray (size >= 2) with sum = multiple of k.
    
    Approach: Prefix sum modulo + hash map
    Time: O(n), Space: O(min(n, k))
    """
    # Map: remainder -> index
    remainder_map = {0: -1}  # Handle edge case
    prefix_sum = 0
    
    for i, num in enumerate(nums):
        prefix_sum += num
        remainder = prefix_sum % k if k != 0 else prefix_sum
        
        if remainder in remainder_map:
            # Check if subarray length >= 2
            if i - remainder_map[remainder] >= 2:
                return True
        else:
            remainder_map[remainder] = i
    
    return False

# Example
print(checkSubarraySum([23, 2, 4, 6, 7], 6))  # True ([2, 4])
```

### 14. Minimum Window Substring
```python
def minWindow(s, t):
    """
    Find minimum window in s that contains all characters of t.
    
    Approach: Sliding window + two hash maps
    Time: O(m + n), Space: O(m + n)
    """
    from collections import Counter
    
    if not s or not t:
        return ""
    
    t_count = Counter(t)
    required = len(t_count)
    
    left = 0
    formed = 0  # Unique chars in window matching t_count
    window_counts = {}
    
    # (window_length, left, right)
    ans = float('inf'), None, None
    
    for right in range(len(s)):
        char = s[right]
        window_counts[char] = window_counts.get(char, 0) + 1
        
        # Check if frequency matches
        if char in t_count and window_counts[char] == t_count[char]:
            formed += 1
        
        # Try to shrink window
        while left <= right and formed == required:
            char = s[left]
            
            # Update result if smaller window
            if right - left + 1 < ans[0]:
                ans = (right - left + 1, left, right)
            
            # Remove from window
            window_counts[char] -= 1
            if char in t_count and window_counts[char] < t_count[char]:
                formed -= 1
            
            left += 1
    
    return "" if ans[0] == float('inf') else s[ans[1]:ans[2] + 1]

# Example
print(minWindow("ADOBECODEBANC", "ABC"))  # "BANC"
```

### 15. Fraction to Recurring Decimal
```python
def fractionToDecimal(numerator, denominator):
    """
    Convert fraction to decimal with recurring part in parentheses.
    
    Approach: Hash map to track remainders
    Time: O(d) where d is denominator, Space: O(d)
    """
    if numerator == 0:
        return "0"
    
    result = []
    
    # Handle sign
    if (numerator < 0) ^ (denominator < 0):
        result.append("-")
    
    numerator, denominator = abs(numerator), abs(denominator)
    
    # Integer part
    result.append(str(numerator // denominator))
    remainder = numerator % denominator
    
    if remainder == 0:
        return ''.join(result)
    
    result.append(".")
    
    # Fractional part
    remainder_map = {}  # remainder -> index in result
    
    while remainder != 0:
        if remainder in remainder_map:
            # Found recurring cycle
            idx = remainder_map[remainder]
            result.insert(idx, "(")
            result.append(")")
            break
        
        remainder_map[remainder] = len(result)
        remainder *= 10
        result.append(str(remainder // denominator))
        remainder %= denominator
    
    return ''.join(result)

# Example
print(fractionToDecimal(1, 2))  # "0.5"
print(fractionToDecimal(2, 3))  # "0.(6)"
print(fractionToDecimal(4, 333))  # "0.(012)"
```

### 16. Random Pick with Blacklist
```python
class Solution:
    """
    Pick random number from [0, n) excluding blacklisted numbers.
    
    Approach: Remap blacklisted numbers to valid range
    Time: O(b) init, O(1) pick, Space: O(b)
    """
    def __init__(self, n, blacklist):
        import random
        self.random = random
        
        # Valid range: [0, n - len(blacklist))
        self.valid_range = n - len(blacklist)
        
        # Remap blacklisted numbers in valid range
        self.mapping = {}
        blacklist_set = set(blacklist)
        
        # Available numbers in invalid range [valid_range, n)
        available = n - 1
        
        for b in blacklist:
            if b < self.valid_range:
                # Find next available number
                while available in blacklist_set:
                    available -= 1
                self.mapping[b] = available
                available -= 1
    
    def pick(self):
        num = self.random.randint(0, self.valid_range - 1)
        return self.mapping.get(num, num)

# Example
obj = Solution(7, [2, 3, 5])
print([obj.pick() for _ in range(10)])  # Random picks from {0,1,4,6}
```

### 17. Insert Delete GetRandom O(1)
```python
class RandomizedSet:
    """
    Set with O(1) insert, remove, and getRandom.
    
    Approach: Hash map + dynamic array
    """
    def __init__(self):
        import random
        self.random = random
        self.nums = []  # Store values
        self.indices = {}  # val -> index in nums
    
    def insert(self, val):
        """Time: O(1)"""
        if val in self.indices:
            return False
        
        self.indices[val] = len(self.nums)
        self.nums.append(val)
        return True
    
    def remove(self, val):
        """Time: O(1)"""
        if val not in self.indices:
            return False
        
        # Swap with last element
        idx = self.indices[val]
        last_val = self.nums[-1]
        
        self.nums[idx] = last_val
        self.indices[last_val] = idx
        
        # Remove last element
        self.nums.pop()
        del self.indices[val]
        
        return True
    
    def getRandom(self):
        """Time: O(1)"""
        return self.random.choice(self.nums)

# Example
randomSet = RandomizedSet()
randomSet.insert(1)
randomSet.remove(2)
randomSet.insert(2)
print(randomSet.getRandom())  # 1 or 2
```

### 18. LRU Cache
```python
class LRUCache:
    """
    Least Recently Used cache with O(1) operations.
    
    Approach: Hash map + doubly linked list
    """
    class Node:
        def __init__(self, key=0, val=0):
            self.key = key
            self.val = val
            self.prev = None
            self.next = None
    
    def __init__(self, capacity):
        self.capacity = capacity
        self.cache = {}  # key -> node
        
        # Dummy head and tail
        self.head = self.Node()
        self.tail = self.Node()
        self.head.next = self.tail
        self.tail.prev = self.head
    
    def _remove(self, node):
        """Remove node from linked list"""
        node.prev.next = node.next
        node.next.prev = node.prev
    
    def _add_to_head(self, node):
        """Add node right after head"""
        node.next = self.head.next
        node.prev = self.head
        self.head.next.prev = node
        self.head.next = node
    
    def get(self, key):
        """Time: O(1)"""
        if key not in self.cache:
            return -1
        
        node = self.cache[key]
        # Move to front (most recently used)
        self._remove(node)
        self._add_to_head(node)
        return node.val
    
    def put(self, key, value):
        """Time: O(1)"""
        if key in self.cache:
            # Update value and move to front
            node = self.cache[key]
            node.val = value
            self._remove(node)
            self._add_to_head(node)
        else:
            # Add new node
            if len(self.cache) >= self.capacity:
                # Remove LRU (tail.prev)
                lru = self.tail.prev
                self._remove(lru)
                del self.cache[lru.key]
            
            new_node = self.Node(key, value)
            self.cache[key] = new_node
            self._add_to_head(new_node)

# Example
lru = LRUCache(2)
lru.put(1, 1)
lru.put(2, 2)
print(lru.get(1))  # 1
lru.put(3, 3)  # Evicts key 2
print(lru.get(2))  # -1
```

### 19. LFU Cache
```python
class LFUCache:
    """
    Least Frequently Used cache with O(1) operations.
    
    Approach: Multiple hash maps + doubly linked lists
    """
    class Node:
        def __init__(self, key=0, val=0):
            self.key = key
            self.val = val
            self.freq = 1
            self.prev = None
            self.next = None
    
    class DoublyLinkedList:
        def __init__(self):
            self.head = LFUCache.Node()
            self.tail = LFUCache.Node()
            self.head.next = self.tail
            self.tail.prev = self.head
            self.size = 0
        
        def add(self, node):
            node.next = self.head.next
            node.prev = self.head
            self.head.next.prev = node
            self.head.next = node
            self.size += 1
        
        def remove(self, node):
            node.prev.next = node.next
            node.next.prev = node.prev
            self.size -= 1
        
        def remove_last(self):
            if self.size > 0:
                last = self.tail.prev
                self.remove(last)
                return last
            return None
    
    def __init__(self, capacity):
        self.capacity = capacity
        self.min_freq = 0
        self.cache = {}  # key -> node
        self.freq_map = {}  # freq -> DoublyLinkedList
    
    def _update_freq(self, node):
        """Update node frequency"""
        freq = node.freq
        self.freq_map[freq].remove(node)
        
        # Update min_freq if necessary
        if self.min_freq == freq and self.freq_map[freq].size == 0:
            self.min_freq += 1
        
        node.freq += 1
        if node.freq not in self.freq_map:
            self.freq_map[node.freq] = self.DoublyLinkedList()
        self.freq_map[node.freq].add(node)
    
    def get(self, key):
        """Time: O(1)"""
        if key not in self.cache:
            return -1
        
        node = self.cache[key]
        self._update_freq(node)
        return node.val
    
    def put(self, key, value):
        """Time: O(1)"""
        if self.capacity == 0:
            return
        
        if key in self.cache:
            node = self.cache[key]
            node.val = value
            self._update_freq(node)
        else:
            if len(self.cache) >= self.capacity:
                # Remove LFU
                lfu_list = self.freq_map[self.min_freq]
                lfu_node = lfu_list.remove_last()
                del self.cache[lfu_node.key]
            
            new_node = self.Node(key, value)
            self.cache[key] = new_node
            self.min_freq = 1
            
            if 1 not in self.freq_map:
                self.freq_map[1] = self.DoublyLinkedList()
            self.freq_map[1].add(new_node)

# Example
lfu = LFUCache(2)
lfu.put(1, 1)
lfu.put(2, 2)
print(lfu.get(1))  # 1
lfu.put(3, 3)  # Evicts key 2
print(lfu.get(2))  # -1
```

### 20. Subdomain Visit Count
```python
def subdomainVisits(cpdomains):
    """
    Count visits to all subdomains.
    
    Approach: Hash map with domain splitting
    Time: O(n * m), Space: O(n * m)
    """
    from collections import defaultdict
    
    domain_count = defaultdict(int)
    
    for cpdomain in cpdomains:
        count, domain = cpdomain.split()
        count = int(count)
        
        # Split domain into parts
        parts = domain.split('.')
        
        # Count all subdomains
        for i in range(len(parts)):
            subdomain = '.'.join(parts[i:])
            domain_count[subdomain] += count
    
    return [f"{count} {domain}" for domain, count in domain_count.items()]

# Example
cpdomains = ["9001 discuss.leetcode.com"]
print(subdomainVisits(cpdomains))
# ["9001 discuss.leetcode.com", "9001 leetcode.com", "9001 com"]
```

---

## 8. GRAPHS (35 Questions)

### 1. Number of Islands
```python
def numIslands(grid):
    """
    Count number of islands (connected 1s).
    
    Approach 1: DFS
    Time: O(m*n), Space: O(m*n) for recursion stack
    """
    if not grid:
        return 0
    
    rows, cols = len(grid), len(grid[0])
    count = 0
    
    def dfs(r, c):
        # Boundary check and water check
        if r < 0 or r >= rows or c < 0 or c >= cols or grid[r][c] != '1':
            return
        
        # Mark as visited
        grid[r][c] = '0'
        
        # Explore 4 directions
        dfs(r + 1, c)
        dfs(r - 1, c)
        dfs(r, c + 1)
        dfs(r, c - 1)
    
    for r in range(rows):
        for c in range(cols):
            if grid[r][c] == '1':
                dfs(r, c)
                count += 1
    
    return count

# Approach 2: BFS
def numIslands_bfs(grid):
    from collections import deque
    
    if not grid:
        return 0
    
    rows, cols = len(grid), len(grid[0])
    count = 0
    
    def bfs(start_r, start_c):
        queue = deque([(start_r, start_c)])
        grid[start_r][start_c] = '0'
        
        while queue:
            r, c = queue.popleft()
            
            for dr, dc in [(1,0), (-1,0), (0,1), (0,-1)]:
                nr, nc = r + dr, c + dc
                if 0 <= nr < rows and 0 <= nc < cols and grid[nr][nc] == '1':
                    grid[nr][nc] = '0'
                    queue.append((nr, nc))
    
    for r in range(rows):
        for c in range(cols):
            if grid[r][c] == '1':
                bfs(r, c)
                count += 1
    
    return count

# Example
grid = [
    ["1","1","0","0","0"],
    ["1","1","0","0","0"],
    ["0","0","1","0","0"],
    ["0","0","0","1","1"]
]
print(numIslands(grid))  # 3
```

### 2. Clone Graph
```python
class Node:
    def __init__(self, val=0, neighbors=None):
        self.val = val
        self.neighbors = neighbors if neighbors is not None else []

def cloneGraph(node):
    """
    Deep copy undirected graph.
    
    Approach: DFS/BFS with hash map
    Time: O(V + E), Space: O(V)
    """
    if not node:
        return None
    
    # Map original node to clone
    clones = {}
    
    def dfs(node):
        if node in clones:
            return clones[node]
        
        # Create clone
        clone = Node(node.val)
        clones[node] = clone
        
        # Clone neighbors
        for neighbor in node.neighbors:
            clone.neighbors.append(dfs(neighbor))
        
        return clone
    
    return dfs(node)

# BFS approach
def cloneGraph_bfs(node):
    from collections import deque
    
    if not node:
        return None
    
    clones = {node: Node(node.val)}
    queue = deque([node])
    
    while queue:
        curr = queue.popleft()
        
        for neighbor in curr.neighbors:
            if neighbor not in clones:
                clones[neighbor] = Node(neighbor.val)
                queue.append(neighbor)
            
            clones[curr].neighbors.append(clones[neighbor])
    
    return clones[node]
```

### 3. Course Schedule
```python
def canFinish(numCourses, prerequisites):
    """
    Detect if courses can be finished (cycle detection).
    
    Approach: DFS with cycle detection
    Time: O(V + E), Space: O(V + E)
    """
    from collections import defaultdict
    
    # Build adjacency list
    graph = defaultdict(list)
    for course, prereq in prerequisites:
        graph[course].append(prereq)
    
    # 0 = unvisited, 1 = visiting, 2 = visited
    state = [0] * numCourses
    
    def has_cycle(course):
        if state[course] == 1:  # Visiting - cycle detected
            return True
        if state[course] == 2:  # Already visited
            return False
        
        state[course] = 1  # Mark as visiting
        
        for prereq in graph[course]:
            if has_cycle(prereq):
                return True
        
        state[course] = 2  # Mark as visited
        return False
    
    for course in range(numCourses):
        if has_cycle(course):
            return False
    
    return True

# Approach 2: Kahn's Algorithm (BFS topological sort)
def canFinish_kahn(numCourses, prerequisites):
    from collections import defaultdict, deque
    
    graph = defaultdict(list)
    in_degree = [0] * numCourses
    
    for course, prereq in prerequisites:
        graph[prereq].append(course)
        in_degree[course] += 1
    
    # Start with courses having no prerequisites
    queue = deque([i for i in range(numCourses) if in_degree[i] == 0])
    completed = 0
    
    while queue:
        course = queue.popleft()
        completed += 1
        
        for next_course in graph[course]:
            in_degree[next_course] -= 1
            if in_degree[next_course] == 0:
                queue.append(next_course)
    
    return completed == numCourses

# Example
print(canFinish(2, [[1,0]]))  # True
print(canFinish(2, [[1,0],[0,1]]))  # False
```

### 4. Course Schedule II
```python
def findOrder(numCourses, prerequisites):
    """
    Find course order (topological sort).
    
    Approach: Kahn's Algorithm
    Time: O(V + E), Space: O(V + E)
    """
    from collections import defaultdict, deque
    
    graph = defaultdict(list)
    in_degree = [0] * numCourses
    
    for course, prereq in prerequisites:
        graph[prereq].append(course)
        in_degree[course] += 1
    
    queue = deque([i for i in range(numCourses) if in_degree[i] == 0])
    order = []
    
    while queue:
        course = queue.popleft()
        order.append(course)
        
        for next_course in graph[course]:
            in_degree[next_course] -= 1
            if in_degree[next_course] == 0:
                queue.append(next_course)
    
    return order if len(order) == numCourses else []

# DFS approach
def findOrder_dfs(numCourses, prerequisites):
    from collections import defaultdict
    
    graph = defaultdict(list)
    for course, prereq in prerequisites:
        graph[course].append(prereq)
    
    state = [0] * numCourses  # 0=unvisited, 1=visiting, 2=visited
    order = []
    
    def dfs(course):
        if state[course] == 1:
            return False
        if state[course] == 2:
            return True
        
        state[course] = 1
        
        for prereq in graph[course]:
            if not dfs(prereq):
                return False
        
        state[course] = 2
        order.append(course)
        return True
    
    for course in range(numCourses):
        if not dfs(course):
            return []
    
    return order

# Example
print(findOrder(4, [[1,0],[2,0],[3,1],[3,2]]))  # [0,1,2,3] or [0,2,1,3]
```

### 5. Pacific Atlantic Water Flow
```python
def pacificAtlantic(heights):
    """
    Find cells where water can flow to both oceans.
    
    Approach: DFS from ocean borders
    Time: O(m*n), Space: O(m*n)
    """
    if not heights:
        return []
    
    rows, cols = len(heights), len(heights[0])
    pacific = set()
    atlantic = set()
    
    def dfs(r, c, visited):
        visited.add((r, c))
        
        for dr, dc in [(1,0), (-1,0), (0,1), (0,-1)]:
            nr, nc = r + dr, c + dc
            if (0 <= nr < rows and 0 <= nc < cols and 
                (nr, nc) not in visited and
                heights[nr][nc] >= heights[r][c]):
                dfs(nr, nc, visited)
    
    # DFS from Pacific border (top and left)
    for c in range(cols):
        dfs(0, c, pacific)
        dfs(rows - 1, c, atlantic)
    
    for r in range(rows):
        dfs(r, 0, pacific)
        dfs(r, cols - 1, atlantic)
    
    return list(pacific & atlantic)

# Example
heights = [[1,2,2,3,5],[3,2,3,4,4],[2,4,5,3,1],[6,7,1,4,5],[5,1,1,2,4]]
print(pacificAtlantic(heights))
# [[0,4],[1,3],[1,4],[2,2],[3,0],[3,1],[4,0]]
```

### 6. Rotting Oranges
```python
def orangesRotting(grid):
    """
    Find time for all oranges to rot (multi-source BFS).
    
    Approach: BFS from all rotten oranges
    Time: O(m*n), Space: O(m*n)
    """
    from collections import deque
    
    rows, cols = len(grid), len(grid[0])
    queue = deque()
    fresh = 0
    
    # Find all rotten oranges and count fresh
    for r in range(rows):
        for c in range(cols):
            if grid[r][c] == 2:
                queue.append((r, c, 0))  # (row, col, time)
            elif grid[r][c] == 1:
                fresh += 1
    
    if fresh == 0:
        return 0
    
    max_time = 0
    
    while queue:
        r, c, time = queue.popleft()
        max_time = max(max_time, time)
        
        for dr, dc in [(1,0), (-1,0), (0,1), (0,-1)]:
            nr, nc = r + dr, c + dc
            if 0 <= nr < rows and 0 <= nc < cols and grid[nr][nc] == 1:
                grid[nr][nc] = 2
                fresh -= 1
                queue.append((nr, nc, time + 1))
    
    return max_time if fresh == 0 else -1

# Example
grid = [[2,1,1],[1,1,0],[0,1,1]]
print(orangesRotting(grid))  # 4
```

### 7. Walls and Gates
```python
def wallsAndGates(rooms):
    """
    Fill rooms with distance to nearest gate (multi-source BFS).
    
    Approach: BFS from all gates
    Time: O(m*n), Space: O(m*n)
    """
    from collections import deque
    
    if not rooms:
        return
    
    rows, cols = len(rooms), len(rooms[0])
    queue = deque()
    
    # Find all gates
    for r in range(rows):
        for c in range(cols):
            if rooms[r][c] == 0:
                queue.append((r, c))
    
    while queue:
        r, c = queue.popleft()
        
        for dr, dc in [(1,0), (-1,0), (0,1), (0,-1)]:
            nr, nc = r + dr, c + dc
            if (0 <= nr < rows and 0 <= nc < cols and 
                rooms[nr][nc] == 2147483647):
                rooms[nr][nc] = rooms[r][c] + 1
                queue.append((nr, nc))

# Example
INF = 2147483647
rooms = [
    [INF, -1, 0, INF],
    [INF, INF, INF, -1],
    [INF, -1, INF, -1],
    [0, -1, INF, INF]
]
wallsAndGates(rooms)
print(rooms)
```

### 8. Graph Valid Tree
```python
def validTree(n, edges):
    """
    Check if edges form a valid tree.
    
    Conditions: n-1 edges, connected, no cycles
    Time: O(V + E), Space: O(V + E)
    """
    if len(edges) != n - 1:
        return False
    
    from collections import defaultdict
    
    graph = defaultdict(list)
    for u, v in edges:
        graph[u].append(v)
        graph[v].append(u)
    
    visited = set()
    
    def dfs(node, parent):
        visited.add(node)
        
        for neighbor in graph[node]:
            if neighbor == parent:
                continue
            if neighbor in visited:
                return False  # Cycle detected
            if not dfs(neighbor, node):
                return False
        
        return True
    
    return dfs(0, -1) and len(visited) == n

# Union-Find approach
def validTree_uf(n, edges):
    if len(edges) != n - 1:
        return False
    
    parent = list(range(n))
    
    def find(x):
        if parent[x] != x:
            parent[x] = find(parent[x])
        return parent[x]
    
    def union(x, y):
        px, py = find(x), find(y)
        if px == py:
            return False  # Cycle
        parent[px] = py
        return True
    
    for u, v in edges:
        if not union(u, v):
            return False
    
    return True

# Example
print(validTree(5, [[0,1],[0,2],[0,3],[1,4]]))  # True
print(validTree(5, [[0,1],[1,2],[2,3],[1,3],[1,4]]))  # False
```

### 9. Number of Connected Components
```python
def countComponents(n, edges):
    """
    Count connected components in undirected graph.
    
    Approach 1: DFS
    Time: O(V + E), Space: O(V + E)
    """
    from collections import defaultdict
    
    graph = defaultdict(list)
    for u, v in edges:
        graph[u].append(v)
        graph[v].append(u)
    
    visited = set()
    count = 0
    
    def dfs(node):
        visited.add(node)
        for neighbor in graph[node]:
            if neighbor not in visited:
                dfs(neighbor)
    
    for i in range(n):
        if i not in visited:
            dfs(i)
            count += 1
    
    return count

# Union-Find approach
def countComponents_uf(n, edges):
    parent = list(range(n))
    
    def find(x):
        if parent[x] != x:
            parent[x] = find(parent[x])
        return parent[x]
    
    def union(x, y):
        px, py = find(x), find(y)
        if px != py:
            parent[px] = py
            return True
        return False
    
    components = n
    for u, v in edges:
        if union(u, v):
            components -= 1
    
    return components

# Example
print(countComponents(5, [[0,1],[1,2],[3,4]]))  # 2
```

### 10. Alien Dictionary
```python
def alienOrder(words):
    """
    Find alien language character order (topological sort).
    
    Approach: Build graph from word pairs, topological sort
    Time: O(C) where C is total chars, Space: O(1) - limited alphabet
    """
    from collections import defaultdict, deque
    
    # Build graph
    graph = defaultdict(set)
    in_degree = {c: 0 for word in words for c in word}
    
    # Compare adjacent words
    for i in range(len(words) - 1):
        w1, w2 = words[i], words[i + 1]
        min_len = min(len(w1), len(w2))
        
        # Check for invalid case: w1 is prefix of w2 but longer
        if len(w1) > len(w2) and w1[:min_len] == w2[:min_len]:
            return ""
        
        # Find first different character
        for j in range(min_len):
            if w1[j] != w2[j]:
                if w2[j] not in graph[w1[j]]:
                    graph[w1[j]].add(w2[j])
                    in_degree[w2[j]] += 1
                break
    
    # Kahn's algorithm
    queue = deque([c for c in in_degree if in_degree[c] == 0])
    order = []
    
    while queue:
        char = queue.popleft()
        order.append(char)
        
        for next_char in graph[char]:
            in_degree[next_char] -= 1
            if in_degree[next_char] == 0:
                queue.append(next_char)
    
    if len(order) != len(in_degree):
        return ""  # Cycle detected
    
    return ''.join(order)

# Example
print(alienOrder(["wrt","wrf","er","ett","rftt"]))  # "wertf"
```

### 11. Word Ladder
```python
def ladderLength(beginWord, endWord, wordList):
    """
    Find shortest transformation sequence length.
    
    Approach: BFS with word transformations
    Time: O(M^2 * N), Space: O(M^2 * N)
    M = word length, N = wordList size
    """
    from collections import deque
    
    word_set = set(wordList)
    if endWord not in word_set:
        return 0
    
    queue = deque([(beginWord, 1)])
    
    while queue:
        word, length = queue.popleft()
        
        if word == endWord:
            return length
        
        # Try all possible transformations
        for i in range(len(word)):
            for c in 'abcdefghijklmnopqrstuvwxyz':
                next_word = word[:i] + c + word[i+1:]
                
                if next_word in word_set:
                    word_set.remove(next_word)
                    queue.append((next_word, length + 1))
    
    return 0

# Bidirectional BFS (faster)
def ladderLength_bidirectional(beginWord, endWord, wordList):
    word_set = set(wordList)
    if endWord not in word_set:
        return 0
    
    begin_set = {beginWord}
    end_set = {endWord}
    word_set.remove(endWord)
    length = 1
    
    while begin_set and end_set:
        # Always expand smaller set
        if len(begin_set) > len(end_set):
            begin_set, end_set = end_set, begin_set
        
        next_set = set()
        
        for word in begin_set:
            for i in range(len(word)):
                for c in 'abcdefghijklmnopqrstuvwxyz':
                    next_word = word[:i] + c + word[i+1:]
                    
                    if next_word in end_set:
                        return length + 1
                    
                    if next_word in word_set:
                        word_set.remove(next_word)
                        next_set.add(next_word)
        
        begin_set = next_set
        length += 1
    
    return 0

# Example
wordList = ["hot","dot","dog","lot","log","cog"]
print(ladderLength("hit", "cog", wordList))  # 5
```

### 12. Word Ladder II
```python
def findLadders(beginWord, endWord, wordList):
    """
    Find all shortest transformation sequences.
    
    Approach: BFS to build graph + DFS to find paths
    Time: O(M^2 * N), Space: O(M^2 * N)
    """
    from collections import defaultdict, deque
    
    word_set = set(wordList)
    if endWord not in word_set:
        return []
    
    # BFS to find shortest paths and build graph
    graph = defaultdict(list)
    distance = {beginWord: 0}
    queue = deque([beginWord])
    found = False
    
    while queue and not found:
        level_size = len(queue)
        local_visited = set()
        
        for _ in range(level_size):
            word = queue.popleft()
            curr_dist = distance[word]
            
            # Try transformations
            for i in range(len(word)):
                for c in 'abcdefghijklmnopqrstuvwxyz':
                    next_word = word[:i] + c + word[i+1:]
                    
                    if next_word == endWord:
                        found = True
                        graph[word].append(next_word)
                    
                    if next_word in word_set:
                        if next_word not in distance:
                            distance[next_word] = curr_dist + 1
                            local_visited.add(next_word)
                        
                        if distance[next_word] == curr_dist + 1:
                            graph[word].append(next_word)
        
        queue.extend(local_visited)
    
    # DFS to find all paths
    result = []
    
    def dfs(word, path):
        if word == endWord:
            result.append(path[:])
            return
        
        for next_word in graph[word]:
            path.append(next_word)
            dfs(next_word, path)
            path.pop()
    
    dfs(beginWord, [beginWord])
    return result

# Example
wordList = ["hot","dot","dog","lot","log","cog"]
print(findLadders("hit", "cog", wordList))
# [["hit","hot","dot","dog","cog"],["hit","hot","lot","log","cog"]]
```

### 13. Network Delay Time
```python
def networkDelayTime(times, n, k):
    """
    Find minimum time for all nodes to receive signal (Dijkstra).
    
    Approach: Dijkstra's shortest path
    Time: O(E log V), Space: O(V + E)
    """
    from collections import defaultdict
    import heapq
    
    graph = defaultdict(list)
    for u, v, w in times:
        graph[u].append((v, w))
    
    # (time, node)
    min_heap = [(0, k)]
    visited = set()
    max_time = 0
    
    while min_heap:
        time, node = heapq.heappop(min_heap)
        
        if node in visited:
            continue
        
        visited.add(node)
        max_time = max(max_time, time)
        
        for neighbor, weight in graph[node]:
            if neighbor not in visited:
                heapq.heappush(min_heap, (time + weight, neighbor))
    
    return max_time if len(visited) == n else -1

# Bellman-Ford approach
def networkDelayTime_bf(times, n, k):
    dist = [float('inf')] * (n + 1)
    dist[k] = 0
    
    # Relax edges n-1 times
    for _ in range(n - 1):
        for u, v, w in times:
            if dist[u] != float('inf'):
                dist[v] = min(dist[v], dist[u] + w)
    
    max_time = max(dist[1:])
    return max_time if max_time != float('inf') else -1

# Example
times = [[2,1,1],[2,3,1],[3,4,1]]
print(networkDelayTime(times, 4, 2))  # 2
```

### 14. Cheapest Flights Within K Stops
```python
def findCheapestPrice(n, flights, src, dst, k):
    """
    Find cheapest flight with at most k stops.
    
    Approach: Modified Dijkstra/Bellman-Ford
    Time: O(E * K), Space: O(V)
    """
    import heapq
    from collections import defaultdict
    
    graph = defaultdict(list)
    for u, v, w in flights:
        graph[u].append((v, w))
    
    # (cost, node, stops)
    min_heap = [(0, src, 0)]
    visited = {}  # (node, stops) -> min_cost
    
    while min_heap:
        cost, node, stops = heapq.heappop(min_heap)
        
        if node == dst:
            return cost
        
        if stops > k:
            continue
        
        if (node, stops) in visited and visited[(node, stops)] <= cost:
            continue
        
        visited[(node, stops)] = cost
        
        for neighbor, price in graph[node]:
            heapq.heappush(min_heap, (cost + price, neighbor, stops + 1))
    
    return -1

# Bellman-Ford approach (simpler)
def findCheapestPrice_bf(n, flights, src, dst, k):
    dist = [float('inf')] * n
    dist[src] = 0
    
    # Relax edges k+1 times (k stops = k+1 edges)
    for _ in range(k + 1):
        temp = dist[:]
        for u, v, w in flights:
            if dist[u] != float('inf'):
                temp[v] = min(temp[v], dist[u] + w)
        dist = temp
    
    return dist[dst] if dist[dst] != float('inf') else -1

# Example
flights = [[0,1,100],[1,2,100],[0,2,500]]
print(findCheapestPrice(3, flights, 0, 2, 1))  # 200
```

### 15. Reconstruct Itinerary
```python
def findItinerary(tickets):
    """
    Find itinerary that uses all tickets (Eulerian path).
    
    Approach: Hierholzer's algorithm (DFS)
    Time: O(E log E), Space: O(E)
    """
    from collections import defaultdict
    
    graph = defaultdict(list)
    
    # Build graph and sort destinations
    for src, dst in sorted(tickets)[::-1]:
        graph[src].append(dst)
    
    route = []
    
    def dfs(airport):
        while graph[airport]:
            next_dest = graph[airport].pop()
            dfs(next_dest)
        route.append(airport)
    
    dfs("JFK")
    return route[::-1]

# Example
tickets = [["MUC","LHR"],["JFK","MUC"],["SFO","SJC"],["LHR","SFO"]]
print(findItinerary(tickets))  # ["JFK","MUC","LHR","SFO","SJC"]
```

### 16. Critical Connections in Network
```python
def criticalConnections(n, connections):
    """
    Find bridges (critical connections) in network.
    
    Approach: Tarjan's algorithm
    Time: O(V + E), Space: O(V + E)
    """
    from collections import defaultdict
    
    graph = defaultdict(list)
    for u, v in connections:
        graph[u].append(v)
        graph[v].append(u)
    
    disc = [-1] * n  # Discovery time
    low = [-1] * n   # Lowest reachable node
    time = [0]
    bridges = []
    
    def dfs(node, parent):
        disc[node] = low[node] = time[0]
        time[0] += 1
        
        for neighbor in graph[node]:
            if neighbor == parent:
                continue
            
            if disc[neighbor] == -1:
                dfs(neighbor, node)
                low[node] = min(low[node], low[neighbor])
                
                # Bridge condition
                if low[neighbor] > disc[node]:
                    bridges.append([node, neighbor])
            else:
                low[node] = min(low[node], disc[neighbor])
    
    dfs(0, -1)
    return bridges

# Example
connections = [[0,1],[1,2],[2,0],[1,3]]
print(criticalConnections(4, connections))  # [[1,3]]
```

### 17. Redundant Connection
```python
def findRedundantConnection(edges):
    """
    Find edge that creates cycle in tree (Union-Find).
    
    Approach: Union-Find
    Time: O(N * α(N)), Space: O(N)
    """
    parent = list(range(len(edges) + 1))
    
    def find(x):
        if parent[x] != x:
            parent[x] = find(parent[x])
        return parent[x]
    
    def union(x, y):
        px, py = find(x), find(y)
        if px == py:
            return False  # Already connected - cycle
        parent[px] = py
        return True
    
    for u, v in edges:
        if not union(u, v):
            return [u, v]
    
    return []

# Example
print(findRedundantConnection([[1,2],[1,3],[2,3]]))  # [2,3]
```

### 18. Minimum Height Trees
```python
def findMinHeightTrees(n, edges):
    """
    Find roots that minimize tree height (topological sort).
    
    Approach: Peel leaves layer by layer
    Time: O(V), Space: O(V)
    """
    if n == 1:
        return [0]
    
    from collections import defaultdict, deque
    
    graph = defaultdict(set)
    for u, v in edges:
        graph[u].add(v)
        graph[v].add(u)
    
    # Find initial leaves
    leaves = deque([i for i in range(n) if len(graph[i]) == 1])
    
    remaining = n
    while remaining > 2:
        leaf_count = len(leaves)
        remaining -= leaf_count
        
        for _ in range(leaf_count):
            leaf = leaves.popleft()
            neighbor = graph[leaf].pop()
            graph[neighbor].remove(leaf)
            
            if len(graph[neighbor]) == 1:
                leaves.append(neighbor)
    
    return list(leaves)

# Example
print(findMinHeightTrees(4, [[1,0],[1,2],[1,3]]))  # [1]
```

### 19. Evaluate Division
```python
def calcEquation(equations, values, queries):
    """
    Evaluate division queries (weighted graph).
    
    Approach: DFS with weighted edges
    Time: O(Q * (E + V)), Space: O(E + V)
    """
    from collections import defaultdict
    
    graph = defaultdict(dict)
    
    # Build graph
    for (dividend, divisor), value in zip(equations, values):
        graph[dividend][divisor] = value
        graph[divisor][dividend] = 1 / value
    
    def dfs(start, end, visited):
        if start not in graph or end not in graph:
            return -1.0
        
        if start == end:
            return 1.0
        
        visited.add(start)
        
        for neighbor, value in graph[start].items():
            if neighbor not in visited:
                result = dfs(neighbor, end, visited)
                if result != -1.0:
                    return value * result
        
        return -1.0
    
    return [dfs(start, end, set()) for start, end in queries]

# Union-Find approach
def calcEquation_uf(equations, values, queries):
    parent = {}
    weight = {}
    
    def find(x):
        if x not in parent:
            parent[x] = x
            weight[x] = 1.0
            return x, 1.0
        
        if parent[x] != x:
            root, w = find(parent[x])
            parent[x] = root
            weight[x] *= w
        
        return parent[x], weight[x]
    
    def union(x, y, value):
        rx, wx = find(x)
        ry, wy = find(y)
        
        if rx != ry:
            parent[rx] = ry
            weight[rx] = value * wy / wx
    
    for (x, y), value in zip(equations, values):
        union(x, y, value)
    
    result = []
    for x, y in queries:
        if x not in parent or y not in parent:
            result.append(-1.0)
        else:
            rx, wx = find(x)
            ry, wy = find(y)
            if rx != ry:
                result.append(-1.0)
            else:
                result.append(wx / wy)
    
    return result

# Example
equations = [["a","b"],["b","c"]]
values = [2.0, 3.0]
queries = [["a","c"],["b","a"],["a","e"]]
print(calcEquation(equations, values, queries))  # [6.0, 0.5, -1.0]
```

### 20. Shortest Path in Binary Matrix
```python
def shortestPathBinaryMatrix(grid):
    """
    Find shortest path from top-left to bottom-right (8-directional).
    
    Approach: BFS
    Time: O(N^2), Space: O(N^2)
    """
    from collections import deque
    
    n = len(grid)
    
    if grid[0][0] == 1 or grid[n-1][n-1] == 1:
        return -1
    
    if n == 1:
        return 1
    
    queue = deque([(0, 0, 1)])  # (row, col, distance)
    grid[0][0] = 1  # Mark visited
    
    # 8 directions
    directions = [(-1,-1),(-1,0),(-1,1),(0,-1),(0,1),(1,-1),(1,0),(1,1)]
    
    while queue:
        r, c, dist = queue.popleft()
        
        for dr, dc in directions:
            nr, nc = r + dr, c + dc
            
            if nr == n - 1 and nc == n - 1:
                return dist + 1
            
            if 0 <= nr < n and 0 <= nc < n and grid[nr][nc] == 0:
                grid[nr][nc] = 1  # Mark visited
                queue.append((nr, nc, dist + 1))
    
    return -1

# Example
grid = [[0,1],[1,0]]
print(shortestPathBinaryMatrix(grid))  # 2
```

### 21. Keys and Rooms
```python
def canVisitAllRooms(rooms):
    """
    Check if all rooms can be visited starting from room 0.
    
    Approach: DFS/BFS
    Time: O(V + E), Space: O(V)
    """
    visited = set([0])
    stack = [0]
    
    while stack:
        room = stack.pop()
        
        for key in rooms[room]:
            if key not in visited:
                visited.add(key)
                stack.append(key)
    
    return len(visited) == len(rooms)

# Example
rooms = [[1],[2],[3],[]]
print(canVisitAllRooms(rooms))  # True
```

### 22. Find Eventual Safe States
```python
def eventualSafeNodes(graph):
    """
    Find nodes that eventually lead to terminal nodes.
    
    Approach: DFS with cycle detection
    Time: O(V + E), Space: O(V)
    """
    n = len(graph)
    # 0 = unvisited, 1 = visiting (unsafe), 2 = safe
    state = [0] * n
    
    def dfs(node):
        if state[node] != 0:
            return state[node] == 2
        
        state[node] = 1  # Mark as visiting
        
        for neighbor in graph[node]:
            if not dfs(neighbor):
                return False
        
        state[node] = 2  # Mark as safe
        return True
    
    return [i for i in range(n) if dfs(i)]

# Example
graph = [[1,2],[2,3],[5],[0],[5],[],[]]
print(eventualSafeNodes(graph))  # [2,4,5,6]
```

### 23. Is Graph Bipartite
```python
def isBipartite(graph):
    """
    Check if graph can be 2-colored (bipartite).
    
    Approach: BFS/DFS with 2-coloring
    Time: O(V + E), Space: O(V)
    """
    n = len(graph)
    colors = [-1] * n  # -1 = uncolored, 0/1 = colors
    
    def bfs(start):
        from collections import deque
        queue = deque([start])
        colors[start] = 0
        
        while queue:
            node = queue.popleft()
            
            for neighbor in graph[node]:
                if colors[neighbor] == -1:
                    colors[neighbor] = 1 - colors[node]
                    queue.append(neighbor)
                elif colors[neighbor] == colors[node]:
                    return False
        
        return True
    
    for i in range(n):
        if colors[i] == -1:
            if not bfs(i):
                return False
    
    return True

# DFS approach
def isBipartite_dfs(graph):
    n = len(graph)
    colors = [-1] * n
    
    def dfs(node, color):
        colors[node] = color
        
        for neighbor in graph[node]:
            if colors[neighbor] == -1:
                if not dfs(neighbor, 1 - color):
                    return False
            elif colors[neighbor] == color:
                return False
        
        return True
    
    for i in range(n):
        if colors[i] == -1:
            if not dfs(i, 0):
                return False
    
    return True

# Example
print(isBipartite([[1,3],[0,2],[1,3],[0,2]]))  # True
```

### 24. Detect Cycle in Directed Graph
```python
def hasCycle(graph):
    """
    Detect cycle in directed graph.
    
    Approach: DFS with 3-state coloring
    Time: O(V + E), Space: O(V)
    """
    n = len(graph)
    # 0 = unvisited, 1 = visiting, 2 = visited
    state = [0] * n
    
    def dfs(node):
        if state[node] == 1:
            return True  # Cycle detected
        if state[node] == 2:
            return False
        
        state[node] = 1
        
        for neighbor in graph[node]:
            if dfs(neighbor):
                return True
        
        state[node] = 2
        return False
    
    for i in range(n):
        if state[i] == 0:
            if dfs(i):
                return True
    
    return False

# Example
graph = [[1],[2],[0]]
print(hasCycle(graph))  # True
```

### 25. Topological Sort
```python
def topologicalSort(graph):
    """
    Return topological ordering of DAG.
    
    Approach 1: DFS
    Time: O(V + E), Space: O(V)
    """
    n = len(graph)
    visited = [False] * n
    stack = []
    
    def dfs(node):
        visited[node] = True
        
        for neighbor in graph[node]:
            if not visited[neighbor]:
                dfs(neighbor)
        
        stack.append(node)
    
    for i in range(n):
        if not visited[i]:
            dfs(i)
    
    return stack[::-1]

# Kahn's Algorithm (BFS)
def topologicalSort_kahn(graph):
    from collections import deque
    
    n = len(graph)
    in_degree = [0] * n
    
    for node in range(n):
        for neighbor in graph[node]:
            in_degree[neighbor] += 1
    
    queue = deque([i for i in range(n) if in_degree[i] == 0])
    result = []
    
    while queue:
        node = queue.popleft()
        result.append(node)
        
        for neighbor in graph[node]:
            in_degree[neighbor] -= 1
            if in_degree[neighbor] == 0:
                queue.append(neighbor)
    
    return result if len(result) == n else []  # [] if cycle

# Example
graph = [[],[],[3],[1],[0,1],[0,2]]
print(topologicalSort(graph))  # [5,4,2,3,1,0] or similar
```

### 26. Dijkstra's Algorithm
```python
def dijkstra(graph, start):
    """
    Find shortest paths from start to all nodes.
    
    Time: O(E log V), Space: O(V)
    """
    import heapq
    
    n = len(graph)
    dist = [float('inf')] * n
    dist[start] = 0
    
    # (distance, node)
    min_heap = [(0, start)]
    
    while min_heap:
        d, node = heapq.heappop(min_heap)
        
        if d > dist[node]:
            continue
        
        for neighbor, weight in graph[node]:
            new_dist = d + weight
            if new_dist < dist[neighbor]:
                dist[neighbor] = new_dist
                heapq.heappush(min_heap, (new_dist, neighbor))
    
    return dist

# Example with adjacency list
graph = [
    [(1, 4), (2, 1)],  # 0 -> 1 (weight 4), 0 -> 2 (weight 1)
    [(3, 1)],          # 1 -> 3 (weight 1)
    [(1, 2), (3, 5)],  # 2 -> 1 (weight 2), 2 -> 3 (weight 5)
    []                 # 3 has no outgoing edges
]
print(dijkstra(graph, 0))  # [0, 3, 1, 4]
```

### 27. Bellman-Ford Algorithm
```python
def bellmanFord(edges, n, start):
    """
    Find shortest paths, detects negative cycles.
    
    Time: O(V * E), Space: O(V)
    """
    dist = [float('inf')] * n
    dist[start] = 0
    
    # Relax edges V-1 times
    for _ in range(n - 1):
        for u, v, w in edges:
            if dist[u] != float('inf') and dist[u] + w < dist[v]:
                dist[v] = dist[u] + w
    
    # Check for negative cycles
    for u, v, w in edges:
        if dist[u] != float('inf') and dist[u] + w < dist[v]:
            return None  # Negative cycle detected
    
    return dist

# Example
edges = [(0, 1, 4), (0, 2, 1), (2, 1, 2), (1, 3, 1), (2, 3, 5)]
print(bellmanFord(edges, 4, 0))  # [0, 3, 1, 4]
```

### 28. Floyd-Warshall Algorithm
```python
def floydWarshall(graph):
    """
    Find shortest paths between all pairs of nodes.
    
    Time: O(V^3), Space: O(V^2)
    """
    n = len(graph)
    dist = [row[:] for row in graph]  # Deep copy
    
    # Initialize with direct edges
    for i in range(n):
        for j in range(n):
            if i == j:
                dist[i][j] = 0
            elif dist[i][j] == 0:
                dist[i][j] = float('inf')
    
    # Try all intermediate nodes
    for k in range(n):
        for i in range(n):
            for j in range(n):
                dist[i][j] = min(dist[i][j], dist[i][k] + dist[k][j])
    
    return dist

# Example
INF = float('inf')
graph = [
    [0, 3, INF, 7],
    [8, 0, 2, INF],
    [5, INF, 0, 1],
    [2, INF, INF, 0]
]
print(floydWarshall(graph))
```

### 29. Prim's Algorithm
```python
def prim(graph):
    """
    Find Minimum Spanning Tree.
    
    Time: O(E log V), Space: O(V)
    """
    import heapq
    
    n = len(graph)
    visited = [False] * n
    min_heap = [(0, 0)]  # (weight, node)
    total_cost = 0
    mst_edges = []
    
    while min_heap and len(mst_edges) < n - 1:
        weight, node = heapq.heappop(min_heap)
        
        if visited[node]:
            continue
        
        visited[node] = True
        total_cost += weight
        
        for neighbor, edge_weight in graph[node]:
            if not visited[neighbor]:
                heapq.heappush(min_heap, (edge_weight, neighbor))
    
    return total_cost

# Example
graph = [
    [(1, 2), (3, 6)],
    [(0, 2), (2, 3), (3, 8), (4, 5)],
    [(1, 3), (4, 7)],
    [(0, 6), (1, 8)],
    [(1, 5), (2, 7)]
]
print(prim(graph))  # 16
```

### 30. Kruskal's Algorithm
```python
def kruskal(n, edges):
    """
    Find Minimum Spanning Tree using Union-Find.
    
    Time: O(E log E), Space: O(V)
    """
    parent = list(range(n))
    
    def find(x):
        if parent[x] != x:
            parent[x] = find(parent[x])
        return parent[x]
    
    def union(x, y):
        px, py = find(x), find(y)
        if px != py:
            parent[px] = py
            return True
        return False
    
    # Sort edges by weight
    edges.sort(key=lambda x: x[2])
    
    total_cost = 0
    mst_edges = []
    
    for u, v, weight in edges:
        if union(u, v):
            total_cost += weight
            mst_edges.append((u, v, weight))
            
            if len(mst_edges) == n - 1:
                break
    
    return total_cost, mst_edges

# Example
edges = [(0,1,2), (0,3,6), (1,2,3), (1,3,8), (1,4,5), (2,4,7)]
print(kruskal(5, edges))  # (16, [(0,1,2), (1,2,3), (1,4,5), (0,3,6)])
```

### 31. Union-Find (Disjoint Set Union)
```python
class UnionFind:
    """
    Union-Find data structure with path compression and union by rank.
    
    Time: O(α(n)) per operation, Space: O(n)
    """
    def __init__(self, n):
        self.parent = list(range(n))
        self.rank = [0] * n
        self.components = n
    
    def find(self, x):
        """Find with path compression"""
        if self.parent[x] != x:
            self.parent[x] = self.find(self.parent[x])
        return self.parent[x]
    
    def union(self, x, y):
        """Union by rank"""
        px, py = self.find(x), self.find(y)
        
        if px == py:
            return False
        
        if self.rank[px] < self.rank[py]:
            self.parent[px] = py
        elif self.rank[px] > self.rank[py]:
            self.parent[py] = px
        else:
            self.parent[py] = px
            self.rank[px] += 1
        
        self.components -= 1
        return True
    
    def connected(self, x, y):
        """Check if x and y are in same set"""
        return self.find(x) == self.find(y)
    
    def count_components(self):
        """Return number of disjoint sets"""
        return self.components

# Example usage
uf = UnionFind(5)
uf.union(0, 1)
uf.union(1, 2)
print(uf.connected(0, 2))  # True
print(uf.count_components())  # 3
```

### 32. Strongly Connected Components (Kosaraju's Algorithm)
```python
def stronglyConnectedComponents(graph):
    """
    Find all SCCs in directed graph.
    
    Time: O(V + E), Space: O(V)
    """
    n = len(graph)
    
    # Step 1: Fill order based on finish times (DFS)
    visited = [False] * n
    stack = []
    
    def dfs1(node):
        visited[node] = True
        for neighbor in graph[node]:
            if not visited[neighbor]:
                dfs1(neighbor)
        stack.append(node)
    
    for i in range(n):
        if not visited[i]:
            dfs1(i)
    
    # Step 2: Create transpose graph
    transpose = [[] for _ in range(n)]
    for u in range(n):
        for v in graph[u]:
            transpose[v].append(u)
    
    # Step 3: DFS on transpose in reverse finish order
    visited = [False] * n
    sccs = []
    
    def dfs2(node, scc):
        visited[node] = True
        scc.append(node)
        for neighbor in transpose[node]:
            if not visited[neighbor]:
                dfs2(neighbor, scc)
    
    while stack:
        node = stack.pop()
        if not visited[node]:
            scc = []
            dfs2(node, scc)
            sccs.append(scc)
    
    return sccs

# Example
graph = [[1],[2],[0],[4],[5],[3]]
print(stronglyConnectedComponents(graph))  # [[0,1,2], [3,4,5]]
```

### 33. Tarjan's Algorithm (SCC)
```python
def tarjanSCC(graph):
    """
    Find SCCs using Tarjan's algorithm (single DFS).
    
    Time: O(V + E), Space: O(V)
    """
    n = len(graph)
    disc = [-1] * n  # Discovery time
    low = [-1] * n   # Lowest reachable
    on_stack = [False] * n
    stack = []
    time = [0]
    sccs = []
    
    def dfs(node):
        disc[node] = low[node] = time[0]
        time[0] += 1
        stack.append(node)
        on_stack[node] = True
        
        for neighbor in graph[node]:
            if disc[neighbor] == -1:
                dfs(neighbor)
                low[node] = min(low[node], low[neighbor])
            elif on_stack[neighbor]:
                low[node] = min(low[node], disc[neighbor])
        
        # Root of SCC
        if low[node] == disc[node]:
            scc = []
            while True:
                v = stack.pop()
                on_stack[v] = False
                scc.append(v)
                if v == node:
                    break
            sccs.append(scc)
    
    for i in range(n):
        if disc[i] == -1:
            dfs(i)
    
    return sccs

# Example
graph = [[1],[2],[0],[4],[5],[3]]
print(tarjanSCC(graph))  # [[2,1,0], [5,4,3]]
```

### 34. Articulation Points (Cut Vertices)
```python
def findArticulationPoints(graph):
    """
    Find articulation points in undirected graph.
    
    Time: O(V + E), Space: O(V)
    """
    n = len(graph)
    disc = [-1] * n
    low = [-1] * n
    parent = [-1] * n
    ap = [False] * n
    time = [0]
    
    def dfs(u):
        children = 0
        disc[u] = low[u] = time[0]
        time[0] += 1
        
        for v in graph[u]:
            if disc[v] == -1:
                children += 1
                parent[v] = u
                dfs(v)
                
                low[u] = min(low[u], low[v])
                
                # u is AP if:
                # 1. u is root and has 2+ children
                # 2. u is not root and low[v] >= disc[u]
                if parent[u] == -1 and children > 1:
                    ap[u] = True
                if parent[u] != -1 and low[v] >= disc[u]:
                    ap[u] = True
            
            elif v != parent[u]:
                low[u] = min(low[u], disc[v])
    
    for i in range(n):
        if disc[i] == -1:
            dfs(i)
    
    return [i for i in range(n) if ap[i]]

# Example
graph = [[1,2],[0,2],[0,1,3],[2]]
print(findArticulationPoints(graph))  # [2]
```

### 35. Bridges in Graph
```python
def findBridges(graph):
    """
    Find bridges (critical edges) in undirected graph.
    
    Time: O(V + E), Space: O(V)
    """
    n = len(graph)
    disc = [-1] * n
    low = [-1] * n
    parent = [-1] * n
    time = [0]
    bridges = []
    
    def dfs(u):
        disc[u] = low[u] = time[0]
        time[0] += 1
        
        for v in graph[u]:
            if disc[v] == -1:
                parent[v] = u
                dfs(v)
                
                low[u] = min(low[u], low[v])
                
                # Bridge condition: low[v] > disc[u]
                if low[v] > disc[u]:
                    bridges.append((u, v))
            
            elif v != parent[u]:
                low[u] = min(low[u], disc[v])
    
    for i in range(n):
        if disc[i] == -1:
            dfs(i)
    
    return bridges

# Example
graph = [[1],[0,2],[1,3],[2]]
print(findBridges(graph))  # [(2,3), (1,2), (0,1)]
```

---

## Summary of Key Concepts

### Hashing Techniques:
1. **Hash Maps/Sets**: O(1) average lookup
2. **Sliding Window**: For substring/subarray problems
3. **Prefix Sum**: For subarray sum problems
4. **Anagram Detection**: Sort or character count
5. **LRU/LFU**: Combine hash map + linked list

### Graph Algorithms:
1. **DFS/BFS**: Basic traversal
2. **Topological Sort**: DAG ordering (Kahn's/DFS)
3. **Shortest Path**: Dijkstra, Bellman-Ford, Floyd-Warshall
4. **MST**: Prim's, Kruskal's
5. **Cycle Detection**: 3-state coloring
6. **Bipartite**: 2-coloring
7. **SCC**: Kosaraju's, Tarjan's
8. **Bridges/Articulation Points**: Tarjan-based

# DSA Questions - Dynamic Programming, Backtracking, Tries, and Greedy

I'll provide solutions for all questions with detailed explanations.

---

## 9. Dynamic Programming (40 Questions)

### 1. Climbing Stairs

**Problem:** Count ways to climb n stairs (1 or 2 steps at a time)

```python
def climbStairs(n: int) -> int:
    """
    At each step, we can come from step (i-1) or (i-2)
    dp[i] = dp[i-1] + dp[i-2]
    
    Time: O(n), Space: O(1)
    """
    if n <= 2:
        return n
    
    prev2, prev1 = 1, 2
    
    for i in range(3, n + 1):
        current = prev1 + prev2
        prev2 = prev1
        prev1 = current
    
    return prev1

# Example
print(climbStairs(5))  # 8
```

---

### 2. House Robber

**Problem:** Rob houses to maximize money without robbing adjacent houses

```python
def rob(nums: list[int]) -> int:
    """
    At each house: rob it (skip previous) or don't rob it
    dp[i] = max(dp[i-1], nums[i] + dp[i-2])
    
    Time: O(n), Space: O(1)
    """
    if not nums:
        return 0
    if len(nums) == 1:
        return nums[0]
    
    prev2, prev1 = 0, 0
    
    for num in nums:
        current = max(prev1, num + prev2)
        prev2 = prev1
        prev1 = current
    
    return prev1

# Example
print(rob([2, 7, 9, 3, 1]))  # 12 (2 + 9 + 1)
```

---

### 3. House Robber II

**Problem:** Houses arranged in circle (first and last are adjacent)

```python
def rob2(nums: list[int]) -> int:
    """
    Circle constraint: can't rob both first and last house
    Solution: run House Robber I twice:
    1. Skip first house (rob 1 to n-1)
    2. Skip last house (rob 0 to n-2)
    
    Time: O(n), Space: O(1)
    """
    def rob_linear(houses):
        prev2, prev1 = 0, 0
        for num in houses:
            current = max(prev1, num + prev2)
            prev2, prev1 = prev1, current
        return prev1
    
    if len(nums) == 1:
        return nums[0]
    
    # Skip first or skip last
    return max(rob_linear(nums[1:]), rob_linear(nums[:-1]))

# Example
print(rob2([2, 3, 2]))  # 3
```

---

### 4. Coin Change

**Problem:** Minimum coins needed to make amount

```python
def coinChange(coins: list[int], amount: int) -> int:
    """
    dp[i] = minimum coins to make amount i
    For each amount, try all coins:
    dp[i] = min(dp[i], dp[i - coin] + 1)
    
    Time: O(amount * coins), Space: O(amount)
    """
    dp = [float('inf')] * (amount + 1)
    dp[0] = 0
    
    for i in range(1, amount + 1):
        for coin in coins:
            if coin <= i:
                dp[i] = min(dp[i], dp[i - coin] + 1)
    
    return dp[amount] if dp[amount] != float('inf') else -1

# Example
print(coinChange([1, 2, 5], 11))  # 3 (5+5+1)
```

---

### 5. Coin Change II

**Problem:** Count ways to make amount with coins

```python
def change(amount: int, coins: list[int]) -> int:
    """
    dp[i] = number of ways to make amount i
    For each coin, update all amounts that can use it
    
    Time: O(amount * coins), Space: O(amount)
    """
    dp = [0] * (amount + 1)
    dp[0] = 1  # One way to make 0: use no coins
    
    # For each coin type
    for coin in coins:
        # Update all amounts >= coin
        for i in range(coin, amount + 1):
            dp[i] += dp[i - coin]
    
    return dp[amount]

# Example
print(change(5, [1, 2, 5]))  # 4 ways
```

---

### 6. Longest Increasing Subsequence

**Problem:** Find length of longest increasing subsequence

```python
def lengthOfLIS(nums: list[int]) -> int:
    """
    Method 1: DP - O(n²)
    dp[i] = length of LIS ending at i
    
    Method 2: Binary Search - O(n log n)
    Maintain array of smallest tail elements
    """
    # Method 1: DP
    def dp_solution(nums):
        if not nums:
            return 0
        
        dp = [1] * len(nums)
        
        for i in range(1, len(nums)):
            for j in range(i):
                if nums[i] > nums[j]:
                    dp[i] = max(dp[i], dp[j] + 1)
        
        return max(dp)
    
    # Method 2: Binary Search (optimal)
    def binary_search_solution(nums):
        from bisect import bisect_left
        
        tails = []  # tails[i] = smallest tail of LIS of length i+1
        
        for num in nums:
            pos = bisect_left(tails, num)
            if pos == len(tails):
                tails.append(num)
            else:
                tails[pos] = num
        
        return len(tails)
    
    return binary_search_solution(nums)

# Example
print(lengthOfLIS([10, 9, 2, 5, 3, 7, 101, 18]))  # 4
```

---

### 7. Longest Common Subsequence

**Problem:** Find LCS of two strings

```python
def longestCommonSubsequence(text1: str, text2: str) -> int:
    """
    dp[i][j] = LCS of text1[0:i] and text2[0:j]
    
    If text1[i-1] == text2[j-1]:
        dp[i][j] = dp[i-1][j-1] + 1
    Else:
        dp[i][j] = max(dp[i-1][j], dp[i][j-1])
    
    Time: O(m*n), Space: O(m*n)
    """
    m, n = len(text1), len(text2)
    dp = [[0] * (n + 1) for _ in range(m + 1)]
    
    for i in range(1, m + 1):
        for j in range(1, n + 1):
            if text1[i-1] == text2[j-1]:
                dp[i][j] = dp[i-1][j-1] + 1
            else:
                dp[i][j] = max(dp[i-1][j], dp[i][j-1])
    
    return dp[m][n]

# Example
print(longestCommonSubsequence("abcde", "ace"))  # 3
```

---

### 8. Longest Palindromic Subsequence

**Problem:** Find length of longest palindromic subsequence

```python
def longestPalindromeSubseq(s: str) -> int:
    """
    LPS of s = LCS of s and reverse(s)
    
    Or use 2D DP:
    dp[i][j] = LPS of s[i:j+1]
    
    Time: O(n²), Space: O(n²)
    """
    n = len(s)
    dp = [[0] * n for _ in range(n)]
    
    # Every single character is palindrome of length 1
    for i in range(n):
        dp[i][i] = 1
    
    # Check substrings of increasing length
    for length in range(2, n + 1):
        for i in range(n - length + 1):
            j = i + length - 1
            
            if s[i] == s[j]:
                dp[i][j] = dp[i+1][j-1] + 2
            else:
                dp[i][j] = max(dp[i+1][j], dp[i][j-1])
    
    return dp[0][n-1]

# Example
print(longestPalindromeSubseq("bbbab"))  # 4 ("bbbb")
```

---

### 9. Edit Distance

**Problem:** Minimum operations to convert word1 to word2

```python
def minDistance(word1: str, word2: str) -> int:
    """
    Operations: insert, delete, replace
    dp[i][j] = edit distance for word1[0:i] and word2[0:j]
    
    If word1[i-1] == word2[j-1]:
        dp[i][j] = dp[i-1][j-1]
    Else:
        dp[i][j] = 1 + min(
            dp[i-1][j],    # delete
            dp[i][j-1],    # insert
            dp[i-1][j-1]   # replace
        )
    
    Time: O(m*n), Space: O(m*n)
    """
    m, n = len(word1), len(word2)
    dp = [[0] * (n + 1) for _ in range(m + 1)]
    
    # Base cases
    for i in range(m + 1):
        dp[i][0] = i
    for j in range(n + 1):
        dp[0][j] = j
    
    for i in range(1, m + 1):
        for j in range(1, n + 1):
            if word1[i-1] == word2[j-1]:
                dp[i][j] = dp[i-1][j-1]
            else:
                dp[i][j] = 1 + min(
                    dp[i-1][j],      # delete
                    dp[i][j-1],      # insert
                    dp[i-1][j-1]     # replace
                )
    
    return dp[m][n]

# Example
print(minDistance("horse", "ros"))  # 3
```

---

### 10. Unique Paths

**Problem:** Count paths in grid from top-left to bottom-right

```python
def uniquePaths(m: int, n: int) -> int:
    """
    dp[i][j] = paths to reach cell (i, j)
    dp[i][j] = dp[i-1][j] + dp[i][j-1]
    
    Time: O(m*n), Space: O(n)
    """
    dp = [1] * n  # First row all 1s
    
    for i in range(1, m):
        for j in range(1, n):
            dp[j] += dp[j-1]
    
    return dp[n-1]

# Example
print(uniquePaths(3, 7))  # 28
```

---

### 11. Unique Paths II

**Problem:** Unique paths with obstacles

```python
def uniquePathsWithObstacles(obstacleGrid: list[list[int]]) -> int:
    """
    If cell has obstacle: dp[i][j] = 0
    Else: dp[i][j] = dp[i-1][j] + dp[i][j-1]
    
    Time: O(m*n), Space: O(n)
    """
    if not obstacleGrid or obstacleGrid[0][0] == 1:
        return 0
    
    m, n = len(obstacleGrid), len(obstacleGrid[0])
    dp = [0] * n
    dp[0] = 1
    
    for i in range(m):
        for j in range(n):
            if obstacleGrid[i][j] == 1:
                dp[j] = 0
            elif j > 0:
                dp[j] += dp[j-1]
    
    return dp[n-1]

# Example
grid = [[0,0,0],[0,1,0],[0,0,0]]
print(uniquePathsWithObstacles(grid))  # 2
```

---

### 12. Minimum Path Sum

**Problem:** Find path with minimum sum from top-left to bottom-right

```python
def minPathSum(grid: list[list[int]]) -> int:
    """
    dp[i][j] = minimum sum to reach (i, j)
    dp[i][j] = grid[i][j] + min(dp[i-1][j], dp[i][j-1])
    
    Time: O(m*n), Space: O(n)
    """
    if not grid:
        return 0
    
    m, n = len(grid), len(grid[0])
    dp = [float('inf')] * n
    dp[0] = 0
    
    for i in range(m):
        dp[0] += grid[i][0]
        for j in range(1, n):
            dp[j] = grid[i][j] + min(dp[j], dp[j-1])
    
    return dp[n-1]

# Example
grid = [[1,3,1],[1,5,1],[4,2,1]]
print(minPathSum(grid))  # 7
```

---

### 13. Maximal Square

**Problem:** Find largest square containing only 1s

```python
def maximalSquare(matrix: list[list[str]]) -> int:
    """
    dp[i][j] = side length of largest square with bottom-right at (i,j)
    
    If matrix[i][j] == '1':
        dp[i][j] = min(dp[i-1][j], dp[i][j-1], dp[i-1][j-1]) + 1
    
    Time: O(m*n), Space: O(n)
    """
    if not matrix:
        return 0
    
    m, n = len(matrix), len(matrix[0])
    dp = [0] * (n + 1)
    max_side = 0
    prev = 0
    
    for i in range(1, m + 1):
        for j in range(1, n + 1):
            temp = dp[j]
            if matrix[i-1][j-1] == '1':
                dp[j] = min(dp[j], dp[j-1], prev) + 1
                max_side = max(max_side, dp[j])
            else:
                dp[j] = 0
            prev = temp
    
    return max_side * max_side

# Example
matrix = [["1","0","1","0","0"],
          ["1","0","1","1","1"],
          ["1","1","1","1","1"],
          ["1","0","0","1","0"]]
print(maximalSquare(matrix))  # 4
```

---

### 14. Decode Ways

**Problem:** Count ways to decode a digit string to letters (1=A, 2=B, ..., 26=Z)

```python
def numDecodings(s: str) -> int:
    """
    dp[i] = ways to decode s[0:i]
    
    Single digit (1-9): add dp[i-1]
    Two digits (10-26): add dp[i-2]
    
    Time: O(n), Space: O(1)
    """
    if not s or s[0] == '0':
        return 0
    
    n = len(s)
    prev2, prev1 = 1, 1
    
    for i in range(1, n):
        current = 0
        
        # Single digit decode
        if s[i] != '0':
            current += prev1
        
        # Two digit decode
        two_digit = int(s[i-1:i+1])
        if 10 <= two_digit <= 26:
            current += prev2
        
        prev2, prev1 = prev1, current
    
    return prev1

# Example
print(numDecodings("226"))  # 3 ("BZ", "VF", "BBF")
```

---

### 15. Jump Game

**Problem:** Can you reach the last index?

```python
def canJump(nums: list[int]) -> bool:
    """
    Greedy approach: track maximum reachable index
    
    Time: O(n), Space: O(1)
    """
    max_reach = 0
    
    for i in range(len(nums)):
        if i > max_reach:
            return False
        max_reach = max(max_reach, i + nums[i])
        if max_reach >= len(nums) - 1:
            return True
    
    return True

# Example
print(canJump([2,3,1,1,4]))  # True
print(canJump([3,2,1,0,4]))  # False
```

---

### 16. Jump Game II

**Problem:** Minimum jumps to reach last index

```python
def jump(nums: list[int]) -> int:
    """
    BFS-like approach: track current level's max reach
    
    Time: O(n), Space: O(1)
    """
    if len(nums) <= 1:
        return 0
    
    jumps = 0
    current_end = 0
    farthest = 0
    
    for i in range(len(nums) - 1):
        farthest = max(farthest, i + nums[i])
        
        if i == current_end:
            jumps += 1
            current_end = farthest
            
            if current_end >= len(nums) - 1:
                break
    
    return jumps

# Example
print(jump([2,3,1,1,4]))  # 2
```

---

### 17. Partition Equal Subset Sum

**Problem:** Can array be partitioned into two equal sum subsets?

```python
def canPartition(nums: list[int]) -> bool:
    """
    This is 0/1 knapsack problem
    Target = sum(nums) / 2
    dp[i] = can we make sum i?
    
    Time: O(n * sum), Space: O(sum)
    """
    total = sum(nums)
    
    if total % 2:
        return False
    
    target = total // 2
    dp = [False] * (target + 1)
    dp[0] = True
    
    for num in nums:
        # Traverse backwards to avoid using same element twice
        for i in range(target, num - 1, -1):
            dp[i] = dp[i] or dp[i - num]
    
    return dp[target]

# Example
print(canPartition([1,5,11,5]))  # True (11 = 11)
```

---

### 18. Word Break

**Problem:** Can string be segmented into dictionary words?

```python
def wordBreak(s: str, wordDict: list[str]) -> bool:
    """
    dp[i] = can s[0:i] be segmented?
    
    For each position i, check all words ending at i
    
    Time: O(n² * m), Space: O(n)
    where m = average word length
    """
    word_set = set(wordDict)
    dp = [False] * (len(s) + 1)
    dp[0] = True
    
    for i in range(1, len(s) + 1):
        for j in range(i):
            if dp[j] and s[j:i] in word_set:
                dp[i] = True
                break
    
    return dp[len(s)]

# Example
print(wordBreak("leetcode", ["leet", "code"]))  # True
```

---

### 19. Palindrome Partitioning

**Problem:** Partition string into palindromic substrings (backtracking version in that section)

```python
def partition(s: str) -> list[list[str]]:
    """
    Use backtracking to find all partitions
    Use DP to precompute palindrome checks
    
    Time: O(n * 2^n), Space: O(n²)
    """
    n = len(s)
    
    # Precompute palindrome checks
    is_palindrome = [[False] * n for _ in range(n)]
    for i in range(n):
        is_palindrome[i][i] = True
    
    for length in range(2, n + 1):
        for i in range(n - length + 1):
            j = i + length - 1
            if s[i] == s[j]:
                is_palindrome[i][j] = (length == 2) or is_palindrome[i+1][j-1]
    
    result = []
    
    def backtrack(start, path):
        if start == n:
            result.append(path[:])
            return
        
        for end in range(start, n):
            if is_palindrome[start][end]:
                path.append(s[start:end+1])
                backtrack(end + 1, path)
                path.pop()
    
    backtrack(0, [])
    return result

# Example
print(partition("aab"))  # [["a","a","b"], ["aa","b"]]
```

---

### 20. Burst Balloons

**Problem:** Maximum coins from bursting balloons

```python
def maxCoins(nums: list[int]) -> int:
    """
    Add 1 to both ends, treat as virtual balloons
    dp[i][j] = max coins from bursting balloons (i, j) (exclusive)
    
    For each k in (i, j), burst k last:
    dp[i][j] = max(dp[i][j], 
                   dp[i][k] + nums[i]*nums[k]*nums[j] + dp[k][j])
    
    Time: O(n³), Space: O(n²)
    """
    nums = [1] + nums + [1]
    n = len(nums)
    dp = [[0] * n for _ in range(n)]
    
    # length is the gap between i and j
    for length in range(2, n):
        for i in range(n - length):
            j = i + length
            for k in range(i + 1, j):
                dp[i][j] = max(
                    dp[i][j],
                    dp[i][k] + nums[i] * nums[k] * nums[j] + dp[k][j]
                )
    
    return dp[0][n-1]

# Example
print(maxCoins([3,1,5,8]))  # 167
```

---

### 21. Target Sum

**Problem:** Count ways to add +/- to reach target

```python
def findTargetSumWays(nums: list[int], target: int) -> int:
    """
    Transform to subset sum problem:
    sum(P) - sum(N) = target
    sum(P) + sum(N) = sum(nums)
    => sum(P) = (target + sum(nums)) / 2
    
    Count subsets with this sum
    
    Time: O(n * sum), Space: O(sum)
    """
    total = sum(nums)
    
    if abs(target) > total or (target + total) % 2:
        return 0
    
    sum_p = (target + total) // 2
    dp = [0] * (sum_p + 1)
    dp[0] = 1
    
    for num in nums:
        for i in range(sum_p, num - 1, -1):
            dp[i] += dp[i - num]
    
    return dp[sum_p]

# Example
print(findTargetSumWays([1,1,1,1,1], 3))  # 5
```

---

### 22. Combination Sum IV

**Problem:** Count combinations that sum to target (order matters)

```python
def combinationSum4(nums: list[int], target: int) -> int:
    """
    dp[i] = number of combinations to make sum i
    
    For each sum, try all numbers
    
    Time: O(target * n), Space: O(target)
    """
    dp = [0] * (target + 1)
    dp[0] = 1
    
    for i in range(1, target + 1):
        for num in nums:
            if num <= i:
                dp[i] += dp[i - num]
    
    return dp[target]

# Example
print(combinationSum4([1,2,3], 4))  # 7
```

---

### 23. Best Time to Buy and Sell Stock II

**Problem:** Multiple transactions allowed

```python
def maxProfit2(prices: list[int]) -> int:
    """
    Greedy: add all positive differences
    
    Time: O(n), Space: O(1)
    """
    profit = 0
    
    for i in range(1, len(prices)):
        if prices[i] > prices[i-1]:
            profit += prices[i] - prices[i-1]
    
    return profit

# Example
print(maxProfit2([7,1,5,3,6,4]))  # 7
```

---

### 24. Best Time to Buy and Sell Stock III

**Problem:** At most 2 transactions

```python
def maxProfit3(prices: list[int]) -> int:
    """
    Track 4 states:
    - buy1: max profit after first buy
    - sell1: max profit after first sell
    - buy2: max profit after second buy
    - sell2: max profit after second sell
    
    Time: O(n), Space: O(1)
    """
    buy1 = buy2 = float('-inf')
    sell1 = sell2 = 0
    
    for price in prices:
        buy1 = max(buy1, -price)
        sell1 = max(sell1, buy1 + price)
        buy2 = max(buy2, sell1 - price)
        sell2 = max(sell2, buy2 + price)
    
    return sell2

# Example
print(maxProfit3([3,3,5,0,0,3,1,4]))  # 6
```

---

### 25. Best Time to Buy and Sell Stock IV

**Problem:** At most k transactions

```python
def maxProfit4(k: int, prices: list[int]) -> int:
    """
    If k >= n/2, it's unlimited transactions
    
    Otherwise, use DP:
    buy[i][j] = max profit after at most i transactions, last action is buy
    sell[i][j] = max profit after at most i transactions, last action is sell
    
    Time: O(n*k), Space: O(k)
    """
    if not prices or k == 0:
        return 0
    
    n = len(prices)
    
    # If k >= n/2, unlimited transactions
    if k >= n // 2:
        profit = 0
        for i in range(1, n):
            profit += max(0, prices[i] - prices[i-1])
        return profit
    
    # DP solution
    buy = [float('-inf')] * (k + 1)
    sell = [0] * (k + 1)
    
    for price in prices:
        for i in range(k, 0, -1):
            sell[i] = max(sell[i], buy[i] + price)
            buy[i] = max(buy[i], sell[i-1] - price)
    
    return sell[k]

# Example
print(maxProfit4(2, [3,2,6,5,0,3]))  # 7
```

---

### 26. Best Time to Buy and Sell Stock with Cooldown

**Problem:** After selling, must cooldown 1 day

```python
def maxProfitCooldown(prices: list[int]) -> int:
    """
    Three states:
    - hold: currently holding stock
    - sold: just sold stock
    - rest: not holding stock, not in cooldown
    
    Time: O(n), Space: O(1)
    """
    if len(prices) <= 1:
        return 0
    
    hold = -prices[0]
    sold = 0
    rest = 0
    
    for i in range(1, len(prices)):
        prev_hold, prev_sold, prev_rest = hold, sold, rest
        
        hold = max(prev_hold, prev_rest - prices[i])
        sold = prev_hold + prices[i]
        rest = max(prev_rest, prev_sold)
    
    return max(sold, rest)

# Example
print(maxProfitCooldown([1,2,3,0,2]))  # 3
```

---

### 27. Best Time to Buy and Sell Stock with Transaction Fee

**Problem:** Pay fee on each transaction

```python
def maxProfitFee(prices: list[int], fee: int) -> int:
    """
    Two states:
    - hold: holding stock
    - cash: not holding stock
    
    Time: O(n), Space: O(1)
    """
    cash = 0
    hold = -prices[0]
    
    for i in range(1, len(prices)):
        cash = max(cash, hold + prices[i] - fee)
        hold = max(hold, cash - prices[i])
    
    return cash

# Example
print(maxProfitFee([1,3,2,8,4,9], 2))  # 8
```

---

### 28. Maximum Product Subarray

**Problem:** Find contiguous subarray with maximum product

```python
def maxProduct(nums: list[int]) -> int:
    """
    Track both max and min (negative * negative = positive)
    
    Time: O(n), Space: O(1)
    """
    if not nums:
        return 0
    
    max_prod = min_prod = result = nums[0]
    
    for i in range(1, len(nums)):
        num = nums[i]
        
        # When multiplied by negative, swap max and min
        if num < 0:
            max_prod, min_prod = min_prod, max_prod
        
        max_prod = max(num, max_prod * num)
        min_prod = min(num, min_prod * num)
        
        result = max(result, max_prod)
    
    return result

# Example
print(maxProduct([2,3,-2,4]))  # 6
```

---

### 29. Longest Valid Parentheses

**Problem:** Find length of longest valid parentheses substring

```python
def longestValidParentheses(s: str) -> int:
    """
    Method 1: DP
    dp[i] = length of longest valid ending at i
    
    Method 2: Stack (track indices)
    
    Time: O(n), Space: O(n)
    """
    # Method 1: DP
    def dp_solution(s):
        if not s:
            return 0
        
        dp = [0] * len(s)
        max_len = 0
        
        for i in range(1, len(s)):
            if s[i] == ')':
                if s[i-1] == '(':
                    dp[i] = (dp[i-2] if i >= 2 else 0) + 2
                elif i - dp[i-1] > 0 and s[i - dp[i-1] - 1] == '(':
                    dp[i] = dp[i-1] + 2 + (dp[i - dp[i-1] - 2] if i - dp[i-1] >= 2 else 0)
                
                max_len = max(max_len, dp[i])
        
        return max_len
    
    # Method 2: Stack
    def stack_solution(s):
        stack = [-1]
        max_len = 0
        
        for i, char in enumerate(s):
            if char == '(':
                stack.append(i)
            else:
                stack.pop()
                if not stack:
                    stack.append(i)
                else:
                    max_len = max(max_len, i - stack[-1])
        
        return max_len
    
    return stack_solution(s)

# Example
print(longestValidParentheses("(()"))  # 2
```

---

### 30. Interleaving String

**Problem:** Is s3 formed by interleaving s1 and s2?

```python
def isInterleave(s1: str, s2: str, s3: str) -> bool:
    """
    dp[i][j] = can s1[0:i] and s2[0:j] form s3[0:i+j]?
    
    Time: O(m*n), Space: O(n)
    """
    m, n, l = len(s1), len(s2), len(s3)
    
    if m + n != l:
        return False
    
    dp = [False] * (n + 1)
    
    for i in range(m + 1):
        for j in range(n + 1):
            if i == 0 and j == 0:
                dp[j] = True
            elif i == 0:
                dp[j] = dp[j-1] and s2[j-1] == s3[j-1]
            elif j == 0:
                dp[j] = dp[j] and s1[i-1] == s3[i-1]
            else:
                dp[j] = (dp[j] and s1[i-1] == s3[i+j-1]) or \
                        (dp[j-1] and s2[j-1] == s3[i+j-1])
    
    return dp[n]

# Example
print(isInterleave("aabcc", "dbbca", "aadbbcbcac"))  # True
```

---

### 31. Regular Expression Matching

**Problem:** Implement regex with '.' and '*'

```python
def isMatch(s: str, p: str) -> bool:
    """
    dp[i][j] = does s[0:i] match p[0:j]?
    
    If p[j-1] == '*':
        - match 0 times: dp[i][j-2]
        - match 1+ times: dp[i-1][j] if s[i-1] matches p[j-2]
    
    Time: O(m*n), Space: O(m*n)
    """
    m, n = len(s), len(p)
    dp = [[False] * (n + 1) for _ in range(m + 1)]
    dp[0][0] = True
    
    # Handle patterns like a*, a*b*, etc.
    for j in range(2, n + 1):
        if p[j-1] == '*':
            dp[0][j] = dp[0][j-2]
    
    for i in range(1, m + 1):
        for j in range(1, n + 1):
            if p[j-1] == '*':
                # Match 0 times
                dp[i][j] = dp[i][j-2]
                # Match 1+ times
                if p[j-2] == s[i-1] or p[j-2] == '.':
                    dp[i][j] = dp[i][j] or dp[i-1][j]
            elif p[j-1] == '.' or p[j-1] == s[i-1]:
                dp[i][j] = dp[i-1][j-1]
    
    return dp[m][n]

# Example
print(isMatch("aa", "a*"))  # True
```

---

### 32. Wildcard Matching

**Problem:** Implement wildcard with '?' and '*'

```python
def isMatchWildcard(s: str, p: str) -> bool:
    """
    dp[i][j] = does s[0:i] match p[0:j]?
    
    '?' matches single character
    '*' matches any sequence
    
    Time: O(m*n), Space: O(n)
    """
    m, n = len(s), len(p)
    dp = [False] * (n + 1)
    dp[0] = True
    
    # Handle leading '*'
    for j in range(1, n + 1):
        if p[j-1] == '*':
            dp[j] = dp[j-1]
    
    for i in range(1, m + 1):
        prev = dp[0]
        dp[0] = False
        
        for j in range(1, n + 1):
            temp = dp[j]
            
            if p[j-1] == '*':
                dp[j] = dp[j] or dp[j-1]
            elif p[j-1] == '?' or p[j-1] == s[i-1]:
                dp[j] = prev
            else:
                dp[j] = False
            
            prev = temp
    
    return dp[n]

# Example
print(isMatchWildcard("aa", "a"))  # False
print(isMatchWildcard("aa", "*"))  # True
```

---

### 33. Scramble String

**Problem:** Check if s2 is a scrambled version of s1

```python
def isScramble(s1: str, s2: str) -> bool:
    """
    Recursive with memoization
    
    Try all split points, check if:
    1. No swap: left matches left AND right matches right
    2. Swap: left matches right AND right matches left
    
    Time: O(n^4), Space: O(n^3)
    """
    memo = {}
    
    def helper(s1, s2):
        if (s1, s2) in memo:
            return memo[(s1, s2)]
        
        if s1 == s2:
            return True
        
        if len(s1) != len(s2) or sorted(s1) != sorted(s2):
            return False
        
        n = len(s1)
        
        for i in range(1, n):
            # No swap
            if helper(s1[:i], s2[:i]) and helper(s1[i:], s2[i:]):
                memo[(s1, s2)] = True
                return True
            
            # Swap
            if helper(s1[:i], s2[-i:]) and helper(s1[i:], s2[:-i]):
                memo[(s1, s2)] = True
                return True
        
        memo[(s1, s2)] = False
        return False
    
    return helper(s1, s2)

# Example
print(isScramble("great", "rgeat"))  # True
```

---

### 34. Distinct Subsequences

**Problem:** Count distinct subsequences of s that equal t

```python
def numDistinct(s: str, t: str) -> int:
    """
    dp[i][j] = number of distinct subsequences of s[0:i] that equal t[0:j]
    
    If s[i-1] == t[j-1]:
        dp[i][j] = dp[i-1][j-1] + dp[i-1][j]
    Else:
        dp[i][j] = dp[i-1][j]
    
    Time: O(m*n), Space: O(n)
    """
    m, n = len(s), len(t)
    dp = [0] * (n + 1)
    dp[0] = 1
    
    for i in range(1, m + 1):
        for j in range(n, 0, -1):
            if s[i-1] == t[j-1]:
                dp[j] += dp[j-1]
    
    return dp[n]

# Example
print(numDistinct("rabbbit", "rabbit"))  # 3
```

---

### 35. Minimum Insertions to Make Palindrome

**Problem:** Minimum insertions to make string palindrome

```python
def minInsertions(s: str) -> int:
    """
    Find LPS (Longest Palindromic Subsequence)
    Answer = len(s) - LPS
    
    Time: O(n²), Space: O(n²)
    """
    n = len(s)
    dp = [[0] * n for _ in range(n)]
    
    for i in range(n):
        dp[i][i] = 1
    
    for length in range(2, n + 1):
        for i in range(n - length + 1):
            j = i + length - 1
            
            if s[i] == s[j]:
                dp[i][j] = dp[i+1][j-1] + 2
            else:
                dp[i][j] = max(dp[i+1][j], dp[i][j-1])
    
    return n - dp[0][n-1]

# Example
print(minInsertions("zzazz"))  # 0
print(minInsertions("mbadm"))  # 2
```

---

### 36. Stone Game

**Problem:** Two players pick stones optimally from ends

```python
def stoneGame(piles: list[int]) -> bool:
    """
    Player 1 always wins (proven mathematically for even piles)
    
    DP solution for general case:
    dp[i][j] = max advantage of current player for piles[i:j+1]
    
    Time: O(n²), Space: O(n²)
    """
    # Mathematical solution
    return True
    
    # DP solution (for learning)
    def dp_solution(piles):
        n = len(piles)
        dp = [[0] * n for _ in range(n)]
        
        for i in range(n):
            dp[i][i] = piles[i]
        
        for length in range(2, n + 1):
            for i in range(n - length + 1):
                j = i + length - 1
                dp[i][j] = max(
                    piles[i] - dp[i+1][j],
                    piles[j] - dp[i][j-1]
                )
        
        return dp[0][n-1] > 0

# Example
print(stoneGame([5,3,4,5]))  # True
```

---

### 37. Predict the Winner

**Problem:** Can player 1 guarantee a win?

```python
def PredictTheWinner(nums: list[int]) -> bool:
    """
    dp[i][j] = max score difference (current - opponent) for nums[i:j+1]
    
    Time: O(n²), Space: O(n²)
    """
    n = len(nums)
    dp = [[0] * n for _ in range(n)]
    
    for i in range(n):
        dp[i][i] = nums[i]
    
    for length in range(2, n + 1):
        for i in range(n - length + 1):
            j = i + length - 1
            dp[i][j] = max(
                nums[i] - dp[i+1][j],
                nums[j] - dp[i][j-1]
            )
    
    return dp[0][n-1] >= 0

# Example
print(PredictTheWinner([1,5,2]))  # False
```

---

### 38. Cherry Pickup

**Problem:** Pick maximum cherries going down and back up

```python
def cherryPickup(grid: list[list[int]]) -> int:
    """
    Model as two people going down simultaneously
    dp[r1][c1][c2] where r2 = r1 + c1 - c2
    
    Time: O(n³), Space: O(n³)
    """
    n = len(grid)
    memo = {}
    
    def dp(r1, c1, c2):
        r2 = r1 + c1 - c2
        
        # Out of bounds or thorn
        if (r1 >= n or c1 >= n or r2 >= n or c2 >= n or
            grid[r1][c1] == -1 or grid[r2][c2] == -1):
            return float('-inf')
        
        # Both reached end
        if r1 == n - 1 and c1 == n - 1:
            return grid[r1][c1]
        
        if (r1, c1, c2) in memo:
            return memo[(r1, c1, c2)]
        
        # Pick cherries
        cherries = grid[r1][c1]
        if c1 != c2:  # Not same cell
            cherries += grid[r2][c2]
        
        # Try all 4 combinations of moves
        cherries += max(
            dp(r1 + 1, c1, c2 + 1),  # down, right
            dp(r1 + 1, c1, c2),      # down, down
            dp(r1, c1 + 1, c2 + 1),  # right, right
            dp(r1, c1 + 1, c2)       # right, down
        )
        
        memo[(r1, c1, c2)] = cherries
        return cherries
    
    return max(0, dp(0, 0, 0))

# Example
grid = [[0,1,-1],[1,0,-1],[1,1,1]]
print(cherryPickup(grid))  # 5
```

---

### 39. Dungeon Game

**Problem:** Minimum initial health to reach princess

```python
def calculateMinimumHP(dungeon: list[list[int]]) -> int:
    """
    Work backwards from bottom-right
    dp[i][j] = minimum health needed at (i,j) to reach end
    
    Time: O(m*n), Space: O(n)
    """
    if not dungeon:
        return 1
    
    m, n = len(dungeon), len(dungeon[0])
    dp = [float('inf')] * (n + 1)
    dp[n-1] = 1
    
    for i in range(m - 1, -1, -1):
        for j in range(n - 1, -1, -1):
            if i == m - 1 and j == n - 1:
                dp[j] = max(1, 1 - dungeon[i][j])
            else:
                dp[j] = max(1, min(dp[j], dp[j+1]) - dungeon[i][j])
    
    return dp[0]

# Example
dungeon = [[-2,-3,3],[-5,-10,1],[10,30,-5]]
print(calculateMinimumHP(dungeon))  # 7
```

---

### 40. Super Egg Drop

**Problem:** Minimum attempts to find critical floor with k eggs

```python
def superEggDrop(k: int, n: int) -> int:
    """
    dp[m][k] = max floors we can check with m moves and k eggs
    
    If egg breaks: dp[m-1][k-1] (below)
    If egg doesn't break: dp[m-1][k] (above)
    Total: dp[m][k] = dp[m-1][k-1] + dp[m-1][k] + 1
    
    Time: O(k*n), Space: O(k)
    """
    dp = [[0] * (k + 1) for _ in range(n + 1)]
    
    m = 0
    while dp[m][k] < n:
        m += 1
        for i in range(1, k + 1):
            dp[m][i] = dp[m-1][i-1] + dp[m-1][i] + 1
    
    return m

# Example
print(superEggDrop(2, 100))  # 14
```

---

## 10. Backtracking (20 Questions)

### 1. Subsets

**Problem:** Generate all subsets

```python
def subsets(nums: list[int]) -> list[list[int]]:
    """
    Use backtracking to explore all possibilities
    At each step: include or exclude current element
    
    Time: O(2^n), Space: O(n)
    """
    result = []
    
    def backtrack(start, path):
        result.append(path[:])
        
        for i in range(start, len(nums)):
            path.append(nums[i])
            backtrack(i + 1, path)
            path.pop()
    
    backtrack(0, [])
    return result

# Example
print(subsets([1,2,3]))
# [[],[1],[1,2],[1,2,3],[1,3],[2],[2,3],[3]]
```

---

### 2. Subsets II

**Problem:** Generate subsets with duplicates

```python
def subsetsWithDup(nums: list[int]) -> list[list[int]]:
    """
    Sort first, then skip duplicates at same level
    
    Time: O(2^n), Space: O(n)
    """
    result = []
    nums.sort()
    
    def backtrack(start, path):
        result.append(path[:])
        
        for i in range(start, len(nums)):
            # Skip duplicates at same recursion level
            if i > start and nums[i] == nums[i-1]:
                continue
            
            path.append(nums[i])
            backtrack(i + 1, path)
            path.pop()
    
    backtrack(0, [])
    return result

# Example
print(subsetsWithDup([1,2,2]))
```

---

### 3. Permutations

**Problem:** Generate all permutations

```python
def permute(nums: list[int]) -> list[list[int]]:
    """
    Use backtracking with a 'used' set
    
    Time: O(n!), Space: O(n)
    """
    result = []
    
    def backtrack(path, used):
        if len(path) == len(nums):
            result.append(path[:])
            return
        
        for i in range(len(nums)):
            if i in used:
                continue
            
            path.append(nums[i])
            used.add(i)
            backtrack(path, used)
            used.remove(i)
            path.pop()
    
    backtrack([], set())
    return result

# Example
print(permute([1,2,3]))
```

---

### 4. Permutations II

**Problem:** Generate permutations with duplicates

```python
def permuteUnique(nums: list[int]) -> list[list[int]]:
    """
    Sort first, use 'used' array to track usage
    Skip if: nums[i] == nums[i-1] and i-1 not used
    
    Time: O(n!), Space: O(n)
    """
    result = []
    nums.sort()
    used = [False] * len(nums)
    
    def backtrack(path):
        if len(path) == len(nums):
            result.append(path[:])
            return
        
        for i in range(len(nums)):
            if used[i]:
                continue
            
            # Skip duplicates: only use duplicate if previous same element is used
            if i > 0 and nums[i] == nums[i-1] and not used[i-1]:
                continue
            
            path.append(nums[i])
            used[i] = True
            backtrack(path)
            used[i] = False
            path.pop()
    
    backtrack([])
    return result

# Example
print(permuteUnique([1,1,2]))
```

---

### 5. Combination Sum

**Problem:** Find combinations that sum to target (reuse allowed)

```python
def combinationSum(candidates: list[int], target: int) -> list[list[int]]:
    """
    Can reuse same element, so don't increment start
    
    Time: O(n^(target/min)), Space: O(target/min)
    """
    result = []
    candidates.sort()
    
    def backtrack(start, target, path):
        if target == 0:
            result.append(path[:])
            return
        
        if target < 0:
            return
        
        for i in range(start, len(candidates)):
            path.append(candidates[i])
            # Can reuse same element
            backtrack(i, target - candidates[i], path)
            path.pop()
    
    backtrack(0, target, [])
    return result

# Example
print(combinationSum([2,3,6,7], 7))  # [[2,2,3],[7]]
```

---

### 6. Combination Sum II

**Problem:** Find combinations (no reuse, has duplicates)

```python
def combinationSum2(candidates: list[int], target: int) -> list[list[int]]:
    """
    Sort and skip duplicates at same level
    
    Time: O(2^n), Space: O(n)
    """
    result = []
    candidates.sort()
    
    def backtrack(start, target, path):
        if target == 0:
            result.append(path[:])
            return
        
        if target < 0:
            return
        
        for i in range(start, len(candidates)):
            # Skip duplicates
            if i > start and candidates[i] == candidates[i-1]:
                continue
            
            path.append(candidates[i])
            backtrack(i + 1, target - candidates[i], path)
            path.pop()
    
    backtrack(0, target, [])
    return result

# Example
print(combinationSum2([10,1,2,7,6,1,5], 8))
```

---

### 7. N Queens

**Problem:** Place N queens on N×N board

```python
def solveNQueens(n: int) -> list[list[str]]:
    """
    Track columns, diagonals, anti-diagonals
    
    Diagonal: row - col is constant
    Anti-diagonal: row + col is constant
    
    Time: O(n!), Space: O(n)
    """
    result = []
    board = [['.'] * n for _ in range(n)]
    cols = set()
    diag = set()  # row - col
    anti_diag = set()  # row + col
    
    def backtrack(row):
        if row == n:
            result.append([''.join(row) for row in board])
            return
        
        for col in range(n):
            if col in cols or (row - col) in diag or (row + col) in anti_diag:
                continue
            
            # Place queen
            board[row][col] = 'Q'
            cols.add(col)
            diag.add(row - col)
            anti_diag.add(row + col)
            
            backtrack(row + 1)
            
            # Remove queen
            board[row][col] = '.'
            cols.remove(col)
            diag.remove(row - col)
            anti_diag.remove(row + col)
    
    backtrack(0)
    return result

# Example
print(solveNQueens(4))
```

---

### 8. N Queens II

**Problem:** Count N-Queens solutions

```python
def totalNQueens(n: int) -> int:
    """
    Same as N-Queens but just count
    
    Time: O(n!), Space: O(n)
    """
    cols = set()
    diag = set()
    anti_diag = set()
    
    def backtrack(row):
        if row == n:
            return 1
        
        count = 0
        for col in range(n):
            if col in cols or (row - col) in diag or (row + col) in anti_diag:
                continue
            
            cols.add(col)
            diag.add(row - col)
            anti_diag.add(row + col)
            
            count += backtrack(row + 1)
            
            cols.remove(col)
            diag.remove(row - col)
            anti_diag.remove(row + col)
        
        return count
    
    return backtrack(0)

# Example
print(totalNQueens(4))  # 2
```

---

### 9. Sudoku Solver

**Problem:** Solve Sudoku puzzle

```python
def solveSudoku(board: list[list[str]]) -> None:
    """
    Try digits 1-9 for each empty cell
    Check row, column, and 3×3 box constraints
    
    Time: O(9^m) where m = empty cells, Space: O(1)
    """
    def is_valid(row, col, num):
        # Check row
        if num in board[row]:
            return False
        
        # Check column
        if num in [board[i][col] for i in range(9)]:
            return False
        
        # Check 3×3 box
        box_row, box_col = 3 * (row // 3), 3 * (col // 3)
        for i in range(box_row, box_row + 3):
            for j in range(box_col, box_col + 3):
                if board[i][j] == num:
                    return False
        
        return True
    
    def backtrack():
        for i in range(9):
            for j in range(9):
                if board[i][j] == '.':
                    for num in '123456789':
                        if is_valid(i, j, num):
                            board[i][j] = num
                            
                            if backtrack():
                                return True
                            
                            board[i][j] = '.'
                    
                    return False
        
        return True
    
    backtrack()

# Example
board = [
    ["5","3",".",".","7",".",".",".","."],
    ["6",".",".","1","9","5",".",".","."],
    [".","9","8",".",".",".",".","6","."],
    ["8",".",".",".","6",".",".",".","3"],
    ["4",".",".","8",".","3",".",".","1"],
    ["7",".",".",".","2",".",".",".","6"],
    [".","6",".",".",".",".","2","8","."],
    [".",".",".","4","1","9",".",".","5"],
    [".",".",".",".","8",".",".","7","9"]
]
solveSudoku(board)
```

---

### 10. Letter Combinations of Phone Number

**Problem:** Generate letter combinations from phone digits

```python
def letterCombinations(digits: str) -> list[str]:
    """
    Map digits to letters, backtrack through all combinations
    
    Time: O(4^n), Space: O(n)
    """
    if not digits:
        return []
    
    phone = {
        '2': 'abc', '3': 'def', '4': 'ghi', '5': 'jkl',
        '6': 'mno', '7': 'pqrs', '8': 'tuv', '9': 'wxyz'
    }
    
    result = []
    
    def backtrack(index, path):
        if index == len(digits):
            result.append(''.join(path))
            return
        
        for letter in phone[digits[index]]:
            path.append(letter)
            backtrack(index + 1, path)
            path.pop()
    
    backtrack(0, [])
    return result

# Example
print(letterCombinations("23"))  # ["ad","ae","af","bd","be","bf","cd","ce","cf"]
```

---

### 11. Palindrome Partitioning (Backtracking)

**Problem:** All palindrome partitionings

```python
def partition(s: str) -> list[list[str]]:
    """
    At each position, try all palindromic prefixes
    
    Time: O(n * 2^n), Space: O(n)
    """
    def is_palindrome(string):
        return string == string[::-1]
    
    result = []
    
    def backtrack(start, path):
        if start == len(s):
            result.append(path[:])
            return
        
        for end in range(start + 1, len(s) + 1):
            substring = s[start:end]
            if is_palindrome(substring):
                path.append(substring)
                backtrack(end, path)
                path.pop()
    
    backtrack(0, [])
    return result

# Example
print(partition("aab"))  # [["a","a","b"],["aa","b"]]
```

---

### 12. Word Search

**Problem:** Find if word exists in grid

```python
def exist(board: list[list[str]], word: str) -> bool:
    """
    DFS with backtracking
    Mark visited cells temporarily
    
    Time: O(m*n*4^L), Space: O(L)
    where L = len(word)
    """
    if not board:
        return False
    
    m, n = len(board), len(board[0])
    
    def backtrack(i, j, k):
        if k == len(word):
            return True
        
        if i < 0 or i >= m or j < 0 or j >= n or board[i][j] != word[k]:
            return False
        
        # Mark as visited
        temp = board[i][j]
        board[i][j] = '#'
        
        # Explore all 4 directions
        found = (backtrack(i+1, j, k+1) or
                 backtrack(i-1, j, k+1) or
                 backtrack(i, j+1, k+1) or
                 backtrack(i, j-1, k+1))
        
        # Restore
        board[i][j] = temp
        
        return found
    
    for i in range(m):
        for j in range(n):
            if backtrack(i, j, 0):
                return True
    
    return False

# Example
board = [["A","B","C","E"],["S","F","C","S"],["A","D","E","E"]]
print(exist(board, "ABCCED"))  # True
```

---

### 13. Word Search II

**Problem:** Find all words from dictionary in grid

```python
def findWords(board: list[list[str]], words: list[str]) -> list[str]:
    """
    Build Trie from words, then DFS
    
    Time: O(m*n*4^L), Space: O(total chars in words)
    """
    # Build Trie
    class TrieNode:
        def __init__(self):
            self.children = {}
            self.word = None
    
    root = TrieNode()
    for word in words:
        node = root
        for char in word:
            if char not in node.children:
                node.children[char] = TrieNode()
            node = node.children[char]
        node.word = word
    
    m, n = len(board), len(board[0])
    result = []
    
    def backtrack(i, j, node):
        char = board[i][j]
        if char not in node.children:
            return
        
        next_node = node.children[char]
        
        if next_node.word:
            result.append(next_node.word)
            next_node.word = None  # Avoid duplicates
        
        board[i][j] = '#'
        
        for di, dj in [(0,1), (1,0), (0,-1), (-1,0)]:
            ni, nj = i + di, j + dj
            if 0 <= ni < m and 0 <= nj < n and board[ni][nj] != '#':
                backtrack(ni, nj, next_node)
        
        board[i][j] = char
    
    for i in range(m):
        for j in range(n):
            backtrack(i, j, root)
    
    return result

# Example
board = [["o","a","a","n"],["e","t","a","e"],["i","h","k","r"],["i","f","l","v"]]
words = ["oath","pea","eat","rain"]
print(findWords(board, words))  # ["oath","eat"]
```

---

### 14. Generate Parentheses

**Problem:** Generate all valid parentheses combinations

```python
def generateParenthesis(n: int) -> list[str]:
    """
    Track count of open and close parentheses
    Add '(' if open < n
    Add ')' if close < open
    
    Time: O(4^n / sqrt(n)), Space: O(n)
    """
    result = []
    
    def backtrack(open_count, close_count, path):
        if len(path) == 2 * n:
            result.append(''.join(path))
            return
        
        if open_count < n:
            path.append('(')
            backtrack(open_count + 1, close_count, path)
            path.pop()
        
        if close_count < open_count:
            path.append(')')
            backtrack(open_count, close_count + 1, path)
            path.pop()
    
    backtrack(0, 0, [])
    return result

# Example
print(generateParenthesis(3))
# ["((()))","(()())","(())()","()(())","()()()"]
```

---

### 15. Restore IP Addresses

**Problem:** Generate all valid IP addresses

```python
def restoreIpAddresses(s: str) -> list[str]:
    """
    Backtrack with 4 segments
    Each segment: 0-255, no leading zeros (except "0")
    
    Time: O(1) - max 3^4 combinations, Space: O(1)
    """
    result = []
    
    def is_valid(segment):
        if not segment or len(segment) > 3:
            return False
        if segment[0] == '0' and len(segment) > 1:
            return False
        return int(segment) <= 255
    
    def backtrack(start, path):
        if len(path) == 4:
            if start == len(s):
                result.append('.'.join(path))
            return
        
        for length in range(1, 4):
            if start + length > len(s):
                break
            
            segment = s[start:start+length]
            if is_valid(segment):
                path.append(segment)
                backtrack(start + length, path)
                path.pop()
    
    backtrack(0, [])
    return result

# Example
print(restoreIpAddresses("25525511135"))
# ["255.255.11.135","255.255.111.35"]
```

---

### 16. Partition to K Equal Sum Subsets

**Problem:** Can array be partitioned into k equal sum subsets?

```python
def canPartitionKSubsets(nums: list[int], k: int) -> bool:
    """
    Target sum = total / k
    Use backtracking to fill k buckets
    
    Time: O(k^n), Space: O(n)
    """
    total = sum(nums)
    if total % k:
        return False
    
    target = total // k
    nums.sort(reverse=True)
    used = [False] * len(nums)
    
    def backtrack(k, bucket_sum, start):
        if k == 0:
            return True
        
        if bucket_sum == target:
            return backtrack(k - 1, 0, 0)
        
        for i in range(start, len(nums)):
            if used[i] or bucket_sum + nums[i] > target:
                continue
            
            used[i] = True
            if backtrack(k, bucket_sum + nums[i], i + 1):
                return True
            used[i] = False
        
        return False
    
    return backtrack(k, 0, 0)

# Example
print(canPartitionKSubsets([4,3,2,3,5,2,1], 4))  # True
```

---

### 17. Beautiful Arrangement

**Problem:** Count beautiful arrangements (permutations with divisibility)

```python
def countArrangement(n: int) -> int:
    """
    Permutation where: pos % val == 0 or val % pos == 0
    
    Time: O(n!), Space: O(n)
    """
    def backtrack(pos, used):
        if pos > n:
            return 1
        
        count = 0
        for i in range(1, n + 1):
            if not used[i] and (i % pos == 0 or pos % i == 0):
                used[i] = True
                count += backtrack(pos + 1, used)
                used[i] = False
        
        return count
    
    return backtrack(1, [False] * (n + 1))

# Example
print(countArrangement(2))  # 2
```

---

### 18. Expression Add Operators

**Problem:** Add operators (+, -, *) to reach target

```python
def addOperators(num: str, target: int) -> list[str]:
    """
    Backtrack through all operator placements
    Track previous value for multiplication
    
    Time: O(4^n), Space: O(n)
    """
    result = []
    
    def backtrack(index, path, value, prev):
        if index == len(num):
            if value == target:
                result.append(path)
            return
        
        for i in range(index, len(num)):
            # Avoid leading zeros
            if i != index and num[index] == '0':
                break
            
            current = int(num[index:i+1])
            
            if index == 0:
                backtrack(i + 1, str(current), current, current)
            else:
                # Addition
                backtrack(i + 1, path + '+' + str(current), 
                         value + current, current)
                
                # Subtraction
                backtrack(i + 1, path + '-' + str(current), 
                         value - current, -current)
                
                # Multiplication
                backtrack(i + 1, path + '*' + str(current),
                         value - prev + prev * current, prev * current)
    
    backtrack(0, '', 0, 0)
    return result

# Example
print(addOperators("123", 6))  # ["1+2+3","1*2*3"]
```

---

### 19. Matchsticks to Square

**Problem:** Can matchsticks form a square?

```python
def makesquare(matchsticks: list[int]) -> bool:
    """
    Similar to partition k subsets (k=4)
    
    Time: O(4^n), Space: O(n)
    """
    if not matchsticks or len(matchsticks) < 4:
        return False
    
    total = sum(matchsticks)
    if total % 4:
        return False
    
    side = total // 4
    matchsticks.sort(reverse=True)
    
    if matchsticks[0] > side:
        return False
    
    sides = [0] * 4
    
    def backtrack(index):
        if index == len(matchsticks):
            return all(s == side for s in sides)
        
        for i in range(4):
            if sides[i] + matchsticks[index] <= side:
                sides[i] += matchsticks[index]
                if backtrack(index + 1):
                    return True
                sides[i] -= matchsticks[index]
            
            # Optimization: if this side is empty, no point trying others
            if sides[i] == 0:
                break
        
        return False
    
    return backtrack(0)

# Example
print(makesquare([1,1,2,2,2]))  # True
```

---

### 20. Maximum Length of Concatenated String with Unique Characters

**Problem:** Maximum length by concatenating strings with unique chars

```python
def maxLength(arr: list[str]) -> int:
    """
    Backtrack through all combinations
    Check if characters are unique
    
    Time: O(2^n), Space: O(n)
    """
    def is_unique(s):
        return len(s) == len(set(s))
    
    def backtrack(index, current):
        if not is_unique(current):
            return 0
        
        max_len = len(current)
        
        for i in range(index, len(arr)):
            max_len = max(max_len, backtrack(i + 1, current + arr[i]))
        
        return max_len
    
    return backtrack(0, '')

# Example
print(maxLength(["un","iq","ue"]))  # 4
```

---

## 11. Tries (10 Questions)

### 1. Implement Trie

**Problem:** Implement prefix tree

```python
class Trie:
    """
    Trie (prefix tree) for efficient string operations
    
    Time: O(m) per operation where m = word length
    Space: O(total characters)
    """
    
    class TrieNode:
        def __init__(self):
            self.children = {}
            self.is_end = False
    
    def __init__(self):
        self.root = self.TrieNode()
    
    def insert(self, word: str) -> None:
        node = self.root
        for char in word:
            if char not in node.children:
                node.children[char] = self.TrieNode()
            node = node.children[char]
        node.is_end = True
    
    def search(self, word: str) -> bool:
        node = self.root
        for char in word:
            if char not in node.children:
                return False
            node = node.children[char]
        return node.is_end
    
    def startsWith(self, prefix: str) -> bool:
        node = self.root
        for char in prefix:
            if char not in node.children:
                return False
            node = node.children[char]
        return True

# Example
trie = Trie()
trie.insert("apple")
print(trie.search("apple"))   # True
print(trie.search("app"))     # False
print(trie.startsWith("app")) # True
```

---

### 2. Add and Search Word

**Problem:** Design data structure with wildcard search

```python
class WordDictionary:
    """
    Trie with wildcard '.' support
    
    Time: O(m) insert, O(26^m) search worst case
    """
    
    class TrieNode:
        def __init__(self):
            self.children = {}
            self.is_end = False
    
    def __init__(self):
        self.root = self.TrieNode()
    
    def addWord(self, word: str) -> None:
        node = self.root
        for char in word:
            if char not in node.children:
                node.children[char] = self.TrieNode()
            node = node.children[char]
        node.is_end = True
    
    def search(self, word: str) -> bool:
        def dfs(node, i):
            if i == len(word):
                return node.is_end
            
            if word[i] == '.':
                # Try all children
                for child in node.children.values():
                    if dfs(child, i + 1):
                        return True
                return False
            else:
                if word[i] not in node.children:
                    return False
                return dfs(node.children[word[i]], i + 1)
        
        return dfs(self.root, 0)

# Example
wd = WordDictionary()
wd.addWord("bad")
wd.addWord("dad")
wd.addWord("mad")
print(wd.search("pad"))  # False
print(wd.search("bad"))  # True
print(wd.search(".ad"))  # True
print(wd.search("b.."))  # True
```

---

### 3. Word Search II (Already covered in Backtracking)

---

### 4. Replace Words

**Problem:** Replace words with shortest root from dictionary

```python
def replaceWords(dictionary: list[str], sentence: str) -> str:
    """
    Build Trie from roots, search for each word
    
    Time: O(d + s) where d = dict chars, s = sentence chars
    Space: O(d)
    """
    class TrieNode:
        def __init__(self):
            self.children = {}
            self.word = None
    
    root = TrieNode()
    
    # Build Trie
    for word in dictionary:
        node = root
        for char in word:
            if char not in node.children:
                node.children[char] = TrieNode()
            node = node.children[char]
        node.word = word
    
    def find_root(word):
        node = root
        for char in word:
            if char not in node.children:
                return word
            node = node.children[char]
            if node.word:
                return node.word
        return word
    
    words = sentence.split()
    return ' '.join(find_root(word) for word in words)

# Example
dictionary = ["cat","bat","rat"]
sentence = "the cattle was rattled by the battery"
print(replaceWords(dictionary, sentence))
# "the cat was rat by the bat"
```

---

### 5. Map Sum Pairs

**Problem:** Insert and sum values with given prefix

```python
class MapSum:
    """
    Trie with value tracking
    
    Time: O(m) insert, O(m) sum
    """
    
    class TrieNode:
        def __init__(self):
            self.children = {}
            self.value = 0
    
    def __init__(self):
        self.root = self.TrieNode()
        self.map = {}
    
    def insert(self, key: str, val: int) -> None:
        delta = val - self.map.get(key, 0)
        self.map[key] = val
        
        node = self.root
        for char in key:
            if char not in node.children:
                node.children[char] = self.TrieNode()
            node = node.children[char]
            node.value += delta
    
    def sum(self, prefix: str) -> int:
        node = self.root
        for char in prefix:
            if char not in node.children:
                return 0
            node = node.children[char]
        return node.value

# Example
ms = MapSum()
ms.insert("apple", 3)
print(ms.sum("ap"))  # 3
ms.insert("app", 2)
print(ms.sum("ap"))  # 5
```

---

### 6. Maximum XOR of Two Numbers

**Problem:** Find maximum XOR of two numbers in array

```python
def findMaximumXOR(nums: list[int]) -> int:
    """
    Build binary Trie, for each number find best XOR partner
    
    Time: O(32n), Space: O(32n)
    """
    class TrieNode:
        def __init__(self):
            self.children = {}
    
    root = TrieNode()
    
    # Build Trie with binary representation
    for num in nums:
        node = root
        for i in range(31, -1, -1):
            bit = (num >> i) & 1
            if bit not in node.children:
                node.children[bit] = TrieNode()
            node = node.children[bit]
    
    max_xor = 0
    
    # Find max XOR for each number
    for num in nums:
        node = root
        current_xor = 0
        
        for i in range(31, -1, -1):
            bit = (num >> i) & 1
            # Try opposite bit for max XOR
            toggled = 1 - bit
            
            if toggled in node.children:
                current_xor |= (1 << i)
                node = node.children[toggled]
            else:
                node = node.children[bit]
        
        max_xor = max(max_xor, current_xor)
    
    return max_xor

# Example
print(findMaximumXOR([3,10,5,25,2,8]))  # 28
```

---

### 7. Stream of Characters

**Problem:** Query if suffix is in dictionary

```python
class StreamChecker:
    """
    Build Trie with reversed words
    Query from end of stream
    
    Time: O(m) per query, Space: O(total chars)
    """
    
    class TrieNode:
        def __init__(self):
            self.children = {}
            self.is_end = False
    
    def __init__(self, words: list[str]):
        self.root = self.TrieNode()
        self.stream = []
        
        # Build Trie with reversed words
        for word in words:
            node = self.root
            for char in reversed(word):
                if char not in node.children:
                    node.children[char] = self.TrieNode()
                node = node.children[char]
            node.is_end = True
    
    def query(self, letter: str) -> bool:
        self.stream.append(letter)
        node = self.root
        
        # Check from end of stream
        for i in range(len(self.stream) - 1, -1, -1):
            char = self.stream[i]
            if char not in node.children:
                return False
            node = node.children[char]
            if node.is_end:
                return True
        
        return False

# Example
sc = StreamChecker(["cd","f","kl"])
print(sc.query('a'))  # False
print(sc.query('b'))  # False
print(sc.query('c'))  # False
print(sc.query('d'))  # True
```

---

### 8. Longest Word in Dictionary

**Problem:** Find longest word built one character at a time

```python
def longestWord(words: list[str]) -> str:
    """
    Build Trie, use BFS/DFS to find longest buildable word
    
    Time: O(sum of lengths), Space: O(sum of lengths)
    """
    class TrieNode:
        def __init__(self):
            self.children = {}
            self.word = None
    
    root = TrieNode()
    
    # Build Trie
    for word in words:
        node = root
        for char in word:
            if char not in node.children:
                node.children[char] = TrieNode()
            node = node.children[char]
        node.word = word
    
    # BFS to find longest word
    from collections import deque
    queue = deque([root])
    result = ""
    
    while queue:
        node = queue.popleft()
        
        for char in sorted(node.children.keys(), reverse=True):
            child = node.children[char]
            if child.word:
                queue.append(child)
                if len(child.word) > len(result):
                    result = child.word
    
    return result

# Example
print(longestWord(["w","wo","wor","worl","world"]))  # "world"
```

---

### 9. Design Search Autocomplete System

**Problem:** Autocomplete with ranking

```python
class AutocompleteSystem:
    """
    Trie with sentence frequency tracking
    
    Time: O(m + n log k) per input where m = prefix, n = matches, k = top 3
    """
    
    class TrieNode:
        def __init__(self):
            self.children = {}
            self.sentences = {}  # sentence -> frequency
    
    def __init__(self, sentences: list[str], times: list[int]):
        self.root = self.TrieNode()
        self.current_node = self.root
        self.current_input = []
        
        # Build Trie
        for sentence, time in zip(sentences, times):
            self._add_sentence(sentence, time)
    
    def _add_sentence(self, sentence, time):
        node = self.root
        for char in sentence:
            if char not in node.children:
                node.children[char] = self.TrieNode()
            node = node.children[char]
            node.sentences[sentence] = node.sentences.get(sentence, 0) + time
    
    def input(self, c: str) -> list[str]:
        if c == '#':
            # End of input, save sentence
            sentence = ''.join(self.current_input)
            self._add_sentence(sentence, 1)
            self.current_input = []
            self.current_node = self.root
            return []
        
        self.current_input.append(c)
        
        if c not in self.current_node.children:
            self.current_node.children[c] = self.TrieNode()
        
        self.current_node = self.current_node.children[c]
        
        # Get top 3 sentences
        sentences = self.current_node.sentences.items()
        top3 = sorted(sentences, key=lambda x: (-x[1], x[0]))[:3]
        
        return [s for s, _ in top3]

# Example
ac = AutocompleteSystem(["i love you", "island", "iroman", "i love leetcode"], [5,3,2,2])
print(ac.input('i'))  # ["i love you","island","i love leetcode"]
print(ac.input(' '))  # ["i love you","i love leetcode"]
print(ac.input('a'))  # []
print(ac.input('#'))  # []
```

---

### 10. Concatenated Words

**Problem:** Find all concatenated words

```python
def findAllConcatenatedWordsInADict(words: list[str]) -> list[str]:
    """
    Build Trie, check if word can be formed by other words
    
    Time: O(n * m²), Space: O(total chars)
    """
    class TrieNode:
        def __init__(self):
            self.children = {}
            self.is_end = False
    
    root = TrieNode()
    
    # Build Trie
    for word in words:
        node = root
        for char in word:
            if char not in node.children:
                node.children[char] = TrieNode()
            node = node.children[char]
        node.is_end = True
    
    def can_form(word, start, count):
        if start == len(word):
            return count >= 2
        
        node = root
        for i in range(start, len(word)):
            if word[i] not in node.children:
                return False
            node = node.children[word[i]]
            
            if node.is_end:
                if can_form(word, i + 1, count + 1):
                    return True
        
        return False
    
    result = []
    for word in words:
        if can_form(word, 0, 0):
            result.append(word)
    
    return result

# Example
words = ["cat","cats","catsdogcats","dog","dogcatsdog","hippopotamuses","rat","ratcatdogcat"]
print(findAllConcatenatedWordsInADict(words))
# ["catsdogcats","dogcatsdog","ratcatdogcat"]
```

---

## 12. Greedy (10 Questions)

### 1. Jump Game (Already covered in DP)

---

### 2. Jump Game II (Already covered in DP)

---

### 3. Gas Station

**Problem:** Find starting gas station to complete circuit

```python
def canCompleteCircuit(gas: list[int], cost: list[int]) -> int:
    """
    If total gas < total cost, impossible
    Otherwise, start from station where tank becomes positive
    
    Time: O(n), Space: O(1)
    """
    if sum(gas) < sum(cost):
        return -1
    
    tank = 0
    start = 0
    
    for i in range(len(gas)):
        tank += gas[i] - cost[i]
        
        if tank < 0:
            tank = 0
            start = i + 1
    
    return start

# Example
print(canCompleteCircuit([1,2,3,4,5], [3,4,5,1,2]))  # 3
```

---

### 4. Candy

**Problem:** Minimum candies to distribute (neighbors with higher rating get more)

```python
def candy(ratings: list[int]) -> int:
    """
    Two passes:
    1. Left to right: if ratings[i] > ratings[i-1], candies[i] = candies[i-1] + 1
    2. Right to left: if ratings[i] > ratings[i+1], candies[i] = max(candies[i], candies[i+1] + 1)
    
    Time: O(n), Space: O(n)
    """
    n = len(ratings)
    candies = [1] * n
    
    # Left to right
    for i in range(1, n):
        if ratings[i] > ratings[i-1]:
            candies[i] = candies[i-1] + 1
    
    # Right to left
    for i in range(n-2, -1, -1):
        if ratings[i] > ratings[i+1]:
            candies[i] = max(candies[i], candies[i+1] + 1)
    
    return sum(candies)

# Example
print(candy([1,0,2]))  # 5
```

---

### 5. Non-overlapping Intervals

**Problem:** Minimum removals to make intervals non-overlapping

```python
def eraseOverlapIntervals(intervals: list[list[int]]) -> int:
    """
    Sort by end time, keep intervals ending earliest
    
    Time: O(n log n), Space: O(1)
    """
    if not intervals:
        return 0
    
    intervals.sort(key=lambda x: x[1])
    
    count = 0
    end = intervals[0][1]
    
    for i in range(1, len(intervals)):
        if intervals[i][0] < end:
            count += 1
        else:
            end = intervals[i][1]
    
    return count

# Example
print(eraseOverlapIntervals([[1,2],[2,3],[3,4],[1,3]]))  # 1
```

---

### 6. Partition Labels

**Problem:** Partition string into max parts where each letter appears in at most one part

```python
def partitionLabels(s: str) -> list[int]:
    """
    Track last occurrence of each character
    Extend partition to include all occurrences
    
    Time: O(n), Space: O(1)
    """
    last = {char: i for i, char in enumerate(s)}
    
    result = []
    start = 0
    end = 0
    
    for i, char in enumerate(s):
        end = max(end, last[char])
        
        if i == end:
            result.append(end - start + 1)
            start = i + 1
    
    return result

# Example
print(partitionLabels("ababcbacadefegdehijhklij"))
# [9,7,8]
```

---

### 7. Minimum Number of Arrows to Burst Balloons

**Problem:** Minimum arrows to burst all balloons

```python
def findMinArrowShots(points: list[list[int]]) -> int:
    """
    Sort by end position, shoot at end of first balloon
    
    Time: O(n log n), Space: O(1)
    """
    if not points:
        return 0
    
    points.sort(key=lambda x: x[1])
    
    arrows = 1
    end = points[0][1]
    
    for i in range(1, len(points)):
        if points[i][0] > end:
            arrows += 1
            end = points[i][1]
    
    return arrows

# Example
print(findMinArrowShots([[10,16],[2,8],[1,6],[7,12]]))  # 2
```

---

### 8. Queue Reconstruction by Height

**Problem:** Reconstruct queue based on height and count of taller people

```python
def reconstructQueue(people: list[list[int]]) -> list[list[int]]:
    """
    Sort by height desc, then by k asc
    Insert each person at index k
    
    Time: O(n²), Space: O(n)
    """
    people.sort(key=lambda x: (-x[0], x[1]))
    
    result = []
    for person in people:
        result.insert(person[1], person)
    
    return result

# Example
print(reconstructQueue([[7,0],[4,4],[7,1],[5,0],[6,1],[5,2]]))
# [[5,0],[7,0],[5,2],[6,1],[4,4],[7,1]]
```

---

### 9. Task Scheduler

**Problem:** Minimum time to complete tasks with cooldown

```python
def leastInterval(tasks: list[str], n: int) -> int:
    """
    Count frequencies, calculate idle slots
    
    Time: O(m) where m = number of tasks, Space: O(1)
    """
    from collections import Counter
    
    freq = Counter(tasks)
    max_freq = max(freq.values())
    max_count = sum(1 for f in freq.values() if f == max_freq)
    
    # Minimum intervals needed
    intervals = (max_freq - 1) * (n + 1) + max_count
    
    return max(len(tasks), intervals)

# Example
print(leastInterval(["A","A","A","B","B","B"], 2))  # 8
```

---

### 10. Maximum Units on Truck

**Problem:** Maximum units with box capacity constraint

```python
def maximumUnits(boxTypes: list[list[int]], truckSize: int) -> int:
    """
    Sort by units per box descending, take greedily
    
    Time: O(n log n), Space: O(1)
    """
    boxTypes.sort(key=lambda x: x[1], reverse=True)
    
    units = 0
    
    for boxes, units_per_box in boxTypes:
        take = min(boxes, truckSize)
        units += take * units_per_box
        truckSize -= take
        
        if truckSize == 0:
            break
    
    return units

# Example
print(maximumUnits([[1,3],[2,2],[3,1]], 4))  # 8
```

---


