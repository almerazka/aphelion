extends Node

const BACKGROUND_SCENE_PATH := "res://scenes/ui/global_background.tscn"

var _background_instance: CanvasLayer


func _ready() -> void:
	if _background_instance != null and is_instance_valid(_background_instance):
		return
	var scene_resource := load(BACKGROUND_SCENE_PATH)
	if scene_resource == null or not (scene_resource is PackedScene):
		push_error("GlobalBackground bootstrap failed to load scene: %s" % BACKGROUND_SCENE_PATH)
		return
	_background_instance = (scene_resource as PackedScene).instantiate() as CanvasLayer
	get_tree().root.add_child.call_deferred(_background_instance)
