class_name CliParserNotOkTests
extends GdUnitTestSuite

func test_invalid_namespace():
	var parser = CliParser.CommandParser.new(TestGrammar.grammar)
	var result = parser.parse_command(["invalidNamespace"])
	assert(result.namesp.is_empty())
	assert(result.verb.is_empty())
	assert(result.names[0] == "invalidNamespace")

func test_invalid_command():
	var parser = CliParser.CommandParser.new(TestGrammar.grammar)
	var result = parser.parse_command(["namespace1", "invalidVerb"])
	assert(result.namesp == "namespace1")
	assert(result.verb.is_empty())
	assert(result.names[0] == "invalidVerb")

func test_invalid_option():
	var parser = CliParser.CommandParser.new(TestGrammar.grammar)
	var result = parser.parse_command(["namespace1", "verb1", "--invalidOption"])
	assert(result.has_error())
	assert(result.errors[0] == "Unsupported option: --invalidOption")

func test_repeated_options():
	var parser = CliParser.CommandParser.new(TestGrammar.grammar)
	var result = parser.parse_command(["namespace1", "verb1", "--flag1", "value1", "--flag1", "value2"])
	assert(result.has_error())
	assert(result.errors[0] == "Only one option with name (`flag1`, `f1`) can be used.")

func test_repeated_short_and_long_options():
	var parser = CliParser.CommandParser.new(TestGrammar.grammar)
	var result = parser.parse_command(["namespace1", "verb1", "--flag1", "value1", "-f1", "value2"])
	assert(result.has_error())
	assert(result.errors[0] == "Only one option with name (`flag1`, `f1`) can be used.")
