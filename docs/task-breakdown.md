# Corner Office — Task Breakdown (Coding Master Boss, Oct 14 2026)
Owner of the repo build: the cloud agent (bc-1eba598a…). Nobody else pushes until the slice PR lands; then work goes in as small PRs off main.

## Milestone A — First playable (lock Nov 15): Dana, L1–L6
| Area | Task | Owner |
|---|---|---|
| Build | Main menu, save/load, office placement, trading app, mover job (pack→load→drive→unpack), Dana L1–6 arcs, Bakery Loft unlock ($1,500 + 3 jobs) | Cloud agent (in progress) |
| Code | After PR lands: review it, then own **snap juice** (#1), **damage & repair** (#10 / §7), **payout tally** (#5) as separate PRs | Programmer Master |
| Code | Engine review of the PR: perf, export presets (Win/Mac/Linux), input map, autoload structure | Game Engine Specialist |
| Art | Top-down truck sprite → Biscuit idle + toy train loops → 5 hex fixes + sage beanbag | Art Specialist |
| Design | UI review of menu, computer apps, results screen once PR lands | Design Specialist |
| Audio | Hook-up review once playable; ambience/ folder is empty — fill office + cafe + rain ambience | Audio Producer |
| Narrative | Dana L1–6 polish; job brief text for L2/L4 jobs | Narrative Writer |
| QA | Smoke test plan + playthrough of L1–6 on PR; bug list as GitHub issues | QA Tester |
| Levels | Tune L1–6 numbers (pay, timers-free pacing, unlock costs) against the build | Level Platform Brainstormer |
| Scope | Feature list + cut line; owns the roadmap dates | Game Director |

## Milestone B — Post-slice (Nov 16 → Dec)
- TropicalForest webstore + courier unboxing (tape rip, bubble wrap #3) — cloud agent run, then Programmer Master polish.
- Customer shop / Vibe score / cat barista.
- Sol + Cafe Corner start; character select screen.
- Fun list items #2 wiggling cat box, #4 condition meter feedback, #6 alley shortcut, #7 honks, #8 evolving whiteboard — Programmer Master.

## Milestone C — 1.0 content (freeze Dec 31)
- Levels 7–22 art (Art), arcs (Narrative), tuning (Level Platform).
- Hank / Milo / Bea spaces + props.
- Full QA pass, Steam page prep (mid-Jan).

## Source of truth for features
Game Director's `build-list.md` (P0–P3, acceptance criteria, TUNE numbers) is the feature list. P0 = Milestone A, P1 = B, P2–P3 = C or cut.

## Locked tuning (from Game Director)
- Damage: −5% of base per scuff, −10% per chip, capped at 20% of base, taken from tips only — base always pays in full. No tape inventory in the slice.
- Snapping: 0.25 m grid, 90° rotate + 15° fine rotate.
- Box meter: starts 100; bumps −3 to −8, collisions −10. Tips +50/+30/+15/+5% at ≥90/≥70/≥50/<50.
- Office unlocks: $1.5k / $5k / $15k / $40k, gated by Rep 1–4 and 3/8/16/24 jobs.
