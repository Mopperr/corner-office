# Customer concept sheets (v2): handoff for Art Specialist

Design Specialist, Oct 23 2026. These are the 8 official customers from `narrative/customers/customers.json` (Narrative Writer). The art is soft stylized-realistic 3D to match Dana, in the style-guide v2 warm palette, on cream.

## Files
- `<id>_sheet.png` (1920x1080): front and side views to scale (440 px/m, with a ruler), personality, favourite drink with its unlock level, 6 hex swatches, key prop and outfit.
- `customers_lineup.png` (1920x1080): all 8 front views to scale next to Dana (1.70 m).
- `customers_spec.json`: the machine-readable version of the table below (heights, palettes, props).
- `gen/`: raw generated turnarounds (`<id>_turn.jpg`) and prop renders (`<id>_prop.jpg`). `gen/cut/` holds the transparent front and side cutouts.
- `cutout.py` cuts the figures out and `build_sheets.py` rebuilds every sheet and the lineup: `python3 cutout.py && python3 build_sheets.py`.
- `_old/`: the first attempt (5 flat placeholder sheets plus its build.py), kept for the record. It's superseded.

Heights are measured to the top of the skull. Hats, buns and hair puffs add extra height on top (the `top_extra_m` field).

## Cast summary

| id | Name | Height | Age | Build | Favourite drink (unlock) | Also likes |
|---|---|---|---|---|---|---|
| `steve` | Steve (StaplerSteve88) | 1.76 m | ~45 | average, soft shoulders | Black Coffee (L6) | Espresso, Vanilla Latte |
| `lamp_lady` | Lorna (Lamp_Lady) | 1.64 m | ~50 | curvy, full figure | Pink Lemonade (L2) | Honey-Lavender Lemonade, Latte |
| `keyclackr` | Kit (KeyClackr) | 1.74 m | ~24 | slim, lanky | Espresso (L7) | Iced Coffee, Black Coffee |
| `dottie` | Dottie Ruiz | 1.55 m | ~72 | short, rounded | Classic Lemonade (L1) | Iced Tea Lemonade, Mocha |
| `theo` | Theo Nakamura | 1.80 m | ~32 | tall, slim-athletic | Latte (L9) | Cappuccino, Black Coffee |
| `pippa` | Pippa Mensah | 1.33 m | 9 | child, small and slim | Classic Lemonade (L1) | Strawberry Lemonade, Pink Lemonade |
| `rocco` | Rocco Delgado | 1.72 m | ~40 | stocky, broad, small belly | Mint Lemonade (L5) | Iced Coffee, Strawberry Lemonade |
| `wren` | Wren Albright | 1.68 m | ~28 | slender, willowy | Honey-Lavender Lemonade (L8) | Cappuccino, Seasonal Special |


