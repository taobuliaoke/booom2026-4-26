extends Control

# --- 编辑器变量 ---
@export_file("*.json") var data_file_path: String = "res://Script/Resourse/prologue_data.json" 
@export var to_minigame_slide: int 
@export var special_slides: Array[Node2D] 
@export var slide_nodes: Array[Node2D] = [] 
@export var typing_speed: float = 0.05 
@export var prologue_bgm: AudioStream
# prologue.gd
@export var post_3d_bgm: AudioStream # 3D 场景结束后的新音乐
@export var eye_pupil_red:Sprite2D
@export var put_button:AudioStream
# --- 节点引用 ---

@onready var dialogue_label = $CanvasLayer/DialogueLabel # 请确保你的场景中有此路径的 Label 
@onready var eye_pupil =$SlidesContainer/AlienSlide/medium/Node2D/EyeAnchor/Pupil




# --- 运行状态 ---
var dialogue_data: Array = []
var final_slide: int 
var is_typing: bool = false
var current_dialogue_index: int = 0
var current_tween: Tween
var is_locked: bool = false # 终极输入锁
var is_animation = false

var eye_center_pos: Vector2
var max_follow_distance: float = 20 # 眼球移动的最大半径
var is_eye_active: bool = false
var is_post_bgm_finished:bool = false

signal item_clicked 

func _ready():
	#场景开始时候，自动播放序章背景音乐,淡入2s
	if prologue_bgm:
		MusicManager.play_with_fade_in(prologue_bgm,2.0)
		
	#防御性检查：确保inspector 已赋值
	eye_center_pos = eye_pupil.position
	if slide_nodes.is_empty():
		push_error('错误：slide_nodes 数组为空，请在inspector 中拖入了节点')
		return
	final_slide = slide_nodes.size() - 1 
	item_clicked.connect(_on_item_clicked) 
	
	# 加载 JSON 数据
	_load_dialogue_data()
	
	# 初始化显示状态
	$CanvasLayer/AnimationPlayer.play("fade_in") 
	for i in range(slide_nodes.size()):
		slide_nodes[i].visible = (i == GlobalData.current_page) 
	
	# 显示当前页的第一句对白
	_display_current_content()
func _process(_delta):
	if is_eye_active:
		_update_eye_follow()
		
func _update_eye_follow():
	# 1. 获取鼠标相对于眼球中心的位置
	print("眼动")
	var mouse_pos = eye_pupil.get_parent().get_local_mouse_position()
	var direction = (mouse_pos - eye_pupil.global_position).normalized()
	var distance = eye_pupil.global_position.distance_to(mouse_pos)
	
	# 2. 计算偏移量（距离越远偏移越多，但不能超过最大半径）
	var target_offset = direction * min(distance * 0.2, max_follow_distance)
	_update_eyelid_direction(target_offset)
	# 3. 平滑移动眼球（Lerp 让动作更柔和，符合生物感）
	eye_pupil.position = eye_pupil.position.lerp(eye_center_pos + target_offset, 0.1)

func _update_eyelid_direction(offset: Vector2):
	# 设定一个阈值，只有当眼珠动得足够远时才切换眼皮方向
	var threshold = 5.0 
	
	# 获取眼皮的 AnimatedSprite2D（假设叫 eye_skin）
	var eye_skin = $SlidesContainer/AlienSlide/medium/Node2D/Eye

	if offset.length() < threshold:
		eye_skin.play("center") # 默认居中状态
	else:
		# 简单的四方向判定，如果你画了八方向也可以细化
		if abs(offset.x) > abs(offset.y):
			if offset.x > 0:
				eye_skin.play("eye_skin_up")
			else:
				eye_skin.play("eye_skin_down")
		else:
			if offset.y > 0:
				eye_skin.play("eye_skin_down")
			else:
				eye_skin.play("eye_skin_up")
func _load_dialogue_data():
	if not FileAccess.file_exists(data_file_path):
		print("错误：找不到对白文件 ", data_file_path)
		return
	
	var file = FileAccess.open(data_file_path, FileAccess.READ)
	var json = JSON.new()
	var error = json.parse(file.get_as_text())
	if error == OK:
		dialogue_data = json.data["slides"]
	else:
		print("JSON 解析错误")

func _unhandled_input(event):
	
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT: 
		var current_node = slide_nodes[GlobalData.current_page]
		
		# 1. 如果正在播字，点击瞬间显示全
		if is_typing:
			_finish_typing_instantly()
			return
		if is_animation:
			return
		# 2. 检查这一页是否还有下一句对白
		var slide_info = dialogue_data[GlobalData.current_page]
		var dialogues = slide_info['dialogues']

		# 如果当前页有对话，且还没播完，则进入下一句
		if not dialogues.is_empty() and current_dialogue_index < dialogues.size() - 1:
			current_dialogue_index += 1
			_show_dialogue_step()
			return

		# 3. 如果对话播完了（或本来就没对话），检查是否是特殊交互页
		if current_node in special_slides or "Alien" in current_node.name: 
			print("对话已结束，请点击特定物品交互")
			return
		
		# 4. 执行翻页
		go_to_next_step()

