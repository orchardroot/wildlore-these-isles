"""Wave 55 stories: Wales. 'The Keys to Bethania' (the Rhondda). python3 tools/zones/w55_stories_wales.py"""
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from w55_stories_lib import *  # noqa

P = "q_stories_wales_"
CHAPEL, INST, HOME = "rhondda_chapel", "rhondda_institute", "rhondda_home"
WHEN = P + "when"
RIPE = "later_%s_3" % WHEN


def pick(n, then, other=None):
    return iff(P + "pick", then, other, eq=n)


eirlys = [
    iff(P + "done", [
        iff(P + "pick_sell", [say("Eirlys", "I walked past on Sunday and there were curtains in the windows. Real curtains. It is a strange thing, seeing your chapel have a front door with a number on it.")]),
        iff(P + "pick_keep", [say("Eirlys", "Nine of us and a rota and a hundred and forty pounds a month in the tin. We are not dead. We are not well, either. But we sang on Sunday and the roof held.")]),
        iff(P + "pick_split", [say("Eirlys", "The flats are full and the chapel is still a chapel. I have noticed that nobody is entirely happy, which I have decided to take as a good sign.")]),
    ], [
        iff(P + "decided", [
            pick(0, [say("Eirlys", "Sell it, then. To a lad who sat in the third pew on a Sunday afternoon and complained about the sermon. I will tell the members what you said.")]),
            pick(1, [say("Eirlys", "Keep it. Nine of us and a roof. I will tell the members what you said, and then I will go and look for a ladder.")]),
            pick(2, [say("Eirlys", "Sell the back and keep the front. Well. I would have liked to have thought of it. I will tell the members.")]),
            say("Eirlys", "The post for the terrace comes to Bryn Terrace, where the kettle always is. Word will come, one way or another."),
        ], [
            iff(P + "started", [
                iff(P + "kieran", [
                    iff(P + "elwyn", [
                        say("Eirlys", "Well? You have heard Kieran and you have heard Elwyn. We are four to four, and I am the ninth, and I cannot say, because I have been secretary for thirty-one years and they would say I only wanted what I wanted."),
                        choice("What do you tell Eirlys?", ["Sell it to Kieran, for flats", "Keep it, and raise the money", "Sell the schoolroom, keep the chapel", "I need to think"], P + "pick"),
                        pick(0, [
                            setf(P + "pick_sell"), setf(P + "decided"), stamp(WHEN),
                            say("Eirlys", "Flats. Six of them, and the front kept as it is. And the choir in a cold hall, and the organ in a van."),
                            say("Eirlys", "I will tell the members. Come to the terrace for the post when it is done."),
                        ]),
                        pick(1, [
                            setf(P + "pick_keep"), setf(P + "decided"), stamp(WHEN),
                            say("Eirlys", "Keep it. Nine of us, a tin and a roof with a hole in it. And not one person under fifty to hold the ladder."),
                            say("Eirlys", "I will tell the members. Come to the terrace for the post when it is done."),
                        ]),
                        pick(2, [
                            setf(P + "pick_split"), setf(P + "decided"), stamp(WHEN),
                            say("Eirlys", "The old Sunday school at the back to Kieran, for two flats, and the chapel for the choir. The teas move into the vestry, and the choir stops at nine, or the flats will complain."),
                            say("Eirlys", "I will tell the members. Come to the terrace for the post when it is done."),
                        ]),
                        pick(3, [say("Eirlys", "Take your time. The roof will not, but you can.")]),
                    ], [say("Eirlys", "Elwyn Prosser is at the front, when he is not in the pulpit pretending it is a podium. Ask him what the choir would lose.")]),
                ], [say("Eirlys", "Kieran Rees. He is over at the Institute, in the reading room, with his plans. Hear him out. He is not what you think.")]),
            ], [
                say("Eirlys", "Eirlys Bevan, secretary. Mind the third pew, it complains."),
                say("Eirlys", "There are nine of us on a Sunday now. In my mother's day there were four hundred, and a gallery, and a sermon that went on until the beef burned. The roof needs more than we have, and so does the boiler, and so do I."),
                say("Eirlys", "A builder has made us an offer. It is a good one, for flats. The members meet on Sunday and we are four against four, and I am the ninth. Would you hear everyone out and tell me what you think? You are nobody's cousin."),
                setf(P + "started"),
            ]),
        ]),
    ]),
]

