extends CanvasLayer

@export var fade_out_duration: float = 0.35
@export var fade_in_duration: float = 0.35
@export var mid_delay: float = 0.05

var _busy: bool = false
var _fade_rect: ColorRect

func _ready() -> void:
	layer = 200
	_fade_rect = ColorRect.new()
	_fade_rect.color = Color(0, 0, 0, 0)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_fade_rect)


func change_scene(path: String, spawn_marker: StringName = &"") -> void:
	if path.is_empty() or _busy:
		return
	_busy = true
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	await _fade_to(1.0, fade_out_duration)
	if not spawn_marker.is_empty():
		get_tree().set_meta("aphelion_spawn_marker", spawn_marker)
	await get_tree().create_timer(mid_delay).timeout
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	await _fade_to(0.0, fade_in_duration)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_busy = false


func _fade_to(alpha: float, duration: float) -> void:
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_fade_rect, "color:a", alpha, maxf(duration, 0.01))
	await tween.finished
