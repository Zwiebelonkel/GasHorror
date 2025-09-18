extends Node3D
@export var cam_path: NodePath = "../Camera3D"
@export var distance: float = 2.5
@export var look_distance: float = 5.0  # Der längere Ray

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
	var to_interact := from + (-cam.global_transform.basis.z) * distance  # Der kürzere Interaktions-Ray
	var to_look := from + (-cam.global_transform.basis.z) * look_distance  # Der längere Schau-Ray

	# Ray für die Interaktion
	var query_interact := PhysicsRayQueryParameters3D.new()
	query_interact.from = from
	query_interact.to = to_interact
	query_interact.collide_with_areas = true
	query_interact.collide_with_bodies = true

	var hit_interact := get_world_3d().direct_space_state.intersect_ray(query_interact)

	# Ray für das Aktualisieren des Objectives (länger)
	var query_look := PhysicsRayQueryParameters3D.new()
	query_look.from = from
	query_look.to = to_look
	query_look.collide_with_areas = true
	query_look.collide_with_bodies = true

	var hit_look := get_world_3d().direct_space_state.intersect_ray(query_look)

	# Überprüfen des Interaktions-Rays
	if hit_interact.has("collider") and hit_interact["collider"].has_method("interact"):
		current_target = hit_interact["collider"]
		prompt_label.visible = true
	else:
		current_target = null
		prompt_label.visible = false

	if hit_look.has("collider"):
		var hit_object = hit_look["collider"]
	
	# Falls der Collider ein Kind von 'thereIsMore' ist, gehen wir einen Eltern-Node hoch
		while hit_object != null and hit_object.name != "thereIsMore":
			hit_object = hit_object.get_parent()

		if hit_object and hit_object.name == "thereIsMore":
			if Objectives.current_step == Objectives.SIGN_CHANGE:
				Objectives.state.sign_changed = true
				Objectives.set_step(Objectives.REENTER_CELLAR)
