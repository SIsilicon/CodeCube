extends State

var interrupted := false

func on_enter(cube) -> void:
	interrupted = cube.check_wall(0)
	cube.moving = true
	
	if interrupted:
		cube.play_anim("Cube-interrupt-roll")
	else:
		cube.play_anim("Cube-jump-roll")
		cube.linear_velocity = cube.get_dir() * 4.0
		cube.linear_velocity.y = 15.0

func on_physics_process(cube, delta) -> void:
	cube.linear_velocity.y -= 40.0 * delta
	cube.linear_velocity -= cube.linear_velocity * delta
	cube.check_tile()

func on_exit(cube) -> void:
	if not interrupted:
		cube.play_anim("Cube-land")
