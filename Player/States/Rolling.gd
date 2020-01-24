extends State

var interrupted := false

func on_enter(cube) -> void:
	cube.moving = true
	
	interrupted = cube.check_wall(0)
	
	if interrupted:
		cube.play_anim("Cube-interrupt-roll")
	else:
		cube.linear_velocity = cube.get_dir() / 0.43
		cube.play_anim("Cube-roll")
	
	cube.tween.interpolate_callback(cube, 0.4, "check_tile")
	cube.tween.start()

func on_exit(cube) -> void:
	if not interrupted:
		cube.play_anim("Cube-land")

