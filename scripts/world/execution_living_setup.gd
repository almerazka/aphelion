extends Node2D

@export var ethan_node_path: NodePath = ^"Ethan"
@export var center_marker_path: NodePath = ^"ExecutionCenter"
@export var disable_exit_area: bool = true
@export var exit_area_path: NodePath = ^"ExitToLobby"
@export var execution_action: StringName = &"execution"
@export var correct_culprit_key: String = "dominic"
@export var execution_input_unlock_delay_seconds: float = 5.0
@export_file("*.tscn") var retry_scene_path: String = "res://scenes/main_menu/lobby_1.tscn"
@export var retry_spawn_marker: StringName = &"SpawnFromLiving"
@export_file("*.tscn") var restart_scene_path: String = "res://scenes/cutscene/intro_start.tscn"
@export_file("*.tscn") var main_menu_scene_path: String = "res://scenes/main_menu/lobby_1.tscn"
@export_file("*.tscn") var lose_scene_path: String = "res://scenes/main_menu/lose_screen.tscn"
@export_file("*.tscn") var win_scene_path: String = "res://scenes/main_menu/win_screen.tscn"

const NPC_RING_ORDER: Array[String] = ["Dominic", "Victoria", "Julian", "Luna", "Marcus"]
const SUSPECTS: Array[Dictionary] = [
	{"key":"dominic", "label":"Dominic Hale"},
	{"key":"victoria", "label":"Victoria Hayes"},
	{"key":"julian", "label":"Julian Park"},
	{"key":"luna", "label":"Luna Hart"},
	{"key":"marcus", "label":"Marcus Cole"},
]
const SUSPECT_SCENES := {
	"dominic": "res://scenes/characters/dominic.tscn",
	"victoria": "res://scenes/characters/victoria.tscn",
	"julian": "res://scenes/characters/julian.tscn",
	"luna": "res://scenes/characters/luna.tscn",
	"marcus": "res://scenes/characters/marcus.tscn",
}

@onready var ui_root: CanvasLayer = $ExecutionUI
@onready var dim_overlay: ColorRect = $ExecutionUI/DimOverlay
@onready var choose_panel: PanelContainer = $ExecutionUI/ChoosePanel
@onready var suspect_option: OptionButton = $ExecutionUI/ChoosePanel/Margin/VBox/SuspectOption
@onready var suspect_portrait: TextureRect = $ExecutionUI/ChoosePanel/Margin/VBox/SuspectPortrait
@onready var suspect_name_label: Label = $ExecutionUI/ChoosePanel/Margin/VBox/SuspectName
@onready var accuse_button: Button = $ExecutionUI/ChoosePanel/Margin/VBox/AccuseButton
@onready var close_button: Button = $ExecutionUI/ChoosePanel/Margin/VBox/CloseButton
@onready var confirm_panel: PanelContainer = $ExecutionUI/ConfirmPanel
@onready var confirm_label: Label = $ExecutionUI/ConfirmPanel/Margin/VBox/ConfirmLabel
@onready var confirm_yes_button: Button = $ExecutionUI/ConfirmPanel/Margin/VBox/HBox/YesButton
@onready var confirm_no_button: Button = $ExecutionUI/ConfirmPanel/Margin/VBox/HBox/NoButton
@onready var result_panel: PanelContainer = $ExecutionUI/ResultPanel
@onready var win_image: TextureRect = $ExecutionUI/ResultPanel/Margin/VBox/WinImage
@onready var lose_label: Label = $ExecutionUI/ResultPanel/Margin/VBox/LoseLabel
@onready var result_label: Label = $ExecutionUI/ResultPanel/Margin/VBox/ResultLabel
@onready var win_time_label: Label = $ExecutionUI/ResultPanel/Margin/VBox/WinTimeLabel
@onready var try_again_button: Button = $ExecutionUI/ResultPanel/Margin/VBox/HBox/TryAgainButton
@onready var finish_button: Button = $ExecutionUI/ResultPanel/Margin/VBox/HBox/FinishButton

