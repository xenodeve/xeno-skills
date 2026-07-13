**🇹🇭 ภาษาไทย** · [🇬🇧 English](./README.en.md)

# xeno-skills

Agent skills สำหรับโหลดเข้า Claude Code

## ความเป็นมา

repo นี้เติบโตมาจากโปรเจกต์ที่ต้องการกำจัดคอขวด "คนกลาง" ของการ brainstorm ด้วย AI — แทนที่จะให้ developer นั่งหน้า terminal คอยตอบคำถามของแต่ละโมเดลทีละข้อ ให้ master agent กระจายปัญหาออกไปยังคณะของ CLI agent อิสระที่ถกกันเองโดยอัตโนมัติ แล้วค่อยสรุปเฉพาะผลลัพธ์สุดท้ายที่สังเคราะห์แล้วขึ้นมาให้คนอนุมัติ

สถาปัตยกรรมนี้บันทึกไว้ใน [`docs/agentic-workflow-presentation.md`](./docs/agentic-workflow-presentation.md) — เอกสารอธิบาย Hybrid Multi-Agent Architecture (Multi-Turn Negotiation Loop + Dynamic Skill Injection) ซึ่งเดิมจัดทำเป็น presentation ของโปรเจกต์

## โครงสร้าง

Skills อยู่ภายใต้ `skills/`:

- `multi-agent/` — การ orchestrate CLI ของ AI หลายตัวให้ทำงานร่วมกัน
- `t4/` — มาตรฐานการทำงานแบบ agent-primary ของทีม T4 (entry map, bootstrap, memory, records, workflow)

แต่ละ skill เป็น directory ของตัวเอง มี `SKILL.md` (พร้อม YAML frontmatter — `name` และ `description`) และไฟล์ reference ที่แนบมา

## การติดตั้ง

### ด้วย `npx skills` (แนะนำ — ใช้ได้กับทุก agent)

```bash
npx skills add xenodeve/xeno-skills
```

ติดตั้ง skill เฉพาะตัวตามชื่อ:

```bash
npx skills add xenodeve/xeno-skills --skill clink-brainstorm
```

## รายการอ้างอิง

### Multi-agent

