#!/usr/bin/env python3
"""Author the L7 to L22 places, jobs and drives into the data files.

Idempotent: every record it writes carries "authored": "gen_levels", and a
rerun replaces those records. Plans come from a row grid (depth, [(kind, w)])
so every floor tiles its footprint exactly.
"""
import json

ROOT = "."


def load(p):
    return json.load(open(f"{ROOT}/{p}"))


def save(p, d):
    json.dump(d, open(f"{ROOT}/{p}", "w"), indent=1)
    open(f"{ROOT}/{p}", "a").write("\n")


def grid(rows):
    """rows: [(depth, [(kind, w, name), ...])] -> rooms list, with unique ids."""
    rooms, z, seen = [], 0, {}
    for depth, cells in rows:
        x = 0
        for kind, w, name in cells:
            seen[kind] = seen.get(kind, 0) + 1
            rid = kind if seen[kind] == 1 else f"{kind}{seen[kind]}"
            rooms.append({"id": rid, "name": name, "x": x, "z": z, "w": w, "d": depth})
            x += w
        z += depth
    return rooms


PLANS = {
 "dentist": dict(w=11, d=9, kind="shop", style="render", floors=[
   {"name": "Surgery", "rooms": grid([
     (3, [("hall", 3, "Entrance"), ("reception", 5, "Reception"), ("office", 3, "Records")]),
     (3, [("washroom", 3, "Washroom"), ("seating", 5, "Waiting room"), ("store", 3, "Supplies")]),
     (3, [("studio", 4, "Surgery one"), ("studio", 4, "Surgery two"), ("kitchenette", 3, "Staff kitchen")]),
   ])}], fixtures=[]),
 "architect": dict(w=12, d=9, kind="shop", style="render", floors=[
   {"name": "Studio", "rooms": grid([
     (3, [("hall", 3, "Entrance"), ("reception", 5, "Reception"), ("office", 4, "Partner's office")]),
     (6, [("studio", 8, "Drawing studio"), ("display", 4, "Model room")]),
   ]), "stairs": [1.5, 1.6]},
   {"name": "Upstairs", "rooms": grid([
     (3, [("landing", 3, "Landing"), ("office", 5, "Meeting room"), ("store", 4, "Plan chest")]),
     (6, [("studio", 6, "Studio two"), ("kitchenette", 3, "Kitchenette"), ("loo", 3, "Loo")]),
   ]), "stairs": [1.5, 1.6]}], fixtures=[]),
 "library": dict(w=13, d=10, kind="shop", style="brick", floors=[
   {"name": "Library", "rooms": grid([
     (3, [("hall", 3, "Entrance"), ("reception", 6, "Issue desk"), ("seating", 4, "Reading room")]),
     (4, [("display", 5, "Fiction"), ("display", 4, "Reference"), ("display", 4, "Children's")]),
     (3, [("office", 4, "Librarian's office"), ("store", 5, "Stack room"), ("washroom", 4, "Washroom")]),
   ])}], fixtures=[]),
 "record": dict(w=9, d=8, kind="shop", style="brick", floors=[
   {"name": "Shop", "rooms": grid([
     (3, [("hall", 3, "Entrance"), ("shopfloor", 6, "Racks")]),
     (3, [("counter", 3, "Counter"), ("seating", 6, "Listening corner")]),
     (2, [("store", 4, "Stock"), ("office", 3, "Back office"), ("loo", 2, "Loo")]),
   ])}], fixtures=[]),
 "florist": dict(w=10, d=8, kind="shop", style="timber", floors=[
   {"name": "Greenhouse", "rooms": grid([
     (3, [("hall", 3, "Entrance"), ("shopfloor", 7, "Shop")]),
     (3, [("workbench", 4, "Potting bench"), ("display", 6, "Greenhouse")]),
     (2, [("coldstore", 3, "Cold room"), ("store", 4, "Pots"), ("washroom", 3, "Washroom")]),
   ])}], fixtures=[]),
 "theatre": dict(w=13, d=10, kind="shop", style="brick", floors=[
   {"name": "Backstage", "rooms": grid([
     (3, [("hall", 3, "Stage door"), ("workshop", 6, "Prop workshop"), ("store", 4, "Costume store")]),
     (4, [("display", 7, "Prop store"), ("studio", 6, "Rehearsal room")]),
     (3, [("office", 4, "Director's office"), ("staff", 5, "Green room"), ("washroom", 4, "Dressing room")]),
   ])}], fixtures=[]),
 "broker": dict(w=12, d=9, kind="shop", style="render", floors=[
   {"name": "Ground", "rooms": grid([
     (3, [("hall", 3, "Lobby"), ("reception", 5, "Reception"), ("office", 4, "Broker's office")]),
     (3, [("office", 4, "Deal room"), ("office", 4, "Junior desks"), ("kitchenette", 4, "Kitchen")]),
     (3, [("seating", 5, "Client lounge"), ("store", 4, "Files"), ("washroom", 3, "Washroom")]),
   ])}], fixtures=[]),
 "lodge": dict(w=13, d=10, kind="home", style="timber", floors=[
   {"name": "Lodge", "rooms": grid([
     (3, [("hall", 3, "Boot room"), ("lounge", 6, "Great room"), ("kitchen", 4, "Kitchen")]),
     (4, [("dining", 6, "Dining hall"), ("study", 4, "Snug"), ("utility", 3, "Drying room")]),
     (3, [("bedroom", 5, "Bunk room"), ("bathroom", 4, "Bathroom"), ("shed", 4, "Wood store")]),
   ]), "stairs": [1.5, 1.6]},
   {"name": "Upstairs", "rooms": grid([
     (3, [("landing", 3, "Landing"), ("bedroom", 5, "Owner's room"), ("bathroom", 5, "Bathroom")]),
     (7, [("bedroom", 7, "Guest room"), ("loft", 6, "Eaves")]),
   ]), "stairs": [1.5, 1.6]}], fixtures=[]),
 "warehouse": dict(w=14, d=10, kind="shop", style="brick", floors=[
   {"name": "Loading floor", "rooms": grid([
     (4, [("hall", 3, "Goods in"), ("shopfloor", 7, "Open floor"), ("workshop", 4, "Workshop")]),
     (6, [("store", 5, "Racking"), ("office", 5, "Foreman's office"), ("kitchenette", 4, "Mess room")]),
   ]), "stairs": [1.5, 2.0]},
   {"name": "Loft", "rooms": grid([
     (5, [("landing", 3, "Landing"), ("office", 7, "The loft office"), ("staff", 4, "Crew room")]),
     (5, [("seating", 6, "Lounge"), ("display", 4, "Showroom"), ("loo", 4, "Washroom")]),
   ]), "stairs": [1.5, 2.0]}], fixtures=[]),
 "glass": dict(w=16, d=12, kind="shop", style="render", floors=[
   {"name": "Suite", "rooms": grid([
     (3, [("hall", 4, "Lobby"), ("reception", 6, "Front desk"), ("seating", 6, "Lounge")]),
     (5, [("office", 5, "Pod one"), ("office", 5, "Pod two"), ("office", 6, "Pod three")]),
     (4, [("kitchenette", 5, "Kitchen"), ("washroom", 3, "Washroom"), ("store", 4, "Store"), ("studio", 4, "Phone booth")]),
   ]), "stairs": [2.0, 1.6]},
   {"name": "Skyline floor", "rooms": grid([
     (4, [("landing", 4, "Landing"), ("office", 8, "Boardroom"), ("office", 4, "Corner pod")]),
     (4, [("seating", 6, "Terrace lounge"), ("office", 5, "Quiet room"), ("staff", 5, "Helper's desk")]),
     (4, [("display", 6, "Gallery wall"), ("loo", 4, "Washroom"), ("kitchenette", 6, "Coffee bar")]),
   ]), "stairs": [2.0, 1.6]}], fixtures=[]),
 "corner": dict(w=18, d=14, kind="shop", style="render", floors=[
   {"name": "Ground", "rooms": grid([
     (4, [("hall", 4, "Atrium"), ("reception", 6, "Reception"), ("seating", 8, "Waiting lounge")]),
     (4, [("office", 4, "Dispatch"), ("office", 5, "Accounts"), ("office", 5, "Bookings"), ("store", 4, "Archive")]),
     (3, [("kitchenette", 5, "Kitchen"), ("staff", 5, "Crew room"), ("washroom", 4, "Washrooms"), ("display", 4, "Trophy wall")]),
     (3, [("workshop", 6, "Mail room"), ("store", 6, "Stores"), ("office", 6, "Server room")]),
   ]), "stairs": [2.0, 2.0]},
   {"name": "Top floor", "rooms": grid([
     (5, [("landing", 4, "Landing"), ("office", 8, "The corner office"), ("seating", 6, "Sunset lounge")]),
     (5, [("office", 6, "Boardroom"), ("office", 4, "Priya's desk"), ("office", 4, "Marge's desk"), ("studio", 4, "Map room")]),
     (4, [("kitchenette", 6, "Coffee bar"), ("loo", 4, "Washroom"), ("display", 8, "Gallery")]),
   ]), "stairs": [2.0, 2.0]}], fixtures=[]),
}

