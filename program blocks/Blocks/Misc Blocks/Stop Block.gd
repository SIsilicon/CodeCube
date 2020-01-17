extends ProgramBlock

func interpret() -> Array:
	if DEBUG_INTERPRET_STACK:
		prints("stop-block", self)
		print()
	
	return ["stop"]
