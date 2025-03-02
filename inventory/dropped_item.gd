# dropped_item.gd
extends Node3D # Changed to Node3D

var item_instance : ItemInstance

@onready var label = Label.new()

func set_item(item : ItemInstance):
	item_instance = item
	if item_instance.item_resource.mesh: # Check for mesh
		$MeshInstance3D.mesh = item.item_resource.mesh
	else:
		print("WARNING: Item has no mesh:", item_instance.item_resource.item_name)
	if item_instance.item_resource.stackable: # Check if we need a label
		add_child(label)
		label.text = str(item_instance.quantity)
		
func _ready():
	pass # We do set_item on item drop
