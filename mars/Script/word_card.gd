extends MarginContainer

# 获取底下的 Label 和底框节点
@onready var label = $MarginContainer/Label
@onready var bg_texture = $NinePatchRect
var drag_tween: Tween


func set_word(text: String):
	#初始化好了没
	if label != null:
		label.text = text
	else:
		#手抓饼
		var manual_label = get_node_or_null("MarginContainer/Label")
		if manual_label:
			manual_label.text = text
		else:
			#不准给我打印错误，揍你死
			print('wrong')

	# 让底框的大小跟随外层容器（即文字的长短）
	# 注意：这里我们依靠 MarginContainer 的自动布局

#鼠标在此ui上按下并拖动时，Godot自动调用这个函数
# 1. 处理拖拽开始
func _get_drag_data(_at_position):
	var preview = self.duplicate()
	set_drag_preview(preview)
	
	# 如果之前有动画在跑，先杀掉它防止叠加
	if drag_tween:
		drag_tween.kill()
	
	# 创建循环变色动画
	drag_tween = create_tween().set_loops()
	drag_tween.tween_property(bg_texture, "modulate", Color.BLUE, 1)
	drag_tween.tween_property(bg_texture, "modulate", Color.DARK_ORANGE, 1)
	
	return label.text

# 2. 【新增】处理拖拽结束（无论成功还是失败）
func _notification(what):
	if what == NOTIFICATION_DRAG_END:
		# 如果动画正在运行，停止它
		if drag_tween:
			drag_tween.kill()
		
		# 恢复原始颜色（白色）
		var reset_tween = create_tween()
		reset_tween.tween_property(bg_texture, "modulate", Color.WHITE, 0.2)
