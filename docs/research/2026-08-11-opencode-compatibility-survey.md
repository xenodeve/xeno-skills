# OpenCode compatibility — surveyed 2026-08-11

**What this changes.** Two things this repo ships are affected. First, the skills already run in
OpenCode with no changes at all, which was not known. Second, `guards-layer.md` argues that the
checkable rules must move into git *because* `PreToolUse` is a Claude Code event and therefore binds
one agent — OpenCode has its own pre-tool-use hook that can block a call, so that premise is intact
for Codex/Gemini but incomplete as stated.

**Nothing here has been acted on.** This is a survey; the implications are listed at the end and left
open deliberately, because most of them rest on documentation rather than on a running install.

OpenCode is an open-source coding agent by Anomaly (anoma.ly), delivered as a TUI, desktop app and
IDE extension, with its own model marketplace ("Zen") and any-provider BYO-key configuration.

---

## 1. Our skills run there unchanged

OpenCode searches **six** locations for `SKILL.md`, walking up from the working directory to the git
worktree root for the project-scoped ones:

| # | Path | Scope |
|---|---|---|
| 1 | `.opencode/skills/<name>/SKILL.md` | project, native |
| 2 | `~/.config/opencode/skills/<name>/SKILL.md` | global, native |
| 3 | `.claude/skills/<name>/SKILL.md` | project, **Claude-compatible** |
| 4 | `~/.claude/skills/<name>/SKILL.md` | global, **Claude-compatible** |
| 5 | `.agents/skills/<name>/SKILL.md` | project, agent-compatible |
| 6 | `~/.agents/skills/<name>/SKILL.md` | global, agent-compatible |

Paths 3 and 4 are deliberate Claude Code compatibility. **Observed**, not inferred — OpenCode 1.18.15
was run against this machine on 2026-08-11:

```
$ opencode debug skill        # 379 skills loaded in total
  using-t4               <- C:\Users\xenod\.agents\skills\using-t4\SKILL.md
  t4-dev-workflow        <- C:\Users\xenod\.agents\skills\t4-dev-workflow\SKILL.md
  design                 <- C:\Users\xenod\.agents\skills\design\SKILL.md
  design-setup           <- C:\Users\xenod\.agents\skills\design-setup\SKILL.md
  …  all 14 of ours, 14/14
```

So a user who ran `npx skills add xenodeve/xeno-skills` has these skills available in OpenCode
already, without knowing it and without any porting work. That is now an observed load, not a path
match plus a documented contract.

**The mechanism is not the one first assumed.** `npx skills add` writes to **both** `~/.claude/skills/`
and `~/.agents/skills/` — `using-t4/SKILL.md` is 8601 bytes in each, byte-identical — and the skill
OpenCode actually resolved came from `.agents` (search path **6**), not `.claude` (path **4**). The
documentation lists `.claude` before `.agents`; the observed resolution is the other way round, so
either that list is not a precedence order or precedence differs from listing. Not worth guessing at:
the conclusion holds through path 6 regardless, and the Claude-compatible paths matter for a repo that
ships `.claude/skills/` in-tree rather than through the installer.

Skills are loaded on demand through a native `skill` tool — `skill({ name: "using-t4" })` — and the
available skills are surfaced to the model as name/description pairs, the same progressive-disclosure
shape Claude Code uses.

## 2. It enforces the same structural constraints we learned the hard way

- **`name` must match the directory name**, 1–64 chars, pattern `^[a-z0-9]+(-[a-z0-9]+)*$`.
- **`description` required**, 1–1024 chars.
- Unknown frontmatter fields are ignored (so the `triggers:` key in the `design` family is inert
  there, not an error).
- The documented layout is **single-level**: `skills/<name>/SKILL.md`. No nested skill directories.

That last point is the same constraint behind #45, where four `design` sub-skills shipped complete
and undiscoverable because their family directory was itself a skill. `tests/skills/test-skill-manifest.sh`
already guards both the name/directory rule and the nesting rule, so the guard written for the Claude
installer happens to also encode OpenCode's contract.

## 3. `CLAUDE.md` is a documented fallback, not an accident

Rules resolution order: local `AGENTS.md` → local `CLAUDE.md` → `~/.config/opencode/AGENTS.md` →
`~/.claude/CLAUDE.md` (unless disabled), first match per category. `opencode.json` can additionally
list `instructions` as paths, globs, or remote URLs (5-second fetch timeout).