VENUES = {
 "dentist": {"name": "Hartley Dental", "music": "music_office_build", "ambience": "amb_l10_library_loop"},
 "architect": {"name": "Okonkwo & Partners", "music": "music_office_build", "ambience": "amb_l10_library_loop"},
 "library": {"name": "Mill Lane Library", "music": "music_act2_morning", "ambience": "amb_l10_library_loop"},
 "record": {"name": "Spindle Records", "music": "music_record_store", "ambience": "amb_l04_shop_clock_loop"},
 "florist": {"name": "Pemberton & Pemberton", "music": "music_act2_morning", "ambience": "amb_l14_greenhouse_loop"},
 "theatre": {"name": "The Alcazar Props", "music": "music_act3_loft", "ambience": "amb_l04_shop_clock_loop"},
 "broker": {"name": "Grayline Brokerage", "music": "music_office_build", "ambience": "amb_l10_library_loop"},
 "lodge": {"name": "Switchback Lodge", "music": "music_act1_home", "ambience": "amb_l20_lodge_loop"},
 "warehouse": {"name": "Brick Warehouse Loft", "music": "music_act3_loft", "ambience": "amb_l04_shop_clock_loop"},
 "glass": {"name": "Glass Co-Working Suite", "music": "music_office_build", "ambience": "amb_l10_library_loop"},
 "corner": {"name": "The Corner Office", "music": "music_act3_loft", "ambience": "amb_l10_library_loop"},
}

