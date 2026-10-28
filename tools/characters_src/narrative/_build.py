import json, os
D = os.path.dirname(os.path.abspath(__file__))
PRODUCTS = ["black_coffee","latte","sweet_coffee","lemonade","iced_lemonade"]
SRC = "/workspace/game/prototypes/data/shop.json (recipes, P1.14 Director TUNE draft)"
meta = {"version":1,"phase":"post_slice","product_source":SRC,"product_ids":PRODUCTS,"product_ids_provisional":False,
        "tone":"Cozy sitcom. Customers are kind. Poor drinks get gentle, funny feedback and the customer still pays."}

C = [
 ("steve","Steve (StaplerSteve88)","Cardigan, lanyard, a stapler holstered like a sheriff's badge.",
  "The market regular in person. Earnest collector of office supplies, polite to a fault, tips in exact change.",
  ["black_coffee","sweet_coffee"],{"sweet":"medium","sour":"low","ice":"none","foam":"none","strength":"high","temperature":"hot"},
  ["Rates every drink in staples out of five.","Asks if the cups are stackable.","Says 'acquired' instead of 'bought'."],
  "they/them"),
 ("lamp_lady","Lorna (Lamp_Lady)","Big sunhat, bigger tote bag, always backlit somehow.",
  "The lamp-trading regular. Sunny optimist who describes every drink in terms of lighting.",
  ["iced_lemonade","latte"],{"sweet":"high","sour":"medium","ice":"high","foam":"high","strength":"low","temperature":"cold"},
  ["Holds cups up to the light before sipping.","Calls good drinks 'warm wattage'."],
  "she/her (explicit: 'Lamp Lady' is her chosen handle)"),
 ("keyclackr","Kit (KeyClackr)","Wrist braces, mechanical keyboard in a backpack, typing on the counter.",
  "The keyboard enthusiast. Fast talker, mild typo in everything they say, generous reviewer.",
  ["black_coffee","latte"],{"sweet":"low","sour":"low","ice":"low","foam":"medium","strength":"high","temperature":"hot"},
  ["Drums fingers in actual keyboard rhythms.","Reviews drinks like switch types: 'tactile', 'linear'."],
  "they/them"),
 ("dottie","Dottie Ruiz","Retired crossing guard, reflective vest worn 'for fashion now'.",
  "Grandmotherly traffic-controller of the line. Waves everyone forward. Has opinions on lemon wedges.",
  ["lemonade","sweet_coffee"],{"sweet":"high","sour":"medium","ice":"low","foam":"none","strength":"medium","temperature":"warm"},
  ["Says 'slow down, sweetie' to the espresso machine.","Tells you about her late husband's lemon tree."],
  "she/her (explicit)"),
 ("theo","Theo Nakamura","Scrubs, sleepy eyes, comfy sneakers, a single heroic yawn.",
  "Night-shift nurse heading home. Gentle, dry humor, deeply grateful for anything warm.",
  ["latte","black_coffee"],{"sweet":"low","sour":"none","ice":"none","foam":"high","strength":"high","temperature":"hot"},
  ["Orders a coffee to sleep after, somehow.","Thanks you twice, once for each eye that's open."],
  "they/them"),
 ("pippa","Pippa Mensah","Nine years old, clipboard, sticker-covered glasses.",
  "Junior lemonade critic and future business mogul. Serious notes, enormous smiles.",
  ["lemonade","iced_lemonade"],{"sweet":"high","sour":"high","ice":"high","foam":"none","strength":"low","temperature":"cold"},
  ["Grades with stickers: gold star, silver star, 'nice try' frog.","Asks about your profit margins."],
  "she/her (explicit, kid character)"),
 ("rocco","Rocco Delgado","Mail carrier shorts in every season, satchel, sunburned nose.",
  "Chatty route-runner who knows every dog by name. Drinks fast, talks faster, never in a bad mood.",
  ["iced_lemonade","black_coffee"],{"sweet":"medium","sour":"high","ice":"high","foam":"none","strength":"medium","temperature":"cold"},
  ["Delivers neighborhood gossip like parcels.","Times his sips to his step counter."],
  "he/him (explicit)"),
 ("wren","Wren Albright","Hand-knit scarf, notebook, ink on one finger.",
  "Quiet poet who writes a tiny haiku about every drink. Soft-spoken, notices everything.",
  ["latte","lemonade"],{"sweet":"medium","sour":"low","ice":"low","foam":"high","strength":"medium","temperature":"warm"},
  ["Leaves haiku on napkins as a tip.","Counts the bubbles in the foam."],
  "they/them"),
]
# is_regular defaults to False everywhere; the 8 regulars are set True explicitly here.
IS_REGULAR = {"steve": True, "lamp_lady": True, "keyclackr": True, "dottie": True,
              "theo": True, "pippa": True, "rocco": True, "wren": True}
