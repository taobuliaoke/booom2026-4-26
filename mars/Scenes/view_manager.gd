extends Node
@export var cameras:Array[Node3D]
var current_index = 0

func apply_view(index):
	var count = cameras.size()
	
	current_index = (index + count) % count
	
	for i in count:
		cameras[i].current = (i == current_index)

func _on_texture_buttonleft_pressed() -> void:
	apply_view(current_index - 1)


func _on_texture_buttonright_pressed() -> void:
	apply_view(current_index + 1)
