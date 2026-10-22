class_name Main
extends Node2D

# =====================
# ===== ATTRIBUTS =====
# =====================

@onready var camera: PanZoomCamera = $Camera2D
@onready var grid_view: GridView = %GridView
@onready var grid_board: GridBoard = %GridBoard
@onready var puzzle_ui: PuzzleUiController = %PuzzleUi
@onready var simulation: SimulationRunner = %SimulationRunner


# ====================
# ===== METHODES =====
# ====================

func _ready() -> void:
	_connect_ui_signals()
	
	# Appel après le premier frame pour s'assurer que la taille du viewport est initialisée
	call_deferred("_setup_camera_framing")


# --- Fonctions de gestion des signaux ---

func _connect_ui_signals() -> void:
	puzzle_ui.simulation_started.connect(_on_simulation_started)
	puzzle_ui.simulation_stopped.connect(_on_simulation_stopped)
	puzzle_ui.hint_requested.connect(_on_hint_requested)


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
	# Recalcul des dimensions à partir du Modèle et de la Vue
	var total_size := Vector2(grid_board.grid_width * grid_view.cell_size, grid_board.grid_height * grid_view.cell_size)
	var center := grid_view.global_position + (total_size * 0.5)
	
	camera.frame_rect(center, total_size, 2.0, grid_view.cell_size)
