tool
extends Control

const PROG_VERSION = 1

const SHOW_BLOCKS_IN_EDITOR = true

export(String, FILE, "*.ccprogram") var save_file

var zoom := 1.0
var zoom_center := Vector2()

var dragging := false
var expanded := false

var code := []

func _ready() -> void:
	if not expanded:
		rect_position.x = -rect_size.x
	
	if Engine.editor_hint:
		set_process(false)
	
	load_program(save_file)

func _unhandled_input(event) -> void:
	if expanded and event is InputEventKey and not event.pressed and event.control:
		match event.scancode:
			KEY_S:
				save_program(save_file)
				get_tree().set_input_as_handled()
			KEY_O:
				load_program(save_file)
				get_parent()._on_Reset_pressed()
				get_tree().set_input_as_handled()

func _gui_input(event : InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_WHEEL_DOWN :
			zoom /= 1.1
			zoom_center = event.position
			accept_event()
		elif event.button_index == BUTTON_WHEEL_UP:
			zoom *= 1.1
			zoom_center = event.position
			accept_event()
		elif event.button_index == BUTTON_MIDDLE:
			dragging = event.pressed
			accept_event()
		elif event.button_index == BUTTON_LEFT and not event.pressed:
			$LinkHandler/Selector.clear_selection()
			accept_event()
		
		zoom = clamp(zoom, 0.125, 4.0)
	
	if event is InputEventMouseMotion and dragging:
		$LinkHandler.rect_position += event.relative
		accept_event()

func _process(delta : float) -> void:
	if expanded:
		if Input.is_action_just_released("undo"):
			Global.undo_redo.undo()
		elif Input.is_action_just_released("redo"):
			Global.undo_redo.redo()
	
	var new_scale : Vector2 = $LinkHandler.rect_scale.linear_interpolate(Vector2(1, 1) * zoom, delta * 10.0)
	var zoom_ratio = new_scale / $LinkHandler.rect_scale
	$LinkHandler.rect_scale = new_scale
	$LinkHandler.rect_position = zoom_center + zoom_ratio * ($LinkHandler.rect_position - zoom_center)

func can_drop_data(position : Vector2, data) -> bool:
	return data is ProgramBlock

func drop_data(position : Vector2, data) -> void:
	var block = data.duplicate()
	
	var undo_redo = Global.undo_redo
	undo_redo.create_action("Add Block(s)")
	undo_redo.add_do_method($LinkHandler, "add_block", block)
	undo_redo.add_undo_method($LinkHandler, "remove_child", block)
	undo_redo.commit_action()
	block.rect_position = $LinkHandler.get_transform().affine_inverse().xform(position)

func interpret() -> int:
	for block in $LinkHandler.get_blocks():
		if block is preload("Blocks/Misc Blocks/Start Block.gd"):
			code = block.interpret()
			
			if code.size() == 0:
				return 1
			elif code[-1] != "stop":
				return 2
			else:
				return 0
	
	return 3

func save_program(program : String) -> void:
	var blocks : Array = $LinkHandler.get_blocks()
	
	var file := File.new()
	file.open(program, File.WRITE)
	file.store_8(PROG_VERSION)
	file.store_16(blocks.size())
	file.store_32(0) # placeholder for link list offset
	
	var list_offset = 7 # offset from stored values above.
	var list_size = blocks.size() * 2 # size of list (2 bytes per element)
	
	var block_offset = list_offset + list_size
	for i in blocks.size():
		var block : ProgramBlock = blocks[i]
		file.store_16(block_offset)
		file.seek(block_offset)
		
		var block_data := block.serialize()
		file.store_buffer(block_data)
		block_offset += block_data.size()
		
		file.seek(list_offset + (i + 1) * 2)
	
	file.seek(3) # Link list offset
	file.store_32(block_offset)
	file.seek(block_offset)
	
	for link in $LinkHandler.links:
		file.store_16(link)
		file.store_16($LinkHandler.links[link][0])
		file.store_16($LinkHandler.links[link][1])
	file.store_16(0xFFFF) # marks end of list
	
	file.close()

func load_program(program : String) -> void:
	var file := File.new()
	if not file.file_exists(program):
		return
	
	for block in $LinkHandler.get_blocks():
		$LinkHandler.remove_child(block)
		block.queue_free()
	
	file.open(program, File.READ)
	
	var version := file.get_8()
	var block_num := file.get_16()
	var link_offset := file.get_32()
	
	var list_offset = 7
	for i in block_num:
		file.seek(list_offset)
		var block_offset := file.get_16()
		file.seek(block_offset)
		
		var rect_pos := Vector2(
				_to_signed_16(file.get_16()),
				_to_signed_16(file.get_16())
		)
		var type := file.get_8()
		
		var block = load(ProgramBlock.TYPES[type] + ".tscn").instance()
		block.rect_position = rect_pos
		for socket in block.get_sockets():
			socket.id = file.get_16()
		
		if type == ProgramBlock.Type.Turn:
			block.set_direction(file.get_8())
		
		$LinkHandler.add_block(block)
		
		if Engine.editor_hint and SHOW_BLOCKS_IN_EDITOR:
			block.owner = get_parent()
		list_offset += 2
	
	file.seek(link_offset)
	var key := file.get_16()
	while key != 0xFFFF:
		$LinkHandler.add_link(file.get_16(), file.get_16(), key)
		key = file.get_16()
	
	file.close()

func _on_Drawer_pressed():
	if expanded:
		$Tween.interpolate_property(self, "rect_position", rect_position, Vector2(-rect_size.x, 0), 0.5, Tween.TRANS_QUAD, Tween.EASE_OUT)
	else:
		$Tween.interpolate_property(self, "rect_position", rect_position, Vector2(), 0.5, Tween.TRANS_QUAD, Tween.EASE_OUT)
	$Tween.start()
	expanded = not expanded

func _to_signed_16(val : int) -> int:
	if val > 0x7FFF:
		return -(~val & 0xFFFF) - 1
	return val
