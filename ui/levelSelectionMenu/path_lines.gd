class_name PathLines
extends Control

@export var buttons_container: Control

@export_category("Style des lignes")
@export var line_color: Color = Color(0.4, 0.5, 0.7, 0.8)
@export var line_width: float = 4.0                    

func _ready() -> void:
	await get_tree().process_frame
	queue_redraw()


func _draw() -> void:
	if not buttons_container:
		return
		
	var buttons = buttons_container.get_children()
	if buttons.size() < 2:
		return
		
	for i in range(buttons.size() - 1):
		var btn1 = buttons[i] as Control
		var btn2 = buttons[i + 1] as Control
		
		if btn1 and btn2:
			var p1 = btn1.global_position + (btn1.size * 0.5) - global_position
			var p2 = btn2.global_position + (btn2.size * 0.5) - global_position
			
			draw_line(p1, p2, line_color, line_width, true)