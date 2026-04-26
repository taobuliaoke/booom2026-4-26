extends Label

@export var correct_answer: String = "周某"
var current_text: String = ""

func _gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var grabbed_word = get_node("/root/Game").current_grabbed_word
		if grabbed_word != "":
			text = grabbed_word
			current_text = grabbed_word
