#!/usr/bin/env python3
"""Adds "fx": {"shape": ...} to every move in data/moves/*.json (wave 47 F). Idempotent: existing fx is kept.
Run from the repo root: python3 tools/dev/add_move_fx.py"""
import glob, json, collections

KW = [  # first match wins; keywords are looked for in the move id
    ("song", ["howl", "wail", "scream", "shriek", "lullaby", "keening", "whisper", "tannoy", "squeal", "yell", "roar", "chatter", "bell", "mutter", "chant", "hoot", "terrace", "ravens_watch"]),
    ("bite", ["bite", "nip", "pinch", "snap", "latch", "chomp", "sting", "prick", "peck"]),
    ("wing", ["swoop", "dive", "plunge", "murmuration", "flurry", "battle_crow", "murder_of_crows"]),
    ("rain", ["rain", "drizzle", "downpour", "hail", "sleet", "shower", "drench", "blizzard", "squall", "spray", "splash", "spit", "sizzle", "scald", "pour"]),
    ("quake", ["stomp", "slam", "crash", "drop", "hammer", "clang", "thunderclap", "megalith", "boulder", "crunch", "scrum", "shove", "quarry", "bash", "caber", "gridlock"]),
    ("wave", ["surge", "tide", "wave", "flood", "spate", "current", "undertow", "ripple", "rush", "fell_run", "sweeper", "frozen_thames", "gale_force", "stornoway", "wind_shear", "bluster", "updraught"]),
    ("burst", ["blast", "burst", "belch", "ball_lightning", "puffball", "furnace", "alarm", "scream", "static", "smoulder", "chip_shop"]),
    ("volley", ["volley", "pelt", "midge", "swarm", "rivet", "pebble", "flint", "conker", "chuck", "kerb", "spark_shower", "spore_puff"]),
    ("slash", ["lash", "slice", "swing", "sweep", "claw", "scratch", "thorn", "spear", "slide", "flick", "bramble", "wrap", "tangle", "poke", "prod", "hurley", "shinty", "kick", "pound", "tap", "rap", "nudge", "barge"]),
    ("pounce", ["pounce", "charge", "dash", "tackle", "scrap", "haymaker", "run", "bounce", "caper", "stomp", "herd", "squabble"]),
]
BEAM_TYPES = {"storm", "frost", "fae", "spirit", "night", "iron"}

def shape(m):
    mid, cat, typ = m["id"], m["category"], m["type"]
    eff = m.get("effect", {})
    eid = eff.get("id", "none")
    if cat == "status":
        if eid == "set_weather":
            return "cloud"
        if eid in ("heal_self", "protect", "cure_team") or eff.get("target") == "self":
            return "self"
        for s, kws in KW:
            if s == "song" and any(k in mid for k in kws):
                return "song"
        return "cloud"
    if eid == "multi_hit":
        return "volley" if cat == "special" else "slash"
    if eid == "drain":
        return "bite" if cat == "physical" else "wave"
    for s, kws in KW:
        if any(k in mid for k in kws):
            return s
    if cat == "special":
        return "beam" if typ in BEAM_TYPES else "bolt"
    return "pounce"

counts = collections.Counter()
for f in sorted(glob.glob("data/moves/*.json")):
    moves = json.load(open(f))
    for m in moves:
        if "fx" not in m:
            m["fx"] = {"shape": shape(m)}
        counts[m["fx"]["shape"]] += 1
    with open(f, "w") as fh:
        fh.write("[\n" + ",\n".join("  " + json.dumps(m, ensure_ascii=False) for m in moves) + "\n]\n")
print(dict(counts))
