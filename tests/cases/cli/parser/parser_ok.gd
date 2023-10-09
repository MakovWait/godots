class_name CliParserOkTests
extends GdUnitTestSuite

func test_parse_command():
	var parser = CliParser.CommandParser.new(MockGrammar.new())
	var result = parser.parse_command(["namespace1", "cmd1", "just_name", "--flag1", "value1", "value2", "--bool-flag", "-a"])
	assert(result.namesp == "namespace1")
	assert(result.verb == "cmd1")
	assert("just_name" in result.names)
	assert("value1" in result.option_values("flag1"))
	assert("value2" in result.option_values("flag1"))
	assert(result.has_options(["bool-flag"]))
	assert(result.has_options(["a"]))
