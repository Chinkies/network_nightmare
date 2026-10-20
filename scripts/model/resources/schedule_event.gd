class_name ScheduleEvent
extends Resource #sinon pas de putain d'export

@export var packet: NetworkPacketData
@export var delay: float

func _init(_packet: NetworkPacketData = null, _delay: float = 1.0) -> void:
	packet = _packet
	delay = _delay