extends CanvasLayer

@onready var character_sheet: Control = $CharacterSheet


func _input(event):
	if event.is_action_pressed("CharacterSheet"):
		character_sheet.visible =! character_sheet.visible
