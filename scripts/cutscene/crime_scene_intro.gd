extends Node2D

@export_file("*.tscn") var gameplay_scene_path: String = "res://scenes/main_menu/lobby_1.tscn"
@export var cutscene_zoom: Vector2 = Vector2(2.4, 2.4)
@export var cutscene_camera_offset: Vector2 = Vector2(-110.0, 0.0)
@export var intro_fade_in_duration: float = 1.35
@export var scene_entry_hold_seconds: float = 0.16

@onready var fade_rect: ColorRect = $IntroOverlay/FadeRect
@onready var cutscene_camera: Camera2D = $CutsceneCamera

const CRIME_SCENE_TIMELINE_TEXT := """
Luna: Someone called the police or ambulance!
Julian: They're on their way.
"""

func _ready() -> void:
	_setup_camera()
	_run_scene_intro()


func _run_scene_intro() -> void:
	fade_rect.color.a = 1.0
	await get_tree().create_timer(scene_entry_hold_seconds).timeout
	await _fade_from_black(intro_fade_in_duration)
	await _play_dialogic_timeline(CRIME_SCENE_TIMELINE_TEXT)
	await _fade_to_black(1.0)
	get_tree().change_scene_to_file(gameplay_scene_path)


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
	auto_advance.fixed_delay = 0.4
	auto_advance.per_word_delay = 0.1
	auto_advance.per_character_delay = 0.02

	Dialogic.start(timeline)
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
	for name_label in get_tree().get_nodes_in_group("dialogic_name_label"):
		if "use_character_color" in name_label:
			name_label.use_character_color = false
		if name_label is CanvasItem:
			(name_label as CanvasItem).self_modulate = Color(1, 1, 1, 1)
		if name_label is Control:
			var panel := _find_parent_panel(name_label as Control)
			if panel != null:
				panel.self_modulate = Color(1, 1, 1, 1)
				panel.add_theme_stylebox_override("panel", _build_name_stylebox())


func _find_parent_panel(node: Node) -> PanelContainer:
	var current := node.get_parent()
	while current != null:
		if current is PanelContainer:
			return current as PanelContainer
		current = current.get_parent()
	return null


func _build_name_stylebox() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.05, 0.07, 0.98)
	style.border_color = Color(0.82, 0.72, 0.52, 0.95)
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
