extends Control

var zoom := 1.0
var zoom_center := Vector2()

var dragging := false

func _gui_input(event : InputEvent) -> void:
	
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_WHEEL_DOWN :
			zoom /= 1.2
			zoom_center = event.position
		elif event.button_index == BUTTON_WHEEL_UP:
			zoom *= 1.2
			zoom_center = event.position
		elif event.button_index == BUTTON_MIDDLE:
			dragging = event.pressed
		
		zoom = clamp(zoom, 0.125, 4.0)
		accept_event()
	
	if event is InputEventMouseMotion and dragging:
		$LinkHandler.rect_position += event.relative
		accept_event()

func _process(delta : float) -> void:
	var new_scale : Vector2 = $LinkHandler.rect_scale.linear_interpolate(Vector2(1, 1) * zoom, delta * 10.0)
	var zoom_ratio = new_scale / $LinkHandler.rect_scale
	$LinkHandler.rect_scale = new_scale
	$LinkHandler.rect_position = zoom_center + zoom_ratio * ($LinkHandler.rect_position - zoom_center)

func interpret() -> void:
	for block in $LinkHandler.get_children():
		if block == $LinkHandler/LinkRenderer:
			continue
		
		if block is preload("Blocks/Start Block.gd"):
			var code : Array = block.interpret()
			$"../Cube".code = code

