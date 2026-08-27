class_name CaseUI
extends CanvasLayer

signal theory_selected(category: int, candidate_id: StringName)
signal accusation_confirmed
signal return_requested

@onready var objective_title: Label = $ObjectivePanel/Margin/VBox/CaseTitle
@onready var objective_text: Label = $ObjectivePanel/Margin/VBox/Objective
@onready var deduction_overlay: Control = $DeductionOverlay
@onready var review_panel: PanelContainer = $DeductionOverlay/Center/Panel
@onready var deduction_title: Label = $DeductionOverlay/Center/Panel/Margin/VBox/Header/Title
@onready var case_file_body: VBoxContainer = $DeductionOverlay/Center/Panel/Margin/VBox/CaseFileBody
@onready var weapon_tab: Button = $DeductionOverlay/Center/Panel/Margin/VBox/CaseFileBody/TabsCenter/Tabs/Weapon
@onready var motive_tab: Button = $DeductionOverlay/Center/Panel/Margin/VBox/CaseFileBody/TabsCenter/Tabs/Motive
@onready var suspect_tab: Button = $DeductionOverlay/Center/Panel/Margin/VBox/CaseFileBody/TabsCenter/Tabs/Suspect
@onready var candidate_detail_layout: HBoxContainer = $DeductionOverlay/Center/Panel/Margin/VBox/CaseFileBody/ContentPanel/Margin/Content
@onready var candidate_scroll: ScrollContainer = $DeductionOverlay/Center/Panel/Margin/VBox/CaseFileBody/ContentPanel/Margin/Content/CandidateScroll
@onready var candidate_list: VBoxContainer = $DeductionOverlay/Center/Panel/Margin/VBox/CaseFileBody/ContentPanel/Margin/Content/CandidateScroll/CandidateList
@onready var full_width_empty_state: CenterContainer = $DeductionOverlay/Center/Panel/Margin/VBox/CaseFileBody/ContentPanel/Margin/FullWidthEmptyState
@onready var empty_message: Label = $DeductionOverlay/Center/Panel/Margin/VBox/CaseFileBody/ContentPanel/Margin/FullWidthEmptyState/EmptyMessage
@onready var dossier_scroll: ScrollContainer = $DeductionOverlay/Center/Panel/Margin/VBox/CaseFileBody/ContentPanel/Margin/Content/Detail/DossierScroll
@onready var candidate_name: Label = $DeductionOverlay/Center/Panel/Margin/VBox/CaseFileBody/ContentPanel/Margin/Content/Detail/CandidateHeader/CandidateName
@onready var theory_button: Button = $DeductionOverlay/Center/Panel/Margin/VBox/CaseFileBody/ContentPanel/Margin/Content/Detail/CandidateHeader/TheoryButton
@onready var portrait_frame: PanelContainer = $DeductionOverlay/Center/Panel/Margin/VBox/CaseFileBody/ContentPanel/Margin/Content/Detail/DossierScroll/Dossier/Upper/PortraitFrame
@onready var portrait: TextureRect = $DeductionOverlay/Center/Panel/Margin/VBox/CaseFileBody/ContentPanel/Margin/Content/Detail/DossierScroll/Dossier/Upper/PortraitFrame/Portrait
@onready var portrait_placeholder: Label = $DeductionOverlay/Center/Panel/Margin/VBox/CaseFileBody/ContentPanel/Margin/Content/Detail/DossierScroll/Dossier/Upper/PortraitFrame/PortraitPlaceholder
@onready var candidate_type: Label = $DeductionOverlay/Center/Panel/Margin/VBox/CaseFileBody/ContentPanel/Margin/Content/Detail/DossierScroll/Dossier/Upper/Information/CandidateType
@onready var description: Label = $DeductionOverlay/Center/Panel/Margin/VBox/CaseFileBody/ContentPanel/Margin/Content/Detail/DossierScroll/Dossier/Upper/Information/Description
@onready var species_heading: Label = $DeductionOverlay/Center/Panel/Margin/VBox/CaseFileBody/ContentPanel/Margin/Content/Detail/DossierScroll/Dossier/Upper/Information/SpeciesHeading
@onready var species: Label = $DeductionOverlay/Center/Panel/Margin/VBox/CaseFileBody/ContentPanel/Margin/Content/Detail/DossierScroll/Dossier/Upper/Information/Species
@onready var relationship_heading: Label = $DeductionOverlay/Center/Panel/Margin/VBox/CaseFileBody/ContentPanel/Margin/Content/Detail/DossierScroll/Dossier/Upper/Information/RelationshipHeading
@onready var relationship: Label = $DeductionOverlay/Center/Panel/Margin/VBox/CaseFileBody/ContentPanel/Margin/Content/Detail/DossierScroll/Dossier/Upper/Information/Relationship
@onready var reason_heading: Label = $DeductionOverlay/Center/Panel/Margin/VBox/CaseFileBody/ContentPanel/Margin/Content/Detail/DossierScroll/Dossier/Upper/Information/ReasonHeading
@onready var reason: Label = $DeductionOverlay/Center/Panel/Margin/VBox/CaseFileBody/ContentPanel/Margin/Content/Detail/DossierScroll/Dossier/Upper/Information/Reason
@onready var evidence_heading: Label = $DeductionOverlay/Center/Panel/Margin/VBox/CaseFileBody/ContentPanel/Margin/Content/Detail/DossierScroll/Dossier/EvidenceHeading
@onready var evidence_text: RichTextLabel = $DeductionOverlay/Center/Panel/Margin/VBox/CaseFileBody/ContentPanel/Margin/Content/Detail/DossierScroll/Dossier/EvidenceText
@onready var weapon_selection: Label = $DeductionOverlay/Center/Panel/Margin/VBox/CaseFileBody/TheoryPanel/Margin/VBox/Columns/Weapon/Selection
@onready var motive_selection: Label = $DeductionOverlay/Center/Panel/Margin/VBox/CaseFileBody/TheoryPanel/Margin/VBox/Columns/Motive/Selection
@onready var suspect_selection: Label = $DeductionOverlay/Center/Panel/Margin/VBox/CaseFileBody/TheoryPanel/Margin/VBox/Columns/Suspect/Selection
@onready var incomplete_message: Label = $DeductionOverlay/Center/Panel/Margin/VBox/CaseFileBody/IncompleteMessage
@onready var submit_button: Button = $DeductionOverlay/Center/Panel/Margin/VBox/CaseFileBody/SubmitCenter/SubmitAccusation
@onready var confirmation: VBoxContainer = $DeductionOverlay/Center/Panel/Margin/VBox/Confirmation
@onready var confirmation_theory: RichTextLabel = $DeductionOverlay/Center/Panel/Margin/VBox/Confirmation/Theory
@onready var confirm_button: Button = $DeductionOverlay/Center/Panel/Margin/VBox/Confirmation/Buttons/Submit
@onready var return_to_file_button: Button = $DeductionOverlay/Center/Panel/Margin/VBox/Confirmation/Buttons/ReturnToFile
@onready var return_button: Button = $DeductionOverlay/Center/Panel/Margin/VBox/CaseFileBody/ReturnCenter/ReturnButton

