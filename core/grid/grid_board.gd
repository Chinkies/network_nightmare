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

# --- Getters ---

## Vérifie si une coordonnée mathématique est dans les limites
func is_inside_grid(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < grid_width and cell.y >= 0 and cell.y < grid_height

## Vérifie si une cellule de la grille est occupée
func is_cell_occupied(cell: Vector2i) -> bool:
	return _occupied_cells.has(cell)

## Retourne l'item qui occupe une cellule
func get_cell_item(cell: Vector2i) -> Variant:
	if not is_cell_occupied(cell):
		return null
	return _occupied_cells[cell]


## Récupère la position globale exacte du centre d'un port
func get_port_global_position(device: NetworkDevice, port_id: int) -> Vector2:
	# Retrouver la vue associée à l'appareil logique
	for cell in _occupied_cells:
		var view = _occupied_cells[cell]
		if view is NetworkDeviceView and view.logic_device == device:
			for child in view.ports_container.get_children():
				if child is NetworkPortView and child.port_id == port_id:
					return child.global_position
	return Vector2.ZERO



# ----------------------------------------------
# --- Enregistrement / Libération de cellule ---
# ----------------------------------------------

## Passe une cellule de la grille en "occupied"
func set_cell_occupied(cell: Vector2i, network_item: Variant) -> void:
	_occupied_cells[cell] = network_item

## Libère une cellule occupée de la grille
func free_cell(cell: Vector2i) -> void:
	_occupied_cells.erase(cell)


## Enregistre comme "occupied" toutes les cellules par lesquelles passe un Wire
func register_wire_cells(wire: NetworkWire) -> void:
	if wire == null or wire.occupied_cells.size() == 0:
		return
	for cell in wire.occupied_cells:
		set_cell_occupied(cell, wire)

## Libère toutes les cellules occupées par un Wire
func unregister_wire_cells(wire: NetworkWire) -> void:
	if wire == null or wire.occupied_cells.size() == 0:
		return
	for cell in wire.occupied_cells:
		free_cell(cell)



# ------------------------------------------------------
# --- Gestion de la visibilité des ports des devices ---
# ------------------------------------------------------

## Affiche ou masque les ports de toutes les machines actuellement sur la grille
func set_all_ports_interaction_active(active: bool) -> void:
	for cell in _occupied_cells:
		var item = _occupied_cells[cell]
		# On s'assure que l'objet est bien une vue de machine avant de l'appeler
		if item is NetworkDeviceView:
			item.set_ports_active(active)


## Évalue la compatibilité physique de tous les ports de la grille par rapport au port source
func preview_wiring_compatibility(source_device: NetworkDevice, source_port_id: int) -> void:
	var source_type = source_device.port_types[source_port_id]
	
	for cell in _occupied_cells:
		var view = _occupied_cells[cell]
		if view is NetworkDeviceView:
			view.evaluate_ports_compatibility(source_device, source_port_id, source_type)


## Remet tous les ports non-occupés dans leur état AVAILABLE de base
func reset_wiring_preview() -> void:
	for cell in _occupied_cells:
		var view = _occupied_cells[cell]
		if view is NetworkDeviceView:
			view.reset_available_ports()


## Passe un port spécifique en état OCCUPIED (grisé, non cliquable)
func set_port_occupied(device: NetworkDevice, port_id: int) -> void:
	for cell in _occupied_cells:
		var view = _occupied_cells[cell]
		if view is NetworkDeviceView and view.logic_device == device:
			view.set_specific_port_state(port_id, NetworkPortView.PortState.OCCUPIED)
			break
