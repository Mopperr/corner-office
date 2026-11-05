# Oct 23: one-off event characters added to customers.json["customers"] (is_regular: false)
# so QA's check_shop_data.py DC-06 resolves every character id used in customer_events.json.
# The 8 regulars get is_regular: true. tools/build_customer_events.py only builds its customer
# table from is_regular entries. Exec'd by _build.py after _ext_drinks.py.
# Tuple: id, name, kind, description, first_level, first_event, favourite_drink, orders, alias_of,
#        reviews (great, okay, off), idle thoughts (<=40 chars)
CAST = [
 ("neighbor_kid","Neighbor kid","one_off","Kid from next door with a fistful of quarters; the very first customer.","L1","ev_drink_classic_first_sale","classic_lemonade",True,None,
  ("Best. Lemonade. On the whole street!","It's lemon-y AND sugar-y. Telling everyone.","Still lemonade! Lemonade is always good."),
  ["Quarters: counted twice.","Quiet straw, please.","Mom says say thank you."]),
 ("dana","Dana (player character)","player","The player. Listed so event lines can name Dana as a speaker; never queues or orders.","L1","ev_drink_classic_first_sale","classic_lemonade",False,None,
  ("Nailed it. Writing that one on the sticky note.","Not bad! Next one's even better.","Okay, note to self: more lemon. Still proud."),
  ["First sale. Breathe.","Sticky note: more ice?","This place is coming together."]),
 ("priya_okafor","Priya Okafor","one_off","Owner of the Whisker & Bean cat cafe. Debuts in her L2 pink-lemonade event (with Biscuit), then comes back as a regular-for-a-day after great serves.","L2","ev_drink_pink_biscuit_nose","pink_lemonade",True,None,
  ("My usual, and somehow better. Purr-fect.","Just how I like it, give or take a whisker.","Bit of a hairball day for this one, but I'm smiling!"),
  ["My usual, please.","Biscuit says hi.","Fur on my sleeve again."]),
 ("biscuit","Biscuit (the cat)","pet","The Whisker & Bean cat. Wanders in, sniffs cups, never orders.","L2","ev_drink_pink_biscuit_nose","pink_lemonade",False,None,
  ("(Slow blink. A purr like a tiny engine.)","(Biscuit sniffs the cup and sits on your foot.)","(Biscuit headbutts the cup. Approved anyway.)"),
  ["Sunbeam: located.","Is that... a box?","Prrrrrp."]),
 ("cyclist_from_l3","Soggy cyclist","one_off","Drenched cyclist from the L3 rainy drive who shelters at the stand.","L3","ev_drink_icedtea_after_rain","iced_tea_lemonade",True,None,
  ("Worth every puddle on the way here.","Hit the spot. My socks disagree, but I don't.","Rain got in it? Fair. I'm half rain too. Cheers!"),
  ["Socks: soaked.","Is that the sun?","Helmet hair, don't care."]),
 ("grandpa_train_shop","Grandpa Walt Hale","one_off","Retired conductor from the L4 train shop; strawberry lemonade fan and caboose collector.","L4","ev_drink_strawberry_caboose","strawberry_lemonade",True,None,
  ("All aboard! First-class lemonade.","Right on schedule. Good and sweet.","A little late to the station, but it arrived. Toot toot!"),
  ["Next stop: lemonade.","Caboose is the best car.","Ticket, please... oh, me."]),
 ("duckling","Duckling","pet","A very small duck at the L5 pond. Waddles, quacks, does not drink lemonade.","L5","ev_drink_mint_duckling","mint_lemonade",False,None,
  ("Quack! (one tiny happy hop)","Quack. (polite little waddle)","Quack? (it pats the cup with one webbed foot, kindly)"),
  ["Quack.","Puddle! Puddle!","Where's mom?"]),
 ("delbert_finch","Delbert Finch","one_off","Retired watchmaker in the bakery loft building. Times every coffee to the second.","L6","ev_drink_black_delbert_clock","black_coffee",True,None,
  ("Precise. Like a well-wound watch.","Ticks along nicely.","Running a few seconds slow, as do I. Thank you kindly."),
  ["Three minutes, twelve seconds.","Tick, tock, coffee.","My watch is never wrong."]),
 ("retiring_dentist","Dr. Barry Plum","one_off","Cheerful dentist on his last day at the L7 office; espresso, no sugar, 'for professional reasons'.","L7","ev_drink_espresso_dentist","espresso",True,None,
  ("A flawless shot. I'd floss with joy.","Good bite to it. No cavities detected.","A gentle little espresso. Very kind to the teeth!"),
  ["Last day. Strange feeling.","Gerald needs a good home.","No sugar. Professional reasons."]),
 ("gerald","Gerald (the fish)","pet","The dentist's goldfish and VIP of the L7 move. Watches from his bowl.","L7","ev_drink_espresso_dentist","espresso",False,None,
  ("(Gerald does a delighted loop.)","(Gerald blows one approving bubble.)","(Gerald blinks. He loves you regardless.)"),
  ["Blub.","Bowl: very round today.","Blub blub."]),
 ("npc_vendor","Market vendor","one_off","Honey seller at the L8 Saturday market who trades a jar for a honey-lavender lemonade.","L8","ev_drink_honeylav_vendor","honey_lavender_lemonade",True,None,
  ("That's my honey singing in there!","Sweet and calm. Bees would approve.","A bit shy on the honey. I'll bring you an extra jar!"),
  ["Bees were busy today.","Market's buzzing.","Did a cabbage just roll by?"]),
 ("npc_architect","Imogen Vance-Okoro","one_off","Architect from the L9 job who sketches on everything, including latte foam.","L9","ev_drink_latte_sketch_art","latte",True,None,
  ("Clean lines, perfect foam. I'd frame it.","Solid structure. Lovely finish.","A draft, not a final. Drafts are my favourite part!"),
  ["Door: redraw again?","Foam is a blueprint.","Pencil behind my ear..."]),
 ("agnes_pell","Ms. Agnes Pell","one_off","Town librarian moving the library to its new branch at the L10 job. Speaks in a whisper; loves a quiet cappuccino.","L10","ev_drink_cappuccino_quiet","cappuccino",True,None,
  ("(whispering) Exquisite. Five quiet stars.","(whispering) Very nice. Shelved under 'cozy'.","(whispering) A little loud, but so am I on Thursdays. Thank you."),
  ["Shhh... the foam is thinking.","Overdue: one nap.","Page 112, I think."]),
 ("juno_park","Juno Park","one_off","Drummer in The Laundromats and a regular at Lou's record shop (L12); drops by the L11 loft. Mocha-powered and always late.","L11","ev_drink_mocha_juno","mocha",True,None,
  ("This mocha is a ten out of ten. Encore!","Solid groove. I'd play this one twice.","A rough first take! Every great song starts with one."),
  ["Soundcheck in ten... ish.","Mocha is a backbeat.","Drumsticks? Pocket. Keys? Hmm."]),
 ("record_store_owner","Lou Marchetti","one_off","Record shop owner at the L12 job; keeps a turntable spinning and the iced coffee on beat.","L12","ev_drink_iced_on_beat","iced_coffee",True,None,
  ("Pure groove. Iced coffee on vinyl.","Nice B-side. Easy listening.","A little off-beat, but jazz is too. Love it."),
  ["Flip to side B.","That bassline...","Ice clinks in 4/4."]),
 ("rosa_pemberton","Rosa Pemberton","one_off","Florist with an orchid corner. Debuts in her L14 vanilla-latte event, then comes back as a regular-for-a-day; met Ray in this very line.","L14","ev_drink_vanilla_orchid","vanilla_latte",True,None,
  ("My usual, and it's in full bloom!","Lovely as ever, dear.","Needs a little sun, like my ferns. Still lovely."),
  ["Is Ray here today?","Ferns need water.","Vanilla latte, please."]),
 ("ray_pemberton","Ray Pemberton","one_off","Rosa's husband-to-be; first met her chatting in your queue. Plain-coffee man.","L14","ev_gen_two_customers_chat","black_coffee",True,None,
  ("Best cup in town. Don't tell Rosa I said 'best'.","Good, honest coffee.","A bit weak, but so are my knees. Cheers, friend."),
  ["Where's Rosa?","Plain is fine. Plain is great.","Should I buy her flowers? Oh."]),
 ("coworker_npc","Co-worker","one_off","Friendly teammate in Dana's L16 glass suite who always tries the seasonal special first.","L16","ev_drink_seasonal_board","seasonal_special",True,None,
  ("New season, new favourite!","Nice twist on the season.","A brave seasonal experiment! I respect it."),
  ["Meeting at three?","What's on the board?","Snacks in the break room?"]),
 ("food_critic","Quiet critic","one_off","Notebook-carrying critic who visits once you reach Rep 2 and 30 orders. Silent, then surprisingly kind.","L3","ev_gen_critic_visit","black_coffee",True,None,
  ("(writes for a long time, then smiles) Remarkable.","(nods) Honest and well made.","(gentle smile) Promising. I'll be back to see it grow."),
  ["Noting the cup weight...","Lighting: cozy.","Hm. Hm! Hm."]),
 ("marge_holloway","Marge 'Mile Marker' Holloway","one_off","Dana's mentor and dispatcher; drops in at each office move to check on the shop.","L6","ev_gen_marge_checkin","black_coffee",True,None,
  ("That's a mile-marker cup, kiddo. Proud of you.","Good work. Keep the wheels turning.","Every road has a bump. You're doing fine."),
  ["Checking in on my favourite.","Long drive, good coffee.","Look at this place now."]),
 ("queue_npc","Queue customers (generic crowd)","crowd","Generic background customers used for rush hour and weather crowds. Not a character; a crowd tag.","L1","ev_gen_weather_turn","classic_lemonade",True,None,
  ("Wow, worth the wait!","Nice, thanks!","No worries, still tasty!"),
  ["Long line, good sign.","What's everyone getting?","Smells great."]),
 ("customer","Any customer (generic)","crowd","Generic 'any customer' tag used by the review board. Not a character; a crowd tag.","L1","ev_gen_review_board","classic_lemonade",True,None,
  ("Five stars, easy!","Pretty good!","Still nice! Thanks for trying."),
  ["Reading the review board.","Leave a review? Sure.","Cozy spot."]),
]
_SLICE = customers["_meta"]["slice_drinks"]
_COFFEE = {"black_coffee","espresso","latte","cappuccino","mocha","iced_coffee","vanilla_latte"}
for c in customers["customers"]: c.setdefault("is_regular", False)   # default False; _build.py sets True on the 8 regulars
assert sorted(c["id"] for c in customers["customers"] if c["is_regular"]) == sorted(REGULAR_IDS), "regulars must be explicit"
_cast_entries = []
for (cid,name,kind,desc,lvl,ev,fav,orders,alias,rv3,idl3) in CAST:
    assert fav in UNLOCK and all(len(x) <= 40 for x in idl3), cid
    e = {"id":cid,"name":name,"is_regular":False,"kind":kind,"description":desc,"first_level":lvl,"first_event":ev,
         "orders":orders,"favourite_drink":fav,"favorite_products":[fav] if orders else [],
         "slice_order": fav if fav in _SLICE else ("black_coffee" if fav in _COFFEE else "classic_lemonade")}
    if alias: e["alias_of"] = alias
    _cast_entries.append(e)
