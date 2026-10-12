class_name NetworkSwitch
extends NetworkDevice

# Table de commutation : destination_id (ou IP/MAC) -> index de port de sortie
var mac_table: Dictionary[String, int] = {}

# Configuration des 4 directions physiques locales des ports
# 0: Haut, 1: Droite, 2: Bas, 3: Gauche
const PORT_DIRECTIONS: Dictionary[int, Vector2i] = {
	0: Vector2i.UP,
	1: Vector2i.RIGHT,
	2: Vector2i.DOWN,
	3: Vector2i.LEFT
}


func _init(p_id: String, p_capacity: int = 6, p_rate: float = 3.0) -> void:
	super._init(p_id, p_capacity, p_rate)
	device_type = Type.GENERIC


# --- Gestion dynamique des connexions ---

## Tente de brancher un câble en entrée sur l'un des 4 ports physiques
func connect_input(port: int, wire: NetworkWire) -> bool:
	if wire == null or not PORT_DIRECTIONS.has(port):
		return false
	# Un port ne peut pas être à la fois entrée et sortie
	if output_wires.has(port) or input_wires.has(port):
		return false

	input_ports[port] = PORT_DIRECTIONS[port]
	input_wires[port] = wire
	return true


## Tente de brancher un câble en sortie sur l'un des 4 ports physiques
func connect_output(port: int, wire: NetworkWire) -> bool:
	if wire == null or not PORT_DIRECTIONS.has(port):
		return false
	# Un port ne peut pas être à la fois entrée et sortie
	if input_wires.has(port) or output_wires.has(port):
		return false

	output_ports[port] = PORT_DIRECTIONS[port]
	output_wires[port] = wire
	return true


func disconnect_input(port: int) -> void:
	super.disconnect_input(port)
	input_ports.erase(port)


func disconnect_output(port: int) -> void:
	super.disconnect_output(port)
	output_ports.erase(port)


# --- Logique de commutation ---

func receive_packet(port: int, packet: NetworkPacket) -> void:
	# Apprentissage dynamique (Auto-learning) :
	# On retient que l'émetteur du paquet est accessible via ce port
	if not packet.source_id.is_empty():
		mac_table[packet.source_id] = port

	super.receive_packet(port, packet)


func _process_next_packet() -> void:
	if output_wires.is_empty():
		return

	var packet: NetworkPacket = buffer.front()
	var target_port: int = -1

	# 1. Vérification dans la table de commutation
	if mac_table.has(packet.destination_id):
		var candidate_port: int = mac_table[packet.destination_id]
		# On s'assure qu'un câble de sortie y est bien branché
		if output_wires.has(candidate_port):
			target_port = candidate_port

	# 2. Si destination inconnue ou non raccordée : diffusion (Flooding) vers la première sortie disponible
	# (ou un tour de rôle / round-robin)
	if target_port == -1:
		for port_index in output_wires.keys():
			target_port = port_index
			break

	var wire: NetworkWire = output_wires.get(target_port, null)
	if wire == null:
		return

	# Injection sur le câble sélectionné
	if wire.push_packet(packet):
		buffer.pop_front()
		processing_cooldown = 1.0 / processing_rate
		packet_processed.emit(packet)
