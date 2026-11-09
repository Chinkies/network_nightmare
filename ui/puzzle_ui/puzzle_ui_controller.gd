class_name PuzzleUiController
extends Control

# --- SIGNAUX VERS LE LEVEL MANAGER ---

signal simulation_button_pressed
signal reset_button_pressed
signal wiring_button_pressed
signal edit_button_pressed
signal delete_button_pressed
signal speed_button_pressed
signal hint_button_pressed

## Liste des items disponibles
@export var available_devices: Array[NetworkDeviceData] = []

# Stocke les limites maximales et les quantités restantes { "device_id": nombre_restant }
var device_limits: Dictionary = {}
var remaining_stocks: Dictionary = {}

# --- RÉFÉRENCES AUX 7 BOUTONS ---
@onready var simulation_button: TextureButton = %SimulationButton
@onready var reset_button: TextureButton = %ResetButton
@onready var wiring_button: TextureButton = %WiringButton
@onready var edit_button: TextureButton = %EditButton
@onready var delete_button: TextureButton = %DeleteButton
@onready var speed_button: TextureButton = %SpeedButton
@onready var hint_button: TextureButton = %HintButton

# --- RÉFÉRENCE AU PANEL D'OBJECTIF ---
@export var objectives_panel: ObjectivesPanel

# --- TEXTURES POUR LE BOUTON WIRING (Normal vs Connecté) ---
@export_category("Textures Wiring Button")
@export var wiring_disable_textures: Dictionary = {} # { "normal": Texture, "hover": Texture, "pressed": Texture }
@export var wiring_enable_textures: Dictionary = {}

# --- TEXTURES POUR LE BOUTON SIMULATION (Start vs Pause) ---
@export_category("Textures Simulation Button")
@export var simulation_start_textures: Dictionary = {}
@export var simulation_pause_textures: Dictionary = {}

# --- TEXTURES POUR LE BOUTON SPEED (0.5 - 1 - 2) ---
@export_category("Textures Speed Button")
@export var speed_1_textures: Dictionary = {}
@export var speed_2_textures: Dictionary = {}
@export var speed_05_textures: Dictionary = {}

# ====================
# ===== METHODES =====
# ====================

func _ready() -> void:
	simulation_button.pressed.connect(func(): simulation_button_pressed.emit())
	reset_button.pressed.connect(func(): reset_button_pressed.emit())
	wiring_button.pressed.connect(func(): wiring_button_pressed.emit())
	edit_button.pressed.connect(func(): edit_button_pressed.emit())
	delete_button.pressed.connect(func(): delete_button_pressed.emit())
	speed_button.pressed.connect(func(): speed_button_pressed.emit())
	hint_button.pressed.connect(func(): hint_button_pressed.emit())

## Initialise les quotas du niveau
func initialize_device_limits(limits: Dictionary) -> void:
	device_limits = limits.duplicate()
	remaining_stocks.clear()
	
	_setup_menu_with_resources()


## Consomme 1 exemplaire du stock lors du placement
func consume_device_stock(device: NetworkDevice) -> void:
	var dtype = device.device_type
	if remaining_stocks.has(dtype):
		remaining_stocks[dtype] = max(0, remaining_stocks[dtype] - 1)
		_update_menu_display()

## Restaure 1 exemplaire du stock lors de la suppression
func restore_device_stock(device: NetworkDevice) -> void:
	var dtype = device.device_type
	if remaining_stocks.has(dtype):
		var max_limit = device_limits.get(dtype, 99)
		remaining_stocks[dtype] = min(max_limit, remaining_stocks[dtype] + 1)
		_update_menu_display()

func _update_menu_display() -> void:
	if has_node("%DeviceSelectionMenu"):
		%DeviceSelectionMenu.update_stocks(remaining_stocks)


