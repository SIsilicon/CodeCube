tool
extends Node

const DYNAMIC_FONT_SIZE = false

var particles_enabled := true
var shadows_enabled := true

var background_music := AudioStreamPlayer.new()
var button_click := AudioStreamPlayer.new()

var updated_buttons_in_tree := false

func _init() -> void:
	pause_mode = PAUSE_MODE_PROCESS
	
	if DYNAMIC_FONT_SIZE:
		var font := preload("res://assets/fonts/Noto Sans UI/NotoSansUI.tres")
		font.size = OS.window_size.x / 70
	
	var dir := Directory.new()
	if not dir.dir_exists("user://programs"):
		dir.make_dir("user://programs")
	if not dir.dir_exists("user://levels"):
		dir.make_dir("user://levels")

func _enter_tree() -> void:
	if not Engine.editor_hint:
		var file := File.new()
		if file.file_exists("user://settings.json"):
			file.open("user://settings.json", File.READ)
			var settings : Dictionary = godotify(file.get_line())
			OS.window_fullscreen = settings.graphics.Fullscreen.value

		button_click.stream = preload("res://assets/button_click.wav")
		button_click.bus = "SFX"
		add_child(button_click)
		
		background_music.stream = preload("res://assets/calm_ambient.ogg")
		background_music.bus = "Music"
		add_child(background_music)
		
		get_tree().connect("tree_changed", self, "_on_tree_changed", [get_tree().root], CONNECT_DEFERRED)

func _process(_delta : float) -> void:
	updated_buttons_in_tree = false

func _on_tree_changed(node : Node) -> void:
	if updated_buttons_in_tree:
		return
	
	if node is BaseButton and not node.is_connected("pressed", self, "play_button_click"):
		node.connect("pressed", self, "play_button_click", [null])
	elif node is Slider and not node.is_connected("value_changed", self, "play_button_click"):
		node.connect("value_changed", self, "play_button_click")
	
	for child in node.get_children():
		_on_tree_changed(child)
	
	if node == get_tree().root:
		updated_buttons_in_tree = true

func play_button_click(_dummy) -> void:
	button_click.play()

func render_viewport(viewport : Viewport) -> void:
	if not viewport.is_inside_tree():
		return
	
	var viewports := _get_viewports(get_tree().root)
	var update_modes := []
	for viewport in viewports:
		update_modes.append(viewport.render_target_update_mode)
		viewport.render_target_update_mode = Viewport.UPDATE_DISABLED
	
	for viewport in _get_viewports(viewport):
		viewport.render_target_update_mode = Viewport.UPDATE_ALWAYS
	
	VisualServer.request_frame_drawn_callback(self, "_finish_render_viewport", [viewports, update_modes])
	VisualServer.force_draw(false)

func _finish_render_viewport(user_data) -> void:
	var viewports = user_data[0]
	var update_modes = user_data[1]
	for i in viewports.size():
		viewports[i].render_target_update_mode = update_modes[i]

func _get_viewports(node : Node) -> Array:
	var viewports := []
	
	if node is Viewport:
		viewports.append(node)
	
	for child in node.get_children():
		viewports += _get_viewports(child)
	
	return viewports

# Below Code is a modified version of Zylann's code from
# https://github.com/Zylann/godot_texture_generator/blob/master/addons/zylann.tgen/util/jsonify.gd

func jsonify(data, is_json := true):
	if is_json:
		return to_json(jsonify(data, not is_json))
	
	match typeof(data):
		
		TYPE_STRING, \
		TYPE_BOOL, \
		TYPE_INT, \
		TYPE_REAL:
			return data
		
		TYPE_ARRAY:
			for i in len(data):
				data[i] = jsonify(data[i], is_json)
			return data
		
		TYPE_DICTIONARY:
			for k in data:
				data[k] = jsonify(data[k], is_json)
			return data
		
		TYPE_VECTOR2:
			return {
				"x": data.x,
				"y": data.y
			}
		
		TYPE_COLOR:
			return {
				"r": data.r,
				"g": data.g,
				"b": data.b,
				"a": data.a
			}
		
		TYPE_RECT2:
			return {
				"x": data.position.x,
				"y": data.position.y,
				"w": data.size.x,
				"h": data.size.y
			}
		
		TYPE_VECTOR3:
			return {
				"x": data.x,
				"y": data.y,
				"z": data.z
			}
		
		TYPE_TRANSFORM:
			return {
				"x": jsonify(data.basis.x, is_json),
				"y": jsonify(data.basis.y, is_json),
				"z": jsonify(data.basis.z, is_json),
				"origin": jsonify(data.origin, is_json)
			}
		
		_:
			# Unhandled data type
			printerr("Unhandled data: ", data, " of type ", typeof(data))
			assert(false)

func godotify(data, is_json := true):
	if is_json:
		return godotify(parse_json(data), not is_json)
	
	match typeof(data):
		
		TYPE_ARRAY:
			for i in len(data):
				data[i] = godotify(data[i], is_json)
			return data
		
		TYPE_DICTIONARY:
			
			match len(data):
				2:
					if data.has("x") and data.has("y"):
						return Vector2(data.x, data.y)
				3:
					if data.has("x") and data.has("y") and data.has("z"):
						return Vector3(data.x, data.y, data.z)
				4:
					if data.has("r") and data.has("g") and data.has("b") and data.has("a"):
						return Color(data.r, data.g, data.b, data.a)
					
					elif data.has("x") and data.has("y") and data.has("w") and data.has("h"):
						return Rect2(data.x, data.y, data.w, data.h)
					
					elif data.has("x") and data.has("y") and data.has("z") and data.has("origin"):
						return Transform(
								godotify(data.x, is_json),
								godotify(data.y, is_json),
								godotify(data.z, is_json),
								godotify(data.origin, is_json)
						)
			
			for k in data:
				data[k] = godotify(data[k], is_json)
			return data
		
		_:
			return data
