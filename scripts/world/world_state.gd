extends Node

signal world_mode_changed(is_shadow: bool)
signal shadow_unlocked_changed(unlocked: bool)

var shadow_unlocked: bool = false
var is_shadow_world: bool = false

var _canvas_modulate: CanvasModulate

const REAL_WORLD_COLOR := Color(1.0, 1.0, 1.0, 1.0)
const SHADOW_WORLD_COLOR := Color(0.28, 0.28, 0.35, 1.0)


func _ready() -> void:
	_canvas_modulate = CanvasModulate.new()
	_canvas_modulate.name = "WorldTint"
	_canvas_modulate.color = REAL_WORLD_COLOR
	get_tree().root.call_deferred("add_child", _canvas_modulate)
	# Allow quick testing in editor/debug builds without waiting story unlock.
	if OS.is_debug_build():
		shadow_unlocked = true


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("shadow_world"):
		switch_to_shadow_world()
		return
	if event.is_action_pressed("real_world"):
		switch_to_real_world()
		return


func unlock_shadow_world(start_in_shadow_world: bool = false) -> void:
	if shadow_unlocked:
		if start_in_shadow_world:
			switch_to_shadow_world()
		return

	shadow_unlocked = true
	emit_signal("shadow_unlocked_changed", shadow_unlocked)

	if start_in_shadow_world:
		switch_to_shadow_world()


func switch_to_shadow_world() -> void:
	if not shadow_unlocked:
		return
	_set_world_mode(true)


func switch_to_real_world() -> void:
	_set_world_mode(false)


func _set_world_mode(shadow_mode: bool) -> void:
	if is_shadow_world == shadow_mode:
		return

	is_shadow_world = shadow_mode
	_canvas_modulate.color = SHADOW_WORLD_COLOR if is_shadow_world else REAL_WORLD_COLOR
	emit_signal("world_mode_changed", is_shadow_world)
