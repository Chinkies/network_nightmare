class_name NetworkWireView
extends Line2D

# =====================
# ===== ATTRIBUTS =====
# =====================

@export var wire_color: Color = Color("4b5563") # Un gris industriel par défaut
@export var wire_width: float = 4.0

var logic_wire: NetworkWire = null


# ====================
# ===== METHODES =====
# ====================

func _ready() -> void:
	width = wire_width
	default_color = wire_color
	# Contrairement à GhostWireView, on veut une opacité totale (1.0)
	modulate.a = 1.0


## Initialise et dessine le câble définitif à partir de son modèle logique
func setup_wire(wire: NetworkWire, grid_view: GridView) -> void:
	logic_wire = wire
	clear_points()
	
	var path = logic_wire.key_points
	if path.size() < 2:
		return
		
	# On reproduit la logique d'ancrage de GhostWireView, mais statiquement
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
