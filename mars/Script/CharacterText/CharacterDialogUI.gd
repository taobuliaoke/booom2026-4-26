extends Control


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
	
	# 调用生成 Area2D 
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
	# 清理旧的交互区域
	for child in word_container.get_children():
		child.queue_free()
	
	# -------------------------------用 TextServer 模拟排版--------------------------------------------
	var p = TextParagraph.new()
	# 必须与RichTextLabel 属性完全对齐
	p.alignment = dialog_label.horizontal_alignment 
	p.width = dialog_label.size.x
	
	var font = dialog_label.get_theme_font("normal_font")
	var font_size = dialog_label.get_theme_font_size("normal_font_size")
	if font_size == 0: font_size = 43
	# 将干净的文本交给排版引擎
	p.add_string(parsed_result["text"], font, font_size)
	
	# 遍历data数组里的每一个拾取词，抓取该词在句子中的起始位置（start)、长度（length),来确定rect的位置与长度
	for info in parsed_result["data"]:
		var start = info["index"]
		var length = info["length"]
		
		# 把数据传入下一个函数获取矩形区域
		var word_rect = _get_rect_from_paragraph(p, start, length)
		# 生成interactable
		if word_rect != Rect2():
			_spawn_interactable(info["word"], word_rect)
			
	# 辅助函数：计算索引范围的矩形
#生成可拾取词rect（辅助）
func _get_rect_from_paragraph(p: TextParagraph, start: int, length: int) -> Rect2:
	for i in p.get_line_count():  									#方法返回段落行数，也就是遍历每一行
		var line_range = p.get_line_range(i) 						#获取当前行包含的字符范围
		if start >= line_range.x and start < line_range.y:			# 当这一行有可拾取词汇
			var ts = TextServerManager.get_primary_interface()		# 调用底层文字服务器
			var rid = p.get_line_rid(i)								# 获取这一行文字的“身份证”(RID)
			
			# 获取起始位置和结束位置的光标字典
			var c_start = ts.shaped_text_get_carets(rid, start)
			var c_end = ts.shaped_text_get_carets(rid, start + length)
			
			# 从字典中提取开始和结束的 X 轴数值。注意：字典里 x 坐标在 trailing_rect.position.x
			var x_start = c_start["trailing_rect"].position.x
			var x_end = c_end["trailing_rect"].position.x
			
			#获取行高
			var line_ascent = p.get_line_ascent(i)
			var line_descent = p.get_line_descent(i)
			var line_height = line_ascent + line_descent # 上升部+下降部
			
			#计算y轴坐标，每一行的高度累加
			var y_pos = 0.0
			for j in i:
				y_pos += p.get_line_ascent(j) + p.get_line_descent(j)
			
			# Rect2 的第一个参数是左上角坐标，第二个是尺寸 (Width, Height)
			var rect_x = min(x_start, x_end)
			var rect_width = abs(x_end - x_start)
			
			# 如果宽度还是 0，强制给一个字符的大约宽度（兜底逻辑）
			if rect_width < 1: rect_width = 80 
			
			return Rect2(Vector2(rect_x, y_pos), Vector2(rect_width, line_height))
			
	return Rect2()

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
				GameEvents.add_word(word)
				GameEvents.collect_clue(word)
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
	print("触发")
	# 如果当前对话框是开启状态，重新解析并刷新文本颜色
	if visible and current_character_id != "":
		show_content(current_character_id)

	
	
