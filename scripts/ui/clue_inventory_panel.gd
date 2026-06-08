extends CanvasLayer

@export var toggle_action: StringName = &"clue"

const COVER_TEXTURE := preload("res://assets/ui/Sprites_Casebook/UI_TravelBook_BookCover01a.png")
const LEFT_PAGE_TEXTURE := preload("res://assets/ui/Sprites_Casebook/UI_TravelBook_BookPageLeft01a.png")
const RIGHT_PAGE_TEXTURE := preload("res://assets/ui/Sprites_Casebook/UI_TravelBook_BookPageRight01a.png")
const FRAME_TEXTURE := preload("res://assets/ui/Sprites_Casebook/UI_TravelBook_Frame01a.png")
const FRAME_SELECTED_TEXTURE := preload("res://assets/ui/Sprites_Casebook/UI_TravelBook_FrameSelect01b.png")
const POPUP_TEXTURE := preload("res://assets/ui/Sprites_Casebook/UI_TravelBook_Popup01a.png")
const SLOT_TEXTURE := preload("res://assets/ui/Sprites_Casebook/UI_TravelBook_Slot01a.png")
const STAR_TEXTURE := preload("res://assets/ui/Sprites_Casebook/UI_TravelBook_IconStar01a.png")
const TICK_TEXTURE := preload("res://assets/ui/Sprites_Casebook/UI_TravelBook_IconTick01a.png")
const LINE_TEXTURE := preload("res://assets/ui/Sprites_Casebook/UI_TravelBook_Line01a.png")

const SUSPECT_SCENES: Dictionary = {
	"dominic": "res://scenes/characters/dominic.tscn",
	"victoria": "res://scenes/characters/victoria.tscn",
	"julian": "res://scenes/characters/julian.tscn",
	"luna": "res://scenes/characters/luna.tscn",
	"marcus": "res://scenes/characters/marcus.tscn",
}

const INK_DARK := Color(0.24, 0.15, 0.1, 1.0)
const INK_SOFT := Color(0.41, 0.28, 0.19, 1.0)
const INK_MUTED := Color(0.54, 0.4, 0.29, 1.0)
const ACCENT := Color(0.64, 0.34, 0.18, 1.0)
const LIGHT_TEXT := Color(0.97, 0.89, 0.78, 1.0)
const ENTRY_SELECTED_TINT := Color(0.56, 0.35, 0.22, 1.0)
const ENTRY_UNSELECTED_TINT := Color(0.93, 0.84, 0.74, 0.84)
const PORTRAIT_FRAME_SELECTED_TINT := Color(0.44, 0.28, 0.19, 1.0)
const PORTRAIT_FRAME_UNSELECTED_TINT := Color(0.57, 0.42, 0.31, 0.8)

var _selected_key: String = ""
var _portrait_cache: Dictionary = {}

