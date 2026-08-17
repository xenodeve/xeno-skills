#!/usr/bin/env bash
# Contract tests for hooks/t4-gate (PreToolUse)
# Seam: stdin (PreToolUse JSON) + cwd -> deny-decision JSON (block) OR empty (allow).
# The gate only ever BLOCKS; it never auto-approves (silence = normal flow).
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
HOOK="$REPO_ROOT/hooks/t4-gate"

pass=0 fail=0
ok()  { echo "  PASS: $1"; pass=$((pass+1)); }
bad() { echo "  FAIL: $1"; fail=$((fail+1)); }
denied()  { case "$1" in *'"permissionDecision":"deny"'*) ok "$2";; *) bad "$2 (expected deny, got: ${1:0:50})";; esac; }
asked()   { case "$1" in *'"permissionDecision":"ask"'*)  ok "$2";; *) bad "$2 (expected ask, got: ${1:0:50})";; esac; }
allowed() { if [ -z "$1" ]; then ok "$2"; else bad "$2 (expected allow/silent, got: ${1:0:50})"; fi; }

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
REPO="$TMP/repo"; mkdir -p "$REPO/.claude"; printf '{"t4":true}\n' > "$REPO/.claude/t4.json"
PLAIN="$TMP/plain"; mkdir -p "$PLAIN"
REPOV="$TMP/repov"; mkdir -p "$REPOV/.claude"; printf '{"t4":true,"verify":"exit 0"}\n' > "$REPOV/.claude/t4.json"
REPOF="$TMP/repof"; mkdir -p "$REPOF/.claude"; printf '{"t4":true,"verify":"exit 1"}\n' > "$REPOF/.claude/t4.json"
REPOA="$TMP/repoa"; mkdir -p "$REPOA/.claude"; printf '{"t4":true,"autoMerge":true}\n' > "$REPOA/.claude/t4.json"
REPOAF="$TMP/repoaf"; mkdir -p "$REPOAF/.claude"; printf '{"t4":true,"verify":"exit 1","autoMerge":true}\n' > "$REPOAF/.claude/t4.json"
REPOAFK="$TMP/repoafk"; mkdir -p "$REPOAFK/.claude"; printf '{"t4":true,"afk":true}\n' > "$REPOAFK/.claude/t4.json"
REPOFV="$TMP/repofv"; mkdir -p "$REPOFV/.claude"; printf '{"t4":true,"verify":"echo BROKEN_XYZ; exit 1"}\n' > "$REPOFV/.claude/t4.json"
REPOCI="$TMP/repoci"; mkdir -p "$REPOCI/.claude"; printf '{"t4":true,"requireGreenCI":true}\n' > "$REPOCI/.claude/t4.json"
REPOCIA="$TMP/repocia"; mkdir -p "$REPOCIA/.claude"; printf '{"t4":true,"requireGreenCI":true,"autoMerge":true}\n' > "$REPOCIA/.claude/t4.json"
printf 'PR body\nCloses #7\n' > "$TMP/withref.md"
printf 'PR body\njust some text\n'   > "$TMP/noref.md"

# Stub `gh` so the CI check is testable offline: it echoes a marker and exits
# with $GH_STUB_EXIT (gh pr checks: 0 = all green, 1 = a check failed, 8 = pending).
STUB="$TMP/bin"; mkdir -p "$STUB"
cat > "$STUB/gh" <<'STUBEOF'
#!/usr/bin/env bash
# `pr diff --name-only` answers with $GH_STUB_FILES so #141's diff-aware review ask is
# testable offline; everything else keeps the original checks behaviour.
if [ "${1:-}" = "pr" ] && [ "${2:-}" = "diff" ]; then
  [ "${GH_STUB_DIFF_FAIL:-0}" = "1" ] && exit 1
  printf '%s\n' ${GH_STUB_FILES:-README.md}
  exit 0
fi
echo "GH_STUB_CALLED $*"
exit "${GH_STUB_EXIT:-0}"
STUBEOF
chmod +x "$STUB/gh"

