extends Area3D

@export var path_follow_path: NodePath  # Pfad zu PathFollow3D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	set_monitorable(false)
	print("Trigger _ready(), PF:", path_follow_path)

func arm(pf: PathFollow3D) -> void:
	if pf == null:
		push_warning("arm(): PathFollow3D ist null"); return
	path_follow_path = pf.get_path()
	set_monitorable(true)
	print("🎯 Trigger ge-armed. PF:", path_follow_path)

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return

	var pf := get_node_or_null(path_follow_path) as PathFollow3D
	if pf == null:
		printerr("⚠️ PathFollow3D nicht gefunden:", path_follow_path); return

	var npc := _find_npc_near_pf(pf)
	if npc == null:
		await get_tree().process_frame
		npc = _find_npc_near_pf(pf)
		if npc == null:
			printerr("⚠️ Kein NPC mit start_path() gefunden."); return

	npc.call_deferred("start_path")
	print("🚶 NPC startet (Trigger)")
	queue_free()

func _find_npc_near_pf(pf: PathFollow3D) -> Node:
	var pf_pos: Vector3 = pf.global_transform.origin
	var best: Node = null
	var best_d: float = INF

	# 1) Gruppe "npc" bevorzugen
	for n in get_tree().get_nodes_in_group("npc"):
		if not (n is Node3D): continue
		var n3d := n as Node3D
		if n3d.has_method("start_path"):
			var d: float = n3d.global_transform.origin.distance_to(pf_pos)
			if d < best_d:
				best_d = d; best = n3d
	if best != null:
		return best

	# 2) Parent von PF
	var parent := pf.get_parent()
	for c in parent.get_children():
		if (c is Node3D) and c.has_method("start_path"):
			return c

	# 3) Szene
	var scene := get_tree().current_scene
	if scene:
		for c in scene.get_children():
			if (c is Node3D) and c.has_method("start_path"):
				return c

	return null
