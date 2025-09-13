extends Node3D

@onready var anim: AnimationPlayer = $AnimationPlayer

func _process(delta):
	if Input.is_action_just_pressed("shoot"):
		shoot()

func shoot():
	print("ballern")
	# Beide Animationen starten
	anim.play("MuzzleFlash")
	anim.play("shot")
