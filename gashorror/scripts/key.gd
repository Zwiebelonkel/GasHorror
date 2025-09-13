extends Area3D

@export var npc_scene: PackedScene
@export var npc_spawn_location: NodePath        # auf ein PathFollow3D unter Path3D
@export var npc_scare_script: Script            # optional (z. B. scare.gd)
@export var npc_parent_path: NodePath           # optional Ziel-Parent (z. B. /root/Main/NPCs)
@export var trigger_path: NodePath              # Area3D mit scareTrigger.gd

func interact(player: Node) -> void:
	if not player.is_in_group("player"):
		return

	print("🔑 Schlüssel aufgenommen")
	# Autoload direkt benutzen
	Objectives.set_flag("has_key", true)

	# Optional: Objective Schritt setzen (falls noch nicht)
	if Objectives.current_step < Objectives.POWER_ON:
		Objectives.set_step(Objectives.POWER_ON)

	queue_free() # Schlüssel verschwinden lassen



	var pf := get_node_or_null(npc_spawn_location)
	if pf == null or not (pf is PathFollow3D):
		printerr("⚠️ npc_spawn_location muss auf PathFollow3D zeigen."); queue_free(); return
	var path3d := pf.get_parent()
	if path3d == null or not (path3d is Path3D):
		printerr("⚠️ PathFollow3D ohne Path3D-Parent."); queue_free(); return

	var npc_parent := get_node_or_null(npc_parent_path)
	if npc_parent == null:
		npc_parent = path3d.get_parent()

	if npc_scene == null:
		printerr("⚠️ npc_scene fehlt."); queue_free(); return
	var npc := npc_scene.instantiate()
	if npc_scare_script:
		npc.set_script(npc_scare_script)

	npc_parent.add_child(npc)
	# Startpose an aktuelle PF-Pose (keine zusätzliche Rotation hier!)
	npc.global_transform = pf.global_transform

	if npc.has_method("set_follow_path"):
		npc.set_follow_path(path3d.get_path())
	else:
		push_warning("NPC hat keine set_follow_path(NodePath)-Methode.")

	# Trigger armen
	var trig := get_node_or_null(trigger_path)
	if trig and trig.has_method("arm"):
		trig.arm(pf)

	print("✅ NPC gespawnt & Trigger ge-armed.")
	queue_free()
