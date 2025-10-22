class_name EnemyData

var name: String
var animation_path: String
var max_hp: int
var hp: int
var attack_speed: float
var turns_since_attack: int = 1
var attacks_per_turn: int = 1

func _init(level_name: String):
	#if level_name == "classic":
	name = "EVIL Tippi"
	animation_path = "res://animations/turtle.tres"
	max_hp = 10
	attack_speed = 6
	#
	hp = max_hp
