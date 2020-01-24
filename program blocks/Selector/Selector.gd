extends Panel

var selected_blocks := []

func add_to_selection(block : ProgramBlock, toggle : bool) -> void:
	if selected_blocks.find(block) == -1:
		selected_blocks.append(block)
	elif toggle:
		remove_from_selection(block)

func remove_from_selection(block : ProgramBlock) -> void:
	selected_blocks.erase(block)

func set_selection(block : ProgramBlock) -> void:
	selected_blocks = [block]

func clear_selection() -> void:
	selected_blocks.resize(0)

func _process(delta : float) -> void:
	visible = false
	if selected_blocks.size() > 0:
		var rect : Rect2
		for block in selected_blocks:
			if block.is_inside_tree():
				if not rect:
					rect = block.get_rect()
				else:
					rect = rect.merge(block.get_rect())
				visible = true
			block.selected = true
		
		rect_position = rect.position
		rect_size = rect.size

func _on_Delete_pressed():
	var undo_redo : UndoRedo = Global.undo_redo
	undo_redo.create_action("Delete block(s)")
	undo_redo.add_undo_property(get_parent(), "links", get_parent().links.duplicate())
	for block in selected_blocks:
		undo_redo.add_undo_property(block, "link_keys", block.link_keys.duplicate())
		undo_redo.add_undo_method(get_parent(), "add_block", block)
		undo_redo.add_do_method(get_parent(), "remove_child", block)
	
	undo_redo.add_do_property(self, "selected_blocks", [])
	undo_redo.add_undo_property(self, "selected_blocks", selected_blocks)
	undo_redo.commit_action()

func _on_Copy_pressed():
	var undo_redo : UndoRedo = Global.undo_redo
	undo_redo.create_action("Duplicate Block(s)")
	
	var new_blocks := {}
	for block in selected_blocks:
		var new_block : ProgramBlock = block.duplicate()
		
		get_parent().add_block(new_block)
		undo_redo.add_do_method(get_parent(), "add_block", new_block)
		undo_redo.add_undo_method(get_parent(), "remove_child", new_block)
		new_block.rect_position.x += rect_size.x + 10
		new_block.unselected_color = block.unselected_color
		new_blocks[block] = new_block
	
	clear_selection()
	
	for old_block in new_blocks:
		var new_block : ProgramBlock = new_blocks[old_block]
		
		var sockets : Array = old_block.get_sockets()
		for i in sockets.size():
			if sockets[i].type == 1:
				var links : Array = get_parent().get_socket_links(sockets[i])
				if links.size() > 0:
					var other_socket : Panel = get_parent().get_socket(links[0], true)
					var other_block : ProgramBlock = other_socket.block
					if other_block in new_blocks.keys():
						var old_socket_idx : int = other_block.get_sockets().find(other_socket)
						var new_socket_in : Panel = new_blocks[other_block].get_sockets()[old_socket_idx]
						var new_socket_out : Panel = new_blocks[old_block].get_sockets()[i]
						
						undo_redo.add_do_method(get_parent(), "add_link", new_socket_out.id, new_socket_in.id, get_parent().link_key)
						undo_redo.add_undo_method(get_parent(), "remove_link", get_parent().link_key)
						get_parent().link_key += 1
		add_to_selection(new_block, false)
	
	undo_redo.add_undo_property(get_parent(), "link_key", get_parent().link_key)
	undo_redo.commit_action()

func _on_block_dragged(velocity : Vector2, block : ProgramBlock) -> void:
	var block_idx = selected_blocks.find(block)
	if block_idx != -1:
		for i in selected_blocks.size():
			if i == block_idx:
				continue
			
			var t_block : ProgramBlock = selected_blocks[i]
			t_block.rect_position += velocity
