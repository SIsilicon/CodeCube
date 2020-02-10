extends Control

const PROG_VERSION = 2
const SHOW_BLOCKS_IN_EDITOR = true

export(String, FILE, "*.ccprogram") var program

const builtin_blocks := [
	"res://program blocks/Blocks/Misc Blocks/Start Block",
	"res://program blocks/Blocks/Misc Blocks/Stop Block",
	"res://program blocks/Blocks/Loop Blocks/Counter Loop Block",
	"res://program blocks/Blocks/Loop Blocks/Loop End Block"
]
var specific_blocks := [] setget set_specific_blocks

var zoom := 1.0
var zoom_center := Vector2()

var dragging := false
var expanded := false

var undo_redo := UndoRedo.new()
var code := []

func _ready() -> void:
	if not expanded:
		rect_position.x = -rect_size.x
	load_program(program)

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

func _input(event : InputEvent) -> void:
	if expanded:
		if event.is_action_pressed("undo"):
			undo_redo.undo()
			accept_event()
		elif event.is_action_pressed("redo"):
			undo_redo.redo()
			accept_event()

func _process(delta : float) -> void:
	var new_scale : Vector2 = $LinkHandler.rect_scale.linear_interpolate(Vector2(1, 1) * zoom, delta * 10.0)
	var zoom_ratio = new_scale / $LinkHandler.rect_scale
	$LinkHandler.rect_scale = new_scale
	$LinkHandler.rect_position = zoom_center + zoom_ratio * ($LinkHandler.rect_position - zoom_center)

func can_drop_data(_position : Vector2, data) -> bool:
	return data is ProgramBlock

func drop_data(position : Vector2, data) -> void:
	var block = data.duplicate()
	
	undo_redo.create_action("Add Block(s)")
	undo_redo.add_do_method($LinkHandler, "add_block", block)
	undo_redo.add_undo_method($LinkHandler, "remove_child", block)
	undo_redo.commit_action()
	block.rect_position = $LinkHandler.get_transform().affine_inverse().xform(position)

func interpret() -> int:
	for block in $LinkHandler.get_blocks():
		if block is preload("Blocks/Misc Blocks/Start Block.gd"):
			code = block.interpret()
			for b in $LinkHandler.get_blocks():
				b.visited = false
			
			if code.size() == 0:
				return 1
			elif code[0] == "already visited":
				return 4
			elif code[-1] != "stop":
				return 2
			else:
				return 0
	
	return 3

# warning-ignore:shadowed_variable
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
		
		var block_data := block.serialize(builtin_blocks + specific_blocks)
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

# warning-ignore:shadowed_variable
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
		
		var block : ProgramBlock
		if version == 1:
			var rect_pos := Vector2(
					Global.to_signed16(file.get_16()),
					Global.to_signed16(file.get_16())
			)
			var type := file.get_8()
			
			block = load(ProgramBlock.TYPES[type] + ".tscn").instance()
			block.rect_position = rect_pos
			
			for socket in block.get_sockets():
				socket.id = file.get_16()
			
			if type == ProgramBlock.Type.Turn:
				block.set_direction(file.get_8())
			elif type == ProgramBlock.Type.CounterLoop:
				block.set_count(file.get_8())
			$LinkHandler.add_block(block)
		
		elif version == 2:
			var type := file.get_8()
			var path = (builtin_blocks + specific_blocks)[type]
			block = load(path + ".tscn").instance()
			
			block.deserialize(file)
			
			$LinkHandler.add_block(block)
		
		if Engine.editor_hint and SHOW_BLOCKS_IN_EDITOR:
			block.owner = get_parent()
		list_offset += 2
	
	file.seek(link_offset)
	var max_key := 0
	var key := file.get_16()
	
	while key != 0xFFFF:
		$LinkHandler.add_link(file.get_16(), file.get_16(), key)
		max_key = max(max_key, key)
		key = file.get_16()
		max_key = max(max_key, key)
	
	$LinkHandler.link_key = max_key + 1
	file.close()

func set_specific_blocks(value : Array) -> void:
	specific_blocks = value
	$ScrollContainer.update_list(specific_blocks + builtin_blocks)

func _on_Drawer_pressed() -> void:
	if expanded:
		$Tween.interpolate_property(self, "rect_position", rect_position, Vector2(-rect_size.x, 0), 0.5, Tween.TRANS_QUAD, Tween.EASE_OUT)
	else:
		$Tween.interpolate_property(self, "rect_position", rect_position, Vector2(), 0.5, Tween.TRANS_QUAD, Tween.EASE_OUT)
	$Tween.start()
	expanded = not expanded

func _on_FileDialog_file_selected(path : String) -> void:
	if $FileDialog.mode == FileDialog.MODE_SAVE_FILE:
		save_program(path)
	elif $FileDialog.mode == FileDialog.MODE_OPEN_FILE:
		load_program(path)
		undo_redo.clear_history()

func _on_Save_pressed():
	if expanded:
		$FileDialog.mode = FileDialog.MODE_SAVE_FILE
		$FileDialog.invalidate()
		$FileDialog.popup_centered()

func _on_Open_pressed():
	if expanded:
		$FileDialog.mode = FileDialog.MODE_OPEN_FILE
		$FileDialog.invalidate()
		$FileDialog.popup_centered()
