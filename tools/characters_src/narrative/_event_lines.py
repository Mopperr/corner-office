# Fills every placeholder line id in /workspace/game/customer_events.json.
# Output: customer_event_lines.json (+ .md), keyed by line id. Run: python3 _event_lines.py
import json, os
D = os.path.dirname(os.path.abspath(__file__))
EV = json.load(open("/workspace/game/customer_events.json"))
N = "narration"
L = {}
def a(i, sp, t, **kw): L[i] = {"speaker": sp, "text": t, **kw}

# ---------- drink events ----------
e="ev_drink_classic_first_sale"
a(f"line_{e}_order","neighbor_kid","One classic lemonade, please. With a quiet straw. Mom says the squeaky ones are rude.")
a(f"line_{e}_success","neighbor_kid","Whoa. This is the best lemonade on the whole street. Maybe the whole world. Here's a quarter extra!")
a(f"line_{e}_okay","neighbor_kid","It's good! It's lemon-y and sugar-y. I'm gonna tell everybody.")
a(f"line_{e}_off","neighbor_kid","It's a little funny... but it's still lemonade! Lemonade is always lemonade. Thank you!")
e="ev_drink_pink_biscuit_nose"
a(f"line_{e}_order","priya_okafor","Priya here! Could I get the pink one? Like his nose. Biscuit insisted. Well, he blinked at the menu.")
a(f"line_{e}_success","priya_okafor","Oh, that's exactly Biscuit-nose pink! I'm putting it on the Whisker & Bean specials board. With credit.")
a(f"line_{e}_okay","priya_okafor","A little pale, but sweet. More of a sleepy-nose pink. Biscuit approves, I think. He yawned.")
a(f"line_{e}_off","priya_okafor","That's more of a sunburned-nose pink! Still lovely. Want to try one more pour? No rush at all.")
a(f"line_{e}_biscuit_meow","biscuit","Mrrp? (Biscuit watches the pitcher very, very closely.)")
e="ev_drink_icedtea_after_rain"
a(f"line_{e}_order","cyclist_from_l3","Rain's done and I'm soaked. Iced tea lemonade, please. Cold drink, wet jacket. Perfect balance.")
a(f"line_{e}_success","cyclist_from_l3","Oh, that's the sun coming back in a cup. Worth every puddle on the way here.")
a(f"line_{e}_okay","cyclist_from_l3","Tea's a touch warm, so the ice is racing. I'm racing too. We'll all get there!")
a(f"line_{e}_off","cyclist_from_l3","That's hot tea in a cold disguise! Honestly, cozy after the rain. Want another go? I'm in no hurry.")
e="ev_drink_strawberry_caboose"
a(f"line_{e}_order","grandpa_train_shop","Walt Hale, all aboard! One strawberry lemonade, caboose-red if you please. This little fella keeps time.")
a(f"line_{e}_success","grandpa_train_shop","Caboose-red, right on schedule! Best stop on the whole line.")
a(f"line_{e}_okay","grandpa_train_shop","A touch more pink than red. A caboose that's been out in the sun. I'll take it, gladly.")
a(f"line_{e}_off","grandpa_train_shop","Hm! A few berries missed the train. Happens on every line. Shall we run it one more time?")
a(f"line_{e}_caboose_gift","grandpa_train_shop","You keep the caboose. Every good stand needs a conductor. Toot toot.")
e="ev_drink_mint_duckling"
a(f"line_{e}_order","pond_jogger","Mint lemonade, please! Oh, don't mind my friend. He followed me from the pond. He has opinions.")
a(f"line_{e}_success","pond_jogger","That's a breeze off the pond in a cup. And so calm! He didn't even flinch. You're a duck friend now.")
a(f"line_{e}_okay","pond_jogger","Mint's a little shy, but it's cool and sweet. My little shadow is very content.")
a(f"line_{e}_off","pond_jogger","Whoa, minty! My whole face feels brand new. Want to try a gentler one? We'll wait. He's sitting.")
a(f"line_{e}_duck_quack","duckling","Quack. (The duckling settles down beside the stand.)")
e="ev_drink_black_delbert_clock"
a(f"line_{e}_order","delbert_finch","Black coffee, please. A quiet cup. This clock and I have an appointment with nothing at all.")
a(f"line_{e}_success","delbert_finch","Precisely right. Not a second too strong. I'll be back tomorrow at this same tick.")
a(f"line_{e}_okay","delbert_finch","A touch thin. Like a clock that runs two minutes slow. Still keeps good company.")
a(f"line_{e}_off","delbert_finch","Ah. This one's running backwards a bit. No matter. Shall we wind it again?")
a(f"line_{e}_clock_tick",N,"Tick... tick... (Delbert's pocket clock keeps time on the counter.)")
e="ev_drink_espresso_dentist"
a(f"line_{e}_order","retiring_dentist","One espresso, please. Before I never hear a drill again. Gerald's along, he's very well behaved.")
a(f"line_{e}_success","retiring_dentist","Perfect crema. And I didn't even check anyone's molars. Retirement is wonderful.")
a(f"line_{e}_okay","retiring_dentist","A smidge bitter. Like a good flossing. Good for you, mostly.")
a(f"line_{e}_off","retiring_dentist","Very... relaxed shot. On vacation, like me! Want to pull one more? Gerald and I have all day.")
a(f"line_{e}_gerald_bubble","gerald","blub. (Gerald makes one tiny, approving bubble.)")
e="ev_drink_honeylav_vendor"
a(f"line_{e}_order","npc_vendor","Brought you honey from my stall and a little lavender bunch. Try the fancy one? I've been dying to taste it.")
a(f"line_{e}_success","npc_vendor","Oh, that's a Saturday morning in a glass! I'm sending my whole aisle over.")
a(f"line_{e}_okay","npc_vendor","Lavender's a little loud, but it's sweet as can be. Next time, a shorter steep!")
a(f"line_{e}_off","npc_vendor","That's a very sweet candle you've made! Ha! Take another go, there's plenty of honey.")
a(f"line_{e}_honey_gift","npc_vendor","Keep the jar. Honey keeps forever, and so do good neighbors.")
e="ev_drink_latte_sketch_art"
a(f"line_{e}_order","npc_architect","Latte. With this on top. No, wait, this. Okay, this. Final answer. Probably.")
a(f"line_{e}_success","npc_architect","That's... my sketch. In foam. I'm pinning the napkin on your wall. Don't argue, I'm an architect.")
a(f"line_{e}_okay","npc_architect","Close. It's like my sketch after a second draft. I'll allow it.")
a(f"line_{e}_off","npc_architect","Interesting. Abstract. I may have drawn it upside down anyway. Try again? I'll hold the napkin still.")
a(f"line_{e}_grudging_not_bad","npc_architect","...Not bad. Don't let it go to your head.")
e="ev_drink_cappuccino_quiet"
a(f"line_{e}_order","agnes_pell","(whispering) One cappuccino, please. Quiet foam, if you have it.")
a(f"line_{e}_success","agnes_pell","(whispering) Lovely. Foam like a turned page. Five stars, silently.")
a(f"line_{e}_okay","agnes_pell","(whispering) A little thin, but very kind. Like a paperback.")
a(f"line_{e}_off","agnes_pell","(whispering) It's a bit loud, flavor-wise. That's all right, dear. Another one, softly?")
a(f"line_{e}_shh",N,"shh... (Agnes smiles and taps her book.)")
e="ev_drink_mocha_juno"
a(f"line_{e}_order","juno_park","mocha!! extra whip!! sorry, I'm late, I'm always late, the band's waiting, it's fine!!")
a(f"line_{e}_success","juno_park","OH that's an encore in a cup. Big tip. Biggest tip. You're on the guest list forever.")
a(f"line_{e}_okay","juno_park","It's chocolatey, it's coffee-ish, it's GREAT. Okay, it's good! Still tipping!")
a(f"line_{e}_off","juno_park","Ha! Hot chocolate with a coffee rumor! I love it. I'm late anyway, wanna try again?")
e="ev_drink_iced_on_beat"
a(f"line_{e}_order","record_store_owner","Lou Marchetti. Dropped a record on for you. Iced coffee, please, and feel the groove.")
a(f"line_{e}_success","record_store_owner","Every step on the beat. That's a B-side hit. Here's a coupon, my friend.")
a(f"line_{e}_okay","record_store_owner","A little off the rhythm, but the melody's there. Nice chill.")
a(f"line_{e}_off","record_store_owner","Ha, you skipped a groove! Happens to the best records. Drop the needle again?")
a(f"line_{e}_needle_drop",N,"*crackle* (The needle drops. A warm bassline fills the room.)")
e="ev_drink_vanilla_orchid"
a(f"line_{e}_order","rosa_pemberton","Rosa Pemberton, from the greenhouse! Vanilla latte, please. The pod's from my orchid corner. Don't tell Ray.")
a(f"line_{e}_success","rosa_pemberton","Oh, it smells like my orchids at sunrise! I'm naming a bud after this cup.")
a(f"line_{e}_okay","rosa_pemberton","Vanilla's a little shy, like a bud that's not quite open. Lovely anyway.")
a(f"line_{e}_off","rosa_pemberton","That's a lot of vanilla! Ray would say I told you so. Let's try once more, gently.")
e="ev_drink_seasonal_board"
a(f"line_{e}_board_reveal","dana","New on the board! (Dana chalks the season's flavor in big curly letters.)",
  variants={"spring":"New on the board: Blossom Honey Latte!","summer":"New on the board: Toasted Coconut Latte!","autumn":"New on the board: Maple Pumpkin Latte!","winter":"New on the board: Winter Spice Latte!"})
