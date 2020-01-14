extends ProgramBlock

export var action := 0 setget set_action

var string = "move"

func _ready() -> void:
	_link_handler.register_socket($Inflow)
	_link_handler.register_socket($Outflow)

func interpret() -> Array:
	var code := [string]
	
	if link_keys.size() > 1:
		var next_block : ProgramBlock = _link_handler.sockets \
		[_link_handler.links[link_keys[1]][1]].block
		
		code += next_block.interpret()
	
	return code

func set_action(value : int) -> void:
	action = value
	$Option.selected = action

func _on_action_selected(ID : int) -> void:
	match ID:
		0: string = "move"
		1: string = "turn left"
		2: string = "turn right"
		3: string = "jump"
