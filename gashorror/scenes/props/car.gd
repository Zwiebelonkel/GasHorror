extends Area3D

func interact(player):
	_capture_mouse(false)
	Objectives.end_game()

		
		
func _capture_mouse(enable: bool) -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED if enable else Input.MOUSE_MODE_VISIBLE)
