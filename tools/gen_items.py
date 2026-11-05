"""Generate the big household and office catalogue: data/items/*.json.

    python3 tools/gen_items.py

Each room file holds {"items": {id: def}, "props": {id: [parts]}}. An item
def is the same shape as data/content.json's items (name, model, w, d, h,
mount, room, flavor, fragile, nobox, heavy, bulky) plus "family" and
"variant". A props entry is the primitive list scripts/props.gd builds
from (t box|cyl|sph, s size, p centre, c hex colour, r rotation), the same
format as data/props.json, with y up and the origin at the floor centre.

Items come from families: one builder per family, a few colour ways and a
few named or sized variants each. The team can add more of their own in
the same format (see docs/ITEMS.md); tools/check_items.py validates them.
"""
import itertools
import json
import os
import random

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "data", "items")
DOC = os.path.join(ROOT, "docs", "ITEMS.md")

# ---------------------------------------------------------------- palette
OAK, WALNUT, PINE, DARK = "C68B59", "6B4A3A", "D9B98A", "2B2622"
CREAM, WHITE, CARD = "F4F1EA", "EAE6DC", "E7DCC6"
TERRA, SAGE, MUSTARD, BLUE = "D9765F", "8FA882", "E6B655", "4A6FA5"
ROSE, NIGHT, RED, GREEN = "E8B4A8", "3E3A4F", "B6453F", "5E7B52"
STEEL, GREY, TEAL, PLUM = "C9CED3", "8E8276", "4F8A8B", "6E4B6E"
BRASS, KRAFT, GLASS, BLACK = "C9A24E", "C9A070", "BFD6DA", "1E1B19"

WAYS = {
    "sage": SAGE, "terracotta": TERRA, "mustard": MUSTARD, "blue": BLUE, "rose": ROSE,
    "night": NIGHT, "cream": CREAM, "teal": TEAL, "plum": PLUM, "red": RED, "green": GREEN,
}
WOODS = {"oak": OAK, "walnut": WALNUT, "pine": PINE, "painted white": WHITE, "painted sage": SAGE, "black": BLACK}
METALS = {"brass": BRASS, "steel": STEEL, "black": BLACK, "copper": "B87333"}

rng = random.Random(7)


def B(s, p, c, r=None):
    part = {"t": "box", "s": [round(v, 3) for v in s], "p": [round(v, 3) for v in p], "c": c}
    if r:
        part["r"] = [round(v, 3) for v in r]
    return part


def C(radius, h, p, c, r=None):
    part = {"t": "cyl", "s": [round(radius, 3), round(h, 3)], "p": [round(v, 3) for v in p], "c": c}
    if r:
        part["r"] = [round(v, 3) for v in r]
    return part


def S(radius, p, c):
    return {"t": "sph", "s": [round(radius, 3)], "p": [round(v, 3) for v in p], "c": c}


def legs(w, d, h, c, t=0.04, inset=0.05):
    return [B((t, h, t), (sx * (w / 2 - inset), h / 2, sz * (d / 2 - inset)), c) for sx in (-1, 1) for sz in (-1, 1)]


# ------------------------------------------------------------- families
# Each family: room, mount, base size (w, d, h), builder(w, d, h, col, acc)
# -> parts, colour ways {name: hex}, variants [(suffix, scale, extra)],
# flavour lines ({way} and {variant} fill), and flags.
FAMILIES = []


def family(id, name, room, mount, size, build, ways, variants, flavors, fragile=False, big=False, heavy=False, bulky=False, acc=DARK):
    FAMILIES.append(dict(id=id, name=name, room=room, mount=mount, size=size, build=build, ways=ways, variants=variants,
                         flavors=flavors, fragile=fragile, big=big, heavy=heavy, bulky=bulky, acc=acc))


SIZES3 = [("small", 0.8, {}), ("", 1.0, {}), ("large", 1.25, {})]
SIZES2 = [("", 1.0, {}), ("large", 1.3, {})]
ONE = [("", 1.0, {})]


def pick(d, n):
    keys = list(d.keys())
    return {k: d[k] for k in keys[:n]}


# ---- kitchen
family("mug", "Mug", "kitchen", "small", (0.09, 0.09, 0.1),
       lambda w, d, h, c, a: [C(w * 0.45, h, (0, h / 2, 0), c), C(w * 0.38, 0.01, (0, h - 0.004, 0), WHITE), B((0.03, h * 0.5, 0.015), (w * 0.55, h * 0.55, 0), c)],
       WAYS, [("", 1.0, {}), ("stripe", 1.0, {}), ("chipped", 0.95, {}), ("giant", 1.4, {})],
       ["Somebody's favourite. Everyone has one.", "Tea rings inside, decades deep.", "The handle has been glued twice."], fragile=True)
family("teapot", "Teapot", "kitchen", "small", (0.24, 0.16, 0.18),
       lambda w, d, h, c, a: [S(h * 0.5, (0, h * 0.5, 0), c), C(h * 0.2, 0.03, (0, h * 0.95, 0), c), S(0.02, (0, h * 1.02, 0), a),
                              C(0.02, w * 0.45, (w * 0.42, h * 0.6, 0), c, (0, 0, 1.1)), B((0.025, h * 0.4, 0.025), (-w * 0.45, h * 0.55, 0), a)],
       pick(WAYS, 6), [("", 1.0, {}), ("two-cup", 0.8, {}), ("family", 1.3, {})],
       ["Pours sideways. Always has.", "Brown inside. That is flavour, apparently.", "Still warm, somehow."], fragile=True)
family("plate_stack", "Plate stack", "kitchen", "small", (0.26, 0.26, 0.09),
       lambda w, d, h, c, a: [C(w * 0.5, h * 0.33, (0, h * 0.17, 0), c), C(w * 0.48, h * 0.33, (0, h * 0.5, 0), WHITE), C(w * 0.5, h * 0.33, (0, h * 0.83, 0), c)],
       pick(WAYS, 5), [("", 1.0, {}), ("side plates", 0.75, {}), ("dinner service", 1.2, {})],
       ["Six, and one that does not match.", "Wedding china. Never used. Never will be.", "Chipped on the one you always get."], fragile=True)
family("bowl_set", "Bowl set", "kitchen", "small", (0.22, 0.22, 0.12),
       lambda w, d, h, c, a: [C(w * 0.5, h * 0.5, (0, h * 0.25, 0), c), C(w * 0.42, h * 0.45, (0, h * 0.72, 0), WHITE), C(w * 0.34, h * 0.3, (0, h * 0.95, 0), c)],
       pick(WAYS, 5), SIZES2, ["Cereal, soup, and the big one for crisps.", "They nest. They also wobble."], fragile=True)
family("saucepan", "Saucepan", "kitchen", "small", (0.22, 0.22, 0.14),
       lambda w, d, h, c, a: [C(w * 0.5, h * 0.75, (0, h * 0.37, 0), STEEL), C(w * 0.5, 0.01, (0, h * 0.78, 0), c), S(0.02, (0, h * 0.84, 0), a), B((w * 0.8, 0.02, 0.03), (w * 0.85, h * 0.7, 0), a)],
       {"steel": STEEL, "copper": "B87333", "black": BLACK, "cream": CREAM}, [("", 1.0, {}), ("milk pan", 0.7, {}), ("stock pot", 1.4, {})],
       ["The lid belongs to another pan.", "Burnt on the bottom since the rice incident."])
family("casserole", "Casserole dish", "kitchen", "small", (0.3, 0.24, 0.16),
       lambda w, d, h, c, a: [B((w, h * 0.7, d), (0, h * 0.35, 0), c), B((w * 0.96, h * 0.2, d * 0.96), (0, h * 0.8, 0), c), S(0.02, (0, h * 0.95, 0), a),
                              B((0.06, 0.03, 0.03), (w * 0.53, h * 0.4, 0), c), B((0.06, 0.03, 0.03), (-w * 0.53, h * 0.4, 0), c)],
       pick(WAYS, 5), SIZES2, ["Heavy as sin. Makes a good stew.", "A wedding present with a lid that fits."], fragile=True, heavy=False)
family("chopping_board", "Chopping board", "kitchen", "small", (0.36, 0.26, 0.03),
       lambda w, d, h, c, a: [B((w, h, d), (0, h / 2, 0), c), C(0.015, h + 0.004, (w * 0.42, h / 2, 0), WHITE)],
       WOODS, [("", 1.0, {}), ("bread", 0.8, {}), ("butcher's", 1.3, {})], ["Knife scars in a hundred directions.", "Smells of garlic forever."])
family("utensil_jar", "Utensil jar", "kitchen", "small", (0.12, 0.12, 0.3),
       lambda w, d, h, c, a: [C(w * 0.5, h * 0.5, (0, h * 0.25, 0), c)] + [B((0.015, h * 0.55, 0.015), (sx * 0.03, h * 0.7, sz * 0.03), a) for sx in (-1, 1) for sz in (-1, 0.5)] + [B((0.05, 0.01, 0.03), (0.03, h * 0.98, -0.03), WHITE)],
       pick(WAYS, 6), ONE, ["Spoons, spatulas, a thing nobody can name.", "The whisk is bent. It works."])
family("cookbooks", "Cookbook stack", "kitchen", "small", (0.24, 0.2, 0.14),
       lambda w, d, h, c, a: [B((w, h * 0.3, d), (0, h * 0.15, 0), c), B((w * 0.95, h * 0.3, d * 0.9), (0.01, h * 0.45, 0), a), B((w * 0.9, h * 0.3, d * 0.95), (-0.01, h * 0.75, 0), WAYS["mustard"])],
       pick(WAYS, 5), SIZES2, ["Splashed open at the one recipe that works.", "Three cookbooks. One cook."])
family("fruit_bowl", "Fruit bowl", "kitchen", "small", (0.28, 0.28, 0.14),
       lambda w, d, h, c, a: [C(w * 0.5, h * 0.5, (0, h * 0.25, 0), c), S(0.045, (0.05, h * 0.6, 0.02), WAYS["red"]), S(0.04, (-0.05, h * 0.6, 0.03), WAYS["green"]), S(0.04, (0.0, h * 0.7, -0.05), WAYS["mustard"])],
       pick(WAYS, 5), ONE, ["Two apples and a banana going soft.", "The bowl outlives the fruit every week."], fragile=True)
family("cake_stand", "Cake stand", "kitchen", "small", (0.3, 0.3, 0.18),
       lambda w, d, h, c, a: [C(w * 0.3, 0.02, (0, 0.01, 0), c), C(0.02, h * 0.8, (0, h * 0.45, 0), c), C(w * 0.5, 0.015, (0, h, 0), c)],
       {"glass": GLASS, "cream": CREAM, "rose": ROSE}, ONE, ["For birthdays and the one Victoria sponge.", "Glass. Of course it is glass."], fragile=True)
family("spice_jars", "Spice jars", "kitchen", "small", (0.24, 0.07, 0.1),
       lambda w, d, h, c, a: [C(0.028, h * 0.85, (x, h * 0.43, 0), GLASS) for x in (-0.09, -0.03, 0.03, 0.09)] + [C(0.03, 0.02, (x, h * 0.9, 0), c) for x in (-0.09, -0.03, 0.03, 0.09)],
       pick(WAYS, 4), ONE, ["Paprika, cumin, and a jar of 2011.", "Alphabetical. Somebody's rule."], fragile=True)
family("biscuit_tin", "Biscuit tin", "kitchen", "small", (0.22, 0.22, 0.12),
       lambda w, d, h, c, a: [C(w * 0.5, h * 0.8, (0, h * 0.4, 0), c), C(w * 0.5, h * 0.2, (0, h * 0.9, 0), a), B((w * 0.5, 0.006, w * 0.3), (0, h * 0.5, w * 0.5), CREAM)],
       pick(WAYS, 6), [("", 1.0, {}), ("square", 1.0, {}), ("Christmas", 1.15, {})], ["Sewing things. Never biscuits.", "Dented where it fell in 2009."])
family("coffee_grinder", "Coffee grinder", "kitchen", "small", (0.12, 0.12, 0.22),
       lambda w, d, h, c, a: [B((w, h * 0.55, d), (0, h * 0.28, 0), c), C(w * 0.4, h * 0.3, (0, h * 0.7, 0), STEEL), B((0.08, 0.012, 0.012), (0.04, h * 0.95, 0), a), S(0.015, (0.08, h * 0.95, 0), WOODS["walnut"])],
       pick(WOODS, 4), ONE, ["Hand-cranked, for the ritual.", "Grinds coarse, whatever you ask."])
family("blender", "Blender", "kitchen", "small", (0.16, 0.16, 0.4),
       lambda w, d, h, c, a: [B((w, h * 0.35, d), (0, h * 0.17, 0), c), C(w * 0.42, h * 0.6, (0, h * 0.65, 0), GLASS), C(w * 0.4, 0.02, (0, h * 0.96, 0), a)],
       pick(WAYS, 5), ONE, ["Loud enough to wake the street.", "The lid flies off on high."], fragile=True)
family("stand_mixer", "Stand mixer", "kitchen", "small", (0.22, 0.34, 0.34),
       lambda w, d, h, c, a: [B((w, h * 0.15, d * 0.7), (0, h * 0.07, 0), c), B((w * 0.5, h * 0.75, d * 0.3), (0, h * 0.5, d * 0.3), c), B((w * 0.8, h * 0.25, d * 0.8), (0, h * 0.85, -d * 0.05), c), C(w * 0.5, h * 0.4, (0, h * 0.35, -d * 0.1), STEEL)],
       pick(WAYS, 6), ONE, ["Weighs what it costs. A lot.", "Only comes out for the Christmas cake."], heavy=False)
family("scales", "Kitchen scales", "kitchen", "small", (0.2, 0.2, 0.16),
       lambda w, d, h, c, a: [B((w, h * 0.3, d), (0, h * 0.15, 0), c), C(0.035, h * 0.3, (0, h * 0.45, 0), a), C(w * 0.5, h * 0.3, (0, h * 0.75, 0), STEEL), C(0.04, 0.01, (0, h * 0.32, d * 0.4), WHITE, (1.57, 0, 0))],
       pick(WAYS, 4), ONE, ["Weighs flour and the cat.", "The needle sticks at two hundred."])
family("egg_box", "Egg basket", "kitchen", "small", (0.2, 0.14, 0.12),
       lambda w, d, h, c, a: [B((w, h * 0.6, d), (0, h * 0.3, 0), c)] + [S(0.028, (x, h * 0.7, z), CREAM) for x in (-0.06, 0, 0.06) for z in (-0.03, 0.03)],
       {"wire": STEEL, "wicker": KRAFT, "sage": SAGE}, ONE, ["Half a dozen, one cracked.", "From the hens two doors down."], fragile=True)
family("bread_board", "Bread and board", "kitchen", "small", (0.3, 0.18, 0.12),
       lambda w, d, h, c, a: [B((w, 0.02, d), (0, 0.01, 0), c), B((w * 0.7, h * 0.7, d * 0.7), (0, h * 0.45, 0), KRAFT), B((w * 0.68, 0.01, d * 0.68), (0, h * 0.82, 0), "A67B4C")],
       pick(WOODS, 3), ONE, ["Yesterday's loaf, today's toast.", "The crust end nobody wants."])
family("jug", "Jug", "kitchen", "small", (0.14, 0.14, 0.22),
       lambda w, d, h, c, a: [C(w * 0.45, h, (0, h / 2, 0), c), B((0.04, 0.02, 0.04), (0, h, w * 0.4), c), B((0.025, h * 0.5, 0.02), (-w * 0.52, h * 0.55, 0), a)],
       pick(WAYS, 7), [("", 1.0, {}), ("milk", 0.6, {}), ("water", 1.2, {})], ["Cracked, kept, filled with wooden spoons.", "Pours true. A rare thing in a jug."], fragile=True)
family("wine_rack", "Wine rack", "kitchen", "floor", (0.5, 0.26, 0.6),
       lambda w, d, h, c, a: [B((0.03, h, 0.03), (sx * (w / 2 - 0.02), h / 2, sz * (d / 2 - 0.02)), c) for sx in (-1, 1) for sz in (-1, 1)] + [C(0.035, d * 0.9, (x, y, 0), GREEN if (x + y) % 2 else NIGHT, (1.57, 0, 0)) for x in (-0.15, 0, 0.15) for y in (0.15, 0.32, 0.49)],
       pick(WOODS, 4), SIZES2, ["Nine bottles. Three worth drinking.", "The good one is at the back, on purpose."], fragile=True)
family("bar_stool", "Bar stool", "kitchen", "floor", (0.36, 0.36, 0.72),
       lambda w, d, h, c, a: [C(w * 0.48, 0.04, (0, h - 0.02, 0), c), C(0.025, h - 0.04, (0, (h - 0.04) / 2, 0), a), C(w * 0.42, 0.02, (0, 0.01, 0), a), C(w * 0.3, 0.015, (0, h * 0.35, 0), a)],
       pick(WAYS, 5), ONE, ["Spins. Kids know.", "One of a pair; the other broke."], acc=STEEL)
family("kitchen_clock", "Kitchen clock", "kitchen", "hang", (0.3, 0.05, 0.3),
       lambda w, d, h, c, a: [C(w * 0.5, d, (0, h / 2, 0), c, (1.57, 0, 0)), C(w * 0.44, 0.01, (0, h / 2, d * 0.55), WHITE, (1.57, 0, 0)), B((0.01, h * 0.3, 0.006), (0, h * 0.62, d * 0.6), a), B((h * 0.22, 0.01, 0.006), (h * 0.1, h / 2, d * 0.6), a)],
       pick(WAYS, 6), ONE, ["Five minutes fast, on purpose.", "Ticks loudest at night."], fragile=True)
family("kitchen_shelf", "Kitchen shelf", "kitchen", "hang", (0.8, 0.22, 0.3),
       lambda w, d, h, c, a: [B((w, 0.03, d), (0, 0.015, 0), c), B((0.03, h, 0.03), (-w * 0.45, h / 2, -d * 0.4), a), B((0.03, h, 0.03), (w * 0.45, h / 2, -d * 0.4), a), C(0.04, 0.12, (-w * 0.25, 0.09, 0), GLASS), C(0.04, 0.12, (0, 0.09, 0), WAYS["sage"]), B((0.1, 0.14, 0.08), (w * 0.3, 0.1, 0), KRAFT)],
       pick(WOODS, 4), SIZES2, ["Jars, a plant, and a photo that is always askew.", "The bracket was a Saturday job."])
