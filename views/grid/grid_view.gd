class_name GridView
extends Control

# =====================
# ===== SIGNAUX =======
# =====================
## Émis quand le joueur lâche un appareil sur une case valide
signal device_drop_requested(cell: Vector2i, device_data: Variant)


# =====================
# ===== ATTRIBUTS =====
# =====================

## Référence vers le modèle logique de la grille
@export var grid_board: GridBoard

@export var cell_size: int = 64
@export var line_color: Color = Color(0.25, 0.3, 0.4, 0.4)
@export var background_color: Color = Color(0.08, 0.1, 0.14, 1.0)
@export var border_color: Color = Color(0.35, 0.45, 0.6, 0.8)


# ====================
# ===== METHODES =====
# ====================

func _ready() -> void:
	# La vue s'adapte automatiquement à la taille dictée par le modèle
	if grid_board:
		custom_minimum_size = Vector2(grid_board.grid_width * cell_size, grid_board.grid_height * cell_size)
		size = custom_minimum_size


func _draw() -> void:
	if not grid_board:
		return
		
	var total_size := size
	
	draw_rect(Rect2(Vector2.ZERO, total_size), background_color, true)

	for x in range(grid_board.grid_width + 1):
		var from := Vector2(x * cell_size, 0)
		var to := Vector2(x * cell_size, total_size.y)
		draw_line(from, to, line_color, 1.0)

	for y in range(grid_board.grid_height + 1):
		var from := Vector2(0, y * cell_size)
		var to := Vector2(total_size.x, y * cell_size)
		draw_line(from, to, line_color, 1.0)

	draw_rect(Rect2(Vector2.ZERO, total_size), border_color, false, 2.0)


# --- Conversions Spatiales ---

func local_to_cell(local_pos: Vector2) -> Vector2i:
	return Vector2i(
		int(floor(local_pos.x / cell_size)),
		int(floor(local_pos.y / cell_size))
	)

func cell_to_world_center(cell: Vector2i) -> Vector2:
	# global_position remplace to_global() pour décaler la position locale
	var local_center = Vector2(
		(cell.x * cell_size) + (cell_size * 0.5),
		(cell.y * cell_size) + (cell_size * 0.5)
	)
	return global_position + local_center


# --- Gestion du Drag & Drop natif ---

func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	if not grid_board: return false
	if typeof(data) != TYPE_DICTIONARY or not data.has("device_data"): return false
	
	var cell := local_to_cell(at_position)
	return grid_board.is_inside_grid(cell) and not grid_board.is_cell_occupied(cell)

func _drop_data(at_position: Vector2, data: Variant) -> void:
	var cell := local_to_cell(at_position)
	device_drop_requested.emit(cell, data["device_data"])
