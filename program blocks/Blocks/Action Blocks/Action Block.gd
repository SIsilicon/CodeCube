extends ProgramBlock
class_name ActionBlock

func get_output_link() -> int:
	for link_key in link_keys:
		if program.get_socket(link_key, false) == $Outflow:
			return link_key
	return -1
