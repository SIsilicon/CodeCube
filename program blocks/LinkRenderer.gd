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
		var begin : Vector2 = points[i]
		var end : Vector2 = points[i+1]
		
		var curve_strength := begin.distance_to(end) * 0.35
		
		var curve := Curve2D.new()
		curve.add_point(begin, Vector2(), Vector2.DOWN * curve_strength)
		curve.add_point(end, Vector2.UP * curve_strength, Vector2())
		var curve_points := curve.tessellate()
		
		if i == points.size() - 2 and dragging_link:
			draw_polyline(curve_points, Color.burlywood, 1.5, true)
		else:
			draw_polyline(curve_points, Color.white, 1.5, true)
	
	draw_set_transform_matrix(get_global_transform().affine_inverse())
	if cut_line.size() > 1:
		draw_polyline(cut_line, Color.red, 1.2, true)

func _process(delta : float) -> void:
	update()
