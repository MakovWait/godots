static func clear_and_free(dict: Dictionary) -> void:
	var old_values = dict.values()
	dict.clear()
	for x in old_values:
		if not x is RefCounted:
			x.free()
		elif x.has_method('before_delete_as_ref_counted'):
			x.before_delete_as_ref_counted()
