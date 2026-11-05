# Corner Office — Prioritized Build List (Programmer Master)
Owner: Game Director. Written Oct 14, 2026.
Audience: Programmer Master (Godot 4 / GDScript). Numbers marked **(TUNE)** are starting values for playtests.

**Locked:** Bakery Loft is first unlock · no-fail (base pay always pays; tips/Rep scale skill) · 5 offices + L22 epilogue · 11 client jobs · standalone drives double as random-job variety · Nov 15 slice = L1–L6 (cut L5 Duck Pond if behind).

**Sources:** roadmap.md, corner-office-level-specs.md, programmer-notes.md, style-guide.md, narrative/. Note: `job_briefs.json` lists alternate clients (clocks/Juno/twins); **level-specs L2/L4/L7… are authoritative** until narrative is reconciled.

---

## Shared tuning constants (all priorities)

### Snapping
| Constant | Starting value **(TUNE)** |
|---|---|
| Grid | 0.25 m |
| Default rotation step | 90° |
| Fine rotate (hold modifier) | 15° |
| Wall-mount snap | origin on back face; valid wall points only |
| Soft thunk SFX on valid snap | `sfx_item_snap` / `sfx_box_set_down` |
| Invalid placement | soft shake + `sfx_invalid_placement`; item returns to hand |

### Drive / Box condition
| Constant | Starting value **(TUNE)** |
|---|---|
| Drive length | 60–90 s (L3 ~70 s, L5 ~80 s) |
| Box condition start | 100 |
| Bump (speed bump / puddle / gravel) | −3 to −8 |
| Collision (cone / wall) | −10 |
| Hard brake (rain) | −2 to −4 |
| Padding reduction | ×0.5 damage to that box |
| Heavy-on-bottom | ×0.75 damage to cargo stack |
| Hank perk "Road Legs" | −1 per bump event |
| Mesh swap to damaged box | condition &lt; 70 |

**Tip multiplier from Box condition** (level-specs; tips only — base untouched):

| Box condition | Tip on base **(TUNE)** |
|---|---|
| 90–100% | +50% (+ "Smooth Ride" stamp) |
| 70–89% | +30% |
| 50–69% | +15% |
| &lt;50% | +5% |

### Damage & repair (no-fail)
| Constant | Starting value **(TUNE)** |
|---|---|
| Damage levels | 0 fine · 1 scuffed · 2 chipped (never broken / never lost) |
| Pay cut per scuffed item | −5% of **job base pay** |
| Pay cut per chipped item | −10% of **job base pay** |
| Cap | total cut ≤ **20% of job base pay**; deducted from **tips only** (if tips &lt; cut → tips = $0; base still 100%) |
| Repair | 1–3 taps on glow spots (~1–2 s); Bea perk = 1 tap |
| Tape inventory | **none** for slice (open Q closed) |
| All-fine bonus | +1 Rep star toward "Careful Hands" |

### Offices / Rep gates
| Office | Cost | Unlock gates |
|---|---|---|
| L1 Starter (Dana Garage default) | free | game start |
| L6 Bakery Loft | **$1,500** | $1,500 earned · 3 jobs · **Rep 1** |
| L11 Brick Warehouse Loft | **$5,000** | $5,000 · 8 jobs · **Rep 2** |
| L16 Glass Co-Working Suite | **$15,000** | $15,000 · 16 jobs · **Rep 3** |
| L21 Corner Office | **$40,000** | $40,000 · 24 jobs · **Rep 4** |
| L22 Last Delivery | gift / credits | finish L21 move-in |

Rep 0–5; never decreases. Job gives 1–3 stars from condition / precision / bonuses. Rep 1→Tier 2, Rep 2→Tier 3, Rep 3→Tier 4 (per level-specs).

### Pay / tips / items (Act curves)
| Band | Job base **(TUNE)** | Box tip pool | Flat bonuses |
|---|---|---|---|
| Act 1 (L2, L4) | $100–$150 (L2 $120 / L4 $140) | up to +50% of base | cat $20, duck friend $15, Smooth Ride in tip tier |
| Act 2 | $200–$260 | same tiers | Gerald $25, sketch +$50 |
| Act 3 | $320–$340 | | Night Owl $20, etc. |
| Act 4 | $450–$520 | | scenic +$30 |

