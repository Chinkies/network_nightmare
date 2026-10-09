extends Button

func _ready() -> void:
	toggled.connect(_on_toggled)
	_update_mouse_filter(button_pressed)

func _on_toggled(is_pressed: bool) -> void:
	_update_mouse_filter(is_pressed)
# Tous ça pour corriger ce putain d'hover pressed state qui merde (style normal sur un hover pressed toggle button)
func _update_mouse_filter(is_pressed: bool) -> void:
	# Quand le bouton est déjà enfoncé, il ignore les clics de souris
	mouse_filter = MOUSE_FILTER_IGNORE if is_pressed else MOUSE_FILTER_STOP