class_name Packet
extends RefCounted

enum PacketColor { BLUE, RED, GREEN, YELLOW }
enum PacketShape { CIRCLE, SQUARE, TRIANGLE }

var id: int
var color: PacketColor
var shape: PacketShape
var ttl: int = -1 	#Time-To-Live, -1 pour un paquet non éphémère
var payload: Dictionary = {}

func _init(p_id: int, p_color: PacketColor, p_shape: PacketShape, p_ttl: int = -1, p_payload: Dictionary = {}) -> void:
	id = p_id
	color = p_color
	shape = p_shape
	ttl = p_ttl
	payload = p_payload

func step_ttl() -> bool:
	if ttl < 0:
		return false
	ttl -= 1
	return ttl <= 0
