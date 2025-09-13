extends Area3D

@export var npc_scene: PackedScene
@export var npc_spawn_location: NodePath        # Pfad auf einen PathFollow3D
@export var npc_scare_script: Script            # optional, z.B. scare.gd
@export var npc_trigger_path: NodePath          # optional: Pfad zum Trigger (Area3D o.ä.)
@export var npc_parent_path: NodePath           # optional: Ziel-Elternknoten (z.B. /root/Main/World/NPCs)

func interact(player: Node) -> void:
	if not player.is_in_group("player"):
		return

	print("🔑 Schlüssel aufgenommen!")
	if Engine.has_singleton("Objectives"):
		Engine.get_singleton("Objectives").set_flag("found_key", true)
		if Engine.get_singleton("Objectives").current_step < Engine.get_singleton("Objectives").JUMPSCARE:
			Engine.get_singleton("Objectives").set_step(Engine.get_singleton("Objectives").JUMPSCARE)

	# --- Spawn-Quelle: PathFollow3D finden ---
	var pf := get_node_or_null(npc_spawn_location)
	if pf == null or not (pf is PathFollow3D):
		printerr("⚠️ Spawn fehlgeschlagen: npc_spawn_location zeigt nicht auf PathFollow3D.")
		queue_free()
		return
	var path3d := pf.get_parent()
	if path3d == null or not (path3d is Path3D):
		printerr("⚠️ PathFollow3D ohne Path3D-Parent gefunden.")
		queue_free()
		return

	# --- Ziel-Eltern bestimmen ---
	var npc_parent: Node = get_node_or_null(npc_parent_path)
	if npc_parent == null:
		# Fallback: neben den Pfad hängen
		npc_parent = path3d.get_parent()

	# --- NPC instanziieren ---
	if npc_scene == null:
		printerr("⚠️ Kein npc_scene zugewiesen.")
		queue_free()
		return

	var npc := npc_scene.instantiate()
	if npc_scare_script:
		npc.set_script(npc_scare_script)

	npc_parent.add_child(npc)

	# Startpose: genau auf die aktuelle Pose des PathFollow setzen
	npc.global_transform = pf.global_transform

	# Orientierung optional (wenn dein Modell seitlich schaut)
	npc.rotate_y(deg_to_rad(90))  # anpassen/entfernen, falls nicht nötig

	print("✅ NPC gespawnt bei ", npc.global_transform.origin)

	# --- PathFollow auf yaw-only ---
	pf.rotation_mode = PathFollow3D.ROTATION_Y
	if pf.has_method("set_tilt_enabled"):
		pf.tilt_enabled = false

	# --- NPC mit Pfad verdrahten und starten ---
	if npc.has_method("set_follow_path"):
		npc.set_follow_path(path3d.get_path())
	else:
		push_warning("NPC hat keine set_follow_path(NodePath)-Methode.")

	if npc.has_method("start_path"):
		npc.start_path()
	else:
		push_warning("NPC hat keine start_path()-Methode.")

	# --- Trigger optional armen ---
	var trigger := get_node_or_null(npc_trigger_path)
	if trigger:
		if trigger.has_method("arm"):
			trigger.arm(pf)
		else:
			# Minimal: Path dem Trigger mitteilen, falls er so arbeitet
			if trigger.has_method("set"):
				trigger.set("path_follow_path", pf.get_path())
			if trigger.has_method("set_monitorable"):
				trigger.set_monitorable(true)
		print("🎯 Trigger vorbereitet")
	else:
		print("ℹ️ Kein Trigger verknüpft (optional)")

	# Schlüssel entfernen
	queue_free()
