extends Control

#导出参数
@export var max_width: float = 500 # max width
@export var spacing:int = 10 #how far from dialogbox to item box
#导出路径
@onready var vbox = $VBoxContainer
@onready var dialog_label = $VBoxContainer/DialogBox/TextMargin/MyCustomLabel
@onready var item_box = $VBoxContainer/ItemBox
@onready var container = $VBoxContainer/ItemBox/HFlowContainer
@onready var word_container = $VBoxContainer/DialogBox/TextMargin/MyCustomLabel/WordContainer

func _ready():
	visible = false
	add_to_group("dialog_uis")
	# 确保节点存在再操作，防止崩溃
	if vbox and dialog_label:
		vbox.add_theme_constant_override('separation', spacing)
		dialog_label.custom_minimum_size.x = max_width
	else:
		print("错误：找不到 UI 节点，请检查场景树路径！")

	GameEvents.request_character_dialog.connect(_on_request_dialog)
	GameEvents.global_clicked.connect(_on_global_clicked)
	
#负责接收两个参数
func _on_request_dialog(cid:String,pos:Vector2):
	# 通知组内所有对话框立刻隐藏 (包括其他视角的对话框)
	get_tree().call_group("dialog_uis", "hide") 
	
	# 如果你的 hide 逻辑里有复杂的解开锁逻辑，建议单独写一个受控隐藏函数
	#get_tree().call_group("dialog_uis", "controlled_hide")


	$VBoxContainer.global_position = pos
	$VBoxContainer.modulate.a = 0.0
	$VBoxContainer.scale = Vector2(0.9,0.9)#微小的弹出感
	$VBoxContainer/ItemBox.modulate.a = 0.0
	$VBoxContainer/ItemBox.scale = Vector2(0.9,0.9)
	GameEvents.is_in_dialogue = true #爸呀大哥，总算给你锁死了
	#设置内容，计算容器大小	
	
	show()
	
	# 阶段 1：Tween 出现动画
	var tween = create_tween().set_parallel(true) # 并行执行透明度和缩放
	tween.tween_property($VBoxContainer, "modulate:a", 1.0, 0.4).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property($VBoxContainer, "scale", Vector2.ONE, 0.4).set_ease(Tween.EASE_OUT)
	tween.tween_property($VBoxContainer/ItemBox, "modulate:a", 1.0, 0.4).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property($VBoxContainer/ItemBox, "scale", Vector2.ONE, 0.4).set_ease(Tween.EASE_OUT)
	# 阶段 2：待机状态
	# 此时 Shader 会在后台自动运行边缘波浪。
	# 如果你还想要一点缓慢的整体“呼吸感”，可以再加一个：
	#_play_idle_float()
	
	#3.显示自己

	show_content(cid)

# id 从 characterInteract 脚本传过来
func show_content(id: String):
	var data = GameData.character_data.get(id,{})
	GameEvents.is_in_dialogue = true
	#清空旧道具
	for child in container.get_children():
		child.queue_free()
		
	if data.is_empty():
		dialog_label.text = '……'
		item_box.hide()

	#填入文本
	var raw_dialog = data.get('dialog','')
	var parsed_result = GameData.parse_pickable_text(raw_dialog)
		
	# 1. 给 Label 显示没有花括号的干净文本
	dialog_label.text = parsed_result["formatted_text"]
		
	# 2. 将解析出的词条信息存起来，用于生成交互区域
	# (你可以先打印一下，看看后台识别对不对)
	print("解析成功，词条数据：", parsed_result["data"])
		
	# 3. 接下来你可以调用生成 Area2D 的方法了
	generate_word_areas(parsed_result)
		 
		#处理道具
	var items_array = data.get('items',[])
	if items_array.is_empty():
		item_box.hide()
	else:
		for item_info in items_array:
			add_new_item(item_info)
		item_box.show()
			
	# 4. 关键：强制刷新布局
	# 这两行能保证道具框在文字变动后，立刻重新吸附到文字下方
	vbox.reset_size() 
	await get_tree().process_frame
	
	
func _play_idle_animation():
	var tween = create_tween().set_loops() # 无限循环
	tween.tween_property($VBoxContainer/DialogBox/BG, "scale", Vector2(1.02, 1.02), 1.5)
	tween.tween_property($VBoxContainer/DialogBox/BG, "scale", Vector2(1.0, 1.0), 1.5)
	
	
