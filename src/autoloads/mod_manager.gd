extends Node

enum Modifiers {
	Pickaxe,
	FlashlightHelmet,
	GasMask,
	Piolet,
	Harness,
	Camera,
}

signal mod_added(mod: Modifiers)
signal mod_removed(mod: Modifiers)

#func toggle_modifier(mod: Modifiers) -> void:
	#if mod in active_modifiers:
		#active_modifiers.erase(mod)
	#else:
		#active_modifiers.append(mod)
#
#func is_mod_active(mod: Modifiers) -> bool:
	#return mod in active_modifiers
