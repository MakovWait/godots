class_name Comp
extends _Component


func _init(script, children=[]):
	super._init(func(): return script.new())
	self.children(children)
