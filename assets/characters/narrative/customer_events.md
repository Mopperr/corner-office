# Customer events (shop)

Machine-readable version: `customer_events.json` (built by `tools/build_customer_events.py`). Drinks: `drink_unlocks.json`. Quality (TUNE, Design Specialist): great ≥ 80, okay 50–79, off < 50.

- No-fail: an off result still pays the base price and offers a gentle redo; reviews never go below 3★ and rep never goes down.
- Tips are % of the drink's base price (products.json owns prices).
- Rep points feed rep_star_gates [0,2,6,12,20,30] in tuning.json; event rep is 0-2.
- chance is rolled once per eligible check; cooldown_orders counts orders served since the event last fired. Max one general event active at a time.
- Line ids are placeholders for Narrative Writer: line_<event_id>_<beat>. Existing names come from narrative/stand_minigame.md.
- Customer lines added for Narrative Writer's 8 customers all start with line_cust_ (signature events: line_cust_<customer>_<event>_<beat>; cameos in existing events: line_cust_<customer>_<beat>).
- Customers (narrative/customers/customers.json) appear from appears_from; before their favourite_drink unlocks they order slice_order.

## Customers (Narrative Writer's 8)

| Customer | Favourite (unlock) | Also likes | Slice order | Appears from | Signature events | All events |
|---|---|---|---|---|---|---|
| Steve (StaplerSteve88) (`steve`) | Black Coffee (L6) | Espresso, Vanilla Latte | Black Coffee | L6 | `ev_cust_steve_staple_rating` | 7 |
| Lorna (Lamp_Lady) (`lamp_lady`) | Pink Lemonade (L2) | Honey-Lavender Lemonade, Latte | Pink Lemonade | L2 | `ev_cust_lamp_lady_golden_hour` | 6 |
| Kit (KeyClackr) (`keyclackr`) | Espresso (L7) | Iced Coffee, Black Coffee | Black Coffee | L6 | `ev_cust_keyclackr_typed_order` | 8 |
| Dottie Ruiz (`dottie`) | Classic Lemonade (L1) | Iced Tea Lemonade, Mocha | Classic Lemonade | L1 | `ev_cust_dottie_crossing_guard`, `ev_cust_dottie_lemon_tree` | 9 |
| Theo Nakamura (`theo`) | Latte (L9) | Cappuccino, Black Coffee | Black Coffee | L6 | `ev_cust_theo_night_shift` | 7 |
| Pippa Mensah (`pippa`) | Classic Lemonade (L1) | Strawberry Lemonade, Pink Lemonade | Classic Lemonade | L1 | `ev_cust_pippa_critique`, `ev_cust_pippa_margins` | 8 |
| Rocco Delgado (`rocco`) | Mint Lemonade (L5) | Iced Coffee, Strawberry Lemonade | Strawberry Lemonade | L4 | `ev_cust_rocco_route_stop` | 8 |
| Wren Albright (`wren`) | Honey-Lavender Lemonade (L8) | Cappuccino, Seasonal Special | Black Coffee | L6 | `ev_cust_wren_haiku_card`, `ev_cust_wren_napkin_wall` | 9 |

