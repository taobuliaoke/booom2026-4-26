extends Control

#导出参数
@export var max_width: float = 500 # max width
@export var spacing:int = 10 #how far from dialogbox to item box
#导出路径
@onready var vbox = $VBoxContainer
@onready var dialog_label = $VBoxContainer/DialogBox/TextMargin/MyCustomLabel
@onready var item_box = $VBoxContainer/ItemBox
@onready var container = $VBoxContainer/ItemBox/HFlowContainer


func _ready():
	visible = false
	
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
	GameEvents.is_in_dialogue = true #爸呀大哥，总算给你锁死了
	#设置内容，计算容器大小
	show_content(cid)
	
	#1.处理位置
	global_position = pos
	
	#3.显示自己
	show()


# id 从 characterInteract 脚本传过来
func show_content(id: String):
	var data = GameData.character_data.get(id,{})
	
	#清空旧道具
	for child in container.get_children():
		child.queue_free()
		
	if data.is_empty():
		dialog_label.text = '……'
		item_box.hide()
	else:
		#填入文本
		dialog_label.text = data.get('dialog','')
		 
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
		hide_dialog()
		await get_tree().process_frame
		GameEvents.is_in_dialogue = false
		GameEvents.emit_signal("ui_closed_refresh_hover")


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
	rect.custom_minimum_size = Vector2(80, 80)
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.mouse_filter = Control.MOUSE_FILTER_STOP

# 鼠标样式状态刷新
func _refresh_item_cursor(rect: TextureRect, info: Dictionary):
	var word = info.get("collectible_word", "")
	var can_interact = info.get("can_interact", false)
	# 打印当前字典里所有的 Key，看看有没有“钢笔”
	print("当前注册表内容: ", GameEvents.clues_registry.keys())
	print("正在对比的词条 ID: ", word)
	var is_collected = GameEvents.clues_registry.get(word, false)
	print("当前检查词条: ", word, " 是否已收集: ", is_collected)
	# 判断是否还有未拿取的词条
	var has_pending_word = word != "" and not GameEvents.clues_registry.get(word, false)
	
	if has_pending_word or can_interact:
		rect.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	else:
		rect.mouse_default_cursor_shape = Control.CURSOR_ARROW

# 信号连接交互绑定
func _bind_item_signals(rect: TextureRect, info: Dictionary):
	var item_key = info.get("item_name", info.get("name", "未知物品"))
	
	# 悬停反馈
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
				GameEvents.emit_signal("request_item_detail", info.get("content", ""))
	)
	
func hide_dialog():
	print('执行统一关闭逻辑，重置对话状态为false')
	hide()
	GameEvents.is_in_dialogue = false #只有设为false，按钮才能恢复点击
	
	#别忘了之前的刷新信号，否则鼠标样式会卡住
	await get_tree().process_frame
	GameEvents.emit_signal('ui_closed_refresh_hover')
	
	
	
