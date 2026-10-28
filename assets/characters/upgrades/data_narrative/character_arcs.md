# Corner Office: Character Arcs

Full beats in `character_arcs.json` (22 levels × 5 characters = 110 beats). Each beat has an arrival, a Marge email, and a personal moment.

**Naming:** L6 is the **Bakery Loft** (per level specs and Boss's ruling). Flavor text may still call it a shared coworking space; the unlock name is Bakery Loft, not "Shared Coworking."

## Dana Reyes
*Rebuilding confidence after a layoff, one sticky note at a time.*

- Start: Garage Startup, fresh off the Grayline layoff. Whiteboard says "CEO (probably)."
- Act 1: Priya calls her "a natural"; Grandpa's conductor joins the red stapler as "staff of two."
- Act 2: Bakery Loft grand opening (small). The architect's "not bad" is the best review of her career.
- Act 3: Brick Warehouse Loft; the twins name a flower "The Dana."
- Act 4: Hires a helper who calls her a great boss; earns the rival's respect.
- Payoff: Corner office, framed whiteboard: "CEO (definitely)." Hands her sticky notes to the next founder.

## If L5 Duck Pond is cut (Dana, decision Nov 1)

Default: keep Dana's L5 beat ("A duckling refuses to move. Dana waits, smiling. She realizes she hasn't checked the time once."). If L5 is cut, ship **one** variant (both `ship_in: slice`); full text in `character_arcs.json` → `pc_dana` → L5 → `if_l5_cut`.

- **variant_l4 (fold into L4 Train Shop):** Grandpa sends her home by the pond road ("ducks make everyone wait"); a duckling blocks the gravel, the tiny conductor rides on the dash, and Dana waits without checking the time. Marge's L4 email gains two lines: "Bridge is out on the way home. Take the pond road. / One stubborn duckling per trip is the rule." Subject unchanged.
- **variant_l6_open (fold into the opening of L6 Bakery Loft):** Bridge is closed on moving day; New Dana takes the pond road with the whiteboard rattling in the back, waits out a duckling, and only notices at the loft door that she never checked the time. Marge's L6 email gains "Bridge is out, so take the pond road. Ducks first." Subject becomes "A real office, kid (scenic route)".
- **Either way:** drop the L5 email "Detours count as miles"; Rocco's L5 gossip hint is skipped; mint lemonade (L5 unlock) and the duckling event need a new trigger; duck audio can move to the variant's drive.

## Hank "Gravel" Dubois
*A lifelong road dog learning to stay put and call somewhere home.*

- Start: Unit 14B Storage. The string lights turn it into "a palace."
- Act 1: Truce with Biscuit; waits out a duckling and doesn't mind.
- Act 2: Bakery Loft; sleeps through a rainy morning for the first time in years.
- Act 3: A stray cat named Two Lane rides home with him from the night drive.
- Act 4: First time being a boss; the rival also started in a storage unit.
- Payoff: CB radio on the windowsill, a toast with Marge. Leaves his string lights for the next founder.

## Milo Tran
*A fresh grad growing up, from ramen and big talk to a steady hand.*

- Start: Dorm Corner, a HUSTLE poster and lots of ramen.
- Act 1: Biscuit sits on his business cards. Learns to listen to Grandpa.
- Act 2: Roommate's farewell; Bakery Loft; eats a vegetable.
- Act 3: Owns up to his real favourite record and stops pretending.
- Act 4: Hires a helper older than him and cooks the team lunch (not ramen).
- Payoff: Swaps HUSTLE for "Take it easy." Leaves his ramen kettle and some advice.

## Bea Lindqvist
*Scaling her craft from kitchen table to studio without losing its handmade heart.*

- Start: Kitchen Table HQ, her cat in the yarn. Marge would buy two cacti.
- Act 1: A felt Biscuit for Priya; knits Grandpa's conductor a scarf.
- Act 2: Bakery Loft studio; sells six cacti at the market; knitted grand-opening banner.
- Act 3: Thinks about hiring help; decides every order still gets a handwritten note.
- Act 4: Hires her first helper at the Glass suite (L16) and teaches her team the heart of the work. Felt props take a curtain call.
- Payoff: Cacti on every windowsill. Marge holds up her two. Leaves the yarn basket behind.

## Sol Achebe
*A freelancer finding a room of her own, without leaving her people behind.*

- Start: Cafe Corner at Whisker & Bean, with Biscuit as her art director.
- Act 1: Priya's last latte at the old table; Sol's corner moves with her.
- Act 2: Bakery Loft, her first room of her own, with a sign she designed.
- Act 3: Her neon sign lights up the record store. A Biscuit-lookalike follows her truck.
- Act 4: Holds the team lunch at Priya's new cafe and keeps her people close.
- Payoff: A corner office of her own, a toast with Priya, and Biscuit on her keyboard.

## Gaps / notes for Boss
- Helper timing (Boss ruling Oct 23): every character hires the first helper at L16 (Glass suite); the tease is at L15 (`helper_tease_L15` email). L11 only puts up a NOW HIRING sign "for later" (Milo, Bea and Sol's L11 beats no longer hire anyone).
- Client jobs match level-specs (11 entries in `job_briefs.json`). Delbert Finch appears at L4 as Walt's neighbor; Juno Park tags along at L12; Rosa & Ray run L14. Gerald is the dentist's fish (L7), not a clock.
- L16's official name remains **Glass Co-Working Suite** (specs); that is unrelated to the old L6 "Shared Coworking" name.
- `player_characters.md` unlock note updated to say Bakery Loft.