a(f"line_{e}_order","coworker_npc","Ooh, the seasonal one! I have no idea what that word means, but I want it.")
a(f"line_{e}_success","coworker_npc","It tastes exactly like this time of year. I'm telling the whole floor.")
a(f"line_{e}_okay","coworker_npc","Little heavy on the syrup. Very festive. I'm extremely awake now.")
a(f"line_{e}_off","coworker_npc","The topping went on a little adventure down the side! Cute. Want a redo? I'll wait.")

# ---------- general events ----------
e="ev_gen_regular_returns"
a(f"line_{e}_greeting","regular","Hey, it's me again! Missed this place.")
a(f"line_{e}_usual","regular","The usual, please. You remember, right? No pressure!")
a(f"line_{e}_success","regular","You remembered! That makes my whole day.")
a(f"line_{e}_okay","regular","Close to my usual! Close enough to make me smile.")
a(f"line_{e}_off","regular","Ha, not quite my usual, but you tried! Shall we have another go together?")
e="ev_gen_two_customers_chat"
a(f"line_{e}_chat_a","rosa_pemberton","Ray! Fancy meeting you in line. Have you tried the sweet one?")
a(f"line_{e}_chat_b","ray_pemberton","Rosa. I came here to avoid your sugar opinions.")
a(f"line_{e}_order_change","ray_pemberton","Fine. I'll have what she's having. Don't tell her she's right.")
a(f"line_{e}_success","ray_pemberton","...She was right. This one's wonderful. I'll deny saying that.")
a(f"line_{e}_okay","ray_pemberton","Hm. Not bad. Not as good as mine. But not bad.")
a(f"line_{e}_off","ray_pemberton","See, Rosa? Too much of a good thing! Ha. One more try, though? It's growing on me.")
e="ev_gen_rush_hour"
a(f"line_{e}_rush_start",N,"Ding ding! Here comes the rush. Everybody's smiling. Take it one cup at a time.",
  variants={"coffee_counter":"Ding ding! The morning crowd's here. Deep breath, one cup at a time.","lemonade_stand":"Ding ding! Afternoon thirst o'clock. One cup at a time."})