bashj() { printf '{"tool_name":"Bash","tool_input":{"command":"%s"},"cwd":"x"}' "$1"; }
mcpj() { printf '{"tool_name":"%s","tool_input":%s,"cwd":"x"}' "$1" "$2"; }
run()  { ( cd "$1" && printf '%s' "$2" | bash "$HOOK" ); }
# Same as run(), but with the stub `gh` first on PATH and a forced stub exit code.
runci() { ( cd "$1" && export PATH="$STUB:$PATH" GH_STUB_EXIT="$2"; printf '%s' "$3" | bash "$HOOK" ); }

echo "PR-needs-issue:"
allowed "$(run "$REPO" "$(bashj 'gh pr create --title x --body Closes #12')")"        "allow: PR with #12 inline"
denied  "$(run "$REPO" "$(bashj 'gh pr create --title x --body just-some-text')")"     "deny:  PR with no issue ref"
allowed "$(run "$REPO" "$(bashj "gh pr create --title x --body-file $TMP/withref.md")")" "allow: PR whose --body-file references #7"
denied  "$(run "$REPO" "$(bashj "gh pr create --title x --body-file $TMP/noref.md")")"   "deny:  PR whose --body-file has no ref"

echo "dangerous git:"
denied  "$(run "$REPO" "$(bashj 'git reset --hard HEAD~1')")"              "deny:  git reset --hard"
denied  "$(run "$REPO" "$(bashj 'git push --force origin main')")"         "deny:  git push --force"
allowed "$(run "$REPO" "$(bashj 'git push --force-with-lease origin main')")" "allow: git push --force-with-lease"
denied  "$(run "$REPO" "$(bashj 'git clean -fd')")"                        "deny:  git clean -fd"
denied  "$(run "$REPO" "$(bashj 'git branch -D feature')")"                "deny:  git branch -D"
allowed "$(run "$REPO" "$(bashj 'git commit -m wip')")"                    "allow: ordinary git commit"
allowed "$(run "$REPO" "$(bashj 'git commit -m \"fix: reset --hard was risky\"')")" "allow: 'reset --hard' only inside a commit message"
allowed "$(run "$REPO" "$(bashj 'git commit -m \"document git push --force\"')")"   "allow: 'push --force' only inside a commit message"
allowed "$(run "$REPO" "$(bashj 'git commit -m \"add gh pr create helper\"')")"     "allow: 'gh pr create' only inside a commit message"
allowed "$(run "$REPO" "$(bashj 'git commit -m \"note: gh pr merge flow\"')")"       "allow: 'gh pr merge' only inside a commit message"

echo "#236 — a SEPARATOR inside quoted prose must not manufacture a command position:"
# THE MECHANISM, MEASURED 2026-08-17 WITH A CONTROL. The gate never strips quotes; it
# relies entirely on POS anchoring — `(^|[;&|`(])`. So one `(`, `|`, `;` or `&` inside
# a quoted argument creates a command position out of nothing, and the gated pattern
# after it matches. Remove the separator from the same sentence and every one of these
# returns silence, which is what makes it the separator and not the words.
#
# The four cases above pass today only by accident: no separator happens to precede
# the words in them. These are the same sentences with one character added.
#
# Not academic — hit live four times on 2026-08-16, and each one also ran the full
# `verify` suite at ~90 s. A gate that denies what it should not is one people learn
# to route around, and the route around it also gets past the true positives.
allowed "$(run "$REPO" "$(bashj 'gh issue comment 1 --body \"see (gh pr merge) in the docs\"')")" \
        "allow: a paren before 'gh pr merge' inside a comment body"
allowed "$(run "$REPO" "$(bashj 'gh issue comment 1 --body \"then | gh pr merge\"')")" \
        "allow: a pipe before it"
allowed "$(run "$REPO" "$(bashj 'gh issue comment 1 --body \"first x; gh pr merge\"')")" \
        "allow: a semicolon before it"
