class_name GhostWireView
extends Line2D


# =====================
# ===== ATTRIBUTS =====
# =====================

@export var preview_color: Color = Color("00f0ffd2") # Cyan holographique
@export var preview_width: float = 4.0
@export var preview_opacity: float = 0.6


# ====================
# ===== METHODES =====
# ====================

func _ready() -> void:
	width = preview_width
	default_color = preview_color
	modulate.a = preview_opacity
	visible = false


## Met à jour le tracé visuel à partir des coordonnées mathématiques de la grille
func update_preview(
	path_cells: Array[Vector2i], 
	grid_board: GridBoard, 
	grid_view: GridView,
	source_device: NetworkDevice, 
	source_port_id: int, 
	target_device: NetworkDevice = null, 
	target_port_id: int = -1
) -> void:
	
	if path_cells.size() < 2:
		visible = false
		return

	if target_device == null and path_cells.size() == 2 and path_cells[0] == path_cells[1]:
		clear_points()
		visible = false
		return
		
	clear_points()
	
	for i in range(path_cells.size()):
		var cell = path_cells[i]
		
		# Point de départ : centre du port source
		if i == 0 and source_device != null:
			add_point(grid_board.get_port_global_position(source_device, source_port_id))
			continue
			
		# Point d'arrivée : centre du port cible s'il y en a un
		if i == path_cells.size() - 1 and target_device != null:
			add_point(grid_board.get_port_global_position(target_device, target_port_id))
			continue
			
		# Coudes et trajet normal : on s'ancre au centre géométrique des cases
		add_point(grid_view.cell_to_world_center(cell))
		
	visible = true
