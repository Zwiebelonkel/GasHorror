extends CharacterBody3D

# -------- Movement ----------
@export var move_speed: float = 3.2
@export var run_mult: float = 1.8
@export var mouse_sens: float = 0.01
@export var gravity: float = 9.8
@export var jump_strength: float = 2.0
@export var crouch_speed: float = 1.6
@export var crouch_height: float = 0.5
@export var normal_height: float = 2.0

# -------- Footsteps ----------
@export var step_interval_walk: float = 0.45
@export var step_interval_run_mult: float = 0.65
@export var step_interval_crouch_mult: float = 1.4
@export var step_pitch_jitter: float = 0.06

# -------- Headbob (Camera) ----------
@export var bob_amp_x: float = 0.02
@export var bob_amp_y: float = 0.035
@export var bob_freq_walk: float = 7.0
@export var bob_freq_run: float  = 9.5
@export var bob_freq_crouch: float = 5.0
@export var bob_return_speed: float = 10.0

# -------- Weapon Sway (flashlight + gun) ----------
@export var flashlight_path: NodePath
@export var gun_path: NodePath
@export var pickup_group: StringName = &"PistolPickup"  # Gruppe der World-Pistolen

@export var sway_rot_deg_x: float = 1.5
@export var sway_rot_deg_y: float = 1.5
@export var sway_pos_x: float = 0.02
@export var sway_pos_y: float = 0.01
@export var sway_return_speed: float = 12.0
@export var sway_from_move_scale: float = 0.5
@export var weapon_scale := Vector3.ONE
@export var gunProp: Node3D  # Pfad zur Pistole, um sie später zu finden

@onready var pistol: Node3D  # Referenz zur Pistole
@onready var cam: Camera3D = $Camera3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var s_light: AudioStreamPlayer = $LightSound
@onready var s_step:  AudioStreamPlayer = $StepSound
@onready var step_timer: Timer = $StepTimer

# Sway-Halter (dürfen NICHT skaliert sein)
var flashlight: Node3D
var gun: Node3D

# intern
var yaw: float = 0.0
var pitch: float = 0.0
var is_crouching: bool = false
var can_look := true
var keys: Array[String] = []

# Headbob
var _bob_t: float = 0.0
var _cam_base_pos: Vector3

# Weapon sway
var _mouse_impulse := Vector2.ZERO
var _flash_base_pos: Vector3
var _gun_base_pos: Vector3
var _flash_base_rot := Basis.IDENTITY
var _gun_base_rot := Basis.IDENTITY

var has_pistol: bool = false  # Flag, ob der Spieler die Pistole hat

# Funktion zum Aufheben der Pistole
func pickup_pistol() -> void:
	if gun:
		has_pistol = true
		gun.visible = true  # Pistole sichtbar machen
		gun.position = Vector3(0.5, 0.5, 1.0)  # Positioniere die Pistole in der Hand des Spielers
		gun.rotation = cam.rotation  # Setze die Rotation der Pistole entsprechend der Kamera
		# Weitere Logik, um die Pistole dem Spieler zu geben
		_update_weapon_sway(0.0, Vector3.ZERO)  # Update für Waffen-Sway
		print("Pistole aufgenommen!")

func _ready() -> void:
	add_to_group("player")
	_capture_mouse(true)
		# Pistole wird nur verbunden, wenn sie im Spiel existiert