**Item / Market price bands** **(TUNE)** — items.json has no prices yet:
| Category | Buy | Sell (fine) | Sell (scuffed / chipped) |
|---|---|---|---|
| Small trade goods | $5–$40 | 60–80% of buy | ×0.7 / ×0.4 |
| Desk electronics | $25–$80 | 55–75% | ×0.7 / ×0.4 |
| Decor | $15–$120 | n/a (place only) | cosmetic kintsugi if chipped in client room |
| Furniture | $50–$400 | | |
| Statement / set pieces | $200–$800 | | |
| Daily Market swing | ±10–25% | | |

Starter money (character): Dana $120 · Sol $130 · Hank $100 · Milo $90 · Bea $110 **(TUNE)**.

---

## P0 — Nov 15 vertical slice (must-have)
Full Act 1 loop + first unlock: **L1 → L2 → L3 → L4 → (L5 if time) → L6**. Ship Dana only; other starters deferred (art manifest). Cut L5 if behind.

| # | Feature / mechanic | Acceptance criteria |
|---|---|---|
| P0.1 | Autoloads: `GameState`, `SaveManager`, `ItemDB`, `JobDB` | Money, Rep, jobs_done, office_id, character persist to `user://` JSON; reload restores mid-office and post-job. |
| P0.2 | MainMenu → Intro → Office | Slice plays as Dana Reyes only ($120, Garage Startup). No character select. CRT boot SFX optional. |
| P0.3 | L1 Garage Startup (Dana) | 6×8 m, 12 start items, 0.25 m grid, wall snaps, rotate 90°/15°, ghost preview, soft thunk. Tutorial: pick / rotate / snap / wall-mount. Whiteboard milestone decals at $100 / $500 / $1,000 earned. |
| P0.4 | Retro computer — Market v0 | Buy/sell ≥8 trade goods; line chart; green/terracotta pills; balance coin; profit pop. Spreadsheet Brain perk stub OK (yesterday price). |
| P0.5 | Job board / clipboard | Offers L2 after L1 unpack tutorial; shows base pay + brief from JobDB. |
| P0.6 | Packing (L2 Cat Cafe) | 18 items; tags **fragile** (needs padding) + **heavy** (bottom hint); seal boxes; padding roll; one random box `has_cat`. |
| P0.7 | Cat box twist | Sealed cat box wobbles + meow; open → tip $20 + museum photo stub + confetti. |
| P0.8 | Truck load | Place boxes in truck bed; heavy-bottom soft hint; door SFX. |
| P0.9 | Drive L3 Rainy Afternoon | Top-down ~70 s; rain braking +15%; bumps/puddles/cones; optional alley (+10% tip vs wobble); ducks auto-stop; Box meter UI; no timer fail. |
| P0.10 | Unpack + repair | Carry in → open → place; damaged items show crack icon; **Repair** (1–3 taps) or **Keep (−$X)**; pay cut per constants above. |
| P0.11 | Job results | Line-by-line: base (always full) → Box tip → bonuses → damage cut (tips only) → Rep stars. Cash tally tween. |
| P0.12 | L4 Grandpa Train Shop | 24 items; **keep-together** sets (split = tip loss only); mystery parts sort → toy-train decor; drive Sunny Main Street (reuse town tile, clear weather). |
| P0.13 | L5 Duck Pond (cuttable) | ~80 s park loop; gravel; honk → ducks faster; +$15 Duck Friend if no near-miss. **Cut if P0.1–P0.12 + L6 slip.** |
| P0.14 | L6 Bakery Loft unlock | Gates $1,500 / 3 jobs / Rep 1; cost $1,500; multi-room 8×10 + nook; height-limit red ghost; move-in decorate; break nook may stub. |
| P0.15 | Scene flow | Office ↔ JobPacking → TruckLoad → Drive → JobUnpack → Results → Office via signals (`job_completed`, `box_damaged`, etc.). |
| P0.16 | Juice minimum | Ghost lerp to cell; snap squash 1.15→0.95→1 (TRANS_BACK); pitch-rand set-down ±8%; Box shake + rattle on bump. |
| P0.17 | Playtest build | Export runnable; 5+ outsiders complete L1→L2→L3→unpack without soft-lock. |

**P0 pay check (L2 example):** base $120 always · Box 95% → tip $60 · cat $20 · 2 scuffed kept → cut min(2×5%×120, tips, 20%×120) = $12 from tips → net tips $68 · total $188 **(TUNE)**.

---

