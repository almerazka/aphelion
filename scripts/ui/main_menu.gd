extends Control

@export_file("*.tscn") var start_scene_path: String = "res://scenes/cutscene/intro_start.tscn"

@onready var start_button: Button = $Center/VBox/StartButton
@onready var exit_button: Button = $Center/VBox/ExitButton


func _ready() -> void:
	if not start_button.pressed.is_connected(_on_start_pressed):
		start_button.pressed.connect(_on_start_pressed)
	if not exit_button.pressed.is_connected(_on_exit_pressed):
		exit_button.pressed.connect(_on_exit_pressed)


func _on_start_pressed() -> void:
	if has_node("/root/SceneTransition"):
		SceneTransition.change_scene(start_scene_path)
	else:
		get_tree().change_scene_to_file(start_scene_path)


func _on_exit_pressed() -> void:
	get_tree().quit()
