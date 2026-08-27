class_name EcholocationControlHint
extends CanvasLayer

@export_range(1.0, 8.0, 0.25) var display_duration: float = 3.0
@export_range(0.05, 1.0, 0.05) var fade_duration: float = 0.25
@export_range(0.2, 2.0, 0.05) var pulse_duration: float = 0.55

@onready var hint: Control = $Hint
@onready var right_button: PanelContainer = $Hint/Center/Content/MouseGraphic/RightButton

var _display_tween: Tween
var _pulse_tween: Tween


func _ready() -> void:
	hint.visible = false
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE


func show_hint() -> void:
	_stop_tweens()
	hint.visible = true
	hint.modulate.a = 0.0
	right_button.modulate.a = 1.0
	_pulse_tween = create_tween().set_loops()
	_pulse_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_pulse_tween.tween_property(right_button, "modulate:a", 0.4, pulse_duration)
	_pulse_tween.tween_property(right_button, "modulate:a", 1.0, pulse_duration)
	_display_tween = create_tween()
	_display_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_display_tween.tween_property(hint, "modulate:a", 1.0, fade_duration)
	_display_tween.tween_interval(maxf(display_duration - fade_duration * 2.0, 0.0))
	_display_tween.tween_property(hint, "modulate:a", 0.0, fade_duration)
	_display_tween.tween_callback(_finish_hint)


func _finish_hint() -> void:
	if _pulse_tween != null and _pulse_tween.is_valid():
		_pulse_tween.kill()
	hint.visible = false


func _stop_tweens() -> void:
	if _display_tween != null and _display_tween.is_valid():
		_display_tween.kill()
	if _pulse_tween != null and _pulse_tween.is_valid():
		_pulse_tween.kill()

