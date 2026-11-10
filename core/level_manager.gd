class_name LevelManager
extends Node

# =====================
# ===== ATTRIBUTS =====
# =====================

@export_category("Registres, Grid & Simulation")
@export var mode_manager: ModeManager
@export var simulation: SimulationRunner
@export var level_validator: LevelValidator
@export var grid_board: GridBoard
@export var grid_view: GridView
@export var puzzle_ui: PuzzleUiController

@export_category("UI & Menus")
@export var pause_menu: PauseMenu
@export var level_end_ui: LevelEndUi

## Niveau de test par défaut si la scène est lancée directement depuis l'éditeur
@export var fallback_default_level: LevelDefinition

var is_loading_level: bool = false
var current_level: LevelDefinition

var unlocked_hints_count: int = 0

# Vitesses disponibles pour la boucle cyclique
var speed_multipliers: Array[float] = [1.0, 2.0, 0.5]
var current_speed_index: int = 0

# ====================
# ===== METHODES =====
# ====================

func _ready() -> void:
	assert(mode_manager != null, "[LevelManager] Erreur critique : ModeManager non assigné !")
	assert(simulation != null, "[LevelManager] Erreur critique : SimulationRunner non assigné !")
	assert(level_validator != null, "[LevelManager] Erreur critique : LevelValidator non assigné !")
	assert(grid_board != null, "[LevelManager] Erreur critique : GridBoard non assigné !")
	assert(grid_view != null, "[LevelManager] Erreur critique : GridView non assigné !")
	assert(puzzle_ui != null, "[LevelManager] Erreur critique : PuzzleUiController non assigné !")
	
	_connect_signals()
	
	puzzle_ui.set_reset_button_enabled(false)
	puzzle_ui.set_simulation_button_state(false)

	call_deferred("_load_current_level")

func _connect_signals() -> void:
	# Connexion des signaux de l'ui
	puzzle_ui.simulation_button_pressed.connect(_on_simulation_requested)
	puzzle_ui.reset_button_pressed.connect(_on_reset_requested)
	puzzle_ui.wiring_button_pressed.connect(_on_wiring_requested)
	puzzle_ui.edit_button_pressed.connect(_on_edit_requested)
	puzzle_ui.delete_button_pressed.connect(_on_delete_requested)
	puzzle_ui.speed_button_pressed.connect(_on_speed_requested)
	puzzle_ui.hint_button_pressed.connect(_on_hint_requested)
	puzzle_ui.tutorial_button_pressed.connect(_on_tutorial_requested)

	# Connexion des signaux du ModeManager
	mode_manager.mode_changed.connect(_on_mode_changed)
	level_validator.validation_finished.connect(_on_validation_finished)
	
	level_end_ui.restart_requested.connect(_on_restart_end_ui_requested)
	level_end_ui.return_to_selection_requested.connect(_on_return_to_selection_requested)
	level_end_ui.next_level_requested.connect(_on_next_level_requested)

	# Connexion des signaux du GridBoard
	grid_board.device_registered.connect(_on_device_placed_on_grid)
	grid_board.device_unregistered.connect(_on_device_removed_from_grid)
	grid_board.wire_registered.connect(simulation.register_wire)
	grid_board.wire_unregistered.connect(simulation.unregister_wire)
	
	simulation.statistics_updated.connect(puzzle_ui.update_objectives_from_statistics)

	# Connexion de l'UI flottante de la grille vers le ModeManager
	grid_view.ui_rotate_requested.connect(mode_manager.on_rotate_requested)
	grid_view.ui_config_requested.connect(mode_manager.on_config_requested)


