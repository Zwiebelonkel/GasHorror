extends Node3D

@export var road_segment_scene: PackedScene
@export var segment_length: float = 10.0
@export var number_of_segments: int = 6
@export var move_speed: float = 5.0

var segments: Array[Node3D] = []

func _ready() -> void:
	# Erzeuge die initialen Straßensegmente
	for i in range(number_of_segments):
		var segment = road_segment_scene.instantiate() as Node3D
		add_child(segment)
		segment.position.z = -i * segment_length
		segments.append(segment)

func _process(delta: float) -> void:
	# Bewege alle Segmente nach vorne (relativ zum Auto)
	for segment in segments:
		segment.position.z += move_speed * delta

	# Wenn das vorderste Segment den "Recyclepunkt" überschreitet
	var first_segment = segments[0]
	if first_segment.position.z > segment_length:
		# Entferne das erste Segment aus der Liste
		segments.pop_front()
		first_segment.queue_free()

		# Neues Segment ans Ende
		var new_segment = road_segment_scene.instantiate() as Node3D
		add_child(new_segment)

		var last_segment = segments[-1]
		new_segment.position.z = last_segment.position.z - segment_length

		segments.append(new_segment)