@onready var dimmer: ColorRect = $Dimmer
@onready var panel: Control = $BookPanel
@onready var book_cover: NinePatchRect = $BookPanel/BookCover
@onready var left_page_background: NinePatchRect = $BookPanel/ContentMargin/PageRow/LeftPage/PageBackground
@onready var right_page_background: NinePatchRect = $BookPanel/ContentMargin/PageRow/RightPage/PageBackground
@onready var left_marker: TextureRect = $BookPanel/ContentMargin/PageRow/LeftPage/ContentMargin/LeftVBox/HeaderRow/Marker
@onready var right_marker: TextureRect = $BookPanel/ContentMargin/PageRow/RightPage/ContentMargin/RightVBox/SelectedHeader/SelectedMarker
@onready var progress_card_background: NinePatchRect = $BookPanel/ContentMargin/PageRow/LeftPage/ContentMargin/LeftVBox/ProgressCard/CardBackground
@onready var controls_card_background: NinePatchRect = $BookPanel/ContentMargin/PageRow/RightPage/ContentMargin/RightVBox/ControlsCard/CardBackground
@onready var divider: TextureRect = $BookPanel/ContentMargin/PageRow/RightPage/ContentMargin/RightVBox/Divider
@onready var suspect_scroll: ScrollContainer = $BookPanel/ContentMargin/PageRow/LeftPage/ContentMargin/LeftVBox/SuspectScroll
@onready var suspect_list: VBoxContainer = $BookPanel/ContentMargin/PageRow/LeftPage/ContentMargin/LeftVBox/SuspectScroll/SuspectList
@onready var clue_scroll: ScrollContainer = $BookPanel/ContentMargin/PageRow/RightPage/ContentMargin/RightVBox/ClueScroll
@onready var clue_list: VBoxContainer = $BookPanel/ContentMargin/PageRow/RightPage/ContentMargin/RightVBox/ClueScroll/ClueList
@onready var progress_text: Label = $BookPanel/ContentMargin/PageRow/LeftPage/ContentMargin/LeftVBox/ProgressCard/CardMargin/ProgressText
@onready var notebook_title: Label = $BookPanel/ContentMargin/PageRow/LeftPage/ContentMargin/LeftVBox/HeaderRow/HeaderText/NotebookTitle
@onready var notebook_subtitle: Label = $BookPanel/ContentMargin/PageRow/LeftPage/ContentMargin/LeftVBox/HeaderRow/HeaderText/NotebookSubtitle
@onready var section_label: Label = $BookPanel/ContentMargin/PageRow/LeftPage/ContentMargin/LeftVBox/SectionLabel
@onready var left_footer: Label = $BookPanel/ContentMargin/PageRow/LeftPage/ContentMargin/LeftVBox/LeftFooter
@onready var selected_section_title: Label = $BookPanel/ContentMargin/PageRow/RightPage/ContentMargin/RightVBox/SelectedHeader/HeaderText/SelectedSectionTitle
@onready var selected_section_subtitle: Label = $BookPanel/ContentMargin/PageRow/RightPage/ContentMargin/RightVBox/SelectedHeader/HeaderText/SelectedSectionSubtitle
@onready var empty_state: Label = $BookPanel/ContentMargin/PageRow/RightPage/ContentMargin/RightVBox/EmptyState
@onready var controls_text: Label = $BookPanel/ContentMargin/PageRow/RightPage/ContentMargin/RightVBox/ControlsCard/CardMargin/ControlsText


func _ready() -> void:
	visible = false
	dimmer.visible = false
	panel.visible = false
	_apply_visual_theme()
	_connect_inventory_signal()
	_refresh()


func _input(event: InputEvent) -> void:
	if not panel.visible:
		if event.is_action_pressed(toggle_action):
			if _is_dialog_running():
				return
			_toggle_inventory(true)
			get_viewport().set_input_as_handled()
		return

	if _handle_open_inventory_input(event):
		get_viewport().set_input_as_handled()


func _toggle_inventory(prefer_latest_selection: bool = false) -> void:
	var next_visible := not panel.visible
	panel.visible = next_visible
	dimmer.visible = next_visible
	visible = next_visible
	if next_visible:
		_refresh(prefer_latest_selection)
	_set_player_walk_state(not next_visible)


func _handle_open_inventory_input(event: InputEvent) -> bool:
	if event.is_action_pressed(toggle_action):
		_toggle_inventory()
		return true

	if not (event is InputEventKey):
		return false

	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return false

	if _matches_key(key_event, KEY_ESCAPE):
		_toggle_inventory()
		return true
	if _matches_any_key(key_event, [KEY_W, KEY_UP, KEY_A, KEY_LEFT]):
		_move_selection(-1)
		return true
	if _matches_any_key(key_event, [KEY_S, KEY_DOWN, KEY_D, KEY_RIGHT]):
		_move_selection(1)
		return true
	if _matches_key(key_event, KEY_HOME):
		_select_boundary_section(true)
		return true
	if _matches_key(key_event, KEY_END):
		_select_boundary_section(false)
		return true

	return true


func _set_player_walk_state(can_move: bool) -> void:
	var owner_node := get_parent()
	if owner_node == null:
		return
	for property in owner_node.get_property_list():
		if String(property.get("name", "")) == "can_walk":
			owner_node.set("can_walk", can_move)
			return


func _is_dialog_running() -> bool:
	if not has_node("/root/Dialogic"):
		return false
	return Dialogic.current_timeline != null


