# inventory_item.gd
extends Control
class_name InventoryItem

var item_instance : ItemInstance :
	set(value):
		item_instance = value
		if texture_rect:
			update_item()

var texture_rect : TextureRect
var is_dragging = false
var drag_offset = Vector2.ZERO  # Offset in GRID coordinates
var inventory_grid = null
var grid_position : Vector2i
var quantity_label : Label

func _ready():
	texture_rect = TextureRect.new()
	add_child(texture_rect)
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE

	quantity_label = Label.new()
	quantity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	quantity_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	quantity_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(quantity_label)
	update_quantity_label()

func _process(delta):
	if is_dragging:
		global_position = get_global_mouse_position() - (drag_offset * inventory_grid.cell_size)
		inventory_grid.update_drag_preview(item_instance.item_resource, get_global_mouse_position())

func update_item():
	if item_instance and inventory_grid:
		texture_rect.texture = item_instance.item_resource.icon
		texture_rect.size = inventory_grid.cell_size * Vector2(item_instance.item_resource.width, item_instance.item_resource.height)
		modulate = Color(1, 1, 1, 1)
		update_quantity_label()
		quantity_label.position = texture_rect.size - quantity_label.size

func update_quantity_label():
	if quantity_label:
		if item_instance and item_instance.item_resource.stackable:
			quantity_label.text = str(item_instance.quantity)
			quantity_label.show()
		else:
			quantity_label.hide()

func _gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				# Use texture_rect.size for the hit test.  This is reliable.
				if Rect2(Vector2.ZERO, texture_rect.size).has_point(get_local_mouse_position()):
					print("local click")
					is_dragging = true
					drag_offset = get_local_mouse_position() / inventory_grid.cell_size
					get_viewport().set_input_as_handled()
					z_index = 100
					modulate = Color(1, 1, 1, 0.7)

			elif is_dragging:
				is_dragging = false
				get_viewport().set_input_as_handled()
				z_index = 0
				inventory_grid.drop_item(self)
				modulate = Color(1, 1, 1, 1)
