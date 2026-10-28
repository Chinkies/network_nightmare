class_name WiringMode
extends BaseMode


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
		
		# Conversion spatiale -> grille
		var port_w = grid_board.get_port_global_position(device, local_port_id)
		var start_cell = grid_view.local_to_cell(port_w - grid_view.global_position)
		
		# On détermine la direction du port, l'axe permis et le sens strict
		strict_direction = device.get_port_global_direction(local_port_id)
		allowed_axis = Vector2i(abs(strict_direction.x), abs(strict_direction.y))
		initial_strict_direction = strict_direction
		initial_axis = allowed_axis
		
		# Le tableau contient le point de départ, et un second point (flottant) pour la souris
		current_path = [start_cell, start_cell]
		
		ghost_wire_view.update_preview(current_path, grid_view)
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
		
	# On traduit immédiatement la souris en coordonnée logique (bornée à la grille)
	var mouse_world_pos = grid_view.get_global_mouse_position()
	var clicked_cell = grid_view.local_to_cell(mouse_world_pos - grid_view.global_position)
	clicked_cell.x = clampi(clicked_cell.x, 0, grid_board.grid_width - 1)
	clicked_cell.y = clampi(clicked_cell.y, 0, grid_board.grid_height - 1)
		
	# CAS 1 : La souris bouge
	if event is InputEventMouseMotion:
		# current_path[-2] est toujours notre point d'ancrage actuel (le dernier coude validé)
		var valid_cell = _calculate_valid_segment(current_path[-2], clicked_cell, allowed_axis, strict_direction)
		current_path[-1] = valid_cell
		ghost_wire_view.update_preview(current_path, grid_view)
	
	# CAS 2 : Pose d'un coude
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var valid_cell = _calculate_valid_segment(current_path[-2], clicked_cell, allowed_axis, strict_direction)
		
		if clicked_cell == valid_cell and valid_cell != current_path[-2]:
			current_path[-1] = valid_cell
			allowed_axis = Vector2i(1 - allowed_axis.x, 1 - allowed_axis.y)
			strict_direction = Vector2i.ZERO
			current_path.append(valid_cell) # Nouveau point flottant
			
	# CAS 3 : Annulation locale (Clic Droit)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		var target_idx = current_path.find(clicked_cell)
		
		# Si on clique sur une case de notre chemin (en ignorant le bout flottant actuel)
		if target_idx != -1 and target_idx < current_path.size() - 1:
			if target_idx == 0:
				cancel_action()
				return
				
			# On tronque le tableau jusqu'à l'index cible + 1 place pour le flottant
			current_path.resize(target_idx + 2)
			current_path[-1] = current_path[-2] 
			
			var prev_cell = current_path[target_idx - 1]
			var curr_cell = current_path[target_idx]
			var arriving_dir = (curr_cell - prev_cell).sign()
			var arriving_axis = Vector2i(abs(arriving_dir.x), abs(arriving_dir.y))
			
			allowed_axis = Vector2i(1 - arriving_axis.x, 1 - arriving_axis.y)
			strict_direction = Vector2i.ZERO
			
			ghost_wire_view.update_preview(current_path, grid_view)
		else:
			cancel_action()


## Calcule la position finale valide d'un segment de câble en appliquant 
## les contraintes d'axe, de sens, le magnétisme et les collisions.
func _calculate_valid_segment(start_cell: Vector2i, target_cell: Vector2i, axis: Vector2i, strict_dir: Vector2i) -> Vector2i:
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
			return start_cell
			
	if start_cell == constrained_cell:
		return start_cell
		
	# 3. Détection d'obstacles (Raycast sur la grille)
	var current_cell = start_cell
	var dir = (constrained_cell - start_cell).sign()
	
	while current_cell != constrained_cell:
		var next_cell = current_cell + dir
		
		if not grid_board.is_inside_grid(next_cell):
			break
			
		if grid_board.is_cell_occupied(next_cell):
			var item = grid_board.get_cell_item(next_cell)
			
			if item is NetworkDeviceView:
				var compatible_port = null
				var expected_port_dir = Vector2i(-dir.x, -dir.y) 
				
				for child in item.ports_container.get_children():
					if child is NetworkPortView:
						var port_dir = item.logic_device.get_port_global_direction(child.port_id)
						if port_dir == expected_port_dir and child.current_state == NetworkPortView.PortState.AVAILABLE:
							compatible_port = child
							break
							
				if compatible_port != null:
					return next_cell # Cible connectable atteinte
			break # Obstacle rencontré
			
		current_cell = next_cell
		
	return current_cell


func _attempt_connection(target_device: NetworkDevice, target_port_id: int) -> void:
	# 1. Vérification logique basique (Interdire de boucler sur le même port)
	if source_device == target_device and source_port_id == target_port_id:
		print("[WiringMode] Erreur : Impossible de relier un port à lui-même.")
		_reset_selection()
		return
	
	# On traduit le port cible en cellule
	var target_w = grid_board.get_port_global_position(target_device, target_port_id)
	var target_cell = grid_view.local_to_cell(target_w - grid_view.global_position)
	
	# 2. On vérifie la validité physique du tracé
	var valid_cell = _calculate_valid_segment(current_path[-2], target_cell, allowed_axis, strict_direction)
	
	if valid_cell != target_cell:
		print("[WiringMode] Erreur : Le chemin vers ce port n'est pas valide.")
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
