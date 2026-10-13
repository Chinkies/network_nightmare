class_name NetworkSimulation
extends Node

# =====================
# ===== ATTRIBUTS =====
# =====================

# --- Registres actifs de la simulation ---
var devices: Array[NetworkDevice] = []
var _device_map: Dictionary = {}
var wires: Array[NetworkWire] = []
var ephemeral_packets: Array[NetworkPacket] = []

# --- Contrôle du temps de simulation ---
var is_running: bool = false
var simulation_speed: float = 1.0


# ====================
# ===== METHODES =====
# ====================

# --- Enregistrement d'entités ---

func register_device(device: NetworkDevice) -> void:
	if not devices.has(device):
		devices.append(device)
		_device_map[device.id] = device
		
		# Connexion dynamique si la machine est un Receiver
		if device is NetworkReceiver:
			# On connecte le signal à la méthode apply_route_learning
			if not device.route_learned.is_connected(apply_route_learning):
				device.route_learned.connect(apply_route_learning)

func unregister_device(device: NetworkDevice) -> void:
	devices.erase(device)
	_device_map.erase(device.id)
	
	# Déconnexion propre
	if device is NetworkReceiver:
		if device.route_learned.is_connected(apply_route_learning):
			device.route_learned.disconnect(apply_route_learning)


func register_wire(wire: NetworkWire) -> void:
	if not wires.has(wire):
		wires.append(wire)

func unregister_wire(wire: NetworkWire) -> void:
	wires.erase(wire)


# Appelée dès qu'un paquet avec TTL > 0 est instancié
func register_ephemeral_packet(packet: NetworkPacket) -> void:
	if packet.ttl > 0.0 and not ephemeral_packets.has(packet):
		ephemeral_packets.append(packet)



# --- Contrôle de l'exécution ---

func start() -> void:
	is_running = true

func stop() -> void:
	is_running = false

func toggle() -> void:
	is_running = not is_running



# --- Boucle principale ---

func _physics_process(delta: float) -> void:
	if not is_running:
		return
	
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


# Parcourt la liste globale des paquets éphémères et marque ceux qui expirent
func _update_ephemeral_packets(delta: float) -> void:
	for i in range(ephemeral_packets.size() - 1, -1, -1):
		var packet: NetworkPacket = ephemeral_packets[i]
		
		# Si le paquet a expiré lors de ce pas de temps
		if packet.update_ttl(delta):
			ephemeral_packets.remove_at(i)


# --- Interface de communication inter-device

# Appelée par une machine terminale (Receiver) quand un paquet est validé
func apply_route_learning(routing_history: Dictionary, packet_color: int, target_number: int) -> void:
	for switch_id in routing_history.keys():
		var port_used: int = routing_history[switch_id]
		
		# On vérifie de manière sécurisée si la machine existe toujours dans le registre
		var device = _device_map.get(switch_id, null)
		
		# Si la machine est bien un switch, on lui demande de mettre à jour sa table
		if device != null and device is NetworkSwitch:
			device.learn_route(packet_color, target_number, port_used)
