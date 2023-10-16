class_name exml

class XMLNodeSmart extends RefCounted:
	var o : XMLNode
	
	func _init(origin):
		self.o = origin
	
	func attr(name, default=null):
		return o.attributes.get(name, default)
	
	func find_child_recursive(filter) -> XMLNode:
		for node in iter_children_recursive():
			if filter.call(node):
				return node
		return null
	
	func find_smart_child_recursive(filter) -> XMLNodeSmart:
		var node = find_child_recursive(filter)
		if node:
			return XMLNodeSmart.new(node)
		else:
			return null

	func iter_children_recursive():
		return FlatChildren.new(o)


class Filters:
	static func by_name(name):
		return func(x): return x.name == name
	
	static func by_attr(attr_name, attr_value):
		return func(x): return x.attributes.get(attr_name) == attr_value
	
	static func by_content(content):
		return func(x): return x.content == content
	
	static func and_(filters):
		return func(x):
			for filter in filters:
				if filter.call(x) == false:
					return false
			return true


class FlatChildren extends RefCounted:
	var _node: XMLNode
	var _nodes_to_iter = []
	
	func _init(node):
		_node = node
	
	func _should_continue():
		return len(_nodes_to_iter) > 0
	
	func _iter_next(arg):
		return _should_continue()
	
	func _iter_get(arg):
		var node = _nodes_to_iter.pop_front()
		_nodes_to_iter.append_array(node.children)
		return node
	
	func _iter_init(arg):
		if not _node:
			return false
		_nodes_to_iter.clear()
		_nodes_to_iter.append_array(_node.children)
		return _should_continue()


static func smart(node: XMLNode) -> XMLNodeSmart:
	return XMLNodeSmart.new(node)
