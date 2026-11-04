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
@export var wiring_mode: WiringMode
@export var simulation_mode: SimulationMode

# ====================
# ===== METHODES =====
# ====================

func _ready() -> void:
	_connect_signals()

func _connect_signals() -> void:
	# Connexion des signaux provenant de l'UI
	if puzzle_ui:
		if puzzle_ui.has_signal("edit_button_pressed"):
			puzzle_ui.edit_button_pressed.connect(_on_edit_button_requested)
		if puzzle_ui.has_signal("wiring_button_pressed"):
			puzzle_ui.wiring_button_pressed.connect(_on_wiring_button_requested)
		
		if puzzle_ui.has_signal("simulation_started"):
			puzzle_ui.simulation_started.connect(_on_simulation_start_requested)
		if puzzle_ui.has_signal("simulation_stopped"):
			puzzle_ui.simulation_stopped.connect(_on_simulation_stop_requested)
		if puzzle_ui.has_signal("simulation_reset"):
			puzzle_ui.simulation_reset.connect(_on_simulation_reset_requested)

	if mode_manager:
		mode_manager.mode_changed.connect(_on_mode_changed)

# ============================================
# ===== CALLBACKS : UI -> LOGIQUE DE JEU =====
# ============================================

func _on_edit_button_requested() -> void:
	if mode_manager and edit_mode:
		mode_manager.switch_mode(edit_mode)

func _on_wiring_button_requested() -> void:
	if mode_manager and wiring_mode:
		mode_manager.switch_mode(wiring_mode)

func _on_simulation_start_requested() -> void:
	if mode_manager and simulation_mode:
		mode_manager.switch_mode(simulation_mode)
	if simulation:
		simulation.start()
	print("[LevelManager] Simulation démarrée.")

func _on_simulation_stop_requested() -> void:
	if simulation:
		simulation.stop()
	print("[LevelManager] Simulation mise en pause.")

func _on_simulation_reset_requested() -> void:
	# 1. On stoppe la simulation et on nettoie ses registres
	if simulation:
		simulation.stop()
		simulation.devices.clear()
		simulation.wires.clear()
		simulation.ephemeral_packets.clear()
		
	# 2. On nettoie la grille (via GridBoard / GridManager si besoin)
	# ...
	
	# 3. On repasse par défaut en mode édition
	if mode_manager and edit_mode:
		mode_manager.switch_mode(edit_mode)
		
	print("[LevelManager] Simulation réinitialisée, retour en mode édition.")

# ==========================================
# ===== CALLBACKS : MODE -> UI & JEU =======
# ==========================================

func _on_mode_changed(new_mode: BaseMode) -> void:
	print("[LevelManager] Changement de mode détecté : ", new_mode.name)
	
	# Mise à jours des boutons de l'UI
	if puzzle_ui and puzzle_ui.has_method("update_mode_button"):
		puzzle_ui.update_mode_button(new_mode)
		
	# Si on quitte le mode simulation par un autre moyen, on s'assure que le runner s'arrête
	if simulation and new_mode != simulation_mode:
		simulation.stop()

# ==========================================
# ===== GESTION DES INPUTS GLOBAUX =========
# ==========================================

# Pour le moment j'y ai pas touché c'est la vielle gestion de l'échap

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			# 1. On demande d'abord au ModeManager s'il a une action en cours à annuler (ex: quitter le mode wiring)
			if mode_manager and mode_manager.cancel_action():
				get_viewport().set_input_as_handled()
				return
				
			# 2. Plus tard : Fermer les fenêtres de l'UI
			
			# 3. Sinon : Menu Pause
			print("[LevelManager] Rien à annuler : Ouverture du menu de Pause (TODO)")
			get_viewport().set_input_as_handled()
