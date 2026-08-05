extends Node
class_name JumpComponent2D

enum AirState { GROUNDED, RISING, HANGING, FALLING }
var _air_state: AirState = AirState.GROUNDED:
	set(value):
		if _air_state == value or value is not AirState:
			return
		_air_state = value
		state_changed.emit(_air_state)

signal state_changed(new_state: AirState)
signal jump_begun(is_airjump: bool)
signal hang_time_begun()
signal fall_begun()
signal land()

@export_category("Jump Physics")
## Upward velocity applied on jump ("Jump Strength").
@export var jump_velocity: float = 30.0
## Gravity applied on the rising arc of the jump.
@export var rising_gravity: float = 20.0
## Amount to multiply to gravity when jump button is released early.
@export var short_hop_gravity_multiplier: float = 2.0
## Velocity window to dampen gravity at the apex of the jump.
@export var apex_velocity_threshold: float = 0.05
## Amount to multiply to gravity by at the apex of the jump ("Floatiness").
@export var apex_gravity_multiplier: float = 0.5
## Gravity applied on the falling arc of the jump.
@export var falling_gravity: float = 40.0
## Time window (seconds) to jump after leaving a ledge.
@export var coyote_time: float = 0.03
## Time window (seconds) to queue a jump before landing.
@export var jump_buffer_time: float = 0.01
## Total number of jumps allowed before landing.
@export var max_jumps: int = 1

var character_body: CharacterBody2D
var _jumps_remaining: int = 0
var _coyote_timer: float = 0.0
var _buffer_timer: float = 0.0
var _is_jump_held: bool = false

func _ready() -> void:
	character_body = get_parent() as CharacterBody2D
	if !character_body:
		push_warning("JumpComponent2D must be a direct child of a CharacterBody2D, deleting.")
		queue_free()

func _physics_process(delta: float) -> void:
	_update_timers(delta)
	_update_state()
	_apply_gravity(delta)
	if _buffer_timer > 0.0 and can_jump():
		_jump()

## Execute this function when the jump button is pressed.
func input_jump_pressed() -> void:
	_is_jump_held = true
	_buffer_timer = jump_buffer_time
	if can_jump():
		_jump()

## Execute this function when the jump input is released.
func input_jump_released() -> void:
	_is_jump_held = false

func get_air_state() -> AirState:
	return _air_state

func is_grounded() -> bool:
	return character_body.is_on_floor() or _coyote_timer > 0.0

func can_jump() -> bool:
	return is_grounded() or _jumps_remaining > 0

func reset_jumps() -> void:
	_jumps_remaining = max_jumps

func _jump() -> void:
	if !can_jump():
		return
	jump_begun.emit(!is_grounded())
	character_body.velocity.y = -jump_velocity
	_jumps_remaining -= 1
	_coyote_timer = 0.0
	_buffer_timer = 0.0

func _apply_gravity(delta: float) -> void:
	if character_body.is_on_floor():
		return
	var gravity: float = rising_gravity
	match _air_state:
		AirState.RISING:
			if !_is_jump_held:
				gravity *= short_hop_gravity_multiplier
		AirState.HANGING:
			gravity = rising_gravity * apex_gravity_multiplier
		AirState.FALLING:
			gravity = falling_gravity
	character_body.velocity.y += gravity * delta

func _update_timers(delta: float) -> void:
	if character_body.is_on_floor():
		_coyote_timer = coyote_time
		reset_jumps()
	else:
		_coyote_timer = max(0.0, _coyote_timer - delta)
	_buffer_timer = max(0.0, _buffer_timer - delta)

func _update_state() -> void:
	var velocity_y: float = character_body.velocity.y
	if character_body.is_on_floor():
		if _air_state == AirState.GROUNDED:
			return
		_air_state = AirState.GROUNDED
		land.emit()
	else:
		if _coyote_timer == 0.0 and _jumps_remaining == max_jumps: #eat first jump if coyote time out
			_jumps_remaining = max(0, _jumps_remaining - 1)
		if velocity_y < -apex_velocity_threshold:
			_air_state = AirState.RISING
		elif velocity_y > apex_velocity_threshold:
			if _air_state == AirState.FALLING:
				return
			_air_state = AirState.FALLING
			fall_begun.emit()
		else:
			if _air_state == AirState.HANGING:
				return
			_air_state = AirState.HANGING
			hang_time_begun.emit()
