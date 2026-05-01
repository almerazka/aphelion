extends Control

@export_file("*.tscn") var main_menu_scene_path: String = "res://scenes/main_menu/main_menu.tscn"

@onready var back_button: Button = $Center/VBox/BackButton


func _ready() -> void:
	if not back_button.pressed.is_connected(_on_back_pressed):
		back_button.pressed.connect(_on_back_pressed)


func _on_back_pressed() -> void:
	if has_node("/root/SceneTransition"):
		SceneTransition.change_scene(main_menu_scene_path)
	else:
		get_tree().change_scene_to_file(main_menu_scene_path)
