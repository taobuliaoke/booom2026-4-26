extends TextureButton
func _ready() -> void:
	self_modulate.a=0
	$AnimatedSprite2D.play("idle")
	
func _on_pressed():
	$AnimatedSprite2D.play("pressed")
	await $AnimatedSprite2D.animation_finished
	$AnimatedSprite2D.play("idle")
	print('成功发出切换信号')
	GameEvents.emit_signal("request_next_view")
