extends VBoxList

signal item_removed(item_data)
signal item_edited(item_data)
signal item_manage_tags_requested(item_data)
signal item_duplicate_requested(item_data)


func _post_add(item_data, item_control):
	item_control.removed.connect(
		func(): item_removed.emit(item_data)
	)
	item_control.edited.connect(
		func(): item_edited.emit(item_data)
	)
	item_control.manage_tags_requested.connect(
		func(): item_manage_tags_requested.emit(item_data)
	)
	item_control.duplicate_requested.connect(
		func(): item_duplicate_requested.emit(item_data)
	)


func _item_comparator(a, b):
	if a.favorite && !b.favorite:
		return true
	if b.favorite && !a.favorite:
		return false
	match _sort_option_button.selected:
		0: return a.last_modified > b.last_modified
		2: return a.path < b.path
		3: return a.tag_sort_string < b.tag_sort_string
		_: return a.name < b.name
	return a.name < b.name


func _fill_sort_options(btn: OptionButton):
	btn.add_item(tr("Last Edited"))
	btn.add_item(tr("Name"))
	btn.add_item(tr("Path"))
	btn.add_item(tr("Tags"))
	
	var last_checked_sort = Cache.smart_value(self, "last_checked_sort", true)
	btn.select(last_checked_sort.ret(1))
	btn.item_selected.connect(func(idx): last_checked_sort.put(idx))
