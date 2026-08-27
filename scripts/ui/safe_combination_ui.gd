class_name SafeCombinationUI
extends CanvasLayer

signal code_submitted(code: String)
signal cancelled

const MAX_DIGITS: int = 4

@onready var entry_label: Label = $UIRoot/Center/Panel/Margin/Layout/EntryLabel
@onready var feedback_label: Label = $UIRoot/Center/Panel/Margin/Layout/FeedbackLabel

var _entered_digits: String = ""


func _ready() -> void:
	visible = false
	for digit: int in range(10):
		var button_path: NodePath = NodePath(
			"UIRoot/Center/Panel/Margin/Layout/Keypad/Digit%d" % digit
		)
		var digit_button: Button = get_node(button_path) as Button
		digit_button.pressed.connect(_on_digit_pressed.bind(digit))
	$UIRoot/Center/Panel/Margin/Layout/Actions/Clear.pressed.connect(_on_clear_pressed)
	$UIRoot/Center/Panel/Margin/Layout/Actions/Enter.pressed.connect(_on_enter_pressed)
	$UIRoot/Center/Panel/Margin/Layout/Cancel.pressed.connect(_on_cancel_pressed)
	_update_entry_display()


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		cancelled.emit()
		get_viewport().set_input_as_handled()


func open_ui() -> void:
	_entered_digits = ""
	feedback_label.text = ""
	_update_entry_display()
	visible = true
	add_to_group("gameplay_modal")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func close_ui() -> void:
	visible = false
	remove_from_group("gameplay_modal")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func show_incorrect_combination() -> void:
	feedback_label.text = "Incorrect combination."
	_entered_digits = ""
	_update_entry_display()


func _on_digit_pressed(digit: int) -> void:
	if _entered_digits.length() >= MAX_DIGITS:
		return
	_entered_digits += str(digit)
	feedback_label.text = ""
	_update_entry_display()


func _on_clear_pressed() -> void:
	_entered_digits = ""
	feedback_label.text = ""
	_update_entry_display()


func _on_enter_pressed() -> void:
	code_submitted.emit(_entered_digits)


func _on_cancel_pressed() -> void:
	cancelled.emit()


func _update_entry_display() -> void:
	var slots: Array[String] = []
	for index: int in range(MAX_DIGITS):
		slots.append(_entered_digits[index] if index < _entered_digits.length() else "–")
	entry_label.text = "  ".join(slots)
