extends Area2D

@export_file("*.tscn") var target_scene: String
@export var target_spawn_marker: StringName = &""

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if target_scene.is_empty():
		return
	if not (body is CharacterBody2D):
		return
	if body.name != "Ethan":
		return
	if has_node("/root/SceneTransition"):
		SceneTransition.change_scene(target_scene, target_spawn_marker)
		return
	if not target_spawn_marker.is_empty():
		get_tree().set_meta("aphelion_spawn_marker", target_spawn_marker)
	get_tree().change_scene_to_file(target_scene)
