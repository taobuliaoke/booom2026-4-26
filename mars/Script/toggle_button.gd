extends TextureButton

@onready var pupil = $EyeWhite/Pupil
@onready var click_anim = $ClickAnim
@onready var environment =$"../../Environment" #拿来吧你
@onready var reasoning_group =$"../../ReasoningGroup"
@onready var dialogueUI = %CharacterDialogUI
@export var max_look_dist: float = 8.0 # 眼珠晃动最大半径
var is_animating: bool = false
var env_original_pos: Vector2
#预加载
var normal_img = preload("res://Art/UI/ToggleButton.png")
var pressed_img = preload("res://Art/UI/ToggleButton_open.png")




func _ready() -> void:
	#初始状态隐藏
	click_anim.hide()
	click_anim.animation_finished.connect(_on_anim_finished)
	
	if reasoning_group:
		reasoning_group.visible = false
	# 确保已经指定了 normal texture
	if texture_normal:
		await get_tree().process_frame
		texture_click_mask = create_bitmap_from_texture(texture_normal)
		self_modulate.a = 0
	#记录初始位置方便日后还原
	if environment:
		env_original_pos = environment.position
		
func _process(_delta):
	# 只要不在播放点击动画，眼珠就跟随鼠标
	if not is_animating:
		update_pupil_focus()
		
func update_pupil_focus():
	# 1. 获取鼠标在“眼白”坐标系下的位置
	# 这会自动处理缩放、旋转和眼白在屏幕上的偏移
	var local_mouse_pos = $EyeWhite.get_local_mouse_position()
	
	# 2. 计算方向（相对于眼白中心的向量）
	var direction = local_mouse_pos.normalized()
	
	# 3. 计算距离，并限制在眼白的半径内
	var dist = local_mouse_pos.length()
	
	# 假设眼白是 40x40，那么半径大约是 20
	# 我们限制眼珠最多移动 8 像素，防止贴边
	var move_amount = min(dist * 0.1, max_look_dist)
	
	# 4. 计算最终的目标位置
	# 因为 Pupil 是 EyeWhite 的子节点，(0,0) 就是中心
	var target_pos = direction * move_amount
	
	# 5. 平滑移动
	pupil.position = pupil.position.lerp(target_pos, 0.15)
	
func _pressed():
	if is_animating:return
	var is_to_reasoning = !reasoning_group.visible
	
	#连全局GameEvent，控制其他ui开关
	# 去推理界面的画，should_suppress = true: 切回场景为false
	GameEvents.request_ui_suppression.emit(is_to_reasoning)  

	

	
	#眼球
	click_anim.show()
	
	#reasoning_group.visible = is_to_reasoning
	print("pressed：",reasoning_group.visible)
	#修改按钮样式
	update_button_style(is_to_reasoning)
	is_animating = true
	#调用淡入淡出动画
	run_env_animation(is_to_reasoning)
	if is_to_reasoning:
		GameEvents.is_in_dialogue = false
		GameEvents.is_sub_ui_open = false
		click_anim.play("to_reasoning")
		$background.hide()
		$EyeWhite.hide()
	else:
		click_anim.play("to_environment")
		$background.hide()
	
	##执行场景平移补间动画
	#run_env_animation(reasoning_group.visible)
	#update_button_style(is_to_reasoning)
func update_button_style(is_reasoning: bool):
	# 这里根据状态修改你三层结构中任意一层的贴图
	if is_reasoning:
		$background.texture =  pressed_img
	else:
		$background.texture = normal_img

#动画整合
func run_env_animation(is_opening:bool):
	print("去填空：",is_opening)
	if not environment or not reasoning_group:
		#如果没有场景，立刻解锁，防止死锁
		is_animating = false
		return
	
	#创建tween
	var tween = create_tween()
	
	#设置environment平滑曲线
	tween.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	
	if  is_opening:
		#让大局逆转吧，开！
		reasoning_group.modulate.a = 0
		reasoning_group.visible = true
		GameEvents.is_sub_ui_open = true
		
		#environment+group魂兮归来
		var target_pos = env_original_pos - Vector2(0, get_viewport_rect().size.y)
		tween.parallel().tween_property(environment, 'position', target_pos, 0.5)
		tween.parallel().tween_property(reasoning_group, 'modulate:a', 1.0, 0.4)
		
	else:
		
		print("渐出")
		#关了，再见世界886
		#environment+group魂飞魄散
		tween.parallel().tween_property(environment, 'position', env_original_pos, 0.5)
		tween.parallel().tween_property(reasoning_group, 'modulate:a', 0.0, 0.3)
		
		#动画结束后把它们都杀掉，鼠标闪亮登场
		tween.chain().tween_callback(func():
			$EyeWhite.show()
			reasoning_group.visible = false
			GameEvents.is_sub_ui_open = false
			GameEvents.ui_closed_refresh_hover.emit()
			)
	#动画完全结束后解锁togglebutton
	tween.chain().tween_callback(func():
		is_animating = false
		print('动画完成，按钮解锁')
		)

func create_bitmap_from_texture(tex: Texture2D) -> BitMap:
	var bitmap = BitMap.new()
	# 根据纹理尺寸创建一个空的位图
	bitmap.create(tex.get_size())
	
	# 获取 Image 数据以便访问像素
	var img = tex.get_image()
	
	# 自动根据 Alpha 通道创建遮罩
	# 参数 0.5 是 alpha 阈值（0.0 到 1.0）
	# 只有 alpha 大于 0.5 的像素才会被视为“可点击”
	bitmap.create_from_image_alpha(img, 0.9)
	
	return bitmap

func _on_anim_finished():
	# 隐藏动画节点
	$background.show()
	click_anim.hide()
	# 重置到第一帧，防止下次显示时闪现最后一帧的残影
	click_anim.frame = 0 
	# 停止动画播放状态
	click_anim.stop()


func _on_mouse_entered() -> void:
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)
	


func _on_mouse_exited() -> void:
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	
