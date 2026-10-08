class_name NetworkDevice
extends RefCounted

# Signaux pour la logique du rendu et du son
signal packet_received(port: int, packet: NetworkPacket)
signal packet_processed(packet: NetworkPacket)
signal packet_dropped(packet: NetworkPacket, reason: String)
# TODO: signal device_overloaded(device: NetworkDevice)

# Types de machines pour JSON, UI et Factory
enum Type {
	GENERIC,
	EMITTER,
	RECEIVER
}


# =====================
# ===== ATTRIBUTS =====
# =====================

# --- Identification & Placement ---
var id: String
var device_type: Type = Type.GENERIC
var grid_position: Vector2i = Vector2i.ZERO
var rotation_quadrants: int = 0 	# 0: 0°, 1: 90°, 2: 180°, 3: 270°

# --- Configuration locale des ports (index de port -> direction locale) ---
var input_ports: Dictionary = {}		# Ex: { 0: Vector2i.LEFT }
var output_ports: Dictionary = {}

# --- Connexions réelles (index de port -> NetworkWire) ---
var input_wires: Dictionary = {}
var output_wires: Dictionary = {}

# --- Buffer & Métriques matérielles ---
var buffer: Array[NetworkPacket] = []
var buffer_capacity: int = 5
var is_broken: bool = false

# --- Cadence de traitement ---
var processing_rate: float = 2.0 # Paquets traités par seconde
var processing_cooldown: float = 0.0



# ====================
# ===== METHODES =====
# ====================

func _init(p_id: String, p_capacity: int = 5, p_rate: float = 2.0) -> void:
	id = p_id
	buffer_capacity = p_capacity
	processing_rate = p_rate


# --- Branchement des câbles aux ports

# Tente de connecter un câble à un port de sortie donné
func connect_output(port: int, wire: NetworkWire) -> bool:
	if wire == null or not output_ports.has(port) or output_wires.get(port) != null:
		return false
	
	output_wires[port] = wire
	return true

# Tente de connecter un câble à un port d'entrée donné
func connect_input(port: int, wire: NetworkWire) -> bool:
	if wire == null or input_ports.get(port) == null or input_wires.get(port) != null:
		return false
	
	input_wires[port] = wire
	return true


# Déconnecte le câble branché sur un port de sortie donné
func disconnect_output(port: int) -> void:
	output_wires.erase(port)

# Déconnecte le câble branché sur un port d'entrée donné
func disconnect_input(port: int) -> void:
	input_wires.erase(port)


# --- Utilitaires géométriques ---

# Convertit une direction locale (-1, 0, etc.) en direction sur la grille selon la rotation
func get_port_global_direction(local_dir: Vector2i) -> Vector2i:
	var dir: Vector2i = local_dir
	for _i in range(rotation_quadrants % 4):
		dir = Vector2i(-dir.y, dir.x)
	return dir

# Renvoie la case voisine ciblée par un port de sortie donné
func get_output_target_cell(port: int) -> Vector2i:
	if not output_ports.has(port):
		return grid_position
	return grid_position + get_port_global_direction(output_ports[port])


# --- Traitement des paquets ---

# Vérifie si le port d'entrée existe et si le buffer interne a de la place + machine not broken
func can_receive_packet(port: int) -> bool:
	return not is_broken and input_ports.has(port) and buffer.size() < buffer_capacity


# Réceptionne un paquet sur un port donné
func receive_packet(port: int, packet: NetworkPacket) -> void:
	# 1. Vérification de sécurité matérielle
	if not can_receive_packet(port):
		var reason: String = "Unknown error"
		if is_broken:
			reason = "Device broken"
		elif not input_ports.has(port):
			reason = "Invalid input port"
		elif buffer.size() >= buffer_capacity:
			reason = "Buffer full"
			
		packet_dropped.emit(packet, reason)
		return

	# 2. Admission dans le buffer
	buffer.push_back(packet)
	packet_received.emit(port, packet)


# Fait avancer le cycle interne de la machine
func simulate(delta: float) -> void:
	# Vérifie si la machine est fonctionnelle
	if is_broken:
		return
	# Update le cooldown
	if processing_cooldown > 0.0:
		processing_cooldown = maxf(0.0, processing_cooldown - delta)
	# Vérifie s'il y a des paquets à traiter
	if processing_cooldown <= 0.0 and not buffer.is_empty():
		_process_next_packet()
	# TODO: ajouter un passage à l'état broken sous conditions


# Méthode virtuelle : surchargée par chaque type d'appareil
# Implémentation par défaut : tente d'évacuer le premier paquet sur le port 0
func _process_next_packet() -> void:
	# On cherche le câble branché sur le port de sortie 0
	if output_wires.is_empty():
		return
	var wire: NetworkWire = output_wires.get(0, null)
	if wire == null:
		return
	
	# Tentative d'injection sur le câble
	var packet: NetworkPacket = buffer.front()
	if wire.push_packet(packet):
		buffer.pop_front()
		processing_cooldown = 1.0 / processing_rate
		packet_processed.emit(packet)
