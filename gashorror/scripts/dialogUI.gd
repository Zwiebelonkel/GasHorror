extends CanvasLayer

@onready var label: Label = $Panel/Label

var dialog_lines: Array = []
var current_line_index: int = 0
var is_active: bool = false
var on_dialog_finished: Callable = func(): pass

var player = null
var target_look_at_position: Vector3 = Vector3.ZERO
var is_rotating_to_target: bool = false
var rotation_speed: float = 5.0

# Schreibmaschinen-Effekt
var full_text: String = ""
var visible_chars: int = 0
var typing_timer: float = 0.0
var typing_speed: float = 30.0  # Zeichen pro Sekunde
var is_typing: bool = false

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
	
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	player.can_look = false
	player.can_move = false

func _process(delta):
	if is_rotating_to_target:
		_rotate_player_towards_target(delta)
	elif is_typing:
		typing_timer += delta
		var chars_to_show = int(typing_timer * typing_speed)
		if chars_to_show > visible_chars:
			visible_chars = chars_to_show
			label.text = full_text.substr(0, visible_chars)
		
		if visible_chars >= full_text.length():
			is_typing = false

func _rotate_player_towards_target(delta):
	var player_pos = player.global_transform.origin
	var target_pos = target_look_at_position
	target_pos.y = player_pos.y

	var direction = (target_pos - player_pos).normalized()
	var target_yaw = atan2(-direction.x, -direction.z)
	var current_yaw = player.rotation.y
	var new_yaw = lerp_angle(current_yaw, target_yaw, rotation_speed * delta)
	player.rotation.y = new_yaw

	if abs(angle_diff(new_yaw, target_yaw)) < 0.01:
		is_rotating_to_target = false
		_start_dialog()

func _start_dialog():
	is_active = true
	_show_current_line()

func _show_current_line():
	full_text = dialog_lines[current_line_index]
	visible_chars = 0
	typing_timer = 0.0
	is_typing = true
	label.text = ""  # leer starten

func _unhandled_input(event):
	if is_active and event.is_action_pressed("ui_accept"):
		if is_typing:
			# sofort den ganzen Text anzeigen
			is_typing = false
			label.text = full_text
		else:
			next_line()

func next_line():
	current_line_index += 1

	if current_line_index >= dialog_lines.size():
		hide_dialog()
	else:
		_show_current_line()

func hide_dialog():
	is_active = false
	visible = false
	dialog_lines.clear()
	label.text = ""  # leer starten


	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	player.can_look = true
	player.can_move = true

	on_dialog_finished.call()

func angle_diff(angle1: float, angle2: float) -> float:
	var diff = fposmod(angle2 - angle1 + PI, TAU) - PI
	return diff
