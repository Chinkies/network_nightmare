class_name NetworkSwitch
extends NetworkDevice

# Table d'adresses : clé = "Couleur_Numéro" (ex: "0_5" pour BLUE et machine 5), valeur = port de sortie
var mac_table: Dictionary = {}


# ====================
# ===== METHODES =====
# ====================

func _init(p_id: String, p_capacity: int = 10, p_rate: float = 2.0) -> void:
	super(p_id, p_capacity, p_rate)
	device_type = Type.SWITCH


# --- Surcharges des méthodes de Device ---

## Surcharge : Aiguillage conditionnel basé sur la table
func _process_next_packet() -> void:
	var packet: NetworkPacket = buffer.front()
	var routing_key: String = str(packet.color) + "_" + str(packet.target_number)
	
	if mac_table.has(routing_key):
		_handle_unicast(packet, mac_table[routing_key])
	else:
		_handle_broadcast(packet)



# --- Méthodes spécifiques au Switch ---

## Envoi direct si la route est connue
func _handle_unicast(packet: NetworkPacket, target_port: int) -> void:
	var wire: NetworkWire = output_wires.get(target_port, null)
	
	if wire == null:
		var dropped: NetworkPacket = buffer.pop_front()
		packet_dropped.emit(dropped, "No wire on target port")
		return
		
	if wire.push_packet(packet):
		buffer.pop_front()
		processing_cooldown = 1.0 / processing_rate
		packet_processed.emit(packet)


## Duplication et ajout de la trace si la route est inconnue
func _handle_broadcast(packet: NetworkPacket) -> void:
	var valid_ports: Array[int] = output_wires.keys()
	
	if valid_ports.is_empty():
		var dropped: NetworkPacket = buffer.pop_front()
		packet_dropped.emit(dropped, "No output routes for broadcast")
		return
		
	# Le switch attend que tous les ports soient libres pour lancer son broadcast synchronisé
	for port in valid_ports:
		var wire: NetworkWire = output_wires[port]
		if wire.injection_cooldown > 0.0 or (not wire.transit_queue.is_empty() and wire.transit_queue.back().distance < wire.min_packet_spacing):
			return

	buffer.pop_front()
	
	for port in valid_ports:
		var packet_copy: NetworkPacket = packet.clone()
		# Le switch inscrit simplement son ID (String) et le port de sortie
		packet_copy.routing_history[id] = port 
		output_wires[port].push_packet(packet_copy)
		
	processing_cooldown = 1.0 / processing_rate
	packet_processed.emit(packet)


## Méthode appelée par un Receiver terminal lorsqu'un paquet arrive à la bonne destination
func learn_route(packet_color: int, target_number: int, learned_port: int) -> void:
	var routing_key: String = str(packet_color) + "_" + str(target_number)
	
	if not mac_table.has(routing_key) or mac_table[routing_key] != learned_port:
		mac_table[routing_key] = learned_port
		# TODO: Émettre un signal pour l'UI afin d'afficher la nouvelle entrée dans la table visuelle
