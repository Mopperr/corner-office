"""Write ../../FINAL_art.md from VALIDATION.json, fit_log.json and readme_notes.json (recog / deviations keys)."""
import json, os
HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.dirname(os.path.dirname(HERE))
B = os.path.basename(OUT)
V = json.load(open(os.path.join(OUT, "VALIDATION.json")))
F = json.load(open(os.path.join(HERE, "fit_log.json")))
N = json.load(open(os.path.join(HERE, "readme_notes.json")))
fs = V["files"]
L = ["# FINAL - %s art share (%d families)" % (B, len(fs)), "", "Created by Andrew's Helpers (Grok Bots)", "",
     N["scope"], "",
     "| file | w x d x h (m) | max dev vs CSV | stretch to fit | KB | mats | way | front | recognisable as | result |",
     "|---|---|---|---|---|---|---|---|---|---|"]
for r in fs:
    s = r["size_m"]; st = max(F[r["family_id"]]["stretch_pct"], key=abs)
    fr = r["checks"].get("front")
    L.append("| %s | %.3f x %.3f x %.3f | %.2f%% | %+.1f%% | %.0f | %d | %s | %s | %s | **%s** |" % (
        r["file"], s["w"], s["d"], s["h"], r["max_size_deviation_pct"], st, r["size_bytes"] / 1024,
        len(r["materials"]), r["way_colour"]["actual"], {True: "PASS", False: "FAIL", None: "n/a"}.get(fr, "n/a"),
        N.get("recog", {}).get(r["family_id"], ""), "PASS" if r["pass"] else "FAIL"))
L += ["", "Validation: **%s** (%d/%d pass, see `VALIDATION.md`). Checks: GLB structure, size within 3%%, bottom-centre origin, front -Y (or back +Y for wall pieces), `way` = first colour-way, 3-7 matte untextured materials, no copper, no texture-hook part names, < 1 MB." % (
    "ALL PASS" if V["all_pass"] else "SOME FAIL", sum(r["pass"] for r in fs), len(fs)), "",
    "## Deviations and notes", ""]
L += ["- " + x for x in N.get("deviations", [])] or ["- none"]
L += ["", "Contact sheet: `%s_contact_art.png`. Scripts: `_build/art/` (build_families.py, validate.py, render_contact.py, contact_sheet.py, make_readme.py, make_final.py)." % B,
      "Add-only; nothing committed or pushed. Design Specialist's files and batch1/batch2 build scripts untouched."]
open(os.path.join(OUT, "FINAL_art.md"), "w").write("\n".join(L) + "\n")
print("wrote", os.path.join(OUT, "FINAL_art.md"))