# Hand-Pistole holen und anfangs verstecken
	gun = cam.get_node_or_null(gun_path) as Node3D if gun_path != NodePath() else cam.get_node_or_null("gun") as Node3D
	if gun:
		gun.visible = false   # <— ganz wichtig: erst unsichtbar!

	# alle World-Pistol-Pickups automatisch verbinden (Gruppe: PistolPickup)
	for p in get_tree().get_nodes_in_group(pickup_group):
		if p.has_signal("picked_up"):
			print("Connecting")
			# Signal ohne Argumente – ruft _on_pistol_picked_up() auf
			p.connect("picked_up", Callable(self, "_on_pistol_picked_up"))

	# falls du zusätzlich eine einzelne Referenz im Inspector gesetzt hast (optional)
	# if gunProp and gunProp.has_signal("picked_up"):
	# 	gunProp.connect("picked_up", Callable(self, "_on_pistol_picked_up"))


	randomize()

	if not step_timer.is_connected("timeout", Callable(self, "_on_step_timer_timeout")):
		step_timer.connect("timeout", Callable(self, "_on_step_timer_timeout"))

	_cam_base_pos = cam.position

	# --- Sway-Halter suchen ---
	flashlight = null
	#gun = null
	if flashlight_path != NodePath():
		flashlight = cam.get_node_or_null(flashlight_path) as Node3D
	if gun_path != NodePath():
		gun = cam.get_node_or_null(gun_path) as Node3D
	# Fallbacks (an deine Szene angepasst)
	if flashlight == null:
		flashlight = cam.get_node_or_null("flashlightModel") as Node3D
	if gun == null:
		gun = cam.get_node_or_null("gun") as Node3D

	# --- Halter dürfen KEINE Scale haben; Scale kommt auf visuelle Kinder ---
	if flashlight:
		_make_holder_unscaled_and_scale_child(flashlight, weapon_scale)
		_flash_base_pos = flashlight.position
		_flash_base_rot = flashlight.transform.basis.orthonormalized()
	if gun:
		_make_holder_unscaled_and_scale_child(gun, weapon_scale)
		_gun_base_pos = gun.position
		_gun_base_rot = gun.transform.basis.orthonormalized()
		
func _on_pistol_picked_up() -> void:
	if has_pistol:
		return
	has_pistol = true

	# zur Sicherheit den Holder noch mal auflösen
	if gun == null:
		if gun_path != NodePath():
			gun = cam.get_node_or_null(gun_path) as Node3D
		if gun == null:
			gun = cam.get_node_or_null("gun") as Node3D

	if gun:
		gun.visible = true
		print("[player] Hand-Gun sichtbar:", gun.get_path())
	else:
		push_warning("[player] Hand-Gun-Holder nicht gefunden! Setze 'gun_path' korrekt (z.B. 'Camera3D/gun').")
		
func _make_holder_unscaled_and_scale_child(holder: Node3D, desired_scale: Vector3) -> void:
	# Finde ein visuelles Kind (z.B. "Node3D", Mesh, Armature). Nimm das erste Node3D-Kind.
	var visual: Node3D = null
	# bevorzugte Namen
	visual = holder.get_node_or_null("Node3D") as Node3D
	if visual == null:
		# nimm das erste Node3D-Kind, das nicht die Kamera o. ä. ist
		for c in holder.get_children():
			if c is Node3D:
				visual = c
				break

	if visual:
		# Parent-Scale in das visuelle Kind übertragen + gewünschte Scale anwenden
		var parent_scale := holder.scale
		holder.scale = Vector3.ONE
		visual.scale = visual.scale * parent_scale * desired_scale
	else:
		# Kein Kind gefunden → setze sicherheitshalber Holder-Scale zurück
		holder.scale = Vector3.ONE

func _input(event: InputEvent) -> void:
	if not can_look:
		return

	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		yaw   -= event.relative.x * mouse_sens
		pitch -= event.relative.y * mouse_sens
		pitch = clamp(pitch, deg_to_rad(-85.0), deg_to_rad(85.0))
		rotation.y = yaw
		cam.rotation.x = pitch

		_mouse_impulse += Vector2(event.relative.x, event.relative.y) * 0.01

	if event.is_action_pressed("flashlight"):
		var lamp := cam.get_node_or_null("flashlight")
		if lamp:
			lamp.visible = !lamp.visible
		if s_light:
			s_light.play()

	if event.is_action_pressed("ui_cancel"):
		_capture_mouse(false)
	elif event is InputEventMouseButton and event.pressed and Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
		_capture_mouse(true)

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
	if Input.is_action_pressed("move_forward"):
		dir -= transform.basis.z
	if Input.is_action_pressed("move_back"):
		dir += transform.basis.z
	if Input.is_action_pressed("move_left"):
		dir -= transform.basis.x
	if Input.is_action_pressed("move_right"):
		dir += transform.basis.x
	dir.y = 0.0
	if dir != Vector3.ZERO:
		dir = dir.normalized()

	var speed: float = crouch_speed if is_crouching else move_speed

	var running := false
	if Input.is_action_pressed("run"):
		speed *= run_mult
		running = true

	velocity.x = dir.x * speed
	velocity.z = dir.z * speed

	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		if velocity.y < 0.0:
			velocity.y = 0.0
		if Input.is_action_pressed("ui_accept"):
			velocity.y = jump_strength

	move_and_slide()

	_update_step_timer(dir, running)
	_update_headbob(delta, dir, running)
	_update_weapon_sway(delta, dir)

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

