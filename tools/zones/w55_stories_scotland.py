"""Wave 55 stories: Scotland. 'The Hall Roof and the Flows' (Thurso and the Flow Country). python3 tools/zones/w55_stories_scotland.py"""
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from w55_stories_lib import *  # noqa

P = "q_stories_scotland_"
PUB, CENTRE = "thurso_pub", "forsinard_centre"
WHEN = P + "when"
RIPE = "later_%s_3" % WHEN


def pick(n, then, other=None):
    return iff(P + "pick", then, other, eq=n)


# --- Isobel Mackay, the hall committee (the Flagstone Bar) -------------------------------------
isobel = [
    iff(P + "done", [
        iff(P + "pick_support", [say("Isobel", "The lunch club has doubled. Thursday is soup and a seat by a radiator that works. I will not tell you it was an easy answer, but I will tell you the roof is dry.")]),
        iff(P + "pick_object", [say("Isobel", "The tarpaulin stays and the raffle goes on. We were asked, and we answered. I have decided that is worth something, on the days I can manage it.")]),
        iff(P + "pick_compromise", [say("Isobel", "Everyone is a bit cross, about equally. I am told that is what a fair answer feels like. I am not convinced, but I am too tired to argue.")]),
    ], [
        iff(P + "decided", [
            iff(P + "pick_support", [say("Isobel", "I will tell the meeting what you said. They will not all like it. Somebody will have to say it out loud, and you have made it easier that it was not one of us.")]),
            iff(P + "pick_object", [say("Isobel", "I will read your letter out on Thursday. There will be a silence, and then Hamish Gunn will say 'aye', and then the rest.")]),
            iff(P + "pick_compromise", [say("Isobel", "Move them off the deep peat. Yes. That might be both of our answers at once, or it might be neither. We shall find out when the developer reads it.")]),
            say("Isobel", "The post for this end of the strath waits at the Flagstone Bar. Word will come, one way or another."),
        ], [
            iff(P + "started", [
                iff(P + "calum", [
                    iff(P + "warden", [
                        say("Isobel", "Well? You have heard Calum and you have heard the Flows. We are four against four on the committee and the chair would sooner have a straight answer from someone who is nobody's cousin."),
                        choice("What do you tell the committee?", ["Back the wind farm as planned", "Object to it", "Back it, but move it off the deep peat", "I need to think"], P + "pick"),
                        pick(0, [
                            setf(P + "pick_support"), setf(P + "decided"), stamp(WHEN),
                            say("Isobel", "Back it. Fourteen turbines on the Flats, the hall roof, the lunch club, the minibus. And a skyline I will see every morning from the kitchen window."),
                            say("Isobel", "I will write it up. Come back for the post when the committee has met."),
                        ]),
                        pick(1, [
                            setf(P + "pick_object"), setf(P + "decided"), stamp(WHEN),
                            say("Isobel", "Object. The peat stays as it is and the waders keep their ridge. And the hall keeps its tarpaulin, and the minibus stays a drawing."),
                            say("Isobel", "I will write it up. Come back for the post when the committee has met."),
                        ]),
                        pick(2, [
                            setf(P + "pick_compromise"), setf(P + "decided"), stamp(WHEN),
                            say("Isobel", "Move the turbines that stand on the deep peat. A smaller scheme, a smaller fund, and the developer may say no and take the lot away."),
                            say("Isobel", "Fair is not the same as safe. I will write it up. Come back for the post when the committee has met."),
                        ]),
                        pick(3, [say("Isobel", "Take your time. The consultation will not, but you can.")]),
                    ], [say("Isobel", "The Flows Warden, at Forsinard. Ask what the ground under the wind farm actually is. Then come back.")]),
                ], [say("Isobel", "Calum is the estate manager. He is at the back table most dinner times. Hear his side, then the Warden's.")]),
            ], [
                say("Isobel", "Isobel Mackay. I do the books for the hall up the strath, so I am used to being the one with the bad news."),
                say("Isobel", "A developer wants to put fourteen turbines on the Flats, the high ground behind us. There is a community fund in it: the hall roof, a lunch club for the old folk, a minibus for the school run. We have a tarpaulin over the roof and two buckets in the kitchen."),
                say("Isobel", "We are four against four. The chair says nobody here can settle it without losing a friend. Would you hear us all out, and then tell us what you think? You are nobody's cousin."),
                setf(P + "started"),
            ]),
        ]),
    ]),
]

