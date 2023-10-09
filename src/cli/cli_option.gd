class_name CliOption

var description: String
var usage: String
var short: String
var long: String

func _init(long: String, short: String, description: String, usage: String):
	self.long = long
	self.short = short
	self.description = description
	self.usage = usage
