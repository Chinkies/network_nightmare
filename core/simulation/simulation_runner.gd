class_name SimulationRunner
extends Node

# --- Signaux ---

signal packet_emitted(packet: NetworkPacket, transmitter: NetworkTransmitter)
signal packet_delivered(packet: NetworkPacket, receiver: NetworkReceiver)
signal packet_dropped(packet: NetworkPacket, source: NetworkItem, reason: String)
signal packet_expired(packet: NetworkPacket, source: NetworkItem)
signal statistics_updated(statistics: Dictionary)
signal simulation_finished


# =====================
# ===== ATTRIBUTS =====
# =====================

# --- Registres actifs de la simulation ---
var devices: Array[NetworkDevice] = []
var _device_map: Dictionary = {}
var wires: Array[NetworkWire] = []
var ephemeral_packets: Array[NetworkPacket] = []
var statistics: Dictionary = {}
var initial_devices_count: int = 0
var player_devices_count: int = 0

# --- Contrôle du temps de simulation ---
var is_running: bool = false
var has_started: bool = false
var _simulation_finished_emitted: bool = false
var simulation_speed: float = 1.0


# ====================
# ===== METHODES =====
# ====================

func _ready() -> void:
	reset_statistics()


# --------------------------------
# --- Enregistrement d'entités ---
# --------------------------------

func register_device(device: NetworkDevice) -> void:
	if not devices.has(device):
		devices.append(device)
		_device_map[device.id] = device
		_update_statistics_device_count()
		_emit_statistics_updated()

		device.packet_processed.connect(_on_device_packet_processed)
		device.packet_dropped.connect(_on_device_packet_dropped)
		
		# Connexion dynamique si la machine est un Receiver
		if device is NetworkReceiver:
			# On connecte le signal à la méthode apply_route_learning
			if not device.route_learned.is_connected(apply_route_learning):
				device.route_learned.connect(apply_route_learning)


func unregister_device(device: NetworkDevice) -> void:
	devices.erase(device)
	_device_map.erase(device.id)
	_update_statistics_device_count()
	_emit_statistics_updated()

	if device.packet_processed.is_connected(_on_device_packet_processed):
		device.packet_processed.disconnect(_on_device_packet_processed)
	if device.packet_dropped.is_connected(_on_device_packet_dropped):
		device.packet_dropped.disconnect(_on_device_packet_dropped)
	
	# Déconnexion propre
	if device is NetworkReceiver:
		if device.route_learned.is_connected(apply_route_learning):
			device.route_learned.disconnect(apply_route_learning)


func register_wire(wire: NetworkWire) -> void:
	if not wires.has(wire):
		wires.append(wire)

		wire.packet_dropped.connect(_on_wire_packet_dropped)


func unregister_wire(wire: NetworkWire) -> void:
	wires.erase(wire)

	if wire.packet_dropped.is_connected(_on_wire_packet_dropped):
		wire.packet_dropped.disconnect(_on_wire_packet_dropped)


# Appelée dès qu'un paquet avec TTL > 0 est instancié
func register_ephemeral_packet(packet: NetworkPacket) -> void:
	if packet.ttl > 0.0 and not ephemeral_packets.has(packet):
		ephemeral_packets.append(packet)


func _unregister_ephemeral_packet(packet: NetworkPacket) -> void:
	ephemeral_packets.erase(packet)



# --------------------------------
# --- Gestion des statistiques ---
# --------------------------------

func reset_statistics() -> void:
	statistics = {
		"emitted_count": 0,
		"delivered_count": 0,
		"dropped_count": 0,
		"expired_count": 0,
		"initial_devices_count": initial_devices_count,
		"placed_devices_count": player_devices_count,
		"total_devices_count": devices.size(),
		"elapsed_time": 0.0
	}
	statistics_updated.emit(statistics.duplicate())


func get_statistics() -> Dictionary:
	return statistics.duplicate()


func _update_statistics_device_count() -> void:
	statistics["initial_devices_count"] = initial_devices_count
	statistics["placed_devices_count"] = player_devices_count
	statistics["total_devices_count"] = devices.size()


func set_initial_device_count(count: int) -> void:
	initial_devices_count = maxi(0, count)
	player_devices_count = 0
	_update_statistics_device_count()
	_emit_statistics_updated()


func record_player_device_placed() -> void:
	player_devices_count += 1
	_update_statistics_device_count()
	_emit_statistics_updated()


func record_player_device_removed() -> void:
	player_devices_count = maxi(0, player_devices_count - 1)
	_update_statistics_device_count()
	_emit_statistics_updated()


