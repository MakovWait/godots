class_name MockGrammar 
extends Grammar

func supports_flag(namesp: String, verb: String, token: String) -> bool:
	return token in ["--flag1", "-f1", "--flag2", "--auto", "-a", "--bool-flag"]

func supports_namespace(namesp: String) -> bool:
	return namesp in ["namespace1", "namespace2"]

func supports_verb(namesp: String, verb: String) -> bool:
	return verb in ["cmd1", "cmd2"]

func flag_name_forms(namesp: String, verb: String, flag: String) -> Array[String]:
	if flag == "--flag1" or flag == "-f1":
		return ["--flag1", "-f1"]

	if flag == "--auto" or flag == "-a":
		return ["--auto", "-a"]

	if flag == "--bool-flag" or flag == "-bf":
		return ["--bool-flag", "-bf"]

	return []

func verbs(scope: String) -> Array:
	return ["cmd1", "cmd2"]

func namespaces() -> Array:
	return ["namespace1", "namespace2"]
