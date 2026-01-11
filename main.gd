extends Node

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_tree().auto_accept_quit = false
	$Menu.load_game()

func timeout_save() -> void:
	$Menu.save_game()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		# do save stuff here
		$Menu.save_game()
		get_tree().quit()
