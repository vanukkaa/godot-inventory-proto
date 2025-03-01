# item_resource.gd
extends Resource
class_name ItemResource

# Enum for item categories.  Add more as needed.
enum ItemClass {
	WEAPON,
	ARMOR,
	CONSUMABLE,
	QUEST,
	MISC
}

@export var item_name : String = "Default Item" :
	set(value):
		item_name = value
	get:
		return item_name
@export var icon : Texture2D:
	set(value):
		icon = value
	get:
		return icon
@export var width : int = 1:
	set(value):
		width = value
	get:
		return width
@export var height : int = 1:
	set(value):
		height = value
	get:
		return height
@export var description: String = "Item Description":
	set(value):
		description = value
	get:
		return description
@export var other_stats : Dictionary = {}:
	set(value):
		other_stats = value
	get:
		return other_stats
@export var stackable : bool = false:
	set(value):
		stackable = value
	get:
		return stackable
@export var max_stack_size : int = 1:
	set(value):
		max_stack_size = value
	get:
		return max_stack_size
# Item category
@export var item_class : ItemClass = ItemClass.MISC:
	set(value):
		item_class = value
	get:
		return item_class

func _to_string():
	return item_name
