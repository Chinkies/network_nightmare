class_name NetworkDeviceView
extends Node2D


# =====================
# ===== SIGNAUX =======
# =====================

## Émis lorsqu'un joueur interagit avec l'un des ports visuels de cette machine.
## Relaye l'instance logique et l'identifiant du port vers le gestionnaire de modes.
signal port_interaction_requested(device: NetworkDevice, local_port_id: int)

# Signaux relatifs aux clics sur le device
signal interaction_started(logic_item: NetworkItem)
signal interaction_ended(logic_item: NetworkItem)
signal configuration_requested(device: NetworkDevice)


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
## Référence sur l'Area2D
@onready var click_area: Area2D = $ClickArea

## La référence vers l'objet logique qui tourne en mémoire
var logic_device: NetworkDevice

# --- Attributs visuels ---
var is_pressed: bool = false


# ====================
# ===== METHODES =====
# ====================

# --- Setup et Draw ---

## Fonction d'initialisation appelée par le GridManager juste après le drop
func setup(p_logic_device: NetworkDevice, p_texture: Texture2D, cell_size: float) -> void:
	logic_device = p_logic_device
	_resize_click_area(cell_size)
	
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
				NetworkDevice.PortType.STATIC_OUTPUT, NetworkDevice.PortType.DYNAMIC:
					port_texture = TEX_STATIC if port_type == NetworkDevice.PortType.STATIC_OUTPUT else TEX_DYNAMIC
					# Les deux pointent vers l'extérieur
					port_angle = port_direction.angle() 
					
				NetworkDevice.PortType.STATIC_INPUT:
					port_texture = TEX_STATIC
					# On inverse le vecteur pour que la flèche rentre
					port_angle = (-port_direction).angle()
			
			# Instanciation et rattachement à la scène
			var port_instance = port_view_scene.instantiate() as NetworkPortView
			ports_container.add_child(port_instance)
			
			# On décale l'indicateur du centre
			port_instance.position = port_direction * (cell_size * 0.35)
			
			# Configuration du port
			port_instance.setup(port_id, port_texture, port_angle, port_direction)
			
			# On connecte le clic
			port_instance.port_clicked.connect(_on_port_clicked)
			
			# On masque le port de base
			port_instance.set_visibility(false)
			
	# On lie l'Area2D à nos signaux
	click_area.input_event.connect(_on_input_event)
	click_area.mouse_exited.connect(_on_mouse_exited)


## Redimensionne la CollisionShape2D par rapport à la taille d'une cellule
func _resize_click_area(cell_size: float) -> void:
	var collision_shape := click_area.get_node("CollisionShape2D") as CollisionShape2D
	if collision_shape == null:
		push_error("[NetworkDeviceView] CollisionShape2D manquante.")
		return

	var rectangle := collision_shape.shape as RectangleShape2D
	if rectangle == null:
		rectangle = RectangleShape2D.new()
		collision_shape.shape = rectangle

	rectangle.size = Vector2(cell_size, cell_size)
	collision_shape.scale = Vector2.ONE



# ------------------------------
# --- Gestion de la rotation ---
# ------------------------------

