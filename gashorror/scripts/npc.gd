extends CharacterBody3D

@onready var animation_player: AnimationPlayer = $hillybilly/AnimationPlayer
@onready var path_follow: PathFollow3D = get_node("..")

@export var speed: float = 1.0

var started := false
var reached_end := false

func _ready():
	# Animation auf idle setzen
	play_idle_animation()
	
	# Mit Objectives verbinden
	Objectives.all_packages_stocked.connect(_on_all_packages_stocked)

func _process(delta):
	if not started or reached_end:
		return

	# NPC entlang des Pfads bewegen
	path_follow.progress += speed * delta

	if animation_player.current_animation != "walk":
		play_walk_animation()

	if path_follow.progress_ratio >= 1.0:
		reached_end = true
		play_idle_animation()

func _on_all_packages_stocked():
	print("Alle Pakete eingeräumt – NPC startet")
	started = true

func play_idle_animation():
	if animation_player.has_animation("idle"):
		var anim = animation_player.get_animation("idle")
		anim.loop = true
		animation_player.play("idle")

func play_walk_animation():
	if animation_player.has_animation("walk"):
		var anim = animation_player.get_animation("walk")
		anim.loop = true
		animation_player.play("walk")
