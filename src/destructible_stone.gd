extends StaticBody3D
class_name DestructibleStone

@onready var mesh_instance_3d: MeshInstance3D = $MeshInstance3D
@onready var collision_shape_3d: CollisionShape3D = $CollisionShape3D
@onready var cpu_particles_3d: CPUParticles3D = $CPUParticles3D

func destroy() -> void:
	mesh_instance_3d.hide()
	collision_shape_3d.disabled = true
	cpu_particles_3d.emitting = true
	var timer := get_tree().create_timer(1.1)
	timer.timeout.connect(self.queue_free)
