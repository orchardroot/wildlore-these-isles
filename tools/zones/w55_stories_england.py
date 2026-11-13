"""Wave 55 stories: England. 'Who Takes the Moor Farm' (North York Moors). python3 tools/zones/w55_stories_england.py"""
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from w55_stories_lib import *  # noqa

P = "q_stories_england_"
FARM, ROSE, INN = "nym_moorfarm", "nym_rosedale", "nym_moorcock"
WHEN = P + "when"
RIPE = "later_%s_3" % WHEN


def pick(flag, then, other=None):
    return iff(P + "pick", then, other, eq=flag)


# --- Hannah (Moor Farm kitchen) -------------------------------------------------------------
hannah = [
    iff(P + "done", [
        iff(P + "pick_hannah", [
            say("Hannah", "Mind the lamb in the porch. He thinks he lives here, and he is not wrong."),
            say("Hannah", "I do two days a week from the kitchen table for the hospital, and the rest is the hill. It is thin money and thick mud. I would not change it."),
        ], [say("Hannah", "Leeds is fine. The radiator works.")]),
    ], [
        iff(P + "decided", [
            pick(0, [say("Hannah", "He rang me. He ASKED. I have been in the lane for ten minutes shouting at a sheep. Thank you, {player}.")]),
            pick(1, [say("Hannah", "Joe Hartley, then. It is right for the flock, I can see that. Funny how you can agree with something and want to throw a mug at it.")]),
            pick(2, [say("Hannah", "A scheme. Fewer sheep, and Dad keeps his hill. That is not nothing. I would have liked to be asked, mind, but I did not ask either.")]),
        ], [
            iff(P + "started", [
                say("Hannah", "Have you had a word with Dad? He is by the fire pretending not to be nervous. He is bad at it."),
            ], [
                say("Hannah", "Oh, hello. Mind the boots, they are Dad's. I am only home for the weekend. I work in a hospital dispensary in Leeds, so I am used to being asked things, but I have never been asked this."),
                say("Hannah", "The estate wants to know who takes Moor Farm on when the tenancy comes round at lambing. Dad is sixty-seven. He has not said 'Hannah' and I have not said 'me', and the letter has been on the dresser since January."),
                say("Hannah", "I do not know if I want it or if I just cannot bear the alternative. Would you talk to him? You are not family. He might actually listen."),
                setf(P + "started"),
            ]),
        ]),
    ]),
]

# --- Dale (in front of his old script) ----------------------------------------------------------
dale = [
    iff(P + "done", [
        pick(0, [say("Farmer Dale", "Lambing's going better than I let on. She has a way with the ewes. Don't tell her I said.")]),
        pick(1, [say("Farmer Dale", "Joe has the flock and I have the view.")]),
        pick(2, [say("Farmer Dale", "Forty ewes and a clipboard. It is a quiet hill. I find I do not mind it as much as I thought.")]),
    ], [
        iff(P + "decided", [
            pick(0, [say("Farmer Dale", "I have asked her properly. Out loud, in the kitchen, with my hat in my hand. I have not felt that daft since I proposed to her mother.")]),
            pick(1, [say("Farmer Dale", "I have told Joe. The flock goes up the hill in March, on its own two legs, and I shall not watch.")]),
            pick(2, [say("Farmer Dale", "The scheme man is coming in the new year with a clipboard and a flask. I will sign.")]),
            say("Farmer Dale", "The post for this end of the moor waits at the Moorcock. Word will come, one way or another, after lambing."),
            END,
        ]),
        iff(P + "dale", [
            iff(P + "joe", [
                iff(P + "ranger", [
                    say("Farmer Dale", "Well? You have seen the lot of them. Tell me straight."),
                    choice("What do you tell Dale?", ["Let Hannah try it", "Let Joe Hartley take the flock", "Take the habitat scheme", "I need to think"], P + "pick"),
                    pick(0, [
                        setf(P + "pick_hannah"), setf(P + "decided"), stamp(WHEN),
                        say("Farmer Dale", "Hannah. Aye. I think I knew you would say that, and I think I wanted you to. Mind, it is me that has to ring her, and ask properly, which I have never been good at."),
                        say("Farmer Dale", "It is a hard hill for someone learning it. I will be there. My hip and me."),
                    ]),
                    pick(1, [
                        setf(P + "pick_joe"), setf(P + "decided"), stamp(WHEN),
                        say("Farmer Dale", "Joe. Aye. He will keep the flock together and keep them on our hill, and that is the part I could not bear to lose."),
                        say("Farmer Dale", "It does leave the house. And it leaves Hannah where she is, which was her own choice, I suppose, if anyone had asked her."),
                    ]),
                    pick(2, [
                        setf(P + "pick_scheme"), setf(P + "decided"), stamp(WHEN),
                        say("Farmer Dale", "The scheme. Fewer ewes, more heather, folk with clipboards. Paid to look after the place the way I always did, and told how."),
                        say("Farmer Dale", "I will sleep on it. No, I will not. But I will sign."),
                    ]),
                    pick(3, [say("Farmer Dale", "Take your time. The estate will not, but you can.")]),
                    iff(P + "decided", [
                        say("Farmer Dale", "Come back to the Moorcock after lambing. That is where the post waits, for half the moor. Somebody will write."),
                    ]),
                    END,
                ], [say("Farmer Dale", "Have a word with the lass who counts the curlews. She is in the Moorcock most dinner times. Then come back."), END]),
            ], [say("Farmer Dale", "Joe Hartley, at Rosedale. Ask him what he would do with it. Then the curlew lass, then me."), END]),
        ], [
            iff(P + "started", [
                say("Farmer Dale", "Ey up. Hannah has been at you, has she? She means well. She always has."),
                say("Farmer Dale", "Moor Farm has been let to us since before the war. The estate wrote in the winter: the tenancy comes up at lambing, and they want to know who is taking it on. I am sixty-seven and my hip has opinions."),
                say("Farmer Dale", "The ewes are hefted. Each flock learns its own bit of open hill, and the lambs learn it off their mothers. Sell the flock and that knowledge goes off in the lorry. You cannot buy it back."),
                say("Farmer Dale", "Hannah would come home if I asked. That is why I have not asked. She has a job she is good at and a flat with a radiator that works."),
                say("Farmer Dale", "Go and ask Joe Hartley at Rosedale what he would do with it, and have a word with the lass who counts the curlews, she is in the Moorcock most dinner times. Then come back and tell me straight. I will not hear it from folk who want something."),
                setf(P + "dale"),
                END,
            ]),
        ]),
    ]),
]

