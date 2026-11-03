# QA pass: Corner Office slice

Played end to end, headless and rendered, on branch `claude/make-slice-playable`
(PR #21). Headless runs drive the real scene with mouse events; rendered runs use
the Compatibility renderer under software GL at 1280x720, so lighting is flatter
than Forward+ on a real GPU.

## What was tested

- Menu → intro → garage pack and place → computer (every page, Next day and the
  night card) → map → rotate view → shop (coffee machine, a customer served by
  hand, the Till ladder upgrade) → three story jobs (pack, truck, drive, unpack,
  results) → Goals → workbench (buy clay, make a mug, sell it, journal) → back
  room (unlock, fence a good) → a generated board job with the helpers (Pack the
  rest for me, Unpack it all for me) → Bakery Loft move → save round trip after
  every step.
- A gallery run that builds every venue (café, train shop, park shed, bakery,
  studio, flat), every rung of the shop ladder in the yard, and the Bakery Loft
  as an office.
- Six different board seeds through the generated job.

## Bugs found and fixed in this pass

1. Shop, TropicalForest, Email, Listings and Till pages overflowed and overlapped
   at the readable font size (cards laid out for 18px copy). Rebuilt with
   containers; the Till had labels wrapping one letter per line and the sign
   button over the text.
2. The Market buyer line was cut mid-sentence and ran under the buttons.
3. The map's info panel sat on top of the Glass Co-Working pin and the board rows
   spilled off the card.
4. A stale "+$28" money pop stayed on screen over the night card.
5. The round rug was unclickable under other pieces in a generated job, and a
   generated job could hand out more wall-hung pieces than a café has hooks.
6. The heavy twist could name two pieces "Tool Tin 2".
7. Carried boxes lined up toward the camera's low corner, so later boxes projected
   below the hint bar and clicks landed on the UI; tipped-out pieces could pile
   onto one square or land outside the room; the level postcard's inner
   containers swallowed clicks on the room behind it; a re-opened box card could
   stay open and eat the next click.
8. With the bigger room framing, the Rotate view button sat over the boxed chair
   in the garage; moved into the left column.
9. The results card was half empty (stars, a line from the client and the jar
   total now fill it).

## Open notes (not fixed)

- No model carries animation data. People, the dog, the cat and the customers
  are animated in code; it reads fine but rigged art would be better.
- Dishes beyond coffee, juice and buns share a few generic props (a plate, a bun).
- The bakery office still has beams; only the garage lost them, as asked.
- The Till's menu shows eight dishes and a "more" line; a scrolling menu would be
  friendlier at the restaurant rung.
- Sound was not checked in the rendered runs (no audio device in the container).

## What I think of the playthrough

The loop works now and has a shape: unpack the garage, trade a little, take a
job, drive, unpack, come home to a shop that has customers. The board and the
goals give a reason to keep going, and the workbench and the back room give two
very different ways to make money when the jar is low. The map is the part most
likely to make someone smile; the drive is the part most likely to make someone
keep playing.

What still holds it back, in order:

1. Pacing. The first fifteen minutes are the garage tutorial and the computer,
   which is a lot of reading before the first drive. The "Box it all for me" and
   "Pack the rest for me" buttons help, but the intro should hand the player a
   job within five minutes.
2. Feedback on money. Pay arrives as a results card and a toast; there is no
   running sense of "I am richer than yesterday" apart from the night card.
   A small ledger chip on the HUD would help.
3. The drive is the strongest minute of the game and also the shortest. Longer
   routes, a second alley, and a reason to honk would stretch it.
4. Art consistency. The procedural props (yard, venues, bike, workbench) sit
   next to the modelled furniture. They match in palette but not in detail;
   either direction (more models, or restyling the models flatter) would settle
   it.
5. The shop is passive until the player clicks a customer. Giving the customer a
   small ask (extra ice, a cutting, "is the cat in?") with a two-choice reply
   would make serving by hand feel like a decision.

Two hours of content is there on paper: the board, six venues, the ladder, the
workbench tree, the back room and the goals. Whether it holds two hours depends
on the pacing points above more than on more systems.

# QA pass three: the recorded playthrough and the rework (29 Oct to 3 Nov)

Played end to end again, headless in CI and on the branch, and recorded once with
Movie Maker (`corner_office_playthrough_part1.mp4`, 16 minutes to the house move's
unpack, then the full take after the rework). Watching the recording is what set
the agenda for this pass: the problems below are the ones a player sees in the first
minute, not the ones a test finds.

## Seen in the recording and fixed

1. **Dana walked backwards.** The team's models face +Z like the built figures, but
   the wrapper turned them 180 degrees, and nothing turned a walker toward its
   motion. Everyone now faces the way they move (`_face_motion`).
2. **Nothing in her hands.** The v2 rig had no carry prop; a kraft box shows on the
   ramp and the actual piece shows when she carries one across the room.
3. **Floating text.** Lines over heads were loose white text; they are speech bubbles
   on a white card with a dark rim, and they fade with the card.
4. **Into the truck for every box.** At the new place the boxes come off into a pile
   on the pavement beside the ramp, and Dana fetches them from the pile; the loading
   pile at the old place stands on the camera's side of the ramp.
5. **People through the truck.** Passers-by bend their line round the back of the
   parked truck.
6. **The drive.** A steep bird's-eye camera over a grey town with a tiny truck. Now a
   low close chase camera that drops back and widens with speed, lane assist on a
   straight, softer walls, a warmer town under a stronger sun with kerb lines, bigger
   route marks, a pillar of light over the bay, the next turn and its distance in the
   objective, and a speed readout.
7. **No music of our own.** Six tracks composed and rendered in code, in rotation.

## Found by the runs and fixed

8. A board recipe could carry four wrapped pieces into a move the bed cannot hold
   (nothing stacks on a wrapped piece); a wrapped piece now costs its whole column.
9. "Pack the rest for me" taped a half-full box shut whenever a hefty piece came
   along; the hefty piece takes a fresh box and the open one stays open.
10. A stale hand record after the shove swallowed the next click; it is cleared.
11. The kettle card, moved to the top centre, sat over the room and took clicks;
    it times out on its own and the run answers it.
12. Spilled pieces could heap on one spot in a crowded room where none could be
    clicked; the fallback now takes any free square first.
13. A click over the family's things with a piece in hand opened their card instead
    of placing; placing wins. Their pictures hang clear of the default hang point.
14. After a forgiveness in the ward the owner takes one more slip, so the forced
    breaks in the test follow the temper limit.

## The fun layer (docs/FUN_RESEARCH.md)

From the research: pieces hop into the box with a bounce and a +1; an emptied box
folds flat and pops away; a neat placement earns a word, a sparkle and a chime that
climbs with each good one in a row; china clinks and heavy things thump; a wrong
room says so; a progress bar for the step; Dana says where a piece lives; the
wrong-room check at Finish with outlines and a fix-or-finish card; "Kitchen done!";
the PERFECT MOVE stamp; the room before and after on the results card; houses with
six to nine of the family's pieces a room and pictures on the walls.

## Still open

- Rendered runs under software GL are slow; a Movie Maker take of the whole slice
  takes two to three hours of wall time at 1080p.
- The L07 to L15 sprites are in the tree, unused by the 3D drive.
- Rocco's v2 look is off his concept (the team's note).
- The combo chime reuses the shelf chime at a shifted pitch; a dedicated set of
  placement tones would read cleaner.
