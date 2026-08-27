class_name GameSettings
extends Node

signal mouse_sensitivity_changed(value: float)

const SETTINGS_PATH: String = "user://settings.cfg"
const DEFAULT_MASTER_VOLUME: float = 1.0
const DEFAULT_BRIGHTNESS: float = 1.0
const DEFAULT_MOUSE_SENSITIVITY: float = 0.12
const DEFAULT_FULLSCREEN: bool = false
const MINIMUM_VOLUME_DB: float = -80.0

var master_volume: float = DEFAULT_MASTER_VOLUME
var brightness: float = DEFAULT_BRIGHTNESS
var mouse_sensitivity: float = DEFAULT_MOUSE_SENSITIVITY
var fullscreen: bool = DEFAULT_FULLSCREEN


func _ready() -> void:
	load_settings()
	apply_settings()


func load_settings() -> void:
	var config: ConfigFile = ConfigFile.new()
	var load_error: Error = config.load(SETTINGS_PATH)
	if load_error != OK:
		return
	master_volume = clampf(
		float(config.get_value("audio", "master_volume", DEFAULT_MASTER_VOLUME)), 0.0, 1.0
	)
	brightness = clampf(
		float(config.get_value("display", "brightness", DEFAULT_BRIGHTNESS)), 0.75, 1.25
	)
	mouse_sensitivity = clampf(
		float(
			config.get_value(
				"controls", "mouse_sensitivity", DEFAULT_MOUSE_SENSITIVITY
			)
		),
		0.04,
		0.30
	)
	fullscreen = bool(config.get_value("display", "fullscreen", DEFAULT_FULLSCREEN))


func save_settings() -> void:
	var config: ConfigFile = ConfigFile.new()
	config.set_value("audio", "master_volume", master_volume)
	config.set_value("display", "brightness", brightness)
	config.set_value("controls", "mouse_sensitivity", mouse_sensitivity)
	config.set_value("display", "fullscreen", fullscreen)
	var save_error: Error = config.save(SETTINGS_PATH)
	if save_error != OK:
		push_warning("Unable to save settings.cfg (error %d)." % save_error)


func apply_settings() -> void:
	_apply_master_volume()
	_apply_brightness()
	_apply_fullscreen()
	mouse_sensitivity_changed.emit(mouse_sensitivity)


func set_master_volume(value: float) -> void:
	master_volume = clampf(value, 0.0, 1.0)
	_apply_master_volume()
	save_settings()


func set_brightness(value: float) -> void:
	brightness = clampf(value, 0.75, 1.25)
	_apply_brightness()
	save_settings()


func set_mouse_sensitivity(value: float) -> void:
	mouse_sensitivity = clampf(value, 0.04, 0.30)
	mouse_sensitivity_changed.emit(mouse_sensitivity)
	save_settings()


func set_fullscreen(value: bool) -> void:
	fullscreen = value
	_apply_fullscreen()
	save_settings()


func _apply_master_volume() -> void:
	var master_bus_index: int = AudioServer.get_bus_index("Master")
	if master_bus_index < 0:
		push_warning("The Master audio bus could not be found.")
		return
	var muted: bool = master_volume <= 0.0001
	AudioServer.set_bus_mute(master_bus_index, muted)
	var volume_db: float = MINIMUM_VOLUME_DB
	if not muted:
		volume_db = linear_to_db(master_volume)
	AudioServer.set_bus_volume_db(master_bus_index, volume_db)


func _apply_brightness() -> void:
	var targets: Array[Node] = get_tree().get_nodes_in_group("echolocation_target")
	for target in targets:
		if target.has_method("set_brightness_multiplier"):
			target.call("set_brightness_multiplier", brightness)


func _apply_fullscreen() -> void:
	var mode: int = (
		DisplayServer.WINDOW_MODE_FULLSCREEN
		if fullscreen
		else DisplayServer.WINDOW_MODE_WINDOWED
	)
	DisplayServer.window_set_mode(mode)
