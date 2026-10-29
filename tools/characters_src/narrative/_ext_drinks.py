# Extension: 14-drink menu from /workspace/game/drink_unlocks.json (exec'd by _build.py)
_DU = json.load(open("/workspace/game/drink_unlocks.json"))
DRINKS = [d["id"] for d in _DU["drinks"]]
NAMES = {d["id"]: d["name"] for d in _DU["drinks"]}
SLICE6 = ["classic_lemonade","pink_lemonade","iced_tea_lemonade","strawberry_lemonade","mint_lemonade","black_coffee"]
LEGACY = {"lemonade":"classic_lemonade","iced_lemonade":"classic_lemonade (served with extra ice; heat-weather variant)","sweet_coffee":"black_coffee + sugar (no longer a menu item; nearest menu drinks: mocha, vanilla_latte)"}
PRODUCTS = DRINKS
SRC = "/workspace/game/drink_unlocks.json (14 drinks; products.json from Programmer Master not yet present, ids to match)"
for blk in (customers, order_lines, reviews, banter, idle):
    blk["_meta"].update(version=2, phase="slice", product_source=SRC, product_ids=DRINKS, slice_drinks=SLICE6,
        legacy_product_ids=LEGACY, quality_bands={"great":">=80","okay":"50-79","off":"<50"},
        tone="Cozy sitcom. Customers are kind. Off drinks get gentle, funny feedback and the customer still pays.")

FAV = {"steve":["black_coffee","espresso","vanilla_latte"],"lamp_lady":["pink_lemonade","honey_lavender_lemonade","latte"],
 "keyclackr":["espresso","iced_coffee","black_coffee"],"dottie":["classic_lemonade","iced_tea_lemonade","mocha"],
 "theo":["latte","cappuccino","black_coffee"],"pippa":["classic_lemonade","strawberry_lemonade","pink_lemonade"],
 "rocco":["mint_lemonade","iced_coffee","strawberry_lemonade"],"wren":["honey_lavender_lemonade","cappuccino","seasonal_special"]}
for c in customers["customers"]: c["favorite_products"] = FAV[c["id"]]
for c in C: c[4][:] = FAV[c[0]]

