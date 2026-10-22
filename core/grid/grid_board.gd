class_name GridBoard
extends Node


# =====================
# ===== ATTRIBUTS =====
# =====================

@export var grid_width: int = 10
@export var grid_height: int = 6

## Registre des cellules occupées (Clé: Vector2i, Valeur: Object)
var _occupied_cells: Dictionary[Vector2i, Variant] = {}


# ====================
# ===== METHODES =====
# ====================

## Vérifie si une coordonnée mathématique est dans les limites
func is_inside_grid(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < grid_width and cell.y >= 0 and cell.y < grid_height

func is_cell_occupied(cell: Vector2i) -> bool:
	return _occupied_cells.has(cell)

func get_cell_item(cell: Vector2i) -> Variant:
	if not is_cell_occupied(cell):
		return null
	return _occupied_cells[cell]

func set_cell_occupied(cell: Vector2i, network_item: Variant) -> void:
	_occupied_cells[cell] = network_item

func free_cell(cell: Vector2i) -> void:
	_occupied_cells.erase(cell)


# ---------------------------------------
# --- Gestion des cellules des câbles ---
# ---------------------------------------

func register_wire(wire: NetworkWire) -> void:
	if wire == null or wire.occupied_cells.size() == 0:
		return
	for cell in wire.occupied_cells:
		set_cell_occupied(cell, wire)

func unregister_wire(wire: NetworkWire) -> void:
	if wire == null or wire.occupied_cells.size() == 0:
		return
	for cell in wire.occupied_cells:
		free_cell(cell)


## Vérifie si le chemin en ligne droite entre start et end est libre
func is_straight_path_clear(start: Vector2i, end: Vector2i) -> bool:
	if start.x != end.x and start.y != end.y:
		return false
		
	var dir := (end - start).sign()
	var current := start + dir
	
	while current != end:
		if not is_inside_grid(current) or is_cell_occupied(current):
			return false
		current += dir
		
	return true
