"""Authored examine spots for homes (islands), see home_looks.py. zone -> (prop type[:nth], lines, extra)."""

E = {
    "bermuda_lighthouse": ("wall_map", ["A chart of the waters round Bermuda, the reefs cross-hatched in red and the wrecks marked with small crosses.", "Gibbs Hill was lit in 1846 to keep ships off them, and the crosses show how well that worked early on."], {"find": {"item": "sea_glass"}}),
    "douglas_home1": ("wall_picture", ["A photograph of a Loaghtan ram, four horns, brown wool and an expression of enormous dignity.", "Ned Maddrell, the last native Manx speaker, died in 1974. The language is being taught again, and the sheep will not be told."]),
    "douglas_home2": ("wall_picture", ["A framed photograph of an old Steam Packet ferry steaming into Douglas.", "The company has run boats here since 1830, and Old Tom has crossed on most of them."]),
    "douglas_home3": ("wall_picture", ["A photograph of a Manx cat, sitting very upright, with no tail at all.", "Manx cats are stumpy or tailless because of a natural gene. The Noah story is better, and Aunty Jo knows it."]),
    "falklands_farmhouse": ("fireplace", ["The stove ticks quietly, and a neat stack of peat blocks sits beside it. It has not gone out in years.", "Peat is cut on the Camp in the summer and dried through the winter. Diddle-dee jam is on the shelf above."], {"find": {"item": "peat"}}),
    "pit_boathouse": ("wall_map", ["A chart of Pitcairn with the landing at Bounty Bay marked in pencil, and a note in the margin: aim for the gap.", "The islanders descend from the Bounty mutineers and the Tahitians who settled here in 1790. The longboat is how everything and everyone comes ashore."]),
    "st_helena_plantation_house": ("wall_picture:1", ["A photograph of Jonathan the giant tortoise on the lawn, looking as if the house belongs to him.", "He is thought to have hatched around 1832, which makes him the oldest known living land animal. He has outlasted every Governor in the building."]),
    "tci_lighthouse": ("telescope", ["A brass telescope on a stand, pointed at the reef.", "The lighthouse went up in 1852, cast iron shipped out from England, to warn ships off. Through the glass the sea is a very good blue."]),
}
