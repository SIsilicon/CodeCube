extends ActionBlock

enum Direction {
	Left,
	Right
}

var string = "turn left"

func interpret() -> Array:
	var code := .interpret()
	if not code.empty() and code[0] == "already visited":
		return code
	
	code.append(string)
	
	if DEBUG_INTERPRET_STACK:
		prints("turn-block", string, self)
	
	var output_link := get_output_link()
	if output_link != -1:
		var next_block : ProgramBlock = program.get_socket(output_link, true).block
		code += next_block.interpret()
	
	return code

func set_direction(dir : int) -> void:
	$Option.selected = dir

func serialize(blocks : Array) -> Dictionary:
	var dict := .serialize(blocks)
	dict.dir = $Option.selected
	return dict

func deserialize(dict : Dictionary) -> void:
	.deserialize(dict)
	set_direction(dict.dir)

func _on_action_selected(ID : int) -> void:
	match ID:
		0: string = "turn left"
		1: string = "turn right"
	
	if program:
		program.code_dirty = true
