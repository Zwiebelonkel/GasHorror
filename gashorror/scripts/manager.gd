extends CharacterBody3D

# --- Referenzen (im Inspector zuweisen) ---
@export var dialog_ui: CanvasLayer
@export var animation_player: AnimationPlayer
@export var manager_trigger: Area3D
@export var player_path: NodePath      # optional; leer lassen, wenn Player über Gruppe "player" gefunden werden soll

# --- Animationen ---
@export var walk_anim: StringName = &"mixamo_com"
@export var idle_anim: StringName = &"idle"

# --- Bewegung/Verhalten ---
@export var speed: float = 5.0
@export var turn_speed: float = 8.0        # wie schnell er Richtung Spieler dreht
@export var stop_distance: float = 1.5     # Abstand, bei dem er stehen bleibt
@export var use_gravity: bool = true
@export var gravity: float = 9.8

# --- intern ---
var _dialog_started: bool = false
var _chase: bool = false
var _player: Node3D

func _ready() -> void:
	# UI vorbereiten
	if dialog_ui:
		dialog_ui.hide()

	# Trigger verbinden
	if manager_trigger and not manager_trigger.is_connected("body_entered", Callable(self, "_on_manager_trigger_entered")):
		manager_trigger.body_entered.connect(Callable(self, "_on_manager_trigger_entered"))

	# Player auflösen (direkt + Fallback über Gruppe)
	_resolve_player()

func _resolve_player() -> void:
	# 1) expliziter Pfad
	if _player == null and player_path != NodePath():
		_player = get_node_or_null(player_path) as Node3D
	# 2) Gruppe "player" (dein FPS-Controller ist dort drin)
	if _player == null:
		var arr := get_tree().get_nodes_in_group("player")
		if arr.size() > 0:
			_player = arr[0] as Node3D

func _on_manager_trigger_entered(body: Node) -> void:
	if not body.is_in_group("player") or _dialog_started:
		return
	_dialog_started = true

	# Dialog starten
	if dialog_ui and dialog_ui.has_method("show_dialog"):
		var lines := [
			"Manager: Was suchst du denn hier?",
			"Spieler: Was geht hier unten vor sich?",
			"Manager: Das hat dich einen Scheiß zu interessieren!",
			"Manager: Hättest du nicht einfach weiterarbeiten können?",
			"Spieler: Was sind das hier für Leute?",
			"Manager: Das ist der Schmutz der Gesellschaft. 
			 Diese Penner werden hier gemolken um das beste und angesagteste Benzin zu produzieren.",
			"Spieler: Das kann so nicht weitergehen!",
			"Manager: Wie du meinst"
		]
		dialog_ui.show_dialog(lines, Callable(self, "_on_dialog_finished"))
	else:
		_on_dialog_finished()

	# Trigger nur einmal nutzen
	if manager_trigger:
		manager_trigger.queue_free()

func _on_dialog_finished() -> void:
	_chase = true   # ab jetzt im Physics-Loop verfolgen

func _physics_process(delta: float) -> void:
	# Player ggf. nachladen (z. B. wenn noch nicht vorhanden)
	if _player == null or not is_instance_valid(_player):
		_resolve_player()
		if _player == null:
			return

	# Wenn noch kein Verfolgen: stehen bleiben/idle
	if not _chase:
		velocity.x = 0.0
		velocity.z = 0.0
		# Idle-Anim
		if animation_player and animation_player.has_animation(idle_anim) and animation_player.current_animation != String(idle_anim):
			animation_player.play(String(idle_anim))
		# Gravitation
		if use_gravity:
			velocity.y = (velocity.y - gravity * delta) if not is_on_floor() else 0.0
		move_and_slide()
		return

	# --- aktuelles Ziel jedes Frame nehmen ---
	var from: Vector3 = global_position
	var to: Vector3 = _player.global_position

	var dir: Vector3 = to - from
	dir.y = 0.0
	var dist: float = dir.length()

	# weich zum Spieler drehen
	if dist > 0.001:
		var n: Vector3 = dir / dist
		var target_yaw: float = atan2(n.x, n.z)
		rotation.y = lerp_angle(rotation.y, target_yaw, turn_speed * delta)

	# laufen / stoppen
	var n2: Vector3 = (dir / dist) if dist > 0.0001 else Vector3.ZERO
	if dist > stop_distance:
		velocity.x = n2.x * speed
		velocity.z = n2.z * speed
		# Lauf-Anim
		if animation_player and animation_player.has_animation(walk_anim) and animation_player.current_animation != String(walk_anim):
			animation_player.play(String(walk_anim))
	else:
		velocity.x = 0.0
		velocity.z = 0.0
		# Idle-Anim
		if animation_player and animation_player.has_animation(idle_anim) and animation_player.current_animation != String(idle_anim):
			animation_player.play(String(idle_anim))

	# Gravitation
	if use_gravity:
		velocity.y = (velocity.y - gravity * delta) if not is_on_floor() else 0.0

	move_and_slide()
