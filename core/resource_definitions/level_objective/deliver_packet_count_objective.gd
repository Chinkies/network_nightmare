class_name DeliverPacketCountObjective
extends LevelObjective

@export var required_count: int = 1
@export var specific_packet_id: int = -1 # Optionnel, -1 si n'importe quel paquet
@export var receiver_id: String = ""    # Optionnel, vide si n'importe quel receiver

func check_fulfillment(stats: Dictionary) -> bool:
	var delivered = stats.get("delivered_count", 0)
	return delivered >= required_count