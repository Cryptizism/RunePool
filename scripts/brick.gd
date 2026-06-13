extends CellObject
class_name Brick

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	if !sprite:
		queue_free()
		return
	super()
	add_to_group("bricks")

func _process(delta: float) -> void:
	super(delta)
