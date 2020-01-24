extends State

func on_enter(cube) -> void:
	cube.linear_velocity = Vector3()
	cube.moving = false

func on_physics_process(cube, delta) -> void:
	if cube.tile:
		cube.translation = cube.translation.linear_interpolate(cube.tile.translation, 0.4)
	else:
		go_to("falling")

func on_exit(cube) -> void:
	if cube.tile:
		cube.translation = cube.tile.translation
