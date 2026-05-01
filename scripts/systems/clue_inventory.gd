extends Node

const CLUES_BY_NPC := {
	"dominic": {
		"name": "DOMINIC HALE",
		"clues": [
			"Dominic personally handed drinks to every guest at the start of the party.",
			"Dominic confirms that Luna and Valerie had a well-known rivalry.",
			"According to Dominic, anyone could access the kitchen freely during the party."
		]
	},
	"victoria": {
		"name": "VICTORIA HAYES",
		"clues": [
			"Victoria saw Valerie in the kitchen with Julian earlier.",
			"Victoria suspects Julian may have given Valerie something that looked like medicine.",
			"Victoria reinforces that Luna had a long-standing rivalry with Valerie."
		]
	},
	"julian": {
		"name": "JULIAN PARK",
		"clues": [
			"Julian states Valerie was pale and vomiting before her death.",
			"Julian admits he gave Valerie medicine when she approached him.",
			"Julian explains poisoning usually involves overdose."
		]
	},
	"luna": {
		"name": "LUNA HART",
		"clues": [
			"Luna was with Valerie shortly before her death.",
			"Luna confirms she drank tequila with Valerie, prepared by the chef, Marcus.",
			"Luna claims she found Valerie already dying near the bathroom."
		]
	},
	"marcus": {
		"name": "MARCUS HALE",
		"clues": [
			"Marcus prepared all food and drinks, including tequila.",
			"Valerie consumed food and drinks before showing signs of illness.",
			"Guests occasionally entered the kitchen freely during the party."
		]
	}
}

var _unlocked_npc_keys: Dictionary = {}


func unlock_npc_clues(npc_key: String) -> bool:
	var key := npc_key.to_lower()
	if not CLUES_BY_NPC.has(key):
		return false
	if _unlocked_npc_keys.has(key):
		return false
	_unlocked_npc_keys[key] = true
	return true


func has_npc_clues(npc_key: String) -> bool:
	return _unlocked_npc_keys.has(npc_key.to_lower())


func get_unlocked_sections() -> Array[Dictionary]:
	var sections: Array[Dictionary] = []
	for key in CLUES_BY_NPC.keys():
		if not _unlocked_npc_keys.has(key):
			continue
		var section_data: Dictionary = CLUES_BY_NPC[key]
		sections.append({
			"key": key,
			"name": section_data.get("name", key.to_upper()),
			"clues": section_data.get("clues", [])
		})
	return sections
