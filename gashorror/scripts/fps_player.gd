extends CharacterBody3D

@export var move_speed: float = 3.2
@export var run_mult: float = 1.8
@export var mouse_sens: float = 0.01     # 0.05–0.15 angenehm
@export var gravity: float = 9.8
@export var jump_strength: float = 2.0   # Sprungkraft
@export var crouch_speed: float = 1.6    # Crouch movement speed
@export var crouch_height: float = 0.5   # Crouch height (lowered height)
@export var normal_height: float = 2   # Normal height (standing)

@onready var cam: Camera3D = $Camera3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D  # Assuming your character has a CollisionShape3D node

var yaw: float = 0.0
var pitch: float = 0.0
var is_crouching: bool = false

func _ready() -> void:
	add_to_group("player")
	_capture_mouse(true)

func _input(event: InputEvent) -> void:
	# Mouse look (only when mouse is captured)
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		yaw   -= event.relative.x * mouse_sens
		pitch -= event.relative.y * mouse_sens
		pitch = clamp(pitch, deg_to_rad(-85.0), deg_to_rad(85.0))
		rotation.y = yaw
		cam.rotation.x = pitch

	# Toggle flashlight on/off
	if event.is_action_pressed("flashlight"):
		var lamp := cam.get_node_or_null("flashlight")
		if lamp:
			lamp.visible = !lamp.visible

	# Release or recapture mouse (ESC or left-click)
	if event.is_action_pressed("ui_cancel"):     # ESC → release
		_capture_mouse(false)
	elif event is InputEventMouseButton and event.pressed and Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
		_capture_mouse(true)

	# Crouch toggle (Ctrl key)
	#if event.is_action_pressed("crouch"):
		#is_crouching = !is_crouching
		#_toggle_crouch()

func _toggle_crouch() -> void:
	var capsule_shape: CapsuleShape3D = collision_shape.shape as CapsuleShape3D
	if capsule_shape:
		if is_crouching:
			capsule_shape.height = crouch_height  # Adjust height for crouching
			capsule_shape.radius = 0.5            # Adjust radius if necessary for crouch
			cam.position.y = crouch_height        # Lower the camera position to match crouch
		else:
			capsule_shape.height = normal_height  # Reset height to normal
			capsule_shape.radius = 0.6            # Reset radius to normal (adjust if needed)
			cam.position.y = normal_height        # Reset the camera height to normal

func _physics_process(delta: float) -> void:
	var dir := Vector3.ZERO
	if Input.is_action_pressed("move_forward"): dir -= transform.basis.z
	if Input.is_action_pressed("move_back"):    dir += transform.basis.z
	if Input.is_action_pressed("move_left"):    dir -= transform.basis.x
	if Input.is_action_pressed("move_right"):   dir += transform.basis.x
	dir.y = 0.0
	if dir != Vector3.ZERO:
		dir = dir.normalized()

	# Adjust movement speed when crouching
	var speed : float
	if is_crouching:
		speed = crouch_speed
	else:
		speed = move_speed

	if Input.is_action_pressed("run"):
		speed *= run_mult

	velocity.x = dir.x * speed
	velocity.z = dir.z * speed

	# Simple gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0
		
		# Jump if the spacebar (ui_accept) is pressed and the character is on the floor
		if Input.is_action_pressed("ui_accept"):  # Spacebar by default as "ui_accept"
			velocity.y = jump_strength

	move_and_slide()

func _capture_mouse(enable: bool) -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED if enable else Input.MOUSE_MODE_VISIBLE)
