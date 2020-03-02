extends State

func on_enter(cube) -> void:
	$"../../Step".play()
	
	cube.play_anim("Cube-teleport")
	cube.linear_velocity = Vector3()
	cube.moving = true
	
	cube.tween.interpolate_callback(cube, 0.5, "hide")
	cube.tween.interpolate_property($"../../ColorRect", "color", Color(0, 1, 0, 0.6),
			Color.transparent, 0.7, Tween.TRANS_LINEAR, Tween.EASE_OUT, 0.5)
	cube.tween.interpolate_callback(cube, 1.2, "queue_free")
	cube.tween.start()
	
	cube.face_state = 2

func on_exit(cube) -> void:
	cube.face_state = 0
