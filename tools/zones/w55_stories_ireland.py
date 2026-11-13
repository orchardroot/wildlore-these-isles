"""Wave 55 stories: Ireland. 'Sell the Pub' (Gweedore). python3 tools/zones/w55_stories_ireland.py"""
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from w55_stories_lib import *  # noqa

P = "q_stories_ireland_"
PUB = "gweedore_pub"
WHEN = P + "when"
RIPE = "later_%s_3" % WHEN


def pick(n, then, other=None):
    return iff(P + "pick", then, other, eq=n)


# --- Pádraig, behind the bar: after his own welcome ----------------------------------------------
padraig = [
    iff(P + "decided", [
        pick(0, [say("Pádraig", "Niamh and Ciarán, then. Food in the day and the session on a Tuesday. I will tell them, and I will tell them they are mad, and I will wish them well.")]),
        pick(1, [say("Pádraig", "The co-op. Bríd will be unbearable about it. I will tell them tonight, and then I will go home and not sleep.")]),
        pick(2, [say("Pádraig", "Orla. I will tell her yes. It is the price, and it is January, and it is that the lights will be on. I know what that sounds like.")]),
        say("Pádraig", "The post for this end of the parish comes in here. I will make sure it does. Word will come, one way or another."),
    ], [
        iff(P + "started", [
            iff(P + "niamh", [
                iff(P + "brid", [
                    iff(P + "orla", [
                        say("Pádraig", "Well? You have heard the three of them. Tell me straight, a chara. Who do I sell to?"),
                        choice("Who should Pádraig sell to?", ["Niamh and Ciarán, to run it as a pub with food", "The community co-op", "Orla, the hotelier", "I need to think"], P + "pick"),
                        pick(0, [setf(P + "pick_couple"), setf(P + "decided"), stamp(WHEN)]),
                        pick(1, [setf(P + "pick_coop"), setf(P + "decided"), stamp(WHEN)]),
                        pick(2, [setf(P + "pick_hotel"), setf(P + "decided"), stamp(WHEN)]),
                        pick(3, [say("Pádraig", "Take your time. The licence will not run off, but I might.")]),
                        iff(P + "decided", [
                            say("Pádraig", "I will tell her tonight. Slán go fóill. Come back for the post when it is settled."),
                        ]),
                    ], [say("Pádraig", "Orla is the hotelier, over at the table in the corner. Hear her out too.")]),
                ], [say("Pádraig", "Bríd is at the table by the fire. She is not shy. You will hear her before you see her.")]),
            ], [say("Pádraig", "Niamh is at the table by the door with the high chair. Start with her, so as not to be rude.")]),
        ], [
            say("Pádraig", "Pádraig Ó Gallchóir. I am seventy-one, and my father pulled pints behind this bar, and so did his. The youngest of my regulars is fifty-three."),
            say("Pádraig", "The licence is the only valuable thing I own, and I cannot hold on to it any more. I have three people wanting it, each of them honest, each of them a different pub."),
            say("Pádraig", "I would sooner ask someone who is not selling, buying or drinking. Would you hear them all out, and tell me what you think?"),
            setf(P + "started"),
        ]),
    ]),
]

niamh = [
    iff(P + "decided", [say("Niamh", "Whatever Pádraig decides, we will be civil, and we will have a soup on. It is the one thing I can promise in advance.")], [
        iff(P + "started", [
            iff(P + "niamh", [say("Niamh", "Tell him we would be good to the place. Tell him we have a baby and a bank manager and no plan B.")], [
                say("Niamh", "Niamh Ní Fhearraigh. Ciarán cooks in a restaurant kitchen in Letterkenny five days a week and he hates it. We came home so our daughter could grow up in Irish."),
                say("Niamh", "We would do food, lunches and the early evening, and a proper kitchen. We would keep the Tuesday session and the Irish on the quiz night. The snug would have to go to make room, and the telly with it."),
                say("Niamh", "We need a loan to do it. If the January trade does not come, the bank gets a pub, and Pádraig gets a letter. I would rather you knew that now."),
                setf(P + "niamh"),
            ]),
        ], [say("Niamh", "Sorry, I am doing the sums on a napkin, and the napkin is winning.")]),
    ]),
]

