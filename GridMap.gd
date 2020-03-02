tool
extends Spatial

const SHOW_TILES_IN_EDITOR = false
const LVL_VERSION = 3

export(String, FILE, GLOBAL, "*.cclevel") var save_file

var description := ""

var tiles := {}
var spawn_tile : Tile
var goal_tile : Tile

func _ready() -> void:
	if not save_file.empty():
		load_level_json(save_file)
		if get_parent().get("sandbox_mode") and not Engine.editor_hint and get_node_or_null("../MapEditor"):
			$"../MapEditor".update_wall_data()

func start_tile_codes() -> void:
	for tile in tiles.values():
		if tile.program:
			tile.program.interpret()
			tile.execute()

func save_level_json(level : String) -> void:
	if weakref(spawn_tile).get_ref() == null:
		get_parent().show_error_msg("You need a spawn tile!")
		return
	if weakref(goal_tile).get_ref() == null:
		get_parent().show_error_msg("You need a goal tile!")
		return
	
	var file := File.new()
	file.open(level, File.WRITE)
	
	var map_dict := {
		version = LVL_VERSION,
		description = self.description,
		tiles = [],
		programs = []
	}
	
	if get_viewport().get_camera():
		map_dict.camera = get_viewport().get_camera().global_transform
	
	var programs := []
	
	for tile in tiles.values():
		var tile_dict := {
			type = tile.type,
			pos = tile.translation,
		}
		if tile.program:
			if not programs.has(tile.program):
				programs.append(tile.program)
			tile_dict.program = programs.find(tile.program)
		
		if tile.is_wall:
			tile_dict.rotation = tile.rotation_degrees.y / 90
		
		map_dict.tiles.append(tile_dict)
	
	for program in programs:
		var program_json := CCProgramSaverLoader.save_as_json(program)
		map_dict.programs.append(program_json)
	
	file.store_line(Global.jsonify(map_dict))

func load_level_json(level : String, load_cam := false) -> void:
	var file := File.new()
	if not file.file_exists(level):
		return
	
	# Reset everything
	for pos in tiles.keys():
		remove_tile(tiles[pos])
	
	file.open(level, File.READ)
	var map_dict : Dictionary = Global.godotify(file.get_line())
	
	if load_cam and map_dict.has("camera") and get_viewport().get_camera():
		get_viewport().get_camera().global_transform = map_dict.camera
	
	if map_dict.has("description"):
		description = map_dict.description
	else:
		description = ""
	
	var programs := []
	for program_json in map_dict.programs:
		var program := CCProgramSaverLoader.load_from_json(program_json)
		programs.append(program)
	
	for tile_dict in map_dict.tiles:
		var tile := preload("res://tiles/Tile.tscn").instance()
		tile.type = tile_dict.type
		tile.translation = tile_dict.pos
		if tile_dict.has("program"):
			tile.program = programs[tile_dict.program]
		if tile_dict.has("rotation"):
			tile.rotation_degrees.y = tile_dict.rotation * 90
		
		add_tile(tile)
		
		if Engine.editor_hint and SHOW_TILES_IN_EDITOR:
			tile.owner = get_parent()

func remove_tile(tile : Tile, delete := true) -> void:
	remove_child(tile)
	tiles.erase(tile.translation)
	
	if tile == spawn_tile:
		spawn_tile = null
		for pos in tiles:
			if tiles[pos].type == Tile.Type.Spawn:
				spawn_tile = tiles[pos]
				break
	
	if tile == goal_tile:
		goal_tile = null
		for pos in tiles:
			if tiles[pos].type == Tile.Type.Goal:
				goal_tile = tiles[pos]
				break
	
	if delete:
		tile.queue_free()

func add_tile(tile : Tile, return_other_tile := false):
	var pos := tile.translation
	var other_tile : Tile
	if tiles.has(pos):
		other_tile = tiles[pos]
		remove_tile(other_tile, not return_other_tile)
	add_child(tile)
	tiles[pos] = tile
	
	if tile.type == Tile.Type.Spawn:
		spawn_tile = tile
	if tile.type == Tile.Type.Goal:
		goal_tile = tile
	
	if return_other_tile:
		return other_tile

func create_tile(type : int, pos : Vector3) -> StaticBody:
	var tile = preload("res://tiles/Tile.tscn").instance()
	tile.translation = pos
	tile.type = type
	add_tile(tile)
	
	return tile
