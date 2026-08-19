# Example — an architecture question, answered `ready`

## Request

```yaml
protocol: clink-delegation
version: 1
request:
  type: architecture
  problem: >
    A Redis failure leaves each node holding divergent local state, and nothing
    decides which copy is authoritative when it comes back.
  objective: >
    Choose a recovery strategy the implementer can build without another round.
  scope:
    exclude: [replacing Redis, changing the client protocol]
  questions:
    - Which state becomes authoritative after recovery?
    - How are conflicting timestamps resolved?
  context:
    facts:
      - Redis is the shared L2 state.
      - Every node keeps an in-memory L1 mirror and a JSON snapshot on disk.
    unknowns:
      - The maximum acceptable recovery delay.
  permissions:
    inspect_files: true
    execute_commands: false
```

## Response

```markdown
---
protocol: clink-delegation
version: 1
decision_status: ready
confidence: high
user_decision_required: false
---

## Summary
Rebuild Redis from the newest valid state, selected by a monotonic version rather
than a timestamp.

## Findings
1. L1 cannot be trusted alone: nodes diverge, and nothing distinguishes a stale
   mirror from a fresh one.
2. Snapshots are recovery candidates and must not become authoritative on their own.

## Recommendation
Introduce a monotonic state version; resolve conflicts on version first and
timestamp second. Timestamp-only loses to clock skew.

## Evidence boundary
Read the node startup path and the snapshot writer. Did not run anything, and did
not read the deployment manifests, so the recovery-delay ceiling is still unknown.
```
