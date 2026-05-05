extends TextureButton
func _on_pressed():
	# 只要对话框开着，这个按钮就根本不接收鼠标点击
	print("按钮被点击了，当前对话状态",GameEvents.is_in_dialogue)
	# 如果正在对话中，直接拦截，不执行任何操作[cite: 18, 19]

	print('成功发出切换信号')
	GameEvents.emit_signal("request_next_view")
