# Product

<!-- lang:en -->
> This is the product brief (users, purpose, brand). The **visual design system** —
> color tokens, typography, components, do/don'ts — is canonical in **`DESIGN.md`**;
> the brand/principles below are the "why", DESIGN.md is the "how".
> (xeno-skills is a developer-tools library, not a visual product — DESIGN.md is not
> applicable and is intentionally absent.)

## Users
- **T4-team coding agents** — the primary user. Agents in T4 Labs / Slow-Inc repos (MangaDock,
  T4-Fastwork, xeno-skills itself) that need the operating standard (memory, workflow,
  enforcement) to survive sessions and stay correct.
- **Other Claude Code / agent users** — humans and agents installing `xeno-skills` via
  `npx skills add` or the plugin to get the same skills and hooks.

## Product Purpose
A library of agent skills and workflow-enforcement hooks that make agent-primary repos correct,
verifiable, and self-consistent. It **succeeds when**: a fresh agent in a bootstrapped repo can
recover state, route a task, ship it test-first with a tracked issue, and cannot silently skip
the rules — measured by this repo's own `tests/` and by the composition audits in `docs/research/`.

## Brand Personality
- **Verifiable** — every claim ships with a test; a documented-but-unenforced claim is a defect.
- **Surgical** — the T4 layer is a thin team-specific slice on top of superpowers / mattpocock /
  9arm; it hands technique off rather than duplicating it.
- **Retrieval-first** — memory is an index you open one slice of, never a wall to read whole.
- **Honest about limits** — the docs name what hooks can't enforce (judgment) as clearly as what
  they can (checkable actions).

## Anti-references
- **Theater enforcement** — a "gate" nobody runs, a "required check" that isn't required, a
  documented vocabulary with no labels behind it. The repo's own audits exist because these
  defects were real.
- **Paperwork** — docs that are team formality rather than the agent's operating manual.

## Design Principles
1. **Documented ≠ enforced** — every rule has a test, or it's a defect.
2. **Index-then-open** — memory and docs are pointers to slices, not monoliths.
3. **Simple + maintainable + sustainable** — the default for any decision; performance (agent
   context budget) is part of "sustainable".
4. **Bilingual, not summarized** — the Thai mirror matches the English depth exactly.

## Accessibility & Inclusion
- Agent-facing, text-first library: WCAG mostly N/A, but docs are written for both Thai and
  English readers (full bilingual mirror, never a summary).
<!-- lang:end -->

<!-- lang:th -->
> นี่คือ product brief (users, purpose, brand) **visual design system** — color tokens,
> typography, components, do/don'ts — อยู่ใน **`DESIGN.md`** เป็นหลัก; brand/principles ข้างล่างคือ
> "why" DESIGN.md คือ "how"
> (xeno-skills เป็น library เครื่องมือสำหรับ developer ไม่ใช่ product ภาพ — DESIGN.md ไม่เกี่ยวข้อง
> จึงตั้งใจไม่สร้าง)

## ผู้ใช้
- **coding agent ของทีม T4** — ผู้ใช้หลัก agent ใน repo ของ T4 Labs / Slow-Inc (MangaDock,
  T4-Fastwork, ตัว xeno-skills เอง) ที่ต้องการมาตรฐานการทำงาน (memory, workflow, enforcement)
  เพื่อให้รอดข้าม session และทำงานถูกต้อง
- **ผู้ใช้ Claude Code / agent อื่น** — คนและ agent ที่ติดตั้ง `xeno-skills` ผ่าน `npx skills add`
  หรือ plugin เพื่อให้ได้ skills และ hooks เดียวกัน

## วัตถุประสงค์ของ product
library ของ agent skills และ workflow-enforcement hooks ที่ทำให้ repo แบบ agent-primary ถูกต้อง
ตรวจสอบได้ และ self-consistent — **สำเร็จเมื่อ**: agent ใหม่ใน repo ที่ bootstrap แล้วสามารถกู้
state, route งาน, ship แบบ test-first พร้อม issue ที่ติดตาม และไม่สามารถข้ามกฎโดยไม่มีใครรู้ —
วัดได้จาก `tests/` ของ repo นี้เองและจาก composition audits ใน `docs/research/`

## บุคลิกของแบรนด์
- **ตรวจสอบได้** — ทุกคำอ้าง ship มาพร้อมเทสต์ การอ้างว่ามีแต่ไม่ได้บังคับจริงคือ defect
- **เฉียบคม** — ชั้น T4 เป็นชั้นบางเฉพาะทีมวางบน superpowers / mattpocock / 9arm; ยกเทคนิคให้
  ecosystem แทนการทำซ้ำ
- **retrieval-first** — memory คือ index ที่เปิดทีละชิ้น ไม่ใช่กำแพงให้อ่านทั้งก้อน
- **ซื่อสัตย์เรื่องขีดจำกัด** — docs บอกสิ่งที่ hooks บังคับไม่ได้ (judgment) ชัดเจนเท่ากับสิ่งที่บังคับได้
  (การกระทำที่ตรวจได้)

## สิ่งที่ไม่ใช่แบรนด์เรา
- **Theater enforcement** — "gate" ที่ไม่มีใครรัน "required check" ที่ไม่ได้ required ภาษาที่เขียนไว้
  แต่ไม่มี labels อยู่จริง การ audit ใน repo นี้มีอยู่เพราะ defect พวกนี้เคยเป็นจริง
- **เอกสารองค์กร** — docs ที่เป็นพิธีการของทีม ไม่ใช่คู่มือการทำงานของ agent

## หลักการออกแบบ
1. **Documented ≠ enforced** — ทุกกฎมีเทสต์ หรือไม่ก็เป็น defect
2. **Index-then-open** — memory และ docs เป็น pointer ไปยังชิ้นย่อย ไม่ใช่ก้อนเดียว
3. **Simple + maintainable + sustainable** — ค่าเริ่มต้นของการตัดสินใจใดๆ performance (งบ context
   ของ agent) เป็นส่วนหนึ่งของ "sustainable"
4. **Bilingual ไม่ใช่ย่อ** — ไทย mirror ความลึกของอังกฤษพอดี

## Accessibility & Inclusion
- library แบบ text-first สำหรับ agent: WCAG ส่วนใหญ่ไม่เกี่ยวข้อง แต่ docs เขียนสำหรับทั้งผู้อ่าน
  ไทยและอังกฤษ (mirror เต็มสองภาษา ไม่ใช่บทสรุป)
<!-- lang:end -->