customers["customers"] = customers["customers"] + _cast_entries
customers["_meta"]["roster_note"] = ("customers[] holds the 8 regulars (is_regular: true) and the one-off event cast "
    f"({len(_cast_entries)} entries, is_regular: false). Spawners and banter use is_regular entries only. "
    "kind: one_off | pet | player | crowd | alias (alias_of names the canonical id). orders:false = never queues or orders.")
customers["_meta"]["id_renames"] = {
    "_note": "Oct 23 (Programmer Master): ids unified. Old -> new. Aliases merged into the canonical entry (no alias rows).",
    "cat_cafe_owner": "priya_okafor", "florist": "rosa_pemberton", "cyclist_from_L3": "cyclist_from_l3",
    "customers": "customer", "queue_npcs": "queue_npc"}
customers["_meta"]["id_flags"] = {"dana": "Player character; never orders."}
customers["_meta"]["event_cast_note"] = ("event_cast maps every speaker id (including unused generic ones like queue_npc, regular, narration) "
    "to a display name. The roster for one-offs is customers[] with is_regular:false.")
customers["_meta"]["regular_ids"] = [c[0] for c in C]
reviews["per_customer"] = {**reviews["per_customer"], **{c[0]: dict(zip(("great","okay","off"), c[9])) for c in CAST}}
idle["per_customer"] = {**idle["per_customer"], **{c[0]: c[10] for c in CAST}}
CAST_MD = ("\n# Event cast (one-off, is_regular: false)\n\nThese characters appear in specific events only; they are not in the random customer pool.\n\n"
    "| id | Name | Kind | First level | First event | Drink | Orders |\n|---|---|---|---|---|---|---|\n"
    + "\n".join(f"| `{c[0]}` | {c[1]} | {c[2]}{' of `'+c[8]+'`' if c[8] else ''} | {c[4]} | `{c[5]}` | {c[6]} | {'yes' if c[7] else 'no'} |" for c in CAST)
    + "\n\n" + "\n".join(f"- **{c[1]}** (`{c[0]}`): {c[3]} Reviews: \"{c[9][0]}\" / \"{c[9][1]}\" / \"{c[9][2]}\"" for c in CAST)
    + "\n\n**Id flags:** " + "; ".join(f"`{k}`: {v}" for k, v in customers["_meta"]["id_flags"].items()) + "\n")
