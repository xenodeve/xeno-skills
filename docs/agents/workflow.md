<!-- lang:en -->
# Agent Workflow

How agents plan and implement in this repo, and which skills to invoke automatically.

## Development workflow

When planning or implementing a feature, follow this order:

1. **`/grill-me`** — stress-test the concept first (interview-style)
2. **`/grill-with-docs`** — challenge the plan against existing ADRs in `docs/adr/`
3. **Survey the change sites** — enumerate every place the change touches, before the plan exists (see the skill)
4. **`/to-prd`** — create a PRD from the grilled plan (one PRD per epic), carrying the survey as its change inventory
5. **`/to-issues`** — break the PRD into GitHub issues on `xenodeve/xeno-skills` with triage labels (one issue per deliverable)
6. **`/tdd`** — implement test-first, then make the tests pass

Hard ordering: **PRD → issues → PR**. Never open a PR without a referenced issue.

## Auto-triggered skills

| Trigger | Skill | Condition |
|---|---|---|
| Bug / error / stack trace | `/debug-mantra` | Start a debug session every time |
| After fixing a bug | `/post-mortem` | Record root cause + fix + validation |
| After writing or changing code | `/simplify` | Before committing — check over-engineering |
| Editing UI / frontend | `/impeccable` | Every time a component or CSS is touched |
| Before merge / ship | `/code-review` + `/scrutinize` | Correctness + outsider perspective |
| Touching a security boundary | `/security-review` | Every time code crosses auth/secret/token |
| After implementation | `/verify` | Confirm the feature works in the app |

## Verification mandate

Run `bash tests/hooks/run-all.sh` to verify every change — the bash contract suite is the
repo's test suite (hooks + gate + guards + skills) and its CI `tests` job. This repo has no
frontend; the closest to an end-to-end check is the CI `skill-discovery` job, which runs the
real installer (`npx skills@1 add . --list`) and asserts every `SKILL.md` is discoverable — run
it locally when a skill's directory structure changes, since the installer stops descending at
the first `SKILL.md` in a directory (see #45).
<!-- lang:end -->

<!-- lang:th -->

# Workflow ของ Agent

วิธีที่ agent วางแผนและ implement ใน repo นี้ และ skill ใดที่ควร invoke อัตโนมัติ

## Development workflow

เมื่อวางแผนหรือ implement feature ให้ทำตามลำดับนี้:

1. **`/grill-me`** — ทดสอบแนวคิดก่อน (แบบ interview)
2. **`/grill-with-docs`** — ท้าทายแผนกับ ADR ที่มีใน `docs/adr/`
3. **Survey change sites** — ระบุทุกจุดที่การเปลี่ยนแปลงแตะถึง ก่อนที่จะมีแผน (ดูใน skill)
4. **`/to-prd`** — สร้าง PRD จากแผนที่ grill แล้ว (หนึ่ง PRD ต่อหนึ่ง epic) พร้อม change inventory
5. **`/to-issues`** — แตก PRD เป็น GitHub issues บน `xenodeve/xeno-skills` พร้อม triage labels (หนึ่ง issue ต่อหนึ่ง deliverable)
6. **`/tdd`** — implement แบบ test-first แล้วทำให้เทสต์ผ่าน

ลำดับบังคับ: **PRD → issues → PR** ห้ามเปิด PR โดยไม่มี issue อ้างอิง

## Auto-triggered skills

| Trigger | Skill | เงื่อนไข |
|---|---|---|
| Bug / error / stack trace | `/debug-mantra` | เริ่ม debug session ทุกครั้ง |
| หลังแก้ bug | `/post-mortem` | บันทึก root cause + fix + validation |
| หลังเขียน/เปลี่ยนโค้ด | `/simplify` | ก่อน commit — เช็ค over-engineering |
| แก้ UI / frontend | `/impeccable` | ทุกครั้งที่แตะ component หรือ CSS |
| ก่อน merge / ship | `/code-review` + `/scrutinize` | correctness + มุมมองคนนอก |
| แตะ security boundary | `/security-review` | ทุกครั้งที่โค้ดข้าม auth/secret/token |
| หลัง implementation | `/verify` | ยืนยันว่า feature ทำงานจริงในแอป |

## Verification mandate

รัน `bash tests/hooks/run-all.sh` เพื่อ verify ทุกการเปลี่ยนแปลง — bash contract suite คือ
ชุดเทสต์ของ repo (hooks + gate + guards + skills) และตรงกับ CI job `tests` repo นี้ไม่มี
frontend; สิ่งที่ใกล้เคียง E2E มากที่สุดคือ CI job `skill-discovery` ซึ่งรัน installer จริง
(`npx skills@1 add . --list`) และยืนยันว่าทุก `SKILL.md` ถูกค้นพบ — รันเองเมื่อโครงสร้าง
directory ของ skill เปลี่ยน เพราะ installer หยุดไล่ลงที่ `SKILL.md` แรกของ directory (ดู #45)

<!-- lang:end -->
