extends Node2D

func _ready() -> void:
	var tree := get_tree()
	if not tree.has_meta("aphelion_spawn_marker"):
		return

	var marker_name: StringName = tree.get_meta("aphelion_spawn_marker")
	tree.remove_meta("aphelion_spawn_marker")
	if marker_name.is_empty():
		return

	var marker := get_node_or_null(NodePath(String(marker_name)))
	var ethan := get_node_or_null("Ethan")
	if marker == null or ethan == null:
		return

	if marker is Node2D and ethan is Node2D:
		_snap_ethan_to_marker(ethan as Node2D, marker as Node2D)


func _snap_ethan_to_marker(ethan: Node2D, marker: Node2D) -> void:
	ethan.global_position = marker.global_position
	var camera := ethan.get_node_or_null("Camera2D")
	if camera is Camera2D:
		var cam := camera as Camera2D
		cam.reset_smoothing()