allowed "$(run "$REPO" "$(bashj 'gh issue comment 1 --body \"x & gh pr merge\"')")" \
        "allow: an ampersand before it"
allowed "$(run "$REPO" "$(bashj 'gh issue comment 1 --body \"run (git reset --hard) to recover\"')")" \
        "allow: a paren before 'git reset --hard' inside a comment body"
allowed "$(run "$REPO" "$(bashj 'git commit -m \"document (git reset --hard) being denied\"')")" \
        "allow: the same inside a commit message"

# A HEREDOC BODY IS DATA. Found the hard way: the commit that fixed the cases above
# could not itself be committed, because `git commit -F- <<'MSG'` puts the message in
# the command string where it is NOT a quoted span, and a markdown BACKTICK around a
# command name in the prose stayed a command position. Backticks are in POS because
# backtick command substitution is real; inside a heredoc body nothing is.
BT="$(printf '\140')"; SQ="$(printf '\047')"   # backtick and single quote, built not typed
HD_PROSE="git commit -F- <<${SQ}MSG${SQ}\\nthe gate goes silent on ${BT}git reset --hard${BT} while it looks fine\\nMSG\\n"
allowed "$(run "$REPO" "$(printf '{"tool_name":"Bash","tool_input":{"command":"%s"},"cwd":"x"}' "$HD_PROSE")")" \
        "allow: a backticked command name inside a heredoc commit message"
# And the control: the same command OUTSIDE a heredoc is still a real command position.
denied "$(run "$REPO" "$(bashj 'echo x; git reset --hard')")" \
       "deny: the same words after a real separator are still caught"

# FAIL TOWARD DETECTION. The scan step is a subprocess, and a subprocess can die. If
# it does, the naive version leaves `scan` empty, every pattern fails to match, and
# the gate goes silent on `git reset --hard` while looking exactly like a gate with no
# opinion -- a guard that is off and indistinguishable from one that allowed. Probed
# by making the scan step return nothing on purpose, which is the only way to know the
# fallback is wired rather than merely written.
SCANBROKE="$TMP/scanbroke"; mkdir -p "$SCANBROKE/bin" "$SCANBROKE/.claude"
printf '{"t4":true}\n' > "$SCANBROKE/.claude/t4.json"
printf '#!/usr/bin/env bash\nexit 1\n' > "$SCANBROKE/bin/perl"; chmod +x "$SCANBROKE/bin/perl"
denied "$( cd "$SCANBROKE" && export PATH="$SCANBROKE/bin:$PATH"; printf '%s' "$(bashj 'git reset --hard')" | bash "$HOOK" )" \
       "no perl: the gate DENIES rather than going silent — it cannot read the command"
# The control that makes the line above mean something. Denying wherever perl is
# missing would break every non-T4 repository on a machine with the plugin installed
# globally, which is the property that makes the plugin safe to install at all.
allowed "$( cd "$PLAIN" && export PATH="$SCANBROKE/bin:$PATH"; printf '%s' "$(bashj 'git reset --hard')" | bash "$HOOK" )" \
        "and a repo with no .claude/t4.json is still silent, perl or no perl"

# THE LIMIT THIS FIX NARROWS, pinned so it is a decision on the record rather than a
# hole someone finds later. A dangerous command nested inside a quoted string used to
# be caught THROUGH THE VERY SEPARATOR blanked above -- by accident, never by design:
# the same command without a separator was always silent. A regex is not a shell
# parser. If this ever needs to be caught, it needs a parser, not a looser anchor.
allowed "$(run "$REPO" "$(bashj 'sh -c \"x; git reset --hard\"')")" \
        "KNOWN LIMIT: a dangerous command nested in a quoted string is not caught"
allowed "$(run "$REPO" "$(bashj 'bash -c \"git reset --hard\"')")" \
        "and was not caught before this change either -- the control for that claim"

