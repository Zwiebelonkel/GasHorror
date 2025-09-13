# scare.gd
extends CharacterBody3D

signal reached_destination(npc)

# --- Verhalten / Tuning ---
@export var speed: float = 1.0                  # Bewegungsgeschwindigkeit entlang des Pfades
@export var height_offset: float = 0.0          # vertikaler Offset zur PathFollow-Position
@export var scale_factor: float = 1.6           # NPC größer/kleiner
@export var yaw_offset_deg: float = 90.0        # konstante Y-Rotation (z.B. 90° nach rechts)
@export var rotation_fix_deg := Vector3(0,0,0)  # zusätzliche Feinrotationen (x,y,z in Grad)

# Der Pfad wird vom Spawner gesetzt: bitte den NodePath auf ein Path3D geben
@export var follow_path: NodePath               

@onready var animation_player: AnimationPlayer = $hillybilly/AnimationPlayer
@onready var s_jumpscare: AudioStreamPlayer = get_node_or_null("JumpscareSound") as AudioStreamPlayer

var _path3d: Path3D = null
var _pf: PathFollow3D = null
var _path_length: float = 0.0

var started := false
var reached_end := false
var _start_sound_played := false

func _ready() -> void:
	# Größe anwenden
	scale *= scale_factor

	# Wenn im Inspector bereits gesetzt: direkt zuweisen
	if has_node(follow_path):
		var n := get_node(follow_path)
		if n is Path3D:
			_assign_path(n)

	_play_idle()
	set_process(false)

	# Optional: Objectives-Hook
	if Engine.has_singleton("Objectives"):
		Engine.get_singleton("Objectives").objective_changed.connect(_on_objective_changed)

# Vom Spawner aufgerufen – bekommt den NodePath zu einem Path3D
func set_follow_path(p: NodePath) -> void:
	follow_path = p
	if has_node(follow_path):
		var n := get_node(follow_path)
		if n is Path3D:
			_assign_path(n)
		else:
			push_warning("set_follow_path(): Node ist kein Path3D")
	else:
		push_warning("set_follow_path(): NodePath nicht gefunden")

# Interne Zuordnung + Vorbereitung von PathFollow3D
func _assign_path(path: Path3D) -> void:
	_path3d = path
	_path_length = _path3d.curve.get_baked_length()
	_pf = null
	for c in _path3d.get_children():
		if c is PathFollow3D:
			_pf = c
			break
	if _pf == null:
		_pf = PathFollow3D.new()
		_path3d.add_child(_pf)
	_pf.rotation_mode = PathFollow3D.ROTATION_Y
	_pf.loop = false
	_pf.progress = 0.0
	_pf.progress_ratio = 0.0

# Optional: auf Ziele reagieren
func _on_objective_changed(_name: String, state: Dictionary) -> void:
	if state.has("found_key") and state["found_key"] == true:
		visible = true
		print("🔓 NPC sichtbar (Objective)")

# Start vom Spawner (key.gd) aus aufrufen
func start_path() -> void:
	if started:
		return
	if _path3d == null or _pf == null:
		push_warning("start_path(): Pfad nicht gesetzt.")
		return

	_pf.loop = false
	_pf.progress = 0.0
	_pf.progress_ratio = 0.0
	reached_end = false
	started = true
	set_process(true)
	_play_walk()

	# Jumpscare-Sound genau beim Start
	if s_jumpscare and not _start_sound_played:
		_start_sound_played = true
		s_jumpscare.play()

	print("▶️ NPC startet entlang des Pfades")

func _process(delta: float) -> void:
	if not started or reached_end or _pf == null or _path3d == null:
		return

	# --- Fortschritt berechnen und hart bis zum Ende clampen ---
	var next := _pf.progress + speed * delta
	if next >= _path_length:
		_pf.progress = _path_length
	else:
		_pf.progress = next

	# --- Pose/Rotation übernehmen ---
	var t := _pf.global_transform
	var fwd := -t.basis.z.normalized()
	var yaw := atan2(fwd.x, fwd.z) + deg_to_rad(yaw_offset_deg)

	var basis := Basis().rotated(Vector3.UP, yaw)
	basis = basis \
		* Basis().rotated(Vector3.RIGHT,   deg_to_rad(rotation_fix_deg.x)) \
		* Basis().rotated(Vector3.UP,      deg_to_rad(rotation_fix_deg.y)) \
		* Basis().rotated(Vector3.FORWARD, deg_to_rad(rotation_fix_deg.z))

	var origin := t.origin + Vector3(0, height_offset, 0)
	global_transform = Transform3D(basis, origin)

	# Animation konsistent halten
	if animation_player and animation_player.current_animation != "walk":
		_play_walk()

	# --- Ende erreicht? Dann endgültig stehen bleiben ---
	if _pf.progress >= _path_length and not reached_end:
		reached_end = true
		_pf.progress = _path_length
		_pf.progress_ratio = 1.0

		# Endpose sicher noch einmal setzen (exakt)
		var t_end := _pf.global_transform
		var f_end := -t_end.basis.z.normalized()
		var yaw_end := atan2(f_end.x, f_end.z) + deg_to_rad(yaw_offset_deg)
		var basis_end := Basis().rotated(Vector3.UP, yaw_end)
		basis_end = basis_end \
			* Basis().rotated(Vector3.RIGHT,   deg_to_rad(rotation_fix_deg.x)) \
			* Basis().rotated(Vector3.UP,      deg_to_rad(rotation_fix_deg.y)) \
			* Basis().rotated(Vector3.FORWARD, deg_to_rad(rotation_fix_deg.z))
		var origin_end := t_end.origin + Vector3(0, height_offset, 0)
		global_transform = Transform3D(basis_end, origin_end)

		_play_idle()
		set_process(false)
		emit_signal("reached_destination", self)
		print("🏁 NPC hat das Pfadende erreicht und bleibt stehen.")

# Spieler anblicken (optional aufrufbar)
func address_player(player: Node3D) -> void:
	var my_pos := global_transform.origin
	var look_pos := player.global_transform.origin
	look_pos.y = my_pos.y
	look_at(look_pos, Vector3.UP)
	_play_idle()

# --- Animation Helpers ---
func _play_idle() -> void:
	if animation_player and animation_player.has_animation("idle"):
		var anim := animation_player.get_animation("idle")
		anim.loop = true
		animation_player.play("idle")

func _play_walk() -> void:
	if animation_player and animation_player.has_animation("walk"):
		var anim := animation_player.get_animation("walk")
		anim.loop = true
		animation_player.play("walk")