func _connect_inventory_signal() -> void:
	if not has_node("/root/ClueInventory"):
		return
	if not ClueInventory.clues_updated.is_connected(_on_clues_updated):
		ClueInventory.clues_updated.connect(_on_clues_updated)


func _on_clues_updated() -> void:
	_refresh()


func _refresh(prefer_latest_selection: bool = false) -> void:
	var sections: Array[Dictionary] = _get_sections()
	_ensure_valid_selection(sections, prefer_latest_selection)
	_update_progress(sections)
	_rebuild_suspect_list(sections)
	_update_selected_page(sections)


func _get_sections() -> Array[Dictionary]:
	if not has_node("/root/ClueInventory"):
		return []
	return ClueInventory.get_unlocked_sections()


func _ensure_valid_selection(sections: Array[Dictionary], prefer_latest_selection: bool) -> void:
	if sections.is_empty():
		_selected_key = ""
		return

	if _find_section_index(sections, _selected_key) != -1:
		return

	var fallback_index := 0
	if prefer_latest_selection:
		fallback_index = sections.size() - 1
	_selected_key = String(sections[fallback_index].get("key", ""))


func _update_progress(sections: Array[Dictionary]) -> void:
	if not has_node("/root/ClueInventory"):
		progress_text.text = "Clue inventory autoload is not active."
		return

	var clue_total := 0
	for section in sections:
		var clues: Array = section.get("clues", [])
		clue_total += clues.size()

	var interviewed := ClueInventory.get_unlocked_npc_count()
	var required: int = maxi(ClueInventory.get_required_npc_count(), 1)
	var summary_line := "Witnesses interviewed: %d/%d" % [interviewed, required]
	var notes_line := "Notes archived: %d" % clue_total

	if ClueInventory.has_shadow_dominic_clue():
		notes_line += "   |   Shadow lead secured"

	progress_text.text = "%s\n%s" % [summary_line, notes_line]


func _rebuild_suspect_list(sections: Array[Dictionary]) -> void:
	_clear_children(suspect_list)

	if sections.is_empty():
		var placeholder := Label.new()
		placeholder.text = "No interview files yet.\nQuestion each guest to build the notebook."
		placeholder.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		placeholder.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		placeholder.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		placeholder.size_flags_vertical = Control.SIZE_EXPAND_FILL
		placeholder.add_theme_color_override("font_color", INK_SOFT)
		placeholder.add_theme_font_size_override("font_size", 16)
		suspect_list.add_child(placeholder)
		return

	for section in sections:
		var is_selected := String(section.get("key", "")) == _selected_key
		var entry := _build_section_entry(section, is_selected)
		suspect_list.add_child(entry)
		if is_selected:
			call_deferred("_scroll_suspect_entry_into_view", entry)


func _build_section_entry(section: Dictionary, is_selected: bool) -> Control:
	var entry := Control.new()
	entry.custom_minimum_size = Vector2(0, 60)
	entry.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var background := NinePatchRect.new()
	background.anchor_right = 1.0
	background.anchor_bottom = 1.0
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_setup_nine_patch(
		background,
		FRAME_SELECTED_TEXTURE if is_selected else FRAME_TEXTURE,
		8,
		5,
		8,
		5
	)
	background.self_modulate = ENTRY_SELECTED_TINT if is_selected else ENTRY_UNSELECTED_TINT
	entry.add_child(background)

	var portrait_frame := NinePatchRect.new()
	portrait_frame.anchor_top = 0.5
	portrait_frame.anchor_bottom = 0.5
	portrait_frame.offset_left = 12.0
	portrait_frame.offset_top = -15.0
	portrait_frame.offset_right = 42.0
	portrait_frame.offset_bottom = 15.0
	portrait_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_setup_nine_patch(portrait_frame, SLOT_TEXTURE, 6, 6, 6, 6)
	portrait_frame.self_modulate = PORTRAIT_FRAME_SELECTED_TINT if is_selected else PORTRAIT_FRAME_UNSELECTED_TINT
	entry.add_child(portrait_frame)

	var portrait := TextureRect.new()
	portrait.anchor_right = 1.0
	portrait.anchor_bottom = 1.0
	portrait.offset_left = 4.0
	portrait.offset_top = 4.0
	portrait.offset_right = -4.0
	portrait.offset_bottom = -4.0
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var portrait_texture: Texture2D = _get_section_portrait(String(section.get("key", "")))
	_setup_texture_rect(
		portrait,
		portrait_texture if portrait_texture != null else STAR_TEXTURE,
		TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	)
	portrait_frame.add_child(portrait)

	var button := Button.new()
	button.anchor_right = 1.0
	button.anchor_bottom = 1.0
	button.offset_left = 54.0
	button.offset_top = 3.0
	button.offset_right = -12.0
	button.offset_bottom = -3.0
	button.flat = true
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.text = String(section.get("name", "UNKNOWN"))
	button.clip_text = true
	button.add_theme_color_override("font_color", LIGHT_TEXT if is_selected else INK_SOFT)
	button.add_theme_color_override("font_hover_color", LIGHT_TEXT if is_selected else INK_SOFT)
	button.add_theme_color_override("font_pressed_color", LIGHT_TEXT if is_selected else INK_SOFT)
	button.add_theme_font_size_override("font_size", 17)
	button.pressed.connect(_on_section_selected.bind(String(section.get("key", ""))))
	entry.add_child(button)

	return entry


