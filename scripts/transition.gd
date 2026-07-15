extends CanvasLayer

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var new_scene_capture: TextureRect = $NewSceneCapture
@onready var old_scene_capture: TextureRect = $OldSceneCapture
@onready var temp_viewport: SubViewport = $SubViewportContainer/TempViewport

var loading_screen: String = "res://scenes/menus/loading_level.tscn"
var scene_path: String = "res://scenes/menus/main_menu.tscn"
var loading_text: String = "Loading"
var previous_scene: String
var loading_animation_in: String = ""
var loading_animation_out: String = ""

func _ready() -> void:
	_reset_captures()

func load_scene(scene: PackedScene, animation_in: String = "fade_in", animation_out: String = "fade_out") -> void:
	if !scene:
		push_error("Attempted loading non-existing scene.")
		return
	if get_tree().current_scene:
		previous_scene = get_tree().current_scene.scene_file_path
	if !animation_player:
		push_error("Error playing scene transition.")
		get_tree().change_scene_to_packed(scene)
		return
	if _is_slide_transition(animation_out):
		old_scene_capture.texture = _capture_main_viewport()
		old_scene_capture.show()
	if animation_player.has_animation(animation_in):
		animation_player.play(animation_in)
		await animation_player.animation_finished
	if _is_slide_transition(animation_out):
		var new_scene_instance = scene.instantiate()
		temp_viewport.add_child(new_scene_instance)
		await RenderingServer.frame_post_draw
		new_scene_capture.texture = _capture_temp_viewport()
		new_scene_capture.show()
		temp_viewport.remove_child(new_scene_instance)
	get_tree().change_scene_to_packed(scene)
	if animation_player.has_animation(animation_out):
		animation_player.play(animation_out)
		await animation_player.animation_finished
	_reset_captures()

func change_scene(_scene_path: String, animation_in: String = "fade_in", animation_out: String = "fade_out") -> void:
	if !ResourceLoader.exists(_scene_path):
		push_error("Attempted loading non-existing scene " + _scene_path + ".")
		return
	var scene_resource = load(_scene_path)
	if scene_resource is not PackedScene:
		push_error("Loaded scene is not packed.")
		return
	load_scene(scene_resource, animation_in, animation_out)

func change_scene_loading(_scene_path: String, text: String = "Loading", animation_in: String = "fade_in", animation_out: String = "fade_out", _loading_animation_in: String = "fade_in", _loading_animation_out: String = "fade_out") -> void:
	loading_text = text
	scene_path = _scene_path
	change_scene(loading_screen, animation_in, animation_out)
	loading_animation_in = _loading_animation_in
	loading_animation_out = _loading_animation_out

func change_to_previous_scene() -> void:
	change_scene(previous_scene)

func _reset_captures() -> void:
	old_scene_capture.hide()
	old_scene_capture.texture = null
	new_scene_capture.hide()
	new_scene_capture.texture = null

func _capture_main_viewport() -> ImageTexture:
	var image: Image = get_viewport().get_texture().get_image()
	var base_width: float = ProjectSettings.get_setting("display/window/size/viewport_width")
	var base_height: float = ProjectSettings.get_setting("display/window/size/viewport_height")
	image.resize(base_width, base_height, Image.INTERPOLATE_NEAREST)
	return ImageTexture.create_from_image(image)

func _capture_temp_viewport() -> ImageTexture:
	var image: Image = temp_viewport.get_texture().get_image()
	var base_width: float = ProjectSettings.get_setting("display/window/size/viewport_width")
	var base_height: float = ProjectSettings.get_setting("display/window/size/viewport_height")
	image.resize(base_width, base_height, Image.INTERPOLATE_NEAREST)
	return ImageTexture.create_from_image(image)

func _is_slide_transition(animation_out: String) -> bool:
	return ["slide_up", "slide_down", "slide_left", "slide_right"].has(animation_out)
