"""Wave 55 stories: Northern Ireland. 'The Counter' (Bushmills). python3 tools/zones/w55_stories_ni.py"""
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from w55_stories_lib import *  # noqa

P = "q_stories_northern_ireland_"
OFFICE, CRAFT = "bushmills_postoffice", "bushmills_craftshop"
WHEN = P + "when"
RIPE = "later_%s_3" % WHEN


def pick(n, then, other=None):
    return iff(P + "pick", then, other, eq=n)


# --- Maeve Hanna, the postmaster (after her own welcome) ---------------------------------------------
maeve = [
    iff(P + "decided", [
        pick(0, [say("Maeve", "Margaret's ladies, then. They will do it properly or they will do it loudly, and probably both.")]),
        pick(1, [say("Maeve", "Gareth's group. Seven days and a till. I will not pretend it is not a wrench, but there will be someone there at eight in the morning, and that is more than I have managed since 1998.")]),
        pick(2, [say("Maeve", "Joanne's spare room, then. Tuesday to Saturday, a hatch and a chair. Better a hatch than a shutter.")]),
        say("Maeve", "The post for this end of the town comes through the van, and the van comes here. Word will come, one way or another."),
    ], [
        iff(P + "started", [
            iff(P + "margaret", [
                iff(P + "gareth", [
                    iff(P + "joanne", [
                        say("Maeve", "Well? You have heard the three of them. Tell me straight. I will be passing whoever it is every day of my life."),
                        choice("What do you tell Maeve?", ["Hand it to Margaret's volunteers", "Hand it to the convenience group", "Move the counter into Joanne's craft shop", "I need to think"], P + "pick"),
                        pick(0, [setf(P + "pick_community"), setf(P + "decided"), stamp(WHEN)]),
                        pick(1, [setf(P + "pick_franchise"), setf(P + "decided"), stamp(WHEN)]),
                        pick(2, [setf(P + "pick_hosted"), setf(P + "decided"), stamp(WHEN)]),
                        pick(3, [say("Maeve", "Take your time. The counter will not, but you can.")]),
                        iff(P + "decided", [say("Maeve", "I will tell them tonight. Come back for the post when it is settled.")]),
                    ], [say("Maeve", "Joanne has the craft shop across the green. She has a proposal and a very good kettle.")]),
                ], [say("Maeve", "Gareth is here in the corner with a lanyard. Hear him out. He is not what you think either.")]),
            ], [say("Maeve", "Margaret is here by the table, with her notes. Hear her first. She will be offended if you do not.")]),
        ], [
            say("Maeve", "Maeve Hanna. I have been at this counter for thirty-eight years. I know who gets what pension and which dog belongs to whom."),
            say("Maeve", "I am retiring at Easter, and the counter goes with me unless somebody takes it on. It is the only reason half the back roads come into town. If it shuts, the shop shuts with it, and so, in time, does the rest."),
            say("Maeve", "Three people have asked for it, each with a different idea. I cannot choose among friends. Would you hear them out and tell me what you think?"),
            setf(P + "started"),
        ]),
    ]),
]

margaret = [
    iff(P + "decided", [say("Margaret", "Whatever Maeve decides, I will have the kettle on. That is the whole of my policy.")], [
        iff(P + "started", [
            iff(P + "margaret", [say("Margaret", "Tell her we are ready, and we are scared, and we are both of those at the same time.")], [
                say("Margaret", "Margaret Cuthbert. I taught for thirty-four years and I have never once been short of volunteers for anything involving a biscuit."),
                say("Margaret", "We could run the counter ourselves: a rota of eleven, three mornings a week, in this same room. The grant would cover the setup. The shop shelves could not stay, I will be honest. You would buy your milk across the road."),
                say("Margaret", "Its strength is that it belongs to the town. Its weakness is that it belongs to eleven people, and eleven people get colds. If the grant does not renew, we go."),
                setf(P + "margaret"),
            ]),
        ], [say("Margaret", "I am reading the form. It has a question about 'sustainability', and I intend to answer it honestly.")]),
    ]),
]