brid = [
    iff(P + "decided", [say("Bríd", "Whatever he decides, the co-op is still the co-op. It will be a shop or a hall or a pub, and we will take what the parish gives us.")], [
        iff(P + "started", [
            iff(P + "brid", [say("Bríd", "Tell him it would not be Pádraig's, and it would not be anybody's, and that is the whole point of it.")], [
                say("Bríd", "Bríd Nic Giolla Bhríde. I run the shop and chair the community co-op, and I will tell you, no one ever made a living out of a pub in this part of the parish. It makes a place, which is not the same."),
                say("Bríd", "Shares in the parish, a rota of volunteers, open four nights and the Sunday session. We could not pay him what the hotel would, and we would pay it in instalments."),
                say("Bríd", "The pub stays ours. If it fails it fails in front of everyone. If it works there will be a pub for the next fifty years, whoever is behind the bar."),
                setf(P + "brid"),
            ]),
        ], [say("Bríd", "I am counting shares in my head. Do not ask me to stop, I will lose my place.")]),
    ]),
]

orla = [
    iff(P + "decided", [say("Orla", "I wish him well whatever he does. I would only say that the offer is not an insult, and a pub in January with the lights on is not nothing.")], [
        iff(P + "started", [
            iff(P + "orla", [say("Orla", "Tell him the price is the price, and the pub stays a pub. I would sooner be told no kindly than yes unkindly.")], [
                say("Orla", "Orla Gallagher. I have a small hotel in Letterkenny and a bit of capital, and I will not pretend I do not want a second place. Everybody does."),
                say("Orla", "I would pay the full price, in one go. Six rooms in the loft, the bar kept as a bar and open every day of the year, with staff from the parish. I would hire a manager from here."),
                say("Orla", "It would not be Pádraig's. It would be open in January. I would say those are different things, and both of them are real."),
                setf(P + "orla"),
            ]),
        ], [say("Orla", "Just passing through, with a notebook. I am told it is a very good pint.")]),
    ]),
]

LETTERS = {
    "couple": [
        "A chara. Ciarán has put in a kitchen, and the smell of onions has got into the old curtains, which is not the worst thing to happen to them. The snug is gone. The lads miss it, and the high chair has gone where the snug was, which is a kind of justice.",
        "The session is still on a Tuesday. The bank manager came in for his dinner, which Niamh says is the right sort of pressure.",
        "We will see how January treats them. I sit on the stool by the door and say nothing, like a man who has sold a pub.",
    ],
    "coop": [
        "A chara. They have shares now: three hundred and forty at the last count, and a rota written on the back of the toilet door. They open Thursday to Sunday, and on the other nights the light is off, and I pass it, and it hurts.",
        "The price was less, and I have said nothing about it, and Bríd has said nothing about it, loudly. I go in on the Sunday session. There are more people in it than there ever were when I owned it. I do not know what to do with that.",
        "Come and have a pint. Bring a few coins for the kitty. They will give you a receipt.",
    ],
    "hotel": [
        "A chara. The pub is open every day now, even in January, which I did not think possible. There is a man from Germany asking for a hot whiskey, which I am told is progress.",
        "The rooms are full from May to September and the staff are from the parish, three of them, and one is my niece. Orla paid the price in one go, and my pension is sorted for the first time in a decade.",
        "I would be lying if I said it feels like mine. It never was, I suppose, only mine to keep open. It is open.",
    ],
}

