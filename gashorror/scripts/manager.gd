# manager.gd
extends CharacterBody3D

# --- Referenzen (im Inspector zuweisen) ---
@export var dialog_ui: CanvasLayer
@export var animation_player: AnimationPlayer
@export var manager_trigger: Area3D
@export var player_path: NodePath = NodePath()     # leer lassen -> per Gruppe "player"

# --- Animationen ---
@export var walk_anim: StringName = &"mixamo_com"
@export var idle_anim:  StringName = &"idle"

# --- Bewegung/Verhalten ---
@export var speed: float = 5.0
@export var turn_speed: float = 8.0                # weich zum Spieler drehen
@export var stop_distance: float = 1.5
@export var use_gravity: bool = true
@export var gravity: float = 9.8

# --- Ragdoll/Death ---
@export var skeleton_path:  NodePath               # -> Skeleton3D deines Models
@export var simulator_path: NodePath               # -> PhysicalBoneSimulator3D
@export var ragdoll_impulse: float = 18.0
@export var death_free_delay: float = 10.0         # 0 = liegen lassen
@export var auto_shrink_shapes_factor: float = 0.0 # z.B. 0.1 falls Shapes zu groß

# --- Debug ---
@export var debug_logs: bool = true

# --- intern ---
var _dialog_started := false
var _chase := false
var _player: Node3D
var _skeleton: Skeleton3D
var _sim: PhysicalBoneSimulator3D
var _dead := false
var _reacquire_timer := 0.0       # alle 0.5s den richtigen Player wählen

# -----------------------------------------------------------
# READY
# -----------------------------------------------------------
func _ready() -> void:
	if dialog_ui:
		dialog_ui.hide()

	# Trigger verbinden
	if manager_trigger and not manager_trigger.is_connected("body_entered", Callable(self, "_on_manager_trigger_entered")):
		manager_trigger.body_entered.connect(Callable(self, "_on_manager_trigger_entered"))

	# Player bestimmen
	_resolve_player(true)

	# Ragdoll-Komponenten holen
	_skeleton = get_node_or_null(skeleton_path) as Skeleton3D
	_sim      = get_node_or_null(simulator_path) as PhysicalBoneSimulator3D
	_bind_simulator_to_skeleton()

	# Shapes und Simulation zu Beginn AUS, damit nichts „flattert“
	if _skeleton:
		_set_pb_shapes_enabled(false)
		_skeleton.physical_bones_stop_simulation()
		_skeleton.reset_bone_poses()
		if auto_shrink_shapes_factor > 0.0:
			_shrink_ragdoll_shapes(_skeleton, auto_shrink_shapes_factor)

	# Logs ausgeben
	_log_ragdoll_setup()

# -----------------------------------------------------------
# PLAYER RESOLVE
# -----------------------------------------------------------
func _resolve_player(force_pick_nearest := false) -> void:
	# 1) expliziter Pfad
	if not force_pick_nearest and _player == null and player_path != NodePath():
		_player = get_node_or_null(player_path) as Node3D
		if _player:
			return

	# 2) per Gruppe "player"
	var candidates := get_tree().get_nodes_in_group("player")
	if candidates.is_empty():
		return

	if force_pick_nearest or candidates.size() > 1:
		_player = _pick_nearest_player(candidates)
	else:
		_player = candidates[0] as Node3D

func _pick_nearest_player(arr: Array) -> Node3D:
	var best: Node3D = null
	var best_d2 := INF
	for n in arr:
		if not (n is Node3D):
			continue
		var p := (n as Node3D).global_position
		var d2 := (p - global_position).length_squared()
		if d2 < best_d2:
			best_d2 = d2
			best = n
	return best