# old product reviews -> new ids
R["classic_lemonade"] = R.pop("lemonade")
_iced = R.pop("iced_lemonade"); R.pop("sweet_coffee")
R.update({
"pink_lemonade":{"great":["Pink as a sunset and twice as sweet. Perfect!","The berry splash is just right. Biscuit would approve.","It's so pretty I almost didn't drink it. Almost."],
 "okay":["A little more lemon than berry today. Still cheerful!","Pale pink. Shy pink. I like it anyway.","Berry's hiding at the bottom. Fun surprise for the last sip!"],
 "off":["This is more red lemonade than pink. Very dramatic! Paying!","I think the berries had a party and invited no lemons. Cute!","It's pink-ish. In the right light. I'll bring a lamp. Here you go!"]},
"iced_tea_lemonade":{"great":["Tea and lemon holding hands. Lovely.","Cooled just right. Tastes like the sun coming back.","Smooth tea, bright lemon. A rainy-day reward."],
 "okay":["Tea's still a bit warm, so the ice is racing. Tasty though!","A touch strong on the tea. Very awake now!","Little light on lemon. Still a nice porch sip."],
 "off":["This is hot tea pretending to be cold. Brave little drink! Paying.","The ice melted out of politeness. Still paying, friend!","Mostly tea, a whisper of lemon. Nap-flavored. Thank you!"]},
"strawberry_lemonade":{"great":["Caboose-red and full steam ahead!","You can taste real strawberries. Wonderful.","Sweet, tart, berry-bright. Perfect ride."],
 "okay":["A few berry chunks went rogue. I'll chew them happily.","Could use a bit more muddle. Still lovely!","More lemon than berry. A pink-ish caboose."],
 "off":["I think the strawberries are still napping in the bowl. Cute! Paying.","It's a strawberry smoothie that got lost. I love it anyway.","One whole strawberry, just floating. Like a little lifeboat! Here you go."]},
"mint_lemonade":{"great":["Cool mint, bright lemon. Like a breeze off the pond.","So fresh I can hear ducks. Perfect.","Just enough mint. You're a natural."],
 "okay":["Mint's a little shy. Still refreshing!","A bit leafy! I'm part garden now.","Strong mint! My nose feels very clean."],
 "off":["This is toothpaste's sunny cousin. Fun! Paying.","I think the mint stayed by the pond. Still sweet effort!","There's a whole leaf in my straw. We're friends now. Here you go!"]},
"espresso":{"great":["Tiny cup, big hug. Perfect shot.","Crema like a little sunset. Wonderful.","Short, sweet, strong. Like a great nap in reverse."],
 "okay":["A touch quick on the pull. Still zippy!","Little bitter at the end. Wakes me right up.","Bit thin, but it's got spirit."],
 "off":["This espresso is... very relaxed. On vacation, maybe. Paying!","Strong enough to reorganize my bookshelf. Thank you!","It's a long shot. Like, a really long shot. Very hydrating!"]},
"honey_lavender_lemonade":{"great":["Honey, lavender, lemon. A garden in a glass.","Floral but not soapy. That's hard! Bravo.","Tastes like the market on a sunny Saturday."],
 "okay":["Lavender's a little loud today. Still pretty!","Honey sank to the bottom. Sweet treasure at the end.","Gentle and nice. Could steep a smidge longer."],
 "off":["I'm drinking a very sweet candle. Delightful! Paying.","Lavender took the whole stage. Standing ovation anyway!","More honey than lemonade. The bees would be proud. Here you go!"]},
"latte_extra":[],
"cappuccino":{"great":["Perfect foam, light as a library whisper.","Cocoa dust on a cloud. Wonderful.","Equal parts coffee, milk and foam. Textbook!"],
 "okay":["Foam's a little thin, but it's cozy.","Bit heavy on the cocoa. A chocolate mustache!","Nice! Slightly more latte than cappuccino today."],
 "off":["The foam ran off to find a better book. Still paying!","Cocoa avalanche! I'm wearing it. Thank you!","It's flat, but it's trying its best. So am I. Here you go!"]},
"mocha":{"great":["Chocolate and coffee best friends. Perfect.","Rich, warm, and the whip is a crown. Wonderful.","Tastes like a snow day. Thank you!"],
 "okay":["Little more chocolate than coffee. Not complaining!","Chocolate's hiding at the bottom. Stir and smile!","Bit sweet! My teeth waved hello."],
 "off":["This is hot chocolate with a coffee rumor. Delicious rumor! Paying.","The whip sank like a tiny ship. Brave whip. Here you go!","Chocolate forgot to come. It's just a latte with hope. Still lovely!"]},
"iced_coffee":{"great":["Smooth cold brew, clinking ice. Perfect groove.","Cold, strong, not bitter. You nailed it.","Tastes like a record on a lazy afternoon."],
 "okay":["Too much ice, but what's there is tasty!","A little watery at the end. Still chill!","Strong! I'm vibrating slightly. Happily."],
 "off":["This is an ice cube with coffee dreams. Paying!","Not cold. A warm iced coffee! Bold invention. Thank you!","Mostly ice! I'll wait for the melt. Patient sips."]},
"vanilla_latte":{"great":["Vanilla like a warm cookie. Lovely.","Sweet but balanced. A flower in a cup.","Silky, gentle, perfect. Thank you!"],
 "okay":["Vanilla's a little shy today. Still cozy!","A tad sweet! Dessert came early.","Foam's a bit flat, flavor's lovely."],
 "off":["This tastes like a vanilla candle's first try. Sweet! Paying.","I think the vanilla got lost in the milk. Still warm, still kind.","Vanilla party! Everyone came. Here's your money, friend."]},
"seasonal_special":{"great":["Tastes exactly like this time of year. Perfect.","The topping makes it. Seasonal magic!","Cozy, spiced, just right. I'll be back next season."],
 "okay":["Syrup's a little strong. Very festive though!","Topping slid off. It's on the saucer now. Fine!","Nice! The season's a bit faint in this one."],
 "off":["This is... several seasons at once. A whole year! Paying.","The topping went on a little adventure down the side. Cute!","Very mysterious flavor. Like a surprise gift. Thank you!"]},
})
R.pop("latte_extra")
R["classic_lemonade"]["off"] += []
R["mint_lemonade"]["okay"].append(_iced["okay"][0])
assert set(R) == set(DRINKS), set(R) ^ set(DRINKS)
for p, t in R.items():
    for b in ("great","okay","off"): assert len(t[b]) >= 3, (p, b)

