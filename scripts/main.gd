class_name Main
extends Node2D

# =====================
# ===== ATTRIBUTS =====
# =====================

@onready var camera: PanZoomCamera = $Camera2D
@onready var grid_manager: GridManager = %GridManager
@onready var ui_puzzle: UIPuzzleController = %UiPuzzle
@onready var simulation: NetworkSimulation = %NetworkSimulation


# ====================
# ===== METHODES =====
# ====================

func _ready() -> void:
	_connect_ui_signals()
	
	# Appel après le premier frame pour s'assurer que la taille du viewport est initialisée
	call_deferred("_setup_camera_framing")


# --- Fonctions de gestion des signaux ---

func _connect_ui_signals() -> void:
	ui_puzzle.simulation_started.connect(_on_simulation_started)
	ui_puzzle.simulation_stopped.connect(_on_simulation_stopped)
	ui_puzzle.hint_requested.connect(_on_hint_requested)


func _on_simulation_started() -> void:
	simulation.start()
	print("[Simulation] Démarrée.")


func _on_simulation_stopped() -> void:
	simulation.stop()
	print("[Simulation] Arrêtée.")


func _on_hint_requested() -> void:
	print("[UI] Demande d'indice reçue.")
	# TODO: Afficher le dialogue ou la popup d'indice


# --- Setup de la caméra ---

func _setup_camera_framing() -> void:
	var center := grid_manager.get_grid_center_world()
	var size := grid_manager.get_grid_pixel_size()
	
	# Marge de 2 cellules de chaque côté pour le décor
	camera.frame_rect(center, size, 2.0, grid_manager.cell_size)
