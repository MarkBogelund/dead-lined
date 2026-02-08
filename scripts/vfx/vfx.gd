extends Node
class_name VFXComponent

func instantiate_vfx(vfx_scene: PackedScene, vfx_position: Vector2):
	if vfx_scene == null:
		push_error("No hit vfx scene attached")
		return
	
	var vfx = vfx_scene.instantiate()
	vfx.position = vfx_position
	get_tree().current_scene.add_child(vfx)
