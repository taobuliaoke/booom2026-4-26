extends Area2D
@export var prologue:Control
@export var glass_anim:AnimatedSprite2D
@export var eye_anim:AnimatedSprite2D

@export var lidopen_se : AudioStream
@export var  eyeopen_se : AudioStream

func _ready():
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
# event 是输入的具体内容（移动、点击、滚轮等）
# shape_idx 如果你有多个碰撞形状，可以用它区分点到了哪个
func _input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if self.name == "Area2D2": prologue.item_clicked.emit()
			else:
				$CollisionShape2D.disabled = true
				MusicManager.play_se(lidopen_se, 4.0) 
				glass_anim.play("glass_open")
				prologue.is_animation = true
			
				await glass_anim.animation_finished
				prologue.is_eye_active = false
				$"../EyeAnchor/Pupil".hide()
				MusicManager.play_se(eyeopen_se, 4.0) 
				$"../Eye".play("eye")
				
				await eye_anim.animation_finished
				$"../Eye".play("eye_rolling")
				$"../EyeAnchor/Pupil".hide()
				$"../Area2D2/CollisionShape2D".disabled = false
				prologue.is_animation = false
				return


func _on_mouse_entered() -> void:
	
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)
	
func _on_mouse_exited():
	# 恢复默认光标
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
