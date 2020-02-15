extends Control

const PROG_VERSION = 2
const SHOW_BLOCKS_IN_EDITOR = true

var program := CCProgram.new() setget set_program

var zoom := 1.0
var zoom_center := Vector2()

var dragging := false
var expanded := false

var undo_redo := UndoRedo.new()
var code := []

func _ready() -> void:
	if not expanded:
		rect_position.x = -rect_size.x

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
	
	material.set_shader_param("zoom", new_scale.x)
	material.set_shader_param("offset", $LinkHandler.rect_position)

func can_drop_data(_position : Vector2, data) -> bool:
	return data is ProgramBlock

func drop_data(position : Vector2, data) -> void:
	var block = data.duplicate()
	
	undo_redo.create_action("Add Block(s)")
	undo_redo.add_do_method($LinkHandler, "add_block", block)
	undo_redo.add_undo_method($LinkHandler, "remove_child", block)
	undo_redo.commit_action()
	block.rect_position = $LinkHandler.get_transform().affine_inverse().xform(position)

func set_program(value : CCProgram) -> void:
	for child in $LinkHandler.get_children():
		if child is ProgramBlock:
			$LinkHandler.remove_child(child)
	
	program = value
	
	if program:
		program.set_link_handler($LinkHandler)
		$ScrollContainer.update_list(program.available_blocks)
		$GetProgram.hide()
		
		if not $"..".sandbox_mode:
			$"..".cube_program = program
			$"..".cube.program = program
		else:
			$"../MapEditor".selected_tile.program = program
		
	else:
		$GetProgram.show()

func _on_Drawer_pressed() -> void:
	if expanded:
		$Tween.interpolate_property(self, "rect_position", rect_position, Vector2(-rect_size.x, 0), 0.5, Tween.TRANS_QUAD, Tween.EASE_OUT)
	else:
		$Tween.interpolate_property(self, "rect_position", rect_position, Vector2(), 0.5, Tween.TRANS_QUAD, Tween.EASE_OUT)
	$Tween.start()
	expanded = not expanded

func _on_FileDialog_file_selected(path : String) -> void:
	if $FileDialog.mode == FileDialog.MODE_SAVE_FILE:
		CCProgramSaverLoader.save(path, program)
	elif $FileDialog.mode == FileDialog.MODE_OPEN_FILE:
		self.program = CCProgramSaverLoader.load(path)
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

# Creates a tile program. Keep that in mind!
func _on_Create_Program_pressed():
	self.program = CCProgram.new(CCProgram.Type.TILE)
