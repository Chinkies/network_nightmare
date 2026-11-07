class_name NetworkPacketView
extends Sprite2D

@export_category("Textures par Forme (Shape)")
@export var texture_circle: Texture2D
@export var texture_square: Texture2D
@export var texture_triangle: Texture2D

func setup(packet: NetworkPacket) -> void:
	match packet.color:
		NetworkPacket.PacketColor.BLUE:
			modulate = Color.BLUE
		NetworkPacket.PacketColor.RED:
			modulate = Color.RED
		NetworkPacket.PacketColor.GREEN:
			modulate = Color.GREEN
		NetworkPacket.PacketColor.YELLOW:
			modulate = Color.YELLOW
		_:
			modulate = Color.WHITE

	match packet.shape:
		NetworkPacket.PacketShape.CIRCLE:
			if texture_circle: texture = texture_circle
		NetworkPacket.PacketShape.SQUARE:
			if texture_square: texture = texture_square
		NetworkPacket.PacketShape.TRIANGLE:
			if texture_triangle: texture = texture_triangle