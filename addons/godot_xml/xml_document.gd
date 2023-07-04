## Represents an XML document.
class_name XMLDocument extends RefCounted

## The XML root node.
var root: XMLNode

## Converts this tree into a [Dictionary].
## Set [param include_empty_fields] to [code]true[/code] if you want
## to include fields that do not have any content (e.g., a node without
## a single attribute or without content).
## [param node_content_field_name] controls which field node's content is assigned to.
func to_dict(
	include_empty_fields: bool = false,
	node_content_field_name: String = "__content__",
) -> Dictionary:
	return _to_dict(root, include_empty_fields, node_content_field_name)


static func _to_dict(
	node: XMLNode,
	include_empty_fields: bool = false,
	node_content_field_name: String = "__content__",
) -> Dictionary:
	var data: Dictionary = {}

	if include_empty_fields:
		data = _to_dict_all_fields(node)
		data.children = []
	else:
		data =_to_dict_least_fields(node)

	data[node_content_field_name] = node.content

	for child in node.children:
		if not data.has("children"):
			data.children = []

		data.children.append(_to_dict(child))

	return data


static func _to_dict_all_fields(node: XMLNode) -> Dictionary:
	var data: Dictionary = {}

	data.name = node.name
	data.attributes = node.attributes
	data.standalone = node.standalone

	return data


static func _to_dict_least_fields(node: XMLNode) -> Dictionary:
	var data: Dictionary = {}

	if not node.name.is_empty():
		data.name = node.name

	if not node.attributes.is_empty():
		data.attributes = node.attributes

	data.standalone = node.standalone

	return data


func _to_string():
	return "<XMLDocument root=%s>" % str(root)
