class_name RadioButton
extends Button

func _ready() -> void:
	toggled.connect(_on_toggled)
	_update_mouse_filter(button_pressed)

func _on_toggled(is_pressed: bool) -> void:
	_update_mouse_filter(is_pressed)

func _update_mouse_filter(is_pressed: bool) -> void:
	# Ignore les événements souris quand le bouton est actif pour préserver le style pressed
	mouse_filter = Control.MOUSE_FILTER_IGNORE if is_pressed else Control.MOUSE_FILTER_STOP
