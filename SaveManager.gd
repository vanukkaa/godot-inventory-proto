extends Node

var player_data: PlayerData


func _ready():
	load_game()

func save_game():
	var save_dict = player_data.to_dict()
	var file = FileAccess.open("user://player_data.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(save_dict))
	file.close()

func load_game():
	var file = FileAccess.open("user://player_data.json", FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		var loaded_data = JSON.parse_string(json_string)
		player_data = PlayerData.new()
		player_data.stats = loaded_data.get("stats", player_data.stats)
		player_data.stat_points = loaded_data.get("stat_points", player_data.stat_points)
	else:
		player_data = PlayerData.new()  # Creates default if no save exists
