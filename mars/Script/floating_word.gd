extends Label

func _ready():
	# 初始状态隐藏
	hide()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	modulate = Color.AQUA

func _process(_delta):
	# 每一帧都检查 GameManager 里有没有词
	if GameManager.current_grabbed_word != "":
		show() # 显示
		text = GameManager.current_grabbed_word # 显示内容
		global_position = get_global_mouse_position() + Vector2(15, 15) # 跟随鼠标，稍微偏离一点点
	else:
		hide() # 手里没词就藏起来
