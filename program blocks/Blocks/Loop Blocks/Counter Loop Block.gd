extends ProgramBlock

func interpret() -> Array:
	var code := .interpret()
	if not code.empty() and code[0] == "already visited":
		return code
	
	code.append("loop count " + str($SpinBox.value))
	
	if DEBUG_INTERPRET_STACK:
		prints("counter-loop-block", self)
	
	var output_link := get_socket_link($Outflow)
	if output_link != -1:
		var next_block : ProgramBlock = link_handler.get_socket(output_link, true).block
		code += next_block.interpret()
	
	return code

func set_count(value : int) -> void:
	$SpinBox.value = value

func serialize() -> PoolByteArray:
	var array := .serialize()
	array.append($SpinBox.value)
	return array