# Recipes stay within the truck: a wrapped piece costs three places, a heavy one, the rest six to a box.
JOBS = [
 dict(id="job_dentist", level="L7", venue="dentist", drive="dentist_run", unlock="job:job_ducks", title="Retiring Dentist",
      client="Dr. Ada Hartley", base=180, twist="fragile", mood='warm', brief='Thirty-five years of a surgery into eleven rooms by the park. The records cabinet is heavy and the mirrors are glass; the plants have names.', mentor_note="Doc's retiring. You know a thing or two about endings; tell him the next part's good.", why='Retiring after thirty-five years.', line='Retirement feels like being laid off, only on purpose.',
      recipe=[("filing_cabinet_grey", 1), ("office_plant_sage", 3), ("whiteboard_aluminium", 1), ("safe_black", 1), ("side_table_v_oak", 2),
              ("bar_stool_blue", 3), ("suitcase_tan", 2), ("mirror_round_small_steel", 2), ("bath_bin_steel", 2), ("wine_rack_oak", 1), ("picture_frame_oak", 2), ("crate_stack_plastic", 2)]),
 dict(id="job_architect", level="L9", venue="architect", drive="architect_rain", unlock="job:job_dentist", title="Chaotic Architect",
      client="Femi Okonkwo", base=210, twist="plain", mood='fussy', brief="Two drawing studios, a model room and a partner's office. The plan has been redrawn three times. Expect a fourth.", mentor_note='The architect will move the goalposts. You moved spreadsheets for a living. Adapt.', why='A bigger studio for a bigger practice.', line="I've redrawn it. Again. Just put things down where they make sense and I'll argue later.",
      recipe=[("filing_cabinet_steel", 2), ("whiteboard_oak", 2), ("office_plant_large_sage", 2), ("school_desk_oak", 3), ("side_table_v_walnut", 2),
              ("picture_v_oak", 2), ("crate_stack_oak", 3), ("bar_stool_sage", 2), ("suitcase_cabin_blue", 2), ("kitchen_clock_sage", 1), ("plant_pot_v_mustard", 3)]),
 dict(id="job_library", level="L10", venue="library", drive="library_day", unlock="job:job_architect", title="Library Move",
      client="Ms. Imogen Bly", base=240, twist="sets", mood='warm', brief="The whole branch to the new building: shelves, desks, the children's corner and crates of books by the hundred. Keep the sets together.", mentor_note='A library is a thousand small things that each belong somewhere. Take the time.', why='The old building is closing.', line="Mind the crates. Every one of those is somebody's winter.",
      recipe=[("kitchen_shelf_large_oak", 2), ("school_desk_pine", 4), ("crate_stack_oak", 4), ("picture_frame_pine", 3), ("side_table_v_pine", 2),
              ("office_plant_grey", 3), ("deck_chair_sage", 2), ("suitcase_sage", 2), ("dartboard_classic", 1), ("bath_mat_sage", 1)]),
 dict(id="job_record", level="L12", venue="record", drive="record_run", unlock="job:job_library", title="Indie Record Store",
      client="Theo Marsh", base=200, twist="fragile", mood='warm', brief='Racks, crates of records and a listening corner into the shop on the corner. The aquarium is heavier than it looks.', mentor_note="He'll ask your favourite record. Have an answer.", why='A shop with a window at last.', line="What's your favourite record? Don't say you don't have one. Everyone has one.",
      recipe=[("armchair_v_mustard", 1), ("crate_stack_oak", 2), ("loft_vinyl_wall_shelf", 2), ("school_desk_oak", 2), ("side_table_v_painted_sage", 2), ("bar_stool_rose", 2),
              ("picture_v_pine", 3), ("plant_pot_v_sage", 2), ("suitcase_rose", 1), ("dartboard_faded", 1), ("aquarium_black", 1)]),
 dict(id="job_florist", level="L14", venue="florist", drive="florist_run", unlock="job:job_record", title="Florist's Greenhouse",
      client="Rosa & Ray Pemberton", base=220, twist="fragile", mood='fussy', party=['adult', 'adult'], brief='Two flower shops becoming one greenhouse. Rosa wants the pots by colour, Ray wants them by size. Do not pick a side.', mentor_note='Twins. Say yes to both and put it where it fits.', why='Two shops are becoming one.', line="By colour. (By size.) By colour. Just... put it down, we'll move it.",
      recipe=[("garden_bench_oak", 1), ("plant_pot_v_sage", 4), ("plant_pot_v_mustard", 4), ("deck_chair_mustard", 2), ("barbecue_green", 1),
              ("push_mower_green", 1), ("pegboard_sage", 1), ("wine_rack_pine", 1), ("bath_mat_rose", 2), ("side_table_v_painted_white", 2), ("tool_box_v_red", 1)]),
 dict(id="job_theatre", level="L17", venue="theatre", drive="theatre_rain", unlock="job:job_florist", title="Theater Prop Department",
      client="Marguerite Vale", base=280, twist="heavy", mood='warm', brief='The prop department of the Alcazar into the new backstage: trunks, a coat stand of costumes, crates of props and the piano that plays itself on a bump.', mentor_note="Opening night is Friday. Tell them we've got this, and mean it.", why='Opening night is Friday.', line='Everything in here is older than me and more dramatic. Careful with the trunks.',
      recipe=[("trunk_v_leather", 1), ("coat_stand_brass", 1), ("crate_stack_walnut", 2), ("side_table_v_painted_white", 2), ("broken_chair_painted_white", 3), ("school_desk_walnut", 2),
              ("picture_v_white", 3), ("suitcase_stack_terracotta", 1), ("dartboard_classic", 1), ("plant_pot_v_sage", 2), ("bar_stool_mustard", 2)]),
 dict(id="job_broker", level="L19", venue="broker", drive="broker_day", unlock="job:job_theatre", title="Rival Broker's Office",
      client="Vernon Grayline", base=320, twist="plain", mood='rude', brief="Your old firm's rival, moving up a floor. Filing cabinets, a safe, the plants nobody waters. They will be watching.", mentor_note="The rival broker will inspect every box. Don't flinch.", why='Moving up a floor.', line="So you're the garage outfit. We'll see.",
      recipe=[("filing_cabinet_black", 2), ("safe_grey", 1), ("whiteboard_black", 2), ("office_plant_large_grey", 3), ("side_table_v_large_walnut", 2),
              ("bar_stool_blue", 2), ("picture_frame_brass", 3), ("crate_stack_plastic", 2), ("suitcase_cabin_terracotta", 2), ("kitchen_clock_terracotta", 1)]),
 dict(id="job_lodge", level="L20", venue="lodge", drive="lodge_snow", unlock="job:job_broker", title="Snowy Mountain Lodge",
      client="The Halvorsen family", base=360, twist="heavy", mood='warm', party=['adult', 'adult', 'kid'], brief="A family's lodge up the switchbacks: wingbacks, a trunk, the bunk room and the wood store. Snow on the road; chains on the truck.", mentor_note='Snow on the switchbacks. Chains on, calm as cocoa.', why='The first winter at the lodge.', line="Cocoa's on when you're done. Mind the step, it ices over.",
      recipe=[("armchair_v_wingback_terracotta", 2), ("trunk_v_pine", 1), ("deck_chair_rose", 2), ("barbecue_kettle_black", 1), ("wine_rack_walnut", 2),
              ("suitcase_tan", 3), ("bath_mat_cream", 2), ("laundry_hamper_wicker", 1), ("picture_v_oak", 3), ("plant_pot_v_mustard", 2), ("side_table_v_large_oak", 2), ("tool_box_v_steel", 1)]),
 dict(id="job_last", level="L22", venue="garage", drive="sunny_main", unlock="job:job_lodge", title="The Last Delivery",
      client="Nia Okafor-Reyes", base=150, twist="plain", mood='warm', brief='A young founder has bought your old garage. A desk, some crates, a whiteboard. You know that face.', mentor_note="Hand over the sticky notes. They're more ready than they think.", why='Starting out, in your old garage.', line='Is it always this quiet before the first job?',
      recipe=[("school_desk_pine", 1), ("crate_stack_oak", 3), ("office_plant_sage", 2), ("side_table_v_oak", 1), ("whiteboard_oak", 1),
              ("suitcase_cabin_blue", 2), ("bar_stool_sage", 2), ("picture_frame_pine", 2)]),
]

