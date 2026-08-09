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

## Conventions

- **Create**: `gh issue create --title "..." --body "..."` (heredoc for multi-line bodies).
- **Read**: `gh issue view <n> --comments`.
- **List**: `gh issue list --state open --json number,title,body,labels,comments --jq '...'`.
- **Comment**: `gh issue comment <n> --body "..."`.
- **Label**: `gh issue edit <n> --add-label "..."` / `--remove-label "..."`.
- **Close (with REASON)**: `gh issue close <n> --comment "<reason + evidence>"`.

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

## ธรรมเนียม

- **สร้าง**: `gh issue create --title "..." --body "..."` (heredoc สำหรับ body หลายบรรทัด)
- **อ่าน**: `gh issue view <n> --comments`
- **ลิสต์**: `gh issue list --state open --json number,title,body,labels,comments --jq '...'`
- **คอมเมนต์**: `gh issue comment <n> --body "..."`
- **Label**: `gh issue edit <n> --add-label "..."` / `--remove-label "..."`
- **ปิด (พร้อมเหตุผล)**: `gh issue close <n> --comment "<เหตุผล + หลักฐาน>"`

อนุมาน repo จาก `git remote -v` — `gh` ทำอัตโนมัติเมื่อรันใน clone

## แผนที่ศัพท์ของ skill

- "publish to the issue tracker" → สร้าง GitHub issue
- "fetch the relevant ticket" → `gh issue view <n> --comments`

<!-- lang:end -->
