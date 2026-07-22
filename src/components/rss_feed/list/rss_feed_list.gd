extends VBoxList


func _post_add(_item_data: Object, _raw_item_control: Control) -> void:
	if _raw_item_control is RssFeedItemControl:
		var rss_control := get_parent()
		if rss_control is RssFeedControl:
			var item := _raw_item_control as RssFeedItemControl
			item.set_images_src((rss_control as RssFeedControl)._images_src)


func _item_comparator(a: Dictionary, b: Dictionary) -> bool:
	return true


func _fill_sort_options(_btn: OptionButton) -> void:
	pass
