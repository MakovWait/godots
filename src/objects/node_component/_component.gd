class_name _Component


var _node_src
var _on_init
var _children = []
var _comp_ref


func _init(node_src):
	self._node_src = node_src


func on_init(actions) -> _Component:
	if not actions is Array:
		actions = [actions]
	self._on_init = actions
	return self


func children(array) -> _Component:
	_children = array
	return self


func ref(ref) -> _Component:
	_comp_ref = ref
	return self


func add_to(target_node):
	var self_node = _node_src.call()
	
	if _on_init:
		for callback in _on_init:
			callback.call(self_node)
	
	if _comp_ref:
		_comp_ref.value = self_node
	
	for child in _children:
		child.add_to(self_node)
	
	target_node.add_child(self_node)
