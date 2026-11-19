extends CharacterBody3D
## Third-person movement, climbing, stamina and AI-readable noise output.
## Put climbable surfaces in the "Climbable" group.

signal stamina_changed(current: float, maximum: float)
signal noise_emitted(world_position: Vector3, radius: float)
signal climbing_changed(active: bool)

@export var walk_speed := 4.0
@export var sprint_speed := 7.0
@export var acceleration := 18.0
@export var jump_velocity := 8.0
@export var turn_speed := 12.0
@export var climb_speed := 3.0
@export var climb_sprint_speed := 4.5
@export var climb_probe_distance := 1.25
@export var climb_probe_height := 1.2
@export var wall_standoff := 0.45
@export var max_stamina := 100.0
@export var stamina_recovery_rate := 22.0
@export var sprint_drain_rate := 16.0
@export var climb_drain_rate := 12.0
@export var climb_sprint_drain_rate := 22.0
@export var walk_noise_radius := 3.0
@export var sprint_noise_radius := 12.0
@export var climb_noise_radius := 5.0
@export var climb_sprint_noise_radius := 15.0
@export var noise_emit_interval := 0.35
@export var camera_path: NodePath

var stamina := 100.0
var is_climbing := false
var _wall_normal := Vector3.ZERO
var _noise_timer := 0.0
var _camera: Camera3D

func _ready() -> void:
	stamina = max_stamina
	if not camera_path.is_empty():
		_camera = get_node_or_null(camera_path) as Camera3D
	stamina_changed.emit(stamina, max_stamina)

func _physics_process(delta: float) -> void:
	_noise_timer = maxf(0.0, _noise_timer - delta)
	var input_2d := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var sprinting := Input.is_action_pressed("sprint") and input_2d.length_squared() > 0.01
	if is_climbing:
		_process_climbing(input_2d, sprinting, delta)
	else:
		if Input.is_action_just_pressed("climb"):
			_try_start_climb()
		if not is_climbing:
			_process_ground(input_2d, sprinting, delta)
	if not is_climbing and (not sprinting or input_2d.length_squared() < 0.01):
		_recover_stamina(delta)
	if input_2d.length_squared() > 0.01 and not is_climbing:
		_emit_noise(sprint_noise_radius if sprinting and stamina > 0.0 else walk_noise_radius)
	move_and_slide()

func _process_ground(input_2d: Vector2, sprinting: bool, delta: float) -> void:
	var direction := _camera_relative_direction(input_2d)
	var speed := sprint_speed if sprinting and stamina > 0.0 else walk_speed
	if sprinting and stamina > 0.0:
		_set_stamina(stamina - sprint_drain_rate * delta)
	velocity.x = move_toward(velocity.x, direction.x * speed, acceleration * delta)
	velocity.z = move_toward(velocity.z, direction.z * speed, acceleration * delta)
	if direction.length_squared() > 0.001:
		_rotate_toward(direction, delta)
	if not is_on_floor():
		velocity.y -= float(ProjectSettings.get_setting("physics/3d/default_gravity", 24.0)) * delta
	elif Input.is_action_just_pressed("jump"):
		velocity.y = jump_velocity

func _process_climbing(input_2d: Vector2, sprinting: bool, delta: float) -> void:
	if stamina <= 0.0:
		_end_climb() # Normal gravity resumes; the character falls.
		return
	var hit := _get_climb_hit()
	if hit.is_empty() or not hit.collider.is_in_group("Climbable"):
		_end_climb()
		return
	_wall_normal = hit.normal
	var side := Vector3.UP.cross(_wall_normal).normalized()
	var move := side * input_2d.x + Vector3.UP * -input_2d.y
	var fast := sprinting and move.length_squared() > 0.01
	velocity = move.normalized() * (climb_sprint_speed if fast else climb_speed) if move.length_squared() > 0.001 else Vector3.ZERO
	var probe_origin := global_position + Vector3.UP * climb_probe_height
	velocity += -_wall_normal * (probe_origin.distance_to(hit.position) - wall_standoff) * 8.0
	_set_stamina(stamina - (climb_sprint_drain_rate if fast else climb_drain_rate) * delta)
	_rotate_toward(-_wall_normal, delta)
	if move.length_squared() > 0.01:
		_emit_noise(climb_sprint_noise_radius if fast else climb_noise_radius)
	if Input.is_action_just_pressed("jump"):
		_end_climb()
		velocity = _wall_normal * jump_velocity + Vector3.UP * jump_velocity * 0.65

func _try_start_climb() -> void:
	var hit := _get_climb_hit()
	if hit.is_empty() or not hit.collider.is_in_group("Climbable") or stamina <= 0.0:
		return
	_wall_normal = hit.normal
	velocity = Vector3.ZERO
	_set_climbing(true)

func _get_climb_hit() -> Dictionary:
	var origin := global_position + Vector3.UP * climb_probe_height
	var query := PhysicsRayQueryParameters3D.create(origin, origin - global_transform.basis.z * climb_probe_distance)
	query.exclude = [get_rid()]
	return get_world_3d().direct_space_state.intersect_ray(query)

func _camera_relative_direction(input_2d: Vector2) -> Vector3:
	var basis := _camera.global_transform.basis if is_instance_valid(_camera) else global_transform.basis
	var forward := -basis.z
	forward.y = 0.0
	forward = forward.normalized()
	var right := basis.x
	right.y = 0.0
	right = right.normalized()
	return (right * input_2d.x + forward * -input_2d.y).normalized()

func _rotate_toward(direction: Vector3, delta: float) -> void:
	if direction.length_squared() > 0.001:
		rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), turn_speed * delta)

func _emit_noise(radius: float) -> void:
	if _noise_timer <= 0.0:
		_noise_timer = noise_emit_interval
		noise_emitted.emit(global_position, radius)

func _recover_stamina(delta: float) -> void:
	_set_stamina(stamina + stamina_recovery_rate * delta)

func _set_stamina(value: float) -> void:
	var next := clampf(value, 0.0, max_stamina)
	if not is_equal_approx(next, stamina):
		stamina = next
		stamina_changed.emit(stamina, max_stamina)

func _end_climb() -> void:
	_set_climbing(false)

func _set_climbing(active: bool) -> void:
	if is_climbing != active:
		is_climbing = active
		climbing_changed.emit(active)
