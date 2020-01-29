extends Panel

const HALF = Vector3(0.5, 0.0, 0.5)

export(NodePath) var grid_map

onready var viewport_tex : ViewportTexture = $Viewport.get_texture()

var button_group := ButtonGroup.new()
var select_material := SpatialMaterial.new()

var expanded := false

var tile_to_add : Tile
var wall_mode := false
var walls := {}

var debug_walls := ImmediateGeometry.new()

func _ready():
	if not get_parent().sandbox_mode:
		return
	
	if not expanded:
		rect_position.x += rect_size.x
	
	select_material.flags_transparent = true
	select_material.flags_unshaded = true
	select_material.albedo_color = Color(1.0, 1.0, 0.6, 0.5)
	select_material.params_grow = true
	select_material.params_grow_amount = 0.04
	
	$Viewport.size = Vector2(1,1) * OS.window_size.x / 10.0
	$Viewport.render_target_update_mode = Viewport.UPDATE_ALWAYS
	yield(VisualServer, "frame_post_draw")
	for type in Tile.TYPE_COUNT:
		var tile := preload("res://tiles/Tile.tscn").instance()
		tile.type = type
		
		if not tile.is_wall || tile.type == Tile.Type.Wall:
			$Viewport.add_child(tile)
			yield(VisualServer, "frame_post_draw")
			$Viewport.remove_child(tile)
			
			var image : Image = viewport_tex.get_data()
			var texture := ImageTexture.new()
			texture.create_from_image(image, 0)
			
			var button := preload("res://MapFloorButton.tscn").instance()
			button.icon = texture
			button.text = tile.tile_name
			button.hint_tooltip = tile.tile_description
			button.group = button_group
			button.connect("pressed", self, "_on_Tile_button_pressed", [tile.type])
			$Scroll/VBox.add_child(button)
		
		tile.queue_free()
	$Viewport.render_target_update_mode = Viewport.UPDATE_DISABLED
	
	_on_Tile_button_pressed(0)
	
	if debug_walls:
		debug_walls.material_override = SpatialMaterial.new()
		debug_walls.material_override.flags_use_point_size = true
		debug_walls.material_override.params_point_size = 4.0
		add_child(debug_walls)

func _unhandled_input(event : InputEvent) -> void:
	if event is InputEventKey and not event.pressed and event.control:
		match event.scancode:
			KEY_S:
				$FileDialog.mode = FileDialog.MODE_SAVE_FILE
				$FileDialog.invalidate()
				$FileDialog.popup()
				get_tree().set_input_as_handled()
			KEY_O:
				$FileDialog.mode = FileDialog.MODE_OPEN_FILE
				$FileDialog.invalidate()
				$FileDialog.popup()
				get_tree().set_input_as_handled()
	
	if event is InputEventMouse:
		var viewport := get_viewport()
		var mouse := viewport.get_mouse_position()
		var ray := viewport.get_camera().project_ray_normal(mouse)
		var origin := viewport.get_camera().project_ray_origin(mouse)
		
		var plane := Plane(Vector3.UP, 0)
		var point := plane.intersects_ray(origin, ray)
		if point and tile_to_add:
			if wall_mode:
				point = (point - HALF).snapped(Vector3(1,1,1)) + HALF
			else:
				point = point.snapped(Vector3(1,1,1))
			
			tile_to_add.translation = point
			
			if Input.is_mouse_button_pressed(BUTTON_LEFT):
				if wall_mode:
					place_wall(point, false)
				else:
					var new_tile := tile_to_add.duplicate()
					new_tile.set_material_override(null)
					new_tile.translation = point
					_grid_map().add_tile(new_tile)
				
				get_tree().set_input_as_handled()
			elif Input.is_mouse_button_pressed(BUTTON_RIGHT):
				if wall_mode:
					place_wall(point, true)
				elif _grid_map().tiles.has(point):
					_grid_map().remove_tile(_grid_map().tiles[point])
				
				get_tree().set_input_as_handled()

func _process(delta : float) -> void:
	if debug_walls:
		debug_walls.clear()
		debug_walls.begin(Mesh.PRIMITIVE_POINTS)
		for pos in walls:
			debug_walls.add_vertex(Vector3(pos.x - 0.5, 1.1, pos.y - 0.5))
		debug_walls.end()

