# Wren's haiku (5-7-5 check)

Built by `_haiku.py` (run via `_build.py`). Every haiku Wren says in the narrative data, hand-counted word by word.
Storage: JSON strings use `\n` between the 3 lines. `customer_event_lines.json` haiku lines also carry `lines` (array of 3) and `syllables` ([5,7,5]) for the napkin card, which draws one row per line with a count chip.
Note for Design: `assets/ui_mocks/build_shop_mocks.py` still splits on `" / "` (lines 516, 645, 686); switch to `.split('\n')` or read `lines`.

| # | Where | Haiku | Counts | Changed? |
|---|---|---|---|---|
| 1 | reviews.per_customer.wren.great + line_cust_wren_haiku_card_haiku_great (mock) | Warm between my palms / a small sun I can hold close / thank you, morning hands | 5/7/5 | no (already 5-7-5) |
| 2 | reviews.per_customer.wren.okay + line_cust_wren_haiku_card_haiku_okay | Almost there, just like / the first warm day of April. / Still, I'm glad of it. | 5/7/5 | before: Almost there, like / the first warm day of April. / Still, I'm glad of it.  (4/7/5) |
| 3 | reviews.per_customer.wren.off + line_cust_wren_haiku_card_haiku_off | Brave little cup, you / tried your best and so did I. / Here, for your effort. | 5/7/5 | no (already 5-7-5) |
| 4 | line_cust_wren_napkin_wall_shop_haiku (shop haiku, poem corner) | Warm cups, kind faces / a corner where words can rest / this place is a verse | 5/7/5 | before: Warm cups, kind faces / a corner where words can rest / this place is a poem  (5/7/6: 'po-em' is 2) |
| 5 | line_leave_shiftend_wren_1 (leave line) | The day folds itself / like a napkin, soft and small. / Until tomorrow. | 5/7/5 | no (already 5-7-5) |
| 6 | reviews.per_customer_product.wren.latte.great | Soft foam, like fresh snow / a little heart drawn in white / I'll keep this moment | 5/7/5 | before: Foam like fresh snow / a heart drawn in the white / I'll keep this moment  (4/6/5) |
| 7 | reviews.per_customer_product.wren.honey_lavender_lemonade.great (steam_page + marketing quote) | Lavender evening / honey settles like the dusk / lemon, the first star | 5/7/5 | no (already 5-7-5) |
| 8 | reviews.per_customer_product.wren.black_coffee.great | Dark and plain and warm / nothing extra, nothing missed / the morning, poured out | 5/7/5 | before: Dark, plain, and warm / nothing extra, nothing missed / the morning, poured out  (4/7/5) |
| 9 | reviews.per_customer_product.wren.black_coffee.off | Thin as early light / still, it found my hands. Thank you / for pouring the dawn | 5/7/5 | no (already 5-7-5) |

## Hand counts

**1. reviews.per_customer.wren.great + line_cust_wren_haiku_card_haiku_great (mock)**
- Warm between my palms: warm(1) be-tween(2) my(1) palms(1) = 5
- a small sun I can hold close: a(1) small(1) sun(1) I(1) can(1) hold(1) close(1) = 7
- thank you, morning hands: thank(1) you(1) mor-ning(2) hands(1) = 5

**2. reviews.per_customer.wren.okay + line_cust_wren_haiku_card_haiku_okay**
- Almost there, just like: al-most(2) there(1) just(1) like(1) = 5
- the first warm day of April.: the(1) first(1) warm(1) day(1) of(1) A-pril(2) = 7
- Still, I'm glad of it.: still(1) I'm(1) glad(1) of(1) it(1) = 5

**3. reviews.per_customer.wren.off + line_cust_wren_haiku_card_haiku_off**
- Brave little cup, you: brave(1) lit-tle(2) cup(1) you(1) = 5
- tried your best and so did I.: tried(1) your(1) best(1) and(1) so(1) did(1) I(1) = 7
- Here, for your effort.: here(1) for(1) your(1) ef-fort(2) = 5

**4. line_cust_wren_napkin_wall_shop_haiku (shop haiku, poem corner)**
- Warm cups, kind faces: warm(1) cups(1) kind(1) fa-ces(2) = 5
- a corner where words can rest: a(1) cor-ner(2) where(1) words(1) can(1) rest(1) = 7
- this place is a verse: this(1) place(1) is(1) a(1) verse(1) = 5

**5. line_leave_shiftend_wren_1 (leave line)**
- The day folds itself: the(1) day(1) folds(1) it-self(2) = 5
- like a napkin, soft and small.: like(1) a(1) nap-kin(2) soft(1) and(1) small(1) = 7
- Until tomorrow.: un-til(2) to-mor-row(3) = 5

**6. reviews.per_customer_product.wren.latte.great**
- Soft foam, like fresh snow: soft(1) foam(1) like(1) fresh(1) snow(1) = 5
- a little heart drawn in white: a(1) lit-tle(2) heart(1) drawn(1) in(1) white(1) = 7
- I'll keep this moment: I'll(1) keep(1) this(1) mo-ment(2) = 5

**7. reviews.per_customer_product.wren.honey_lavender_lemonade.great (steam_page + marketing quote)**
- Lavender evening: lav-en-der(3) eve-ning(2) = 5
- honey settles like the dusk: hon-ey(2) set-tles(2) like(1) the(1) dusk(1) = 7
- lemon, the first star: lem-on(2) the(1) first(1) star(1) = 5

**8. reviews.per_customer_product.wren.black_coffee.great**
- Dark and plain and warm: dark(1) and(1) plain(1) and(1) warm(1) = 5
- nothing extra, nothing missed: noth-ing(2) ex-tra(2) noth-ing(2) missed(1) = 7
- the morning, poured out: the(1) mor-ning(2) poured(1) out(1) = 5

**9. reviews.per_customer_product.wren.black_coffee.off**
- Thin as early light: thin(1) as(1) ear-ly(2) light(1) = 5
- still, it found my hands. Thank you: still(1) it(1) found(1) my(1) hands(1) thank(1) you(1) = 7
- for pouring the dawn: for(1) pour-ing(2) the(1) dawn(1) = 5

Also checked, not haiku (no change): idle thought "Five, seven, five...", order lines, banter lines, sip-count and napkin-tip lines.
Ambiguous words avoided: 'poem' (1 or 2) was swapped for 'verse'. 'evening' is counted as 2 (eve-ning), the common reading; it is the approved marketing quote, so it stays.
