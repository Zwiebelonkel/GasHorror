extends Node3D

# --- Nodes ---
@onready var anim: AnimationPlayer = $AnimationPlayer

@export var animation_name: StringName = &"combined"

@export var muzzle_light_path: NodePath = ^"Muzzle/muzzleLight"
@export var shot_sound_path: NodePath  = ^"shot_sound"

@onready var muzzle_light: Node = get_node_or_null(muzzle_light_path)
@onready var s_shot: AudioStreamPlayer = get_node_or_null(shot_sound_path) as AudioStreamPlayer

# --- Timing ---
@export var muzzle_flash_time: float = 0.1   # 80 ms typischer Flash
@export var fire_cooldown: float = 0.12       # minimale Zeit zwischen Schüssen

# Optional: Anim-Visibility-Tracks deaktivieren (falls vorhanden)
@export var disable_anim_visibility_tracks: bool = true

var _flash_left: float = 0.0
var _cd_left: float = 0.0

func _ready() -> void:
	# Licht initial aus
	if muzzle_light:
		muzzle_light.visible = false

	# sicherstellen: keine Autoplay-Animation
	if anim:
		anim.stop()

	# (Optional) Visibility-Tracks auf 'visible' in der Animation deaktivieren
	if disable_anim_visibility_tracks and anim:
		_disable_visibility_tracks(animation_name)

func _process(delta: float) -> void:
	# Cooldown herunterzählen
	if _cd_left > 0.0:
		_cd_left -= delta

	# Flash aktiv halten (setzt Sichtbarkeit am Frameende, damit sie gegenüber Animation "gewinnt")
	if _flash_left > 0.0:
		_flash_left -= delta
		if muzzle_light:
			muzzle_light.visible = true
			muzzle_light.call_deferred("set", "visible", true)
	else:
		if muzzle_light and muzzle_light.visible:
			muzzle_light.visible = false
			muzzle_light.call_deferred("set", "visible", false)

	# Input
	if Input.is_action_just_pressed("shoot") and _cd_left <= 0.0:
		shoot()

func shoot() -> void:
	_cd_left = fire_cooldown
	_flash_left = muzzle_flash_time

	# Animation korrekt starten (Godot 4: name, blend, speed, from_end)
	if anim:
		anim.play(animation_name, 0.0, 1.0, false)
		anim.seek(0.0, true)  # sofort auf Start updaten

	# Sound
	if s_shot:
		s_shot.play()

# --- Helpers -------------------------------------------------------------

# Deaktiviert alle 'visible'-Tracks der angegebenen Animation
# (einfach & sicher – falls du Visibility nur per Code steuern willst)
func _disable_visibility_tracks(anim_name: StringName) -> void:
	if anim == null:
		return
	var a: Animation = anim.get_animation(anim_name)
	if a == null:
		return
	for i in a.get_track_count():
		if a.track_get_type(i) != Animation.TYPE_VALUE:
			continue
		var path: NodePath = a.track_get_path(i)
		# In Godot 4: Node-Pfad (names) + Property (subnames)
		if path.get_concatenated_subnames() == "visible":
			a.track_set_enabled(i, false)