## Steve (StaplerSteve88) (`steve`, they/them)
- **Height:** 1.76 m (+0.02 m hat/hair). **Build:** average, soft shoulders. **Age:** ~45.
- **Outfit pieces:** sage button cardigan, cream collared shirt, dusty-blue lanyard + ID badge (#4F7488), brown belt, brown slacks, dark-brown loafers, round wire glasses.
- **Palette:** skin `#E6A977`, hair `#6B4A3A`, cardigan `#6E8A5A`, shirt `#F3DDBC`, slacks `#8A5A36`, stapler `#D9765F`
- **Key prop:** Stapler in a leather belt holster with a brass star. **Size:** stapler 0.16 x 0.05 x 0.07 m; holster 0.18 x 0.07 x 0.10 m (right hip).
- **Personality:** The market regular in person. Earnest collector of office supplies, polite to a fault, tips in exact change.

## Lorna (Lamp_Lady) (`lamp_lady`, she/her)
- **Height:** 1.64 m (+0.13 m hat/hair). **Build:** curvy, full figure. **Age:** ~50.
- **Outfit pieces:** mustard sundress with cream daisies, peach-terracotta cardigan, wide straw sunhat (0.55 m brim), gold hoops (#C9A24A), tan sandals (#8A5A36).
- **Palette:** skin `#B9794F`, hair `#3B2A22`, sundress `#E6B655`, cardigan `#E09A7A`, straw hat `#E8C48A`, tote `#F4E9D8`
- **Key prop:** Big canvas tote with a little brass lamp poking out. **Size:** tote 0.45 x 0.18 x 0.40 m (lamp top reaches 0.58 m); straps 0.60 m loop.
- **Personality:** The lamp-trading regular. Sunny optimist who describes every drink in terms of lighting.

## Kit (KeyClackr) (`keyclackr`, they/them)
- **Height:** 1.74 m (+0.05 m hat/hair). **Build:** slim, lanky. **Age:** ~24.
- **Outfit pieces:** oversized dusty-blue hoodie, black fingerless wrist braces, charcoal joggers, chunky cream sneakers, dark backpack (#3E3A4F).
- **Palette:** skin `#A8693F`, hair `#1E1914`, hoodie `#6A84A0`, joggers `#332E2B`, sneakers `#F4EDE2`, keycaps `#E6B655`
- **Key prop:** Compact 65% mechanical keyboard (lives in the backpack). **Size:** 0.32 x 0.11 x 0.04 m; backpack 0.30 x 0.14 x 0.42 m.
- **Personality:** The keyboard enthusiast. Fast talker, mild typo in everything they say, generous reviewer.

## Dottie Ruiz (`dottie`, she/her)
- **Height:** 1.55 m (+0.06 m hat/hair). **Build:** short, rounded. **Age:** ~72.
- **Outfit pieces:** terracotta blouse, mustard reflective vest with grey reflective stripes (#CFC6BE), dusty-blue slacks, brown loafers (#6B4A3A), silver bun, gold stud earrings.
- **Palette:** skin `#C98A5E`, hair `#E3DCD2`, blouse `#C9714F`, vest `#E9C23E`, slacks `#4F6478`, paddle `#D9765F`
- **Key prop:** Hand-held crossing-guard paddle (octagon, cream border, no lettering). **Size:** octagon 0.25 m across x 0.03 m; total length 0.42 m; handle 0.035 m dia.
- **Personality:** Grandmotherly traffic-controller of the line. Waves everyone forward. Has opinions on lemon wedges.

## Theo Nakamura (`theo`, they/them)
- **Height:** 1.80 m (+0.03 m hat/hair). **Build:** tall, slim-athletic. **Age:** ~32.
- **Outfit pieces:** dusty-blue scrub top and trousers, sage long-sleeve underlayer, white sneakers, pen in chest pocket; lid #3E3A4F.
- **Palette:** skin `#E0A678`, hair `#2B2018`, scrubs `#5F7088`, undershirt `#8C9F72`, sneakers `#F2EDE4`, thermos `#6E86A3`
- **Key prop:** Travel thermos (dusty blue, charcoal flip lid). **Size:** 0.08 m dia x 0.22 m tall.
- **Personality:** Night-shift nurse heading home. Gentle, dry humor, deeply grateful for anything warm.

## Pippa Mensah (`pippa`, she/her)
- **Height:** 1.33 m (+0.07 m hat/hair). **Build:** child, small and slim. **Age:** 9.
- **Outfit pieces:** mustard tee, sage overall skirt, cream knee socks (#F4E9D8), terracotta sneakers, two hair puffs, round gold glasses with colourful stickers (#8FAF7E, #E8B4A8, #7FA3B8).
- **Palette:** skin `#7A4A2A`, hair `#24170C`, t-shirt `#E6B655`, overall skirt `#6F7A50`, sneakers `#D9765F`, clipboard `#C68B59`
- **Key prop:** Wooden clipboard with gold/silver star and 'nice try' frog stickers. **Size:** 0.23 x 0.31 x 0.015 m (child scale).
- **Personality:** Junior lemonade critic and future business mogul. Serious notes, enormous smiles.

## Rocco Delgado (`rocco`, he/him)
- **Height:** 1.72 m (+0.03 m hat/hair). **Build:** stocky, broad, small belly. **Age:** ~40.
- **Outfit pieces:** short-sleeve dusty-blue postal shirt, brown shorts, tall cream socks with blue stripes (#4F7488), charcoal sneakers (#3E3A4F), step-counter watch, sunburned nose (#D9765F blush).
- **Palette:** skin `#B27243`, hair/beard `#2A1E16`, postal shirt `#7F96AA`, shorts `#7A5A36`, socks `#F4EDE2`, satchel `#C9A46C`
- **Key prop:** Mail satchel with envelopes and a parcel. **Size:** 0.36 x 0.14 x 0.30 m; cross-body strap 1.30 m.
- **Personality:** Chatty route-runner who knows every dog by name. Drinks fast, talks faster, never in a bad mood.

## Wren Albright (`wren`, they/them)
- **Height:** 1.68 m (+0.04 m hat/hair). **Build:** slender, willowy. **Age:** ~28.
- **Outfit pieces:** chunky cream knit sweater, very long sage hand-knit scarf (1.8 m, fringed), rolled brown corduroys, brown lace-up boots, ink smudge on right index finger (#3E3A4F).
- **Palette:** skin `#F2CDB0`, hair `#A0471D`, sweater `#EEDFC4`, scarf `#8C9F72`, cords `#7A4A26`, boots `#6B4A3A`
- **Key prop:** Sage pocket notebook, fountain pen and a haiku napkin. **Size:** notebook 0.09 x 0.14 x 0.015 m; pen 0.14 m; napkin 0.12 x 0.12 m folded.
- **Personality:** Quiet poet who writes a tiny haiku about every drink. Soft-spoken, notices everything.

## Shared Dana skeleton notes
- All customers use Dana's humanoid rig so they share her clips. Bone names follow Godot `SkeletonProfileHumanoid` (Hips, Spine, Chest, Neck, Head, Left/RightUpperArm, ...), as in `engine-prep/anim/ANIM_SETUP.md`. The `interact` library and TwoBoneIK3D grips then work unchanged.
- **Adults (Steve, Lorna, Kit, Dottie, Theo, Rocco, Wren):** use the same skeleton with the rest pose adjusted. Scale bone lengths by height / 1.70 (Dana), for example Theo 1.059, Dottie 0.912 and Lorna 0.965. Change bone *rest lengths and offsets*, not node scale, so animation tracks still retarget cleanly. Keep root motion and foot planting in metres.
- **Wide builds (Lorna, Rocco, Dottie):** widen the shoulder and hip offsets by about 8–12% and push the elbow pole targets (`ElbowPoleLeft/Right`) outward by about 5 cm so forearms clear the belly and bust in the carry and pick-up poses. Hold the tote and satchel on a shoulder attachment bone or socket, not on the hands.
- **Slim builds (Kit, Wren, Theo):** use the same proportions, longer for Theo. Wren's 1.8 m scarf needs 2–3 spring bones or a cloth tail, and so does Kit's backpack strap if the budget allows.
- **Pippa (child, 1.33 m):** use a **separate scaled skeleton** (`customer_child`) on the same humanoid profile so clips retarget through the bone map. Use child proportions: the head is about 1/6 of body height (adults about 1/7.5) at roughly 1.15x Dana's head size, shorter legs (about 0.45 of height) and shorter arms. Scale the IK grip targets by about 0.78. She should only use small-prop interactions (no 0.40 m box carry). At a ~1.0 m counter she needs the step-stool idle or a raised order-window pose to reach the counter.
- **Props as attachments:** use BoneAttachment3D. Steve's stapler holster goes on the right hip (Hips), Lorna's tote and Rocco's satchel on the shoulder (UpperChest), Kit's keyboard in the backpack on Chest, Dottie's paddle in the right hand, Theo's thermos in the right hand, Pippa's clipboard held at the chest, and Wren's notebook in the left hand.
- **Materials:** follow style-guide §V2-4 (StandardMaterial3D, palette atlas or vertex colour, no outlines). The hexes above are albedo mids, so pick the Light and Dark steps from §V2-2 where one is close.

## Notes
- Dana's select art is flatter and more 2D-painted than these 3D-style turnarounds. That's fine for concepts, but once all 9 are built in 3D they will match.
- Dottie's paddle has no lettering on purpose (no red 'STOP' text). It is terracotta #D9765F with a cream border, not pure red, so it doesn't clash with the loss red #E0675C that is reserved for trading.
- Ethnicities: Steve is white, Lorna Samoan, Kit Indian-American, Dottie Mexican-American, Theo Japanese-American, Pippa Ghanaian-American, Rocco Afro-Latino and Wren white with red hair. Ages run from 9 to about 72.
