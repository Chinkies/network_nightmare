class_name LevelManager
extends Node

# =====================
# ===== ATTRIBUTS =====
# =====================

@export var mode_manager: ModeManager
@export var puzzle_ui: PuzzleUiController
@export var simulation: SimulationRunner

# Références directes aux modes (pour que le LevelManager sache quoi demander au ModeManager)
@export var edit_mode: EditMode
@export var delete_mode: DeleteMode
@export var wiring_mode: WiringMode
@export var simulation_mode: SimulationMode

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
		if mode_manager and simulation_mode:
			mode_manager.switch_mode(simulation_mode)
			
		if puzzle_ui:
			puzzle_ui.set_simulation_button_state(true)  # Passe l'icône à "Pause"
			puzzle_ui.set_reset_button_enabled(true)     # Active le bouton Reset
			
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
	if mode_manager and edit_mode:
		mode_manager.switch_mode(edit_mode)
		
	# Remise à zéro de l'UI
	if puzzle_ui:
		puzzle_ui.set_simulation_button_state(false)
		puzzle_ui.set_reset_button_enabled(false)
		
	print("[LevelManager] Simulation réinitialisée.")

func _on_wiring_requested() -> void:
	if mode_manager and wiring_mode:
		mode_manager.switch_mode(wiring_mode)

func _on_edit_requested() -> void:
	if mode_manager and edit_mode:
		mode_manager.switch_mode(edit_mode)

func _on_delete_requested() -> void:
	if mode_manager and delete_mode:
		mode_manager.switch_mode(delete_mode)

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
	
	var is_wiring = (new_mode == wiring_mode)
	if puzzle_ui:
		puzzle_ui.update_mode_buttons(new_mode, is_wiring)
		
	# Si on quitte le mode simulation par un autre biais, on stoppe le runner et met l'UI à jour
	if simulation and new_mode != simulation_mode and simulation.is_running:
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
				_on_wiring_requested()
				get_viewport().set_input_as_handled()
					
			KEY_X:
				_on_delete_requested()
				get_viewport().set_input_as_handled()

			KEY_E:
				_on_edit_requested()
				get_viewport().set_input_as_handled()
					
			KEY_R:
				if simulation.has_started:
					_on_reset_requested()
					get_viewport().set_input_as_handled()

			KEY_S:
				_on_simulation_requested()
				get_viewport().set_input_as_handled()

			KEY_Z:
				_on_speed_requested()
				get_viewport().set_input_as_handled()

			KEY_H:
				_on_hint_requested()
				get_viewport().set_input_as_handled()