REGULAR_IDS = [i for i, v in IS_REGULAR.items() if v]
assert sorted(REGULAR_IDS) == sorted(c[0] for c in C), "IS_REGULAR must list exactly the 8 regulars in C"
customers = {"_meta":{**meta,"taste_scale":["none","low","medium","high"],"temperature_scale":["cold","warm","hot"],
  "cameo_note":"steve, lamp_lady, keyclackr are the market regulars StaplerSteve88, Lamp_Lady, KeyClackr appearing in person."},
 "customers":[{"id":i,"name":n,"is_regular":IS_REGULAR.get(i, False),"look":l,"personality":p,"favorite_products":f,"taste":t,"quirks":q,"pronouns":pr} for i,n,l,p,f,t,q,pr in C]}

O = {
"steve":["One {product}, please. For the collection. Of memories.","I'd like to acquire a {product}.","Could I trouble you for a {product}? Strong as a heavy-duty staple.","Black coffee, please. No frills, like a good standard stapler.","Coffee with sugar, please. Exactly one sweetness unit."],
"lamp_lady":["One {product}, sweetie! Make it glow.","Iced lemonade, extra ice. I want it to sparkle in the sun!","A latte, please. Lots of foam. Soft lighting for my tummy.","Ooh, what's brightest today? Surprise me with a {product}."],
"keyclackr":["{product}, plz. Sorry. Please. Typing habit.","Black coffee. Strong. Like a clicky blue switch.","Latte me, friend. Medium foam, high RPM.","One {product}, thx. Thanks. I'm working on it."],
"dottie":["Slow and steady, dear. One {product}.","Lemonade, please, and don't be shy with the sugar.","Coffee with sugar, sweetie. Two scoops' worth of love.","Could I get a {product}? Then go help that nice young man behind me."],
"theo":["One {product}... please. Sorry. Long night.","Latte, hot as you can, extra foam. I'm basically a cloud now.","Black coffee, please. I'm going to drink it and then sleep. Don't ask.","{product}, please. You're a lifesaver. Professionally speaking."],
"pippa":["One {product}, please. This is for research.","Lemonade, please! I'm grading it, no pressure.","Iced lemonade, extra ice and extra sour. I'm brave.","I'll have a {product}. What's your cost per cup? Just curious."],
"rocco":["Quick {product} for the route, buddy!","Iced lemonade, lots of ice, lots of zing. It's a long block!","Black coffee to go. Biscuit the beagle's waiting at number 12.","One {product}, special delivery to me!"],
"wren":["A {product}, if it's no trouble.","Latte, please. The foam is the poem.","Lemonade, gently made. I'll write about it.","Could I have a {product}? Take your time. I'll watch the clouds."],
}
order_lines = {"_meta":{**meta,"placeholders":{"{product}":"display name of the ordered product"},
  "note":"generic lines use {product}; product_specific lines are only picked when that product is ordered."},
 "generic":{k:[l for l in v if "{product}" in l] for k,v in O.items()},
 "product_specific":{}}
