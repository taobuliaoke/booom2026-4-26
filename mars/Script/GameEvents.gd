extends Node
signal word_collected(word_text)
signal show_tooltip(text)
signal hide_tooltip

var collected_words = [] # 存储所有已获得的词条名
var word_card_scene = preload("res://Scenes/word_card.tscn")

func add_word(word):
	if not collected_words.has(word):
		collected_words.append(word)
		emit_signal("word_collected", word) # 只有新词才发信号词才发送信号



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
