tool
extends Control

var links := {}
var dragging_link := false
var begin_vec := Vector2()
var end_vec := Vector2()

func _draw() -> void:
	var rect := Rect2()
	
	var points := []
	
	for link in links:
		var socket_a = get_parent().sockets[links[link][0]]
		var socket_b = get_parent().sockets[links[link][1]]
		
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
	
	for i in range(0, points.size(), 2):
		var begin = points[i] - rect_position
		var end = points[i+1] - rect_position
		
		if i == points.size() - 2 and dragging_link:
			draw_line(begin, end, Color.burlywood, 1.5, true)
		else:
			draw_line(begin, end, Color.white, 1.5, true)

func _process(delta : float) -> void:
	update()
