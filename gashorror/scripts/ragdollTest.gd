extends Node3D

@export var animated_skeleton_path: NodePath
@onready var animated_skeleton: Skeleton3D = get_node(animated_skeleton_path)

var ragdoll_bones := []
var ragdoll_active := false

func _ready():
	# Alle Ragdoll-RigidBodies und Constraints deaktivieren beim Start
	_disable_ragdoll_physics(animated_skeleton)
	print("🔧 Ragdoll-Setup fertig.")

func _input(event):
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ragdoll_toggle"):
		if ragdoll_active:
			print("⏹️ Ragdoll deaktivieren")
			_disable_ragdoll_physics(animated_skeleton)
			ragdoll_active = false
		else:
			print("💥 Ragdoll aktivieren")
			_enable_ragdoll_physics(animated_skeleton)
			ragdoll_active = true

# Aktiviere die RigidBodies und deaktiviere Animation
func _enable_ragdoll_physics(skeleton: Skeleton3D):
	skeleton.physical_bones_stop_simulation()  # Nur falls bereits simuliert
	skeleton.physical_bones_start_simulation()

	# Deaktiviere den AnimationPlayer, wenn du eine Animation hast
	var anim_player := skeleton.get_parent().get_node_or_null("AnimationPlayer")
	if anim_player:
		anim_player.stop()

# Deaktiviere die Ragdoll-Physik (zurück zu Animation)
func _disable_ragdoll_physics(skeleton: Skeleton3D):
	skeleton.physical_bones_stop_simulation()

	# Reaktiviere AnimationPlayer
	var anim_player := skeleton.get_parent().get_node_or_null("AnimationPlayer")
	if anim_player:
		anim_player.play("idle")  # Passe das an deine Idle-Animation an
