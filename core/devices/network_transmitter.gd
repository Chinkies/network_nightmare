class_name NetworkTransmitter
extends NetworkDevice

#Liste des paquets à émettre et timer
var emission_schedule: Array[ScheduleEvent] = []
var schedule_index: int = 0
var emission_timer: float = 0.0

# ====================
# ===== METHODES =====
# ====================

func _init(p_id: String, p_schedule: Array[ScheduleEvent], p_capacity: int = 5, p_rate:float = 2.0) -> void:
	super(p_id, p_capacity, p_rate)
	device_type = Type.TRANSMITTER
	emission_schedule = p_schedule

	port_types = {
		2: PortType.STATIC_OUTPUT
	}

## Surcharge de simulate pour gérer le calendrier d'émission de paquets
func simulate(delta: float) -> void:
	if is_broken:
		return
		
	# 1. Gestion du calendrier d'émission : on alimente le buffer interne du transmitter
	if schedule_index < emission_schedule.size():
		emission_timer += delta
		var current_event = emission_schedule[schedule_index]

		if current_event == null or current_event.packet == null:
			push_error("[NetworkTransmitter] Event n°%s sans paquets !", schedule_index)
			schedule_index += 1
			emission_timer = 0.0
		elif emission_timer >= current_event.delay:
			# Si le buffer a de la place, on instancie et on pousse le paquet dedans
			if buffer.size() < buffer_capacity:
				var packet_data = current_event.packet
				var new_packet = NetworkPacket.new(
					packet_data.id,
					packet_data.target_number,
					packet_data.color,
					packet_data.shape,
					packet_data.ttl
				)
				
				buffer.push_back(new_packet)
				print("[Transmitter] Paquet injecté dans le buffer (Couleur: %s, Numéro: %d)" % [packet_data.color, packet_data.id])
				
				schedule_index += 1
				emission_timer = 0.0

	# 2. Exécution de la logique de la classe mère : 
	# Elle gérera d'elle-même le cooldown, l'expiration TTL et appellera _process_next_packet()
	super(delta)

func _process_next_packet() -> void:
	if output_wires.is_empty():
		return
		
	# On cherche un câble de sortie valide parmi tous les ports connectés
	var wire: NetworkWire = null
	for port in output_wires.keys():
		if output_wires[port] != null:
			wire = output_wires[port]
			break
			
	if wire == null:
		return
		
	# Tentative d'injection sur le câble
	var packet: NetworkPacket = buffer.front()
	if packet != null and wire.push_packet(packet):
		buffer.pop_front()
		processing_cooldown = 1.0 / processing_rate
		print("[Transmitter] Paquet emit")
		packet_processed.emit(packet)
