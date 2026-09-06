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

You are running inside Claude Code. It gives you tools; each one has a job, and using the wrong one costs a turn. The table is the whole rule: find your want in the left column, use the tool in the second, and check the pass condition before moving on. Calibrated on the 44 Claude Code streams of 2026-09-05 (`Qwen-3.8-27B-Tuning/qwen38-tuning/results/quality-2026-09-05/`): 14 tool errors in 9 of them, and all 14 fall under a row below. Only 12 of the 31 tools were touched at all — read that as tools nobody explained, not as tools that were wrong for the work. Pair 2026-09-06 (A-ccguide-r1 vs A-both ×3): the guessed-path Reads went 2 → 0 and every skill was loaded by name; the heredoc script and the `cd` prefix did not move — hence their own rows.

## The tools, by what you want

| you want | use | not | pass condition |
|---|---|---|---|
| a file by name or pattern | **Glob** `**/*.py` | Bash `find` / `ls -R` (27 `ls` + 4 `find` calls vs 5 Glob in the runs) | the path comes back from the tool; you never type a path you have not seen |
| text inside files | **Grep** `pattern`, `path`, `glob` | Bash `grep -rn` | a `file:line` list |
| to read a file | **Read** with an absolute path; `offset`/`limit` for a long one | Bash `cat` / `sed -n` | you can quote the exact line you will change |
| to change an existing file | **Edit**: `old_string` is a line you **Read in this session**, pasted byte-exact and unique; for Thai text paste the whole line, tone marks included | typing the line from memory (`String to replace not found` ×2 on one Thai line, A-gateonly-r2) | the tool returns without an error; **the same target failing twice → re-Read the line, then Edit again with a longer unique anchor** — never a third try from memory |
| a new file | **Write** (whole content; it overwrites) | Bash `echo >` / heredocs | the file exists and Read shows it |
| a script to run (a Playwright check, a node one-liner grown long) | **Write** it to a file, then Bash `node <absolute path>` | a `cat <<'EOF'` heredoc in Bash — the shell eats backslashes: `replace(/\/g,'/')` arrived as `replace(/\/g,'/')` and died with `missing )` in A-both-r3 **and again in A-ccguide-r1 with this guide loaded** | the script runs from a path you can Read back |
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

## Every tool Claude Code gives you, and the verdict on each

Claude Code sends **31 tools and 87,799 characters of their JSON schema** with every request — against 6,186 characters for the whole system prompt (`harness-tools.txt`, recorded from a real request on 2026-09-06). You are not short of descriptions. What follows is the part a schema cannot give you: **which to reach for, which to leave, and why.**

**A tool you did not use in a past run is not a tool that was wrong for the job.** Across the 44 bench streams only 12 of the 31 were touched at all, and the likeliest reason is the plain one: the schema said what the tool accepts, nothing said what it is *for*, so it was safer to ignore. That is the gap this table closes. Where a row says **use**, using it is the better move, not a permission.

Rows marked **measured here** name a 2026-09-05 or 2026-09-06 bench cell. The rest are **harness facts** — what the tool is, and whether this machine can run it — and carry no figure because none has been taken.

### Files and search

| tool | what it is | verdict |
|---|---|---|
| `Read` | a file from disk; `offset`/`limit` for a long one, and it renders images and PDF pages | **use** — the only way you should see a file's content (measured here: 148 calls) |
| `Write` | writes a whole file, overwriting what is there | **use** for a new file, and for a script you are about to run |
| `Edit` | exact string replacement; `replace_all` for every occurrence | **use** for every change to a file that exists (measured here: 108 calls, 3 failed on a string typed from memory) |
| `Glob` | file names by pattern, newest first | **use** whenever you do not know a path — it is faster than `ls` and cannot mistype (measured here: 5 calls against 27 `ls` through Bash) |
| `Grep` | ripgrep over content: `output_mode`, `-A`/`-B`/`-C`, `type`, `glob`, `multiline` | **use** for anything inside files; its own description says prefer it over `grep` in Bash (measured here: 3 calls — far below what the work needed) |
| `NotebookEdit` | replaces, inserts or deletes one cell of a `.ipynb` | **use for any notebook** — a notebook is JSON, so `Edit` on one corrupts it |

### Running things

