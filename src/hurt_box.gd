extends Area3D
class_name HurtBox

var player: Player : 
	set (p):
		player = p
	get: 
		return player
signal take_damage(dmg: float)
