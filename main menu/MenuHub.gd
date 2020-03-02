extends Control

func _on_Play_pressed() -> void:
	get_parent().move_to(Vector2.UP)

func _on_Settings_pressed() -> void:
	get_parent().move_to(Vector2.RIGHT)
	$"../Settings".old_settings = $"../Settings".settings.duplicate(true)

func _on_Credits_pressed() -> void:
	get_parent().move_to(Vector2.DOWN)
	

func _on_Quit_pressed(button : String) -> void:
	match button:
		"confirm":
			get_tree().quit()
		"cancel":
			pass
		_:
			$QuitDialog.popup_centered()
