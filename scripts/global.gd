extends Node

var next_gem_cluster: Array = []
var selected_level: String = "classic"
var speed_p1: float = 0.0
var speed_p2: float = 0.0
var difficulty_p1: int = 0
var difficulty_p2: int = 0

const COLORS: Array[String] = [
	"red",
	"blue",
	"green",
	"yellow",
]
const PARTICLES: Dictionary = {
	"red": preload("res://sprites/game/fire.png"),
	"blue": preload("res://sprites/game/water.png"),
	"green": preload("res://sprites/game/leaf.png"),
	"yellow": preload("res://sprites/game/lightning.png"),
}
const EXTRAS: Dictionary = {
	"brick": preload("res://sprites/ui/brick.png")
}
