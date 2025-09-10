extends SpotLight3D

@export var min_interval := 0.05
@export var max_interval := 0.2
@export var min_energy := 0.5
@export var max_energy := 1.0

func _ready():
	flicker()

func flicker() -> void:
	# light_energy ist der richtige Property-Name
	light_energy = randf_range(min_energy, max_energy)
	
	var wait_time = randf_range(min_interval, max_interval)
	await get_tree().create_timer(wait_time).timeout
	
	flicker()
