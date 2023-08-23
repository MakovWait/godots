class_name CompRefs


class Simple:
	var value
	
	func _init(value=null):
		self.value = value


class Transient:
	var _on_set
	var value:
		set(v): 
			_on_set.call(v)
	
	func _init(on_set):
		_on_set = on_set


class Field extends Transient:
	func _init(obj, field_key):
		super._init(func(v): obj.set(field_key, v))
