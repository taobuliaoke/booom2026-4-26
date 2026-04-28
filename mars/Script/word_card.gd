extends MarginContainer

# 获取底下的 Label 和底框节点
@onready var label = $Label
@onready var bg_texture = $NinePatchRect

func set_word(text: String):
	label.text = text
	# 让底框的大小跟随外层容器（即文字的长短）
	# 注意：这里我们依靠 MarginContainer 的自动布局

#鼠标在此ui上按下并拖动时，Godot自动调用这个函数
func _get_drag_data(_at_position):
	#创建临时预览框，拖动时能看到东西
	var preview = self.duplicate()
	set_drag_preview(preview)
	
	#返回词条内容
	return label.text
