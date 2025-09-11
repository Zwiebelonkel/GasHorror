extends StaticBody3D

@onready var snack_container = $cans
@onready var place_sound: AudioStreamPlayer = $PlaceSound


var is_filled := false

func _ready():
	# Snacks ausblenden
	for child in snack_container.get_children():
		child.visible = false

func interact(player):
	if is_filled:
		print("Shelf already filled")
		return

	var box = _get_held_box(player)
	if box:
		_fill_shelf(box)

func _get_held_box(player) -> Node3D:
	var hold_point = player.get_node_or_null("Camera3D/HoldPoint")
	if hold_point and hold_point.get_child_count() > 0:
		return hold_point.get_child(0)
	return null

func _fill_shelf(box: Node3D):
	is_filled = true
	box.queue_free()
	Objectives.progress_package_stock()
	print("Should add now")
	place_sound.play()

	for child in snack_container.get_children():
		child.visible = true
