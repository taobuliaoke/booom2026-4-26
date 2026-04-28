extends Node
signal word_collected(word_text)


var collected_words = [] # 存储所有已获得的词条名

func add_word(word):
	if not collected_words.has(word):
		collected_words.append(word)
		emit_signal("word_collected", word) # 只有新词才发信号词才发送信号
