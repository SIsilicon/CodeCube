extends Panel
class_name ProgramBlock

signal selected(multi_selcect)
signal dragged(velocity)

enum Type {
	Start, Stop,
	Jump, Move, Turn,
	CounterLoop, LoopEnd
}

const DEBUG_INTERPRET_STACK := true
const TYPES := [
	"res://program blocks/Blocks/Misc Blocks/Start Block",
	"res://program blocks/Blocks/Misc Blocks/Stop Block",
	"res://program blocks/Blocks/Action Blocks/Jump Block",
	"res://program blocks/Blocks/Action Blocks/Move Block",
	"res://program blocks/Blocks/Action Blocks/Turn Block",
	"res://program blocks/Blocks/Loop Blocks/Counter Loop Block",
	"res://program blocks/Blocks/Loop Blocks/Loop End Block"
]

export(Texture) var icon

var pressed := false
var dragged := false
onready var pre_drag_position := rect_position

var program setget set_program
var link_handler : Control setget set_link_handler
var link_keys := []

var unselected_color : Color
var selected := false

var visited := false # Used during interpretation

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
		if not event.shift:
			emit_signal("dragged", event.position - pre_drag_position)
		accept_event()

func _ready():
	var stylebox : StyleBoxFlat = get_stylebox("panel", "").duplicate()
	if stylebox:
		unselected_color = stylebox.border_color
		add_stylebox_override("panel", stylebox)

func _process(_delta : float) -> void:
	if selected and get_stylebox("panel", ""):
		get_stylebox("panel", "").border_color = Color.white
		selected = false
	else:
		get_stylebox("panel", "").border_color = unselected_color

func _notification(what : int) -> void:
	if what == NOTIFICATION_PREDELETE and program:
		for socket in get_sockets():
			program.unregister_socket(socket)

func interpret() -> Array:
	if visited:
		return ["already visited"]
	else:
		visited = true
		return []

func set_program(value) -> void:
	program = value
	
	for socket in get_sockets():
		if program:
			program.register_socket(socket)

func set_link_handler(value : Control) -> void:
	link_handler = value
	if link_handler and not is_connected("selected", link_handler, "_on_block_selected"):
		connect("selected", link_handler, "_on_block_selected", [self])
		connect("dragged", link_handler.selector, "_on_block_dragged", [self])

func get_sockets() -> Array:
	var sockets := []
	for child in get_children():
		if child is preload("res://program blocks/Socket.gd"):
			sockets.append(child)
	return sockets

func get_socket_link(socket : Panel) -> int:
	for link_key in link_keys:
		if program.get_socket(link_key, false) == socket:
			return link_key
	return -1

func serialize(blocks : Array) -> Dictionary:
	var dict := {
		type = blocks.find(get_script().resource_path.rstrip(".gd")),
		pos = rect_position,
		sockets = []
	}
	
	for socket in get_sockets():
		dict.sockets.append(socket.id)
	
	return dict

func deserialize(dict : Dictionary) -> void:
	rect_position = dict.pos
	for i in get_sockets().size():
		get_sockets()[i].id = dict.sockets[i]
