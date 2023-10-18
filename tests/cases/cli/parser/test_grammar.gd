class_name TestGrammar

static var grammar = CliGrammar.new([
	CliCommand.new(
		"namespace1",
		"verb1",
		"",
		[
			CliOption.new("flag1", "f1", "", ""),
			CliOption.new("bool-flag", "bl", "", ""),
			CliOption.new("auto", "a", "", ""),
		],
	),
	CliCommand.new(
		"namespace1",
		"",
		"",
		[
			CliOption.new("flag1", "f1", "", ""),
			CliOption.new("bool-flag", "bl", "", ""),
			CliOption.new("auto", "a", "", ""),
		],
	),
	CliCommand.new(
		"",
		"",
		"",
		[
			CliOption.new("flag1", "f1", "", ""),
			CliOption.new("bool-flag", "bl", "", ""),
			CliOption.new("auto", "a", "", ""),
		],
	),
	CliCommand.new(
		"namespace1",
		"verb2",
		"",
		[]
	),
	CliCommand.new(
		"namespace2",
		"verb1",
		"",
		[
			CliOption.new("flag1", "f1", "", ""),
			CliOption.new("bool-flag", "bl", "", ""),
		]
	),
])
