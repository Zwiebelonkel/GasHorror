extends Node

signal objective_changed(name: String, data: Dictionary)
signal all_packages_stocked()  # <-- Hier hinzufügen

# Enum für besser lesbare States
enum {
	START,
	PACKAGES,
	CUSTOMER,
	BLACKOUT,
	FIND_NOTE,
	FIND_KEY,
	JUMPSCARE,
	POWER_ON,
	SIGN_CHANGE,
	REENTER_CELLAR,
	SECRET_ENTRANCE,
	SEE_TRUTH,
	TRY_TO_ESCAPE,
	MANAGER_APPEARS,
	ESCAPE,
	END
}

var current_step := START

var state := {
	"entered_station": false,
	"packages_stocked": 0,
	"packages_total": 4,
	"customer_spoken": false,
	"blackout": false,
	"found_note": false,
	"has_key": false,
	"jumpscare_done": false,
	"power_on": false,
	"sign_changed": false,
	"found_secret": false,
	"seen_truth": false,
	"manager_triggered": false,
	"escaped": false
}

func _ready():
	emit_signal("objective_changed", get_current_objective_name(), state)

func advance():
	current_step += 1
	emit_signal("objective_changed", get_current_objective_name(), state)

func set_step(step: int):
	current_step = step
	emit_signal("objective_changed", get_current_objective_name(), state)

func get_current_objective_name() -> String:
	match current_step:
		START:
			return "Ziel: Betrete die Tankstelle."
		PACKAGES:
			return "Ziel: Pakete in die Schränke einräumen."
		CUSTOMER:
			return "Ziel: Sprich mit dem Kunden."
		BLACKOUT:
			return "Ziel: Der Strom ist ausgefallen!"
		FIND_NOTE:
			return "Ziel: Abgeschlossen: Schaue im Laden nach einer Notiz."
		FIND_KEY:
			return "Ziel: Finde den Schlüssel im Keller."
		JUMPSCARE:
			return "Ziel: Kehre nach oben zurück."
		POWER_ON:
			return "Ziel: Schalte den Strom wieder an."
		SIGN_CHANGE:
			return "Ziel: Das Schild draußen hat sich verändert..."
		REENTER_CELLAR:
			return "Ziel: Gehe erneut in den Keller."
		SECRET_ENTRANCE:
			return "Ziel: Finde einen geheimen Zugang."
		SEE_TRUTH:
			return "Ziel: Entdecke, was wirklich hier unten passiert."
		TRY_TO_ESCAPE:
			return "Ziel: Fliehe aus der Tankstelle!"
		MANAGER_APPEARS:
			return "Ziel: Der Manager ist hier – lauf!"
		ESCAPE:
			return "Ziel: Entkomme!"
		END:
			return "Ziel erreicht. (Oder doch nicht?)"
		_:
			return "Ziel: ???"

func progress_package_stock():
	state.packages_stocked += 1
	emit_signal("objective_changed", get_current_objective_name(), state)
	
	if state.packages_stocked >= state.packages_total:
		emit_signal("all_packages_stocked")  # Signal feuern, wenn alles fertig ist
		advance()

		
func enter_station():
	if current_step == START:
		state.entered_station = true
		set_step(PACKAGES)  # Hier wird dann das Signal emittiert
		
func blackOut():
	if current_step == CUSTOMER:
		state.blackout = true
		set_step(BLACKOUT)

		# 🕯️ Lichter ausschalten
		for light in get_tree().get_nodes_in_group("Lights"):
			if light is Light3D:
				light.visible = false

		# 💡 Emission-Materialien deaktivieren
		for mesh in get_tree().get_nodes_in_group("Emissive"):
			if mesh is MeshInstance3D:
				var mat = mesh.get_active_material()
				if mat is StandardMaterial3D:
					mat.emission_enabled = false
					mesh.set_surface_override_material(0, mat)
					
func found_locked_breaker():
	if current_step < FIND_NOTE:
		set_step(FIND_NOTE)


func restore_lights():
	if current_step == BLACKOUT:
		state.blackout = true
		set_step(BLACKOUT)
	for light in get_tree().get_nodes_in_group("Lights"):
		light.visible = true

	#for mesh in get_tree().get_nodes_in_group("Emissive"):
		#var mat = mesh.get_active_material()
		#if mat is StandardMaterial3D:
			#mat.emission_enabled = true
			#mesh.set_surface_override_material(0, mat)




func set_flag(key: String, value: bool):
	if state.has(key):
		state[key] = value
	emit_signal("objective_changed", get_current_objective_name(), state)
