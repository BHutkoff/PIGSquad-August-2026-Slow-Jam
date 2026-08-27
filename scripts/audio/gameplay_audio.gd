class_name GameplayAudio
extends Node

@export_category("Audio Streams")
@export var interaction_stream: AudioStream
@export var clue_discovered_stream: AudioStream
@export var case_solved_stream: AudioStream

@export_category("Volume")
@export_range(-40.0, 6.0, 0.5) var interaction_volume_db: float = -14.0
@export_range(-40.0, 6.0, 0.5) var clue_discovered_volume_db: float = -8.0
@export_range(-40.0, 6.0, 0.5) var case_solved_volume_db: float = -5.0

@onready var interaction_player: AudioStreamPlayer = $InteractionPlayer
@onready var clue_player: AudioStreamPlayer = $ClueDiscoveredPlayer
@onready var solved_player: AudioStreamPlayer = $CaseSolvedPlayer


func play_interaction() -> void:
	_play_stream(interaction_player, interaction_stream, interaction_volume_db)


func play_clue_discovered() -> void:
	SFXManager.play_writing()


func play_case_solved() -> void:
	_play_stream(solved_player, case_solved_stream, case_solved_volume_db)


func play_jump() -> void:
	SFXManager.play_jump()


func play_land() -> void:
	SFXManager.play_land()


func play_footstep(in_water: bool) -> void:
	SFXManager.play_footstep(in_water)


func _play_stream(player: AudioStreamPlayer, stream: AudioStream, volume_db: float) -> void:
	if stream == null:
		return
	player.stream = stream
	player.volume_db = volume_db
	player.play()