## Charge la configuration du niveau depuis le LevelContext
func _load_current_level() -> void:
	is_loading_level = true
	var level_def: LevelDefinition = null
	
	# Vérifie si le LevelContext existe en tant qu'autoload
	if Engine.has_singleton("LevelContext") or has_node("/root/LevelContext"):
		var context = get_node_or_null("/root/LevelContext")
		if context and "current_level" in context:
			level_def = context.current_level

	if not level_def:
		push_warning("[LevelManager] Aucun niveau actif trouvé dans le contexte. Chargement du niveau de secours par défaut.")
		level_def = fallback_default_level
		
	if not level_def:
		push_error("[LevelManager] Erreur critique : Aucun LevelDefinition valide trouvé pour initialiser le niveau !")
		is_loading_level = false
		return

	print("[LevelManager] Chargement du niveau : ", level_def.level_id)
	current_level = level_def
	level_validator.setup(current_level, simulation)

	# Configuration de la grille
	grid_board.grid_width = level_def.grid_width
	grid_board.grid_height = level_def.grid_height

	grid_view.custom_minimum_size = Vector2(level_def.grid_width * grid_view.cell_size, level_def.grid_height * grid_view.cell_size)
	grid_view.size = grid_view.custom_minimum_size
	grid_view.queue_redraw()

	# Transmission des limites de devices à l'UI
	puzzle_ui.initialize_device_limits(level_def.device_limits)
	puzzle_ui.initialize_objectives(level_def.objectives, level_def.emission_schedule)

	# Configuration de l'aide et du tutoriel pour ce niveau
	var has_tutorial = not current_level.tutorial_pages.is_empty()
	puzzle_ui.set_tutorial_button_visible(has_tutorial)
	
	if has_tutorial and current_level.show_tutorial_on_start:
		puzzle_ui.show_tutorial_pages(current_level.tutorial_pages)

	# Instanciation des devices initiaux définis dans la ressource du niveau
	for entry in level_def.initial_devices:
		if not entry.device_data:
			push_warning("[LevelManager] Entrée de device invalide dans le niveau.")
			continue
			
		var cell = entry.grid_position
		if not grid_board.is_cell_inside_grid(cell):
			push_error("[LevelManager] Cellule de device %s hors de la grille !" % cell)
			continue
			
		# Création de la machine logique
		var unique_id = "%s_%d_%d" % [entry.device_data.device_id_template, cell.x, cell.y]
		if not entry.device_id.is_empty():
			unique_id = entry.device_id
			
		var logic_device = entry.device_data.instantiate_device(unique_id)
		logic_device.grid_position = cell
		logic_device.rotation_quadrants = entry.rotation_quadrants
		
		if logic_device is NetworkTransmitter:
			logic_device.emission_schedule = level_def.emission_schedule

		# Application des états modifiable / supprimable
		if "is_movable" in logic_device:
			logic_device.is_movable = entry.is_movable
		if "is_deletable" in logic_device:
			logic_device.is_deletable = entry.is_deletable

		# Création de la machine visuelle
		if not entry.device_data.device_scene:
			push_error("[LevelManager] Aucune device_scene définie pour %s !" % unique_id)
			continue
			
		var view_node = entry.device_data.device_scene.instantiate() as NetworkDeviceView
		if not view_node:
			push_error("[LevelManager] La scène instanciée n'a pas le script NetworkDeviceView attaché !")
			continue

		view_node.global_position = grid_view.cell_to_world_center(cell)
		grid_view.add_child(view_node)
		
		# Liaison vue / logique
		view_node.setup(logic_device, entry.device_data.texture, float(grid_view.cell_size))
		grid_view.register_device_view(logic_device, view_node)

		if not view_node.port_interaction_requested.is_connected(mode_manager.on_port_interaction_requested):
			view_node.port_interaction_requested.connect(mode_manager.on_port_interaction_requested)

		# Enregistrement dans les systèmes
		var registered := grid_board.register_device(logic_device)

		if not registered:
			push_error("[LevelManager] Impossible d'enregistrer le device '%s' à la cellule %s." % [unique_id, cell])
			view_node.queue_free()
			continue

	simulation.set_initial_device_count(simulation.devices.size())
	simulation.recalculate_initial_stats()
	is_loading_level = false
	print("[LevelManager] Niveau initialisé avec succès.")


