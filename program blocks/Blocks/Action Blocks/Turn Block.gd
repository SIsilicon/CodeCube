extends ActionBlock

enum Direction {
	Left,
	Right
}

var string = "turn left"

func interpret() -> Array:
	var code := [string]
	
	if DEBUG_INTERPRET_STACK:
		prints("turn-block", string, self)
	
	var output_link := get_output_link()
	if output_link != -1:
		var next_block : ProgramBlock = link_handler.get_socket(output_link, true).block
		code += next_block.interpret()
	
	return code

func set_direction(dir : int) -> void:
	$Option.selected = dir

func serialize() -> PoolByteArray:
	var array := .serialize()
	array.append($Option.selected)
	return array

func _on_action_selected(ID : int) -> void:
	match ID:
		0: string = "turn left"
		1: string = "turn right"
