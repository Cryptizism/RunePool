extends Node

class BufferedInput:
	var input: InputEvent
	var time: int
const _MAX_INPUTS: int = 10
var _input_buffer: Array[BufferedInput] = []
