class_name LevelManager
extends Node

# =====================
# ===== ATTRIBUTS =====
# =====================

@export_category("Registres, Grid & Simulation")
@export var mode_manager: ModeManager
@export var simulation: SimulationRunner
@export var grid_board: GridBoard
@export var grid_view: GridView
@export var puzzle_ui: PuzzleUiController

## Ressource du transmitter de test à placer au lancement (pour le dev)
@export_category("Test & Debug - Mock Level Setup")
@export var debug_transmitter_data: NetworkTransmitterData
@export var debug_transmitter_cell: Vector2i = Vector2i(0, 2)

# Vitesses disponibles pour la boucle cyclique
var speed_multipliers: Array[float] = [1.0, 2.0, 0.5]
var current_speed_index: int = 0

# ====================
# ===== METHODES =====
# ====================

func _ready() -> void:
	_connect_signals()
	if puzzle_ui:
		puzzle_ui.set_reset_button_enabled(false)
		puzzle_ui.set_simulation_button_state(false)

	call_deferred("_debug_spawn_transmitter")


func _connect_signals() -> void:
	# Connexion des signaux provenant de l'UI
	if puzzle_ui:
		puzzle_ui.simulation_button_pressed.connect(_on_simulation_requested)
		puzzle_ui.reset_button_pressed.connect(_on_reset_requested)
		puzzle_ui.wiring_button_pressed.connect(_on_wiring_requested)
		puzzle_ui.edit_button_pressed.connect(_on_edit_requested)
		puzzle_ui.delete_button_pressed.connect(_on_delete_requested)
		puzzle_ui.speed_button_pressed.connect(_on_speed_requested)
		puzzle_ui.hint_button_pressed.connect(_on_hint_requested)

	if mode_manager:
		mode_manager.mode_changed.connect(_on_mode_changed)

# ============================================
# ===== CALLBACKS : UI -> LOGIQUE DE JEU =====
# ============================================

func _on_simulation_requested() -> void:
	if not simulation:
		return
		
	if not simulation.is_running:
		# --- LANCEMENT DE LA SIMULATION / REPRISE ---
		simulation.start()
		if mode_manager:
			mode_manager.switch_mode_by_enum(ModeManager.GameMode.SIMULATION)
			
		if puzzle_ui:
			puzzle_ui.set_simulation_button_state(true)  # Passe l'icône à "Pause"
			puzzle_ui.set_reset_button_enabled(true)     # Active le bouton Reset
			puzzle_ui.set_edit_button_enabled(false)
			puzzle_ui.set_wiring_button_enabled(false)
			puzzle_ui.set_delete_button_enabled(false)
			
		print("[LevelManager] Simulation lancée.")
	else:
		# --- MISE EN PAUSE ---
		simulation.stop()
		
		if puzzle_ui:
			puzzle_ui.set_simulation_button_state(false) # Repasse l'icône à "Start"
			puzzle_ui.set_reset_button_enabled(true)     # Le Reset reste actif en pause
			
		print("[LevelManager] Simulation mise en pause.")

func _on_reset_requested() -> void:
	if simulation:
		simulation.reset_runner()
		
	current_speed_index = 0
	
	# Retour forcé en mode édition
	if mode_manager:
		mode_manager.switch_mode_by_enum(ModeManager.GameMode.EDIT)
		
	# Remise à zéro de l'UI
	if puzzle_ui:
		puzzle_ui.set_simulation_button_state(false)
		puzzle_ui.set_reset_button_enabled(false)
		puzzle_ui.set_edit_button_enabled(true)
		puzzle_ui.set_wiring_button_enabled(true)
		puzzle_ui.set_delete_button_enabled(true)
		
	print("[LevelManager] Simulation réinitialisée.")

func _on_wiring_requested() -> void:
	if mode_manager:
		mode_manager.switch_mode_by_enum(ModeManager.GameMode.WIRING)

func _on_edit_requested() -> void:
	if mode_manager:
		mode_manager.switch_mode_by_enum(ModeManager.GameMode.EDIT)

func _on_delete_requested() -> void:
	if mode_manager:
		mode_manager.switch_mode_by_enum(ModeManager.GameMode.DELETE)

func _on_speed_requested() -> void:
	# Boucle cyclique sur les vitesses
	current_speed_index = (current_speed_index + 1) % speed_multipliers.size()
	var new_speed = speed_multipliers[current_speed_index]
	
	if simulation:
		simulation.simulation_speed = new_speed
	
	puzzle_ui.set_speed_button_state(new_speed)
	print("[LevelManager] Vitesse de simulation changée à : %.1fx" % new_speed)