var _pending_suspect_key: String = ""
var _case_resolved: bool = false
var _execution_input_unlocked: bool = false
var _bad_ending_pending_restart: bool = false

func _ready() -> void:
	_disable_exit_if_needed()
	_setup_execution_group()
	_enforce_execution_blockers()
	_unlock_post_execution_features()
	_setup_ui()
	_start_execution_input_unlock_delay()


func _unhandled_input(event: InputEvent) -> void:
	if _case_resolved:
		return
	if not _execution_input_unlocked:
		return
	if event.is_action_pressed(execution_action):
		if _is_dialog_running() or _is_clue_inventory_open():
			return
		if _is_any_panel_open():
			_close_selection_panels()
			return
		_open_choose_panel()


func _disable_exit_if_needed() -> void:
	if not disable_exit_area:
		return
	var exit_area := get_node_or_null(exit_area_path)
	if exit_area is Area2D:
		(exit_area as Area2D).monitoring = false
		var shape := exit_area.get_node_or_null("CollisionShape2D")
		if shape is CollisionShape2D:
			(shape as CollisionShape2D).disabled = true


func _setup_execution_group() -> void:
	var center := _get_center_position()
	if center == Vector2.ZERO:
		return

	# NPC placement is now fully manual from the scene editor.
	var ethan := get_node_or_null(ethan_node_path)
	if ethan is Node2D:
		(ethan as Node2D).global_position = center + Vector2(0, 92)
		(ethan as Node2D).z_index = 0

	_ensure_npcs_above_ethan_in_tree()


func _get_center_position() -> Vector2:
	var center_marker := get_node_or_null(center_marker_path)
	if center_marker is Node2D:
		return (center_marker as Node2D).global_position

	var ethan := get_node_or_null(ethan_node_path)
	if ethan is Node2D:
		return (ethan as Node2D).global_position + Vector2(0, -20)

	return Vector2.ZERO


func _unlock_post_execution_features() -> void:
	if has_node("/root/ClueInventory"):
		ClueInventory.mark_execution_completed()


func _enforce_execution_blockers() -> void:
	var ethan := get_node_or_null(ethan_node_path)
	if ethan is CharacterBody2D:
		var ethan_body := ethan as CharacterBody2D
		ethan_body.collision_layer = 1
		ethan_body.collision_mask = 3

	for npc_name in NPC_RING_ORDER:
		var npc := get_node_or_null(NodePath(npc_name))
		if npc is CharacterBody2D:
			var npc_body := npc as CharacterBody2D
			npc_body.collision_layer = 2
			npc_body.collision_mask = 3
			npc_body.z_index = 2
			var npc_shape_node := npc_body.get_node_or_null("CollisionShape2D")
			if npc_shape_node is CollisionShape2D:
				var npc_shape := (npc_shape_node as CollisionShape2D).shape
				if npc_shape is RectangleShape2D:
					# Execution room needs tighter body blocking so Ethan cannot slip between suspects.
					(npc_shape as RectangleShape2D).size = Vector2(56, 92)


func _ensure_npcs_above_ethan_in_tree() -> void:
	var ethan := get_node_or_null(ethan_node_path)
	if ethan == null:
		return
	for npc_name in NPC_RING_ORDER:
		var npc := get_node_or_null(NodePath(npc_name))
		if npc != null and npc.get_parent() == self:
			move_child(npc, -1)


