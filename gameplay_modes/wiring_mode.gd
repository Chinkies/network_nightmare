class_name WiringMode
extends BaseMode


# =====================
# ===== STRUCTURE =====
# =====================

## Encapsule le résultat logique pur du calcul d'un segment
class ValidSegmentResult:
	var cell: Vector2i
	var target_device: NetworkDevice
	var target_port_id: int
	
	func _init(c: Vector2i, dev: NetworkDevice = null, port: int = -1) -> void:
		cell = c
		target_device = dev
		target_port_id = port


# =====================
# ===== ATTRIBUTS =====
# =====================

@export var grid_board: GridBoard
@export var grid_view: GridView
@export var ghost_wire_view: GhostWireView

# Mémoire du premier port cliqué
var source_device: NetworkDevice = null
var source_port_id: int = -1

# Variables pour le tracé fantôme (espace grille)
var current_path: Array[Vector2i] = []
var strict_direction: Vector2i = Vector2i.ZERO
var allowed_axis: Vector2i = Vector2i.ZERO
var initial_strict_direction: Vector2i = Vector2i.ZERO
var initial_axis: Vector2i = Vector2i.ZERO


# =====================
# ===== METHODES  =====
# =====================

func _ready() -> void:
	assert(grid_board != null, "[WiringMode] Erreur critique : GridBoard non assigné !")
	assert(grid_view != null, "[WiringMode] Erreur critique : GridView non assigné !")
	assert(ghost_wire_view != null, "[WiringMode] Erreur critique : GhostWireView non assignée !")


# --- Entrée et sortie du mode ---

func enter_mode() -> void:
	grid_board.set_all_ports_interaction_active(true)
	_reset_selection()

func exit_mode() -> void:
	grid_board.set_all_ports_interaction_active(false)
	_reset_selection()


# ------------------------------------------
# --- METHODES SPECIFIQUES AU WIRINGMODE ---
# ------------------------------------------

# --- Interface publique ---

func cancel_action() -> bool:
	if source_device != null:
		print("[WiringMode] Câblage annulé.")
		_reset_selection()
		return true
	return false


func handle_port_click(device: NetworkDevice, local_port_id: int) -> void:
	# CAS 1 : Aucun port n'est encore sélectionné -> On enregistre la source
	if source_device == null:
		source_device = device
		source_port_id = local_port_id
		
		var start_cell = device.grid_position
		
		# On détermine la direction du port, l'axe permis et le sens strict
		strict_direction = device.get_port_global_direction(local_port_id)
		allowed_axis = Vector2i(abs(strict_direction.x), abs(strict_direction.y))
		initial_strict_direction = strict_direction
		initial_axis = allowed_axis
		
		# Le tableau contient le point de départ, et un second point (flottant) pour la souris
		current_path = [start_cell, start_cell]
		
		ghost_wire_view.update_preview(current_path, grid_board, grid_view, source_device, source_port_id)
		grid_board.preview_wiring_compatibility(source_device, source_port_id)
		
	# CAS 2 : On clique sur le MÊME port -> On annule la sélection
	elif source_device == device and source_port_id == local_port_id:
		_reset_selection()
		
	# CAS 3 : On clique sur un port DIFFÉRENT -> On tente la connexion
	else:
		_attempt_connection(device, local_port_id)


# --- Méthodes privées ---

