extends Node

var next_gem_cluster: Array = []
var selected_level: String = "classic"
var player_count: int = 1
var player_characters: Array[String] = ["tippi", "tippi"]
var player_speed: Array[float] = [0.0, 0.0]
var player_difficulty: Array[int] = [0, 0]
var current_floor: int = 1
var story_mode_enemies: Array[String] = [
	"mummy",
	"goblin",
	"golem",
	"mimic",
	"dragon",
	"bobo",
	"wizard",
	"feline",
]

const COLORS: Array[String] = [
	"red",
	"blue",
	"green",
	"yellow",
]
const PARTICLES: Dictionary = {
	"red": preload("res://sprites/game/particles/fire.png"),
	"blue": preload("res://sprites/game/particles/water.png"),
	"green": preload("res://sprites/game/particles/leaf.png"),
	"yellow": preload("res://sprites/game/particles/lightning.png"),
}
const EXTRAS: Dictionary = {
	"brick": preload("res://sprites/ui/brick.png")
}
