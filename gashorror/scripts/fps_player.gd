extends CharacterBody3D

@export var move_speed: float = 3.2
@export var run_mult: float = 1.8
@export var mouse_sens: float = 0.01
@export var gravity: float = 9.8
@export var jump_strength: float = 2.0
@export var crouch_speed: float = 1.6
@export var crouch_height: float = 0.5
@export var normal_height: float = 2.0

# Schritt-Tempo-Basis (Sekunden)
@export var step_interval_walk: float = 0.45
@export var step_interval_run_mult: float = 0.65      # schneller beim Rennen
@export var step_interval_crouch_mult: float = 1.4    # langsamer im Crouch
@export var step_pitch_jitter: float = 0.06           # ±6% Pitch-Variation

@onready var cam: Camera3D = $Camera3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var s_light: AudioStreamPlayer = $LightSound
@onready var s_step:  AudioStreamPlayer = $StepSound
@onready var step_timer: Timer = $StepTimer

var yaw: float = 0.0
var pitch: float = 0.0
var is_crouching: bool = false
var can_look := true
var keys: Array[String] = []


func _ready() -> void:
	add_to_group("player")
	_capture_mouse(true)
	randomize()
	if not step_timer.is_connected("timeout", Callable(self, "_on_step_timer_timeout")):
		step_timer.connect("timeout", Callable(self, "_on_step_timer_timeout"))

func _input(event: InputEvent) -> void:
	# Maus-Look
	if not can_look:
		return  # Input ignorieren, wenn nicht erlaubt
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		yaw   -= event.relative.x * mouse_sens
		pitch -= event.relative.y * mouse_sens
		pitch = clamp(pitch, deg_to_rad(-85.0), deg_to_rad(85.0))
		rotation.y = yaw
		cam.rotation.x = pitch

	# Taschenlampe toggeln + Sound
	if event.is_action_pressed("flashlight"):
		var lamp := cam.get_node_or_null("flashlight")
		if lamp:
			lamp.visible = !lamp.visible
		if s_light:
			s_light.play()

	# Maus-Capture toggeln
	if event.is_action_pressed("ui_cancel"):
		_capture_mouse(false)
	elif event is InputEventMouseButton and event.pressed and Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
		_capture_mouse(true)

	# (Optional) Crouch-Toggle, falls du eine Action "crouch" hast:
	# if event.is_action_pressed("crouch"):
	# 	is_crouching = !is_crouching
	# 	_toggle_crouch()

func _toggle_crouch() -> void:
	var capsule_shape: CapsuleShape3D = collision_shape.shape as CapsuleShape3D
	if capsule_shape:
		if is_crouching:
			capsule_shape.height = crouch_height
			capsule_shape.radius = 0.5
			cam.position.y = crouch_height
		else:
			capsule_shape.height = normal_height
			capsule_shape.radius = 0.6
			cam.position.y = normal_height

func _physics_process(delta: float) -> void:
	var dir := Vector3.ZERO
	if Input.is_action_pressed("move_forward"): dir -= transform.basis.z
	if Input.is_action_pressed("move_back"):    dir += transform.basis.z
	if Input.is_action_pressed("move_left"):    dir -= transform.basis.x
	if Input.is_action_pressed("move_right"):   dir += transform.basis.x
	dir.y = 0.0
	if dir != Vector3.ZERO:
		dir = dir.normalized()

	# Geschwindigkeit (ohne ?:)
	var speed: float = crouch_speed if is_crouching else move_speed
	var running := false
	if Input.is_action_pressed("run"):
		speed *= run_mult
		running = true

	velocity.x = dir.x * speed
	velocity.z = dir.z * speed

	# Gravity + Jump
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		if velocity.y < 0.0:
			velocity.y = 0.0
		if Input.is_action_pressed("ui_accept"):
			velocity.y = jump_strength

	move_and_slide()

	# Fußschritte an/aus je nach Bewegung
	_update_step_timer(dir, running)

func _update_step_timer(dir: Vector3, running: bool) -> void:
	var moving := dir.length() > 0.01
	if moving and is_on_floor():
		var interval := step_interval_walk
		if is_crouching:
			interval *= step_interval_crouch_mult
		if running:
			interval *= step_interval_run_mult
		if abs(step_timer.wait_time - interval) > 0.001:
			step_timer.wait_time = interval
		if step_timer.is_stopped():
			step_timer.start()
	else:
		if not step_timer.is_stopped():
			step_timer.stop()

func _on_step_timer_timeout() -> void:
	if s_step:
		var jitter := (randf() * 2.0 - 1.0) * step_pitch_jitter
		s_step.pitch_scale = 1.0 + jitter
		s_step.play()

func _capture_mouse(enable: bool) -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED if enable else Input.MOUSE_MODE_VISIBLE)

func has_key(key_name: String) -> bool:
	return key_name in keys


func add_key(name) -> void:
		keys.append(name)
