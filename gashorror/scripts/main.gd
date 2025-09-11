extends Node3D  # oder Node, je nachdem

func _ready():
	$Area3D.body_entered.connect(_on_area_3d_body_entered_station)

func _on_area_3d_body_entered_station(body: Node3D) -> void:
	if body.is_in_group("player"):
		print("Spieler betritt die Tankstelle")
		Objectives.enter_station()  # benutzt die neue Funktion
