extends Control

@onready var label: Label = $CenterContainer/Label
@onready var texture_progress_bar: TextureProgressBar = $TextureProgressBar

var scene_path: String = Transition.scene_path
var text: String = Transition.loading_text
var loading_progress: Array[float] = []
var tick: float = 0.5
var time_passed: float = 0.0
var step: int = 3
var min_wait_time: float = 2.5
var bar_speed: float = 0.15
var animation_in: String = ""
var animation_out: String = ""

func _ready() -> void:
	label.text = text + "\n..."
	ResourceLoader.load_threaded_request(scene_path, "", true)

func _process(delta: float) -> void:
	time_passed += delta
	min_wait_time -= delta
	if min_wait_time <= 0 and texture_progress_bar.value >= 1.0 and loading_progress[0] >= 1.0:
		_on_load_complete()
	ResourceLoader.load_threaded_get_status(scene_path, loading_progress)
	if texture_progress_bar.value < loading_progress[0]:
		texture_progress_bar.value = lerp(texture_progress_bar.value, loading_progress[0], bar_speed * delta)
	var change: float = 0.5 if loading_progress[0] >= 1.0 else clamp(0.9 - texture_progress_bar.value, 0.0, 1.0)
	texture_progress_bar.value += change * delta
	#label.text = str(int(texture_progress_bar.value * 100.0)) + " %"
	if time_passed <= tick:
		return
	time_passed = 0.0
	step += 1
	if step > 2:
		step = 0
	var next_line: String = ""
	for i in range(step + 1):
		next_line += "."
	label.text = text + "\n" + next_line

func _on_load_complete() -> void:
	Transition.load_scene(ResourceLoader.load_threaded_get(scene_path), Transition.loading_animation_in, Transition.loading_animation_out)
