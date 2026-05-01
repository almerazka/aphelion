extends CharacterBody2D

@export var speed: float = 150.0
@export var can_walk: bool = false
@export var talk_action: StringName = &"talk"
@export var execution_action: StringName = &"execution"
@export_file("*.tscn") var execution_scene_path: String = "res://scenes/rooms/execution_living.tscn"

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var interaction_area: Area2D = get_node_or_null("InteractionArea")
var _last_dir: Vector2 = Vector2.DOWN
var _dialog_active: bool = false
var _active_dialog_npc_key: String = ""
const DIALOG_NAME_COLOR := Color(1, 1, 1, 1)
const DIALOG_PANEL_BG := Color(0.02, 0.02, 0.03, 0.92)
const DIALOG_PANEL_BORDER := Color(0.71, 0.63, 0.45, 0.78)

const INTERACTABLE_DIALOG_KEYS: Dictionary = {
	"dominic": "dominic",
	"victoria": "victoria",
	"julian": "julian",
	"luna": "luna",
	"marcus": "marcus",
}

func _physics_process(_delta: float) -> void:
	if not can_walk:
		velocity = Vector2.ZERO
		_play_idle()
		move_and_slide()
		return

	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = input_dir * speed

	if input_dir != Vector2.ZERO:
		_last_dir = input_dir
		_play_walk(input_dir)
	else:
		_play_idle()

	move_and_slide()


func _unhandled_input(event: InputEvent) -> void:
	if _dialog_active:
		return
	if event.is_action_pressed(talk_action):
		_try_talk_to_nearest_npc()
		return
	if event.is_action_pressed(execution_action):
		_try_enter_execution_scene()


func _try_talk_to_nearest_npc() -> void:
	if interaction_area == null:
		return
	if not has_node("/root/Dialogic"):
		return

	var nearest_npc: Node2D = null
	var nearest_distance := INF

	for body in interaction_area.get_overlapping_bodies():
		if not (body is Node2D):
			continue
		var npc_key := String(body.name).to_lower()
		if not INTERACTABLE_DIALOG_KEYS.has(npc_key):
			continue

		var distance := global_position.distance_to((body as Node2D).global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_npc = body

	if nearest_npc == null:
		return

	var key: String = String(INTERACTABLE_DIALOG_KEYS[String(nearest_npc.name).to_lower()])
	var timeline_text: String = NpcDialogues.get_timeline_text(key)
	if timeline_text.is_empty():
		return

	var timeline := DialogicTimeline.new()
	timeline.from_text(timeline_text)

	_dialog_active = true
	can_walk = false
	_active_dialog_npc_key = key

	if not Dialogic.timeline_ended.is_connected(_on_dialogue_ended):
		Dialogic.timeline_ended.connect(_on_dialogue_ended)
	if not Dialogic.Text.speaker_updated.is_connected(_on_dialogic_speaker_updated):
		Dialogic.Text.speaker_updated.connect(_on_dialogic_speaker_updated)

	Dialogic.start(timeline)
	_apply_dialog_name_style()
	_apply_dialog_panel_style()


func _try_enter_execution_scene() -> void:
	if _dialog_active:
		return
	if execution_scene_path.is_empty():
		return
	if not has_node("/root/ClueInventory"):
		return
	if not ClueInventory.is_all_core_clues_unlocked():
		return
	if get_tree().current_scene != null and get_tree().current_scene.scene_file_path == execution_scene_path:
		return
	get_tree().change_scene_to_file(execution_scene_path)


func _on_dialogue_ended() -> void:
	if Dialogic.timeline_ended.is_connected(_on_dialogue_ended):
		Dialogic.timeline_ended.disconnect(_on_dialogue_ended)
	if Dialogic.Text.speaker_updated.is_connected(_on_dialogic_speaker_updated):
		Dialogic.Text.speaker_updated.disconnect(_on_dialogic_speaker_updated)
	if has_node("/root/ClueInventory") and not _active_dialog_npc_key.is_empty():
		ClueInventory.unlock_npc_clues(_active_dialog_npc_key)
	_active_dialog_npc_key = ""
	_dialog_active = false
	can_walk = true


func _on_dialogic_speaker_updated(_character: DialogicCharacter) -> void:
	_apply_dialog_name_style()
	_apply_dialog_panel_style()


func _apply_dialog_name_style() -> void:
	for name_label in get_tree().get_nodes_in_group("dialogic_name_label"):
		if "use_character_color" in name_label:
			name_label.use_character_color = false
		if name_label is CanvasItem:
			(name_label as CanvasItem).self_modulate = DIALOG_NAME_COLOR


func _apply_dialog_panel_style() -> void:
	for dialog_text in get_tree().get_nodes_in_group("dialogic_dialog_text"):
		if not (dialog_text is Control):
			continue
		var dialog_panel := _find_parent_panel(dialog_text as Control)
		if dialog_panel != null:
			dialog_panel.self_modulate = Color(1, 1, 1, 1)
			dialog_panel.add_theme_stylebox_override("panel", _build_dialog_stylebox())

	for name_label in get_tree().get_nodes_in_group("dialogic_name_label"):
		if not (name_label is Control):
			continue
		var name_panel := _find_parent_panel(name_label as Control)
		if name_panel != null:
			name_panel.self_modulate = Color(1, 1, 1, 1)
			name_panel.add_theme_stylebox_override("panel", _build_name_stylebox())


func _find_parent_panel(node: Node) -> PanelContainer:
	var current := node.get_parent()
	while current != null:
		if current is PanelContainer:
			return current as PanelContainer
		current = current.get_parent()
	return null


func _build_dialog_stylebox() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = DIALOG_PANEL_BG
	style.border_color = DIALOG_PANEL_BORDER
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_right = 10
	style.corner_radius_bottom_left = 10
	style.shadow_color = Color(0, 0, 0, 0.5)
	style.shadow_size = 7
	style.content_margin_left = 14
	style.content_margin_top = 11
	style.content_margin_right = 14
	style.content_margin_bottom = 11
	return style


func _build_name_stylebox() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.06, 0.08, 0.97)
	style.border_color = DIALOG_PANEL_BORDER
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	style.content_margin_left = 10
	style.content_margin_right = 10
	return style

func _play_walk(dir: Vector2) -> void:
	if absf(dir.x) > absf(dir.y):
		sprite.flip_h = dir.x < 0.0
		sprite.play("walk_right")
	else:
		sprite.flip_h = false
		if dir.y < 0.0:
			sprite.play("walk_up")
		else:
			sprite.play("walk_down")

func _play_idle() -> void:
	if absf(_last_dir.x) > absf(_last_dir.y):
		sprite.flip_h = _last_dir.x < 0.0
		sprite.play("walk_right")
		sprite.frame = 0
		sprite.pause()
	else:
		sprite.flip_h = false
		if _last_dir.y < 0.0:
			sprite.play("walk_up")
		else:
			sprite.play("walk_down")
		sprite.frame = 0
		sprite.pause()
