extends Control


@export var title_bgm: AudioStream
@export var click_se: AudioStream 
@export var hover_se: AudioStream
@onready var active_anim =$HoverDisplay/ChoiceAnimation
@onready var select_ui = $HoverDisplay/Select
var current_static_frame: Node2D = null

func _ready():
	#音乐播放启动
	if title_bgm:
		MusicManager.play_with_fade_in(title_bgm,0)
		
	active_anim.hide()
	# 停止在第一帧
	active_anim.stop() 
	
	for btn in get_tree().get_nodes_in_group("menu_buttons"):
		#鼠标移入，执行原有逻辑+变调
		btn.mouse_entered.connect(_on_button_hovered.bind(btn))
		#鼠标移出，慢慢恢复原调
		btn.mouse_exited.connect(_on_button_unhovered)
		#点击，如果点击后要跳转，可以直接在这里处理变调或者淡出
		btn.pressed.connect(_on_button_clicked)
		

func _on_button_hovered(btn: TextureButton):
	_restore_all_static_frames()
	current_static_frame = btn.get_parent().get_node("StaticFrame")

	active_anim.global_position = current_static_frame.global_position

	current_static_frame.modulate.a = 0.0 # 隐藏底图，防止重叠闪烁
	active_anim.show()
	active_anim.frame = 0 # 从第一帧开始
	active_anim.play("select_effect")
	

	var btn_center_x = btn.global_position.x + (btn.size.x / 2)
	select_ui.global_position = Vector2(btn_center_x,450)
	
	#播放切换音效
	if hover_se:
		MusicManager.play_se(hover_se, -5.0)

	#music音调变低
	MusicManager.smooth_pitch(0.7,0.8)
	
	
func _on_button_unhovered():
	#慢慢恢复到音调1.0
	MusicManager.smooth_pitch(1.0,0.5)
	

func _on_button_clicked():
	#播放音效
	if click_se:
		MusicManager.play_se(click_se)
	MusicManager.smooth_pitch(1.2,0.2)

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
	MusicManager.fade_out_and_stop(1.0)
	$CanvasLayer/AnimationPlayer.play("fade_out")
	await$CanvasLayer/AnimationPlayer.animation_finished
	get_tree().change_scene_to_file("res://Scenes/Level/prologue.tscn")
