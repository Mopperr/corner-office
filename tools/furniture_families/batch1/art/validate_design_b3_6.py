"""Batches 3-6 wrapper around validate_design.py (which stays untouched).

    python3 validate_design_b3_6.py batch3 batch4 batch5 batch6

Uses validate_design_config_b3_6.json (lists, front markers, and Design's extra first-colour-way aliases:
canvas -> card, aluminium -> steel, navy -> night, linen -> cream, velvet rose -> rose, velvet -> plum, wire -> steel).
"""
import importlib.util, json, os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
spec = importlib.util.spec_from_file_location("vd", os.path.join(HERE, "validate_design.py"))
vd = importlib.util.module_from_spec(spec); spec.loader.exec_module(vd)
CFG = json.load(open(os.path.join(HERE, "validate_design_config_b3_6.json")))
vd.CFG = CFG
vd.v.ALIAS.update(CFG["alias"])
if __name__ == "__main__":
    for b in (sys.argv[1:] or ["batch3", "batch4", "batch5", "batch6"]):
        vd.run(b)
