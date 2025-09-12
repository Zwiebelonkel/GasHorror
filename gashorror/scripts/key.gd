extends Area3D

@export var npc_scene: PackedScene
@export var npc_spawn_location: NodePath        # Pfad zu PathFollow3D
@export var npc_scare_script: Script            # optional
@export var npc_trigger_path: NodePath          # Pfad zu scare_trigger.gd
@export var npc_parent_path: NodePath           # wohin der NPC im Baum soll (z.B. /root/Main/World/NPCs)

func interact(player: Node) -> void:
	if not player.is_in_group("player"):
		return

	print("🔑 Schlüssel aufgenommen!")
	Objectives.set_flag("found_key", true)
	if Objectives.current_step < Objectives.JUMPSCARE:
		Objectives.set_step(Objectives.JUMPSCARE)

	var pf := get_node_or_null(npc_spawn_location) # MUSS PathFollow3D sein
	if pf == null or npc_scene == null:
		print("⚠️ Spawn-Daten fehlen oder falscher Pfad")
		queue_free()
		return

	# Ziel-Eltern für NPC (nicht als Kind unter PathFollow!)
	var npc_parent: Node = get_node_or_null(npc_parent_path)
	if npc_parent == null:
		npc_parent = pf.get_parent()

	# NPC instanziieren
	var npc := npc_scene.instantiate()
	if npc_scare_script:
		npc.set_script(npc_scare_script)
		print("📜 Script scare.gd zugewiesen")

	npc_parent.add_child(npc)
	npc.scale = npc.scale * 1.6
	npc.global_transform = pf.global_transform
	npc.rotate_y(deg_to_rad(90))

	print("✅ NPC gespawnt neben PathFollow bei ", npc.global_transform.origin)

	# PathFollow nur um Y rotieren lassen (kein Pitch/Roll)
	if pf.has_method("set_rotation_mode"):
		pf.rotation_mode = PathFollow3D.ROTATION_Y
	elif pf.has_method("set_tilt_enabled"):
		pf.tilt_enabled = false

	# -> WICHTIG: robust & typsicher: Methode statt has_variable()
	if npc.has_method("set_follow_path"):
		npc.set_follow_path(pf.get_path())
	else:
		push_warning("NPC hat keine Methode set_follow_path(NodePath). Bitte im npc.gd ergänzen.")

	# Trigger aktivieren/armen
	var trigger := get_node_or_null(npc_trigger_path)
	if trigger:
		if trigger.has_method("arm"):
			trigger.arm(pf)
		else:
			if trigger.has_method("set"):
				trigger.set("path_follow_path", pf.get_path())
			trigger.set_monitorable(true)
		print("🎯 Trigger vorbereitet und aktiviert")
	else:
		print("⚠️ Trigger nicht gefunden")

	queue_free() # Schlüssel entfernen
