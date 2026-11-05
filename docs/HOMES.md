# Houses

Every house is a footprint split into rooms per floor (`data/homes.json`,
built by `scripts/homes.gd`). The front door is in the middle of the front
wall; `x`/`z` run from the front-left corner in metres. Interior walls are
drawn waist high with a doorway in the middle of every shared wall that is
long enough. The stairs stand in the same spot on every floor.

| House | Style | Size | Floors | Rooms |
| --- | --- | --- | --- | --- |
| Terrace on Elm Row | brick | 6×8 m | 2 | lounge, kitchen, dining room / landing, bedroom, back bedroom, bathroom |
| Terrace on Mill Lane | clapboard | 6×8 m | 2 | lounge, kitchen, dining room / landing, bedroom, back bedroom, bathroom |
| Semi on Larch Street | render | 8×8 m | 2 | lounge, hall, dining room, kitchen / bedroom, landing, second bedroom, bathroom, box bedroom |
| Semi on Copper Lane | stone | 8×8 m | 2 | lounge, hall, dining room, kitchen / bedroom, landing, second bedroom, bathroom, box bedroom |
| Detached on Station Hill | stone | 10×8 m | 2 | lounge, hall, study, kitchen, dining room / bedroom, landing, second bedroom, bathroom, third bedroom, box room |
| Detached on Harbour Road | brick | 10×8 m | 2 | lounge, hall, study, kitchen, dining room / bedroom, landing, second bedroom, bathroom, third bedroom, box room |
| Bungalow on Mill Lane | clapboard | 10×7 m | 1 | lounge, bedroom, hall, kitchen, bathroom, second bedroom |
| Bungalow on Quay Street | timber | 10×7 m | 1 | lounge, bedroom, hall, kitchen, bathroom, second bedroom |
| Flat on Quay Street | render | 7×6 m | 1 | lounge, kitchen, bedroom, bathroom |
| Flat on Station Hill | stone | 7×6 m | 1 | lounge, kitchen, bedroom, bathroom |
| Townhouse on Harbour Road | brick | 6×7 m | 3 | lounge, kitchen, dining room / landing, bedroom, bathroom, second bedroom / loft |
| Townhouse on Larch Street | clapboard | 6×7 m | 3 | lounge, kitchen, dining room / landing, bedroom, bathroom, second bedroom / loft |
| Cottage on Copper Lane | timber | 8×6 m | 1 | lounge, kitchen, bedroom, bathroom, shed |
| Cottage by the Pond | render | 8×6 m | 1 | lounge, kitchen, bedroom, bathroom, shed |
| Loft on the Quay | brick | 9×7 m | 1 | living space, kitchen, bedroom, bathroom, storage loft |
| Loft on Mill Lane | clapboard | 9×7 m | 1 | living space, kitchen, bedroom, bathroom, storage loft |
| Maisonette on Elm Row | render | 7×8 m | 2 | lounge, kitchen, dining room, study / bedroom, second bedroom, landing, bathroom |
| Maisonette on Harbour Road | stone | 7×8 m | 2 | lounge, kitchen, dining room, study / bedroom, second bedroom, landing, bathroom |
| Villa on Station Hill | stone | 10×10 m | 3 | lounge, hall, dining room, kitchen, utility room, garden shed / bedroom, landing, second bedroom, bathroom, third bedroom, study / loft |
| Villa on Copper Lane | brick | 10×10 m | 3 | lounge, hall, dining room, kitchen, utility room, garden shed / bedroom, landing, second bedroom, bathroom, third bedroom, study / loft |

## Rooms and what belongs in them

| Room kind | Item room tag |
| --- | --- |
| lounge, study | living |
| kitchen, dining room, utility | kitchen |
| bathroom | bathroom |
| bedroom | bedroom |
| loft, box room | loft |
| shed | shed |
| hall, landing | anything |

## What the family already has there

| Room | Pieces |
| --- | --- |
| kitchen | fridge, cooker, bread bin, knife block |
| dining | kitchen chairs |
| utility | laundry basket, paint tins |
| bathroom | bathtub, toilet, pedestal sink, towel stack |
| bedroom | wardrobe, alarm clock, pillow stack |
| lounge | TV stand, television, magazine rack |
| study | telescope, globe |
| hall | standing mirror |
| loft | old suitcase, Christmas box, box of records |
| boxroom | travel trunk |
| shed | lawnmower, ladder, paint tins, watering can |

Two or three of these stand along the far walls of each room (three in a big
room), never in a doorway, never in a wall, never in the box row. Heavy ones
(bath, fridge, mower...) cannot be pocketed.

## Pocketing

Click a piece of theirs: **Leave it** or **Pocket it**. Pocketing adds the
piece to the bag (`Crime.loot`), heat +1, and rolls to be seen: 20% for the
first piece, +15% for each one after, capped at 80%. Seen once, the job pays
a quarter less base and costs a Rep star. The bag sells on the fence row of
the back room at 60% of what the pieces are worth ($12 small, $25 no-box,
$40 heavy, +$6 fragile), once Sal is a fence.
