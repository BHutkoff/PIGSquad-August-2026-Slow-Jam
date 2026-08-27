class_name CaseData
extends Resource

@export_category("Case")
@export var case_id: StringName
@export var case_title: String
@export var hud_case_title: String
@export_multiline var case_objective: String
@export_multiline var case_question: String
@export var required_clue_ids: Array[StringName] = []

@export_category("Case File")
@export var deduction_candidates: Array[DeductionCandidate] = []

@export_category("Solution")
@export var correct_weapon_id: StringName
@export var correct_motive_id: StringName
@export var correct_suspect_id: StringName