func _setup_ui() -> void:
	if ui_root == null:
		return
	ui_root.visible = true
	choose_panel.visible = false
	confirm_panel.visible = false
	result_panel.visible = false
	_refresh_ui_visibility()
	_pending_suspect_key = ""
	suspect_option.clear()
	for suspect in SUSPECTS:
		suspect_option.add_item(String(suspect.get("label", "")))
	if not suspect_option.item_selected.is_connected(_on_suspect_selected):
		suspect_option.item_selected.connect(_on_suspect_selected)

	if not accuse_button.pressed.is_connected(_on_accuse_pressed):
		accuse_button.pressed.connect(_on_accuse_pressed)
	if not close_button.pressed.is_connected(_on_close_pressed):
		close_button.pressed.connect(_on_close_pressed)
	if not confirm_yes_button.pressed.is_connected(_on_confirm_yes_pressed):
		confirm_yes_button.pressed.connect(_on_confirm_yes_pressed)
	if not confirm_no_button.pressed.is_connected(_on_confirm_no_pressed):
		confirm_no_button.pressed.connect(_on_confirm_no_pressed)
	if not try_again_button.pressed.is_connected(_on_try_again_pressed):
		try_again_button.pressed.connect(_on_try_again_pressed)
	if not finish_button.pressed.is_connected(_on_finish_pressed):
		finish_button.pressed.connect(_on_finish_pressed)

	finish_button.visible = false
	try_again_button.visible = true
	try_again_button.text = "Try Again"
	win_image.visible = false
	lose_label.visible = false
	win_time_label.visible = false
	_set_ethan_can_walk(true)
	_refresh_suspect_preview(0)


func _is_any_panel_open() -> bool:
	return choose_panel.visible or confirm_panel.visible or result_panel.visible


func _open_choose_panel() -> void:
	choose_panel.visible = true
	confirm_panel.visible = false
	result_panel.visible = false
	_refresh_ui_visibility()
	_set_ethan_can_walk(false)


func _on_accuse_pressed() -> void:
	var selected_index := suspect_option.selected
	if selected_index < 0 or selected_index >= SUSPECTS.size():
		return
	_pending_suspect_key = String(SUSPECTS[selected_index].get("key", ""))
	var selected_name := String(SUSPECTS[selected_index].get("label", "this person"))
	confirm_label.text = "Are you sure %s is the killer?" % selected_name
	choose_panel.visible = false
	confirm_panel.visible = true
	_refresh_ui_visibility()


func _on_close_pressed() -> void:
	_close_selection_panels()


func _on_confirm_yes_pressed() -> void:
	if _pending_suspect_key.is_empty():
		return
	confirm_panel.visible = false
	result_panel.visible = true
	_refresh_ui_visibility()

	if _pending_suspect_key == correct_culprit_key.to_lower():
		_case_resolved = true
		var elapsed_text: String = "00:00:00"
		if has_node("/root/PlayGuide"):
			elapsed_text = PlayGuide.get_formatted_elapsed()
		if has_node("/root/WorldState"):
			WorldState.last_win_elapsed_text = elapsed_text
		_set_ethan_can_walk(false)
		if has_node("/root/SceneTransition"):
			SceneTransition.change_scene(win_scene_path)
		else:
			get_tree().change_scene_to_file(win_scene_path)
		return
	else:
		win_image.visible = false
		win_time_label.visible = false
		result_label.visible = true
		var is_final_judgment := has_node("/root/WorldState") and has_node("/root/ClueInventory") and WorldState.shadow_unlocked and ClueInventory.has_shadow_dominic_clue()
		if is_final_judgment:
			if has_node("/root/ClueInventory"):
				ClueInventory.reset_progress()
			if has_node("/root/WorldState"):
				WorldState.reset_state()
			if has_node("/root/SceneTransition"):
				SceneTransition.change_scene(lose_scene_path)
			else:
				get_tree().change_scene_to_file(lose_scene_path)
			return
		else:
			_bad_ending_pending_restart = false
			lose_label.visible = false
			result_label.text = "You are wrong.\nTry again."
			try_again_button.text = "Try Again"
		try_again_button.visible = true
		finish_button.visible = false
		if has_node("/root/WorldState"):
			WorldState.unlock_shadow_world(false)


func _on_confirm_no_pressed() -> void:
	confirm_panel.visible = false
	choose_panel.visible = true
	_refresh_ui_visibility()


