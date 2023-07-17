class_name Set
extends RefCounted

var _set = {}


func append(value):
	_set[value] = value


func values():
	return _set.values()


static func of(array) -> Set:
	var set = Set.new()
	for el in array:
		set.append(el)
	return set
