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
	var mock_device_data: Array[NetworkDeviceData] = []

	#SWITCH
	var switch_data = NetworkDeviceData.new();
	switch_data.device_id_template = "switch_01"
	switch_data.device_name = "Switch Réseau"
	switch_data.device_type = NetworkDevice.Type.SWITCH

	var switch_texture = PlaceholderTexture2D.new()
	switch_texture.size = Vector2(100, 100)
	switch_data.icon = switch_texture

	mock_device_data.append(switch_data)

	var receiver_data = NetworkDeviceData.new()
	receiver_data.device_id_template = "receiver_01"
	receiver_data.device_name = "Receiver"
	receiver_data.device_type = NetworkDevice.Type.RECEIVER

	var receiver_texture = PlaceholderTexture2D.new()
	receiver_texture.size = Vector2(100, 100)
	receiver_data.icon = receiver_texture

	mock_device_data.append(receiver_data)

	var extra_types = [
		NetworkDevice.Type.EMITTER,
		NetworkDevice.Type.SWITCH,
		NetworkDevice.Type.RECEIVER,
		NetworkDevice.Type.GENERIC
	]

	for i in range(8):

		var device_data = NetworkDeviceData.new()
		device_data.device_id_template = "device_%02d" % (i + 3)
		device_data.device_name = "Appareil %02d" % (i + 3)
		device_data.device_type = extra_types[i % extra_types.size()]

		var tex = PlaceholderTexture2D.new()
		tex.size = Vector2(100, 100)
		device_data.icon = tex
		
		mock_device_data.append(device_data)
	
	if has_node("%UIMenuDeviceSelection"):
		%UIMenuDeviceSelection.setup_menu(mock_device_data)
		print("[Test] Menu peuplé avec succès avec %d devices." % mock_device_data.size())
	else:
		push_warning("[Test] Impossible de trouver le nœud UIMenuDeviceSelection via %UIMenuDeviceSelection")
