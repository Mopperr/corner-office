"""List Design parts whose names hit Props.PART_TEXTURES (props.gd) -- notes only.
    python3 texture_hook_scan.py batch7 batch8 ...   -> prints JSON {batch: {family: [hooked parts]}}"""
import json, os, struct, sys
HERE = os.path.dirname(os.path.abspath(__file__)); FAM = os.path.dirname(os.path.dirname(os.path.dirname(HERE)))
CFG = json.load(open(os.path.join(HERE, "validate_design_config_b3_6.json")))
HOOK = {"cushion": "fabric_linen", "throw_cushion": "velvet", "pillow": "fabric_linen", "mattress": "fabric_linen",
        "duvet": "fabric_linen", "towel": "fabric_linen", "saddle": "leather", "strap": "leather", "trunk": "leather",
        "rug": "rug_kilim", "mat": "rug_kilim", "top": "oak_floor", "splashback": "kitchen_tile",
        "tray": "brushed_steel", "box": "cardboard", "soil": "concrete"}
def scan(batch):
    out = {}
    for fid in CFG[batch]:
        p = os.path.join(FAM, batch, "hh_cat_%s.glb" % fid)
        if not os.path.exists(p): continue
        b = open(p, "rb").read(); jl = struct.unpack("<I", b[12:16])[0]; j = json.loads(b[20:20 + jl])
        hits = sorted({"%s->%s" % (n["name"].lower().rstrip("0123456789._"), HOOK[n["name"].lower().rstrip("0123456789._")])
                       for n in j["nodes"] if "mesh" in n and n.get("name", "").lower().rstrip("0123456789._") in HOOK})
        if hits: out[fid] = hits
    return out
if __name__ == "__main__":
    print(json.dumps({b: scan(b) for b in sys.argv[1:]}, indent=1))
