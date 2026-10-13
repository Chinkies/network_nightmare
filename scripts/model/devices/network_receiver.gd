class_name NetworkReceiver
extends NetworkDevice


# Signal spécifique au receiver pour remonter l'information au manager
signal route_learned(routing_history: Dictionary, packet_color: int, target_number: int)


# --- Attibuts spécifiques au Receiver ---

# Configuration attendue par cette machine
var expected_color: NetworkPacket.PacketColor
var expected_number: int


# ====================
# ===== METHODES =====
# ====================

func _init(p_id: String, p_color: NetworkPacket.PacketColor, p_number: int, p_capacity: int = 5, p_rate: float = 2.0) -> void:
	super(p_id, p_capacity, p_rate)
	device_type = Type.RECEIVER
	expected_color = p_color
	expected_number = p_number


## Surcharge : Un Receiver ne transfère pas, il consomme et valide
func _process_next_packet() -> void:
	# On retire le paquet du buffer
	var packet: NetworkPacket = buffer.pop_front()
	
	# 1. Validation de la destination
	if packet.color == expected_color and packet.target_number == expected_number:
		# Succès ! Le paquet a atteint la bonne cible.
		# On émet le signal pour que la simulation mette à jour les switchs
		if not packet.routing_history.is_empty():
			route_learned.emit(packet.routing_history, packet.color, packet.target_number)
			
		packet_processed.emit(packet)
	else:
		# Échec : le paquet (ou le clone d'un flooding) s'est perdu.
		packet_dropped.emit(packet, "Wrong destination")
	
	# 2. Mise à jour du délai matériel (le temps de traiter le paquet)
	processing_cooldown = 1.0 / processing_rate
