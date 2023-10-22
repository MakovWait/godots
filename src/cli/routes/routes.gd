class_name Routes

class List extends Item:
	var _items: Array[Item] = []

	func route(cmd: CliParser.ParsedCommandResult, user_args: PackedStringArray):
		for item in _items:
			if item.match(cmd, user_args):
				item.route(cmd, user_args)
				break

	func match(cmd: CliParser.ParsedCommandResult, user_args: PackedStringArray) -> bool:
		for item in _items:
			if item.match(cmd, user_args):
				return true
		return false

class Item:
	func route(cmd, user_args) -> Callable:
		return func(): pass

	func match(cmd: CliParser.ParsedCommandResult, user_args: PackedStringArray) -> bool:
		return false
