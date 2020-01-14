extends ProgramBlock

func _ready() -> void:
	_link_handler.register_socket($Inflow)

func interpret() -> Array:
	return ["stop"]
