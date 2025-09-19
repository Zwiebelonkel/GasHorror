extends CharacterBody3D

@export var shake_duration: float = 0.5      # Dauer des Shakes in Sekunden
@export var shake_strength: float = 0.1      # Stärke des Zitterns

var _is_shaking: bool = false
var _shake_timer: float = 0.0
var _original_position: Vector3

func _ready() -> void:
	_capture_mouse(false)
	start_shake(3, 0.05)  # (z. B. 0.7 Sekunden, 0.15 Stärke)


func _process(delta):
	if _is_shaking:
		_shake_timer -= delta
		if _shake_timer <= 0.0:
			global_position = _original_position
			_is_shaking = false
		else:
			var random_offset = Vector3(
				randf_range(-shake_strength, shake_strength),
				randf_range(-shake_strength, shake_strength),
				randf_range(-shake_strength, shake_strength)
			)
			global_position = _original_position + random_offset

func _capture_mouse(enable: bool) -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED if enable else Input.MOUSE_MODE_VISIBLE)

func start_shake(duration: float = 0.5, strength: float = 0.1):
	if not _is_shaking:
		_original_position = global_position
	shake_duration = duration
	shake_strength = strength
	_shake_timer = shake_duration
	_is_shaking = true
