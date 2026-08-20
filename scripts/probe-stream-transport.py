"""Re-probe the supervisor transport when the CLI version changes (#305, PRD #304).

RUN THIS, DO NOT TRUST THE FIXTURE. tests/hooks/fixtures/t4-compact-stream-transport.jsonl
records what claude 2.1.222 did on 2026-08-21; a fixture cannot notice that a later build
changed the contract. The capability rows in the plan carry the date they were verified for
the same reason -- an old date is a prompt to re-probe, not a fact.

WHAT IT ESTABLISHES, by observation:

  Q1  a slash command sent as a USER MESSAGE on --input-format stream-json EXECUTES.
      Observed: system/status status=compacting, then compact_result=success, and the
      result event for that message carries num_turns=0 with zero usage -- no model call.
  Q2  the stream carries what the layer needs: per-result usage (cache_read is the running
      context size) and the compaction outcome.
  Q4  --replay-user-messages echoes an injected message back, so injection is acknowledged.

It costs real tokens: eight cheap turns on Haiku, one compaction, one recall question.
"""
import json, os, subprocess, threading, time

CLAUDE = r"C:\Users\xenod\.local\bin\claude.exe"
HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "stream2.jsonl")
SESSION = "9d2f4b61-8c07-4a3e-b5d1-77e0c6a94f12"
MODEL = "claude-haiku-4-5-20251001"

cmd = [CLAUDE, "-p", "--input-format", "stream-json", "--output-format", "stream-json",
       "--replay-user-messages", "--verbose", "--session-id", SESSION, "--model", MODEL]

events, lock = [], threading.Lock()


def pump(stream, sink):
    for raw in iter(stream.readline, ""):
        line = raw.rstrip("\n")
        if line:
            with lock:
                sink.append(line)
    stream.close()


def send(proc, text):
    with lock:
        mark = len(events)
    proc.stdin.write(json.dumps({"type": "user", "message": {
        "role": "user", "content": [{"type": "text", "text": text}]}}) + "\n")
    proc.stdin.flush()
    print("SENT %r" % text[:60], flush=True)
    return mark


def wait_result(deadline_s, mark):
    end = time.time() + deadline_s
    while time.time() < end:
        with lock:
            chunk = events[mark:]
        for line in chunk:
            try:
                o = json.loads(line)
            except Exception:
                continue
            if o.get("type") == "result":
                return o
        time.sleep(0.4)
    return None


def main():
    proc = subprocess.Popen(cmd, cwd=HERE, stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                            stderr=subprocess.PIPE, text=True, encoding="utf-8",
                            errors="replace", bufsize=1)
    errs = []
    threading.Thread(target=pump, args=(proc.stdout, events), daemon=True).start()
    threading.Thread(target=pump, args=(proc.stderr, errs), daemon=True).start()

    # Eight cheap turns, each carrying one fact only this conversation knows.
    facts = [
        "Remember: the codename is FALCON. Reply with just: ok",
        "Remember: the port is 8431. Reply with just: ok",
        "Remember: the owner is Xeno. Reply with just: ok",
        "Remember: the branch is feat/probe. Reply with just: ok",
        "Remember: the limit is 42. Reply with just: ok",
        "Remember: the city is Chiang Mai. Reply with just: ok",
        "Remember: the colour is teal. Reply with just: ok",
        "Remember: the animal is otter. Reply with just: ok",
    ]
    for f in facts:
        r = wait_result(120, send(proc, f))
        if r is None:
            print("!! no result for:", f[:40], flush=True)
            break

    print("--- compacting ---", flush=True)
    mark = send(proc, "/compact")
    r = wait_result(240, mark)
    print("compact result event:", (r or {}).get("subtype"), flush=True)
    with lock:
        after = events[mark:]
    for line in after:
        o = json.loads(line)
        if o.get("type") == "system" and o.get("subtype") == "status":
            print("  STATUS:", json.dumps({k: v for k, v in o.items()
                                           if k not in ("session_id", "uuid")}, ensure_ascii=False)[:300], flush=True)

    r = wait_result(120, send(proc, "Without guessing: what is the codename and the port I told you?"))
    with lock:
        tail = events[-14:]
    print("--- after compaction ---", flush=True)
    for line in tail:
        o = json.loads(line)
        if o.get("type") == "assistant":
            c = (o.get("message") or {}).get("content")
            if isinstance(c, list):
                for b in c:
                    if isinstance(b, dict) and b.get("type") == "text":
                        print("  ASSISTANT:", b.get("text", "")[:300].replace("\n", " "), flush=True)

    try:
        proc.stdin.close()
        proc.wait(timeout=60)
    except Exception:
        proc.kill()

    with lock:
        lines = list(events)
    open(OUT, "w", encoding="utf-8").write("\n".join(lines) + "\n")
    print("\n%d events -> %s" % (len(lines), OUT), flush=True)

    # Usage trajectory: what the layer would read to size "context is long".
    print("\nusage per result:", flush=True)
    for line in lines:
        o = json.loads(line)
        if o.get("type") == "result":
            u = o.get("usage") or {}
            print("  turns=%s in=%s cache_create=%s cache_read=%s out=%s" % (
                o.get("num_turns"), u.get("input_tokens"), u.get("cache_creation_input_tokens"),
                u.get("cache_read_input_tokens"), u.get("output_tokens")), flush=True)


if __name__ == "__main__":
    main()
