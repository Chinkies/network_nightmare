class_name NetworkPacketView
extends Node2D

# =====================
# ===== ATTRIBUTS =====
# =====================

@export_category("Textures par Forme (Shape)")
@export var texture_circle: Texture2D
@export var texture_square: Texture2D
@export var texture_triangle: Texture2D

@export_category("Configuration Visuelle")
@export var packet_scale: Vector2 = Vector2(0.5, 0.5) # Réduit la taille du sprite à 50%

# Référence vers le Label enfant pour afficher le target number
@onready var label: Label = $Label
@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	scale = packet_scale

func setup(packet: NetworkPacket) -> void:
	match packet.color:
		NetworkPacket.PacketColor.BLUE:
			sprite.modulate = Color.BLUE
		NetworkPacket.PacketColor.RED:
			sprite.modulate = Color.RED
		NetworkPacket.PacketColor.GREEN:
			sprite.modulate = Color.GREEN
		NetworkPacket.PacketColor.YELLOW:
			sprite.modulate = Color.YELLOW
		_:
			sprite.modulate = Color.WHITE

	match packet.shape:
		NetworkPacket.PacketShape.CIRCLE:
			if texture_circle: sprite.texture = texture_circle
		NetworkPacket.PacketShape.SQUARE:
			if texture_square: sprite.texture = texture_square
		NetworkPacket.PacketShape.TRIANGLE:
			if texture_triangle: sprite.texture = texture_triangle

	if label:
		label.text = str(packet.target_number)
