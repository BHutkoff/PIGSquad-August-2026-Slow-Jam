class_name CaseManager
extends Node

signal case_solved(theory: CaseTheory)
signal case_failed(theory: CaseTheory)

@export_category("Case")
@export var case_data: CaseData
@export var play_intro_on_start: bool = false

@export_category("References")
@export var investigation_state: InvestigationState
@export var case_ui: CaseUI
@export var gameplay_audio: GameplayAudio
@export var ending_controller: EndingController
@export var control_hint: EcholocationControlHint

@export_category("Debug")
@export var debug_input: bool = true
@export var debug_accusation_validation: bool = true

var current_theory: CaseTheory = CaseTheory.new()
var accusation_submitted: bool = false


func _ready() -> void:
	if (
		case_data == null
		or investigation_state == null
		or case_ui == null
		or ending_controller == null
	):
		push_warning(
			"CaseManager needs CaseData, InvestigationState, CaseUI, and EndingController references."
		)
		return
	investigation_state.clue_discovered.connect(_on_clue_discovered)
	case_ui.theory_selected.connect(_on_theory_selected)
	case_ui.accusation_confirmed.connect(_on_accusation_confirmed)
	case_ui.return_requested.connect(close_deduction)
	ending_controller.success_ending_started.connect(_on_success_ending_started)
	ending_controller.intro_finished.connect(_on_intro_finished)
	case_ui.configure(
		case_data.case_title,
		case_data.hud_case_title,
		case_data.case_question,
		case_data.case_objective
	)
	_refresh_case_ui()
	if play_intro_on_start:
		if CaseLaunchContext.consume_case1_intro_skip():
			ending_controller.start_retry_entry()
		else:
			ending_controller.start_intro()


func _input(event: InputEvent) -> void:
	if accusation_submitted:
		return
	if ending_controller != null and ending_controller.is_input_locked():
		return
	if not get_tree().get_nodes_in_group("gameplay_modal").is_empty():
		return
	if event is InputEventKey and event.echo:
		return
	if event.is_action_pressed("review_case"):
		if debug_input:
			print("Review case input received")
		if case_ui != null and case_ui.is_deduction_open():
			close_deduction()
		else:
			open_deduction()
		get_viewport().set_input_as_handled()


func open_deduction() -> void:
	if case_ui == null or investigation_state == null or case_data == null:
		return
	if debug_input:
		print("Opening deduction UI")
	_refresh_case_ui()
	case_ui.open_case_file()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func close_deduction() -> void:
	if case_ui == null:
		return
	case_ui.close_deduction()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _on_clue_discovered(_clue_id: StringName) -> void:
	_refresh_case_ui()


func _on_theory_selected(category: int, candidate_id: StringName) -> void:
	match category:
		DeductionCandidate.Category.WEAPON:
			current_theory.weapon_id = candidate_id
		DeductionCandidate.Category.MOTIVE:
			current_theory.motive_id = candidate_id
		DeductionCandidate.Category.SUSPECT:
			current_theory.suspect_id = candidate_id
		_:
			return
	print("Current theory updated: %s" % candidate_id)
	_refresh_case_ui()


func _refresh_case_ui() -> void:
	if case_ui == null or investigation_state == null or case_data == null:
		return
	case_ui.update_case_file(
		_get_player_known_candidates(),
		investigation_state,
		current_theory
	)


func _on_accusation_confirmed() -> void:
	if accusation_submitted or case_data == null or not current_theory.is_complete():
		return
	accusation_submitted = true
	var weapon_match: bool = current_theory.weapon_id == case_data.correct_weapon_id
	var motive_match: bool = current_theory.motive_id == case_data.correct_motive_id
	var suspect_match: bool = current_theory.suspect_id == case_data.correct_suspect_id
	if debug_accusation_validation:
		print("Selected Weapon ID: %s" % current_theory.weapon_id)
		print("Correct Weapon ID: %s" % case_data.correct_weapon_id)
		print("Selected Motive ID: %s" % current_theory.motive_id)
		print("Correct Motive ID: %s" % case_data.correct_motive_id)
		print("Selected Suspect ID: %s" % current_theory.suspect_id)
		print("Correct Suspect ID: %s" % case_data.correct_suspect_id)
		print("Weapon match: %s" % weapon_match)
		print("Motive match: %s" % motive_match)
		print("Suspect match: %s" % suspect_match)
	var success: bool = weapon_match and motive_match and suspect_match
	case_ui.close_deduction()
	ending_controller.begin_ending(success)
	if success:
		case_solved.emit(current_theory)
	else:
		case_failed.emit(current_theory)


func _on_success_ending_started() -> void:
	if gameplay_audio != null:
		gameplay_audio.play_case_solved()


func _on_intro_finished() -> void:
	if control_hint != null:
		control_hint.show_hint()


func _get_candidate_display_name(candidate_id: StringName) -> String:
	if case_data == null:
		return "Unknown"
	for candidate in case_data.deduction_candidates:
		if candidate != null and candidate.candidate_id == candidate_id:
			return candidate.display_name
	return "Unknown"


func _get_required_clue_count() -> int:
	var count: int = 0
	if case_data == null:
		return count
	for clue_id in case_data.required_clue_ids:
		if investigation_state.has_discovered(clue_id):
			count += 1
	return count


func _get_player_known_candidates() -> Array[DeductionCandidate]:
	var known_candidates: Array[DeductionCandidate] = []
	if case_data == null or investigation_state == null:
		return known_candidates
	for candidate in case_data.deduction_candidates:
		if candidate == null:
			continue
		if candidate.known_at_start:
			known_candidates.append(candidate)
		elif investigation_state.has_discovered_candidate(candidate.candidate_id):
			known_candidates.append(candidate)
	return known_candidates


func print_debug_case_info() -> void:
	if case_data == null or investigation_state == null:
		print("DEBUG CASE INFO: no active case data")
		return
	var revealed_weapons: int = 0
	var revealed_motives: int = 0
	var known_candidates: Array[DeductionCandidate] = _get_player_known_candidates()
	for candidate in known_candidates:
		match candidate.category:
			DeductionCandidate.Category.WEAPON:
				revealed_weapons += 1
			DeductionCandidate.Category.MOTIVE:
				revealed_motives += 1
	var discovered_ids: Array[StringName] = investigation_state.get_discovered_clues()
	print("DEBUG CASE INFO")
	print("Case: %s" % case_data.case_id)
	print(
		"Required clues found: %d / %d"
		% [_get_required_clue_count(), case_data.required_clue_ids.size()]
	)
	print("Weapon candidates revealed: %d" % revealed_weapons)
	print("Motive candidates revealed: %d" % revealed_motives)
	print("Discovered clue IDs:")
	if discovered_ids.is_empty():
		print("- none")
	else:
		for clue_id in discovered_ids:
			print("- %s" % clue_id)
