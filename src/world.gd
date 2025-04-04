extends Node3D
class_name World

@onready var player: Player = %PlayerCharacter

func start() -> void:
	player.process_mode = Node.PROCESS_MODE_INHERIT
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	ModManager.mod_added.connect(on_mod_added)
	ModManager.mod_removed.connect(on_mod_removed)

func on_mod_added(mod: ModManager.Modifiers) -> void:
	if mod != ModManager.Modifiers.FlashlightHelmet:
		return
	get_world_3d().environment.fog_density = 0.15
	get_world_3d().environment.fog_height_density = .1

func on_mod_removed(mod: ModManager.Modifiers) -> void:
	if mod != ModManager.Modifiers.FlashlightHelmet:
		return
	get_world_3d().environment.fog_density = 0.2
	get_world_3d().environment.fog_height_density = .25
