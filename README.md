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
- `design/` — ตระกูล skill ออกแบบเว็บ/UI (setup, rules, audit, psychology) พร้อมคลัง reference
- `karpathy-guidelines/` — guardrails เชิงพฤติกรรมสำหรับการเขียนโค้ด (T4 โหลดอัตโนมัติตอนเริ่ม session)

แต่ละ skill เป็น directory ของตัวเอง มี `SKILL.md` (พร้อม YAML frontmatter — `name` และ `description`) และไฟล์ reference ที่แนบมา

repo นี้ยังเป็น **Claude Code plugin** ด้วย (`.claude-plugin/` + `hooks/`) — ที่ ship **workflow-enforcement hooks** เพื่อดึง session ให้อยู่บนรางของ T4

## การติดตั้ง

### ด้วย `npx skills` (แนะนำ — ใช้ได้กับทุก agent)

```bash
npx skills add xenodeve/xeno-skills
```

ติดตั้ง skill เฉพาะตัวตามชื่อ:

```bash
npx skills add xenodeve/xeno-skills --skill clink-brainstorm
```

### ด้วย plugin (ได้ workflow-enforcement hooks เพิ่ม)

ติดตั้งเป็น Claude Code plugin เพื่อให้ได้ hook ที่ดึง session ให้อยู่บนราง T4:

```
/plugin marketplace add xenodeve/xeno-skills
/plugin install xeno-skills
```

hook สามตัว — ยิงเฉพาะ repo ที่มี marker `.claude/t4.json` เท่านั้น (repo อื่นไม่ถูกแตะ):

- **`SessionStart`** → inject เนื้อ `using-t4` ครั้งเดียวต่อ session (แก้ปัญหา "ไม่เรียก skill ตั้งแต่ต้น")
- **`UserPromptSubmit`** → เตือน rails สั้นๆ ทุก turn (ลด drift กลางทาง)
- **`PreToolUse`** → **บล็อก/ถาม** ก่อนคำสั่งเสี่ยง: `gh pr create` ที่ไม่มี issue อ้างอิง, git อันตราย (`reset --hard`, force-push, `clean -f`, `branch -D` — โดย `reset --hard`/`clean` อนุญาตใต้ `"afk"` เพื่อ revert-to-green), และ **ship gate** — รันคำสั่ง verify ของ repo (`.claude/t4.json` `"verify"`) **เอง** ก่อน `gh pr merge` แล้ว deny ถ้าไม่ผ่าน (verify ควรเป็นชุด**เร็ว** unit+build+lint; e2e ปล่อยให้ CI); `gh pr merge` ยัง `ask` ให้ยืนยัน `/scrutinize` + `/code-review` — **ข้ามได้เมื่อตั้ง `"autoMerge"`/`"afk"`** ตอน AFK; ถ้าตั้ง `"requireGreenCI": true` จะรัน `gh pr checks` ด้วยแล้ว deny ตราบใดที่ยังมี check แดงหรือค้างอยู่

hook พวกนี้เป็นของ Claude Code จึงเห็นเฉพาะคำสั่งที่ **Claude** รัน — repo ที่รัน Codex/Gemini ด้วย (หรือคน) จะหลุดไป จึงมีชั้น **git `pre-push` guard** เสริม (ตรวจ issue ref จาก branch/commit/PR body + บล็อก dirty tree เกินงบและ build artifact) ที่ผูกทุก agent บน clone นั้น — ดู [`guards-layer.md`](./skills/t4/t4-project-bootstrap/references/guards-layer.md)

