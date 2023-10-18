class_name GodotsCommands

static var commands: Array[CliCommand] = [
	CliCommand.new(
		"",
		"",
		"Shows the global help menu.",
		[
			CliOption.new(
				"ghelp",
				"gh",
				"Displays global help information.",
				"--ghelp or -gh")
		]
	)
]
