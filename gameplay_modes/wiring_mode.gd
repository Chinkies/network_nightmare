class_name WiringMode
extends BaseMode


# =====================
# ===== ATTRIBUTS =====
# =====================

@export var grid_board: GridBoard
@export var grid_view: GridView

# Mémoire du premier port cliqué
var source_device: NetworkDevice = null
var source_port_id: int = -1

# Variables pour le tracé fantôme
var ghost_line: Line2D
var start_pos: Vector2 = Vector2.ZERO
var allowed_axis: Vector2 = Vector2.ZERO # Vaudra (1,0) pour horizontal, (0,1) pour vertical
var strict_direction: Vector2 = Vector2.ZERO 
var initial_axis: Vector2 = Vector2.ZERO
var initial_strict_direction: Vector2 = Vector2.ZERO


# =====================
# ===== METHODES  =====
# =====================

func _ready() -> void:
	assert(grid_board != null, "[WiringMode] Erreur critique : GridBoard non assigné !")
	assert(grid_view != null, "[WiringMode] Erreur critique : GridView non assigné !")
	
	# Initialisation de la ligne fantôme
	ghost_line = Line2D.new()
	ghost_line.width = 4.0
	ghost_line.default_color = Color("00f0ffd2") # Cyan holographique
	ghost_line.modulate.a = 0.6 # Légèrement transparente
	ghost_line.visible = false
	add_child(ghost_line)


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
		return true # L'événement est consommé
	return false # Rien n'était en cours


func handle_port_click(device: NetworkDevice, local_port_id: int) -> void:
	# CAS 1 : Aucun port n'est encore sélectionné -> On enregistre la source
	if source_device == null:
		source_device = device
		source_port_id = local_port_id
		
		# On récupère la position globale et la direction du port via la grille/device
		start_pos = grid_board.get_port_global_position(device, local_port_id)
		var direction = device.get_port_global_direction(local_port_id)
		
		# On détermine l'axe permis et le sens strict
		allowed_axis = Vector2(abs(direction.x), abs(direction.y))
		strict_direction = direction
		
		# On sauvegarde ces valeurs pour pouvoir y revenir
		initial_axis = allowed_axis
		initial_strict_direction = strict_direction
		
		# On initialise la ligne fantôme
		ghost_line.clear_points()
		ghost_line.add_point(start_pos)
		ghost_line.add_point(start_pos)
		ghost_line.visible = true
		
		# On ordonne à la grille de mettre à jour l'affichage de tous les ports
		grid_board.preview_wiring_compatibility(source_device, source_port_id)
		
	# CAS 2 : On clique sur le MÊME port -> On annule la sélection
	elif source_device == device and source_port_id == local_port_id:
		_reset_selection()
		
	# CAS 3 : On clique sur un port DIFFÉRENT -> On tente la connexion
	else:
		_attempt_connection(device, local_port_id)


# --- Méthodes privées ---

## Mets à jour la ghost_line pour suivre la position de la souris en garrantissant un segment valide.
## Pose un "coude" lors du clic sur une case vide.
func _unhandled_input(event: InputEvent) -> void:
	if source_device == null:
		return
		
	# CAS 1 : La souris bouge
	if event is InputEventMouseMotion:
		var mouse_world_pos = grid_view.get_global_mouse_position()
		var valid_pos = _calculate_valid_segment(start_pos, mouse_world_pos, allowed_axis, strict_direction)
		
		# On met à jour le dernier point de la ghost_line
		ghost_line.set_point_position(ghost_line.get_point_count() - 1, valid_pos)
	
	# CAS 2 : Le joueur fait un clic gauche sur la grille
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var mouse_world_pos = grid_view.get_global_mouse_position()
		
		# On rejette le clic s'il est physiquement hors de la grille
		var clicked_cell = grid_view.local_to_cell(mouse_world_pos - grid_view.global_position)
		if not grid_board.is_inside_grid(clicked_cell):
			return 
		
		var valid_pos = _calculate_valid_segment(start_pos, mouse_world_pos, allowed_axis, strict_direction)
		var snapped_mouse = grid_view.snap_world_to_center(mouse_world_pos)
		
		# On valide le coude si la case cliquée fait partie du tracé valide
		if snapped_mouse == valid_pos and valid_pos != start_pos:
			# 1. Le point validé devient le nouveau point d'ancrage
			start_pos = valid_pos
			
			# 2. On inverse mathématiquement l'axe autorisé (Horizontal <-> Vertical)
			# Si c'était (1,0), ça devient (0,1) et inversement
			allowed_axis = Vector2(1.0 - allowed_axis.x, 1.0 - allowed_axis.y)
			
			# 3. À partir d'un coude, le joueur est libre d'aller dans les deux sens sur le nouvel axe
			strict_direction = Vector2.ZERO
			
			# 4. On ajoute un nouveau point à la ligne (qui deviendra le nouveau point flottant)
			ghost_line.add_point(start_pos)
	
	# --- CAS 3 : Le joueur fait un clic droit (Annulation intelligente ou totale) ---
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		var mouse_world_pos = grid_view.get_global_mouse_position()
		var snapped_mouse = grid_view.snap_world_to_center(mouse_world_pos)
		
		var target_index = -1
		
		# On cherche si la case cliquée correspond à un point posé (sauf le point flottant final)
		for i in range(ghost_line.get_point_count() - 1):
			# distance_to prévient les erreurs d'arrondis des flottants au lieu de "=="
			if ghost_line.get_point_position(i).distance_to(snapped_mouse) < 1.0:
				target_index = i
				break
				
		if target_index != -1:
			var anchor_index = target_index - 1
			
			# Si on clique sur le port de départ (P0), on annule tout le câblage
			if anchor_index < 0:
				cancel_action()
				return
				
			# On recule le point de départ
			start_pos = ghost_line.get_point_position(anchor_index)
			
			# Restauration de l'axe de contrainte
			if anchor_index == 0:
				# Retour à l'état du port source
				allowed_axis = initial_axis
				strict_direction = initial_strict_direction
			else:
				# Rétro-ingénierie : l'axe autorisé est perpendiculaire au segment précédent
				var prev_pos = ghost_line.get_point_position(anchor_index - 1)
				var arriving_dir = (start_pos - prev_pos).normalized()
				var arriving_axis = Vector2(abs(arriving_dir.x), abs(arriving_dir.y))
				allowed_axis = Vector2(1.0 - arriving_axis.x, 1.0 - arriving_axis.y)
				strict_direction = Vector2.ZERO
				
			# Nettoyage visuel : on coupe tous les points après notre nouvelle ancre
			while ghost_line.get_point_count() > anchor_index + 1:
				ghost_line.remove_point(ghost_line.get_point_count() - 1)
				
			# On rajoute le nouveau point flottant pour la souris
			ghost_line.add_point(start_pos)
			
		else:
			# Si le joueur fait un clic droit dans le vide, comportement par défaut : on annule tout
			cancel_action()


