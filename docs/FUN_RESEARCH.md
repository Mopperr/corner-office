# What makes moving-and-placing games stick, and what we did about it

A short piece of desk research on the games Corner Office sits beside (Unpacking,
House Flipper, PowerWash Simulator, Moving Out) and the game-feel literature, and the
changes it led to on the branch. Each finding has a line on where it now lives in the
game.

## Findings

1. **Order out of chaos is the core pleasure.** Unpacking's designer Tim Dawson says the
   satisfaction is "creating order out of chaos", and that every placement should read as
   progress toward a finished room. The chaos has to be visible first, the order after.
   - Applied: the boxes come off the truck into a pile on the pavement, the room starts
     with the pieces spilled behind the box row, and the results card now shows a
     **Before** and **After** picture of the room side by side (`_take_photo`,
     `results_ui.gd`), so the transformation is the reward.

2. **Snap and foley carry the feel.** The Limited Run write-up on Unpacking credits the
   "visually satisfying item snap" and the per-item foley for giving things physicality;
   the PAX preview singles out the box that folds away "with a satisfying whoosh" once it
   is empty.
   - Applied: a piece hops into the open box with a bounce and a +1 (`_hop_into_box`),
     an emptied box folds flat and pops away with a whoosh (`_fold_box`), and set-downs
     have foley by material: china clinks, heavy things thump, the rest snap
     (`_set_down_foley`).

3. **Feedback tied to the core action, not spectacle.** The game-feel literature (Juice
   it or lose it; the "juicy interface" studies) agrees that exaggerated feedback works
   when it answers the player's own input, and muddies the game when it is decoration.
   - Applied: every placement is graded on things the player actually chose (right room,
     up on a surface, flush to a wall, snug beside another piece) and only a graded
     placement earns the word, the sparkle and the chime; the chime climbs a step with
     each good placement in a row (`_placement_grade`, `_place_feedback`). Nothing fires
     for a careless drop.

4. **Clear right and wrong, gently.** Unpacking's red outline on a misplaced item is its
   one hard rule, and reviewers note it reads best when the game explains it.
   - Applied: at Finish, pieces standing in the wrong kind of room are outlined and a
     card names them with the choice **Set them right** or **Finish anyway**
     (`_misfit_card`); a wrong-room placement says so over the piece; the first time Dana
     lifts a piece she says where it lives (`_where_it_lives`).

5. **Small completions inside the big one.** House Flipper and PowerWash keep a
   per-room, per-surface percentage so there is always a near goal; a cozy game keeps the
   penalties soft so the loop stays relaxing.
   - Applied: a progress bar for the current step in the hint card, a "Half of it boxed"
     beat while packing, "Kitchen done!" pops when a room's pieces are all home
     (`_room_done_check`), and a **PERFECT MOVE** stamp with confetti and a chime when
     every piece is home and nothing broke. Wrong rooms cost tip, never the job.

6. **Readable characters and a readable road.** Tested on the first recording: a figure
   that walks backwards or passes through a truck breaks the fiction faster than any
   missing feature; a bird's-eye camera over a grey town made the drive the weakest part.
   - Applied: everyone faces the way they move, Dana carries the box or the piece in her
     hands, speech bubbles sit on white cards, passers-by go round the truck, and the
     drive has a low close chase camera, lane assist, a brighter town, a turn cue and a
     speed readout.

## Sources

- GamesRadar, "The making of Unpacking: Developer Witch Beam on bringing the moving indie hit to life"
- Game Developer, "Intimacy from the inanimate in house-moving puzzler Unpacking" and
  "Telling a story through someone's belongings in Unpacking"
- Limited Run Games, "Unpacking Unpacking with Designer Tim Dawson"
- Checkpoint Gaming, "PAX Aus 2019 highlight: Unpacking"
- bugnet.io, "Game feel: why juice matters and how to add it"; wayline.io, "Juice overload: when sensory feedback hurts gameplay"
- "Good feedback for bad players? A preliminary study of 'juicy' interface feedback" (Aalborg University)
- Mechanics of Magic, "Coziness and juiciness in games" (2025)