postman = [
    iff(P + "done", [say("Postman", "That was yours. The rest of the parish's post is in the van, and the van is outside the chipper.")], [
        when(RIPE, [
            say("Postman", "There you are. A letter for you, care of the pub. Pádraig said I was to put it in your hand, and not on the bar."),
            iff(P + "pick_couple", [say("", t) for t in LETTERS["couple"]] + [give("w55_snug_latch"), setf(P + "world_couple")]),
            iff(P + "pick_coop", [say("", t) for t in LETTERS["coop"]] + [give("w55_coop_share"), setf(P + "world_coop")]),
            iff(P + "pick_hotel", [say("", t) for t in LETTERS["hotel"]] + [give("w55_last_orders_bell"), setf(P + "world_hotel")]),
            say("Postman", "There was a note folded in with it. A recipe, for boxty, on the back of a beer mat. Pádraig's mother's, it says. She would want the credit."),
            recipe("boxty"),
            give("w55_gaeltacht_shawl"),
            setf(P + "world"),
            setf(P + "done"),
        ], [
            say("Postman", "Nothing yet. A letter from Pádraig takes a few days, and he writes them twice. Try after a night's sleep."),
        ]),
    ]),
]

retired = [
    iff(P + "pick_hotel", [
        say("Pádraig", "I sit here and people bring me a drink and tell me how it was in my day. I tell them it was the same, only emptier."),
        say("Pádraig", "The rooms are full. I never thought I would say a bad word against a full house, and I have not."),
    ], [
        say("Pádraig", "I sit here and people bring me a drink and tell me how it was in my day. I tell them it was the same, only emptier."),
        iff(P + "pick_coop", [say("Pádraig", "I stand behind Tadhg on a Thursday and say nothing. He tells me it is the most expensive nothing he has ever heard.")], [
            say("Pádraig", "Ciarán asks me about the cellar every week. I tell him the cellar is a cellar. He writes it down."),
        ]),
    ]),
]
owner_couple = [
    say("Ciarán", "A bowl of soup? Pádraig's mother's recipe, with a few liberties. He told me which ones, in detail."),
    say("Ciarán", "I miss the kitchen in Letterkenny about as much as I miss a toothache. I like this one. It has a window."),
]
owner_coop = [
    say("Tadhg", "I do Thursdays on the rota. I have never poured a pint in my life, so Pádraig comes in and stands behind me and says nothing."),
    say("Tadhg", "There are three hundred and forty of us who own this, and none of us can find the key. It is the best pub I have ever been in."),
]
owner_hotel = [
    say("Sinéad", "Duty manager. The hot whiskeys are a disgrace to nobody, the rooms are full, and the old regulars have the corner by the fire. That was in the contract, I am told, and Orla does not break a contract."),
    say("Sinéad", "My mother says it is not Pádraig's pub. I say it is open. We are both right, and one of us pays more tax."),
]

quest = {
    "id": "stories_ireland",
    "title": "Sell the Pub",
    "region": "stories_ireland",
    "town": "gweedore",
    "giver": "Pádraig Ó Gallchóir, behind the bar",
    "summary": "Pádraig is seventy-one and wants to sell the pub. A young couple, the community co-op and a hotelier each want it, and each would run it differently. Hear them all, then tell him straight.",
    "start_flag": P + "started",
    "steps": [
        {"flag": P + "niamh", "text": "Hear Niamh, by the door with the high chair.", "zone": PUB},
        {"flag": P + "brid", "text": "Hear Bríd of the community co-op, by the fire.", "zone": PUB},
        {"flag": P + "orla", "text": "Hear Orla the hotelier, in the corner.", "zone": PUB},
        {"flag": P + "decided", "text": "Tell Pádraig who you think should buy.", "zone": PUB},
        {"flag": P + "done", "text": "Wait for word. The parish post comes in at the pub, a night's sleep or a day later.", "zone": PUB},
    ],
    "done_flag": P + "done",
    "reward": "A Donegal tweed shawl, a keepsake from the pub, and Pádraig's mother's boxty recipe.",
    "endings": [
        {"flag": P + "pick_couple", "text": "Niamh and Ciarán took the pub on as a pub with a kitchen. The snug is gone, the Tuesday session stays, and the first January decides it."},
        {"flag": P + "pick_coop", "text": "The community co-op bought the pub: three hundred and forty shares and a rota. It opens four nights, and the Sunday session is fuller than it ever was."},
        {"flag": P + "pick_hotel", "text": "Orla's hotel took the pub on as a bar with six rooms. It is open every day of the year, with local staff, and it is not Pádraig's any more."},
    ],
}

