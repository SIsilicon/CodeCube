extends State

func on_enter(cube) -> void:
	cube.transform = cube.tile.transform
#	pos = Vector2(transform.origin.x, transform.origin.z)
	
	cube.play_anim("Cube-turn")
	cube.tween.stop_all()
	cube.tween.interpolate_property(cube, "scale", Vector3(), Vector3(1,1,1), 0.2, Tween.TRANS_BACK, Tween.EASE_OUT)
	cube.tween.interpolate_callback(fsm, 0.33, "go_to", "idle")
	cube.tween.start()

func on_exit(cube) -> void:
	cube.play_anim("Cube-land")
