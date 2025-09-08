extends CharacterBody3D

@export var move_speed: float = 3.2
@export var run_mult: float = 1.8
@export var mouse_sens: float = 0.01     # 0.05–0.15 angenehm
@export var gravity: float = 9.8

@onready var cam: Camera3D = $Camera3D

var yaw: float = 0.0
var pitch: float = 0.0

func _ready() -> void:
	add_to_group("player")
	_capture_mouse(true)

func _input(event: InputEvent) -> void:
	# Maus-Look (nur wenn Maus gecaptured ist)
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		yaw   -= event.relative.x * mouse_sens
		pitch -= event.relative.y * mouse_sens
		pitch = clamp(pitch, deg_to_rad(-85.0), deg_to_rad(85.0))
		rotation.y = yaw
		cam.rotation.x = pitch

	# Taschenlampe ein/aus
	if event.is_action_pressed("flashlight"):
		var lamp := cam.get_node_or_null("SpotLight3D")
		if lamp:
			lamp.visible = !lamp.visible

	# Maus freigeben / wieder fangen
	if event.is_action_pressed("ui_cancel"):     # ESC → freigeben
		_capture_mouse(false)
	elif event is InputEventMouseButton and event.pressed and Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
		_capture_mouse(true)                     # Klick ins Fenster → wieder capturen

func _physics_process(delta: float) -> void:
	var dir := Vector3.ZERO
	if Input.is_action_pressed("move_forward"): dir -= transform.basis.z
	if Input.is_action_pressed("move_back"):    dir += transform.basis.z
	if Input.is_action_pressed("move_left"):    dir -= transform.basis.x
	if Input.is_action_pressed("move_right"):   dir += transform.basis.x
	dir.y = 0.0
	if dir != Vector3.ZERO:
		dir = dir.normalized()

	var speed := move_speed
	if Input.is_action_pressed("run"):
		speed *= run_mult

	velocity.x = dir.x * speed
	velocity.z = dir.z * speed

	# einfache Schwerkraft
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

	move_and_slide()

func _capture_mouse(enable: bool) -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED if enable else Input.MOUSE_MODE_VISIBLE)
