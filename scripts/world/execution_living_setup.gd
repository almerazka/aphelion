extends Node2D

@export var ethan_node_path: NodePath = ^"Ethan"
@export var center_marker_path: NodePath = ^"ExecutionCenter"
@export var disable_exit_area: bool = true
@export var exit_area_path: NodePath = ^"ExitToLobby"

@export var dominic_scene: PackedScene = preload("res://scenes/characters/dominic.tscn")
@export var victoria_scene: PackedScene = preload("res://scenes/characters/victoria.tscn")
@export var julian_scene: PackedScene = preload("res://scenes/characters/julian.tscn")
@export var luna_scene: PackedScene = preload("res://scenes/characters/luna.tscn")
@export var marcus_scene: PackedScene = preload("res://scenes/characters/marcus.tscn")

const NPC_RING_ORDER: Array[String] = ["Dominic", "Victoria", "Julian", "Luna", "Marcus"]
const NPC_RING_OFFSETS: Dictionary = {
	"Dominic": Vector2(-132, -72),
	"Victoria": Vector2(-64, -114),
	"Julian": Vector2(0, -130),
	"Luna": Vector2(64, -114),
	"Marcus": Vector2(132, -72),
}

func _ready() -> void:
	_disable_exit_if_needed()
	_setup_execution_group()
	_unlock_post_execution_features()


func _disable_exit_if_needed() -> void:
	if not disable_exit_area:
		return
	var exit_area := get_node_or_null(exit_area_path)
	if exit_area is Area2D:
		(exit_area as Area2D).monitoring = false
		var shape := exit_area.get_node_or_null("CollisionShape2D")
		if shape is CollisionShape2D:
			(shape as CollisionShape2D).disabled = true


func _setup_execution_group() -> void:
	var center := _get_center_position()
	if center == Vector2.ZERO:
		return

	var scene_by_name := {
		"Dominic": dominic_scene,
		"Victoria": victoria_scene,
		"Julian": julian_scene,
		"Luna": luna_scene,
		"Marcus": marcus_scene,
	}

	for npc_name in NPC_RING_ORDER:
		var scene: PackedScene = scene_by_name.get(npc_name)
		if scene == null:
			continue
		var npc := get_node_or_null(NodePath(npc_name))
		if npc == null:
			npc = scene.instantiate()
			npc.name = npc_name
			add_child(npc)

		if npc is Node2D:
			var offset: Vector2 = NPC_RING_OFFSETS.get(npc_name, Vector2.ZERO)
			(npc as Node2D).global_position = center + offset

	var ethan := get_node_or_null(ethan_node_path)
	if ethan is Node2D:
		(ethan as Node2D).global_position = center + Vector2(0, 92)


func _get_center_position() -> Vector2:
	var center_marker := get_node_or_null(center_marker_path)
	if center_marker is Node2D:
		return (center_marker as Node2D).global_position

	var ethan := get_node_or_null(ethan_node_path)
	if ethan is Node2D:
		return (ethan as Node2D).global_position + Vector2(0, -20)

	return Vector2.ZERO


func _unlock_post_execution_features() -> void:
	if has_node("/root/ClueInventory"):
		ClueInventory.mark_execution_completed()
	if has_node("/root/WorldState"):
		WorldState.unlock_shadow_world(false)
