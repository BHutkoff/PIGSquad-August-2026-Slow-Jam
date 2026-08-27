class_name DrainController
extends Node3D

enum DrainState {
	PLUGGED,
	DRAINING,
	DRAINED,
}

@export_range(0.1, 10.0, 0.1) var drain_duration: float = 4.0
@export var drained_water_position: Vector3 = Vector3(-22.92, -7.25, -0.27)
@export_range(0.05, 2.0, 0.05) var plug_removal_duration: float = 0.45
@export var plug_removed_offset: Vector3 = Vector3(0.0, 0.75, 0.35)

@export_category("References")
@export var plug_visual: Node3D
@export var plug_interactable: DrainPlugInteractable
@export var water: Node3D

var state: DrainState = DrainState.PLUGGED
var _water_start_position: Vector3 = Vector3.ZERO


func _ready() -> void:
	if plug_visual == null or plug_interactable == null or water == null:
		push_warning("DrainController needs plug visual, plug interactable, and water references.")
		return
	_water_start_position = water.position
	plug_interactable.plug_pulled.connect(remove_plug)


func remove_plug(player: Node) -> void:
	if state != DrainState.PLUGGED:
		return
	state = DrainState.DRAINING
	plug_interactable.set_interaction_enabled(false)
	plug_interactable.show_pull_observation(player)

	var plug_tween: Tween = create_tween()
	plug_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	plug_tween.tween_property(
		plug_visual,
		"position",
		plug_visual.position + plug_removed_offset,
		plug_removal_duration
	)
	plug_tween.tween_callback(_hide_removed_plug)

	var water_tween: Tween = create_tween()
	water_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	water_tween.tween_property(water, "position", drained_water_position, drain_duration)
	water_tween.tween_callback(_finish_draining)


func get_water_start_position() -> Vector3:
	return _water_start_position


func _hide_removed_plug() -> void:
	plug_visual.visible = false


func _finish_draining() -> void:
	state = DrainState.DRAINED
	water.visible = false
	water.process_mode = Node.PROCESS_MODE_DISABLED
