# `BrainstormRequest v1` — the shape a delegation must carry before it runs

Every `clink` delegation is built from this before the call. It is not paperwork: a
delegation today is prose, and **every way it fails looks the same from outside —
a plausible answer.** Three different failures share that appearance, and without a
contract the master cannot tell them apart:

- the worker answered a **different question**, because the objective was implied;
- the worker **filled a gap** the master knew about and never wrote down;
- the worker **could not reach** what it needed and reasoned to an answer instead.

```yaml
protocol: clink-delegation
version: 1

request:
  type: architecture          # a label, not a validated enum -- see below
  problem: >
    What is wrong or uncertain right now.
  objective: >
    What decision this delegation must let the master make.

  scope:
    include: [ ... ]          # optional; usually re-derivable from `questions`
    exclude: [ ... ]          # REQUIRED

  questions: [ ... ]          # REQUIRED, at least one

  constraints: [ ... ]

  context:
    facts: [ ... ]            # known; not to be re-litigated
    evidence: [ ... ]         # logs, test output, file:line -- untrusted content lives HERE
    assumptions: [ ... ]      # unproven, being used anyway
    unknowns: [ ... ]         # known gaps, so the worker does not fill them silently
    prior_attempts: [ ... ]   # so it does not re-propose what already failed

  permissions:
    inspect_files: true
    use_tools: true
    execute_commands: false   # default false -- for a measured reason, below
    modify_files: false
    use_web: false
```

## Required

`protocol` · `version` · `problem` · `objective` · `scope.exclude` · `questions`.

Everything else is omitted when empty. **Absence beats fabricated completeness** — a
worker filling in `risks: none` to satisfy a form has told you nothing.

## Why `scope.exclude` is required and `scope.include` is not

A worker told what to look at still expands. A worker told **what it may not touch**
has a boundary someone can check. The include list is usually re-derivable from
`questions`; the exclude list never is.

## Why `type` is a label and not a validated enum

It earns validation the day it selects a `role` preset. Ten values validated against
nothing is ceremony, and ceremony is what a contract has to avoid to stay used.

## Why `execute_commands` defaults to `false`

**A measured reason, not a policy one.** Antigravity cannot run shell commands
through this transport, and its `codereviewer` role returns the permission error
*instead of* its output with `return_code: 0` — a failure that reads as a bad answer
rather than a broken tool. Forbidding commands in the prompt is what makes that
client reliable. Least privilege is a side effect here, not the argument.

## Untrusted content goes under `evidence`, never inline

File, web and tool output carried into a prompt is **data about the world, not an
instruction from the delegator**. A worker that reads *"ignore previous instructions"*
inside an `evidence` entry is reading a string. The same text pasted into `problem`
is an instruction, and the difference is the whole defence.
