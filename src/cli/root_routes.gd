class_name RootRoutes
extends Routes.List

func _init() -> void:
	self._items = [
		DefaultRoutes.new(),
		EditorsRoutes.new()
	]
