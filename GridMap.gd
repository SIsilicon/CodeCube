tool
extends Spatial

const SHOW_TILES_IN_EDITOR = false
const LVL_VERSION = 3

export(String, FILE, GLOBAL, "*.cclevel") var save_file

var tiles := {}
var spawn_tile : Tile

func _ready() -> void:
	load_level_json(save_file)
	if get_parent().sandbox_mode and not Engine.editor_hint:
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
	
	var file := File.new()
	file.open(level, File.WRITE)
	
	var map_dict := {
		version = LVL_VERSION,
		tiles = [],
		programs = []
	}
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

func load_level_json(level : String) -> void:
	var file := File.new()
	if not file.file_exists(level):
		return
	
	for pos in tiles.keys():
		remove_tile(tiles[pos])
	
	file.open(level, File.READ)
	var map_dict : Dictionary = Global.godotify(file.get_line())
	
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
		for pos in tiles:
			if tiles[pos].type == Tile.Type.Spawn:
				spawn_tile = tile
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
	
	if return_other_tile:
		return other_tile

func create_tile(type : int, pos : Vector3) -> StaticBody:
	var tile = preload("res://tiles/Tile.tscn").instance()
	tile.translation = pos
	tile.type = type
	add_tile(tile)
	
	return tile
