extends Control
class_name LobbyEntry

const DISABLED_COLOR: Color = Color(0.2, 0.2, 0.2, 1.0)

@onready var label_name: Label = $HBoxContainer/LabelName
@onready var label_members: Label = $HBoxContainer/LabelMembers

var lobby_data: NetworkManager.LobbyData

func _ready() -> void:
	_set_lobby_data()

func _set_lobby_data() -> void:
	if !lobby_data:
		queue_free()
		return
	var members: int = lobby_data.members
	var max_members: int = lobby_data.max_members
	label_name.text = lobby_data.name
	label_members.text = str(members) + "/" + str(max_members)
	if members >= max_members:
		label_name.modulate = DISABLED_COLOR
		label_members.modulate = DISABLED_COLOR

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_join_lobby()

func _join_lobby() -> void:
	NetworkManager.join_lobby(lobby_data.lobby_id)
