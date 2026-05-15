extends Control
@export var is_global_manager: bool = false # 在编辑器里，主 UI 设为 true，NPC 下的设为 false

@export var max_width: float = 500 # max width
@export var spacing:int = 10 #how far from dialogbox to item box

@onready var vbox = $VBoxContainer
@onready var dialog_label = $VBoxContainer/DialogBox/TextMargin/MyCustomLabel
@onready var item_box = $VBoxContainer/ItemBox
@onready var container = $VBoxContainer/ItemBox/HFlowContainer
@onready var word_container = $VBoxContainer/DialogBox/TextMargin/MyCustomLabel/WordContainer
var current_character_id: String = ""


func _ready():
	visible = false
	add_to_group("dialog_uis")
	# 确保节点存在再操作，防止崩溃
	if vbox and dialog_label:
		vbox.add_theme_constant_override('separation', spacing)
		dialog_label.custom_minimum_size.x = max_width
	else:
		print("错误：找不到 UI 节点，请检查场景树路径！")
	# 设置行间距为 10 像素
	dialog_label.add_theme_constant_override("line_separation", 5)
	
	GameEvents.request_ui_suppression.connect(_on_ui_suppression)
	print('对话框：信号连接成功')
	GameEvents.request_character_dialog.connect(_on_request_dialog)
	GameEvents.global_clicked.connect(_on_global_clicked)
	
	
func _on_ui_suppression(should_suppress: bool):
	if should_suppress:
		# 仅仅是隐藏视觉效果，不清除 current_character_id [cite: 4]
		visible = false
	#else:
		## 如果切回主场景，且之前确实有对话在进行，则恢复显示
		#if current_character_id != "":
			#visible = true

#处理对话框生成
func _on_request_dialog(cid:String,pos:Vector2):
	
	# 通知组内所有对话框立刻隐藏 (包括其他视角的对话框)
	get_tree().call_group("dialog_uis", "hide") 
	
	#---------------------设置对话框的初始参数-------------------
	$VBoxContainer.global_position = pos
	$VBoxContainer.modulate.a = 0.0
	$VBoxContainer.scale = Vector2(0.9,0.9)#微小的弹出感
	$VBoxContainer/ItemBox.modulate.a = 0.0
	$VBoxContainer/ItemBox.scale = Vector2(0.9,0.9)
	
	GameEvents.is_in_dialogue = true 
	show()
	
	# -----------------------出现动画-------------------------------
	var tween = create_tween().set_parallel(true) # 并行执行透明度和缩放
	tween.tween_property($VBoxContainer, "modulate:a", 1.0, 0.4).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property($VBoxContainer, "scale", Vector2.ONE, 0.4).set_ease(Tween.EASE_OUT)
	tween.tween_property($VBoxContainer/ItemBox, "modulate:a", 1.0, 0.4).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property($VBoxContainer/ItemBox, "scale", Vector2.ONE, 0.4).set_ease(Tween.EASE_OUT)
	
	
	#显示内容
	show_content(cid)

# 显示内容，id从charinteract传来
func show_content(id: String):
	current_character_id = id
	var data = GameData.character_data.get(id,{})
	GameEvents.is_in_dialogue = true
	#清空旧道具
	for child in container.get_children():
		child.queue_free()
	if data.is_empty():
		dialog_label.text = '……'
		item_box.hide()
	#----------------------------生成拾取词汇-------------------------------------
	#把源文本送去gamedata解析
	var raw_dialog = data.get('dialog','')
	var parsed_result = GameData.parse_pickable_text(raw_dialog)
		
	# 给 Label 显示没有花括号的干净文本
	dialog_label.text = parsed_result["formatted_text"]
	
	vbox.reset_size() 
	await get_tree().process_frame 
	
	generate_word_areas(parsed_result)
	
	#---------------------------处理道具栏显示------------------------------------
	var items_array = data.get('items',[])
	if items_array.is_empty():
		item_box.hide()
	else:
		for item_info in items_array:
			add_new_item(item_info)#逐个增加道具
		item_box.show()
		
	#刷新道具栏大小，这两行能保证道具框在文字变动后，立刻重新吸附到文字下方
	vbox.reset_size() 

