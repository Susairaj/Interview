Production Incident Handling & Documentation/Communication

## A Comprehensive Guide

---

# Part 1: Production Incident Handling

Production incidents are unplanned disruptions to your live systems that affect users. How you handle them determines your team's reliability and trustworthiness.

---

## 1. Incident Management

Incident management is the structured process of detecting, responding to, and resolving production issues as quickly as possible.

### The Incident Lifecycle

```
Detection → Triage → Response → Resolution → Post-Incident Review
    │          │         │           │               │
    ▼          ▼         ▼           ▼               ▼
 Alerts    Severity   Assemble    Fix the       Learn and
 Monitors  Assessment  Team      Problem        Improve
 Reports   Priority   Communicate Verify        Document
```

### Severity Levels

```
┌──────────┬──────────────────────────────┬──────────────┬────────────────────┐
│ Severity │ Description                  │ Response Time│ Example            │
├──────────┼──────────────────────────────┼──────────────┼────────────────────┤
│ SEV-1    │ Complete outage, all users   │ < 15 min     │ Site is down,      │
│ (P1)     │ affected, revenue impact     │              │ payment system     │
│          │                              │              │ broken             │
├──────────┼──────────────────────────────┼──────────────┼────────────────────┤
│ SEV-2    │ Major feature broken, many   │ < 30 min     │ Search not working,│
│ (P2)     │ users affected               │              │ login failures     │
│          │                              │              │ for 30% users      │
├──────────┼──────────────────────────────┼──────────────┼────────────────────┤
│ SEV-3    │ Minor feature broken, some   │ < 4 hours    │ Profile pictures   │
│ (P3)     │ users affected               │              │ not loading,       │
│          │                              │              │ slow API response  │
├──────────┼──────────────────────────────┼──────────────┼────────────────────┤
│ SEV-4    │ Cosmetic/minor issue, few    │ Next business│ UI alignment bug,  │
│ (P4)     │ users notice                 │ day          │ typo in error msg  │
└──────────┴──────────────────────────────┴──────────────┴────────────────────┘
```

### Incident Roles

```
┌─────────────────────────────────────────────────────────────────┐
│                    INCIDENT RESPONSE TEAM                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Incident Commander (IC)                                        │
│  ├── Owns the overall incident response                         │
│  ├── Makes decisions on priorities                              │
│  ├── Delegates tasks                                            │
│  └── Does NOT debug — coordinates                               │
│                                                                 │
│  Communications Lead                                            │
│  ├── Updates status page                                        │
│  ├── Communicates with stakeholders                             │
│  ├── Posts updates in incident channel                          │
│  └── Manages external communication                             │
│                                                                 │
│  Technical Lead(s)                                              │
│  ├── Investigates the root cause                                │
│  ├── Implements fixes                                           │
│  ├── Runs diagnostics                                           │
│  └── Reports findings to IC                                     │
│                                                                 │
│  Scribe                                                         │
│  ├── Records timeline of events                                 │
│  ├── Documents actions taken                                    │
│  ├── Notes decisions and rationale                              │
│  └── Creates base material for postmortem                       │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Real-World Example: E-Commerce Checkout Failure

```
INCIDENT TIMELINE
═════════════════

14:02 UTC  🚨 DETECTION
           PagerDuty alert: "checkout_success_rate dropped below 90%"
           Datadog dashboard shows 500 errors on /api/v2/checkout

14:05 UTC  📋 TRIAGE
           On-call engineer Sarah acknowledges alert
           Checks dashboards — error rate at 45% and climbing
           Sarah declares SEV-1, creates Slack channel #inc-20240115-checkout

14:08 UTC  📢 ROLES ASSIGNED
           IC: Sarah (on-call)
           Comms Lead: Mike (engineering manager)
           Tech Leads: James (payments team), Priya (platform team)
           Scribe: Alex

14:10 UTC  📊 INITIAL INVESTIGATION
           James: "Seeing timeout errors to payment gateway in logs"
           Priya: "No recent deployments. Infra metrics look normal."
           Sarah: "James, focus on the payment service. Priya, check
                   if the payment gateway has a status page update."

14:15 UTC  🔍 NARROWING DOWN
           Priya: "Stripe status page shows degraded performance in us-east-1"
           James: "Confirmed — our payment timeout is set to 5s,
                   Stripe responding in 12-15s"

14:18 UTC  💡 MITIGATION DECISION
           Sarah: "Options: 1) Increase timeout  2) Failover to us-west-2
                   3) Queue payments for retry"
           Team decides: Increase timeout to 30s AND add retry logic
           with failover to us-west-2

14:25 UTC  🔧 FIX DEPLOYED
           James pushes config change to increase timeout
           Priya enables Stripe failover to us-west-2

14:30 UTC  ✅ VERIFICATION
           Checkout success rate climbing: 60%... 75%... 92%... 98%
           Error rate back to baseline

14:35 UTC  📢 COMMUNICATION
           Mike updates status page: "Payment processing restored.
           Some users may have experienced checkout failures between
           14:02-14:30 UTC. All systems operational."

14:45 UTC  📝 INCIDENT CLOSED
           Sarah: "Incident resolved. Scheduling postmortem for
           tomorrow 10:00 UTC."
```

### Incident Communication Templates

```markdown
## INTERNAL STATUS UPDATE (Slack/Teams)

**🔴 INCIDENT UPDATE — #inc-20240115-checkout**
**Severity:** SEV-1
**Status:** INVESTIGATING → MITIGATING → RESOLVED
**Impact:** ~35% of checkout attempts failing
**Duration:** 14:02 - 14:30 UTC (28 minutes)
**IC:** Sarah Chen
**Current Actions:**
- Increased payment gateway timeout to 30s
- Enabled failover to us-west-2
**Next Update:** In 10 minutes or when status changes

---

## EXTERNAL STATUS UPDATE (Status Page / Customer-facing)

**Title:** Checkout Processing Delays
**Status:** Resolved

**Update 3 (14:35 UTC):** The issue has been resolved. Checkout
processing is functioning normally. Some customers may have
experienced failed transactions between 14:02-14:30 UTC. Any
charges from failed attempts will be automatically refunded
within 3-5 business days.

**Update 2 (14:20 UTC):** We have identified the issue and are
implementing a fix. Some customers may still experience
checkout failures.

**Update 1 (14:10 UTC):** We are investigating reports of
checkout failures. Our team is actively working on resolution.
```

---

## 2. Root Cause Analysis (RCA)

Root Cause Analysis is the systematic process of identifying **why** an incident happened — not just what happened, but the underlying cause that, if addressed, would prevent recurrence.

### The "5 Whys" Technique

```
INCIDENT: Checkout failures for 28 minutes

Why #1: Why did checkouts fail?
  → Because the payment API returned timeout errors.

Why #2: Why did the payment API timeout?
  → Because our timeout was set to 5 seconds and the payment
    gateway was responding in 12-15 seconds.

Why #3: Why was the payment gateway slow?
  → Because Stripe experienced degraded performance in us-east-1.

Why #4: Why didn't we handle the Stripe degradation gracefully?
  → Because we had no failover mechanism to another region
    and our timeout was too aggressive with no retry logic.

Why #5: Why didn't we have failover and retry mechanisms?
  → Because our payment integration was built as a prototype
    2 years ago and was never hardened for production resilience.

ROOT CAUSE: Lack of resilience patterns (failover, retries,
circuit breakers) in the payment service, combined with
aggressive timeout configuration.
```

### Fishbone (Ishikawa) Diagram

```
                    CHECKOUT FAILURES
                          │
    ┌─────────────┬───────┴───────┬──────────────┐
    │             │               │              │
 TECHNOLOGY   PROCESS        PEOPLE         ENVIRONMENT
    │             │               │              │
    ├─ No retry   ├─ No runbook   ├─ Team had    ├─ Stripe
    │  logic      │  for payment  │  no training │  us-east-1
    │             │  failures     │  on payment  │  degradation
    ├─ 5s timeout │               │  failover    │
    │  too low    ├─ No regular   │              ├─ No advance
    │             │  resilience   ├─ Prototype   │  warning from
    ├─ No circuit │  testing      │  code not    │  Stripe
    │  breaker    │               │  reviewed    │
    │             ├─ No alerts on │              │
    ├─ Single     │  gateway      │              │
    │  region     │  latency      │              │
    │  dependency │               │              │
