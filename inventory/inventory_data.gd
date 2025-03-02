# inventory_data.gd
extends Resource
class_name InventoryData

# --- Signal ---
# Emitted whenever the inventory changes (add, remove, stack).  This is how the
# UI (InventoryGrid) knows to update itself.  The @warning_ignore annotation
# prevents a false positive warning from Godot, since we primarily use
# call_deferred to emit the signal.
@warning_ignore("unused_signal")
signal inventory_changed

# --- Inventory Dimensions ---
@export var width : int = 10  # Inventory width in cells
@export var height : int = 6   # Inventory height in cells

# --- Data Storage ---
# Stores the actual inventory items.
# Key: Vector2i (top-left cell position of the item)
# Value: ItemInstance (the actual item object)
@export var items : Dictionary = {}

# Stores a mapping to quickly find which item occupies a given grid cell.  This
# is used for collision detection (overlap checks) and for finding the top-left
# position of an item given *any* cell it occupies.
# Key: Vector2i (any grid cell occupied by an item)
# Value: Vector2i (the top-left cell of the item that occupies the key cell)
@export var item_positions: Dictionary = {}

# --- Core Inventory Logic ---

# Checks if an item *can* be placed at the given top-left position.
func can_place_item(item_instance: ItemInstance, top_left: Vector2i) -> bool:
	var item_resource = item_instance.item_resource

	# 1. Bounds Check: Is the position within the inventory grid?
	if top_left.x < 0 or top_left.y < 0 or top_left.x + item_resource.width > width or top_left.y + item_resource.height > height:
		return false

	# 2. Overlap Check (including stackability check):
	for x in range(top_left.x, top_left.x + item_resource.width):
		for y in range(top_left.y, top_left.y + item_resource.height):
			var grid_pos = Vector2i(x, y)
			if grid_pos in item_positions: # Is this cell occupied?
				var existing_item_top_left = item_positions[grid_pos]
				var existing_item_instance = items.get(existing_item_top_left)

				if existing_item_instance:  # Make sure we actually got an item (should always be true)
					if (item_resource.stackable and existing_item_instance.item_resource == item_resource and
						existing_item_instance.quantity + item_instance.quantity <= item_resource.max_stack_size):
						continue # We *can* stack here (same item type, room in stack). Check next cell.
					else:
						return false  # Overlap with a non-stackable item, or a different item type.

	# If we get here, all cells are either empty, or contain a stackable item of the same type.
	return true


# Attempts to *place* an item at the given top-left position.  Handles stacking.
func place_item(item_instance: ItemInstance, top_left: Vector2i) -> bool:
	var item_resource = item_instance.item_resource

	# If we can't place the item, return false.
	if not can_place_item(item_instance, top_left):
		return false

	# Check for existing stacks if the item is stackable.
	if item_resource.stackable:
		for x in range(top_left.x, top_left.x + item_resource.width):
			for y in range(top_left.y, top_left.y + item_resource.height):
				var grid_pos = Vector2i(x,y)
				if grid_pos in item_positions:
					var existing_item_top_left = item_positions[grid_pos]
					if existing_item_top_left in items:
						var existing_item_instance = items[existing_item_top_left]
						# If it's the same item type, stack it.
						if existing_item_instance.item_resource == item_resource:
							existing_item_instance.quantity += item_instance.quantity
							call_deferred("emit_signal", "inventory_changed")  # Notify UI
							return true # We stacked the item, so we're done.

	# If we get here, either:
	# 1. The item is not stackable.
	# 2. The item is stackable, but there's no existing stack of the same type.
	# In either case, we place the item as a new entry.

	items[top_left] = item_instance  # Add to the main items dictionary
	# Update item_positions for *all* cells the item occupies.
	for x in range(top_left.x, top_left.x + item_resource.width):
		for y in range(top_left.y, top_left.y + item_resource.height):
			item_positions[Vector2i(x, y)] = top_left
	call_deferred("emit_signal", "inventory_changed")  # Notify UI
	return true


# Removes the item at the given top-left position and returns the ItemInstance.
func remove_item_at(top_left: Vector2i) -> ItemInstance:
	var item_instance = items.get(top_left)
	if item_instance:
		items.erase(top_left)
		# Remove all position entries for this item.
		var positions_to_remove = []
		for pos in item_positions:
			if item_positions[pos] == top_left:
				positions_to_remove.append(pos)
		for pos in positions_to_remove:
			item_positions.erase(pos)
		call_deferred("emit_signal", "inventory_changed") # Notify UI
		return item_instance
	return null

# Gets the ItemInstance at a given *grid position* (not necessarily the top-left).
func get_item_at_grid_position(grid_pos: Vector2i) -> ItemInstance:
	var item_top_left = item_positions.get(grid_pos)
	if item_top_left and item_top_left in items:
		return items[item_top_left]
	return null

# Returns a simple array of all ItemInstances in the inventory (for sorting, etc.).
func get_items() -> Array:
	var item_list = []
	for top_left in items:
		item_list.append(items[top_left])
	return item_list

# Sorts the inventory items based on a custom comparison function.
func sort_items(comparison_function):
	var item_list = get_items()
	item_list.sort_custom(comparison_function)
	clear()  # Clear the inventory (this also emits inventory_changed)
	# Re-add items in the sorted order.
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

# Clears the entire inventory.
func clear():
	items.clear()
	item_positions.clear()
	call_deferred("emit_signal", "inventory_changed")  # Still deferred for clearing
