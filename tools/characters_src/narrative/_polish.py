# v2.3 (Oct 23): warmth + variety pass on reviews and banter. Exec'd by _build.py after
# _event_cast.py, before the JSON write. Every 'off' line stays warm: the customer always
# pays and leaves 3+ stars, so off = gentle, funny, appreciative. Fixes are exact-string
# swaps so a stale entry fails loudly instead of silently doing nothing.
import re as _re, collections as _co
REV_FIX = {
 # --- off (<50): reworded from complaint-ish / "This is.../I think..." openers / "Paying." tails
 "I think this is beans' cousin. Still paying!": "Beans' gentle cousin, this one. I like the whole family!",
 "Tastes like coffee heard about from a friend. Thanks anyway!": "Coffee, as told by a friend of a friend. Great story. Thank you!",
 "Bit bitter! It's like a pep talk from a grumpy uncle.": "Extra bold! Like a pep talk from my favourite grumpy uncle. Love him.",
 "This is mostly milk with a rumor of espresso. Cute!": "Milk with a whispered rumor of espresso. I love a good rumor!",
 "Lukewarm latte, but warm heart. Here you go.": "Cozy-warm, not hot-warm. My hands are happy. Here you go.",
 "I think the milk and coffee haven't been introduced yet.": "Milk and coffee are still getting to know each other. Sweet first date!",
 "Flat as a packed box. Still drinking it. Still paying!": "Flat as a packed box, and I love a good box. Sipping happily!",
 "This is sugar water that once saw a lemon. Lovely try!": "Sugar water with lemony daydreams. Sweetest daydream I've had!",
 "Mostly water. Very hydrating, though!": "So refreshing it's practically a spa day. Hydrated and happy!",
 "So sour I can hear colors. Paying anyway!": "So sour I can hear colors! What a ride. Thank you!",
 "I think the lemon is still in the bag. Sweet effort.": "The lemon's playing hide-and-seek. I'll keep sipping till I find it!",
 "This is more red lemonade than pink. Very dramatic! Paying!": "Ruby-red instead of pink. Very dramatic! I'm a fan of drama.",
 "I think the berries had a party and invited no lemons. Cute!": "The berries threw a party! Lemons can come next time. Fun!",
 "This is hot tea pretending to be cold. Brave little drink! Paying.": "A warm iced tea! Brave little drink. Cozy on a gray day.",
 "The ice melted out of politeness. Still paying, friend!": "The ice melted out of politeness. Such good manners, this cup!",
 "I think the strawberries are still napping in the bowl. Cute! Paying.": "Soft and sweet. The strawberries must be napping. Sweet dreams!",
 "It's a strawberry smoothie that got lost. I love it anyway.": "A strawberry smoothie took a wrong turn and found me. Lucky me!",
 "This is toothpaste's sunny cousin. Fun! Paying.": "Minty fresh! My smile is extra sparkly now. Fun!",
 "I think the mint stayed by the pond. Still sweet effort!": "The mint's off visiting the pond. Still sweet and sunny!",
 "This espresso is... very relaxed. On vacation, maybe. Paying!": "A very relaxed espresso. On vacation, maybe. I could use one too!",
 "It's a long shot. Like, a really long shot. Very hydrating!": "A long shot! A really long shot. More espresso to love.",
 "I'm drinking a very sweet candle. Delightful! Paying.": "Like sipping a sweet candle. My whole day smells nice now!",
 "The foam ran off to find a better book. Still paying!": "The foam slipped off to read a book. Can't blame it. Cozy cup!",
 "This is hot chocolate with a coffee rumor. Delicious rumor! Paying.": "Hot chocolate wearing a little coffee hat. Adorable and delicious!",
 "Chocolate forgot to come. It's just a latte with hope. Still lovely!": "The chocolate's fashionably late. Meanwhile, a hopeful latte. Lovely!",
 "This is an ice cube with coffee dreams. Paying!": "An ice cube with big coffee dreams. I believe in it!",
 "Not cold. A warm iced coffee! Bold invention. Thank you!": "A warm iced coffee! Bold invention. Patent pending!",
 "Mostly ice! I'll wait for the melt. Patient sips.": "So much ice! Built-in refills as it melts. Clever!",
 "This tastes like a vanilla candle's first try. Sweet! Paying.": "A vanilla candle's first draft. Smells like a hug!",
 "I think the vanilla got lost in the milk. Still warm, still kind.": "The vanilla's hiding in the milk. Still warm, still kind.",
 "This is... several seasons at once. A whole year! Paying.": "Several seasons at once. A whole year in one cup!",
 "Well, it's wet and it's warm-ish. Here's a little extra for trying.": "Warm-ish and made with love. Here's a little extra for trying, sweetie.",
 "A bit weak, but so are my knees. Cheers, friend.": "Gentle, the way my knees like it. Cheers, friend.",
 "Not much sparkle, but I'll bring my own!": "Soft sparkle today. I brought my own, so we're both glowing!",
 "Needs more lemon. I'll make you a chart. Free!": "One more lemon and it's gold-star! I'll make you a chart. Free!",
 "Lukewarm. Laggy. Still pressing 'like'. Paying!": "Bit of input lag on the chill. Still smashing 'like'!",
 # --- okay (50-79): soften "Bit/A touch/Too much" openers, de-dupe the shared ice line
 "A touch thin, but it's warm and honest.": "Gentle and honest. Warm hands, warm heart.",
 "Bit milky for me. Still very cozy.": "Extra milky, extra cozy. I'll take it!",
 "Too much ice, but what's there is tasty!": None,  # duplicated: handled per product below
 "Bit thin, but it's got spirit.": "Light and lively. It's got spirit!",
 "Bit heavy on the cocoa. A chocolate mustache!": "Cocoa-forward! I'm wearing a chocolate mustache now.",
 # --- great (80+): fewer "Tastes like..." openers
 "Not too bitter, not too thin. Just right.": "Smooth, warm, just right. Goldilocks would move in.",
 "Tastes like a summer afternoon. Wow.": "A summer afternoon in a cup. Wow.",
 "Tastes like a snow day. Thank you!": "A snow day in a mug. Thank you!",
 # --- round 2: vary "A little/Little" openers, drop "anyway"
 "Little watery, but refreshing.": "Light and breezy. Very refreshing!",
 "Little bitter at the edge. I kind of like it.": "A bold little edge. I kind of like it.",
 "Little bitter at the end. Wakes me right up.": "Ends with a kick. Wakes me right up!",
 "A little watery at the end. Still chill!": "Mellows out at the end. Still chill!",
 "A little off-beat, but jazz is too. Love it.": "Off-beat, like all the best jazz. Love it.",
 "Pale pink. Shy pink. I like it anyway.": "Pale pink. Shy pink. I like shy.",
}
REV_FIX_BY_PRODUCT = {("mint_lemonade","Too much ice, but what's there is tasty!"): "Extra ice! A frosty little adventure. Tasty!",
                      ("iced_coffee","Too much ice, but what's there is tasty!"): "Lots of ice, lots of chill. What's there is tasty!"}