family("towel_rail", "Tea towel rail", "kitchen", "hang", (0.4, 0.08, 0.26),
       lambda w, d, h, c, a: [C(0.012, w, (0, h * 0.9, 0), a, (0, 0, 1.57)), B((w * 0.35, h * 0.85, 0.02), (-w * 0.2, h * 0.47, 0), c), B((w * 0.35, h * 0.7, 0.02), (w * 0.2, h * 0.55, 0), WAYS["mustard"])],
       pick(WAYS, 5), ONE, ["Two tea towels, one for show.", "Souvenir of somewhere wet."], acc=STEEL)
family("tray", "Serving tray", "kitchen", "small", (0.4, 0.28, 0.05),
       lambda w, d, h, c, a: [B((w, 0.012, d), (0, 0.006, 0), c), B((w, h, 0.012), (0, h / 2, d / 2), c), B((w, h, 0.012), (0, h / 2, -d / 2), c), B((0.012, h, d), (w / 2, h / 2, 0), c), B((0.012, h, d), (-w / 2, h / 2, 0), c)],
       pick(WOODS, 4), SIZES2, ["Breakfast in bed, once a year.", "Painted by a child. Kept forever."])
family("salt_pepper", "Salt and pepper", "kitchen", "small", (0.1, 0.05, 0.1),
       lambda w, d, h, c, a: [C(0.02, h * 0.9, (-0.025, h * 0.45, 0), c), C(0.02, h * 0.9, (0.025, h * 0.45, 0), a), C(0.021, 0.015, (-0.025, h * 0.95, 0), STEEL), C(0.021, 0.015, (0.025, h * 0.95, 0), STEEL)],
       {"wood": OAK, "cream": CREAM, "steel": STEEL}, ONE, ["Always the pepper that runs out.", "A matching pair, by accident."], fragile=True)
family("cutlery_tray", "Cutlery tray", "kitchen", "small", (0.34, 0.26, 0.05),
       lambda w, d, h, c, a: [B((w, h, d), (0, h / 2, 0), c)] + [B((0.012, 0.01, d * 0.8), (x, h + 0.005, 0), STEEL) for x in (-0.1, -0.03, 0.04, 0.11)],
       pick(WOODS, 3), ONE, ["Knives, forks, and the spoon that is too big.", "Rattles like a drawer should."])
family("storage_jar", "Storage jar", "kitchen", "small", (0.14, 0.14, 0.24),
       lambda w, d, h, c, a: [C(w * 0.5, h * 0.85, (0, h * 0.43, 0), GLASS), C(w * 0.5, h * 0.15, (0, h * 0.93, 0), c), B((w * 0.6, h * 0.3, 0.004), (0, h * 0.45, w * 0.5), CREAM)],
       pick(WAYS, 5), [("", 1.0, {}), ("flour", 1.3, {}), ("sugar", 1.0, {}), ("pasta", 1.5, {})], ["Labelled, and the label lies.", "Half full of something brown."], fragile=True)
family("bin_kitchen", "Kitchen bin", "kitchen", "floor", (0.32, 0.32, 0.62),
       lambda w, d, h, c, a: [C(w * 0.5, h * 0.9, (0, h * 0.45, 0), c), C(w * 0.5, h * 0.1, (0, h * 0.95, 0), a), B((0.1, 0.02, 0.06), (0, h * 0.2, w * 0.5), a)],
       {"steel": STEEL, "cream": CREAM, "sage": SAGE, "black": BLACK}, [("", 1.0, {}), ("pedal", 1.0, {}), ("recycling", 1.1, {})], ["The lid sticks. Everyone's does.", "Empty, washed, still faintly fish."])
family("kitchen_trolley", "Kitchen trolley", "kitchen", "floor", (0.7, 0.45, 0.85),
       lambda w, d, h, c, a: [B((w, 0.03, d), (0, h - 0.015, 0), c), B((w, 0.025, d), (0, h * 0.5, 0), c), B((w, 0.025, d), (0, 0.12, 0), c)] + legs(w, d, h, a, 0.03) + [C(0.04, 0.03, (sx * (w / 2 - 0.06), 0.03, sz * (d / 2 - 0.06)), BLACK, (1.57, 0, 0)) for sx in (-1, 1) for sz in (-1, 1)],
       pick(WOODS, 4), ONE, ["Wheels. One squeaks, one sticks.", "Three shelves of things that have no home."], big=True, bulky=True)
family("high_chair", "High chair", "kitchen", "floor", (0.5, 0.55, 0.95),
       lambda w, d, h, c, a: [B((w * 0.7, 0.03, d * 0.6), (0, h * 0.55, 0), c), B((w * 0.7, h * 0.35, 0.03), (0, h * 0.72, -d * 0.28), c), B((w * 0.8, 0.03, d * 0.4), (0, h * 0.68, d * 0.25), a)] + [B((0.03, h * 0.55, 0.03), (sx * (w / 2 - 0.03), h * 0.27, sz * (d / 2 - 0.03)), c, (sz * 0.12, 0, -sx * 0.1)) for sx in (-1, 1) for sz in (-1, 1)],
       pick(WOODS, 4), ONE, ["Mashed banana in the hinges.", "Outgrown. Kept for the next one."], big=True)
family("radio_kitchen", "Kitchen radio", "kitchen", "small", (0.24, 0.1, 0.14),
       lambda w, d, h, c, a: [B((w, h, d), (0, h / 2, 0), c), C(h * 0.3, 0.01, (-w * 0.25, h * 0.5, d * 0.5), a, (1.57, 0, 0)), B((w * 0.3, h * 0.5, 0.01), (w * 0.22, h * 0.5, d * 0.5), WHITE), C(0.004, h * 1.2, (w * 0.4, h * 1.1, 0), STEEL, (0, 0, 0.5))],
       pick(WAYS, 6), ONE, ["Tuned to the one station, since 1998.", "Crackles when the kettle is on."])
family("soap_dispenser", "Soap and brush", "kitchen", "small", (0.14, 0.08, 0.16),
       lambda w, d, h, c, a: [C(0.03, h * 0.8, (-0.035, h * 0.4, 0), c), C(0.012, h * 0.3, (-0.035, h * 0.95, 0), a), B((0.03, h * 0.9, 0.02), (0.04, h * 0.45, 0), OAK), B((0.05, h * 0.15, 0.03), (0.04, h * 0.1, 0), WHITE)],
       pick(WAYS, 4), ONE, ["Refilled from the big bottle under the sink.", "The brush has seen things."])

# ---- bathroom
family("toothbrush_set", "Toothbrush cup", "bathroom", "small", (0.08, 0.08, 0.2),
       lambda w, d, h, c, a: [C(0.035, h * 0.5, (0, h * 0.25, 0), c), B((0.012, h * 0.8, 0.012), (-0.015, h * 0.55, 0), WAYS["blue"]), B((0.012, h * 0.8, 0.012), (0.015, h * 0.6, 0.01), WAYS["rose"]), B((0.03, h * 0.6, 0.02), (0, h * 0.5, -0.02), WHITE)],
       pick(WAYS, 5), ONE, ["Two brushes, one tube, squeezed from the middle.", "Nobody's is the blue one."], fragile=True)
family("soap_dish", "Soap dish", "bathroom", "small", (0.12, 0.09, 0.05),
       lambda w, d, h, c, a: [B((w, 0.02, d), (0, 0.01, 0), c), B((w * 0.6, h * 0.5, d * 0.6), (0, h * 0.45, 0), CREAM)],
       pick(WAYS, 5), ONE, ["A sliver of soap welded to it.", "The soap is older than the dish."], fragile=True)
family("towel_pile", "Towel pile", "bathroom", "small", (0.4, 0.3, 0.24),
       lambda w, d, h, c, a: [B((w, h * 0.33, d), (0, h * 0.17, 0), c), B((w * 0.95, h * 0.33, d * 0.95), (0.01, h * 0.5, 0), WHITE), B((w * 0.92, h * 0.33, d), (-0.01, h * 0.83, 0), a)],
       pick(WAYS, 6), SIZES2, ["Warm from the airing cupboard, once.", "The good towels, for guests who never come."])
family("loo_roll", "Loo roll stack", "bathroom", "small", (0.12, 0.12, 0.33),
       lambda w, d, h, c, a: [C(0.055, 0.1, (0, 0.05 + i * 0.11, 0), WHITE if i % 2 == 0 else CREAM) for i in range(3)] + [C(0.02, 0.1, (0, 0.05 + i * 0.11, 0), KRAFT) for i in range(3)],
       {"white": WHITE}, [("", 1.0, {}), ("tower", 1.5, {})], ["Three rolls. Peace of mind.", "Stocked for a siege."])
family("bath_mat", "Bath mat", "bathroom", "floor", (0.6, 0.4, 0.03),
       lambda w, d, h, c, a: [B((w, h, d), (0, h / 2, 0), c), B((w * 0.8, 0.005, d * 0.8), (0, h + 0.002, 0), a)],
       pick(WAYS, 7), SIZES2, ["Damp. It is always damp.", "Says WELCOME. Lies."])
family("laundry_hamper", "Laundry hamper", "bathroom", "floor", (0.42, 0.42, 0.6),
       lambda w, d, h, c, a: [C(w * 0.5, h * 0.9, (0, h * 0.45, 0), c), C(w * 0.52, h * 0.1, (0, h * 0.95, 0), a), B((w * 0.6, 0.06, w * 0.6), (0, h * 0.9, 0), WHITE)],
       {"wicker": KRAFT, "sage": SAGE, "cream": CREAM, "grey": GREY}, ONE, ["Full. It is full when you leave and full when you arrive.", "The lid lives on the floor."])
family("bath_scales", "Bathroom scales", "bathroom", "small", (0.3, 0.3, 0.04),
       lambda w, d, h, c, a: [B((w, h, d), (0, h / 2, 0), c), C(0.05, 0.01, (0, h, d * 0.3), WHITE), B((0.004, 0.005, 0.03), (0, h + 0.005, d * 0.3), RED)],
       {"white": WHITE, "black": BLACK, "sage": SAGE, "glass": GLASS}, ONE, ["Lies by a kilo. The kind one.", "Kicked under the sink after Christmas."])
family("mirror_round", "Round mirror", "bathroom", "hang", (0.5, 0.04, 0.5),
       lambda w, d, h, c, a: [C(w * 0.5, d, (0, h / 2, 0), c, (1.57, 0, 0)), C(w * 0.45, 0.01, (0, h / 2, d * 0.6), GLASS, (1.57, 0, 0))],
       pick(WOODS, 3) | pick(METALS, 2), SIZES3, ["Steams up before you need it.", "Kind in the morning light. Honest at noon."], fragile=True)
family("bath_shelf", "Bathroom shelf", "bathroom", "hang", (0.6, 0.14, 0.24),
       lambda w, d, h, c, a: [B((w, 0.02, d), (0, 0.01, 0), c), C(0.025, 0.12, (-w * 0.3, 0.08, 0), GLASS), C(0.03, 0.1, (0, 0.07, 0), WAYS["rose"]), B((0.08, 0.1, 0.06), (w * 0.3, 0.07, 0), WHITE)],
       {"glass": GLASS, "oak": OAK, "white": WHITE}, SIZES2, ["Bottles that are nearly empty, forever.", "A plant that likes the steam."], fragile=True)
family("toiletries", "Toiletries basket", "bathroom", "small", (0.26, 0.18, 0.2),
       lambda w, d, h, c, a: [B((w, h * 0.5, d), (0, h * 0.25, 0), c), C(0.03, h * 0.9, (-0.07, h * 0.45, 0), WAYS["blue"]), C(0.025, h * 0.8, (0, h * 0.4, 0.02), WAYS["mustard"]), B((0.05, h * 0.7, 0.03), (0.07, h * 0.35, 0), WHITE)],
       {"wicker": KRAFT, "wire": STEEL, "sage": SAGE}, ONE, ["Half-used bottles of good intentions.", "Hotel shampoos, a hundred of them."])
family("rubber_duck", "Rubber duck", "bathroom", "small", (0.1, 0.08, 0.1),
       lambda w, d, h, c, a: [S(0.04, (0, 0.04, 0), c), S(0.03, (0, 0.08, -0.025), c), B((0.025, 0.012, 0.02), (0, 0.075, -0.055), WAYS["terracotta"])],
       {"yellow": MUSTARD, "sage": SAGE, "rose": ROSE, "blue": BLUE, "black": BLACK}, [("", 1.0, {}), ("family of", 1.0, {}), ("giant", 1.8, {})], ["Squeaks. Nobody knows how it still squeaks.", "The captain of the bath."])
family("bath_plant", "Fern in a pot", "bathroom", "small", (0.26, 0.26, 0.34),
       lambda w, d, h, c, a: [C(w * 0.32, h * 0.35, (0, h * 0.17, 0), c)] + [B((0.03, h * 0.5, 0.012), (x * 0.07, h * 0.6, z * 0.07), GREEN, (z * 0.5, 0, -x * 0.5)) for x in (-1, 0, 1) for z in (-1, 1)],
       pick(WAYS, 5), SIZES2, ["Thrives on steam and neglect.", "The only plant that has survived them."])
family("bath_bin", "Bathroom bin", "bathroom", "floor", (0.2, 0.2, 0.28),
       lambda w, d, h, c, a: [C(w * 0.5, h, (0, h / 2, 0), c), C(w * 0.48, 0.015, (0, h, 0), a)],
       {"steel": STEEL, "cream": CREAM, "sage": SAGE, "rose": ROSE}, ONE, ["Cotton buds and regret.", "Small, and always full."])
family("towel_rail_bath", "Towel rail", "bathroom", "hang", (0.6, 0.1, 0.12),
       lambda w, d, h, c, a: [C(0.012, w, (0, h * 0.5, 0), c, (0, 0, 1.57)), B((0.03, 0.03, 0.08), (-w * 0.45, h * 0.5, -0.04), c), B((0.03, 0.03, 0.08), (w * 0.45, h * 0.5, -0.04), c), B((w * 0.5, h * 0.9, 0.02), (0, h * 0.05, 0.02), WAYS["sage"])],
       METALS, [("", 1.0, {}), ("double", 1.0, {})], ["Heated, which is to say warm-ish.", "Holds the one towel that gets used."], acc=STEEL)
family("medicine_cabinet", "Medicine cabinet", "bathroom", "hang", (0.4, 0.14, 0.5),
       lambda w, d, h, c, a: [B((w, h, d), (0, h / 2, 0), c), B((w * 0.9, h * 0.9, 0.01), (0, h / 2, d * 0.5), GLASS), B((0.02, 0.08, 0.02), (w * 0.38, h / 2, d * 0.55), a)],
       {"white": WHITE, "steel": STEEL, "oak": OAK}, ONE, ["Plasters, paracetamol, a thermometer from 1985.", "The mirror door swings open on its own."], fragile=True)
family("bath_caddy", "Bath caddy", "bathroom", "small", (0.7, 0.16, 0.1),
       lambda w, d, h, c, a: [B((w, 0.015, d), (0, 0.04, 0), c), B((w, 0.05, 0.01), (0, 0.065, d / 2), c), C(0.03, 0.09, (w * 0.3, 0.09, 0), GLASS), B((0.12, 0.02, 0.09), (-w * 0.25, 0.055, 0), WAYS["mustard"])],
       pick(WOODS, 3), ONE, ["A book, a glass, and the dream of a long bath.", "Bamboo. Everything is bamboo now."])
family("candles", "Candle set", "bathroom", "small", (0.2, 0.1, 0.12),
       lambda w, d, h, c, a: [C(0.03, h * 0.9, (-0.06, h * 0.45, 0), c), C(0.03, h * 0.6, (0, h * 0.3, 0), c), C(0.03, h * 0.75, (0.06, h * 0.37, 0), c), S(0.006, (-0.06, h * 0.92, 0), BLACK)],
       pick(WAYS, 6), ONE, ["Vanilla. Everything smells of vanilla.", "Never lit. Too nice to light."], fragile=True)
family("hair_dryer", "Hair dryer", "bathroom", "small", (0.22, 0.08, 0.2),
       lambda w, d, h, c, a: [C(0.035, w * 0.8, (0, h * 0.75, 0), c, (0, 0, 1.57)), B((0.04, h * 0.7, 0.03), (-0.03, h * 0.35, 0), c), C(0.04, 0.02, (w * 0.42, h * 0.75, 0), a, (0, 0, 1.57))],
       pick(WAYS, 5), ONE, ["Two settings: hot and hotter.", "The cord is a knot. The knot is permanent."])

# ---- bedroom
family("bedside_lamp", "Bedside lamp", "bedroom", "small", (0.24, 0.24, 0.42),
       lambda w, d, h, c, a: [C(w * 0.3, 0.03, (0, 0.015, 0), a), C(0.015, h * 0.5, (0, h * 0.28, 0), a), C(w * 0.5, h * 0.4, (0, h * 0.78, 0), c)],
       pick(WAYS, 7), SIZES2, ["Reads until one in the morning.", "The switch is on the cord, behind the bed."], fragile=True)
family("book_stack", "Book stack", "bedroom", "small", (0.2, 0.15, 0.2),
       lambda w, d, h, c, a: [B((w, h * 0.25, d), (0, h * 0.12, 0), c), B((w * 0.9, h * 0.25, d), (0.01, h * 0.37, 0), WAYS["night"]), B((w * 0.95, h * 0.25, d * 0.9), (-0.01, h * 0.62, 0), a), B((w * 0.85, h * 0.25, d), (0.0, h * 0.87, 0), CREAM)],
       pick(WAYS, 6), [("", 1.0, {}), ("to-read", 1.3, {}), ("paperbacks", 0.8, {})], ["Bookmarked a third of the way in. All of them.", "The one on top is for show."])
