class_name Clue
extends Interactable

enum ClueCategory {
	GENERAL,
	WEAPON,
	MOTIVE,
	SUSPECT,
}

@export var clue_id: StringName
@export var clue_category: ClueCategory = ClueCategory.GENERAL
@export var reveals_candidate_ids: Array[StringName] = []

var inspected: bool = false


func interact(player: Node) -> void:
	var gameplay_audio: GameplayAudio = _get_gameplay_audio(player)
	if gameplay_audio != null:
		gameplay_audio.play_interaction()
	print(observation)
	var first_discovery: bool = false
	if not inspected:
		var investigation_state: InvestigationState = (
			player.get_node_or_null("InvestigationState") as InvestigationState
		)
		if investigation_state == null:
			push_warning("Player needs an InvestigationState child to register clues.")
		else:
			first_discovery = investigation_state.discover_clue(
				clue_id,
				display_name,
				observation,
				get_category_name(),
				reveals_candidate_ids
			)
		inspected = true
	if first_discovery and gameplay_audio != null:
		gameplay_audio.play_clue_discovered()

	_show_observation(player, observation, first_discovery)


func get_category_name() -> StringName:
	match clue_category:
		ClueCategory.WEAPON:
			return &"WEAPON"
		ClueCategory.MOTIVE:
			return &"MOTIVE"
		ClueCategory.SUSPECT:
			return &"SUSPECT"
		_:
			return &"GENERAL"