BANTER_FIX = {  # (exchange id, line index) -> (old, new): trims repeated closers
 ("banter_05",2): ("Thanks, Dottie.", "You're the best, Dottie."),
 ("banter_47",3): ("Respect, Dottie.", "Certified legend, Dottie."),
 ("banter_48",3): ("Write that one down.", "Poem material, right there."),
 ("banter_50",3): ("I write it all down.", "Every word goes in the notebook."),
 ("banter_28",3): ("...Thanks?", "...I'll take it as a compliment."),
}

def _all_reviews(rv):
    for p,t in rv["by_product"].items():
        for tier,ls in t.items():
            for i,l in enumerate(ls): yield ("bp",p,tier,i,l)
    for c,t in rv["per_customer"].items():
        for tier,l in t.items(): yield ("pc",c,tier,None,l)
    for c,m in rv["per_customer_product"].items():
        for p,t in m.items():
            for tier,l in t.items(): yield ("pcp",(c,p),tier,None,l)

def _stats(rv, bn):
    L=[x[-1] for x in _all_reviews(rv)]
    w=lambda s:_re.findall(r"[A-Za-z']+",s)
    op2=_co.Counter(' '.join(w(l)[:2]).lower() for l in L)
    tails=_co.Counter(_re.split(r"(?<=[.!?]) ",l)[-1] for l in L)
    fl=_co.Counter(w(e["lines"][0]["text"])[0].lower() for e in bn["exchanges"])
    last=_co.Counter(e["lines"][-1]["text"] for e in bn["exchanges"])
    return {"review_lines":len(L),
            "repeated_2word_openers(lines)":sum(v for v in op2.values() if v>1),
            "top_openers":op2.most_common(4),
            "this_is/i_think/tastes_like/bit_openers":sum(bool(_re.match(r"(This is|I think|Tastes like|Bit |A bit |Too much|Not |Mostly )",l)) for l in L),
            "paying_tails":sum(t.startswith(("Paying","Still paying")) for t in tails.elements()),
            "anyway":sum('anyway' in l.lower() for l in L),
            "complaint_words_in_off":sum(bool(_re.search(r"\b(lukewarm|watery|mostly|weak|bitter|forgot|not cold|got lost|laggy|wet)\b",x[-1],_re.I)) for x in _all_reviews(rv) if x[2]=="off"),
            "duplicate_review_lines":sum(v-1 for v in _co.Counter(L).values() if v>1),
            "banter_first_word_max":fl.most_common(1)[0]}

POLISH_BEFORE=_stats(reviews,banter)
_hit=set()
for kind,key,tier,i,l in list(_all_reviews(reviews)):
    new = REV_FIX_BY_PRODUCT.get((key,l)) if kind=="bp" else None
    if new is None: new = REV_FIX.get(l)
    if not new: continue
    _hit.add(l)
    if kind=="bp": reviews["by_product"][key][tier][i]=new
    elif kind=="pc": reviews["per_customer"][key][tier]=new
    else: reviews["per_customer_product"][key[0]][key[1]][tier]=new
_miss=[k for k in REV_FIX if k not in _hit]
assert not _miss, ("polish: stale review fixes", _miss)
_bx={e["id"]:e for e in banter["exchanges"]}
for (bid,j),(old,new) in BANTER_FIX.items():
    assert _bx[bid]["lines"][j]["text"]==old,(bid,j)
    _bx[bid]["lines"][j]["text"]=new
POLISH_AFTER=_stats(reviews,banter)
reviews.setdefault("_meta",{})["polish_note"]=("Oct 23 warmth pass: off lines are gentle, funny and appreciative (3+ stars, always pays); "
    "fewer 'This is/I think/Tastes like' openers and 'Paying.' tails. See bark_style_notes.md.")
print("polish before",POLISH_BEFORE); print("polish after ",POLISH_AFTER)
