extends Node3D

# -------------------- N O D E S --------------------
@onready var anim: AnimationPlayer = $AnimationPlayer
@export var player_root_path: NodePath     # optional: Player-Root zum Excluden


@export var animation_name: StringName = &"combined"

@export var muzzle_light_path: NodePath = ^"Muzzle/muzzleLight"
@export var shot_sound_path: NodePath  = ^"shot_sound"
@onready var muzzle_light: Node = get_node_or_null(muzzle_light_path)
@onready var s_shot: AudioStreamPlayer = get_node_or_null(shot_sound_path) as AudioStreamPlayer

# -------------------- A I M I N G  /  R A Y --------------------
@export var cam_path: NodePath = ^"/root/Main/FpsPlayer/Camera3D"  # FPS-Kamera
@export var muzzle_path: NodePath                                  # optional: echter Mündungs-Node
@onready var cam: Camera3D = get_node_or_null(cam_path) as Camera3D
@onready var player: CharacterBody3D = get_node_or_null(player_root_path) as CharacterBody3D
@onready var muzzle: Node3D = get_node_or_null(muzzle_path) as Node3D

@export var use_camera_ray: bool = true          # true = vom Crosshair, false = vom Muzzle
@export var max_distance: float = 120.0
@export_flags_3d_physics var ray_mask: int = -1  # DEBUG: alles treffen; später Welt+Manager-Layer setzen
@export var manager_group: StringName = &"manager"  # Manager-Root MUSS in dieser Gruppe sein

# -------------------- T I M I N G --------------------
@export var muzzle_flash_time: float = 0.1
@export var fire_cooldown: float = 0.5

# -------------------- D E B U G --------------------
@export var debug_logs: bool = true
@export var debug_draw_ray: bool = true
@export var debug_draw_hit: bool = true
@export var debug_ray_time: float = 2.0
@export var debug_ray_miss_color := Color(1, 0, 0, 1)   # rot
@export var debug_ray_hit_color  := Color(0, 1, 0, 1)   # grün
@export var debug_parent_path: NodePath                 # z.B. ^"/root/Main" oder ^"/root/FpsPlayer"
@export var debug_camera_offset: float = 0.5            # Ray-Start etwas vor die Kamera
@export var debug_ray_radius: float = 0.08              # Dicke des Zylinders
@export var debug_hit_radius: float = 0.15              # Größe der Treffer-Kugel
@export var debug_depth_draw_always: bool = true        # Ray immer sichtbar (on top)

# Falls in deiner Animation Visibility-Tracks sind (muzzleLight etc.), kannst du sie deaktivieren:
@export var disable_anim_visibility_tracks: bool = true

var _flash_left := 0.0
var _cd_left := 0.0
var _can_fire := true

func _ready() -> void:
	# Licht initial aus
	if muzzle_light:
		muzzle_light.visible = false
	# keine Autoplay-Anim
	if anim:
		anim.stop()
	# optional Visibility-Tracks deaktivieren
	if disable_anim_visibility_tracks and anim:
		_disable_visibility_tracks(animation_name)

func _process(delta: float) -> void:
	# Cooldown
	if _cd_left > 0.0:
		_cd_left -= delta

	# Flash sichtbar halten (überstimmt evtl. Anim-Tracks)
	if _flash_left > 0.0:
		_flash_left -= delta
		if muzzle_light:
			muzzle_light.visible = true
			muzzle_light.call_deferred("set", "visible", true)
	else:
		if muzzle_light and muzzle_light.visible:
			muzzle_light.visible = false
			muzzle_light.call_deferred("set", "visible", false)

	# Input
	if Input.is_action_pressed("shoot") and _cd_left <= 0.0 and _can_fire:
		_fire_once()

func _fire_once() -> void:
	if Objectives.state["has_gun"] == false:
		return
		
	_can_fire = false
	_cd_left = fire_cooldown
	_flash_left = muzzle_flash_time

	# Animation
	if anim:
		anim.play(animation_name, 0.0, 1.0, false)
		anim.seek(0.0, true)
	# Sound
	if s_shot:
		s_shot.play()

	# Hitscan
	_hitscan()

	# Sperre bis Cooldown vorbei
	await get_tree().create_timer(fire_cooldown).timeout
	_can_fire = true

