# Example — the state the contract exists for: `needs_user_input`

Without this state a recommendation about **product behaviour** reads exactly like
one about an implementation detail, and the master acts on both.

## Response

```markdown
---
protocol: clink-delegation
version: 1
decision_status: needs_user_input
confidence: high
user_decision_required: true
---

## Summary
The recovery strategy is decidable, but which guarantee to keep is not ours.

## Findings
1. Strong consistency costs availability during a partial failure: reads block
   until a quorum agrees.
2. Eventual consistency keeps the service up and shows some users stale balances.

## Recommendation
Either is buildable. This is not a tie-break the implementer should make.

## User Decision Required

### Decision
Strong consistency, or availability during a partial cluster failure.

### Why the agent must not decide it
It changes what a user sees during an outage. Nothing in the requirements settles
it, and inferring it would put a product choice in a commit message.

## Evidence boundary
Read the read path and the failover handler. Did not run a failure simulation, so
the duration of the blocking window is unmeasured.
```