family("jewellery_box", "Jewellery box", "bedroom", "small", (0.2, 0.14, 0.1),
       lambda w, d, h, c, a: [B((w, h * 0.7, d), (0, h * 0.35, 0), c), B((w, h * 0.3, d), (0, h * 0.85, -d * 0.02), c), B((0.03, 0.01, 0.01), (0, h * 0.7, d * 0.5), BRASS)],
       pick(WOODS, 4) | {"velvet rose": ROSE}, ONE, ["A ring that was Gran's, and some that were not.", "Plays a tune when it opens. Nearly."], fragile=True)
family("picture_frame", "Framed picture", "bedroom", "hang", (0.4, 0.03, 0.5),
       lambda w, d, h, c, a: [B((w, h, d), (0, h / 2, 0), c), B((w * 0.86, h * 0.86, 0.01), (0, h / 2, d * 0.55), a)],
       pick(WOODS, 4) | {"brass": BRASS, "white": WHITE}, [("", 1.0, {}), ("small", 0.6, {}), ("landscape", 1.0, {"swap": True}), ("large", 1.5, {})], ["A beach. Nobody can agree which one.", "The wedding. Everyone looks younger."], fragile=True, acc=TEAL)
family("slippers", "Slippers", "bedroom", "small", (0.26, 0.12, 0.08),
       lambda w, d, h, c, a: [B((w * 0.42, h * 0.5, d * 0.45), (-w * 0.26, h * 0.25, 0), c), B((w * 0.42, h * 0.5, d * 0.45), (w * 0.26, h * 0.25, 0), c), B((w * 0.3, h * 0.5, d * 0.45), (-w * 0.3, h * 0.6, -d * 0.1), a), B((w * 0.3, h * 0.5, d * 0.45), (w * 0.3, h * 0.6, -d * 0.1), a)],
       pick(WAYS, 6), ONE, ["Worn flat on the inside edge.", "One is always under the bed."])
family("dressing_stool", "Dressing stool", "bedroom", "floor", (0.44, 0.34, 0.46),
       lambda w, d, h, c, a: [B((w, 0.08, d), (0, h - 0.04, 0), c)] + legs(w, d, h - 0.08, a, 0.035),
       pick(WAYS, 6), ONE, ["Padded. Not enough.", "Where the clothes live between wears."], acc=WALNUT)
family("mirror_oval", "Oval mirror", "bedroom", "hang", (0.4, 0.04, 0.6),
       lambda w, d, h, c, a: [C(w * 0.5, d, (0, h / 2, 0), c, (1.57, 0, 0)), C(w * 0.44, 0.01, (0, h / 2, d * 0.6), GLASS, (1.57, 0, 0))],
       pick(WOODS, 3) | pick(METALS, 2), SIZES2, ["Tilts. Never stays tilted.", "Flattering, in the right light."], fragile=True)
family("blanket", "Folded blanket", "bedroom", "small", (0.44, 0.34, 0.14),
       lambda w, d, h, c, a: [B((w, h * 0.5, d), (0, h * 0.25, 0), c), B((w * 0.96, h * 0.5, d * 0.96), (0, h * 0.75, 0), c), B((w, 0.01, 0.03), (0, h * 0.5, d * 0.5), a)],
       pick(WAYS, 7), SIZES2, ["Knitted by someone, for someone.", "The itchy one. Warmest by a mile."])
family("teddy", "Teddy bear", "bedroom", "small", (0.2, 0.16, 0.3),
       lambda w, d, h, c, a: [S(0.08, (0, 0.1, 0), c), S(0.065, (0, 0.22, 0), c), S(0.025, (-0.05, 0.27, 0), c), S(0.025, (0.05, 0.27, 0), c), S(0.03, (-0.08, 0.1, 0.02), c), S(0.03, (0.08, 0.1, 0.02), c), S(0.012, (0, 0.21, 0.06), a)],
       {"honey": "C9A070", "brown": WALNUT, "cream": CREAM, "grey": GREY, "pink": ROSE}, [("", 1.0, {}), ("small", 0.7, {}), ("huge", 1.8, {})], ["One eye. Loved harder for it.", "Sits on the bed. Judges."])
family("coat_stand", "Coat stand", "bedroom", "floor", (0.4, 0.4, 1.7),
       lambda w, d, h, c, a: [C(0.02, h, (0, h / 2, 0), c), C(w * 0.5, 0.03, (0, 0.015, 0), c)] + [B((0.12, 0.02, 0.02), (sx * 0.07, h * 0.95 - i * 0.12, sz * 0.07), c, (0, (sx * 0.8 + sz * 0.3), 0.3 * sx)) for i, (sx, sz) in enumerate(((1, 0), (0, 1), (-1, 0), (0, -1)))] + [B((0.2, 0.5, 0.1), (0.08, h * 0.65, 0), WAYS["night"])],
       pick(WOODS, 4) | {"brass": BRASS}, ONE, ["Leans. Has always leaned.", "Five coats, one owner."], big=True)
family("hat_box", "Hat box", "bedroom", "small", (0.34, 0.34, 0.2),
       lambda w, d, h, c, a: [C(w * 0.5, h * 0.8, (0, h * 0.4, 0), c), C(w * 0.52, h * 0.2, (0, h * 0.9, 0), a), B((0.02, h * 0.9, 0.02), (0, h * 0.5, w * 0.5), KRAFT)],
       pick(WAYS, 6), SIZES2, ["A hat. Worn once, to a wedding.", "Round boxes do not stack. This one tries."])
family("suitcase", "Suitcase", "bedroom", "floor", (0.5, 0.2, 0.7),
       lambda w, d, h, c, a: [B((w, h * 0.92, d), (0, h * 0.46, 0), c), B((w * 0.3, 0.03, 0.025), (0, h * 0.95, 0), a), B((w * 0.9, 0.012, d * 1.02), (0, h * 0.5, 0), a)] + [C(0.03, 0.02, (sx * w * 0.4, 0.03, d * 0.4), BLACK, (1.57, 0, 0)) for sx in (-1, 1)],
       pick(WAYS, 6) | {"tan": KRAFT}, [("", 1.0, {}), ("cabin", 0.75, {}), ("trunk", 1.3, {})], ["Half packed since the last trip.", "A sticker from an airport that closed."])
family("hangers", "Bundle of hangers", "bedroom", "small", (0.42, 0.06, 0.24),
       lambda w, d, h, c, a: [B((w, 0.012, 0.012), (0, 0.08, i * 0.012), c, (0, 0, 0.22 * (i - 1))) for i in range(3)] + [B((w * 0.8, 0.012, 0.012), (0, 0.16 + i * 0.03, i * 0.01), c, (0, 0, -0.2)) for i in range(2)] + [C(0.006, 0.06, (0, 0.22, 0), STEEL)],
       pick(WOODS, 3) | {"wire": STEEL, "velvet": NIGHT}, ONE, ["Tangled. They tangle themselves.", "Fourteen hangers, nine shirts."])
family("cot", "Cot", "bedroom", "floor", (1.2, 0.65, 0.9),
       lambda w, d, h, c, a: [B((w, 0.04, d), (0, 0.35, 0), c)] + [B((0.025, h * 0.95, 0.025), (sx * (w / 2 - 0.015), h * 0.47, sz * (d / 2 - 0.015)), c) for sx in (-1, 1) for sz in (-1, 1)] + [B((0.015, h * 0.6, 0.015), (x, h * 0.65, sz * (d / 2 - 0.015)), c) for x in [-0.45 + i * 0.1 for i in range(10)] for sz in (-1, 1)] + [B((w * 0.9, 0.08, d * 0.85), (0, 0.41, 0), WHITE)],
       pick(WOODS, 4), ONE, ["Teeth marks on the top rail.", "Flat-packed twice. Never quite right since."], big=True, heavy=True, bulky=True)
family("toy_box", "Toy box", "bedroom", "floor", (0.7, 0.4, 0.42),
       lambda w, d, h, c, a: [B((w, h * 0.8, d), (0, h * 0.4, 0), c), B((w * 1.02, h * 0.2, d * 1.02), (0, h * 0.9, 0), a), B((0.12, 0.08, 0.1), (-0.15, h * 1.05, 0), WAYS["red"]), S(0.05, (0.15, h * 1.05, 0), WAYS["blue"])],
       pick(WAYS, 6), SIZES2, ["Lego. Always Lego, at the bottom.", "Painted with the child's name. Misspelt."], bulky=True)
family("dollhouse", "Doll's house", "bedroom", "small", (0.6, 0.35, 0.6),
       lambda w, d, h, c, a: [B((w, h * 0.65, d), (0, h * 0.32, 0), c), B((w * 0.7, h * 0.35, d * 0.9), (0, h * 0.82, 0), a, (0, 0, 0.785)), B((0.1, 0.15, 0.01), (0, h * 0.35, d * 0.5), WOODS["walnut"]), B((0.08, 0.08, 0.01), (-0.18, h * 0.45, d * 0.5), GLASS), B((0.08, 0.08, 0.01), (0.18, h * 0.45, d * 0.5), GLASS)],
       pick(WAYS, 5), ONE, ["Three floors. Better furnished than this one.", "The front swings open. Sometimes by itself."], fragile=True)
family("rocking_chair", "Rocking chair", "bedroom", "floor", (0.6, 0.8, 1.0),
       lambda w, d, h, c, a: [B((w, 0.04, d * 0.6), (0, 0.42, 0), c), B((w, h * 0.55, 0.04), (0, h * 0.7, -d * 0.28), c, (0.15, 0, 0))] + [B((0.04, 0.4, 0.04), (sx * (w / 2 - 0.02), 0.2, sz * d * 0.28), c) for sx in (-1, 1) for sz in (-1, 1)] + [B((0.04, 0.03, d), (sx * (w / 2 - 0.02), 0.015, 0), a) for sx in (-1, 1)] + [B((0.04, 0.04, 0.5), (sx * (w / 2 - 0.02), 0.62, -0.05), c) for sx in (-1, 1)],
       pick(WOODS, 5), ONE, ["Creaks on the back stroke.", "Grandad's. Then Dad's. Then nobody's."], big=True)
family("ottoman", "Ottoman", "bedroom", "floor", (0.9, 0.45, 0.45),
       lambda w, d, h, c, a: [B((w, h * 0.85, d), (0, h * 0.42, 0), c), B((w * 1.02, h * 0.15, d * 1.02), (0, h * 0.92, 0), a)] + legs(w, d, 0.06, WALNUT, 0.04),
       pick(WAYS, 6), SIZES2, ["Blankets inside. Lid lifts with a sigh.", "The dog thinks it is his."], big=True, bulky=True)
family("clothes_rail", "Clothes rail", "bedroom", "floor", (1.0, 0.45, 1.5),
       lambda w, d, h, c, a: [C(0.012, w, (0, h, 0), c, (0, 0, 1.57)), C(0.012, h, (-w / 2, h / 2, 0), c), C(0.012, h, (w / 2, h / 2, 0), c), B((0.04, 0.02, d), (-w / 2, 0.01, 0), c), B((0.04, 0.02, d), (w / 2, 0.01, 0), c)] + [B((0.12, 0.55, 0.03), (-0.3 + i * 0.15, h - 0.32, 0), [WAYS["sage"], WAYS["terracotta"], NIGHT, CREAM, WAYS["blue"]][i]) for i in range(5)],
       METALS, ONE, ["The wardrobe overflow. Wheels, so it roams.", "Folds flat, in theory."], big=True, bulky=True, acc=STEEL)
family("shoe_rack", "Shoe rack", "bedroom", "floor", (0.7, 0.3, 0.36),
       lambda w, d, h, c, a: [B((w, 0.02, d), (0, 0.17, 0), c), B((w, 0.02, d), (0, 0.34, 0), c)] + legs(w, d, 0.35, c, 0.025, 0.02) + [B((0.09, 0.07, 0.22), (-w * 0.3 + i * 0.12, 0.215, 0), [BLACK, WAYS["red"], KRAFT, WHITE, NIGHT][i]) for i in range(5)],
       pick(WOODS, 4), SIZES2, ["Eleven shoes. Count again.", "Trainers on top, the good ones underneath."])
family("cushion_set", "Cushion set", "bedroom", "small", (0.4, 0.2, 0.3),
       lambda w, d, h, c, a: [B((w, h * 0.3, d * 0.5), (0, h * 0.15, 0), c), B((w * 0.9, h * 0.3, d * 0.5), (0.02, h * 0.45, 0.01), a), B((w * 0.8, h * 0.3, d * 0.5), (-0.02, h * 0.75, 0), WAYS["mustard"])],
       pick(WAYS, 7), ONE, ["Four, arranged nightly, flung nightly.", "The scatter in scatter cushion is literal."])
family("poster", "Poster", "bedroom", "hang", (0.5, 0.02, 0.7),
       lambda w, d, h, c, a: [B((w, h, d), (0, h / 2, 0), c), B((w * 0.6, h * 0.1, 0.005), (0, h * 0.8, d * 0.6), a), B((w * 0.4, h * 0.3, 0.005), (0, h * 0.4, d * 0.6), WHITE)],
       pick(WAYS, 6), [("", 1.0, {}), ("band", 1.0, {}), ("film", 1.2, {})], ["A band that split in 2004.", "Blu-tack marks in every corner."])
family("string_lights", "String lights", "bedroom", "hang", (0.9, 0.06, 0.2),
       lambda w, d, h, c, a: [C(0.004, w, (0, h * 0.9, 0), a, (0, 0, 1.57))] + [S(0.018, (-w * 0.4 + i * w * 0.1, h * 0.75 - (0.03 if i % 2 else 0.0), 0), [MUSTARD, ROSE, SAGE, BLUE][i % 4]) for i in range(9)],
       {"warm": MUSTARD, "mixed": ROSE}, ONE, ["Up since Christmas. Which Christmas, unclear.", "One bulb out. Always one."], fragile=True)
family("bedroom_chair", "Bedroom chair", "bedroom", "floor", (0.5, 0.5, 0.85),
       lambda w, d, h, c, a: [B((w, 0.04, d), (0, 0.44, 0), c), B((w, h * 0.45, 0.04), (0, h * 0.7, -d * 0.48), c)] + legs(w, d, 0.42, a, 0.035) + [B((w * 0.8, 0.3, 0.05), (0, 0.62, -d * 0.4), WAYS["night"])],
       pick(WOODS, 4), ONE, ["The chair for clothes that are not dirty yet.", "Nobody has sat on it this year."])
family("laundry_bag", "Laundry bag", "bedroom", "small", (0.4, 0.4, 0.5),
       lambda w, d, h, c, a: [C(w * 0.5, h * 0.9, (0, h * 0.45, 0), c), C(w * 0.3, h * 0.12, (0, h * 0.95, 0), a), B((0.08, 0.1, 0.03), (0.1, h * 0.8, w * 0.45), WHITE)],
       pick(WAYS, 5), ONE, ["Pop-up. Pops up in the truck.", "Full of the clothes that were in the hamper."])

# ---- living
family("armchair_v", "Armchair", "living", "floor", (0.85, 0.85, 0.9),
       lambda w, d, h, c, a: [B((w, h * 0.4, d), (0, h * 0.2, 0), c), B((w, h * 0.55, d * 0.3), (0, h * 0.5, -d * 0.35), c), B((0.16, h * 0.62, d), (-w / 2 + 0.08, h * 0.31, 0), c), B((0.16, h * 0.62, d), (w / 2 - 0.08, h * 0.31, 0), c), B((w - 0.36, 0.1, d * 0.62), (0, h * 0.45, -d * 0.1), a)] + legs(w, d, 0.05, WALNUT, 0.04, 0.05),
       pick(WAYS, 7), [("", 1.0, {}), ("wingback", 1.1, {}), ("club", 0.95, {})], ["Dad's chair. Nobody else sits in it. Nobody tries.", "The springs went in 2016. Comfiest chair in the house."], big=True, heavy=True, bulky=True, acc=CREAM)
family("side_table_v", "Side table", "living", "floor", (0.45, 0.45, 0.55),
       lambda w, d, h, c, a: [C(w * 0.5, 0.025, (0, h - 0.012, 0), c), C(0.025, h - 0.03, (0, (h - 0.03) / 2, 0), a), C(w * 0.35, 0.02, (0, 0.01, 0), a)],
       pick(WOODS, 5), SIZES2, ["Ring marks from every mug since 2003.", "Wobbles unless the coaster is under the leg."])
family("bookshelf_v", "Bookshelf", "living", "floor", (0.8, 0.3, 1.2),
       lambda w, d, h, c, a: [B((w, h, 0.02), (0, h / 2, -d / 2 + 0.01), c), B((0.02, h, d), (-w / 2 + 0.01, h / 2, 0), c), B((0.02, h, d), (w / 2 - 0.01, h / 2, 0), c)] + [B((w, 0.025, d), (0, y, 0), c) for y in (0.02, h * 0.35, h * 0.68, h - 0.012)] + [B((0.03, h * 0.25, d * 0.7), (-w * 0.35 + i * 0.07, h * 0.49, 0), [a, NIGHT, MUSTARD, SAGE, CREAM, TERRA][i % 6]) for i in range(9)] + [B((0.03, h * 0.27, d * 0.7), (-w * 0.35 + i * 0.07, h * 0.82, 0), [TERRA, a, CREAM, BLUE, NIGHT][i % 5]) for i in range(7)],
       pick(WOODS, 5), [("", 1.0, {}), ("tall", 1.4, {}), ("low", 0.7, {})], ["Alphabetical for a week.", "Double-stacked. The back row is forgotten."], big=True, heavy=True, bulky=True, acc=RED)
family("record_player", "Record player", "living", "small", (0.42, 0.34, 0.14),
       lambda w, d, h, c, a: [B((w, h * 0.6, d), (0, h * 0.3, 0), c), C(w * 0.3, 0.012, (-w * 0.1, h * 0.65, 0), BLACK), C(0.02, 0.01, (-w * 0.1, h * 0.72, 0), WAYS["mustard"]), B((0.015, 0.01, d * 0.4), (w * 0.3, h * 0.7, -d * 0.1), STEEL, (0, 0.4, 0))],
       pick(WOODS, 3) | pick(WAYS, 2), ONE, ["The needle is older than the music.", "Plays slightly slow. Everything sounds wiser."], fragile=True)
