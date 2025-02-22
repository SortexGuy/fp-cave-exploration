extends Node

var p_inv: Inventory = null :
	set (inv): _set_p_inv

var hud_item_tex_rects: Array[TextureRect]

func _set_p_inv(inv: Inventory) -> void:
	if inv != null:
		inv.inv_changed.connect(_on_inv_changed)
		p_inv = inv
	else:
		inv.inv_changed.disconnect(_on_inv_changed)
		for item_tex in hud_item_tex_rects:
			item_tex.texture = null
		p_inv = inv

func _on_inv_changed(items: Array[InventoryItem]) -> void:
	if hud_item_tex_rects == null: return
	for item_tex in hud_item_tex_rects:
		item_tex = item_tex as TextureRect
		var item: InventoryItem = items.pop_front()
		var texture: Texture = item.texture if item else null
		item_tex.texture = texture
