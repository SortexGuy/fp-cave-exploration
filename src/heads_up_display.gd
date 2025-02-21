extends CanvasLayer
class_name HeadsUpDisplay

@onready var p_inv: Inventory = (get_parent() as Player).inventory
@onready var item_tex_rect_1: TextureRect = %ItemTextureRect1
@onready var item_tex_rect_2: TextureRect = %ItemTextureRect2
@onready var item_tex_rect_3: TextureRect = %ItemTextureRect3

func _process(delta: float) -> void:
	var items: Array[InventoryItem] = p_inv.items.duplicate(true)
	for item_tex in [item_tex_rect_1, item_tex_rect_2, item_tex_rect_3]:
		item_tex = item_tex as TextureRect
		var item: InventoryItem = items.pop_front()
		var texture: Texture = item.texture if item else null
		item_tex.texture = texture
