class_name LevelObjective
extends Resource

enum Type {
	DELIVER_PACKET,
	DELIVER_PACKET_COUNT,
	NO_DROPPED_PACKETS,
	NO_EXPIRED_PACKETS,
	MAX_DEVICE_COUNT,
	MAX_DURATION
}

@export var objective_id: String = ""
@export var description: String = ""
@export var type: Type = Type.DELIVER_PACKET
@export var packet_id: int = -1
@export var receiver_id: String = ""
@export var required_count: int = 1
@export var maximum_device_count: int = -1
@export var maximum_duration: float = -1.0
