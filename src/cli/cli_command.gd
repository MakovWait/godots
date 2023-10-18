class_name CliCommand

var namesp: String
var verb: String
var description: String
var options: Array[CliOption] = []

func _init(namesp: String, verb: String, description: String, options: Array[CliOption]):
	self.namesp = namesp
	self.verb = verb
	self.description = description
	self.options = options

func to_help_string(padding: int) -> String:
	var result: PackedStringArray = []

	if not self.verb.is_empty():
		result.append("\t%s - %s" % [ljust(self.verb, padding), description])

	for option in options:
		result.append("\t\t%s" % option.to_help_string())

	return "\n".join(result)

static func ljust(input: String, width: int) -> String:
	var output = input
	while output.length() < width:
		output += " "
	return output
