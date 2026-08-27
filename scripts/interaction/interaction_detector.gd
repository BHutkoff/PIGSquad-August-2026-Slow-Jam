class_name InteractionDetector
extends Node

@export_range(0.1, 10.0, 0.1) var interaction_distance: float = 2.75
@export_flags_3d_physics var interaction_collision_mask: int = 5
@export var debug_misses: bool = false

@export_category("References")
@export var camera: Camera3D


func try_interact(player: Node) -> void:
	if camera == null:
		push_warning("InteractionDetector needs a Camera3D reference.")
		return

	var origin: Vector3 = camera.global_position
	var destination: Vector3 = origin - camera.global_basis.z.normalized() * interaction_distance
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
		origin, destination, interaction_collision_mask
	)
	query.collide_with_areas = false
	query.collide_with_bodies = true

	var result: Dictionary = camera.get_world_3d().direct_space_state.intersect_ray(query)
	if result.is_empty():
		_print_debug_miss()
		return

	var collider: Node = result.get("collider") as Node
	var interactable: Interactable = _find_interactable(collider)
	if interactable == null:
		_print_debug_miss()
		return
	interactable.interact(player)


func _find_interactable(collider: Node) -> Interactable:
	var current: Node = collider
	while current != null:
		if current is Interactable:
			return current as Interactable
		if current.is_in_group("interactable"):
			var interactable: Interactable = _find_interactable_in_branch(current)
			if interactable != null:
				return interactable
		current = current.get_parent()
	return null


func _find_interactable_in_branch(node: Node) -> Interactable:
	if node is Interactable:
		return node as Interactable
	var children: Array[Node] = node.get_children()
	for child in children:
		var interactable: Interactable = _find_interactable_in_branch(child)
		if interactable != null:
			return interactable
	return null


func _print_debug_miss() -> void:
	if debug_misses:
		print("No interactable target")
