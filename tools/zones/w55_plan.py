# Dry run: where would each road's gaps go? python3 tools/zones/w55_plan.py haworth:west blackpool:east ...
import sys
from w55_lib import *

for arg in sys.argv[1:]:
    zid, side = arg.split(":")[:2]
    parts = arg.split(":")
    want = int(parts[2]) if len(parts) > 2 and parts[2].isdigit() else None
    at, cut = plan_gap(zid, side, want, water_ok=arg.endswith(":b"))
    d = json.load(open(os.path.join(OUT, zid + ".json")))
    print(zid, side, "at", at, "cut tiles", len(cut), "size", len(d["rows"][0]), "x", len(d["rows"]), "edges", list(d["edges"]))
