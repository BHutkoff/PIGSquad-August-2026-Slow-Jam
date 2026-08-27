class_name DrainPlugInteractable
extends Interactable

signal plug_pulled(player: Node)

var _interaction_enabled: bool = true


func interact(player: Node) -> void:
	if not _interaction_enabled:
		return
	plug_pulled.emit(player)


func set_interaction_enabled(enabled: bool) -> void:
	_interaction_enabled = enabled
	var collision_shape: CollisionShape3D = get_node_or_null("CollisionShape3D") as CollisionShape3D
	if collision_shape != null:
		collision_shape.set_deferred("disabled", not enabled)


func show_pull_observation(player: Node) -> void:
	var gameplay_audio: GameplayAudio = _get_gameplay_audio(player)
	if gameplay_audio != null:
		gameplay_audio.play_interaction()
	print(observation)
	_show_observation(player, observation, false)
