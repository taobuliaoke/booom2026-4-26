extends Control

# 获取节点引用
@onready var reasoning_manager = $ReasoningManager
@onready var slot_1 = $ReasoningManager/Slot1    
@onready var slot_2 = $ReasoningManager/Slot2    # 对应“赵四被___杀了”
# 修正路径：HBoxContainer 是 ReasoningManager 的直接子节点，不再属于 GuideLabel
@onready var words_container = $ReasoningManager/HBoxContainer
# 修正路径：首字母大写匹配 tscn 中的 Trues
@onready var trues_label = $ReasoningManager/Trues

# 词条预制体
var word_card_scene = preload("res://Scenes/word_card.tscn")

func _ready() -> void:
	modulate.a = 0.0
	var fade_tween = create_tween()
	fade_tween.tween_property(self,'modulate:a',1.0,1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	# 安全检查，防止路径再次写错导致后续代码不执行
	if not slot_1 or not slot_2:
		printerr("错误：无法在场景中找到对应的 Slot 节点，请检查路径！")
		return

	# ==========================================
	# 1. 修复 Manager 注册 (手动把槽位塞给 Manager)
	# ==========================================
	reasoning_manager.all_slots.clear()
	var slots = [slot_1, slot_2]
	for s in slots:
		reasoning_manager.all_slots.append(s)
		# 手动连接信号，让 Manager 能够监听到拖拽变化
		if not s.slot_changed.is_connected(reasoning_manager._check_all_slots):
			s.slot_changed.connect(reasoning_manager._check_all_slots)
	
	# 初始化真相文本
	if trues_label:
		trues_label.text = ""
		trues_label.hide()

	# ==========================================
	# 2. 核心教学配置：设置谜题与正确答案
	# ==========================================
	slot_1.correct_answer.assign(["凶手"])
	slot_2.correct_answer.assign(["张三", "利刃"]) 
	
	# ==========================================
	# 3. 核心教学配置：预填错误选项引导“右键清空”
	# ==========================================
	slot_1.label.text = "利刃" 
	slot_2.label.text = '凶手'
	
	# 模拟已经填入的高亮状态
	slot_1.get_node("NinePatchRect").modulate = Color(0.95, 0.859, 0.629, 1.0) 
	slot_2.get_node("NinePatchRect").modulate = Color(0.95, 0.859, 0.629, 1.0) 
	
	# ==========================================
	# 4. 生成可拖拽的词条备选库 (现在前面的代码不报错，这里能正常执行了)
	# ==========================================
	var available_words = ["凶手", "张三", "利刃", "赵四"]
	for word in available_words:
		create_word_card(word)

	# ==========================================
	# 5. 初始主动刷新反馈面板
	# ==========================================
	# 进游戏时立刻计算一次，由于此时填了“利刃”和“凶手”，会正确触发显示“仍有 2 处疑点...”
	reasoning_manager._check_all_slots()


# 生成词条卡片的辅助函数 (已修复高度拉伸与文本无法更新问题)
func create_word_card(text: String) -> void:
	if word_card_scene:
		var card = word_card_scene.instantiate()
		
		# ----------------------------------------------------
		# 解决方案1：防止垂直高度拉伸
		# ----------------------------------------------------
		# 将垂直尺寸标志(Vertical Size Flags)设为居中对齐(SIZE_SHRINK_CENTER = 4)
		# 这样 HBoxContainer 就不会强制把卡片拉高，而是让其保持自身预设高度垂直居中
		if "size_flags_vertical" in card:
			card.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		
		words_container.add_child(card)
		
		# ----------------------------------------------------
		# 解决方案2：穿透任意UI层级定位 Label 并正确改写文字
		# ----------------------------------------------------
		if card.has_method("set_text"):
			card.set_text(text)
		else:
			# 使用 find_child 递归深层寻找名字包含 Label 的控件（不区分大小写）
			var label_node = card.find_child("*Label*", true, false)
			if label_node and "text" in label_node:
				label_node.text = text
			else:
				# 备用方案：如果上面没找到，遍历所有子节点检查是否有文本属性的控件
				for child in card.get_children():
					if "text" in child:
						child.text = text
						break


# ==========================================
# 6. 通关回调 (Manager 全部判定正确后会调用)
# ==========================================
func check_global_victory() -> void:
	print("新手教程完成！恭喜通关！")
	get_tree().change_scene_to_file("res://Scenes/title_screen.tscn")
