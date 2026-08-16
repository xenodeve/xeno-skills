# `BrainstormResponse v1` — what must come back

```markdown
---
protocol: clink-delegation
version: 1
decision_status: ready | needs_more_analysis | needs_user_input | blocked
confidence: high | medium | low
user_decision_required: false
---

## Summary
## Findings
## Recommendation
## Evidence boundary
```

## Required

Metadata: `protocol` · `version` · `decision_status` · `confidence`.
Sections: `Summary` · `Findings` · `Recommendation` · **`Evidence boundary`**.

Conditional, and omitted when empty: `Options` · `Assumptions` · `Unresolved` ·
`Risks` · `Suggested Actions` · `User Decision Required`.

## The four decision states

| State | Meaning | What the master does |
|---|---|---|
| `ready` | the master may act | evaluate the recommendation and continue |
| `needs_more_analysis` | not yet; another round would resolve it | build a new request |
| `needs_user_input` | **a human owns this choice** | **stop; ask** |
| `blocked` | cannot proceed with the information or capability available | resolve the blocker or report it |

`needs_user_input` is the state the whole contract exists for. Without it, a
recommendation about a product behaviour reads exactly like a recommendation about
an implementation detail, and the master acts on both.

## Why `Evidence boundary` is required and `Risks` is not

Omitting a risks section because there are no risks is honest. **Omitting what was
never checked is indistinguishable from having checked it** — and that is the shape
of the confident-wrong answer.

It is also the one required field a worker cannot fabricate its way through the way
it can through `Risks: none`. *"Read `hooks/t4-gate` and `tests/guards/`; ran
nothing; did not open the PAL config"* is a sentence whose falsity is checkable.

## Why `confidence` is coarse

`high` / `medium` / `low`. A percentage with no calibration procedure behind it is a
decoration that reads as rigour.

## The one contradiction that is normalised rather than rejected

`decision_status: ready` together with `user_decision_required: true` is
inconsistent. **Normalise to `needs_user_input`.** The worker got the substance right
and the metadata wrong; rejecting the whole response would lose the substance.
