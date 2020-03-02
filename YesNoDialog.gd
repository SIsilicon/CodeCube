tool
extends PopupPanel

# Button is either 'confirm' or 'cancel'
signal pressed(button)

export(String, MULTILINE) var dialog := "" setget set_dialog

func _ready() -> void:
	set_dialog(dialog)

func set_dialog(value : String) -> void:
	dialog = value
	if has_node("Control/Label"):
		$Control/Label.text = dialog

func _on_Yes_pressed() -> void:
	emit_signal("pressed", "confirm")
	hide()

func _on_No_pressed() -> void:
	emit_signal("pressed", "cancel")
	hide()
