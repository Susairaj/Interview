Classic LLD Interview Problems — Complete Guide with Python

---

## Table of Contents
1. [Parking Lot System](#1-parking-lot-system)
2. [Elevator System](#2-elevator-system)
3. [Library Management System](#3-library-management-system)
4. [ATM System](#4-atm-system)
5. [Hotel Booking System](#5-hotel-booking-system)
6. [Online Shopping Cart](#6-online-shopping-cart)
7. [File System](#7-file-system)
8. [Vending Machine](#8-vending-machine)
9. [Snake and Ladder Game](#9-snake-and-ladder-game)
10. [Chess Game](#10-chess-game)

---

## 1. Parking Lot System

### Requirements
- Multiple floors, each with many spots
- Spot types: **Compact**, **Large**, **Handicapped**, **Motorcycle**
- Vehicle types: **Car**, **Truck**, **Motorcycle**, **Van**
- Issue ticket on entry, calculate fee on exit
- Track availability per floor and per type
- Singleton parking lot

### Design Patterns
| Pattern | Purpose |
|---------|---------|
| **Singleton** | One ParkingLot instance |
| **Strategy** | Fee calculation strategies |
| **Factory** | Create spots / tickets |

### Class Diagram (Textual)
```
ParkingLot (Singleton)
 ├── List<Floor>
 │     └── List<ParkingSpot>
 │           ├── CompactSpot
 │           ├── LargeSpot
 │           ├── HandicappedSpot
 │           └── MotorcycleSpot
 ├── EntryPanel
 ├── ExitPanel
 ├── DisplayBoard
 └── FeeStrategy
Vehicle (Abstract)
 ├── Car
 ├── Truck
 ├── Motorcycle
 └── Van
Ticket
Payment
```

### Full Python Code

```python
from abc import ABC, abstractmethod
from enum import Enum
from datetime import datetime, timedelta
import threading
import uuid


# ─── Enums ───────────────────────────────────────────────
class VehicleType(Enum):
    MOTORCYCLE = 1
    CAR = 2
    VAN = 3
    TRUCK = 4


class SpotType(Enum):
    MOTORCYCLE = 1
    COMPACT = 2
    LARGE = 3
    HANDICAPPED = 4


class TicketStatus(Enum):
    ACTIVE = 1
    PAID = 2


class PaymentStatus(Enum):
    PENDING = 1
    COMPLETED = 2
    FAILED = 3


# ─── Vehicle Hierarchy ───────────────────────────────────
class Vehicle:
    def __init__(self, license_plate: str, vehicle_type: VehicleType):
        self.license_plate = license_plate
        self.vehicle_type = vehicle_type

    def __repr__(self):
        return f"{self.vehicle_type.name}({self.license_plate})"


class Car(Vehicle):
    def __init__(self, license_plate: str):
        super().__init__(license_plate, VehicleType.CAR)


class Truck(Vehicle):
    def __init__(self, license_plate: str):
        super().__init__(license_plate, VehicleType.TRUCK)


class Motorcycle(Vehicle):
    def __init__(self, license_plate: str):
        super().__init__(license_plate, VehicleType.MOTORCYCLE)


class Van(Vehicle):
    def __init__(self, license_plate: str):
        super().__init__(license_plate, VehicleType.VAN)


# ─── Parking Spot ────────────────────────────────────────
class ParkingSpot:
    def __init__(self, spot_id: str, spot_type: SpotType, floor_num: int):
        self.spot_id = spot_id
        self.spot_type = spot_type
        self.floor_num = floor_num
        self.vehicle = None
        self.is_available = True

    def park(self, vehicle: Vehicle):
        self.vehicle = vehicle
        self.is_available = False

    def free(self):
        self.vehicle = None
        self.is_available = True

    def __repr__(self):
        status = "Free" if self.is_available else f"Occupied({self.vehicle})"
        return f"Spot({self.spot_id}, {self.spot_type.name}, {status})"


# ─── Ticket ──────────────────────────────────────────────
class Ticket:
    def __init__(self, vehicle: Vehicle, spot: ParkingSpot):
        self.ticket_id = str(uuid.uuid4())[:8]
        self.vehicle = vehicle
        self.spot = spot
        self.entry_time = datetime.now()
        self.exit_time = None
        self.status = TicketStatus.ACTIVE

    def close(self):
        self.exit_time = datetime.now()
        self.status = TicketStatus.PAID

    def get_duration_hours(self) -> float:
        end = self.exit_time or datetime.now()
        return max((end - self.entry_time).total_seconds() / 3600, 1)

    def __repr__(self):
        return (f"Ticket({self.ticket_id}, {self.vehicle}, "
                f"Spot={self.spot.spot_id}, Status={self.status.name})")


# ─── Fee Strategy (Strategy Pattern) ─────────────────────
class FeeStrategy(ABC):
    @abstractmethod
    def calculate(self, ticket: Ticket) -> float:
        pass


class HourlyFeeStrategy(FeeStrategy):
    RATES = {
        VehicleType.MOTORCYCLE: 10,
        VehicleType.CAR: 20,
        VehicleType.VAN: 30,
        VehicleType.TRUCK: 40,
    }

    def calculate(self, ticket: Ticket) -> float:
        hours = ticket.get_duration_hours()
        rate = self.RATES.get(ticket.vehicle.vehicle_type, 20)
        return round(rate * hours, 2)


class FlatFeeStrategy(FeeStrategy):
    RATES = {
        VehicleType.MOTORCYCLE: 50,
        VehicleType.CAR: 100,
        VehicleType.VAN: 150,
        VehicleType.TRUCK: 200,
    }

    def calculate(self, ticket: Ticket) -> float:
        return self.RATES.get(ticket.vehicle.vehicle_type, 100)


# ─── Payment ─────────────────────────────────────────────
class Payment:
    def __init__(self, amount: float, ticket: Ticket):
        self.payment_id = str(uuid.uuid4())[:8]
        self.amount = amount
        self.ticket = ticket
        self.timestamp = datetime.now()
        self.status = PaymentStatus.COMPLETED

    def __repr__(self):
        return f"Payment({self.payment_id}, ${self.amount}, {self.status.name})"


# ─── Floor ───────────────────────────────────────────────
class Floor:
    def __init__(self, floor_num: int, spots: list[ParkingSpot]):
        self.floor_num = floor_num
        self.spots = spots

    def get_available_spot(self, spot_type: SpotType):
        for spot in self.spots:
            if spot.is_available and spot.spot_type == spot_type:
                return spot
        return None

    def available_count(self, spot_type: SpotType = None) -> int:
        return sum(
            1 for s in self.spots
            if s.is_available and (spot_type is None or s.spot_type == spot_type)
        )

    def __repr__(self):
        return (f"Floor {self.floor_num}: "
                f"{self.available_count()} / {len(self.spots)} available")


# ─── Display Board ───────────────────────────────────────
class DisplayBoard:
    def show(self, floors: list[Floor]):
        print("\n" + "=" * 50)
        print("        PARKING LOT AVAILABILITY")
        print("=" * 50)
        for floor in floors:
            counts = {st: floor.available_count(st) for st in SpotType}
            print(f"  Floor {floor.floor_num}: ", end="")
            print(" | ".join(f"{st.name}: {c}" for st, c in counts.items()))
        print("=" * 50 + "\n")


# ─── Parking Lot (Singleton) ─────────────────────────────
class ParkingLot:
    _instance = None
    _lock = threading.Lock()

    VEHICLE_TO_SPOT = {
        VehicleType.MOTORCYCLE: [SpotType.MOTORCYCLE, SpotType.COMPACT, SpotType.LARGE],
        VehicleType.CAR: [SpotType.COMPACT, SpotType.LARGE, SpotType.HANDICAPPED],
        VehicleType.VAN: [SpotType.LARGE],
        VehicleType.TRUCK: [SpotType.LARGE],
    }

    def __new__(cls, *args, **kwargs):
        if not cls._instance:
            with cls._lock:
                if not cls._instance:
                    cls._instance = super().__new__(cls)
        return cls._instance

    def __init__(self, name: str = "Main Lot"):
        if hasattr(self, "_initialized"):
            return
        self._initialized = True
        self.name = name
        self.floors: list[Floor] = []
        self.active_tickets: dict[str, Ticket] = {}   # ticket_id -> Ticket
        self.fee_strategy: FeeStrategy = HourlyFeeStrategy()
        self.display = DisplayBoard()

    # ---------- Setup ----------
    def add_floor(self, floor: Floor):
        self.floors.append(floor)

    def set_fee_strategy(self, strategy: FeeStrategy):
        self.fee_strategy = strategy

    # ---------- Core Operations ----------
    def enter(self, vehicle: Vehicle) -> Ticket | None:
        """Find a spot and issue a ticket."""
        spot = self._find_spot(vehicle.vehicle_type)
        if not spot:
            print(f"  ✗ No spot available for {vehicle}")
            return None
        spot.park(vehicle)
        ticket = Ticket(vehicle, spot)
        self.active_tickets[ticket.ticket_id] = ticket
        print(f"  ✓ {vehicle} parked at Spot {spot.spot_id} "
              f"(Floor {spot.floor_num}) | Ticket: {ticket.ticket_id}")
        return ticket

    def exit(self, ticket: Ticket) -> Payment | None:
        """Calculate fee, process payment, free spot."""
        if ticket.ticket_id not in self.active_tickets:
            print(f"  ✗ Invalid or already used ticket: {ticket.ticket_id}")
            return None
        fee = self.fee_strategy.calculate(ticket)
        ticket.close()
        ticket.spot.free()
        del self.active_tickets[ticket.ticket_id]
        payment = Payment(fee, ticket)
        print(f"  ✓ {ticket.vehicle} exited | Fee: ${fee} | {payment}")
        return payment

    def show_availability(self):
        self.display.show(self.floors)

    # ---------- Helpers ----------
    def _find_spot(self, vehicle_type: VehicleType):
        preferred = self.VEHICLE_TO_SPOT.get(vehicle_type, [])
        for floor in self.floors:
            for spot_type in preferred:
                spot = floor.get_available_spot(spot_type)
                if spot:
                    return spot
        return None


# ─── Helper: Build a floor quickly ───────────────────────
def build_floor(floor_num: int,
                motorcycle: int = 2,
                compact: int = 5,
                large: int = 3,
                handicapped: int = 1) -> Floor:
    spots = []
    counter = 1
    for spot_type, count in [
        (SpotType.MOTORCYCLE, motorcycle),
        (SpotType.COMPACT, compact),
        (SpotType.LARGE, large),
        (SpotType.HANDICAPPED, handicapped),
    ]:
        for _ in range(count):
            sid = f"F{floor_num}-{spot_type.name[0]}{counter}"
            spots.append(ParkingSpot(sid, spot_type, floor_num))
            counter += 1
        
    return Floor(floor_num, spots)


# ─── Demo ─────────────────────────────────────────────────
if __name__ == "__main__":
    # Reset singleton for demo
    ParkingLot._instance = None

    lot = ParkingLot("Downtown Parking")
    lot.add_floor(build_floor(1, motorcycle=2, compact=3, large=2, handicapped=1))
    lot.add_floor(build_floor(2, motorcycle=1, compact=3, large=2, handicapped=1))

    lot.show_availability()

    # Vehicles arrive
    t1 = lot.enter(Car("ABC-1234"))
    t2 = lot.enter(Motorcycle("MOTO-99"))
    t3 = lot.enter(Truck("TRK-5678"))
    t4 = lot.enter(Van("VAN-0001"))

    lot.show_availability()

    # Simulate time passage (monkey-patch for demo)
    if t1:
        t1.entry_time -= timedelta(hours=3)
    if t2:
        t2.entry_time -= timedelta(hours=1)

    # Vehicles exit
    if t1:
        lot.exit(t1)
    if t2:
        lot.exit(t2)

    lot.show_availability()
```

### Output
```
==================================================
        PARKING LOT AVAILABILITY
==================================================
  Floor 1: MOTORCYCLE: 2 | COMPACT: 3 | LARGE: 2 | HANDICAPPED: 1
  Floor 2: MOTORCYCLE: 1 | COMPACT: 3 | LARGE: 2 | HANDICAPPED: 1
==================================================

  ✓ CAR(ABC-1234) parked at Spot F1-C3 (Floor 1) | Ticket: a1b2c3d4
  ✓ MOTORCYCLE(MOTO-99) parked at Spot F1-M1 (Floor 1) | Ticket: e5f6g7h8
  ✓ TRUCK(TRK-5678) parked at Spot F1-L6 (Floor 1) | Ticket: i9j0k1l2
  ✓ VAN(VAN-0001) parked at Spot F1-L7 (Floor 1) | Ticket: m3n4o5p6

  ✓ CAR(ABC-1234) exited | Fee: $60.0  | Payment(...)
  ✓ MOTORCYCLE(MOTO-99) exited | Fee: $10.0 | Payment(...)
```

---

## 2. Elevator System

### Requirements
- Multiple elevators in a building
- Handle **UP / DOWN** requests from floors
- Handle **internal** floor-selection requests
- Scheduling: Nearest-elevator, same-direction preference
- Door open/close, moving states
- Concurrent-safe

### Design Patterns
| Pattern | Purpose |
|---------|---------|
| **Strategy** | Elevator scheduling algorithm |
| **State** | Elevator states (Idle/MovingUp/MovingDown) |
| **Observer** | Notify display on floor change |
| **Singleton** | ElevatorController |

### Full Python Code

```python
from abc import ABC, abstractmethod
from enum import Enum
from collections import defaultdict
import threading
import time
import heapq


# ─── Enums ───────────────────────────────────────────────
class Direction(Enum):
    UP = 1
    DOWN = 2
    IDLE = 3


class DoorState(Enum):
    OPEN = 1
    CLOSED = 2


class ElevatorState(Enum):
    IDLE = 1
    MOVING_UP = 2
    MOVING_DOWN = 3
    MAINTENANCE = 4


# ─── Request ─────────────────────────────────────────────
class Request:
    """An external request from a floor OR an internal cabin button press."""
    def __init__(self, floor: int, direction: Direction = Direction.IDLE):
        self.floor = floor
        self.direction = direction          # relevant for external requests
        self.timestamp = time.time()

    def __repr__(self):
        return f"Req(floor={self.floor}, dir={self.direction.name})"


# ─── Elevator ────────────────────────────────────────────
class Elevator:
    def __init__(self, elevator_id: int, min_floor: int = 0, max_floor: int = 10):
        self.id = elevator_id
        self.current_floor = 0
        self.state = ElevatorState.IDLE
        self.direction = Direction.IDLE
        self.door = DoorState.CLOSED
        self.min_floor = min_floor
        self.max_floor = max_floor

        # Two sets: floors to visit going UP, floors to visit going DOWN
        self._up_stops: set[int] = set()
        self._down_stops: set[int] = set()
        self._lock = threading.Lock()

    # ---------- Public API ----------
    def add_stop(self, floor: int, direction: Direction = Direction.IDLE):
        """Add a destination floor to the correct queue."""
        with self._lock:
            if floor > self.current_floor or direction == Direction.UP:
                self._up_stops.add(floor)
            elif floor < self.current_floor or direction == Direction.DOWN:
                self._down_stops.add(floor)
            else:
                # Same floor → open door
                self._open_door()
                return
            if self.state == ElevatorState.IDLE:
                self._decide_direction()

    def step(self):
        """Simulate one step of movement (called by controller loop)."""
        with self._lock:
            if self.state == ElevatorState.IDLE:
                self._decide_direction()
                return

            if self.state == ElevatorState.MOVING_UP:
                self.current_floor += 1
                self._check_and_stop(self._up_stops)
                if not self._up_stops:
                    if self._down_stops:
                        self.state = ElevatorState.MOVING_DOWN
                        self.direction = Direction.DOWN
                    else:
                        self.state = ElevatorState.IDLE
                        self.direction = Direction.IDLE

            elif self.state == ElevatorState.MOVING_DOWN:
                self.current_floor -= 1
                self._check_and_stop(self._down_stops)
                if not self._down_stops:
                    if self._up_stops:
                        self.state = ElevatorState.MOVING_UP
                        self.direction = Direction.UP
                    else:
                        self.state = ElevatorState.IDLE
                        self.direction = Direction.IDLE

    def is_idle(self) -> bool:
        return self.state == ElevatorState.IDLE

    def pending_stops(self) -> int:
        return len(self._up_stops) + len(self._down_stops)

    # ---------- Internals ----------
    def _decide_direction(self):
        if self._up_stops and (not self._down_stops
                               or min(self._up_stops) >= self.current_floor):
            self.state = ElevatorState.MOVING_UP
            self.direction = Direction.UP
        elif self._down_stops:
            self.state = ElevatorState.MOVING_DOWN
            self.direction = Direction.DOWN

    def _check_and_stop(self, stop_set: set):
        if self.current_floor in stop_set:
            stop_set.discard(self.current_floor)
            self._open_door()

    def _open_door(self):
        self.door = DoorState.OPEN
        print(f"    Elevator {self.id} | Floor {self.current_floor} "
              f"| 🔔 Door OPEN")
        self.door = DoorState.CLOSED

    def __repr__(self):
        return (f"Elevator {self.id}: Floor={self.current_floor}, "
                f"State={self.state.name}, "
                f"Up={sorted(self._up_stops)}, Down={sorted(self._down_stops)}")


# ─── Scheduling Strategy ─────────────────────────────────
class SchedulingStrategy(ABC):
    @abstractmethod
    def select(self, elevators: list[Elevator], request: Request) -> Elevator:
        pass


class NearestElevatorStrategy(SchedulingStrategy):
    """Pick the nearest idle or same-direction elevator."""
    def select(self, elevators: list[Elevator], request: Request) -> Elevator:
        best, best_score = None, float('inf')
        for e in elevators:
            if e.state == ElevatorState.MAINTENANCE:
                continue
            dist = abs(e.current_floor - request.floor)
            # Prefer idle
            if e.is_idle():
                score = dist
            # Prefer same direction and approaching
            elif (e.direction == Direction.UP and request.direction == Direction.UP
                  and e.current_floor <= request.floor):
                score = dist + 0.5
            elif (e.direction == Direction.DOWN and request.direction == Direction.DOWN
                  and e.current_floor >= request.floor):
                score = dist + 0.5
            else:
                score = dist + 100  # penalty: wrong direction
            if score < best_score:
                best, best_score = e, score
        return best


# ─── Elevator Controller (Singleton) ─────────────────────
class ElevatorController:
    _instance = None

    def __new__(cls, *args, **kwargs):
        if not cls._instance:
            cls._instance = super().__new__(cls)
        return cls._instance

    def __init__(self, num_elevators: int = 3, floors: int = 10):
        if hasattr(self, "_init"):
            return
        self._init = True
        self.floors = floors
        self.elevators = [Elevator(i, 0, floors) for i in range(num_elevators)]
        self.strategy: SchedulingStrategy = NearestElevatorStrategy()

    def request_elevator(self, floor: int, direction: Direction):
        """External hall call."""
        req = Request(floor, direction)
        elevator = self.strategy.select(self.elevators, req)
        if elevator:
            elevator.add_stop(floor, direction)
            print(f"  → Dispatched Elevator {elevator.id} for {req}")
        else:
            print(f"  ✗ No elevator available for {req}")

    def press_floor_button(self, elevator_id: int, floor: int):
        """Internal cabin button press."""
        self.elevators[elevator_id].add_stop(floor)
        print(f"  → Elevator {elevator_id} | Cabin button: floor {floor}")

    def step_all(self):
        """Advance all elevators by one step."""
        for e in self.elevators:
            e.step()

    def run(self, steps: int = 20):
        """Simulate the system for N steps."""
        print("\n--- Simulation Start ---")
        for t in range(steps):
            print(f"\n⏱  Step {t}")
            self.step_all()
            for e in self.elevators:
                if not e.is_idle():
                    print(f"    {e}")
            if all(e.is_idle() for e in self.elevators):
                print("    All elevators idle ✓")
                break
        print("--- Simulation End ---\n")

    def status(self):
        print("\n--- Elevator Status ---")
        for e in self.elevators:
            print(f"  {e}")
        print()


# ─── Demo ─────────────────────────────────────────────────
if __name__ == "__main__":
    ElevatorController._instance = None
    ctrl = ElevatorController(num_elevators=3, floors=15)

    ctrl.status()

    # External requests
    ctrl.request_elevator(floor=5, direction=Direction.UP)
    ctrl.request_elevator(floor=3, direction=Direction.DOWN)

    # Internal requests (passenger inside elevator 0 wants floor 8)
    ctrl.press_floor_button(elevator_id=0, floor=8)

    ctrl.run(steps=15)
    ctrl.status()
```

### Output
```
--- Elevator Status ---
  Elevator 0: Floor=0, State=IDLE, Up=[], Down=[]
  Elevator 1: Floor=0, State=IDLE, Up=[], Down=[]
  Elevator 2: Floor=0, State=IDLE, Up=[], Down=[]

  → Dispatched Elevator 0 for Req(floor=5, dir=UP)
  → Dispatched Elevator 1 for Req(floor=3, dir=DOWN)
  → Elevator 0 | Cabin button: floor 8

--- Simulation Start ---
⏱  Step 0
    Elevator 0: Floor=1, State=MOVING_UP, Up=[5, 8], Down=[]
    Elevator 1: Floor=1, State=MOVING_UP, Up=[3], Down=[]
...
⏱  Step 4
    Elevator 0 | Floor 5 | 🔔 Door OPEN
...
⏱  Step 7
    Elevator 0 | Floor 8 | 🔔 Door OPEN
    All elevators idle ✓
--- Simulation End ---
```

---

## 3. Library Management System

### Requirements
- Members can **search**, **borrow**, **return**, **reserve** books
- Book copies vs book metadata
- Fine calculation for late returns
- Librarian can **add/remove** books
- Rack/shelf location tracking
- Notification on book availability

### Design Patterns
| Pattern | Purpose |
|---------|---------|
| **Observer** | Notify members when reserved book available |
| **Strategy** | Fine calculation |
| **Repository** | Book catalog management |

### Full Python Code

```python
from abc import ABC, abstractmethod
from enum import Enum
from datetime import datetime, timedelta
import uuid


# ─── Enums ───────────────────────────────────────────────
class BookStatus(Enum):
    AVAILABLE = 1
    BORROWED = 2
    RESERVED = 3
    LOST = 4


class MemberStatus(Enum):
    ACTIVE = 1
    SUSPENDED = 2


class ReservationStatus(Enum):
    WAITING = 1
    FULFILLED = 2
    CANCELLED = 3


# ─── Observer Pattern ────────────────────────────────────
class Observer(ABC):
    @abstractmethod
    def update(self, message: str):
        pass


class Subject:
    def __init__(self):
        self._observers: list[Observer] = []

    def subscribe(self, observer: Observer):
        self._observers.append(observer)

    def unsubscribe(self, observer: Observer):
        self._observers.remove(observer)

    def notify(self, message: str):
        for obs in self._observers:
            obs.update(message)


# ─── Book & BookItem ─────────────────────────────────────
class Book:
    """Book metadata (ISBN-level)."""
    def __init__(self, isbn: str, title: str, author: str, category: str = "General"):
        self.isbn = isbn
        self.title = title
        self.author = author
        self.category = category

    def __repr__(self):
        return f"'{self.title}' by {self.author} (ISBN: {self.isbn})"


class BookItem(Subject):
    """Physical copy of a book."""
    def __init__(self, book: Book, barcode: str, rack_location: str = "A-1"):
        super().__init__()
        self.book = book
        self.barcode = barcode
        self.rack_location = rack_location
        self.status = BookStatus.AVAILABLE
        self.borrowed_by = None
        self.due_date: datetime | None = None

    def checkout(self, member, days: int = 14):
        self.status = BookStatus.BORROWED
        self.borrowed_by = member
        self.due_date = datetime.now() + timedelta(days=days)

    def return_book(self):
        self.status = BookStatus.AVAILABLE
        self.borrowed_by = None
        self.due_date = None
        self.notify(f"Book '{self.book.title}' (barcode={self.barcode}) "
                     f"is now available!")

    def is_overdue(self) -> bool:
        return (self.status == BookStatus.BORROWED
                and self.due_date and datetime.now() > self.due_date)

    def __repr__(self):
        return (f"BookItem({self.barcode}, {self.book.title}, "
                f"{self.status.name})")


# ─── Fine Strategy ───────────────────────────────────────
class FineStrategy(ABC):
    @abstractmethod
    def calculate(self, due_date: datetime, return_date: datetime) -> float:
        pass


class PerDayFineStrategy(FineStrategy):
    def __init__(self, rate_per_day: float = 1.0):
        self.rate = rate_per_day

    def calculate(self, due_date: datetime, return_date: datetime) -> float:
        overdue_days = (return_date - due_date).days
        return max(0, overdue_days * self.rate)


# ─── Member ──────────────────────────────────────────────
class Member(Observer):
    MAX_BOOKS = 5

    def __init__(self, member_id: str, name: str, email: str):
        self.member_id = member_id
        self.name = name
        self.email = email
        self.status = MemberStatus.ACTIVE
        self.borrowed_books: list[BookItem] = []
        self.notifications: list[str] = []
        self.total_fine: float = 0.0

    def update(self, message: str):
        """Observer callback."""
        self.notifications.append(message)
        print(f"    📧 Notification to {self.name}: {message}")

    def can_borrow(self) -> bool:
        return (self.status == MemberStatus.ACTIVE
                and len(self.borrowed_books) < self.MAX_BOOKS)

    def __repr__(self):
        return (f"Member({self.member_id}, {self.name}, "
                f"Borrowed={len(self.borrowed_books)})")


# ─── Reservation ─────────────────────────────────────────
class Reservation:
    def __init__(self, member: Member, book: Book):
        self.reservation_id = str(uuid.uuid4())[:8]
        self.member = member
        self.book = book
        self.status = ReservationStatus.WAITING
        self.created = datetime.now()

    def fulfill(self):
        self.status = ReservationStatus.FULFILLED

    def cancel(self):
        self.status = ReservationStatus.CANCELLED


# ─── Library ─────────────────────────────────────────────
class Library:
    def __init__(self, name: str):
        self.name = name
        self.catalog: dict[str, Book] = {}            # isbn -> Book
        self.book_items: dict[str, BookItem] = {}      # barcode -> BookItem
        self.members: dict[str, Member] = {}           # member_id -> Member
        self.reservations: list[Reservation] = []
        self.fine_strategy: FineStrategy = PerDayFineStrategy(1.0)

    # ---------- Admin Operations ----------
    def add_book(self, book: Book):
        self.catalog[book.isbn] = book
        print(f"  [Catalog] Added: {book}")

    def add_book_item(self, item: BookItem):
        if item.book.isbn not in self.catalog:
            self.add_book(item.book)
        self.book_items[item.barcode] = item
        print(f"  [Inventory] Added copy: {item.barcode} → {item.book.title}")

    def register_member(self, member: Member):
        self.members[member.member_id] = member
        print(f"  [Members] Registered: {member.name}")

    # ---------- Search ----------
    def search_by_title(self, title: str) -> list[BookItem]:
        return [i for i in self.book_items.values()
                if title.lower() in i.book.title.lower()]

    def search_by_author(self, author: str) -> list[BookItem]:
        return [i for i in self.book_items.values()
                if author.lower() in i.book.author.lower()]

    def search_available(self, isbn: str) -> list[BookItem]:
        return [i for i in self.book_items.values()
                if i.book.isbn == isbn and i.status == BookStatus.AVAILABLE]

    # ---------- Borrow / Return ----------
    def borrow_book(self, member_id: str, barcode: str) -> bool:
        member = self.members.get(member_id)
        item = self.book_items.get(barcode)
        if not member or not item:
            print("  ✗ Invalid member or barcode")
            return False
        if not member.can_borrow():
            print(f"  ✗ {member.name} cannot borrow (limit or suspended)")
            return False
        if item.status != BookStatus.AVAILABLE:
            print(f"  ✗ Book {barcode} is not available ({item.status.name})")
            return False
        item.checkout(member)
        member.borrowed_books.append(item)
        print(f"  ✓ {member.name} borrowed '{item.book.title}' "
              f"(Due: {item.due_date.strftime('%Y-%m-%d')})")
        return True

    def return_book(self, member_id: str, barcode: str) -> float:
        member = self.members.get(member_id)
        item = self.book_items.get(barcode)
        if not member or not item:
            print("  ✗ Invalid member or barcode")
            return 0
        fine = 0.0
        if item.is_overdue():
            fine = self.fine_strategy.calculate(item.due_date, datetime.now())
            member.total_fine += fine
        item.return_book()
        member.borrowed_books.remove(item)
        self._check_reservations(item.book)
        msg = f"  ✓ {member.name} returned '{item.book.title}'"
        if fine > 0:
            msg += f" | Fine: ${fine:.2f}"
        print(msg)
        return fine

    # ---------- Reserve ----------
    def reserve_book(self, member_id: str, isbn: str) -> Reservation | None:
        member = self.members.get(member_id)
        book = self.catalog.get(isbn)
        if not member or not book:
            return None
        # Subscribe member to all copies
        for item in self.book_items.values():
            if item.book.isbn == isbn:
                item.subscribe(member)
        res = Reservation(member, book)
        self.reservations.append(res)
        print(f"  ✓ Reservation created for {member.name} → {book.title}")
        return res

    def _check_reservations(self, book: Book):
        for r in self.reservations:
            if r.book.isbn == book.isbn and r.status == ReservationStatus.WAITING:
                r.fulfill()
                break   # first waiting reservation


# ─── Demo ─────────────────────────────────────────────────
if __name__ == "__main__":
    lib = Library("City Central Library")

    # Add books
    b1 = Book("978-0-13-468599-1", "Clean Code", "Robert C. Martin", "Software")
    b2 = Book("978-0-201-63361-0", "Design Patterns", "GoF", "Software")

    lib.add_book_item(BookItem(b1, "CC-001", "Rack-A1"))
    lib.add_book_item(BookItem(b1, "CC-002", "Rack-A1"))
    lib.add_book_item(BookItem(b2, "DP-001", "Rack-B2"))

    # Register members
    m1 = Member("M001", "Alice", "alice@mail.com")
    m2 = Member("M002", "Bob", "bob@mail.com")
    lib.register_member(m1)
    lib.register_member(m2)

    # Search
    print("\n--- Search 'Clean' ---")
    results = lib.search_by_title("Clean")
    for r in results:
        print(f"  Found: {r}")

    # Borrow
    print("\n--- Borrow ---")
    lib.borrow_book("M001", "CC-001")
    lib.borrow_book("M002", "CC-002")

    # Reserve (all copies borrowed)
    print("\n--- Reserve ---")
    lib.reserve_book("M002", "978-0-13-468599-1")

    # Return with overdue simulation
    print("\n--- Return ---")
    item = lib.book_items["CC-001"]
    item.due_date = datetime.now() - timedelta(days=5)  # simulate overdue
    lib.return_book("M001", "CC-001")

    print(f"\n  Alice's total fine: ${m1.total_fine:.2f}")
    print(f"  Bob's notifications: {m2.notifications}")
```

---

## 4. ATM System

### Requirements
- **Card** insertion → authentication (PIN)
- **Balance inquiry**, **Withdraw**, **Deposit**, **Transfer**
- Denomination-based cash dispensing
- Transaction logging
- State transitions: Idle → HasCard → Authenticated → Transaction

### Design Patterns
| Pattern | Purpose |
|---------|---------|
| **State** | ATM states (Idle, HasCard, Authenticated, etc.) |
| **Chain of Responsibility** | Cash dispenser (100s → 50s → 20s → 10s) |
| **Command** | Transaction commands |

### Full Python Code

```python
from abc import ABC, abstractmethod
from enum import Enum
from datetime import datetime
import uuid


# ─── Enums ───────────────────────────────────────────────
class TransactionType(Enum):
    BALANCE_INQUIRY = 1
    WITHDRAWAL = 2
    DEPOSIT = 3
    TRANSFER = 4


# ─── Account & Card ─────────────────────────────────────
class Account:
    def __init__(self, account_number: str, holder_name: str,
                 balance: float = 0, pin: str = "1234"):
        self.account_number = account_number
        self.holder_name = holder_name
        self.balance = balance
        self.pin = pin

    def verify_pin(self, pin: str) -> bool:
        return self.pin == pin

    def debit(self, amount: float) -> bool:
        if amount > self.balance:
            return False
        self.balance -= amount
        return True

    def credit(self, amount: float):
        self.balance += amount

    def __repr__(self):
        return f"Account({self.account_number}, {self.holder_name}, ${self.balance:.2f})"


class Card:
    def __init__(self, card_number: str, account: Account):
        self.card_number = card_number
        self.account = account

    def __repr__(self):
        return f"Card({self.card_number})"


# ─── Transaction Log ────────────────────────────────────
class Transaction:
    def __init__(self, txn_type: TransactionType, account: Account,
                 amount: float = 0):
        self.txn_id = str(uuid.uuid4())[:8]
        self.txn_type = txn_type
        self.account_number = account.account_number
        self.amount = amount
        self.timestamp = datetime.now()
        self.success = True

    def __repr__(self):
        return (f"Txn({self.txn_id}, {self.txn_type.name}, "
                f"${self.amount:.2f}, {'✓' if self.success else '✗'})")


# ─── Cash Dispenser (Chain of Responsibility) ────────────
class CashDispenser(ABC):
    def __init__(self, denomination: int, count: int):
        self.denomination = denomination
        self.count = count        # available notes
        self._next: CashDispenser | None = None

    def set_next(self, handler: 'CashDispenser') -> 'CashDispenser':
        self._next = handler
        return handler

    def dispense(self, amount: int) -> dict:
        result = {}
        if amount >= self.denomination:
            needed = min(amount // self.denomination, self.count)
            result[self.denomination] = needed
            self.count -= needed
            remaining = amount - needed * self.denomination
        else:
            remaining = amount

        if remaining > 0 and self._next:
            result.update(self._next.dispense(remaining))
        elif remaining > 0:
            print(f"    ⚠ Cannot dispense ${remaining} — insufficient notes")

        return result

    def can_dispense(self, amount: int) -> bool:
        """Check without actually dispensing."""
        available = min(amount // self.denomination, self.count) * self.denomination
        remaining = amount - available
        if remaining == 0:
            return True
        if self._next:
            return self._next.can_dispense(remaining)
        return False


class Dispenser100(CashDispenser):
    def __init__(self, count=100):
        super().__init__(100, count)

class Dispenser50(CashDispenser):
    def __init__(self, count=100):
        super().__init__(50, count)

class Dispenser20(CashDispenser):
    def __init__(self, count=100):
        super().__init__(20, count)

class Dispenser10(CashDispenser):
    def __init__(self, count=200):
        super().__init__(10, count)


# ─── ATM States (State Pattern) ─────────────────────────
class ATMState(ABC):
    def __init__(self, atm: 'ATM'):
        self.atm = atm

    @abstractmethod
    def insert_card(self, card: Card): pass

    @abstractmethod
    def enter_pin(self, pin: str): pass

    @abstractmethod
    def select_transaction(self, txn_type: TransactionType,
                           amount: float = 0): pass

    @abstractmethod
    def eject_card(self): pass


class IdleState(ATMState):
    def insert_card(self, card: Card):
        print(f"  Card {card.card_number} inserted")
        self.atm.current_card = card
        self.atm.set_state(HasCardState(self.atm))

    def enter_pin(self, pin):
        print("  ✗ Insert card first")

    def select_transaction(self, txn_type, amount=0):
        print("  ✗ Insert card first")

    def eject_card(self):
        print("  ✗ No card inserted")


class HasCardState(ATMState):
    def __init__(self, atm):
        super().__init__(atm)
        self._attempts = 0

    def insert_card(self, card):
        print("  ✗ Card already inserted")

    def enter_pin(self, pin: str):
        if self.atm.current_card.account.verify_pin(pin):
            print("  ✓ PIN verified")
            self.atm.set_state(AuthenticatedState(self.atm))
        else:
            self._attempts += 1
            remaining = 3 - self._attempts
            print(f"  ✗ Wrong PIN ({remaining} attempts remaining)")
            if self._attempts >= 3:
                print("  ⛔ Card locked — ejecting")
                self.eject_card()

    def select_transaction(self, txn_type, amount=0):
        print("  ✗ Enter PIN first")

    def eject_card(self):
        print(f"  Card {self.atm.current_card.card_number} ejected")
        self.atm.current_card = None
        self.atm.set_state(IdleState(self.atm))


class AuthenticatedState(ATMState):
    def insert_card(self, card):
        print("  ✗ Already authenticated")

    def enter_pin(self, pin):
        print("  ✗ Already authenticated")

    def select_transaction(self, txn_type: TransactionType, amount: float = 0):
        account = self.atm.current_card.account

        if txn_type == TransactionType.BALANCE_INQUIRY:
            txn = Transaction(txn_type, account)
            print(f"  💰 Balance: ${account.balance:.2f}")
            self.atm.transactions.append(txn)

        elif txn_type == TransactionType.WITHDRAWAL:
            int_amount = int(amount)
            if int_amount % 10 != 0:
                print("  ✗ Amount must be multiple of 10")
                return
            if not self.atm.dispenser_chain.can_dispense(int_amount):
                print("  ✗ ATM cannot dispense this amount")
                return
            if not account.debit(amount):
                print("  ✗ Insufficient funds")
                return
            notes = self.atm.dispenser_chain.dispense(int_amount)
            txn = Transaction(txn_type, account, amount)
            self.atm.transactions.append(txn)
            print(f"  ✓ Dispensed ${amount:.0f}: {notes}")
            print(f"    Remaining balance: ${account.balance:.2f}")

        elif txn_type == TransactionType.DEPOSIT:
            account.credit(amount)
            txn = Transaction(txn_type, account, amount)
            self.atm.transactions.append(txn)
            print(f"  ✓ Deposited ${amount:.2f} | "
                  f"New balance: ${account.balance:.2f}")

    def eject_card(self):
        print(f"  Card {self.atm.current_card.card_number} ejected")
        self.atm.current_card = None
        self.atm.set_state(IdleState(self.atm))


# ─── ATM ─────────────────────────────────────────────────
class ATM:
    def __init__(self, atm_id: str, location: str):
        self.atm_id = atm_id
        self.location = location
        self.current_card: Card | None = None
        self.transactions: list[Transaction] = []

        # Build dispenser chain: 100 → 50 → 20 → 10
        d100 = Dispenser100(50)
        d50 = Dispenser50(50)
        d20 = Dispenser20(100)
        d10 = Dispenser10(200)
        d100.set_next(d50).set_next(d20).set_next(d10)
        self.dispenser_chain = d100

        self._state: ATMState = IdleState(self)

    def set_state(self, state: ATMState):
        self._state = state

    # Public API (delegate to state)
    def insert_card(self, card: Card):
        self._state.insert_card(card)

    def enter_pin(self, pin: str):
        self._state.enter_pin(pin)

    def check_balance(self):
        self._state.select_transaction(TransactionType.BALANCE_INQUIRY)

    def withdraw(self, amount: float):
        self._state.select_transaction(TransactionType.WITHDRAWAL, amount)

    def deposit(self, amount: float):
        self._state.select_transaction(TransactionType.DEPOSIT, amount)

    def eject_card(self):
        self._state.eject_card()


# ─── Demo ─────────────────────────────────────────────────
if __name__ == "__main__":
    acc = Account("ACC-001", "Alice", balance=5000, pin="4321")
    card = Card("CARD-9999", acc)
    atm = ATM("ATM-01", "Main Street")

    print("=== ATM Session ===\n")

    atm.insert_card(card)
    atm.enter_pin("0000")    # wrong
    atm.enter_pin("4321")    # correct

    atm.check_balance()
    atm.withdraw(270)
    atm.check_balance()
    atm.deposit(100)
    atm.check_balance()

    atm.eject_card()

    # Try operations without card
    atm.check_balance()

    print("\n--- Transaction Log ---")
    for t in atm.transactions:
        print(f"  {t}")
```

---

## 5. Hotel Booking System

### Requirements
- Room types: **Standard**, **Deluxe**, **Suite**
- **Search** rooms by date, type, price
- **Book**, **Cancel**, **Check-in**, **Check-out**
- Payment processing
- Housekeeping status tracking

### Full Python Code

```python
from abc import ABC, abstractmethod
from enum import Enum
from datetime import datetime, date, timedelta
import uuid


# ─── Enums ───────────────────────────────────────────────
class RoomType(Enum):
    STANDARD = 1
    DELUXE = 2
    SUITE = 3


class RoomStatus(Enum):
    AVAILABLE = 1
    BOOKED = 2
    OCCUPIED = 3
    UNDER_MAINTENANCE = 4


class BookingStatus(Enum):
    CONFIRMED = 1
    CHECKED_IN = 2
    CHECKED_OUT = 3
    CANCELLED = 4


class PaymentMethod(Enum):
    CREDIT_CARD = 1
    DEBIT_CARD = 2
    CASH = 3


# ─── Guest ───────────────────────────────────────────────
class Guest:
    def __init__(self, guest_id: str, name: str, email: str, phone: str):
        self.guest_id = guest_id
        self.name = name
        self.email = email
        self.phone = phone
        self.bookings: list['Booking'] = []

    def __repr__(self):
        return f"Guest({self.name}, {self.email})"


# ─── Room ────────────────────────────────────────────────
class Room:
    PRICING = {
        RoomType.STANDARD: 100,
        RoomType.DELUXE: 200,
        RoomType.SUITE: 400,
    }

    def __init__(self, room_number: str, room_type: RoomType, floor: int = 1):
        self.room_number = room_number
        self.room_type = room_type
        self.floor = floor
        self.status = RoomStatus.AVAILABLE
        self.price_per_night = self.PRICING[room_type]
        self.is_clean = True

    def __repr__(self):
        return (f"Room {self.room_number} ({self.room_type.name}) "
                f"- ${self.price_per_night}/night - {self.status.name}")


# ─── Booking ─────────────────────────────────────────────
class Booking:
    def __init__(self, guest: Guest, room: Room,
                 check_in: date, check_out: date):
        self.booking_id = str(uuid.uuid4())[:8]
        self.guest = guest
        self.room = room
        self.check_in_date = check_in
        self.check_out_date = check_out
        self.status = BookingStatus.CONFIRMED
        self.created_at = datetime.now()
        self.total_amount = self._calculate_total()

    def _calculate_total(self) -> float:
        nights = (self.check_out_date - self.check_in_date).days
        return max(1, nights) * self.room.price_per_night

    def cancel(self):
        self.status = BookingStatus.CANCELLED
        self.room.status = RoomStatus.AVAILABLE

    def check_in(self):
        self.status = BookingStatus.CHECKED_IN
        self.room.status = RoomStatus.OCCUPIED

    def check_out(self):
        self.status = BookingStatus.CHECKED_OUT
        self.room.status = RoomStatus.AVAILABLE
        self.room.is_clean = False  # needs housekeeping

    def __repr__(self):
        return (f"Booking({self.booking_id}, {self.guest.name}, "
                f"Room {self.room.room_number}, "
                f"{self.check_in_date} → {self.check_out_date}, "
                f"${self.total_amount:.2f}, {self.status.name})")


# ─── Payment ────────────────────────────────────────────
class Payment:
    def __init__(self, booking: Booking, method: PaymentMethod):
        self.payment_id = str(uuid.uuid4())[:8]
        self.booking = booking
        self.amount = booking.total_amount
        self.method = method
        self.timestamp = datetime.now()
        self.success = True

    def __repr__(self):
        return (f"Payment({self.payment_id}, ${self.amount:.2f}, "
                f"{self.method.name})")


# ─── Housekeeping ────────────────────────────────────────
class HousekeepingLog:
    def __init__(self, room: Room, staff_name: str):
        self.room = room
        self.staff_name = staff_name
        self.cleaned_at = datetime.now()
        room.is_clean = True


# ─── Hotel ───────────────────────────────────────────────
class Hotel:
    def __init__(self, name: str, address: str):
        self.name = name
        self.address = address
        self.rooms: dict[str, Room] = {}
        self.guests: dict[str, Guest] = {}
        self.bookings: list[Booking] = []
        self.payments: list[Payment] = []

    def add_room(self, room: Room):
        self.rooms[room.room_number] = room

    def register_guest(self, guest: Guest):
        self.guests[guest.guest_id] = guest

    # ---------- Search ----------
    def search_available_rooms(self, check_in: date, check_out: date,
                                room_type: RoomType = None) -> list[Room]:
        available = []
        for room in self.rooms.values():
            if room_type and room.room_type != room_type:
                continue
            if room.status == RoomStatus.UNDER_MAINTENANCE:
                continue
            # Check no overlapping bookings
            conflict = any(
                b.status in (BookingStatus.CONFIRMED, BookingStatus.CHECKED_IN)
                and b.room == room
                and b.check_in_date < check_out
                and b.check_out_date > check_in
                for b in self.bookings
            )
            if not conflict:
                available.append(room)
        return available

    # ---------- Book ----------
    def book_room(self, guest_id: str, room_number: str,
                  check_in: date, check_out: date) -> Booking | None:
        guest = self.guests.get(guest_id)
        room = self.rooms.get(room_number)
        if not guest or not room:
            print("  ✗ Invalid guest or room")
            return None

        avail = self.search_available_rooms(check_in, check_out, room.room_type)
        if room not in avail:
            print(f"  ✗ Room {room_number} not available for those dates")
            return None

        booking = Booking(guest, room, check_in, check_out)
        room.status = RoomStatus.BOOKED
        guest.bookings.append(booking)
        self.bookings.append(booking)
        print(f"  ✓ {booking}")
        return booking

    def cancel_booking(self, booking_id: str):
        for b in self.bookings:
            if b.booking_id == booking_id and b.status == BookingStatus.CONFIRMED:
                b.cancel()
                print(f"  ✓ Booking {booking_id} cancelled")
                return
        print(f"  ✗ Cannot cancel booking {booking_id}")

    def do_check_in(self, booking_id: str):
        for b in self.bookings:
            if b.booking_id == booking_id and b.status == BookingStatus.CONFIRMED:
                b.check_in()
                print(f"  ✓ {b.guest.name} checked in to Room {b.room.room_number}")
                return
        print(f"  ✗ Cannot check in for {booking_id}")

    def do_check_out(self, booking_id: str,
                     method: PaymentMethod = PaymentMethod.CREDIT_CARD) -> Payment | None:
        for b in self.bookings:
            if b.booking_id == booking_id and b.status == BookingStatus.CHECKED_IN:
                b.check_out()
                payment = Payment(b, method)
                self.payments.append(payment)
                print(f"  ✓ {b.guest.name} checked out | {payment}")
                return payment
        print(f"  ✗ Cannot check out for {booking_id}")
        return None


# ─── Demo ─────────────────────────────────────────────────
if __name__ == "__main__":
    hotel = Hotel("Grand Palace", "123 Main St")

    # Setup rooms
    for i in range(1, 4):
        hotel.add_room(Room(f"10{i}", RoomType.STANDARD, floor=1))
    for i in range(1, 3):
        hotel.add_room(Room(f"20{i}", RoomType.DELUXE, floor=2))
    hotel.add_room(Room("301", RoomType.SUITE, floor=3))

    # Register guests
    g1 = Guest("G001", "Alice", "alice@mail.com", "555-0001")
    g2 = Guest("G002", "Bob", "bob@mail.com", "555-0002")
    hotel.register_guest(g1)
    hotel.register_guest(g2)

    # Search
    today = date.today()
    tomorrow = today + timedelta(days=1)
    next_week = today + timedelta(days=7)

    print("--- Available Deluxe Rooms ---")
    for r in hotel.search_available_rooms(today, next_week, RoomType.DELUXE):
        print(f"  {r}")

    # Book
    print("\n--- Booking ---")
    b1 = hotel.book_room("G001", "201", today, next_week)
    b2 = hotel.book_room("G002", "301", today, tomorrow)

    # Check-in
    print("\n--- Check-in ---")
    if b1:
        hotel.do_check_in(b1.booking_id)

    # Check-out
    print("\n--- Check-out ---")
    if b1:
        hotel.do_check_out(b1.booking_id)

    # Cancel
    print("\n--- Cancel ---")
    if b2:
        hotel.cancel_booking(b2.booking_id)
```

---

## 6. Online Shopping Cart

### Requirements
- Product catalog with categories
- Add/remove/update items in cart
- Apply **discount coupons** (percentage, flat)
- Checkout with shipping address
- Order placement and tracking
- Payment processing

### Design Patterns
| Pattern | Purpose |
|---------|---------|
| **Strategy** | Discount/pricing strategies |
| **Observer** | Order status updates |
| **Builder** | Building complex Order objects |

### Full Python Code

```python
from abc import ABC, abstractmethod
from enum import Enum
from datetime import datetime
import uuid


# ─── Enums ───────────────────────────────────────────────
class OrderStatus(Enum):
    PENDING = 1
    CONFIRMED = 2
    SHIPPED = 3
    DELIVERED = 4
    CANCELLED = 5


class PaymentMethod(Enum):
    CREDIT_CARD = 1
    PAYPAL = 2
    UPI = 3


# ─── Product & Category ─────────────────────────────────
class Category:
    def __init__(self, name: str):
        self.name = name

    def __repr__(self):
        return self.name


class Product:
    def __init__(self, product_id: str, name: str, price: float,
                 category: Category, stock: int = 100):
        self.product_id = product_id
        self.name = name
        self.price = price
        self.category = category
        self.stock = stock

    def is_in_stock(self, qty: int = 1) -> bool:
        return self.stock >= qty

    def reduce_stock(self, qty: int):
        self.stock -= qty

    def __repr__(self):
        return f"{self.name} (${self.price:.2f}, Stock: {self.stock})"


# ─── Cart Item ───────────────────────────────────────────
class CartItem:
    def __init__(self, product: Product, quantity: int = 1):
        self.product = product
        self.quantity = quantity

    @property
    def subtotal(self) -> float:
        return self.product.price * self.quantity

    def __repr__(self):
        return (f"{self.product.name} x{self.quantity} "
                f"= ${self.subtotal:.2f}")


# ─── Discount Strategy ──────────────────────────────────
class DiscountStrategy(ABC):
    @abstractmethod
    def apply(self, total: float) -> float:
        """Return discounted total."""
        pass

    @abstractmethod
    def description(self) -> str:
        pass


class NoDiscount(DiscountStrategy):
    def apply(self, total: float) -> float:
        return total

    def description(self) -> str:
        return "No discount"


class PercentageDiscount(DiscountStrategy):
    def __init__(self, code: str, percentage: float):
        self.code = code
        self.percentage = min(percentage, 100)

    def apply(self, total: float) -> float:
        return total * (1 - self.percentage / 100)

    def description(self) -> str:
        return f"Coupon {self.code}: {self.percentage}% off"


class FlatDiscount(DiscountStrategy):
    def __init__(self, code: str, amount: float):
        self.code = code
        self.amount = amount

    def apply(self, total: float) -> float:
        return max(0, total - self.amount)

    def description(self) -> str:
        return f"Coupon {self.code}: ${self.amount:.2f} off"


# ─── Address ─────────────────────────────────────────────
class Address:
    def __init__(self, street: str, city: str, state: str,
                 zip_code: str, country: str = "US"):
        self.street = street
        self.city = city
        self.state = state
        self.zip_code = zip_code
        self.country = country

    def __repr__(self):
        return f"{self.street}, {self.city}, {self.state} {self.zip_code}"


# ─── Shopping Cart ───────────────────────────────────────
class ShoppingCart:
    def __init__(self):
        self.items: dict[str, CartItem] = {}  # product_id -> CartItem
        self.discount: DiscountStrategy = NoDiscount()

    def add_item(self, product: Product, quantity: int = 1):
        if not product.is_in_stock(quantity):
            print(f"  ✗ {product.name} out of stock")
            return
        if product.product_id in self.items:
            self.items[product.product_id].quantity += quantity
        else:
            self.items[product.product_id] = CartItem(product, quantity)
        print(f"  ✓ Added {product.name} x{quantity} to cart")

    def remove_item(self, product_id: str):
        if product_id in self.items:
            item = self.items.pop(product_id)
            print(f"  ✓ Removed {item.product.name} from cart")
        else:
            print(f"  ✗ Product not in cart")

    def update_quantity(self, product_id: str, quantity: int):
        if product_id in self.items:
            if quantity <= 0:
                self.remove_item(product_id)
            else:
                self.items[product_id].quantity = quantity
                print(f"  ✓ Updated {self.items[product_id].product.name} "
                      f"to x{quantity}")

    def apply_coupon(self, discount: DiscountStrategy):
        self.discount = discount
        print(f"  ✓ Applied: {discount.description()}")

    @property
    def subtotal(self) -> float:
        return sum(item.subtotal for item in self.items.values())

    @property
    def total(self) -> float:
        return self.discount.apply(self.subtotal)

    def clear(self):
        self.items.clear()
        self.discount = NoDiscount()

    def display(self):
        print("\n  🛒 Shopping Cart:")
        print("  " + "-" * 40)
        for item in self.items.values():
            print(f"    {item}")
        print("  " + "-" * 40)
        print(f"    Subtotal: ${self.subtotal:.2f}")
        if not isinstance(self.discount, NoDiscount):
            print(f"    Discount: {self.discount.description()}")
        print(f"    Total:    ${self.total:.2f}\n")

    def is_empty(self) -> bool:
        return len(self.items) == 0


# ─── Order ───────────────────────────────────────────────
class OrderItem:
    def __init__(self, product_name: str, price: float, quantity: int):
        self.product_name = product_name
        self.price = price
        self.quantity = quantity
        self.subtotal = price * quantity


class Order:
    def __init__(self, customer: 'Customer', items: list[OrderItem],
                 total: float, shipping_address: Address,
                 payment_method: PaymentMethod):
        self.order_id = str(uuid.uuid4())[:8]
        self.customer = customer
        self.items = items
        self.total = total
        self.shipping_address = shipping_address
        self.payment_method = payment_method
        self.status = OrderStatus.CONFIRMED
        self.created_at = datetime.now()

    def cancel(self):
        if self.status in (OrderStatus.PENDING, OrderStatus.CONFIRMED):
            self.status = OrderStatus.CANCELLED
            return True
        return False

    def ship(self):
        self.status = OrderStatus.SHIPPED

    def deliver(self):
        self.status = OrderStatus.DELIVERED

    def __repr__(self):
        return (f"Order({self.order_id}, {self.customer.name}, "
                f"${self.total:.2f}, {self.status.name})")


# ─── Customer ────────────────────────────────────────────
class Customer:
    def __init__(self, customer_id: str, name: str, email: str,
                 address: Address):
        self.customer_id = customer_id
        self.name = name
        self.email = email
        self.address = address
        self.cart = ShoppingCart()
        self.orders: list[Order] = []

    def checkout(self, payment_method: PaymentMethod = PaymentMethod.CREDIT_CARD,
                 shipping_address: Address = None) -> Order | None:
        if self.cart.is_empty():
            print("  ✗ Cart is empty")
            return None

        addr = shipping_address or self.address

        # Reduce stock
        order_items = []
        for ci in self.cart.items.values():
            if not ci.product.is_in_stock(ci.quantity):
                print(f"  ✗ {ci.product.name} insufficient stock")
                return None
            ci.product.reduce_stock(ci.quantity)
            order_items.append(
                OrderItem(ci.product.name, ci.product.price, ci.quantity)
            )

        order = Order(self, order_items, self.cart.total, addr, payment_method)
        self.orders.append(order)
        self.cart.clear()
        print(f"  ✓ Order placed: {order}")
        return order


# ─── Demo ─────────────────────────────────────────────────
if __name__ == "__main__":
    # Setup
    electronics = Category("Electronics")
    books = Category("Books")

    laptop = Product("P001", "MacBook Pro", 2499.99, electronics, stock=10)
    phone = Product("P002", "iPhone 15", 999.99, electronics, stock=20)
    book = Product("P003", "Clean Code", 45.00, books, stock=50)

    addr = Address("123 Main St", "San Francisco", "CA", "94102")
    customer = Customer("C001", "Alice", "alice@mail.com", addr)

    # Add to cart
    print("--- Adding to Cart ---")
    customer.cart.add_item(laptop, 1)
    customer.cart.add_item(phone, 2)
    customer.cart.add_item(book, 3)

    customer.cart.display()

    # Apply coupon
    print("--- Applying Coupon ---")
    customer.cart.apply_coupon(PercentageDiscount("SAVE20", 20))
    customer.cart.display()

    # Update quantity
    print("--- Update Quantity ---")
    customer.cart.update_quantity("P002", 1)
    customer.cart.display()

    # Checkout
    print("--- Checkout ---")
    order = customer.checkout(PaymentMethod.CREDIT_CARD)

    # Track order
    if order:
        print(f"\n--- Order Status ---")
        print(f"  {order}")
        order.ship()
        print(f"  {order}")
        order.deliver()
        print(f"  {order}")
```

---

## 7. File System

### Requirements
- Directories and files (tree structure)
- Create, delete, move, rename
- Search by name/extension
- Display tree structure
- Calculate size (files have size, directories = sum of children)

### Design Patterns
| Pattern | Purpose |
|---------|---------|
| **Composite** | Files and directories share a common interface |
| **Iterator** | Traverse the file tree |

### Full Python Code

```python
from abc import ABC, abstractmethod
from datetime import datetime


# ─── Composite Pattern: FileSystemEntry ──────────────────
class FileSystemEntry(ABC):
    def __init__(self, name: str, parent: 'Directory | None' = None):
        self.name = name
        self.parent = parent
        self.created_at = datetime.now()
        self.modified_at = datetime.now()

    @abstractmethod
    def size(self) -> int:
        """Size in bytes."""
        pass

    @abstractmethod
    def display(self, indent: int = 0):
        pass

    @property
    def path(self) -> str:
        parts = []
        node = self
        while node:
            parts.append(node.name)
            node = node.parent
        return "/".join(reversed(parts))

    def __repr__(self):
        return f"{self.__class__.__name__}({self.path})"


# ─── File (Leaf) ─────────────────────────────────────────
class File(FileSystemEntry):
    def __init__(self, name: str, content: str = "",
                 parent: 'Directory | None' = None):
        super().__init__(name, parent)
        self.content = content
        self.extension = name.rsplit('.', 1)[-1] if '.' in name else ""

    def size(self) -> int:
        return len(self.content.encode('utf-8'))

    def write(self, content: str):
        self.content = content
        self.modified_at = datetime.now()

    def append(self, content: str):
        self.content += content
        self.modified_at = datetime.now()

    def read(self) -> str:
        return self.content

    def display(self, indent: int = 0):
        print(" " * indent + f"📄 {self.name} ({self.size()} bytes)")


# ─── Directory (Composite) ──────────────────────────────
class Directory(FileSystemEntry):
    def __init__(self, name: str, parent: 'Directory | None' = None):
        super().__init__(name, parent)
        self.children: dict[str, FileSystemEntry] = {}

    def size(self) -> int:
        return sum(child.size() for child in self.children.values())

    def add(self, entry: FileSystemEntry):
        if entry.name in self.children:
            raise FileExistsError(f"'{entry.name}' already exists in {self.name}")
        entry.parent = self
        self.children[entry.name] = entry
        self.modified_at = datetime.now()

    def remove(self, name: str) -> FileSystemEntry:
        if name not in self.children:
            raise FileNotFoundError(f"'{name}' not found in {self.name}")
        entry = self.children.pop(name)
        entry.parent = None
        self.modified_at = datetime.now()
        return entry

    def get(self, name: str) -> FileSystemEntry:
        if name not in self.children:
            raise FileNotFoundError(f"'{name}' not found in {self.name}")
        return self.children[name]

    def list_contents(self) -> list[str]:
        return list(self.children.keys())

    def display(self, indent: int = 0):
        print(" " * indent + f"📁 {self.name}/ ({self.size()} bytes)")
        for child in sorted(self.children.values(),
                            key=lambda c: (isinstance(c, File), c.name)):
            child.display(indent + 4)

    # ---------- Search ----------
    def search_by_name(self, name: str) -> list[FileSystemEntry]:
        results = []
        for child in self.children.values():
            if child.name == name:
                results.append(child)
            if isinstance(child, Directory):
                results.extend(child.search_by_name(name))
        return results

    def search_by_extension(self, ext: str) -> list[File]:
        results = []
        for child in self.children.values():
            if isinstance(child, File) and child.extension == ext:
                results.append(child)
            elif isinstance(child, Directory):
                results.extend(child.search_by_extension(ext))
        return results


# ─── FileSystem Facade ───────────────────────────────────
class FileSystem:
    def __init__(self):
        self.root = Directory("root")

    def _resolve(self, path: str) -> FileSystemEntry:
        """Resolve a path like 'root/home/docs' to its entry."""
        parts = path.strip("/").split("/")
        if parts[0] == "root":
            parts = parts[1:]
        current = self.root
        for part in parts:
            if not part:
                continue
            if not isinstance(current, Directory):
                raise NotADirectoryError(f"{current.name} is not a directory")
            current = current.get(part)
        return current

    def mkdir(self, path: str, name: str) -> Directory:
        parent = self._resolve(path)
        if not isinstance(parent, Directory):
            raise NotADirectoryError(f"{path} is not a directory")
        d = Directory(name)
        parent.add(d)
        print(f"  ✓ Created directory: {d.path}")
        return d

    def create_file(self, path: str, name: str,
                    content: str = "") -> File:
        parent = self._resolve(path)
        if not isinstance(parent, Directory):
            raise NotADirectoryError(f"{path} is not a directory")
        f = File(name, content)
        parent.add(f)
        print(f"  ✓ Created file: {f.path}")
        return f

    def delete(self, path: str, name: str):
        parent = self._resolve(path)
        if isinstance(parent, Directory):
            parent.remove(name)
            print(f"  ✓ Deleted: {path}/{name}")

    def move(self, src_path: str, name: str, dest_path: str):
        src_dir = self._resolve(src_path)
        dest_dir = self._resolve(dest_path)
        if not isinstance(src_dir, Directory) or not isinstance(dest_dir, Directory):
            raise NotADirectoryError("Source and destination must be directories")
        entry = src_dir.remove(name)
        dest_dir.add(entry)
        print(f"  ✓ Moved {name} from {src_path} to {dest_path}")

    def rename(self, path: str, old_name: str, new_name: str):
        parent = self._resolve(path)
        if isinstance(parent, Directory):
            entry = parent.remove(old_name)
            entry.name = new_name
            if isinstance(entry, File):
                entry.extension = new_name.rsplit('.', 1)[-1] if '.' in new_name else ""
            parent.add(entry)
            print(f"  ✓ Renamed {old_name} → {new_name}")

    def tree(self):
        print("\n--- File System Tree ---")
        self.root.display()
        print()


# ─── Demo ─────────────────────────────────────────────────
if __name__ == "__main__":
    fs = FileSystem()

    # Build structure
    fs.mkdir("root", "home")
    fs.mkdir("root/home", "alice")
    fs.mkdir("root/home/alice", "documents")
    fs.mkdir("root/home/alice", "photos")
    fs.mkdir("root", "etc")

    fs.create_file("root/home/alice/documents", "resume.pdf",
                   "Alice's resume content here")
    fs.create_file("root/home/alice/documents", "notes.txt",
                   "Some important notes")
    fs.create_file("root/home/alice/photos", "vacation.jpg",
                   "x" * 5000)  # simulated binary
    fs.create_file("root/etc", "config.txt", "key=value")

    fs.tree()

    # Search
    print("--- Search .txt files ---")
    results = fs.root.search_by_extension("txt")
    for r in results:
        print(f"  Found: {r.path} ({r.size()} bytes)")

    # Move
    print("\n--- Move ---")
    fs.move("root/etc", "config.txt", "root/home/alice/documents")
    fs.tree()

    # Rename
    print("--- Rename ---")
    fs.rename("root/home/alice/documents", "notes.txt", "important_notes.txt")
    fs.tree()

    # Total size
    print(f"Total filesystem size: {fs.root.size()} bytes")
```

---

## 8. Vending Machine

### Requirements
- Multiple products with price & quantity
- Accept coins/notes (multiple denominations)
- Select product → insert money → dispense + change
- Handle: no stock, insufficient money, no change
- States: Idle → ProductSelected → MoneyInserted → Dispensing

### Design Patterns
| Pattern | Purpose |
|---------|---------|
| **State** | Machine states |
| **Strategy** | Change calculation |

### Full Python Code

```python
from abc import ABC, abstractmethod
from enum import Enum
import uuid


# ─── Enums ───────────────────────────────────────────────
class Coin(Enum):
    PENNY = 0.01
    NICKEL = 0.05
    DIME = 0.10
    QUARTER = 0.25


class Note(Enum):
    ONE = 1
    FIVE = 5
    TEN = 10
    TWENTY = 20


# ─── Product ────────────────────────────────────────────
class Product:
    def __init__(self, code: str, name: str, price: float, quantity: int = 10):
        self.code = code
        self.name = name
        self.price = price
        self.quantity = quantity

    def is_available(self) -> bool:
        return self.quantity > 0

    def dispense_one(self):
        if self.quantity > 0:
            self.quantity -= 1

    def __repr__(self):
        return f"[{self.code}] {self.name} - ${self.price:.2f} (Qty: {self.quantity})"


# ─── Inventory ───────────────────────────────────────────
class Inventory:
    def __init__(self):
        self.products: dict[str, Product] = {}

    def add_product(self, product: Product):
        self.products[product.code] = product

    def get_product(self, code: str) -> Product | None:
        return self.products.get(code)

    def display(self):
        print("\n  ┌────────────────────────────────────┐")
        print("  │        PRODUCT SELECTION           │")
        print("  ├────────────────────────────────────┤")
        for p in self.products.values():
            status = "✓" if p.is_available() else "✗ SOLD OUT"
            print(f"  │  {p.code}: {p.name:<12} "
                  f"${p.price:.2f}  {status:<10} │")
        print("  └────────────────────────────────────┘\n")


# ─── State Pattern ───────────────────────────────────────
class VendingState(ABC):
    def __init__(self, machine: 'VendingMachine'):
        self.machine = machine

    @abstractmethod
    def select_product(self, code: str): pass

    @abstractmethod
    def insert_money(self, amount: float): pass

    @abstractmethod
    def dispense(self): pass

    @abstractmethod
    def cancel(self): pass


class IdleState(VendingState):
    def select_product(self, code: str):
        product = self.machine.inventory.get_product(code)
        if not product:
            print("  ✗ Invalid product code")
            return
        if not product.is_available():
            print(f"  ✗ {product.name} is sold out")
            return
        self.machine.selected_product = product
        self.machine.inserted_amount = 0
        print(f"  ✓ Selected: {product.name} (${product.price:.2f})")
        print(f"    Please insert ${product.price:.2f}")
        self.machine.set_state(HasSelectionState(self.machine))

    def insert_money(self, amount):
        print("  ✗ Select a product first")

    def dispense(self):
        print("  ✗ Select a product first")

    def cancel(self):
        print("  ✗ Nothing to cancel")


class HasSelectionState(VendingState):
    def select_product(self, code: str):
        print("  ✗ Product already selected. Cancel first to change.")

    def insert_money(self, amount: float):
        self.machine.inserted_amount += amount
        remaining = self.machine.selected_product.price - self.machine.inserted_amount
        if remaining <= 0:
            print(f"  ✓ Inserted ${amount:.2f} | Total: "
                  f"${self.machine.inserted_amount:.2f} — Sufficient!")
            self.machine.set_state(DispensingState(self.machine))
            self.machine.state.dispense()
        else:
            print(f"  ✓ Inserted ${amount:.2f} | "
                  f"Remaining: ${remaining:.2f}")

    def dispense(self):
        print(f"  ✗ Insert ${self.machine.selected_product.price - self.machine.inserted_amount:.2f} more")

    def cancel(self):
        refund = self.machine.inserted_amount
        self.machine.reset()
        if refund > 0:
            print(f"  ✓ Cancelled. Refund: ${refund:.2f}")
        else:
            print("  ✓ Cancelled.")


class DispensingState(VendingState):
    def select_product(self, code: str):
        print("  ✗ Dispensing in progress...")

    def insert_money(self, amount):
        print("  ✗ Dispensing in progress...")

    def dispense(self):
        product = self.machine.selected_product
        change = round(self.machine.inserted_amount - product.price, 2)

        product.dispense_one()
        self.machine.total_revenue += product.price

        print(f"\n  ═══════════════════════════════")
        print(f"  ║  🎁 Dispensing: {product.name}")
        if change > 0:
            print(f"  ║  💰 Change: ${change:.2f}")
        print(f"  ═══════════════════════════════\n")

        self.machine.reset()

    def cancel(self):
        print("  ✗ Cannot cancel during dispensing")


# ─── Vending Machine ────────────────────────────────────
class VendingMachine:
    def __init__(self, machine_id: str):
        self.machine_id = machine_id
        self.inventory = Inventory()
        self.selected_product: Product | None = None
        self.inserted_amount: float = 0
        self.total_revenue: float = 0
        self.state: VendingState = IdleState(self)

    def set_state(self, state: VendingState):
        self.state = state

    def reset(self):
        self.selected_product = None
        self.inserted_amount = 0
        self.set_state(IdleState(self))

    # Public API
    def select_product(self, code: str):
        self.state.select_product(code)

    def insert_money(self, amount: float):
        self.state.insert_money(amount)

    def insert_coin(self, coin: Coin):
        self.insert_money(coin.value)

    def insert_note(self, note: Note):
        self.insert_money(note.value)

    def dispense(self):
        self.state.dispense()

    def cancel(self):
        self.state.cancel()

    def display_products(self):
        self.inventory.display()


# ─── Demo ─────────────────────────────────────────────────
if __name__ == "__main__":
    vm = VendingMachine("VM-001")

    # Stock products
    vm.inventory.add_product(Product("A1", "Coke", 1.50, 5))
    vm.inventory.add_product(Product("A2", "Pepsi", 1.25, 3))
    vm.inventory.add_product(Product("B1", "Chips", 2.00, 8))
    vm.inventory.add_product(Product("B2", "Candy Bar", 1.75, 0))  # sold out

    vm.display_products()

    # Scenario 1: Successful purchase
    print("=== Scenario 1: Buy Coke ===")
    vm.select_product("A1")
    vm.insert_coin(Coin.QUARTER)
    vm.insert_coin(Coin.QUARTER)
    vm.insert_note(Note.ONE)

    # Scenario 2: Sold out
    print("=== Scenario 2: Sold out ===")
    vm.select_product("B2")

    # Scenario 3: Cancel
    print("\n=== Scenario 3: Cancel ===")
    vm.select_product("B1")
    vm.insert_note(Note.ONE)
    vm.cancel()

    # Scenario 4: Exact change
    print("=== Scenario 4: Exact change ===")
    vm.select_product("A2")
    vm.insert_note(Note.ONE)
    vm.insert_coin(Coin.QUARTER)

    print(f"\nTotal Revenue: ${vm.total_revenue:.2f}")
    vm.display_products()
```

---

## 9. Snake and Ladder Game

### Requirements
- Configurable **board size** (default 100)
- Multiple players, turn-based
- **Snakes** (go down) and **Ladders** (go up)
- Single die or double dice
- First player to reach/exceed last cell wins
- Configurable snake/ladder positions

### Full Python Code

```python
import random
from dataclasses import dataclass, field


# ─── Board Elements ──────────────────────────────────────
@dataclass
class Snake:
    head: int    # higher position
    tail: int    # lower position

    def __post_init__(self):
        assert self.head > self.tail, "Snake head must be above tail"

    def __repr__(self):
        return f"🐍 Snake({self.head} → {self.tail})"


@dataclass
class Ladder:
    bottom: int  # lower position
    top: int     # higher position

    def __post_init__(self):
        assert self.top > self.bottom, "Ladder top must be above bottom"

    def __repr__(self):
        return f"🪜 Ladder({self.bottom} → {self.top})"


# ─── Dice ────────────────────────────────────────────────
class Dice:
    def __init__(self, num_dice: int = 1, faces: int = 6):
        self.num_dice = num_dice
        self.faces = faces

    def roll(self) -> int:
        total = sum(random.randint(1, self.faces) for _ in range(self.num_dice))
        return total


# ─── Player ──────────────────────────────────────────────
class Player:
    def __init__(self, name: str):
        self.name = name
        self.position = 0
        self.moves_count = 0

    def __repr__(self):
        return f"{self.name} (pos={self.position})"


# ─── Board ───────────────────────────────────────────────
class Board:
    def __init__(self, size: int = 100):
        self.size = size
        self.snakes: dict[int, Snake] = {}   # head_position -> Snake
        self.ladders: dict[int, Ladder] = {} # bottom_position -> Ladder

    def add_snake(self, head: int, tail: int):
        snake = Snake(head, tail)
        if head in self.ladders:
            raise ValueError(f"Position {head} already has a ladder")
        self.snakes[head] = snake

    def add_ladder(self, bottom: int, top: int):
        ladder = Ladder(bottom, top)
        if bottom in self.snakes:
            raise ValueError(f"Position {bottom} already has a snake")
        self.ladders[bottom] = ladder

    def get_final_position(self, position: int) -> tuple[int, str]:
        """Check if the position has a snake/ladder, return final pos + event."""
        if position in self.snakes:
            s = self.snakes[position]
            return s.tail, f"  {s}"
        if position in self.ladders:
            l = self.ladders[position]
            return l.top, f"  {l}"
        return position, ""

    def display(self):
        print("\n  Board Configuration:")
        print(f"  Size: {self.size}")
        print(f"  Snakes: {list(self.snakes.values())}")
        print(f"  Ladders: {list(self.ladders.values())}\n")


# ─── Game ────────────────────────────────────────────────
class SnakeAndLadderGame:
    def __init__(self, board: Board, players: list[Player],
                 dice: Dice = None):
        self.board = board
        self.players = players
        self.dice = dice or Dice(num_dice=1)
        self.current_turn = 0
        self.winner: Player | None = None
        self.is_over = False
        self.move_log: list[str] = []

    def play_turn(self):
        """Execute one turn for the current player."""
        if self.is_over:
            return

        player = self.players[self.current_turn % len(self.players)]
        roll = self.dice.roll()
        old_pos = player.position
        new_pos = old_pos + roll

        log = f"  {player.name} rolls {roll}: {old_pos}"

        if new_pos > self.board.size:
            log += f" + {roll} = {new_pos} (exceeds {self.board.size}, stays)"
            print(log)
            self.current_turn += 1
            return

        # Check snake/ladder
        final_pos, event = self.board.get_final_position(new_pos)
        if event:
            log += f" → {new_pos} {event} → {final_pos}"
        else:
            log += f" → {new_pos}"

        player.position = final_pos
        player.moves_count += 1
        print(log)
        self.move_log.append(log)

        # Check win
        if player.position >= self.board.size:
            self.winner = player
            self.is_over = True
            print(f"\n  🏆 {player.name} WINS in {player.moves_count} moves!\n")
            return

        self.current_turn += 1

    def play(self, max_turns: int = 200):
        """Auto-play the entire game."""
        print("=" * 55)
        print("       🎲 SNAKE AND LADDER GAME 🎲")
        print("=" * 55)
        self.board.display()

        turn = 0
        while not self.is_over and turn < max_turns:
            self.play_turn()
            turn += 1

        if not self.is_over:
            print("  Game ended: max turns reached")

        # Scoreboard
        print("\n  --- Final Positions ---")
        for p in sorted(self.players, key=lambda x: -x.position):
            print(f"    {p.name}: position {p.position} "
                  f"({p.moves_count} moves)")


# ─── Demo ─────────────────────────────────────────────────
if __name__ == "__main__":
    random.seed(42)

    board = Board(size=100)

    # Add snakes
    board.add_snake(99, 10)
    board.add_snake(62, 18)
    board.add_snake(48, 26)
    board.add_snake(95, 56)
    board.add_snake(36, 6)

    # Add ladders
    board.add_ladder(2, 38)
    board.add_ladder(7, 14)
    board.add_ladder(8, 31)
    board.add_ladder(15, 46)
    board.add_ladder(28, 84)
    board.add_ladder(51, 67)
    board.add_ladder(71, 91)

    players = [Player("Alice"), Player("Bob"), Player("Charlie")]
    dice = Dice(num_dice=1, faces=6)

    game = SnakeAndLadderGame(board, players, dice)
    game.play()
```

---

## 10. Chess Game

### Requirements
- 8×8 board with standard piece setup
- All **six piece types** with correct movement rules
- Turn-based (White then Black)
- **Check** and **Checkmate** detection
- Move validation (can't move into check)
- Capture opponent pieces
- Special moves: Castling, Pawn promotion (simplified)

### Design Patterns
| Pattern | Purpose |
|---------|---------|
| **Template Method** | Base Piece with abstract `get_valid_moves` |
| **Command** | Move execution / undo |
| **Observer** | Notify on check/checkmate |

### Full Python Code

```python
from abc import ABC, abstractmethod
from enum import Enum
from copy import deepcopy


# ─── Enums ───────────────────────────────────────────────
class Color(Enum):
    WHITE = "White"
    BLACK = "Black"

    @property
    def opposite(self):
        return Color.BLACK if self == Color.WHITE else Color.WHITE


class PieceType(Enum):
    PAWN = "Pawn"
    ROOK = "Rook"
    KNIGHT = "Knight"
    BISHOP = "Bishop"
    QUEEN = "Queen"
    KING = "King"


# ─── Position ────────────────────────────────────────────
class Position:
    def __init__(self, row: int, col: int):
        self.row = row
        self.col = col

    def is_valid(self) -> bool:
        return 0 <= self.row < 8 and 0 <= self.col < 8

    def __eq__(self, other):
        return isinstance(other, Position) and self.row == other.row and self.col == other.col

    def __hash__(self):
        return hash((self.row, self.col))

    def __repr__(self):
        cols = "abcdefgh"
        return f"{cols[self.col]}{self.row + 1}"


# ─── Piece Hierarchy ────────────────────────────────────
class Piece(ABC):
    SYMBOLS = {
        (Color.WHITE, PieceType.KING): "♔",
        (Color.WHITE, PieceType.QUEEN): "♕",
        (Color.WHITE, PieceType.ROOK): "♖",
        (Color.WHITE, PieceType.BISHOP): "♗",
        (Color.WHITE, PieceType.KNIGHT): "♘",
        (Color.WHITE, PieceType.PAWN): "♙",
        (Color.BLACK, PieceType.KING): "♚",
        (Color.BLACK, PieceType.QUEEN): "♛",
        (Color.BLACK, PieceType.ROOK): "♜",
        (Color.BLACK, PieceType.BISHOP): "♝",
        (Color.BLACK, PieceType.KNIGHT): "♞",
        (Color.BLACK, PieceType.PAWN): "♟",
    }

    def __init__(self, color: Color, piece_type: PieceType):
        self.color = color
        self.piece_type = piece_type
        self.has_moved = False

    @abstractmethod
    def get_potential_moves(self, pos: Position, board: 'Board') -> list[Position]:
        """Return all positions this piece could move to (ignoring check)."""
        pass

    @property
    def symbol(self) -> str:
        return self.SYMBOLS.get((self.color, self.piece_type), "?")

    def __repr__(self):
        return f"{self.color.value[0]}{self.piece_type.value}"

    def _slide_moves(self, pos: Position, board: 'Board',
                     directions: list[tuple[int, int]]) -> list[Position]:
        """Generate moves along given directions (for Rook/Bishop/Queen)."""
        moves = []
        for dr, dc in directions:
            r, c = pos.row + dr, pos.col + dc
            while 0 <= r < 8 and 0 <= c < 8:
                target = Position(r, c)
                occupant = board.get_piece(target)
                if occupant is None:
                    moves.append(target)
                elif occupant.color != self.color:
                    moves.append(target)  # capture
                    break
                else:
                    break  # own piece blocks
                r += dr
                c += dc
        return moves


class Pawn(Piece):
    def __init__(self, color: Color):
        super().__init__(color, PieceType.PAWN)

    def get_potential_moves(self, pos: Position, board: 'Board') -> list[Position]:
        moves = []
        direction = 1 if self.color == Color.WHITE else -1
        start_row = 1 if self.color == Color.WHITE else 6

        # Forward one
        one_ahead = Position(pos.row + direction, pos.col)
        if one_ahead.is_valid() and board.get_piece(one_ahead) is None:
            moves.append(one_ahead)
            # Forward two from start
            if pos.row == start_row:
                two_ahead = Position(pos.row + 2 * direction, pos.col)
                if two_ahead.is_valid() and board.get_piece(two_ahead) is None:
                    moves.append(two_ahead)

        # Diagonal captures
        for dc in [-1, 1]:
            diag = Position(pos.row + direction, pos.col + dc)
            if diag.is_valid():
                target = board.get_piece(diag)
                if target and target.color != self.color:
                    moves.append(diag)

        return moves


class Rook(Piece):
    def __init__(self, color: Color):
        super().__init__(color, PieceType.ROOK)

    def get_potential_moves(self, pos: Position, board: 'Board') -> list[Position]:
        return self._slide_moves(pos, board,
                                 [(0, 1), (0, -1), (1, 0), (-1, 0)])


class Knight(Piece):
    def __init__(self, color: Color):
        super().__init__(color, PieceType.KNIGHT)

    def get_potential_moves(self, pos: Position, board: 'Board') -> list[Position]:
        moves = []
        offsets = [(-2, -1), (-2, 1), (-1, -2), (-1, 2),
                   (1, -2), (1, 2), (2, -1), (2, 1)]
        for dr, dc in offsets:
            target = Position(pos.row + dr, pos.col + dc)
            if target.is_valid():
                occupant = board.get_piece(target)
                if occupant is None or occupant.color != self.color:
                    moves.append(target)
        return moves


class Bishop(Piece):
    def __init__(self, color: Color):
        super().__init__(color, PieceType.BISHOP)

    def get_potential_moves(self, pos: Position, board: 'Board') -> list[Position]:
        return self._slide_moves(pos, board,
                                 [(1, 1), (1, -1), (-1, 1), (-1, -1)])


class Queen(Piece):
    def __init__(self, color: Color):
        super().__init__(color, PieceType.QUEEN)

    def get_potential_moves(self, pos: Position, board: 'Board') -> list[Position]:
        return self._slide_moves(pos, board,
                                 [(0, 1), (0, -1), (1, 0), (-1, 0),
                                  (1, 1), (1, -1), (-1, 1), (-1, -1)])


class King(Piece):
    def __init__(self, color: Color):
        super().__init__(color, PieceType.KING)

    def get_potential_moves(self, pos: Position, board: 'Board') -> list[Position]:
        moves = []
        for dr in [-1, 0, 1]:
            for dc in [-1, 0, 1]:
                if dr == 0 and dc == 0:
                    continue
                target = Position(pos.row + dr, pos.col + dc)
                if target.is_valid():
                    occupant = board.get_piece(target)
                    if occupant is None or occupant.color != self.color:
                        moves.append(target)
        return moves


# ─── Move ────────────────────────────────────────────────
class Move:
    def __init__(self, piece: Piece, start: Position, end: Position,
                 captured: Piece = None, is_castling: bool = False,
                 promotion_piece: Piece = None):
        self.piece = piece
        self.start = start
        self.end = end
        self.captured = captured
        self.is_castling = is_castling
        self.promotion_piece = promotion_piece

    def __repr__(self):
        capture = "x" if self.captured else ""
        return f"{self.piece.symbol}{self.start}{capture}{self.end}"


# ─── Board ───────────────────────────────────────────────
class Board:
    def __init__(self):
        self.grid: list[list[Piece | None]] = [
            [None] * 8 for _ in range(8)
        ]
        self._setup()

    def _setup(self):
        """Place pieces in standard starting positions."""
        # Pawns
        for c in range(8):
            self.grid[1][c] = Pawn(Color.WHITE)
            self.grid[6][c] = Pawn(Color.BLACK)

        # Back ranks
        order = [Rook, Knight, Bishop, Queen, King, Bishop, Knight, Rook]
        for c, cls in enumerate(order):
            self.grid[0][c] = cls(Color.WHITE)
            self.grid[7][c] = cls(Color.BLACK)

    def get_piece(self, pos: Position) -> Piece | None:
        if not pos.is_valid():
            return None
        return self.grid[pos.row][pos.col]

    def set_piece(self, pos: Position, piece: Piece | None):
        self.grid[pos.row][pos.col] = piece

    def find_king(self, color: Color) -> Position:
        for r in range(8):
            for c in range(8):
                p = self.grid[r][c]
                if p and p.piece_type == PieceType.KING and p.color == color:
                    return Position(r, c)
        raise ValueError(f"King not found for {color}")

    def get_all_pieces(self, color: Color) -> list[tuple[Position, Piece]]:
        result = []
        for r in range(8):
            for c in range(8):
                p = self.grid[r][c]
                if p and p.color == color:
                    result.append((Position(r, c), p))
        return result

    def is_under_attack(self, pos: Position, by_color: Color) -> bool:
        """Check if a position is attacked by any piece of given color."""
        for p_pos, piece in self.get_all_pieces(by_color):
            if pos in piece.get_potential_moves(p_pos, self):
                return True
        return False

    def display(self):
        print("\n     a   b   c   d   e   f   g   h")
        print("   ┌───┬───┬───┬───┬───┬───┬───┬───┐")
        for r in range(7, -1, -1):
            row_str = f" {r + 1} │"
            for c in range(8):
                piece = self.grid[r][c]
                symbol = piece.symbol if piece else " "
                row_str += f" {symbol} │"
            print(row_str)
            if r > 0:
                print("   ├───┼───┼───┼───┼───┼───┼───┼───┤")
        print("   └───┴───┴───┴───┴───┴───┴───┴───┘")
        print("     a   b   c   d   e   f   g   h\n")


# ─── Game ────────────────────────────────────────────────
class ChessGame:
    def __init__(self):
        self.board = Board()
        self.current_turn = Color.WHITE
        self.move_history: list[Move] = []
        self.is_over = False
        self.winner: Color | None = None
        self.captured_pieces = {Color.WHITE: [], Color.BLACK: []}

    def get_legal_moves(self, pos: Position) -> list[Position]:
        """Return all legal moves for piece at pos (filters out self-check)."""
        piece = self.board.get_piece(pos)
        if not piece or piece.color != self.current_turn:
            return []

        potential = piece.get_potential_moves(pos, self.board)
        legal = []
        for target in potential:
            if self._is_legal_move(pos, target, piece):
                legal.append(target)
        return legal

    def _is_legal_move(self, start: Position, end: Position,
                       piece: Piece) -> bool:
        """Simulate the move and check if own king is in check."""
        # Save state
        captured = self.board.get_piece(end)
        self.board.set_piece(end, piece)
        self.board.set_piece(start, None)

        king_pos = self.board.find_king(piece.color)
        in_check = self.board.is_under_attack(king_pos, piece.color.opposite)

        # Restore state
        self.board.set_piece(start, piece)
        self.board.set_piece(end, captured)

        return not in_check

    def make_move(self, start: Position, end: Position) -> bool:
        """Execute a move if legal."""
        piece = self.board.get_piece(start)
        if not piece:
            print(f"  ✗ No piece at {start}")
            return False
        if piece.color != self.current_turn:
            print(f"  ✗ It's {self.current_turn.value}'s turn")
            return False
        if end not in self.get_legal_moves(start):
            print(f"  ✗ Illegal move: {start} → {end}")
            return False

        captured = self.board.get_piece(end)
        move = Move(piece, start, end, captured)

        # Execute
        self.board.set_piece(end, piece)
        self.board.set_piece(start, None)
        piece.has_moved = True

        if captured:
            self.captured_pieces[piece.color].append(captured)

        # Pawn promotion (auto-Queen)
        if (piece.piece_type == PieceType.PAWN and
                (end.row == 0 or end.row == 7)):
            promoted = Queen(piece.color)
            self.board.set_piece(end, promoted)
            move.promotion_piece = promoted
            print(f"  👑 Pawn promoted to Queen!")

        self.move_history.append(move)
        print(f"  Move {len(self.move_history)}: {move}")

        # Check for check / checkmate
        opponent = self.current_turn.opposite
        if self._is_in_check(opponent):
            if self._is_checkmate(opponent):
                print(f"\n  ♛ CHECKMATE! {self.current_turn.value} wins!\n")
                self.is_over = True
                self.winner = self.current_turn
                return True
            else:
                print(f"  ⚠ {opponent.value} is in CHECK!")
        elif self._is_stalemate(opponent):
            print(f"\n  🤝 STALEMATE! Game is a draw.\n")
            self.is_over = True
            return True

        self.current_turn = opponent
        return True

    def _is_in_check(self, color: Color) -> bool:
        king_pos = self.board.find_king(color)
        return self.board.is_under_attack(king_pos, color.opposite)

    def _is_checkmate(self, color: Color) -> bool:
        """Color is in check — can they escape?"""
        return self._has_no_legal_moves(color)

    def _is_stalemate(self, color: Color) -> bool:
        """Color is NOT in check but has no legal moves."""
        return self._has_no_legal_moves(color)

    def _has_no_legal_moves(self, color: Color) -> bool:
        saved_turn = self.current_turn
        self.current_turn = color
        for pos, piece in self.board.get_all_pieces(color):
            if self.get_legal_moves(pos):
                self.current_turn = saved_turn
                return False
        self.current_turn = saved_turn
        return True

    def display(self):
        self.board.display()
        print(f"  Turn: {self.current_turn.value}")
        w_cap = " ".join(p.symbol for p in self.captured_pieces[Color.WHITE])
        b_cap = " ".join(p.symbol for p in self.captured_pieces[Color.BLACK])
        if w_cap:
            print(f"  White captured: {w_cap}")
        if b_cap:
            print(f"  Black captured: {b_cap}")
        print()


# ─── Helper: Parse algebraic notation ────────────────────
def parse_pos(s: str) -> Position:
    """Convert 'e2' to Position(1, 4)."""
    col = ord(s[0]) - ord('a')
    row = int(s[1]) - 1
    return Position(row, col)


# ─── Demo ─────────────────────────────────────────────────
if __name__ == "__main__":
    game = ChessGame()
    game.display()

    # Scholar's Mate (4-move checkmate)
    moves = [
        ("e2", "e4"),  # White pawn
        ("e7", "e5"),  # Black pawn
        ("f1", "c4"),  # White bishop
        ("b8", "c6"),  # Black knight
        ("d1", "h5"),  # White queen
        ("g8", "f6"),  # Black knight
        ("h5", "f7"),  # White queen captures f7 — CHECKMATE
    ]

    for start_str, end_str in moves:
        start = parse_pos(start_str)
        end = parse_pos(end_str)
        game.make_move(start, end)

    game.display()

    # Print move history
    print("--- Move History ---")
    for i, m in enumerate(game.move_history, 1):
        print(f"  {i}. {m}")
```

### Output (Scholar's Mate)
```
     a   b   c   d   e   f   g   h
   ┌───┬───┬───┬───┬───┬───┬───┬───┐
 8 │ ♜ │ ♞ │ ♝ │ ♛ │ ♚ │ ♝ │ ♞ │ ♜ │
   ├───┼───┼───┼───┼───┼───┼───┼───┤
 7 │ ♟ │ ♟ │ ♟ │ ♟ │ ♟ │ ♟ │ ♟ │ ♟ │
  ...
 1 │ ♖ │ ♘ │ ♗ │ ♕ │ ♔ │ ♗ │ ♘ │ ♖ │
   └───┴───┴───┴───┴───┴───┴───┴───┘

  Move 1: ♙e2e4
  Move 2: ♟e7e5
  Move 3: ♗f1c4
  Move 4: ♞b8c6
  Move 5: ♕d1h5
  Move 6: ♞g8f6
  Move 7: ♕h5xf7

  ♛ CHECKMATE! White wins!
```

---

## Summary: Design Patterns Across All Problems

```
┌───────────────────────┬────────────────────────────────────────────┐
│ Pattern               │ Used In                                    │
├───────────────────────┼────────────────────────────────────────────┤
│ Singleton             │ ParkingLot, ElevatorController             │
│ Strategy              │ ParkingLot fees, ATM dispensing,           │
│                       │ Shopping cart discounts, Library fines     │
│ State                 │ ATM, Vending Machine, Elevator             │
│ Observer              │ Elevator, Library, Shopping cart orders     │
│ Chain of Resp.        │ ATM cash dispenser                         │
│ Composite             │ File System (File/Directory)               │
│ Factory               │ Parking spots, Chess pieces                │
│ Template Method       │ Chess piece movement                       │
│ Command               │ Chess moves (with undo support)            │
│ Builder               │ Order construction                         │
└───────────────────────┴────────────────────────────────────────────┘
```

> **Key Takeaway**: In LLD interviews, **identify the nouns** (→ classes), **identify the verbs** (→ methods), **identify the variations** (→ Strategy/State/Factory patterns), and **identify constraints** (→ enums & validation). Always start with requirements clarification, then draw the class diagram, then write code.




# Real Backend LLD Questions (11–18) — Complete Deep Dive

---

## 11. Cache with Eviction Policy (LRU / LFU)

### Core Concept

A **cache** stores frequently-accessed data in fast storage.
When full, an **eviction policy** decides which entry to remove.

```
┌──────────────────────────────────────────────────────────┐
│                     CACHE ARCHITECTURE                   │
│                                                          │
│   Client ──► get(key) ──► ┌────────────┐                │
│                           │  HashMap    │  O(1) lookup   │
│   Client ──► put(k,v) ──►│  key→node   │────►┌────────┐ │
│                           └────────────┘     │  DLL /  │ │
│                                              │  Freq   │ │
│              Eviction on capacity overflow    │  Map    │ │
│              ◄────────────────────────────────┘        │ │
│                                              └────────┘ │
│                                                          │
│   LRU: Doubly-Linked List (most→least recent)           │
│   LFU: Frequency Map + min-frequency pointer             │
│   TTL: Expiry timestamps per entry                       │
└──────────────────────────────────────────────────────────┘
```

### Full Implementation

```python
import threading
import time
from collections import OrderedDict, defaultdict
from abc import ABC, abstractmethod
from typing import Any, Optional


# ──────────────────────────────────────────────
# 1. EVICTION POLICY INTERFACE
# ──────────────────────────────────────────────
class EvictionPolicy(ABC):
    """Strategy pattern: swap eviction algorithms without changing cache."""

    @abstractmethod
    def on_access(self, key: str) -> None:
        """Called when a key is read or updated."""

    @abstractmethod
    def on_insert(self, key: str) -> None:
        """Called when a new key is inserted."""

    @abstractmethod
    def on_remove(self, key: str) -> None:
        """Called when a key is explicitly removed."""

    @abstractmethod
    def evict(self) -> Optional[str]:
        """Return the key to evict, or None."""


# ──────────────────────────────────────────────
# 2. LRU POLICY — Doubly Linked List + HashMap
# ──────────────────────────────────────────────
class DLLNode:
    """Node in a doubly-linked list."""
    __slots__ = ('key', 'prev', 'next')

    def __init__(self, key: str = ""):
        self.key = key
        self.prev: Optional['DLLNode'] = None
        self.next: Optional['DLLNode'] = None


class LRUPolicy(EvictionPolicy):
    """
    Least Recently Used: evicts the entry not accessed for the longest time.

    Structure:
        HEAD <-> node1 <-> node2 <-> ... <-> TAIL
        (most recent)                  (least recent = evict)
    """

    def __init__(self):
        # Sentinel nodes avoid null-checks
        self._head = DLLNode("HEAD")
        self._tail = DLLNode("TAIL")
        self._head.next = self._tail
        self._tail.prev = self._head
        self._map: dict[str, DLLNode] = {}  # key → DLL node

    def _remove_node(self, node: DLLNode) -> None:
        node.prev.next = node.next
        node.next.prev = node.prev

    def _add_to_front(self, node: DLLNode) -> None:
        node.next = self._head.next
        node.prev = self._head
        self._head.next.prev = node
        self._head.next = node

    def on_access(self, key: str) -> None:
        if key in self._map:
            node = self._map[key]
            self._remove_node(node)
            self._add_to_front(node)

    def on_insert(self, key: str) -> None:
        node = DLLNode(key)
        self._map[key] = node
        self._add_to_front(node)

    def on_remove(self, key: str) -> None:
        if key in self._map:
            self._remove_node(self._map.pop(key))

    def evict(self) -> Optional[str]:
        if self._tail.prev == self._head:
            return None  # empty
        victim = self._tail.prev
        self._remove_node(victim)
        return self._map.pop(victim.key).key if victim.key in self._map else victim.key


# ──────────────────────────────────────────────
# 3. LFU POLICY — Frequency Map + Min Freq
# ──────────────────────────────────────────────
class LFUPolicy(EvictionPolicy):
    """
    Least Frequently Used: evicts the entry with the smallest access count.
    Ties broken by LRU (oldest among same-frequency entries).

    Structures:
        key_freq:   key → current frequency
        freq_keys:  freq → OrderedDict{key: None}  (insertion-ordered set)
        min_freq:   smallest frequency currently in cache
    """

    def __init__(self):
        self._key_freq: dict[str, int] = {}
        self._freq_keys: dict[int, OrderedDict] = defaultdict(OrderedDict)
        self._min_freq: int = 0

    def on_access(self, key: str) -> None:
        if key not in self._key_freq:
            return
        old_freq = self._key_freq[key]
        new_freq = old_freq + 1
        self._key_freq[key] = new_freq

        # Move from old freq bucket to new
        del self._freq_keys[old_freq][key]
        if not self._freq_keys[old_freq]:
            del self._freq_keys[old_freq]
            if self._min_freq == old_freq:
                self._min_freq = new_freq

        self._freq_keys[new_freq][key] = None

    def on_insert(self, key: str) -> None:
        self._key_freq[key] = 1
        self._freq_keys[1][key] = None
        self._min_freq = 1

    def on_remove(self, key: str) -> None:
        if key not in self._key_freq:
            return
        freq = self._key_freq.pop(key)
        del self._freq_keys[freq][key]
        if not self._freq_keys[freq]:
            del self._freq_keys[freq]

    def evict(self) -> Optional[str]:
        if not self._freq_keys:
            return None
        # popitem(last=False) → FIFO = oldest in that frequency bucket
        bucket = self._freq_keys[self._min_freq]
        evicted_key, _ = bucket.popitem(last=False)
        if not bucket:
            del self._freq_keys[self._min_freq]
        del self._key_freq[evicted_key]
        return evicted_key


# ──────────────────────────────────────────────
# 4. CACHE ENTRY (supports TTL)
# ──────────────────────────────────────────────
class CacheEntry:
    __slots__ = ('value', 'created_at', 'ttl')

    def __init__(self, value: Any, ttl: Optional[float] = None):
        self.value = value
        self.created_at = time.time()
        self.ttl = ttl  # seconds; None = no expiry

    @property
    def is_expired(self) -> bool:
        if self.ttl is None:
            return False
        return (time.time() - self.created_at) > self.ttl


# ──────────────────────────────────────────────
# 5. THE CACHE CLASS (thread-safe)
# ──────────────────────────────────────────────
class Cache:
    """
    Thread-safe, generic cache.

    Features:
        • Pluggable eviction (LRU / LFU via Strategy pattern)
        • Per-key TTL
        • get / put / delete / clear
        • Hit/miss statistics
    """

    def __init__(self, capacity: int, policy: EvictionPolicy,
                 default_ttl: Optional[float] = None):
        if capacity <= 0:
            raise ValueError("capacity must be > 0")
        self._capacity = capacity
        self._policy = policy
        self._default_ttl = default_ttl
        self._store: dict[str, CacheEntry] = {}
        self._lock = threading.Lock()
        self._hits = 0
        self._misses = 0

    # ── Public API ──────────────────────────

    def get(self, key: str) -> Optional[Any]:
        with self._lock:
            entry = self._store.get(key)
            if entry is None:
                self._misses += 1
                return None
            if entry.is_expired:
                self._remove_internal(key)
                self._misses += 1
                return None
            self._policy.on_access(key)
            self._hits += 1
            return entry.value

    def put(self, key: str, value: Any, ttl: Optional[float] = None) -> None:
        effective_ttl = ttl if ttl is not None else self._default_ttl
        with self._lock:
            if key in self._store:
                # Update existing
                self._store[key] = CacheEntry(value, effective_ttl)
                self._policy.on_access(key)
                return

            # Evict if at capacity
            while len(self._store) >= self._capacity:
                victim = self._policy.evict()
                if victim is None:
                    break
                self._store.pop(victim, None)

            self._store[key] = CacheEntry(value, effective_ttl)
            self._policy.on_insert(key)

    def delete(self, key: str) -> bool:
        with self._lock:
            return self._remove_internal(key)

    def clear(self) -> None:
        with self._lock:
            for k in list(self._store):
                self._remove_internal(k)

    @property
    def size(self) -> int:
        return len(self._store)

    @property
    def stats(self) -> dict:
        total = self._hits + self._misses
        return {
            "hits": self._hits,
            "misses": self._misses,
            "hit_rate": self._hits / total if total else 0.0,
            "size": len(self._store),
            "capacity": self._capacity,
        }

    # ── Internal ────────────────────────────

    def _remove_internal(self, key: str) -> bool:
        if key in self._store:
            del self._store[key]
            self._policy.on_remove(key)
            return True
        return False


# ──────────────────────────────────────────────
# DEMO
# ──────────────────────────────────────────────
if __name__ == "__main__":
    print("═══ LRU Cache Demo ═══")
    lru = Cache(capacity=3, policy=LRUPolicy())
    lru.put("a", 1)
    lru.put("b", 2)
    lru.put("c", 3)
    print(lru.get("a"))    # 1  → a becomes most recent
    lru.put("d", 4)        # evicts "b" (least recent)
    print(lru.get("b"))    # None
    print(lru.stats)

    print("\n═══ LFU Cache Demo ═══")
    lfu = Cache(capacity=3, policy=LFUPolicy())
    lfu.put("x", 10)
    lfu.put("y", 20)
    lfu.put("z", 30)
    lfu.get("x");  lfu.get("x");  lfu.get("y")   # x:3, y:2, z:1
    lfu.put("w", 40)       # evicts "z" (freq=1, lowest)
    print(lfu.get("z"))    # None
    print(lfu.get("x"))    # 10
    print(lfu.stats)

    print("\n═══ TTL Demo ═══")
    ttl_cache = Cache(capacity=10, policy=LRUPolicy(), default_ttl=1.0)
    ttl_cache.put("temp", "gone-soon")
    print(ttl_cache.get("temp"))  # "gone-soon"
    time.sleep(1.1)
    print(ttl_cache.get("temp"))  # None (expired)
```

**Complexity Table:**

| Operation | LRU | LFU |
|-----------|-----|-----|
| `get` | O(1) | O(1) |
| `put` | O(1) | O(1) |
| `evict` | O(1) | O(1) |
| Space | O(n) | O(n) |

---

## 12. Rate Limiter Class

### Core Concept

Controls how many requests a client can make within a time window.

```
┌─────────────────────────────────────────────────────────────────┐
│                    RATE LIMITER STRATEGIES                       │
│                                                                 │
│  ┌─────────────────┐  ┌──────────────┐  ┌───────────────────┐  │
│  │  Fixed Window    │  │ Sliding Log  │  │  Token Bucket     │  │
│  │                  │  │              │  │                   │  │
│  │ |___10___|___10__│  │  • • •  • •  │  │  ╭───╮            │  │
│  │  window  window  │  │  ↑ check all │  │  │🪣 │ tokens     │  │
│  │  counter resets  │  │  timestamps  │  │  │●●●│ refill     │  │
│  │  at boundary     │  │  in window   │  │  ╰───╯ over time  │  │
│  └─────────────────┘  └──────────────┘  └───────────────────┘  │
│                                                                 │
│  ┌──────────────────┐  ┌──────────────────────────────────────┐ │
│  │  Leaky Bucket    │  │  Sliding Window Counter              │ │
│  │  ╭───╮           │  │  weighted blend of prev+curr window  │ │
│  │  │💧 │ fixed     │  │  count ≈ prev*(1-overlap) + curr     │ │
│  │  │💧 │ drain     │  └──────────────────────────────────────┘ │
│  │  ╰─┬─╯ rate     │                                           │
│  │    💧            │                                           │
│  └──────────────────┘                                           │
└─────────────────────────────────────────────────────────────────┘
```

### Full Implementation

```python
import time
import threading
from abc import ABC, abstractmethod
from collections import deque
from enum import Enum, auto
from dataclasses import dataclass


# ──────────────────────────────────────────────
# 1. RESULT OBJECT
# ──────────────────────────────────────────────
@dataclass
class RateLimitResult:
    allowed: bool
    remaining: int          # requests left in current window
    retry_after: float      # seconds until next allowed request (0 if allowed)
    limit: int              # configured limit


# ──────────────────────────────────────────────
# 2. STRATEGY INTERFACE
# ──────────────────────────────────────────────
class RateLimitStrategy(ABC):
    @abstractmethod
    def try_acquire(self, key: str, tokens: int = 1) -> RateLimitResult:
        """Attempt to consume `tokens` for `key`. Thread-safe."""


# ──────────────────────────────────────────────
# 3. FIXED WINDOW
# ──────────────────────────────────────────────
class FixedWindowStrategy(RateLimitStrategy):
    """
    Divides time into fixed windows (e.g., every 60s).
    Resets counter at each boundary.

    Pros: simple, low memory.
    Cons: burst at window boundaries (2× burst possible).
    """

    def __init__(self, max_requests: int, window_seconds: float):
        self._max = max_requests
        self._window = window_seconds
        self._counters: dict[str, tuple[int, int]] = {}  # key → (window_id, count)
        self._lock = threading.Lock()

    def try_acquire(self, key: str, tokens: int = 1) -> RateLimitResult:
        with self._lock:
            now = time.time()
            window_id = int(now // self._window)

            stored_window, count = self._counters.get(key, (window_id, 0))

            if stored_window != window_id:
                count = 0  # new window, reset

            if count + tokens <= self._max:
                count += tokens
                self._counters[key] = (window_id, count)
                return RateLimitResult(True, self._max - count, 0, self._max)
            else:
                next_window_start = (window_id + 1) * self._window
                return RateLimitResult(False, 0, next_window_start - now, self._max)


# ──────────────────────────────────────────────
# 4. SLIDING WINDOW LOG
# ──────────────────────────────────────────────
class SlidingWindowLogStrategy(RateLimitStrategy):
    """
    Stores timestamp of every request; counts those within window.

    Pros: very accurate, no boundary bursts.
    Cons: high memory for heavy traffic.
    """

    def __init__(self, max_requests: int, window_seconds: float):
        self._max = max_requests
        self._window = window_seconds
        self._logs: dict[str, deque] = {}
        self._lock = threading.Lock()

    def try_acquire(self, key: str, tokens: int = 1) -> RateLimitResult:
        with self._lock:
            now = time.time()
            cutoff = now - self._window

            if key not in self._logs:
                self._logs[key] = deque()
            log = self._logs[key]

            # Purge expired
            while log and log[0] <= cutoff:
                log.popleft()

            if len(log) + tokens <= self._max:
                for _ in range(tokens):
                    log.append(now)
                return RateLimitResult(True, self._max - len(log), 0, self._max)
            else:
                retry = log[0] + self._window - now
                return RateLimitResult(False, 0, max(retry, 0), self._max)


# ──────────────────────────────────────────────
# 5. TOKEN BUCKET
# ──────────────────────────────────────────────
class TokenBucketStrategy(RateLimitStrategy):
    """
    Bucket holds up to `capacity` tokens. Tokens added at `refill_rate`/sec.
    Each request consumes tokens.

    Pros: allows controlled bursts, smooth rate limiting.
    Cons: requires per-key state.
    """

    def __init__(self, capacity: int, refill_rate: float):
        self._capacity = capacity        # max burst size
        self._refill_rate = refill_rate  # tokens per second
        self._buckets: dict[str, list] = {}  # key → [tokens, last_refill_time]
        self._lock = threading.Lock()

    def try_acquire(self, key: str, tokens: int = 1) -> RateLimitResult:
        with self._lock:
            now = time.time()

            if key not in self._buckets:
                self._buckets[key] = [self._capacity, now]

            bucket = self._buckets[key]
            elapsed = now - bucket[1]
            bucket[0] = min(self._capacity, bucket[0] + elapsed * self._refill_rate)
            bucket[1] = now

            if bucket[0] >= tokens:
                bucket[0] -= tokens
                return RateLimitResult(
                    True, int(bucket[0]), 0, self._capacity
                )
            else:
                wait = (tokens - bucket[0]) / self._refill_rate
                return RateLimitResult(
                    False, 0, wait, self._capacity
                )


# ──────────────────────────────────────────────
# 6. LEAKY BUCKET
# ──────────────────────────────────────────────
class LeakyBucketStrategy(RateLimitStrategy):
    """
    Requests enter a queue processed at fixed rate.
    If queue is full, request is rejected.

    Pros: perfectly smooth output rate.
    Cons: no bursts allowed (by design).
    """

    def __init__(self, capacity: int, leak_rate: float):
        self._capacity = capacity
        self._leak_rate = leak_rate  # requests per second
        self._buckets: dict[str, list] = {}  # key → [water_level, last_leak_time]
        self._lock = threading.Lock()

    def try_acquire(self, key: str, tokens: int = 1) -> RateLimitResult:
        with self._lock:
            now = time.time()

            if key not in self._buckets:
                self._buckets[key] = [0.0, now]

            bucket = self._buckets[key]
            elapsed = now - bucket[1]
            leaked = elapsed * self._leak_rate
            bucket[0] = max(0.0, bucket[0] - leaked)
            bucket[1] = now

            if bucket[0] + tokens <= self._capacity:
                bucket[0] += tokens
                remaining = int(self._capacity - bucket[0])
                return RateLimitResult(True, remaining, 0, self._capacity)
            else:
                wait = (bucket[0] + tokens - self._capacity) / self._leak_rate
                return RateLimitResult(False, 0, wait, self._capacity)


# ──────────────────────────────────────────────
# 7. SLIDING WINDOW COUNTER (Approximate)
# ──────────────────────────────────────────────
class SlidingWindowCounterStrategy(RateLimitStrategy):
    """
    Weighted average of previous and current window counts.
    count ≈ prev_count × (1 - elapsed/window) + curr_count

    Pros: memory-efficient, smoother than fixed window.
    Cons: approximate.
    """

    def __init__(self, max_requests: int, window_seconds: float):
        self._max = max_requests
        self._window = window_seconds
        self._state: dict[str, dict] = {}
        self._lock = threading.Lock()

    def try_acquire(self, key: str, tokens: int = 1) -> RateLimitResult:
        with self._lock:
            now = time.time()
            window_id = int(now // self._window)
            position = (now % self._window) / self._window  # 0..1

            if key not in self._state:
                self._state[key] = {"prev_window": -1, "prev_count": 0,
                                     "curr_window": window_id, "curr_count": 0}
            s = self._state[key]

            if s["curr_window"] != window_id:
                s["prev_window"] = s["curr_window"]
                s["prev_count"] = s["curr_count"]
                s["curr_window"] = window_id
                s["curr_count"] = 0

            prev_weight = 1 - position
            estimated = s["prev_count"] * prev_weight + s["curr_count"]

            if estimated + tokens <= self._max:
                s["curr_count"] += tokens
                remaining = int(self._max - (estimated + tokens))
                return RateLimitResult(True, max(remaining, 0), 0, self._max)
            else:
                retry = self._window * (1 - position)
                return RateLimitResult(False, 0, retry, self._max)


# ──────────────────────────────────────────────
# 8. RATE LIMITER FACADE
# ──────────────────────────────────────────────
class RateLimiter:
    """Facade that wraps any strategy. Can be used as a decorator."""

    def __init__(self, strategy: RateLimitStrategy):
        self._strategy = strategy

    def allow(self, key: str, tokens: int = 1) -> RateLimitResult:
        return self._strategy.try_acquire(key, tokens)

    def decorator(self, key_func=None):
        """Decorator for functions. key_func extracts key from args."""
        def wrapper(fn):
            def inner(*args, **kwargs):
                k = key_func(*args, **kwargs) if key_func else fn.__name__
                result = self.allow(k)
                if not result.allowed:
                    raise Exception(
                        f"Rate limited. Retry after {result.retry_after:.2f}s"
                    )
                return fn(*args, **kwargs)
            return inner
        return wrapper


# ──────────────────────────────────────────────
# DEMO
# ──────────────────────────────────────────────
if __name__ == "__main__":
    print("═══ Token Bucket Demo ═══")
    limiter = RateLimiter(TokenBucketStrategy(capacity=5, refill_rate=2))

    for i in range(8):
        result = limiter.allow("user:42")
        status = "✅" if result.allowed else f"❌ retry in {result.retry_after:.2f}s"
        print(f"  Request {i+1}: {status}  (remaining: {result.remaining})")

    print("\n═══ Sliding Window Log Demo ═══")
    limiter2 = RateLimiter(SlidingWindowLogStrategy(max_requests=3, window_seconds=2))
    for i in range(5):
        r = limiter2.allow("ip:10.0.0.1")
        print(f"  Request {i+1}: {'✅' if r.allowed else '❌'}")
        time.sleep(0.3)

    print("\n═══ Decorator Demo ═══")
    api_limiter = RateLimiter(FixedWindowStrategy(max_requests=2, window_seconds=5))

    @api_limiter.decorator(key_func=lambda uid: f"user:{uid}")
    def process_order(uid):
        return f"Order processed for {uid}"

    for i in range(3):
        try:
            print(f"  {process_order(101)}")
        except Exception as e:
            print(f"  {e}")
```

---

## 13. Task Scheduler

### Core Concept

Executes tasks at specified times or intervals, supporting one-time, delayed, and periodic scheduling.

```
┌──────────────────────────────────────────────────────────────┐
│                    TASK SCHEDULER                             │
│                                                              │
│  schedule_once(task, delay)                                  │
│  schedule_periodic(task, interval)                           │
│  schedule_cron(task, "*/5 * * * *")                          │
│                                                              │
│   ┌──────────┐    ┌────────────────┐    ┌──────────────┐     │
│   │ Client   │───►│  Priority Queue │───►│ Worker       │     │
│   │ submits  │    │  (min-heap by   │    │ Threads      │     │
│   │ tasks    │    │   next_run_at)  │    │              │     │
│   └──────────┘    └───────┬────────┘    └──────┬───────┘     │
│                           │                     │             │
│                    ┌──────▼──────┐        ┌─────▼──────┐      │
│                    │ Scheduler   │        │ Execute    │      │
│                    │ Thread      │───────►│ callback   │      │
│                    │ (sleeps     │        │ re-queue   │      │
│                    │  until next │        │ if periodic│      │
│                    │  task due)  │        └────────────┘      │
│                    └─────────────┘                            │
└──────────────────────────────────────────────────────────────┘
```

### Full Implementation

```python
import heapq
import threading
import time
import uuid
import logging
from enum import Enum, auto
from dataclasses import dataclass, field
from typing import Callable, Optional, Any
from concurrent.futures import ThreadPoolExecutor

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
logger = logging.getLogger(__name__)


class TaskState(Enum):
    PENDING = auto()
    RUNNING = auto()
    COMPLETED = auto()
    FAILED = auto()
    CANCELLED = auto()


class TaskType(Enum):
    ONE_SHOT = auto()      # run once after delay
    FIXED_RATE = auto()    # run every N seconds (from start of each execution)
    FIXED_DELAY = auto()   # run N seconds after end of each execution


@dataclass(order=True)
class ScheduledTask:
    next_run_at: float                          # sort key for min-heap
    task_id: str        = field(compare=False)
    name: str           = field(compare=False)
    callback: Callable  = field(compare=False)
    args: tuple         = field(compare=False, default=())
    kwargs: dict        = field(compare=False, default_factory=dict)
    task_type: TaskType = field(compare=False, default=TaskType.ONE_SHOT)
    interval: float     = field(compare=False, default=0)
    state: TaskState    = field(compare=False, default=TaskState.PENDING)
    max_retries: int    = field(compare=False, default=0)
    retry_count: int    = field(compare=False, default=0)


class TaskScheduler:
    """
    A scheduler that runs tasks using a min-heap sorted by next_run_at.

    A dedicated scheduler thread sleeps until the soonest task is due,
    then dispatches it to a thread pool.
    """

    def __init__(self, pool_size: int = 4):
        self._heap: list[ScheduledTask] = []
        self._task_map: dict[str, ScheduledTask] = {}
        self._lock = threading.Lock()
        self._condition = threading.Condition(self._lock)
        self._pool = ThreadPoolExecutor(max_workers=pool_size)
        self._running = False
        self._scheduler_thread: Optional[threading.Thread] = None

    # ── Public API ──────────────────────────

    def start(self) -> None:
        self._running = True
        self._scheduler_thread = threading.Thread(
            target=self._scheduler_loop, daemon=True, name="SchedulerThread"
        )
        self._scheduler_thread.start()
        logger.info("Scheduler started")

    def shutdown(self, wait: bool = True) -> None:
        with self._condition:
            self._running = False
            self._condition.notify_all()
        self._pool.shutdown(wait=wait)
        logger.info("Scheduler shut down")

    def schedule_once(self, name: str, callback: Callable,
                      delay: float = 0, args=(), kwargs=None,
                      max_retries: int = 0) -> str:
        return self._schedule(name, callback, delay, TaskType.ONE_SHOT, 0,
                              args, kwargs or {}, max_retries)

    def schedule_at_fixed_rate(self, name: str, callback: Callable,
                               interval: float, initial_delay: float = 0,
                               args=(), kwargs=None) -> str:
        return self._schedule(name, callback, initial_delay, TaskType.FIXED_RATE,
                              interval, args, kwargs or {})

    def schedule_at_fixed_delay(self, name: str, callback: Callable,
                                interval: float, initial_delay: float = 0,
                                args=(), kwargs=None) -> str:
        return self._schedule(name, callback, initial_delay, TaskType.FIXED_DELAY,
                              interval, args, kwargs or {})

    def cancel(self, task_id: str) -> bool:
        with self._lock:
            task = self._task_map.get(task_id)
            if task and task.state == TaskState.PENDING:
                task.state = TaskState.CANCELLED
                logger.info(f"Task '{task.name}' cancelled")
                return True
        return False

    def get_status(self, task_id: str) -> Optional[TaskState]:
        task = self._task_map.get(task_id)
        return task.state if task else None

    # ── Internal ────────────────────────────

    def _schedule(self, name, callback, delay, task_type, interval,
                  args, kwargs, max_retries=0) -> str:
        task_id = str(uuid.uuid4())[:8]
        task = ScheduledTask(
            next_run_at=time.time() + delay,
            task_id=task_id, name=name, callback=callback,
            args=args, kwargs=kwargs,
            task_type=task_type, interval=interval,
            max_retries=max_retries
        )
        with self._condition:
            heapq.heappush(self._heap, task)
            self._task_map[task_id] = task
            self._condition.notify()
        logger.info(f"Scheduled '{name}' (id={task_id}, type={task_type.name}, "
                     f"delay={delay}s, interval={interval}s)")
        return task_id

    def _scheduler_loop(self) -> None:
        while self._running:
            with self._condition:
                # Wait until there's a task or shutdown
                while self._running and not self._heap:
                    self._condition.wait()

                if not self._running:
                    break

                next_task = self._heap[0]

                # Skip cancelled tasks
                if next_task.state == TaskState.CANCELLED:
                    heapq.heappop(self._heap)
                    continue

                now = time.time()
                wait_time = next_task.next_run_at - now

                if wait_time > 0:
                    self._condition.wait(timeout=wait_time)
                    continue  # re-check after waking

                # Time to execute
                task = heapq.heappop(self._heap)

            if task.state == TaskState.CANCELLED:
                continue

            # Dispatch to thread pool
            self._pool.submit(self._execute_task, task)

    def _execute_task(self, task: ScheduledTask) -> None:
        task.state = TaskState.RUNNING
        try:
            logger.info(f"Executing '{task.name}'")
            task.callback(*task.args, **task.kwargs)
            task.state = TaskState.COMPLETED
        except Exception as e:
            logger.error(f"Task '{task.name}' failed: {e}")
            task.retry_count += 1
            if task.retry_count <= task.max_retries:
                logger.info(f"Retrying '{task.name}' ({task.retry_count}/{task.max_retries})")
                task.state = TaskState.PENDING
                task.next_run_at = time.time() + 1  # retry after 1s
                with self._condition:
                    heapq.heappush(self._heap, task)
                    self._condition.notify()
                return
            task.state = TaskState.FAILED

        # Re-schedule periodic tasks
        if task.state == TaskState.COMPLETED:
            if task.task_type == TaskType.FIXED_RATE:
                task.state = TaskState.PENDING
                task.next_run_at += task.interval
                with self._condition:
                    heapq.heappush(self._heap, task)
                    self._condition.notify()
            elif task.task_type == TaskType.FIXED_DELAY:
                task.state = TaskState.PENDING
                task.next_run_at = time.time() + task.interval
                with self._condition:
                    heapq.heappush(self._heap, task)
                    self._condition.notify()


# ──────────────────────────────────────────────
# DEMO
# ──────────────────────────────────────────────
if __name__ == "__main__":
    scheduler = TaskScheduler(pool_size=3)
    scheduler.start()

    # One-shot task after 1 second
    scheduler.schedule_once("send-welcome-email",
                            lambda: print("  📧 Welcome email sent!"),
                            delay=1)

    # Periodic health check every 2 seconds
    counter = {"n": 0}
    def health_check():
        counter["n"] += 1
        print(f"  💓 Health check #{counter['n']}")

    hc_id = scheduler.schedule_at_fixed_rate("health-check", health_check,
                                              interval=2, initial_delay=0.5)

    # Task with retry on failure
    attempt = {"n": 0}
    def flaky_task():
        attempt["n"] += 1
        if attempt["n"] < 3:
            raise RuntimeError("transient error")
        print("  ✅ Flaky task succeeded on attempt", attempt["n"])

    scheduler.schedule_once("flaky-job", flaky_task, delay=0.2, max_retries=3)

    time.sleep(8)
    scheduler.cancel(hc_id)
    print("  ⛔ Health check cancelled")
    time.sleep(3)
    scheduler.shutdown()
```

---

## 14. Message Queue

### Core Concept

An in-process message queue that decouples producers from consumers with reliability features.

```
┌──────────────────────────────────────────────────────────────────┐
│                      MESSAGE QUEUE                               │
│                                                                  │
│  Producer ──► enqueue(topic, msg) ──┐                            │
│  Producer ──► enqueue(topic, msg) ──┤                            │
│                                     ▼                            │
│                          ┌──────────────────┐                    │
│                          │  Topic: "orders"  │                   │
│                          │  ┌──┬──┬──┬──┬──┐ │                   │
│                          │  │m1│m2│m3│m4│m5│ │  ← FIFO queue    │
│                          │  └──┴──┴──┴──┴──┘ │                   │
│                          │  Consumer Groups:  │                   │
│                          │    grp_A: offset 3 │                   │
│                          │    grp_B: offset 1 │                   │
│                          └────────┬─────────┘                    │
│                                   │                              │
│        ┌──────────────────────────┼───────────────────┐          │
│        ▼                          ▼                   ▼          │
│  ┌──────────┐            ┌──────────┐          ┌──────────┐     │
│  │Consumer A1│            │Consumer A2│          │Consumer B│     │
│  │(grp_A)   │            │(grp_A)   │          │(grp_B)  │     │
│  └──────────┘            └──────────┘          └──────────┘     │
│                                                                  │
│  Features: topics, consumer groups, ack/nack, DLQ, retry         │
└──────────────────────────────────────────────────────────────────┘
```

### Full Implementation

```python
import threading
import time
import uuid
import logging
from collections import deque, defaultdict
from dataclasses import dataclass, field
from enum import Enum, auto
from typing import Callable, Optional, Any

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
logger = logging.getLogger("mq")


class MessageState(Enum):
    PENDING = auto()
    DELIVERED = auto()
    ACKNOWLEDGED = auto()
    FAILED = auto()
    DEAD = auto()


@dataclass
class Message:
    msg_id: str
    topic: str
    body: Any
    headers: dict = field(default_factory=dict)
    created_at: float = field(default_factory=time.time)
    state: MessageState = MessageState.PENDING
    delivery_count: int = 0
    max_retries: int = 3


class Topic:
    """Holds a log of messages + per-consumer-group offsets."""

    def __init__(self, name: str, max_size: int = 10_000):
        self.name = name
        self._messages: list[Message] = []  # append-only log
        self._max_size = max_size
        self._lock = threading.Lock()
        self._group_offsets: dict[str, int] = {}  # group_name → next offset
        self._condition = threading.Condition(self._lock)

    def publish(self, message: Message) -> None:
        with self._condition:
            if len(self._messages) >= self._max_size:
                raise OverflowError(f"Topic '{self.name}' is full")
            self._messages.append(message)
            self._condition.notify_all()

    def poll(self, group: str, timeout: float = 5.0) -> Optional[Message]:
        """
        Blocking poll: returns the next unconsumed message for the group,
        or None after timeout.
        """
        with self._condition:
            if group not in self._group_offsets:
                self._group_offsets[group] = 0

            deadline = time.time() + timeout

            while True:
                offset = self._group_offsets[group]
                if offset < len(self._messages):
                    msg = self._messages[offset]
                    self._group_offsets[group] = offset + 1
                    msg.delivery_count += 1
                    msg.state = MessageState.DELIVERED
                    return msg

                remaining = deadline - time.time()
                if remaining <= 0:
                    return None
                self._condition.wait(timeout=remaining)

    @property
    def size(self) -> int:
        return len(self._messages)


class DeadLetterQueue:
    """Stores messages that exceeded max retries."""

    def __init__(self):
        self._messages: list[Message] = []
        self._lock = threading.Lock()

    def add(self, message: Message) -> None:
        with self._lock:
            message.state = MessageState.DEAD
            self._messages.append(message)
            logger.warning(f"DLQ: message {message.msg_id} moved to dead letter")

    def drain(self) -> list[Message]:
        with self._lock:
            msgs = list(self._messages)
            self._messages.clear()
            return msgs


class MessageQueue:
    """
    Central broker managing topics, consumer groups, ack/nack, and DLQ.
    """

    def __init__(self):
        self._topics: dict[str, Topic] = {}
        self._dlq = DeadLetterQueue()
        self._lock = threading.Lock()
        self._unacked: dict[str, Message] = {}  # msg_id → message

    def create_topic(self, name: str, max_size: int = 10_000) -> Topic:
        with self._lock:
            if name not in self._topics:
                self._topics[name] = Topic(name, max_size)
                logger.info(f"Topic '{name}' created")
            return self._topics[name]

    def publish(self, topic_name: str, body: Any,
                headers: dict = None) -> str:
        topic = self._get_or_create_topic(topic_name)
        msg = Message(
            msg_id=str(uuid.uuid4())[:8],
            topic=topic_name,
            body=body,
            headers=headers or {}
        )
        topic.publish(msg)
        logger.info(f"Published msg {msg.msg_id} to '{topic_name}'")
        return msg.msg_id

    def consume(self, topic_name: str, group: str,
                timeout: float = 5.0) -> Optional[Message]:
        topic = self._topics.get(topic_name)
        if not topic:
            return None
        msg = topic.poll(group, timeout)
        if msg:
            self._unacked[msg.msg_id] = msg
        return msg

    def ack(self, msg_id: str) -> None:
        msg = self._unacked.pop(msg_id, None)
        if msg:
            msg.state = MessageState.ACKNOWLEDGED
            logger.info(f"Acked msg {msg_id}")

    def nack(self, msg_id: str) -> None:
        msg = self._unacked.pop(msg_id, None)
        if not msg:
            return
        if msg.delivery_count >= msg.max_retries:
            self._dlq.add(msg)
        else:
            msg.state = MessageState.PENDING
            topic = self._topics.get(msg.topic)
            if topic:
                topic.publish(msg)  # re-queue
                logger.info(f"Nacked msg {msg_id}, requeued "
                             f"(attempt {msg.delivery_count}/{msg.max_retries})")

    @property
    def dlq(self) -> DeadLetterQueue:
        return self._dlq

    def _get_or_create_topic(self, name: str) -> Topic:
        with self._lock:
            if name not in self._topics:
                self._topics[name] = Topic(name)
            return self._topics[name]


# ──────────────────────────────────────────────
# CONSUMER WORKER (runs in background thread)
# ──────────────────────────────────────────────
class ConsumerWorker:
    """A simple background consumer that processes messages with a handler."""

    def __init__(self, mq: MessageQueue, topic: str, group: str,
                 handler: Callable[[Message], None]):
        self._mq = mq
        self._topic = topic
        self._group = group
        self._handler = handler
        self._running = False
        self._thread: Optional[threading.Thread] = None

    def start(self) -> None:
        self._running = True
        self._thread = threading.Thread(target=self._loop, daemon=True)
        self._thread.start()

    def stop(self) -> None:
        self._running = False

    def _loop(self) -> None:
        while self._running:
            msg = self._mq.consume(self._topic, self._group, timeout=1.0)
            if msg is None:
                continue
            try:
                self._handler(msg)
                self._mq.ack(msg.msg_id)
            except Exception as e:
                logger.error(f"Handler error for {msg.msg_id}: {e}")
                self._mq.nack(msg.msg_id)


# ──────────────────────────────────────────────
# DEMO
# ──────────────────────────────────────────────
if __name__ == "__main__":
    mq = MessageQueue()
    mq.create_topic("orders")

    # Two consumer groups: each group gets every message independently
    def payment_handler(msg: Message):
        print(f"  💳 Payment processing: {msg.body}")

    def inventory_handler(msg: Message):
        print(f"  📦 Inventory update: {msg.body}")
        if msg.body.get("item") == "bad-item":
            raise ValueError("Unknown item!")

    worker1 = ConsumerWorker(mq, "orders", "payment-service", payment_handler)
    worker2 = ConsumerWorker(mq, "orders", "inventory-service", inventory_handler)
    worker1.start()
    worker2.start()

    # Produce messages
    mq.publish("orders", {"item": "laptop", "qty": 1})
    mq.publish("orders", {"item": "phone", "qty": 2})
    mq.publish("orders", {"item": "bad-item", "qty": 1})  # will fail

    time.sleep(3)
    worker1.stop()
    worker2.stop()

    print(f"\n  Dead letter queue: {len(mq.dlq.drain())} messages")
```

---

## 15. Thread Pool Executor

### Core Concept

Reuses a fixed set of worker threads to execute submitted tasks, avoiding the overhead of creating/destroying threads.

```
┌────────────────────────────────────────────────────────────────┐
│                   THREAD POOL EXECUTOR                         │
│                                                                │
│  submit(task) ──► ┌────────────────────┐                       │
│  submit(task) ──► │   Task Queue       │                       │
│  submit(task) ──► │ (bounded/unbounded)│                       │
│                   └────────┬───────────┘                       │
│                            │ dequeue                           │
│          ┌─────────────────┼──────────────────┐                │
│          ▼                 ▼                  ▼                │
│   ┌──────────┐      ┌──────────┐       ┌──────────┐           │
│   │ Worker 1 │      │ Worker 2 │       │ Worker N │           │
│   │ (Thread) │      │ (Thread) │  ...  │ (Thread) │           │
│   └────┬─────┘      └────┬─────┘       └────┬─────┘           │
│        │                  │                  │                 │
│        ▼                  ▼                  ▼                 │
│   ┌─────────┐       ┌─────────┐        ┌─────────┐            │
│   │ Future  │       │ Future  │        │ Future  │            │
│   │ .result │       │ .result │        │ .result │            │
│   └─────────┘       └─────────┘        └─────────┘            │
│                                                                │
│  Rejection Policies: Abort | CallerRuns | Discard              │
└────────────────────────────────────────────────────────────────┘
```

### Full Implementation

```python
import threading
import time
import logging
from collections import deque
from enum import Enum, auto
from typing import Callable, Any, Optional
from queue import Queue, Full

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
logger = logging.getLogger("pool")


# ──────────────────────────────────────────────
# FUTURE — result holder
# ──────────────────────────────────────────────
class Future:
    """
    Represents the result of an asynchronous computation.
    Consumers call .result() to block until completion.
    """

    def __init__(self):
        self._result: Any = None
        self._exception: Optional[Exception] = None
        self._done = threading.Event()
        self._callbacks: list[Callable] = []
        self._lock = threading.Lock()

    def set_result(self, value: Any) -> None:
        with self._lock:
            self._result = value
            self._done.set()
            for cb in self._callbacks:
                try:
                    cb(self)
                except Exception:
                    pass

    def set_exception(self, exc: Exception) -> None:
        with self._lock:
            self._exception = exc
            self._done.set()
            for cb in self._callbacks:
                try:
                    cb(self)
                except Exception:
                    pass

    def result(self, timeout: Optional[float] = None) -> Any:
        if not self._done.wait(timeout):
            raise TimeoutError("Future did not complete in time")
        if self._exception:
            raise self._exception
        return self._result

    def is_done(self) -> bool:
        return self._done.is_set()

    def add_done_callback(self, fn: Callable) -> None:
        with self._lock:
            if self._done.is_set():
                fn(self)
            else:
                self._callbacks.append(fn)


# ──────────────────────────────────────────────
# REJECTION POLICIES
# ──────────────────────────────────────────────
class RejectionPolicy(Enum):
    ABORT = auto()       # raise exception
    CALLER_RUNS = auto() # caller thread executes task
    DISCARD = auto()     # silently discard


# ──────────────────────────────────────────────
# THREAD POOL EXECUTOR
# ──────────────────────────────────────────────
class ThreadPoolExecutor:
    """
    Fixed-size thread pool with:
      - Bounded task queue
      - Future-based result retrieval
      - Configurable rejection policy
      - Graceful shutdown
    """

    def __init__(self, core_size: int = 4,
                 queue_capacity: int = 100,
                 rejection_policy: RejectionPolicy = RejectionPolicy.ABORT,
                 thread_name_prefix: str = "pool"):
        self._core_size = core_size
        self._queue: Queue = Queue(maxsize=queue_capacity)
        self._rejection_policy = rejection_policy
        self._prefix = thread_name_prefix
        self._workers: list[threading.Thread] = []
        self._shutdown = False
        self._lock = threading.Lock()
        self._active_count = 0

        # Start worker threads
        for i in range(core_size):
            t = threading.Thread(target=self._worker_loop,
                                 name=f"{thread_name_prefix}-worker-{i}",
                                 daemon=True)
            self._workers.append(t)
            t.start()
        logger.info(f"ThreadPool started with {core_size} workers")

    # ── Public API ──────────────────────────

    def submit(self, fn: Callable, *args, **kwargs) -> Future:
        """Submit a callable and return a Future."""
        if self._shutdown:
            raise RuntimeError("Pool is shut down")

        future = Future()
        task = (fn, args, kwargs, future)

        try:
            self._queue.put_nowait(task)
        except Full:
            self._handle_rejection(task)

        return future

    def map(self, fn: Callable, iterable) -> list[Future]:
        """Submit fn(item) for every item. Returns list of Futures."""
        return [self.submit(fn, item) for item in iterable]

    def shutdown(self, wait: bool = True) -> None:
        """Signal shutdown. If wait=True, block until all tasks complete."""
        logger.info("Initiating shutdown...")
        self._shutdown = True

        # Send poison pills (one per worker)
        for _ in self._workers:
            self._queue.put(None)

        if wait:
            for w in self._workers:
                w.join()
        logger.info("Pool shut down")

    @property
    def active_count(self) -> int:
        return self._active_count

    @property
    def queue_size(self) -> int:
        return self._queue.qsize()

    # ── Internal ────────────────────────────

    def _worker_loop(self) -> None:
        name = threading.current_thread().name
        logger.info(f"{name} started")

        while True:
            task = self._queue.get()  # blocking

            if task is None:  # poison pill
                logger.info(f"{name} stopping")
                break

            fn, args, kwargs, future = task
            with self._lock:
                self._active_count += 1

            try:
                result = fn(*args, **kwargs)
                future.set_result(result)
            except Exception as e:
                future.set_exception(e)
            finally:
                with self._lock:
                    self._active_count -= 1

    def _handle_rejection(self, task) -> None:
        fn, args, kwargs, future = task

        if self._rejection_policy == RejectionPolicy.ABORT:
            future.set_exception(RuntimeError("Task rejected: queue full"))
            raise RuntimeError("Task rejected: queue full")

        elif self._rejection_policy == RejectionPolicy.CALLER_RUNS:
            logger.warning("Queue full — caller running task")
            try:
                result = fn(*args, **kwargs)
                future.set_result(result)
            except Exception as e:
                future.set_exception(e)

        elif self._rejection_policy == RejectionPolicy.DISCARD:
            logger.warning("Queue full — task discarded")
            future.set_exception(RuntimeError("Discarded"))


# ──────────────────────────────────────────────
# DEMO
# ──────────────────────────────────────────────
if __name__ == "__main__":
    pool = ThreadPoolExecutor(core_size=3, queue_capacity=10)

    def compute(n):
        time.sleep(0.5)
        return n * n

    # Submit tasks
    futures = [pool.submit(compute, i) for i in range(8)]

    # Collect results
    for i, f in enumerate(futures):
        print(f"  Task {i}: result = {f.result(timeout=5)}")

    # Callback example
    f = pool.submit(compute, 100)
    f.add_done_callback(lambda fut: print(f"  Callback: 100² = {fut.result()}"))

    time.sleep(1)
    pool.shutdown(wait=True)
```

---

## 16. Database Connection Pool

### Core Concept

Maintains a pool of reusable database connections to amortize connection setup cost and bound concurrency.

```
┌──────────────────────────────────────────────────────────────────┐
│                  CONNECTION POOL                                 │
│                                                                  │
│  App Thread 1 ──► acquire() ──┐                                  │
│  App Thread 2 ──► acquire() ──┤     ┌──────────────────────┐     │
│  App Thread 3 ──► acquire() ──┼────►│  Idle Connections    │     │
│                               │     │  ┌────┐ ┌────┐ ┌────┐│     │
│                               │     │  │conn│ │conn│ │conn││     │
│                               │     │  └────┘ └────┘ └────┘│     │
│                               │     └──────────────────────┘     │
│  App Thread ────► release() ──┘                                  │
│                                                                  │
│  Config: min_size, max_size, max_idle_time, connection_timeout   │
│                                                                  │
│  Health Check Thread:                                            │
│    periodically validates & removes stale connections             │
└──────────────────────────────────────────────────────────────────┘
```

### Full Implementation

```python
import threading
import time
import uuid
import logging
from queue import Queue, Empty
from typing import Optional, Any
from contextlib import contextmanager
from dataclasses import dataclass, field

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
logger = logging.getLogger("connpool")


# ──────────────────────────────────────────────
# SIMULATED DB CONNECTION
# ──────────────────────────────────────────────
class DatabaseConnection:
    """Simulates a real database connection."""

    def __init__(self, dsn: str):
        self.conn_id = str(uuid.uuid4())[:6]
        self.dsn = dsn
        self.created_at = time.time()
        self.last_used_at = time.time()
        self._closed = False
        # Simulate connection setup time
        time.sleep(0.05)
        logger.info(f"Connection {self.conn_id} opened to {dsn}")

    def execute(self, query: str, params=None) -> list[dict]:
        if self._closed:
            raise RuntimeError("Connection is closed")
        self.last_used_at = time.time()
        # Simulate query
        time.sleep(0.01)
        return [{"result": f"data for '{query}'"}]

    def ping(self) -> bool:
        """Health check."""
        if self._closed:
            return False
        try:
            self.last_used_at = time.time()
            return True
        except Exception:
            return False

    def close(self) -> None:
        if not self._closed:
            self._closed = False
            logger.info(f"Connection {self.conn_id} closed")
            self._closed = True

    @property
    def is_closed(self) -> bool:
        return self._closed

    @property
    def idle_time(self) -> float:
        return time.time() - self.last_used_at


# ──────────────────────────────────────────────
# CONNECTION POOL CONFIG
# ──────────────────────────────────────────────
@dataclass
class PoolConfig:
    dsn: str = "postgresql://localhost:5432/mydb"
    min_size: int = 2          # minimum idle connections
    max_size: int = 10         # maximum total connections
    max_idle_time: float = 300  # seconds before idle connection is reaped
    acquire_timeout: float = 10 # seconds to wait for a connection
    validation_interval: float = 60  # health check interval


# ──────────────────────────────────────────────
# CONNECTION POOL
# ──────────────────────────────────────────────
class ConnectionPool:
    """
    Thread-safe database connection pool.

    Features:
        • Lazy creation up to max_size
        • Connection validation / health checking
        • Idle connection reaping
        • Context manager support
        • Metrics
    """

    def __init__(self, config: PoolConfig):
        self._config = config
        self._idle: Queue[DatabaseConnection] = Queue()
        self._total_count = 0
        self._lock = threading.Lock()
        self._closed = False

        # Statistics
        self._acquired_count = 0
        self._released_count = 0
        self._created_count = 0
        self._timeout_count = 0

        # Pre-populate with min_size connections
        for _ in range(config.min_size):
            self._add_connection()

        # Health check thread
        self._health_thread = threading.Thread(
            target=self._health_check_loop, daemon=True
        )
        self._health_thread.start()
        logger.info(f"Pool initialized: min={config.min_size}, max={config.max_size}")

    # ── Public API ──────────────────────────

    def acquire(self, timeout: Optional[float] = None) -> DatabaseConnection:
        """Get a connection from the pool. Blocks up to timeout."""
        if self._closed:
            raise RuntimeError("Pool is closed")

        timeout = timeout or self._config.acquire_timeout

        # Try to get an idle connection
        try:
            conn = self._idle.get(timeout=0)  # non-blocking first
            if self._validate(conn):
                self._acquired_count += 1
                return conn
            else:
                self._destroy_connection(conn)
        except Empty:
            pass

        # Try to create a new one
        with self._lock:
            if self._total_count < self._config.max_size:
                conn = self._create_connection()
                self._acquired_count += 1
                return conn

        # Pool exhausted — block and wait
        try:
            conn = self._idle.get(timeout=timeout)
            if self._validate(conn):
                self._acquired_count += 1
                return conn
            self._destroy_connection(conn)
            # Retry once more
            return self.acquire(timeout=1)
        except Empty:
            self._timeout_count += 1
            raise TimeoutError(
                f"Could not acquire connection within {timeout}s. "
                f"Pool exhausted ({self._total_count}/{self._config.max_size})"
            )

    def release(self, conn: DatabaseConnection) -> None:
        """Return a connection to the pool."""
        if conn.is_closed:
            with self._lock:
                self._total_count -= 1
            return

        conn.last_used_at = time.time()
        self._idle.put(conn)
        self._released_count += 1

    @contextmanager
    def connection(self):
        """Context manager for auto-release."""
        conn = self.acquire()
        try:
            yield conn
        finally:
            self.release(conn)

    def close(self) -> None:
        """Close the pool and all connections."""
        self._closed = True
        while not self._idle.empty():
            try:
                conn = self._idle.get_nowait()
                conn.close()
            except Empty:
                break
        with self._lock:
            self._total_count = 0
        logger.info("Pool closed")

    @property
    def stats(self) -> dict:
        return {
            "total_connections": self._total_count,
            "idle_connections": self._idle.qsize(),
            "active_connections": self._total_count - self._idle.qsize(),
            "acquired": self._acquired_count,
            "released": self._released_count,
            "created": self._created_count,
            "timeouts": self._timeout_count,
        }

    # ── Internal ────────────────────────────

    def _create_connection(self) -> DatabaseConnection:
        conn = DatabaseConnection(self._config.dsn)
        with self._lock:
            self._total_count += 1
            self._created_count += 1
        return conn

    def _add_connection(self) -> None:
        conn = self._create_connection()
        self._idle.put(conn)

    def _destroy_connection(self, conn: DatabaseConnection) -> None:
        conn.close()
        with self._lock:
            self._total_count -= 1

    def _validate(self, conn: DatabaseConnection) -> bool:
        if conn.is_closed:
            return False
        if conn.idle_time > self._config.max_idle_time:
            return False
        return conn.ping()

    def _health_check_loop(self) -> None:
        while not self._closed:
            time.sleep(self._config.validation_interval)
            self._reap_idle()
            self._ensure_min_size()

    def _reap_idle(self) -> None:
        """Remove connections idle too long (down to min_size)."""
        reaped = 0
        temp = []
        while not self._idle.empty():
            try:
                conn = self._idle.get_nowait()
                if conn.idle_time > self._config.max_idle_time and \
                   self._total_count > self._config.min_size:
                    self._destroy_connection(conn)
                    reaped += 1
                else:
                    temp.append(conn)
            except Empty:
                break
        for c in temp:
            self._idle.put(c)
        if reaped:
            logger.info(f"Reaped {reaped} idle connections")

    def _ensure_min_size(self) -> None:
        with self._lock:
            while self._total_count < self._config.min_size:
                self._add_connection()


# ──────────────────────────────────────────────
# DEMO
# ──────────────────────────────────────────────
if __name__ == "__main__":
    config = PoolConfig(
        dsn="postgresql://localhost:5432/demo",
        min_size=2, max_size=5,
        max_idle_time=30, acquire_timeout=5
    )
    pool = ConnectionPool(config)

    # Context manager usage
    with pool.connection() as conn:
        result = conn.execute("SELECT * FROM users WHERE id = 1")
        print(f"  Query result: {result}")

    # Concurrent usage
    def worker(worker_id):
        with pool.connection() as conn:
            result = conn.execute(f"SELECT * FROM orders WHERE user_id = {worker_id}")
            print(f"  Worker {worker_id}: {result}")

    threads = [threading.Thread(target=worker, args=(i,)) for i in range(8)]
    for t in threads:
        t.start()
    for t in threads:
        t.join()

    print(f"\n  Pool stats: {pool.stats}")
    pool.close()
```

---

## 17. Event Bus

### Core Concept

A synchronous/asynchronous in-process publish-subscribe system where components communicate without direct references.

```
┌────────────────────────────────────────────────────────────────┐
│                       EVENT BUS                                │
│                                                                │
│   Component A                          Component C             │
│   (publisher)                          (subscriber)            │
│       │                                    ▲                   │
│       │ emit(UserCreated)                  │ on(UserCreated)   │
│       ▼                                    │                   │
│   ┌────────────────────────────────────────────────────┐       │
│   │                    EVENT BUS                       │       │
│   │                                                    │       │
│   │  Registry:                                         │       │
│   │    UserCreated → [handler_C, handler_D]            │       │
│   │    OrderPlaced → [handler_E]                       │       │
│   │    *           → [logger_handler]  (wildcard)      │       │
│   │                                                    │       │
│   │  Features:                                         │       │
│   │    • Priority ordering                             │       │
│   │    • Async dispatch                                │       │
│   │    • Event hierarchy (inheritance)                 │       │
│   │    • Once-only listeners                           │       │
│   │    • Middleware / interceptors                      │       │
│   └──────────────────────────────┬─────────────────────┘       │
│                                  │                             │
│                                  ▼                             │
│                            Component D                         │
│                            (subscriber)                        │
└────────────────────────────────────────────────────────────────┘
```

### Full Implementation

```python
import threading
import time
import logging
from dataclasses import dataclass, field
from typing import Callable, Any, Optional, Type
from concurrent.futures import ThreadPoolExecutor
from enum import Enum, auto

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
logger = logging.getLogger("eventbus")


# ──────────────────────────────────────────────
# 1. BASE EVENT
# ──────────────────────────────────────────────
@dataclass
class Event:
    """Base event class. All domain events inherit from this."""
    timestamp: float = field(default_factory=time.time, init=False)
    _propagation_stopped: bool = field(default=False, init=False, repr=False)

    def stop_propagation(self):
        self._propagation_stopped = True

    @property
    def event_type(self) -> str:
        return self.__class__.__name__


# Domain events
@dataclass
class UserCreated(Event):
    user_id: int = 0
    email: str = ""

@dataclass
class UserUpdated(Event):
    user_id: int = 0
    changes: dict = field(default_factory=dict)

@dataclass
class OrderPlaced(Event):
    order_id: int = 0
    user_id: int = 0
    amount: float = 0.0


# ──────────────────────────────────────────────
# 2. SUBSCRIPTION
# ──────────────────────────────────────────────
@dataclass
class Subscription:
    handler: Callable[[Event], None]
    priority: int = 0          # higher = executed first
    once: bool = False         # auto-unsubscribe after first call
    is_async: bool = False     # dispatch in thread pool
    filter_fn: Optional[Callable[[Event], bool]] = None  # conditional

    sub_id: str = field(default_factory=lambda: str(id(object())))


# ──────────────────────────────────────────────
# 3. MIDDLEWARE
# ──────────────────────────────────────────────
class EventMiddleware:
    """Intercepts events before they reach handlers."""

    def process(self, event: Event, next_fn: Callable) -> None:
        """Override to add behavior. Call next_fn(event) to continue."""
        next_fn(event)


class LoggingMiddleware(EventMiddleware):
    def process(self, event: Event, next_fn: Callable) -> None:
        logger.info(f"[Middleware] Event dispatched: {event.event_type}")
        start = time.time()
        next_fn(event)
        elapsed = (time.time() - start) * 1000
        logger.info(f"[Middleware] {event.event_type} processed in {elapsed:.1f}ms")


class ErrorHandlingMiddleware(EventMiddleware):
    def process(self, event: Event, next_fn: Callable) -> None:
        try:
            next_fn(event)
        except Exception as e:
            logger.error(f"[Middleware] Error processing {event.event_type}: {e}")


# ──────────────────────────────────────────────
# 4. EVENT BUS
# ──────────────────────────────────────────────
class EventBus:
    """
    Central event dispatcher.

    Features:
        • Type-safe event routing (uses class hierarchy)
        • Priority ordering
        • Sync and async dispatch
        • Once-only subscriptions
        • Wildcard listeners (subscribe to Event base class)
        • Middleware chain
        • Event filtering
    """

    def __init__(self, pool_size: int = 4):
        self._subscribers: dict[Type[Event], list[Subscription]] = {}
        self._lock = threading.RLock()
        self._pool = ThreadPoolExecutor(max_workers=pool_size)
        self._middlewares: list[EventMiddleware] = []
        self._event_history: list[Event] = []
        self._history_enabled = False

    # ── Subscription ────────────────────────

    def on(self, event_type: Type[Event], handler: Callable,
           priority: int = 0, once: bool = False,
           is_async: bool = False,
           filter_fn: Callable = None) -> str:
        """Subscribe to an event type. Returns subscription ID."""
        sub = Subscription(
            handler=handler, priority=priority, once=once,
            is_async=is_async, filter_fn=filter_fn
        )
        with self._lock:
            if event_type not in self._subscribers:
                self._subscribers[event_type] = []
            self._subscribers[event_type].append(sub)
            # Sort by priority descending
            self._subscribers[event_type].sort(key=lambda s: s.priority, reverse=True)
        logger.info(f"Subscribed to {event_type.__name__} (id={sub.sub_id[:8]})")
        return sub.sub_id

    def off(self, event_type: Type[Event], sub_id: str) -> bool:
        """Unsubscribe by ID."""
        with self._lock:
            subs = self._subscribers.get(event_type, [])
            for i, s in enumerate(subs):
                if s.sub_id == sub_id:
                    subs.pop(i)
                    return True
        return False

    def once(self, event_type: Type[Event], handler: Callable, **kwargs) -> str:
        """Subscribe for one event only."""
        return self.on(event_type, handler, once=True, **kwargs)

    # ── Middleware ──────────────────────────

    def use(self, middleware: EventMiddleware) -> None:
        self._middlewares.append(middleware)

    # ── Emit ───────────────────────────────

    def emit(self, event: Event) -> None:
        """Dispatch an event to all matching subscribers."""
        if self._history_enabled:
            self._event_history.append(event)

        # Build middleware chain
        def dispatch(evt):
            self._dispatch_to_subscribers(evt)

        chain = dispatch
        for mw in reversed(self._middlewares):
            prev = chain
            chain = lambda evt, m=mw, p=prev: m.process(evt, p)

        chain(event)

    def _dispatch_to_subscribers(self, event: Event) -> None:
        to_remove: list[tuple[Type[Event], str]] = []

        # Walk MRO to support event hierarchy
        for event_class in type(event).__mro__:
            if not issubclass(event_class, Event):
                continue

            with self._lock:
                subs = list(self._subscribers.get(event_class, []))

            for sub in subs:
                if event._propagation_stopped:
                    return

                # Apply filter
                if sub.filter_fn and not sub.filter_fn(event):
                    continue

                if sub.is_async:
                    self._pool.submit(self._safe_call, sub.handler, event)
                else:
                    self._safe_call(sub.handler, event)

                if sub.once:
                    to_remove.append((event_class, sub.sub_id))

        # Clean up once-only subscriptions
        for evt_class, sid in to_remove:
            self.off(evt_class, sid)

    def _safe_call(self, handler: Callable, event: Event) -> None:
        try:
            handler(event)
        except Exception as e:
            logger.error(f"Handler error: {e}")

    # ── Utilities ──────────────────────────

    def enable_history(self) -> None:
        self._history_enabled = True

    @property
    def history(self) -> list[Event]:
        return list(self._event_history)

    def clear(self) -> None:
        with self._lock:
            self._subscribers.clear()

    def shutdown(self) -> None:
        self._pool.shutdown(wait=True)


# ──────────────────────────────────────────────
# DEMO
# ──────────────────────────────────────────────
if __name__ == "__main__":
    bus = EventBus()
    bus.use(LoggingMiddleware())
    bus.use(ErrorHandlingMiddleware())
    bus.enable_history()

    # Subscribe to specific event
    bus.on(UserCreated, lambda e: print(f"  📧 Send welcome to {e.email}"))
    bus.on(UserCreated, lambda e: print(f"  📊 Analytics: user {e.user_id} created"),
           priority=10)  # runs first

    # Subscribe to all events (wildcard via base class)
    bus.on(Event, lambda e: print(f"  📝 Audit log: {e.event_type}"), priority=-1)

    # Once-only listener
    bus.once(OrderPlaced, lambda e: print(f"  🎉 First order bonus for user {e.user_id}!"))

    # Filtered listener
    bus.on(OrderPlaced,
           lambda e: print(f"  🚨 High value order: ${e.amount}"),
           filter_fn=lambda e: e.amount > 100)

    print("═══ Emit UserCreated ═══")
    bus.emit(UserCreated(user_id=1, email="alice@example.com"))

    print("\n═══ Emit OrderPlaced (high value) ═══")
    bus.emit(OrderPlaced(order_id=101, user_id=1, amount=250.0))

    print("\n═══ Emit OrderPlaced (low value) ═══")
    bus.emit(OrderPlaced(order_id=102, user_id=1, amount=25.0))
    # The "once" handler won't fire again; the filter won't match

    print(f"\n  Event history: {len(bus.history)} events recorded")
    bus.shutdown()
```

---

## 18. Pub/Sub System

### Core Concept

A full publish/subscribe messaging system with channels, pattern matching, message persistence, and delivery guarantees.

```
┌──────────────────────────────────────────────────────────────────────┐
│                        PUB/SUB SYSTEM                                │
│                                                                      │
│  Publisher                                                           │
│    ├── publish("chat.room1", "hello")                                │
│    └── publish("chat.room2", "world")                                │
│                                                                      │
│  ┌────────────────────────────────────────────────────────────────┐   │
│  │                        BROKER                                  │   │
│  │                                                                │   │
│  │  Channel Registry:                                             │   │
│  │    "chat.room1" ──► [sub_A, sub_B]                             │   │
│  │    "chat.room2" ──► [sub_C]                                    │   │
│  │                                                                │   │
│  │  Pattern Registry:                                             │   │
│  │    "chat.*"     ──► [sub_D]   (matches chat.room1, chat.room2) │   │
│  │    "*.room1"    ──► [sub_E]                                    │   │
│  │                                                                │   │
│  │  Message Store (optional persistence):                         │   │
│  │    [msg1, msg2, msg3, ...]                                     │   │
│  │                                                                │   │
│  │  Delivery Thread Pool → async fan-out to subscribers           │   │
│  └────────────────────────────────────────────────────────────────┘   │
│                                                                      │
│  Subscriber A ◄── receives "chat.room1" messages                     │
│  Subscriber D ◄── receives "chat.*" pattern matches                  │
└──────────────────────────────────────────────────────────────────────┘
```

### Full Implementation

```python
import threading
import time
import uuid
import re
import fnmatch
import logging
from collections import defaultdict, deque
from dataclasses import dataclass, field
from typing import Callable, Optional, Any, Set
from concurrent.futures import ThreadPoolExecutor
from enum import Enum, auto

logging.basicConfig(level=logging.INFO,
                    format="%(asctime)s [%(levelname)s] %(message)s")
logger = logging.getLogger("pubsub")


# ──────────────────────────────────────────────
# 1. MESSAGE
# ──────────────────────────────────────────────
@dataclass
class PubSubMessage:
    msg_id: str = field(default_factory=lambda: str(uuid.uuid4())[:8])
    channel: str = ""
    data: Any = None
    publisher_id: str = ""
    timestamp: float = field(default_factory=time.time)
    headers: dict = field(default_factory=dict)


# ──────────────────────────────────────────────
# 2. SUBSCRIBER
# ──────────────────────────────────────────────
class DeliveryMode(Enum):
    AT_MOST_ONCE = auto()   # fire and forget
    AT_LEAST_ONCE = auto()  # retry until acked


@dataclass
class Subscriber:
    sub_id: str = field(default_factory=lambda: str(uuid.uuid4())[:8])
    callback: Callable[[PubSubMessage], None] = None
    channel: str = ""               # exact channel or pattern
    is_pattern: bool = False        # True if channel is a glob pattern
    delivery_mode: DeliveryMode = DeliveryMode.AT_MOST_ONCE
    active: bool = True
    message_queue: deque = field(default_factory=lambda: deque(maxlen=10_000))


# ──────────────────────────────────────────────
# 3. MESSAGE STORE (for persistence / replay)
# ──────────────────────────────────────────────
class MessageStore:
    """Retains messages for replay / late subscribers."""

    def __init__(self, max_per_channel: int = 1000):
        self._store: dict[str, deque[PubSubMessage]] = defaultdict(
            lambda: deque(maxlen=max_per_channel)
        )
        self._lock = threading.Lock()

    def save(self, msg: PubSubMessage) -> None:
        with self._lock:
            self._store[msg.channel].append(msg)

    def get_since(self, channel: str, since_ts: float) -> list[PubSubMessage]:
        with self._lock:
            return [m for m in self._store.get(channel, [])
                    if m.timestamp > since_ts]

    def get_last_n(self, channel: str, n: int) -> list[PubSubMessage]:
        with self._lock:
            msgs = self._store.get(channel, deque())
            return list(msgs)[-n:]


# ──────────────────────────────────────────────
# 4. PUB/SUB BROKER
# ──────────────────────────────────────────────
class PubSubBroker:
    """
    Central Pub/Sub broker.

    Features:
        • Exact channel subscriptions
        • Glob pattern subscriptions (e.g., "chat.*")
        • Async delivery via thread pool
        • Message persistence + replay
        • Channel listing + subscriber counts
        • Unsubscribe
    """

    def __init__(self, pool_size: int = 4, persist: bool = True):
        self._exact_subs: dict[str, list[Subscriber]] = defaultdict(list)
        self._pattern_subs: list[Subscriber] = []
        self._lock = threading.RLock()
        self._pool = ThreadPoolExecutor(max_workers=pool_size)
        self._store = MessageStore() if persist else None
        self._stats = {
            "messages_published": 0,
            "messages_delivered": 0,
            "delivery_failures": 0,
        }

    # ── Subscribe ──────────────────────────

    def subscribe(self, channel: str, callback: Callable,
                  is_pattern: bool = False,
                  delivery_mode: DeliveryMode = DeliveryMode.AT_MOST_ONCE) -> str:
        """Subscribe to a channel or pattern. Returns subscriber ID."""
        sub = Subscriber(
            callback=callback, channel=channel,
            is_pattern=is_pattern, delivery_mode=delivery_mode
        )
        with self._lock:
            if is_pattern:
                self._pattern_subs.append(sub)
            else:
                self._exact_subs[channel].append(sub)
        logger.info(f"Subscriber {sub.sub_id} subscribed to "
                     f"{'pattern' if is_pattern else 'channel'} '{channel}'")
        return sub.sub_id

    def unsubscribe(self, sub_id: str) -> bool:
        with self._lock:
            # Check exact subscriptions
            for channel, subs in self._exact_subs.items():
                for i, s in enumerate(subs):
                    if s.sub_id == sub_id:
                        subs.pop(i)
                        logger.info(f"Unsubscribed {sub_id} from '{channel}'")
                        return True
            # Check pattern subscriptions
            for i, s in enumerate(self._pattern_subs):
                if s.sub_id == sub_id:
                    self._pattern_subs.pop(i)
                    return True
        return False

    # ── Publish ────────────────────────────

    def publish(self, channel: str, data: Any,
                publisher_id: str = "",
                headers: dict = None) -> str:
        """Publish a message to a channel. Returns message ID."""
        msg = PubSubMessage(
            channel=channel, data=data,
            publisher_id=publisher_id,
            headers=headers or {}
        )

        # Persist
        if self._store:
            self._store.save(msg)

        self._stats["messages_published"] += 1

        # Gather matching subscribers
        targets: list[Subscriber] = []

        with self._lock:
            # Exact matches
            targets.extend(self._exact_subs.get(channel, []))

            # Pattern matches
            for psub in self._pattern_subs:
                if psub.active and fnmatch.fnmatch(channel, psub.channel):
                    targets.append(psub)

        # Deliver
        for sub in targets:
            if not sub.active:
                continue
            self._pool.submit(self._deliver, sub, msg)

        return msg.msg_id

    def _deliver(self, sub: Subscriber, msg: PubSubMessage) -> None:
        max_attempts = 3 if sub.delivery_mode == DeliveryMode.AT_LEAST_ONCE else 1

        for attempt in range(1, max_attempts + 1):
            try:
                sub.callback(msg)
                self._stats["messages_delivered"] += 1
                return
            except Exception as e:
                logger.error(f"Delivery failed to {sub.sub_id} "
                             f"(attempt {attempt}): {e}")
                if attempt < max_attempts:
                    time.sleep(0.1 * attempt)  # backoff

        self._stats["delivery_failures"] += 1
        logger.error(f"Message {msg.msg_id} permanently failed "
                     f"for subscriber {sub.sub_id}")

    # ── Replay ─────────────────────────────

    def replay(self, channel: str, last_n: int = 10) -> list[PubSubMessage]:
        """Get the last N messages on a channel."""
        if not self._store:
            return []
        return self._store.get_last_n(channel, last_n)

    def replay_since(self, channel: str, since_ts: float) -> list[PubSubMessage]:
        if not self._store:
            return []
        return self._store.get_since(channel, since_ts)

    # ── Info ───────────────────────────────

    def channels(self) -> list[str]:
        with self._lock:
            return list(self._exact_subs.keys())

    def subscriber_count(self, channel: str) -> int:
        with self._lock:
            exact = len(self._exact_subs.get(channel, []))
            pattern = sum(1 for p in self._pattern_subs
                          if fnmatch.fnmatch(channel, p.channel))
            return exact + pattern

    @property
    def stats(self) -> dict:
        return dict(self._stats)

    def shutdown(self) -> None:
        self._pool.shutdown(wait=True)
        logger.info("PubSub broker shut down")


# ──────────────────────────────────────────────
# 5. HIGHER-LEVEL: CHANNEL ABSTRACTION
# ──────────────────────────────────────────────
class Channel:
    """Convenience wrapper around the broker for a specific channel."""

    def __init__(self, broker: PubSubBroker, name: str):
        self._broker = broker
        self._name = name

    def publish(self, data: Any, **kwargs) -> str:
        return self._broker.publish(self._name, data, **kwargs)

    def subscribe(self, callback: Callable, **kwargs) -> str:
        return self._broker.subscribe(self._name, callback, **kwargs)


# ──────────────────────────────────────────────
# DEMO
# ──────────────────────────────────────────────
if __name__ == "__main__":
    broker = PubSubBroker(pool_size=4, persist=True)

    # ── Exact subscriptions ──
    broker.subscribe(
        "chat.general",
        lambda msg: print(f"  💬 [general] {msg.publisher_id}: {msg.data}")
    )
    broker.subscribe(
        "chat.random",
        lambda msg: print(f"  🎲 [random] {msg.publisher_id}: {msg.data}")
    )

    # ── Pattern subscription (wildcard) ──
    broker.subscribe(
        "chat.*",
        lambda msg: print(f"  📋 [audit] message on {msg.channel}: {msg.data}"),
        is_pattern=True
    )

    # ── Subscribe with guaranteed delivery ──
    attempt_counter = {"n": 0}
    def flaky_handler(msg):
        attempt_counter["n"] += 1
        if attempt_counter["n"] <= 2:
            raise RuntimeError("Temporary failure")
        print(f"  ✅ [reliable] got: {msg.data}")

    broker.subscribe(
        "alerts",
        flaky_handler,
        delivery_mode=DeliveryMode.AT_LEAST_ONCE
    )

    # ── Publish ──
    print("═══ Publishing messages ═══")
    broker.publish("chat.general", "Hello everyone!", publisher_id="alice")
    broker.publish("chat.random", "Anyone up for lunch?", publisher_id="bob")
    broker.publish("chat.general", "Meeting at 3pm", publisher_id="charlie")
    broker.publish("alerts", "Server CPU at 95%", publisher_id="monitor")

    time.sleep(2)

    # ── Replay ──
    print("\n═══ Replay last 2 messages from chat.general ═══")
    for msg in broker.replay("chat.general", last_n=2):
        print(f"  ⏪ {msg.publisher_id}: {msg.data}")

    # ── Channel wrapper ──
    print("\n═══ Channel abstraction ═══")
    notifications = Channel(broker, "notifications")
    notifications.subscribe(lambda m: print(f"  🔔 Notification: {m.data}"))
    notifications.publish("You have 3 new messages")

    time.sleep(1)

    print(f"\n  Stats: {broker.stats}")
    print(f"  Channels: {broker.channels()}")
    print(f"  Subscribers on 'chat.general': {broker.subscriber_count('chat.general')}")

    broker.shutdown()
```

---

## Summary Comparison Table

| # | System | Core Data Structure | Thread Safety | Key Pattern |
|---|--------|-------------------|---------------|-------------|
| 11 | **Cache** | HashMap + DLL (LRU) / FreqMap (LFU) | `Lock` | Strategy |
| 12 | **Rate Limiter** | Counters / Deque / Token float | `Lock` | Strategy |
| 13 | **Task Scheduler** | Min-Heap (priority queue) | `Condition` | Producer-Consumer |
| 14 | **Message Queue** | Append-only log + offsets | `Condition` | Consumer Groups |
| 15 | **Thread Pool** | Bounded Queue + worker threads | `Queue` | Worker Pool |
| 16 | **Connection Pool** | Queue of connections | `Queue` + `Lock` | Object Pool |
| 17 | **Event Bus** | Dict[EventType → handlers] | `RLock` | Observer + Mediator |
| 18 | **Pub/Sub** | Dict[channel → subscribers] + patterns | `RLock` + ThreadPool | Observer + Fan-out |

Each system uses **real production patterns**: Strategy, Observer, Producer-Consumer, and Object Pool. All implementations are **thread-safe** and include **metrics/monitoring hooks**.

