<!-- lang:en -->
# Issue tracker: GitHub

Issues and PRDs for this repo live as GitHub issues on `xenodeve/xeno-skills`. Use the `gh` CLI for all operations.

> **`gh` path/auth:** `gh` on PATH, authenticated as `xenodeve`, owner of the `xenodeve` org.

## Language: bilingual bodies (English + Thai)

Every issue body, PRD body, and PR description must be **bilingual**:

- **Title**: English, conventional-commit style (e.g. `fix(<scope>): ...`).
- **Body**: each section in English, then a mirrored Thai version — a `## สรุปภาษาไทย` section
  covering the whole body, or `EN / TH` paired paragraphs per section for long docs.
- **Thai must mirror English exactly** — same detail, sentence count, bullets, tables. Never
  summarise or omit. "สรุป" does not mean "shorter".
- Code identifiers, filenames, log excerpts, and acceptance-criteria checkboxes stay English;
  the Thai explains them, never translates identifiers.
- Review-reply comments may be English-only; anything a teammate reads to decide gets both languages.

**The mirror is checked when the body is EDITED, not only when it is created.** A PR body is the
one tracker artifact that outlives the turn that wrote it: it is created early as a working index
and extended later, and *"update the PR body"* reads as an edit to existing text — so the rule that
governs authoring a tracker body never re-fires. The English half grows in place and the absent Thai
half is never noticed, because there is nothing there to look wrong. **PR #235's body stayed
English-only across 42 commits and 34 issues** — 9,465 characters, zero Thai — in a repo whose
`CLAUDE.md` was in context the whole time.

**And never reuse a commit message as a PR body.** Commit messages are English *by this repo's rule*;
tracker bodies are bilingual by the same rule. Passing the one file to both `git commit -F` and
`gh pr create --body-file` imports the wrong language rule across a boundary where it changes.
Measured on 2026-08-19: of 25 PR bodies written in one session **9 were bilingual and then 16
consecutive ones were English-only**, and the switch point is exactly where the commit-message file
started being reused as the body. **A clean break like that is a mechanism, not a lapse of
attention.**

## Conventions

- **Create**: `gh issue create --title "..." --body "..."` (heredoc for multi-line bodies).
- **Read**: `gh issue view <n> --comments`.
- **List**: `gh issue list --state open --json number,title,body,labels,comments --jq '...'`.
- **Comment**: `gh issue comment <n> --body "..."`.
- **Label**: `gh issue edit <n> --add-label "..."` / `--remove-label "..."`.
- **Close (with REASON)**: `gh issue close <n> --comment "<reason + evidence>"`.
- **Link a child to its parent** (`gh` has no command; use the API):
  `gh api --method POST repos/{owner}/{repo}/issues/<parent>/sub_issues -F sub_issue_id=<child INTERNAL id>`
  The child's internal id is `gh api repos/{owner}/{repo}/issues/<n> --jq .id` — **not** its number. Undo with `--method DELETE .../issues/<parent>/sub_issue`.
- **Read a tree**: `gh api repos/{owner}/{repo}/issues/<n>/sub_issues` · progress: `gh api .../issues/<n> --jq .sub_issues_summary`.

**The hierarchy is plan → PRD → issues, expressed as sub-issues, never as a `## Parent` heading.** The heading may stay for a human reader; it is not the mechanism. Three caveats that mislead if unknown: the rollup counts **direct children only** (a plan at 0% may have thirty slices done), a child has **exactly one parent**, and **`## Blocked by` stays prose** — a sub-issue is decomposition, not ordering, and GitHub has no dependency edge.

Infer the repo from `git remote -v` — `gh` does this automatically inside a clone.

## Skill phrase mapping

- "publish to the issue tracker" → create a GitHub issue.
- "fetch the relevant ticket" → `gh issue view <n> --comments`.
<!-- lang:end -->

<!-- lang:th -->

# Issue tracker: GitHub

Issue และ PRD ของ repo นี้อยู่เป็น GitHub issues บน `xenodeve/xeno-skills` ใช้ `gh` CLI สำหรับทุกการทำงาน

> **`gh` path/auth:** `gh` อยู่บน PATH, authenticate เป็น `xenodeve`, เจ้าของ org `xenodeve`

## ภาษา: body แบบ bilingual (อังกฤษ + ไทย)

ทุก issue body, PRD body และ PR description ต้องเป็น **bilingual**:

- **Title**: อังกฤษ, แบบ conventional-commit (เช่น `fix(<scope>): ...`)
- **Body**: แต่ละ section เป็นอังกฤษ แล้วตามด้วยไทยที่ mirror — section `## สรุปภาษาไทย`
  ครอบคลุมทั้ง body หรือ EN / TH คู่กันเป็นย่อหน้าสำหรับเอกสารยาว