## Anime la rotation visuelle de la machine et met à jour instantanément les ports
func update_rotation(direction: int, cell_size: float) -> void:
	# 1. Calcul de l'angle relatif (ajoute +/- 90° à la rotation actuelle du sprite)
	var target_angle = visual_sprite.rotation + (direction * PI / 2.0)
	
	# Rotation fluide uniquement sur la texture de la machine
	var tween = create_tween()
	tween.tween_property(visual_sprite, "rotation", target_angle, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	# 2. Mise à jour instantanée des ports (puisqu'ils sont invisibles)
	for child in ports_container.get_children():
		if child is NetworkPortView:
			var port_id = child.port_id
			var port_direction: Vector2 = logic_device.get_port_global_direction(port_id)
			var port_angle: float = 0.0
			
			match logic_device.port_types[port_id]:
				NetworkDevice.PortType.STATIC_OUTPUT, NetworkDevice.PortType.DYNAMIC:
					port_angle = port_direction.angle()
				NetworkDevice.PortType.STATIC_INPUT:
					port_angle = (-port_direction).angle()
					
			# On déplace le port à sa nouvelle position spatiale instantanément
			child.position = port_direction * (cell_size * 0.35)
			
			# On met à jour les données internes du port (l'icône tournera toute seule)
			child.update_internal_rotation(port_angle, port_direction)



# ------------------------------------------
# --- Gestion de la visibilité des ports ---
# ------------------------------------------

## Active ou désactive l'interaction et l'affichage de tous les ports de cette machine
func display_ports(active: bool) -> void:
	for child in ports_container.get_children(): 
		if child is NetworkPortView:
			child.set_visibility(active)


## Restaure l'état AVAILABLE sur tous les ports qui ne sont pas verrouillés
func reset_ports_comptibility_view() -> void:
	for child in ports_container.get_children():
		if child is NetworkPortView:
			if child.is_in_compatibility_state():
				child.set_visual_state(NetworkPortView.PortState.AVAILABLE)


## Compare chaque port de cette machine avec le port source pour définir son état visuel
func set_ports_comptibility_view(source_device: NetworkDevice, source_port_id: int):
	for child in ports_container.get_children():
		if child is NetworkPortView:
			var port_id = child.port_id
			
			# Si le port est déjà occupé par un câble, on n'y touche pas
			if not logic_device.is_port_available(port_id):
				continue
			
			# Si c'est le port que l'on vient de cliquer
			elif logic_device == source_device and port_id == source_port_id:
				child.set_visual_state(NetworkPortView.PortState.SELECTED)
			
			# On met à jour l'état en fonction de la compatibilité
			elif logic_device.are_ports_compatible(port_id, source_device, source_port_id):
				child.set_visual_state(NetworkPortView.PortState.COMPATIBLE)
			
			else:
				child.set_visual_state(NetworkPortView.PortState.INCOMPATIBLE)


## Modifie directement l'état d'un port précis (utilisé pour valider une connexion)
func set_port_visual_state(port_id: int, state: NetworkPortView.PortState) -> void:
	for child in ports_container.get_children():
		if child is NetworkPortView and child.port_id == port_id:
			child.set_visual_state(state)
			break


# ----------------------------------------
# --- Feedbacks de gestion des paquets ---
# ----------------------------------------

func _on_packet_received(_port: int, _packet: NetworkPacket) -> void:
	# TODO: feedback ? 
	pass

func _on_packet_processed(_source: NetworkDevice, _packet: NetworkPacket) -> void:
	if logic_device.device_type == NetworkDevice.Type.RECEIVER:
		visual_sprite.modulate = Color.GREEN
		var tween = create_tween()
		tween.tween_property(visual_sprite, "modulate", Color.WHITE, 0.5)
	print("[", logic_device.id, "] Paquet ", _packet.shape, " ", _packet.color, " ", _packet.target_number, " bien reçu !")

func _on_packet_dropped(
	_source: NetworkDevice,
	_packet: NetworkPacket,
	reason: String
) -> void:
	# Feedback immédiat pour le prototype : le carré devient rouge un instant
	if visual_sprite:
		visual_sprite.modulate = Color.RED
		var tween = create_tween()
		tween.tween_property(visual_sprite, "modulate", Color.WHITE, 0.5)
		
	print("[", logic_device.id, "] Paquet détruit. Raison : ", reason)


# ------------------------------------------
# --- Feedbacks des interfaces des ports ---
# ------------------------------------------

## Capte le clic d'un NetworkPortView enfant et fait remonter l'événement 
## jusqu'au ModeManager via le signal port_interaction_requested.
func _on_port_clicked(local_port_id: int) -> void:
	port_interaction_requested.emit(logic_device, local_port_id)


# ---------------------------------
# --- Feedbacks de la ClickArea ---
# ---------------------------------

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton:
		
		# --- CLIC GAUCHE (Sélection / Drag) ---
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				is_pressed = true
				interaction_started.emit(logic_device)
			elif is_pressed: # Clic relâché
				is_pressed = false
				interaction_ended.emit(logic_device)
		
		# --- CLIC DROIT (Configuration) ---
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			get_viewport().set_input_as_handled()
			configuration_requested.emit(logic_device)


func _on_mouse_exited() -> void:
	# Si la souris sort de la zone de collision, on annule l'action en cours
	if is_pressed:
		is_pressed = false
		interaction_ended.emit(logic_device)
