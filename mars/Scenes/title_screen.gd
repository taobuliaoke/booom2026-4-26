extends Control
@onready var settings_ui = $SettingsLayer
@onready var confirm_rect = $ExitConfirmLayer/ColorRect
@onready var confirm_panel = $ExitConfirmLayer/Panel
@export var title_bgm: AudioStream
@export var click_se: AudioStream 
@export var hover_se: AudioStream
@onready var active_anim =$HoverDisplay/ChoiceAnimation
@onready var select_ui = $HoverDisplay/Select
@onready var exit_confirm_layer = $ExitConfirmLayer
#--- 视差配置 ---
@onready var tree = $Background/Tree          # 第一层：最前面
@onready var bird =   $Background/Bird          # 第二层
@onready var bird_shadow = $Background/BirdShadow # 第三层：影子（我们要让它反向动）
@onready var background = $Background/Background # 第四层：底板
# 记录初始位置
var tree_base_pos: Vector2
var bird_base_pos: Vector2
var shadow_base_pos: Vector2

# 视差敏感度（数值越大动得越远）
var tree_factor = 0.01
var bird_factor = 0.005
var shadow_factor = -0.005 # 负数实现“伪装打光”的影子反向位移


var current_static_frame: Node2D = null

func _ready():
	#  记录初始位置 [cite: 11]
	tree_base_pos = tree.position
	bird_base_pos = bird.position
	shadow_base_pos = bird_shadow.position
	
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
		
func _process(delta):
	_handle_parallax(delta)

func _handle_parallax(delta):
	# 获取鼠标距离屏幕中心的偏移
	var center = get_viewport_rect().size / 2
	var mouse_pos = get_viewport().get_mouse_position()
	var offset = mouse_pos - center
	
	# 第一层：Tree (正向位移，最快)
	var tree_target = tree_base_pos + offset * tree_factor
	tree.position = tree.position.lerp(tree_target, delta * 5.0)
	
	# 第二层：Bird (正向位移，中速)
	var bird_target = bird_base_pos + offset * bird_factor
	bird.position = bird.position.lerp(bird_target, delta * 5.0)
	
	# 第三层：BirdShadow (反向位移 + 稍微拉伸)
	# 当鼠标（光）往右走，影子往左偏
	var shadow_target = shadow_base_pos + offset * shadow_factor
	bird_shadow.position = bird_shadow.position.lerp(shadow_target, delta * 5.0)
	
	# 可选：让影子随鼠标位置产生轻微倾斜，更有立体感
	bird_shadow.skew = lerp(bird_shadow.skew, (offset.x / center.x) * 0.05, delta * 5.0)
	
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

func _on_settings_button_pressed():
	if click_se:
		MusicManager.play_se(click_se)
	settings_ui.show_settings()
	
func _on_exit_button_pressed() -> void:
	if click_se:
		MusicManager.play_se(click_se)
	
	# 不直接退出，而是显示弹窗
	exit_confirm_layer.show()
	
	# 如果想更细腻点，可以给弹窗做一个简单的淡入
	var tween = create_tween()
	# 设置过渡曲线，让弹窗弹出感更丝滑（EASE_OUT 适合弹出）
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	
	# 动画逻辑：透明度从 0 到 1
	 # 假设你有个面板
	
	tween.tween_property(confirm_rect, "modulate:a", 1.0, 0.4).from(0.0)
# --- 2. 弹窗内的“确认退出”按钮 ---
func _on_confirm_exit_pressed() -> void:
	if click_se:
		MusicManager.play_se(click_se)
	# 播放你原有的淡出效果
	$CanvasLayer/AnimationPlayer.play("fade_out")
	await $CanvasLayer/AnimationPlayer.animation_finished
	
	get_tree().quit()

# --- 3. 弹窗内的“再留一会儿”按钮 ---
func _on_cancel_exit_pressed() -> void:
	if click_se:
		MusicManager.play_se(click_se)
	# 隐藏弹窗
	exit_confirm_layer.hide()