var _active_category: int = DeductionCandidate.Category.WEAPON
var _selected_candidate_id: StringName
var _candidates: Array[DeductionCandidate] = []
var _investigation_state: InvestigationState
var _theory: CaseTheory
var _candidate_button_group: ButtonGroup = ButtonGroup.new()


func _ready() -> void:
	deduction_overlay.visible = false
	get_viewport().size_changed.connect(_update_review_panel_size)
	_update_review_panel_size()
	weapon_tab.pressed.connect(_select_category.bind(DeductionCandidate.Category.WEAPON))
	motive_tab.pressed.connect(_select_category.bind(DeductionCandidate.Category.MOTIVE))
	suspect_tab.pressed.connect(_select_category.bind(DeductionCandidate.Category.SUSPECT))
	theory_button.pressed.connect(_on_theory_button_pressed)
	submit_button.pressed.connect(_show_confirmation)
	confirm_button.pressed.connect(_confirm_accusation)
	return_to_file_button.pressed.connect(_return_to_case_file)
	return_button.pressed.connect(_on_return_pressed)
	_set_confirmation_visible(false)


func configure(
		case_title: String,
		hud_case_title: String,
		_question: String,
		objective: String
	) -> void:
	var overlay_title: String = hud_case_title if not hud_case_title.is_empty() else case_title
	objective_title.text = "CASE: %s" % overlay_title
	objective_text.text = objective
	deduction_title.text = case_title if case_title.begins_with("CASE: ") else case_title.to_upper()


func update_case_file(
		candidates: Array[DeductionCandidate],
		investigation_state: InvestigationState,
		theory: CaseTheory
	) -> void:
	_candidates = candidates
	_investigation_state = investigation_state
	_theory = theory
	_rebuild_candidate_list()
	_update_theory_summary()


func open_case_file() -> void:
	deduction_overlay.visible = true
	_set_confirmation_visible(false)
	_select_category(_active_category)


