extends Panel
class_name ProgramBlock

signal selected(multi_selcect)
signal dragged(velocity)

const DEBUG_INTERPRET_STACK := true

var pressed := false
var dragged := false
onready var pre_drag_position := rect_position

var link_handler : Control setget set_link_handler
var link_keys := []

var unselected_color : Color
var selected := false

func _gui_input(event : InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT:
		if event.pressed:
			pre_drag_position = event.position
		elif not dragged:
			emit_signal("selected", event.shift)
		
		pressed = event.pressed
		dragged = false
		accept_event()
	elif event is InputEventMouseMotion and pressed:
		rect_position += event.position - pre_drag_position
		dragged = true
		if event.shift:
			emit_signal("dragged", event.position - pre_drag_position)
		accept_event()

func _ready():
	var stylebox : StyleBoxFlat = get_stylebox("panel", "").duplicate()
	if stylebox:
		unselected_color = stylebox.border_color
		add_stylebox_override("panel", stylebox)

func _process(delta : float) -> void:
	if selected and get_stylebox("panel", ""):
		get_stylebox("panel", "").border_color = Color.white
		selected = false
	else:
		get_stylebox("panel", "").border_color = unselected_color

func _exit_tree() -> void:
	if link_handler:
		for socket in get_sockets():
			link_handler.unregister_socket(socket)

func interpret() -> Array:
	return []

func set_link_handler(value : Control) -> void:
	var prev_handler := link_handler
	link_handler = value
	
	if link_handler and not is_connected("selected", link_handler, "_on_block_selected"):
		connect("selected", link_handler, "_on_block_selected", [self])
		connect("dragged", link_handler.selector, "_on_block_dragged", [self])
	
	for socket in get_sockets():
		if link_handler:
			link_handler.register_socket(socket)

func get_sockets() -> Array:
	var sockets := []
	for child in get_children():
		if child is preload("res://program blocks/Socket.gd"):
			sockets.append(child)
	return sockets