a(f"line_{e}_rush_clear_great","dana","Rush Hour Hero! Every cup a winner. Dana's doing a tiny victory dance.")
a(f"line_{e}_rush_clear_okay","dana","Rush cleared! Everyone left happy and caffeinated (or lemonaded).")
e="ev_gen_biscuit_visit"
a(f"line_{e}_arrive",N,"Biscuit has arrived. Biscuit is sitting on the counter. Biscuit is in charge now.")
a(f"line_{e}_pet","biscuit","Prrrrrrr. (Biscuit leans into the scratch.)")
a(f"line_{e}_customer_aww","customer","Awww! Is he yours? Can I pet him? I'm leaving a cat-photo review.")
a(f"line_{e}_leave",N,"Biscuit stretches, blinks slowly at you, and strolls off. Business as usual.")
e="ev_gen_kid_short_quarter"
a(f"line_{e}_short","neighbor_kid","Um... I'm one quarter short. I counted twice. It's still one quarter.")
a(f"line_{e}_on_house","dana","This one's on the house, kiddo. Enjoy your lemonade.")
a(f"line_{e}_next_time","dana","No worries. Pay me next time, okay?")
a(f"line_{e}_payback","neighbor_kid","I'm back! Here's two quarters, one for last time and one for being nice!")
e="ev_gen_critic_visit"
a(f"line_{e}_arrive",N,"A quiet customer with a notebook sits down. They seem to be noticing... everything.")
a(f"line_{e}_order","food_critic","Your most ambitious drink, please. Take all the time you need.")
a(f"line_{e}_review_great","food_critic","'A hidden gem. Warm, careful, delicious.' I'll be writing about this.")
a(f"line_{e}_review_okay","food_critic","'A charming spot with real heart.' Four stars, with pleasure.")
a(f"line_{e}_review_off","food_critic","'Promising.' Truly. Everything great starts somewhere.")
e="ev_gen_marge_checkin"
a(f"line_{e}_arrive","marge_holloway","Mile Marker, checking in! New office, new counter. Had to see it with my own eyes.")
a(f"line_{e}_order","marge_holloway","Give me whatever's newest, boss. I like my coffee like my routes: fresh.")
a(f"line_{e}_logged_and_loaded","marge_holloway","Logged and loaded. That one's going in the logbook.")
a(f"line_{e}_hint_next","marge_holloway","Word down the road is something new is coming soon. Keep your straps tight.",
  variants_by_next_drink={
   "pink_lemonade":"Heard the cat cafe crowd likes things pink. Just saying.",
   "iced_tea_lemonade":"Rain's on the radio. Something tea-flavored usually follows a good rain.",
   "strawberry_lemonade":"There's a fella with a train set who swears by strawberries. Keep an ear out.",
   "mint_lemonade":"The pond road's got wild mint growing all along it. Smells like a breeze.",
   "black_coffee":"A real office deserves a real coffee counter. Truck-stop rule number one.",
   "espresso":"Small cups, big kick. Somebody retiring might show you how it's done.",
   "honey_lavender_lemonade":"Market day's coming. Honey and lavender, if my nose is right.",
   "latte":"Saw an architect doodling on napkins. Bet they'd like a drawing on their coffee.",
   "cappuccino":"Libraries run on quiet foam, I hear. Whisper it.",
   "mocha":"A warehouse morning calls for chocolate. Don't argue with Mile Marker.",
   "iced_coffee":"Record shop owner brews it cold and slow. Keeps a good beat.",
   "vanilla_latte":"There's a florist with an orchid corner. Smells like vanilla, I'm told.",
   "seasonal_special":"Fancy offices have fancy menu boards. Chalk's already in my glovebox."})
