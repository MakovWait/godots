class_name CliParserOkTests
extends GdUnitTestSuite

func test_parse_command():
	var parser = CliParser.CommandParser.new(TestGrammar.grammar)
	var result = parser.parse_command(["namespace1", "verb1", "just_name", "--flag1", "value1", "value2", "--bool-flag", "-a"])
	assert(result.namesp == "namespace1")
	assert(result.verb == "verb1")
	assert("just_name" in result.names)
	assert("value1" in result.option_values("flag1"))
	assert("value2" in result.option_values("flag1"))
	assert(result.has_options(["bool-flag"]))
	assert(result.has_options(["a"]))

func test_parse_without_verb():
	var parser = CliParser.CommandParser.new(TestGrammar.grammar)
	var result = parser.parse_command(["namespace1", "just_name", "--flag1", "value1", "value2", "--bool-flag", "-a"])
	assert(result.namesp == "namespace1")
	assert(result.verb == "")
	assert("just_name" in result.names)
	assert("value1" in result.option_values("flag1"))
	assert("value2" in result.option_values("flag1"))
	assert(result.has_options(["bool-flag"]))
	assert(result.has_options(["a"]))


func test_parse_without_namespace_and_verb():
	var parser = CliParser.CommandParser.new(TestGrammar.grammar)
	var result = parser.parse_command(["just_name", "--flag1", "value1", "value2", "--bool-flag", "-a"])
	assert(result.namesp == "")
	assert(result.verb == "")
	assert("just_name" in result.names)
	assert("value1" in result.option_values("flag1"))
	assert("value2" in result.option_values("flag1"))
	assert(result.has_options(["bool-flag"]))
	assert(result.has_options(["a"]))