## P1 — Next Fest demo (internal Apr 15 → fest Jun 14–21, 2027)
Demo slice: **Garage + Bakery Loft + ≥2 jobs + trading**, ~45–60 min, progression capped (no Act 3+ offices).

| # | Feature / mechanic | Acceptance criteria |
|---|---|---|
| P1.1 | Demo progression cap | Soft wall after L6 decorate + 2–3 jobs; "Wishlist on Steam" end card; no $5k office. |
| P1.2 | Market v1 | Daily price swing ±10–25%; inventory stack; damage affects resale; chart history ≥7 days. |
| P1.3 | Email app v0 | Marge welcome + job complete notes from `emails.json`; ping SFX. |
| P1.4 | Second character starter | At least one of Sol / Hank / Milo / Bea fully playable (perk + unique L1). Prefer Sol (reuses cafe art) or Hank (Road Legs exercises damage). |
| P1.5 | Drive variety | L3 + L5 both ship; rain + park tiles; shortcut + honk polish. |
| P1.6 | Packing tags complete for Act 1–2 | fragile · heavy · keep-together · padding required. |
| P1.7 | Museum shelf stub | Cat photo + toy train display in L1/L6; click shows flavor. |
| P1.8 | Audio wiring | Act 1–2 music beds, cafe/rain/park ambience, shared SFX bus; mute/volume in options. |
| P1.9 | Options / accessibility | Remap or defaults documented; camera shake toggle; text scale ≥2 sizes. |
| P1.10 | Performance | 60 fps target on mid PC; Steam Deck smoke later (Engine Specialist). |
| P1.11 | Demo build pipeline | Separate export / Steam demo depot; resettable save; no cheat soft-locks. |

---

## P2 — 1.0 (content lock Aug 1 → launch Sep 23, 2027)
Ship L7–L22, all systems.

| # | Feature / mechanic | Acceptance criteria |
|---|---|---|
| P2.1 | Offices L11 / L16 / L21 | Costs & gates per table; vertical placement + zones (L11); helper NPC + comfort (L16); museum hall + free-place (L21). |
| P2.2 | Client jobs ×11 | L2, L4, L7, L9, L10, L12, L14, L17, L19, L20, L22 — each with twist, tags, pay from level-specs. Reconcile `job_briefs.json`. |
| P2.3 | Standalone drives as random-job pool | L3, L5, L8, L13, L15, L18 (+ weather variants) selectable for any job in band. |
| P2.4 | Advanced cargo tags | upright-only · fragile+heavy · heat-sensitive · this-side-up · care-on-arrival · 2-person carry · door rotation · match-sketch · precision 0.1 m. |
| P2.5 | TropicalForest shop | Browse categories, deals (non-stress timer), delivery bell, unbox, place; returns/resale. |
| P2.6 | Customer shop + Vibe | Zone items → visitors + passive income; Vibe from decor/plants/light; Shop Manager app; Marge daily email. |
| P2.7 | All 5 starters | Perks live: Spreadsheet Brain, Cafe Regular, Road Legs, Campus Buzz, Handmade Touch. |
| P2.8 | Rep / referrals | Stars → Rep 1–4 gates; referral unlocks chain jobs. |
| P2.9 | Endless / post-L21 jobs | Random job generator using drive pool + item templates. |
| P2.10 | Save slots + cloud prep | ≥3 local slots; Steam Cloud hooks (Engine Specialist). |
| P2.11 | Achievements | Careful Hands, Duck Friend, Cat Rescue, office unlocks, etc. |
| P2.12 | L22 epilogue | Note-writing → credits; character-specific handoff item. |
| P2.13 | Localization hooks | String tables; EN ship; 4 langs AI+review per roadmap **(A)**. |

**1.0 content targets (aligned roadmap + locked 11 jobs):** 5 offices + epilogue · 11 crafted clients · ≥6 drive variants · ~150 decor/furniture · ~50 Market goods · 5–7 h main path.

---