func _unhandled_input(event: InputEvent) -> void:
	if source_device == null:
		return
		
	# On calcule la position brute pour rejeter les clics hors grille
	var mouse_world_pos = grid_view.get_global_mouse_position()
	var raw_cell = grid_view.local_to_cell(mouse_world_pos - grid_view.global_position)
	var is_inside = grid_board.is_inside_grid(raw_cell)
	
	# On calcule une version bornée uniquement pour le mouvement fluide de la souris
	var motion_cell = raw_cell
	motion_cell.x = clampi(motion_cell.x, 0, grid_board.grid_width - 1)
	motion_cell.y = clampi(motion_cell.y, 0, grid_board.grid_height - 1)
		
	# CAS 1 : La souris bouge (position bornée)
	if event is InputEventMouseMotion:
		var result = _calculate_valid_segment(current_path[-2], motion_cell, allowed_axis, strict_direction)
		current_path[-1] = result.cell
		
		ghost_wire_view.update_preview(
			current_path, grid_board, grid_view, 
			source_device, source_port_id, 
			result.target_device, result.target_port_id
		)
	
	# CAS 2 : Pose d'un coude (position brute)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		# Rejet strict des clics hors grille
		if not is_inside:
			return 
			
		var result = _calculate_valid_segment(current_path[-2], raw_cell, allowed_axis, strict_direction)
		
		if result.target_device == null and raw_cell == result.cell and result.cell != current_path[-2]:
			current_path[-1] = result.cell
			allowed_axis = Vector2i(1 - allowed_axis.x, 1 - allowed_axis.y)
			strict_direction = Vector2i.ZERO
			current_path.append(result.cell)
			
	# CAS 3 : Annulation locale au Clic Droit (position brute)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		if not is_inside:
			cancel_action()
			return
			
		var target_idx = current_path.find(raw_cell)
		
		# On exclut le point flottant final de la sélection
		if target_idx != -1 and target_idx < current_path.size() - 1:
			var anchor_idx = target_idx - 1
			
			if anchor_idx < 0:
				cancel_action()
				return
				
			current_path.resize(anchor_idx + 2)
			current_path[-1] = current_path[-2] 
			
			if anchor_idx == 0:
				allowed_axis = initial_axis
				strict_direction = initial_strict_direction
			else:
				var prev_cell = current_path[anchor_idx - 1]
				var curr_cell = current_path[anchor_idx]
				var arriving_dir = (curr_cell - prev_cell).sign()
				var arriving_axis = Vector2i(abs(arriving_dir.x), abs(arriving_dir.y))
				allowed_axis = Vector2i(1 - arriving_axis.x, 1 - arriving_axis.y)
				strict_direction = Vector2i.ZERO
				
			ghost_wire_view.update_preview(current_path, grid_board, grid_view, source_device, source_port_id)
		else:
			cancel_action()


## Calcule la position finale valide d'un segment de câble en appliquant 
## les contraintes d'axe, de sens, le magnétisme et les collisions.
func _calculate_valid_segment(
	start_cell: Vector2i,
	target_cell: Vector2i,
	axis: Vector2i,
	strict_dir: Vector2i,
	expected_target_device: NetworkDevice = null,
	expected_target_port_id: int = -1
) -> ValidSegmentResult:
	var constrained_cell = start_cell
	
	# 1. Contrainte sur l'axe
	if axis.x > 0:
		constrained_cell.x = target_cell.x
		if strict_dir.x > 0: constrained_cell.x = maxi(start_cell.x, target_cell.x)
		elif strict_dir.x < 0: constrained_cell.x = mini(start_cell.x, target_cell.x)
	elif axis.y > 0:
		constrained_cell.y = target_cell.y
		if strict_dir.y > 0: constrained_cell.y = maxi(start_cell.y, target_cell.y)
		elif strict_dir.y < 0: constrained_cell.y = mini(start_cell.y, target_cell.y)
			
	# 2. Vérification absolue de la direction (Produit Scalaire manuel sur entiers)
	if strict_dir != Vector2i.ZERO:
		var dir_to_target = constrained_cell - start_cell
		var dot = (dir_to_target.x * strict_dir.x) + (dir_to_target.y * strict_dir.y)
		if dot <= 0:
			return ValidSegmentResult.new(start_cell)
			
	if start_cell == constrained_cell:
		return ValidSegmentResult.new(start_cell)
		
	# 3. Détection d'obstacles (Raycast sur la grille)
	var current_cell = start_cell
	var dir = (constrained_cell - start_cell).sign()
	
	while current_cell != constrained_cell:
		var next_cell = current_cell + dir
		
		if not grid_board.is_inside_grid(next_cell):
			break
			
		# Une machine cible est autorisée uniquement si le câble arrive par la
		# face du port demandé. Elle doit être testée avant l'auto-collision :
		# une connexion vers le device source peut revenir sur sa case.
		if grid_board.is_cell_occupied(next_cell):
			var item = grid_board.get_cell_item(next_cell)
			
			if item is NetworkDeviceView:
				var expected_port_dir = Vector2i(-dir.x, -dir.y) 
				var compatible_port_id := -1
				
				for child in item.ports_container.get_children():
					if child is NetworkPortView:
						var port_dir = item.logic_device.get_port_global_direction(child.port_id)
						var is_available = child.current_state == NetworkPortView.PortState.AVAILABLE
						var is_requested = (
							expected_target_device == item.logic_device
							and expected_target_port_id == child.port_id
						)
						var is_allowed_target = expected_target_device == null or is_requested
						if port_dir == expected_port_dir and is_available and is_allowed_target:
							compatible_port_id = child.port_id
							break
							
				if compatible_port_id != -1:
					return ValidSegmentResult.new(next_cell, item.logic_device, compatible_port_id)
			break # Obstacle rencontré

		# Vérification d'auto-collision avec les segments précédents
		var hit_self = false
		for i in range(current_path.size() - 2):
			var p1 = current_path[i]
			var p2 = current_path[i+1]
			
			var min_x = mini(p1.x, p2.x)
			var max_x = maxi(p1.x, p2.x)
			var min_y = mini(p1.y, p2.y)
			var max_y = maxi(p1.y, p2.y)
			
			if next_cell.x >= min_x and next_cell.x <= max_x and next_cell.y >= min_y and next_cell.y <= max_y:
				hit_self = true
				break
				
		if hit_self:
			break
			
		current_cell = next_cell
		
	return ValidSegmentResult.new(current_cell)


