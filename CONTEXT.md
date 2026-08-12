<!-- lang:en -->
# xeno-skills System Context

## Language

> **Canonical glossary = `UBIQUITOUS_LANGUAGE.md`** (root). The terms below are a
> local quick-reference for this document; if they ever disagree, `UBIQUITOUS_LANGUAGE.md` wins.

**Agent-primary repo**:
A repo where the coding agent is the main developer, so the repo's docs are its operating manual,
not team paperwork. The T4 standard exists to make that survivable across sessions (memory layer)
and correct (workflow enforcement).
_Avoid_: "AI-first", "agent-driven"

**Standard-shipper**:
A repo that ships a standard it must itself follow — every rule/figure/contract here is tested by
`tests/`, and a documented-but-unenforced claim is a defect.
_Avoid_: "meta", "dogfooding repo"

**Workflow-enforcement hook**:
A lifecycle hook (SessionStart / UserPromptSubmit / PreToolUse) that keeps an agent session on the
T4 rails. The PreToolUse gate is the only hard wall; injects are reminders.
_Avoid_: "nudge script"

### Example dialogue

> **Dev A:** "Let me just install the plugin; the hooks will fire from there."
> **Dev B:** "This repo ships the hooks in `hooks/` AND the bootstrap copy in `references/hooks/` — they must stay byte-identical (`test-bootstrap-sync.sh`). Editing one alone is a defect."

---

## Hooks Architecture — 2026-08-09

### The two delivery paths
Path A (bootstrap): `.claude/hooks/` copies committed into a repo, resolved via `${CLAUDE_PROJECT_DIR}`
— travel with the repo via git. Path B (plugin): `${CLAUDE_PLUGIN_ROOT}/hooks/`, registered on install.
The per-`session_id` lock (`$TMPDIR/t4-hooks/<id>.session-start`) prevents double injection when both
are present.

### Truth Hierarchy
```
hooks/ (root)             canonical — edit here
skills/t4/t4-project-bootstrap/references/hooks/   byte-identical copy — CI-pinned
.claude/hooks/ (in a consumer repo)                copy installed by bootstrap
```

## CI Architecture — 2026-08-09

### Jobs
```
T4 verify (workflow)
├── tests             bash tests/hooks/run-all.sh — the contract suite (fast prefix of CI)
└── skill-discovery   npx skills@1 add . --list — every SKILL.md discoverable by the real installer
```
The repo also runs the git guards (`check-tree-budget`, `check-gate-ledger`, `check-issue-ref`) in
the `tests` job — the same scripts the local `.githooks/pre-push` runs, so they cannot be bypassed.
<!-- lang:end -->

<!-- lang:th -->
# xeno-skills System Context — ภาษาไทย

## ภาษา

> **Glossary หลัก = `UBIQUITOUS_LANGUAGE.md`** (root) ข้อความด้านล่างเป็น quick-reference เฉพาะ
> เอกสารนี้ ถ้าไม่ตรงกัน `UBIQUITOUS_LANGUAGE.md` ชนะ

**Agent-primary repo**:
repo ที่ coding agent เป็น developer หลัก ดังนั้น docs ของ repo คือคู่มือการทำงานของ agent ไม่ใช่
เอกสารองค์กร มาตรฐาน T4 มีไว้เพื่อให้ทำงานนี้รอดข้าม session (memory layer) และถูกต้อง (workflow enforcement)
_Avoid_: "AI-first", "agent-driven"

**Standard-shipper**:
repo ที่ ship มาตรฐานซึ่งตัวเองต้องปฏิบัติตาม — ทุกกฎ/ตัวเลข/contract ที่นี่มี `tests/` ยืนยัน และ
การอ้างว่ามีแต่ไม่ได้บังคับจริงคือ defect
_Avoid_: "meta", "dogfooding repo"

**Workflow-enforcement hook**:
lifecycle hook (SessionStart / UserPromptSubmit / PreToolUse) ที่ดึง session ให้อยู่บนราง T4
PreToolUse gate คือกำแพงแข็งเพียงอย่างเดียว ส่วน inject เป็นแค่การเตือน
_Avoid_: "nudge script"

### ตัวอย่างบทสนทนา

> **Dev A:** "ติดตั้ง plugin ก่อนเลย เดี๋ยว hooks ยิงจากตรงนั้น"
> **Dev B:** "repo นี้ ship hooks ทั้งใน `hooks/` และ copy ใน `references/hooks/` — สองที่ต้อง
> byte-identical กันเสมอ (`test-bootstrap-sync.sh`) แก้ทีเดียวผิดคือ defect"

---

## Hooks Architecture — 2026-08-09

### เส้นทางการส่งสองแบบ
Path A (bootstrap): `.claude/hooks/` ที่ commit เข้า repo แก้ผ่าน `${CLAUDE_PROJECT_DIR}` — เดินทาง
ไปกับ repo ผ่าน git Path B (plugin): `${CLAUDE_PLUGIN_ROOT}/hooks/` ลงทะเบียนตอนติดตั้ง
lock ต่อ `session_id` (`$TMPDIR/t4-hooks/<id>.session-start`) กันการ inject ซ้ำเมื่อมีทั้งสอง

### ลำดับความจริง
```
hooks/ (root)             ต้นฉบับ — แก้ที่นี่
skills/t4/t4-project-bootstrap/references/hooks/   copy ที่ byte-identical — CI คอย pin
.claude/hooks/ (ใน repo ที่บริโภค)                   copy ที่ bootstrap ติดตั้งให้
```

## CI Architecture — 2026-08-09

### Jobs
```
T4 verify (workflow)
├── tests             bash tests/hooks/run-all.sh — ชุดเทสต์ contract (fast prefix ของ CI)
└── skill-discovery   npx skills@1 add . --list — ทุก SKILL.md ถูกค้นพบโดย installer จริง
```
repo นี้ยังรัน git guards (`check-tree-budget`, `check-gate-ledger`, `check-issue-ref`) ใน job `tests`
— script เดียวกับที่ `.githooks/pre-push` รันในเครื่อง จึง bypass ไม่ได้
<!-- lang:end -->
