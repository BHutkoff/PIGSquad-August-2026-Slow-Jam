extends Node3D

@export var debug_visibility_enabled: bool = true

@onready var debug_light: OmniLight3D = $DebugLight
@onready var status_label: Label = $HUD/DebugStatus


func _ready() -> void:
	_apply_debug_visibility()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_debug_visibility"):
		debug_visibility_enabled = not debug_visibility_enabled
		_apply_debug_visibility()
		get_viewport().set_input_as_handled()


func _apply_debug_visibility() -> void:
	debug_light.visible = debug_visibility_enabled
	status_label.text = "DEBUG VISIBILITY: %s  [F1 to toggle]" % (
		"ON" if debug_visibility_enabled else "OFF (echolocation state)"
	)
	if debug_visibility_enabled:
		var case_manager: CaseManager = get_node_or_null("CaseManager") as CaseManager
		if case_manager != null:
			case_manager.print_debug_case_info()