# --- Joe Hartley (Rosedale Farm) -------------------------------------------------------------
joe = [
    iff(P + "done", [
        iff(P + "pick_joe", [say("Joe", "They went back to their own bit of hill without being told. I stood at the gate like a daft lad. Dale's lot, my lot, same flock now.")]),
        iff(P + "pick_hannah", [say("Joe", "I lent Hannah the dog for lambing. Dale will not hear a word against his girl, and he is right.")]),
        iff(P + "pick_scheme", [say("Joe", "Dale has gone green, I told him. He said I was welcome to a clipboard. We are still speaking.")]),
    ], [
        iff(P + "decided", [
            say("Joe", "Whatever Dale decides, I will abide by it. And I will not say a word out of turn at the mart."),
        ], [
            iff(P + "started", [
                iff(P + "joe", [say("Joe", "Tell him what I said, and tell him I would sooner be turned down by Dale than praised by anyone else.")], [
                    say("Joe", "You will be the one Dale has sent. He is a proud man and a good farmer, and he would hate me for saying it, but his is the best flock on this moor."),
                    say("Joe", "I would take the tenancy and the ewes together, keep them on their own hill and put my shepherd in the house. It would double my acreage in a year when prices are telling everyone to shrink."),
                    say("Joe", "I will be straight about it: it is good for me. It is also the only way that flock stays a flock. Split it or sell it, and those are just ewes."),
                    say("Joe", "What I cannot give is Hannah's choice. If she wants it, it is hers by every right but the paperwork, and I would not stand in her way."),
                    setf(P + "joe"),
                ]),
            ], [
                say("Joe", "Morning. Rosedale used to have ironstone kilns smoking all down the dale. Now it has me and a very loud dog."),
            ]),
        ]),
    ]),
]

ranger = [
    iff(P + "done", [
        iff(P + "pick_scheme", [say("Ranger", "Nine pairs of curlew on Moor Farm this spring, where I found five. I am not saying it is the sheep. I am saying it is not nothing.")], [
            say("Ranger", "Still counting. Curlew numbers on the moors are down, and every nest that gets off is a small argument won."),
        ]),
    ], [
        iff(P + "decided", [say("Ranger", "Whatever Dale chooses, I will be counting on his hill come April. A farmed moor and a watched moor are both better than one nobody walks.")], [
            iff(P + "started", [
                iff(P + "ranger", [say("Ranger", "Tell Dale it is his hill and his say. I would just like him to know the offer is a real one.")], [
                    say("Ranger", "I count birds on contract, which means I am paid in flasks of tea. Curlew, lapwing, golden plover on the tops. All of them are fewer than they were."),
                    say("Ranger", "The estate has offered Moor Farm a scheme: payments for fewer sheep, drains blocked, heather left to grow. It is not charity. It is a modest, steady income for fifteen years, and in return the moor does what a moor does."),
                    say("Ranger", "I would like to see it signed, and I would be lying if I said I was neutral. But a hill with nobody living on it is a hill with nobody watching it. A farmer paid to farm for the birds still has to be a farmer."),
                    say("Ranger", "Hefting survives, by the way. Fewer sheep means a thinner flock, but it is the same flock. Dale would keep his own."),
                    setf(P + "ranger"),
                ]),
            ], [
                say("Ranger", "Do not mind me. I am counting. Curlews are the sound of the moor in spring, and there are fewer each year."),
            ]),
        ]),
    ]),
]