- **[clink-brainstorm](./skills/multi-agent/clink-brainstorm/SKILL.md)** — กระจายคำถามออกไปยัง CLI agent อิสระหลายตัว (Gemini/Antigravity, Codex, Claude ฯลฯ) ผ่าน tool `clink` ของ [PAL](https://github.com/BeehiveInnovations/pal-mcp-server) แล้วสังเคราะห์เป็นข้อเสนอแนะเดียว แต่ละ agent มี cognitive lens ที่ต่างกัน (Code-centric, System-centric, Logic-centric, Conceptual-centric) ซึ่งกำหนดวิธีปรับ prompt สำหรับการ challenge มี judge-led challenge loop สำหรับตอนที่ agent เห็นไม่ตรงกัน และ adversarial round แบบเจาะ lens สำหรับตอนที่ทุกตัวเห็นตรงกัน (การเห็นตรงกันโดยไม่ถูกกดดัน ≠ การยืนยันว่าถูก) **ต้องมี PAL MCP server** เชื่อมต่อกับ agent ของคุณ พร้อม `clink` CLI agent อย่างน้อยสองตัว

### ทีม T4 (มาตรฐานการทำงานแบบ agent-primary)

ตระกูลของ skill ที่กลั่นออกมาแบบไม่ผูกกับโปรเจกต์เดียว จาก repo ที่โตเต็มที่ของทีม T4 (MangaDock, T4-Fastwork) สำหรับ repo ที่ **coding agent เป็น developer หลัก** ออกแบบมาแบบ retrieval-first เพื่อให้ agent คง context ข้าม session และการ compaction ได้ แต่ละตัวค้นเจอได้เองด้วย trigger ของตัวเอง; `using-t4` เป็น entry map, `t4-project-bootstrap` เป็นตัวติดตั้งไฟล์ ส่วนอีกสามตัวที่เหลือดูแล discipline ที่ทำต่อเนื่อง

- **[using-t4](./skills/t4/using-t4/SKILL.md)** — entry-point map ของทั้งตระกูล (คล้าย `using-superpowers`) ตอนเริ่ม task ใดๆ ใน T4 repo มันจะ route คุณไปยัง skill ที่ถูกต้อง — memory ตอนเริ่ม session, การ setup repo, pipeline ของ feature หรือ engineering record — และแบก non-negotiable rules ของทีมไว้ `CLAUDE.md` ของ repo จะชี้ agent ที่เพิ่งเข้ามาให้มาที่นี่ก่อน
- **[t4-project-bootstrap](./skills/t4/t4-project-bootstrap/SKILL.md)** — scaffold repo T4 ใหม่ (หรือที่ยังมีเอกสารไม่ครบ) ด้วย operating layer ในรอบเดียว: เอกสาร domain/product (`CONTEXT.md`, `UBIQUITOUS_LANGUAGE.md`, `PRODUCT.md`, `DESIGN.md`, `docs/agents/domain.md`), knowledge dir ที่ index ตามสถานะ และการ wiring `CLAUDE.md` — โดย orchestrate สาม skill พี่น้องด้านล่าง แบ่งเป็น tier ตามภาระ context ของ agent (memory layer เปิดเป็น default) พร้อมชุด deliverable ของ Software-Engineering แบบ 7 เฟสให้เลือกเสริม
- **[t4-agent-memory](./skills/t4/t4-agent-memory/SKILL.md)** — working memory ถาวรที่ repo แบบ agent-primary ใช้ขับเคลื่อน: team memory vault (`Home.md` Map-of-Content → note ที่ link กัน), open-work ledger, ship log, survey-provenance cache และ Serena code memories — พร้อม protocol การอ่านตอนเริ่ม session และกฎ retrieval-first (index-then-open, single-source, จำกัดขนาด log, ความสดใหม่เหนือ authority)
- **[t4-engineering-records](./skills/t4/t4-engineering-records/SKILL.md)** — เลือกว่าจะเขียน record แบบไหนเมื่อมีอะไรสำคัญเกิดขึ้น (post-mortem vs ADR vs system-impact entry vs bug-case-catalog) และเขียนอย่างไรให้ยังเป็น index ที่เชื่อถือได้ (`file:line`, commit SHA, เฉพาะที่ validated แล้ว, blameless) มีเทมเพลตให้
- **[t4-dev-workflow](./skills/t4/t4-dev-workflow/SKILL.md)** — pipeline ของ feature (grill→PRD→issues→TDD), gate แบบ PRD→issues→PR, map ของ skill ที่ trigger อัตโนมัติ, triage label, issue lifecycle และกฎ tracker แบบ bilingual (ไทยสะท้อนอังกฤษ) มีเทมเพลต `docs/agents/*` + PRD/spec/plan ให้
- **[t4-afk](./skills/t4/t4-afk/SKILL.md)** — ชั้น discipline สำหรับรัน autonomous batch แบบไม่มีคนเฝ้า: preflight scope-lock (AFK รันได้เฉพาะ worklist ที่อนุมัติไว้ก่อน), เส้นแบ่ง "ตัดสินเองได้ vs ต้อง park", ลูปต่อชิ้นงานที่ปลอดภัย (convention→TDD→gate→checkpoint), เงื่อนไข stop-and-park ที่กัน tree ไม่ให้พัง และวิธีปิดจบ batch ด้วย digest เดียวพร้อม reconcile ทุก issue มีเทมเพลต preflight / park-note / landing-digest ให้ มันไม่ผ่อนกฎ T4 ข้อไหน — มันแค่เอา human checkpoint ออก ดังนั้น gate ต่างๆ ต้องยืนด้วยตัวเอง

## ที่เกี่ยวข้อง

**Companion skill ecosystems** — ตระกูล `t4-*` เป็นชั้นบางๆ เฉพาะทีมที่วางทับสิ่งเหล่านี้; `using-t4` route ไปหาพวกมัน และตั้งใจให้ติดตั้งควบคู่กัน:

- **[superpowers](https://github.com/obra/superpowers)** — process discipline ทั่วไป (brainstorming, TDD, systematic-debugging, writing-plans/skills, verification-before-completion) entry map ของมันเองคือ `superpowers:using-superpowers`; T4 ยกเรื่อง *วิธีการทำงาน* ให้มัน
- **[mattpocock/skills](https://github.com/mattpocock/skills)** — "Skills for Real Engineers" flow ที่ pipeline ของ T4 สร้างขึ้นมาจาก: loop grill→spec→tickets บวกกับ convention ของ issue-tracker / triage-label / domain-doc ที่ T4 นำมาใช้ซ้ำ ติดตั้ง/ตั้งค่าผ่าน `/setup-matt-pocock-skills`
- **[thananon/9arm-skills](https://github.com/thananon/9arm-skills)** — `debug-mantra`, `post-mortem`, `scrutinize`, `qwen-agent` (delegate ไปยัง subagent ราคาถูกที่ขับด้วย Qwen ผ่าน `claude-9arm`), `qwenchance`, `management-talk`

**เครื่องมือ:**

- **[xenodeve/pal-mcp-server](https://github.com/xenodeve/pal-mcp-server)** — fork ของ PAL ที่เพิ่ม clink agent `antigravity` (ตัวสืบทอดของ Gemini จาก Google, `agy`, ผ่าน ConPTY บน Windows) และเทมเพลต `claude-9arm.json.example` สำหรับชี้ `claude` ไปยัง model gateway อื่น เป็นสิ่งที่ต้องมีก่อนจะใช้ `clink-brainstorm` กับ Antigravity หรือ gateway ที่กำหนดเอง

## License

MIT — ดู [LICENSE](LICENSE)
