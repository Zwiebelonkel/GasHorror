extends Control
@onready var obj = $ObjectiveLabel
@onready var prog = $ProgressLabel

func _ready():
	Objectives.objective_changed.connect(_refresh)
	Objectives.all_packages_stocked.connect(_refresh)
	_refresh()

func _refresh(_n=null,_d={}):
	var s = Objectives.state
	if not s.entered_station:
		obj.text = "Ziel: Betrete die Tankstelle."; prog.text = ""
	elif s.packages_stocked < s.packages_total:
		obj.text = "Ziel: Pakete in die Schränke einräumen."
		prog.text = "Fortschritt: %d / %d" % [s.packages_stocked, s.packages_total]
	elif s.basement_unlocked and not s.basement_entered:
		obj.text = "Ziel: Gehe in den Emulsionskeller."; prog.text = ""
	elif s.basement_entered and not s.valve_fixed:
		obj.text = "Ziel: Repariere das Ventil."; prog.text = ""
	elif s.valve_fixed and not s.is_blackout:
		obj.text = "Ziel: Kehre nach oben zurück."; prog.text = ""
	elif s.is_blackout and s.outside_checkpoints_hit < s.outside_checkpoints_total:
		obj.text = "Ziel: Mit Taschenlampe außen einmal herumgehen."
		prog.text = "Außen-Checkpoints: %d / %d" % [s.outside_checkpoints_hit, s.outside_checkpoints_total]
	elif s.is_blackout:
		obj.text = "Ziel: Außen-Stromkasten einschalten."; prog.text = ""
	else:
		obj.text = "Ziel: Licht ist wieder an."; prog.text = ""
