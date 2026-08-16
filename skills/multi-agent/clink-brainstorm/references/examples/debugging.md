# Example — a debugging question, answered `blocked`

`blocked` is what a worker returns instead of reasoning its way to an answer it
could not check. A plausible answer produced without the evidence is the failure
this state prevents.

## Response

```markdown
---
protocol: clink-delegation
version: 1
decision_status: blocked
confidence: low
user_decision_required: false
---

## Summary
The cause cannot be established from what is reachable here.

## Findings
1. The stack trace names a frame in a module that is not in this checkout.
2. The failing test needs a running database; `execute_commands` is false, as it
   must be on this client, so it was not run.

## Recommendation
None. A cause named from this position would be a guess wearing a diagnosis.

## Evidence boundary
Read the handler and its two callers. Did not run the suite, did not reproduce,
and did not see the missing module. **Nothing here was verified by execution.**
```
