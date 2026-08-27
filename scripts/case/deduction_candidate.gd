class_name DeductionCandidate
extends Resource

enum Category {
	WEAPON,
	MOTIVE,
	SUSPECT,
}

@export_category("Identity")
@export var candidate_id: StringName
@export var display_name: String
@export_multiline var description: String
@export var category: Category = Category.WEAPON
@export var known_at_start: bool = false

@export_category("Case File")
@export var associated_evidence_ids: Array[StringName] = []

@export_category("Suspect")
@export var portrait: Texture2D
@export var species: String
@export_multiline var relationship_to_victim: String
@export_multiline var reason_for_visit: String
@export_multiline var known_information: String
@export var connected_weapon_ids: Array[StringName] = []
@export var connected_motive_ids: Array[StringName] = []
