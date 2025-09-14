extends CanvasLayer

@export var player_path: NodePath = ^"/root/Main/FpsPlayer/CharacterBody3D"
@export var debug_logs: bool = true

@onready var _panel: Panel        = $Panel
@onready var _title: Label        = $Panel/VBox/Title
@onready var _input: LineEdit     = $Panel/VBox/Input
@onready var _ok_btn: Button      = $Panel/VBox/HBox/OkBtn
@onready var _cancel_btn: Button  = $Panel/VBox/HBox/CancelBtn

var _cb: Callable = Callable()
var _required_len: int = 0
var _open: bool = false

func _ready() -> void:
	visible = false
	_ok_btn.pressed.connect(_on_ok)
	_cancel_btn.pressed.connect(_on_cancel)
	_input.text_submitted.connect(func(_t): _on_ok())
	_log("ready; player_path=", str(player_path))

func is_open() -> bool:
	return _open

# Öffnet den Code-Dialog
# required_len: 0 = beliebig; >0 = feste Länge (z. B. 4)
# mask: true = Sternchenanzeige
# cb(ok: bool, code: String)
func open_code(title: String, required_len: int, mask: bool, cb: Callable) -> void:
	if _open:
		_log("open_code(): already open – ignoring")
		return
	_open = true
	_cb = cb
	_required_len = max(required_len, 0)

	_title.text = title
	_input.text = ""
	_input.secret = mask
	_input.max_length = (_required_len if _required_len > 0 else 0)

	visible = true
	_set_player_look_enabled(false)
	await get_tree().process_frame
	_input.grab_focus()
	_log("open_code(): shown")

func _on_ok() -> void:
	var code := _input.text.strip_edges()
	if _required_len > 0 and code.length() != _required_len:
		# kurze visuelle Rückmeldung
		_input.modulate = Color(1, 0.6, 0.6)
		await get_tree().create_timer(0.15).timeout
		_input.modulate = Color(1, 1, 1)
		_log("on_ok(): wrong length: ", str(code.length()), " expected: ", str(_required_len))
		return
	_finish(true, code)

func _on_cancel() -> void:
	_finish(false, "")

func _finish(ok: bool, code: String) -> void:
	if not _open:
		return
	_open = false
	visible = false
	_set_player_look_enabled(true)

	var cb := _cb
	_cb = Callable()
	_log("_finish(): ok=", str(ok), " code='", code, "'")
	if cb.is_valid():
		cb.call(ok, code)

func _unhandled_input(event: InputEvent) -> void:
	if not _open:
		return
	if event.is_action_pressed("ui_cancel"):
		_on_cancel()

# ------- Player-Handling (ohne has_variable) --------
func _set_player_look_enabled(enable_look: bool) -> void:
	var player := get_node_or_null(player_path)
	if player == null:
		_log("_set_player_look_enabled(): player not found at ", str(player_path))
	else:
		if _has_property(player, &"can_look"):
			player.set("can_look", enable_look)
			_log("player.can_look = ", str(enable_look))
		else:
			_log("player has no 'can_look' property (skipping)")

	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED if enable_look else Input.MOUSE_MODE_VISIBLE)

func _has_property(obj: Object, prop: StringName) -> bool:
	for info in obj.get_property_list():
		if info.has("name") and String(info["name"]) == String(prop):
			return true
	return false

# ------- Debug helper -------
func _log(a: String, b: String = "", c: String = "", d: String = "", e: String = "") -> void:
	if not debug_logs:
		return
	print("[code_ui] " + a + b + c + d + e)
