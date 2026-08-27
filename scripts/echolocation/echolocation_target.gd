class_name EcholocationTarget
extends Node3D

const REVEAL_SHADER: Shader = preload("res://shaders/echolocation_reveal.gdshader")
const SHADER_PULSE_CAPACITY: int = 6
const CANONICAL_ENVIRONMENT_REVEAL_COLOR: Color = Color(0.22, 0.26, 0.3, 1.0)

enum TargetType {
	ENVIRONMENT,
	OBJECT,
}

class PulseState:
	var pulse_id: int = 0
	var origin: Vector3 = Vector3.ZERO
	var forward: Vector3 = Vector3.FORWARD
	var cone_minimum_dot: float = 0.0
	var maximum_distance: float = 0.0
	var radius: float = 0.0
	var wave_band_width: float = 0.0
	var propagation_speed: float = 0.0
	var trail_hold_length: float = 0.0
	var trail_fade_length: float = 0.0
	var distance_brightness: float = 1.0
	var arrival_distance: float = 0.0
	var final_radius: float = 0.0
	var refresh_on_arrival: bool = false
	var arrival_logged: bool = false
	var debug_refresh_events: bool = false

@export_category("Visual Category")
@export var target_type: TargetType = TargetType.OBJECT
@export var environment_reveal_color: Color = CANONICAL_ENVIRONMENT_REVEAL_COLOR
@export var object_reveal_color: Color = Color(1.0, 1.0, 1.0, 1.0)

@export_category("Edge Style")
@export_range(0.25, 8.0, 0.05) var edge_power: float = 2.5
@export_range(0.0, 4.0, 0.05) var object_edge_intensity: float = 1.4
@export_range(0.0, 4.0, 0.05) var environment_edge_intensity: float = 0.7
@export_range(0.0, 0.5, 0.005) var object_surface_brightness: float = 0.2
@export_range(0.0, 0.5, 0.005) var environment_surface_brightness: float = 0.14

@export_category("Wave Style")
@export_range(0.0, 4.0, 0.05) var object_wavefront_intensity: float = 1.5
@export_range(0.0, 4.0, 0.05) var environment_wavefront_intensity: float = 1.7
@export_range(0.0, 2.0, 0.05) var object_wavefront_surface_boost: float = 0.0
@export_range(0.0, 2.0, 0.05) var environment_wavefront_surface_boost: float = 1.0
@export_range(0.0, 2.0, 0.05) var object_trail_intensity: float = 0.55
@export_range(0.0, 2.0, 0.05) var environment_trail_intensity: float = 0.9

@export_category("Distance Brightness")
@export_range(0.0, 2.0, 0.05) var near_brightness: float = 1.0
@export_range(0.0, 2.0, 0.05) var far_brightness: float = 0.3
@export_range(0.1, 4.0, 0.05) var brightness_falloff: float = 1.25

@export_category("Pulse History")
@export_range(1, SHADER_PULSE_CAPACITY, 1) var maximum_active_pulses: int = 6

@export_category("Environment Detection")
@export_range(2, 8, 1) var environment_bounds_sample_grid_size: int = 5

var _visuals: Array[GeometryInstance3D] = []
var _original_material_overrides: Array[Material] = []
var _reveal_material: ShaderMaterial
var _active_pulses: Array[PulseState] = []
var _brightness_multiplier: float = 1.0


func _ready() -> void:
	var settings_manager: GameSettings = get_node_or_null(
		"/root/SettingsManager"
	) as GameSettings
	if settings_manager != null:
		_brightness_multiplier = settings_manager.brightness
	_collect_visuals(self)
	_reveal_material = ShaderMaterial.new()
	_reveal_material.shader = REVEAL_SHADER
	_apply_visual_parameters()
	_reveal_material.set_shader_parameter("reveal_amount", 0.0)
	_reveal_material.set_shader_parameter("active_pulse_count", 0)
	set_process(false)


func set_target_type(value: TargetType) -> void:
	target_type = value
	if _reveal_material != null:
		_apply_visual_parameters()


func set_brightness_multiplier(value: float) -> void:
	_brightness_multiplier = clampf(value, 0.75, 1.25)
	if _reveal_material != null:
		_reveal_material.set_shader_parameter("brightness_multiplier", _brightness_multiplier)