- **ไทยต้อง mirror อังกฤษเป๊ะ** — รายละเอียดเท่ากัน จำนวนประโยคเท่ากัน bullets เท่ากัน ตารางเท่ากัน
  ห้ามสรุปหรือตัดทิ้ง "สรุป" ไม่ได้แปลว่า "สั้นลง"
- code identifiers, filenames, log excerpts และ acceptance-criteria checkboxes คงเป็นอังกฤษ
  ไทยอธิบายรอบๆ ไม่แปล identifiers
- comment ตอบ review อาจเป็นอังกฤษล้วน; สิ่งที่ teammate อ่านเพื่อตัดสินใจต้องได้สองภาษา

**การ mirror ถูกตรวจตอน EDIT ไม่ใช่แค่ตอนสร้าง** · PR body เป็น artifact เดียวใน tracker ที่อายุยืนกว่า turn
ที่เขียนมัน: มันถูกสร้างแต่เนิ่น ๆ เป็นดัชนีชั่วคราวแล้วต่อเติมทีหลัง และคำว่า *"อัปเดต PR body"* อ่านได้ว่าเป็นการแก้
ข้อความที่มีอยู่ — กฎที่กำกับ *การเขียน* tracker body จึงไม่ยิงซ้ำ · ครึ่งอังกฤษโตขึ้นในที่เดิม ส่วนครึ่งไทยที่ไม่มีอยู่
ก็ไม่มีใครสังเกต เพราะไม่มีอะไรให้ดูผิด · **body ของ PR #235 เป็นอังกฤษล้วนตลอด 42 commit และ 34 issue** —
9,465 อักขระ ไทยศูนย์ — ใน repo ที่ `CLAUDE.md` อยู่ใน context ตลอดเวลา

**และห้ามเอา commit message มาใช้เป็น PR body** · commit message เป็นอังกฤษ *ตามกฎของ repo นี้* ส่วน
tracker body เป็นสองภาษาตามกฎเดียวกัน · การส่งไฟล์เดียวกันให้ทั้ง `git commit -F` และ
`gh pr create --body-file` คือการนำกฎภาษาที่ผิดข้ามเส้นที่กฎมันเปลี่ยน · วัดเมื่อ 2026-08-19: จาก PR body
25 อันที่เขียนใน session เดียว **9 อันเป็นสองภาษา แล้ว 16 อันติดกันเป็นอังกฤษล้วน** และจุดเปลี่ยนคือตรงที่เริ่ม
เอาไฟล์ commit message มาใช้เป็น body พอดี · **การขาดตอนที่คมขนาดนั้นคือกลไก ไม่ใช่ความไม่ใส่ใจ**

## ธรรมเนียม

- **สร้าง**: `gh issue create --title "..." --body "..."` (heredoc สำหรับ body หลายบรรทัด)
- **อ่าน**: `gh issue view <n> --comments`
- **ลิสต์**: `gh issue list --state open --json number,title,body,labels,comments --jq '...'`
- **คอมเมนต์**: `gh issue comment <n> --body "..."`
- **Label**: `gh issue edit <n> --add-label "..."` / `--remove-label "..."`
- **ปิด (พร้อมเหตุผล)**: `gh issue close <n> --comment "<เหตุผล + หลักฐาน>"`
- **ผูกลูกเข้ากับ parent** (`gh` ไม่มีคำสั่งให้ ต้องใช้ API):
  `gh api --method POST repos/{owner}/{repo}/issues/<parent>/sub_issues -F sub_issue_id=<id ภายในของลูก>`
  id ภายในของลูกมาจาก `gh api repos/{owner}/{repo}/issues/<n> --jq .id` — **ไม่ใช่** เลข issue · ถอนด้วย `--method DELETE .../issues/<parent>/sub_issue`
- **อ่านต้นไม้**: `gh api repos/{owner}/{repo}/issues/<n>/sub_issues` · ความคืบหน้า: `gh api .../issues/<n> --jq .sub_issues_summary`

**ลำดับชั้นคือ plan → PRD → issues แสดงด้วย sub-issue ไม่ใช่หัวข้อ `## Parent`** · หัวข้อนั้นคงไว้ให้คนอ่านได้ แต่ไม่ใช่กลไก · ข้อควรระวังสามข้อที่ทำให้เข้าใจผิดถ้าไม่รู้: การรวมยอดนับ **เฉพาะลูกชั้นเดียว** (plan ที่ค้างอยู่ 0% อาจมี slice เสร็จไปสามสิบอัน), ลูกมี **parent ได้ตัวเดียว**, และ **`## Blocked by` ยังเป็นข้อความ** — sub-issue คือการแตกงาน ไม่ใช่ลำดับก่อนหลัง และ GitHub ไม่มีเส้น dependency

อนุมาน repo จาก `git remote -v` — `gh` ทำอัตโนมัติเมื่อรันใน clone

## แผนที่ศัพท์ของ skill

- "publish to the issue tracker" → สร้าง GitHub issue
- "fetch the relevant ticket" → `gh issue view <n> --comments`

<!-- lang:end -->