family("speaker", "Speaker", "living", "small", (0.22, 0.22, 0.4),
       lambda w, d, h, c, a: [B((w, h, d), (0, h / 2, 0), c), C(w * 0.3, 0.01, (0, h * 0.3, d * 0.5), a, (1.57, 0, 0)), C(w * 0.15, 0.01, (0, h * 0.75, d * 0.5), a, (1.57, 0, 0))],
       pick(WOODS, 3) | {"black": BLACK, "white": WHITE}, [("", 1.0, {}), ("pair of", 1.0, {}), ("bookshelf", 0.7, {}), ("floor-standing", 1.9, {})], ["Louder than the neighbours would like.", "One channel crackles. Call it warmth."])
family("plant_pot_v", "Potted plant", "living", "floor", (0.4, 0.4, 0.9),
       lambda w, d, h, c, a: [C(w * 0.4, h * 0.3, (0, h * 0.15, 0), c), C(0.012, h * 0.5, (0, h * 0.5, 0), WALNUT)] + [B((0.08, 0.22, 0.012), (x * 0.1, h * 0.75 + abs(x) * 0.05, z * 0.1), GREEN, (z * 0.6, 0.4, -x * 0.6)) for x in (-1, 0, 1) for z in (-1, 1)],
       pick(WAYS, 7), [("", 1.0, {}), ("monstera", 1.3, {}), ("small", 0.6, {}), ("rubber plant", 1.5, {})], ["Watered on Sundays, remembered on Tuesdays.", "Came as a cutting. Took over."])
family("vase", "Vase", "living", "small", (0.14, 0.14, 0.3),
       lambda w, d, h, c, a: [C(w * 0.35, h * 0.5, (0, h * 0.25, 0), c), C(w * 0.5, h * 0.25, (0, h * 0.6, 0), c), C(w * 0.28, h * 0.25, (0, h * 0.85, 0), c), C(0.006, h * 0.5, (0.02, h * 1.1, 0), GREEN, (0, 0, 0.2)), S(0.03, (0.06, h * 1.3, 0), WAYS["rose"])],
       pick(WAYS, 7) | {"glass": GLASS}, SIZES3, ["Flowers from the garden, when there are any.", "Survived three moves. Tempting fate."], fragile=True)
family("candle_holder", "Candlesticks", "living", "small", (0.2, 0.1, 0.26),
       lambda w, d, h, c, a: [C(0.035, 0.02, (-0.06, 0.01, 0), c), C(0.012, h * 0.7, (-0.06, h * 0.37, 0), c), C(0.012, h * 0.3, (-0.06, h * 0.85, 0), CREAM), C(0.035, 0.02, (0.06, 0.01, 0), c), C(0.012, h * 0.55, (0.06, h * 0.3, 0), c), C(0.012, h * 0.3, (0.06, h * 0.7, 0), CREAM)],
       METALS, ONE, ["Brass, polished once a decade.", "The candles have never been lit. Ornamental wax."], fragile=True)
family("picture_v", "Painting", "living", "hang", (0.6, 0.04, 0.45),
       lambda w, d, h, c, a: [B((w, h, d), (0, h / 2, 0), c), B((w * 0.88, h * 0.86, 0.01), (0, h / 2, d * 0.55), a), B((w * 0.4, h * 0.3, 0.012), (-w * 0.1, h * 0.4, d * 0.6), WAYS["sage"]), C(0.04, 0.012, (w * 0.2, h * 0.65, d * 0.6), WAYS["mustard"], (1.57, 0, 0))],
       pick(WOODS, 3) | {"gilt": BRASS, "white": WHITE, "black": BLACK}, [("", 1.0, {}), ("small", 0.6, {}), ("portrait", 1.0, {"swap": True}), ("huge", 1.6, {})], ["An uncle painted it. Nobody says which uncle.", "Hung over the sofa. Then the fireplace. Then the sofa."], fragile=True, acc=TEAL)
family("wall_clock", "Wall clock", "living", "hang", (0.36, 0.06, 0.36),
       lambda w, d, h, c, a: [C(w * 0.5, d, (0, h / 2, 0), c, (1.57, 0, 0)), C(w * 0.44, 0.01, (0, h / 2, d * 0.55), CREAM, (1.57, 0, 0)), B((0.012, h * 0.3, 0.006), (0, h * 0.63, d * 0.6), a), B((h * 0.25, 0.012, 0.006), (h * 0.11, h / 2, d * 0.6), a)],
       pick(WOODS, 3) | pick(METALS, 3), [("", 1.0, {}), ("station", 1.5, {}), ("small", 0.7, {})], ["Stopped at ten past four. Right twice a day.", "Loud. You stop hearing it after a year."], fragile=True)
family("wall_mirror", "Wall mirror", "living", "hang", (0.7, 0.04, 0.5),
       lambda w, d, h, c, a: [B((w, h, d), (0, h / 2, 0), c), B((w * 0.9, h * 0.88, 0.01), (0, h / 2, d * 0.55), GLASS)],
       pick(WOODS, 3) | {"gilt": BRASS, "black": BLACK}, [("", 1.0, {}), ("hall", 1.3, {}), ("tall", 1.0, {"swap": True})], ["Makes the room look bigger and the hallway look worse.", "Seven years' bad luck, in a crate."], fragile=True)
family("coffee_table_v", "Coffee table", "living", "floor", (1.0, 0.55, 0.42),
       lambda w, d, h, c, a: [B((w, 0.03, d), (0, h - 0.015, 0), c), B((w * 0.85, 0.02, d * 0.85), (0, h * 0.35, 0), a)] + legs(w, d, h - 0.03, c, 0.04) + [B((0.2, 0.025, 0.15), (-0.25, h + 0.012, 0), NIGHT), C(0.04, 0.08, (0.3, h + 0.04, 0.1), WHITE)],
       pick(WOODS, 5) | {"glass": GLASS}, [("", 1.0, {}), ("round", 0.8, {}), ("long", 1.4, {})], ["Feet go on it. Everybody knows.", "The remote lives under it."], big=True, bulky=True)
family("footstool", "Footstool", "living", "floor", (0.5, 0.4, 0.38),
       lambda w, d, h, c, a: [B((w, h * 0.5, d), (0, h * 0.75, 0), c)] + legs(w, d, h * 0.5, a, 0.035),
       pick(WAYS, 6), ONE, ["Matches a chair that was sold.", "Step, seat, table. Whatever is needed."], acc=WALNUT)
family("magazine_pile", "Magazine pile", "living", "small", (0.3, 0.24, 0.1),
       lambda w, d, h, c, a: [B((w, h * 0.25, d), (0, h * 0.12, 0), c), B((w, h * 0.25, d), (0.015, h * 0.37, 0.01), WHITE), B((w, h * 0.25, d), (-0.01, h * 0.62, 0), a), B((w, h * 0.25, d), (0.005, h * 0.87, -0.01), WAYS["mustard"])],
       pick(WAYS, 5), ONE, ["Unread since the subscription started.", "A crossword, half done, in pen."])
family("board_games", "Board games", "living", "small", (0.4, 0.28, 0.2),
       lambda w, d, h, c, a: [B((w, h * 0.3, d), (0, h * 0.15, 0), c), B((w * 0.95, h * 0.3, d * 0.9), (0.01, h * 0.45, 0), a), B((w * 0.8, h * 0.3, d), (-0.01, h * 0.75, 0), WAYS["mustard"]), B((w * 0.6, h * 0.12, d * 0.6), (0, h * 0.96, 0), WHITE)],
       pick(WAYS, 5), SIZES2, ["Monopoly, with the money from another set.", "A thousand-piece jigsaw, nine hundred and ninety-nine."])
family("tv_small", "Small television", "living", "small", (0.7, 0.18, 0.45),
       lambda w, d, h, c, a: [B((w, h * 0.85, 0.04), (0, h * 0.55, 0), BLACK), B((w * 0.95, h * 0.78, 0.01), (0, h * 0.55, 0.025), c), B((w * 0.3, 0.03, d), (0, 0.015, 0), BLACK), B((0.03, h * 0.15, 0.03), (0, h * 0.1, 0), BLACK)],
       {"off": NIGHT, "on": TEAL, "static": GREY}, [("", 1.0, {}), ("bedroom", 0.75, {}), ("big", 1.5, {})], ["Screen out, pad it twice.", "Only the kitchen one gets the news."], fragile=True)
family("console", "Games console", "living", "small", (0.3, 0.24, 0.08),
       lambda w, d, h, c, a: [B((w, h, d), (0, h / 2, 0), c), B((w * 0.3, 0.01, d * 0.5), (0, h + 0.005, 0), a), B((0.12, 0.03, 0.08), (w * 0.4, 0.015, d * 0.7), BLACK)],
       {"black": BLACK, "white": WHITE, "grey": GREY}, ONE, ["Two controllers, one with a sticky button.", "Saves on it going back eight years."], fragile=True)
family("floor_lamp_v", "Floor lamp", "living", "floor", (0.4, 0.4, 1.6),
       lambda w, d, h, c, a: [C(w * 0.4, 0.03, (0, 0.015, 0), a), C(0.015, h * 0.8, (0, h * 0.42, 0), a), C(w * 0.5, h * 0.2, (0, h * 0.9, 0), c)],
       pick(WAYS, 7), [("", 1.0, {}), ("arc", 1.1, {}), ("reading", 0.85, {})], ["Lights the corner nobody sits in.", "The shade is on upside down. Nobody will say."], big=True, fragile=True)
family("table_lamp", "Table lamp", "living", "small", (0.3, 0.3, 0.5),
       lambda w, d, h, c, a: [C(w * 0.3, h * 0.45, (0, h * 0.22, 0), a), C(w * 0.5, h * 0.35, (0, h * 0.8, 0), c)],
       pick(WAYS, 7), SIZES2, ["A warm one. The room is a different room with it on.", "The base is a ceramic cat. It is a long story."], fragile=True)
family("tall_bookcase", "Tall bookcase", "living", "floor", (0.9, 0.32, 1.9),
       lambda w, d, h, c, a: [B((w, h, 0.02), (0, h / 2, -d / 2 + 0.01), c), B((0.02, h, d), (-w / 2 + 0.01, h / 2, 0), c), B((0.02, h, d), (w / 2 - 0.01, h / 2, 0), c)] + [B((w, 0.025, d), (0, y, 0), c) for y in (0.02, 0.4, 0.78, 1.16, 1.54, h - 0.012)] + [B((0.03, 0.28, d * 0.7), (-w * 0.4 + i * 0.065, y + 0.17, 0), [a, NIGHT, MUSTARD, SAGE, CREAM, TERRA, BLUE][(i + int(y * 10)) % 7]) for y in (0.02, 0.4, 0.78, 1.16) for i in range(10)],
       pick(WOODS, 5), ONE, ["Floor to ceiling, and still not enough.", "Screwed to the wall after the incident."], big=True, heavy=True, bulky=True, acc=RED)
family("glass_cabinet", "Glass cabinet", "living", "floor", (0.8, 0.4, 1.4),
       lambda w, d, h, c, a: [B((w, h, d), (0, h / 2, 0), c), B((w * 0.85, h * 0.8, 0.01), (0, h * 0.55, d * 0.5), GLASS)] + [C(0.03, 0.08, (-0.2 + i * 0.2, 0.5 + j * 0.4, 0), [CREAM, WAYS["rose"], GLASS][(i + j) % 3]) for i in range(3) for j in range(2)],
       pick(WOODS, 4), ONE, ["The good china, behind glass, behind a lock.", "Rattles when the lorry goes past."], big=True, heavy=True, bulky=True, fragile=True)
family("sideboard", "Sideboard", "living", "floor", (1.4, 0.45, 0.8),
       lambda w, d, h, c, a: [B((w, h * 0.9, d), (0, h * 0.5, 0), c), B((0.01, h * 0.7, 0.005), (0, h * 0.5, d * 0.5), a), B((0.1, 0.02, 0.02), (-w * 0.2, h * 0.5, d * 0.52), BRASS), B((0.1, 0.02, 0.02), (w * 0.2, h * 0.5, d * 0.52), BRASS)] + legs(w, d, 0.08, a, 0.04, 0.08),
       pick(WOODS, 5), ONE, ["Tablecloths, candles, and the drawer of batteries.", "Mid-century. Mid-weight. Takes two."], big=True, heavy=True, bulky=True)
family("drinks_trolley", "Drinks trolley", "living", "floor", (0.7, 0.4, 0.75),
       lambda w, d, h, c, a: [B((w, 0.02, d), (0, h - 0.01, 0), c), B((w, 0.02, d), (0, h * 0.45, 0), c)] + [C(0.01, h, (sx * (w / 2 - 0.03), h / 2, sz * (d / 2 - 0.03)), c) for sx in (-1, 1) for sz in (-1, 1)] + [C(0.04, 0.02, (sx * (w / 2 - 0.05), 0.04, sz * (d / 2 - 0.04)), BLACK, (1.57, 0, 0)) for sx in (-1, 1) for sz in (-1, 1)] + [C(0.03, 0.22, (-0.15 + i * 0.12, h + 0.11, 0), [GREEN, NIGHT, GLASS, MUSTARD][i]) for i in range(4)],
       pick(METALS, 3), ONE, ["Three bottles and the good glasses.", "Squeaks across the parquet on Fridays."], big=True, fragile=True, acc=BRASS)
family("chess_set", "Chess set", "living", "small", (0.34, 0.34, 0.08),
       lambda w, d, h, c, a: [B((w, 0.02, d), (0, 0.01, 0), c)] + [B((0.07, 0.004, 0.07), (-0.12 + i * 0.08, 0.022, -0.12 + j * 0.08), WHITE if (i + j) % 2 else BLACK) for i in range(4) for j in range(4)] + [C(0.012, 0.05, (-0.12 + i * 0.08, 0.045, -0.12), CREAM) for i in range(4)] + [C(0.012, 0.05, (-0.12 + i * 0.08, 0.045, 0.12), BLACK) for i in range(4)],
       pick(WOODS, 3), ONE, ["A game in progress since March.", "The white queen is a bottle top."])
family("guitar", "Guitar", "living", "small", (0.4, 0.12, 1.0),
       lambda w, d, h, c, a: [C(w * 0.5, d * 0.8, (0, h * 0.2, 0), c, (1.57, 0, 0)), C(w * 0.4, d * 0.8, (0, h * 0.42, 0), c, (1.57, 0, 0)), C(0.05, 0.01, (0, h * 0.28, d * 0.45), BLACK, (1.57, 0, 0)), B((0.05, h * 0.6, 0.03), (0, h * 0.7, 0), WALNUT), B((0.07, 0.12, 0.03), (0, h * 0.97, 0), BLACK)],
       pick(WOODS, 3) | {"sunburst": TERRA, "black": BLACK}, [("", 1.0, {}), ("on a stand", 1.0, {}), ("ukulele", 0.5, {})], ["Three chords and the truth.", "Out of tune. Perfectly."], fragile=True)
family("keyboard_piano", "Electric keyboard", "living", "small", (1.3, 0.35, 0.12),
       lambda w, d, h, c, a: [B((w, h, d), (0, h / 2, 0), c), B((w * 0.9, 0.01, d * 0.4), (0, h + 0.005, d * 0.2), WHITE)] + [B((0.02, 0.012, d * 0.25), (-w * 0.42 + i * 0.06, h + 0.012, d * 0.1), BLACK) for i in range(15)],
       {"black": BLACK, "grey": GREY, "white": WHITE}, ONE, ["Eighty-eight keys, one song.", "The stand is in a different box. Probably."], fragile=True, bulky=True)
family("aquarium", "Aquarium", "living", "small", (0.6, 0.3, 0.4),
       lambda w, d, h, c, a: [B((w, h, d), (0, h / 2, 0), GLASS), B((w, 0.03, d), (0, h - 0.015, 0), c), B((w * 0.95, 0.05, d * 0.95), (0, 0.025, 0), KRAFT), B((0.06, 0.03, 0.02), (0.1, h * 0.5, 0), WAYS["mustard"]), B((0.05, 0.025, 0.02), (-0.15, h * 0.6, 0.05), WAYS["terracotta"])],
       {"black": BLACK, "white": WHITE}, SIZES2, ["Two fish, one of them new since last time.", "Empty for the move. The fish are in a bucket."], fragile=True, heavy=True)
family("log_basket", "Log basket", "living", "floor", (0.45, 0.35, 0.4),
       lambda w, d, h, c, a: [B((w, h * 0.7, d), (0, h * 0.35, 0), c)] + [C(0.05, d * 0.9, (-0.12 + i * 0.1, h * 0.8, 0), WALNUT if i % 2 else OAK, (1.57, 0, 0)) for i in range(4)],
       {"wicker": KRAFT, "steel": STEEL, "canvas": CREAM}, ONE, ["Logs for a fire that was blocked up in the eighties.", "Spiders. Several."], heavy=True)
family("round_rug", "Round rug", "living", "floor", (1.2, 1.2, 0.03),
       lambda w, d, h, c, a: [C(w * 0.5, h, (0, h / 2, 0), c), C(w * 0.35, 0.005, (0, h + 0.002, 0), a)],
       pick(WAYS, 7), SIZES2, ["Rolls up with the crumbs inside.", "Where the dog sleeps, in the sun patch."], bulky=True)
family("bean_bag", "Bean bag", "living", "floor", (0.8, 0.8, 0.5),
       lambda w, d, h, c, a: [S(w * 0.45, (0, h * 0.45, 0), c), S(w * 0.3, (0, h * 0.75, 0), c)],
       pick(WAYS, 7), SIZES2, ["Leaks beans. A trail of beans to the truck.", "Sat in once; never climbed out of."], bulky=True)
family("trophy", "Trophy", "living", "small", (0.14, 0.14, 0.3),
       lambda w, d, h, c, a: [B((w, 0.04, w), (0, 0.02, 0), WALNUT), C(0.015, h * 0.4, (0, h * 0.3, 0), c), C(w * 0.4, h * 0.35, (0, h * 0.7, 0), c), B((0.03, 0.08, 0.01), (-w * 0.45, h * 0.65, 0), c), B((0.03, 0.08, 0.01), (w * 0.45, h * 0.65, 0), c)],
       {"gold": BRASS, "silver": STEEL, "bronze": "B87333"}, ONE, ["Under-11s, third place.", "Polished more than it was earned."], fragile=True)
