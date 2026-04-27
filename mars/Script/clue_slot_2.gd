extends Label

@export var correct_answer: String = "周某"
var current_content: String = ""


func _ready():
	#鼠标检测
	mouse_filter = Control.MOUSE_FILTER_STOP
	text = '____'
	


# 这是 Godot 处理 UI 点击的核心函数
func _gui_input(event):
	# 只有当：玩家按下了鼠标（pressed） 并且 是左键（LEFT）时触发
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			handle_click()

func handle_click():
	# 逻辑分支 1：手里有词，想填进去
	if GameManager.current_grabbed_word != "":
		# 如果格子里原来就有词，我们先不管它，直接覆盖
		current_content = GameManager.current_grabbed_word
		text = current_content
		
		# 【关键】填入后，清空手里拿的词，让鼠标上的词消失
		GameManager.current_grabbed_word = ""
	
	# 逻辑分支 2：手里没词，但想把格子里已经填好的词拿回来
	elif current_content != "":
		# 把格子里的词重新交给鼠标
		GameManager.current_grabbed_word = current_content
		# 格子恢复原样
		current_content = ""
		text = "____"
