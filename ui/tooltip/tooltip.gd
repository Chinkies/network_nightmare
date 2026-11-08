class_name TooltipManager
extends CanvasLayer

@onready var panel: PanelContainer = $Panel
@onready var label: Label = $Panel/Label

# Singleton global optionnel (si tu veux l'appeler facilement via TooltipManager.show_tooltip(...))
static var instance: TooltipManager

func _ready() -> void:
	instance = self
	hide_tooltip()


func _process(_delta: float) -> void:
	if panel.visible:
		# Positionne la bulle légèrement à côté de la souris
		var mouse_pos = get_viewport().get_mouse_position()
		var window_size = get_viewport().get_visible_rect().size
		
		# Décalage par rapport au curseur
		var target_pos = mouse_pos + Vector2(15, 15)
		
		# Empêche la bulle de dépasser en bas/à droite de l'écran
		var panel_size = panel.size
		if target_pos.x + panel_size.x > window_size.x:
			target_pos.x = mouse_pos.x - panel_size.x - 10
		if target_pos.y + panel_size.y > window_size.y:
			target_pos.y = mouse_pos.y - panel_size.y - 10
			
		panel.global_position = target_pos


func show_tooltip(text: String) -> void:
	if text.is_empty():
		hide_tooltip()
		return
	
	label.text = text
	show()
	panel.show()


func hide_tooltip() -> void:
	panel.hide()
	hide()