echo "#245 — the ship gate must verify the PR BEING MERGED, not whatever is checked out:"
# THE FIXTURE IS THE POINT. Every other fixture in this file has ONE tree, so it cannot
# tell "verified the working tree" from "verified the PR head" -- which is why 82
# assertions never caught this. Here the working tree is commit A and the PR head is
# commit B, and `verify` records which commit it actually ran against. That is a
# behavioural observation: whatever tree the gate chose is what gets written down.
GITREPO="$TMP/gitrepo"; mkdir -p "$GITREPO/.claude"
( cd "$GITREPO" && git init -q . && git config user.email t@t && git config user.name t
  echo a > f.txt && git add -A && git commit -qm A
  echo b > f.txt && git add -A && git commit -qm B ) >/dev/null 2>&1
HEAD_B="$(cd "$GITREPO" && git rev-parse HEAD)"
( cd "$GITREPO" && git checkout -q HEAD~1 ) >/dev/null 2>&1
HEAD_A="$(cd "$GITREPO" && git rev-parse HEAD)"
printf '%s\n' "$HEAD_B" > "$TMP/prhead.txt"
VERIFIED="$TMP/verified.txt"; rm -f "$VERIFIED"
python - "$GITREPO/.claude/t4.json" "$VERIFIED" <<'PYJSON'
import json, sys
json.dump({"t4": True, "verify": "git rev-parse HEAD > '%s'" % sys.argv[2]},
          open(sys.argv[1], "w", encoding="utf-8"))
PYJSON
# A stub gh that can answer for the PR head. It READS the sha from a file rather than
# having it interpolated in, so no quoting in this fixture can corrupt it.
GHSTUB="$TMP/bin245"; mkdir -p "$GHSTUB"
cat > "$GHSTUB/gh" <<'STUB245'
#!/usr/bin/env bash
if [ "${1:-}" = "pr" ] && [ "${2:-}" = "view" ]; then cat "$T4_TEST_PRHEAD"; exit 0; fi
if [ "${1:-}" = "pr" ] && [ "${2:-}" = "diff" ]; then printf 'README.md\n'; exit 0; fi
exit 0
STUB245
chmod +x "$GHSTUB/gh"
( cd "$GITREPO" && export PATH="$GHSTUB:$PATH" T4_TEST_PRHEAD="$TMP/prhead.txt"
  printf '%s' "$(bashj 'gh pr merge 7 --squash')" | bash "$HOOK" ) >/dev/null 2>&1
GOT="$(cat "$VERIFIED" 2>/dev/null || echo NONE)"
[ "$GOT" = "$HEAD_B" ] && ok "verify ran against the PR head, not the checked-out tree" \
                       || bad "verify ran against ${GOT:0:12} instead of the PR head ${HEAD_B:0:12} (tree is ${HEAD_A:0:12})"

echo "#141 — under autoMerge/afk the review ask now depends on what the diff TOUCHES:"
# THE FIFTH BYPASS, AND IT IS DIFFERENT IN KIND from the four in #129. Those are ways
# PAST the gate. Here the gate runs, sees the command, and CHOOSES to stand down — so
# it survives all four of their fixes. The inline defence was "the checkable guard
# (verify) still holds", which is true and insufficient: verify is the test suite, not
# a review. A change to t4-gate that keeps every test green and removes a deny is
# exactly what verify cannot see, and exactly what the review ask exists for.
#
# Including a PR that weakens the gate performing the skip.
rundiff() { ( cd "$1" && export PATH="$STUB:$PATH" GH_STUB_FILES="$2"; printf '%s' "$3" | bash "$HOOK" ); }

allowed "$(rundiff "$REPOA"   'README.md docs/notes.md' "$(bashj 'gh pr merge 34 --squash')")" \
        "allow: ordinary work under autoMerge still skips the ask — the property worth keeping"
asked   "$(rundiff "$REPOA"   'hooks/t4-gate'           "$(bashj 'gh pr merge 34 --squash')")" \
        "ask:   a PR touching hooks/ keeps the ask, even under autoMerge"
