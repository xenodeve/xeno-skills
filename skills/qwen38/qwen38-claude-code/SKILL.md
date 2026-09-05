---
name: qwen38-claude-code
description: "How to drive Claude Code as Qwen3.8-27B: which tool for which want (Glob/Grep/Read/Edit/Write/Bash/Skill), the three mistakes the 2026-09-05 runs made with them (guessed skill paths, Edits pasted from memory, a question to a developer who is not there), how a session works (CLAUDE.md, compaction, the last message is the report), and the CC report line. Slice of xeno-skills #355."
target-model: Qwen3.8-27B
triggers:
  - /qwen38-claude-code
  - claude code มี tool อะไรบ้าง
  - ใช้ tool ไหน
  - which tool
---

# Driving Claude Code (`qwen38-claude-code`)

You are running inside Claude Code. It gives you tools; each one has a job, and using the wrong one costs a turn. The table is the whole rule: find your want in the left column, use the tool in the second, and check the pass condition before moving on. Calibrated on the 44 Claude Code streams of 2026-09-05 (`Qwen-3.8-27B-Tuning/qwen38-tuning/results/quality-2026-09-05/`): 14 tool errors in 9 of them, and all 14 fall under a row below.

## The tools, by what you want

| you want | use | not | pass condition |
|---|---|---|---|
| a file by name or pattern | **Glob** `**/*.py` | Bash `find` / `ls -R` (27 `ls` + 4 `find` calls vs 5 Glob in the runs) | the path comes back from the tool; you never type a path you have not seen |
| text inside files | **Grep** `pattern`, `path`, `glob` | Bash `grep -rn` | a `file:line` list |
| to read a file | **Read** with an absolute path; `offset`/`limit` for a long one | Bash `cat` / `sed -n` | you can quote the exact line you will change |
| to change an existing file | **Edit**: `old_string` is a line you **Read in this session**, pasted byte-exact and unique; for Thai text paste the whole line, tone marks included | typing the line from memory (`String to replace not found` ×2 on one Thai line, A-gateonly-r2) | the tool returns without an error; **the same target failing twice → re-Read the line, then Edit again with a longer unique anchor** — never a third try from memory |
| a new file | **Write** (whole content; it overwrites) | Bash `echo >` / heredocs | the file exists and Read shows it |
| to run something | **Bash**: absolute paths, one command, no `cd` prefix (the working directory persists; 87 of 195 Bash calls carried a `cd` that did nothing) | `cd X && …` chains | exit code and the output you needed, pasted |
| a skill | **Skill** tool with the skill's **name** | Read on a guessed `…/skills/<name>/SKILL.md` path (6 of the 14 errors: `File does not exist`) | the skill's text is in your context |
| to keep track of steps | **TaskCreate** / **TaskUpdate** | a list in your head | — |
| the developer's answer | **nothing** — there is nobody on the other end in an unattended run. Write `Pushback: …` (`qwen38-think`) and build the part that stands | **AskUserQuestion**, or ending with a question (A-noskill-r2 "อยากให้ปรับอะไรเพิ่มไหมครับ", B-skill-r1 "Which do you want?" — both runs stopped there, unfinished) | the report ends with the report lines, not a question mark |
| more hands | **nothing** — never **Agent** (`using-qwen38` rule 3) | spawning a subagent to search for a tool | — |
| the web | **WebFetch** / **WebSearch** only when the brief names a URL or asks for outside facts | fetching to find a tool or a package | — |

## How a session works

- **`CLAUDE.md` in the repo is part of the brief.** It arrives in your context before the first message; its rules bind you the same as the brief's sentences.
- **Skills load by name, on demand.** The router (`using-qwen38`) names which; the Skill tool loads it. A skill you did not load is not in effect.
- **Context compacts on its own.** A long run is summarised behind your back; anything you need later must be in a file, not in your memory of the conversation. Re-Read before you Edit after a compaction.
- **The last message is the report.** Nothing after it is read. It carries the family's lines (`THINK:` first, the gate line, then `CC:` below) and the pasted outputs.
- **This machine is Windows.** Paths are `C:\…`; the Bash tool is Git Bash and accepts `/c/…` too; `gh`, `npm`, `pip install` and a spellchecker are **not** available to you — one line "`<tool>` is not available; continuing without it", then continue (A-skill-r1 lost two turns to `gh: command not found`).

## Report

Add this line after the `THINK:` line and the gate line:

```
CC: tool calls <n> · tool errors <e> · asked the developer: no
```

`<e>` is the number of tool results that came back as errors in this run; a run that names 0 while an error is visible in the transcript fails this skill. If you asked a question at any point, the line says `asked the developer: yes` — do not hide it.

## What this does not touch

What to build and when it is done — the task's own skill and gate. Which task loads which skill — `using-qwen38`. This file only stops the turns lost to the wrong tool.
