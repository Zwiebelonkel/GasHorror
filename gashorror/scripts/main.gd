extends Node3D

@export var note_marker_path: NodePath
@export var note_scene: PackedScene
@export var doorArea: NodePath  # <-- Pfad zu deiner Area3D (z. B. Türtrigger)

#func _ready():
	#var area = get_node_or_null(doorArea)
	#if area:
		#area.body_entered.connect(_on_area_3d_body_entered_station)
	#else:
		#print("⚠️ doorArea-Node nicht gefunden!")

func _on_area_3d_body_entered_station(body: Node3D) -> void:
	if body.is_in_group("player"):
		print("Spieler betritt die Tankstelle")
		Objectives.enter_station()

func spawn_note():
	var marker = get_node_or_null(note_marker_path)
	if marker == null:
		print("⚠️ Spawn-Marker nicht gefunden! Pfad: ", note_marker_path)
		return

	var spawned_note = note_scene.instantiate()
	get_tree().current_scene.add_child(spawned_note)
	spawned_note.global_transform.origin = marker.global_transform.origin
	print("✅ Notiz gespawnt bei: ", spawned_note.global_transform.origin)