SPEC = {
"steve":{"black_coffee":"Black coffee, please. No frills, like a good standard stapler.","sweet_coffee":"Coffee with sugar, please. Exactly one sweetness unit."},
"lamp_lady":{"iced_lemonade":"Iced lemonade, extra ice. I want it to sparkle in the sun!","latte":"A latte, please. Lots of foam. Soft lighting for my tummy."},
"keyclackr":{"black_coffee":"Black coffee. Strong. Like a clicky blue switch.","latte":"Latte me, friend. Medium foam, high RPM."},
"dottie":{"lemonade":"Lemonade, please, and don't be shy with the sugar.","sweet_coffee":"Coffee with sugar, sweetie. Two scoops' worth of love."},
"theo":{"latte":"Latte, hot as you can, extra foam. I'm basically a cloud now.","black_coffee":"Black coffee, please. I'm going to drink it and then sleep. Don't ask."},
"pippa":{"lemonade":"Lemonade, please! I'm grading it, no pressure.","iced_lemonade":"Iced lemonade, extra ice and extra sour. I'm brave."},
"rocco":{"iced_lemonade":"Iced lemonade, lots of ice, lots of zing. It's a long block!","black_coffee":"Black coffee to go. Biscuit the beagle's waiting at number 12."},
"wren":{"latte":"Latte, please. The foam is the poem.","lemonade":"Lemonade, gently made. I'll write about it."},
}
order_lines["product_specific"]={k:{p:[l] for p,l in v.items()} for k,v in SPEC.items()}
order_lines["product_specific"]["steve"]["latte"]=["A latte, please. I hear the foam holds its shape like a good binder clip."]
order_lines["product_specific"]["rocco"]["lemonade"]=["Plain lemonade today. Keeping it classic, like a first-class stamp."]

R = {
"black_coffee":{"great":["Bold, smooth, not a hint of bitter. Perfect.","That's a proper cup. Marge would rate it five mile markers.","Strong enough to lift a couch. Thank you!","Rich and hot. My whole morning just straightened up.","Not too bitter, not too thin. Just right."],
 "okay":["A touch thin, but it's warm and honest.","Little bitter at the edge. I kind of like it.","Could stand one more scoop of beans. Still nice!","Solid. A dependable mid-size box of a coffee."],
 "off":["This coffee is... shy. Very shy. I'll cheer it on.","I think this is beans' cousin. Still paying!","Tastes like coffee heard about from a friend. Thanks anyway!","Bold choice, adding no bold. Here's your money, friend.","Bit bitter! It's like a pep talk from a grumpy uncle."]},
"latte":{"great":["Perfect foam. I could nap on it.","Silky milk, smooth shot. A hug in a cup.","Foam holds its shape like a good moving box. Wonderful.","Creamy, warm, balanced. You've got the touch.","That milk was steamed with love."],
 "okay":["Foam's a little flat, but the flavor's lovely.","Bit milky for me. Still very cozy.","Could be a smidge hotter. I'll drink fast!","Nice! The shot's a little quiet under all that milk."],
 "off":["The foam took the day off. Fair enough, honestly.","This is mostly milk with a rumor of espresso. Cute!","Lukewarm latte, but warm heart. Here you go.","I think the milk and coffee haven't been introduced yet.","Flat as a packed box. Still drinking it. Still paying!"]},
"sweet_coffee":{"great":["Sweet, but the coffee still talks. Perfect balance.","Just enough sugar to make me hum.","Like a warm cookie in drink form. Thank you!","Sugar dissolved all the way. A pro's cup.","That's my grandma's coffee. Highest compliment."],
 "okay":["A little extra sweet. My teeth said hello.","Could use a pinch more sugar. Still nice!","Sugar's hiding at the bottom. A treasure hunt!","Good! A bit more coffee than sugar today."],
 "off":["Is this... dessert? I'm not complaining. Paying!","I asked for sugar, and I got a sugar party. Fun!","Not a grain of sweetness. A very serious coffee.","It's syrup with ambition. I respect it.","My spoon is standing up. Impressive, honestly."]},
"lemonade":{"great":["Sweet and sour in perfect harmony!","Tastes like a summer afternoon. Wow.","Fresh-squeezed, you can tell. Wonderful.","Just enough pucker. Bright and happy.","That's a front-porch lemonade. Perfect."],
 "okay":["Needs a squeeze more lemon, but it's sweet!","Bit sour! My face did a little dance.","Little watery, but refreshing.","Good! A pinch more sugar and it's legendary."],
 "off":["This is sugar water that once saw a lemon. Lovely try!","My whole face folded up. Like a cardboard box! Thanks!","Mostly water. Very hydrating, though!","So sour I can hear colors. Paying anyway!","I think the lemon is still in the bag. Sweet effort."]},
"iced_lemonade":{"great":["Ice-cold and zippy. Perfect!","Just the right amount of ice. Chef's kiss.","Brain freeze, but the good kind.","Crisp, cold, and bright. Summer in a cup.","Ice clinks like applause. Wonderful."],
 "okay":["Too much ice, but what's there is tasty!","Ice is melting a bit fast. Gulping now!","Needs a squeeze more lemon under all that chill.","Nice! Could be a touch colder."],
 "off":["This is an ice sculpture with a lemonade hobby. Fun!","Not much ice. A lukewarm adventure! Paying!","I got one ice cube. We're very close now.","Mostly ice! It's a glacier. I'll wait for it.","Lemon went missing in the ice storm. Still a sweetheart."]},
}
CV = {
"steve":{"great":"Five staples out of five. Acquired with joy.","okay":"Three and a half staples. Solid binding.","off":"Two staples. But they're good staples. Here's exact change!"},
"lamp_lady":{"great":"Warm wattage, darling! This glows!","okay":"Soft lighting. A little dim, still pretty.","off":"Bit of a flicker in this one! I adore a fixer-upper. Paying!"},
"keyclackr":{"great":"Tactile perfection. Zero input lag.","okay":"Linear. Smooth enough. 7/10, wuold sip again.","off":"Lots of key chatter in this cup. Still a fan! Payign! Paying."},
"dottie":{"great":"Oh, sweetie, that's just how Harold made it.","okay":"Close enough for Sunday, dear.","off":"Well, it's wet and it's warm-ish. Here's a little extra for trying."},
"theo":{"great":"Clinically excellent. I may cry.","okay":"Vitals stable. Drink is fine. So am I.","off":"I've had worse at 4 a.m. Many times. Thank you, truly."},
"pippa":{"great":"GOLD STAR. I'm writing this down.","okay":"Silver star. Room to grow!","off":"You get the 'nice try' frog. He's very proud of you."},
"rocco":{"great":"Signed, sealed, delicious!","okay":"Arrived a little dented, but it got here!","off":"Return to sender? Nah, I'll keep it. Paid in full!"},
"wren":{"great":"Warm between my palms / a small sun I can hold close / thank you, morning hands","okay":"Almost there, just like / the first warm day of April. / Still, I'm glad of it.","off":"Brave little cup, you / tried your best and so did I. / Here, for your effort."},
}
CVP = {
"theo":{"latte":{"great":"This foam is a pillow. Goodnight. Kidding. Thank you."}},
"lamp_lady":{"iced_lemonade":{"great":"Look how the ice catches the light!","off":"Not much sparkle, but I'll bring my own!"}},
"pippa":{"lemonade":{"off":"Needs more lemon. I'll make you a chart. Free!"}},
"rocco":{"iced_lemonade":{"great":"Coldest stop on my whole route!"}},
"dottie":{"lemonade":{"great":"Harold's lemon tree would be proud."}},
"keyclackr":{"black_coffee":{"great":"Clicky. Bold. Blue switch energy."}},
"steve":{"sweet_coffee":{"okay":"Exactly 1.3 sweetness units. Close!"}},
"wren":{"latte":{"great":"Soft foam, like fresh snow / a little heart drawn in white / I'll keep this moment"}},
}
reviews = {"_meta":{**meta,"tiers":["great","okay","off"],"tier_alias":{"poor":"off"},"customer_still_pays":True,
  "selection":"Pick per_customer_product line if present, else 40% per_customer tier line, else product tier line."},
 "by_product":R,"per_customer":CV,"per_customer_product":CVP}

