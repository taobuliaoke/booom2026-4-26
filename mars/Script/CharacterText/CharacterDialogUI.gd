extends Control

#导出路径
@onready var dialog_label = $Itempreview/MyCustomLabel
@onready var item_box = $ItemBox
@onready var dialog_box = $Itempreview
@onready var container = $ItemBox/HFlowContainer

func _ready():
	visible = false

	GameEvents.request_character_dialog.connect(show_content)
	# 重点：订阅 GameEvents 的“电报”，只要有人点屏幕，我就去检查
	GameEvents.global_clicked.connect(_on_global_clicked)
	
	# 如果正在看信，对话框就当没看见点击，不要自己缩回去

# id 从 characterInteract 脚本传过来
func show_content(id: String):
	
	#从GameDate里读Character_date
	visible = true
	var data= GameData.character_data.get(id,{})
	
	# 每次显示前，清空旧的道具图标
	for child in container.get_children():
		child.queue_free()
	
	if data.is_empty():
		dialog_label.text = '……'
		item_box.hide()
		return
	#填入自定义文本内容
	dialog_label.text = data.get('dialog','')
	
	# 获取道具数组
	var items_array = data.get("items", [])
	if items_array != []:
		for item_info in items_array:
			add_new_item(item_info)
		item_box.show()
	else:
		item_box.hide()

# 点击外部收起对话框道具栏逻辑
func _on_global_clicked(event: InputEventMouseButton):
	var dialog_rect = dialog_box.get_global_rect()
	var item_rect = item_box.get_global_rect()
	# 如果我本来就没出来，那就不用理会
	if GameEvents.is_sub_ui_open:
		return
	if not visible:
		return

	# 【核心逻辑】
	# get_global_rect() 获取这个 UI 面板在屏幕上的矩形区域
	# has_point(点击位置) 判断你点的地方在不在这个矩形里
	if item_box.visible:
		if dialog_rect.has_point(event.global_position) or item_rect.has_point(event.global_position):
			return
	if dialog_rect.has_point(event.global_position):
		return
	
	print("点到 UI 外面了，收起面板")
	hide()
	await get_tree().process_frame
	GameEvents.is_in_dialogue = false
	# 收起面板
	#发信号告诉所有 Area2D 可以重新检查鼠标了
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
		print("小手")
		rect.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	else:
		print("指针")
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
	