```

### Fault Tree Analysis

```
                    ┌──────────────────────┐
                    │   CHECKOUT FAILURE   │
                    │      (TOP EVENT)     │
                    └──────────┬───────────┘
                               │
                          ┌────┴────┐
                          │   AND   │
                          └────┬────┘
                    ┌──────────┼──────────┐
                    │          │          │
            ┌───────▼──┐ ┌────▼─────┐ ┌──▼──────────┐
            │ Stripe   │ │ No       │ │ No fallback │
            │ Degraded │ │ Retry    │ │ Region      │
            │          │ │ Logic    │ │ Configured  │
            └──────────┘ └────┬─────┘ └─────────────┘
                              │
                         ┌────┴────┐
                         │   OR    │
                         └────┬────┘
                    ┌─────────┼─────────┐
                    │                   │
            ┌───────▼──────┐   ┌───────▼──────┐
            │ Never        │   │ No           │
            │ Implemented  │   │ Resilience   │
            │              │   │ Review       │
            └──────────────┘   └──────────────┘
```

### Contributing Factors vs. Root Cause

```
┌─────────────────────────────────────────────────────────────┐
│                    CAUSE CLASSIFICATION                      │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  TRIGGER (Proximate Cause):                                 │
│  └── Stripe us-east-1 degradation                          │
│      (This initiated the incident but is outside our        │
│       control)                                              │
│                                                             │
│  ROOT CAUSE:                                                │
│  └── Payment service lacked resilience patterns             │
│      (This is what WE can fix to prevent recurrence)        │
│                                                             │
│  CONTRIBUTING FACTORS:                                      │
│  ├── No monitoring on payment gateway latency               │
│  ├── No runbook for payment service failures                │
│  ├── Detection took 3 minutes (could be faster)             │
│  └── Prototype code promoted to production without review   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 3. Postmortems

A postmortem is a structured document written after an incident to capture what happened, why it happened, and how to prevent it from happening again. It must be **blameless**.

### Postmortem Template with Full Example

```markdown
═══════════════════════════════════════════════════════════════
            POSTMORTEM: Checkout Service Failure
                    January 15, 2024
═══════════════════════════════════════════════════════════════

## Summary
On January 15, 2024, between 14:02 and 14:30 UTC, approximately
35% of checkout attempts failed due to timeout errors when
communicating with our payment gateway (Stripe). The issue was
triggered by degraded performance in Stripe's us-east-1 region
and was exacerbated by our lack of retry logic, failover
capability, and overly aggressive timeout configuration.

## Impact
- Duration: 28 minutes
- Users affected: ~12,400 users attempted checkout during window
- Failed transactions: ~4,340 (35%)
- Estimated revenue impact: $178,000
- Support tickets generated: 847
- SLA impact: Monthly uptime dropped from 99.97% to 99.93%
  (still within 99.9% SLA)

## Timeline (all times UTC)

| Time  | Event                                                  |
|-------|--------------------------------------------------------|
| 13:55 | Stripe begins experiencing degradation in us-east-1    |
| 14:02 | Datadog alert fires: checkout_success_rate < 90%       |
| 14:03 | PagerDuty pages on-call engineer (Sarah)               |
| 14:05 | Sarah acknowledges, begins investigation               |
| 14:08 | SEV-1 declared, incident channel created               |
| 14:10 | Roles assigned, investigation begins                   |
| 14:15 | Root cause identified: Stripe latency + no failover    |
| 14:18 | Mitigation plan decided                                |
| 14:22 | Config change PR submitted and approved                 |
| 14:25 | Fix deployed to production                             |
| 14:30 | Metrics return to normal, incident resolved            |
| 14:35 | Status page updated, incident channel updated          |
| 14:45 | Incident formally closed                               |

## Root Cause
The payment service was configured with a 5-second timeout for
Stripe API calls and had no retry logic or regional failover.
When Stripe us-east-1 experienced latency (12-15s response
times), all requests timed out. The service returned 500 errors
to the checkout frontend with no graceful degradation.

## 5 Whys Analysis
1. Checkouts failed → Payment API returned 500 errors
2. Payment API errored → Stripe requests timed out at 5s
3. Requests timed out → Stripe latency was 12-15s in us-east-1
4. No graceful handling → No retry, failover, or circuit breaker
5. No resilience patterns → Service built as prototype, never
   reviewed for production hardening

## What Went Well
- Alert fired within 7 minutes of Stripe degradation starting
- Incident response was fast: 3 min from alert to acknowledgment
- Clear role assignment followed incident protocol
- Fix was identified and deployed in 20 minutes
- External communication was timely and clear

## What Went Wrong
- Payment service had no resilience patterns for 2 years
- No monitoring specifically on payment gateway latency
- No runbook existed for payment service failures
- Timeout value (5s) was never tuned based on actual P99 latency
- No integration tests simulating gateway degradation

## Action Items

| ID   | Action                              | Owner    | Priority | Due Date   |
|------|-------------------------------------|----------|----------|------------|
| AI-1 | Add retry logic with exponential    | James    | P0       | 2024-01-22 |
|      | backoff to payment service          |          |          |            |
| AI-2 | Configure Stripe regional failover  | James    | P0       | 2024-01-22 |
|      | (us-east-1 → us-west-2)            |          |          |            |
| AI-3 | Implement circuit breaker pattern   | James    | P1       | 2024-01-29 |
|      | for payment calls                   |          |          |            |
| AI-4 | Add payment gateway latency         | Priya    | P1       | 2024-01-25 |
|      | monitoring and alerting             |          |          |            |
| AI-5 | Create payment service runbook      | Sarah    | P1       | 2024-01-26 |
| AI-6 | Tune timeout based on P99 latency   | James    | P2       | 2024-02-01 |
|      | data (consider 15-30s)              |          |          |            |
| AI-7 | Add chaos engineering tests for     | Platform | P2       | 2024-02-15 |
|      | payment gateway degradation         | Team     |          |            |
| AI-8 | Conduct resilience review of all    | All Teams| P2       | 2024-03-01 |
|      | critical-path external dependencies |          |          |            |

## Lessons Learned
1. External dependencies MUST have resilience patterns from day
   one — retry, circuit breaker, fallback, timeout tuning.
2. Prototype code that makes it to production needs a formal
   production-readiness review.
3. Monitoring gateway latency (not just error rates) would have
   given us earlier warning.

## Supporting Data

Checkout Success Rate During Incident:
100%|████████████████████
 95%|██████████████████
 90%|████████████████        ← Alert threshold
 85%|
 80%|
 75%|
 70%|                ██
 65%|              ██  █
 60%|            ██    █
 55%|          ██       █
 50%|        ██          █
 45%|      ██             █
    |─────█────────────────██████████████████
    13:55  14:00  14:10  14:20  14:25  14:30  14:35

## Attendees
Sarah Chen (IC), James Wilson (Payments), Priya Sharma (Platform),
Mike Torres (Eng Manager), Alex Kim (Scribe)

## Review Date
January 16, 2024, 10:00 UTC
```

### Blameless Culture

