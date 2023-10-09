class_name CliParserNotOkTests
extends GdUnitTestSuite

func test_invalid_namespace():
	var parser = CliParser.CommandParser.new(MockGrammar.new())
	var result = parser.parse_command(["invalidNamespace"])
	assert(result.has_error())
	assert(result.errors[0] == "Expected any `namespace1 namespace2` namespace, got `invalidNamespace`")

func test_invalid_command():
	var parser = CliParser.CommandParser.new(MockGrammar.new())
	var result = parser.parse_command(["namespace1", "invalidCmd"])
	assert(result.has_error())
	assert(result.errors[0] == "Expected any `cmd1 cmd2` verb, got `invalidCmd`")

func test_invalid_option():
	var parser = CliParser.CommandParser.new(MockGrammar.new())
	var result = parser.parse_command(["namespace1", "cmd1", "--invalidOption"])
	assert(result.has_error())

func test_repeated_options():
	var parser = CliParser.CommandParser.new(MockGrammar.new())
	var result = parser.parse_command(["namespace1", "cmd1", "--flag1", "value1", "--flag1", "value2"])
	assert(result.has_error())
	assert(result.errors[0] == "Only one option with name (`flag1`, `f1`) can be used.")

func test_repeated_short_and_long_options():
	var parser = CliParser.CommandParser.new(MockGrammar.new())
	var result = parser.parse_command(["namespace1", "cmd1", "--flag1", "value1", "-f1", "value2"])
	assert(result.has_error())
	assert(result.errors[0] == "Only one option with name (`flag1`, `f1`) can be used.")
