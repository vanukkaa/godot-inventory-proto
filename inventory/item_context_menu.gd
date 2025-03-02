# item_context_menu.gd
extends Control

signal drop_item
signal destroy_item

func _ready():
	$VBoxContainer/DropButton.pressed.connect(emit_drop)
	$VBoxContainer/DestroyButton.pressed.connect(emit_destroy)
	hide() # Hide by default

func emit_drop():
	hide() # Hide the menu when an option is selected
	drop_item.emit()

func emit_destroy():
	hide() # Hide the menu when an option is selected
	destroy_item.emit()

func _on_gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		get_viewport().set_input_as_handled()
