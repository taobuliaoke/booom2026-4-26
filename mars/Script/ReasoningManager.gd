extends Control

var all_slots = []


func _ready() :
	#自动收集所有slot
	for child in get_children():
		if child.has_method('is_correct'):
			all_slots.append(child)
			child.slot_changed.connect(Callable(self, "_check_all_slots"))


# --- 新增：核心位置管理逻辑 ---
func handle_word_move(word_text: String, from_node: Node, to_node: Node):
	#遍历所有 slot，如果在其他地方已经有这个词了，就先清空它（实现唯一性）
	for slot in all_slots:
		if slot.label.text == word_text:
			slot.clear_slot()
	
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
	var wrong_count = 0
	#填满没有
	for slot in all_slots:
		if !slot.is_filled():
			return #还有空的
	#如果全部填满了，就开始判定是不是都对了
		if  not slot.is_correct():
			wrong_count += 1
			
	if wrong_count == 0:
		_on_all_crrect()
	else:
		_on_some_wrong(wrong_count)

		
func _on_all_crrect():
	print('完全正确，事情是这样的：')
	#播放通关动画


func _on_some_wrong(count:int):
	print('还没有搞清楚发生了什么，还有'+str(count)+'个错误。')
	#播放错误提示音效



#func _on_verify_button_pressed():
	#
	## 自动获取目录下所有的 Slot 节点
	## 假设你的 Slot 都是 ReasoningPage 的子节点
	#for child in get_children():
		#if child.name.contains("Slot"):
			#all_slots.append(child)
	#
	#var correct_count = 0
	#for slot in all_slots:
		#if slot.is_correct():
			#correct_count += 1
	#
	## 判断结果
	#if correct_count == all_slots.size():
		#print("推理完全正确！你解开了谜案！")
		## 这里可以播放通关动画或跳转下一关
	#else:
		#print("推理还有错误，目前对了个数：", correct_count)
