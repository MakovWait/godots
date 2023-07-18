class_name Set
extends RefCounted

var _set = {}


func append(value):
	_set[value] = value


func append_array(array):
	for el in array:
		append(el)


func values():
	var values = _set.values().duplicate()
	values.sort()
	return values


static func of(array) -> Set:
	var set = Set.new()
	for el in array:
		set.append(el)
	return set
