tool
extends Node

const VERSION = 6

func _init() -> void:
	pause_mode = PAUSE_MODE_PROCESS

func save(path : String, program : CCProgram) -> int:
	var file := File.new()
	file.open(path, File.WRITE)
	if file.get_error():
		return file.get_error()
	
	file.store_line(save_as_json(program))
	file.close()
	return OK

func save_as_json(program : CCProgram) -> String:
	var program_json := {}
	program_json.version = VERSION
	program_json.type = program.type
	
	program_json.blocks = []
	for block in program.blocks:
		program_json.blocks.append(block.serialize(program.available_blocks))
	
	program_json.links = program.links
	
	return Global.jsonify(program_json)

func load(path : String):
	var file := File.new()
	if not file.file_exists(path):
		return ERR_FILE_NOT_FOUND
	
	file.open(path, File.READ)
	if file.get_error():
		return file.get_error()
	
	var program = load_from_json(file.get_line())
	file.close()
	
	return program


func load_from_json(json : String) -> CCProgram:
	var program_dict : Dictionary = Global.godotify(json)
	var program := CCProgram.new(program_dict.type)
	
	for block_dict in program_dict.blocks:
		var available_blocks := program.available_blocks
		if program_dict.version == 5:
			available_blocks = [
				"res://program blocks/Blocks/Misc Blocks/Start Block",
				"res://program blocks/Blocks/Misc Blocks/Stop Block",
				"res://program blocks/Blocks/Loop Blocks/Counter Block",
				"res://program blocks/Blocks/Loop Blocks/Loop End Block",
				"res://program blocks/Blocks/Loop Blocks/Infinite Block",
			] + program.get_specific_blocks()
		
		var block_path : String = (available_blocks)[block_dict.type]
		
		var block : ProgramBlock = load(block_path + ".tscn").instance()
		block.deserialize(block_dict)
		
		# Setup sockets
		get_viewport().add_child(block)
		for socket in block.get_sockets():
			socket.block = block
		get_viewport().remove_child(block)
		
		program.add_block(block)
	
	for link in program_dict.links:
		program.add_link(program_dict.links[link][0], program_dict.links[link][1], int(link))
		program.link_key = max(program.link_key, int(link))
	program.link_key += 1
	
	return program