# 点击外部收起逻辑 (修改检测范围，因为现在都在 VBox 里)
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

func generate_word_areas(parsed_result):
	# 1. 清理旧的交互区域
	for child in word_container.get_children():
		child.queue_free()
	
	# 2. 准备 TextServer 模拟排版
	var p = TextParagraph.new()
	# 必须与你的 RichTextLabel 属性完全对齐
	p.alignment = dialog_label.horizontal_alignment 
	p.width = dialog_label.size.x
	
	var font = dialog_label.get_theme_font("normal_font")
	var font_size = dialog_label.get_theme_font_size("normal_font_size")
	if font_size == 0: font_size = 43
	# 将干净的文本交给排版引擎
	p.add_string(parsed_result["text"], font, font_size)
	
	# 3. 遍历关键词并生成 Area2D
	for info in parsed_result["data"]:
		var start = info["index"]
		var length = info["length"]
		
		# 利用 TextParagraph 查找该索引段落的矩形区域
		var word_rect = _get_rect_from_paragraph(p, start, length)
		
		if word_rect != Rect2():
			_spawn_interactable(info["word"], word_rect)
			
	# 辅助函数：计算索引范围的矩形

func _get_rect_from_paragraph(p: TextParagraph, start: int, length: int) -> Rect2:
	for i in p.get_line_count():
		var line_range = p.get_line_range(i)
		if start >= line_range.x and start < line_range.y:
			var ts = TextServerManager.get_primary_interface()
			var rid = p.get_line_rid(i)
			
			# 获取起始位置和结束位置的光标字典
			var c_start = ts.shaped_text_get_carets(rid, start)
			var c_end = ts.shaped_text_get_carets(rid, start + length)
			
			# 从字典中提取 X 轴数值。注意：你的字典里 x 坐标在 trailing_rect.position.x
			var x_start = c_start["trailing_rect"].position.x
			var x_end = c_end["trailing_rect"].position.x
			
			var line_ascent = p.get_line_ascent(i)
			var line_descent = p.get_line_descent(i)
			var line_height = line_ascent + line_descent # 这是完整的行高
			
			var y_pos = 0.0
			for j in i:
				y_pos += p.get_line_ascent(j) + p.get_line_descent(j)
			
			# 【关键修改】：Rect2 的第一个参数是左上角坐标，第二个是尺寸 (Width, Height)[cite: 5]
			var rect_x = min(x_start, x_end)
			var rect_width = abs(x_end - x_start)
			
			# 如果宽度还是 0，强制给一个字符的大约宽度（兜底逻辑）
			if rect_width < 1: rect_width = 80 
			
			return Rect2(Vector2(rect_x, y_pos), Vector2(rect_width, line_height))
			
	return Rect2()

func _calculate_word_rect(index: int, length: int) -> Rect2:
	var first_char_rect = dialog_label.get_character_bounds(index)
	var last_char_rect = dialog_label.get_character_bounds(index + length - 1)
	
	# 合并这两个矩形得到完整单词的范围
	return first_char_rect.merge(last_char_rect)
	
func _spawn_interactable(word: String, rect: Rect2):
	var new_area = preload("res://Scenes/Interactable.tscn").instantiate()
	word_container.add_child(new_area)
	new_area.word_name = word
	
	# 确保缩放是 (1, 1)，防止框框看起来很小
	new_area.scale = Vector2.ONE 
	
	var col = new_area.get_node("CollisionShape2D")
	col.scale = Vector2.ONE # 强制形状节点缩放也为 1
	
	var shape = RectangleShape2D.new()
	shape.size = rect.size # 确认这是 (86, 55)
	col.shape = shape
	
	# 位置对齐
	new_area.position = rect.position
	col.position = rect.size / 2 
	
	# 赋值
	if "word_name" in new_area:
		new_area.word_name = word 
		new_area.z_index = 5
		print("词条 [", word, "] 实际碰撞尺寸已设为: ", shape.size)
	# 关键：让这个词条所在的容器（以及它自己）在鼠标经过时默认就是小手
	# 这样 UI 系统和物理系统就统一了
	word_container.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	dialog_label.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
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
				GameEvents.add_word(word)
				GameEvents.collect_clue(word)
				get_tree().call_group("clue_items", "check_status")
				# 拾取后，再次调用刷新函数
				await get_tree().process_frame
				_refresh_item_cursor(rect, info)
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
	

	
	
	
