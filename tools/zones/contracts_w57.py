#!/usr/bin/env python3
"""Wave 57 contracts: puts the pieces a reworked contract gained into the zones, by text, like contracts_w55.py.

    python3 tools/zones/contracts_w57.py add mink scat        # one or more new clues of an existing contract
    python3 tools/zones/contracts_w57.py new mink_next        # a whole new contract (people, spots, lair, folk)

A look-spot in "places.looks" may say "at": [x, y] for an exact tile (a buoy the coracle floats up to); otherwise the
tile is searched for near "near", as in wave 55.
"""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import contracts_w55 as w55  # noqa: E402


def load(cid):
    return json.load(open(os.path.join(w55.ROOT, "data", "contracts", cid + ".json"), encoding="utf-8"))


def add(cid, clues):
    c = load(cid)
    pl = c["places"]
    zones, scripts = {}, {}

    def zone(zid):
        if zid not in zones:
            zones[zid] = w55.Zone(zid)
        return zones[zid]

    for cl in clues:
        k = next(k for k in c["clues"] if k["id"] == cl)
        spec = f'"clue": "{cid}.{cl}"'
        if spec in zone(k["zone"]).text or f'"id": "ct_{cid}_{cl}"' in zone(k["zone"]).text:
            raise SystemExit(f"{cid}.{cl} is already placed")
        for lk in pl.get("looks", []):
            if lk["clue"] == cl:
                z = zone(k["zone"])
                x, y = tuple(lk["at"]) if "at" in lk else z.find_spot(z.anchor(lk["near"]), lk.get("on", "any"))
                ex = {"x": x, "y": y, "text": lk["text"], "clue": f"{cid}.{cl}"}
                if k.get("from") == "coracle":
                    ex["coracle"] = True  # reached by coracle: ZoneData.validate looks for somewhere afloat to face it from
                z.add_examine(ex)
        for wi in pl.get("witnesses", []):
            if wi["clue"] == cl:
                z = zone(k["zone"])
                key = f"ct_{cid}_{cl}"
                x, y = z.find_stand(z.anchor(wi["near"]))
                z.add_npc({"id": key, "sprite": wi["sprite"], "x": x, "y": y, "facing": "down", "move": "still", "script": key, "name": k["who"]})
                scripts.setdefault(k["zone"], {})[key] = [{"do": "contract", "as": "clue", "id": cid, "clue": cl}]
    for z in zones.values():
        z.save()
    for zid, s in scripts.items():
        w55.add_dialogue(zid, s)
    for zid, z in zones.items():
        for e in z.new_examine:
            print("  look %-30s %s (%d,%d)" % (e["clue"], zid, e["x"], e["y"]))
        for n in z.new_npcs:
            print("  npc  %-30s %s (%d,%d)" % (n["id"], zid, n["x"], n["y"]))


def main():
    if len(sys.argv) < 3:
        raise SystemExit(__doc__)
    if sys.argv[1] == "add":
        add(sys.argv[2], sys.argv[3:])
    elif sys.argv[1] == "new":
        w55.place(load(sys.argv[2]), {})
    else:
        raise SystemExit(__doc__)


if __name__ == "__main__":
    main()
