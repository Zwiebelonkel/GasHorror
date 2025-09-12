extends Node3D

@export var cam_path: NodePath = "../Camera3D"
@export var distance: float = 2.5

@onready var cam: Camera3D = get_node(cam_path)
@onready var prompt_label: Label = get_node("/root/Main/Interactor HUD/InteractionPrompt")

var current_target: Object = null

func _process(_d: float) -> void:
	_check_interactable()

	if Input.is_action_just_pressed("interact") and current_target:
		var player := get_tree().get_first_node_in_group("player")
		current_target.interact(player)

func _check_interactable() -> void:
	var from := cam.global_transform.origin
	var to := from + (-cam.global_transform.basis.z) * distance

	var query := PhysicsRayQueryParameters3D.new()
	query.from = from
	query.to = to
	query.collide_with_areas = true
	query.collide_with_bodies = true

	var hit := get_world_3d().direct_space_state.intersect_ray(query)

	if hit.has("collider") and hit["collider"].has_method("interact"):
		current_target = hit["collider"]
		prompt_label.visible = true
	else:
		current_target = null
		prompt_label.visible = false