family("typewriter", "Typewriter", "living", "small", (0.36, 0.34, 0.22),
       lambda w, d, h, c, a: [B((w, h * 0.5, d), (0, h * 0.25, 0), c), B((w * 0.9, h * 0.3, d * 0.3), (0, h * 0.65, -d * 0.25), c), C(0.03, w * 0.95, (0, h * 0.9, -d * 0.25), BLACK, (0, 0, 1.57))] + [C(0.011, 0.01, (-w * 0.33 + i * w * 0.055, h * 0.52, d * 0.05 + j * 0.07), WHITE) for i in range(13) for j in range(3)],
       {"black": BLACK, "sage": SAGE, "cream": CREAM, "red": RED}, ONE, ["Weighs a ton. Writes nothing.", "The e sticks. The e has always stuck."], heavy=True)
family("sewing_box", "Sewing box", "living", "small", (0.32, 0.22, 0.2),
       lambda w, d, h, c, a: [B((w, h * 0.8, d), (0, h * 0.4, 0), c), B((w * 1.02, h * 0.2, d * 1.02), (0, h * 0.9, 0), a), C(0.02, 0.05, (0, h * 1.05, 0), WAYS["red"])],
       pick(WAYS, 5) | {"wicker": KRAFT}, ONE, ["Buttons from clothes that no longer exist.", "A tin inside a box inside a basket."])
family("globe_v", "Globe", "living", "small", (0.32, 0.32, 0.45),
       lambda w, d, h, c, a: [C(w * 0.3, 0.02, (0, 0.01, 0), a), C(0.012, h * 0.3, (0, h * 0.18, 0), a), S(w * 0.45, (0, h * 0.65, 0), c), B((0.01, h * 0.6, 0.01), (w * 0.4, h * 0.65, 0), a, (0, 0, 0.4))],
       {"blue": BLUE, "antique": KRAFT, "sage": SAGE}, SIZES2, ["Countries that no longer exist.", "Spins. Lands on sea."], fragile=True, acc=BRASS)
family("fireplace_set", "Fireplace tools", "living", "floor", (0.2, 0.2, 0.6),
       lambda w, d, h, c, a: [C(w * 0.5, 0.02, (0, 0.01, 0), c), C(0.012, h, (0, h / 2, 0), c)] + [C(0.006, h * 0.85, (sx * 0.05, h * 0.5, sz * 0.05), c) for sx, sz in ((1, 0), (-1, 0), (0, 1))],
       METALS, ONE, ["A poker, a brush, and a thing with no name.", "Decorative, since the gas fire."])

# ---- loft
family("labelled_box", "Labelled box", "loft", "small", (0.45, 0.35, 0.3),
       lambda w, d, h, c, a: [B((w, h, d), (0, h / 2, 0), c), B((w * 0.5, 0.004, d * 0.4), (0, h + 0.002, 0), WHITE), B((w * 0.4, h * 0.3, 0.004), (0, h * 0.5, d * 0.5), WHITE)],
       {"kraft": KRAFT, "white": WHITE, "plastic blue": BLUE, "plastic grey": GREY}, [("", 1.0, {}), ("photos", 0.8, {}), ("tax returns", 1.0, {}), ("baby clothes", 1.1, {}), ("cables", 0.9, {})], ["Labelled MISC. Everything is MISC.", "Taped shut in 2011. Nobody has looked since."])
family("trunk_v", "Trunk", "loft", "floor", (0.9, 0.5, 0.5),
       lambda w, d, h, c, a: [B((w, h * 0.8, d), (0, h * 0.4, 0), c), B((w, h * 0.2, d), (0, h * 0.9, 0), c)] + [B((0.03, h * 1.02, d * 1.02), (x, h * 0.5, 0), a) for x in (-w * 0.3, w * 0.3)] + [B((0.06, 0.05, 0.02), (0, h * 0.78, d * 0.51), BRASS)],
       pick(WOODS, 3) | {"tin": STEEL, "leather": WALNUT}, SIZES2, ["Steamer trunk. Never saw a steamer.", "Smells of mothballs and 1962."], big=True, heavy=True)
family("old_lamp", "Old lamp", "loft", "small", (0.26, 0.26, 0.5),
       lambda w, d, h, c, a: [C(w * 0.35, 0.03, (0, 0.015, 0), a), C(0.02, h * 0.55, (0, h * 0.3, 0), a), C(w * 0.5, h * 0.3, (0, h * 0.75, 0), c, (0, 0, 0.15))],
       pick(WAYS, 5) | {"tarnished": GREY}, ONE, ["The shade is burnt on one side.", "Works. Needs a plug. Needs a bulb. Works."], fragile=True, acc=BRASS)
family("broken_chair", "Broken chair", "loft", "floor", (0.45, 0.45, 0.9),
       lambda w, d, h, c, a: [B((w, 0.03, d), (0, 0.45, 0), c), B((w, h * 0.45, 0.03), (0, h * 0.7, -d * 0.48), c, (0.12, 0, 0))] + legs(w, d, 0.44, c, 0.035)[:3] + [B((0.035, 0.3, 0.035), (w / 2 - 0.05, 0.15, d / 2 - 0.05), c, (0.5, 0, 0.3))],
       pick(WOODS, 4), ONE, ["Going to be fixed. Since 2014.", "Three good legs and a plan."])
family("picture_stack", "Stack of pictures", "loft", "small", (0.5, 0.2, 0.6),
       lambda w, d, h, c, a: [B((w, h, 0.03), (0, h / 2, -0.06), c, (0.12, 0, 0)), B((w * 0.9, h * 0.85, 0.03), (0.01, h * 0.42, -0.02), a, (0.1, 0, 0)), B((w * 0.8, h * 0.9, 0.03), (-0.01, h * 0.45, 0.02), WHITE, (0.08, 0, 0))],
       pick(WOODS, 3) | {"gilt": BRASS}, ONE, ["Frames worth more than the pictures.", "A relative nobody can place."], fragile=True, acc=TEAL)
family("pram", "Old pram", "loft", "floor", (0.9, 0.5, 1.0),
       lambda w, d, h, c, a: [B((w * 0.7, h * 0.3, d), (0, h * 0.5, 0), c), B((w * 0.4, h * 0.25, d), (-w * 0.1, h * 0.75, 0), c), C(0.012, h * 0.5, (w * 0.35, h * 0.6, 0), a, (0, 0, -0.5)), C(0.012, d, (w * 0.5, h * 0.9, 0), a, (1.57, 0, 0))] + [C(0.13, 0.03, (sx * w * 0.3, 0.13, sz * d * 0.5), BLACK, (1.57, 0, 0)) for sx in (-1, 1) for sz in (-1, 1)],
       pick(WAYS, 4) | {"navy": NIGHT}, ONE, ["Three children and a dog rode in it.", "The brake works. The brake is the only thing."], big=True, bulky=True, acc=STEEL)
family("skis", "Skis", "loft", "small", (0.2, 0.12, 1.7),
       lambda w, d, h, c, a: [B((0.08, h, 0.02), (-0.05, h / 2, 0), c), B((0.08, h, 0.02), (0.05, h / 2, 0), c), B((0.07, 0.15, 0.05), (-0.05, h * 0.5, 0.03), BLACK), B((0.07, 0.15, 0.05), (0.05, h * 0.5, 0.03), BLACK), C(0.008, h * 0.8, (0.12, h * 0.4, 0), a), C(0.008, h * 0.8, (-0.12, h * 0.4, 0), a)],
       pick(WAYS, 5), ONE, ["One trip, 2009. Knee went.", "Longer than the loft hatch. Found that out the hard way."], bulky=True, acc=STEEL)
family("tent_bag", "Tent in a bag", "loft", "small", (0.7, 0.25, 0.25),
       lambda w, d, h, c, a: [C(d * 0.5, w, (0, h * 0.5, 0), c, (0, 0, 1.57)), B((0.02, 0.1, 0.03), (0, h * 0.95, 0), a), B((w * 0.3, 0.01, 0.06), (0, h * 0.5, d * 0.5), WHITE)],
       pick(WAYS, 5), SIZES2, ["Missing one pole. Everyone knows which.", "Still damp from the last festival."])
family("suitcase_stack", "Suitcase stack", "loft", "floor", (0.7, 0.45, 0.6),
       lambda w, d, h, c, a: [B((w, h * 0.4, d), (0, h * 0.2, 0), c), B((w * 0.8, h * 0.35, d * 0.85), (0.02, h * 0.57, 0), a), B((w * 0.55, h * 0.25, d * 0.6), (-0.02, h * 0.87, 0), KRAFT), B((0.15, 0.025, 0.02), (0, h * 0.4, 0), BLACK)],
       pick(WAYS, 5) | {"tan": KRAFT}, ONE, ["Each one holds a smaller one. Russian luggage.", "Airline tags from three honeymoons. One marriage."], heavy=True)
family("gramophone", "Gramophone", "loft", "small", (0.4, 0.4, 0.6),
       lambda w, d, h, c, a: [B((w * 0.8, h * 0.3, d * 0.8), (0, h * 0.15, 0), c), C(w * 0.3, 0.01, (0, h * 0.31, 0), BLACK), C(0.015, h * 0.3, (0.08, h * 0.45, -0.08), a, (0.4, 0, -0.4)), C(0.12, h * 0.35, (0.16, h * 0.78, -0.16), a, (0.6, 0, -0.6))],
       pick(WOODS, 3), ONE, ["Horn dented. Still louder than the radio.", "Three records. All the same one."], fragile=True, acc=BRASS)
family("mannequin", "Dressmaker's dummy", "loft", "floor", (0.42, 0.3, 1.5),
       lambda w, d, h, c, a: [C(0.012, h * 0.4, (0, h * 0.2, 0), a), C(w * 0.5, 0.025, (0, 0.012, 0), a), B((w * 0.8, h * 0.45, d * 0.8), (0, h * 0.65, 0), c), C(0.04, 0.05, (0, h * 0.9, 0), a)],
       pick(WAYS, 4) | {"linen": CREAM}, ONE, ["Called Doris. Nobody remembers why.", "Scares the life out of anyone at night."], big=True, acc=WALNUT)
family("hat_stand_loft", "Hat stand", "loft", "floor", (0.4, 0.4, 1.6),
       lambda w, d, h, c, a: [C(0.02, h, (0, h / 2, 0), c), C(w * 0.5, 0.03, (0, 0.015, 0), c), C(0.16, 0.05, (0, h * 0.98, 0), NIGHT), C(0.1, 0.08, (0.12, h * 0.8, 0.1), WAYS["mustard"])],
       pick(WOODS, 4), ONE, ["Hats nobody wears, on a stand nobody uses.", "The top hat is real. The occasion was not."], big=True)
family("dartboard", "Dartboard", "loft", "hang", (0.45, 0.05, 0.45),
       lambda w, d, h, c, a: [C(w * 0.5, d, (0, h / 2, 0), BLACK, (1.57, 0, 0)), C(w * 0.42, 0.01, (0, h / 2, d * 0.55), c, (1.57, 0, 0)), C(w * 0.25, 0.012, (0, h / 2, d * 0.58), RED, (1.57, 0, 0)), C(0.02, 0.014, (0, h / 2, d * 0.6), GREEN, (1.57, 0, 0))],
       {"classic": CREAM, "faded": KRAFT}, ONE, ["Holes in the wall around it, mostly.", "Three darts. Two flights."])
family("crate_stack", "Crate stack", "loft", "floor", (0.5, 0.35, 0.6),
       lambda w, d, h, c, a: [B((w, h * 0.45, d), (0, h * 0.22, 0), c), B((w * 0.98, h * 0.45, d * 0.98), (0.01, h * 0.7, 0), c)] + [B((w * 1.02, 0.02, 0.02), (0, y, d * 0.5), a) for y in (h * 0.1, h * 0.35, h * 0.55, h * 0.85)],
       pick(WOODS, 3) | {"plastic": BLUE}, SIZES2, ["Apples came in them, decades ago.", "Stencilled with a brewery that closed."], heavy=True)
family("bird_cage", "Bird cage", "loft", "small", (0.35, 0.35, 0.55),
       lambda w, d, h, c, a: [C(w * 0.5, 0.02, (0, 0.01, 0), c), C(w * 0.5, 0.02, (0, h * 0.8, 0), c), S(w * 0.3, (0, h * 0.92, 0), c)] + [C(0.004, h * 0.8, (w * 0.45 * __import__("math").cos(i), h * 0.4, w * 0.45 * __import__("math").sin(i)), c) for i in [k * 0.52 for k in range(12)]],
       METALS, ONE, ["Empty. The budgie is a sore subject.", "Brass. Nobody polishes it."], fragile=True)
family("vinyl_crate", "Record crate", "loft", "small", (0.4, 0.36, 0.36),
       lambda w, d, h, c, a: [B((w, h * 0.9, d), (0, h * 0.45, 0), c)] + [B((0.012, h * 0.85, d * 0.85), (-w * 0.4 + i * w * 0.04, h * 0.6, 0), [BLACK, a, WHITE, NIGHT, MUSTARD][i % 5]) for i in range(21)],
       pick(WOODS, 3) | {"milk crate": BLUE}, ONE, ["Worth something, apparently. Not these ones.", "Alphabetised by someone who moved out."], heavy=True)
family("tree_box", "Christmas tree box", "loft", "small", (1.2, 0.35, 0.35),
       lambda w, d, h, c, a: [B((w, h, d), (0, h / 2, 0), c), B((w * 0.6, h * 0.6, 0.004), (0, h * 0.5, d * 0.5), GREEN), B((w * 0.2, 0.004, d * 0.6), (0, h + 0.002, 0), WHITE)],
       {"kraft": KRAFT, "green": GREEN, "red": RED}, ONE, ["Six feet of plastic fir, folded in thirds.", "Needles from a real one, somehow, inside."], bulky=True)
family("model_ship", "Model ship", "loft", "small", (0.5, 0.14, 0.45),
       lambda w, d, h, c, a: [B((w, 0.03, d), (0, 0.015, 0), WALNUT), B((w * 0.8, h * 0.25, d * 0.7), (0, h * 0.22, 0), c), C(0.006, h * 0.7, (-0.08, h * 0.65, 0), KRAFT), C(0.006, h * 0.8, (0.06, h * 0.7, 0), KRAFT), B((0.12, h * 0.4, 0.004), (0.06, h * 0.65, 0), CREAM), B((0.09, h * 0.3, 0.004), (-0.08, h * 0.6, 0), CREAM)],
       pick(WOODS, 3), SIZES2, ["Took a winter to build. Took a cat a second.", "The rigging is fishing line and patience."], fragile=True)
family("sewing_machine", "Sewing machine", "loft", "small", (0.42, 0.2, 0.3),
       lambda w, d, h, c, a: [B((w, 0.04, d), (0, 0.02, 0), WALNUT), B((0.1, h * 0.8, d * 0.6), (-w * 0.35, h * 0.45, 0), c), B((w * 0.7, 0.08, d * 0.4), (0, h * 0.88, 0), c), B((0.06, h * 0.4, 0.06), (w * 0.3, h * 0.65, 0), c), C(0.06, 0.02, (-w * 0.45, h * 0.5, 0), a, (0, 0, 1.57))],
       {"black": BLACK, "sage": SAGE, "cream": CREAM}, ONE, ["Treadle. Heavier than it looks, which is heavy.", "Still threaded with the last thing she made."], heavy=True, acc=BRASS)
family("school_desk", "School desk", "loft", "floor", (0.6, 0.45, 0.7),
       lambda w, d, h, c, a: [B((w, 0.03, d), (0, h - 0.015, 0), c, (0.12, 0, 0)), B((w, 0.15, d), (0, h - 0.1, 0), c)] + legs(w, d, h - 0.18, a, 0.03) + [C(0.02, 0.03, (w * 0.35, h + 0.01, -d * 0.3), WHITE)],
       pick(WOODS, 4), ONE, ["Initials carved inside the lid. Not theirs.", "An inkwell. Dry since decimalisation."], acc=STEEL)

# ---- shed
family("tool_box_v", "Tool box", "shed", "small", (0.45, 0.22, 0.22),
       lambda w, d, h, c, a: [B((w, h * 0.7, d), (0, h * 0.35, 0), c), B((w, h * 0.3, d), (0, h * 0.85, 0), c), B((w * 0.4, 0.025, 0.02), (0, h * 1.02, 0), a), B((0.04, 0.03, 0.02), (0, h * 0.68, d * 0.5), STEEL)],
       {"red": RED, "steel": STEEL, "black": BLACK, "blue": BLUE, "green": GREEN}, SIZES2, ["Every screw that ever came out of anything.", "The good screwdriver is in the kitchen drawer."], heavy=True)
family("paint_cans", "Paint cans", "shed", "small", (0.4, 0.22, 0.2),
       lambda w, d, h, c, a: [C(0.09, h * 0.9, (-0.12, h * 0.45, 0), STEEL), C(0.09, h * 0.9, (0.1, h * 0.45, 0.03), STEEL), C(0.07, 0.02, (-0.12, h * 0.9, 0), c), C(0.07, 0.02, (0.1, h * 0.9, 0.03), a), B((0.06, 0.12, 0.004), (-0.12, h * 0.4, 0.09), WHITE)],
       pick(WAYS, 7), ONE, ["Half a tin of every colour in the house.", "Skinned over. Still the right shade."], heavy=True)
family("flower_pot_v", "Flower pots", "shed", "small", (0.3, 0.3, 0.26),
       lambda w, d, h, c, a: [C(0.1, h * 0.6, (-0.06, h * 0.3, 0), c), C(0.08, h * 0.5, (0.09, h * 0.25, 0.05), c), C(0.1, h * 0.25, (-0.06, h * 0.72, 0), c), C(0.06, h * 0.4, (0.06, h * 0.2, -0.1), a)],
       {"terracotta": TERRA, "glazed sage": SAGE, "glazed blue": BLUE, "plastic black": BLACK, "cream": CREAM}, SIZES2, ["Stacked. Welded together by frost.", "One has a plant. The plant is not well."], fragile=True)