calum = [
    iff(P + "done", [
        iff(P + "pick_support", [say("Calum", "The lease pays for the three jobs the estate had, and a fourth. I would be lying if I said that was not on my mind. It was not the only thing on my mind.")]),
        iff(P + "pick_object", [say("Calum", "We are looking at trees instead. The Flow has been planted before, in the eighties, and regretted. So we shall see. I do not like it any better than you do.")]),
        iff(P + "pick_compromise", [say("Calum", "A smaller lease. A smaller fund. A smaller row about it. I am too tired to be cross, and I have been cross about worse.")]),
    ], [
        iff(P + "decided", [say("Calum", "Whatever the committee decides, the estate will live with it. It is their strath too. It is only that it is our ground.")], [
            iff(P + "started", [
                iff(P + "calum", [say("Calum", "Tell the committee I am not their enemy, and not their friend either. I am the man who has to find the wages.")], [
                    say("Calum", "Calum Ross. I run the estate. Three jobs, a lot of hill, and a roof of my own that needs doing."),
                    say("Calum", "The turbines go on our ground, and the lease would pay for the three jobs and more. Estates like ours have not had a good year since the price of lamb went where it went."),
                    say("Calum", "The developer comes from the south, and I have not got used to it, but they have been straight with me and they have been straight with the committee. The fund is real money. I do not say that to buy anyone."),
                    say("Calum", "What I will say is that if it is not turbines then it is trees, or it is selling. I have no wish to sell to anyone who has never seen the place in January."),
                    setf(P + "calum"),
                ]),
            ], [
                say("Calum", "Estate business. Do not mind me. I am working out a rota with a pencil and a very short pencil at that."),
            ]),
        ]),
    ]),
]

kirsty = [
    iff(P + "done", [
        say("Kirsty", "The minibus. The minibus is the thing, and it is not a wind farm thing, it is a money thing, and I do not know any more which."),
    ], [
        say("Kirsty", "Mind the pram. My boy starts school in August and the school is eleven miles away. There is a bus on the timetable that does not, as it happens, go."),
        say("Kirsty", "I would not stay for a wind farm. I would not leave for one either. But I might leave for the school run, and nobody is counting that."),
    ]),
]

warden = [
    iff(P + "done", [
        iff(P + "pick_support", [say("Flows Warden", "The greenshank moved their nests back from the nearest ridge. I count them every April. I will say what I counted and no more.")]),
        iff(P + "pick_object", [say("Flows Warden", "Same number on the ridge as last year. Same is a good number, when you have seen what different looks like.")]),
        iff(P + "pick_compromise", [say("Flows Warden", "They moved them off the deep peat, and I am a little bit cross about the ones that are left, and I have decided to be cross in a measured way.")]),
    ], [
        iff(P + "decided", [say("Flows Warden", "I hear the strath has made up its mind. Whatever it is, I will be out on the ridge counting come April.")], [
            iff(P + "started", [
                iff(P + "warden", [], [
                    iff(P + "calum", [
                        say("Flows Warden", "Ah. They sent you. Good, they usually send me a lawyer."),
                        say("Flows Warden", "I do not oppose wind. I oppose it in the wrong place. Deep blanket bog is a bad place to build: roads and foundations cut the drainage, the peat dries, and it gives back the carbon it has held for thousands of years."),
                        say("Flows Warden", "The Flats are mostly thinner ground on the south side and deep on the north. Greenshank and golden plover nest across the lot. Turbines do not kill many of them; what happens is they move off and do not come back. It is the quiet kind of loss."),
                        say("Flows Warden", "The peat of the Flows holds more carbon than all the forests in Britain put together. Turbines on thin ground are a different conversation."),
                        say("Flows Warden", "And I will tell you the other thing, because I would want to be told. The fund is real. A village with a leaking roof and a school bus that does not run is not an abstraction. Anyone who tells you the peat is simple is selling something. So is anyone who says the roof is."),
                        setf(P + "warden"),
                        END,
                    ], [say("Flows Warden", "About the wind farm on the Flats? Hear the estate manager first, he will be in the Flagstone Bar at the back. Then come and ask me what the ground is.")]),
                ]),
            ]),
        ]),
    ]),
]

