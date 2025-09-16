extends Node

# --- Einstellungen ---
@export var cam_path: NodePath = ^"/root/Main/FpsPlayer/Camera3D"   # FPS-Kamera
@export var muzzle_path: NodePath                                   # optional: Mündungs-Node
@export var max_distance: float = 120.0
@export var fire_rate: float = 7.0                                  # Schüsse/Sek
@export_flags_3d_physics var ray_mask: int = 0                      # Welt + Manager-Layer anhaken
@export var debug_logs: bool = false

@onready var cam: Camera3D = get_node_or_null(cam_path) as Camera3D
@onready var muzzle: Node3D = get_node_or_null(muzzle_path) as Node3D

var _can_fire := true

func _process(_dt: float) -> void:
	if Input.is_action_pressed("shoot"):
		_try_fire()

func _try_fire() -> void:
	if not _can_fire:
		return
	_can_fire = false
	_fire_once()
	if fire_rate > 0.0:
		await get_tree().create_timer(1.0 / fire_rate).timeout
	_can_fire = true

func _fire_once() -> void:
	if cam == null and muzzle == null:
		if debug_logs: print("[gun] Keine Kamera/Muzzle gefunden")
		return

	var from: Vector3
	var dir: Vector3
	if cam:
		from = cam.global_position
		dir  = -cam.global_transform.basis.z
	else:
		from = muzzle.global_position
		dir  = -muzzle.global_transform.basis.z

	var to := from + dir * max_distance

	var space := get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(from, to)
	q.collision_mask = ray_mask                 # Welt + Manager aktivieren
	q.hit_from_inside = true
	q.exclude = [get_owner()]                   # sich selbst ausschließen

	var res := space.intersect_ray(q)
	if res.is_empty():
		if debug_logs: print("[gun] miss")
		return

	_on_hit(res, dir)

func _on_hit(res: Dictionary, dir: Vector3) -> void:
	var collider := res.get("collider") as Node
	var pos: Vector3 = res.get("position")
	var mgr := _find_parent_in_group(collider, "manager")
	if mgr:
		# One-Shot: direkt sterben lassen (oder apply_damage aufrufen)
		if mgr.has_method("die"):
			mgr.call_deferred("die", pos, dir)
		elif mgr.has_method("apply_damage"):
			mgr.call_deferred("apply_damage", 9999.0, pos, dir)
		if debug_logs: print("[gun] manager hit at ", pos)
	else:
		if debug_logs: print("[gun] hit non-manager: ", collider)

func _find_parent_in_group(n: Node, group: StringName) -> Node:
	var cur := n
	while cur:
		if cur.is_in_group(group):
			return cur
		cur = cur.get_parent()
	return null
