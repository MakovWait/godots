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