#对话框idle
func _play_idle_animation():
	var tween = create_tween().set_loops() # 无限循环
	tween.tween_property($VBoxContainer/DialogBox/BG, "scale", Vector2(1.02, 1.02), 1.5)
	tween.tween_property($VBoxContainer/DialogBox/BG, "scale", Vector2(1.0, 1.0), 1.5)

# 点击外部收起逻辑 
func _on_global_clicked(event: InputEventMouseButton): 
	#只有在左键点击，且当前UI可见的时候才判断
	if event.button_index != MOUSE_BUTTON_LEFT or not event.pressed:
		return
	if GameEvents.is_sub_ui_open or not visible:
		return

	# 现在只需检测鼠标是否在 VBoxContainer 的范围内即可
	var rect = vbox.get_global_rect()
	if not rect.has_point(event.global_position):
		print("点到 UI 外面了，收起面板")
		await get_tree().process_frame
		hide_dialog()


#---------------------------------生成可拾取词----------------------------------------
#生成可拾取词area2D交互区域（主方法）
func generate_word_areas(parsed_result):
	for child in word_container.get_children():
		child.queue_free()
	
	# 关键：多等几帧，确保打包后的 RichTextLabel 完成布局计算
	await get_tree().process_frame
	await get_tree().process_frame
	
	var font = dialog_label.get_theme_font("normal_font")
	var font_size = dialog_label.get_theme_font_size("normal_font_size")
	if font_size == 0: font_size = 43
	
	# 获取行间距设定
	var line_sep = 5 

	for info in parsed_result["data"]:
		var start = info["index"]
		var length = info["length"]
		var word = info["word"]
		
		# 1. 确定行号
		var line_idx = dialog_label.get_character_line(start)
		
		# 2. 获取 Y 坐标 (使用官方 API：get_line_offset)
		# 这个 offset 是相对于 Label 顶部的，且包含了 line_separation 的逻辑
		var y_pos = dialog_label.get_line_offset(line_idx)
		
		# 3. 计算 X 坐标
		# 获取这一行的起始字符索引
		var line_range = dialog_label.get_line_range(line_idx)
		var line_start_idx = line_range.x
		
		# 计算从“行首”到“词首”的文本宽度作为偏移
		var text_before_word_in_line = parsed_result["text"].substr(line_start_idx, start - line_start_idx)
		var x_offset = font.get_string_size(text_before_word_in_line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		
		# 计算词条本身的宽度
		var word_w = font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		var rect_h = dialog_label.get_line_height(line_idx)
		
		# 4. 生成 Rect2
		var final_rect = Rect2(Vector2(x_offset, y_pos), Vector2(word_w, rect_h))
		
		if word_w > 0:
			print("DEBUG: [", word, "] 行:", line_idx, " Y轴:", y_pos, " X轴:", x_offset)
			_spawn_interactable(word, final_rect)


#生成interactable,重设碰撞箱大小
func _spawn_interactable(word: String, rect: Rect2):
	var new_area = preload("res://Scenes/Interactable.tscn").instantiate()
	word_container.add_child(new_area)
	new_area.word_name = word
	
	var col = new_area.get_node("CollisionShape2D")
	
	var shape = RectangleShape2D.new()
	shape.size = rect.size 
	col.shape = shape
	
	# 位置对齐（因为碰撞体的默认锚点是中心点）
	new_area.position = rect.position
	col.position = rect.size / 2 
	
	# 赋值
	
	new_area.word_name = word 
	new_area.z_index = 5

	if GameEvents.clues_registry.get(word, false):
			# 既然是新生成的且需要禁用，直接设为 true，不需要 deferred
			col.disabled = true


#----------------------以下是道具框相关逻辑----------------------------------------
# 道具栏添加角色物品
func add_new_item(info: Dictionary):
	var rect = TextureRect.new()
	_setup_item_appearance(rect, info)      # 设置外观
	_bind_item_signals(rect, info)          # 绑定交互
	_refresh_item_cursor(rect, info)        # 初始化状态
	container.add_child(rect)               # 放入容器

# 外观设置
func _setup_item_appearance(rect: TextureRect, info: Dictionary):
	rect.texture = load(info.get("path", ""))
	rect.custom_minimum_size = Vector2(100, 100)
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.mouse_filter = Control.MOUSE_FILTER_STOP

# 鼠标样式状态刷新
func _refresh_item_cursor(rect: TextureRect, info: Dictionary):
	var word = info.get("collectible_word", "")
	var can_interact = info.get("can_interact", false)
	# 判断是否还有未拿取的词条
	var has_pending_word = word != "" and not GameEvents.clues_registry.get(word, false)
	
	if has_pending_word or can_interact:
		rect.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	else:
		rect.mouse_default_cursor_shape = Control.CURSOR_ARROW

# 信号连接交互绑定
func _bind_item_signals(rect: TextureRect, info: Dictionary):
	var item_key = info.get("item_name", '未知物品')
	
	# 悬停反馈（展示描述）
	rect.mouse_entered.connect(func():
		var desc = GameData.item_descriptions.get(item_key, item_key)
		GameEvents.emit_signal("show_tooltip", desc)
	)
	rect.mouse_exited.connect(func():
		GameEvents.emit_signal("hide_tooltip")
	)

	# 点击反馈
	rect.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			# 处理拾取
			var word = info.get("collectible_word", "")
			if word != "" and not GameEvents.clues_registry.get(word, false):
				GameEvents.register_and_add_clue(word)
				get_tree().call_group("clue_items", "check_status")
				# 拾取后，再次调用刷新函数
				#await get_tree().process_frame
				#_refresh_item_cursor()
				# 如果该道具不能进次级界面，拾取完后立刻让小手消失变回箭头
				if not info.get("can_interact", false):
					Input.set_default_cursor_shape(Input.CURSOR_ARROW)
			
			# 处理详情页
			if info.get("can_interact", false):
				GameEvents.emit_signal("hide_tooltip")
			
				# 这里的info['letter_node_name'] 对应 json中定义的节点名字
				#并且，如果用了contente字段，取content
				var target_node = info.get("letter_node_name", info.get("content", ""))
			
				if target_node !='':
				#触发开信信号
					GameEvents.emit_signal("request_letter_open", target_node)
)
	
	#————————————整体hide————————————————