LETTERS = {
    "hannah": [
        "Dear {player}. It is the end of April and I am writing this on the back of a feed bill, because the kitchen table is covered in lambing kit.",
        "We lost eleven ewes in the March snow and Dad has not said I told you so, which is how I know he was worried. The rest scanned better than he feared, and the vet said nothing, which I am told is a compliment.",
        "I kept the Leeds job two days a week from this table, which I did not know a job could do. The money is thin. The hill is not.",
        "Thank you for being the one who said it out loud. Dad would not have asked and I would not have offered. Come and see the lambs. P.S. Dad has taught me to say 'gimmer' without laughing.",
    ],
    "joe": [
        "Dear {player}. Dale here. I am writing from a flat in the village, which has a bathroom indoors and a view of a wall.",
        "Joe took the flock in March and drove them up himself. They went back to their own bit of hill without being told. I wept, and I blame the wind.",
        "The house is let to Joe's shepherd, who is a decent lad and puts his boots in the porch. Hannah rang. She was kind about it, and that was worse.",
        "I am up at the Moorcock most days now, and at the gate on Sundays. It is a farm. Somebody is still farming it. That has to be worth something.",
    ],
    "scheme": [
        "Dear {player}. The scheme man came in February with a clipboard and a good flask. I signed.",
        "We run forty ewes on the hill now instead of a hundred and thirty, and the heather is coming back thick on the south side. The lass counted curlews in April: nine pairs, where she found five.",
        "The payments cover the rent and not much else. Hannah comes and helps with the lambing, and Joe Hartley says I have gone soft. He is not wrong. He is not right, either.",
        "It is a quiet hill. I find I do not mind it as much as I thought I would.",
    ],
}


def letter(kind):
    out = [say("", t) for t in LETTERS[kind]]
    return out


postie = [
    iff(P + "done", [say("Postwoman", "That was the last of yours. I have the whole moor's post to get round, and a pasty to finish.")], [
        when(RIPE, [
            say("Postwoman", "There you are. A letter for you, care of the Moorcock. I have kept it out of the rain."),
            iff(P + "pick_hannah", letter("hannah") + [give("w55_moor_notebook")]),
            iff(P + "pick_joe", letter("joe") + [give("w55_moor_crook"), setf(P + "world_joe"), setf(P + "away")]),
            iff(P + "pick_scheme", letter("scheme") + [give("w55_moor_tally"), setf(P + "world_scheme"), setf(P + "away")]),
            say("Postwoman", "And a flat cap, brown paper round it. Dale's spare, it says, the one with the sweat stain. And a note on how to bake his mother's parkin. She would want the credit."),
            recipe("parkin"),
            give("flat_cap_yorkshire"),
            setf(P + "done"),
        ], [
            say("Postwoman", "Nothing for you yet. Letters from the dale take their time, and so does the weather. Try after a night's sleep."),
        ]),
    ]),
]

dale_pub = [
    say("Dale", "I come down for the Yorkshire pudding the landlord is too mean to charge me for."),
    say("Dale", "I go up to the gate on Sundays. They knew me fine the first week. By May they only knew Joe's whistle, which is as it should be, and I will not pretend I like it."),
]
sam = [
    say("Sam", "I am Joe's shepherd. Dale's old house, Joe's flock. They know the hill better than I do, so I just walk behind and look as if I meant it."),
    say("Sam", "Boots in the porch. I was told. I was told twice."),
]
ranger_farm = [
    say("Ranger", "Nine pairs of curlew on Moor Farm this spring. I am out here more than the Moorcock these days."),
    say("Ranger", "Dale shows me the nests he knows. Thirty years of knowing a hill is worth more than my clipboard, and I tell him so, which he does not believe."),
]

