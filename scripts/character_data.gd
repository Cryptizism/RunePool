extends Resource

const CHARACTER_DATA: Dictionary = {
	"error": {
		"name": "error",
		"ability": "N/A",
		"max_hp": 5,
		"attack_frequency": 999,
		"sprite_frames": preload("res://animations/error.tres"),
	},
	"tippi": {
		"name": "Tippi",
		"ability": "Throw a Gem after combo.",
		"max_hp": 30,
		"attack_frequency": 3,
		"sprite_frames": preload("res://animations/turtle.tres"),
	},
	"mummy": {
		"name": "Mop",
		"ability": "Short pause every 3 Turns.",
		"max_hp": 10,
		"attack_frequency": 6,
		"sprite_frames": preload("res://animations/mummy.tres"),
	},
	"goblin": {
		"name": "Ka'Bam",
		"ability": "Occasionally drop Bombs.",
		"max_hp": 20,
		"attack_frequency": 4,
		"sprite_frames": preload("res://animations/goblin.tres"),
	},
	"golem": {
		"name": "Oug",
		"ability": "Clear top 3 rows on combo.",
		"max_hp": 30,
		"attack_frequency": 4,
		"sprite_frames": preload("res://animations/golem.tres"),
	},
	"mimic": {
		"name": "Slobber",
		"ability": "More single colored Clusters.",
		"max_hp": 10,
		"attack_frequency": 2,
		"sprite_frames": preload("res://animations/mimic.tres"),
	},
	"dragon": {
		"name": "Tod, Alan, & Mim",
		"ability": "More Runes + Can combo with 3.",
		"max_hp": 20,
		"attack_frequency": 3,
		"sprite_frames": preload("res://animations/dragon.tres"),
	},
	"bobo": {
		"name": "Bobo",
		"ability": "No Wacky Clusters.",
		"max_hp": 20,
		"attack_frequency": 3,
		"sprite_frames": preload("res://animations/bobo.tres"),
	},
	"wizard": {
		"name": "Archibald",
		"ability": "Combo breaks +1 random Gem.",
		"max_hp": 20,
		"attack_frequency": 3,
		"sprite_frames": preload("res://animations/wizard.tres"),
	},
	"feline": {
		"name": "???",
		"ability": "Only Wacky Clusters.",
		"max_hp": 40,
		"attack_frequency": 3,
		"sprite_frames": preload("res://animations/feline.tres"),
	},
}
