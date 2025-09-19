extends Control


func _on_menu_pressed() -> void:
	get_tree().paused = false
	Engine.time_scale = 1
	Objectives.reset()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
