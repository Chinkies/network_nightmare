class_name GridManager
extends Node2D


# =====================
# ===== ATTRIBUTS =====
# =====================

## Référence vers la simulation pour enregistrer les machines créées
@export var simulation: NetworkSimulation

@export var cell_size: int = 64
@export var grid_width: int = 10   # Largeur en nombre de cellules
@export var grid_height: int = 6  # Hauteur en nombre de cellules

@export var line_color: Color = Color(0.25, 0.3, 0.4, 0.4)
@export var background_color: Color = Color(0.08, 0.1, 0.14, 1.0)
@export var border_color: Color = Color(0.35, 0.45, 0.6, 0.8)

## Registre des cellules occupées
var _occupied_cells: Dictionary[Vector2i, Variant] = {}



# ===============================
# ===== DESSIN DE LA GRILLE =====
# ===============================

func _draw() -> void:
	var total_size := Vector2(grid_width * cell_size, grid_height * cell_size)
	
	# Fond du plateau de jeu
	draw_rect(Rect2(Vector2.ZERO, total_size), background_color, true)

	# Lignes verticales
	for x in range(grid_width + 1):
		var from := Vector2(x * cell_size, 0)
		var to := Vector2(x * cell_size, total_size.y)
		draw_line(from, to, line_color, 1.0)

	# Lignes horizontales
	for y in range(grid_height + 1):
		var from := Vector2(0, y * cell_size)
		var to := Vector2(total_size.x, y * cell_size)
		draw_line(from, to, line_color, 1.0)

	# Bordure extérieure du plateau
	draw_rect(Rect2(Vector2.ZERO, total_size), border_color, false, 2.0)


# ===========================================
# ===== CONVERSIONS ET LOGIQUE SPATIALE =====
# ===========================================

## Convertit une position monde (ex: globale de la souris) en coordonnées de cellule (colonne, ligne)
func world_to_cell(world_pos: Vector2) -> Vector2i:
	var local_pos := to_local(world_pos)
	return Vector2i(
		int(floor(local_pos.x / cell_size)),
		int(floor(local_pos.y / cell_size))
	)


## Renvoie la position monde du centre d'une cellule donnée
func cell_to_world_center(cell: Vector2i) -> Vector2:
	var local_pos := Vector2(
		(cell.x * cell_size) + (cell_size * 0.5),
		(cell.y * cell_size) + (cell_size * 0.5)
	)
	return to_global(local_pos)


## Vérifie si une coordonnée de cellule est dans les limites du niveau
func is_inside_grid(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < grid_width and cell.y >= 0 and cell.y < grid_height



# =======================================================
# ===== GETTERS DES METRIQUES RELATIVES A LA CAMERA =====
# =======================================================

## Renvoie la taille totale de la grille en pixels
func get_grid_pixel_size() -> Vector2:
	return Vector2(grid_width * cell_size, grid_height * cell_size)

## Renvoie le centre global du plateau
func get_grid_center_world() -> Vector2:
	return to_global(get_grid_pixel_size() * 0.5)



# =========================================
# ===== GESTION DES CELLULES OCCUPEES =====
# =========================================

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


## Vérifie si le chemin en ligne droite entre start et end est libre (excluant start et end)
func is_straight_path_clear(start: Vector2i, end: Vector2i) -> bool:
	# 1. Vérifie si le tracé est bien une ligne droite (strictement horizontal ou vertical)
	if start.x != end.x and start.y != end.y:
		return false
		
	# 2. Détermine la direction du mouvement (ex: Vector2i(1, 0) pour la droite)
	var dir := (end - start).sign()
	var current := start + dir
	
	# 3. Parcours des cases intermédiaires jusqu'à la destination
	while current != end:
		if not is_inside_grid(current):
			return false
		if is_cell_occupied(current):
			return false
		current += dir
		
	return true



# ================================================
# ===== GESTION DU DRAG & DROP SUR LA GRILLE =====
# ================================================

## Vérifie si le drop est possible sur la case
func can_handle_drop(_at_position: Vector2, data: Variant) -> bool:
	
	# Securité sur le contenu de data
	if typeof(data) != TYPE_DICTIONARY or not data.has("device_data"):
		print("[GridManager] PLacement impossible device incorrecte")
		return false
	
	var cell := world_to_cell(get_global_mouse_position())

	# Verifie si la cellule est occupée / dans la grille
	if not is_inside_grid(cell) or is_cell_occupied(cell):
		return false

	return true


## Exécute le drop du device
func handle_drop(_at_position: Vector2, data: Variant) -> void:
	if not can_handle_drop(_at_position, data):
		return
		
	var device_data: NetworkDeviceData = data["device_data"]
	var cell := world_to_cell(get_global_mouse_position())

	# 1. Création de la machine logique
	var unique_id = "%s_%d_%s" % [device_data.device_id_template, cell.x, cell.y]
	var logic_device = device_data.instantiate_device(unique_id)
	logic_device.grid_position = cell

	# 2. Création de la machine visuelle (La Vue)
	if not device_data.device_scene:
		push_error("[GridManager] Impossible de placer : aucune device_scene définie dans la ressource !")
		return
		
	var view_node = device_data.device_scene.instantiate() as NetworkDeviceView
	if not view_node:
		push_error("[GridManager] La scène n'a pas le script NetworkDeviceView attaché !")
		return

	# On place le visuel au centre de la case
	view_node.global_position = cell_to_world_center(cell)
	add_child(view_node)
	
	# 3. On lie la vue à la logique
	view_node.setup(logic_device, device_data.texture, float(cell_size))

	# 4. Enregistrements
	set_cell_occupied(cell, view_node)
	
	if simulation:
		simulation.register_device(logic_device)
	else:
		push_warning("[GridManager] Attention, aucune NetworkSimulation assignée. La machine ne tournera pas !")

	print("[GridManager] Appareil '%s' placé et enregistré avec succès." % unique_id)
