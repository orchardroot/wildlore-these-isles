"""Wave 55 stories: the islands. 'The Isle Boat' (Lerwick, Shetland). python3 tools/zones/w55_stories_islands.py"""
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from w55_stories_lib import *  # noqa

P = "q_stories_islands_"
WOOL, TEA, HALL = "lerwick_wool", "lerwick_tearoom", "lerwick_townhall"
WHEN = P + "when"
RIPE = "later_%s_3" % WHEN


def pick(n, then, other=None):
    return iff(P + "pick", then, other, eq=n)


eila = [
    iff(P + "done", [
        iff(P + "pick_full", [say("Eila", "I am at the stall every day now. The boat runs, and the wool goes out and the yarn comes back. It was dear, and it was worth it. Ask me again in five years.")]),
        iff(P + "pick_lean", [say("Eila", "Tuesday, Thursday, Saturday. You learn to plan by it, like tides. It is not the end of anything. It is only the end of a Wednesday.")]),
        iff(P + "pick_small", [say("Eila", "We have a boat. It is smaller and faster and warm. It will not take a sheep, and the sheep have noticed.")]),
    ], [
        iff(P + "decided", [
            pick(0, [say("Eila", "The full boat. I will say it at the meeting. And then someone will ask who pays, and I will have to say that too.")]),
            pick(1, [say("Eila", "The lean timetable. Three days. I will say it at the meeting, and I will not say it kindly, because I will not feel it kindly.")]),
            pick(2, [say("Eila", "A smaller boat. New, and fewer things it can do. I will say it at the meeting, and I will watch Magnie's face.")]),
            say("Eila", "The isle's post comes in with the boat hand, who has his tea at the harbour tearoom. Word will come, one way or another."),
        ], [
            iff(P + "started", [
                iff(P + "magnie", [
                    iff(P + "ruth", [
                        say("Eila", "Well? You have heard the skipper and you have heard the council. Tell me straight. I am to speak for the isle and I am not allowed to be sure."),
                        choice("What should the isle ask for?", ["The full boat, whatever it costs", "A lean timetable, and the old boat kept going", "A smaller, newer boat", "I need to think"], P + "pick"),
                        pick(0, [setf(P + "pick_full"), setf(P + "decided"), stamp(WHEN)]),
                        pick(1, [setf(P + "pick_lean"), setf(P + "decided"), stamp(WHEN)]),
                        pick(2, [setf(P + "pick_small"), setf(P + "decided"), stamp(WHEN)]),
                        pick(3, [say("Eila", "Take your time. The council will not, but you can.")]),
                        iff(P + "decided", [say("Eila", "I will say it at the meeting. Come back for the post when it is done.")]),
                    ], [say("Eila", "Ruth Leask, in the Town Hall. She has the spreadsheet. She is not the enemy, she only has the spreadsheet.")]),
                ], [say("Eila", "Magnie Tulloch has the harbour tearoom most dinnertimes when he is not at sea. Hear him first.")]),
            ], [
                say("Eila", "Eila Jamieson. I knit, and I sell it here, and I come from the isle, a long way out. The boat takes my jumpers in and the yarn out, and the doctor, and the post, and the cheese."),
                say("Eila", "The boat is old, and it is dear to run, and it will need replacing, and the council has to decide what to do about it. The isle meeting was split down the middle and nobody could agree on a word."),
                say("Eila", "I am to speak for the isle and I cannot be sure. Would you hear the skipper and the council, and tell me what you think we should ask for? You are nobody's cousin."),
                setf(P + "started"),
            ]),
        ]),
    ]),
]

magnie = [
    iff(P + "done", [
        iff(P + "pick_full", [say("Magnie", "She is still on. Five days. In March she broke down and we had a charter for three weeks, which cost more than the engine. I do not say it is an argument. I say it is a fact.")]),
        iff(P + "pick_lean", [say("Magnie", "Three days. I have the crew on part-time and the old girl has two years left in her. I am proud of her and I am not blind.")]),
        iff(P + "pick_small", [say("Magnie", "The little new one is a fine boat. I will not say otherwise. She is not mine, and she is not hers, and the sheep go by charter. I have gone into the harbour office and been very civil.")]),
    ], [
        iff(P + "decided", [say("Magnie", "Whatever the isle asks, I will sail what I am given. I have never had a boat I did not love, and I have had some I should not have.")], [
            iff(P + "started", [
                iff(P + "magnie", [say("Magnie", "Tell Eila I will be at the meeting, and I will keep my mouth shut, which is not like me.")], [
                    say("Magnie", "Magnie Tulloch. Twenty-six years on the isle boat, and fourteen before that on worse. She is old, but she is sound."),
                    say("Magnie", "The council would cut my days, and the crew with them. I would be lying if I said I did not mind. I would also be lying if I said the boat was not dear to run. Everyone has seen the figures. I have seen them upside down, across a desk."),
                    say("Magnie", "What I will say is this: a boat that carries sheep, a doctor and a coffin is not a bus. It is how the isle stays an isle and not a holiday cottage. Whatever else you hear, hear that."),
                    setf(P + "magnie"),
                ]),
            ], [say("Magnie", "Soup, a roll and the weather forecast. In that order. Do not talk to me before the forecast.")]),
        ]),
    ]),
]

