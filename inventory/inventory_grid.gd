# inventory_grid.gd
@tool
extends Control

@export var inventory_data : InventoryData:
	set(value):
		inventory_data = value
		if Engine.is_editor_hint():
			queue_redraw()

@export var cell_size : Vector2 = Vector2(64, 64):
	set(value):
		cell_size = value
		if Engine.is_editor_hint():
			queue_redraw()

@export var background_color: Color = Color("222222"):
	set(value):
		background_color = value
		if Engine.is_editor_hint():
			queue_redraw()

@export var grid_line_color : Color = Color("444444"):
	set(value):
		grid_line_color = value
		if Engine.is_editor_hint():
			queue_redraw()
@export var grid_line_width : float = 2.0:
	set(value):
		grid_line_width = value
		if Engine.is_editor_hint():
			queue_redraw()

@export var valid_preview_color : Color = Color(1.0, 1.0, 1.0, 0.5)
@export var invalid_preview_color : Color = Color(1.0, 0.0, 0.0, 0.5)

var preview_item = null
var filter_option: OptionButton
var sort_button: Button
var initial_items_added = false
var dropped_item_scene = preload("res://inventory/dropped_item.tscn") # Preload DroppedItem scene

# --- Initialization ---

func _ready():
	# Editor mode setup (grid lines, etc.)
	if Engine.is_editor_hint():
		setup_ui()
		queue_redraw()
		return

	# If no inventory data is assigned, create a new one.
	if inventory_data == null:
		inventory_data = InventoryData.new()

	# Create the preview item (semi-transparent, hidden initially).
	preview_item = Control.new()
	preview_item.modulate = Color(1.0, 1.0, 1.0, 0.5)
	preview_item.hide()
	var texture_rect = TextureRect.new()
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview_item.add_child(texture_rect)
	add_child(preview_item)

	setup_ui() # Sets up filter and sort buttons.
	call_deferred("add_initial_items_and_connect")

func _enter_tree():
	if Engine.is_editor_hint():
		queue_redraw()

func _exit_tree():
	if Engine.is_editor_hint():
		queue_redraw()
		
func add_initial_items_and_connect():
	# --- Example with different stats ---
	if initial_items_added:
		return
	initial_items_added = true
	var sword_resource = preload("res://resources/Sword.tres")
	assert(sword_resource != null, "Failed to load Sword.tres")
	if sword_resource:
		# Duplicate the resource for each instance!
		var sword1_resource = sword_resource.duplicate() as ItemResource
		sword1_resource.width = 1
		sword1_resource.height = 2
		var sword1 = ItemInstance.new(sword1_resource, 1, {"damage": 12, "rarity": "common"})

		var sword2_resource = sword_resource.duplicate() as ItemResource
		sword2_resource.width = 1
		sword2_resource.height = 2
		var sword2 = ItemInstance.new(sword2_resource, 1, {"damage": 18, "rarity": "rare"})

		add_item_at_grid_pos(sword1, Vector2i(1, 1))
		add_item_at_grid_pos(sword2, Vector2i(3, 1))

	# --- Stackable Item Example ---
	var potion_resource = preload("res://resources/Healthpotion.tres")
	assert(potion_resource != null, "Failed to load Potion.tres")
	if potion_resource:
		potion_resource.width = 1
		potion_resource.height = 1
		var potion1 = ItemInstance.new(potion_resource, 5)
		var potion2 = ItemInstance.new(potion_resource, 3)
		add_item_at_grid_pos(potion1, Vector2i(0, 0))  # Add a stack of 5 potions
		add_item_at_grid_pos(potion2, Vector2i(0, 0))  # Add 3 more (should stack)

	# Connect signal AFTER items are added
	inventory_data.inventory_changed.connect(update_inventory_display)

func setup_ui():
	var header_container = HBoxContainer.new()
	header_container.position = Vector2(0, -30)
	add_child(header_container)

	var name_label = Label.new()
	name_label.text = "Name"
	header_container.add_child(name_label)

	var type_label = Label.new()
	type_label.text = "Type"
	header_container.add_child(type_label)

	filter_option = OptionButton.new()
	filter_option.add_item("All")
	filter_option.add_item("Weapons")
	filter_option.add_item("Armor")
	filter_option.add_item("Consumables") # Added consumable
	filter_option.position = Vector2(200, -30)
	add_child(filter_option)
	filter_option.connect("item_selected", _on_filter_selected)

	sort_button = Button.new()
	sort_button.text = "Sort by Name"
	sort_button.position = Vector2(350, -30)
	add_child(sort_button)
	sort_button.connect("pressed", _on_sort_pressed)

# --- Drawing (Grid Lines and Background) ---

func _draw():
	# Draw the background
	draw_rect(Rect2(0, 0, inventory_data.width * cell_size.x, inventory_data.height * cell_size.y), background_color)

	# Draw the grid lines
	for x in range(inventory_data.width + 1):
		var start_point = Vector2(x * cell_size.x, 0)
		var end_point = Vector2(x * cell_size.x, inventory_data.height * cell_size.y)
		draw_line(start_point, end_point, grid_line_color, grid_line_width)

	for y in range(inventory_data.height + 1):
		var start_point = Vector2(0, y * cell_size.y)
		var end_point = Vector2(inventory_data.width * cell_size.x, y * cell_size.y)
		draw_line(start_point, end_point, grid_line_color, grid_line_width)

# --- Item Placement and Display ---
func add_item_at_grid_pos(item_instance: ItemInstance, grid_pos: Vector2i):
	if inventory_data.place_item(item_instance, grid_pos):
		var item_display = preload("res://inventory/inventory_item.tscn").instantiate()
		item_display.item_instance = item_instance
		item_display.inventory_grid = self
		item_display.grid_position = grid_pos
		add_child(item_display)
		item_display.global_position = global_position + (Vector2(grid_pos) * cell_size)
		item_display.update_item()

