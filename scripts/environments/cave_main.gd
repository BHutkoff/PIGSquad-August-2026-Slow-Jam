extends Node3D

const CAVE_ASSET_DIRECTORY_PREFIX: String = "res://assets/Cave GLB format/"

@export var debug_visibility_enabled: bool = false
@export var debug_hud_enabled: bool = false

@onready var debug_lights: Node3D = $DebugLights
@onready var status_label: Label = $HUD/DebugStatus


func _ready() -> void:
	_configure_environment_echolocation_targets()
	_create_structural_collision()
	_apply_debug_visibility()
	_apply_debug_hud_visibility()


func _configure_environment_echolocation_targets() -> void:
	var target_nodes: Array[Node] = get_tree().get_nodes_in_group("echolocation_target")
	for target_node in target_nodes:
		var target: EcholocationTarget = target_node as EcholocationTarget
		if target == null or not _is_imported_cave_geometry(target):
			continue
		target.environment_reveal_color = EcholocationTarget.CANONICAL_ENVIRONMENT_REVEAL_COLOR
		target.set_target_type(EcholocationTarget.TargetType.ENVIRONMENT)


func _is_imported_cave_geometry(target: EcholocationTarget) -> bool:
	return target.scene_file_path.begins_with(CAVE_ASSET_DIRECTORY_PREFIX)


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.echo:
		return
	if event.is_action_pressed("toggle_debug_visibility"):
		debug_visibility_enabled = not debug_visibility_enabled
		_apply_debug_visibility()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("toggle_debug_hud"):
		debug_hud_enabled = not debug_hud_enabled
		_apply_debug_hud_visibility()
		get_viewport().set_input_as_handled()


func _apply_debug_visibility() -> void:
	debug_lights.visible = debug_visibility_enabled
	status_label.text = "CAVE DEBUG VISIBILITY: %s  [F1 to toggle]" % (
		"ON" if debug_visibility_enabled else "OFF (echolocation state)"
	)


func _apply_debug_hud_visibility() -> void:
	var debug_hud_nodes: Array[Node] = get_tree().get_nodes_in_group("debug_gameplay_hud")
	for hud_node: Node in debug_hud_nodes:
		var canvas_item: CanvasItem = hud_node as CanvasItem
		if canvas_item != null:
			canvas_item.visible = debug_hud_enabled


func _create_structural_collision() -> void:
	var collision_sources: Array[Node] = get_tree().get_nodes_in_group("cave_collision_source")
	for source in collision_sources:
		_create_collision_for_branch(source)


func _create_collision_for_branch(node: Node) -> void:
	if node is MeshInstance3D:
		var mesh_instance: MeshInstance3D = node as MeshInstance3D
		mesh_instance.create_trimesh_collision()
	var children: Array[Node] = node.get_children()
	for child in children:
		_create_collision_for_branch(child)