DRIVES = {
 "dentist_run": dict(title="Hartley Dental, clear", weather="clear", pickup="train", dropoff="dentist", hazards=[
   {"type": "cone", "along": 0.3, "lane": 1}, {"type": "bump", "along": 0.55, "w": 170, "h": 36}, {"type": "cone", "along": 0.75, "lane": 1}], scenery="town"),
 "market_morning": dict(title="Farmers Market Morning", weather="clear", pickup="florist", dropoff="library", hazards=[
   {"type": "gravel", "along": 0.25, "lane": 1, "w": 260, "h": 80}, {"type": "ducks", "along": 0.5, "w": 220, "h": 160, "auto_stop": True},
   {"type": "gravel", "along": 0.72, "lane": 1, "w": 260, "h": 80}], scenery="town"),
 "architect_rain": dict(title="Rain on Quay Street", weather="rain", pickup="cafe", dropoff="architect", hazards=[
   {"type": "puddle", "along": 0.2, "lane": 1, "r": 60}, {"type": "cone", "along": 0.5, "lane": 1}, {"type": "puddle", "along": 0.7, "lane": 1, "r": 56}], scenery="town"),
 "library_day": dict(title="Mill Lane, clear", weather="clear", pickup="library", dropoff="corner", hazards=[
   {"type": "bump", "along": 0.3, "w": 170, "h": 36}, {"type": "bump", "along": 0.65, "w": 170, "h": 36}], scenery="town"),
 "neon_night": dict(title="Midnight Neon", weather="night", pickup="record", dropoff="theatre", patrols=1, hazards=[
   {"type": "cone", "along": 0.35, "lane": 1}, {"type": "puddle", "along": 0.6, "lane": 1, "r": 60}], scenery="town"),
 "record_run": dict(title="Spindle Records, clear", weather="clear", pickup="record", dropoff="warehouse", hazards=[
   {"type": "cone", "along": 0.4, "lane": 1}, {"type": "gravel", "along": 0.7, "lane": 1, "w": 260, "h": 80}], scenery="town"),
 "florist_run": dict(title="Two shops, one van", weather="clear", pickup="florist", dropoff="glass", hazards=[
   {"type": "bump", "along": 0.35, "w": 170, "h": 36}, {"type": "ducks", "along": 0.8, "w": 220, "h": 160, "auto_stop": True}], scenery="town"),
 "theatre_rain": dict(title="Opening night, rain", weather="rain", pickup="theatre", dropoff="train", hazards=[
   {"type": "puddle", "along": 0.3, "lane": 1, "r": 64}, {"type": "cone", "along": 0.55, "lane": 1}, {"type": "puddle", "along": 0.8, "lane": 1, "r": 56}], scenery="town"),
 "parade_detour": dict(title="Parade Detour", weather="clear", pickup="cafe_new", dropoff="broker", hazards=[
   {"type": "cone", "along": 0.3, "lane": 1}, {"type": "cone", "along": 0.4, "lane": 1}, {"type": "ducks", "along": 0.6, "w": 220, "h": 160, "auto_stop": True}], scenery="town"),
 "broker_day": dict(title="The other side of town", weather="clear", pickup="glass", dropoff="broker", hazards=[
   {"type": "bump", "along": 0.5, "w": 170, "h": 36}], scenery="town"),
 "lodge_snow": dict(title="Snow on the Switchbacks", weather="snow", pickup="warehouse", dropoff="lodge", hazards=[
   {"type": "gravel", "along": 0.3, "lane": 1, "w": 260, "h": 80}, {"type": "puddle", "along": 0.55, "lane": 1, "r": 60}, {"type": "gravel", "along": 0.8, "lane": 1, "w": 260, "h": 80}], scenery="town"),
}

