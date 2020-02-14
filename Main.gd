extends Spatial

export(bool) var sandbox_mode := false
export(bool) var manual_control := false
export(float) var running_speed := 1.0

onready var cube : Spatial
var cube_died := false
var cube_program := CCProgram.new(CCProgram.Type.CUBE)

var dragging := false
var zoom := 1.0
var drag_offset := Vector2()
var drag_speed := 2.0

var interpreting := false
var playing := false
var show_controls := true

var current_instruction : Label

func _ready() -> void:
	$ProgramWorkshop.visible = not sandbox_mode
	
	spawn_cube()
	if not sandbox_mode:
		$ProgramWorkshop.program = cube_program
		$MapEditor.queue_free()
		$GridMap.start_tile_codes()

func _process(_delta : float) -> void:
	$CameraFollow.enable_drag = sandbox_mode or not ($Controls/Pause.visible and $Controls/Reset.visible)
	if not cube_exists() and manual_control:
		spawn_cube()
	
	Engine.time_scale = max(running_speed, 0.01)

func spawn_cube() -> void:
	if not $GridMap.spawn_tile:
		show_error_msg("Can't place QBoy! There's no spawn tile!")
		return
	
	cube = preload("res://Player/Cube.tscn").instance()
	add_child_below_node($GridMap, cube)
	cube.program = cube_program
	cube.manual_control = manual_control
	cube.teleport($GridMap.spawn_tile)
	cube.connect("died", self, "_on_Cube_died")
	cube.connect("read_instruction", self, "_on_instruction_read")
	cube_died = false

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
	$CameraFollow.shake = 0.25

func _on_Play_pressed() -> void:
	if not interpreting and not playing:
		if sandbox_mode:
			$GridMap.start_tile_codes()
			
			$Controls/Play.hide()
			$Controls/Pause.show()
			$Controls/Reset.show()
			$MapEditor.hide()
			playing = true
			return
		
		interpreting = true
		cube.show_loading_icon()
		
		var error = cube_program.interpret()
		yield(get_tree().create_timer(0.5, true), "timeout")
		
		interpreting = false
		cube.hide_loading_icon()
		
		if error:
			show_error_msg(CCProgram.get_error_msg(error))
			return
		
		$Controls/Play.hide()
		$Controls/Pause.show()
		$Controls/Reset.show()
		
		playing = true
		load_instructions(cube_program.code)
		cube.execute()
	
	if playing:
		get_tree().paused = false
		$Controls/Play.hide()
		$Controls/Pause.show()

func _on_Pause_pressed() -> void:
	$Controls/Pause.hide()
	$Controls/Play.show()
	get_tree().paused = true

func _on_Reset_pressed() -> void:
	get_tree().paused = false
	
	if sandbox_mode:
		for tile in $GridMap.tiles.values():
			if tile.program:
				tile.reset()
		$MapEditor.show()
	else:
		if cube_exists():
			cube.executing = false
			cube.teleport($GridMap.spawn_tile)
		else:
			spawn_cube()
		drag_offset = Vector2()
		load_instructions([])
	
	playing = false
	$Controls/Reset.hide()
	$Controls/Pause.hide()
	$Controls/Play.show()

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
	
	current_instruction = null
