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
func update_preview(path_cells: Array[Vector2i], grid_view: GridView) -> void:
	if path_cells.size() < 2:
		visible = false
		return
		
	clear_points()
	
	for cell in path_cells:
		add_point(grid_view.cell_to_world_center(cell))
		
	visible = true