```
┌─────────────────────────────────────────────────────────────┐
│               BLAMELESS POSTMORTEM PRINCIPLES                │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ❌ WRONG (Blame-focused):                                  │
│  "James wrote bad code without retry logic, causing the     │
│   outage. James needs to be more careful."                  │
│                                                             │
│  ✅ RIGHT (Blameless, system-focused):                      │
│  "The payment service lacked retry logic. Our code review   │
│   process and production-readiness checklist did not catch   │
│   this gap. We need to add resilience checks to our         │
│   review process."                                          │
│                                                             │
│  KEY PRINCIPLES:                                            │
│  1. People made the best decisions with available info      │
│  2. Focus on SYSTEMS and PROCESSES, not individuals         │
│  3. "How did our system allow this?" not "Who did this?"    │
│  4. Everyone speaks freely without fear of punishment       │
│  5. The goal is LEARNING, not accountability                │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 4. Rollback Strategies

Rollback strategies are predefined methods for reverting a system to a previous known-good state when a deployment causes issues.

### Strategy Comparison

```
┌──────────────────┬───────────┬────────────┬──────────────┬─────────────┐
│ Strategy         │ Speed     │ Risk       │ Complexity   │ Best For    │
├──────────────────┼───────────┼────────────┼──────────────┼─────────────┤
│ Version Rollback │ Fast      │ Low        │ Low          │ Stateless   │
│ (Redeploy prev)  │ (2-5 min) │            │              │ services    │
├──────────────────┼───────────┼────────────┼──────────────┼─────────────┤
│ Blue-Green       │ Very Fast │ Low        │ Medium       │ Full app    │
│ Deployment       │ (seconds) │            │              │ deployments │
├──────────────────┼───────────┼────────────┼──────────────┼─────────────┤
│ Canary Rollback  │ Fast      │ Very Low   │ Medium       │ Gradual     │
│                  │ (1-2 min) │ (limited   │              │ rollouts    │
│                  │           │  blast)    │              │             │
├──────────────────┼───────────┼────────────┼──────────────┼─────────────┤
│ Feature Flag     │ Instant   │ Very Low   │ Low          │ Feature     │
│ Toggle           │ (seconds) │            │              │ releases    │
├──────────────────┼───────────┼────────────┼──────────────┼─────────────┤
│ Database         │ Slow      │ HIGH       │ High         │ Schema      │
│ Rollback         │ (minutes  │ (data loss │              │ changes     │
│                  │  to hours)│  possible) │              │             │
├──────────────────┼───────────┼────────────┼──────────────┼─────────────┤
│ Infrastructure   │ Medium    │ Medium     │ Medium       │ Infra       │
│ Rollback (IaC)   │ (5-15 min)│            │              │ changes     │
└──────────────────┴───────────┴────────────┴──────────────┴─────────────┘
```

### Strategy 1: Blue-Green Deployment Rollback

```
BEFORE DEPLOYMENT:
                    ┌──────────────────┐
    Users ─────────►│  LOAD BALANCER   │
                    └────────┬─────────┘
                             │ (100% traffic)
                    ┌────────▼─────────┐
                    │   BLUE (v1.2)    │  ← Currently serving
                    │   ✅ Active      │
                    └──────────────────┘
                    ┌──────────────────┐
                    │   GREEN (idle)   │  ← Standby
                    │   ⬜ Inactive    │
                    └──────────────────┘

DURING DEPLOYMENT:
                    ┌──────────────────┐
    Users ─────────►│  LOAD BALANCER   │
                    └────────┬─────────┘
                             │ (100% traffic)
                    ┌────────▼─────────┐
                    │   BLUE (v1.2)    │  ← Still serving
                    │   ✅ Active      │
                    └──────────────────┘
                    ┌──────────────────┐
                    │   GREEN (v1.3)   │  ← Deploying + testing
                    │   🔄 Deploying   │
                    └──────────────────┘

AFTER DEPLOYMENT (traffic switched):
                    ┌──────────────────┐
    Users ─────────►│  LOAD BALANCER   │
                    └────────┬─────────┘
                             │ (100% traffic)
                    ┌──────────────────┐
                    │   BLUE (v1.2)    │  ← Kept as rollback
                    │   ⬜ Standby     │
                    └──────────────────┘
                    ┌────────▼─────────┐
                    │   GREEN (v1.3)   │  ← Now serving
                    │   ✅ Active      │
                    └──────────────────┘

ROLLBACK (if v1.3 has issues — just flip traffic back):
                    ┌──────────────────┐
    Users ─────────►│  LOAD BALANCER   │
                    └────────┬─────────┘
                             │ (100% traffic — SWITCHED BACK)
                    ┌────────▼─────────┐
                    │   BLUE (v1.2)    │  ← Serving again!
                    │   ✅ Active      │
                    └──────────────────┘
                    ┌──────────────────┐
                    │   GREEN (v1.3)   │  ← Investigate later
                    │   ❌ Pulled      │
                    └──────────────────┘

Rollback time: ~seconds (just a load balancer config change)
```

### Strategy 2: Canary Deployment with Rollback

```
PHASE 1 — Deploy to canary (5% of traffic):

                    ┌──────────────────┐
    Users ─────────►│  LOAD BALANCER   │
                    └───┬──────────┬───┘
                   95%  │          │  5%
               ┌────────▼──┐  ┌───▼──────────┐
               │ MAIN FLEET│  │   CANARY     │
               │  v1.2     │  │   v1.3       │
               │ (20 pods) │  │  (1 pod)     │
               └───────────┘  └──────────────┘

PHASE 2 — Monitor canary metrics:

    ┌──────────────────────────────────────────────────┐
    │  CANARY ANALYSIS (automated)                     │
    │                                                  │
    │  Error Rate:    Main: 0.1%    Canary: 0.12%  ✅  │
    │  Latency P99:   Main: 200ms   Canary: 195ms  ✅  │
    │  CPU Usage:     Main: 45%     Canary: 47%    ✅  │
    │  Success Rate:  Main: 99.9%   Canary: 99.88% ✅  │
    │                                                  │
    │  VERDICT: ✅ PASS — Proceed to next phase        │
    └──────────────────────────────────────────────────┘

PHASE 3 — Expand (25%, 50%, 100%) or ROLLBACK:

    IF canary fails at any phase:
    ┌──────────────────────────────────────────────────┐
    │  CANARY ANALYSIS                                 │
    │                                                  │
    │  Error Rate:    Main: 0.1%    Canary: 5.2%   ❌  │
    │  Latency P99:   Main: 200ms   Canary: 2100ms ❌  │
    │                                                  │
    │  VERDICT: ❌ FAIL — AUTO ROLLBACK                │
    │  Action: Terminate canary, route 100% to main    │
    └──────────────────────────────────────────────────┘

    Impact: Only 5% of traffic was affected for a short window
```

### Strategy 3: Feature Flag Rollback

```python
# Feature flag implementation example

class FeatureFlagService:
    """
    Feature flags allow instant rollback by toggling
    a configuration — no redeployment needed.
    """

    def __init__(self, flag_provider):
        self.provider = flag_provider  # LaunchDarkly, Unleash, etc.

    def is_enabled(self, flag_name: str, user_id: str = None) -> bool:
        return self.provider.get_flag(flag_name, user_id)


# In application code
feature_flags = FeatureFlagService(provider)

def process_checkout(cart, user):
    """
    The new payment flow is behind a feature flag.
    If anything goes wrong, we toggle the flag OFF
    and all users instantly get the old flow.
    """
    if feature_flags.is_enabled("new_payment_flow_v2", user.id):
        # New code path
        return new_payment_processor.charge(cart, user)
    else:
        # Old, proven code path (fallback)
        return legacy_payment_processor.charge(cart, user)


# Gradual rollout configuration:
#
# ┌──────────────────────────────────────────────┐
# │  Flag: new_payment_flow_v2                   │
# │                                              │
# │  Day 1:  1% of users  (internal testers)     │
# │  Day 3:  5% of users  (monitor metrics)      │
# │  Day 5:  25% of users (monitor metrics)      │
# │  Day 7:  50% of users (monitor metrics)      │
# │  Day 10: 100% of users                       │
# │                                              │
# │  ROLLBACK: Set to 0% → Instant, no deploy   │
# └──────────────────────────────────────────────┘
```

### Strategy 4: Database Rollback (The Hard One)

```
DATABASE CHANGES ARE THE HARDEST TO ROLLBACK
═══════════════════════════════════════════════

Why? Because data may have been written using the new schema.

SAFE MIGRATION PATTERN (Expand-Contract):

Phase 1: EXPAND (Add new column, keep old one)
┌──────────────────────────────────────────────────────┐
│ users table                                          │
│ ┌────────┬───────────┬────────────────┬────────────┐ │
│ │ id     │ name      │ email          │ full_name  │ │
│ │        │ (old col) │                │ (NEW col)  │ │
│ ├────────┼───────────┼────────────────┼────────────┤ │
│ │ 1      │ "John"    │ john@test.com  │ NULL       │ │
│ │ 2      │ "Jane"    │ jane@test.com  │ NULL       │ │
│ └────────┴───────────┴────────────────┴────────────┘ │
│                                                      │
│ App writes to BOTH columns. Reads from old.          │
│ ✅ Rollback: Just stop writing to new column.        │
└──────────────────────────────────────────────────────┘

Phase 2: MIGRATE (Backfill data)
┌──────────────────────────────────────────────────────┐
│ users table                                          │
│ ┌────────┬───────────┬────────────────┬────────────┐ │
│ │ id     │ name      │ email          │ full_name  │ │
│ ├────────┼───────────┼────────────────┼────────────┤ │
│ │ 1      │ "John"    │ john@test.com  │ "John Doe" │ │
│ │ 2      │ "Jane"    │ jane@test.com  │ "Jane Doe" │ │
│ └────────┴───────────┴────────────────┴────────────┘ │
│                                                      │
│ Backfill complete. App still writes to both.         │
│ Switch reads to new column.                          │
│ ✅ Rollback: Switch reads back to old column.        │
└──────────────────────────────────────────────────────┘

