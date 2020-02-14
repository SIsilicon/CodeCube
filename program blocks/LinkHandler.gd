extends Control

var dragging_link := false
var dragging_outflow := false
var temp_socket_a : Control
var temp_socket_b : Control

var cutting_links := false
var cut_links := []

onready var renderer = $LinkRenderer
onready var selector = $Selector

func _input(event : InputEvent) -> void:
	var undo_redo : UndoRedo = get_parent().undo_redo
	var program : CCProgram = get_parent().program
	
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
						undo_redo.add_do_method(program, "remove_link", link)
						undo_redo.add_undo_method(program, "add_link", program.links[link][0], program.links[link][1], link)
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
		for i in range(program.links.size()-1, -1, -1):
			var link : int = program.links.keys()[i]
			
			var point_a : Vector2 = program.get_socket(link, false).get_position()
			var dir_a : Vector2 = program.get_socket(link, true).get_position() - point_a
			
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

func _process(_delta : float) -> void:
	renderer = $LinkRenderer
	renderer.dragging_link = dragging_link
	
	var program : CCProgram = get_parent().program
	
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
		undo_redo.add_do_method(program, "add_link", temp_socket_a.id, temp_socket_b.id, program.link_key)
		undo_redo.add_undo_method(program, "remove_link", program.link_key)
		undo_redo.add_do_property(program, "link_key", program.link_key + 1)
		undo_redo.add_undo_property(program, "link_key", program.link_key)
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

func add_block(block : ProgramBlock) -> void:
	if block.get_parent() != self:
		add_child(block)
		move_child(block, get_child_count() - 2)
		get_parent().program.add_block(block)
		block.link_handler = self

func remove_block(block : ProgramBlock) -> void:
	if block.get_parent() == self:
		remove_child(block)
		get_parent().program.remove_block(block)

func get_blocks() -> Array:
	var blocks := []
	for child in get_child_count() - 2:
		blocks.append(get_child(child + 1))
	return blocks
