class_name RemoteImageSrc


class I:
	func async_load_img(url, callback: Callable):
		pass


class AlwaysBroken extends I:
	var _theme_src: Control
	
	func _init(theme_src: Control):
		_theme_src = theme_src
	
	func async_load_img(url, callback: Callable):
		var texture = _theme_src.get_theme_icon("FileBrokenBigThumb", "EditorIcons")
		callback.call(texture)
