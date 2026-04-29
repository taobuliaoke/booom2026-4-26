extends Control

var all_slots = []


func _ready() :
	#自动收集所有slot
	for child in get_children():
		if child.has_method('is_correct'):
			all_slots.append(child)
			child.slot_changed.connect(Callable(self, "_check_all_slots"))

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