PLACES = [
 {"id": "dentist", "name": "Hartley Dental", "block": [1, 2], "side": "N", "t": 0.5, "color": "BFDDEA"},
 {"id": "architect", "name": "Okonkwo & Partners", "block": [3, 1], "side": "W", "t": 0.5, "color": "E6CDA3"},
 {"id": "library", "name": "Mill Lane Library", "block": [1, 3], "side": "N", "t": 0.5, "color": "B98C72"},
 {"id": "record", "name": "Spindle Records", "block": [3, 3], "side": "S", "t": 0.3, "color": "3E3A4F"},
 {"id": "florist", "name": "Pemberton & Pemberton", "block": [0, 2], "side": "E", "t": 0.5, "color": "A9C6A2"},
 {"id": "theatre", "name": "The Alcazar", "block": [1, 0], "side": "S", "t": 0.5, "color": "C0392B"},
 {"id": "broker", "name": "Grayline Brokerage", "block": [3, 2], "side": "S", "t": 0.7, "color": "9FC4D6"},
 {"id": "lodge", "name": "Switchback Lodge", "block": [4, 3], "side": "S", "t": 0.5, "color": "7A5C40"},
]


def main():
    plans = load("data/office_plans.json")
    for pid, plan in PLANS.items():
        plan = dict(plan)
        plan["authored"] = "gen_levels"
        plans["plans"][pid] = plan
    for pid, plan in plans["plans"].items():
        for fl in plan["floors"]:
            area = sum(r["w"] * r["d"] for r in fl["rooms"])
            assert area == plan["w"] * plan["d"], (pid, fl["name"], area)
    save("data/office_plans.json", plans)

    content = load("data/content.json")
    for vid, extra in VENUES.items():
        plan = PLANS[vid]
        content["venues"][vid] = {"name": extra["name"], "x": 0, "z": 0, "w": plan["w"], "d": plan["d"], "opening": "door", "open_w": 2,
                                  "windows": True, "music": extra["music"], "ambience": extra["ambience"], "authored": "gen_levels"}
    content["jobs"] = [j for j in content["jobs"] if j.get("authored") != "gen_levels"]
    for j in JOBS:
        rec = {"id": j["id"], "level": j["level"], "venue": j["venue"], "drive": j["drive"], "unlock": j["unlock"], "title": j["title"],
               "client": j["client"], "narrative_base": j["base"], "twist": j["twist"], "authored": "gen_levels",
               "recipe": [{"item": item, "count": n} for item, n in j["recipe"]]}
        for key in ("party", "mood", "brief", "mentor_note", "story", "why", "line"):
            if key in j:
                rec[key] = j[key]
        content["jobs"].append(rec)
    save("data/content.json", content)

    drives = load("data/drives.json")
    for did, d in DRIVES.items():
        rec = dict(d)
        rec["id"] = did
        rec["authored"] = "gen_levels"
        drives[did] = rec
    save("data/drives.json", drives)

    city = load("data/city.json")
    have = {p["id"] for p in city["places"]}
    for p in PLACES:
        if p["id"] not in have:
            city["places"].append(dict(p, authored="gen_levels"))
    save("data/city.json", city)

    tuning = load("data/tuning.json")
    for office in tuning["offices"]:
        if office["id"] in ("warehouse", "glass", "corner"):
            office["playable"] = True
    save("data/tuning.json", tuning)
    print("levels authored:", len(JOBS), "jobs,", len(DRIVES), "drives,", len(PLANS), "plans")


if __name__ == "__main__":
    main()
