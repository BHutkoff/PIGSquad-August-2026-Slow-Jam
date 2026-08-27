@tool
extends Path3D

@export_range(0.03, 0.06, 0.005) var tape_width: float = 0.045:
	set(value):
		tape_width = value
		_queue_rebuild()
@export_range(0, 3, 1) var smoothing_iterations: int = 2:
	set(value):
		smoothing_iterations = value
		_queue_rebuild()
@export var initial_control_points: PackedVector3Array

var _rebuild_queued: bool = false


func _ready() -> void:
	_rebuild_curve_from_initial_points()
	if curve != null and not curve.changed.is_connected(_queue_rebuild):
		curve.changed.connect(_queue_rebuild)
	_rebuild_mesh()


func _rebuild_curve_from_initial_points() -> void:
	curve = Curve3D.new()
	curve.closed = true
	for point: Vector3 in initial_control_points:
		curve.add_point(Vector3(point.x, 0.0, point.z))


func _queue_rebuild() -> void:
	if not is_inside_tree() or _rebuild_queued:
		return
	_rebuild_queued = true
	call_deferred("_rebuild_mesh")


func _rebuild_mesh() -> void:
	_rebuild_queued = false
	var tape_mesh: MeshInstance3D = get_node_or_null("TapeMesh") as MeshInstance3D
	if tape_mesh == null or curve == null or curve.point_count < 3:
		return
	curve.closed = true
	var points: PackedVector3Array = PackedVector3Array()
	for index in curve.point_count:
		var curve_point: Vector3 = curve.get_point_position(index)
		points.append(Vector3(curve_point.x, 0.0, curve_point.z))
	for _iteration in smoothing_iterations:
		points = _smooth_closed_points(points)
	tape_mesh.mesh = _build_ribbon(points)


func _smooth_closed_points(points: PackedVector3Array) -> PackedVector3Array:
	var smoothed: PackedVector3Array = PackedVector3Array()
	for index in points.size():
		var current_point: Vector3 = points[index]
		var next_point: Vector3 = points[(index + 1) % points.size()]
		smoothed.append(current_point.lerp(next_point, 0.25))
		smoothed.append(current_point.lerp(next_point, 0.75))
	return smoothed


func _build_ribbon(points: PackedVector3Array) -> ArrayMesh:
	var left_edges: PackedVector3Array = PackedVector3Array()
	var right_edges: PackedVector3Array = PackedVector3Array()
	var half_width: float = tape_width * 0.5
	for index in points.size():
		var previous_point: Vector3 = points[(index - 1 + points.size()) % points.size()]
		var next_point: Vector3 = points[(index + 1) % points.size()]
		var tangent: Vector3 = (next_point - previous_point).normalized()
		var side: Vector3 = Vector3(-tangent.z, 0.0, tangent.x) * half_width
		left_edges.append(points[index] + side)
		right_edges.append(points[index] - side)

	var surface: SurfaceTool = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index in points.size():
		var next_index: int = (index + 1) % points.size()
		_add_vertex(surface, left_edges[index])
		_add_vertex(surface, left_edges[next_index])
		_add_vertex(surface, right_edges[index])
		_add_vertex(surface, right_edges[index])
		_add_vertex(surface, left_edges[next_index])
		_add_vertex(surface, right_edges[next_index])
	return surface.commit()


func _add_vertex(surface: SurfaceTool, point: Vector3) -> void:
	surface.set_normal(Vector3.UP)
	surface.add_vertex(point)
