class_name EcholocationAudio
extends Node

@export_category("Audio Streams")
@export var pulse_stream: AudioStream
@export var object_echo_stream: AudioStream

@export_category("Volume")
@export_range(-40.0, 6.0, 0.5) var pulse_volume_db: float = -6.0
@export_range(-40.0, 6.0, 0.5) var object_echo_volume_db: float = -16.0

@export_category("Spatial Echo")
@export_range(1.0, 50.0, 0.5) var object_echo_max_distance: float = 18.0
@export_range(0.1, 10.0, 0.1) var object_echo_unit_size: float = 3.0

@onready var pulse_player: AudioStreamPlayer = $PulsePlayer

var _scheduled_positions: Array[Vector3] = []
var _scheduled_delays: Array[float] = []


func _ready() -> void:
	set_process(false)


func _process(delta: float) -> void:
	var index: int = _scheduled_delays.size() - 1
	while index >= 0:
		_scheduled_delays[index] -= delta
		if _scheduled_delays[index] <= 0.0:
			_play_spatial_echo(_scheduled_positions[index])
			_scheduled_positions.remove_at(index)
			_scheduled_delays.remove_at(index)
		index -= 1
	if _scheduled_delays.is_empty():
		set_process(false)


func begin_pulse() -> void:
	_scheduled_positions.clear()
	_scheduled_delays.clear()
	SFXManager.play_echolocation()


func schedule_object_echo(world_position: Vector3, delay: float) -> void:
	if object_echo_stream == null:
		return
	_scheduled_positions.append(world_position)
	_scheduled_delays.append(maxf(delay, 0.0))
	set_process(true)


func _play_spatial_echo(world_position: Vector3) -> void:
	var echo_player: AudioStreamPlayer3D = AudioStreamPlayer3D.new()
	var scene_root: Node = get_tree().current_scene
	scene_root.add_child(echo_player)
	echo_player.global_position = world_position
	echo_player.stream = object_echo_stream
	echo_player.volume_db = object_echo_volume_db
	echo_player.max_distance = object_echo_max_distance
	echo_player.unit_size = object_echo_unit_size
	echo_player.finished.connect(echo_player.queue_free)
	echo_player.play()