kieran = [
    iff(P + "done", [
        iff(P + "pick_sell", [say("Kieran", "Six flats. Four are let to people who grew up within a mile. One is mine. I lie awake sometimes and think about the pew I sat in, and then I go to sleep in the room that has the pulpit's window.")]),
        iff(P + "pick_keep", [say("Kieran", "I put my plans in a drawer. They are still in the drawer. If the roof fund ever gives up, I will still be here, and I will still not be the villain.")]),
        iff(P + "pick_split", [say("Kieran", "Two flats in the old Sunday school and both let. I did them for less than I would have done the lot. Do not tell the bank.")]),
    ], [
        iff(P + "decided", [say("Kieran", "Whatever Eirlys decides, I will be civil. It is only a building. It is only the building where I was baptised, but it is only a building.")], [
            iff(P + "started", [
                iff(P + "kieran", [say("Kieran", "Tell her I would sooner it was kept, if it could be. And tell her I cannot do it for love.")], [
                    say("Kieran", "Kieran Rees. I do conversions. I was in Bethania's Sunday school until I was fourteen, and I did not like it much, and I would rather like it not to fall in."),
                    say("Kieran", "Six flats, kept in the old shell with the front left as it is. I live in the valley and I know what it costs to rent here, and what it costs to buy. The lads I went to school with are in Cardiff because there was nothing for them here."),
                    say("Kieran", "The chapel is not going to be a chapel for much longer: you can see it from the road. The choice is flats, or the roof coming in. Nobody is paying for the third thing."),
                    say("Kieran", "I would give the choir a room. Not the room, a room. I know that is not the same."),
                    setf(P + "kieran"),
                ]),
            ], [
                say("Kieran", "Sorry, plans. Do not mind the drawings. I have been told to be gentle with the margins."),
            ]),
        ]),
    ]),
]

elwyn = [
    iff(P + "done", [
        iff(P + "pick_sell", [say("Elwyn", "We rehearse in the Institute now. It is cold, and the acoustic is a wardrobe. We have sung worse, and in worse, and not often.")]),
        iff(P + "pick_keep", [say("Elwyn", "We sang on a scaffold in March. The altos said it was the best acoustic yet, which I did not take as a compliment.")]),
        iff(P + "pick_split", [say("Elwyn", "We stop at nine, and Kieran's tenants send down tea on Thursdays. It is not what I would have chosen, and it is better than I deserve.")]),
    ], [
        iff(P + "started", [
            iff(P + "elwyn", [], [
                iff(P + "kieran", [
                    say("Elwyn", "Eirlys has had you in the vestry, has she? Then I know what you will ask. Sit down. Not on the third pew."),
                    say("Elwyn", "A male voice choir is not a thing you can move into a hall. It is the roof. The sound goes up, comes back and arrives at the back row as a chord. Forty men in a cold hall sing at the floor."),
                    say("Elwyn", "I am not a deacon and I do not decide the sale. I would only say: the choir is the best argument for the chapel, and Kieran is the best argument for the valley, and I like him, and I will not forgive either of you."),
                    say("Elwyn", "We would manage. The hymns survive anything. I would just like it to be said that I minded."),
                    setf(P + "elwyn"),
                    END,
                ], [say("Elwyn", "About the chapel? Hear Kieran at the Institute first. Then come and ask me what a choir loses. I will have a better answer if you have heard what a lad needs.")]),
            ]),
        ]),
    ]),
]

postman = [
    iff(P + "done", [say("Postman", "That was your letter. Terrace post is the only post that stops for tea, by agreement.")], [
        when(RIPE, [
            say("Postman", "There you are. A letter for you, care of Bryn Terrace. Mrs Pugh's sister said I was to watch for you."),
            iff(P + "pick_sell", [say("", t) for t in [
                "Dear {player}. It is done. Six flats, and the front of Bethania as it always was, with the date over the door and a number beside it.",
                "Four are let to people from the valley, to folk who grew up within a mile of here. One is Kieran's. He has asked me to say he does not sleep well, and that is the closest I have had to an apology from a builder.",
                "The choir rehearses in the Institute. The organ went to a chapel in Swansea that wanted it. I went to hear it. It sounded the same, which was somehow worse.",
                "I am glad, and I am not glad. I have noticed that is a thing a person can be, at my age. Come for a cup of tea. E.B.",
            ]] + [give("w55_bethania_key"), setf(P + "world_sell")]),
            iff(P + "pick_keep", [say("", t) for t in [
                "Dear {player}. We kept it. Nine of us, and a tin, and a rota that has been written on the back of an order of service because nobody could find paper.",
                "We have raised enough for the roof over the vestry end. The rest is a thermometer in the porch that Mrs Pugh's sister painted. It is at forty per cent and has not moved since Easter.",
                "Elwyn says the choir sings better under scaffolding. I think he is being kind, and I think he knows I know.",
                "I will not say we were right. I will say the door is open on Sundays and there is a hymn at eleven. E.B.",
            ]] + [give("w55_bethania_thermometer"), setf(P + "world_keep")]),
            iff(P + "pick_split", [say("", t) for t in [
                "Dear {player}. Done. Two flats in the old Sunday school and the chapel still a chapel. The money did the roof.",
                "Both flats are let, to young couples from the valley. One of them has a baby, and on Thursday evenings the baby and the choir are in a competition. The choir stops at nine. The baby does not.",
                "The teas have moved into the vestry and everyone says they miss the old schoolroom. They mean they miss being twenty.",
                "I have noticed that nobody is entirely happy, and I have decided to take it as a good sign. E.B.",
            ]] + [give("w55_bethania_keys"), setf(P + "world_split")]),
            say("Postman", "There was a parcel under my arm, tied with string: a wool shawl from the vestry cupboard, which Eirlys says has outlived three ministers. And a recipe on the back of a hymn sheet, in a very upright hand. Welsh cakes. The chapel teas, it says. She wants you to have it."),
            recipe("welsh_cakes"),
            give("welsh_wool_shawl"),
            setf(P + "done"),
        ], [
            say("Postman", "Nothing yet. These things take a few days to get down the valley, and the members have to meet. Try after a night's sleep."),
        ]),
    ]),
]

