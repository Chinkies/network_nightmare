class_name PanZoomCamera
extends Camera2D

# =====================
# ===== ATTRIBUTS =====
# =====================

# --- Paramètres de déplacement (Pan) ---
@export var move_speed: float = 600.0 # Pixels par seconde

# --- Paramètres de zoom ---
@export var min_zoom: float = 1.0
@export var max_zoom: float = 3.0
@export var zoom_range_factor: float = 3.0
@export var zoom_factor: float = 1.15
@export var zoom_duration: float = 0.15


var _target_zoom: Vector2 = Vector2.ONE
var _zoom_tween: Tween

# ====================
# ===== METHODES =====
# ====================

func _ready() -> void:
	_target_zoom = zoom


func _process(delta: float) -> void:
	_handle_movement(delta)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.is_pressed():
			_adjust_zoom(zoom_factor)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.is_pressed():
			_adjust_zoom(1.0 / zoom_factor)


## Déplacement au clavier ZQSD
func _handle_movement(delta: float) -> void:
	var input_vector: Vector2 = Input.get_vector("pan_left", "pan_right", "pan_up", "pan_down")
	if input_vector != Vector2.ZERO:
		# On divise par zoom.x pour que la vitesse perçue reste constante quel que soit le niveau de zoom
		
		var half_size_screen: Vector2 = (get_viewport_rect().size / 2.0) / zoom

		position += input_vector * (move_speed / zoom.x) * delta

		position.x = clamp(position.x, limit_left + half_size_screen.x, limit_right - half_size_screen.x)
		position.y = clamp(position.y, limit_top + half_size_screen.y, limit_bottom - half_size_screen.y)


## Ajuste le zoom de manière fluide et bornée
func _adjust_zoom(factor: float) -> void:
	var new_zoom_val: float = clampf(_target_zoom.x * factor, min_zoom, max_zoom)
	_target_zoom = Vector2(new_zoom_val, new_zoom_val)

	# Transition fluide avec un Tween
	if _zoom_tween and _zoom_tween.is_valid():
		_zoom_tween.kill()

	_zoom_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_zoom_tween.tween_property(self, "zoom", _target_zoom, zoom_duration)


## Cadre la caméra sur une zone rectangulaire (centre, zoom mini et limites)
func frame_rect(rect_center: Vector2, rect_size: Vector2, margin_cells: float = 2.0, cell_size: float = 64.0) -> void:
	var viewport_size := get_viewport_rect().size
	if viewport_size == Vector2.ZERO:
		return

	# 1. Calcul de la marge (padding) en pixels pour le décor
	var padding := Vector2.ONE * (margin_cells * cell_size * 2.0)
	var bounding_size := rect_size + padding

	# 2. Zoom optimal pour faire rentrer tout le plateau + la marge
	var optimum_zoom_factor: float = min(viewport_size.x / bounding_size.x, viewport_size.y / bounding_size.y)
	
	# Si la variable de zoom minimum existe dans ton script (ex: min_zoom), on l'aligne :
	min_zoom = optimum_zoom_factor
	max_zoom = optimum_zoom_factor * zoom_range_factor
	zoom = Vector2(optimum_zoom_factor, optimum_zoom_factor)

	# 3. Centrage de la caméra
	global_position = rect_center

	# 4. Ajustement des limites de la caméra (pour ne pas pan dans le vide infini)
	var half_bounds := bounding_size * 0.5
	limit_left = int(rect_center.x - half_bounds.x)
	limit_right = int(rect_center.x + half_bounds.x)
	limit_top = int(rect_center.y - half_bounds.y)
	limit_bottom = int(rect_center.y + half_bounds.y)
