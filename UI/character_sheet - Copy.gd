extends Control

@onready var points_label: Label = $HBoxContainer/VBoxContainer/HBoxContainer/Control/MainStats/StatPoints/Label
@onready var main_stats: VBoxContainer = $HBoxContainer/VBoxContainer/HBoxContainer/Control/MainStats
@onready var available_points: int = SaveManager.player_data.available_points
@onready var player_stats: Dictionary = SaveManager.player_data.stats

var stat_labels = {}  # Dictionary to store references to all stat labels

@export var stats_add: Dictionary = {
	"strength": 0,
	"agility": 0,
	"endurance": 0,
	"intelligence": 0,
	"wisdom": 0,
	
}

func _ready() -> void:
	get_stat_labels()
	update_all_stats()
	fetch_all_stats()
	update_points_label()
	edit_points()
	
	
func edit_points() -> void:
	
	if available_points == 0:
		pass
	else:
		for button in get_tree().get_nodes_in_group("PlusButtons"):
			button.set_disabled(false)

	for button in get_tree().get_nodes_in_group("PlusButtons"):
		var stat = button.get_parent().get_parent().name.to_lower()
		button.pressed.connect(func(): increase_stat(stat))
	
	for button in get_tree().get_nodes_in_group("MinusButtons"):
		var stat = button.get_parent().get_parent().name.to_lower()
		button.pressed.connect(func(): decrease_stat(stat))
	
	
func increase_stat(stat) -> void:
	
	stats_add[stat] += 1
	available_points -= 1
	
	get_change_label(stat).set_text("+ " + str(stats_add[stat]))
	update_points_label()
	
	main_stats.get_node("%s/StatBox/Min" % stat.capitalize()).set_disabled(false)
	
	if available_points <= 0:
		for button in get_tree().get_nodes_in_group("PlusButtons"):
			button.set_disabled(true)
	

func decrease_stat(stat) -> void:
	
	stats_add[stat] -= 1
	available_points += 1
	
	get_change_label(stat).set_text("+ " + str(stats_add[stat]))
	update_points_label()
	
	for button in get_tree().get_nodes_in_group("PlusButtons"):
		button.set_disabled(false)
	
	if stats_add[stat] <= 0:
		main_stats.get_node("%s/StatBox/Min" % stat.capitalize()).set_disabled(true)
		get_change_label(stat).text = ""

func get_change_label(stat: String) -> Label:
	return main_stats.get_node("%s/StatBox/Stats/Change" % stat.capitalize())
	
func update_points_label() -> void:
	points_label.set_text(str(available_points) + " Points")


func _on_confirm_pressed() -> void:
	# Apply changes to PlayerData and reset change values
	for stat in stat_labels.keys():
		var change_value = int(stat_labels[stat]["change"].text)

		# Update the player's base stat with the applied changes
		player_stats[stat] += change_value

		# Reset the change label to 0
		stat_labels[stat]["change"].text = ""

	# Update available points
	player_stats.available_points = available_points

	# Save updated stats
	SaveManager.save_game()

	# Refresh UI after confirmation
	update_all_stats()
	update_points_label()

## Populate the dictionary with stat label references
func get_stat_labels() -> void:
	stat_labels.clear()  # Ensure it's empty before refilling
	
	for stat in player_stats.keys():
		var value_label_path = "%s/StatBox/Stats/Value" % stat.capitalize()
		var change_label_path = "%s/StatBox/Stats/Change" % stat.capitalize()
		if main_stats.has_node(value_label_path):
			stat_labels[stat] = main_stats.get_node(value_label_path)

		if main_stats.has_node(value_label_path) and main_stats.has_node(change_label_path):
			stat_labels[stat] = {
				"value": main_stats.get_node(value_label_path),
				"change": main_stats.get_node(change_label_path)
			}

func fetch_all_stats() -> void:
	# Loop through all cached labels and update them dynamically
	for stat in stat_labels.keys():
		stat_labels[stat].text = str(player_stats[stat])

func update_all_stats() -> void:
	# Loop through all cached labels and update them dynamically
	for stat in stat_labels.keys():
		var base_value = player_stats[stat]  # Original stat value
		#var change_value = int(stat_labels[stat]["change"].text)  # Change applied

		# Update label text
		stat_labels[stat]["value"].text = "%d" % [base_value]
		
	for button in get_tree().get_nodes_in_group("MinusButtons"):
		button.set_disabled(true)
