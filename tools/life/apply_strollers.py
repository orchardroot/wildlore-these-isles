#!/usr/bin/env python3
"""Writes tools/life/pick_strollers.gd's picks into data/zones/*.json as text edits, so each file keeps its own
formatting (indented or one object per line). Usage: apply_strollers.py <picks.json>"""
import json, re, sys

def edit(raw, pick):
    pid = re.escape(pick["id"])
    move = pick["move"]
    path = pick.get("path", [])
    # indented layout: "id" on its own line, "move" a few lines on
    m = re.search(r'^( *)"id": "%s",?\n' % pid, raw, re.M)
    if m:
        ind = m.group(1)
        seg_end = raw.find("\n%s}" % ind[:-1], m.end())
        seg = raw[m.start():seg_end]
        mm = re.search(r'^( *)"move": "still"(,?)\n', seg, re.M)
        if not mm or '"path"' in seg or '"radius"' in seg:
            return None
        if move == "wander":
            new = '%s"move": "wander",\n%s"radius": %d%s\n' % (ind, ind, pick["radius"], mm.group(2))
        else:
            items = ",\n".join('%s "%s"' % (ind, d) for d in path)
            new = '%s"move": "pace",\n%s"path": [\n%s\n%s]%s\n' % (ind, ind, items, ind, mm.group(2))
        s = m.start() + mm.start()
        return raw[:s] + new + raw[s + len(mm.group(0)):]
    # compact layout: {"id": "x", ... "move": "still", ...}
    m = re.search(r'\{"id": "%s",[^{}]*?"move": "still"' % pid, raw)
    if not m or '"path"' in m.group(0):
        return None
    if move == "wander":
        new = '"move": "wander", "radius": %d' % pick["radius"]
    else:
        new = '"move": "pace", "path": [%s]' % ", ".join('"%s"' % d for d in path)
    return raw[:m.end() - len('"move": "still"')] + new + raw[m.end():]

picks = json.load(open(sys.argv[1]))
done = 0
for pick in picks:
    f = "data/zones/%s.json" % pick["zone"]
    raw = open(f).read()
    out = edit(raw, pick)
    if out is None:
        print("skipped", pick["zone"], pick["id"])
        continue
    json.loads(out)
    open(f, "w").write(out)
    done += 1
print("applied", done, "of", len(picks))
