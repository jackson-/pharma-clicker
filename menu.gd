extends Control

	
func add_to_score() -> void:
	$MenuContainer/Score.score += 1
	$MenuContainer/Score.text = str($MenuContainer/Score.score)
	var save_file = FileAccess.open("user://savegame.save", FileAccess.WRITE)
	save_file.store_var(self.save_dict().duplicate())
	save_file.close()
	
func save_dict():
	var save_data_dict = {
		"score": $MenuContainer/Score.score,
	}
	return save_data_dict


func save_game() -> void:
	var save_file = FileAccess.open("user://savegame.save", FileAccess.WRITE)
	save_file.store_var(self.save_dict().duplicate())
	save_file.close()
		
		
func load_game() -> void:
	if not FileAccess.file_exists("user://savegame.save"):
		return # Error! We don't have a save to load.
	
	var save_file = FileAccess.open("user://savegame.save", FileAccess.READ)
	var data = save_file.get_var()
	save_file.close()
	
	var save_data = data.duplicate()
	$MenuContainer/Score.score = save_data.score
	$MenuContainer/Score.text = str(save_data.score)
	
func quit_game() -> void:
	get_tree().quit()
	
	
	
