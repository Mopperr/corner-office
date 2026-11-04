# Why each loop exists

The one sentence: **the counter out front is the point, and nobody on the
street knows the name on the door yet.** Dana was laid off on a Tuesday and
opened the garage on a Wednesday with a lemonade pitcher on a folding table.
Rent is due whether or not anyone walks in. Every mover job is a person who
will know where the counter is afterwards. The game is about turning
strangers on the corner into regulars, one move at a time.

That gives every loop a reason that points at the same place. The words
Dana and Marge use for each are in `data/narrative/why.json`, which the
clipboard, the results card and the how-to-play page read.

## The network

`GameState.network` is the list of people Dana has moved who now know the
counter. Every finished job with a client adds one name. A job with every
piece in the right room and nothing broken adds the friend they bring. It
saves with the game.

What it does:

- **Footfall.** The wait between faces at the counter is multiplied by
  `1 / (1 + 0.05 × network)`, floored at a half: ten people who know the
  place take a third off the wait, thirty take half. The daily till email
  already counts the visitors, so the player sees the number move.
- **The results card** says so in words: "Word gets round · Ada Hartley
  knows the counter now", or "brings a friend to the counter" on a perfect
  job.
- **The clipboard** opens with Dana's reason for the jobs and the count of
  people who know the counter from them.

Shady jobs (Sal's) add nobody: money without faces.

## The loops, each with its reason

| Loop | Dana's reason | What it feeds |
| --- | --- | --- |
| Packing | You handle somebody's whole life in an afternoon. Pack it right and they trust you with the thing they care about. | The tip, and a client who remembers the name on the box. |
| The drive | The truck is the only advert I can afford. | Honks at the kerb are people who look up; the ones who look up find the counter. |
| Unpacking | The room I leave behind is the one they tell their friends about. | A perfect room sends the client in with a friend. |
| The counter | This is the point of all of it. | Every name in the network shortens the wait for the next face at the till. |
| The computer | Rent does not wait for the next move. | Cash between jobs; the odd piece that makes the counter look like a shop. |
| The workbench | A chipped thing mended is a client who comes back. | Mending keeps the tip and the client. |
| The back room | When the till is empty and the rent is due, Sal's work is money tonight. | Money without faces; heat that keeps the regulars away. |
| The Movers' League | The bigger shop needs the bigger name. | Rank opens the bigger offices and the clients who pay for a reputation. |
| A life of her own | Pickle in the cab. A room that is mine. | The reason to want any of this. |
| The ladder of offices | Each office is a bigger window on a busier street. | A bigger window is a bigger counter and more of the street walking past. |

## Where the player meets it

- The intro card: "Nobody knows you yet. Every job fixes that."
- Marge's welcome email: "Then take the jobs. The counter out front won't
  feed you until the street knows where you are."
- How to play: a first tip, "Why the Jobs".
- The clipboard header, the results card line, and the till email's visitor
  count, every day.

## Referrals and lost names

Once people know the counter, seven board jobs in ten come by referral: the
brief opens with who sent them ("Grandpa Ellis sent them."), drawn from the
network. A job that ends in a shove, a suit or a hand in their things takes
the client's name off the list, and the friend they would have brought with
it; the results card says so.

## What is still only words

The chapter unlock chain (the dentist tells the architect, who tells the
librarian) reads as referral but is a fixed order.