# per-customer-product: remap legacy ids, add more
_map = {"lemonade":"classic_lemonade","iced_lemonade":"classic_lemonade","sweet_coffee":"black_coffee"}
for cid, pm in CVP.items():
    for old, new in _map.items():
        if old in pm: pm.setdefault(new, {}).update(pm.pop(old))
CVP["steve"]["espresso"]={"great":"Compact. Efficient. A mini stapler of a drink. Five staples."}
CVP["pippa"]["strawberry_lemonade"]={"great":"Gold star AND a strawberry sticker. Rare!","off":"Nice-try frog. He likes strawberries, so he's extra proud."}
CVP["rocco"]["mint_lemonade"]={"great":"Minty zing! Fastest block of the whole route now."}
CVP["rocco"]["strawberry_lemonade"]={"great":"Signed, sealed, strawberry! Mint can take its time.","off":"Bit squished in transit, but I'd sign for it again."}
CVP["wren"]["honey_lavender_lemonade"]={"great":"Lavender evening / honey settles like the dusk / lemon, the first star"}
CVP["theo"]["cappuccino"]={"okay":"Foam's a bit thin. Like my patience at hour eleven. Still lovely."}
CVP["keyclackr"]["iced_coffee"]={"great":"Cold brew, clean actuation. Zero latency.","off":"Lukewarm. Laggy. Still pressing 'like'. Paying!"}
CVP["dottie"]["mocha"]={"great":"Chocolate in my coffee! Harold would've called this cheating. Delicious cheating."}
CVP["lamp_lady"]["pink_lemonade"]={"great":"It's the exact color of my favorite lampshade!"}
reviews["by_product"]=R; reviews["per_customer_product"]=CVP