family("spades", "Spade and fork", "shed", "small", (0.2, 0.1, 1.1),
       lambda w, d, h, c, a: [C(0.012, h * 0.75, (-0.05, h * 0.55, 0), c), B((0.14, 0.22, 0.012), (-0.05, h * 0.12, 0), STEEL), B((0.08, 0.03, 0.03), (-0.05, h * 0.95, 0), c), C(0.012, h * 0.75, (0.06, h * 0.55, 0), c)] + [B((0.012, 0.22, 0.012), (0.03 + i * 0.03, h * 0.12, 0), STEEL) for i in range(3)] + [B((0.08, 0.03, 0.03), (0.06, h * 0.95, 0), c)],
       pick(WOODS, 3) | {"steel": STEEL}, ONE, ["Dug one bed. Retired.", "The fork is bent from the one big stone."])
family("hose_v", "Coiled hose", "shed", "small", (0.4, 0.4, 0.14),
       lambda w, d, h, c, a: [C(w * 0.5, h * 0.3, (0, h * 0.15, 0), c), C(w * 0.3, h * 0.3, (0, h * 0.15, 0), KRAFT), C(w * 0.48, h * 0.3, (0, h * 0.45, 0.02), c), C(w * 0.45, h * 0.3, (0.02, h * 0.75, 0), c), C(0.02, 0.06, (w * 0.45, h * 0.5, 0), a, (0, 0, 1.57))],
       {"green": GREEN, "yellow": MUSTARD, "black": BLACK}, SIZES2, ["Kinks. Always kinks.", "Leaks at the tap end, sprays at the other."], acc=STEEL)
family("bucket", "Bucket", "shed", "small", (0.3, 0.3, 0.3),
       lambda w, d, h, c, a: [C(w * 0.5, h, (0, h / 2, 0), c), C(0.006, w * 0.9, (0, h * 0.95, 0), a, (0, 0, 1.57))],
       pick(WAYS, 6) | {"galvanised": STEEL}, [("", 1.0, {}), ("stack of", 1.0, {}), ("mop", 1.1, {})], ["Cracked. Still a bucket, mostly.", "The handle pinches. Everybody knows."], acc=STEEL)
family("child_bike", "Child's bike", "shed", "floor", (0.9, 0.3, 0.6),
       lambda w, d, h, c, a: [C(0.2, 0.03, (-0.28, 0.2, 0), BLACK, (1.57, 0, 0)), C(0.2, 0.03, (0.28, 0.2, 0), BLACK, (1.57, 0, 0)), B((0.5, 0.02, 0.02), (0, 0.35, 0), c, (0, 0, 0.3)), B((0.4, 0.02, 0.02), (-0.1, 0.4, 0), c), C(0.012, 0.25, (0.25, 0.42, 0), c, (0, 0, 0.2)), B((0.3, 0.02, 0.02), (0.28, 0.55, 0), c, (0, 1.57, 0)), B((0.12, 0.03, 0.06), (-0.1, 0.52, 0), a), C(0.06, 0.02, (-0.45, 0.06, 0), WHITE, (1.57, 0, 0))],
       pick(WAYS, 6), [("", 1.0, {}), ("with stabilisers", 1.0, {}), ("balance", 0.8, {})], ["Stabilisers off at six. Tears. Then joy.", "Outgrown. Kept for the cousins."], bulky=True, acc=BLACK)
family("push_mower", "Push mower", "shed", "floor", (0.5, 0.9, 0.9),
       lambda w, d, h, c, a: [C(w * 0.45, 0.02, (-w * 0.3, 0.12, 0.3), BLACK, (0, 0, 1.57)), C(w * 0.45, 0.02, (w * 0.3, 0.12, 0.3), BLACK, (0, 0, 1.57)), C(0.1, w * 0.5, (0, 0.12, 0.3), c, (0, 0, 1.57)), B((w * 0.6, 0.1, 0.2), (0, 0.15, 0.15), c), C(0.012, h * 0.95, (0.12, h * 0.5, -0.1), a, (0.5, 0, 0)), C(0.012, h * 0.95, (-0.12, h * 0.5, -0.1), a, (0.5, 0, 0)), C(0.015, 0.3, (0, h * 0.95, -0.32), a, (0, 0, 1.57))],
       {"green": GREEN, "red": RED, "black": BLACK}, ONE, ["The blades go whirr. The grass stays long.", "Oiled yearly, by a man who died."], heavy=True, bulky=True, acc=STEEL)
family("garden_bench", "Garden bench", "shed", "floor", (1.3, 0.5, 0.85),
       lambda w, d, h, c, a: [B((w, 0.04, d), (0, 0.44, 0), c), B((w, 0.35, 0.03), (0, 0.65, -d * 0.45), c, (0.1, 0, 0))] + legs(w, d, 0.42, c, 0.05) + [B((0.05, 0.25, d * 0.9), (sx * (w / 2 - 0.025), 0.58, 0), c) for sx in (-1, 1)],
       pick(WOODS, 4) | {"cast iron": BLACK}, ONE, ["Dedicated to someone, with a plaque.", "Silvered by the weather. Still solid."], big=True, heavy=True, bulky=True)
family("barbecue", "Barbecue", "shed", "floor", (0.6, 0.6, 0.9),
       lambda w, d, h, c, a: [C(w * 0.5, h * 0.3, (0, h * 0.6, 0), c), C(w * 0.5, h * 0.25, (0, h * 0.85, 0), c), S(0.02, (0, h * 1.0, 0), WALNUT)] + [C(0.012, h * 0.55, (sx * 0.15, h * 0.27, sz * 0.15), a) for sx, sz in ((1, 0), (-0.5, 0.86), (-0.5, -0.86))] + [C(0.06, 0.02, (0.15, 0.06, 0), BLACK, (1.57, 0, 0))],
       {"black": BLACK, "red": RED, "green": GREEN}, [("", 1.0, {}), ("kettle", 1.0, {}), ("gas", 1.3, {})], ["Used twice a summer. Cleaned once.", "Last year's ash, still in it."], heavy=True, acc=STEEL)
family("compost_bin", "Compost bin", "shed", "floor", (0.6, 0.6, 0.8),
       lambda w, d, h, c, a: [C(w * 0.45, h * 0.9, (0, h * 0.45, 0), c), C(w * 0.5, h * 0.1, (0, h * 0.95, 0), a), B((0.2, 0.15, 0.02), (0, h * 0.15, w * 0.45), a)],
       {"black": BLACK, "green": GREEN, "wood": OAK}, ONE, ["Hot in the middle, apparently.", "Rats. Possibly. Probably."], big=True, bulky=True, acc=GREY)
family("seed_trays", "Seed trays", "shed", "small", (0.4, 0.24, 0.1),
       lambda w, d, h, c, a: [B((w, h * 0.5, d), (0, h * 0.25, 0), c)] + [C(0.025, 0.04, (-0.15 + i * 0.075, h * 0.6, z), GREEN) for i in range(5) for z in (-0.06, 0.06)],
       {"black": BLACK, "terracotta": TERRA, "green": GREEN}, ONE, ["Tomatoes that will never ripen.", "Labelled in pencil, washed out by rain."], fragile=True)
family("wellies", "Wellies", "shed", "small", (0.3, 0.3, 0.36),
       lambda w, d, h, c, a: [C(0.05, h * 0.9, (-0.07, h * 0.45, 0), c), C(0.05, h * 0.9, (0.07, h * 0.45, 0), c), B((0.1, 0.05, 0.26), (-0.07, 0.025, 0.06), c), B((0.1, 0.05, 0.26), (0.07, 0.025, 0.06), c)],
       pick(WAYS, 7) | {"black": BLACK}, [("", 1.0, {}), ("child's", 0.6, {}), ("pair of", 1.0, {})], ["Mud in the tread from a walk in 2019.", "Spider in the left one. Always check."])
family("bird_feeder", "Bird feeder", "shed", "small", (0.2, 0.2, 0.5),
       lambda w, d, h, c, a: [C(0.012, h * 0.5, (0, h * 0.25, 0), a), B((w, 0.02, d), (0, h * 0.5, 0), c), B((w * 1.1, h * 0.25, d * 1.1), (0, h * 0.85, 0), c, (0, 0.785, 0)), C(0.03, 0.14, (0, h * 0.62, 0), GLASS)],
       pick(WOODS, 3) | {"green": GREEN}, ONE, ["Squirrels got it. Squirrels get everything.", "Full of seed. Empty of birds."])
family("wheelbarrow_v", "Wheelbarrow", "shed", "floor", (0.65, 1.2, 0.6),
       lambda w, d, h, c, a: [B((w, h * 0.45, d * 0.6), (0, h * 0.5, 0.1), c), C(0.15, 0.06, (0, 0.15, d * 0.4), BLACK, (0, 0, 1.57)), C(0.012, d * 0.9, (-w * 0.35, 0.3, -0.1), a, (1.57, 0, 0)), C(0.012, d * 0.9, (w * 0.35, 0.3, -0.1), a, (1.57, 0, 0)), B((0.04, 0.25, 0.04), (-w * 0.3, 0.12, -d * 0.2), a), B((0.04, 0.25, 0.04), (w * 0.3, 0.12, -d * 0.2), a)],
       {"green": GREEN, "red": RED, "galvanised": STEEL, "black": BLACK}, ONE, ["Flat tyre. Has been since the leaves.", "Carried bricks, logs, a child, a dog."], big=True, heavy=True, bulky=True, acc=WALNUT)
family("deck_chair", "Deck chair", "shed", "floor", (0.6, 0.8, 0.85),
       lambda w, d, h, c, a: [B((w * 0.8, h * 0.9, 0.012), (0, h * 0.5, -0.1), c, (0.6, 0, 0)), B((0.03, h * 0.95, 0.03), (-w * 0.45, h * 0.47, -0.2), a, (0.3, 0, 0)), B((0.03, h * 0.95, 0.03), (w * 0.45, h * 0.47, -0.2), a, (0.3, 0, 0)), B((0.03, h * 0.6, 0.03), (-w * 0.45, h * 0.3, 0.2), a, (-0.5, 0, 0)), B((0.03, h * 0.6, 0.03), (w * 0.45, h * 0.3, 0.2), a, (-0.5, 0, 0))],
       pick(WAYS, 6), [("", 1.0, {}), ("striped", 1.0, {}), ("pair of", 1.0, {})], ["Collapses on anyone over twelve.", "Striped like a seaside from a brochure."], acc=PINE)
family("parasol", "Parasol", "shed", "floor", (0.4, 0.4, 2.0),
       lambda w, d, h, c, a: [C(w * 0.5, 0.06, (0, 0.03, 0), BLACK), C(0.015, h, (0, h / 2, 0), a), C(0.12, h * 0.6, (0, h * 0.65, 0), c), C(0.05, 0.05, (0, h * 0.98, 0), c)],
       pick(WAYS, 6), ONE, ["Folded. Opening it is a two-person job.", "Blew into next door's pond once."], big=True, bulky=True, acc=PINE)
family("planter_box", "Planter box", "shed", "floor", (0.8, 0.35, 0.4),
       lambda w, d, h, c, a: [B((w, h * 0.85, d), (0, h * 0.42, 0), c), B((w * 0.95, 0.03, d * 0.95), (0, h * 0.84, 0), WALNUT)] + [S(0.06, (-0.25 + i * 0.16, h * 0.95, 0), GREEN if i % 2 else SAGE) for i in range(4)],
       pick(WOODS, 3) | {"terracotta": TERRA, "black": BLACK}, SIZES2, ["Herbs. Mint has won.", "Full of soil, which is to say full of weight."], heavy=True, bulky=True)
family("watering_v", "Watering can", "shed", "small", (0.4, 0.2, 0.3),
       lambda w, d, h, c, a: [C(0.1, h * 0.8, (-0.08, h * 0.4, 0), c), C(0.015, 0.25, (0.08, h * 0.5, 0), c, (0, 0, -1.0)), C(0.035, 0.02, (0.17, h * 0.75, 0), a), B((0.12, 0.02, 0.02), (-0.08, h * 0.88, 0), c), B((0.02, h * 0.4, 0.02), (-0.2, h * 0.5, 0), c)],
       pick(WAYS, 6) | {"galvanised": STEEL}, SIZES2, ["Rose on the spout, mostly blocked.", "Leaves a puddle wherever it is put down."], acc=STEEL)
family("axe_logs", "Axe and logs", "shed", "small", (0.4, 0.4, 0.4),
       lambda w, d, h, c, a: [C(0.18, 0.28, (0, 0.14, 0), WALNUT), B((0.03, h * 0.9, 0.03), (0.05, h * 0.65, 0.05), c, (0.3, 0, -0.5)), B((0.12, 0.08, 0.02), (0.14, h * 0.95, -0.05), STEEL, (0.3, 0, -0.5))] + [C(0.06, 0.25, (-0.1 + i * 0.1, 0.34, 0.1), OAK, (1.57, 0, 0)) for i in range(2)],
       pick(WOODS, 2), ONE, ["The chopping block is older than the house.", "Sharp. Treat it as sharp."], heavy=True)
family("sawhorse", "Sawhorse", "shed", "floor", (0.9, 0.5, 0.75),
       lambda w, d, h, c, a: [B((w, 0.06, 0.08), (0, h - 0.03, 0), c)] + [B((0.04, h, 0.04), (sx * (w / 2 - 0.08), h / 2, sz * 0.18), c, (sz * 0.3, 0, 0)) for sx in (-1, 1) for sz in (-1, 1)],
       pick(WOODS, 3) | {"steel": STEEL}, [("", 1.0, {}), ("pair of", 1.0, {})], ["Sawdust still on it from the shelves.", "Held a door, a plank, a tea tray."])
family("step_ladder", "Step ladder", "shed", "floor", (0.5, 0.7, 1.2),
       lambda w, d, h, c, a: [B((0.04, h, 0.04), (sx * (w / 2 - 0.02), h / 2, -0.15), c, (0.25, 0, 0)) for sx in (-1, 1)] + [B((0.04, h, 0.04), (sx * (w / 2 - 0.02), h / 2, 0.15), c, (-0.25, 0, 0)) for sx in (-1, 1)] + [B((w - 0.08, 0.03, 0.12), (0, 0.25 + i * 0.25, -0.15 + i * 0.07), a) for i in range(4)],
       pick(WOODS, 2) | {"aluminium": STEEL}, ONE, ["Wobbles on the third step. Everyone knows.", "Paint on every rung, a different colour each."], big=True, acc=PINE)
family("metal_shelving", "Metal shelving", "shed", "floor", (0.9, 0.4, 1.8),
       lambda w, d, h, c, a: [B((0.03, h, 0.03), (sx * (w / 2 - 0.015), h / 2, sz * (d / 2 - 0.015)), c) for sx in (-1, 1) for sz in (-1, 1)] + [B((w, 0.02, d), (0, y, 0), c) for y in (0.1, 0.55, 1.0, 1.45, h - 0.01)] + [B((0.25, 0.18, 0.3), (-0.25, 0.65, 0), KRAFT), C(0.08, 0.22, (0.2, 1.11, 0), a), B((0.3, 0.2, 0.25), (0.15, 0.2, 0), BLUE)],
       {"grey": GREY, "steel": STEEL, "black": BLACK}, ONE, ["Bolted together wrong. Holds anyway.", "Paint, pots, and a box marked DO NOT OPEN."], big=True, heavy=True, bulky=True, acc=RED)
family("pegboard", "Pegboard", "shed", "hang", (0.8, 0.04, 0.6),
       lambda w, d, h, c, a: [B((w, h, d), (0, h / 2, 0), c), B((0.03, 0.25, 0.015), (-0.25, h * 0.5, d * 0.6), STEEL), B((0.2, 0.03, 0.015), (0.1, h * 0.75, d * 0.6), a), B((0.06, 0.1, 0.02), (0.25, h * 0.35, d * 0.6), WALNUT), B((0.12, 0.06, 0.015), (-0.05, h * 0.3, d * 0.6), RED)],
       {"kraft": KRAFT, "white": WHITE, "sage": SAGE}, ONE, ["An outline for every tool, and half the tools.", "The hammer has its own hook. Royalty."], acc=STEEL)
family("lantern", "Lantern", "shed", "small", (0.16, 0.16, 0.3),
       lambda w, d, h, c, a: [B((w, 0.02, d), (0, 0.01, 0), c), B((w * 0.8, h * 0.7, d * 0.8), (0, h * 0.45, 0), GLASS), B((w, 0.03, d), (0, h * 0.82, 0), c), C(0.006, 0.12, (0, h * 0.95, 0), c, (0, 0, 1.57)), C(0.012, h * 0.3, (0, h * 0.35, 0), MUSTARD)],
       METALS, ONE, ["Paraffin. There is no paraffin.", "Lit for power cuts and once for a proposal."], fragile=True)
family("cool_box", "Cool box", "shed", "small", (0.5, 0.32, 0.36),
       lambda w, d, h, c, a: [B((w, h * 0.8, d), (0, h * 0.4, 0), c), B((w * 1.02, h * 0.2, d * 1.02), (0, h * 0.9, 0), a), B((w * 0.5, 0.025, 0.025), (0, h * 1.02, 0), a)],
       {"blue": BLUE, "red": RED, "white": WHITE, "green": GREEN}, SIZES2, ["Smells of a picnic that went wrong.", "Ice packs in the freezer since July."])
family("fishing_rods", "Fishing rods", "shed", "small", (0.15, 0.12, 1.6),
       lambda w, d, h, c, a: [C(0.008, h, (-0.03, h / 2, 0), c, (0, 0, 0.05)), C(0.008, h * 0.9, (0.03, h * 0.45, 0), a, (0, 0, -0.05)), C(0.03, 0.04, (-0.03, h * 0.3, 0.03), BLACK, (1.57, 0, 0)), B((0.2, 0.15, 0.1), (0.06, 0.08, 0), GREEN)],
       pick(WOODS, 2) | {"carbon": BLACK}, ONE, ["Caught one fish. The story has grown.", "The reel sings when it is cast. It is not cast."], fragile=True)
