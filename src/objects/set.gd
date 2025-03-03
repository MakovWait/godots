class_name Set
extends RefCounted

var _set: Dictionary = {}


func append(value: Variant) -> void:
	_set[value] = value


func append_array(array: Array) -> void:
	for el: Variant in array:
		append(el)


func values() -> Array:
	var values := values_unsorted()
	values.sort()
	return values


func values_unsorted() -> Array:
	var values := _set.values().duplicate()
	return values


static func of(array: Array) -> Set:
	var set := Set.new()
	for el: Variant in array:
		set.append(el)
	return set
