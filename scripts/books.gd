extends RefCounted

## The office books: an accountant you hire, pay and audit, and the ledger
## that adds every day up (`data/staff.json`). Pay the accountant what they
## ask and they find savings on the day's takings. Pay them under it and
## the greedy ones help themselves; the jar only says "sundries" until an
## audit, which costs money and names the thief. Marge's tips live here too.

static var _data: Dictionary = {}


static func load_data() -> Dictionary:
	if _data.is_empty():
		var file := FileAccess.open("res://data/staff.json", FileAccess.READ)
		if file:
			var parsed: Variant = JSON.parse_string(file.get_as_text())
			if typeof(parsed) == TYPE_DICTIONARY:
				_data = parsed
	return _data


static func candidates() -> Array:
	return load_data().get("accountants", [])


static func candidate(id: String) -> Dictionary:
	for row in candidates():
		if str(row.get("id", "")) == id:
			return row
	return {}


static func tips() -> Array:
	return load_data().get("tips", ["Heavy on the bottom."])


static func tip_for(day: int) -> String:
	var pool := tips()
	return str(pool[day % pool.size()])


static func audit_cost() -> int:
	return int(load_data().get("audit_cost", 30))


static func hired() -> bool:
	return not GameState.accountant.is_empty()


static func hire(id: String, wage: int) -> Dictionary:
	if hired():
		return {"error": "You already have %s." % GameState.accountant.get("name", "an accountant")}
	var row := candidate(id)
	if row.is_empty():
		return {"error": "Nobody by that name."}
	GameState.accountant = {
		"id": id, "name": str(row.get("name", id)), "wage": maxi(5, wage), "ask": int(row.get("ask", 30)),
		"skill": float(row.get("skill", 0.05)), "greed": float(row.get("greed", 0.3)), "hired_day": GameState.day,
		"skimmed": 0, "saved": 0, "caught": false, "nights": 0, "sulk": 0,
	}
	GameState.bump_stat("hired_accountant")
	return {"said": str(row.get("line_hire", "Right then."))}


static func set_wage(wage: int) -> void:
	if hired():
		GameState.accountant["wage"] = clampi(wage, 5, 500)


static func fire() -> Dictionary:
	# Shown the door. A thief caught by the audit gives half of it back on the step.
	if not hired():
		return {"error": "Nobody to fire."}
	var acc: Dictionary = GameState.accountant
	var back := 0
	if bool(acc.get("caught", false)):
		back = int(acc.get("skimmed", 0)) / 2
		if back > 0:
			GameState.add_money(back, false)
	var name := str(acc.get("name", ""))
	GameState.accountant = {}
	GameState.bump_stat("fired_accountant")
	return {"said": "%s is gone.%s" % [name, (" $%d of it came back out of their coat." % back) if back > 0 else ""], "back": back}


static func audit() -> Dictionary:
	# Thirty dollars to go through the books with a pencil. It names what "sundries" was.
	if not hired():
		return {"error": "No books to audit."}
	var cost := audit_cost()
	if GameState.money < cost:
		return {"error": "The auditor wants $%d." % cost}
	GameState.add_money(-cost, false)
	GameState.bump_stat("audits")
	var acc: Dictionary = GameState.accountant
	var taken := int(acc.get("skimmed", 0))
	if taken <= 0:
		return {"clean": true, "said": "%s's books are clean. Every receipt where it should be." % acc.get("name", "")}
	acc["caught"] = true
	var row := candidate(str(acc.get("id", "")))
	GameState.inbox.append({
		"id": "audit_d%d" % GameState.day, "from": "Pell & Daughters, auditors", "subject": "Re: sundries",
		"body": "We went through the office books. 'Sundries' over %d night%s comes to $%d, and every entry is in %s's hand. We suggest you have a word, or several.\\n\\nOur fee has been deducted." % [int(acc.get("nights", 1)), "" if int(acc.get("nights", 1)) == 1 else "s", taken, acc.get("name", "")],
		"read": false,
	})
	GameState.emit_signal("emails_changed")
	return {"clean": false, "taken": taken, "said": "Sundries was %s. $%d, a bit each night. '%s'" % [acc.get("name", ""), taken, row.get("line_caught", "")]}


