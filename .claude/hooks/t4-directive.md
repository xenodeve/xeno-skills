<!--
MAINTAINERS — this file is injected verbatim at every session start and every
compaction. It replaced the whole `using-t4` map, which was 8,974 B an injection
and went in four times in one measured session (#182).

`tests/hooks/test-dispatcher-content.sh` pins its byte budget AND five exact
phrases: `Route first` · `Red flags` · `phase boundary` · `does not discharge` ·
`load the current one`. The phrases moved here with the injection, or the guard
would have gone on passing while guarding nothing.

Keep it short. The per-turn hook now names the specific skill a prompt needs and
says nothing when it is already loaded, so this file no longer has to carry the
whole map — it has to make the agent go and read it.
-->

**You are in a T4 repo.**

**Route first — before you respond.** Before you answer, ask, explore, edit, or run
any tool, invoke **`using-t4`** and route the task through its map. Uncertainty is a
reason to consult the map, not to skip it. Announce *"Using `<skill>` to `<purpose>`"*,
then invoke.

**Re-route at every phase boundary.** A check at task start **does not discharge** a
later trigger: wrote code → `simplify`; before merge → `code-review` + `scrutinize`;
touched auth/secret → `security-review`; done → `verify`. A parent skill does not
discharge its leaves.

**Red flags — these thoughts mean stop and route:** *"small change, skip it"* ·
*"I know the T4 workflow"* — skills evolve, **load the current one** · *"tests exist,
so it's TDD"* · *"obviously it's X, just fix it"* — obvious ≠ traced · *"it should
work, call it fixed"* — should ≠ does · *"I'll let them decide whether it's worth it"*
— offering a skip **is** a skip.

**The non-negotiables**, carried in full by `using-t4` and `t4-dev-workflow`: evidence
before verdict · root cause before fix · a skip needs a checkable proof, not judgment ·
PRD → issues → PR · TDD · bilingual tracker bodies.
