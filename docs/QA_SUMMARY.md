# QA at a glance

Branch `claude/make-slice-playable`, PR #21. Every item below was checked by the
automated playthrough (headless and rendered), the venue gallery and the smoke
tests, which all run in CI.

## Verdict

Playable start to finish. No crashes, no soft locks, saves round-trip after
every step. It is a game now, not a slice; the remaining work is polish and
feel, not missing systems.

## What works

| Area | State | Note |
| --- | --- | --- |
| Garage tutorial | Pass | Place it all / Box it all helpers; clipboard opens itself when you go live |
| Computer pages | Pass | Shop, Market, Forest, Email, Listings, Till, night card, ads sidebar |
| Map | Pass | Illustrated, pins, legend, board rows |
| Jobs (story + daily board) | Pass | 25 clients, twists, goals, contracts; 10 drive routes |
| Drive | Pass | Weather, hazards, two alleys, honk bonus, duck friend |
| Unpack | Pass | Box modal: Take / Set here / Tip it out / auto-unpack |
| Shop ladder | Pass | Lemonade stand to top-end restaurant, yard building with tables |
| Customers | Pass | Cars park, people arrive, thought bubbles, two-choice asks |
| Workshop | Pass | Materials, 32 recipe levels, fix-up to spec, buyer stories |
| Back room | Pass | Fence, night jobs, knockoffs; nudge when broke; raid on the third visit |
| Six venues | Pass | Each dressed, framed, with its own goal |

## Bugs fixed in this pass (9)

1. Five computer pages overflowed at the readable font size.
2. Market buyer line cut mid-sentence under the buttons.
3. Map info panel hid a pin; board rows spilled off the card.
4. Stale money pop over the night card.
5. Round rug unclickable; generated jobs handed out too many wall pieces.
6. Two pieces could get the same "Tool Tin 2" name.
7. Carried boxes projected under the hint bar; tipped-out items piled or left the room; box card could stay open.
8. Rotate view button sat over the boxed chair.
9. Results card half empty.

## Still open

- No rigged animation; people and animals move by code.
- Dishes past coffee, juice and buns share a few generic props.
- The bakery office keeps its ceiling beams.
- Till menu shows eight dishes then "more".
- Sound unchecked in the container (no audio device).

## Does it hold two hours?

On paper yes: board, six venues, six shop rungs, the workbench tree, the back
room and 28 goals. The first job now lands within minutes and the HUD shows
today's takings, so the early drop-off risk is lower. Next biggest wins would be
art consistency between procedural props and modelled furniture, and more dish
props at the restaurant rungs.
