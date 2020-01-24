extends State

func on_enter(cube) -> void:
	cube.moving = true
	cube.play_anim("Cube-roll-fall")
	cube.linear_velocity.y = -3.0

func on_physics_process(cube, delta) -> void:
	cube.linear_velocity.y -= 40.0 * delta
	cube.linear_velocity -= cube.linear_velocity * delta
	
	cube.check_tile()

func on_exit(cube) -> void:
	cube.play_anim("Cube-land")
