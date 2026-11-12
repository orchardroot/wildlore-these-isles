"""Authored examine spots for homes (england), see home_looks.py. zone -> (prop type[:nth], lines, extra)."""

E = {
    "bath_home1": ("fireplace", ["A shortbread tin on the mantelpiece, marked DO NOT TOUCH in capital letters.", "The cat has read it and decided it is a challenge."]),
    "bath_home2": ("bookshelf", ["A star atlas lies open beside the old telescope, with one tiny dot ringed in pencil.", "On 13 March 1781 William Herschel spotted it from his garden in Bath, and it turned out to be Uranus. He wanted to call it King George's Star. The astronomers were not keen."], {"flag": "looked_herschel"}),
    "bath_home3": ("table", ["A tin of Bath Olivers, the crisp dry biscuits Dr William Oliver devised in the 1700s.", "He said they were good for you. Sensible, plain, and best with a bit of cheese."]),
    "bath_home4": ("bookshelf", ["A revision timetable, with the rugby fixtures coloured in far more neatly than the lectures.", "The Rec is a few minutes' walk. The exam is later. You can see which has the better handwriting."]),
    "birmingham_home1": ("fireplace", ["A kettle sits on the hob, and by the look of it, always has.", "Nan Pat says the kettle is on in Birmingham the way the tide is in the sea. Tara-a-bit."]),
    "birmingham_home2": ("bookshelf", ["A biscuit tin of old steel pen nibs, each stamped with the maker's name. Gillott's, mostly.", "Birmingham made nibs by the million in the 1800s. The whole world wrote with them."]),
    "birmingham_home3": ("table", ["A school project on canals, drawn in felt tip. The heron is excellent. The towpath is slightly too wide.", "Birmingham claims more miles of canal than Venice, and Mia has the sums to prove it. Spaghetti Junction gets a page of its own."]),
    "birmingham_home4": ("wall_picture:1", ["A retirement card from the depot, signed by half the Number 11 route.", "Thirty years of Outer Circle, one of the longest city bus routes in Europe. He has not been on a bus since. Not once."]),
    "cambridge_home_a": ("fireplace", ["The chimney breast is the same pale gault brick as the street outside.", "Cambridge clay bakes yellowish grey, not red. The landlady calls it Cambridge white. The tenants call it beige."]),
    "cambridge_home_b": ("piano", ["Equations are propped up on the piano where the sheet music should be.", "Newton went home in the plague year of 1665 and came up with half of calculus. The student has taken the hint about working from home."]),
    "cotswolds_woolhouse": ("display_case", ["A skein of Cotswold wool, long in the fibre and with a lustre like silk. A bale of it was a small fortune.", "The Cotswold Lion, as the breed is called, paid for the great wool churches. Not bad for a sheep."], {"find": {"item": "sheep_wool"}}),
    "dover_painted_house": ("display_case", ["Part of the floor has been lifted to show a hypocaust: little pillars of tile, with room for hot air to flow beneath.", "Underfloor heating, Roman style. The house was a hotel for important travellers, which tells you what the important ones expected."]),
}
