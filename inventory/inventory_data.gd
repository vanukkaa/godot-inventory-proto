# inventory_data.gd
extends Resource
class_name InventoryData

@warning_ignore("unused_signal")
signal inventory_changed

@export var width : int = 10
@export var height : int = 6
@export var items : Dictionary = {} # Key: Vector2i, Value: ItemInstance
@export var item_positions: Dictionary = {}

func can_place_item(item_instance: ItemInstance, top_left: Vector2i) -> bool:
	var item_resource = item_instance.item_resource

	# Bounds check
	if top_left.x < 0 or top_left.y < 0 or top_left.x + item_resource.width > width or top_left.y + item_resource.height > height:
		return false

	# Overlap check (including stackability check)
	for x in range(top_left.x, top_left.x + item_resource.width):
		for y in range(top_left.y, top_left.y + item_resource.height):
			var grid_pos = Vector2i(x, y)
			if grid_pos in item_positions:
				var existing_item_top_left = item_positions[grid_pos]
				var existing_item_instance = items.get(existing_item_top_left)

				if existing_item_instance:  # Make sure we actually got an item
					if (item_resource.stackable and existing_item_instance.item_resource == item_resource and
						existing_item_instance.quantity + item_instance.quantity <= item_resource.max_stack_size):
						continue # We *can* stack here, so this cell is OK.  Continue checking other cells.
					else:
						return false  # Overlap with a non-stackable item or different item type

	return true  # No overlaps found (or stackable and within limits)

func place_item(item_instance: ItemInstance, top_left: Vector2i) -> bool:
	var item_resource = item_instance.item_resource
	if not can_place_item(item_instance, top_left):
		return false

	# Check for existing stacks if the item is stackable
	if item_resource.stackable:
		for x in range(top_left.x, top_left.x + item_resource.width):
			for y in range(top_left.y, top_left.y + item_resource.height):
				var grid_pos = Vector2i(x, y)
				if grid_pos in item_positions:
					var existing_item_top_left = item_positions[grid_pos]
					if existing_item_top_left in items:
						var existing_item_instance = items[existing_item_top_left]
						# Check if same base item
						if existing_item_instance.item_resource == item_resource:
							existing_item_instance.quantity += item_instance.quantity  # Stack onto existing
							call_deferred("emit_signal", "inventory_changed")
							return true

	# If not stackable or no existing stack, create a new entry
	items[top_left] = item_instance
	for x in range(top_left.x, top_left.x + item_resource.width):
		for y in range(top_left.y, top_left.y + item_resource.height):
			item_positions[Vector2i(x,y)] = top_left
	call_deferred("emit_signal", "inventory_changed")
	return true

func remove_item_at(top_left: Vector2i) -> ItemInstance:
	var item_instance = items.get(top_left)
	if item_instance:
		items.erase(top_left)
		var positions_to_remove = []
		for pos in item_positions:
			if item_positions[pos] == top_left:
				positions_to_remove.append(pos)
		for pos in positions_to_remove:
			item_positions.erase(pos)
		call_deferred("emit_signal", "inventory_changed")
		return item_instance
	return null

func get_item_at_grid_position(grid_pos: Vector2i) -> ItemInstance:
	var item_top_left = item_positions.get(grid_pos)
	if item_top_left and item_top_left in items:
		return items[item_top_left]
	return null
	
func get_items() -> Array:
	var item_list = []
	for top_left in items:
		item_list.append(items[top_left])
	return item_list

func sort_items(comparison_function):
	var item_list = get_items()
	item_list.sort_custom(comparison_function)
	clear()
	for item_instance in item_list:
		var placed = false
		for y in range(height):
			for x in range(width):
				var pos = Vector2i(x, y)
				if can_place_item(item_instance, pos):
					place_item(item_instance, pos)
					placed = true
					break
			if placed:
				break

func clear():
	items.clear()
	item_positions.clear()
	call_deferred("emit_signal", "inventory_changed")
