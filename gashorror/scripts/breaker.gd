extends Area3D

var is_on := true # Lokaler Zustand zur Animation

func _ready():
	# Synchronisiere Hebel-Animation mit dem globalen Zustand
	is_on = Objectives.state.power_on
	var anim = $breaker2/AnimationPlayer
	anim.play("on")
	if not is_on:
		anim.seek(anim.current_animation_length, true)
		anim.stop()

func interact(_player):
	_toggle_breaker()

func _toggle_breaker():
	var anim = $breaker2/AnimationPlayer
	if is_on:
		anim.play_backwards("on")
		Objectives.trigger_blackout()
	else:
		anim.play("on")
		Objectives.restore_power()
	is_on = !is_on
