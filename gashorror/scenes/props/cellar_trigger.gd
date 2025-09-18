extends Area3D


func _on_cellar_entered(_body: Node3D) -> void:
	if Objectives.current_step == Objectives.REENTER_CELLAR:
		Objectives.set_step(Objectives.SECRET_ENTRANCE)
