extends Button

var word_name = "周某"
# 预加载我们刚才做好的卡片模板
var word_card_scene = preload("res://Scenes/word_card.tscn")

func _pressed():
	# 1. 实例化（克隆）一个卡片
	var new_card = word_card_scene.instantiate()
	
	# 2. 把单词传给卡片
	new_card.get_node("Label").text = word_name
	
	 # 3. 把卡片塞进底部的 Inventory 容器里
	$"../../UiLayer/Inventory".add_child(new_card)
	
	# 4. 防止重复点击获取同一个词（可选）
	disabled = true