Phase 3: CONTRACT (Remove old column — AFTER validation)
┌──────────────────────────────────────────────────────┐
│ users table                                          │
│ ┌────────┬────────────────┬────────────┐             │
│ │ id     │ email          │ full_name  │             │
│ ├────────┼────────────────┼────────────┤             │
│ │ 1      │ john@test.com  │ "John Doe" │             │
│ │ 2      │ jane@test.com  │ "Jane Doe" │             │
│ └────────┴────────────────┴────────────┘             │
│                                                      │
│ Old column removed. This is the point of no return.  │
│ ⚠️  Rollback: Would need to re-add column + backfill │
│    Only do Phase 3 after Phase 2 is proven stable.   │
└──────────────────────────────────────────────────────┘
```

### Rollback Decision Framework

```
                    ┌─────────────────────┐
                    │ Issue Detected in   │
                    │    Production       │
                    └──────────┬──────────┘
                               │
                    ┌──────────▼──────────┐
                    │ Is it a feature     │──── YES ──► Toggle feature flag OFF
                    │ flag rollout?       │             (Instant rollback)
                    └──────────┬──────────┘
                               │ NO
                    ┌──────────▼──────────┐
                    │ Can you deploy the  │──── YES ──► Deploy previous version
                    │ previous version?   │             (2-5 min rollback)
                    └──────────┬──────────┘
                               │ NO
                    ┌──────────▼──────────┐
                    │ Blue-green setup?   │──── YES ──► Switch traffic to blue
                    │                     │             (Instant rollback)
                    └──────────┬──────────┘
                               │ NO
                    ┌──────────▼──────────┐
                    │ Does it involve     │──── YES ──► Follow expand-contract
                    │ database changes?   │             rollback plan
                    └──────────┬──────────┘             (10-60 min)
                               │ NO
                    ┌──────────▼──────────┐
                    │ Infrastructure      │──── YES ──► Revert IaC to previous
                    │ change (IaC)?       │             state + apply
                    └──────────┬──────────┘             (5-15 min)
                               │ NO
                    ┌──────────▼──────────┐
                    │   FORWARD FIX       │
                    │ (Fix the issue with │
                    │  a new deployment)  │
                    └─────────────────────┘
```

---

# Part 2: Documentation & Communication

---

## 1. Architecture Documents

Architecture documents describe the high-level structure, components, and decisions of a system. They serve as the "blueprint" that helps current and future engineers understand how and why the system is built the way it is.

### Architecture Document Template with Full Example

```markdown
═══════════════════════════════════════════════════════════════
          ARCHITECTURE DOCUMENT
          E-Commerce Order Processing System
═══════════════════════════════════════════════════════════════

## 1. Overview

### Purpose
This document describes the architecture of the Order
Processing System — the set of services responsible for
handling customer orders from checkout through fulfillment.

### Scope
- Order creation and validation
- Payment processing
- Inventory reservation
- Order fulfillment initiation
- Order status tracking

### Out of Scope
- Product catalog management
- User authentication (handled by Identity Service)
- Shipping carrier integration (handled by Logistics Service)

### Target Audience
- Backend engineers working on order-related features
- Platform/infrastructure team
- New team members for onboarding

---

## 2. System Context

### Context Diagram (C4 Level 1)

┌─────────────────────────────────────────────────────────┐
│                    EXTERNAL SYSTEMS                      │
│                                                         │
│  ┌──────────┐  ┌──────────┐  ┌──────────────────────┐  │
│  │  Stripe  │  │ Warehouse│  │  Email Service       │  │
│  │ (Payment)│  │  System  │  │  (SendGrid)          │  │
│  └─────▲────┘  └─────▲────┘  └──────────▲───────────┘  │
│        │              │                  │              │
└────────┼──────────────┼──────────────────┼──────────────┘
         │              │                  │
┌────────┼──────────────┼──────────────────┼──────────────┐
│        │              │                  │              │
│  ┌─────┴──────────────┴──────────────────┴───────────┐  │
│  │           ORDER PROCESSING SYSTEM                  │  │
│  │                                                    │  │
│  │  ┌────────────┐ ┌──────────┐ ┌─────────────────┐  │  │
│  │  │  Order     │ │ Payment  │ │  Fulfillment    │  │  │
│  │  │  Service   │ │ Service  │ │  Service        │  │  │
│  │  └────────────┘ └──────────┘ └─────────────────┘  │  │
│  └────────────────────▲──────────────────────────────┘  │
│                       │                                 │
│  ┌────────────────────┴──────────────────────────────┐  │
│  │              API GATEWAY                           │  │
│  └────────────────────▲──────────────────────────────┘  │
│                       │                                 │
│                 INTERNAL SYSTEMS                        │
└───────────────────────┼─────────────────────────────────┘
                        │
              ┌─────────┴─────────┐
              │   Web / Mobile    │
              │   Clients         │
              └───────────────────┘

---

## 3. Component Architecture (C4 Level 2)

┌─────────────────────────────────────────────────────────────┐
│                 ORDER PROCESSING SYSTEM                      │
│                                                             │
│   ┌──────────────────┐        ┌──────────────────┐         │
│   │   Order API      │───────►│   Order Worker   │         │
│   │   (REST/gRPC)    │        │   (Async)        │         │
│   │                  │        │                  │         │
│   │ POST /orders     │        │ Process payment  │         │
│   │ GET /orders/{id} │        │ Reserve inventory│         │
│   │ PUT /orders/{id} │        │ Trigger fulfill  │         │
│   └───────┬──────────┘        └────────┬─────────┘         │
│           │                            │                   │
│           │  ┌─────────────────────┐   │                   │
│           └──►   Message Queue     ◄───┘                   │
│              │   (Amazon SQS)      │                       │
│              └──────────┬──────────┘                       │
│                         │                                  │
│           ┌─────────────┼─────────────┐                    │
│           │             │             │                    │
│     ┌─────▼─────┐ ┌────▼──────┐ ┌────▼──────────┐        │
│     │ Payment   │ │ Inventory │ │ Notification   │        │
│     │ Service   │ │ Service   │ │ Service        │        │
│     │           │ │           │ │                │        │
│     │ Stripe    │ │ PostgreSQL│ │ SendGrid       │        │
│     │ Circuit   │ │ Stock DB  │ │ Email/SMS      │        │
│     │ Breaker   │ │           │ │                │        │
│     └───────────┘ └───────────┘ └────────────────┘        │
│                                                             │
│   DATA STORES:                                             │
│   ┌───────────────┐  ┌───────────────┐  ┌──────────────┐  │
│   │  PostgreSQL   │  │    Redis      │  │     S3       │  │
│   │  (Orders DB)  │  │  (Cache +     │  │ (Order docs) │  │
│   │               │  │   Sessions)   │  │              │  │
│   └───────────────┘  └───────────────┘  └──────────────┘  │
│                                                             │
└─────────────────────────────────────────────────────────────┘

---

## 4. Data Flow

### Happy Path: Order Creation

 Customer          API Gateway       Order Service       SQS Queue
    │                   │                │                   │
    │  POST /checkout   │                │                   │
    │──────────────────►│                │                   │
    │                   │  Create Order  │                   │
    │                   │───────────────►│                   │
    │                   │                │  Validate cart    │
    │                   │                │  Create order     │
    │                   │                │  (status=PENDING) │
    │                   │                │                   │
    │                   │                │  Publish event    │
    │                   │                │──────────────────►│
    │                   │  order_id      │                   │
    │                   │◄───────────────│                   │
    │  { order_id,      │                │                   │
    │    status:pending} │                │                   │
    │◄──────────────────│                │                   │

        SQS Queue     Payment Svc    Inventory Svc   Notification
           │               │               │               │
           │ order.created │               │               │
           │──────────────►│               │               │
           │               │ Charge card   │               │
           │               │──────►Stripe  │               │
           │               │◄──────        │               │
           │               │               │               │
           │               │ payment.ok    │               │
           │───────────────┼──────────────►│               │
           │               │               │ Reserve stock │
           │               │               │──────►DB      │
           │               │               │◄──────        │
           │               │               │               │
           │               │               │ inventory.ok  │
           │───────────────┼───────────────┼──────────────►│
           │               │               │               │ Send
           │               │               │               │ confirm
           │               │               │               │ email

---

## 5. Technology Choices

