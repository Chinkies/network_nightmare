class_name PanZoomCamera
extends Camera2D

# =====================
# ===== ATTRIBUTS =====
# =====================

# --- Paramètres de déplacement (Pan) ---
@export var move_speed: float = 600.0 # Pixels par seconde

# --- Paramètres de zoom ---
@export var min_zoom: float = 0.5
@export var max_zoom: float = 2.5
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


# Déplacement au clavier ZQSD
func _handle_movement(delta: float) -> void:
	var input_vector: Vector2 = Input.get_vector("pan_left", "pan_right", "pan_up", "pan_down")
	if input_vector != Vector2.ZERO:
		# On divise par zoom.x pour que la vitesse perçue reste constante quel que soit le niveau de zoom
		
		var half_size_screen: Vector2 = (get_viewport_rect().size / 2.0) / zoom

		position += input_vector * (move_speed / zoom.x) * delta

		position.x = clamp(position.x, limit_left + half_size_screen.x, limit_right - half_size_screen.x)
		position.y = clamp(position.y, limit_top + half_size_screen.y, limit_bottom - half_size_screen.y)


# Ajuste le zoom de manière fluide et bornée
func _adjust_zoom(factor: float) -> void:
	var new_zoom_val: float = clampf(_target_zoom.x * factor, min_zoom, max_zoom)
	_target_zoom = Vector2(new_zoom_val, new_zoom_val)

	# Transition fluide avec un Tween
	if _zoom_tween and _zoom_tween.is_valid():
		_zoom_tween.kill()

	_zoom_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_zoom_tween.tween_property(self, "zoom", _target_zoom, zoom_duration)