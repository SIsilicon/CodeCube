extends ActionBlock

func interpret() -> Array:
	var code := .interpret()
	if not code.empty() and code[0] == "already visited":
		return code
	
	code.append("jump")
	
	if DEBUG_INTERPRET_STACK:
		prints("jump-block", self)
	
	var output_link := get_output_link()
	if output_link != -1:
		var next_block : ProgramBlock = program.get_socket(output_link, true).block
		code += next_block.interpret()
	
	return code