func _emit_statistics_updated() -> void:
	statistics_updated.emit(statistics.duplicate())


func _increment_statistic(key: String) -> void:
	statistics[key] = statistics.get(key, 0) + 1
	_emit_statistics_updated()



# -------------------------------
# --- Contrôle de l'exécution ---
# -------------------------------

func start() -> void:
	if _simulation_finished_emitted:
		return
	has_started = true
	is_running = true

func stop() -> void:
	is_running = false

func toggle() -> void:
	is_running = not is_running
	if is_running:
		has_started = true


# Reset le runner de simulation
func reset_runner() -> void:
	stop()
	ephemeral_packets.clear()
	has_started = false
	_simulation_finished_emitted = false
	reset_statistics()
	
	for device in devices:
		if device.has_method("reset_state"):
			device.reset_state()
			
	for wire in wires:
		if wire.has_method("reset_state"):
			wire.reset_state()



# -------------------------
# --- Boucle principale ---
# -------------------------

func _physics_process(delta: float) -> void:
	if not is_running:
		return
	
	statistics["elapsed_time"] += delta * simulation_speed
	_update_statistics_device_count()
	_emit_statistics_updated()
	step(delta * simulation_speed)


# Exécute un pas discret de simulation complet
func step(delta: float) -> void:
	# 1. Mise à jour de l'horloge des paquets éphémères
	_update_ephemeral_packets(delta)

	# 2. Simulation des machines (consommation du buffer, timers internes, injections)
	for device in devices:
		device.simulate(delta)

	# 3. Simulation des câbles (mouvements, bouchons, arrivées en bout de ligne)
	for wire in wires:
		wire.simulate(delta)

	_check_simulation_finished()


# Parcourt la liste globale des paquets éphémères et marque ceux qui expirent
func _update_ephemeral_packets(delta: float) -> void:
	for i in range(ephemeral_packets.size() - 1, -1, -1):
		var packet: NetworkPacket = ephemeral_packets[i]
		
		# Si le paquet a expiré lors de ce pas de temps
		if packet.update_ttl(delta):
			ephemeral_packets.remove_at(i)


func _check_simulation_finished() -> void:
	if _simulation_finished_emitted or not has_started:
		return

	for device in devices:
		if device is NetworkTransmitter and device.schedule_index < device.emission_schedule.size():
			return
		if not device.buffer.is_empty():
			return

	for wire in wires:
		if not wire.transit_queue.is_empty():
			return

	if not ephemeral_packets.is_empty():
		return

	_simulation_finished_emitted = true
	is_running = false
	simulation_finished.emit()



# -----------------------------------------------
# --- Interface de communication inter-device ---
# -----------------------------------------------

func _on_device_packet_processed(device: NetworkDevice, packet: NetworkPacket) -> void:
	if device is NetworkTransmitter:
		register_ephemeral_packet(packet)
		_increment_statistic("emitted_count")
		packet_emitted.emit(packet, device)
	elif device is NetworkReceiver:
		_unregister_ephemeral_packet(packet)
		_increment_statistic("delivered_count")
		packet_delivered.emit(packet, device)


func _on_device_packet_dropped(device: NetworkDevice, packet: NetworkPacket, reason: String) -> void:
	_unregister_ephemeral_packet(packet)
	if reason == "TTL expired":
		_increment_statistic("expired_count")
		packet_expired.emit(packet, device)
	else:
		_increment_statistic("dropped_count")
		packet_dropped.emit(packet, device, reason)


func _on_wire_packet_dropped(wire: NetworkWire, packet: NetworkPacket, reason: String) -> void:
	_unregister_ephemeral_packet(packet)
	if reason == "TTL expired":
		_increment_statistic("expired_count")
		packet_expired.emit(packet, wire)
	else:
		_increment_statistic("dropped_count")
		packet_dropped.emit(packet, wire, reason)



# -----------------------------------------------
# --- Interface de communication inter-device ---
# -----------------------------------------------

# Appelée par une machine terminale (Receiver) quand un paquet est validé
func apply_route_learning(routing_history: Dictionary, packet_color: int, target_number: int) -> void:
	for switch_id in routing_history.keys():
		var port_used: int = routing_history[switch_id]
		
		# On vérifie de manière sécurisée si la machine existe toujours dans le registre
		var device = _device_map.get(switch_id, null)
		
		# Si la machine est bien un switch, on lui demande de mettre à jour sa table
		if device != null and device is NetworkSwitch:
			device.learn_route(packet_color, target_number, port_used)
