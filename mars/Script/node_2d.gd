extends Area2D
# 在编辑器右侧可以手动填入这个物品代表的单词
@export var word_to_give: String = "未命名词条"

func _input_event(_viewport, event, _shape_idx):
	# 检测鼠标左键点击
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		collect_word()

func collect_word():
	print("你发现了词条: ", word_to_give)
	GameEvents.emit_signal("word_collected", word_to_give)
