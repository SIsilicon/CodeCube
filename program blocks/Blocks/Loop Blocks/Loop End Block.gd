extends ProgramBlock

func interpret() -> Array:
	var code := .interpret()
	if not code.empty() and code[0] == "already visited":
		return code
	
	code.append("loop end")
	
	if DEBUG_INTERPRET_STACK:
		prints("loop-end-block", self)
	
	var loop_link := get_socket_link($LoopBack)
	if loop_link != -1:
		var loop_socket : Panel = link_handler.get_socket(loop_link, true)
		var loop_block : ProgramBlock = loop_socket.block
		if loop_block is preload("Counter Loop Block.gd") and loop_socket == loop_block.get_node("LoopBack"):
			
			var output_link := get_socket_link($Outflow)
			if output_link != -1:
				var next_block : ProgramBlock = link_handler.get_socket(output_link, true).block
				code += next_block.interpret()
	
	return code
