class_name NetworkWireView
extends Line2D

# --- Signaux ---

signal interaction_started(logic_item: NetworkItem)
signal interaction_ended(logic_item: NetworkItem)


# =====================
# ===== ATTRIBUTS =====
# =====================

@export var wire_color: Color = Color("4b5563") # Un gris industriel par défaut
@export var wire_width: float = 4.0
@export var packet_view_scene: PackedScene # Scène du NetworkPacketView à assigner dans l'inspecteur

var logic_wire: NetworkWire = null
var click_area: Area2D
var is_pressed: bool = false

# Référence pour la conversion distance -> pixels
var cell_size: float = 64.0
# Dictionnaire associant chaque transit unique à sa vue graphique
var packet_views: Dictionary[NetworkWire.WireTransit, Node2D] = {}

# ====================
# ===== METHODES =====
# ====================

func _ready() -> void:
	width = wire_width
	default_color = wire_color
	modulate.a = 1.0
	set_process(true)
	
	# Création du conteneur physique
	click_area = Area2D.new()
	click_area.input_pickable = true
	add_child(click_area)
	click_area.input_event.connect(_on_input_event)
	click_area.mouse_exited.connect(_on_mouse_exited)

func _process(_delta: float) -> void:
	if logic_wire == null:
		return
		
	# Met à jour la position de chaque paquet en transit sur ce câble
	for transit in logic_wire.transit_queue:
		if packet_views.has(transit):
			var view = packet_views[transit]
			# Conversion de la distance logique (en cases) en position globale (en pixels)
			view.global_position = get_position_at_distance(transit.distance)

## Initialise et dessine le câble définitif à partir de son modèle logique
func setup_wire(wire: NetworkWire, grid_view: GridView) -> void:
	logic_wire = wire
	cell_size = float(grid_view.cell_size)
	clear_points()
	
	if not logic_wire.packet_entered.is_connected(_on_packet_entered):
		logic_wire.packet_entered.connect(_on_packet_entered)
	if not logic_wire.packet_exited.is_connected(_on_packet_exited):
		logic_wire.packet_exited.connect(_on_packet_exited)
	
	var path = logic_wire.key_points
	if path.size() < 2:
		return
		
	# 1. Tracé visuel
	for i in range(path.size()):
		var cell = path[i]
		
		# Point de départ sur le port source
		if i == 0:
			add_point(grid_view.get_port_global_position(logic_wire.from_device, logic_wire.from_port))
			continue
			
		# Point d'arrivée sur le port cible
		if i == path.size() - 1:
			add_point(grid_view.get_port_global_position(logic_wire.to_device, logic_wire.to_port))
			continue
			
		# Coudes ancrés au centre géométrique des cases
		add_point(grid_view.cell_to_world_center(cell))
	
	var total_pixels = 0.0
	for i in range(get_point_count() - 1):
		total_pixels += get_point_position(i).distance_to(get_point_position(i + 1))
	
	if logic_wire and cell_size > 0.0:
		logic_wire.total_length = total_pixels / cell_size

	# 2. Génération des Hitboxes (Câblage physique)
	_generate_collisions()


# --- Conversion Géométrique ---

## Convertit une distance logique (en cases) le long de la polyligne du câble en position Monde (Pixels)
func get_position_at_distance(distance_in_cells: float) -> Vector2:
	if get_point_count() < 2:
		return global_position
		
	var remaining_pixels = distance_in_cells * cell_size
	
	for i in range(get_point_count() - 1):
		var p1 = get_point_position(i)
		var p2 = get_point_position(i + 1)
		var segment_length = p1.distance_to(p2)
		
		if remaining_pixels <= segment_length:
			var ratio = remaining_pixels / segment_length if segment_length > 0 else 0.0
			# Les points de Line2D sont locaux, on les convertit en globaux pour les paquets
			return to_global(p1.lerp(p2, ratio))
			
		remaining_pixels -= segment_length
		
	return to_global(get_point_position(get_point_count() - 1))


# --- Gestion des vues de paquets ---

func _on_packet_entered(transit: NetworkWire.WireTransit) -> void:
	if not packet_view_scene:
		return
		
	var packet_view = packet_view_scene.instantiate() as Node2D
	if packet_view:
		add_child(packet_view)
		if packet_view.has_method("setup"):
			packet_view.setup(transit.packet)
		packet_views[transit] = packet_view


func _on_packet_exited(transit: NetworkWire.WireTransit) -> void:
	if packet_views.has(transit):
		var packet_view = packet_views[transit]
		packet_views.erase(transit)
		packet_view.queue_free()

## Génère la CollisionShape d'un câble en créant un RectangleShape2D pour chaque segment du câble
func _generate_collisions() -> void:
	if click_area == null:
		push_error("[NetworkWireView] Impossible de générer les collisions : click_area n'est pas initialisé.")
		return

	# Nettoyage d'anciennes collisions si on recycle la vue
	for child in click_area.get_children():
		child.queue_free()
		
	# On crée un rectangle de collision pour chaque segment du câble
	for i in range(get_point_count() - 1):
		var p1 = get_point_position(i)
		var p2 = get_point_position(i + 1)
		
		var segment_length = p1.distance_to(p2)
		var segment_angle = p1.angle_to_point(p2)
		var segment_center = (p1 + p2) / 2.0
		
		var col_shape = CollisionShape2D.new()
		var rect = RectangleShape2D.new()
		
		# La hitbox fait la longueur du segment, et l'épaisseur du trait + 10 pixels de marge de confort
		rect.size = Vector2(segment_length, width + 10.0)
		
		col_shape.shape = rect
		col_shape.position = segment_center
		col_shape.rotation = segment_angle
		
		click_area.add_child(col_shape)

## Supprime et nettoie toutes les vues de paquets en transit sur ce câble
func reset_state() -> void:
	for view in packet_views.values():
		if is_instance_valid(view):
			view.queue_free()
	packet_views.clear()
	

# ================================
# ===== GESTION DE LA SOURIS =====
# ================================

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			is_pressed = true
			interaction_started.emit(logic_wire)
		elif is_pressed: # Clic relâché
			is_pressed = false
			interaction_ended.emit(logic_wire)


func _on_mouse_exited() -> void:
	# Si la souris sort de la zone de collision, on annule l'action en cours
	if is_pressed:
		is_pressed = false
		interaction_ended.emit(logic_wire)