# order lines
SPEC2 = {
"steve":{"black_coffee":["Black coffee, please. No frills, like a good standard stapler."],"espresso":["One espresso. Small, dense, reliable. Like a mini stapler."],"vanilla_latte":["A vanilla latte, please. My weekend treat. Acquiring it now."],"cappuccino":["Cappuccino, please. Is the foam load-bearing?"],"classic_lemonade":["A classic lemonade. For the classics collection."]},
"lamp_lady":{"pink_lemonade":["Pink lemonade, sweetie! It matches my sunhat lining."],"honey_lavender_lemonade":["The honey-lavender, please! It sounds like golden hour."],"latte":["A latte, please. Lots of foam. Soft lighting for my tummy."],"seasonal_special":["What's the season today? I'll have it in a cup!"],"iced_tea_lemonade":["Iced tea lemonade! I love how it glows amber."]},
"keyclackr":{"black_coffee":["Black coffee. Strong. Like a clicky blue switch."],"espresso":["Espresso, plz. Please. Double-tap speed."],"iced_coffee":["Iced coffee, cold brew, low latency."],"latte":["Latte me, friend. Medium foam, high RPM."],"mocha":["Mocha. I earned it. I finished a build."]},
"dottie":{"classic_lemonade":["Lemonade, please, and don't be shy with the sugar."],"iced_tea_lemonade":["Iced tea lemonade, dear. Light ice. My teeth are retired too."],"mocha":["A mocha, sweetie. Coffee and chocolate, all in one. What a world."],"strawberry_lemonade":["Strawberry lemonade, please. Harold grew strawberries too, you know."]},
"theo":{"latte":["Latte, hot as you can, extra foam. I'm basically a cloud now."],"cappuccino":["Cappuccino, please. Extra foam. Foam is a pillow."],"black_coffee":["Black coffee, please. I'm going to drink it and then sleep. Don't ask."],"vanilla_latte":["Vanilla latte. Something gentle. It's been a night."],"mint_lemonade":["Mint lemonade? Sure. It's practically mouthwash, which is basically self-care."]},
"pippa":{"classic_lemonade":["Lemonade, please! I'm grading it, no pressure."],"strawberry_lemonade":["Strawberry lemonade, extra berries. It's for science."],"pink_lemonade":["Pink lemonade, please. I'm comparing it to regular. Professionally."],"mint_lemonade":["Mint lemonade. Extra sour if you can. I'm brave."],"honey_lavender_lemonade":["One fancy one. The lavender. I'm expanding my palate."]},
"rocco":{"mint_lemonade":["Mint lemonade, lots of ice, lots of zing! It's a long block!"],"iced_coffee":["Iced coffee to go! Biscuit the beagle's waiting at number 12."],"classic_lemonade":["Plain lemonade today. Keeping it classic, like a first-class stamp."],"black_coffee":["Black coffee to go, buddy. Route waits for no one."]},
"wren":{"honey_lavender_lemonade":["Honey-lavender, please. It sounds like a poem already."],"cappuccino":["A cappuccino, if it's no trouble. I like a quiet foam."],"seasonal_special":["The seasonal one, please. I write a poem for each one."],"latte":["Latte, please. The foam is the poem."],"iced_tea_lemonade":["Iced tea lemonade, gently made. I'll write about the rain."],"pink_lemonade":["Pink lemonade, please. It's a lovely color to think in."]},
}
order_lines["product_specific"] = SPEC2
for cid in O:
    order_lines["generic"][cid] = [l for l in O[cid] if "{product}" in l]
_cov = {p: sum(p in v for v in SPEC2.values()) for p in DRINKS}
GEN_ORDERS = {p: [f"One {NAMES[p]}, please.", f"Could I get a {NAMES[p]}?"] for p in DRINKS}
GEN_ORDERS.update({
 "pink_lemonade":["One pink lemonade, please. The pretty one!"],"espresso":["Just a quick espresso, please."],
 "iced_coffee":["Iced coffee, please. It's warm out!"],"seasonal_special":["I'll try the seasonal special. What is it today?"],
 "cappuccino":["Cappuccino, please. Nice foam if you can."],"mocha":["Mocha, please. It's a treat day."]})
order_lines["any_customer_product"] = GEN_ORDERS
for p in DRINKS: assert _cov[p] >= 1 or p in GEN_ORDERS, p
order_lines["_meta"]["coverage_customer_specific"] = _cov

