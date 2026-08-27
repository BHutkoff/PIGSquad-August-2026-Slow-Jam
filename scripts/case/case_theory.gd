class_name CaseTheory
extends RefCounted

var weapon_id: StringName
var motive_id: StringName
var suspect_id: StringName


func is_complete() -> bool:
	return not weapon_id.is_empty() and not motive_id.is_empty() and not suspect_id.is_empty()
