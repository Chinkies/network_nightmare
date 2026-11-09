class_name SimulationRunner
extends Node


# ===================
# ===== SIGNAUX =====
# ===================

signal packet_emitted(packet: NetworkPacket, transmitter: NetworkTransmitter)
signal packet_delivered(packet: NetworkPacket, receiver: NetworkReceiver)
signal packet_dropped(packet: NetworkPacket, source: NetworkItem, reason: String)
signal packet_expired(packet: NetworkPacket, source: NetworkItem)
signal statistics_updated(statistics: Dictionary)
signal simulation_finished
signal stats_updated(processed: int, dropped: int, tx_buffer: int, tx_initial: int)

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

# --- Compteurs de télémétrie en direct ---
var total_processed_count: int = 0
var total_dropped_count: int = 0
var initial_nbr_packets: int = -1

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

		if not device.packet_processed.is_connected(_on_device_packet_processed):
			device.packet_processed.connect(_on_device_packet_processed)
		if not device.packet_dropped.is_connected(_on_device_packet_dropped):
			device.packet_dropped.connect(_on_device_packet_dropped)
		
		if device is NetworkReceiver:
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
	
	if device is NetworkReceiver:
		if device.route_learned.is_connected(apply_route_learning):
			device.route_learned.disconnect(apply_route_learning)


func register_wire(wire: NetworkWire) -> void:
	if not wires.has(wire):
		wires.append(wire)
		if not wire.packet_dropped.is_connected(_on_wire_packet_dropped):
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
	var total_initial_tx = 0
	for device in devices:
		if device is NetworkTransmitter and "emission_schedule" in device:
			total_initial_tx += device.emission_schedule.size()

	statistics = {
		"emitted_count": 0,
		"delivered_count": 0,
		"dropped_count": 0,
		"expired_count": 0,
		"initial_devices_count": initial_devices_count,
		"placed_devices_count": player_devices_count,
		"total_devices_count": devices.size(),
		"elapsed_time": 0.0,
		"initial_tx_packets": total_initial_tx,
		"current_tx_packets": total_initial_tx
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

# Calcul et émission des stats pour l'UI du Panneau d'Objectifs (Bonus)
func _emit_stats() -> void:
	var tx_current = 0
	for device in devices:
		if device is NetworkTransmitter:
			var sched_size = device.emission_schedule.size()
			var sched_index = device.schedule_index
			var buf_size = device.buffer.size()
			tx_current += max(0, sched_size - sched_index) + buf_size
				
	if initial_nbr_packets < 0:
		initial_nbr_packets = tx_current
		statistics["initial_tx_packets"] = initial_nbr_packets
				
	statistics["current_tx_packets"] = tx_current

	_emit_statistics_updated()
	stats_updated.emit(total_processed_count, total_dropped_count, tx_current, initial_nbr_packets)

# Recalcule les stats initiales (utile après l'injection du schedule par le LevelManager)
func recalculate_initial_stats() -> void:
	var total_initial_tx = 0
	for device in devices:
		if device is NetworkTransmitter and "emission_schedule" in device:
			total_initial_tx += device.emission_schedule.size()

	statistics["initial_tx_packets"] = total_initial_tx
	statistics["current_tx_packets"] = total_initial_tx
	initial_nbr_packets = total_initial_tx
	_emit_statistics_updated()

# -------------------------------
# --- Contrôle de l'exécution ---
# -------------------------------

func start() -> void:
	if _simulation_finished_emitted:
		return
	has_started = true
	is_running = true
	
	if initial_nbr_packets < 0:
		initial_nbr_packets = 0
		for device in devices:
			if device is NetworkTransmitter:
				var sched_size = device.emission_schedule.size()
				var sched_index = device.schedule_index
				var buf_size = device.buffer.size()
				initial_nbr_packets += max(0, sched_size - sched_index) + buf_size
					
	_emit_stats()

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
	total_processed_count = 0
	total_dropped_count = 0
	initial_nbr_packets = -1
	reset_statistics()

	for device in devices:
		if device.has_method("reset_state"):
			device.reset_state()
			
	for wire in wires:
		if wire.has_method("reset_state"):
			wire.reset_state()

	_emit_stats()



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
	_update_ephemeral_packets(delta)

	for device in devices:
		device.simulate(delta)

	for wire in wires:
		wire.simulate(delta)

	_check_simulation_finished()


# Parcourt la liste globale des paquets éphémères et marque ceux qui expirent
func _update_ephemeral_packets(delta: float) -> void:
	for i in range(ephemeral_packets.size() - 1, -1, -1):
		var packet: NetworkPacket = ephemeral_packets[i]
		
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



# ------------------------------------------------------
# --- Gestion des événements de paquets (UI & Stats) ---
# ------------------------------------------------------

func _on_device_packet_processed(device: NetworkDevice, packet: NetworkPacket) -> void:
	if device is NetworkTransmitter:
		register_ephemeral_packet(packet)
		_increment_statistic("emitted_count")
		packet_emitted.emit(packet, device)
		_emit_stats()
	elif device is NetworkReceiver:
		_unregister_ephemeral_packet(packet)
		_increment_statistic("delivered_count")
		total_processed_count += 1
		packet_delivered.emit(packet, device)
		_emit_stats()
	else:
		_emit_stats()


func _on_device_packet_dropped(device: NetworkDevice, packet: NetworkPacket, reason: String) -> void:
	_unregister_ephemeral_packet(packet)
	total_dropped_count += 1
	if reason == "TTL expired":
		_increment_statistic("expired_count")
		packet_expired.emit(packet, device)
	else:
		_increment_statistic("dropped_count")
		packet_dropped.emit(packet, device, reason)
	_emit_stats()


func _on_wire_packet_dropped(wire: NetworkWire, packet: NetworkPacket, reason: String) -> void:
	_unregister_ephemeral_packet(packet)
	total_dropped_count += 1
	if reason == "TTL expired":
		_increment_statistic("expired_count")
		packet_expired.emit(packet, wire)
	else:
		_increment_statistic("dropped_count")
		packet_dropped.emit(packet, wire, reason)
	_emit_stats()


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
