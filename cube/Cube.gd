extends Spatial

signal finished_moving

var pos := Vector2(0, 4)
export var speed_factor := 1.0
export var manual_control := false

export(NodePath) var grid_map

var moving := false setget set_moving
var executing := false

onready var anim_player := $AnimationPlayer

export var code := [
	"move",
	"move",
	"turn left",
	"move",
	"jump",
	"move"
]

func execute() -> void:
	var line_num := 0
	
	while true:
		var expression : String = code[line_num]
		match expression:
			"move":
				move()
			"turn left":
				turn(true)
			"turn right":
				turn(false)
			"jump":
				jump()
			"stop":
				return
		
		yield(self, "finished_moving")
		line_num += 1

func _ready():
	translation = translation.round()
	rotation.y = stepify(rotation.y, PI/2)
	pos = Vector2(translation.x, translation.z)

func _process(delta : float) -> void:
	if not executing:
		if Input.is_action_just_pressed("toggle"):
			manual_control = not manual_control
	
	if not moving:
		if manual_control:
			if Input.is_action_pressed("ui_up"):
				move()
			elif Input.is_action_just_pressed("jump"):
				jump()
			elif Input.is_action_pressed("ui_left"):
				turn(true)
			elif Input.is_action_pressed("ui_right"):
				turn(false)
	
	translation = Vector3(pos.x, 0.0, pos.y)

func _physics_process(delta : float) -> void:
	$CollisionShape.transform = $Cube.transform

func prep_move() -> void:
	anim_player.playback_speed = speed_factor
	$Tween.stop_all()
	pos = pos.round()
	rotation.y = stepify(rotation.y, PI/2)
	self.moving = true

func move() -> void:
	prep_move()
	
	if check_wall(get_dir()):
		play_anim("Cube-interrupt-roll")
	else:
		play_anim("Cube-roll")
		$Tween.interpolate_callback(self, 0.4 / speed_factor, "check_tile")
		$Tween.interpolate_property(self, "pos", pos, pos + get_dir(),
				0.4 / speed_factor, Tween.TRANS_LINEAR, Tween.EASE_IN)
	
	$Tween.start()

func jump() -> void:
	prep_move()
	
	play_anim("Cube-jump-roll")
	$Tween.interpolate_callback(self, 0.5 / speed_factor, "check_tile")
	$Tween.interpolate_property(self, "pos", pos, pos + get_dir() * 2.0,
			0.55 / speed_factor, Tween.TRANS_LINEAR, Tween.EASE_IN)
	$Tween.start()

func turn(left : bool) -> void:
	prep_move()
	
	var new_rotation := rotation
	new_rotation.y += (2.0 * float(left) - 1.0) * PI/2
	
	play_anim("Cube-turn")
	$Tween.interpolate_callback(self, 0.34 / speed_factor, "check_tile")
	$Tween.interpolate_property(self, "rotation", rotation, new_rotation,
			0.34 / speed_factor, Tween.TRANS_LINEAR, Tween.EASE_IN)
	$Tween.start()

func die() -> void:
	var explosion : Spatial = preload("res://particle systems/Explode.tscn").instance()
	explosion.translation = $Cube.global_transform.origin
	get_parent().add_child(explosion)
	queue_free()

func teleport() -> void:
	anim_player.playback_speed = 1.0
	play_anim("Cube-teleport")
	moving = true
	
	$Tween.interpolate_callback(self, 0.5, "queue_free")
	$Tween.start()

func play_anim(anim : String) -> void:
	if anim_player.is_playing() and anim_player.current_animation == anim:
		anim_player.seek(0.0, true)
	else:
		anim_player.play(anim)

func floor_position() -> Vector3:
	return translation * Vector3(1, 0, 1)

func get_tile(position : Vector3) -> int:
	if get_node_or_null(grid_map):
		var map : GridMap = get_node(grid_map)
		var grid_pos := map.world_to_map(position.round())
		return map.get_cell_item(grid_pos.x, 0, grid_pos.z)
	else:
		return 0

func check_wall(dir : Vector2) -> bool:
	if get_node_or_null(grid_map):
		var map : GridMap = get_node(grid_map)
		var grid_pos := map.world_to_map(floor_position().round() + Vector3(dir.x, 0.0, dir.y))
		return map.get_cell_item(grid_pos.x, 1, grid_pos.z) != -1
	else:
		return false

func check_tile() -> void:
	var tile := get_tile(floor_position())
	
	if check_wall(Vector2()):
		die()
		return
	
	match tile:
		-1: die() # no tile, no life
		6: die() # spikes
		5: teleport() # goal

func get_dir() -> Vector2:
	return Vector2(0, -1).rotated(-rotation.y).round()

func set_moving(value : bool) -> void:
	if moving != value and value == false and anim_player.current_animation != "Cube-teleport":
		moving = value
		emit_signal("finished_moving")
		return
	moving = value

