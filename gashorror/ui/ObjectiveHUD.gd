extends CanvasLayer

@onready var obj_label = $Control/ObjectiveLabel
@onready var prog_label = $Control/ProgressLabel

# Zugriff auf das Objectives-Singleton
var objectives = Objectives

func _ready():
	print("HUD Skript geladen, Objectives Instanz-ID:", objectives.get_instance_id())	
	print("objectives ist: ", objectives)

	if not objectives.objective_changed.is_connected(_refresh):
		objectives.objective_changed.connect(_refresh)
		print("Signal 'objective_changed' verbunden")
	
	_refresh()

# Signal-Handler
func _refresh(_n = null, _d = {}):
	print("HUD _refresh aufgerufen mit Signal:", _n)
	var s = objectives.state
	print("State im HUD:", s)

	# Objective-Text vom Singleton holen
	obj_label.text = objectives.get_current_objective_name()

	# Fortschrittsanzeige, wenn relevant
	match objectives.current_step:
		objectives.PACKAGES:
			prog_label.text = "Fortschritt: %d / %d" % [s.packages_stocked, s.packages_total]
		objectives.BLACKOUT:
			prog_label.text = "Stromstatus: AUS"
		objectives.SEE_TRUTH:
			prog_label.text = "Ort: Unterirdische Anlage"
		_:
			prog_label.text = ""
