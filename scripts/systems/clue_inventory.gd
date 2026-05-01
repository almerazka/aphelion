extends Node

signal clues_updated
signal execution_state_changed(completed: bool)

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


func get_unlocked_sections() -> Array[Dictionary]:
	var sections: Array[Dictionary] = []
	for key in _unlock_order:
		if not _unlocked_npc_keys.has(key):
			continue
		var section_data: Dictionary = CLUES_BY_NPC[key]
		sections.append({
			"key": key,
			"name": section_data.get("name", key.to_upper()),
			"clues": section_data.get("clues", [])
		})

	if _shadow_dominic_clue_unlocked:
		sections.append({
			"key": "shadow_dominic",
			"name": "SHADOW CLUE - DOMINIC",
			"clues": [
				"Dominic admitted the victim received a special last drink without a guest sticker."
			]
		})
	return sections
