# Wren's haiku: hand-counted 5-7-5 table (Design: the napkin card shows a syllable chip per line).
# Sources keep " / " between lines for readability; haiku_store() writes them to JSON with "\n"
# between lines (and, for customer_event_lines.json, adds "lines": [3 strings] + "syllables": [5,7,5],
# because Design's mock draws one row per line). Every Wren " / " string in the data must be listed
# here, or the build stops. Counts are by hand (word-by-word breakdown below).
import json as _json, re as _re, copy as _copy

HAIKU = [
 # (where, lines, hand breakdown per line, before-text if rewritten)
 ("reviews.per_customer.wren.great + line_cust_wren_haiku_card_haiku_great (mock)",
  ["Warm between my palms", "a small sun I can hold close", "thank you, morning hands"],
  ["warm(1) be-tween(2) my(1) palms(1)", "a(1) small(1) sun(1) I(1) can(1) hold(1) close(1)", "thank(1) you(1) mor-ning(2) hands(1)"], None),
 ("reviews.per_customer.wren.okay + line_cust_wren_haiku_card_haiku_okay",
  ["Almost there, just like", "the first warm day of April.", "Still, I'm glad of it."],
  ["al-most(2) there(1) just(1) like(1)", "the(1) first(1) warm(1) day(1) of(1) A-pril(2)", "still(1) I'm(1) glad(1) of(1) it(1)"],
  "Almost there, like / the first warm day of April. / Still, I'm glad of it.  (4/7/5)"),
 ("reviews.per_customer.wren.off + line_cust_wren_haiku_card_haiku_off",
  ["Brave little cup, you", "tried your best and so did I.", "Here, for your effort."],
  ["brave(1) lit-tle(2) cup(1) you(1)", "tried(1) your(1) best(1) and(1) so(1) did(1) I(1)", "here(1) for(1) your(1) ef-fort(2)"], None),
 ("line_cust_wren_napkin_wall_shop_haiku (shop haiku, poem corner)",
  ["Warm cups, kind faces", "a corner where words can rest", "this place is a verse"],
  ["warm(1) cups(1) kind(1) fa-ces(2)", "a(1) cor-ner(2) where(1) words(1) can(1) rest(1)", "this(1) place(1) is(1) a(1) verse(1)"],
  "Warm cups, kind faces / a corner where words can rest / this place is a poem  (5/7/6: 'po-em' is 2)"),
 ("line_leave_shiftend_wren_1 (leave line)",
  ["The day folds itself", "like a napkin, soft and small.", "Until tomorrow."],
  ["the(1) day(1) folds(1) it-self(2)", "like(1) a(1) nap-kin(2) soft(1) and(1) small(1)", "un-til(2) to-mor-row(3)"], None),
 ("reviews.per_customer_product.wren.latte.great",
  ["Soft foam, like fresh snow", "a little heart drawn in white", "I'll keep this moment"],
  ["soft(1) foam(1) like(1) fresh(1) snow(1)", "a(1) lit-tle(2) heart(1) drawn(1) in(1) white(1)", "I'll(1) keep(1) this(1) mo-ment(2)"],
  "Foam like fresh snow / a heart drawn in the white / I'll keep this moment  (4/6/5)"),
 ("reviews.per_customer_product.wren.honey_lavender_lemonade.great (steam_page + marketing quote)",
  ["Lavender evening", "honey settles like the dusk", "lemon, the first star"],
  ["lav-en-der(3) eve-ning(2)", "hon-ey(2) set-tles(2) like(1) the(1) dusk(1)", "lem-on(2) the(1) first(1) star(1)"], None),
 ("reviews.per_customer_product.wren.black_coffee.great",
  ["Dark and plain and warm", "nothing extra, nothing missed", "the morning, poured out"],
  ["dark(1) and(1) plain(1) and(1) warm(1)", "noth-ing(2) ex-tra(2) noth-ing(2) missed(1)", "the(1) mor-ning(2) poured(1) out(1)"],
  "Dark, plain, and warm / nothing extra, nothing missed / the morning, poured out  (4/7/5)"),
 ("reviews.per_customer_product.wren.black_coffee.off",
  ["Thin as early light", "still, it found my hands. Thank you", "for pouring the dawn"],
  ["thin(1) as(1) ear-ly(2) light(1)", "still(1) it(1) found(1) my(1) hands(1) thank(1) you(1)", "for(1) pour-ing(2) the(1) dawn(1)"], None),
]
def _cnt(b): return sum(int(x) for x in _re.findall(r"\((\d)\)", b))
for _w, _ls, _bd, _bf in HAIKU:
    assert len(_ls) == 3 and [_cnt(b) for b in _bd] == [5, 7, 5], ("haiku not 5-7-5", _w, [_cnt(b) for b in _bd])
