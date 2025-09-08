extends Node3D

@export var cam_path: NodePath
@export var distance: float = 2.5   # Reichweite des Blickstrahls

@onready var cam: Camera3D = get_node(cam_path)

func _process(_d: float) -> void:
	if Input.is_action_just_pressed("interact"):
		_try_interact()

func _try_interact() -> void:
	var from := cam.global_transform.origin
	var to   := from + (-cam.global_transform.basis.z) * distance

	var query := PhysicsRayQueryParameters3D.new()
	query.from = from
	query.to   = to
	query.collide_with_areas = true
	query.collide_with_bodies = true

	# Use get_world_3d() to access the 3D physics world in Godot 4.x
	var hit : Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	
	if hit.has("collider") and hit["collider"].has_method("interact"):
		# Spieler-Referenz (erstes Node in Gruppe "player")
		var player := get_tree().get_first_node_in_group("player")
		hit["collider"].interact(player)
