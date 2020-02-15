extends ProgramBlock

func interpret() -> Array:
	var code := []
	
	if DEBUG_INTERPRET_STACK:
		prints("start-block", self)
	
	if link_keys.size() > 0:
		var socket = program.get_socket(link_keys[0], true)
		var next_block : ProgramBlock = socket.block
		code = next_block.interpret()
	
	return code