func close_deduction() -> void:
	_set_confirmation_visible(false)
	deduction_overlay.visible = false


func is_deduction_open() -> bool:
	return deduction_overlay.visible


func _select_category(category: int) -> void:
	_active_category = category
	_selected_candidate_id = &""
	weapon_tab.button_pressed = category == DeductionCandidate.Category.WEAPON
	motive_tab.button_pressed = category == DeductionCandidate.Category.MOTIVE
	suspect_tab.button_pressed = category == DeductionCandidate.Category.SUSPECT
	_rebuild_candidate_list()


func _rebuild_candidate_list() -> void:
	for child in candidate_list.get_children():
		candidate_list.remove_child(child)
		child.queue_free()
	var visible_candidates: Array[DeductionCandidate] = _get_visible_candidates()
	if visible_candidates.is_empty():
		_show_empty_category()
		return
	candidate_detail_layout.visible = true
	full_width_empty_state.visible = false
	candidate_scroll.visible = true
	if _selected_candidate_id.is_empty() or _find_visible_candidate(_selected_candidate_id) == null:
		_selected_candidate_id = visible_candidates[0].candidate_id
	for candidate in visible_candidates:
		var button: Button = Button.new()
		button.custom_minimum_size = Vector2(0.0, 50.0)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.toggle_mode = true
		button.button_group = _candidate_button_group
		button.button_pressed = candidate.candidate_id == _selected_candidate_id
		button.text = candidate.display_name
		if candidate.candidate_id == _get_current_theory(_active_category):
			button.text += "  —  CURRENT THEORY"
		button.pressed.connect(_show_candidate.bind(candidate.candidate_id))
		candidate_list.add_child(button)
	_show_candidate(_selected_candidate_id)


func _get_visible_candidates() -> Array[DeductionCandidate]:
	var visible_candidates: Array[DeductionCandidate] = []
	for candidate in _candidates:
		if candidate == null or candidate.category != _active_category:
			continue
		visible_candidates.append(candidate)
	return visible_candidates


func _show_empty_category() -> void:
	match _active_category:
		DeductionCandidate.Category.WEAPON:
			empty_message.text = "No possible murder weapons identified yet."
		DeductionCandidate.Category.MOTIVE:
			empty_message.text = "No possible motives identified yet."
		_:
			empty_message.text = "No suspects are currently known."
	candidate_detail_layout.visible = false
	full_width_empty_state.visible = true


func _show_candidate(candidate_id: StringName) -> void:
	var candidate: DeductionCandidate = _find_visible_candidate(candidate_id)
	if candidate == null:
		return
	_selected_candidate_id = candidate_id
	candidate_detail_layout.visible = true
	full_width_empty_state.visible = false
	dossier_scroll.visible = true
	dossier_scroll.scroll_vertical = 0
	candidate_name.text = candidate.display_name
	var is_suspect: bool = candidate.category == DeductionCandidate.Category.SUSPECT
	portrait_frame.visible = is_suspect
	portrait.visible = is_suspect and candidate.portrait != null
	portrait.texture = candidate.portrait
	portrait_placeholder.visible = is_suspect and candidate.portrait == null
	species_heading.visible = is_suspect
	species.visible = is_suspect
	relationship_heading.visible = is_suspect
	relationship.visible = is_suspect
	reason_heading.visible = is_suspect
	reason.visible = is_suspect
	description.visible = not is_suspect
	if is_suspect:
		candidate_type.text = "SUSPECT CASE FILE"
		species.text = candidate.species
		relationship.text = candidate.relationship_to_victim
		reason.text = (
			candidate.reason_for_visit
			if not candidate.reason_for_visit.is_empty()
			else candidate.description
		)
		evidence_heading.text = "OVERVIEW"
		evidence_text.text = _build_suspect_overview(candidate)
	elif candidate.category == DeductionCandidate.Category.WEAPON:
		candidate_type.text = "POSSIBLE MURDER WEAPON"
		description.text = candidate.description
		evidence_heading.text = "EVIDENCE CONNECTED TO THIS THEORY"
		evidence_text.text = _build_discovered_evidence(candidate)
	else:
		candidate_type.text = "POSSIBLE MOTIVE"
		description.text = candidate.description
		evidence_heading.text = "EVIDENCE CONNECTED TO THIS THEORY"
		evidence_text.text = _build_discovered_evidence(candidate)
	theory_button.visible = true
	var is_current: bool = candidate_id == _get_current_theory(candidate.category)
	if candidate.category == DeductionCandidate.Category.SUSPECT:
		theory_button.text = "CURRENT SUSPECT" if is_current else "MARK AS CURRENT SUSPECT"
	elif candidate.category == DeductionCandidate.Category.WEAPON:
		theory_button.text = "CURRENT WEAPON" if is_current else "MARK AS CURRENT WEAPON"
	else:
		theory_button.text = "CURRENT MOTIVE" if is_current else "MARK AS CURRENT MOTIVE"


