class_name NetworkDevice
extends RefCounted

# Signaux pour la logique du rendu et du son
signal packet_received(port: int, packet: NetworkPacket)
signal packet_processed(packet: NetworkPacket)
signal packet_dropped(packet: NetworkPacket, reason: String)
# TODO: signal device_overloaded(device: NetworkDevice)

## Types de machines pour JSON, UI et Factory
enum Type {
	GENERIC,
	EMITTER,
	RECEIVER,
	SWITCH
}

## Types possibles pour chaque face de la machine
enum PortType {
	BLOCKED,			# Face murée, aucune connexion
	STATIC_INPUT,		# N'accepte que des câbles entrants
	STATIC_OUTPUT,		# N'accepte que des câbles sortants
	DYNAMIC				# Accepte entrantou sortant suivant certaines règles propres à chaque machine
}


# =====================
# ===== ATTRIBUTS =====
# =====================

# --- Identification & Placement ---
var id: String
var device_type: Type = Type.GENERIC
var grid_position: Vector2i = Vector2i.ZERO
var rotation_quadrants: int = 0 	# 0: 0°, 1: 90°, 2: 180°, 3: 270°

# --- Configuration locale des faces (0: Haut, 1: Droite, 2: Bas, 3: Gauche) ---
# Par défaut, une machine générique est totalement bloquée. Les classes enfants surchargeront ceci.
var port_types: Dictionary = {
	0: PortType.BLOCKED,
	1: PortType.BLOCKED,
	2: PortType.BLOCKED,
	3: PortType.BLOCKED
}
var max_input_ports: int = 0
var max_output_ports: int = 0

# --- Connexions réelles (index de port -> NetworkWire) ---
var input_wires: Dictionary[int, NetworkWire] = {}
var output_wires: Dictionary[int, NetworkWire] = {}

# --- Buffer & Métriques matérielles ---
var buffer: Array[NetworkPacket] = []
var buffer_capacity: int = 5
var is_broken: bool = false

# --- Cadence de traitement ---
var processing_rate: float = 2.0 # Paquets traités par seconde
var processing_cooldown: float = 0.0

# TODO:
# --- Texture du device ---
var icon: Texture2D

# ====================
# ===== METHODES =====
# ====================

func _init(p_id: String, p_capacity: int = 5, p_rate: float = 2.0) -> void:
	id = p_id
	buffer_capacity = p_capacity
	processing_rate = p_rate


# --- Gestion des Connexions ---

## Vérifie si on peut brancher un câble ENTRANT sur cette face locale
func can_connect_input(local_port: int) -> bool:
	if not port_types.has(local_port): return false
	var type: int = port_types[local_port]
	
	if type == PortType.BLOCKED or type == PortType.STATIC_OUTPUT:
		return false
	if input_wires.has(local_port):
		return false # Déjà un câble entrant ici
		
	# Règle universelle anti-collision (Full-duplex interdit sur une même face)
	if output_wires.has(local_port):
		return false 
		
	# Vérification stricte de la limite matérielle
	if input_wires.size() >= max_input_ports:
		return false
		
	return true

## Vérifie si on peut brancher un câble SORTANT sur cette face locale
func can_connect_output(local_port: int) -> bool:
	if not port_types.has(local_port): return false
	var type: int = port_types[local_port]
	
	if type == PortType.BLOCKED or type == PortType.STATIC_INPUT:
		return false
	if output_wires.has(local_port):
		return false # Déjà un câble sortant ici
		
	# Règle universelle anti-collision (Full-duplex interdit sur une même face)
	if input_wires.has(local_port):
		return false 
		
	# Vérification stricte de la limite matérielle
	if output_wires.size() >= max_output_ports:
		return false
		
	return true


## Tente de connecter un câble à un port donné
func connect_input(local_port: int, wire: NetworkWire) -> bool:
	if can_connect_input(local_port):
		input_wires[local_port] = wire
		return true
	return false

## Tente de connecter un câble à un port donné
func connect_output(local_port: int, wire: NetworkWire) -> bool:
	if can_connect_output(local_port):
		output_wires[local_port] = wire
		return true
	return false


## Déconnecte le câble branché sur un port d'entrée donné
func disconnect_input(port: int) -> void:
	input_wires.erase(port)

## Déconnecte le câble branché sur un port de sortie donné
func disconnect_output(port: int) -> void:
	output_wires.erase(port)



# --- Utilitaires géométriques ---

const LOCAL_DIRECTIONS = {
	0: Vector2i(0, -1), # Haut
	1: Vector2i(1, 0),  # Droite
	2: Vector2i(0, 1),  # Bas
	3: Vector2i(-1, 0)  # Gauche
}

## Convertit une face locale en direction sur la grille globale selon la rotation
func get_port_global_direction(local_port: int) -> Vector2i:
	var dir: Vector2i = LOCAL_DIRECTIONS.get(local_port, Vector2i.ZERO)
	var steps: int = posmod(rotation_quadrants, 4)
	for _i in range(steps):
		dir = Vector2i(-dir.y, dir.x)
	return dir

## Renvoie la coordonnée de la case ciblée par le port de sortie
func get_output_target_cell(local_port: int) -> Vector2i:
	if not output_wires.has(local_port):
		return grid_position
	return grid_position + get_port_global_direction(local_port)



# --- Traitement des paquets ---

## Vérifie si le port d'entrée existe et si le buffer interne a de la place + machine not broken
func can_receive_packet(port: int) -> bool:
	return not is_broken and input_wires.has(port) and buffer.size() < buffer_capacity


## Réceptionne un paquet sur un port donné
func receive_packet(port: int, packet: NetworkPacket) -> void:
	# 1. Vérification de sécurité matérielle
	if not can_receive_packet(port):
		var reason: String = "Unknown error"
		if is_broken:
			reason = "Device broken"
		elif not input_wires.has(port):
			reason = "Invalid or unconnected input port"
		elif buffer.size() >= buffer_capacity:
			reason = "Buffer full"
			
		packet_dropped.emit(packet, reason)
		return

	# 2. Admission dans le buffer
	buffer.push_back(packet)
	packet_received.emit(port, packet)


## Fait avancer le cycle interne de la machine
func simulate(delta: float) -> void:
	# Vérifie si la machine est fonctionnelle
	if is_broken:
		return
	
	# 1. Update le cooldown
	if processing_cooldown > 0.0:
		processing_cooldown = maxf(0.0, processing_cooldown - delta)
	
	# 2. Purge des paquets expirés dans le buffer interne
	for i in range(buffer.size() - 1, -1, -1):
		var packet: NetworkPacket = buffer[i]
		if packet.is_expired:
			buffer.remove_at(i)
			packet_dropped.emit(packet, "TTL expired")
	
	# 3. Vérifie si on peut traiter le paquet suivant
	if processing_cooldown <= 0.0 and not buffer.is_empty():
		_process_next_packet()
	# TODO: ajouter un passage à l'état broken sous conditions


# Méthode virtuelle : surchargée par chaque type d'appareil
## Implémentation par défaut : tente d'évacuer le premier paquet sur le port 0
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
