tool
extends Control

export var links := {}
var link_key := 0

var dragging_link := false
var dragging_outflow := false
var temp_socket_a : Control
var temp_socket_b : Control

onready var renderer = $LinkRenderer

var socket_count := 0
var sockets := {}

func _ready() -> void:
	if links.size() > 0:
		for link in links:
			link[0].block.link_keys.append(link_key)
			link[1].block.link_keys.append(link_key)
			
			link_key += 1
		renderer.links = links

func _input(event : InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT and not event.pressed:
		dragging_link = false
	
	if event is InputEventKey and event.scancode == KEY_C and event.control:
		OS.clipboard = str(links)

func _process(delta : float) -> void:
	renderer = $LinkRenderer
	
	renderer.dragging_link = dragging_link
	
	if dragging_link:
		if dragging_outflow:
			renderer.begin_vec = temp_socket_a.get_position()
			renderer.end_vec = get_local_mouse_position()
		else:
			renderer.begin_vec = get_local_mouse_position()
			renderer.end_vec = temp_socket_a.get_position()
	
	if temp_socket_a and temp_socket_b and temp_socket_a != temp_socket_b:
		var in_block : Control
		var out_block : Control
		
		if temp_socket_a.type == 0: # is it an inflow?
			in_block = temp_socket_a.get_parent()
			out_block = temp_socket_b.get_parent()
			
			var temp_handle := temp_socket_b
			temp_socket_b = temp_socket_a
			temp_socket_a = temp_handle
		else:
			in_block = temp_socket_b.get_parent()
			out_block = temp_socket_a.get_parent()
		
		in_block.link_keys.append(link_key)
		out_block.link_keys.append(link_key)
		
		links[link_key] = [temp_socket_a.id, temp_socket_b.id]
		link_key += 1
		renderer.links = links
		
		temp_socket_a = null
		temp_socket_b = null

func register_socket(temp_socket_a : Control) -> void:
	temp_socket_a.id = socket_count
	sockets[socket_count] = temp_socket_a
	socket_count += 1
