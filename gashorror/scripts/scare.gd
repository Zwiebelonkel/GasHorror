extends CharacterBody3D

signal reached_destination(npc)

# --- Bewegung / Ausrichtung ---
@export var speed: float = 7.0
@export var height_offset: float = 0.0
@export var yaw_offset_deg: float = -90.0            # Ausrichtung relativ zur Pfadrichtung
@export var rotation_fix_deg := Vector3(0,0,0)       # Feinkorrektur XYZ in Grad
@export var end_extra_yaw_deg: float = 0.0           # EINMALIGE Zusatzdrehung am Ende (z. B. 180)

# --- Pfad (wird vom Spawner gesetzt; erwarte Path3D) ---
@export var follow_path: NodePath

# --- Skalierung ---
@export var scale_factor: float = 1.6
@export var visual_root_path: NodePath = NodePath("hillybilly")  # Mesh/Armature Root
@onready var visual_root: Node3D = get_node_or_null(visual_root_path) as Node3D
var _use_root_scale: bool = false
var _root_scale := Vector3.ONE

# --- Audio ---
@onready var s_jumpscare: Node = get_node_or_null("JumpscareSound") as Node
var _start_sound_played: bool = false

# --- Dialog nach Scare ---
@export var dialog_ui_path: NodePath = NodePath("/root/Main/dialog")
@onready var dialog_ui: Node = get_node_or_null(dialog_ui_path)
var _dialog_started: bool = false

# --- Intern ---
@onready var animation_player: AnimationPlayer = $hillybilly/AnimationPlayer
var _path3d: Path3D
var _pf: PathFollow3D
var _path_length: float = 0.0
var started: bool = false
var reached_end: bool = false

# Cache für exakte Endpose
var _cached_end_transform: Transform3D
var _cached_yaw: float = 0.0

func _ready() -> void:
	add_to_group("npc")

	# --- Skalierung robust ---
	if visual_root:
		visual_root.scale *= scale_factor
		if animation_player:
			animation_player.animation_started.connect(func(_n): if visual_root: visual_root.scale = Vector3.ONE * scale_factor)
	else:
		_use_root_scale = true
		_root_scale = Vector3.ONE * scale_factor

	# Inspector-Pfad übernehmen, falls gesetzt
	if has_node(follow_path):
		var node := get_node(follow_path)
		if node is Path3D:
			_assign_path(node)

	_play_idle()
	set_process(false) # Start per Trigger

# Vom Spawner gesetzt (Path3D)
func set_follow_path(p: NodePath) -> void:
	follow_path = p
	if has_node(follow_path):
		var n := get_node(follow_path)
		if n is Path3D:
			_assign_path(n)
		else:
			push_warning("set_follow_path(): Node ist kein Path3D")

func _assign_path(path: Path3D) -> void:
	_path3d = path
	_path_length = _path3d.curve.get_baked_length()
	_pf = null
	for c in _path3d.get_children():
		if c is PathFollow3D:
			_pf = c; break
	if _pf == null:
		_pf = PathFollow3D.new()
		_path3d.add_child(_pf)

	_pf.rotation_mode = PathFollow3D.ROTATION_Y
	_pf.loop = false
	_pf.progress = 0.0
	_pf.progress_ratio = 0.0

func start_path() -> void:
	if started: return
	if _path3d == null or _pf == null:
		push_warning("start_path(): Pfad nicht zugewiesen."); return

	_pf.loop = false
	_pf.progress = 0.0
	_pf.progress_ratio = 0.0
	reached_end = false
	started = true
	set_process(true)
	_play_walk()

	# Jumpscare-Sound genau beim Start
	if s_jumpscare and s_jumpscare.has_method("play") and not _start_sound_played:
		_start_sound_played = true
		s_jumpscare.call("play")

	print("▶️ NPC startet entlang des Pfades")

func _process(delta: float) -> void:
	if not started or reached_end or _pf == null or _path3d == null:
		return

	# Fortschritt clampen
	var next := _pf.progress + speed * delta
	if next >= _path_length:
		next = _path_length
	_pf.progress = next

	# Pose/Rotation DIESES FRAMES berechnen & cachen
	var t: Transform3D = _pf.global_transform
	var fwd := -t.basis.z.normalized()
	var yaw_this := atan2(fwd.x, fwd.z) + deg_to_rad(yaw_offset_deg)
	_cached_yaw = yaw_this

	var basis := Basis().rotated(Vector3.UP, yaw_this)
	basis = basis \
		* Basis().rotated(Vector3.RIGHT,   deg_to_rad(rotation_fix_deg.x)) \
		* Basis().rotated(Vector3.UP,      deg_to_rad(rotation_fix_deg.y)) \
		* Basis().rotated(Vector3.FORWARD, deg_to_rad(rotation_fix_deg.z))
	if _use_root_scale:
		basis = basis.scaled(_root_scale)

	var origin := t.origin + Vector3(0, height_offset, 0)
	var xform := Transform3D(basis, origin)
	global_transform = xform
	_cached_end_transform = xform

	if animation_player and animation_player.current_animation != "walk":
		_play_walk()

	# Ende: exakt diese Pose einfrieren (optional +180°) & stoppen
	if _pf.progress >= _path_length and not reached_end:
		reached_end = true
		_pf.progress = _path_length
		_pf.progress_ratio = 1.0

		var end_basis := Basis().rotated(Vector3.UP, _cached_yaw + deg_to_rad(end_extra_yaw_deg))
		end_basis = end_basis \
			* Basis().rotated(Vector3.RIGHT,   deg_to_rad(rotation_fix_deg.x)) \
			* Basis().rotated(Vector3.UP,      deg_to_rad(rotation_fix_deg.y)) \
			* Basis().rotated(Vector3.FORWARD, deg_to_rad(rotation_fix_deg.z))
		if _use_root_scale:
			end_basis = end_basis.scaled(_root_scale)

		global_transform = Transform3D(end_basis, _cached_end_transform.origin)

		_play_idle()
		set_process(false)
		emit_signal("reached_destination", self)
		print("🏁 NPC am Pfadende – Pose gefreezt.")

		# → Nach dem Scare automatisch Dialog starten
		_start_dialog_after_scare()

# ---- Dialog nach Scare ----
func _start_dialog_after_scare() -> void:
	if _dialog_started:
		return
	_dialog_started = true

	if dialog_ui == null:
		push_warning("Dialog UI nicht gefunden: " + str(dialog_ui_path))
		return
	if dialog_ui.has_method("is_active") and dialog_ui.is_active:
		return

	var lines := [
		"Du hast mich erschreckt!",
		"Entschuldigung. Ist hier die Toilette?",
		"Nein, ist sie nicht.",
		"Okay, auf Wiedersehen!"
	]

	if dialog_ui.has_method("show_dialog"):
		dialog_ui.show_dialog(lines, Callable(self, "_on_scare_dialog_finished"))
	else:
		push_warning("Dialog-Controller hat keine Methode show_dialog(lines, callback)")
		_on_scare_dialog_finished()

func _on_scare_dialog_finished() -> void:
	# Optional: Flag in Objectives setzen
	if typeof(Objectives) != TYPE_NIL and Objectives.has_method("set_flag"):
		Objectives.set_flag("jumpscare_done", true)
	# Hier verbleibt der NPC am Platz (steht ja schon). Falls entfernen gewünscht:
	queue_free()

# Optional: Spieler ansehen
func address_player(player: Node3D) -> void:
	var my := global_transform.origin
	var look := player.global_transform.origin
	look.y = my.y
	look_at(look, Vector3.UP)
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
