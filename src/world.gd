extends Node3D
class_name World

@onready var player: Player = %PlayerCharacter

func start() -> void:
	player.process_mode = Node.PROCESS_MODE_INHERIT
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