func _build_discovered_evidence(candidate: DeductionCandidate) -> String:
	var evidence_lines: PackedStringArray = []
	if _investigation_state != null:
		for clue_id in candidate.associated_evidence_ids:
			if not _investigation_state.has_discovered(clue_id):
				continue
			var evidence_name: String = _investigation_state.get_clue_display_name(clue_id)
			var observation: String = _investigation_state.get_clue_observation(clue_id)
			evidence_lines.append("• [b]%s[/b]\n  %s" % [evidence_name, observation])
	if evidence_lines.is_empty():
		return "No connected evidence discovered yet."
	return "\n\n".join(evidence_lines)


func _build_suspect_overview(candidate: DeductionCandidate) -> String:
	var overview_text: String = (
		candidate.known_information
		if not candidate.known_information.is_empty()
		else candidate.description
	)
	var discovered_evidence: String = _build_discovered_evidence(candidate)
	if discovered_evidence == "No connected evidence discovered yet.":
		return overview_text
	return "%s\n\n[b]DISCOVERED EVIDENCE[/b]\n%s" % [overview_text, discovered_evidence]


func _find_visible_candidate(candidate_id: StringName) -> DeductionCandidate:
	var visible_candidates: Array[DeductionCandidate] = _get_visible_candidates()
	for candidate in visible_candidates:
		if candidate.candidate_id == candidate_id:
			return candidate
	return null


func _get_current_theory(category: int) -> StringName:
	if _theory == null:
		return &""
	match category:
		DeductionCandidate.Category.WEAPON:
			return _theory.weapon_id
		DeductionCandidate.Category.MOTIVE:
			return _theory.motive_id
		DeductionCandidate.Category.SUSPECT:
			return _theory.suspect_id
		_:
			return &""


func _on_theory_button_pressed() -> void:
	if _selected_candidate_id.is_empty():
		return
	theory_selected.emit(_active_category, _selected_candidate_id)


func _update_theory_summary() -> void:
	if _theory == null:
		return
	var weapon_name: String = _get_candidate_name(_theory.weapon_id)
	var motive_name: String = _get_candidate_name(_theory.motive_id)
	var suspect_name: String = _get_candidate_name(_theory.suspect_id)
	weapon_selection.text = weapon_name
	motive_selection.text = motive_name
	suspect_selection.text = suspect_name
	var complete: bool = _theory.is_complete()
	submit_button.disabled = not complete
	incomplete_message.visible = not complete


func _get_candidate_name(candidate_id: StringName) -> String:
	if candidate_id.is_empty():
		return "Not selected"
	for candidate in _candidates:
		if candidate != null and candidate.candidate_id == candidate_id:
			return candidate.display_name
	return "Not selected"


func _show_confirmation() -> void:
	if _theory == null or not _theory.is_complete():
		return
	confirmation_theory.text = (
		"[b]Submit this accusation?[/b]\n\nWeapon: %s\nMotive: %s\nSuspect: %s"
		% [
			_get_candidate_name(_theory.weapon_id),
			_get_candidate_name(_theory.motive_id),
			_get_candidate_name(_theory.suspect_id),
		]
	)
	_set_confirmation_visible(true)
	return_to_file_button.grab_focus()


func _return_to_case_file() -> void:
	_set_confirmation_visible(false)
	submit_button.grab_focus()


func _confirm_accusation() -> void:
	if _theory == null or not _theory.is_complete():
		return
	accusation_confirmed.emit()


func _set_confirmation_visible(is_visible: bool) -> void:
	confirmation.visible = is_visible
	case_file_body.visible = not is_visible
	deduction_title.visible = not is_visible
	if not is_visible:
		incomplete_message.visible = _theory == null or not _theory.is_complete()


func _on_return_pressed() -> void:
	return_requested.emit()


func _update_review_panel_size() -> void:
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var panel_width: float = minf(1200.0, viewport_size.x * 0.94)
	var panel_height: float = minf(680.0, viewport_size.y * 0.94)
	review_panel.custom_minimum_size = Vector2(panel_width, panel_height)
	candidate_scroll.custom_minimum_size.x = minf(300.0, panel_width * 0.27)
	empty_message.custom_minimum_size.x = minf(640.0, panel_width * 0.65)
