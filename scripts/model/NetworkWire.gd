class_name NetworkWire
extends RefCounted

# Signaux pour la logique du rendu et du son
signal packet_dropped(packet: NetworkPacket, reason: String)

# =====================
# ===== STRUCTURE =====
# =====================

# Structure interne représentant un paquet en transit sur ce câble
class WireTransit:
	var packet: NetworkPacket
	var distance: float = 0.0		# Distance parcourue sur le câble
	
	func _init(p_packet: NetworkPacket) -> void:
		packet = p_packet


# ======================
# ===== ATTRIBUTS ======
# ======================

# --- Connexions ---
var from_device: NetworkDevice
var from_port: int
var to_device: NetworkDevice
var to_port: int

# --- Géométrie & Métriques ---
var points: Array[Vector2] = []
var total_length: float = 0.0
var speed: float = 100.0				# Pixels par seconde
var min_packet_spacing: float = 24.0	# Distance minimale en pixels entre 2 paquets
var max_rate: float = 1.0				# Paquets max par seconde

# --- File de transit ---
# Ordonnée : l'élément à l'index 0 est le plus proche de l'arrivée
var transit_queue: Array[WireTransit] = []
var injection_cooldown: float = 0.0 	# Chronomètre interne pour cadencer les entrées



# ====================
# ===== METHODES =====
# ====================

func _init(p_from_device: NetworkDevice, p_from_port: int, p_to_device: NetworkDevice, p_to_port: int, p_points: Array[Vector2]) -> void:
	from_device = p_from_device
	from_port = p_from_port
	to_device = p_to_device
	to_port = p_to_port
	points = p_points
	_calculate_total_length()


# Calcule la somme des longueurs des segments du tracé
func _calculate_total_length() -> void:
	total_length = 0.0
	
	if points.size() <= 1:
		return
	
	var length: float = 0.0
	for i in range(points.size()-1):
		length += points[i+1].distance_to(points[i])
	total_length = length


# Tente d'injecter un nouveau paquet sur le câble (appelé par le device émetteur)
# Renvoie true si le paquet a pu entrer, false si le câble est saturé / en cooldown
func push_packet(packet: NetworkPacket) -> bool:
	# On vérifie qu'il n'y a pas de cooldown
	if injection_cooldown > 0.0:
		return false
	# On vérifie que l'entrée n'est pas bouchée
	if not transit_queue.is_empty():
		if (transit_queue.back().distance < min_packet_spacing):
			return false
	# On peut faire entrer le paquet
	transit_queue.push_back(WireTransit.new(packet))
	injection_cooldown = 1.0/max_rate
	return true


# Fait avancer les paquets et gère la sortie
func simulate(delta: float) -> void:
	# On met à jour le cooldown du câble
	if injection_cooldown > 0.0:
		injection_cooldown = maxf(0.0, injection_cooldown - delta)
	
	if transit_queue.is_empty():
		return
	
	# Purge des paquets expirés en transit sur le câble
	for i in range(transit_queue.size() - 1, -1, -1):
		var transit: WireTransit = transit_queue[i]
		if transit.packet.is_expired:
			var dropped: NetworkPacket = transit.packet
			transit_queue.remove_at(i)
			packet_dropped.emit(dropped, "TTL expired")
	
	if transit_queue.is_empty():
		return
	
	# On déplace les paquets
	_update_packet_positions(delta)
	
	# Si un paquet est en sortie de câble, on tente de le délivrer
	if transit_queue.front().distance >= total_length:
		_deliver_arrived_packet()


# Résout l'avancement des paquets et gère l'accumulation (bouchons)
func _update_packet_positions(delta: float) -> void:
	var move_step: float = delta * speed
	
	# On déplace le 1er paquet
	var first: WireTransit = transit_queue.front()
	first.distance = minf(total_length, first.distance + move_step)
	
	# On déplace les paquets suivants
	for i in range(1, transit_queue.size()):
		var cur_pack: WireTransit = transit_queue[i]
		var front_pack: WireTransit = transit_queue[i-1]
		
		# Distance atteinte en avançant sans contreinte
		var raw_new_distance: float = cur_pack.distance + move_step
		# Distance max autorisée par le paquet devant
		var max_distance: float = front_pack.distance - min_packet_spacing
		
		# Distance maximale autorisée par rapport à la proximité du paquet de devant
		var legal_closeness_distance: float = minf(raw_new_distance, max_distance)
		
		# On fait avancer le paquet en l'empêchant de reculer
		cur_pack.distance = maxf(cur_pack.distance, legal_closeness_distance)


# Tente de faire entrer le paquet arrivé au bout dans le to_device
func _deliver_arrived_packet() -> void:
	# On vérifie si le device existe
	if to_device == null:
		return
	else:
		# On vérifie si le device peut acceuillir le paquet
		if to_device.can_receive_packet(to_port):
			var delivered_packet = transit_queue.pop_front().packet
			to_device.receive_packet(to_port, delivered_packet)
