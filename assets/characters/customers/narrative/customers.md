# Stand Customers

Product source: `/workspace/game/drink_unlocks.json (14 drinks; products.json from Programmer Master not yet present, ids to match)`. Ids: classic_lemonade, pink_lemonade, iced_tea_lemonade, strawberry_lemonade, mint_lemonade, black_coffee, espresso, honey_lavender_lemonade, latte, cappuccino, mocha, iced_coffee, vanilla_latte, seasonal_special.

## Steve (StaplerSteve88) (`steve`, they/them)
Cardigan, lanyard, a stapler holstered like a sheriff's badge.

The market regular in person. Earnest collector of office supplies, polite to a fault, tips in exact change.

- Favorites: black_coffee, espresso, vanilla_latte
- Taste: sweet medium, sour low, ice none, foam none, strength high, temperature hot
- Quirks: Rates every drink in staples out of five.; Asks if the cups are stackable.; Says 'acquired' instead of 'bought'.

## Lorna (Lamp_Lady) (`lamp_lady`, she/her (explicit: 'Lamp Lady' is her chosen handle))
Big sunhat, bigger tote bag, always backlit somehow.

The lamp-trading regular. Sunny optimist who describes every drink in terms of lighting.

- Favorites: pink_lemonade, honey_lavender_lemonade, latte
- Taste: sweet high, sour medium, ice high, foam high, strength low, temperature cold
- Quirks: Holds cups up to the light before sipping.; Calls good drinks 'warm wattage'.

## Kit (KeyClackr) (`keyclackr`, they/them)
Wrist braces, mechanical keyboard in a backpack, typing on the counter.

The keyboard enthusiast. Fast talker, mild typo in everything they say, generous reviewer.

- Favorites: espresso, iced_coffee, black_coffee
- Taste: sweet low, sour low, ice low, foam medium, strength high, temperature hot
- Quirks: Drums fingers in actual keyboard rhythms.; Reviews drinks like switch types: 'tactile', 'linear'.

## Dottie Ruiz (`dottie`, she/her (explicit))
Retired crossing guard, reflective vest worn 'for fashion now'.

Grandmotherly traffic-controller of the line. Waves everyone forward. Has opinions on lemon wedges.

- Favorites: classic_lemonade, iced_tea_lemonade, mocha
- Taste: sweet high, sour medium, ice low, foam none, strength medium, temperature warm
- Quirks: Says 'slow down, sweetie' to the espresso machine.; Tells you about her late husband's lemon tree.

## Theo Nakamura (`theo`, they/them)
Scrubs, sleepy eyes, comfy sneakers, a single heroic yawn.

Night-shift nurse heading home. Gentle, dry humor, deeply grateful for anything warm.

- Favorites: latte, cappuccino, black_coffee
- Taste: sweet low, sour none, ice none, foam high, strength high, temperature hot
- Quirks: Orders a coffee to sleep after, somehow.; Thanks you twice, once for each eye that's open.

## Pippa Mensah (`pippa`, she/her (explicit, kid character))
Nine years old, clipboard, sticker-covered glasses.

Junior lemonade critic and future business mogul. Serious notes, enormous smiles.

- Favorites: classic_lemonade, strawberry_lemonade, pink_lemonade
- Taste: sweet high, sour high, ice high, foam none, strength low, temperature cold
- Quirks: Grades with stickers: gold star, silver star, 'nice try' frog.; Asks about your profit margins.

## Rocco Delgado (`rocco`, he/him (explicit))
Mail carrier shorts in every season, satchel, sunburned nose.

Chatty route-runner who knows every dog by name. Drinks fast, talks faster, never in a bad mood.

- Favorites: mint_lemonade, iced_coffee, strawberry_lemonade
- Taste: sweet medium, sour high, ice high, foam none, strength medium, temperature cold
- Quirks: Delivers neighborhood gossip like parcels.; Times his sips to his step counter.

## Wren Albright (`wren`, they/them)
Hand-knit scarf, notebook, ink on one finger.

Quiet poet who writes a tiny haiku about every drink. Soft-spoken, notices everything.

- Favorites: honey_lavender_lemonade, cappuccino, seasonal_special
- Taste: sweet medium, sour low, ice low, foam high, strength medium, temperature warm
- Quirks: Leaves haiku on napkins as a tip.; Counts the bubbles in the foam.

# Event cast (one-off, is_regular: false)

These characters appear in specific events only; they are not in the random customer pool.

