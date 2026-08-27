class_name SafeController
extends Interactable

@export var combination_code: String = "1931"
@export_range(0.1, 3.0, 0.05) var door_open_duration: float = 0.65
@export_range(45.0, 135.0, 1.0) var door_open_angle_degrees: float = 100.0

@export_category("References")
@export var door_hinge: Node3D
@export var combination_ui: SafeCombinationUI

var is_unlocked: bool = false


func _ready() -> void:
	if door_hinge == null or combination_ui == null:
		push_warning("SafeController needs door hinge and combination UI references.")
		return
	combination_ui.code_submitted.connect(_on_code_submitted)
	combination_ui.cancelled.connect(_on_ui_cancelled)


func open_combination_ui() -> void:
	if is_unlocked or combination_ui == null:
		return
	combination_ui.open_ui()


func interact(player: Node) -> void:
	if is_unlocked:
		return
	var gameplay_audio: GameplayAudio = _get_gameplay_audio(player)
	if gameplay_audio != null:
		gameplay_audio.play_interaction()
	open_combination_ui()


func _on_code_submitted(code: String) -> void:
	if code != combination_code:
		combination_ui.show_incorrect_combination()
		return
	is_unlocked = true
	combination_ui.close_ui()
	_open_door()


func _on_ui_cancelled() -> void:
	combination_ui.close_ui()


func _open_door() -> void:
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(
		door_hinge,
		"rotation:y",
		deg_to_rad(door_open_angle_degrees),
		door_open_duration
	)