e="ev_gen_weather_turn"
a(f"line_{e}_rain_start",N,"Pitter-patter! Customers huddle under the awning. Something warm, or tea with lemon?")
a(f"line_{e}_heat_start",N,"Phew, a hot one! Everyone's fanning themselves and asking for extra ice.")
a(f"line_{e}_weather_quip","queue_npc","Weather's changing, but this line's still the coziest spot in town.",
  variants={"rain":"Rain makes everything taste better under an awning.","heat":"Extra ice, please! I'm basically a puddle."})
e="ev_gen_review_board"
a(f"line_{e}_fan_favourite","dana","Fan favourite today: {drink}! The people have spoken.")
a(f"line_{e}_tip_note","dana","Sticky note from Dana: Try a little less ice next time. You're doing great!",
  variants_by_weakest_part={"ingredients":"Sticky note: double-check the recipe card. You're doing great!","order":"Sticky note: steps in order make it sing. You're doing great!","amounts":"Sticky note: a little less pour, a little more taste. You're doing great!","ice_temp":"Sticky note: watch the ice and the heat. You're doing great!","timing":"Sticky note: a quick serve keeps it fresh. No rush, though. You're doing great!"})

# ---------- customer cameos + signature events ----------
a("line_cust_dottie_rain_wave","dottie","Yoo-hoo! Rain's stopped, sweetie. I'll have one of those tea lemonades too. Light ice, my teeth are retired.")
a("line_cust_wren_whisper_order","wren","(whispering) A cappuccino, please. I like a quiet foam too.")
a("line_cust_keyclackr_drum_along","keyclackr","*tap tap tap* Sorry! This bassline is a perfect typing tempo.")
a("line_cust_wren_seasonal_first","wren","A new season on the board. I'll write a new poem for it.")
a("line_cust_pippa_critic_copy","pippa","(Pippa sits next to the critic and copies their notes exactly. Same frown. Same pen tap.)")
a("line_cust_dottie_rain_traffic","dottie","Single file under the awning, everybody! Umbrellas in, elbows friendly.")
a("line_cust_rocco_heat_ice","rocco","Extra ice, chief! It's ninety degrees on my route and Biscuit the beagle wants shade.")

e="line_cust_steve_staple_rating"
a(f"{e}_order","steve","One black coffee, please. I'd like to acquire it.",
  variants_by_drink={"espresso":"One espresso, please. Small, dense, reliable.","vanilla_latte":"A vanilla latte, please. Weekend acquisition."})
a(f"{e}_stackable_ask","steve","Quick question: are the cups stackable? For science. And joy.")
a(f"{e}_stack_done","steve","Look at that. A perfect stack. May I acquire one for the collection?")
a(f"{e}_staples_great","steve","Five staples out of five. Acquired with joy. Here's exact change, plus two.")
a(f"{e}_staples_okay","steve","Three staples. Solid binding. A dependable cup.")
a(f"{e}_staples_off","steve","Two staples. But they still hold the pages together! Paying with exact change.")

e="line_cust_lamp_lady_golden_hour"
a(f"{e}_order","lamp_lady","Pink lemonade, sweetie! It's golden hour and I want something that glows.",
  variants_by_drink={"honey_lavender_lemonade":"The honey-lavender, please! It's golden hour, darling.","latte":"A latte, please! Lots of foam for the low light."})
a(f"{e}_hold_to_light","lamp_lady","(Lorna lifts the cup toward the setting sun.) Oh, look at that. Just look at it.")
a(f"{e}_warm_wattage","lamp_lady","Warm wattage! A hundred watts of happy!")
a(f"{e}_forty_watts","lamp_lady","A cozy forty watts. Perfect for reading by.")
a(f"{e}_dim_but_sunny","lamp_lady","A little dim, but that's okay. I brought my own sunshine! Paying, of course.")
a(f"{e}_lamp_gift","lamp_lady","This is for you, darling. Every stand needs a little lamp. Doesn't it glow?")

