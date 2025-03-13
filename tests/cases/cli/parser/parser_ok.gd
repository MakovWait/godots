class_name CliParserOkTests
extends GdUnitTestSuite

func test_parse_command() -> void:
	var parser := CliParser.CommandParser.new(TestGrammar.grammar)
	var result := parser.parse_command(["namespace1", "verb1", "just_name", "--flag1", "value1", "value2", "--bool-flag", "-a"])
	var args: CliParser.ParsedArguments = result.args
	assert(result.namesp == "namespace1")
	assert(result.verb == "verb1")
	assert("just_name" in args.names)
	assert("value1" in args.option_values("flag1"))
	assert("value2" in args.option_values("flag1"))
	assert(args.has_options(["bool-flag"]))
	assert(args.has_options(["a"]))

func test_parse_without_verb() -> void:
	var parser := CliParser.CommandParser.new(TestGrammar.grammar)
	var result := parser.parse_command(["namespace1", "just_name", "--flag1", "value1", "value2", "--bool-flag", "-a"])
	var args: CliParser.ParsedArguments = result.args
	assert(result.namesp == "namespace1")
	assert(result.verb == "")
	assert("just_name" in args.names)
	assert("value1" in args.option_values("flag1"))
	assert("value2" in args.option_values("flag1"))
	assert(args.has_options(["bool-flag"]))
	assert(args.has_options(["a"]))

func test_parse_without_namespace_and_verb() -> void:
	var parser := CliParser.CommandParser.new(TestGrammar.grammar)
	var result := parser.parse_command(["just_name", "--flag1", "value1", "value2", "--bool-flag", "-a"])
	var args: CliParser.ParsedArguments = result.args
	assert(result.namesp == "")
	assert(result.verb == "")
	assert("just_name" in args.names)
	assert("value1" in args.option_values("flag1"))
	assert("value2" in args.option_values("flag1"))
	assert(args.has_options(["bool-flag"]))
	assert(args.has_options(["a"]))