static func underpaid() -> float:
	# How far under the ask the wage sits, 0 to 1.
	if not hired():
		return 0.0
	var acc: Dictionary = GameState.accountant
	var ask := float(acc.get("ask", 30))
	return clampf((ask - float(acc.get("wage", 0))) / maxf(1.0, ask), 0.0, 1.0)


static func mood() -> String:
	if not hired():
		return ""
	if bool(GameState.accountant.get("caught", false)):
		return "caught"
	var under := underpaid()
	if under <= 0.0:
		return "happy"
	return "short" if under < 0.5 else "sour"


static func mood_line() -> String:
	if not hired():
		return ""
	var row := candidate(str(GameState.accountant.get("id", "")))
	match mood():
		"caught":
			return str(row.get("line_caught", ""))
		"happy":
			return str(row.get("line_happy", ""))
		_:
			return str(row.get("line_short", ""))


static func nightly(summary: Dictionary) -> Dictionary:
	# The wage comes out, the savings go in, and sometimes so does a hand.
	if not hired():
		return {}
	var acc: Dictionary = GameState.accountant
	var rng := GameState.rng
	var wage := int(acc.get("wage", 0))
	var out := {"name": str(acc.get("name", "")), "wage": wage, "saved": 0, "sundries": 0, "left": false, "raise": false}
	acc["nights"] = int(acc.get("nights", 0)) + 1
	var row := candidate(str(acc.get("id", "")))
	var every := int(row.get("raise_every", 0))
	if every > 0 and int(acc["nights"]) % every == 0:
		acc["ask"] = int(acc.get("ask", 30)) + 5
		out["raise"] = true
	if GameState.money < wage:
		# Not paid: they leave, and the greedy ones leave with something.
		var parting := 0
		if float(acc.get("greed", 0.0)) > 0.4:
			parting = clampi(int(float(GameState.money) * 0.5), 0, 200)
			GameState.add_money(-parting, false)
		out["left"] = true
		out["parting"] = parting
		GameState.inbox.append({"id": "acc_left_d%d" % GameState.day, "from": str(acc.get("name", "")), "subject": "Consider this my notice", "body": "The wage wasn't there tonight. I don't work for a jar that's empty.%s\\n\\nGood luck with the books." % ((" I've taken $%d for the week, which is fair." % parting) if parting > 0 else ""), "read": false})
		GameState.emit_signal("emails_changed")
		GameState.accountant = {}
		return out
	GameState.add_money(-wage, false)
	var takings := int(summary.get("job_pay", 0)) + int(summary.get("shop_earned", 0))
	var skill := float(acc.get("skill", 0.05))
	if underpaid() <= 0.0 and float(acc.get("wage", 0)) >= float(acc.get("ask", 30)) * 1.2:
		skill += 0.01
	var saved := int(round(float(takings) * skill))
	if saved > 0:
		GameState.add_money(saved, true)
		acc["saved"] = int(acc.get("saved", 0)) + saved
	out["saved"] = saved
	var chance := underpaid() * float(acc.get("greed", 0.0))
	if bool(out["raise"]):
		chance += 0.15
	if chance > 0.0 and rng.randf() < chance:
		var take := clampi(int(float(GameState.money) * rng.randf_range(0.04, 0.12)), 10, 400)
		take = mini(take, GameState.money)
		if take > 0:
			GameState.add_money(-take, false)
			acc["skimmed"] = int(acc.get("skimmed", 0)) + take
			GameState.stats["skimmed_total"] = int(GameState.stats.get("skimmed_total", 0)) + take
			out["sundries"] = take
	return out
