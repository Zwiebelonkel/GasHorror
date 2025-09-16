extends Area3D

# --- Einstellungen ---
@export var debug_logs: bool = true

# Sound
@export var s_switch: AudioStreamPlayer

# Schilder: am leichtesten per Drag&Drop im Inspector zuweisen
@export var sign_node: Node            # altes Schild (Node3D oder Control)
@export var sign2_node: Node           # neues Schild

# Optional zusätzlich: NodePaths (falls du lieber Pfade nutzt)
#@export var sign_path: NodePath
#@export var sign2_path: NodePath

# Fallback-Gruppen (falls oben nichts gesetzt ist)
@export var old_group: StringName = &"SignOld"
@export var new_group: StringName = &"SignNew"

var is_on := false

func interact(player: Node) -> void:
	_dbg("breaker path: " + str(get_path()))
	if not player.is_in_group("player"):
		_dbg("interact(): Body ist kein Spieler → Abbruch.")
		return

	_dbg("interact(): aufgerufen. is_on=" + str(is_on))

	if is_on:
		_log("ℹ️ Strom ist bereits an.")
		return

	# Sound
	if s_switch:
		s_switch.play()
	_dbg("Schalter-Sound vorhanden: " + str(s_switch != null))

	# Lichter an (Autoload oder Fallback)
	if typeof(Objectives) != TYPE_NIL and Objectives.has_method("restore_lights"):
		_dbg("Rufe Objectives.restore_lights() auf …")
		Objectives.restore_lights()
	else:
		var c := 0
		for light in get_tree().get_nodes_in_group("Lights"):
			if light is Node3D:
				(light as Node3D).visible = true
				c += 1
		_dbg("Fallback: Lights sichtbar geschaltet. Count=" + str(c))

	# Schilder umschalten
	#var ok := _switch_signs_on_power()
	#if not ok:
		#_warn("⚠️ Konnte keine Schilder finden. Bitte `sign_node`/`sign2_node` oder `sign_path`/`sign2_path` korrekt setzen.")

	# Flags/Step
	is_on = true
	if typeof(Objectives) != TYPE_NIL and Objectives.has_method("set_flag"):
		Objectives.set_flag("power_on", true)
	if typeof(Objectives) != TYPE_NIL and Objectives.has_method("set_step"):
		Objectives.set_step(Objectives.SIGN_CHANGE)

	_log("⚡ Strom eingeschaltet.")

# ----------------------------------------------------------------------
# intern

func _switch_signs_on_power() -> bool:
	var touched := false

	# Priorität 1: direkte Node-Referenzen verwenden, wenn gesetzt

	# Umschalten per Node-Referenz (Node direkt gesetzt oder über Pfad aufgelöst)
	if sign_node != null:
		_dbg("Altes Schild (Node) vorher: " + _vis_str(sign_node))
		_set_visible_recursive(sign_node, false)
		_log("🪧 Alt aus (Node): " + str(sign_node.get_path()))
		touched = true
	else:
		_dbg("❌ Kein `sign_node` vorhanden.")

	if sign2_node != null:
		_dbg("Neues Schild (Node) vorher: " + _vis_str(sign2_node))
		_set_visible_recursive(sign2_node, true)
		_log("🪧 Neu an  (Node): " + str(sign2_node.get_path()))
		touched = true
	else:
		_dbg("❌ Kein `sign2_node` vorhanden.")

	# Fallback: Gruppen
	if not touched:
		var any_old := _set_group_visibility(old_group, false)
		var any_new := _set_group_visibility(new_group, true)
		if any_old:
			_log("🪧 Gruppe " + str(old_group) + ": alle aus")
		if any_new:
			_log("🪧 Gruppe " + str(new_group) + ": alle an")
		touched = any_old or any_new

	return touched

func _set_visible_recursive(n: Node, vis: bool) -> void:
	if n is Node3D:
		(n as Node3D).visible = vis
	elif n is CanvasItem:
		(n as CanvasItem).visible = vis
	for c in n.get_children():
		_set_visible_recursive(c, vis)

func _set_group_visibility(group: StringName, vis: bool) -> bool:
	var found := false
	var count := 0
	for n in get_tree().get_nodes_in_group(group):
		_set_visible_recursive(n, vis)
		found = true
		count += 1
	_dbg("Gruppe " + str(group) + " → vis=" + str(vis) + " count=" + str(count))
	return found

# ----------------------------------------------------------------------
# Debug helpers

func _node_info(n: Node) -> String:
	return "(null)" if n == null else str(n.get_path()) + " [" + n.get_class() + "]"

func _vis_str(n: Node) -> String:
	if n is Node3D:
		return "visible=" + str((n as Node3D).visible)
	if n is CanvasItem:
		return "visible=" + str((n as CanvasItem).visible)
	return "(kein visible-Property)"

func _log(msg: String) -> void:
	print("[breaker] " + msg)

func _dbg(msg: String) -> void:
	if debug_logs:
		_log(msg)

func _warn(msg: String) -> void:
	push_warning(msg)
	_log(msg)