e="line_cust_keyclackr_typed_order"
a(f"{e}_typing","keyclackr","*clack clack clack* Order coming in! Hold on, autocorrect is fighting me.",
  note="Event drink is black_coffee (L6). Espresso unlocks at L7; after that the ticket can show the ticket_espresso variant.",
  variants={"ticket_espresso":"1x expresso plz","ticket_black_coffee":"1x blakc coffee plz","ticket_iced_coffee":"1x iced cofee plz","ticket_latte":"1x lattee plz"})
a(f"{e}_typo_fix","keyclackr","Ha, thanks. You fixed my typo faster than I did. Zero input lag.")
a(f"{e}_tactile","keyclackr","Tactile. Perfect actuation. Posting a five-star review with a keyboard emoji. ⌨️")
a(f"{e}_linear","keyclackr","Linear. Smooth enough. 7/10, wuold sip again. Would. Would sip.")
a(f"{e}_mushy","keyclackr","Bit mushy, like a membrane board. Still paying! Payign. Paying.")

e="line_cust_dottie_crossing_guard"
a(f"{e}_stand_up","dottie","Alright, everybody! (Dottie stands up and straightens her vest.) Thirty years of training, here we go.")
a(f"{e}_wave_line","dottie","You first, then you, then you. Nice and easy. Nobody's in a rush here.")
a(f"{e}_you_go_first","dottie","You go ahead, sweetie. I'm retired. I've got all day.")
a(f"{e}_smooth_traffic","dottie","Smooth traffic today. I'm so proud of all of you.")
a(f"{e}_slow_down_sweetie","dottie","Slow down, sweetie. You're doing fine. Better than fine.")

e="line_cust_dottie_lemon_tree"
a(f"{e}_arrive_bag","dottie","I brought you something, dear. Lemons from Harold's old tree. Still going strong, just like me.")
a(f"{e}_harold_story","dottie","Harold planted that tree the week we got married. Every summer he'd make lemonade too sour, and I'd add sugar when he wasn't looking.")
a(f"{e}_harold_proud","dottie","Oh, that's it. That's the one. Harold's lemon tree would be proud.")
a(f"{e}_bag_gift","dottie","You keep the rest. A jar of lemons looks lovely on a windowsill. He'd like that.")

e="line_cust_theo_night_shift"
a(f"{e}_yawn","theo","*yaaaawn* Sorry. Twelve hours. Hi.")
a(f"{e}_order","theo","A coffee to sleep after, please. Somehow it works. Don't ask.",
  note="Event drink is black_coffee (L6). Latte unlocks at L9; from then the latte variant can play.",
  variants_by_drink={"black_coffee":"Black coffee, please. Then sleep. In that order.","latte":"A latte, hot as you can, extra foam. I'm basically a cloud now."})
a(f"{e}_thanks_twice","theo","Thank you. And thank you. Once for each eye that's open.")
a(f"{e}_vitals_stable","theo","Vitals stable. Drink is fine. So am I. Mostly.")
a(f"{e}_worse_at_4am","theo","I've had worse at 4 a.m. Many times. This is lovely by comparison. Thank you, truly.")

e="line_cust_pippa_critique"
a(f"{e}_arrive_official","pippa","Hello. This is an official review. Please act natural.")
a(f"{e}_watching","pippa","(Pippa leans in, clipboard up, watching every pour.) Mm-hmm. Interesting. Very interesting.")
a(f"{e}_box_balance","pippa","Balance: sweet versus sour.",
  variants_by_band={"great":"Balance: gold star. Sweet and sour are best friends.","okay":"Balance: silver star. A tiny bit more lemon, please.","off":"Balance: nice-try frog. Next time, taste before you serve!"})
a(f"{e}_box_chill","pippa","Chill: ice level.",
  variants_by_band={"great":"Chill: gold star. Perfect ice. My brain is only slightly frozen.","okay":"Chill: silver star. One more scoop of ice next time.","off":"Chill: nice-try frog. The ice went on vacation."})
a(f"{e}_box_service","pippa","Service: timing.",
  variants_by_band={"great":"Service: gold star. Fast and friendly.","okay":"Service: silver star. Good, a little slow. That's okay!","off":"Service: nice-try frog. But you smiled the whole time. That counts."})
a(f"{e}_gold_seal","pippa","Three gold stars. That's the Official Seal. It's going right here on your stand. Don't peel it off.")
a(f"{e}_silver_tip","pippa","Silver star. Room to grow! Tip: work on your weakest box. I believe in you.")
a(f"{e}_frog_tip","pippa","You get the nice-try frog. He's very proud of you. Tip: one thing at a time. I'll check back next time!")

