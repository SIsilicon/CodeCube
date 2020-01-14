extends Panel
class_name ProgramBlock

export(NodePath) var link_handler = ".."

var dragged := false
onready var pre_drag_position := rect_position

var _link_handler : Control
var link_keys := []

func _ready() -> void:
	_link_handler = get_node(link_handler)

func _gui_input(event : InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT:
		dragged = event.pressed
		if event.pressed:
			pre_drag_position = event.position
		accept_event()
	elif event is InputEventMouseMotion and dragged:
		rect_position += event.position - pre_drag_position
		accept_event()

func interpret() -> Array:
	return []