# --- the quest -------------------------------------------------------------------------------
quest = {
    "id": "stories_england",
    "title": "Who Takes the Moor Farm",
    "region": "stories_england",
    "town": "north_york_moors",
    "giver": "Hannah, at Moor Farm",
    "summary": "Farmer Dale's tenancy comes up at lambing and nobody has said who takes the hill farm on. Hear everyone, then tell him straight.",
    "start_flag": P + "started",
    "steps": [
        {"flag": P + "dale", "text": "Talk to Farmer Dale at Moor Farm.", "zone": FARM},
        {"flag": P + "joe", "text": "Ask Joe Hartley at Rosedale Farm what he would do with it.", "zone": ROSE},
        {"flag": P + "ranger", "text": "Hear the moor ranger at the Moorcock Inn.", "zone": INN},
        {"flag": P + "decided", "text": "Tell Farmer Dale what you think.", "zone": FARM},
        {"flag": P + "done", "text": "Wait for word. The post for this end of the moor waits at the Moorcock Inn, a night's sleep or a day later.", "zone": INN},
    ],
    "done_flag": P + "done",
    "reward": "A Yorkshire flat cap, a keepsake of how it went, and Dale's mother's parkin recipe.",
    "endings": [
        {"flag": P + "pick_hannah", "text": "Hannah took Moor Farm on, with a part-time job to keep the roof on. Hill farms have long leaned on a second income, and on flocks that know their own hill."},
        {"flag": P + "pick_joe", "text": "Joe Hartley took the flock and the tenancy and the flock stayed on its hill. Dale moved to the village, and a shepherd lives in the farmhouse."},
        {"flag": P + "pick_scheme", "text": "Moor Farm went into a habitat scheme: forty ewes, not a hundred and thirty, more heather, and curlews nesting where there were fewer."},
    ],
}

items = [
    key_item("w55_moor_notebook", "Hannah's Lambing Notebook", "A school exercise book, spattered. Dates, ewes, a column headed 'Dad says' and a column headed 'Actually'. The second column is winning."),
    key_item("w55_moor_crook", "Dale's Old Crook", "An ash crook worn pale where one hand held it for forty years. Dale did not want it left in the farmhouse porch. 'Somebody ought to carry it,' he said."),
    key_item("w55_moor_tally", "Curlew Tally Sheet", "A ranger's tally sheet for Moor Farm: nine pairs of curlew in a neat column, five in the last. Somebody has drawn a very small bird in the margin."),
]

# --- go ----------------------------------------------------------------------------------------
add_items(items)
set_quests("england", [quest])
add_script(FARM, "w55e_hannah", hannah)
add_script(FARM, "w55e_sam", sam)
add_script(FARM, "w55e_ranger_farm", ranger_farm)
prepend(FARM, "moorfarm_farmer", "england", dale)
add_script(ROSE, "w55e_joe", joe)
add_script(INN, "w55e_ranger", ranger)
add_script(INN, "w55e_postie", postie)
add_script(INN, "w55e_dale_pub", dale_pub)

add_npc(FARM, {"id": "w55e_hannah", "name": "Hannah", "sprite": "villager_2", "x": 8, "y": 4, "facing": "left", "script": "w55e_hannah", "hide_if": P + "away"})
add_npc(FARM, {"id": "w55e_sam", "name": "Sam", "sprite": "villager_3", "x": 3, "y": 5, "facing": "right", "script": "w55e_sam", "show_if": P + "world_joe"})
add_npc(FARM, {"id": "w55e_ranger_farm", "name": "Ranger", "sprite": "birdwatcher", "x": 9, "y": 3, "facing": "left", "script": "w55e_ranger_farm", "show_if": P + "world_scheme"})
gate_npc(FARM, "moorfarm_farmer", hide_if=P + "world_joe")
add_npc(ROSE, {"id": "w55e_joe", "name": "Joe Hartley", "sprite": "villager_1", "x": 7, "y": 4, "facing": "left", "script": "w55e_joe"})
add_npc(INN, {"id": "w55e_ranger", "name": "Ranger", "sprite": "birdwatcher", "x": 9, "y": 4, "facing": "down", "script": "w55e_ranger", "hide_if": P + "world_scheme"})
add_npc(INN, {"id": "w55e_postie", "name": "Postwoman", "sprite": "villager_6", "x": 4, "y": 6, "facing": "right", "script": "w55e_postie", "show_if": P + "decided", "hide_if": P + "done"})
add_npc(INN, {"id": "w55e_dale_pub", "name": "Dale", "sprite": "farmer", "x": 4, "y": 4, "facing": "right", "script": "w55e_dale_pub", "show_if": P + "world_joe"})
print("england written")
