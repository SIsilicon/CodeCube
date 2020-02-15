extends Node

const DYNAMIC_FONT_SIZE = false

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

func to_signed8(val : int) -> int:
	if val > 0x7F:
		return -(~val & 0xFF) - 1
	return val

func to_signed16(val : int) -> int:
	if val > 0x7FFF:
		return -(~val & 0xFFFF) - 1
	return val

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
				data[i] = jsonify(data[i], false)
			return data
		
		TYPE_DICTIONARY:
			for k in data:
				data[k] = jsonify(data[k], false)
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
			
			for k in data:
				data[k] = godotify(data[k], is_json)
			return data
		
		_:
			return data