# new banter about the new drinks
B2 = [
 (["pippa","dottie"],["stand_type:lemonade"],["Pink or regular? I need data.","Regular, dear. Pink is for celebrations.","What are we celebrating?","Tuesday."]),
 (["rocco","theo"],["stand_type:lemonade"],["Mint lemonade, Theo. Wakes you right up!","I'm trying to go to sleep, Rocco.","Oh. Then don't drink it fast."]),
 (["keyclackr","steve"],["stand_type:coffee"],["Espresso is the 60% keyboard of coffee.","Small but complete?","Exactly. No wasted keys."]),
 (["wren","lamp_lady"],["stand_type:lemonade"],["Honey-lavender tastes purple.","Oh, purple is a lovely wattage.","Is wattage a flavor?","Today it is!"]),
 (["dottie","rocco"],["stand_type:coffee"],["Have you tried the mocha, Rocco?","Coffee AND chocolate? On a route day?","It's a delivery of joy, sweetie.","Signed for it."]),
 (["theo","wren"],["stand_type:coffee"],["Cappuccino foam is basically a nap.","Then you're drinking a nap.","Don't tell my supervisor."]),
 (["pippa","rocco"],["stand_type:lemonade"],["Strawberry is the best one. Fact.","Mint's got more zing!","Zing isn't a category.","It is on my route."]),
 (["steve","lamp_lady"],["stand_type:coffee"],["The vanilla latte is very... organized.","Vanilla is just soft lighting for coffee, dear.","I'll note that in my binder."]),
 (["keyclackr","rocco"],["stand_type:coffee"],["Iced coffee hits different at noon.","Cold brew, hot route. Perfect match.","Ice clinks like a keypress.","Everything does, to you."]),
 (["lamp_lady","dottie"],["rain","stand_type:lemonade"],["Iced tea lemonade in the rain? Bold!","Tea is for rain, ice is for courage.","Dottie, you're a poet.","Don't tell Wren. They'll want royalties."]),
 (["wren","steve"],["stand_type:coffee"],["Have you seen the seasonal board?","I photograph it every season. For the archive.","You have an archive?","Three binders. Color-coded."]),
 (["theo","pippa"],["stand_type:lemonade"],["Is pink lemonade healthier?","No. But it's happier.","That's medically fine by me."]),
 (["dottie","keyclackr"],["stand_type:coffee"],["Sweetie, that espresso is the size of a thimble.","Tiny cup, big power.","Like me in my crossing guard days.","Respect, Dottie."]),
 (["rocco","wren"],["morning","stand_type:coffee"],["Black coffee, then 9,000 steps.","Black coffee, then one quiet poem.","Same coffee, different miles.","Write that one down."]),
]
B.extend(B2)
banter["exchanges"]=[{"id":f"banter_{i+1:02d}","speakers":s,"context":c,"lines":[{"speaker":s[j%2],"text":t} for j,t in enumerate(L)]} for i,(s,c,L) in enumerate(B)]
banter["_meta"]["drink_banter_ids"]=[f"banter_{i+1:02d}" for i in range(len(B)-len(B2),len(B))]

# --- v2.1 (Oct 23): appearance/unlock gating from customer_events.json customers block ---
_CE = {c["id"]: c for c in json.load(open("/workspace/game/customer_events.json"))["customers"]}
_LV = lambda s: int(str(s).lstrip("L"))
UNLOCK = {d["id"]: _LV(d["unlock_level"]) for d in _DU["drinks"]}
for c in customers["customers"]:
    ce = _CE[c["id"]]
    c.update(appears_from=ce["appears_from"], favourite_drink=ce["favourite_drink"],
             favourite_unlock=ce["favourite_unlock"], slice_order=ce["slice_order"])
customers["_meta"]["gating"] = ("A customer appears from appears_from. Until favourite_drink unlocks they order slice_order "
    "(e.g. Wren appears at L6 and orders black_coffee until honey_lavender_lemonade unlocks at L8). "
    "Orders and banter are only picked when every drink they mention is unlocked.")
assert set(_CE) == {c[0] for c in C} and "bea" not in _CE

# Wren: black coffee voice for L6-L7, before honey-lavender
SPEC2["wren"]["black_coffee"] = ["Black coffee, please. Plain is a kind of poem too.",
    "A black coffee, if it's no trouble. I'm saving my fancy words for later.",
    "Black coffee. Dark as the line before a new stanza."]