family("generator", "Generator", "shed", "floor", (0.6, 0.45, 0.5),
       lambda w, d, h, c, a: [B((w, h * 0.7, d), (0, h * 0.35, 0), c), B((w * 0.7, h * 0.3, d * 0.7), (0, h * 0.85, 0), a), C(0.02, 0.1, (w * 0.3, h * 1.05, 0), STEEL), C(0.015, w * 0.9, (0, h * 1.1, 0), STEEL, (0, 0, 1.57))],
       {"red": RED, "yellow": MUSTARD, "black": BLACK}, ONE, ["For the power cut that never came.", "Petrol in it. Mind the fumes."], heavy=True, acc=BLACK)
family("kayak", "Kayak", "shed", "floor", (2.4, 0.6, 0.35),
       lambda w, d, h, c, a: [C(d * 0.5, w * 0.7, (0, h * 0.5, 0), c, (0, 0, 1.57)), C(d * 0.3, w * 0.2, (w * 0.42, h * 0.5, 0), c, (0, 0, 1.57)), C(d * 0.3, w * 0.2, (-w * 0.42, h * 0.5, 0), c, (0, 0, 1.57)), C(d * 0.3, 0.02, (0, h * 0.95, 0), BLACK)],
       pick(WAYS, 5), ONE, ["One summer on the river. Then the shed.", "Longer than the truck. Mind the doors."], big=True, heavy=True, bulky=True)

# ---- office
family("desk_lamp", "Desk lamp", "office", "small", (0.2, 0.2, 0.42),
       lambda w, d, h, c, a: [C(w * 0.4, 0.02, (0, 0.01, 0), c), C(0.012, h * 0.5, (0, h * 0.27, 0), c, (0, 0, 0.2)), C(0.012, h * 0.45, (0.08, h * 0.7, 0), c, (0, 0, -0.6)), C(0.05, 0.08, (0.17, h * 0.85, 0), c, (0, 0, 0.8))],
       pick(WAYS, 6) | {"black": BLACK, "steel": STEEL}, ONE, ["Angled at the one spot that matters.", "Hums when it warms up."], fragile=True)
family("monitor", "Monitor", "office", "small", (0.55, 0.2, 0.42),
       lambda w, d, h, c, a: [B((w, h * 0.75, 0.03), (0, h * 0.6, 0), BLACK), B((w * 0.95, h * 0.68, 0.01), (0, h * 0.6, 0.02), c), B((0.04, h * 0.2, 0.04), (0, h * 0.15, 0), BLACK), B((w * 0.4, 0.02, d), (0, 0.01, 0), BLACK)],
       {"off": NIGHT, "on": TEAL, "spreadsheet": CREAM}, [("", 1.0, {}), ("wide", 1.5, {}), ("second", 1.0, {})], ["Screen out, and pad it twice.", "A sticky note on the bezel: the password."], fragile=True)
family("keyboard_mouse", "Keyboard and mouse", "office", "small", (0.46, 0.2, 0.03),
       lambda w, d, h, c, a: [B((w * 0.8, h, d * 0.7), (-w * 0.1, h / 2, 0), c)] + [B((0.02, 0.008, 0.02), (-w * 0.45 + i * 0.03, h + 0.004, z), a) for i in range(12) for z in (-0.04, 0, 0.04)] + [B((0.06, 0.03, 0.1), (w * 0.4, 0.015, 0), c)],
       {"black": BLACK, "white": WHITE, "grey": GREY}, ONE, ["Crumbs under every key.", "The space bar needs a thump."])
family("filing_cabinet", "Filing cabinet", "office", "floor", (0.45, 0.6, 1.3),
       lambda w, d, h, c, a: [B((w, h, d), (0, h / 2, 0), c)] + [B((w * 0.9, h * 0.28, 0.01), (0, h * (0.17 + i * 0.3), d * 0.5), c) for i in range(3)] + [B((0.12, 0.02, 0.02), (0, h * (0.2 + i * 0.3), d * 0.52), a) for i in range(3)],
       {"grey": GREY, "black": BLACK, "sage": SAGE, "cream": CREAM, "steel": STEEL}, [("", 1.0, {}), ("two-drawer", 0.7, {}), ("four-drawer", 1.3, {})], ["Locked. Key lost. Contents unknown.", "Top drawer sticks, bottom drawer biscuits."], big=True, heavy=True, acc=STEEL)
family("office_chair", "Office chair", "office", "floor", (0.6, 0.6, 1.0),
       lambda w, d, h, c, a: [B((w * 0.8, 0.08, d * 0.8), (0, 0.48, 0), c), B((w * 0.75, h * 0.45, 0.06), (0, h * 0.72, -d * 0.35), c), C(0.025, 0.3, (0, 0.3, 0), a), C(0.3, 0.02, (0, 0.05, 0), a)] + [B((0.12, 0.03, 0.03), (sx * 0.15, 0.6, 0), a) for sx in (-1, 1)],
       pick(WAYS, 5) | {"black": BLACK}, [("", 1.0, {}), ("mesh", 1.0, {}), ("executive", 1.15, {})], ["Sinks slowly. Every meeting ends shorter.", "One wheel goes its own way."], big=True, bulky=True, acc=BLACK)
family("printer", "Printer", "office", "small", (0.45, 0.38, 0.2),
       lambda w, d, h, c, a: [B((w, h * 0.8, d), (0, h * 0.4, 0), c), B((w * 0.6, 0.01, d * 0.5), (0, h * 0.85, -d * 0.1), a), B((w * 0.5, 0.004, d * 0.3), (0, h * 0.6, d * 0.55), WHITE), S(0.01, (w * 0.35, h * 0.82, d * 0.3), GREEN)],
       {"white": WHITE, "grey": GREY, "black": BLACK}, ONE, ["Out of magenta. Nobody prints in magenta.", "Jams on page two of anything."], fragile=True)
family("paper_tray", "Paper trays", "office", "small", (0.34, 0.26, 0.2),
       lambda w, d, h, c, a: [B((w, 0.012, d), (0, 0.02 + i * 0.07, 0), c) for i in range(3)] + [B((w * 0.9, 0.01, d * 0.9), (0, 0.03 + i * 0.07, 0), WHITE) for i in range(3)] + [B((0.02, h, 0.02), (sx * (w / 2 - 0.01), h / 2, -d * 0.45), c) for sx in (-1, 1)],
       {"black": BLACK, "steel": STEEL, "sage": SAGE}, ONE, ["In, out, and the one nobody checks.", "A memo from 2019, still in the in-tray."])
