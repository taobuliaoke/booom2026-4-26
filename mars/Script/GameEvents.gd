extends Node
@warning_ignore("unused_signal")
signal show_tooltip(text) # 定义显示信号，带一个文字参数
@warning_ignore("unused_signal")
signal hide_tooltip       # 定义隐藏信号
@warning_ignore("unused_signal")
signal request_character_dialog(char_name: String)
signal global_clicked(event:InputEventMouseButton) #检查鼠标点击
@warning_ignore("unused_signal")
signal request_item_detail(info: Dictionary)
@warning_ignore("unused_signal")
signal request_letter_open(letter_node_name:String)#负责通知信件库，打开哪封信
@warning_ignore("unused_signal")
signal ui_closed_refresh_hover # 当 UI 关闭时提醒场景物体刷新状态
@warning_ignore("unused_signal")
signal request_next_view
@warning_ignore("unused_signal")
signal request_prev_view
signal clue_collected
signal request_ui_suppression(should_suppress: bool)

var is_sub_ui_open: bool = false
var is_in_dialogue = false
var collected_words = [] # 存储所有已获得的词条名
var word_card_scene = preload("res://Scenes/word_card.tscn")
var clues_registry = {}#用字典储存所有线索的收集状态，键是词条名，值是布尔值


func _input(event):
	#只要有鼠标按下
	if event is InputEventMouseButton and event.pressed:
		#发电报，通知UI面板，认领工作
		emit_signal('global_clicked',event)

func register_and_add_clue(word: String) -> bool:
	print("信号发射源头")
	# 1. 检查是否已经收集过
	if clues_registry.get(word, false):
		return false
		
	# 2. 写入注册表
	clues_registry[word] = true
	
	# 3. 加入列表（如果不在列表里）
	if not collected_words.has(word):
		collected_words.append(word)
	
	# 4. 只发射一个统一的信号，通知 UI 刷新
	clue_collected.emit(word) 
	
	return true

#皮肤中转
func get_drag_preview(word_text: String) -> Control:
	# 1. 实例化卡片[cite: 16]
	var preview = word_card_scene.instantiate()
	
	# 2. 赋值文字。注意：因为节点还没进入场景树，
	# 我们直接在实例化后的节点上调用 set_word[cite: 8, 23]
	if preview.has_method("set_word"):
		preview.set_word(word_text)
	else:
		# 备用方案：如果方法失效，直接找节点赋值[cite: 20, 21]
		var label_node = preview.find_child("Label", true, false)
		if label_node:
			label_node.text = word_text
			
	return preview