LETTERS = {
    "support": [
        "Dear {player}. The roof is on. Slates, and not a tarpaulin in sight. It was the first thing the fund paid for, and the lunch club has doubled.",
        "There are fourteen turbines on the Flats now, and from the hall car park you can see every one. Some days I think they look like a row of people waiting for a bus. Some days Hamish Gunn will not look at them.",
        "The warden writes that the greenshank have moved their nests back from the nearest ridge. He is not cross. He is only measured, and that is worse.",
        "I voted the way you wrote. I would do it again, and I would not blame anyone who would not. Come for the soup.",
    ],
    "object": [
        "Dear {player}. It was refused in the spring. The tarpaulin stays and the raffle goes on. Kirsty has gone to Inverness. She says it was the school run and not the turbines, and I believe her, mostly.",
        "Calum says the estate is looking at trees instead. The Flow has been planted before and regretted, so we shall see.",
        "The warden counted greenshank on the ridge, and it was the same as last year. Same is a good number when you have seen what different looks like.",
        "I do not know if we were right. I do know that we were asked, and that we answered. Come for the soup.",
    ],
    "compromise": [
        "Dear {player}. They moved the turbines off the deep peat. Six had to go, which cost the developer a good deal of temper, and the other eight were built. The fund is smaller. The roof is on, and the minibus is still a drawing.",
        "Calum is cross because the lease is smaller. The warden is cross because there are any. Hamish says it is a wind farm done as badly as everything done halfway.",
        "I think it is the first thing in this strath that everyone has been a bit cross about, equally. That may be what a fair answer feels like. Come for the soup.",
    ],
}

postie = [
    iff(P + "done", [say("Postie", "That was yours. The rest of the strath's post is in the van, and the van is double-parked.")], [
        when(RIPE, [
            say("Postie", "There you are. A letter for you, care of the Flagstone Bar. It has come all the way down the strath in a plastic bag, since you ask."),
            iff(P + "pick_support", [say("", t) for t in LETTERS["support"]] + [give("w55_hall_slate"), setf(P + "world_built")]),
            iff(P + "pick_object", [say("", t) for t in LETTERS["object"]] + [give("w55_hall_feather"), setf(P + "world_object")]),
            iff(P + "pick_compromise", [say("", t) for t in LETTERS["compromise"]] + [give("w55_hall_minute"), setf(P + "world_built")]),
            say("Postie", "There was something else in the bag. A dumpling in a cloth, and a note on how it is done, for a person with a pudding cloth. The strath's recipe, it says."),
            recipe("clootie_dumpling"),
            give("w55_peat_cap"),
            setf(P + "done"),
        ], [
            say("Postie", "Nothing yet. The committee has to meet, and the post has to come down the strath. Try after a night's sleep."),
        ]),
    ]),
]

tech = [
    iff(P + "pick_support", [
        say("Technician", "I am here for the annual service. You can hear them from the car park on a calm night: a sort of long breath. The locals say it grows on you."),
        say("Technician", "I will say this: the ones I like best are the ones nobody argues about. That is not these ones. They are well built, though."),
    ], [
        say("Technician", "Eight machines on the thin ground, and the north side left alone. A smaller job than it was meant to be, and I am told that is the point."),
        say("Technician", "I did hear the warden say it was the first time he had been consulted before the diggers, not after. I would not put that on a poster, but I would not forget it."),
    ]),
]

