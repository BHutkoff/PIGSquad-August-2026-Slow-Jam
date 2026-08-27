class_name ScreenTransition
extends CanvasLayer

@export_range(0.1, 3.0, 0.05) var fade_duration: float = 0.85
@export_range(0.0, 1.0, 0.05) var black_pause_duration: float = 0.25

@onready var blocker: ColorRect = $Black

var _active_tween: Tween


func _ready() -> void:
	_set_alpha(0.0)
	blocker.mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_black_immediately() -> void:
	_kill_active_tween()
	_set_alpha(1.0)
	blocker.mouse_filter = Control.MOUSE_FILTER_STOP


func clear_immediately() -> void:
	_kill_active_tween()
	_set_alpha(0.0)
	blocker.mouse_filter = Control.MOUSE_FILTER_IGNORE


func fade_to_black() -> void:
	blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	await _tween_alpha(1.0)
	if black_pause_duration > 0.0:
		await get_tree().create_timer(black_pause_duration).timeout


func fade_from_black() -> void:
	await _tween_alpha(0.0)
	blocker.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _tween_alpha(target_alpha: float) -> void:
	_kill_active_tween()
	_active_tween = create_tween()
	_active_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_active_tween.tween_method(_set_alpha, blocker.color.a, target_alpha, fade_duration)
	await _active_tween.finished


func _set_alpha(alpha: float) -> void:
	blocker.color = Color(0.0, 0.0, 0.0, clampf(alpha, 0.0, 1.0))


func _kill_active_tween() -> void:
	if _active_tween != null and _active_tween.is_valid():
		_active_tween.kill()
