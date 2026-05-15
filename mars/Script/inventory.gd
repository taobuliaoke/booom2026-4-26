extends HFlowContainer

@export var get_slot_se:AudioStream

var word_card_scene = preload("res://Scenes/word_card.tscn")

func _ready():
	# 听 GameEvents 的信号，只要有新词，就执行 add_new_card_ui
	GameEvents.clue_collected.connect(add_new_card_ui)

func add_new_card_ui(word_name):
	MusicManager.play_se(get_slot_se, 1.0) # 类似“啪嗒”一声的木质或纸张卡入声
	var new_card = word_card_scene.instantiate()
	new_card.set_word(word_name) # 或者你给 Label 赋值的逻辑
	add_child(new_card)
