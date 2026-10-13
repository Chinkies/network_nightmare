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

	### === TEMPORAIRE POUR TESTER LES MENUS ===
	call_deferred("_load_mock_devices_for_testing")


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

## === TEMPORAIRE POUR TESTER LES MENUS ===
func _load_mock_devices_for_testing() -> void:
	var mock_devices: Array[NetworkDevice] = []

	var switch_dev = NetworkDevice.new("switch_01", 5, 2.0)
	switch_dev.device_type = NetworkDevice.Type.SWITCH

	var switch_texture = PlaceholderTexture2D.new()
	switch_texture.size = Vector2(64, 64)
	switch_dev.icon = switch_texture

	mock_devices.append(switch_dev)

	var receiver_dev = NetworkDevice.new("receiver_01", 5, 2.0)
	receiver_dev.device_type = NetworkDevice.Type.RECEIVER

	var receiver_texture = PlaceholderTexture2D.new()
	receiver_texture.size = Vector2(64, 64)
	receiver_dev.icon = receiver_texture

	mock_devices.append(receiver_dev)
	
	if has_node("%UIMenuDeviceSelection"):
		%UIMenuDeviceSelection.setup_menu(mock_devices)
		print("[Test] Menu peuplé avec succès avec %d devices." % mock_devices.size())
	else:
		push_warning("[Test] Impossible de trouver le nœud UIMenuDeviceSelection via %UIMenuDeviceSelection")
