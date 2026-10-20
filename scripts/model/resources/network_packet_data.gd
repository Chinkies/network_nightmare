class_name NetworkPacketData
extends Resource

@export_category("Paramètres du paquet")
@export var id: int = 1
@export var color: NetworkPacket.PacketColor = NetworkPacket.PacketColor.BLUE
@export var shape: NetworkPacket.PacketShape = NetworkPacket.PacketShape.CIRCLE
@export var target_number: int = 1
@export var ttl: float = -1.0
