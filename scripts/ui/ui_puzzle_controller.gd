class_name UIPuzzleController
extends Control

## Signaux émis vers le chef d'orchestre (Main ou LevelManager)
signal simulation_started
signal simulation_stopped
signal hint_requested


## Références aux composants enfants
@onready var start_button: Button = %StartButton
@onready var stop_button: Button = %StopButton
@onready var hint_button: Button = %HintButton


# ====================
# ===== METHODES =====
# ====================

func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)
	stop_button.pressed.connect(_on_stop_pressed)
	hint_button.pressed.connect(_on_hint_pressed)


func _on_start_pressed() -> void:
	simulation_started.emit()


func _on_stop_pressed() -> void:
	simulation_stopped.emit()


func _on_hint_pressed() -> void:
	hint_requested.emit()


## Permet à la simulation ou au puzzle de forcer l'état graphique de l'UI
## (ex: échec d'un paquet, condition de victoire, touche Espace pressée)
func set_simulation_running(is_running: bool) -> void:
	if is_running:
		start_button.button_pressed = true
	else:
		stop_button.button_pressed = true