# Pippa's per-box silver-star tips (Design, Oct 23). Same tip panel as line_cust_pippa_critique_silver_tip
# (one line, Nunito SemiBold 36, <= 2 lines in the mock panel, so <= 80 chars). Each names the box it means.
PIPPA_TIPS = {
 "pippa_tip_balance_1": ("balance", "Silver star! Tip: taste first to fix your Balance box. I believe in you."),
 "pippa_tip_balance_2": ("balance", "Silver star! Tip: Balance box. Sweet and sour need to hold hands. Almost!"),
 "pippa_tip_chill_1":   ("chill",   "Silver star! Tip: Chill box. Ice goes in first, then the pour. You can do it!"),
 "pippa_tip_chill_2":   ("chill",   "Silver star. Tip: your Chill box is almost frosty. Just a few more cubes!"),
 "pippa_tip_service_1": ("service", "Silver star! Tip: your Service box. Hand it over a teeny bit faster. Go, go!"),
 "pippa_tip_service_2": ("service", "Silver star. Tip: Service box! Smiling is great. Smiling faster is greater."),
}
for _k, (_b, _t) in PIPPA_TIPS.items():
    assert len(_t) <= 80 and _b.capitalize() in _t and _t.startswith("Silver star"), _k

e="line_cust_pippa_margins"
a(f"{e}_margins_ask","pippa","Question. What are your profit margins? Just curious. For my future empire.")
a(f"{e}_ledger_card",N,"One cup: price {price}, ingredients {cost}, you keep {profit}. That's about {margin_pct}% for you!")
a(f"{e}_business_partner","pippa","Makes sense. You're a smart business. Future business partner. I'm writing it down.")

e="line_cust_rocco_route_stop"
a(f"{e}_arrive_route","rocco","Two minutes, chief! Step count's on! Strawberry lemonade, please. My mint's still in the mail.",
  min_level="L1", max_level="L4",
  note="Base text is L1-L4 only (min_level/max_level, banter.json convention): mint lemonade unlocks at L5. From L5 onward use variants_by_level['L5+'] (variants_by_level_range: min_level L5, no max).",
  variants_by_level={"L5+":"Two minutes, chief! Step count's on! Strawberry for the event, but hey, the mint finally got delivered!"},
  variants_by_level_range={"L5+":{"min_level":"L5"}})
a(f"{e}_gossip","rocco","Got some news from the route, hot off the satchel...",
  note="Gossip is a hint about the NEXT level. Pick variants_by_next_level[next level]. Rocco appears from L4, so the first hint teases L5.",
  variants_by_next_level={
   "L5":"Heads up: they're closing the bridge for repairs. Detour goes right round the duck pond. Ducks have the right of way, you know.",
   "L6":"Word is there's a sunny room up above the bakery. Smells like bread every morning. Just saying, chief.",
   "L7":"The dentist on Elm's finally retiring. Big chair, lots of glass, and a fish named Gerald. Gerald's a VIP.",
   "L8":"Saturday's market day! Watch the lanes, though. Last week a cabbage made a run for it.",
   "L9":"There's an architect on my route who's redrawn her own front door three times this week.",
   "L10":"Library's moving to the new branch. Don't tell anyone, but I heard there's a secret letter tucked in one of the books.",
   "L11":"Delivered a package to an old brick warehouse. Huge windows, clanky elevator. Real business vibes.",
   "L12":"The record shop's owner keeps a turntable spinning all day long. My route goes faster past there.",
   "L13":"Did a late route last night. The streets glow after dark, and a little cat followed me three whole blocks.",
   "L14":"The greenhouse twins are fighting about pots again. Somebody's going to have to move all those plants.",
   "L15":"Drove the coast road. Windy! A gull stole my sandwich. Worth it for the lighthouse.",
   "L16":"There's a glass suite downtown with room for a whole team. Fancy! Bet you'd look good in there.",
   "L17":"The theater's opening night is coming up and the director's in a panic. Piano, castle wall, rubber chicken, the works.",
   "L18":"Parade's this weekend! Main road's closed, so plan a detour. Follow the band if you get lost.",
   "L19":"A rival mover's been asking about you. Very snooty. Very shiny shoes. I think they're secretly impressed.",
   "L20":"Up at the mountain lodge, they say the cocoa's the best in the state. And the first snow's on its way.",
   "L21":"There's a corner office with floor-to-ceiling windows sitting empty. I'd keep my eye on that one, chief.",
   "L22":"Some kid starting a business is asking about an old garage. Funny how things come back around, huh?"})
a(f"{e}_personal_best","rocco","Personal best! Look at that step counter go!")
a(f"{e}_signed_sealed","rocco","Signed, sealed, delicious!")
a(f"{e}_dented","rocco","Arrived a little dented, but it got here! That's what counts.")
a(f"{e}_return_to_sender","rocco","Return to sender? Nah, I'll keep it. Paid in full!")

