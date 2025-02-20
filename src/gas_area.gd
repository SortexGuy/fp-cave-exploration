extends Area3D
class_name GasArea

func _on_area_entered(area: Area3D) -> void:
	if area is not HurtBox: return
	area = area as HurtBox
	area.gas_entered.emit()

func _on_area_exited(area: Area3D) -> void:
	if area is not HurtBox: return
	area = area as HurtBox
	area.gas_exited.emit()
