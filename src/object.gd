extends Area3D
class_name ObjectItem

@export var item: InventoryItem
@export var selected: bool = false
@onready var mesh_instance_3d: MeshInstance3D = $MeshInstance3D

func _process(delta: float) -> void:
	if selected and mesh_instance_3d.visible:
		mesh_instance_3d.hide()
	elif not selected and not mesh_instance_3d.visible:
		mesh_instance_3d.show()