| Component       | Technology        | Rationale                      |
|-----------------|-------------------|--------------------------------|
| API Layer       | Go + gRPC/REST    | High throughput, low latency   |
| Message Queue   | Amazon SQS        | Managed, reliable, scales well |
| Primary DB      | PostgreSQL 15     | ACID compliance, JSON support  |
| Cache           | Redis 7           | Sub-ms reads for order status  |
| Object Storage  | S3                | Invoice PDFs, receipts         |
| Monitoring      | Datadog           | Already used company-wide      |
| CI/CD           | GitHub Actions    | Team familiarity               |
| Container       | EKS (Kubernetes)  | Standardized across org        |

---

## 6. Non-Functional Requirements

| Requirement     | Target              | Current         |
|-----------------|---------------------|-----------------|
| Availability    | 99.95%              | 99.97%          |
| Latency (P99)   | < 500ms             | 320ms           |
| Throughput      | 10,000 orders/min   | 6,500 orders/min|
| Data Retention  | 7 years (compliance)| 7 years         |
| Recovery (RTO)  | < 15 minutes        | ~10 minutes     |
| Recovery (RPO)  | < 1 minute          | ~30 seconds     |

---

## 7. Security Considerations

- All PII encrypted at rest (AES-256) and in transit (TLS 1.3)
- PCI DSS compliance: No card data stored; tokenized via Stripe
- API authentication via OAuth2 + JWT
- Service-to-service auth via mTLS
- Audit logging for all order state changes

---

## 8. Known Limitations & Technical Debt

1. Order Service is a single PostgreSQL instance (no read replicas)
   - Risk: DB becomes bottleneck at >15K orders/min
   - Plan: Add read replicas in Q2 2024

2. No dead letter queue processing for failed SQS messages
   - Risk: Silent message loss
   - Plan: Implement DLQ consumer in Q1 2024

3. Inventory reservation is not idempotent
   - Risk: Double reservation on retry
   - Plan: Add idempotency key support

---

## 9. Revision History

| Version | Date       | Author       | Changes              |
|---------|------------|--------------|----------------------|
| 1.0     | 2023-06-15 | Sarah Chen   | Initial version      |
| 1.1     | 2023-09-20 | James Wilson | Added payment circuit|
|         |            |              | breaker details      |
| 1.2     | 2024-01-20 | Priya Sharma | Updated after        |
|         |            |              | checkout incident    |
```

---

## 2. RFCs (Request for Comments)

An RFC is a document proposing a significant technical change for team discussion and review before implementation. It ensures that important decisions are well-thought-out and have broad input.

### When to Write an RFC

```
┌─────────────────────────────────────────────────────────────┐
│              SHOULD I WRITE AN RFC?                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  WRITE AN RFC when:                                         │
│  ✅ Introducing a new service or system                     │
│  ✅ Making breaking changes to APIs                         │
│  ✅ Changing core infrastructure                            │
│  ✅ Adopting new technology / framework                     │
│  ✅ Changes that affect multiple teams                      │
│  ✅ Decisions that are hard/expensive to reverse            │
│  ✅ Proposing significant refactoring                       │
│                                                             │
│  DON'T need an RFC when:                                    │
│  ❌ Bug fixes                                               │
│  ❌ Small features within existing architecture             │
│  ❌ Routine dependency updates                              │
│  ❌ Configuration changes                                   │
│  ❌ Code style/formatting changes                           │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### RFC Lifecycle

```
  DRAFT ──► REVIEW ──► DISCUSSION ──► ACCEPTED ──► IMPLEMENTED
    │          │           │              │              │
    ▼          ▼           ▼              ▼              ▼
  Author    Shared     Comments,       Approved       Work
  writes    with       questions,      by decision    begins
  proposal  reviewers  alternatives    makers
                       debated
                           │
                           ├──► REVISED (update based on feedback)
                           │
                           └──► REJECTED (with reasoning documented)
```

### Complete RFC Example

```markdown
═══════════════════════════════════════════════════════════════
RFC-2024-007: Migrate Payment Processing to Event-Driven
              Architecture
═══════════════════════════════════════════════════════════════

## Metadata
- **Authors:** James Wilson, Priya Sharma
- **Status:** REVIEW (Draft → Review → Accepted → Implemented)
- **Created:** January 20, 2024
- **Last Updated:** January 25, 2024
- **Decision Deadline:** February 5, 2024
- **Reviewers:** Sarah Chen, Mike Torres, Platform Team, 
  Payments Team, SRE Team
- **Approvers:** VP Engineering, Principal Engineer

---

## 1. Summary

This RFC proposes migrating the payment processing pipeline
from synchronous REST calls to an event-driven architecture
using Amazon EventBridge and SQS. This change addresses the
resilience failures exposed by the January 15th checkout
incident and prepares us for 10x order volume growth planned
for 2024.

---

## 2. Motivation

### Problem Statement
Our current payment processing is synchronous and tightly
coupled:

```
Current Flow (Synchronous):
Client → API → Order Svc → Payment Svc → Stripe → Response
                   │            │
              If Stripe is slow, ENTIRE chain blocks
              If Payment Svc is down, orders CANNOT be created
```

This architecture has caused:
- **3 SEV-1 incidents** in the past 6 months
- **$500K+ estimated revenue loss** from checkout failures
- **Inability to scale** beyond 8K orders/min

### Goals
1. Decouple order creation from payment processing
2. Enable graceful degradation when Stripe is unavailable
3. Support retry and dead-letter queue patterns
4. Scale to 50K orders/min by end of 2024
5. Reduce checkout-related SEV-1 incidents to zero

### Non-Goals
- Replacing Stripe as payment provider
- Changing the customer-facing checkout UI
- Migrating other services to event-driven (separate RFC)

---

## 3. Proposed Design

### Architecture Overview

```
NEW Flow (Event-Driven):

Client → API → Order Service → EventBridge → Payment Worker
                   │                              │
                   │ Creates order                 │ Processes
                   │ (status: PENDING)             │ payment
                   │ Returns immediately           │ async
                   │                               │
                   │         ┌─────────────────────┘
                   │         │
                   │    ┌────▼────────────┐
                   │    │  On success:    │
                   │    │  Update order   │
                   │    │  status = PAID  │
                   │    │  Notify user    │
                   │    └─────────────────┘
                   │    ┌─────────────────┐
                   │    │  On failure:    │
                   │    │  Retry (3x)     │
                   │    │  Then DLQ       │
                   │    │  Alert team     │
                   │    └─────────────────┘
```

### Detailed Component Design

```
┌──────────────────────────────────────────────────────────┐
│                                                          │
│  ┌─────────────┐    ┌──────────────┐                    │
│  │ Order API   │───►│ EventBridge  │                    │
│  │             │    │              │                    │
│  │ POST /order │    │ order.created│                    │
│  │ Returns 202 │    │ event        │                    │
│  └─────────────┘    └──────┬───────┘                    │
│                            │                            │
│              ┌─────────────┼─────────────┐              │
│              │             │             │              │
│        ┌─────▼─────┐ ┌────▼──────┐ ┌────▼──────────┐   │
│        │ Payment   │ │ Inventory │ │ Analytics     │   │
│        │ Queue     │ │ Queue     │ │ Queue         │   │
│        │ (SQS)     │ │ (SQS)    │ │ (SQS)        │   │
│        └─────┬─────┘ └────┬──────┘ └────┬──────────┘   │
│              │             │             │              │
│        ┌─────▼─────┐ ┌────▼──────┐ ┌────▼──────────┐   │
│        │ Payment   │ │ Inventory │ │ Analytics     │   │
│        │ Worker    │ │ Worker    │ │ Worker        │   │
│        │           │ │           │ │               │   │
│        │ Retries:3 │ │ Retries:3 │ │ Retries:3    │   │
│        │ Timeout:  │ │           │ │               │   │
│        │ 30s       │ │           │ │               │   │
│        │ Circuit   │ │           │ │               │   │
│        │ Breaker   │ │           │ │               │   │
│        └─────┬─────┘ └───────────┘ └───────────────┘   │
│              │                                          │
│        ┌─────▼─────┐                                    │
│        │ DLQ       │ ← Failed after all retries        │
│        │ (Dead     │   Alerts fire, manual review       │
│        │  Letter)  │                                    │
│        └───────────┘                                    │
│                                                          │
└──────────────────────────────────────────────────────────┘
```

### Event Schema

```json
{
  "version": "1.0",
  "id": "evt_abc123",
  "type": "order.created",
  "timestamp": "2024-01-20T10:30:00Z",
  "source": "order-service",
  "data": {
    "order_id": "ord_xyz789",
    "customer_id": "cust_456",
    "items": [
      {
        "product_id": "prod_001",
        "quantity": 2,
        "unit_price": 29.99
      }
    ],
    "total_amount": 59.98,
    "currency": "USD",
    "idempotency_key": "idem_abc123_20240120"
  },
  "metadata": {
    "correlation_id": "corr_def456",
    "trace_id": "trace_ghi789"
  }
}
```

---

## 4. Alternatives Considered

### Alternative A: Add retry logic to existing sync flow

```
Pros:
  + Minimal code changes
  + No architectural change
  + Fast to implement (1-2 days)