gareth = [
    iff(P + "decided", [say("Gareth", "Whatever Maeve decides, I wish her a long retirement. I mean that. Nobody here has ever said I did not.")], [
        iff(P + "started", [
            iff(P + "gareth", [say("Gareth", "Tell her I will not pretend we are the same as her. We would be there when she is not. That is the only promise I can make that I can keep.")], [
                say("Gareth", "Gareth Boyd. I look after a group of convenience stores across the north coast, and I will say it plainly: I am here to make an offer, not a speech."),
                say("Gareth", "We would take the counter and the shop together. Open seven till ten, seven days. The counter stays; the staff are on a rota, with a uniform, and three jobs for people from the town. The building stays Maeve's to rent."),
                say("Gareth", "It would be a shop first and a counter second. The counter would not close for lunch or a funeral. It might not know your dog's name. I would train them to try."),
                setf(P + "gareth"),
            ]),
        ], [say("Gareth", "Sorry, lanyard. I am told it looks officious. It is only so they know where I am.")]),
    ]),
]

joanne = [
    iff(P + "decided", [say("Joanne", "Whatever Maeve decides, the kettle is still on. I am only the woman with the spare room and a very good cake tin.")], [
        iff(P + "started", [
            iff(P + "joanne", [say("Joanne", "Tell her I will keep the hatch warm, and the chair is better than the one she has.")], [
                say("Joanne", "Joanne Hill. I have the craft shop across the green, and I have a spare room that does nothing but hold tea towels."),
                say("Joanne", "I could host the counter in it: a hatch, a chair, Tuesday to Saturday ten till three. People would queue past the tea towels, and I am not stupid, I know that is good for me. It is also the only way I can afford to take it on."),
                say("Joanne", "No Mondays and no evenings. I cannot do more than five days and still be a craft shop. Someone will lose out, and I would like to know it will not be me alone."),
                setf(P + "joanne"),
            ]),
        ], [say("Joanne", "Just looking at the premises. The light in here is lovely and the radiator is a crime.")]),
    ]),
]

LETTERS = {
    "community": [
        "Dear {player}. The ladies run it Tuesday, Thursday and Saturday mornings. Margaret keeps the rota in a biscuit tin and the tin has not been wrong yet.",
        "The shop shelves went, and you buy your milk across the road. One week in March the cover fell through and the shutter stayed down. The whole street came and stood about in the wet, and somebody put a note on the door: 'Back at 2'. They were.",
        "Mr Ferris comes every Thursday at ten sharp, and has done for a decade, and is not about to change for a rota. I am told the counter is warmer than it was. I would not have believed that.",
    ],
    "franchise": [
        "Dear {player}. It is open seven days, eight hours, in bright light, and the counter and the till sit side by side. Three girls from the town have jobs. The parcels come on time. I never could say that.",
        "Mr Ferris says the new lad is very civil and does not know his dog's name. I said give him time. I said it as a person who took thirty-eight years.",
        "It is better. It is not the same, and it was never going to be. I went in on Saturday for a stamp I did not need, and nobody noticed, and that was the worst of it.",
    ],
    "hosted": [
        "Dear {player}. The counter is a hatch at the back of Joanne's, with a chair, and the queue sometimes goes out the door past the tea towels. It is open Tuesday to Saturday.",
        "On Mondays nothing is posted anywhere in the town, and a number of people have taken to treating Tuesday as the new Monday. It is not a catastrophe. It is a rearrangement.",
        "The craft shop has had its best summer. Joanne asked me to say that, and she asked me not to say it too loudly. I have said it quietly, to you.",
    ],
}

