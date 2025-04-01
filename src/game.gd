extends Node

@onready var main_menu: MainMenu = %MainMenu
@onready var hud: HeadsUpDisplay = %HeadsUpDisplay
@onready var world: World = %World
@onready var pause_menu: PauseMenu = %PauseMenu

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	main_menu.play_button.pressed.connect(_play_button_pressed)
	main_menu.settings_button.pressed.connect(_settings_button_pressed)
	main_menu.exit_button.pressed.connect(_exit_button_pressed)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode == KEY_ESCAPE:
		if event.pressed and not get_tree().paused:
			pause_menu.tween_show()
			get_tree().paused = true
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _play_button_pressed() -> void:
	main_menu.tween_hide()
	hud.tween_show()
	world.start()

func _settings_button_pressed() -> void:
	pass

func _exit_button_pressed() -> void:
	get_tree().quit()

func _on_continue_button_pressed() -> void:
	get_tree().paused = false
	pause_menu.tween_hide()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _on_main_menu_button_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
