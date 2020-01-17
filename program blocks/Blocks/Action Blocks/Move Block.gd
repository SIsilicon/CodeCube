extends ActionBlock

func interpret() -> Array:
	var code := ["move"]
	
	if DEBUG_INTERPRET_STACK:
		prints("move-block", self)
	
	var output_link := get_output_link()
	if output_link != -1:
		var next_block : ProgramBlock = link_handler.get_socket(output_link, true).block
		code += next_block.interpret()
	
	return code
