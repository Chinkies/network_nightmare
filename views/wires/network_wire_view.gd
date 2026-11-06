class_name NetworkWireView
extends Line2D

# --- Signaux ---

signal interaction_started(logic_item: Variant)
signal interaction_ended(logic_item: Variant)


# =====================
# ===== ATTRIBUTS =====
# =====================

@export var wire_color: Color = Color("4b5563") # Un gris industriel par défaut
@export var wire_width: float = 4.0

var logic_wire: NetworkWire = null
var click_area: Area2D
var is_pressed: bool = false


# ====================
# ===== METHODES =====
# ====================

func _ready() -> void:
	width = wire_width
	default_color = wire_color
	modulate.a = 1.0
	
	# Création du conteneur physique
	click_area = Area2D.new()
	click_area.input_pickable = true
	add_child(click_area)
	click_area.input_event.connect(_on_input_event)
	click_area.mouse_exited.connect(_on_mouse_exited)


## Initialise et dessine le câble définitif à partir de son modèle logique
func setup_wire(wire: NetworkWire, grid_view: GridView) -> void:
	logic_wire = wire
	clear_points()
	
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
	
	# 2. Génération des Hitboxes (Câblage physique)
	_generate_collisions()


## Génère la CollisionShape d'un câble en créant un RectangleShape2D pour chaque segment du câble
func _generate_collisions() -> void:
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
