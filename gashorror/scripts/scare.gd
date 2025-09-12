extends CharacterBody3D

signal reached_destination(npc)

@export var speed: float = 1.0
@export var follow_path: NodePath        # wird über set_follow_path gesetzt
@export var height_offset: float = 0.0
@export var rotation_fix_deg := Vector3(0.0, 0.0, 0.0)

@onready var animation_player: AnimationPlayer = $hillybilly/AnimationPlayer

var _pf: PathFollow3D
var started := false
var reached_end := false

func _ready() -> void:
	set_process(false)
	_play_idle()
	# Falls follow_path im Inspector gesetzt war:
	if has_node(follow_path):
		_pf = get_node(follow_path)

	# Optional: auf Objectives reagieren
	if has_node("/root/Objectives"):
		$"/root/Objectives".objective_changed.connect(_on_objective_changed)
	elif Engine.has_singleton("Objectives"):
		Engine.get_singleton("Objectives").objective_changed.connect(_on_objective_changed)

# === WICHTIG: öffentliche Setter-Methode für den Pfad ===
func set_follow_path(p: NodePath) -> void:
	follow_path = p
	if has_node(follow_path):
		_pf = get_node(follow_path)
	else:
		_pf = null

func _on_objective_changed(name: String, state: Dictionary) -> void:
	if state.has("found_key") and state["found_key"] == true:
		visible = true
		print("🔓 NPC sichtbar/aktiv (Start via Trigger)")

func _process(delta: float) -> void:
	if not started or reached_end or _pf == null:
		return

	_pf.progress += speed * delta

	# Pose vom PathFollow übernehmen (nur Yaw)
	var t := _pf.global_transform
	var forward := -t.basis.z.normalized()
	var yaw := atan2(forward.x, forward.z)

	var new_basis := Basis().rotated(Vector3.UP, yaw)
	new_basis = new_basis \
		* Basis().rotated(Vector3.RIGHT, deg_to_rad(rotation_fix_deg.x)) \
		* Basis().rotated(Vector3.UP,    deg_to_rad(rotation_fix_deg.y)) \
		* Basis().rotated(Vector3.FORWARD, deg_to_rad(rotation_fix_deg.z))

	var new_origin := t.origin + Vector3(0, height_offset, 0)
	global_transform = Transform3D(new_basis, new_origin)

	if animation_player and animation_player.current_animation != "walk":
		_play_walk()

	if _pf.progress_ratio >= 1.0 and not reached_end:
		reached_end = true
		_play_idle()
		emit_signal("reached_destination", self)
		print("🏁 NPC hat das Ziel erreicht.")

func start_path() -> void:
	if started:
		return
	if _pf == null and has_node(follow_path):
		_pf = get_node(follow_path)
	if _pf == null:
		push_warning("start_path(): follow_path nicht gesetzt / PF nicht gefunden.")
		return
	started = true
	set_process(true)
	_play_walk()
	print("▶️ NPC startet dem Pfad zu folgen")

func address_player(player: Node3D) -> void:
	var my_pos := global_transform.origin
	var look_pos := player.global_transform.origin
	look_pos.y = my_pos.y
	look_at(look_pos, Vector3.UP)
	_play_idle()

# --- Animation Helpers ---
func _play_idle() -> void:
	if animation_player and animation_player.has_animation("idle"):
		var anim = animation_player.get_animation("idle")
		anim.loop = true
		animation_player.play("idle")

func _play_walk() -> void:
	if animation_player and animation_player.has_animation("walk"):
		var anim = animation_player.get_animation("walk")
		anim.loop = true
		animation_player.play("walk")
