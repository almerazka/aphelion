extends Node

const TRACK_MAIN_MENU := preload("res://assets/audio/MainMenu.wav")
const TRACK_MAIN := preload("res://assets/audio/Main.wav")
const TRACK_EXECUTION := preload("res://assets/audio/Execution.wav")
const TRACK_LOSE := preload("res://assets/audio/Lose.wav")
const TRACK_WIN := preload("res://assets/audio/Win.wav")
const TRACK_PARTY := preload("res://assets/audio/Party.wav")
const TRACK_TALKING := preload("res://assets/audio/Talking.wav")

const SFX_SCREAM := preload("res://assets/audio/Scream.wav")
const SFX_WALK := preload("res://assets/audio/Walk.wav")

var _bgm_player: AudioStreamPlayer
var _walk_player: AudioStreamPlayer
var _sfx_player: AudioStreamPlayer
var _scene_bgm_blocked: bool = false
var _walk_loop_requested: bool = false
var _bgm_loop_requested: bool = false


func _ready() -> void:
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.name = "BGM"
	_bgm_player.bus = "Master"
	_bgm_player.volume_db = -8.0
	if not _bgm_player.finished.is_connected(_on_bgm_finished):
		_bgm_player.finished.connect(_on_bgm_finished)
	add_child(_bgm_player)

	_walk_player = AudioStreamPlayer.new()
	_walk_player.name = "WalkLoop"
	_walk_player.bus = "Master"
	_walk_player.volume_db = -9.0
	_walk_player.stream = SFX_WALK
	if not _walk_player.finished.is_connected(_on_walk_finished):
		_walk_player.finished.connect(_on_walk_finished)
	add_child(_walk_player)

	_sfx_player = AudioStreamPlayer.new()
	_sfx_player.name = "SFX"
	_sfx_player.bus = "Master"
	_sfx_player.volume_db = -6.0
	add_child(_sfx_player)

	var tree := get_tree()
	if tree.has_signal("scene_changed") and not tree.is_connected("scene_changed", Callable(self, "_on_scene_changed")):
		tree.connect("scene_changed", Callable(self, "_on_scene_changed"))
	elif tree.has_signal("current_scene_changed") and not tree.is_connected("current_scene_changed", Callable(self, "_on_current_scene_changed")):
		tree.connect("current_scene_changed", Callable(self, "_on_current_scene_changed"))

	call_deferred("_refresh_scene_bgm")


func _on_current_scene_changed(_scene: Node) -> void:
	_refresh_scene_bgm()


func _on_scene_changed() -> void:
	_refresh_scene_bgm()


func _refresh_scene_bgm() -> void:
	if _scene_bgm_blocked:
		return
	var current_scene := get_tree().current_scene
	if current_scene == null:
		return
	var path := String(current_scene.scene_file_path)
	if path == "res://scenes/main_menu/main_menu.tscn":
		play_main_menu_bgm()
		return
	if path == "res://scenes/main_menu/lose_screen.tscn":
		play_lose_bgm()
		return
	if path == "res://scenes/main_menu/win_screen.tscn":
		play_win_bgm()
		return
	if path == "res://scenes/cutscene/intro_start.tscn":
		return
	if path == "res://scenes/cutscene/crime_scene_intro.tscn":
		play_talking_bgm()
		return
	if path == "res://scenes/rooms/execution.tscn":
		play_execution_bgm()
		return
	play_main_bgm()


func lock_scene_bgm() -> void:
	_scene_bgm_blocked = true


func unlock_scene_bgm() -> void:
	_scene_bgm_blocked = false
	_refresh_scene_bgm()


func play_main_menu_bgm() -> void:
	_play_bgm(TRACK_MAIN_MENU)


func play_main_bgm() -> void:
	_play_bgm(TRACK_MAIN)


func play_execution_bgm() -> void:
	_play_bgm(TRACK_EXECUTION)


func play_lose_bgm() -> void:
	_play_bgm(TRACK_LOSE)


func play_win_bgm() -> void:
	_play_bgm(TRACK_WIN)


func play_party_bgm() -> void:
	_play_bgm(TRACK_PARTY)


func play_talking_bgm() -> void:
	_play_bgm(TRACK_TALKING)


func stop_bgm() -> void:
	_bgm_loop_requested = false
	_bgm_player.stop()


func play_scream() -> void:
	_sfx_player.stream = SFX_SCREAM
	_sfx_player.play()


func start_walk_loop() -> void:
	_walk_loop_requested = true
	if _walk_player.playing:
		return
	_walk_player.play()


func stop_walk_loop() -> void:
	_walk_loop_requested = false
	if not _walk_player.playing:
		return
	_walk_player.stop()


func _on_walk_finished() -> void:
	if _walk_loop_requested:
		_walk_player.play()


func _on_bgm_finished() -> void:
	if _bgm_loop_requested:
		_bgm_player.play()


func _play_bgm(stream: AudioStream) -> void:
	if stream == null:
		return
	_bgm_loop_requested = true
	if _bgm_player.stream == stream and _bgm_player.playing:
		return
	_bgm_player.stream = stream
	_bgm_player.play()