ruth = [
    iff(P + "decided", [say("Ruth", "Whatever the isle asks, I will put it to the committee with my name on it. I will recommend what I can defend, and I will say what I could not.")], [
        iff(P + "started", [
            iff(P + "ruth", [say("Ruth", "Tell Eila I would give her the full boat if the pot allowed. That is not a line. That is arithmetic.")], [
                say("Ruth", "Ruth Leask. I do transport for the council, which means I say no to people who are right."),
                say("Ruth", "The isle boat is old and costs more per passenger than anything else we run. It needs replacing within a few years, and the money for lifeline services is one pot, shared between a dozen isles. Every pound for this boat is a pound I cannot give to another isle's boat, or to the school bus on the north Mainland."),
                say("Ruth", "I am not asking the isle to be grateful. I am asking them to tell me which loss they can live with. A smaller boat, or fewer days, or the full service and somebody else's bus. There is no fourth option, and I have looked."),
                setf(P + "ruth"),
            ]),
        ], [say("Ruth", "Please, sit. I have thirty-one emails and six of them are polite.")]),
    ]),
]

LETTERS = {
    "full": [
        "Dear {player}. The committee voted for the full boat. The council found the money by putting off a road scheme in the north Mainland, and the north Mainland wrote a number of letters to the paper.",
        "The boat runs five days. In March the old engine failed and we had a charter for three weeks, which cost more than the engine. The old boat will need replacing in any case.",
        "I think we bought time. Time is what a small place needs most, and what it is always asked to give up first. Come and see the isle. The boat will take you. It is still allowed to.",
    ],
    "lean": [
        "Dear {player}. Three sailings a week: Tuesday, Thursday and Saturday. The vet comes on Tuesday and the nurse on Thursday, and nobody is ill on a Wednesday, by agreement.",
        "The school bairns board in Lerwick Monday to Friday, which some did anyway and which Lorna hates. Two families left in the autumn. I will not say it was the boat, and I will not say it was not.",
        "The old boat has two more years in her, Magnie says. After that we shall all have a conversation we have been avoiding. Come on a Tuesday. We are best on a Tuesday.",
    ],
    "small": [
        "Dear {player}. A new little boat, from the spring: twelve passengers, faster, with a heated cabin, which has been a revelation. Nobody has been sick in it, which is a first for the isle.",
        "It will not carry sheep. The sheep go on a charter twice a year, and the crofters mutter, and rightly. The council kept the flight for emergencies.",
        "We have a boat. We have fewer things the boat can do. I think that is what a fair answer is, in a place like this. Come in the spring. Bring the wind.",
    ],
}

hand = [
    iff(P + "done", [say("Boat hand", "That was yours. The rest of the mailbag is for the isle, and the isle can wait for its tea.")], [
        when(RIPE, [
            say("Boat hand", "There you are. A letter for you, off the boat. Eila put it in with the post for Lerwick and told me not to let it fall in the harbour."),
            iff(P + "pick_full", [say("", t) for t in LETTERS["full"]] + [give("w55_isle_plate"), setf(P + "world_full")]),
            iff(P + "pick_lean", [say("", t) for t in LETTERS["lean"]] + [give("w55_isle_timetable"), setf(P + "world_lean")]),
            iff(P + "pick_small", [say("", t) for t in LETTERS["small"]] + [give("w55_isle_lifebelt"), setf(P + "world_small")]),
            say("Boat hand", "And a shawl, folded small enough to pull through a ring, Eila says, so it will go in your bag. And a note on how to do stovies. The isle way, it says, with the dripping. You will not get it from a book."),
            recipe("stovies"),
            give("shetland_lace_shawl"),
            setf(P + "done"),
        ], [
            say("Boat hand", "Nothing off the boat yet. It comes when the boat comes, and the boat comes when it can. Try after a night's sleep."),
        ]),
    ]),
]