# ---------------- HEADBOB ----------------
func _update_headbob(delta: float, dir: Vector3, running: bool) -> void:
	var moving := dir.length() > 0.01 and is_on_floor()
	var target_pos: Vector3 = _cam_base_pos

	if moving:
		var freq: float = bob_freq_walk
		if is_crouching:
			freq = bob_freq_crouch
		elif running:
			freq = bob_freq_run

		_bob_t += delta * freq

		var offset_x: float = cos(_bob_t) * bob_amp_x
		var offset_y: float = absf(sin(_bob_t)) * bob_amp_y
		target_pos += Vector3(offset_x, offset_y, 0.0)
	else:
		_bob_t = lerp(_bob_t, 0.0, delta * 5.0)

	cam.position = cam.position.lerp(target_pos, clamp(bob_return_speed * delta, 0.0, 1.0))

# ---------------- WEAPON SWAY ----------------
func _update_weapon_sway(delta: float, dir: Vector3) -> void:
	# Impuls dämpfen
	_mouse_impulse = _mouse_impulse.lerp(Vector2.ZERO, clamp(sway_return_speed * delta, 0.0, 1.0))

	# Bewegungseinfluss
	var moving := dir.length() > 0.01 and is_on_floor()
	var move_bob := Vector2.ZERO
	if moving:
		move_bob.x = cos(_bob_t) * bob_amp_x * sway_from_move_scale
		move_bob.y = sin(_bob_t) * bob_amp_y * sway_from_move_scale

	var rot_x := -_mouse_impulse.y * deg_to_rad(sway_rot_deg_x)
	var rot_y := -_mouse_impulse.x * deg_to_rad(sway_rot_deg_y)
	var pos_x := -_mouse_impulse.x * sway_pos_x + move_bob.x
	var pos_y := -_mouse_impulse.y * sway_pos_y + move_bob.y

	# Flashlight sway (nur Rotation/Pos, keine Scale!)
	if flashlight:
		var tgt_basis := (_flash_base_rot
			* Basis(Vector3.RIGHT, rot_x)
			* Basis(Vector3.UP,    rot_y)).orthonormalized()

		var cur_basis := flashlight.transform.basis.orthonormalized()
		flashlight.transform.basis = cur_basis.slerp(
			tgt_basis, clamp(sway_return_speed * delta, 0.0, 1.0)
		).orthonormalized()

		var tgt_pos := _flash_base_pos + Vector3(pos_x, pos_y, 0.0)
		flashlight.position = flashlight.position.lerp(
			tgt_pos, clamp(sway_return_speed * delta, 0.0, 1.0)
		)

	# Gun sway
	if gun:
		var tgt_basis2 := (_gun_base_rot
			* Basis(Vector3.RIGHT, rot_x)
			* Basis(Vector3.UP,    rot_y)).orthonormalized()

		var cur_basis2 := gun.transform.basis.orthonormalized()
		gun.transform.basis = cur_basis2.slerp(
			tgt_basis2, clamp(sway_return_speed * delta, 0.0, 1.0)
		).orthonormalized()

		var tgt_pos2 := _gun_base_pos + Vector3(pos_x, pos_y, 0.0)
		gun.position = gun.position.lerp(
			tgt_pos2, clamp(sway_return_speed * delta, 0.0, 1.0)
		)

# ------------- Utility -------------
func _capture_mouse(enable: bool) -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED if enable else Input.MOUSE_MODE_VISIBLE)

func has_key(key_name: String) -> bool:
	return key_name in keys

func add_key(name) -> void:
	keys.append(name)
