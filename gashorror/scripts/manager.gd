extends CharacterBody3D

# --- Referenzen (im Inspector zuweisen) ---
@export var dialog_ui: CanvasLayer
@export var animation_player: AnimationPlayer
@export var manager_trigger: Area3D
@export var player_path: NodePath = NodePath()      # leer lassen → per Gruppe "player" wird gesucht
@export var sound: Node

# --- Animationen ---
@export var walk_anim: StringName = "mixamo_com"
@export var idle_anim: StringName = "idle"

# --- Bewegung/Verhalten ---
@export var speed: float = 5.0
@export var turn_speed: float = 8.0            # Yaw-Lerp
@export var stop_distance: float = 1.5
@export var use_gravity: bool = true
@export var gravity: float = 9.8

# --- Ragdoll/Death (nur Skeleton + PhysicalBone3D nötig; KEIN Simulator zwingend) ---
@export var skeleton_path: NodePath             # → dein Skeleton3D
@export var ragdoll_impulse: float = 18.0
@export var death_free_delay: float = 10.0      # 0 = liegen lassen
@export var auto_shrink_shapes_factor: float = 0.0  # z.B. 0.9 für -10%

# Auto-Freeze nach dem Umfallen (damit es ruhig wird)
@export var freeze_after_seconds: float = 0.8
@export var freeze_lin_vel: float = 0.08
@export var freeze_ang_vel: float = 0.25

# --- intern ---
var _dialog_started := false
var _chase := false
var _player: Node3D
var _skeleton: Skeleton3D
var _dead := false
var _reacquire_timer := 0.0

func _ready() -> void:
	if dialog_ui:
		dialog_ui.hide()

	if manager_trigger and not manager_trigger.is_connected("body_entered", Callable(self, "_on_manager_trigger_entered")):
		manager_trigger.body_entered.connect(Callable(self, "_on_manager_trigger_entered"))

	_resolve_player(true)

	_skeleton = get_node_or_null(skeleton_path) as Skeleton3D
	if _skeleton:
		# Ragdoll im Leerlauf wirklich AUS:
		_set_pb_shapes_enabled(false)
		_skeleton.physical_bones_stop_simulation()
		_skeleton.reset_bone_poses()
		if auto_shrink_shapes_factor > 0.0:
			_shrink_ragdoll_shapes(_skeleton, auto_shrink_shapes_factor)

func _resolve_player(force_pick_nearest := false) -> void:
	if not force_pick_nearest and _player == null and player_path != NodePath():
		_player = get_node_or_null(player_path) as Node3D
		if _player: return

	var candidates := get_tree().get_nodes_in_group("player")
	if candidates.is_empty(): return
	if force_pick_nearest or candidates.size() > 1:
		_player = _pick_nearest_player(candidates)
	else:
		_player = candidates[0] as Node3D

func _pick_nearest_player(arr: Array) -> Node3D:
	var best: Node3D = null
	var best_d2 := INF
	for n in arr:
		if not (n is Node3D): continue
		var p := (n as Node3D).global_position
		var d2 := (p - global_position).length_squared()
		if d2 < best_d2:
			best_d2 = d2
			best = n
	return best

func _on_manager_trigger_entered(body: Node) -> void:
	if not body.is_in_group("player") or _dialog_started:
		return
	_dialog_started = true
	sound.call("play")
	if dialog_ui and dialog_ui.has_method("show_dialog"):
		var lines := [
			{"speaker": "Manager", "text": "Was suchst du denn hier?"},
			{"speaker": "Spieler", "text": "Was geht hier unten vor sich?"},
			{"speaker": "Manager", "text": "Das hat dich einen Scheiß zu interessieren!"},
			{"speaker": "Manager", "text": "Hättest du nicht einfach weiterarbeiten können?"},
			{"speaker": "Spieler", "text": "Was sind das hier für Leute?"},
			{"speaker": "Manager", "text": "Der Schmutz der Gesellschaft – sie werden hier gemolken für das angesagteste Benzin."},
			{"speaker": "Spieler", "text": "Das kann so nicht weitergehen!"},
			{"speaker": "Manager", "text": "Wie du meinst."}
		]
		dialog_ui.show_dialog(lines, global_transform.origin, Callable(self, "_on_dialog_finished"))

	else:
		_on_dialog_finished()

	if manager_trigger:
		manager_trigger.queue_free()

func _on_dialog_finished() -> void:
	_resolve_player(true)
	_chase = true

func _physics_process(delta: float) -> void:
	if _dead: return

	# alle 0.5 s sicherheitshalber „richtigen“ Player wählen
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
	var to: Vector3 = _player.global_position
	var dir: Vector3 = to - from
	dir.y = 0.0
	var dist: float = dir.length()

	if dist > 0.001:
		var n := dir / dist
		var target_yaw := atan2(n.x, n.z)
		rotation.y = lerp_angle(rotation.y, target_yaw, turn_speed * delta)

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