## Création du menu des appareils disponibles (uniquement ceux autorisés par le niveau)
func _setup_menu_with_resources() -> void:
	if has_node("%DeviceSelectionMenu"):
		var placeable_devices: Array[NetworkDeviceData] = []
		
		for device_data in available_devices:
			if device_data == null:
				continue
				
			# On exclut les éléments fixes du niveau
			if device_data.device_type == NetworkDevice.Type.TRANSMITTER or device_data.device_type == NetworkDevice.Type.RECEIVER:
				continue
				
			var dtype = device_data.device_type
			
			# On récupère la limite définie dans le .tres (par défaut -1 si non défini)
			var stock_limit = device_limits.get(dtype, -1)
			
			if stock_limit > 0:
				placeable_devices.append(device_data)
				remaining_stocks[dtype] = stock_limit
			else:
				print("[UI] Device %s exclu du niveau (quota à 0 ou non défini)." % device_data.device_name)
		
		%DeviceSelectionMenu.setup_menu(placeable_devices, remaining_stocks)
		print("[UI] Menu peuplé avec %d devices plaçables." % placeable_devices.size())
	else:
		push_warning("[UI] Impossible de trouver le nœud UIMenuDeviceSelection")


# ==========================================
# ===== AJOUT : GESTION DES OBJECTIFS ======
# ==========================================

## Initialise le panneau d'objectifs avec la liste des objectifs du niveau
func initialize_objectives(objectives: Array[LevelObjective], emission_schedule: Array = []) -> void:
	if objectives_panel:
		objectives_panel.setup_objectives(objectives, emission_schedule.size())


## Transmet les métriques de la simulation en direct au panneau (Bonus)
func update_objectives_from_statistics(stats: Dictionary) -> void:
	if objectives_panel:
		objectives_panel.update_from_statistics(stats)


# ==========================================
# ===== METHODES DE MISE À JOUR VISUELLE ===
# ==========================================

## Met en valeur le bouton du mode actif et change l'icône de Wiring si nécessaire
func update_mode_buttons(active_mode: BaseMode, is_wiring_connected: bool) -> void:

	edit_button.set_pressed_no_signal(false)
	wiring_button.set_pressed_no_signal(false)
	delete_button.set_pressed_no_signal(false)

	edit_button.mouse_filter = Control.MOUSE_FILTER_STOP
	wiring_button.mouse_filter = Control.MOUSE_FILTER_STOP
	delete_button.mouse_filter = Control.MOUSE_FILTER_STOP

	if active_mode is EditMode:
		edit_button.set_pressed_no_signal(true)
		edit_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	elif active_mode is WiringMode:
		wiring_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		wiring_button.set_pressed_no_signal(true)
	elif active_mode is DeleteMode:
		delete_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		delete_button.set_pressed_no_signal(true)

	if is_wiring_connected:
		_apply_textures(wiring_button, wiring_enable_textures)
	else:
		_apply_textures(wiring_button, wiring_disable_textures)


## Change l'apparence du bouton Simulation (Start vs Pause)
func set_simulation_button_state(is_running: bool) -> void:
	if is_running:
		_apply_textures(simulation_button, simulation_pause_textures)
	else:
		_apply_textures(simulation_button, simulation_start_textures)

func set_speed_button_state(speed: float) -> void:
	match speed:
		0.5:
			_apply_textures(speed_button, speed_05_textures)
		1.:
			_apply_textures(speed_button, speed_1_textures)
		2.:
			_apply_textures(speed_button, speed_2_textures)

## Active ou désactive l'état de session active du panneau d'objectifs
func set_simulation_session_active(active: bool) -> void:
	if objectives_panel:
		objectives_panel.set_session_active(active)

## Active ou désactive le bouton Reset
func set_reset_button_enabled(is_enabled: bool) -> void:
	reset_button.disabled = not is_enabled

func set_edit_button_enabled(is_enabled: bool) -> void:
	edit_button.disabled = not is_enabled

func set_wiring_button_enabled(is_enabled: bool) -> void:
	wiring_button.disabled = not is_enabled

func set_delete_button_enabled(is_enabled: bool) -> void:
	delete_button.disabled = not is_enabled

## Utilitaire pour appliquer un dictionnaire de textures (normal, hover, pressed) à un TextureButton
func _apply_textures(btn: TextureButton, textures: Dictionary) -> void:
	if textures.has("normal") and textures["normal"]:
		btn.texture_normal = textures["normal"]
	if textures.has("hover") and textures["hover"]:
		btn.texture_hover = textures["hover"]
	if textures.has("pressed") and textures["pressed"]:
		btn.texture_pressed = textures["pressed"]