func _on_section_selected(section_key: String) -> void:
	_selected_key = section_key
	_refresh()


func _move_selection(direction: int) -> void:
	var sections: Array[Dictionary] = _get_sections()
	if sections.is_empty():
		return

	var current_index := _find_section_index(sections, _selected_key)
	if current_index == -1:
		current_index = 0

	var next_index := clampi(current_index + direction, 0, sections.size() - 1)
	if next_index == current_index:
		return

	_selected_key = String(sections[next_index].get("key", ""))
	_refresh()


func _select_boundary_section(select_first: bool) -> void:
	var sections: Array[Dictionary] = _get_sections()
	if sections.is_empty():
		return

	var boundary_index := 0 if select_first else sections.size() - 1
	_selected_key = String(sections[boundary_index].get("key", ""))
	_refresh()


func _find_section_index(sections: Array[Dictionary], section_key: String) -> int:
	for index in range(sections.size()):
		if String(sections[index].get("key", "")) == section_key:
			return index
	return -1


func _update_selected_page(sections: Array[Dictionary]) -> void:
	_clear_children(clue_list)

	if not has_node("/root/ClueInventory"):
		selected_section_title.text = "NOTEBOOK OFFLINE"
		selected_section_subtitle.text = "The clue inventory singleton is missing."
		empty_state.text = "ClueInventory autoload is not active."
		empty_state.visible = true
		clue_scroll.visible = false
		_set_right_header_marker(STAR_TEXTURE, false)
		return

	if sections.is_empty():
		selected_section_title.text = "NO NOTES YET"
		selected_section_subtitle.text = "Question the guests to unlock entries."
		empty_state.text = "Talk to the guests first.\nEach interview unlocks a new page of notes."
		empty_state.visible = true
		clue_scroll.visible = false
		_set_right_header_marker(STAR_TEXTURE, false)
		return

	var selected_index: int = maxi(_find_section_index(sections, _selected_key), 0)
	var section: Dictionary = sections[selected_index]
	var clue_entries: Array = section.get("clues", [])
	var section_key := String(section.get("key", ""))
	var section_name := String(section.get("name", "UNKNOWN"))

	selected_section_title.text = section_name
	selected_section_subtitle.text = _build_selected_section_subtitle(section_key, clue_entries.size())
	empty_state.visible = false
	clue_scroll.visible = true

	var portrait_texture: Texture2D = _get_section_portrait(section_key)
	_set_right_header_marker(
		portrait_texture if portrait_texture != null else STAR_TEXTURE,
		portrait_texture != null
	)

	for clue_index in range(clue_entries.size()):
		clue_list.add_child(_build_clue_card(clue_index + 1, String(clue_entries[clue_index])))


func _build_selected_section_subtitle(section_key: String, clue_count: int) -> String:
	if section_key == "shadow_dominic":
		return "Hidden evidence recovered. %d lead%s recorded." % [clue_count, "" if clue_count == 1 else "s"]
	return "%d statement%s logged for review." % [clue_count, "" if clue_count == 1 else "s"]


