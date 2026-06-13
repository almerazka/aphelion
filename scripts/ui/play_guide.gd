extends CanvasLayer

@export var intro_duration_seconds: float = 8.0
@export var lobby_intro_duration_seconds: float = 8.0
@export var execution_prompt_duration_seconds: float = 5.0
@export var shadow_prompt_duration_seconds: float = 10.0

@onready var panel: PanelContainer = $CenterGuidePanel
@onready var label: RichTextLabel = $CenterGuidePanel/Margin/GuideText
@onready var timer: Timer = $DisplayTimer
@onready var play_time_panel: PanelContainer = $PlayTimePanel
@onready var play_time_label: Label = $PlayTimePanel/Margin/Center/PlayTimeLabel

var _showing_execution_prompt: bool = false
var _shadow_hint_shown_once: bool = false
var _lobby_intro_shown_once: bool = false
var _intro_guide_shown_once: bool = false
var _execution_room_hint_shown_once: bool = false
var _default_panel_offsets: Vector4 = Vector4.ZERO
var _timer_started: bool = false
var _elapsed_seconds: float = 0.0

func _ready() -> void:
	_default_panel_offsets = Vector4(panel.offset_left, panel.offset_top, panel.offset_right, panel.offset_bottom)
	play_time_panel.visible = false
	play_time_label.visible = false
	if not timer.timeout.is_connected(_on_display_timer_timeout):
		timer.timeout.connect(_on_display_timer_timeout)
	var tree := get_tree()
	if tree.has_signal("scene_changed") and not tree.is_connected("scene_changed", Callable(self, "_on_scene_changed")):
		tree.connect("scene_changed", Callable(self, "_on_scene_changed"))
	elif tree.has_signal("current_scene_changed") and not tree.is_connected("current_scene_changed", Callable(self, "_on_current_scene_changed")):
		tree.connect("current_scene_changed", Callable(self, "_on_current_scene_changed"))
	if has_node("/root/ClueInventory"):
		if not ClueInventory.clues_updated.is_connected(_refresh):
			ClueInventory.clues_updated.connect(_refresh)
		if not ClueInventory.execution_state_changed.is_connected(_on_execution_state_changed):
			ClueInventory.execution_state_changed.connect(_on_execution_state_changed)
	if has_node("/root/WorldState"):
		if not WorldState.shadow_unlocked_changed.is_connected(_on_shadow_unlock_changed):
			WorldState.shadow_unlocked_changed.connect(_on_shadow_unlock_changed)
	_maybe_show_intro_guide_once()
	set_process(true)
	_update_play_time_label()
	_refresh()


func _notification(what: int) -> void:
	if what == NOTIFICATION_ENTER_TREE:
		call_deferred("_maybe_show_intro_guide_once")


func _on_execution_state_changed(_completed: bool) -> void:
	_refresh()


func _on_shadow_unlock_changed(_unlocked: bool) -> void:
	_refresh()


func _on_current_scene_changed(_scene: Node) -> void:
	_deferred_scene_refresh()


func _on_scene_changed() -> void:
	_deferred_scene_refresh()


func _deferred_scene_refresh() -> void:
	call_deferred("_refresh_after_scene_ready")


func _refresh_after_scene_ready() -> void:
	await get_tree().process_frame
	_maybe_show_intro_guide_once()
	_refresh()


func _refresh() -> void:
	if _is_cutscene_scene():
		panel.visible = false
		play_time_panel.visible = false
		return
	if not _is_gameplay_scene():
		panel.visible = false
		play_time_panel.visible = false
		play_time_label.visible = false
		return
	play_time_panel.visible = not _is_main_menu_scene()
	play_time_label.visible = play_time_panel.visible
	if not has_node("/root/ClueInventory"):
		return

	if _is_execution_scene():
		_show_execution_room_hint()
		return

	if has_node("/root/WorldState") and WorldState.shadow_unlocked:
		_show_execution_completed_hint()
		return

	if ClueInventory.is_all_core_clues_unlocked():
		_show_ready_execution_hint()
		return


func _maybe_show_intro_guide_once() -> void:
	if _is_cutscene_scene():
		panel.visible = false
		return
	if not _is_gameplay_scene():
		panel.visible = false
		return
	if _intro_guide_shown_once:
		return
	_showing_execution_prompt = false
	var intro_text := "[center][color=#9efcff][b]PLAY GUIDE[/b][/color][/center]\n"
	intro_text += "[center][color=#e8f7ff]Press `Space` to talk to NPCs[/color][/center]\n"
	intro_text += "[center][color=#e8f7ff]Press `C` to open the Detective Notebook[/color][/center]\n"
	intro_text += "\n[center][color=#8bd8ff]Gather information first. Once all NPCs have been questioned[/color][/center]"
	var duration := intro_duration_seconds
	var current_scene := get_tree().current_scene
	if current_scene != null and current_scene.scene_file_path == "res://scenes/main_menu/lobby_1.tscn" and not _lobby_intro_shown_once:
		duration = lobby_intro_duration_seconds
		_lobby_intro_shown_once = true
	_show_text(intro_text, duration)
	_intro_guide_shown_once = true


