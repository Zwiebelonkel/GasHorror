extends Area3D

@export var move_speed: float = 10.0
@export var horizontal_speed: float = 5.0
@export var max_offset_x: float = 3.5# Wie weit man nach links/rechts darf

func _process(delta: float) -> void:
	# Seitliche Bewegung
	var input_dir := 0.0
	if Input.is_action_pressed("move_left"):
		input_dir -= 1.0
	if Input.is_action_pressed("move_right"):
		input_dir += 1.0

	# Neue X-Position berechnen
	var new_x = position.x + input_dir * horizontal_speed * delta
	new_x = clamp(new_x, -max_offset_x, max_offset_x)  # Begrenzung

	# Position aktualisieren
	position.x = new_x
