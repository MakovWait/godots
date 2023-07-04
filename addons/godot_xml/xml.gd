## GodotXML - Advanced XML support for Godot 4.
## 
## This class allows parsing and dumping XML data from and to various sources.
class_name XML extends RefCounted


## Specifies the type of a node.
enum XMLNodeType {
	XML_NODE_ELEMENT_START, ## Start node ([code]<myroot>[/code])
	XML_NODE_ELEMENT_END, ## End node ([code]</myroot>[/code])
	XML_NODE_COMMENT, ## Comment node ([code]<!-- My comment -->[/code])
}


## Parses file content as XML into [XMLDocument].
## The file at a specified [code]path[/code] [b]must[/b] be readable.
## File content [b]must[/b] be a valid XML document.
static func parse_file(path: String) -> XMLDocument:
	var file = FileAccess.open(path, FileAccess.READ)
	var xml: PackedByteArray = file.get_as_text().to_utf8_buffer()
	file = null

	return _parse(xml)


## Parses string as XML into [XMLDocument].
## String content [b]must[/b] be a valid XML document.
static func parse_str(xml: String) -> XMLDocument:
	return _parse(xml.to_utf8_buffer())


## Parses byte buffer as XML into [XMLDocument].
## Buffer content [b]must[/b] be a valid XML document.
static func parse_buffer(xml: PackedByteArray) -> XMLDocument:
	return _parse(xml)


## Dumps [param document] to the specified file.
## The file at a specified [code]path[/code] [b]must[/b] be writeable.
## Set [param beautify] to [code]true[/code] if you want indented output.
static func dump_file(path: String, document: XMLDocument, beautify: bool = false):
	var file = FileAccess.open(path, FileAccess.WRITE)
	var xml: String = dump_str(document, beautify)
	file.store_string(xml)
	file = null


## Dumps [param document] to a [PackedByteArray].
## Set [param beautify] to [code]true[/code] if you want indented output.
static func dump_buffer(document: XMLDocument, beautify: bool = false) -> PackedByteArray:
	return dump_str(document, beautify).to_utf8_buffer()


## Dumps [param document] to [String].
## Set [param beautify] to [code]true[/code] if you want indented output.
static func dump_str(document: XMLDocument, beautify: bool = false) -> String:
	return _dump(document, beautify)


static func _dump(document: XMLDocument, beautify: bool = false):
	if not beautify:
		return _dump_compact(document.root)
	else:
		return _dump_beautifully(document.root)


static func _dump_compact(node: XMLNode):
	var out: String = ""

	out += _dump_node(node)
	
	for child in node.children:
		out += _dump_compact(child)

	if not node.standalone:
		out += _dump_node(node, true)

	return out


static func _dump_beautifully(node: XMLNode, indent: int = 0):
	var out: String = ""

	out += _beauty(_dump_node(node, false, true), indent)

	for child in node.children:
		out += _dump_beautifully(child, indent + 4)

	if not node.standalone:
		out += _beauty(_dump_node(node, true, true), indent)

	return out


static func _beauty(string: String, i: int) -> String:
	return " ".repeat(i) + string + "\n"


static func _dump_node(node: XMLNode, closing: bool = false, beautify: bool = false):
	var attrs: Array[String] = []

	for attr in node.attributes:
		attrs.append(attr + "=\"" + node.attributes.get(attr) + "\"")
	
	var attrstr = " ".join(attrs)

	if node.standalone:
		var space = " " if beautify else ""
		return "<%s %s%s/>" % [node.name, attrstr, space]
	else:
		if closing:
			return "</%s>" % node.name
		else:
			var space = " " if not attrstr.is_empty() else ""
			return "<%s%s%s>%s" % [node.name, space, attrstr, node.content]


static func _parse(xml: PackedByteArray) -> XMLDocument:
	var doc: XMLDocument = XMLDocument.new()
	var queue: Array = []

	var parser: XMLParser = XMLParser.new()
	parser.open_buffer(xml)

	while parser.read() != ERR_FILE_EOF:
		var node: XMLNode = _make_node(queue, parser)

		if node == null:
			continue

		if len(queue) == 0:
			doc.root = node
			queue.append(node)
		else:
			var node_type = parser.get_node_type()

			if node_type == XMLParser.NODE_TEXT:
				continue

			if node.standalone and not node_type == XMLParser.NODE_ELEMENT_END:
				queue.back().children.append(node)
			elif node_type == XMLParser.NODE_ELEMENT_END and not node.standalone:
				queue.pop_back()
			else:
				queue.back().children.append(node)
				queue.append(node)
	
	return doc


static func _make_node(queue: Array, parser: XMLParser):
	var node_type = parser.get_node_type()

	match node_type:
		XMLParser.NODE_ELEMENT:
			return _make_node_element(parser)
		XMLParser.NODE_ELEMENT_END:
			return _make_node_element_end(parser)
		XMLParser.NODE_TEXT:
			_attach_node_data(queue.back(), parser)
			return

	#print(node_type)
	#print(parser.get_node_data())
	#print(parser.get_node_name())


static func _make_node_element(parser: XMLParser):
	var node: XMLNode = XMLNode.new()

	node.name = parser.get_node_name()
	node.attributes = _get_attributes(parser)
	node.content = ""
	node.standalone = parser.is_empty()
	node.children = []

	return node


static func _make_node_element_end(parser: XMLParser) -> XMLNode:
	var node: XMLNode = XMLNode.new()

	node.name = parser.get_node_name()
	node.attributes = {}
	node.content = ""
	node.standalone = false
	node.children = []

	return node


static func _attach_node_data(node: XMLNode, parser: XMLParser) -> void:
	if node.content.is_empty():
		node.content = parser.get_node_data().strip_edges().lstrip(" ").rstrip(" ")


static func _get_attributes(parser: XMLParser) -> Dictionary:
	var attrs: Dictionary = {}
	var attr_count: int = parser.get_attribute_count()

	for attr_idx in range(attr_count):
		attrs[parser.get_attribute_name(attr_idx)] = parser.get_attribute_value(attr_idx)
	
	return attrs
