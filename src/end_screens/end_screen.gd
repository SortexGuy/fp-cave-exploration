extends CanvasLayer
class_name EndScreen

func begin_sequence() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	await get_tree().create_timer(3).timeout
	get_tree().reload_current_scene()
