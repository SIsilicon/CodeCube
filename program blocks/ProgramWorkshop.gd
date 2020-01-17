extends Control

var zoom := 1.0
var zoom_center := Vector2()

var dragging := false
var expanded := false

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

func _process(delta : float) -> void:
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
	$LinkHandler.add_block(block)
	block.rect_position = $LinkHandler.get_transform().affine_inverse().xform(position)

func interpret() -> int:
	for block in $LinkHandler.get_children():
		if block == $LinkHandler/LinkRenderer:
			continue
		
		if block is preload("Blocks/Misc Blocks/Start Block.gd"):
			code = block.interpret()
			
			if code.size() == 0:
				return 1
			elif code[-1] != "stop":
				return 2
			else:
				return 0
	
	return 3

func _on_Drawer_pressed():
	if expanded:
		$Tween.interpolate_property(self, "rect_position", rect_position, Vector2(-rect_size.x, 0), 0.5, Tween.TRANS_QUAD, Tween.EASE_OUT)
	else:
		$Tween.interpolate_property(self, "rect_position", rect_position, Vector2(), 0.5, Tween.TRANS_QUAD, Tween.EASE_OUT)
	
	$Tween.start()
	expanded = not expanded
