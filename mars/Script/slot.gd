extends MarginContainer

signal slot_changed
var word_card_scene = preload("res://Scenes/word_card.tscn")

@onready var label = $MarginContainer/Label
@onready var bg =$NinePatchRect
# 有多个正确答案的情况
@export var correct_answer:Array[String] = []


#检查是否是正确答案
func is_correct() -> bool:
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
	#if typeof(data) == TYPE_DICTIONARY and data.has("text"): return true
	return false


#允许从slot处拖拽
func _get_drag_data(_at_position):
	if label.text == '':
		return null
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
	var manager = get_parent()
	if manager.has_method('handle_word_move'):
		manager.handle_word_move(new_text, origin_node, self)
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
