extends TextureButton
func _on_pressed():
	print('成功发出切换信号')
	GameEvents.emit_signal("request_next_view")
