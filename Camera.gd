extends Spatial

export(float) var drag_speed
var enable_drag := true

var zoom := 1.0

var dragging = false
var drag_offset := Vector2()

var shake := 0.0

onready var camera := $"../Camera"

func refocus() -> void:
	if $"..".cube_exists():
		drag_offset = Vector2.ZERO
		zoom = 1.0

func _unhandled_input(event : InputEvent) -> void:
	if enable_drag:
		if event is InputEventMouseButton:
			if event.button_index == BUTTON_MIDDLE:
				dragging = event.pressed
				get_tree().set_input_as_handled()
			elif event.button_index == BUTTON_WHEEL_UP:
				zoom /= 1.1
				get_tree().set_input_as_handled()
			elif event.button_index == BUTTON_WHEEL_DOWN:
				zoom *= 1.1
				get_tree().set_input_as_handled()
		zoom = clamp(zoom, 0.3, 5.0)
		if event is InputEventMouseMotion and dragging:
			drag_offset += event.relative * 0.01 * drag_speed
			get_tree().set_input_as_handled()

func _process(_delta : float) -> void:
	var new_cam_trans := Transform().translated(Vector3(0, 6, -4) * zoom)
	var target : Vector3 = $"..".cube.translation if $"..".cube_exists() else Vector3()
	target.y = max(target.y, -2.0)
	new_cam_trans = new_cam_trans.translated(target)
	new_cam_trans = new_cam_trans.looking_at(target, Vector3.UP)

	if enable_drag:
		new_cam_trans.origin.x += drag_offset.x
		new_cam_trans.origin.z += drag_offset.y
#	elif $"..".sandbox_mode:
#		drag_offset = Vector2()
#		zoom = 1.0
	
	transform = new_cam_trans
	
	shake *= 0.6
	camera.h_offset = (randf() * 2.0 - 1.0) * shake
	camera.v_offset = (randf() * 2.0 - 1.0) * shake
