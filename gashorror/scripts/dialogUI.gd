extends CanvasLayer

@onready var label: Label = $Panel/Label

var dialog_lines: Array = []
var current_line_index: int = 0
var is_active: bool = false
var on_dialog_finished: Callable = func(): pass

var player = null
var target_look_at_position: Vector3 = Vector3.ZERO
var is_rotating_to_target: bool = false
var rotation_speed: float = 5.0  # Wie schnell der Spieler sich dreht

func _ready():
	visible = false
	player = get_node("/root/Main/FpsPlayer/CharacterBody3D")

func show_dialog(lines: Array, target_position: Vector3, finished_callback: Callable = func(): pass):
	if lines.is_empty():
		return
	
	dialog_lines = lines
	current_line_index = 0
	is_active = false
	visible = true
	on_dialog_finished = finished_callback
	
	target_look_at_position = target_position
	is_rotating_to_target = true
	
	# Steuerung vorläufig deaktivieren (vor allem Blick)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	player.can_look = false
	player.can_move = false  # Falls dein Spieler so eine Variable hat

func _process(delta):
	if is_rotating_to_target:
		_rotate_player_towards_target(delta)

func _rotate_player_towards_target(delta):
	var player_pos = player.global_transform.origin
	var target_pos = target_look_at_position
	target_pos.y = player_pos.y  # Höhe angleichen

	var direction = (target_pos - player_pos).normalized()

	# Je nach Ausrichtung des Spieler-Modells hier anpassen:
	# Falls dein Spieler "vorwärts" auf -Z zeigt, dann ist das hier richtig:
	var target_yaw = atan2(-direction.x, -direction.z)  # das ist Standard für Godot

	# Falls das Modell nach +X zeigt, dann musst du 90 Grad draufrechnen:
	# var target_yaw = atan2(direction.x, direction.z) + deg2rad(90)

	var current_yaw = player.rotation.y
	var new_yaw = lerp_angle(current_yaw, target_yaw, rotation_speed * delta)
	player.rotation.y = new_yaw

	if abs(angle_diff(new_yaw, target_yaw)) < 0.01:
		is_rotating_to_target = false
		_start_dialog()


func _start_dialog():
	is_active = true
	label.text = dialog_lines[current_line_index]

func hide_dialog():
	is_active = false
	visible = false
	dialog_lines.clear()

	# Steuerung wieder freigeben
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	player.can_look = true
	player.can_move = true

	# Callback ausführen
	on_dialog_finished.call()

func _unhandled_input(event):
	if is_active and event.is_action_pressed("ui_accept"):
		next_line()

func next_line():
	current_line_index += 1

	if current_line_index >= dialog_lines.size():
		hide_dialog()
	else:
		label.text = dialog_lines[current_line_index]

# Hilfsfunktion für Winkel-Differenz (in Radiant)
func angle_diff(angle1: float, angle2: float) -> float:
	var diff = fposmod(angle2 - angle1 + PI, TAU) - PI
	return diff
