extends Resource
class_name Inventory

@export var max_items: int = 5
@export var items: Array[InventoryItem]
signal item_added(mod: ModManager.Modifiers)
signal item_removed(mod: ModManager.Modifiers)
signal inv_changed(items: Array[InventoryItem])

func add_item(item: InventoryItem) -> bool:
	for _item in items:
		if _item.modifier == item.modifier:
			return true
	if is_full():
		return true
	items.append(item)
	ModManager.mod_added.emit(item.modifier)
	inv_changed.emit(items.duplicate(true))
	return false

func has_modifier(mod: ModManager.Modifiers) -> bool:
	if items.is_empty(): return false
	for item in items:
		if item.modifier == mod:
			return true
	return false

func remove_item(item: InventoryItem) -> void:
	for _item in items:
		if _item.modifier == item.modifier:
			items.erase(_item)
	ModManager.mod_removed.emit(item.modifier)
	inv_changed.emit(items.duplicate(true))

func is_full() -> bool:
	if items.size() >= max_items:
		return true
	return false
