extends Node

@onready var main_menu: MainMenu = %MainMenu
@onready var hud: HeadsUpDisplay = %HeadsUpDisplay
@onready var world: World = %World

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	main_menu.play_button.pressed.connect(_play_button_pressed)
	main_menu.settings_button.pressed.connect(_settings_button_pressed)
	main_menu.exit_button.pressed.connect(_exit_button_pressed)

func _play_button_pressed() -> void:
	main_menu.tween_hide()
	hud.show()
	world.start()

func _settings_button_pressed() -> void:
	pass

func _exit_button_pressed() -> void:
	get_tree().quit()
