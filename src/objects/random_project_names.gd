class_name RandomProjectNames
extends RefCounted


var prefixes: PackedStringArray = [
	"Super",
	"Mega",
	"Ultra",
	"Hyper",
	"Epic",
	"Fantastic",
	"Awesome",
	"Incredible",
	"Stellar",
	"Quantum",
	"Galactic",
	"Cosmic",
	"Mystical",
	"Legendary",
	"Enigmatic",
	"Mythic",
	"Futuristic",
	"Timeless",
	"Dynamic",
	"Adrenaline",
	"Exquisite",
	"Spectacular",
	"Immersive",
	"Daring",
	"Enchanted",
	"Ingenious",
	"Dreamlike",
	"Serene",
	"Vibrant",
	"Whimsical"
]


var topics: PackedStringArray = [
	"Adventure",
	"Space",
	"Fantasy",
	"Puzzle",
	"Mystery",
	"Platformer",
	"Simulation",
	"Racing",
	"Strategy",
	"Horror",
	"Survival",
	"Exploration",
	"Stealth",
	"Action",
	"Role-playing",
	"Science Fiction",
	"Medieval",
	"Historical",
	"Cyberpunk",
	"Post-apocalyptic",
	"Martial Arts",
	"Western",
	"Noir",
	"Comedy",
	"Romance",
	"Superhero",
	"Magical",
	"Surreal",
	"Educational"
]

var suffixes: PackedStringArray = [
	"Game",
	"Adventure",
	"Quest",
	"Journey",
	"Challenge",
	"Simulator",
	"Racer",
	"Puzzle",
	"Mystery",
	"Fantasy",
	"World",
	"Realm",
	"Planet",
	"Universe",
	"Tales",
	"Legends",
	"Chronicles",
	"Odyssey",
	"Voyage",
	"Expedition",
	"Adventures",
	"Explorer",
	"Discovery",
	"Misadventure",
	"Saga",
	"Epic",
	"Quests",
	"Ventures",
	"Travels",
	"Mysteries"
]


func next() -> String:
	var prefix := prefixes[randi() % prefixes.size()]
	var topic := topics[randi() % topics.size()]
	var suffix := suffixes[randi() % suffixes.size()]
	return prefix + " " + topic + " " + suffix


func set_prefixes(value: Array) -> void:
	if len(value) > 0:
		prefixes = value


func set_suffixes(value: Array) -> void:
	if len(value) > 0:
		suffixes = value


func set_topics(value: Array) -> void:
	if len(value) > 0:
		topics = value