asked   "$(rundiff "$REPOAFK" '.github/workflows/ci.yml' "$(bashj 'gh pr merge 34 --squash')")" \
        "ask:   and under afk, for a workflow change"
asked   "$(rundiff "$REPOA"   'skills/t4/t4-afk/SKILL.md' "$(bashj 'gh pr merge 34 --squash')")" \
        "ask:   and for a t4 skill — the rules themselves"
asked   "$(rundiff "$REPOA"   'docs/adr/0001-hook-based-workflow-enforcement.md' "$(bashj 'gh pr merge 34 --squash')")" \
        "ask:   and for an ADR"
asked   "$(rundiff "$REPOA"   'README.md hooks/t4-gate'  "$(bashj 'gh pr merge 34 --squash')")" \
        "ask:   one enforcement path among many ordinary ones is enough"
# FAIL TOWARD THE ASK. If the diff cannot be read, the gate does not know whether an
# enforcement path was touched — and answering "probably not" is how the bypass got
# here. There is no deadlock risk: if gh cannot answer, `gh pr merge` cannot run either.
asked "$( cd "$REPOA" && export PATH="$STUB:$PATH" GH_STUB_DIFF_FAIL=1; printf '%s' "$(bashj 'gh pr merge 34 --squash')" | bash "$HOOK" )" \
      "ask:   an unreadable diff keeps the ask rather than assuming it was ordinary"
# The MCP path must not drift from the shell path — it is the surface that was already
# invisible once (#83), and two copies of the same skip is how it goes invisible again.
asked   "$(rundiff "$REPOA" 'hooks/t4-gate' "$(mcpj mcp__github__merge_pull_request '{"pullNumber":34}')")" \
        "ask:   and the MCP merge path applies the identical rule"
allowed "$(rundiff "$REPOA" 'README.md'     "$(mcpj mcp__github__merge_pull_request '{"pullNumber":34}')")" \
        "allow: ordinary work through MCP still skips it too"

echo "#83 — a GitHub-mutating MCP tool meets the same gate as the shell command:"
# THE SAME AGENT, IN THE SAME SESSION, REACHING THE SAME API WITHOUT A SHELL. The
# session that filed #83 merged SIX pull requests through mcp__github__merge_pull_request
# across two repositories. Every one skipped the ship gate by construction — no verify,
# no review confirmation — and none of them looked like a bypass at the time.
#
# Decisions come from tool_name + tool_input, because these calls have no shell string.

allowed "$(run "$REPO"  "$(mcpj mcp__github__create_pull_request '{"title":"x","body":"Closes #12"}')")" \
        "allow: MCP pr create WITH an issue ref"
denied  "$(run "$REPO"  "$(mcpj mcp__github__create_pull_request '{"title":"x","body":"just some text"}')")" \
        "deny:  MCP pr create with no issue ref — same rule as gh pr create"
asked   "$(run "$REPOV" "$(mcpj mcp__github__merge_pull_request '{"pullNumber":34}')")" \
        "ask:   MCP merge asks for the review confirmation"
denied  "$(run "$REPOF" "$(mcpj mcp__github__merge_pull_request '{"pullNumber":34}')")" \
        "deny:  MCP merge runs verify and blocks on failure"
allowed "$(rundiff "$REPOA" 'README.md' "$(mcpj mcp__github__merge_pull_request '{"pullNumber":34}')")" \
        "allow: MCP merge under autoMerge skips the ask for ORDINARY work, as the shell path does"

echo "#83 — direct-write tools, and what an UNKNOWN tool defaults to:"
asked "$(run "$REPO" "$(mcpj mcp__github__push_files '{"branch":"main"}')")" \
      "ask:   push_files writes into the repo without touching git"
asked "$(run "$REPO" "$(mcpj mcp__github__create_or_update_file '{"path":"a.txt"}')")" \
      "ask:   create_or_update_file likewise"
asked "$(run "$REPO" "$(mcpj mcp__github__some_future_mutation '{"x":1}')")" \
      "ask:   an UNKNOWN mcp__github__ tool has a stated default, not 'whatever happens'"
