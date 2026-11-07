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

# Highlight des cells pour le drop
@export var highlight_valid_color: Color = Color(0.1, 0.8, 0.3, 0.35)   # Vert translucide
@export var highlight_invalid_color: Color = Color(0.9, 0.2, 0.2, 0.35) # Rouge translucide

var device_views: Dictionary[NetworkDevice, NetworkDeviceView] = {}
var wire_views: Dictionary[NetworkWire, NetworkWireView] = {}

## État actuel du Drag & Drop pour le highlight
var _is_dragging_over: bool = false
var _current_drag_cell: Vector2i = Vector2i(-1, -1)
var _is_current_cell_valid: bool = false
var _is_device_selected: bool = false
var _selected_cell: Vector2i = Vector2i(-1, -1)


# ====================
# ===== METHODES =====
# ====================

func _ready() -> void:
	assert(grid_board != null, "[GridView] Erreur critique : GridBoard non assigné !")
	
	# La vue s'adapte automatiquement à la taille dictée par le modèle
	custom_minimum_size = Vector2(grid_board.grid_width * cell_size, grid_board.grid_height * cell_size)
	size = custom_minimum_size


func _draw() -> void:
	var total_size := size
	
	# 1. Dessin de la grille
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
	
	# 2. Dessin de la sélection (carré jaune)
	if _is_device_selected and grid_board.is_cell_inside_grid(_selected_cell):
		var rect := Rect2(
			Vector2(_selected_cell.x * cell_size, _selected_cell.y * cell_size),
			Vector2(cell_size, cell_size)
		)
		draw_rect(rect, Color.YELLOW, false, 1.0)

	# 3. Dessin du Drag & Drop (carré vert/rouge)
	if _is_dragging_over and grid_board.is_cell_inside_grid(_current_drag_cell):
		var rect := Rect2(
			Vector2(_current_drag_cell.x * cell_size, _current_drag_cell.y * cell_size),
			Vector2(cell_size, cell_size)
		)
		var color = highlight_valid_color if _is_current_cell_valid else highlight_invalid_color
		draw_rect(rect, color, true)
		draw_rect(rect, color.lightened(0.4), false, 2.0)



# -----------------------------
# --- Conversions Spatiales ---
# -----------------------------

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


## Aligne une coordonnée spatiale (monde) sur le centre de la cellule correspondante
func snap_world_to_center(world_pos: Vector2) -> Vector2:
	# On repasse en coordonnées locales pour prendre en compte un éventuel décalage de la grille
	var local_pos = world_pos - global_position
	var cell = local_to_cell(local_pos)
	
	# On clamp aux limites de la grille
	if grid_board:
		cell.x = clamp(cell.x, 0, grid_board.grid_width - 1)
		cell.y = clamp(cell.y, 0, grid_board.grid_height - 1)
	
	return cell_to_world_center(cell)


## Calcule la position idéale (pixels globaux) pour afficher une UI au-dessus de la case pointée
func get_delete_bar_placement(mouse_global_pos: Vector2) -> Vector2:
	# 1. On trouve la case visée
	var local_pos = mouse_global_pos - global_position
	var cell = local_to_cell(local_pos)
	
	# 2. On trouve le centre global de cette case
	var cell_center = cell_to_world_center(cell)
	
	# 3. On applique l'offset visuel vers le haut (axe Y négatif)
	var visual_offset = Vector2(0, -cell_size * 0.4)
	
	return cell_center + visual_offset



# ----------------------------------------
# --- Gestion des registres Model/View ---
# ----------------------------------------

# --- Enregistrement / Suppression de device --- 

func register_device_view(device: NetworkDevice, view: NetworkDeviceView) -> void:
	if device != null and view != null and view.logic_device == device:
		device_views[device] = view

func unregister_device_view(device: NetworkDevice) -> void:
	if device != null and device_views.has(device):
		device_views.erase(device)


# --- Enregistrement / Suppression de wire --- 

func register_wire_view(wire: NetworkWire, view: NetworkWireView) -> void:
	if wire != null and view != null and view.logic_wire == wire:
		wire_views[wire] = view

func unregister_wire_view(wire: NetworkWire) -> void:
	if wire != null and wire_views.has(wire):
		wire_views.erase(wire)


# --- Getters --- 

func get_device_view(device: NetworkDevice) -> NetworkDeviceView:
	if device == null:
		return null
	return device_views.get(device)

func get_wire_view(wire: NetworkWire) -> NetworkWireView:
	if wire == null:
		return null
	return wire_views.get(wire)


