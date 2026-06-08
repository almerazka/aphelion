extends Node

signal clues_updated
signal execution_state_changed(completed: bool)

const SHADOW_DOMINIC_CLUE_TEXT := "Valerie's drink was the only one served personally by Dominic after the stickers had run out."

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
		"name": "MARCUS COLE",
		"clues": [
			"Marcus prepared all food and drinks, including tequila.",
			"Valerie consumed food and drinks before showing signs of illness.",
			"Guests occasionally entered the kitchen freely during the party."
		]
	}
}

var _unlocked_npc_keys: Dictionary = {}
var _unlock_order: Array[String] = []
var _execution_completed: bool = false
var _shadow_dominic_clue_unlocked: bool = false


func unlock_npc_clues(npc_key: String) -> bool:
	var key := npc_key.to_lower()
	if not CLUES_BY_NPC.has(key):
		return false
	if _unlocked_npc_keys.has(key):
		return false
	_unlocked_npc_keys[key] = true
	_unlock_order.append(key)
	clues_updated.emit()
	return true


func has_npc_clues(npc_key: String) -> bool:
	return _unlocked_npc_keys.has(npc_key.to_lower())


func get_unlocked_npc_count() -> int:
	return _unlocked_npc_keys.size()


func get_required_npc_count() -> int:
	return CLUES_BY_NPC.size()


func is_all_core_clues_unlocked() -> bool:
	return get_unlocked_npc_count() >= get_required_npc_count()


func mark_execution_completed() -> void:
	if _execution_completed:
		return
	_execution_completed = true
	execution_state_changed.emit(true)


func has_completed_execution() -> bool:
	return _execution_completed


func unlock_shadow_dominic_clue() -> bool:
	if _shadow_dominic_clue_unlocked:
		return false
	_shadow_dominic_clue_unlocked = true
	clues_updated.emit()
	return true


func has_shadow_dominic_clue() -> bool:
	return _shadow_dominic_clue_unlocked


func reset_progress() -> void:
	_unlocked_npc_keys.clear()
	_unlock_order.clear()
	_execution_completed = false
	_shadow_dominic_clue_unlocked = false
	clues_updated.emit()
	execution_state_changed.emit(false)


func get_unlocked_sections() -> Array[Dictionary]:
	var sections: Array[Dictionary] = []
	var dominic_section_index := -1
	for key in _unlock_order:
		if not _unlocked_npc_keys.has(key):
			continue
		if key == "dominic":
			dominic_section_index = sections.size()
		sections.append(_build_section_data(key))

	if _shadow_dominic_clue_unlocked:
		if dominic_section_index == -1:
			var dominic_shadow_section := {
				"key": "dominic",
				"name": String(CLUES_BY_NPC["dominic"].get("name", "DOMINIC HALE")),
				"clues": [_build_clue_entry(SHADOW_DOMINIC_CLUE_TEXT, true)]
			}
			sections.append(dominic_shadow_section)
		else:
			var dominic_section: Dictionary = sections[dominic_section_index]
			var dominic_clues: Array = dominic_section.get("clues", [])
			dominic_clues.insert(0, _build_clue_entry(SHADOW_DOMINIC_CLUE_TEXT, true))
			dominic_section["clues"] = dominic_clues
			sections[dominic_section_index] = dominic_section
	return sections


func _build_section_data(key: String) -> Dictionary:
	var section_data: Dictionary = CLUES_BY_NPC[key]
	var clue_entries: Array[Dictionary] = []
	var raw_clues: Array = section_data.get("clues", [])
	for clue in raw_clues:
		clue_entries.append(_build_clue_entry(String(clue)))
	return {
		"key": key,
		"name": String(section_data.get("name", key.to_upper())),
		"clues": clue_entries
	}


func _build_clue_entry(text: String, is_shadow_world: bool = false) -> Dictionary:
	return {
		"text": text,
		"is_shadow_world": is_shadow_world
	}
