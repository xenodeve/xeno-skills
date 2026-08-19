#!/usr/bin/env python3
"""The only thing allowed to write a hook configuration, for any host (#226).

Run:  python scripts/generate-hook-config.py <host> <out.json> --hook EVENT=SCRIPT ...

WHY A GENERATOR AT ALL. Hand-writing a hook config is a documented silent-failure
path -- #212 catalogues five ways a configured hook is completely dead while the
file still reads as correct, and three of them are properties of HOW THE FILE WAS
PRODUCED rather than of what it says:

  * A UTF-8 BOM makes cursor load the file as nothing. Silently. It is the default
    output of Windows PowerShell's `Set-Content -Encoding utf8`, which is exactly
    what someone on this platform reaches for. `json.loads` accepts a BOM; cursor
    does not.
  * An unrecognised handler TYPE voids cursor's entire file, not the entry.
  * An unknown event KEY does the same, and on codex it is ignored with no
    diagnostic at all -- `--strict-config` does not catch it.

So: allowlists refuse the bad entry HERE, where the refusal is visible, instead of
at the client, where it is silent and takes the whole file with it. And every write
READS ITS OWN BYTES BACK.

THE SHAPES GENUINELY DIFFER, and getting one wrong is silent on three of four
hosts. Measured 2026-08-14 and recorded in docs/research/cli-capability-reference.md.
"""
import argparse
import json
import os
import sys

# Event names and handler types verified against each host's own artifact -- its
# binary, its bundle, or its shipped hook contract -- never another vendor's
# spelling. Three wrong negatives in this project came from testing one vendor's
# event name against another's runtime.
ALLOWLIST = {
    "claude": {
        "events": {"SessionStart", "UserPromptSubmit", "PreToolUse", "PostToolUse",
                   "PostToolBatch", "Stop", "SubagentStart", "SubagentStop",
                   "PreCompact", "PostCompact", "SessionEnd", "InstructionsLoaded"},
        "types": {"command", "prompt", "agent"},
    },
    "codex": {
        # Ten events and that is all -- an exhaustive enum, verified. Unlike the
        # other three, its documentation is not a subset of its behaviour.
        "events": {"SessionStart", "SessionEnd", "UserPromptSubmit", "PreToolUse",
                   "PostToolUse", "Stop", "SubagentStart", "SubagentStop",
                   "PreCompact", "PostCompact"},
        "types": {"command"},
    },
    "cursor": {
        "events": {"beforeShellExecution", "afterShellExecution", "beforeReadFile",
                   "afterFileEdit", "beforeSubmitPrompt", "preToolUse",
                   "postToolUse", "stop"},
        "types": {"command", "prompt"},
    },
    "agy": {
        "events": {"SessionStart", "PreToolUse", "PostToolUse", "PreInvocation",
                   "PostInvocation", "Stop"},
        "types": {"command"},
        # PreToolUse and PostToolUse take a GROUPED matcher + hooks wrapper; the
        # rest take handler objects FLAT. A flat list on a tool event is dropped
        # with no diagnostic and the file still counts as loaded -- the trap that
        # cost the most time on this host.
        "grouped_events": {"PreToolUse", "PostToolUse"},
    },
}


def build(host, hooks):
    spec = ALLOWLIST[host]
    for event, script in hooks:
        if event not in spec["events"]:
            raise ValueError(
                "%s: event %r is not on the allowlist. An unknown event key is "
                "silent on this host and can void the whole file." % (host, event))

    if host == "claude":
        out = {"hooks": {}}
        for event, script in hooks:
            out["hooks"].setdefault(event, []).append(
                {"matcher": "", "hooks": [{"type": "command", "command": script}]})
        return out

    if host == "codex":
        # Windows needs commandWindows, forward slashes only.
        out = {"hooks": []}
        for event, script in hooks:
            out["hooks"].append({"event": event, "type": "command",
                                 "command": script,
                                 "commandWindows": script.replace("\\", "/")})
        return out

    if host == "cursor":
        out = {"version": 1, "hooks": {}}
        for event, script in hooks:
            out["hooks"].setdefault(event, []).append({"command": script})
        return out

    if host == "agy":
        # The top-level key is a HOOK NAME, not the literal string "hooks".
        out = {"t4": {}}
        for event, script in hooks:
            handler = {"type": "command", "command": script,
                       "windows": script.replace("\\", "/")}
            if event in spec["grouped_events"]:
                out["t4"].setdefault(event, []).append(
                    {"matcher": "", "hooks": [handler]})
            else:
                out["t4"].setdefault(event, []).append(handler)
        return out

    raise ValueError("unknown host %r" % host)


def write_and_verify(path, doc):
    """Write, read the bytes back, compare. A BOM, a stray encoding or a truncated
    write fails loudly here instead of silently at the client."""
    payload = (json.dumps(doc, indent=2, ensure_ascii=False) + "\n").encode("utf-8")
    if payload.startswith(b"\xef\xbb\xbf"):
        raise ValueError("refusing to write a BOM -- cursor loads such a file as nothing")
    with open(path, "wb") as f:
        f.write(payload)
    with open(path, "rb") as f:
        back = f.read()
    if back != payload:
        raise ValueError("byte readback mismatch: wrote %d bytes, read %d"
                         % (len(payload), len(back)))
    if back.startswith(b"\xef\xbb\xbf"):
        raise ValueError("the file on disk starts with a BOM")
    return len(payload)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("host", choices=sorted(ALLOWLIST))
    ap.add_argument("out")
    ap.add_argument("--hook", action="append", default=[], metavar="EVENT=SCRIPT")
    args = ap.parse_args()

    hooks = []
    for spec in args.hook:
        if "=" not in spec:
            print("--hook takes EVENT=SCRIPT, got %r" % spec, file=sys.stderr)
            return 2
        event, script = spec.split("=", 1)
        hooks.append((event.strip(), script.strip()))

    try:
        doc = build(args.host, hooks)
        n = write_and_verify(args.out, doc)
    except ValueError as e:
        print("generate-hook-config: %s" % e, file=sys.stderr)
        return 1
    print("wrote %s for %s (%d bytes, read back and compared)"
          % (os.path.basename(args.out), args.host, n))
    return 0


if __name__ == "__main__":
    sys.exit(main())
