extends Node3D

@export var hinge_path: NodePath = ^"hinge"                 # Pivot-Node
@export var body_path: NodePath = ^"hinge/AnimatableBody3D" # Tür-Body mit Collision
@export var collision_shape_path: NodePath                  # optional: explizite CollisionShape3D

@export var open_angle_deg: float = 90.0
@export var open_time: float = 0.7
@export var open_dir: int = 1                 # 1 oder -1
@export var s_open: AudioStreamPlayer
@export var debug_logs: bool = true

var _is_open := false
var _tw: Tween

@onready var _hinge: Node3D = get_node_or_null(hinge_path) as Node3D
@onready var _body: AnimatableBody3D = get_node_or_null(body_path) as AnimatableBody3D
@onready var _col: CollisionShape3D = get_node_or_null(collision_shape_path) as CollisionShape3D

var _closed_rot := Vector3.ZERO
var _open_rot := Vector3.ZERO
var _orig_layer := 0
var _orig_mask := 0

func _ready() -> void:
	# Hinge/Body/Collision ggf. automatisch finden
	if _hinge == null:
		_hinge = self
	if _body == null and _hinge:
		for c in _hinge.get_children():
			if c is AnimatableBody3D:
				_body = c
				break
	if _col == null and _body:
		for c in _body.get_children():
			if c is CollisionShape3D:
				_col = c
				break

	_closed_rot = _hinge.rotation_degrees
	_open_rot   = _closed_rot + Vector3(0, open_dir * open_angle_deg, 0)

	if _body:
		_orig_layer = _body.collision_layer
		_orig_mask  = _body.collision_mask

	var h := _hinge if _hinge else null
	var b := _body if _body else null
	var c := _col if _col else null
	_log("Init: hinge=" + (str(h.get_path()) if h else "null")
		+ " body=" + (str(b.get_path()) if b else "null")
		+ " col=" + (str(c.get_path()) if c else "null"))

func open() -> void:
	if _is_open:
		return
	_is_open = true
	if _tw:
		_tw.kill()
	_tw = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tw.tween_property(_hinge, "rotation_degrees", _open_rot, open_time)
	_tw.tween_callback(Callable(self, "_on_open_finished"))
	if s_open:
		s_open.play()
	_log("open() tween → " + str(_open_rot))

func _on_open_finished() -> void:
	_set_collision_enabled(false)
	_log("open finished → collision OFF")

func close() -> void:
	if not _is_open:
		return
	_is_open = false
	# Kollisionsblock direkt wieder aktivieren, bevor die Tür zu fährt
	_set_collision_enabled(true)

	if _tw:
		_tw.kill()
	_tw = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tw.tween_property(_hinge, "rotation_degrees", _closed_rot, open_time)
	_log("close() tween → " + str(_closed_rot))

func toggle() -> void:
	if _is_open:
		close()
	else:
		open()

func is_open() -> bool:
	return _is_open

# --- Collision togglen: bevorzugt Shape.disabled, sonst Body-Layer/Mask ---
func _set_collision_enabled(enable: bool) -> void:
	if _col:
		_col.disabled = not enable
		_log("collision shape " + ( "ENABLED" if enable else "DISABLED" ))
	elif _body:
		if enable:
			_body.collision_layer = _orig_layer
			_body.collision_mask  = _orig_mask
		else:
			_body.collision_layer = 0
			_body.collision_mask  = 0
		_log("body layers→ " + str(_body.collision_layer) + " mask→ " + str(_body.collision_mask))

func _log(msg: String) -> void:
	if debug_logs:
		print("[door] " + msg)
