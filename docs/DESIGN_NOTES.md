# Design notes: the road to a game worth ten dollars

Running notes on what was decided and why, from 4 Nov 2026 on. Each entry says
what people are likely to love, what they are likely to bounce off, and what was
done about it. Sources for the research are in `docs/FUN_RESEARCH.md`.

## The drive (decided: ridden, not steered)

**What people love in this genre.** Moving Out's van on its world map: a short,
charming trip between levels that never asks for driving skill. Lake's slow
scenic drive is loved by some and called tedious by others, and the ones who
loved it found the autopilot first. Nobody comes to a moving game to drive.

**What they bounce off.** Steering a truck on a grid with a keyboard, a camera
that swings with every correction, a town of grey slabs, a HUD that competes
with the road, and a van that straddles the centre line.

**Done.** The truck keeps its own lane and takes the bends itself. The player
holds the throttle, brakes for what is on the road (cones, bumps, puddles,
ducks, patrols at night) and honks at people on the kerb. The road starts at
the kerb of the place just packed and ends with a reverse into the bay of the
house about to be unpacked, both buildings raised from the job's own blueprint
so the drive and the rooms agree. One objective line carries the next turn or
the next hazard; the minimap, discs, arrow and beacon are gone.

**Still to do.** The town between the two kerbs is better than it was (hills on
the horizon, trees, kerb lines) but the parcels are still boxes with painted
windows; a pass of shopfronts and house rows along the route would finish it.

## Packing and unpacking (decided: feel over features)

**What people love.** Unpacking's snap and foley, the box that folds away with a
whoosh, the room filling up, a clear right and wrong told gently.

**What they bounce off.** People that walk through walls, a figure with empty
hands, text floating over heads, and a helper who does the work for you with
no visible effort.

**Done.** Pieces hop into the box with a bounce and a +1; an emptied box folds
flat; neat placements earn a word, a sparkle and a climbing chime; china
clinks, heavy things thump; the results card shows before and after. Dana
carries the box or the piece in her hands. People now walk round the interior
walls and through the doorways. What she carries slows her and bends her
forward; past fifteen kilos a step can catch, she goes down, the piece lands at
her feet and can break. The trip is rare (about one in eighty metres with a
twenty-kilo piece) so it reads as a story, not a tax.

**Done since.** A place being packed up reads as itself: the loose pieces
start in the room that takes their kind (mugs on the seating floor, the
kettle at the counter, tools in the workshop) rather than on a grid across
the whole floor, so the rooms say what goes together before a box is opened.
Room names are drawn through the walls, like the lettering on a plan.

**Done since.** When Dana puts the lot away herself she knows where things
live: on a plan she tries the rooms that take a piece's kind first, nearest
spot first, before spiralling out from where it lies, so a helper you pay
for does not fill the porch with saucepans.

**Ideas held back.** Dragging a box across the floor (a second way to move heavy
things, slower but safe); a dolly that is pushed rather than carried; two
movers lifting a sofa together with the helper. Each is a system; none is
needed before the rooms themselves are finished.

## The offices (decided: floor plans, like the houses)

**What people love.** A place that reads as somebody's: a counter, a kitchen
behind it, an office upstairs, a loo. The houses already work this way and
they are the best rooms in the game.

**What they bounce off.** The single-room shops (the train shop most of all): one
box of a room with the furniture along the walls, no sense of where anything
goes.

**Done.** Every authored place carries a floor plan now: the cafe with eleven
rooms over two floors (entrance, washroom, seating, counter, kitchen, pantry,
dry store; office, staff room and stock room above), the train shop with
twelve, the bakery with thirteen (the loft studio upstairs), the studio with
nine, the flat with eight, the duck pond shed with five. The rooms tile the
footprint exactly, the stairs stand in the hall, each room has a floor and a
tint by its kind, and the place's own fittings are drawn from the catalogue by
room. The fixtures the goals need (the cafe counter and mug rack, the bakery's
shelf, fern, radiator and stair steps, the train layout board) stand in the
right rooms. The drive builds its kerbside fronts from the same plans.

**Still to do.** The larger offices on the ladder (the Brick Warehouse Loft,
the Glass Co-Working Suite, the Corner Office) at sixteen to twenty-five rooms;
per-room dressing (pendants, tables, counters) so a shop reads as a shop before
the boxes come in; the park shed's pond outside.