| id | Name | Kind | First level | First event | Drink | Orders |
|---|---|---|---|---|---|---|
| `neighbor_kid` | Neighbor kid | one_off | L1 | `ev_drink_classic_first_sale` | classic_lemonade | yes |
| `dana` | Dana (player character) | player | L1 | `ev_drink_classic_first_sale` | classic_lemonade | no |
| `priya_okafor` | Priya Okafor | one_off | L2 | `ev_drink_pink_biscuit_nose` | pink_lemonade | yes |
| `biscuit` | Biscuit (the cat) | pet | L2 | `ev_drink_pink_biscuit_nose` | pink_lemonade | no |
| `cyclist_from_l3` | Soggy cyclist | one_off | L3 | `ev_drink_icedtea_after_rain` | iced_tea_lemonade | yes |
| `grandpa_train_shop` | Grandpa Walt Hale | one_off | L4 | `ev_drink_strawberry_caboose` | strawberry_lemonade | yes |
| `duckling` | Duckling | pet | L5 | `ev_drink_mint_duckling` | mint_lemonade | no |
| `delbert_finch` | Delbert Finch | one_off | L6 | `ev_drink_black_delbert_clock` | black_coffee | yes |
| `retiring_dentist` | Dr. Barry Plum | one_off | L7 | `ev_drink_espresso_dentist` | espresso | yes |
| `gerald` | Gerald (the fish) | pet | L7 | `ev_drink_espresso_dentist` | espresso | no |
| `npc_vendor` | Market vendor | one_off | L8 | `ev_drink_honeylav_vendor` | honey_lavender_lemonade | yes |
| `npc_architect` | Imogen Vance-Okoro | one_off | L9 | `ev_drink_latte_sketch_art` | latte | yes |
| `agnes_pell` | Ms. Agnes Pell | one_off | L10 | `ev_drink_cappuccino_quiet` | cappuccino | yes |
| `juno_park` | Juno Park | one_off | L11 | `ev_drink_mocha_juno` | mocha | yes |
| `record_store_owner` | Lou Marchetti | one_off | L12 | `ev_drink_iced_on_beat` | iced_coffee | yes |
| `rosa_pemberton` | Rosa Pemberton | one_off | L14 | `ev_drink_vanilla_orchid` | vanilla_latte | yes |
| `ray_pemberton` | Ray Pemberton | one_off | L14 | `ev_gen_two_customers_chat` | black_coffee | yes |
| `coworker_npc` | Co-worker | one_off | L16 | `ev_drink_seasonal_board` | seasonal_special | yes |
| `food_critic` | Quiet critic | one_off | L3 | `ev_gen_critic_visit` | black_coffee | yes |
| `marge_holloway` | Marge 'Mile Marker' Holloway | one_off | L6 | `ev_gen_marge_checkin` | black_coffee | yes |
| `queue_npc` | Queue customers (generic crowd) | crowd | L1 | `ev_gen_weather_turn` | classic_lemonade | yes |
| `customer` | Any customer (generic) | crowd | L1 | `ev_gen_review_board` | classic_lemonade | yes |

