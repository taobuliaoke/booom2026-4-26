extends TextureButton
func _ready() -> void:
	self_modulate.a=0
	$AnimatedSprite2D.play("idle")
	
func _on_pressed():
	if GameEvents.is_in_dialogue:return
	$AnimatedSprite2D.play("pressed")
	await $AnimatedSprite2D.animation_finished
	$AnimatedSprite2D.play("idle")
	print('成功发出切换信号')