robbie = [
    say("Robbie", "I am back from Aberdeen. Eila's cousin, not that anyone will let me forget. I crew on the boat now, five days a week."),
    say("Robbie", "I went away to be a welder and I came home to tie ropes. My mother says it is the same thing, if you do it properly."),
]
lorna = [
    say("Lorna", "I board in Lerwick Monday to Friday. I am fourteen. I like it and I do not like it, and I have not told my mother which."),
    say("Lorna", "The Tuesday boat is the best boat. I stand at the rail for the whole of it. I would like that written down."),
]
skipper = [
    say("Ingrid", "The new boat. Twelve passengers, a heated cabin, and a very clean deck. I came in from the mainland ferries and I have not stopped being surprised that people wave."),
    say("Ingrid", "I know about the sheep. I have been told, by a number of crofters, in a number of tones. I intend to learn the tone before the lambing."),
]

quest = {
    "id": "stories_islands",
    "title": "The Isle Boat",
    "region": "stories_islands",
    "town": "lerwick",
    "giver": "Eila Jamieson, in the wool shop",
    "summary": "The council is deciding what to do about the old boat to a small Shetland isle. The skipper, the council officer and the isle itself want different things. Hear them, then tell Eila what to ask for.",
    "start_flag": P + "started",
    "steps": [
        {"flag": P + "magnie", "text": "Hear Magnie Tulloch, the skipper, in the Harbour Tea Room.", "zone": TEA},
        {"flag": P + "ruth", "text": "Hear Ruth Leask, the transport officer, in the Town Hall.", "zone": HALL},
        {"flag": P + "decided", "text": "Tell Eila what the isle should ask for.", "zone": WOOL},
        {"flag": P + "done", "text": "Wait for word. The isle's post comes in with the boat hand at the Harbour Tea Room, a night's sleep or a day later.", "zone": TEA},
    ],
    "done_flag": P + "done",
    "reward": "A Shetland lace shawl, a keepsake from the boat, and the isle's stovies recipe.",
    "endings": [
        {"flag": P + "pick_full", "text": "The isle kept the full boat, five days a week, paid for by putting off a road scheme on the north Mainland. The old boat will still need replacing."},
        {"flag": P + "pick_lean", "text": "The isle took a lean timetable: three days a week, and the old boat kept going for a few more years. The school bairns board in Lerwick in the week."},
        {"flag": P + "pick_small", "text": "The isle got a smaller, newer boat: faster, with a heated cabin, and no room for sheep, which now go by charter twice a year."},
    ],
}

items = [
    key_item("w55_isle_plate", "The Old Boat's Engine Plate", "A brass plate off the old boat's engine, polished, with a maker's name and a date from the year the boat came on the run. Magnie says she has earned a plate and a pension."),
    key_item("w55_isle_timetable", "The Three-Day Timetable", "A laminated timetable: Tuesday, Thursday, Saturday. In pen across the top, in Eila's hand: 'Lorna says it is not a timetable, it is a sentence'."),
    key_item("w55_isle_lifebelt", "The Old Lifebelt", "A cork-and-canvas lifebelt, painted with the name of the old boat in red. The new boat has a better one. Nobody could throw this one away."),
]

add_items(items)
set_quests("islands", [quest])
add_script(WOOL, "w55k_eila", eila)
add_script(TEA, "w55k_magnie", magnie)
add_script(HALL, "w55k_ruth", ruth)
add_script(TEA, "w55k_hand", hand)
add_script(WOOL, "w55k_robbie", robbie)
add_script(WOOL, "w55k_lorna", lorna)
add_script(TEA, "w55k_skipper", skipper)

add_npc(WOOL, {"id": "w55k_eila", "name": "Eila Jamieson", "sprite": "villager_4", "x": 3, "y": 5, "facing": "right", "script": "w55k_eila"})
add_npc(TEA, {"id": "w55k_magnie", "name": "Magnie Tulloch", "sprite": "fisherman_north", "x": 4, "y": 4, "facing": "right", "script": "w55k_magnie"})
add_npc(HALL, {"id": "w55k_ruth", "name": "Ruth Leask", "sprite": "commuter", "x": 9, "y": 5, "facing": "left", "script": "w55k_ruth"})
add_npc(TEA, {"id": "w55k_hand", "name": "Boat hand", "sprite": "sailor", "x": 3, "y": 5, "facing": "right", "script": "w55k_hand", "show_if": P + "decided", "hide_if": P + "done"})
add_npc(WOOL, {"id": "w55k_robbie", "name": "Robbie", "sprite": "villager_1", "x": 10, "y": 4, "facing": "left", "script": "w55k_robbie", "show_if": P + "world_full"})
add_npc(WOOL, {"id": "w55k_lorna", "name": "Lorna", "sprite": "student", "x": 9, "y": 5, "facing": "left", "script": "w55k_lorna", "show_if": P + "world_lean"})
add_npc(TEA, {"id": "w55k_skipper", "name": "Ingrid", "sprite": "sailor", "x": 5, "y": 5, "facing": "left", "script": "w55k_skipper", "show_if": P + "world_small"})
print("islands written")
