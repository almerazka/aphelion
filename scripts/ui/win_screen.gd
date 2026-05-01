extends Control

@export_file("*.tscn") var main_menu_scene_path: String = "res://scenes/main_menu/main_menu.tscn"

@onready var time_label: Label = $Center/VBox/TimeLabel
@onready var back_button: Button = $Center/VBox/BackButton


func _ready() -> void:
	var elapsed_text: String = "00:00:00"
	if has_node("/root/WorldState"):
		elapsed_text = WorldState.last_win_elapsed_text
	time_label.text = "Time Spent: %s" % elapsed_text

	if not back_button.pressed.is_connected(_on_back_pressed):
		back_button.pressed.connect(_on_back_pressed)


func _on_back_pressed() -> void:
	if has_node("/root/SceneTransition"):
		SceneTransition.change_scene(main_menu_scene_path)
	else:
		get_tree().change_scene_to_file(main_menu_scene_path)