chorister = [
    say("Chorister", "We rehearse here now, Thursdays and Saturdays. The Institute has a good heater and an acoustic like a wardrobe."),
    say("Chorister", "Elwyn says we will get used to it. Elwyn has said that about a great many things, and he has been right about most."),
]
ladder = [
    say("Volunteer", "Roof. I am the one who holds the ladder. I am sixty-eight, so that tells you where the next generation is."),
    say("Volunteer", "The thermometer in the porch says forty per cent. I say that is rounding."),
]
father = [
    say("Young father", "We have the flat at the back, the old Sunday school. The baby sleeps through the sermon, which I am told is a first for that room."),
    say("Young father", "The choir stops at nine. I thank them every Thursday. I do not say it out loud."),
]

quest = {
    "id": "stories_wales",
    "title": "The Keys to Bethania",
    "region": "stories_wales",
    "town": "rhondda",
    "giver": "Eirlys Bevan, at Bethania Chapel",
    "summary": "A Rhondda chapel with nine members has an offer from a local builder to turn it into flats. The choir wants to keep singing there. Hear everyone, then tell the secretary what you think.",
    "start_flag": P + "started",
    "steps": [
        {"flag": P + "kieran", "text": "Hear Kieran Rees, the builder, at the Miners' Institute.", "zone": INST},
        {"flag": P + "elwyn", "text": "Ask Elwyn Prosser what the choir would lose.", "zone": CHAPEL},
        {"flag": P + "decided", "text": "Tell Eirlys what you think the members should do.", "zone": CHAPEL},
        {"flag": P + "done", "text": "Wait for word. The terrace post comes to Bryn Terrace, a night's sleep or a day later.", "zone": HOME},
    ],
    "done_flag": P + "done",
    "reward": "A Welsh wool shawl, a keepsake of how it went, and the chapel teas' Welsh cake recipe.",
    "endings": [
        {"flag": P + "pick_sell", "text": "Bethania became six flats, four let to people from the valley, and the choir moved to the Miners' Institute."},
        {"flag": P + "pick_keep", "text": "Bethania stayed a chapel: nine members, a roof fund at forty per cent and a choir singing under scaffolding."},
        {"flag": P + "pick_split", "text": "The old schoolroom became two flats and the money mended the roof. The chapel is still a chapel, and the choir stops at nine."},
    ],
}

items = [
    key_item("w55_bethania_key", "Bethania Door Key", "A black iron chapel key, heavy as a spanner. The chapel has a new key now, brass, for the flats. This one hung in the vestry for about a century."),
    key_item("w55_bethania_thermometer", "Roof Fund Thermometer Card", "A painted card thermometer from the chapel porch, red up to forty per cent. Mrs Pugh's sister did the lettering. Someone has added a very small ladder."),
    key_item("w55_bethania_keys", "Two Keys on One Ring", "One brass, one iron, on a loop of string. Flats at the back, chapel at the front. The label says 'do not lose either'."),
]

add_items(items)
set_quests("wales", [quest])
add_script(CHAPEL, "w55w_eirlys", eirlys)
add_script(INST, "w55w_kieran", kieran)
add_script(HOME, "w55w_postman", postman)
prepend(CHAPEL, "rhn_conductor", "wales", elwyn)

add_script(INST, "w55w_chorister", chorister)
add_script(CHAPEL, "w55w_ladder", ladder)
add_script(CHAPEL, "w55w_father", father)
add_npc(INST, {"id": "w55w_chorister", "name": "Chorister", "sprite": "choir_singer", "x": 6, "y": 5, "facing": "down", "script": "w55w_chorister", "show_if": P + "world_sell"})
add_npc(CHAPEL, {"id": "w55w_ladder", "name": "Volunteer", "sprite": "villager_3", "x": 9, "y": 6, "facing": "left", "script": "w55w_ladder", "show_if": P + "world_keep"})
add_npc(CHAPEL, {"id": "w55w_father", "name": "Young father", "sprite": "villager_6", "x": 11, "y": 4, "facing": "left", "script": "w55w_father", "show_if": P + "world_split"})
add_npc(CHAPEL, {"id": "w55w_eirlys", "name": "Eirlys Bevan", "sprite": "villager_4", "x": 3, "y": 6, "facing": "right", "script": "w55w_eirlys"})
add_npc(INST, {"id": "w55w_kieran", "name": "Kieran Rees", "sprite": "villager_1", "x": 10, "y": 6, "facing": "left", "script": "w55w_kieran"})
add_npc(HOME, {"id": "w55w_postman", "name": "Postman", "sprite": "rail_guard", "x": 8, "y": 5, "facing": "up", "script": "w55w_postman", "show_if": P + "decided", "hide_if": P + "done"})
print("wales written")
