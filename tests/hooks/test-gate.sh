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
printf 'PR body\nCloses #7\n' > "$TMP/withref.md"
printf 'PR body\njust some text\n'   > "$TMP/noref.md"

bashj() { printf '{"tool_name":"Bash","tool_input":{"command":"%s"},"cwd":"x"}' "$1"; }
run()  { ( cd "$1" && printf '%s' "$2" | bash "$HOOK" ); }

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
allowed "$(run "$REPOA"  "$(bashj 'gh pr merge 3 --squash')")" "allow: autoMerge/afk marker skips the ask"
denied  "$(run "$REPOAF" "$(bashj 'gh pr merge 3 --squash')")" "deny:  autoMerge still can't bypass a failed verify"

echo "AFK revert allowance (gate must not deadlock t4-afk's revert-to-green):"
allowed "$(run "$REPOAFK" "$(bashj 'git reset --hard HEAD')")"          "allow: reset --hard under afk (revert the in-flight item)"
allowed "$(run "$REPOAFK" "$(bashj 'git clean -fd')")"                  "allow: clean -fd under afk (drop in-flight untracked)"
denied  "$(run "$REPOAFK" "$(bashj 'git push --force origin main')")"   "deny:  force-push still blocked even under afk"
denied  "$(run "$REPO"    "$(bashj 'git reset --hard HEAD')")"          "deny:  reset --hard still blocked without afk"

echo "verify diagnostics (failure output surfaced, not swallowed):"
out_fv="$(run "$REPOFV" "$(bashj 'gh pr merge 3 --squash')")"
denied "$out_fv" "deny: merge blocked when verify fails"
case "$out_fv" in *BROKEN_XYZ*) ok "verify failure output is in the deny reason";; *) bad "verify output swallowed (no BROKEN_XYZ)";; esac

echo ""
echo "gate: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
