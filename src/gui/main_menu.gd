extends CanvasLayer
class_name MainMenu

@onready var play_button: Button = %PlayButton
@onready var settings_button: Button = %SettingsButton
@onready var exit_button: Button = %ExitButton

func _ready() -> void:
	play_button.grab_focus()

func tween_hide() -> void:
	self.hide()

func tween_show() -> void:
	self.show()