func place_wall(pos : Vector3, erase : bool) -> void:
	pos += HALF
	set_wall(pos.x, pos.z, not erase)
	
	for z in range(-1, 1):
		for x in range(-1, 1):
			var wall_flags := 0
			wall_flags |= get_wall(pos.x + x + 1, pos.z + z + 1) << 0
			wall_flags |= get_wall(pos.x + x, pos.z + z + 1) << 1
			wall_flags |= get_wall(pos.x + x + 1, pos.z + z) << 2
			wall_flags |= get_wall(pos.x + x, pos.z + z) << 3
			
			var type := -1
			var rot := 0
			
			if wall_flags == 15:
				type = Tile.Type.Wall
			elif wall_flags in [6, 9]:
				type = Tile.Type.WallPinch
			elif wall_flags in [3, 10, 12, 5]:
				type = Tile.Type.WallEdge
			elif wall_flags in [1, 2, 8, 4]:
				type = Tile.Type.WallCorner
			elif wall_flags in [14, 11, 7, 13]:
				type = Tile.Type.WallInvCorner
			
			if wall_flags in [1, 3, 7]:
				rot = 3
			elif wall_flags in [2, 10, 11]:
				rot = 2
			elif wall_flags in [8, 12, 14, 9]:
				rot = 1
			
			var tile_pos := pos + Vector3(x, 1, z)
			if type != -1:
				var tile : Tile = _grid_map().create_tile(type, tile_pos)
				tile.rotation_degrees.y = rot * 90
			elif _grid_map().tiles.has(tile_pos):
				_grid_map().remove_tile(_grid_map().tiles[tile_pos])

func get_wall(x : int, z : int) -> int:
	if walls.has(Vector2(x, z)):
		return walls[Vector2(x, z)]
	return 0

func set_wall(x : int, z : int, set : bool, additive := false) -> void:
	if set:
		walls[Vector2(x,z)] = 1
	elif not additive:
		walls.erase(Vector2(x,z))

func update_wall_data() -> void:
	walls = {}
	for key in _grid_map().tiles:
		var tile : Tile = _grid_map().tiles[key]
		if tile.is_wall:
			var pos := Vector2(tile.translation.x, tile.translation.z)
			
			var points := [0, 0, 0, 0]
			var Type := Tile.Type
			points[0] = tile.type in [Type.Wall, Type.WallInvCorner]
			points[1] = tile.type in [Type.Wall, Type.WallPinch]
			points[2] = tile.type in [Type.Wall, Type.WallEdge, Type.WallInvCorner]
			points[3] = tile.type in [Type.Wall, Type.WallEdge, Type.WallCorner, Type.WallInvCorner, Type.WallPinch]
			
			for i in range(tile.rotation_degrees.y / 90):
				var val = points.pop_back()
				points.push_front(val)
			
			set_wall(pos.x, pos.y, points[0], true)
			set_wall(pos.x, pos.y + 1, points[1], true)
			set_wall(pos.x + 1, pos.y + 1, points[2], true)
			set_wall(pos.x + 1, pos.y, points[3], true)

func _grid_map() -> Node:
	return get_node_or_null(grid_map)

func _on_Tile_button_pressed(tile_type : int) -> void:
	wall_mode = tile_type == Tile.Type.Wall
	
	var tile := preload("res://tiles/Tile.tscn").instance()
	tile.type = tile_type
	tile.set_material_override(select_material)
	add_child(tile)
	
	if tile_to_add:
		tile_to_add.queue_free()
		tile.translation = tile_to_add.translation
	tile_to_add = tile

func _on_WallToggle_toggled(button_pressed : bool) -> void:
	wall_mode = button_pressed

func _on_Drawer_toggled(button_pressed : bool) -> void:
	if not button_pressed:
		$Tween.interpolate_property(self, "rect_position", rect_position, rect_position + \
				Vector2(rect_size.x, 0), 0.3, Tween.TRANS_QUAD, Tween.EASE_OUT)
	else:
		$Tween.interpolate_property(self, "rect_position", rect_position, rect_position - \
				Vector2(rect_size.x, 0), 0.3, Tween.TRANS_QUAD, Tween.EASE_OUT)
	
	$Tween.start()
	expanded = button_pressed

func _on_Program_Drawer_pressed():
	if expanded:
		$Drawer.pressed = false

func _on_FileDialog_file_selected(path):
	if $FileDialog.mode == FileDialog.MODE_SAVE_FILE:
		_grid_map().save_level(_grid_map().save_file)
	elif $FileDialog.mode == FileDialog.MODE_OPEN_FILE:
		_grid_map().load_level(_grid_map().save_file)
		update_wall_data()
		get_parent()._on_Reset_pressed()
