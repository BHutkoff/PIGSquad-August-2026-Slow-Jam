class_name FirstPersonController
extends CharacterBody3D

@export_category("Movement")
@export var move_speed: float = 5.0
@export var acceleration: float = 20.0
@export var gravity: float = 18.0
@export var jump_velocity: float = 7.5

@export_category("Footsteps")
@export_range(0.5, 4.0, 0.05) var footstep_distance: float = 1.55
@export_range(0.05, 2.0, 0.05) var footstep_velocity_threshold: float = 0.25

@export_category("Look")
@export_range(0.01, 1.0, 0.01) var mouse_sensitivity: float = 0.12
@export_range(1.0, 89.0, 1.0) var max_look_angle: float = 85.0

@onready var head: Node3D = $Head
@onready var echolocation_detector: EcholocationDetector = $Head/Camera3D/EcholocationDetector
@onready var interaction_detector: InteractionDetector = $Head/Camera3D/InteractionDetector
@onready var case_ui: CaseUI = $CaseUI
@onready var ending_controller: EndingController = $EndingController
@onready var gameplay_audio: GameplayAudio = $GameplayAudio

var _ground_state_initialized: bool = false
var _was_on_floor: bool = false
var _accumulated_footstep_distance: float = 0.0
var _in_water: bool = false


func _ready() -> void:
	mouse_sensitivity = SettingsManager.mouse_sensitivity
	SettingsManager.mouse_sensitivity_changed.connect(_on_mouse_sensitivity_changed)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if _is_gameplay_blocked():
		return
	if event.is_action_pressed("interact") and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		interaction_detector.try_interact(self)
	elif event.is_action_pressed("echolocation") and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		echolocation_detector.pulse()
	elif event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(deg_to_rad(-event.relative.x * mouse_sensitivity))
		head.rotation.x = clamp(
			head.rotation.x + deg_to_rad(-event.relative.y * mouse_sensitivity),
			deg_to_rad(-max_look_angle),
			deg_to_rad(max_look_angle)
		)
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.mouse_mode = (
			Input.MOUSE_MODE_CAPTURED
			if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED
			else Input.MOUSE_MODE_VISIBLE
		)
	elif (
		event is InputEventMouseButton
		and event.pressed
		and event.button_index == MOUSE_BUTTON_LEFT
		and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED
	):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _physics_process(delta: float) -> void:
	var previous_position: Vector3 = global_position
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0
		if not _is_gameplay_blocked() and Input.is_action_just_pressed("jump"):
			velocity.y = jump_velocity
			if gameplay_audio != null:
				gameplay_audio.play_jump()

	if _is_gameplay_blocked():
		velocity.x = move_toward(velocity.x, 0.0, acceleration * delta)
		velocity.z = move_toward(velocity.z, 0.0, acceleration * delta)
		move_and_slide()
		_accumulated_footstep_distance = 0.0
		_ground_state_initialized = false
		return

	var input_vector: Vector2 = Input.get_vector(
		"move_left", "move_right", "move_forward", "move_backward"
	)
	var move_direction: Vector3 = (
		transform.basis * Vector3(input_vector.x, 0.0, input_vector.y)
	).normalized()
	var target_velocity: Vector3 = move_direction * move_speed
	velocity.x = move_toward(velocity.x, target_velocity.x, acceleration * delta)
	velocity.z = move_toward(velocity.z, target_velocity.z, acceleration * delta)
	move_and_slide()
	_update_movement_audio(previous_position)


func set_in_water(value: bool) -> void:
	_in_water = value


func _update_movement_audio(previous_position: Vector3) -> void:
	var currently_on_floor: bool = is_on_floor()
	if not _ground_state_initialized:
		_ground_state_initialized = true
		_was_on_floor = currently_on_floor
		return

	var just_landed: bool = not _was_on_floor and currently_on_floor
	_was_on_floor = currently_on_floor
	if just_landed:
		_accumulated_footstep_distance = 0.0
		if gameplay_audio != null:
			gameplay_audio.play_land()
		return
	if not currently_on_floor:
		_accumulated_footstep_distance = 0.0
		return

	var horizontal_distance: float = Vector2(
		global_position.x - previous_position.x,
		global_position.z - previous_position.z
	).length()
	var horizontal_speed: float = Vector2(velocity.x, velocity.z).length()
	if horizontal_distance <= 0.0001 or horizontal_speed < footstep_velocity_threshold:
		return
	_accumulated_footstep_distance += horizontal_distance
	while _accumulated_footstep_distance >= footstep_distance:
		_accumulated_footstep_distance -= footstep_distance
		if gameplay_audio != null:
			gameplay_audio.play_footstep(_in_water)


func _is_gameplay_blocked() -> bool:
	var case_review_open: bool = case_ui != null and case_ui.is_deduction_open()
	var ending_active: bool = (
		ending_controller != null and ending_controller.is_ending_active()
	)
	var puzzle_ui_open: bool = not get_tree().get_nodes_in_group("gameplay_modal").is_empty()
	return case_review_open or ending_active or puzzle_ui_open


func _on_mouse_sensitivity_changed(value: float) -> void:
	mouse_sensitivity = value
