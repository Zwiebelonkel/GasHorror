extends Node3D

var is_held := false
var holder = null

func interact(player):
	if is_held:
		drop()
	else:
		pick_up(player)

func pick_up(player):
	if is_held: return
	is_held = true
	holder = player
	
	var hold_point = player.get_node("Camera3D/HoldPoint")
	if hold_point:
		get_parent().remove_child(self)
		hold_point.add_child(self)
		self.transform = Transform3D.IDENTITY
		self.position = Vector3.ZERO
		self.rotation = Vector3.ZERO

func drop():
	if not is_held: return
	is_held = false
	
	var world = get_tree().current_scene
	var global_pos = global_transform.origin
	
	get_parent().remove_child(self)
	world.add_child(self)
	self.global_transform.origin = global_pos

	holder = null
