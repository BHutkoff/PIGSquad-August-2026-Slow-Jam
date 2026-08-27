extends Node

const PLAYER_POOL_SIZE: int = 12

const JUMP_STREAM: AudioStream = preload("res://soundEffects/Sound Effects/jump_v1.wav")
const LAND_STREAM: AudioStream = preload("res://soundEffects/Sound Effects/jump_land_v1.wav")
const UI_SELECT_STREAM: AudioStream = preload("res://soundEffects/Sound Effects/ui_select_v1.wav")
const WRITING_STREAM: AudioStream = preload("res://soundEffects/Sound Effects/writing_v1.wav")

var normal_footstep_streams: Array[AudioStream] = [
	preload("res://soundEffects/Sound Effects/walk_a_v1.wav"),
	preload("res://soundEffects/Sound Effects/walk_b_v1.wav"),
	preload("res://soundEffects/Sound Effects/walk_c_v1.wav"),
]
var water_footstep_streams: Array[AudioStream] = [
	preload("res://soundEffects/Sound Effects/water_walk_a_v1.wav"),
	preload("res://soundEffects/Sound Effects/water_walk_b_v1.wav"),
	preload("res://soundEffects/Sound Effects/water_walk_c_v1.wav"),
]
var echolocation_streams: Array[AudioStream] = [
	preload("res://soundEffects/Sound Effects/echolocation_C3_v1.wav"),
	preload("res://soundEffects/Sound Effects/echolocation_Eb3_v1.wav"),
	preload("res://soundEffects/Sound Effects/echolocation_F3_v1.wav"),
	preload("res://soundEffects/Sound Effects/echolocation_G3_v1.wav"),
	preload("res://soundEffects/Sound Effects/echolocation_Bb3_v1.wav"),
	preload("res://soundEffects/Sound Effects/echolocation_C4_v1.wav"),
]

@export_category("Volume")
@export_range(-40.0, 6.0, 0.5) var jump_volume_db: float = -7.0
@export_range(-40.0, 6.0, 0.5) var landing_volume_db: float = -7.0
@export_range(-40.0, 6.0, 0.5) var footstep_volume_db: float = -10.0
@export_range(-40.0, 6.0, 0.5) var water_footstep_volume_db: float = -9.0
@export_range(-40.0, 6.0, 0.5) var ui_select_volume_db: float = -10.0
@export_range(-40.0, 6.0, 0.5) var writing_volume_db: float = -7.0
@export_range(-40.0, 6.0, 0.5) var echolocation_volume_db: float = -6.0

@export_category("Variation")
@export_range(0.0, 0.08, 0.005) var footstep_pitch_variation: float = 0.025
@export var debug_output_enabled: bool = false

var _players: Array[AudioStreamPlayer] = []
var _pool_cursor: int = 0
var _last_normal_footstep_index: int = -1
var _last_water_footstep_index: int = -1
var _last_echolocation_index: int = -1


func _ready() -> void:
	for index in PLAYER_POOL_SIZE:
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		player.name = "SFXPlayer%d" % index
		player.bus = &"Master"
		add_child(player)
		_players.append(player)
	get_tree().node_added.connect(_on_node_added)
	call_deferred("_connect_existing_buttons")


func play_jump() -> void:
	_play_stream(JUMP_STREAM, jump_volume_db)
	_debug("SFX: Jump")


func play_land() -> void:
	_play_stream(LAND_STREAM, landing_volume_db)
	_debug("SFX: Land")


func play_footstep(in_water: bool) -> void:
	var streams: Array[AudioStream] = (
		water_footstep_streams if in_water else normal_footstep_streams
	)
	var previous_index: int = (
		_last_water_footstep_index if in_water else _last_normal_footstep_index
	)
	var selected_index: int = _choose_random_index(streams.size(), previous_index)
	if selected_index < 0:
		return
	if in_water:
		_last_water_footstep_index = selected_index
	else:
		_last_normal_footstep_index = selected_index
	var pitch_offset: float = randf_range(-footstep_pitch_variation, footstep_pitch_variation)
	var volume_db: float = water_footstep_volume_db if in_water else footstep_volume_db
	_play_stream(streams[selected_index], volume_db, 1.0 + pitch_offset)
	var surface_name: String = "water" if in_water else "normal"
	_debug("SFX: Footstep [%s_%d]" % [surface_name, selected_index + 1])


func play_ui_select() -> void:
	_play_stream(UI_SELECT_STREAM, ui_select_volume_db)
	_debug("SFX: UI Select")


func play_writing() -> void:
	_play_stream(WRITING_STREAM, writing_volume_db)
	_debug("SFX: Writing")


func play_echolocation() -> void:
	var selected_index: int = _choose_random_index(
		echolocation_streams.size(), _last_echolocation_index
	)
	if selected_index < 0:
		return
	_last_echolocation_index = selected_index
	_play_stream(echolocation_streams[selected_index], echolocation_volume_db)
	_debug("SFX: Echolocation [echo_%d]" % (selected_index + 1))


func _play_stream(stream: AudioStream, volume_db: float, pitch_scale: float = 1.0) -> void:
	if stream == null or _players.is_empty():
		return
	var selected_player: AudioStreamPlayer
	for player in _players:
		if not player.playing:
			selected_player = player
			break
	if selected_player == null:
		selected_player = _players[_pool_cursor]
		_pool_cursor = (_pool_cursor + 1) % _players.size()
		selected_player.stop()
	selected_player.stream = stream
	selected_player.volume_db = volume_db
	selected_player.pitch_scale = pitch_scale
	selected_player.play()


func _choose_random_index(stream_count: int, previous_index: int) -> int:
	if stream_count <= 0:
		return -1
	if stream_count == 1:
		return 0
	var selected_index: int = randi_range(0, stream_count - 1)
	if selected_index == previous_index:
		selected_index = (selected_index + randi_range(1, stream_count - 1)) % stream_count
	return selected_index


func _on_node_added(node: Node) -> void:
	if node is BaseButton:
		call_deferred("_connect_button", node)


func _connect_existing_buttons() -> void:
	var root: Window = get_tree().root
	_connect_buttons_recursive(root)


func _connect_buttons_recursive(node: Node) -> void:
	if node is BaseButton:
		_connect_button(node as BaseButton)
	for child: Node in node.get_children():
		_connect_buttons_recursive(child)


func _connect_button(button: BaseButton) -> void:
	if not is_instance_valid(button):
		return
	var callback: Callable = Callable(self, "_on_button_pressed")
	if not button.pressed.is_connected(callback):
		button.pressed.connect(callback)


func _on_button_pressed() -> void:
	play_ui_select()


func _debug(message: String) -> void:
	if debug_output_enabled:
		print(message)