# The half that keeps the default from being useless. Failing closed on every GitHub
# MCP call would make the gate unusable and get it switched off, which is #236's lesson.
allowed "$(run "$REPO" "$(mcpj mcp__github__get_me '{}')")" \
        "allow: a READ-only GitHub tool is not a mutation"
allowed "$(run "$REPO" "$(mcpj mcp__github__list_issues '{}')")" \
        "allow: and neither is listing issues"
allowed "$(run "$REPO" "$(mcpj mcp__pal__clink '{"prompt":"x"}')")" \
        "allow: a non-GitHub MCP server is out of scope entirely"
allowed "$(run "$PLAIN" "$(mcpj mcp__github__merge_pull_request '{"pullNumber":34}')")" \
        "allow: and an unmarked repo is untouched by all of it"

echo "#84 — an executable invoked by absolute or quoted path is still the same command:"
# NOT EXOTIC — IT IS WHAT ACTUALLY GETS TYPED HERE. `gh` is not on the PATH that agent
# tool shells inherit on this machine, so every `gh` call in the session that filed #84
# used the quoted absolute path, and the gate was bypassed continuously by an agent
# trying to comply. Measured 2026-08-03: same payload, only the spelling changed.
#
# The anchor itself is kept. It is what stops `git commit -m "reset --hard"` from
# tripping the gate. What changes is that the executable at a command position is
# reduced to its BASENAME first, so the anchor still sees a command and not a path.
denied "$(run "$REPO" "$(bashj '\"/c/Program Files/GitHub CLI/gh.exe\" pr create --title x --body nothing')")" \
       "deny: pr create by quoted absolute path, no issue ref"
asked  "$(run "$REPO" "$(bashj '\"/c/Program Files/GitHub CLI/gh.exe\" pr merge 34 --merge')")" \
       "ask:  pr merge by quoted absolute path"
denied "$(run "$REPO" "$(bashj '\"/c/Program Files/Git/bin/git.exe\" push --force origin main')")" \
       "deny: force-push by quoted absolute path"
denied "$(run "$REPO" "$(bashj '/usr/bin/git reset --hard HEAD~1')")" \
       "deny: reset --hard by unquoted absolute path"
denied "$(run "$REPO" "$(bashj 'git.exe reset --hard HEAD~1')")" \
       "deny: the .exe spelling with no directory"
# THE CONTROL. Reducing to a basename must not become a substring search — that is
# exactly the loosening #84 warns against, and it would reintroduce the false
# positives the anchor was written to prevent.
allowed "$(run "$REPO" "$(bashj '/usr/bin/notgh pr merge 34')")" \
        "allow: an executable whose basename merely ENDS in gh is not gh"
allowed "$(run "$REPO" "$(bashj '/usr/bin/mygit reset --hard')")" \
        "allow: and one that ends in git is not git"

echo "dangerous git — a quoted FLAG must still be denied (no bypass):"
denied "$(run "$REPO" "$(bashj 'git reset \"--hard\" HEAD~1')")"     "deny: git reset with a quoted --hard"
denied "$(run "$REPO" "$(bashj 'git push \"--force\" origin main')")" "deny: git push with a quoted --force"
denied "$(run "$REPO" "$(bashj 'git clean \"-fd\"')")"               "deny: git clean with a quoted -fd"
denied "$(run "$REPO" "$(bashj 'git branch \"-D\" feature')")"       "deny: git branch with a quoted -D"
denied "$(run "$REPO" "$(bashj 'true && git reset --hard HEAD~1')")" "deny: dangerous git after a shell separator"

echo "scope:"
allowed "$(run "$REPO" '{"tool_name":"Edit","tool_input":{"file_path":"x"},"cwd":"x"}')" "allow: non-Bash tool"
allowed "$(run "$PLAIN" "$(bashj 'git reset --hard HEAD~1')")"             "allow: dangerous git in a NON-T4 repo (guard)"

