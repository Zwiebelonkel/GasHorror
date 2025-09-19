extends HSlider

func _ready() -> void:
	connect("value_changed", Callable(self, "_on_slider_value_changed"))
	
	var player = get_node_or_null("/root/Main/FpsPlayer/CharacterBody3D")

	if player:
		self.value = player.mouse_sens

func _on_slider_value_changed(value: float) -> void:
	var	player = get_node_or_null("/root/Main/FpsPlayer/CharacterBody3D")
	if player:
		player.call("change_sensitivity", value)