The bootstrap layer's `CLAUDE.md` is therefore read as-is. It also means the `CLAUDE.md`/`AGENTS.md`
parity that MangaDock maintains by hand — two 313-line mirrors — has a concrete consumer rather than
being redundancy for its own sake.

## 4. It has a real pre-tool-use hook — the premise in `guards-layer.md` needs qualifying

Plugins are JS/TS modules in `.opencode/plugins/` (or global, or npm packages named in
`opencode.json`, installed with Bun at startup). They export functions returning a hooks object.
**Throwing inside `tool.execute.before` blocks the call**, which is functionally what `t4-gate` does:

```js
export const EnvProtection = async ({ project, client, $, directory, worktree }) => {
  return {
    "tool.execute.before": async (input, output) => {
      if (input.tool === "read" && output.args.filePath.includes(".env")) {
        throw new Error("Do not read .env files")
      }
    },
  }
}
```

Hook surface is broad: `tool.execute.before` / `tool.execute.after`, `session.created` /
`session.compacted` / `session.idle`, `permission.asked` / `permission.replied`, `file.edited`,
`command.executed`, `message.*`, `tui.*`, `shell.env`, `lsp.*`.

Separately, dangerous-command blocking is available **declaratively**, without writing a plugin:

```json
{
  "permission": {
    "bash": { "*": "ask", "git *": "allow", "npm *": "allow", "rm *": "deny" }
  }
}
```

Wildcards are `*` (zero or more) and `?` (exactly one), matched against the parsed command, and
**the last matching rule wins**. The gated tool list includes `read`, `edit`, `glob`, `grep`, `bash`,
`task`, **`skill`**, `lsp`, `question`, `webfetch`, `websearch`, `external_directory`, `doom_loop`.

**Consequence for the enforcement ladder.** The ladder documented in `guards-layer.md` and ADR 0001
reads:

```
Tier 0    PreToolUse gate   →  binds Claude
Tier 0.5  git pre-push      →  binds every agent + human on the clone
Tier 3    CI required check →  binds everyone
```

The Tier 0.5 argument stands — Codex and Gemini still have no equivalent, and a human pushing has
none either. What is incomplete is the implied "so Claude is the only agent with a native gate."
OpenCode has one, which makes a plugin a **third delivery path** alongside the bootstrap `.claude/hooks/`
copy and the Claude Code plugin.

## 4a. The dispatcher does not port — only its compaction half does

This was the survey's open question: whether a plugin can inject context at session start, since that
is the mechanism the whole `using-t4` dispatcher depends on. **Answered: it cannot.**

- `session.created` is listed as an event with no documented payload or mutation surface — detection
  only. No example injects through it.
- `experimental.session.compacting` **does** inject. It exposes `output.context.push(...)`, and
  setting `output.prompt` replaces the compaction prompt entirely (which makes `output.context`
  ignored). It fires *before the LLM generates the continuation summary*.

So the T4 dispatcher ports on the **compact** leg and not the **startup** leg, and even the compact
leg runs through an `experimental.` hook. That asymmetry matters: `t4-session-start` fires on
`startup|clear|compact` precisely because compaction is when the map is most likely to have fallen
out of context — OpenCode covers that case and misses the one where a session begins cold.

Anything equivalent to a cold-start injection would have to come from a different mechanism —
`instructions` in `opencode.json`, or `AGENTS.md`/`CLAUDE.md` content, both of which are static files
rather than a hook.

## 5. Two enforcement mechanisms we have no analogue for

**The `skill` tool is itself permission-gated.** Because `skill` appears in the permission tool list,
an operator can make consulting the map a config-level requirement rather than an injected reminder.
The entire `using-t4` dispatcher exists to raise the odds that a skill is invoked; here that is
expressible as configuration.

**Policies override in the operator's favour.** `experimental.policies` statements take
`{effect, action, resource}` — currently only `provider.use`. The documented precedence is the
inverse of the usual: *"If policies from both locations match the same provider, your global policy
takes priority over the project policy. This prevents a repository from re-enabling a provider that
you deny globally."*

Everything in the T4 ladder is per-repo and can be weakened by editing the repo. A global-beats-local
rule is a shape the ladder does not currently have, and it is the shape that survives a hostile or
careless checkout.

## 6. Mapping