echo "verify-gate — MERGE only (#13: create is iterative; CI builds on push):"
allowed "$(run "$REPOF" "$(bashj 'gh pr create --title x --body Closes #12')")" "allow: verify does NOT run on PR create"
denied  "$(run "$REPOF" "$(bashj 'gh pr merge 3 --squash')")"                   "deny:  verify DOES gate PR merge (fails)"
asked   "$(run "$REPOV" "$(bashj 'gh pr merge 3 --squash')")"                   "ask:   merge with passing verify -> review confirm"
allowed "$(run "$REPOF" "$(bashj 'git commit -m wip')")"                        "allow: verify never gates ordinary commits"

echo "before-merge ask — skipped under standing authorization (#12: AFK):"
asked   "$(run "$REPO"   "$(bashj 'gh pr merge 3 --squash')")" "ask:   interactive merge (no marker) still prompts"
# Since #141 the skip is conditional on the diff, so this needs the stub to answer
# `pr diff`. Without it the gate cannot read what the PR touches and keeps the ask --
# the intended fail-toward-the-ask direction, asserted in the #141 block above.
allowed "$(rundiff "$REPOA" 'README.md' "$(bashj 'gh pr merge 3 --squash')")" "allow: autoMerge/afk marker skips the ask for ordinary work"
denied  "$(run "$REPOAF" "$(bashj 'gh pr merge 3 --squash')")" "deny:  autoMerge still can't bypass a failed verify"

echo "AFK revert allowance (gate must not deadlock t4-afk's revert-to-green):"
allowed "$(run "$REPOAFK" "$(bashj 'git reset --hard HEAD')")"          "allow: reset --hard under afk (revert the in-flight item)"
allowed "$(run "$REPOAFK" "$(bashj 'git clean -fd')")"                  "allow: clean -fd under afk (drop in-flight untracked)"
denied  "$(run "$REPOAFK" "$(bashj 'git push --force origin main')")"   "deny:  force-push still blocked even under afk"
denied  "$(run "$REPO"    "$(bashj 'git reset --hard HEAD')")"          "deny:  reset --hard still blocked without afk"

echo "CI ship gate (opt-in \"requireGreenCI\": every check must be green before merge):"
asked   "$(runci "$REPOCI"  0 "$(bashj 'gh pr merge 3 --squash')")" "ask:   merge allowed when CI is green"
denied  "$(runci "$REPOCI"  1 "$(bashj 'gh pr merge 3 --squash')")" "deny:  merge blocked when a check is FAILING"
denied  "$(runci "$REPOCI"  8 "$(bashj 'gh pr merge 3 --squash')")" "deny:  merge blocked when a check is still PENDING"
allowed "$(runci "$REPOCI"  1 "$(bashj 'gh pr create --title x --body Closes #12')")" "allow: CI check does not gate PR create"
asked   "$(runci "$REPO"    1 "$(bashj 'gh pr merge 3 --squash')")" "ask:   red CI is a no-op when requireGreenCI is unset"
denied  "$(runci "$REPOCIA" 1 "$(bashj 'gh pr merge 3 --squash')")" "deny:  autoMerge/afk cannot bypass a red CI"
out_ci="$(runci "$REPOCI" 1 "$(bashj 'gh pr merge 3 --squash')")"
case "$out_ci" in *GH_STUB_CALLED*) ok "CI check output is in the deny reason";; *) bad "CI output swallowed (no GH_STUB_CALLED)";; esac
case "$out_ci" in *"pr checks 3"*) ok "CI check targets the PR number from the merge command";; *) bad "CI check did not pass the PR number through";; esac

echo "verify diagnostics (failure output surfaced, not swallowed):"
out_fv="$(run "$REPOFV" "$(bashj 'gh pr merge 3 --squash')")"
denied "$out_fv" "deny: merge blocked when verify fails"
case "$out_fv" in *BROKEN_XYZ*) ok "verify failure output is in the deny reason";; *) bad "verify output swallowed (no BROKEN_XYZ)";; esac

echo ""
echo "gate: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