func _build_clue_card(card_number: int, clue_text: String) -> Control:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", _make_stylebox_texture(POPUP_TEXTURE, 8, 8, 8, 8))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 12)
	card.add_child(margin)

	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 6)
	margin.add_child(content)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	content.add_child(header)

	var badge := TextureRect.new()
	badge.custom_minimum_size = Vector2(15, 15)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_setup_texture_rect(badge, TICK_TEXTURE, TextureRect.STRETCH_KEEP_ASPECT_CENTERED)
	header.add_child(badge)

	var note_title := Label.new()
	note_title.text = "NOTE %02d" % card_number
	note_title.add_theme_color_override("font_color", ACCENT)
	note_title.add_theme_font_size_override("font_size", 15)
	header.add_child(note_title)

	var body := Label.new()
	body.text = clue_text
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_color_override("font_color", INK_DARK)
	body.add_theme_font_size_override("font_size", 16)
	content.add_child(body)

	return card


func _apply_visual_theme() -> void:
	_setup_nine_patch(book_cover, COVER_TEXTURE, 12, 12, 12, 12)
	_setup_nine_patch(left_page_background, LEFT_PAGE_TEXTURE, 10, 10, 10, 10)
	_setup_nine_patch(right_page_background, RIGHT_PAGE_TEXTURE, 10, 10, 10, 10)
	_setup_nine_patch(progress_card_background, POPUP_TEXTURE, 8, 8, 8, 8)
	_setup_nine_patch(controls_card_background, POPUP_TEXTURE, 8, 8, 8, 8)

	_setup_texture_rect(left_marker, STAR_TEXTURE, TextureRect.STRETCH_KEEP_ASPECT_CENTERED)
	left_marker.custom_minimum_size = Vector2(18, 18)
	left_marker.modulate = Color(1, 1, 1, 1)

	_set_right_header_marker(STAR_TEXTURE, false)

	_setup_texture_rect(divider, LINE_TEXTURE)
	divider.modulate = Color(0.6, 0.36, 0.18, 0.8)

	notebook_title.add_theme_color_override("font_color", INK_DARK)
	notebook_title.add_theme_font_size_override("font_size", 28)
	notebook_subtitle.add_theme_color_override("font_color", ACCENT)
	notebook_subtitle.add_theme_font_size_override("font_size", 15)
	section_label.add_theme_color_override("font_color", ACCENT)
	section_label.add_theme_font_size_override("font_size", 17)
	progress_text.add_theme_color_override("font_color", INK_DARK)
	progress_text.add_theme_font_size_override("font_size", 16)
	progress_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left_footer.text = "C close   |   W/S or Arrow Keys"
	left_footer.add_theme_color_override("font_color", INK_MUTED)
	left_footer.add_theme_font_size_override("font_size", 11)
	left_footer.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	selected_section_title.add_theme_color_override("font_color", INK_DARK)
	selected_section_title.add_theme_font_size_override("font_size", 22)
	selected_section_title.autowrap_mode = TextServer.AUTOWRAP_OFF
	selected_section_subtitle.add_theme_color_override("font_color", ACCENT)
	selected_section_subtitle.add_theme_font_size_override("font_size", 13)
	selected_section_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	empty_state.add_theme_color_override("font_color", INK_SOFT)
	empty_state.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	controls_text.text = "Open a file, or browse with W/S or Arrow Keys."
	controls_text.add_theme_color_override("font_color", INK_DARK)
	controls_text.add_theme_font_size_override("font_size", 13)
	controls_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


func _set_right_header_marker(texture: Texture2D, use_portrait_scale: bool) -> void:
	right_marker.custom_minimum_size = Vector2(66, 66) if use_portrait_scale else Vector2(18, 18)
	right_marker.modulate = Color(1, 1, 1, 1)
	_setup_texture_rect(right_marker, texture, TextureRect.STRETCH_KEEP_ASPECT_CENTERED)