Cons:
  - Still synchronous — user waits for retries
  - Doesn't solve scaling problem
  - Doesn't decouple services
  - Retry storms can overwhelm Stripe

Verdict: REJECTED — Treats symptoms, not root cause
```

### Alternative B: Use Apache Kafka instead of EventBridge/SQS

```
Pros:
  + Higher throughput ceiling
  + Event replay capability
  + More control over partitioning

Cons:
  - Significant operational burden (cluster management)
  - Team has no Kafka experience
  - Overkill for current volume (8K orders/min)
  - 3-4 month setup time

Verdict: REJECTED — Operational cost too high for current scale.
         Revisit if we exceed 100K orders/min.
```

### Alternative C: Use managed EventBridge + SQS (PROPOSED)

```
Pros:
  + Fully managed — no infrastructure to maintain
  + Native AWS integration
  + Built-in retry, DLQ, filtering
  + Team has AWS experience
  + Scales to 100K+ events/second
  + 4-6 week implementation

Cons:
  - AWS vendor lock-in
  - No event replay (unlike Kafka)
  - EventBridge has 256KB event size limit

Verdict: ACCEPTED — Best balance of capability, speed, and
         operational simplicity.
```

### Decision Matrix

```
┌───────────────────┬──────────┬──────────┬──────────┬──────────┐
│ Criteria (weight) │ Sync     │ Kafka    │EventBrdg │ Winner   │
│                   │ Retry    │          │+ SQS     │          │
├───────────────────┼──────────┼──────────┼──────────┼──────────┤
│ Resilience (30%)  │ 4/10     │ 9/10     │ 8/10     │ Kafka    │
│ Time to impl(25%) │ 9/10     │ 3/10     │ 7/10     │ Retry    │
│ Ops burden  (20%) │ 2/10     │ 3/10     │ 9/10     │ EvtBrdg  │
│ Scalability (15%) │ 3/10     │ 10/10    │ 8/10     │ Kafka    │
│ Team skill  (10%) │ 8/10     │ 2/10     │ 7/10     │ Retry    │
├───────────────────┼──────────┼──────────┼──────────┼──────────┤
│ WEIGHTED TOTAL    │ 4.85     │ 5.65     │ 7.85     │ EvtBrdg  │
└───────────────────┴──────────┴──────────┴──────────┴──────────┘
```

---

## 5. Migration Plan

```
Phase 1 (Week 1-2): Build event infrastructure
  ├── Create EventBridge event bus
  ├── Create SQS queues + DLQs
  ├── Deploy payment worker service
  └── Integration tests

Phase 2 (Week 3): Dual-write mode
  ├── Order service publishes events AND calls sync API
  ├── Compare results (shadow mode)
  ├── Monitor for discrepancies
  └── Rollback: Disable event publishing

Phase 3 (Week 4): Cutover
  ├── Switch to event-driven flow (feature flag)
  ├── Canary rollout: 5% → 25% → 50% → 100%
  ├── Monitor all metrics
  └── Rollback: Toggle feature flag

Phase 4 (Week 5-6): Cleanup
  ├── Remove synchronous payment code
  ├── Update documentation
  ├── Remove feature flags
  └── Knowledge sharing session
```

---

## 6. Risks and Mitigations

| Risk                              | Likelihood | Impact | Mitigation               |
|-----------------------------------|-----------|--------|--------------------------|
| Event ordering issues             | Medium    | High   | Idempotency keys on      |
|                                   |           |        | all operations           |
| Increased checkout latency        | Low       | High   | Optimistic UI + webhooks |
|                                   |           |        | for status updates       |
| DLQ messages pile up              | Medium    | Medium | Automated alerts +       |
|                                   |           |        | DLQ processing dashboard |
| EventBridge service outage        | Low       | High   | Circuit breaker falls    |
|                                   |           |        | back to sync flow        |

---

## 7. Success Metrics

| Metric                        | Current    | Target     |
|-------------------------------|------------|------------|
| Checkout SEV-1 incidents/qtr  | 3          | 0          |
| Checkout success rate         | 99.2%      | 99.95%     |
| Max orders/minute             | 8,000      | 50,000     |
| Payment processing P99        | 4,500ms    | 800ms      |
| Mean time to recovery (MTTR)  | 25 min     | < 5 min    |

---

## 8. Open Questions

1. Should we use FIFO SQS queues for strict ordering, or
   standard queues with idempotency? (Leaning: standard + idem)

2. How long should we keep the synchronous fallback path?
   (Proposal: 3 months after 100% cutover)

3. Do we need event replay capability for payment events?
   (If yes, consider adding S3 event archival)

---

## 9. Feedback & Discussion

### Comment Thread:

**Sarah Chen (Jan 22):**
> How do we handle the case where a customer is waiting on the
> checkout page? If payment is async, what does the UI show?

**James Wilson (Jan 22):**
> Good point. Proposal: Return 202 with order_id, show
> "Processing payment..." screen, use WebSocket for real-time
> status updates. 95th percentile should complete in < 3 seconds,
> so UX impact is minimal.

**Platform Team (Jan 23):**
> We'd recommend using SQS standard queues (not FIFO) for higher
> throughput. Idempotency keys at the consumer level are more
> reliable than FIFO deduplication.

**SRE Team (Jan 24):**
> Please ensure all events include trace_id and correlation_id
> for distributed tracing. Also, DLQ alerts should page on-call
> if queue depth > 100.
```

---

## 3. Technical Design Documents

Technical design documents (TDDs) are more detailed than architecture docs and more implementation-focused than RFCs. They describe **how** to implement a specific feature or system component.

### How TDDs Differ from RFCs and Architecture Docs

```
┌────────────────────────────────────────────────────────────┐
│              DOCUMENT TYPE COMPARISON                       │
├────────────────┬──────────────────┬────────────────────────┤
│ Architecture   │ RFC              │ Technical Design       │
│ Document       │                  │ Document               │
├────────────────┼──────────────────┼────────────────────────┤
│ WHY the system │ WHAT change to   │ HOW to implement       │
│ exists and     │ make and why     │ a specific component   │
│ how it works   │ this approach    │ in detail              │
│ at high level  │ over others      │                        │
├────────────────┼──────────────────┼────────────────────────┤
│ Long-lived     │ Snapshot in time │ Lives with the feature │
│ reference doc  │ Decision record  │ Updated as code evolves│
├────────────────┼──────────────────┼────────────────────────┤
│ Broad audience │ Decision-makers  │ Implementing engineers │
│ (eng + non-eng)│ and reviewers    │ and code reviewers     │
├────────────────┼──────────────────┼────────────────────────┤
│ C4 Levels 1-2  │ Level 2-3       │ Level 3-4 (detailed)   │
└────────────────┴──────────────────┴────────────────────────┘
```

### Technical Design Document Example

```markdown
═══════════════════════════════════════════════════════════════
  TECHNICAL DESIGN: Payment Worker Service
  (Implements RFC-2024-007)
═══════════════════════════════════════════════════════════════

## 1. Overview
This document details the implementation of the Payment Worker
service — an asynchronous consumer that processes payment
events from the SQS queue and interfaces with Stripe.

## 2. Service Design

### Class/Module Structure

```
payment-worker/
├── cmd/
│   └── worker/
│       └── main.go              # Entry point
├── internal/
│   ├── consumer/
│   │   ├── sqs_consumer.go      # SQS message polling
│   │   └── sqs_consumer_test.go
│   ├── processor/
│   │   ├── payment_processor.go # Core payment logic
│   │   ├── idempotency.go       # Idempotency check
│   │   └── processor_test.go
│   ├── gateway/
│   │   ├── stripe_gateway.go    # Stripe API client
│   │   ├── circuit_breaker.go   # Circuit breaker wrapper
│   │   └── gateway_test.go
│   ├── notifier/
│   │   ├── event_publisher.go   # Publish result events
│   │   └── notifier_test.go
│   └── models/
│       ├── order.go
│       └── payment.go
├── config/
│   └── config.yaml
├── Dockerfile
└── README.md
```

### Core Processing Flow

```go
// Pseudocode for the payment processing pipeline

