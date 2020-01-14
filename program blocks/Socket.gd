tool
extends Panel

export(int, "Inflow", "Outflow") var type := 0

onready var block := get_parent_control()
var id := 0

var mouse_inside := false

func _input(event : InputEvent) -> void:
	if mouse_inside:
		if event is InputEventMouseButton:
			block._link_handler.dragging_link = event.pressed
			
			if event.pressed:
				block._link_handler.temp_socket_a = self
				block._link_handler.dragging_outflow = bool(type)
			elif block._link_handler.dragging_outflow != bool(type):
				block._link_handler.temp_socket_b = self
			
			get_tree().set_input_as_handled()

func _notification(what : int) -> void:
	if what == NOTIFICATION_MOUSE_ENTER:
		mouse_inside = true
	if what == NOTIFICATION_MOUSE_EXIT:
		mouse_inside = false

func get_position() -> Vector2:
	return get_parent().get_transform() * get_transform() * $Position.position