## P3 — Nice-to-have / post-launch
| # | Feature | Notes |
|---|---|---|
| P3.1 | Tape-rip + bubble-wrap unboxing | Path-follow rip; poppable grid; pure juice. |
| P3.2 | Honk-friends collectible list | Hidden Area2D reactions across all routes. |
| P3.3 | Kintsugi client-room visual + note | Chipped item "adds character." |
| P3.4 | Helper mood / staff-room minigame depth | Beyond comfort score. |
| P3.5 | Toucan Prime membership | TropicalForest late upgrade. |
| P3.6 | Cat barista hire | From Priya arc. |
| P3.7 | Photo mode / diorama cam | Shareable screenshots. |
| P3.8 | New Game+ or challenge stickers | Optional modifiers; still no-fail. |
| P3.9 | Multiplayer / async visit | Out of scope for 1.0. |
| P3.10 | Full physics apple spill (L8) | Simple VFX OK for 1.0; rich physics later. |

---

## Fun moments (ship priority)
Moments that sell the trailer and Next Fest clips — implement juice even if art is stubbed.

1. **Snap juice** — ghost + squash + dust + thunk (P0).
2. **Biscuit in the box** — meow, wiggle, confetti, photo (P0).
3. **Rainbow Smooth Ride** — arrive Box ≥90% after rain (P0).
4. **Alley shortcut choice** — signpost risk/reward (P0).
5. **Whiteboard doodles growing** with earnings (P0).
6. **Cash tally stamps** — Cat / Duck Friend / Careful Hands (P0).
7. **Repair sparkle "Good as new!"** (P0).
8. **Honk → duck waddle** (P0 if L5; else P1).
9. **Keep-together glow + mystery parts → toy train** (P0 L4).
10. **Pastry at Bakery Loft door** morning freebie (P0/P1).
11. **Gerald the fish cab icon** (P2).
12. **Beat-pack vinyl** (P2) / **curtain call** (P2) / **full-circle L22 note** (P2).

---

## Reaction to programmer-notes.md (§6–7)

| Idea | Decision | Why |
|---|---|---|
| 1. Snap juice (ghost, squash, dust, pitch SFX) | **Adopt — P0** | Roadmap: never cut snapping feel. |
| 2. Wiggling cat box | **Adopt — P0** | L2 signature twist. |
| 3. Tape-rip & bubble-wrap unboxing | **Defer — P3** (light tape SFX only in P0) | Delightful but not needed for loop proof. |
| 4. Box meter readable feedback (shake, cracks, rainbow) | **Adopt — P0** | Core skill signal for tips. |
| 5. Animated cash pops & payout tally | **Adopt — P0** | Makes no-fail pay readable and rewarding. |
| 6. Risk/reward alley shortcut | **Adopt — P0** | L3 teaches tradeoff without fail. |
| 7. Honk interactions (+ honk-friends list) | **Adopt honk for L5 — P0/P1; friends list — P3** | Duck honk is slice-worthy; collectathon later. |
| 8. Evolving whiteboard | **Adopt — P0** | Cheap visible progression. |
| 9. Keep-together glow & mystery parts | **Adopt — P0** (L4) | Teaches sets before Act 2. |
| 10. Repair mini-moment | **Adopt — P0** | Turns penalty into cozy action. |
| §7 pay cut −5%/−10% capped 25% of tips, base ≥75% | **Adopt with Director override** | Use **−5% scuff / −10% chip, cap 20% of base, tips-only** so base always pays in full (locked no-fail). |
| §7 no tape inventory | **Adopt** | Confirmed for slice. |
| §7 kintsugi + client note | **Defer — P3** | Flavor after systems solid. |
| Autoload / signal architecture (§2) | **Adopt** | Follow as written. |
| Don't push until slice PR lands (§3) | **Adopt** | Re-check repo; PR still missing as of notes. |
| TropicalForest + customer shop (style-guide) | **Defer systems to P2**; catalog stub OK in P1 Market | Not needed for Nov 15 or demo core loop. |
| Sol/Hank/Milo/Bea starters | **Defer to P1+** (Dana only in P0) | Matches art DEFERRED note. |

---

## Cut order if behind (never cut first)
1. L5 Duck Pond from slice (keep as P1).
2. Whiteboard third milestone / museum photo polish.
3. Alley shortcut (keep straight route only).
4. Market goods count (floor: 5 items).
5. Fine 15° rotate (90° only).
6. **Never cut:** snap feel, no-fail base pay, repair choice, Box tip readability, L2 cat twist, L6 unlock.

---

## Handoff
Programmer Master owns implementation of P0.x against level-specs + this file. Coding Master Boss merges after cloud-agent PR. Flag tuning constants that feel wrong in the first 5 playtests; Game Director adjusts **(TUNE)** values — do not invent new systems without a Director note.
