extends LoopBlock

func interpret() -> Array:
	var code := .interpret()
	if not code.empty() and code[0] == "already visited":
		return code
	
	code.append("loop forever")
	
	if DEBUG_INTERPRET_STACK:
		prints("infinite-loop-block", self)
	
	var output_link := get_socket_link($Outflow)
	if output_link != -1:
		var next_block : ProgramBlock = program.get_socket(output_link, true).block
		code += next_block.interpret()
	
	return code
