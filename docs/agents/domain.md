<!-- lang:en -->
# Domain Docs

How engineering skills should consume this repo's domain documentation when exploring.

## Layout: Single-context

One `CONTEXT.md` at the root covers the whole repo.

```
/
├── CONTEXT.md              ← domain glossary for the whole repo
├── UBIQUITOUS_LANGUAGE.md  ← canonical term glossary (CONTEXT.md points at it)
├── docs/adr/               ← architectural decision records
├── docs/research/          ← empirical research that calibrated the skills
└── skills/                 ← the skills themselves
```

(Revisit as multi-context — a root `CONTEXT-MAP.md` pointing at one `CONTEXT.md` per
context — once the repo gains a second bounded context.)

## Before exploring, read these

- **`CONTEXT.md`** at the repo root — the system-context doc; the **canonical term glossary is `UBIQUITOUS_LANGUAGE.md`** (`CONTEXT.md` points at it and defers to it on any conflict).
- **`docs/adr/`** — read ADRs touching the area you're about to work in before proposing alternatives.
- **`docs/research/`** — the empirical data (delegation routing, effort ladders) the `multi-agent` skills' figures are drawn from.

If any of these files don't exist, **proceed silently**. Don't flag their absence; don't
suggest creating them upfront. The producer skill (`/grill-with-docs` → `/domain-modeling`)
creates them lazily when terms or decisions actually get resolved.

## Use the glossary's vocabulary

When your output names a domain concept (issue title, refactor proposal, hypothesis, test
name), use the term exactly as defined in `CONTEXT.md`. Don't drift to synonyms the glossary
avoids. If a concept isn't in the glossary yet, that's a signal — either you're inventing
language the project doesn't use (reconsider) or there's a real gap (note it for `/domain-modeling`).

## Flag ADR conflicts

If your output contradicts an existing ADR, surface it explicitly instead of silently overriding:

> _Contradicts ADR-0001 (hook-based workflow enforcement) — but worth reopening because…_
<!-- lang:end -->

<!-- lang:th -->

# Domain Docs

วิธีที่ engineering skills ควรบริโภค domain documentation ของ repo นี้เวลาสำรวจ

## Layout: Single-context

`CONTEXT.md` ตัวเดียวที่ root ครอบคลุมทั้ง repo

```
/
├── CONTEXT.md              ← domain glossary ของทั้ง repo
├── UBIQUITOUS_LANGUAGE.md  ← canonical term glossary (CONTEXT.md ชี้มาที่นี่)
├── docs/adr/               ← architecture decision records
├── docs/research/          ← ข้อมูลเชิงประจักษ์ที่ปรับเทียบ skills
└── skills/                 ← ตัว skills
```

(ทบทวนเป็น multi-context — `CONTEXT-MAP.md` ที่ root ชี้ไปยัง `CONTEXT.md` หนึ่งตัวต่อ context
พร้อม `docs/adr/` ตาม context — เมื่อ repo มี bounded context ที่สอง)

## ก่อนสำรวจ อ่านเหล่านี้

- **`CONTEXT.md`** ที่ repo root — system-context doc; **canonical term glossary คือ `UBIQUITOUS_LANGUAGE.md`** (`CONTEXT.md` ชี้และยอมให้ชนะเมื่อขัดแย้ง)
- **`docs/adr/`** — อ่าน ADR ที่แตะพื้นที่ที่คุณกำลังจะทำงานก่อนเสนอทางเลือก
- **`docs/research/`** — ข้อมูลเชิงประจักษ์ (delegation routing, effort ladders) ที่ตัวเลขของ skills กลุ่ม `multi-agent` อ้างอิง

ถ้าไฟล์ใดไม่มี **ให้ทำต่อไปอย่างเงียบๆ** อย่า flag การไม่มี; อย่าเสนอให้สร้างล่วงหน้า
producer skill (`/grill-with-docs` → `/domain-modeling`) สร้างแบบ lazy เมื่อคำศัพท์หรือการตัดสินใจ
ถูกทำให้เป็นจริง

## ใช้คำศัพท์จาก glossary

เมื่อ output ของคุณตั้งชื่อ concept ใน domain (issue title, refactor proposal, hypothesis, test
name) ให้ใช้คำตรงตาม `CONTEXT.md` อย่าไถลไป synonyms ที่ glossary หลีกเลี่ยง ถ้า concept ไม่ได้
อยู่ใน glossary — เป็นสัญญาณ: คุณกำลังสร้างภาษาที่โปรเจกต์ไม่ใช้ (คิดใหม่) หรือมีช่องว่างจริง
(บันทึกให้ `/domain-modeling`)

## Flag ADR conflicts

ถ้า output ของคุณขัดแย้งกับ ADR ที่มี ให้ชี้ให้เห็นอย่างชัดแจ้ง แทนที่จะ override เงียบๆ:

> _Contradicts ADR-0001 (hook-based workflow enforcement) — แต่คุ้มที่จะเปิดใหม่เพราะ…_

<!-- lang:end -->