e="line_cust_wren_haiku_card"
a(f"{e}_sip_count","wren","(Wren sips slowly.) Seven bubbles. No, eight. One was hiding.",
  note="Event drink is black_coffee (L6); Wren orders black coffee until honey-lavender unlocks at L8.",
  variants_by_drink={"black_coffee":"(Wren holds the cup close and looks in.) Dark as a quiet night. One small bubble, like a moon.","honey_lavender_lemonade":"(Wren sips slowly.) Seven bubbles. No, eight. One was hiding. And the lavender is humming."})
a(f"{e}_haiku_great","wren","Warm between my palms / a small sun I can hold close / thank you, morning hands",
  note="Default great haiku; prefer reviews.json per_customer_product.wren[drink].great when present.")
a(f"{e}_haiku_okay","wren","Almost there, just like / the first warm day of April. / Still, I'm glad of it.",
  note="Default okay haiku; prefer reviews.json per_customer_product.wren[drink].okay when present.")
a(f"{e}_haiku_off","wren","Brave little cup, you / tried your best and so did I. / Here, for your effort.",
  note="Default off haiku; prefer reviews.json per_customer_product.wren[drink].off when present.")
a(f"{e}_napkin_tip","wren","(Wren folds the napkin into a tiny square and tucks it under the cup.) For you.")

e="line_cust_wren_napkin_wall"
a(f"{e}_notice_napkins","wren","You kept them? All my napkins? Oh. I don't know what to say. That's rare for me.")
a(f"{e}_pin_request","wren","Could we pin them up somewhere? A little poem corner. Anywhere you like.")
a(f"{e}_shop_haiku","wren","Warm cups, kind faces / a corner where words can rest / this place is a verse")

# ---------- verify ----------
want = [l for ev in EV["events"] for l in ev["line_ids"]]
ev_of = {l: ev["id"] for ev in EV["events"] for l in ev["line_ids"]}
chars = {ev["id"]: ev["characters"] for ev in EV["events"]}
missing = [w for w in want if w not in L]; extra = [k for k in L if k not in set(want)]
assert not missing and not extra, (missing, extra)
cust_ids = {c["id"] for c in EV["customers"]}
for k, v in L.items():
    v["event"] = ev_of[k]
    assert v["text"].strip() and "TODO" not in v["text"] and "placeholder" not in v["text"].lower(), k
    if v["speaker"] in cust_ids: assert v["speaker"] in chars[ev_of[k]] or k.startswith("line_cust_"), k
rh = L["line_cust_rocco_route_stop_gossip"]["variants_by_next_level"]
assert list(rh) == [f"L{i}" for i in range(5, 23)]
# ---------- leave lines (not event beats: patience runs out / shift ends with a queue) ----------
# Kept in a separate top-level "leave_lines" block so the event-line checks (DC-05 counts/orphans) stay exact.
LV = {}
def lv(cust, reason, *texts):
    for i, t in enumerate(texts, 1):
        LV[f"line_leave_{reason}_{cust}_{i}"] = {"speaker": cust if cust != "generic" else "customer", "reason": reason, "text": t}
P, S = "patience", "shiftend"
lv("steve", P, "Oh! Meeting in five. I'll grab one tomorrow. Save me a stackable cup?")
lv("steve", S, "Closing time? Fair. Even staplers need rest. See you tomorrow!",
               "No worries. I'll file this under 'tomorrow'. Alphabetically, it's very close.")
lv("lamp_lady", P, "Oh, the light's changing, darling! I'll pop back when it's golden again.",
                   "I've just remembered a lamp I left on. Back soon, sweetie!")
lv("lamp_lady", S, "Lights out already? Lovely. Sleep well, and I'll see you at golden hour.")
lv("keyclackr", P, "Brb! Gotta catch a group buy. Back tomorow. Tomorrow.")
lv("keyclackr", S, "Shop's closing? All good, I'll queue up again tomorrow. Saving my order to drafts.",
                   "GG for today! Same time tomorrow, friend. ⌨️")
lv("dottie", P, "I'll let the young ones go first, sweetie. I'll be back tomorrow. I've got all day, every day.",
                "Oh, there's my bus! You're doing wonderfully, dear. See you soon.")
lv("dottie", S, "Closing up? Good for you, dear. Everyone needs to go home on time. Harold always said so.")
lv("theo", P, "My eyes are voting for bed. I'll come back tomorrow. Thank you anyway.")
lv("theo", S, "Closing? Same. Go rest. Doctor's orders. Well, nurse's.",
              "Shift's over for both of us, then. See you after my next one.")
lv("pippa", P, "I have to go, it's almost snack time. The official review is postponed. Not cancelled!",
               "My mom's waving. I'll be back tomorrow with my clipboard. Be ready!")
lv("pippa", S, "Closing time is a smart business choice. I'm writing that down. See you tomorrow!")
lv("rocco", P, "Gotta keep the route moving, chief! I'll swing by tomorrow. Step count waits for no one!")
lv("rocco", S, "All closed up? No problem! I'll deliver myself back tomorrow, first thing.",
               "Out for delivery till tomorrow, chief. Keep the counter warm!")