SPEC2["steve"].setdefault("black_coffee", []).append("Black coffee, please. I'll acquire a second one if this one's a five-stapler.")
# Product-specific order lines are only valid once the drink is unlocked AND the customer is around.
order_lines["product_specific"] = SPEC2
# Level-gated order lines (same min_level/max_level convention as banter.json). A gated entry that applies
# (min_level <= level <= max_level when present) REPLACES product_specific[customer][product] for that level;
# it is never added alongside it (customer_manager.gd order_line: gated wins). Rocco's strawberry_lemonade
# is covered at every level (L1-L4 mint-in-the-mail, L5+ mint-delivered), so he has no plain strawberry line
# in product_specific (removed Oct 23 so no consumer can roll it alongside the gated line).
order_lines["product_specific_gated"] = [
 {"customer": "rocco", "product": "strawberry_lemonade", "min_level": "L1", "max_level": "L4",
  "text": "Strawberry lemonade, chief. My mint's still in the mail.",
  "why": "Mint lemonade unlocks at L5; the joke is stale after that."},
 {"customer": "rocco", "product": "strawberry_lemonade", "min_level": "L5",
  "text": "Strawberry lemonade, chief. The mint finally got delivered, but I'm loyal to the berry."}]
order_lines["_meta"]["gated_rule"] = ("product_specific_gated: when an entry for customer+product applies at the current level "
    "(min_level/max_level inclusive), pick only from the applicable gated entries; they REPLACE product_specific/generic for that order, "
    "never add to them. Rocco strawberry_lemonade: L1-L4 'My mint's still in the mail', L5+ 'The mint finally got delivered'.")
order_lines["_meta"]["unlock_levels"] = UNLOCK
order_lines["_meta"]["customer_appears_from"] = {k: v["appears_from"] for k, v in _CE.items()}
order_lines["_meta"]["order_rule"] = ("Pick product_specific[customer][drink] only if drink unlock_level <= current level. "
    "Before a customer's favourite_drink unlocks, they order their slice_order. Wren: black_coffee only until L8.")
for cid, pm in SPEC2.items():
    for p in pm: assert p in UNLOCK, (cid, p)
assert "black_coffee" in SPEC2["wren"]

# Steve's legacy sweet_coffee line was remapped onto black_coffee; give black coffee its own okay line
CVP["steve"]["black_coffee"] = {"okay": "Three and a half staples. Standard issue. Dependable."}
CVP["wren"]["black_coffee"] = {"great": "Dark and plain and warm / nothing extra, nothing missed / the morning, poured out",
                               "off": "Thin as early light / still, it found my hands. Thank you / for pouring the dawn"}

# legacy sweet_coffee banter -> black coffee
for s, c, L in B:
    if L and L[0] == "Coffee with sugar, Steve?":
        L[:] = ["Black coffee again, Steve?", "Always. No frills.", "Harold took two sugars.", "Harold was a brave man."]

# two more drink banters for Wren's black-coffee era
B3 = [
 (["wren","theo"],["stand_type:coffee","morning"],["You take it black too?","Black and fast. You?","Black and slow. I'm waiting for the lavender.","Then we'll both be here a while."]),
 (["steve","wren"],["stand_type:coffee"],["Black coffee is the standard stapler of drinks.","Then honey-lavender is the fancy one with the swirl.","You understand me.","I write it all down."]),
]
B.extend(B3)

# banter drink requirements + min level (customers present AND mentioned drinks unlocked)
BANTER_DRINKS = {
 "Pink or regular? I need data.":["pink_lemonade","classic_lemonade"], "Mint lemonade, Theo. Wakes you right up!":["mint_lemonade"],
 "Espresso is the 60% keyboard of coffee.":["espresso"], "Honey-lavender tastes purple.":["honey_lavender_lemonade"],
 "Have you tried the mocha, Rocco?":["mocha"], "Cappuccino foam is basically a nap.":["cappuccino"],
 "Strawberry is the best one. Fact.":["strawberry_lemonade","mint_lemonade"], "The vanilla latte is very... organized.":["vanilla_latte"],
 "Iced coffee hits different at noon.":["iced_coffee"], "Iced tea lemonade in the rain? Bold!":["iced_tea_lemonade"],
 "Have you seen the seasonal board?":["seasonal_special"], "Is pink lemonade healthier?":["pink_lemonade"],
 "Sweetie, that espresso is the size of a thimble.":["espresso"], "Black coffee, then 9,000 steps.":["black_coffee"],
 "You take it black too?":["black_coffee","honey_lavender_lemonade"], "Black coffee is the standard stapler of drinks.":["black_coffee"],
 "Black coffee again, Steve?":["black_coffee"],
}
def _ctx_drinks(c):
    return ["black_coffee"] if "stand_type:coffee" in c else (["classic_lemonade"] if "stand_type:lemonade" in c else [])
