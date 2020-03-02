extends BaseButton
class_name SoundButton

var sound_player := AudioStreamPlayer.new()

func _ready():
	sound_player.stream = preload("res://assets/button_click.wav")
	sound_player.bus = "SFX"
	connect("pressed", self, "play_sound")

func play_sound() -> void:
	sound_player.play()
