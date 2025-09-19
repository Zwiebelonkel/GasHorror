extends Node3D

@export var note_marker_path: NodePath
@export var note_scene: PackedScene
@export var doorArea: NodePath  # <-- Pfad zu deiner Area3D (z. B. Türtrigger)
@onready var options: Panel = $OptionsCanvas/OptionsControl/Options
@onready var spawn_point: Marker3D = $PlayerSpawn
@onready var respawn_point: Marker3D = $PlayerRespawn
@export var player_scene: PackedScene

var paused = false

func _process(delta):
	if Input.is_action_just_pressed("pause"):
		pauseMenu()
	
func pauseMenu():
	if paused:
		options.hide()
		Engine.time_scale = 1
	else:
		options.show()
		Engine.time_scale = 0
	paused = !paused

func _ready():
	spawn_player()
	options.hide()
	paused = false


func _on_area_3d_body_entered_station(body: Node3D) -> void:
	if body.is_in_group("player"):
		print("Spieler betritt die Tankstelle")
		Objectives.enter_station()

func spawn_player():
	if player_scene:
		var player = player_scene.instantiate()
		if Objectives.state["is_retrying"] == false:
			player.global_transform = spawn_point.global_transform
		elif Objectives.state["is_retrying"] == true:
			delete_all_doors()
			player.global_transform = respawn_point.global_transform
		add_child(player)

		# Kamera aktivieren
		var camera = player.get_node("CharacterBody3D/Camera3D") as Camera3D
		if camera:
			camera.current = true


func spawn_note():
	var marker = get_node_or_null(note_marker_path)
	if marker == null:
		print("⚠️ Spawn-Marker nicht gefunden! Pfad: ", note_marker_path)
		return

	var spawned_note = note_scene.instantiate()
	get_tree().current_scene.add_child(spawned_note)
	spawned_note.global_transform.origin = marker.global_transform.origin
	print("✅ Notiz gespawnt bei: ", spawned_note.global_transform.origin)

func delete_all_doors():
	for door in get_tree().get_nodes_in_group("doors"):
		if is_instance_valid(door):
			door.queue_free()


func _on_menu_pressed() -> void:
	pass # Replace with function body.
