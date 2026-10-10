class_name NetworkSimulation
extends Node

# =====================
# ===== ATTRIBUTS =====
# =====================

# --- Registres actifs de la simulation ---
var devices: Array[NetworkDevice] = []
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

func unregister_device(device: NetworkDevice) -> void:
	devices.erase(device)

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
