class_name CliOption

var description: String
var usage: String
var short: String
var long: String

func _init(long: String, short: String, description: String, usage: String):
	self.long = "--%s" % long
	self.short = "-%s" % short
	self.description = description
	self.usage = usage