func _show_ready_execution_hint() -> void:
	_showing_execution_prompt = false
	_restore_default_panel_size()
	var text := "[center][color=#ffd79a][b]ALL CLUES COLLECTED[/b][/color][/center]\n"
	text += "[center][color=#fff2d8]Proceeding to the execution room...[/color][/center]"
	_show_text(text, 1.8)


func _show_execution_room_hint() -> void:
	if _execution_room_hint_shown_once:
		return
	_execution_room_hint_shown_once = true
	_showing_execution_prompt = false
	_set_compact_execution_panel()
	var text := "[center][color=#ffd79a][b]PRESS E TO ACCUSE[/b][/color][/center]"
	_show_text(text, execution_prompt_duration_seconds)


func _show_execution_completed_hint() -> void:
	if _shadow_hint_shown_once:
		return
	_shadow_hint_shown_once = true
	_restore_default_panel_size()
	var text := "[center][color=#b5ccff][b]SHADOW WORLD UNLOCKED[/b][/color][/center]\n"
	text += "[center][color=#dfe9ff]Press `R` for Real World.\n Press `S` for Shadow World to find hidden clues.[/color][/center]"
	_show_text(text, shadow_prompt_duration_seconds)


func _show_text(text: String, duration_seconds: float) -> void:
	label.text = text
	panel.visible = true
	timer.stop()
	if duration_seconds > 0.0:
		timer.start(duration_seconds)


func _is_gameplay_scene() -> bool:
	var current_scene := get_tree().current_scene
	if current_scene == null:
		return false
	return current_scene.get_node_or_null("Ethan") != null


func _is_execution_scene() -> bool:
	var current_scene := get_tree().current_scene
	if current_scene == null:
		return false
	return current_scene.scene_file_path == "res://scenes/rooms/execution.tscn"


func _is_cutscene_scene() -> bool:
	var current_scene := get_tree().current_scene
	if current_scene == null:
		return false
	return String(current_scene.scene_file_path).begins_with("res://scenes/cutscene/")


func _is_main_menu_scene() -> bool:
	var current_scene := get_tree().current_scene
	if current_scene == null:
		return false
	return String(current_scene.scene_file_path) == "res://scenes/main_menu/main_menu.tscn"


func _on_display_timer_timeout() -> void:
	if _showing_execution_prompt:
		return
	panel.visible = false
	_restore_default_panel_size()


func _process(delta: float) -> void:
	if _is_gameplay_scene():
		_timer_started = true
	if _timer_started:
		_elapsed_seconds += delta
	_update_play_time_label()


func get_elapsed_seconds() -> float:
	return _elapsed_seconds


func get_formatted_elapsed() -> String:
	return _format_seconds(_elapsed_seconds)


func _set_compact_execution_panel() -> void:
	panel.offset_left = -315.0
	panel.offset_right = 315.0
	panel.offset_top = -45.0
	panel.offset_bottom = 45.0


func _restore_default_panel_size() -> void:
	if _default_panel_offsets == Vector4.ZERO:
		return
	panel.offset_left = _default_panel_offsets.x
	panel.offset_top = _default_panel_offsets.y
	panel.offset_right = _default_panel_offsets.z
	panel.offset_bottom = _default_panel_offsets.w


func _update_play_time_label() -> void:
	if play_time_label == null:
		return
	play_time_label.text = "Time %s" % _format_seconds(_elapsed_seconds)


func _format_seconds(total_seconds: float) -> String:
	var value := int(total_seconds)
	var hours := value / 3600
	var minutes := (value % 3600) / 60
	var seconds := value % 60
	return "%02d:%02d:%02d" % [hours, minutes, seconds]


func reset_session() -> void:
	_showing_execution_prompt = false
	_shadow_hint_shown_once = false
	_lobby_intro_shown_once = false
	_intro_guide_shown_once = false
	_execution_room_hint_shown_once = false
	_timer_started = false
	_elapsed_seconds = 0.0
	timer.stop()
	panel.visible = false
	_restore_default_panel_size()
	_update_play_time_label()