func _get_section_portrait(section_key: String) -> Texture2D:
	var base_key := _get_base_section_key(section_key)
	if base_key.is_empty():
		return null
	if _portrait_cache.has(base_key):
		return _portrait_cache.get(base_key) as Texture2D

	var scene_path := String(SUSPECT_SCENES.get(base_key, ""))
	var portrait_texture := _extract_portrait_from_scene(scene_path)
	if portrait_texture == null:
		return null

	var head_texture := _crop_portrait_head(portrait_texture)
	_portrait_cache[base_key] = head_texture
	return head_texture


func _get_base_section_key(section_key: String) -> String:
	if section_key == "shadow_dominic":
		return "dominic"
	return section_key.to_lower()


func _extract_portrait_from_scene(scene_path: String) -> Texture2D:
	if scene_path.is_empty():
		return null

	var packed := load(scene_path)
	if not (packed is PackedScene):
		return null

	var node := (packed as PackedScene).instantiate()
	if node == null:
		return null

	var portrait_texture: Texture2D = null
	var sprite := node.get_node_or_null("AnimatedSprite2D")
	if sprite is AnimatedSprite2D:
		var animated_sprite := sprite as AnimatedSprite2D
		var frames := animated_sprite.sprite_frames
		if frames != null:
			var animation := "walk_down"
			if not frames.has_animation(animation):
				var names := frames.get_animation_names()
				if names.size() > 0:
					animation = String(names[0])
			if not animation.is_empty() and frames.get_frame_count(animation) > 0:
				portrait_texture = frames.get_frame_texture(animation, 0)

	node.free()
	return portrait_texture


func _crop_portrait_head(texture: Texture2D) -> Texture2D:
	if texture == null:
		return null

	var image := texture.get_image()
	if image.is_empty():
		return texture

	var width := image.get_width()
	var height := image.get_height()
	var crop_width: int = maxi(int(round(float(width) * 0.72)), 1)
	var crop_height: int = maxi(int(round(float(height) * 0.58)), 1)
	var crop_x: int = maxi(int((float(width - crop_width)) * 0.5), 0)
	var portrait_image := image.get_region(Rect2i(crop_x, 0, crop_width, crop_height))
	return ImageTexture.create_from_image(portrait_image)


func _setup_nine_patch(
	rect: NinePatchRect,
	texture: Texture2D,
	margin_left: int,
	margin_top: int,
	margin_right: int,
	margin_bottom: int
) -> void:
	rect.texture = texture
	rect.patch_margin_left = margin_left
	rect.patch_margin_top = margin_top
	rect.patch_margin_right = margin_right
	rect.patch_margin_bottom = margin_bottom
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func _setup_texture_rect(
	rect: TextureRect,
	texture: Texture2D,
	stretch_mode: int = TextureRect.STRETCH_SCALE
) -> void:
	rect.texture = texture
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	rect.stretch_mode = stretch_mode
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE


func _make_stylebox_texture(
	texture: Texture2D,
	margin_left: int,
	margin_top: int,
	margin_right: int,
	margin_bottom: int
) -> StyleBoxTexture:
	var stylebox := StyleBoxTexture.new()
	stylebox.texture = texture
	stylebox.texture_margin_left = margin_left
	stylebox.texture_margin_top = margin_top
	stylebox.texture_margin_right = margin_right
	stylebox.texture_margin_bottom = margin_bottom
	stylebox.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
	stylebox.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
	stylebox.draw_center = true
	return stylebox


func _scroll_suspect_entry_into_view(entry: Control) -> void:
	if entry == null or suspect_scroll == null:
		return

	var entry_top := int(entry.position.y)
	var entry_bottom := int(entry.position.y + entry.size.y)
	var visible_top := suspect_scroll.scroll_vertical
	var visible_bottom := visible_top + int(suspect_scroll.size.y)

	if entry_top < visible_top:
		suspect_scroll.scroll_vertical = entry_top
	elif entry_bottom > visible_bottom:
		suspect_scroll.scroll_vertical = maxi(entry_bottom - int(suspect_scroll.size.y), 0)


func _clear_children(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()


func _matches_any_key(event: InputEventKey, keycodes: Array[int]) -> bool:
	for keycode in keycodes:
		if _matches_key(event, keycode):
			return true
	return false


func _matches_key(event: InputEventKey, keycode: int) -> bool:
	return event.keycode == keycode or event.physical_keycode == keycode
