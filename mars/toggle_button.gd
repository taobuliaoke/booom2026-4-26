extends Node2D

@onready var reasoning_page = $UILayer/ReasoningPage

func _on_toggle_button_pressed():
	# 切换显示或隐藏（取反逻辑）
	reasoning_page.visible = !reasoning_page.visible
	
	# 细节处理：打开推理页时，可以改变按钮文字
	if reasoning_page.visible:
		$UILayer/ToggleButton.text = "返回现场"
	else:
		$UILayer/ToggleButton.text = "查看推理"
