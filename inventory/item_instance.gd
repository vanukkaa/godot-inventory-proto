# item_instance.gd
extends RefCounted
class_name ItemInstance

# Reference to the base ItemResource (the template)
var item_resource : ItemResource
# Unique ID for this specific item instance
var unique_id : int
# Current quantity (for stackable items)
var quantity : int
# Dictionary for instance-specific stats (damage, rarity, etc.)
var instance_stats : Dictionary

# Constructor. Takes the ItemResource, initial quantity, and optional custom stats.
func _init(base_item: ItemResource, initial_quantity: int = 1, custom_stats: Dictionary = {}):
	item_resource = base_item
	unique_id = get_instance_id() # Get a unique ID from Godot
	quantity = initial_quantity
	instance_stats = custom_stats.duplicate()  # IMPORTANT: Duplicate the stats!

# String representation for debugging (very useful!)
func _to_string() -> String:
	var item_instance_string = "ItemInstance: %s (ID: %d, Quantity: %d" % [item_resource.item_name, unique_id, quantity]
	if !instance_stats.is_empty():
		item_instance_string += ", Stats: " + str(instance_stats)
	item_instance_string += ")"
	return item_instance_string
