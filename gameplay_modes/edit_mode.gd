class_name EditMode
extends BaseMode


# =====================
# ===== ATTRIBUTS =====
# =====================

# --- Dépendances --- 
@export var grid_board: GridBoard
@export var grid_view: GridView
@export var simulation: SimulationRunner

# --- Sélection de device --- 
var selected_device: NetworkDevice = null

# --- Drag & Drop ---
var is_dragging: bool = false
var drag_start_cell: Vector2i = Vector2i.ZERO


# =====================
# ===== METHODES  =====
# =====================

func _ready() -> void:
	# Vérification des dépendances
	assert(grid_board != null, "[EditMode] Erreur critique : GridBoard non assigné !")
	assert(grid_view != null, "[EditMode] Erreur critique : GridView non assigné !")
	assert(simulation != null, "[EditMode] Erreur critique : SimulationRunner non assigné !")


func exit_mode() -> void:
	if is_dragging:
		_end_drag()
	_deselect_current()


# --------------------------
# --- INTERFACE PUBLIQUE ---
# --------------------------

func handle_unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		
		# 1. CLIC ENFONCÉ dans le vide (Désélection)
		if event.pressed:
			var local_pos = grid_view.get_local_mouse_position()
			var cell = grid_view.local_to_cell(local_pos)
			if not grid_board.is_cell_inside_grid(cell) or not grid_board.is_cell_occupied(cell):
				_deselect_current()
				
		# 2. CLIC RELÂCHÉ (Fin du Drag)
		elif not event.pressed and is_dragging:
			_end_drag()


## Au clic d'un device, s'il n'est pas déjà séléctionné le sélectionne. 
## S'il n'est pas sélectionné et qu'il n'est pas branché commence le drag
func handle_item_interaction_started(item: NetworkItem) -> void:
	if item is NetworkDevice:
		var device: NetworkDevice = item
		
		if device != selected_device:
			_select_device(item)
		else:
			# Vérification des droits de déplacement
			if not device.is_movable:
				print("[EditMode] Cette machine est fixée par le niveau, déplacement interdit.")
				return
			
			# Si le device est sélectionné et non connecté, on démarre le Drag & Drop
			if not device.is_wired():
				is_dragging = true
				drag_start_cell = item.grid_position


## Au drop d'un device sélectionné depuis le menu de sélection, place ce device sur la grille si la position est valide
func handle_device_drop(cell: Vector2i, device_data: Variant) -> void:
	# 1. Vérification dans le Modèle
	if grid_board.is_cell_occupied(cell):
		print("[EditMode] Case occupée, placement annulé.")
		return

	# 2. Création de la machine logique
	var unique_id = "%s_%d_%d" % [device_data.device_id_template, cell.x, cell.y]
	var logic_device = device_data.instantiate_device(unique_id)
	logic_device.grid_position = cell

	# 3. Création de la machine visuelle
	if not device_data.device_scene:
		push_error("[EditMode] Scène visuelle manquante dans la ressource !")
		return
		
	var device_view = device_data.device_scene.instantiate() as NetworkDeviceView
	device_view.global_position = grid_view.cell_to_world_center(cell)
	
	# Le GridView sert de conteneur d'affichage
	grid_view.add_child(device_view)
	device_view.setup(logic_device, device_data.texture, float(grid_view.cell_size))

	# 4. Enregistrement dans les systèmes
	grid_board.register_device(logic_device)
	grid_view.register_device_view(logic_device, device_view)


func handle_rotate_requested(direction: int) -> void:
	if selected_device == null:
		return
	
	# Vérification des droits de déplacement
	if not selected_device.is_movable:
		print("[EditMode] Cette machine est fixée par le niveau, rotation interdite.")
		return
		
	# On ne peut pas tourner une machine déjà connectée à des câbles
	if selected_device.is_wired():
		print("[EditMode] Impossible de tourner une machine connectée.")
		return
		
	selected_device.rotate(direction)
	
	var view = grid_view.get_device_view(selected_device)
	if view != null:
		view.update_rotation(direction, grid_view.cell_size)



# ----------------------
# --- LOGIQUE PRIVEE --- 
# ----------------------

## Enregistre un device comme sélectionné et créé un feedback visuel, s'il ne l'est pas déjà
func _select_device(device: NetworkDevice) -> void:
	if selected_device == device:
		return
		
	_deselect_current()
	selected_device = device
	
	grid_view.set_selection_highlight(selected_device.grid_position)


## Réinitialise la sélection
func _deselect_current() -> void:
	if selected_device != null:
		grid_view.clear_selection_highlight()
		selected_device = null


## Gère le déplacement en direct lors du drag
func _process(_delta: float) -> void:
	if is_dragging and selected_device != null:
		var mouse_pos = grid_view.get_global_mouse_position()
		var cell = grid_view.local_to_cell(mouse_pos - grid_view.global_position)
		
		# 1. On déplace visuellement la machine sous la souris (centrée)
		grid_view.set_device_visual_position(selected_device, mouse_pos)
		
		# 2. On calcule si la case survolée est valide
		var is_valid = false
		if grid_board.is_cell_inside_grid(cell):
			if not grid_board.is_cell_occupied(cell) or cell == drag_start_cell:
				is_valid = true
				
		# 3. On ordonne le highlight vert/rouge
		grid_view.set_drag_highlight(cell, is_valid)


## Met fin au drag. Si la case finale est valide, enregistre le déplacement, sinon replace le device à la cellule de départ
func _end_drag() -> void:
	is_dragging = false
	grid_view.clear_drag_highlight()
	
	if selected_device == null:
		return
		
	var mouse_pos = grid_view.get_global_mouse_position()
	var cell = grid_view.local_to_cell(mouse_pos - grid_view.global_position)
	
	# Vérification de la validité du placement
	if grid_board.is_cell_inside_grid(cell) and (not grid_board.is_cell_occupied(cell) or cell == drag_start_cell):
		# Déplacement valide (Logique)
		grid_board.unregister_device(selected_device)
		selected_device.grid_position = cell
		grid_board.register_device(selected_device)
	else:
		# Déplacement invalide : on restaure la case de départ
		cell = drag_start_cell

	# On ordonne l'animation de la Vue pour s'aimanter (snap) proprement au centre de la case finale
	var target_pos = grid_view.cell_to_world_center(cell)
	var view = grid_view.get_device_view(selected_device)
	if view != null:
		var tween = create_tween()
		tween.tween_property(view, "global_position", target_pos, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	# NOUVEAU : On met à jour la case sélectionnée
	grid_view.set_selection_highlight(selected_device.grid_position)