func (p *PaymentProcessor) ProcessMessage(ctx context.Context,
    msg *sqs.Message) error {

    // Step 1: Parse event
    event, err := parseOrderEvent(msg.Body)
    if err != nil {
        // Malformed message — send to DLQ, don't retry
        return NewNonRetryableError("invalid message format", err)
    }

    // Step 2: Idempotency check
    if p.idempotencyStore.HasProcessed(event.IdempotencyKey) {
        log.Info("Already processed, skipping",
            "idempotency_key", event.IdempotencyKey)
        return nil // Acknowledge message
    }

    // Step 3: Process payment through circuit breaker
    result, err := p.circuitBreaker.Execute(func() (interface{},
        error) {
        return p.stripeGateway.Charge(ctx, ChargeRequest{
            Amount:         event.Data.TotalAmount,
            Currency:       event.Data.Currency,
            CustomerID:     event.Data.CustomerID,
            IdempotencyKey: event.IdempotencyKey,
        })
    })

    if err != nil {
        if isRetryable(err) {
            // Return error — SQS will retry based on policy
            return fmt.Errorf("retryable payment error: %w", err)
        }
        // Non-retryable (e.g., card declined)
        p.publishEvent("payment.failed", event.Data.OrderID, err)
        p.idempotencyStore.MarkProcessed(event.IdempotencyKey)
        return nil
    }

    // Step 4: Record success
    p.idempotencyStore.MarkProcessed(event.IdempotencyKey)

    // Step 5: Publish success event
    p.publishEvent("payment.succeeded", event.Data.OrderID, result)

    return nil
}
```

### Circuit Breaker Configuration

```
┌─────────────────────────────────────────────┐
│         CIRCUIT BREAKER STATES              │
│                                             │
│   CLOSED ──────► OPEN ──────► HALF-OPEN     │
│   (Normal)      (Failing)    (Testing)      │
│      │              │            │          │
│      │              │            ├─► CLOSED  │
│      │              │            │  (if test │
│      │              │            │   passes) │
│      │              │            │          │
│      │              │            └─► OPEN    │
│      │              │              (if test  │
│      │              │               fails)   │
│      └──────────────┘                        │
│       (when error threshold exceeded)        │
│                                             │
│   Config:                                   │
│   - Failure threshold: 5 failures in 30s    │
│   - Open duration: 60 seconds               │
│   - Half-open test requests: 3              │
│   - Success threshold to close: 3/3         │
│   - Timeout per request: 30 seconds         │
└─────────────────────────────────────────────┘
```

### Retry Policy

```
┌─────────────────────────────────────────────────────────┐
│                   SQS RETRY POLICY                       │
│                                                         │
│  Attempt 1: Process immediately                         │
│       │ (failure)                                       │
│       ▼                                                 │
│  Attempt 2: After 30 seconds (visibility timeout)       │
│       │ (failure)                                       │
│       ▼                                                 │
│  Attempt 3: After 120 seconds                           │
│       │ (failure)                                       │
│       ▼                                                 │
│  → Move to Dead Letter Queue                            │
│  → Fire PagerDuty alert                                 │
│  → Log with full context for manual investigation       │
│                                                         │
│  NON-RETRYABLE ERRORS (skip retry, acknowledge):        │
│  - Card declined                                        │
│  - Invalid card number                                  │
│  - Insufficient funds                                   │
│  - Malformed request                                    │
│                                                         │
│  RETRYABLE ERRORS (retry according to policy):          │
│  - Stripe timeout                                       │
│  - Stripe 500/502/503 errors                            │
│  - Network errors                                       │
│  - Circuit breaker open (wait for half-open)            │
└─────────────────────────────────────────────────────────┘
```

### Database Schema

```sql
-- Idempotency tracking table
CREATE TABLE payment_idempotency (
    idempotency_key VARCHAR(255) PRIMARY KEY,
    order_id        VARCHAR(255) NOT NULL,
    status          VARCHAR(50)  NOT NULL,
    -- 'processing', 'succeeded', 'failed'
    stripe_charge_id VARCHAR(255),
    error_message    TEXT,
    created_at       TIMESTAMP    NOT NULL DEFAULT NOW(),
    updated_at       TIMESTAMP    NOT NULL DEFAULT NOW(),

    -- Auto-cleanup after 7 days
    expires_at       TIMESTAMP    NOT NULL
        DEFAULT (NOW() + INTERVAL '7 days')
);

CREATE INDEX idx_idempotency_order
    ON payment_idempotency(order_id);
CREATE INDEX idx_idempotency_expires
    ON payment_idempotency(expires_at);