hook แบบ inject = "เตือน" (model ยังเลือกไม่ทำตามได้) ที่ "บังคับ" ได้จริงคือ `PreToolUse` deny + **verify ที่ hook รันเอง** (ปลอมไม่ได้เพราะ hook รันเทสต์เอง ไม่เชื่อคำอ้าง) การันตีสูงสุด "ห้าม merge ถ้าไม่เขียว" อยู่ที่ **CI required-check + branch ruleset**: `t4-project-bootstrap` ให้ทั้ง workflow (`lint` · `typecheck` · `test` · `build` แยกเป็น required check คนละตัว, ชุด e2e แยกต่างหาก และ CD ที่ gate ด้วย verify เขียว) และคำสั่งตั้ง ruleset ที่ทำให้เป็น required + ห้าม push ตรงเข้า `main` — ดู [`ci-cd-layer.md`](./skills/t4/t4-project-bootstrap/references/ci-cd-layer.md) — repo นี้เองก็รัน gate แบบเดียวกัน ([`.github/workflows/t4-verify.yml`](./.github/workflows/t4-verify.yml): `tests` = ชุดเทสต์ contract ทั้งหมด, `skill-discovery` = ยิง installer จริงเพื่อยืนยันว่าทุก `SKILL.md` ถูกค้นพบ) · **สถานะ 2026-08-09:** ruleset `T4 main gate` ติดตั้งแล้ว (`deletion` + `non_fast_forward` + `pull_request` — ห้าม push ตรงเข้า `main`, merge ผ่าน squash เท่านั้น) แต่ **ยังไม่ได้เพิ่ม `tests`/`skill-discovery` เป็น required check** เพราะ CI โดน lock ด้วยปัญหา billing ของ account (ทุก run ล้มที่ provisioning — annotation: *"account is locked due to a billing issue"*) — ต้องแก้ billing, ให้ CI เขียว, แล้วเพิ่มสอง check นั้นใน ruleset ก่อนปิด #109 · การเขียนเป็นอย่างอื่นคือภาพของการบังคับใช้ที่ส่วนนี้เตือนไว้เองพอดี ชั้นนี้คุมการ merge บนเว็บของคนได้ด้วย — local hook คุมได้แค่คำสั่งที่ agent รัน ส่วน repo ที่ผ่าน bootstrap พก hook ชุดเดียวกันไปเองผ่าน git (ไม่ต้องมี plugin)

> **เหตุผลการออกแบบทั้งหมด** (ปัญหา 2 อย่างที่แก้, enforcement ladder, เพดานความจริงว่าอะไรบังคับได้/อะไรเป็น theater) อยู่ใน [`docs/adr/0001`](./docs/adr/0001-hook-based-workflow-enforcement.md) · ภาพรวม workflow ระดับรายงาน (pipeline + enforcement ladder) อยู่ใน [`docs/development-workflow.md`](./docs/development-workflow.md)

## รายการอ้างอิง

### เริ่มที่นี่

- **[ask-xeno](./skills/ask-xeno/SKILL.md)** — router ที่ครอบ **ทุก** skill ในคลังนี้: งานที่ทำอยู่ควรใช้ตัวไหน หนึ่งบรรทัดต่อหนึ่งตัว มันทำดัชนีแล้วส่งต่อ ตัว skill เองเป็นคนแบกกฎ และมันไม่เขียนกฎซ้ำเลย เขียนขึ้นเพราะเก้าจากสิบเจ็ด skill ที่นี่ — ทั้งตระกูล `clink-*` และตระกูล design ทั้งหมด — เข้าไม่ถึงจาก `using-t4` agent ที่ไม่รู้อยู่ก่อนว่ามีจึงไม่มีอะไรบอกมันเลย มี contract test ที่จะแดงในวันที่มีคนเพิ่ม skill แล้วไม่เพิ่มในดัชนี

### Multi-agent

