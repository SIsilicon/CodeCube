extends Control

export var links := {}
var link_key := 0

var dragging_link := false
var dragging_outflow := false
var temp_socket_a : Control
var temp_socket_b : Control

var cutting_links := false
var cut_links := []

var socket_count := 0
var sockets := {}

onready var renderer = $LinkRenderer
onready var selector = $Selector

func _ready() -> void:
	for block in get_blocks():
		block.set_link_handler(self)
	
	if links.size() > 0:
		for link in links:
			link[0].block.link_keys.append(link_key)
			link[1].block.link_keys.append(link_key)
			
			link_key += 1

func _input(event : InputEvent) -> void:
	var undo_redo : UndoRedo = get_parent().undo_redo
	
	# Select all blocks
	if event is InputEventKey and event.pressed and event.scancode == KEY_A and event.control:
		undo_redo.create_action("Select all blocks")
		for block in get_blocks():
			undo_redo.add_undo_method(selector, "remove_from_selection", block)
			undo_redo.add_do_method(selector, "add_to_selection", block, false)
		undo_redo.commit_action()
		get_tree().set_input_as_handled()
	
	# Releasing deletes links in cut_links
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT:
		if event.control:
			cutting_links = event.pressed
			if not event.pressed:
				renderer.cut_line.resize(0)
				if cut_links.size() > 0:
					undo_redo.create_action("Cut lines")
					for link in cut_links:
						undo_redo.add_do_method(self, "remove_link", link)
						undo_redo.add_undo_method(self, "add_link", links[link][0], links[link][1], link)
					cut_links.resize(0)
					undo_redo.commit_action()
			else:
				renderer.cut_line.append(event.position)
			
			get_tree().set_input_as_handled()
		elif not event.pressed:
			dragging_link = false
	
	# Dragging while cutting_links calculates whatever links are inbetween the mouse's previous and current position.
	# If a link is inbetween, it's put into cut_links for deletion
	if event is InputEventMouseMotion and cutting_links:
		for i in range(links.size()-1, -1, -1):
			var link : int = links.keys()[i]
			
			var point_a : Vector2 = get_socket(link, false).get_position()
			var dir_a : Vector2 = get_socket(link, true).get_position() - point_a
			
			var point_b : Vector2 = get_transform().affine_inverse().xform(event.position)
			var dir_b : Vector2 = get_transform().affine_inverse().basis_xform(-event.relative)
			
			var intersect = Geometry.line_intersects_line_2d(point_a, dir_a, point_b, dir_b)
			var intersect_bool := true
			if typeof(intersect) == TYPE_VECTOR2:
				var t := inverse_lerp(point_a.x, dir_a.x + point_a.x, intersect.x)
				intersect_bool = t > 0 and t < 1
				
				t = inverse_lerp(point_b.x, dir_b.x + point_b.x, intersect.x)
				intersect_bool = intersect_bool and t > 0 and t < 1
			else:
				intersect_bool = false
			
			if intersect_bool:
				cut_links.append(link)
		
		renderer.cut_line.append(event.position)

func _process(delta : float) -> void:
	renderer = $LinkRenderer
	
	renderer.dragging_link = dragging_link
	
	if dragging_link:
		if dragging_outflow:
			renderer.begin_vec = temp_socket_a.get_position()
			renderer.end_vec = get_local_mouse_position()
		else:
			renderer.begin_vec = get_local_mouse_position()
			renderer.end_vec = temp_socket_a.get_position()
	
	if temp_socket_a and temp_socket_b:
		var undo_redo : UndoRedo = get_parent().undo_redo
		undo_redo.create_action("Create link")
		undo_redo.add_do_method(self, "add_link", temp_socket_a.id, temp_socket_b.id, link_key)
		undo_redo.add_undo_method(self, "remove_link", link_key)
		undo_redo.add_do_property(self, "link_key", link_key + 1)
		undo_redo.add_undo_property(self, "link_key", link_key)
		undo_redo.commit_action()
		
		temp_socket_a = null
		temp_socket_b = null
		dragging_link = false

func _on_block_selected(multi_select : bool, block : ProgramBlock) -> void:
	var undo_redo : UndoRedo = get_parent().undo_redo
	undo_redo.create_action("Select block")
	if multi_select:
		undo_redo.add_do_method(selector, "add_to_selection", block, true)
		undo_redo.add_undo_method(selector, "add_to_selection", block, true)
	else:
		undo_redo.add_do_property(selector, "selected_blocks", [block])
		undo_redo.add_undo_property(selector, "selected_blocks", selector.selected_blocks)
	undo_redo.commit_action()

func can_connect(socket_in : Panel, socket_out : Panel) -> bool:
	if socket_in == socket_out:
		return false
	
	for link in links:
		if sockets[links[link][0]] == socket_in:
			return false
	
	return true

func add_block(block : ProgramBlock) -> void:
	if block.get_parent() != self:
		add_child(block)
		move_child(block, get_child_count() - 2)
		block.link_handler = self

func get_blocks() -> Array:
	var blocks := []
	for child in get_child_count() - 2:
		blocks.append(get_child(child + 1))
	return blocks

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

func remove_link(link : int) -> void:
	if links.has(link):
		get_socket(link, false).block.link_keys.erase(link)
		get_socket(link, true).block.link_keys.erase(link)
		links.erase(link)

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