-- Payment audit log
CREATE TABLE payment_audit_log (
    id              BIGSERIAL PRIMARY KEY,
    order_id        VARCHAR(255) NOT NULL,
    event_type      VARCHAR(100) NOT NULL,
    stripe_charge_id VARCHAR(255),
    amount_cents     BIGINT       NOT NULL,
    currency         VARCHAR(3)   NOT NULL,
    status           VARCHAR(50)  NOT NULL,
    error_code       VARCHAR(100),
    error_message    TEXT,
    raw_response     JSONB,
    created_at       TIMESTAMP    NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_audit_order
    ON payment_audit_log(order_id);
CREATE INDEX idx_audit_created
    ON payment_audit_log(created_at);
```

### Monitoring & Alerting

```
┌─────────────────────────────────────────────────────────┐
│                MONITORING DASHBOARD                      │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  KEY METRICS:                                           │
│                                                         │
│  1. payment_processed_total (counter)                   │
│     Labels: status={success,failed,retried}             │
│     Alert: success_rate < 95% for 5min → SEV-2         │
│                                                         │
│  2. payment_processing_duration_seconds (histogram)     │
│     Alert: P99 > 10s for 5min → SEV-3                  │
│                                                         │
│  3. sqs_messages_in_flight (gauge)                      │
│     Alert: > 1000 for 10min → SEV-2                    │
│                                                         │
│  4. sqs_dlq_depth (gauge)                               │
│     Alert: > 0 → SEV-3                                  │
│     Alert: > 100 → SEV-1 (page on-call)                │
│                                                         │
│  5. circuit_breaker_state (gauge)                       │
│     Alert: state=open for > 2min → SEV-2               │
│                                                         │
│  6. stripe_api_latency_seconds (histogram)              │
│     Alert: P99 > 5s → SEV-3 (early warning)            │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

### Testing Plan

```
Unit Tests:
├── Payment processor logic (mock Stripe)
├── Idempotency check logic
├── Circuit breaker state transitions
├── Event parsing and validation
└── Error classification (retryable vs non-retryable)

Integration Tests:
├── SQS consumer end-to-end (LocalStack)
├── Stripe API with test keys
├── Database idempotency operations
└── EventBridge event publishing

Chaos/Resilience Tests:
├── Stripe returns 500 errors → verify circuit breaker opens
├── Stripe responds with 15s latency → verify timeout handling
├── SQS message processed twice → verify idempotency
├── Worker crashes mid-processing → verify message retry
└── DLQ receives messages → verify alerting fires
```

---

## 4. Stakeholder Communication

Effective communication with stakeholders (non-technical leadership, product managers, customers) is essential for building trust and alignment.

### Communication Framework by Audience

```
┌─────────────────────────────────────────────────────────────┐
│          COMMUNICATION ADAPTION BY AUDIENCE                  │
├──────────────┬──────────────────────────────────────────────┤
│              │                                              │
│ EXECUTIVES   │ • Lead with BUSINESS IMPACT                  │
│ (CTO, VP)    │ • Revenue, customer satisfaction, risk       │
│              │ • 1-2 sentences max per point                │
│              │ • What you need from them (decisions/budget) │
│              │ • No code, no technical jargon               │
│              │                                              │
│ PRODUCT      │ • Lead with USER IMPACT                      │
│ MANAGERS     │ • Feature timelines, trade-offs              │
│              │ • What it means for the roadmap              │
│              │ • Light technical context                    │
│              │                                              │
│ ENGINEERING  │ • Lead with TECHNICAL DETAILS                │
│ PEERS        │ • Architecture, trade-offs, alternatives     │
│              │ • Code samples, diagrams                     │
│              │ • Seek feedback on approach                  │
│              │                                              │
│ CUSTOMERS    │ • Lead with SERVICE IMPACT                   │
│              │ • What happened, what we're doing about it   │
│              │ • No blame, no internal details              │
│              │ • Empathy first, then facts                  │
│              │                                              │
└──────────────┴──────────────────────────────────────────────┘
```

### Example: Communicating the Same Incident to Different Audiences

```markdown
═══════════════════════════════════════════════════════════
SCENARIO: The January 15th checkout incident
          (28 minutes, $178K revenue impact)
═══════════════════════════════════════════════════════════

────────────────────────────────────────
TO: CEO / CTO (Executive Summary Email)
────────────────────────────────────────

Subject: Checkout Incident Resolution + Prevention Plan

Hi [CEO/CTO],

On January 15th, our checkout system experienced a 28-minute
outage affecting ~12,400 customers, with an estimated revenue
impact of $178K.

**What happened:** Our payment provider (Stripe) had a regional
slowdown. Our system wasn't equipped to handle this gracefully,
causing checkout failures.

**What we've done:**
- Restored service within 28 minutes
- Implemented immediate fixes (timeouts, regional failover)
- Identified 8 action items to prevent recurrence

**What we need:**
- Approval for a 6-week engineering initiative to rebuild our
  payment pipeline for resilience (RFC-2024-007 attached)
- This requires 2 engineers full-time, delaying the loyalty
  program feature by 3 weeks

**Expected outcome:** Zero payment-related outages going
forward. System will handle 10x our current order volume.

Happy to discuss in our 1:1 Thursday.

— James

────────────────────────────────────────
TO: Product Manager (Feature Impact)
────────────────────────────────────────

Subject: Payment Resilience Work — Roadmap Impact

Hi [PM],

Following the checkout incident, we need to prioritize a
payment infrastructure upgrade. Here's what this means for
your roadmap:

**Impact to features:**
- Loyalty program launch: Delayed from Feb 15 → March 7
  (3 weeks)
- Everything else on track

**Why this matters:**
- 3 checkout outages in 6 months is hurting customer trust
- NPS scores drop measurably after outage events
- This fix also unlocks the capacity we need for the
  Black Friday 2024 sale

**What stays the same:**
- Mobile checkout redesign (different team)
- Gift card feature (not affected)

**Timeline:**
- Weeks 1-2: Infrastructure setup (no feature impact)
- Weeks 3-4: Migration (checkout flow changes, need QA)
- Weeks 5-6: Rollout and cleanup

Can we sync tomorrow to update the roadmap?

— James

────────────────────────────────────────
TO: Engineering Team (Technical Detail)
────────────────────────────────────────

Subject: RFC-2024-007: Payment Event-Driven Migration — 
         Review Requested

Team,

Based on the postmortem from last week's checkout incident,
I've drafted an RFC to migrate our payment pipeline from
synchronous REST to event-driven using EventBridge + SQS.

**Key changes:**
- Order creation decoupled from payment processing
- Async payment with retry, circuit breaker, and DLQ
- Idempotent processing with deduplication keys
- Regional failover for Stripe

**RFC:** [link to RFC-2024-007]
**Postmortem:** [link to postmortem]

I need reviews from:
- Platform team (infrastructure choices)
- SRE team (monitoring and alerting)
- Payments team (Stripe integration details)

**Review deadline:** February 5th
**Discussion meeting:** February 3rd, 2:00 PM UTC

Please leave comments directly in the RFC document.

— James

────────────────────────────────────────
TO: Customers (Status Page / Email)
────────────────────────────────────────

Subject: Update on January 15th Checkout Issue

Dear [Customer],

On January 15th between 2:02 PM and 2:30 PM UTC, some
customers experienced difficulties completing their purchases
on our platform. We sincerely apologize for the inconvenience.

**What happened:**
A temporary issue with one of our payment processing systems
caused some checkout attempts to fail during a 28-minute
window.

**What we've done:**
- The issue was resolved the same day
- All failed transactions were automatically refunded
- We've implemented additional safeguards to prevent this
  from happening again

**If you were affected:**
- Any charges from failed attempts have been refunded
- Refunds may take 3-5 business days to appear
- If you have questions, contact support@company.com

We take the reliability of our service seriously and are
investing in improvements to ensure a seamless experience.

Thank you for your patience,
The [Company] Team
```

### Status Update Templates

```markdown
## PROJECT STATUS UPDATE (Weekly)

### Payment Migration Project — Week 2 of 6

**Overall Status:** 🟢 On Track

**Completed This Week:**
- ✅ EventBridge event bus created and tested
- ✅ SQS queues provisioned with DLQ configuration
- ✅ Payment worker service scaffolded with CI/CD

**In Progress:**
- 🔄 Stripe integration with circuit breaker (70% complete)
- 🔄 Idempotency store implementation (50% complete)

**Planned Next Week:**
- Integration testing with Stripe test environment
- Begin dual-write mode implementation
- Write runbook for new payment worker

**Risks/Blockers:**
- ⚠️ Need SRE team to review alerting configuration by Friday
  (requested, awaiting response)
- No blockers currently

**Key Metrics:**
- Sprint velocity: 34 points (target: 30) ✅
- Test coverage: 87% (target: 85%) ✅
- Open PRs: 2 (both in review)

---

## DECISION LOG

| Date       | Decision                           | Rationale                | Decided By    |
|------------|------------------------------------|-----------------------------|---------------|
| 2024-01-22 | Use standard SQS (not FIFO)       | Higher throughput, idempotency | James, Sarah  |
|            |                                    | at consumer level suffices     |               |
| 2024-01-24 | 30s timeout for Stripe calls       | Based on P99 data + buffer     | James, Priya  |
| 2024-01-25 | Keep sync fallback for 3 months    | Safety net during transition   | Sarah, Mike   |
```

### Escalation Communication

```
┌─────────────────────────────────────────────────────────────┐
│              ESCALATION LADDER                               │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Level 1: Team Slack Channel                                │
│  └── "Hey team, seeing elevated error rates on payments.    │
│       Investigating. Will update in 15 min."                │
│                                                             │
│  Level 2: Engineering Manager + Incident Channel            │
│  └── "Declaring SEV-2. Payment errors at 5% (baseline 0.1%)│
│       Created #inc-20240120. Need help from payments team." │
│                                                             │
│  Level 3: Director / VP + War Room                          │
│  └── "Escalating to SEV-1. Checkout completely down.        │
│       ~$6K/min revenue impact. War room link: [zoom].       │
│       Need authorization for emergency Stripe region change"│
│                                                             │
│  Level 4: CTO / Executive + Status Page                     │
│  └── "CEO brief: Customer-facing outage, 15 min so far.     │
│       Actively mitigating. ETA for resolution: 10 min.      │
│       Comms team: Please prepare customer statement."        │
│                                                             │
│  RULE: Escalate EARLY. It's always better to over-escalate  │
│  and stand down than to under-escalate and miss help.       │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Summary: How Everything Connects

```
┌─────────────────────────────────────────────────────────────┐
│                  THE FULL LIFECYCLE                          │
│                                                             │
│  1. ARCHITECTURE DOC                                        │
│     └── "Here's how our system works"                       │
│                                                             │
│  2. RFC                                                     │
│     └── "Here's a change we want to make and why"           │
│                                                             │
│  3. TECHNICAL DESIGN DOC                                    │
│     └── "Here's exactly how we'll implement it"             │
│                                                             │
│  4. IMPLEMENTATION                                          │
│     └── Code, tests, deployment                             │
│                                                             │
│  5. INCIDENT (when things go wrong)                         │
│     ├── Incident Management: Detect, respond, resolve       │
│     ├── Rollback Strategy: Revert if needed                 │
│     ├── Root Cause Analysis: Find the real "why"            │
│     └── Postmortem: Document and learn                      │
│                                                             │
│  6. STAKEHOLDER COMMUNICATION (throughout)                  │
│     ├── Executives: Business impact + decisions needed      │
│     ├── Product: Feature impact + timelines                 │
│     ├── Engineering: Technical details + feedback           │
│     └── Customers: Empathy + transparency                   │
│                                                             │
│  7. BACK TO STEP 1                                          │
│     └── Update architecture doc with learnings              │
│                                                             │
│              ┌──────────────────────┐                       │
│              │   CONTINUOUS CYCLE   │                       │
│              │   OF IMPROVEMENT     │                       │
│              └──────────────────────┘                       │
└─────────────────────────────────────────────────────────────┘
```