| tool | what it is | verdict |
|---|---|---|
| `Bash` | one bash command (Git Bash here); `timeout` up to 10 min, and `run_in_background` | **use** for commands and tests. Absolute paths, no `cd` prefix — the directory persists (measured here: 87 of 195 calls carried a `cd` that did nothing). **A suite or build that runs for minutes goes in `run_in_background`**: you keep working and a notification brings you the output file |
| `PowerShell` | PowerShell 7, same persistent directory | **use for what only Windows has** — services, the registry (`HKLM:\…`), `Get-CimInstance`, `Start-Process`. Not for file work; the dedicated tools are better (used twice in the runs with no rule written until #358) |

### Keeping track of your own work

| tool | what it is | verdict |
|---|---|---|
| `TaskCreate` | opens a tracked task with a subject and description | **use** when the brief has more than about three steps (measured here: 9 calls) |
| `TaskUpdate` | changes one task's status, owner, or what blocks it | **use** as each step finishes (measured here: 16 calls) |
| `TaskList` | every task in this session | **use before the report** — it is how you catch a step you left open (used once in the runs, with no rule until #358) |
| `TaskGet` | one task by id | **use** when you need a task you did not just write |
| `TaskStop` | stops a background task by id | **use** to stop something you started and no longer need |
| `TaskOutput` | **deprecated by its own description** | **do not** — a background task hands you an output file path; `Read` that file |
| `Monitor` | streams a long-running script's stdout into the chat as events | **use** when a run must keep going while you work — a server boot, a long suite. It is the tool for "start it and watch"; no bench run used it, which is a gap in the runs, not a verdict on the tool |

### Skills

| tool | what it is | verdict |
|---|---|---|
| `Skill` | loads a skill **by its name**, plus optional `args` | **use** — the only correct way to reach a skill (measured here: 6 of the 14 tool errors were a `Read` on a guessed `…/SKILL.md` path; with this guide loaded, A-ccguide-r1 made 6 `Skill` calls and no guessed `Read`) |

### Other agents and other sessions

| tool | what it is | verdict |
|---|---|---|
| `Agent` | launches a subagent with its own context | **do not** — `using-qwen38` rule 3: it returns work you did not watch, and you are the one who has to verify it |
| `ListAgents` | lists sessions and teammates you could message | **do not** — an unattended run has nobody to address |
| `SendMessage` | messages one of those | **do not** — same reason |
| `Workflow` | runs a script that orchestrates many subagents | **do not** — its own description requires the developer's explicit opt-in, and it can spawn dozens |

### The web

| tool | what it is | verdict |
|---|---|---|
| `WebFetch` | fetches one URL and answers a question against it with a small model | **use when the brief names a URL or needs a fact you cannot read from the repo** — never to hunt for a missing tool |
| `WebSearch` | searches the web (US-only results) | **use for an outside fact the brief needs** — never to find a command that is not installed (measured here: A-skill-r1 lost two turns hunting for `gh`, which is simply absent) |

### Time and the developer's attention

| tool | what it is | verdict |
|---|---|---|
| `CronCreate` | schedules a prompt for a later time | **do not** — your run ends at the report; nothing you schedule will be watched |
| `CronDelete` | cancels one | **do not** — nothing to cancel |
| `CronList` | lists them | **do not** — same |
| `ScheduleWakeup` | paces iterations in `/loop` mode | **do not** — that mode is entered by the developer, not by you |
| `PushNotification` | rings the developer's terminal, and their phone if connected | **do not** — it pulls them out of whatever they are doing; the report is your channel |

### Git worktrees

| tool | what it is | verdict |
|---|---|---|
| `EnterWorktree` | moves the session into an isolated git worktree | **use only when the brief or `CLAUDE.md` says worktree** — its own description says exactly that |
| `ExitWorktree` | returns from one | **use** only if you entered one |

### Special-purpose

| tool | what it is | verdict |
|---|---|---|
| `DesignSync` | reads and writes the user's claude.ai design projects | **not available here** — it needs a claude.ai login this server does not have |
| `ReportFindings` | returns code-review findings as a typed list the UI renders | **use when the review instructions in front of you say to** — otherwise write the findings in the report |

**If a tool appears that is not in this file**, Claude Code has changed: use it from its own schema, and say in one line at the end of the report that it was not covered here.

## When a tool comes back with an error

Every error is a result to read, not a wall to push against. Find the first line of the error in the left column and do the right column **once**; the same call a second time, unchanged, is the failure this table exists for.

| the error says | what it means | do next |
|---|---|---|
| `Permission … denied`, `denied by the … auto mode classifier`, `blocked by`, a hook's `deny` | the harness, not you, refused that action — a policy, not a bug | **do not retry it and do not route around it** (no other tool, no subagent, no script that does the same thing). Say in one line what was refused, take the nearest allowed path if one exists (a refused `Agent` → do the work yourself; a refused write outside the work dir → write inside it), else report the gap |
| `File does not exist` | you typed a path you had not seen | Glob for it; never guess a second path |
| `String to replace not found` / `No changes to make` | your `old_string` is not what the file holds | re-Read the line, Edit with a longer unique anchor (row above) |
| Bash `Exit code` ≠ 0 with a traceback or `command not found` | the command failed, or the tool is not there | `command not found` → the missing-tool line, continue. A traceback → the three lines of `qwen38-think` §3 (Observed / Hypothesis / Falsify), then one changed attempt |
| a failing test in your own test run | a result, not an error — this is what RED looks like | read the assertion; fix the code, not the test (`qwen38-code-gate`) |
| `timed out` | the command runs longer than the tool allows | run a smaller piece (one test file, one directory); never the same long command again |
| `API Error`, `500`, `overloaded`, the stream stops | the model server, not your work | wait, retry the **same** step once; if it fails again, end with the report of what is done and `stopped: server error` |

Every error, whatever you did next, counts in the `CC:` line below.

## Report

Add this line after the `THINK:` line and the gate line (`stopped: …` only when a server error ended the run):

```
CC: tool calls <n> · tool errors <e> · asked the developer: no
```

`<e>` is the number of tool results that came back as errors in this run; a run that names 0 while an error is visible in the transcript fails this skill. If you asked a question at any point, the line says `asked the developer: yes` — do not hide it.

## What this does not touch

What to build and when it is done — the task's own skill and gate. Which task loads which skill — `using-qwen38`. This file only stops the turns lost to the wrong tool.
