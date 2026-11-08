class_name DeviceEditUi
extends Control


# --- Signaux ---

signal rotate_left_requested
signal rotate_right_requested
signal config_requested


# =====================
# ===== ATTRIBUTS =====
# =====================

# --- Boutons --- 
@onready var buttons_container: HBoxContainer = $HBoxContainer
@onready var btn_rotate_left: TextureButton = $HBoxContainer/BtnRotateLeft
@onready var btn_config: TextureButton = $HBoxContainer/BtnConfig
@onready var btn_rotate_right: TextureButton = $HBoxContainer/BtnRotateRight


# =====================
# ===== METHODES  =====
# =====================

func _ready() -> void:
	# Connexion des signaux natifs
	btn_rotate_left.pressed.connect(func(): rotate_left_requested.emit())
	btn_rotate_right.pressed.connect(func(): rotate_right_requested.emit())
	btn_config.pressed.connect(func(): config_requested.emit())


## Dimensionne l'UI dynamiquement selon la taille d'une case
func setup(cell_size: float) -> void:
	var btn_size = cell_size * 0.40
	var custom_size = Vector2(btn_size, btn_size)
	
	btn_rotate_left.custom_minimum_size = custom_size
	btn_rotate_right.custom_minimum_size = custom_size
	btn_config.custom_minimum_size = custom_size
	
	# On centre le conteneur
	self.size = Vector2.ZERO
	buttons_container.reset_size()
	buttons_container.position = Vector2(-buttons_container.size.x / 2.0, -buttons_container.size.y / 2.0)


## Met à jour l'apparence des boutons en fonction des capacités de l'appareil
func update_state(can_rotate: bool, can_config: bool) -> void:
	btn_rotate_left.disabled = not can_rotate
	btn_rotate_right.disabled = not can_rotate
	btn_config.disabled = not can_config
