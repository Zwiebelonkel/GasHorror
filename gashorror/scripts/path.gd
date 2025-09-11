extends PathFollow3D

@export var speed: float = 1.0
var started: bool = false
var reached_end: bool = false

func _process(delta):
	if not started or reached_end:
		return

	progress += speed * delta

	if progress_ratio >= 1.0:
		reached_end = true
