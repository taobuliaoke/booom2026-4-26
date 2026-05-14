extends Control

@onready var active_anim =$HoverDisplay/ChoiceAnimation
@onready var select_ui = $HoverDisplay/Select
var current_static_frame: Node2D = null

func _ready():
	
	active_anim.hide()
	# 停止在第一帧
	active_anim.stop() 
	
	for btn in get_tree().get_nodes_in_group("menu_buttons"):
		btn.mouse_entered.connect(_on_button_hovered.bind(btn))

func _on_button_hovered(btn: TextureButton):
	_restore_all_static_frames()
	current_static_frame = btn.get_parent().get_node("StaticFrame")

	active_anim.global_position = current_static_frame.global_position

	current_static_frame.modulate.a = 0.0 # 隐藏底图，防止重叠闪烁
	active_anim.show()
	active_anim.frame = 0 # 从第一帧开始
	active_anim.play("select_effect")
	

	var btn_center_x = btn.global_position.x + (btn.size.x / 2)

	var fixed_y_position = 450

	var target_pos = Vector2(btn_center_x, fixed_y_position)
	select_ui.global_position = target_pos

# 记得连接 AnimatedSprite2D 的信号
func _on_choice_animation_finished():
	active_anim.hide()
	# 动画播完后，让所有底图重新显现（或者只显现当前选中的，看你美术需求）
	current_static_frame.modulate.a = 1.0 

# 辅助函数：保险起见，清空状态时调用
func _restore_all_static_frames():
	for frame in get_tree().get_nodes_in_group("static_frames"):
		frame.modulate.a = 1.0


func _on_start_button_pressed() -> void:
	$CanvasLayer/AnimationPlayer.play("fade_out")
	await$CanvasLayer/AnimationPlayer.animation_finished
	get_tree().change_scene_to_file("res://Scenes/Level/prologue.tscn")
