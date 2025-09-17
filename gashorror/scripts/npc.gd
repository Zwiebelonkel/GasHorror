extends CharacterBody3D

@onready var animation_player: AnimationPlayer = $hillybilly/AnimationPlayer
@onready var path_follow: PathFollow3D = get_node("..")
@onready var dialog_ui = get_node("/root/Main/dialog")

@export var speed: float = 1.0
@export var product_scene: PackedScene
@export var spawn_marker_path: NodePath

var started := false
var reached_end := false
var has_spawned := false
var spawned_product = null  # Zum späteren Entfernendw

func _ready():
	play_idle_animation()
	randomize()
	Objectives.all_packages_stocked.connect(_on_all_packages_stocked)

func _process(delta):
	if not started or reached_end:
		return

	path_follow.progress += speed * delta

	if animation_player.current_animation != "walk":
		play_walk_animation()

	if path_follow.progress_ratio >= 1.0:
		reached_end = true
		play_idle_animation()

		if not has_spawned:
			spawn_product()
			has_spawned = true

func interact(player):
	if dialog_ui.is_active:
		print("dont start again")
		return  # ⛔️ Dialog läuft schon – keine neue Interaktion starten
	if not reached_end:
		return
	else:
		var dialogues = [
			"Kunde: Einmal das hier bitte.",
			"Spieler: 2$ bitte. Haben Sie alles gefunden?",
			"Kunde: Ja, aber alles kann ich mir hier leider nicht leisten.",
			"Spieler: Tankstellenpreise eben. Tschüss!",
			"Kunde: Tschüss."
		]
		dialog_ui.show_dialog(dialogues, global_transform.origin, Callable(self, "_on_dialog_finished"))


func _on_dialog_finished():
	if spawned_product:
		spawned_product.queue_free()
		print("🗑️ Produkt entfernt")

	queue_free()  # NPC verschwindet
	print("👋 NPC geht nach Hause")
	Objectives.blackOut()

func _on_all_packages_stocked():
	print("✅ Alle Pakete eingeräumt – NPC startet")
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

func spawn_product():
	if product_scene == null:
		print("⚠️ Keine Produktszene zugewiesen!")
		return

	var marker = get_node_or_null(spawn_marker_path)
	if marker == null:
		print("⚠️ Spawn-Marker nicht gefunden! Pfad: ", spawn_marker_path)
		return

	spawned_product = product_scene.instantiate()
	get_tree().current_scene.add_child(spawned_product)
	spawned_product.global_transform.origin = marker.global_transform.origin
	print("✅ Produkt gespawnt bei: ", spawned_product.global_transform.origin)