func _process(delta: float) -> void:
	var index: int = _active_pulses.size() - 1
	while index >= 0:
		var pulse_state: PulseState = _active_pulses[index]
		pulse_state.radius += delta * pulse_state.propagation_speed
		if not pulse_state.arrival_logged and pulse_state.radius >= pulse_state.arrival_distance:
			pulse_state.arrival_logged = true
			if pulse_state.debug_refresh_events:
				var event_description: String = (
					"reveal refreshed" if pulse_state.refresh_on_arrival else "reveal reached"
				)
				print(
					"Pulse %d reached %s — %s"
					% [pulse_state.pulse_id, name, event_description]
				)
		if pulse_state.radius >= pulse_state.final_radius:
			_active_pulses.remove_at(index)
		index -= 1
	_upload_pulse_parameters()
	if _active_pulses.is_empty():
		_deactivate_reveal()


func begin_pulse(
		pulse_id: int,
		pulse_origin: Vector3,
		pulse_forward: Vector3,
		cone_minimum_dot: float,
		distance: float,
		maximum_distance: float,
		wave_band_width: float,
		propagation_speed: float,
		trail_hold_duration: float,
		trail_fade_duration: float,
		debug_refresh_events: bool
	) -> void:
	var normalized_distance: float = clampf(
		distance / maxf(maximum_distance, 0.001), 0.0, 1.0
	)
	var falloff_amount: float = pow(normalized_distance, brightness_falloff)
	var pulse_state: PulseState = PulseState.new()
	pulse_state.pulse_id = pulse_id
	pulse_state.origin = pulse_origin
	pulse_state.forward = pulse_forward
	pulse_state.cone_minimum_dot = cone_minimum_dot
	pulse_state.maximum_distance = maximum_distance
	pulse_state.wave_band_width = wave_band_width
	pulse_state.propagation_speed = propagation_speed
	pulse_state.trail_hold_length = propagation_speed * trail_hold_duration
	pulse_state.trail_fade_length = propagation_speed * trail_fade_duration
	pulse_state.distance_brightness = lerpf(near_brightness, far_brightness, falloff_amount)
	pulse_state.arrival_distance = distance
	pulse_state.final_radius = (
		maximum_distance
		+ wave_band_width
		+ propagation_speed * (trail_hold_duration + trail_fade_duration)
	)
	pulse_state.refresh_on_arrival = not _active_pulses.is_empty()
	pulse_state.debug_refresh_events = debug_refresh_events

	var pulse_limit: int = mini(maximum_active_pulses, SHADER_PULSE_CAPACITY)
	if _active_pulses.size() >= pulse_limit:
		_active_pulses.remove_at(0)
	_active_pulses.append(pulse_state)
	_activate_reveal()
	_upload_pulse_parameters()
	set_process(true)


func end_pulse() -> void:
	_active_pulses.clear()
	_upload_pulse_parameters()
	_deactivate_reveal()


func get_detection_points() -> Array[Vector3]:
	var points: Array[Vector3] = []
	for visual in _visuals:
		var bounds: AABB = visual.get_aabb()
		if target_type == TargetType.ENVIRONMENT:
			_append_environment_bounds_samples(points, visual, bounds)
		else:
			points.append(visual.global_transform * bounds.get_center())
			for corner_index in 8:
				var corner: Vector3 = bounds.get_endpoint(corner_index)
				points.append(visual.global_transform * corner)
	if points.is_empty():
		points.append(global_position)
	return points


func _append_environment_bounds_samples(
		points: Array[Vector3], visual: GeometryInstance3D, bounds: AABB
	) -> void:
	var grid_size: int = maxi(environment_bounds_sample_grid_size, 2)
	var last_index: int = grid_size - 1
	for x_index in grid_size:
		for y_index in grid_size:
			for z_index in grid_size:
				var is_surface_point: bool = (
					x_index == 0
					or x_index == last_index
					or y_index == 0
					or y_index == last_index
					or z_index == 0
					or z_index == last_index
				)
				if not is_surface_point:
					continue
				var normalized_point: Vector3 = Vector3(
					float(x_index) / float(last_index),
					float(y_index) / float(last_index),
					float(z_index) / float(last_index)
				)
				var local_point: Vector3 = bounds.position + bounds.size * normalized_point
				points.append(visual.global_transform * local_point)


func _activate_reveal() -> void:
	_reveal_material.set_shader_parameter("reveal_amount", 1.0)
	for visual in _visuals:
		visual.material_override = _reveal_material


func _deactivate_reveal() -> void:
	_reveal_material.set_shader_parameter("reveal_amount", 0.0)
	_reveal_material.set_shader_parameter("active_pulse_count", 0)
	for index in _visuals.size():
		_visuals[index].material_override = _original_material_overrides[index]
	set_process(false)