## Dana (decided: keep the team's rig, change what she wears and how she smiles)

**What people love.** A lead with a face that reads at a glance and an outfit
that is hers.

**What they bounce off.** A doll in a plain blue jumper with a small, flat face.

**Done.** A new painted face (bigger, brighter eyes with a catchlight and
lashes, lifted brows, a wide smile with a glint of teeth, freckles, a soft
blush) on the same UV layout as the team's; a terracotta rib knit with a cream
collar over navy trousers; a mustard beanie with a bobble on the Head bone. All
procedural, the team's skin tone and rig untouched.

**Done since.** The portrait icons and the expression cards are renders of the
new face (`tools/paint_dana_face.py <expression>`, `tests/figure_peek.tscn`,
`tools/build_dana_portraits.py`), so the HUD matches the figure. Standing still she
shifts her weight, looks round the room or stretches.

## Why each loop (decided: the counter is the point)

**What people love.** A reason. Unpacking's story is told in the objects;
Moving Out's is a company you work for; Lake's is a postal round you chose.
Nobody asks why in a game that has already answered.

**What they bounce off.** A job board with no reason behind it: pack, drive,
unpack, get paid, repeat, and never know who any of it was for.

**Done.** Dana's shop is struggling because nobody on the street knows the
name yet, and every move is somebody who will. The people she moves join a
network that saves with the game; a job with every piece in the right room
adds the friend they bring; the counter's wait between faces shrinks as the
network grows. The results card says "Word gets round · Ada Hartley knows the
counter now", the clipboard opens with the reason and the count, the intro,
Marge's welcome email and the how-to-play page carry it. Each loop has its
own reason in Dana's and Marge's words in `data/narrative/why.json`;
`docs/WHY_EACH_LOOP.md` lays them out.

**Done since.** The loop closes where the player can see it: the people Dana
moved walk into the shop by name with a line about the move, a friend says who
sent them, and the Books page lists them on a People sheet with the move that
put them there and the visits since.

## The chapters' named pieces (done)

**What people love.** A brief that promises a piano and then hands you a
piano. The thing the client is worried about being the thing in your hands.

**Done.** Every chapter job now carries what its brief names, drawn from the
team's catalogue: the dentist's gilt mirror, clocking-in machine and
typewriter; the architect's model ship and globe; the library's tall
bookcase, book trolley and revolving bookcase with stacks of books; the
record shop's record cabinet, aquarium, vinyl crates and speakers; the
florist's pots in three colours and a wheelbarrow; the theatre's upright
piano and stool, trunk, coat stand, standing mirror and accordion; the
broker's photocopier and safe; the lodge's wingbacks, cuckoo clock, fishing
rods, snow globe and chess set. Each recipe stays within the truck's eighteen
places and six floor places, checked by the authoring tool.

## The ending (done)

**What people love.** A bow on it: credits that mean the game is finished,
and a world that stays open afterwards. Nobody wants a cosy game to lock.

**Done.** Finishing L22, The Last Delivery, closes with four pages before
the office comes back: the arc's last moment (the sticky notes handed over),
the people who know the counter with the run's numbers, the credits, and
"From Garage Startup to Corner Office" with Keep playing. Settings has a
Full screen toggle that is remembered between runs.

## The level ladder (next)

L1 to L6 are the slice. L7 to L22 have their narrative beats (the dentist, the
market lane, the night neon, the lighthouse, the warehouse loft, the glass
co-working suite, the corner office, the last delivery) but no venues, jobs or
drives of their own yet. The build list calls for eleven client jobs and six
standalone drives. The plan machinery now makes a venue a day's work: a plan,
a recipe, a drive, a client, the beat's email.

## The family by name

A party of two or more has a name per person, and every bubble says who
is talking: "Ray: By colour." The names come from the client label when
it carries them ("Rosa & Ray Pemberton", "Yuki, Ren and Baba", "Dev and
the boys") and from a first-name pool in `data/clients.json` otherwise
("The Halvorsen family" deals Ingrid, Lars and Sunny). A person on their
own keeps the label as it is, so Grandpa Ellis stays Grandpa Ellis. On the
drive, the ride's verdict ("Smooth Ride") has its own line under the speed,
the awning name boards are painted flat on the board, and the kerb signs
fade out at 38 m so the far end of a street is not a stack of names.