## ev_drink_classic_first_sale (drink, Classic Lemonade)
- **Unlock:** L1 after job 1 · **Shop:** lemonade stand
- **Trigger:** first stand session after classic_lemonade unlocks; first customer; chance 100%; once per save
- **Steps:** (1) Neighbor kid walks up holding a fistful of quarters. (2) Orders classic lemonade, 'quiet straw, please'. (3) Tutorial prompts show the 3 steps (lemons → sugar → ice).
- **Resolve:** Make the classic lemonade (tutorial-guided; can't fail).
  - **great:** 50% tip; 5★; +1 rep; Kid drops a quarter in the tip jar; first 5★ review lands.
  - **okay:** 25% tip; 5★
  - **off:** 10% tip; 4★; Kid sips anyway: 'it's still lemonade!'
- **Characters:** neighbor_kid, dana
- **Lines:** `line_ev_drink_classic_first_sale_order`, `line_ev_drink_classic_first_sale_success`, `line_ev_drink_classic_first_sale_okay`, `line_ev_drink_classic_first_sale_off`
- **Note:** Teaches the order → make → serve loop and introduces reviews.

## ev_drink_pink_biscuit_nose (drink, Pink Lemonade)
- **Unlock:** L2 after job · **Shop:** lemonade stand
- **Trigger:** first order of Pink Lemonade after it unlocks; chance 100%; once per save
- **Steps:** (1) The cat cafe owner stops by with Biscuit in a carrier. (2) Asks for 'the pink one, like his nose'. (3) Biscuit watches the pitcher.
- **Resolve:** Make pink lemonade; optional: keep the pour steady (Biscuit tracks the stream).
  - **great:** 40% tip; 5★; +1 rep
  - **okay:** 20% tip; 4★
  - **off:** 5% tip; 3★; Gentle redo offered; customer stays happy. Only a little stock is used.
- **Characters:** priya_okafor, biscuit
- **Lines:** `line_ev_drink_pink_biscuit_nose_order`, `line_ev_drink_pink_biscuit_nose_success`, `line_ev_drink_pink_biscuit_nose_okay`, `line_ev_drink_pink_biscuit_nose_off`, `line_ev_drink_pink_biscuit_nose_biscuit_meow`

## ev_drink_icedtea_after_rain (drink, Iced Tea Lemonade)
- **Unlock:** L3 after drive · **Shop:** lemonade stand
- **Trigger:** first order of Iced Tea Lemonade after it unlocks with weather = after_rain (forced for the first session after L3); chance 100%; once per save
- **Steps:** (1) Rain stops; the sidewalk sparkles. (2) A cyclist in a dripping jacket orders iced tea lemonade. (3) The tea needs a short cool step. (4) Dottie waves the soggy line in under the awning and asks for iced tea lemonade too, 'not too cold, sweetie'.
- **Resolve:** Brew → cool (hold) → lemons → ice. Cooling too short gives 'okay', never 'off' by itself.
  - **great:** 40% tip; 5★; +1 rep
  - **okay:** 20% tip; 4★
  - **off:** 5% tip; 3★; Gentle redo offered; customer stays happy. Only a little stock is used.
- **Characters:** cyclist_from_l3, dottie
- **Lines:** `line_ev_drink_icedtea_after_rain_order`, `line_ev_drink_icedtea_after_rain_success`, `line_ev_drink_icedtea_after_rain_okay`, `line_ev_drink_icedtea_after_rain_off`, `line_cust_dottie_rain_wave`
- **Note:** Dottie is a second order in the same session; she uses the standard outcomes.

## ev_drink_strawberry_caboose (drink, Strawberry Lemonade)
- **Unlock:** L4 after job · **Shop:** lemonade stand
- **Trigger:** first order of Strawberry Lemonade after it unlocks; chance 100%; once per save
- **Steps:** (1) Grandpa (L4 client) shows up with a tiny caboose. (2) Orders 'caboose-red' strawberry lemonade. (3) He sets the caboose on the counter as a timer joke.
- **Resolve:** Muddle strawberries, then the classic steps.
  - **great:** 40% tip; 5★; +1 rep; Grandpa leaves the caboose as a decor gift (toy_train.glb).
  - **okay:** 20% tip; 4★
  - **off:** 5% tip; 3★; Gentle redo offered; customer stays happy. Only a little stock is used.
- **Characters:** grandpa_train_shop
- **Lines:** `line_ev_drink_strawberry_caboose_order`, `line_ev_drink_strawberry_caboose_success`, `line_ev_drink_strawberry_caboose_okay`, `line_ev_drink_strawberry_caboose_off`, `line_ev_drink_strawberry_caboose_caboose_gift`

## ev_drink_mint_duckling (drink, Mint Lemonade)
- **Unlock:** L5 after drive · **Shop:** lemonade stand
- **Trigger:** first order of Mint Lemonade after it unlocks; chance 100%; once per save
- **Steps:** (1) Rocco, on the pond leg of his mail route, orders mint lemonade between steps. (2) A duckling waddles in behind him and sits by the stand.
- **Resolve:** Make mint lemonade. Optional calm serve: skip the noisy ice scoop while the duckling is there.
  - **great:** 40% tip; 5★; +1 rep; Calm serve: +$5 'Duck Friend' tip on top.
  - **okay:** 20% tip; 4★
  - **off:** 5% tip; 3★; Gentle redo offered; customer stays happy. Only a little stock is used.
- **Characters:** rocco, duckling
- **Lines:** `line_ev_drink_mint_duckling_order`, `line_ev_drink_mint_duckling_success`, `line_ev_drink_mint_duckling_okay`, `line_ev_drink_mint_duckling_off`, `line_ev_drink_mint_duckling_duck_quack`
- **Note:** Rocco replaces the generic pond jogger (his favourite drink is mint lemonade).

## ev_drink_black_delbert_clock (drink, Black Coffee)
- **Unlock:** L6 move-in or Rep 1 · **Shop:** coffee counter
- **Trigger:** first order of Black Coffee after it unlocks; chance 100%; once per save
- **Steps:** (1) Delbert Finch arrives winding a pocket clock. (2) Orders black coffee, 'quiet cup'. (3) Coffee counter tutorial: brew → pour.
- **Resolve:** Brew and pour (tutorial-guided).
  - **great:** 40% tip; 5★; +1 rep; Delbert becomes a regular (eligible for ev_gen_regular_returns).
  - **okay:** 20% tip; 4★
  - **off:** 5% tip; 3★; Gentle redo offered; customer stays happy. Only a little stock is used.
- **Characters:** delbert_finch, steve, keyclackr, theo
- **Lines:** `line_ev_drink_black_delbert_clock_order`, `line_ev_drink_black_delbert_clock_success`, `line_ev_drink_black_delbert_clock_okay`, `line_ev_drink_black_delbert_clock_off`, `line_ev_drink_black_delbert_clock_clock_tick`
- **Note:** Coffee counter intro. From the next session, Steve, Kit and Theo join the coffee pool (black coffee is in all three of their favourites).

## ev_drink_espresso_dentist (drink, Espresso)
- **Unlock:** L7 after job · **Shop:** coffee counter
- **Trigger:** first order of Espresso after it unlocks; chance 100%; once per save
- **Steps:** (1) The retired dentist visits with Gerald in his travel bag. (2) Orders an espresso 'before I never hear a drill again'. (3) Gerald's bag sits on the counter.
- **Resolve:** Pull one shot inside the timing window.
  - **great:** 40% tip; 5★; +1 rep
  - **okay:** 20% tip; 4★
  - **off:** 5% tip; 3★; Gentle redo offered; customer stays happy. Only a little stock is used.
- **Characters:** retiring_dentist, gerald
- **Lines:** `line_ev_drink_espresso_dentist_order`, `line_ev_drink_espresso_dentist_success`, `line_ev_drink_espresso_dentist_okay`, `line_ev_drink_espresso_dentist_off`, `line_ev_drink_espresso_dentist_gerald_bubble`

## ev_drink_honeylav_vendor (drink, Honey-Lavender Lemonade)
- **Unlock:** L8 after drive · **Shop:** lemonade stand
- **Trigger:** first order of Honey-Lavender Lemonade after it unlocks; chance 100%; once per save
- **Steps:** (1) The market vendor who waved you through brings honey and a lavender bunch. (2) Asks you to try 'the fancy one'. (3) Recipe card appears (first complexity-3 drink).
- **Resolve:** Steep lavender → honey → lemons → ice.
  - **great:** 40% tip; 5★; +1 rep
  - **okay:** 20% tip; 4★
  - **off:** 5% tip; 3★; Gentle redo offered; customer stays happy. Only a little stock is used.
- **Characters:** npc_vendor
- **Lines:** `line_ev_drink_honeylav_vendor_order`, `line_ev_drink_honeylav_vendor_success`, `line_ev_drink_honeylav_vendor_okay`, `line_ev_drink_honeylav_vendor_off`, `line_ev_drink_honeylav_vendor_honey_gift`

## ev_drink_latte_sketch_art (drink, Latte)
- **Unlock:** L9 after job · **Shop:** coffee counter
- **Trigger:** first order of Latte after it unlocks; chance 100%; once per save
- **Steps:** (1) The architect rushes in and sketches a shape on a napkin. (2) Orders a latte 'with this on top'. (3) The latte-art step shows the napkin sketch as a ghost.
- **Resolve:** Shot → steam → pour; trace the napkin shape (a partial match is fine).
  - **great:** 50% tip; 5★; +1 rep; Architect pins the napkin on your wall (decor).
  - **okay:** 25% tip; 4★
  - **off:** 5% tip; 3★; Gentle redo offered; customer stays happy. Only a little stock is used.
- **Characters:** npc_architect
- **Lines:** `line_ev_drink_latte_sketch_art_order`, `line_ev_drink_latte_sketch_art_success`, `line_ev_drink_latte_sketch_art_okay`, `line_ev_drink_latte_sketch_art_off`, `line_ev_drink_latte_sketch_art_grudging_not_bad`

## ev_drink_cappuccino_quiet (drink, Cappuccino)
- **Unlock:** L10 after job · **Shop:** coffee counter
- **Trigger:** first order of Cappuccino after it unlocks; chance 100%; once per save
- **Steps:** (1) Agnes Pell (librarian) comes in with a book under her arm. (2) Orders a cappuccino in her library voice. (3) Ambience dips; loud actions show a soft 'shh' icon. (4) Wren is already at the window seat, writing; they whisper their cappuccino order after Agnes.
- **Resolve:** Make the cappuccino; quieter actions (slow tamp, gentle steam) count toward great.
  - **great:** 40% tip; 5★; +1 rep
  - **okay:** 20% tip; 4★
  - **off:** 5% tip; 3★; Gentle redo offered; customer stays happy. Only a little stock is used.
- **Characters:** agnes_pell, wren
- **Lines:** `line_ev_drink_cappuccino_quiet_order`, `line_ev_drink_cappuccino_quiet_success`, `line_ev_drink_cappuccino_quiet_okay`, `line_ev_drink_cappuccino_quiet_off`, `line_ev_drink_cappuccino_quiet_shh`, `line_cust_wren_whisper_order`
- **Note:** Wren's cappuccino can trigger ev_cust_wren_haiku_card.

## ev_drink_mocha_juno (drink, Mocha)
- **Unlock:** L11 move-in · **Shop:** coffee counter
- **Trigger:** first order of Mocha after it unlocks; chance 100%; once per save
- **Steps:** (1) Juno Park arrives late, out of breath: 'mocha!! extra whip!!' (2) She tips well, rushed or not.
- **Resolve:** Shot → chocolate → steam; optional extra whip.
  - **great:** 60% tip; 5★; +1 rep
  - **okay:** 35% tip; 5★
  - **off:** 10% tip; 4★; Gentle redo offered; customer stays happy. Only a little stock is used.
- **Characters:** juno_park
- **Lines:** `line_ev_drink_mocha_juno_order`, `line_ev_drink_mocha_juno_success`, `line_ev_drink_mocha_juno_okay`, `line_ev_drink_mocha_juno_off`

## ev_drink_iced_on_beat (drink, Iced Coffee)
- **Unlock:** L12 after job · **Shop:** coffee counter
- **Trigger:** first order of Iced Coffee after it unlocks; chance 100%; once per save
- **Steps:** (1) The record store owner drops off a record and puts it on. (2) Orders iced coffee. (3) Each step on the beat lights the beat ring. (4) Kit drums the beat on the counter; following Kit's drumming counts as on the beat.
- **Resolve:** Cold brew → ice → pour; steps on the beat build a combo (visual ring + haptic).
  - **great:** 40% tip; 5★; +1 rep; Combo of 3: coupon for the record-player decor.
  - **okay:** 20% tip; 4★
  - **off:** 5% tip; 3★; Gentle redo offered; customer stays happy. Only a little stock is used.
- **Characters:** record_store_owner, keyclackr
- **Lines:** `line_ev_drink_iced_on_beat_order`, `line_ev_drink_iced_on_beat_success`, `line_ev_drink_iced_on_beat_okay`, `line_ev_drink_iced_on_beat_off`, `line_ev_drink_iced_on_beat_needle_drop`, `line_cust_keyclackr_drum_along`

## ev_drink_vanilla_orchid (drink, Vanilla Latte)
- **Unlock:** L14 after job · **Shop:** coffee counter
- **Trigger:** first order of Vanilla Latte after it unlocks; chance 100%; once per save
- **Steps:** (1) The florist brings a vanilla pod from her orchid corner. (2) Orders a vanilla latte; her watering can goes on the counter.
- **Resolve:** Shot → vanilla syrup → steam → pour.
  - **great:** 40% tip; 5★; +1 rep
  - **okay:** 20% tip; 4★
  - **off:** 5% tip; 3★; Gentle redo offered; customer stays happy. Only a little stock is used.
- **Characters:** rosa_pemberton
- **Lines:** `line_ev_drink_vanilla_orchid_order`, `line_ev_drink_vanilla_orchid_success`, `line_ev_drink_vanilla_orchid_okay`, `line_ev_drink_vanilla_orchid_off`

## ev_drink_seasonal_board (drink, Seasonal Special)
- **Unlock:** L16 move-in; repeats each in-game season · **Shop:** coffee counter
- **Trigger:** first order of seasonal_special each in-game season; chance 100%; once per season
- **Steps:** (1) Dana chalks the new seasonal flavour on the menu board. (2) A co-worker reads it aloud and orders one. (3) The topping changes with the season (winter spice by L20). (4) Wren is the first in line for every new seasonal flavour.
- **Resolve:** Shot → seasonal syrup → steam → topping.
  - **great:** 40% tip; 5★; +1 rep
  - **okay:** 20% tip; 4★
  - **off:** 5% tip; 3★; Gentle redo offered; customer stays happy. Only a little stock is used.
- **Characters:** coworker_npc, dana, wren
- **Lines:** `line_ev_drink_seasonal_board_board_reveal`, `line_ev_drink_seasonal_board_order`, `line_ev_drink_seasonal_board_success`, `line_ev_drink_seasonal_board_okay`, `line_ev_drink_seasonal_board_off`, `line_cust_wren_seasonal_first`

## ev_gen_regular_returns (general)
- **Unlock:** a customer has 3 great serves · **Shop:** both
- **Trigger:** session start; a customer with >= 3 great serves exists; chance 25%; cooldown 8 orders
- **Steps:** (1) A regular walks in and says 'the usual'. (2) No order card: the player remembers it, or opens the review log to check.
- **Resolve:** Make their usual. Opening the log is allowed and caps the result at okay.
  - **great:** 60% tip; 5★; +1 rep; Loyalty heart +1; at 5 hearts they send a postcard.
  - **okay:** 30% tip; 5★
  - **off:** 10% tip; 4★; Gentle redo offered; customer stays happy. Only a little stock is used.
- **Characters:** delbert_finch, priya_okafor, juno_park, rosa_pemberton, ray_pemberton, agnes_pell, steve, lamp_lady, keyclackr, dottie, theo, pippa, rocco, wren
- **Lines:** `line_ev_gen_regular_returns_greeting`, `line_ev_gen_regular_returns_usual`, `line_ev_gen_regular_returns_success`, `line_ev_gen_regular_returns_okay`, `line_ev_gen_regular_returns_off`
- **Note:** Any of the 8 customers can become a regular; their 'usual' is their favourite_drink once it is unlocked, otherwise slice_order.

## ev_gen_two_customers_chat (general)
- **Unlock:** shop open with 2+ customers queued · **Shop:** both
- **Trigger:** 2 customers in queue for >= 10 s; chance 20%; cooldown 6 orders
- **Steps:** (1) Two customers start chatting (Rosa & Ray Pemberton once met). (2) Their patience timers pause while they talk. (3) One recommends a drink to the other, changing the second order.
- **Resolve:** Serve the changed order; timers stay paused until you start it.
  - **great:** 40% tip; 5★; +1 rep
  - **okay:** 20% tip; 4★
  - **off:** 5% tip; 3★; Gentle redo offered; customer stays happy. Only a little stock is used.
- **Characters:** rosa_pemberton, ray_pemberton, steve, lamp_lady, keyclackr, dottie, theo, pippa, rocco, wren
- **Lines:** `line_ev_gen_two_customers_chat_chat_a`, `line_ev_gen_two_customers_chat_chat_b`, `line_ev_gen_two_customers_chat_order_change`, `line_ev_gen_two_customers_chat_success`, `line_ev_gen_two_customers_chat_okay`, `line_ev_gen_two_customers_chat_off`
- **Note:** Pairs and lines for the 8 customers come from narrative/customers/banter.json (48 exchanges, filtered by context tags); Rosa & Ray keep their scripted first meeting.

## ev_gen_rush_hour (general)
- **Unlock:** 10 orders served in total · **Shop:** both
- **Trigger:** in-game 8:00-9:00 or 12:00-13:00 (lemonade stand: 15:00-16:00); chance 30%; cooldown 15 orders
- **Steps:** (1) Bell rings; 4-5 customers arrive within 20 s. (2) Rush banner; music tempo up a step. (3) Patience timers run 25% slower during the rush.
- **Resolve:** Serve them in any order; batching two of the same drink is allowed.
  - **great:** 30% tip; 5★; +2 rep; All great: 'Rush Hour Hero' stamp.
  - **okay:** 15% tip; 4★; +1 rep
  - **off:** 5% tip; 3★; Gentle redo offered; customer stays happy. Only a little stock is used.
- **Characters:** queue_npc, steve, lamp_lady, keyclackr, dottie, theo, pippa, rocco, wren
- **Lines:** `line_ev_gen_rush_hour_rush_start`, `line_ev_gen_rush_hour_rush_clear_great`, `line_ev_gen_rush_hour_rush_clear_okay`
- **Note:** Band is the average quality across the rush; rep is for the whole rush, not per order. Rush customers are drawn from the 8 customers first (whoever has appears_from met), then queue_npc.

## ev_gen_biscuit_visit (general)
- **Unlock:** L2 completed · **Shop:** both
- **Trigger:** any session; Biscuit not already in the scene; chance 15%; cooldown 10 orders
- **Steps:** (1) Biscuit wanders in and sits on the counter (or the stand's cushion crate). (2) Customers stop to pet him; patience timers pause. (3) He may sit on an ingredient, which then needs a tap to free.
- **Resolve:** Tap Biscuit for a scratch; he leaves after 2 scratches or 1 served order.
  - **great:** 30% tip; 5★; +1 rep; Each customer served while he's there leaves a cat-photo review.
  - **okay:** 30% tip; 5★
  - **off:** 30% tip; 4★; Even an off drink gets 4★: 'the cat was worth it'.
- **Characters:** biscuit, steve, lamp_lady, keyclackr, dottie, theo, pippa, rocco, wren
- **Lines:** `line_ev_gen_biscuit_visit_arrive`, `line_ev_gen_biscuit_visit_pet`, `line_ev_gen_biscuit_visit_customer_aww`, `line_ev_gen_biscuit_visit_leave`

## ev_gen_kid_short_quarter (general)
- **Unlock:** lemonade stand open · **Shop:** lemonade stand
- **Trigger:** neighbor_kid in the queue; chance 20%; cooldown 12 orders
- **Steps:** (1) Neighbor kid is one quarter short and glances at the tip jar.
- **Resolve:** Choose 'On the house' or 'Pay me next time'. Both are good.
  - **great:** 0% tip; 5★; +1 rep; Kid's parent leaves a 5★ review later.
  - **okay:** 0% tip; 5★; Kid pays double next visit.
  - **off:** No off outcome; it's a choice.
- **Characters:** neighbor_kid
- **Lines:** `line_ev_gen_kid_short_quarter_short`, `line_ev_gen_kid_short_quarter_on_house`, `line_ev_gen_kid_short_quarter_next_time`, `line_ev_gen_kid_short_quarter_payback`

## ev_gen_critic_visit (general)
- **Unlock:** Rep 2+ and 30 orders served · **Shop:** both
- **Trigger:** session start; chance 10%; cooldown 30 orders
- **Steps:** (1) A quiet customer with a notebook orders your most complex unlocked drink. (2) No timer is shown. (3) If Pippa is in the shop, she sits beside the critic and copies their notes.
- **Resolve:** Make the drink; only quality counts.
  - **great:** 50% tip; 5★; +2 rep; 'Hidden Gems' column: framed clipping decor.
  - **okay:** 25% tip; 4★; +1 rep; Polite 4★ mention.
  - **off:** 10% tip; 4★; 'Promising.' (the critic never goes below 4★)
- **Characters:** food_critic, pippa
- **Lines:** `line_ev_gen_critic_visit_arrive`, `line_ev_gen_critic_visit_order`, `line_ev_gen_critic_visit_review_great`, `line_ev_gen_critic_visit_review_okay`, `line_ev_gen_critic_visit_review_off`, `line_cust_pippa_critic_copy`
- **Note:** Flavour only; Pippa does not change the critic's outcome.

## ev_gen_marge_checkin (general)
- **Unlock:** each office move (L6, L11, L16, L21) · **Shop:** both
- **Trigger:** first shop session after an office move; chance 100%; once per office
- **Steps:** (1) Marge 'Mile Marker' Holloway stops by and orders 'whatever's newest'.
- **Resolve:** Serve the newest unlocked drink.
  - **great:** 40% tip; 5★; +1 rep; Marge: 'Logged and loaded.' plus a hint about the next drink.
  - **okay:** 20% tip; 5★
  - **off:** 10% tip; 4★; Gentle redo offered; customer stays happy. Only a little stock is used.
- **Characters:** marge_holloway
- **Lines:** `line_ev_gen_marge_checkin_arrive`, `line_ev_gen_marge_checkin_order`, `line_ev_gen_marge_checkin_logged_and_loaded`, `line_ev_gen_marge_checkin_hint_next`

## ev_gen_weather_turn (general)
- **Unlock:** lemonade stand open · **Shop:** lemonade stand
- **Trigger:** weather changes during a session (rain or heat); chance 100%; cooldown 10 orders
- **Steps:** (1) Rain: customers crowd under the awning and order iced tea lemonade (or hot coffee once the counter is unlocked). (2) Heat: everyone asks for extra ice. (3) Rain: Dottie directs the awning crowd. Heat: Rocco asks for 'all the ice you've got'.
- **Resolve:** Follow the suggestion shown on the order card.
  - **great:** 40% tip; 5★; +1 rep
  - **okay:** 20% tip; 4★
  - **off:** 5% tip; 3★; Gentle redo offered; customer stays happy. Only a little stock is used.
- **Characters:** queue_npc, dottie, rocco
- **Lines:** `line_ev_gen_weather_turn_rain_start`, `line_ev_gen_weather_turn_heat_start`, `line_ev_gen_weather_turn_weather_quip`, `line_cust_dottie_rain_traffic`, `line_cust_rocco_heat_ice`

## ev_gen_review_board (general)
- **Unlock:** 5 reviews received · **Shop:** both
- **Trigger:** end of every session; chance 100%
- **Steps:** (1) The review board shows the session's 3 best reviews and highlights a 'fan favourite' drink.
- **Resolve:** Nothing to do; tap to read.
  - **great:** Average >= 4.5★: board glows; +5% tips next session.
  - **okay:** Average 3.5-4.4★: normal.
  - **off:** Average < 3.5★: Dana's sticky note gives one gentle tip. No penalty.
- **Characters:** dana, customer, steve, lamp_lady, keyclackr, dottie, theo, pippa, rocco, wren
- **Lines:** `line_ev_gen_review_board_fan_favourite`, `line_ev_gen_review_board_tip_note`
- **Note:** Wren's haiku and Pippa's sticker grades show on the board in their own card style.

## ev_cust_steve_staple_rating (customer, Black Coffee)
- **Unlock:** coffee counter open (L6 or Rep 1) · **Shop:** coffee counter
- **Trigger:** Steve is in the queue; chance 25%; cooldown 10 orders
- **Steps:** (1) Steve orders, then asks: 'Are the cups stackable?' (2) Optional mini stack: set 3 spare cups into a neat stack on the counter (uses the stacking controls). (3) Steve rates the drink in staples out of five.
- **Resolve:** Make Steve's order. The cup stack is optional and can't fall badly (cups reset gently).
  - **great:** 40% tip; 5★; +1 rep; Neat stack: Steve 'acquires' a cup for his collection and leaves exact-change +$2.
  - **okay:** 20% tip; 4★; Steve: 'Three staples. Solid binding.'
  - **off:** 5% tip; 3★; Steve: 'Two staples. Still holds the pages together!'
- **Characters:** steve
- **Lines:** `line_cust_steve_staple_rating_order`, `line_cust_steve_staple_rating_stackable_ask`, `line_cust_steve_staple_rating_stack_done`, `line_cust_steve_staple_rating_staples_great`, `line_cust_steve_staple_rating_staples_okay`, `line_cust_steve_staple_rating_staples_off`
- **Note:** Ties the shop back to the stacking game.

## ev_cust_lamp_lady_golden_hour (customer, Pink Lemonade)
- **Unlock:** L2 after job · **Shop:** both
- **Trigger:** in-game 17:00-19:00 and Lorna in the queue; chance 30%; cooldown 10 orders
- **Steps:** (1) Lorna holds her cup up to the low sun before sipping. (2) Bright drinks (clear ice, pink, garnish) catch the light with a soft glow.
- **Resolve:** Make her order; an optional garnish adds 'warm wattage' (counts toward great).
  - **great:** 40% tip; 5★; +1 rep; 'Warm wattage!' She gifts a small lamp decor at her 3rd golden-hour great.
  - **okay:** 20% tip; 4★; 'A cosy 40 watts.'
  - **off:** 5% tip; 3★; 'A little dim, but I brought my own sunshine.'
- **Characters:** lamp_lady
- **Lines:** `line_cust_lamp_lady_golden_hour_order`, `line_cust_lamp_lady_golden_hour_hold_to_light`, `line_cust_lamp_lady_golden_hour_warm_wattage`, `line_cust_lamp_lady_golden_hour_forty_watts`, `line_cust_lamp_lady_golden_hour_dim_but_sunny`, `line_cust_lamp_lady_golden_hour_lamp_gift`

## ev_cust_keyclackr_typed_order (customer, Black Coffee)
- **Unlock:** coffee counter open (L6 or Rep 1) · **Shop:** coffee counter
- **Trigger:** Kit is in the queue; chance 25%; cooldown 10 orders
- **Steps:** (1) Kit types the order on the counter in keyboard rhythm. (2) The order ticket appears as typed text with one friendly typo ('blakc coffee' in the slice; 'expresso', 'lattee' once those unlock). (3) Tap the typo to auto-correct it (or just make the drink; the game knows what Kit meant).
- **Resolve:** Make Kit's order. The typo is a joke, never a trap.
  - **great:** 40% tip; 5★; +1 rep; Kit rates it 'tactile' and posts a 5★ review with a keyboard emoji.
  - **okay:** 20% tip; 4★; 'Linear. Smooth enough.'
  - **off:** 5% tip; 3★; 'Bit mushy, like a membrane board. Still paying!'
- **Characters:** keyclackr
- **Lines:** `line_cust_keyclackr_typed_order_typing`, `line_cust_keyclackr_typed_order_typo_fix`, `line_cust_keyclackr_typed_order_tactile`, `line_cust_keyclackr_typed_order_linear`, `line_cust_keyclackr_typed_order_mushy`
- **Note:** Drink is black_coffee (unlocked L6, when Kit first appears; ticket '1x blakc coffee plz'). Kit's favourite espresso unlocks at L7; from then the ticket can use the 'expresso' variant.

## ev_cust_dottie_crossing_guard (customer)
- **Unlock:** 3 customers queued at once · **Shop:** both
- **Trigger:** 3+ customers in queue and Dottie is one of them; chance 35%; cooldown 12 orders
- **Steps:** (1) Dottie stands up, vest on, and waves the line into order. (2) All patience timers pause for 10 s while she 'directs traffic'. (3) She lets someone ahead of her: 'You go, sweetie, I'm retired.'
- **Resolve:** Nothing extra needed; serve as normal. Dottie is served last and always happily.
  - **great:** 40% tip; 5★; +1 rep; 'Smooth traffic today.' Everyone in the line leaves +1★ (cap 5).
  - **okay:** 30% tip; 5★; 'Nice and orderly.'
  - **off:** 10% tip; 4★; 'Slow down, sweetie. You're doing fine.'
- **Characters:** dottie
- **Lines:** `line_cust_dottie_crossing_guard_stand_up`, `line_cust_dottie_crossing_guard_wave_line`, `line_cust_dottie_crossing_guard_you_go_first`, `line_cust_dottie_crossing_guard_smooth_traffic`, `line_cust_dottie_crossing_guard_slow_down_sweetie`
- **Note:** Pairs well with ev_gen_rush_hour (Dottie can fire inside a rush).

## ev_cust_dottie_lemon_tree (customer, Classic Lemonade)
- **Unlock:** L3 after drive · **Shop:** lemonade stand
- **Trigger:** Dottie has 2 great serves; next lemonade-stand session; chance 100%; once per save
- **Steps:** (1) Dottie brings a paper bag of lemons from Harold's old tree. (2) She tells you about the tree while you make classic lemonade with her lemons.
- **Resolve:** Make classic lemonade with Harold's lemons (they count as perfect lemons).
  - **great:** 50% tip; 5★; +1 rep; 'Harold's lemon tree would be proud.' The lemons become a free restock and a jar-of-lemons decor.
  - **okay:** 30% tip; 5★
  - **off:** 10% tip; 4★; 'Lemons were too sour anyway, sweetie. He always said so.'
- **Characters:** dottie
- **Lines:** `line_cust_dottie_lemon_tree_arrive_bag`, `line_cust_dottie_lemon_tree_harold_story`, `line_cust_dottie_lemon_tree_harold_proud`, `line_cust_dottie_lemon_tree_bag_gift`

## ev_cust_theo_night_shift (customer, Black Coffee)
- **Unlock:** coffee counter open (L6 or Rep 1) · **Shop:** coffee counter
- **Trigger:** in-game 6:00-8:00 and Theo is in the queue; chance 40%; cooldown 10 orders
- **Steps:** (1) Theo shuffles in after a night shift with one heroic yawn. (2) Orders 'a coffee to sleep after, somehow'. (3) Optional quiet serve: the shop dims a little while Theo waits.
- **Resolve:** Make Theo's order hot. Serving it within 60 s counts toward great (a soft timer, no failure).
  - **great:** 40% tip; 5★; +1 rep; Theo thanks you twice, once for each open eye, and leaves a warm 5★.
  - **okay:** 20% tip; 4★; 'Vitals stable.'
  - **off:** 10% tip; 4★; 'I've had worse at 4 a.m. Thank you, truly.'
- **Characters:** theo
- **Lines:** `line_cust_theo_night_shift_yawn`, `line_cust_theo_night_shift_order`, `line_cust_theo_night_shift_thanks_twice`, `line_cust_theo_night_shift_vitals_stable`, `line_cust_theo_night_shift_worse_at_4am`
- **Note:** Drink is black_coffee (unlocked L6, when Theo first appears). His favourite latte unlocks at L9; from then the order line can use the latte variant.

## ev_cust_pippa_critique (customer, Classic Lemonade)
- **Unlock:** L2 after job (after 5 lemonade orders served) · **Shop:** lemonade stand
- **Trigger:** Pippa is in the queue; chance 30%; cooldown 10 orders
- **Steps:** (1) Pippa arrives with her clipboard: 'This is an official review.' (2) She orders a lemonade and watches each step, ticking boxes. (3) Her rubric card shows 3 boxes: Balance (sweet vs sour), Chill (ice), Service (timing).
- **Resolve:** Make the lemonade. Each rubric box gets a sticker: gold star (great), silver star (okay) or the 'nice try' frog (off). She always ends with one kind, specific tip.
  - **great:** 40% tip; 5★; +1 rep; Three gold stars: Pippa's 'Official Seal' sticker goes on the stand (decor).
  - **okay:** 20% tip; 4★; 'Silver star. Room to grow!' plus one tip for the weakest box.
  - **off:** 5% tip; 3★; 'You get the nice-try frog. He's very proud of you.' plus one tip; she comes back next session to re-check.
- **Characters:** pippa
- **Lines:** `line_cust_pippa_critique_arrive_official`, `line_cust_pippa_critique_watching`, `line_cust_pippa_critique_box_balance`, `line_cust_pippa_critique_box_chill`, `line_cust_pippa_critique_box_service`, `line_cust_pippa_critique_gold_seal`, `line_cust_pippa_critique_silver_tip`, `line_cust_pippa_critique_frog_tip`
- **Note:** Strict but kind: the rubric is honest about which box was weakest, but the tone is encouraging, the stars never drop below 3 and rep never goes down. Rubric boxes map to the quality score parts (ingredients/amounts, ice/temperature, timing window).

## ev_cust_pippa_margins (customer)
- **Unlock:** Pippa has 2 critiques done · **Shop:** lemonade stand
- **Trigger:** next Pippa visit after 2 critiques; chance 100%; once per save
- **Steps:** (1) Pippa asks: 'What are your profit margins?' (2) A kid-friendly ledger card shows one drink's price, ingredient cost and profit (from products.json, about 30% margin). (3) She nods seriously and writes it down.
- **Resolve:** Read the card and tap 'Makes sense!'. No wrong answers.
  - **great:** 20% tip; 5★; +1 rep; Pippa: 'Future business partner.' She unlocks her 'Mogul' review stickers.
  - **okay:** No okay outcome; it's a read-and-tap.
  - **off:** No off outcome; it's a read-and-tap.
- **Characters:** pippa
- **Lines:** `line_cust_pippa_margins_margins_ask`, `line_cust_pippa_margins_ledger_card`, `line_cust_pippa_margins_business_partner`
- **Note:** Soft tutorial for the shop economy.

## ev_cust_rocco_route_stop (customer, Strawberry Lemonade)
- **Unlock:** L4 after job · **Shop:** both
- **Trigger:** Rocco is in the queue; chance 30%; cooldown 10 orders
- **Steps:** (1) Rocco jogs up mid-route: 'Two minutes, chief, step count's on!' (2) He delivers one piece of neighbourhood gossip while you make his drink. (3) Serving him fast earns a step-counter 'personal best' bubble.
- **Resolve:** Make his order. Fast is nice, never required: a slow serve just means more gossip.
  - **great:** 40% tip; 5★; +1 rep; 'Signed, sealed, delicious!' His gossip is a hint about the next level or drink unlock.
  - **okay:** 20% tip; 4★; 'Arrived a little dented, but it got here!'
  - **off:** 5% tip; 3★; 'Return to sender? Nah, I'll keep it. Paid in full!'
- **Characters:** rocco
- **Lines:** `line_cust_rocco_route_stop_arrive_route`, `line_cust_rocco_route_stop_gossip`, `line_cust_rocco_route_stop_personal_best`, `line_cust_rocco_route_stop_signed_sealed`, `line_cust_rocco_route_stop_dented`, `line_cust_rocco_route_stop_return_to_sender`
- **Note:** Gossip lines are hints, so Narrative Writer writes one per upcoming level. Drink is strawberry_lemonade (unlocks L4, when Rocco first appears); his favourite mint_lemonade only unlocks at L5, so his L4 order jokes that the mint is 'still in the mail'.

## ev_cust_wren_haiku_card (customer, Black Coffee)
- **Unlock:** L6 (coffee counter open) or L8 honey-lavender · **Shop:** both
- **Trigger:** after serving Wren any drink; chance 100%
- **Steps:** (1) Wren sips slowly and counts the foam bubbles. (2) Instead of the normal review card, a cream haiku card slides in (3 lines, 5-7-5) with the stars underneath. (3) Wren leaves the haiku on a napkin as part of the tip.
- **Resolve:** Nothing extra; the haiku matches the quality band (great, okay or off) and the drink.
  - **great:** 40% tip; 5★; +1 rep; Golden haiku; the napkin is added to the 'Haiku Book' in the review log.
  - **okay:** 25% tip; 5★; Gentle haiku; napkin collected.
  - **off:** 10% tip; 4★; Kind 'brave little cup' haiku; napkin collected. Wren never goes below 4★.
- **Characters:** wren
- **Lines:** `line_cust_wren_haiku_card_sip_count`, `line_cust_wren_haiku_card_haiku_great`, `line_cust_wren_haiku_card_haiku_okay`, `line_cust_wren_haiku_card_haiku_off`, `line_cust_wren_haiku_card_napkin_tip`
- **Note:** Drink is black_coffee (unlocked L6, when Wren first appears); Wren orders black coffee until their favourite honey_lavender_lemonade unlocks at L8, then the card can fire on that too. Haiku text comes from narrative/customers/reviews.json (per_customer.wren and per_customer_product.wren). Design Specialist: the haiku card is a variant of shop_review_card.

## ev_cust_wren_napkin_wall (customer)
- **Unlock:** Haiku Book has 5 napkins · **Shop:** both
- **Trigger:** session start after the 5th napkin; chance 100%; once per save
- **Steps:** (1) Wren notices the napkins and asks to pin them up. (2) Pick a wall spot for a small 'poem corner' (uses the normal placement controls).
- **Resolve:** Place the poem corner anywhere; every spot works.
  - **great:** 0% tip; 5★; +1 rep; Poem corner decor; Wren writes a haiku about the shop itself.
  - **okay:** No okay outcome; placement always succeeds.
  - **off:** No off outcome; placement always succeeds.
- **Characters:** wren
- **Lines:** `line_cust_wren_napkin_wall_notice_napkins`, `line_cust_wren_napkin_wall_pin_request`, `line_cust_wren_napkin_wall_shop_haiku`
