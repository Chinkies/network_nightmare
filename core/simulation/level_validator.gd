class_name LevelValidator
extends Node


# =====================
# ===== SIGNAUX =======
# =====================

signal objective_updated(objective_id: String, fulfilled: bool)
signal validation_finished(result: Dictionary)


# =====================
# ===== ATTRIBUTS =====
# =====================

var level_definition: LevelDefinition
var simulation: SimulationRunner
var objective_states: Dictionary = {}
var last_result: Dictionary = {}
var _has_validated: bool = false



# ====================
# ===== METHODES =====
# ====================

# -----------------------------------
# --- Configuration du validateur ---
# -----------------------------------

func setup(p_level_definition: LevelDefinition, p_simulation: SimulationRunner) -> void:
	if simulation != null:
		_disconnect_simulation_signals()

	level_definition = p_level_definition
	simulation = p_simulation
	objective_states.clear()
	last_result.clear()
	_has_validated = false

	if simulation == null:
		push_error("[LevelValidator] SimulationRunner manquant.")
		return

	simulation.statistics_updated.connect(_on_statistics_updated)
	simulation.packet_emitted.connect(_on_packet_event)
	simulation.packet_delivered.connect(_on_packet_event)
	simulation.packet_dropped.connect(_on_packet_dropped_event)
	simulation.packet_expired.connect(_on_packet_expired_event)
	simulation.simulation_finished.connect(validate)
	_initialize_objective_states()


# -------------------------------------
# --- Réinitialisation & validation ---
# -------------------------------------

func reset() -> void:
	objective_states.clear()
	last_result.clear()
	_has_validated = false
	_initialize_objective_states()


func validate() -> Dictionary:
	if level_definition == null or simulation == null:
		push_error("[LevelValidator] Validation impossible : configuration incomplète.")
		return {}

	if _has_validated:
		return last_result.duplicate(true)

	var statistics := simulation.get_statistics()
	var completed: Array[String] = []
	var failed: Array[String] = []

	for objective in level_definition.objectives:
		if objective == null:
			continue

		var fulfilled := objective.check_fulfillment(statistics)
		objective_states[objective.objective_id] = fulfilled
		objective_updated.emit(objective.objective_id, fulfilled)

		if fulfilled:
			completed.append(objective.objective_id)
		else:
			failed.append(objective.objective_id)

	last_result = {
		"success": failed.is_empty(),
		"objectives_completed": completed,
		"objectives_failed": failed,
		"statistics": statistics
	}
	_has_validated = true
	validation_finished.emit(last_result.duplicate(true))
	return last_result.duplicate(true)



# -----------------------------
# --- Gestion des objectifs ---
# -----------------------------

func _initialize_objective_states() -> void:
	if level_definition == null:
		return

	for objective in level_definition.objectives:
		if objective != null:
			objective_states[objective.objective_id] = false


# --------------------------------
# --- Réception des événements ---
# --------------------------------

func _on_statistics_updated(statistics: Dictionary) -> void:
	if _has_validated or level_definition == null:
		return

	for objective in level_definition.objectives:
		if objective == null:
			continue

		var objective_id := objective.objective_id
		var fulfilled := objective.check_fulfillment(statistics)
		if objective_states.get(objective_id, false) != fulfilled:
			objective_states[objective_id] = fulfilled
			objective_updated.emit(objective_id, fulfilled)


func _on_packet_event(_packet: NetworkPacket, _source: NetworkItem) -> void:
	pass


func _on_packet_dropped_event(_packet: NetworkPacket, _source: NetworkItem, _reason: String) -> void:
	pass


func _on_packet_expired_event(_packet: NetworkPacket, _source: NetworkItem) -> void:
	pass



# -------------------
# --- Déconnexion ---
# -------------------

func _disconnect_simulation_signals() -> void:
	if not is_instance_valid(simulation):
		return

	if simulation.statistics_updated.is_connected(_on_statistics_updated):
		simulation.statistics_updated.disconnect(_on_statistics_updated)
	if simulation.packet_emitted.is_connected(_on_packet_event):
		simulation.packet_emitted.disconnect(_on_packet_event)
	if simulation.packet_delivered.is_connected(_on_packet_event):
		simulation.packet_delivered.disconnect(_on_packet_event)
	if simulation.packet_dropped.is_connected(_on_packet_dropped_event):
		simulation.packet_dropped.disconnect(_on_packet_dropped_event)
	if simulation.packet_expired.is_connected(_on_packet_expired_event):
		simulation.packet_expired.disconnect(_on_packet_expired_event)
	if simulation.simulation_finished.is_connected(validate):
		simulation.simulation_finished.disconnect(validate)
