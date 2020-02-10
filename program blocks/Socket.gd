tool
extends Panel

export(int, "Inflow", "Outflow") var type := 0

onready var block := get_parent_control()
var id := -1

var unselected_color : Color
var mouse_inside := false

func _ready():
	var stylebox : StyleBoxFlat = get_stylebox("panel", "").duplicate()
	if stylebox:
		unselected_color = stylebox.bg_color
		add_stylebox_override("panel", stylebox)

func _input(event : InputEvent) -> void:
	if mouse_inside:
		if event is InputEventMouseButton and event.button_index == BUTTON_LEFT and event.pressed:
			var link_handler : Control = block.link_handler
			
			if type == 1:
				var link : Array = link_handler.get_socket_links(self)
				if link.size() > 0:
					var in_socket : Control = link_handler.get_socket(link[0], true)
					link_handler.remove_link(link[0])
					
					in_socket.mouse_inside = true
					in_socket._input(event)
					in_socket.mouse_inside = false
					return
			
			link_handler.dragging_link = event.pressed
			link_handler.temp_socket_a = self
			link_handler.dragging_outflow = bool(type)
			force_drag([self, link_handler.dragging_outflow], null)
			
			if event.pressed:
				link_handler.temp_socket_a = self
				link_handler.dragging_outflow = bool(type)
			
			if not event.pressed and link_handler.dragging_outflow != bool(type):
				link_handler.temp_socket_b = self
			
			get_tree().set_input_as_handled()

func _notification(what : int) -> void:
	if what == NOTIFICATION_MOUSE_ENTER:
		mouse_inside = true
		get_stylebox("panel", "").bg_color = Color.white
	if what == NOTIFICATION_MOUSE_EXIT:
		mouse_inside = false
		get_stylebox("panel", "").bg_color = unselected_color

func can_drop_data(_position : Vector2, data) -> bool:
	return typeof(data) == TYPE_ARRAY and data.size() == 2 and \
			data[0] is (get_script() as Script) and \
			data[1] != bool(type)

func drop_data(_position : Vector2, _data) -> void:
	block.link_handler.temp_socket_b = self

func get_position() -> Vector2:
	return get_parent().get_transform() * get_transform() * $Position.position
