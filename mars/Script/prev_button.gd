extends TextureButton

@export var kiss2_se :AudioStream

func _ready() -> void:
	self_modulate.a=0
	$AnimatedSprite2D.play("idle")
	
func _on_pressed():
	MusicManager.play_se(kiss2_se, 4.0) # 稍微清脆、带有一点解开谜题成就感的铃声或正向音效
	if GameEvents.is_in_dialogue:return
	$AnimatedSprite2D.play("pressed")
	await $AnimatedSprite2D.animation_finished
	$AnimatedSprite2D.play("idle")
	print('成功发出切换信号')