postman = [
    iff(P + "done", [say("Postman", "That was your letter. I am the last to know anything in this town, and I deliver the news.")], [
        when(RIPE, [
            say("Postman", "There you are. A letter for you, in Maeve's own hand. I was told not to leave it with anyone else."),
            iff(P + "pick_community", [say("", t) for t in LETTERS["community"]] + [give("w55_counter_tin"), setf(P + "world_community")]),
            iff(P + "pick_franchise", [say("", t) for t in LETTERS["franchise"]] + [give("w55_counter_scales"), setf(P + "world_franchise")]),
            iff(P + "pick_hosted", [say("", t) for t in LETTERS["hosted"]] + [give("w55_counter_sign"), setf(P + "world_hosted")]),
            say("Postman", "There was a note in the envelope. A recipe, on the back of a pension form that has been well used. Her soda farls. She said they would see you right on a long walk."),
            recipe("soda_farl"),
            give("w55_ulster_cardigan"),
            setf(P + "world"),
            setf(P + "done"),
        ], [
            say("Postman", "Nothing yet. Maeve writes by hand, and she writes it twice. Try after a night's sleep."),
        ]),
    ]),
]

retired = [
    say("Maeve", "I come in every week for a stamp I do not need. Nobody has noticed. I think that is the point of retirement."),
    iff(P + "pick_community", [say("Maeve", "Margaret has put a cushion on my old chair. I have said nothing, and I have sat in it.")], [
        iff(P + "pick_franchise", [say("Maeve", "They have bright lights and a till, and it is the first time in my life I have seen the corners of this room.")], [
            say("Maeve", "I walk past Joanne's hatch on a Tuesday and wave. Nobody is more surprised than I am by how much I mean it."),
        ]),
    ]),
]
till = [
    say("Caitlin", "Counter and till. Seven till ten, I do the early. Mr Ferris told me his dog's name on Tuesday, and I wrote it on my hand."),
    say("Caitlin", "I am from the town. My mother says that makes it all right. Maeve says it makes it a start."),
]
vol = [
    say("Margaret", "Behind the counter, Tuesday, Thursday and Saturday. I have given the biscuit tin a number. The tin is not amused."),
    say("Margaret", "The rota is eleven names and a space for a twelfth. You are welcome to it. I only say that."),
]
hatch = [
    say("Joanne", "The hatch is a window I cut myself. There is a queue past the tea towels, and the tea towels have never sold so well."),
    say("Joanne", "No Mondays. I have put a sign up. A lot of people have put 'Tuesday' on their calendar, and I have a very small, very guilty smile."),
]

quest = {
    "id": "stories_northern_ireland",
    "title": "The Counter",
    "region": "stories_northern_ireland",
    "town": "bushmills",
    "giver": "Maeve Hanna, at the post counter",
    "summary": "The postmaster at Bushmills retires at Easter, and the counter goes with her unless somebody takes it on. Volunteers, a convenience group and the craft shop each have a plan. Hear them all, then tell her what you think.",
    "start_flag": P + "started",
    "steps": [
        {"flag": P + "margaret", "text": "Hear Margaret Cuthbert, the retired teacher, in the post office.", "zone": OFFICE},
        {"flag": P + "gareth", "text": "Hear Gareth Boyd, from the convenience group.", "zone": OFFICE},
        {"flag": P + "joanne", "text": "Hear Joanne Hill at the craft shop.", "zone": CRAFT},
        {"flag": P + "decided", "text": "Tell Maeve what you think.", "zone": OFFICE},
        {"flag": P + "done", "text": "Wait for word. The post comes through the van and the post office, a night's sleep or a day later.", "zone": OFFICE},
    ],
    "done_flag": P + "done",
    "reward": "An Ulster cardigan, a keepsake of the counter, and Maeve's soda farl recipe.",
    "endings": [
        {"flag": P + "pick_community", "text": "Volunteers took the counter on, three mornings a week from a biscuit tin. The shop shelves are gone, and so far the rota has held."},
        {"flag": P + "pick_franchise", "text": "A convenience group took the counter and the shop. It is open seven days, three people from the town have jobs and the parcels are on time."},
        {"flag": P + "pick_hosted", "text": "The counter moved to a hatch in the back of the craft shop, open Tuesday to Saturday. Mondays are quiet, and the craft shop has had its best summer."},
    ],
}

