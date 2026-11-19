extends Control
## Responsive touch overlay for player_movement.gd.
## Add this Control under a CanvasLayer below the player in the scene tree.

@export var joystick_radius := 62.0
@export var button_size := 76.0
@export var edge_margin := 18.0

var _joy_center := Vector2.ZERO
var _joy_pointer := -1
var _joy_vector := Vector2.ZERO
var _buttons: Dictionary = {}

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_buttons()
	get_viewport().size_changed.connect(_layout)
	_layout()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_inside_tree():
		_layout()

func _draw() -> void:
	if size == Vector2.ZERO:
		return
	var r := minf(joystick_radius, size.y * 0.115)
	_joy_center = Vector2(edge_margin + r + 10.0, size.y - edge_margin - r - 8.0)
	draw_circle(_joy_center, r + 12.0, Color(0.03, 0.06, 0.08, 0.20))
	draw_circle(_joy_center, r, Color(0.08, 0.13, 0.15, 0.52))
	draw_arc(_joy_center, r, 0.0, TAU, 48, Color(0.72, 0.82, 0.78, 0.55), 2.0, true)
	draw_circle(_joy_center + _joy_vector * r * 0.62, r * 0.36, Color(0.83, 0.91, 0.86, 0.76))

func _build_buttons() -> void:
	_add_action_button("SPRINT", "sprint", true)
	_add_action_button("JUMP", "jump", true)
	_add_action_button("CLIMB", "climb", false)

func _add_action_button(label: String, action: String, hold_action: bool) -> void:
	var button := Button.new()
	button.text = label
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.add_theme_font_size_override("font_size", 14)
	button.add_theme_color_override("font_color", Color(0.96, 0.97, 0.92))
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.10, 0.17, 0.18, 0.72)
	normal.border_color = Color(0.74, 0.84, 0.75, 0.75)
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(36)
	button.add_theme_stylebox_override("normal", normal)
	var pressed := StyleBoxFlat.new()
	pressed.bg_color = Color(0.27, 0.46, 0.34, 0.92)
	pressed.border_color = Color(0.88, 0.95, 0.83)
	pressed.set_border_width_all(3)
	pressed.set_corner_radius_all(36)
	button.add_theme_stylebox_override("pressed", pressed)
	if hold_action:
		button.button_down.connect(func(): Input.action_press(action))
		button.button_up.connect(func(): Input.action_release(action))
	else:
		button.button_down.connect(func(): Input.action_press(action))
		button.button_up.connect(func(): Input.action_release(action))
	add_child(button)
	_buttons[action] = button

func _layout() -> void:
	if not is_inside_tree():
		return
	var unit := clampf(size.y * 0.125, 64.0, button_size)
	var gap := unit * 0.16
	var right := size.x - edge_margin - unit
	var bottom := size.y - edge_margin - unit
	# Keep controls in the bottom corners so the central play area stays visible.
	if _buttons.has("jump"):
		_buttons.jump.position = Vector2(right, bottom - unit - gap)
		_buttons.jump.size = Vector2(unit, unit)
		_buttons.sprint.position = Vector2(right - unit - gap, bottom)
		_buttons.sprint.size = Vector2(unit, unit)
		_buttons.climb.position = Vector2(right, bottom)
		_buttons.climb.size = Vector2(unit, unit)
	queue_redraw()

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_handle_touch(event.index, event.position, event.pressed)
	elif event is InputEventScreenDrag and event.index == _joy_pointer:
		_update_joystick(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_handle_touch(-2, event.position, true)
		else:
			_handle_touch(-2, event.position, false)
	elif event is InputEventMouseMotion and _joy_pointer == -2 and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_update_joystick(event.position)

func _handle_touch(pointer: int, point: Vector2, pressed: bool) -> void:
	if pressed:
		if _joy_pointer == -1 and point.distance_to(_joy_center) <= joystick_radius * 1.75:
			_joy_pointer = pointer
			_update_joystick(point)
	elif pointer == _joy_pointer:
		_joy_pointer = -1
		_set_joystick(Vector2.ZERO)

func _update_joystick(point: Vector2) -> void:
	var delta := point - _joy_center
	_set_joystick(delta.limit_length(joystick_radius) / joystick_radius)

func _set_joystick(value: Vector2) -> void:
	_joy_vector = value
	_set_axis("move_left", value.x < -0.28)
	_set_axis("move_right", value.x > 0.28)
	_set_axis("move_forward", value.y < -0.28)
	_set_axis("move_backward", value.y > 0.28)
	queue_redraw()

func _set_axis(action: String, active: bool) -> void:
	if active and not Input.is_action_pressed(action):
		Input.action_press(action)
	elif not active and Input.is_action_pressed(action):
		Input.action_release(action)

func _exit_tree() -> void:
	for action in ["move_left", "move_right", "move_forward", "move_backward", "sprint", "jump", "climb"]:
		Input.action_release(action)
