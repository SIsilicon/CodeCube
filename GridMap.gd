tool
extends Spatial

const SHOW_TILES_IN_EDITOR = false
const LVL_VERSION = 3

export(String, FILE, GLOBAL, "*.cclevel") var save_file

var tiles := {}
var spawn_tile : Tile

func _ready():
	load_level(save_file)
	if get_parent().sandbox_mode and not Engine.editor_hint:
		$"../MapEditor".update_wall_data()

func save_level(level : String) -> void:
	if weakref(spawn_tile).get_ref() == null:
		get_parent().show_error_msg("You need a spawn tile!")
		return
	
	var file := File.new()
	file.open(level, File.WRITE)
	file.store_8(LVL_VERSION)
	file.store_32(tiles.size())
	
	var list_offset = 5 # offset from stored values above.
	var list_size = tiles.size() * 4 # size of list
	
	var tile_offset = list_offset + list_size
	for i in tiles.size():
		var tile : Tile = tiles.values()[i]
		
		file.store_32(tile_offset)
		file.seek(tile_offset)
		
		file.store_8(tile.type)
		file.store_8(tile.translation.x)
		file.store_8(tile.translation.y)
		file.store_8(tile.translation.z)
		tile_offset += 4
		
		if tile.is_wall:
			file.store_8(tile.rotation_degrees.y / 90)
			tile_offset += 1
		
		file.seek(list_offset + (i + 1) * 4)
	file.close()

func load_level(level : String) -> void:
	var file := File.new()
	if not file.file_exists(level):
		return
	
	for pos in tiles.keys():
		remove_tile(tiles[pos])
	
	file.open(level, File.READ)
	
	var _version := file.get_8()
	var tile_num := file.get_32()
	
	var list_offset = 5
	for i in tile_num:
		file.seek(list_offset)
		var tile_offset := file.get_32()
		file.seek(tile_offset)
		
		var tile := preload("res://tiles/Tile.tscn").instance()
		tile.type = file.get_8()
		tile.translation = Vector3(
				Global.to_signed8(file.get_8()),
				Global.to_signed8(file.get_8()),
				Global.to_signed8(file.get_8())
		)
		
		add_tile(tile)
		if Engine.editor_hint and SHOW_TILES_IN_EDITOR:
			tile.owner = get_parent()
		if tile.is_wall:
			tile.rotation_degrees.y = Global.to_signed8(file.get_8()) * 90
		
		list_offset += 4
	
	file.close()

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