# -----------------------------------------------------------
# TRIGGER + DIALOG
# -----------------------------------------------------------
func _on_manager_trigger_entered(body: Node) -> void:
	if not body.is_in_group("player") or _dialog_started:
		return
	_dialog_started = true

	if dialog_ui and dialog_ui.has_method("show_dialog"):
		var lines := [
			"Manager: Was suchst du denn hier?",
			"Spieler: Was geht hier unten vor sich?",
			"Manager: Das hat dich einen Scheiß zu interessieren!",
			"Manager: Hättest du nicht einfach weiterarbeiten können?",
			"Spieler: Was sind das hier für Leute?",
			"Manager: Der Schmutz der Gesellschaft – sie werden hier 'gemolken' für das angesagteste Benzin.",
			"Spieler: Das kann so nicht weitergehen!",
			"Manager: Wie du meinst."
		]
		dialog_ui.show_dialog(lines, Callable(self, "_on_dialog_finished"))
	else:
		_on_dialog_finished()

	# Trigger nur einmal
	if manager_trigger:
		manager_trigger.queue_free()

func _on_dialog_finished() -> void:
	_resolve_player(true)
	_chase = true

# -----------------------------------------------------------
# MOVEMENT
# -----------------------------------------------------------
func _physics_process(delta: float) -> void:
	if _dead:
		return

	# alle 0.5 s ggf. richtigen Player neu wählen
	_reacquire_timer -= delta
	if _reacquire_timer <= 0.0:
		_reacquire_timer = 0.5
		_resolve_player(true)

	if _player == null or not is_instance_valid(_player):
		return

	if not _chase:
		velocity.x = 0.0
		velocity.z = 0.0
		if animation_player and animation_player.has_animation(idle_anim) and animation_player.current_animation != String(idle_anim):
			animation_player.play(String(idle_anim))
		if use_gravity:
			velocity.y = (velocity.y - gravity * delta) if not is_on_floor() else 0.0
		move_and_slide()
		return

	var from: Vector3 = global_position
	var to:   Vector3 = _player.global_position
	var dir:  Vector3 = to - from
	dir.y = 0.0
	var dist: float = dir.length()

	# weich zum Spieler drehen
	if dist > 0.001:
		var n := dir / dist
		var target_yaw := atan2(n.x, n.z)
		rotation.y = lerp_angle(rotation.y, target_yaw, turn_speed * delta)

	# laufen/stoppen
	var n2: Vector3 = (dir / dist) if dist > 0.0001 else Vector3.ZERO
	if dist > stop_distance:
		velocity.x = n2.x * speed
		velocity.z = n2.z * speed
		if animation_player and animation_player.has_animation(walk_anim) and animation_player.current_animation != String(walk_anim):
			animation_player.play(String(walk_anim))
	else:
		velocity.x = 0.0
		velocity.z = 0.0
		if animation_player and animation_player.has_animation(idle_anim) and animation_player.current_animation != String(idle_anim):
			animation_player.play(String(idle_anim))

	if use_gravity:
		velocity.y = (velocity.y - gravity * delta) if not is_on_floor() else 0.0

	move_and_slide()

# -----------------------------------------------------------
# DAMAGE / RAGDOLL
# -----------------------------------------------------------
# Wird von der Gun aufgerufen (ein Treffer reicht)
func apply_damage(_amount: float, hit_pos: Vector3, hit_dir: Vector3) -> void:
	die(hit_pos, hit_dir)

func die(hit_pos: Vector3 = global_position, hit_dir: Vector3 = Vector3.FORWARD) -> void:
	if _dead:
		return
	_dead = true

	_chase = false
	set_physics_process(false)
	velocity = Vector3.ZERO

	# CharacterBody-Kollision aus (nur Ragdoll soll kollidieren)
	collision_layer = 0
	collision_mask  = 0
	for c in get_children():
		if c is CollisionShape3D:
			(c as CollisionShape3D).disabled = true

	if animation_player:
		animation_player.stop()

	# Simulator sauber binden (falls noch nicht) und aktivieren
	_bind_simulator_to_skeleton()

	# PB-Shapes aktivieren, dann Simulation starten
	if _skeleton:
		_set_pb_shapes_enabled(true)

		# Simulator aktiv schalten (versch. Godot-Versionen absichern)
		if _sim:
			if _has_property(_sim, &"active"):
				_sim.active = true
			if _sim.has_method("set_physics_process"):
				_sim.set_physics_process(true)
			if _sim.has_method("set_process"):
				_sim.set_process(true)

		_skeleton.call_deferred("physical_bones_start_simulation")
		await get_tree().process_frame

		# kleiner Impuls in Schussrichtung
		var impulse := hit_dir.normalized() * ragdoll_impulse
		for n in _skeleton.get_children():
			if n is PhysicalBone3D:
				(n as PhysicalBone3D).apply_central_impulse(impulse)
				break

	# Auto-Despawn
	if death_free_delay > 0.0:
		await get_tree().create_timer(death_free_delay).timeout
		if is_instance_valid(self):
			queue_free()

