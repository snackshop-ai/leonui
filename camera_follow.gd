extends Camera3D
## Fixed third-person camera for the MVP test scene.
@export var target_path: NodePath = NodePath("..")
@export var follow_offset := Vector3(0.0, 5.0, 9.0)
@export var look_height := 1.0
@export var follow_smoothing := 8.0

var _target: Node3D

func _ready() -> void:
	_target = get_node_or_null(target_path) as Node3D

func _process(delta: float) -> void:
	if not is_instance_valid(_target):
		return
	var desired := _target.global_position + follow_offset
	global_position = global_position.lerp(desired, 1.0 - exp(-follow_smoothing * delta))
	look_at(_target.global_position + Vector3.UP * look_height, Vector3.UP)
