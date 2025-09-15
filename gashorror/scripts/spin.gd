extends CharacterBody3D

# Drehgeschwindigkeit in Grad pro Sekunde
@export var rotation_speed = 10.0

# Schwunghöhe (Amplitude) für das Schwingen
@export var swing_height = 1.0

# Geschwindigkeit des Schwingens
@export var swing_speed = 1.0

# Zeitpunkt, um das Schwingen zu steuern
var time = 0.0

func _ready():
	pass

func _process(delta):
	# Drehung um die Y-Achse
	rotate_y(deg_to_rad(rotation_speed * delta))
	
	# Schwungbewegung (sinusförmig)
	time += delta * swing_speed
	var offset_y = sin(time) * swing_height
	# Die Höhe ändern, indem die Position entlang der Y-Achse verschoben wird
	position.y = offset_y