func _on_hint_requested() -> void:
	print("[LevelManager] Demande d'indice reçue.")

# ==========================================
# ===== CALLBACKS : MODE -> UI & JEU =======
# ==========================================

func _on_mode_changed(new_mode: BaseMode) -> void:
	print("[LevelManager] Changement de mode détecté : ", new_mode.name)
	
	# On compare directement avec le nœud simulation_mode stocké dans le mode_manager si besoin, 
	# ou on vérifie si le mode est de type SimulationMode
	var is_wiring = (new_mode == mode_manager.wiring_mode)
	if puzzle_ui:
		puzzle_ui.update_mode_buttons(new_mode, is_wiring)
		
	if simulation and new_mode != mode_manager.simulation_mode and simulation.is_running:
		simulation.stop()
		if puzzle_ui:
			puzzle_ui.set_simulation_button_state(false)

# ==========================================
# ===== GESTION DES INPUTS GLOBAUX =========
# ==========================================

# Pour le moment j'y ai pas touché c'est la vielle gestion de l'échap

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_ESCAPE:
				# 1. On demande d'abord au ModeManager s'il a une action en cours à annuler (ex: quitter le mode wiring)
				if mode_manager and mode_manager.cancel_action():
					get_viewport().set_input_as_handled()
					return
					
				# 2. Plus tard : Fermer les fenêtres de l'UI
				
				# 3. Sinon : Menu Pause
				print("[LevelManager] Rien à annuler : Ouverture du menu de Pause (TODO)")
				get_viewport().set_input_as_handled()

			KEY_W:
				if not simulation.has_started:
					_on_wiring_requested()
					get_viewport().set_input_as_handled()
					
			KEY_X:
				if not simulation.has_started:
					_on_delete_requested()
					get_viewport().set_input_as_handled()

			KEY_E:
				if not simulation.has_started:
					_on_edit_requested()
					get_viewport().set_input_as_handled()
					
			KEY_R:
				if simulation.has_started:
					_on_reset_requested()
					get_viewport().set_input_as_handled()

			KEY_F:
				_on_simulation_requested()
				get_viewport().set_input_as_handled()

			KEY_A:
				_on_speed_requested()
				get_viewport().set_input_as_handled()

			KEY_H:
				_on_hint_requested()
				get_viewport().set_input_as_handled()


## Fonction debug pour placer le transmitter
func _debug_spawn_transmitter() -> void:
	if not debug_transmitter_data:
		return
		
	if not grid_board or not grid_view or not simulation:
		push_error("[LevelManager] Références manquantes (grid_board, grid_view ou simulation) pour le spawn de debug !")
		return
		
	var cell = debug_transmitter_cell
	
	if not grid_board.is_cell_inside_grid(cell):
		push_error("[LevelManager] Cellule de debug %s hors de la grille !" % cell)
		return
		
	if grid_board.is_cell_occupied(cell):
		print("[LevelManager] Cellule %s déjà occupée, spawn de debug ignoré." % cell)
		return

	# 1. Création de la machine logique
	var unique_id = "%s_%d_%d" % [debug_transmitter_data.device_id_template, cell.x, cell.y]
	var logic_device = debug_transmitter_data.instantiate_device(unique_id)
	logic_device.grid_position = cell

	# 2. Création de la machine visuelle
	if not debug_transmitter_data.device_scene:
		push_error("[LevelManager] Aucune device_scene définie dans la ressource de debug !")
		return
		
	var view_node = debug_transmitter_data.device_scene.instantiate() as NetworkDeviceView
	if not view_node:
		push_error("[LevelManager] La scène de debug n'a pas le script NetworkDeviceView attaché !")
		return

	view_node.global_position = grid_view.cell_to_world_center(cell)
	grid_view.add_child(view_node)
	
	# 3. Liaison vue / logique
	view_node.setup(logic_device, debug_transmitter_data.texture, float(grid_view.cell_size))

	# === CORRECTION : Enregistrement de la vue dans le GridView pour que les ports s'affichent ===
	grid_view.register_device_view(logic_device, view_node)

	if not view_node.port_interaction_requested.is_connected(mode_manager.on_port_interaction_requested):
		view_node.port_interaction_requested.connect(mode_manager.on_port_interaction_requested)

	# 4. Enregistrements croisés via le GridBoard et le SimulationRunner
	grid_board.register_device(logic_device)
	simulation.register_device(logic_device)
