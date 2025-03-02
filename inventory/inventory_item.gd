# inventory_item.gd
extends Control
class_name InventoryItem

# The specific ItemInstance this UI element represents.
var item_instance : ItemInstance :
	set(value):
		item_instance = value
		if texture_rect: # Ensure texture_rect has been created
			update_item()

# --- Node References (using @onready for efficiency) ---
@onready var texture_rect : TextureRect = TextureRect.new() # The TextureRect that displays the item's icon.
@onready var quantity_label : Label = Label.new() # Quantity label for item

# --- Drag and Drop Variables ---
var is_dragging = false # Tracks whether the item is currently being dragged.
var drag_offset = Vector2.ZERO # The offset between the mouse click position and the item's top-left corner (in grid cells).

# --- References ---
var inventory_grid = null # A reference to the InventoryGrid this item belongs to.
var grid_position : Vector2i # The item's position within the inventory grid (in grid coordinates).
var context_menu : Node # Connects to right-click context menu

func _ready():
	
	# --- Setup TextureRect ---
	add_child(texture_rect)
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE

	# --- Setup Quantity Label ---
	quantity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT  # Align right
	quantity_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM    # Align bottom
	quantity_label.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Don't block clicks
	add_child(quantity_label)

		# --- Connect signals ---
	# Context menu is created when needed, so connecting signals here
	# might be premature.  We connect when instantiating the menu.

# Called every frame.  Handles dragging the item.
func _process(delta):
	if is_dragging:
		# Calculate the item's new global position based on the mouse and the drag offset.
		global_position = get_global_mouse_position() - (drag_offset * inventory_grid.cell_size)
		# Update the drag preview in the InventoryGrid.
		inventory_grid.update_drag_preview(item_instance.item_resource, get_global_mouse_position())

# Updates the visual representation of the item (icon, size, quantity).
func update_item():
	if item_instance and inventory_grid:  # Make sure both are valid (Check for nulls)
		texture_rect.texture = item_instance.item_resource.icon
		texture_rect.size = inventory_grid.cell_size * Vector2(item_instance.item_resource.width, item_instance.item_resource.height)
		modulate = Color(1, 1, 1, 1)  # Ensure fully opaque (unless dragging)
		update_quantity_label() # Update quantity label
		quantity_label.position = texture_rect.size - quantity_label.size  # Position the label

# Updates the text and visibility of the quantity label.
func update_quantity_label():
	if quantity_label:  # Make sure the label exists
		if item_instance and item_instance.item_resource.stackable:
			quantity_label.text = str(item_instance.quantity) if item_instance.item_resource.stackable else "" # Empty unless stackable
			quantity_label.visible = item_instance.item_resource.stackable # Show only if stackable

# Handles mouse input events (for drag-and-drop).
func _gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				# Check if the click is within the item's bounds (using texture_rect.size)
				if Rect2(Vector2.ZERO, texture_rect.size).has_point(get_local_mouse_position()):
					print("local click") # Debugging output
					is_dragging = true
					# Calculate the drag offset *in grid coordinates*.
					drag_offset = get_local_mouse_position() / inventory_grid.cell_size
					get_viewport().set_input_as_handled() # Consume the input
					z_index = 100  # Bring the item to the front while dragging
					modulate = Color(1, 1, 1, 0.7) # Make slightly transparent

			elif is_dragging: # If the mouse button is released AND we were dragging
				is_dragging = false
				get_viewport().set_input_as_handled() # Consume the input
				z_index = 0  # Reset Z-index
				inventory_grid.drop_item(self) # Tell the grid to handle the drop
				modulate = Color(1, 1, 1, 1)  # Reset opacity
				
				# --- Right Click Menu Handling ---
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			get_viewport().set_input_as_handled() # Prevent event propagation
			show_context_menu(global_position) # Use global_position directly
			
func show_context_menu(position: Vector2):
	if context_menu == null:
		context_menu = preload("res://inventory/item_context_menu.tscn").instantiate()
		get_tree().get_root().add_child(context_menu) # Add to root of the scene
		context_menu.drop_item.connect(drop_from_inventory) # Connect signals here
		context_menu.destroy_item.connect(destroy)
	context_menu.global_position = position # Use global_position
	context_menu.show()
	z_index = 100
	
func drop_from_inventory():
	inventory_grid.drop_item_into_world(item_instance, get_global_mouse_position())
	queue_free() # Remove the item display from the inventory

func destroy():
	# Remove instance from the data
	var top_left = inventory_grid.inventory_data.item_positions.get(Vector2i(item_instance.unique_id % inventory_grid.inventory_data.width, item_instance.unique_id % inventory_grid.inventory_data.height))
	if top_left:
		inventory_grid.inventory_data.remove_item_at(top_left)
	# Remove visual
	queue_free()
