extends CanvasLayer

@export var toggle_action: StringName = &"clue"

@onready var panel: PanelContainer = $BookPanel
@onready var content_label: RichTextLabel = $BookPanel/Margin/VBox/Content


func _ready() -> void:
	visible = false
	panel.visible = false
	_update_content()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed(toggle_action):
		return
	if _is_dialog_running():
		return
	_toggle_inventory()


func _toggle_inventory() -> void:
	var next_visible := not panel.visible
	panel.visible = next_visible
	visible = next_visible
	if next_visible:
		_update_content()
	_set_player_walk_state(not next_visible)


func _set_player_walk_state(can_move: bool) -> void:
	var owner_node := get_parent()
	if owner_node == null:
		return
	for property in owner_node.get_property_list():
		if String(property.get("name", "")) == "can_walk":
			owner_node.set("can_walk", can_move)
			return


func _is_dialog_running() -> bool:
	if not has_node("/root/Dialogic"):
		return false
	return Dialogic.current_timeline != null


func _update_content() -> void:
	if not has_node("/root/ClueInventory"):
		content_label.text = "[color=#ff9090]ClueInventory autoload is not active yet.[/color]"
		return

	var sections: Array[Dictionary] = ClueInventory.get_unlocked_sections()
	if sections.is_empty():
		content_label.text = "[font_size=20][i]No clues yet.[/i]\n\nTalk to NPCs first (press Space) to unlock clues.[/font_size]"
		return

	var lines: Array[String] = []
	for section in sections:
		lines.append("[color=#f0d7a1][b]%s[/b][/color]" % String(section.get("name", "UNKNOWN")))
		var clues: Array = section.get("clues", [])
		for clue in clues:
			lines.append("[color=#e6e9ee]- %s[/color]" % String(clue))
		lines.append("")

	content_label.text = "\n".join(lines)
