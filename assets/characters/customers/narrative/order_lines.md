# Order Lines

Product source: `/workspace/game/drink_unlocks.json (14 drinks; products.json from Programmer Master not yet present, ids to match)`. Ids: classic_lemonade, pink_lemonade, iced_tea_lemonade, strawberry_lemonade, mint_lemonade, black_coffee, espresso, honey_lavender_lemonade, latte, cappuccino, mocha, iced_coffee, vanilla_latte, seasonal_special.

Rule: Pick product_specific[customer][drink] only if drink unlock_level <= current level. Before a customer's favourite_drink unlocks, they order their slice_order. Wren: black_coffee only until L8.

## steve (appears L6, slice order black_coffee)
**Generic**
- One {product}, please. For the collection. Of memories.
- I'd like to acquire a {product}.
- Could I trouble you for a {product}? Strong as a heavy-duty staple.

**By drink**
- `black_coffee` (L6): Black coffee, please. No frills, like a good standard stapler. / Black coffee, please. I'll acquire a second one if this one's a five-stapler.
- `espresso` (L7): One espresso. Small, dense, reliable. Like a mini stapler.
- `vanilla_latte` (L14): A vanilla latte, please. My weekend treat. Acquiring it now.
- `cappuccino` (L10): Cappuccino, please. Is the foam load-bearing?
- `classic_lemonade` (L1): A classic lemonade. For the classics collection.

## lamp_lady (appears L2, slice order pink_lemonade)
**Generic**
- One {product}, sweetie! Make it glow.
- Ooh, what's brightest today? Surprise me with a {product}.

**By drink**
- `pink_lemonade` (L2): Pink lemonade, sweetie! It matches my sunhat lining.
- `honey_lavender_lemonade` (L8): The honey-lavender, please! It sounds like golden hour.
- `latte` (L9): A latte, please. Lots of foam. Soft lighting for my tummy.
- `seasonal_special` (L16): What's the season today? I'll have it in a cup!
- `iced_tea_lemonade` (L3): Iced tea lemonade! I love how it glows amber.

## keyclackr (appears L6, slice order black_coffee)
**Generic**
- {product}, plz. Sorry. Please. Typing habit.
- One {product}, thx. Thanks. I'm working on it.

**By drink**
- `black_coffee` (L6): Black coffee. Strong. Like a clicky blue switch.
- `espresso` (L7): Espresso, plz. Please. Double-tap speed.
- `iced_coffee` (L12): Iced coffee, cold brew, low latency.
- `latte` (L9): Latte me, friend. Medium foam, high RPM.
- `mocha` (L11): Mocha. I earned it. I finished a build.

## dottie (appears L1, slice order classic_lemonade)
**Generic**
- Slow and steady, dear. One {product}.
- Could I get a {product}? Then go help that nice young man behind me.

**By drink**
- `classic_lemonade` (L1): Lemonade, please, and don't be shy with the sugar.
- `iced_tea_lemonade` (L3): Iced tea lemonade, dear. Light ice. My teeth are retired too.
- `mocha` (L11): A mocha, sweetie. Coffee and chocolate, all in one. What a world.
- `strawberry_lemonade` (L4): Strawberry lemonade, please. Harold grew strawberries too, you know.

## theo (appears L6, slice order black_coffee)
**Generic**
- One {product}... please. Sorry. Long night.
- {product}, please. You're a lifesaver. Professionally speaking.

**By drink**
- `latte` (L9): Latte, hot as you can, extra foam. I'm basically a cloud now.
- `cappuccino` (L10): Cappuccino, please. Extra foam. Foam is a pillow.
- `black_coffee` (L6): Black coffee, please. I'm going to drink it and then sleep. Don't ask.
- `vanilla_latte` (L14): Vanilla latte. Something gentle. It's been a night.
- `mint_lemonade` (L5): Mint lemonade? Sure. It's practically mouthwash, which is basically self-care.

## pippa (appears L1, slice order classic_lemonade)
**Generic**
- One {product}, please. This is for research.
- I'll have a {product}. What's your cost per cup? Just curious.

**By drink**
- `classic_lemonade` (L1): Lemonade, please! I'm grading it, no pressure.
- `strawberry_lemonade` (L4): Strawberry lemonade, extra berries. It's for science.
- `pink_lemonade` (L2): Pink lemonade, please. I'm comparing it to regular. Professionally.
- `mint_lemonade` (L5): Mint lemonade. Extra sour if you can. I'm brave.
- `honey_lavender_lemonade` (L8): One fancy one. The lavender. I'm expanding my palate.

## rocco (appears L4, slice order strawberry_lemonade)
**Generic**
- Quick {product} for the route, buddy!
- One {product}, special delivery to me!

**By drink**
- `mint_lemonade` (L5): Mint lemonade, lots of ice, lots of zing! It's a long block!
- `iced_coffee` (L12): Iced coffee to go! Biscuit the beagle's waiting at number 12.
- `classic_lemonade` (L1): Plain lemonade today. Keeping it classic, like a first-class stamp.
- `black_coffee` (L6): Black coffee to go, buddy. Route waits for no one.

## wren (appears L6, slice order black_coffee)
**Generic**
- A {product}, if it's no trouble.
- Could I have a {product}? Take your time. I'll watch the clouds.

**By drink**
- `honey_lavender_lemonade` (L8): Honey-lavender, please. It sounds like a poem already.
- `cappuccino` (L10): A cappuccino, if it's no trouble. I like a quiet foam.
- `seasonal_special` (L16): The seasonal one, please. I write a poem for each one.
- `latte` (L9): Latte, please. The foam is the poem.
- `iced_tea_lemonade` (L3): Iced tea lemonade, gently made. I'll write about the rain.
- `pink_lemonade` (L2): Pink lemonade, please. It's a lovely color to think in.
- `black_coffee` (L6): Black coffee, please. Plain is a kind of poem too. / A black coffee, if it's no trouble. I'm saving my fancy words for later. / Black coffee. Dark as the line before a new stanza.

## Any customer
- `classic_lemonade`: One Classic Lemonade, please. / Could I get a Classic Lemonade?
- `pink_lemonade`: One pink lemonade, please. The pretty one!
- `iced_tea_lemonade`: One Iced Tea Lemonade, please. / Could I get an Iced Tea Lemonade?
- `strawberry_lemonade`: One Strawberry Lemonade, please. / Could I get a Strawberry Lemonade?
- `mint_lemonade`: One Mint Lemonade, please. / Could I get a Mint Lemonade?
- `black_coffee`: One Black Coffee, please. / Could I get a Black Coffee?
- `espresso`: Just a quick espresso, please.
- `honey_lavender_lemonade`: One Honey-Lavender Lemonade, please. / Could I get a Honey-Lavender Lemonade?
- `latte`: One Latte, please. / Could I get a Latte?
- `cappuccino`: Cappuccino, please. Nice foam if you can.
- `mocha`: Mocha, please. It's a treat day.
- `iced_coffee`: Iced coffee, please. It's warm out!
- `vanilla_latte`: One Vanilla Latte, please. / Could I get a Vanilla Latte?
- `seasonal_special`: I'll try the seasonal special. What is it today?
