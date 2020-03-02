extends State

func on_enter(cube) -> void:
	cube.moving = true
	cube.play_anim("Cube-turn")
	if cube.get_tile():
		cube.linear_velocity = cube.get_tile().linear_velocity
	
	cube.tween.interpolate_callback(cube, 0.33, "check_tile")
	cube.tween.start()

func on_physics_process(cube, delta : float) -> void:
	cube.rotation.y += cube.turn_direction * delta / 0.33 * PI/2

func on_exit(cube) -> void:
	cube.rotation.y = stepify(cube.rotation.y, PI/2)
	cube.play_anim("Cube-land")
