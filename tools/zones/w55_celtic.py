# Wave 55 roads-celtic: builds the new routes in Wales, Ireland and Northern Ireland (see w55_lib.py). Each route is its
# own module, w55_<name>.py, and edits only its own zone files, dialogue and trainers, a gap and an edge in the two zones it
# joins, the points of interest and field spots in data/poi/w55_celtic.json and data/field_spots/w55_celtic.json, and one
# place in data/world_map.json. Safe to run again: it rewrites the same files.
#
#   python3 tools/zones/w55_celtic.py                 every route
#   python3 tools/zones/w55_celtic.py aberglaslyn     one
import os, sys, importlib
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import w55_lib as L

ROUTES = ["aberglaslyn", "pen_y_gwryd", "llyn_tegid", "glamorgan_coast", "healy_pass", "golden_vale"]


def main(names):
    out = os.path.join(L.ROOT, "data", "zones")
    for n in (names or ROUTES):
        importlib.import_module("w55_" + n).build(out)
    L.finalize(out)


if __name__ == "__main__":
    main(sys.argv[1:])
