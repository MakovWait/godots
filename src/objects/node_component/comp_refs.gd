class_name CompRefs


class Simple:
	var value: Variant
	
	func _init(value: Variant = null) -> void:
		self.value = value


class Transient:
	var _on_set: Callable
	var value: Variant:
		set(v): 
			_on_set.call(v)
	
	func _init(on_set: Callable) -> void:
		_on_set = on_set


class Field extends Transient:
	func _init(obj: Object, field_key: String) -> void:
		super._init(func(v: Variant) -> void: obj.set(field_key, v))