| xeno-skills / T4 | OpenCode | Portability |
|---|---|---|
| `SKILL.md` + `npx skills` | `skill` tool, six search paths incl. `.claude/` | **works today, unchanged** |
| `CLAUDE.md` | `AGENTS.md` primary, `CLAUDE.md` fallback | **works today, unchanged** |
| `PreToolUse` gate (`t4-gate`) | plugin `tool.execute.before`, throw to block | portable — rewrite in JS |
| dangerous-git deny list | `permission.bash` patterns, last-match-wins | partly declarative, no plugin needed |
| `SessionStart` dispatcher injection | no equivalent — see §4a | **does not port** (compact leg only) |
| `UserPromptSubmit` reminder | no documented equivalent found | unknown |
| `/grill-me`, `/tdd`, … | `.opencode/commands/*.md`, `$ARGUMENTS`, `` !`shell` `` | portable — rewrite per command |
| clink subagents | agents as markdown, `mode: subagent`, per-agent `permission` | different mechanism, same intent |
| verify-before-merge | no equivalent; a plugin would have to run it | portable via plugin |

## 7. Method, and its boundary

**Doc-sourced** (read from `opencode.ai/docs` on 2026-08-11, pages: index, `/skills/`, `/plugins/`,
`/permissions/`, `/rules/`, `/agents/`, `/commands/`, `/policies/`, `/config/`): every path list,
frontmatter rule, hook name, permission and policy schema, and config key above. Fetched through a
summarising reader, not read as raw HTML — quoted strings are reproduced from that reader's output.

**Machine-verified** (run here, 2026-08-11, OpenCode **1.18.15** at `~/.bun/bin/opencode.exe`): the
contents of `~/.claude/skills/` and `~/.agents/skills/`; and `opencode debug skill`, which loaded 379
skills including **all 14 of ours**, resolved from `~/.agents/skills/`.

**Corrected after first publication.** The first version of this file placed *"OpenCode has never been
installed or run"* in the unverified column. That was false: it was installed at
`~/.bun/bin/opencode.exe`, simply absent from `PATH`, which is why a check for the binary would have
come back empty and why the claim felt safe to make. It was never checked at all. The error was caught
by another agent working the same clone, and the fix is not merely to delete the sentence — running
the tool promoted §1 from doc-sourced to observed and corrected the install path in the process. A
register table is worth exactly what its worst cell is worth; one wrong cell puts every other cell in
question, which is why this correction is recorded rather than quietly edited away.

**Unverified, and load-bearing:**

- **No plugin was written or executed.** `tool.execute.before` blocking a call is doc-sourced and its
  example is quoted, but nothing in this survey exercised it. The claim that the T4 gate is portable
  rests on a reading, not a run — and §8.2 is deliberately gated on that.
- One fetched summary described permissions as "post-tool-use gating," which contradicts the
  `tool.execute.before` hook name and example on the same site. Treated here as an artifact of the
  summariser; resolving it needs the source.
- Whether a user can bypass a policy is not addressed in the docs.
- Why `.agents` (path 6) resolved ahead of `.claude` (path 4) is not established — see §1.

## 8. Implications, deliberately not acted on

1. The README and skill descriptions say "for Claude Code." That is now narrower than the truth for
   the skills, though not for the hooks.
2. A `.opencode/plugins/t4-gate.js` would give the enforcement layer a second native home. Worth
   doing only after §7's unverified items are resolved — a gate ported from a misread of the docs is
   worse than no gate, because the repo would believe it is covered.
3. `guards-layer.md` should qualify its Claude-only premise. The conclusion does not change; the
   reasoning as written is now falsifiable by a reader who knows OpenCode.
4. The `skill`-as-gated-tool and global-beats-project policy shapes are both stronger than anything in
   the current ladder and are worth considering on their own merits, independently of OpenCode.

### Open issues this bears on

- **#83** (every GitHub-mutating MCP tool bypasses the gate) and **#126** (the gate disappears
  silently without bash). §4's third delivery path matters *most* exactly where the Claude path fails
  open, which is what both of these describe. A gate that binds tool calls rather than shell strings
  is the shape neither of those defects could take.
- **#85** (a repo missing `.claude/t4.json` is silently ungated, with no way to tell). §5's
  global-beats-project policy precedence is a direct design answer: an operator-level rule a
  repository cannot switch off is precisely what #85 asks for, and nothing in the current ladder has
  that shape — every T4 control is per-repo and editable from inside the repo.

*Cross-references contributed by a second agent surveying OpenCode as a `clink` client rather than as
a skill host; the two surveys do not overlap and neither supersedes the other.*