func _display_current_content():
	#如果当前页是3d出来后的第一页
	if GlobalData.current_page == (to_minigame_slide + 1) and post_3d_bgm:
		is_post_bgm_finished = false
		MusicManager.play_once_then_callback(post_3d_bgm)
# 监听播放结束信号
		if not MusicManager.bgm_finished.is_connected(_on_post_bgm_ended):
			MusicManager.bgm_finished.connect(_on_post_bgm_ended)
	current_dialogue_index = 0
	_show_dialogue_step()
	
	
func _on_post_bgm_ended():
	is_post_bgm_finished = true
	is_locked = false
	print("[调试] 收到信号：音乐已播放完毕，is_post_bgm_finished 设为 true")

func _show_dialogue_step():
	if GlobalData.current_page < dialogue_data.size():
		var slide_info = dialogue_data[GlobalData.current_page]
		var dialogues = slide_info['dialogues']
		
		#新增判断：如果当前页面没有对话内容，结束播字
		if dialogues.is_empty():
			is_typing = false
			dialogue_label.text = ''#清空上一页残留文字
			print('当前页面没有对话数据，点击直接翻页')
			return
		#如果有对话数据
		if current_dialogue_index < dialogues.size():
			_start_typing(dialogues[current_dialogue_index])

func _start_typing(content: String):
	is_typing = true
	dialogue_label.text = content
	dialogue_label.visible_ratio = 0.0
	
	if current_tween: current_tween.kill()
	current_tween = create_tween()
	
	var duration = content.length() * typing_speed
	current_tween.tween_property(dialogue_label, "visible_ratio", 1.0, duration)
	current_tween.finished.connect(func(): is_typing = false)

func _finish_typing_instantly():
	if current_tween: current_tween.kill()
	dialogue_label.visible_ratio = 1.0
	is_typing = false

func go_to_next_step():
	if is_locked:
		print("!!! [调试] 点击被拦截：is_locked 当前为 true")
		return
	is_locked = true
	if GlobalData.current_page==2:
		is_eye_active = true
	print("!!! [调试] 开始执行跳转逻辑，当前页码:", GlobalData.current_page)
	
		#从3d出来之后播放新音乐
	if GlobalData.current_page == 5:
		#淡出动画
		set_process_unhandled_input(false)
		$CanvasLayer/AnimationPlayer.play('fade_out_long')
		await $CanvasLayer/AnimationPlayer.animation_finished
	
	#在黑屏下切换内容
		_change_slide_content()
	
		#播放淡入动画
		$CanvasLayer/AnimationPlayer.play('fade_in')
		_display_current_content()
		set_process_unhandled_input(true) 
		is_locked = false
		return
	if GlobalData.current_page == (to_minigame_slide + 1):
		if not is_post_bgm_finished:
			print('音乐尚未播放结束，暂时无法跳转')
			return #如果音乐没有播完，直接拦截点击
		var tween = create_tween()
		tween.tween_property($SlidesContainer/PanoramaSlide/Prologue6, "modulate:a", 1.0, 5)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)
		await tween.finished
		GlobalData.current_page =5
		is_locked = false
		return
	if GlobalData.current_page == to_minigame_slide: 
		print('正在跳转3d场景，锁定所有后续逻辑')
		#音乐戛然而止
		MusicManager.fade_out_and_stop(0)
		SceneChanger.change_scene("res://3D_Content/3Dgame.tscn") 
		GlobalData.current_page = to_minigame_slide + 1 
		return
	
	#第三种情况，正常翻页或结束
	if GlobalData.current_page >= final_slide: 
		SceneChanger.change_scene("res://Scenes/Level/MainScene.tscn") 
		return

	#淡出动画
	set_process_unhandled_input(false)
	$CanvasLayer/AnimationPlayer.play('fade_out')
	await $CanvasLayer/AnimationPlayer.animation_finished
	
	#在黑屏下切换内容
	_change_slide_content()
	
	#播放淡入动画
	$CanvasLayer/AnimationPlayer.play('fade_in')
	_display_current_content()
	

	set_process_unhandled_input(true) 
	is_locked = false

func _change_slide_content():
	var current_node = slide_nodes[GlobalData.current_page]
	if GlobalData.current_page < slide_nodes.size() - 1:
		slide_nodes[GlobalData.current_page].hide()
		GlobalData.current_page += 1
		slide_nodes[GlobalData.current_page].show()
		var particles = current_node.get_node_or_null("GPUParticles2D")
		if particles:
			particles.emitting = true # 开始发射
			particles.restart()       # 从头开始
	else:
		SceneChanger.change_scene("res://Scenes/MainScene.tscn")

func _on_item_clicked():
	# 只有在不播字，不切换场景时才响应
	if not is_typing and not is_locked:
		$SlidesContainer/AlienSlide/medium/Node2D/Eye.play("eye_white")
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)
		eye_pupil_red.visible = true
		MusicManager.play_se(put_button)
		var tween = create_tween()
		tween.tween_property(eye_pupil_red,"position:y",430.0,1)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)
		
		await tween.finished
		go_to_next_step()
		
		
