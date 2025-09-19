extends Control


func _on_menu_pressed() -> void:
	get_tree().paused = false
	Engine.time_scale = 1
	Objectives.state["is_retrying"] = true
	Objectives.set_step(Objectives["SEE_TRUTH"])
	get_tree().change_scene_to_file("res://scenes/main.tscn")
