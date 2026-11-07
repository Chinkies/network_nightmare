class_name ModeManager
extends Node

# =====================
# ===== ENUMS =========
# =====================

enum GameMode {
	EDIT,
	WIRING,
	DELETE,
	SIMULATION
}

# ======================
# ===== ATTRIBUTS ======
# ======================

signal mode_changed(new_mode: BaseMode)

var current_mode: BaseMode
var previous_mode: BaseMode

@onready var edit_mode = $EditMode
@onready var wiring_mode = $WiringMode
@onready var delete_mode = $DeleteMode
@onready var simulation_mode = $SimulationMode


# =====================
# ===== METHODES ======
# =====================

func _ready() -> void:
	# Injection de dépendance : on donne aux enfants l'accès au manager
	for child in get_children():
		if child is BaseMode:
			child.mode_manager = self
	
	# État initial au lancement
	call_deferred("switch_mode", edit_mode)


# --- Gestion des modes ---

func switch_mode_by_enum(mode_enum: GameMode, save_history: bool = false) -> void:
	var target_mode: BaseMode = null
	
	match mode_enum:
		GameMode.EDIT:
			target_mode = edit_mode
		GameMode.WIRING:
			target_mode = wiring_mode
		GameMode.DELETE:
			target_mode = delete_mode
		GameMode.SIMULATION:
			target_mode = simulation_mode
			
	if target_mode:
		switch_mode(target_mode, save_history)

func switch_mode(new_mode: BaseMode, save_history: bool = false) -> void:
	if current_mode == new_mode:
		return
		
	if save_history and current_mode:
		previous_mode = current_mode
		
	if current_mode:
		current_mode.exit_mode()
		
	current_mode = new_mode
	
	if current_mode:
		current_mode.enter_mode()

	mode_changed.emit(current_mode)


func switch_to_previous_mode() -> void:
	if previous_mode:
		switch_mode(previous_mode, false)
		previous_mode = null


## Tente d'annuler l'action du mode courant. Retourne true si le signal a été consommé.
func cancel_action() -> bool:
	if current_mode and current_mode.has_method("cancel_action"):
		return current_mode.cancel_action()
	return false


func on_device_drop_requested(cell: Vector2i, device_data: Variant) -> void:
	# Seuls les modes qui possèdent explicitement cette méthode (Edition, Wiring, Delete) la recevront.
	if current_mode and current_mode.has_method("handle_device_drop"):
		current_mode.handle_device_drop(cell, device_data)
	else:
		# Optionnel : log de debug pour vérifier que le drop est bien bloqué en mode simulation
		# print("[ModeManager] Drop ignoré, mode inadapté.")
		pass


func on_port_interaction_requested(device: NetworkDevice, local_port_id: int) -> void:
	print("[ModeManager] Clic détecté sur le port ", local_port_id, " de l'appareil ", device.id)
	
	# Seul le WiringMode (et éventuellement DeleteMode plus tard si tu veux cliquer sur un port pour supprimer son câble) réagira.
	if current_mode and current_mode.has_method("handle_port_click"):
		current_mode.handle_port_click(device, local_port_id)


func on_item_interaction_started(item: Variant) -> void:
	if current_mode and current_mode.has_method("handle_item_interaction_started"):
		current_mode.handle_item_interaction_started(item)


func on_item_interaction_ended(item: Variant) -> void:
	if current_mode and current_mode.has_method("handle_item_interaction_ended"):
		current_mode.handle_item_interaction_ended(item)
