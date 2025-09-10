extends CharacterBody3D

@onready var animation_player: AnimationPlayer = $hillybilly/AnimationPlayer  # Der korrekte Pfad zum AnimationPlayer

# Diese Funktion wird beim Start des Spiels aufgerufen
func _ready():
	# Überprüfe, ob die "idle"-Animation existiert
	if animation_player.has_animation("idle"):
		print("Found idle animation, playing now.")
		play_idle_animation()  # Idle-Animation abspielen
	else:
		print("Idle animation not found.")  # Fehlermeldung, falls die Animation nicht existiert

# Diese Funktion spielt die Idle-Animation kontinuierlich ab
func play_idle_animation():
	var idle_animation = animation_player.get_animation("idle")  # Hole die "idle"-Animation
	idle_animation.loop = true  # Setze die Loop-Option auf true
	animation_player.play("idle")  # Die Idle-Animation wird abgespielt

# Optional: Falls du Animationen per Tastendruck wechseln möchtest (z.B. auf "F" drücken, um eine neue Animation zu starten)
#func _input(event):
	#if event.is_action_pressed("ui_accept"):  # Standard-Taste "Enter" oder "F"
		#if animation_player.has_animation("walk"):  # Falls eine "walk"-Animation existiert
			#animation_player.play("walk")  # Wechsel zur Walk-Animation
			#print("Playing Walk animation")
