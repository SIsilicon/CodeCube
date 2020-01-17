extends ProgramBlock

func interpret() -> Array:
	var code := []
	
	if DEBUG_INTERPRET_STACK:
		prints("start-block", self)
	
	if link_keys.size() > 0:
		var next_block : ProgramBlock = link_handler.get_socket(link_keys[0], true).block
		code = next_block.interpret()
	
	return code
