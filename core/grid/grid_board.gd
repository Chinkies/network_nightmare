class_name GridBoard
extends Node


# =====================
# ===== ATTRIBUTS =====
# =====================

@export var grid_width: int = 10
@export var grid_height: int = 6

## Registre des cellules occupées
var _occupied_cells: Dictionary[Vector2i, NetworkItem] = {}


# ====================
# ===== METHODES =====
# ====================

# --- Getters ---

## Vérifie si une coordonnée mathématique est dans les limites
func is_cell_inside_grid(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < grid_width and cell.y >= 0 and cell.y < grid_height

## Vérifie si une cellule de la grille est occupée
func is_cell_occupied(cell: Vector2i) -> bool:
	return _occupied_cells.has(cell)


## Retourne l'item qui occupe une cellule
func get_cell_item(cell: Vector2i) -> NetworkItem:
	if not is_cell_occupied(cell):
		return null
	return _occupied_cells[cell]


## Retourne le device qui se trouve sur une case
## Retourne null si la case est vide ou occupée par un autre type d'item
func get_device_at(cell: Vector2i) -> NetworkDevice:
	if not is_cell_occupied(cell):
		return null
	
	var item = get_cell_item(cell)
	if item is NetworkDevice:
		return item
	
	return null

## Retourne le wire qui se trouve sur une case
## Retourne null si la case est vide ou occupée par un autre type d'item
func get_wire_at(cell: Vector2i) -> NetworkWire:
	if not is_cell_occupied(cell):
		return null
	
	var item = get_cell_item(cell)
	if item is NetworkWire:
		return item
	
	return null


## Retourne la liste des devices uniques placés sur la grille
func get_devices() -> Array[NetworkDevice]:
	var devices: Array[NetworkDevice] = []
	
	for item in _occupied_cells.values():
		if item is NetworkDevice and not devices.has(item):
			devices.append(item)
	
	return devices



# ------------------------------------------
# --- Enregistrement / Libération d'item ---
# ------------------------------------------

## Enregistre un device et la cellule qu'il occupe
## Retourne un booléen indiquant si le succès de l'enregistrement. 
func register_device(device: NetworkDevice) -> bool:
	if device == null:
		return false
	
	var cell = device.grid_position
	if ( not is_cell_inside_grid(cell) ) or is_cell_occupied(cell):
		return false
	
	_occupied_cells[cell] = device
	return true

## Libère la cellule occupée par un device
func unregister_device(device: NetworkDevice) -> void:
	if device == null:
		return
	
	var cell = device.grid_position
	if _occupied_cells.get(cell) == device:
		_occupied_cells.erase(cell)


## Enregistre un wire et passe en "occupied" toutes les cellules qu'il occupe.
## Retourne un booléen indiquant si la validité du wire a permis l'enregistrement. 
func register_wire(wire: NetworkWire) -> bool:
	if wire == null:
		return false
	
	if wire.occupied_cells.is_empty():
		return true
	
	for cell in wire.occupied_cells:
		if not is_cell_inside_grid(cell):
			return false
		if is_cell_occupied(cell):
			return false
	
	for cell in wire.occupied_cells:
		_occupied_cells[cell] = wire
	
	return true

## Libère toutes les cellules occupées par un Wire
func unregister_wire(wire: NetworkWire) -> void:
	if wire == null or wire.occupied_cells.size() == 0:
		return
	for cell in wire.occupied_cells:
		if _occupied_cells.get(cell) == wire:
			_occupied_cells.erase(cell)