lv("wren", P, "(Wren smiles and tucks their pencil away.) Another day. The poem can wait.")
lv("wren", S, "The day folds itself / like a napkin, soft and small. / Until tomorrow.",
              "Closing is a kind of rest too. Goodnight.")
lv("generic", P, "I'll come back tomorrow! Looks like a good one.",
                 "Oh, I've got to run. Next time for sure!",
                 "No rush at all, I'll swing by later. Have a lovely day!")
lv("generic", S, "Closing up? Totally fine. See you tomorrow!",
                 "Early night for everyone! I'll be first in line next time.",
                 "Thanks for a great day, everyone. Same time tomorrow!")
for k, v in LV.items():
    assert v["text"].strip() and v["reason"] in (P, S), k
out = {"_meta": {"version": 1, "source": "/workspace/game/customer_events.json", "keyed_by": "line_id",
   "count": len(L), "count_line_cust": sum(k.startswith("line_cust_") for k in L),
   "count_event_lines": sum(not k.startswith("line_cust_") for k in L),
   "fields": {"speaker": "character id from the event (or 'narration' for scene text)", "text": "default line",
              "variants*": "optional keyed alternatives; pick by the named key, else use text"},
   "placeholders": {"{drink}": "display name", "{price}/{cost}/{profit}/{margin_pct}": "from products.json"},
   "tone": "Cozy sitcom. Off results are kind and funny; the customer always pays.",
   "quality_bands": {"great": ">=80", "okay": "50-79", "off": "<50"}},
  "lines": {w: {"event": L[w]["event"], **{k: v for k, v in L[w].items() if k != "event"}} for w in want},
  "leave_lines": {"_meta": {"count": len(LV), "scheme": "line_leave_<reason>_<customer>_<n>; reason is patience (patience ran out) or shiftend (shift ended with a queue); customer is a regular id or 'generic' (speaker 'customer')",
                            "tone": "Warm and neutral, never guilt-tripping. The customer leaves for their own cheerful reason and plans to come back. No Rep or star change implied."},
                  **LV},
  "pippa_tips": {"_meta": {"count": len(PIPPA_TIPS), "event": "ev_cust_pippa_critique",
                           "scheme": "pippa_tip_<box>_<n>; box is balance | chill | service (the clipboard rows); n is 1 or 2 (alternates)",
                           "use": "On an okay (silver star) result, show the tip for Pippa's lowest-scoring box (by its share: Balance /70, Chill /15, Service /15) in the 'Pippa's tip' panel, alternating _1 and _2. Fallback: line_cust_pippa_critique_silver_tip. Gold and frog results keep gold_seal / frog_tip."},
                 **{k: {"speaker": "pippa", "box": b_, "sticker": "silver", "band": "okay", "text": t_} for k, (b_, t_) in PIPPA_TIPS.items()}}}
json.dump(haiku_store(out, add_fields=True), open(f"{D}/customer_event_lines.json", "w"), indent=2, ensure_ascii=False)
haiku_report()
md = ["# Customer Event Lines", "", f"All {len(L)} line ids from `customer_events.json` ({out['_meta']['count_event_lines']} event lines + {out['_meta']['count_line_cust']} line_cust_ lines). Data: `customer_event_lines.json`.", ""]
cur = None
for w in want:
    v = out["lines"][w]
    if v["event"] != cur: cur = v["event"]; md += ["", f"## {cur}"]
    md.append(f"- `{w}` **{v['speaker']}**: {v['text']}")
    for vk in [k for k in v if k.startswith("variants")]:
        for kk, tt in v[vk].items(): md.append(f"    - {vk.split('_by_')[-1] if '_by_' in vk else 'variant'} `{kk}`: {tt}")
md += ["", "## Leave lines (patience ran out / shift ended with a queue)", "", "Warm and neutral, never guilt-tripping. Data: `customer_event_lines.json` → `leave_lines`."]
for r in (P, S):
    md += ["", f"### {r}"]
    md += [f"- `{k}` **{v['speaker']}**: {v['text']}" for k, v in LV.items() if v["reason"] == r]
md += ["", "## Pippa's silver-star tips (per box)", "", "Section `pippa_tips` in `customer_event_lines.json`. Keys: `pippa_tip_<box>_<n>` (box = balance | chill | service, n = 1 or 2). Shown on an okay result for Pippa's lowest-scoring box; fallback `line_cust_pippa_critique_silver_tip`.", ""] + [f"- `{k}` ({b_}): {t_}" for k, (b_, t_) in PIPPA_TIPS.items()]
open(f"{D}/customer_event_lines.md", "w").write("\n".join(md) + "\n")
print("lines", len(L), "want", len(want), "cust", out["_meta"]["count_line_cust"], "rocco hints", len(rh))
