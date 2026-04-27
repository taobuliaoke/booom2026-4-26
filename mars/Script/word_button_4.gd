extends Button

func _ready():
	pressed.connect(_on_pressed)

func _on_pressed():
	GameManager.current_grabbed_word = text # 直接改全局变量
	print("抓取了：", text)
