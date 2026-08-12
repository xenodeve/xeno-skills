<!-- lang:en -->
# CLAUDE.md — xeno-skills (T4 agent-primary repo)

> Agent operating manual. **Read fully at session start.** The `using-t4` entry map below is a
> **standing default**, not a pointer to read once: re-route at every phase boundary. This repo is
> the T4 standard-shipper — the rules here are the ones it ships.

## North-star

Ship agent skills and workflow-enforcement hooks that make agent-primary repos (like this one)
correct, verifiable, and self-consistent. This repo documents a standard it must itself follow:
every rule, figure, or contract it ships is tested by `tests/`, and a documented-but-unenforced
claim is a defect (see the composition audits in `docs/research/2026-08-04-*`).

## Repo layout

- `skills/` — the skills: `multi-agent/` (clink delegation), `t4/` (the T4 standard incl. this
  bootstrap), `design/` (web/UI), `karpathy-guidelines/` (coding guardrails).
- `hooks/` — **canonical** workflow-enforcement hook scripts (the plugin's path-B copies).
- `.claude-plugin/` — plugin manifest.
- `tests/` — the bash contract suite (hooks, gate, guards, skills). CI job `tests` runs it.
- `docs/` — `adr/`, `research/` (empirical data that calibrated the skills), `plans/`, `agents/`.
- Memory: `docs/OPEN-WORK-LEDGER.md`, `DONE.md`, `Obsidian-xeno-skills/Home.md`.

## Commands

- **Test / verify (fast prefix of CI):** `bash tests/hooks/run-all.sh` — runs every `test-*.sh`.
  This is the `.claude/t4.json` `"verify"`; the gate runs it before `gh pr merge`.
- **E2E / skill discovery (CI only):** `npx --yes skills@1 add . --list` — asserts every
  `SKILL.md` is discoverable by the real installer (installer stops descending at a dir's own
  `SKILL.md`, #45). Run locally when a skill's directory structure changes.
- **Git-bash on Windows:** `C:\Program Files\Git\bin\bash.exe` (hooks resolve it via `run-hook.cmd`).

## Session-start read protocol

1. `Obsidian-xeno-skills/Home.md` (vault index) — open only the notes the task touches.
2. `docs/OPEN-WORK-LEDGER.md` — current open work, tracked and untracked.
3. The GitHub issue you're picking up — `gh issue view <n> --comments`.
4. `DONE.md` / `docs/research/` only if the task needs history or provenance.

## Session-end protocol — write the skill-usage entry

Before the session ends, write one entry to `Obsidian-xeno-skills/skill-usage/<YYYY-MM-DD>-<slug>.md`
(skeleton and rules in `t4-agent-memory`). It records **skill↔behaviour only** — what shipped goes in
`DONE.md`, what is still open goes in the ledger.

This is the repo's feedback database: read it *before changing a skill*, instead of designing a
benchmark for one. Three rules make it worth having:

- **A session that skipped a rule records the skip** — especially the embarrassing case. An empty
  section is written out as `none observed`; dropping it turns silence into an unearned pass.
- **Only what happened in this session.** A reconstructed retrospective is a hypothesis.
- **Name the skill file and quote what was actually written or done**, or the next agent cannot act
  on it.

**No hook produces this entry and none can** (`docs/adr/0001-hook-based-workflow-enforcement.md`) —
a missing entry means a missing entry, not a session in which nothing went wrong.

## using-t4 — standing default (invoke at every phase boundary)

This repo follows the T4 operating standard. **Re-route at every phase boundary:** a check at task
start does **not** discharge a later trigger. After writing code → `simplify`; before merge →
`code-review` + `scrutinize`; touched auth/secrets → `security-review`; done → `verify`. When a task
matches a `t4-*` skill or a companion-ecosystem skill (superpowers, mattpocock, 9arm), invoke it
before acting — don't work from memory; skills evolve. The non-negotiable rules (evidence before
verdict, root cause before fix, proof before skipping, PRD → issues → PR, TDD, bilingual tracker)
are carried by `using-t4` — load it at session start and follow it through the session.

**clink-masteragent wiring:** NOT wired. `clink` (PAL MCP) is not configured in this environment,
so the delegation tier is not a session default. If `clink` is added, decide between *invoke before
any `clink` call* (cheap) and *load at session start* (~19 KB every session) and record the choice
here — until then this stands as a deliberate decision, not an omission.

## Dev notification

Notify the developer (toast via `scripts/notify.ps1` if present, else the push tool) on: a
TDD cycle / long task complete, needing a confirm (before closing issues / merging), or an AFK
batch done — not routine sub-progress.

## Writing conventions (bilingual)

- **GitHub tracker** (issue/PRD/PR bodies): English + a **full Thai mirror**, same depth — never a
  summary. Identifiers stay English. See `docs/agents/issue-tracker.md`.
- **Governed docs** (`CONTEXT.md`, `UBIQUITOUS_LANGUAGE.md`, `PRODUCT.md`, `docs/agents/*`):
  `<!-- lang:en -->` … `<!-- lang:end -->` / `<!-- lang:th -->` … `<!-- lang:end -->` full mirror.
- **Chat, reports, status updates:** single-language (Thai).
- **Code, commit messages, inline comments:** English.

## Agents docs pointers

- Workflow & auto-triggered skills → `docs/agents/workflow.md`
- Issue tracker & bilingual bodies → `docs/agents/issue-tracker.md`
- Triage labels (canonical roles + T4 delta) → `docs/agents/triage-labels.md`
- Domain doc consumption rules → `docs/agents/domain.md`
- Domain glossary → `CONTEXT.md` (canonical: `UBIQUITOUS_LANGUAGE.md`)

## Self-consistency rules (this repo only)

- Editing a root `hooks/` script ⇒ re-copy it to `skills/t4/t4-project-bootstrap/references/hooks/`
  in the same change (`test-bootstrap-sync.sh` byte-compares).
- Editing hook wiring ⇒ update both `hooks/hooks.json` (plugin) and the bootstrap
  `references/hooks/settings.json` (`test-wiring-parity.sh`).
- A new rule/claim in a skill ⇒ a `tests/skills/test-*.sh` asserting it. Documented ≠ enforced.

<!-- lang:th -->
# CLAUDE.md — xeno-skills (T4 repo แบบ agent-primary)

> คู่มือการทำงานของ agent **อ่านให้ครบตอนเริ่ม session** entry map `using-t4` ด้านล่างเป็น **ค่า
> เริ่มต้นถาวร** ไม่ใช่ pointer ที่อ่านครั้งเดียว — ต้อง re-route ทุกครั้งที่ข้าม phase repo นี้เป็น
> **ตัว ship มาตรฐาน T4** — กฎที่เขียนที่นี่คือกฎที่ repo นี้เป็นคนแจกจ่าย

## เป้าหมาย (North-star)

Ship agent skills และ workflow-enforcement hooks ที่ทำให้ repo แบบ agent-primary (รวมทั้ง repo นี้)
ถูกต้อง ตรวจสอบได้ และ self-consistent — repo นี้เป็นมาตรฐานที่ตัวเองต้องปฏิบัติตาม: ทุกกฎ/ตัวเลข/
contract ที่ ship ออกไปต้องมี `tests/` คอยยืนยัน และการอ้างว่ามีแต่ไม่ได้บังคับจริงคือ defect
(ดู composition audits ใน `docs/research/2026-08-04-*`)

## โครงสร้าง repo

- `skills/` — ตัว skills: `multi-agent/` (clink delegation), `t4/` (มาตรฐาน T4 รวม bootstrap นี้),
  `design/` (web/UI), `karpathy-guidelines/` (guardrails การเขียนโค้ด)
- `hooks/` — **ต้นฉบับ** ของ workflow-enforcement hooks (path-B ของ plugin)
- `.claude-plugin/` — plugin manifest
- `tests/` — ชุดเทสต์ bash (hooks, gate, guards, skills) — CI job `tests` รันชุดนี้
- `docs/` — `adr/`, `research/` (ข้อมูลเชิงประจักษ์ที่ปรับเทียบ skills), `plans/`, `agents/`
- Memory: `docs/OPEN-WORK-LEDGER.md`, `DONE.md`, `Obsidian-xeno-skills/Home.md`

## คำสั่ง

- **Test / verify (fast prefix ของ CI):** `bash tests/hooks/run-all.sh` — รันทุก `test-*.sh`
  นี่คือค่า `"verify"` ใน `.claude/t4.json`; gate จะรันก่อน `gh pr merge`
- **E2E / skill discovery (เฉพาะ CI):** `npx --yes skills@1 add . --list` — ยืนยันว่าทุก
  `SKILL.md` ถูกค้นพบโดย installer จริง (installer หยุดไล่ directory ที่มี `SKILL.md` ของตัวเอง, #45)
  — รันเองเมื่อโครงสร้าง directory ของ skill เปลี่ยน
- **Git-bash บน Windows:** `C:\Program Files\Git\bin\bash.exe` (hooks ค้นผ่าน `run-hook.cmd`)

## วิธีอ่านตอนเริ่ม session

1. `Obsidian-xeno-skills/Home.md` (vault index) — เปิดเฉพาะ note ที่งานแตะถึง
2. `docs/OPEN-WORK-LEDGER.md` — งานที่ค้างอยู่ ทั้งที่มีและไม่มี issue
3. ตัว issue ที่กำลังหยิบ — `gh issue view <n> --comments`
4. `DONE.md` / `docs/research/` เฉพาะเมื่องานต้องการ history หรือ provenance

## using-t4 — ค่าเริ่มต้นถาวร (invoke ทุกขอบ phase)

repo นี้ใช้มาตรฐานการทำงาน T4 **Re-route ทุกขอบ phase:** การตรวจตอนเริ่ม task **ไม่ได้** ตัดสิทธิ์
trigger ที่จะเกิดทีหลัง เขียนโค้ดเสร็จ → `simplify`; ก่อน merge → `code-review` + `scrutinize`;
แตะ auth/secrets → `security-review`; เสร็จ → `verify` เมื่อ task ตรงกับ skill `t4-*` หรือ
companion ecosystem (superpowers, mattpocock, 9arm) ให้ invoke ก่อนลงมือ — อย่าทำจากความจำ
เพราะ skills มีการพัฒนา กฎที่ไม่ negotiable (หลักฐานก่อน verdict, root cause ก่อน fix, proof ก่อน
skip, PRD → issues → PR, TDD, bilingual tracker) อยู่ใน `using-t4` — โหลดตอนเริ่ม session และทำตามทั้ง session

**clink-masteragent wiring:** NOT wired — `clink` (PAL MCP) ยังไม่ได้ config ใน environment นี้
ดังนั้น delegation tier จึงไม่ใช่ค่าเริ่มต้นของ session ถ้าเพิ่ม `clink` ให้ตัดสินใจระหว่าง
*invoke ก่อนทุก `clink` call* (ประหยัด) กับ *โหลดตอนเริ่ม session* (~19 KB ทุก session) แล้วจดไว้ที่นี่
— จนกว่าจะถึงตอนนั้น นี่คือการตัดสินใจที่ตั้งใจ ไม่ใช่การมองข้าม

## การแจ้งเตือน developer

แจ้ง (toast ผ่าน `scripts/notify.ps1` ถ้ามี หรือ push tool) เมื่อ: TDD cycle / งานยาวเสร็จ,
ต้องให้คนยืนยัน (ก่อนปิด issue / merge), หรือ AFK batch จบ — ไม่ใช่ทุกความคืบหน้าเล็กๆ

## ข้อตกลงการเขียน (bilingual)

- **GitHub tracker** (issue/PRD/PR body): อังกฤษ + **ไทยที่ mirror เต็ม** ความลึกเท่ากัน — ห้ามสรุป
  identifiers ต้องเป็นอังกฤษ ดู `docs/agents/issue-tracker.md`
- **Governed docs** (`CONTEXT.md`, `UBIQUITOUS_LANGUAGE.md`, `PRODUCT.md`, `docs/agents/*`):
  `<!-- lang:en -->` … `<!-- lang:end -->` / `<!-- lang:th -->` … `<!-- lang:end -->` mirror เต็ม
- **Chat, reports, status updates:** ภาษาเดียว (ไทย)
- **โค้ด, commit message, inline comment:** อังกฤษ

## ตัวชี้ docs/agents

- Workflow และ auto-triggered skills → `docs/agents/workflow.md`
- Issue tracker และ bilingual bodies → `docs/agents/issue-tracker.md`
- Triage labels (roles มาตรฐาน + T4 delta) → `docs/agents/triage-labels.md`
- กฎการอ่าน domain docs → `docs/agents/domain.md`
- Domain glossary → `CONTEXT.md` (canonical: `UBIQUITOUS_LANGUAGE.md`)

## กฎ self-consistency (เฉพาะ repo นี้)

- แก้ script ใน `hooks/` root ⇒ ต้องคัดลอกไป `skills/t4/t4-project-bootstrap/references/hooks/`
  ในคอมมิทเดียวกัน (`test-bootstrap-sync.sh` เทียบ byte)
- แก้ hook wiring ⇒ ต้องแก้ทั้ง `hooks/hooks.json` (plugin) และ bootstrap
  `references/hooks/settings.json` (`test-wiring-parity.sh`)
- กฎ/คำอ้างใหม่ใน skill ⇒ ต้องมี `tests/skills/test-*.sh` ยืนยัน — "เขียนไว้" ≠ "บังคับจริง"

<!-- lang:end -->
