class_name MainMenu
extends Control

const CASE1_SCENE: String = "res://scenes/case1/case1.tscn"

@onready var main_panel: VBoxContainer = $Center/Panel/Margin/Layout/MainPanel
@onready var level_select_panel: VBoxContainer = $Center/Panel/Margin/Layout/LevelSelectPanel
@onready var settings_panel: VBoxContainer = $Center/Panel/Margin/Layout/SettingsPanel
@onready var quit_button: Button = $Center/Panel/Margin/Layout/MainPanel/Quit
@onready var master_volume_slider: HSlider = $Center/Panel/Margin/Layout/SettingsPanel/MasterVolume/Slider
@onready var master_volume_value: Label = $Center/Panel/Margin/Layout/SettingsPanel/MasterVolume/Value
@onready var brightness_slider: HSlider = $Center/Panel/Margin/Layout/SettingsPanel/Brightness/Slider
@onready var brightness_value: Label = $Center/Panel/Margin/Layout/SettingsPanel/Brightness/Value
@onready var mouse_sensitivity_slider: HSlider = $Center/Panel/Margin/Layout/SettingsPanel/MouseSensitivity/Slider
@onready var mouse_sensitivity_value: Label = $Center/Panel/Margin/Layout/SettingsPanel/MouseSensitivity/Value
@onready var fullscreen_toggle: CheckButton = $Center/Panel/Margin/Layout/SettingsPanel/Fullscreen

var _updating_controls: bool = false


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	$Center/Panel/Margin/Layout/MainPanel/Play.pressed.connect(_load_case1)
	$Center/Panel/Margin/Layout/MainPanel/LevelSelect.pressed.connect(_show_level_select)
	$Center/Panel/Margin/Layout/MainPanel/Settings.pressed.connect(_show_settings)
	quit_button.pressed.connect(_quit_game)
	$Center/Panel/Margin/Layout/LevelSelectPanel/Case1.pressed.connect(_load_case1)
	$Center/Panel/Margin/Layout/LevelSelectPanel/Back.pressed.connect(_show_main)
	$Center/Panel/Margin/Layout/SettingsPanel/Back.pressed.connect(_show_main)
	master_volume_slider.value_changed.connect(_on_master_volume_changed)
	brightness_slider.value_changed.connect(_on_brightness_changed)
	mouse_sensitivity_slider.value_changed.connect(_on_mouse_sensitivity_changed)
	fullscreen_toggle.toggled.connect(_on_fullscreen_toggled)
	quit_button.disabled = OS.has_feature("web")
	_sync_settings_controls()
	_show_main()


func _load_case1() -> void:
	CaseLaunchContext.begin_normal_case1()
	var change_error: Error = get_tree().change_scene_to_file(CASE1_SCENE)
	if change_error != OK:
		push_error("Unable to load Case 1 (error %d)." % change_error)


func _show_main() -> void:
	main_panel.visible = true
	level_select_panel.visible = false
	settings_panel.visible = false


func _show_level_select() -> void:
	main_panel.visible = false
	level_select_panel.visible = true
	settings_panel.visible = false


func _show_settings() -> void:
	_sync_settings_controls()
	main_panel.visible = false
	level_select_panel.visible = false
	settings_panel.visible = true


func _quit_game() -> void:
	if OS.has_feature("web"):
		return
	get_tree().quit()


func _sync_settings_controls() -> void:
	_updating_controls = true
	master_volume_slider.value = SettingsManager.master_volume * 100.0
	brightness_slider.value = SettingsManager.brightness * 100.0
	mouse_sensitivity_slider.value = SettingsManager.mouse_sensitivity
	fullscreen_toggle.button_pressed = SettingsManager.fullscreen
	_update_value_labels()
	_updating_controls = false


func _on_master_volume_changed(value: float) -> void:
	master_volume_value.text = "%d%%" % int(round(value))
	if not _updating_controls:
		SettingsManager.set_master_volume(value / 100.0)


func _on_brightness_changed(value: float) -> void:
	brightness_value.text = "%d%%" % int(round(value))
	if not _updating_controls:
		SettingsManager.set_brightness(value / 100.0)


func _on_mouse_sensitivity_changed(value: float) -> void:
	mouse_sensitivity_value.text = "%.2f" % value
	if not _updating_controls:
		SettingsManager.set_mouse_sensitivity(value)


func _on_fullscreen_toggled(enabled: bool) -> void:
	if not _updating_controls:
		SettingsManager.set_fullscreen(enabled)


func _update_value_labels() -> void:
	master_volume_value.text = "%d%%" % int(round(master_volume_slider.value))
	brightness_value.text = "%d%%" % int(round(brightness_slider.value))
	mouse_sensitivity_value.text = "%.2f" % mouse_sensitivity_slider.value
