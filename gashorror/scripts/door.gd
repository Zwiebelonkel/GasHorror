extends Node3D  # Der Hauptknoten für die Tür, jetzt Node3D statt StaticBody3D

@export var is_open: bool = false  # Flag, ob die Tür geöffnet ist oder nicht
@onready var animation_player: AnimationPlayer = $AnimationPlayer  # AnimationPlayer unter StaticBody3D
@onready var door_sound: AudioStreamPlayer = $DoorSound


# Tür öffnen
func open_door() -> void:
	if not is_open:
		is_open = true
		print("Tür geöffnet")
		if animation_player:
			animation_player.play("open")  # Türöffnungs-Animation
			door_sound.play()

		else:
			print("Fehler: AnimationPlayer nicht gefunden")

# Tür schließen
func close_door() -> void:
	if is_open:
		is_open = false
		print("Tür geschlossen")
		if animation_player:
			animation_player.play("close")  # Türschließungs-Animation
			door_sound.play()

		else:
			print("Fehler: AnimationPlayer nicht gefunden")

# Wenn der Spieler in den Interaktionsbereich eintritt
func _on_Area3D_body_entered(body: Node) -> void:
	print("body Typ:", body.get_class())
	if body is CharacterBody3D:
		print("Ein Charakter (Spieler oder NPC) ist in Reichweite der Tür!")
		open_door()

func _on_Area3D_body_exited(body: Node) -> void:
	print("body Typ:", body.get_class())
	if body is CharacterBody3D:
		print("Ein Charakter (Spieler oder NPC) ist außerhalb der Tür!")
		close_door()