_ex = []
for i, (s, c, L) in enumerate(B):
    req = sorted(set(BANTER_DRINKS.get(L[0], []) + _ctx_drinks(c)))
    # the 'waiting for lavender' banter is the one exception: it is FOR the pre-L8 window
    if L[0] == "You take it black too?": req = ["black_coffee"]
    lvl = max([_LV(_CE[x]["appears_from"]) for x in s] + [UNLOCK[d] for d in req])
    e = {"id": f"banter_{i+1:02d}", "speakers": s, "context": c, "requires_drinks": req, "min_level": f"L{lvl}",
         "lines": [{"speaker": s[j % 2], "text": t} for j, t in enumerate(L)]}
    if L[0] == "You take it black too?": e["max_level"] = "L7"
    _ex.append(e)
banter["exchanges"] = _ex
banter["_meta"]["drink_banter_ids"] = [f"banter_{i+1:02d}" for i in range(len(B)-len(B2)-len(B3), len(B))]
banter["_meta"]["gating"] = "Pick an exchange only if current level >= min_level (and <= max_level when present)."
assert len(B2) + len(B3) >= 10

# alias + bands on reviews
reviews["_meta"]["tier_alias"] = {"poor": "off"}
reviews["_meta"]["alias_note"] = "Tier was called 'poor' in v1; code (products.json quality.tiers) uses 'off'. Treat 'poor' as an alias of 'off'."
reviews["_meta"]["quality_bands"] = {"great": ">=80", "okay": "50-79", "off": "<50"}

# a/an fix for any_customer_product
def _art(n): return ("an " if n[0].lower() in "aeiou" else "a ") + n
for p, ls in GEN_ORDERS.items():
    GEN_ORDERS[p] = [l.replace(f"a {NAMES[p]}", _art(NAMES[p])) for l in ls]
order_lines["any_customer_product"] = GEN_ORDERS

# event cast: display names for every non-customer character id used in customer_events.json
EVENT_CAST = {
 "neighbor_kid":"Neighbor kid","dana":"Dana (player character, name only)",
 "priya_okafor":"Priya Okafor","biscuit":"Biscuit (the cat)","cyclist_from_l3":"Soggy cyclist (L3 rainy drive)",
 "grandpa_train_shop":"Grandpa Walt Hale","pond_jogger":"Pond jogger (L5)","duckling":"Duckling","delbert_finch":"Delbert Finch",
 "retiring_dentist":"Dr. Barry Plum","gerald":"Gerald (the fish)","npc_vendor":"Market vendor (L8)","npc_architect":"Imogen Vance-Okoro",
 "agnes_pell":"Ms. Agnes Pell","juno_park":"Juno Park","record_store_owner":"Lou Marchetti",
 "rosa_pemberton":"Rosa Pemberton","ray_pemberton":"Ray Pemberton","coworker_npc":"Co-worker (L16 suite)",
 "food_critic":"Quiet critic","marge_holloway":"Marge 'Mile Marker' Holloway",
 "queue_npc":"Queue customer (generic)","customer":"Any customer (generic)",
 "regular":"Any returning regular (generic)","narration":"Scene text (no speaker)"}
customers["event_cast"] = EVENT_CAST
customers["_meta"]["event_cast_note"] = "event_cast is NOT a customer roster; it names the one-off NPCs used as speakers in customer_events.json / customer_event_lines.json."
order_lines["_meta"]["customer_order_gates"] = {"wren": {"before_level": "L8", "only": ["black_coffee"],
    "why": "Wren appears at L6 (coffee counter) and orders black coffee until honey_lavender_lemonade unlocks at L8."}}
