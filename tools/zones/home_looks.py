"""Adds one authored `examine` spot to each home zone (issue #144), from the hl_<nation>.py tables.

Each entry is zone id -> (prop type or "type:n" for the nth such prop, text lines, extra) where extra is None or a dict
of `find` / `flag` for the spot. The spot goes on that prop's tile. Zones that already have `examine` are left alone, and
the file is edited as text (key appended after the last one) so the zone's own formatting is kept.
Run from the repo root: python3 tools/zones/home_looks.py
"""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import hl_england, hl_wales, hl_scotland, hl_ireland, hl_ni, hl_islands

TABLES = [hl_england, hl_wales, hl_scotland, hl_ireland, hl_ni, hl_islands]
ZONES = "data/zones"

def entries() -> dict:
    out = {}
    for t in TABLES:
        for k, v in t.E.items():
            assert k not in out, "duplicate " + k
            out[k] = v
    return out

def spot_for(z: dict, prop: str, lines: list, extra) -> dict:
    kind, _, nth = prop.partition(":")
    hits = [p for p in z["props"] if p["type"] == kind]
    p = hits[int(nth or 0)]
    ex = {"x": p["x"], "y": p["y"], "text": list(lines)}
    if extra:
        ex.update(extra)
    return ex

def apply(zid: str, spec) -> bool:
    path = "%s/%s.json" % (ZONES, zid)
    raw = open(path, encoding="utf8").read()
    z = json.loads(raw)
    if z.get("examine"):
        return False
    ex = spot_for(z, spec[0], spec[1], spec[2] if len(spec) > 2 else None)
    ascii_ = "\\u" in raw
    body = json.dumps([ex], indent=1, ensure_ascii=ascii_)
    body = body.replace("\n", "\n ")
    tail = "\n" if raw.endswith("\n") else ""
    end = raw.rstrip().rfind("}")
    head = raw[:end].rstrip()
    if '"examine": []' in head:
        return False
    open(path, "w", encoding="utf8").write(head + ',\n "examine": ' + body + "\n}" + tail)
    return True

if __name__ == "__main__":
    n = 0
    for zid, spec in entries().items():
        n += apply(zid, spec)
    print("wrote", n, "of", len(entries()))