## Calcule la position finale valide d'un segment de câble en appliquant 
## les contraintes d'axe, de sens, le magnétisme et les collisions.
func _calculate_valid_segment(start_w: Vector2, target_w: Vector2, axis: Vector2, strict_dir: Vector2) -> Vector2:
	var constrained_pos = start_w
	
	# 1. Contrainte sur l'axe et le sens strict
	if axis.x > 0:
		constrained_pos.x = target_w.x
		if strict_dir.x > 0: constrained_pos.x = max(start_w.x, target_w.x)
		elif strict_dir.x < 0: constrained_pos.x = min(start_w.x, target_w.x)
	elif axis.y > 0:
		constrained_pos.y = target_w.y
		if strict_dir.y > 0: constrained_pos.y = max(start_w.y, target_w.y)
		elif strict_dir.y < 0: constrained_pos.y = min(start_w.y, target_w.y)
			
	# 2. Magnétisme sur les cellules
	var snapped_pos = grid_view.snap_world_to_center(constrained_pos)
	
	# 3. Vérification absolue de la direction (Produit Scalaire)
	if strict_dir != Vector2.ZERO:
		var direction_to_snap = snapped_pos - start_w
		if direction_to_snap.dot(strict_dir) <= 0:
			return start_w # On superpose les points si on part à l'envers
			
	# 4. Détection d'obstacles (Raycast sur la grille)
	# On convertit les positions spatiales en coordonnées de grille
	var start_cell = grid_view.local_to_cell(start_w - grid_view.global_position)
	var target_cell = grid_view.local_to_cell(snapped_pos - grid_view.global_position)
	
	if start_cell == target_cell:
		return snapped_pos
		
	# On avance case par case vers la cible
	var current_cell = start_cell
	var dir = (target_cell - start_cell).sign()
	
	while current_cell != target_cell:
		var next_cell = current_cell + dir
		
		# Arrêt immédiat si on sort de la grille
		if not grid_board.is_inside_grid(next_cell):
			break
			
		# Si la prochaine case est occupée
		if grid_board.is_cell_occupied(next_cell):
			var item = grid_board.get_cell_item(next_cell)
			
			# Si l'obstacle est une machine, on cherche un port d'accueil
			if item is NetworkDeviceView:
				var compatible_port = null
				# Le port cible doit regarder exactement dans la direction opposée à notre câble
				var expected_port_dir = Vector2(-dir.x, -dir.y) 
				
				for child in item.ports_container.get_children():
					if child is NetworkPortView:
						var port_dir = Vector2(item.logic_device.get_port_global_direction(child.port_id)).normalized()
						
						# Si un port est sur cette face ET qu'il est valide/disponible
						if port_dir.is_equal_approx(expected_port_dir) and child.current_state == NetworkPortView.PortState.AVAILABLE:
							compatible_port = child
							break
							
				if compatible_port != null:
					# On renvoie la position du port compatible
					return grid_board.get_port_global_position(item.logic_device, compatible_port.port_id) 
					break
				else:
					# Aucun port valide sur cette face : on s'écrase sur la case précédente
					break 
			else:
				# L'obstacle est autre chose (ex: un autre câble), on s'écrase
				break
				
		current_cell = next_cell
		
	# On retourne le centre spatial de la dernière case libre trouvée
	return grid_view.cell_to_world_center(current_cell)


func _attempt_connection(target_device: NetworkDevice, target_port_id: int) -> void:
	# TODO : Instancier le NetworkWire logique et visuel (le dessin du câble)
	print("[WiringMode] SUCCÈS : Connexion établie entre ", source_device.id, " et ", target_device.id)
	
	# Verrouillage définitif des deux ports
	grid_board.set_port_occupied(source_device, source_port_id)
	grid_board.set_port_occupied(target_device, target_port_id)
	
	# On nettoie la sélection en mémoire sans réinitialiser les ports désormais OCCUPIED
	source_device = null
	source_port_id = -1
	grid_board.reset_wiring_preview()


## Remet à zéro l'ensemble des paramètres de la sélection en cours (annulation ou validation)
func _reset_selection() -> void:
	if source_device != null:
		grid_board.reset_wiring_preview()
		
	source_device = null
	source_port_id = -1
	start_pos = Vector2.ZERO
	allowed_axis = Vector2.ZERO
	strict_direction = Vector2.ZERO
	initial_axis = Vector2.ZERO
	initial_strict_direction = Vector2.ZERO
	ghost_line.visible = false
