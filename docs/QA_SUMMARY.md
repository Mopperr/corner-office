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
| UI look | Pass | Paper cut-out cards with outlines and hard shadows, lipped buttons, ribbon titles, colour-coded HUD |
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
10. CI-only: the raid smoke check could see the jar go up when a fence sale and a goal reward outweighed the fine.
11. The HUD status line wrapped and clipped once the ledger was added; it is two short lines now.
12. "Unpack it all for me" sat on top of the Pause button.
13. Stale action buttons showed as duplicate Mend rows for a frame; right-pinned buttons spilled past the screen edge on long captions.
14. Tipped-out pieces could land inside café furniture, under a placed piece, or in a far corner hidden behind a tall piece, where they could not be clicked.
15. The pack phase borrowed the unpack goal ("Set the small plant on the counter") as its objective.

## Closed since the first pass

- Make it by hand: a recipe card for every order, with a tray, slips and a perfect-make bonus.
- Box towers: Stack the boxes piles carried boxes in threes; the top box opens.
- Twelve new items in the job pool, each with a line of its own in the box card.
- Solid traffic on the drive: the truck follows the car ahead and cannot phase through one.
- Packing reads as packing: boxes in a row by the back wall, open or sealed, with counts; click one to use it.
- The Room score card says what the score is for and only shows while placing.

- Bakery loft: ceiling beams gone, skylight glow and a painted picture rail instead.
- Till: the whole board, grouped by rung, in a scrolling column.
- Every dish has its own prop.
- Characters hold poses (raise a hand, nod, shrug, sip, wave) on top of the code-driven walk and idle.
- Sound: every effect the scripts name has a file (checked by smoke). Playback itself still cannot be heard in the container.

## Still open

- No rigged animation data; all movement is code-driven.

## Does it hold two hours?

On paper yes: board, six venues, six shop rungs, the workbench tree, the back
room and 28 goals. The first job now lands within minutes and the HUD shows
today's takings, so the early drop-off risk is lower. Next biggest wins would be
art consistency between procedural props and modelled furniture, and more dish
props at the restaurant rungs.
