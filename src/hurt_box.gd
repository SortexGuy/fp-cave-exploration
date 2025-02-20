extends Area3D
class_name HurtBox

var player: Player : 
	set (p):
		player = p
	get: 
		return player
signal take_damage()
signal gas_entered()
signal gas_exited()
