extends Area3D

@export var light_controller_path: NodePath  # Verknüpft mit deinem Node3D, das das Lichter-Skript trägt

func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))

#func _on_body_entered(body):
	#if body.is_in_group("player"):
		#var light_controller = get_node(light_controller_path)
		#if light_controller:
			#light_controller.start_sequence()
		#
		## Entferne diese Area nach dem Auslösen
		#queue_free()