quest = {
    "id": "stories_scotland",
    "title": "The Hall Roof and the Flows",
    "region": "stories_scotland",
    "town": "thurso",
    "giver": "Isobel Mackay, at the Flagstone Bar",
    "summary": "A wind farm on the hill behind a Caithness strath would pay for the hall roof and a school minibus, on ground the Flows Warden worries about. The committee is split. Hear everyone, then tell them what you think.",
    "start_flag": P + "started",
    "steps": [
        {"flag": P + "calum", "text": "Hear Calum, the estate manager, in the Flagstone Bar.", "zone": PUB},
        {"flag": P + "warden", "text": "Ask the Flows Warden what the ground is.", "zone": CENTRE},
        {"flag": P + "decided", "text": "Tell Isobel what you think the committee should answer.", "zone": PUB},
        {"flag": P + "done", "text": "Wait for word. The strath's post waits at the Flagstone Bar, a night's sleep or a day later.", "zone": PUB},
    ],
    "done_flag": P + "done",
    "reward": "A peat-brown bunnet, a keepsake from the hall, and the strath's clootie dumpling recipe.",
    "endings": [
        {"flag": P + "pick_support", "text": "The wind farm went ahead, the hall roof is slated and the lunch club has doubled. The greenshank moved their nests back from the nearest ridge."},
        {"flag": P + "pick_object", "text": "The application was refused. The peat and the ridge are as they were, the hall roof is still tarpaulin and the minibus is still a drawing."},
        {"flag": P + "pick_compromise", "text": "The scheme was moved off the deep peat and made smaller. The fund is smaller too: the roof is mended, the minibus is not."},
    ],
}

items = [
    key_item("w55_hall_slate", "Slate from the Hall Roof", "A spare Caithness slate from the first batch for the hall roof, signed on the back in pencil by about forty people, one of whom drew a very small turbine."),
    key_item("w55_hall_feather", "Greenshank Feather", "A grey-brown feather, moulted and not taken, found on the ridge by the warden. 'They were here again this year,' says the card."),
    key_item("w55_hall_minute", "A Page of Hall Minutes", "The minute of the meeting that moved the turbines. Four people abstained, three said 'aye' and one wrote 'under protest' and then crossed it out."),
    {"id": "w55_peat_cap", "name": "Peat-brown bunnet", "kind": "wear", "slot": "hat", "price": 300,
     "desc": "A Scottish flat cap, a bunnet, in the brown of peat water. It sheds the rain on a wet hill, which is the whole of its argument.",
     "look": {"hat": "flat_cap", "palette": {"hat": "#4a3a28", "accent2": "#2a2218"}}},
]

add_items(items)
set_quests("scotland", [quest])
add_script(PUB, "w55s_isobel", isobel)
add_script(PUB, "w55s_calum", calum)
add_script(PUB, "w55s_kirsty", kirsty)
add_script(PUB, "w55s_postie", postie)
add_script(PUB, "w55s_tech", tech)
prepend(CENTRE, "flows_warden", "scotland", warden)

add_npc(PUB, {"id": "w55s_isobel", "name": "Isobel Mackay", "sprite": "villager_5", "x": 4, "y": 3, "facing": "right", "script": "w55s_isobel"})
add_npc(PUB, {"id": "w55s_calum", "name": "Calum Ross", "sprite": "farmer", "x": 11, "y": 2, "facing": "down", "script": "w55s_calum"})
add_npc(PUB, {"id": "w55s_kirsty", "name": "Kirsty", "sprite": "villager_6", "x": 2, "y": 4, "facing": "right", "script": "w55s_kirsty", "hide_if": P + "world_object"})
add_npc(PUB, {"id": "w55s_postie", "name": "Postie", "sprite": "villager_1", "x": 4, "y": 5, "facing": "right", "script": "w55s_postie", "show_if": P + "decided", "hide_if": P + "done"})
add_npc(PUB, {"id": "w55s_tech", "name": "Technician", "sprite": "steelworker", "x": 9, "y": 6, "facing": "left", "script": "w55s_tech", "show_if": P + "world_built"})
print("scotland written")
