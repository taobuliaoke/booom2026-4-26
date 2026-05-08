extends TextureButton
func _ready() -> void:
	self_modulate.a=0
	$AnimatedSprite2D.play("idle")
func _on_pressed():
	$AnimatedSprite2D.play("pressed")
	await $AnimatedSprite2D.animation_finished
	$AnimatedSprite2D.play("idle")
	print("按钮被点击了，当前对话状态",GameEvents.is_in_dialogue)
	# 如果正在对话中，直接拦截，不执行任何操作[cite: 18, 19]

	print('成功发出切换信号')
	GameEvents.emit_signal("request_next_view")