B = [
 (["dottie","rocco"],["line_wait","morning"],["Morning, Rocco! You're early.","Dottie! Dogs were in a good mood. Route flew by.","Did Pepper bark at you again?","Only to say hello. We're friends now."]),
 (["steve","keyclackr"],["line_wait"],["KeyClackr? In person?","StaplerSteve88! Your stapler's even shinier IRL.","I polish it on Tuesdays.","Respect."]),
 (["lamp_lady","wren"],["rain"],["Isn't the rain lovely? Everything's softly lit.","It sounds like the sky is whispering.","Write that down, hon.","I already did."]),
 (["pippa","theo"],["stand_type:lemonade"],["Excuse me, how would you rate this stand?","Five stars. I'm too tired to be critical.","That's not scientific.","Neither is my sleep schedule."]),
 (["theo","dottie"],["morning","stand_type:coffee"],["Coffee to sleep. Don't judge me.","Sweetie, I'd never. You go rest.","Thanks, Dottie."]),
 (["rocco","pippa"],["stand_type:lemonade"],["Pippa! Running a rival stand yet?","Not yet. I'm doing market research.","Smart kid. Watch the ice ratio.","Already noted."]),
 (["keyclackr","wren"],["line_wait"],["What are you writing?","A haiku about the line.","How many syllables is 'clack'?","One. It's a good one."]),
 (["steve","lamp_lady"],[],["Lamp_Lady! I almost bought that brass lamp.","I know, I outbid you. Sorry, dear.","It's okay. It looks better in your window.","It really does."]),
 (["dottie","pippa"],["line_wait"],["Let the grown-ups go first?","Customers are customers, ma'am.","Fair enough. Go ahead, boss."]),
 (["rocco","theo"],["rain","stand_type:coffee"],["Rain on the route today. Soaked socks.","Warm drink, dry socks, then sleep. Doctor's orders.","You're a nurse, not a doctor.","Nurse's orders, then. Stronger."]),
 (["wren","dottie"],["morning"],["Your vest is very bright.","Thirty years of crossing guard. Keeps the habit.","It's like wearing a sunrise.","Oh, you're a sweet one."]),
 (["keyclackr","pippa"],["stand_type:lemonade"],["Is the lemonade good?","Silver star so far.","High bar.","I'm a professional."]),
 (["lamp_lady","rocco"],["morning"],["Any packages for me today, Rocco?","Two! One lamp-shaped, one... also lamp-shaped.","My favorite shape!"]),
 (["steve","theo"],["line_wait","stand_type:coffee"],["You look tired. Want my spot?","You're a good person, Steve.","I'm StaplerSteve88 online.","You're a good person online too."]),
 (["pippa","wren"],[],["Are you a writer?","I try to be.","Write about my stand someday. When I have one.","It'll be the first poem in the book."]),
 (["dottie","keyclackr"],["line_wait"],["You're tapping the counter, dear.","Sorry! Keyboard hands.","Tap me a little waltz, then.","...Okay, that was fun."]),
 (["rocco","steve"],[],["Steve, your stapler order shipped!","The heavy-duty one?","The heavy-duty one.","Best day of the week."]),
 (["theo","wren"],["rain"],["Rain makes me sleepy.","Rain makes me write.","Want to trade?","Not today."]),
 (["lamp_lady","pippa"],["stand_type:lemonade"],["What a darling clipboard!","Thank you. It's for business.","Every great empire starts with a clipboard!"]),
 (["keyclackr","rocco"],["morning","stand_type:coffee"],["How many steps so far today?","Eight thousand and the sun's barely up.","I've done eight thousand keystrokes.","Same energy."]),
 (["dottie","steve"],["stand_type:coffee"],["Coffee with sugar, Steve?","Always. One sweetness unit.","Harold used two.","Harold was a brave man."]),
 (["wren","rocco"],["line_wait"],["Do the dogs on your route have names?","Every single one. Biscuit's my favorite.","Biscuit the cat?","Biscuit the beagle. Different Biscuit. Small town, big name."]),
 (["theo","lamp_lady"],["morning"],["Morning, Lorna. Already bright out.","It's always bright when you've got good company!","...Too bright. I'm going home to sleep.","Sweet dreams, darling!"]),
 (["pippa","steve"],["line_wait"],["Why do you carry a stapler?","In case something needs holding together.","Like what?","Life, mostly."]),
 (["keyclackr","lamp_lady"],["rain"],["Rain's kinda nice with headphones.","Rain's nice with a lamp on!","You'd put a lamp on in the rain?","Especially in the rain."]),
 (["rocco","dottie"],["stand_type:lemonade"],["Dottie, try it iced!","Ice hurts my teeth, sweetie.","More zing for me, then!"]),
 (["wren","steve"],["stand_type:coffee"],["How's your coffee?","Four staples.","Is that good?","Out of five, it's very good."]),
 (["theo","keyclackr"],["line_wait"],["Typing on the counter?","Muscle memory. Sorry.","No, it's soothing. Like a heart monitor.","...Thanks?"]),
 (["pippa","rocco"],["rain"],["Do you deliver in the rain?","Rain or shine, kid!","And snow?","Snow's my favorite. The dogs bounce."]),
 (["lamp_lady","dottie"],["stand_type:coffee"],["Dottie, is that a new vest?","Same vest, new sparkle sticker!","Oh, it catches the light beautifully!"]),
 (["wren","keyclackr"],["morning"],["You're up early.","Never went to bed. Building a keyboard.","Is it done?","It's never done. That's the fun."]),
 (["steve","pippa"],["stand_type:lemonade"],["How's the lemonade, critic?","Gold star. Don't tell them, it'll go to their head.","Your secret's safe with me.","Thank you, stapler man."]),
 (["dottie","theo"],["rain"],["You'll catch a cold, dear.","I work in a hospital. Colds are scared of me.","Well, take my umbrella anyway.","...Thank you, Dottie."]),
 (["rocco","lamp_lady"],["line_wait"],["Another lamp in the bag, Lorna?","Just a tiny one!","It's glowing.","It's on. I couldn't wait."]),
]
banter = {"_meta":{**meta,"context_tags":["line_wait","rain","morning","stand_type:coffee","stand_type:lemonade"],
  "format":"lines alternate speakers in order: speakers[0], speakers[1], speakers[0], ... Empty context = any time."},
 "exchanges":[{"id":f"banter_{i+1:02d}","speakers":s,"context":c,
   "lines":[{"speaker":s[j%2],"text":t} for j,t in enumerate(L)]} for i,(s,c,L) in enumerate(B)]}