func _upload_pulse_parameters() -> void:
	var pulse_origins: PackedVector3Array = PackedVector3Array()
	var pulse_forwards: PackedVector3Array = PackedVector3Array()
	var cone_minimum_dots: PackedFloat32Array = PackedFloat32Array()
	var pulse_max_distances: PackedFloat32Array = PackedFloat32Array()
	var pulse_radii: PackedFloat32Array = PackedFloat32Array()
	var wave_band_widths: PackedFloat32Array = PackedFloat32Array()
	var trail_hold_lengths: PackedFloat32Array = PackedFloat32Array()
	var trail_fade_lengths: PackedFloat32Array = PackedFloat32Array()
	var distance_brightnesses: PackedFloat32Array = PackedFloat32Array()
	pulse_origins.resize(SHADER_PULSE_CAPACITY)
	pulse_forwards.resize(SHADER_PULSE_CAPACITY)
	cone_minimum_dots.resize(SHADER_PULSE_CAPACITY)
	pulse_max_distances.resize(SHADER_PULSE_CAPACITY)
	pulse_radii.resize(SHADER_PULSE_CAPACITY)
	wave_band_widths.resize(SHADER_PULSE_CAPACITY)
	trail_hold_lengths.resize(SHADER_PULSE_CAPACITY)
	trail_fade_lengths.resize(SHADER_PULSE_CAPACITY)
	distance_brightnesses.resize(SHADER_PULSE_CAPACITY)
	for index in _active_pulses.size():
		var pulse_state: PulseState = _active_pulses[index]
		pulse_origins[index] = pulse_state.origin
		pulse_forwards[index] = pulse_state.forward
		cone_minimum_dots[index] = pulse_state.cone_minimum_dot
		pulse_max_distances[index] = pulse_state.maximum_distance
		pulse_radii[index] = pulse_state.radius
		wave_band_widths[index] = pulse_state.wave_band_width
		trail_hold_lengths[index] = pulse_state.trail_hold_length
		trail_fade_lengths[index] = pulse_state.trail_fade_length
		distance_brightnesses[index] = pulse_state.distance_brightness
	_reveal_material.set_shader_parameter("pulse_origins", pulse_origins)
	_reveal_material.set_shader_parameter("pulse_forwards", pulse_forwards)
	_reveal_material.set_shader_parameter("cone_minimum_dots", cone_minimum_dots)
	_reveal_material.set_shader_parameter("pulse_max_distances", pulse_max_distances)
	_reveal_material.set_shader_parameter("pulse_radii", pulse_radii)
	_reveal_material.set_shader_parameter("wave_band_widths", wave_band_widths)
	_reveal_material.set_shader_parameter("trail_hold_lengths", trail_hold_lengths)
	_reveal_material.set_shader_parameter("trail_fade_lengths", trail_fade_lengths)
	_reveal_material.set_shader_parameter("distance_brightnesses", distance_brightnesses)
	_reveal_material.set_shader_parameter("active_pulse_count", _active_pulses.size())


func _apply_visual_parameters() -> void:
	var reveal_color: Color = (
		environment_reveal_color
		if target_type == TargetType.ENVIRONMENT
		else object_reveal_color
	)
	var edge_intensity: float = (
		environment_edge_intensity
		if target_type == TargetType.ENVIRONMENT
		else object_edge_intensity
	)
	var surface_brightness: float = (
		environment_surface_brightness
		if target_type == TargetType.ENVIRONMENT
		else object_surface_brightness
	)
	var wavefront_intensity: float = (
		environment_wavefront_intensity
		if target_type == TargetType.ENVIRONMENT
		else object_wavefront_intensity
	)
	var wavefront_surface_boost: float = (
		environment_wavefront_surface_boost
		if target_type == TargetType.ENVIRONMENT
		else object_wavefront_surface_boost
	)
	var trail_intensity: float = (
		environment_trail_intensity
		if target_type == TargetType.ENVIRONMENT
		else object_trail_intensity
	)
	_reveal_material.set_shader_parameter(
		"edge_color", Vector3(reveal_color.r, reveal_color.g, reveal_color.b)
	)
	_reveal_material.set_shader_parameter("edge_power", edge_power)
	_reveal_material.set_shader_parameter("edge_intensity", edge_intensity)
	_reveal_material.set_shader_parameter("surface_brightness", surface_brightness)
	_reveal_material.set_shader_parameter("wavefront_intensity", wavefront_intensity)
	_reveal_material.set_shader_parameter("wavefront_surface_boost", wavefront_surface_boost)
	_reveal_material.set_shader_parameter("trail_intensity", trail_intensity)
	_reveal_material.set_shader_parameter("brightness_multiplier", _brightness_multiplier)


func _collect_visuals(node: Node) -> void:
	if node is GeometryInstance3D:
		var visual: GeometryInstance3D = node as GeometryInstance3D
		_visuals.append(visual)
		_original_material_overrides.append(visual.material_override)
	var children: Array[Node] = node.get_children()
	for child in children:
		_collect_visuals(child)