func _attempt_connection(target_device: NetworkDevice, target_port_id: int) -> void:
	# 1. Vérification logique basique (Interdire de boucler sur le même port)
	if source_device == target_device and source_port_id == target_port_id:
		print("[WiringMode] Erreur : Impossible de relier un port à lui-même.")
		_reset_selection()
		return
	
	var target_cell = target_device.grid_position
	
	# 2. On vérifie la validité physique du tracé
	var result = _calculate_valid_segment(
		current_path[-2],
		target_cell,
		allowed_axis,
		strict_direction,
		target_device,
		target_port_id
	)
	
	if result.cell != target_cell or result.target_device != target_device or result.target_port_id != target_port_id:
		print("[WiringMode] Erreur : Le chemin vers ce port n'est pas valide ou est bloqué.")
		return
	
	# 3. Validation finale
	current_path[-1] = target_cell
	
	# 4. Création de l'objet logique NetworkWire
	var new_wire = NetworkWire.new(
		source_device, source_port_id, 
		target_device, target_port_id, 
		current_path.duplicate()
	)
	
	# 5. Enregistrement physique dans la grille (Bloque les cases pour les autres câbles)
	grid_board.register_wire_cells(new_wire)
	print("[WiringMode] SUCCÈS : Câble créé avec ", current_path.size(), " points. Cases bloquées : ", new_wire.occupied_cells)
	
	# TODO : Instancier la VUE (NetworkWireView) pour remplacer la ghost_line
	
	# 6. Verrouillage définitif des deux ports
	grid_board.set_port_occupied(source_device, source_port_id)
	grid_board.set_port_occupied(target_device, target_port_id)
	
	# 7. Nettoyage de la sélection
	_reset_selection()


## Remet à zéro l'ensemble des paramètres de la sélection en cours (annulation ou validation)
func _reset_selection() -> void:
	if source_device != null:
		grid_board.reset_wiring_preview()
		
	source_device = null
	source_port_id = -1
	current_path.clear()
	allowed_axis = Vector2i.ZERO
	strict_direction = Vector2i.ZERO
	initial_axis = Vector2i.ZERO
	initial_strict_direction = Vector2i.ZERO
	ghost_wire_view.visible = false
