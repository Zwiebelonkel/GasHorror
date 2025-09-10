extends CanvasLayer  # Oder Control, je nachdem was bei dir passt

@onready var obj_label = $Control/ObjectiveLabel
@onready var prog_label = $Control/ProgressLabel

# Zugriff auf dein Objectives-Singleton (Autoload)
var objectives = Objectives

func _ready():
	print("HUD Skript geladen, Objectives Instanz-ID:", objectives.get_instance_id())	
	print("objectives ist: ", objectives)
	var connected = objectives.objective_changed.is_connected(_refresh)
	print("Signal 'objective_changed' verbunden? ", connected)
	
	# Verbinde sicherheitshalber nochmal
	if not connected:
		objectives.objective_changed.connect(_refresh)
		print("Signal 'objective_changed' neu verbunden")
	
	objectives.all_packages_stocked.connect(_refresh)
	_refresh()

# Signal-Handler für alle Änderungen
# _n: Name der geänderten Objective (z.B. "packages_stocked")
# _d: Daten (dein State Dictionary)
func _refresh(_n = null, _d = {}):
	print("HUD _refresh aufgerufen mit Signal:", _n)
	var s = objectives.state
	print("State im HUD:", s)

	if not s.entered_station:
		obj_label.text = "Ziel: Betrete die Tankstelle."
		prog_label.text = ""
	elif s.packages_stocked < s.packages_total:
		obj_label.text = "Ziel: Pakete in die Schränke einräumen."
		prog_label.text = "Fortschritt: %d / %d" % [s.packages_stocked, s.packages_total]
	elif s.basement_unlocked and not s.basement_entered:
		obj_label.text = "Ziel: Gehe in den Emulsionskeller."
		prog_label.text = ""
	elif s.basement_entered and not s.valve_fixed:
		obj_label.text = "Ziel: Repariere das Ventil."
		prog_label.text = ""
	elif s.valve_fixed and not s.is_blackout:
		obj_label.text = "Ziel: Kehre nach oben zurück."
		prog_label.text = ""
	elif s.is_blackout and s.outside_checkpoints_hit < s.outside_checkpoints_total:
		obj_label.text = "Ziel: Mit Taschenlampe außen einmal herumgehen."
		prog_label.text = "Außen-Checkpoints: %d / %d" % [s.outside_checkpoints_hit, s.outside_checkpoints_total]
	elif s.is_blackout:
		obj_label.text = "Ziel: Außen-Stromkasten einschalten."
		prog_label.text = ""
	else:
		obj_label.text = "Ziel: Licht ist wieder an."
		prog_label.text = ""