- **[clink-brainstorm](./skills/multi-agent/clink-brainstorm/SKILL.md)** — กระจายคำถามออกไปยัง CLI agent อิสระหลายตัว (Gemini/Antigravity, Codex, Claude ฯลฯ) ผ่าน tool `clink` ของ [PAL](https://github.com/BeehiveInnovations/pal-mcp-server) แล้วสังเคราะห์เป็นข้อเสนอแนะเดียว แต่ละ agent มี cognitive lens ที่ต่างกัน (Code-centric, System-centric, Logic-centric, Conceptual-centric) ซึ่งกำหนดวิธีปรับ prompt สำหรับการ challenge มี judge-led challenge loop สำหรับตอนที่ agent เห็นไม่ตรงกัน และ adversarial round แบบเจาะ lens สำหรับตอนที่ทุกตัวเห็นตรงกัน (การเห็นตรงกันโดยไม่ถูกกดดัน ≠ การยืนยันว่าถูก) **ต้องมี PAL MCP server** เชื่อมต่อกับ agent ของคุณ พร้อม `clink` CLI agent อย่างน้อยสองตัว

- **[clink-subagents](./skills/multi-agent/clink-subagents/SKILL.md)** — มอบหมาย **งานที่มีขอบเขตชัด** (เขียน implementation, refactor, แปลงชุดใหญ่, research เฉพาะจุด, ร่างแรก) ให้ Codex (GPT-5.6) หรือ Antigravity (Gemini) ทำเป็น subagent ผ่าน tool `clink` ของ [PAL](https://github.com/BeehiveInnovations/pal-mcp-server) — เพื่อ offload งาน, รันขนานกัน หรือประหยัด context ต่างจาก `clink-brainstorm` (ที่ขอ *ความเห็น*) ตรงที่อันนี้ *สั่งให้ทำงานจริงแล้วเอาผลกลับมา* มาพร้อม routing rubric อิงดัชนี [Artificial Analysis](https://artificialanalysis.ai/models) (Codex = โมเดล coding เทพแต่ harness อ่อน → งานยาก self-contained + ต้อง verify; Antigravity = agentic อ่อน → เฉพาะงาน single-shot ง่าย ๆ; คุณ = orchestrate + verify) และกฎเหล็ก **verify ทุกอย่างที่ subagent คืนมา** **ต้องมี PAL MCP server** พร้อม `clink` agent `codex`/`antigravity`

### ทีม T4 (มาตรฐานการทำงานแบบ agent-primary)

ตระกูลของ skill ที่กลั่นออกมาแบบไม่ผูกกับโปรเจกต์เดียว จาก repo ที่โตเต็มที่ของทีม T4 (MangaDock, T4-Fastwork) สำหรับ repo ที่ **coding agent เป็น developer หลัก** ออกแบบมาแบบ retrieval-first เพื่อให้ agent คง context ข้าม session และการ compaction ได้ แต่ละตัวค้นเจอได้เองด้วย trigger ของตัวเอง; `using-t4` เป็น entry map, `t4-project-bootstrap` เป็นตัวติดตั้งไฟล์ ส่วนตัวที่เหลือดูแล discipline ที่ทำต่อเนื่อง

- **[using-t4](./skills/t4/using-t4/SKILL.md)** — entry-point map ของทั้งตระกูล (คล้าย `using-superpowers`) ตอนเริ่ม task ใดๆ ใน T4 repo มันจะ route คุณไปยัง skill ที่ถูกต้อง — memory ตอนเริ่ม session, การ setup repo, pipeline ของ feature หรือ engineering record — และแบก non-negotiable rules ของทีมไว้ `CLAUDE.md` ของ repo จะชี้ agent ที่เพิ่งเข้ามาให้มาที่นี่ก่อน
- **[t4-project-bootstrap](./skills/t4/t4-project-bootstrap/SKILL.md)** — scaffold repo T4 ใหม่ (หรือที่ยังมีเอกสารไม่ครบ) ด้วย operating layer ในรอบเดียว: เอกสาร domain/product (`CONTEXT.md`, `UBIQUITOUS_LANGUAGE.md`, `PRODUCT.md`, `DESIGN.md`, `docs/agents/domain.md`), knowledge dir ที่ index ตามสถานะ และการ wiring `CLAUDE.md` — โดย orchestrate สาม skill พี่น้องด้านล่าง แบ่งเป็น tier ตามภาระ context ของ agent (memory layer เปิดเป็น default) พร้อมชุด deliverable ของ Software-Engineering แบบ 7 เฟสให้เลือกเสริม
- **[t4-agent-memory](./skills/t4/t4-agent-memory/SKILL.md)** — working memory ถาวรที่ repo แบบ agent-primary ใช้ขับเคลื่อน: team memory vault (`Home.md` Map-of-Content → note ที่ link กัน), open-work ledger, ship log, survey-provenance cache และ Serena code memories — พร้อม protocol การอ่านตอนเริ่ม session และกฎ retrieval-first (index-then-open, single-source, จำกัดขนาด log, ความสดใหม่เหนือ authority)
- **[t4-engineering-records](./skills/t4/t4-engineering-records/SKILL.md)** — เลือกว่าจะเขียน record แบบไหนเมื่อมีอะไรสำคัญเกิดขึ้น (post-mortem vs ADR vs system-impact entry vs bug-case-catalog) และเขียนอย่างไรให้ยังเป็น index ที่เชื่อถือได้ (`file:line`, commit SHA, เฉพาะที่ validated แล้ว, blameless) มีเทมเพลตให้
- **[t4-dev-workflow](./skills/t4/t4-dev-workflow/SKILL.md)** — pipeline ของ feature (grill→survey→PRD→issues→TDD), gate แบบ PRD→issues→PR, map ของ skill ที่ trigger อัตโนมัติ, triage label, issue lifecycle และกฎ tracker แบบ bilingual (ไทยสะท้อนอังกฤษ) มีเทมเพลต `docs/agents/*` + PRD/spec/plan ให้
- **[t4-afk](./skills/t4/t4-afk/SKILL.md)** — ชั้น discipline สำหรับรัน autonomous batch แบบไม่มีคนเฝ้า: preflight scope-lock (AFK รันได้เฉพาะ worklist ที่อนุมัติไว้ก่อน), เส้นแบ่ง "ตัดสินเองได้ vs ต้อง park", ลูปต่อชิ้นงานที่ปลอดภัย (convention→TDD→gate→checkpoint), เงื่อนไข stop-and-park ที่กัน tree ไม่ให้พัง และวิธีปิดจบ batch ด้วย digest เดียวพร้อม reconcile ทุก issue มีเทมเพลต preflight / park-note / landing-digest ให้ มันไม่ผ่อนกฎ T4 ข้อไหน — มันแค่เอา human checkpoint ออก ดังนั้น gate ต่างๆ ต้องยืนด้วยตัวเอง
- **[t4-bro](./skills/t4/t4-bro/SKILL.md)** — ระดับภาษาของทุกอย่างที่ dev ต้องอ่าน: ภาษาไทยธรรมดาระดับ dev ทำงานจริง พร้อมบททดสอบความจำเป็นสามทางที่คำอังกฤษต้องผ่านจึงจะได้อยู่ต่อ (เป็น identifier · dev ใช้คำนี้อยู่แล้ว · ตัดแล้วเสียความแม่นยำ) และกฎหลักฐานสำหรับกรณีตรงกลาง — คำหนึ่งนับว่าเป็นคำที่ใช้จริงเมื่อ dev เขียนคำนั้นเอง มีเพดานความถูกต้องกำกับ (ทำให้ง่ายห้ามทำให้ข้อความกลายเป็นเท็จ, คำที่กันไว้ไม่ใช่ศัพท์เทคนิค), คู่ตัวอย่างก่อน/หลังจาก session จริง และระบุขอบเขตที่ไม่ครอบคลุมไว้ชัด เพื่อให้ identifier, commit message และกฎ tracker แบบ bilingual ยังเป็นไปตามที่ `t4-dev-workflow` กำหนดทุกประการ

### Coding behavior

- **[karpathy-guidelines](./skills/karpathy-guidelines/SKILL.md)** — guardrails เชิงพฤติกรรมที่ลดข้อผิดพลาดที่ LLM มักทำตอนเขียนโค้ด (คิดก่อนเขียน, ทำให้ง่ายที่สุด, แก้แบบ surgical, ตั้งเกณฑ์ success ที่ตรวจสอบได้) กลั่นจาก[ข้อสังเกตของ Andrej Karpathy](https://x.com/karpathy/status/2015883857489522876) `using-t4` โหลดตัวนี้อัตโนมัติครั้งเดียวตอนเริ่ม session ใน T4 repo — จึงใช้ควบคู่กับตระกูล T4 ได้ทันที (MIT, ให้เครดิต Karpathy)

### Design (เว็บ/UI)

ตระกูล skill ด้านการออกแบบเว็บ กลั่นจากคลังวิดีโอของ Chase AI, Flux Academy (Ran Segall), Chris McCoy, Kole Jain และ Satori Graphics โดย `design` เป็นตัวประสานที่ route ไปยังอีกสี่ตัว (transcript ต้นทางอยู่ใน `skills/design/references/` — เครดิตเป็นของผู้สร้างวิดีโอแต่ละราย)

- **[design](./skills/design/design/SKILL.md)** — ตัวประสานของตระกูล route งานออกแบบไปยัง skill ที่ถูกต้อง
- **[design-setup](./skills/design/design-setup/SKILL.md)** — กรอบการ setup + prototype เว็บแบบ 0→1 ครบวงจร: preflight check, decision gate, การแยกโค้ดทดลอง, prompt 4 ส่วน, ลำดับ build 3 เฟส และการปิดท้ายด้วยการ commit token
- **[design-rules](./skills/design/design-rules/SKILL.md)** — กฎ micro-UI ระดับ CSS/Tailwind: typography (tracking -2%, สเกล Major Third 1.25x, line-height 150%), สมดุลสี 60-30-10, กริด 12/8/4 คอลัมน์, จังหวะ spacing 8pt, ปุ่ม 4 สถานะ และระบบ LIFT กับ 6 ระดับของ visual flow
- **[design-audit](./skills/design/design-audit/SKILL.md)** — กรอบการรีวิว UI/portfolio ด้วย 30-Second First Impression Test และระบบ LIFT: ความชัดในทันที, visual hierarchy, trust signal, ความพร้อมด้าน conversion
- **[design-psychology](./skills/design/design-psychology/SKILL.md)** — จิตวิทยา UX/conversion: 3-Brain Persona (Survival/Emotional/Rational), mental model ของ layout, การหักแพตเทิร์นแบบ MAYA, cognitive chunking (กฎ 3-4 ชิ้นของ working memory) และ Luxury White Space

## ที่เกี่ยวข้อง

**Companion skill ecosystems** — ตระกูล `t4-*` เป็นชั้นบางๆ เฉพาะทีมที่วางทับสิ่งเหล่านี้; `using-t4` route ไปหาพวกมัน และตั้งใจให้ติดตั้งควบคู่กัน:

- **[superpowers](https://github.com/obra/superpowers)** — process discipline ทั่วไป (brainstorming, TDD, systematic-debugging, writing-plans/skills, verification-before-completion) entry map ของมันเองคือ `superpowers:using-superpowers`; T4 ยกเรื่อง *วิธีการทำงาน* ให้มัน
- **[mattpocock/skills](https://github.com/mattpocock/skills)** — "Skills for Real Engineers" flow ที่ pipeline ของ T4 สร้างขึ้นมาจาก: loop grill→spec→tickets บวกกับ convention ของ issue-tracker / triage-label / domain-doc ที่ T4 นำมาใช้ซ้ำ ติดตั้ง/ตั้งค่าผ่าน `/setup-matt-pocock-skills`
- **[thananon/9arm-skills](https://github.com/thananon/9arm-skills)** — `debug-mantra`, `post-mortem`, `scrutinize`, `qwen-agent` (delegate ไปยัง subagent ราคาถูกที่ขับด้วย Qwen ผ่าน `claude-9arm`), `qwenchance`, `management-talk`

**เครื่องมือ:**

- **[xenodeve/pal-mcp-server](https://github.com/xenodeve/pal-mcp-server)** — fork ของ PAL ที่เพิ่ม clink agent `antigravity` (ตัวสืบทอดของ Gemini จาก Google, `agy`, ผ่าน ConPTY บน Windows) และเทมเพลต `claude-9arm.json.example` สำหรับชี้ `claude` ไปยัง model gateway อื่น เป็นสิ่งที่ต้องมีก่อนจะใช้ `clink-brainstorm` / `clink-subagents` กับ Antigravity หรือ gateway ที่กำหนดเอง

## License

MIT — ดู [LICENSE](LICENSE)
