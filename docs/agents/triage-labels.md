<!-- lang:en -->
# Triage Labels

**The five canonical roles and their mapping table come from `/setup-matt-pocock-skills`** — invoke it
rather than reproducing them here. What follows is the **T4 delta**: the groups pocock does not carry.

## The five canonical roles (from setup-matt-pocock-skills)

| Role | Label string in this repo | Meaning |
|---|---|---|
| needs-triage | `needs-triage` | New, not yet assessed |
| needs-info | `needs-info` | Blocked on a question / missing repro |
| ready-for-agent | `ready-for-agent` | Scoped enough for the coding agent to pick up unattended |
| ready-for-human | `ready-for-human` | Needs a human decision, review, or an external action |
| wontfix | `wontfix` | Will not be actioned |

## T4 delta — optional label groups (this repo uses them)

- **Component** — one per issue: `t4`, `hooks`, `multi-agent`, `ci`, `research` (which part of the repo owns it).
- **Type** — one or more: `bug`, `Feature`, `tech-debt`, `security`.
- **Severity** — one per Bug/Security: `critical`, `Major`, `Minor`.

**A `security` issue must carry `critical` or `Major`.** And the vocabulary is not installed until the
labels exist: create them with `gh label create` and report what was created, what was already there,
and what you skipped. A documented vocabulary with no labels behind it reads as configured and is not.

## Conventions

- Every issue has ≥1 triage-state label and exactly one component label.
- `security` issues must be `critical` or `Major` — a `Minor` security label is not valid.
- A `Latent` bug that activates is upgraded to a full Bug issue with severity.
<!-- lang:end -->

<!-- lang:th -->

# Triage Labels

**ห้าบทบาทมาตรฐานและตาราง mapping มาจาก `/setup-matt-pocock-skills`** — invoke มัน
แทนที่จะลอกมาลงที่นี่ ต่อไปนี้คือ **T4 delta**: กลุ่มที่ pocock ไม่มี

## ห้าบทบาทมาตรฐาน (จาก setup-matt-pocock-skills)

| บทบาท | label ใน repo นี้ | ความหมาย |
|---|---|---|
| needs-triage | `needs-triage` | ใหม่ ยังไม่ถูกประเมิน |
| needs-info | `needs-info` | ติดอยู่กับคำถาม / ยังไม่มี repro |
| ready-for-agent | `ready-for-agent` | ขอบเขตพอสำหรับ coding agent หยิบไปทำแบบไม่มีคนเฝ้า |
| ready-for-human | `ready-for-human` | ต้องให้คนตัดสินใจ / review / หรือ action ภายนอก |
| wontfix | `wontfix` | จะไม่ดำเนินการ |

## T4 delta — กลุ่ม label เพิ่มเติม (repo นี้ใช้)

- **Component** — หนึ่งตัวต่อ issue: `t4`, `hooks`, `multi-agent`, `ci`, `research` (ส่วนไหนของ repo เป็นเจ้าของ)
- **Type** — หนึ่งตัวหรือมากกว่า: `bug`, `Feature`, `tech-debt`, `security`
- **Severity** — หนึ่งตัวต่อ Bug/Security: `critical`, `Major`, `Minor`

**issue ที่เป็น `security` ต้องมี `critical` หรือ `Major`** และคำศัพท์จะถือว่าติดตั้งจริงก็ต่อเมื่อ
labels มีอยู่: สร้างด้วย `gh label create` แล้วรายงานว่าสร้างอะไร, อะไรมีอยู่แล้ว, และอะไรที่ข้าม
คำศัพท์ที่มีเอกสารแต่ไม่มี labels รองรับ อ่านเหมือนว่ามีครบทั้งที่จริงไม่ใช่

## ธรรมเนียม

- ทุก issue มี label สถานะ triage ≥1 และ label component หนึ่งตัวพอดี
- `security` ต้องเป็น `critical` หรือ `Major` — label security ที่เป็น `Minor` ไม่ถูกต้อง
- bug แบบ `Latent` ที่เริ่มแสดงผลจริง ถูกอัปเกรดเป็น Bug issue เต็มพร้อม severity

<!-- lang:end -->
