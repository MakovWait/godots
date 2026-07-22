class_name ProjectTemplatesVBoxList
extends VBoxList

signal item_opened(item_data: ProjectTemplates.Item)
signal item_removed(item_data: ProjectTemplates.Item)


func _post_add(raw_item_data: Object, raw_item_control: Control) -> void:
	var item_data := raw_item_data as ProjectTemplates.Item
	var item_control := raw_item_control as TemplateListItemControl
	item_control.opened.connect(
		func() -> void: item_opened.emit(item_data)
	)


func _item_comparator(a: Dictionary, b: Dictionary) -> bool:
	match _sort_option_button.selected:
		0: return a.created_at > b.created_at
		_: return a.name < b.name
	return a.name < b.name


func _fill_sort_options(btn: OptionButton) -> void:
	btn.add_item(tr("Newest First"))
	btn.add_item(tr("Name"))
	
	var last_checked_sort := Cache.smart_value(self, "last_checked_sort", true)
	btn.select(last_checked_sort.ret(0) as int)
	btn.item_selected.connect(func(idx: int) -> void: last_checked_sort.put(idx))
