extends Node  # Oder extends Node3D, je nach Node-Typ

func _ready():
	$Area3D.body_entered.connect(Objectives._on_area_3d_body_entered_station)
