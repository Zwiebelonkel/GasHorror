extends Area3D

@export var unlocked_breaker_scene: PackedScene   # Scene mit dem neuen (bedienbaren) Breaker
@export var replace_parent_path: NodePath         # optional: wohin instanziert werden soll (sonst: get_parent())
@export var s_unlock_path: NodePath               # optional: AudioStreamPlayer für "Klack"
@export_node_path var main_node_path: NodePath  # ← Referenz auf den Main-Knoten (mit spawn_note)


#@onready var s_unlock: AudioStreamPlayer = get_node_or_null(s_unlock_path) as AudioStreamPlayer
@onready var s_unlock: AudioStreamPlayer3D = $open

func interact(player: Node) -> void:
	if not player.is_in_group("player"):
		return

	# Hat der Spieler den Schlüssel?
	var has_key := false
	if typeof(Objectives) != TYPE_NIL and Objectives.state.has("has_key"):
		has_key = Objectives.state["has_key"]

	if not has_key:
		print("Kein Schlüssel – Notiz muss gefunden werden")

		if Objectives.current_step < Objectives.FIND_NOTE:
			Objectives.found_locked_breaker()

			# Notiz spawnen über Main-Node
		var main = get_node_or_null(main_node_path)
		if main and main.has_method("spawn_note"):
			main.spawn_note()
		else:
			print("⚠️ Main-Node nicht gefunden oder keine spawn_note()-Methode.")
		return

	if unlocked_breaker_scene == null:
		push_warning("⚠️ unlocked_breaker_scene fehlt!")
		return

	# Austausch
	var parent: Node = get_parent()
	if replace_parent_path != NodePath() and has_node(replace_parent_path):
		parent = get_node(replace_parent_path)

	var t := global_transform
	var new_breaker := unlocked_breaker_scene.instantiate()
	parent.add_child(new_breaker)
	new_breaker.owner = get_tree().current_scene
	new_breaker.global_transform = t

	if s_unlock:
		s_unlock.play()

	print("✅ LockedBreaker → Breaker ersetzt an gleicher Stelle")
	queue_free()

	# Optional: Objective Hinweis „Schalte den Strom ein“
	if Objectives.current_step < Objectives.POWER_ON:
		Objectives.set_step(Objectives.POWER_ON)
