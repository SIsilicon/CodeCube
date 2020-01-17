tool
extends Control

var dragging_link := false
var begin_vec := Vector2()
var end_vec := Vector2()

var cut_line := []

func _draw() -> void:
	var rect := Rect2()
	
	var points := []
	
	for link in get_parent().links:
		var socket_a = get_parent().get_socket(link, false)
		var socket_b = get_parent().get_socket(link, true)
		
		var point_a : Vector2 = socket_a.get_position()
		var point_b : Vector2 = socket_b.get_position()
		
		rect = rect.expand(point_a)
		rect = rect.expand(point_b)
		points.append(point_a)
		points.append(point_b)
		
	if dragging_link:
		rect = rect.expand(begin_vec)
		rect = rect.expand(end_vec)
		points.append(begin_vec)
		points.append(end_vec)
	
	rect_size = rect.size
	rect_position = rect.position
	
	draw_set_transform(-rect_position, 0, Vector2(1, 1))
	for i in range(0, points.size(), 2):
		var begin = points[i]
		var end = points[i+1]
		
		if i == points.size() - 2 and dragging_link:
			draw_line(begin, end, Color.burlywood, 1.5, true)
		else:
			draw_line(begin, end, Color.white, 1.5, true)
	
	draw_set_transform_matrix(get_global_transform().affine_inverse())
	if cut_line.size() > 1:
		draw_polyline(cut_line, Color.red, 1.2, true)

func _process(delta : float) -> void:
	update()
