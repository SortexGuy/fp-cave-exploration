extends CanvasLayer
class_name PauseMenu

@onready var continue_button: Button = %ContinueButton
@onready var main_menu_button: Button = %MainMenuButton

func tween_hide() -> void:
	self.hide()

func tween_show() -> void:
	self.show()