items = [
    key_item("w55_counter_tin", "The Rota Biscuit Tin", "A shortbread tin with eleven names on the lid in biro, and a twelfth space left blank. Margaret keeps it on the counter and says it has never been wrong."),
    key_item("w55_counter_scales", "The Old Brass Scales", "Maeve's brass parcel scales, with a set of weights that went missing in 1986 and came back in 1991. They are accurate to a gram, and have never been told."),
    key_item("w55_counter_sign", "A Sign: 'Back at 2'", "A hand-lettered card from the shutter of the old counter, the one that went up the week the cover fell through. Underneath, someone has written 'And we were'."),
    {"id": "w55_ulster_cardigan", "name": "Ulster cardigan", "kind": "wear", "slot": "top", "price": 700,
     "desc": "A thick navy cardigan of the kind worn behind counters all over the north coast in January. It is warmer than it looks, and the elbows have been proudly mended.",
     "look": {"accessories": ["aran"], "palette": {"top": "#2a3a5a", "accent": "#d8d0c0", "accent2": "#7a8aa0"}}},
]

add_items(items)
set_quests("northern_ireland", [quest])
add_script(OFFICE, "w55n_margaret", margaret)
add_script(OFFICE, "w55n_gareth", gareth)
add_script(CRAFT, "w55n_joanne", joanne)
add_script(OFFICE, "w55n_postman", postman)
add_script(OFFICE, "w55n_retired", retired)
add_script(OFFICE, "w55n_till", till)
add_script(OFFICE, "w55n_vol", vol)
add_script(CRAFT, "w55n_hatch", hatch)
append(OFFICE, "bush_postmaster", "northern_ireland", maeve)

add_npc(OFFICE, {"id": "w55n_margaret", "name": "Margaret Cuthbert", "sprite": "villager_3", "x": 8, "y": 4, "facing": "left", "script": "w55n_margaret", "hide_if": P + "world"})
add_npc(OFFICE, {"id": "w55n_gareth", "name": "Gareth Boyd", "sprite": "commuter", "x": 2, "y": 3, "facing": "right", "script": "w55n_gareth", "hide_if": P + "world"})
add_npc(CRAFT, {"id": "w55n_joanne", "name": "Joanne Hill", "sprite": "villager_5", "x": 8, "y": 3, "facing": "left", "script": "w55n_joanne", "hide_if": P + "world"})
add_npc(OFFICE, {"id": "w55n_postman", "name": "Postman", "sprite": "rail_guard", "x": 7, "y": 5, "facing": "left", "script": "w55n_postman", "show_if": P + "decided", "hide_if": P + "done"})
add_npc(OFFICE, {"id": "w55n_retired", "name": "Maeve", "sprite": "villager_4", "x": 3, "y": 5, "facing": "right", "script": "w55n_retired", "show_if": P + "world"})
add_npc(OFFICE, {"id": "w55n_till", "name": "Caitlin", "sprite": "villager_6", "x": 5, "y": 3, "facing": "down", "script": "w55n_till", "show_if": P + "world_franchise"})
add_npc(OFFICE, {"id": "w55n_vol", "name": "Margaret", "sprite": "villager_3", "x": 5, "y": 3, "facing": "down", "script": "w55n_vol", "show_if": P + "world_community"})
add_npc(CRAFT, {"id": "w55n_hatch", "name": "Joanne", "sprite": "villager_5", "x": 9, "y": 3, "facing": "left", "script": "w55n_hatch", "show_if": P + "world_hosted"})
gate_npc(OFFICE, "bush_postmaster", hide_if=P + "world")
print("northern ireland written")
