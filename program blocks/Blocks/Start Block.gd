extends ProgramBlock

func _ready():
	_link_handler.register_socket($Outflow)

func interpret() -> Array:
	var code := []
	
	if link_keys.size() > 0:
		var next_block : ProgramBlock = _link_handler.sockets \
		[_link_handler.links[link_keys[0]][1]].block
		code = next_block.interpret()
	
	return code