I = {
"steve":["Do they sell staples here?","Four staples, maybe five...","Cup looks stackable.","Exact change: ready.","Shiny stapler, shiny day.","Should I start a cup collection?"],
"lamp_lady":["That window light is perfect.","Is that bulb warm white?","Sunhat: on. Mood: lit.","Ooh, sparkly ice!","Every room needs one more lamp.","Golden hour all day here."],
"keyclackr":["Clack clack clack...","Linear or tactile mood today?","Need more keycaps. Always.","Coffee = keyboard fuel.","WPM going up, I can feel it.","Is that a typo on the sign?"],
"dottie":["Slow down, everybody. No rush.","Harold loved lemonade.","Vest still fits!","Such a nice young barista.","Two sugars, maybe three...","What a lovely little line."],
"theo":["So... sleepy...","Coffee, then bed. Yes.","Twelve hours. Worth it.","Is it morning or night?","Warm cup. Warm blanket. Soon.","Everyone's being so nice."],
"pippa":["Noting the cup size...","Gold star potential.","Sour? Bring it on.","I'll charge 25 cents more.","Margins, margins, margins.","Need more stickers."],
"rocco":["8,412 steps!","Biscuit's waiting at #12.","Zing! I need zing.","Package for the bakery later.","Sun's out, shorts out.","Who's got gossip today?"],
"wren":["Foam like a cloud...","Five, seven, five...","The rain has a rhythm.","Counting bubbles. Seven.","Ink on my finger again.","This line is a little poem."],
}
G = ["Smells amazing in here.","What a cozy little place.","No rush. Nice.","Ooh, what should I get?","Love that menu board.","Perfect day for a drink.","I should come here more.","Is that cat around?","Mmm, fresh lemons.","That grinder sounds happy.","Nice music.","Everyone's so friendly here.","Hope the ice holds out!","Warm cup, warm heart.","Today's a good day."]
idle = {"_meta":{**meta,"max_chars":40},"per_customer":I,"generic":G}

