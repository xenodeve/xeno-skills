# Hooks layer — keep the session on the T4 rails

Agents fail two ways in a T4 repo: they **don't invoke the skill** at all, and they **drift off the workflow** mid-task. This layer installs lifecycle hooks that fight both. It is the **universal (path A)** delivery — the hooks are committed into the repo's own `.claude/`, so they travel with the repo via git and fire for anyone who opens it, even without the `xeno-skills` plugin installed.

> The **native (path B)** delivery is the `xeno-skills` plugin, which ships the same hooks under `${CLAUDE_PLUGIN_ROOT}/hooks/` and registers them on install. A and B share a per-`session_id` lock (`$TMPDIR/t4-hooks/<id>.session-start`) so a machine that has both never injects twice.

## What the hooks do (and honestly can't)

| Hook | Event | Effect | Strength |
|---|---|---|---|
| `t4-session-start` | `SessionStart` (`startup\|clear\|compact`) | Injects the `using-t4` map content, once per session | **Solves** "didn't invoke at start" |
| `t4-prompt-reminder` | `UserPromptSubmit` | Injects a short rails reminder every turn | **Reduces** mid-session drift (soft) |
| `t4-gate` | `PreToolUse` (`Bash`) | **Blocks** `gh pr create` with no referenced issue; blocks dangerous git (`reset --hard`, force-push, `clean -f`, `branch -D`) | **Enforces** the discrete, checkable rules (hard) |

Hooks that *inject context* are reminders — the model can still ignore them. Only the `PreToolUse` **deny** is a hard wall, and only for conditions a script can check. Fuzzy discipline (TDD order, bilingual quality) stays a soft nudge. Do not oversell this to the user.

## Files this installs into the target repo

All committed (not `.local`), so they ship with the repo:

```
<repo>/.claude/
├── settings.json                     # registers the three hooks (see references/hooks/settings.json)
├── t4.json                           # the marker every hook guards on (references/hooks/t4.json)
└── hooks/
    ├── run-hook.cmd                  # cross-platform launcher (references/hooks/run-hook.cmd)
    ├── t4-session-start
    ├── t4-prompt-reminder
    ├── t4-gate
    └── using-t4.snapshot.md          # a copy of the current using-t4 SKILL.md (see below)
```

The four scripts are the canonical hook scripts, kept byte-identical to the plugin's `hooks/` copies (a repo test enforces the sync). Copy them verbatim from `references/hooks/`.

## Install steps

1. Copy `references/hooks/{run-hook.cmd, t4-session-start, t4-prompt-reminder, t4-gate}` → `<repo>/.claude/hooks/` and mark the scripts executable (`chmod +x`).
2. Copy `references/hooks/t4.json` → `<repo>/.claude/t4.json` (the guard marker).
3. Merge `references/hooks/settings.json` into `<repo>/.claude/settings.json`. If the repo already has a `settings.json`, **merge the `hooks` keys** — don't clobber existing permissions/env. The commands use `${CLAUDE_PROJECT_DIR}` so they resolve without the plugin.
4. Write `<repo>/.claude/hooks/using-t4.snapshot.md` = the **current** `using-t4` SKILL.md body. Without the plugin, `t4-session-start` has no `${CLAUDE_PLUGIN_ROOT}` to read from, so it falls back to this snapshot for full-content injection (else it injects only a short "invoke using-t4" directive). Refresh the snapshot when `using-t4` changes.
5. Tell the user the hooks are in and what the `t4-gate` will block, so a denied `gh pr create` / `git reset --hard` isn't a surprise.

## Notes

- **Marker-guarded:** every hook exits silently unless `<cwd>/.claude/t4.json` exists, so a copy leaking into a non-T4 checkout does nothing.
- **Fail-safe:** no bash on the machine → `run-hook.cmd` exits 0 and the hooks become no-ops (a missing reminder, never a broken session).
- **The gate never auto-approves** — silence means "no opinion, normal permission flow"; it only ever adds a `deny` or an `ask`.

## Ship gate: verify + CI — the layer that actually holds

Injected reminders are soft and PreToolUse denies only cover *agent-run* commands. The genuinely un-bypassable enforcement is verification the machine runs itself:

1. **Local ship gate (opt-in).** Set `.claude/t4.json` `"verify"` to the repo's test command (e.g. `"bun test"`). `t4-gate` then **runs it itself** before any `gh pr create` / `gh pr merge` and blocks on failure — real, un-forgeable, because the hook runs the tests rather than trusting a claim. Empty = off. `gh pr merge` also `ask`s the human to confirm `/scrutinize` + `/code-review` ran.
2. **Server-side gate (the real guarantee).** Install `references/ci/t4-verify.yml` as `.github/workflows/t4-verify.yml` and make it a **required status check** on `main`, with **direct pushes to `main` disallowed**. This is the only layer that also catches a human merging on the web and that `--no-hooks` can't skip. Keep its command in sync with `.claude/t4.json` `"verify"`.

Honest scope: the local gate raises the floor for agent-run merges; the CI required-check is what makes "no merge without a green verify" actually true.