# -------------------- H I T S C A N --------------------
func _hitscan() -> void:
	if cam == null and muzzle == null:
		if debug_logs: print("[gun] keine Kamera/Muzzle gefunden")
		return

	var from: Vector3
	var dir: Vector3
	if use_camera_ray and cam:
		from = cam.global_position
		dir  = -cam.global_transform.basis.z
		from += dir * debug_camera_offset   # Start leicht vor die Kamera
	else:
		var src := muzzle if muzzle != null else self
		from = src.global_position
		dir  = -src.global_transform.basis.z

	var to := from + dir * max_distance

	var space := get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(from, to)
	q.collision_mask = ray_mask
	q.hit_from_inside = false

	# Excludes (Waffe, Owner, optional Player-Root)
	var excludes: Array = [self]
	var own := get_owner()
	if own: excludes.append(own)
	var player_root := get_node_or_null(player_root_path)
	if player_root: excludes.append(player_root)
	q.exclude = excludes

	var res := space.intersect_ray(q)
	if res.is_empty():
		if debug_draw_ray: _debug_line(from, to, debug_ray_miss_color, debug_ray_time)
		if debug_logs: print("[gun] miss")
		return

	var hit_pos: Vector3 = res.get("position")
	if debug_draw_ray: _debug_line(from, hit_pos, debug_ray_hit_color, debug_ray_time)
	if debug_draw_hit: _debug_hit_marker(hit_pos, debug_hit_radius, debug_ray_time)

	_on_hit(res, dir)

func _on_hit(res: Dictionary, dir: Vector3) -> void:
	var collider := res.get("collider") as Node
	var pos: Vector3 = res.get("position")

	# bis zum Manager-Root hochlaufen (Gruppe 'manager')
	var mgr := _find_parent_in_group(collider, manager_group)
	if mgr:
		# One-Shot: zuerst die(), sonst apply_damage()
		if mgr.has_method("die"):
			mgr.call_deferred("die", pos, dir)
		elif mgr.has_method("apply_damage"):
			mgr.call_deferred("apply_damage", 9999.0, pos, dir)
		if debug_logs: print("[gun] manager hit at ", pos)
	else:
		if debug_logs: print("[gun] hit non-manager: ", collider, " at ", pos)

func _find_parent_in_group(n: Node, group: StringName) -> Node:
	var cur := n
	while cur:
		if cur.is_in_group(group):
			return cur
		cur = cur.get_parent()
	return null

# -------------------- D E B U G  R E N D E R --------------------
func _debug_parent() -> Node:
	var p := get_node_or_null(debug_parent_path)
	return p if p != null else get_tree().current_scene

func _debug_line(from: Vector3, to: Vector3, color: Color, secs: float) -> void:
	var dir := to - from
	var len := dir.length()
	if len < 0.001:
		return

	var mi := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = debug_ray_radius
	cyl.bottom_radius = debug_ray_radius
	cyl.height = len
	cyl.radial_segments = 16
	mi.mesh = cyl

	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = color
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED        # beidseitig
	if debug_depth_draw_always:
		mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_ALWAYS
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	# Y-Achse des Zylinders auf 'dir' ausrichten
	var y := dir.normalized()
	var x := y.cross(Vector3.FORWARD)
	if x.length() < 0.001:
		x = y.cross(Vector3.RIGHT)
	x = x.normalized()
	var z := x.cross(y).normalized()
	mi.global_transform = Transform3D(Basis(x, y, z), (from + to) * 0.5)

	# Sichtbarkeit an Kamera-Layern ausrichten
	if cam != null:
		mi.layers = cam.cull_mask

	var parent := _debug_parent()
	if parent: parent.add_child(mi)
	await get_tree().create_timer(secs).timeout
	if is_instance_valid(mi):
		mi.queue_free()

func _debug_hit_marker(pos: Vector3, radius: float, secs: float) -> void:
	var mi := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = radius
	s.height = radius * 2.0
	s.radial_segments = 16
	mi.mesh = s

	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1, 1, 0, 1)
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	if debug_depth_draw_always:
		mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_ALWAYS
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	mi.global_position = pos
	if cam != null:
		mi.layers = cam.cull_mask

	var parent := _debug_parent()
	if parent: parent.add_child(mi)
	await get_tree().create_timer(secs).timeout
	if is_instance_valid(mi):
		mi.queue_free()

# -------------------- H E L P E R --------------------
func _disable_visibility_tracks(anim_name: StringName) -> void:
	if anim == null:
		return
	var a: Animation = anim.get_animation(anim_name)
	if a == null:
		return
	for i in range(a.get_track_count()):
		if a.track_get_type(i) != Animation.TYPE_VALUE:
			continue
		var path: NodePath = a.track_get_path(i)
		if path.get_concatenated_subnames() == "visible":
			a.track_set_enabled(i, false)
