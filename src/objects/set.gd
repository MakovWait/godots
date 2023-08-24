class_name Set
extends RefCounted

var _set = {}


func append(value):
	_set[value] = value


func append_array(array):
	for el in array:
		append(el)


func values():
	var values = values_unsorted()
	values.sort()
	return values


func values_unsorted():
	var values = _set.values().duplicate()
	return values


static func of(array) -> Set:
	var set = Set.new()
	for el in array:
		set.append(el)
	return set