- **Neighbor kid** (`neighbor_kid`): Kid from next door with a fistful of quarters; the very first customer. Reviews: "Best. Lemonade. On the whole street!" / "It's lemon-y AND sugar-y. Telling everyone." / "Still lemonade! Lemonade is always good."
- **Dana (player character)** (`dana`): The player. Listed so event lines can name Dana as a speaker; never queues or orders. Reviews: "Nailed it. Writing that one on the sticky note." / "Not bad! Next one's even better." / "Okay, note to self: more lemon. Still proud."
- **Priya Okafor** (`priya_okafor`): Owner of the Whisker & Bean cat cafe. Debuts in her L2 pink-lemonade event (with Biscuit), then comes back as a regular-for-a-day after great serves. Reviews: "My usual, and somehow better. Purr-fect." / "Just how I like it, give or take a whisker." / "Bit of a hairball day for this one, but I'm smiling!"
- **Biscuit (the cat)** (`biscuit`): The Whisker & Bean cat. Wanders in, sniffs cups, never orders. Reviews: "(Slow blink. A purr like a tiny engine.)" / "(Biscuit sniffs the cup and sits on your foot.)" / "(Biscuit headbutts the cup. Approved anyway.)"
- **Soggy cyclist** (`cyclist_from_l3`): Drenched cyclist from the L3 rainy drive who shelters at the stand. Reviews: "Worth every puddle on the way here." / "Hit the spot. My socks disagree, but I don't." / "Rain got in it? Fair. I'm half rain too. Cheers!"
- **Grandpa Walt Hale** (`grandpa_train_shop`): Retired conductor from the L4 train shop; strawberry lemonade fan and caboose collector. Reviews: "All aboard! First-class lemonade." / "Right on schedule. Good and sweet." / "A little late to the station, but it arrived. Toot toot!"
- **Duckling** (`duckling`): A very small duck at the L5 pond. Waddles, quacks, does not drink lemonade. Reviews: "Quack! (one tiny happy hop)" / "Quack. (polite little waddle)" / "Quack? (it pats the cup with one webbed foot, kindly)"
- **Delbert Finch** (`delbert_finch`): Retired watchmaker in the bakery loft building. Times every coffee to the second. Reviews: "Precise. Like a well-wound watch." / "Ticks along nicely." / "Running a few seconds slow, as do I. Thank you kindly."
- **Dr. Barry Plum** (`retiring_dentist`): Cheerful dentist on his last day at the L7 office; espresso, no sugar, 'for professional reasons'. Reviews: "A flawless shot. I'd floss with joy." / "Good bite to it. No cavities detected." / "A gentle little espresso. Very kind to the teeth!"
- **Gerald (the fish)** (`gerald`): The dentist's goldfish and VIP of the L7 move. Watches from his bowl. Reviews: "(Gerald does a delighted loop.)" / "(Gerald blows one approving bubble.)" / "(Gerald blinks. He loves you regardless.)"
- **Market vendor** (`npc_vendor`): Honey seller at the L8 Saturday market who trades a jar for a honey-lavender lemonade. Reviews: "That's my honey singing in there!" / "Sweet and calm. Bees would approve." / "A bit shy on the honey. I'll bring you an extra jar!"
- **Imogen Vance-Okoro** (`npc_architect`): Architect from the L9 job who sketches on everything, including latte foam. Reviews: "Clean lines, perfect foam. I'd frame it." / "Solid structure. Lovely finish." / "A draft, not a final. Drafts are my favourite part!"
- **Ms. Agnes Pell** (`agnes_pell`): Town librarian moving the library to its new branch at the L10 job. Speaks in a whisper; loves a quiet cappuccino. Reviews: "(whispering) Exquisite. Five quiet stars." / "(whispering) Very nice. Shelved under 'cozy'." / "(whispering) A little loud, but so am I on Thursdays. Thank you."
- **Juno Park** (`juno_park`): Drummer in The Laundromats and a regular at Lou's record shop (L12); drops by the L11 loft. Mocha-powered and always late. Reviews: "This mocha is a ten out of ten. Encore!" / "Solid groove. I'd play this one twice." / "A rough first take! Every great song starts with one."
- **Lou Marchetti** (`record_store_owner`): Record shop owner at the L12 job; keeps a turntable spinning and the iced coffee on beat. Reviews: "Pure groove. Iced coffee on vinyl." / "Nice B-side. Easy listening." / "A little off-beat, but jazz is too. Love it."
- **Rosa Pemberton** (`rosa_pemberton`): Florist with an orchid corner. Debuts in her L14 vanilla-latte event, then comes back as a regular-for-a-day; met Ray in this very line. Reviews: "My usual, and it's in full bloom!" / "Lovely as ever, dear." / "Needs a little sun, like my ferns. Still lovely."
- **Ray Pemberton** (`ray_pemberton`): Rosa's husband-to-be; first met her chatting in your queue. Plain-coffee man. Reviews: "Best cup in town. Don't tell Rosa I said 'best'." / "Good, honest coffee." / "A bit weak, but so are my knees. Cheers, friend."
- **Co-worker** (`coworker_npc`): Friendly teammate in Dana's L16 glass suite who always tries the seasonal special first. Reviews: "New season, new favourite!" / "Nice twist on the season." / "A brave seasonal experiment! I respect it."
- **Quiet critic** (`food_critic`): Notebook-carrying critic who visits once you reach Rep 2 and 30 orders. Silent, then surprisingly kind. Reviews: "(writes for a long time, then smiles) Remarkable." / "(nods) Honest and well made." / "(gentle smile) Promising. I'll be back to see it grow."
- **Marge 'Mile Marker' Holloway** (`marge_holloway`): Dana's mentor and dispatcher; drops in at each office move to check on the shop. Reviews: "That's a mile-marker cup, kiddo. Proud of you." / "Good work. Keep the wheels turning." / "Every road has a bump. You're doing fine."
- **Queue customers (generic crowd)** (`queue_npc`): Generic background customers used for rush hour and weather crowds. Not a character; a crowd tag. Reviews: "Wow, worth the wait!" / "Nice, thanks!" / "No worries, still tasty!"
- **Any customer (generic)** (`customer`): Generic 'any customer' tag used by the review board. Not a character; a crowd tag. Reviews: "Five stars, easy!" / "Pretty good!" / "Still nice! Thanks for trying."

**Id flags:** `dana`: Player character; never orders.
