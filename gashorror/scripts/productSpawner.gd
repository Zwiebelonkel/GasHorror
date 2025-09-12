extends Node3D

@export var possible_products: Array[PackedScene] = []

func _ready():
	randomize()
	if possible_products.is_empty():
		print("⚠️ Keine Produkte vorhanden")
		queue_free()
		return

	var random_index = randi() % possible_products.size()
	var selected_scene = possible_products[random_index]
	var product_instance = selected_scene.instantiate()
	
	# Produkt an dieselbe Stelle setzen
	add_child(product_instance)
	product_instance.transform = Transform3D.IDENTITY
