extends Control
@onready var page_container = self 

@export var page_correct_se: AudioStream
@onready var feedback_panel = $FeedBackPanel
@onready var feedback_label = $FeedBackPanel/Label
@onready var E_slots_container = $Emptys
@onready var Words_Label = $Words
@onready var Trues_label = $Trues
var all_slots = []



func _ready() :
	if E_slots_container:
		for child in E_slots_container.get_children():
			if child.has_method('is_correct'):
				all_slots.append(child)
				child.slot_changed.connect(Callable(self, "_check_all_slots"))


# --- 新增：核心位置管理逻辑 ---
func handle_word_move(word_text: String, _from_node: Node, to_node: Node):
	##遍历所有 slot，如果在其他地方已经有这个词了，就先清空它（实现唯一性）
	#for slot in all_slots:
		#if slot.label.text == word_text:
			#slot.clear_slot()
	
	#如果是从另一个 Slot 拖过来的，且目标位置已经有词了
	# 这里可以选择交换词语，或者简单地覆盖。
	to_node.label.text = word_text
	to_node.get_node("NinePatchRect").modulate = Color(0.767, 1.2, 0.567, 1.0) # 发光效果
	
	
	#播放动效
	var tween = create_tween()
	tween.tween_property(to_node, "scale", Vector2(1.1, 1.1), 0.1)
	tween.chain().tween_property(to_node, "scale", Vector2(1.0, 1.0), 0.1)
	
	
	#触发检查
	to_node.slot_changed.emit()
	
func _check_all_slots():
	for slot in all_slots:
		print('slot:',slot.name,'填入',slot.label.text,'正确答案库',slot.correct_answer)
		if !slot.is_filled():
			return #还有空的
	var wrong_count = 0
	#给多选题准备核对名单
	var used_for_multi_choice = [] #记录已被填过的正确答案
	
	for slot in all_slots:
		var current_text = slot.label.text
		var is_correct = false
		#判定：
		#A.如果是“火星/荧惑”这类有多个选项且不能重复的题（数组长度>1）
		if slot.correct_answer.size() >1:
			if current_text in slot.correct_answer and not current_text in used_for_multi_choice:
				is_correct = true
				used_for_multi_choice.append(current_text)
			else:
				is_correct = false
				print('当前答案错误')
		#B.是单选题的哟
		else:
			if current_text in slot.correct_answer:
				is_correct = true
			else:
				is_correct = false
				print('当前答案错误')
				
			
		if not is_correct:
			print("判定失败的槽位: ", slot.name, " 填入值: ", current_text)
			wrong_count += 1
			
			
	#反馈结果
	if wrong_count == 0:
		_on_all_crrect()
	else:
		_on_some_wrong(wrong_count)
		
func _on_all_crrect():
	MusicManager.play_se(page_correct_se, 4.0) # 稍微清脆、带有一点解开谜题成就感的铃声或正向音效
	print('完全正确，事情是这样的：')
	_show_feedback("推理完全正确！")
	_display_truth_state()
	var parent_node = get_parent()
	if parent_node and parent_node.has_method('check_global_victory'):
		parent_node.check_global_victory()
	else:
		if owner and owner.has_method('check_global_victory'):
			owner.check_global_victory()


func _on_some_wrong(count:int):
	print('还没有搞清楚发生了什么，还有'+str(count)+'个错误。')
	_show_feedback("仍有 " + str(count) + " 处疑点...")
	#播放错误提示音效
	
func _show_feedback(msg: String):
	if feedback_label:
		feedback_label.text = msg
	
	if feedback_panel:
		feedback_panel.show() #确保面板一直可见
	
	## 如果你希望它几秒后自动消失，可以使用 Tween 或 Timer
	#var tween = create_tween()
	#tween.tween_interval(2.0) # 显示2秒
	#tween.tween_callback(feedback_panel.hide)

func _display_truth_state():
	#隐藏所有emptys节点和words节点
	if E_slots_container:
		E_slots_container.hide()
		Words_Label.hide()
	#显示真相
	Trues_label.show()
