extends Control

const MAIN_MENU_SCENE: String = "res://scenes/ui/main_menu.tscn"


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	$Center/Panel/Margin/VBox/MainMenu.pressed.connect(_return_to_main_menu)
	$Center/Panel/Margin/VBox/MainMenu.grab_focus()


func _return_to_main_menu() -> void:
	var change_error: Error = get_tree().change_scene_to_file(MAIN_MENU_SCENE)
	if change_error != OK:
		push_error("Unable to return to the Main Menu (error %d)." % change_error)

