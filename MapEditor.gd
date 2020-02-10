extends Panel

const HALF = Vector3(0.5, 0.0, 0.5)
const DEBUG_WALLS = false

export(NodePath) var grid_map

onready var viewport_tex : ViewportTexture = $Viewport.get_texture()

var button_group := ButtonGroup.new()
var select_material := SpatialMaterial.new()

var expanded := false

var tile_to_add : Tile
var painting := false
var erasing := false
var wall_mode := false
var walls := {}
var edited_points := []

var undo_redo := UndoRedo.new()

var debug_walls : ImmediateGeometry

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
	
	if DEBUG_WALLS and OS.is_debug_build():
		debug_walls = ImmediateGeometry.new()
		debug_walls.material_override = SpatialMaterial.new()
		debug_walls.material_override.flags_use_point_size = true
		debug_walls.material_override.params_point_size = 4.0
		add_child(debug_walls)

func _unhandled_input(event : InputEvent) -> void:
	if not get_node("../ProgramWorkshop").expanded:
		
		if event is InputEventMouseMotion:
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
			
			if not edited_points.has(point) and (painting or erasing):
				if painting:
					if wall_mode:
						place_wall(point, false, true)
					else:
						var new_tile := tile_to_add.duplicate()
						new_tile.set_colliding(true)
						new_tile.set_material_override(null)
						new_tile.scale = Vector3(1, 1, 1)
						new_tile.translation = point
						if not _grid_map().tiles.has(point + Vector3.UP): # checking for wall
							var other_tile = _grid_map().add_tile(new_tile, true)
							
							undo_redo.add_do_method(_grid_map(), "add_tile", new_tile, true)
							if other_tile:
								undo_redo.add_undo_method(_grid_map(), "add_tile", other_tile, true)
							else:
								undo_redo.add_undo_method(_grid_map(), "remove_tile", new_tile, false)
							
					
					get_tree().set_input_as_handled()
				elif erasing:
					if wall_mode:
						place_wall(point, true, true)
					elif _grid_map().tiles.has(point):
						var other_tile : Tile = _grid_map().tiles[point]
						
						_grid_map().remove_tile(other_tile, false)
						undo_redo.add_do_method(_grid_map(), "remove_tile", other_tile, false)
						undo_redo.add_undo_method(_grid_map(), "add_tile", other_tile, true)
					
					get_tree().set_input_as_handled()
				
				edited_points.append(point)
		
		if event is InputEventMouseButton:
			if event.button_index == BUTTON_LEFT:
				painting = event.pressed
			elif event.button_index == BUTTON_RIGHT:
				erasing = event.pressed
			else:
				return
			
			if event.pressed:
				undo_redo.create_action("Paint Tiles/Walls" if painting else "Erase Tiles/Walls")
				var fake_event := InputEventMouseMotion.new()
				_unhandled_input(fake_event)
			else:
				undo_redo.commit_action()
				edited_points.clear()

func _input(event : InputEvent) -> void:
	if event.is_action_pressed("undo"):
		undo_redo.undo()
		accept_event()
	elif event.is_action_pressed("redo"):
		undo_redo.redo()
		accept_event()

func _process(_delta : float) -> void:
	if debug_walls:
		debug_walls.clear()
		debug_walls.begin(Mesh.PRIMITIVE_POINTS)
		for pos in walls:
			debug_walls.add_vertex(Vector3(pos.x - 0.5, 1.1, pos.y - 0.5))
		debug_walls.end()

func place_wall(pos : Vector3, erase : bool, set_undo_redo := false) -> void:
	pos += HALF
	
	if not erase:
		for i in range(0, 4):
			# warning-ignore:integer_division
			var tile_pos := Vector3(i % 2 - 1, 0.0, i / 2 - 1)
			tile_pos += pos
			if _grid_map().tiles.has(tile_pos):
				return
	
	var prev_wall := get_wall(pos.x, pos.z)
	set_wall(pos.x, pos.z, not erase)
	
	if prev_wall != get_wall(pos.x, pos.z) and set_undo_redo:
		undo_redo.add_do_method(self, "place_wall", pos - HALF, erase)
		undo_redo.add_undo_method(self, "place_wall", pos - HALF, not erase)
	
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
			
# warning-ignore:unused_variable
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
	tile.set_colliding(false)
	add_child(tile)
	
	if tile_to_add:
		tile_to_add.queue_free()
		tile.translation = tile_to_add.translation
	tile_to_add = tile
	
	if wall_mode:
		tile_to_add.scale = Vector3(2,1,2)

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
		_grid_map().save_level(path)
	elif $FileDialog.mode == FileDialog.MODE_OPEN_FILE:
		_grid_map().load_level(path)
		undo_redo.clear_history()
		update_wall_data()
		get_parent()._on_Reset_pressed()

func _on_Save_pressed():
	if expanded:
		if not _grid_map().spawn_tile:
			get_parent().show_error_msg("This level doesn't have a spawn tile!")
			return
		
		$FileDialog.mode = FileDialog.MODE_SAVE_FILE
		$FileDialog.invalidate()
		$FileDialog.popup_centered()

func _on_Open_pressed():
	if expanded:
		$FileDialog.mode = FileDialog.MODE_OPEN_FILE
		$FileDialog.invalidate()
		$FileDialog.popup_centered()

func _on_visibility_changed():
	if tile_to_add:
		tile_to_add.visible = visible
