extends Area3D

@export var code_ui_path: NodePath = ^"/root/Main/code_ui"
@export var correct_code: String = "1234"
@export var code_length: int = 4
@export var mask_input: bool = true

@export var s_ok: AudioStreamPlayer3D
@export var s_fail: AudioStreamPlayer3D

# Ziel
@export var success_target: NodePath                # Tür-Root mit door.gd hier zuweisen
@export var success_method: StringName = &"open"    # Methode an der Tür
@export var door_group: StringName = &"Door"        # optional: Gruppe am Tür-Root
@export var debug_logs: bool = true

@onready var _ui = get_node_or_null(code_ui_path)
var _unlocked := false

func interact(player: Node) -> void:
	if not player.is_in_group("player"):
		return
	if _unlocked:
		_log("interact(): bereits entsperrt")
		return
	if _ui == null:
		push_warning("Code UI nicht gefunden: " + str(code_ui_path))
		return
	if _ui.has_method("is_open") and _ui.is_open():
		_log("interact(): UI bereits offen")
		return

	var req_len := (code_length if code_length > 0 else correct_code.length())
	_log("interact(): öffne Code-UI, len=" + str(req_len))
	_ui.open_code("Code eingeben", req_len, mask_input, Callable(self, "_on_code_done"))

func _on_code_done(ok: bool, entered: String) -> void:
	_log("_on_code_done ok=" + str(ok) + " code='" + entered + "'")
	if not ok:
		if s_fail: s_fail.play()
		return

	if entered != correct_code:
		if s_fail: s_fail.play()
		_log("❌ falscher Code")
		return

	_unlocked = true
	if s_ok: s_ok.play()
	_log("✅ korrekter Code – versuche TÜR zu öffnen")
	Objectives.set_step(Objectives.SEE_TRUTH)

	var target := _resolve_target()
	if target == null:
		push_warning("Kein Tür-Node gefunden (success_target leer/falsch, keine Gruppe '" + str(door_group) + "', nichts mit Methode '" + str(success_method) + "').")
		return

	_log("target=" + str(target.get_path()) + " has " + str(success_method) + "=" + str(target.has_method(success_method)))
	if target.has_method(success_method):
		target.call_deferred(success_method)
	else:
		push_warning("Ziel hat Methode nicht: " + str(success_method))

# -------------------- Ziel-Findung --------------------

func _resolve_target() -> Node:
	# 1) Direkt: success_target
	if success_target != NodePath():
		var t := get_node_or_null(success_target)
		if t != null:
			return t

	# 2) Per Gruppe „Door“
	var group_nodes := get_tree().get_nodes_in_group(door_group)
	for n in group_nodes:
		if n.has_method(success_method):
			return n

	# 3) Heuristik: Eltern rauf, dann Szene runter
	var up := _find_with_method_up(self, success_method)
	if up: return up
	var down := _find_with_method_down(get_tree().current_scene, success_method, 0, 64)
	return down

func _find_with_method_up(from: Node, method: StringName) -> Node:
	var n := from.get_parent()
	while n:
		if n.has_method(method):
			return n
		n = n.get_parent()
	return null

func _find_with_method_down(root: Node, method: StringName, depth: int, limit: int) -> Node:
	if root == null or depth > limit:
		return null
	if root.has_method(method):
		return root
	for c in root.get_children():
		var f := _find_with_method_down(c, method, depth + 1, limit)
		if f: return f
	return null

# -------------------- Logging --------------------

func _log(msg: String) -> void:
	if debug_logs:
		print("[code_panel] " + msg)
