"""Helpers for the wave 55 story chains (tools/zones/w55_stories_<chain>.py).

Each chain script edits, idempotently: data/dialogue/<zone>.json (new scripts, or lines put in front of an existing
one), data/zones/<zone>.json (new NPCs, optional hide_if on an old one), data/quests/w55_<chain>.json and
data/items/w55_stories.json. Run from the repo root: python3 tools/zones/w55_stories_<chain>.py

Files are written the way Godot's JSON writer wrote them (one space of indent, no ASCII escaping); the loader refuses to
touch a file that would not round-trip, so a chain only ever changes the keys it owns.
"""
import json
import os

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
TAG = "_w55"  # marks a block of lines this wave put in front of an old script


def _path(kind, name):
    return os.path.join(ROOT, "data", kind, name + ".json")


def _dump(d):
    return json.dumps(d, indent=1, ensure_ascii=False) + "\n"


_NL = {}  # whether each file ended in a newline when we read it: keep it that way


def load(kind, name):
    p = _path(kind, name)
    raw = open(p, encoding="utf-8").read()
    _NL[p] = raw.endswith("\n")
    d = json.loads(raw)
    if _dump(d) != raw and _dump(d).rstrip("\n") != raw.rstrip("\n"):
        raise SystemExit("%s would not round-trip; edit it by hand" % p)
    return d


def save(kind, name, d):
    p = _path(kind, name)
    text = _dump(d)
    if not _NL.get(p, True):
        text = text.rstrip("\n")
    open(p, "w", encoding="utf-8").write(text)


# --- commands ---------------------------------------------------------------------------

def say(who, text):
    return {"do": "say", "who": who, "text": text}


def setf(flag, value=True):
    return {"do": "set", "flag": flag, "value": value}


def stamp(flag):
    return {"do": "set", "flag": flag, "value": "@now"}


def iff(flag, then, other=None, eq=None):
    c = {"do": "if", "flag": flag}
    if eq is not None:
        c["eq"] = eq
    c["then"] = then
    if other:
        c["else"] = other
    return c


def when(cond, then, other=None):
    c = {"do": "when", "cond": cond, "then": then}
    if other:
        c["else"] = other
    return c


def choice(text, options, flag):
    return {"do": "choice", "text": text, "options": options, "set": flag}


def give(item, n=1):
    return {"do": "give_item", "item": item, "n": n}


def recipe(rid):
    return {"do": "recipe", "id": rid}


END = {"do": "end"}


# --- data ---------------------------------------------------------------------------------

def add_script(zone, name, commands):
    d = load("dialogue", zone)
    d[name] = commands
    save("dialogue", zone, d)


def _tagged(commands, tag):
    out = []
    for c in commands:
        c = dict(c)
        c[TAG] = tag
        out.append(c)
    return out


def prepend(zone, name, tag, commands):
    """Put commands in front of an old script. Re-running replaces the blocks it put there before."""
    d = load("dialogue", zone)
    old = [c for c in d[name] if not (isinstance(c, dict) and c.get(TAG) == tag)]
    d[name] = _tagged(commands, tag) + old
    save("dialogue", zone, d)


def append(zone, name, tag, commands):
    """Put commands after an old script's lines (its own welcome first). Re-running replaces what it added."""
    d = load("dialogue", zone)
    old = [c for c in d[name] if not (isinstance(c, dict) and c.get(TAG) == tag)]
    d[name] = old + _tagged(commands, tag)
    save("dialogue", zone, d)


def add_npc(zone, npc):
    z = load("zones", zone)
    npc = dict(npc)
    npc.setdefault("facing", "down")
    npc.setdefault("move", "still")
    z["npcs"] = [n for n in z["npcs"] if n.get("id") != npc["id"]] + [npc]
    save("zones", zone, z)


def gate_npc(zone, npc_id, **keys):
    z = load("zones", zone)
    for n in z["npcs"]:
        if n.get("id") == npc_id:
            n.update(keys)
    save("zones", zone, z)


def set_quests(chain, quests):
    save("quests", "w55_" + chain, {"quests": quests})


def add_items(items):
    name = "w55_stories"
    p = _path("items", name)
    cur = load("items", name) if os.path.exists(p) else []
    ids = {i["id"] for i in items}
    save("items", name, [i for i in cur if i["id"] not in ids] + items)


def key_item(iid, name, desc):
    return {"id": iid, "name": name, "kind": "key", "price": 0, "battle": False, "field": True, "desc": desc}
