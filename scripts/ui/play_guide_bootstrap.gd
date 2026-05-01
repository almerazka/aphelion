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


func get_elapsed_seconds() -> float:
	if _play_guide_instance == null or not is_instance_valid(_play_guide_instance):
		return 0.0
	if _play_guide_instance.has_method("get_elapsed_seconds"):
		return float(_play_guide_instance.call("get_elapsed_seconds"))
	return 0.0


func get_formatted_elapsed() -> String:
	if _play_guide_instance == null or not is_instance_valid(_play_guide_instance):
		return "00:00:00"
	if _play_guide_instance.has_method("get_formatted_elapsed"):
		return String(_play_guide_instance.call("get_formatted_elapsed"))
	return "00:00:00"


func reset_session() -> void:
	if _play_guide_instance == null or not is_instance_valid(_play_guide_instance):
		return
	if _play_guide_instance.has_method("reset_session"):
		_play_guide_instance.call("reset_session")
