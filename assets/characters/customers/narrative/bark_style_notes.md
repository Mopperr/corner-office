# Bark & customer-line style notes (Corner Office)

Short research pass, Oct 23 2026. It covers how well-loved cozy games write short NPC lines, and what that means for our orders, reviews, idle thoughts and banter.

## What the games do

**Animal Crossing (New Horizons)**
- Villager dialogue comes from 8 shared personality pools (lazy, peppy, cranky, and so on) plus small subtype branches. A personal catchphrase at the end of a line makes shared text feel owned.
- Players notice when lines repeat. The games soften this with situational lines (weather, holidays, time of day, friendship level) layered over the base pool.
- Sources: [Nookipedia: Catchphrase](https://nookipedia.com/wiki/Catchphrase), [ACNH modding wiki: Editing Dialogue](https://acnh-modding.fandom.com/wiki/Editing_Dialogue), [Bell Tree Forums: personality subtypes](https://www.belltreeforums.com/threads/personality-subtypes-the-details.522610/)

**Stardew Valley**
- NPC lines are keyed from general to specific: weekday, then heart level (in 2-heart steps), then season, then exact date. The most specific match wins, so a small pool still feels alive.
- Modders treat about 40 lines as a "full" NPC. George ships with about 32.
- The base line for each key should work alone and survive being heard many times.
- Sources: [Stardew Modding Wiki: Tips and Tricks for Dialogue](https://stardewmodding.wiki.gg/wiki/Tips_and_Tricks_for_Dialogue), [Stardew Wiki: Modding:Dialogue](https://wiki.stardewvalley.net/Modding:Dialogue)

**Coffee Talk (Toge Productions)**
- The drink you serve is the conversation's branch point.
- Regulars feel like a sitcom cast you grow fond of.
- Distinct voices came from the team role-playing the characters out loud. Each regular has a speech rhythm you can recognise without a name tag.
- Sources: [MonsterVine interview](https://monstervine.com/2020/03/coffee-talk-interview-brewing-gentle-discussions-on-society/), [Xbox Wire: Blending storytelling in Coffee Talk Episode 2](https://news.xbox.com/en-us/2023/04/20/blending-storytelling-in-coffee-talk-episode-2/), [Fahmi: A letter about Coffee Talk](https://fahmitsu.medium.com/a-letter-about-coffee-talk-a-game-and-an-unconscious-effort-to-learn-cff1149b1cbd)

**General bark craft (Ryan Matejka; Ubisoft's The Division 2 voice design)**
- Every bark does three jobs: it responds to a trigger, tells the player something, and sounds like its speaker.
- Think about how the line makes the *player* feel. An NPC teasing a mistake can read as the developer teasing the player, so tone it down or turn it into encouragement.
- Write several variants per trigger (about 3 to 10) that are genuinely different, not rephrases. Cut extra words.
- At runtime, pick at random with cooldowns and priorities. Write more responses than starters, so a starter/response matrix multiplies variety.
- Sources: [How To Write Video Game Barks (Matejka)](https://howtowriteagame.substack.com/p/how-to-write-video-game-barks), [NPC voice design in The Division 2](https://gameindustrylibrary.com/documents/npc-voice-design-in-the-division-2)

## Takeaways for our lines

1. **Repetition: layer, don't just add.** Keep a sturdy generic pool and put specific lines on top: drink-specific (`per_customer_product`), level-gated (`variants_by_level`, banter `min_level`) and weather/context lines. The most specific match wins, like Stardew. Generic lines must survive the 20th hearing, so avoid one-time jokes in them.
2. **Variety means different shapes, not synonyms.** Vary the opener (avoid every review starting "This is..."/"I think..."), the length, and the sign-off. "Paying!" was closing about 1 in 15 review lines. The customer always pays, and the UI already shows that.
3. **Every line is in character.** Like an Animal Crossing catchphrase, each regular has a fingerprint: Steve rates in staples, Rocco talks in parcels, Wren writes haiku, Kit makes keyboard puns, Dottie says "sweetie". Generic `by_product` lines stay neutral and kind, so anyone can say them.
4. **Short.** Orders are one breath (≤ ~12 words). Idle bubbles are ≤ 40 chars (the checker enforces this). Reviews are 1–2 short sentences. Banter is 2–4 lines, ending on a button.
5. **Warm by design.** Reviews never drop below 3★. "Off" lines notice the miss in a funny, affectionate way ("The lemon's playing hide-and-seek") and never complain ("Mostly water"). Avoid backhanded closers like "...anyway" and "Thanks anyway".