## Récupère la position globale exacte du centre d'un port
func get_port_global_position(device: NetworkDevice, port_id: int) -> Vector2:
	var view = get_device_view(device)
	if view != null:
		for child in view.ports_container.get_children():
			if child is NetworkPortView and child.port_id == port_id:
				return child.global_position
	return Vector2.ZERO



# -------------------------------------
# --- Gestion des visuels des ports ---
# -------------------------------------

## Affiche tous les ports actifs (non bloqués) de tous les devices enregistrés
func display_all_ports(active: bool) -> void:
	for view: NetworkDeviceView in device_views.values():
		view.display_ports(active)


## Évalue la compatibilité physique de tous les ports de la grille par rapport au port source
func preview_wiring_compatibility(source_device: NetworkDevice, source_port_id: int) -> void:
	for view: NetworkDeviceView in device_views.values():
		view.set_ports_comptibility_view(source_device, source_port_id)


## Remet tous les ports non-occupés dans leur état AVAILABLE de base
func reset_wiring_preview() -> void:
	for view: NetworkDeviceView in device_views.values():
		view.reset_ports_comptibility_view()


## Passe un port spécifique en état OCCUPIED (grisé et non cliquable)
func set_port_occupied(device: NetworkDevice, port_id: int) -> bool:
	if device_views.has(device):
		if device.input_wires.has(port_id):
			device_views.get(device).set_port_visual_state(port_id, NetworkPortView.PortState.OCCUPIED_INPUT)
			return true
		elif device.output_wires.has(port_id):
			device_views.get(device).set_port_visual_state(port_id, NetworkPortView.PortState.OCCUPIED_OUTPUT)
			return true
	return false


## Passe un port spécifique en état AVAILABLE (coloré et cliquable)
func set_port_available(device: NetworkDevice, port_id: int) -> bool:
	if device_views.has(device):
		device_views.get(device).set_port_visual_state(port_id, NetworkPortView.PortState.AVAILABLE)
		return true
	return false



# -------------------------------------------------------------
# --- Gestion du Drag & Drop Manuel (déplacement de device) ---
# -------------------------------------------------------------

## Affiche le contour jaune de sélection sur une case donnée
func set_selection_highlight(cell: Vector2i) -> void:
	if not _is_device_selected or _selected_cell != cell:
		_is_device_selected = true
		_selected_cell = cell
		queue_redraw()

## Masque le contour jaune de sélection
func clear_selection_highlight() -> void:
	if _is_device_selected:
		_is_device_selected = false
		queue_redraw()


## Force l'affichage du survol (vert/rouge) sur une cellule précise
func set_drag_highlight(cell: Vector2i, is_valid: bool) -> void:
	if _current_drag_cell != cell or _is_current_cell_valid != is_valid or not _is_dragging_over:
		_is_dragging_over = true
		_current_drag_cell = cell
		_is_current_cell_valid = is_valid
		queue_redraw()

## Cache le survol
func clear_drag_highlight() -> void:
	if _is_dragging_over:
		_is_dragging_over = false
		queue_redraw()

## Place visuellement un appareil à une position spatiale (utilisé pendant le drag)
func set_device_visual_position(device: NetworkDevice, global_pos: Vector2) -> void:
	var view = get_device_view(device)
	if view != null:
		view.global_position = global_pos



# -----------------------------------------------------
# --- Gestion du Drag & Drop natif (pose de device) ---
# -----------------------------------------------------

func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	if not grid_board: 
		return false
	if typeof(data) != TYPE_DICTIONARY or not data.has("device_data"): 
		return false
	
	var cell := local_to_cell(at_position)
	var is_valid = grid_board.is_cell_inside_grid(cell) and not grid_board.is_cell_occupied(cell)
	
	# On active le mode de survol et on met à jour la cellule ciblée en temps réel
	if not _is_dragging_over or _current_drag_cell != cell or _is_current_cell_valid != is_valid:
		_is_dragging_over = true
		_current_drag_cell = cell
		_is_current_cell_valid = is_valid
		queue_redraw() # Force le redessin du highlight
		
	return is_valid


func _drop_data(at_position: Vector2, data: Variant) -> void:
	_is_dragging_over = false
	queue_redraw()
	
	var cell := local_to_cell(at_position)
	device_drop_requested.emit(cell, data["device_data"])

# ------------------------------------
# --- Prévisualisation Drag & Drop ---
# ------------------------------------

func _notification(what: int) -> void:
	# Si le drag se termine ou sort de la zone sans être lâché sur un drop valide
	if what == NOTIFICATION_DRAG_END:
		if _is_dragging_over:
			_is_dragging_over = false
			queue_redraw()
