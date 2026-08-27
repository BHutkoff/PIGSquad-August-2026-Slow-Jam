class_name Interactable
extends Node

@export var display_name: String = "Interactable"
@export_multiline var observation: String = ""


func interact(player: Node) -> void:
	var gameplay_audio: GameplayAudio = _get_gameplay_audio(player)
	if gameplay_audio != null:
		gameplay_audio.play_interaction()
	var message: String = observation
	if message.is_empty():
		message = "Interacted with %s" % display_name
	print(message)
	_show_observation(player, message, false)


func _show_observation(player: Node, message: String, clue_discovered: bool) -> void:
	var display: ObservationDisplay = player.get_node_or_null("ObservationDisplay") as ObservationDisplay
	if display == null:
		push_warning("Player needs an ObservationDisplay child to show inspection text.")
		return
	display.show_observation(message, clue_discovered)


func _get_gameplay_audio(player: Node) -> GameplayAudio:
	return player.get_node_or_null("GameplayAudio") as GameplayAudio
