extends TextureButton
func _ready() -> void:
	self_modulate.a=0
	$AnimatedSprite2D.play("idle")
func _on_pressed():
	if GameEvents.is_in_dialogue:return
	$AnimatedSprite2D.play("pressed")
	await $AnimatedSprite2D.animation_finished
	$AnimatedSprite2D.play("idle")
	print("按钮被点击了，当前对话状态",GameEvents.is_in_dialogue)