func hide_dialog():
	# 阶段 3：Tween 消失动画
	var tween = create_tween().set_parallel(true)
	tween.tween_property($VBoxContainer, "modulate:a", 0.0, 0.3).set_trans(Tween.TRANS_SINE)
	tween.tween_property($VBoxContainer/ItemBox, "modulate:a", 0.0, 0.3).set_trans(Tween.TRANS_SINE)
	tween.tween_property($VBoxContainer, "scale", Vector2(0.9, 0.9), 0.3)
	tween.tween_property($VBoxContainer/ItemBox, "scale", Vector2(0.9, 0.9), 0.3)
	
	# 等待动画结束
	await tween.finished
	
	hide()#  视觉上立刻消失
	
	# 我们在这里“等一帧”，确保当前的点击信号（比如按钮的 pressed 信号）
	# 在 is_in_dialogue 还是 true 的时候就处理完。
	await get_tree().process_frame 
	
	GameEvents.is_in_dialogue = false # 2. 此时再解锁，下一帧的点击才会生效
	GameEvents.emit_signal('ui_closed_refresh_hover')
	
func _on_clue_collected_refresh(_word):
	print("收到信号的节点: ", name, " | 路径: ", get_path(), " | ID: ", get_instance_id())
	print("触发")
	# 如果当前对话框是开启状态，重新解析并刷新文本颜色
	if visible and current_character_id != "":
		show_content(current_character_id)

	
	
