class_name InvestigationState
extends Node

signal clue_discovered(clue_id: StringName)
signal candidate_discovered(candidate_id: StringName)

var _discovered_clues: Array[StringName] = []
var _clue_display_names: Dictionary = {}
var _clue_observations: Dictionary = {}
var _clue_categories: Dictionary = {}
var _discovered_candidates: Array[StringName] = []


func discover_clue(
		clue_id: StringName,
		display_name: String,
		observation: String,
		category: StringName,
		reveals_candidate_ids: Array[StringName] = []
	) -> bool:
	if clue_id.is_empty():
		push_warning("Cannot discover a clue with an empty clue ID.")
		return false
	if _discovered_clues.has(clue_id):
		return false

	_discovered_clues.append(clue_id)
	_clue_display_names[clue_id] = display_name
	_clue_observations[clue_id] = observation
	_clue_categories[clue_id] = category
	print("Clue discovered: %s [%s]" % [clue_id, category])
	print("Total clues discovered: %d" % _discovered_clues.size())
	for candidate_id in reveals_candidate_ids:
		if candidate_id.is_empty() or _discovered_candidates.has(candidate_id):
			continue
		_discovered_candidates.append(candidate_id)
		print("Deduction possibility discovered: %s" % candidate_id)
		candidate_discovered.emit(candidate_id)
	clue_discovered.emit(clue_id)
	return true


func has_discovered(clue_id: StringName) -> bool:
	return _discovered_clues.has(clue_id)


func get_discovered_clues() -> Array[StringName]:
	return _discovered_clues.duplicate()


func get_clue_display_name(clue_id: StringName) -> String:
	return str(_clue_display_names.get(clue_id, "Unknown Evidence"))


func get_clue_observation(clue_id: StringName) -> String:
	return str(_clue_observations.get(clue_id, ""))


func get_clue_category(clue_id: StringName) -> StringName:
	return StringName(_clue_categories.get(clue_id, &"GENERAL"))


func has_discovered_candidate(candidate_id: StringName) -> bool:
	return _discovered_candidates.has(candidate_id)


func get_discovered_candidates() -> Array[StringName]:
	return _discovered_candidates.duplicate()
