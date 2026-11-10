class_name DroppedPacketCountObjective
extends LevelObjective

@export var max_dropped_packets: int = 0
@export var packet_color: NetworkPacket.PacketColor = NetworkPacket.PacketColor.BLUE
@export var has_color_filter: bool = false
@export var packet_number: int = 0
@export var has_number_filter: bool = false
@export var packet_shape: NetworkPacket.PacketShape = NetworkPacket.PacketShape.CIRCLE
@export var has_shape_filter: bool = false

func check_fulfillment(stats: Dictionary) -> bool:
	var dropped_packets: Array = stats.get("dropped_packets_details", [])
	var match_count = 0
	
	for packet in dropped_packets:
		if packet and _matches_criteria(packet):
			match_count += 1
			
	return match_count <= max_dropped_packets

func _matches_criteria(packet: NetworkPacket) -> bool:
	if has_number_filter and packet.target_number != packet_number:
		return false
	if has_shape_filter and packet.shape != packet_shape:
		return false
	if has_color_filter and packet.color != packet_color:
		return false
	return true