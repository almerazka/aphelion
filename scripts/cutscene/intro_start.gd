extends Node2D

@export_file("*.tscn") var crime_intro_scene_path: String = "res://scenes/cutscene/crime_scene_intro.tscn"
@export var cutscene_zoom: Vector2 = Vector2(1.52, 1.52)
@export var cutscene_camera_offset: Vector2 = Vector2(-24.0, 0.0)
@export var transition_fade_out_duration: float = 1.45
@export var transition_black_hold_seconds: float = 0.2

@onready var fade_rect: ColorRect = $IntroOverlay/FadeRect
@onready var cutscene_camera: Camera2D = $CutsceneCamera

const DIALOG_PANEL_BG := Color(0.02, 0.02, 0.03, 0.92)
const DIALOG_PANEL_BORDER := Color(0.71, 0.63, 0.45, 0.78)
const DIALOG_PANEL_PADDING_X := 22
const DIALOG_PANEL_PADDING_Y := 18

const INTRO_TIMELINE_PARTY_TEXT := """
The tension at the party room was so much alive.

Victoria: Congratulations again, Dominic for your new business and hosting this party.
Dominic: Thank you so much, I'd really appreciate that.

Everyone was dancing, drinking, talking until there's something interrupting...
A hysterical scream.
"""

const INTRO_TIMELINE_AFTER_SCREAM_TEXT := """
Unknown: AAA.. OH MY GODDDDD! HELP!
Victoria: Who is that?

Everyone ran to the scene and it's over. It was pure chaos. Valerie Kane is dead.
"""

func _ready() -> void:
	_setup_camera()
	_run_intro()


func _run_intro() -> void:
	if has_node("/root/AudioManager"):
		AudioManager.lock_scene_bgm()
		AudioManager.play_party_bgm()
	await _fade_from_black(1.2)
	await _play_dialogic_timeline(INTRO_TIMELINE_PARTY_TEXT)
	if has_node("/root/AudioManager"):
		AudioManager.stop_bgm()
		AudioManager.play_scream()
	await get_tree().create_timer(0.35).timeout
	if has_node("/root/AudioManager"):
		AudioManager.play_talking_bgm()
	await _play_dialogic_timeline(INTRO_TIMELINE_AFTER_SCREAM_TEXT)
	if has_node("/root/AudioManager"):
		AudioManager.unlock_scene_bgm()
	await _transition_to_scene(crime_intro_scene_path, transition_fade_out_duration)


func _play_dialogic_timeline(timeline_text: String) -> void:
	if not has_node("/root/Dialogic"):
		return
	var timeline := DialogicTimeline.new()
	timeline.from_text(timeline_text)
	_apply_dialogic_cutscene_style()
	if not Dialogic.Text.speaker_updated.is_connected(_on_speaker_updated):
		Dialogic.Text.speaker_updated.connect(_on_speaker_updated)

	var auto_advance := Dialogic.Inputs.auto_advance
	var old_enabled_forced: bool = auto_advance.enabled_forced
	var old_fixed_delay: float = auto_advance.fixed_delay
	var old_per_word_delay: float = auto_advance.per_word_delay
	var old_per_character_delay: float = auto_advance.per_character_delay
	auto_advance.enabled_forced = true
	auto_advance.fixed_delay = 0.45
	auto_advance.per_word_delay = 0.12
	auto_advance.per_character_delay = 0.02

	Dialogic.start(timeline)
	await get_tree().process_frame
	_apply_dialogic_cutscene_style()
	await Dialogic.timeline_ended

	auto_advance.enabled_forced = old_enabled_forced
	auto_advance.fixed_delay = old_fixed_delay
	auto_advance.per_word_delay = old_per_word_delay
	auto_advance.per_character_delay = old_per_character_delay
	if Dialogic.Text.speaker_updated.is_connected(_on_speaker_updated):
		Dialogic.Text.speaker_updated.disconnect(_on_speaker_updated)


func _on_speaker_updated(_character: DialogicCharacter) -> void:
	_apply_dialogic_cutscene_style()


func _apply_dialogic_cutscene_style() -> void:
	for dialog_text in get_tree().get_nodes_in_group("dialogic_dialog_text"):
		if not (dialog_text is Control):
			continue
		var dialog_panel := _find_parent_panel(dialog_text as Control)
		if dialog_panel != null:
			dialog_panel.self_modulate = Color(1, 1, 1, 1)
			dialog_panel.add_theme_stylebox_override("panel", _build_dialog_stylebox())

	for name_label in get_tree().get_nodes_in_group("dialogic_name_label"):
		if "use_character_color" in name_label:
			name_label.use_character_color = false
		if name_label is CanvasItem:
			(name_label as CanvasItem).self_modulate = Color(1, 1, 1, 1)


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
	style.content_margin_left = DIALOG_PANEL_PADDING_X
	style.content_margin_top = DIALOG_PANEL_PADDING_Y
	style.content_margin_right = DIALOG_PANEL_PADDING_X
	style.content_margin_bottom = DIALOG_PANEL_PADDING_Y
	return style


func _setup_camera() -> void:
	if cutscene_camera == null:
		return
	cutscene_camera.enabled = true
	cutscene_camera.make_current()
	cutscene_camera.zoom = cutscene_zoom
	var center := _compute_room_center_from_tilemaps()
	if center != Vector2.ZERO:
		cutscene_camera.global_position = center + cutscene_camera_offset


func _compute_room_center_from_tilemaps() -> Vector2:
	var first := true
	var min_pos := Vector2.ZERO
	var max_pos := Vector2.ZERO

	for child in get_children():
		if not (child is TileMapLayer):
			continue
		var layer := child as TileMapLayer
		var used := layer.get_used_rect()
		if used.size == Vector2i.ZERO:
			continue

		var tl := layer.to_global(layer.map_to_local(used.position))
		var br := layer.to_global(layer.map_to_local(used.position + used.size))

		if first:
			min_pos = tl
			max_pos = br
			first = false
		else:
			min_pos.x = minf(min_pos.x, tl.x)
			min_pos.y = minf(min_pos.y, tl.y)
			max_pos.x = maxf(max_pos.x, br.x)
			max_pos.y = maxf(max_pos.y, br.y)

	if first:
		return Vector2.ZERO

	return (min_pos + max_pos) * 0.5


func _fade_from_black(duration: float) -> void:
	fade_rect.color.a = 1.0
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_property(fade_rect, "color:a", 0.0, duration)
	await tween.finished


func _fade_to_black(duration: float) -> void:
	var tween := create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_property(fade_rect, "color:a", 1.0, duration)
	await tween.finished


func _transition_to_scene(path: String, fade_duration: float) -> void:
	await _fade_to_black(fade_duration)
	await get_tree().create_timer(transition_black_hold_seconds).timeout
	get_tree().change_scene_to_file.bind(path).call_deferred()
