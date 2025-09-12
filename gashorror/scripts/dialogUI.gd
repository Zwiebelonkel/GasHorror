extends CanvasLayer

@onready var label: Label = $Panel/Label

var dialog_lines: Array = []
var current_line_index: int = 0
var is_active: bool = false
var on_dialog_finished: Callable = func(): pass  # Leerer Fallback

func _ready():
	visible = false

func show_dialog(lines: Array, finished_callback: Callable = func(): pass):
	if lines.is_empty():
		return
	
	dialog_lines = lines
	current_line_index = 0
	is_active = true
	visible = true
	on_dialog_finished = finished_callback

	label.text = dialog_lines[current_line_index]

	# Spielersteuerung deaktivieren
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	var player = get_node("/root/Main/FpsPlayer/CharacterBody3D")
	player.can_look = false

func hide_dialog():
	is_active = false
	visible = false
	dialog_lines.clear()

	# Spielersteuerung wieder aktivieren
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	var player = get_node("/root/Main/FpsPlayer/CharacterBody3D")
	player.can_look = true

	# Callback aufrufen
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
