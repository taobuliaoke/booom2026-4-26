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

# --- 核心位置管理逻辑 ---
func handle_word_move(word_text: String, _from_node: Node, to_node: Node):
	to_node.label.text = word_text
	to_node.get_node("NinePatchRect").modulate = Color(0.95, 0.859, 0.629, 1.0) # 发光效果
	
	var tween = create_tween()
	tween.tween_property(to_node, "scale", Vector2(1.1, 1.1), 0.1)
	tween.chain().tween_property(to_node, "scale", Vector2(1.0, 1.0), 0.1)
	
	# 触发检查
	to_node.slot_changed.emit()
	
func _check_all_slots():
	var empty_count = 0
	var wrong_count = 0
	var used_for_multi_choice = [] # 记录已被填过的正确答案
	
	# 遍历所有槽位，同时统计空格和错误
	for slot in all_slots:
		print('slot:', slot.name, '填入:', slot.label.text, '正确答案库:', slot.correct_answer)
		
		if not slot.is_filled():
			empty_count += 1
		else:
			var current_text = slot.label.text
			var is_correct = false
			
			# A. 多选题判定
			if slot.correct_answer.size() > 1:
				if current_text in slot.correct_answer and not current_text in used_for_multi_choice:
					is_correct = true
					used_for_multi_choice.append(current_text)
				else:
					is_correct = false
			# B. 单选题判定
			else:
				if current_text in slot.correct_answer:
					is_correct = true
				else:
					is_correct = false
					
			if not is_correct:
				print("判定失败的槽位: ", slot.name, " 填入值: ", current_text)
				wrong_count += 1
			
	# 反馈结果
	if empty_count == 0 and wrong_count == 0:
		_on_all_crrect()
	else:
		_on_some_wrong_custom(empty_count, wrong_count)
		
func _on_all_crrect():
	if page_correct_se:
		MusicManager.play_se(page_correct_se, 4.0)
	print('完全正确，事情是这样的：')
	_show_feedback("推理完全正确！")
	_display_truth_state()
	var parent_node = get_parent()
	if parent_node and parent_node.has_method('check_global_victory'):
		parent_node.check_global_victory()
	else:
		if owner and owner.has_method('check_global_victory'):
			owner.check_global_victory()

# 自定义实时反馈文本逻辑
func _on_some_wrong_custom(empty_count: int, wrong_count: int):
	var msg = ""
	if empty_count > 0:
		msg += "还有 " + str(empty_count) + " 个空格未填。 "
	if wrong_count > 0:
		msg += "仍有 " + str(wrong_count) + " 处疑点..."
		
	print(msg)
	_show_feedback(msg)

func _show_feedback(msg: String):
	if feedback_label:
		feedback_label.text = msg
	if feedback_panel:
		feedback_panel.show() 

func _display_truth_state():
	if E_slots_container: E_slots_container.hide()
	if Words_Label: Words_Label.hide()
	if Trues_label: Trues_label.show()
