Cloud / DevOps System Design — Complete Guide

## Table of Contents
1. [Auto Scaling System](#33)
2. [CI/CD Pipeline](#34)
3. [Container Orchestration System](#35)
4. [Service Discovery](#36)
5. [Blue-Green Deployment System](#37)

---

<a id="33"></a>
## 33. Auto Scaling System

### Core Concept

An auto-scaling system dynamically adjusts compute resources based on real-time demand — scaling **out** (add instances) when load increases and scaling **in** (remove instances) when load decreases.

```
                         ┌─────────────────────────────────────────┐
                         │          AUTO SCALING SYSTEM            │
                         └─────────────────────────────────────────┘

  ┌──────────┐     ┌──────────────┐     ┌──────────────┐     ┌──────────────┐
  │  Metrics  │────▶│   Collector  │────▶│  Aggregator  │────▶│   Decision   │
  │  Sources  │     │   Agents     │     │   (TSDB)     │     │   Engine     │
  └──────────┘     └──────────────┘     └──────────────┘     └──────┬───────┘
   CPU/Mem/RPS                                                      │
   Latency                                                          ▼
   Queue Depth                                              ┌──────────────┐
                                                            │   Scaling    │
  ┌──────────────────────────────────────────────────┐      │   Policies   │
  │              Instance Pool                       │      └──────┬───────┘
  │  ┌────┐  ┌────┐  ┌────┐  ┌────┐  ┌────┐        │             │
  │  │ I1 │  │ I2 │  │ I3 │  │ I4 │  │ I5 │  ...   │◀────────────┘
  │  └────┘  └────┘  └────┘  └────┘  └────┘        │    Scale Up/Down
  └──────────────────────────────────────────────────┘

  ┌──────────────────────────────────────────────────────────────────┐
  │                    SCALING STRATEGIES                            │
  │                                                                  │
  │  Reactive          Predictive         Scheduled                  │
  │  ┌─────┐          ┌─────┐           ┌─────┐                    │
  │  │Thres│          │ ML  │           │Cron │                    │
  │  │hold │          │Model│           │Jobs │                    │
  │  └─────┘          └─────┘           └─────┘                    │
  │  "CPU > 70%"      "Predict peak"    "9AM scale up"             │
  └──────────────────────────────────────────────────────────────────┘

  ┌──────────────────────────────────────────────────────────────────┐
  │                   COOLDOWN & SAFETY                              │
  │                                                                  │
  │  • Cooldown Period: Wait N seconds between scaling actions       │
  │  • Min/Max Bounds: Never go below 2 or above 100 instances      │
  │  • Health Checks:  Only count healthy instances                  │
  │  • Gradual Scale-In: Remove 1 at a time to avoid oscillation    │
  └──────────────────────────────────────────────────────────────────┘
```

### Complete Implementation

```python
"""
Auto Scaling System
===================
A production-grade auto-scaling engine with reactive, predictive,
and scheduled scaling strategies.
"""

import time
import threading
import statistics
import uuid
import json
import logging
from datetime import datetime, timedelta
from dataclasses import dataclass, field
from enum import Enum
from typing import Dict, List, Optional, Callable
from collections import deque
from abc import ABC, abstractmethod
import heapq
import math
import random

logging.basicConfig(level=logging.INFO,
                    format='%(asctime)s [%(levelname)s] %(message)s')
logger = logging.getLogger(__name__)


# ─── Data Models ────────────────────────────────────────────────────

class InstanceState(Enum):
    PENDING = "pending"
    RUNNING = "running"
    DRAINING = "draining"       # Graceful shutdown — stop accepting traffic
    TERMINATING = "terminating"
    TERMINATED = "terminated"


class ScalingDirection(Enum):
    SCALE_OUT = "scale_out"     # Add instances
    SCALE_IN = "scale_in"       # Remove instances
    NO_CHANGE = "no_change"


@dataclass
class Instance:
    instance_id: str
    state: InstanceState
    launch_time: datetime
    health_check_passed: bool = True
    availability_zone: str = "us-east-1a"
    cpu_utilization: float = 0.0
    memory_utilization: float = 0.0
    request_count: int = 0
    metadata: Dict = field(default_factory=dict)

    @property
    def age_seconds(self) -> float:
        return (datetime.utcnow() - self.launch_time).total_seconds()


@dataclass
class ScalingPolicy:
    """Defines WHEN and HOW to scale."""
    policy_name: str
    metric_name: str            # e.g., "cpu_utilization"
    scale_out_threshold: float  # e.g., 70.0 (percent)
    scale_in_threshold: float   # e.g., 30.0 (percent)
    scale_out_amount: int       # e.g., 2 (add 2 instances)
    scale_in_amount: int        # e.g., 1 (remove 1 instance)
    cooldown_seconds: int = 300
    evaluation_periods: int = 3  # Must breach N consecutive periods
    period_seconds: int = 60


@dataclass
class ScalingGroupConfig:
    group_name: str
    min_instances: int = 1
    max_instances: int = 20
    desired_capacity: int = 2
    health_check_interval: int = 30
    health_check_grace_period: int = 120  # New instances get grace
    default_cooldown: int = 300
    termination_policy: str = "oldest_first"  # or "newest_first"
    availability_zones: List[str] = field(
        default_factory=lambda: ["us-east-1a", "us-east-1b"]
    )


@dataclass
class MetricDatapoint:
    timestamp: datetime
    value: float
    metric_name: str
    instance_id: Optional[str] = None


@dataclass
class ScalingActivity:
    activity_id: str
    timestamp: datetime
    direction: ScalingDirection
    from_capacity: int
    to_capacity: int
    reason: str
    status: str = "completed"


# ─── Metrics Collector ──────────────────────────────────────────────

class MetricsStore:
    """Time-series metrics storage (simplified CloudWatch)."""

    def __init__(self, retention_minutes: int = 60):
        self._data: Dict[str, deque] = {}
        self._retention = timedelta(minutes=retention_minutes)
        self._lock = threading.Lock()

    def put_metric(self, metric_name: str, value: float,
                   instance_id: Optional[str] = None):
        key = f"{metric_name}:{instance_id}" if instance_id else metric_name
        dp = MetricDatapoint(
            timestamp=datetime.utcnow(),
            value=value,
            metric_name=metric_name,
            instance_id=instance_id
        )
        with self._lock:
            if key not in self._data:
                self._data[key] = deque()
            self._data[key].append(dp)
            self._evict_old(key)

    def get_metric_statistics(
        self, metric_name: str, period_seconds: int,
        num_periods: int, statistic: str = "Average",
        instance_id: Optional[str] = None
    ) -> List[float]:
        """Get aggregated metric values for the last N periods."""
        key = f"{metric_name}:{instance_id}" if instance_id else metric_name
        now = datetime.utcnow()
        results = []

        with self._lock:
            points = list(self._data.get(key, []))

        for i in range(num_periods):
            period_end = now - timedelta(seconds=i * period_seconds)
            period_start = period_end - timedelta(seconds=period_seconds)
            period_values = [
                dp.value for dp in points
                if period_start <= dp.timestamp < period_end
            ]
            if period_values:
                if statistic == "Average":
                    results.append(statistics.mean(period_values))
                elif statistic == "Maximum":
                    results.append(max(period_values))
                elif statistic == "Minimum":
                    results.append(min(period_values))
                elif statistic == "Sum":
                    results.append(sum(period_values))
                elif statistic == "P99":
                    results.append(self._percentile(period_values, 99))

        return results

    def get_aggregate_across_instances(
        self, metric_name: str, instance_ids: List[str],
        period_seconds: int = 60
    ) -> float:
        """Average a metric across all instances (like group-level CPU)."""
        values = []
        for iid in instance_ids:
            stats = self.get_metric_statistics(
                metric_name, period_seconds, 1, "Average", iid
            )
            if stats:
                values.append(stats[0])
        return statistics.mean(values) if values else 0.0

    def _evict_old(self, key: str):
        cutoff = datetime.utcnow() - self._retention
        while self._data[key] and self._data[key][0].timestamp < cutoff:
            self._data[key].popleft()

    @staticmethod
    def _percentile(values: List[float], pct: float) -> float:
        sorted_v = sorted(values)
        idx = int(math.ceil(pct / 100.0 * len(sorted_v))) - 1
        return sorted_v[max(0, idx)]


# ─── Instance Manager (simulates EC2 API) ──────────────────────────

class InstanceManager:
    """Manages the lifecycle of compute instances."""

    def __init__(self):
        self._instances: Dict[str, Instance] = {}
        self._lock = threading.Lock()
        self._launch_callback: Optional[Callable] = None
        self._terminate_callback: Optional[Callable] = None

    def launch_instance(self, az: str = "us-east-1a") -> Instance:
        instance = Instance(
            instance_id=f"i-{uuid.uuid4().hex[:12]}",
            state=InstanceState.PENDING,
            launch_time=datetime.utcnow(),
            availability_zone=az,
        )
        with self._lock:
            self._instances[instance.instance_id] = instance

        # Simulate boot time
        def boot():
            time.sleep(random.uniform(0.5, 1.5))  # Simulated boot
            with self._lock:
                if instance.instance_id in self._instances:
                    self._instances[instance.instance_id].state = \
                        InstanceState.RUNNING
            logger.info(f"Instance {instance.instance_id} is now RUNNING")

        threading.Thread(target=boot, daemon=True).start()
        logger.info(f"Launching instance {instance.instance_id} in {az}")
        return instance

    def terminate_instance(self, instance_id: str, drain_seconds: int = 10):
        with self._lock:
            if instance_id not in self._instances:
                return
            self._instances[instance_id].state = InstanceState.DRAINING

        logger.info(f"Draining instance {instance_id}...")

        def drain_and_terminate():
            time.sleep(drain_seconds * 0.1)  # Simulated drain
            with self._lock:
                if instance_id in self._instances:
                    self._instances[instance_id].state = \
                        InstanceState.TERMINATED
            logger.info(f"Instance {instance_id} TERMINATED")

        threading.Thread(target=drain_and_terminate, daemon=True).start()

    def get_running_instances(self) -> List[Instance]:
        with self._lock:
            return [i for i in self._instances.values()
                    if i.state == InstanceState.RUNNING]

    def get_all_active_instances(self) -> List[Instance]:
        with self._lock:
            return [i for i in self._instances.values()
                    if i.state in (InstanceState.PENDING,
                                   InstanceState.RUNNING)]

    def get_instance(self, instance_id: str) -> Optional[Instance]:
        return self._instances.get(instance_id)

    def update_health(self, instance_id: str, healthy: bool):
        with self._lock:
            if instance_id in self._instances:
                self._instances[instance_id].health_check_passed = healthy


# ─── Scaling Strategies ────────────────────────────────────────────

class ScalingStrategy(ABC):
    """Base class for scaling strategies."""

    @abstractmethod
    def evaluate(self, current_capacity: int,
                 config: ScalingGroupConfig) -> (ScalingDirection, int, str):
        """Returns (direction, target_capacity, reason)."""
        pass


class TargetTrackingStrategy(ScalingStrategy):
    """
    Maintains a target value for a metric.
    Example: Keep average CPU at 50%.
    """

    def __init__(self, metrics_store: MetricsStore,
                 instance_manager: InstanceManager,
                 target_metric: str = "cpu_utilization",
                 target_value: float = 50.0):
        self.metrics = metrics_store
        self.instance_mgr = instance_manager
        self.target_metric = target_metric
        self.target_value = target_value

    def evaluate(self, current_capacity: int,
                 config: ScalingGroupConfig) -> tuple:
        running = self.instance_mgr.get_running_instances()
        if not running:
            return (ScalingDirection.SCALE_OUT, config.min_instances,
                    "No running instances")

        # Get aggregate metric
        ids = [i.instance_id for i in running]
        current_value = self.metrics.get_aggregate_across_instances(
            self.target_metric, ids
        )

        if current_value == 0:
            return ScalingDirection.NO_CHANGE, current_capacity, "No data"

        # Calculate desired capacity:
        # desired = ceil(current_capacity × (current_value / target_value))
        desired = math.ceil(
            current_capacity * (current_value / self.target_value)
        )
        desired = max(config.min_instances,
                      min(config.max_instances, desired))

        if desired > current_capacity:
            return (ScalingDirection.SCALE_OUT, desired,
                    f"{self.target_metric}={current_value:.1f}% > "
                    f"target={self.target_value}%")
        elif desired < current_capacity:
            return (ScalingDirection.SCALE_IN, desired,
                    f"{self.target_metric}={current_value:.1f}% < "
                    f"target={self.target_value}%")
        return ScalingDirection.NO_CHANGE, current_capacity, "On target"


class StepScalingStrategy(ScalingStrategy):
    """
    Step scaling — different actions for different breach magnitudes.
    Example:
        CPU 60-70% → add 1
        CPU 70-85% → add 2
        CPU 85%+   → add 4
    """

    def __init__(self, metrics_store: MetricsStore,
                 instance_manager: InstanceManager,
                 metric_name: str = "cpu_utilization"):
        self.metrics = metrics_store
        self.instance_mgr = instance_manager
        self.metric_name = metric_name
        self.scale_out_steps = [
            (60, 70, 1),   # (lower_bound, upper_bound, adjustment)
            (70, 85, 2),
            (85, 100, 4),
        ]
        self.scale_in_steps = [
            (20, 30, -1),
            (0, 20, -2),
        ]

    def evaluate(self, current_capacity: int,
                 config: ScalingGroupConfig) -> tuple:
        running = self.instance_mgr.get_running_instances()
        if not running:
            return (ScalingDirection.SCALE_OUT, config.min_instances,
                    "No instances")

        ids = [i.instance_id for i in running]
        current_value = self.metrics.get_aggregate_across_instances(
            self.metric_name, ids
        )

        # Check scale-out steps
        for lower, upper, adj in self.scale_out_steps:
            if lower <= current_value < upper:
                target = min(current_capacity + adj, config.max_instances)
                return (ScalingDirection.SCALE_OUT, target,
                        f"Step: {self.metric_name}={current_value:.1f}% "
                        f"in [{lower},{upper}) → +{adj}")

        # Check scale-in steps
        for lower, upper, adj in self.scale_in_steps:
            if lower <= current_value < upper:
                target = max(current_capacity + adj, config.min_instances)
                return (ScalingDirection.SCALE_IN, target,
                        f"Step: {self.metric_name}={current_value:.1f}% "
                        f"in [{lower},{upper}) → {adj}")

        return ScalingDirection.NO_CHANGE, current_capacity, "Within bounds"


class ScheduledScalingStrategy(ScalingStrategy):
    """
    Time-based scaling — e.g., scale up at 9 AM, scale down at 6 PM.
    """

    def __init__(self):
        self.schedules: List[Dict] = []

    def add_schedule(self, name: str, hour: int, minute: int,
                     desired_capacity: int,
                     days: List[int] = None):
        """days: 0=Mon,...,6=Sun. None = every day."""
        self.schedules.append({
            "name": name,
            "hour": hour,
            "minute": minute,
            "desired": desired_capacity,
            "days": days or list(range(7)),
        })

    def evaluate(self, current_capacity: int,
                 config: ScalingGroupConfig) -> tuple:
        now = datetime.utcnow()
        for sched in self.schedules:
            if (now.weekday() in sched["days"] and
                    now.hour == sched["hour"] and
                    now.minute == sched["minute"]):
                desired = max(config.min_instances,
                              min(config.max_instances, sched["desired"]))
                if desired != current_capacity:
                    direction = (ScalingDirection.SCALE_OUT
                                 if desired > current_capacity
                                 else ScalingDirection.SCALE_IN)
                    return (direction, desired,
                            f"Schedule '{sched['name']}' → {desired}")
        return ScalingDirection.NO_CHANGE, current_capacity, "No schedule"


class PredictiveScalingStrategy(ScalingStrategy):
    """
    Uses historical patterns to predict future load.
    Simplified: uses moving average + trend detection.
    """

    def __init__(self, metrics_store: MetricsStore,
                 instance_manager: InstanceManager,
                 metric_name: str = "request_rate",
                 capacity_per_instance: float = 100.0):
        self.metrics = metrics_store
        self.instance_mgr = instance_manager
        self.metric_name = metric_name
        self.capacity_per_instance = capacity_per_instance
        self.history: deque = deque(maxlen=60)  # Last 60 observations

    def evaluate(self, current_capacity: int,
                 config: ScalingGroupConfig) -> tuple:
        running = self.instance_mgr.get_running_instances()
        if not running:
            return (ScalingDirection.SCALE_OUT, config.min_instances,
                    "No instances")

        ids = [i.instance_id for i in running]
        current_load = self.metrics.get_aggregate_across_instances(
            self.metric_name, ids
        )
        self.history.append(current_load)

        if len(self.history) < 10:
            return ScalingDirection.NO_CHANGE, current_capacity, "Not enough data"

        # Simple linear trend prediction
        recent = list(self.history)[-10:]
        trend = (recent[-1] - recent[0]) / len(recent)
        predicted_load = current_load + trend * 5  # 5 periods ahead

        predicted_capacity = math.ceil(
            predicted_load / self.capacity_per_instance
        )
        predicted_capacity = max(config.min_instances,
                                 min(config.max_instances, predicted_capacity))

        if predicted_capacity > current_capacity:
            return (ScalingDirection.SCALE_OUT, predicted_capacity,
                    f"Predicted load={predicted_load:.0f}, "
                    f"trend={trend:+.1f}/period")
        elif predicted_capacity < current_capacity:
            return (ScalingDirection.SCALE_IN, predicted_capacity,
                    f"Predicted load={predicted_load:.0f}, "
                    f"trend={trend:+.1f}/period")
        return ScalingDirection.NO_CHANGE, current_capacity, "Stable trend"


# ─── Core Auto Scaling Engine ──────────────────────────────────────

class AutoScalingGroup:
    """
    The main auto-scaling controller.
    Coordinates metrics, strategies, and instance lifecycle.
    """

    def __init__(self, config: ScalingGroupConfig,
                 instance_manager: InstanceManager,
                 metrics_store: MetricsStore):
        self.config = config
        self.instance_mgr = instance_manager
        self.metrics = metrics_store
        self.strategies: List[ScalingStrategy] = []
        self.activities: List[ScalingActivity] = []
        self._last_scaling_time: Optional[datetime] = None
        self._running = False
        self._lock = threading.Lock()

        logger.info(f"AutoScalingGroup '{config.group_name}' created | "
                    f"min={config.min_instances}, max={config.max_instances}, "
                    f"desired={config.desired_capacity}")

    def add_strategy(self, strategy: ScalingStrategy):
        self.strategies.append(strategy)
        logger.info(f"Added strategy: {strategy.__class__.__name__}")

    def initialize(self):
        """Launch instances to meet desired capacity."""
        current = len(self.instance_mgr.get_all_active_instances())
        needed = self.config.desired_capacity - current
        if needed > 0:
            logger.info(f"Initializing: launching {needed} instances")
            self._launch_instances(needed)

    def _launch_instances(self, count: int):
        """Launch instances distributed across AZs."""
        azs = self.config.availability_zones
        for i in range(count):
            az = azs[i % len(azs)]  # Round-robin across AZs
            self.instance_mgr.launch_instance(az)

    def _terminate_instances(self, count: int):
        """Terminate instances based on termination policy."""
        running = self.instance_mgr.get_running_instances()
        if not running:
            return

        if self.config.termination_policy == "oldest_first":
            candidates = sorted(running, key=lambda i: i.launch_time)
        elif self.config.termination_policy == "newest_first":
            candidates = sorted(running, key=lambda i: i.launch_time,
                                reverse=True)
        else:
            candidates = running

        for i in range(min(count, len(candidates))):
            self.instance_mgr.terminate_instance(
                candidates[i].instance_id
            )

    def _is_in_cooldown(self) -> bool:
        if self._last_scaling_time is None:
            return False
        elapsed = (datetime.utcnow() - self._last_scaling_time).total_seconds()
        return elapsed < self.config.default_cooldown

    def _record_activity(self, direction: ScalingDirection,
                         from_cap: int, to_cap: int, reason: str):
        activity = ScalingActivity(
            activity_id=f"act-{uuid.uuid4().hex[:8]}",
            timestamp=datetime.utcnow(),
            direction=direction,
            from_capacity=from_cap,
            to_capacity=to_cap,
            reason=reason,
        )
        self.activities.append(activity)
        logger.info(f"SCALING ACTIVITY: {direction.value} "
                    f"{from_cap} → {to_cap} | Reason: {reason}")

    def evaluate_and_scale(self):
        """Main control loop iteration."""
        if self._is_in_cooldown():
            logger.debug("In cooldown period — skipping evaluation")
            return

        current_capacity = len(self.instance_mgr.get_all_active_instances())

        # Evaluate all strategies — most aggressive wins
        best_direction = ScalingDirection.NO_CHANGE
        best_target = current_capacity
        best_reason = ""

        for strategy in self.strategies:
            direction, target, reason = strategy.evaluate(
                current_capacity, self.config
            )
            if direction == ScalingDirection.SCALE_OUT:
                if target > best_target:
                    best_direction = direction
                    best_target = target
                    best_reason = reason
            elif direction == ScalingDirection.SCALE_IN:
                if (best_direction != ScalingDirection.SCALE_OUT and
                        target < best_target):
                    best_direction = direction
                    best_target = target
                    best_reason = reason

        # Enforce bounds
        best_target = max(self.config.min_instances,
                          min(self.config.max_instances, best_target))

        # Execute scaling
        if best_direction == ScalingDirection.SCALE_OUT:
            diff = best_target - current_capacity
            if diff > 0:
                self._launch_instances(diff)
                self._record_activity(best_direction, current_capacity,
                                      best_target, best_reason)
                self._last_scaling_time = datetime.utcnow()

        elif best_direction == ScalingDirection.SCALE_IN:
            diff = current_capacity - best_target
            if diff > 0:
                self._terminate_instances(diff)
                self._record_activity(best_direction, current_capacity,
                                      best_target, best_reason)
                self._last_scaling_time = datetime.utcnow()

    def health_check_loop(self):
        """Replace unhealthy instances."""
        running = self.instance_mgr.get_running_instances()
        for instance in running:
            if instance.age_seconds < self.config.health_check_grace_period:
                continue  # Grace period for new instances
            if not instance.health_check_passed:
                logger.warning(f"Unhealthy instance {instance.instance_id} "
                               f"— replacing")
                self.instance_mgr.terminate_instance(instance.instance_id)
                az = instance.availability_zone
                self.instance_mgr.launch_instance(az)

    def start(self, interval: float = 10.0):
        """Start the auto-scaling control loop."""
        self._running = True
        self.initialize()

        def loop():
            while self._running:
                try:
                    self.evaluate_and_scale()
                    self.health_check_loop()
                except Exception as e:
                    logger.error(f"Auto-scaling error: {e}")
                time.sleep(interval)

        self._thread = threading.Thread(target=loop, daemon=True)
        self._thread.start()
        logger.info("Auto-scaling loop started")

    def stop(self):
        self._running = False
        logger.info("Auto-scaling loop stopped")

    def get_status(self) -> Dict:
        active = self.instance_mgr.get_all_active_instances()
        running = self.instance_mgr.get_running_instances()
        return {
            "group_name": self.config.group_name,
            "desired_capacity": self.config.desired_capacity,
            "active_instances": len(active),
            "running_instances": len(running),
            "min": self.config.min_instances,
            "max": self.config.max_instances,
            "in_cooldown": self._is_in_cooldown(),
            "recent_activities": [
                {
                    "id": a.activity_id,
                    "direction": a.direction.value,
                    "from": a.from_capacity,
                    "to": a.to_capacity,
                    "reason": a.reason,
                    "time": a.timestamp.isoformat(),
                }
                for a in self.activities[-5:]
            ]
        }


# ─── Load Simulator ────────────────────────────────────────────────

class LoadSimulator:
    """Simulates varying load to test auto-scaling."""

    def __init__(self, metrics_store: MetricsStore,
                 instance_manager: InstanceManager):
        self.metrics = metrics_store
        self.instance_mgr = instance_manager
        self._running = False

    def start(self, pattern: str = "sine"):
        """Generate load patterns: 'sine', 'spike', 'ramp'."""
        self._running = True

        def generate():
            t = 0
            while self._running:
                running = self.instance_mgr.get_running_instances()
                if pattern == "sine":
                    # Oscillates between 20% and 90%
                    base_load = 55 + 35 * math.sin(t * 0.1)
                elif pattern == "spike":
                    # Normal 30%, spike to 95% periodically
                    base_load = 30 if t % 50 > 10 else 95
                elif pattern == "ramp":
                    # Steadily increasing
                    base_load = min(20 + t * 2, 95)
                else:
                    base_load = 50

                for inst in running:
                    noise = random.gauss(0, 5)
                    cpu = max(0, min(100, base_load + noise))
                    self.metrics.put_metric("cpu_utilization", cpu,
                                            inst.instance_id)
                    self.metrics.put_metric("request_rate",
                                            cpu * 10 + random.gauss(0, 50),
                                            inst.instance_id)
                t += 1
                time.sleep(1)

        threading.Thread(target=generate, daemon=True).start()

    def stop(self):
        self._running = False


# ─── AWS Integration Example ───────────────────────────────────────

class AWSAutoScalingClient:
    """
    Real AWS Auto Scaling integration using boto3.
    This wraps the actual AWS API.
    """

    def __init__(self, region: str = "us-east-1"):
        try:
            import boto3
            self.client = boto3.client('autoscaling', region_name=region)
            self.ec2 = boto3.client('ec2', region_name=region)
        except ImportError:
            logger.warning("boto3 not installed — using simulation mode")
            self.client = None

    def create_launch_template(self, name: str, ami_id: str,
                               instance_type: str = "t3.micro"):
        if not self.client:
            return {"simulated": True}
        return self.ec2.create_launch_template(
            LaunchTemplateName=name,
            LaunchTemplateData={
                'ImageId': ami_id,
                'InstanceType': instance_type,
                'Monitoring': {'Enabled': True},
            }
        )

    def create_auto_scaling_group(
        self, group_name: str, launch_template: str,
        min_size: int = 1, max_size: int = 10,
        desired: int = 2, azs: List[str] = None
    ):
        if not self.client:
            return {"simulated": True}
        return self.client.create_auto_scaling_group(
            AutoScalingGroupName=group_name,
            LaunchTemplate={
                'LaunchTemplateName': launch_template,
                'Version': '$Latest',
            },
            MinSize=min_size,
            MaxSize=max_size,
            DesiredCapacity=desired,
            AvailabilityZones=azs or ['us-east-1a', 'us-east-1b'],
            HealthCheckType='ELB',
            HealthCheckGracePeriod=120,
        )

    def put_scaling_policy(self, group_name: str, policy_name: str,
                           target_value: float = 50.0):
        if not self.client:
            return {"simulated": True}
        return self.client.put_scaling_policy(
            AutoScalingGroupName=group_name,
            PolicyName=policy_name,
            PolicyType='TargetTrackingScaling',
            TargetTrackingConfiguration={
                'PredefinedMetricSpecification': {
                    'PredefinedMetricType': 'ASGAverageCPUUtilization',
                },
                'TargetValue': target_value,
            },
        )


# ─── Demo ───────────────────────────────────────────────────────────

def main():
    print("=" * 70)
    print("         AUTO SCALING SYSTEM DEMO")
    print("=" * 70)

    # Create components
    metrics = MetricsStore(retention_minutes=30)
    instance_mgr = InstanceManager()

    # Configure auto-scaling group
    config = ScalingGroupConfig(
        group_name="web-service-asg",
        min_instances=2,
        max_instances=10,
        desired_capacity=2,
        default_cooldown=5,  # Short for demo
        availability_zones=["us-east-1a", "us-east-1b"],
    )

    # Create auto-scaling group
    asg = AutoScalingGroup(config, instance_mgr, metrics)

    # Add strategies
    target_tracking = TargetTrackingStrategy(
        metrics, instance_mgr,
        target_metric="cpu_utilization",
        target_value=50.0,
    )
    asg.add_strategy(target_tracking)

    step_scaling = StepScalingStrategy(metrics, instance_mgr)
    asg.add_strategy(step_scaling)

    # Start load simulator with a sine wave pattern
    simulator = LoadSimulator(metrics, instance_mgr)

    # Initialize and start
    asg.initialize()
    time.sleep(2)  # Wait for initial instances to boot

    simulator.start(pattern="spike")
    asg.start(interval=3)

    # Run for a while and observe
    for i in range(8):
        time.sleep(3)
        status = asg.get_status()
        print(f"\n--- Tick {i+1} ---")
        print(f"  Running: {status['running_instances']}, "
              f"Active: {status['active_instances']}, "
              f"Cooldown: {status['in_cooldown']}")
        if status['recent_activities']:
            last = status['recent_activities'][-1]
            print(f"  Last activity: {last['direction']} "
                  f"({last['from']}→{last['to']}): {last['reason']}")

    simulator.stop()
    asg.stop()

    print("\n" + "=" * 70)
    print("Final Status:")
    print(json.dumps(asg.get_status(), indent=2))


if __name__ == "__main__":
    main()
```

---

<a id="34"></a>
## 34. CI/CD Pipeline

### Core Concept

A CI/CD pipeline automates the process of building, testing, and deploying software. **Continuous Integration (CI)** merges and validates code frequently; **Continuous Delivery/Deployment (CD)** automates releases.

```
  ┌─────────────────────────────────────────────────────────────────────┐
  │                        CI/CD PIPELINE                               │
  └─────────────────────────────────────────────────────────────────────┘

  Developer                                                   Production
  ─────────                                                   ──────────

  git push ──▶ ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐
               │  SOURCE  │──▶│  BUILD   │──▶│   TEST   │──▶│  DEPLOY  │
               │  STAGE   │   │  STAGE   │   │  STAGE   │   │  STAGE   │
               └──────────┘   └──────────┘   └──────────┘   └──────────┘
                    │              │               │               │
                    ▼              ▼               ▼               ▼
               ┌────────┐    ┌────────┐     ┌────────┐      ┌────────┐
               │Webhook │    │Compile │     │Unit    │      │Staging │
               │Clone   │    │Docker  │     │Integr. │      │Canary  │
               │Validate│    │Build   │     │E2E     │      │Prod    │
               └────────┘    │Artifact│     │Security│      │Rollback│
                             └────────┘     └────────┘      └────────┘

  ┌─────────────────────────────────────────────────────────────────────┐
  │                     PIPELINE STAGES DETAIL                          │
  │                                                                     │
  │  ┌─ Source ────────────────────────────────────────────────────┐    │
  │  │  • Git webhook triggers pipeline                            │    │
  │  │  • Checkout code, resolve dependencies                      │    │
  │  │  • Validate branch policies                                 │    │
  │  └─────────────────────────────────────────────────────────────┘    │
  │                              │                                      │
  │                              ▼                                      │
  │  ┌─ Build ────────────────────────────────────────────────────┐    │
  │  │  • Compile / Transpile source code                          │    │
  │  │  • Build Docker images                                      │    │
  │  │  • Run linting & static analysis                            │    │
  │  │  • Push artifacts to registry                               │    │
  │  └─────────────────────────────────────────────────────────────┘    │
  │                              │                                      │
  │                              ▼                                      │
  │  ┌─ Test ─────────────────────────────────────────────────────┐    │
  │  │  • Unit tests (fast, isolated)                              │    │
  │  │  • Integration tests (DB, API interactions)                 │    │
  │  │  • End-to-End tests (full user workflows)                   │    │
  │  │  • Security scanning (SAST/DAST)                            │    │
  │  │  • Performance/Load tests                                   │    │
  │  │  • Code coverage gate (≥ 80%)                               │    │
  │  └─────────────────────────────────────────────────────────────┘    │
  │                              │                                      │
  │                              ▼                                      │
  │  ┌─ Deploy ───────────────────────────────────────────────────┐    │
  │  │  • Deploy to staging  →  smoke tests                        │    │
  │  │  • Manual approval gate (optional)                          │    │
  │  │  • Deploy to production (blue-green / canary / rolling)     │    │
  │  │  • Post-deploy verification                                 │    │
  │  │  • Automated rollback on failure                            │    │
  │  └─────────────────────────────────────────────────────────────┘    │
  └─────────────────────────────────────────────────────────────────────┘

  ┌─────────────────────────────────────────────────────────────────────┐
  │                   ARTIFACT FLOW                                     │
  │                                                                     │
  │  Source ──▶ Docker Image ──▶ ECR Registry ──▶ ECS/EKS Deployment   │
  │  Code       (tagged with      (versioned)     (rolling update)      │
  │             commit SHA)                                             │
  └─────────────────────────────────────────────────────────────────────┘
```

### Complete Implementation

```python
"""
CI/CD Pipeline System
=====================
A complete pipeline engine that models source, build, test, and deploy
stages with pluggable steps, parallel execution, and artifact management.
"""

import os
import time
import uuid
import json
import hashlib
import subprocess
import threading
import logging
from datetime import datetime
from dataclasses import dataclass, field
from enum import Enum
from typing import Dict, List, Optional, Callable, Any
from abc import ABC, abstractmethod
from collections import OrderedDict
from concurrent.futures import ThreadPoolExecutor, as_completed

logging.basicConfig(level=logging.INFO,
                    format='%(asctime)s [%(levelname)s] %(message)s')
logger = logging.getLogger(__name__)


# ─── Data Models ────────────────────────────────────────────────────

class StepStatus(Enum):
    PENDING = "pending"
    RUNNING = "running"
    SUCCESS = "success"
    FAILED = "failed"
    SKIPPED = "skipped"


class PipelineStatus(Enum):
    QUEUED = "queued"
    RUNNING = "running"
    SUCCESS = "success"
    FAILED = "failed"
    CANCELLED = "cancelled"


@dataclass
class Artifact:
    name: str
    path: str
    artifact_type: str           # "docker_image", "binary", "test_report"
    checksum: str = ""
    size_bytes: int = 0
    metadata: Dict = field(default_factory=dict)
    created_at: datetime = field(default_factory=datetime.utcnow)


@dataclass
class StepResult:
    step_name: str
    status: StepStatus
    duration_seconds: float
    output: str = ""
    error: str = ""
    artifacts: List[Artifact] = field(default_factory=list)


@dataclass
class PipelineContext:
    """Shared context passed through the pipeline."""
    pipeline_id: str
    commit_sha: str
    branch: str
    repository: str
    trigger: str = "push"         # push, pr, manual, schedule
    environment: str = "staging"
    artifacts: Dict[str, Artifact] = field(default_factory=dict)
    variables: Dict[str, str] = field(default_factory=dict)
    step_results: Dict[str, StepResult] = field(default_factory=dict)

    def set_artifact(self, name: str, artifact: Artifact):
        self.artifacts[name] = artifact

    def get_artifact(self, name: str) -> Optional[Artifact]:
        return self.artifacts.get(name)


# ─── Pipeline Steps ────────────────────────────────────────────────

class PipelineStep(ABC):
    """Base class for pipeline steps."""

    def __init__(self, name: str, timeout_seconds: int = 300,
                 continue_on_failure: bool = False):
        self.name = name
        self.timeout = timeout_seconds
        self.continue_on_failure = continue_on_failure

    @abstractmethod
    def execute(self, context: PipelineContext) -> StepResult:
        pass


class ShellStep(PipelineStep):
    """Runs a shell command."""

    def __init__(self, name: str, command: str, **kwargs):
        super().__init__(name, **kwargs)
        self.command = command

    def execute(self, context: PipelineContext) -> StepResult:
        start = time.time()
        logger.info(f"  🔧 [{self.name}] Running: {self.command}")

        # Simulate — in production this would be subprocess.run
        # with proper timeout, env vars, working dir
        time.sleep(0.2)  # Simulated execution
        output = f"Simulated output for: {self.command}"

        duration = time.time() - start
        return StepResult(
            step_name=self.name,
            status=StepStatus.SUCCESS,
            duration_seconds=duration,
            output=output,
        )


class GitCloneStep(PipelineStep):
    """Clone repository and checkout specific commit."""

    def execute(self, context: PipelineContext) -> StepResult:
        start = time.time()
        logger.info(f"  📥 [{self.name}] Cloning {context.repository} "
                     f"@ {context.commit_sha[:8]}")

        time.sleep(0.3)  # Simulated clone

        context.variables["workspace"] = f"/tmp/build/{context.pipeline_id}"
        duration = time.time() - start
        return StepResult(
            step_name=self.name,
            status=StepStatus.SUCCESS,
            duration_seconds=duration,
            output=f"Cloned to {context.variables['workspace']}",
        )


class DockerBuildStep(PipelineStep):
    """Build a Docker image."""

    def __init__(self, name: str, dockerfile: str = "Dockerfile",
                 image_name: str = "app", **kwargs):
        super().__init__(name, **kwargs)
        self.dockerfile = dockerfile
        self.image_name = image_name

    def execute(self, context: PipelineContext) -> StepResult:
        start = time.time()
        tag = context.commit_sha[:8]
        full_image = f"{self.image_name}:{tag}"

        logger.info(f"  🐳 [{self.name}] Building {full_image}")

        # In production:
        # subprocess.run(
        #     ["docker", "build", "-t", full_image,
        #      "-f", self.dockerfile, "."],
        #     check=True
        # )

        time.sleep(0.5)  # Simulated build

        artifact = Artifact(
            name="docker_image",
            path=full_image,
            artifact_type="docker_image",
            checksum=hashlib.sha256(full_image.encode()).hexdigest()[:12],
            metadata={"tag": tag, "image": self.image_name},
        )
        context.set_artifact("docker_image", artifact)

        duration = time.time() - start
        return StepResult(
            step_name=self.name,
            status=StepStatus.SUCCESS,
            duration_seconds=duration,
            output=f"Built image: {full_image}",
            artifacts=[artifact],
        )


class DockerPushStep(PipelineStep):
    """Push Docker image to a registry (ECR)."""

    def __init__(self, name: str,
                 registry: str = "123456789.dkr.ecr.us-east-1.amazonaws.com",
                 **kwargs):
        super().__init__(name, **kwargs)
        self.registry = registry

    def execute(self, context: PipelineContext) -> StepResult:
        start = time.time()
        image_artifact = context.get_artifact("docker_image")
        if not image_artifact:
            return StepResult(self.name, StepStatus.FAILED, 0,
                              error="No docker image artifact found")

        remote_image = f"{self.registry}/{image_artifact.path}"
        logger.info(f"  📤 [{self.name}] Pushing {remote_image}")

        time.sleep(0.3)  # Simulated push

        image_artifact.metadata["remote_path"] = remote_image
        duration = time.time() - start
        return StepResult(
            step_name=self.name,
            status=StepStatus.SUCCESS,
            duration_seconds=duration,
            output=f"Pushed to {remote_image}",
        )


class TestStep(PipelineStep):
    """Run tests (unit, integration, e2e)."""

    def __init__(self, name: str, test_type: str = "unit",
                 test_command: str = "pytest", coverage_threshold: float = 80,
                 **kwargs):
        super().__init__(name, **kwargs)
        self.test_type = test_type
        self.test_command = test_command
        self.coverage_threshold = coverage_threshold

    def execute(self, context: PipelineContext) -> StepResult:
        start = time.time()
        logger.info(f"  🧪 [{self.name}] Running {self.test_type} tests")

        time.sleep(0.4)  # Simulated tests

        # Simulated results
        import random
        tests_run = random.randint(50, 200)
        tests_passed = tests_run - random.randint(0, 2)
        coverage = random.uniform(75, 95)
        all_passed = tests_passed == tests_run

        # Check coverage gate
        coverage_passed = coverage >= self.coverage_threshold

        report = Artifact(
            name=f"{self.test_type}_report",
            path=f"/reports/{self.test_type}_results.xml",
            artifact_type="test_report",
            metadata={
                "tests_run": tests_run,
                "tests_passed": tests_passed,
                "tests_failed": tests_run - tests_passed,
                "coverage": round(coverage, 2),
            },
        )
        context.set_artifact(f"{self.test_type}_report", report)

        status = StepStatus.SUCCESS if (all_passed and coverage_passed) \
            else StepStatus.FAILED
        duration = time.time() - start

        output = (f"{tests_passed}/{tests_run} tests passed | "
                  f"Coverage: {coverage:.1f}%")
        error = ""
        if not all_passed:
            error += f"{tests_run - tests_passed} tests failed. "
        if not coverage_passed:
            error += (f"Coverage {coverage:.1f}% below threshold "
                      f"{self.coverage_threshold}%")

        return StepResult(
            step_name=self.name,
            status=status,
            duration_seconds=duration,
            output=output,
            error=error,
            artifacts=[report],
        )


class SecurityScanStep(PipelineStep):
    """Run security scanning (SAST/dependency check)."""

    def execute(self, context: PipelineContext) -> StepResult:
        start = time.time()
        logger.info(f"  🔒 [{self.name}] Running security scan")

        time.sleep(0.3)

        import random
        vulnerabilities = {
            "critical": random.randint(0, 1),
            "high": random.randint(0, 3),
            "medium": random.randint(0, 10),
            "low": random.randint(0, 20),
        }

        has_blockers = vulnerabilities["critical"] > 0
        status = StepStatus.FAILED if has_blockers else StepStatus.SUCCESS
        duration = time.time() - start

        return StepResult(
            step_name=self.name,
            status=status,
            duration_seconds=duration,
            output=f"Vulnerabilities: {json.dumps(vulnerabilities)}",
            error="Critical vulnerabilities found!" if has_blockers else "",
        )


class DeployStep(PipelineStep):
    """Deploy to target environment."""

    def __init__(self, name: str, environment: str = "staging",
                 strategy: str = "rolling",
                 requires_approval: bool = False, **kwargs):
        super().__init__(name, **kwargs)
        self.environment = environment
        self.strategy = strategy
        self.requires_approval = requires_approval

    def execute(self, context: PipelineContext) -> StepResult:
        start = time.time()

        if self.requires_approval:
            logger.info(f"  ⏸️  [{self.name}] Waiting for approval...")
            # In production, this would wait for human input
            time.sleep(0.2)
            logger.info(f"  ✅ [{self.name}] Approved!")

        image = context.get_artifact("docker_image")
        image_path = image.path if image else "unknown:latest"

        logger.info(f"  🚀 [{self.name}] Deploying {image_path} "
                     f"to {self.environment} ({self.strategy})")

        time.sleep(0.5)  # Simulated deploy

        duration = time.time() - start
        return StepResult(
            step_name=self.name,
            status=StepStatus.SUCCESS,
            duration_seconds=duration,
            output=(f"Deployed {image_path} to {self.environment} "
                    f"using {self.strategy} strategy"),
        )


class ApprovalGate(PipelineStep):
    """Manual approval gate between stages."""

    def __init__(self, name: str, approvers: List[str] = None, **kwargs):
        super().__init__(name, **kwargs)
        self.approvers = approvers or ["lead-dev", "devops"]

    def execute(self, context: PipelineContext) -> StepResult:
        start = time.time()
        logger.info(f"  ⏸️  [{self.name}] Approval required from: "
                     f"{', '.join(self.approvers)}")
        # Simulate auto-approval for demo
        time.sleep(0.2)
        logger.info(f"  ✅ [{self.name}] Approved by lead-dev")
        return StepResult(
            step_name=self.name,
            status=StepStatus.SUCCESS,
            duration_seconds=time.time() - start,
            output="Approved by lead-dev",
        )


# ─── Pipeline Stage ────────────────────────────────────────────────

class PipelineStage:
    """A group of steps that can run sequentially or in parallel."""

    def __init__(self, name: str, parallel: bool = False):
        self.name = name
        self.steps: List[PipelineStep] = []
        self.parallel = parallel
        self.status = StepStatus.PENDING

    def add_step(self, step: PipelineStep):
        self.steps.append(step)
        return self

    def execute(self, context: PipelineContext) -> List[StepResult]:
        logger.info(f"\n{'='*50}")
        logger.info(f"📋 STAGE: {self.name} "
                     f"({'parallel' if self.parallel else 'sequential'})")
        logger.info(f"{'='*50}")

        self.status = StepStatus.RUNNING
        results = []

        if self.parallel:
            results = self._execute_parallel(context)
        else:
            results = self._execute_sequential(context)

        # Determine stage status
        failed = [r for r in results if r.status == StepStatus.FAILED]
        if failed:
            non_continuable = [
                r for r in failed
                if not any(s.name == r.step_name and s.continue_on_failure
                           for s in self.steps)
            ]
            self.status = StepStatus.FAILED if non_continuable \
                else StepStatus.SUCCESS
        else:
            self.status = StepStatus.SUCCESS

        return results

    def _execute_sequential(self, context: PipelineContext) -> List[StepResult]:
        results = []
        for step in self.steps:
            result = step.execute(context)
            results.append(result)
            context.step_results[step.name] = result

            if result.status == StepStatus.FAILED and \
               not step.continue_on_failure:
                logger.error(f"  ❌ Step '{step.name}' failed — "
                             f"aborting stage")
                break
            else:
                emoji = "✅" if result.status == StepStatus.SUCCESS else "⚠️"
                logger.info(f"  {emoji} Step '{step.name}' "
                            f"{result.status.value} "
                            f"({result.duration_seconds:.1f}s)")
        return results

    def _execute_parallel(self, context: PipelineContext) -> List[StepResult]:
        results = []
        with ThreadPoolExecutor(max_workers=4) as executor:
            futures = {
                executor.submit(step.execute, context): step
                for step in self.steps
            }
            for future in as_completed(futures):
                step = futures[future]
                result = future.result()
                results.append(result)
                context.step_results[step.name] = result
                emoji = "✅" if result.status == StepStatus.SUCCESS else "❌"
                logger.info(f"  {emoji} Step '{step.name}' "
                            f"{result.status.value} "
                            f"({result.duration_seconds:.1f}s)")
        return results


# ─── Pipeline Engine ───────────────────────────────────────────────

class Pipeline:
    """The main CI/CD pipeline."""

    def __init__(self, name: str):
        self.name = name
        self.stages: List[PipelineStage] = []
        self.status = PipelineStatus.QUEUED
        self.start_time: Optional[datetime] = None
        self.end_time: Optional[datetime] = None
        self._notifications: List[Callable] = []

    def add_stage(self, stage: PipelineStage) -> 'Pipeline':
        self.stages.append(stage)
        return self

    def on_complete(self, callback: Callable):
        self._notifications.append(callback)

    def run(self, context: PipelineContext) -> Dict:
        self.status = PipelineStatus.RUNNING
        self.start_time = datetime.utcnow()

        logger.info(f"\n{'#'*60}")
        logger.info(f"🚀 PIPELINE: {self.name}")
        logger.info(f"   Commit: {context.commit_sha[:8]} "
                     f"| Branch: {context.branch}")
        logger.info(f"   Trigger: {context.trigger}")
        logger.info(f"{'#'*60}")

        all_results = {}

        for stage in self.stages:
            results = stage.execute(context)
            all_results[stage.name] = results

            if stage.status == StepStatus.FAILED:
                self.status = PipelineStatus.FAILED
                logger.error(f"\n💥 Pipeline FAILED at stage: {stage.name}")
                break
        else:
            self.status = PipelineStatus.SUCCESS
            logger.info(f"\n🎉 Pipeline SUCCEEDED!")

        self.end_time = datetime.utcnow()
        total_duration = (self.end_time - self.start_time).total_seconds()

        # Notify
        for callback in self._notifications:
            callback(self.status, context)

        # Generate report
        report = self._generate_report(context, all_results, total_duration)
        return report

    def _generate_report(self, context: PipelineContext,
                         all_results: Dict, total_duration: float) -> Dict:
        report = {
            "pipeline": self.name,
            "pipeline_id": context.pipeline_id,
            "status": self.status.value,
            "commit": context.commit_sha,
            "branch": context.branch,
            "total_duration_seconds": round(total_duration, 2),
            "stages": {},
            "artifacts": {
                name: {
                    "path": a.path,
                    "type": a.artifact_type,
                    "checksum": a.checksum,
                }
                for name, a in context.artifacts.items()
            }
        }

        for stage_name, results in all_results.items():
            report["stages"][stage_name] = [
                {
                    "step": r.step_name,
                    "status": r.status.value,
                    "duration": round(r.duration_seconds, 2),
                    "output": r.output[:200],
                    "error": r.error,
                }
                for r in results
            ]

        return report


# ─── Pipeline Builder (Fluent API) ─────────────────────────────────

class PipelineBuilder:
    """Fluent builder for creating pipelines from config."""

    @staticmethod
    def create_standard_pipeline(
        app_name: str = "my-app",
        registry: str = "123456789.dkr.ecr.us-east-1.amazonaws.com",
        run_security_scan: bool = True,
        require_approval: bool = True,
    ) -> Pipeline:
        pipeline = Pipeline(f"{app_name}-pipeline")

        # Stage 1: Source
        source_stage = PipelineStage("source")
        source_stage.add_step(
            GitCloneStep("git-clone")
        )
        source_stage.add_step(
            ShellStep("install-deps", "pip install -r requirements.txt")
        )
        pipeline.add_stage(source_stage)

        # Stage 2: Build
        build_stage = PipelineStage("build")
        build_stage.add_step(
            ShellStep("lint", "flake8 . --max-line-length=100")
        )
        build_stage.add_step(
            DockerBuildStep("docker-build", image_name=app_name)
        )
        build_stage.add_step(
            DockerPushStep("docker-push", registry=registry)
        )
        pipeline.add_stage(build_stage)

        # Stage 3: Test (parallel)
        test_stage = PipelineStage("test", parallel=True)
        test_stage.add_step(
            TestStep("unit-tests", test_type="unit",
                     coverage_threshold=80)
        )
        test_stage.add_step(
            TestStep("integration-tests", test_type="integration",
                     coverage_threshold=60,
                     continue_on_failure=True)
        )
        if run_security_scan:
            test_stage.add_step(
                SecurityScanStep("security-scan",
                                 continue_on_failure=True)
            )
        pipeline.add_stage(test_stage)

        # Stage 4: Deploy to Staging
        staging_stage = PipelineStage("deploy-staging")
        staging_stage.add_step(
            DeployStep("deploy-staging", environment="staging",
                       strategy="rolling")
        )
        staging_stage.add_step(
            ShellStep("smoke-test", "curl -f http://staging.example.com/health")
        )
        pipeline.add_stage(staging_stage)

        # Stage 5: Approval + Production
        if require_approval:
            approval_stage = PipelineStage("approval")
            approval_stage.add_step(
                ApprovalGate("prod-approval",
                             approvers=["tech-lead", "sre-team"])
            )
            pipeline.add_stage(approval_stage)

        prod_stage = PipelineStage("deploy-production")
        prod_stage.add_step(
            DeployStep("deploy-prod", environment="production",
                       strategy="blue-green")
        )
        pipeline.add_stage(prod_stage)

        return pipeline


# ─── Pipeline Runner (webhook handler) ─────────────────────────────

class PipelineRunner:
    """Manages pipeline execution, queuing, and history."""

    def __init__(self):
        self._history: List[Dict] = []
        self._running: Dict[str, Pipeline] = {}
        self._queue: List[PipelineContext] = []
        self._max_concurrent = 3
        self._lock = threading.Lock()

    def trigger(self, pipeline: Pipeline, commit_sha: str,
                branch: str, repository: str,
                trigger_type: str = "push") -> Dict:
        context = PipelineContext(
            pipeline_id=f"pipe-{uuid.uuid4().hex[:8]}",
            commit_sha=commit_sha,
            branch=branch,
            repository=repository,
            trigger=trigger_type,
        )

        report = pipeline.run(context)
        self._history.append(report)
        return report

    def get_history(self, limit: int = 10) -> List[Dict]:
        return self._history[-limit:]


# ─── Webhook Server (simplified) ──────────────────────────────────

class WebhookHandler:
    """
    Handles incoming webhooks from GitHub/GitLab.
    In production, use Flask/FastAPI.
    """

    def __init__(self, runner: PipelineRunner):
        self.runner = runner
        self.pipeline_factory = PipelineBuilder.create_standard_pipeline

    def handle_push_event(self, payload: Dict) -> Dict:
        """Process a git push webhook."""
        commit = payload.get("after", "abc123def456")
        branch = payload.get("ref", "refs/heads/main").split("/")[-1]
        repo = payload.get("repository", {}).get(
            "full_name", "org/my-app")

        # Only run on main/develop branches
        if branch not in ("main", "develop"):
            logger.info(f"Skipping pipeline for branch: {branch}")
            return {"status": "skipped", "reason": "non-deployable branch"}

        pipeline = self.pipeline_factory(app_name="my-app")

        # Add notification
        pipeline.on_complete(lambda status, ctx:
            logger.info(f"📧 Notification: Pipeline {ctx.pipeline_id} "
                        f"finished with status: {status.value}"))

        report = self.runner.trigger(
            pipeline, commit, branch, repo, "push"
        )
        return report


# ─── Pipeline-as-Code (YAML-like config) ──────────────────────────

PIPELINE_CONFIG = {
    "name": "my-app-pipeline",
    "trigger": {
        "branches": ["main", "develop"],
        "events": ["push", "pull_request"],
    },
    "stages": [
        {
            "name": "source",
            "steps": [
                {"type": "git_clone"},
                {"type": "shell", "command": "pip install -r requirements.txt"},
            ]
        },
        {
            "name": "build",
            "steps": [
                {"type": "shell", "command": "flake8 ."},
                {"type": "docker_build", "image": "my-app"},
                {"type": "docker_push", "registry": "ecr"},
            ]
        },
        {
            "name": "test",
            "parallel": True,
            "steps": [
                {"type": "test", "test_type": "unit",
                 "coverage_threshold": 80},
                {"type": "test", "test_type": "integration"},
                {"type": "security_scan"},
            ]
        },
        {
            "name": "deploy-staging",
            "steps": [
                {"type": "deploy", "environment": "staging",
                 "strategy": "rolling"},
            ]
        },
        {
            "name": "deploy-production",
            "steps": [
                {"type": "approval", "approvers": ["tech-lead"]},
                {"type": "deploy", "environment": "production",
                 "strategy": "blue-green"},
            ]
        },
    ]
}


def build_pipeline_from_config(config: Dict) -> Pipeline:
    """Parse YAML/JSON config into a Pipeline object."""
    pipeline = Pipeline(config["name"])

    step_factory = {
        "git_clone": lambda c: GitCloneStep("git-clone"),
        "shell": lambda c: ShellStep(
            c.get("name", "shell"), c["command"]),
        "docker_build": lambda c: DockerBuildStep(
            "docker-build", image_name=c.get("image", "app")),
        "docker_push": lambda c: DockerPushStep(
            "docker-push", registry=c.get("registry", "ecr")),
        "test": lambda c: TestStep(
            f"{c.get('test_type','unit')}-tests",
            test_type=c.get("test_type", "unit"),
            coverage_threshold=c.get("coverage_threshold", 80)),
        "security_scan": lambda c: SecurityScanStep("security-scan",
                                                     continue_on_failure=True),
        "deploy": lambda c: DeployStep(
            f"deploy-{c.get('environment','staging')}",
            environment=c.get("environment", "staging"),
            strategy=c.get("strategy", "rolling")),
        "approval": lambda c: ApprovalGate(
            "approval", approvers=c.get("approvers", [])),
    }

    for stage_cfg in config["stages"]:
        stage = PipelineStage(
            stage_cfg["name"],
            parallel=stage_cfg.get("parallel", False)
        )
        for step_cfg in stage_cfg["steps"]:
            factory = step_factory.get(step_cfg["type"])
            if factory:
                stage.add_step(factory(step_cfg))
        pipeline.add_stage(stage)

    return pipeline


# ─── Demo ───────────────────────────────────────────────────────────

def main():
    print("=" * 70)
    print("         CI/CD PIPELINE SYSTEM DEMO")
    print("=" * 70)

    runner = PipelineRunner()

    # Method 1: Using the builder
    print("\n" + "─" * 60)
    print("Method 1: Pipeline Builder")
    print("─" * 60)

    pipeline = PipelineBuilder.create_standard_pipeline(
        app_name="web-service",
        require_approval=True,
    )

    report = runner.trigger(
        pipeline,
        commit_sha="a1b2c3d4e5f6789012345678",
        branch="main",
        repository="org/web-service",
    )

    print("\n📊 Pipeline Report:")
    print(json.dumps(report, indent=2, default=str))

    # Method 2: From config (pipeline-as-code)
    print("\n" + "─" * 60)
    print("Method 2: Pipeline from Config")
    print("─" * 60)

    pipeline2 = build_pipeline_from_config(PIPELINE_CONFIG)
    report2 = runner.trigger(
        pipeline2,
        commit_sha="ff00ff11223344556677",
        branch="develop",
        repository="org/my-app",
    )
    print(f"\nPipeline status: {report2['status']}")

    # Method 3: Webhook simulation
    print("\n" + "─" * 60)
    print("Method 3: Webhook Trigger")
    print("─" * 60)

    webhook = WebhookHandler(runner)
    payload = {
        "after": "deadbeef12345678",
        "ref": "refs/heads/main",
        "repository": {"full_name": "org/my-app"},
    }
    result = webhook.handle_push_event(payload)
    print(f"\nWebhook result: {result['status']}")


if __name__ == "__main__":
    main()
```

---

<a id="35"></a>
## 35. Container Orchestration System

### Core Concept

A container orchestration system manages the lifecycle, scheduling, networking, and scaling of containers across a cluster of machines. Think Kubernetes or AWS ECS.

```
  ┌─────────────────────────────────────────────────────────────────────┐
  │               CONTAINER ORCHESTRATION SYSTEM                        │
  └─────────────────────────────────────────────────────────────────────┘

   ┌─────────────────────────────────────┐
   │           CONTROL PLANE             │
   │                                     │
   │  ┌───────────┐  ┌───────────────┐  │
   │  │    API     │  │   Scheduler   │  │
   │  │  Server    │  │               │  │
   │  └─────┬─────┘  └───────┬───────┘  │
   │        │                 │          │
   │  ┌─────▼─────────────────▼───────┐  │
   │  │       State Store (etcd)      │  │
   │  │  ┌─────────────────────────┐  │  │
   │  │  │ Desired State           │  │  │
   │  │  │  - Services             │  │  │
   │  │  │  - Deployments          │  │  │
   │  │  │  - Replicas             │  │  │
   │  │  └─────────────────────────┘  │  │
   │  └───────────────────────────────┘  │
   │                                     │
   │  ┌───────────┐  ┌───────────────┐  │
   │  │Controller │  │  Health       │  │
   │  │ Manager   │  │  Monitor      │  │
   │  └───────────┘  └───────────────┘  │
   └─────────┬───────────────────────────┘
             │
    ─────────┼───────────────── Cluster Network ────────────
             │
   ┌─────────▼───────────────────────────────────────────────┐
   │                     WORKER NODES                         │
   │                                                          │
   │  ┌─ Node 1 ──────────┐  ┌─ Node 2 ──────────┐          │
   │  │                    │  │                    │          │
   │  │ ┌─Agent (kubelet)─┐│  │ ┌─Agent (kubelet)─┐│          │
   │  │ └─────────────────┘│  │ └─────────────────┘│          │
   │  │                    │  │                    │          │
   │  │ ┌──Pod──┐ ┌──Pod──┐│  │ ┌──Pod──┐ ┌──Pod──┐│          │
   │  │ │┌────┐ │ │┌────┐ ││  │ │┌────┐ │ │┌────┐ ││          │
   │  │ ││ C1 │ │ ││ C3 │ ││  │ ││ C5 │ │ ││ C7 │ ││          │
   │  │ │└────┘ │ │└────┘ ││  │ │└────┘ │ │└────┘ ││          │
   │  │ │┌────┐ │ │┌────┐ ││  │ │┌────┐ │ │       ││          │
   │  │ ││ C2 │ │ ││ C4 │ ││  │ ││ C6 │ │ │       ││          │
   │  │ │└────┘ │ │└────┘ ││  │ │└────┘ │ │       ││          │
   │  │ └──────┘ └──────┘  │  │ └──────┘ └──────┘  │          │
   │  │                    │  │                    │          │
   │  │ CPU: 4c  Mem: 8GB  │  │ CPU: 8c  Mem: 16GB│          │
   │  │ Used: 2c      4GB  │  │ Used: 3c      8GB │          │
   │  └────────────────────┘  └────────────────────┘          │
   │                                                          │
   │  ┌─ Node 3 ──────────┐                                  │
   │  │ ┌──Pod──┐ ┌──Pod──┐│                                  │
   │  │ │┌────┐ │ │┌────┐ ││                                  │
   │  │ ││ C8 │ │ ││ C9 │ ││                                  │
   │  │ │└────┘ │ │└────┘ ││                                  │
   │  │ └──────┘ └──────┘  │                                  │
   │  │ CPU: 4c  Mem: 8GB  │                                  │
   │  └────────────────────┘                                  │
   └──────────────────────────────────────────────────────────┘

  ┌─────────────────────────────────────────────────────────────────────┐
  │                    SCHEDULING ALGORITHM                             │
  │                                                                     │
  │  1. Filter: Remove nodes that don't meet requirements               │
  │     - Enough CPU/Memory?                                           │
  │     - Correct labels/taints?                                       │
  │     - Not at max pod limit?                                        │
  │                                                                     │
  │  2. Score: Rank remaining nodes                                     │
  │     - Least resource usage (spread load)                           │
  │     - Data locality                                                │
  │     - Anti-affinity (spread replicas across nodes)                 │
  │                                                                     │
  │  3. Bind: Assign pod to highest-scoring node                       │
  └─────────────────────────────────────────────────────────────────────┘
```

### Complete Implementation

```python
"""
Container Orchestration System
==============================
A simplified container orchestrator with scheduling, health monitoring,
service management, and reconciliation loop — inspired by Kubernetes.
"""

import time
import uuid
import json
import threading
import logging
import random
from datetime import datetime, timedelta
from dataclasses import dataclass, field
from enum import Enum
from typing import Dict, List, Optional, Tuple, Set
from collections import defaultdict
from abc import ABC, abstractmethod

logging.basicConfig(level=logging.INFO,
                    format='%(asctime)s [%(levelname)s] %(message)s')
logger = logging.getLogger(__name__)


# ─── Data Models ────────────────────────────────────────────────────

class ContainerState(Enum):
    CREATED = "created"
    RUNNING = "running"
    STOPPED = "stopped"
    FAILED = "failed"
    TERMINATED = "terminated"


class PodPhase(Enum):
    PENDING = "Pending"
    RUNNING = "Running"
    SUCCEEDED = "Succeeded"
    FAILED = "Failed"
    UNKNOWN = "Unknown"


class RestartPolicy(Enum):
    ALWAYS = "Always"
    ON_FAILURE = "OnFailure"
    NEVER = "Never"


@dataclass
class ResourceRequirements:
    cpu_millicores: int = 250       # 250m = 0.25 CPU cores
    memory_mb: int = 256            # 256 MB

    def __repr__(self):
        return f"Resources(cpu={self.cpu_millicores}m, mem={self.memory_mb}MB)"


@dataclass
class Container:
    name: str
    image: str
    command: List[str] = field(default_factory=list)
    env: Dict[str, str] = field(default_factory=dict)
    ports: List[int] = field(default_factory=list)
    resources: ResourceRequirements = field(
        default_factory=ResourceRequirements)
    state: ContainerState = ContainerState.CREATED
    container_id: str = field(
        default_factory=lambda: f"ctr-{uuid.uuid4().hex[:10]}")
    restart_count: int = 0
    started_at: Optional[datetime] = None


@dataclass
class PodSpec:
    """Desired state of a Pod."""
    containers: List[Container]
    restart_policy: RestartPolicy = RestartPolicy.ALWAYS
    labels: Dict[str, str] = field(default_factory=dict)
    node_selector: Dict[str, str] = field(default_factory=dict)


@dataclass
class Pod:
    """A group of co-located containers."""
    pod_id: str
    name: str
    namespace: str
    spec: PodSpec
    phase: PodPhase = PodPhase.PENDING
    node_name: Optional[str] = None
    pod_ip: Optional[str] = None
    created_at: datetime = field(default_factory=datetime.utcnow)
    health_check_failures: int = 0

    @property
    def labels(self) -> Dict[str, str]:
        return self.spec.labels

    @property
    def total_cpu(self) -> int:
        return sum(c.resources.cpu_millicores for c in self.spec.containers)

    @property
    def total_memory(self) -> int:
        return sum(c.resources.memory_mb for c in self.spec.containers)


@dataclass
class Node:
    """A worker machine in the cluster."""
    node_id: str
    name: str
    total_cpu: int = 4000          # 4 CPU cores = 4000 millicores
    total_memory: int = 8192       # 8 GB
    labels: Dict[str, str] = field(default_factory=dict)
    pods: List[str] = field(default_factory=list)  # Pod IDs
    is_ready: bool = True
    last_heartbeat: datetime = field(default_factory=datetime.utcnow)
    max_pods: int = 30

    @property
    def allocated_cpu(self) -> int:
        return getattr(self, '_allocated_cpu', 0)

    @allocated_cpu.setter
    def allocated_cpu(self, val):
        self._allocated_cpu = val

    @property
    def allocated_memory(self) -> int:
        return getattr(self, '_allocated_memory', 0)

    @allocated_memory.setter
    def allocated_memory(self, val):
        self._allocated_memory = val

    @property
    def available_cpu(self) -> int:
        return self.total_cpu - self.allocated_cpu

    @property
    def available_memory(self) -> int:
        return self.total_memory - self.allocated_memory

    @property
    def cpu_utilization_pct(self) -> float:
        return (self.allocated_cpu / self.total_cpu * 100
                if self.total_cpu > 0 else 0)


@dataclass
class ServiceSpec:
    """Defines a service (load-balanced endpoint for pods)."""
    name: str
    namespace: str = "default"
    selector: Dict[str, str] = field(default_factory=dict)
    port: int = 80
    target_port: int = 8080
    service_type: str = "ClusterIP"  # ClusterIP, NodePort, LoadBalancer
    cluster_ip: Optional[str] = None


@dataclass
class DeploymentSpec:
    """Defines a deployment (manages replica sets of pods)."""
    name: str
    namespace: str = "default"
    replicas: int = 3
    template: PodSpec = None
    strategy: str = "RollingUpdate"  # RollingUpdate or Recreate
    max_surge: int = 1
    max_unavailable: int = 0


# ─── State Store ───────────────────────────────────────────────────

class StateStore:
    """
    Centralized state store (like etcd in Kubernetes).
    Stores both desired and actual state.
    """

    def __init__(self):
        self.nodes: Dict[str, Node] = {}
        self.pods: Dict[str, Pod] = {}
        self.services: Dict[str, ServiceSpec] = {}
        self.deployments: Dict[str, DeploymentSpec] = {}
        self._lock = threading.RLock()
        self._watchers: Dict[str, List] = defaultdict(list)

    def add_node(self, node: Node):
        with self._lock:
            self.nodes[node.node_id] = node
            node.allocated_cpu = 0
            node.allocated_memory = 0

    def get_nodes(self) -> List[Node]:
        with self._lock:
            return list(self.nodes.values())

    def add_pod(self, pod: Pod):
        with self._lock:
            self.pods[pod.pod_id] = pod
            self._notify("pod", "ADDED", pod)

    def update_pod(self, pod: Pod):
        with self._lock:
            self.pods[pod.pod_id] = pod
            self._notify("pod", "MODIFIED", pod)

    def delete_pod(self, pod_id: str):
        with self._lock:
            pod = self.pods.pop(pod_id, None)
            if pod:
                self._notify("pod", "DELETED", pod)

    def get_pods_by_selector(self, selector: Dict[str, str],
                             namespace: str = "default") -> List[Pod]:
        with self._lock:
            result = []
            for pod in self.pods.values():
                if pod.namespace != namespace:
                    continue
                if all(pod.labels.get(k) == v
                       for k, v in selector.items()):
                    result.append(pod)
            return result

    def get_pods_on_node(self, node_name: str) -> List[Pod]:
        with self._lock:
            return [p for p in self.pods.values()
                    if p.node_name == node_name]

    def watch(self, resource_type: str, callback):
        self._watchers[resource_type].append(callback)

    def _notify(self, resource_type: str, event_type: str, resource):
        for cb in self._watchers.get(resource_type, []):
            try:
                cb(event_type, resource)
            except Exception as e:
                logger.error(f"Watcher error: {e}")


# ─── Scheduler ─────────────────────────────────────────────────────

class Scheduler:
    """
    Assigns Pods to Nodes using a filter-then-score approach.
    """

    def __init__(self, state: StateStore):
        self.state = state

    def schedule_pod(self, pod: Pod) -> Optional[str]:
        """Find the best node for a pod. Returns node_name or None."""
        nodes = self.state.get_nodes()
        if not nodes:
            logger.warning(f"No nodes available for pod {pod.name}")
            return None

        # Phase 1: Filter — remove nodes that can't run this pod
        feasible = self._filter_nodes(nodes, pod)
        if not feasible:
            logger.warning(f"No feasible nodes for pod {pod.name} "
                           f"(needs {pod.total_cpu}m CPU, "
                           f"{pod.total_memory}MB mem)")
            return None

        # Phase 2: Score — rank feasible nodes
        scored = self._score_nodes(feasible, pod)

        # Pick the best
        best_node = max(scored, key=lambda x: x[1])[0]
        return best_node.name

    def _filter_nodes(self, nodes: List[Node],
                      pod: Pod) -> List[Node]:
        feasible = []
        for node in nodes:
            # Check readiness
            if not node.is_ready:
                continue

            # Check resource capacity
            if node.available_cpu < pod.total_cpu:
                continue
            if node.available_memory < pod.total_memory:
                continue

            # Check pod limit
            if len(node.pods) >= node.max_pods:
                continue

            # Check node selector
            if pod.spec.node_selector:
                if not all(node.labels.get(k) == v
                           for k, v in pod.spec.node_selector.items()):
                    continue

            feasible.append(node)
        return feasible

    def _score_nodes(self, nodes: List[Node],
                     pod: Pod) -> List[Tuple[Node, float]]:
        scored = []
        for node in nodes:
            score = 0.0

            # Score 1: Least resource utilization (spread load)
            cpu_after = ((node.allocated_cpu + pod.total_cpu)
                         / node.total_cpu)
            mem_after = ((node.allocated_memory + pod.total_memory)
                         / node.total_memory)
            score += (1 - cpu_after) * 50    # 0-50 points
            score += (1 - mem_after) * 30    # 0-30 points

            # Score 2: Balance across nodes (fewer pods = higher score)
            score += max(0, 20 - len(node.pods))  # 0-20 points

            scored.append((node, score))

        return scored


# ─── Controller Manager ───────────────────────────────────────────

class DeploymentController:
    """
    Watches deployments and ensures the desired number of
    pod replicas are running. Implements the reconciliation loop.
    """

    def __init__(self, state: StateStore, scheduler: Scheduler):
        self.state = state
        self.scheduler = scheduler
        self._running = False

    def reconcile_deployment(self, deployment: DeploymentSpec):
        """Ensure desired replicas match actual replicas."""
        selector = deployment.template.labels
        current_pods = self.state.get_pods_by_selector(
            selector, deployment.namespace
        )

        # Filter to running/pending pods
        active_pods = [p for p in current_pods
                       if p.phase in (PodPhase.RUNNING, PodPhase.PENDING)]

        current_count = len(active_pods)
        desired_count = deployment.replicas

        if current_count < desired_count:
            # Scale up
            diff = desired_count - current_count
            logger.info(f"Deployment '{deployment.name}': scaling up "
                        f"{current_count} → {desired_count} (+{diff})")
            for _ in range(diff):
                self._create_pod(deployment)

        elif current_count > desired_count:
            # Scale down
            diff = current_count - desired_count
            logger.info(f"Deployment '{deployment.name}': scaling down "
                        f"{current_count} → {desired_count} (-{diff})")
            # Remove newest pods first
            pods_to_remove = sorted(active_pods,
                                    key=lambda p: p.created_at,
                                    reverse=True)[:diff]
            for pod in pods_to_remove:
                self._delete_pod(pod)

    def _create_pod(self, deployment: DeploymentSpec):
        """Create a new pod from deployment template."""
        pod = Pod(
            pod_id=f"pod-{uuid.uuid4().hex[:8]}",
            name=f"{deployment.name}-{uuid.uuid4().hex[:5]}",
            namespace=deployment.namespace,
            spec=PodSpec(
                containers=[
                    Container(
                        name=c.name,
                        image=c.image,
                        ports=c.ports.copy(),
                        resources=ResourceRequirements(
                            cpu_millicores=c.resources.cpu_millicores,
                            memory_mb=c.resources.memory_mb,
                        ),
                        env=c.env.copy(),
                    )
                    for c in deployment.template.containers
                ],
                restart_policy=deployment.template.restart_policy,
                labels=deployment.template.labels.copy(),
                node_selector=deployment.template.node_selector.copy(),
            ),
        )

        self.state.add_pod(pod)

        # Schedule the pod
        node_name = self.scheduler.schedule_pod(pod)
        if node_name:
            self._bind_pod(pod, node_name)
        else:
            logger.warning(f"Pod {pod.name} is unschedulable")

    def _bind_pod(self, pod: Pod, node_name: str):
        """Assign a pod to a node."""
        pod.node_name = node_name
        pod.phase = PodPhase.RUNNING
        pod.pod_ip = f"10.244.{random.randint(0,255)}.{random.randint(1,254)}"

        # Update node resource accounting
        for node in self.state.get_nodes():
            if node.name == node_name:
                node.allocated_cpu += pod.total_cpu
                node.allocated_memory += pod.total_memory
                node.pods.append(pod.pod_id)
                break

        # Start containers
        for container in pod.spec.containers:
            container.state = ContainerState.RUNNING
            container.started_at = datetime.utcnow()

        self.state.update_pod(pod)
        logger.info(f"  Pod {pod.name} bound to node {node_name} "
                    f"(IP: {pod.pod_ip})")

    def _delete_pod(self, pod: Pod):
        """Remove a pod and free resources."""
        # Free resources on node
        for node in self.state.get_nodes():
            if node.name == pod.node_name:
                node.allocated_cpu -= pod.total_cpu
                node.allocated_memory -= pod.total_memory
                if pod.pod_id in node.pods:
                    node.pods.remove(pod.pod_id)
                break

        pod.phase = PodPhase.SUCCEEDED
        for c in pod.spec.containers:
            c.state = ContainerState.TERMINATED

        self.state.delete_pod(pod.pod_id)
        logger.info(f"  Pod {pod.name} deleted")

    def reconcile_all(self):
        """Reconcile all deployments."""
        for dep in self.state.deployments.values():
            self.reconcile_deployment(dep)

    def start_reconcile_loop(self, interval: float = 5.0):
        self._running = True

        def loop():
            while self._running:
                try:
                    self.reconcile_all()
                except Exception as e:
                    logger.error(f"Reconciliation error: {e}")
                time.sleep(interval)

        threading.Thread(target=loop, daemon=True).start()

    def stop(self):
        self._running = False


# ─── Health Monitor ────────────────────────────────────────────────

class HealthMonitor:
    """Monitors node and pod health, replaces failed pods."""

    def __init__(self, state: StateStore,
                 deployment_controller: DeploymentController):
        self.state = state
        self.controller = deployment_controller
        self._running = False

    def check_nodes(self):
        now = datetime.utcnow()
        for node in self.state.get_nodes():
            age = (now - node.last_heartbeat).total_seconds()
            if age > 60:  # No heartbeat for 60s
                if node.is_ready:
                    logger.warning(f"Node {node.name} is NOT READY "
                                   f"(last heartbeat {age:.0f}s ago)")
                    node.is_ready = False
                    # Reschedule pods from failed node
                    self._handle_node_failure(node)

    def check_pods(self):
        for pod in list(self.state.pods.values()):
            if pod.phase != PodPhase.RUNNING:
                continue

            # Simulate random health check failure
            if random.random() < 0.02:  # 2% chance
                pod.health_check_failures += 1
                if pod.health_check_failures >= 3:
                    logger.warning(f"Pod {pod.name} failed health check "
                                   f"({pod.health_check_failures}x)")
                    pod.phase = PodPhase.FAILED
                    self.state.update_pod(pod)
                    # Controller will reconcile and create replacement

    def _handle_node_failure(self, node: Node):
        pods = self.state.get_pods_on_node(node.name)
        for pod in pods:
            pod.phase = PodPhase.FAILED
            self.state.update_pod(pod)
            logger.info(f"  Marked pod {pod.name} as Failed "
                        f"(node {node.name} down)")

    def start(self, interval: float = 10.0):
        self._running = True

        def loop():
            while self._running:
                self.check_nodes()
                self.check_pods()
                time.sleep(interval)

        threading.Thread(target=loop, daemon=True).start()

    def stop(self):
        self._running = False


# ─── Service (Load Balancing) ──────────────────────────────────────

class ServiceProxy:
    """
    Simple service proxy that load-balances requests to pods
    matching a service's selector.
    """

    def __init__(self, state: StateStore):
        self.state = state

    def resolve_service(self, service_name: str,
                        namespace: str = "default") -> List[str]:
        """Get list of pod IPs that back a service."""
        key = f"{namespace}/{service_name}"
        service = self.state.services.get(key)
        if not service:
            return []

        pods = self.state.get_pods_by_selector(
            service.selector, namespace
        )
        return [
            f"{p.pod_ip}:{service.target_port}"
            for p in pods
            if p.phase == PodPhase.RUNNING and p.pod_ip
        ]

    def route_request(self, service_name: str,
                      namespace: str = "default") -> Optional[str]:
        """Round-robin load balance to a pod endpoint."""
        endpoints = self.resolve_service(service_name, namespace)
        if not endpoints:
            return None
        return random.choice(endpoints)  # Simplified round-robin


# ─── Orchestrator API ──────────────────────────────────────────────

class Orchestrator:
    """
    Main API interface for the container orchestration system.
    Analogous to kubectl / Kubernetes API server.
    """

    def __init__(self):
        self.state = StateStore()
        self.scheduler = Scheduler(self.state)
        self.controller = DeploymentController(
            self.state, self.scheduler)
        self.health_monitor = HealthMonitor(
            self.state, self.controller)
        self.service_proxy = ServiceProxy(self.state)

    def register_node(self, name: str, cpu: int = 4000,
                      memory: int = 8192,
                      labels: Dict[str, str] = None) -> Node:
        node = Node(
            node_id=f"node-{uuid.uuid4().hex[:6]}",
            name=name,
            total_cpu=cpu,
            total_memory=memory,
            labels=labels or {},
        )
        self.state.add_node(node)
        logger.info(f"Node registered: {name} "
                    f"(CPU: {cpu}m, Mem: {memory}MB)")
        return node

    def create_deployment(self, name: str, image: str,
                          replicas: int = 3,
                          cpu: int = 250, memory: int = 256,
                          port: int = 8080,
                          labels: Dict[str, str] = None,
                          env: Dict[str, str] = None,
                          namespace: str = "default") -> DeploymentSpec:
        """Create a deployment (desired state)."""
        if labels is None:
            labels = {"app": name}

        deployment = DeploymentSpec(
            name=name,
            namespace=namespace,
            replicas=replicas,
            template=PodSpec(
                containers=[
                    Container(
                        name=name,
                        image=image,
                        ports=[port],
                        resources=ResourceRequirements(cpu, memory),
                        env=env or {},
                    ),
                ],
                labels=labels,
            ),
        )

        self.state.deployments[name] = deployment
        logger.info(f"Deployment created: {name} "
                    f"(replicas={replicas}, image={image})")

        # Trigger immediate reconciliation
        self.controller.reconcile_deployment(deployment)
        return deployment

    def scale_deployment(self, name: str, replicas: int):
        """Change the desired replica count."""
        if name not in self.state.deployments:
            logger.error(f"Deployment '{name}' not found")
            return

        dep = self.state.deployments[name]
        old = dep.replicas
        dep.replicas = replicas
        logger.info(f"Scaled deployment '{name}': {old} → {replicas}")
        self.controller.reconcile_deployment(dep)

    def create_service(self, name: str, selector: Dict[str, str],
                       port: int = 80, target_port: int = 8080,
                       namespace: str = "default") -> ServiceSpec:
        """Create a service (load-balanced endpoint)."""
        service = ServiceSpec(
            name=name,
            namespace=namespace,
            selector=selector,
            port=port,
            target_port=target_port,
            cluster_ip=f"10.96.{random.randint(0,255)}."
                       f"{random.randint(1,254)}",
        )
        self.state.services[f"{namespace}/{name}"] = service
        logger.info(f"Service created: {name} → selector={selector} "
                    f"(ClusterIP: {service.cluster_ip})")
        return service

    def get_cluster_status(self) -> Dict:
        """Get comprehensive cluster status."""
        nodes = self.state.get_nodes()
        pods = list(self.state.pods.values())

        return {
            "nodes": [
                {
                    "name": n.name,
                    "ready": n.is_ready,
                    "cpu": f"{n.allocated_cpu}/{n.total_cpu}m "
                           f"({n.cpu_utilization_pct:.0f}%)",
                    "memory": f"{n.allocated_memory}/{n.total_memory}MB",
                    "pods": len(n.pods),
                }
                for n in nodes
            ],
            "pods": [
                {
                    "name": p.name,
                    "phase": p.phase.value,
                    "node": p.node_name,
                    "ip": p.pod_ip,
                    "containers": [
                        {"name": c.name, "image": c.image,
                         "state": c.state.value}
                        for c in p.spec.containers
                    ],
                }
                for p in pods
            ],
            "deployments": {
                name: {
                    "desired": d.replicas,
                    "current": len([
                        p for p in pods
                        if all(p.labels.get(k) == v
                               for k, v in d.template.labels.items())
                        and p.phase == PodPhase.RUNNING
                    ]),
                }
                for name, d in self.state.deployments.items()
            },
            "services": {
                name: {
                    "cluster_ip": s.cluster_ip,
                    "port": s.port,
                    "endpoints": self.service_proxy.resolve_service(
                        s.name, s.namespace),
                }
                for name, s in self.state.services.items()
            },
        }

    def start(self):
        self.controller.start_reconcile_loop(interval=5)
        self.health_monitor.start(interval=10)
        logger.info("Orchestrator started")

    def stop(self):
        self.controller.stop()
        self.health_monitor.stop()


# ─── Demo ───────────────────────────────────────────────────────────

def main():
    print("=" * 70)
    print("       CONTAINER ORCHESTRATION SYSTEM DEMO")
    print("=" * 70)

    orch = Orchestrator()

    # Register worker nodes
    orch.register_node("node-1", cpu=4000, memory=8192,
                       labels={"zone": "us-east-1a", "type": "general"})
    orch.register_node("node-2", cpu=8000, memory=16384,
                       labels={"zone": "us-east-1b", "type": "general"})
    orch.register_node("node-3", cpu=4000, memory=8192,
                       labels={"zone": "us-east-1a", "type": "gpu"})

    # Create a deployment (like `kubectl apply`)
    print("\n--- Creating web-app deployment (3 replicas) ---")
    orch.create_deployment(
        name="web-app",
        image="nginx:1.21",
        replicas=3,
        cpu=500,
        memory=512,
        port=8080,
        labels={"app": "web-app", "tier": "frontend"},
    )

    # Create API deployment
    print("\n--- Creating api-server deployment (2 replicas) ---")
    orch.create_deployment(
        name="api-server",
        image="myapp/api:v2.1",
        replicas=2,
        cpu=1000,
        memory=1024,
        port=3000,
        labels={"app": "api-server", "tier": "backend"},
    )

    # Create services
    print("\n--- Creating services ---")
    orch.create_service("web-svc", {"app": "web-app"}, port=80,
                        target_port=8080)
    orch.create_service("api-svc", {"app": "api-server"}, port=80,
                        target_port=3000)

    time.sleep(1)

    # Show cluster status
    print("\n--- Cluster Status ---")
    status = orch.get_cluster_status()
    print(json.dumps(status, indent=2))

    # Scale up
    print("\n--- Scaling web-app to 5 replicas ---")
    orch.scale_deployment("web-app", 5)
    time.sleep(0.5)

    # Service discovery
    print("\n--- Service Discovery ---")
    for svc in ["web-svc", "api-svc"]:
        endpoints = orch.service_proxy.resolve_service(svc)
        print(f"  {svc} endpoints: {endpoints}")
        target = orch.service_proxy.route_request(svc)
        print(f"  {svc} routed to: {target}")

    # Final status
    print("\n--- Final Cluster Status ---")
    status = orch.get_cluster_status()
    print(json.dumps(status, indent=2))


if __name__ == "__main__":
    main()
```

---

<a id="36"></a>
## 36. Service Discovery

### Core Concept

Service discovery allows services in a distributed system to find and communicate with each other without hardcoded addresses. Services **register** themselves and **discover** others dynamically.

```
  ┌─────────────────────────────────────────────────────────────────────┐
  │                    SERVICE DISCOVERY                                 │
  └─────────────────────────────────────────────────────────────────────┘

  ┌─ Client-Side Discovery ────────────────────────────────────────────┐
  │                                                                     │
  │  ┌──────────┐      ┌──────────────────┐      ┌──────────────┐     │
  │  │  Client   │─────▶│  Service Registry │      │   Service    │     │
  │  │ (caller)  │  1.  │                  │      │  Instance A  │     │
  │  │           │query │  ┌────────────┐  │  2.  ├──────────────┤     │
  │  │           │◀─────│  │ user-svc:  │  │─────▶│  Instance B  │     │
  │  │           │  3.  │  │ [A, B, C]  │  │call  ├──────────────┤     │
  │  │           │──────│  │            │  │      │  Instance C  │     │
  │  │           │direct│  └────────────┘  │      └──────────────┘     │
  │  └──────────┘      └──────────────────┘                            │
  │                                                                     │
  │  Client picks instance & calls directly (e.g., Netflix Eureka)     │
  └─────────────────────────────────────────────────────────────────────┘

  ┌─ Server-Side Discovery ────────────────────────────────────────────┐
  │                                                                     │
  │  ┌──────────┐      ┌──────────────┐      ┌──────────────┐         │
  │  │  Client   │─────▶│ Load Balancer │─────▶│  Service     │         │
  │  │ (caller)  │      │  / Router     │      │  Instance A  │         │
  │  └──────────┘      │              │      ├──────────────┤         │
  │                     │      ▲       │      │  Instance B  │         │
  │                     └──────┼───────┘      └──────────────┘         │
  │                            │                                        │
  │                     ┌──────┴──────────┐                            │
  │                     │ Service Registry │                            │
  │                     └─────────────────┘                            │
  │                                                                     │
  │  Load balancer handles discovery (e.g., AWS ALB, Kubernetes)       │
  └─────────────────────────────────────────────────────────────────────┘

  ┌─ DNS-Based Discovery ─────────────────────────────────────────────┐
  │                                                                     │
  │  ┌──────────┐  DNS query      ┌──────────────┐                    │
  │  │  Client   │────────────────▶│  DNS Server   │                    │
  │  │           │  "user-svc"     │              │                    │
  │  │           │◀────────────────│  A: 10.0.1.5 │                    │
  │  │           │  IP response    │  A: 10.0.1.6 │                    │
  │  └──────────┘                  │  SRV records  │                    │
  │                                └──────┬───────┘                    │
  │                                       │                             │
  │                                ┌──────▼──────────┐                 │
  │                                │ Service Registry │                 │
  │                                └─────────────────┘                 │
  │                                                                     │
  │  DNS resolves service names to IPs (e.g., Consul DNS, Route 53)    │
  └─────────────────────────────────────────────────────────────────────┘

  ┌─ Registration Flow ───────────────────────────────────────────────┐
  │                                                                     │
  │  Service starts ──▶ Register(name, host, port, health_url)         │
  │                            │                                        │
  │                            ▼                                        │
  │                     ┌──────────────┐                               │
  │                     │   Registry    │                               │
  │                     │              │                               │
  │                     │  Heartbeat ◀─┤── TTL-based expiry            │
  │                     │  every 10s   │                               │
  │                     │              │                               │
  │                     │  Health ─────┤── Active health checks         │
  │                     │  Check       │                               │
  │                     └──────────────┘                               │
  │                                                                     │
  │  If no heartbeat for 30s → mark unhealthy → remove after 90s      │
  └─────────────────────────────────────────────────────────────────────┘
```

### Complete Implementation

```python
"""
Service Discovery System
=========================
A complete service registry with registration, health checks,
DNS resolution, load balancing, and client library.
"""

import time
import uuid
import json
import socket
import hashlib
import threading
import logging
import random
from datetime import datetime, timedelta
from dataclasses import dataclass, field
from enum import Enum
from typing import Dict, List, Optional, Tuple, Set
from collections import defaultdict
from http.server import HTTPServer, BaseHTTPRequestHandler
from abc import ABC, abstractmethod
import struct

logging.basicConfig(level=logging.INFO,
                    format='%(asctime)s [%(levelname)s] %(message)s')
logger = logging.getLogger(__name__)


# ─── Data Models ────────────────────────────────────────────────────

class HealthStatus(Enum):
    HEALTHY = "healthy"
    UNHEALTHY = "unhealthy"
    UNKNOWN = "unknown"
    DRAINING = "draining"   # Accepting no new connections


class LoadBalanceStrategy(Enum):
    ROUND_ROBIN = "round_robin"
    RANDOM = "random"
    LEAST_CONNECTIONS = "least_connections"
    WEIGHTED = "weighted"
    CONSISTENT_HASH = "consistent_hash"


@dataclass
class ServiceInstance:
    """A single instance of a service."""
    instance_id: str
    service_name: str
    host: str
    port: int
    health_check_url: str = ""
    metadata: Dict[str, str] = field(default_factory=dict)
    tags: Set[str] = field(default_factory=set)
    weight: int = 100                # For weighted load balancing
    health_status: HealthStatus = HealthStatus.UNKNOWN
    registered_at: datetime = field(default_factory=datetime.utcnow)
    last_heartbeat: datetime = field(default_factory=datetime.utcnow)
    health_check_failures: int = 0
    active_connections: int = 0
    version: str = "1.0.0"
    zone: str = "us-east-1a"

    @property
    def address(self) -> str:
        return f"{self.host}:{self.port}"

    @property
    def is_healthy(self) -> bool:
        return self.health_status == HealthStatus.HEALTHY

    def to_dict(self) -> Dict:
        return {
            "instance_id": self.instance_id,
            "service_name": self.service_name,
            "host": self.host,
            "port": self.port,
            "address": self.address,
            "health_status": self.health_status.value,
            "metadata": self.metadata,
            "tags": list(self.tags),
            "weight": self.weight,
            "version": self.version,
            "zone": self.zone,
            "last_heartbeat": self.last_heartbeat.isoformat(),
        }


@dataclass
class ServiceDefinition:
    """Metadata about a service type."""
    name: str
    instances: Dict[str, ServiceInstance] = field(default_factory=dict)
    ttl_seconds: int = 30             # Heartbeat TTL
    deregister_after: int = 90        # Auto-remove after N seconds
    health_check_interval: int = 10   # Seconds between health checks

    @property
    def healthy_instances(self) -> List[ServiceInstance]:
        return [i for i in self.instances.values()
                if i.is_healthy]

    @property
    def all_instances(self) -> List[ServiceInstance]:
        return list(self.instances.values())


# ─── Health Checker ────────────────────────────────────────────────

class HealthChecker:
    """
    Actively checks the health of registered service instances.
    Supports HTTP, TCP, and TTL-based checks.
    """

    def __init__(self):
        self._running = False

    def check_http(self, instance: ServiceInstance) -> bool:
        """HTTP health check (simulated)."""
        try:
            # In production: requests.get(instance.health_check_url, timeout=5)
            # Simulate: 95% chance of healthy
            return random.random() < 0.95
        except Exception:
            return False

    def check_tcp(self, host: str, port: int, timeout: float = 5) -> bool:
        """TCP connect check."""
        try:
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.settimeout(timeout)
            result = sock.connect_ex((host, port))
            sock.close()
            return result == 0
        except Exception:
            return False

    def check_ttl(self, instance: ServiceInstance,
                  ttl_seconds: int) -> bool:
        """TTL-based: instance must send heartbeats within TTL."""
        elapsed = (datetime.utcnow() - instance.last_heartbeat).total_seconds()
        return elapsed < ttl_seconds


# ─── Service Registry ─────────────────────────────────────────────

class ServiceRegistry:
    """
    Central registry that stores all service instances.
    Supports registration, deregistration, health monitoring,
    and discovery queries.
    """

    def __init__(self):
        self._services: Dict[str, ServiceDefinition] = {}
        self._lock = threading.RLock()
        self._health_checker = HealthChecker()
        self._watchers: Dict[str, List] = defaultdict(list)
        self._running = False

    # ── Registration ─────────────────────────────────────────────

    def register(self, service_name: str, host: str, port: int,
                 health_check_url: str = "",
                 metadata: Dict[str, str] = None,
                 tags: Set[str] = None,
                 version: str = "1.0.0",
                 zone: str = "us-east-1a",
                 weight: int = 100) -> ServiceInstance:
        """Register a service instance."""
        instance = ServiceInstance(
            instance_id=f"{service_name}-{uuid.uuid4().hex[:8]}",
            service_name=service_name,
            host=host,
            port=port,
            health_check_url=health_check_url or f"http://{host}:{port}/health",
            metadata=metadata or {},
            tags=tags or set(),
            version=version,
            zone=zone,
            weight=weight,
            health_status=HealthStatus.HEALTHY,
        )

        with self._lock:
            if service_name not in self._services:
                self._services[service_name] = ServiceDefinition(
                    name=service_name)
            self._services[service_name].instances[
                instance.instance_id] = instance

        self._notify_watchers(service_name, "REGISTER", instance)
        logger.info(f"Registered: {service_name} at {instance.address} "
                    f"(id={instance.instance_id})")
        return instance

    def deregister(self, instance_id: str):
        """Remove a service instance."""
        with self._lock:
            for svc in self._services.values():
                if instance_id in svc.instances:
                    instance = svc.instances.pop(instance_id)
                    self._notify_watchers(
                        svc.name, "DEREGISTER", instance)
                    logger.info(f"Deregistered: {instance.service_name} "
                                f"at {instance.address}")
                    return True
        return False

    def heartbeat(self, instance_id: str) -> bool:
        """Process a heartbeat from a service instance."""
        with self._lock:
            for svc in self._services.values():
                if instance_id in svc.instances:
                    svc.instances[instance_id].last_heartbeat = \
                        datetime.utcnow()
                    svc.instances[instance_id].health_status = \
                        HealthStatus.HEALTHY
                    svc.instances[instance_id].health_check_failures = 0
                    return True
        return False

    # ── Discovery ────────────────────────────────────────────────

    def discover(self, service_name: str,
                 healthy_only: bool = True,
                 tags: Set[str] = None,
                 version: str = None,
                 zone: str = None) -> List[ServiceInstance]:
        """Find instances of a service with optional filters."""
        with self._lock:
            svc = self._services.get(service_name)
            if not svc:
                return []

            instances = svc.all_instances

        # Apply filters
        if healthy_only:
            instances = [i for i in instances if i.is_healthy]
        if tags:
            instances = [i for i in instances
                         if tags.issubset(i.tags)]
        if version:
            instances = [i for i in instances
                         if i.version == version]
        if zone:
            instances = [i for i in instances if i.zone == zone]

        return instances

    def get_all_services(self) -> Dict[str, int]:
        """List all registered services with instance counts."""
        with self._lock:
            return {
                name: len(svc.healthy_instances)
                for name, svc in self._services.items()
            }

    # ── Health Monitoring ────────────────────────────────────────

    def _run_health_checks(self):
        """Check health of all instances and evict stale ones."""
        now = datetime.utcnow()
        to_remove = []

        with self._lock:
            for svc in self._services.values():
                for inst_id, inst in list(svc.instances.items()):
                    # TTL check
                    elapsed = (now - inst.last_heartbeat).total_seconds()

                    if elapsed > svc.deregister_after:
                        to_remove.append(inst_id)
                        logger.warning(
                            f"Auto-deregistering {inst.service_name} "
                            f"at {inst.address} (no heartbeat for "
                            f"{elapsed:.0f}s)")
                        continue

                    if elapsed > svc.ttl_seconds:
                        inst.health_check_failures += 1
                        if inst.health_check_failures >= 3:
                            inst.health_status = HealthStatus.UNHEALTHY
                            self._notify_watchers(
                                svc.name, "UNHEALTHY", inst)
                    else:
                        # Active health check (HTTP)
                        healthy = self._health_checker.check_http(inst)
                        if healthy:
                            if inst.health_status != HealthStatus.HEALTHY:
                                inst.health_status = HealthStatus.HEALTHY
                                self._notify_watchers(
                                    svc.name, "HEALTHY", inst)
                            inst.health_check_failures = 0
                        else:
                            inst.health_check_failures += 1
                            if inst.health_check_failures >= 3:
                                inst.health_status = HealthStatus.UNHEALTHY

        for inst_id in to_remove:
            self.deregister(inst_id)

    def start_health_checks(self, interval: float = 10.0):
        self._running = True

        def loop():
            while self._running:
                self._run_health_checks()
                time.sleep(interval)

        threading.Thread(target=loop, daemon=True).start()
        logger.info("Health check loop started")

    def stop(self):
        self._running = False

    # ── Watching ─────────────────────────────────────────────────

    def watch(self, service_name: str, callback):
        """Watch for changes to a service."""
        self._watchers[service_name].append(callback)

    def _notify_watchers(self, service_name: str, event: str,
                         instance: ServiceInstance):
        for cb in self._watchers.get(service_name, []):
            try:
                cb(event, instance)
            except Exception as e:
                logger.error(f"Watcher error: {e}")


# ─── Load Balancers ───────────────────────────────────────────────

class LoadBalancer(ABC):
    @abstractmethod
    def select(self, instances: List[ServiceInstance],
               key: str = None) -> Optional[ServiceInstance]:
        pass


class RoundRobinBalancer(LoadBalancer):
    def __init__(self):
        self._counters: Dict[str, int] = defaultdict(int)

    def select(self, instances: List[ServiceInstance],
               key: str = None) -> Optional[ServiceInstance]:
        if not instances:
            return None
        svc = instances[0].service_name
        idx = self._counters[svc] % len(instances)
        self._counters[svc] += 1
        return instances[idx]


class WeightedBalancer(LoadBalancer):
    def select(self, instances: List[ServiceInstance],
               key: str = None) -> Optional[ServiceInstance]:
        if not instances:
            return None
        weights = [i.weight for i in instances]
        return random.choices(instances, weights=weights, k=1)[0]


class LeastConnectionsBalancer(LoadBalancer):
    def select(self, instances: List[ServiceInstance],
               key: str = None) -> Optional[ServiceInstance]:
        if not instances:
            return None
        return min(instances, key=lambda i: i.active_connections)


class ConsistentHashBalancer(LoadBalancer):
    """
    Consistent hashing — same key always goes to the same instance
    (unless the ring changes). Used for caching, sticky sessions.
    """

    def __init__(self, virtual_nodes: int = 150):
        self.virtual_nodes = virtual_nodes

    def select(self, instances: List[ServiceInstance],
               key: str = None) -> Optional[ServiceInstance]:
        if not instances:
            return None
        if key is None:
            key = str(random.random())

        # Build hash ring
        ring = []
        for inst in instances:
            for i in range(self.virtual_nodes):
                h = self._hash(f"{inst.instance_id}:{i}")
                ring.append((h, inst))
        ring.sort(key=lambda x: x[0])

        # Find the instance for this key
        key_hash = self._hash(key)
        for h, inst in ring:
            if h >= key_hash:
                return inst
        return ring[0][1]  # Wrap around

    @staticmethod
    def _hash(key: str) -> int:
        return int(hashlib.md5(key.encode()).hexdigest(), 16)


# ─── Service Discovery Client ─────────────────────────────────────

class DiscoveryClient:
    """
    Client library that applications use to register themselves
    and discover other services.
    """

    def __init__(self, registry: ServiceRegistry,
                 lb_strategy: LoadBalanceStrategy = LoadBalanceStrategy.ROUND_ROBIN):
        self.registry = registry
        self._instances: Dict[str, ServiceInstance] = {}  # My registrations
        self._cache: Dict[str, Tuple[List[ServiceInstance], datetime]] = {}
        self._cache_ttl = timedelta(seconds=10)
        self._heartbeat_running = False

        # Select load balancer
        balancers = {
            LoadBalanceStrategy.ROUND_ROBIN: RoundRobinBalancer(),
            LoadBalanceStrategy.RANDOM: LoadBalancer,
            LoadBalanceStrategy.LEAST_CONNECTIONS: LeastConnectionsBalancer(),
            LoadBalanceStrategy.WEIGHTED: WeightedBalancer(),
            LoadBalanceStrategy.CONSISTENT_HASH: ConsistentHashBalancer(),
        }
        self._lb = balancers.get(lb_strategy, RoundRobinBalancer())

    def register(self, service_name: str, host: str, port: int,
                 **kwargs) -> ServiceInstance:
        """Register this service instance."""
        instance = self.registry.register(
            service_name, host, port, **kwargs)
        self._instances[instance.instance_id] = instance
        self._start_heartbeat()
        return instance

    def deregister_all(self):
        """Deregister all instances owned by this client."""
        for inst_id in list(self._instances.keys()):
            self.registry.deregister(inst_id)
        self._instances.clear()
        self._heartbeat_running = False

    def resolve(self, service_name: str,
                **filters) -> Optional[ServiceInstance]:
        """Find one healthy instance of a service (load-balanced)."""
        instances = self._get_instances(service_name, **filters)
        return self._lb.select(instances,
                               key=filters.get("hash_key"))

    def resolve_all(self, service_name: str,
                    **filters) -> List[ServiceInstance]:
        """Get all healthy instances of a service."""
        return self._get_instances(service_name, **filters)

    def _get_instances(self, service_name: str,
                       **filters) -> List[ServiceInstance]:
        # Check cache
        if service_name in self._cache:
            cached, cache_time = self._cache[service_name]
            if datetime.utcnow() - cache_time < self._cache_ttl:
                return cached

        # Fetch from registry
        instances = self.registry.discover(
            service_name,
            healthy_only=filters.get("healthy_only", True),
            tags=filters.get("tags"),
            version=filters.get("version"),
            zone=filters.get("zone"),
        )

        # Update cache
        self._cache[service_name] = (instances, datetime.utcnow())
        return instances

    def _start_heartbeat(self):
        if self._heartbeat_running:
            return
        self._heartbeat_running = True

        def heartbeat_loop():
            while self._heartbeat_running and self._instances:
                for inst_id in list(self._instances.keys()):
                    self.registry.heartbeat(inst_id)
                time.sleep(10)

        threading.Thread(target=heartbeat_loop, daemon=True).start()


# ─── DNS-Based Discovery ──────────────────────────────────────────

class ServiceDNS:
    """
    DNS interface for service discovery.
    Resolves service-name.service.local → list of IPs
    """

    def __init__(self, registry: ServiceRegistry):
        self.registry = registry

    def resolve_a(self, query: str) -> List[str]:
        """Resolve A records (hostname → IPs)."""
        # query format: "service-name.service.local"
        parts = query.split(".")
        if len(parts) >= 2 and parts[1] == "service":
            service_name = parts[0]
            instances = self.registry.discover(service_name)
            return [inst.host for inst in instances]
        return []

    def resolve_srv(self, query: str) -> List[Dict]:
        """Resolve SRV records (hostname → host:port with priority)."""
        parts = query.split(".")
        if len(parts) >= 2 and parts[1] == "service":
            service_name = parts[0]
            instances = self.registry.discover(service_name)
            return [
                {
                    "target": inst.host,
                    "port": inst.port,
                    "priority": 10,
                    "weight": inst.weight,
                }
                for inst in instances
            ]
        return []


# ─── API Server (simplified HTTP) ─────────────────────────────────

class RegistryAPIHandler(BaseHTTPRequestHandler):
    """HTTP API for the service registry."""
    registry: ServiceRegistry = None

    def do_GET(self):
        if self.path == "/services":
            data = self.registry.get_all_services()
            self._respond(200, data)
        elif self.path.startswith("/services/"):
            service_name = self.path.split("/")[2]
            instances = self.registry.discover(service_name)
            self._respond(200, [i.to_dict() for i in instances])
        elif self.path == "/health":
            self._respond(200, {"status": "healthy"})
        else:
            self._respond(404, {"error": "not found"})

    def _respond(self, status: int, data):
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        self.wfile.write(json.dumps(data).encode())

    def log_message(self, format, *args):
        pass  # Suppress request logs


# ─── Demo ───────────────────────────────────────────────────────────

def main():
    print("=" * 70)
    print("        SERVICE DISCOVERY SYSTEM DEMO")
    print("=" * 70)

    # Create registry
    registry = ServiceRegistry()
    registry.start_health_checks(interval=5)

    # Create DNS resolver
    dns = ServiceDNS(registry)

    # ─── Simulate microservices registering ─────────────────────

    print("\n--- Service Registration ---")

    # User Service (3 instances)
    user_instances = []
    for i in range(3):
        inst = registry.register(
            "user-service",
            host=f"10.0.1.{10+i}",
            port=8080,
            version="2.1.0",
            zone=f"us-east-1{'a' if i % 2 == 0 else 'b'}",
            tags={"grpc", "v2"},
            metadata={"team": "platform"},
        )
        user_instances.append(inst)

    # Order Service (2 instances)
    for i in range(2):
        registry.register(
            "order-service",
            host=f"10.0.2.{10+i}",
            port=3000,
            version="1.5.0",
            tags={"rest", "v1"},
        )

    # Payment Service (2 instances)
    for i in range(2):
        registry.register(
            "payment-service",
            host=f"10.0.3.{10+i}",
            port=443,
            version="3.0.0",
            tags={"grpc", "pci"},
            weight=100 if i == 0 else 50,  # Primary gets more traffic
        )

    # ─── Service Discovery ──────────────────────────────────────

    print("\n--- Service Discovery ---")
    all_services = registry.get_all_services()
    print(f"Registered services: {json.dumps(all_services, indent=2)}")

    # Client-side discovery
    print("\n--- Client-Side Discovery ---")
    client = DiscoveryClient(
        registry,
        lb_strategy=LoadBalanceStrategy.ROUND_ROBIN
    )

    # Resolve user-service multiple times (round-robin)
    for i in range(5):
        instance = client.resolve("user-service")
        if instance:
            print(f"  Request {i+1} → {instance.address} "
                  f"(zone={instance.zone})")

    # Filter by version
    print("\n--- Filtered Discovery ---")
    v2_instances = client.resolve_all(
        "user-service", version="2.1.0", tags={"grpc"}
    )
    print(f"  user-service v2.1.0 (grpc): "
          f"{[i.address for i in v2_instances]}")

    # ─── DNS Resolution ─────────────────────────────────────────

    print("\n--- DNS Resolution ---")
    a_records = dns.resolve_a("user-service.service.local")
    print(f"  A records for user-service: {a_records}")

    srv_records = dns.resolve_srv("payment-service.service.local")
    print(f"  SRV records for payment-service:")
    for r in srv_records:
        print(f"    {r['target']}:{r['port']} (weight={r['weight']})")

    # ─── Consistent Hashing ────────────────────────────────────

    print("\n--- Consistent Hash Load Balancing ---")
    hash_client = DiscoveryClient(
        registry,
        lb_strategy=LoadBalanceStrategy.CONSISTENT_HASH
    )

    # Same user always goes to same instance
    for user_id in ["user-123", "user-456", "user-123", "user-789",
                     "user-123"]:
        instance = hash_client.resolve("user-service",
                                       hash_key=user_id)
        if instance:
            print(f"  {user_id} → {instance.address}")

    # ─── Watch for changes ──────────────────────────────────────

    print("\n--- Watching for changes ---")
    changes = []
    registry.watch("user-service",
                   lambda event, inst: changes.append(
                       f"{event}: {inst.address}"))

    # Deregister one instance
    registry.deregister(user_instances[0].instance_id)
    print(f"  Changes observed: {changes}")

    # ─── Health Status ──────────────────────────────────────────

    print("\n--- Health Status ---")
    for svc_name in ["user-service", "order-service", "payment-service"]:
        instances = registry.discover(svc_name, healthy_only=False)
        for inst in instances:
            print(f"  {svc_name} @ {inst.address} → "
                  f"{inst.health_status.value}")

    registry.stop()


if __name__ == "__main__":
    main()
```

---

<a id="37"></a>
## 37. Blue-Green Deployment System

### Core Concept

Blue-green deployment maintains **two identical production environments**. At any time, only one (say "blue") serves live traffic. New code is deployed to the other ("green"), tested, then traffic is switched instantly. If issues arise, switch back.

```
  ┌─────────────────────────────────────────────────────────────────────┐
  │                  BLUE-GREEN DEPLOYMENT                              │
  └─────────────────────────────────────────────────────────────────────┘

  ┌─ Phase 1: Blue is LIVE ──────────────────────────────────────────┐
  │                                                                    │
  │  Users ──▶ Load Balancer ──▶ ┌─ BLUE (v1.0) ─── LIVE ──┐        │
  │                100%          │  ┌────┐ ┌────┐ ┌────┐    │        │
  │                              │  │ I1 │ │ I2 │ │ I3 │    │        │
  │                              │  └────┘ └────┘ └────┘    │        │
  │                              └───────────────────────────┘        │
  │                                                                    │
  │                              ┌─ GREEN (idle) ────────────┐        │
  │                              │  (empty — no instances)    │        │
  │                              └───────────────────────────┘        │
  └────────────────────────────────────────────────────────────────────┘

  ┌─ Phase 2: Deploy to GREEN ───────────────────────────────────────┐
  │                                                                    │
  │  Users ──▶ Load Balancer ──▶ ┌─ BLUE (v1.0) ─── LIVE ──┐        │
  │                100%          │  ┌────┐ ┌────┐ ┌────┐    │        │
  │                              │  │ I1 │ │ I2 │ │ I3 │    │        │
  │                              │  └────┘ └────┘ └────┘    │        │
  │                              └───────────────────────────┘        │
  │                                                                    │
  │  Deploy ─────────────────▶   ┌─ GREEN (v2.0) ── TEST ──┐        │
  │  & Test                      │  ┌────┐ ┌────┐ ┌────┐    │        │
  │                              │  │ I4 │ │ I5 │ │ I6 │    │        │
  │                              │  └────┘ └────┘ └────┘    │        │
  │       Smoke tests, health    └───────────────────────────┘        │
  │       checks pass ✓                                               │
  └────────────────────────────────────────────────────────────────────┘

  ┌─ Phase 3: SWITCH traffic ────────────────────────────────────────┐
  │                                                                    │
  │                              ┌─ BLUE (v1.0) ─── IDLE ──┐        │
  │                              │  ┌────┐ ┌────┐ ┌────┐    │        │
  │                              │  │ I1 │ │ I2 │ │ I3 │    │        │
  │                              │  └────┘ └────┘ └────┘    │        │
  │                              └───────────────────────────┘        │
  │                                         ◀── instant rollback      │
  │  Users ──▶ Load Balancer ──▶ ┌─ GREEN (v2.0) ── LIVE ──┐        │
  │                100%          │  ┌────┐ ┌────┐ ┌────┐    │        │
  │                              │  │ I4 │ │ I5 │ │ I6 │    │        │
  │                              │  └────┘ └────┘ └────┘    │        │
  │                              └───────────────────────────┘        │
  └────────────────────────────────────────────────────────────────────┘

  ┌─ VARIANTS ───────────────────────────────────────────────────────┐
  │                                                                    │
  │  Blue-Green:     100% switch, instant                              │
  │  Canary:         Gradual 1% → 10% → 50% → 100%                   │
  │  Rolling Update: Replace instances one-by-one                      │
  │  A/B Testing:    Route by user attributes, not just percentage     │
  │                                                                    │
  │  ┌─ Canary Timeline ───────────────────────────────────────┐      │
  │  │                                                          │      │
  │  │  t=0     t=5m    t=15m    t=30m    t=60m                │      │
  │  │  ┌─┐    ┌──┐    ┌────┐   ┌──────┐  ┌──────────────┐    │      │
  │  │  │1│    │5%│    │ 25%│   │  50% │  │    100%      │    │      │
  │  │  │%│    │  │    │    │   │      │  │              │    │      │
  │  │  └─┘    └──┘    └────┘   └──────┘  └──────────────┘    │      │
  │  │  Monitor error rates at each step                       │      │
  │  └─────────────────────────────────────────────────────────┘      │
  └────────────────────────────────────────────────────────────────────┘
```

### Complete Implementation

```python
"""
Blue-Green Deployment System
=============================
Supports blue-green instant cutover, canary (gradual traffic shift),
and rolling updates with automated health verification and rollback.
"""

import time
import uuid
import json
import threading
import logging
import random
from datetime import datetime, timedelta
from dataclasses import dataclass, field
from enum import Enum
from typing import Dict, List, Optional, Tuple, Callable
from collections import defaultdict

logging.basicConfig(level=logging.INFO,
                    format='%(asctime)s [%(levelname)s] %(message)s')
logger = logging.getLogger(__name__)


# ─── Data Models ────────────────────────────────────────────────────

class EnvironmentStatus(Enum):
    IDLE = "idle"             # No traffic, ready for deploy
    DEPLOYING = "deploying"   # New version being deployed
    TESTING = "testing"       # Running pre-switch tests
    LIVE = "live"             # Serving production traffic
    DRAINING = "draining"     # Finishing in-flight requests
    FAILED = "failed"         # Deploy failed


class DeploymentStrategy(Enum):
    BLUE_GREEN = "blue_green"
    CANARY = "canary"
    ROLLING = "rolling"


class DeploymentStatus(Enum):
    PENDING = "pending"
    IN_PROGRESS = "in_progress"
    VERIFYING = "verifying"
    SWITCHING = "switching"
    COMPLETED = "completed"
    ROLLED_BACK = "rolled_back"
    FAILED = "failed"


@dataclass
class AppVersion:
    version: str
    image: str                    # Docker image
    commit_sha: str = ""
    deployed_at: Optional[datetime] = None
    config: Dict = field(default_factory=dict)


@dataclass
class Instance:
    instance_id: str
    host: str
    port: int
    version: str
    healthy: bool = True
    request_count: int = 0
    error_count: int = 0

    @property
    def error_rate(self) -> float:
        if self.request_count == 0:
            return 0.0
        return self.error_count / self.request_count


@dataclass
class Environment:
    """One half of the blue/green pair."""
    name: str                             # "blue" or "green"
    status: EnvironmentStatus = EnvironmentStatus.IDLE
    version: Optional[AppVersion] = None
    instances: List[Instance] = field(default_factory=list)
    traffic_weight: float = 0.0           # 0.0 to 1.0
    deployed_at: Optional[datetime] = None

    @property
    def is_healthy(self) -> bool:
        if not self.instances:
            return False
        healthy_count = sum(1 for i in self.instances if i.healthy)
        return healthy_count / len(self.instances) >= 0.8

    @property
    def avg_error_rate(self) -> float:
        rates = [i.error_rate for i in self.instances
                 if i.request_count > 0]
        return sum(rates) / len(rates) if rates else 0.0


@dataclass
class CanaryConfig:
    """Configuration for canary deployments."""
    steps: List[float] = field(
        default_factory=lambda: [0.01, 0.05, 0.10, 0.25, 0.50, 1.0]
    )
    step_interval_seconds: int = 60       # Wait between steps
    error_rate_threshold: float = 0.05    # 5% — auto-rollback
    latency_threshold_ms: float = 500     # p99 latency threshold
    min_requests_for_eval: int = 100      # Min requests before evaluating


@dataclass
class DeploymentRecord:
    deployment_id: str
    strategy: DeploymentStrategy
    from_version: str
    to_version: str
    status: DeploymentStatus
    started_at: datetime
    completed_at: Optional[datetime] = None
    events: List[Dict] = field(default_factory=list)
    rollback_reason: str = ""

    def add_event(self, message: str):
        self.events.append({
            "timestamp": datetime.utcnow().isoformat(),
            "message": message,
        })
        logger.info(f"  📋 {message}")


# ─── Traffic Router ────────────────────────────────────────────────

class TrafficRouter:
    """
    Routes traffic between blue and green environments
    based on configured weights.
    """

    def __init__(self):
        self.blue_weight: float = 1.0   # 100% to blue initially
        self.green_weight: float = 0.0
        self._lock = threading.Lock()

    def set_weights(self, blue: float, green: float):
        with self._lock:
            self.blue_weight = blue
            self.green_weight = green
        logger.info(f"  🔀 Traffic weights: blue={blue*100:.0f}% "
                    f"green={green*100:.0f}%")

    def route_request(self) -> str:
        """Returns 'blue' or 'green' based on weights."""
        with self._lock:
            if random.random() < self.blue_weight:
                return "blue"
            return "green"

    def switch_to_blue(self):
        self.set_weights(1.0, 0.0)

    def switch_to_green(self):
        self.set_weights(0.0, 1.0)


# ─── Health Verifier ──────────────────────────────────────────────

class HealthVerifier:
    """
    Runs health checks and smoke tests against an environment
    before it goes live.
    """

    def __init__(self):
        self.checks: List[Callable] = []

    def add_check(self, name: str, check_fn: Callable):
        self.checks.append((name, check_fn))

    def verify(self, environment: Environment) -> Tuple[bool, List[Dict]]:
        """Run all health checks. Returns (passed, results)."""
        results = []
        all_passed = True

        for name, check_fn in self.checks:
            try:
                passed = check_fn(environment)
                results.append({
                    "check": name,
                    "passed": passed,
                    "error": None,
                })
                if not passed:
                    all_passed = False
            except Exception as e:
                results.append({
                    "check": name,
                    "passed": False,
                    "error": str(e),
                })
                all_passed = False

        return all_passed, results

    @staticmethod
    def default_checks() -> 'HealthVerifier':
        """Create verifier with standard checks."""
        verifier = HealthVerifier()

        verifier.add_check("instances_healthy", lambda env:
            env.is_healthy)
        verifier.add_check("min_instances", lambda env:
            len(env.instances) >= 2)
        verifier.add_check("error_rate_low", lambda env:
            env.avg_error_rate < 0.05)
        verifier.add_check("version_deployed", lambda env:
            env.version is not None)

        return verifier


# ─── Instance Provisioner ─────────────────────────────────────────

class InstanceProvisioner:
    """Provisions and manages instances in an environment."""

    def deploy_to_environment(self, env: Environment,
                              version: AppVersion,
                              instance_count: int = 3) -> bool:
        """Deploy a version to an environment."""
        env.status = EnvironmentStatus.DEPLOYING
        env.version = version
        env.instances = []

        logger.info(f"  🐳 Deploying {version.image} to {env.name} "
                    f"({instance_count} instances)")

        for i in range(instance_count):
            instance = Instance(
                instance_id=f"{env.name}-{uuid.uuid4().hex[:6]}",
                host=f"10.0.{1 if env.name == 'blue' else 2}.{10+i}",
                port=8080,
                version=version.version,
                healthy=True,
            )
            env.instances.append(instance)
            time.sleep(0.1)  # Simulated deploy time

        env.deployed_at = datetime.utcnow()
        version.deployed_at = datetime.utcnow()
        env.status = EnvironmentStatus.TESTING

        logger.info(f"  ✅ Deployed {instance_count} instances to {env.name}")
        return True

    def teardown_environment(self, env: Environment):
        """Remove all instances from an environment."""
        logger.info(f"  🗑️  Tearing down {env.name} environment")
        env.instances = []
        env.status = EnvironmentStatus.IDLE
        env.traffic_weight = 0.0


# ─── Blue-Green Deployment Manager ────────────────────────────────

class BlueGreenDeployer:
    """
    Main deployment manager that coordinates blue-green,
    canary, and rolling deployments.
    """

    def __init__(self):
        self.blue = Environment(name="blue",
                                status=EnvironmentStatus.LIVE)
        self.green = Environment(name="green",
                                 status=EnvironmentStatus.IDLE)
        self.router = TrafficRouter()
        self.verifier = HealthVerifier.default_checks()
        self.provisioner = InstanceProvisioner()
        self.deployment_history: List[DeploymentRecord] = []
        self._current_deployment: Optional[DeploymentRecord] = None
        self._lock = threading.Lock()

    @property
    def live_env(self) -> Environment:
        if self.blue.status == EnvironmentStatus.LIVE:
            return self.blue
        return self.green

    @property
    def idle_env(self) -> Environment:
        if self.blue.status == EnvironmentStatus.LIVE:
            return self.green
        return self.blue

    @property
    def current_version(self) -> Optional[str]:
        live = self.live_env
        return live.version.version if live.version else None

    # ── Blue-Green Deploy ────────────────────────────────────────

    def deploy_blue_green(self, version: AppVersion,
                          instance_count: int = 3) -> DeploymentRecord:
        """
        Full blue-green deployment:
        1. Deploy to idle environment
        2. Run health checks
        3. Switch traffic instantly
        4. Keep old environment as rollback target
        """
        record = self._start_deployment(
            DeploymentStrategy.BLUE_GREEN, version)

        target = self.idle_env
        source = self.live_env

        try:
            # Step 1: Deploy to idle environment
            record.add_event(f"Deploying {version.version} to "
                             f"{target.name} environment")
            success = self.provisioner.deploy_to_environment(
                target, version, instance_count)

            if not success:
                return self._fail_deployment(record, "Deploy failed")

            # Step 2: Health verification
            record.add_event("Running health verification")
            time.sleep(0.5)  # Wait for instances to stabilize
            passed, results = self.verifier.verify(target)

            for r in results:
                emoji = "✅" if r["passed"] else "❌"
                record.add_event(f"  {emoji} {r['check']}: "
                                 f"{'PASS' if r['passed'] else 'FAIL'}")

            if not passed:
                return self._fail_deployment(
                    record, "Health verification failed",
                    target=target)

            # Step 3: Switch traffic
            record.status = DeploymentStatus.SWITCHING
            record.add_event(f"Switching traffic: {source.name} → "
                             f"{target.name}")

            if target.name == "green":
                self.router.switch_to_green()
            else:
                self.router.switch_to_blue()

            target.status = EnvironmentStatus.LIVE
            target.traffic_weight = 1.0
            source.status = EnvironmentStatus.DRAINING
            source.traffic_weight = 0.0

            # Step 4: Drain old environment
            record.add_event(f"Draining {source.name} (30s)")
            time.sleep(0.3)  # Simulated drain
            source.status = EnvironmentStatus.IDLE

            return self._complete_deployment(record)

        except Exception as e:
            return self._fail_deployment(record, str(e), target=target)

    # ── Canary Deploy ────────────────────────────────────────────

    def deploy_canary(self, version: AppVersion,
                      canary_config: CanaryConfig = None,
                      instance_count: int = 3) -> DeploymentRecord:
        """
        Canary deployment:
        1. Deploy to idle environment
        2. Gradually shift traffic (1% → 5% → 25% → 50% → 100%)
        3. Monitor error rates at each step
        4. Auto-rollback if errors exceed threshold
        """
        config = canary_config or CanaryConfig()
        record = self._start_deployment(
            DeploymentStrategy.CANARY, version)

        target = self.idle_env
        source = self.live_env

        try:
            # Deploy
            record.add_event(f"Deploying canary {version.version} to "
                             f"{target.name}")
            self.provisioner.deploy_to_environment(
                target, version, instance_count)

            # Health check
            passed, _ = self.verifier.verify(target)
            if not passed:
                return self._fail_deployment(
                    record, "Initial health check failed", target=target)

            # Gradual traffic shift
            for step_pct in config.steps:
                record.add_event(
                    f"Canary step: {step_pct*100:.0f}% traffic "
                    f"to {target.name} (v{version.version})")

                # Update weights
                target.traffic_weight = step_pct
                source.traffic_weight = 1.0 - step_pct

                if target.name == "green":
                    self.router.set_weights(1 - step_pct, step_pct)
                else:
                    self.router.set_weights(step_pct, 1 - step_pct)

                # Simulate traffic and monitor
                self._simulate_traffic(source, target, duration=0.3)

                # Evaluate metrics
                error_rate = target.avg_error_rate
                record.add_event(
                    f"  Error rate: {error_rate*100:.2f}% "
                    f"(threshold: {config.error_rate_threshold*100:.1f}%)")

                if error_rate > config.error_rate_threshold:
                    record.add_event(
                        f"  ⚠️ Error rate exceeded threshold — ROLLING BACK")
                    return self._rollback(record, source, target)

                time.sleep(0.2)  # Wait between steps

            # All steps passed — finalize
            target.status = EnvironmentStatus.LIVE
            source.status = EnvironmentStatus.IDLE
            return self._complete_deployment(record)

        except Exception as e:
            return self._fail_deployment(record, str(e), target=target)

    # ── Rollback ─────────────────────────────────────────────────

    def rollback(self) -> Optional[DeploymentRecord]:
        """Rollback to the previous version."""
        source = self.live_env
        target = self.idle_env

        if target.version is None:
            logger.error("No previous version to rollback to")
            return None

        record = DeploymentRecord(
            deployment_id=f"deploy-{uuid.uuid4().hex[:8]}",
            strategy=DeploymentStrategy.BLUE_GREEN,
            from_version=source.version.version if source.version else "unknown",
            to_version=target.version.version,
            status=DeploymentStatus.IN_PROGRESS,
            started_at=datetime.utcnow(),
        )
        record.add_event("🔄 ROLLBACK initiated")

        return self._rollback(record, target, source)

    def _rollback(self, record: DeploymentRecord,
                  rollback_to: Environment,
                  rollback_from: Environment) -> DeploymentRecord:
        """Execute rollback — switch traffic back."""
        record.status = DeploymentStatus.ROLLED_BACK
        record.rollback_reason = record.events[-1]["message"] \
            if record.events else "Manual rollback"

        # Switch traffic back
        if rollback_to.name == "blue":
            self.router.switch_to_blue()
        else:
            self.router.switch_to_green()

        rollback_to.status = EnvironmentStatus.LIVE
        rollback_to.traffic_weight = 1.0
        rollback_from.status = EnvironmentStatus.IDLE
        rollback_from.traffic_weight = 0.0

        record.add_event(f"Traffic restored to {rollback_to.name} "
                         f"(v{rollback_to.version.version if rollback_to.version else '?'})")
        record.completed_at = datetime.utcnow()
        self.deployment_history.append(record)
        return record

    # ── Helpers ──────────────────────────────────────────────────

    def _start_deployment(self, strategy: DeploymentStrategy,
                          version: AppVersion) -> DeploymentRecord:
        record = DeploymentRecord(
            deployment_id=f"deploy-{uuid.uuid4().hex[:8]}",
            strategy=strategy,
            from_version=self.current_version or "none",
            to_version=version.version,
            status=DeploymentStatus.IN_PROGRESS,
            started_at=datetime.utcnow(),
        )
        self._current_deployment = record

        logger.info(f"\n{'='*60}")
        logger.info(f"🚀 DEPLOYMENT: {strategy.value} | "
                    f"{record.from_version} → {version.version}")
        logger.info(f"   ID: {record.deployment_id}")
        logger.info(f"{'='*60}")

        return record

    def _complete_deployment(self, record: DeploymentRecord) \
            -> DeploymentRecord:
        record.status = DeploymentStatus.COMPLETED
        record.completed_at = datetime.utcnow()
        duration = (record.completed_at - record.started_at).total_seconds()
        record.add_event(f"✅ Deployment COMPLETED in {duration:.1f}s")
        self.deployment_history.append(record)
        self._current_deployment = None
        return record

    def _fail_deployment(self, record: DeploymentRecord, reason: str,
                         target: Environment = None) -> DeploymentRecord:
        record.status = DeploymentStatus.FAILED
        record.completed_at = datetime.utcnow()
        record.add_event(f"❌ Deployment FAILED: {reason}")
        if target:
            self.provisioner.teardown_environment(target)
        self.deployment_history.append(record)
        self._current_deployment = None
        return record

    def _simulate_traffic(self, source: Environment,
                          target: Environment, duration: float = 1.0):
        """Simulate traffic to both environments."""
        end_time = time.time() + duration
        while time.time() < end_time:
            env_name = self.router.route_request()
            env = source if env_name == source.name else target

            if env.instances:
                inst = random.choice(env.instances)
                inst.request_count += 1
                # Simulate errors (new version might have bugs)
                if env == target and random.random() < 0.02:
                    inst.error_count += 1
            time.sleep(0.01)

    def get_status(self) -> Dict:
        return {
            "blue": {
                "status": self.blue.status.value,
                "version": self.blue.version.version
                           if self.blue.version else None,
                "instances": len(self.blue.instances),
                "healthy": self.blue.is_healthy if self.blue.instances else False,
                "traffic": f"{self.blue.traffic_weight*100:.0f}%",
            },
            "green": {
                "status": self.green.status.value,
                "version": self.green.version.version
                           if self.green.version else None,
                "instances": len(self.green.instances),
                "healthy": self.green.is_healthy if self.green.instances else False,
                "traffic": f"{self.green.traffic_weight*100:.0f}%",
            },
            "live_environment": self.live_env.name,
            "current_version": self.current_version,
            "deployment_count": len(self.deployment_history),
        }

    def get_deployment_history(self) -> List[Dict]:
        return [
            {
                "id": d.deployment_id,
                "strategy": d.strategy.value,
                "from": d.from_version,
                "to": d.to_version,
                "status": d.status.value,
                "started": d.started_at.isoformat(),
                "completed": d.completed_at.isoformat()
                             if d.completed_at else None,
                "duration": (
                    (d.completed_at - d.started_at).total_seconds()
                    if d.completed_at else None
                ),
                "events_count": len(d.events),
                "rollback_reason": d.rollback_reason,
            }
            for d in self.deployment_history
        ]


# ─── AWS Integration ──────────────────────────────────────────────

class AWSBlueGreenDeployer:
    """
    Blue-green deployment using AWS services:
    - ECS with target groups
    - ALB listener rules for traffic switching
    - Route 53 weighted routing
    """

    def __init__(self, region: str = "us-east-1"):
        try:
            import boto3
            self.ecs = boto3.client('ecs', region_name=region)
            self.elb = boto3.client('elbv2', region_name=region)
            self.route53 = boto3.client('route53', region_name=region)
        except ImportError:
            logger.warning("boto3 not installed — demo mode")
            self.ecs = None

    def create_ecs_service(self, cluster: str, service_name: str,
                           task_def: str, target_group_arn: str,
                           desired_count: int = 3):
        """Create an ECS service in a target group."""
        if not self.ecs:
            return {"simulated": True, "service": service_name}

        return self.ecs.create_service(
            cluster=cluster,
            serviceName=service_name,
            taskDefinition=task_def,
            desiredCount=desired_count,
            loadBalancers=[{
                'targetGroupArn': target_group_arn,
                'containerName': service_name,
                'containerPort': 8080,
            }],
            deploymentConfiguration={
                'maximumPercent': 200,
                'minimumHealthyPercent': 100,
            },
        )

    def switch_traffic(self, listener_arn: str,
                       blue_tg_arn: str, green_tg_arn: str,
                       blue_weight: int = 0, green_weight: int = 100):
        """Switch ALB listener to point to different target group."""
        if not self.elb:
            return {"simulated": True, "blue": blue_weight,
                    "green": green_weight}

        return self.elb.modify_listener(
            ListenerArn=listener_arn,
            DefaultActions=[{
                'Type': 'forward',
                'ForwardConfig': {
                    'TargetGroups': [
                        {
                            'TargetGroupArn': blue_tg_arn,
                            'Weight': blue_weight,
                        },
                        {
                            'TargetGroupArn': green_tg_arn,
                            'Weight': green_weight,
                        },
                    ],
                },
            }],
        )

    def route53_weighted_switch(self, hosted_zone_id: str,
                                record_name: str,
                                blue_ip: str, green_ip: str,
                                blue_weight: int = 0,
                                green_weight: int = 100):
        """Use Route 53 weighted routing for traffic shift."""
        if not self.route53:
            return {"simulated": True}

        return self.route53.change_resource_record_sets(
            HostedZoneId=hosted_zone_id,
            ChangeBatch={
                'Changes': [
                    {
                        'Action': 'UPSERT',
                        'ResourceRecordSet': {
                            'Name': record_name,
                            'Type': 'A',
                            'SetIdentifier': 'blue',
                            'Weight': blue_weight,
                            'TTL': 60,
                            'ResourceRecords': [{'Value': blue_ip}],
                        },
                    },
                    {
                        'Action': 'UPSERT',
                        'ResourceRecordSet': {
                            'Name': record_name,
                            'Type': 'A',
                            'SetIdentifier': 'green',
                            'Weight': green_weight,
                            'TTL': 60,
                            'ResourceRecords': [{'Value': green_ip}],
                        },
                    },
                ],
            },
        )


# ─── Demo ───────────────────────────────────────────────────────────

def main():
    print("=" * 70)
    print("       BLUE-GREEN DEPLOYMENT SYSTEM DEMO")
    print("=" * 70)

    deployer = BlueGreenDeployer()

    # Deploy initial version to blue
    print("\n" + "─" * 60)
    print("1. Initial deployment (v1.0)")
    print("─" * 60)

    v1 = AppVersion(version="1.0.0", image="myapp:v1.0.0",
                    commit_sha="abc123")
    deployer.provisioner.deploy_to_environment(
        deployer.blue, v1, instance_count=3)
    deployer.blue.status = EnvironmentStatus.LIVE
    deployer.blue.traffic_weight = 1.0
    deployer.router.switch_to_blue()

    print(f"\nStatus: {json.dumps(deployer.get_status(), indent=2)}")

    # ── Blue-Green Deploy v2.0 ──────────────────────────────────

    print("\n" + "─" * 60)
    print("2. Blue-Green deployment (v1.0 → v2.0)")
    print("─" * 60)

    v2 = AppVersion(version="2.0.0", image="myapp:v2.0.0",
                    commit_sha="def456")
    record = deployer.deploy_blue_green(v2, instance_count=3)

    print(f"\nResult: {record.status.value}")
    print(f"Status: {json.dumps(deployer.get_status(), indent=2)}")

    # ── Canary Deploy v3.0 ──────────────────────────────────────

    print("\n" + "─" * 60)
    print("3. Canary deployment (v2.0 → v3.0)")
    print("─" * 60)

    v3 = AppVersion(version="3.0.0", image="myapp:v3.0.0",
                    commit_sha="ghi789")
    canary_config = CanaryConfig(
        steps=[0.05, 0.25, 0.50, 1.0],
        step_interval_seconds=30,
        error_rate_threshold=0.10,
    )
    record = deployer.deploy_canary(v3, canary_config,
                                     instance_count=3)

    print(f"\nResult: {record.status.value}")
    print(f"Status: {json.dumps(deployer.get_status(), indent=2)}")

    # ── Rollback ────────────────────────────────────────────────

    print("\n" + "─" * 60)
    print("4. Manual rollback")
    print("─" * 60)

    rollback_record = deployer.rollback()
    if rollback_record:
        print(f"\nRollback result: {rollback_record.status.value}")
        print(f"Status: {json.dumps(deployer.get_status(), indent=2)}")

    # ── Deploy again (v3.0, blue-green) ─────────────────────────

    print("\n" + "─" * 60)
    print("5. Re-deploy v3.0 via blue-green")
    print("─" * 60)

    record = deployer.deploy_blue_green(v3, instance_count=3)
    print(f"\nResult: {record.status.value}")

    # ── Deployment History ──────────────────────────────────────

    print("\n" + "─" * 60)
    print("Deployment History")
    print("─" * 60)
    for entry in deployer.get_deployment_history():
        duration = f"{entry['duration']:.1f}s" if entry['duration'] else "N/A"
        print(f"  [{entry['status']:12s}] {entry['strategy']:12s} "
              f"{entry['from']:8s} → {entry['to']:8s} "
              f"({duration})")
        if entry['rollback_reason']:
            print(f"    └─ Rollback: {entry['rollback_reason']}")


if __name__ == "__main__":
    main()
```

---

## Summary Comparison

| System | Core Pattern | Key Challenge | AWS Service |
|--------|-------------|---------------|-------------|
| **Auto Scaling** | Control loop: observe → decide → act | Avoiding oscillation (cooldown) | EC2 Auto Scaling |
| **CI/CD Pipeline** | DAG of stages with gates | Parallelism + failure handling | CodePipeline + CodeBuild |
| **Container Orchestration** | Desired state reconciliation | Bin-packing scheduling | ECS / EKS |
| **Service Discovery** | Registry + heartbeats + LB | Consistency during failures | Cloud Map / Route 53 |
| **Blue-Green Deploy** | Two identical envs + traffic switch | Zero-downtime cutover | CodeDeploy + ALB |

Each system follows the **control loop pattern**: continuously compare desired state vs actual state and take corrective action. This is the fundamental principle behind all modern cloud infrastructure.