# Converts a global mouse position to grid coordinates.
func get_grid_position(global_mouse_pos: Vector2) -> Vector2i:
	var local_pos = global_mouse_pos - global_position
	var grid_x = int(local_pos.x / cell_size.x)
	var grid_y = int(local_pos.y / cell_size.y)
	return Vector2i(grid_x, grid_y)

# --- Drag and Drop ---

# Handles dropping an item into the inventory.
func drop_item(item_display : InventoryItem):
	var global_mouse_pos = get_global_mouse_position() # Where the mouse is NOW
		# Check if the mouse is within the inventory grid's bounds.
	if get_global_rect().has_point(global_mouse_pos):
		var target_grid_pos = get_grid_position(global_mouse_pos) # The grid cell we're dropping ONTO
		hide_preview()

		var original_grid_pos = item_display.grid_position		 # Where the item WAS
		var dropped_item_instance = inventory_data.remove_item_at(original_grid_pos) # Remove from original

		if not dropped_item_instance:
			return

		if inventory_data.can_place_item(dropped_item_instance, target_grid_pos):
			# Try to place (stacking is handled within place_item)
			if inventory_data.place_item(dropped_item_instance, target_grid_pos):
				item_display.queue_free() # Remove the visual for where we picked it up from
				update_inventory_display()  # Redraw to show updated inventory.
				return

		# If we couldn't place the item at the target (e.g., invalid position, no space),
		# put the item *back* in its original location in the data.
		inventory_data.place_item(dropped_item_instance, original_grid_pos)
		item_display.grid_position = original_grid_pos
		item_display.global_position = global_position + (Vector2(original_grid_pos) * cell_size)
		item_display.update_item()
	else:
		# Outside the inventory: drop into the world.
		drop_item_into_world(item_display.item_instance, global_mouse_pos)
		item_display.queue_free() # Remove item display

func drop_item_into_world(item_instance: ItemInstance, drop_position: Vector2):
	# 1. Remove from InventoryData
	var top_left = inventory_data.item_positions.get(Vector2i(item_instance.unique_id % inventory_data.width, item_instance.unique_id % inventory_data.height))
	if top_left != null:
		inventory_data.remove_item_at(top_left)

	# 2. Instantiate DroppedItem scene
	var dropped_item = dropped_item_scene.instantiate()

	# 3. Set the item instance
	dropped_item.set_item(item_instance)

	# 4. Set the position (convert to world coordinates if necessary)
	get_tree().get_root().add_child(dropped_item) # Add to the root for now, for simplicity
	dropped_item.global_position = drop_position # Use global position


# Updates the drag preview (the semi-transparent item image that follows the mouse).
func update_drag_preview(item_resource : ItemResource, global_mouse_pos : Vector2):
	var grid_pos = get_grid_position(global_mouse_pos)
	var item_display = get_node_or_null(str(item_resource.get_instance_id())) as InventoryItem

	# --- Calculate Drag Offset ---
	if item_display:
		grid_pos = Vector2i(global_mouse_pos / cell_size) - Vector2i(item_display.drag_offset)

	# --- Calculate Preview Position ---
	preview_item.show()  # ALWAYS show the preview
	preview_item.global_position = global_position + (Vector2(grid_pos) * cell_size)
	var new_size = Vector2(item_resource.width * cell_size.x, item_resource.height * cell_size.y)
	preview_item.get_child(0).size = new_size
	preview_item.get_child(0).texture = item_resource.icon

	# --- Simplified Preview Logic (no temporary removal) ---
	# Create a temporary ItemInstance for the preview check
	var temp_instance = ItemInstance.new(item_resource)
	if inventory_data.can_place_item(temp_instance, grid_pos):
		preview_item.modulate = valid_preview_color
	else:
		preview_item.modulate = invalid_preview_color

func hide_preview():
	preview_item.hide()
	
func clear_inventory():
	for child in get_children():
		if child is InventoryItem:
			child.queue_free()
	inventory_data.clear()

func _on_filter_selected(index: int) -> void:
	var selected_filter = filter_option.get_item_text(index)
	print("Filter selected: ", selected_filter)
	for child in get_children():
		if child is InventoryItem:
			if selected_filter == "All":
				child.show()
			elif selected_filter == "Weapons" and child.item_instance.item_resource.item_class == ItemResource.ItemClass.WEAPON:
				child.show()
			elif selected_filter == "Armor" and child.item_instance.item_resource.item_class == ItemResource.ItemClass.ARMOR:
				child.show()
			elif selected_filter == "Consumables" and child.item_instance.item_resource.item_class == ItemResource.ItemClass.CONSUMABLE:
				child.show()
			else:
				child.hide()

func _on_sort_pressed() -> void:
	print("Sort button pressed")
	inventory_data.sort_items(func(a, b): return a.item_resource.item_name < b.item_resource.item_name)

# --- Redraw the entire inventory ---
func update_inventory_display():
	# Clear existing items (visually)
	for child in get_children():
		if child is InventoryItem:
			child.queue_free()

	# Re-add all items from inventory_data
	for top_left in inventory_data.items:
		var item_instance = inventory_data.items[top_left]
		# add_item_at_grid_pos(item_instance, top_left) # Use original
		var item_display = preload("res://inventory/inventory_item.tscn").instantiate()
		item_display.item_instance = item_instance
		item_display.inventory_grid = self
		item_display.grid_position = top_left
		add_child(item_display)
		item_display.global_position = global_position + (Vector2(top_left) * cell_size)
		item_display.update_item()
