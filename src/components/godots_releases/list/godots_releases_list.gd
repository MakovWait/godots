extends VBoxList

signal download_and_install_requested(url)


func _post_add(item_data, item_control):
	item_control.download_and_install_requested.connect(func(url): 
		download_and_install_requested.emit(url)
	)


func _item_comparator(a, b):
	return true


func _fill_sort_options(btn: OptionButton):
	pass
