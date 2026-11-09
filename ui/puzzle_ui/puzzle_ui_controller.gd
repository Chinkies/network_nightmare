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
signal tutorial_button_pressed

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
@onready var tutorial_button: Button = %TutorialButton

# --- RÉFÉRENCE AU PANEL OBJECTIFS ---
@export_category("Objectifs")
@export var objectives_panel: ObjectivesPanel

@export_category("Hint & Tutorial")
@export var tutorial_window: Control
@export var tutorial_title_label: Label
@export var tutorial_content_label: RichTextLabel
@export var tutorial_texture: TextureRect
@export var tutorial_page_counter: Label
@export var tutorial_prev_button: Button
@export var tutorial_next_button: Button
@export var tutorial_close_button: Button

@export var hint_window: Control
@export var hint_title_label: Label
@export var hint_content_label: RichTextLabel
@export var hint_page_counter: Label
@export var hint_prev_button: Button
@export var hint_next_button: Button
@export var hint_close_button: Button

var current_tutorial_pages: Array[TutorialPage] = []
var current_tutorial_index: int = 0

var current_hint_pages: Array[HintPage] = []
var current_hint_index: int = 0

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
	tutorial_button.pressed.connect(func(): tutorial_button_pressed.emit())

	tutorial_prev_button.pressed.connect(_on_tutorial_prev_pressed)
	tutorial_next_button.pressed.connect(_on_tutorial_next_pressed)
	hint_prev_button.pressed.connect(_on_hint_prev_pressed)
	hint_next_button.pressed.connect(_on_hint_next_pressed)
	tutorial_close_button.pressed.connect(_on_tutorial_close_pressed)
	hint_close_button.pressed.connect(_on_hint_close_pressed)

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

func set_tutorial_button_enabled(is_enabled: bool) -> void:
	tutorial_button.disabled = not is_enabled

func set_hint_button_enabled(is_enabled: bool) -> void:
	hint_button.disabled = not is_enabled

## Utilitaire pour appliquer un dictionnaire de textures (normal, hover, pressed) à un TextureButton
func _apply_textures(btn: TextureButton, textures: Dictionary) -> void:
	if textures.has("normal") and textures["normal"]:
		btn.texture_normal = textures["normal"]
	if textures.has("hover") and textures["hover"]:
		btn.texture_hover = textures["hover"]
	if textures.has("pressed") and textures["pressed"]:
		btn.texture_pressed = textures["pressed"]

# --- GESTION DU TUTORIEL ---

func show_tutorial_pages(pages: Array[TutorialPage]) -> void:
	if pages.is_empty():
		return
	current_tutorial_pages = pages
	current_tutorial_index = 0
	_update_tutorial_display()
	if tutorial_window:
		tutorial_window.visible = true

func _update_tutorial_display() -> void:
	if current_tutorial_pages.is_empty():
		return
	var page = current_tutorial_pages[current_tutorial_index]
	
	if tutorial_title_label:
		tutorial_title_label.text = page.title
	if tutorial_content_label:
		tutorial_content_label.text = page.text # RichTextLabel supporte nativement le BBCode
		
	if tutorial_texture:
		if page.image:
			tutorial_texture.texture = page.image
			tutorial_texture.visible = true
		else:
			tutorial_texture.visible = false
			
	if tutorial_page_counter:
		tutorial_page_counter.text = "Page %d / %d" % [current_tutorial_index + 1, current_tutorial_pages.size()]
		
	if tutorial_prev_button:
		tutorial_prev_button.disabled = (current_tutorial_index == 0)
	if tutorial_next_button:
		tutorial_next_button.disabled = (current_tutorial_index >= current_tutorial_pages.size() - 1)

func _on_tutorial_prev_pressed() -> void:
	if current_tutorial_index > 0:
		current_tutorial_index -= 1
		_update_tutorial_display()

func _on_tutorial_next_pressed() -> void:
	if current_tutorial_index < current_tutorial_pages.size() - 1:
		current_tutorial_index += 1
		_update_tutorial_display()

func _on_tutorial_close_pressed() -> void:
	if tutorial_window:
		tutorial_window.visible = false


# --- GESTION DES INDICES (HINTS) ---

func show_hint_pages(hints: Array[HintPage]) -> void:
	if hints.is_empty():
		return
	current_hint_pages = hints
	current_hint_index = hints.size() - 1
	_update_hint_display()
	if hint_window:
		hint_window.visible = true

func _update_hint_display() -> void:
	if current_hint_pages.is_empty():
		return
	var hint_page = current_hint_pages[current_hint_index]
	
	if hint_title_label:
		hint_title_label.text = hint_page.title
	if hint_content_label:
		hint_content_label.text = hint_page.text
		
	if hint_page_counter:
		hint_page_counter.text = "Indice %d / %d" % [current_hint_index + 1, current_hint_pages.size()]
		
	if hint_prev_button:
		hint_prev_button.disabled = (current_hint_index == 0)
	if hint_next_button:
		hint_next_button.disabled = (current_hint_index >= current_hint_pages.size() - 1)


func _on_hint_prev_pressed() -> void:
	if current_hint_index > 0:
		current_hint_index -= 1
		_update_hint_display()

func _on_hint_next_pressed() -> void:
	if current_hint_index < current_hint_pages.size() - 1:
		current_hint_index += 1
		_update_hint_display()

func set_tutorial_button_visible(v: bool) -> void:
	if tutorial_button:
		tutorial_button.visible = v

func _on_hint_close_pressed() -> void:
	if hint_window:
		hint_window.visible = false


## Renvoie true si l'une des fenêtres Tuto ou Hint est visible
func is_modal_open() -> bool:
	return (tutorial_window and tutorial_window.visible) or (hint_window and hint_window.visible)

## Ferme toutes les fenêtres modales ouvertes
func close_active_modals() -> void:
	if tutorial_window:
		tutorial_window.visible = false
	if hint_window:
		hint_window.visible = false