exec(open(os.path.join(D,"_ext_drinks.py")).read())
exec(open(os.path.join(D,"_event_cast.py")).read())
exec(open(os.path.join(D,"_polish.py")).read())
exec(open(os.path.join(D,"_haiku.py")).read())   # Wren haiku: 5-7-5 table, '\n' storage at dump time
out = {"customers":customers,"order_lines":order_lines,"reviews":reviews,"banter":banter,"idle_thoughts":idle}
for k,v in out.items():
    json.dump(haiku_store(v),open(f"{D}/{k}.json","w"),indent=2,ensure_ascii=False)
# checks
for k,v in I.items(): assert len(v)>=6 and all(len(x)<=40 for x in v),k
assert all(len(x)<=40 for x in G) and len(G)==15
assert len(B)>=32 and all(2<=len(b[2])<=4 for b in B)
for k in O: assert len(O[k])>=4
ids={c[0] for c in C}
for b in B: assert set(b[0])<=ids
for c in C: assert set(c[4])<=set(PRODUCTS)
# md companions
def md(name,title,body): open(f"{D}/{name}.md","w").write(f"# {title}\n\nProduct source: `{SRC}`. Ids: {', '.join(PRODUCTS)}.\n\n"+body)
md("customers","Stand Customers","\n".join(f"## {n} (`{i}`, {pr})\n{l}\n\n{p}\n\n- Favorites: {', '.join(f)}\n- Taste: "+", ".join(f"{a} {b}" for a,b in t.items())+"\n- Quirks: "+"; ".join(q)+"\n" for i,n,l,p,f,t,q,pr in C))
md("order_lines","Order Lines","\n".join(f"## {k}\n"+"\n".join(f"- {l}" for l in v)+"\n" for k,v in O.items()))
md("reviews","Drink Reviews","Customer always pays. Off (<50, formerly 'poor') = kind and funny.\n\n"+"\n".join(f"## {p}\n"+"\n".join(f"**{t}**\n"+"\n".join(f"- {l}" for l in ls)+"\n" for t,ls in tiers.items()) for p,tiers in R.items())+"\n## Per-customer\n"+"\n".join(f"- **{k}**: great \"{v['great']}\" / okay \"{v['okay']}\" / off \"{v['off']}\"" for k,v in CV.items())+"\n")
md("banter","Customer Banter",f"{len(B)} exchanges.\n\n"+"\n".join(f"### banter_{i+1:02d} ({', '.join(s)}){' ['+', '.join(c)+']' if c else ''}\n"+"\n".join(f"- **{s[j%2]}**: {t}" for j,t in enumerate(L))+"\n" for i,(s,c,L) in enumerate(B)))
md("idle_thoughts","Idle Thought Bubbles","\n".join(f"## {k}\n"+"\n".join(f"- {x}" for x in v)+"\n" for k,v in {**I,"generic":G}.items()))
print("ok",len(B),sum(map(len,I.values())))

