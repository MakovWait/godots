extends VBoxList

signal item_removed(item_data)
signal item_edited(item_data)


func _post_add(item_data, item_control):
	item_control.removed.connect(
		func(): item_removed.emit(item_data)
	)
	item_control.edited.connect(
		func(): item_edited.emit(item_data)
	)


func _item_comparator(a, b):
	if a.favorite && !b.favorite:
		return true
	if b.favorite && !a.favorite:
		return false
	return a.name < b.name
