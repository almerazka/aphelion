extends CharacterBody2D

@export var speed: float = 150.0
@export var can_walk: bool = false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
var _last_dir: Vector2 = Vector2.DOWN

func _physics_process(_delta: float) -> void:
	if not can_walk:
		velocity = Vector2.ZERO
		_play_idle()
		move_and_slide()
		return

	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = input_dir * speed

	if input_dir != Vector2.ZERO:
		_last_dir = input_dir
		_play_walk(input_dir)
	else:
		_play_idle()

	move_and_slide()

func _play_walk(dir: Vector2) -> void:
	if absf(dir.x) > absf(dir.y):
		sprite.flip_h = dir.x < 0.0
		sprite.play("walk_right")
	else:
		sprite.flip_h = false
		if dir.y < 0.0:
			sprite.play("walk_up")
		else:
			sprite.play("walk_down")

func _play_idle() -> void:
	if absf(_last_dir.x) > absf(_last_dir.y):
		sprite.flip_h = _last_dir.x < 0.0
		sprite.play("walk_right")
		sprite.frame = 0
		sprite.pause()
	else:
		sprite.flip_h = false
		if _last_dir.y < 0.0:
			sprite.play("walk_up")
		else:
			sprite.play("walk_down")
		sprite.frame = 0
		sprite.pause()
