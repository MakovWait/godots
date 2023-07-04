## Represents an XML element (AKA XML node).
class_name XMLNode extends RefCounted

## XML node name.
var name: String = ""

## XML node attributes.
var attributes: Dictionary = {}

## XML node content.
var content: String = ""

## Whether the XML node is an empty node (AKA standalone node).
var standalone: bool = false

## XML node's children.
var children: Array[XMLNode] = []

func _to_string():
	return "<XMLNode name=%s attributes=%s content=%s standalone=%s children=%s>" % [
		name,
		"{...}" if len(attributes) > 0 else "{}",
		"\"...\"" if len(content) > 0 else "\"\"",
		str(standalone),
		"[...]" if len(children) > 0 else "[]"
	]
