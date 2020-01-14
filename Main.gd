extends Spatial

onready var cube = $Cube

func _input(event : InputEvent) -> void:
	if event.is_action_pressed("ui_accept") and not cube.executing:
		$ProgramWorkshop.interpret()
		
		print(cube.code)
		if cube.code.size() == 0 or cube.code.find("stop") == -1:
			return
		
		cube.executing = true
		cube.execute()