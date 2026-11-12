# Wave 53 facts review

Everything player-facing that wave 53 added was read in full: 187 visit entries, 163 new `examine` spots, 200 family drawers,
41 asks, 54 new Regulars (the brief said 53; there are 54 after the original 12) and the 28 renamed residents.
Data-only edits; no ids, keys, items or code touched.

## Fixes (before -> after)

### data/visits (7 fixes)
- aberdeen_home_d: "ye look like a rowie wants ye" -> "ye look like ye could dae wi a rowie" (the old line was not Doric or sense).
- central_belt_cottage: "Fog on the cut" -> "Fog on the canal" ("the cut" is English canal talk, not Central Belt Scots).
- galway_home_prom, kilkenny_home3, lancaster_home_rigby, york_house_c: "pet" -> "love" ("pet" is North East and Cumbrian, not Irish, Lancaster or York).
- norwich_home_a: "my duck" -> "bor" ("my duck" is East Midlands; Norfolk is "bor").
- portree_home_c: "Oidhche mhath soon." -> "It is nearly oidhche mhath, good night, in this house."
- stornoway_home_a: "You remember, you said it already." -> "That is how are you, and you will be asked it a lot." (the player had not said it).

### examine (5 fixes)
- belfast_home_riveter: "A riveting gang was four: ... the hammerer" -> "A riveting gang had a heater, a catcher, a holder-on and a riveter." (gang size and "hammerer" unsure).
- kilkenny_home1: "Within a generation half the settlers spoke the language better than the locals." -> "Plenty of the settlers carried on speaking Irish anyway." (overclaim).
- kirkwall_home_a: dropped "The simmer dim, the Shetlanders call it" (Shetland term, and the resident's own dialogue already says so).
- llanberis_home_eglwys: "Half the roofs in Britain were once Welsh slate." -> "Welsh slate once roofed streets far beyond Wales."
- shannon_cottage: "Some hearths in these cottages have burned for two hundred years." -> "In the old days the fire was never let go out, only raked over for the night."

### family_drawers (6 fixes)
- dingle_home4: Irish "mo cheachtanna baile" -> "m'obair bhaile" (obair bhaile is standard Irish for homework). Full line now "d'ith mo mhadra m'obair bhaile".
- dingle_home3: "since before the nephew called Fungie was born" (nonsense) -> "since before Fungie came to the harbour".
- kilkenny_home4: "forty Septembers" -> "forty summers" (the hurling final moved to July).
- macc_h2: Hovis "Born in Macclesfield" -> "Named in Macclesfield" (the name came from a Macclesfield firm's 1890 competition).
- buxton_h2: "Highest market town in England" -> "..., they say" (Alston disputes it).
- york_house_b: "before the Vikings dug up Coppergate" -> "before anyone dug up Coppergate" (archaeologists dug it).

### asks (4 text edits, 3 asks)
- dingle_home4 polartern thanks: "Mar sin leat" (Scottish Gaelic) -> "Slan leat" (Irish; written with the fada in the file).
- bermuda_lighthouse photo thanks: "a hundred and ten metres of cast iron" -> "thirty-odd metres" (the tower is about 36 m; 110 m is the light above sea level).
- kirkwall_home_d cragchough: ask and thanks no longer claim they nest near Kirkwall (the species habitat is Welsh coasts; real choughs do not breed in Orkney).

### regulars (22 text edits)
- 9 Regulars (breda_cork, francie_derry, mattie_galway, nora_kilkenny, aidan_limerick, ruth_newgrange, con_kerry, batt_shannon, peggy_sligo) had a doubled speaker prefix in `meet` and `thanks` ("Mrs Lynch: Mrs Lynch: ..."): 18 lines fixed.
- murdo_harris: "Gearrannan is quiet today" -> "The village is quiet today" (Gearrannan is on Lewis, not Harris).
- hugh_lincoln: "Stone since about 1160" -> "Stone since the twelfth century".
- alf_wirral_way: "Handel landed right here" -> "Handel crossed to Dublin in 1741 with the Messiah in his luggage" (could not confirm the Parkgate departure point).
- emrys_llanberis: "Half the roofs in Britain" -> "Roofs all over Britain".
- No edit touched the last entry (catriona_oban).

### Renamed residents
All 28 names fit their places (Orkney Flett/Rendall/Drever/Linklater, Skye Nicolson/MacAskill/Beaton/MacKinnon, Lochaber Cameron/MacMillan, Welsh names in Gwynedd/Denbighshire). No edits.

## Checked and left alone
Manx (Traa dy liooar, Moghrey mie, Fastyr mie, Gura mie ayd), Scottish Gaelic (Failte air ais, Ciamar a tha thu, Madainn mhath, Oidhche mhath, Tha/Chan eil, Tha i fuar, Mòran taing, Tapadh leibh, Am bheil thu sgith), Welsh (cwtch, butt, hwyl, picau ar y maen, bara brith, tylwyth teg, Dyna ni, Diolch), Irish (Go raibh maith agat, Slan abhaile, Slan go foill, Cruinniu na mBad, cuplá focal, Bean an Ti, a chara), Doric (Fit like, dinna fash), Orcadian (peedie, Uppie/Doonie), Cornish (dreckly, emmet), Norfolk (on the huh), Cumbrian (yat), plus the dated claims (Rubislaw 1971, Herschel 1781, Bath Olivers, Fringe 1947, Neptune's Staircase, Lune Aqueduct, Ironbridge 1950, Statutes of Kilkenny 1366, Staffin footprints, Jonathan the tortoise c.1832, Pitcairn surnames).

## For a human
- Language I could not fully verify: Doric "dae wi a rowie" (my replacement), Manx and Scottish Gaelic phrases were checked from memory only, Welsh "Dyna ni" in an ask. Gaelic name "Mairead" (portree_home_c) may want the grave accent (Mairead) if you prefer the Gaelic form.
- Surnames I am less sure of: Handfield (Turks and Caicos), Boycott (Shropshire toll keeper).
- Handel's departure point for Dublin: I could not confirm Parkgate, so the line is now vaguer.
- Style: nearly every visit `again` line opens "Back again". Worth a pass for variety.
- Seen asks use species whose habitat list does not include the town (orcalet at Aberdeen, rillotter at Kilkenny, starlet at Belfast); true to the real birds and animals, but the player may have to travel.
- Emeka Okafor says "Mom" (West Midlands usage, but reads American).
- Stored `kirkwall_home_d` visit line "cliffs are noisy" and the resident's older dialogue still say cragchoughs nest near Kirkwall (pre-wave text, not edited).
- Test status: `tools/test.sh w53` and `regulars` show 0 failed, but `validate` reports 1 error, `bath_home2: examine spot 9,1 is blocked off`. That is a props/examine clash between the rooms and looks sessions, not text; I did not touch bath_home2 and left props alone as out of scope. Needs the rooms owner.
