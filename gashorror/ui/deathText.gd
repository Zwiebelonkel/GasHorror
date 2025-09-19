extends Control

@onready var label_index: Label = $LabelIndex
@onready var label_title: Label = $LabelTitle

@export var typing_speed := 0.09  # Sekunden pro Buchstabe

func _ready() -> void:
	# Zeige Title mit Schreibmaschineneffekt
	var full_text = "YOU DIED"
	label_title.text = ""
	type_text(label_title, full_text)
	

func type_text(label: Label, text: String) -> void:
	# Coroutine starten
	async_func(label, text)


func async_func(label: Label, text: String) -> void:
	for i in text.length():
		label.text += text[i]
		await get_tree().create_timer(typing_speed).timeout
