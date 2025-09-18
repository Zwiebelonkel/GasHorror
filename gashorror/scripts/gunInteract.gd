extends Area3D

signal picked_up   # wird beim Einsammeln gefeuert

@export var auto_free := true        # nach Pickup aus der Szene entfernen
@export var hide_only := false       # statt löschen nur verstecken

var _taken := false

func interact(player: Node) -> void:
	if _taken:
		return
	if not player.is_in_group("player"):
		return

	_taken = true
	emit_signal("picked_up")  
	Objectives.state["has_gun"] = true    # sagt dem Player: "du hast die Pistole jetzt"
	if hide_only:
		_hide_self()
	elif auto_free:
		queue_free()
	else:
		_hide_self()

func _hide_self() -> void:
	visible = false
	set_physics_process(false)
	set_process(false)
