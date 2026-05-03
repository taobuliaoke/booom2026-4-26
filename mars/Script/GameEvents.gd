extends Node
signal word_collected(word_text)
signal request_next_view
signal request_prev_view
signal show_tooltip(text) # 定义显示信号，带一个文字参数
signal hide_tooltip       # 定义隐藏信号
signal request_character_dialog(char_name: String)
signal global_clicked(event:InputEventMouseButton) #检查鼠标点击
signal request_item_detail(content)

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

func collect_clue(word_name:String):
	if not clues_registry.has(word_name) or clues_registry[word_name] == false:
		clues_registry[word_name] = true
		return true#成功收集
	return false #表示之前已经拿过了

func add_word(word):
	if not collected_words.has(word):
		collected_words.append(word)
		emit_signal("word_collected", word) # 只有新词才发信号词



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
