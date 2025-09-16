extends Node3D

@export var delay_between_lights = 0.5
var lights = []

var current_light_index = 0
var time_since_last_on = 0.0
var is_active = false


func _ready():

	find_spotlights(self)
	for light in lights:
		set_visible_recursive(light, false)

func find_spotlights(node: Node):
	for child in node.get_children():
		if child is SpotLight3D:
			if not child in lights:
				lights.append(child)
		elif child is Node:
			find_spotlights(child)

func set_visible_recursive(node: Node, visibility: bool):
	if node is Node3D:
		node.visible = visibility

	var parent = node.get_parent()
	while parent:
		if parent is Node3D:
			parent.visible = visibility
		else:
			break
		parent = parent.get_parent()

func _process(delta):
	if current_light_index < lights.size():
		time_since_last_on += delta
		if time_since_last_on >= delay_between_lights:
			set_visible_recursive(lights[current_light_index], true)
			current_light_index += 1
			time_since_last_on = 0.0
