class_name GridManager
extends Node2D

# =====================
# ===== ATTRIBUTS =====
# =====================

@export var cell_size: int = 64
@export var grid_width: int = 10   # Largeur en nombre de cellules
@export var grid_height: int = 6  # Hauteur en nombre de cellules

@export var line_color: Color = Color(0.25, 0.3, 0.4, 0.4)
@export var background_color: Color = Color(0.08, 0.1, 0.14, 1.0)
@export var border_color: Color = Color(0.35, 0.45, 0.6, 0.8)

# Registre des cellules occupées : Vector2i -> Node (ou NetworkDevice)
var _occupied_cells: Dictionary = {}


# ====================
# ===== METHODES =====
# ====================

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


# --- Gestion de l'occupation des cellules ---

func is_cell_occupied(cell: Vector2i) -> bool:
	return _occupied_cells.has(cell)


func set_cell_occupied(cell: Vector2i, device: Node) -> void:
	_occupied_cells[cell] = device


func free_cell(cell: Vector2i) -> void:
	_occupied_cells.erase(cell)


# --- Getters pour setup la caméra ---

## Renvoie la taille totale de la grille en pixels
func get_grid_pixel_size() -> Vector2:
	return Vector2(grid_width * cell_size, grid_height * cell_size)


## Renvoie le centre global du plateau
func get_grid_center_world() -> Vector2:
	return to_global(get_grid_pixel_size() * 0.5)


# ================================================
# ===== GESTION DU DRAG & DROP SUR LA GRILLE =====
# ================================================

## Verifie si le drop est possible sur la case
func can_handle_drop(_at_position: Vector2, data: Variant) -> bool:
	
	# Securité sur le contenu de data
	if typeof(data) != TYPE_DICTIONARY or not data.has("item_data"):
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
		
	var item_data: NetworkDeviceData = data["item_data"]
	var cell := world_to_cell(get_global_mouse_position())

	var unique_id = "%s_%d_%s" % [item_data.device_id_template, cell.x, cell.y]

	var logic_device = item_data.instantiate_device(unique_id)
	logic_device.grid_position = cell

	var device_node: Node2D = null
	if item_data.device_scene:
		device_node = item_data.device_scene.instantiate() as Node2D
	else :
		device_node = Node2D.new()
		var sprite = Sprite2D.new()
		sprite.texture = item_data.icon
		if item_data.icon:
				var tex_size := item_data.icon.get_size()
				if tex_size.x > 0 and tex_size.y > 0:
					var scale_factor = float(cell_size) / max(tex_size.x, tex_size.y)
					sprite.scale = Vector2(scale_factor, scale_factor)
		device_node.add_child(sprite)

	device_node.global_position = cell_to_world_center(cell)
	
	add_child(device_node)
	set_cell_occupied(cell, device_node)

	print("[GridManager] Appareil '%s' placé avec succès sur la cellule %s" % [unique_id, cell])
