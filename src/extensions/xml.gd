class_name exml

class XMLNodeSmart extends RefCounted:
	var o: XMLNode
	
	func _init(origin: XMLNode) -> void:
		self.o = origin
	
	func attr(name: String, default: Variant = null) -> Variant:
		return o.attributes.get(name, default)
	
	func find_child_recursive(filter: Callable) -> XMLNode:
		for node in iter_children_recursive():
			if filter.call(node):
				return node
		return null
	
	func find_smart_child_recursive(filter: Callable) -> XMLNodeSmart:
		var node := find_child_recursive(filter)
		if node:
			return XMLNodeSmart.new(node)
		else:
			return null

	func iter_children_recursive() -> FlatChildren:
		return FlatChildren.new(o)


class Filters:
	static func by_name(name: String) -> Callable:
		return func(x: XMLNode) -> bool: return x.name == name
	
	static func by_attr(attr_name: String, attr_value: Variant) -> Callable:
		return func(x: XMLNode) -> bool: return x.attributes.get(attr_name) == attr_value
	
	static func by_content(content: String) -> Callable:
		return func(x: XMLNode) -> bool: return x.content == content
	
	static func and_(filters: Array) -> Callable:
		return func(x: XMLNode) -> bool:
			for filter: Callable in filters:
				if filter.call(x) == false:
					return false
			return true


class FlatChildren extends RefCounted:
	var _node: XMLNode
	var _nodes_to_iter: Array[XMLNode] = []
	
	func _init(node: XMLNode) -> void:
		_node = node
	
	func _should_continue() -> bool:
		return len(_nodes_to_iter) > 0
	
	func _iter_next(arg: Array) -> bool:
		return _should_continue()
	
	func _iter_get(arg: Variant) -> XMLNode:
		var node := _nodes_to_iter.pop_front() as XMLNode
		_nodes_to_iter.append_array(node.children)
		return node
	
	func _iter_init(arg: Array) -> bool:
		if not _node:
			return false
		_nodes_to_iter.clear()
		_nodes_to_iter.append_array(_node.children)
		return _should_continue()


static func smart(node: XMLNode) -> XMLNodeSmart:
	return XMLNodeSmart.new(node)