# ============================================
# ===== CALLBACKS : UI -> LOGIQUE DE JEU =====
# ============================================

func _on_simulation_requested() -> void:
	if not simulation.is_running:
		# --- LANCEMENT DE LA SIMULATION / REPRISE ---
		simulation.start()
		
		mode_manager.switch_mode_by_enum(ModeManager.GameMode.SIMULATION)
			
		puzzle_ui.set_simulation_session_active(true)
		puzzle_ui.set_simulation_button_state(true)  # Passe l'icône à "Pause"
		puzzle_ui.set_reset_button_enabled(true)     # Active le bouton Reset
		puzzle_ui.set_edit_button_enabled(false)
		puzzle_ui.set_wiring_button_enabled(false)
		puzzle_ui.set_delete_button_enabled(false)
		puzzle_ui.set_tutorial_button_enabled(false)
		puzzle_ui.set_hint_button_enabled(false)
		
	else:
		# --- MISE EN PAUSE ---
		simulation.stop()
		
		puzzle_ui.set_simulation_button_state(false) # Repasse l'icône à "Start"
		puzzle_ui.set_reset_button_enabled(true)     # Le Reset reste actif en pause


func _on_reset_requested() -> void:
	simulation.reset_runner()
	level_validator.reset()
		
	for wire in grid_board.get_wires():
		var wire_view = grid_view.get_wire_view(wire)
		if wire_view and wire_view.has_method("reset_state"):
			wire_view.reset_state()
	
	# Retour forcé en mode édition
	mode_manager.switch_mode_by_enum(ModeManager.GameMode.EDIT)
		
	# Remise à zéro de l'UI
	puzzle_ui.set_simulation_session_active(false)
	puzzle_ui.set_simulation_button_state(false)
	puzzle_ui.set_reset_button_enabled(false)
	puzzle_ui.set_edit_button_enabled(true)
	puzzle_ui.set_wiring_button_enabled(true)
	puzzle_ui.set_delete_button_enabled(true)
	puzzle_ui.set_tutorial_button_enabled(true)
	puzzle_ui.set_hint_button_enabled(true)
		
	print("[LevelManager] Simulation réinitialisée.")


func _on_restart_end_ui_requested() -> void:
	if level_end_ui:
		level_end_ui.hide_ui()
	_on_reset_requested()


func _on_next_level_requested() -> void:
	if current_level and current_level.next_level:
		if Engine.has_singleton("LevelContext") or has_node("/root/LevelContext"):
			var context = get_node_or_null("/root/LevelContext")
			if context and "current_level" in context:
				context.current_level = current_level.next_level
		
		get_tree().reload_current_scene()
	else:
		print("[LevelManager] C'était le dernier niveau du jeu !")
		_on_return_to_selection_requested()


func _on_return_to_selection_requested() -> void:
	get_tree().change_scene_to_file("res://ui/levelSelectionMenu/levelSelectionMenu.tscn")

func _on_validation_finished(result: Dictionary) -> void:
	print("[LevelManager] Résultat du niveau : ", result)
	if level_end_ui:
		level_end_ui.show_result(result, current_level.objectives)


func validate_current_level() -> Dictionary:
	return level_validator.validate()


func _on_wiring_requested() -> void:
	mode_manager.switch_mode_by_enum(ModeManager.GameMode.WIRING)

func _on_edit_requested() -> void:
	mode_manager.switch_mode_by_enum(ModeManager.GameMode.EDIT)

func _on_delete_requested() -> void:
	mode_manager.switch_mode_by_enum(ModeManager.GameMode.DELETE)

func _on_speed_requested() -> void:
	# Boucle cyclique sur les vitesses
	current_speed_index = (current_speed_index + 1) % speed_multipliers.size()
	var new_speed = speed_multipliers[current_speed_index]
	
	simulation.simulation_speed = new_speed
	
	puzzle_ui.set_speed_button_state(new_speed)


