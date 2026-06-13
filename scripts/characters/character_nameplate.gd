extends Node2D

@export var display_name: String = ""
@export var y_offset: float = 0.0

const NAMEPLATE_MEASURE_FONT := preload("res://assets/ui/SpecialElite-Regular.ttf")

const DEFAULT_DISPLAY_NAMES: Dictionary = {
	"ethan": "Ethan",
	"dominic": "Dominic",
	"victoria": "Victoria",
	"julian": "Julian",
	"luna": "Luna",
	"marcus": "Marcus",
	"valerie": "Valerie",
}

const DEFAULT_Y_OFFSETS: Dictionary = {
	"ethan": -46.0,
	"dominic": -50.0,
	"victoria": -50.0,
	"julian": -50.0,
	"luna": -50.0,
	"marcus": -50.0,
	"valerie": -40.0,
}

const TEXT_COLOR := Color(1.0, 0.97, 0.9, 1.0)
const OUTLINE_COLOR := Color(0.06, 0.04, 0.03, 1.0)
const PLATE_BG_COLOR := Color(0.08, 0.06, 0.05, 0.8)
const PLATE_BORDER_COLOR := Color(0.95, 0.86, 0.68, 0.42)
const FONT_SIZE := 13
const PLATE_HEIGHT := 20.0
const PLATE_HORIZONTAL_PADDING := 16.0

var _anchor_parent: Node2D
var _plate: PanelContainer
var _label: Label


func _ready() -> void:
	top_level = true
	z_as_relative = false
	z_index = 100
	_anchor_parent = get_parent() as Node2D
	_ensure_plate()
	_refresh_plate()
	_sync_to_parent()


func _physics_process(_delta: float) -> void:
	_sync_to_parent()


func _ensure_plate() -> void:
	var existing_plate := get_node_or_null("Plate")
	if existing_plate is PanelContainer:
		_plate = existing_plate as PanelContainer
	else:
		_plate = PanelContainer.new()
		_plate.name = "Plate"
		add_child(_plate)

	var margin := _plate.get_node_or_null("Margin") as MarginContainer
	if margin == null:
		margin = MarginContainer.new()
		margin.name = "Margin"
		_plate.add_child(margin)

	var center := margin.get_node_or_null("Center") as CenterContainer
	if center == null:
		center = CenterContainer.new()
		center.name = "Center"
		margin.add_child(center)

	var existing_label := center.get_node_or_null("Label")
	if existing_label is Label:
		_label = existing_label as Label
	else:
		_label = Label.new()
		_label.name = "Label"
		center.add_child(_label)

	_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 1)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 1)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_label.clip_text = false
	_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER


func _refresh_plate() -> void:
	var resolved_name := _get_resolved_display_name()
	var text_size: Vector2 = NAMEPLATE_MEASURE_FONT.get_string_size(
		resolved_name,
		HORIZONTAL_ALIGNMENT_CENTER,
		-1,
		FONT_SIZE
	)
	var plate_width: float = float(ceili(text_size.x)) + PLATE_HORIZONTAL_PADDING
	var settings := LabelSettings.new()
	settings.font_size = FONT_SIZE
	settings.font_color = TEXT_COLOR
	settings.outline_size = 5
	settings.outline_color = OUTLINE_COLOR
	var style := StyleBoxFlat.new()
	style.bg_color = PLATE_BG_COLOR
	style.border_color = PLATE_BORDER_COLOR
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_right = 4
	style.corner_radius_bottom_left = 4

	_plate.add_theme_stylebox_override("panel", style)
	_plate.custom_minimum_size = Vector2(plate_width, PLATE_HEIGHT)
	_plate.size = _plate.custom_minimum_size
	_plate.position = Vector2(-plate_width * 0.5, -PLATE_HEIGHT)
	_label.label_settings = settings
	_label.text = resolved_name


func _sync_to_parent() -> void:
	if _anchor_parent == null:
		_anchor_parent = get_parent() as Node2D
	if _anchor_parent == null:
		return
	global_position = _anchor_parent.global_position + Vector2(0.0, _get_resolved_y_offset())


func _get_resolved_display_name() -> String:
	if not display_name.is_empty():
		return display_name

	var key := _get_parent_key()
	if DEFAULT_DISPLAY_NAMES.has(key):
		return String(DEFAULT_DISPLAY_NAMES.get(key, key))
	return key.replace("_", " ").capitalize()


func _get_resolved_y_offset() -> float:
	if !is_zero_approx(y_offset):
		return y_offset

	var key := _get_parent_key()
	if DEFAULT_Y_OFFSETS.has(key):
		return float(DEFAULT_Y_OFFSETS.get(key, -72.0))
	return -72.0


func _get_parent_key() -> String:
	if _anchor_parent == null:
		return ""
	return _anchor_parent.name.to_lower()
