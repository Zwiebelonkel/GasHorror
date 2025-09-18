extends Area3D

# Exportierte Variablen
@export var manager: CharacterBody3D  # Referenz zum Manager (der NPC, der verfolgt wird)

# Signal-Handler, wenn ein Körper den Trigger betritt
func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):  # Überprüfen, ob der Körper der Spieler ist
		print("Spieler hat den Trigger betreten!")
		Objectives.set_step(Objectives.TRY_TO_ESCAPE)
		Objectives.state["seen_truth"] = true;
		Objectives.state["manager_triggered"] = true;

		#manager.is_active = true  # Aktiviert den Manager, damit er beginnt, den Spieler zu verfolgen
		#print("Manger ist aktiv: ",manager.is_active)

# Optional: Entferne den Trigger, wenn der Spieler den Bereich verlässt
func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):  # Überprüfen, ob der Körper der Spieler ist
		print("Spieler hat den Trigger verlassen!")