_SLASH = {" / ".join(ls): ls for _, ls, _, _ in HAIKU}
_seen = set()

def haiku_store(obj, add_fields=False):
    """Deep copy; every Wren haiku 'a / b / c' becomes 'a\\nb\\nc'. Unknown 3-part slash strings stop the build."""
    o = _copy.deepcopy(obj)
    def fix(x):
        if isinstance(x, dict):
            for k, v in list(x.items()):
                if isinstance(v, str) and v in _SLASH:
                    _seen.add(v); x[k] = "\n".join(_SLASH[v])
                    if add_fields and k == "text":
                        x["lines"] = list(_SLASH[v]); x["syllables"] = [5, 7, 5]
                else: fix(v)
        elif isinstance(x, list):
            for i, v in enumerate(x):
                if isinstance(v, str) and v in _SLASH: _seen.add(v); x[i] = "\n".join(_SLASH[v])
                else: fix(v)
    fix(o)
    return o

def haiku_report():
    missing = [k for k in _SLASH if k not in _seen]
    assert not missing, ("haiku table entry not found in any data file (stale?)", missing)
    md = ["# Wren's haiku (5-7-5 check)", "",
          "Built by `_haiku.py` (run via `_build.py`). Every haiku Wren says in the narrative data, hand-counted word by word.",
          "Storage: JSON strings use `\\n` between the 3 lines. `customer_event_lines.json` haiku lines also carry `lines` (array of 3) and `syllables` ([5,7,5]) for the napkin card, which draws one row per line with a count chip.",
          "Note for Design: `assets/ui_mocks/build_shop_mocks.py` still splits on `\" / \"` (lines 516, 645, 686); switch to `.split('\\n')` or read `lines`.", "",
          "| # | Where | Haiku | Counts | Changed? |", "|---|---|---|---|---|"]
    for i, (w, ls, bd, bf) in enumerate(HAIKU, 1):
        md.append(f"| {i} | {w} | {' / '.join(ls)} | {'/'.join(str(_cnt(b)) for b in bd)} | {'before: ' + bf if bf else 'no (already 5-7-5)'} |")
    md += ["", "## Hand counts", ""]
    for i, (w, ls, bd, bf) in enumerate(HAIKU, 1):
        md.append(f"**{i}. {w}**")
        md += [f"- {l}: {b} = {_cnt(b)}" for l, b in zip(ls, bd)]
        md.append("")
    md += ["Also checked, not haiku (no change): idle thought \"Five, seven, five...\", order lines, banter lines, sip-count and napkin-tip lines.",
           "Ambiguous words avoided: 'poem' (1 or 2) was swapped for 'verse'. 'evening' is counted as 2 (eve-ning), the common reading; it is the approved marketing quote, so it stays."]
    open(f"{D}/wren_haiku.md", "w").write("\n".join(md) + "\n")
    _json.dump({"_meta": {"source": "_haiku.py", "storage": "lines joined with \\n in data files", "rule": "5-7-5, hand-counted"},
                "haiku": [{"where": w, "lines": ls, "syllables": [_cnt(b) for b in bd], "hand_count": bd, "before": bf} for w, ls, bd, bf in HAIKU]},
               open(f"{D}/wren_haiku.json", "w"), indent=2, ensure_ascii=False)
