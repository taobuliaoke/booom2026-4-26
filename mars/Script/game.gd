extends Node2D

# 记录玩家当前点中的词
var current_grabbed_word: String = ""

#func _ready():
	## 遍历场景里所有的词条按钮，把它们的信号连到这里
	#for child in get_children():
		#if child is Button:
			#child.word_clicked.connect(_on_word_captured)

func _on_word_captured(word):
	# 玩家点了一个词，我们把它存起来
	current_grabbed_word = word
	print("现在手里拿着词: ", word)
"res://Scenes/word_button_2.gd"
"res://Scenes/word_button_3.gd"
"res://Scenes/word_button_4.gd"
