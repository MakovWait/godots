class_name Comp
extends _Component


func _init(script: Object, children:=[]) -> void:
	super._init(func() -> Node: return script.call("new"))
	self.children(children)