# -----------------------------------------------------------
# Helpers
# -----------------------------------------------------------
func _bind_simulator_to_skeleton() -> void:
	if _sim == null or _skeleton == null:
		return
	# je nach Godot-Version 'skeleton' ODER 'skeleton_path'
	if _has_property(_sim, &"skeleton"):
		_sim.set(&"skeleton", _skeleton)
	elif _has_property(_sim, &"skeleton_path"):
		_sim.set(&"skeleton_path", _skeleton.get_path())

func _set_pb_shapes_enabled(enabled: bool) -> void:
	if _skeleton == null:
		return
	for n in _skeleton.get_children():
		if n is PhysicalBone3D:
			for ch in n.get_children():
				if ch is CollisionShape3D:
					ch.set_deferred("disabled", not enabled)

func _shrink_ragdoll_shapes(skel: Skeleton3D, factor: float) -> void:
	if skel == null:
		return
	for pb in skel.get_children():
		if pb is PhysicalBone3D:
			for ch in pb.get_children():
				if ch is CollisionShape3D and ch.shape:
					if ch.shape is CapsuleShape3D:
						var cap := ch.shape as CapsuleShape3D
						cap.radius *= factor
						cap.height *= factor
					elif ch.shape is BoxShape3D:
						(ch.shape as BoxShape3D).size *= factor
					elif ch.shape is SphereShape3D:
						(ch.shape as SphereShape3D).radius *= factor

# -------- Debug ----------
func _dbg(msg: String) -> void:
	if debug_logs:
		print("[manager] " + msg)

func _has_property(obj: Object, prop: StringName) -> bool:
	for info in obj.get_property_list():
		if info.has("name") and String(info["name"]) == String(prop):
			return true
	return false

func _log_ragdoll_setup() -> void:
	# Skeleton
	if _skeleton == null:
		_dbg("❌ Skeleton NICHT gefunden. skeleton_path=" + str(skeleton_path))
	else:
		_dbg("✅ Skeleton: " + str(_skeleton.get_path()) + " | bones=" + str(_skeleton.get_bone_count()))
		var pb_total := 0
		var shape_total := 0
		for n in _skeleton.get_children():
			if n is PhysicalBone3D:
				pb_total += 1
				var shapes_for_bone := 0
				for ch in n.get_children():
					if ch is CollisionShape3D:
						shapes_for_bone += 1
						shape_total += 1
				if pb_total <= 4:
					_dbg("  PB " + n.name + " | shapes=" + str(shapes_for_bone))
		_dbg("PB total=" + str(pb_total) + " | shapes total=" + str(shape_total))

	# Simulator
	if _sim == null:
		_dbg("❌ Simulator NICHT gefunden. simulator_path=" + str(simulator_path))
	else:
		_dbg("✅ Simulator: " + str(_sim.get_path()))
		if _has_property(_sim, &"skeleton"):
			_dbg("  sim.skeleton = " + str(_sim.get("skeleton")))
		elif _has_property(_sim, &"skeleton_path"):
			_dbg("  sim.skeleton_path = " + str(_sim.get("skeleton_path")))
		else:
			_dbg("  (Simulator hat weder 'skeleton' noch 'skeleton_path')")
		if _has_property(_sim, &"active"):
			_dbg("  sim.active=" + str(_sim.get("active")))
		_dbg("  sim.process=" + str(_sim.is_processing()) + " | sim.physics_process=" + str(_sim.is_physics_processing()))
