class_name EndingController
extends CanvasLayer

signal success_ending_started
signal failure_ending_started
signal intro_finished

const CREDITS_SCENE: String = "res://scenes/ui/credits.tscn"
const MAIN_MENU_SCENE: String = "res://scenes/ui/main_menu.tscn"
const SUCCESS_TITLE_COLOR: Color = Color("b3ebff")
const FAILURE_TITLE_COLOR: Color = Color("c94444")

@export_category("Case Intro")
@export var play_intro_on_ready: bool = false
@export_range(0.1, 2.0, 0.05) var content_fade_duration: float = 0.5
@export var intro_voiceover: AudioStream

@onready var overlay: Control = $Overlay
@onready var intro_content: VBoxContainer = $Overlay/IntroCenter/IntroContent
@onready var intro_continue: Button = $Overlay/IntroCenter/IntroContent/Continue
@onready var ending_content: VBoxContainer = $Overlay/EndingCenter/EndingContent
@onready var ending_title: Label = $Overlay/EndingCenter/EndingContent/Title
@onready var ending_message: Label = $Overlay/EndingCenter/EndingContent/Message
@onready var win_continue: Button = $Overlay/EndingCenter/EndingContent/WinContinue
@onready var retry_button: Button = $Overlay/EndingCenter/EndingContent/LossButtons/RetryCase
@onready var main_menu_button: Button = $Overlay/EndingCenter/EndingContent/LossButtons/MainMenu
@onready var loss_buttons: HBoxContainer = $Overlay/EndingCenter/EndingContent/LossButtons
@onready var transition: ScreenTransition = $ScreenTransition
@onready var intro_voiceover_player: AudioStreamPlayer = $IntroVoiceover

var _input_locked: bool = false
var _intro_continue_available: bool = false
var _sequence_running: bool = false


func _ready() -> void:
	overlay.visible = false
	intro_continue.disabled = true
	intro_continue.pressed.connect(_continue_intro)
	win_continue.pressed.connect(_open_credits)
	retry_button.pressed.connect(_retry_case)
	main_menu_button.pressed.connect(_return_to_main_menu)
	if play_intro_on_ready:
		start_intro()


func start_intro() -> void:
	if _input_locked or _sequence_running:
		return
	_input_locked = true
	transition.set_black_immediately()
	call_deferred("_start_intro")


func start_retry_entry() -> void:
	if _input_locked or _sequence_running:
		return
	_input_locked = true
	transition.set_black_immediately()
	call_deferred("_fade_retry_into_gameplay")


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.echo:
		return
	if (
		_intro_continue_available
		and event.is_action_pressed("jump")
	):
		_continue_intro()
		get_viewport().set_input_as_handled()


func begin_ending(success: bool) -> void:
	if _sequence_running:
		return
	_sequence_running = true
	_input_locked = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	await transition.fade_to_black()
	_show_ending_content(success)
	await transition.fade_from_black()
	_sequence_running = false


func is_ending_active() -> bool:
	return _input_locked


func is_input_locked() -> bool:
	return _input_locked


func _start_intro() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if intro_voiceover != null:
		intro_voiceover_player.stream = intro_voiceover
		intro_voiceover_player.play()
	overlay.visible = true
	intro_content.visible = true
	ending_content.visible = false
	intro_content.modulate.a = 1.0
	transition.clear_immediately()
	_intro_continue_available = true
	intro_continue.disabled = false
	intro_continue.text = "CONTINUE  (SPACE)"
	intro_continue.grab_focus()
	_sequence_running = false


func _continue_intro() -> void:
	if not _intro_continue_available or _sequence_running:
		return
	_sequence_running = true
	_intro_continue_available = false
	intro_continue.disabled = true
	await _fade_control(intro_content, 0.0)
	transition.set_black_immediately()
	intro_content.visible = false
	overlay.visible = false
	await transition.fade_from_black()
	_input_locked = false
	_sequence_running = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	intro_finished.emit()


func _fade_retry_into_gameplay() -> void:
	_sequence_running = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	await transition.fade_from_black()
	_input_locked = false
	_sequence_running = false


func _show_ending_content(success: bool) -> void:
	overlay.visible = true
	intro_content.visible = false
	ending_content.visible = true
	ending_content.modulate.a = 1.0
	win_continue.visible = success
	loss_buttons.visible = not success
	if success:
		ending_title.add_theme_color_override("font_color", SUCCESS_TITLE_COLOR)
		ending_title.text = "CASE SOLVED"
		ending_message.text = (
			"Your theory connects the suspect, motive, and murder weapon into a case "
			+ "that can hold up.\n\nThe evidence supports your accusation.\n\n"
			+ "Bramble Bear's killer will face justice.\n\nCase closed."
		)
		win_continue.grab_focus()
		success_ending_started.emit()
	else:
		ending_title.add_theme_color_override("font_color", FAILURE_TITLE_COLOR)
		ending_title.text = "CASE FAILED"
		ending_message.text = (
			"Your theory couldn't connect the suspect, motive, and weapon strongly enough "
			+ "to secure a conviction.\n\nThe accused was brought to trial, but the case "
			+ "fell apart under scrutiny.\n\nWithout enough connecting evidence, they were "
			+ "released.\n\nThe investigation remains unresolved."
		)
		retry_button.grab_focus()
		failure_ending_started.emit()


func _fade_control(control: Control, target_alpha: float) -> void:
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(control, "modulate:a", target_alpha, content_fade_duration)
	await tween.finished


func _open_credits() -> void:
	_change_scene(CREDITS_SCENE, "Credits")


func _retry_case() -> void:
	CaseLaunchContext.request_case1_retry()
	var reload_error: Error = get_tree().reload_current_scene()
	if reload_error != OK:
		push_error("Unable to retry Case 1 (error %d)." % reload_error)


func _return_to_main_menu() -> void:
	_change_scene(MAIN_MENU_SCENE, "Main Menu")


func _change_scene(scene_path: String, scene_name: String) -> void:
	var change_error: Error = get_tree().change_scene_to_file(scene_path)
	if change_error != OK:
		push_error("Unable to load %s (error %d)." % [scene_name, change_error])
