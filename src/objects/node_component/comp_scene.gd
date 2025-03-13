class_name CompScene
extends _Component


func _init(scene: PackedScene, children: Array =[]) -> void:
	super._init(func() -> Node: return scene.instantiate())
	self.children(children)
