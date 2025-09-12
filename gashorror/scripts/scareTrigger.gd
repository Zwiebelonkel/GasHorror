extends Area3D

@export var path_follow_path: NodePath  # Pfad zu PathFollow3D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	set_monitorable(false)
	print("Trigger _ready(), path_follow_path: ", path_follow_path)

func arm(pf: Node) -> void:
	if pf == null:
		push_warning("arm(): PathFollow3D ist null")
		return
	path_follow_path = pf.get_path()
	set_monitorable(true)
	print("Trigger ge-armed und aktiv. PF: ", path_follow_path)

func _on_body_entered(body: Node) -> void:
	print("Body entered: ", body.name)
	if not body.is_in_group("player"):
		print("Body ist kein Spieler.")
		return

	var pf := get_node_or_null(path_follow_path)
	if pf == null:
		print("⚠️ PathFollow3D nicht gefunden: ", path_follow_path)
		return

	var npc := _find_npc_near_pf(pf)
	if npc == null:
		await get_tree().process_frame
		npc = _find_npc_near_pf(pf)
		if npc == null:
			print("⚠️ Kein NPC gefunden")
			return

	npc.start_path()
	print("🚶 NPC startet durch Trigger")
	queue_free()

func _find_npc_near_pf(pf: Node) -> Node:
	var parent := pf.get_parent()
	for c in parent.get_children():
		if c.has_method("start_path"):
			return c
	for c in get_tree().get_current_scene().get_children():
		if c.has_method("start_path"):
			return c
	return null
