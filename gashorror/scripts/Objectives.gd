extends Node
signal objective_changed(name: String, data: Dictionary)
signal all_packages_stocked()
signal blackout_triggered()
signal power_restored()

var state := {
	"entered_station": false,
	"packages_total": 6,
	"packages_stocked": 0,
	"basement_unlocked": false,
	"note_spawned": false,

	"basement_entered": false,
	"valve_fixed": false,
	"is_blackout": false,
	"outside_checkpoints_total": 3,
	"outside_checkpoints_hit": 0,
	"power_on": true
}

func set_entered_station():
	if state.entered_station: return
	state.entered_station = true
	emit_signal("objective_changed", "entered_station", state)

func add_stocked_package():
	state.packages_stocked += 1
	emit_signal("objective_changed", "packages_stocked", state)
	if state.packages_stocked >= state.packages_total:
		emit_signal("all_packages_stocked")
		unlock_basement()

func unlock_basement():
	state.basement_unlocked = true
	emit_signal("objective_changed", "basement_unlocked", state)

func mark_note_spawned(): state.note_spawned = true
func mark_basement_entered():
	if state.basement_entered: return
	state.basement_entered = true
	emit_signal("objective_changed", "basement_entered", state)

func mark_valve_fixed():
	if state.valve_fixed: return
	state.valve_fixed = true
	emit_signal("objective_changed", "valve_fixed", state)

func trigger_blackout():
	if state.is_blackout: return
	state.is_blackout = true
	state.power_on = false
	emit_signal("blackout_triggered")
	emit_signal("objective_changed", "blackout", state)

func hit_outside_checkpoint():
	if not state.is_blackout: return
	state.outside_checkpoints_hit = min(state.outside_checkpoints_hit + 1, state.outside_checkpoints_total)
	emit_signal("objective_changed", "outside_progress", state)

func restore_power():
	if not state.is_blackout: return
	state.is_blackout = false
	state.power_on = true
	emit_signal("power_restored")
	emit_signal("objective_changed", "power_restored", state)