func _on_hint_requested() -> void:
	if not current_level or current_level.hints.is_empty():
		return
	
	if unlocked_hints_count < current_level.hints.size():
		unlocked_hints_count += 1
		
	print("[LevelManager] Affichage des indices. Débloqués : %d / %d" % [unlocked_hints_count, current_level.hints.size()])
	
	var active_hints = current_level.hints.slice(0, unlocked_hints_count)
	puzzle_ui.show_hint_pages(active_hints)

func _on_tutorial_requested() -> void:
	print("[LevelManager] Affichage du tutoriel.")
	if current_level and puzzle_ui:
		puzzle_ui.show_tutorial_pages(current_level.tutorial_pages)

func _on_device_placed_on_grid(device: NetworkDevice) -> void:
	simulation.register_device(device)
	
	if not is_loading_level:
		simulation.record_player_device_placed()
		puzzle_ui.consume_device_stock(device)


func _on_device_removed_from_grid(device: NetworkDevice) -> void:
	simulation.unregister_device(device)
	simulation.record_player_device_removed()
	if puzzle_ui:
		puzzle_ui.restore_device_stock(device)

func _on_mode_changed(new_mode: BaseMode) -> void:
	var is_wiring = (new_mode == mode_manager.wiring_mode)
	puzzle_ui.update_mode_buttons(new_mode, is_wiring)
		
	if new_mode != mode_manager.simulation_mode and simulation.is_running:
		simulation.stop()
		puzzle_ui.set_simulation_button_state(false)



# ==========================================
# ===== GESTION DES INPUTS GLOBAUX =========
# ==========================================

func _unhandled_input(event: InputEvent) -> void:
	# Si une fenêtre modale (Tuto ou Hint) est ouverte, on bloque les inputs du jeu
	if level_end_ui and level_end_ui.visible:
		if event is InputEventKey and event.pressed and not event.echo:
			if event.keycode == KEY_ESCAPE:
				level_end_ui.close_active_modals()
				get_viewport().set_input_as_handled()
		return # Bloque les autres raccourcis tant que l'écran de fin est visible
	
	if puzzle_ui and puzzle_ui.is_modal_open():
		if event is InputEventKey and event.pressed and not event.echo:
			if event.keycode == KEY_ESCAPE:
				puzzle_ui.close_active_modals()
				get_viewport().set_input_as_handled()
		return # Empêche l'exécution de tous les autres raccourcis en dessous

	# --- Tes inputs habituels (Escape pour le menu pause, raccourcis de jeu, etc.) ---
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_ESCAPE:
				if mode_manager.cancel_action():
					get_viewport().set_input_as_handled()
					return
					
				if pause_menu:
					pause_menu.open()
					get_viewport().set_input_as_handled()
				else:
					push_warning("[LevelManager] La référence 'pause_menu' n'est pas assignée !")

			KEY_W:
				if not simulation.has_started:
					_on_wiring_requested()
					get_viewport().set_input_as_handled()
					
			KEY_X:
				if not simulation.has_started:
					_on_delete_requested()
					get_viewport().set_input_as_handled()

			KEY_C:
				if not simulation.has_started:
					_on_edit_requested()
					get_viewport().set_input_as_handled()
					
			KEY_F:
				if simulation.has_started:
					_on_reset_requested()
					get_viewport().set_input_as_handled()

			KEY_R:
				_on_simulation_requested()
				get_viewport().set_input_as_handled()

			KEY_T:
				_on_speed_requested()
				get_viewport().set_input_as_handled()

			KEY_H:
				_on_hint_requested()
				get_viewport().set_input_as_handled()
			
			KEY_A:
				mode_manager.on_rotate_requested(-1)
				get_viewport().set_input_as_handled()
				
			KEY_E:
				mode_manager.on_rotate_requested(1)
				get_viewport().set_input_as_handled()