func _on_try_again_pressed() -> void:
	choose_panel.visible = false
	confirm_panel.visible = false
	result_panel.visible = false
	_refresh_ui_visibility()
	_pending_suspect_key = ""
	var restart_from_beginning := _bad_ending_pending_restart
	_bad_ending_pending_restart = false
	_set_ethan_can_walk(false)
	if restart_from_beginning:
		if has_node("/root/ClueInventory"):
			ClueInventory.reset_progress()
		if has_node("/root/WorldState"):
			WorldState.reset_state()
		if has_node("/root/SceneTransition"):
			SceneTransition.change_scene(main_menu_scene_path)
		else:
			get_tree().change_scene_to_file(main_menu_scene_path)
		return
	if has_node("/root/WorldState"):
		WorldState.unlock_shadow_world(false)
	if has_node("/root/SceneTransition"):
		SceneTransition.change_scene(retry_scene_path, retry_spawn_marker)
	else:
		if not retry_spawn_marker.is_empty():
			get_tree().set_meta("aphelion_spawn_marker", retry_spawn_marker)
		get_tree().change_scene_to_file(retry_scene_path)


func _on_finish_pressed() -> void:
	if has_node("/root/SceneTransition"):
		SceneTransition.change_scene(main_menu_scene_path)
	else:
		get_tree().change_scene_to_file(main_menu_scene_path)


func _set_ethan_can_walk(value: bool) -> void:
	var ethan := get_node_or_null(ethan_node_path)
	if ethan == null:
		return
	for property in ethan.get_property_list():
		if String(property.get("name", "")) == "can_walk":
			ethan.set("can_walk", value)
			return


func _start_execution_input_unlock_delay() -> void:
	_execution_input_unlocked = false
	if has_node("/root/WorldState") and WorldState.execution_prompt_seen:
		_execution_input_unlocked = true
		return
	if has_node("/root/WorldState"):
		WorldState.execution_prompt_seen = true
	if execution_input_unlock_delay_seconds <= 0.0:
		_execution_input_unlocked = true
		return
	call_deferred("_unlock_execution_input_after_delay")


func _unlock_execution_input_after_delay() -> void:
	await get_tree().create_timer(execution_input_unlock_delay_seconds).timeout
	_execution_input_unlocked = true


func _is_dialog_running() -> bool:
	if not has_node("/root/Dialogic"):
		return false
	return Dialogic.current_timeline != null


func _is_clue_inventory_open() -> bool:
	var ethan := get_node_or_null(ethan_node_path)
	if ethan == null:
		return false
	var clue_ui := ethan.get_node_or_null("ClueInventoryUI")
	if clue_ui == null:
		return false
	var panel := clue_ui.get_node_or_null("BookPanel")
	if panel is CanvasItem:
		return (panel as CanvasItem).visible
	return false


func _on_suspect_selected(index: int) -> void:
	_refresh_suspect_preview(index)


func _refresh_suspect_preview(index: int) -> void:
	if index < 0 or index >= SUSPECTS.size():
		return
	var suspect := SUSPECTS[index]
	suspect_name_label.text = String(suspect.get("label", "Unknown"))
	var key := String(suspect.get("key", ""))
	var scene_path := String(SUSPECT_SCENES.get(key, ""))
	suspect_portrait.texture = _extract_portrait_from_scene(scene_path)


func _refresh_ui_visibility() -> void:
	if dim_overlay == null:
		return
	dim_overlay.visible = _is_any_panel_open()


func _close_selection_panels() -> void:
	if result_panel.visible:
		return
	choose_panel.visible = false
	confirm_panel.visible = false
	_refresh_ui_visibility()
	_set_ethan_can_walk(true)


func _extract_portrait_from_scene(scene_path: String) -> Texture2D:
	if scene_path.is_empty():
		return null
	var packed := load(scene_path)
	if not (packed is PackedScene):
		return null
	var node := (packed as PackedScene).instantiate()
	if node == null:
		return null
	var sprite := node.get_node_or_null("AnimatedSprite2D")
	if sprite is AnimatedSprite2D:
		var frames := (sprite as AnimatedSprite2D).sprite_frames
		if frames == null:
			return null
		var animation := "walk_down"
		if not frames.has_animation(animation):
			var names := frames.get_animation_names()
			if names.size() > 0:
				animation = String(names[0])
		if animation.is_empty():
			return null
		if frames.get_frame_count(animation) <= 0:
			return null
		return frames.get_frame_texture(animation, 0)
	return null
