extends Area2D
@export var prologue:Control

func _ready():
	
	pass

# event 是输入的具体内容（移动、点击、滚轮等）
# shape_idx 如果你有多个碰撞形状，可以用它区分点到了哪个
func _input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_on_clicked()

func _on_clicked():
	prologue.item_clicked.emit()
	get_viewport().set_input_as_handled()
