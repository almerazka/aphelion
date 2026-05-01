extends Node

const PLAY_GUIDE_SCENE_PATH := "res://scenes/ui/play_guide.tscn"

var _play_guide_instance: CanvasLayer

func _ready() -> void:
	if _play_guide_instance != null and is_instance_valid(_play_guide_instance):
		return
	var scene_resource := load(PLAY_GUIDE_SCENE_PATH)
	if scene_resource == null or not (scene_resource is PackedScene):
		push_error("PlayGuide bootstrap gagal load scene: %s" % PLAY_GUIDE_SCENE_PATH)
		return
	_play_guide_instance = (scene_resource as PackedScene).instantiate() as CanvasLayer
	get_tree().root.add_child.call_deferred(_play_guide_instance)