family("pen_pot", "Pen pot", "office", "small", (0.09, 0.09, 0.14),
       lambda w, d, h, c, a: [C(w * 0.5, h * 0.7, (0, h * 0.35, 0), c)] + [B((0.008, h * 0.9, 0.008), (sx * 0.02, h * 0.6, sz * 0.02), [BLUE, RED, BLACK, MUSTARD][(sx + 1) + (sz + 1) // 2], (sz * 0.1, 0, sx * 0.15)) for sx in (-1, 1) for sz in (-1, 1)],
       pick(WAYS, 6) | {"steel": STEEL}, ONE, ["Twelve pens. Two work.", "A mug that lost its handle, promoted."])
family("whiteboard", "Whiteboard", "office", "hang", (0.9, 0.04, 0.6),
       lambda w, d, h, c, a: [B((w, h, d), (0, h / 2, 0), c), B((w * 0.95, h * 0.92, 0.01), (0, h / 2, d * 0.55), WHITE), B((w * 0.6, 0.02, 0.06), (0, 0.04, d * 0.6), c), B((0.3, 0.02, 0.004), (-0.15, h * 0.7, d * 0.62), BLUE), B((0.2, 0.02, 0.004), (0.1, h * 0.5, d * 0.62), RED)],
       {"aluminium": STEEL, "oak": OAK, "black": BLACK}, SIZES2, ["A plan from a meeting nobody remembers.", "DO NOT ERASE, in the corner, since March."], fragile=True)
family("cork_board", "Cork board", "office", "hang", (0.6, 0.03, 0.45),
       lambda w, d, h, c, a: [B((w, h, d), (0, h / 2, 0), c), B((w * 0.92, h * 0.9, 0.01), (0, h / 2, d * 0.55), KRAFT), B((0.1, 0.12, 0.004), (-0.15, h * 0.6, d * 0.6), WHITE), B((0.08, 0.08, 0.004), (0.12, h * 0.45, d * 0.6), MUSTARD), S(0.006, (-0.15, h * 0.7, d * 0.62), RED), S(0.006, (0.12, h * 0.52, d * 0.62), BLUE)],
       pick(WOODS, 3), SIZES2, ["A takeaway menu and a photo of a dog.", "Pinned: the rota from last winter."])
family("office_plant", "Office plant", "office", "floor", (0.35, 0.35, 0.8),
       lambda w, d, h, c, a: [C(w * 0.4, h * 0.3, (0, h * 0.15, 0), c), C(0.015, h * 0.45, (0, h * 0.5, 0), WALNUT)] + [B((0.06, 0.28, 0.01), (x * 0.08, h * 0.78, z * 0.08), GREEN, (z * 0.5, 0.3, -x * 0.5)) for x in (-1, 0, 1) for z in (-1, 1)],
       pick(WAYS, 5) | {"grey": GREY}, SIZES2, ["Watered by whoever notices.", "Plastic. Nobody has noticed."])
family("water_cooler", "Water cooler", "office", "floor", (0.35, 0.35, 1.2),
       lambda w, d, h, c, a: [B((w, h * 0.7, d), (0, h * 0.35, 0), c), C(w * 0.38, h * 0.3, (0, h * 0.85, 0), GLASS), B((0.04, 0.06, 0.04), (0, h * 0.5, d * 0.5), a), B((0.04, 0.06, 0.04), (0.08, h * 0.5, d * 0.5), BLUE)],
       {"white": WHITE, "grey": GREY, "black": BLACK}, ONE, ["Where the gossip happens.", "Glug. Everyone looks up."], heavy=True, acc=RED)
family("office_bin", "Waste bin", "office", "floor", (0.28, 0.28, 0.32),
       lambda w, d, h, c, a: [C(w * 0.5, h, (0, h / 2, 0), c), B((0.08, 0.04, 0.06), (0.02, h * 1.0, 0), WHITE, (0.3, 0.5, 0.2))],
       {"steel mesh": STEEL, "black": BLACK, "sage": SAGE, "grey": GREY}, ONE, ["Missed. From across the room, mostly.", "Shredded something important. Again."])
family("shredder", "Shredder", "office", "floor", (0.36, 0.26, 0.5),
       lambda w, d, h, c, a: [B((w, h * 0.8, d), (0, h * 0.4, 0), c), B((w * 1.02, h * 0.2, d * 1.02), (0, h * 0.9, 0), a), B((w * 0.7, 0.01, 0.02), (0, h * 1.01, 0), BLACK)],
       {"black": BLACK, "grey": GREY, "white": WHITE}, ONE, ["Jammed on a credit card.", "Confetti for the office party."], acc=GREY)
family("office_shelf", "Office shelving", "office", "floor", (0.8, 0.35, 1.8),
       lambda w, d, h, c, a: [B((0.03, h, d), (sx * (w / 2 - 0.015), h / 2, 0), c) for sx in (-1, 1)] + [B((w, 0.025, d), (0, y, 0), c) for y in (0.05, 0.5, 0.95, 1.4, h - 0.01)] + [B((0.06, 0.3, d * 0.8), (-w * 0.35 + i * 0.075, y + 0.17, 0), [a, NIGHT, WHITE, SAGE, BLUE, CREAM][(i + int(y * 10)) % 6]) for y in (0.05, 0.5, 0.95) for i in range(8)],
       pick(WOODS, 3) | {"white": WHITE, "grey": GREY}, ONE, ["Lever-arch files from the dawn of time.", "Labelled by year. Missing 2017."], big=True, heavy=True, bulky=True, acc=RED)
family("desk_v", "Desk", "office", "floor", (1.4, 0.7, 0.75),
       lambda w, d, h, c, a: [B((w, 0.03, d), (0, h - 0.015, 0), c), B((0.4, h - 0.05, d * 0.9), (w / 2 - 0.22, (h - 0.05) / 2, 0), c), B((0.36, 0.01, 0.005), (w / 2 - 0.22, h * 0.5, d * 0.46), a), B((0.04, h - 0.05, 0.04), (-w / 2 + 0.05, (h - 0.05) / 2, -d / 2 + 0.05), c), B((0.04, h - 0.05, 0.04), (-w / 2 + 0.05, (h - 0.05) / 2, d / 2 - 0.05), c)],
       pick(WOODS, 5) | {"white": WHITE}, [("", 1.0, {}), ("corner", 1.2, {}), ("small", 0.8, {})], ["Coffee rings in a chain to the keyboard.", "The drawer that will not open has the good pens."], big=True, heavy=True, bulky=True, acc=BRASS)
family("laptop", "Laptop", "office", "small", (0.34, 0.24, 0.22),
       lambda w, d, h, c, a: [B((w, 0.02, d), (0, 0.01, 0), c), B((w, 0.01, d), (0, h * 0.5, -d * 0.42), c, (1.2, 0, 0)), B((w * 0.9, 0.005, d * 0.9), (0, h * 0.5, -d * 0.4), a, (1.2, 0, 0))],
       {"silver": STEEL, "black": BLACK, "sage": SAGE}, [("", 1.0, {}), ("open", 1.0, {}), ("old", 1.1, {})], ["Forty-seven tabs open.", "Fan like a hairdryer. Battery like a memory."], fragile=True, acc=TEAL)
family("desk_phone", "Desk phone", "office", "small", (0.22, 0.18, 0.1),
       lambda w, d, h, c, a: [B((w, h * 0.6, d), (0, h * 0.3, 0), c, (0.2, 0, 0)), B((0.05, h * 0.4, d * 0.9), (-w * 0.35, h * 0.75, 0), c), B((w * 0.4, 0.008, d * 0.4), (w * 0.15, h * 0.62, 0), a)],
       {"black": BLACK, "cream": CREAM, "grey": GREY}, ONE, ["Rings. Nobody answers it.", "A cord that reaches the kettle, just."])
family("office_clock", "Office clock", "office", "hang", (0.3, 0.04, 0.3),
       lambda w, d, h, c, a: [C(w * 0.5, d, (0, h / 2, 0), c, (1.57, 0, 0)), C(w * 0.45, 0.01, (0, h / 2, d * 0.55), WHITE, (1.57, 0, 0)), B((0.01, h * 0.3, 0.006), (0, h * 0.62, d * 0.6), BLACK), B((h * 0.24, 0.01, 0.006), (h * 0.1, h / 2, d * 0.6), BLACK), B((0.004, h * 0.4, 0.004), (0, h * 0.55, d * 0.62), RED)],
       {"black": BLACK, "white": WHITE, "steel": STEEL}, ONE, ["Everyone watches it from four.", "Ten minutes fast, by decree."], fragile=True)
family("office_poster", "Framed print", "office", "hang", (0.5, 0.03, 0.7),
       lambda w, d, h, c, a: [B((w, h, d), (0, h / 2, 0), c), B((w * 0.9, h * 0.9, 0.01), (0, h / 2, d * 0.55), a), B((w * 0.5, h * 0.08, 0.005), (0, h * 0.3, d * 0.6), WHITE)],
       {"black": BLACK, "oak": OAK, "white": WHITE}, [("", 1.0, {}), ("motivational", 1.0, {}), ("map", 1.3, {})], ["TEAMWORK, over a photo of rowers.", "A map of the town with the office circled."], fragile=True, acc=SAGE)
family("desk_tidy", "Desk tidy", "office", "small", (0.24, 0.12, 0.08),
       lambda w, d, h, c, a: [B((w, h * 0.5, d), (0, h * 0.25, 0), c), B((0.08, 0.025, 0.04), (-0.06, h * 0.6, 0), a), C(0.015, 0.03, (0.06, h * 0.6, 0), STEEL), B((0.04, 0.012, 0.04), (0.0, h * 0.55, 0.03), MUSTARD)],
       pick(WOODS, 3) | {"black": BLACK}, ONE, ["Paperclips, a stapler, and a key to nothing.", "Rubber bands, dry as biscuits."])
family("coat_rack_office", "Coat rack", "office", "hang", (0.6, 0.1, 0.2),
       lambda w, d, h, c, a: [B((w, 0.04, 0.03), (0, h * 0.8, 0), c)] + [C(0.01, 0.08, (-w * 0.35 + i * w * 0.23, h * 0.75, 0.04), a, (1.57, 0, 0)) for i in range(4)] + [B((0.14, h * 2.5, 0.06), (-w * 0.12, h * 0.1, 0.05), NIGHT)],
       pick(WOODS, 3) | {"steel": STEEL}, ONE, ["One coat left behind by a leaver.", "Umbrellas. Three. All broken."], acc=STEEL)
family("safe", "Safe", "office", "floor", (0.45, 0.45, 0.55),
       lambda w, d, h, c, a: [B((w, h, d), (0, h / 2, 0), c), C(0.05, 0.03, (0.08, h * 0.55, d * 0.5), a, (1.57, 0, 0)), B((0.03, 0.12, 0.03), (-0.1, h * 0.55, d * 0.52), STEEL)],
       {"black": BLACK, "grey": GREY, "green": GREEN}, [("", 1.0, {}), ("small", 0.7, {})], ["Combination written on the underside.", "Heavier than it needs to be. On purpose."], heavy=True, acc=STEEL)
family("low_cabinet", "Low cabinet", "office", "floor", (0.9, 0.45, 0.75),
       lambda w, d, h, c, a: [B((w, h, d), (0, h / 2, 0), c), B((0.01, h * 0.8, 0.005), (0, h / 2, d * 0.5), a), B((0.08, 0.02, 0.02), (-0.12, h * 0.5, d * 0.52), STEEL), B((0.08, 0.02, 0.02), (0.12, h * 0.5, d * 0.52), STEEL)],
       pick(WOODS, 4) | {"white": WHITE, "grey": GREY}, SIZES2, ["Stationery. More stationery than staff.", "Doors that swing open on a slope."], big=True, heavy=True, acc=BRASS)
family("coffee_machine_v", "Coffee machine", "office", "small", (0.3, 0.35, 0.38),
       lambda w, d, h, c, a: [B((w, h, d * 0.6), (0, h / 2, -d * 0.2), c), B((w * 0.8, 0.02, d * 0.4), (0, 0.01, d * 0.3), BLACK), C(0.03, 0.06, (0, h * 0.5, d * 0.25), a), C(0.04, 0.1, (0, 0.07, d * 0.3), CREAM)],
       {"black": BLACK, "steel": STEEL, "red": RED, "cream": CREAM}, [("", 1.0, {}), ("pod", 0.8, {}), ("bean-to-cup", 1.3, {})], ["Descale light on since the spring.", "Makes a noise like a small train."], fragile=True, acc=STEEL)
family("mug_tree", "Mug tree", "office", "small", (0.22, 0.22, 0.34),
       lambda w, d, h, c, a: [C(w * 0.4, 0.02, (0, 0.01, 0), c), C(0.012, h, (0, h / 2, 0), c)] + [C(0.04, 0.08, (sx * 0.08, h * 0.5 + sz * 0.1, sz * 0.08), [SAGE, TERRA, MUSTARD, BLUE][(sx + 1) + (sz + 1) // 2]) for sx in (-1, 1) for sz in (-1, 1)],
       pick(WOODS, 3) | {"steel": STEEL}, ONE, ["Six mugs. One is somebody's and everyone knows.", "WORLD'S OKAYEST BOSS, chipped."], fragile=True)
family("folder_stack", "Folder stack", "office", "small", (0.3, 0.34, 0.22),
       lambda w, d, h, c, a: [B((w, h * 0.3, d), (0, h * 0.15, 0), c), B((w * 0.95, h * 0.3, d), (0.01, h * 0.45, 0.01), a), B((w, h * 0.3, d * 0.95), (-0.01, h * 0.75, 0), WHITE)] + [B((0.04, 0.02, 0.004), (w * 0.3, h * (0.15 + i * 0.3), d * 0.5), WHITE) for i in range(3)],
       pick(WAYS, 6), SIZES2, ["Invoices, in an order only one person understood.", "Lever arch. Mind the fingers."])
family("desk_fan", "Desk fan", "office", "small", (0.3, 0.14, 0.38),
       lambda w, d, h, c, a: [C(0.08, 0.02, (0, 0.01, 0), c), C(0.015, h * 0.4, (0, h * 0.25, 0), c), C(w * 0.5, 0.03, (0, h * 0.7, 0), a, (1.57, 0, 0)), C(0.04, 0.06, (0, h * 0.7, 0), c, (1.57, 0, 0))],
       {"white": WHITE, "black": BLACK, "steel": STEEL, "sage": SAGE}, ONE, ["Rattles on the top setting.", "Blows the paperwork around the room. The best bit."], acc=GREY)
family("heater", "Heater", "office", "floor", (0.5, 0.2, 0.6),
       lambda w, d, h, c, a: [B((w, h, d), (0, h / 2, 0), c)] + [B((0.03, h * 0.85, d * 1.02), (-w * 0.4 + i * w * 0.08, h * 0.5, 0), c) for i in range(11)] + [C(0.03, 0.02, (w * 0.45, h * 0.9, d * 0.5), a, (1.57, 0, 0))] + [C(0.03, 0.02, (sx * w * 0.4, 0.03, sz * d * 0.4), BLACK, (1.57, 0, 0)) for sx in (-1, 1) for sz in (-1, 1)],
       {"white": WHITE, "grey": GREY, "black": BLACK}, ONE, ["Trips the fuse when the kettle is on.", "Under the desk, on the feet of the cold one."], heavy=True, acc=BLACK)
family("office_kettle", "Office kettle", "office", "small", (0.2, 0.16, 0.24),
       lambda w, d, h, c, a: [C(w * 0.45, h * 0.85, (0, h * 0.42, 0), c), C(0.012, 0.1, (w * 0.45, h * 0.8, 0), c, (0, 0, -1.0)), B((0.025, h * 0.5, 0.025), (-w * 0.5, h * 0.5, 0), a), B((w * 0.2, 0.01, 0.006), (0, h * 0.5, w * 0.45), GLASS)],
       pick(WAYS, 5) | {"steel": STEEL}, ONE, ["Limescale like a coral reef.", "Boils for a tea round of eleven."], acc=BLACK)
family("office_trolley", "Trolley", "office", "floor", (0.6, 0.4, 0.8),
       lambda w, d, h, c, a: [B((w, 0.02, d), (0, h - 0.01, 0), c), B((w, 0.02, d), (0, h * 0.5, 0), c)] + [C(0.01, h, (sx * (w / 2 - 0.03), h / 2, sz * (d / 2 - 0.03)), c) for sx in (-1, 1) for sz in (-1, 1)] + [C(0.04, 0.02, (sx * (w / 2 - 0.05), 0.04, sz * (d / 2 - 0.04)), BLACK, (1.57, 0, 0)) for sx in (-1, 1) for sz in (-1, 1)] + [B((0.3, 0.2, 0.25), (-0.1, h + 0.1, 0), KRAFT), B((0.2, 0.12, 0.3), (0.15, h * 0.56, 0), a)],
       {"steel": STEEL, "black": BLACK, "grey": GREY}, ONE, ["The mail trolley. Pushes left.", "Squeaks announce it two rooms away."], big=True, acc=WHITE)
family("locker", "Locker", "office", "floor", (0.4, 0.5, 1.8),
       lambda w, d, h, c, a: [B((w, h, d), (0, h / 2, 0), c), B((w * 0.9, h * 0.95, 0.01), (0, h / 2, d * 0.5), c), B((0.03, 0.08, 0.02), (w * 0.35, h * 0.55, d * 0.52), a)] + [B((w * 0.6, 0.008, 0.012), (0, h * (0.8 + i * 0.03), d * 0.51), BLACK) for i in range(4)],
       {"grey": GREY, "sage": SAGE, "blue": BLUE, "red": RED, "cream": CREAM}, [("", 1.0, {}), ("double", 1.0, {})], ["A padlock nobody has the key for.", "Trainers inside. Smell of trainers outside."], big=True, heavy=True, acc=STEEL)
family("notice_board", "Notice board", "office", "hang", (0.9, 0.04, 0.6),
       lambda w, d, h, c, a: [B((w, h, d), (0, h / 2, 0), c), B((w * 0.94, h * 0.9, 0.01), (0, h / 2, d * 0.55), a)] + [B((0.12, 0.16, 0.004), (-0.3 + i * 0.2, h * (0.5 + 0.1 * (i % 2)), d * 0.6), [WHITE, MUSTARD, CREAM, ROSE][i]) for i in range(4)],
       pick(WOODS, 3), ONE, ["Fire drill. Bake sale. Lost cat. Found cat.", "Out of date by exactly one month."], acc=SAGE)
family("reception_sign", "Reception sign", "office", "small", (0.4, 0.08, 0.2),
       lambda w, d, h, c, a: [B((w, h, d), (0, h / 2, 0), c, (-0.3, 0, 0)), B((w * 0.8, h * 0.4, 0.004), (0, h * 0.55, d * 0.52), WHITE, (-0.3, 0, 0))],
       pick(WOODS, 3) | {"brass": BRASS, "black": BLACK}, ONE, ["RING FOR ATTENTION. There is no bell.", "The company name, one letter peeling."])
family("projector", "Projector", "office", "small", (0.3, 0.24, 0.1),
       lambda w, d, h, c, a: [B((w, h, d), (0, h / 2, 0), c), C(0.03, 0.03, (0.08, h * 0.5, d * 0.5), a, (1.57, 0, 0)), S(0.008, (-0.1, h + 0.004, 0), GREEN)],
       {"white": WHITE, "black": BLACK, "grey": GREY}, ONE, ["Finds the one cable it does not like.", "Fifteen minutes of every meeting, warming up."], fragile=True, acc=GLASS)
family("office_speaker", "Conference speaker", "office", "small", (0.2, 0.2, 0.06),
       lambda w, d, h, c, a: [C(w * 0.5, h, (0, h / 2, 0), c), C(0.012, 0.004, (0, h + 0.002, 0), a), B((0.03, 0.004, 0.03), (0.06, h + 0.002, 0), RED)],
       {"black": BLACK, "grey": GREY}, ONE, ["Everyone talks to it. Nobody hears.", "Muted. Still muted. Always muted."], fragile=True, acc=GREEN)
family("stapler_set", "Stapler and hole punch", "office", "small", (0.24, 0.12, 0.08),
       lambda w, d, h, c, a: [B((0.14, 0.03, 0.04), (-0.05, 0.015, 0), c), B((0.14, 0.025, 0.035), (-0.05, 0.045, 0), c, (0, 0, 0.12)), B((0.08, 0.06, 0.08), (0.08, 0.03, 0), a), B((0.04, 0.015, 0.02), (0.08, 0.07, 0), STEEL)],
       {"black": BLACK, "red": RED, "sage": SAGE, "steel": STEEL}, ONE, ["Out of staples. Full of confetti.", "Punches two holes, one in the wrong place."], acc=GREY)
family("dispatch_scale", "Parcel scale", "office", "small", (0.3, 0.3, 0.12),
       lambda w, d, h, c, a: [B((w, h * 0.5, d), (0, h * 0.25, 0), c), B((w * 0.8, 0.02, d * 0.8), (0, h * 0.6, 0), STEEL), B((0.08, 0.03, 0.02), (0, h * 0.4, d * 0.5), a)],
       {"grey": GREY, "black": BLACK, "white": WHITE}, ONE, ["Weighs the post and the cat.", "Set to grams. Nobody thinks in grams."], acc=GREEN)
family("globe_office", "Office globe", "office", "small", (0.26, 0.26, 0.36),
       lambda w, d, h, c, a: [C(w * 0.3, 0.02, (0, 0.01, 0), a), C(0.01, h * 0.25, (0, h * 0.15, 0), a), S(w * 0.45, (0, h * 0.62, 0), c), B((0.01, h * 0.55, 0.01), (w * 0.4, h * 0.62, 0), a, (0, 0, 0.4))],
       {"blue": BLUE, "antique": KRAFT, "black": BLACK}, ONE, ["Points at the client that never paid.", "A bar inside. Empty, of course."], fragile=True, acc=BRASS)
family("umbrella_stand", "Umbrella stand", "office", "floor", (0.22, 0.22, 0.85),
       lambda w, d, h, c, a: [C(w * 0.5, h * 0.7, (0, h * 0.35, 0), c), C(0.012, h * 0.9, (0.03, h * 0.55, 0.02), BLACK, (0.1, 0, 0.1)), C(0.012, h * 0.8, (-0.03, h * 0.5, -0.02), a, (-0.1, 0, -0.1)), S(0.02, (0.06, h * 0.98, 0.05), WALNUT)],
       METALS | {"ceramic": CREAM}, ONE, ["Three umbrellas, none of them yours.", "Drips onto the good floor."], acc=RED)
family("desk_calendar", "Desk calendar", "office", "small", (0.18, 0.1, 0.14),
       lambda w, d, h, c, a: [B((w, h, 0.01), (0, h / 2, -0.04), c, (0.4, 0, 0)), B((w, h, 0.01), (0, h / 2, 0.04), c, (-0.4, 0, 0)), B((w * 0.8, h * 0.7, 0.004), (0, h * 0.55, 0.06), WHITE, (-0.4, 0, 0)), B((w * 0.3, h * 0.2, 0.005), (0, h * 0.5, 0.065), a, (-0.4, 0, 0))],
       pick(WAYS, 5), ONE, ["Still on March.", "A dog for every month. Mostly spaniels."], acc=RED)

# ----------------------------------------------------------- generation
ROOM_FILES = ["kitchen", "bathroom", "bedroom", "living", "loft", "shed", "office"]


def slug(text):
    out = "".join(ch if ch.isalnum() else "_" for ch in text.lower())
    while "__" in out:
        out = out.replace("__", "_")
    return out.strip("_")


def make_items():
    rooms = {r: {"items": {}, "props": {}} for r in ROOM_FILES}
    for fam in FAMILIES:
        combos = list(itertools.product(fam["variants"], fam["ways"].items()))
        # Cap a family at twelve, keeping every variant and spreading the colours.
        if len(combos) > 12:
            keep = []
            ways = list(fam["ways"].items())
            for vi, variant in enumerate(fam["variants"]):
                for k in range(max(1, 12 // len(fam["variants"]))):
                    keep.append((variant, ways[(vi + k * 2) % len(ways)]))
            combos = keep[:12]
        for (suffix, scale, extra), (way_name, way_hex) in combos:
            w, d, h = (v * scale for v in fam["size"])
            if extra.get("swap"):
                w, h = h, w
            parts = fam["build"](w, d, h, way_hex, fam["acc"])
            name_bits = [fam["name"]]
            if suffix:
                if suffix in ("pair of", "stack of", "family of"):
                    name_bits = [suffix.capitalize() + " " + fam["name"].lower() + ("s" if not fam["name"].endswith("s") else "")]
                else:
                    name_bits.append(suffix)
            name = ", ".join(name_bits)
            name = "%s (%s)" % (name, way_name)
            item_id = slug("%s_%s_%s" % (fam["id"], suffix, way_name))
            flavor = rng.choice(fam["flavors"]).replace("{way}", way_name).replace("{variant}", suffix or "plain")
            big = fam["big"] or max(w, d) > 1.0 or h > 1.1
            defn = {
                "name": name, "model": "proc:" + item_id,
                "w": round(w, 3), "d": round(d, 3), "h": round(h, 3),
                "mount": fam["mount"], "room": fam["room"], "flavor": flavor,
                "family": fam["id"], "variant": (suffix or "plain"), "way": way_name, "way_hex": way_hex, "scale": round(scale, 3),
            }
            if fam["mount"] == "small" and big:
                defn["mount"] = "floor"
            if fam["fragile"]:
                defn["fragile"] = True
            if big:
                defn["nobox"] = True
            if fam["heavy"] or (big and w * d * h > 0.45):
                defn["heavy"] = True
            if fam["bulky"] or (big and max(w, d) > 1.2):
                defn["bulky"] = True
            rooms[fam["room"]]["items"][item_id] = defn
            rooms[fam["room"]]["props"][item_id] = parts
    return rooms


def write_docs(rooms):
    total = sum(len(r["items"]) for r in rooms.values())
    lines = ["# The big catalogue", "",
             "%d household and office pieces in `data/items/*.json`, generated by `tools/gen_items.py` from %d families: a shape, a few colour ways, a few named or sized variants, a line each. The game loads every file in that folder (the team can add their own in the same format), builds each model from its primitive list, and draws on them for house moves, the client's own furniture, and the clutter in offices and shops." % (total, len(FAMILIES)),
             "",
             "## Format", "",
             "```json", '{"items": {"mug_stripe_sage": {"name": "Mug, stripe (sage)", "model": "proc:mug_stripe_sage", "w": 0.09, "d": 0.09, "h": 0.1, "mount": "small", "room": "kitchen", "flavor": "...", "fragile": true}},',
             ' "props": {"mug_stripe_sage": [{"t": "cyl", "s": [0.04, 0.1], "p": [0, 0.05, 0], "c": "8FA882"}, {"t": "box", "s": [0.03, 0.05, 0.015], "p": [0.05, 0.055, 0], "c": "8FA882"}]}}', "```", "",
             "- **items**: `name`, `model` (`proc:<id>`, the same id as the props entry), `w`/`d`/`h` in metres, `mount` (`floor` stands on the floor, `small` sits on things, `hang` goes on a wall), `room` (kitchen, bathroom, bedroom, living, loft, shed, office), `flavor` (one line), and the box rules: `fragile`, `nobox` (too big for a box, wrapped and carried as itself), `heavy`, `bulky`.",
             "- **props**: a list of parts. `t` is `box`, `cyl` or `sph`; `s` is the size (box: w, h, d; cyl: radius, height; sph: radius); `p` is the part's centre with y up and the origin at the floor under the piece's middle; `c` is a hex colour; `r` an optional rotation in radians. Keep a piece inside its `w`/`d`/`h` and give it at least two parts.",
             "- Check a file with `python3 tools/check_items.py data/items/<file>.json`.",
             "- Files named `team_*.json` in the same folder are the team's own hand-authored pieces (ids prefixed `kit_`, `bth_`, `bed_`, `liv_`, `loft_`, `shed_`, `off_`); see `docs/ADDITIONS_README.md`. They are not touched by the generator.",
             "",
             "## Real models for a family (GLB)", "",
             "A piece builds from its primitive list unless a Blender model for it exists in `assets/models/`: `hh_cat_<family>_<variant>.glb` first, then `hh_cat_<family>.glb` (`family` and `variant` are fields on every generated item; a variant is `plain` when unnamed, else the suffix with spaces as underscores, e.g. `two_cup`). The model is built like the household ones in `tools/build_household.py`: Z-up in Blender, front toward -Y, origin at the floor centre, sized to the family's base `w`/`d`/`h` (the game scales it by the item's `scale` field for sized variants), exported with `export_yup=True`. Meshes whose names start with `way_` are recoloured to the item's colour way (`way_hex`); every other mesh keeps its own material. Keep it under seven materials. Nothing else changes: the item's data, box rules and line stay as they are.",
             "", "## Counts by room", "", "| Room | Pieces | Families |", "| --- | --- | --- |"]
    for room in ROOM_FILES:
        fams = {v["family"] for v in rooms[room]["items"].values()}
        lines.append("| %s | %d | %d |" % (room.capitalize(), len(rooms[room]["items"]), len(fams)))
    lines += ["", "## Families", "", "| Room | Family | Mount | Variants | Example |", "| --- | --- | --- | --- | --- |"]
    for fam in FAMILIES:
        members = [v for v in rooms[fam["room"]]["items"].values() if v["family"] == fam["id"]]
        lines.append("| %s | %s | %s | %d | %s |" % (fam["room"], fam["name"], fam["mount"], len(members), members[0]["name"] if members else ""))
    with open(DOC, "w") as f:
        f.write("\n".join(lines) + "\n")
    return total


def main():
    os.makedirs(OUT, exist_ok=True)
    rooms = make_items()
    for room in ROOM_FILES:
        path = os.path.join(OUT, room + ".json")
        with open(path, "w") as f:
            json.dump(rooms[room], f, separators=(",", ":"))
    total = write_docs(rooms)
    print("wrote %d items in %d families" % (total, len(FAMILIES)))


if __name__ == "__main__":
    main()
