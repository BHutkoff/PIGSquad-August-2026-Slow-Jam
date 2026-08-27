extends Area3D


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node3D) -> void:
	if body is FirstPersonController:
		(body as FirstPersonController).set_in_water(true)


func _on_body_exited(body: Node3D) -> void:
	if body is FirstPersonController:
		(body as FirstPersonController).set_in_water(false)
