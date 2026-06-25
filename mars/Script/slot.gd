extends MarginContainer

signal slot_changed
var word_card_scene = preload("res://Scenes/word_card.tscn")

@onready var label = $MarginContainer/Label
@onready var bg =$NinePatchRect
# 有多个正确答案的情况
@export var correct_answer:Array[String] = []
@export var place_slot_se:AudioStream
@export var drag_start_se:AudioStream
#检查是否是正确答案

# ==================== 新增功能：右键清空 ====================
func _gui_input(event: InputEvent) -> void:
	# 检查是否是鼠标按键事件，并且是按下状态（非释放）
	if event is InputEventMouseButton and event.pressed:
		# 检查是否是鼠标右键 (MOUSE_BUTTON_RIGHT)
		if event.button_index == MOUSE_BUTTON_RIGHT:
			# 如果当前 slot 里面有文本，才执行清空
			if is_filled():
				clear_slot()
				# 播放个清空的声音（如果需要，可以复用 drag_start_se 或不播）
				MusicManager.play_se(drag_start_se, -2.0)
				
				# 接收了该事件，防止它继续向上传递
				accept_event()
# ==========================================================


func is_correct() -> bool:
	if label.text == '' or label.text == "":
		return false
	
	return label.text in correct_answer
	
	
func is_filled() -> bool:
	return label.text != ""


#彻底重置Slot状态

func clear_slot():
	label.text = ''
	bg.modulate = Color(1, 1, 1, 1) # 恢复原色
	slot_changed.emit()


# 当玩家拖着东西经过时接不接受？
func _can_drop_data(_at_position, data):
	# 兼容Inventory传来的String和Slot传来的Dictionary
	if typeof(data) == TYPE_STRING: return true
	if typeof(data) == TYPE_DICTIONARY and data.has("text"): return true
	return false


#允许从slot处拖拽
func _get_drag_data(_at_position):
	if label.text == '':
		return null
		
	MusicManager.play_se(drag_start_se, -2.0)
	#中转
	var preview = GameEvents.get_drag_preview(label.text)
	
	#设置预览
	set_drag_preview(preview)
	
	#传递数据,保持字典结构并兼容manager
	return{'text':label.text,'origin_node':self}



#当玩家松开鼠标，把东西扔进这里时，执行什么？
func _drop_data(_at_position, data):
	var new_text = ''
	var origin_node = null
	
	if typeof(data) == TYPE_STRING:
		new_text = data
	else:
		new_text = data['text']
		origin_node = data['origin_node']
		
		
	#通知ReasoningManager处理排他性
	var manager = _get_page_manager(self)
	if manager and manager.has_method('handle_word_move'):
		manager.handle_word_move(new_text, origin_node, self)
	MusicManager.play_se(place_slot_se, 1.0) # 类似“啪嗒”一声的木质或纸张卡入声

func _get_page_manager(node):
	var p = node.get_parent()
	while p != null:
		if p.has_method('handle_word_move'):
			return p
		p = p.get_parent()
	return null
	
	# 将空格的文字改为拖过来的词条内容
	#label.text = data
	
	## 改变底框颜色
	#$NinePatchRect.modulate = Color(0.767, 1.2, 0.567, 1.0) # 略微过曝，看起来像发光
	#
	## 果冻
	#var tween = create_tween()
	#tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.1)
	#tween.chain().tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)
	#
	##通知manager，slot被填了
	#slot_changed.emit()
