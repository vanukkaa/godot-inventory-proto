# item_resource.gd
extends Resource
class_name ItemResource

# Enum for item categories. Add more categories as needed for your game.
enum ItemClass {
	WEAPON,
	ARMOR,
	CONSUMABLE,
	QUEST,
	MISC
}

# --- Basic Item Properties ---
@export_group("Basic Properties")
@export var item_name : String = "Default Item" : # The name of the item (e.g., "Sword", "Potion")
	set(value):
		item_name = value
	get:
		return item_name
@export var icon : Texture2D: # The item's icon (Texture2D resource).
	set(value):
		icon = value
	get:
		return icon
@export var description: String = "Item Description": # A description of the item.
	set(value):
		description = value
	get:
		return description
@export var item_class : ItemClass = ItemClass.MISC: #The category of the item.
	set(value):
		item_class = value
	get:
		return item_class
		
@export var mesh : Mesh:
	set(value):
		mesh = value
	get:
		return mesh

# --- Grid Properties ---
@export_group("Grid Properties")
@export var width : int = 1: # Width of the item in grid cells.
	set(value):
		width = value
	get:
		return width
@export var height : int = 1: # Height of the item in grid cells.
	set(value):
		height = value
	get:
		return height

# --- Stacking Properties ---
@export_group("Stacking")
@export var stackable : bool = false: # Whether this item can be stacked.
	set(value):
		stackable = value
	get:
		return stackable
@export var max_stack_size : int = 1: # Maximum number of items in a stack (if stackable).
	set(value):
		max_stack_size = value
	get:
		return max_stack_size
		
# --- Custom Stats ---
@export_group("Custom Stats")
@export var other_stats : Dictionary = {}: # A dictionary for custom item stats (e.g., damage, armor).
	set(value):
		other_stats = value
	get:
		return other_stats
		
# --- Built in methods ---
# String representation for debugging.
func _to_string():
	return item_name
