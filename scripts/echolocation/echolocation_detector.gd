class_name EcholocationDetector
extends Node

@export_category("Echolocation")
@export var echolocation_max_distance: float = 12.0
@export_range(1.0, 179.0, 0.5) var echolocation_cone_angle: float = 137.5
@export_range(1.0, 100.0, 0.5) var echolocation_propagation_speed: float = 14.0
@export_range(0.0, 2.0, 0.05) var echolocation_cooldown: float = 0.6
@export var debug_output_enabled: bool = true
@export var debug_target_sampling_enabled: bool = false

@export_category("Wave Visualization")
@export_range(0.05, 5.0, 0.05) var wave_band_width: float = 0.8
@export_range(0.0, 5.0, 0.05) var trail_hold_duration: float = 2.25
@export_range(0.1, 5.0, 0.05) var trail_fade_duration: float = 1.0
@export_range(0.1, 4.0, 0.1) var fade_duration_multiplier: float = 2 #100% increase

@export_category("References")
@export var camera: Camera3D
@export var audio_feedback: EcholocationAudio

var _last_pulse_time_msec: int = -1000000
var _next_pulse_id: int = 1


func pulse() -> void:
	if camera == null:
		push_warning("EcholocationDetector needs a Camera3D reference.")
		return
	var current_time_msec: int = Time.get_ticks_msec()
	var cooldown_msec: int = int(roundf(echolocation_cooldown * 1000.0))
	if current_time_msec - _last_pulse_time_msec < cooldown_msec:
		return
	_last_pulse_time_msec = current_time_msec
	var pulse_id: int = _next_pulse_id
	_next_pulse_id += 1
	if audio_feedback != null:
		audio_feedback.begin_pulse()
	if debug_output_enabled:
		print("Echolocation pulse %d" % pulse_id)

	var origin: Vector3 = camera.global_position
	var forward: Vector3 = -camera.global_basis.z.normalized()
	var minimum_dot: float = cos(deg_to_rad(echolocation_cone_angle * 0.5))
	var effective_fade_duration: float = trail_fade_duration * fade_duration_multiplier
	var detections: Array[Dictionary] = []

	var target_nodes: Array[Node] = get_tree().get_nodes_in_group("echolocation_target")
	for node in target_nodes:
		if not node is EcholocationTarget:
			continue
		var echolocation_target: EcholocationTarget = node as EcholocationTarget
		var detection_points: Array[Vector3] = echolocation_target.get_detection_points()
		var evaluation: Dictionary = _evaluate_detection_points(
			detection_points, origin, forward, minimum_dot
		)
		var nearest_distance: float = float(evaluation.get("nearest_distance", -1.0))
		if debug_target_sampling_enabled:
			var category_name: String = (
				"ENVIRONMENT"
				if echolocation_target.target_type == EcholocationTarget.TargetType.ENVIRONMENT
				else "OBJECT"
			)
			var distance_result: String = (
				"%.1fm" % nearest_distance if nearest_distance >= 0.0 else "none"
			)
			var diagnostic_message: String = (
				(
					"Echo samples: %s | category: %s | tested: %d | in range: %d | "
					+ "in cone: %d | distance: %s"
				)
				% [
					echolocation_target.name,
					category_name,
					int(evaluation.get("sample_count", 0)),
					int(evaluation.get("within_distance_count", 0)),
					int(evaluation.get("accepted_count", 0)),
					distance_result,
				]
			)
			print(diagnostic_message)
		if nearest_distance >= 0.0:
			detections.append({"target": echolocation_target, "distance": nearest_distance})

	detections.sort_custom(
		func(a: Dictionary, b: Dictionary) -> bool:
			return float(a.get("distance", INF)) < float(b.get("distance", INF))
	)
	for detection in detections:
		var target: EcholocationTarget = detection.get("target") as EcholocationTarget
		var distance: float = float(detection.get("distance", -1.0))
		var approximate_arrival_time: float = distance / echolocation_propagation_speed
		target.begin_pulse(
			pulse_id,
			origin,
			forward,
			minimum_dot,
			distance,
			echolocation_max_distance,
			wave_band_width,
			echolocation_propagation_speed,
			trail_hold_duration,
			effective_fade_duration,
			debug_target_sampling_enabled
		)
		if (
			audio_feedback != null
			and target.target_type == EcholocationTarget.TargetType.OBJECT
		):
			audio_feedback.schedule_object_echo(target.global_position, approximate_arrival_time)
		if debug_output_enabled:
			print(
				"Detected: %s | Distance: %.1fm | Wave arrival: ~%.2fs"
				% [target.name, distance, approximate_arrival_time]
			)

	if debug_output_enabled and detections.is_empty():
		print("Detected: nothing")


func _evaluate_detection_points(
		points: Array[Vector3], origin: Vector3, forward: Vector3, minimum_dot: float
	) -> Dictionary:
	var nearest_distance: float = INF
	var within_distance_count: int = 0
	var accepted_count: int = 0
	for point in points:
		var offset: Vector3 = point - origin
		var distance: float = offset.length()
		if distance <= echolocation_max_distance and distance > 0.001:
			within_distance_count += 1
			if forward.dot(offset / distance) >= minimum_dot:
				accepted_count += 1
				nearest_distance = minf(nearest_distance, distance)
	return {
		"sample_count": points.size(),
		"within_distance_count": within_distance_count,
		"accepted_count": accepted_count,
		"nearest_distance": -1.0 if is_inf(nearest_distance) else nearest_distance,
	}
