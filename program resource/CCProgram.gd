tool
extends Resource
class_name CCProgram

enum Type {
	CUBE,
	TILE
}

const BUILTIN_BLOCKS = [
	"res://program blocks/Blocks/Misc Blocks/Start Block",
	"res://program blocks/Blocks/Misc Blocks/Stop Block",
	"res://program blocks/Blocks/Misc Blocks/Wait Block",
	"res://program blocks/Blocks/Loop Blocks/Counter Block",
	"res://program blocks/Blocks/Loop Blocks/Infinite Block",
	"res://program blocks/Blocks/Loop Blocks/Loop End Block",
]

var type : int = Type.CUBE

var available_blocks : Array

var socket_count := 0
var sockets := {}

var links := {}
var link_key := 0

var blocks := []
var root_block : ProgramBlock

var code := [] setget , get_code
var code_dirty := true setget set_code_dirty
var error := 0

# warning-ignore:shadowed_variable
func _init(type := 0) -> void:
	self.type = type
	available_blocks = BUILTIN_BLOCKS + get_specific_blocks()

func interpret() -> int:
	if not code_dirty:
		error = 0
		return error
	
	if blocks.empty():
		error = 4
		return error
	
	code = root_block.interpret()
	for block in blocks:
		block.visited = false
	
	if code.size() == 0:
		error = 1
		return error
	elif code[-1] != "stop":
		error = 2
		return error
	elif code[0] == "already visited":
		error = 3
		return error
	else:
		code_dirty = false
		error = 0
		return error
	
	# warning-ignore:unreachable_code
	error = 4
	return error

func add_block(block : ProgramBlock) -> void:
	if blocks.has(block):
		return
	
	blocks.append(block)
	block.set_program(self)
	if block is preload("res://program blocks/Blocks/Misc Blocks/Start Block.gd"):
		root_block = block
	
	self.code_dirty = true

func remove_block(block : ProgramBlock) -> void:
	if not blocks.has(block):
		return
	
	block._notification(NOTIFICATION_PREDELETE)
	blocks.erase(block)
	
	if block == root_block:
		root_block = null
	
	self.code_dirty = true

func add_link(socket_a_id : int, socket_b_id : int, link_key_override := -1) -> void:
	var socket_a : Panel = sockets[socket_a_id]
	var socket_b : Panel = sockets[socket_b_id]
	
	if socket_a.type == 0: # is it an inflow?
		var temp_socket := socket_b
		socket_b = socket_a
		socket_a = temp_socket
		
	if can_connect(socket_a, socket_b):
		var in_block : Control = socket_b.get_parent()
		var out_block : Control = socket_a.get_parent()
		
		if link_key_override != -1:
			in_block.link_keys.append(link_key_override)
			out_block.link_keys.append(link_key_override)
			
			links[link_key_override] = [socket_a.id, socket_b.id]
		else:
			in_block.link_keys.append(link_key)
			out_block.link_keys.append(link_key)
			
			links[link_key] = [socket_a.id, socket_b.id]
			link_key += 1
		
		self.code_dirty = true

func remove_link(link : int) -> void:
	if not links.has(link):
		return
	
	get_socket(link, false).block.link_keys.erase(link)
	get_socket(link, true).block.link_keys.erase(link)
	links.erase(link)
	
	self.code_dirty = true

func get_socket_links(socket : Panel) -> Array:
	var socket_links := []
	
	for i in links:
		var link = links[i]
		if link[0] == socket.id || link[1] == socket.id:
			socket_links.append(i)
			if socket.type == 1:
				break
	
	return socket_links

func get_socket(link : int, is_inflow : bool) -> Panel:
	return sockets[links[link][int(is_inflow)]]

func can_connect(socket_in : Panel, socket_out : Panel) -> bool:
	if socket_in == socket_out:
		return false
	
	for link in links:
		if sockets[links[link][0]] == socket_in:
			return false
	
	return true

func unregister_socket(socket : Panel) -> void:
	if sockets.has(socket.id):
		for i in range(links.size()-1, -1, -1):
			var link = links[links.keys()[i]]
			if link[0] == socket.id || link[1] == socket.id:
				remove_link(links.keys()[i])
		
		sockets.erase(socket.id)

func register_socket(socket : Panel) -> void:
	if not sockets.has(socket.id):
		socket.id = socket_count if socket.id == -1 else socket.id
		sockets[socket.id] = socket
		socket_count += 1

func set_link_handler(link_handler : Control) -> void:
	for block in blocks:
		if block.get_parent():
			block.get_parent().remove_child(block)
		
		link_handler.add_child(block)
		link_handler.move_child(block, link_handler.get_child_count() - 2)
		
		block.set_link_handler(link_handler)

func set_code_dirty(value : bool) -> void:
	code_dirty = value

func get_code() -> Array:
	if code_dirty:
		printerr("Code needs to be (re)interpreted!")
		return []
	
	return code

func get_specific_blocks() -> Array:
	if type == Type.CUBE:
		return [
			"res://program blocks/Blocks/Action Blocks/Jump Block",
			"res://program blocks/Blocks/Action Blocks/Move Block",
			"res://program blocks/Blocks/Action Blocks/Turn Block"
		]
	else:
		return [
			"res://program blocks/Blocks/Tile Blocks/Translate Block",
		]

# warning-ignore:shadowed_variable
static func get_error_msg(error : int) -> String:
	match error:
		0: return "It's all good."
		1: return "The start block is not connected to anything!"
		2: return "There is no stop block connected to the blocks!"
		3: return "There is a cyclic link in the program!"
		4: return "There is no start block!"
	return "Unknown error. :/ " + str(error)
