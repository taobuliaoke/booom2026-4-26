extends MarginContainer

signal slot_changed
@onready var label = $Label
# 有多个正确答案的情况
@export var correct_answer:Array[String] = []


#检查是否是正确答案
func is_correct() -> bool:
	return label.text in correct_answer
	
	

func is_filled() -> bool:
	return label.text != ""


# 当玩家拖着东西经过时接不接受？
func _can_drop_data(_at_position, data):
	# 只要拖过来的数据是string，我就接受
	return typeof(data) == TYPE_STRING


#当玩家松开鼠标，把东西扔进这里时，执行什么？
func _drop_data(_at_position, data):
	# 将空格的文字改为拖过来的词条内容
	label.text = data
	#通知manager，slot被填了
	slot_changed.emit()
	# 可以在这里改变底框颜色，比如变亮，表示已填充
	$NinePatchRect.modulate = Color.WHITE
