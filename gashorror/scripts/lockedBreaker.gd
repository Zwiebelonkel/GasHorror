extends Area3D

@export var is_locked: bool = true
@export var requires_key: bool = true
@export var required_key_name: String = "breaker_key"
@export_node_path var breaker_closed_node: NodePath
@export_node_path var breaker_open_node: NodePath
@export_node_path var main_node_path: NodePath  # ← Referenz auf den Main-Knoten (mit spawn_note)

func interact(player):
	print("Interagiere mit Breaker")

	if is_locked:
		if requires_key and player.has_key(required_key_name):
			is_locked = false

			# Breaker austauschen (geschlossen -> offen)
			var closed = get_node_or_null(breaker_closed_node)
			var open = get_node_or_null(breaker_open_node)
			if closed:
				closed.visible = false
			if open:
				open.visible = true

			# Schritt wechseln, falls nötig
			if Objectives.current_step < Objectives.POWER_ON:
				Objectives.set_step(Objectives.POWER_ON)

		else:
			print("Kein Schlüssel – Notiz muss gefunden werden")

			if Objectives.current_step < Objectives.FIND_NOTE:
				Objectives.found_locked_breaker()

				# Notiz spawnen über Main-Node
				var main = get_node_or_null(main_node_path)
				if main and main.has_method("spawn_note"):
					main.spawn_note()
				else:
					print("⚠️ Main-Node nicht gefunden oder keine spawn_note()-Methode.")
	else:
		_toggle_breaker()


func _toggle_breaker():
	# Optional: Schaltlogik bei offenem Breaker
	pass
