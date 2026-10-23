class_name NetworkDeviceView
extends Node2D


# =====================
# ===== SIGNAUX =======
# =====================

## Émis lorsqu'un joueur interagit avec l'un des ports visuels de cette machine.
## Relaye l'instance logique et l'identifiant du port vers le gestionnaire de modes.
signal port_interaction_requested(device: NetworkDevice, local_port_id: int)


# =====================
# ===== ATTRIBUTS =====
# =====================

# Textures des ports
const TEX_DYNAMIC = preload("res://views/ports/assets/dynamic_flow_shape.png")
const TEX_STATIC = preload("res://views/ports/assets/static_flow_shape.png")

## Référence sur la scène de la vue des indicateurs des ports
@export var port_view_scene: PackedScene

## Référence sur le sprite pour associer la texture du device
@onready var visual_sprite: Sprite2D = $Sprite2D
## Référence sur le container des ports pour instancier dynamiquement les ports
@onready var ports_container = $PortsContainer

## La référence vers l'objet logique qui tourne en mémoire
var logic_device: NetworkDevice


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
	
	# On instancie les ports
	var ports = logic_device.port_types
	for port_id in ports:
		var port_type = ports[port_id]
		
		if port_type != NetworkDevice.PortType.BLOCKED:
			var port_direction: Vector2 = logic_device.get_port_global_direction(port_id)
			var port_texture: Texture2D
			var port_angle: float = 0.0
			
			# On déduit la texture et l'angle
			match port_type:
				NetworkDevice.PortType.STATIC_OUTPUT:
					port_texture = TEX_STATIC
					port_angle = port_direction.angle()
				NetworkDevice.PortType.STATIC_INPUT:
					port_texture = TEX_STATIC
					# On inverse le vecteur pour que la flèche rentre dans la machine
					port_angle = (-port_direction).angle()
				NetworkDevice.PortType.DYNAMIC:
					port_texture = TEX_DYNAMIC
			
			# Instanciation et rattachement à la scène
			var port_instance = port_view_scene.instantiate() as NetworkPortView
			ports_container.add_child(port_instance)
			
			# On décale l'indicateur du centre
			port_instance.position = port_direction * (cell_size * 0.35)
			
			# Configuration du port
			port_instance.setup(port_id, port_texture, port_angle)
			
			# On connecte le clic
			port_instance.port_clicked.connect(_on_port_clicked)
			
			# On masque le port de base
			port_instance.set_interaction_active(false)


# ------------------------------------------
# --- Gestion de la visibilité des ports ---
# ------------------------------------------

## Active ou désactive l'interaction et l'affichage de tous les ports de cette machine
func set_ports_active(active: bool) -> void:
	for child in ports_container.get_children(): 
		if child is NetworkPortView:
			child.set_interaction_active(active)


# ----------------------------------------
# --- Feedbacks de gestion des paquets ---
# ----------------------------------------

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


# ------------------------------------------
# --- Feedbacks des interfaces des ports ---
# ------------------------------------------

## Capte le clic d'un NetworkPortView enfant et fait remonter l'événement 
## jusqu'au ModeManager via le signal port_interaction_requested.
func _on_port_clicked(local_port_id: int) -> void:
	port_interaction_requested.emit(logic_device, local_port_id)