# --- Treffer-API (One-Shot reicht) ---
func apply_damage(_amount: float, hit_pos: Vector3, hit_dir: Vector3) -> void:
	die(hit_pos, hit_dir)

func die(hit_pos: Vector3 = global_position, hit_dir: Vector3 = Vector3.FORWARD) -> void:
	if _dead: return
	_dead = true

	_chase = false
	set_physics_process(false)
	velocity = Vector3.ZERO

	# CharacterBody-Kollision aus, damit nur noch die PBs kollidieren
	collision_layer = 0
	collision_mask  = 0
	for c in get_children():
		if c is CollisionShape3D:
			(c as CollisionShape3D).disabled = true

	if animation_player:
		animation_player.stop()

	if _skeleton:
		_configure_ragdoll()                    # Dämpfung, Massen, Exceptions …
		_set_pb_shapes_enabled(true)
		_skeleton.physical_bones_start_simulation()

		# kleiner Impuls in Schussrichtung
		var impulse := hit_dir.normalized() * ragdoll_impulse
		for n in _skeleton.get_children():
			if n is PhysicalBone3D:
				(n as PhysicalBone3D).apply_central_impulse(impulse)
				break

		_auto_freeze_ragdoll()                  # schläft ein, wird ruhig

	# optionaler Autodespawn
	if death_free_delay > 0.0:
		await get_tree().create_timer(death_free_delay).timeout
		if is_instance_valid(self):
			queue_free()

# ---------------- Helpers (Ragdoll-Tuning) ----------------

func _configure_ragdoll() -> void:
	if _skeleton == null: return
	for n in _skeleton.get_children():
		if n is PhysicalBone3D:
			var pb := n as PhysicalBone3D
			# starke Dämpfung → kein Gezappel
			pb.linear_damp  = 1.0
			pb.angular_damp = 6.0
			pb.can_sleep = true

			# grobe Massen
			var name := pb.name.to_lower()
			if "hips" in name or "pelvis" in name:
				pb.mass = 12.0
			elif "spine" in name or "chest" in name:
				pb.mass = 9.0
			elif "head" in name:
				pb.mass = 5.0
			elif "thigh" in name or "upperleg" in name or "upper_arm" in name or "arm" in name:
				pb.mass = 3.5
			elif "calf" in name or "lowerleg" in name or "forearm" in name:
				pb.mass = 2.5
			else:
				pb.mass = 1.5

			# Parent/Child kollidieren nicht miteinander
			var parent_pb := pb.get_parent() as PhysicalBone3D
			if parent_pb:
				pb.add_collision_exception_with(parent_pb)
				parent_pb.add_collision_exception_with(pb)

			# (Optional) Shapes leicht schrumpfen
			for ch in pb.get_children():
				if ch is CollisionShape3D and ch.shape:
					if ch.shape is CapsuleShape3D:
						var cap := ch.shape as CapsuleShape3D
						cap.radius *= 0.9
					elif ch.shape is BoxShape3D:
						(ch.shape as BoxShape3D).size *= 0.9
					elif ch.shape is SphereShape3D:
						(ch.shape as SphereShape3D).radius *= 0.9

func _auto_freeze_ragdoll() -> void:
	await get_tree().create_timer(0.4).timeout  # kurz warten bis Aufschlag
	var still_time := 0.0
	var need: float = max(0.1, freeze_after_seconds)
	while still_time < need:
		await get_tree().physics_frame
		var moving := false
		for n in _skeleton.get_children():
			if n is PhysicalBone3D:
				var pb := n as PhysicalBone3D
				# falls deine Godot-Version das nicht hat, entferne diese Prüfung
				if pb.linear_velocity.length() > freeze_lin_vel or pb.angular_velocity.length() > freeze_ang_vel:
					moving = true
					break
		still_time = 0.0 if moving else still_time + (1.0 / float(Engine.physics_ticks_per_second))

	# einfrieren: Kollisionen aus & schlafen
	for n in _skeleton.get_children():
		if n is PhysicalBone3D:
			var pb := n as PhysicalBone3D
			pb.sleeping = true
			for ch in pb.get_children():
				if ch is CollisionShape3D:
					ch.set_deferred("disabled", true)

func _set_pb_shapes_enabled(enabled: bool) -> void:
	if _skeleton == null: return
	for n in _skeleton.get_children():
		if n is PhysicalBone3D:
			for ch in n.get_children():
				if ch is CollisionShape3D:
					ch.set_deferred("disabled", not enabled)

func _shrink_ragdoll_shapes(skel: Skeleton3D, factor: float) -> void:
	if skel == null: return
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
