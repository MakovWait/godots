class_name _Component


var _node_src: Callable
var _on_init: Array
var _children := []
var _comp_ref: Object


func _init(node_src: Callable) -> void:
	self._node_src = node_src


func on_init(actions: Variant) -> _Component:
	if not actions is Array:
		actions = [actions]
	self._on_init = actions
	return self


func children(array: Array) -> _Component:
	_children = array
	return self


func ref(ref: Object) -> _Component:
	_comp_ref = ref
	return self


## target_node: {add_child: Callable}
func add_to(target_node: Object) -> void:
	var self_node: Node = _node_src.call()
	
	if _on_init:
		for callback: Callable in _on_init:
			callback.call(self_node)
	
	if _comp_ref:
		_comp_ref.set("value", self_node)
	
	for child: _Component in _children:
		child.add_to(self_node)
	
	target_node.call("add_child", self_node)