# v2.1 md overrides (order lines with product-specific + gating)
md("order_lines","Order Lines","Rule: "+order_lines["_meta"]["order_rule"]+"\n\n"+"\n".join(f"## {k} (appears {_CE[k]['appears_from']}, slice order {_CE[k]['slice_order']})\n**Generic**\n"+"\n".join(f"- {l}" for l in order_lines['generic'][k])+"\n\n**By drink**\n"+"\n".join(f"- `{p}` (L{UNLOCK[p]}): "+" / ".join(v) for p,v in SPEC2.get(k,{}).items())+"\n" for k in O)+"\n## Any customer\n"+"\n".join(f"- `{p}`: "+" / ".join(v) for p,v in GEN_ORDERS.items())+"\n")
md("banter","Customer Banter",f"{len(B)} exchanges ({len(B2)+len(B3)} about the new drinks). Gate: level >= min_level.\n\n"+"\n".join(f"### {e['id']} ({', '.join(e['speakers'])}) min {e['min_level']}{' max '+e['max_level'] if 'max_level' in e else ''}{' ['+', '.join(e['context'])+']' if e['context'] else ''}\n"+"\n".join(f"- **{l['speaker']}**: {l['text']}" for l in e['lines'])+"\n" for e in banter['exchanges']))
print("v2.1 md ok")

# v2.1: customer event lines (all line ids in customer_events.json)
exec(open(os.path.join(D,"_event_lines.py")).read())

# v2.2: event cast section in customers.md
open(f"{D}/customers.md","a").write(CAST_MD)
print("event cast ok", len(CAST))

# v2.3: reviews.md rebuilt from the final (polished) reviews dict, all customers incl. one-offs
# (_event_lines.py rebinds the name md, so write directly)
_mdw=lambda name,title,body: open(f"{D}/{name}.md","w").write(f"# {title}\n\nProduct source: `{SRC}`. Ids: {', '.join(PRODUCTS)}.\n\n"+body)
_mdw("reviews","Drink Reviews","Customer always pays and leaves 3+ stars. Off (<50) = warm, gentle and funny, never harsh.\n\n"
   +"\n".join(f"## {p}\n"+"\n".join(f"**{t}**\n"+"\n".join(f"- {l}" for l in ls)+"\n" for t,ls in tiers.items()) for p,tiers in reviews["by_product"].items())
   +"\n## Per-customer\n"+"\n".join(f"- **{k}**: great \"{v['great']}\" / okay \"{v['okay']}\" / off \"{v['off']}\"" for k,v in reviews["per_customer"].items())
   +"\n\n## Per-customer, per-drink\n"+"\n".join(f"- **{c}** / `{p}`: "+" / ".join(f"{t} \"{l}\"" for t,l in tv.items()) for c,m in reviews["per_customer_product"].items() for p,tv in m.items())+"\n")
print("reviews.md polished")
