class_name ProjectsVBoxList
extends VBoxList

signal item_removed(item_data: Projects.Item)
signal item_edited(item_data: Projects.Item)
signal item_manage_tags_requested(item_data: Projects.Item)
signal item_duplicate_requested(item_data: Projects.Item)


func _post_add(raw_item_data: Object, raw_item_control: Control) -> void:
	var item_data := raw_item_data as Projects.Item
	var item_control := raw_item_control as ProjectListItemControl
	item_control.removed.connect(
		func() -> void: item_removed.emit(item_data)
	)
	item_control.edited.connect(
		func() -> void: item_edited.emit(item_data)
	)
	item_control.manage_tags_requested.connect(
		func() -> void: item_manage_tags_requested.emit(item_data)
	)
	item_control.duplicate_requested.connect(
		func() -> void: item_duplicate_requested.emit(item_data)
	)


func _item_comparator(a: Dictionary, b: Dictionary) -> bool:
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


func _fill_sort_options(btn: OptionButton) -> void:
	btn.add_item(tr("Last Edited"))
	btn.add_item(tr("Name"))
	btn.add_item(tr("Path"))
	btn.add_item(tr("Tags"))
	
	var last_checked_sort := Cache.smart_value(self, "last_checked_sort", true)
	btn.select(last_checked_sort.ret(1) as int)
	btn.item_selected.connect(func(idx: int) -> void: last_checked_sort.put(idx))
