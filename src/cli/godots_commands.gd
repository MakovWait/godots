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
				"--ghelp or -gh"
			),
			CliOption.new(
				"recent",
				"r",
				"Open last modified project.",
				"--recent"
			),
		]
	),
#	CliCommand.new(
#		"editor",
#		"cfg",
#		"Manipulate editor cfg",
#		[
#			CliOption.new(
#				"name",
#				"n",
#				"Name of the editor",
#				"--name <partial-editor-name> or -n <partial-editor-name>"
#			),
#			CliOption.new(
#				"version-hint",
#				"vh",
#				"Version hint of the editor",
#				"--version-hint <version-hint> or -vh <version-hint>"
#			)
#		]
#	),
	CliCommand.new(
		"editor",
		"list",
		"Show editors list",
		[
		]
	),
	CliCommand.new(
		"exec",
		"",
		"Execute the command on specific editor. godots exec -- <args to pass to the editor>",
		[
			CliOption.new(
				"name",
				"n",
				"Name of the editor",
				"--name <partial-editor-name> or -n <partial-editor-name>"
			),
			CliOption.new(
				"version-hint",
				"vh",
				"Version hint of the editor",
				"--version-hint <version-hint> or -vh <version-hint>"
			),
			CliOption.new(
				"ignore-mono",
				"im",
				"Whether to take mono version into account if it is not explicitly specified",
				"--ignore-mono or -im"
			)
		]
	)
]
