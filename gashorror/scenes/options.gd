extends Control


func _on_menu_pressed() -> void:
	Objectives.reset()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
