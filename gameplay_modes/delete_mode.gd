class_name DeleteMode
extends BaseMode


# =====================
# ===== ATTRIBUTS =====
# =====================

@export var grid_board: GridBoard
@export var grid_view: GridView
@export var simulation: SimulationRunner

var delete_timer: Timer
var target_item: NetworkItem = null 


# ====================
# ===== METHODES =====
# ====================

func _ready() -> void:
	# Vérification des dépendances 
	assert(simulation != null, "[DeleteMode] Erreur critique : SimulationRunner non assigné !")
	assert(grid_board != null, "[DeleteMode] Erreur critique : GridBoard non assigné !")
	assert(grid_view != null, "[DeleteMode] Erreur critique : GridView non assigné !")
	
	# Création du chronomètre interne
	delete_timer = Timer.new()
	delete_timer.wait_time = 2.0
	delete_timer.one_shot = true
	delete_timer.timeout.connect(_on_delete_timeout)
	add_child(delete_timer)


# --------------------------------
# --- Entrée et sortie du mode ---
# --------------------------------

func enter_mode() -> void:
	print("[DeleteMode] Prêt à détruire.")

func exit_mode() -> void:
	cancel_action()


## Annule la sélection en cours (reset le timer de suppression)
## Retourne un booléen indiquant si une sélection était en cours et a été annulée
func cancel_action() -> bool:
	if not delete_timer.is_stopped():
		_stop_deletion()
		return true
	return false


# --------------------------------
# --- Réception des événements ---
# --------------------------------

func handle_item_interaction_started(item: NetworkItem) -> void:
	if item == null or not delete_timer.is_stopped():
		return

	target_item = item
	delete_timer.start()
	print("[DeleteMode] Suppression commencée... Maintenez le clic.")
	
	# TODO plus tard : Déclencher un feedback visuel (barre de chargement, clignotement rouge, etc.)


func handle_item_interaction_ended(item: NetworkItem) -> void:
	if target_item == item:
		_stop_deletion()
		print("[DeleteMode] Suppression annulée.")


# ----------------------
# --- Logique privée ---
# ----------------------

func _stop_deletion() -> void:
	delete_timer.stop()
	target_item = null
	# TODO plus tard : Stopper le feedback visuel


## Déclenche la suppression de l'item séléctionné
func _on_delete_timeout() -> void:
	var item := target_item
	_stop_deletion()

	if item is NetworkWire:
		_remove_wire(item)
	elif item is NetworkDevice:
		_remove_device(item)


## Supprime un wire et sa vue de tous les systèmes du niveau
func _remove_wire(wire: NetworkWire) -> void:
	# Déconnection des ports des devices
	var from_device := wire.from_device
	var to_device := wire.to_device

	if from_device.output_wires.get(wire.from_port) == wire:
		from_device.disconnect_output(wire.from_port)
		grid_view.set_port_available(from_device, wire.from_port)

	if to_device.input_wires.get(wire.to_port) == wire:
		to_device.disconnect_input(wire.to_port)
		grid_view.set_port_available(to_device, wire.to_port)

	# Suppression des registres
	grid_board.unregister_wire(wire)
	simulation.unregister_wire(wire)

	# Suppression de la vue
	var wire_view := grid_view.get_wire_view(wire)
	grid_view.unregister_wire_view(wire)

	if wire_view != null:
		wire_view.queue_free()


## Supprime un wire et sa vue de tous les systèmes du niveau
func _remove_device(device: NetworkDevice) -> void:
	# On récupère tous les wires connectés au device
	var connected_wires: Array[NetworkWire] = []

	for wire in device.input_wires.values():
		if not connected_wires.has(wire):
			connected_wires.append(wire)

	for wire in device.output_wires.values():
		if not connected_wires.has(wire):
			connected_wires.append(wire)
	
	# On supprime tous les câbles connectés
	for wire in connected_wires:
		_remove_wire(wire)
	
	# On supprime le device des registres
	grid_board.unregister_device(device)
	simulation.unregister_device(device)
	
	# On délie la vue et on la supprime
	var device_view := grid_view.get_device_view(device)
	grid_view.unregister_device_view(device)

	if device_view != null:
		device_view.queue_free()