items = [
    key_item("w55_snug_latch", "The Snug Latch", "A brass latch off the snug door, which has gone. Pádraig kept it. 'For the next one who wants a bit of privacy,' says the label, in biro."),
    key_item("w55_coop_share", "Co-op Share No. 1", "A share certificate in a pub co-op, number one of three hundred and forty. The cheque stub has been framed. Pádraig has signed the back, and added 'cheap at the price'."),
    key_item("w55_last_orders_bell", "The Last Orders Bell", "A small brass bell that rang last orders for sixty years. The new management has a clock. Pádraig took the bell, and then, kindly, lent it to you."),
    {"id": "w55_gaeltacht_shawl", "name": "Donegal tweed shawl", "kind": "wear", "slot": "neck", "price": 900,
     "desc": "A shawl woven from Donegal tweed, the flecks, or neps, spun into the yarn in bright dots. It has been round more shoulders in more wet pubs than anyone has counted.",
     "look": {"accessories": ["shawl"], "palette": {"accent": "#6a7a5a", "accent2": "#c8a060"}}},
]

add_items(items)
set_quests("ireland", [quest])
add_script(PUB, "w55i_niamh", niamh)
add_script(PUB, "w55i_brid", brid)
add_script(PUB, "w55i_orla", orla)
add_script(PUB, "w55i_postman", postman)
add_script(PUB, "w55i_retired", retired)
add_script(PUB, "w55i_couple", owner_couple)
add_script(PUB, "w55i_coop", owner_coop)
add_script(PUB, "w55i_hotel", owner_hotel)
append(PUB, "gp_barman", "ireland", padraig)

add_npc(PUB, {"id": "w55i_brid", "name": "Bríd", "sprite": "villager_4", "x": 3, "y": 3, "facing": "right", "script": "w55i_brid"})
add_npc(PUB, {"id": "w55i_niamh", "name": "Niamh", "sprite": "villager_2", "x": 10, "y": 7, "facing": "left", "script": "w55i_niamh"})
add_npc(PUB, {"id": "w55i_orla", "name": "Orla", "sprite": "shopkeeper", "x": 13, "y": 4, "facing": "left", "script": "w55i_orla"})
add_npc(PUB, {"id": "w55i_postman", "name": "Postman", "sprite": "rail_guard", "x": 2, "y": 5, "facing": "right", "script": "w55i_postman", "show_if": P + "decided", "hide_if": P + "done"})
add_npc(PUB, {"id": "w55i_retired", "name": "Pádraig", "sprite": "villager_6", "x": 1, "y": 4, "facing": "right", "script": "w55i_retired", "show_if": P + "world"})
add_npc(PUB, {"id": "w55i_couple", "name": "Ciarán", "sprite": "shopkeeper", "x": 5, "y": 1, "facing": "down", "script": "w55i_couple", "show_if": P + "world_couple"})
add_npc(PUB, {"id": "w55i_coop", "name": "Tadhg", "sprite": "villager_1", "x": 6, "y": 1, "facing": "down", "script": "w55i_coop", "show_if": P + "world_coop"})
add_npc(PUB, {"id": "w55i_hotel", "name": "Sinéad", "sprite": "villager_5", "x": 4, "y": 1, "facing": "down", "script": "w55i_hotel", "show_if": P + "world_hotel"})
gate_npc(PUB, "gp_barman", hide_if=P + "world")
print("ireland written")
