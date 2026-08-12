<!-- lang:en -->
# Ubiquitous Language

Canonical term glossary for xeno-skills. When a term appears in **bold**, use it exactly
as written — in code identifiers, PR descriptions, issue titles, and team conversations.

## Governance

| Term | Definition | Aliases to avoid |
|------|-----------|-----------------|
| **agent-primary repo** | A repo where the coding agent is the main developer; the docs are its operating manual. | AI-first, agent-driven |
| **standard-shipper** | A repo that ships a standard it must itself follow (tested by its own `tests/`). | meta repo, dogfooding |
| **T4 standard** | The team operating standard: memory-first, evidence-before-verdict, PRD→issues→PR, TDD, bilingual tracker. | — |
| **governed doc** | A root/`docs/agents` doc with the `<!-- lang:en/th -->` full-mirror convention. | — |

## Workflow enforcement

| Term | Definition | Aliases to avoid |
|------|-----------|-----------------|
| **workflow-enforcement hook** | A Claude lifecycle hook (SessionStart / UserPromptSubmit / PreToolUse) that keeps a session on the T4 rails. | nudge script |
| **gate** | The PreToolUse hard wall: blocks `gh pr create` with no issue, dangerous git, and merges past a failed `verify`. | — |
| **guards layer** | The git `pre-push` + CI tier (issue-ref, tree-budget, gate-ledger) that binds every agent and human. | — |
| **verify** | The repo's fast test command (`.claude/t4.json` `"verify"`) the gate runs itself before `gh pr merge`. | — |
| **bootstrap** | Installing the T4 operating layer (CLAUDE.md, memory, agents, hooks, guards, CI) into a repo. | scaffolding |
| **standing default** | A session-start instruction that must be re-invoked at every phase boundary, not read once. | — |

## Delegation (multi-agent skills)

| Term | Definition | Aliases to avoid |
|------|-----------|-----------------|
| **clink** | PAL's CLI-delegation tool; orchestrates independent CLI agents (Codex, Antigravity). Not configured in this environment. | — |
| **delegation** | Handing a bounded chunk of work to a subagent via clink; verify everything it returns. | — |
| **brainstorm** | Fanning a question out to multiple independent agents and synthesizing one recommendation. | — |
| **effort ladder** | The model×effort routing ladder calibrated by docs/research. | — |

## Relationships

- A **standard-shipper** ships **workflow-enforcement hooks** that a **gate** and the **guards layer** enforce.
- A **governed doc** is written for an **agent-primary repo** under the **T4 standard**.

## Flagged ambiguities

- **"hooks"** in this repo means the enforcement hooks, not git hooks — but `.githooks/` holds the **guards layer**, which IS git hooks. The guard scripts live under `.githooks/`, the Claude hooks under `hooks/` (canonical) and `.claude/hooks/` (installed copies).
- **"delegation" vs "brainstorm"**: delegation asks an agent to *do work*; brainstorm asks it for *an opinion*. The skills differ accordingly.
<!-- lang:end -->

<!-- lang:th -->
# Ubiquitous Language — คำศัพท์มาตรฐาน

glossary คำศัพท์มาตรฐานของ xeno-skills เมื่อคำใดปรากฏเป็น **ตัวหนา** ให้ใช้คำนั้นตรงตามที่เขียน —
ทั้งใน code identifiers, PR descriptions, issue titles และการสนทนาในทีม

## Governance

| คำศัพท์ | นิยาม | alias ที่ควรเลี่ยง |
|------|-----------|-----------------|
| **agent-primary repo** | repo ที่ coding agent เป็น developer หลัก docs คือคู่มือการทำงาน | AI-first, agent-driven |
| **standard-shipper** | repo ที่ ship มาตรฐานซึ่งตัวเองต้องปฏิบัติตาม (มี `tests/` ของตัวเองยืนยัน) | meta repo, dogfooding |
| **T4 standard** | มาตรฐานการทำงานของทีม: memory-first, หลักฐานก่อน verdict, PRD→issues→PR, TDD, bilingual tracker | — |
| **governed doc** | doc ที่ root/`docs/agents` ซึ่งมี convention mirror เต็มแบบ `<!-- lang:en/th -->` | — |

## Workflow enforcement

| คำศัพท์ | นิยาม | alias ที่ควรเลี่ยง |
|------|-----------|-----------------|
| **workflow-enforcement hook** | lifecycle hook ของ Claude (SessionStart / UserPromptSubmit / PreToolUse) ที่ดึง session อยู่บนราง T4 | nudge script |
| **gate** | กำแพงแข็งของ PreToolUse: บล็อก `gh pr create` ที่ไม่มี issue, git อันตราย และ merge ที่ `verify` ไม่ผ่าน | — |
| **guards layer** | tier ของ git `pre-push` + CI (issue-ref, tree-budget, gate-ledger) ที่ผูกทุก agent และคน | — |
| **verify** | คำสั่งเทสต์เร็วของ repo (`.claude/t4.json` `"verify"`) ที่ gate รันเองก่อน `gh pr merge` | — |
| **bootstrap** | การติดตั้ง operating layer ของ T4 (CLAUDE.md, memory, agents, hooks, guards, CI) เข้า repo | scaffolding |
| **standing default** | คำสั่งตอนเริ่ม session ที่ต้อง invoke ซ้ำทุกขอบ phase ไม่ใช่อ่านครั้งเดียว | — |

## Delegation (multi-agent skills)

| คำศัพท์ | นิยาม | alias ที่ควรเลี่ยง |
|------|-----------|-----------------|
| **clink** | เครื่องมือ delegating ของ PAL; orchestrate CLI agent อิสระ (Codex, Antigravity) ยังไม่ config ใน environment นี้ | — |
| **delegation** | มอบหมายงานที่มีขอบเขตชัดให้ subagent ผ่าน clink; ต้อง verify ทุกอย่างที่มันคืนมา | — |
| **brainstorm** | กระจายคำถามไปยัง agent อิสระหลายตัวแล้วสังเคราะห์เป็นข้อเสนอเดียว | — |
| **effort ladder** | routing ladder แบบ model×effort ที่ปรับเทียบจาก docs/research | — |

## ความสัมพันธ์

- **standard-shipper** ship **workflow-enforcement hooks** ที่ **gate** และ **guards layer** บังคับใช้
- **governed doc** เขียนสำหรับ **agent-primary repo** ภายใต้ **T4 standard**

## ความกำกวมที่ต้องจับตา

- **"hooks"** ใน repo นี้หมายถึง enforcement hooks ไม่ใช่ git hooks — แต่ `.githooks/` คือ **guards layer** ซึ่งเป็น git hooks จริง ตัว guard อยู่ใต้ `.githooks/`, Claude hooks อยู่ใต้ `hooks/` (ต้นฉบับ) และ `.claude/hooks/` (copy ที่ติดตั้ง)
- **"delegation" vs "brainstorm"**: delegation สั่งให้ agent *ทำงาน*; brainstorm ขอ *ความเห็น* ทั้งสอง skill ต่างกันตามนั้น
<!-- lang:end -->
