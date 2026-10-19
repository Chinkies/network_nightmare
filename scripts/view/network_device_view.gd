class_name NetworkDeviceView
extends Node2D

## La référence vers l'objet logique qui tourne en mémoire
var logic_device: NetworkDevice

# On peut imaginer qu'actuellement ton carré de couleur est un Sprite2D enfant
@onready var visual_sprite: Sprite2D = $Sprite2D


# ====================
# ===== METHODES =====
# ====================

## Fonction d'initialisation appelée par le GridManager juste après le drop
func setup(p_logic_device: NetworkDevice, p_texture: Texture2D, cell_size: float) -> void:
	logic_device = p_logic_device
	
	# On applique la texture
	if p_texture and visual_sprite:
		visual_sprite.texture = p_texture
		
		# Mise à l'échelle automatique
		var tex_size := p_texture.get_size()
		if tex_size.x > 0 and tex_size.y > 0:
			# On calcule le ratio pour que la plus grande dimension rentre dans la case
			var scale_factor = cell_size / maxf(tex_size.x, tex_size.y)
			visual_sprite.scale = Vector2(scale_factor, scale_factor)
	
	# On écoute la machine logique pour réagir visuellement
	logic_device.packet_received.connect(_on_packet_received)
	logic_device.packet_processed.connect(_on_packet_processed)
	logic_device.packet_dropped.connect(_on_packet_dropped)


# --- Feedbacks Visuels ---

func _on_packet_received(_port: int, _packet: NetworkPacket) -> void:
	# Plus tard : faire clignoter le port d'entrée
	pass

func _on_packet_processed(_packet: NetworkPacket) -> void:
	# Plus tard : petite animation de succès
	pass

func _on_packet_dropped(_packet: NetworkPacket, reason: String) -> void:
	# Feedback immédiat pour le prototype : le carré devient rouge un instant
	if visual_sprite:
		visual_sprite.modulate = Color.RED
		var tween = create_tween()
		tween.tween_property(visual_sprite, "modulate", Color.WHITE, 0.5)
		
	print("[Vue] Paquet détruit sur ", logic_device.id, " Raison : ", reason)
