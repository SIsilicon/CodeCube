extends ProgramBlock

func interpret() -> Array:
	var code := .interpret()
	if not code.empty() and code[0] == "already visited":
		return code
	
	code.append("wait " + str($SpinBox.value))
	
	if DEBUG_INTERPRET_STACK:
		prints("wait-block", self)
	
	var output_link := get_socket_link($Outflow)
	if output_link != -1:
		var next_block : ProgramBlock = program.get_socket(output_link, true).block
		code += next_block.interpret()
	
	return code


func serialize(blocks : Array) -> Dictionary:
	var dict := .serialize(blocks)
	dict.time = $SpinBox.value
	
	return dict

func deserialize(dict : Dictionary) -> void:
	.deserialize(dict)
	if dict.has("time"):
		$SpinBox.value = dict.time

func _on_SpinBox_value_changed(_value : float) -> void:
	if program:
		program.code_dirty = true
