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
	# Appel après le premier frame pour s'assurer que la taille du viewport est initialisée
	call_deferred("_setup_camera_framing")


# --- Setup de la caméra ---

func _setup_camera_framing() -> void:
	# Recalcul des dimensions à partir du Modèle et de la Vue
	var total_size := Vector2(grid_board.grid_width * grid_view.cell_size, grid_board.grid_height * grid_view.cell_size)
	var center := grid_view.global_position + (total_size * 0.5)
	
	camera.frame_rect(center, total_size, 2.0, grid_view.cell_size)
