class_name CompScene
extends _Component


func _init(scene: PackedScene, children=[]):
	super._init(func(): return scene.instantiate())
	self.children(children)
