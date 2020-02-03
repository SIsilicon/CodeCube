extends Spatial

export(bool) var sandbox_mode := false
export(bool) var manual_control := false

onready var cube : Spatial

var dragging := false
var zoom := 1.0
var drag_offset := Vector2()
var drag_speed := 2.0

var interpreting := false
var playing := false
var show_controls := true

var current_instruction : Label

var cube_died := false

func _ready() -> void:
	if not sandbox_mode:
		$MapEditor.queue_free()
	spawn_cube()

func _unhandled_input(event : InputEvent) -> void:
	if not ($Controls/Pause.visible and $Controls/Reset.visible):
		if event is InputEventMouseButton:
			if event.button_index == BUTTON_MIDDLE:
				dragging = event.pressed
			elif event.button_index == BUTTON_WHEEL_UP:
				zoom /= 1.1
			elif event.button_index == BUTTON_WHEEL_DOWN:
				zoom *= 1.1
		if event is InputEventMouseMotion and dragging:
			drag_offset += event.relative * 0.01 * drag_speed

func _process(delta : float) -> void:
	if cube_exists():
		var new_cam_trans := Transform().translated(Vector3(0, 6, -4) * zoom)
		var target := cube.translation
		target.y = max(target.y, -2.0)
		new_cam_trans = new_cam_trans.translated(target)
		new_cam_trans = new_cam_trans.looking_at(target, Vector3.UP)
		
		if not ($Controls/Pause.visible and $Controls/Reset.visible):
			new_cam_trans.origin.x += drag_offset.x
			new_cam_trans.origin.z += drag_offset.y
		else:
			drag_offset = Vector2()
			zoom = 1.0
		
		$CameraFollow.transform = new_cam_trans
	elif manual_control:
		spawn_cube()

func spawn_cube() -> void:
	if not $GridMap.spawn_tile:
		show_error_msg("Can't place QBoy! There's no spawn tile!")
		return
	
	cube = preload("res://Player/Cube.tscn").instance()
	add_child_below_node($GridMap, cube)
	cube.manual_control = manual_control
	cube.teleport($GridMap.spawn_tile)
	cube.connect("died", self, "_on_Cube_died")
	cube.connect("read_instruction", self, "_on_instruction_read")
	cube_died = false

func pause_node(node : Node, paused : bool) -> void:
	node.set_process(!paused)
	node.set_physics_process(!paused)
	node.set_process_input(!paused)
	node.set_process_internal(!paused)
	node.set_process_unhandled_input(!paused)
	node.set_process_unhandled_key_input(!paused)
	for child in node.get_children():
		pause_node(child, paused)

func show_error_msg(msg : String) -> void:
	$Error.text = msg
	var stylebox = $Error.get_stylebox("normal", "")
	
	$Tween.stop($Error)
	$Tween.stop(stylebox)
	$Error.margin_top = -$Error.rect_size.y
	$Error.margin_bottom = 0
	
	$Tween.interpolate_property(stylebox, "bg_color", Color.red, Color(1,0,0,0), 0.5, Tween.TRANS_LINEAR, Tween.EASE_IN)
	$Tween.interpolate_property($Error, "margin_top", $Error.margin_top, 0, 0.3, Tween.TRANS_LINEAR, Tween.EASE_IN, 3.0)
	$Tween.interpolate_property($Error, "margin_bottom", 0, $Error.margin_bottom, 0.3, Tween.TRANS_LINEAR, Tween.EASE_IN, 3.0)
	$Tween.start()

func _on_Cube_died() -> void:
	cube_died = true

func _on_Play_pressed() -> void:
	if not interpreting and not playing:
		interpreting = true
		cube.show_loading_icon()
		
		var error = $ProgramWorkshop.interpret()
		yield(get_tree().create_timer(0.5, true), "timeout")
		
		print($ProgramWorkshop.code)
		interpreting = false
		cube.hide_loading_icon()
		
		if error:
			match error:
				1: show_error_msg("The start block is not connected to anything!")
				2: show_error_msg("There is no stop block connected to the blocks!")
				3: show_error_msg("There is no start block!")
				4: show_error_msg("There is a cyclic link in the program!")
			return
		
		$Controls/Play.hide()
		$Controls/Pause.show()
		$Controls/Reset.show()
		
		playing = true
		load_instructions($ProgramWorkshop.code)
		cube.execute()
	
	if cube_exists() and playing:
		pause_node(cube, false)
		$Controls/Play.hide()
		$Controls/Pause.show()

func _on_Pause_pressed() -> void:
	$Controls/Pause.hide()
	$Controls/Play.show()
	
	if cube_exists():
		pause_node(cube, true)

func _on_Reset_pressed() -> void:
	if cube_exists():
		cube.executing = false
		cube.teleport($GridMap.spawn_tile)
	else:
		spawn_cube()
	
	playing = false
	drag_offset = Vector2()
	$Controls/Reset.hide()
	$Controls/Pause.hide()
	$Controls/Play.show()
	
	load_instructions([])

func _on_Drawer_pressed() -> void:
	if show_controls:
		$Tween.interpolate_property($Controls, "rect_position", $Controls.rect_position,
				Vector2(0, -$Controls.rect_size.y), 0.5, Tween.TRANS_QUAD, Tween.EASE_IN_OUT)
	else:
		$Tween.interpolate_property($Controls, "rect_position", $Controls.rect_position,
				Vector2(), 0.5, Tween.TRANS_QUAD, Tween.EASE_IN_OUT, 0.25)
	
	$Tween.start()
	show_controls = not show_controls

func _on_instruction_read(line_num : int) -> void:
	if current_instruction:
		current_instruction.get_stylebox("normal", "").border_color = Color(0.070588, 0.070588, 0.070588)
	
	current_instruction = $Instructions/VBox.get_child(line_num)
	current_instruction.get_stylebox("normal", "").border_color = Color.white

func cube_exists() -> bool:
	return weakref(cube).get_ref() != null

func load_instructions(code : Array) -> void:
	var template := $Instructions/Template
	var vbox := $Instructions/VBox
	
	for child in vbox.get_children():
		vbox.remove_child(child)
	for instruction in code:
		var label : Label = template.duplicate()
		label.text = instruction
		var stylebox := label.get_stylebox("normal", "").duplicate()
		label.add_stylebox_override("normal", stylebox)
		label.show()
		vbox.add_child(label)
	
	if cube_exists():
		cube.code = code
	
	current_instruction = null
